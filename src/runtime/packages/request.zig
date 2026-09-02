const std = @import("std");
const luau = @import("zolt_luau");

const max_query_len = 4096;

pub fn register(L: *luau.State, path: []const u8, query: []const u8) void {
    const env = luau.getTop(L);
    luau.pushLString(L, path); // env + 1: path string
    luau.pushClosure(L, luaRequestPath, "request.path", 1); // consumes path, pushes closure: env + 1
    luau.createTable(L, 0, 2); // env + 2: request table
    luau.pushValue(L, -2); // env + 3: closure copy
    luau.setField(L, env + 2, "path"); // request.path = closure

    luau.pushLString(L, query); // env + 3: query string
    luau.pushClosure(L, luaRequestQuery, "request.query", 1); // consumes query, pushes closure: env + 3
    luau.setField(L, env + 2, "query"); // request.query = closure

    luau.setField(L, env, "request"); // env.request = request
    luau.settop(L, env);
}

fn luaRequestPath(L: *luau.State) callconv(.c) c_int {
    luau.pushValue(L, luau.upvalueIndex(1));
    return 1;
}

fn luaRequestQuery(L: *luau.State) callconv(.c) c_int {
    const field = luau.getString(L, 1) orelse
        return raise(L, "request.query: expected a string field name", .{});

    const raw_query = luau.getString(L, luau.upvalueIndex(1)) orelse return 0;
    if (raw_query.len == 0) return 0;

    var key_buf: [max_query_len]u8 = undefined;
    var value_buf: [max_query_len]u8 = undefined;

    var pairs = std.mem.splitScalar(u8, raw_query, '&');
    while (pairs.next()) |pair| {
        if (pair.len == 0) continue;

        const eq = std.mem.indexOfScalar(u8, pair, '=');
        const raw_key = if (eq) |i| pair[0..i] else pair;
        const raw_value = if (eq) |i| pair[i + 1 ..] else "";

        const key = decodeQueryPart(raw_key, &key_buf) orelse continue;
        if (!std.mem.eql(u8, key, field)) continue;

        const value = decodeQueryPart(raw_value, &value_buf) orelse
            return raise(L, "request.query: query value too long", .{});
        luau.pushLString(L, value);
        return 1;
    }

    return 0;
}

fn decodeQueryPart(raw: []const u8, out: []u8) ?[]const u8 {
    var pos: usize = 0;
    var i: usize = 0;
    while (i < raw.len) {
        const c = raw[i];
        if (c == '+') {
            if (pos == out.len) return null;
            out[pos] = ' ';
            pos += 1;
            i += 1;
            continue;
        }
        if (c == '%' and i + 2 < raw.len) {
            if (hexValue(raw[i + 1])) |hi| {
                if (hexValue(raw[i + 2])) |lo| {
                    if (pos == out.len) return null;
                    out[pos] = hi * 16 + lo;
                    pos += 1;
                    i += 3;
                    continue;
                }
            }
        }
        if (pos == out.len) return null;
        out[pos] = c;
        pos += 1;
        i += 1;
    }
    return out[0..pos];
}

fn hexValue(c: u8) ?u8 {
    return switch (c) {
        '0'...'9' => c - '0',
        'a'...'f' => c - 'a' + 10,
        'A'...'F' => c - 'A' + 10,
        else => null,
    };
}

fn raise(L: *luau.State, comptime fmt: []const u8, args: anytype) c_int {
    var buf: [256]u8 = undefined;
    const msg: []const u8 = std.fmt.bufPrint(&buf, fmt, args) catch "request: internal error";
    luau.pushLString(L, msg);
    return luau.errorRaise(L);
}
