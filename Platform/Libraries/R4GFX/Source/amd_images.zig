// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Canonical AMD image admission. The library owns geometry; the R4D owns
//! measured topology, BO memory generation and physical execution.
const std = @import("std");
const a = @import("r4os").abi;
const amd = @import("r4amd_binding");
const d = @import("device.zig");
pub const Result = struct { request: amd.R4AmdImageRequest, layout: amd.R4AmdImageLayout };
fn result(rc: i32) d.Error!void {
    switch (rc) {
        amd.status_ok => {},
        amd.status_unsupported => return error.Unsupported,
        amd.status_stale => return error.Stale,
        amd.status_limit, amd.status_oom => return error.Limit,
        else => return error.Invalid,
    }
}
pub fn query(device: *d.Device, desc: a.GfxBufferDescriptor) d.Error!Result {
    if (device.backend() != d.c.render_backend_amd) return error.Unsupported;
    const client = device.caller.client(amd.ImageV1Client) catch return error.Unsupported;
    var properties: a.GfxBackendProperties = .{};
    try d.platform(device.queues().backendProperties(&device.selected.binding, &properties));
    if (properties.version != 1 or properties.size < @sizeOf(a.GfxBackendProperties) or
        properties.interface_id_lo != amd.image_v1_header.interface_id_lo or properties.interface_id_hi != amd.image_v1_header.interface_id_hi or
        ((properties.revision != 1 or properties.data_bytes != @sizeOf(amd.R4AmdArchitecture)) and
        (properties.revision != 2 or properties.data_bytes != @sizeOf(amd.R4AmdDeviceFacts)) and
             (properties.revision != 3 or properties.data_bytes != @sizeOf(amd.R4AmdDeviceFactsV3)))) return error.Unsupported;
    for (properties.data[properties.data_bytes..]) |byte| if (byte != 0) return error.Invalid;
    const arch = std.mem.bytesToValue(amd.R4AmdArchitecture, properties.data[0..@sizeOf(amd.R4AmdArchitecture)]);
    return validate(client, arch, device.selected, desc, @ptrFromInt(std.mem.alignForward(usize, @intFromPtr(&device.amd_image_scratch), 16)));
}
pub fn validate(client: amd.ImageV1Client, arch: amd.R4AmdArchitecture, selected: a.GfxBackendInfo, desc: a.GfxBufferDescriptor, scratch: *align(16) [65536]u8) d.Error!Result {
    try validateArchitecture(arch, selected);
    if (selected.binding.adapter_id == 0 or selected.memory_generation == 0 or arch.memory_generation != selected.memory_generation or
        desc.adapter_id != selected.binding.adapter_id or desc.device_generation != selected.memory_generation) return error.Stale;
    if (desc.version != 1 or desc.size < @sizeOf(a.GfxBufferDescriptor) or desc.location != a.gfx_buffer_location_device_local or
        desc.driver_owner == 0 or desc.plane_count != 1 or desc.reserved0 != 0 or desc.plane_offsets[0] != 0 or
        desc.usage & (a.gfx_buffer_usage_cpu_read | a.gfx_buffer_usage_cpu_write) != 0 or desc.byte_length > arch.max_image_bytes or
        desc.alignment < arch.bind_alignment) return error.Unsupported;
    for (1..4) |i| if (desc.plane_offsets[i] != 0 or desc.plane_pitches[i] != 0) return error.Invalid;
    const pitch = std.math.cast(u32, desc.plane_pitches[0]) orelse return error.Overflow;
    const sw: u32 = if (desc.modifier == 0) 0 else @intCast((desc.modifier >> 8) & 31);
    const usage: u32 = amd.image_usage_texture | (if (desc.usage & a.gfx_buffer_usage_render != 0) amd.image_usage_color else 0) |
        (if (desc.usage & a.gfx_buffer_usage_scanout != 0) amd.image_usage_scanout else 0);
    const request: amd.R4AmdImageRequest = .{ .version = 1, .size = @sizeOf(amd.R4AmdImageRequest), .gb_addr_config = arch.gb_addr_config, .chip_revision = arch.chip_revision, .device_id = arch.device_id, .gc_version = arch.gc_version, .resource_type = 1, .format = desc.format, .width = desc.width, .height = desc.height, .depth = 1, .mip_count = 1, .samples = 1, .usage = usage, .swizzle = sw, .pipe_xor = 0, .pitch = pitch, .reserved = 0, .modifier = desc.modifier };
    var layout: amd.R4AmdImageLayout = undefined;
    var mip: amd.R4AmdMip = undefined;
    try result(client.import_image(&request, &.{ .version = 1, .size = @sizeOf(amd.R4AmdImageImport), .byte_length = desc.byte_length, .alignment = desc.alignment, .offset = desc.plane_offsets[0], .modifier = desc.modifier, .adapter_id = desc.adapter_id, .reserved = 0, .memory_generation = desc.device_generation, .expected_adapter = selected.binding.adapter_id, .metadata_state = 0, .expected_memory_generation = selected.memory_generation, .pitch = pitch, .usage = usage }, scratch, scratch.len, &layout, @ptrCast(&mip), 1));
    return .{ .request = request, .layout = layout };
}

pub fn validateArchitecture(arch: amd.R4AmdArchitecture, selected: a.GfxBackendInfo) d.Error!void {
    const raven2 = arch.gc_version == amd.gc_9_2_2 and arch.sdma_version == amd.sdma_4_1_1;
    const picasso = arch.gc_version == amd.gc_9_1_0 and arch.sdma_version == amd.sdma_4_1_0;
    if (arch.version != 1 or arch.size != @sizeOf(amd.R4AmdArchitecture) or arch.vendor_id != amd.vendor_id or arch.device_id != 0x15d8 or
        (!picasso and !raven2) or
        arch.chip_revision < (if (raven2) @as(u32, 0x81) else 0x41) or arch.chip_revision > (if (raven2) @as(u32, 0x88) else 0x48) or arch.flags != 0 or arch.reserved != 0 or
        arch.bind_alignment != 4096 or arch.max_image_bytes != 64 * 1024 * 1024) return error.Unsupported;
    if (selected.profile.interface_id_lo != amd.backend_v1_header.interface_id_lo or selected.profile.interface_id_hi != amd.backend_v1_header.interface_id_hi or
        selected.profile.revision != 1 or selected.profile.data_bytes != @sizeOf(amd.R4AmdDriverProfile)) return error.Unsupported;
    const profile = std.mem.bytesToValue(amd.R4AmdDriverProfile, selected.profile.data[0..@sizeOf(amd.R4AmdDriverProfile)]);
    if (profile.vendor_id != arch.vendor_id or profile.device_id != arch.device_id or profile.gc_version != arch.gc_version or profile.sdma_version != arch.sdma_version) return error.Unsupported;
}
