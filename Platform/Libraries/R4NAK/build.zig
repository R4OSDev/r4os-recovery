const std = @import("std");

fn trackTree(b: *std.Build, run: *std.Build.Step.Run, path: []const u8) void {
    var dir = std.Io.Dir.cwd().openDir(b.graph.io, b.pathFromRoot(path), .{ .iterate = true }) catch @panic("Missing native compiler input directory");
    defer dir.close(b.graph.io);
    var iter = dir.iterate();
    while (iter.next(b.graph.io) catch @panic("Cannot enumerate compiler inputs")) |entry| {
        const child = b.pathJoin(&.{ path, entry.name });
        if (entry.kind == .directory) trackTree(b, run, child) else if (entry.kind == .file) run.addFileInput(b.path(child));
    }
}
pub fn build(b: *std.Build) void {
    b.addNamedLazyPath("binding", b.path("Bindings/Zig/r4nak.zig"));
    const sdk_build = b.lazyImport(@This(), "r4os_sdk") orelse return;
    const sdk = sdk_build.sdk(b, b.dependencyFromBuildZig(sdk_build, .{}), .{});
    const native = b.addSystemCommand(&.{ "pwsh", "-NoProfile", "-File" });
    native.addFileArg(b.path("Tools/Build.ps1"));
    if (b.option(bool, "offline", "Require already cached compiler source archives") orelse false) native.addArg("-Offline");
    native.addArg("-OutputFile");
    const archive = native.addOutputFileArg("R4NAK.a");
    inline for (.{ "Port", "ThirdParty", "Tools" }) |tree| trackTree(b, native, tree);
    inline for (.{ "Source/native.c", "Source/native.h" }) |path| native.addFileInput(b.path(path));
    // Toolchain/source verification remains the PS7 owner's responsibility.
    // Always enter it so changed host tools cannot silently reuse a Zig step.
    native.has_side_effects = true;
    _ = sdk.addR4MFWithOptions(b.path("module.R4MF"), .{ .native_archives = &.{archive} });
    const host = sdk.createR4osModule(b.graph.host, .ReleaseSafe);
    const implementation = b.createModule(.{ .root_source_file = b.path("Contract/Generated/implementation_abi.zig"), .target = b.graph.host });
    implementation.addImport("r4os", host);
    const binding = b.createModule(.{ .root_source_file = b.path("Bindings/Zig/r4nak.zig"), .target = b.graph.host });
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
    b.getInstallStep().dependOn(&abi_check.step);
    b.step("test", "R4NAK C/Zig ABI conformance").dependOn(&abi_check.step);
}
