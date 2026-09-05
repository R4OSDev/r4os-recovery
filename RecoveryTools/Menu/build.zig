const std = @import("std");

pub fn build(b: *std.Build) void {
    const sdk_build = b.lazyImport(@This(), "r4os_sdk") orelse return;
    const dependency = b.dependencyFromBuildZig(sdk_build, .{});
    const sdk = sdk_build.sdk(b, dependency, .{});
    _ = sdk.addR4MF(b.path("module.R4MF"));
    const tests = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("src/view.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    }) });
    const run = b.addRunArtifact(tests);
    b.step("view-test", "Recovery image geometry and console clipping").dependOn(&run.step);
}
