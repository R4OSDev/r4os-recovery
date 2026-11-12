// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 AND MIT
// Copyright 2026 Advanced Micro Devices, Inc. SPDX-License-Identifier: MIT
//! VCN1 eligibility adapted from Mesa 26.2.2 ac_video.c. Original bytes,
//! SHA256 and complete MIT grant remain in ThirdParty/Sources.json.
//! These limits never stand in for a running R4VIDEO/R4ENC implementation.
const std = @import("std");
pub const Surface = struct {
    width: u32, height: u32, depth: u32, pitch: u32,
    rows: u32, chroma_rows: u32, chroma_offset: u64, bytes: u64,
    pub fn plan(width: u32, height: u32, depth: u32) error{Unsupported}!Surface {
        if (width == 0 or height == 0 or width > 8192 or height > 8192 or (width | height) & 1 != 0 or (depth != 8 and depth != 10)) return error.Unsupported;
        const pitch = std.mem.alignForward(u32, width * @as(u32, if (depth == 10) 2 else 1), 256);
        const rows = std.mem.alignForward(u32, height, 16);
        const chroma_rows = std.mem.alignForward(u32, height / 2, 16);
        const chroma_offset = std.mem.alignForward(u64, @as(u64, pitch) * rows, 65536);
        const bytes = chroma_offset + std.mem.alignForward(u64, @as(u64, pitch) * chroma_rows, 65536);
        return .{ .width = width, .height = height, .depth = depth, .pitch = pitch, .rows = rows, .chroma_rows = chroma_rows, .chroma_offset = chroma_offset, .bytes = bytes };
    }
};
pub fn Provider(comptime c: type) type {
    return struct {
        pub fn limits(query: c.R4AmdMediaQuery) error{ Invalid, Unsupported }!c.R4AmdMediaCaps {
            if (query.version != 1 or query.size != @sizeOf(c.R4AmdMediaQuery) or query.flags != 0 or query.reserved != 0 or
                (query.width == 0) != (query.height == 0)) return error.Invalid;
            if (query.vendor_id != c.vendor_id or !@import("asic.zig").Profiles(c).media(query.device_id, query.gc_version, query.vcn_version, query.firmware_version) or
                query.operation > 1 or query.chroma != 1 or
                (query.bit_depth != 8 and query.bit_depth != 10)) return error.Unsupported;
            var out = std.mem.zeroes(c.R4AmdMediaCaps);
            out.version = 1; out.size = @sizeOf(c.R4AmdMediaCaps); out.flags = c.media_caps_source_profile;
            out.format = if (query.bit_depth == 8) 1 else 2;
            out.min_width = 64; out.min_height = 64; out.max_width = 4096; out.max_height = 4096;
            out.width_alignment = 16; out.height_alignment = 16; out.bitstream_alignment = 256;
            switch (query.codec) {
                1 => {
                    const profile = if (query.profile == 0) @as(u32, 66) else query.profile;
                    if (query.bit_depth != 8 or (profile != 66 and profile != 77 and profile != 100)) return error.Unsupported;
                    out.max_level = 52; out.dpb_slots = 17; out.active_references = 16;
                },
                2 => {
                    const profile = if (query.profile == 0) @as(u32, 1) else query.profile;
                    if ((profile != 1 or query.bit_depth != 8) and (profile != 2 or query.bit_depth != 10)) return error.Unsupported;
                    out.max_level = 186; out.dpb_slots = 17; out.active_references = 15; out.width_alignment = 64;
                },
                3 => {
                    if (query.operation != 0 or (query.profile != 0 or query.bit_depth != 8) and (query.profile != 2 or query.bit_depth != 10)) return error.Unsupported;
                    out.min_width = 16; out.min_height = 16; out.max_level = 62; out.dpb_slots = 9; out.active_references = 3;
                },
                4 => {
                    if (query.operation != 0 or query.bit_depth != 8 or (query.profile != 0 and query.profile != 4 and query.profile != 5)) return error.Unsupported;
                    out.max_level = 3; out.dpb_slots = 6; out.active_references = 2;
                },
                5 => {
                    if (query.operation != 0 or query.bit_depth != 8 or (query.profile != 0 and query.profile != 1 and query.profile != 3)) return error.Unsupported;
                    out.max_level = 4; out.dpb_slots = 5; out.active_references = 2;
                },
                6 => {
                    if (query.operation != 0 or query.bit_depth != 8 or query.profile != 0) return error.Unsupported;
                    out.max_width = 8192; out.max_height = 8192;
                },
                else => return error.Unsupported, // no AV1 or MPEG4 Part 2
            }
            if (query.operation == 1) {
                if (query.codec > 2 or query.bit_depth != 8) return error.Unsupported;
                out.min_width = if (query.codec == 1) 128 else 130; out.min_height = 128;
                out.max_height = 2304; out.active_references = 1; out.max_slices = 128;
                out.rate_controls = 7; // CQP, CBR and VBR; no QVBR/B-frame claim.
            }
            if (query.width != 0 and (query.width < out.min_width or query.height < out.min_height or query.width > out.max_width or
                query.height > out.max_height or (query.width | query.height) & 1 != 0)) return error.Unsupported;
            return out;
        }
        pub fn caps(query: *const c.R4AmdMediaQuery, output: *c.R4AmdMediaCaps) callconv(.c) i32 {
            const src = @intFromPtr(query); const dst = @intFromPtr(output);
            if (src == 0 or dst == 0 or (src | dst) & 3 != 0 or src > std.math.maxInt(usize) - @sizeOf(c.R4AmdMediaQuery) or
                dst > std.math.maxInt(usize) - @sizeOf(c.R4AmdMediaCaps) or
                src < dst + @sizeOf(c.R4AmdMediaCaps) and dst < src + @sizeOf(c.R4AmdMediaQuery)) return c.status_invalid;
            const value = limits(query.*) catch |err| return if (err == error.Invalid) c.status_invalid else c.status_unsupported;
            output.* = value; return c.status_ok;
        }
    };
}
