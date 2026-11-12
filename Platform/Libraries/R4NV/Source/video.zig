// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Wire fields derived from NVIDIA nvdec_drv.h, clc7b0.h and clc9b0.h (MIT).
// H.264 buffer sizing, EOS and field marking follow Mesa NVK h264.rs (MIT),
// NVDEC's SET_OBJECT must select the software engine (NVC56F ENGINE_SW),
// on subchannel4 as in NVK rust/video/decode/mod.rs and nv_push_rs.
// Copyright (c) 2024 Collabora, Ltd and Red Hat, Inc.
// Full notices: ../ThirdParty/Nvidia/LICENSES.txt; pinned sources and original
// C-header vectors: nvdec_h264_vectors.json. No CUDA/NVDECODE dependency.
const std = @import("std");

pub const picture_bytes = 764;
pub const status_bytes = 56;
pub const max_references = 16;
pub const max_surfaces = 17;
pub const max_slices = 255;
pub const max_stream_bytes = 8 * 1024 * 1024;
pub const command_words = 54;
pub const eos = [16]u8{ 0, 0, 1, 11, 0, 0, 0, 0, 0, 0, 1, 11, 0, 0, 0, 0 };
pub const Error = error{ Unsupported, Bounds, Capacity, Alias, State };

pub const Sequence = struct {
    profile: u32,
    level: u32,
    width_mbs: u32,
    height_mbs: u32,
    max_refs: u32,
    log2_frame_num: u32,
    poc_type: u32,
    log2_poc_lsb: u32,
    delta_poc_always_zero: bool = false,
    direct_8x8: bool = true,
    frame_mbs_only: bool = true,
    bit_depth_luma: u32 = 8,
    bit_depth_chroma: u32 = 8,
    chroma_format: u32 = 1,
    separate_colour_plane: bool = false,
    transform_bypass: bool = false,
};
pub const Parameters = struct {
    entropy_coding: bool = false,
    bottom_field_poc_present: bool = false,
    l0_default_minus1: u32 = 0,
    l1_default_minus1: u32 = 0,
    deblocking_control: bool = false,
    redundant_pic_cnt: bool = false,
    transform_8x8: bool = false,
    weighted_pred: bool = false,
    constrained_intra_pred: bool = false,
    weighted_bipred: u32 = 0,
    initial_qp_minus26: i32 = 0,
    chroma_qp_offset: i32 = 0,
    second_chroma_qp_offset: i32 = 0,
    slice_groups: u32 = 1,
    // Fully resolved PPS/SPS scaling matrices in raster order, not scan order.
    scaling4: [96]u8 = @splat(16),
    scaling8: [128]u8 = @splat(16),
};
pub const Reference = struct {
    surface: u32,
    long_term: bool = false,
    frame_index: u32,
    poc: [2]i32,
};
pub const Picture = struct {
    sequence: Sequence,
    parameters: Parameters,
    current_surface: u32,
    frame_num: u32,
    poc: [2]i32,
    is_reference: bool,
    references: []const Reference,
    bitstream_bytes: u32, // Includes Annex B slice prefixes; excludes EOS.
    slices: u32,
};
pub const Layout = struct {
    luma_pitch: u32,
    chroma_pitch: u32,
    // KBL NV12. NVDEC encodes log2_gobs - 1; one-GOB tiling is unsupported.
    log2_gobs: u32,
};
pub const Requirements = struct {
    macroblocks: u32,
    coloc_stride: u32,
    coloc: u32,
    mbhist: u32,
    history: u32,
    luma: u32,
    chroma: u32,
};

pub fn supported(class: u32) bool {
    // These identities only select a wire format; the driver must separately
    // admit a real, offered NVDEC class/engine and keep its device epoch alive.
    return class == 0xc7b0 or class == 0xc9b0;
}

