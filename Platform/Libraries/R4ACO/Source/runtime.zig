// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const c = @import("r4l_contract");
const Alloc = *const fn (u64, u64, u64) callconv(.c) u64;
const Free = *const fn (u64, u64, u64, u64) callconv(.c) void;
const Clock = *const fn (u64) callconv(.c) u64;
const Abort = *const fn (u64, i32) callconv(.c) void;
const Retired = *const fn (u64, u64) callconv(.c) u32;
const Cancelled = *const fn (u64) callconv(.c) u32;
const Block = struct { previous: ?*Block, next: ?*Block, raw: u64, raw_size: u64, size: usize };
const Job = struct {
    runtime: c.R4AcoRuntime,
    request: c.R4AcoRequest,
    output: *c.R4AcoBinary,
    head: ?*Block = null,
    slots: [8]?*anyopaque = @splat(null),
    current: u64 = 0,
    start: u64,
    epoch: u64,
    keys: ?*Key = null,
    finalizers: ?*Finalizer = null,
    finalizer_count: u32 = 0,

    fn now(self: *const Job) u64 {
        const f: Clock = @ptrFromInt(self.runtime.clock_ns);
        return f(self.runtime.user);
    }
    fn check(self: *const Job) void {
        if (self.runtime.cancelled != 0) {
            const f: Cancelled = @ptrFromInt(self.runtime.cancelled);
            if (f(self.runtime.user) != 0) fail(c.status_cancelled);
        }
        if (self.request.deadline_ns != 0 and self.now() >= self.request.deadline_ns) fail(c.status_cancelled);
    }
    fn finish(self: *Job, status: i32) void {
        if (status == c.status_ok) {
            while (self.finalizers) |f| {
                self.finalizers = f.next;
                self.check();
                f.callback();
            }
        }
        self.output.status = status;
        self.output.elapsed_ns = self.now() -| self.start;
        while (self.head) |head| release(@ptrFromInt(@intFromPtr(head) + @sizeOf(Block)));
        active = null;
        owner.store(0, .release);
    }
};

const Key = struct { next: ?*Key, token: *const anyopaque, value: *anyopaque, size: usize, alignment: usize, ready: bool };
const Finalizer = struct { next: ?*Finalizer, callback: *const fn () callconv(.c) void };
// Protected by exclusive compiler admission; never a process-owned pointer.
var last_epoch: u64 = 0;

// The generation is resident, never a pointer into a terminated program.
// A new caller may reclaim only after its runtime proves exact retirement.
var owner: std.atomic.Value(u64) = .init(0);
var active: ?*Job = null;

fn fail(status: i32) noreturn {
    const job = active orelse @trap();
    const user = job.runtime.user;
    const abort_worker: Abort = @ptrFromInt(job.runtime.abort_worker);
    job.finish(status);
    // Do not unwind or resume abandoned C/C++ frames after retiring their heap.
    abort_worker(user, status);
    @trap(); // Callback contract violation; it must terminate the worker.
}

