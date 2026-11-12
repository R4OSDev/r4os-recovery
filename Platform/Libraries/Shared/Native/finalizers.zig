// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const local = @import("process_local.zig");
const threads = @import("threads.zig");
const sync = @import("threading.zig");

/// Process-lifetime callbacks for one consuming native R4L. Finish follows
/// API/worker quiescence; this is neither a kernel exit hook nor an unwinder.
pub fn Runtime(comptime Memory: type) type {
    return struct {
        pub const Callback = *const fn (?*anyopaque) callconv(.c) void;
        pub const PlainCallback = *const fn () callconv(.c) void;
        const Function = union(enum) { plain: PlainCallback, context: Callback };
        const Record = struct { next: ?*Record, function: Function, argument: ?*anyopaque };
        const Phase = enum { open, running, closed };
        const State = struct {
            mutex: sync.Mutex = .{},
            phase: Phase = .open,
            head: ?*Record = null,
            pending: usize = 0,
        };
        var key: u8 = 0;
        fn initialize(value: *State) void {
            value.* = .{};
        }
        fn state() ?*State {
            return local.getOrCreate(State, &key, initialize);
        }
        fn host() sync.Host {
            return threads.host();
        }
        fn unlock(value: *State) void {
            if (value.mutex.unlock(&host()) != sync.success) @trap();
        }
        fn add(function: Function, argument: ?*anyopaque) bool {
            const value = state() orelse return false;
            const record: *Record = @ptrCast(@alignCast(Memory.malloc(@sizeOf(Record)) orelse return false));
            if (value.mutex.lock(&host(), sync.forever) != sync.success) {
                Memory.free(record);
                return false;
            }
            if (value.phase == .closed or value.pending == std.math.maxInt(usize)) {
                unlock(value);
                Memory.free(record);
                return false;
            }
            record.* = .{ .next = value.head, .function = function, .argument = argument };
            value.head = record;
            value.pending += 1;
            unlock(value);
            return true;
        }
        pub fn register(callback: Callback, argument: ?*anyopaque) bool {
            return add(.{ .context = callback }, argument);
        }
        pub fn registerPlain(callback: PlainCallback) bool {
            return add(.{ .plain = callback }, null);
        }
        pub fn pending() ?usize {
            const value = (local.lookup(State, &key) catch return null) orelse return 0;
            if (value.mutex.lock(&host(), sync.forever) != sync.success) return null;
            defer unlock(value);
            return value.pending;
        }
        /// Sequentially idempotent. Concurrent or recursive Finish reports busy;
        /// callbacks can register further callbacks, which run next in LIFO order.
        pub fn finish() bool {
            const value = state() orelse return false;
            if (value.mutex.lock(&host(), sync.forever) != sync.success) return false;
            if (value.phase != .open) {
                const closed = value.phase == .closed;
                unlock(value);
                return closed;
            }
            value.phase = .running;
            while (value.head) |record| {
                value.head = record.next;
                value.pending -= 1;
                const function = record.function;
                const argument = record.argument;
                unlock(value);
                Memory.free(record);
                switch (function) {
                    .plain => |callback| callback(),
                    .context => |callback| callback(argument),
                }
                // An integrity failure retains the running state rather than
                // allowing a second runner to claim successful completion.
                if (value.mutex.lock(&host(), sync.forever) != sync.success) return false;
            }
            value.phase = .closed;
            unlock(value);
            return true;
        }
    };
}
