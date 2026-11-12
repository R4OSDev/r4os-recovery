//! Current table admission only. PCM, service and device work stay at owners.
const a = @import("r4os_contract").abi;
const p = @import("program.zig");
const S = @import("platform_support.zig").Context;
pub export fn R4SdkPlatformOpenNative2(fp: u64, out: *S, view: *const @import("platform2.zig").Context) callconv(.c) i32 {
    if (fp != @import("gui_bridge_schema.zig").fingerprint) return a.io_error_invalid;
    _ = view.system() orelse return a.err_no_group;
    const base: p.Context = .{ .generation2 = view };
    // The input view remains in the borrowed App2. No self-pointer is formed
    // in a value that will subsequently move into caller-owned storage.
    out.* = .{
        .bundle = undefined,
        .sys = @import("r4sys.zig").Context.fromProgram(base),
        .dev = @import("r4dev.zig").Context.fromProgram(base),
        .audio_raw = @import("r4audio.zig").Context.fromProgram(base),
        .audio = undefined,
        .devices = undefined,
    };
    out.audio = .{ .sys = out.sys, .raw = out.audio_raw };
    out.devices = .{ .raw = out.dev };
    return 0;
}
pub export fn R4SdkPlatformOpenNative(fp: u64, out: *S, raw: *const a.R4XStartContext) callconv(.c) i32 {
    if (fp != @import("gui_bridge_schema.zig").fingerprint) return a.io_error_invalid;
    const bundle = p.bundleValueFromR4XStart(raw) orelse return a.err_no_group;
    const sys = bundle.sys orelse return a.err_no_group;
    const current = a.R4XStartR4Sys{};
    if (sys.abi_version < current.abi_version or sys.size < current.size) return a.err_no_fn;
    inline for (.{ .{ bundle.dev, a.R4XStartR4Dev{} }, .{ bundle.audio, a.R4XStartR4Audio{} } }) |entry| {
        if (entry[0]) |table| if (table.abi_version < entry[1].abi_version or table.size < entry[1].size) return a.err_no_fn;
    }
    out.* = .{ .bundle = bundle, .sys = undefined, .dev = undefined, .audio_raw = undefined, .audio = undefined, .devices = undefined };
    out.sys = @import("r4sys.zig").Context.init(&out.bundle);
    out.dev = @import("r4dev.zig").Context.init(&out.bundle);
    out.audio_raw = @import("r4audio.zig").Context.init(&out.bundle);
    out.audio = .{ .sys = out.sys, .raw = out.audio_raw };
    out.devices = .{ .raw = out.dev };
    return 0;
}
pub export fn R4SdkPlatformSystem(out: *S) callconv(.c) *@import("r4sys.zig").Context {
    return &out.sys;
}
pub export fn R4SdkPlatformDevice(out: *S) callconv(.c) *@import("r4dev.zig").Context {
    return &out.dev;
}
pub export fn R4SdkPlatformAudio(out: *S) callconv(.c) *@import("app_audio.zig").Audio {
    return &out.audio;
}
pub export fn R4SdkPlatformAudioRaw(out: *S) callconv(.c) *@import("r4audio.zig").Context {
    return &out.audio_raw;
}
pub export fn R4SdkPlatformDevices(out: *S) callconv(.c) *@import("app_devices.zig").Devices {
    return &out.devices;
}
