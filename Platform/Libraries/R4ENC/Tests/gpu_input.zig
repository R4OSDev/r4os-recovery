// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Production Input/GR preparer with actual SDK dispatch. The model inspects
// emitted work/ownership; it does not execute shaders or encode pixels.
const std = @import("std");
const t = std.testing;
const r = @import("r4os");
const a = r.abi;
const c = @import("binding");
const gpu = @import("gpu_resources");
const fixture = @import("gpu_model");
const encoder = @import("gpu_encoder");
const prepare = @import("gpu_input");
const input = @import("encode_input");
const Budget = @import("native_allocation").Budget;
var expected: struct {
    preparer: *prepare.Preparer,
    width: u32,
    height: u32,
    count: usize,
    mapped: usize,
    calls: u32 = 0,
    planes: u32 = 0,
} = undefined;
fn inspect(words: []const u8) void {
    const prep = expected.preparer;
    std.debug.assert(fixture.word(words, 4) == prep.ctx.device.class and words.len <= 4052);
    const bytes = fixture.virtualBytes(prep.work[1].address);
    const plane = fixture.word(bytes, 260);
    std.debug.assert(fixture.word(bytes, 256) == (if (expected.count == 2) @as(u32, 1) else 3) and plane < 2);
    std.debug.assert(fixture.word(bytes, 264) == prep.target.descriptor.plane_pitches[plane] and
        fixture.word(bytes, 268) == expected.width and fixture.word(bytes, 272) == expected.height);
    if (expected.width == 638 and plane == 0) std.debug.assert(fixture.word(bytes, 1280 + 268) == 638 and
        fixture.word(bytes, 1280 + 272) == 382); // Luma slices share a submit.
    expected.calls += 1;
    expected.planes |= @as(u32, 1) << @intCast(plane);
    var mapped: usize = 0;
    var sources: usize = 0;
    for (&fixture.model.bos) |*bo| if (bo.mapped) { mapped += 1; };
    for (&prep.sources) |*source| if (source.ready) {
        sources += 1;
        std.debug.assert(source.borrowed and source.charged == 0 and source.mapping.lease.id == 0);
    };
    std.debug.assert(mapped == expected.mapped and fixture.model.loan_count == 4 + sources);
    std.debug.assert(prep.destination.borrowed and prep.destination.charged == 0 and
        std.meta.eql(prep.destination.backing.buffer, prep.target.backing.buffer) and
        prep.destination.address != prep.target.address);
    var writes: usize = 0;
    for (fixture.model.loans[0..fixture.model.loan_count]) |loan| if (loan.access != 0) {
        writes += 1;
        std.debug.assert(loan.access == 1 and std.meta.eql(loan.binding, prep.destination.binding));
    };
    std.debug.assert(writes == 1);
}
pub fn frameFor(source: []const gpu.Resource, width: u32, height: u32, planar: bool) c.R4EncFrame {
    var frame = std.mem.zeroes(c.R4EncFrame);
    frame.version = 1; frame.size = @sizeOf(c.R4EncFrame); frame.stream_generation = 1;
    frame.format = if (planar) c.format_yuv420p else c.format_nv12;
    frame.plane_count = if (planar) 3 else 2;
    const planes = [_]*c.R4EncPlane{ &frame.plane0, &frame.plane1, &frame.plane2 };
    for (planes[0..frame.plane_count], 0..) |plane, p| {
        const bo = &source[if (planar) p else 0];
        plane.* = .{ .buffer = @bitCast(bo.backing.buffer), .reference = @bitCast(bo.backing.reference),
            .offset = if (planar) 0 else bo.descriptor.plane_offsets[p],
            .pitch = if (planar) std.mem.alignForward(u64, if (p == 0) width else width / 2, 64) else bo.descriptor.plane_pitches[p],
            .row_bytes = if (planar and p != 0) width / 2 else width, .rows = if (p == 0) height else height / 2, .reserved = 0 };
    }
    return frame;
}
pub fn run() !void {
    var state: fixture.Model = .{};
    fixture.model = &state;
    var raw: a.R4XStartContext = .{};
    var table: a.R4XStartR4Draw = .{};
    fixture.install(&table);
    var bundle: r.program.Bundle = .{ .raw = &raw, .draw = &table };
    const base = r.program.Context.initBundle(&bundle);
    const memory: r.gfx_buffers.Context = .{ .base = base };
    var budget: Budget = .{ .limit = 16 * 1024 * 1024 };
    var producer_budget: Budget = .{ .limit = 4 * 1024 * 1024 };
    // Native NV12 retains its padded TIC extent64x48; I420 uses three linear
    // retained BOs. Larger Ada input also exercises bounded scissor slices.
    for (0..3) |case| {
        state = .{ .graphics = true, .engine = .graphics, .class_chip = if (case == 2) 0x192 else 0x174,
            .push_bytes = 0, .on_submit = &inspect };
        const width: u32 = if (case == 2) 638 else 62;
        const height: u32 = if (case == 2) 382 else 46;
        const planar = case == 1;
        var session: encoder.Session = .{ .ctx = .{ .base = base, .device = try gpu.Device.queryFor(base, 9, .encode), .budget = &budget, .clock = fixture.clock } };
        try session.open(.{ .width = width, .height = height, .qp = 26, .fps_num = 30, .fps_den = 1 }, 65536, 30);
        var prep: prepare.Preparer = .{ .ctx = .{ .base = base, .device = try gpu.Device.queryFor(base, 9, .graphics), .budget = &budget, .clock = fixture.clock } };
        var producer: gpu.Context = .{ .base = base, .device = session.ctx.device, .budget = &producer_budget, .clock = fixture.clock };
        var sources: [3]gpu.Resource = @splat(.{});
        if (planar) {
            for (&sources) |*source| try source.system(&producer, 65536);
        } else try sources[0].nv12(&producer, std.mem.alignForward(u32, width, 16), std.mem.alignForward(u32, height, 16));
        var owner: input.Input(c) = .{};
        try owner.admit(&memory, &budget, frameFor(&sources, width, height, planar), width, height);
        try prep.open(&session);
        expected = .{ .preparer = &prep, .width = width, .height = height, .count = if (planar) 3 else 2,
            .mapped = if (planar) 10 else 7 };
        const held = budget.liveBytes();
        // Engine completion and the subsequent input-VA retirement are
        // distinct acknowledgements. A pending unmap must be awaited inside
        // this worker preparation, without resubmitting either plane.
        state.retire_ready = false;
        const prepared = try prep.prepare(&owner);
        try t.expect(state.retire_ready and !prep.failed);
        try t.expect(prepared == &prep.target and prepared.owner == &session.ctx);
        try t.expectEqual(@as(u32, 3), expected.planes);
        try t.expectEqual(@as(u32, 2), expected.calls);
        try t.expectEqual(held, budget.liveBytes());
        for (&prep.sources) |*source| try t.expect(source.owner == null);
        // A second frame reuses only completed packet/shader/target storage.
        _ = try prep.prepare(&owner);
        try t.expectEqual(@as(u32, 4), expected.calls);
        try owner.close(&memory);
        var alias: input.Input(c) = .{};
        if (case == 0) {
            var alias_frame = frameFor(&sources, width, height, false);
            for ([_]*c.R4EncPlane{ &alias_frame.plane0, &alias_frame.plane1 }, 0..) |plane, p| {
                plane.buffer = @bitCast(prep.target.backing.buffer);
                plane.reference = @bitCast(prep.target.backing.reference);
                plane.pitch = prep.target.descriptor.plane_pitches[p];
                plane.offset = prep.target.descriptor.plane_offsets[p];
            }
            try alias.admit(&memory, &budget, alias_frame, width, height);
            try t.expectError(error.Invalid, prep.prepare(&alias));
            try t.expectEqual(@as(u32, 4), expected.calls);
        }
        try prep.close(); try prep.close(); try session.close();
        try alias.close(&memory);
        for (&sources) |*source| try source.close();
        try producer.close();
        try t.expectEqual(@as(usize, 0), budget.liveBytes());
        try t.expectEqual(@as(usize, 0), producer_budget.liveBytes());
        try state.clean();
    }
    // Timeout: source VA/ref and prepared destination cannot be retired just
    // because the CPU wait ended. No ready input is returned to NVENC.
    state = .{ .graphics = true, .engine = .graphics, .push_bytes = 0, .queue_timeout = true, .on_submit = &inspect };
    var session: encoder.Session = .{ .ctx = .{ .base = base, .device = try gpu.Device.queryFor(base, 9, .encode), .budget = &budget, .clock = fixture.clock } };
    try session.open(.{ .width = 62, .height = 46, .qp = 26, .fps_num = 30, .fps_den = 1 }, 65536, 30);
    var prep: prepare.Preparer = .{ .ctx = .{ .base = base, .device = try gpu.Device.queryFor(base, 9, .graphics), .budget = &budget, .clock = fixture.clock } };
    var producer: gpu.Context = .{ .base = base, .device = session.ctx.device, .budget = &producer_budget, .clock = fixture.clock };
    var sources: [1]gpu.Resource = @splat(.{});
    try sources[0].nv12(&producer, 64, 48);
    var owner: input.Input(c) = .{};
    try owner.admit(&memory, &budget, frameFor(&sources, 62, 46, false), 62, 46);
    try prep.open(&session);
    expected = .{ .preparer = &prep, .width = 62, .height = 46, .count = 2, .mapped = 7 };
    const held = budget.liveBytes();
    try t.expectError(error.Timeout, prep.prepare(&owner));
    try t.expect(prep.failed and expected.calls == 1 and session.picture_index == 0);
    try t.expectError(error.Busy, prep.close());
    try t.expectEqual(held, budget.liveBytes());
    state.queue_released = true;
    state.retire_ready = false;
    try t.expectError(error.Busy, prep.close());
    try t.expectEqual(held, budget.liveBytes());
    state.retire_ready = true;
    try prep.close(); try owner.close(&memory); try sources[0].close(); try producer.close(); try session.close();
    try t.expectEqual(@as(usize, 0), budget.liveBytes()); try state.clean();
    std.debug.print("NVENC input: retained NV12/I420, padded texture extent, bounded GR work, no pixel CPU maps, timeout retirement: OK\n", .{});
}
