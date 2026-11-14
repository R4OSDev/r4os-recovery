const abi = @import("r4os_contract").abi;
const allocator_source = @import("allocator_source.zig");
const Source = allocator_source.Source;
const std = @import("std");
const wait = @import("allocator_wait.zig");

const Alignment = std.mem.Alignment;

const page_size: usize = 4096;
const small_region_reserve: usize = 64 * 1024 * 1024;
const small_region_initial_commit: usize = 64 * 1024;
const small_region_max_grow: usize = 1024 * 1024;
const small_region_retain: usize = 256 * 1024;
const small_region_decommit_threshold: usize = 512 * 1024;
const large_threshold: usize = 1024 * 1024;
const direct_cache_first_size: usize = 2 * 1024 * 1024;
const direct_cache_class_count: usize = 3;
const direct_cache_max_region: usize = direct_cache_first_size << (direct_cache_class_count - 1);
const direct_cache_max_bytes: usize = direct_cache_first_size * ((1 << direct_cache_class_count) - 1);
const max_small_regions: usize = 32;
const block_magic: u32 = 0x33414D52; // "RMA3"
const retired_block_magic: u32 = 0x58414D52; // "RMAX"
const footer_magic: u32 = 0x33464D52; // "RMF3"
const block_flag_used: u32 = 1 << 0;
const block_flag_direct: u32 = 1 << 1;
const block_flag_listed: u32 = 1 << 2;
const valid_block_flags: u32 = block_flag_used | block_flag_direct | block_flag_listed;

const BlockHeader = extern struct {
    magic: u32 = block_magic,
    flags: u32 = 0,
    region_id: u32 = 0,
    reserved: u32 = 0,
    block_size: usize = 0,
    requested_size: usize = 0,
    user_addr: usize = 0,
    free_previous: usize = 0,
    free_next: usize = 0,
};

const BlockFooter = extern struct {
    magic: u32 = footer_magic,
    reserved: u32 = 0,
    block_size: usize = 0,
};

const FreeLinks = extern struct {
    previous: usize = 0,
    next: usize = 0,
};

const min_free_block_unaligned = @sizeOf(BlockHeader) + @sizeOf(usize) + 1 + @sizeOf(BlockFooter);
const min_free_block: usize = (min_free_block_unaligned + @alignOf(BlockHeader) - 1) & ~@as(usize, @alignOf(BlockHeader) - 1);
const first_size_class_limit: usize = 128;
const size_class_count: usize = 20;

comptime {
    if (min_free_block > first_size_class_limit) @compileError("first VM allocator size class is smaller than a free block");
    if ((first_size_class_limit << (size_class_count - 1)) < small_region_reserve) @compileError("VM allocator size classes do not cover a small region");
    if (small_region_initial_commit < min_free_block or small_region_retain < small_region_initial_commit) @compileError("invalid VM allocator small-region retention policy");
    if (direct_cache_max_bytes > 16 * 1024 * 1024) @compileError("direct VM cache exceeds its per-process RAM budget");
}

const SmallRegion = struct {
    used: bool = false,
    region_id: u32 = 0,
    base: usize = 0,
    reserve_size: usize = 0,
    committed_size: usize = 0,
    next_commit_size: usize = small_region_initial_commit,
    pending_decommit_offset: usize = 0,
    pending_decommit_len: usize = 0,
    active_allocations: u32 = 0,
    allocations: u64 = 0,
    frees: u64 = 0,
    active_bytes: u64 = 0,
    peak_active_bytes: u64 = 0,
    decommits: u64 = 0,
    free_heads: [size_class_count]usize = .{0} ** size_class_count,
};

const DirectCacheEntry = struct {
    used: bool = false,
    region_id: u32 = 0,
    base: usize = 0,
    reserve_size: usize = 0,
    alignment: usize = 0,
    retiring: bool = false,
};

const State = struct {
    allocator_lock: u32 = 0,
    wait_api: usize = 0,
    lock_wait: wait.Channel = .{},
    vm_wait: wait.Channel = .{},
    vm_operation: u64 = 0,
    next_vm_operation: u64 = 0,
    preparing_slot: ?usize = null,
    retired_reservation: ?abi.ProgramVmRegionInfo = null,
    retiring_direct: ?DirectRetirement = null,
    retiring_direct_head: usize = 0,
    direct_retiring: u32 = 0,
    small_regions: [max_small_regions]SmallRegion = .{SmallRegion{}} ** max_small_regions,
    direct_cache: [direct_cache_class_count]DirectCacheEntry = .{DirectCacheEntry{}} ** direct_cache_class_count,
    direct_active: u32 = 0,
    direct_cached: u32 = 0,
    direct_allocations: u64 = 0,
    direct_frees: u64 = 0,
    direct_active_bytes: u64 = 0,
    direct_peak_active_bytes: u64 = 0,
    active_bytes: u64 = 0,
    peak_active_bytes: u64 = 0,
    direct_reserved_bytes: u64 = 0,
    direct_cached_bytes: u64 = 0,
    peak_committed_bytes: u64 = 0,
    direct_cache_hits: u64 = 0,
    direct_cache_misses: u64 = 0,
    direct_cache_evictions: u64 = 0,
    trim_calls: u64 = 0,
    trim_reclaimed_bytes: u64 = 0,
    allocation_errors: u64 = 0,
    allocation_search_steps: u64 = 0,
    class_search_steps: u64 = 0,
    backward_search_steps: u64 = 0,
    end_search_steps: u64 = 0,
    splits: u64 = 0,
    coalesces: u64 = 0,
    corruptions: u64 = 0,
    vm_reserve_calls: u64 = 0,
    vm_commit_calls: u64 = 0,
    vm_decommit_calls: u64 = 0,
    vm_decommit_bytes: u64 = 0,
    vm_release_calls: u64 = 0,
};

const DirectRetirement = struct {
    region_id: u32,
    base: usize,
    reserve_size: usize,
    requested_size: usize,
    user_addr: usize,
};

const FreeAction = union(enum) { small: usize, direct: DirectRetirement };

pub const Stats = struct {
    small_regions: u32 = 0,
    direct_active: u32 = 0,
    direct_cached: u32 = 0,
    active_allocations: u64 = 0,
    direct_retiring: u32 = 0,
    allocations: u64 = 0,
    frees: u64 = 0,
    active_bytes: u64 = 0,
    /// Historical maximum of all simultaneously active allocations in this heap.
    peak_active_bytes: u64 = 0,
    /// Largest single small region or direct allocation aggregate peak.
    peak_region_active_bytes: u64 = 0,
    reserved_bytes: u64 = 0,
    committed_bytes: u64 = 0,
    peak_committed_bytes: u64 = 0,
    cached_bytes: u64 = 0,
    decommits: u64 = 0,
    allocation_errors: u64 = 0,
    allocation_search_steps: u64 = 0,
    class_search_steps: u64 = 0,
    backward_search_steps: u64 = 0,
    end_search_steps: u64 = 0,
    splits: u64 = 0,
    coalesces: u64 = 0,
    corruptions: u64 = 0,
    direct_cache_hits: u64 = 0,
    direct_cache_misses: u64 = 0,
    direct_cache_evictions: u64 = 0,
    trim_calls: u64 = 0,
    trim_reclaimed_bytes: u64 = 0,
    vm_reserve_calls: u64 = 0,
    vm_commit_calls: u64 = 0,
    vm_decommit_calls: u64 = 0,
    vm_decommit_bytes: u64 = 0,
    vm_release_calls: u64 = 0,
};

const AllocationLayout = struct {
    user_addr: usize,
    backref_addr: usize,
    allocated_size: usize,
    remaining_size: usize,
};

const DirectActivation = struct {
    entry: DirectCacheEntry,
    layout: AllocationLayout,
};

var state: State = .{};

const vtable = AllocatorContext(.default).vtable;

/// Caller-owned VM heap for shared runtime libraries. Keep this object at a
/// stable address until every allocation and concurrent caller has retired.
/// The existing per-R4X default below remains independent of explicit heaps.
pub const Heap = struct {
    api: *const @import("r4os_contract2").R4XStartR4Sys2,
    storage: State = .{},

    pub fn allocator(self: *Heap) std.mem.Allocator {
        return .{ .ptr = self, .vtable = &AllocatorContext(.legacy).vtable };
    }
    pub fn stats(self: *Heap) Stats {
        return stateStats(&self.storage);
    }
    pub fn trim(self: *Heap) void {
        stateTrim(&self.storage, self.api);
    }
};

/// An explicit shared-library heap whose callbacks were admitted from the
/// actual Context2. The copied mapping and all heap metadata belong to this
/// stable object; no caller stack or fabricated legacy table is retained.
pub const MappedHeap = struct {
    memory: allocator_source.Memory,
    storage: State = .{},

    pub fn init(self: *MappedHeap, table: *const @import("r4os_contract2").R4XStartR4Sys2) void {
        self.* = .{ .memory = allocator_source.Memory.fromSystem2(table) };
    }

    pub fn allocator(self: *MappedHeap) std.mem.Allocator {
        return .{ .ptr = self, .vtable = &AllocatorContext(.mapped).vtable };
    }
    pub fn stats(self: *MappedHeap) Stats {
        return stateStats(&self.storage);
    }
    pub fn trim(self: *MappedHeap) void {
        stateTrim(&self.storage, &self.memory);
    }
};

fn AllocatorContext(comptime explicit: enum { default, legacy, mapped }) type {
    return struct {
        const vtable: std.mem.Allocator.VTable = .{
            .alloc = alloc,
            .resize = resize,
            .remap = remap,
            .free = free,
        };
        fn storage(ptr: *anyopaque) *State {
            if (explicit != .default) {
                const Owner = if (explicit == .legacy) Heap else MappedHeap;
                const value: *Owner = @ptrCast(@alignCast(ptr));
                return &value.storage;
            }
            return &state;
        }
        fn api(ptr: *anyopaque) *anyopaque {
            if (explicit == .legacy) {
                const value: *Heap = @ptrCast(@alignCast(ptr));
                return @constCast(value.api);
            }
            if (explicit == .mapped) {
                const value: *MappedHeap = @ptrCast(@alignCast(ptr));
                return Source.mapped(&value.memory).toOpaque();
            }
            return ptr;
        }
        fn alloc(ptr: *anyopaque, len: usize, alignment: Alignment, ret: usize) ?[*]u8 {
            return allocatorAlloc(storage(ptr), api(ptr), len, alignment, ret);
        }
        fn resize(ptr: *anyopaque, memory: []u8, alignment: Alignment, len: usize, ret: usize) bool {
            return allocatorResize(storage(ptr), api(ptr), memory, alignment, len, ret);
        }
        fn remap(ptr: *anyopaque, memory: []u8, alignment: Alignment, len: usize, ret: usize) ?[*]u8 {
            return allocatorRemap(storage(ptr), api(ptr), memory, alignment, len, ret);
        }
        fn free(ptr: *anyopaque, memory: []u8, alignment: Alignment, ret: usize) void {
            allocatorFree(storage(ptr), api(ptr), memory, alignment, ret);
        }
    };
}

pub fn stats() Stats {
    return stateStats(&state);
}
pub fn trim(api: *const @import("r4os_contract2").R4XStartR4Sys2) void {
    stateTrim(&state, api);
}

pub const Shutdown = enum { done, busy, pending };

/// Irreversible teardown for an externally closed, quiescent R4X heap.
/// No allocation/resize may enter after this call, even when a VM release
/// fails: that release may already have unmapped part of its exact region.
/// Live allocations return busy; callers must allow their frees and retry.
/// The normal Zig allocator and its trim policy do not call this path.
pub fn shutdown(api: *const @import("r4os_contract2").R4XStartR4Sys2) Shutdown {
    const result = shutdownState(&state, api);
    if (result != .done) return result;
    state.lock_wait.prune(api);
    state.vm_wait.prune(api);
    return if (state.lock_wait.handle == 0 and state.vm_wait.handle == 0) .done else .pending;
}

fn shutdownState(heap_state: *State, api: anytype) Shutdown {
    acquireAllocatorLock(heap_state, api);
    defer releaseAllocatorLock(heap_state);
    if (!supportsVmApi(api) or heap_state.vm_operation != 0) return .busy;
    for (heap_state.small_regions) |region| if (region.active_allocations != 0) return .busy;
    if (heap_state.direct_active != heap_state.direct_retiring) return .busy;
    if (!beginVm(heap_state)) return .busy;
    defer endVm(heap_state, api);
    if (!finishRetiredReservation(heap_state, api) or !finishDirectRetirement(heap_state, api)) return .pending;
    _ = releaseDirectCachesLocked(heap_state, api);
    if (heap_state.direct_cached != 0) return .pending;
    for (&heap_state.small_regions) |*region| {
        if (!region.used) continue;
        const id = region.region_id;
        // Only the value identity crosses release; never read its old pages.
        if (vmRelease(heap_state, api, id) != abi.vm_ok) return .pending;
        std.debug.assert(region.region_id == id and region.active_allocations == 0);
        region.* = .{};
    }
    return .done;
}

// 0.56.41 (B2): der Allokator laeuft ueber die R4SYS-Gruppentabelle
// (vm_reserve/commit/decommit/release seit v5 enthalten); der
// Parameter heisst weiter api, traegt aber den Tabellenzeiger.
pub fn allocator(api: *const @import("r4os_contract2").R4XStartR4Sys2) std.mem.Allocator {
    return .{ .ptr = @constCast(api), .vtable = &vtable };
}

/// Borrow the SDK callback record for the lifetime of the allocator and all
/// outstanding calls. Uses the same default heap, lock and VM retirement path.
pub fn allocatorMapped(memory: *const allocator_source.Memory) std.mem.Allocator {
    return .{ .ptr = Source.mapped(memory).toOpaque(), .vtable = &vtable };
}
pub fn trimMapped(memory: *const allocator_source.Memory) void {
    stateTrim(&state, Source.mapped(memory));
}
pub fn shutdownMapped(memory: *const allocator_source.Memory) Shutdown {
    const api = Source.mapped(memory);
    const result = shutdownState(&state, api);
    if (result != .done) return result;
    state.lock_wait.prune(api);
    state.vm_wait.prune(api);
    return if (state.lock_wait.handle == 0 and state.vm_wait.handle == 0) .done else .pending;
}

