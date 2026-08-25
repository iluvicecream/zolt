const std = @import("std");

const Io = std.Io;
const Dir = Io.Dir;
const luau = @import("zolt_luau");
const HttpRsp = @import("protocol/http_rsp.zig").HttpRsp;

pub const max_content_size = 16 * 1024;

const max_output_size = 16 * 1024;

const not_found_body = "𐔌՞.‸.՞𐦯 not found";

const RequestCtx = struct {
    output: [max_output_size]u8 = undefined,
    len: usize = 0,
    echoed: bool = false,
    overflowed: bool = false,

    fn append(self: *RequestCtx, s: []const u8) void {
        if (self.overflowed or s.len > self.output.len - self.len) {
            self.overflowed = true;
            return;
        }
        @memcpy(self.output[self.len..][0..s.len], s);
        self.len += s.len;
    }
};

const RuntimeFn = struct {
    name: [:0]const u8,
    func: luau.CFunction,
};

const runtime_fns = [_]RuntimeFn{
    .{ .name = "echo", .func = luaEcho },
};

fn luaEcho(L: *luau.State) callconv(.c) c_int {
    const raw_ctx = luau.upvaluePtr(L, 1) orelse return 0;
    const ctx: *RequestCtx = @ptrCast(@alignCast(raw_ctx));
    ctx.echoed = true;

    const argc: usize = @intCast(luau.getTop(L));
    for (0..argc) |i| {
        const index: c_int = @intCast(i + 1);
        if (luau.getString(L, index)) |s| ctx.append(s);
    }
    return 0;
}

fn registerRuntime(L: *luau.State, ctx: *RequestCtx) void {
    for (runtime_fns) |f| {
        luau.registerFunction(L, -1, f.name, ctx, f.func);
    }
}

const CachedScript = struct {
    path: []const u8,
    mtime: Io.Timestamp,
    size: u64,
    bytecode: []u8,
};

