const std = @import("std");

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
        .root_source_file = b.path("src/luau/luau.zig"),
        .target = target,
        .optimize = optimize,
        .link_libcpp = true,
    });
    luau_mod.linkLibrary(luau_lib);

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
