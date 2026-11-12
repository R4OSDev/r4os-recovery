//! One synchronous owner call per step, exact prefix and one outer deadline.
const std = @import("std");
const budget = @import("time_budget.zig");
const abi = @import("r4os_contract").abi;
pub const Mode = enum(u32) { read_exact = 0, write_all = 1 };
pub const Outcome = enum(u32) { pending = 0, complete = 1, would_block = 2, eof = 3, timed_out = 4, cancelled = 5, failed = 6, uncertain = 7, clock_failed = 8, invalid_progress = 9, closed = 10 };
pub const IoKind = enum(u32) { progress = 0, eof = 1, would_block = 2, timed_out = 3, closed = 4, failed = 5, uncertain = 6 };
pub const Ack = extern struct { bytes: u32 = 0, kind: u32 = 0, error_code: i32 = 0, reserved: u32 = 0 };
pub const Progress = extern struct { bytes: u64, total: u64, last_bytes: u32, outcome: u32, error_code: i32, flags: u32 };
pub const goal_met: u32 = 1;
pub const terminal: u32 = 2;
pub const in_call: u32 = 4;
pub const effect_uncertain: u32 = 8;
pub const Error = error{ InvalidState, InvalidMode, InvalidBuffer, InvalidLimit, Busy, LengthOverflow } || budget.Error;
pub const Clock = *const fn (?*anyopaque, *budget.ClockSample) callconv(.c) i32;
// A callback is synchronous: no pointer may remain borrowed after real return.
// An absolute budget copy is passed, never rebased per chunk/discovery phase.
pub const Read = *const fn (?*anyopaque, u64, [*]u8, u32, *const budget.DeadlineBudget) callconv(.c) Ack;
pub const Write = *const fn (?*anyopaque, u64, [*]const u8, u32, *const budget.DeadlineBudget) callconv(.c) Ack;
pub const Transfer = extern struct {
    total: u64,
    bytes: u64 = 0,
    deadline: budget.DeadlineBudget,
    mode: u32,
    outcome: u32 = 0,
    ended: u32 = 0,
    busy: u32 = 0,
    cancel_requested: u32 = 0,
    poll_used: u32 = 0,
    last_error: i32 = 0,
    last_bytes: u32 = 0,
    pub fn init(mode: Mode, total: u64, initial: budget.ClockSample, timeout: abi.R4Timeout) Error!Transfer {
        return initAbsolute(mode, total, try budget.DeadlineBudget.init(initial, timeout));
    }
    /// Retain an already existing outer deadline, including discovery time.
    pub fn initAbsolute(mode: Mode, total: u64, deadline: budget.DeadlineBudget) Error!Transfer {
        var check = deadline;
        _ = try check.remaining(.{ .identity = deadline.identity, .instant_ns = deadline.last_ns });
        return .{ .total = total, .deadline = deadline, .mode = @intFromEnum(mode), .outcome = if (total == 0) @intFromEnum(Outcome.complete) else 0, .ended = @intFromBool(total == 0) };
    }
    fn validate(self: *const Transfer) Error!void {
        if (self.mode > 1 or self.bytes > self.total or self.outcome > 10 or self.ended > 1 or self.busy > 1 or self.cancel_requested > 1 or self.poll_used > 1 or self.deadline.kind > 2 or self.deadline.reserved != 0) return error.InvalidState;
    }
    pub fn progress(self: *const Transfer) Error!Progress {
        try self.validate();
        return .{ .bytes = self.bytes, .total = self.total, .last_bytes = self.last_bytes, .outcome = self.outcome, .error_code = self.last_error, .flags = (if (self.bytes == self.total) goal_met else @as(u32, 0)) | (if (self.ended != 0) terminal else @as(u32, 0)) | (if (self.busy != 0) in_call else @as(u32, 0)) | (if (self.outcome == @intFromEnum(Outcome.uncertain) or self.outcome == @intFromEnum(Outcome.invalid_progress)) effect_uncertain else @as(u32, 0)) };
    }
    pub fn cancel(self: *Transfer) Error!Progress {
        try self.validate();
        if (self.ended != 0) return self.progress();
        self.cancel_requested = 1;
        // A reentrant stop is a request. It does not end an active callback
        // loan; the outer step consumes its real return before ending state.
        if (self.busy == 0) return self.finish(.cancelled, 0);
        return self.progress();
    }
    fn finish(self: *Transfer, outcome: Outcome, code: i32) Error!Progress {
        self.outcome = @intFromEnum(outcome);
        self.ended = @intFromBool(outcome != .pending and outcome != .would_block);
        self.last_error = code;
        self.busy = 0;
        return self.progress();
    }
    fn clockError(self: *Transfer, err: budget.Error) Error!Progress {
        return self.finish(.clock_failed, switch (err) {
            error.ClockChanged => -102,
            error.ClockRegressed => -103,
            error.ClockUnavailable => -101,
            else => -104,
        });
    }
    fn begin(self: *Transfer, expected: Mode, length: usize, limit: u32, stop: bool, clock: Clock, clock_context: ?*anyopaque) Error!?Progress {
        try self.validate();
        if (self.busy != 0) return error.Busy;
        if (self.mode != @intFromEnum(expected)) return error.InvalidMode;
        if (self.ended != 0) return try self.progress();
        self.last_bytes = 0;
        if (self.cancel_requested != 0 or stop) return try self.finish(.cancelled, 0);
        if (self.bytes == self.total) return try self.finish(.complete, 0);
        if (length == 0) return error.InvalidBuffer;
        if (limit == 0 or limit > std.math.maxInt(i32)) return error.InvalidLimit;
        self.busy = 1;
        var sample: budget.ClockSample = .{};
        const code = clock(clock_context, &sample);
        if (code != 0) return try self.finish(.clock_failed, code);
        const remaining = self.deadline.remaining(sample) catch |err| return try self.clockError(err);
        if (self.cancel_requested != 0) return try self.finish(.cancelled, 0);
        if (self.deadline.kind == 0) {
            if (self.poll_used != 0) {
                const p = try self.finish(.would_block, 0);
                self.ended = 1;
                return .{ .bytes = p.bytes, .total = p.total, .last_bytes = p.last_bytes, .outcome = p.outcome, .error_code = p.error_code, .flags = p.flags | terminal };
            }
            self.poll_used = 1;
        } else if (remaining.kind == 0) return try self.finish(.timed_out, 0);
        self.outcome = @intFromEnum(Outcome.pending);
        return null;
    }
    fn end(self: *Transfer, offered: u32, ack: Ack, clock: Clock, clock_context: ?*anyopaque) Error!Progress {
        // Callback has really returned. No deadline/cancel result is treated
        // as a stop acknowledgement for an external peer or hardware owner.
        if (ack.reserved != 0 or ack.kind > 6 or ack.bytes > offered) return self.finish(.invalid_progress, ack.error_code);
        self.bytes += ack.bytes; // bounded by offered <= total-bytes
        self.last_bytes = ack.bytes;
        if (ack.kind == @intFromEnum(IoKind.uncertain)) return self.finish(.uncertain, ack.error_code);
        var sample: budget.ClockSample = .{};
        const code = clock(clock_context, &sample);
        if (code != 0) return self.finish(.clock_failed, code);
        const remaining = self.deadline.remaining(sample) catch |err| return self.clockError(err);
        if (self.cancel_requested != 0) return self.finish(.cancelled, ack.error_code);
        if (self.deadline.kind == 1 and remaining.kind == 0) return self.finish(.timed_out, ack.error_code);
        const outcome: Outcome = switch (@as(IoKind, @enumFromInt(ack.kind))) {
            .progress => if (self.bytes == self.total) .complete else if (ack.bytes == 0) .would_block else .pending,
            .eof => if (self.mode == 1) .closed else if (self.bytes == self.total) .complete else .eof,
            .would_block => if (self.bytes == self.total) .complete else .would_block,
            .timed_out => .timed_out,
            .closed => .closed,
            .failed => .failed,
            .uncertain => unreachable,
        };
        var result = try self.finish(if (self.deadline.kind == 0 and outcome == .pending) .would_block else outcome, ack.error_code);
        if (self.deadline.kind == 0) {
            self.ended = 1; // Poll permits exactly one immediate owner step.
            result.flags |= terminal;
        }
        return result;
    }
    pub fn readStep(self: *Transfer, storage: []u8, limit: u32, stop: bool, clock: Clock, clock_context: ?*anyopaque, reader: Read, context: ?*anyopaque) Error!Progress {
        if (@addWithOverflow(@intFromPtr(storage.ptr), storage.len)[1] != 0) return error.LengthOverflow;
        if (try self.begin(.read_exact, storage.len, limit, stop, clock, clock_context)) |done| return done;
        defer self.busy = 0;
        const count: u32 = @intCast(@min(@as(u64, storage.len), @min(self.total - self.bytes, limit)));
        const snapshot = self.deadline;
        return self.end(count, reader(context, self.bytes, storage.ptr, count, &snapshot), clock, clock_context);
    }
    pub fn writeStep(self: *Transfer, data: []const u8, limit: u32, stop: bool, clock: Clock, clock_context: ?*anyopaque, writer: Write, context: ?*anyopaque) Error!Progress {
        if (@addWithOverflow(@intFromPtr(data.ptr), data.len)[1] != 0) return error.LengthOverflow;
        if (try self.begin(.write_all, data.len, limit, stop, clock, clock_context)) |done| return done;
        defer self.busy = 0;
        const count: u32 = @intCast(@min(@as(u64, data.len), @min(self.total - self.bytes, limit)));
        const snapshot = self.deadline;
        return self.end(count, writer(context, self.bytes, data.ptr, count, &snapshot), clock, clock_context);
    }
};