fn stateStats(heap_state: *State) Stats {
    acquireAllocatorLock(heap_state, null);
    defer releaseAllocatorLock(heap_state);
    var out: Stats = .{
        .direct_active = heap_state.direct_active,
        .direct_cached = heap_state.direct_cached,
        .direct_retiring = heap_state.direct_retiring,
        .active_allocations = heap_state.direct_active,
        .allocations = heap_state.direct_allocations,
        .frees = heap_state.direct_frees,
        .active_bytes = heap_state.active_bytes,
        .peak_active_bytes = heap_state.peak_active_bytes,
        .peak_region_active_bytes = heap_state.direct_peak_active_bytes,
        .reserved_bytes = heap_state.direct_reserved_bytes,
        .committed_bytes = heap_state.direct_reserved_bytes,
        .peak_committed_bytes = heap_state.peak_committed_bytes,
        .cached_bytes = heap_state.direct_cached_bytes,
        .allocation_errors = heap_state.allocation_errors,
        .allocation_search_steps = heap_state.allocation_search_steps,
        .class_search_steps = heap_state.class_search_steps,
        .backward_search_steps = heap_state.backward_search_steps,
        .end_search_steps = heap_state.end_search_steps,
        .splits = heap_state.splits,
        .coalesces = heap_state.coalesces,
        .corruptions = heap_state.corruptions,
        .direct_cache_hits = heap_state.direct_cache_hits,
        .direct_cache_misses = heap_state.direct_cache_misses,
        .direct_cache_evictions = heap_state.direct_cache_evictions,
        .trim_calls = heap_state.trim_calls,
        .trim_reclaimed_bytes = heap_state.trim_reclaimed_bytes,
        .vm_reserve_calls = heap_state.vm_reserve_calls,
        .vm_commit_calls = heap_state.vm_commit_calls,
        .vm_decommit_calls = heap_state.vm_decommit_calls,
        .vm_decommit_bytes = heap_state.vm_decommit_bytes,
        .vm_release_calls = heap_state.vm_release_calls,
    };
    for (heap_state.small_regions) |region| {
        if (!region.used) continue;
        out.small_regions += 1;
        out.active_allocations += region.active_allocations;
        out.allocations += region.allocations;
        out.frees += region.frees;
        if (region.peak_active_bytes > out.peak_region_active_bytes) out.peak_region_active_bytes = region.peak_active_bytes;
        out.reserved_bytes +%= region.reserve_size;
        out.committed_bytes +%= region.committed_size;
        out.decommits +%= region.decommits;
    }
    return out;
}

/// Releases all reusable direct regions and reduces free small-region tails
/// to the one-page metadata minimum. Allocation failures invoke the same
/// bounded reclaim path before one retry.
fn stateTrim(heap_state: *State, api: anytype) void {
    acquireAllocatorLock(heap_state, api);
    defer releaseAllocatorLock(heap_state);
    if (!supportsVmApi(api)) return;
    while (!beginVm(heap_state)) waitForVm(heap_state, api);
    defer endVm(heap_state, api);
    _ = finishRetiredReservation(heap_state, api);
    _ = finishDirectRetirement(heap_state, api);
    _ = trimLocked(heap_state, api, null);
}

fn allocatorAlloc(heap_state: *State, ptr: *anyopaque, len: usize, alignment: Alignment, ret_addr: usize) ?[*]u8 {
    _ = ret_addr;
    const api = apiFromPtr(ptr);
    acquireAllocatorLock(heap_state, api);
    defer releaseAllocatorLock(heap_state);
    if (len == 0 or !supportsVmApi(api)) return failAlloc(heap_state);
    const byte_alignment = normalizeAlignment(alignment.toByteUnits()) orelse return failAlloc(heap_state);
    while (true) {
        if (len >= large_threshold or byte_alignment > page_size) {
            if (len >= large_threshold) {
                const need = conservativeBlockNeed(len, @max(byte_alignment, page_size)) orelse return failAlloc(heap_state);
                const reserve_size = alignForward(need, page_size) orelse return failAlloc(heap_state);
                if (takeCachedDirect(heap_state, reserve_size, @max(byte_alignment, page_size), len)) |cached| {
                    return activateDirect(heap_state, cached.entry.region_id, cached.entry.base, cached.entry.reserve_size, len, cached.layout);
                }
            }
        } else if (tryAllocExistingSmall(heap_state, len, byte_alignment)) |memory| return memory;
        if (!beginVm(heap_state)) {
            waitForVm(heap_state, api);
            continue; // A publisher or free may now satisfy the fast path.
        }
        defer endVm(heap_state, api);
        if (!finishRetiredReservation(heap_state, api)) return failAlloc(heap_state);
        if (len >= large_threshold or byte_alignment > page_size) return allocDirect(heap_state, api, len, byte_alignment) orelse failAlloc(heap_state);
        return allocSmall(heap_state, api, len, byte_alignment) orelse failAlloc(heap_state);
    }
}

fn allocatorResize(heap_state: *State, ptr: *anyopaque, memory: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) bool {
    _ = ret_addr;
    if (new_len == memory.len) return true;
    if (memory.len == 0) return new_len == 0;
    const api = apiFromPtr(ptr);
    acquireAllocatorLock(heap_state, api);
    defer releaseAllocatorLock(heap_state);
    if (!supportsVmApi(api)) return false;
    const byte_alignment = normalizeAlignment(alignment.toByteUnits()) orelse return false;
    while (true) {
        // Rebind only after a wait: neighboring blocks may have changed.
        const header_addr = blk: {
            const header = headerFromUser(heap_state, memory.ptr, byte_alignment) orelse return false;
            if (!isUsed(header)) return false;
            if (new_len <= memory.len) {
                shrinkBlock(heap_state, header, memory.len, new_len);
                return true;
            }
            if (isDirect(header)) return false;
            const index = findSmallRegion(heap_state, header.region_id) orelse return false;
            const region = &heap_state.small_regions[index];
            const address = @intFromPtr(header);
            if (canHoldUser(address, header.block_size, header.user_addr, new_len)) {
                accountResize(heap_state, region, memory.len, new_len);
                header.requested_size = new_len;
                return true;
            }
            if ((nextBlock(heap_state, region.*, header) catch return false)) |next| {
                if (isUsed(next)) return false;
                if (canHoldUser(address, header.block_size + next.block_size, header.user_addr, new_len)) {
                    return growSmallBlock(heap_state, api, address, byte_alignment, memory.len, new_len);
                }
            }
            break :blk @intFromPtr(header);
        };
        if (!beginVm(heap_state)) {
            waitForVm(heap_state, api);
            continue;
        }
        defer endVm(heap_state, api);
        return growSmallBlock(heap_state, api, header_addr, byte_alignment, memory.len, new_len);
    }
}

fn allocatorRemap(heap_state: *State, ptr: *anyopaque, memory: []u8, alignment: Alignment, new_len: usize, ret_addr: usize) ?[*]u8 {
    if (new_len == 0) return null;
    if (allocatorResize(heap_state, ptr, memory, alignment, new_len, ret_addr)) return memory.ptr;
    const next = allocatorAlloc(heap_state, ptr, new_len, alignment, ret_addr) orelse return null;
    @memcpy(next[0..@min(memory.len, new_len)], memory[0..@min(memory.len, new_len)]);
    allocatorFree(heap_state, ptr, memory, alignment, ret_addr);
    return next;
}

fn allocatorFree(heap_state: *State, ptr: *anyopaque, memory: []u8, alignment: Alignment, ret_addr: usize) void {
    _ = ret_addr;
    if (memory.len == 0) return;
    const api = apiFromPtr(ptr);
    acquireAllocatorLock(heap_state, api);
    defer releaseAllocatorLock(heap_state);
    const byte_alignment = normalizeAlignment(alignment.toByteUnits()) orelse return;
    while (true) {
        if (heap_state.retiring_direct) |retired| {
            if (retired.user_addr == @intFromPtr(memory.ptr)) {
                if (!beginVm(heap_state)) return; // Same allocation already retiring.
                defer endVm(heap_state, api);
                _ = finishDirectRetirement(heap_state, api);
                return;
            }
        }
        const action: FreeAction = blk: {
            const header = headerFromUser(heap_state, memory.ptr, byte_alignment) orelse return;
            if (!isUsed(header)) return;
            if (!isDirect(header)) {
                const index = findSmallRegion(heap_state, header.region_id) orelse return;
                const freed = freeSmallBlock(heap_state, index, header, header.requested_size);
                if (!freed) return;
                break :blk .{ .small = index };
            }
            if (cacheDirectRegion(heap_state, header, @max(byte_alignment, page_size))) {
                accountDirectFree(heap_state, header.requested_size);
                heap_state.vm_wait.notify(api);
                return;
            }
            break :blk .{ .direct = .{ .region_id = header.region_id, .base = @intFromPtr(header), .reserve_size = header.block_size, .requested_size = header.requested_size, .user_addr = header.user_addr } };
        };
        const direct = switch (action) {
            .small => |index| {
                // A foreign VM operation must not delay a free publication.
                // Ordinary small frees do not need VM admission at all.
                const before = heap_state.small_regions[index];
                heap_state.vm_wait.notify(api);
                if ((before.pending_decommit_len != 0 or before.committed_size >= small_region_retain + small_region_decommit_threshold) and beginVm(heap_state)) {
                    defer endVm(heap_state, api);
                    _ = decommitTopFree(heap_state, api, index, false);
                }
                return;
            },
            .direct => |entry| entry,
        };
        if (!beginVm(heap_state)) {
            waitForVm(heap_state, api);
            continue;
        }
        defer endVm(heap_state, api);
        // Queue only still-resident headers. Before any physical release the
        // head is detached into the exact value record below. A failed older
        // release must not lose this second logical free.
        const header = headerAt(direct.base);
        header.magic = retired_block_magic;
        header.free_next = heap_state.retiring_direct_head;
        heap_state.retiring_direct_head = direct.base;
        heap_state.direct_retiring += 1;
        _ = finishDirectRetirement(heap_state, api);
        return;
    }
}

fn finishDirectRetirement(heap_state: *State, api: anytype) bool {
    while (true) {
        if (heap_state.retiring_direct == null) {
            if (heap_state.retiring_direct_head == 0) return true;
            const header = headerAt(heap_state.retiring_direct_head);
            std.debug.assert(header.magic == retired_block_magic and isDirect(header));
            heap_state.retiring_direct_head = header.free_next;
            heap_state.retiring_direct = .{ .region_id = header.region_id, .base = @intFromPtr(header), .reserve_size = header.block_size, .requested_size = header.requested_size, .user_addr = header.user_addr };
        }
        const entry = heap_state.retiring_direct.?;
        if (vmRelease(heap_state, api, entry.region_id) != abi.vm_ok) return false;
        accountDirectFree(heap_state, entry.requested_size);
        if (heap_state.direct_reserved_bytes >= entry.reserve_size) {
            heap_state.direct_reserved_bytes -= entry.reserve_size;
        } else {
            heap_state.direct_reserved_bytes = 0;
        }
        heap_state.retiring_direct = null;
        std.debug.assert(heap_state.direct_retiring != 0);
        heap_state.direct_retiring -= 1;
    }
}

fn finishRetiredReservation(heap_state: *State, api: anytype) bool {
    if (heap_state.retired_reservation) |info| {
        if (vmRelease(heap_state, api, info.id) != abi.vm_ok) return false;
        heap_state.retired_reservation = null;
    }
    return true;
}

fn rollbackReservation(heap_state: *State, api: anytype, info: abi.ProgramVmRegionInfo) void {
    std.debug.assert(heap_state.retired_reservation == null);
    heap_state.retired_reservation = info;
    _ = finishRetiredReservation(heap_state, api);
}

fn beginVm(heap_state: *State) bool {
    if (heap_state.vm_operation != 0) return false;
    // Exhaustion cannot alias an earlier private operation.
    heap_state.next_vm_operation = std.math.add(u64, heap_state.next_vm_operation, 1) catch @panic("VM allocator operation exhausted");
    heap_state.vm_operation = heap_state.next_vm_operation;
    return true;
}

fn endVm(heap_state: *State, api: anytype) void {
    std.debug.assert(heap_state.vm_operation != 0 and heap_state.preparing_slot == null);
    heap_state.vm_operation = 0;
    heap_state.vm_wait.notify(api);
}

fn waitForVm(heap_state: *State, api: anytype) void {
    releaseAllocatorLock(heap_state);
    const ticket = heap_state.vm_wait.enroll(api);
    acquireAllocatorLock(heap_state, api);
    const needed = heap_state.vm_operation != 0;
    releaseAllocatorLock(heap_state);
    if (needed) {
        if (ticket) |value| value.wait() else wait.pause(api);
    }
    if (ticket) |value| value.deinit();
    heap_state.vm_wait.prune(api);
    acquireAllocatorLock(heap_state, api);
}

fn allocSmall(heap_state: *State, api: anytype, len: usize, alignment: usize) ?[*]u8 {
    if (tryAllocExistingSmall(heap_state, len, alignment)) |ptr| return ptr;

    const needed = conservativeBlockNeed(len, alignment) orelse return null;
    var i: usize = 0;
    while (i < heap_state.small_regions.len) : (i += 1) {
        if (!heap_state.small_regions[i].used) continue;
        if (growSmallRegion(heap_state, api, i, needed)) {
            if (tryAllocFromRegion(heap_state, i, len, alignment)) |ptr| return ptr;
        }
    }

    const region_index = createSmallRegion(heap_state, api) orelse return null;
    if (tryAllocFromRegion(heap_state, region_index, len, alignment)) |ptr| return ptr;
    // 0.56.34f: Eine frische Region committet nur EINE Seite; ohne dieses
    // Nachwachsen scheiterte JEDE Erstallokation groesser ~4KB dauerhaft
    // (Befund: REG "scratch-memory" - hive_buffer 32KB ist REGs erste
    // Allokation; alle spaeteren Groessen gingen nur, wenn vorher eine
    // kleine Allokation die Region angelegt hatte).
    if (growSmallRegion(heap_state, api, region_index, needed)) {
        if (tryAllocFromRegion(heap_state, region_index, len, alignment)) |ptr| return ptr;
    }
    return null;
}

