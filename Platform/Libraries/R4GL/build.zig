const std = @import("std");
pub fn build(b: *std.Build) void {
    b.addNamedLazyPath("binding", b.path("Bindings/Zig/r4gl.zig"));
    b.addNamedLazyPath("c_include", b.path("Bindings/C"));
    const sdk_build = b.lazyImport(@This(), "r4os_sdk") orelse return;
    const sdk = sdk_build.sdk(b, b.dependencyFromBuildZig(sdk_build, .{}), .{});
    const native = b.addSystemCommand(&.{ "pwsh", "-NoLogo", "-NoProfile", "-File" });
    native.addFileArg(b.path("Tools/Build.ps1"));
    native.addArg("-OutputRoot");
    const archives = native.addOutputDirectoryArg("native");
    if (b.option(bool, "offline", "Require already cached source archives") orelse false) native.addArg("-Offline");
    native.has_side_effects = true;
    const artifact = sdk.addR4MFWithOptions(b.path("module.R4MF"), .{ .native_archives = &.{
        archives.path(b, "R4GL-C.a"), archives.path(b, "R4NativeMath.a"), archives.path(b, "R4NativeScan.a"),
    } });
    const host = sdk.createR4osModule(b.graph.host, .ReleaseSafe);
    const implementation = b.createModule(.{ .root_source_file = b.path("Contract/Generated/implementation_abi.zig"), .target = b.graph.host });
    implementation.addImport("r4os", host);
    const binding = b.createModule(.{ .root_source_file = b.path("Bindings/Zig/r4gl.zig"), .target = b.graph.host });
    binding.addImport("r4os", host);
    const conformance = b.createModule(.{ .root_source_file = b.path("Tests/Generated/contract_conformance.zig"), .target = b.graph.host });
    conformance.addImport("implementation", implementation);
    conformance.addImport("binding", binding);
    conformance.addIncludePath(b.path("Bindings/C"));
    conformance.addIncludePath(sdk.profile.c_include_root);
    conformance.addIncludePath(sdk.profile.contract_c_include_root);
    conformance.addIncludePath(sdk.profile.contract_c_include_root2);
    conformance.addCSourceFile(.{ .file = b.path("Tests/Generated/contract_conformance.c"), .flags = &.{ "-std=c11", "-Wall", "-Wextra", "-Werror" } });
    const run = b.addRunArtifact(b.addTest(.{ .root_module = conformance }));
    b.getInstallStep().dependOn(&run.step);
    const test_step = b.step("test", "R4GL C/Zig bootstrap ABI conformance");
    test_step.dependOn(&run.step);
    if (artifact.verification) |verification| test_step.dependOn(verification);
}
