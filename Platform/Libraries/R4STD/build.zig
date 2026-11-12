const std = @import("std");

pub fn build(b: *std.Build) void {
    const sdk_build = b.lazyImport(@This(), "r4os_sdk") orelse return;
    const sdk_dep = b.dependencyFromBuildZig(sdk_build, .{});
    const sdk = sdk_build.sdk(b, sdk_dep, .{});
    const artifact = sdk.addR4MF(b.path("module.R4MF"));

    const host_r4os = sdk.createR4osModule(b.graph.host, .Debug);
    const implementation = b.createModule(.{
        .root_source_file = b.path("Contract/Generated/implementation_abi.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    implementation.addImport("r4os", host_r4os);
    const binding_abi = b.createModule(.{
        .root_source_file = b.path("Bindings/Zig/r4std_abi.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    binding_abi.addImport("r4os", host_r4os);
    const binding = b.createModule(.{
        .root_source_file = b.path("Bindings/Zig/r4std.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    binding.addImport("r4os", host_r4os);
    binding.addImport("r4std_abi.zig", binding_abi);

    const conformance_root = b.createModule(.{
        .root_source_file = b.path("Tests/Generated/contract_conformance.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    conformance_root.addImport("implementation", implementation);
    conformance_root.addImport("binding", binding_abi);
    conformance_root.addIncludePath(b.path("Bindings/C"));
    conformance_root.addIncludePath(sdk.profile.c_include_root);
    conformance_root.addIncludePath(sdk.profile.contract_c_include_root);
    conformance_root.addIncludePath(sdk.profile.contract_c_include_root2);
    conformance_root.addCSourceFile(.{
        .file = b.path("Tests/Generated/contract_conformance.c"),
        .flags = &.{ "-std=c11", "-Wall", "-Wextra", "-Werror" },
    });
    const conformance_tests = b.addTest(.{ .root_module = conformance_root });
    const run_conformance = b.addRunArtifact(conformance_tests);

    const provider_root = b.createModule(.{
        .root_source_file = b.path("Source/main.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    provider_root.addImport("r4os", host_r4os);
    provider_root.addImport("r4l_contract", implementation);
    const provider_tests = b.addTest(.{ .root_module = provider_root });
    const run_provider = b.addRunArtifact(provider_tests);

    const binding_tests = b.addTest(.{ .root_module = binding });
    const run_binding = b.addRunArtifact(binding_tests);
    const console_text_tests = b.addRunArtifact(b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("Bindings/Zig/console_text.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    }) }));
    b.getInstallStep().dependOn(&console_text_tests.step);

    const runtime_root = b.createModule(.{
        .root_source_file = b.path("Tests/runtime_test.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    runtime_root.addImport("project", provider_root);
    runtime_root.addImport("r4std", binding);
    runtime_root.addImport("r4os", host_r4os);
    runtime_root.addIncludePath(b.path("Bindings/C"));
    runtime_root.addIncludePath(sdk.profile.c_include_root);
    runtime_root.addIncludePath(sdk.profile.contract_c_include_root);
    runtime_root.addIncludePath(sdk.profile.contract_c_include_root2);
    runtime_root.addCSourceFile(.{ .file = b.path("Tests/codec_transport.c"), .flags = &.{ "-std=c11", "-Wall", "-Wextra", "-Werror" } });
    const runtime_tests = b.addTest(.{ .root_module = runtime_root });
    const run_runtime = b.addRunArtifact(runtime_tests);

    b.getInstallStep().dependOn(&run_conformance.step);
    b.getInstallStep().dependOn(&run_provider.step);
    b.getInstallStep().dependOn(&run_binding.step);
    b.getInstallStep().dependOn(&run_runtime.step);
    const test_step = b.step("test", "Run R4STD contract and provider tests");
    test_step.dependOn(&console_text_tests.step);
    test_step.dependOn(&run_conformance.step);
    test_step.dependOn(&run_provider.step);
    test_step.dependOn(&run_binding.step);
    test_step.dependOn(&run_runtime.step);
    if (artifact.verification) |verification| test_step.dependOn(verification);
    artifact.output.addStepDependencies(test_step);
}
