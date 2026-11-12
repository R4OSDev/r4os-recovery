//
// Copyright © 2011 Red Hat All Rights Reserved.
// Copyright © 2017 Advanced Micro Devices, Inc.
//
// SPDX-License-Identifier: MIT
//
// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Stateless image provider. Every call builds/destroys genuine upstream
//! AddrLib in disjoint caller scratch. No global device/allocator/lock.
const std = @import("std");
const max_bytes = 64 * 1024 * 1024;
const invalid_modifier = std.math.maxInt(u64);
// AddrLib uses its own callback-backed Object operators. This is the only
// C++ ABI failure symbol it references; an impossible pure virtual call traps.
export fn __cxa_pure_virtual() callconv(.c) noreturn {
    @trap();
}

pub fn Provider(comptime c: type) type { return struct {
extern fn r4amd_addr_compute(*const c.R4AmdImageRequest, [*]u8, u32, *c.R4AmdImageLayout, [*]c.R4AmdMip, ?*const c.R4AmdCoordinate, ?*c.R4AmdImageAddress, ?*c.R4AmdMetadata) callconv(.c) i32;
extern fn r4amd_addr_descriptors(*const c.R4AmdImageRequest, *const c.R4AmdImageLayout, *const c.R4AmdImageView, *c.R4AmdImageDescriptors) callconv(.c) i32;
pub const Format = struct { bytes: u32, block: u32 = 1, depth: bool = false, color: bool = true };
pub fn pixelFormat(value: u32) ?Format {
    return switch (value) {
        875713112, 875713089, 808669784, 808669761 => .{ .bytes = 4 },
        1211384385, 942948929 => .{ .bytes = 8 },
        538982482 => .{ .bytes = 1 },
        0x38385247, 0x20363152 => .{ .bytes = 2 }, // RG8, R16
        0x32335247 => .{ .bytes = 4 }, // RG16
        0x01000001 => .{ .bytes = 4, .depth = true, .color = false },
        0x01000002 => .{ .bytes = 2, .depth = true, .color = false },
        0x01000003 => .{ .bytes = 1, .depth = true, .color = false }, // Separate S8 attachment.
        0x01000101 => .{ .bytes = 8, .block = 4, .color = false },
        0x01000103, 0x01000105, 0x01000107 => .{ .bytes = 16, .block = 4, .color = false },
        else => null,
    };
}
pub fn modifier(gb: u32, sw: u32) ?u64 {
    if (sw == 0) return 0;
    const base: u64 = 0x0200000000000001 | @as(u64, sw) << 8;
    if (sw == 9 or sw == 10) return base;
    if (sw == 22 or sw == 25 or sw == 26 or sw == 27) {
        const pipe = @min((gb & 7) + ((gb >> 19) & 3), if (sw == 22) @as(u32, 4) else 8);
        const bank = @min((gb >> 12) & 7, (if (sw == 22) @as(u32, 4) else 8) - pipe);
        return base | @as(u64, pipe) << 21 | @as(u64, bank) << 24;
    }
    // Other valid GFX9 swizzles can be used internally, but have no public
    // modifier admitted by this provider. An import must reject this sentinel.
    if (sw <= 11 or (sw >= 16 and sw <= 27)) return invalid_modifier;
    return null;
}
pub fn validate(r: c.R4AmdImageRequest) i32 {
    if (r.version != 1 or r.size != @sizeOf(c.R4AmdImageRequest) or r.reserved != 0 or r.usage == 0 or r.usage & ~@as(u32, 31) != 0 or
        r.width == 0 or r.height == 0 or r.depth == 0 or r.mip_count == 0 or r.samples == 0) return c.status_invalid;
    if (@import("asic.zig").Profiles(c).image(r.device_id, r.gc_version, r.chip_revision) == null or
        r.resource_type > 2 or r.gb_addr_config == 0 or (r.gb_addr_config & 7) > 5 or
        ((r.gb_addr_config >> 3) & 7) != 0 or ((r.gb_addr_config >> 12) & 7) > 4 or
        ((r.gb_addr_config >> 26) & 3) > 2 or r.pipe_xor != 0) return c.status_unsupported;
    if (r.width > 16384 or r.height > 16384 or r.depth > 2048 or r.mip_count > 15 or r.samples > 8) return c.status_limit;
    if (!std.math.isPowerOfTwo(r.samples) or (r.resource_type == 0 and (r.height != 1 or r.samples != 1)) or
        (r.resource_type == 2 and r.samples != 1) or (r.samples > 1 and r.mip_count != 1)) return c.status_invalid;
    const dimension = @max(r.width, @max(r.height, if (r.resource_type == 2) r.depth else 1));
    if (r.mip_count > 32 - @clz(dimension)) return c.status_invalid;
    const f = pixelFormat(r.format) orelse return c.status_unsupported;
    if (r.format == 0x01000003 and (r.usage != c.image_usage_depth or r.samples != 1 or r.depth != 1 or r.mip_count != 1)) return c.status_unsupported;
    if (f.depth != (r.usage & c.image_usage_depth != 0) or (r.usage & c.image_usage_color != 0 and !f.color) or
        (f.block != 1 and (r.samples != 1 or r.usage != c.image_usage_texture)) or
        (f.depth and r.usage & (c.image_usage_color | c.image_usage_storage | c.image_usage_scanout) != 0)) return c.status_unsupported;
    const minimum = @as(u64, (r.width + f.block - 1) / f.block) * ((r.height + f.block - 1) / f.block) * r.depth * r.samples * f.bytes;
    if (minimum > max_bytes) return c.status_limit;
    if (r.pitch != 0 and (r.pitch % f.bytes != 0 or r.pitch / f.bytes < (r.width + f.block - 1) / f.block or r.pitch > 1024 * 1024)) return c.status_invalid;
    const expected = modifier(r.gb_addr_config, r.swizzle) orelse return c.status_unsupported;
    if (r.modifier != expected) return c.status_unsupported;
    if (r.swizzle == 0 and (f.depth or r.samples > 1)) return c.status_unsupported;
    if (r.usage & c.image_usage_scanout != 0 and (r.resource_type != 1 or r.mip_count != 1 or r.depth != 1 or r.samples != 1 or
        (r.format != 875713112 and r.format != 808669784) or (r.swizzle != 0 and r.swizzle != 9 and r.swizzle != 25))) return c.status_unsupported;
    return c.status_ok;
}
const Range = struct { start: usize, bytes: usize, align_to: usize };
fn range(p: anytype) Range {
    const T = @typeInfo(@TypeOf(p)).pointer.child;
    return .{ .start = @intFromPtr(p), .bytes = @sizeOf(T), .align_to = @alignOf(T) };
}
fn spans(items: []const Range) bool {
    for (items, 0..) |item, i| {
        if (item.start == 0 or item.bytes == 0 or item.start % item.align_to != 0) return false;
        const end = std.math.add(usize, item.start, item.bytes) catch return false;
        for (items[0..i]) |other| if (item.start < other.start + other.bytes and other.start < end) return false;
    }
    return true;
}
fn workspaceRange(workspace: [*]u8, bytes: u32) Range {
    return .{ .start = @intFromPtr(workspace), .bytes = bytes, .align_to = 16 };
}
fn mipRange(mips: [*]c.R4AmdMip, capacity: u32) Range {
    return .{ .start = @intFromPtr(mips), .bytes = @as(usize, capacity) * @sizeOf(c.R4AmdMip), .align_to = @alignOf(c.R4AmdMip) };
}
fn sizes(bytes: u32, capacity: u32) bool {
    return bytes != 0 and bytes <= c.image_workspace_bytes and capacity != 0 and capacity <= c.image_max_mips;
}
const Result = struct { layout: c.R4AmdImageLayout = undefined, mips: [15]c.R4AmdMip = undefined };
fn compute(r: *const c.R4AmdImageRequest, workspace: [*]u8, bytes: u32, result: *Result, coord: ?*const c.R4AmdCoordinate, address_out: ?*c.R4AmdImageAddress, meta: ?*c.R4AmdMetadata) i32 {
    const valid = validate(r.*);
    if (valid != c.status_ok) return valid;
    const rc = r4amd_addr_compute(r, workspace, bytes, &result.layout, &result.mips, coord, address_out, meta);
    if (rc != c.status_ok) return rc;
    const l = result.layout;
    if (l.byte_length == 0 or l.byte_length > max_bytes or l.slice_bytes == 0 or l.slice_bytes > l.byte_length) return c.status_limit;
    if (l.alignment == 0 or !std.math.isPowerOfTwo(l.alignment) or l.alignment > max_bytes or l.pitch == 0 or
        l.height == 0 or l.depth < r.depth or l.mip_count != r.mip_count or l.epitch > 65535 or
        l.first_mip_tail > r.mip_count or l.element_bits == 0 or l.element_bits % 8 != 0) return c.status_invalid;
    if (r.pitch != 0 and l.pitch != r.pitch) return c.status_invalid;
    return c.status_ok;
}
pub fn calculate(r: *const c.R4AmdImageRequest, workspace: [*]u8, bytes: u32, out: *c.R4AmdImageLayout, mips: [*]c.R4AmdMip, capacity: u32) callconv(.c) i32 {
    if (!sizes(bytes, capacity) or !spans(&.{ range(r), workspaceRange(workspace, bytes), range(out), mipRange(mips, capacity) })) return c.status_invalid;
    if (capacity < r.mip_count) return c.status_invalid;
    var result: Result = undefined;
    const rc = compute(r, workspace, bytes, &result, null, null, null);
    if (rc != c.status_ok) return rc;
    out.* = result.layout;
    @memcpy(mips[0..r.mip_count], result.mips[0..r.mip_count]);
    return c.status_ok;
}
pub fn address(r: *const c.R4AmdImageRequest, coord: *const c.R4AmdCoordinate, workspace: [*]u8, bytes: u32, out: *c.R4AmdImageAddress) callconv(.c) i32 {
    if (!sizes(bytes, 1) or !spans(&.{ range(r), range(coord), workspaceRange(workspace, bytes), range(out) })) return c.status_invalid;
    const rc = validate(r.*);
    if (rc != c.status_ok) return rc;
    if (coord.version != 1 or coord.size != @sizeOf(c.R4AmdCoordinate) or coord.reserved != 0 or coord.mip >= r.mip_count or coord.sample >= r.samples) return c.status_invalid;
    const shift: u5 = @intCast(coord.mip);
    const f = pixelFormat(r.format).?;
    const w = (@max(r.width >> shift, 1) + f.block - 1) / f.block;
    const h = (@max(r.height >> shift, 1) + f.block - 1) / f.block;
    const depth = if (r.resource_type == 2) @max(r.depth >> shift, 1) else r.depth;
    if (coord.x >= w or coord.y >= h or coord.slice >= depth) return c.status_invalid;
    var result: Result = undefined;
    var a: c.R4AmdImageAddress = undefined;
    const code = compute(r, workspace, bytes, &result, coord, &a, null);
    if (code != c.status_ok) return code;
    if (a.offset >= result.layout.byte_length or f.bytes > result.layout.byte_length - a.offset or a.bit_position != 0) return c.status_invalid;
    out.* = a;
    return c.status_ok;
}
pub fn metadata(r: *const c.R4AmdImageRequest, workspace: [*]u8, bytes: u32, out: *c.R4AmdMetadata) callconv(.c) i32 {
    if (!sizes(bytes, 1) or !spans(&.{ range(r), workspaceRange(workspace, bytes), range(out) })) return c.status_invalid;
    if (r.format == 0x01000003) return c.status_unsupported;
    const valid = validate(r.*);
    if (valid != c.status_ok) return valid;
    if (r.swizzle == 0 or r.usage & (c.image_usage_color | c.image_usage_depth) == 0) return c.status_unsupported;
    var result: Result = undefined;
    var meta: c.R4AmdMetadata = undefined;
    const rc = compute(r, workspace, bytes, &result, null, null, &meta);
    if (rc != c.status_ok) return rc;
    if (meta.byte_length == 0 or meta.byte_length > max_bytes or meta.alignment == 0 or !std.math.isPowerOfTwo(meta.alignment)) return c.status_invalid;
    out.* = meta;
    return c.status_ok;
}
pub fn importImage(r: *const c.R4AmdImageRequest, imported: *const c.R4AmdImageImport, workspace: [*]u8, bytes: u32, out: *c.R4AmdImageLayout, mips: [*]c.R4AmdMip, capacity: u32) callconv(.c) i32 {
    if (!sizes(bytes, capacity) or !spans(&.{ range(r), range(imported), workspaceRange(workspace, bytes), range(out), mipRange(mips, capacity) })) return c.status_invalid;
    if (capacity < r.mip_count or imported.version != 1 or imported.size != @sizeOf(c.R4AmdImageImport) or imported.reserved != 0 or
        imported.byte_length == 0 or imported.alignment == 0 or !std.math.isPowerOfTwo(imported.alignment) or imported.offset >= imported.byte_length) return c.status_invalid;
    if (imported.metadata_state != 0 or imported.modifier == invalid_modifier or imported.modifier != r.modifier or imported.usage & r.usage != r.usage) return c.status_unsupported;
    if (imported.expected_adapter == 0 or imported.expected_memory_generation == 0 or imported.adapter_id != imported.expected_adapter or
        imported.memory_generation != imported.expected_memory_generation) return c.status_stale;
    var result: Result = undefined;
    const rc = compute(r, workspace, bytes, &result, null, null, null);
    if (rc != c.status_ok) return rc;
    const l = result.layout;
    if (l.byte_length > imported.byte_length - imported.offset or imported.alignment < l.alignment or imported.offset % l.alignment != 0 or imported.pitch != l.pitch) return c.status_invalid;
    out.* = l;
    @memcpy(mips[0..r.mip_count], result.mips[0..r.mip_count]);
    return c.status_ok;
}
pub fn descriptors(r: *const c.R4AmdImageRequest, view: *const c.R4AmdImageView, workspace: [*]u8, bytes: u32, out: *c.R4AmdImageDescriptors) callconv(.c) i32 {
    if (!sizes(bytes, 1) or !spans(&.{ range(r), range(view), workspaceRange(workspace, bytes), range(out) })) return c.status_invalid;
    const v = view.*;
    if (v.version != 1 or v.size != @sizeOf(c.R4AmdImageView) or v.reserved != 0 or v.flags > 2 or v.address == 0 or v.byte_length == 0 or
        v.address >= @as(u64, 1) << 48 or v.byte_length > (@as(u64, 1) << 48) - v.address or v.offset >= v.byte_length or
        v.first_layer > v.last_layer or v.first_mip > v.last_mip or v.sampler > 1 or v.min_lod > v.max_lod or v.max_lod > 15 * 256 or
        v.lod_bias < -4096 or v.lod_bias > 4095 or v.wrap_u > 2 or v.wrap_v > 2 or v.wrap_w > 2 or v.compare > 7 or v.aniso > 4 or v.border > 2) return c.status_invalid;
    if (v.flags == 1 and ((r.format != 538982482 and r.format != 0x38385247 and r.format != 0x20363152 and r.format != 0x32335247) or
        r.usage != c.image_usage_texture or v.sampler != 0 or v.aniso != 0)) return c.status_unsupported;
    if (v.flags == 2 and (r.format != 538982482 or r.usage != c.image_usage_texture)) return c.status_unsupported;
    var result: Result = undefined;
    const rc = compute(r, workspace, bytes, &result, null, null, null);
    if (rc != c.status_ok) return rc;
    const l = result.layout;
    if (v.last_layer >= r.depth or v.last_mip >= r.mip_count or (r.samples > 1 and (v.first_mip != 0 or v.last_mip != 0)) or
        v.address % l.alignment != 0 or v.offset % l.alignment != 0 or l.byte_length > v.byte_length - v.offset) return c.status_invalid;
    // A 3D texture describes the full volume. Sliced 2D views and color views
    // at smaller volume mips need separate depth/layer state, absent in V1.
    if (r.resource_type == 2 and (v.first_layer != 0 or v.last_layer != r.depth - 1 or
        (r.usage & c.image_usage_color != 0 and v.first_mip != 0))) return c.status_unsupported;
    var output: c.R4AmdImageDescriptors = undefined;
    const status = r4amd_addr_descriptors(r, &l, view, &output);
    if (status != c.status_ok) return status;
    out.* = output;
    return c.status_ok;
}
}; }
