// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Native Mesa C11 transport. Mutable locks/once objects must belong to the
// calling program; process-owned notification handles are not cross-process.
const std = @import("std");
const r4os = @import("r4os");
const a = r4os.abi;
pub const system = @import("system.zig");
const sync = @import("threading.zig");
const Mutex = sync.Mutex;
const Condition = sync.Condition;
pub const Once = extern struct { state: u32 = 0, reserved: u32 = 0, notification: u64 = 0 };
const Timespec = extern struct { seconds: i64, nanoseconds: i64 };
const MonotonicCondition = extern struct { cond: Condition };
pub const Entry = *const fn (?*anyopaque) callconv(.c) c_int;
/// Immutable code-only dispatch owned by the consuming R4L. It must be bound
/// before that library creates workers; no process data is retained here.
pub const Lifecycle = struct {
    create: *const fn (*a.ProgramJoinHandle, Entry, ?*anyopaque) c_int,
    finish_current: *const fn () bool,
};
var lifecycle_table: std.atomic.Value(usize) = .init(0);
pub fn bindLifecycle(value: *const Lifecycle) bool {
    const old = lifecycle_table.cmpxchgStrong(0, @intFromPtr(value), .release, .acquire);
    return old == null or old.? == @intFromPtr(value);
}
fn lifecycle() ?*const Lifecycle {
    const address = lifecycle_table.load(.acquire);
    return if (address == 0) null else @ptrFromInt(address);
}

// The table is kernel-owned and immutable for the boot generation. Keep no
// caller Bundle, allocator, task pointer or other application storage here.
pub fn bind(kernel: *const a.R4XStartR4Sys) bool {
    _ = sync.Host.fromTable(kernel) orelse return false;
    if (kernel.abi_version < 21 or kernel.size < @offsetOf(a.R4XStartR4Sys, "thread_current_handle") + 8 or
        kernel.thread_current_handle == 0) return false;
    inline for (.{ "thread_create_handle", "thread_handle_join", "thread_current", "thread_status", "thread_exit", "task_yield" }) |field|
        if (@field(kernel.*, field) == 0) return false;
    return system.bind(kernel);
}
pub fn bind2(kernel: *const r4os.platform2.abi.R4XStartR4Sys2) bool {
    _ = sync.Host.fromTable2(kernel) orelse return false;
    return system.bind2(kernel);
}
pub fn table() *const a.R4XStartR4Sys {
    return system.legacy() orelse @trap();
}
pub fn host() sync.Host {
    return sync.Host.bound() orelse @trap();
}
fn function(comptime name: []const u8) @field(a.R4SysFns, name) {
    return system.required(name);
}
// A void C API cannot report a violated lock lifetime. Never continue with
// an unlocked/destroyed object or claim that a failed operation succeeded.
fn require(result: c_int) void {
    if (result != sync.success) @trap();
}

pub export fn mtx_init(mutex: *Mutex, flags: c_int) callconv(.c) c_int {
    if (flags < 0) return sync.failed;
    return mutex.init(&host(), @intCast(flags));
}
pub export fn mtx_destroy(mutex: *Mutex) callconv(.c) void {
    require(mutex.destroy(&host()));
}
/// Private retryable destruction for a quiescent native runtime shutdown.
pub export fn r4native_mutex_close(mutex: *Mutex) callconv(.c) c_int {
    return mutex.destroy(&host());
}
pub export fn mtx_lock(mutex: *Mutex) callconv(.c) c_int {
    return mutex.lock(&host(), sync.forever);
}
pub export fn mtx_trylock(mutex: *Mutex) callconv(.c) c_int {
    return mutex.tryLock(&host());
}
pub export fn mtx_unlock(mutex: *Mutex) callconv(.c) c_int {
    return mutex.unlock(&host());
}
pub export fn cnd_init(condition: *Condition) callconv(.c) c_int {
    return condition.init(&host());
}
pub export fn cnd_destroy(condition: *Condition) callconv(.c) void {
    require(condition.destroy(&host()));
}
pub export fn cnd_wait(condition: *Condition, mutex: *Mutex) callconv(.c) c_int {
    return condition.wait(&host(), mutex, sync.forever);
}
pub export fn cnd_signal(condition: *Condition) callconv(.c) c_int {
    return condition.signal(&host(), false);
}
pub export fn cnd_broadcast(condition: *Condition) callconv(.c) c_int {
    return condition.signal(&host(), true);
}

pub export fn u_cnd_monotonic_init(condition: *MonotonicCondition) callconv(.c) c_int {
    return cnd_init(&condition.cond);
}
pub export fn u_cnd_monotonic_destroy(condition: *MonotonicCondition) callconv(.c) void {
    cnd_destroy(&condition.cond);
}
pub export fn u_cnd_monotonic_signal(condition: *MonotonicCondition) callconv(.c) c_int {
    return cnd_signal(&condition.cond);
}
pub export fn u_cnd_monotonic_broadcast(condition: *MonotonicCondition) callconv(.c) c_int {
    return cnd_broadcast(&condition.cond);
}
pub export fn u_cnd_monotonic_wait(condition: *MonotonicCondition, mutex: *Mutex) callconv(.c) c_int {
    return cnd_wait(&condition.cond, mutex);
}
pub export fn u_cnd_monotonic_timedwait(condition: *MonotonicCondition, mutex: *Mutex, absolute: *const Timespec) callconv(.c) c_int {
    if (absolute.nanoseconds < 0 or absolute.nanoseconds >= 1_000_000_000) return sync.failed;
    const deadline = if (absolute.seconds < 0) 0 else std.math.cast(u64, @as(u128, @intCast(absolute.seconds)) * 1_000_000_000 + @as(u64, @intCast(absolute.nanoseconds))) orelse sync.forever;
    return condition.cond.wait(&host(), mutex, deadline);
}

