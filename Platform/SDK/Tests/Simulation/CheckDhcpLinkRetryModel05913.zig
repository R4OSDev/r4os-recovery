const std = @import("std");
const runtime = @import("dhcp_runtime");

const base: u64 = 250;
const maximum: u64 = 4000;

fn input(now: u64, desired: bool, present: bool, up: bool, bound: bool) runtime.Input {
    return .{
        .now = now,
        .desired_dhcp = desired,
        .adapter_present = present,
        .link_up = up,
        .lease_bound = bound,
    };
}

test "boot link down and late R4D link produce exactly one acquire" {
    var c: runtime.Coordinator = .{};
    try std.testing.expectEqual(runtime.Action.none, c.observe(input(0, true, false, false, false)));
    try std.testing.expectEqual(runtime.State.wait_adapter, c.state);
    try std.testing.expectEqual(@as(u32, 1), c.link_generation);

    try std.testing.expectEqual(runtime.Action.none, c.observe(input(10, true, true, false, false)));
    try std.testing.expectEqual(runtime.State.wait_link, c.state);
    try std.testing.expectEqual(@as(u32, 1), c.link_generation);

    try std.testing.expectEqual(runtime.Action.acquire, c.observe(input(20, true, true, true, false)));
    try std.testing.expectEqual(@as(u32, 2), c.link_generation);
    try std.testing.expect(c.startOperation(20, .acquire));
    try std.testing.expect(!c.startOperation(20, .acquire));
    try std.testing.expectEqual(@as(u64, 1), c.starts);
    c.finishOperation(25, true, false, base, maximum);
    try std.testing.expectEqual(runtime.State.bound, c.state);
    try std.testing.expectEqual(@as(u64, 1), c.starts);
}

test "offer and ACK failures use capped exponential backoff without parallel acquire" {
    var c: runtime.Coordinator = .{};
    var now: u64 = 0;
    const expected = [_]u64{ 250, 500, 1000, 2000, 4000, 4000, 4000 };
    for (expected, 0..) |delay, round| {
        try std.testing.expectEqual(runtime.Action.acquire, c.observe(input(now, true, true, true, false)));
        try std.testing.expect(c.startOperation(now, .acquire));
        try std.testing.expect(!c.startOperation(now, .acquire));
        c.finishOperation(now, false, (round & 1) == 0, base, maximum);
        try std.testing.expectEqual(now + delay, c.next_retry_tick);
        try std.testing.expectEqual(runtime.Action.none, c.observe(input(now + delay - 1, true, true, true, false)));
        now += delay;
    }
    try std.testing.expectEqual(@as(u8, expected.len), c.retry_round);
    try std.testing.expectEqual(@as(u64, expected.len), c.starts);
    try std.testing.expect(c.last_timeout_tick != 0);
}

test "link loss cancels one operation clears a lease and recovers on a new generation" {
    var c: runtime.Coordinator = .{};
    try std.testing.expectEqual(runtime.Action.acquire, c.observe(input(1, true, true, true, false)));
    try std.testing.expect(c.startOperation(1, .acquire));
    const active_generation = c.operation_generation;

    try std.testing.expectEqual(runtime.Action.none, c.observe(input(2, true, true, false, false)));
    try std.testing.expect(c.cancel(2, true));
    try std.testing.expect(c.operation_generation != active_generation);
    try std.testing.expectEqual(runtime.State.lease_lost, c.state);
    try std.testing.expectEqual(@as(u64, 1), c.cancels);

    try std.testing.expectEqual(runtime.Action.clear_lease, c.observe(input(3, true, true, false, true)));
    try std.testing.expectEqual(runtime.Action.acquire, c.observe(input(4, true, true, true, false)));
    try std.testing.expectEqual(@as(u32, 3), c.link_generation);
    try std.testing.expect(c.startOperation(4, .acquire));
    c.finishOperation(5, true, false, base, maximum);
    try std.testing.expectEqual(runtime.State.bound, c.state);
    try std.testing.expectEqual(@as(u64, 1), c.recoveries);
}

test "static configuration stays separate and can return to DHCP after late link" {
    var c: runtime.Coordinator = .{};
    try std.testing.expectEqual(runtime.Action.none, c.observe(input(1, false, true, true, false)));
    try std.testing.expectEqual(runtime.State.static, c.state);
    try std.testing.expectEqual(runtime.Action.none, c.observe(input(2, false, true, false, false)));
    try std.testing.expectEqual(runtime.State.static, c.state);

    try std.testing.expectEqual(runtime.Action.none, c.observe(input(3, true, true, false, false)));
    try std.testing.expectEqual(runtime.State.wait_link, c.state);
    try std.testing.expectEqual(runtime.Action.acquire, c.observe(input(4, true, true, true, false)));
    try std.testing.expect(c.startOperation(4, .acquire));
    c.finishOperation(5, true, false, base, maximum);
    try std.testing.expectEqual(runtime.State.bound, c.state);
}

test "renew rebind and expiration actions are deterministic" {
    var c: runtime.Coordinator = .{};
    _ = c.observe(input(1, true, true, true, false));
    try std.testing.expect(c.startOperation(1, .acquire));
    c.finishOperation(2, true, false, base, maximum);

    var renew = input(10, true, true, true, true);
    renew.renew_due = true;
    try std.testing.expectEqual(runtime.Action.renew, c.observe(renew));
    try std.testing.expect(c.startOperation(10, .renew));
    c.finishOperation(11, false, true, base, maximum);
    try std.testing.expectEqual(runtime.Action.none, c.observe(renew));

    renew.now = c.next_retry_tick;
    renew.rebind_due = true;
    try std.testing.expectEqual(runtime.Action.rebind, c.observe(renew));
    try std.testing.expect(c.startOperation(renew.now, .rebind));
    c.finishOperation(renew.now + 1, true, false, base, maximum);

    var expired = renew;
    expired.now += 2;
    expired.lease_expired = true;
    try std.testing.expectEqual(runtime.Action.clear_lease, c.observe(expired));
    try std.testing.expectEqual(runtime.State.lease_lost, c.state);
}

test "10000 injected link flaps never admit two active operations" {
    var c: runtime.Coordinator = .{};
    var now: u64 = 1;
    var active: u32 = 0;
    var peak: u32 = 0;
    var cycle: usize = 0;
    while (cycle < 10_000) : (cycle += 1) {
        const up = (cycle & 1) == 0;
        const action = c.observe(input(now, true, true, up, false));
        if (!up) {
            if (c.cancel(now, true)) active -= 1;
        } else if (action == .acquire) {
            try std.testing.expect(c.startOperation(now, .acquire));
            active += 1;
            peak = @max(peak, active);
            c.finishOperation(now, false, false, 1, 1);
            active -= 1;
        }
        try std.testing.expect(active <= 1);
        now += 1;
    }
    try std.testing.expectEqual(@as(u32, 1), peak);
    try std.testing.expect(c.link_generation >= 10_000);
}
