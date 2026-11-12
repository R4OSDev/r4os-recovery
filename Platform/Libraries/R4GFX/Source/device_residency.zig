//! R4GFX owns logical images; the R4D owns their physical BOs. Eviction
//! preserves mutable image contents through the actual copy queue and keeps
//! the public R4GFX handle stable while replacing its private BO identity.
//! Scanout, imports, shared aliases and in-flight work are not evictable.
const std = @import("std");
const a = @import("r4os").abi;
const d = @import("device.zig");
const c = d.c;
const resources = @import("device_resources.zig");
pub const pinned_priority = c.memory_priority_pinned;
pub const Phase = enum(u32) { idle, prepare, allocate, describe, submit, copy, retire };
pub const Work = struct {
    phase: Phase = .prepare,
    index: usize,
    serial: u64,
    restore: bool,
    deadline: u64,
    binding: a.GfxBackendBinding,
    memory_generation: u64,
    request: a.GfxBufferHandle = .{},
    other: a.GfxBufferReference = .{},
    descriptor: a.GfxBufferDescriptor = .{},
    amd_image: ?@import("amd_images.zig").Result = null,
    image: c.R4GfxCpuImage = std.mem.zeroes(c.R4GfxCpuImage),
    fence: a.GfxFence = .{},
    commit: bool = false,
    cancelled: bool = false,
    failure: ?d.Error = null,
};
pub const Snapshot = struct {
    phase: Phase = .idle,
    resident_bytes: u64 = 0,
    evicted_bytes: u64 = 0,
    system_bytes: u64 = 0,
    pinned_bytes: u64 = 0,
    pending_bytes: u64 = 0,
    reclaimable_bytes: u64 = 0,
};
pub fn eligible(device: *const d.Device, item: *const d.Resource) bool {
    if (item.serial == 0 or item.kind != c.resource_image or item.source_kind != c.source_create_native or
        item.public_refs == 0 or item.invalidated or item.evicted or item.residency_busy or item.job_refs != 0 or
        item.map.lease.id != 0 or item.priority == pinned_priority or item.descriptor.location != a.gfx_buffer_location_device_local or
        item.descriptor.usage & a.gfx_buffer_usage_scanout != 0 or item.backing.reference.id == 0) return false;
    if (device.native_yuv.contains(item.backing.buffer)) return false;
    // A second resource may share this mutable BO. Replacing just one alias
    // would split their contents, even if the physical BO remained alive.
    for (&device.resources) |*other| if (other != item and other.serial != 0 and
        std.meta.eql(other.backing.buffer, item.backing.buffer)) return false;
    return true;
}
pub fn snapshot(device: *const d.Device) Snapshot {
    var result: Snapshot = .{};
    next: for (&device.resources, 0..) |*item, index| if (item.serial != 0 and item.backing.reference.id != 0) {
        for (device.resources[0..index]) |*prior| if (prior.serial != 0 and prior.backing.reference.id != 0 and
            std.meta.eql(prior.backing.buffer, item.backing.buffer)) continue :next;
        if (item.descriptor.location == a.gfx_buffer_location_device_local) {
            result.resident_bytes += item.descriptor.byte_length;
            if (eligible(device, item)) result.reclaimable_bytes += item.descriptor.byte_length else result.pinned_bytes += item.descriptor.byte_length;
        } else result.system_bytes += item.descriptor.byte_length;
        if (item.evicted) result.evicted_bytes += item.native_bytes;
    };
    if (device.residency_work) |work| {
        result.phase = work.phase;
        if (work.other.reference.id != 0) result.pending_bytes = work.descriptor.byte_length;
    }
    // Native cache references can outlive a logical image/decoder reference.
    // Count those BOs once, including the bounded coherent command uploads.
    cached: for (&device.native_yuv.entries, 0..) |*entry, index| {
        const item = &entry.resource;
        if (!item.live()) continue;
        for (&device.resources) |*logical| if (logical.serial != 0 and logical.backing.reference.id != 0 and
            std.meta.eql(logical.backing.buffer, item.backing.buffer)) continue :cached;
        for (device.native_yuv.entries[0..index]) |*prior| if (prior.resource.live() and
            std.meta.eql(prior.resource.backing.buffer, item.backing.buffer)) continue :cached;
        if (item.descriptor.location == a.gfx_buffer_location_device_local) {
            result.resident_bytes += item.descriptor.byte_length;
            result.pinned_bytes += item.descriptor.byte_length;
        } else result.system_bytes += item.descriptor.byte_length;
    }
    for (&device.native_yuv.uploads) |*item| if (item.live()) { result.system_bytes += item.descriptor.byte_length; };
    return result;
}
fn now(device: *d.Device) d.Error!u64 {
    const instant = device.base().monotonicNanoseconds() orelse return error.Unavailable;
    if (instant == 0 or instant == std.math.maxInt(u64)) return error.Unavailable;
    return instant;
}
fn begin(device: *d.Device, index: usize, restore: bool, deadline: u64) d.Error!void {
    if (device.closing or device.residency_work != null) return error.Busy;
    if (deadline == 0 or deadline == std.math.maxInt(u64) or try now(device) >= deadline) return error.Invalid;
    if (device.selected.binding.adapter_id == 0 or device.gpu_operations & c.device_gpu_copy_rows == 0) return error.Unsupported;
    const item = &device.resources[index];
    if (item.job_refs != 0 or item.residency_busy or item.map.lease.id != 0) return error.Busy;
    if (item.native_layout != 0 and device.gpu_operations & c.device_gpu_copy_layout == 0) return error.Unsupported;
    item.job_refs += 1; item.residency_busy = true;
    item.resident_result = null;
    device.residency_work = .{ .index = index, .serial = item.serial, .restore = restore, .deadline = deadline,
        .binding = device.selected.binding, .memory_generation = device.selected.memory_generation };
}
/// One victim per request: bounded work, no waiting loop or reservation per
/// application. Actual driver charges fall only after RM retirement as usual.
pub fn trim(device: *d.Device, deadline: u64) d.Error!void {
    if (device.residency_work != null) return error.Busy;
    if (device.residency_pending != 0) return error.Busy;
    var candidate: ?usize = null;
    for (&device.resources, 0..) |*item, index| if (eligible(device, item)) {
        if (candidate) |old| {
            const previous = &device.resources[old];
            if (item.priority > previous.priority or (item.priority == previous.priority and item.last_use >= previous.last_use)) continue;
        }
        candidate = index;
    };
    try begin(device, candidate orelse return error.Limit, false, deadline);
}
pub fn ensure(device: *d.Device, item: *d.Resource, deadline: u64) d.Error!void {
    if (item.residency_busy) return error.Busy;
    if (!item.evicted) return;
    if (item.resident_result) |err| { item.resident_result = null; return err; }
    if (item.invalidated or item.source_kind != c.source_create_native or item.public_refs == 0) return error.Stale;
    if (device.selected.binding.adapter_id == 0 or device.gpu_operations & c.device_gpu_copy_rows == 0) return error.Unsupported;
    for (&device.resources) |*other| if (other != item and other.serial != 0 and
        std.meta.eql(other.backing.buffer, item.backing.buffer)) return error.Busy;
    if (deadline == 0 or deadline == std.math.maxInt(u64) or try now(device) >= deadline) return error.Invalid;
    if (item.resident_deadline == 0) {
        device.residency_order = std.math.add(u64, device.residency_order, 1) catch return error.Limit;
        item.resident_order = device.residency_order; item.resident_deadline = deadline;
        device.residency_pending += 1;
    } else item.resident_deadline = @min(item.resident_deadline, deadline);
    if (device.residency_work) |*work| {
        // Requested image use takes precedence over a background readback
        // that has not submitted a GPU command yet. Submitted copies retain
        // both endpoints and yield only after their real completion.
        if (!work.restore and work.fence.timeline == 0) work.cancelled = true;
    } else startNext(device);
    return error.Busy; // The copy receipt, not allocation alone, makes it resident.
}
fn startNext(device: *d.Device) void {
    if (device.closing or device.residency_work != null or device.residency_pending == 0) return;
    const instant = now(device) catch return;
    var selected: ?usize = null;
    next: for (&device.resources, 0..) |*item, index| if (item.resident_deadline != 0) {
        if (item.public_refs == 0 or item.invalidated or !item.evicted or instant >= item.resident_deadline) {
            item.resident_deadline = 0; device.residency_pending -= 1; continue;
        }
        if (item.job_refs != 0 or item.residency_busy or item.map.lease.id != 0) continue;
        for (&device.resources) |*other| if (other != item and other.serial != 0 and
            std.meta.eql(other.backing.buffer, item.backing.buffer)) continue :next;
        if (selected) |previous| {
            const prior = &device.resources[previous];
            if (item.priority < prior.priority or (item.priority == prior.priority and item.resident_order >= prior.resident_order)) continue;
        }
        selected = index;
    };
    const index = selected orelse return;
    const item = &device.resources[index];
    begin(device, index, true, item.resident_deadline) catch return;
    item.resident_deadline = 0; device.residency_pending -= 1;
}
fn fail(work: *Work, err: d.Error) void {
    if (work.failure == null) work.failure = err;
    work.commit = false;
    work.phase = .retire;
}
pub fn holdsQueue(device: *const d.Device, timeline: u64) bool {
    return if (device.residency_work) |work| work.fence.timeline != 0 and work.fence.timeline == timeline else false;
}
/// One bounded state transition, called from ordinary device progress. A
/// cancel/deadline/app close never substitutes for physical queue retirement.
pub fn step(device: *d.Device) void {
    const work = if (device.residency_work) |*value| value else { startNext(device); return; };
    const item = &device.resources[work.index];
    std.debug.assert(item.serial == work.serial and item.residency_busy and item.job_refs != 0);
    const memory = device.buffers();
    const queues = device.queues();
    const instant = now(device) catch work.deadline;
    if (work.cancelled or device.closing or item.public_refs == 0 or instant >= work.deadline or item.invalidated or
        !std.meta.eql(work.binding, device.selected.binding) or work.memory_generation != device.selected.memory_generation) {
        work.cancelled = true;
        if (work.phase != .copy) fail(work, if (item.invalidated) error.Stale else error.Unavailable);
    }
    switch (work.phase) {
        .idle => unreachable,
        .prepare => {
            if (work.restore) {
                var status: a.GfxNativeStatus = .{};
                const rc = memory.nativeStart(&.{ .adapter_id = work.binding.adapter_id, .memory_generation = work.memory_generation,
                    .deadline_ns = work.deadline, .kind = 1, .width = item.image.width, .height = item.image.height,
                    .format = item.image.format, .layout = item.native_layout, .usage = 28 }, &status);
                d.platform(rc) catch |err| { fail(work, err); return; };
                work.request = status.request; work.phase = .allocate;
            } else {
                const row = @as(u64, item.image.width) * (resources.pixelBytes(item.image.format) catch { fail(work, error.Unsupported); return; });
                const bytes = std.math.mul(u64, row, item.image.height) catch { fail(work, error.Overflow); return; };
                const descriptor: a.GfxBufferDescriptor = .{ .byte_length = bytes, .width = item.image.width, .height = item.image.height,
                    .format = item.image.format, .plane_count = 1, .plane_pitches = .{ row, 0, 0, 0 }, .usage = 31 };
                d.platform(memory.create(&descriptor, &work.other)) catch |err| { fail(work, err); return; };
                work.phase = .describe;
            }
        },
        .allocate => {
            var status: a.GfxNativeStatus = .{};
            d.platform(memory.nativeQuery(&work.request, &status)) catch |err| { fail(work, err); return; };
            if (status.phase != 2) return; // GfxNativeStatus: queued0, claimed1, terminal2.
            d.platform(status.result) catch |err| { fail(work, err); return; };
            d.platform(memory.nativeReceive(&work.request, &work.other)) catch |err| { fail(work, err); return; };
            work.request = .{}; work.phase = .describe;
        },
        .describe => {
            d.platform(memory.describe(&work.other.reference, &work.descriptor)) catch |err| { fail(work, err); return; };
            work.amd_image = resources.validateDescriptor(device,work.descriptor) catch |err| { fail(work,err); return; };
            work.image = resources.descriptorImage(work.descriptor) catch |err| { fail(work, err); return; };
            if (work.image.width != item.image.width or work.image.height != item.image.height or work.image.format != item.image.format or
                (work.restore and (work.descriptor.location != a.gfx_buffer_location_device_local or work.descriptor.adapter_id != work.binding.adapter_id or
                    work.descriptor.device_generation != work.memory_generation or work.descriptor.usage != 28)) or
                (!work.restore and work.descriptor.location != a.gfx_buffer_location_system)) { fail(work, error.Stale); return; }
            work.phase = .submit;
        },
        .submit => {
            device.ensureQueue() catch |err| { fail(work, err); return; };
            var receipt: a.GfxFenceStatus = .{};
            const request: a.GfxSubmission = .{ .operation = a.gfx_queue_operation_copy_rows, .source = item.backing.reference,
                .target = work.other.reference, .byte_length = @as(u64, item.image.width) * (resources.pixelBytes(item.image.format) catch unreachable),
                .row_count = item.image.height, .source_pitch = item.image.pitch, .target_pitch = work.image.pitch, .deadline_ns = work.deadline };
            const rc = queues.submit(&device.queue, &request, &receipt);
            if (rc == a.gfx_queue_error_busy) return;
            d.platform(rc) catch |err| { fail(work, err); return; };
            work.fence = receipt.fence; work.phase = .copy;
        },
        .copy => {
            if (work.cancelled) _ = queues.cancel(&work.fence);
            var receipt: a.GfxFenceStatus = .{};
            // Failed or lost receipts remain held. Without exact physical
            // retirement there is no permission to drop either backing.
            if (queues.query(&work.fence, &receipt) != a.gfx_queue_ok or !std.meta.eql(receipt.fence, work.fence)) return;
            if (receipt.phase != a.gfx_queue_phase_terminal or receipt.flags & (a.gfx_queue_flag_device_active | a.gfx_queue_flag_resources_held) != 0) return;
            work.commit = !work.cancelled and receipt.result == a.gfx_queue_result_complete;
            if (!work.commit) work.failure = error.Unavailable;
            work.phase = .retire;
        },
        .retire => {
            if (work.commit and work.restore) {
                // Recheck the provider before dropping the authoritative RAM
                // image. A reset may race the final successful copy receipt.
                device.selectBackend() catch { work.commit = false; work.failure = error.Stale; };
                if (!std.meta.eql(work.binding, device.selected.binding) or work.memory_generation != device.selected.memory_generation) {
                    work.commit = false; work.failure = error.Stale;
                }
            }
            if (work.fence.timeline != 0) {
                if (queues.release(&work.fence) != a.gfx_queue_ok) return;
                work.fence = .{};
            }
            if (work.request.id != 0) {
                if (memory.nativeClose(&work.request) != a.gfx_buffer_result_ok) return;
                work.request = .{};
            }
            if (work.commit) {
                if (memory.release(&item.backing.reference) != a.gfx_buffer_result_ok) return;
                if (!work.restore) item.native_bytes = item.descriptor.byte_length;
                item.backing = work.other; item.descriptor = work.descriptor;
                item.amd_image = work.amd_image; item.image = work.image;
                item.evicted = !work.restore;
                if (work.restore) device.residency_restores +|= 1 else device.residency_evictions +|= 1;
            } else {
                if (work.other.reference.id != 0 and memory.release(&work.other.reference) != a.gfx_buffer_result_ok) return;
                if (work.restore) item.resident_result = work.failure orelse error.Unavailable;
                device.residency_failures +|= 1;
            }
            item.residency_busy = false; item.job_refs -= 1;
            device.residency_work = null;
            _ = device.cleanResource(item);
        },
    }
}
