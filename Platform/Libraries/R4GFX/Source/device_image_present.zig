//! A complete composition image uses the same retained queue job as a draw.
//! The kernel display owner admits geometry; the driver owns private scanout.
const std = @import("std");
const a = @import("r4os").abi;
const d = @import("device.zig");
const c = d.c;

pub fn submit(device: *d.Device, input: *const c.R4GfxImagePresentRequest, output: *c.R4GfxJob) d.Error!i32 {
    return submitPath(device, input, output, false);
}
pub fn submitPath(device: *d.Device, input: *const c.R4GfxImagePresentRequest, output: *c.R4GfxJob, direct: bool) d.Error!i32 {
    return submitImpl(device, input, output, direct, null);
}
const Route = struct { target: a.GfxOutputTarget, queue: a.GfxQueueHandle };
pub fn submitOutput(device: *d.Device, input: *const c.R4GfxImagePresentRequest, output: *c.R4GfxJob,
    direct: bool, target: a.GfxOutputTarget, queue: a.GfxQueueHandle) d.Error!i32
{
    if (target.version != 1 or target.size != @sizeOf(a.GfxOutputTarget) or target.adapter_id == 0 or target.connector_id == 0 or
        target.device_generation == 0 or target.connection_generation == 0 or target.display_generation == 0 or target.reserved0 != 0 or
        target.head_id >= 8 or queue.timeline == 0) return error.Invalid;
    return submitImpl(device, input, output, direct, .{ .target = target, .queue = queue });
}
fn submitImpl(device: *d.Device, input: *const c.R4GfxImagePresentRequest, output: *c.R4GfxJob, direct: bool, route: ?Route) d.Error!i32 {
    _ = try d.pointer(c.R4GfxImagePresentRequest, @intFromPtr(input));
    try d.outputSafe(c.R4GfxJob, output, device);
    if (d.overlaps(@intFromPtr(input), @sizeOf(c.R4GfxImagePresentRequest), @intFromPtr(output), @sizeOf(c.R4GfxJob)) or
        d.overlaps(@intFromPtr(input), @sizeOf(c.R4GfxImagePresentRequest), @intFromPtr(device), @sizeOf(d.Device))) return error.Alias;
    const request = input.*;
    if (request.version != 1 or request.size != @sizeOf(c.R4GfxImagePresentRequest) or request.reserved != 0 or
        request.frame_key == 0 or request.deadline_ns == 0 or request.deadline_ns == std.math.maxInt(u64) or
        request.dependency_count > c.copy_max_dependencies or (request.dependency_count == 0 and request.dependencies != 0)) return error.Invalid;
    var dependencies: [c.copy_max_dependencies]a.GfxFence = undefined;
    if (request.dependency_count != 0) {
        _ = try d.pointer(c.R4GfxCopyFence, request.dependencies);
        const bytes = @as(u64, request.dependency_count) * @sizeOf(c.R4GfxCopyFence);
        _ = std.math.add(u64, request.dependencies, bytes) catch return error.Overflow;
        if (d.overlaps(request.dependencies, bytes, @intFromPtr(device), @sizeOf(d.Device)) or
            d.overlaps(request.dependencies, bytes, @intFromPtr(output), @sizeOf(c.R4GfxJob))) return error.Alias;
        const source: [*]const c.R4GfxCopyFence = @ptrFromInt(request.dependencies);
        for (source[0..request.dependency_count], 0..) |fence, i| dependencies[i] = @bitCast(fence);
    }
    try device.selectBackend();
    if (route == null and device.gpu_operations & c.device_gpu_present == 0) return error.Unsupported;
    if (direct and device.gpu_operations & c.device_gpu_direct == 0) return error.Unsupported;
    const source = try device.resource(request.source, true);
    if (source.invalidated) return error.Stale;
    if (source.kind != c.resource_image or source.backing.reference.id == 0 or
        (source.descriptor.format != a.gfx_buffer_format_xrgb8888 and source.descriptor.format != a.gfx_buffer_format_xrgb2101010) or
        (route == null and source.descriptor.location != a.gfx_buffer_location_device_local))
        return error.Unsupported;
    if (route) |selected| {
        if (source.descriptor.location == a.gfx_buffer_location_device_local) {
            if (source.descriptor.adapter_id != selected.target.adapter_id or device.gpu_operations & c.device_gpu_present == 0) return error.Unsupported;
        } else if (source.descriptor.location != a.gfx_buffer_location_system or source.descriptor.modifier != 0) return error.Unsupported;
    }
    if (direct and (source.descriptor.usage & a.gfx_buffer_usage_scanout == 0 or source.descriptor.modifier != 0 or
        source.descriptor.plane_count != 1 or source.descriptor.plane_offsets[0] != 0 or source.descriptor.plane_pitches[0] & 63 != 0)) return error.Unsupported;
    try @import("device_output_color.zig").validate(device, source, if (route) |selected| selected.target else null);
    const index = for (&device.jobs, 0..) |*item, i| { if (item.serial == 0) break i; } else return error.Busy;
    const serial = std.math.add(u64, device.job_serial, 1) catch return error.Limit;
    if (source.job_refs == std.math.maxInt(u32)) return error.Limit;
    if (!device.cleanResources()) return error.Busy;
    if (route == null) try device.ensureQueue();
    var submission: a.GfxSubmission = .{ .operation = if (direct) a.gfx_queue_operation_direct_present else a.gfx_queue_operation_present, .source = source.backing.reference,
        .byte_length = @as(u64, source.image.width) * 4, .row_count = source.image.height, .source_pitch = source.image.pitch,
        .frame_key = request.frame_key, .deadline_ns = request.deadline_ns, .dependency_count = request.dependency_count };
    @memcpy(submission.dependencies[0..request.dependency_count], dependencies[0..request.dependency_count]);
    const queues = device.queues();
    var accepted: a.GfxFenceStatus = .{};
    try d.queueAdmission(if (route) |selected| queues.submitOutput(&selected.queue, &submission, &selected.target, &accepted)
        else queues.submit(&device.queue, &submission, &accepted));
    source.job_refs += 1;
    device.jobs[index] = .{ .serial = serial, .source = request.source, .fence = accepted.fence,
        .backend = if (source.descriptor.location == a.gfx_buffer_location_device_local) device.backend() else c.render_backend_software,
        // Direct retains and flips the source image; final retirement does
        // not transfer its bytes. Composition presentation still counts its
        // complete copy after the exact successful completion receipt.
        .bytes = if (direct) 0 else submission.byte_length * source.image.height };
    device.job_serial = serial;
    output.* = .{ .slot = @intCast(index + 1), .reserved = 0, .generation = serial, .device_generation = device.generation, .device_address = device.self_address };
    return c.status_ok;
}