fn tryAllocExistingSmall(heap_state: *State, len: usize, alignment: usize) ?[*]u8 {
    var i: usize = 0;
    while (i < heap_state.small_regions.len) : (i += 1) {
        if (!heap_state.small_regions[i].used) continue;
        if (tryAllocFromRegion(heap_state, i, len, alignment)) |ptr| return ptr;
    }
    return null;
}

fn tryAllocFromRegion(heap_state: *State, region_index: usize, len: usize, alignment: usize) ?[*]u8 {
    const region = &heap_state.small_regions[region_index];
    const needed = conservativeBlockNeed(len, alignment) orelse return null;
    var class_index = sizeClass(needed);
    while (class_index < size_class_count) : (class_index += 1) {
        heap_state.class_search_steps +%= 1;
        var addr = region.free_heads[class_index];
        var previous: usize = 0;
        var visits: usize = 0;
        const visit_limit = region.committed_size / min_free_block + 1;
        while (addr != 0 and visits < visit_limit) : (visits += 1) {
            heap_state.allocation_search_steps +%= 1;
            const header = validatedFreeNode(heap_state, region.*, addr, class_index, previous) orelse return null;
            const next = freeLinks(header).next;
            if (layoutInBlock(addr, header.block_size, len, alignment)) |layout| {
                if (!removeFree(heap_state, region, header)) return null;
                allocateFromFreeBlock(heap_state, region, header, addr, layout, len);
                return @ptrFromInt(layout.user_addr);
            }
            previous = addr;
            addr = next;
        }
        if (addr != 0) {
            recordCorruption(heap_state);
            return null;
        }
    }
    return null;
}

fn allocateFromFreeBlock(heap_state: *State, region: *SmallRegion, header: *BlockHeader, header_addr: usize, layout: AllocationLayout, len: usize) void {
    const region_id = header.region_id;
    if (layout.remaining_size >= min_free_block) {
        heap_state.splits +%= 1;
        const next_addr = header_addr + layout.allocated_size;
        header.block_size = layout.allocated_size;
        writeFooter(header);
        const next = initFreeBlock(region_id, next_addr, layout.remaining_size);
        _ = insertFree(heap_state, region, next);
    }
    header.magic = block_magic;
    header.flags = block_flag_used;
    header.region_id = region_id;
    header.requested_size = len;
    header.user_addr = layout.user_addr;
    writeFooter(header);
    writeBackref(layout.backref_addr, header_addr);
    region.active_allocations += 1;
    region.allocations +%= 1;
    region.active_bytes +%= len;
    if (region.active_bytes > region.peak_active_bytes) region.peak_active_bytes = region.active_bytes;
    accountActiveGrowth(heap_state, len);
}

fn allocDirect(heap_state: *State, api: anytype, len: usize, alignment: usize) ?[*]u8 {
    const effective_alignment = @max(alignment, page_size);
    const need = conservativeBlockNeed(len, effective_alignment) orelse return null;
    const reserve_size = alignForward(need, page_size) orelse return null;
    if (len >= large_threshold) {
        if (takeCachedDirect(heap_state, reserve_size, effective_alignment, len)) |cached| {
            return activateDirect(heap_state, cached.entry.region_id, cached.entry.base, cached.entry.reserve_size, len, cached.layout);
        }
    }
    if (len >= large_threshold and directCacheClass(reserve_size) != null) heap_state.direct_cache_misses +%= 1;

    const reserve_alignment: u64 = @intCast(effective_alignment);
    var retried = false;
    while (true) {
        var info: abi.ProgramVmRegionInfo = .{};
        if (vmReserve(heap_state, api, reserve_size, reserve_alignment, abi.vm_region_flags_default, &info) != abi.vm_ok) {
            if (!retried and trimDirectCachesLocked(heap_state, api) > 0) {
                retried = true;
                continue;
            }
            return null;
        }
        if (!validReservedRegion(info, reserve_size, effective_alignment)) {
            rollbackReservation(heap_state, api, info);
            return null;
        }
        const base: usize = @intCast(info.base);
        const layout = layoutInBlock(base, reserve_size, len, effective_alignment) orelse {
            recordCorruption(heap_state);
            rollbackReservation(heap_state, api, info);
            return null;
        };
        if (vmCommit(heap_state, api, info.id, 0, reserve_size, 0) != abi.vm_ok) {
            rollbackReservation(heap_state, api, info);
            if (heap_state.retired_reservation != null) return null;
            if (!retried and trimLocked(heap_state, api, null) > 0) {
                retried = true;
                continue;
            }
            return null;
        }
        heap_state.direct_reserved_bytes +%= reserve_size;
        updatePeakCommitted(heap_state);
        return activateDirect(heap_state, info.id, base, reserve_size, len, layout);
    }
}

fn activateDirect(heap_state: *State, region_id: u32, base: usize, reserve_size: usize, len: usize, layout: AllocationLayout) [*]u8 {
    const header = headerAt(base);
    header.* = .{
        .flags = block_flag_used | block_flag_direct,
        .region_id = region_id,
        .block_size = reserve_size,
        .requested_size = len,
        .user_addr = layout.user_addr,
    };
    writeFooter(header);
    writeBackref(layout.backref_addr, base);
    heap_state.direct_active += 1;
    heap_state.direct_allocations +%= 1;
    heap_state.direct_active_bytes +%= len;
    if (heap_state.direct_active_bytes > heap_state.direct_peak_active_bytes) heap_state.direct_peak_active_bytes = heap_state.direct_active_bytes;
    accountActiveGrowth(heap_state, len);
    return @ptrFromInt(layout.user_addr);
}

fn accountDirectFree(heap_state: *State, requested_size: usize) void {
    if (heap_state.direct_active > 0) heap_state.direct_active -= 1;
    heap_state.direct_frees +%= 1;
    if (heap_state.direct_active_bytes >= requested_size) {
        heap_state.direct_active_bytes -= requested_size;
    } else {
        heap_state.direct_active_bytes = 0;
    }
    accountActiveShrink(heap_state, requested_size);
}

fn directCacheClass(reserve_size: usize) ?usize {
    var limit = direct_cache_first_size;
    for (0..direct_cache_class_count) |class_index| {
        if (reserve_size <= limit) return class_index;
        limit <<= 1;
    }
    return null;
}

fn takeCachedDirect(heap_state: *State, reserve_size: usize, alignment: usize, len: usize) ?DirectActivation {
    const first_class = directCacheClass(reserve_size) orelse return null;
    var class_index = first_class;
    while (class_index < direct_cache_class_count) : (class_index += 1) {
        const entry = heap_state.direct_cache[class_index];
        if (!entry.used or entry.retiring or entry.reserve_size < reserve_size or entry.alignment < alignment or (entry.base & (alignment - 1)) != 0) continue;
        const layout = layoutInBlock(entry.base, entry.reserve_size, len, alignment) orelse {
            recordCorruption(heap_state);
            continue;
        };
        heap_state.direct_cache[class_index] = .{};
        if (heap_state.direct_cached > 0) heap_state.direct_cached -= 1;
        if (heap_state.direct_cached_bytes >= entry.reserve_size) heap_state.direct_cached_bytes -= entry.reserve_size;
        heap_state.direct_cache_hits +%= 1;
        return .{ .entry = entry, .layout = layout };
    }
    return null;
}

fn cacheDirectRegion(heap_state: *State, header: *BlockHeader, alignment: usize) bool {
    if (header.requested_size < large_threshold) return false;
    const class_index = directCacheClass(header.block_size) orelse return false;
    if (heap_state.direct_cache[class_index].used) return false;
    if (heap_state.direct_cached_bytes + header.block_size > direct_cache_max_bytes) return false;
    const base = @intFromPtr(header);
    heap_state.direct_cache[class_index] = .{
        .used = true,
        .region_id = header.region_id,
        .base = base,
        .reserve_size = header.block_size,
        .alignment = alignment,
    };
    heap_state.direct_cached += 1;
    heap_state.direct_cached_bytes +%= header.block_size;
    header.magic = retired_block_magic;
    return true;
}

fn createSmallRegion(heap_state: *State, api: anytype) ?usize {
    const slot = freeSmallRegionSlot(heap_state) orelse return null;
    heap_state.preparing_slot = slot;
    defer heap_state.preparing_slot = null;
    var retried = false;
    while (true) {
        var info: abi.ProgramVmRegionInfo = .{};
        if (vmReserve(heap_state, api, small_region_reserve, page_size, abi.vm_region_flags_default, &info) != abi.vm_ok) {
            if (!retried and trimDirectCachesLocked(heap_state, api) > 0) {
                retried = true;
                continue;
            }
            return null;
        }
        if (!validReservedRegion(info, small_region_reserve, page_size)) {
            rollbackReservation(heap_state, api, info);
            return null;
        }
        if (vmCommit(heap_state, api, info.id, 0, small_region_initial_commit, 0) != abi.vm_ok) {
            rollbackReservation(heap_state, api, info);
            if (heap_state.retired_reservation != null) return null;
            if (!retried and trimLocked(heap_state, api, null) > 0) {
                retried = true;
                continue;
            }
            return null;
        }
        const base: usize = @intCast(info.base);
        heap_state.small_regions[slot] = .{
            .used = true,
            .region_id = info.id,
            .base = base,
            .reserve_size = @intCast(info.len),
            .committed_size = small_region_initial_commit,
        };
        const header = initFreeBlock(info.id, base, small_region_initial_commit);
        if (!insertFree(heap_state, &heap_state.small_regions[slot], header)) {
            heap_state.small_regions[slot] = .{};
            rollbackReservation(heap_state, api, info);
            return null;
        }
        updatePeakCommitted(heap_state);
        return slot;
    }
}

fn growSmallRegion(heap_state: *State, api: anytype, region_index: usize, needed: usize) bool {
    return growSmallRegionAttempt(heap_state, api, region_index, needed, true);
}

fn growSmallRegionAttempt(heap_state: *State, api: anytype, region_index: usize, needed: usize, allow_reclaim: bool) bool {
    if (!heap_state.small_regions[region_index].used) return false;
    _ = finishPendingDecommit(heap_state, api, region_index);
    const before = heap_state.small_regions[region_index];
    if (before.pending_decommit_len != 0 or before.committed_size >= before.reserve_size) return false;
    const wanted = @max(needed, before.next_commit_size);
    var add = alignForward(wanted, page_size) orelse return false;
    const available = before.reserve_size - before.committed_size;
    if (add > available) add = alignDown(available, page_size);
    if (add == 0) return false;
    const old_committed = before.committed_size;
    // Nothing above old_committed is public while the exact operation owns
    // VM admission. Existing blocks below it can be allocated, freed/resized.
    if (vmCommit(heap_state, api, before.region_id, old_committed, add, 0) != abi.vm_ok) {
        if (allow_reclaim and trimLocked(heap_state, api, before.region_id) > 0) {
            return growSmallRegionAttempt(heap_state, api, region_index, needed, false);
        }
        return false;
    }
    const region = &heap_state.small_regions[region_index];
    std.debug.assert(region.region_id == before.region_id and region.base == before.base and region.committed_size == old_committed);
    const last = lastBlock(heap_state, region.*) orelse {
        rollbackGrowth(heap_state, api, region_index, old_committed, add);
        return false;
    };
    const extend_last = !isUsed(last.header);
    const new_block_addr = region.base + old_committed;
    if (extend_last) {
        if (!removeFree(heap_state, region, last.header)) {
            rollbackGrowth(heap_state, api, region_index, old_committed, add);
            return false;
        }
        footerFromHeader(last.header).magic = 0;
        region.committed_size = old_committed + add;
        last.header.block_size += add;
        writeFooter(last.header);
        if (!insertFree(heap_state, region, last.header)) return false;
        advanceCommitGrowth(region, add);
        updatePeakCommitted(heap_state);
        return true;
    }
    region.committed_size = old_committed + add;
    const header = initFreeBlock(region.region_id, new_block_addr, add);
    if (!insertFree(heap_state, region, header)) return false;
    advanceCommitGrowth(region, add);
    updatePeakCommitted(heap_state);
    return true;
}

fn advanceCommitGrowth(region: *SmallRegion, committed: usize) void {
    const doubled = if (committed > small_region_max_grow / 2) small_region_max_grow else committed * 2;
    region.next_commit_size = @max(region.next_commit_size, doubled);
}

fn rollbackGrowth(heap_state: *State, api: anytype, index: usize, offset: usize, len: usize) void {
    heap_state.small_regions[index].pending_decommit_offset = offset;
    heap_state.small_regions[index].pending_decommit_len = len;
    _ = finishPendingDecommit(heap_state, api, index);
}

