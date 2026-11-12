const std = @import("std");

// The source has exactly one build-module owner, the SDK-selected Libraries
// package. Unit and external consumers delegate to that shared implementation.
pub fn addHostDecoder(b: *std.Build, module: *std.Build.Module, root: std.Build.LazyPath) void {
    const sdk_build = b.lazyImport(@This(), "r4os_sdk") orelse return;
    const sdk_dep = b.dependencyFromBuildZig(sdk_build, .{});
    const libraries = sdk_build.systemLibrariesBuild(sdk_dep) orelse return;
    libraries.addR4fontHostDecoder(b, module, root);
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
        .root_source_file = b.path("Bindings/Zig/r4font_abi.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    binding_abi.addImport("r4os", host_r4os);
    const binding = b.createModule(.{
        .root_source_file = b.path("Bindings/Zig/r4font.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    binding.addImport("r4os", host_r4os);
    binding.addImport("r4font_abi.zig", binding_abi);

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
        .optimize = host_test_optimize,
        .link_libc = true,
    });
    project.addImport("r4os", host_r4os);
    project.addImport("r4l_contract", implementation);
    addHostDecoder(b, project, b.path("ThirdParty/r4font"));
    const provider_tests = b.addTest(.{ .root_module = project });
    const run_provider = b.addRunArtifact(provider_tests);

    const test_binding = b.createModule(.{
        .root_source_file = b.path("Tests/test_binding.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    test_binding.addImport("binding", binding);
    test_binding.addImport("project", project);
    const decoder_root = b.createModule(.{
        .root_source_file = b.path("Tests/decoder_tests.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
        .link_libc = true,
    });
    decoder_root.addImport("r4font", test_binding);
    const decoder_tests = b.addTest(.{ .root_module = decoder_root });
    const run_decoder = b.addRunArtifact(decoder_tests);

    const profile_root = b.createModule(.{
        .root_source_file = b.path("Tests/performance_profile.zig"),
        .target = b.graph.host,
        .optimize = host_test_optimize,
        .link_libc = true,
    });
    profile_root.addImport("r4font", test_binding);
    const profile_exe = b.addExecutable(.{ .name = "r4font-profile", .root_module = profile_root });
    const run_profile = b.addRunArtifact(profile_exe);
    const profile_step = b.step("profile", "Run the opt-in R4FONT glyph-raster profile");
    profile_step.dependOn(&run_profile.step);

    const app_fonts = b.createModule(.{
        .root_source_file = b.path("Bindings/Zig/app_fonts.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    app_fonts.addImport("r4os", host_r4os);
    const app_fonts_root = b.createModule(.{
        .root_source_file = b.path("Tests/app_fonts_tests.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
        .link_libc = true,
    });
    app_fonts_root.addImport("app_fonts", app_fonts);
    app_fonts_root.addImport("project", project);
    const app_fonts_tests = b.addTest(.{ .root_module = app_fonts_root });
    const run_app_fonts = b.addRunArtifact(app_fonts_tests);

    const runtime_root = b.createModule(.{
        .root_source_file = b.path("Tests/runtime_test.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
        .link_libc = true,
    });
    runtime_root.addImport("project", project);
    runtime_root.addImport("r4font", binding);
    runtime_root.addImport("r4os", host_r4os);
    const runtime_tests = b.addTest(.{ .root_module = runtime_root });
    const run_runtime = b.addRunArtifact(runtime_tests);

    b.getInstallStep().dependOn(&run_conformance.step);
    b.getInstallStep().dependOn(&run_provider.step);
    b.getInstallStep().dependOn(&run_decoder.step);
    b.getInstallStep().dependOn(&run_app_fonts.step);
    b.getInstallStep().dependOn(&run_runtime.step);
    const test_step = b.step("test", "Run R4FONT contract, provider, decoder and runtime-table tests");
    test_step.dependOn(&run_conformance.step);
    test_step.dependOn(&run_provider.step);
    test_step.dependOn(&run_decoder.step);
    test_step.dependOn(&run_app_fonts.step);
    test_step.dependOn(&run_runtime.step);
    if (artifact.verification) |verification| test_step.dependOn(verification);
    artifact.output.addStepDependencies(test_step);
    c_consumer.output.addStepDependencies(test_step);
}
