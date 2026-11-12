// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// NAK's Rust allocator needs an explicit, persistent owner. Each call runs
// on a disposable worker; Rust panic/OOM never unwinds through Mesa's C ABI.
const std = @import("std");
const r4os = @import("r4os");
const memory = @import("memory.zig");
const local = @import("process_local.zig");
const threads = @import("r4native").threads;
const sync = @import("r4native").threading;

pub const success: i32 = 0;
pub const out_of_memory: i32 = -1; // VkResult
pub const initialization_failed: i32 = -3;
pub const compiler_failed: i32 = -13;
pub const Callback = *const fn (?*anyopaque) callconv(.c) i32;
const Block = struct { previous: ?*Block, next: ?*Block, arena: *Arena, raw: *anyopaque, bytes: usize };
const Context = struct { mutex: sync.Mutex = .{}, calls: ?*Call = null, active_count: std.atomic.Value(usize) = .init(0), trace: @import("compiler_trace.zig").State = .{}, pm4_trace: @import("pm4_trace.zig").State = .{} };
const Call = struct {
    next: ?*Call = null,
    arena: *Arena,
    callback: Callback,
    argument: ?*anyopaque,
    thread: u32 = 0,
    status: i32 = compiler_failed,
    errno_value: c_int = 0,
    diagnostic_flags: [4096]u8 = undefined,
    diagnostic_enum: [64]u8 = undefined,
};
var context_key: u8 = 0;
fn init(value: *Context) void {
    value.* = .{};
    value.trace.init();
    value.pm4_trace.init();
}
fn context() ?*Context {
    return local.getOrCreate(Context, &context_key, init);
}
// Internal diagnostic entry, never an exported public library contract.
// The submit owner calls it before taking its residency/submission locks.
pub export fn r4vk_pm4_trace(engine: u32, group: u32, index: u32, count: u32, address: u64, words: [*]const u32, dwords: u32) callconv(.c) void {
    const ctx = context() orelse return;
    ctx.pm4_trace.record(engine, group, index, count, address, words, dwords);
}
fn require(result: c_int) void {
    if (result != sync.success) @trap();
}
fn currentThread() u32 {
    const function = threads.system.required("thread_current");
    return function();
}
fn maybeActive() ?*Call {
    const ctx = (local.lookup(Context, &context_key) catch @trap()) orelse return null;
    if (ctx.active_count.load(.acquire) == 0) return null;
    const id = currentThread();
    if (id == 0) @trap();
    require(threads.mtx_lock(&ctx.mutex));
    defer require(threads.mtx_unlock(&ctx.mutex));
    var it = ctx.calls;
    while (it) |call| : (it = call.next) if (call.thread == id) return call;
    return null;
}
fn active() *Call {
    return maybeActive() orelse @trap(); // No ambient Rust allocator.
}
pub fn allocationScope() ?*memory.Scope {
    const call = maybeActive() orelse return null;
    return if (call.arena.isolated) &call.arena.c_scope else null;
}
pub export fn r4vk_compiler_isolated() callconv(.c) bool {
    const call = maybeActive() orelse return false;
    return call.arena.isolated;
}
fn remove(call: *Call) void {
    const ctx = call.arena.context;
    require(threads.mtx_lock(&ctx.mutex));
    defer require(threads.mtx_unlock(&ctx.mutex));
    var at = &ctx.calls;
    while (at.*) |found| {
        if (found == call) {
            at.* = found.next;
            _ = ctx.active_count.fetchSub(1, .release);
            return;
        }
        at = &found.next;
    }
}
fn entry(argument: ?*anyopaque) callconv(.c) c_int {
    const call: *Call = @ptrCast(@alignCast(argument.?));
    const ctx = call.arena.context;
    call.thread = currentThread();
    if (call.thread == 0) return initialization_failed;
    const locked = threads.mtx_lock(&ctx.mutex);
    if (locked != sync.success) return if (locked == sync.nomem) out_of_memory else initialization_failed;
    call.next = ctx.calls;
    ctx.calls = call;
    _ = ctx.active_count.fetchAdd(1, .release);
    require(threads.mtx_unlock(&ctx.mutex));
    ctx.trace.mark(call.arena.trace_job, "worker-enter", call.thread);
    call.status = call.callback(call.argument);
    ctx.trace.mark(call.arena.trace_job, "worker-return", call.status);
    remove(call);
    ctx.trace.mark(call.arena.trace_job, "worker-unlinked", call.status);
    return call.status;
}