pub fn requirements(s: Sequence, layout: Layout) Error!Requirements {
    if ((s.profile != 66 and s.profile != 77 and s.profile != 100) or
        !s.frame_mbs_only or s.bit_depth_luma != 8 or s.bit_depth_chroma != 8 or
        s.chroma_format != 1 or s.separate_colour_plane or s.transform_bypass or
        s.level == 0 or s.level > 51) return error.Unsupported;
    if (s.width_mbs == 0 or s.width_mbs > 256 or s.height_mbs == 0 or s.height_mbs > 256 or
        s.max_refs > max_references or s.log2_frame_num < 4 or s.log2_frame_num > 16 or
        s.poc_type > 2 or s.log2_poc_lsb < 4 or s.log2_poc_lsb > 16 or
        (s.delta_poc_always_zero and s.poc_type != 1)) return error.Bounds;
    const mbs = s.width_mbs * s.height_mbs;
    if (mbs > 36864) return error.Unsupported; // Maximum frame size at level 5.1.
    if (layout.log2_gobs < 1 or layout.log2_gobs > 5 or
        layout.luma_pitch < s.width_mbs * 16 or layout.chroma_pitch < s.width_mbs * 16 or
        layout.luma_pitch > 65536 or layout.chroma_pitch > 65536 or
        layout.luma_pitch % 64 != 0 or layout.chroma_pitch % 64 != 0) return error.Bounds;
    const block_rows = @as(u32, 8) << @intCast(layout.log2_gobs);
    const stride = alignUp(alignUp(s.height_mbs, 2) * s.width_mbs * 64 - 63, 256);
    return .{
        .macroblocks = mbs,
        .coloc_stride = stride,
        .coloc = stride * (s.max_refs + 1),
        .mbhist = alignUp(s.width_mbs * 104, 256),
        .history = alignUp(s.width_mbs * 0x300, 512),
        .luma = layout.luma_pitch * alignUp(s.height_mbs * 16, block_rows),
        .chroma = layout.chroma_pitch * alignUp(s.height_mbs * 8, block_rows),
    };
}

fn validate(p: *const Picture, layout: Layout) Error!Requirements {
    const r = try requirements(p.sequence, layout);
    const s = p.sequence;
    const q = &p.parameters;
    if (q.slice_groups != 1 or (s.profile != 100 and q.transform_8x8) or
        (s.profile == 66 and (q.entropy_coding or q.weighted_pred or q.weighted_bipred != 0))) return error.Unsupported;
    if (q.l0_default_minus1 > 31 or q.l1_default_minus1 > 31 or q.weighted_bipred > 2 or
        q.initial_qp_minus26 < -26 or q.initial_qp_minus26 > 25 or
        q.chroma_qp_offset < -12 or q.chroma_qp_offset > 12 or
        q.second_chroma_qp_offset < -12 or q.second_chroma_qp_offset > 12 or
        p.current_surface > s.max_refs or p.frame_num >= (@as(u32, 1) << @intCast(s.log2_frame_num)) or
        p.references.len > s.max_refs or p.bitstream_bytes == 0 or p.bitstream_bytes > max_stream_bytes or
        p.slices == 0 or p.slices > max_slices or p.slices > r.macroblocks or
        p.poc[0] == std.math.maxInt(i32) or p.poc[1] == std.math.maxInt(i32)) return error.Bounds;
    for (q.scaling4) |v| if (v == 0) return error.Bounds;
    for (q.scaling8) |v| if (v == 0) return error.Bounds;
    var used: u32 = @as(u32, 1) << @intCast(p.current_surface);
    for (p.references) |ref| {
        if (ref.surface > s.max_refs or ref.frame_index >=
            (if (ref.long_term) @as(u32, 16) else @as(u32, 1) << @intCast(s.log2_frame_num)) or
            ref.poc[0] == std.math.maxInt(i32) or ref.poc[1] == std.math.maxInt(i32)) return error.Bounds;
        const bit = @as(u32, 1) << @intCast(ref.surface);
        if (used & bit != 0) return error.Alias;
        used |= bit;
    }
    return r;
}

