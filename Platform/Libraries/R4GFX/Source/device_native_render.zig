//! Resolve logical state once, then hand immutable values and retained BOs
//! to the common queue. No image map, pixel conversion or GPU wait occurs here.
const std = @import("std");
const a = @import("r4os").abi;
const d = @import("device.zig");
const c = d.c;
const empty_resource = std.mem.zeroes(c.R4GfxResource);
const empty_rect = std.mem.zeroes(c.R4GfxSignedRect);

fn image(device: *d.Device, handle: c.R4GfxResource, target: bool) d.Error!*d.Resource {
    const result = try device.resource(handle, true);
    if (result.invalidated) return error.Stale;
    if (result.kind != c.resource_image or (target and result.flags & c.image_target == 0)) return error.Invalid;
    if (result.backing.reference.id == 0) return error.Unsupported;
    return result;
}
pub fn submit(device: *d.Device, input: *const c.R4GfxRenderRequest, output: *c.R4GfxJob) d.Error!i32 {
    _ = try d.pointer(c.R4GfxRenderRequest, @intFromPtr(input));
    try d.outputSafe(c.R4GfxJob, output, device);
    if (d.overlaps(@intFromPtr(input), @sizeOf(c.R4GfxRenderRequest), @intFromPtr(output), @sizeOf(c.R4GfxJob)) or
        d.overlaps(@intFromPtr(input), @sizeOf(c.R4GfxRenderRequest), @intFromPtr(device), @sizeOf(d.Device))) return error.Alias;
    const request = input.*;
    return execute(device, &.{request}, false, null, null, output);
}
pub fn submitList(device: *d.Device, input: *const c.R4GfxRenderListRequest, output: *c.R4GfxJob) d.Error!i32 {
    return submitListCommon(device, input, null, output);
}
pub fn submitColorList(device: *d.Device, input: *const c.R4GfxRenderListRequest, flags: u32, output: *c.R4GfxJob) d.Error!i32 {
    return submitListCommon(device, input, flags, output);
}
fn submitListCommon(device: *d.Device, input: *const c.R4GfxRenderListRequest, color_flags: ?u32, output: *c.R4GfxJob) d.Error!i32 {
    _ = try d.pointer(c.R4GfxRenderListRequest, @intFromPtr(input));
    try d.outputSafe(c.R4GfxJob, output, device);
    const request = input.*;
    if (request.version != 1 or request.size != @sizeOf(c.R4GfxRenderListRequest) or request.reserved != 0 or
        request.count == 0 or request.count > c.render_list_capacity) return error.Invalid;
    _ = try d.pointer(c.R4GfxRenderRequest, request.commands);
    const bytes = @as(u64, request.count) * @sizeOf(c.R4GfxRenderRequest);
    _ = std.math.add(u64, request.commands, bytes) catch return error.Overflow;
    if (d.overlaps(@intFromPtr(input), @sizeOf(c.R4GfxRenderListRequest), @intFromPtr(device), @sizeOf(d.Device)) or
        d.overlaps(@intFromPtr(input), @sizeOf(c.R4GfxRenderListRequest), @intFromPtr(output), @sizeOf(c.R4GfxJob)) or
        d.overlaps(request.commands, bytes, @intFromPtr(device), @sizeOf(d.Device)) or
        d.overlaps(request.commands, bytes, @intFromPtr(output), @sizeOf(c.R4GfxJob))) return error.Alias;
    var copied: [c.render_list_capacity]c.R4GfxRenderRequest = undefined;
    @memcpy(copied[0..request.count], @as([*]const c.R4GfxRenderRequest, @ptrFromInt(request.commands))[0..request.count]);
    return execute(device, copied[0..request.count], true, null, color_flags, output);
}
pub fn submitGridList(device: *d.Device, input: *const c.R4GfxRenderGridListRequest, output: *c.R4GfxJob) d.Error!i32 {
    return submitGridListCommon(device, input, null, output);
}
pub fn submitColorGridList(device: *d.Device, input: *const c.R4GfxRenderGridListRequest, flags: u32, output: *c.R4GfxJob) d.Error!i32 {
    return submitGridListCommon(device, input, flags, output);
}
fn submitGridListCommon(device: *d.Device, input: *const c.R4GfxRenderGridListRequest, color_flags: ?u32, output: *c.R4GfxJob) d.Error!i32 {
    _ = try d.pointer(c.R4GfxRenderGridListRequest, @intFromPtr(input));
    try d.outputSafe(c.R4GfxJob, output, device);
    const request = input.*;
    if (request.version != 1 or request.size != @sizeOf(c.R4GfxRenderGridListRequest) or request.reserved != 0 or
        request.count == 0 or request.count > c.render_list_capacity) return error.Invalid;
    _ = try d.pointer(c.R4GfxRenderRequest, request.commands);
    _ = try d.pointer(c.R4GfxLogicalGrid, request.grids);
    const spans = [_][2]u64{ .{ @intFromPtr(input), @sizeOf(c.R4GfxRenderGridListRequest) },
        .{ request.commands, @as(u64, request.count) * @sizeOf(c.R4GfxRenderRequest) },
        .{ request.grids, @as(u64, request.count) * @sizeOf(c.R4GfxLogicalGrid) } };
    for (spans) |span| {
        _ = std.math.add(u64, span[0], span[1]) catch return error.Overflow;
        if (d.overlaps(span[0], span[1], @intFromPtr(device), @sizeOf(d.Device)) or
            d.overlaps(span[0], span[1], @intFromPtr(output), @sizeOf(c.R4GfxJob))) return error.Alias;
    }
    var commands: [c.render_list_capacity]c.R4GfxRenderRequest = undefined;
    var grids: [c.render_list_capacity]c.R4GfxLogicalGrid = undefined;
    @memcpy(commands[0..request.count], @as([*]const c.R4GfxRenderRequest, @ptrFromInt(request.commands))[0..request.count]);
    @memcpy(grids[0..request.count], @as([*]const c.R4GfxLogicalGrid, @ptrFromInt(request.grids))[0..request.count]);
    return execute(device, commands[0..request.count], true, grids[0..request.count], color_flags, output);
}
fn execute(device: *d.Device, requests: []const c.R4GfxRenderRequest, batched: bool, grids: ?[]const c.R4GfxLogicalGrid, color_flags: ?u32, output: *c.R4GfxJob) d.Error!i32 {
    const request = requests[0];
    if (request.version != 1 or request.size != @sizeOf(c.R4GfxRenderRequest) or request.opacity > 255 or
        request.transfer > c.render_transfer_srgb_encode or request.dependency_count > c.copy_max_dependencies or
        (request.dependency_count == 0 and request.dependencies != 0)) return error.Invalid;
    var dependencies: [c.copy_max_dependencies]a.GfxFence = undefined;
    if (request.dependency_count != 0) {
        _ = try d.pointer(c.R4GfxCopyFence, request.dependencies);
        const bytes = @as(u64, request.dependency_count) * @sizeOf(c.R4GfxCopyFence);
        _ = std.math.add(u64, request.dependencies, bytes) catch return error.Overflow;
        if (d.overlaps(request.dependencies, bytes, @intFromPtr(output), @sizeOf(c.R4GfxJob)) or
            d.overlaps(request.dependencies, bytes, @intFromPtr(device), @sizeOf(d.Device))) return error.Alias;
        const source: [*]const c.R4GfxCopyFence = @ptrFromInt(request.dependencies);
        for (source[0..request.dependency_count], 0..) |fence, i| dependencies[i] = @bitCast(fence);
    }
    try device.selectBackend();
    if (device.gpu_operations & c.device_gpu_render == 0) return error.Unsupported;
    if (batched and device.gpu_operations & c.device_gpu_render_list == 0) return error.Unsupported;
    if (grids != null and device.gpu_operations & c.device_gpu_grid == 0) return error.Unsupported;
    if (color_flags != null and device.gpu_operations & c.device_gpu_color == 0) return error.Unsupported;
    if (color_flags != null and grids != null and device.gpu_operations & c.device_gpu_color_grid == 0) return error.Unsupported;
    const pipeline = try device.resource(request.pipeline, true);
    if (pipeline.kind != c.resource_pipeline) return error.Invalid;
    const fill = pipeline.operation == c.render_operation_fill;
    const target = try image(device, request.target, true);
    const source: ?*d.Resource = if (fill) null else try image(device, request.source, false);
    var filter: u32 = 0;
    if (fill) {
        if (!std.meta.eql(request.source, empty_resource) or !std.meta.eql(request.sampler, empty_resource) or
            !std.meta.eql(request.source_rect, empty_rect) or request.transfer != 0) return error.Invalid;
    } else {
        if (request.color != 0) return error.Invalid;
        if (std.meta.eql(source.?.backing.buffer, target.backing.buffer)) return error.Alias;
        const sampler = try device.resource(request.sampler, true);
        if (sampler.kind != c.resource_sampler) return error.Invalid;
        filter = sampler.sampler;
    }
    const color_program: ?a.GfxRenderColorProgram = if (color_flags) |flags| blk: {
        if (fill or filter != c.render_sampler_nearest or request.transfer != c.render_transfer_identity) return error.Unsupported;
        const color_api = @import("color_api.zig");
        const from = try color_api.description(&(source.?.color orelse return error.Unsupported));
        const to = try color_api.description(&(target.color orelse return error.Unsupported));
        const over = pipeline.operation == c.render_operation_over;
        if (over and to.precision != .float16) return error.Unsupported;
        const program = @import("color_gpu.zig").build(from, to, flags, over) catch |err| return if (err == error.Invalid) error.Invalid else error.Unsupported;
        break :blk .{ .words = program.words };
    } else null;
    var list: a.GfxRenderList = .{ .count = @intCast(requests.len) };
    for (requests, 0..) |item, i| {
        if (item.version != 1 or item.size != @sizeOf(c.R4GfxRenderRequest) or item.opacity > 255 or
            item.transfer != request.transfer or item.deadline_ns != request.deadline_ns or
            !std.meta.eql(item.source, request.source) or !std.meta.eql(item.target, request.target) or
            !std.meta.eql(item.pipeline, request.pipeline) or !std.meta.eql(item.sampler, request.sampler) or
            (i != 0 and (item.dependency_count != 0 or item.dependencies != 0)) or
            (fill and !std.meta.eql(item.source_rect, empty_rect)) or (!fill and item.color != 0)) return error.Invalid;
        if (grids) |values| {
            const grid = values[i];
            if (grid.enabled == 0) {
                if (!std.meta.eql(grid, std.mem.zeroes(c.R4GfxLogicalGrid))) return error.Invalid;
            } else if (grid.enabled != 1 or grid.reserved != 0 or grid.rotation > 3 or
                grid.scale < 60 or grid.scale > 960 or grid.pixel_width == 0 or grid.pixel_height == 0 or
                grid.viewport_width == 0 or grid.viewport_height == 0 or grid.guest_width == 0 or grid.guest_height == 0 or
                fill or filter != c.render_sampler_nearest or item.transfer != c.render_transfer_identity) return error.Invalid;
        }
        if (color_program == null) try @import("color_resource.zig").nativeTransition(source, target, item.transfer, pipeline.operation, item.color);
        list.commands[i] = .{ .kind = if (fill) a.gfx_render_kind_fill else a.gfx_render_kind_sample,
            .blend = if (pipeline.operation == c.render_operation_over) a.gfx_render_blend_over else a.gfx_render_blend_replace,
            .filter = filter, .transfer = if (color_program != null) a.gfx_render_transfer_color else item.transfer, .color = item.color, .opacity = item.opacity,
            .source_rect = @bitCast(item.source_rect), .target_rect = @bitCast(item.target_rect), .scissor = @bitCast(item.scissor) };
    }
    const index = for (&device.jobs, 0..) |*item, i| { if (item.serial == 0) break i; } else return error.Busy;
    const serial = std.math.add(u64, device.job_serial, 1) catch return error.Limit;
    if (target.job_refs == std.math.maxInt(u32) or (source != null and source.?.job_refs == std.math.maxInt(u32))) return error.Limit;
    if (!device.cleanResources()) return error.Busy;
    try @import("device_residency.zig").ensure(device, target, request.deadline_ns);
    if (source) |value| try @import("device_residency.zig").ensure(device, value, request.deadline_ns);
    try device.ensureQueue();
    var submission: a.GfxSubmission = .{ .operation = if (batched) a.gfx_queue_operation_render_list else a.gfx_queue_operation_render, .deadline_ns = request.deadline_ns,
        .target = target.backing.reference, .source = if (source) |value| value.backing.reference else .{},
        .render = list.commands[0], .dependency_count = request.dependency_count };
    @memcpy(submission.dependencies[0..request.dependency_count], dependencies[0..request.dependency_count]);
    const queues = device.queues();
    var status: a.GfxFenceStatus = .{};
    if (color_program != null and grids != null) {
        var mapped: a.GfxRenderColorGridList = .{ .count = list.count, .commands = list.commands, .program = color_program.? };
        for (grids.?, 0..) |grid, i| mapped.grids[i] = @bitCast(grid);
        submission.operation = a.gfx_queue_operation_render_color_grid_list;
        try d.queueAdmission(queues.submitRenderColorGridList(&device.queue, &submission, &mapped, &status));
    } else if (color_program) |program| {
        const mapped: a.GfxRenderColorList = .{ .count = list.count, .commands = list.commands, .program = program };
        submission.operation = a.gfx_queue_operation_render_color_list;
        try d.queueAdmission(queues.submitRenderColorList(&device.queue, &submission, &mapped, &status));
    } else if (grids) |values| {
        var mapped: a.GfxRenderGridList = .{ .count = list.count, .commands = list.commands };
        for (values, 0..) |grid, i| mapped.grids[i] = @bitCast(grid);
        submission.operation = a.gfx_queue_operation_render_grid_list;
        try d.queueAdmission(queues.submitRenderGridList(&device.queue, &submission, &mapped, &status));
    } else try d.queueAdmission(if (batched) queues.submitRenderList(&device.queue, &submission, &list, &status) else queues.submit(&device.queue, &submission, &status));
    target.job_refs += 1;
    if (source) |value| value.job_refs += 1;
    device.jobs[index] = .{ .serial = serial, .source = request.source, .target = request.target,
        .fence = status.fence, .backend = device.backend(), .render = true };
    device.job_serial = serial;
    output.* = .{ .slot = @intCast(index + 1), .reserved = 0, .generation = serial, .device_generation = device.generation, .device_address = device.self_address };
    return c.status_ok;
}
