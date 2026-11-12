// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const t = std.testing;
const v = @import("vcn_decode.zig");
const seq: v.Sequence = .{ .profile = 100, .level = 31, .width_mbs = 120, .height_mbs = 68, .max_refs = 4, .log2_frame_num = 8, .poc_type = 0, .log2_poc_lsb = 8 };
test "VCN1 H264 wire bounds, fresh feedback and transactional escaped slices" {
    const req = try v.requirements(seq);
    try t.expectEqual(@as(u32, 5 * 3133440), req.dpb);
    var bytes: [256]u8 = @splat(0xa7);
    var au: v.AccessUnit = .{ .storage = &bytes };
    try au.append(&.{ 0x65, 0x88, 0x80 });
    const saved = bytes;
    try t.expectError(error.Unsupported, au.append(&.{ 0x67, 1, 2 }));
    try t.expectEqualDeep(saved, bytes);
    try t.expectError(error.Invalid, au.append(bytes[3..6]));
    try t.expectEqualDeep(saved, bytes);
    try t.expectEqual(@as(u32, 128), try au.finish());
    try t.expectEqualSlices(u8, &.{ 0, 0, 1, 0x65, 0x88, 0x80 }, bytes[0..6]);
    for (bytes[6..128]) |b| try t.expectEqual(@as(u8, 0), b);
    const refs = [_]v.Reference{.{ .slot = 1, .frame_num = 7, .poc = .{ -2, 1 }, .long_term = true }};
    var p: v.Picture = .{ .sequence = seq, .parameters = .{}, .slot = 0, .frame_num = 8, .poc = .{ 4, 4 }, .references = &refs };
    const target: v.Target = .{ .pitch = 2048, .chroma_offset = 2228224, .bytes = 3342336 };
    var message = try v.decode(p, target, 51, 27, 128);
    const f = message[v.feedback_offset..][0..v.feedback_bytes];
    try t.expectError(error.MissingStatus, v.feedback(f, 27));
    std.mem.writeInt(u32, f[12..16], 27, .little);
    std.mem.writeInt(u32, f[16..20], 0, .little);
    std.mem.writeInt(u32, f[24..28], 0, .little);
    try v.feedback(f, 27);
    try t.expectError(error.MissingStatus, v.feedback(f, 28));
    std.mem.writeInt(u32, f[24..28], 1, .little);
    try t.expectError(error.Decode, v.feedback(f, 27));
    p.slot = 1;
    try t.expectError(error.Invalid, v.decode(p, target, 51, 27, 128));
    var bad = seq;
    bad.profile = 110;
    try t.expectError(error.Unsupported, v.requirements(bad));
    bad = seq;
    bad.max_refs = 17;
    try t.expectError(error.Unsupported, v.requirements(bad));
    bad = seq;
    bad.width_mbs = 256;
    bad.height_mbs = 256;
    try t.expectError(error.Unsupported, v.requirements(bad));
}

test "VCN1 AVC messages match original Mesa C oracle for Baseline Main and High" {
    const vectors = @embedFile("Generated/vcn_h264.bin");
    const refs = [_]v.Reference{ .{ .slot = 1, .frame_num = 7, .poc = .{ -2, 1 } }, .{ .slot = 0, .frame_num = 0, .poc = .{ 0, 1 }, .long_term = true } };
    for ([_]u32{ 66, 77, 100 }, 0..) |profile, k| {
        var s = seq;
        s.profile = profile;
        s.poc_type = @intCast(k);
        s.delta_poc_always_zero = k == 1;
        s.gaps_allowed = k == 2;
        var q: v.Parameters = .{ .entropy_coding = k != 0, .transform_8x8 = k == 2, .deblocking_control = true, .weighted_pred = k != 0, .weighted_bipred = @intCast(k), .bottom_field_poc_present = true, .redundant_pic_cnt = k == 0, .constrained_intra_pred = k == 2, .initial_qp_minus26 = -3, .initial_qs_minus26 = 2, .chroma_qp_offset = -2, .second_chroma_qp_offset = 4, .l0_default_minus1 = 1 };
        for (&q.scaling4, 0..) |*b, i| b.* = @intCast(i + 1);
        for (&q.scaling8, 0..) |*b, i| b.* = @intCast(i + 2);
        const result = try v.decode(.{ .sequence = s, .parameters = q, .slot = 2, .frame_num = 8, .poc = .{ 4, 5 }, .references = &refs }, .{ .pitch = 2048, .chroma_offset = 2228224, .bytes = 3342336 }, 51, 27, 128);
        try t.expectEqualSlices(u8, vectors[k * v.embedded_bytes ..][0..v.embedded_bytes], &result);
    }
}
