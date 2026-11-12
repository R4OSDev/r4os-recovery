//! Canonical queue receipts remain referenced until physical retirement.
//! Closing an old queue early would discard those receipts, so the device
//! keeps obsolete queues until their last job has actually been released.
const std = @import("std");
const a = @import("r4os").abi;
const d = @import("device.zig");
const c = d.c;

pub fn submit(device: *d.Device, request: *const c.R4GfxCopyRequest, output: *c.R4GfxJob) d.Error!i32 {
    _ = try d.pointer(c.R4GfxCopyRequest, @intFromPtr(request));
    try d.outputSafe(c.R4GfxJob, output, device);
    if (d.overlaps(@intFromPtr(request), @sizeOf(c.R4GfxCopyRequest), @intFromPtr(output), @sizeOf(c.R4GfxJob))) return error.Alias;
    return submitRequest(device, request.*, 0, 0, 0, &.{}, output);
}
pub fn submitEx(device: *d.Device, request: *const c.R4GfxCopyRequestEx, output: *c.R4GfxJob) d.Error!i32 {
    _ = try d.pointer(c.R4GfxCopyRequestEx, @intFromPtr(request));
    try d.outputSafe(c.R4GfxJob, output, device);
    if (d.overlaps(@intFromPtr(request), @sizeOf(c.R4GfxCopyRequestEx), @intFromPtr(output), @sizeOf(c.R4GfxJob))) return error.Alias;
    const input = request.*;
    if (input.version != 1 or input.size != @sizeOf(c.R4GfxCopyRequestEx) or input.dependency_count > c.copy_max_dependencies or
        (input.dependency_count == 0 and input.dependencies != 0)) return error.Invalid;
    var dependencies: [c.copy_max_dependencies]a.GfxFence = undefined;
    if (input.dependency_count != 0) {
        _ = try d.pointer(c.R4GfxCopyFence, input.dependencies);
        const bytes = @as(u64, input.dependency_count) * @sizeOf(c.R4GfxCopyFence);
        _ = std.math.add(u64, input.dependencies, bytes) catch return error.Overflow;
        if (d.overlaps(input.dependencies, bytes, @intFromPtr(output), @sizeOf(c.R4GfxJob))) return error.Alias;
        const source: [*]const c.R4GfxCopyFence = @ptrFromInt(input.dependencies);
        for (source[0..input.dependency_count], 0..) |fence, i| dependencies[i] = @bitCast(fence);
    }
    return submitRequest(device, input.copy, input.row_count, input.source_pitch, input.target_pitch, dependencies[0..input.dependency_count], output);
}
fn span(bytes: u64, rows: u32, pitch: u64) d.Error!u64 {
    if (rows == 0) {
        if (pitch != 0) return error.Invalid;
        return bytes;
    }
    if (pitch < bytes) return error.Invalid;
    return std.math.add(u64, std.math.mul(u64, rows - 1, pitch) catch return error.Overflow, bytes) catch error.Overflow;
}
fn submitRequest(device: *d.Device, request: c.R4GfxCopyRequest, rows: u32, source_pitch: u64, target_pitch: u64, dependencies: []const a.GfxFence, output: *c.R4GfxJob) d.Error!i32 {
    try device.selectBackend();
    const source = try device.resource(request.source, true);
    const target = try device.resource(request.target, true);
    if (source.invalidated or target.invalidated) return error.Stale;
    if (source.kind != c.resource_image or target.kind != c.resource_image or target.flags & c.image_target == 0 or
        source.backing.reference.id == 0 or target.backing.reference.id == 0 or std.meta.eql(source.backing.buffer, target.backing.buffer)) return error.Unsupported;
    const source_bytes = try span(request.byte_length, rows, source_pitch);
    const target_bytes = try span(request.byte_length, rows, target_pitch);
    const bytes = std.math.mul(u64, request.byte_length, if (rows == 0) 1 else rows) catch return error.Overflow;
    if (request.byte_length == 0 or request.source_offset > source.image.byte_length or request.target_offset > target.image.byte_length or
        source_bytes > source.image.byte_length - request.source_offset or target_bytes > target.image.byte_length - request.target_offset) return error.Invalid;
    const tiled = source.descriptor.modifier != 0 or target.descriptor.modifier != 0;
    if (tiled and (rows == 0 or device.gpu_operations & c.device_gpu_copy_layout == 0)) return error.Unsupported;
    const index = for (&device.jobs, 0..) |*item, i| { if (item.serial == 0) break i; } else return error.Busy;
    const serial = std.math.add(u64, device.job_serial, 1) catch return error.Limit;
    if (source.job_refs == std.math.maxInt(u32) or target.job_refs == std.math.maxInt(u32)) return error.Limit;
    if (!device.cleanResources()) return error.Busy;
    try device.ensureQueue();
    const queues = device.queues();
    const software = @import("providers.zig").hardware(device.backend()) and rows != 0 and device.gpu_operations & c.device_gpu_copy_rows == 0;
    if (software and (source.descriptor.location != a.gfx_buffer_location_system or target.descriptor.location != a.gfx_buffer_location_system)) return error.Unsupported;
    const queue = if (software) try device.softwareQueue() else &device.queue;
    var status: a.GfxFenceStatus = .{};
    var submission: a.GfxSubmission = .{ .operation = if (rows == 0) a.gfx_queue_operation_copy else a.gfx_queue_operation_copy_rows,
        .source = source.backing.reference, .target = target.backing.reference,
        .source_offset = request.source_offset, .target_offset = request.target_offset, .byte_length = request.byte_length, .deadline_ns = request.deadline_ns,
        .row_count = rows, .source_pitch = source_pitch, .target_pitch = target_pitch, .dependency_count = @intCast(dependencies.len) };
    @memcpy(submission.dependencies[0..dependencies.len], dependencies);
    try d.queueAdmission(queues.submit(queue, &submission, &status));
    source.job_refs += 1; target.job_refs += 1;
    device.jobs[index] = .{ .serial = serial, .source = request.source, .target = request.target,
        .fence = status.fence, .backend = if (software) c.render_backend_software else device.backend(), .bytes = bytes };
    device.job_serial = serial;
    output.* = .{ .slot = @intCast(index + 1), .reserved = 0, .generation = serial, .device_generation = device.generation, .device_address = device.self_address };
    return c.status_ok;
}
fn query(device: *d.Device, item: *d.Job) d.Error!a.GfxFenceStatus {
    const queues = device.queues();
    var status: a.GfxFenceStatus = .{};
    try d.platform(queues.query(&item.fence, &status));
    if (!std.meta.eql(item.fence, status.fence)) return error.Stale;
    if (!item.counted and status.phase == a.gfx_queue_phase_terminal and status.result == a.gfx_queue_result_complete and status.flags & a.gfx_queue_flag_device_active == 0) {
        if (item.render) {
            // A draw is neither a copy nor CPU traffic. Future render counters
            // must derive from its completed render receipt, not byte_length.
        } else if (@import("providers.zig").hardware(item.backend)) device.counters.gpu_copy_bytes +|= item.bytes else {
            device.counters.cpu_read_bytes +|= item.bytes;
            device.counters.cpu_write_bytes +|= item.bytes;
        }
        item.counted = true;
    }
    return status;
}
pub fn info(device: *d.Device, handle: *const c.R4GfxJob, output: *c.R4GfxJobInfo) d.Error!i32 {
    _ = try d.pointer(c.R4GfxJob, @intFromPtr(handle));
    try d.outputSafe(c.R4GfxJobInfo, output, device);
    if (d.overlaps(@intFromPtr(handle), @sizeOf(c.R4GfxJob), @intFromPtr(output), @sizeOf(c.R4GfxJobInfo))) return error.Alias;
    const item = try device.job(handle.*);
    const value = try query(device, item);
    output.* = .{ .version = 1, .size = @sizeOf(c.R4GfxJobInfo), .phase = value.phase, .result = value.result, .flags = value.flags,
        .backend = item.backend, .timeline = value.fence.timeline, .point = value.fence.point,
        .device_generation = value.fence.device_generation, .reset_generation = value.fence.reset_generation };
    return c.status_ok;
}
pub fn cancel(device: *d.Device, handle: *const c.R4GfxJob) d.Error!i32 {
    _ = try d.pointer(c.R4GfxJob, @intFromPtr(handle));
    const item = try device.job(handle.*);
    const queues = device.queues();
    const rc = queues.cancel(&item.fence);
    if (rc != a.gfx_queue_error_already_completed) try d.platform(rc);
    return c.status_ok;
}
pub fn release(device: *d.Device, handle: *const c.R4GfxJob) d.Error!i32 {
    _ = try d.pointer(c.R4GfxJob, @intFromPtr(handle));
    const item = try device.job(handle.*);
    if (item.chain_refs != 0) return error.Busy;
    const value = try query(device, item);
    if (value.phase != a.gfx_queue_phase_terminal or value.flags & (a.gfx_queue_flag_device_active | a.gfx_queue_flag_resources_held) != 0) return error.Busy;
    const queues = device.queues();
    try d.platform(queues.release(&item.fence));
    if (item.native_yuv_count != 0) device.native_yuv.release(item.native_yuv_indices[0..item.native_yuv_count]);
    for ([_]c.R4GfxResource{item.source, item.target}) |resource| {
        if (resource.slot == 0) continue;
        const held = try device.resource(resource, false);
        std.debug.assert(held.job_refs != 0);
        held.job_refs -= 1;
        _ = device.cleanResource(held);
    }
    item.* = .{};
    _ = device.drainQueues();
    return c.status_ok;
}
