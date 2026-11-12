// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const r = @import("r4os");
const native = @import("r4native");
const a = r.abi;
pub const Budget = @import("native_allocation").Budget;
const Policy = struct {
    pub fn currentBudget() ?*Budget {
        return if (currentOwner()) |owner| &owner.memory else null;
    }
};
pub const memory = native.budgeted_memory.Runtime(Policy, @import("native_allocation"));
const lifecycle = native.thread_lifecycle.Runtime(memory, releaseApiThread);
var bound: std.atomic.Value(bool) = .init(false);
const Process = struct { phase: std.atomic.Value(u32) = .init(0), io_error: bool = false }; // binding, ready, closing, closed
var process_key: u8 = 0;
fn initializeProcess(value: *Process) void {
    value.* = .{};
}
fn process() ?*Process {
    return native.process_local.getOrCreate(Process, &process_key, initializeProcess);
}

/// Retained by the decoder until all pthread joins, allocations and BO leases
/// have returned. Parent budgets belong to the enclosing public runtime owner.
pub const Owner = struct {
    memory: Budget,
    workers: Budget,
    process_generation: u64,
};
const Thread = struct { owner: ?*Owner = null };
const owner_control: native.thread_local.Control = .{
    .size = @sizeOf(Thread),
    .alignment = @alignOf(Thread),
    .object = 0,
    .default_value = null,
};
fn currentThread() ?*Thread {
    if (!bound.load(.acquire)) return null;
    return @ptrCast(@alignCast(native.thread_local.getAddress(&owner_control) orelse return null));
}
fn currentOwner() ?*Owner {
    return (currentThread() orelse return null).owner;
}
pub const Scope = struct {
    thread: *Thread,
    previous: ?*Owner,
    pub fn leave(self: Scope) void {
        self.thread.owner = self.previous;
    }
};
pub fn enter(owner: *Owner) ?Scope {
    const thread = currentThread() orelse return null;
    const identity = native.threads.thrd_current();
    if (owner.process_generation == 0 or identity.instance_generation != owner.process_generation) return null;
    const result: Scope = .{ .thread = thread, .previous = thread.owner };
    thread.owner = owner;
    return result;
}

extern fn r4video_ffmpeg_prepare() callconv(.c) c_int;
extern fn r4video_ffmpeg_finish() callconv(.c) c_int;
extern fn r4native_stdio_finish() callconv(.c) c_int;
fn requiredSystem(sys: anytype) bool {
    inline for (.{ "write", "program_exit", "cpu_capacity", "vm_reserve", "vm_commit", "vm_release", "program_local_get", "program_local_publish", "monotonic_clock", "sleep_ticks" }) |field|
        if (!native.system.reaches(sys, field)) return false;
    return true;
}
pub fn bindAddress(address: u64) bool {
    const input = native.caller.Input.init(address) catch return false;
    switch (input) {
        .legacy => |view| {
            const sys = view.sys orelse return false;
            if (sys.abi_version < 23 or !requiredSystem(sys) or !native.threads.bind(sys)) return false;
        },
        .generation2 => |view| {
            const sys = view.system() orelse return false;
            if (!requiredSystem(sys) or !native.threads.bind2(sys)) return false;
        },
    }
    if (!native.application.bindAddress(address) or !lifecycle.bind()) return false;
    bound.store(true, .release);
    const value = process() orelse return false;
    if (value.phase.load(.acquire) >= 2) return false;
    const capacity = native.process.cpuCapacity() orelse return false;
    if (capacity.available_cpus == 0 or native.time.read() == null) return false;
    if (r4video_ffmpeg_prepare() == 0) return false;
    const previous = value.phase.cmpxchgStrong(0, 1, .acq_rel, .acquire);
    return previous == null or previous.? == 1;
}
pub fn applicationBound() bool {
    return bound.load(.acquire) and native.application.snapshot() != null;
}
// Public calls are non-reentrant and retain no language TLS across return.
// Native pthread entries instead use the exact thread lifecycle destructor.
pub fn releaseCaller() bool {
    return native.thread_local.releaseCurrent();
}
export fn r4video_thread_tryjoin(handle: *const a.ProgramJoinHandle, output: ?*c_int) callconv(.c) c_int {
    const join = native.system.required("thread_handle_join");
    var result: i32 = 0;
    return switch (join(handle, 0, &result)) {
        a.thread_ok => blk: {
            if (output) |value| value.* = result;
            break :blk native.threading.success;
        },
        a.thread_error_timeout, a.thread_error_busy => native.threading.busy,
        else => native.threading.failed,
    };
}
fn releaseApiThread() bool {
    return true;
}
// Called only after the public runtime has stopped admission and confirmed all
// exact joins and frame returns. An incomplete shutdown retains its providers.
pub const Finish = enum { complete, pending, io_error };
pub fn finishNative() Finish {
    const value = process() orelse return .pending;
    if (value.phase.load(.acquire) == 3) return if (value.io_error) .io_error else .complete;
    value.phase.store(2, .release);
    if (!lifecycle.closeAdmission() or !lifecycle.finishCurrent()) return .pending;
    if ((lifecycle.liveWorkers() orelse return .pending) != 0 or
        (native.thread_local.liveThreadCount() orelse return .pending) != 0) return .pending;
    if (r4video_ffmpeg_finish() == 0) return .pending;
    const stdio = r4native_stdio_finish();
    if (stdio < 0) return .pending;
    value.io_error = value.io_error or stdio != 0;
    memory.trim();
    if (!native.thread_local.releaseCurrent()) return .pending;
    value.phase.store(3, .release);
    return if (value.io_error) .io_error else .complete;
}

