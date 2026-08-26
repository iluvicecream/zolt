const std = @import("std");
const luau = @import("zolt_luau");
const Response = @import("../response.zig").Response;

pub fn register(L: *luau.State, response: *Response) void {
    luau.registerFunction(L, -1, "echo", response, luaEcho);
}

fn luaEcho(L: *luau.State) callconv(.c) c_int {
    const raw_response = luau.upvaluePtr(L, 1) orelse return 0;
    const response: *Response = @ptrCast(@alignCast(raw_response));

    const argc: usize = @intCast(luau.getTop(L));
    for (0..argc) |i| {
        const index: c_int = @intCast(i + 1);
        if (luau.getString(L, index)) |s| response.append(s);
    }
    return 0;
}
