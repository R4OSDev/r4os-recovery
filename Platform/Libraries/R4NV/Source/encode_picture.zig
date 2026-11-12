// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// NVIDIA nvenc_drv.h / clc7b7.h / clc9b7.h (MIT), exact original-header
// vectors: nvenc_picture_vectors.json. Full notice: ../ThirdParty/Nvidia/LICENSES.txt.
//! Bounded C7B7/C9B7 H.264 picture parameters; no allocation or submission.
const std = @import("std");
const h = @import("encode_headers.zig");
pub const Error = h.Error;
pub const picture_bytes = 1152;
pub const slice_offset = 512;
pub const me_offset = 640;
pub const md_offset = 832;
pub const quant_offset = 960;
pub const Kind = enum(u16) { predicted = 0, idr = 3 };
pub const Layout = struct {
    luma_pitch: u32,
    chroma_pitch: u32,
    // Both plane methods share one base; the wire offset is in256-byte units.
    chroma_offset: u64,
    // This is the actual NVIDIA wire field, not a generic BO modifier. Its
    // interpretation and backing layout must be admitted by the surface owner.
    block_height_field: u7 = 0,
    tiled_16x16: bool = false,
};
pub const Picture = struct {
    sequence: h.Sequence,
    input: Layout,
    reference: Layout,
    kind: Kind,
    frame_num: u16,
    idr_pic_id: u16,
    bitstream_bytes: u32,
};
pub const Requirements = struct { macroblocks: u32, history: u32, coloc: u32 };

pub fn requirements(p: Picture) Error!Requirements {
    const d = try h.dimensions(p.sequence);
    if (p.reference.block_height_field != 2) return error.Unsupported;
    for ([_]Layout{ p.input, p.reference }) |layout| {
        if (layout.tiled_16x16 or layout.block_height_field < 2 or layout.block_height_field > 32 or
            !std.math.isPowerOfTwo(layout.block_height_field)) return error.Unsupported;
        if (layout.luma_pitch < d.width_mbs * 16 or layout.chroma_pitch < d.width_mbs * 16 or
            layout.luma_pitch > 65535 or layout.chroma_pitch > 65535 or
            layout.luma_pitch % 64 != 0 or layout.chroma_pitch % 64 != 0) return error.Bounds;
        const extents = try planeBytes(layout, d.height_mbs * 16);
        if (layout.chroma_offset < extents.luma or layout.chroma_offset & 255 != 0 or
            layout.chroma_offset >= (@as(u64, 1) << 40)) return error.Bounds;
    }
    if ((p.kind == .idr and p.frame_num != 0) or p.bitstream_bytes < 4096 or
        p.bitstream_bytes > 8 * 1024 * 1024) return error.Bounds;
    // Original H264_HIST_BLOCK_SIZE=224 supersedes the old128-byte prose.
    return .{ .macroblocks = d.macroblocks,
        .history = alignUp((d.width_mbs + 16) * 224, 256),
        .coloc = alignUp(d.macroblocks * 64, 256) };
}

