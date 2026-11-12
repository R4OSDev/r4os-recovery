// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const t = std.testing;
const e = @import("encode.zig");
const original = @embedFile("nvenc_status_vectors.bin");

pub fn run() !void {
    try pictures();
    try capturedStatus();
    var expected: e.Expected = .{ .picture_index = 0x12345678, .kind = .idr,
        .macroblocks = 240, .buffer_bytes = 4096, .start = 256 };
    const valid = original[0..e.status_bytes];
    const result = try e.pictureStatus(valid, .succeeded, expected);
    try t.expect(result.offset == 256 and result.bytes == 20 and result.header_bits == 16 and
        result.cycles == 0x76543210 and result.qp_min == 18 and result.qp_max == 32);
    expected.kind = .predicted;
    _ = try e.pictureStatus(original[e.status_bytes..][0..e.status_bytes], .succeeded, expected);
    expected.kind = .idr;
    for (2..4) |i| {
        const failed = original[i * e.status_bytes..][0..e.status_bytes];
        try t.expectError(error.Encode, e.pictureStatus(failed, .succeeded, expected));
        var rejected = e.pendingStatus();
        @memcpy(rejected[0..8], failed[0..8]);
        try t.expectError(error.Encode, e.pictureStatus(&rejected, .succeeded, expected));
    }
    try t.expectError(error.NotReady, e.pictureStatus(valid, .pending, expected));
    try t.expectError(error.Device, e.pictureStatus(valid, .failed, expected));
    try t.expectError(error.MissingStatus, e.pictureStatus(&e.pendingStatus(), .succeeded, expected));
    expected.picture_index += 1;
    try t.expectError(error.MissingStatus, e.pictureStatus(valid, .succeeded, expected));
    expected.picture_index -= 1;
    try t.expectError(error.Bounds, e.pictureStatus(valid[0..143], .succeeded, expected));
    expected.start = 4096;
    try t.expectError(error.Bounds, e.pictureStatus(valid, .succeeded, expected));
    expected.start = 256;
    expected.buffer_bytes = 275;
    try t.expectError(error.Encode, e.pictureStatus(valid, .succeeded, expected));
    expected.buffer_bytes = 4096;
    // Corrupt independently returned identity, counts and range receipts.
    for ([_]struct { offset: usize, value: u32 }{
        .{ .offset = 8, .value = 0 }, .{ .offset = 8, .value = 168 },
        .{ .offset = 12, .value = 161 }, .{ .offset = 16, .value = 3 },
        .{ .offset = 16, .value = 0x20003 }, .{ .offset = 32, .value = 255 },
        .{ .offset = 36, .value = 274 }, .{ .offset = 36, .value = 275 }, .{ .offset = 40, .value = 239 },
        .{ .offset = 68, .value = 52 << 16 }, .{ .offset = 68, .value = (18 << 16) | 32 },
        .{ .offset = 128, .value = 0xfffffffe }, .{ .offset = 132, .value = 0 },
        .{ .offset = 136, .value = 0 }, .{ .offset = 136, .value = 161 },
    }) |fault| {
        var data = valid.*;
        std.mem.writeInt(u32, data[fault.offset..][0..4], fault.value, .little);
        try t.expectError(error.Encode, e.pictureStatus(&data, .succeeded, expected));
    }
    var output: [4096]u8 = @splat(0xa5);
    const slice = output[result.offset..][0..result.bytes];
    slice[0..5].* = .{ 0, 0, 0, 1, 0x65 };
    slice[5..10].* = .{ 0, 0, 3, 0, 1 };
    try t.expectEqualSlices(u8, slice, try e.sliceBytes(&output, result, .idr));
    try t.expectError(error.Bitstream, e.sliceBytes(&output, result, .predicted));
    try t.expectError(error.Bounds, e.sliceBytes(output[0..275], result, .idr));
    slice[4] |= 0x80;
    try t.expectError(error.Bitstream, e.sliceBytes(&output, result, .idr));
    slice[4] = 5;
    try t.expectError(error.Bitstream, e.sliceBytes(&output, result, .idr));
    slice[4] = 0x65;
    for ([_]u8{ 0, 1, 2 }) |bad| {
        slice[7] = bad;
        try t.expectError(error.Bitstream, e.sliceBytes(&output, result, .idr));
    }
    slice[7] = 3; slice[8] = 4;
    try t.expectError(error.Bitstream, e.sliceBytes(&output, result, .idr));
    @memset(slice[5..], 0);
    slice[5] = 0x80;
    _ = try e.sliceBytes(&output, result, .idr); // Annex-B trailing zeros.
    slice[19] = 3;
    try t.expectError(error.Bitstream, e.sliceBytes(&output, result, .idr));
    try t.expect(e.supported(0xc7b7) and e.supported(0xc9b7) and !e.supported(0xc4b7) and !e.supported(0xcfb7));
}

