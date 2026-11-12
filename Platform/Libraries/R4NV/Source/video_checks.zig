// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const t = std.testing;
const v = @import("video.zig");
const vectors = @embedFile("nvdec_h264_vectors.bin");

fn picture(refs: []const v.Reference) v.Picture {
    var p: v.Picture = .{
        .sequence = .{ .profile = 100, .level = 51, .width_mbs = 4, .height_mbs = 3,
            .max_refs = 16, .log2_frame_num = 16, .poc_type = 0, .log2_poc_lsb = 16 },
        .parameters = .{ .entropy_coding = true, .bottom_field_poc_present = true,
            .l0_default_minus1 = 15, .l1_default_minus1 = 7, .deblocking_control = true,
            .redundant_pic_cnt = true, .transform_8x8 = true, .weighted_pred = true,
            .constrained_intra_pred = true, .initial_qp_minus26 = -26,
            .chroma_qp_offset = -12, .second_chroma_qp_offset = 12, .weighted_bipred = 2 },
        .current_surface = 16, .frame_num = 65535, .poc = .{ -2147483647, 2147483646 },
        .is_reference = true, .references = refs, .bitstream_bytes = 1234, .slices = 3,
    };
    for (&p.parameters.scaling4, 0..) |*value, i| value.* = @intCast(i + 1);
    for (&p.parameters.scaling8, 0..) |*value, i| value.* = @intCast(255 - i);
    return p;
}

pub fn run() !void {
    var refs: [16]v.Reference = undefined;
    for (&refs, 0..) |*ref, i| ref.* = .{ .surface = @intCast(i), .long_term = i % 2 != 0,
        .frame_index = @intCast(if (i % 2 != 0) i else 65534 - i),
        .poc = .{ -100 + @as(i32, @intCast(i)), 100 + @as(i32, @intCast(i)) } };
    var p = picture(&refs);
    var layout: v.Layout = .{ .luma_pitch = 128, .chroma_pitch = 64, .log2_gobs = 1 };
    for (0..2) |variant| {
        p.sequence.poc_type = @intCast(variant);
        p.sequence.delta_poc_always_zero = variant != 0;
        p.parameters.initial_qp_minus26 = if (variant == 0) -26 else 25;
        p.parameters.chroma_qp_offset = if (variant == 0) -12 else 12;
        p.parameters.second_chroma_qp_offset = if (variant == 0) 12 else -12;
        layout.log2_gobs = if (variant == 0) 1 else 5;
        for ([_]u32{ 0xc7b0, 0xc9b0 }) |class| {
            const actual = try v.encodePicture(class, &p, layout);
            try t.expectEqualSlices(u8, vectors[variant * 764 ..][0..764], &actual);
        }
    }
    p = picture(&refs);
    layout.log2_gobs = 1;
    const required = try v.requirements(p.sequence, layout);
    try t.expectEqual(@as(u32, 12), required.macroblocks);
    try t.expectEqual(@as(u32, 1024), required.coloc_stride);
    try t.expectEqual(@as(u32, 17408), required.coloc);
    try t.expectEqual(@as(u32, 512), required.mbhist);
    try t.expectEqual(@as(u32, 3072), required.history);
    try t.expectEqual(@as(u32, 6144), required.luma);
    try t.expectEqual(@as(u32, 2048), required.chroma);
    try commands(&p, layout);
    try rejectedPictures(&p, layout);
    try sliceChecks();
    try accessUnits();
    try statusChecks();
}