// The C pointer argument and R4OS u64 argument have the same x86_64 ABI.
// The kernel admits only this program's image or an imported executable R4L
// generation; it owns the worker's stack, execution pin, join and hard kill.
pub export fn thrd_create(output: *a.ProgramJoinHandle, entry: Entry, argument: ?*anyopaque) callconv(.c) c_int {
    if (lifecycle()) |owner| return owner.create(output, entry, argument);
    return createRaw(output, entry, argument);
}
pub fn createRaw(output: *a.ProgramJoinHandle, entry: Entry, argument: ?*anyopaque) c_int {
    var candidate: a.ProgramJoinHandle = .{};
    const result = function("thread_create_handle")(@ptrCast(entry), @intFromPtr(argument), 1024 * 1024, 0, &candidate);
    if (result != a.thread_ok) return if (result == a.thread_error_no_memory) sync.nomem else sync.failed;
    output.* = candidate;
    return sync.success;
}
pub export fn thrd_join(thread: a.ProgramJoinHandle, output: ?*c_int) callconv(.c) c_int {
    var code: i32 = 0;
    if (function("thread_handle_join")(&thread, sync.forever, &code) != a.thread_ok) return sync.failed;
    if (output) |value| value.* = code;
    return sync.success;
}
pub export fn thrd_current() callconv(.c) a.ProgramJoinHandle {
    var identity: a.ProgramJoinHandle = .{};
    if (function("thread_current_handle")(&identity) != a.thread_ok) return .{};
    return identity;
}
pub export fn thrd_equal(left: a.ProgramJoinHandle, right: a.ProgramJoinHandle) callconv(.c) c_int {
    return @intFromBool(left.thread_id != 0 and left.thread_generation != 0 and
        left.thread_id == right.thread_id and left.instance_id == right.instance_id and
        left.thread_generation == right.thread_generation and left.instance_generation == right.instance_generation);
}
pub export fn thrd_yield() callconv(.c) void {
    function("task_yield")();
}
pub export fn thrd_exit(code: c_int) callconv(.c) noreturn {
    if (lifecycle()) |owner| if (!owner.finish_current()) @trap();
    function("thread_exit")(code);
    @trap();
}

fn once(once_flag: *Once, callback: *const fn (?*const anyopaque) callconv(.c) void, argument: ?*const anyopaque) void {
    if (@atomicLoad(u32, &once_flag.state, .acquire) == 2) return;
    var condition: Condition = .{ .notification = @atomicLoad(u64, &once_flag.notification, .acquire) };
    if (condition.notification == 0) {
        require(condition.init(&host()));
        if (@cmpxchgStrong(u64, &once_flag.notification, 0, condition.notification, .release, .acquire)) |previous| {
            require(condition.destroy(&host()));
            condition.notification = previous;
        }
    }
    if (@cmpxchgStrong(u32, &once_flag.state, 0, 1, .acq_rel, .acquire) == null) {
        callback(argument);
        @atomicStore(u32, &once_flag.state, 2, .release);
        require(condition.signal(&host(), true));
        // No waiter needs the event after observing state=done. Keep its
        // closed, never-reused identity in the flag so a delayed contender
        // cannot allocate a replacement. Dynamic Mesa mutexes otherwise
        // accumulate one notification per once object until process exit.
        require(condition.destroy(&host()));
        return;
    }
    const transport = host();
    while (@atomicLoad(u32, &once_flag.state, .acquire) != 2) {
        var sequence: u64 = 0;
        const queried = transport.query(condition.notification, &sequence);
        if (@atomicLoad(u32, &once_flag.state, .acquire) == 2) break;
        require(queried);
        const waited = transport.waitUntil(condition.notification, sequence, sync.forever);
        // Completion may close the event between the revision read and wait.
        // Only the published initialized state makes that race successful.
        if (@atomicLoad(u32, &once_flag.state, .acquire) == 2) break;
        require(waited);
    }
}
fn onceCallback(argument: ?*const anyopaque) callconv(.c) void {
    const callback: *const fn () callconv(.c) void = @ptrCast(argument.?);
    callback();
}
pub export fn call_once(flag: *Once, callback: *const fn () callconv(.c) void) callconv(.c) void {
    once(flag, onceCallback, @ptrCast(callback));
}
pub export fn util_call_once_data_slow(flag: *Once, callback: *const fn (?*const anyopaque) callconv(.c) void, data: ?*const anyopaque) callconv(.c) void {
    once(flag, callback, data);
}
