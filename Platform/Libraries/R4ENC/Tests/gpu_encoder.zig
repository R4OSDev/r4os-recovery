// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Real SDK dispatch and session; modeled BO/VA/engine completion, no NVENC
// firmware execution or claim of independently decoded hardware output.
const std = @import("std");
const t = std.testing;
const r = @import("r4os");
const a = r.abi;
const gpu = @import("gpu_resources");
const fixture = @import("gpu_model");
const encoder = @import("gpu_encoder");
const enc = @import("r4nv_encode");
const Budget = @import("native_allocation").Budget;
var expected: struct {
    index: u32 = 0,
    frame_num: u16 = 0,
    idr_id: u16 = 0,
    key: bool = true,
    previous_recon: u32 = 0,
    previous_coloc: u32 = 0,
    failure: enum { none, missing, corrupt, stale, bitstream } = .none,
    mapped: usize = 4,
} = .{};
fn put(bytes: []u8, offset: usize, value: u32) void { std.mem.writeInt(u32, bytes[offset..][0..4], value, .little); }
fn half(bytes: []u8, offset: usize, value: u16) void { std.mem.writeInt(u16, bytes[offset..][0..2], value, .little); }
fn word(bytes: []const u8, index: usize) u32 { return fixture.word(bytes, index * 4); }
fn inspect(words: []const u8) void {
    std.debug.assert(word(words, 1) == ((if (fixture.model.class_chip == 0x174) @as(u32, 0xc7b7) else 0xc9b7) | (31 << 16)));
    std.debug.assert(word(words, 3) == 1 and word(words, 40) == 0x5b03 and word(words, 41) == expected.index);
    // Optional hints are absent; UV shares the exact input base and uses the
    // validated relative offset in the picture. There are no dummy hint BOs.
    std.debug.assert(word(words, 45) == 0 and word(words, 53) == word(words, 55) and word(words, 55) == word(words, 56));
    const params = fixture.virtualBytes(@as(u64, word(words, 44)) << 8);
    const status = fixture.virtualBytes(@as(u64, word(words, 46)) << 8);
    const bitstream = fixture.virtualBytes(@as(u64, word(words, 47)) << 8);
    std.debug.assert((params[430] & 0x60) == 0 and (fixture.word(params, 652) & 0x3ff) == 0);
    std.debug.assert(std.mem.readInt(u16, params[380..382], .little) == expected.frame_num);
    std.debug.assert(std.mem.readInt(u16, params[384..386], .little) == expected.idr_id);
    std.debug.assert((fixture.word(params, 424) >> 2) & 3 == (if (expected.key) @as(u32, 3) else 0));
    std.debug.assert(word(words, 52) != expected.previous_recon and word(words, 51) != expected.previous_coloc);
    std.debug.assert(word(words, 6) == (if (expected.key) @as(u32, 0) else expected.previous_recon));
    std.debug.assert(word(words, 50) == (if (expected.key) @as(u32, 0) else expected.previous_coloc));
    std.debug.assert(fixture.model.loan_count == (if (expected.key) @as(usize, 8) else 10));
    // Four system BOs only: commands, parameters, status, compressed output.
    // The input, history, reconstructed references and coloc data have no map.
    var mapped: usize = 0;
    for (&fixture.model.bos) |*bo| if (bo.mapped) { mapped += 1; std.debug.assert(bo.descriptor.location == 0); };
    std.debug.assert(mapped == expected.mapped);
    for (status[0..enc.status_bytes]) |byte| std.debug.assert(byte == 0xff);
    if (expected.failure == .missing) return;
    @memset(status[0..enc.status_bytes], 0);
    put(status, 0, if (expected.failure == .stale) expected.index + 1 else expected.index);
    put(status, 4, if (expected.failure == .corrupt) 6 else 2);
    put(status, 8, 48); // One six-byte modeled VCL NAL.
    put(status, 36, 6); // Firmware returns the exclusive end.
    half(status, 16, if (expected.key) 3 else 0);
    half(status, 18, 1);
    half(status, 22, 26);
    half(status, 40, 16); //64x64 =16 macroblocks.
    half(status, 68, 26); half(status, 70, 26);
    put(status, 128, 0); put(status, 132, 6); put(status, 136, 16);
    bitstream[0..6].* = .{ 0, 0, 0, 1, if (expected.key) 0x65 else 0x41, 0x80 };
    if (expected.failure == .bitstream) bitstream[4] = 0;
    if (expected.failure == .none) {
        expected.previous_recon = word(words, 52);
        expected.previous_coloc = word(words, 51);
    }
}
pub fn run() !void {
    var state: fixture.Model = .{};
    fixture.model = &state;
    var raw: a.R4XStartContext = .{};
    var table: a.R4XStartR4Draw = .{};
    fixture.install(&table);
    var bundle: r.program.Bundle = .{ .raw = &raw, .draw = &table };
    const base = r.program.Context.initBundle(&bundle);
    const sequence: enc.Sequence = .{ .width = 64, .height = 64, .qp = 26, .fps_num = 30, .fps_den = 1 };
    var budget: Budget = .{ .limit = 16 * 1024 * 1024 };
    var output: [65536]u8 = undefined;
    for ([_]u32{ 0x174, 0x192 }) |chip| {
        state = .{ .engine = .encode, .class_chip = chip, .push_bytes = enc.commands.word_count * 4, .on_submit = &inspect };
        expected = .{};
        var session: encoder.Session = .{ .ctx = .{ .base = base, .device = try gpu.Device.queryFor(base, 9, .encode), .budget = &budget, .clock = fixture.clock } };
        var input: gpu.Resource = .{};
        try session.open(sequence, output.len, 3);
        try input.nv12(&session.ctx, 64, 64);
        // Initial IDR, two P pictures, periodic IDR, explicit IDR, abort/reset IDR.
        const frames = [_]struct { key: bool, frame_num: u16, idr: u16, force: bool = false }{
            .{ .key = true, .frame_num = 0, .idr = 0 }, .{ .key = false, .frame_num = 1, .idr = 1 },
            .{ .key = false, .frame_num = 2, .idr = 1 }, .{ .key = true, .frame_num = 0, .idr = 1 },
            .{ .key = true, .frame_num = 0, .idr = 2, .force = true },
        };
        for (frames, 0..) |frame, i| {
            expected.index = @intCast(i); expected.frame_num = frame.frame_num; expected.idr_id = frame.idr; expected.key = frame.key;
            const packet = try session.encodePrepared(&input, frame.force, &output);
            try t.expectEqual(frame.key, packet.key);
            try t.expectEqual(@as(usize, 6) + (if (frame.key) session.headers.length else 0), packet.bytes);
            if (frame.key) try t.expectEqualSlices(u8, session.headers.bytes(), output[0..session.headers.length]);
        }
        try session.reset();
        // Reset drops the DPB, so the next output may reuse either old slot.
        expected = .{ .index = 5, .idr_id = 3 };
        try t.expect((try session.encodePrepared(&input, false, &output)).key);
        try input.close();
        try session.close();
        try session.close();
        try t.expectEqual(@as(usize, 0), budget.liveBytes());
        try state.clean();
    }
    for ([_]@FieldType(@TypeOf(expected), "failure"){ .missing, .corrupt, .stale, .bitstream }) |failure| {
        state = .{ .engine = .encode, .push_bytes = enc.commands.word_count * 4, .on_submit = &inspect };
        expected = .{ .failure = failure };
        var session: encoder.Session = .{ .ctx = .{ .base = base, .device = try gpu.Device.queryFor(base, 9, .encode), .budget = &budget, .clock = fixture.clock } };
        var input: gpu.Resource = .{};
        try session.open(sequence, output.len, 3);
        try input.nv12(&session.ctx, 64, 64);
        @memset(&output, 0x7c);
        if (session.encodePrepared(&input, false, &output)) |_| return error.AcceptedBadStatus else |err| {
            try t.expect(err == error.MissingStatus or err == error.Encode or err == error.Bitstream);
        }
        try t.expect(session.failed and session.reference == null and session.picture_index == 0);
        try t.expect(std.mem.allEqual(u8, &output, 0x7c));
        try t.expectError(error.Stale, session.reset());
        try session.close(); try input.close();
        try t.expectEqual(@as(usize, 0), budget.liveBytes()); try state.clean();
    }
    // A logical queue timeout must preserve the source and every work BO until
    // the modeled physical release. No output or DPB update is permitted.
    state = .{ .engine = .encode, .push_bytes = enc.commands.word_count * 4, .queue_timeout = true, .on_submit = &inspect };
    expected = .{};
    var session: encoder.Session = .{ .ctx = .{ .base = base, .device = try gpu.Device.queryFor(base, 9, .encode), .budget = &budget, .clock = fixture.clock } };
    var input: gpu.Resource = .{};
    try session.open(sequence, output.len, 3); try input.nv12(&session.ctx, 64, 64);
    const held = budget.liveBytes();
    try t.expectError(error.Timeout, session.encodePrepared(&input, false, &output));
    try t.expect(session.reference == null and session.picture_index == 0);
    try t.expectError(error.Busy, session.close()); try t.expectError(error.Busy, input.close());
    try t.expectEqual(held, budget.liveBytes());
    state.queue_released = true;
    state.queue_close_result = a.gfx_queue_error_stale;
    state.retire_ready = false;
    try t.expectError(error.Busy, session.close());
    try t.expectEqual(held, budget.liveBytes());
    state.retire_ready = true;
    try session.close(); try input.close();
    try t.expectEqual(@as(usize, 0), budget.liveBytes()); try state.clean();
    // Failed setup retains all partial allocations in the stable session.
    state = .{ .engine = .encode };
    budget.limit = 3 * 65536;
    session = .{ .ctx = .{ .base = base, .device = try gpu.Device.queryFor(base, 9, .encode), .budget = &budget, .clock = fixture.clock } };
    try t.expectError(error.NoMemory, session.open(sequence, output.len, 3));
    try t.expect(session.failed and !session.ready and budget.liveBytes() != 0);
    try session.close();
    try t.expectEqual(@as(usize, 0), budget.liveBytes()); try state.clean();
    std.debug.print("NVENC session: Ampere/Ada IDR+P, DPB, abort, fresh status, bounded BOs and physical retirement: OK\n", .{});
    try backendChecks(base);
}

