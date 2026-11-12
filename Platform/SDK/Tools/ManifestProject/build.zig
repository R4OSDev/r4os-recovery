const std = @import("std");
const sdk = @import("r4os_sdk");
pub fn build(b: *std.Build) void {
    const project = b.option([]const u8, "project-root", "Explicit manifest project root") orelse @panic("project-root is required");
    const manifest = std.fs.path.join(b.allocator, &.{ project, "module.R4MF" }) catch @panic("OOM");
    const dep = b.dependency("r4os_sdk", .{});
    _ = sdk.sdk(b, dep, .{}).addR4MF(.{ .cwd_relative = manifest });
}
