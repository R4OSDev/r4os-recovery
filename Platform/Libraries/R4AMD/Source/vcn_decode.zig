// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 AND MIT
// Copyright 2017, 2026 Advanced Micro Devices, Inc. SPDX-License-Identifier: MIT
// VCN1 tier-0 AVC wire format adapted from Mesa 26.2.2 ac_vcn_dec.c/.h and
// si_video_dec.c. Byte-identical originals and full grants: ThirdParty/.
const std = @import("std");
pub const max_refs = 16;
pub const max_slots = 17;
pub const max_stream = 8 * 1024 * 1024;
pub const embedded_bytes = 2048;
pub const its_offset = 1536;
pub const feedback_offset = 1792;
pub const feedback_bytes = 44;
pub const session_context_bytes = 128 * 1024;
pub const Error = error{ Unsupported, Invalid, Capacity, MissingStatus, Decode };
pub const Sequence = struct {
    codec: u32 = 1,
    depth: u32 = 8,
    width: u32 = 0,
    height: u32 = 0,
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
    gaps_allowed: bool = false,
};
pub const Requirements = struct { dpb: u32, context: u32, session: u32, pitch: u32, height: u32 };
pub fn requirements(s: Sequence) Error!Requirements {
    if ((s.profile != 66 and s.profile != 77 and s.profile != 100) or s.level == 0 or s.level > 51 or
        s.width_mbs < 4 or s.width_mbs > 256 or s.height_mbs < 4 or s.height_mbs > 256 or s.max_refs > 16 or
        @as(u64, s.width_mbs) * s.height_mbs > 36864 or
        s.log2_frame_num < 4 or s.log2_frame_num > 16 or s.poc_type > 2 or s.log2_poc_lsb < 4 or s.log2_poc_lsb > 16)
        return error.Unsupported;
    const pitch = std.mem.alignForward(u32, s.width_mbs * 16, 32);
    const height = std.mem.alignForward(u32, s.height_mbs * 16, 64);
    const image = std.mem.alignForward(u32, pitch * height * 3 / 2, 1024);
    const context = (s.max_refs + 1) * std.mem.alignForward(u32, s.width_mbs * std.mem.alignForward(u32, s.height_mbs, 2) * 192, 256);
    return .{ .dpb = image * (s.max_refs + 1), .context = context, .session = context + session_context_bytes, .pitch = pitch, .height = height };
}
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
    initial_qs_minus26: i32 = 0,
    chroma_qp_offset: i32 = 0,
    second_chroma_qp_offset: i32 = 0,
    scaling4: [96]u8 = @splat(16),
    scaling8: [128]u8 = @splat(16),
};
pub const Reference = struct { slot: u32, frame_num: u32, poc: [2]i32, long_term: bool = false };
pub const Picture = struct { sequence: Sequence, parameters: Parameters, slot: u32, frame_num: u32, poc: [2]i32, references: []const Reference };
pub const Target = struct { pitch: u32, chroma_offset: u32, bytes: u32 };
fn put(b: []u8, at: usize, v: u32) void {
    std.mem.writeInt(u32, b[at..][0..4], v, .little);
}
pub fn word(b: []const u8, at: usize) u32 {
    return std.mem.readInt(u32, b[at..][0..4], .little);
}
fn bit(v: bool, shift: u5) u32 {
    return @as(u32, @intFromBool(v)) << shift;
}
pub fn create(s: Sequence, handle: u32) Error![embedded_bytes]u8 {
    _ = try requirements(s);
    if (handle == 0) return error.Invalid;
    var b: [embedded_bytes]u8 = @splat(0);
    for ([_]u32{ 40, 56, 1, 0, handle, 0, 1, 40, 16, 0, 7, 0, s.width_mbs * 16, s.height_mbs * 16 }, 0..) |v, i| put(&b, i * 4, v);
    return b;
}
pub fn decode(p: Picture, target: Target, handle: u32, serial: u32, bitstream_bytes: u32) Error![embedded_bytes]u8 {
    const s = p.sequence;
    const q = p.parameters;
    const req = try requirements(s);
    if (handle == 0 or serial == 0 or p.slot > s.max_refs or p.frame_num >= @as(u32, 1) << @intCast(s.log2_frame_num) or
        p.references.len > s.max_refs or q.l0_default_minus1 > 15 or q.l1_default_minus1 > 15 or q.weighted_bipred > 2 or
        q.initial_qp_minus26 < -26 or q.initial_qp_minus26 > 25 or q.initial_qs_minus26 < -26 or q.initial_qs_minus26 > 25 or
        q.chroma_qp_offset < -12 or q.chroma_qp_offset > 12 or q.second_chroma_qp_offset < -12 or q.second_chroma_qp_offset > 12 or
        target.pitch < s.width_mbs * 16 or target.pitch % 256 != 0 or target.chroma_offset % 65536 != 0 or
        target.chroma_offset < @as(u64, target.pitch) * s.height_mbs * 16 or
        target.bytes < @as(u64, target.chroma_offset) + @as(u64, target.pitch) * s.height_mbs * 8 or
        bitstream_bytes == 0 or bitstream_bytes > max_stream or bitstream_bytes % 128 != 0) return error.Invalid;
    var used: u32 = @as(u32, 1) << @intCast(p.slot);
    for (p.references) |r| {
        if (r.slot > s.max_refs or used & (@as(u32, 1) << @intCast(r.slot)) != 0 or r.frame_num > 65535) return error.Invalid;
        used |= @as(u32, 1) << @intCast(r.slot);
    }
    for (q.scaling4) |v| if (v == 0) return error.Invalid;
    for (q.scaling8) |v| if (v == 0) return error.Invalid;
    var b: [embedded_bytes]u8 = @splat(0);
    // Header plus two indices, 188-byte common decode, 1124-byte AVC message.
    for ([_]u32{ 40, 1368, 2, 1, handle, serial, 2, 56, 188, 0, 6, 244, 1124, 0 }, 0..) |v, i| put(&b, i * 4, v);
    const d = b[56..244];
    put(d, 0, 7);
    put(d, 8, s.width_mbs * 16);
    put(d, 12, s.height_mbs * 16);
    put(d, 16, bitstream_bytes);
    put(d, 20, req.dpb);
    put(d, 24, target.bytes);
    put(d, 36, req.context);
    put(d, 40, session_context_bytes);
    // MSG, DPB, bitstream, target, feedback, scaling and HW context. Session is
    // explicitly excluded from decode_buffer_flags by upstream.
    put(d, 68, 0xa1f);
    put(d, 72, req.pitch);
    put(d, 76, req.height);
    put(d, 100, target.pitch);
    put(d, 104, target.pitch / 2);
    put(d, 144, target.chroma_offset);
    put(d, 164, std.mem.alignForward(u32, s.width_mbs * 8, 32));
    // Linear surfaces; VCN1's addr-lib selector is 0 (ac_vcn_dec.c).
    const a = b[244..1368];
    put(a, 0, switch (s.profile) {
        66 => 0,
        77 => 1,
        else => 2,
    });
    put(a, 4, s.level);
    put(a, 8, bit(s.direct_8x8, 0) | 4 | bit(s.delta_poc_always_zero, 3) | bit(s.gaps_allowed, 5) | 128);
    put(a, 12, bit(q.transform_8x8, 0) | bit(q.redundant_pic_cnt, 1) | bit(q.constrained_intra_pred, 2) | bit(q.deblocking_control, 3) |
        q.weighted_bipred << 4 | bit(q.weighted_pred, 6) | bit(q.bottom_field_poc_present, 7) | bit(q.entropy_coding, 8));
    a[16] = 1;
    a[19] = @intCast(s.log2_frame_num - 4);
    a[20] = @intCast(s.poc_type);
    a[21] = @intCast(s.log2_poc_lsb - 4);
    a[22] = @intCast(s.max_refs);
    a[24] = @bitCast(@as(i8, @intCast(q.initial_qp_minus26)));
    a[25] = @bitCast(@as(i8, @intCast(q.initial_qs_minus26)));
    a[26] = @bitCast(@as(i8, @intCast(q.chroma_qp_offset)));
    a[27] = @bitCast(@as(i8, @intCast(q.second_chroma_qp_offset)));
    a[30] = @intCast(q.l0_default_minus1);
    a[31] = @intCast(q.l1_default_minus1);
    put(a, 260, p.frame_num);
    put(a, 328, @bitCast(p.poc[0]));
    put(a, 332, @bitCast(p.poc[1]));
    put(a, 464, p.slot);
    put(a, 468, @intCast(p.references.len));
    @memset(a[472..488], 255);
    var reference_flags: u32 = 0;
    for (p.references, 0..) |r, i| {
        put(a, 264 + i * 4, r.frame_num);
        put(a, 336 + i * 8, @bitCast(r.poc[0]));
        put(a, 340 + i * 8, @bitCast(r.poc[1]));
        a[472 + i] = @as(u8, @intCast(r.slot)) | if (r.long_term) @as(u8, 128) else 0;
        reference_flags |= @as(u32, 3) << @intCast(i * 2);
    }
    put(a, 1120, reference_flags);
    @memcpy(b[its_offset..][0..96], &q.scaling4);
    @memcpy(b[its_offset + 96 ..][0..128], &q.scaling8);
    // Only the firmware may replace this pending serial/status. A stale success
    // or an untouched all-zero buffer must never publish an output image.
    const f = b[feedback_offset..][0..feedback_bytes];
    put(f, 0, feedback_bytes);
    put(f, 4, feedback_bytes);
    put(f, 12, ~serial);
    put(f, 16, 0xffffffff);
    put(f, 24, 0xffffffff);
    return b;
}
pub fn feedback(bytes: []const u8, serial: u32) Error!void {
    if (bytes.len < feedback_bytes or serial == 0) return error.Invalid;
    if (word(bytes, 0) != feedback_bytes or word(bytes, 4) < feedback_bytes or word(bytes, 4) > embedded_bytes - feedback_offset or
        word(bytes, 12) != serial or word(bytes, 16) == 0xffffffff or word(bytes, 24) == 0xffffffff) return error.MissingStatus;
    if (word(bytes, 16) != 0 or word(bytes, 24) != 0) return error.Decode;
}
pub const Span = struct { address: u64, bytes: u64 };
pub const Buffers = struct { embedded: Span, session: Span, dpb: Span, bitstream: Span, target: Span };
fn validSpan(s: Span, min: u64) bool {
    return s.bytes >= min and s.address != 0 and s.address % 256 == 0 and s.address <= 0xffffffffff -| s.bytes;
}
pub fn commands(s: Sequence, buffers: Buffers, creating: bool) Error![64]u32 {
    const req = try requirements(s);
    if (!validSpan(buffers.embedded, embedded_bytes) or !validSpan(buffers.session, req.session) or
        (!creating and (!validSpan(buffers.dpb, req.dpb) or !validSpan(buffers.bitstream, 128) or !validSpan(buffers.target, 1)))) return error.Invalid;
    var b: [64]u32 = @splat(0x80000000);
    var at: usize = 0;
    emit(&b, &at, 5, buffers.session.address);
    emit(&b, &at, 0, buffers.embedded.address);
    if (!creating) {
        emit(&b, &at, 1, buffers.dpb.address);
        emit(&b, &at, 0x206, buffers.session.address + session_context_bytes);
        emit(&b, &at, 0x204, buffers.embedded.address + its_offset);
        emit(&b, &at, 3, buffers.embedded.address + feedback_offset);
        emit(&b, &at, 0x100, buffers.bitstream.address);
        emit(&b, &at, 2, buffers.target.address);
        b[at] = 0x20718 / 4;
        b[at + 1] = 1;
    }
    return b;
}
fn emit(b: []u32, at: *usize, cmd: u32, va: u64) void {
    @memcpy(b[at.*..][0..6], &[_]u32{ 0x20710 / 4, @truncate(va), 0x20714 / 4, @intCast(va >> 32), 0x2070c / 4, cmd << 1 });
    at.* += 6;
}
pub const AccessUnit = struct {
    storage: []u8,
    codec: u32 = 1,
    length: u32 = 0,
    slices: u32 = 0,
    finished: bool = false,
    pub fn append(self: *AccessUnit, nal: []const u8) Error!void {
        if (self.finished or nal.len == 0 or nal.len > max_stream - 3 or self.slices == 65535) return error.Invalid;
        const prefix: usize = if (self.codec == 1 or self.codec == 2) 3 else 0;
        if (self.codec == 1) {
            if (nal[0] & 128 != 0) return error.Invalid;
            if (nal[0] & 31 != 1 and nal[0] & 31 != 5) return error.Unsupported;
        } else if (self.codec == 2) {
            if (nal.len < 2 or nal[0] & 128 != 0 or nal[1] & 7 == 0 or (nal[0] >> 1) & 63 > 31) return error.Unsupported;
        } else if (self.codec < 3 or self.codec > 6) return error.Unsupported;
        const end = @as(u64, self.length) + nal.len + prefix;
        if (end > max_stream or end > self.storage.len or std.mem.alignForward(u64, end, 128) > self.storage.len) return error.Capacity;
        // memmove semantics are not allowed: original escaped NAL storage is
        // owned by FFmpeg and must be disjoint from the GPU upload buffer.
        if (@intFromPtr(nal.ptr) < @intFromPtr(self.storage.ptr) + self.storage.len and
            @intFromPtr(self.storage.ptr) < @intFromPtr(nal.ptr) + nal.len) return error.Invalid;
        if (prefix != 0) @memcpy(self.storage[self.length..][0..3], &[_]u8{ 0, 0, 1 });
        @memcpy(self.storage[self.length + prefix ..][0..nal.len], nal);
        self.length = @intCast(end);
        self.slices += 1;
    }
    pub fn finish(self: *AccessUnit) Error!u32 {
        if (self.finished or self.slices == 0 or self.length > max_stream) return error.Invalid;
        const end = std.mem.alignForward(u32, self.length, 128);
        if (end > self.storage.len) return error.Capacity;
        @memset(self.storage[self.length..end], 0);
        self.finished = true;
        return end;
    }
};
