const std = @import("std");

const Io = std.Io;

const zolt = @import("zolt");
const RouteHandler = zolt.Route.RouteHandler;
const ConnHandler = zolt.Network.ConnHandler;
const HttpSession = zolt.Network.HttpSession;

pub fn main(init: std.process.Init) !void {
    std.log.info("𐔌՞. .՞𐦯 ⚡︎ ⋆.˚ zoltd", .{});
    var config = loadConfig(init.io, init.gpa) catch |err| {
        std.log.err("failed to load config err={}", .{err});
        std.process.exit(10); // INVALID_CONFIG
    };
    defer config.deinit(init.gpa);

    httpServerSetup(init.io, config, init.gpa) catch |err| {
        std.log.err("failed to setup http server err={}", .{err});
        std.process.exit(11); // FAILED_HTTP_SESSION
    };
}

fn loadConfig(io: Io, allocator: std.mem.Allocator) !zolt.Config {
    return zolt.Config.load(io, allocator);
}

const RouteFactory = struct {
    show_runtime_errors: bool,

    fn init(ctx: *anyopaque, allocator: std.mem.Allocator) anyerror!*anyopaque {
        const self: *const RouteFactory = @ptrCast(@alignCast(ctx));
        const handler = try allocator.create(RouteHandler);
        errdefer allocator.destroy(handler);
        handler.* = try RouteHandler.init(allocator, self.show_runtime_errors);
        return handler;
    }

    fn deinit(conn: *anyopaque) void {
        const handler: *RouteHandler = @ptrCast(@alignCast(conn));
        const allocator = handler.allocator;
        handler.deinit();
        allocator.destroy(handler);
    }
};

fn httpServerSetup(io: Io, config: zolt.Config, allocator: std.mem.Allocator) !void {
    const address = Io.net.IpAddress.parseLiteral(config.host) catch |err| {
        std.log.err("failed to parse host err={}", .{err});
        return err;
    };

    var factory = RouteFactory{ .show_runtime_errors = config.is_show_runtime_error };
    const conn_handler: ConnHandler = .{
        .ctx = &factory,
        .init = RouteFactory.init,
        .handle = RouteHandler.handle,
        .deinit = RouteFactory.deinit,
    };

    var session = HttpSession.init(io, address, allocator, conn_handler, config.max_connections) catch |err| {
        std.log.err("failed to init http session err={}", .{err});
        std.process.exit(11); // FAILED_HTTP_SESSION
        return err;
    };
    defer session.deinit();

    std.log.info("http server started ip={d}.{d}.{d}.{d}:{d} maxConnections={d}", .{ address.ip4.bytes[0], address.ip4.bytes[1], address.ip4.bytes[2], address.ip4.bytes[3], address.ip4.port, config.max_connections });

    session.run() catch |err| {
        std.log.err("failed to run http session err={}", .{err});
        std.process.exit(11); // FAILED_HTTP_SESSION
    };
}