pub export fn r4aco_port_fail(status: i32) callconv(.c) noreturn {
    fail(if (status == c.status_memory or status == c.status_cancelled) status else c.status_compiler);
}
pub export fn r4aco_port_check() callconv(.c) void {
    const job = active orelse @trap();
    job.check();
}
pub export fn r4aco_port_epoch() callconv(.c) u64 {
    return (active orelse @trap()).epoch;
}
pub export fn r4aco_port_key(token: *const anyopaque, size: usize, alignment: usize, initial: ?[*]const u8, initialize: ?*const fn (*anyopaque) callconv(.c) void) callconv(.c) *anyopaque {
    const job = active orelse @trap();
    var it = job.keys;
    while (it) |key| : (it = key.next) {
        if (key.token != token) continue;
        if (!key.ready or key.size != size or key.alignment != alignment) fail(c.status_compiler);
        return key.value;
    }
    const key: *Key = @ptrCast(@alignCast(r4aco_port_allocate(@sizeOf(Key), @alignOf(Key))));
    const value = r4aco_port_allocate(size, alignment);
    const bytes = @as([*]u8, @ptrCast(value))[0..size];
    if (initial) |source| @memcpy(bytes, source[0..size]) else @memset(bytes, 0);
    key.* = .{ .next = job.keys, .token = token, .value = value, .size = size, .alignment = alignment, .ready = false };
    job.keys = key;
    if (initialize) |f| f(value);
    key.ready = true;
    return value;
}
pub export fn r4aco_port_finalizer(callback: *const fn () callconv(.c) void) callconv(.c) i32 {
    const job = active orelse @trap();
    if (job.finalizer_count >= 64) fail(c.status_compiler);
    const record: *Finalizer = @ptrCast(@alignCast(r4aco_port_allocate(@sizeOf(Finalizer), @alignOf(Finalizer))));
    record.* = .{ .next = job.finalizers, .callback = callback };
    job.finalizers = record;
    job.finalizer_count += 1;
    return 0;
}
pub export fn r4aco_port_allocate(size: usize, alignment: usize) callconv(.c) *anyopaque {
    const job = active orelse @trap();
    job.check();
    if (alignment == 0 or alignment > 1024 * 1024 or !std.math.isPowerOfTwo(alignment)) fail(c.status_compiler);
    const align_bytes = @max(alignment, @alignOf(Block));
    const overhead = std.math.add(usize, @sizeOf(Block), align_bytes - 1) catch fail(c.status_memory);
    const bytes = std.math.add(usize, @max(size, 1), overhead) catch fail(c.status_memory);
    if (bytes > job.request.budget_bytes -| job.current) fail(c.status_memory);
    const allocate: Alloc = @ptrFromInt(job.runtime.allocate);
    const raw = allocate(job.runtime.user, bytes, @alignOf(Block));
    if (raw == 0) fail(c.status_memory);
    const address = std.mem.alignForward(usize, raw + @sizeOf(Block), align_bytes);
    const block: *Block = @ptrFromInt(address - @sizeOf(Block));
    block.* = .{ .previous = null, .next = job.head, .raw = raw, .raw_size = bytes, .size = size };
    if (job.head) |head| head.previous = block;
    job.head = block;
    job.current += bytes;
    job.output.peak_bytes = @max(job.output.peak_bytes, job.current);
    return @ptrFromInt(address);
}
fn release(memory: *anyopaque) void {
    const job = active orelse @trap();
    const block: *Block = @ptrFromInt(@intFromPtr(memory) - @sizeOf(Block));
    if (block.previous) |p| p.next = block.next else job.head = block.next;
    if (block.next) |n| n.previous = block.previous;
    const free: Free = @ptrFromInt(job.runtime.release);
    job.current -= block.raw_size;
    free(job.runtime.user, block.raw, block.raw_size, @alignOf(Block));
}
pub export fn r4aco_port_deallocate(memory: ?*anyopaque) callconv(.c) void {
    if (memory) |p| release(p);
}
pub export fn r4aco_port_reallocate(memory: ?*anyopaque, size: usize) callconv(.c) *anyopaque {
    const result = r4aco_port_allocate(size, 16);
    if (memory) |p| {
        const previous: *const Block = @ptrFromInt(@intFromPtr(p) - @sizeOf(Block));
        const length = @min(previous.size, size);
        @memcpy(@as([*]u8, @ptrCast(result))[0..length], @as([*]const u8, @ptrCast(p))[0..length]);
        release(p);
    }
    return result;
}
pub export fn r4aco_port_state(slot: u32, size: usize, alignment: usize) callconv(.c) *anyopaque {
    const job = active orelse @trap();
    if (slot >= job.slots.len) fail(c.status_compiler);
    if (job.slots[slot] == null) {
        const p = r4aco_port_allocate(size, alignment);
        @memset(@as([*]u8, @ptrCast(p))[0..size], 0);
        job.slots[slot] = p;
    }
    return job.slots[slot].?;
}
pub export fn r4aco_port_clock() callconv(.c) u64 {
    const job = active orelse @trap();
    return job.now();
}
pub export fn r4aco_port_log(bytes: [*]const u8, length: usize) callconv(.c) void {
    const job = active orelse @trap();
    const used = job.output.log_length;
    const amount = @min(length, job.request.log_capacity -| used);
    if (amount != 0) {
        const output: [*]u8 = @ptrFromInt(job.request.log);
        @memcpy(output[used..][0..amount], bytes[0..amount]);
        job.output.log_length += amount;
    }
}

