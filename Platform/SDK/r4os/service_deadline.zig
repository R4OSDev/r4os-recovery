const std = @import("std");
const abi = @import("r4os_contract").abi;
const time_contract = @import("time_contract.zig");

pub const footer_size: usize = @sizeOf(abi.ServiceDeadlineFooter);
pub const forever_tick: u64 = std.math.maxInt(u64);

pub const RequestView = struct {
    payload: []const u8,
    deadline_tick: ?u64 = null,
};

pub fn deadlineFromTimeout(timeout: time_contract.Timeout, now_tick: u64, monotonic_hz: u32) time_contract.Error!u64 {
    const wait_ticks = try time_contract.timeoutToTicks(timeout, monotonic_hz);
    if (wait_ticks == abi.io_wait_forever) return forever_tick;
    return now_tick +| wait_ticks;
}

pub fn remainingTimeout(deadline_tick: u64, now_tick: u64, monotonic_hz: u32) time_contract.Timeout {
    if (deadline_tick == forever_tick) return time_contract.timeoutForever();
    if (deadline_tick <= now_tick) return time_contract.timeoutPoll();
    const duration = time_contract.durationFromTicks(deadline_tick - now_tick, monotonic_hz) catch
        return time_contract.timeoutPoll();
    return time_contract.timeoutFinite(duration);
}

pub fn append(out: []u8, payload: []const u8, deadline_tick: u64) ?[]const u8 {
    if (payload.len > out.len or footer_size > out.len - payload.len) return null;
    if (payload.len > std.math.maxInt(u32)) return null;
    if (payload.len != 0) @memcpy(out[0..payload.len], payload);
    var footer = abi.ServiceDeadlineFooter{ .payload_len = @intCast(payload.len), .deadline_tick = deadline_tick };
    @memcpy(out[payload.len .. payload.len + footer_size], std.mem.asBytes(&footer));
    return out[0 .. payload.len + footer_size];
}

pub fn split(request: []const u8) RequestView {
    if (request.len < footer_size) return .{ .payload = request };
    var footer: abi.ServiceDeadlineFooter = undefined;
    @memcpy(std.mem.asBytes(&footer), request[request.len - footer_size ..]);
    const expected = abi.ServiceDeadlineFooter{};
    if (footer.magic != expected.magic or footer.version != expected.version or footer.size != footer_size or
        footer.payload_len != @as(u32, @intCast(request.len - footer_size)) or footer.reserved0 != 0)
    {
        return .{ .payload = request };
    }
    return .{
        .payload = request[0 .. request.len - footer_size],
        .deadline_tick = footer.deadline_tick,
    };
}

test "service deadline suffix preserves payload and absolute budget" {
    const finite = try deadlineFromTimeout(
        time_contract.timeoutFinite(time_contract.durationFromNanoseconds(2_000_000_000)),
        100,
        10,
    );
    try std.testing.expectEqual(@as(u64, 120), finite);

    var encoded: [64]u8 = undefined;
    const message = append(encoded[0..], "payload", finite) orelse return error.TestUnexpectedResult;
    const decoded = split(message);
    try std.testing.expectEqualStrings("payload", decoded.payload);
    try std.testing.expectEqual(finite, decoded.deadline_tick.?);

    const remaining = remainingTimeout(finite, 115, 10);
    try std.testing.expectEqual(abi.timeout_kind_finite, remaining.kind);
    try std.testing.expectEqual(@as(u64, 500_000_000), remaining.nanoseconds);
    try std.testing.expectEqual(abi.timeout_kind_poll, remainingTimeout(finite, finite, 10).kind);
}

test "service deadline suffix supports forever and ignores legacy payloads" {
    try std.testing.expectEqual(forever_tick, try deadlineFromTimeout(time_contract.timeoutForever(), 50, 1000));
    try std.testing.expectEqual(abi.timeout_kind_forever, remainingTimeout(forever_tick, forever_tick, 1000).kind);

    const legacy = split("legacy-request");
    try std.testing.expectEqualStrings("legacy-request", legacy.payload);
    try std.testing.expect(legacy.deadline_tick == null);

    var encoded: [64]u8 = undefined;
    const message = append(encoded[0..], "payload", 1234) orelse return error.TestUnexpectedResult;
    encoded["payload".len + 12] = 1;
    const corrupt = split(message);
    try std.testing.expectEqual(message.len, corrupt.payload.len);
    try std.testing.expect(corrupt.deadline_tick == null);
}
