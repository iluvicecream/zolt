const std = @import("std");
const luau = @import("zolt_luau");
const HttpRsp = @import("../protocol/http_rsp.zig").HttpRsp;
const script_cache = @import("../script_cache.zig");

const Io = std.Io;

pub const packages = struct {
    pub const echo = @import("packages/echo.zig");
    pub const require = @import("packages/require.zig");
    pub const response = @import("packages/response.zig");
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
    rsp: ?*HttpRsp = null,
    allocator: std.mem.Allocator,
    io: Io,
    cache: *script_cache.ScriptCache,
    current_requirer: ?[]const u8 = null,
    loading_paths: [max_require_depth][]const u8 = undefined,
    loading_count: usize = 0,

    pub const max_require_depth = 32;

    pub fn init(allocator: std.mem.Allocator, cache: *script_cache.ScriptCache) !Runtime {
        const L = luau.newState() orelse return error.LuauInitFailed;
        errdefer luau.close(L);
        luau.savePristineGlobals(L);
        return .{
            .L = L,
            .allocator = allocator,
            .io = undefined,
            .cache = cache,
        };
    }

    pub fn deinit(self: *Runtime) void {
        luau.close(self.L);
        self.* = undefined;
    }

    pub fn beginRequest(self: *Runtime, rsp: *HttpRsp) void {
        self.rsp = rsp;
        rsp.reset();
        luau.pushSandboxEnv(self.L);
    }

    pub fn endRequest(self: *Runtime) void {
        luau.settop(self.L, 0);
        luau.gcStep(self.L, 64);
        self.rsp = null;
        self.current_requirer = null;
        self.loading_count = 0;
    }

    pub fn register(self: *Runtime, name: [:0]const u8, ctx: ?*anyopaque, f: CFunction) void {
        luau.registerFunction(self.L, -1, name, ctx, f);
    }

    pub fn run(self: *Runtime, chunk_name: [:0]const u8, requirer: []const u8, bytecode: []const u8) !void {
        luau.pushTracebackHandler(self.L); // [env, handler]
        try luau.loadBytecode(self.L, chunk_name, bytecode, -2); // env at -2, chunk on top
        const prev_requirer = self.current_requirer;
        self.current_requirer = requirer;
        defer self.current_requirer = prev_requirer;
        try luau.pcall(self.L, 0, 1, -2); // handler at -2, chunk at top
    }

    pub fn errorMessage(self: *Runtime) []const u8 {
        return luau.errorMessage(self.L);
    }

    pub fn compileErrorMessage(self: *Runtime, chunk_name: [:0]const u8, bytecode: []const u8) []const u8 {
        _ = luau.loadBytecode(self.L, chunk_name, bytecode, -1) catch {};
        return self.errorMessage();
    }

    pub fn isLoading(self: *Runtime, path: []const u8) bool {
        for (self.loading_paths[0..self.loading_count]) |loading| {
            if (std.mem.eql(u8, loading, path)) return true;
        }
        return false;
    }

    pub fn pushLoading(self: *Runtime, path: []const u8) void {
        if (self.loading_count < self.loading_paths.len) {
            self.loading_paths[self.loading_count] = path;
            self.loading_count += 1;
        }
    }

    pub fn popLoading(self: *Runtime) void {
        if (self.loading_count > 0) self.loading_count -= 1;
    }
};
