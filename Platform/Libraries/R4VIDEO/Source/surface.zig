// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const r = @import("r4os");
const a = r.abi;
const Budget = @import("native_allocation").Budget;

// One worker owns each Surface. Published VIDEO_V1 loans borrow its references;
// the worker may close/rewrite only after every CPU reader and exact GPU receipt.
// CPU FFmpeg DPB buffers have independent lifetimes, so copy Y/U/V into ordinary
// R8 BOs without RGB conversion. Do not export an active decoder write mapping.
pub const CpuFrame = struct {
    data: [3][*]const u8,
    pitch: [3]u64,
    width: u32,
    height: u32,
};
pub const Error = error{ Invalid, Unsupported, NoMemory, Busy, Stale, Internal };
pub const Plane = struct {
    backing: a.GfxBufferReference = .{},
    mapping: a.GfxBufferMap = .{},
    descriptor: a.GfxBufferDescriptor = .{},
    charged: usize = 0,
    row_bytes: u32 = 0,
    rows: u32 = 0,
};
pub const Surface = struct {
    planes: [3]Plane = @splat(.{}),
    budget: ?*Budget = null,
    ready: bool = false,

    pub fn empty(self: *const Surface) bool {
        for (&self.planes) |*plane| if (plane.charged != 0 or plane.backing.reference.id != 0 or plane.mapping.lease.id != 0) return false;
        return true;
    }

    // The worker calls this only after all consumer uses and the exact receipt
    // have retired. It must still withhold upload until Release acknowledges OK.
    // Cached BOs remain charged to the decoder and keep their original identity.
    pub fn recycle(self: *Surface) Error!void {
        if (!self.ready) return error.Invalid;
        for (&self.planes) |*plane| {
            if (plane.mapping.lease.id != 0 or plane.backing.reference.id == 0 or plane.charged == 0) return error.Busy;
        }
        self.ready = false;
    }

    fn fits(self: *const Surface, budget: *Budget, source: CpuFrame) bool {
        if (self.budget != budget) return false;
        for (&self.planes, 0..) |*plane, index| {
            const rows = if (index == 0) source.height else (source.height + 1) / 2;
            const width = if (index == 0) source.width else (source.width + 1) / 2;
            const pitch = std.mem.alignForward(u64, width, 64);
            const bytes = std.mem.alignForward(u64, pitch * rows, 4096);
            if (plane.mapping.lease.id != 0 or plane.backing.reference.id == 0 or
                plane.backing.buffer.id == 0 or plane.charged != bytes or
                plane.row_bytes != width or plane.rows != rows) return false;
        }
        return true;
    }

    // Failure can leave owned BOs/maps. Keep this Surface and its Budget alive,
    // call close until success, and never publish a partial surface.
    pub fn upload(self: *Surface, memory: *const r.gfx_buffers.Context, budget: *Budget, source: CpuFrame) Error!void {
        if (self.ready) return error.Busy;
        if (source.width == 0 or source.height == 0 or source.width > 4096 or source.height > 4096) return error.Unsupported;
        // Validate the complete CPU view before the first allocation.
        for (0..3) |index| {
            const rows = if (index == 0) source.height else (source.height + 1) / 2;
            const width = if (index == 0) source.width else (source.width + 1) / 2;
            if (source.pitch[index] < width) return error.Invalid;
            const span = std.math.mul(u64, rows - 1, source.pitch[index]) catch return error.Invalid;
            const end = std.math.add(u64, span, width) catch return error.Invalid;
            if (@intFromPtr(source.data[index]) == 0 or end > std.math.maxInt(usize) - @intFromPtr(source.data[index])) return error.Invalid;
        }
        // Extent changes and partial failed uploads cannot reuse the old layout.
        // Close retains exact ownership on failure; no new allocation starts yet.
        const cached = self.fits(budget, source);
        if (!cached and !self.empty()) try self.close(memory);
        self.budget = budget;
        for (&self.planes, 0..) |*plane, index| {
            const rows = if (index == 0) source.height else (source.height + 1) / 2;
            const width = if (index == 0) source.width else (source.width + 1) / 2;
            const pitch = std.mem.alignForward(u64, width, 64);
            const bytes: usize = @intCast(std.mem.alignForward(u64, pitch * rows, 4096));
            if (!cached) {
                if (!budget.reserve(bytes)) return error.NoMemory;
                plane.charged = bytes;
                plane.row_bytes = width;
                plane.rows = rows;
                const requested: a.GfxBufferDescriptor = .{
                    .byte_length = bytes,
                    .width = width,
                    .height = rows,
                    .format = a.gfx_buffer_format_r8,
                    .plane_count = 1,
                    .plane_pitches = .{ pitch, 0, 0, 0 },
                    .usage = a.gfx_buffer_usage_cpu_read | a.gfx_buffer_usage_cpu_write |
                        a.gfx_buffer_usage_transfer_source | a.gfx_buffer_usage_render,
                };
                try result(memory.create(&requested, &plane.backing));
                if (plane.backing.version != 1 or plane.backing.size < @sizeOf(a.GfxBufferReference) or
                    plane.backing.reference.id == 0 or plane.backing.buffer.id == 0 or plane.backing.flags != 0) return error.Internal;
            }
            try result(memory.describe(&plane.backing.reference, &plane.descriptor));
            // The actual descriptor is authoritative. Never infer linear
            // addressing from a pitch or silently accept another allocation.
            const actual = plane.descriptor;
            if (actual.version != 1 or actual.size < @sizeOf(a.GfxBufferDescriptor) or
                actual.byte_length != bytes or actual.location != a.gfx_buffer_location_system or actual.modifier != 0 or
                actual.width != width or actual.height != rows or actual.format != a.gfx_buffer_format_r8 or
                actual.plane_count != 1 or actual.plane_offsets[0] != 0 or actual.plane_pitches[0] != pitch) return error.Unsupported;
            try result(memory.map(&plane.backing.reference, a.gfx_buffer_map_write, 0, bytes, &plane.mapping));
            const mapped = plane.mapping;
            if (mapped.version != 1 or mapped.size < @sizeOf(a.GfxBufferMap) or mapped.lease.id == 0 or
                mapped.cpu_address == 0 or mapped.byte_length < bytes or mapped.cpu_address > std.math.maxInt(usize) - bytes) return error.Internal;
            const pixels: [*]u8 = @ptrFromInt(mapped.cpu_address);
            // Initialize padding without writing every active pixel twice.
            // This also restores padding on recycled allocations.
            for (0..rows) |y| {
                const from: usize = @intCast(y * source.pitch[index]);
                const to: usize = @intCast(y * pitch);
                @memcpy(pixels[to..][0..width], source.data[index][from..][0..width]);
                @memset(pixels[to + width .. to + @as(usize, @intCast(pitch))], 0);
            }
            @memset(pixels[@intCast(pitch * rows)..bytes], 0);
            try result(memory.unmap(&plane.mapping.lease));
            plane.mapping = .{};
        }
        self.ready = true;
    }

    // Idempotent even after a partially failed upload. An unsuccessful unmap
    // or release retains its exact identity and charge for the next worker pass.
    pub fn close(self: *Surface, memory: *const r.gfx_buffers.Context) Error!void {
        self.ready = false;
        var failure: ?Error = null;
        for (&self.planes) |*plane| {
            if (plane.mapping.lease.id != 0) {
                result(memory.unmap(&plane.mapping.lease)) catch |err| {
                    failure = err;
                    continue;
                };
                plane.mapping = .{};
            }
            if (plane.backing.reference.id != 0) {
                result(memory.release(&plane.backing.reference)) catch |err| {
                    failure = err;
                    continue;
                };
                plane.backing = .{};
            }
            if (plane.charged != 0) {
                (self.budget orelse return error.Internal).release(plane.charged);
            }
            plane.* = .{};
        }
        if (failure) |err| return err;
        self.budget = null;
    }
};
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
