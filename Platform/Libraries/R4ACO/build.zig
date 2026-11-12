const std = @import("std");
pub fn build(b: *std.Build) void {
    b.addNamedLazyPath("binding", b.path("Bindings/Zig/r4aco.zig"));
    const sdk_build = b.lazyImport(@This(), "r4os_sdk") orelse return;
    const sdk = sdk_build.sdk(b, b.dependencyFromBuildZig(sdk_build, .{}), .{});
    const native = b.addSystemCommand(&.{ "pwsh", "-NoLogo", "-NoProfile", "-File" });
    native.addFileArg(b.path("Tools/Build.ps1"));
    native.addArg("-OutputRoot");
    const archives = native.addOutputDirectoryArg("native");
    native.has_side_effects = true;
    const artifact = sdk.addR4MFWithOptions(b.path("module.R4MF"), .{ .native_archives = &.{
        archives.path(b, "R4ACO.a"), archives.path(b, "R4NativeMath.a"), archives.path(b, "R4NativeScan.a"),
    } });
    const host = sdk.createR4osModule(b.graph.host, .ReleaseSafe);
    const implementation = b.createModule(.{ .root_source_file = b.path("Contract/Generated/implementation_abi.zig"), .target = b.graph.host });
    implementation.addImport("r4os", host);
    const binding = b.createModule(.{ .root_source_file = b.path("Bindings/Zig/r4aco.zig"), .target = b.graph.host });
    binding.addImport("r4os", host);
    const conformance = b.createModule(.{ .root_source_file = b.path("Tests/Generated/contract_conformance.zig"), .target = b.graph.host });
    conformance.addImport("implementation", implementation);
    conformance.addImport("binding", binding);
    conformance.addIncludePath(b.path("Bindings/C"));
    conformance.addIncludePath(sdk.profile.c_include_root);
    conformance.addIncludePath(sdk.profile.contract_c_include_root);
    conformance.addIncludePath(sdk.profile.contract_c_include_root2);
    conformance.addCSourceFile(.{ .file = b.path("Tests/Generated/contract_conformance.c"), .flags = &.{ "-std=c11", "-Werror" } });
    const abi_check = b.addRunArtifact(b.addTest(.{ .root_module = conformance }));
    // Freestanding ELF objects run directly on the Linux host. Windows uses
    // the same ELF runtime build and the SMP4 DISPLAYD compiler probe.
    var compiler_check: ?*std.Build.Step.Run = null;
    if (b.graph.host.result.os.tag == .linux) {
        const runtime = b.createModule(.{ .root_source_file = b.path("Source/main.zig"), .target = b.graph.host, .optimize = .ReleaseSafe });
        runtime.addImport("r4l_contract", implementation);
        runtime.addImport("r4os", host);
        const math = b.createModule(.{ .root_source_file = b.path("../Shared/Native/math.zig"), .target = b.graph.host, .optimize = .ReleaseSafe });
        runtime.addImport("r4native_math", math);
        runtime.addImport("r4cache_codec", b.createModule(.{ .root_source_file = b.path("../Shared/Native/cache_codec.zig"), .target = b.graph.host, .optimize = .ReleaseSafe }));
        const checks = b.createModule(.{ .root_source_file = b.path("Tests/compiler.zig"), .target = b.graph.host, .optimize = .ReleaseSafe });
        checks.addImport("r4l_contract", implementation);
        checks.addImport("compiler_runtime", runtime);
        checks.addImport("compiler_cache", runtime);
        inline for (.{ "R4ACO.a", "R4NativeMath.a", "R4NativeScan.a" }) |name| checks.addObjectFile(archives.path(b, name));
        compiler_check = b.addRunArtifact(b.addTest(.{ .root_module = checks }));
        b.getInstallStep().dependOn(&compiler_check.?.step);
        const cli = b.createModule(.{ .root_source_file = b.path("Tools/compiler.zig"), .target = b.graph.host, .optimize = .ReleaseSafe });
        cli.addImport("r4l_contract", implementation);
        cli.addImport("compiler_runtime", runtime);
        inline for (.{ "R4ACO.a", "R4NativeMath.a", "R4NativeScan.a" }) |name| cli.addObjectFile(archives.path(b, name));
        const tool = b.addExecutable(.{ .name = "r4aco-compiler", .root_module = cli });
        const install_tool = b.addInstallArtifact(tool, .{});
        b.step("compiler", "Build the offline Linux compiler frontend").dependOn(&install_tool.step);
    }
    _ = artifact;
    b.getInstallStep().dependOn(&abi_check.step);
    const test_step = b.step("test", "R4ACO contract and real upstream portability");
    test_step.dependOn(&abi_check.step);
    test_step.dependOn(&native.step);
    if (compiler_check) |check| test_step.dependOn(&check.step);
}
