// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const r = @import("r4os");
const a = r.abi;
const Budget = @import("native_allocation").Budget;
pub const Error = error{ Invalid, Unsupported, NoMemory, Busy, Stale, Internal };
const Buffer = struct {
    backing: a.GfxBufferReference = .{},
    descriptor: a.GfxBufferDescriptor = .{},
    mapping: a.GfxBufferMap = .{},
    charged: usize = 0,
};
pub const DevicePlane = struct {
    backing: a.GfxBufferReference,
    descriptor: a.GfxBufferDescriptor,
    offset: u64,
    pitch: u64,
    width: u32,
    height: u32,
};
pub const CpuView = struct {
    planes: [3]?[*]const u8 = @splat(null),
    pitches: [3]u64 = @splat(0),
    width: u32,
    height: u32,
    interleaved: bool,

    // NV12 -> I420 for the software codec only. Native consumers use the
    // retained BOs directly and never call this CPU mapping/conversion path.
    pub fn copyPlanar(self: CpuView, output: [3][]u8) Error!void {
        for (0..3) |p| {
            const width: usize = if (p == 0) self.width else self.width / 2;
            const height: usize = if (p == 0) self.height else self.height / 2;
            if (output[p].len != width * height) return error.Invalid;
        }
        for (0..3) |p| {
            const width: usize = if (p == 0) self.width else self.width / 2;
            const height: usize = if (p == 0) self.height else self.height / 2;
            const index = if (self.interleaved and p != 0) 1 else p;
            const source = self.planes[index] orelse return error.Invalid;
            for (0..height) |y| {
                const row = source[@intCast(y * self.pitches[index])..];
                if (self.interleaved and p != 0) {
                    for (0..width) |x| output[p][y * width + x] = row[x * 2 + p - 1];
                } else @memcpy(output[p][y * width ..][0..width], row[0..width]);
            }
        }
    }
};

