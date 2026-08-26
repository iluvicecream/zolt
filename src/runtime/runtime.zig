const std = @import("std");
const luau = @import("zolt_luau");
const Response = @import("response.zig").Response;

pub const packages = struct {
    pub const echo = @import("packages/echo.zig");
};

pub const State = luau.State;
pub const CFunction = luau.CFunction;

pub fn compile(source: []const u8, out_size: *usize) ?[]u8 {
    return luau.compile(source, out_size);
}

pub fn isCompileError(bytecode: []const u8) bool {
    return luau.isCompileError(bytecode);
}

pub const Runtime = struct {
    L: *luau.State,
    response: Response = .{},

    pub fn init() !Runtime {
        const L = luau.newState() orelse return error.LuauInitFailed;
        errdefer luau.close(L);
        return .{ .L = L };
    }

    pub fn deinit(self: *Runtime) void {
        luau.close(self.L);
        self.* = undefined;
    }

    pub fn beginRequest(self: *Runtime) void {
        luau.pushSandboxEnv(self.L);
        self.response.reset();
    }

    pub fn endRequest(self: *Runtime) void {
        luau.settop(self.L, 0);
    }

    pub fn register(self: *Runtime, name: [:0]const u8, ctx: ?*anyopaque, f: CFunction) void {
        luau.registerFunction(self.L, -1, name, ctx, f);
    }

    pub fn run(self: *Runtime, chunk_name: [:0]const u8, bytecode: []const u8) !void {
        luau.pushTracebackHandler(self.L); // [env, handler]
        try luau.loadBytecode(self.L, chunk_name, bytecode, -2); // env at -2, chunk on top
        try luau.pcall(self.L, 0, 1, -2); // handler at -2, chunk at top
    }

    pub fn errorMessage(self: *Runtime) []const u8 {
        return luau.errorMessage(self.L);
    }

    pub fn compileErrorMessage(self: *Runtime, chunk_name: [:0]const u8, bytecode: []const u8) []const u8 {
        _ = luau.loadBytecode(self.L, chunk_name, bytecode, -1) catch {};
        return self.errorMessage();
    }
};
