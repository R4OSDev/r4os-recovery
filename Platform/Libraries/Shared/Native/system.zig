// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Only immutable boot-lifetime platform tables are shared. Caller identities,
// startup views and mutable native state remain process-owned.
const std = @import("std");
const r = @import("r4os");
const a = r.abi;
const a2 = r.platform2.abi;
var generation2_address: std.atomic.Value(usize) = .init(0);

pub fn reaches(table: anytype, comptime field: []const u8) bool {
    const T = @TypeOf(table.*);
    const expected: T = .{};
    const end = @offsetOf(T, field) + 8;
    return table.magic == expected.magic and table.abi_version >= 1 and table.size >= end and
        @addWithOverflow(@intFromPtr(table), end)[1] == 0 and @field(table.*, field) != 0;
}
fn complete(table: anytype) bool {
    inline for (.{ "write", "task_yield", "sleep_ticks", "thread_create_handle", "thread_handle_join", "thread_current", "thread_status", "thread_exit", "thread_current_handle", "monotonic_clock", "notification_create", "notification_query", "notification_notify", "notification_wait", "notification_close", "program_local_get", "program_local_publish", "vm_reserve", "vm_commit", "vm_decommit", "vm_release" }) |field|
        if (!reaches(table, field)) return false;
    return true;
}
pub fn bind2(table: *const a2.R4XStartR4Sys2) bool {
    if (!complete(table)) return false;
    const old = generation2_address.cmpxchgStrong(0, @intFromPtr(table), .release, .acquire);
    return old == null or old.? == @intFromPtr(table);
}
pub fn generation2() ?*const a2.R4XStartR4Sys2 {
    const address = generation2_address.load(.acquire);
    return if (address == 0) null else @ptrFromInt(address);
}
// Resolve only actual current offsets. Callback payload revisions are independent.
pub const bind = bind2;
pub fn function(comptime field: []const u8) ?@field(a.R4SysFns, field) {
    const table = generation2() orelse return null;
    return if (reaches(table, field)) @ptrFromInt(@field(table.*, field)) else null;
}
pub fn required(comptime field: []const u8) @field(a.R4SysFns, field) {
    return function(field) orelse @trap();
}
pub const Heap = struct {
    mapped: r.vm_allocator.MappedHeap = undefined,
    pub fn init(self: *Heap) void {
        self.mapped.init(generation2() orelse @trap());
    }
    pub fn allocator(self: *Heap) std.mem.Allocator {
        return self.mapped.allocator();
    }
    pub fn stats(self: *Heap) r.vm_allocator.Stats {
        return self.mapped.stats();
    }
    pub fn trim(self: *Heap) void {
        self.mapped.trim();
    }
};
