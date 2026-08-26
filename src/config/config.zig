const std = @import("std");

const luau = @import("zolt_luau");

const Io = std.Io;
const Dir = Io.Dir;

pub const Config = struct {
    host: []const u8,
    is_show_runtime_error: bool,
    max_connections: usize,

    pub const max_content_size = 16 * 1024;
    pub const default_max_connections = 64;

    // Load the config file, run it
    // and extract returned table for host value
    pub fn load(io: Io, allocator: std.mem.Allocator, path: []const u8) !Config {
        const content = try Dir.readFileAlloc(.cwd(), io, path, allocator, .limited(max_content_size));
        defer allocator.free(content);

        const L = luau.newState() orelse {
            std.log.err("config loader failed to create luau state", .{});
            return error.ConfigEvalFailed;
        };
        defer luau.close(L);

        luau.loadString(L, "=config.lua", content) catch {
            std.log.err("config lua compile error err={s}", .{luau.errorMessage(L)});
            return error.ConfigEvalFailed;
        };
        luau.pcall(L, 0, 1, 0) catch {
            std.log.err("config lua runtime error err={s}", .{luau.errorMessage(L)});
            return error.ConfigEvalFailed;
        };
        defer luau.settop(L, -2); // drop the returned table

        if (luau.typeOf(L, -1) != .table) {
            std.log.err("config lua expected it to return a table", .{});
            return error.ConfigEvalFailed;
        }

        const host = luau.getFieldString(L, -1, "host") orelse {
            std.log.err("config lua missing string field 'host'", .{});
            return error.ConfigEvalFailed;
        };

        const host_owned = try allocator.dupe(u8, host);
        errdefer allocator.free(host_owned);

        const is_show_runtime_error = luau.getFieldBoolean(L, -1, "isShowRuntimeError") orelse false;

        const raw_max_connections = luau.getFieldNumber(L, -1, "maxConnections") orelse default_max_connections;
        const max_connections: usize = @intFromFloat(@min(@max(raw_max_connections, 1), 65536));

        std.log.info("config loaded from {s}", .{path});

        return .{
            .host = host_owned,
            .is_show_runtime_error = is_show_runtime_error,
            .max_connections = max_connections,
        };
    }

    pub fn deinit(self: *Config, allocator: std.mem.Allocator) void {
        allocator.free(self.host);
        self.* = undefined;
    }
};
