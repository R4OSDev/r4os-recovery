//! Module-local C/Rust entry points into the existing SDK VM allocator.
//! Linked into each R4X, never a shared R4L-global heap or a kernel allocator.
const std = @import("std");
const abi = @import("r4os_contract").abi;
const vm = @import("vm_allocator.zig");
const allocator_source = @import("allocator_source.zig");
const Memory = allocator_source.Memory;
const Source = allocator_source.Source;

const ok = 0;
const invalid = -1;
const wrong_owner = -2;
const closed = -3;
const busy = 1;
const pending = 2;
const header_magic: u64 = 0x3150414548345253;
const Header = struct {
    magic: u64,
    instance: u64,
    requested: usize,
    alignment: usize,
    buffer_len: usize,
};
const stats_fields = std.meta.fields(vm.Stats);
comptime {
    if (stats_fields.len > 64) @compileError("Review SDK heap snapshot capacity");
}

// 0=new, 1=binding, 2=open, 3=allocation admission closed (free allowed),
// 4=exclusive teardown, 5=all region/notification release acknowledgements.
var phase: u32 = 0;
var calls: u32 = 0;
var bound_api: usize = 0;
var bound_instance: u64 = 0;
var bound_generation: u64 = 0;
// Published together with the one existing heap binding. No caller record is
// retained, and no second allocator, pool or owner registry is introduced.
var bound_memory: Memory = .{};

fn current(api: anytype, instance: u64) ?abi.ProgramJoinHandle {
    const source = Source.from(api);
    if (comptime @TypeOf(api) == *const abi.R4XStartR4Sys) {
        const expected: abi.R4XStartR4Sys = .{};
        if (api.magic != expected.magic or api.abi_version < expected.abi_version or
            api.size < @sizeOf(abi.R4XStartR4Sys)) return null;
    } else {
        if (!api.valid()) return null;
    }
    if (instance == 0 or !source.supportsVm()) return null;
    const get = source.function("thread_current_handle") orelse return null;
    var handle: abi.ProgramJoinHandle = .{};
    if (get(&handle) != 0 or handle.instance_id != instance or handle.instance_generation == 0) return null;
    return handle;
}

fn identityMatches(api: anytype) bool {
    if (bound_api != Source.from(api).identity()) return false;
    if (comptime @TypeOf(api) == *const Memory)
        return std.mem.eql(u8, std.mem.asBytes(api), std.mem.asBytes(&bound_memory));
    return true;
}

fn heapAllocator(api: anytype) std.mem.Allocator {
    if (comptime @TypeOf(api) == *const Memory) return vm.allocatorMapped(&bound_memory);
    return vm.allocator(api);
}

fn heapBind(api: anytype, instance: u64) i32 {
    const handle = current(api, instance) orelse return wrong_owner;
    if (@cmpxchgStrong(u32, &phase, 0, 1, .acquire, .monotonic) == null) {
        if (comptime @TypeOf(api) == *const Memory) bound_memory = api.*;
        bound_api = Source.from(api).identity();
        bound_instance = instance;
        bound_generation = handle.instance_generation;
        @atomicStore(u32, &phase, 2, .release);
        return ok;
    }
    const state = @atomicLoad(u32, &phase, .acquire);
    if (state == 1) return busy;
    if (!identityMatches(api) or bound_instance != instance or bound_generation != handle.instance_generation) return wrong_owner;
    return if (state == 2) ok else closed;
}

fn enter(api: anytype, instance: u64, allocation: bool) i32 {
    const state = @atomicLoad(u32, &phase, .acquire);
    if (state != 2 and (allocation or state != 3)) return closed;
    const handle = current(api, instance) orelse return wrong_owner;
    if (!identityMatches(api) or bound_instance != instance or bound_generation != handle.instance_generation) return wrong_owner;
    while (true) {
        const previous = @atomicLoad(u32, &calls, .acquire);
        if (previous == std.math.maxInt(u32)) return busy;
        if (@cmpxchgWeak(u32, &calls, previous, previous + 1, .acq_rel, .acquire) == null) break;
    }
    const admitted = @atomicLoad(u32, &phase, .acquire);
    if (admitted != 2 and (allocation or admitted != 3)) {
        leave();
        return closed;
    }
    return ok;
}
fn leave() void {
    const previous = @atomicRmw(u32, &calls, .Sub, 1, .release);
    if (previous == 0) @trap();
}

