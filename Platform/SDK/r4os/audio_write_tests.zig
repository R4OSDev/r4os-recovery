const std = @import("std");
const o = @import("audio_write.zig");
const pcm = @import("pcm_source.zig");
const a = o.abi;
const t = std.testing;
var now: u64 = 0;
var calls: u32 = 0;
var late: u32 = 0;
var ticks_seen: [64]u64 = @splat(0);
var delay: u64 = 3_000_000;
var requested: u32 = 1000;
var mode: u32 = 0;
var cancelling: ?*o.Writer = null;
var active_cancel: bool = false;
fn clock(out: *a.MonotonicClockInfo) callconv(.c) i32 {
    out.* = .{ .flags = a.monotonic_clock_flag_valid, .source = 1, .generation = if (mode == 6 and calls > 0) 42 else 41, .instant_ns = now, .frequency_hz = a.monotonic_clock_frequency_hz, .resolution_ns = 1, .event_backend = 1, .event_requested_hz = requested, .event_effective_hz = 999 };
    return 1;
}
fn call(channel: u32, op: u16, request: [*]const u8, length: u32, header: *a.ServiceMessageHeader, response: [*]u8, capacity: u32, ticks: u64) callconv(.c) i32 {
    std.debug.assert(channel == 7 and op == a.audio_service_op_write_stream and capacity == @sizeOf(a.AudioServiceStreamResult));
    var input: a.AudioServiceStreamWriteRequest = .{};
    @memcpy(std.mem.asBytes(&input), request[0..@sizeOf(a.AudioServiceStreamWriteRequest)]);
    std.debug.assert(input.stream_id == 42 and input.byte_count == length - @sizeOf(a.AudioServiceStreamWriteRequest) and input.byte_count % 4 == 0);
    if (now >= 10_000_000) late += 1;
    ticks_seen[calls] = ticks;
    calls += 1;
    now += delay;
    if (cancelling) |writer| {
        var p: o.Progress = undefined;
        std.debug.assert(writer.cancel(&p) == 0);
        active_cancel = p.io.flags & o.transfer.in_call != 0 and p.io.flags & o.transfer.terminal == 0;
    }
    if (mode == 3) return a.service_api_result_timeout;
    const count: u32 = if (mode == 1 or mode == 4) 0 else if (mode == 2) 3 else @min(input.byte_count, 4);
    var result: a.AudioServiceStreamResult = .{ .action = op, .stream_id = 42, .bytes = count, .result = if (mode == 1) a.service_api_result_busy else if (mode == 4) -90 else @intCast(count), .flags = 8 | 16 };
    header.* = .{ .op = op, .payload_len = @sizeOf(a.AudioServiceStreamResult) };
    @memcpy(response[0..@sizeOf(a.AudioServiceStreamResult)], std.mem.asBytes(&result));
    return @sizeOf(a.AudioServiceStreamResult);
}
fn reset() void {
    now = 0;
    calls = 0;
    late = 0;
    delay = 3_000_000;
    requested = 1000;
    mode = 0;
    cancelling = null;
    active_cancel = false;
}
const provider: o.Provider = .{ .call = &call, .monotonic = &clock, .service_handle = 7, .stream_id = 42, .frame_bytes = 4 };
fn init(data: []const u8, timeout: a.R4Timeout, writer: *o.Writer) !void {
    try t.expectEqual(@as(i32, 0), o.Writer.init(.{ .address = @intFromPtr(data.ptr), .length = data.len }, provider, timeout, writer));
}
test "audio write owner one absolute deadline actual AUDSVC short ACKs preserve complete frames" {
    reset();
    const data = [_]u8{0} ** 64;
    var writer: o.Writer = undefined;
    try init(&data, .{ .kind = a.timeout_kind_finite, .nanoseconds = 10_000_000 }, &writer);
    var p: o.Progress = undefined;
    try t.expectEqual(@as(i32, 0), writer.writeBounded(64, false, &p));
    try t.expectEqual(@as(u32, 4), calls);
    try t.expectEqual(@as(u32, 0), late);
    try t.expectEqual(@as(u64, 12_000_000), now);
    try t.expectEqual(@as(u64, 16), p.io.bytes);
    try t.expectEqual(@as(u64, 4), p.accepted_frames);
    try t.expectEqual(@intFromEnum(o.transfer.Outcome.timed_out), p.io.outcome);
    try t.expectEqualSlices(u64, &.{ 10, 7, 4, 1 }, ticks_seen[0..4]);
    try t.expectEqual(@as(u32, 24), p.last_service_flags);
    try t.expectEqual(@as(u32, 1), p.service_flags_valid);
    try t.expectEqual(@as(i32, 0), writer.writeOnce(false, &p));
    try t.expectEqual(@as(u32, 4), calls);
}
test "audio write owner Poll Forever requested ticks and one-call fairness" {
    const data = [_]u8{0} ** 12;
    var writer: o.Writer = undefined;
    var p: o.Progress = undefined;
    reset();
    try init(&data, .{}, &writer);
    try t.expectEqual(@as(i32, 0), writer.writeBounded(64, false, &p));
    try t.expectEqual(@as(u32, 1), calls);
    try t.expectEqual(@as(u64, 0), ticks_seen[0]);
    try t.expectEqual(@intFromEnum(o.transfer.Outcome.would_block), p.io.outcome);
    try t.expect(p.io.flags & o.transfer.terminal != 0);
    reset();
    try init(&data, .{ .kind = a.timeout_kind_forever }, &writer);
    try t.expectEqual(@as(i32, 0), writer.writeOnce(false, &p));
    try t.expectEqual(@as(u32, 1), calls);
    try t.expectEqual(@as(i32, 0), writer.writeBounded(64, false, &p));
    try t.expectEqual(@as(u32, 3), calls);
    try t.expectEqual(@intFromEnum(o.transfer.Outcome.complete), p.io.outcome);
    for (ticks_seen[0..3]) |ticks| try t.expectEqual(a.io_wait_forever, ticks);
    reset();
    requested = 333;
    try init(&data, .{ .kind = a.timeout_kind_finite, .nanoseconds = 10_000_000 }, &writer);
    try t.expectEqual(@as(i32, 0), writer.writeOnce(false, &p));
    try t.expectEqual(@as(u64, 4), ticks_seen[0]);
}
test "audio write owner Busy invalid ACK unknown effects negative reply and checked frame shape" {
    const data = [_]u8{0} ** 64;
    var writer: o.Writer = undefined;
    var p: o.Progress = undefined;
    for ([_]u32{ 1, 2, 3, 4 }) |kind| {
        reset();
        mode = kind;
        try init(&data, .{ .kind = a.timeout_kind_forever }, &writer);
        try t.expectEqual(@as(i32, 0), writer.writeBounded(64, false, &p));
        try t.expectEqual(@as(u32, 1), calls);
        try t.expectEqual(@as(u64, 0), p.io.bytes);
        try t.expectEqual(@as(u32, if (kind == 1) 2 else if (kind == 4) 6 else 7), p.io.outcome);
        try t.expectEqual(@as(u32, if (kind == 1 or kind == 4) 1 else 0), p.service_flags_valid);
    }
    reset();
    try t.expectEqual(o.invalid_frame, o.Writer.init(.{ .address = @intFromPtr(&data), .length = 3 }, provider, .{}, &writer));
    try t.expectEqual(@as(u32, 0), calls);
    try t.expectEqual(o.invalid_buffer, o.Writer.init(.{ .address = @intFromPtr(&writer), .length = 4 }, provider, .{}, &writer));
    try init(&data, .{}, &writer);
    try t.expectEqual(@as(i32, -4), writer.writeBounded(0, false, &p));
    try t.expectEqual(@as(u32, 0), calls);
}
test "audio write owner cancellation and changed clock retain actual ACK and real loan" {
    const data = [_]u8{0} ** 64;
    var writer: o.Writer = undefined;
    var p: o.Progress = undefined;
    for ([_]u32{ 5, 6 }) |kind| {
        reset();
        mode = kind;
        try init(&data, .{ .kind = a.timeout_kind_forever }, &writer);
        if (kind == 5) cancelling = &writer;
        try t.expectEqual(@as(i32, 0), writer.writeBounded(64, false, &p));
        try t.expectEqual(@as(u32, 1), calls);
        try t.expectEqual(@as(u64, 4), p.io.bytes);
        try t.expectEqual(@as(u32, if (kind == 5) 5 else 8), p.io.outcome);
        try t.expect(p.io.flags & o.transfer.in_call == 0 and p.io.flags & o.transfer.terminal != 0);
        if (kind == 5) try t.expect(active_cancel);
    }
}
fn sample(ns: u64) o.budget.ClockSample {
    return .{ .identity = .{ .source = 1, .generation = 17, .tick_hz = 1000 }, .instant_ns = ns };
}
test "audio write owner rational source frames no long-gap credit and source-only finish" {
    for ([_]u32{ 8000, 11025, 44100, 48000, 96000 }) |rate| {
        var p = try pcm.Pacer.init(rate, 4, rate * 160 / 1000, sample(0));
        var independent: u128 = 0;
        var count: u64 = 0;
        for (0..140) |i| {
            const frames: u64 = ([_]u32{ 1, 17, 127, 960, 4096, 960, 960 })[i % 7];
            const start: u64 = @as(u64, @intCast(i)) * 3_000_000 + if (i >= 12) @as(u64, 500_000_000) else 0;
            independent = @max(independent, @as(u128, start) * rate) + frames * @as(u128, 1_000_000_000);
            count += frames;
            const d = try p.accepted(frames * 4, sample(start));
            try t.expectEqual(independent, @as(u128, p.end_hi) << 64 | p.end_lo);
            try t.expectEqual(count, d.accepted_frames);
            const exact_ceil = independent / rate + @intFromBool(independent % rate != 0);
            try t.expectEqual(@as(u64, @intCast(exact_ceil)), d.source_end_ns);
            const finish = try p.deadline(sample(start), true);
            try t.expectEqual(finish.source_end_ns, finish.due_ns);
            try t.expect(finish.wait_ns >= d.wait_ns);
        }
    }
}
test "audio write owner source zero alignment overflow pause resume reset and clock errors atomic" {
    var p = try pcm.Pacer.init(48000, 4, 7680, sample(100));
    try t.expectEqual(@as(u64, 0), (try p.accepted(0, sample(100))).accepted_frames);
    try t.expectEqual(@as(u32, 0), p.flags);
    _ = try p.accepted(3840, sample(100));
    const before = p;
    try t.expectError(error.InvalidFrame, p.accepted(3, sample(100)));
    try t.expectEqualDeep(before, p);
    var changed = sample(100);
    changed.identity.generation += 1;
    try t.expectError(error.ClockChanged, p.deadline(changed, true));
    try t.expectError(error.ClockRegressed, p.accepted(4, sample(99)));
    try t.expectEqualDeep(before, p);
    try p.pause(sample(200));
    try t.expectEqual(@as(u64, 960), p.accepted_frames);
    try t.expectEqual(@as(u64, 0), (try p.deadline(sample(200), true)).wait_ns);
    const paused = p;
    try t.expectError(error.Paused, p.accepted(4, sample(200)));
    try t.expectEqualDeep(paused, p);
    try p.resumeSource(sample(1_000_000_000));
    const next = try p.accepted(4, sample(1_000_000_000));
    try t.expectEqual(@as(u64, 1_000_020_834), next.source_end_ns);
    try p.reset(44100, 2, 0, sample(0));
    try t.expectEqual(@as(u64, 0), p.accepted_frames);
    const reset_value = p;
    try t.expectError(error.InvalidRate, p.reset(0, 4, 0, sample(0)));
    try t.expectEqualDeep(reset_value, p);
    p.accepted_frames = std.math.maxInt(u64);
    const full = p;
    try t.expectError(error.BudgetOverflow, p.accepted(2, sample(0)));
    try t.expectEqualDeep(full, p);
    try p.reset(48000, 4, 0, sample(std.math.maxInt(u64)));
    const end = p;
    try t.expectError(error.BudgetOverflow, p.accepted(4, sample(std.math.maxInt(u64))));
    try t.expectEqualDeep(end, p);
}