fn capturedStatus() !void {
    // Actual C7 completion after GR preparation and independently decoded
    // NVENC output. This protects semantics that C sizeof/offsetof cannot.
    const data = @embedFile("nvenc_status_capture.bin");
    const expected: e.Expected = .{ .picture_index = 0, .kind = .idr,
        .macroblocks = 240, .buffer_bytes = 1048535 };
    const result = try e.pictureStatus(data, .succeeded, expected);
    try t.expect(result.offset == 0 and result.bytes == 38400 and result.header_bits == 28);
    try t.expectError(error.NotReady, e.pictureStatus(data, .pending, expected));
    try t.expectError(error.Device, e.pictureStatus(data, .failed, expected));
    for ([_]u32{0,1,3,6,10,0x30000006}) |code| {
        var invalid: [e.status_bytes]u8 = data.*;
        std.mem.writeInt(u32, invalid[4..8], code, .little);
        try t.expectError(error.Encode, e.pictureStatus(&invalid, .succeeded, expected));
    }
    var inclusive: [e.status_bytes]u8 = data.*;
    std.mem.writeInt(u32, inclusive[36..40], result.bytes - 1, .little);
    try t.expectError(error.Encode, e.pictureStatus(&inclusive, .succeeded, expected));
}

fn pictures() !void {
    const v = e.picture;
    const vectors = @embedFile("nvenc_picture_vectors.bin");
    var p: v.Picture = .{ .sequence = .{ .width = 62, .height = 46, .qp = 0, .fps_num = 30000, .fps_den = 1001 },
        .input = .{ .luma_pitch = 128, .chroma_pitch = 64, .chroma_offset = 8192, .block_height_field = 2 },
        .reference = .{ .luma_pitch = 128, .chroma_pitch = 64, .chroma_offset = 8192, .block_height_field = 2 },
        .kind = .idr, .frame_num = 0, .idr_pic_id = 65535, .bitstream_bytes = 4096 };
    for ([_]u32{ 0xc7b7, 0xc9b7 }, 0..) |class, ci| {
        for (0..2) |variant| {
            p.kind = if (variant == 0) .idr else .predicted;
            p.sequence.qp = if (variant == 0) 0 else 51;
            p.frame_num = if (variant == 0) 0 else 65535;
            p.input.block_height_field = if (variant == 0) 2 else 4;
            p.bitstream_bytes = if (variant == 0) 4096 else 8 * 1024 * 1024;
            const bytes = try v.encode(class, p);
            try t.expectEqualSlices(u8, vectors[(ci * 2 + variant) * v.picture_bytes ..][0..v.picture_bytes], &bytes);
            const headers = try e.parameterSets(p.sequence);
            try t.expect(headers.length > 0 and headers.length <= e.headers.max_parameter_bytes);
        }
    }
    try commands(p);
    try t.expectError(error.Unsupported, v.encode(0xc4b7, p));
    p.reference.tiled_16x16 = true;
    try t.expectError(error.Unsupported, v.encode(0xc7b7, p));
    p.reference.tiled_16x16 = false;
    p.input.block_height_field = 0;
    try t.expectError(error.Unsupported, v.encode(0xc7b7, p));
    p.input.block_height_field = 4;
    p.input.chroma_offset = 8191;
    try t.expectError(error.Bounds, v.encode(0xc7b7, p));
    p.input.chroma_offset = 8192;
    p.reference.luma_pitch = 65536;
    try t.expectError(error.Bounds, v.encode(0xc7b7, p));
    p.reference.luma_pitch = 128;
    p.kind = .idr;
    try t.expectError(error.Bounds, v.encode(0xc7b7, p));
    p.frame_num = 0;
    p.bitstream_bytes = 4095;
    try t.expectError(error.Bounds, v.encode(0xc7b7, p));
    p.bitstream_bytes = 4096;
    p.sequence.width = 63;
    try t.expectError(error.Bounds, v.encode(0xc7b7, p));
    try t.expectError(error.Bounds, e.parameterSets(p.sequence));
    p.sequence.width = 4096; p.sequence.height = 4096;
    try t.expectError(error.Unsupported, e.parameterSets(p.sequence));
    p.sequence.width = 3840; p.sequence.height = 2160; p.sequence.fps_num = 31; p.sequence.fps_den = 1;
    try t.expectError(error.Unsupported, e.parameterSets(p.sequence));
    p.sequence.fps_num = 30;
    _ = try e.parameterSets(p.sequence);
    p.sequence.fps_num = std.math.maxInt(u32);
    try t.expectError(error.Bounds, e.parameterSets(p.sequence));
    p.sequence.fps_num = 30; p.sequence.fps_den = 0;
    try t.expectError(error.Bounds, e.parameterSets(p.sequence));
    p.sequence.fps_den = 1; p.sequence.qp = 52;
    try t.expectError(error.Bounds, e.parameterSets(p.sequence));
}