/// Pure bounded serializer. Returned bytes own no GPU allocation or DPB state.
pub fn encodePicture(class: u32, p: *const Picture, layout: Layout) Error![picture_bytes]u8 {
    if (!supported(class)) return error.Unsupported;
    const r = try validate(p, layout);
    const s = p.sequence;
    const q = &p.parameters;
    var bytes: [picture_bytes]u8 = @splat(0);
    @memcpy(bytes[52..68], &eos);
    bytes[68] = 1;
    put(&bytes, 72, p.bitstream_bytes + @as(u32, eos.len));
    put(&bytes, 76, p.slices);
    put(&bytes, 80, r.mbhist);
    put(&bytes, 84, 81000000); // Explicit firmware watchdog, as in NVK.
    put(&bytes, 88, s.log2_poc_lsb - 4);
    put(&bytes, 92, @intFromBool(s.delta_poc_always_zero));
    put(&bytes, 96, 1); // Progressive only.
    put(&bytes, 100, s.width_mbs);
    put(&bytes, 104, s.height_mbs);
    put(&bytes, 108, 1 | ((layout.log2_gobs - 1) << 2));
    put(&bytes, 112, @intFromBool(q.entropy_coding));
    put(&bytes, 116, @intFromBool(q.bottom_field_poc_present));
    put(&bytes, 120, q.l0_default_minus1);
    put(&bytes, 124, q.l1_default_minus1);
    put(&bytes, 128, @intFromBool(q.deblocking_control));
    put(&bytes, 132, @intFromBool(q.redundant_pic_cnt));
    put(&bytes, 136, @intFromBool(q.transform_8x8));
    put(&bytes, 140, layout.luma_pitch);
    put(&bytes, 144, layout.chroma_pitch);
    put(&bytes, 152, s.width_mbs * 16);
    put(&bytes, 164, layout.chroma_pitch / 2);
    put(&bytes, 172, r.history >> 8);
    put(&bytes, 176, flag(s.direct_8x8, 1) | flag(q.weighted_pred, 2) |
        flag(q.constrained_intra_pred, 3) | flag(p.is_reference, 4) |
        ((s.log2_frame_num - 4) << 8) | (1 << 12) | (s.poc_type << 14) |
        ((@as(u32, @bitCast(q.initial_qp_minus26)) & 63) << 16) |
        ((@as(u32, @bitCast(q.chroma_qp_offset)) & 31) << 22) |
        ((@as(u32, @bitCast(q.second_chroma_qp_offset)) & 31) << 27));
    put(&bytes, 180, q.weighted_bipred | (p.current_surface << 2) |
        (p.current_surface << 9) | (p.frame_num << 14));
    put(&bytes, 184, @bitCast(p.poc[0]));
    put(&bytes, 188, @bitCast(p.poc[1]));
    for (p.references, 0..) |ref, i| {
        const marking: u32 = if (ref.long_term) 2 else 1;
        const offset = 192 + i * 16;
        put(&bytes, offset, ref.surface | (ref.surface << 7) | (3 << 12) |
            flag(ref.long_term, 14) | (marking << 17) | (marking << 21));
        put(&bytes, offset + 4, @bitCast(ref.poc[0]));
        put(&bytes, offset + 8, @bitCast(ref.poc[1]));
        put(&bytes, offset + 12, ref.frame_index);
    }
    @memcpy(bytes[448..544], &q.scaling4);
    @memcpy(bytes[544..672], &q.scaling8);
    return bytes;
}

pub const Span = struct { address: u64, bytes: u64 };
pub const Surface = struct { luma: Span, chroma: Span };
pub const Buffers = struct {
    picture: Span,
    bitstream: Span,
    slices: Span,
    coloc: Span,
    history: Span,
    status: Span,
    mbhist: Span,
    surfaces: [max_surfaces]?Surface,
};