export fn r4video_task_owner() callconv(.c) ?*Owner {
    return currentOwner();
}
export fn r4video_task_enter(owner: *Owner) callconv(.c) c_int {
    _ = enter(owner) orelse return 0;
    return 1;
}
// Shared Native createRaw reserves a 1-MB program stack. Charge its whole span
// and the separate 64-KB kernel stack until successful exact join, even if the
// callback has returned. Private start/lifecycle allocations are charged too.
const worker_bytes = 1024 * 1024 + 64 * 1024;
export fn r4video_worker_acquire(owner: *Owner) callconv(.c) c_int {
    if (!owner.workers.reserve(1)) return 0;
    if (!owner.memory.reserve(worker_bytes)) {
        owner.workers.release(1);
        return 0;
    }
    return 1;
}
export fn r4video_worker_release(owner: *Owner) callconv(.c) void {
    owner.memory.release(worker_bytes);
    owner.workers.release(1);
}
export fn r4video_condition_close(condition: *native.threading.Condition) callconv(.c) c_int {
    const host = native.threading.Host.bound() orelse return native.threading.failed;
    return condition.destroy(&host);
}
export fn r4video_process_state(key: *const anyopaque, bytes: usize, alignment: usize, initialize: native.process_local.Initializer) callconv(.c) ?*anyopaque {
    return native.process_local.initializedBlob(key, bytes, alignment, initialize);
}
export fn r4video_cpu_count() callconv(.c) c_int {
    const capacity = native.process.cpuCapacity() orelse fatal("R4VIDEO: CPU capacity unavailable\n");
    return std.math.cast(c_int, capacity.available_cpus) orelse fatal("R4VIDEO: CPU capacity overflow\n");
}
export fn r4video_random_seed() callconv(.c) u32 {
    // FFmpeg's fallback seed is not an entropy API. Avoid its clock-spin loop.
    const now = native.time.read() orelse fatal("R4VIDEO: clock unavailable\n");
    const random = native.random.next() catch fatal("R4VIDEO: seed state unavailable\n");
    return @as(u32, @truncate(now.instant_ns ^ (now.instant_ns >> 32))) ^ @as(u32, random);
}
export fn r4video_time_us(relative: c_int) callconv(.c) i64 {
    if (relative != 0) {
        const now = native.time.read() orelse return -1;
        return @intCast(now.instant_ns / 1000);
    }
    const now = native.wall_clock.read() orelse return -1;
    return std.math.mul(i64, now.seconds, 1_000_000) catch -1;
}
export fn r4video_sleep_us(microseconds: c_uint) callconv(.c) c_int {
    native.time.os_time_sleep(microseconds);
    return 0;
}
export fn malloc(bytes: usize) callconv(.c) ?*anyopaque {
    return memory.malloc(bytes);
}
export fn calloc(count: usize, width: usize) callconv(.c) ?*anyopaque {
    return memory.calloc(count, width);
}
export fn realloc(pointer: ?*anyopaque, bytes: usize) callconv(.c) ?*anyopaque {
    return memory.realloc(pointer, bytes);
}
export fn reallocarray(pointer: ?*anyopaque, count: usize, width: usize) callconv(.c) ?*anyopaque {
    return memory.reallocarray(pointer, count, width);
}
export fn free(pointer: ?*anyopaque) callconv(.c) void {
    memory.free(pointer);
}
export fn aligned_alloc(alignment: usize, bytes: usize) callconv(.c) ?*anyopaque {
    return memory.aligned_alloc(alignment, bytes);
}
export fn posix_memalign(output: *?*anyopaque, alignment: usize, bytes: usize) callconv(.c) c_int {
    return memory.posix_memalign(output, alignment, bytes);
}
export fn __emutls_get_address(control: *const native.thread_local.Control) callconv(.c) *anyopaque {
    return native.thread_local.getAddress(control) orelse fatal("R4VIDEO: TLS unavailable\n");
}
pub fn fatal(message: [*:0]const u8) noreturn {
    const write = native.system.required("write");
    _ = write(message, @intCast(std.mem.len(message)));
    const stop = native.system.required("program_exit");
    _ = stop(-1, a.program_exit_reason_failed);
    @trap();
}
export fn abort() callconv(.c) noreturn {
    fatal("R4VIDEO: native abort\n");
}
export fn r4native_console_write(bytes: [*]const u8, count: u32) callconv(.c) i32 {
    const write = native.system.required("write");
    return write(bytes, count);
}
export fn r4nak_port_assert(message: [*:0]const u8, _: [*:0]const u8, _: c_int) callconv(.c) noreturn {
    fatal(message);
}
comptime {
    _ = native.math;
    _ = native.files;
    _ = native.time;
    _ = native.wall_clock;
    _ = native.calendar;
}
