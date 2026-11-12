// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Metadata negotiation for the fixed C797/SM86 image profile. The caller
//! still authenticates the BO, device generation and physical mapping.
//! Sources: pinned NVIDIA570.144 NVKMS surface policy and drm_fourcc.h,
//! plus the existing original-header TIC/target/copy descriptor profiles.
const std = @import("std");
const c = @import("r4l_contract");
const backend = @import("backend.zig");
const Error = error{ Invalid, Unsupported, Overflow };
const turing_generic_modifier: u64 = 0x0300000000606010;
const native_granule: u64 = 65536;
fn alignUp(value: u64, granule: u64) Error!u64 {
    return (std.math.add(u64,value,granule-1) catch return error.Overflow)&~(granule-1);
}
fn blockHeight(height: u32) u5 {
    // Same pinned NVKMS choice as native surface allocation. Bounded to four.
    var h: u5 = 4;
    const limit = @as(u64,height)+height/2;
    while (h > 0 and (@as(u64,8)<<h) > limit) h -= 1;
    if (h > 0) while ((@as(u64,8)<<(h-1)) >= height) {
        h -= 1;
        if (h == 0) break;
    };
    return h;
}
fn decodeModifier(modifier: u64) Error!?u5 {
    if (modifier == 0) return null;
    // No compression, exact generic kind6 / GOB generation2 / sector1.
    // Unknown layouts cannot be repaired by pretending that they are linear.
    if (modifier&~@as(u64,15) != turing_generic_modifier or modifier&15 > 5) return error.Unsupported;
    return @intCast(modifier&15);
}
fn plan(request: c.R4NvImageRequest) Error!c.R4NvImagePlan {
    const v = request.view;
    if (v.version != 1 or v.size != @sizeOf(c.R4NvImageView) or v.reserved != 0 or request.reserved != 0 or
        request.flags&~c.image_force_copy != 0 or request.preference > c.image_prefer_blocklinear or
        request.uses == 0 or request.uses&~@as(u32,7) != 0 or v.location > 1 or v.usage&~@as(u32,63) != 0 or
        v.width == 0 or v.height == 0 or v.width > 16384 or v.height > 16384 or
        v.alignment == 0 or !std.math.isPowerOfTwo(v.alignment)) return error.Invalid;
    const bytes: u64 = switch (v.format) { 0x34325258, 0x34325241, 0x30335258, 0x30335241 => 4,
        0x48344241 => 8, 0x20203852 => 1, else => return error.Unsupported };
    const block = try decodeModifier(v.modifier);
    if (v.location == 0 and block != null) return error.Unsupported;
    const row = @as(u64,v.width)*bytes;
    if (v.pitch < row or v.pitch > std.math.maxInt(u32)) return error.Invalid;
    const rows = if (block) |h| try alignUp(v.height,@as(u64,8)<<h) else v.height;
    const span = std.math.mul(u64,v.pitch,rows) catch return error.Overflow;
    if (span > v.byte_length) return error.Invalid;
    if (block != null and v.pitch&63 != 0) return error.Invalid;
    if (request.uses&c.image_use_scanout != 0 and
        ((v.format != 0x34325258 and v.format != 0x34325241) or request.uses&c.image_use_render_target != 0)) return error.Unsupported;

    var supported: u32 = 0;
    if (v.location == 1) {
        const tex_geometry = if (block != null) v.alignment >= 512 and v.pitch == try alignUp(row,64)
            else v.alignment >= 32 and v.pitch&31 == 0 and v.pitch < 1<<21;
        const target_geometry = if (block != null) tex_geometry else tex_geometry and v.alignment >= 128 and v.pitch&127 == 0;
        const scanout_geometry = if (block != null) tex_geometry else v.alignment >= 256 and v.pitch&255 == 0;
        if (tex_geometry and v.usage&(4|16) != 0) supported |= c.image_use_texture;
        // The current renderer has no inactive-scanout lease. Layout
        // suitability alone must not authorize writing a displayed image.
        if (target_geometry and v.usage&16 != 0 and v.usage&32 == 0) supported |= c.image_use_render_target;
        if (scanout_geometry and bytes == 4 and v.usage&32 != 0) supported |= c.image_use_scanout;
    }
    var reasons: u32 = 0;
    if (v.location != 1) reasons |= c.image_reason_location;
    if (supported&request.uses != request.uses and v.location == 1) {
        if ((request.uses&c.image_use_texture != 0 and v.usage&(4|16) == 0) or
            (request.uses&c.image_use_render_target != 0 and (v.usage&16 == 0 or v.usage&32 != 0)) or
            (request.uses&c.image_use_scanout != 0 and v.usage&32 == 0)) reasons |= c.image_reason_usage
        else reasons |= c.image_reason_pitch;
    }
    if (request.preference == c.image_prefer_linear and block != null or request.preference == c.image_prefer_blocklinear and block == null)
        reasons |= c.image_reason_preference;
    if (request.flags&c.image_force_copy != 0) reasons |= c.image_reason_forced;
    if (reasons == 0) return .{ .version = 1, .size = @sizeOf(c.R4NvImagePlan), .action = c.image_action_reuse,
        .layout = @intFromBool(block != null), .reasons = 0, .supported_uses = supported, .modifier = v.modifier,
        .pitch = v.pitch, .byte_length = span, .allocation_bytes = v.byte_length, .log2_gobs = block orelse 0, .reserved = 0 };
    if (v.usage&4 == 0) return error.Unsupported; // The conversion requires a readable CE source.
    // Preserve a suitable existing native view. New GPU images prefer tiled
    // storage; an explicit linear request remains available for staging.
    const tiled = request.preference != c.image_prefer_linear;
    const height: u5 = if (tiled) blockHeight(v.height) else 0;
    const pitch = try alignUp(row,if (tiled) 64 else 256);
    const target_rows = if (tiled) try alignUp(v.height,@as(u64,8)<<height) else v.height;
    const target_bytes = std.math.mul(u64,pitch,target_rows) catch return error.Overflow;
    return .{ .version = 1, .size = @sizeOf(c.R4NvImagePlan), .action = c.image_action_convert,
        .layout = @intFromBool(tiled), .reasons = reasons, .supported_uses = request.uses,
        .modifier = if (tiled) turing_generic_modifier|height else 0, .pitch = pitch, .byte_length = target_bytes,
        .allocation_bytes = try alignUp(target_bytes,native_granule), .log2_gobs = height, .reserved = 0 };
}
fn pointer(comptime T: type, address: usize) bool {
    return address != 0 and address%@alignOf(T) == 0 and address <= std.math.maxInt(usize)-@sizeOf(T);
}
fn overlaps(left: usize, bytes: usize, right: usize, other: usize) bool { return left < right+other and right < left+bytes; }
pub fn r4nv_image_layout_impl(profile: *const c.R4NvDeviceProfile, request: *const c.R4NvImageRequest, output: *c.R4NvImagePlan) callconv(.c) i32 {
    if (!pointer(c.R4NvDeviceProfile,@intFromPtr(profile)) or !pointer(c.R4NvImageRequest,@intFromPtr(request)) or !pointer(c.R4NvImagePlan,@intFromPtr(output))) return c.status_invalid;
    if (overlaps(@intFromPtr(output),@sizeOf(c.R4NvImagePlan),@intFromPtr(request),@sizeOf(c.R4NvImageRequest)) or
        overlaps(@intFromPtr(output),@sizeOf(c.R4NvImagePlan),@intFromPtr(profile),@sizeOf(c.R4NvDeviceProfile))) return c.status_invalid;
    var features: c.R4NvFeatures = undefined;
    const status = backend.r4nv_negotiate_impl(profile,&features);
    if (status != c.status_ok) return status;
    const result = plan(request.*) catch |err| return switch (err) { error.Unsupported => c.status_unsupported, else => c.status_invalid };
    output.* = result;
    return c.status_ok;
}
