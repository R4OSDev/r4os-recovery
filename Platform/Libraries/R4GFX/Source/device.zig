//! Caller-owned graphics state. No global app context or shared allocator.
//! Backend selection, immutable source retention and logical resource lifetime
//! live here; the common queue and R4D own physical execution and retirement.
const std = @import("std");
const r4os = @import("r4os");
const a = r4os.abi;
pub const c = @import("r4l_contract");
pub const swapchain = @import("device_swapchain.zig");
pub const color_api = @import("color_api.zig");
pub const color_resource = @import("color_resource.zig");
const providers = @import("providers.zig");
const caller = @import("library_caller");
const live_magic: u64 = 0x5234474658444556;
const closed_magic: u64 = 0x5234474658434c53;
pub const Error = error{ Invalid, Unsupported, Overflow, Limit, Alias, Busy, Stale, Unavailable, Occluded, Suboptimal, Lost };
const empty_image = std.mem.zeroes(c.R4GfxCpuImage);
const empty_resource = std.mem.zeroes(c.R4GfxResource);

pub fn code(err: Error) i32 {
    return switch (err) {
        error.Invalid => c.status_invalid, error.Unsupported => c.status_unsupported,
        error.Overflow => c.status_overflow, error.Limit => c.status_limit,
        error.Alias => c.status_alias, error.Busy => c.status_busy,
        error.Stale => c.status_stale, error.Unavailable => c.status_unavailable,
        error.Occluded => c.status_occluded, error.Suboptimal => c.status_suboptimal, error.Lost => c.status_lost,
    };
}
pub fn platform(rc: i32) Error!void {
    return switch (rc) {
        a.gfx_buffer_result_ok => {},
        a.gfx_buffer_error_busy => error.Busy,
        a.gfx_buffer_error_stale, a.gfx_buffer_error_closed, a.gfx_queue_error_device_lost => error.Stale,
        a.gfx_buffer_error_unsupported => error.Unsupported,
        a.gfx_buffer_error_overflow => error.Overflow,
        a.gfx_buffer_error_oom, a.gfx_buffer_error_capacity, a.gfx_buffer_error_budget => error.Limit,
        a.err_no_fn, a.err_no_group, a.gfx_buffer_error_unavailable => error.Unavailable,
        a.gfx_queue_error_wait_timeout, a.gfx_queue_error_wait_cancelled => error.Unavailable,
        else => error.Invalid,
    };
}
/// Completed or in-flight receipts can temporarily fill the common queue.
/// Only queue admission maps that condition to Busy; BO quotas/OOM retain
/// their Limit result, and the caller keeps every existing receipt alive.
pub fn queueAdmission(rc: i32) Error!void {
    if (rc == a.gfx_queue_error_capacity) return error.Busy;
    return platform(rc);
}
pub fn pointer(comptime T: type, address: u64) Error!*T {
    if (address == 0 or address % @alignOf(T) != 0 or address > std.math.maxInt(u64) - @sizeOf(T)) return error.Invalid;
    return @ptrFromInt(address);
}
pub fn overlaps(left: u64, bytes: u64, right: u64, count: u64) bool {
    const end = std.math.add(u64, left, bytes) catch return true;
    const other_end = std.math.add(u64, right, count) catch return true;
    return bytes != 0 and count != 0 and left < other_end and right < end;
}
pub fn outputSafe(comptime T: type, output: *T, device: *Device) Error!void {
    _ = try pointer(T, @intFromPtr(output));
    if (overlaps(@intFromPtr(output), @sizeOf(T), @intFromPtr(device), @sizeOf(Device))) return error.Alias;
}
fn separateInput(input: anytype, output: anytype) Error!void {
    if (overlaps(@intFromPtr(input), @sizeOf(@typeInfo(@TypeOf(input)).pointer.child),
        @intFromPtr(output), @sizeOf(@typeInfo(@TypeOf(output)).pointer.child))) return error.Alias;
}
pub const Resource = struct {
    allocation_request: a.GfxBufferHandle = .{},
    serial: u64 = 0,
    kind: u32 = 0,
    flags: u32 = 0,
    source_kind: u32 = 0,
    source_generation: u64 = 0,
    source_key: struct { id: u64 = 0, generation: u64 = 0 } = .{},
    public_refs: u32 = 0,
    job_refs: u32 = 0,
    invalidated: bool = false,
    evicted: bool = false,
    residency_busy: bool = false,
    native_layout: u32 = 0,
    amd_image: ?@import("amd_images.zig").Result = null,
    native_bytes: u64 = 0,
    priority: u32 = 128,
    last_use: u64 = 0,
    resident_deadline: u64 = 0,
    resident_order: u64 = 0,
    resident_result: ?Error = null,
    sampler: u32 = 0,
    operation: u32 = 0,
    image: c.R4GfxCpuImage = empty_image,
    color: ?c.R4GfxColorDescription = null,
    backing: a.GfxBufferReference = .{},
    descriptor: a.GfxBufferDescriptor = .{},
    map: a.GfxBufferMap = .{},
};
pub const Job = struct {
    serial: u64 = 0,
    source: c.R4GfxResource = empty_resource,
    target: c.R4GfxResource = empty_resource,
    fence: a.GfxFence = .{},
    backend: u32 = 0,
    bytes: u64 = 0,
    counted: bool = false,
    render: bool = false,
    chain_refs: u32 = 0,
    native_yuv_count: u8 = 0,
    native_yuv_indices: [4]u8 = @splat(0),
};
pub const Device = struct {
    // These two fields persist through close so reopening cannot revive handles.
    magic: u64 = 0,
    generation: u64 = 0,
    self_address: u64 = 0,
    caller: caller.Snapshot = undefined,
    closing: bool = false,
    preferred_adapter: u32 = 0,
    flags: u32 = 0,
    resource_serial: u64 = 0,
    job_serial: u64 = 0,
    chain_serial: u64 = 0,
    touch_serial: u64 = 0,
    residency_work: ?@import("device_residency.zig").Work = null,
    residency_evictions: u64 = 0,
    residency_restores: u64 = 0,
    residency_failures: u64 = 0,
    residency_order: u64 = 0,
    residency_pending: u32 = 0,
    selected: a.GfxBackendInfo = .{ .binding = .{ .device_generation = 1, .reset_generation = 1 } },
    selected_backend: u32 = c.render_backend_software,
    queue: a.GfxQueueHandle = .{},
    software_queue: a.GfxQueueHandle = .{},
    gpu_operations: u32 = 0,
    retired_queues: [c.device_job_capacity]a.GfxQueueHandle = @splat(.{}),
    counters: c.R4GfxDeviceInfo = std.mem.zeroes(c.R4GfxDeviceInfo),
    resources: [c.device_resource_capacity]Resource = @splat(.{}),
    jobs: [c.device_job_capacity]Job = @splat(.{}),
    native_yuv: @import("native_yuv_cache.zig").Owner = .{},
    chains: [c.swapchain_capacity]@import("device_swapchain.zig").Slot = @splat(.{}),
    amd_image_scratch: [65551]u8 = undefined,
    // Per-device scratch avoids large render arrays on an application stack.
    images: [c.render_max_images]c.R4GfxCpuImage = undefined,
    image_slots: [c.render_max_images]u32 = undefined,
    image_writes: [c.render_max_images]bool = undefined,
    commands: [c.render_max_commands]c.R4GfxCpuDraw = undefined,

    pub fn base(self: *Device) r4os.program.Context { return self.caller.base(); }
    pub fn buffers(self: *Device) r4os.gfx_buffers.Context { return .{ .base = self.base() }; }
    pub fn queues(self: *Device) r4os.gfx_queue.Context { return .{ .base = self.base() }; }
    pub fn backend(self: *const Device) u32 { return self.selected_backend; }
    pub fn resource(self: *Device, handle: c.R4GfxResource, public: bool) Error!*Resource {
        if (handle.device_address != self.self_address or handle.device_generation != self.generation or handle.slot == 0 or handle.slot > self.resources.len) return error.Stale;
        const item = &self.resources[handle.slot - 1];
        if (item.serial == 0 or item.serial != handle.generation or item.kind != handle.kind or (public and item.public_refs == 0)) return error.Stale;
        if (public and item.residency_busy) return error.Busy;
        if (public) { self.touch_serial +|= 1; item.last_use = self.touch_serial; }
        return item;
    }
    pub fn resourceHandle(self: *const Device, index: usize) c.R4GfxResource {
        const item = &self.resources[index];
        return .{ .slot = @intCast(index + 1), .kind = item.kind, .generation = item.serial, .device_generation = self.generation, .device_address = self.self_address };
    }
    pub fn job(self: *Device, handle: c.R4GfxJob) Error!*Job {
        if (handle.device_address != self.self_address or handle.device_generation != self.generation or handle.reserved != 0 or handle.slot == 0 or handle.slot > self.jobs.len) return error.Stale;
        const item = &self.jobs[handle.slot - 1];
        if (item.serial == 0 or item.serial != handle.generation) return error.Stale;
        return item;
    }
    pub fn cleanResource(self: *Device, item: *Resource) bool {
        const memory = self.buffers();
        if (item.map.lease.id != 0) {
            if (memory.unmap(&item.map.lease) != a.gfx_buffer_result_ok) return false;
            item.map = .{};
        }
        if (item.public_refs != 0 or item.job_refs != 0) return true;
        if (item.allocation_request.id != 0) {
            if (memory.nativeClose(&item.allocation_request) != a.gfx_buffer_result_ok) return false;
            item.allocation_request = .{};
        }
        if (item.backing.reference.id != 0 and memory.release(&item.backing.reference) != a.gfx_buffer_result_ok) return false;
        if (item.resident_deadline != 0) self.residency_pending -= 1;
        item.* = .{};
        return true;
    }
    pub fn cleanResources(self: *Device) bool {
        var okay = true;
        for (&self.resources) |*item| if (!self.cleanResource(item)) { okay = false; };
        return okay;
    }
    fn closeQueue(self: *Device) Error!void {
        return self.retireQueue(&self.queue);
    }
    fn retireQueue(self: *Device, queue: *a.GfxQueueHandle) Error!void {
        if (queue.timeline == 0) return;
        var held = @import("device_residency.zig").holdsQueue(self, queue.timeline);
        for (&self.jobs) |*item| if (item.serial != 0 and item.fence.timeline == queue.timeline) { held = true; };
        if (held) {
            // Common close drops client fence references. Keep this queue open
            // until all exact job receipts have been observed and released.
            for (&self.retired_queues) |*retired| if (retired.timeline == 0) {
                retired.* = queue.*;
                queue.* = .{};
                return;
            };
            return error.Limit;
        }
        const queue_api = self.queues();
        const rc = queue_api.close(queue);
        if (rc != a.gfx_queue_error_stale) try platform(rc);
        queue.* = .{};
    }
    pub fn drainQueues(self: *Device) bool {
        const queue_api = self.queues();
        var okay = true;
        next: for (&self.retired_queues) |*retired| {
            if (retired.timeline == 0) continue;
            if (@import("device_residency.zig").holdsQueue(self, retired.timeline)) { okay = false; continue; }
            for (&self.jobs) |*item| if (item.serial != 0 and item.fence.timeline == retired.timeline) {
                okay = false;
                continue :next;
            };
            const rc = queue_api.close(retired);
            if (rc == a.gfx_queue_ok or rc == a.gfx_queue_error_stale) retired.* = .{} else { okay = false; }
        }
        return okay;
    }
    pub fn ensureQueue(self: *Device) Error!void {
        if (self.queue.timeline != 0) return;
        const value = self.selected.binding;
        const queue_api = self.queues();
        try platform(queue_api.open(&.{ .adapter_id = value.adapter_id, .device_generation = value.device_generation,
            .reset_generation = value.reset_generation, .milestone = value.milestone, .capacity = c.device_job_capacity }, &self.queue));
    }
    pub fn softwareQueue(self: *Device) Error!*const a.GfxQueueHandle {
        if (self.software_queue.timeline == 0) {
            const queue_api = self.queues();
            try platform(queue_api.open(&.{ .capacity = c.device_job_capacity }, &self.software_queue));
        }
        return &self.software_queue;
    }
    pub fn selectBackend(self: *Device) Error!void {
        var candidate: a.GfxBackendInfo = .{ .binding = .{ .device_generation = 1, .reset_generation = 1 } };
        var gpu_operations: u32 = 0;
        var candidate_backend: u32 = c.render_backend_software;
        const registry = providers.Registry.initCaller(&self.caller, self.flags & c.device_software_only != 0);
        if (registry.available()) {
            const queue_api = self.queues();
            var primary: a.DisplayPresentationInfo = .{};
            const base_context = self.base();
            const boot_adapter = if (base_context.displayPresentationInfo(0, &primary) == a.gfx_output_ok and
                primary.version == 1 and primary.size >= @sizeOf(a.DisplayPresentationInfo) and
                primary.flags & a.display_presentation_info_active != 0) primary.backend.adapter_id else 0;
            for (1..a.gfx_queue_backend_capacity) |index| {
                var snapshot: a.GfxBackendInfo = .{};
                if (queue_api.backendInfo(@intCast(index), &snapshot) != a.gfx_queue_ok) continue;
                const binding = snapshot.binding;
                if (snapshot.version != 1 or snapshot.size < @sizeOf(a.GfxBackendInfo) or binding.version != 1 or binding.size < @sizeOf(a.GfxBackendBinding) or
                    binding.adapter_id == 0 or binding.device_generation == 0 or binding.reset_generation == 0 or binding.milestone != a.gfx_queue_milestone_device_execution or
                    (self.preferred_adapter != 0 and binding.adapter_id != self.preferred_adapter)) continue;
                const negotiated = registry.negotiate(snapshot) orelse continue;
                if (snapshot.memory_generation == 0) continue;
                if (!preferBackend(snapshot, candidate, boot_adapter, negotiated.operations, gpu_operations)) continue;
                candidate = snapshot;
                candidate_backend = negotiated.backend;
                gpu_operations = negotiated.operations;
            }
        }
        const same_provider = self.selected_backend == candidate_backend and std.meta.eql(self.selected.profile, candidate.profile);
        if (std.meta.eql(self.selected, candidate) and same_provider) {
            self.gpu_operations = gpu_operations;
            return;
        }
        if (same_provider and std.meta.eql(self.selected.binding, candidate.binding) and self.selected.memory_generation == candidate.memory_generation) {
            // Capability changes alone preserve existing queues and resources.
            self.selected = candidate;
            self.gpu_operations = gpu_operations;
            return;
        }
        const previous = self.selected.binding;
        _ = self.drainQueues();
        try self.closeQueue();
        self.selected = candidate;
        self.selected_backend = candidate_backend;
        self.gpu_operations = gpu_operations;
        // The exact returned generation must still be openable. A raced reset
        // gives software fallback; no cached profile alone authorizes work.
        if (candidate.binding.adapter_id != 0) self.ensureQueue() catch {
            self.selected = .{ .binding = .{ .device_generation = 1, .reset_generation = 1 } };
            self.gpu_operations = 0;
            self.selected_backend = c.render_backend_software;
        };
        const current = self.selected.binding;
        for (&self.resources) |*item| if (item.serial != 0 and item.descriptor.location == a.gfx_buffer_location_device_local) {
            if (!same_provider or item.descriptor.adapter_id != current.adapter_id or item.descriptor.device_generation != self.selected.memory_generation or
                (item.descriptor.adapter_id == previous.adapter_id and previous.reset_generation != current.reset_generation)) item.invalidated = true;
        };
        self.counters.backend_changes +|= 1;
    }
    pub fn info(self: *Device) c.R4GfxDeviceInfo {
        var value = self.counters;
        value.version = 1; value.size = @sizeOf(c.R4GfxDeviceInfo); value.generation = self.generation;
        value.adapter_id = self.selected.binding.adapter_id; value.backend = self.backend();
        value.device_generation = self.selected.binding.device_generation; value.reset_generation = self.selected.binding.reset_generation;
        value.formats = c.render_format_xrgb8888 | c.render_format_argb8888 | c.render_format_r8;
        value.operations = c.render_operation_fill | c.render_operation_blit | c.render_operation_over; value.samplers = 3;
        value.gpu_operations = self.gpu_operations;
        value.resource_capacity = self.resources.len; value.job_capacity = self.jobs.len;
        return value;
    }
};

