// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Mesa's CPU locks stay in the runtime library. Kernel notification handles
// provide only atomic enrollment and sleep/wake, with process-exit cleanup.
const std = @import("std");
const r4os = @import("r4os");
const a = r4os.abi;

pub const success: c_int = 0;
pub const timedout: c_int = 1;
pub const failed: c_int = 2;
pub const busy: c_int = 3;
pub const nomem: c_int = 4;
pub const recursive: u32 = 2;
pub const forever: u64 = std.math.maxInt(u64);

// Copy only immutable kernel function addresses. A shared R4L must never
// retain the first application's Bundle, allocator, TLS or startup storage.
pub const Host = struct {
    create: a.R4SysFns.notification_create,
    query: a.R4SysFns.notification_query,
    notify: a.R4SysFns.notification_notify,
    wait: a.R4SysFns.notification_wait,
    close: a.R4SysFns.notification_close,
    current: a.R4SysFns.thread_current,
    clock: a.R4SysFns.monotonic_clock,

    pub fn fromTable(table: *const a.R4XStartR4Sys) ?Host {
        if (table.abi_version < 19) return null;
        return fromActualTable(table);
    }
    pub fn fromTable2(table: *const r4os.platform2.abi.R4XStartR4Sys2) ?Host {
        return fromActualTable(table);
    }
    fn fromActualTable(table: anytype) ?Host {
        var result: Host = undefined;
        inline for (.{ .{ "create", "notification_create" }, .{ "query", "notification_query" }, .{ "notify", "notification_notify" }, .{ "wait", "notification_wait" }, .{ "close", "notification_close" }, .{ "current", "thread_current" }, .{ "clock", "monotonic_clock" } }) |pair| {
            if (!@import("system.zig").reaches(table, pair[1])) return null;
            const address = @field(table.*, pair[1]);
            if (address == 0) return null;
            @field(result, pair[0]) = @ptrFromInt(address);
        }
        return result;
    }

    pub fn bound() ?Host {
        const system = @import("system.zig");
        if (system.generation2()) |table| return fromTable2(table);
        return fromTable(system.legacy() orelse return null);
    }

    pub fn waitUntil(self: *const Host, handle: u64, sequence: u64, deadline_ns: u64) c_int {
        var timeout: u64 = forever;
        if (deadline_ns != forever) {
            var clock: a.MonotonicClockInfo = .{};
            if (self.clock(&clock) <= 0 or clock.event_effective_hz == 0) return failed;
            if (clock.instant_ns >= deadline_ns) return timedout;
            const delta: u128 = deadline_ns - clock.instant_ns;
            const ticks = (delta * clock.event_effective_hz + 999_999_999) / 1_000_000_000;
            timeout = @intCast(@min(ticks, forever - 1));
        }
        return switch (self.wait(handle, sequence, timeout)) {
            a.notification_ok => success,
            a.notification_timeout => timedout,
            else => failed,
        };
    }
};

fn newNotification(host: *const Host, storage: *u64) c_int {
    if (@atomicLoad(u64, storage, .acquire) != 0) return success;
    var candidate: u64 = 0;
    const result = host.create(&candidate);
    if (result != a.notification_ok or candidate == 0)
        return if (result == a.notification_error_memory) nomem else failed;
    if (@cmpxchgStrong(u64, storage, 0, candidate, .release, .acquire) != null) {
        if (host.close(candidate) != a.notification_ok) return failed;
    }
    return success;
}

