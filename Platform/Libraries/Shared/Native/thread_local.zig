// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Clang emulated TLS storage for a shared native R4L. Descriptors remain
// immutable; all payload and indexing state belongs to the calling process.
const std = @import("std");
const r4os = @import("r4os");
const threads = @import("threads.zig");
const sync = @import("threading.zig");
const local = @import("process_local.zig");
const a = r4os.abi;

// compiler-rt's four-word __emutls_control ABI. object is deliberately unused:
// publishing an index/pointer there would mix callers of the same shared R4L.
pub const Control = extern struct {
    size: usize,
    alignment: usize,
    object: usize,
    default_value: ?[*]const u8,
};
comptime {
    std.debug.assert(@sizeOf(Control) == 32 and @offsetOf(Control, "default_value") == 24);
}
const Value = struct {
    next: ?*Value,
    control: *const Control,
    bytes: usize,
    alignment: std.mem.Alignment,
    address: *anyopaque,
};
const Tree = std.Treap(u64, std.math.order);
const Thread = struct {
    node: Tree.Node = undefined,
    identity: a.ProgramJoinHandle,
    values: ?*Value = null,
};
// This is a cache, never a capacity limit. Misses use the process-owned tree.
// Only the matching current thread can release its entry. Atomic sequence,
// tag and address avoid dereferencing any other thread's potentially freed
// pointer during cache collision/replacement. Hot hits take no userland lock.
const Cache = struct {
    sequence: std.atomic.Value(u64) = .init(0),
    generation: std.atomic.Value(u64) = .init(0),
    address: std.atomic.Value(usize) = .init(0),

    fn read(self: *const Cache, generation: u64) ?*Thread {
        const before = self.sequence.load(.seq_cst);
        if (before & 1 != 0) return null;
        const tag = self.generation.load(.seq_cst);
        const address = self.address.load(.seq_cst);
        const after = self.sequence.load(.seq_cst);
        if (before != after or tag != generation or address == 0) return null;
        return @ptrFromInt(address);
    }
    // Registry mutex serializes writers; release is performed by the entry's
    // actual thread only, after it has stopped using its TLS addresses.
    fn write(self: *Cache, generation: u64, address: usize) void {
        const sequence = self.sequence.load(.seq_cst);
        if (sequence > std.math.maxInt(u64) - 2) @trap();
        self.sequence.store(sequence + 1, .seq_cst);
        self.generation.store(generation, .seq_cst);
        self.address.store(address, .seq_cst);
        self.sequence.store(sequence + 2, .seq_cst);
    }
};
const Owner = struct {
    mutex: sync.Mutex = .{},
    heap: threads.system.Heap,
    tree: Tree = .{},
    cache: [64]Cache = .{Cache{}} ** 64,
    live_threads: usize = 0,
};
var owner_key: u8 = 0;
fn init(owner: *Owner) void {
    // No resources outside this region before process-local publication.
    owner.* = .{ .heap = undefined };
    owner.heap.init();
}
fn ownerContext() ?*Owner {
    return local.getOrCreate(Owner, &owner_key, init);
}
fn transport() sync.Host {
    return threads.host();
}
fn unlock(owner: *Owner) void {
    if (owner.mutex.unlock(&transport()) != sync.success) @trap();
}
fn cacheSlot(owner: *Owner, generation: u64) *Cache {
    return &owner.cache[generation % owner.cache.len];
}
fn current(owner: *Owner) ?*Thread {
    const identity = threads.thrd_current();
    if (identity.thread_generation == 0 or identity.instance_generation == 0) return null;
    const cached = cacheSlot(owner, identity.thread_generation);
    if (cached.read(identity.thread_generation)) |thread| return thread;
    if (owner.mutex.lock(&transport(), sync.forever) != sync.success) return null;
    defer unlock(owner);
    var entry = owner.tree.getEntryFor(identity.thread_generation);
    if (entry.node) |node| {
        const thread: *Thread = @fieldParentPtr("node", node);
        cached.write(identity.thread_generation, @intFromPtr(thread));
        return thread;
    }
    const thread = owner.heap.allocator().create(Thread) catch return null;
    thread.* = .{ .identity = identity };
    entry.set(&thread.node);
    owner.live_threads += 1;
    cached.write(identity.thread_generation, @intFromPtr(thread));
    return thread;
}