fn freeSmallBlock(heap_state: *State, region_index: usize, header: *BlockHeader, old_len: usize) bool {
    const region = &heap_state.small_regions[region_index];
    const header_addr = @intFromPtr(header);
    const previous = previousBlock(heap_state, region.*, header_addr) catch return false;
    const next = nextBlock(heap_state, region.*, header) catch return false;
    if (previous) |candidate| {
        if (!isUsed(candidate) and !canRemoveFree(heap_state, region.*, candidate)) return false;
    }
    if (next) |candidate| {
        if (!isUsed(candidate) and !canRemoveFree(heap_state, region.*, candidate)) return false;
    }

    var merged = header;
    var merged_size = header.block_size;
    header.flags = 0;
    header.requested_size = 0;
    header.user_addr = 0;
    if (previous) |candidate| {
        if (!isUsed(candidate)) {
            if (!removeFree(heap_state, region, candidate)) return false;
            footerFromHeader(candidate).magic = 0;
            header.magic = retired_block_magic;
            merged = candidate;
            merged_size += candidate.block_size;
            heap_state.coalesces +%= 1;
        }
    }
    if (next) |candidate| {
        if (!isUsed(candidate)) {
            if (!removeFree(heap_state, region, candidate)) return false;
            footerFromHeader(merged).magic = 0;
            candidate.magic = retired_block_magic;
            merged_size += candidate.block_size;
            heap_state.coalesces +%= 1;
        }
    }
    merged.magic = block_magic;
    merged.flags = 0;
    merged.region_id = region.region_id;
    merged.block_size = merged_size;
    merged.requested_size = 0;
    merged.user_addr = 0;
    writeFooter(merged);
    if (!insertFree(heap_state, region, merged)) return false;

    if (region.active_allocations > 0) region.active_allocations -= 1;
    region.frees +%= 1;
    if (region.active_bytes >= old_len) {
        region.active_bytes -= old_len;
    } else {
        region.active_bytes = 0;
    }
    accountActiveShrink(heap_state, old_len);
    return true;
}

fn growSmallBlock(heap_state: *State, api: anytype, header_addr: usize, alignment: usize, old_len: usize, new_len: usize) bool {
    _ = alignment;
    for (0..2) |_| {
        // Re-read every neighbor after a VM handoff. Only the caller's live
        // allocation address is retained across the slow operation.
        const growth = blk: {
            const header = headerAt(header_addr);
            const index = findSmallRegion(heap_state, header.region_id) orelse return false;
            const region = &heap_state.small_regions[index];
            if (!validSmallBlock(region.*, header_addr, header) or !isUsed(header)) return false;
            const user_addr = header.user_addr;
            if (canHoldUser(header_addr, header.block_size, user_addr, new_len)) {
                accountResize(heap_state, region, old_len, new_len);
                header.requested_size = new_len;
                return true;
            }
            const required_end = requiredBlockEnd(user_addr, new_len) orelse return false;
            if ((nextBlock(heap_state, region.*, header) catch return false)) |next| {
                if (isUsed(next)) return false;
                if (canHoldUser(header_addr, header.block_size + next.block_size, user_addr, new_len)) {
                    if (!removeFree(heap_state, region, next)) return false;
                    footerFromHeader(header).magic = 0;
                    next.magic = retired_block_magic;
                    header.block_size += next.block_size;
                    writeFooter(header);
                    heap_state.coalesces +%= 1;
                    splitAfterResize(heap_state, region, header, user_addr, new_len);
                    accountResize(heap_state, region, old_len, new_len);
                    header.requested_size = new_len;
                    return true;
                }
                if (@intFromPtr(next) + next.block_size != region.base + region.committed_size) return false;
            }
            const need = checkedSub(required_end, region.base + region.committed_size) orelse min_free_block;
            break :blk .{ .index = index, .need = @max(need, min_free_block) };
        };
        if (!growSmallRegion(heap_state, api, growth.index, growth.need)) return false;
    }
    return false;
}

fn shrinkBlock(heap_state: *State, header: *BlockHeader, old_len: usize, new_len: usize) void {
    if (isDirect(header)) {
        if (old_len > new_len and heap_state.direct_active_bytes >= old_len - new_len) heap_state.direct_active_bytes -= old_len - new_len;
        accountActiveShrink(heap_state, old_len - new_len);
        header.requested_size = new_len;
        return;
    }
    const region_index = findSmallRegion(heap_state, header.region_id) orelse {
        header.requested_size = new_len;
        return;
    };
    var region = &heap_state.small_regions[region_index];
    if (old_len > new_len and region.active_bytes >= old_len - new_len) region.active_bytes -= old_len - new_len;
    accountActiveShrink(heap_state, old_len - new_len);
    header.requested_size = new_len;
}

fn splitAfterResize(heap_state: *State, region: *SmallRegion, header: *BlockHeader, user_addr: usize, new_len: usize) void {
    const header_addr = @intFromPtr(header);
    const block_end = header_addr + header.block_size;
    var split_addr = requiredBlockEnd(user_addr, new_len) orelse block_end;
    if (split_addr > block_end or block_end - split_addr < min_free_block) {
        split_addr = block_end;
    }
    if (split_addr < block_end) {
        heap_state.splits +%= 1;
        const old_size = header.block_size;
        footerFromHeader(header).magic = 0;
        header.block_size = split_addr - header_addr;
        writeFooter(header);
        const free = initFreeBlock(header.region_id, split_addr, old_size - header.block_size);
        _ = insertFree(heap_state, region, free);
    }
}

fn accountResize(heap_state: *State, region: *SmallRegion, old_len: usize, new_len: usize) void {
    if (new_len >= old_len) {
        region.active_bytes +%= new_len - old_len;
        accountActiveGrowth(heap_state, new_len - old_len);
    } else if (region.active_bytes >= old_len - new_len) {
        region.active_bytes -= old_len - new_len;
        accountActiveShrink(heap_state, old_len - new_len);
    } else {
        region.active_bytes = 0;
        accountActiveShrink(heap_state, old_len - new_len);
    }
    if (region.active_bytes > region.peak_active_bytes) region.peak_active_bytes = region.active_bytes;
}

/// All callers hold this heap owner's allocator lock. The peak is updated at
/// the successful mutation, so a short-lived simultaneous peak is retained.
fn accountActiveGrowth(heap_state: *State, amount: usize) void {
    heap_state.active_bytes +|= amount;
    if (heap_state.active_bytes > heap_state.peak_active_bytes) heap_state.peak_active_bytes = heap_state.active_bytes;
}

fn accountActiveShrink(heap_state: *State, amount: usize) void {
    heap_state.active_bytes -|= amount;
}

fn decommitTopFree(heap_state: *State, api: anytype, region_index: usize, pressure: bool) usize {
    const completed = finishPendingDecommit(heap_state, api, region_index);
    {
        const region = &heap_state.small_regions[region_index];
        if (region.pending_decommit_len != 0 or completed != 0) return completed;
        if (region.committed_size <= page_size) return 0;
        const last = lastBlock(heap_state, region.*) orelse return 0;
        if (isUsed(last.header)) return 0;
        if (!canRemoveFree(heap_state, region.*, last.header)) return 0;
        const natural_keep = alignForward(last.addr + min_free_block, page_size) orelse return 0;
        const policy_keep = region.base + if (pressure) page_size else small_region_retain;
        const keep_until = @max(natural_keep, policy_keep);
        const committed_end = region.base + region.committed_size;
        if (keep_until >= committed_end or keep_until < region.base + page_size) return 0;
        const len = committed_end - keep_until;
        if (!pressure and len < small_region_decommit_threshold) return 0;
        if (!removeFree(heap_state, region, last.header)) return 0;
        // Keep valid boundary tags entirely below the retired tail. The exact
        // VM request remains outside that memory and must finish before growth.
        region.committed_size = keep_until - region.base;
        last.header.block_size = keep_until - last.addr;
        writeFooter(last.header);
        region.pending_decommit_offset = keep_until - region.base;
        region.pending_decommit_len = len;
        if (pressure) region.next_commit_size = small_region_initial_commit;
        if (!insertFree(heap_state, region, last.header)) return 0;
    }
    return finishPendingDecommit(heap_state, api, region_index);
}

fn finishPendingDecommit(heap_state: *State, api: anytype, region_index: usize) usize {
    const before = heap_state.small_regions[region_index];
    const len = before.pending_decommit_len;
    if (len == 0) return 0;
    if (vmDecommit(heap_state, api, before.region_id, before.pending_decommit_offset, len) != abi.vm_ok) return 0;
    const region = &heap_state.small_regions[region_index];
    std.debug.assert(region.region_id == before.region_id and region.base == before.base and
        region.pending_decommit_offset == before.pending_decommit_offset and region.pending_decommit_len == len);
    region.pending_decommit_offset = 0;
    region.pending_decommit_len = 0;
    region.decommits +%= 1;
    return len;
}

fn trimLocked(heap_state: *State, api: anytype, excluded_region_id: ?u32) usize {
    heap_state.trim_calls +%= 1;
    var reclaimed = releaseDirectCachesLocked(heap_state, api);
    for (0..heap_state.small_regions.len) |region_index| {
        const region = heap_state.small_regions[region_index];
        if (!region.used) continue;
        if (excluded_region_id) |excluded| if (region.region_id == excluded) continue;
        reclaimed +|= decommitTopFree(heap_state, api, region_index, true);
    }
    heap_state.trim_reclaimed_bytes +%= reclaimed;
    return reclaimed;
}

fn trimDirectCachesLocked(heap_state: *State, api: anytype) usize {
    const reclaimed = releaseDirectCachesLocked(heap_state, api);
    if (reclaimed == 0) return 0;
    heap_state.trim_calls +%= 1;
    heap_state.trim_reclaimed_bytes +%= reclaimed;
    return reclaimed;
}

fn releaseDirectCachesLocked(heap_state: *State, api: anytype) usize {
    var reclaimed: usize = 0;
    for (0..direct_cache_class_count) |index| {
        const before = heap_state.direct_cache[index];
        if (!before.used) continue;
        // A failed release may already have removed some pages. The stored
        // identity remains retryable, but its memory must never be reused.
        heap_state.direct_cache[index].retiring = true;
        if (vmRelease(heap_state, api, before.region_id) != abi.vm_ok) continue;
        std.debug.assert(heap_state.direct_cache[index].retiring and heap_state.direct_cache[index].region_id == before.region_id and heap_state.direct_cache[index].base == before.base);
        reclaimed +|= before.reserve_size;
        if (heap_state.direct_reserved_bytes >= before.reserve_size) heap_state.direct_reserved_bytes -= before.reserve_size;
        if (heap_state.direct_cached_bytes >= before.reserve_size) heap_state.direct_cached_bytes -= before.reserve_size;
        if (heap_state.direct_cached > 0) heap_state.direct_cached -= 1;
        heap_state.direct_cache_evictions +%= 1;
        heap_state.direct_cache[index] = .{};
    }
    return reclaimed;
}

fn updatePeakCommitted(heap_state: *State) void {
    var committed = heap_state.direct_reserved_bytes;
    for (heap_state.small_regions) |region| {
        if (region.used) committed +%= region.committed_size;
    }
    if (committed > heap_state.peak_committed_bytes) heap_state.peak_committed_bytes = committed;
}

fn layoutInBlock(block_addr: usize, block_size: usize, len: usize, alignment: usize) ?AllocationLayout {
    const block_end = checkedAdd(block_addr, block_size) orelse return null;
    const payload_end = checkedSub(block_end, @sizeOf(BlockFooter)) orelse return null;
    const min_user = checkedAdd(block_addr, @sizeOf(BlockHeader) + @sizeOf(usize)) orelse return null;
    const user_addr = alignForward(min_user, alignment) orelse return null;
    const backref_addr = checkedSub(user_addr, @sizeOf(usize)) orelse return null;
    const user_end = checkedAdd(user_addr, len) orelse return null;
    if (user_end > payload_end) return null;
    var split_addr = requiredBlockEnd(user_addr, len) orelse return null;
    if (split_addr > block_end or block_end - split_addr < min_free_block) {
        split_addr = block_end;
    }
    return .{
        .user_addr = user_addr,
        .backref_addr = backref_addr,
        .allocated_size = split_addr - block_addr,
        .remaining_size = block_end - split_addr,
    };
}

fn conservativeBlockNeed(len: usize, alignment: usize) ?usize {
    const with_header = checkedAdd(@sizeOf(BlockHeader) + @sizeOf(usize), len) orelse return null;
    const with_alignment = checkedAdd(with_header, alignment - 1) orelse return null;
    const with_footer = checkedAdd(with_alignment, @sizeOf(BlockFooter)) orelse return null;
    return alignForward(with_footer, @alignOf(BlockHeader));
}

fn requiredBlockEnd(user_addr: usize, len: usize) ?usize {
    const user_end = checkedAdd(user_addr, len) orelse return null;
    const footer_end = checkedAdd(user_end, @sizeOf(BlockFooter)) orelse return null;
    return alignForward(footer_end, @alignOf(BlockHeader));
}

fn headerFromUser(heap_state: *State, ptr: [*]u8, alignment: usize) ?*BlockHeader {
    const user_addr = @intFromPtr(ptr);
    if (heap_state.retiring_direct) |retired| if (retired.user_addr == user_addr) return null;
    if (findSmallRegionContaining(heap_state, user_addr)) |region_index| {
        const region = heap_state.small_regions[region_index];
        const committed_end = checkedAdd(region.base, region.committed_size) orelse return corruptNull(heap_state);
        const backref_addr = checkedSub(user_addr, @sizeOf(usize)) orelse return corruptNull(heap_state);
        if (backref_addr < region.base + @sizeOf(BlockHeader) or backref_addr + @sizeOf(usize) > committed_end) return corruptNull(heap_state);
        const header_addr = (@as(*const usize, @ptrFromInt(backref_addr))).*;
        if (header_addr < region.base or header_addr + @sizeOf(BlockHeader) > committed_end) return corruptNull(heap_state);
        const header = headerAt(header_addr);
        if (header.magic == retired_block_magic) return null;
        if (!validSmallBlock(region, header_addr, header)) return corruptNull(heap_state);
        if (isUsed(header) and header.user_addr != user_addr) return corruptNull(heap_state);
        return header;
    }

    const effective_alignment = @max(alignment, page_size);
    const header_addr = checkedSub(user_addr, effective_alignment) orelse return null;
    const header = headerAt(header_addr);
    if (header.magic == retired_block_magic) return null;
    if (!validDirectBlock(header_addr, header, user_addr, effective_alignment)) return corruptNull(heap_state);
    return header;
}

fn headerAt(addr: usize) *BlockHeader {
    return @ptrFromInt(addr);
}

