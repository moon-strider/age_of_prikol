const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "game",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });
    const raylib = raylib_dep.module("raylib");
    const raylib_artifact = raylib_dep.artifact("raylib");

    exe.root_module.addImport("raylib", raylib);
    exe.linkLibrary(raylib_artifact);

    b.installArtifact(exe);

    const install_shaders = b.addInstallDirectory(.{
        .source_dir = b.path("shaders"),
        .install_dir = .{ .custom = "" },
        .install_subdir = "shaders",
    });
    b.getInstallStep().dependOn(&install_shaders.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.setCwd(b.path("."));

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
