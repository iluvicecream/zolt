const std = @import("std");
const luau = @import("zolt_luau");
const runtime = @import("../runtime.zig");

const Runtime = runtime.Runtime;
const Io = std.Io;
const Dir = Io.Dir;

pub const max_module_size = 16 * 1024;

const max_path_len = 1024;
const max_msg_len = 512;

pub fn register(L: *luau.State, rt: *Runtime) void {
    const env = luau.getTop(L);
    luau.pushLightUserdata(L, rt);
    luau.pushValue(L, env);
    luau.createTable(L, 0, 0);
    luau.pushClosure(L, requireFn, "require", 3);
    luau.setField(L, env, "require");
    luau.settop(L, env);
}

fn requireFn(L: *luau.State) callconv(.c) c_int {
    const rt: *Runtime = @ptrCast(@alignCast(luau.upvaluePtr(L, 1) orelse
        return raise(L, "require: internal error (missing runtime)", .{})));

    const spec = luau.getString(L, 1) orelse
        return raise(L, "require: expected a string module path", .{});

    var path_buf: [max_path_len]u8 = undefined;
    const base_len = resolvePath(rt.current_requirer orelse "", spec, &path_buf) orelse
        return raise(L, "require: invalid module path '{s}' (must stay inside the working directory)", .{spec});
    const base = path_buf[0..base_len];

    var file_buf: [max_path_len + 8]u8 = undefined;
    var chosen: [:0]const u8 = undefined;
    if (std.fs.path.extension(base).len == 0) {
        var found = false;
        for ([_][]const u8{ "", ".luau", ".lua" }) |ext| {
            if (findFile(rt.io, base, ext, &file_buf)) |path| {
                chosen = path;
                found = true;
                break;
            }
        }
        if (!found) return raise(L, "require: module '{s}' not found", .{spec});
    } else {
        chosen = findFile(rt.io, base, "", &file_buf) orelse
            return raise(L, "require: module '{s}' not found", .{spec});
    }

    luau.pushValue(L, luau.upvalueIndex(3)); // cache
    _ = luau.getField(L, -1, chosen);
    if (luau.typeOf(L, -1) != .nil) {
        luau.pushValue(L, -1);
        luau.replace(L, 1);
        luau.settop(L, 1);
        return 1;
    }
    luau.settop(L, 1); // back to [path]

    if (rt.isLoading(chosen))
        return raise(L, "require: cyclic dependency detected while loading '{s}'", .{chosen});

    const bytecode: []const u8 = blk: {
        const lookup = rt.cache.acquire(rt.io, rt.allocator, chosen, max_module_size) catch |err|
            return raise(L, "require: failed to load module '{s}' ({s})", .{ chosen, @errorName(err) });
        switch (lookup) {
            .ok => |bc| break :blk bc,
            .not_found => return raise(L, "require: module '{s}' not found", .{spec}),
            .too_large => return raise(L, "require: module '{s}' exceeds {d} bytes", .{ chosen, max_module_size }),
            .compile_error => |blob| {
                var msg_buf: [max_msg_len]u8 = undefined;
                const msg = compileErrorMessage(L, chosen, blob, &msg_buf);
                std.c.free(@ptrCast(blob.ptr));
                return raise(L, "{s}", .{msg});
            },
        }
    };

    var chunk_buf: [max_path_len + 8]u8 = undefined;
    const chunk_name = chunkName(chosen, &chunk_buf);

    rt.pushLoading(chosen);
    const prev_requirer = rt.current_requirer;
    rt.current_requirer = chosen;

    luau.pushValue(L, luau.upvalueIndex(2)); // env
    luau.pushTracebackHandler(L); // [path, env, handler]

    luau.loadBytecode(L, chunk_name, bytecode, -2) catch {
        rt.popLoading();
        rt.current_requirer = prev_requirer;
        rt.allocator.free(bytecode);
        return raise(L, "require: failed to load module '{s}'", .{chosen});
    };

    if (luau.pcall(L, 0, 1, -2)) |_| {} else |_| {
        rt.popLoading();
        rt.current_requirer = prev_requirer;
        rt.allocator.free(bytecode);
        return luau.errorRaise(L);
    }

    if (luau.typeOf(L, -1) == .nil) {
        rt.popLoading();
        rt.current_requirer = prev_requirer;
        rt.allocator.free(bytecode);
        return raise(L, "require: module '{s}' must return a value", .{chosen});
    }

    luau.pushValue(L, luau.upvalueIndex(3)); // cache
    luau.pushValue(L, -2); // result
    luau.setField(L, -2, chosen); // cache[chosen] = result

    luau.pushValue(L, -2); // result copy
    luau.replace(L, 1);
    luau.settop(L, 1);

    rt.popLoading();
    rt.current_requirer = prev_requirer;
    rt.allocator.free(bytecode);
    return 1;
}

