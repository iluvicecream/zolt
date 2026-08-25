const std = @import("std");

pub const State = opaque {};

const LUA_GLOBALSINDEX: c_int = -10002;

pub const CFunction = *const fn (L: *State) callconv(.c) c_int;

extern fn luaL_newstate() ?*State;
extern fn luaL_openlibs(L: *State) void;
extern fn lua_close(L: *State) void;
extern fn lua_createtable(L: *State, narr: c_int, nrec: c_int) void;
extern fn lua_getfield(L: *State, idx: c_int, k: [*:0]const u8) c_int;
extern fn lua_gettop(L: *State) c_int;
extern fn lua_settop(L: *State, idx: c_int) void;
extern fn lua_setmetatable(L: *State, objindex: c_int) c_int;
extern fn lua_setfield(L: *State, idx: c_int, k: [*:0]const u8) void;
extern fn lua_pushvalue(L: *State, idx: c_int) void;
extern fn lua_pushcclosurek(L: *State, f: CFunction, debugname: ?[*:0]const u8, nup: c_int, cont: ?*anyopaque) void;
extern fn lua_pushlightuserdatatagged(L: *State, p: ?*anyopaque, tag: c_int) void;
extern fn lua_tolstring(L: *State, idx: c_int, len: ?*usize) ?[*:0]const u8;
extern fn lua_tonumberx(L: *State, idx: c_int, isnum: ?*c_int) f64;
extern fn lua_touserdata(L: *State, idx: c_int) ?*anyopaque;
extern fn lua_pcall(L: *State, nargs: c_int, nresults: c_int, errfunc: c_int) c_int;
extern fn luau_load(L: *State, chunkname: [*:0]const u8, data: [*]const u8, size: usize, env: c_int) c_int;
extern fn luau_compile(source: [*]const u8, size: usize, options: ?*anyopaque, outsize: *usize) ?[*]u8;
extern fn lua_type(L: *State, index: c_int) c_int;

pub const Type = enum(c_int) {
    none = -1,
    nil = 0,
    boolean = 1,
    light_userdata = 2,
    number = 3,
    integer = 4,
    vector = 5,
    string = 6,
    table = 7,
    function = 8,
    userdata = 9,
    thread = 10,
    buffer = 11,
    class = 12,
    object = 13,
    _,
};

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

pub fn compile(source: []const u8, out_size: *usize) ?[]u8 {
    const bytecode = luau_compile(source.ptr, source.len, null, out_size) orelse return null;
    if (bytecode[0] == 0) {
        std.c.free(@ptrCast(bytecode));
        return null;
    }
    return bytecode[0..out_size.*];
}

pub fn loadBytecode(L: *State, chunk_name: [:0]const u8, bytecode: []const u8, env: c_int) RunError!void {
    if (luau_load(L, chunk_name.ptr, bytecode.ptr, bytecode.len, env) != 0)
        return error.CompileFailed;
}

pub fn loadString(L: *State, chunk_name: [:0]const u8, source: []const u8) RunError!void {
    var out_size: usize = 0;
    const bytecode = compile(source, &out_size) orelse
        return error.CompileFailed;
    defer std.c.free(@ptrCast(bytecode));
    try loadBytecode(L, chunk_name, bytecode, 0);
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

pub fn getTop(L: *State) c_int {
    return lua_gettop(L);
}

pub fn typeOf(L: *State, index: c_int) Type {
    return @enumFromInt(lua_type(L, index));
}

pub fn getFieldString(L: *State, index: c_int, key: [:0]const u8) ?[]const u8 {
    _ = lua_getfield(L, index, key.ptr);
    defer lua_settop(L, index - 1);
    const str = lua_tolstring(L, -1, null);
    return if (str) |s| std.mem.span(s) else null;
}

pub fn getField(L: *State, index: c_int, key: [:0]const u8) void {
    _ = lua_getfield(L, index, key.ptr);
}

pub fn getString(L: *State, index: c_int) ?[]const u8 {
    const str = lua_tolstring(L, index, null);
    return if (str) |s| std.mem.span(s) else null;
}

pub fn registerFunction(L: *State, table_index: c_int, name: [:0]const u8, ctx: ?*anyopaque, f: CFunction) void {
    const table_abs: c_int = if (table_index < 0)
        lua_gettop(L) + table_index + 1
    else
        table_index;
    lua_pushlightuserdatatagged(L, ctx, 0);
    lua_pushcclosurek(L, f, name.ptr, 1, null);
    lua_setfield(L, table_abs, name.ptr);
}

pub fn upvaluePtr(L: *State, n: c_int) ?*anyopaque {
    return lua_touserdata(L, LUA_GLOBALSINDEX - n);
}

pub fn pushSandboxEnv(L: *State) void {
    lua_createtable(L, 0, 4); // env
    lua_createtable(L, 0, 1); // metatable
    _ = lua_getfield(L, LUA_GLOBALSINDEX, "_G");
    lua_setfield(L, -2, "__index");
    _ = lua_setmetatable(L, -2);
    lua_pushvalue(L, -1);
    lua_setfield(L, -2, "_G");
}

pub fn getFieldNumber(L: *State, index: c_int, key: [:0]const u8) ?f64 {
    _ = lua_getfield(L, index, key.ptr);
    defer lua_settop(L, index - 1);
    var isnum: c_int = 0;
    const n = lua_tonumberx(L, -1, &isnum);
    return if (isnum != 0) n else null;
}
