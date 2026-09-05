const std = @import("std");

pub const abi = @import("Generated/SDK/Zig/abi_exports.zig");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("r4os_contract", .{
        .root_source_file = b.path("Generated/SDK/Zig/package.zig"),
    });
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

    const write_run = b.addRunArtifact(generator);
    write_run.setCwd(b.path("."));
    write_run.addArg("--write");
    const write_step = b.step("write", "Materialize generated Contract artifacts after an intentional schema change");
    write_step.dependOn(&write_run.step);

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
    test_step.dependOn(&check_run.step);
    test_step.dependOn(&selftest_run.step);
    test_step.dependOn(&run_abi_tests.step);
    test_step.dependOn(&run_abi_package_tests.step);
    test_step.dependOn(&run_kernel_tests.step);
    test_step.dependOn(&run_zig_conformance.step);
    test_step.dependOn(&c_conformance.step);

    b.getInstallStep().dependOn(&check_run.step);
}
