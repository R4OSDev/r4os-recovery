// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Single-worker GR preparer. Retained YUV BOs are sampled directly, including
//! block-linear storage; only commands/constants/shaders are mapped by the CPU.
//! The native NV12 output has its own NVENC VA and an authenticated modifier.
const std = @import("std");
const r = @import("r4os");
const a = r.abi;
const gpu = @import("gpu_resources");
const render = @import("r4nv_render");
const encoder = @import("gpu_encoder");
const input_owner = @import("encode_input");
pub const Error = gpu.Error || render.Error || input_owner.Error;
const Image = render.image.Image;
const Work = enum { shaders, packet, commands };

// Stable address, owned by the same worker as Session. Close this preparer
// before releasing the Session or an Input that has been passed to prepare.
pub const Preparer = struct {
    ctx: gpu.Context,
    target: gpu.Resource = .{}, // NVENC owner and VA.
    destination: gpu.Resource = .{}, // GR alias of the target, no second BO.
    sources: [3]gpu.Resource = @splat(.{}),
    work: [3]gpu.Resource = @splat(.{}),
    session: ?*encoder.Session = null,
    ready: bool = false,
    failed: bool = false,
    closing: bool = false,

    fn resource(self: *Preparer, which: Work) *gpu.Resource { return &self.work[@intFromEnum(which)]; }
    pub fn open(self: *Preparer, session: *encoder.Session) Error!void {
        if (self.session != null or self.closing or self.ctx.poisoned) return error.Busy;
        if (!session.ready or session.failed or self.ctx.device.engine != .graphics or
            !std.meta.eql(self.ctx.device.binding, session.ctx.device.binding) or
            self.ctx.device.memory_generation != session.ctx.device.memory_generation or
            self.ctx.budget != session.ctx.budget) return error.Invalid;
        const shader_bytes = try render.shaderBytesFor(self.ctx.device.class);
        self.session = session;
        errdefer self.failed = true;
        try self.target.nv12(&session.ctx, std.mem.alignForward(u32, session.sequence.width, 16), session.storage.rows);
        try self.destination.borrow(&self.ctx, self.target.backing);
        try self.resource(.shaders).system(&self.ctx, shader_bytes);
        try self.resource(.packet).system(&self.ctx, render.packet_capacity_bytes);
        try self.resource(.commands).system(&self.ctx, render.max_words * 4);
        try render.shaderUploadFor(self.ctx.device.class, (try self.resource(.shaders).mappedBytes())[0..shader_bytes]);
        self.ready = true;
    }
    pub fn retireInput(self: *Preparer) Error!void {
        if (self.ctx.fence.timeline != 0) return error.Busy;
        var failure: ?Error = null;
        for (&self.sources) |*source| source.close() catch |err| { failure = err; };
        if (failure) |err| return err;
    }
    fn retireInputUntil(self: *Preparer, until: u64) Error!void {
        if (self.ctx.fence.timeline != 0) return error.Busy;
        var failure: ?Error = null;
        // GR completion starts a separate VA retirement. The codec worker
        // awaits each exact unmap acknowledgement before advancing the job;
        // pending retirement must neither poison the session nor resubmit GR.
        for (&self.sources) |*source| source.closeUntil(until) catch |err| { failure = err; };
        if (failure) |err| return err;
    }
    pub fn prepare(self: *Preparer, input: anytype) Error!*const gpu.Resource {
        if (!self.ready or self.failed or self.closing or self.ctx.poisoned) return error.Stale;
        const session = self.session.?;
        if (!session.ready or session.failed or session.ctx.fence.timeline != 0) return error.Busy;
        if (input.width != session.sequence.width or input.height != session.sequence.height) return error.Invalid;
        const queues: r.gfx_queue.Context = .{ .base = self.ctx.base };
        try input.ready(&queues); // Borrowed producer fence is never consumed.
        try self.retireInputUntil(try self.ctx.deadline());
        const count: usize = input.frame.plane_count;
        if (count != 2 and count != 3) return error.Unsupported;
        var images: [3]Image = undefined;
        var used: usize = 0;
        errdefer self.failed = true; // Every partial mapping stays reachable.
        for (0..count) |p| {
            const view = try input.devicePlane(p);
            // Different VAs may still name the same BO. Reject aliases of our
            // writable destination/control storage by canonical BO identity.
            if (std.meta.eql(view.backing.buffer, self.target.backing.buffer)) return error.Invalid;
            for (&self.work) |*bo| if (std.meta.eql(view.backing.buffer, bo.backing.buffer)) return error.Invalid;
            var found: ?usize = null;
            for (self.sources[0..used], 0..) |source, i| {
                if (std.meta.eql(source.backing.buffer, view.backing.buffer)) { found = i; break; }
            }
            const i = found orelse used;
            if (found == null) {
                try self.sources[i].borrow(&self.ctx, view.backing);
                used += 1;
            }
            images[p] = try planeImage(view, &self.sources[i], count, p);
        }
        const target_desc = self.target.descriptor;
        for (0..2) |p| {
            const offset = target_desc.plane_offsets[p];
            const end = if (p == 0) target_desc.plane_offsets[1] else target_desc.byte_length;
            const pitch: u32 = @intCast(target_desc.plane_pitches[p]);
            const target: Image = .{ .address = self.destination.address + offset, .bytes = end - offset,
                .width = pitch, .height = target_desc.height >> @as(u5, @intCast(p)), .pitch = pitch,
                .format = .r8, .layout = .blocklinear, .log2_gobs = @intCast(target_desc.modifier & 15) };
            const draw: render.Draw = .{ .source = images[0], .target = target,
                .source_rect = .{ .x = 0, .y = 0, .width = input.width, .height = input.height },
                .destination = .{ .x = 0, .y = 0, .width = target.width, .height = target.height },
                .scissor = .{ .x = 0, .y = 0, .width = target.width, .height = target.height },
                .encode_input = .{ .format = if (count == 2) .nv12 else .yuv420p, .chroma = images[1],
                    .second = if (count == 3) images[2] else null, .plane = if (p == 0) .luma else .chroma,
                    .extent = .{ input.width, input.height } } };
            var cursor: u64 = 0;
            while (true) {
                // Up to16 bounded draws share one command submission/fence,
                // avoiding a CPU/GPU round trip for every64KB raster slice.
                var draws: [render.batch_capacity]render.Draw = undefined;
                var count_draws: usize = 0;
                var done = false;
                while (count_draws < draws.len) {
                    const part = try render.slice(draw, cursor, 65536);
                    draws[count_draws] = part.draw;
                    count_draws += 1;
                    cursor = part.next;
                    done = cursor == part.total;
                    if (done) break;
                }
                try self.emit(draws[0..count_draws], self.sources[0..used]);
                if (done) break;
            }
        }
        try self.retireInputUntil(try self.ctx.deadline());
        return &self.target;
    }
    fn emit(self: *Preparer, draws: []const render.Draw, sources: []const gpu.Resource) Error!void {
        const shaders = self.resource(.shaders);
        const packet = self.resource(.packet);
        const commands = self.resource(.commands);
        try render.packetUploadList(draws, (try packet.mappedBytes())[0 .. draws.len * render.packet_bytes]);
        var program: render.Program = .{};
        try render.encode(.{ .class = self.ctx.device.class, .draw = draws[0], .additional = draws[1..],
            .programs = .{ .address = shaders.address, .bytes = shaders.descriptor.byte_length },
            .packet = .{ .address = packet.address, .bytes = packet.descriptor.byte_length } }, &program);
        const bytes = std.mem.sliceAsBytes(program.slice());
        @memcpy((try commands.mappedBytes())[0..bytes.len], bytes);
        var loans: [6]gpu.Context.Loan = undefined;
        loans[0..3].* = .{ .{ .resource = shaders, .write = false }, .{ .resource = packet, .write = false },
            .{ .resource = &self.destination, .write = true } };
        for (sources, 0..) |*source, i| loans[3 + i] = .{ .resource = source, .write = false };
        try self.ctx.submit(commands, @intCast(bytes.len), loans[0 .. 3 + sources.len]);
    }
    pub fn close(self: *Preparer) Error!void {
        self.closing = true;
        self.ready = false;
        try self.ctx.close();
        try self.retireInput();
        try self.destination.close();
        // Its NVENC owner may still have a fence: target.close retains the BO
        // until the broker confirms physical retirement of that separate loan.
        try self.target.close();
        var failure: ?Error = null;
        for (&self.work) |*bo| bo.close() catch |err| { failure = err; };
        if (failure) |err| return err;
    }
};