fn commands(picture: e.picture.Picture) !void {
    const c = e.commands;
    const vectors = @embedFile("nvenc_method_vectors.bin");
    const req = try e.picture.requirements(picture);
    const original_buffers: c.Buffers = .{
        .picture = span(0, 1152), .status = span(1, 256), .history = span(2, req.history),
        .bitstream = span(3, picture.bitstream_bytes),
        .input = testSurface(4),
        .output = testSurface(6),
        .coloc = span(8, req.coloc),
        .reference = .{ .surface = testSurface(9), .coloc = span(11, req.coloc) },
    };
    for ([_]u32{ 0xc7b7, 0xc9b7 }, 0..) |class, i| {
        const words = try c.encode(class, picture, original_buffers, 0x12345678);
        try t.expectEqualSlices(u8, vectors[i * c.word_count * 4 ..][0 .. c.word_count * 4], std.mem.asBytes(&words));
        for ([_]usize{ 0, 2, 5, 22, 39, 54, 59 }) |at|
            try t.expectEqual(@as(u32, 0), (words[at] >> 13) & 7);
        try t.expect(words[53] == words[55] and words[55] == words[56]);
        try t.expect(words[52] == words[58] and words[6] == words[23]);
        try t.expect(std.mem.allEqual(u32, words[7..22], 0) and std.mem.allEqual(u32, words[24..39], 0));
        for ([_]usize{ 42, 43, 45, 49, 57, 60 }) |at| try t.expectEqual(@as(u32, 0), words[at]);
    }
    var p = picture;
    var b = original_buffers;
    b.reference = null;
    try t.expectError(error.Bounds, c.encode(0xc7b7, p, b, 0));
    p.kind = .idr; p.frame_num = 0;
    const intra = try c.encode(0xc7b7, p, b, 0);
    try t.expect(intra[6] == 0 and intra[23] == 0 and intra[50] == 0);
    p = picture; b = original_buffers;
    b.bitstream.bytes -= 1;
    try t.expectError(error.Bounds, c.encode(0xc7b7, p, b, 0));
    b = original_buffers; b.output = b.input;
    try t.expectError(error.Alias, c.encode(0xc7b7, p, b, 0));
    b = original_buffers; b.history.address = b.picture.address;
    try t.expectError(error.Alias, c.encode(0xc7b7, p, b, 0));
    b = original_buffers; b.input.chroma.address += 256;
    try t.expectError(error.Bounds, c.encode(0xc7b7, p, b, 0));
    b = original_buffers; b.status.address += 1;
    try t.expectError(error.Bounds, c.encode(0xc7b7, p, b, 0));
    b = original_buffers; b.status.address = (@as(u64, 1) << 40) - 256; b.status.bytes = 257;
    try t.expectError(error.Bounds, c.encode(0xc7b7, p, b, 0));
    b.status.bytes = 256;
    _ = try c.encode(0xc7b7, p, b, 0);
    try t.expectError(error.Bounds, c.encode(0xc7b7, p, b, 0xffffffff));
    try t.expectError(error.Unsupported, c.encode(0xcfb7, p, b, 0));
}
fn testSurface(index: usize) e.commands.Surface {
    return .{ .luma = span(index, 8192), .chroma = .{ .address = span(index, 0).address + 8192, .bytes = 2048 } };
}
fn span(index: usize, bytes: u64) e.commands.Span {
    return .{ .address = 0x100000000 + index * 0x2000000, .bytes = bytes };
}
fn read(data: []const u8, offset: usize) u32 { return std.mem.readInt(u32, data[offset..][0..4], .little); }
