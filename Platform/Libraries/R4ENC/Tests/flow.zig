const std = @import("std");
const t = std.testing;
const c = @import("binding");
const Flow = @import("encode_flow").Flow(c);

pub fn run() !void {
    var f = try Flow.init(2, 1);
    const a = try f.reserve(1);
    f.commit(a);
    const b = try f.reserve(1);
    f.commit(b);
    try t.expectError(error.Busy, f.reserve(1));
    const first = f.take().?;
    try t.expect(first.force_idr and first.input == a);
    f.finish(first, 80, c.packet_key | c.packet_config, c.ok);
    const output = (try f.receive()).?;
    const token = f.outputs[output].token;
    try t.expect(f.take() == null); // Slow output owns the sole bitstream slot.
    try f.request(1, c.control_drain);
    f.progress(true, false);
    try t.expectEqual(@as(u64, 0), f.completed);
    try f.release(token, 1);
    const second = f.take().?;
    try t.expect(!second.force_idr and second.input == b);
    try f.release(token, 1); // Retry cannot overwrite the new in-flight output.
    try t.expectEqual(.writing, f.outputs[second.output].state);
    f.finish(second, 12, 0, c.ok);
    const last = (try f.receive()).?;
    const old_token = f.outputs[last].token;
    f.progress(true, false);
    try t.expectEqual(c.phase_drained, f.phase);
    try t.expectEqual(@as(u64, 1), f.completed);
    try f.request(2, c.control_abort);
    f.progress(true, false);
    try t.expectEqual(@as(u64, 2), f.generation);
    try t.expectEqual(@as(u32, 1), f.leased());
    try f.request(2, c.control_abort);
    f.progress(true, false);
    try t.expectEqual(@as(u64, 2), f.generation);
    try t.expectError(error.Stale, f.reserve(1));
    try f.release(old_token, 1); // Old-generation lease survives abort.
    const next = try f.reserve(2);
    f.commit(next);
    const active = f.take().?;
    try t.expect(active.force_idr);
    try f.request(3, c.control_abort);
    f.progress(false, false);
    try t.expectEqual(@as(u64, 2), f.generation);
    try t.expectEqual(@as(u64, 3), f.pending);
    // Engine/map retirement, not cancellation admission, permits this ACK.
    f.finish(active, 0, 0, c.error_device_lost);
    f.progress(true, false);
    try t.expectEqual(@as(u64, 3), f.generation);
    try t.expect((try f.receive()) == null);
    const final = try f.reserve(3);
    f.commit(final);
    f.finish(f.take().?, 88, c.packet_key, c.ok);
    const held = (try f.receive()).?;
    const held_token = f.outputs[held].token;
    try f.request(4, c.control_close);
    f.progress(true, true);
    try t.expectEqual(c.phase_closing, f.phase);
    try f.release(held_token, 3);
    f.progress(true, true);
    try t.expectEqual(c.phase_closed, f.phase);
    try t.expectEqual(@as(u64, 4), f.completed);

    // Stop stays usable even while a slow producer/consumer stalls Drain.
    var stop = try Flow.init(1, 1);
    const queued = try stop.reserve(1);
    stop.commit(queued);
    const running = stop.take().?;
    try stop.request(1, c.control_drain);
    try stop.request(2, c.control_abort);
    try t.expectError(error.Cancelled, stop.request(1, c.control_drain));
    try stop.request(3, c.control_close);
    try t.expectError(error.Cancelled, stop.request(2, c.control_abort));
    try t.expectError(error.Stale, stop.request(1, c.control_drain));
    stop.progress(false, false);
    try t.expectEqual(@as(u64, 0), stop.completed);
    stop.finish(running, 0, 0, c.error_cancelled);
    stop.progress(true, true);
    try t.expectEqual(c.phase_closed, stop.phase);
    try t.expectEqual(@as(u64, 1), stop.generation);
}
