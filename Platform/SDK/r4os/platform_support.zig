//! Stable current platform contexts, without product/hardware policy.
const p = @import("program.zig");
pub const Context = struct {
    bundle: p.Bundle,
    sys: @import("r4sys.zig").Context,
    dev: @import("r4dev.zig").Context,
    audio_raw: @import("r4audio.zig").Context,
    audio: @import("app_audio.zig").Audio,
    devices: @import("app_devices.zig").Devices,
};
