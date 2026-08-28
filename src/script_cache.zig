const std = @import("std");
const luau = @import("zolt_luau");

const Io = std.Io;
const Dir = Io.Dir;

pub const ScriptCache = struct {
    pub const max_cached_scripts = 256;

    const freshness_interval_ns: i96 = 1_000_000_000;

    mutex: Io.Mutex = .init,
    entries: std.StringHashMapUnmanaged(Entry) = .{},
    allocator: std.mem.Allocator,
    max_entries: usize,
    seq: u64 = 0,

    const Entry = struct {
        mtime: Io.Timestamp,
        size: u64,
        bytecode: []u8,
        last_used: u64,
        last_checked: i96,
    };

    pub const Lookup = union(enum) {
        ok: []u8,
        compile_error: []u8,
        not_found,
        too_large,
    };

    pub fn init(allocator: std.mem.Allocator, max_entries: usize) ScriptCache {
        return .{
            .allocator = allocator,
            .max_entries = @max(max_entries, 1),
        };
    }

    pub fn deinit(self: *ScriptCache, io: Io) void {
        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);
        var it = self.entries.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            std.c.free(@ptrCast(entry.value_ptr.bytecode.ptr));
        }
        self.entries.deinit(self.allocator);
    }

    pub fn acquire(
        self: *ScriptCache,
        root: Dir,
        io: Io,
        allocator: std.mem.Allocator,
        path: []const u8,
        max_size: usize,
    ) !Lookup {
        const now = Io.Timestamp.now(io, .awake).nanoseconds;

        self.mutex.lockUncancelable(io);
        if (self.entries.getPtr(path)) |entry| {
            if (now - entry.last_checked < freshness_interval_ns) {
                const copy = allocator.dupe(u8, entry.bytecode) catch |err| {
                    self.mutex.unlock(io);
                    return err;
                };
                self.touch(entry);
                self.mutex.unlock(io);
                return .{ .ok = copy };
            }
        }
        self.mutex.unlock(io);

        const stat = Dir.statFile(root, io, path, .{ .follow_symlinks = false }) catch |err| switch (err) {
            error.FileNotFound => return .not_found,
            else => return err,
        };
        if (stat.kind != .file) return .not_found;

        self.mutex.lockUncancelable(io);
        if (self.entries.getPtr(path)) |entry| {
            if (entry.mtime.nanoseconds == stat.mtime.nanoseconds and entry.size == stat.size) {
                entry.last_checked = now;
                const copy = allocator.dupe(u8, entry.bytecode) catch |err| {
                    self.mutex.unlock(io);
                    return err;
                };
                self.touch(entry);
                self.mutex.unlock(io);
                return .{ .ok = copy };
            }
        }
        self.mutex.unlock(io);

        const content = Dir.readFileAlloc(root, io, path, allocator, .limited(max_size)) catch |err| switch (err) {
            error.StreamTooLong => return .too_large,
            else => return err,
        };
        defer allocator.free(content);

        var out_size: usize = 0;
        const bytecode = luau.compile(content, &out_size) orelse return error.OutOfMemory;

        if (luau.isCompileError(bytecode)) {
            return .{ .compile_error = bytecode[0..out_size] };
        }

        const owned_path = allocator.dupe(u8, path) catch |err| {
            std.c.free(@ptrCast(bytecode.ptr));
            return err;
        };

        self.mutex.lockUncancelable(io);
        defer self.mutex.unlock(io);

        if (self.entries.getPtr(path)) |entry| {
            if (entry.mtime.nanoseconds == stat.mtime.nanoseconds and entry.size == stat.size) {
                const copy = allocator.dupe(u8, entry.bytecode) catch |err| {
                    allocator.free(owned_path);
                    std.c.free(@ptrCast(bytecode.ptr));
                    return err;
                };
                allocator.free(owned_path);
                std.c.free(@ptrCast(bytecode.ptr));
                self.touch(entry);
                return .{ .ok = copy };
            }
            self.remove(path);
        }

        if (self.entries.count() >= self.max_entries) self.evictLru();

        self.entries.put(allocator, owned_path, .{
            .mtime = stat.mtime,
            .size = stat.size,
            .bytecode = bytecode,
            .last_used = self.seq,
            .last_checked = now,
        }) catch |err| {
            allocator.free(owned_path);
            std.c.free(@ptrCast(bytecode.ptr));
            return err;
        };
        self.seq += 1;

        return .{ .ok = try allocator.dupe(u8, bytecode) };
    }

    fn touch(self: *ScriptCache, entry: *Entry) void {
        entry.last_used = self.seq;
        self.seq += 1;
    }

    fn remove(self: *ScriptCache, path: []const u8) void {
        if (self.entries.fetchRemove(path)) |kv| {
            self.allocator.free(kv.key);
            std.c.free(@ptrCast(kv.value.bytecode.ptr));
        }
    }

    fn evictLru(self: *ScriptCache) void {
        var oldest_key: ?[]const u8 = null;
        var oldest_used: u64 = std.math.maxInt(u64);
        var it = self.entries.iterator();
        while (it.next()) |entry| {
            if (entry.value_ptr.last_used < oldest_used) {
                oldest_used = entry.value_ptr.last_used;
                oldest_key = entry.key_ptr.*;
            }
        }
        if (oldest_key) |key| self.remove(key);
    }
};
