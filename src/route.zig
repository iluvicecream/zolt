const std = @import("std");

const Io = std.Io;
const Dir = Io.Dir;
const runtime = @import("runtime/runtime.zig");
const HttpRsp = @import("protocol/http_rsp.zig").HttpRsp;

pub const max_content_size = 16 * 1024;

const CachedScript = struct {
    path: []const u8,
    mtime: Io.Timestamp,
    size: u64,
    bytecode: []u8,
};

pub const RouteHandler = struct {
    allocator: std.mem.Allocator,
    rt: runtime.Runtime,
    scripts: std.ArrayList(CachedScript),
    show_runtime_errors: bool,

    pub fn init(allocator: std.mem.Allocator, show_runtime_errors: bool) !RouteHandler {
        const rt = try runtime.Runtime.init(allocator);
        errdefer rt.deinit();
        return .{
            .allocator = allocator,
            .rt = rt,
            .scripts = .empty,
            .show_runtime_errors = show_runtime_errors,
        };
    }

    pub fn deinit(self: *RouteHandler) void {
        for (self.scripts.items) |script| {
            self.allocator.free(script.path);
            std.c.free(@ptrCast(script.bytecode.ptr));
        }
        self.scripts.deinit(self.allocator);
        self.rt.deinit();
        self.* = undefined;
    }

    pub fn handle(ctx: *anyopaque, io: Io, allocator: std.mem.Allocator, req: *std.http.Server.Request) anyerror!void {
        _ = allocator;
        const self: *RouteHandler = @ptrCast(@alignCast(ctx));
        try self.handleRequest(io, req);
    }

    fn handleRequest(self: *RouteHandler, io: Io, req: *std.http.Server.Request) !void {
        defer self.rt.endRequest();

        const target = resolveTarget(req.head.target) orelse {
            std.log.warn("invalid route target target={s}", .{req.head.target});
            return respondNotFound(req);
        };

        var http_rsp: HttpRsp = .{ .content = "", .status = .internal_server_error };

        const bytecode = self.getBytecode(io, target, &http_rsp) catch |err| {
            std.log.err("route script error target={s} err={}", .{ target, err });
            if (self.show_runtime_errors and http_rsp.content.len > 0)
                return req.respond(http_rsp.toContent(), http_rsp.toRespondOptions());
            return err;
        };
        if (bytecode) |bc| {
            self.runScript(io, target, bc, &http_rsp) catch |err| {
                std.log.err("route script error target={s} err={}", .{ target, err });
                if (self.show_runtime_errors) {
                    http_rsp.status = .internal_server_error;
                    http_rsp.content = self.rt.errorMessage();
                    http_rsp.extra_headers = &.{.{ .name = "content-type", .value = "text/plain; charset=utf-8" }};
                    return req.respond(http_rsp.toContent(), http_rsp.toRespondOptions());
                }
                return err;
            };
        } else {
            std.log.warn("route handler script not found target={s}", .{req.head.target});
            return respondNotFound(req);
        }

        try req.respond(http_rsp.toContent(), http_rsp.toRespondOptions());
    }

    fn getBytecode(self: *RouteHandler, io: Io, path: []const u8, rsp: *HttpRsp) !?[]const u8 {
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
        const bytecode = runtime.compile(content, &out_size) orelse {
            std.log.err("route lua compile error target={s}", .{path});
            return error.RouteCompileFailed;
        };
        errdefer std.c.free(@ptrCast(bytecode.ptr));

        if (runtime.isCompileError(bytecode)) {
            var chunk_name_buf: [256]u8 = undefined;
            const compile_err = self.rt.compileErrorMessage(chunkName(path, &chunk_name_buf), bytecode);
            std.log.err("route lua compile error target={s} err={s}", .{ path, compile_err });
            if (self.show_runtime_errors) {
                rsp.status = .internal_server_error;
                rsp.content = compile_err;
                rsp.extra_headers = &.{.{ .name = "content-type", .value = "text/plain; charset=utf-8" }};
            }
            return error.RouteCompileFailed;
        }

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

    fn runScript(self: *RouteHandler, io: Io, target: []const u8, bytecode: []const u8, rsp: *HttpRsp) !void {
        self.rt.beginRequest();
        self.rt.io = io;
        runtime.packages.echo.register(self.rt.L, &self.rt.response);
        runtime.packages.require.register(self.rt.L, &self.rt);

        var chunk_name_buf: [256]u8 = undefined;
        const chunk_name = chunkName(target, &chunk_name_buf);

        self.rt.run(chunk_name, target, bytecode) catch |err| {
            std.log.err("route lua error err={s} target={s}", .{ self.rt.errorMessage(), target });
            return err;
        };

        if (self.rt.response.used) {
            if (self.rt.response.overflowed) {
                std.log.err("route lua output too large target={s}", .{target});
                return error.RouteScriptOutputTooLarge;
            }
            rsp.content = self.rt.response.slice();
            rsp.status = .ok;
            rsp.extra_headers = &.{.{ .name = "content-type", .value = "text/html; charset=utf-8" }};
            return;
        }

        rsp.status = .ok;
    }
};

fn chunkName(path: []const u8, buf: *[256]u8) [:0]const u8 {
    return std.fmt.bufPrintZ(buf, "={s}", .{path}) catch "=route.luau";
}

fn resolveTarget(target: []const u8) ?[]const u8 {
    if (target.len == 0 or target[0] != '/') return null;

    var path = target[1..];
    if (std.mem.indexOfAny(u8, path, "?#")) |i| path = path[0..i];

    if (path.len == 0) return "index.luau";
    if (path[0] == '/' or std.mem.indexOf(u8, path, "//") != null) return null;
    if (std.mem.indexOf(u8, path, "..") != null) return null;
    if (std.mem.indexOfAny(u8, path, "\\\x00") != null) return null;
    return path;
}

fn respondNotFound(req: *std.http.Server.Request) !void {
    const http_rsp: HttpRsp = .{
        .content = "𐔌՞.‸.՞𐦯 not found",
        .status = .not_found,
        .extra_headers = &.{.{ .name = "content-type", .value = "text/plain; charset=utf-8" }},
    };
    try req.respond(http_rsp.toContent(), http_rsp.toRespondOptions());
}
