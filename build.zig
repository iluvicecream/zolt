const std = @import("std");

const Io = std.Io;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("zolt", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    const mod_protocol = b.addModule("zolt_protocol", .{
        .root_source_file = b.path("src/protocol/protocol.zig"),
        .target = target,
    });

    const luau_dep = b.dependency("luau", .{});
    const luau_lib = buildLuau(b, luau_dep, target, optimize);

    const luau_mod = b.addModule("zolt_luau", .{
        .root_source_file = b.path("src/runtime/luau.zig"),
        .target = target,
        .optimize = optimize,
        .link_libcpp = true,
    });
    luau_mod.linkLibrary(luau_lib);

    const stdlib_module = addEmbeddedStdlib(b, target, optimize);
    mod.addImport("zolt_stdlib", stdlib_module);

    mod.addImport("zolt_luau", luau_mod);

    const exe = b.addExecutable(.{
        .name = "zoltd",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{ .{ .name = "zolt", .module = mod }, .{ .name = "zolt_protocol", .module = mod_protocol } },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
}

fn addEmbeddedStdlib(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Module {
    const wf = b.addWriteFiles();
    _ = wf.addCopyDirectory(b.path("std_lib"), "std_lib", .{});

    const io = b.graph.io;
    const std_lib_path = b.pathFromRoot("std_lib");
    var dir = Io.Dir.cwd().openDir(io, std_lib_path, .{ .iterate = true }) catch |err| {
        std.debug.print("error: cannot open std_lib directory: {s}\n", .{@errorName(err)});
        std.process.exit(2);
    };
    defer dir.close(io);

    var walker = Io.Dir.walk(dir, b.allocator) catch |err| {
        std.debug.print("error: cannot walk std_lib directory: {s}\n", .{@errorName(err)});
        std.process.exit(2);
    };
    defer walker.deinit();

    var rel_paths: std.ArrayList([]const u8) = .empty;
    defer rel_paths.deinit(b.allocator);

    while (true) {
        const entry = walker.next(io) catch |err| {
            std.debug.print("error: cannot read std_lib directory: {s}\n", .{@errorName(err)});
            std.process.exit(2);
        };
        const current = entry orelse break;
        if (current.kind != .file) continue;
        const rel = current.path;
        if (!std.mem.endsWith(u8, rel, ".luau") and !std.mem.endsWith(u8, rel, ".lua")) continue;
        rel_paths.append(b.allocator, b.dupe(rel)) catch {
            std.debug.print("error: out of memory scanning std_lib\n", .{});
            std.process.exit(2);
        };
    }

    std.mem.sort([]const u8, rel_paths.items, {}, pathLessThan);

    var out: std.ArrayList(u8) = .empty;
    defer out.deinit(b.allocator);

    out.appendSlice(b.allocator,
        \\pub const Module = struct {
        \\    spec: [:0]const u8,
        \\    source: []const u8,
        \\};
        \\
        \\pub const modules = [_]Module{
        \\
    ) catch {
        std.debug.print("error: out of memory writing std_lib manifest\n", .{});
        std.process.exit(2);
    };

    var aliases: std.ArrayList([]const u8) = .empty;
    defer aliases.deinit(b.allocator);

    for (rel_paths.items) |rel| {
        const ext: []const u8 = if (std.mem.endsWith(u8, rel, ".luau")) ".luau" else ".lua";
        const stem = rel[0 .. rel.len - ext.len];
        const alias = b.fmt("@{s}", .{stem});

        for (aliases.items) |existing| {
            if (std.mem.eql(u8, existing, alias)) {
                std.debug.print("error: duplicate std_lib module alias '{s}'\n", .{alias});
                std.process.exit(2);
            }
        }
        aliases.append(b.allocator, alias) catch {
            std.debug.print("error: out of memory writing std_lib manifest\n", .{});
            std.process.exit(2);
        };

        validateStdlibRelPath(rel);
        const line = std.fmt.allocPrint(
            b.allocator,
            "    .{{ .spec = \"{s}\", .source = @embedFile(\"std_lib/{s}\") }},\n",
            .{ alias, rel },
        ) catch {
            std.debug.print("error: out of memory writing std_lib manifest\n", .{});
            std.process.exit(2);
        };
        out.appendSlice(b.allocator, line) catch {
            std.debug.print("error: out of memory writing std_lib manifest\n", .{});
            std.process.exit(2);
        };
    }

    out.appendSlice(b.allocator, "};\n") catch {
        std.debug.print("error: out of memory writing std_lib manifest\n", .{});
        std.process.exit(2);
    };

    const manifest = wf.add("stdlib_manifest.zig", out.items);
    return b.createModule(.{
        .root_source_file = manifest,
        .target = target,
        .optimize = optimize,
    });
}

fn pathLessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
    return std.mem.lessThan(u8, lhs, rhs);
}

fn validateStdlibRelPath(path: []const u8) void {
    for (path) |c| {
        const valid = std.ascii.isAlphanumeric(c) or c == '/' or c == '_' or c == '-' or c == '.';
        if (!valid) {
            std.debug.print("error: std_lib file '{s}' contains unsupported characters\n", .{path});
            std.process.exit(2);
        }
    }
}

fn buildLuau(
    b: *std.Build,
    luau: *std.Build.Dependency,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const lib = b.addLibrary(.{
        .name = "luau",
        .linkage = .static,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libcpp = true,
        }),
    });
    const mod = lib.root_module;

    mod.addIncludePath(luau.path("Common/include"));
    mod.addIncludePath(luau.path("Ast/include"));
    mod.addIncludePath(luau.path("Bytecode/include"));
    mod.addIncludePath(luau.path("Compiler/include"));
    mod.addIncludePath(luau.path("VM/include"));
    mod.addIncludePath(luau.path("VM/src"));

    mod.addCSourceFiles(.{
        .root = luau.path(""),
        .files = &luau_sources,
        .flags = &.{
            "-DLUA_USE_LONGJMP=1",
            "-DLUA_API=extern \"C\"",
            "-DLUACODE_API=extern \"C\"",
            "-fno-math-errno",
        },
    });

    return lib;
}

const luau_sources = [_][]const u8{
    "Common/src/BytecodeWire.cpp",
    "Common/src/StringUtils.cpp",
    "Common/src/TimeTrace.cpp",

    "Ast/src/Allocator.cpp",
    "Ast/src/Ast.cpp",
    "Ast/src/Confusables.cpp",
    "Ast/src/Cst.cpp",
    "Ast/src/Lexer.cpp",
    "Ast/src/Location.cpp",
    "Ast/src/Parser.cpp",
    "Ast/src/PrettyPrinter.cpp",

    "Bytecode/src/BytecodeBuilder.cpp",
    "Bytecode/src/BytecodeGraph.cpp",
    "Bytecode/src/Sccp.cpp",

    "Compiler/src/Compiler.cpp",
    "Compiler/src/Builtins.cpp",
    "Compiler/src/BuiltinFolding.cpp",
    "Compiler/src/ConstantFolding.cpp",
    "Compiler/src/CostModel.cpp",
    "Compiler/src/TableShape.cpp",
    "Compiler/src/Types.cpp",
    "Compiler/src/ValueTracking.cpp",
    "Compiler/src/lcode.cpp",

    "VM/src/lapi.cpp",
    "VM/src/laux.cpp",
    "VM/src/lbaselib.cpp",
    "VM/src/lbitlib.cpp",
    "VM/src/lbuffer.cpp",
    "VM/src/lbuflib.cpp",
    "VM/src/lbuiltins.cpp",
    "VM/src/lcorolib.cpp",
    "VM/src/ldblib.cpp",
    "VM/src/ldebug.cpp",
    "VM/src/ldo.cpp",
    "VM/src/lfunc.cpp",
    "VM/src/lgc.cpp",
    "VM/src/lgcdebug.cpp",
    "VM/src/linit.cpp",
    "VM/src/lmathlib.cpp",
    "VM/src/lmem.cpp",
    "VM/src/lnumprint.cpp",
    "VM/src/lobject.cpp",
    "VM/src/loslib.cpp",
    "VM/src/lperf.cpp",
    "VM/src/lstate.cpp",
    "VM/src/lstring.cpp",
    "VM/src/lstrlib.cpp",
    "VM/src/ltable.cpp",
    "VM/src/ltablib.cpp",
    "VM/src/ltm.cpp",
    "VM/src/ludata.cpp",
    "VM/src/lutf8lib.cpp",
    "VM/src/lveclib.cpp",
    "VM/src/lintlib.cpp",
    "VM/src/lvmexecute.cpp",
    "VM/src/lclass.cpp",
    "VM/src/lclasslib.cpp",
    "VM/src/lvmload.cpp",
    "VM/src/lvmutils.cpp",
};
