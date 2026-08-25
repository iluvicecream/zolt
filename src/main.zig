const std = @import("std");

const Io = std.Io;
const Dir = Io.Dir;

const zolt = @import("zolt");
const luau = zolt.Luau;
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
    var session = HttpSession.init(io, address, allocator, handleRequest) catch |err| {
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

fn handleRequest(io: Io, allocator: std.mem.Allocator, req: *std.http.Server.Request) !void {
    var http_rsp: zolt.Protocol.HttpRsp = .{
        .content = "hello",
        .status = .ok,
    };
    if (checkTargetExist(io, req.head.target)) {
        var checkTarget = req.head.target;
        if (std.mem.eql(u8, checkTarget, "/")) {
            checkTarget = "index.lua";
        } else {
            checkTarget = req.head.target[1..];
        }

        const max_content_size = 16 * 1024;
        const content = try Dir.readFileAlloc(.cwd(), io, checkTarget, allocator, .limited(max_content_size));
        defer allocator.free(content);
        const L = luau.newState() orelse {
            std.log.err("config loader failed to create luau state", .{});
            return error.ConfigEvalFailed;
        };
        defer luau.close(L);

        luau.loadString(L, "=excu.lua", content) catch {
            std.log.err("config lua compile error err={s}", .{luau.errorMessage(L)});
            return error.ConfigEvalFailed;
        };

        luau.pcall(L, 0, 1) catch {
            std.log.err("config lua runtime error err={s}", .{luau.errorMessage(L)});
            return error.ConfigEvalFailed;
        };
        defer luau.settop(L, -2); // drop the returned table

        if (luau.typeOf(L, -1) != .table) {
            std.log.err("config lua expected it to return a table", .{});
            return error.ConfigEvalFailed;
        }

        const response = luau.getFieldString(L, -1, "response") orelse {
            std.log.err("config lua missing string field 'response'", .{});
            return error.ConfigEvalFailed;
        };

        const response_owned = try allocator.dupe(u8, response);
        errdefer allocator.free(response_owned);

        http_rsp.content = response_owned;
    } else {
        std.log.warn("target handler script not found target={s}", .{req.head.target});
        http_rsp.status = .not_found;
        http_rsp.content = "𐔌՞.‸.՞𐦯 not found";
        http_rsp.extra_headers = &.{.{ .name = "content-type", .value = "text/plain; charset=utf-8" }};
        //http_rsp.content_type = "text/plain; charset=utf-8";
    }
    req.respond(http_rsp.toContent(), http_rsp.toRespondOptions()) catch |err| {
        std.log.err("failed to respond to http request err={}", .{err});
    };
}

fn checkTargetExist(io: Io, target: []const u8) bool {
    var checkTarget = target;
    if (std.mem.eql(u8, checkTarget, "/")) {
        checkTarget = "index.lua";
    } else {
        checkTarget = target[1..];
    }

    Dir.access(.cwd(), io, checkTarget, .{}) catch |err| {
        if (err == error.FileNotFound) {
            return false;
        }
        std.log.err("check target failed err={}", .{err});
        return false;
    };

    return true;
}