const Native = extern struct { metadata: c.R4AcoBinary, code: [*]const u8 };
extern fn r4aco_native_compile([*]const u32, usize, [*:0]const u8, u32, u32, u32, *Native) callconv(.c) i32;
extern fn r4aco_fp_begin(*[2]u64) callconv(.c) void;
extern fn r4aco_fp_end(*const [2]u64) callconv(.c) void;
comptime {
    _ = @import("r4native_math");
}

fn span(address: u64, size: u64, alignment: u64) bool {
    return address != 0 and address % alignment == 0 and size != 0 and address <= std.math.maxInt(u64) - size;
}
fn inputValid(request: *const c.R4AcoRequest) bool {
    if (request.version != 1 or request.size != @sizeOf(c.R4AcoRequest) or request.flags & ~@as(u32, 1) != 0 or
        request.word_count < 5 or request.word_count > 16384 or
        !span(request.words, @as(u64, request.word_count) * 4, 4) or
        request.entry_length == 0 or request.entry_length > 63 or !span(request.entry, request.entry_length, 1) or
        request.budget_bytes == 0 or request.budget_bytes > 256 * 1024 * 1024 or
        !span(request.code, request.code_capacity, 1) or request.code_capacity > 16 * 1024 * 1024 or
        (request.log_capacity != 0 and (!span(request.log, request.log_capacity, 1) or request.log_capacity > 1024 * 1024))) return false;
    const words: [*]const u32 = @ptrFromInt(request.words);
    if (words[0] != 0x07230203 or words[1] < 0x10000 or words[1] > 0x10600 or
        (words[1] & 0xff) != 0 or words[3] == 0 or words[3] > 16384 or words[4] != 0) return false;
    var i: usize = 5;
    while (i < request.word_count) {
        const count = words[i] >> 16;
        if (count == 0 or count > request.word_count - i) return false;
        i += count;
    }
    const entry: [*]const u8 = @ptrFromInt(request.entry);
    return std.mem.indexOfScalar(u8, entry[0..request.entry_length], 0) == null and std.unicode.utf8ValidateSlice(entry[0..request.entry_length]);
}

pub fn sourceHash(request: *const c.R4AcoRequest) c.R4AcoDigest {
    var hash: std.crypto.hash.sha2.Sha256 = .init(.{});
    hash.update("R4ACO-SPIRV-1");
    hash.update(std.mem.asBytes(&request.word_count));
    hash.update(std.mem.asBytes(&request.entry_length));
    const words: [*]const u8 = @ptrFromInt(request.words);
    const entry: [*]const u8 = @ptrFromInt(request.entry);
    hash.update(words[0 .. @as(usize, request.word_count) * 4]);
    hash.update(entry[0..request.entry_length]);
    hash.update(std.mem.asBytes(&request.stage));
    hash.update(std.mem.asBytes(&request.device_id));
    hash.update(std.mem.asBytes(&request.chip_revision));
    var result: c.R4AcoDigest = undefined;
    hash.final(@ptrCast(&result));
    return result;
}

fn outputsDisjoint(runtime: *const c.R4AcoRuntime, request: *const c.R4AcoRequest, output: *c.R4AcoBinary) bool {
    const Range = struct { address: usize, size: usize };
    const writes = [_]Range{
        .{ .address = request.code, .size = request.code_capacity },
        .{ .address = request.log, .size = request.log_capacity },
        .{ .address = @intFromPtr(output), .size = @sizeOf(c.R4AcoBinary) },
    };
    const reads = [_]Range{
        .{ .address = @intFromPtr(runtime), .size = @sizeOf(c.R4AcoRuntime) },
        .{ .address = @intFromPtr(request), .size = @sizeOf(c.R4AcoRequest) },
        .{ .address = request.words, .size = @as(usize, request.word_count) * 4 },
        .{ .address = request.entry, .size = request.entry_length },
    };
    for (writes, 0..) |w, i| {
        if (w.size == 0) continue;
        if (!span(w.address, w.size, 1)) return false;
        for (reads) |r| if (@import("cache.zig").overlaps(w.address, w.size, r.address, r.size)) return false;
        for (writes[0..i]) |r| if (r.size != 0 and @import("cache.zig").overlaps(w.address, w.size, r.address, r.size)) return false;
    }
    return true;
}

