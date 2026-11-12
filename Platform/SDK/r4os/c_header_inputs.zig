//! Bind Clang/C-import build caching to the actual SDK/Contract headers.
//! Header-only changes must invalidate compiler-projected Rust declarations
//! and the C facade object even when an older C-import cache is present.
const std = @import("std");
pub fn addMacro(b: *std.Build, module: *std.Build.Module, roots: []const std.Build.LazyPath) void {
    var hash = std.crypto.hash.sha2.Sha256.init(.{});
    for (roots, 0..) |root, index| {
        hash.update(b.fmt("root={d}\n", .{index}));
        const path = root.getPath(b);
        var dir = std.Io.Dir.cwd().openDir(b.graph.io, path, .{ .iterate = true }) catch |err| @panic(b.fmt("C header inputs unavailable: {s}", .{@errorName(err)}));
        defer dir.close(b.graph.io);
        var walker = dir.walk(b.allocator) catch @panic("OOM");
        defer walker.deinit();
        var names: std.ArrayList([]const u8) = .empty;
        while (walker.next(b.graph.io) catch @panic("C header walk failed")) |entry| {
            if (entry.kind == .file and std.mem.endsWith(u8, entry.path, ".h")) names.append(b.allocator, b.dupe(entry.path)) catch @panic("OOM");
        }
        std.mem.sort([]const u8, names.items, {}, struct {
            fn less(_: void, a: []const u8, z: []const u8) bool {
                return std.mem.lessThan(u8, a, z);
            }
        }.less);
        for (names.items) |name| {
            const bytes = dir.readFileAlloc(b.graph.io, name, b.allocator, .limited(16 * 1024 * 1024)) catch @panic("C header read failed");
            hash.update(name);
            hash.update(&.{0});
            hash.update(bytes);
            hash.update(&.{0});
        }
    }
    const digest = std.fmt.bytesToHex(hash.finalResult(), .lower);
    module.addCMacro("_R4OS_SDK_C_HEADER_INPUT_SHA256", b.fmt("\"{s}\"", .{digest}));
}
