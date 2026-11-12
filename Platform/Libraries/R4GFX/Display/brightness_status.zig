const a = @import("r4os").abi;
pub fn reason(value: u32) []const u8 {
    return switch (value) {
        a.gfx_brightness_reason_none => "Brightness control is available.",
        a.gfx_brightness_reason_firmware_owner => "Firmware currently controls this panel's backlight.",
        a.gfx_brightness_reason_invalid_panel => "The panel did not provide usable brightness settings.",
        a.gfx_brightness_reason_timeout => "The panel did not respond to the brightness change.",
        a.gfx_brightness_reason_io => "The brightness change failed. The current level is uncertain.",
        a.gfx_brightness_reason_inactive => "Activate this display to change its brightness.",
        else => "Brightness control is unavailable for this display.",
    };
}