fn writeBackref(addr: usize, header_addr: usize) void {
    const backref: *usize = @ptrFromInt(addr);
    backref.* = header_addr;
}

fn validHeader(header: *const BlockHeader) bool {
    return header.magic == block_magic and
        (header.flags & ~valid_block_flags) == 0 and
        header.block_size >= min_free_block and
        (header.block_size & (@alignOf(BlockHeader) - 1)) == 0;
}

fn isUsed(header: *const BlockHeader) bool {
    return (header.flags & block_flag_used) != 0;
}

fn isDirect(header: *const BlockHeader) bool {
    return (header.flags & block_flag_direct) != 0;
}

fn footerFromHeader(header: *const BlockHeader) *BlockFooter {
    return @ptrFromInt(@intFromPtr(header) + header.block_size - @sizeOf(BlockFooter));
}

fn writeFooter(header: *const BlockHeader) void {
    footerFromHeader(header).* = .{ .block_size = header.block_size };
}

fn freeLinks(header: *const BlockHeader) *FreeLinks {
    return @ptrCast(@constCast(&header.free_previous));
}

fn initFreeBlock(region_id: u32, addr: usize, block_size: usize) *BlockHeader {
    const header = headerAt(addr);
    header.* = .{
        .region_id = region_id,
        .block_size = block_size,
    };
    freeLinks(header).* = .{};
    writeFooter(header);
    return header;
}

fn sizeClass(block_size: usize) usize {
    var class_index: usize = 0;
    var limit = first_size_class_limit;
    while (class_index + 1 < size_class_count and block_size > limit) : (class_index += 1) {
        limit <<= 1;
    }
    return class_index;
}

fn validSmallBlock(region: SmallRegion, addr: usize, header: *const BlockHeader) bool {
    const committed_end = checkedAdd(region.base, region.committed_size) orelse return false;
    if (addr < region.base or (addr & (@alignOf(BlockHeader) - 1)) != 0) return false;
    if (!validHeader(header) or isDirect(header) or header.region_id != region.region_id) return false;
    if (isUsed(header) and (header.flags & block_flag_listed) != 0) return false;
    const end = checkedAdd(addr, header.block_size) orelse return false;
    if (end > committed_end) return false;
    const footer = footerFromHeader(header);
    return footer.magic == footer_magic and footer.block_size == header.block_size;
}

fn validDirectBlock(header_addr: usize, header: *const BlockHeader, user_addr: usize, alignment: usize) bool {
    if (!validHeader(header) or !isUsed(header) or !isDirect(header) or (header.flags & block_flag_listed) != 0) return false;
    if (header.user_addr != user_addr or header_addr + alignment != user_addr) return false;
    const need = conservativeBlockNeed(header.requested_size, alignment) orelse return false;
    const minimum_size = alignForward(need, page_size) orelse return false;
    if (header.block_size < minimum_size or (header.block_size & (page_size - 1)) != 0) return false;
    const footer = footerFromHeader(header);
    return footer.magic == footer_magic and footer.block_size == header.block_size;
}

fn validatedFreeNode(heap_state: *State, region: SmallRegion, addr: usize, class_index: usize, expected_previous: usize) ?*BlockHeader {
    const header = headerAt(addr);
    if (!validSmallBlock(region, addr, header) or isUsed(header) or
        (header.flags & block_flag_listed) == 0 or sizeClass(header.block_size) != class_index)
    {
        return corruptNull(heap_state);
    }
    const links = freeLinks(header);
    if (links.previous != expected_previous or links.next == addr) return corruptNull(heap_state);
    if (links.next != 0) {
        const next = headerAt(links.next);
        if (!validSmallBlock(region, links.next, next) or isUsed(next) or
            (next.flags & block_flag_listed) == 0 or sizeClass(next.block_size) != class_index or
            freeLinks(next).previous != addr)
        {
            return corruptNull(heap_state);
        }
    }
    return header;
}

fn insertFree(heap_state: *State, region: *SmallRegion, header: *BlockHeader) bool {
    const addr = @intFromPtr(header);
    if (!validSmallBlock(region.*, addr, header) or isUsed(header) or (header.flags & block_flag_listed) != 0) return corruptFalse(heap_state);
    const class_index = sizeClass(header.block_size);
    const old_head = region.free_heads[class_index];
    if (old_head != 0) {
        const old = headerAt(old_head);
        if (!validSmallBlock(region.*, old_head, old) or isUsed(old) or
            (old.flags & block_flag_listed) == 0 or sizeClass(old.block_size) != class_index or
            freeLinks(old).previous != 0)
        {
            return corruptFalse(heap_state);
        }
    }
    freeLinks(header).* = .{ .next = old_head };
    header.flags |= block_flag_listed;
    if (old_head != 0) freeLinks(headerAt(old_head)).previous = addr;
    region.free_heads[class_index] = addr;
    return true;
}

fn freeNodeRemovable(region: SmallRegion, header: *const BlockHeader) bool {
    const addr = @intFromPtr(header);
    if (!validSmallBlock(region, addr, header) or isUsed(header) or (header.flags & block_flag_listed) == 0) return false;
    const class_index = sizeClass(header.block_size);
    const links = freeLinks(header);
    if (links.previous == addr or links.next == addr) return false;
    if (links.previous == 0) {
        if (region.free_heads[class_index] != addr) return false;
    } else {
        const previous = headerAt(links.previous);
        if (!validSmallBlock(region, links.previous, previous) or isUsed(previous) or
            (previous.flags & block_flag_listed) == 0 or sizeClass(previous.block_size) != class_index or
            freeLinks(previous).next != addr)
        {
            return false;
        }
    }
    if (links.next != 0) {
        const next = headerAt(links.next);
        if (!validSmallBlock(region, links.next, next) or isUsed(next) or
            (next.flags & block_flag_listed) == 0 or sizeClass(next.block_size) != class_index or
            freeLinks(next).previous != addr)
        {
            return false;
        }
    }
    return true;
}

fn canRemoveFree(heap_state: *State, region: SmallRegion, header: *const BlockHeader) bool {
    if (freeNodeRemovable(region, header)) return true;
    return corruptFalse(heap_state);
}

fn removeFree(heap_state: *State, region: *SmallRegion, header: *BlockHeader) bool {
    if (!canRemoveFree(heap_state, region.*, header)) return false;
    const class_index = sizeClass(header.block_size);
    const links = freeLinks(header).*;
    if (links.previous == 0) {
        region.free_heads[class_index] = links.next;
    } else {
        freeLinks(headerAt(links.previous)).next = links.next;
    }
    if (links.next != 0) freeLinks(headerAt(links.next)).previous = links.previous;
    freeLinks(header).* = .{};
    header.flags &= ~block_flag_listed;
    return true;
}

const NeighborError = error{Corrupt};

fn previousBlock(heap_state: *State, region: SmallRegion, header_addr: usize) NeighborError!?*BlockHeader {
    if (header_addr == region.base) return null;
    heap_state.backward_search_steps +%= 1;
    if (header_addr < region.base + @sizeOf(BlockFooter)) return corruptNeighbor(heap_state);
    const footer: *const BlockFooter = @ptrFromInt(header_addr - @sizeOf(BlockFooter));
    if (footer.magic != footer_magic or footer.block_size < min_free_block or footer.block_size > header_addr - region.base) return corruptNeighbor(heap_state);
    const previous_addr = header_addr - footer.block_size;
    const previous = headerAt(previous_addr);
    if (!validSmallBlock(region, previous_addr, previous) or previous_addr + previous.block_size != header_addr) return corruptNeighbor(heap_state);
    return previous;
}

fn nextBlock(heap_state: *State, region: SmallRegion, header: *const BlockHeader) NeighborError!?*BlockHeader {
    const next_addr = checkedAdd(@intFromPtr(header), header.block_size) orelse return corruptNeighbor(heap_state);
    const committed_end = checkedAdd(region.base, region.committed_size) orelse return corruptNeighbor(heap_state);
    if (next_addr == committed_end) return null;
    if (next_addr > committed_end or next_addr + @sizeOf(BlockHeader) > committed_end) return corruptNeighbor(heap_state);
    const next = headerAt(next_addr);
    if (!validSmallBlock(region, next_addr, next)) return corruptNeighbor(heap_state);
    return next;
}

const LastBlock = struct {
    addr: usize,
    header: *BlockHeader,
};

fn lastBlock(heap_state: *State, region: SmallRegion) ?LastBlock {
    heap_state.end_search_steps +%= 1;
    const end = checkedAdd(region.base, region.committed_size) orelse {
        recordCorruption(heap_state);
        return null;
    };
    if (region.committed_size < min_free_block) {
        recordCorruption(heap_state);
        return null;
    }
    const footer: *const BlockFooter = @ptrFromInt(end - @sizeOf(BlockFooter));
    if (footer.magic != footer_magic or footer.block_size < min_free_block or footer.block_size > region.committed_size) {
        recordCorruption(heap_state);
        return null;
    }
    const addr = end - footer.block_size;
    const header = headerAt(addr);
    if (!validSmallBlock(region, addr, header) or addr + header.block_size != end) {
        recordCorruption(heap_state);
        return null;
    }
    return .{ .addr = addr, .header = header };
}

fn canHoldUser(header_addr: usize, block_size: usize, user_addr: usize, len: usize) bool {
    const user_end = checkedAdd(user_addr, len) orelse return false;
    const block_end = checkedAdd(header_addr, block_size) orelse return false;
    const payload_end = checkedSub(block_end, @sizeOf(BlockFooter)) orelse return false;
    return user_end <= payload_end;
}

fn freeSmallRegionSlot(heap_state: *State) ?usize {
    var i: usize = 0;
    while (i < heap_state.small_regions.len) : (i += 1) {
        if (!heap_state.small_regions[i].used and heap_state.preparing_slot != i) return i;
    }
    return null;
}

fn findSmallRegion(heap_state: *State, region_id: u32) ?usize {
    var i: usize = 0;
    while (i < heap_state.small_regions.len) : (i += 1) {
        if (heap_state.small_regions[i].used and heap_state.small_regions[i].region_id == region_id) return i;
    }
    return null;
}

fn findSmallRegionContaining(heap_state: *State, addr: usize) ?usize {
    var i: usize = 0;
    while (i < heap_state.small_regions.len) : (i += 1) {
        const region = heap_state.small_regions[i];
        if (!region.used) continue;
        const end = checkedAdd(region.base, region.committed_size) orelse continue;
        if (addr >= region.base and addr < end) return i;
    }
    return null;
}

fn apiFromPtr(ptr: *anyopaque) Source {
    return Source.fromOpaque(ptr);
}

fn supportsVmApi(api: anytype) bool {
    return Source.from(api).supportsVm();
}

fn vmFn(api: anytype, comptime field: []const u8) @field(abi.R4SysFns, field) {
    return Source.from(api).call(field);
}

fn acquireAllocatorLock(heap_state: *State, raw_api: anytype) void {
    if (Source.optional(raw_api)) |api| if (@atomicLoad(usize, &heap_state.wait_api, .acquire) == 0 and supportsVmApi(api)) {
        _ = @cmpxchgStrong(usize, &heap_state.wait_api, 0, api.encoded, .release, .monotonic);
    };
    var spins: usize = 0;
    while (@cmpxchgWeak(u32, &heap_state.allocator_lock, 0, 1, .acquire, .monotonic) != null) {
        if (spins < 32) {
            spins += 1;
            std.atomic.spinLoopHint();
            continue;
        }
        const raw = @atomicLoad(usize, &heap_state.wait_api, .acquire);
        const table: ?Source = if (raw == 0) null else .{ .encoded = raw };
        var ticket = if (table) |value| heap_state.lock_wait.enroll(value) else null;
        defer if (ticket) |value| value.deinit();
        while (true) {
            // The revision was observed before this predicate check, so a
            // release between here and parking cannot be lost.
            if (@cmpxchgStrong(u32, &heap_state.allocator_lock, 0, 1, .acquire, .monotonic) == null) return;
            if (ticket) |*value| {
                value.wait();
                if (!value.observe()) break;
            } else {
                wait.pause(table);
                break;
            }
        }
    }
}

fn releaseAllocatorLock(heap_state: *State) void {
    @atomicStore(u32, &heap_state.allocator_lock, 0, .release);
    const raw = @atomicLoad(usize, &heap_state.wait_api, .acquire);
    if (raw != 0) {
        const api: Source = .{ .encoded = raw };
        heap_state.lock_wait.notify(api);
        heap_state.lock_wait.prune(api);
        heap_state.vm_wait.prune(api);
    }
}

fn vmReserve(heap_state: *State, api: anytype, size: usize, alignment: u64, flags: u64, out: *abi.ProgramVmRegionInfo) i32 {
    heap_state.vm_reserve_calls +%= 1;
    const operation = heap_state.vm_operation;
    std.debug.assert(operation != 0);
    releaseAllocatorLock(heap_state);
    const rc = vmFn(api, "vm_reserve")(@intCast(size), alignment, flags, out);
    acquireAllocatorLock(heap_state, api);
    std.debug.assert(heap_state.vm_operation == operation);
    return rc;
}

fn vmCommit(heap_state: *State, api: anytype, region_id: u32, offset: usize, len: usize, flags: u64) i32 {
    heap_state.vm_commit_calls +%= 1;
    const operation = heap_state.vm_operation;
    std.debug.assert(operation != 0);
    releaseAllocatorLock(heap_state);
    const rc = vmFn(api, "vm_commit")(region_id, @intCast(offset), @intCast(len), flags);
    acquireAllocatorLock(heap_state, api);
    std.debug.assert(heap_state.vm_operation == operation);
    return rc;
}

fn vmDecommit(heap_state: *State, api: anytype, region_id: u32, offset: usize, len: usize) i32 {
    heap_state.vm_decommit_calls +%= 1;
    heap_state.vm_decommit_bytes +%= len;
    const operation = heap_state.vm_operation;
    std.debug.assert(operation != 0);
    releaseAllocatorLock(heap_state);
    const rc = vmFn(api, "vm_decommit")(region_id, @intCast(offset), @intCast(len));
    acquireAllocatorLock(heap_state, api);
    std.debug.assert(heap_state.vm_operation == operation);
    return rc;
}

