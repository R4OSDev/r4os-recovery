//! Explicit preparation outside frame submission. Suitable images retain one
//! reference; changed layouts allocate once and use the existing async copy
//! path. The renderer never maps/scales pixels to prepare a GPU texture.
const std = @import("std");
const a = @import("r4os").abi;
const nv = @import("r4nv_binding");
const d = @import("device.zig");
const c = d.c;
const resources = @import("device_resources.zig");
const jobs = @import("device_jobs.zig");
const Plan = struct {
    software: bool,
    reuse: bool,
    bytes: u64,
    native: ?nv.R4NvImagePlan = null,
};
fn negotiation(device: *d.Device, source: *d.Resource, request: c.R4GfxImagePrepareRequest) d.Error!Plan {
    const scanout = request.uses&c.prepare_use_scanout != 0;
    const target = request.uses&c.prepare_use_render_target != 0;
    if (scanout and target) return error.Unsupported;
    const force = request.flags&c.prepare_force_copy != 0 or (target and source.flags&c.image_target == 0);
    const native_render = device.selected.binding.adapter_id != 0 and (scanout or device.gpu_operations&c.device_gpu_render != 0);
    if (!native_render) {
        if (scanout or source.descriptor.modifier != 0 or source.descriptor.location != a.gfx_buffer_location_system or
            request.preference == c.prepare_layout_blocklinear) return error.Unsupported;
        const allocation_bytes = (std.math.add(u64,source.image.byte_length,4095) catch return error.Overflow)&~@as(u64,4095);
        if (force and source.backing.reference.id == 0) return error.Unsupported;
        return .{ .software = true, .reuse = !force, .bytes = allocation_bytes };
    }
    if (source.backing.reference.id == 0) return error.Unsupported;
    const descriptor = source.descriptor;
    if (device.backend() != c.render_backend_nvidia) return error.Unsupported;
    const client = device.caller.client(nv.BackendV1Client) catch return error.Unsupported;
    const profile = std.mem.bytesToValue(nv.R4NvDriverProfile,device.selected.profile.data[0..@sizeOf(nv.R4NvDriverProfile)]);
    var input: nv.R4NvImageRequest = .{ .view = .{ .version = 1, .size = @sizeOf(nv.R4NvImageView),
        .width = descriptor.width, .height = descriptor.height, .format = descriptor.format, .location = descriptor.location,
        .modifier = descriptor.modifier, .byte_length = descriptor.byte_length, .pitch = descriptor.plane_pitches[0],
        .alignment = descriptor.alignment, .usage = descriptor.usage, .reserved = 0 },
        .uses = request.uses, .preference = request.preference, .flags = @intFromBool(force), .reserved = 0 };
    if (device.gpu_operations&c.device_gpu_copy_layout == 0 and input.preference == nv.image_prefer_compatible and descriptor.modifier == 0)
        input.preference = nv.image_prefer_linear;
    var result: nv.R4NvImagePlan = undefined;
    const binding = device.selected.binding;
    const status = client.image_layout(&.{ .version = 1, .size = @sizeOf(nv.R4NvDeviceProfile), .vendor_id = profile.vendor_id,
        .copy_class = profile.copy_class, .rm_release = profile.rm_release, .command_abi = profile.command_abi, .flags = 0,
        .adapter_id = binding.adapter_id, .device_generation = binding.device_generation, .reset_generation = binding.reset_generation },&input,&result);
    if (status != nv.status_ok) return if (status == nv.status_unsupported) error.Unsupported else error.Invalid;
    if (result.version != 1 or result.size != @sizeOf(nv.R4NvImagePlan) or result.reserved != 0 or result.action > 1 or
        result.layout > 1 or result.pitch < source.image.width*(try resources.pixelBytes(source.image.format)) or
        result.byte_length == 0 or result.allocation_bytes < result.byte_length or
        result.supported_uses&request.uses != request.uses or (result.layout == 0) != (result.modifier == 0)) return error.Invalid;
    if (result.action == nv.image_action_reuse and (force or result.modifier != descriptor.modifier or
        result.pitch != descriptor.plane_pitches[0] or result.allocation_bytes != descriptor.byte_length)) return error.Invalid;
    if (result.action == nv.image_action_convert and (device.gpu_operations&c.device_gpu_copy_rows == 0 or
        ((result.layout == 1 or descriptor.modifier != 0) and device.gpu_operations&c.device_gpu_copy_layout == 0))) return error.Unsupported;
    return .{ .software = false, .reuse = result.action == nv.image_action_reuse, .bytes = result.allocation_bytes, .native = result };
}
fn fenceSpan(address: u64, count: u32) d.Error!u64 {
    if (count == 0) {
        if (address != 0) return error.Invalid;
        return 0;
    }
    _ = try d.pointer(c.R4GfxCopyFence,address);
    const bytes = @as(u64,count)*@sizeOf(c.R4GfxCopyFence);
    _ = std.math.add(u64,address,bytes) catch return error.Overflow;
    return bytes;
}
pub fn prepare(device: *d.Device, public_handle: *const c.R4GfxDevice, input: *const c.R4GfxImagePrepareRequest, output: *c.R4GfxPreparedImage) d.Error!i32 {
    _ = try d.pointer(c.R4GfxImagePrepareRequest,@intFromPtr(input));
    try d.outputSafe(c.R4GfxPreparedImage,output,device);
    if (d.overlaps(@intFromPtr(input),@sizeOf(c.R4GfxImagePrepareRequest),@intFromPtr(output),@sizeOf(c.R4GfxPreparedImage)) or
        d.overlaps(@intFromPtr(input),@sizeOf(c.R4GfxImagePrepareRequest),@intFromPtr(device),@sizeOf(d.Device))) return error.Alias;
    const request = input.*;
    if (request.version != 1 or request.size != @sizeOf(c.R4GfxImagePrepareRequest) or request.reserved != 0 or
        request.uses == 0 or request.uses&~@as(u32,7) != 0 or request.preference > 2 or request.flags&~c.prepare_force_copy != 0 or
        request.dependency_count > c.copy_max_dependencies or request.ready_capacity > c.copy_max_dependencies or
        request.deadline_ns == 0 or request.deadline_ns == std.math.maxInt(u64)) return error.Invalid;
    const dependency_bytes = try fenceSpan(request.dependencies,request.dependency_count);
    const ready_bytes = try fenceSpan(request.ready_dependencies,request.ready_capacity);
    if (d.overlaps(request.dependencies,dependency_bytes,@intFromPtr(device),@sizeOf(d.Device)) or
        d.overlaps(request.dependencies,dependency_bytes,@intFromPtr(output),@sizeOf(c.R4GfxPreparedImage)) or
        d.overlaps(request.ready_dependencies,ready_bytes,@intFromPtr(input),@sizeOf(c.R4GfxImagePrepareRequest)) or
        d.overlaps(request.ready_dependencies,ready_bytes,@intFromPtr(output),@sizeOf(c.R4GfxPreparedImage)) or
        d.overlaps(request.ready_dependencies,ready_bytes,@intFromPtr(device),@sizeOf(d.Device)) or
        d.overlaps(request.ready_dependencies,ready_bytes,@intFromPtr(public_handle),@sizeOf(c.R4GfxDevice))) return error.Alias;
    var dependencies: [c.copy_max_dependencies]c.R4GfxCopyFence = undefined;
    if (request.dependency_count != 0) @memcpy(dependencies[0..request.dependency_count],@as([*]const c.R4GfxCopyFence,@ptrFromInt(request.dependencies))[0..request.dependency_count]);
    try device.selectBackend();
    const source = try device.resource(request.source,true);
    if (source.invalidated) return error.Stale;
    if (source.kind != c.resource_image) return error.Invalid;
    const plan = try negotiation(device,source,request);
    const ready_count = if (plan.reuse) request.dependency_count else 1;
    if (request.ready_capacity < ready_count) return error.Limit;
    var result: c.R4GfxPreparedImage = std.mem.zeroes(c.R4GfxPreparedImage);
    result.version = 1; result.size = @sizeOf(c.R4GfxPreparedImage);
    result.flags = if (plan.software) c.prepared_software else 0;
    result.dependency_count = ready_count;
    if (plan.reuse) {
        const count = std.math.add(u32,source.public_refs,1) catch return error.Limit;
        result.image = request.source; result.flags |= c.prepared_reused;
        source.public_refs = count;
    } else {
        if (plan.bytes > request.byte_budget) return error.Limit;
        if (source.backing.reference.id == 0) return error.Unsupported;
        const source_image = source.image;
        const usage: u32 = if (request.uses&c.prepare_use_scanout != 0) 60 else 28;
        var descriptor: c.R4GfxResourceDesc = std.mem.zeroes(c.R4GfxResourceDesc);
        descriptor.version = 1; descriptor.size = @sizeOf(c.R4GfxResourceDesc);
        descriptor.kind = c.resource_image; descriptor.flags = c.image_target;
        var native: c.R4GfxNativeImage = undefined;
        if (plan.software) {
            descriptor.source_kind = c.source_create_system;
            descriptor.image = source_image;
            descriptor.image.cpu_address = 0;
        } else {
            descriptor.source_kind = c.source_create_native;
            native = .{ .version = 1, .size = @sizeOf(c.R4GfxNativeImage), .deadline_ns = request.deadline_ns,
                .width = source_image.width, .height = source_image.height, .format = source_image.format, .layout = plan.native.?.layout };
            descriptor.source_address = @intFromPtr(&native);
        }
        _ = try resources.createColoredWithUsage(device,&descriptor,&result.image,usage,source.color);
        const target = device.resource(result.image,true) catch unreachable;
        errdefer {
            target.public_refs -= 1;
            _ = device.cleanResource(target);
        }
        if (target.image.width != source_image.width or target.image.height != source_image.height or target.image.format != source_image.format or
            target.image.byte_length > request.byte_budget) return error.Limit;
        if (plan.native) |layout| {
            if (target.descriptor.location != a.gfx_buffer_location_device_local or target.descriptor.modifier != layout.modifier or
                target.descriptor.plane_pitches[0] != layout.pitch or target.descriptor.byte_length < layout.byte_length or
                target.descriptor.byte_length > layout.allocation_bytes or target.descriptor.usage != usage) return error.Unsupported;
        }
        const copy: c.R4GfxCopyRequestEx = .{ .version = 1, .size = @sizeOf(c.R4GfxCopyRequestEx),
            .copy = .{ .source = request.source, .target = result.image, .source_offset = 0, .target_offset = 0,
                .byte_length = @as(u64,source_image.width)*(try resources.pixelBytes(source_image.format)), .deadline_ns = request.deadline_ns },
            .row_count = source_image.height, .source_pitch = source_image.pitch, .target_pitch = target.image.pitch,
            .dependency_count = request.dependency_count, .dependencies = if (request.dependency_count != 0) @intFromPtr(&dependencies) else 0 };
        _ = try jobs.submitEx(device,&copy,&result.job);
        // No fallible operation follows submit: every created job and image
        // must reach the caller, even if its physical work finishes quickly.
        dependencies[0] = @bitCast((device.job(result.job) catch unreachable).fence);
        result.flags |= c.prepared_copy_pending;
    }
    if (ready_count != 0) @memcpy(@as([*]c.R4GfxCopyFence,@ptrFromInt(request.ready_dependencies))[0..ready_count],dependencies[0..ready_count]);
    output.* = result;
    return c.status_ok;
}
