//! Shared display wording; nominal timing is never a measured refresh rate.
pub fn policy(value: u32) []const u8 {
    return switch (value) { 0 => "Off", 1 => "Fullscreen animation", 2 => "Fullscreen and animated windows", else => "Unknown" };
}
pub fn phase(value: u32) []const u8 {
    return switch (value) { 0 => "Fixed refresh", 1 => "Enabling VRR", 2 => "VRR active", 3 => "Returning to fixed refresh",
        4 => "Fixed refresh; VRR fault latched", 5 => "Output lost", else => "Unknown" };
}
pub fn reason(value: u32) []const u8 {
    return switch (value) {
        0 => "Eligible", 1 => "Disabled by policy", 2 => "No animation", 3 => "Windowed content",
        4 => "Unavailable for this mode or output", 5 => "Display transition", 6 => "HDR combination unavailable", 7 => "Monitor combination unavailable",
        8 => "Capture active", 9 => "Audio clock constraint", 10 => "Link changed", 11 => "Timing fault",
        12 => "Flicker reported", 13 => "Refresh clock unavailable", else => "Unknown",
    };
}
