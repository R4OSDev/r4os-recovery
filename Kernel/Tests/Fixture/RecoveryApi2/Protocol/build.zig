const std = @import("std");
pub fn build(b: *std.Build) void {
 const owner = b.lazyImport(@This(), "r4os_sdk") orelse return;
 const sdk = owner.sdk(b, b.dependencyFromBuildZig(owner, .{}), .{});
 _ = sdk.addR4MF(b.path("module.R4MF"));
}