/// Addresses are canonical, live VA loans supplied by the caller. Every span
/// must remain resident through the queue fence. NVDEC method offsets are 40-bit
/// byte addresses shifted by 8, even when the GPU itself has a larger VA space.
pub fn encodeCommands(class: u32, p: *const Picture, layout: Layout, b: *const Buffers, picture_index: u32) Error![command_words]u32 {
    if (!supported(class)) return error.Unsupported;
    const r = try validate(p, layout);
    var ranges: [7 + 2 * max_surfaces]Span = undefined;
    ranges[0..7].* = .{ b.picture, b.bitstream, b.slices, b.coloc, b.history, b.status, b.mbhist };
    const needed = [_]u32{ picture_bytes, p.bitstream_bytes + @as(u32, eos.len), (p.slices + 1) * 4,
        r.coloc, r.history, status_bytes, r.mbhist };
    for (ranges[0..7], needed) |span, need| _ = try address(span, need);
    var used: u32 = @as(u32, 1) << @intCast(p.current_surface);
    for (p.references) |ref| used |= @as(u32, 1) << @intCast(ref.surface);
    var luma: [max_surfaces]u32 = @splat(0);
    var chroma: [max_surfaces]u32 = @splat(0);
    var count: usize = 7;
    for (b.surfaces, 0..) |surface, i| {
        if (used & (@as(u32, 1) << @intCast(i)) == 0) {
            if (surface != null) return error.Bounds;
            continue;
        }
        const image = surface orelse return error.Bounds;
        luma[i] = try address(image.luma, r.luma);
        chroma[i] = try address(image.chroma, r.chroma);
        ranges[count] = image.luma;
        ranges[count + 1] = image.chroma;
        count += 2;
    }
    for (ranges[0..count], 0..) |a, i| for (ranges[0..i]) |other| {
        if (a.address < other.address + other.bytes and other.address < a.address + a.bytes) return error.Alias;
    };
    var words: [command_words]u32 = undefined;
    words[0..4].* = .{ inc(0, 1), class | (0x1f << 16), inc(0x200, 1), 3 };
    words[4..12].* = .{ inc(0x400, 7), 3 | (1 << 4) | (1 << 5) | (1 << 13) | (1 << 18),
        @intCast(b.picture.address >> 8), @intCast(b.bitstream.address >> 8), picture_index,
        @intCast(b.slices.address >> 8), @intCast(b.coloc.address >> 8), @intCast(b.history.address >> 8) };
    words[12..14].* = .{ inc(0x424, 1), @intCast(b.status.address >> 8) };
    words[14] = inc(0x430, 17);
    @memcpy(words[15..32], &luma);
    words[32] = inc(0x474, 17);
    @memcpy(words[33..50], &chroma);
    words[50..54].* = .{ inc(0x500, 1), @intCast(b.mbhist.address >> 8), inc(0x300, 1), 0 };
    // Queue owner appends HOST WFI/memory barrier/fence. No codec semaphore.
    return words;
}

pub fn sliceOffsets(starts: []const u32, stream_bytes: u32) Error![1024]u8 {
    if (starts.len == 0 or starts.len > max_slices or stream_bytes == 0 or
        stream_bytes > max_stream_bytes or starts[0] != 0) return error.Bounds;
    var bytes: [1024]u8 = @splat(0);
    for (starts, 0..) |offset, i| {
        if (offset >= stream_bytes or (i != 0 and offset <= starts[i - 1])) return error.Bounds;
        put(&bytes, i * 4, offset);
    }
    put(&bytes, starts.len * 4, stream_bytes); // Required final boundary, before EOS.
    return bytes;
}