// The arena belongs to one process, may outlive several workers and has no
// shared-library BSS pointers. The owner must externally synchronize reads
// and destruction of its compiler. One arena admits at most one worker.
pub const Arena = struct {
    context: *Context,
    trace_job: u32 = 0,
    running: std.atomic.Value(bool) = .init(false),
    poisoned: bool = false,
    head: ?*Block = null,
    live_bytes: usize = 0,
    limit_bytes: usize,
    log: [1024]u8 = undefined,
    log_length: usize = 0,
    compiler: ?*anyopaque = null,
    isolated: bool = false,
    c_scope: memory.Scope = .{},
    states: [3]struct { pointer: ?*anyopaque = null, bytes: usize = 0, alignment: usize = 0 } = @splat(.{}),

    pub fn create(limit_bytes: usize) ?*Arena {
        const ctx = context() orelse return null;
        const result: *Arena = @ptrCast(@alignCast(memory.mallocUntracked(@sizeOf(Arena)) orelse return null));
        result.* = .{ .context = ctx, .trace_job = ctx.trace.nextJob(), .limit_bytes = limit_bytes, .c_scope = .{ .limit_bytes = limit_bytes } };
        return result;
    }
    pub fn run(self: *Arena, callback: Callback, argument: ?*anyopaque) i32 {
        if (self.running.cmpxchgStrong(false, true, .acq_rel, .acquire) != null) return initialization_failed;
        defer self.running.store(false, .release);
        if (self.poisoned) return compiler_failed;
        var call: Call = .{ .arena = self, .callback = callback, .argument = argument };
        var thread: r4os.abi.ProgramJoinHandle = .{};
        self.context.trace.mark(self.trace_job, "before-thread-create", 0);
        const created = threads.thrd_create(&thread, entry, &call);
        self.context.trace.mark(self.trace_job, "after-thread-create", created);
        if (created != sync.success) return if (created == sync.nomem) out_of_memory else initialization_failed;
        var code: c_int = compiler_failed;
        // Stack arguments and arena storage remain live until exact join.
        // A violated join contract cannot permit their premature release.
        self.context.trace.mark(self.trace_job, "before-thread-join", thread.thread_id);
        const joined = threads.thrd_join(thread, &code);
        self.context.trace.mark(self.trace_job, "after-thread-join", joined);
        require(joined);
        remove(&call); // Also covers a worker retired without normal return.
        if (code != success or call.status != success) {
            self.poisoned = true;
            return if (code == out_of_memory or call.status == out_of_memory) out_of_memory else compiler_failed;
        }
        return success;
    }
    pub fn destroy(self: *Arena) void {
        if (self.running.load(.acquire)) @trap();
        const ctx = self.context;
        const trace_job = self.trace_job;
        ctx.trace.mark(trace_job, "before-arena-destroy", @intCast(self.c_scope.live_bytes));
        self.c_scope.destroy();
        while (self.head) |block| {
            self.head = block.next;
            memory.free(block.raw);
        }
        memory.free(self);
        ctx.trace.mark(trace_job, "after-arena-destroy", 0);
    }
};

pub export fn r4nak_port_allocate(size: usize, alignment: usize) callconv(.c) *anyopaque {
    const arena = active().arena;
    if (alignment == 0 or !std.math.isPowerOfTwo(alignment)) r4nak_port_fail(3);
    const aligned = @max(alignment, @alignOf(Block));
    const overhead = std.math.add(usize, @sizeOf(Block), aligned - 1) catch r4nak_port_fail(2);
    const total = std.math.add(usize, @max(size, 1), overhead) catch r4nak_port_fail(2);
    if (total > arena.limit_bytes -| arena.live_bytes) r4nak_port_fail(2);
    const raw = memory.mallocUntracked(total) orelse r4nak_port_fail(2);
    const address = std.mem.alignForward(usize, @intFromPtr(raw) + @sizeOf(Block), aligned);
    const block: *Block = @ptrFromInt(address - @sizeOf(Block));
    block.* = .{ .previous = null, .next = arena.head, .arena = arena, .raw = raw, .bytes = total };
    if (arena.head) |head| head.previous = block;
    arena.head = block;
    arena.live_bytes += total;
    return @ptrFromInt(address);
}
pub export fn r4nak_port_deallocate(pointer: ?*anyopaque) callconv(.c) void {
    const address = pointer orelse return;
    const arena = active().arena;
    const block: *Block = @ptrFromInt(@intFromPtr(address) - @sizeOf(Block));
    if (block.arena != arena) r4nak_port_fail(3);
    if (block.previous) |previous| previous.next = block.next else arena.head = block.next;
    if (block.next) |next| next.previous = block.previous;
    arena.live_bytes -= block.bytes;
    memory.free(block.raw);
}
pub export fn r4nak_port_log(bytes: [*]const u8, length: usize) callconv(.c) void {
    const arena = active().arena;
    const count = @min(length, arena.log.len - arena.log_length);
    @memcpy(arena.log[arena.log_length..][0..count], bytes[0..count]);
    arena.log_length += count;
}
pub export fn r4nak_port_fail(reason: u32) callconv(.c) noreturn {
    const call = active();
    const status = if (reason == 2) out_of_memory else compiler_failed;
    call.status = status;
    remove(call);
    // Parent frees arena storage only after this worker has actually exited.
    threads.thrd_exit(status);
}

