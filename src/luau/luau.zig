const std = @import("std");

pub const State = opaque {};

const LUA_GLOBALSINDEX: c_int = -10002;

extern fn luaL_newstate() ?*State;
extern fn luaL_openlibs(L: *State) void;
extern fn lua_close(L: *State) void;
extern fn lua_getfield(L: *State, idx: c_int, k: [*:0]const u8) c_int;
extern fn lua_settop(L: *State, idx: c_int) void;
extern fn lua_tolstring(L: *State, idx: c_int, len: ?*usize) ?[*:0]const u8;
extern fn lua_tonumberx(L: *State, idx: c_int, isnum: ?*c_int) f64;
extern fn lua_pcall(L: *State, nargs: c_int, nresults: c_int, errfunc: c_int) c_int;
extern fn luau_load(L: *State, chunkname: [*:0]const u8, data: [*]const u8, size: usize, env: c_int) c_int;
extern fn luau_compile(source: [*]const u8, size: usize, options: ?*anyopaque, outsize: *usize) ?[*]u8;

pub const RunError = error{
    CompileFailed,
    RuntimeError,
};

pub fn newState() ?*State {
    const L = luaL_newstate();
    if (L) |state| luaL_openlibs(state);
    return L;
}

pub fn close(L: *State) void {
    lua_close(L);
}

pub fn version(L: *State) []const u8 {
    _ = lua_getfield(L, LUA_GLOBALSINDEX, "_VERSION");
    defer lua_settop(L, -2);
    const str = lua_tolstring(L, -1, null);
    return if (str) |s| std.mem.span(s) else "unknown";
}

pub fn loadString(L: *State, chunk_name: [:0]const u8, source: []const u8) RunError!void {
    var out_size: usize = 0;
    const bytecode = luau_compile(source.ptr, source.len, null, &out_size) orelse
        return error.CompileFailed;
    defer std.c.free(@ptrCast(bytecode));

    if (bytecode[0] == 0)
        return error.CompileFailed;

    if (luau_load(L, chunk_name.ptr, bytecode, out_size, 0) != 0)
        return error.CompileFailed;
}

pub fn pcall(L: *State, nargs: c_int, nresults: c_int) RunError!void {
    if (lua_pcall(L, nargs, nresults, 0) != 0)
        return error.RuntimeError;
}

pub fn runString(L: *State, chunk_name: [:0]const u8, source: []const u8) RunError!void {
    try loadString(L, chunk_name, source);
    try pcall(L, 0, 0);
}

pub fn tonumber(L: *State, index: c_int) ?f64 {
    return lua_tonumberx(L, index, null);
}

pub fn errorMessage(L: *State) []const u8 {
    const str = lua_tolstring(L, -1, null);
    return if (str) |s| std.mem.span(s) else "(no message)";
}

pub fn settop(L: *State, index: c_int) void {
    lua_settop(L, index);
}
