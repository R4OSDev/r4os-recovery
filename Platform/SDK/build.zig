const std = @import("std");
const sdk_profiles = @import("r4os/build_profile.zig");
const r4os_build = @import("r4os/build.zig");

pub const build_api = r4os_build;
pub const Sdk = r4os_build.Sdk;
pub const SdkOptions = r4os_build.SdkOptions;
pub const HostProfile = r4os_build.HostProfile;
fn addRemovalOwnerTests(b: *std.Build, profile: Sdk, target: std.Build.ResolvedTarget) *std.Build.Step.Run {
    const root = b.createModule(.{ .root_source_file = b.path("Tests/Simulation/RemovalOwners.zig"), .target = target, .optimize = sdk_profiles.defaults.host_optimize });
    const owner_sdk = profile.createR4osModule(target, sdk_profiles.defaults.host_optimize);
    const engine = b.createModule(.{ .root_source_file = b.path("r4os/system_update_engine.zig"), .target = target, .optimize = sdk_profiles.defaults.host_optimize });
    engine.addImport("r4os", owner_sdk);
    root.addImport("system_update_engine", engine);
    return b.addRunArtifact(b.addTest(.{ .root_module = root }));
}
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

/// SDK-selected Libraries build API; callers do not pin the system package.
pub inline fn systemLibrariesBuild(dependency: *std.Build.Dependency) ?type {
    return dependency.builder.lazyImport(@This(), "r4os_libraries");
}

