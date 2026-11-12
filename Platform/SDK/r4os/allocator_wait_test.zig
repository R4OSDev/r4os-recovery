//! Host backend for the allocator's existing tests. Kernel notification queue
//! enrollment is covered separately in the guest; this model uses host waits.
const std = @import("std");
const abi = @import("r4os_contract").abi;
const io = std.testing.io;
const Entry = struct { handle: u64 = 0, sequence: u64 = 0, closed: bool = false };
var mutex: std.Io.Mutex = .init;
var condition: std.Io.Condition = .init;
var entries: [16]Entry = .{Entry{}} ** 16;
var serial: u64 = 0;
pub var waits: std.atomic.Value(u32) = .init(0);
pub var parked: std.atomic.Value(u32) = .init(0);
pub var fail_close: bool = false;
pub var pause_kind: u32 = 0;
pub var reached: bool = false;
pub var resumed: bool = false;

fn find(handle: u64) ?*Entry {
    for (&entries) |*entry| if (entry.handle == handle) return entry;
    return null;
}
fn create(output: *u64) callconv(.c) i32 {
    mutex.lockUncancelable(io);
    defer mutex.unlock(io);
    for (&entries) |*entry| if (entry.handle == 0) {
        serial += 1;
        entry.* = .{ .handle = serial };
        output.* = serial;
        return abi.notification_ok;
    };
    return abi.notification_error_memory;
}
fn query(handle: u64, output: *u64) callconv(.c) i32 {
    mutex.lockUncancelable(io);
    defer mutex.unlock(io);
    const entry = find(handle) orelse return abi.notification_error_stale;
    if (entry.closed) return abi.notification_error_closed;
    output.* = entry.sequence;
    return abi.notification_ok;
}
fn notify(handle: u64, count: u32) callconv(.c) i32 {
    std.debug.assert(count != 0);
    mutex.lockUncancelable(io);
    defer mutex.unlock(io);
    const entry = find(handle) orelse return abi.notification_error_stale;
    if (entry.closed) return abi.notification_error_closed;
    entry.sequence += 1;
    condition.broadcast(io);
    return abi.notification_ok;
}
fn wait(handle: u64, observed: u64, _: u64) callconv(.c) i32 {
    _ = waits.fetchAdd(1, .monotonic);
    mutex.lockUncancelable(io);
    defer mutex.unlock(io);
    const entry = find(handle) orelse return abi.notification_error_stale;
    while (!entry.closed and entry.sequence == observed) {
        _ = parked.fetchAdd(1, .monotonic);
        condition.broadcast(io);
        condition.waitUncancelable(io, &mutex);
    }
    return if (entry.closed) abi.notification_error_closed else abi.notification_ok;
}
fn close(handle: u64) callconv(.c) i32 {
    mutex.lockUncancelable(io);
    defer mutex.unlock(io);
    const entry = find(handle) orelse return abi.notification_error_stale;
    entry.closed = true;
    condition.broadcast(io);
    if (fail_close) return abi.notification_error_release;
    entry.* = .{};
    return abi.notification_ok;
}
fn sleep(_: u64) callconv(.c) void {
    std.Thread.yield() catch {};
}
pub fn install(api: *abi.R4XStartR4Sys) void {
    entries = .{Entry{}} ** entries.len;
    waits.store(0, .release);
    parked.store(0, .release);
    fail_close = false;
    pause_kind = 0;
    reached = false;
    resumed = false;
    api.notification_create = @intFromPtr(&create);
    api.notification_query = @intFromPtr(&query);
    api.notification_notify = @intFromPtr(&notify);
    api.notification_wait = @intFromPtr(&wait);
    api.notification_close = @intFromPtr(&close);
    api.sleep_ticks = @intFromPtr(&sleep);
}
pub fn pause(kind: u32) void {
    mutex.lockUncancelable(io);
    defer mutex.unlock(io);
    if (pause_kind != kind) return;
    pause_kind = 0;
    reached = true;
    condition.broadcast(io);
    while (!resumed) condition.waitUncancelable(io, &mutex);
}
pub fn arm(kind: u32) void {
    mutex.lockUncancelable(io);
    defer mutex.unlock(io);
    pause_kind = kind;
    reached = false;
    resumed = false;
}
pub fn awaitPause() void {
    mutex.lockUncancelable(io);
    defer mutex.unlock(io);
    while (!reached) condition.waitUncancelable(io, &mutex);
}
pub fn continueWork() void {
    mutex.lockUncancelable(io);
    defer mutex.unlock(io);
    resumed = true;
    condition.broadcast(io);
}
pub fn awaitPark(previous: u32) void {
    mutex.lockUncancelable(io);
    defer mutex.unlock(io);
    while (parked.load(.acquire) == previous) condition.waitUncancelable(io, &mutex);
}
pub fn expectClosed() !void {
    for (entries) |entry| try std.testing.expectEqual(@as(u64, 0), entry.handle);
}
pub fn checkRevisionContract(api: *abi.R4XStartR4Sys) !void {
    const Channel = @import("allocator_wait.zig").Channel;
    var channel: Channel = .{};
    const ticket = channel.enroll(api) orelse return error.MissingNotification;
    channel.notify(api); // Deliberately before the actual wait enrollment.
    ticket.wait();
    try std.testing.expectEqual(@as(u32, 0), parked.load(.acquire));
    ticket.deinit();
    fail_close = true;
    channel.prune(api);
    try std.testing.expectEqual(ticket.handle, channel.handle);
    try std.testing.expect(channel.enroll(api) == null);
    fail_close = false;
    channel.prune(api);
    try std.testing.expectEqual(@as(u64, 0), channel.handle);
    const saved = api.size;
    api.size = @offsetOf(abi.R4XStartR4Sys, "notification_close");
    try std.testing.expect(channel.enroll(api) == null);
    api.size = saved;
    const saved_close = api.notification_close;
    api.notification_close = 0;
    try std.testing.expect(channel.enroll(api) == null);
    api.notification_close = saved_close;
    try expectClosed();
}