// Private C shader helpers share the admitted worker's error/diagnostic
// lifetime. No process-global errno or last-caller scratch pointer is stored.
pub export fn r4vk_compiler_errno() callconv(.c) *c_int {
    return &active().errno_value;
}
pub export fn r4vk_compiler_scratch(slot: u32) callconv(.c) [*]u8 {
    const call = active();
    return switch (slot) {
        0 => &call.diagnostic_flags,
        1 => &call.diagnostic_enum,
        else => @trap(),
    };
}
pub export fn r4vk_compiler_fail(reason: u32) callconv(.c) noreturn {
    r4nak_port_fail(reason);
}

// An isolated shader job substitutes its own GLSL/printf/diagnostic metadata.
// NIR is serialized from the immutable input and deserialized inside the job
// so no interned type from a different cache is mixed into its object graph.
pub export fn r4vk_compiler_state(slot: u32, bytes: usize, alignment: usize) callconv(.c) ?*anyopaque {
    const call = maybeActive() orelse return null;
    const arena = call.arena;
    if (!arena.isolated) return null;
    if (slot >= arena.states.len or bytes == 0 or alignment == 0 or !std.math.isPowerOfTwo(alignment)) r4nak_port_fail(3);
    const state = &arena.states[slot];
    if (state.pointer) |pointer| {
        if (state.bytes != bytes or state.alignment != alignment) r4nak_port_fail(3);
        return pointer;
    }
    const pointer = r4nak_port_allocate(bytes, alignment);
    @memset(@as([*]u8, @ptrCast(pointer))[0..bytes], 0);
    state.* = .{ .pointer = pointer, .bytes = bytes, .alignment = alignment };
    return pointer;
}
const Job = struct { callback: Callback, argument: ?*anyopaque, result: i32 = compiler_failed };
fn runJob(argument: ?*anyopaque) callconv(.c) i32 {
    const job: *Job = @ptrCast(@alignCast(argument.?));
    job.result = job.callback(job.argument);
    return success;
}
// A successful owner retains only CPU data for the caller to copy. No GPU
// allocation, callback-owned Vulkan object, or shared cache may be mutated
// inside this boundary. Failure leaves the owner output untouched.
pub export fn r4vk_compiler_job_run(callback: Callback, argument: ?*anyopaque, owner: **Arena) callconv(.c) i32 {
    const arena = Arena.create(std.math.maxInt(usize)) orelse return out_of_memory;
    arena.isolated = true;
    var job: Job = .{ .callback = callback, .argument = argument };
    const result = arena.run(runJob, &job);
    if (result != success or job.result != success) {
        arena.destroy();
        return if (result != success) result else job.result;
    }
    owner.* = arena;
    return success;
}
pub export fn r4vk_compiler_job_destroy(owner: *Arena) callconv(.c) void {
    owner.destroy();
}

extern fn nak_compiler_create(?*const anyopaque) callconv(.c) ?*anyopaque;
extern fn nak_compiler_destroy(*anyopaque) callconv(.c) void;
const Create = struct { info: *const anyopaque, compiler: ?*anyopaque = null };
// NIL image creation has no persistent Rust state. It uses a separate short
// lived arena so an invalid layout cannot poison a physical device's compiler.
// The C adapter publishes the calculated image only after successful join.
pub export fn r4vk_nil_run(callback: Callback, argument: ?*anyopaque) callconv(.c) i32 {
    const arena = Arena.create(std.math.maxInt(usize)) orelse return out_of_memory;
    defer arena.destroy();
    return arena.run(callback, argument);
}
fn createCompiler(argument: ?*anyopaque) callconv(.c) i32 {
    const data: *Create = @ptrCast(@alignCast(argument.?));
    data.compiler = nak_compiler_create(data.info) orelse return out_of_memory;
    return success;
}
fn destroyCompiler(argument: ?*anyopaque) callconv(.c) i32 {
    nak_compiler_destroy(argument.?);
    return success;
}
pub export fn r4vk_nak_create(info: ?*const anyopaque, owner: ?**Arena, compiler: ?**anyopaque) callconv(.c) i32 {
    if (info == null or owner == null or compiler == null) return initialization_failed;
    const arena = Arena.create(std.math.maxInt(usize)) orelse return out_of_memory;
    var data: Create = .{ .info = info.? };
    const status = arena.run(createCompiler, &data);
    if (status != success) {
        arena.destroy();
        return status;
    }
    arena.compiler = data.compiler;
    owner.?.* = arena;
    compiler.?.* = data.compiler.?;
    return success;
}
pub export fn r4vk_nak_destroy(arena: ?*Arena) callconv(.c) void {
    const owner = arena orelse return;
    if (owner.compiler) |compiler| {
        // The current NAK compiler contains CPU-owned Rust data only. If a
        // destructor worker cannot start, the arena still owns every block.
        _ = owner.run(destroyCompiler, compiler);
    }
    owner.destroy();
}
