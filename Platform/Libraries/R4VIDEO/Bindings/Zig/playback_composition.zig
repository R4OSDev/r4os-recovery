// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Three bounded composition owners. Decoder leases remain with the media host
//! until release() confirms CPU unmaps or the R4GFX job's physical retirement.
const std = @import("std");
const r4os = @import("r4os");
const a = r4os.abi;
const v = @import("r4video.zig");
const g = @import("r4gfx_binding");
pub const Error = error{ Invalid, Unsupported, Busy, Stale, Lost, Failed };
pub const Ticket = struct { slot: u8, serial: u64 };
pub const State = enum { preparing, rendering, retiring, ready, failed };
pub const Target = union(enum) {
    /// Caller keeps the CPU target storage alive through release(ticket).
    cpu: g.R4GfxColorImage,
    /// R4GFX retains the actual target after submission; keep its public handle
    /// valid while preparation is BUSY. Present it through the usual host path.
    gpu: g.R4GfxResource,
};
pub const ColorPolicy = struct {
    // An explicit fallback applies only to unspecified fields, never to an
    // unsupported signaled matrix/transfer. Zero means reject unspecified.
    primaries: u32 = 0,
    transfer: u32 = 0,
    matrix: u32 = 0,
    chroma: u32 = 0,
    range: u32 = 0,
    reference_white: u32,
    peak: u32,
    black: u32 = 0,
    pub fn describe(self: ColorPolicy, input: v.R4VideoColor) Error!g.R4GfxYuvDescription {
        if (input.version != 1 or input.size != @sizeOf(v.R4VideoColor) or input.flags & ~@as(u32, 3) != 0) return error.Invalid;
        const result: g.R4GfxYuvDescription = .{ .version = 1, .size = @sizeOf(g.R4GfxYuvDescription),
            .primaries = if (input.primaries == 2) self.primaries else input.primaries,
            .transfer = if (input.transfer == 2) self.transfer else input.transfer,
            .matrix = if (input.matrix == 2) self.matrix else input.matrix,
            .range = if (input.range == 0) self.range else input.range,
            .chroma_location = if (input.chroma_location == 0) self.chroma else input.chroma_location,
            .reference_white = if (input.flags & v.color_reference_white != 0) input.reference_white else self.reference_white,
            .peak = if (input.flags & v.color_luminance != 0) input.peak else self.peak,
            .black = if (input.flags & v.color_luminance != 0) input.black else self.black,
            .flags = 0, .reserved = 0 };
        if (result.primaries == 0 or result.transfer == 0 or result.range == 0 or result.chroma_location == 0 or result.reference_white == 0 or result.peak == 0) return error.Unsupported;
        return result;
    }
};
const Work = struct {
    serial: u64 = 0,
    state: State = .preparing,
    frame: v.R4VideoFrame = undefined,
    target: Target = undefined,
    transform: g.R4GfxColorTransform = undefined,
    description: g.R4GfxYuvDescription = undefined,
    deadline: u64 = 0,
    job: ?g.R4GfxJob = null,
    maps: [3]a.GfxBufferMap = @splat(.{}),
    cancel: bool = false,
    result: i32 = 0,
};
pub const Composition = struct {
    buffers: r4os.gfx_buffers.Context,
    queues: r4os.gfx_queue.Context,
    color: g.ColorV1Client,
    graphics: g.DeviceV1Client,
    device: g.R4GfxDevice,
    work: [3]Work = @splat(.{}),
    serial: u64 = 0,

    pub fn submit(self: *Composition, frame: v.R4VideoFrame, target: Target, transform: g.R4GfxColorTransform, policy: ColorPolicy, deadline: u64) Error!Ticket {
        if (frame.version != 1 or frame.size != @sizeOf(v.R4VideoFrame) or frame.lease.token == 0 or
            frame.coded_width == 0 or frame.coded_height == 0 or frame.plane_count < 2 or frame.plane_count > 3 or deadline == 0) return error.Invalid;
        const description = try policy.describe(frame.color);
        const index = for (&self.work, 0..) |*item, i| { if (item.serial == 0) break i; } else return error.Busy;
        const serial = std.math.add(u64, self.serial, 1) catch return error.Busy;
        self.work[index] = .{ .serial = serial, .frame = frame, .target = target, .transform = transform,
            .description = description, .deadline = deadline };
        self.serial = serial;
        return .{ .slot = @intCast(index), .serial = serial };
    }
    fn get(self: *Composition, ticket: Ticket) Error!*Work {
        if (ticket.slot >= self.work.len or ticket.serial == 0 or self.work[ticket.slot].serial != ticket.serial) return error.Stale;
        return &self.work[ticket.slot];
    }
    pub fn cancel(self: *Composition, ticket: Ticket) Error!void { (try self.get(ticket)).cancel = true; }
    pub fn release(self: *Composition, ticket: Ticket) Error!void {
        const item = try self.get(ticket);
        if (item.state != .ready and item.state != .failed) return error.Busy;
        item.* = .{};
    }
    pub fn result(self: *Composition, ticket: Ticket) Error!i32 { return (try self.get(ticket)).result; }
    fn retireMaps(self: *Composition, item: *Work) bool {
        var done = true;
        for (&item.maps) |*map| if (map.lease.id != 0) {
            if (self.buffers.unmap(&map.lease) == a.gfx_buffer_result_ok) map.* = .{} else done = false;
        };
        return done;
    }
    pub fn poll(self: *Composition, ticket: Ticket, now: u64) Error!State {
        const item = try self.get(ticket);
        if (item.state == .ready or item.state == .failed) return item.state;
        if (now >= item.deadline) item.cancel = true;
        if (item.job) |job| {
            if (item.cancel) _ = self.graphics.job_cancel(&self.device, &job);
            var info: g.R4GfxJobInfo = undefined;
            const rc = self.graphics.job_info(&self.device, &job, &info);
            if (rc != g.status_ok) return error.Lost; // retain exact job/lease
            if (info.phase != a.gfx_queue_phase_terminal or info.flags & (a.gfx_queue_flag_device_active | a.gfx_queue_flag_resources_held) != 0) return item.state;
            if (info.result != a.gfx_queue_result_complete) item.result = g.status_lost;
            if (self.graphics.job_release(&self.device, &job) != g.status_ok) return item.state;
            item.job = null;
            item.state = .retiring;
        }
        if (item.cancel and item.result == 0) item.result = g.status_unavailable;
        if (item.state == .retiring or item.cancel) {
            if (self.retireMaps(item)) item.state = if (item.result == 0) .ready else .failed;
            return item.state;
        }
        if (!std.meta.eql(item.frame.ready, std.mem.zeroes(v.R4VideoFence))) {
            const fence: a.GfxFence = @bitCast(item.frame.ready);
            var status: a.GfxFenceStatus = .{};
            if (self.queues.query(&fence, &status) != a.gfx_queue_ok or !std.meta.eql(status.fence, fence)) return error.Lost;
            if (status.phase != a.gfx_queue_phase_terminal or status.flags & a.gfx_queue_flag_device_active != 0) return .preparing;
            if (status.result != a.gfx_queue_result_complete) { item.result = g.status_lost; item.state = .retiring; return .retiring; }
        }
        self.prepare(item) catch |err| switch (err) {
            error.Busy => return .preparing,
            else => { item.result = if (err == error.Unsupported) g.status_unsupported else g.status_invalid; item.state = .retiring; },
        };
        return item.state;
    }
    fn prepare(self: *Composition, item: *Work) Error!void {
        const frame = item.frame;
        const planes = [_]v.R4VideoPlane{ frame.plane0, frame.plane1, frame.plane2 };
        var input: g.R4GfxYuvBufferImage = std.mem.zeroes(g.R4GfxYuvBufferImage);
        input.version = 1; input.size = @sizeOf(g.R4GfxYuvBufferImage);
        input.width = frame.coded_width; input.height = frame.coded_height;
        input.format = frame.format; input.plane_count = frame.plane_count;
        input.crop = .{ .x = frame.crop_x, .y = frame.crop_y, .width = frame.crop_width, .height = frame.crop_height };
        input.description = item.description;
        var views: [3]g.R4GfxYuvBufferPlane = @splat(std.mem.zeroes(g.R4GfxYuvBufferPlane));
        var cpu: [3]g.R4GfxYuvPlane = @splat(std.mem.zeroes(g.R4GfxYuvPlane));
        for (planes[0..frame.plane_count], 0..) |plane, i| {
            const reference: a.GfxBufferHandle = @bitCast(plane.reference);
            var desc: a.GfxBufferDescriptor = .{};
            if (self.buffers.describe(&reference, &desc) != a.gfx_buffer_result_ok) return error.Lost;
            if (plane.offset >= desc.byte_length or plane.pitch == 0 or plane.row_bytes > plane.pitch or plane.rows == 0) return error.Invalid;
            views[i] = .{ .reference_id = reference.id, .reference_generation = reference.generation, .reserved = 0,
                .offset = plane.offset, .byte_length = desc.byte_length - plane.offset, .pitch = plane.pitch };
            if (item.target == .cpu) {
                // Software mode is explicit and only admits system linear BOs.
                if (desc.location != a.gfx_buffer_location_system or desc.modifier != 0 or desc.usage & a.gfx_buffer_usage_cpu_read == 0) return error.Unsupported;
                if (item.maps[i].lease.id == 0 and self.buffers.map(&reference, a.gfx_buffer_map_read, plane.offset, desc.byte_length - plane.offset, &item.maps[i]) != a.gfx_buffer_result_ok) return error.Busy;
                cpu[i] = .{ .cpu_address = item.maps[i].cpu_address, .byte_length = item.maps[i].byte_length, .pitch = plane.pitch, .reserved = 0 };
            }
        }
        input.plane0 = views[0]; input.plane1 = views[1]; input.plane2 = views[2];
        switch (item.target) {
            .gpu => |target| {
                var job: g.R4GfxJob = undefined;
                const rc = self.color.color_yuv_render_submit(&self.device, &.{ .version = 1, .size = @sizeOf(g.R4GfxYuvRenderRequest),
                    .source = input, .target = target, .transform = item.transform, .deadline_ns = item.deadline,
                    .dependencies = 0, .dependency_count = 0, .reserved = 0 }, &job);
                if (rc == g.status_busy) return error.Busy;
                if (rc != g.status_ok) return if (rc == g.status_unsupported) error.Unsupported else error.Failed;
                item.job = job;
                item.state = .rendering;
            },
            .cpu => |target| {
                const source: g.R4GfxYuvImage = .{ .version = 1, .size = @sizeOf(g.R4GfxYuvImage),
                    .format = input.format, .width = input.width, .height = input.height, .plane_count = input.plane_count,
                    .crop = input.crop, .description = input.description, .reserved = 0,
                    .plane0 = cpu[0], .plane1 = cpu[1], .plane2 = cpu[2] };
                var stats: g.R4GfxCpuStats = undefined;
                item.result = self.color.color_yuv_image_transform(&source, &target, &item.transform, &stats);
                item.state = .retiring;
                if (self.retireMaps(item)) item.state = if (item.result == 0) .ready else .failed;
            },
        }
    }
};
