//! Resource helpers for a caller-owned DEVICE_V1 session.
const std = @import("std");
const r = @import("r4os");
const gfx = @import("r4gfx");

/// Allocate a system-backed XRGB image. Descriptor arithmetic is checked before
/// the provider applies its own memory budget. The output is valid only on OK.
pub fn createTarget(api: *const gfx.DeviceV1Client, device: *const gfx.R4GfxDevice,
    width: u32, height: u32, output: *gfx.R4GfxResource) i32
{
    if (width == 0 or height == 0) return gfx.status_invalid;
    const pitch = @as(u64, width) * 4;
    const bytes = std.math.mul(u64, pitch, height) catch return gfx.status_overflow;
    var desc = std.mem.zeroes(gfx.R4GfxResourceDesc);
    desc.version = 1;
    desc.size = @sizeOf(gfx.R4GfxResourceDesc);
    desc.kind = gfx.resource_image;
    desc.flags = gfx.image_target;
    desc.source_kind = gfx.source_create_system;
    desc.image = .{ .cpu_address = 0, .byte_length = bytes, .pitch = pitch,
        .width = width, .height = height, .format = gfx.format_xrgb8888, .reserved = 0 };
    return api.resource_create(device, &desc, output);
}

/// Import a live BO reference. This acquires an independent reference without
/// copying pixels. The provider derives and validates geometry, adapter and
/// generation from the BO; a CPU pointer is not a shareable BO reference.
pub fn importImage(api: *const gfx.DeviceV1Client, device: *const gfx.R4GfxDevice,
    source: *const r.abi.GfxBufferHandle, writable: bool, output: *gfx.R4GfxResource) i32
{
    var desc = std.mem.zeroes(gfx.R4GfxResourceDesc);
    desc.version = 1;
    desc.size = @sizeOf(gfx.R4GfxResourceDesc);
    desc.kind = gfx.resource_image;
    desc.flags = if (writable) gfx.image_target else 0;
    desc.source_kind = gfx.source_import_buffer;
    desc.source_address = @intFromPtr(source);
    return api.resource_create(device, &desc, output);
}