fn vmRelease(heap_state: *State, api: anytype, region_id: u32) i32 {
    heap_state.vm_release_calls +%= 1;
    const operation = heap_state.vm_operation;
    std.debug.assert(operation != 0);
    releaseAllocatorLock(heap_state);
    const rc = vmFn(api, "vm_release")(region_id);
    acquireAllocatorLock(heap_state, api);
    std.debug.assert(heap_state.vm_operation == operation);
    return rc;
}

fn validReservedRegion(info: abi.ProgramVmRegionInfo, required_size: usize, alignment: usize) bool {
    if (info.base > std.math.maxInt(usize) or info.len > std.math.maxInt(usize)) return false;
    const base: usize = @intCast(info.base);
    const len: usize = @intCast(info.len);
    return len >= required_size and checkedAdd(base, len) != null and (base & (alignment - 1)) == 0;
}

fn recordCorruption(heap_state: *State) void {
    heap_state.corruptions +%= 1;
}

fn corruptNull(heap_state: *State) ?*BlockHeader {
    recordCorruption(heap_state);
    return null;
}

fn corruptFalse(heap_state: *State) bool {
    recordCorruption(heap_state);
    return false;
}

fn corruptNeighbor(heap_state: *State) NeighborError {
    recordCorruption(heap_state);
    return error.Corrupt;
}

fn normalizeAlignment(raw: usize) ?usize {
    var alignment = if (raw == 0) @as(usize, 1) else raw;
    if ((alignment & (alignment - 1)) != 0) return null;
    if (alignment < @alignOf(usize)) alignment = @alignOf(usize);
    return alignment;
}

fn alignForward(value: usize, alignment: usize) ?usize {
    const mask = alignment - 1;
    if (value > std.math.maxInt(usize) - mask) return null;
    return (value + mask) & ~mask;
}

fn alignDown(value: usize, alignment: usize) usize {
    return value & ~(alignment - 1);
}

fn checkedAdd(a: usize, b: usize) ?usize {
    if (a > std.math.maxInt(usize) - b) return null;
    return a + b;
}

fn checkedSub(a: usize, b: usize) ?usize {
    if (a < b) return null;
    return a - b;
}

fn failAlloc(heap_state: *State) ?[*]u8 {
    heap_state.allocation_errors +%= 1;
    return null;
}

const test_vm_capacity: usize = small_region_reserve;
const test_wait = @import("allocator_wait_test.zig");
var test_vm_storage: [test_vm_capacity]u8 align(page_size) = undefined;
var test_vm_second_storage: [16 * 1024 * 1024]u8 align(page_size) = undefined;
var test_vm_multiple: bool = false;
var test_vm_second_size: usize = 0;
var test_vm_second_commit: usize = 0;
var test_vm_table: @import("r4os_contract2").R4XStartR4Sys2 = .{};
var test_vm_active: bool = false;
var test_vm_reserved_size: usize = 0;
var test_vm_committed: usize = 0;
var test_vm_peak_committed: usize = 0;
var test_vm_fail_commit: bool = false;
var test_vm_fail_decommit: bool = false;
var test_vm_fail_release: bool = false;
var test_vm_reserve_calls: u64 = 0;
var test_vm_commit_calls: u64 = 0;
var test_vm_decommit_calls: u64 = 0;
var test_vm_release_calls: u64 = 0;

fn testVmReserve(size: u64, alignment: u64, _: u64, out: *abi.ProgramVmRegionInfo) callconv(.c) i32 {
    test_wait.pause(1);
    test_vm_reserve_calls +%= 1;
    if (test_vm_multiple and test_vm_active and test_vm_second_size == 0 and size <= test_vm_second_storage.len and alignment <= page_size) {
        test_vm_second_size = @intCast(size);
        out.* = .{ .id = 2, .base = @intFromPtr(&test_vm_second_storage), .len = size };
        return abi.vm_ok;
    }
    if (test_vm_active or size > test_vm_capacity or alignment > page_size) return abi.vm_error_no_space;
    test_vm_active = true;
    test_vm_reserved_size = @intCast(size);
    test_vm_committed = 0;
    out.* = .{
        .id = 1,
        .base = @intFromPtr(&test_vm_storage),
        .len = size,
    };
    return abi.vm_ok;
}

fn testVmCommit(id: u32, offset: u64, len: u64, _: u64) callconv(.c) i32 {
    test_wait.pause(2);
    test_vm_commit_calls +%= 1;
    if (test_vm_fail_commit) return abi.vm_error_out_of_memory;
    const end = checkedAdd(@intCast(offset), @intCast(len)) orelse return abi.vm_error_invalid_range;
    if (test_vm_multiple and id == 2 and end <= test_vm_second_size) {
        test_vm_second_commit = @max(test_vm_second_commit, end);
        return abi.vm_ok;
    }
    if (!test_vm_active or id != 1 or len == 0 or end > test_vm_reserved_size) return abi.vm_error_invalid_range;
    if (end > test_vm_committed) test_vm_committed = end;
    if (test_vm_committed > test_vm_peak_committed) test_vm_peak_committed = test_vm_committed;
    return abi.vm_ok;
}

fn testVmDecommit(id: u32, offset: u64, len: u64) callconv(.c) i32 {
    test_wait.pause(3);
    test_vm_decommit_calls +%= 1;
    if (test_vm_fail_decommit) return abi.vm_error_out_of_memory;
    const end = checkedAdd(@intCast(offset), @intCast(len)) orelse return abi.vm_error_invalid_range;
    if (!test_vm_active or id != 1 or len == 0 or end > test_vm_committed) return abi.vm_error_invalid_range;
    test_vm_committed = @intCast(offset);
    return abi.vm_ok;
}

fn testVmRelease(id: u32) callconv(.c) i32 {
    test_wait.pause(4);
    test_vm_release_calls +%= 1;
    if (test_vm_multiple and id == 2 and test_vm_second_size != 0) {
        // A partial release can invalidate the header before returning an
        // error. A retry must use resident metadata, never that old header.
        @memset(test_vm_second_storage[0..page_size], 0);
        if (test_vm_fail_release) return abi.vm_error_owner_mismatch;
        test_vm_second_size = 0;
        test_vm_second_commit = 0;
        return abi.vm_ok;
    }
    if (test_vm_fail_release) return abi.vm_error_owner_mismatch;
    if (!test_vm_active or id != 1) return abi.vm_error_invalid_range;
    test_vm_active = false;
    test_vm_reserved_size = 0;
    test_vm_committed = 0;
    return abi.vm_ok;
}

fn resetTestVm() void {
    @atomicStore(u32, &state.allocator_lock, 0, .release);
    state = .{};
    test_vm_multiple = false;
    test_vm_second_size = 0;
    test_vm_second_commit = 0;
    test_vm_table = .{};
    test_vm_table.vm_reserve = @intFromPtr(&testVmReserve);
    test_vm_table.vm_commit = @intFromPtr(&testVmCommit);
    test_vm_table.vm_decommit = @intFromPtr(&testVmDecommit);
    test_vm_table.vm_release = @intFromPtr(&testVmRelease);
    test_vm_active = false;
    test_vm_reserved_size = 0;
    test_vm_committed = 0;
    test_vm_peak_committed = 0;
    test_vm_fail_commit = false;
    test_vm_fail_decommit = false;
    test_vm_fail_release = false;
    test_vm_reserve_calls = 0;
    test_vm_commit_calls = 0;
    test_vm_decommit_calls = 0;
    test_vm_release_calls = 0;
    @memset(test_vm_storage[0 .. 2 * 1024 * 1024], 0);
}

fn expectTestRegionIntegrity(region_index: usize) !void {
    const region = state.small_regions[region_index];
    try std.testing.expect(region.used);
    const end = region.base + region.committed_size;
    var addr = region.base;
    var physical_free: usize = 0;
    var previous_was_free = false;
    while (addr < end) {
        const header = headerAt(addr);
        try std.testing.expect(validSmallBlock(region, addr, header));
        const free = !isUsed(header);
        if (free) {
            try std.testing.expect((header.flags & block_flag_listed) != 0);
            try std.testing.expect(!previous_was_free);
            physical_free += 1;
        } else {
            try std.testing.expectEqual(@as(u32, 0), header.flags & block_flag_listed);
        }
        previous_was_free = free;
        addr += header.block_size;
    }
    try std.testing.expectEqual(end, addr);

    var listed_free: usize = 0;
    for (0..size_class_count) |class_index| {
        var current = region.free_heads[class_index];
        var previous: usize = 0;
        var visits: usize = 0;
        const visit_limit = region.committed_size / min_free_block + 1;
        while (current != 0 and visits < visit_limit) : (visits += 1) {
            const header = validatedFreeNode(&state, region, current, class_index, previous) orelse return error.CorruptMetadata;
            listed_free += 1;
            previous = current;
            current = freeLinks(header).next;
        }
        try std.testing.expectEqual(@as(usize, 0), current);
    }
    try std.testing.expectEqual(physical_free, listed_free);
}

test "explicit VM heaps keep allocation state separate from each other and the R4X default" {
    resetTestVm();
    var first: Heap = .{ .api = &test_vm_table };
    var second: Heap = .{ .api = &test_vm_table };
    const a1 = first.allocator();
    const a2 = second.allocator();
    const memory = try a1.alloc(u8, 128);
    @memset(memory, 0xA5);
    // This backend has one VM reservation. Reusing first's free list here
    // would incorrectly succeed instead of exposing the independent OOM.
    try std.testing.expectError(error.OutOfMemory, a2.alloc(u8, 64));
    try std.testing.expectEqual(@as(u64, 1), first.stats().active_allocations);
    try std.testing.expectEqual(@as(u64, 0), first.stats().allocation_errors);
    try std.testing.expectEqual(@as(u64, 0), second.stats().active_allocations);
    try std.testing.expectEqual(@as(u64, 1), second.stats().allocation_errors);
    try std.testing.expectEqual(@as(u64, 0), stats().active_allocations);
    try std.testing.expectEqual(@as(u64, 0), stats().allocation_errors);
    try std.testing.expectEqual(@as(u8, 0xA5), memory[127]);
    a1.free(memory);
    try std.testing.expectEqual(@as(u64, 0), first.stats().active_allocations);
}

test "mapped VM heaps own generation2 callbacks and independent stable state" {
    resetTestVm();
    const a2 = @import("r4os_contract2");
    var sys: a2.R4XStartR4Sys2 = .{};
    inline for (.{ "vm_reserve", "vm_commit", "vm_decommit", "vm_release" }) |field|
        @field(sys, field) = @field(test_vm_table, field);
    var first: MappedHeap = undefined;
    var second: MappedHeap = undefined;
    first.init(&sys);
    second.init(&sys);
    // Keep only the mapped callbacks. No caller table or context is retained.
    sys.magic = 0;
    sys.vm_reserve = 0;
    sys.vm_commit = 0;
    sys.vm_decommit = 0;
    sys.vm_release = 0;
    const a1 = first.allocator();
    const memory = try a1.alloc(u8, 257);
    @memset(memory, 0x93);
    try std.testing.expectError(error.OutOfMemory, second.allocator().alloc(u8, 64));
    try std.testing.expectEqual(@as(u64, 1), first.stats().active_allocations);
    try std.testing.expectEqual(@as(u64, 0), second.stats().active_allocations);
    try std.testing.expectEqual(@as(u64, 1), second.stats().allocation_errors);
    try std.testing.expectEqual(@as(u64, 0), stats().active_allocations);
    try std.testing.expectEqual(@as(u8, 0x93), memory[256]);
    a1.free(memory);
    first.trim();
    try std.testing.expectEqual(@as(u64, 0), first.stats().active_allocations);
    try std.testing.expect(test_vm_reserve_calls > 0 and test_vm_commit_calls > 0);
    var short: a2.R4XStartR4Sys2 = .{ .size = 16 };
    var invalid: MappedHeap = undefined;
    invalid.init(&short);
    try std.testing.expectError(error.OutOfMemory, invalid.allocator().alloc(u8, 64));
    try std.testing.expectEqual(@as(u64, 0), invalid.stats().active_allocations);
}

test "VM owner records the simultaneous active peak between stats calls" {
    resetTestVm();
    test_vm_multiple = true;
    const small_len = 4096;
    const direct_len = large_threshold + 4096;
    const small = allocatorAlloc(&state, @ptrCast(&test_vm_table), small_len, .fromByteUnits(16), 0) orelse return error.OutOfMemory;
    const direct = allocatorAlloc(&state, @ptrCast(&test_vm_table), direct_len, .fromByteUnits(16), 0) orelse return error.OutOfMemory;
    // No statistics read at the maximum: the update belongs to the mutation.
    allocatorFree(&state, @ptrCast(&test_vm_table), direct[0..direct_len], .fromByteUnits(16), 0);
    const after = stats();
    try std.testing.expectEqual(@as(u64, small_len), after.active_bytes);
    try std.testing.expectEqual(@as(u64, small_len + direct_len), after.peak_active_bytes);
    try std.testing.expectEqual(@as(u64, direct_len), after.peak_region_active_bytes);
    try std.testing.expect(after.peak_active_bytes >= after.active_bytes);
    allocatorFree(&state, @ptrCast(&test_vm_table), small[0..small_len], .fromByteUnits(16), 0);
    try std.testing.expectEqual(@as(u64, 0), stats().active_bytes);
    try std.testing.expectEqual(@as(u64, small_len + direct_len), stats().peak_active_bytes);

    resetTestVm();
    try std.testing.expectEqual(@as(u64, 0), stats().peak_active_bytes);
}

