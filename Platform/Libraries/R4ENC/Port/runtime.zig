// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const r = @import("r4os");
const a = r.abi;
const native = @import("r4native");
pub const Budget = @import("native_allocation").Budget;
pub const Owner = struct {
    memory: Budget,
    workers: Budget,
    process_generation: u64,
};
const Policy = struct {
    pub fn currentBudget() ?*Budget {
        return if (currentOwner()) |owner| &owner.memory else null;
    }
};
pub const memory = native.budgeted_memory.Runtime(Policy, @import("native_allocation"));
const Thread = struct { owner: ?*Owner = null, calendar: native.calendar.Tm = .{} };
const control: native.thread_local.Control = .{
    .size = @sizeOf(Thread),
    .alignment = @alignOf(Thread),
    .object = 0,
    .default_value = null,
};
var bound: std.atomic.Value(bool) = .init(false);
fn currentThread() ?*Thread {
    if (!bound.load(.acquire)) return null;
    return @ptrCast(@alignCast(native.thread_local.getAddress(&control) orelse return null));
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
    const identity = native.threads.thrd_current();
    if (owner.process_generation == 0 or owner.process_generation != identity.instance_generation) return null;
    const thread = currentThread() orelse return null;
    const result: Scope = .{ .thread = thread, .previous = thread.owner };
    thread.owner = owner;
    return result;
}
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
    if (!native.application.bindAddress(address)) return false;
    bound.store(true, .release);
    const capacity = native.process.cpuCapacity() orelse return false;
    return capacity.available_cpus != 0 and native.time.read() != null;
}
pub fn applicationBound() bool {
    return bound.load(.acquire) and native.application.snapshot() != null;
}
pub fn releaseCaller() bool {
    return native.thread_local.releaseCurrent();
}
// The coordinator joins all exact workers and rejects further admission first.
pub fn finishNative() bool {
    if (!releaseCaller() or (native.thread_local.liveThreadCount() orelse return false) != 0) return false;
    memory.trim();
    return native.thread_local.releaseCurrent();
}

pub const WorkerEntry = *const fn (?*anyopaque, bool) callconv(.c) c_int;
pub const Worker = struct {
    owner: *Owner,
    entry: WorkerEntry,
    argument: ?*anyopaque,
    handle: a.ProgramJoinHandle = .{},
    charged: bool = false,
    startup_mutex: native.threading.Mutex = .{},
    startup_condition: native.threading.Condition = .{},
    ready: bool = false,
    admitted: bool = false,
    // Shared Native's 1-MB program stack plus the 64-KB kernel stack remain
    // charged after the callback returns and until the exact join succeeds.
    const stack_bytes = 1024 * 1024 + 64 * 1024;
    pub fn start(self: *Worker) bool {
        if (self.charged or self.handle.thread_generation != 0) return false;
        if (!self.owner.workers.reserve(1)) return false;
        if (!self.owner.memory.reserve(stack_bytes)) {
            self.owner.workers.release(1);
            return false;
        }
        self.charged = true;
        self.ready = false;
        self.admitted = false;
        const host = native.threading.Host.bound().?;
        if (self.startup_condition.init(&host) != native.threading.success) {
            self.retire() catch fatal("R4ENC: failed startup retirement\n");
            return false;
        }
        if (self.startup_mutex.lock(&host, native.threading.forever) != native.threading.success)
            fatal("R4ENC: startup lock failed\n");
        if (native.threads.createRaw(&self.handle, run, self) != native.threading.success) {
            if (self.startup_mutex.unlock(&host) != native.threading.success) fatal("R4ENC: startup unlock failed\n");
            self.retire() catch fatal("R4ENC: failed startup retirement\n");
            return false;
        }
        while (!self.ready) {
            if (self.startup_condition.wait(&host, &self.startup_mutex, native.threading.forever) != native.threading.success)
                fatal("R4ENC: startup wait failed\n");
        }
        const admitted = self.admitted;
        if (self.startup_mutex.unlock(&host) != native.threading.success) fatal("R4ENC: startup unlock failed\n");
        if (!admitted) {
            // The callback never ran. The blocking Create caller owns cleanup
            // only after the failed startup has completed its exact join.
            if (native.threads.thrd_join(self.handle, null) != native.threading.success) fatal("R4ENC: failed startup join\n");
            self.handle = .{};
            self.retire() catch fatal("R4ENC: failed startup retirement\n");
            return false;
        }
        return true;
    }
    fn run(argument: ?*anyopaque) callconv(.c) c_int {
        const self: *Worker = @ptrCast(@alignCast(argument.?));
        const scope = enter(self.owner);
        const host = native.threading.Host.bound().?;
        if (self.startup_mutex.lock(&host, native.threading.forever) != native.threading.success) fatal("R4ENC: startup lock failed\n");
        self.admitted = scope != null;
        self.ready = true;
        if (self.startup_condition.signal(&host, false) != native.threading.success or
            self.startup_mutex.unlock(&host) != native.threading.success) fatal("R4ENC: startup notification failed\n");
        const result = if (scope != null) self.entry(self.argument, true) else 0;
        if (scope) |value| value.leave();
        if (!native.thread_local.releaseCurrent()) fatal("R4ENC: worker TLS retirement failed\n");
        return result;
    }
    pub fn tryJoin(self: *Worker) error{ Busy, Internal }!void {
        if (!self.charged) return error.Internal;
        if (self.handle.thread_generation != 0) {
            const join = native.system.required("thread_handle_join");
            var result: i32 = 0;
            switch (join(&self.handle, 0, &result)) {
                a.thread_ok => {},
                a.thread_error_busy, a.thread_error_timeout => return error.Busy,
                else => return error.Internal,
            }
            self.handle = .{};
        }
        try self.retire();
    }
    fn retire(self: *Worker) error{Internal}!void {
        const host = native.threading.Host.bound().?;
        // Both objects remain live until exact join, including a successful
        // startup: the child may still be completing its unlock notification.
        if (self.startup_condition.destroy(&host) != native.threading.success or
            self.startup_mutex.destroy(&host) != native.threading.success) return error.Internal;
        self.owner.memory.release(stack_bytes);
        self.owner.workers.release(1);
        self.charged = false;
    }
};

