const std = @import("std");
const luau = @import("zolt_luau");
const manifest = @import("zolt_stdlib");

pub const Module = struct {
    spec: [:0]const u8,
    bytecode: []const u8,
};

pub const Catalog = struct {
    allocator: std.mem.Allocator,
    modules: []Module,

    pub fn init(allocator: std.mem.Allocator) !Catalog {
        const modules = try allocator.alloc(Module, manifest.modules.len);
        var ready: usize = 0;
        errdefer {
            for (modules[0..ready]) |module| {
                std.c.free(@constCast(module.bytecode.ptr));
            }
            allocator.free(modules);
        }

        for (manifest.modules, 0..) |source_module, i| {
            var out_size: usize = 0;
            const bytecode = luau.compile(source_module.source, &out_size) orelse
                return error.OutOfMemory;
            if (luau.isCompileError(bytecode)) {
                std.c.free(@ptrCast(bytecode.ptr));
                return error.StdlibCompileError;
            }
            modules[i] = .{
                .spec = source_module.spec,
                .bytecode = bytecode[0..out_size],
            };
            ready = i + 1;
        }

        return .{
            .allocator = allocator,
            .modules = modules,
        };
    }

    pub fn deinit(self: *Catalog) void {
        for (self.modules) |module| {
            std.c.free(@constCast(module.bytecode.ptr));
        }
        self.allocator.free(self.modules);
        self.* = undefined;
    }

    pub fn find(self: *const Catalog, spec: []const u8) ?*const Module {
        for (self.modules) |*module| {
            if (std.mem.eql(u8, module.spec, spec)) return module;
        }
        return null;
    }
};
