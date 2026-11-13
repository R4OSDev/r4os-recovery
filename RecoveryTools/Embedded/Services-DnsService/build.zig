const std = @import("std");

/// Eigenstaendiger Bau aus dem Manifest.
///
/// `zig build` erzeugt das Modul allein aus diesem Verzeichnis, ohne den Rest
/// von R4OS. Die Datei zeigt nur auf module.R4MF - Name, Klasse, Quellen,
/// Ziel, Imports und Metadaten stehen dort und nirgends sonst.
pub fn build(b: *std.Build) void {
    const sdk_build = b.lazyImport(@This(), "r4os_sdk") orelse return;
    const sdk_dep = b.dependencyFromBuildZig(sdk_build, .{});
    const sdk = sdk_build.sdk(b, sdk_dep, .{});
    const codec: std.Build.LazyPath = .{ .cwd_relative = b.pathResolve(&.{"../Protocols-NetDns/src/address_codec.zig"}) };
    _ = sdk.addR4MFWithOptions(b.path("module.R4MF"), .{ .zig_module_roots = &.{codec} });
}