const Probe = struct {
    sample: budget.ClockSample = .{ .identity = .{ .source = 1, .generation = 1, .tick_hz = 1000 }, .instant_ns = 100 },
    advance: u64 = 0,
    calls: usize = 0,
    code: i32 = 0,
    next: Ack = .{ .bytes = 2 },
    transfer: ?*Transfer = null,
    observed_in_call: bool = false,
    fn clock(raw: ?*anyopaque, out: *budget.ClockSample) callconv(.c) i32 {
        const p: *@This() = @ptrCast(@alignCast(raw.?));
        out.* = p.sample;
        return p.code;
    }
    fn write(raw: ?*anyopaque, _: u64, _: [*]const u8, length: u32, snapshot: *const budget.DeadlineBudget) callconv(.c) Ack {
        const p: *@This() = @ptrCast(@alignCast(raw.?));
        p.calls += 1;
        if (snapshot.deadline_ns != 110 and snapshot.kind != 0 and snapshot.kind != 2) return .{ .kind = 6, .error_code = -90 };
        p.sample.instant_ns += p.advance;
        if (p.transfer) |t| {
            const stopped = t.cancel() catch unreachable;
            p.observed_in_call = stopped.flags & in_call != 0 and stopped.flags & terminal == 0;
        }
        var ack = p.next;
        if (ack.bytes <= length) return ack;
        ack.kind = 0;
        return ack;
    }
    fn read(raw: ?*anyopaque, offset: u64, data: [*]u8, length: u32, snapshot: *const budget.DeadlineBudget) callconv(.c) Ack {
        const ack = write(raw, offset, data, length, snapshot);
        if (ack.bytes <= length) @memset(data[0..ack.bytes], @truncate(offset + 65));
        return ack;
    }
};
test "stream owner one deadline exact prefixes zero progress EOF and no timer rebasing" {
    var p: Probe = .{};
    var t = try Transfer.init(.write_all, 6, p.sample, .{ .kind = 1, .nanoseconds = 10 });
    p.advance = 3;
    try std.testing.expectEqual(@as(u64, 2), (try t.writeStep("abcd", 4, false, Probe.clock, &p, Probe.write, &p)).bytes);
    p.next.bytes = 0;
    try std.testing.expectEqual(@intFromEnum(Outcome.would_block), (try t.writeStep("abcd", 4, false, Probe.clock, &p, Probe.write, &p)).outcome);
    p.next.bytes = 2;
    p.advance = 5;
    const expired = try t.writeStep("abcd", 4, false, Probe.clock, &p, Probe.write, &p);
    try std.testing.expectEqual(@intFromEnum(Outcome.timed_out), expired.outcome);
    try std.testing.expectEqual(@as(u64, 4), expired.bytes);
    _ = try t.writeStep("abcd", 4, false, Probe.clock, &p, Probe.write, &p);
    try std.testing.expectEqual(@as(usize, 3), p.calls);
    p = .{};
    t = try Transfer.init(.read_exact, 5, p.sample, .{ .kind = 1, .nanoseconds = 10 });
    p.next = .{ .bytes = 2, .kind = 1 };
    var output: [5]u8 = @splat(0);
    const eof = try t.readStep(&output, 5, false, Probe.clock, &p, Probe.read, &p);
    try std.testing.expectEqual(@intFromEnum(Outcome.eof), eof.outcome);
    try std.testing.expectEqualStrings("AA\x00\x00\x00", &output);
}
test "stream owner stop retains active loan until real return and unknown effects never replay" {
    var p: Probe = .{};
    var t = try Transfer.init(.write_all, 3, p.sample, .{ .kind = 1, .nanoseconds = 10 });
    p.transfer = &t;
    const stopped = try t.writeStep("abc", 3, false, Probe.clock, &p, Probe.write, &p);
    try std.testing.expect(p.observed_in_call);
    try std.testing.expectEqual(@intFromEnum(Outcome.cancelled), stopped.outcome);
    try std.testing.expectEqual(@as(u64, 2), stopped.bytes);
    try std.testing.expect(stopped.flags & in_call == 0);
    p = .{};
    t = try Transfer.init(.write_all, 3, p.sample, .{ .kind = 1, .nanoseconds = 10 });
    p.next = .{ .bytes = 1, .kind = 6, .error_code = -8 };
    const unknown = try t.writeStep("abc", 3, false, Probe.clock, &p, Probe.write, &p);
    try std.testing.expectEqual(@as(u64, 1), unknown.bytes);
    try std.testing.expect(unknown.flags & effect_uncertain != 0);
    _ = try t.writeStep("bc", 2, false, Probe.clock, &p, Probe.write, &p);
    try std.testing.expectEqual(@as(usize, 1), p.calls);
    p = .{};
    t = try Transfer.init(.write_all, 3, p.sample, .{ .kind = 1, .nanoseconds = 10 });
    p.next.bytes = 4;
    const invalid = try t.writeStep("abc", 3, false, Probe.clock, &p, Probe.write, &p);
    try std.testing.expectEqual(@as(u64, 0), invalid.bytes);
    try std.testing.expectEqual(@intFromEnum(Outcome.invalid_progress), invalid.outcome);
}
test "stream owner terminal clock epochs one poll zero length and wide cumulative range" {
    var p: Probe = .{};
    var t = try Transfer.init(.write_all, 9, p.sample, .{ .kind = 1, .nanoseconds = 10 });
    p.sample.identity.generation = 2;
    try std.testing.expectEqual(@intFromEnum(Outcome.clock_failed), (try t.writeStep("abc", 3, false, Probe.clock, &p, Probe.write, &p)).outcome);
    try std.testing.expectEqual(@as(usize, 0), p.calls);
    p = .{};
    t = try Transfer.init(.write_all, 9, p.sample, .{});
    _ = try t.writeStep("abc", 3, false, Probe.clock, &p, Probe.write, &p);
    _ = try t.writeStep("abc", 3, false, Probe.clock, &p, Probe.write, &p);
    try std.testing.expectEqual(@as(usize, 1), p.calls);
    p = .{};
    t = try Transfer.init(.read_exact, 0, p.sample, .{});
    var out: [1]u8 = undefined;
    try std.testing.expectEqual(@intFromEnum(Outcome.complete), (try t.readStep(&out, 1, false, Probe.clock, &p, Probe.read, &p)).outcome);
    try std.testing.expectEqual(@as(usize, 0), p.calls);
    t = try Transfer.init(.write_all, 0x1_0000_0002, p.sample, .{ .kind = 2 });
    t.bytes = 0x1_0000_0000;
    const wide = try t.writeStep("ab", 2, false, Probe.clock, &p, Probe.write, &p);
    try std.testing.expectEqual(@as(u64, 0x1_0000_0002), wide.bytes);
    try std.testing.expectEqual(@intFromEnum(Outcome.complete), wide.outcome);
}
