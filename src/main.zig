const std = @import("std");

const Io = std.Io;

const zolt = @import("zolt");
const RouteHandler = zolt.Route.RouteHandler;
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

fn httpServerSetup(io: Io, config: zolt.Config, allocator: std.mem.Allocator) !void {
    const address = Io.net.IpAddress.parseLiteral(config.host) catch |err| {
        std.log.err("failed to parse host err={}", .{err});
        return err;
    };

    var route_handler = RouteHandler.init(allocator) catch |err| {
        std.log.err("failed to init route handler err={}", .{err});
        return err;
    };
    defer route_handler.deinit();

    var session = HttpSession.init(io, address, allocator, &route_handler, RouteHandler.handle) catch |err| {
        std.log.err("failed to init http session err={}", .{err});
        std.process.exit(11); // FAILED_HTTP_SESSION
        return err;
    };
    defer session.deinit();

    std.log.info("http server started ip={d}.{d}.{d}.{d}:{d}", .{ address.ip4.bytes[0], address.ip4.bytes[1], address.ip4.bytes[2], address.ip4.bytes[3], address.ip4.port });

    session.run() catch |err| {
        std.log.err("failed to run http session err={}", .{err});
        std.process.exit(11); // FAILED_HTTP_SESSION
    };
}