// Prefer a working render engine, then avoid interadapter presentation when
// capabilities are equal. PCI adapter identity breaks ties independently of
// driver registration order. No unmeasured performance score is invented.
fn preferBackend(next: a.GfxBackendInfo, current: a.GfxBackendInfo, boot_adapter: u32, next_operations: u32, current_operations: u32) bool {
    if (current.binding.adapter_id == 0) return true;
    const next_render = next_operations & c.device_gpu_render != 0;
    const current_render = current_operations & c.device_gpu_render != 0;
    if (next_render != current_render) return next_render;
    const next_boot = next.binding.adapter_id == boot_adapter;
    const current_boot = current.binding.adapter_id == boot_adapter;
    if (next_boot != current_boot) return next_boot;
    return next.binding.adapter_id < current.binding.adapter_id;
}
pub fn get(handle: *const c.R4GfxDevice, closing: bool) Error!*Device {
    _ = try pointer(c.R4GfxDevice, @intFromPtr(handle));
    const device = try pointer(Device, handle.address);
    if (device.magic != live_magic or device.self_address != handle.address or device.generation != handle.generation) return error.Stale;
    if (!closing and device.closing) return error.Busy;
    @import("device_residency.zig").step(device);
    device.native_yuv.step(device);
    return device;
}
pub fn storageSize() callconv(.c) u64 { return @sizeOf(Device); }
comptime { std.debug.assert(@alignOf(Device) <= c.device_storage_alignment); }
pub fn open(config: *const c.R4GfxDeviceConfig, output: *c.R4GfxDevice) callconv(.c) i32 {
    openDevice(config, output) catch |err| return code(err);
    return c.status_ok;
}
fn openDevice(config: *const c.R4GfxDeviceConfig, output: *c.R4GfxDevice) Error!void {
    _ = try pointer(c.R4GfxDeviceConfig, @intFromPtr(config));
    if (config.version != 1 or config.size != @sizeOf(c.R4GfxDeviceConfig) or config.storage_bytes < @sizeOf(Device) or config.flags & ~c.device_software_only != 0) return error.Invalid;
    const device = try pointer(Device, config.storage_address);
    const input = try caller.Input.init(config.start_context);
    try outputSafe(c.R4GfxDevice, output, device);
    if (overlaps(@intFromPtr(config), @sizeOf(c.R4GfxDeviceConfig), @intFromPtr(device), @sizeOf(Device)) or
        overlaps(input.address(), input.bytes(), @intFromPtr(device), @sizeOf(Device)) or
        overlaps(@intFromPtr(config), @sizeOf(c.R4GfxDeviceConfig), @intFromPtr(output), @sizeOf(c.R4GfxDevice))) return error.Alias;
    if (device.magic != 0 and device.magic != closed_magic) return error.Busy;
    if (device.magic == 0 and device.generation != 0) return error.Invalid;
    const generation = std.math.add(u64, device.generation, 1) catch return error.Limit;
    device.* = .{ .magic = live_magic, .generation = generation, .self_address = @intFromPtr(device),
        .preferred_adapter = config.preferred_adapter, .flags = config.flags };
    device.caller.init(input);
    // Initial selection has no old queue and cannot require a retained close.
    device.selectBackend() catch unreachable;
    output.* = .{ .address = @intFromPtr(device), .generation = generation };
}
pub fn info(handle: *const c.R4GfxDevice, output: *c.R4GfxDeviceInfo) callconv(.c) i32 {
    const device = get(handle, true) catch |err| return code(err);
    separateInput(handle, output) catch |err| return code(err);
    outputSafe(c.R4GfxDeviceInfo, output, device) catch |err| return code(err);
    output.* = device.info();
    return c.status_ok;
}
pub fn refresh(handle: *const c.R4GfxDevice, output: *c.R4GfxDeviceInfo) callconv(.c) i32 {
    const device = get(handle, false) catch |err| return code(err);
    separateInput(handle, output) catch |err| return code(err);
    outputSafe(c.R4GfxDeviceInfo, output, device) catch |err| return code(err);
    device.selectBackend() catch |err| return code(err);
    output.* = device.info();
    return c.status_ok;
}

