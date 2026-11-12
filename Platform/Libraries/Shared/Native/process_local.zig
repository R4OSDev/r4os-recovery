// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Mutable native-library state belongs to the calling process. Only the
// address of the key is shared; the kernel publishes one resident context.
const std = @import("std");
const r4os = @import("r4os");
const a = r4os.abi;
const threads = @import("threads.zig");

fn function(comptime name: []const u8) @field(a.R4SysFns, name) {
    return threads.system.required(name);
}

pub fn lookup(comptime T: type, key: *const anyopaque) error{Unavailable}!?*T {
    var value: u64 = 0;
    if (function("program_local_get")(@intFromPtr(key), &value) != a.program_local_ok)
        return error.Unavailable;
    return if (value == 0) null else @ptrFromInt(value);
}

// init runs before publication without any kernel owner lock. It must not
// recursively look up its own key or acquire resources outside the region:
// a losing candidate is simply released. Process retirement owns the region;
// there is no destructor callback into an unloaded library.
pub fn getOrCreate(comptime T: type, key: *const anyopaque, comptime init: fn (*T) void) ?*T {
    if (lookup(T, key) catch return null) |existing| return existing;
    const bytes = comptime std.mem.alignForward(usize, @sizeOf(T), 4096);
    comptime std.debug.assert(@sizeOf(T) > 0 and @alignOf(T) <= 4096 and bytes <= a.vm_commit_resident_max_bytes);
    var region: a.ProgramVmRegionInfo = .{};
    if (function("vm_reserve")(bytes, 4096, a.vm_region_flags_default, &region) != a.vm_ok) return null;
    if (region.id == 0 or region.base == 0 or region.base % 4096 != 0 or region.len < bytes) @trap();
    if (function("vm_commit")(region.id, 0, bytes, a.vm_commit_flag_resident) != a.vm_ok) {
        _ = function("vm_release")(region.id);
        return null;
    }
    const candidate: *T = @ptrFromInt(region.base);
    init(candidate);
    var value: u64 = 0;
    const result = function("program_local_publish")(@intFromPtr(key), region.base, &value);
    if (result == a.program_local_ok) {
        if (value != region.base) @trap();
        return candidate;
    }
    // A failed release stays in the process VM ledger for its normal reaper.
    _ = function("vm_release")(region.id);
    return if (result == a.program_local_existing and value != 0) @ptrFromInt(value) else null;
}

const Blob = extern struct { bytes: usize, alignment: usize, offset: usize };
// C owns the layout of these private Mesa objects. A distinct immutable key
// identifies each layout; publication owns the region until process retirement.
pub fn ensureBlob(key: *const anyopaque, bytes: usize, alignment: usize) callconv(.c) bool {
    if (bytes == 0 or alignment == 0 or alignment > 4096 or !std.math.isPowerOfTwo(alignment)) return false;
    if (lookup(Blob, key) catch return false) |existing|
        return existing.bytes == bytes and existing.alignment == alignment;
    const offset = std.mem.alignForward(usize, @sizeOf(Blob), alignment);
    const needed = std.math.add(usize, offset, bytes) catch return false;
    if (needed > a.vm_commit_resident_max_bytes) return false;
    const committed = std.mem.alignForward(usize, needed, 4096);
    var region: a.ProgramVmRegionInfo = .{};
    if (function("vm_reserve")(committed, 4096, a.vm_region_flags_default, &region) != a.vm_ok) return false;
    var published = false;
    defer if (!published) {
        _ = function("vm_release")(region.id);
    };
    if (region.id == 0 or region.base == 0 or region.base % 4096 != 0 or region.len < committed) @trap();
    if (function("vm_commit")(region.id, 0, committed, a.vm_commit_flag_resident) != a.vm_ok) return false;
    const data: [*]u8 = @ptrFromInt(region.base);
    @memset(data[0..committed], 0);
    const candidate: *Blob = @ptrFromInt(region.base);
    candidate.* = .{ .bytes = bytes, .alignment = alignment, .offset = offset };
    var value: u64 = 0;
    const status = function("program_local_publish")(@intFromPtr(key), region.base, &value);
    if (status == a.program_local_ok) {
        if (value != region.base) @trap();
        published = true;
        return true;
    }
    if (status != a.program_local_existing or value == 0) return false;
    const winner: *const Blob = @ptrFromInt(value);
    return winner.bytes == bytes and winner.alignment == alignment;
}

pub fn getBlob(key: *const anyopaque) callconv(.c) ?*anyopaque {
    const blob = (lookup(Blob, key) catch return null) orelse return null;
    return @ptrFromInt(@intFromPtr(blob) + blob.offset);
}

pub const Initializer = *const fn (*anyopaque) callconv(.c) void;
const Initialized = extern struct { once: threads.Once };
const InitCall = struct { callback: Initializer, payload: *anyopaque };

fn initializePublished(argument: ?*const anyopaque) callconv(.c) void {
    const call: *const InitCall = @ptrCast(@alignCast(argument.?));
    call.callback(call.payload);
}

// Only the zero storage is published before initialization. Every consumer of
// this private key must use this accessor. The winner runs init synchronously
// after publication, so C++ construction may allocate other resources without
// leaking them from a losing candidate. Recursive lookup of this key is invalid.
// The layout and callback are immutable properties of the owner's unique key.
pub fn initializedBlob(key: *const anyopaque, bytes: usize, alignment: usize, callback: Initializer) ?*anyopaque {
    if (bytes == 0 or alignment == 0 or alignment > 4096 or !std.math.isPowerOfTwo(alignment)) return null;
    const storage_alignment = @max(alignment, @alignOf(Initialized));
    const offset = std.mem.alignForward(usize, @sizeOf(Initialized), alignment);
    const total = std.math.add(usize, offset, bytes) catch return null;
    const blob = (lookup(Blob, key) catch return null) orelse blk: {
        if (!ensureBlob(key, total, storage_alignment)) return null;
        break :blk (lookup(Blob, key) catch return null) orelse return null;
    };
    if (blob.bytes != total or blob.alignment != storage_alignment) return null;
    const storage: *Initialized = @ptrFromInt(@intFromPtr(blob) + blob.offset);
    const payload: *anyopaque = @ptrFromInt(@intFromPtr(storage) + offset);
    const call: InitCall = .{ .callback = callback, .payload = payload };
    threads.util_call_once_data_slow(&storage.once, initializePublished, &call);
    return payload;
}
