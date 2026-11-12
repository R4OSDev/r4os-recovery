const std = @import("std");

const host_c_flags: []const []const u8 = &.{ "-std=c11", "-fno-builtin" };

fn addStb(b: *std.Build, module: *std.Build.Module) void {
    module.addIncludePath(b.path("ThirdParty/stb"));
    module.addCSourceFile(.{
        .file = b.path("ThirdParty/stb/r4img_stb.c"),
        .flags = host_c_flags,
    });
}

pub fn build(b: *std.Build) void {
    const host_test_optimize = b.option(
        std.builtin.OptimizeMode,
        "host-test-optimize",
        "Override only the host-side owner workload optimization",
    ) orelse .Debug;
    const sdk_build = b.lazyImport(@This(), "r4os_sdk") orelse return;
    const sdk_dep = b.dependencyFromBuildZig(sdk_build, .{});
    const sdk = sdk_build.sdk(b, sdk_dep, .{});
    const artifact = sdk.addR4MF(b.path("module.R4MF"));
    const c_consumer = sdk.addR4MF(b.path("Tests/CConsumer/module.R4MF"));

    const host_r4os = sdk.createR4osModule(b.graph.host, .Debug);
    const implementation = b.createModule(.{
        .root_source_file = b.path("Contract/Generated/implementation_abi.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    implementation.addImport("r4os", host_r4os);
    const binding_abi = b.createModule(.{
        .root_source_file = b.path("Bindings/Zig/r4img_abi.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    binding_abi.addImport("r4os", host_r4os);
    const binding = b.createModule(.{
        .root_source_file = b.path("Bindings/Zig/r4img.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    binding.addImport("r4os", host_r4os);
    binding.addImport("r4img_abi.zig", binding_abi);

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

    const project = b.createModule(.{
        .root_source_file = b.path("Source/main.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    project.addImport("r4os", host_r4os);
    project.addImport("r4l_contract", implementation);

    const provider_root = b.createModule(.{
        .root_source_file = b.path("Source/main.zig"),
        .target = b.graph.host,
        .optimize = host_test_optimize,
    });
    provider_root.addImport("r4os", host_r4os);
    provider_root.addImport("r4l_contract", implementation);
    addStb(b, provider_root);
    const provider_tests = b.addTest(.{ .root_module = provider_root });
    const run_provider = b.addRunArtifact(provider_tests);

    const host_codec = b.createModule(.{
        .root_source_file = b.path("Source/codec.zig"),
        .target = b.graph.host,
        .optimize = host_test_optimize,
    });
    const decoder_root = b.createModule(.{
        .root_source_file = b.path("Tests/Decoder/decoder_test.zig"),
        .target = b.graph.host,
        .optimize = host_test_optimize,
    });
    decoder_root.addImport("r4img", host_codec);
    addStb(b, decoder_root);
    const decoder_tests = b.addTest(.{ .root_module = decoder_root });
    const run_decoder = b.addRunArtifact(decoder_tests);

    const profile_root = b.createModule(.{
        .root_source_file = b.path("Tests/performance_profile.zig"),
        .target = b.graph.host,
        .optimize = host_test_optimize,
    });
    profile_root.addImport("r4img", host_codec);
    addStb(b, profile_root);
    const profile_exe = b.addExecutable(.{ .name = "r4img-profile", .root_module = profile_root });
    const run_profile = b.addRunArtifact(profile_exe);
    const profile_step = b.step("profile", "Run the opt-in R4IMG scaling profile");
    profile_step.dependOn(&run_profile.step);

    const runtime_root = b.createModule(.{
        .root_source_file = b.path("Tests/runtime_test.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    runtime_root.addImport("project", project);
    runtime_root.addImport("r4img", binding);
    runtime_root.addImport("r4os", host_r4os);
    addStb(b, runtime_root);
    const runtime_tests = b.addTest(.{ .root_module = runtime_root });
    const run_runtime = b.addRunArtifact(runtime_tests);

    b.getInstallStep().dependOn(&run_conformance.step);
    b.getInstallStep().dependOn(&run_provider.step);
    b.getInstallStep().dependOn(&run_decoder.step);
    b.getInstallStep().dependOn(&run_runtime.step);
    const test_step = b.step("test", "Run R4IMG contract, provider, decoder and runtime-table tests");
    test_step.dependOn(&run_conformance.step);
    test_step.dependOn(&run_provider.step);
    test_step.dependOn(&run_decoder.step);
    test_step.dependOn(&run_runtime.step);
    if (artifact.verification) |verification| test_step.dependOn(verification);
    artifact.output.addStepDependencies(test_step);
    c_consumer.output.addStepDependencies(test_step);
}
