// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const r = @import("r4os");
const local = @import("process_local.zig");
const tls = @import("thread_local.zig");
const threads = @import("threads.zig");
const sync = @import("threading.zig");

/// Memory is the consumer's ordinary process heap, never a compiler-job arena.
/// release_api_thread runs after language destructors and before raw TLS release.
/// Its code and all registered destructors stay pinned for the process lifetime.
pub fn Runtime(comptime Memory: type, comptime release_api_thread: fn () bool) type {
    return struct {
        const Tree = std.Treap(u64, std.math.order);
        const State = struct {
            mutex: sync.Mutex = .{},
            accepting: bool = true,
            workers: usize = 0,
            tree: Tree = .{},
        };
        const Start = struct {
            node: Tree.Node = undefined,
            owner: *State,
            entry: threads.Entry,
            argument: ?*anyopaque,
        };
        const Destructor = struct {
            next: ?*Destructor,
            callback: *const fn (?*anyopaque) callconv(.c) void,
            argument: ?*anyopaque,
        };
        const ThreadState = struct { head: ?*Destructor = null, finishing: bool = false };
        const control: tls.Control = .{
            .size = @sizeOf(ThreadState),
            .alignment = @alignOf(ThreadState),
            .object = 0,
            .default_value = null,
        };
        const dispatch: threads.Lifecycle = .{ .create = create, .finish_current = finishCurrent };
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
        pub fn bind() bool {
            return threads.bindLifecycle(&dispatch);
        }

        pub fn create(output: *r.abi.ProgramJoinHandle, entry: threads.Entry, argument: ?*anyopaque) c_int {
            const value = state() orelse return sync.nomem;
            const start: *Start = @ptrCast(@alignCast(Memory.malloc(@sizeOf(Start)) orelse return sync.nomem));
            start.* = .{ .owner = value, .entry = entry, .argument = argument };
            if (value.mutex.lock(&host(), sync.forever) != sync.success) {
                Memory.free(start);
                return sync.failed;
            }
            if (!value.accepting or value.workers == std.math.maxInt(usize)) {
                unlock(value);
                Memory.free(start);
                return sync.failed;
            }
            value.workers += 1; // Includes admission until the child publishes its exact identity.
            unlock(value);
            const result = threads.createRaw(output, worker, start);
            if (result != sync.success) {
                if (value.mutex.lock(&host(), sync.forever) != sync.success) @trap();
                value.workers -= 1;
                unlock(value);
                Memory.free(start);
            }
            return result;
        }
        fn worker(argument: ?*anyopaque) callconv(.c) c_int {
            const start: *Start = @ptrCast(@alignCast(argument.?));
            const value = start.owner;
            const identity = threads.thrd_current();
            if (identity.thread_generation == 0 or value.mutex.lock(&host(), sync.forever) != sync.success) @trap();
            var entry = value.tree.getEntryFor(identity.thread_generation);
            if (entry.node != null) @trap();
            entry.set(&start.node);
            unlock(value);
            const result = start.entry(start.argument);
            if (!finishCurrent()) @trap();
            return result;
        }

        pub fn registerDestructor(callback: *const fn (?*anyopaque) callconv(.c) void, argument: ?*anyopaque) bool {
            const current: *ThreadState = @ptrCast(@alignCast(tls.getAddress(&control) orelse return false));
            const record: *Destructor = @ptrCast(@alignCast(Memory.malloc(@sizeOf(Destructor)) orelse return false));
            record.* = .{ .next = current.head, .callback = callback, .argument = argument };
            current.head = record;
            return true;
        }
        pub fn finishCurrent() bool {
            var current: ?*ThreadState = null;
            var released = false;
            defer if (!released) {
                if (current) |value| value.finishing = false;
            };
            while (true) {
                if (tls.existingAddress(&control) catch return false) |pointer| {
                    const value: *ThreadState = @ptrCast(@alignCast(pointer));
                    if (current == null and value.finishing) return false;
                    current = value;
                    value.finishing = true;
                    // Pop/free before callback. A destructor may register another
                    // one; no registry or stream lock spans foreign code.
                    while (value.head) |record| {
                        value.head = record.next;
                        const callback = record.callback;
                        const argument = record.argument;
                        Memory.free(record);
                        callback(argument);
                    }
                }
                if ((tls.hasCurrent() catch return false) and !release_api_thread()) return false;
                // API cleanup can initialize another language TLS object. Drain
                // its destructor too and unbind any API context it recreates.
                const pointer = (tls.existingAddress(&control) catch return false) orelse break;
                const value: *ThreadState = @ptrCast(@alignCast(pointer));
                if (value.head == null) break;
            }
            if (!tls.releaseCurrent()) return false;
            released = true;
            const value = (local.lookup(State, &key) catch return false) orelse return true;
            const identity = threads.thrd_current();
            if (identity.thread_generation == 0 or value.mutex.lock(&host(), sync.forever) != sync.success) return false;
            var entry = value.tree.getEntryFor(identity.thread_generation);
            const node = entry.node orelse {
                unlock(value);
                return true;
            };
            const start: *Start = @fieldParentPtr("node", node);
            entry.set(null);
            value.workers -= 1;
            unlock(value);
            Memory.free(start);
            return true;
        }
        /// Close admission before joining/draining all existing workers. A zero
        /// count is a userland-cleanup boundary; actual retirement still needs join.
        pub fn closeAdmission() bool {
            const value = state() orelse return false;
            if (value.mutex.lock(&host(), sync.forever) != sync.success) return false;
            value.accepting = false;
            unlock(value);
            return true;
        }
        pub fn liveWorkers() ?usize {
            const value = (local.lookup(State, &key) catch return null) orelse return 0;
            if (value.mutex.lock(&host(), sync.forever) != sync.success) return null;
            defer unlock(value);
            return value.workers;
        }
    };
}
