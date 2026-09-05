const std = @import("std");

pub fn build(b: *std.Build) void {
    const sdk_build = b.lazyImport(@This(), "r4os_sdk") orelse return;
    const dependency = b.dependencyFromBuildZig(sdk_build, .{});
    const sdk = sdk_build.sdk(b, dependency, .{});
    _ = sdk.addR4MFWithOptions(b.path("module.R4MF"), .{ .zig_module_roots = &.{ b.path("../../Kernel/storage/installation.zig"), dependency.path("r4os/ntfs_volume.zig"), b.path("src/ntfs_format.zig") } });
    const test_module = b.createModule(.{
        .root_source_file = b.path("src/tests.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    test_module.addImport("r4os", sdk.createR4osModule(b.graph.host, .Debug));
    test_module.addImport("installation", b.createModule(.{ .root_source_file = b.path("../../Kernel/storage/installation.zig") }));
    const tests = b.addTest(.{ .root_module = test_module });
    const run = b.addRunArtifact(tests);
    b.step("view-test", "Recovery clipping, target identity and readable OS markers").dependOn(&run.step);
}
