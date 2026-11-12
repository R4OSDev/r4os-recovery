const std = @import("std");
const catalog = @import("r4os/subsystem_catalog.zig");
const launch = @import("r4os/subsystem_launch.zig");
const host = @import("r4os/subsystem_host.zig");
const runtime = @import("r4os/subsystem_runtime.zig");
const persistence = @import("r4os/subsystem_persistence.zig");
const Config = struct {
    pub const save_root = "C:\\TEMP\\SD65\\";
    pub const root_directories = [_][]const u8{"C:\\TEMP\\SD65"};
    pub const rtc_record_bytes: usize = 4;
    pub fn validateRtc(bytes: []const u8) bool {
        return std.mem.eql(u8, bytes, "RTC!");
    }
};
test "subsystem owner collector includes actual current source tests" {
    std.testing.refAllDecls(catalog);
    std.testing.refAllDecls(launch);
    std.testing.refAllDecls(host);
    std.testing.refAllDecls(runtime);
    std.testing.refAllDecls(persistence.R4osStore(Config));
}
test "runtime save configuration shares static canonical paths and validates scratch" {
    const D = persistence.R4osStore(persistence.Configuration);
    const S = persistence.R4osStore(Config);
    var scratch: [4]u8 = undefined;
    var config = persistence.Configuration{ .save_root = Config.save_root, .root_directories = &.{"C:\\TEMP\\SD65"}, .rtc_record_bytes = 4, .record_scratch = &scratch, .validate_rtc = &validate };
    try std.testing.expect(config.valid());
    const digest = [_]u8{0xAB} ** 32;
    const dynamic = try D.dataPath(&config, &digest, .sram);
    const original = try S.dataPath(&digest, .sram);
    try std.testing.expectEqualStrings(original.bytes(), dynamic.bytes());
    config.record_scratch = &.{};
    try std.testing.expect(!config.valid());
    try std.testing.expectError(error.Unsupported, D.dataPath(&config, &digest, .sram));
}
fn validate(_: ?*anyopaque, bytes: []const u8) bool {
    return Config.validateRtc(bytes);
}