test "VM allocator mixed fragmentation workload exposes bounded search metrics" {
    resetTestVm();

    const allocation_count = 512;
    const lengths = [_]usize{ 24, 80, 192, 512, 1536, 4096, 73, 777 };
    const alignments = [_]usize{ 8, 16, 64, 256 };
    var pointers: [allocation_count]?[*]u8 = .{null} ** allocation_count;
    var sizes: [allocation_count]usize = .{0} ** allocation_count;
    var aligns: [allocation_count]usize = .{0} ** allocation_count;

    for (0..allocation_count) |i| {
        const len = lengths[i % lengths.len];
        const alignment = alignments[i % alignments.len];
        const memory = allocatorAlloc(&state, @ptrCast(&test_vm_table), len, .fromByteUnits(alignment), 0) orelse return error.OutOfMemory;
        try std.testing.expectEqual(@as(usize, 0), @intFromPtr(memory) & (alignment - 1));
        @memset(memory[0..len], @intCast(i % 251));
        pointers[i] = memory;
        sizes[i] = len;
        aligns[i] = alignment;
    }

    for (0..allocation_count) |i| {
        if ((i & 1) != 0) continue;
        const memory = pointers[i].?;
        allocatorFree(&state, @ptrCast(&test_vm_table), memory[0..sizes[i]], .fromByteUnits(aligns[i]), 0);
        pointers[i] = null;
    }

    const frees_before_repeat = stats().frees;
    const first_backref_addr = state.small_regions[0].base + @sizeOf(BlockHeader);
    const first_user_addr = alignForward(first_backref_addr + @sizeOf(usize), aligns[0]).?;
    const first_freed: [*]u8 = @ptrFromInt(first_user_addr);
    allocatorFree(&state, @ptrCast(&test_vm_table), first_freed[0..sizes[0]], .fromByteUnits(aligns[0]), 0);
    try std.testing.expectEqual(frees_before_repeat, stats().frees);

    for (0..allocation_count) |i| {
        if ((i & 1) != 0) continue;
        const memory = allocatorAlloc(&state, @ptrCast(&test_vm_table), sizes[i], .fromByteUnits(aligns[i]), 0) orelse return error.OutOfMemory;
        try std.testing.expectEqual(@as(usize, 0), @intFromPtr(memory) & (aligns[i] - 1));
        pointers[i] = memory;
    }

    for (0..allocation_count) |i| {
        if ((i & 1) == 0) continue;
        for (pointers[i].?[0..sizes[i]]) |byte| try std.testing.expectEqual(@as(u8, @intCast(i % 251)), byte);
    }

    const measured = stats();
    // The instrumented legacy First-Fit implementation needed 197746 block,
    // 63213 backward and 131152 region-end visits for this exact workload.
    try std.testing.expectEqual(@as(u64, allocation_count + allocation_count / 2), measured.allocations);
    try std.testing.expectEqual(@as(u64, allocation_count / 2), measured.frees);
    try std.testing.expectEqual(@as(u64, allocation_count), measured.active_allocations);
    try std.testing.expect(measured.allocation_search_steps <= allocation_count * 2);
    try std.testing.expect(measured.class_search_steps <= measured.allocations * size_class_count);
    try std.testing.expect(measured.backward_search_steps <= measured.frees);
    try std.testing.expect(measured.end_search_steps <= measured.frees + measured.vm_commit_calls);
    try std.testing.expectEqual(@as(u64, 0), measured.corruptions);
    try std.testing.expectEqual(@as(u64, 1), test_vm_reserve_calls);
    try std.testing.expectEqual(test_vm_reserve_calls, measured.vm_reserve_calls);
    try std.testing.expectEqual(test_vm_commit_calls, measured.vm_commit_calls);
    try std.testing.expect(measured.vm_commit_calls <= 5);
    try std.testing.expectEqual(test_vm_decommit_calls, measured.vm_decommit_calls);
    try std.testing.expectEqual(test_vm_release_calls, measured.vm_release_calls);
    try expectTestRegionIntegrity(0);

    for (0..allocation_count) |i| {
        const memory = pointers[i].?;
        allocatorFree(&state, @ptrCast(&test_vm_table), memory[0..sizes[i]], .fromByteUnits(aligns[i]), 0);
    }
    const complete = stats();
    try std.testing.expectEqual(@as(u64, allocation_count + allocation_count / 2), complete.frees);
    try std.testing.expectEqual(@as(u64, 0), complete.active_allocations);
    try std.testing.expect(complete.coalesces > 0);
    try std.testing.expectEqual(@as(u64, 0), complete.corruptions);
    try expectTestRegionIntegrity(0);
}

test "VM allocator rolls back VM failures and preserves direct ownership" {
    resetTestVm();
    test_vm_fail_commit = true;
    try std.testing.expectEqual(@as(?[*]u8, null), allocatorAlloc(&state, @ptrCast(&test_vm_table), 128, .fromByteUnits(16), 0));
    try std.testing.expect(!test_vm_active);
    try std.testing.expectEqual(@as(u64, 1), test_vm_reserve_calls);
    try std.testing.expectEqual(@as(u64, 1), test_vm_commit_calls);
    try std.testing.expectEqual(@as(u64, 1), test_vm_release_calls);
    try std.testing.expectEqual(@as(u32, 0), stats().small_regions);

    resetTestVm();
    test_vm_fail_commit = true;
    test_vm_fail_release = true;
    try std.testing.expectEqual(@as(?[*]u8, null), allocatorAlloc(&state, @ptrCast(&test_vm_table), 128, .fromByteUnits(16), 0));
    try std.testing.expect(state.retired_reservation != null);
    const private_reserve_calls = test_vm_reserve_calls;
    try std.testing.expectEqual(@as(?[*]u8, null), allocatorAlloc(&state, @ptrCast(&test_vm_table), 128, .fromByteUnits(16), 0));
    try std.testing.expectEqual(private_reserve_calls, test_vm_reserve_calls);
    test_vm_fail_commit = false;
    test_vm_fail_release = false;
    const after_rollback = allocatorAlloc(&state, @ptrCast(&test_vm_table), 128, .fromByteUnits(16), 0) orelse return error.OutOfMemory;
    try std.testing.expect(state.retired_reservation == null);
    allocatorFree(&state, @ptrCast(&test_vm_table), after_rollback[0..128], .fromByteUnits(16), 0);
    try std.testing.expectEqual(@as(u64, 0), stats().active_allocations);

    resetTestVm();
    const small = allocatorAlloc(&state, @ptrCast(&test_vm_table), 128, .fromByteUnits(16), 0) orelse return error.OutOfMemory;
    const committed_before_failure = state.small_regions[0].committed_size;
    test_vm_fail_commit = true;
    try std.testing.expectEqual(@as(?[*]u8, null), allocatorAlloc(&state, @ptrCast(&test_vm_table), 192 * 1024, .fromByteUnits(64), 0));
    try std.testing.expectEqual(committed_before_failure, state.small_regions[0].committed_size);
    try std.testing.expectEqual(@as(u64, 1), stats().active_allocations);
    try expectTestRegionIntegrity(0);

    test_vm_fail_commit = false;
    const large_small_len = 768 * 1024;
    const large_small = allocatorAlloc(&state, @ptrCast(&test_vm_table), large_small_len, .fromByteUnits(64), 0) orelse return error.OutOfMemory;
    const committed_before_decommit = state.small_regions[0].committed_size;
    test_vm_fail_decommit = true;
    allocatorFree(&state, @ptrCast(&test_vm_table), large_small[0..large_small_len], .fromByteUnits(64), 0);
    try std.testing.expect(state.small_regions[0].committed_size < committed_before_decommit);
    try std.testing.expectEqual(committed_before_decommit - state.small_regions[0].committed_size, state.small_regions[0].pending_decommit_len);
    try std.testing.expectEqual(@as(u64, 1), test_vm_decommit_calls);
    try std.testing.expectEqual(@as(u64, 1), stats().active_allocations);
    try expectTestRegionIntegrity(0);
    test_vm_fail_decommit = false;
    allocatorFree(&state, @ptrCast(&test_vm_table), small[0..128], .fromByteUnits(16), 0);
    try std.testing.expectEqual(@as(u64, 0), stats().active_allocations);
    try expectTestRegionIntegrity(0);

    resetTestVm();
    const resized = allocatorAlloc(&state, @ptrCast(&test_vm_table), 256, .fromByteUnits(64), 0) orelse return error.OutOfMemory;
    @memset(resized[0..256], 0x5A);
    try std.testing.expect(allocatorResize(&state, @ptrCast(&test_vm_table), resized[0..256], .fromByteUnits(64), 48 * 1024, 0));
    for (resized[0..256]) |byte| try std.testing.expectEqual(@as(u8, 0x5A), byte);
    try std.testing.expect(allocatorResize(&state, @ptrCast(&test_vm_table), resized[0 .. 48 * 1024], .fromByteUnits(64), 64, 0));
    try std.testing.expectEqual(@as(u64, 64), stats().active_bytes);
    allocatorFree(&state, @ptrCast(&test_vm_table), resized[0..64], .fromByteUnits(64), 0);
    try std.testing.expectEqual(@as(u64, 0), stats().active_allocations);
    try expectTestRegionIntegrity(0);

    resetTestVm();
    const direct_len = direct_cache_max_region + page_size;
    const direct = allocatorAlloc(&state, @ptrCast(&test_vm_table), direct_len, .fromByteUnits(64), 0) orelse return error.OutOfMemory;
    @memset(direct[0..256], 0xA5);
    try std.testing.expectEqual(@as(u32, 1), stats().direct_active);
    try std.testing.expect(allocatorResize(&state, @ptrCast(&test_vm_table), direct[0..direct_len], .fromByteUnits(64), direct_len / 2, 0));
    try std.testing.expectEqual(@as(u64, direct_len / 2), stats().active_bytes);
    for (direct[0..256]) |byte| try std.testing.expectEqual(@as(u8, 0xA5), byte);

    test_vm_fail_release = true;
    allocatorFree(&state, @ptrCast(&test_vm_table), direct[0 .. direct_len / 2], .fromByteUnits(64), 0);
    try std.testing.expectEqual(@as(u32, 1), stats().direct_active);
    try std.testing.expect(test_vm_active);
    test_vm_fail_release = false;
    allocatorFree(&state, @ptrCast(&test_vm_table), direct[0 .. direct_len / 2], .fromByteUnits(64), 0);
    try std.testing.expectEqual(@as(u32, 0), stats().direct_active);
    try std.testing.expect(!test_vm_active);
    try std.testing.expectEqual(test_vm_reserve_calls, stats().vm_reserve_calls);
    try std.testing.expectEqual(test_vm_commit_calls, stats().vm_commit_calls);
    try std.testing.expectEqual(test_vm_release_calls, stats().vm_release_calls);

    resetTestVm();
    const cached_len = large_threshold + 128 * 1024;
    const cached = allocatorAlloc(&state, @ptrCast(&test_vm_table), cached_len, .fromByteUnits(64), 0) orelse return error.OutOfMemory;
    allocatorFree(&state, @ptrCast(&test_vm_table), cached[0..cached_len], .fromByteUnits(64), 0);
    try std.testing.expectEqual(@as(u32, 1), stats().direct_cached);
    const oversized_len = direct_cache_max_region + page_size;
    const oversized = allocatorAlloc(&state, @ptrCast(&test_vm_table), oversized_len, .fromByteUnits(64), 0) orelse return error.OutOfMemory;
    const reclaimed = stats();
    try std.testing.expectEqual(@as(u32, 0), reclaimed.direct_cached);
    try std.testing.expectEqual(@as(u64, 1), reclaimed.trim_calls);
    try std.testing.expect(reclaimed.trim_reclaimed_bytes >= cached_len);
    try std.testing.expectEqual(@as(u64, 3), reclaimed.vm_reserve_calls);
    try std.testing.expectEqual(@as(u64, 2), reclaimed.vm_commit_calls);
    try std.testing.expectEqual(@as(u64, 1), reclaimed.vm_release_calls);
    allocatorFree(&state, @ptrCast(&test_vm_table), oversized[0..oversized_len], .fromByteUnits(64), 0);
    try std.testing.expectEqual(@as(u64, 0), stats().active_allocations);
    try std.testing.expect(!test_vm_active);
}

test "VM allocator keeps multiple failed direct frees and closes only after real release" {
    resetTestVm();
    test_vm_multiple = true;
    const length = direct_cache_max_region + page_size;
    const a = allocator(&test_vm_table);
    const first = try a.alloc(u8, length);
    const second = try a.alloc(u8, length);
    try std.testing.expectEqual(Shutdown.busy, shutdown(&test_vm_table));
    test_vm_fail_release = true;
    a.free(first);
    a.free(second);
    try std.testing.expectEqual(@as(u32, 2), stats().direct_retiring);
    try std.testing.expectEqual(@as(u32, 2), stats().direct_active);
    try std.testing.expectEqual(Shutdown.pending, shutdown(&test_vm_table));
    const old_base = state.retiring_direct.?.base;
    @memset(@as([*]u8, @ptrFromInt(old_base))[0..page_size], 0);
    test_vm_fail_release = false;
    try std.testing.expectEqual(Shutdown.done, shutdown(&test_vm_table));
    try std.testing.expectEqual(@as(u64, 0), stats().active_allocations);
    try std.testing.expectEqual(@as(u64, 0), stats().reserved_bytes);
    try std.testing.expect(!test_vm_active and test_vm_second_size == 0);
    try std.testing.expectEqual(@as(usize, 0), state.retiring_direct_head);

    resetTestVm();
    const small = try a.alloc(u8, 128);
    try std.testing.expectEqual(Shutdown.busy, shutdown(&test_vm_table));
    a.free(small);
    test_vm_fail_release = true;
    try std.testing.expectEqual(Shutdown.pending, shutdown(&test_vm_table));
    test_vm_fail_release = false;
    try std.testing.expectEqual(Shutdown.done, shutdown(&test_vm_table));
    try std.testing.expect(!test_vm_active);
}