/// Per-picture collector for FFmpeg's original, escaped NAL bytes (with the NAL
/// header, without Annex B prefix). Storage and this owner must have stable,
/// disjoint addresses. Failed append/finish calls leave both unchanged.
pub const AccessUnit = struct {
    storage: []u8,
    starts: [max_slices]u32 = @splat(0),
    length: u32 = 0,
    count: u16 = 0,
    finished: bool = false,

    pub const Encoded = struct {
        bitstream_bytes: u32, // Before the sixteen EOS bytes.
        upload_bytes: u32, // EOS and zero padding to 256 bytes included.
        slice_count: u32,
        offsets: [1024]u8,
    };

    pub fn append(self: *AccessUnit, nal: []const u8) Error!void {
        try self.valid();
        if (self.finished) return error.State;
        if (nal.len == 0 or nal.len > max_stream_bytes - 3 or nal[0] & 0x80 != 0) return error.Bounds;
        // Data partitioning, extensions and auxiliary pictures need their own
        // codec contract. Non-VCL SPS/PPS/SEI are consumed by FFmpeg's parser.
        const kind = nal[0] & 31;
        if (kind != 1 and kind != 5) return error.Unsupported;
        if (self.count == max_slices or nal.len + 3 > max_stream_bytes - self.length) return error.Capacity;
        const next: u32 = self.length + @as(u32, @intCast(nal.len)) + 3;
        if (alignUp(next + @as(u32, eos.len), 256) > self.storage.len) return error.Capacity;
        if (overlaps(@intFromPtr(self.storage.ptr), self.storage.len, @intFromPtr(nal.ptr), nal.len) or
            overlaps(@intFromPtr(self), @sizeOf(AccessUnit), @intFromPtr(nal.ptr), nal.len)) return error.Alias;
        const pos = self.length;
        @memcpy(self.storage[pos..][0..3], &[_]u8{ 0, 0, 1 });
        @memcpy(self.storage[pos + 3 ..][0..nal.len], nal);
        self.starts[self.count] = pos;
        self.length = next;
        self.count += 1;
    }

    pub fn finish(self: *AccessUnit) Error!Encoded {
        try self.valid();
        if (self.finished) return error.State;
        const offsets = try sliceOffsets(self.starts[0..self.count], self.length);
        const end = self.length + @as(u32, eos.len);
        const padded = alignUp(end, 256);
        if (padded > self.storage.len) return error.Capacity;
        @memcpy(self.storage[self.length..end], &eos);
        @memset(self.storage[end..padded], 0);
        self.finished = true;
        return .{ .bitstream_bytes = self.length, .upload_bytes = padded,
            .slice_count = self.count, .offsets = offsets };
    }

    fn valid(self: *const AccessUnit) Error!void {
        if (self.length > max_stream_bytes or self.count > max_slices or self.length > self.storage.len)
            return error.Bounds;
        if (overlaps(@intFromPtr(self), @sizeOf(AccessUnit), @intFromPtr(self.storage.ptr), self.storage.len))
            return error.Alias;
    }
};

pub const Completion = enum { pending, succeeded, failed };
pub const DecodeStatus = struct { macroblocks: u32, cycles: u32 };
pub const StatusError = error{ NotReady, Device, Bounds, MissingStatus, Decode };

/// Call on a coherent CPU snapshot only after the native queue's fence. A ring
/// GET advance or an all-zero/previous status record does not establish success.
pub fn pictureStatus(bytes: []const u8, completion: Completion, expected_mbs: u32) StatusError!DecodeStatus {
    if (completion == .pending) return error.NotReady;
    if (completion == .failed) return error.Device;
    if (bytes.len < status_bytes or expected_mbs == 0 or expected_mbs > 36864) return error.Bounds;
    const correct = get(bytes, 0);
    const incorrect = get(bytes, 4);
    const code = get(bytes, 12);
    const slice_code = get(bytes, 52);
    if (correct == 0xffffffff or incorrect == 0xffffffff or code == 0xffffffff or slice_code == 0xffffffff)
        return error.MissingStatus;
    if (incorrect != 0 or code != 0 or slice_code != 0 or correct != expected_mbs) return error.Decode;
    return .{ .macroblocks = correct, .cycles = get(bytes, 8) };
}

/// Reset this record for EACH submission, after retiring its previous use.
pub fn pendingStatus() [status_bytes]u8 {
    return @splat(0xff);
}

fn address(span: Span, need: u64) Error!u32 {
    const limit: u64 = @as(u64, 1) << 40;
    if (span.address == 0 or span.address % 256 != 0 or span.address >= limit or
        span.bytes < need or span.bytes > limit - span.address) return error.Bounds;
    return @intCast(span.address >> 8);
}
fn overlaps(a: usize, a_size: usize, b: usize, b_size: usize) bool {
    const a_end = std.math.add(usize, a, a_size) catch return true;
    const b_end = std.math.add(usize, b, b_size) catch return true;
    return a < b_end and b < a_end;
}
fn inc(method: u32, count: u32) u32 {
    return 0x20000000 | (count << 16) | (4 << 13) | (method >> 2);
}
fn alignUp(value: u32, alignment: u32) u32 {
    return (value + alignment - 1) & ~(alignment - 1);
}
fn flag(value: bool, shift: u5) u32 {
    return @as(u32, @intFromBool(value)) << shift;
}
fn put(bytes: []u8, offset: usize, value: u32) void {
    std.mem.writeInt(u32, bytes[offset..][0..4], value, .little);
}
fn get(bytes: []const u8, offset: usize) u32 {
    return std.mem.readInt(u32, bytes[offset..][0..4], .little);
}
