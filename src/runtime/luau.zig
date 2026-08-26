const std = @import("std");

pub const State = opaque {};

const LUA_GLOBALSINDEX: c_int = -10002;
const LUA_REGISTRYINDEX: c_int = -10000;

const GCOp = enum(c_int) {
    stop = 0,
    restart = 1,
    collect = 2,
    count = 3,
    count_b = 4,
    is_running = 5,
    step = 6,
    set_goal = 7,
    set_step_mul = 8,
    set_step_size = 9,
};

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
extern fn lua_pushlstring(L: *State, s: [*]const u8, len: usize) void;
extern fn lua_pushnil(L: *State) void;
extern fn lua_next(L: *State, idx: c_int) c_int;
extern fn lua_rawget(L: *State, idx: c_int) void;
extern fn lua_rawset(L: *State, idx: c_int) void;
extern fn lua_remove(L: *State, idx: c_int) void;
extern fn lua_replace(L: *State, idx: c_int) void;
extern fn lua_tolstring(L: *State, idx: c_int, len: ?*usize) ?[*:0]const u8;
extern fn lua_tonumberx(L: *State, idx: c_int, isnum: ?*c_int) f64;
extern fn lua_toboolean(L: *State, idx: c_int) c_int;
extern fn lua_touserdata(L: *State, idx: c_int) ?*anyopaque;
extern fn lua_pcall(L: *State, nargs: c_int, nresults: c_int, errfunc: c_int) c_int;
extern fn lua_error(L: *State) c_int;
extern fn lua_gc(L: *State, what: c_int, data: c_int) c_int;
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
    return bytecode[0..out_size.*];
}

pub fn isCompileError(bytecode: []const u8) bool {
    return bytecode.len > 0 and bytecode[0] == 0;
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

pub fn pcall(L: *State, nargs: c_int, nresults: c_int, errfunc: c_int) RunError!void {
    if (lua_pcall(L, nargs, nresults, errfunc) != 0)
        return error.RuntimeError;
}

pub fn pushTracebackHandler(L: *State) void {
    _ = lua_getfield(L, LUA_GLOBALSINDEX, "debug");
    _ = lua_getfield(L, -1, "traceback");
    lua_remove(L, -2); // drop the debug table, keep the handler
}

pub fn runString(L: *State, chunk_name: [:0]const u8, source: []const u8) RunError!void {
    try loadString(L, chunk_name, source);
    try pcall(L, 0, 0, 0);
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

pub fn upvalueIndex(n: c_int) c_int {
    return LUA_GLOBALSINDEX - n;
}

pub fn pushLightUserdata(L: *State, p: ?*anyopaque) void {
    lua_pushlightuserdatatagged(L, p, 0);
}

pub fn pushValue(L: *State, idx: c_int) void {
    lua_pushvalue(L, idx);
}

pub fn createTable(L: *State, narr: c_int, nrec: c_int) void {
    lua_createtable(L, narr, nrec);
}

pub fn pushClosure(L: *State, f: CFunction, debugname: [:0]const u8, nup: c_int) void {
    lua_pushcclosurek(L, f, debugname.ptr, nup, null);
}

pub fn setField(L: *State, index: c_int, key: [:0]const u8) void {
    lua_setfield(L, index, key.ptr);
}

pub fn replace(L: *State, index: c_int) void {
    lua_replace(L, index);
}

pub fn pushLString(L: *State, s: []const u8) void {
    lua_pushlstring(L, s.ptr, s.len);
}

pub fn errorRaise(L: *State) c_int {
    return lua_error(L);
}

var pristine_globals_key: u8 = 0;

pub fn savePristineGlobals(L: *State) void {
    lua_pushlightuserdatatagged(L, &pristine_globals_key, 0);
    lua_pushvalue(L, LUA_GLOBALSINDEX);
    lua_rawset(L, LUA_REGISTRYINDEX);
}

pub fn pushSandboxEnv(L: *State) void {
    lua_pushlightuserdatatagged(L, &pristine_globals_key, 0); // key
    lua_rawget(L, LUA_REGISTRYINDEX); // [pristine]
    lua_createtable(L, 0, 32); // [pristine, env]
    lua_pushnil(L); // [pristine, env, nil]
    while (lua_next(L, -3) != 0) { // [pristine, env, key, value]
        lua_pushvalue(L, -2); // [pristine, env, key, value, key]
        lua_pushvalue(L, -2); // [pristine, env, key, value, key, value]
        lua_rawset(L, -5); // env[key] = value; [pristine, env, key, value]
        lua_settop(L, -2); // drop value, keep key; [pristine, env, key]
    } // [pristine, env]
    lua_pushvalue(L, -1); // [pristine, env, env]
    lua_setfield(L, -2, "_G"); // env._G = env; [pristine, env]
    lua_pushvalue(L, -1); // [pristine, env, env]
    lua_replace(L, LUA_GLOBALSINDEX); // L->gt = env; [pristine, env]
    lua_remove(L, 1); // [env]
}

pub fn gcStep(L: *State, kb: c_int) void {
    _ = lua_gc(L, @intFromEnum(GCOp.step), kb);
}

pub fn getFieldNumber(L: *State, index: c_int, key: [:0]const u8) ?f64 {
    _ = lua_getfield(L, index, key.ptr);
    defer lua_settop(L, index - 1);
    var isnum: c_int = 0;
    const n = lua_tonumberx(L, -1, &isnum);
    return if (isnum != 0) n else null;
}

pub fn getFieldBoolean(L: *State, index: c_int, key: [:0]const u8) ?bool {
    _ = lua_getfield(L, index, key.ptr);
    defer lua_settop(L, index - 1);
    if (typeOf(L, -1) != .boolean) return null;
    return lua_toboolean(L, -1) != 0;
}