// A single encoder worker owns an accepted Input after admission. The public
// slot must also retain failed partial admissions until close succeeds. Such
// failures have not borrowed pixels and are never exposed as accepted frames.
pub fn Input(comptime c: type) type {
    return struct {
        const Self = @This();
        buffers: [3]Buffer = @splat(.{}),
        indices: [3]usize = @splat(0),
        frame: c.R4EncFrame = std.mem.zeroes(c.R4EncFrame),
        budget: ?*Budget = null,
        width: u32 = 0,
        height: u32 = 0,
        admitted: bool = false,

        pub fn empty(self: *const Self) bool {
            for (&self.buffers) |*bo| if (bo.backing.reference.id != 0 or bo.mapping.lease.id != 0 or bo.charged != 0) return false;
            return true;
        }
        /// Retained storage for the native worker. The Input stays alive until
        /// the worker has retired every borrowed VA and engine fence.
        pub fn devicePlane(self: *const Self, index: usize) Error!DevicePlane {
            if (!self.admitted or index >= self.frame.plane_count) return error.Invalid;
            const bo = &self.buffers[self.indices[index]];
            const plane = self.planes()[index];
            return .{ .backing = bo.backing, .descriptor = bo.descriptor, .offset = plane.offset, .pitch = plane.pitch,
                .width = if (index == 0) self.width else self.width / 2,
                .height = if (index == 0) self.height else self.height / 2 };
        }
        fn planes(self: *const Self) [3]c.R4EncPlane {
            return .{ self.frame.plane0, self.frame.plane1, self.frame.plane2 };
        }
        pub fn admit(self: *Self, memory: *const r.gfx_buffers.Context, budget: *Budget, frame: c.R4EncFrame, width: u32, height: u32) Error!void {
            if (self.admitted or !self.empty()) return error.Busy;
            if (frame.version != 1 or frame.size != @sizeOf(c.R4EncFrame) or frame.stream_generation == 0 or
                frame.reserved != 0 or frame.flags & ~c.frame_force_idr != 0 or width < 16 or height < 16 or
                width > 4096 or height > 4096 or (width | height) & 1 != 0) return error.Invalid;
            const count: u32 = switch (frame.format) {
                c.format_nv12 => 2,
                c.format_yuv420p => 3,
                else => return error.Unsupported,
            };
            if (frame.plane_count != count or (count == 2 and !std.mem.allEqual(u8, std.mem.asBytes(&frame.plane2), 0))) return error.Invalid;
            const fence: a.GfxFence = @bitCast(frame.ready);
            if (fence.timeline == 0) {
                if (!std.mem.allEqual(u8, std.mem.asBytes(&fence), 0)) return error.Invalid;
            } else if (fence.point == 0 or fence.device_generation == 0 or fence.reset_generation == 0) return error.Invalid;
            const views = [_]c.R4EncPlane{ frame.plane0, frame.plane1, frame.plane2 };
            // Validate all spans before retaining even the first BO.
            for (views[0..count], 0..) |view, p| {
                const rows = if (p == 0) height else height / 2;
                const row_bytes = if (p == 0 or frame.format == c.format_nv12) width else width / 2;
                if (!valid(@bitCast(view.buffer)) or !valid(@bitCast(view.reference)) or view.reserved != 0 or
                    view.rows != rows or view.row_bytes != row_bytes or view.pitch < row_bytes) return error.Invalid;
                _ = try end(view);
            }
            self.frame = frame;
            self.width = width;
            self.height = height;
            self.budget = budget;
            var used: usize = 0;
            for (views[0..count], 0..) |view, p| {
                const buffer: a.GfxBufferHandle = @bitCast(view.buffer);
                var existing: ?usize = null;
                for (self.buffers[0..used], 0..) |bo, i| {
                    if (std.meta.eql(bo.backing.buffer, buffer)) {
                        existing = i;
                        break;
                    }
                }
                const i = existing orelse used;
                if (existing == null) {
                    const reference: a.GfxBufferHandle = @bitCast(view.reference);
                    var bo = &self.buffers[i];
                    try result(memory.import(&reference, &bo.backing));
                    if (bo.backing.version != 1 or bo.backing.size < @sizeOf(a.GfxBufferReference) or
                        !valid(bo.backing.reference) or !std.meta.eql(bo.backing.buffer, buffer) or
                        bo.backing.flags & ~a.gfx_buffer_reference_immutable != 0 or bo.backing.reserved0 != 0) return error.Internal;
                    try result(memory.describe(&bo.backing.reference, &bo.descriptor));
                    const d = bo.descriptor;
                    if (d.version != 1 or d.size < @sizeOf(a.GfxBufferDescriptor) or d.byte_length == 0 or
                        d.byte_length > std.math.maxInt(usize) or d.reserved0 != 0) return error.Internal;
                    if (!budget.reserve(@intCast(d.byte_length))) return error.NoMemory;
                    bo.charged = @intCast(d.byte_length);
                    used += 1;
                }
                self.indices[p] = i;
                const d = self.buffers[i].descriptor;
                if (try end(view) > d.byte_length) return error.Invalid;
                if (d.format != a.gfx_buffer_format_bytes and d.format != a.gfx_buffer_format_r8 and
                    !(frame.format == c.format_nv12 and d.format == a.gfx_buffer_format_nv12)) return error.Unsupported;
            }
            self.admitted = true;
        }
        // Borrowed producer fence: never cancel/release it. The caller keeps it
        // alive until receive or the explicit abort/close input retirement ACK.
        pub fn ready(self: *const Self, queues: *const r.gfx_queue.Context) Error!void {
            if (!self.admitted) return error.Invalid;
            const fence: a.GfxFence = @bitCast(self.frame.ready);
            if (fence.timeline == 0) return;
            var status: a.GfxFenceStatus = .{};
            const rc = queues.query(&fence, &status);
            if (rc == a.gfx_queue_error_stale or rc == a.gfx_queue_error_device_lost or rc == a.gfx_queue_error_closed) return error.Stale;
            if (rc != a.gfx_queue_ok) return if (rc == a.gfx_queue_error_busy) error.Busy else error.Internal;
            if (status.version != 1 or status.size < @sizeOf(a.GfxFenceStatus) or !std.meta.eql(status.fence, fence) or
                status.phase > a.gfx_queue_phase_terminal or status.flags & ~@as(u32, 3) != 0) return error.Internal;
            if (status.phase != a.gfx_queue_phase_terminal or status.flags != 0) return error.Busy;
            if (status.result != a.gfx_queue_result_complete) return error.Stale;
        }
        pub fn mapCpu(self: *Self, memory: *const r.gfx_buffers.Context, queues: *const r.gfx_queue.Context) Error!CpuView {
            try self.ready(queues);
            for (&self.buffers) |*bo| {
                if (bo.backing.reference.id == 0) continue;
                const d = bo.descriptor;
                if (d.modifier != 0 or d.location != a.gfx_buffer_location_system or d.usage & a.gfx_buffer_usage_cpu_read == 0) return error.Unsupported;
            }
            for (&self.buffers) |*bo| {
                if (bo.backing.reference.id == 0) continue;
                if (bo.mapping.lease.id == 0)
                    try result(memory.map(&bo.backing.reference, a.gfx_buffer_map_read, 0, bo.descriptor.byte_length, &bo.mapping));
                const m = bo.mapping;
                if (m.version != 1 or m.size < @sizeOf(a.GfxBufferMap) or !valid(m.lease) or
                    m.cpu_address == 0 or m.byte_length < bo.descriptor.byte_length or m.reserved0 != 0 or
                    m.cpu_address > std.math.maxInt(usize) - bo.descriptor.byte_length) return error.Internal;
            }
            var view: CpuView = .{ .width = self.width, .height = self.height, .interleaved = self.frame.format == c.format_nv12 };
            const values = self.planes();
            for (values[0..self.frame.plane_count], 0..) |plane, p| {
                view.planes[p] = @ptrFromInt(self.buffers[self.indices[p]].mapping.cpu_address + plane.offset);
                view.pitches[p] = plane.pitch;
            }
            return view;
        }
        // Native consumers must first retire their exact device mappings and
        // engine fence. Failed releases retain ownership for a later worker pass.
        pub fn close(self: *Self, memory: *const r.gfx_buffers.Context) Error!void {
            self.admitted = false;
            var failure: ?Error = null;
            for (&self.buffers) |*bo| {
                if (bo.mapping.lease.id != 0) {
                    result(memory.unmap(&bo.mapping.lease)) catch |err| {
                        failure = err;
                        continue;
                    };
                    bo.mapping = .{};
                }
                if (bo.backing.reference.id != 0) {
                    result(memory.release(&bo.backing.reference)) catch |err| {
                        failure = err;
                        continue;
                    };
                    bo.backing = .{};
                }
                if (bo.charged != 0) (self.budget orelse return error.Internal).release(bo.charged);
                bo.* = .{};
            }
            if (failure) |err| return err;
            self.* = .{};
        }
    };
}
fn end(view: anytype) Error!u64 {
    const span = std.math.mul(u64, view.rows - 1, view.pitch) catch return error.Invalid;
    const bytes = std.math.add(u64, span, view.row_bytes) catch return error.Invalid;
    return std.math.add(u64, view.offset, bytes) catch return error.Invalid;
}
fn valid(handle: a.GfxBufferHandle) bool {
    return handle.id != 0 and handle.generation != 0 and handle.reserved0 == 0;
}
fn result(rc: i32) Error!void {
    return switch (rc) {
        a.gfx_buffer_result_ok => {},
        a.gfx_buffer_error_oom, a.gfx_buffer_error_budget, a.gfx_buffer_error_capacity => error.NoMemory,
        a.gfx_buffer_error_busy => error.Busy,
        a.gfx_buffer_error_stale, a.gfx_buffer_error_closed => error.Stale,
        a.gfx_buffer_error_unsupported => error.Unsupported,
        a.gfx_buffer_error_invalid, a.gfx_buffer_error_overflow => error.Invalid,
        else => error.Internal,
    };
}
