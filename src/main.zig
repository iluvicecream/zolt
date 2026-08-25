const std = @import("std");

const Io = std.Io;

const zolt = @import("zolt");
const HttpSession = zolt.Network.HttpSession;

pub fn main(init: std.process.Init) !void {
    std.log.info("𐔌՞. .՞𐦯 ⚡︎ ⋆.˚ zoltd", .{});
    loadConfig(init.io, init.gpa) catch |err| std.log.err("failed to load config err={}", .{err});
    httpServerSetup(init.io) catch |err| std.log.err("failed to setup http server err={}", .{err});
}

fn loadConfig(io: Io, allocator: std.mem.Allocator) !void {
    var config = zolt.Config.load(io, allocator) catch |err| {
        std.log.err("failed to load config err={}", .{err});
        return err;
    };
    defer config.deinit(allocator);
}

fn httpServerSetup(io: Io) !void {
    const address = Io.net.IpAddress.parse("127.0.0.1", 8081) catch |err| {
        std.log.err("failed to parse ip err={}", .{err});
        return err;
    };
    var session = HttpSession.init(io, address, handleRequest) catch |err| {
        std.log.err("failed to init http session err={}", .{err});
        return err;
    };
    defer session.deinit();

    std.log.info("http server started ip={d}.{d}.{d}.{d}:{d}", .{ address.ip4.bytes[0], address.ip4.bytes[1], address.ip4.bytes[2], address.ip4.bytes[3], address.ip4.port });

    session.run() catch |err| {
        std.log.err("failed to run http session err={}", .{err});
    };
}

fn handleRequest(req: *std.http.Server.Request) !void {
    var http_rsp: zolt.Protocol.HttpRsp = .{ .content = "hello", .status = .ok };
    req.respond(http_rsp.toContent(), http_rsp.toRespondOptions()) catch |err| {
        std.log.err("failed to respond to http request err={}", .{err});
    };
}