fn commands(p: *const v.Picture, layout: v.Layout) !void {
    const req = try v.requirements(p.sequence, layout);
    var b: v.Buffers = .{ .picture = span(0, 764), .bitstream = span(1, 1250), .slices = span(2, 16),
        .coloc = span(3, req.coloc), .history = span(4, req.history), .status = span(5, 56),
        .mbhist = span(6, req.mbhist), .surfaces = @splat(null) };
    for (&b.surfaces, 0..) |*surface, i| surface.* = .{
        .luma = span(7 + 2 * i, req.luma), .chroma = span(8 + 2 * i, req.chroma),
    };
    const methods = vectors[2 * 764 ..][0 .. 17 * 4];
    const binding = vectors[2 * 764 + 17 * 4 + 2 * 56 ..][0 .. 5 * 4];
    for ([_]u32{ 0xc7b0, 0xc9b0 }, 0..) |class, class_index| {
        const words = try v.encodeCommands(class, p, layout, &b, 0xfefefefe);
        try t.expectEqual(read(binding, 8), words[0]);
        try t.expectEqual(read(binding, 12 + class_index * 4), words[1]);
        try t.expectEqual(read(methods, class_index * 4), words[1] & 0xffff);
        try t.expectEqual(read(binding, 4), (words[1] >> 16) & 31);
        for ([_]usize{ 0, 2, 4, 12, 14, 32, 50, 52 }) |pos|
            try t.expectEqual(read(binding, 0), (words[pos] >> 13) & 7);
        const positions = [_]usize{ 2, 4, 14, 32, 50, 52 };
        const method_indices = [_]usize{ 2, 4, 13, 14, 15, 16 };
        for (positions, method_indices) |pos, i| try t.expectEqual(read(methods, i * 4), (words[pos] & 0x1fff) * 4);
        try t.expectEqual(@as(u32, 0x42033), words[5]); // Report errors, no concealment, watchdogs, production.
        try t.expectEqual(@as(u32, 0xfefefefe), words[8]);
        for ([_]v.Span{ b.picture, b.bitstream, b.slices, b.coloc, b.history, b.status, b.mbhist },
            [_]usize{ 6, 7, 9, 10, 11, 13, 51 }) |s, i| try t.expectEqual(@as(u32, @intCast(s.address >> 8)), words[i]);
        for (b.surfaces, 0..) |surface, i| {
            try t.expectEqual(@as(u32, @intCast(surface.?.luma.address >> 8)), words[15 + i]);
            try t.expectEqual(@as(u32, @intCast(surface.?.chroma.address >> 8)), words[33 + i]);
        }
        try t.expectEqual(@as(u32, 0), words[53]);
    }
    const original = b;
    b.bitstream.bytes -= 1;
    try t.expectError(error.Bounds, v.encodeCommands(0xc7b0, p, layout, &b, 0));
    b = original; b.coloc.bytes -= 1;
    try t.expectError(error.Bounds, v.encodeCommands(0xc7b0, p, layout, &b, 0));
    b = original; b.status.address += 1;
    try t.expectError(error.Bounds, v.encodeCommands(0xc7b0, p, layout, &b, 0));
    b = original; b.status.address = (@as(u64, 1) << 40) - 256; b.status.bytes = 257;
    try t.expectError(error.Bounds, v.encodeCommands(0xc7b0, p, layout, &b, 0));
    b.status.bytes = 56;
    _ = try v.encodeCommands(0xc7b0, p, layout, &b, 0);
    b = original; b.status.address = 0;
    try t.expectError(error.Bounds, v.encodeCommands(0xc7b0, p, layout, &b, 0));
    b = original; b.surfaces[16] = null;
    try t.expectError(error.Bounds, v.encodeCommands(0xc7b0, p, layout, &b, 0));
    b = original; b.surfaces[16].?.luma.bytes -= 1;
    try t.expectError(error.Bounds, v.encodeCommands(0xc7b0, p, layout, &b, 0));
    b = original; b.status.address = b.picture.address;
    try t.expectError(error.Alias, v.encodeCommands(0xc7b0, p, layout, &b, 0));
    b = original; b.surfaces[16] = b.surfaces[0];
    try t.expectError(error.Alias, v.encodeCommands(0xc7b0, p, layout, &b, 0));
    // A valid intra picture at index zero needs no reference surfaces.
    var intra = p.*;
    intra.references = &.{}; intra.current_surface = 0; intra.sequence.max_refs = 0;
    b = original;
    for (b.surfaces[1..]) |*surface| surface.* = null;
    _ = try v.encodeCommands(0xc7b0, &intra, layout, &b, 0);
    b.surfaces[1] = original.surfaces[1];
    try t.expectError(error.Bounds, v.encodeCommands(0xc7b0, &intra, layout, &b, 0));
}