var graphics_calls: u32 = 0;
var encode_timeout = false;
fn inspectMixed(words: []const u8) void {
    const class = word(words, 1);
    if (class == 0xc797 or class == 0xc997) {
        graphics_calls += 1;
        std.debug.assert(fixture.model.loan_count == 5);
        return;
    }
    inspect(words);
    fixture.model.queue_timeout = encode_timeout;
}
fn backendChecks(base: r.program.Context) !void {
    const native_backend = @import("gpu_backend");
    const c = @import("binding");
    const input_owner = @import("encode_input");
    var state: fixture.Model = .{ .mixed_engines = true, .graphics = true, .push_bytes = 0, .on_submit = &inspectMixed };
    fixture.model = &state;
    const memory: r.gfx_buffers.Context = .{ .base = base };
    var budget: Budget = .{ .limit = 16 * 1024 * 1024 };
    var producer_budget: Budget = .{ .limit = 1024 * 1024 };
    var config = std.mem.zeroes(c.R4EncConfig);
    config.width = 64; config.height = 64; config.fps_num = 30; config.fps_den = 1; config.gop_frames = 30;
    config.max_packet_bytes = 65536; config.rate.qp = 26; config.rate.max_qp = 51;
    config.color.bit_depth = 8; config.color.range = 2;
    config.color.primaries = 1; config.color.transfer = 1; config.color.matrix = 1;
    const settings = try native_backend.Config.from(config);
    config.color.range = 1;
    try t.expectError(error.Unsupported, native_backend.Config.from(config));
    config.color.range = 2; config.rate.mode = 1;
    try t.expectError(error.Unsupported, native_backend.Config.from(config));
    state.graphics = false;
    try t.expectError(error.Unsupported, native_backend.Devices.query(base, 9));
    state.graphics = true;
    const devices = try native_backend.Devices.query(base, 9);
    var backend = native_backend.Backend.init(base, devices, &budget, fixture.clock, settings);
    try t.expectEqual(@as(usize, 0), budget.liveBytes());
    try backend.close(); // No accepted input => no BO or GPU queue was created.
    try state.clean();
    for ([_]bool{ false, true }) |timeout| {
        state = .{ .mixed_engines = true, .graphics = true, .push_bytes = 0, .on_submit = &inspectMixed };
        encode_timeout = timeout; graphics_calls = 0; expected = .{ .mapped = 7 };
        backend = native_backend.Backend.init(base, devices, &budget, fixture.clock, settings);
        var producer: gpu.Context = .{ .base = base, .device = devices.encode, .budget = &producer_budget, .clock = fixture.clock };
        var sources: [1]gpu.Resource = @splat(.{});
        try sources[0].nv12(&producer, 64, 64);
        var owner: input_owner.Input(c) = .{};
        try owner.admit(&memory, &budget, @import("gpu_input.zig").frameFor(&sources, 64, 64, false), 64, 64);
        var output: [65536]u8 = undefined;
        // The common deadline covers allocation, every GR slice and NVENC.
        const until: u64 = 4_001_000_000;
        if (timeout) {
            try t.expectError(error.Timeout, backend.encode(&owner, false, &output, until));
            try t.expectEqual(@as(u32, 2), graphics_calls);
            try t.expect(backend.failed and !backend.closed and backend.session.picture_index == 0);
            const held = budget.liveBytes();
            try t.expectError(error.Busy, backend.retireInput());
            try t.expectEqual(held, budget.liveBytes());
            state.queue_released = true;
            try backend.retireInput();
            try t.expect(backend.closed);
        } else {
            try t.expect((try backend.encode(&owner, false, &output, until)).key);
            try t.expectEqual(until, state.deadline_ns);
            try backend.retireInput();
            expected.index = 1; expected.frame_num = 1; expected.idr_id = 1; expected.key = false;
            try t.expect(!(try backend.encode(&owner, false, &output, until)).key);
            try backend.reset();
            expected = .{ .index = 2, .idr_id = 1, .mapped = 7 };
            try t.expect((try backend.encode(&owner, false, &output, until)).key);
            try t.expectEqual(@as(u32, 6), graphics_calls);
        }
        try backend.retireInput(); try owner.close(&memory); try backend.close();
        try sources[0].close(); try producer.close();
        try t.expectEqual(@as(usize, 0), budget.liveBytes());
        try t.expectEqual(@as(usize, 0), producer_budget.liveBytes());
        try state.clean();
    }
    encode_timeout = false;
    std.debug.print("NVENC worker backend: lazy startup, GR then encoder, shared deadline, reset, no idle work, encode-timeout retirement: OK\n", .{});
}
