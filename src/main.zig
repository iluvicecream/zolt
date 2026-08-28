const std = @import("std");

const Io = std.Io;

const zolt = @import("zolt");
const RouteHandler = zolt.Route.RouteHandler;
const ScriptCache = zolt.Route.ScriptCache;
const ConnHandler = zolt.Network.ConnHandler;
const HttpSession = zolt.Network.HttpSession;

pub fn main(init: std.process.Init) !void {
    std.log.info("𐔌՞. .՞𐦯 ⚡︎ ⋆.˚ zoltd", .{});
    const config_path = parseConfigPath(init);
    std.log.info("using config {s}", .{config_path});

    const config_dir = std.fs.path.dirname(config_path) orelse ".";
    const config_file = std.fs.path.basename(config_path);

    var root = Io.Dir.openDir(.cwd(), init.io, config_dir, .{}) catch |err| {
        std.log.err("failed to open root dir '{s}' err={}", .{ config_dir, err });
        std.process.exit(12); // FAILED_ROOT_DIR
    };
    defer root.close(init.io);

    var config = loadConfig(init.io, init.gpa, root, config_file) catch |err| {
        std.log.err("failed to load config err={}", .{err});
        std.process.exit(10); // INVALID_CONFIG
    };
    defer config.deinit(init.gpa);

    httpServerSetup(init.io, config, root, init.gpa) catch |err| {
        std.log.err("failed to setup http server err={}", .{err});
        std.process.exit(11); // FAILED_HTTP_SESSION
    };
}

fn parseConfigPath(init: std.process.Init) []const u8 {
    var args = std.process.Args.Iterator.init(init.minimal.args);
    _ = args.next();
    return args.next() orelse "config.luau";
}

fn loadConfig(io: Io, allocator: std.mem.Allocator, root: Io.Dir, path: []const u8) !zolt.Config {
    return zolt.Config.load(io, allocator, root, path);
}

const RouteFactory = struct {
    root: Io.Dir,
    show_runtime_errors: bool,
    cache: ScriptCache,

    fn init(ctx: *anyopaque, allocator: std.mem.Allocator) anyerror!*anyopaque {
        const self: *RouteFactory = @ptrCast(@alignCast(ctx));
        const handler = try allocator.create(RouteHandler);
        errdefer allocator.destroy(handler);
        handler.* = try RouteHandler.init(allocator, self.root, self.show_runtime_errors, &self.cache);
        return handler;
    }

    fn deinit(conn: *anyopaque) void {
        const handler: *RouteHandler = @ptrCast(@alignCast(conn));
        const allocator = handler.allocator;
        handler.deinit();
        allocator.destroy(handler);
    }
};

fn httpServerSetup(io: Io, config: zolt.Config, root: Io.Dir, allocator: std.mem.Allocator) !void {
    const address = Io.net.IpAddress.parseLiteral(config.host) catch |err| {
        std.log.err("failed to parse host err={}", .{err});
        return err;
    };

    var factory = RouteFactory{
        .root = root,
        .show_runtime_errors = config.is_show_runtime_error,
        .cache = ScriptCache.init(allocator, ScriptCache.max_cached_scripts),
    };
    defer factory.cache.deinit(io);
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