pub fn encode(class: u32, p: Picture) Error![picture_bytes]u8 {
    if (class != 0xc7b7 and class != 0xc9b7) return error.Unsupported;
    const r = try requirements(p);
    const d = try h.dimensions(p.sequence);
    const s = p.sequence;
    const intra = p.kind == .idr;
    var out: [picture_bytes]u8 = @splat(0);
    put(&out, 0, (class << 16) | 6);
    surface(&out, 4, s, p.reference);
    surface(&out, 36, s, p.input);
    surface(&out, 68, s, p.reference);
    put(&out, 100, h.profile | (h.level << 8) | (1 << 16) | (h.poc_type << 18) |
        ((h.log2_frame_num - 4) << 20) | (1 << 28));
    const qp_delta: i6 = @intCast(@as(i32, @intCast(s.qp)) - 26);
    put(&out, 104, @as(u32, @as(u6, @bitCast(qp_delta))) << 21);
    put(&out, 108, 1 << 6); // PPS deblocking controls match parameterSets().
    // CQP: all three picture-type slots have the same fixed QP and bounds.
    @memset(out[113..122], @intCast(s.qp));
    const pc = 200;
    @memset(out[pc..][0..16], 0xff); // No reference slots except P list0[0].
    if (!intra) { out[pc] = 0; out[pc + 16] = 2; }
    put(&out, pc + 172, p.bitstream_bytes);
    half(&out, pc + 180, p.frame_num);
    half(&out, pc + 184, p.idr_pic_id);
    put(&out, pc + 196, slice_offset);
    put(&out, pc + 200, me_offset);
    put(&out, pc + 204, md_offset);
    put(&out, pc + 208, quant_offset);
    put(&out, pc + 212, r.history);
    put(&out, pc + 216, p.bitstream_bytes);
    // Physical firmware uses mode0 for one macroblock-count slice; mode1 is
    // byte-limited and needs an independent nonzero byte bound. No IPCM rewind.
    put(&out, pc + 224, (@as(u32, @intFromEnum(p.kind)) << 2) | (1 << 4));
    out[pc + 228] = 0xff; out[pc + 229] = 0xff; // No MVC references.
    out[pc + 230] = 0 | (1 << 3); // Picture codec0 is H.264; method CODEC_TYPE is3.
    put(&out, pc + 236, 128); // One enabled slice-stat record after pic status.
    out[pc + 251] = 1; // A whole progressive frame, one strip.
    half(&out, pc + 254, @intCast(d.height_mbs));

    put(&out, slice_offset, r.macroblocks | (s.qp << 19));
    out[slice_offset + 9] = @intCast(s.qp);
    out[slice_offset + 10] = @intCast(s.qp);
    out[slice_offset + 11] = @intFromBool(intra); // force_intra, deblock enabled.
    // ME considers spatial and zero-vector candidates with integer stamp0 and
    // quarter-pixel refinement. No CEA, temporal/colocated or external hints.
    put(&out, me_offset, (1 << 1) | (1 << 14));
    if (!intra) {
        put(&out, me_offset + 12, 0x3c000000);
        put(&out, me_offset + 20, 0xf0000000);
    }
    put(&out, me_offset + 44, 0xffffffff);
    put(&out, me_offset + 48, 0xffffffff);
    put(&out, me_offset + 52, 3);
    put(&out, me_offset + 144, d.width_mbs);
    half(&out, me_offset + 154, 0x4688); // Each of the five hint types once.
    // Baseline intra4x4/16x16 and chroma modes; P partitions through8x8.
    put(&out, md_offset + 4, 0x03fc01ff);
    if (!intra) put(&out, md_offset + 8, 0x0800000f);
    put(&out, md_offset + 52, 0x141e0000); // Full intra evaluation + MV cost.
    // The C7 pipeline needs positive SSD candidate counts and matching RDO
    // controls. A zero-filled MD tail stalls without producing any bytes.
    half(&out, md_offset + 58, 0x9108); // 4x4/8x8/16x16 counts1/2/2, skip evaluation.
    put(&out, md_offset + 60, 0x121); // SSD RDO1, four TU candidates, lambda fraction1/8.
    put(&out, 508, 50_000_000); // Firmware GPTIMER bound, enabled by the method controls.
    // Quantization deadzones/bias are zero, QPP and saturation disabled.
    // All unused structures, padding and reserved bits remain zero.
    return out;
}

pub fn planeBytes(layout: Layout, rows: u32) Error!struct { luma: u64, chroma: u64 } {
    if (layout.tiled_16x16 or layout.block_height_field < 2 or layout.block_height_field > 32 or
        !std.math.isPowerOfTwo(layout.block_height_field)) return error.Unsupported;
    if (rows == 0 or rows > 4096 or rows % 16 != 0) return error.Bounds;
    const block_rows: u32 = @as(u32, layout.block_height_field) * 8;
    return .{ .luma = @as(u64, layout.luma_pitch) * alignUp(rows, block_rows),
        .chroma = @as(u64, layout.chroma_pitch) * alignUp(rows / 2, block_rows) };
}
fn surface(out: []u8, offset: usize, s: h.Sequence, layout: Layout) void {
    // SPS cropping describes the visible image; engine surfaces include the
    // replicated macroblock edges for both input and reconstruction.
    half(out, offset, @intCast(alignUp(s.width, 16) - 1));
    half(out, offset + 2, @intCast(alignUp(s.height, 16) - 1));
    half(out, offset + 4, @intCast(layout.luma_pitch));
    half(out, offset + 6, @intCast(layout.chroma_pitch));
    put(out, offset + 20, @intCast(layout.chroma_offset >> 8));
    // Progressive NV12 has no bottom field, NV21 or planar conversion mode.
    put(out, offset + 28, @as(u32, layout.block_height_field) | (@as(u32, @intFromBool(layout.tiled_16x16)) << 7));
}
fn alignUp(value: u32, alignment: u32) u32 { return (value + alignment - 1) & ~(alignment - 1); }
fn put(out: []u8, offset: usize, value: u32) void { std.mem.writeInt(u32, out[offset..][0..4], value, .little); }
fn half(out: []u8, offset: usize, value: u16) void { std.mem.writeInt(u16, out[offset..][0..2], value, .little); }