fn planeImage(view: input_owner.DevicePlane, source: *const gpu.Resource, count: usize, index: usize) Error!Image {
    const d = source.descriptor;
    if (!std.meta.eql(view.descriptor, d) or view.offset >= d.byte_length or view.pitch > std.math.maxInt(u32)) return error.Stale;
    const pair = count == 2 and index == 1;
    var width = view.width;
    var height = view.height;
    var limit = d.byte_length;
    if (d.format == a.gfx_buffer_format_nv12) {
        if (count != 2 or d.plane_count != 2 or (d.width | d.height) & 1 != 0 or
            view.offset != d.plane_offsets[index] or view.pitch != d.plane_pitches[index]) return error.Unsupported;
        width = if (index == 0) d.width else d.width / 2;
        height = if (index == 0) d.height else d.height / 2;
        if (index == 0) limit = @min(limit, d.plane_offsets[1]);
    } else if (d.format == a.gfx_buffer_format_r8) {
        if (d.plane_count != 1 or view.offset != d.plane_offsets[0] or view.pitch != d.plane_pitches[0] or
            (pair and d.width & 1 != 0)) return error.Unsupported;
        width = if (pair) d.width / 2 else d.width;
        height = d.height;
    } else if (d.format != a.gfx_buffer_format_bytes or d.modifier != 0 or d.plane_count != 0) return error.Unsupported;
    if (width < view.width or height < view.height or limit <= view.offset) return error.Invalid;
    const image: Image = .{ .address = source.address + view.offset, .bytes = limit - view.offset,
        .width = width, .height = height, .pitch = @intCast(view.pitch), .format = if (pair) .rg8 else .r8,
        .layout = if (d.modifier == 0) .linear else .blocklinear, .log2_gobs = @intCast(d.modifier & 15) };
    try image.validate();
    return image;
}