fn rejectedPictures(original: *const v.Picture, layout: v.Layout) !void {
    for ([_]u32{ 0, 0xc4b0, 0xc6b0, 0xcfb0, 0xc7b5 }) |class|
        try t.expectError(error.Unsupported, v.encodePicture(class, original, layout));
    var p = original.*;
    p.sequence.profile = 110;
    try t.expectError(error.Unsupported, v.encodePicture(0xc7b0, &p, layout));
    p = original.*; p.sequence.frame_mbs_only = false;
    try t.expectError(error.Unsupported, v.encodePicture(0xc7b0, &p, layout));
    p = original.*; p.parameters.slice_groups = 2;
    try t.expectError(error.Unsupported, v.encodePicture(0xc7b0, &p, layout));
    p = original.*; p.sequence.width_mbs = 0;
    try t.expectError(error.Bounds, v.encodePicture(0xc7b0, &p, layout));
    p = original.*; p.parameters.initial_qp_minus26 = -27;
    try t.expectError(error.Bounds, v.encodePicture(0xc7b0, &p, layout));
    p = original.*; p.parameters.scaling4[95] = 0;
    try t.expectError(error.Bounds, v.encodePicture(0xc7b0, &p, layout));
    p = original.*; p.current_surface = 17;
    try t.expectError(error.Bounds, v.encodePicture(0xc7b0, &p, layout));
    p = original.*; p.current_surface = 0;
    try t.expectError(error.Alias, v.encodePicture(0xc7b0, &p, layout));
    p = original.*; p.bitstream_bytes = 0xffffffff;
    try t.expectError(error.Bounds, v.encodePicture(0xc7b0, &p, layout));
    var bad_layout = layout; bad_layout.log2_gobs = 0;
    try t.expectError(error.Bounds, v.encodePicture(0xc7b0, original, bad_layout));
    bad_layout.log2_gobs = 6;
    try t.expectError(error.Bounds, v.encodePicture(0xc7b0, original, bad_layout));
    var ref = original.references[0]; ref.long_term = true; ref.frame_index = 16;
    p = original.*; p.references = (&ref)[0..1];
    try t.expectError(error.Bounds, v.encodePicture(0xc7b0, &p, layout));
    // Software-supported Baseline/Main configurations remain representable.
    for ([_]u32{66, 77}) |profile| {
        p = original.*; p.sequence.profile = profile; p.parameters = .{};
        _ = try v.encodePicture(0xc7b0, &p, layout);
    }
}

fn sliceChecks() !void {
    const offsets = try v.sliceOffsets(&.{ 0, 48, 117 }, 1234);
    try t.expectEqual(@as(u32, 1234), read(&offsets, 12));
    try t.expectEqual(@as(u32, 0), read(&offsets, 16));
    try t.expectError(error.Bounds, v.sliceOffsets(&.{}, 12));
    try t.expectError(error.Bounds, v.sliceOffsets(&.{1}, 12));
    try t.expectError(error.Bounds, v.sliceOffsets(&.{0, 5, 5}, 12));
    try t.expectError(error.Bounds, v.sliceOffsets(&.{0, 12}, 12));
    var starts: [256]u32 = undefined;
    for (&starts, 0..) |*entry, i| entry.* = @intCast(i * 16);
    const maximum = try v.sliceOffsets(starts[0..255], 4096);
    try t.expectEqual(@as(u32, 4096), read(&maximum, 1020));
    try t.expectError(error.Bounds, v.sliceOffsets(&starts, 8192));
}