pub const RouteHandler = struct {
    allocator: std.mem.Allocator,
    L: *luau.State,
    scripts: std.ArrayList(CachedScript),

    pub fn init(allocator: std.mem.Allocator) !RouteHandler {
        const L = luau.newState() orelse return error.LuauInitFailed;
        errdefer luau.close(L);
        return .{
            .allocator = allocator,
            .L = L,
            .scripts = .empty,
        };
    }

    pub fn deinit(self: *RouteHandler) void {
        for (self.scripts.items) |script| {
            self.allocator.free(script.path);
            std.c.free(@ptrCast(script.bytecode.ptr));
        }
        self.scripts.deinit(self.allocator);
        luau.close(self.L);
        self.* = undefined;
    }

    pub fn handle(ctx: *anyopaque, io: Io, allocator: std.mem.Allocator, req: *std.http.Server.Request) anyerror!void {
        _ = allocator;
        const self: *RouteHandler = @ptrCast(@alignCast(ctx));
        try self.handleRequest(io, req);
    }

    fn handleRequest(self: *RouteHandler, io: Io, req: *std.http.Server.Request) !void {
        defer luau.settop(self.L, 0);

        const target = resolveTarget(req.head.target) orelse {
            std.log.warn("invalid route target target={s}", .{req.head.target});
            return respondNotFound(req);
        };

        var http_rsp: HttpRsp = .{ .content = "hello", .status = .ok };

        const bytecode = self.getBytecode(io, target) catch |err| {
            std.log.err("route script error target={s} err={}", .{ target, err });
            return err;
        };
        if (bytecode) |bc| {
            var ctx = RequestCtx{};
            self.runScript(target, bc, &ctx, &http_rsp) catch |err| {
                std.log.err("route script error target={s} err={}", .{ target, err });
                return err;
            };
        } else {
            std.log.warn("route handler script not found target={s}", .{req.head.target});
            return respondNotFound(req);
        }

        try req.respond(http_rsp.toContent(), http_rsp.toRespondOptions());
    }

    fn getBytecode(self: *RouteHandler, io: Io, path: []const u8) !?[]const u8 {
        const stat = Dir.statFile(.cwd(), io, path, .{}) catch |err| switch (err) {
            error.FileNotFound => return null,
            else => return err,
        };

        if (self.findScript(path)) |script| {
            if (script.mtime.nanoseconds == stat.mtime.nanoseconds and script.size == stat.size)
                return script.bytecode;
        }

        const content = try Dir.readFileAlloc(.cwd(), io, path, self.allocator, .limited(max_content_size));
        defer self.allocator.free(content);

        var out_size: usize = 0;
        const bytecode = luau.compile(content, &out_size) orelse {
            std.log.err("route lua compile error target={s}", .{path});
            return error.RouteCompileFailed;
        };
        errdefer std.c.free(@ptrCast(bytecode.ptr));

        if (self.findScript(path)) |script| {
            std.c.free(@ptrCast(script.bytecode.ptr));
            script.bytecode = bytecode;
            script.mtime = stat.mtime;
            script.size = stat.size;
            return script.bytecode;
        }

        const owned_path = try self.allocator.dupe(u8, path);
        errdefer self.allocator.free(owned_path);

        try self.scripts.append(self.allocator, .{
            .path = owned_path,
            .mtime = stat.mtime,
            .size = stat.size,
            .bytecode = bytecode,
        });
        return self.scripts.items[self.scripts.items.len - 1].bytecode;
    }

    fn findScript(self: *RouteHandler, path: []const u8) ?*CachedScript {
        for (self.scripts.items) |*script| {
            if (std.mem.eql(u8, script.path, path)) return script;
        }
        return null;
    }

    fn runScript(self: *RouteHandler, target: []const u8, bytecode: []const u8, ctx: *RequestCtx, rsp: *HttpRsp) !void {
        errdefer luau.settop(self.L, 0);

        luau.pushSandboxEnv(self.L);
        registerRuntime(self.L, ctx);

        var chunk_name_buf: [256]u8 = undefined;
        const chunk_name = std.fmt.bufPrintZ(&chunk_name_buf, "={s}", .{target}) catch "=route.lua";

        luau.loadBytecode(self.L, chunk_name, bytecode, -1) catch |err| {
            std.log.err("route lua load error err={s} target={s}", .{ luau.errorMessage(self.L), target });
            return err;
        };
        luau.pcall(self.L, 0, 1) catch |err| {
            std.log.err("route lua runtime error err={s} target={s}", .{ luau.errorMessage(self.L), target });
            return err;
        };

        if (ctx.echoed) {
            if (ctx.overflowed) {
                std.log.err("route lua echo output too large target={s}", .{target});
                return error.RouteScriptOutputTooLarge;
            }
            rsp.content = ctx.output[0..ctx.len];
            return;
        }

        if (luau.typeOf(self.L, -1) != .table) {
            std.log.err("route lua expected to return a table target={s}", .{target});
            return error.RouteScriptReturnType;
        }

        luau.getField(self.L, -1, "response");
        const response = luau.getString(self.L, -1) orelse {
            std.log.err("route lua missing string field 'response' target={s}", .{target});
            return error.RouteScriptMissingResponse;
        };
        rsp.content = response;
    }
};

fn resolveTarget(target: []const u8) ?[]const u8 {
    if (target.len == 0 or target[0] != '/') return null;

    var path = target[1..];

    if (std.mem.indexOfAny(u8, path, "?#")) |i| path = path[0..i];

    if (path.len == 0) return "index.lua";

    if (path[0] == '/' or std.mem.indexOf(u8, path, "//") != null) return null;
    if (std.mem.indexOf(u8, path, "..") != null) return null;
    if (std.mem.indexOfAny(u8, path, "\\\x00") != null) return null;
    return path;
}

fn respondNotFound(req: *std.http.Server.Request) !void {
    const http_rsp: HttpRsp = .{
        .content = not_found_body,
        .status = .not_found,
        .extra_headers = &.{.{ .name = "content-type", .value = "text/plain; charset=utf-8" }},
    };
    try req.respond(http_rsp.toContent(), http_rsp.toRespondOptions());
}
