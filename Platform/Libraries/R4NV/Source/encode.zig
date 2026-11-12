// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// NVENC wire fields: NVIDIA open-gpu-doc nvenc_drv.h (MIT).
// Complete notice: ../ThirdParty/Nvidia/LICENSES.txt.
// Original C-header fixtures and provenance: nvenc_status_vectors.json.
//! Pure NVENC helpers. The caller owns buffers, synchronization and codec state.
const std = @import("std");
pub const headers = @import("encode_headers.zig");
pub const Sequence = headers.Sequence;
pub const parameterSets = headers.parameterSets;
pub const picture = @import("encode_picture.zig");
pub const commands = @import("encode_commands.zig");

pub const picture_status_bytes = 128;
pub const slice_status_bytes = 16;
pub const status_bytes = picture_status_bytes + slice_status_bytes;
pub const max_bitstream_bytes = 8 * 1024 * 1024;
pub const PictureKind = picture.Kind;
pub const Completion = enum { pending, succeeded, failed };
pub const StatusError = error{ NotReady, Device, Bounds, MissingStatus, Encode, Bitstream };
pub const Expected = struct {
    picture_index: u32,
    kind: PictureKind,
    macroblocks: u32,
    buffer_bytes: u32,
    start: u32 = 0,
};
pub const Encoded = struct {
    offset: u32,
    bytes: u32,
    header_bits: u32,
    cycles: u32,
    qp_min: u16,
    qp_max: u16,
};

pub fn supported(class: u32) bool {
    // Wire identities do not establish engine availability or codec admission.
    return class == 0xc7b7 or class == 0xc9b7;
}

/// Initialize before EVERY submission, after the preceding physical retirement.
/// The single-slice profile enables SLICE_STAT_ON and sets slice_stat_offset=128.
/// A zero-filled record cannot be used as a completion indication.
pub fn pendingStatus() [status_bytes]u8 {
    return @splat(0xff);
}

/// The queue fence must have completed and the entire status snapshot must be
/// CPU-coherent. Neither ring GET nor a previous valid record is sufficient.
/// Bitstream syntax and SPS/PPS consistency still belong to the codec caller.
pub fn pictureStatus(data: []const u8, completion: Completion, expected: Expected) StatusError!Encoded {
    if (completion == .pending) return error.NotReady;
    if (completion == .failed) return error.Device;
    if (data.len < status_bytes or expected.picture_index == std.math.maxInt(u32) or
        expected.macroblocks == 0 or expected.macroblocks > 36864 or
        expected.buffer_bytes == 0 or expected.buffer_bytes > max_bitstream_bytes or
        expected.start >= expected.buffer_bytes) return error.Bounds;
    if (word(data, 0) != expected.picture_index or word(data, 4) == 0xffffffff) return error.MissingStatus;
    // Physical C7 completion is engine result2 with zero microcode error.
    // A HOST fence alone only proves that memory accesses have retired.
    if (word(data, 4) != 2) return error.Encode;
    // Firmware can reject parameters before producing any slice record. Keep
    // that fresh engine error distinct from a wholly missing completion; only
    // successful encoding needs the exact slice/range acknowledgement below.
    if (word(data, 8) == 0xffffffff or word(data, 128) == 0xffffffff or
        word(data, 132) == 0xffffffff or word(data, 136) == 0xffffffff) return error.MissingStatus;
    if (half(data, 16) != @intFromEnum(expected.kind) or half(data, 18) != 1 or
        @as(u32, half(data, 40)) + half(data, 42) != expected.macroblocks or
        half(data, 22) > 51 or half(data, 70) > 51 or half(data, 68) > half(data, 70)) return error.Encode;
    const start = word(data, 128);
    const length = word(data, 132);
    const bits = word(data, 8);
    const header_bits = word(data, 136);
    if (word(data, 32) != expected.start or start != expected.start or
        length < 6 or length > expected.buffer_bytes - start or bits == 0 or
        (@as(u64, bits) + 7) / 8 != length or word(data, 12) > bits or
        header_bits == 0 or header_bits > bits or
        word(data, 36) != start + length) return error.Encode; // Exclusive end despite the original field name.
    return .{ .offset = start, .bytes = length, .header_bits = header_bits,
        .cycles = word(data, 24), .qp_min = half(data, 68), .qp_max = half(data, 70) };
}

/// Validate the exact slice range before exposing it. This is a framing check,
/// not an independent H.264 decode. The first profile requests four-byte Annex-B
/// prefixes and one reference VCL NAL per picture; SPS/PPS are appended by owner.
pub fn sliceBytes(output: []const u8, result: Encoded, kind: PictureKind) StatusError![]const u8 {
    if (result.offset > output.len or result.bytes > output.len - result.offset or result.bytes < 6)
        return error.Bounds;
    const slice = output[result.offset..][0..result.bytes];
    if (!std.mem.eql(u8, slice[0..4], &.{ 0, 0, 0, 1 }) or slice[4] & 0x80 != 0 or
        slice[4] & 0x60 == 0 or slice[4] & 31 != @as(u8, if (kind == .idr) 5 else 1)) return error.Bitstream;
    // A second unescaped start code or an invalid emulation-prevention byte
    // contradicts the one-slice contract. Trailing zero bytes remain allowed.
    var zeros: usize = 0;
    var i: usize = 5;
    while (i < slice.len) : (i += 1) {
        const value = slice[i];
        if (zeros >= 2) {
            if (value == 3) {
                if (i + 1 == slice.len or slice[i + 1] > 3) return error.Bitstream;
                zeros = 0;
                continue;
            }
            if (value <= 2) {
                if (value != 0 or !std.mem.allEqual(u8, slice[i..], 0)) return error.Bitstream;
                break;
            }
        }
        zeros = if (value == 0) zeros + 1 else 0;
    }
    return slice;
}

fn word(bytes: []const u8, offset: usize) u32 {
    return std.mem.readInt(u32, bytes[offset..][0..4], .little);
}
fn half(bytes: []const u8, offset: usize) u16 {
    return std.mem.readInt(u16, bytes[offset..][0..2], .little);
}
