const std = @import("std");
const r4os_build = @import("r4os/build.zig");

pub const build_api = r4os_build;
pub const Sdk = r4os_build.Sdk;
pub const SdkOptions = r4os_build.SdkOptions;
pub const HostProfile = r4os_build.HostProfile;
pub const R4XAppOptions = r4os_build.R4XAppOptions;
pub const R4XCAppOptions = r4os_build.R4XCAppOptions;
pub const R4AppOptions = r4os_build.R4AppOptions;
pub const R4CAppOptions = r4os_build.R4CAppOptions;
pub const AppProfile = r4os_build.AppProfile;
pub const R4DModuleOptions = r4os_build.R4DModuleOptions;
pub const R4PModuleOptions = r4os_build.R4PModuleOptions;
pub const R4LModuleOptions = r4os_build.R4LModuleOptions;
pub const R4MFBuildOptions = r4os_build.R4MFBuildOptions;

pub fn sdk(b: *std.Build, dependency: *std.Build.Dependency, opts: SdkOptions) Sdk {
    return Sdk.fromDependency(b, dependency, opts);
}

pub fn build(b: *std.Build) void {
    b.addNamedLazyPath("system_update_engine", b.path("r4os/system_update_engine.zig"));
    b.addNamedLazyPath("update_service_contract", b.path("r4os/update_service_contract.zig"));

    const contract_dependency = b.dependency("r4os_contract", .{});
    const sdk_profile = Sdk.init(b, .{ .contract_dependency = contract_dependency });
    b.installArtifact(sdk_profile.builder);
    if (sdk_profile.r4l_contract_generator) |generator| b.installArtifact(generator);

    const module_filter = b.option([]const u8, "module-filter", "Build only matching SDK smoke R4X names") orelse "";
    _ = sdk_profile.addR4MFCatalog(&.{b.path("Smoke")}, module_filter);
    _ = sdk_profile.addR4MFWithOptions(b.path("Tests/Build/R4MFMapping/module.R4MF"), .{
        .zig_module_roots = &.{b.path("Tests/Build/R4MFMapping/Bindings/external.zig")},
    });
    _ = sdk_profile.addR4MF(b.path("Tests/Build/SubsystemManifest/module.R4MF"));
    _ = sdk_profile.addR4D(.{
        .name = "SDKSMOKE",
        .driver_name = "SDKSMOKE",
        .driver_type = "misc",
        .root_source_file = b.path("Smoke/R4D/src/main.zig"),
    });
    _ = sdk_profile.addR4P(.{
        .name = "SDKSMOKE",
        .protocol_name = "SDKSMOKE",
        .role = "misc.sdk_smoke",
        .category = "misc",
        .root_source_file = b.path("Smoke/R4P/src/main.zig"),
    });

    const host_r4os = sdk_profile.createR4osModule(b.graph.host, .Debug);
    const sdk_unit_tests = b.addTest(.{ .root_module = host_r4os });
    const run_sdk_unit_tests = b.addRunArtifact(sdk_unit_tests);

    const vm_allocator_module = b.createModule(.{
        .root_source_file = b.path("r4os/vm_allocator.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    vm_allocator_module.addImport("r4os_contract", sdk_profile.profile.contract_module);
    const vm_allocator_tests = b.addTest(.{ .root_module = vm_allocator_module });
    const run_vm_allocator_tests = b.addRunArtifact(vm_allocator_tests);

    const subsystem_runtime_module = b.createModule(.{
        .root_source_file = b.path("r4os/subsystem_runtime.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    subsystem_runtime_module.addImport("r4os_contract", sdk_profile.profile.contract_module);
    const subsystem_runtime_tests = b.addTest(.{ .root_module = subsystem_runtime_module });
    const run_subsystem_runtime_tests = b.addRunArtifact(subsystem_runtime_tests);

    const ntfs_format = b.createModule(.{
        .root_source_file = b.path("r4os/ntfs_format.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    const ntfs_volume = b.createModule(.{
        .root_source_file = b.path("r4os/ntfs_volume.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    ntfs_volume.addImport("ntfs_format", ntfs_format);
    const ntfs_volume_tests = b.addTest(.{ .root_module = ntfs_volume });
    const run_ntfs_volume_tests = b.addRunArtifact(ntfs_volume_tests);

    const r4x_builder_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("Tools/R4XBuilder/src/main.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });
    const run_r4x_builder_tests = b.addRunArtifact(r4x_builder_tests);

    const r4l_contract_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("Tools/R4LContractGen/src/main.zig"),
            .target = b.graph.host,
            .optimize = .Debug,
        }),
    });
    const run_r4l_contract_tests = b.addRunArtifact(r4l_contract_tests);

    const catalog_bundle = b.createModule(.{
        .root_source_file = b.path("r4os/r4cp_convert.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    catalog_bundle.addImport("r4os_contract", sdk_profile.profile.contract_module);
    const catalog_root = b.createModule(.{
        .root_source_file = b.path("Tools/ModuleCatalog/src/main.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    catalog_root.addImport("contract_bundle", catalog_bundle);
    const catalog = b.addExecutable(.{ .name = "module-catalog", .root_module = catalog_root });
    b.installArtifact(catalog);
    const catalog_tests = b.addTest(.{ .root_module = catalog_bundle });
    const run_catalog_tests = b.addRunArtifact(catalog_tests);
    const catalog_tool_test_root = b.createModule(.{
        .root_source_file = b.path("Tools/ModuleCatalog/src/main.zig"),
        .target = b.graph.host,
        .optimize = .Debug,
    });
    catalog_tool_test_root.addImport("contract_bundle", catalog_bundle);
    const catalog_tool_tests = b.addTest(.{ .root_module = catalog_tool_test_root });
    const run_catalog_tool_tests = b.addRunArtifact(catalog_tool_tests);

    const test_step = b.step("test", "Run SDK, build-tool and smoke tests");
    test_step.dependOn(b.getInstallStep());
    test_step.dependOn(&run_sdk_unit_tests.step);
    test_step.dependOn(&run_vm_allocator_tests.step);
    test_step.dependOn(&run_subsystem_runtime_tests.step);
    test_step.dependOn(&run_ntfs_volume_tests.step);
    test_step.dependOn(&run_r4x_builder_tests.step);
    test_step.dependOn(&run_r4l_contract_tests.step);
    test_step.dependOn(&run_catalog_tests.step);
    test_step.dependOn(&run_catalog_tool_tests.step);
}