pub fn build(b: *std.Build) void {
    b.addNamedLazyPath("system_update_engine", b.path("r4os/system_update_engine.zig"));
    b.addNamedLazyPath("update_service_contract", b.path("r4os/update_service_contract.zig"));

    const contract_dependency = b.dependency("r4os_contract", .{});
    const platform2 = b.addModule("r4os_platform2", .{ .root_source_file = b.path("r4os/platform2.zig") });
    platform2.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
    platform2.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
    const platform2_tests_root = b.createModule(.{ .root_source_file = b.path("r4os/platform2.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.host_optimize });
    platform2_tests_root.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
    platform2_tests_root.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
    const platform2_tests = b.addRunArtifact(b.addTest(.{ .root_module = platform2_tests_root }));
    const platform2_step = b.step("platform2-test", "Check explicit generation2 context selection");
    platform2_step.dependOn(&platform2_tests.step);
    const technical2_root = b.createModule(.{ .root_source_file = b.path("r4os/technical2.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.host_optimize });
    technical2_root.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
    technical2_root.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
    platform2_step.dependOn(&b.addRunArtifact(b.addTest(.{ .root_module = technical2_root })).step);
    const parity_check = b.addSystemCommand(&.{ "pwsh", "-NoLogo", "-NoProfile", "-File" });
    parity_check.addFileArg(b.path("Tools/Test-LanguageParity.ps1"));
    parity_check.addArg("-SdkRoot");
    parity_check.addDirectoryArg(b.path("."));
    parity_check.addArg("-ContractRoot");
    parity_check.addDirectoryArg(contract_dependency.path("."));
    parity_check.addArgs(&.{ "-LibraryRoot", b.option([]const u8, "parity-library-root", "Explicit Libraries package for the language parity source review") orelse b.pathResolve(&.{ "..", "Libraries" }) });
    b.step("language-parity-check", "Check current Zig/C/Rust implementation and evidence review identities").dependOn(&parity_check.step);
    if (b.option(bool, "packager-only", "Build only the selected host R4M0 packager") orelse false) {
        b.installArtifact(r4os_build.addR4XBuilder(b, b.path("Tools/R4XBuilder/src/main.zig")));
        return;
    }
    if (b.option(bool, "catalog-only", "Build only the selected host ModuleCatalog") orelse false) {
        const target = b.standardTargetOptions(.{});
        const bundle = b.createModule(.{ .root_source_file = b.path("r4os/r4cp_convert.zig"), .target = target, .optimize = sdk_profiles.defaults.host_optimize });
        bundle.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
        bundle.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
        const root = b.createModule(.{ .root_source_file = b.path("Tools/ModuleCatalog/src/main.zig"), .target = target, .optimize = sdk_profiles.defaults.host_optimize });
        root.addImport("contract_bundle", bundle);
        b.installArtifact(b.addExecutable(.{ .name = "module-catalog", .root_module = root }));
        return;
    }
    if (b.option(bool, "r4l-contract-generator-only", "Build only the selected host library contract generator") orelse false) {
        const root = b.createModule(.{ .root_source_file = b.path("Tools/R4LContractGen/src/main.zig"), .target = b.standardTargetOptions(.{}), .optimize = sdk_profiles.defaults.host_optimize });
        b.installArtifact(b.addExecutable(.{ .name = "r4l-contract-gen", .root_module = root }));
        return;
    }
    const sdk_profile = Sdk.init(b, .{ .contract_dependency = contract_dependency });
    if (b.option(bool, "r4l-consumer-fixtures-only", "Build only the C/Zig R4L consumers") orelse false) {
        _ = sdk_profile.addR4MF(b.path("Tests/Build/R4LConsumers/C/module.R4MF"));
        _ = sdk_profile.addR4MF(b.path("Tests/Build/R4LConsumers/Zig/module.R4MF"));
        return;
    }

    if (b.option(bool, "r4l-provider-tests-only", "Only current manifest/library contract tests") orelse false) {
        const root = b.createModule(.{ .root_source_file = b.path("r4os/module_manifest.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.host_optimize });
        root.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
        root.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
        const manifest_tests = b.addRunArtifact(b.addTest(.{ .root_module = root }));
        const contract_tests = b.addRunArtifact(b.addTest(.{ .root_module = sdk_profile.r4l_contract_generator.?.root_module }));
        b.getInstallStep().dependOn(&manifest_tests.step);
        b.getInstallStep().dependOn(&contract_tests.step);
        return;
    }

    const update_json_core = b.option([]const u8, "update-json-core", "Original JSON protocol core for current SDK update owner tests");
    if (b.option(bool, "update-owner-tests-only", "Run only existing update/catalog/journal owner cases") orelse false) {
        const json_file = update_json_core orelse @panic("update-owner-tests-only requires -Dupdate-json-core=<original JSON core path>");
        const target = b.resolveTargetQuery(.{ .cpu_arch = .x86_64, .os_tag = b.graph.host.result.os.tag, .abi = b.graph.host.result.abi, .cpu_model = .baseline });
        const cases = b.createModule(.{ .root_source_file = b.path("test_update_owners.zig"), .target = target, .optimize = sdk_profiles.defaults.host_optimize });
        cases.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
        cases.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
        cases.addImport("r4std_grapheme", b.createModule(.{ .root_source_file = sdk_profile.profile.grapheme_source.?, .target = target, .optimize = sdk_profiles.defaults.host_optimize }));
        cases.addImport("json_core", b.createModule(.{ .root_source_file = .{ .cwd_relative = json_file }, .target = target, .optimize = sdk_profiles.defaults.host_optimize }));
        const selected = b.addRunArtifact(b.addTest(.{ .root_module = cases, .filters = @import("Tests/Simulation/UpdateFilters.zig").names }));
        b.getInstallStep().dependOn(&selected.step);
        b.getInstallStep().dependOn(&addRemovalOwnerTests(b, sdk_profile, target).step);
        return;
    }

    if (b.option(bool, "subsystem-host-fixture-only", "Build only the existing GUI subsystem lifecycle/audio fixture") orelse false) {
        _ = sdk_profile.addR4MF(b.path("Tests/Build/SubsystemManifest/module.R4MF"));
        return;
    }
    if (b.option(bool, "subsystem-guest-fixtures-only", "Build only canonical Zig/C synthetic subsystem consumers") orelse false) {
        _ = sdk_profile.addR4MF(b.path("Tests/Build/CSubsystem/module.R4MF"));
        _ = sdk_profile.addR4MF(b.path("Tests/Build/ZigSubsystem/module.R4MF"));
        return;
    }
    if (b.option(bool, "subsystem-owner-tests-only", "Only current subsystem owner and configuration cases") orelse false) {
        const target = b.resolveTargetQuery(.{ .cpu_arch = .x86_64, .os_tag = b.graph.host.result.os.tag, .abi = b.graph.host.result.abi, .cpu_model = .baseline });
        const cases = b.createModule(.{ .root_source_file = b.path("test_subsystem_owners.zig"), .target = target, .optimize = sdk_profiles.defaults.host_optimize });
        cases.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
        cases.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
        cases.addImport("r4std_grapheme", b.createModule(.{ .root_source_file = sdk_profile.profile.grapheme_source.?, .target = target, .optimize = sdk_profiles.defaults.host_optimize }));
        const selected = b.addRunArtifact(b.addTest(.{ .root_module = cases, .filters = @import("Tests/Simulation/SubsystemFilters.zig").names }));
        b.getInstallStep().dependOn(&selected.step);
        return;
    }
    if (b.option(bool, "driver-bridge-generator-only", "Build only the typed original driver helper generator") orelse false) {
        const root = b.createModule(.{ .root_source_file = b.path("Tools/DataBridgeGen/src/main.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize, .strip = true });
        const schema = b.createModule(.{ .root_source_file = b.path("r4os/driver_bridge_schema.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize });
        schema.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
        schema.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
        const options = b.createModule(.{ .root_source_file = b.path("r4os/driver_bridge_names.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize });
        options.addImport("schema", schema);
        root.addImport("schema", schema);
        root.addImport("options", options);
        b.installArtifact(b.addExecutable(.{ .name = "driver-bridge-gen", .root_module = root, .use_llvm = true }));
        return;
    }
    if (b.option(bool, "subsystem-bridge-generator-only", "Build the compiler-typed SDK subsystem generator") orelse false) {
        const root = b.createModule(.{ .root_source_file = b.path("Tools/DataBridgeGen/src/main.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize, .strip = true });
        const schema = b.createModule(.{ .root_source_file = b.path("r4os/subsystem_bridge_schema.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize });
        schema.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
        schema.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
        schema.addImport("r4std_grapheme", b.createModule(.{ .root_source_file = sdk_profile.profile.grapheme_source.?, .target = b.graph.host, .optimize = sdk_profiles.defaults.host_optimize }));
        const options = b.createModule(.{ .root_source_file = b.path("r4os/subsystem_bridge_names.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize });
        options.addImport("schema", schema);
        root.addImport("schema", schema);
        root.addImport("options", options);
        b.installArtifact(b.addExecutable(.{ .name = "subsystem-bridge-gen", .root_module = root, .use_llvm = true }));
        return;
    }
    if (b.option(bool, "update-bridge-generator-only", "Build the compiler-typed SDK update/job generator") orelse false) {
        const root = b.createModule(.{ .root_source_file = b.path("Tools/DataBridgeGen/src/main.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize, .strip = true });
        const schema = b.createModule(.{ .root_source_file = b.path("r4os/update_bridge_schema.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize });
        schema.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
        schema.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
        schema.addImport("r4std_grapheme", b.createModule(.{ .root_source_file = sdk_profile.profile.grapheme_source.?, .target = b.graph.host, .optimize = sdk_profiles.defaults.host_optimize }));
        const options = b.createModule(.{ .root_source_file = b.path("r4os/update_bridge_names.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize });
        options.addImport("schema", schema);
        root.addImport("schema", schema);
        root.addImport("options", options);
        b.installArtifact(b.addExecutable(.{ .name = "update-bridge-gen", .root_module = root, .use_llvm = true }));
        return;
    }
    if (b.option(bool, "transport-bridge-generator-only", "Build the compiler-typed SDK transport/job generator") orelse false) {
        const root = b.createModule(.{ .root_source_file = b.path("Tools/DataBridgeGen/src/main.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize, .strip = true });
        const schema = b.createModule(.{ .root_source_file = b.path("r4os/transport_bridge_schema.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize });
        schema.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
        schema.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
        schema.addImport("r4std_grapheme", b.createModule(.{ .root_source_file = sdk_profile.profile.grapheme_source.?, .target = b.graph.host, .optimize = sdk_profiles.defaults.host_optimize }));
        const options = b.createModule(.{ .root_source_file = b.path("r4os/transport_bridge_names.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize });
        options.addImport("schema", schema);
        root.addImport("schema", schema);
        root.addImport("options", options);
        b.installArtifact(b.addExecutable(.{ .name = "transport-bridge-gen", .root_module = root, .use_llvm = true }));
        return;
    }
    if (b.option(bool, "web-bridge-generator-only", "Build the compiler-typed SDK web helper generator") orelse false) {
        const root = b.createModule(.{ .root_source_file = b.path("Tools/DataBridgeGen/src/main.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize, .strip = true });
        const schema = b.createModule(.{ .root_source_file = b.path("r4os/web_bridge_schema.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize });
        schema.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
        schema.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
        schema.addImport("r4std_grapheme", b.createModule(.{ .root_source_file = sdk_profile.profile.grapheme_source.?, .target = b.graph.host, .optimize = sdk_profiles.defaults.host_optimize }));
        const options = b.createModule(.{ .root_source_file = b.path("r4os/web_bridge_names.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize });
        options.addImport("schema", schema);
        root.addImport("schema", schema);
        root.addImport("options", options);
        b.installArtifact(b.addExecutable(.{ .name = "web-bridge-gen", .root_module = root, .use_llvm = true }));
        return;
    }
    if (b.option(bool, "web-bridge-runtime-only", "Build only the SDK web owner boundary") orelse false) {
        const native = b.option(bool, "web-bridge-host-test", "Native ABI for web helper interop") orelse false;
        const object = r4os_build.addStorageRuntimeObject(b, b.path("r4os/web_value_bridge.zig"), sdk_profile.profile.contract_module, sdk_profile.profile.contract_module2, sdk_profile.profile.grapheme_source.?, sdk_profile.builder, native);
        b.getInstallStep().dependOn(&b.addInstallFile(object, "lib/r4sdk_web.o").step);
        return;
    }
    if (b.option(bool, "data-bridge-generator-only", "Build the compiler-typed SDK data helper generator") orelse false) {
        const root = b.createModule(.{ .root_source_file = b.path("Tools/DataBridgeGen/src/main.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize, .strip = true });
        const schema = b.createModule(.{ .root_source_file = b.path("r4os/data_bridge_schema.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize });
        schema.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
        schema.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
        schema.addImport("r4std_grapheme", b.createModule(.{ .root_source_file = sdk_profile.profile.grapheme_source.?, .target = b.graph.host, .optimize = sdk_profiles.defaults.host_optimize }));
        root.addImport("schema", schema);
        const options = b.createModule(.{ .root_source_file = b.path("Tools/DataBridgeGen/src/options.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize });
        options.addImport("schema", schema);
        root.addImport("options", options);
        b.installArtifact(b.addExecutable(.{ .name = "data-bridge-gen", .root_module = root, .use_llvm = true }));
        return;
    }
    if (b.option(bool, "data-bridge-runtime-only", "Build only the SDK data owner boundary") orelse false) {
        const native = b.option(bool, "data-bridge-host-test", "Use native ABI for data helper interop") orelse false;
        const object = r4os_build.addStorageRuntimeObject(b, b.path("r4os/data_value_bridge.zig"), sdk_profile.profile.contract_module, sdk_profile.profile.contract_module2, sdk_profile.profile.grapheme_source.?, sdk_profile.builder, native);
        b.getInstallStep().dependOn(&b.addInstallFile(object, "lib/r4sdk_data.o").step);
        return;
    }
    if (b.option([]const u8, "library-helpers-root", "Explicit library owner root for its optional C/Rust helper boundary")) |library_root| {
        if (b.option(bool, "library-helpers-rust-generator-only", "Project the library-owned C helper header to Rust") orelse false) {
            const root = b.createModule(.{ .root_source_file = .{ .cwd_relative = b.pathResolve(&.{ library_root, "Shared/Language/rust_gen.zig" }) }, .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize, .strip = true, .link_libc = true });
            root.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
            root.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
            root.addIncludePath(.{ .cwd_relative = b.pathResolve(&.{ library_root, "Shared/C/include" }) });
            root.addIncludePath(sdk_profile.profile.c_include_root);
            root.addIncludePath(sdk_profile.profile.contract_c_include_root);
            root.addIncludePath(sdk_profile.profile.contract_c_include_root2);
            b.installArtifact(b.addExecutable(.{ .name = "library-helpers-rust-gen", .root_module = root }));
            return;
        }
        const generate = b.option(bool, "library-helpers-generator-only", "Build the library-owned helper generator") orelse false;
        const oracle_only = b.option(bool, "library-helpers-oracle-only", "Build existing recording/media owner oracles") orelse false;
        const native = generate or oracle_only or (b.option(bool, "library-helpers-host-test", "Native ABI for library helper interop") orelse false);
        const target = if (native) b.graph.host else r4os_build.moduleTarget(b);
        const optimize: std.builtin.OptimizeMode = if (generate) sdk_profiles.defaults.debug_optimize else sdk_profiles.defaults.runtime_optimize;
        const owners = b.createModule(.{ .root_source_file = .{ .cwd_relative = b.pathResolve(&.{ library_root, "consumer_helpers.zig" }) }, .target = target, .optimize = optimize, .single_threaded = false });
        const r4os_module = sdk_profile.createR4osModule(target, optimize);
        if (oracle_only) {
            const oracle = b.createModule(.{ .root_source_file = .{ .cwd_relative = b.pathResolve(&.{ library_root, "consumer_oracles.zig" }) }, .target = target, .optimize = sdk_profiles.defaults.debug_optimize, .single_threaded = false, .pic = true });
            oracle.addImport("r4os", r4os_module);
            for ([_][]const u8{ "recording_mux", "recording_pixels", "r4nv_encode" }) |name| oracle.addImport(name, oracle);
            const object = b.addObject(.{ .name = "r4libraries_media_oracle", .root_module = oracle });
            b.getInstallStep().dependOn(&b.addInstallFile(object.getEmittedBin(), "lib/r4libraries_media_oracle.o").step);
            return;
        }
        owners.addImport("r4os", r4os_module);
        inline for (.{ .{ "r4gfx_binding", "R4GFX/Bindings/Zig/r4gfx_abi.zig" }, .{ "r4aco", "R4ACO/Bindings/Zig/r4aco.zig" }, .{ "r4nak", "R4NAK/Bindings/Zig/r4nak.zig" } }) |entry| {
            const binding = b.createModule(.{ .root_source_file = .{ .cwd_relative = b.pathResolve(&.{ library_root, entry[1] }) }, .target = target, .optimize = optimize });
            binding.addImport("r4os", r4os_module);
            owners.addImport(entry[0], binding);
            if (std.mem.eql(u8, entry[0], "r4gfx_binding")) owners.addImport("r4gfx", binding);
        }
        owners.addImport("r4gfx_edid", owners);
        owners.addImport("r4std_console_text", owners);
        owners.addImport("r4std_legacy_tables", b.createModule(.{ .root_source_file = .{ .cwd_relative = b.pathResolve(&.{ library_root, "R4STD/Source/codec_tables.zig" }) }, .target = target, .optimize = optimize }));
        const schema = b.createModule(.{ .root_source_file = .{ .cwd_relative = b.pathResolve(&.{ library_root, "Shared/Language/schema.zig" }) }, .target = target, .optimize = optimize });
        schema.addImport("owners", owners);
        schema.addImport("r4os", r4os_module);
        const root = b.createModule(.{ .root_source_file = .{ .cwd_relative = b.pathResolve(&.{ library_root, if (generate) "Shared/Language/gen.zig" else "Shared/Language/runtime.zig" }) }, .target = target, .optimize = if (generate) sdk_profiles.defaults.debug_optimize else sdk_profiles.defaults.runtime_optimize, .single_threaded = false, .pic = true, .red_zone = false, .stack_check = !native });
        root.addImport("schema", schema);
        if (generate) b.installArtifact(b.addExecutable(.{ .name = "library-helpers-gen", .root_module = root })) else {
            const object = r4os_build.addProbedObject(b, root, sdk_profile.builder, "r4libraries_helpers", native);
            b.getInstallStep().dependOn(&b.addInstallFile(object, "lib/r4libraries_helpers.o").step);
            const facades = r4os_build.addFacadeRuntime(b, .{ .cwd_relative = b.pathResolve(&.{ library_root, "Shared/Language/facades.c" }) }, sdk_profile.profile.c_include_root, sdk_profile.profile.contract_c_include_root, sdk_profile.profile.contract_c_include_root2, native);
            b.getInstallStep().dependOn(&b.addInstallFile(facades, "lib/r4libraries_facades.o").step);
        }
        return;
    }
    if (b.option(bool, "gui-oracle-only", "Build existing GUI callbacks/pixel oracle for language interop") orelse false) {
        const oracle = b.createModule(.{ .root_source_file = b.path("Tests/Conformance/GuiFacadePrototype05824.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize, .pic = true });
        oracle.addImport("r4os", sdk_profile.createR4osModule(b.graph.host, .Debug));
        b.getInstallStep().dependOn(&b.addInstallFile(b.addObject(.{ .name = "r4sdk_gui_oracle", .root_module = oracle }).getEmittedBin(), "lib/r4sdk_gui_oracle.o").step);
        const platform_oracle = b.createModule(.{ .root_source_file = b.path("Tests/Conformance/AudioDeviceFacadePrototype05827.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize, .pic = true });
        platform_oracle.addImport("r4os", sdk_profile.createR4osModule(b.graph.host, .Debug));
        b.getInstallStep().dependOn(&b.addInstallFile(b.addObject(.{ .name = "r4sdk_platform_oracle", .root_module = platform_oracle }).getEmittedBin(), "lib/r4sdk_platform_oracle.o").step);
        return;
    }
    if (b.option(bool, "gui-bridge-runtime-only", "Build only the shared GUI owner boundary") orelse false) {
        const native = b.option(bool, "gui-bridge-host-test", "Use native ABI for GUI bridge interop") orelse false;
        const object = r4os_build.addStorageRuntimeObject(b, b.path("r4os/gui_value_bridge.zig"), sdk_profile.profile.contract_module, sdk_profile.profile.contract_module2, sdk_profile.profile.grapheme_source.?, sdk_profile.builder, native);
        b.getInstallStep().dependOn(&b.addInstallFile(object, "lib/r4sdk_gui.o").step);
        return;
    }
    if (b.option(bool, "gui-bridge-generator-only", "Build the compiler-typed GUI bridge generator") orelse false) {
        const root = b.createModule(.{ .root_source_file = b.path("Tools/GuiBridgeGen/src/main.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize });
        const schema = b.createModule(.{ .root_source_file = b.path("r4os/gui_bridge_schema.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize });
        schema.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
        schema.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
        schema.addImport("r4std_grapheme", b.createModule(.{ .root_source_file = sdk_profile.profile.grapheme_source.?, .target = b.graph.host, .optimize = sdk_profiles.defaults.host_optimize }));
        root.addImport("schema", schema);
        b.installArtifact(b.addExecutable(.{ .name = "gui-bridge-gen", .root_module = root }));
        return;
    }
    if (b.option(bool, "net-bridge-generator-only", "Build the compiler-typed SDK network bridge generator") orelse false) {
        const root = b.createModule(.{ .root_source_file = b.path("Tools/NetBridgeGen/src/main.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.host_optimize });
        const bridge = b.createModule(.{ .root_source_file = b.path("r4os/net_bridge_support.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.host_optimize });
        bridge.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
        bridge.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
        bridge.addImport("r4std_grapheme", b.createModule(.{ .root_source_file = sdk_profile.profile.grapheme_source.?, .target = b.graph.host, .optimize = sdk_profiles.defaults.host_optimize }));
        root.addImport("bridge", bridge);
        b.installArtifact(b.addExecutable(.{ .name = "net-bridge-gen", .root_module = root }));
        return;
    }
    if (b.option(bool, "facade-generator-only", "Build the compiler-typed SDK C/Rust facade projector") orelse false) {
        const root = b.createModule(.{ .root_source_file = b.path("Tools/CFacadeGen/src/main.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.host_optimize, .link_libc = true });
        root.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
        root.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
        root.addIncludePath(sdk_profile.profile.c_include_root);
        root.addIncludePath(sdk_profile.profile.contract_c_include_root);
        root.addIncludePath(sdk_profile.profile.contract_c_include_root2);
        @import("r4os/c_header_inputs.zig").addMacro(b, root, &.{ sdk_profile.profile.c_include_root, sdk_profile.profile.contract_c_include_root, sdk_profile.profile.contract_c_include_root2 });
        b.installArtifact(b.addExecutable(.{ .name = "c-facade-gen", .root_module = root }));
        return;
    }
    if (b.option(bool, "facade-runtime-only", "Build the SDK C facade object for Rust consumers") orelse false) {
        const native = b.option(bool, "facade-host-test", "Use native ABI for facade interop only") orelse false;
        const object = r4os_build.addFacadeRuntime(b, b.path("Shared/C/src/facades.c"), sdk_profile.profile.c_include_root, sdk_profile.profile.contract_c_include_root, sdk_profile.profile.contract_c_include_root2, native);
        const install_c = b.addInstallFile(object, "lib/r4sdk_facades.o");
        b.getInstallStep().dependOn(&install_c.step);
        b.step("facade-c-runtime", "Build only the existing C facade object").dependOn(&install_c.step);
        const storage_runtime = r4os_build.addStorageRuntimeObject(b, b.path("r4os/facade_runtime.zig"), sdk_profile.profile.contract_module, sdk_profile.profile.contract_module2, sdk_profile.profile.grapheme_source.?, sdk_profile.builder, native);
        b.getInstallStep().dependOn(&b.addInstallFile(storage_runtime, "lib/r4sdk_storage.o").step);
        return;
    }
    const r4l_generator_tests = b.addRunArtifact(b.addTest(.{ .root_module = sdk_profile.r4l_contract_generator.?.root_module }));
    b.step("r4l-contract-test", "Run the existing library contract generator cases").dependOn(&r4l_generator_tests.step);

    if (b.option(bool, "heap-host-test-only", "Build the native SDK heap object for its host interop test") orelse false) {
        const root = b.createModule(.{ .root_source_file = b.path("r4os/heap_runtime.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.host_optimize, .pic = true, .single_threaded = false, .stack_check = false });
        root.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
        root.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
        const object = b.addObject(.{ .name = "r4sdk_heap_host", .root_module = root });
        b.getInstallStep().dependOn(&b.addInstallFile(object.getEmittedBin(), "lib/r4sdk_heap_host.o").step);
        const startup = b.createModule(.{ .root_source_file = b.path("r4os/app2_runtime.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.host_optimize, .pic = true, .single_threaded = false, .stack_check = false });
        startup.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
        startup.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
        const startup_object = b.addObject(.{ .name = "r4sdk_startup2_host", .root_module = startup });
        b.getInstallStep().dependOn(&b.addInstallFile(startup_object.getEmittedBin(), "lib/r4sdk_startup2_host.o").step);
        return;
    }
    const heap_runtime = sdk_profile.addHeapRuntime();
    b.getInstallStep().dependOn(&b.addInstallFile(heap_runtime, "lib/r4sdk_heap.o").step);
    if (b.option(bool, "heap-runtime-only", "Build only the module CPU-profile shared C/Rust heap object") orelse false) return;
    const facade_runtime = r4os_build.addFacadeRuntime(b, b.path("Shared/C/src/facades.c"), sdk_profile.profile.c_include_root, sdk_profile.profile.contract_c_include_root, sdk_profile.profile.contract_c_include_root2, false);
    b.getInstallStep().dependOn(&b.addInstallFile(facade_runtime, "lib/r4sdk_facades.o").step);
    b.getInstallStep().dependOn(&b.addInstallFile(sdk_profile.addStorageRuntime(), "lib/r4sdk_storage.o").step);
    b.installArtifact(sdk_profile.builder);
    if (sdk_profile.r4l_contract_generator) |generator| b.installArtifact(generator);

    const module_filter = b.option([]const u8, "module-filter", "Build only matching SDK smoke R4X names") orelse "";
    _ = sdk_profile.addR4MFCatalog(&.{b.path("Smoke")}, module_filter);
    _ = sdk_profile.addR4MFWithOptions(b.path("Tests/Build/R4MFMapping/module.R4MF"), .{
        .zig_module_roots = &.{ b.path("Tests/Build/R4MFMapping/Bindings/external.zig"), b.path("Tests/Build/R4MFMapping/Bindings/shared.zig") },
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
    const data_target = b.resolveTargetQuery(.{ .cpu_arch = .x86_64, .os_tag = b.graph.host.result.os.tag, .abi = b.graph.host.result.abi, .cpu_model = .baseline });
    const data_cases = b.createModule(.{ .root_source_file = b.path("test_owners.zig"), .target = data_target, .optimize = sdk_profiles.defaults.host_optimize });
    data_cases.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
    data_cases.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
    data_cases.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
    data_cases.addImport("r4std_grapheme", b.createModule(.{ .root_source_file = sdk_profile.profile.grapheme_source.?, .target = data_target, .optimize = sdk_profiles.defaults.host_optimize }));
    const data_tests = b.addRunArtifact(b.addTest(.{ .root_module = data_cases, .filters = &.{ "protocol status", "ZIP protocol status", "parse Windows ICO", "parse 8bpp", "bulk ICO", "raster ", "Encoding labels", "TextEncoder", "TextDecoder", "URL", "SHA-256 digest", "release and installed", "semantic versions", "R4M0 metadata", "metadata reads", "V2 derives profile", "contract plan is deterministic", "wire owner", "cli owner", "stream owner", "inventory owner", "device snapshot owner", "metadata2 owner", "text metrics owner", "composition owner", "file picker owner", "audio write owner", "published frame owner", "network family", "network stream" } }));
    const data_step = b.step("data-parity-test", "Existing bounded data, codec, raster, metadata and protocol facade owner cases");
    data_step.dependOn(&data_tests.step);
    // This boundary had a real C/Zig aggregate-call mismatch despite matching
    // record layouts. Keep one small actual ABI call in the existing step.
    const composition_abi = b.createModule(.{ .root_source_file = b.path("r4os/text_composition_abi_tests.zig"), .target = data_target, .optimize = sdk_profiles.defaults.host_optimize, .link_libc = true });
    composition_abi.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
    composition_abi.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
    composition_abi.addImport("r4std_grapheme", b.createModule(.{ .root_source_file = sdk_profile.profile.grapheme_source.?, .target = data_target, .optimize = sdk_profiles.defaults.host_optimize }));
    composition_abi.addIncludePath(sdk_profile.profile.c_include_root);
    composition_abi.addIncludePath(sdk_profile.profile.contract_c_include_root);
    composition_abi.addIncludePath(sdk_profile.profile.contract_c_include_root2);
    composition_abi.addCSourceFile(.{ .file = b.path("Tests/Conformance/TextCompositionABI.c"), .flags = &.{ "-std=c11", "-Wall", "-Wextra", "-Werror" } });
    data_step.dependOn(&b.addRunArtifact(b.addExecutable(.{ .name = "sdk-text-composition-abi", .root_module = composition_abi })).step);
    const web_cases = data_cases;
    const web_tests = b.addRunArtifact(b.addTest(.{ .root_module = web_cases, .filters = &.{
        "HTML parser builds DOM",                  "loaded document MIME",              "CSS parser handles selectors cascade",
        "layout creates deterministic responsive", "font provider drives proportional", "catalogue enumeration retries",
        "font face parser preserves descriptors",  "font cache prepares SHA-256",       "font activation rejects stale epochs",
        "data URL percent and base64",             "background no-repeat composition",  "GET submission uses UTF-8",
        "URL parsing normalization",               "bytecode VM evaluates closures",    "browser runtime allocates and releases",
        "web runtime bounds scripts",              "Canvas 2D keeps bounded",           "offline browser fixtures exercise",
    } }));
    b.step("web-parity-test", "Existing web parse/layout/script/font/form/canvas cases and exact realm teardown").dependOn(&web_tests.step);
    const transport_tests = b.addRunArtifact(b.addTest(.{ .root_module = data_cases, .filters = &.{
        "URL parser separates HTTP",                     "request methods and validated custom headers",
        "complete response heads retain precise errors", "incremental response framing excludes",
        "stream decoder exposes ranges",                 "redirect filtering removes",
        "transport target authorizer observes",          "request deadline remains absolute",
        "stream download pump resumes",                  "stream download observes headers",
        "server credentials",                            "server profile",
        "HTTP81",                                        "CORS preflight derives",
        "TLS handshake records reassemble",              "origin policy blocks",
        "CORS requires an exact origin",                 "cookies honor host path",
        "response cache eviction",                       "response cache modes freshness",
        "resource scheduler rejects stale",              "subdocuments srcdoc inherits",
        "Headers rejects malformed",                     "Headers preserves Set-Cookie",
    } }));
    b.step("transport-parity-test", "Existing bounded HTTP/cache/policy/resource/download owner cases").dependOn(&transport_tests.step);
    const update_cases = b.createModule(.{ .root_source_file = b.path("test_update_owners.zig"), .target = data_target, .optimize = sdk_profiles.defaults.host_optimize });
    update_cases.addImport("r4os_contract", contract_dependency.module("r4os_contract"));
    update_cases.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
    update_cases.addImport("r4std_grapheme", b.createModule(.{ .root_source_file = sdk_profile.profile.grapheme_source.?, .target = data_target, .optimize = sdk_profiles.defaults.host_optimize }));
    if (update_json_core) |file| update_cases.addImport("json_core", b.createModule(.{ .root_source_file = .{ .cwd_relative = file }, .target = data_target, .optimize = sdk_profiles.defaults.host_optimize }));
    const update_tests = b.addRunArtifact(b.addTest(.{ .root_module = update_cases, .filters = @import("Tests/Simulation/UpdateFilters.zig").names }));
    const update_owner_step = b.step("update-parity-test", "Existing current update/catalog/journal/backup owner cases");
    update_owner_step.dependOn(&update_tests.step);
    update_owner_step.dependOn(&addRemovalOwnerTests(b, sdk_profile, data_target).step);
    const gui_cases = b.createModule(.{ .root_source_file = b.path("Tests/Conformance/GuiFacadePrototype05824.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize });
    gui_cases.addImport("r4os", host_r4os);
    const gui_parity = b.addRunArtifact(b.addTest(.{ .root_module = gui_cases, .filters = &.{ "raw GUI events", "command clipboard timer", "transactional paint", "buffered Canvas", "gradient resources", "modern controls" } }));
    b.step("gui-parity-test", "Existing GUI events, frame/immutable generation, pixel and failure oracles").dependOn(&gui_parity.step);
    const graphics_parity = b.addRunArtifact(b.addTest(.{ .root_module = gui_cases, .filters = &.{ "graphics buffer optional tails", "old display and driver prefixes" } }));
    b.step("graphics-parity-test", "Existing graphics descriptors, generations, retire, cursor and telemetry cases").dependOn(&graphics_parity.step);
    const storage_cases = b.createModule(.{ .root_source_file = b.path("Tests/Conformance/StorageFacadePrototype05823.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize });
    storage_cases.addImport("r4os", host_r4os);
    const storage_parity = b.addRunArtifact(b.addTest(.{ .root_module = storage_cases }));
    b.step("storage-parity-test", "Existing file/registry/physical storage cases and imported codec/path owners").dependOn(&storage_parity.step);
    const resource_cases = b.createModule(.{ .root_source_file = b.path("Tests/Conformance/ResourceFacadePrototype05825.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize });
    resource_cases.addImport("r4os", host_r4os);
    const resource_parity = b.addRunArtifact(b.addTest(.{ .root_module = resource_cases, .filters = &.{ "process thread VM and I/O resources", "program handles reject stale copies", "sequential stress reuses", "R4DEV current registry V2" } }));
    b.step("resource-parity-test", "Existing process/thread/VM/I/O resource lifecycle cases only").dependOn(&resource_parity.step);
    const service_cases = b.createModule(.{ .root_source_file = b.path("Tests/Conformance/ServiceNetworkFacadePrototype05826.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize });
    service_cases.addImport("r4os", host_r4os);
    const service_parity = b.addRunArtifact(b.addTest(.{ .root_module = service_cases, .filters = &.{ "service inventory", "service connection and endpoint", "resolver TCP and UDP", "service stop policy", "service loop", "service deadline suffix", "net socket drain", "duration conversion", "duration and deadline", "tagged timeout", "deadline budget", "checked budget" } }));
    b.step("service-parity-test", "Existing service/network, bounded drain and absolute deadline owner cases").dependOn(&service_parity.step);
    const platform_cases = b.createModule(.{ .root_source_file = b.path("Tests/Conformance/AudioDeviceFacadePrototype05827.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize });
    platform_cases.addImport("r4os", host_r4os);
    const platform_step = b.step("platform-parity-test", "Existing Audio/Device/PCM/Power owner cases");
    platform_step.dependOn(&b.addRunArtifact(b.addTest(.{ .root_module = platform_cases })).step);
    const pcm_cases = b.createModule(.{ .root_source_file = b.path("r4os/audio_pcm.zig"), .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize });
    platform_step.dependOn(&b.addRunArtifact(b.addTest(.{ .root_module = pcm_cases })).step);
    platform_step.dependOn(&b.addRunArtifact(b.addTest(.{ .root_module = service_cases, .filters = &.{ "power profile client", "power perCPU client" } })).step);
    const sdk_unit_tests = b.addTest(.{ .root_module = host_r4os });
    const run_sdk_unit_tests = b.addRunArtifact(sdk_unit_tests);
    const dialog_root = b.createModule(.{
        .root_source_file = b.path("r4os/gui.zig"),
        .target = b.graph.host,
        .optimize = sdk_profiles.defaults.debug_optimize,
    });
    dialog_root.addImport("r4os_contract", sdk_profile.profile.contract_module);
    dialog_root.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
    dialog_root.addImport("r4std_grapheme", b.createModule(.{ .root_source_file = sdk_profile.profile.grapheme_source.?, .target = b.graph.host, .optimize = sdk_profiles.defaults.debug_optimize }));
    const dialog_tests = b.addTest(.{ .root_module = dialog_root, .filters = &.{
        "bounded text", "text field",  "text fields",
        "text area",    "ellipsizing", "grapheme",
    } });
    b.step("dialog-text-test", "Actual bounded Unicode dialog and existing scalar widget cases").dependOn(&b.addRunArtifact(dialog_tests).step);

    const cpu_tests_root = b.createModule(.{
        .root_source_file = b.path("r4os/cpu_acceleration_tests.zig"),
        // Independent software SHA oracle; never select the host's optional
        // SHA backend while testing a synthetic executor and its rollback.
        .target = b.resolveTargetQuery(.{ .cpu_arch = .x86_64, .os_tag = b.graph.host.result.os.tag, .abi = b.graph.host.result.abi, .cpu_model = .baseline }),
        .optimize = sdk_profiles.defaults.host_optimize,
    });
    cpu_tests_root.addImport("r4os_contract", sdk_profile.profile.contract_module);
    cpu_tests_root.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
    const cpu_tests = b.addRunArtifact(b.addTest(.{ .root_module = cpu_tests_root }));
    b.step("cpu-acceleration-test", "Exact dispatch, SHA fallback/rollback, memory alignment/overlap/guard pages").dependOn(&cpu_tests.step);
    const entropy_tests_root = b.createModule(.{
        .root_source_file = b.path("r4os/secure_random.zig"),
        .target = b.resolveTargetQuery(.{ .cpu_arch = .x86_64, .os_tag = b.graph.host.result.os.tag, .abi = b.graph.host.result.abi, .cpu_model = .baseline }),
        .optimize = sdk_profiles.defaults.host_optimize,
    });
    entropy_tests_root.addImport("r4os_contract", sdk_profile.profile.contract_module);
    entropy_tests_root.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
    const entropy_tests = b.addRunArtifact(b.addTest(.{ .root_module = entropy_tests_root }));
    b.step("entropy-test", "Shared entropy CF bound, source fallback and whole-output failure").dependOn(&entropy_tests.step);

    const update_engine = b.createModule(.{
        .root_source_file = b.path("r4os/system_update_engine.zig"),
        .target = b.graph.host,
        .optimize = sdk_profiles.defaults.debug_optimize,
    });
    update_engine.addImport("r4os", host_r4os);
    const update_status = b.createModule(.{
        .root_source_file = b.path("Tests/Simulation/CheckSystemUpdateStatus.zig"),
        .target = b.graph.host,
        .optimize = sdk_profiles.defaults.debug_optimize,
    });
    update_status.addImport("r4os", host_r4os);
    update_status.addImport("update_engine", update_engine);
    const update_status_tests = b.addTest(.{
        .root_module = update_status,
        .filters = &.{"status resnapshots"},
    });
    const run_update_status_tests = b.addRunArtifact(update_status_tests);
    b.step("update-status-test", "Run the existing update receipt/status cases").dependOn(&run_update_status_tests.step);

    const vm_allocator_module = b.createModule(.{
        .root_source_file = b.path("r4os/vm_allocator.zig"),
        .target = b.graph.host,
        .optimize = sdk_profiles.defaults.debug_optimize,
    });
    vm_allocator_module.addImport("r4os_contract", sdk_profile.profile.contract_module);
    vm_allocator_module.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
    const vm_allocator_tests = b.addTest(.{ .root_module = vm_allocator_module });
    const run_vm_allocator_tests = b.addRunArtifact(vm_allocator_tests);
    b.step("vm-allocator-test", "Run the existing VM allocator ownership and concurrency tests").dependOn(&run_vm_allocator_tests.step);

    const subsystem_runtime_module = b.createModule(.{
        .root_source_file = b.path("r4os/subsystem_runtime.zig"),
        .target = b.graph.host,
        .optimize = sdk_profiles.defaults.debug_optimize,
    });
    subsystem_runtime_module.addImport("r4os_contract", sdk_profile.profile.contract_module);
    subsystem_runtime_module.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
    const subsystem_runtime_tests = b.addTest(.{ .root_module = subsystem_runtime_module });
    const run_subsystem_runtime_tests = b.addRunArtifact(subsystem_runtime_tests);
    b.step("subsystem-runtime-test", "Run existing SubsystemRuntime owner cases").dependOn(&run_subsystem_runtime_tests.step);

    const ntfs_format = b.createModule(.{
        .root_source_file = b.path("r4os/ntfs_format.zig"),
        .target = b.graph.host,
        .optimize = sdk_profiles.defaults.debug_optimize,
    });
    const ntfs_volume = b.createModule(.{
        .root_source_file = b.path("r4os/ntfs_volume.zig"),
        .target = b.graph.host,
        .optimize = sdk_profiles.defaults.debug_optimize,
    });
    ntfs_volume.addImport("ntfs_format", ntfs_format);
    const ntfs_volume_tests = b.addTest(.{ .root_module = ntfs_volume });
    const run_ntfs_volume_tests = b.addRunArtifact(ntfs_volume_tests);

    const r4x_builder_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("Tools/R4XBuilder/src/main.zig"),
            .target = b.graph.host,
            .optimize = sdk_profiles.defaults.debug_optimize,
        }),
    });
    const run_r4x_builder_tests = b.addRunArtifact(r4x_builder_tests);
    r4x_builder_tests.root_module.addImport("r4os_title_appearance", b.createModule(.{
        .root_source_file = b.path("r4os/appearance_metadata.zig"),
        .target = b.graph.host,
        .optimize = sdk_profiles.defaults.debug_optimize,
    }));
    b.step("packager-test", "Run existing R4M0/ELF packager ownership and relocation cases").dependOn(&run_r4x_builder_tests.step);

    const r4l_contract_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("Tools/R4LContractGen/src/main.zig"),
            .target = b.graph.host,
            .optimize = sdk_profiles.defaults.debug_optimize,
        }),
    });
    const run_r4l_contract_tests = b.addRunArtifact(r4l_contract_tests);

    const catalog_bundle = b.createModule(.{
        .root_source_file = b.path("r4os/r4cp_convert.zig"),
        .target = b.graph.host,
        .optimize = sdk_profiles.defaults.debug_optimize,
    });
    catalog_bundle.addImport("r4os_contract", sdk_profile.profile.contract_module);
    catalog_bundle.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
    const catalog_root = b.createModule(.{
        .root_source_file = b.path("Tools/ModuleCatalog/src/main.zig"),
        .target = b.graph.host,
        .optimize = sdk_profiles.defaults.debug_optimize,
    });
    catalog_root.addImport("contract_bundle", catalog_bundle);
    const catalog = b.addExecutable(.{ .name = "module-catalog", .root_module = catalog_root });
    b.installArtifact(catalog);
    const catalog_tests = b.addTest(.{ .root_module = catalog_bundle });
    const run_catalog_tests = b.addRunArtifact(catalog_tests);
    const catalog_tool_test_root = b.createModule(.{
        .root_source_file = b.path("Tools/ModuleCatalog/src/main.zig"),
        .target = b.graph.host,
        .optimize = sdk_profiles.defaults.debug_optimize,
    });
    catalog_tool_test_root.addImport("contract_bundle", catalog_bundle);
    const catalog_tool_tests = b.addTest(.{ .root_module = catalog_tool_test_root });
    const run_catalog_tool_tests = b.addRunArtifact(catalog_tool_tests);
    const module_test_step = b.step("module-test", "Run the existing manifest and module catalog tests");
    module_test_step.dependOn(&run_catalog_tests.step);
    module_test_step.dependOn(&run_catalog_tool_tests.step);
    module_test_step.dependOn(&parity_check.step);

    const test_step = b.step("test", "Run SDK, build-tool and smoke tests");
    test_step.dependOn(&platform2_tests.step);
    test_step.dependOn(&parity_check.step);
    const input_events_root = b.createModule(.{
        .root_source_file = b.path("r4os/input_events_tests.zig"),
        .target = b.graph.host,
        .optimize = sdk_profiles.defaults.host_optimize,
    });
    input_events_root.addImport("r4os_contract", sdk_profile.profile.contract_module);
    input_events_root.addImport("r4os_contract2", contract_dependency.module("r4os_contract2"));
    const input_events_tests = b.addRunArtifact(b.addTest(.{ .root_module = input_events_root }));
    b.step("input-events-test", "Typed console events, retained producer queue and inaccessible legacy table tail").dependOn(&input_events_tests.step);
    test_step.dependOn(&input_events_tests.step);
    test_step.dependOn(&cpu_tests.step);
    const storage_tools = b.createModule(.{
        .root_source_file = b.path("r4os/storage_tools.zig"),
        .target = b.graph.host,
        .optimize = sdk_profiles.defaults.debug_optimize,
    });
    const storage_fixture = b.createModule(.{
        .root_source_file = b.path("Tests/Simulation/CheckStorageTools0769.zig"),
        .target = b.graph.host,
        .optimize = sdk_profiles.defaults.debug_optimize,
    });
    storage_fixture.addImport("storage_tools", storage_tools);
    const storage_tests = b.addRunArtifact(b.addTest(.{ .root_module = storage_fixture }));
    b.step("storage-tools-test", "Shared partition/format component fixtures and fault cases").dependOn(&storage_tests.step);
    test_step.dependOn(&storage_tests.step);
    test_step.dependOn(b.getInstallStep());
    test_step.dependOn(&run_sdk_unit_tests.step);
    test_step.dependOn(&run_update_status_tests.step);
    test_step.dependOn(&run_vm_allocator_tests.step);
    test_step.dependOn(&run_subsystem_runtime_tests.step);
    test_step.dependOn(&run_ntfs_volume_tests.step);
    test_step.dependOn(&run_r4x_builder_tests.step);
    test_step.dependOn(&run_r4l_contract_tests.step);
    test_step.dependOn(&run_catalog_tests.step);
    test_step.dependOn(&run_catalog_tool_tests.step);
}
