const std = @import("std");
const luau = @import("zolt_luau");
const HttpRsp = @import("../../protocol/http_rsp.zig").HttpRsp;

const http = std.http;

pub fn register(L: *luau.State, rsp: *HttpRsp) void {
    const env = luau.getTop(L);
    luau.createTable(L, 0, 2); // env + 1: response table
    luau.registerFunction(L, -1, "status", rsp, luaStatus);
    luau.registerFunction(L, -1, "header", rsp, luaHeader);
    luau.setField(L, env, "response");
    luau.settop(L, env);
}

fn luaStatus(L: *luau.State) callconv(.c) c_int {
    const raw_rsp = luau.upvaluePtr(L, 1) orelse return 0;
    const rsp: *HttpRsp = @ptrCast(@alignCast(raw_rsp));

    const code = luau.tonumber(L, 1) orelse
        return raise(L, "status: expected a number status code", .{});
    if (code != @floor(code)) return raise(L, "status: expected an integer status code", .{});

    const n: i64 = @intFromFloat(code);
    if (n < 100 or n > 599) return raise(L, "status: status code {d} out of range", .{n});

    const status = std.enums.fromInt(http.Status, @as(u16, @intCast(n))) orelse
        return raise(L, "status: unsupported status code {d}", .{n});
    rsp.setStatus(status, null);
    return 0;
}

fn luaHeader(L: *luau.State) callconv(.c) c_int {
    const raw_rsp = luau.upvaluePtr(L, 1) orelse return 0;
    const rsp: *HttpRsp = @ptrCast(@alignCast(raw_rsp));

    const name = luau.getString(L, 1) orelse
        return raise(L, "header: expected a string name", .{});
    const value = luau.getString(L, 2) orelse
        return raise(L, "header: expected a string value", .{});

    if (!HttpRsp.isValidHeaderName(name) or !HttpRsp.isValidHeaderValue(value))
        return raise(L, "header: invalid header name or value", .{});

    if (!rsp.setHeader(name, value))
        return raise(L, "header: too many headers or header value too long", .{});
    return 0;
}

fn raise(L: *luau.State, comptime fmt: []const u8, args: anytype) c_int {
    var buf: [256]u8 = undefined;
    const msg: []const u8 = std.fmt.bufPrint(&buf, fmt, args) catch "response: internal error";
    luau.pushLString(L, msg);
    return luau.errorRaise(L);
}