pub fn createResource(handle: *const c.R4GfxDevice, descriptor: *const c.R4GfxResourceDesc, output: *c.R4GfxResource) callconv(.c) i32 {
    const device = get(handle, false) catch |err| return code(err);
    separateInput(handle, output) catch |err| return code(err);
    return @import("device_resources.zig").create(device, descriptor, output) catch |err| code(err);
}
pub fn memoryInfo(handle: *const c.R4GfxDevice, output: *c.R4GfxMemoryInfo) callconv(.c) i32 {
    const device = get(handle, true) catch |err| return code(err);
    separateInput(handle, output) catch |err| return code(err);
    outputSafe(c.R4GfxMemoryInfo, output, device) catch |err| return code(err);
    const value = @import("device_residency.zig").snapshot(device);
    output.* = .{ .version = 1, .size = @sizeOf(c.R4GfxMemoryInfo), .phase = @intFromEnum(value.phase),
        .flags = if (device.residency_work) |work| (if (work.restore) c.memory_flag_restoring else 0) else 0,
        .adapter_id = device.selected.binding.adapter_id, .memory_generation = device.selected.memory_generation,
        .resource_slot = if (device.residency_work) |work| @intCast(work.index + 1) else 0,
        .resident_bytes = value.resident_bytes, .evicted_bytes = value.evicted_bytes, .system_bytes = value.system_bytes,
        .pinned_bytes = value.pinned_bytes, .pending_bytes = value.pending_bytes, .reclaimable_bytes = value.reclaimable_bytes,
        .evictions = device.residency_evictions, .restores = device.residency_restores, .failures = device.residency_failures };
    return c.status_ok;
}
pub fn memoryTrim(handle: *const c.R4GfxDevice, deadline: u64) callconv(.c) i32 {
    const device = get(handle, false) catch |err| return code(err);
    device.selectBackend() catch |err| return code(err);
    device.native_yuv.trim(device) catch |err| return code(err);
    @import("device_residency.zig").trim(device, deadline) catch |err| return code(err);
    return c.status_ok;
}
pub fn resourceResident(handle: *const c.R4GfxDevice, resource: *const c.R4GfxResource, deadline: u64) callconv(.c) i32 {
    const device = get(handle, false) catch |err| return code(err);
    _ = pointer(c.R4GfxResource, @intFromPtr(resource)) catch |err| return code(err);
    device.selectBackend() catch |err| return code(err);
    const item = device.resource(resource.*, true) catch |err| return code(err);
    if (item.kind != c.resource_image or item.source_kind != c.source_create_native) return c.status_unsupported;
    @import("device_residency.zig").ensure(device, item, deadline) catch |err| return code(err);
    return c.status_ok;
}
pub fn resourcePriority(handle: *const c.R4GfxDevice, resource: *const c.R4GfxResource, priority: u32) callconv(.c) i32 {
    const device = get(handle, false) catch |err| return code(err);
    _ = pointer(c.R4GfxResource, @intFromPtr(resource)) catch |err| return code(err);
    const item = device.resource(resource.*, true) catch |err| return code(err);
    if (item.kind != c.resource_image or item.source_kind != c.source_create_native) return c.status_unsupported;
    item.priority = priority;
    return c.status_ok;
}
pub fn retainResource(handle: *const c.R4GfxDevice, resource: *const c.R4GfxResource) callconv(.c) i32 {
    const device = get(handle, false) catch |err| return code(err);
    _ = pointer(c.R4GfxResource, @intFromPtr(resource)) catch |err| return code(err);
    const item = device.resource(resource.*, true) catch |err| return code(err);
    item.public_refs = std.math.add(u32, item.public_refs, 1) catch return c.status_limit;
    return c.status_ok;
}
pub fn releaseResource(handle: *const c.R4GfxDevice, resource: *const c.R4GfxResource) callconv(.c) i32 {
    const device = get(handle, true) catch |err| return code(err);
    _ = pointer(c.R4GfxResource, @intFromPtr(resource)) catch |err| return code(err);
    const item = device.resource(resource.*, false) catch |err| return code(err);
    if (item.public_refs == 0) return c.status_stale;
    item.public_refs -= 1;
    _ = device.cleanResource(item); // Logical release is committed; retained maps remain tracked.
    return c.status_ok;
}
pub fn resourceInfo(handle: *const c.R4GfxDevice, resource: *const c.R4GfxResource, output: *c.R4GfxResourceInfo) callconv(.c) i32 {
    const device = get(handle, true) catch |err| return code(err);
    separateInput(handle, output) catch |err| return code(err);
    separateInput(resource, output) catch |err| return code(err);
    _ = pointer(c.R4GfxResource, @intFromPtr(resource)) catch |err| return code(err);
    outputSafe(c.R4GfxResourceInfo, output, device) catch |err| return code(err);
    const item = device.resource(resource.*, true) catch |err| return code(err);
    output.* = .{ .version = 1, .size = @sizeOf(c.R4GfxResourceInfo), .resource = resource.*, .source_kind = item.source_kind,
        .flags = item.flags | @as(u32, if (item.invalidated) c.resource_invalidated else 0), .source_generation = item.source_generation, .buffer_id = item.backing.buffer.id,
        .references = item.public_refs, .buffer_generation = item.backing.buffer.generation, .image = item.image };
    return c.status_ok;
}
pub fn render(handle: *const c.R4GfxDevice, batch: *const c.R4GfxRenderBatch, output: *c.R4GfxRenderStats) callconv(.c) i32 {
    const device = get(handle, false) catch |err| return code(err);
    separateInput(handle, output) catch |err| return code(err);
    return @import("device_render.zig").execute(device, batch, output) catch |err| code(err);
}
pub fn submitRender(handle: *const c.R4GfxDevice, request: *const c.R4GfxRenderRequest, output: *c.R4GfxJob) callconv(.c) i32 {
    const device = get(handle, false) catch |err| return code(err);
    separateInput(handle, output) catch |err| return code(err);
    return @import("device_native_render.zig").submit(device, request, output) catch |err| code(err);
}
pub fn submitRenderGridList(handle: *const c.R4GfxDevice, request: *const c.R4GfxRenderGridListRequest, output: *c.R4GfxJob) callconv(.c) i32 {
    const device = get(handle, false) catch |err| return code(err);
    separateInput(handle, output) catch |err| return code(err);
    return @import("device_native_render.zig").submitGridList(device, request, output) catch |err| code(err);
}
pub fn submitRenderList(handle: *const c.R4GfxDevice, request: *const c.R4GfxRenderListRequest, output: *c.R4GfxJob) callconv(.c) i32 {
    const device = get(handle, false) catch |err| return code(err);
    separateInput(handle, output) catch |err| return code(err);
    return @import("device_native_render.zig").submitList(device, request, output) catch |err| code(err);
}
pub fn submitColorRender(handle: *const c.R4GfxDevice, request: *const c.R4GfxRenderListRequest, flags: u32, output: *c.R4GfxJob) callconv(.c) i32 {
    const device = get(handle, false) catch |err| return code(err);
    separateInput(handle, output) catch |err| return code(err);
    return @import("device_native_render.zig").submitColorList(device, request, flags, output) catch |err| code(err);
}
pub fn submitColorGridRender(handle: *const c.R4GfxDevice, request: *const c.R4GfxRenderGridListRequest, flags: u32, output: *c.R4GfxJob) callconv(.c) i32 {
    const device = get(handle, false) catch |err| return code(err);
    separateInput(handle, output) catch |err| return code(err);
    return @import("device_native_render.zig").submitColorGridList(device, request, flags, output) catch |err| code(err);
}
pub fn prepareImage(handle: *const c.R4GfxDevice, request: *const c.R4GfxImagePrepareRequest, output: *c.R4GfxPreparedImage) callconv(.c) i32 {
    const device = get(handle, false) catch |err| return code(err);
    separateInput(handle, output) catch |err| return code(err);
    return @import("device_image_prepare.zig").prepare(device,handle,request,output) catch |err| code(err);
}
pub fn presentImage(handle: *const c.R4GfxDevice, request: *const c.R4GfxImagePresentRequest, output: *c.R4GfxJob) callconv(.c) i32 {
    const device = get(handle, false) catch |err| return code(err);
    separateInput(handle, output) catch |err| return code(err);
    return @import("device_image_present.zig").submit(device, request, output) catch |err| code(err);
}
pub fn submitCopy(handle: *const c.R4GfxDevice, request: *const c.R4GfxCopyRequest, output: *c.R4GfxJob) callconv(.c) i32 {
    const device = get(handle, false) catch |err| return code(err);
    separateInput(handle, output) catch |err| return code(err);
    return @import("device_jobs.zig").submit(device, request, output) catch |err| code(err);
}
pub fn submitCopyEx(handle: *const c.R4GfxDevice, request: *const c.R4GfxCopyRequestEx, output: *c.R4GfxJob) callconv(.c) i32 {
    const device = get(handle, false) catch |err| return code(err);
    separateInput(handle, output) catch |err| return code(err);
    return @import("device_jobs.zig").submitEx(device, request, output) catch |err| code(err);
}
pub fn jobFence(handle: *const c.R4GfxDevice, job: *const c.R4GfxJob, output: *c.R4GfxCopyFence) callconv(.c) i32 {
    const device = get(handle, true) catch |err| return code(err);
    separateInput(handle, output) catch |err| return code(err);
    separateInput(job, output) catch |err| return code(err);
    _ = pointer(c.R4GfxJob, @intFromPtr(job)) catch |err| return code(err);
    outputSafe(c.R4GfxCopyFence, output, device) catch |err| return code(err);
    const item = device.job(job.*) catch |err| return code(err);
    output.* = @bitCast(item.fence);
    return c.status_ok;
}
pub fn jobInfo(handle: *const c.R4GfxDevice, job: *const c.R4GfxJob, output: *c.R4GfxJobInfo) callconv(.c) i32 {
    const device = get(handle, true) catch |err| return code(err);
    separateInput(handle, output) catch |err| return code(err);
    return @import("device_jobs.zig").info(device, job, output) catch |err| code(err);
}
pub fn cancelJob(handle: *const c.R4GfxDevice, job: *const c.R4GfxJob) callconv(.c) i32 {
    const device = get(handle, true) catch |err| return code(err);
    return @import("device_jobs.zig").cancel(device, job) catch |err| code(err);
}
pub fn releaseJob(handle: *const c.R4GfxDevice, job: *const c.R4GfxJob) callconv(.c) i32 {
    const device = get(handle, true) catch |err| return code(err);
    return @import("device_jobs.zig").release(device, job) catch |err| code(err);
}
pub fn close(handle: *const c.R4GfxDevice) callconv(.c) i32 {
    const device = get(handle, true) catch |err| return code(err);
    device.closing = true;
    _ = @import("device_swapchain.zig").closeAll(device);
    device.closeQueue() catch |err| return code(err);
    device.retireQueue(&device.software_queue) catch |err| return code(err);
    var busy = false;
    @import("device_residency.zig").step(device);
    if (device.residency_work != null) busy = true;
    for (&device.jobs, 0..) |*item, index| if (item.serial != 0) {
        const job: c.R4GfxJob = .{ .slot = @intCast(index + 1), .reserved = 0, .generation = item.serial, .device_generation = device.generation, .device_address = device.self_address };
        _ = @import("device_jobs.zig").cancel(device, &job) catch c.status_busy;
        _ = @import("device_jobs.zig").release(device, &job) catch { busy = true; continue; };
    };
    if (!@import("device_swapchain.zig").closeAll(device)) return c.status_busy;
    for (&device.resources) |*item| item.public_refs = 0;
    if (!device.cleanResources()) busy = true;
    if (!device.drainQueues()) busy = true;
    device.native_yuv.step(device);
    if (device.native_yuv.profile != null) busy = true;
    if (busy) return c.status_busy;
    device.magic = closed_magic;
    return c.status_ok;
}