pub export fn r4aco_compile_impl(runtime: *const c.R4AcoRuntime, request: *const c.R4AcoRequest, output: *c.R4AcoBinary) callconv(.c) i32 {
    if (runtime.version != 1 or runtime.size != @sizeOf(c.R4AcoRuntime) or runtime.owner_generation == 0 or
        runtime.allocate == 0 or runtime.release == 0 or runtime.clock_ns == 0 or runtime.abort_worker == 0 or
        runtime.owner_retired == 0 or !inputValid(request) or !outputsDisjoint(runtime, request, output)) return c.status_invalid;
    const gfx_profile = @import("gpu_profile.zig").select(request.device_id, request.chip_revision) orelse return c.status_unsupported;
    if (request.stage != 0 and request.stage != 4 and request.stage != 5) return c.status_unsupported;
    if (owner.cmpxchgStrong(0, runtime.owner_generation, .acq_rel, .acquire)) |previous| {
        const retired: Retired = @ptrFromInt(runtime.owner_retired);
        if (retired(runtime.user, previous) != 1 or
            owner.cmpxchgStrong(previous, runtime.owner_generation, .acq_rel, .acquire) != null) return c.status_busy;
    }
    if (last_epoch == std.math.maxInt(u64)) {
        owner.store(0, .release);
        return c.status_compiler;
    }
    last_epoch += 1;
    output.* = std.mem.zeroes(c.R4AcoBinary);
    output.version = 1;
    output.size = @sizeOf(c.R4AcoBinary);
    output.status = c.status_compiler;
    output.device_id = request.device_id;
    output.chip_revision = request.chip_revision;
    output.gfx_profile = gfx_profile;
    output.resource_abi = 1 + request.flags;
    output.stage = request.stage;
    const clock: Clock = @ptrFromInt(runtime.clock_ns);
    var job: Job = .{ .runtime = runtime.*, .request = request.*, .output = output, .start = clock(runtime.user), .epoch = last_epoch };
    active = &job;
    job.check();
    output.source_hash = sourceHash(request);
    var entry: [64:0]u8 = @splat(0);
    @memcpy(entry[0..request.entry_length], @as([*]const u8, @ptrFromInt(request.entry))[0..request.entry_length]);
    var fp: [2]u64 = undefined;
    r4aco_fp_begin(&fp);
    defer r4aco_fp_end(&fp);
    var native: Native = undefined;
    const status = r4aco_native_compile(@ptrFromInt(request.words), request.word_count, &entry, request.stage, request.flags, gfx_profile, &native);
    job.check();
    if (status != c.status_ok) {
        job.finish(status);
        return status;
    }
    if (native.metadata.code_bytes > request.code_capacity) {
        job.finish(c.status_capacity);
        return c.status_capacity;
    }
    // Preserve accounting and diagnostics while publishing genuine upstream metadata.
    const saved = output.*;
    output.* = native.metadata;
    output.version = 1;
    output.size = @sizeOf(c.R4AcoBinary);
    output.device_id = request.device_id;
    output.chip_revision = request.chip_revision;
    output.stage = request.stage;
    output.gfx_profile = gfx_profile;
    output.resource_abi = 1 + request.flags;
    output.source_hash = saved.source_hash;
    output.peak_bytes = saved.peak_bytes;
    output.log_length = saved.log_length;
    const code: [*]u8 = @ptrFromInt(request.code);
    @memcpy(code[0..output.code_bytes], native.code[0..output.code_bytes]);
    job.finish(c.status_ok);
    return output.status;
}