fn resolvePath(requirer: []const u8, spec: []const u8, out: []u8) ?usize {
    if (spec.len == 0 or spec[0] == '/') return null;
    if (std.mem.indexOfAny(u8, spec, "\\\x00") != null) return null;

    var segs: [64][]const u8 = undefined;
    var n: usize = 0;

    const dir = std.fs.path.dirname(requirer) orelse "";
    var it = std.mem.splitScalar(u8, dir, '/');
    while (it.next()) |seg| {
        if (seg.len == 0 or std.mem.eql(u8, seg, ".")) continue;
        if (n == segs.len) return null;
        segs[n] = seg;
        n += 1;
    }

    var sit = std.mem.splitScalar(u8, spec, '/');
    while (sit.next()) |seg| {
        if (seg.len == 0 or std.mem.eql(u8, seg, ".")) continue;
        if (std.mem.eql(u8, seg, "..")) {
            if (n == 0) return null; // would escape the working directory
            n -= 1;
            continue;
        }
        if (n == segs.len) return null;
        segs[n] = seg;
        n += 1;
    }

    if (n == 0) return null;

    var pos: usize = 0;
    for (segs[0..n], 0..) |seg, i| {
        if (i > 0) {
            if (pos + 1 > out.len) return null;
            out[pos] = '/';
            pos += 1;
        }
        if (pos + seg.len > out.len) return null;
        @memcpy(out[pos .. pos + seg.len], seg);
        pos += seg.len;
    }
    return pos;
}

fn findFile(io: Io, base: []const u8, ext: []const u8, out: []u8) ?[:0]const u8 {
    if (base.len + ext.len + 1 > out.len) return null;
    @memcpy(out[0..base.len], base);
    @memcpy(out[base.len .. base.len + ext.len], ext);
    out[base.len + ext.len] = 0;
    const path = out[0 .. base.len + ext.len :0];

    const stat = Dir.statFile(.cwd(), io, path, .{ .follow_symlinks = false }) catch return null;
    if (stat.kind != .file) return null;
    return path;
}

fn compileErrorMessage(L: *luau.State, path: [:0]const u8, bytecode: []const u8, buf: []u8) []const u8 {
    var chunk_buf: [max_path_len + 8]u8 = undefined;
    const chunk_name = chunkName(path, &chunk_buf);
    _ = luau.loadBytecode(L, chunk_name, bytecode, -1) catch {};
    const msg = luau.errorMessage(L);
    const n = @min(msg.len, buf.len);
    @memcpy(buf[0..n], msg[0..n]);
    luau.settop(L, 1); // restore [path]
    return buf[0..n];
}

fn chunkName(path: [:0]const u8, buf: []u8) [:0]const u8 {
    return std.fmt.bufPrintZ(buf, "={s}", .{path}) catch "=require";
}

fn raise(L: *luau.State, comptime fmt: []const u8, args: anytype) c_int {
    var buf: [max_msg_len]u8 = undefined;
    const msg: []const u8 = std.fmt.bufPrint(&buf, fmt, args) catch "require: internal error";
    luau.pushLString(L, msg);
    return luau.errorRaise(L);
}
