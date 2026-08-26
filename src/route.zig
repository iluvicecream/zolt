const std = @import("std");

const Io = std.Io;
const runtime = @import("runtime/runtime.zig");
const script_cache = @import("script_cache.zig");
const HttpRsp = @import("protocol/http_rsp.zig").HttpRsp;

pub const max_content_size = 16 * 1024;

pub const ScriptCache = script_cache.ScriptCache;

pub const RouteHandler = struct {
    allocator: std.mem.Allocator,
    rt: runtime.Runtime,
    cache: *ScriptCache,
    show_runtime_errors: bool,

    pub fn init(allocator: std.mem.Allocator, show_runtime_errors: bool, cache: *ScriptCache) !RouteHandler {
        const rt = try runtime.Runtime.init(allocator, cache);
        errdefer rt.deinit();
        return .{
            .allocator = allocator,
            .rt = rt,
            .cache = cache,
            .show_runtime_errors = show_runtime_errors,
        };
    }

    pub fn deinit(self: *RouteHandler) void {
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

        var path_buf: [4096]u8 = undefined;
        const target = resolveTarget(req.head.target, &path_buf) orelse {
            std.log.warn("invalid route target target={s}", .{req.head.target});
            return respondNotFound(req);
        };

        var http_rsp: HttpRsp = .{};

        const lookup = self.cache.acquire(io, self.allocator, target, max_content_size) catch |err| {
            std.log.err("route script error target={s} err={}", .{ target, err });
            return respondServerError(req, &http_rsp, null);
        };
        switch (lookup) {
            .not_found => {
                std.log.warn("route handler script not found target={s}", .{req.head.target});
                return respondNotFound(req);
            },
            .too_large => {
                std.log.err("route script source too large target={s}", .{target});
                return respondServerError(req, &http_rsp, "route script source exceeds 16 KB");
            },
            .compile_error => |blob| {
                defer std.c.free(@ptrCast(blob.ptr));
                var chunk_name_buf: [256]u8 = undefined;
                const compile_err = self.rt.compileErrorMessage(chunkName(target, &chunk_name_buf), blob);
                std.log.err("route lua compile error target={s} err={s}", .{ target, compile_err });
                return respondServerError(
                    req,
                    &http_rsp,
                    if (self.show_runtime_errors) compile_err else null,
                );
            },
            .ok => |bytecode| {
                defer self.allocator.free(bytecode);
                self.runScript(io, target, bytecode, &http_rsp) catch |err| {
                    std.log.err("route lua error err={} target={s}", .{ err, target });
                    const detail: ?[]const u8 = switch (err) {
                        error.RouteScriptOutputTooLarge => "route script output exceeds 16 KB",
                        else => if (self.show_runtime_errors) self.rt.errorMessage() else null,
                    };
                    return respondServerError(req, &http_rsp, detail);
                };

                if (http_rsp.body_used) {
                    if (http_rsp.body_overflowed) {
                        std.log.err("route lua output too large target={s}", .{target});
                        return respondServerError(req, &http_rsp, "route script output exceeds 16 KB");
                    }
                    if (!http_rsp.hasHeader("content-type"))
                        _ = http_rsp.setHeader("content-type", "text/html; charset=utf-8");
                }

                try req.respond(http_rsp.toContent(), http_rsp.toRespondOptions());
            },
        }
    }

    fn runScript(self: *RouteHandler, io: Io, target: []const u8, bytecode: []const u8, rsp: *HttpRsp) !void {
        self.rt.beginRequest(rsp);
        self.rt.io = io;
        runtime.packages.echo.register(self.rt.L, rsp);
        runtime.packages.require.register(self.rt.L, &self.rt);
        runtime.packages.response.register(self.rt.L, rsp);

        var chunk_name_buf: [256]u8 = undefined;
        const chunk_name = chunkName(target, &chunk_name_buf);

        self.rt.run(chunk_name, target, bytecode) catch |err| {
            std.log.err("route lua error err={s} target={s}", .{ self.rt.errorMessage(), target });
            return err;
        };

        if (rsp.body_used) {
            if (rsp.body_overflowed) {
                std.log.err("route lua output too large target={s}", .{target});
                return error.RouteScriptOutputTooLarge;
            }
            if (!rsp.hasHeader("content-type"))
                _ = rsp.setHeader("content-type", "text/html; charset=utf-8");
            return;
        }
    }
};

fn chunkName(path: []const u8, buf: *[256]u8) [:0]const u8 {
    return std.fmt.bufPrintZ(buf, "={s}", .{path}) catch "=route.luau";
}

fn resolveTarget(target: []const u8, buf: []u8) ?[]const u8 {
    if (target.len == 0 or target[0] != '/') return null;

    var path = target[1..];
    if (std.mem.indexOfAny(u8, path, "?#")) |i| path = path[0..i];

    if (path.len == 0) return "index.luau";

    var pos: usize = 0;
    var it = std.mem.splitScalar(u8, path, '/');
    while (it.next()) |seg| {
        if (seg.len == 0 or std.mem.eql(u8, seg, ".")) continue;
        if (std.mem.eql(u8, seg, "..")) return null;
        if (std.mem.indexOfAny(u8, seg, "\\\x00") != null) return null;
        if (pos + seg.len + 1 > buf.len) return null;
        if (pos != 0) {
            buf[pos] = '/';
            pos += 1;
        }
        @memcpy(buf[pos..][0..seg.len], seg);
        pos += seg.len;
    }

    if (pos == 0) return "index.luau";
    return buf[0..pos];
}

fn respondNotFound(req: *std.http.Server.Request) !void {
    var http_rsp: HttpRsp = .{};
    http_rsp.setStatus(.not_found, null);
    http_rsp.append("𐔌՞.‸.՞𐦯 not found");
    _ = http_rsp.setHeader("content-type", "text/plain; charset=utf-8");
    try req.respond(http_rsp.toContent(), http_rsp.toRespondOptions());
}

fn respondServerError(req: *std.http.Server.Request, rsp: *HttpRsp, detail: ?[]const u8) !void {
    rsp.reset();
    rsp.setStatus(.internal_server_error, null);
    rsp.append(detail orelse "Internal Server Error");
    _ = rsp.setHeader("content-type", "text/plain; charset=utf-8");
    try req.respond(rsp.toContent(), rsp.toRespondOptions());
}