// state: 0 unlocked, 1 locked without known waiters, 2 contended. An
// uncontended lock/unlock needs only the current-thread identity lookup;
// it performs no notification query, scheduler wait or wake.
pub const Mutex = extern struct {
    state: u32 = 0,
    owner: u32 = 0,
    depth: u32 = 0,
    flags: u32 = 0,
    notification: u64 = 0,

    pub fn init(self: *Mutex, host: *const Host, flags: u32) c_int {
        if (flags & ~@as(u32, 7) != 0) return failed;
        self.* = .{ .flags = flags };
        return newNotification(host, &self.notification);
    }
    pub fn destroy(self: *Mutex, host: *const Host) c_int {
        if (@atomicLoad(u32, &self.state, .acquire) != 0) return busy;
        const handle = @atomicLoad(u64, &self.notification, .acquire);
        if (handle == 0) return success; // Unused static initializer.
        if (host.close(handle) != a.notification_ok) return failed;
        self.* = .{};
        return success;
    }
    pub fn tryLock(self: *Mutex, host: *const Host) c_int {
        const thread = host.current();
        if (thread == 0) return failed;
        if (@atomicLoad(u32, &self.owner, .acquire) == thread) {
            if (self.flags & recursive == 0) return busy;
            if (self.depth == std.math.maxInt(u32)) return failed;
            self.depth += 1;
            return success;
        }
        if (@cmpxchgStrong(u32, &self.state, 0, 1, .acquire, .monotonic) != null) return busy;
        self.depth = 1;
        @atomicStore(u32, &self.owner, thread, .release);
        return success;
    }
    pub fn lock(self: *Mutex, host: *const Host, deadline_ns: u64) c_int {
        const immediate = self.tryLock(host);
        if (immediate != busy) return immediate;
        const thread = host.current();
        // Locking a nonrecursive mutex twice is invalid; never park forever.
        if (@atomicLoad(u32, &self.owner, .acquire) == thread) return failed;
        const initialized = newNotification(host, &self.notification);
        if (initialized != success) return initialized;
        const handle = @atomicLoad(u64, &self.notification, .acquire);
        while (true) {
            var sequence: u64 = 0;
            if (host.query(handle, &sequence) != a.notification_ok) return failed;
            if (@atomicRmw(u32, &self.state, .Xchg, 2, .acquire) == 0) {
                self.depth = 1;
                @atomicStore(u32, &self.owner, thread, .release);
                return success;
            }
            const result = host.waitUntil(handle, sequence, deadline_ns);
            if (result != success) return result;
        }
    }
    pub fn unlock(self: *Mutex, host: *const Host) c_int {
        const thread = host.current();
        if (thread == 0 or @atomicLoad(u32, &self.owner, .acquire) != thread or self.depth == 0) return failed;
        self.depth -= 1;
        if (self.depth != 0) return success;
        const handle = @atomicLoad(u64, &self.notification, .acquire);
        @atomicStore(u32, &self.owner, 0, .monotonic);
        const old = @atomicRmw(u32, &self.state, .Xchg, 0, .release);
        if (old != 2) return success;
        return if (handle != 0 and host.notify(handle, 1) == a.notification_ok) success else failed;
    }
};

pub const Condition = extern struct {
    notification: u64 = 0,
    waiters: u32 = 0,
    reserved: u32 = 0,

    pub fn init(self: *Condition, host: *const Host) c_int {
        self.* = .{};
        return newNotification(host, &self.notification);
    }
    pub fn destroy(self: *Condition, host: *const Host) c_int {
        if (@atomicLoad(u32, &self.waiters, .acquire) != 0) return busy;
        const handle = @atomicLoad(u64, &self.notification, .acquire);
        if (handle == 0) return success;
        if (host.close(handle) != a.notification_ok) return failed;
        self.* = .{};
        return success;
    }
    pub fn signal(self: *Condition, host: *const Host, all: bool) c_int {
        const handle = @atomicLoad(u64, &self.notification, .acquire);
        // Static unused condition variables have no enrolled waiters.
        if (handle == 0) return success;
        return if (host.notify(handle, if (all) std.math.maxInt(u32) else 1) == a.notification_ok) success else failed;
    }
    pub fn wait(self: *Condition, host: *const Host, mutex: *Mutex, deadline_ns: u64) c_int {
        // Releasing only one recursive level cannot let the producer enter.
        if (mutex.depth != 1 or @atomicLoad(u32, &mutex.owner, .acquire) != host.current()) return failed;
        const initialized = newNotification(host, &self.notification);
        if (initialized != success) return initialized;
        const handle = @atomicLoad(u64, &self.notification, .acquire);
        var sequence: u64 = 0;
        if (host.query(handle, &sequence) != a.notification_ok) return failed;
        _ = @atomicRmw(u32, &self.waiters, .Add, 1, .acq_rel);
        defer _ = @atomicRmw(u32, &self.waiters, .Sub, 1, .release);
        if (mutex.unlock(host) != success) return failed;
        const result = host.waitUntil(handle, sequence, deadline_ns);
        // C11/POSIX condition semantics reacquire even on timeout or error.
        if (mutex.lock(host, forever) != success) return failed;
        return result;
    }
};

comptime {
    std.debug.assert(@sizeOf(Mutex) == 24 and @alignOf(Mutex) == 8);
    std.debug.assert(@sizeOf(Condition) == 16 and @alignOf(Condition) == 8);
}
