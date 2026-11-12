//! Explicit interadapter image transfer through one shared system-memory BO.
//! Each device imports its own reference and uses its own queue/address space.
//! Only a retired source receipt admits the destination upload; no GPU address
//! or uncompleted fence crosses adapters. Caller keeps source pixels stable
//! while sourceHeld() is true and owns both device contexts until close().
const std = @import("std");
const r4os = @import("r4os");
const a = r4os.abi;
const gfx = @import("r4gfx");
const empty = std.mem.zeroes(gfx.R4GfxResource);
pub const max_bytes = 64 * 1024 * 1024;
pub const Error = error{ Busy, Invalid, Unsupported, Limit, Stale, Graphics, Deadline };
pub const Phase = enum { empty, idle, download, upload, draining, ready, failed };
const Job = struct { handle: gfx.R4GfxJob, fence: gfx.R4GfxCopyFence = std.mem.zeroes(gfx.R4GfxCopyFence) };
pub const Owner = struct {
    client: *const gfx.DeviceV1Client,
    colors: *const gfx.ColorV1Client,
    from: *const gfx.R4GfxDevice,
    to: *const gfx.R4GfxDevice,
    memory: r4os.gfx_buffers.Context,
    phase: Phase = .empty,
    failure: ?Error = null,
    reference: a.GfxBufferReference = .{},
    imports: [2]gfx.R4GfxResource = @splat(empty),
    source: gfx.R4GfxResource = empty,
    target: gfx.R4GfxResource = empty,
    description: gfx.R4GfxColorDescription = undefined,
    width: u32 = 0, height: u32 = 0, format: u32 = 0,
    target_pitch: u64 = 0,
    deadline_ns: u64 = 0, last_ns: u64 = 0,
    job: ?Job = null,
    uploading: bool = false,
    completed_bytes: u64 = 0,

    pub fn init(client: *const gfx.DeviceV1Client, colors: *const gfx.ColorV1Client,
        from: *const gfx.R4GfxDevice, to: *const gfx.R4GfxDevice, memory: r4os.gfx_buffers.Context) Owner
    { return .{ .client = client, .colors = colors, .from = from, .to = to, .memory = memory }; }

    pub fn prepare(self: *Owner, width: u32, height: u32, format: u32, description: gfx.R4GfxColorDescription) Error!void {
        if (self.phase != .empty and self.phase != .idle) return error.Busy;
        if (width == 0 or height == 0 or @as(u64, width) * height > max_bytes / 4) return error.Limit;
        if (format != gfx.format_xrgb8888 and format != gfx.format_xrgb2101010) return error.Unsupported;
        try accepted(self.colors.color_description_validate(&description));
        try self.close();
        errdefer self.close() catch {}; // Failed close keeps every remaining handle.
        if (self.memory.create(&.{ .byte_length = @as(u64, width) * height * 4,
            .width = width, .height = height, .format = format, .plane_count = 1,
            .plane_pitches = .{ @as(u64, width) * 4, 0, 0, 0 },
            .usage = a.gfx_buffer_usage_cpu_read | a.gfx_buffer_usage_cpu_write |
                a.gfx_buffer_usage_transfer_source | a.gfx_buffer_usage_transfer_target }, &self.reference) != a.gfx_buffer_result_ok) return error.Graphics;
        var desc = std.mem.zeroes(gfx.R4GfxResourceDesc);
        desc.version = 1; desc.size = @sizeOf(gfx.R4GfxResourceDesc);
        desc.kind = gfx.resource_image; desc.source_kind = gfx.source_import_buffer;
        desc.source_address = @intFromPtr(&self.reference.reference);
        for ([_]*const gfx.R4GfxDevice{ self.from, self.to }, 0..) |device, index| {
            desc.flags = if (index == 0) gfx.image_target else 0;
            try accepted(self.colors.color_resource_create(device, &.{ .version = 1, .size = @sizeOf(gfx.R4GfxColorResourceDesc),
                .resource = desc, .description = description }, &self.imports[index]));
        }
        self.width = width; self.height = height; self.format = format;
        self.description = description; self.phase = .idle;
    }
    pub fn sourceHeld(self: *const Owner) bool { return self.source.slot != 0; }
    pub fn pending(self: *const Owner) bool { return self.phase == .download or self.phase == .upload or self.phase == .draining; }
    pub fn begin(self: *Owner, source: gfx.R4GfxResource, target: gfx.R4GfxResource,
        dependencies: []const gfx.R4GfxCopyFence, now_ns: u64, deadline_ns: u64) Error!void
    {
        if (self.phase != .idle) return error.Busy;
        if (now_ns == 0 or deadline_ns <= now_ns or deadline_ns == ~@as(u64, 0) or dependencies.len > gfx.copy_max_dependencies) return error.Invalid;
        var infos: [2]gfx.R4GfxResourceInfo = undefined;
        for ([_]*const gfx.R4GfxDevice{ self.from, self.to }, [_]gfx.R4GfxResource{ source, target }, 0..) |device, resource, index| {
            const info = &infos[index];
            try accepted(self.client.resource_info(device, &resource, info));
            if (info.flags & gfx.resource_invalidated != 0) return error.Stale;
            if (info.image.width != self.width or info.image.height != self.height or info.image.format != self.format or
                info.image.pitch < @as(u64, self.width) * 4 or (index == 1 and info.flags & gfx.image_target == 0)) return error.Invalid;
            var color: gfx.R4GfxColorDescription = undefined;
            try accepted(self.colors.color_resource_info(device, &resource, &color));
            if (!std.meta.eql(color, self.description)) return error.Invalid;
            var staging: gfx.R4GfxResourceInfo = undefined;
            try accepted(self.client.resource_info(device, &self.imports[index], &staging));
            if (info.buffer_id != 0 and info.buffer_id == staging.buffer_id and info.buffer_generation == staging.buffer_generation) return error.Invalid;
        }
        if (infos[0].buffer_id != 0 and infos[0].buffer_id == infos[1].buffer_id and infos[0].buffer_generation == infos[1].buffer_generation) return error.Invalid;
        try accepted(self.client.resource_retain(self.from, &source));
        self.source = source; self.phase = .download; self.failure = null; self.uploading = false;
        self.completed_bytes = 0; self.last_ns = now_ns; self.deadline_ns = deadline_ns; self.target_pitch = infos[1].image.pitch;
        errdefer self.cancel(error.Graphics);
        try accepted(self.client.resource_retain(self.to, &target));
        self.target = target;
        try self.submit(source, self.imports[0], infos[0].image.pitch, @as(u64, self.width) * 4, dependencies);
    }
    fn submit(self: *Owner, source: gfx.R4GfxResource, target: gfx.R4GfxResource,
        source_pitch: u64, target_pitch: u64, dependencies: []const gfx.R4GfxCopyFence) Error!void
    {
        const device = if (self.uploading) self.to else self.from;
        var handle: gfx.R4GfxJob = undefined;
        try accepted(self.client.copy_submit_ex(device, &.{ .version = 1, .size = @sizeOf(gfx.R4GfxCopyRequestEx),
            .copy = .{ .source = source, .target = target, .source_offset = 0, .target_offset = 0,
                .byte_length = @as(u64, self.width) * 4, .deadline_ns = self.deadline_ns },
            .row_count = self.height, .source_pitch = source_pitch, .target_pitch = target_pitch,
            .dependency_count = @intCast(dependencies.len),
            .dependencies = if (dependencies.len == 0) 0 else @intFromPtr(dependencies.ptr) }, &handle));
        self.job = .{ .handle = handle };
        try accepted(self.client.job_fence(device, &handle, &self.job.?.fence));
    }
    pub fn cancel(self: *Owner, reason: Error) void {
        if (!self.pending()) return;
        if (self.failure == null) self.failure = reason;
        self.phase = .draining;
        if (self.job) |job| _ = self.client.job_cancel(if (self.uploading) self.to else self.from, &job.handle);
    }
    pub fn poll(self: *Owner, now_ns: u64) void {
        if (!self.pending()) return;
        if (now_ns < self.last_ns) self.cancel(error.Invalid);
        self.last_ns = now_ns;
        if (self.failure == null and now_ns >= self.deadline_ns) self.cancel(error.Deadline);
        if (self.job) |job| {
            const device = if (self.uploading) self.to else self.from;
            var info: gfx.R4GfxJobInfo = undefined;
            const rc = self.client.job_info(device, &job.handle, &info);
            if (rc != gfx.status_ok) { self.cancel(if (rc == gfx.status_stale or rc == gfx.status_lost) error.Stale else error.Graphics); return; }
            if (job.fence.timeline != 0 and (info.timeline != job.fence.timeline or info.point != job.fence.point or
                info.device_generation != job.fence.device_generation or info.reset_generation != job.fence.reset_generation)) { self.cancel(error.Stale); return; }
            if (info.phase != a.gfx_queue_phase_terminal or info.flags & (a.gfx_queue_flag_device_active | a.gfx_queue_flag_resources_held) != 0) return;
            if (info.result != a.gfx_queue_result_complete) self.cancel(error.Graphics);
            if (self.client.job_release(device, &job.handle) != gfx.status_ok) return;
            self.job = null;
        }
        if (self.source.slot != 0) {
            if (self.client.resource_release(self.from, &self.source) != gfx.status_ok) return;
            self.source = empty;
        }
        if (self.failure == null and !self.uploading) {
            self.phase = .upload; self.uploading = true;
            self.submit(self.imports[1], self.target, @as(u64, self.width) * 4, self.target_pitch, &.{}) catch { self.cancel(error.Graphics); };
            return;
        }
        if (self.target.slot != 0) {
            if (self.client.resource_release(self.to, &self.target) != gfx.status_ok) return;
            self.target = empty;
        }
        self.phase = if (self.failure == null) .ready else .failed;
        if (self.phase == .ready) self.completed_bytes = @as(u64, self.width) * self.height * 4;
    }
    pub fn acknowledge(self: *Owner) Error!void {
        if (self.phase != .ready and self.phase != .failed) return error.Busy;
        self.phase = .idle; self.failure = null;
    }
    pub fn close(self: *Owner) Error!void {
        if (self.pending() or self.job != null or self.source.slot != 0 or self.target.slot != 0) return error.Busy;
        for ([_]usize{ 1, 0 }) |index| if (self.imports[index].slot != 0) {
            try accepted(self.client.resource_release(if (index == 0) self.from else self.to, &self.imports[index]));
            self.imports[index] = empty;
        };
        if (self.reference.reference.id != 0) {
            if (self.memory.release(&self.reference.reference) != a.gfx_buffer_result_ok) return error.Busy;
            self.reference = .{};
        }
        self.phase = .empty; self.failure = null;
        self.width = 0; self.height = 0; self.format = 0;
    }
};
fn accepted(status: i32) Error!void {
    return switch (status) { gfx.status_ok => {}, gfx.status_busy => error.Busy,
        gfx.status_stale, gfx.status_suboptimal, gfx.status_lost => error.Stale,
        gfx.status_unsupported, gfx.status_unavailable => error.Unsupported, gfx.status_limit => error.Limit, else => error.Graphics };
}
