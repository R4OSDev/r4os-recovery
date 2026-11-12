const std = @import("std");
const sdk = @import("r4os_sdk");
pub fn build(b: *std.Build) void {
    const dep = b.dependency("r4os_sdk", .{});
    const profile = sdk.sdk(b, dep, .{});
    _ = profile.addR4MF(b.path("module.R4MF"));
}
