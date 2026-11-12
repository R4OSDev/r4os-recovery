// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const r = @import("r4os");
const threads = @import("threads.zig");
const local = @import("process_local.zig");
const caller = @import("caller.zig");
const State = struct {
    phase: std.atomic.Value(u32) = .init(0),
    caller: caller.Snapshot = undefined,
};
var key: u8 = 0;
fn initialize(value: *State) void {
    value.* = .{};
}

/// Retains only a process-owned startup snapshot and immutable platform tables.
/// The app's import table follows its ordinary program lifetime. No caller
/// Bundle, stack context or GUI object survives this call.
pub fn bind(raw: *const r.abi.R4XStartContext) bool {
    return bindAddress(@intFromPtr(raw));
}
pub fn bind2(raw: *const r.platform2.abi.R4XStartContext2) bool {
    return bindAddress(@intFromPtr(raw));
}
pub fn bindAddress(address: u64) bool {
    const candidate = caller.Input.init(address) catch return false;
    const correct_system = switch (candidate) {
        .legacy => |view| view.sys != null and view.sys == threads.system.legacy(),
        .generation2 => |view| view.system() == threads.system.generation2(),
    };
    if (!correct_system or candidate.instance() != threads.thrd_current().instance_id) return false;
    const value = local.getOrCreate(State, &key, initialize) orelse return false;
    if (value.phase.cmpxchgStrong(0, 1, .acq_rel, .acquire) == null) {
        value.caller.init(candidate);
        value.phase.store(2, .release);
    } else while (value.phase.load(.acquire) != 2) threads.thrd_yield();
    return value.caller.matches(candidate);
}
pub fn snapshot() ?*const caller.Snapshot {
    const value = (local.lookup(State, &key) catch return null) orelse return null;
    return if (value.phase.load(.acquire) == 2) &value.caller else null;
}
pub fn bundle() ?*const r.program.Bundle {
    const saved = snapshot() orelse return null;
    return switch (saved.*) {
        .legacy => &saved.legacy.bundle,
        .generation2 => null,
    };
}
