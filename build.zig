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
