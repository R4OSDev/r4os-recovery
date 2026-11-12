const std = @import("std");
pub fn build(b: *std.Build) void {
    b.addNamedLazyPath("binding", b.path("Bindings/Zig/r4nv.zig"));
    b.addNamedLazyPath("backend", b.path("Source/backend.zig"));
    b.addNamedLazyPath("render_encoder", b.path("Source/render_api.zig"));
    b.addNamedLazyPath("video", b.path("Source/video.zig"));
    b.addNamedLazyPath("encode", b.path("Source/encode.zig"));
    b.addNamedLazyPath("implementation", b.path("Contract/Generated/implementation_abi.zig"));
    const sdk_build = b.lazyImport(@This(), "r4os_sdk") orelse return;
    const sdk = sdk_build.sdk(b, b.dependencyFromBuildZig(sdk_build, .{}), .{});
    const artifact = sdk.addR4MF(b.path("module.R4MF"));
    const host = sdk.createR4osModule(b.graph.host, .ReleaseSafe);
    const implementation = b.createModule(.{ .root_source_file = b.path("Contract/Generated/implementation_abi.zig"), .target = b.graph.host });
    implementation.addImport("r4os", host);
    const binding = b.createModule(.{ .root_source_file = b.path("Bindings/Zig/r4nv.zig"), .target = b.graph.host });
    binding.addImport("r4os", host);
    const provider = b.createModule(.{ .root_source_file = b.path("Source/main.zig"), .target = b.graph.host, .optimize = .ReleaseSafe });
    provider.addImport("r4os", host);
    provider.addImport("r4l_contract", implementation);
    const conformance = b.createModule(.{ .root_source_file = b.path("Tests/Generated/contract_conformance.zig"), .target = b.graph.host });
    conformance.addImport("implementation", implementation);
    conformance.addImport("binding", binding);
    conformance.addIncludePath(b.path("Bindings/C"));
    conformance.addIncludePath(sdk.profile.c_include_root);
    conformance.addIncludePath(sdk.profile.contract_c_include_root);
    conformance.addIncludePath(sdk.profile.contract_c_include_root2);
    conformance.addCSourceFile(.{ .file = b.path("Tests/Generated/contract_conformance.c"), .flags = &.{ "-std=c11", "-Wall", "-Wextra", "-Werror" } });
    const step = b.step("test", "R4NV backend boundary and C/Zig ABI conformance");
    for ([_]*std.Build.Module{ provider, conformance }) |module| {
        const run = b.addRunArtifact(b.addTest(.{ .root_module = module }));
        step.dependOn(&run.step);
        b.getInstallStep().dependOn(&run.step);
    }
    if (artifact.verification) |verification| step.dependOn(verification);
    artifact.output.addStepDependencies(step);
}
