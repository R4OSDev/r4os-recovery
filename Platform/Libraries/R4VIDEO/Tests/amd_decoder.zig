// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const t = std.testing;
const r = @import("r4os");
const gpu = @import("gpu_resources");
const v = @import("r4amd_decode");
const Budget = @import("native_allocation").Budget;
const ff = @cImport(@cInclude("nvdec.h"));
const Decoder = @import("amd_decoder").Implementation(ff);
const fixture = @import("gpu_model");
var state: struct { mode: enum { success, missing, stale, corrupt } = .success, creates: u32 = 0, pictures: u32 = 0, current: u32 = 0, refs: [2]u8 = @splat(255), serial: u32 = 0 } = .{};
fn inspect(words: []const u8) void {
    const address = @as(u64, v.word(words, 7 * 4)) | @as(u64, v.word(words, 9 * 4)) << 32;
    const emb = fixture.virtualBytes(address);
    std.debug.assert(v.word(emb, 0) == 40 and v.word(emb, 16) != 0);
    if (v.word(emb, 12) == 0) {
        state.creates += 1;
        return;
    }
    std.debug.assert(v.word(emb, 12) == 1 and v.word(emb, 20) > state.serial);
    state.serial = v.word(emb, 20);
    state.pictures += 1;
    state.current = v.word(emb, 244 + 464);
    state.refs = emb[244 + 472 ..][0..2].*;
    const feedback = emb[v.feedback_offset..][0..v.feedback_bytes];
    std.debug.assert(v.word(feedback, 12) == ~state.serial and v.word(feedback, 16) == 0xffffffff and v.word(feedback, 24) == 0xffffffff);
    if (state.mode == .missing) return;
    std.mem.writeInt(u32, feedback[12..16], if (state.mode == .stale) state.serial - 1 else state.serial, .little);
    std.mem.writeInt(u32, feedback[16..20], 0, .little);
    std.mem.writeInt(u32, feedback[24..28], @intFromBool(state.mode == .corrupt), .little);
}
fn pic(s: ff.struct_r4video_nvdec_sequence, n: u32) ff.struct_r4video_nvdec_picture {
    var p = std.mem.zeroes(ff.struct_r4video_nvdec_picture);
    p.sequence = s;
    p.frame_num = n;
    p.is_reference = 1;
    p.poc = @splat(@as(i32, @intCast(n * 2)));
    p.scaling4 = @splat(@splat(16));
    p.scaling8 = @splat(@splat(16));
    return p;
}
fn frame(ops: ff.struct_r4video_nvdec_ops, p: *const ff.struct_r4video_nvdec_picture, rc: c_int) !?*anyopaque {
    var out: ?*anyopaque = null;
    try t.expectEqual(@as(c_int, 0), ops.allocate.?(ops.owner, &p.sequence, &out));
    try t.expect(out != null);
    try t.expectEqual(@as(c_int, 0), ops.begin.?(ops.owner, out, p));
    const nal = [_]u8{ 0x65, 0x88, 0x80 };
    try t.expectEqual(@as(c_int, 0), ops.slice.?(ops.owner, out, &nal, nal.len));
    try t.expectEqual(rc, ops.end.?(ops.owner, out));
    return out;
}
pub fn run(base: r.program.Context) !void {
    var model: fixture.Model = .{ .provider = .amd, .next_va = @import("r4amd").native_va_start, .push_bytes = 256, .on_submit = inspect };
    fixture.model = &model;
    state = .{};
    var budget: Budget = .{ .limit = 64 * 1024 * 1024 };
    const device = try gpu.Device.queryProvider(base, 9, .decode, .amd);
    var decoder: Decoder = .{ .ctx = .{ .base = base, .device = device, .budget = &budget, .clock = fixture.clock } };
    var ops = decoder.ops();
    const seq: ff.struct_r4video_nvdec_sequence = .{ .profile = 100, .level = 31, .width_mbs = 8, .height_mbs = 4, .max_refs = 2, .log2_frame_num = 8, .poc_type = 0, .log2_poc_lsb = 8, .delta_poc_always_zero = 0, .direct_8x8 = 1, .gaps_allowed = 0 };
    var p = pic(seq, 0);
    const first = try frame(ops, &p, 0);
    try t.expectEqual(@as(u32, 0), state.current);
    const first_bo = decoder.describe(first).?.backing.buffer;
    p = pic(seq, 1);
    p.reference_count = 1;
    p.references[0] = .{ .image = first, .long_term = 0, .frame_index = 0, .poc = .{ 0, 0 } };
    const second = try frame(ops, &p, 0);
    try t.expectEqual(@as(u32, 1), state.current);
    try t.expectEqual(@as(u8, 0), state.refs[0]);
    p = pic(seq, 2);
    p.reference_count = 2;
    p.references[0] = .{ .image = second, .long_term = 0, .frame_index = 1, .poc = .{ 2, 2 } };
    p.references[1] = .{ .image = first, .long_term = 1, .frame_index = 0, .poc = .{ 0, 0 } };
    const third = try frame(ops, &p, 0);
    try t.expectEqual(@as(u32, 2), state.current);
    try t.expectEqualDeep([2]u8{ 1, 128 }, state.refs);
    decoder.flush();
    p = pic(seq, 0);
    const after_seek = try frame(ops, &p, 0);
    try t.expectEqual(@as(u32, 0), state.current);
    try t.expectEqualDeep(first_bo, decoder.describe(first).?.backing.buffer);
    try t.expectEqual(@as(u32, 1), state.creates); // Flush reuses the acknowledged external session.
    // Resize with old consumer images: new internal DPB/session, stable old BO.
    p = pic(seq, 0);
    p.sequence.width_mbs = 16;
    const resized = try frame(ops, &p, 0);
    try t.expectEqual(@as(u32, 2), state.creates);
    try t.expectEqualDeep(first_bo, decoder.describe(first).?.backing.buffer);
    try t.expectError(error.Busy, decoder.close());
    try t.expect(decoder.describe(first) != null);
    for ([_]?*anyopaque{ first, second, third, after_seek, resized }) |image| ops.release.?(ops.owner, image);
    try decoder.close();
    try model.clean();
    try t.expectEqual(@as(usize, 0), budget.liveBytes());
    // Each failure is fresh: neither a preceding fence nor a preceding success
    // record may publish this output. Abort/release preserve pending GPU loans.
    for ([_]@TypeOf(state.mode){ .missing, .stale, .corrupt }) |mode| {
        model = .{ .provider = .amd, .next_va = @import("r4amd").native_va_start, .push_bytes = 256, .on_submit = inspect };
        state = .{ .mode = mode };
        decoder = .{ .ctx = .{ .base = base, .device = device, .budget = &budget, .clock = fixture.clock } };
        ops = decoder.ops();
        p = pic(seq, 0);
        const bad = try frame(ops, &p, -6);
        try t.expect(decoder.describe(bad) == null);
        ops.abort.?(ops.owner, bad);
        ops.release.?(ops.owner, bad);
        try decoder.close();
        try model.clean();
        try t.expectEqual(@as(usize, 0), budget.liveBytes());
    }
    model = .{ .provider = .amd, .next_va = @import("r4amd").native_va_start, .push_bytes = 256, .on_submit = inspect };
    state = .{};
    decoder = .{ .ctx = .{ .base = base, .device = device, .budget = &budget, .clock = fixture.clock } };
    ops = decoder.ops();
    p = pic(seq, 0);
    const ready = try frame(ops, &p, 0);
    ops.release.?(ops.owner, ready);
    try decoder.reap();
    model.queue_timeout = true;
    model.queue_released = false;
    const timed = try frame(ops, &p, -7);
    ops.abort.?(ops.owner, timed);
    ops.release.?(ops.owner, timed);
    const held = budget.liveBytes();
    try t.expect(held > 0);
    try t.expectError(error.Busy, decoder.close());
    try t.expectEqual(held, budget.liveBytes());
    model.queue_released = true;
    try decoder.close();
    try model.clean();
    try t.expectEqual(@as(usize, 0), budget.liveBytes());

    // Failed session setup still returns a partial image owner to the parser.
    model = .{ .provider = .amd, .next_va = @import("r4amd").native_va_start, .push_bytes = 256, .on_submit = inspect };
    state = .{};
    budget.limit = 3 * 65536;
    decoder = .{ .ctx = .{ .base = base, .device = device, .budget = &budget, .clock = fixture.clock } };
    ops = decoder.ops();
    p = pic(seq, 0);
    var partial: ?*anyopaque = null;
    try t.expectEqual(@as(c_int, 0), ops.allocate.?(ops.owner, &p.sequence, &partial));
    try t.expectEqual(@as(c_int, -4), ops.begin.?(ops.owner, partial, &p));
    ops.abort.?(ops.owner, partial);
    ops.release.?(ops.owner, partial);
    try decoder.close();
    try model.clean();
    try t.expectEqual(@as(usize, 0), budget.liveBytes());
    std.debug.print("AMD H264 owners: reference reorder, long-term slots, seek/resize/close leases, fresh feedback, timeout and partial setup: OK\n", .{});
}