fn layout(size: usize, raw_alignment: usize) ?struct { total: usize, alignment: std.mem.Alignment } {
    if (size == 0 or raw_alignment == 0 or !std.math.isPowerOfTwo(raw_alignment)) return null;
    const alignment = @max(@alignOf(Header), raw_alignment);
    const prefix = std.math.add(usize, @sizeOf(Header) + @sizeOf(usize), alignment - 1) catch return null;
    const total = std.math.add(usize, prefix, size) catch return null;
    if (total > std.math.maxInt(isize)) return null;
    return .{ .total = total, .alignment = .fromByteUnits(alignment) };
}

fn allocate(api: anytype, instance: u64, size: usize, alignment: usize) ?*anyopaque {
    const l = layout(size, alignment) orelse return null;
    const buffer = heapAllocator(api).rawAlloc(l.total, l.alignment, @returnAddress()) orelse return null;
    const base = @intFromPtr(buffer);
    const user = std.mem.alignForward(usize, base + @sizeOf(Header) + @sizeOf(usize), l.alignment.toByteUnits());
    const header: *Header = @ptrCast(@alignCast(buffer));
    header.* = .{ .magic = header_magic, .instance = instance, .requested = size, .alignment = l.alignment.toByteUnits(), .buffer_len = l.total };
    const backref: *usize = @ptrFromInt(user - @sizeOf(usize));
    backref.* = base;
    return @ptrFromInt(user);
}
fn headerFor(pointer: *anyopaque, instance: u64) ?*Header {
    const user = @intFromPtr(pointer);
    if (user < @sizeOf(Header) + @sizeOf(usize) or user % @alignOf(usize) != 0) return null;
    const backref: *const usize = @ptrFromInt(user - @sizeOf(usize));
    if (backref.* == 0 or backref.* % @alignOf(Header) != 0) return null;
    const header: *Header = @ptrFromInt(backref.*);
    if (header.magic != header_magic or header.instance != instance or
        !std.math.isPowerOfTwo(header.alignment) or user % header.alignment != 0) return null;
    const end = std.math.add(usize, user, header.requested) catch return null;
    const buffer_end = std.math.add(usize, backref.*, header.buffer_len) catch return null;
    if (user < backref.* + @sizeOf(Header) + @sizeOf(usize) or end > buffer_end) return null;
    return header;
}
fn release(api: anytype, header: *Header) void {
    const len = header.buffer_len;
    const alignment: std.mem.Alignment = .fromByteUnits(header.alignment);
    const buffer: [*]u8 = @ptrCast(header);
    header.magic = 0;
    // The core owns pending/cache/partial VM releases after logical free.
    // No access to this payload follows the handoff.
    heapAllocator(api).rawFree(buffer[0..len], alignment, @returnAddress());
}

fn heapAlloc(api: anytype, instance: u64, size: usize, alignment: usize) ?*anyopaque {
    if (enter(api, instance, true) != ok) return null;
    defer leave();
    return allocate(api, instance, size, alignment);
}
fn heapFree(api: anytype, instance: u64, pointer: ?*anyopaque) i32 {
    const p = pointer orelse return ok;
    const result = enter(api, instance, false);
    if (result != ok) return result;
    defer leave();
    const header = headerFor(p, instance) orelse return invalid;
    release(api, header);
    return ok;
}
fn heapRealloc(api: anytype, instance: u64, pointer: ?*anyopaque, size: usize, alignment: usize) ?*anyopaque {
    if (size == 0) {
        _ = heapFree(api, instance, pointer);
        return null;
    }
    if (enter(api, instance, true) != ok) return null;
    defer leave();
    const p = pointer orelse return allocate(api, instance, size, alignment);
    const header = headerFor(p, instance) orelse return null;
    const l = layout(size, alignment) orelse return null;
    if (l.alignment.toByteUnits() == header.alignment) {
        const buffer: [*]u8 = @ptrCast(header);
        if (heapAllocator(api).rawResize(buffer[0..header.buffer_len], l.alignment, l.total, @returnAddress())) {
            header.buffer_len = l.total;
            header.requested = size;
            return p;
        }
    }
    const next = allocate(api, instance, size, alignment) orelse return null;
    const src: [*]const u8 = @ptrCast(p);
    const dst: [*]u8 = @ptrCast(next);
    @memcpy(dst[0..@min(header.requested, size)], src[0..@min(header.requested, size)]);
    release(api, header);
    return next;
}
fn heapStats(api: anytype, instance: u64, values: [*]u64, capacity: u32) i32 {
    const result = enter(api, instance, false);
    if (result != ok) return result;
    defer leave();
    if (capacity < stats_fields.len) return invalid;
    const snapshot = vm.stats();
    inline for (stats_fields, 0..) |field, i| values[i] = @field(snapshot, field.name);
    return @intCast(stats_fields.len);
}
export fn R4SdkHeapStatName(index: u32) callconv(.c) ?[*:0]const u8 {
    inline for (stats_fields, 0..) |field, i| if (i == index) return field.name ++ "\x00";
    return null;
}
fn heapFinish(api: anytype, instance: u64) i32 {
    const state = @atomicLoad(u32, &phase, .acquire);
    if (state == 5) {
        const handle = current(api, instance) orelse return wrong_owner;
        return if (identityMatches(api) and bound_instance == instance and bound_generation == handle.instance_generation) ok else wrong_owner;
    }
    const admitted = enter(api, instance, false);
    if (admitted != ok) return admitted;
    _ = @cmpxchgStrong(u32, &phase, 2, 3, .acq_rel, .acquire);
    leave();
    if (@cmpxchgStrong(u32, &phase, 3, 4, .acq_rel, .acquire) != null) return busy;
    if (@atomicLoad(u32, &calls, .acquire) != 0) {
        @atomicStore(u32, &phase, 3, .release);
        return busy;
    }
    const result = if (comptime @TypeOf(api) == *const Memory) vm.shutdownMapped(&bound_memory) else vm.shutdown(api);
    @atomicStore(u32, &phase, if (result == .done) 5 else 3, .release);
    return switch (result) {
        .done => ok,
        .busy => busy,
        .pending => pending,
    };
}

