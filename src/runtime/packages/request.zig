const std = @import("std");
const luau = @import("zolt_luau");

pub fn register(L: *luau.State, path: []const u8) void {
    const env = luau.getTop(L);
    luau.pushLString(L, path); // env + 1: path string
    luau.pushClosure(L, luaRequestPath, "request.path", 1); // consumes path, pushes closure: env + 1
    luau.createTable(L, 0, 1); // env + 2: request table
    luau.pushValue(L, -2); // env + 3: closure copy
    luau.setField(L, env + 2, "path"); // request.path = closure
    luau.setField(L, env, "request"); // env.request = request
    luau.settop(L, env);
}

fn luaRequestPath(L: *luau.State) callconv(.c) c_int {
    luau.pushValue(L, luau.upvalueIndex(1));
    return 1;
}