fn statusChecks() !void {
    const start = 2 * 764 + 17 * 4;
    const good = vectors[start..][0..56];
    const bad = vectors[start + 56 ..][0..56];
    try t.expectError(error.NotReady, v.pictureStatus(good, .pending, 12));
    try t.expectError(error.Device, v.pictureStatus(good, .failed, 12));
    try t.expectEqual(v.DecodeStatus{ .macroblocks = 12, .cycles = 54321 }, try v.pictureStatus(good, .succeeded, 12));
    try t.expectError(error.Decode, v.pictureStatus(bad, .succeeded, 12));
    try t.expectError(error.Decode, v.pictureStatus(good, .succeeded, 13));
    try t.expectError(error.MissingStatus, v.pictureStatus(&v.pendingStatus(), .succeeded, 12));
    try t.expectError(error.Bounds, v.pictureStatus(good[0..55], .succeeded, 12));
    var bytes = good[0..56].*;
    std.mem.writeInt(u32, bytes[52..56], 0x4101, .little);
    try t.expectError(error.Decode, v.pictureStatus(&bytes, .succeeded, 12));
    bytes = @splat(0);
    try t.expectError(error.Decode, v.pictureStatus(&bytes, .succeeded, 12));
}
fn accessUnits() !void {
    var storage: [256]u8 = @splat(0xa5);
    var au: v.AccessUnit = .{ .storage = &storage };
    const original = storage;
    try t.expectError(error.Unsupported, au.append(&.{ 0x67, 0 }));
    try t.expectError(error.Bounds, au.append(&.{ 0x81, 0 }));
    try t.expectEqualSlices(u8, &original, &storage);
    try t.expectEqual(@as(u16, 0), au.count);
    try t.expectError(error.Bounds, au.finish());
    try au.append(&.{ 0x65, 0x11, 0x22 });
    try au.append(&.{ 0x41, 0x33 });
    const before_alias = au;
    const before_storage = storage;
    try t.expectError(error.Alias, au.append(storage[3..6]));
    try t.expectEqualDeep(before_alias, au);
    try t.expectEqualSlices(u8, &before_storage, &storage);
    const encoded = try au.finish();
    try t.expectEqual(@as(u32, 11), encoded.bitstream_bytes);
    try t.expectEqual(@as(u32, 256), encoded.upload_bytes);
    try t.expectEqual(@as(u32, 2), encoded.slice_count);
    try t.expectEqualSlices(u8, &.{ 0, 0, 1, 0x65, 0x11, 0x22, 0, 0, 1, 0x41, 0x33 }, storage[0..11]);
    try t.expectEqualSlices(u8, &v.eos, storage[11..27]);
    try t.expectEqual(@as(u32, 6), read(&encoded.offsets, 4));
    try t.expectEqual(@as(u32, 11), read(&encoded.offsets, 8));
    for (storage[27..]) |value| try t.expectEqual(@as(u8, 0), value);
    try t.expectError(error.State, au.finish());
    try t.expectError(error.State, au.append(&.{0x41, 0}));
    // Capacity is checked with the complete EOS and padding, before mutation.
    au = .{ .storage = storage[0..255] };
    const full_before = storage;
    try t.expectError(error.Capacity, au.append(&.{0x65, 0}));
    try t.expectEqualSlices(u8, &full_before, &storage);
    try t.expectEqual(@as(u32, 0), au.length);
    // Metadata and output may not alias even in this fully trusted process.
    au = .{ .storage = undefined };
    au.storage = std.mem.asBytes(&au);
    try t.expectError(error.Alias, au.append(&.{0x65, 0}));
}
fn span(index: usize, size: u64) v.Span {
    return .{ .address = 0x100000000 + @as(u64, index) * 0x100000, .bytes = size };
}
fn read(bytes: []const u8, offset: usize) u32 {
    return std.mem.readInt(u32, bytes[offset..][0..4], .little);
}