export fn R4SdkHeapBind(api: *const abi.R4XStartR4Sys, instance: u64) callconv(.c) i32 {
    return heapBind(api, instance);
}

export fn R4SdkHeapBind2(api: *const Memory, instance: u64) callconv(.c) i32 {
    return heapBind(api, instance);
}

// GlobalAlloc keeps this resident, immutable SDK copy rather than a root App
// loan. It remains pinned by the exact module until actual task retirement.
export fn R4SdkHeapMemory2(api: *const Memory, instance: u64) callconv(.c) ?*const Memory {
    if (enter(api, instance, false) != ok) return null;
    defer leave();
    return &bound_memory;
}

export fn R4SdkHeapAlloc(api: *const abi.R4XStartR4Sys, instance: u64, size: usize, alignment: usize) callconv(.c) ?*anyopaque {
    return heapAlloc(api, instance, size, alignment);
}

export fn R4SdkHeapAlloc2(api: *const Memory, instance: u64, size: usize, alignment: usize) callconv(.c) ?*anyopaque {
    return heapAlloc(api, instance, size, alignment);
}

export fn R4SdkHeapFree(api: *const abi.R4XStartR4Sys, instance: u64, pointer: ?*anyopaque) callconv(.c) i32 {
    return heapFree(api, instance, pointer);
}

export fn R4SdkHeapFree2(api: *const Memory, instance: u64, pointer: ?*anyopaque) callconv(.c) i32 {
    return heapFree(api, instance, pointer);
}

export fn R4SdkHeapRealloc(api: *const abi.R4XStartR4Sys, instance: u64, pointer: ?*anyopaque, size: usize, alignment: usize) callconv(.c) ?*anyopaque {
    return heapRealloc(api, instance, pointer, size, alignment);
}

export fn R4SdkHeapRealloc2(api: *const Memory, instance: u64, pointer: ?*anyopaque, size: usize, alignment: usize) callconv(.c) ?*anyopaque {
    return heapRealloc(api, instance, pointer, size, alignment);
}

export fn R4SdkHeapStats(api: *const abi.R4XStartR4Sys, instance: u64, values: [*]u64, capacity: u32) callconv(.c) i32 {
    return heapStats(api, instance, values, capacity);
}

export fn R4SdkHeapStats2(api: *const Memory, instance: u64, values: [*]u64, capacity: u32) callconv(.c) i32 {
    return heapStats(api, instance, values, capacity);
}

export fn R4SdkHeapFinish(api: *const abi.R4XStartR4Sys, instance: u64) callconv(.c) i32 {
    return heapFinish(api, instance);
}

export fn R4SdkHeapFinish2(api: *const Memory, instance: u64) callconv(.c) i32 {
    return heapFinish(api, instance);
}

// A corrupt heap terminates the exact module. No foreign unwind or HLT loop.
pub const panic = std.debug.FullPanic(struct {
    fn panic(_: []const u8, _: ?usize) noreturn {
        const address = @atomicLoad(usize, &bound_api, .acquire);
        if (address != 0) {
            const source = if (address & 1 != 0) Source.mapped(&bound_memory) else Source{ .encoded = address };
            if (source.function("program_exit")) |exit| {
                _ = exit(-103, abi.program_exit_reason_failed);
            }
        }
        @trap();
    }
}.panic);
