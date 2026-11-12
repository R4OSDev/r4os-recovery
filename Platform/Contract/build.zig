const std = @import("std");

pub const abi = @import("Generated/SDK/Zig/abi_exports.zig");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    const base_contract = b.addModule("r4os_contract", .{
        .root_source_file = b.path("Generated/SDK/Zig/package.zig"),
    });
    const next_contract = b.addModule("r4os_contract2", .{
        .root_source_file = b.path("Generated/Generation2/Zig/abi.zig"),
    });
    next_contract.addImport("r4os_base_abi", base_contract);
    b.addNamedLazyPath("r4os_contract2_c_include", b.path("Generated/Generation2/C/include"));
    b.addNamedLazyPath(
        "r4os_contract_c_include",
        b.path("Generated/SDK/C/include"),
    );

    const generator = b.addExecutable(.{
        .name = "api-contract-gen",
        .root_module = b.createModule(.{
            .root_source_file = b.path("Tools/ApiContractGen/src/main.zig"),
            .target = b.graph.host,
            .optimize = optimize,
        }),
    });
    b.installArtifact(generator);

    const check_run = b.addRunArtifact(generator);
    check_run.setCwd(b.path("."));
    check_run.addArg("--check");
    const check_step = b.step("check", "Validate the schema and check every generated Contract artifact");
    check_step.dependOn(&check_run.step);

    const technical_abi = b.createModule(.{
        .root_source_file = b.path("Generated/SDK/Zig/abi.zig"),
        .target = b.graph.host,
        .optimize = optimize,
    });
    const rust_check_generator = addRustGenerator(b, optimize, technical_abi, "api-rust-gen");
    b.installArtifact(rust_check_generator);
    const rust_check = b.addRunArtifact(rust_check_generator);
    rust_check.setCwd(b.path("."));
    rust_check.addArg("--check");
    check_step.dependOn(&rust_check.step);

    const write_run = b.addRunArtifact(generator);
    write_run.setCwd(b.path("."));
    write_run.addArg("--write");
    if (b.args) |args| write_run.addArgs(args);
    const write_step = b.step("write", "Materialize generated Contract artifacts after an intentional schema change");
    write_step.dependOn(&write_run.step);

    // Compile reflection only after the schema generator has materialized its
    // new Zig types. Check/default builds never acquire this write dependency.
    // Same compiler identity permits reuse after write; distinct build steps
    // preserve the required materialize-before-reflection dependency.
    const rust_write_generator = addRustGenerator(b, optimize, technical_abi, "api-rust-gen");
    rust_write_generator.step.dependOn(&write_run.step);
    const rust_write = b.addRunArtifact(rust_write_generator);
    rust_write.setCwd(b.path("."));
    rust_write.addArg("--write");
    write_step.dependOn(&rust_write.step);

    const selftest_run = b.addRunArtifact(generator);
    selftest_run.setCwd(b.path("."));
    selftest_run.addArg("--selftest");
    const selftest_step = b.step("selftest", "Run ApiContractGen mutation and compatibility self-tests");
    selftest_step.dependOn(&selftest_run.step);

    const run = b.addRunArtifact(generator);
    run.setCwd(b.path("."));
    if (b.args) |args| run.addArgs(args);
    const run_step = b.step("run", "Run ApiContractGen with explicit arguments");
    run_step.dependOn(&run.step);

    const abi_module = b.createModule(.{
        .root_source_file = b.path("Generated/SDK/Zig/abi_exports.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    const abi_tests = b.addTest(.{ .root_module = abi_module });
    const run_abi_tests = b.addRunArtifact(abi_tests);

    const abi_package_module = b.createModule(.{
        .root_source_file = b.path("Generated/SDK/Zig/package.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    const abi_package_tests = b.addTest(.{ .root_module = abi_package_module });
    const run_abi_package_tests = b.addRunArtifact(abi_package_tests);

    const kernel_module = b.createModule(.{
        .root_source_file = b.path("Generated/Kernel/Zig/r4x_api_exports.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    const kernel_tests = b.addTest(.{ .root_module = kernel_module });
    const run_kernel_tests = b.addRunArtifact(kernel_tests);

    const zig_conformance_module = b.createModule(.{
        .root_source_file = b.path("Generated/Conformance/Zig/ApiContractConformanceGenerated.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    zig_conformance_module.addImport("r4os_contract_abi", abi_module);
    const zig_conformance_tests = b.addTest(.{ .root_module = zig_conformance_module });
    const run_zig_conformance = b.addRunArtifact(zig_conformance_tests);

    const contract_target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
        .abi = .none,
    });
    const c_conformance_module = b.createModule(.{
        .target = contract_target,
        .optimize = .Debug,
    });
    c_conformance_module.addIncludePath(b.path("Generated/SDK/C/include"));
    c_conformance_module.addCSourceFile(.{
        .file = b.path("Generated/Conformance/C/ApiContractConformanceGenerated.c"),
        .flags = &.{ "-std=c11", "-ffreestanding", "-fno-builtin" },
    });
    const c_conformance = b.addObject(.{
        .name = "r4os-contract-c-conformance",
        .root_module = c_conformance_module,
    });

    const test_step = b.step("test", "Run generator self-tests and compile all generated Zig/C artifacts");
    const next_tests_root = b.createModule(.{
        .root_source_file = b.path("Tests/Generation2.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    next_tests_root.addImport("r4os_contract2", next_contract);
    next_tests_root.addIncludePath(b.path("Generated/SDK/C/include"));
    next_tests_root.addIncludePath(b.path("Generated/Generation2/C/include"));
    const next_tests = b.addRunArtifact(b.addTest(.{ .root_module = next_tests_root }));
    test_step.dependOn(&next_tests.step);
    test_step.dependOn(&check_run.step);
    test_step.dependOn(&selftest_run.step);
    test_step.dependOn(&run_abi_tests.step);
    test_step.dependOn(&run_abi_package_tests.step);
    test_step.dependOn(&run_kernel_tests.step);
    test_step.dependOn(&run_zig_conformance.step);
    test_step.dependOn(&c_conformance.step);
    test_step.dependOn(&rust_check.step);
    const rust_conformance = b.addSystemCommand(&.{ "pwsh", "-NoLogo", "-NoProfile", "-File" });
    rust_conformance.addFileArg(b.path("Tools/Test-RustABI.ps1"));
    rust_conformance.step.dependOn(&rust_check.step);
    test_step.dependOn(&rust_conformance.step);

    b.getInstallStep().dependOn(&check_run.step);
    b.getInstallStep().dependOn(&rust_check.step);
}

fn addRustGenerator(b: *std.Build, optimize: std.builtin.OptimizeMode, abi_module: *std.Build.Module, name: []const u8) *std.Build.Step.Compile {
    const module = b.createModule(.{
        .root_source_file = b.path("Tools/AbiRustGen/src/main.zig"),
        .target = b.graph.host,
        .optimize = optimize,
    });
    module.addImport("r4os_technical_abi", abi_module);
    // Embed the generated export names without compiling their types in a
    // second module (the technical facade already imports those exact types).
    module.addAnonymousImport("r4os_generated_abi_source", .{
        .root_source_file = b.path("Generated/SDK/Zig/abi_exports.zig"),
    });
    return b.addExecutable(.{ .name = name, .root_module = module });
}
