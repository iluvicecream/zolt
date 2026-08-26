const std = @import("std");
const luau = @import("zolt_luau");
const HttpRsp = @import("../../protocol/http_rsp.zig").HttpRsp;

pub fn register(L: *luau.State, rsp: *HttpRsp) void {
    luau.registerFunction(L, -1, "echo", rsp, luaEcho);
}

fn luaEcho(L: *luau.State) callconv(.c) c_int {
    const raw_rsp = luau.upvaluePtr(L, 1) orelse return 0;
    const rsp: *HttpRsp = @ptrCast(@alignCast(raw_rsp));

    const argc: usize = @intCast(luau.getTop(L));
    for (0..argc) |i| {
        const index: c_int = @intCast(i + 1);
        if (luau.getString(L, index)) |s| rsp.append(s);
    }
    return 0;
}