export fn malloc(bytes: usize) callconv(.c) ?*anyopaque {
    return memory.malloc(bytes);
}
export fn calloc(count: usize, width: usize) callconv(.c) ?*anyopaque {
    return memory.calloc(count, width);
}
export fn realloc(pointer: ?*anyopaque, bytes: usize) callconv(.c) ?*anyopaque {
    return memory.realloc(pointer, bytes);
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
export fn __emutls_get_address(value: *const native.thread_local.Control) callconv(.c) *anyopaque {
    return native.thread_local.getAddress(value) orelse fatal("R4ENC: TLS unavailable\n");
}
pub fn fatal(message: [*:0]const u8) noreturn {
    const write = native.system.required("write");
    _ = write(message, @intCast(std.mem.len(message)));
    const stop = native.system.required("program_exit");
    _ = stop(-1, a.program_exit_reason_failed);
    @trap();
}
export fn abort() callconv(.c) noreturn {
    fatal("R4ENC: native abort\n");
}
export fn r4nak_port_assert(message: [*:0]const u8, _: [*:0]const u8, _: c_int) callconv(.c) noreturn {
    fatal(message);
}
export fn r4native_console_write(bytes: [*]const u8, count: u32) callconv(.c) i32 {
    const write = native.system.required("write");
    return write(bytes, count);
}
export fn r4enc_monotonic_us() callconv(.c) i64 {
    return @intCast((native.time.read() orelse fatal("R4ENC: clock unavailable\n")).instant_ns / 1000);
}
const Timeval = extern struct { seconds: i64, microseconds: i64 };
export fn gettimeofday(output: *Timeval, timezone: ?*anyopaque) callconv(.c) c_int {
    if (timezone != null) return -1;
    const value = native.wall_clock.read() orelse return -1;
    output.* = .{ .seconds = value.seconds, .microseconds = @divTrunc(value.nanoseconds, 1000) };
    return 0;
}
export fn localtime(seconds: *const i64) callconv(.c) ?*native.calendar.Tm {
    const thread = currentThread() orelse return null;
    return native.calendar.localtime_r(seconds, &thread.calendar);
}
comptime {
    _ = native.math;
    _ = native.time;
    _ = native.wall_clock;
    _ = native.calendar;
}