test "VM allocator rejects damaged boundary tags and repeated frees fail closed" {
    resetTestVm();
    const first = allocatorAlloc(&state, @ptrCast(&test_vm_table), 192, .fromByteUnits(64), 0) orelse return error.OutOfMemory;
    const second = allocatorAlloc(&state, @ptrCast(&test_vm_table), 96, .fromByteUnits(16), 0) orelse return error.OutOfMemory;
    const header = headerFromUser(&state, first, 64) orelse return error.MissingHeader;
    const footer = footerFromHeader(header);

    footer.magic = 0;
    allocatorFree(&state, @ptrCast(&test_vm_table), first[0..192], .fromByteUnits(64), 0);
    try std.testing.expectEqual(@as(u64, 1), stats().corruptions);
    try std.testing.expectEqual(@as(u64, 2), stats().active_allocations);
    footer.magic = footer_magic;

    header.magic = 0;
    allocatorFree(&state, @ptrCast(&test_vm_table), first[0..192], .fromByteUnits(64), 0);
    try std.testing.expectEqual(@as(u64, 2), stats().corruptions);
    try std.testing.expectEqual(@as(u64, 2), stats().active_allocations);
    header.magic = block_magic;

    allocatorFree(&state, @ptrCast(&test_vm_table), first[0..192], .fromByteUnits(64), 0);
    const after_first_free = stats();
    try std.testing.expectEqual(@as(u64, 1), after_first_free.frees);
    allocatorFree(&state, @ptrCast(&test_vm_table), first[0..192], .fromByteUnits(64), 0);
    try std.testing.expectEqual(after_first_free.frees, stats().frees);
    try std.testing.expectEqual(after_first_free.corruptions, stats().corruptions);

    allocatorFree(&state, @ptrCast(&test_vm_table), second[0..96], .fromByteUnits(16), 0);
    try std.testing.expectEqual(@as(u64, 0), stats().active_allocations);
    try std.testing.expectEqual(@as(u64, 2), stats().corruptions);
    try expectTestRegionIntegrity(0);
}

fn concurrentAllocatorWorker(worker_index: usize, failed: *u32) void {
    const slot_count = 32;
    var pointers: [slot_count]?[*]u8 = .{null} ** slot_count;
    var sizes: [slot_count]usize = .{0} ** slot_count;
    var alignments: [slot_count]usize = .{0} ** slot_count;
    var patterns: [slot_count]u8 = .{0} ** slot_count;
    var value: u64 = 0x9E3779B97F4A7C15 ^ @as(u64, worker_index + 1);

    var operation: usize = 0;
    while (operation < 4096 and @atomicLoad(u32, failed, .acquire) == 0) : (operation += 1) {
        value = value *% 6364136223846793005 +% 1442695040888963407;
        const slot: usize = @intCast((value >> 32) % slot_count);
        if (pointers[slot]) |memory| {
            const last = sizes[slot] - 1;
            if (memory[0] != patterns[slot] or memory[last] != patterns[slot]) {
                @atomicStore(u32, failed, 1, .release);
                break;
            }
            allocatorFree(&state, @ptrCast(&test_vm_table), memory[0..sizes[slot]], .fromByteUnits(alignments[slot]), 0);
            pointers[slot] = null;
        } else {
            const len = 1 + @as(usize, @intCast((value >> 16) % 8192));
            const worker_alignments = [_]usize{ 8, 16, 64, 256 };
            const alignment = worker_alignments[@as(usize, @intCast(value & 3))];
            const memory = allocatorAlloc(&state, @ptrCast(&test_vm_table), len, .fromByteUnits(alignment), 0) orelse {
                @atomicStore(u32, failed, 1, .release);
                break;
            };
            const pattern: u8 = @intCast((worker_index * 37 + operation) % 251);
            @memset(memory[0..len], pattern);
            pointers[slot] = memory;
            sizes[slot] = len;
            alignments[slot] = alignment;
            patterns[slot] = pattern;
        }
    }

    for (0..slot_count) |slot| {
        if (pointers[slot]) |memory| {
            allocatorFree(&state, @ptrCast(&test_vm_table), memory[0..sizes[slot]], .fromByteUnits(alignments[slot]), 0);
        }
    }
}

test "VM allocator serializes concurrent R4X thread traffic" {
    resetTestVm();
    var failed: u32 = 0;
    var threads: [4]std.Thread = undefined;
    for (&threads, 0..) |*thread, worker_index| {
        thread.* = try std.Thread.spawn(.{}, concurrentAllocatorWorker, .{ worker_index, &failed });
    }
    for (&threads) |*thread| thread.join();

    try std.testing.expectEqual(@as(u32, 0), @atomicLoad(u32, &failed, .acquire));
    try std.testing.expectEqual(@as(u64, 0), stats().active_allocations);
    try std.testing.expectEqual(@as(u64, 0), stats().corruptions);
    try expectTestRegionIntegrity(0);
}

const HandoffWorker = struct {
    allocator: std.mem.Allocator,
    length: usize,
    freeing: ?[]u8 = null,
    result: ?[]u8 = null,

    fn run(self: *HandoffWorker) void {
        if (self.freeing) |memory| {
            self.allocator.free(memory);
        } else {
            self.result = self.allocator.alloc(u8, self.length) catch null;
        }
    }
};

test "VM allocator keeps free capacity live across exact VM handoffs and notification enrollment" {
    resetTestVm();
    var unavailable: @import("r4os_contract2").R4XStartR4Sys2 = .{};
    try std.testing.expectError(error.OutOfMemory, allocator(&unavailable).alloc(u8, 128));
    try std.testing.expectEqual(@as(usize, 0), @atomicLoad(usize, &state.wait_api, .acquire));
    const recovered = try allocator(&test_vm_table).alloc(u8, 128);
    try std.testing.expectEqual(@intFromPtr(&test_vm_table), @atomicLoad(usize, &state.wait_api, .acquire));
    allocator(&test_vm_table).free(recovered);
    resetTestVm();
    test_wait.install(&test_vm_table);
    try test_wait.checkRevisionContract(&test_vm_table);

    inline for (.{ false, true }) |explicit| {
        for (1..5) |kind| {
            resetTestVm();
            test_wait.install(&test_vm_table);
            var heap: Heap = .{ .api = &test_vm_table };
            const a = if (explicit) heap.allocator() else allocator(&test_vm_table);
            const storage = if (explicit) &heap.storage else &state;
            const seed = try a.alloc(u8, 128);
            @memset(seed, 0xA5);
            const blocker = if (kind == 2) try a.alloc(u8, 768 * 1024) else null;
            var worker: HandoffWorker = .{ .allocator = a, .length = if (kind == 1) large_threshold else 192 * 1024 };
            if (kind == 3) worker.freeing = try a.alloc(u8, 768 * 1024);
            if (kind == 4) {
                test_vm_multiple = true;
                worker.freeing = try a.alloc(u8, direct_cache_max_region + page_size);
                test_vm_fail_release = true;
            }
            test_wait.arm(@intCast(kind));
            const thread = try std.Thread.spawn(.{}, HandoffWorker.run, .{&worker});
            var joined = false;
            defer if (!joined) thread.join();
            defer test_wait.continueWork();
            test_wait.awaitPause();
            try std.testing.expect(storage.vm_operation != 0);
            // This changes the last free block while the old commit is
            // unpublished; completion must derive its current boundary tags.
            const fast = try a.alloc(u8, 64);
            @memset(fast, 0x5A);
            try std.testing.expect(a.resize(fast, 256));
            const parked_before = test_wait.parked.load(.acquire);
            var waiter: HandoffWorker = .{ .allocator = a, .length = if (kind == 3) 768 * 1024 else 384 * 1024 };
            const second = try std.Thread.spawn(.{}, HandoffWorker.run, .{&waiter});
            test_wait.awaitPark(parked_before);
            if (blocker) |memory| {
                a.free(memory); // Wake on real free publication, even though
                // the other VM commit is still deliberately paused.
            } else test_wait.continueWork();
            second.join();
            test_wait.continueWork();
            thread.join();
            joined = true;
            const waiting_memory = waiter.result orelse return error.WaiterAllocationFailed;
            if (kind == 1) try std.testing.expect(worker.result == null);
            if (kind == 2) a.free(worker.result orelse return error.WorkerAllocationFailed);
            if (kind == 4) {
                try std.testing.expectEqual(@as(u32, 1), stateStats(storage).direct_active);
                const retired = worker.freeing.?;
                try std.testing.expect(!a.resize(retired, retired.len + 1));
                test_vm_fail_release = false;
                a.free(retired); // Header was erased by the failed backend.
                try std.testing.expectEqual(@as(u32, 0), stateStats(storage).direct_active);
                try std.testing.expect(storage.retiring_direct == null);
            }
            for (seed) |byte| try std.testing.expectEqual(@as(u8, 0xA5), byte);
            for (fast) |byte| try std.testing.expectEqual(@as(u8, 0x5A), byte);
            a.free(waiting_memory);
            const resized: []u8 = fast.ptr[0..256];
            a.free(resized);
            a.free(seed);
            try std.testing.expectEqual(@as(u64, 0), stateStats(storage).active_allocations);
            try std.testing.expectEqual(@as(u64, 0), stateStats(storage).corruptions);
            try std.testing.expectEqual(@as(u64, 0), storage.vm_operation);
            try std.testing.expectEqual(@as(u64, 0), storage.lock_wait.handle);
            try std.testing.expectEqual(@as(u64, 0), storage.vm_wait.handle);
            try test_wait.expectClosed();
        }
    }
}

test "VM allocator reports small and direct churn VM traffic" {
    // The committed 0.75.2 implementation needed 1/129/128/0
    // reserve/commit/decommit/release calls for this exact small workload.
    const small_cycles = 128;
    const small_len = 192 * 1024;
    resetTestVm();
    for (0..small_cycles) |_| {
        const memory = allocatorAlloc(&state, @ptrCast(&test_vm_table), small_len, .fromByteUnits(64), 0) orelse return error.OutOfMemory;
        memory[0] = 0x41;
        memory[small_len - 1] = 0x42;
        allocatorFree(&state, @ptrCast(&test_vm_table), memory[0..small_len], .fromByteUnits(64), 0);
    }
    const small = stats();
    try std.testing.expectEqual(@as(u64, 0), small.active_allocations);
    try std.testing.expectEqual(@as(u64, small_cycles), small.allocations);
    try std.testing.expectEqual(@as(u64, small_cycles), small.frees);
    try std.testing.expectEqual(@as(u64, 1), small.vm_reserve_calls);
    try std.testing.expectEqual(@as(u64, 2), small.vm_commit_calls);
    try std.testing.expectEqual(@as(u64, 0), small.vm_decommit_calls);
    try std.testing.expectEqual(@as(u64, 0), small.vm_release_calls);
    try std.testing.expect(small.peak_committed_bytes <= 320 * 1024);
    try std.testing.expect(small.committed_bytes <= 320 * 1024);
    try std.testing.expectEqual(small.peak_committed_bytes, test_vm_peak_committed);
    trim(&test_vm_table);
    const small_trimmed = stats();
    try std.testing.expectEqual(@as(u64, 1), small_trimmed.vm_decommit_calls);
    try std.testing.expectEqual(@as(u64, page_size), small_trimmed.committed_bytes);
    try std.testing.expect(small_trimmed.trim_reclaimed_bytes >= small.committed_bytes - page_size);
    try expectTestRegionIntegrity(0);

    // The committed 0.75.2 implementation needed 64/64/0/64 VM calls for
    // the exact direct workload and retained no region between iterations.
    const direct_cycles = 64;
    const direct_len = large_threshold + 128 * 1024;
    const direct_need = conservativeBlockNeed(direct_len, page_size).?;
    const expected_direct_reserve = alignForward(direct_need, page_size).?;
    resetTestVm();
    for (0..direct_cycles) |_| {
        const memory = allocatorAlloc(&state, @ptrCast(&test_vm_table), direct_len, .fromByteUnits(64), 0) orelse return error.OutOfMemory;
        memory[0] = 0x51;
        memory[direct_len - 1] = 0x52;
        allocatorFree(&state, @ptrCast(&test_vm_table), memory[0..direct_len], .fromByteUnits(64), 0);
    }
    const direct = stats();
    try std.testing.expectEqual(@as(u64, 0), direct.active_allocations);
    try std.testing.expectEqual(@as(u64, direct_cycles), direct.allocations);
    try std.testing.expectEqual(@as(u64, direct_cycles), direct.frees);
    try std.testing.expectEqual(@as(u64, 1), direct.vm_reserve_calls);
    try std.testing.expectEqual(@as(u64, 1), direct.vm_commit_calls);
    try std.testing.expectEqual(@as(u64, 0), direct.vm_decommit_calls);
    try std.testing.expectEqual(@as(u64, 0), direct.vm_release_calls);
    try std.testing.expectEqual(@as(u64, direct_cycles - 1), direct.direct_cache_hits);
    try std.testing.expectEqual(@as(u64, 1), direct.direct_cache_misses);
    try std.testing.expectEqual(@as(u32, 1), direct.direct_cached);
    try std.testing.expectEqual(@as(u64, expected_direct_reserve), direct.cached_bytes);
    try std.testing.expectEqual(@as(u64, expected_direct_reserve), direct.peak_committed_bytes);
    try std.testing.expectEqual(direct.peak_committed_bytes, test_vm_peak_committed);

    test_vm_fail_release = true;
    trim(&test_vm_table);
    try std.testing.expectEqual(@as(u32, 1), stats().direct_cached);
    try std.testing.expect(test_vm_active);
    test_vm_fail_release = false;
    trim(&test_vm_table);
    const direct_trimmed = stats();
    try std.testing.expectEqual(@as(u32, 0), direct_trimmed.direct_cached);
    try std.testing.expectEqual(@as(u64, 0), direct_trimmed.cached_bytes);
    try std.testing.expectEqual(@as(u64, 0), direct_trimmed.committed_bytes);
    try std.testing.expectEqual(@as(u64, 2), direct_trimmed.vm_release_calls);
    try std.testing.expect(!test_vm_active);
}
