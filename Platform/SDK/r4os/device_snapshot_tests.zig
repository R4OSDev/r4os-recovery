const std = @import("std");
const abi = @import("r4os_contract").abi;
const owner = @import("device_snapshot.zig");
const Probe = struct {
    const Fault = enum { none, oom, header, rows, mask, stop_inside };
    var calls: u32 = 0;
    var generation: u64 = 100;
    var total: u32 = 5;
    var fault: Fault = .none;
    var active: ?*owner.Snapshot = null;
    var loan_observed: bool = false;
    fn reset() void {
        calls = 0;
        generation = 100;
        total = 5;
        fault = .none;
        active = null;
        loan_observed = false;
    }
    fn capture(rows: ?[*]abi.DeviceInventoryRecord, capacity: u32, info: *abi.DeviceInventorySnapshotInfo) callconv(.c) i32 {
        calls += 1;
        if (fault == .oom) return abi.device_snapshot_result_no_memory;
        const count = @min(capacity, total);
        if (rows) |target| for (0..count) |i| {
            target[i] = .{};
            target[i].name[0] = 'A' + @as(u8, @intCast(i));
        };
        const complete = count == total;
        info.* = .{ .snapshot_generation = if (complete) generation else 0, .count = count, .required_count = total, .capacity = capacity, .flags = 2 | (if (complete) @as(u32, 1) else 0), .with_driver = total, .source_mask = @intFromBool(total != 0) };
        switch (fault) {
            .header => info.version += 1,
            .rows => if (rows) |target| {
                target[0].binding = 3;
            },
            .mask => info.source_mask ^= 2,
            .stop_inside => if (active) |snapshot| {
                const progress = snapshot.cancel() catch unreachable;
                loan_observed = progress.flags & owner.flag_in_call != 0 and progress.flags & owner.flag_terminal == 0;
                if (snapshot.close()) |_| {
                    loan_observed = false;
                } else |err| {
                    loan_observed = loan_observed and err == error.Busy;
                }
            },
            else => {},
        }
        return if (complete) 0 else abi.device_snapshot_result_capacity;
    }
    fn create(rows: []abi.DeviceInventoryRecord, capacity: u32) !owner.Snapshot {
        return owner.Snapshot.init(.{ .address = @intFromPtr(rows.ptr), .length = rows.len * @sizeOf(abi.DeviceInventoryRecord) }, capacity, .{ .capture = capture });
    }
};
test "device snapshot owner one capture frozen pages explicit refresh and exact cursor revision" {
    Probe.reset();
    var rows: [5]abi.DeviceInventoryRecord = undefined;
    var snapshot = try Probe.create(&rows, 5);
    try std.testing.expectError(error.Incomplete, snapshot.view());
    const ready = try snapshot.capture(false);
    try std.testing.expectEqual(@intFromEnum(owner.Status.complete), ready.status);
    try std.testing.expect(ready.flags & owner.flag_in_call == 0);
    var cursor = try snapshot.beginPages();
    for (0..5) |i| {
        const page = try snapshot.page(&cursor, 1);
        try std.testing.expectEqual(@as(u32, 1), page.info.returned);
        try std.testing.expectEqual(@intFromPtr(&rows[i]), page.rows.address);
        try std.testing.expectEqual(@as(u32, if (i == 4) 2 else 1), page.info.status);
    }
    const ended = try snapshot.page(&cursor, 1);
    try std.testing.expectEqual(@as(u32, 0), ended.info.returned);
    try std.testing.expectEqual(@as(u32, 1), Probe.calls);
    try std.testing.expectEqual(@as(usize, 5), (try snapshot.records()).len);
    Probe.total = 1;
    Probe.generation += 1;
    _ = try snapshot.capture(false);
    const stale = cursor;
    const restart = try snapshot.page(&cursor, 1);
    try std.testing.expectEqual(@intFromEnum(owner.PageStatus.restart), restart.info.status);
    try std.testing.expectEqual(@as(usize, 0), restart.rows.length);
    try std.testing.expect(std.meta.eql(stale, cursor));
    cursor = try snapshot.beginPages();
    try std.testing.expectEqual(@as(u32, 1), (try snapshot.page(&cursor, 1)).info.returned);
    try std.testing.expectEqual(@as(u32, 2), Probe.calls);
    _ = try snapshot.close();
    try std.testing.expectError(error.Incomplete, snapshot.records());
    try std.testing.expectError(error.Closed, snapshot.capture(false));
}
test "device snapshot owner capacity OOM unavailable and malformed native data never publish partial views" {
    var rows: [5]abi.DeviceInventoryRecord = undefined;
    for ([_]Probe.Fault{ .oom, .header, .rows, .mask }) |fault| {
        Probe.reset();
        Probe.fault = fault;
        var snapshot = try Probe.create(&rows, 5);
        const failed = try snapshot.capture(false);
        try std.testing.expect(failed.flags & owner.flag_complete == 0);
        try std.testing.expectEqual(@as(u64, 0), failed.info.snapshot_generation);
        try std.testing.expectError(error.Incomplete, snapshot.view());
        if (fault == .oom) try std.testing.expectEqual(@as(i32, -8), failed.error_code);
    }
    Probe.reset();
    var snapshot = try Probe.create(&rows, 1);
    const short = try snapshot.capture(false);
    try std.testing.expectEqual(@intFromEnum(owner.Status.capacity), short.status);
    try std.testing.expectEqual(@as(u32, 5), short.info.required_count);
    try std.testing.expectEqual(@as(u64, 0), short.info.snapshot_generation);
    try std.testing.expectError(error.Incomplete, snapshot.view());
    snapshot = try owner.Snapshot.init(.{ .address = @intFromPtr(&rows), .length = @sizeOf(@TypeOf(rows)) }, 5, .{});
    try std.testing.expectEqual(@intFromEnum(owner.Status.no_provider), (try snapshot.capture(false)).status);
}
test "device snapshot owner cancel waits for real return and empty complete copy is explicit" {
    Probe.reset();
    var rows: [5]abi.DeviceInventoryRecord = undefined;
    var snapshot = try Probe.create(&rows, 5);
    Probe.active = &snapshot;
    Probe.fault = .stop_inside;
    const stopped = try snapshot.capture(false);
    try std.testing.expect(Probe.loan_observed);
    try std.testing.expectEqual(@intFromEnum(owner.Status.cancelled), stopped.status);
    try std.testing.expect(stopped.flags & owner.flag_in_call == 0);
    try std.testing.expectError(error.Incomplete, snapshot.view());
    Probe.reset();
    snapshot = try Probe.create(&rows, 5);
    _ = try snapshot.capture(true);
    try std.testing.expectEqual(@as(u32, 0), Probe.calls);
    Probe.reset();
    Probe.total = 0;
    snapshot = try Probe.create(&rows, 0);
    _ = try snapshot.capture(false);
    try std.testing.expectEqual(@as(usize, 0), (try snapshot.records()).len);
    var cursor = try snapshot.beginPages();
    try std.testing.expectEqual(@intFromEnum(owner.PageStatus.complete), (try snapshot.page(&cursor, 64)).info.status);
    try std.testing.expectError(error.InvalidLimit, snapshot.page(&cursor, 0));
    try std.testing.expectError(error.InvalidLimit, snapshot.page(&cursor, 65));
}