// Null reports invalid descriptors, allocation failure or missing native
// context. The language ABI adapter owns its failure policy; no fake TLS or
// shared emergency buffer is returned. Repeated lookup preserves the address.
/// Lookup without creating a thread record or allocating a TLS value.
/// Only the actual current thread may read or release its values.
pub fn existingAddress(control: *const Control) error{Unavailable}!?*anyopaque {
    const owner = (try local.lookup(Owner, &owner_key)) orelse return null;
    const identity = threads.thrd_current();
    if (identity.thread_generation == 0) return error.Unavailable;
    if (owner.mutex.lock(&transport(), sync.forever) != sync.success) return error.Unavailable;
    const entry = owner.tree.getEntryFor(identity.thread_generation);
    const node = entry.node orelse {
        unlock(owner);
        return null;
    };
    const thread: *Thread = @fieldParentPtr("node", node);
    unlock(owner);
    var value = thread.values;
    while (value) |existing| : (value = existing.next) {
        if (existing.control == control) return existing.address;
    }
    return null;
}
pub fn hasCurrent() error{Unavailable}!bool {
    const owner = (try local.lookup(Owner, &owner_key)) orelse return false;
    const identity = threads.thrd_current();
    if (identity.thread_generation == 0) return error.Unavailable;
    if (owner.mutex.lock(&transport(), sync.forever) != sync.success) return error.Unavailable;
    defer unlock(owner);
    return owner.tree.getEntryFor(identity.thread_generation).node != null;
}

pub fn getAddress(control: *const Control) ?*anyopaque {
    if (control.size == 0 or control.alignment == 0 or !std.math.isPowerOfTwo(control.alignment)) return null;
    const owner = ownerContext() orelse return null;
    const thread = current(owner) orelse return null;
    var value = thread.values;
    while (value) |existing| : (value = existing.next) {
        if (existing.control == control) return existing.address;
    }
    const alignment = @max(control.alignment, @alignOf(Value));
    const padding = std.math.add(usize, @sizeOf(Value), alignment - 1) catch return null;
    const offset = padding & ~(alignment - 1);
    const bytes = std.math.add(usize, offset, control.size) catch return null;
    const mem_alignment: std.mem.Alignment = .fromByteUnits(alignment);
    const raw = owner.heap.allocator().rawAlloc(bytes, mem_alignment, @returnAddress()) orelse return null;
    const data = raw[offset..][0..control.size];
    if (control.default_value) |template| @memcpy(data, template[0..control.size]) else @memset(data, 0);
    const created: *Value = @ptrCast(@alignCast(raw));
    created.* = .{ .next = thread.values, .control = control, .bytes = bytes, .alignment = mem_alignment, .address = data.ptr };
    thread.values = created;
    return created.address;
}

// The caller first unbinds its language/API objects (e.g. eglReleaseThread).
// This releases only raw TLS storage, never invokes foreign destructors, and
// may be repeated. Later use creates fresh storage with the original template.
// Unexpected process death is covered by the normal process VM reaper.
pub fn releaseCurrent() bool {
    const owner = (local.lookup(Owner, &owner_key) catch return false) orelse return true;
    const identity = threads.thrd_current();
    if (identity.thread_generation == 0) return false;
    if (owner.mutex.lock(&transport(), sync.forever) != sync.success) return false;
    var entry = owner.tree.getEntryFor(identity.thread_generation);
    const node = entry.node orelse {
        unlock(owner);
        return true;
    };
    const thread: *Thread = @fieldParentPtr("node", node);
    const cached = cacheSlot(owner, identity.thread_generation);
    if (cached.generation.load(.seq_cst) == identity.thread_generation) cached.write(0, 0);
    entry.set(null);
    owner.live_threads -= 1;
    unlock(owner);
    const allocator = owner.heap.allocator();
    var value = thread.values;
    while (value) |existing| {
        const next = existing.next;
        const raw: [*]u8 = @ptrCast(existing);
        const bytes = existing.bytes;
        const alignment = existing.alignment;
        allocator.rawFree(raw[0..bytes], alignment, @returnAddress());
        value = next;
    }
    allocator.destroy(thread);
    return true;
}

pub fn liveThreadCount() ?usize {
    const owner = (local.lookup(Owner, &owner_key) catch return null) orelse return 0;
    if (owner.mutex.lock(&transport(), sync.forever) != sync.success) return null;
    defer unlock(owner);
    return owner.live_threads;
}
