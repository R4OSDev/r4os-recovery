// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! AMD's common native queue carries a bounded YUV description. The R4D owns
//! ACO code, parameter upload and PM4 execution; this owner only borrows BOs.
const std = @import("std");
const a = @import("r4os").abi;
const amd = @import("r4amd_binding");
const d = @import("device.zig");
const c = d.c;
fn rect(r: c.R4GfxRect) amd.R4AmdRect {
    return .{ .x = @intCast(r.x), .y = @intCast(r.y), .width = r.width, .height = r.height };
}
pub fn submit(device: *d.Device, request: c.R4GfxYuvRenderRequest, target: *d.Resource, slot: usize, serial: u64, color: [64]u32, matrix: [3][4]f32, origin: [2]f32, dependencies: []const a.GfxFence, output: *c.R4GfxJob) d.Error!void {
    const owner = &device.native_yuv;
    const profile = try owner.ensure(device);
    if (profile.backend != c.render_backend_amd) return error.Unsupported;
    const from = request.source;
    const transform = request.transform;
    const input = [_]c.R4GfxYuvBufferPlane{ from.plane0, from.plane1, from.plane2 };
    var indices: [4]u8 = @splat(0);
    var acquired: usize = 0;
    defer owner.release(indices[0..acquired]);
    var planes: [3]amd.R4AmdYuvPlane = @splat(std.mem.zeroes(amd.R4AmdYuvPlane));
    var loans: [4]a.GfxNativeResource = undefined;
    var count: u32 = 0;
    var ready = true;
    for (input[0..from.plane_count], 0..) |p, i| {
        if (p.reserved != 0 or p.byte_length == 0 or p.pitch == 0 or p.pitch > 1024 * 1024) return error.Invalid;
        indices[i] = @intCast(try owner.acquire(device, .{ .id = p.reference_id, .generation = p.reference_generation }, request.deadline_ns));
        const entry = &owner.entries[indices[i]];
        entry.uses += 1;
        acquired += 1;
        const resource = &entry.resource;
        if (std.meta.eql(resource.backing.buffer, target.backing.buffer)) return error.Alias;
        if (resource.descriptor.modifier != 0 or p.offset >= resource.descriptor.byte_length or p.byte_length > resource.descriptor.byte_length - p.offset or
            resource.descriptor.usage & a.gfx_buffer_usage_transfer_source == 0) return error.Unsupported;
        ready = ready and resource.ready;
        const binding = for (loans[0..count], 0..) |loan, index| {
            if (std.meta.eql(loan.binding, resource.binding)) break @as(u32, @intCast(index));
        } else blk: {
            const index = count;
            loans[count] = .{ .binding = resource.binding };
            count += 1;
            break :blk index;
        };
        planes[i] = .{ .binding = binding, .reserved = 0, .offset = p.offset, .byte_length = p.byte_length, .pitch = @intCast(p.pitch), .reserved1 = 0 };
    }
    indices[from.plane_count] = @intCast(try owner.acquire(device, target.backing.reference, request.deadline_ns));
    const dst = &owner.entries[indices[from.plane_count]];
    dst.uses += 1;
    acquired += 1;
    ready = ready and dst.resource.ready;
    if (!ready) return error.Busy;
    const target_binding = count;
    loans[count] = .{ .binding = dst.resource.binding, .access = 1 };
    count += 1;
    const Packet = extern struct { header: amd.R4AmdYuvHeader, color: [64]u32, matrix: [3][4]f32 };
    comptime {
        if (@sizeOf(Packet) != amd.native_yuv_command_bytes or @offsetOf(Packet, "matrix") != 456) @compileError("AMD native YUV ABI");
    }
    const packet: Packet = .{ .header = .{ .version = 1, .size = @sizeOf(amd.R4AmdYuvHeader), .kind = amd.native_yuv_command_kind, .format = from.format, .filter = transform.sampler, .blend = @intFromBool(transform.operation == c.render_operation_over), .opacity = transform.opacity, .width = from.width, .height = from.height, .target_binding = target_binding, .plane_count = from.plane_count, .reserved = 0, .source = rect(transform.source_rect), .destination = rect(transform.target_rect), .scissor = rect(transform.target_rect), .plane0 = planes[0], .plane1 = planes[1], .plane2 = planes[2], .chroma_x = @bitCast(origin[0]), .chroma_y = @bitCast(origin[1]) }, .color = color, .matrix = matrix };
    var submission: a.GfxSubmission = .{ .operation = a.gfx_queue_operation_native, .deadline_ns = request.deadline_ns, .dependency_count = @intCast(dependencies.len) };
    @memcpy(submission.dependencies[0..dependencies.len], dependencies);
    const native: a.GfxNativeSubmission = .{ .interface_id_lo = amd.backend_v1_header.interface_id_lo, .interface_id_hi = amd.backend_v1_header.interface_id_hi, .revision = 1, .command_bytes = @sizeOf(Packet), .resource_count = count, .commands = @intFromPtr(&packet), .resources = @intFromPtr(&loans) };
    try device.ensureQueue();
    var status: a.GfxFenceStatus = .{};
    try d.platform(device.queues().submitNative(&device.queue, &submission, &native, &status));
    owner.hold(indices[0..acquired]);
    target.job_refs += 1;
    device.jobs[slot] = .{ .serial = serial, .target = request.target, .fence = status.fence, .backend = device.backend(), .render = true, .native_yuv_count = @intCast(acquired), .native_yuv_indices = indices };
    device.job_serial = serial;
    output.* = .{ .slot = @intCast(slot + 1), .reserved = 0, .generation = serial, .device_generation = device.generation, .device_address = device.self_address };
}
