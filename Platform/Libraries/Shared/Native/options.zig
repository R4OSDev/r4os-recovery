// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Stable native option strings belong to the calling process. Consumers choose
// an ordinary process-owned malloc/free backend, never a compiler job arena.
const std = @import("std");
const local = @import("process_local.zig");
const process = @import("process.zig");
const threads = @import("threads.zig");
const sync = @import("threading.zig");

pub const Error = error{ OutOfMemory, Unavailable, Invalid, Closed };
pub const Stats = struct { values: u32, cached_names: u32, closed: bool };

// R4SYS environment names are case-insensitive. Value bytes remain exact.
const NameContext = struct {
    pub fn hash(_: @This(), key: []const u8) u64 {
        var value: u64 = 14695981039346656037;
        for (key) |byte| value = (value ^ std.ascii.toUpper(byte)) *% 1099511628211;
        return value;
    }
    pub fn eql(_: @This(), left: []const u8, right: []const u8) bool {
        return std.ascii.eqlIgnoreCase(left, right);
    }
};

pub fn Runtime(comptime Memory: type) type {
    return struct {
        const Names = std.HashMapUnmanaged([]const u8, ?[:0]const u8, NameContext, 80);
        const Values = std.StringHashMapUnmanaged([:0]const u8);
        const State = struct {
            mutex: sync.Mutex = .{},
            closed: std.atomic.Value(bool) = .init(false),
            names: Names = .{},
            values: Values = .{},
        };
        var state_key: u8 = 0;
        fn init(owner: *State) void { owner.* = .{}; }
        fn state() Error!*State {
            return local.getOrCreate(State, &state_key, init) orelse error.Unavailable;
        }
        fn lock(owner: *State) Error!void {
            if (owner.closed.load(.acquire)) return error.Closed;
            if (threads.mtx_lock(&owner.mutex) != sync.success) return error.Unavailable;
            if (owner.closed.load(.acquire)) {
                unlock(owner);
                return error.Closed;
            }
        }
        fn unlock(owner: *State) void {
            if (threads.mtx_unlock(&owner.mutex) != sync.success) @trap();
        }

        // Adapt the consumer's C heap so the same allocation failure/lifetime
        // policy covers option maps and strings. No second hidden VM heap.
        const Alloc = struct {
            fn allocate(_: *anyopaque, len: usize, alignment: std.mem.Alignment, _: usize) ?[*]u8 {
                const bytes = alignment.toByteUnits();
                const pointer = if (bytes <= 16) Memory.malloc(len) else blk: {
                    const padded = std.math.add(usize, len, bytes - 1) catch return null;
                    break :blk Memory.aligned_alloc(bytes, padded & ~(bytes - 1));
                };
                return @ptrCast(pointer orelse return null);
            }
            fn release(_: *anyopaque, bytes: []u8, _: std.mem.Alignment, _: usize) void {
                Memory.free(bytes.ptr);
            }
            const vtable: std.mem.Allocator.VTable = .{
                .alloc = allocate, .resize = std.mem.Allocator.noResize,
                .remap = std.mem.Allocator.noRemap, .free = release,
            };
        };
        fn allocator() std.mem.Allocator { return .{ .ptr = &state_key, .vtable = &Alloc.vtable }; }

        // Publish all new strings/cache entries only after every fallible step.
        // A failed reserve may retain reusable map capacity, never a new entry
        // or a false cached absence. All temporary strings are released.
        fn publish(owner: *State, name: [:0]const u8, value: ?[]const u8, cached: bool) Error!?[:0]const u8 {
            const alloc = allocator();
            var result: ?[:0]const u8 = null;
            var new_value: ?[:0]u8 = null;
            var new_name: ?[:0]u8 = null;
            errdefer if (new_value) |text| alloc.free(text);
            errdefer if (new_name) |text| alloc.free(text);
            if (value) |text| {
                result = owner.values.get(text);
                if (result == null) {
                    new_value = try alloc.dupeZ(u8, text);
                    result = new_value;
                }
            }
            if (cached) new_name = try alloc.dupeZ(u8, name);
            if (new_value != null) try owner.values.ensureUnusedCapacity(alloc, 1);
            if (cached) try owner.names.ensureUnusedCapacity(alloc, 1);
            if (new_value) |text| owner.values.putAssumeCapacityNoClobber(text, text);
            if (new_name) |text| owner.names.putAssumeCapacityNoClobber(text, result);
            return result;
        }

        fn read(owner: *State, name: [:0]const u8, cached: bool) Error!?[:0]const u8 {
            var small: [256]u8 = undefined;
            var buffer: []u8 = &small;
            var allocated: ?[]u8 = null;
            const alloc = allocator();
            defer if (allocated) |bytes| alloc.free(bytes);
            while (true) {
                const value = process.environmentValue(name.ptr, buffer) catch |err| switch (err) {
                    error.NotFound => return publish(owner, name, null, cached),
                    error.BufferTooSmall => {
                        const next_len = std.math.mul(usize, buffer.len, 2) catch return error.OutOfMemory;
                        const next = try alloc.alloc(u8, next_len);
                        if (allocated) |bytes| alloc.free(bytes);
                        allocated = next;
                        buffer = next;
                        continue;
                    },
                    error.Unavailable => return error.Unavailable,
                    error.Invalid => return error.Invalid,
                };
                return publish(owner, name, value, cached);
            }
        }

        // Refreshes the environment value, but previously returned strings stay
        // valid. Equal value bytes reuse one immutable allocation per process.
        pub fn get(name: [:0]const u8) Error!?[:0]const u8 {
            const owner = try state();
            try lock(owner);
            defer unlock(owner);
            return read(owner, name, false);
        }

        // The first successful read is fixed, including a genuine absence.
        // Transient read/allocation failures are retryable, not negative entries.
        pub fn getCached(name: [:0]const u8) Error!?[:0]const u8 {
            const owner = try state();
            try lock(owner);
            defer unlock(owner);
            if (owner.names.getEntry(name)) |entry| return entry.value_ptr.*;
            return read(owner, name, true);
        }

        pub fn stats() Error!Stats {
            const owner = (local.lookup(State, &state_key) catch return error.Unavailable) orelse
                return .{ .values = 0, .cached_names = 0, .closed = false };
            if (owner.closed.load(.acquire)) return .{ .values = 0, .cached_names = 0, .closed = true };
            try lock(owner);
            defer unlock(owner);
            return .{ .values = owner.values.count(), .cached_names = owner.names.count(), .closed = false };
        }

        // Consumer calls after ALL users and final Mesa callbacks have stopped.
        // No pointers may survive this boundary. Sequential repetition is safe;
        // subsequent reads return Closed and cannot silently create new state.
        // Forced process termination is still covered by the kernel VM reaper.
        pub fn closeAfterUsersStop() bool {
            const owner = state() catch return false;
            if (owner.closed.load(.acquire)) return true;
            lock(owner) catch return false;
            const alloc = allocator();
            var names = owner.names.keyIterator();
            while (names.next()) |name| alloc.free(name.*[0 .. name.*.len + 1]);
            var values = owner.values.valueIterator();
            while (values.next()) |value| alloc.free(value.*);
            owner.names.deinit(alloc);
            owner.values.deinit(alloc);
            owner.closed.store(true, .release);
            unlock(owner);
            threads.mtx_destroy(&owner.mutex);
            return true;
        }
    };
}
