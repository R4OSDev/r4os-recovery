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
    runtime: c.R4NakRuntime,
    request: c.R4NakRequest,
    output: *c.R4NakBinary,
    head: ?*Block = null,
    slots: [8]?*anyopaque = @splat(null),
    current: u64 = 0,
    start: u64,

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
        self.output.status = status;
        self.output.elapsed_ns = self.now() -| self.start;
        while (self.head) |head| release(@ptrFromInt(@intFromPtr(head) + @sizeOf(Block)));
        active = null;
        owner.store(0, .release);
    }
};

// The generation is resident, never a pointer into a terminated program.
// A new caller may reclaim only after its runtime proves exact retirement.
var owner: std.atomic.Value(u64) = .init(0);
var active: ?*Job = null;

fn fail(status: i32) noreturn {
    const job = active orelse @trap();
    const user = job.runtime.user;
    const abort_worker: Abort = @ptrFromInt(job.runtime.abort_worker);
    job.finish(status);
    // Do not longjmp/unwind/resume the suspended Rust/C compiler frames.
    abort_worker(user, status);
    @trap(); // Callback contract violation; it must terminate the worker.
}

pub export fn r4nak_port_fail(reason: u32) callconv(.c) noreturn {
    fail(if (reason == 2) c.status_memory else c.status_compiler);
}
pub export fn r4nak_port_allocate(size: usize, alignment: usize) callconv(.c) *anyopaque {
    const job = active orelse @trap();
    job.check();
    if (alignment == 0 or !std.math.isPowerOfTwo(alignment)) fail(c.status_compiler);
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
pub export fn r4nak_port_deallocate(memory: ?*anyopaque) callconv(.c) void {
    if (memory) |p| release(p);
}
pub export fn r4nak_port_reallocate(memory: ?*anyopaque, size: usize) callconv(.c) *anyopaque {
    const result = r4nak_port_allocate(size, 16);
    if (memory) |p| {
        const previous: *const Block = @ptrFromInt(@intFromPtr(p) - @sizeOf(Block));
        const length = @min(previous.size, size);
        @memcpy(@as([*]u8, @ptrCast(result))[0..length], @as([*]const u8, @ptrCast(p))[0..length]);
        release(p);
    }
    return result;
}
pub export fn r4nak_port_state(slot: u32, size: usize, alignment: usize) callconv(.c) *anyopaque {
    const job = active orelse @trap();
    if (slot >= job.slots.len) fail(c.status_compiler);
    if (job.slots[slot] == null) {
        const p = r4nak_port_allocate(size, alignment);
        @memset(@as([*]u8, @ptrCast(p))[0..size], 0);
        job.slots[slot] = p;
    }
    return job.slots[slot].?;
}
pub export fn r4nak_port_clock() callconv(.c) u64 {
    const job = active orelse @trap();
    return job.now();
}
pub export fn r4nak_port_log(bytes: [*]const u8, length: usize) callconv(.c) void {
    const job = active orelse @trap();
    const used = job.output.log_length;
    const amount = @min(length, job.request.log_capacity -| used);
    if (amount != 0) {
        const output: [*]u8 = @ptrFromInt(job.request.log);
        @memcpy(output[used..][0..amount], bytes[0..amount]);
        job.output.log_length += amount;
    }
}

const Native = extern struct {
    header: [32]u32,
    sm: u32,
    stage: u32,
    gprs: u32,
    instructions: u32,
    code_bytes: u32,
    slm_bytes: u32,
    crs_bytes: u32,
    control_barriers: u32,
    max_warps: u32,
    reserved: u32,
    code: [*]const u8,
};
extern fn r4nak_native_compile([*]const u32, usize, [*:0]const u8, u32, u32, *Native) callconv(.c) i32;

fn span(address: u64, size: u64, alignment: u64) bool {
    return address != 0 and address % alignment == 0 and size != 0 and address <= std.math.maxInt(u64) - size;
}
fn inputValid(request: *const c.R4NakRequest) bool {
    if (request.version != 1 or request.size != @sizeOf(c.R4NakRequest) or
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

pub fn sourceHash(request: *const c.R4NakRequest) c.R4NakDigest {
    var hash: std.crypto.hash.sha2.Sha256 = .init(.{});
    hash.update("R4NAK-SPIRV-1");
    hash.update(std.mem.asBytes(&request.word_count));
    hash.update(std.mem.asBytes(&request.entry_length));
    const words: [*]const u8 = @ptrFromInt(request.words);
    const entry: [*]const u8 = @ptrFromInt(request.entry);
    hash.update(words[0 .. @as(usize, request.word_count) * 4]);
    hash.update(entry[0..request.entry_length]);
    hash.update(std.mem.asBytes(&request.stage));
    hash.update(std.mem.asBytes(&request.sm));
    var result: c.R4NakDigest = undefined;
    hash.final(@ptrCast(&result));
    return result;
}

fn outputsDisjoint(runtime: *const c.R4NakRuntime, request: *const c.R4NakRequest, output: *c.R4NakBinary) bool {
    const Range = struct { address: usize, size: usize };
    const writes = [_]Range{
        .{ .address = request.code, .size = request.code_capacity },
        .{ .address = request.log, .size = request.log_capacity },
        .{ .address = @intFromPtr(output), .size = @sizeOf(c.R4NakBinary) },
    };
    const reads = [_]Range{
        .{ .address = @intFromPtr(runtime), .size = @sizeOf(c.R4NakRuntime) },
        .{ .address = @intFromPtr(request), .size = @sizeOf(c.R4NakRequest) },
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

pub export fn r4nak_compile_impl(runtime: *const c.R4NakRuntime, request: *const c.R4NakRequest, output: *c.R4NakBinary) callconv(.c) i32 {
    if (runtime.version != 1 or runtime.size != @sizeOf(c.R4NakRuntime) or runtime.owner_generation == 0 or
        runtime.allocate == 0 or runtime.release == 0 or runtime.clock_ns == 0 or runtime.abort_worker == 0 or
        runtime.owner_retired == 0 or !inputValid(request) or !outputsDisjoint(runtime, request, output)) return c.status_invalid;
    if ((request.sm != 75 and request.sm != 86 and request.sm != 89 and request.sm != 120) or
        (request.stage != 0 and request.stage != 4 and request.stage != 5)) return c.status_unsupported;
    if (owner.cmpxchgStrong(0, runtime.owner_generation, .acq_rel, .acquire)) |previous| {
        const retired: Retired = @ptrFromInt(runtime.owner_retired);
        if (retired(runtime.user, previous) != 1 or
            owner.cmpxchgStrong(previous, runtime.owner_generation, .acq_rel, .acquire) != null) return c.status_busy;
    }
    output.* = std.mem.zeroes(c.R4NakBinary);
    output.version = 1;
    output.size = @sizeOf(c.R4NakBinary);
    output.status = c.status_compiler;
    output.sm = request.sm;
    output.stage = request.stage;
    const clock: Clock = @ptrFromInt(runtime.clock_ns);
    var job: Job = .{ .runtime = runtime.*, .request = request.*, .output = output, .start = clock(runtime.user) };
    active = &job;
    job.check();
    output.source_hash = sourceHash(request);
    var entry: [64:0]u8 = @splat(0);
    @memcpy(entry[0..request.entry_length], @as([*]const u8, @ptrFromInt(request.entry))[0..request.entry_length]);
    var native: Native = undefined;
    const status = r4nak_native_compile(@ptrFromInt(request.words), request.word_count, &entry, request.stage, request.sm, &native);
    job.check();
    if (status != 0) {
        job.finish(if (status == -2) c.status_unsupported else c.status_invalid);
        return output.status;
    }
    if (native.code_bytes > request.code_capacity) {
        job.finish(c.status_capacity);
        return c.status_capacity;
    }
    const code: [*]u8 = @ptrFromInt(request.code);
    @memcpy(code[0..native.code_bytes], native.code[0..native.code_bytes]);
    @memcpy(std.mem.asBytes(&output.header), std.mem.asBytes(&native.header));
    inline for (.{ "gprs", "instructions", "code_bytes", "slm_bytes", "crs_bytes", "control_barriers", "max_warps" }) |field| @field(output, field) = @field(native, field);
    job.finish(c.status_ok);
    return c.status_ok;
}
