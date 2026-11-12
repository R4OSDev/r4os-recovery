const r4os = @import("r4os");
const runtime = @import("runtime.zig");

pub const abi = runtime.abi;
pub const name = abi.module_name;
pub const import_text_v1 = "R4STD:TEXT_V1:1";
pub const import_codec_v1 = "R4STD:CODEC_V1:1";
pub const import_settings_v1 = "R4STD:SETTINGS_V1:1";
pub const import_date_v1 = "R4STD:DATE_V1:1";
pub const import_time_v1 = "R4STD:TIME_V1:1";
pub const import_config_v1 = "R4STD:CONFIG_V1:1";

pub const text = @import("text.zig");
pub const codec = @import("codec.zig");
pub const settings = @import("settings.zig");
pub const date = @import("date.zig");
pub const time = @import("time.zig");
pub const config = @import("config.zig");
pub const text_file = @import("text_file.zig");
pub const app_assoc = @import("app_assoc.zig");
pub const file_handler = @import("file_handler.zig");
pub const subsystem_runtime = @import("subsystem_runtime.zig");
pub const shortcut = @import("shortcut.zig");

pub fn init(raw: *const r4os.abi.R4XStartContext) bool {
    return runtime.init(raw);
}

pub fn init2(raw: *const r4os.platform2.abi.R4XStartContext2) bool {
    return runtime.init2(raw);
}

pub fn initialized() bool {
    return runtime.initialized();
}

pub fn resetForTesting() void {
    runtime.resetForTesting();
}

test "R4STD binding names only local interfaces" {
    const std = @import("std");
    try std.testing.expectEqualStrings("R4STD", name);
    try std.testing.expectEqualStrings("R4STD:CONFIG_V1:1", import_config_v1);
}
