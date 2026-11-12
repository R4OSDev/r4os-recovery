// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Native video composition uses vendor providers and canonical queue loans.
//! Only bounded descriptors/commands are CPU-written; source/target pixels stay
//! in their BOs. BUSY preparation keeps no decoder pointer or submitted draw.
const std = @import("std");
const a = @import("r4os").abi;
const nv = @import("r4nv_binding");
const d = @import("device.zig");
const c = d.c;
const yuv = @import("color_yuv.zig");
const resource = @import("native_resource.zig");

// Caller opt-in diagnostics preserve the original admission/error and never
// turn a staged mapping or an encoder result into an execution receipt.
const Trace = @import("native_diagnostics.zig").Trace;

pub fn submit(handle: *const c.R4GfxDevice, request: *const c.R4GfxYuvRenderRequest, output: *c.R4GfxJob) callconv(.c) i32 {
    execute(handle, request, output) catch |err| return d.code(err);
    return c.status_ok;
}
fn bounds(width: u32, height: u32, rect: c.R4GfxRect) d.Error!void {
    if (rect.width == 0 or rect.height == 0 or rect.x >= width or rect.y >= height or
        rect.width > width - rect.x or rect.height > height - rect.y) return error.Invalid;
}
fn nvRect(rect: c.R4GfxRect) nv.R4NvRenderRect {
    return .{ .x = @intCast(rect.x), .y = @intCast(rect.y), .width = rect.width, .height = rect.height };
}
fn nvResult(result: i32) d.Error!void {
    return switch (result) { nv.status_ok => {}, nv.status_unsupported => error.Unsupported, nv.status_capacity => error.Limit, else => error.Invalid };
}
fn plane(item: *const resource.Resource, input: c.R4GfxYuvBufferPlane, from: c.R4GfxYuvBufferImage, index: usize) d.Error!nv.R4NvRenderPlane {
    const desc = item.descriptor;
    const width = if (index == 0) from.width else (from.width + 1) / 2;
    const height = if (index == 0) from.height else (from.height + 1) / 2;
    const pair = index != 0 and from.format != c.yuv_format_yuv420p;
    const p010 = from.format == c.yuv_format_p010;
    const unit: u64 = @as(u64,if (p010) 2 else 1) * @as(u64,if (pair) 2 else 1);
    if (input.reserved != 0 or input.byte_length == 0 or input.offset >= desc.byte_length or input.byte_length > desc.byte_length - input.offset or
        input.pitch < @as(u64,width) * unit or input.pitch > std.math.maxInt(u32) or input.pitch % 32 != 0 or
        desc.usage & a.gfx_buffer_usage_transfer_source == 0) return error.Invalid;
    const rows = if (desc.modifier == 0) height else std.mem.alignForward(u64, height, @as(u64,8) << @intCast(desc.modifier & 15));
    if (input.pitch * rows > input.byte_length) return error.Invalid;
    if (desc.format == a.gfx_buffer_format_nv12 or desc.format == a.gfx_buffer_format_p010) {
        if (index >= 2 or desc.plane_count != 2 or desc.format != @as(u32,if (p010) a.gfx_buffer_format_p010 else a.gfx_buffer_format_nv12) or
            from.format == c.yuv_format_yuv420p or from.width > desc.width or from.height > desc.height or
            input.offset != desc.plane_offsets[index] or input.pitch != desc.plane_pitches[index]) return error.Unsupported;
    } else if (desc.format == a.gfx_buffer_format_r8) {
        if (pair or p010 or desc.plane_count != 1 or input.offset != desc.plane_offsets[0] or input.pitch != desc.plane_pitches[0] or
            width > desc.width or height > desc.height) return error.Unsupported;
    } else if (desc.format != a.gfx_buffer_format_bytes or desc.plane_count != 0) return error.Unsupported;
    return .{ .address = item.address + input.offset, .byte_length = input.byte_length, .modifier = desc.modifier,
        .width = width, .height = height, .pitch = @intCast(input.pitch),
        .format = if (p010) (if (pair) @as(u32,0x32335247) else 0x20363152) else (if (pair) @as(u32,0x38385247) else a.gfx_buffer_format_r8) };
}
fn execute(handle: *const c.R4GfxDevice, input: *const c.R4GfxYuvRenderRequest, output: *c.R4GfxJob) d.Error!void {
    const device = try d.get(handle, false);
    var trace = Trace.init(device);
    errdefer |err| trace.failure(err);
    _ = try d.pointer(c.R4GfxYuvRenderRequest, @intFromPtr(input));
    try d.outputSafe(c.R4GfxJob, output, device);
    if (d.overlaps(@intFromPtr(input), @sizeOf(c.R4GfxYuvRenderRequest), @intFromPtr(device), @sizeOf(d.Device)) or
        d.overlaps(@intFromPtr(input), @sizeOf(c.R4GfxYuvRenderRequest), @intFromPtr(output), @sizeOf(c.R4GfxJob)) or
        d.overlaps(@intFromPtr(handle), @sizeOf(c.R4GfxDevice), @intFromPtr(output), @sizeOf(c.R4GfxJob))) return error.Alias;
    const request = input.*; const from = request.source; const transform = request.transform;
    if (request.version != 1 or request.size != @sizeOf(c.R4GfxYuvRenderRequest) or request.reserved != 0 or
        from.version != 1 or from.size != @sizeOf(c.R4GfxYuvBufferImage) or from.reserved != 0 or
        from.width == 0 or from.height == 0 or from.width > 16384 or from.height > 16384 or
        transform.version != 1 or transform.size != @sizeOf(c.R4GfxColorTransform) or transform.opacity > 65535 or transform.sampler > 1 or
        (transform.operation != c.render_operation_blit and transform.operation != c.render_operation_over) or
        request.dependency_count > c.copy_max_dependencies or (request.dependency_count == 0 and request.dependencies != 0)) return error.Invalid;
    const format = std.enums.fromInt(yuv.Format, from.format) orelse return error.Unsupported;
    if (from.plane_count != @as(u32,if (format == .yuv420p) 3 else 2)) return error.Invalid;
    const planes = [_]c.R4GfxYuvBufferPlane{ from.plane0, from.plane1, from.plane2 };
    if (from.plane_count == 2 and !std.meta.eql(from.plane2, std.mem.zeroes(c.R4GfxYuvBufferPlane))) return error.Invalid;
    try bounds(from.width, from.height, from.crop);
    try bounds(from.width, from.height, transform.source_rect);
    const crop = from.crop; const src = transform.source_rect;
    if (src.x < crop.x or src.y < crop.y or src.x + src.width > crop.x + crop.width or src.y + src.height > crop.y + crop.height) return error.Invalid;
    const pixels = @as(u64,transform.target_rect.width) * transform.target_rect.height;
    if (pixels == 0 or pixels > transform.pixel_budget or pixels > c.render_max_pixels or transform.pixel_budget > c.render_max_pixels) return error.Limit;
    const now = device.base().monotonicNanoseconds() orelse return error.Unavailable;
    if (request.deadline_ns <= now or request.deadline_ns == std.math.maxInt(u64)) return error.Invalid;
    const metadata = try d.color_api.yuvDescription(from.description);
    const source_color = try metadata.description(format);
    const matrix = try yuv.Matrix.init(metadata, format);
    const origin = yuv.chromaOffset(metadata.chroma);
    var dependencies: [c.copy_max_dependencies]a.GfxFence = undefined;
    if (request.dependency_count != 0) {
        _ = try d.pointer(c.R4GfxCopyFence, request.dependencies);
        const bytes = @as(u64,request.dependency_count) * @sizeOf(c.R4GfxCopyFence);
        _ = std.math.add(u64, request.dependencies, bytes) catch return error.Overflow;
        if (d.overlaps(request.dependencies, bytes, @intFromPtr(device), @sizeOf(d.Device)) or
            d.overlaps(request.dependencies, bytes, @intFromPtr(output), @sizeOf(c.R4GfxJob))) return error.Alias;
        @memcpy(dependencies[0..request.dependency_count], @as([*]const a.GfxFence,@ptrFromInt(request.dependencies))[0..request.dependency_count]);
    }
    try device.selectBackend();
    trace.stage = "target-residency";
    if (device.backend() != c.render_backend_nvidia and device.backend() != c.render_backend_amd) return error.Unsupported;
    const target = try device.resource(request.target, true);
    if (target.invalidated) return error.Stale;
    if (target.kind != c.resource_image or target.flags & c.image_target == 0 or target.backing.reference.id == 0 or
        target.descriptor.usage & a.gfx_buffer_usage_render == 0) return error.Unsupported;
    try bounds(target.image.width, target.image.height, transform.target_rect);
    if (target.image.width > 16384 or target.image.height > 16384) return error.Unsupported;
    try @import("device_residency.zig").ensure(device, target, request.deadline_ns);
    if (!device.cleanResources()) return error.Busy;
    const target_color = try d.color_api.description(&(target.color orelse return error.Unsupported));
    const program = @import("color_gpu.zig").build(source_color, target_color, transform.flags, transform.operation == c.render_operation_over)
        catch |err| return if (err == error.Invalid) error.Invalid else error.Unsupported;
    const slot = for (&device.jobs, 0..) |*job, i| { if (job.serial == 0) break i; } else return error.Busy;
    const serial = std.math.add(u64, device.job_serial, 1) catch return error.Limit;
    if (target.job_refs == std.math.maxInt(u32)) return error.Limit;
    if (device.backend() == c.render_backend_amd) return @import("native_yuv_amd.zig").submit(device,request,target,slot,serial,
        program.words,matrix.rows,origin,dependencies[0..request.dependency_count],output);
    const owner = &device.native_yuv;
    trace.stage = "native-profile";
    const profile = try owner.ensure(device);
    const client = device.caller.client(nv.RenderV1Client) catch return error.Unsupported;
    var indices: [4]u8 = @splat(0);
    var acquired: usize = 0;
    // Keep earlier planes protected while later cache entries are acquired.
    // Successful queue submission receives a second set of uses below.
    defer owner.release(indices[0..acquired]);
    var views: [3]nv.R4NvRenderPlane = @splat(std.mem.zeroes(nv.R4NvRenderPlane));
    var ready = true;
    for (planes[0..from.plane_count], 0..) |value, i| {
        trace.stage = if (i == 0) "luma-mapping" else "chroma-mapping";
        indices[i] = @intCast(try owner.acquire(device, .{ .id = value.reference_id, .generation = value.reference_generation, .reserved0 = value.reserved }, request.deadline_ns));
        const entry = &owner.entries[indices[i]].resource;
        owner.entries[indices[i]].uses += 1;
        acquired += 1;
        if (std.meta.eql(entry.backing.buffer, target.backing.buffer)) return error.Alias;
        trace.stage = if (i == 0) "luma-view" else "chroma-view";
        views[i] = try plane(entry, value, from, i);
        ready = ready and entry.ready;
    }
    trace.stage = "target-mapping";
    indices[from.plane_count] = @intCast(try owner.acquire(device, target.backing.reference, request.deadline_ns));
    owner.entries[indices[from.plane_count]].uses += 1;
    acquired += 1;
    const target_map = &owner.entries[indices[from.plane_count]].resource;
    trace.stage = "upload-mapping";
    const upload = try owner.upload(device, slot, request.deadline_ns);
    if (!ready or !target_map.ready or !upload.ready) return error.Busy;
    var info: nv.R4NvRenderInfo = undefined;
    trace.stage = "renderer-info";
    try nvResult(client.render_info(profile.graphics_class, &info));
    if (info.version != 1 or info.size != @sizeOf(nv.R4NvRenderInfo) or info.packet_bytes != 1280 or info.max_command_words > 1024 or info.program_bytes == 0) return error.Unsupported;
    const packet_offset = std.mem.alignForward(u64, info.program_bytes, 256);
    const command_offset = std.mem.alignForward(u64, packet_offset + info.packet_bytes, 256);
    if (command_offset + @as(u64,info.max_command_words) * 4 > resource.granule) return error.Limit;
    const bytes = upload.bytes();
    var written: u32 = 0;
    if (!owner.uploaded[slot]) {
        trace.stage = "shader-upload";
        try nvResult(client.render_upload(profile.graphics_class, bytes.ptr, info.program_bytes, &written));
        if (written != info.program_bytes) return error.Invalid;
        owner.uploaded[slot] = true;
    }
    const draw: nv.R4NvYuvDraw = .{ .luma = views[0], .chroma = views[1], .second_chroma = views[2],
        .target = .{ .address = target_map.address, .byte_length = target.descriptor.byte_length, .modifier = target.descriptor.modifier,
            .width = target.image.width, .height = target.image.height, .pitch = std.math.cast(u32, target.image.pitch) orelse return error.Unsupported, .format = target.image.format },
        .source_rect = nvRect(src), .destination = nvRect(transform.target_rect), .scissor = nvRect(transform.target_rect),
        .format = from.format, .filter = transform.sampler, .blend = @intFromBool(transform.operation == c.render_operation_over), .opacity = transform.opacity,
        .chroma_x = @bitCast(origin[0]), .chroma_y = @bitCast(origin[1]) };
    trace.stage = "encode-yuv";
    try nvResult(client.encode_yuv(&.{ .version = 1, .size = @sizeOf(nv.R4NvYuvRender), .graphics_class = profile.graphics_class, .draw_count = 1,
        .draws = @intFromPtr(&draw), .program_address = upload.address, .program_bytes = info.program_bytes,
        .packet_address = upload.address + packet_offset, .packet_bytes = info.packet_bytes,
        .color_program = @intFromPtr(&program), .yuv_matrix = @intFromPtr(&matrix.rows) },
        @ptrCast(@alignCast(bytes[command_offset..].ptr)), info.max_command_words, bytes[packet_offset..].ptr, info.packet_bytes, &written));
    if (written == 0 or written > info.max_command_words) return error.Invalid;
    var loans: [5]a.GfxNativeResource = undefined;
    loans[0] = .{ .binding = upload.binding };
    var loan_count: usize = 1;
    for (indices[0..from.plane_count+1], 0..) |index, i| {
        const binding = owner.entries[index].resource.binding;
        const access: u32 = @intFromBool(i == from.plane_count);
        var duplicate = false;
        for (loans[0..loan_count]) |*loan| if (std.meta.eql(loan.binding, binding)) { loan.access |= access; duplicate = true; break; };
        if (!duplicate) { loans[loan_count] = .{ .binding = binding, .access = access }; loan_count += 1; }
    }
    const packet = extern struct { header: nv.R4NvNativeSubmitHeader, push: nv.R4NvNativePush }{
        .header = .{ .version = nv.native_submit_version, .size = @sizeOf(nv.R4NvNativeSubmitHeader), .engine_mask = nv.native_engine_graphics,
            .push_count = 1, .reserved0 = 0, .reserved1 = 0 },
        .push = .{ .address = upload.address + command_offset, .byte_length = written * 4, .flags = 0 } };
    var submission: a.GfxSubmission = .{ .operation = a.gfx_queue_operation_native, .deadline_ns = request.deadline_ns, .dependency_count = request.dependency_count };
    @memcpy(submission.dependencies[0..request.dependency_count], dependencies[0..request.dependency_count]);
    const native: a.GfxNativeSubmission = .{ .interface_id_lo = nv.backend_v1_header.interface_id_lo, .interface_id_hi = nv.backend_v1_header.interface_id_hi,
        .revision = 1, .command_bytes = @sizeOf(@TypeOf(packet)), .commands = @intFromPtr(&packet), .resource_count = @intCast(loan_count), .resources = @intFromPtr(&loans) };
    trace.stage = "queue-binding";
    try device.ensureQueue();
    asm volatile ("mfence" ::: .{ .memory = true });
    var status: a.GfxFenceStatus = .{};
    trace.stage = "queue-admission";
    try d.queueAdmission(device.queues().submitNative(&device.queue, &submission, &native, &status));
    owner.hold(indices[0..from.plane_count+1]);
    target.job_refs += 1;
    device.jobs[slot] = .{ .serial = serial, .target = request.target, .fence = status.fence, .backend = device.backend(),
        .render = true, .native_yuv_count = @intCast(from.plane_count + 1), .native_yuv_indices = indices };
    device.job_serial = serial;
    output.* = .{ .slot = @intCast(slot + 1), .reserved = 0, .generation = serial, .device_generation = device.generation, .device_address = device.self_address };
}
