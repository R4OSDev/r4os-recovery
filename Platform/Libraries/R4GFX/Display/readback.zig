//! Caller-owned asynchronous capture through ordinary DEVICE_V1 copy jobs.
//! One reusable staging image and one SDR shadow bound memory independently
//! of readers. The display owner keeps the source frame from being rewritten
//! until sourceHeld() becomes false; publication never lends GPU storage.
const std = @import("std");
const a = @import("r4os").abi;
const gfx = @import("r4gfx");
const empty_resource = std.mem.zeroes(gfx.R4GfxResource);
pub const max_regions = 8;
pub const max_image_bytes = 64 * 1024 * 1024;
pub const conversion_pixels = 64 * 1024;
pub const Error = error{ Busy, Invalid, Unsupported, Limit, Stale, Graphics, Deadline };
pub const Phase = enum { empty, idle, copying, converting, ready, draining, failed };
pub const Stats = struct {
    frames: u64 = 0, failed: u64 = 0, copy_bytes: u64 = 0,
    cpu_read_bytes: u64 = 0, cpu_write_bytes: u64 = 0,
    last_latency_ns: u64 = 0, max_latency_ns: u64 = 0,
};
pub const Request = struct {
    source: gfx.R4GfxResource,
    epoch: u64,
    frame: u64,
    // Zero requests a complete image. A nonzero value asserts that regions
    // include every change since this previously acknowledged capture.
    base_frame: u64 = 0,
    regions: []const gfx.R4GfxRect,
    dependencies: []const gfx.R4GfxCopyFence = &.{},
    now_ns: u64,
    deadline_ns: u64,
};
const Job = struct { handle: gfx.R4GfxJob, fence: gfx.R4GfxCopyFence, bytes: u64, counted: bool = false };
pub const Owner = struct {
    allocator: std.mem.Allocator,
    client: *const gfx.DeviceV1Client,
    colors: *const gfx.ColorV1Client,
    device: *const gfx.R4GfxDevice,
    phase: Phase = .empty,
    failure: ?Error = null,
    staging: gfx.R4GfxResource = empty_resource,
    target: gfx.R4GfxResource = empty_resource,
    source: gfx.R4GfxResource = empty_resource,
    pixels: []u32 = &.{},
    width: u32 = 0,
    height: u32 = 0,
    format: u32 = 0,
    description: gfx.R4GfxColorDescription = sdr(),
    jobs: [max_regions]?Job = @splat(null),
    regions: [max_regions]gfx.R4GfxRect = undefined,
    region_count: usize = 0,
    convert_index: usize = 0,
    convert_row: u32 = 0,
    epoch: u64 = 0,
    frame: u64 = 0,
    acknowledged: u64 = 0,
    valid: bool = false,
    started_ns: u64 = 0,
    deadline_ns: u64 = 0,
    completed_ns: u64 = 0,
    stats: Stats = .{},

    pub fn init(allocator: std.mem.Allocator, client: *const gfx.DeviceV1Client,
        colors: *const gfx.ColorV1Client, device: *const gfx.R4GfxDevice) Owner
    { return .{ .allocator = allocator, .client = client, .colors = colors, .device = device }; }

    pub fn matches(self: *const Owner, width: u32, height: u32, format: u32, description: gfx.R4GfxColorDescription) bool {
        return self.staging.slot != 0 and self.target.slot != 0 and self.width == width and self.height == height and
            self.format == format and std.meta.eql(self.description, description);
    }
    /// Allocation belongs on the display's existing preparation worker.
    /// No polling, network operation or GPU wait is performed here.
    pub fn prepare(self: *Owner, width: u32, height: u32, format: u32, description: gfx.R4GfxColorDescription) Error!void {
        if (self.phase != .empty and self.phase != .idle) return error.Busy;
        if (width == 0 or height == 0 or width > conversion_pixels or
            @as(u64, width) * height > max_image_bytes / 4) return error.Limit;
        if (format != gfx.format_xrgb8888 and format != gfx.format_xrgb2101010) return error.Unsupported;
        try accepted(self.colors.color_description_validate(&description));
        if (self.matches(width, height, format, description)) return;
        try self.close();
        const count: usize = @intCast(@as(u64, width) * height);
        self.pixels = self.allocator.alloc(u32, count) catch return error.Limit;
        @memset(self.pixels, 0);
        self.width = width; self.height = height; self.format = format; self.description = description;
        errdefer self.close() catch {};
        var desc = std.mem.zeroes(gfx.R4GfxResourceDesc);
        desc.version = 1; desc.size = @sizeOf(gfx.R4GfxResourceDesc);
        desc.kind = gfx.resource_image; desc.flags = gfx.image_target;
        desc.source_kind = gfx.source_create_system;
        desc.image = .{ .cpu_address = 0, .byte_length = count * 4, .pitch = @as(u64, width) * 4,
            .width = width, .height = height, .format = format, .reserved = 0 };
        try accepted(self.colors.color_resource_create(self.device, &.{ .version = 1, .size = @sizeOf(gfx.R4GfxColorResourceDesc),
            .resource = desc, .description = description }, &self.staging));
        desc.source_kind = gfx.source_borrow_cpu; desc.source_generation = 1;
        desc.image.cpu_address = @intFromPtr(self.pixels.ptr); desc.image.format = gfx.format_xrgb8888;
        try accepted(self.colors.color_resource_create(self.device, &.{ .version = 1, .size = @sizeOf(gfx.R4GfxColorResourceDesc),
            .resource = desc, .description = sdr() }, &self.target));
        self.phase = .idle;
    }
    pub fn sourceHeld(self: *const Owner) bool { return self.source.slot != 0; }
    pub fn pending(self: *const Owner) bool { return self.phase == .copying or self.phase == .converting or self.phase == .draining; }
    pub fn begin(self: *Owner, request: Request) Error!void {
        if (self.phase != .idle) return error.Busy;
        if (request.epoch == 0 or request.frame == 0 or request.now_ns == 0 or request.deadline_ns <= request.now_ns or
            request.deadline_ns == std.math.maxInt(u64) or request.regions.len == 0 or request.regions.len > max_regions or
            request.dependencies.len > gfx.copy_max_dependencies) return error.Invalid;
        for (request.regions) |rect| {
            if (rect.width == 0 or rect.height == 0 or rect.x >= self.width or rect.y >= self.height or
                rect.width > self.width - rect.x or rect.height > self.height - rect.y) return error.Invalid;
        }
        if (request.epoch == self.epoch and request.frame <= self.acknowledged) return error.Stale;
        var source_info: gfx.R4GfxResourceInfo = undefined;
        try accepted(self.client.resource_info(self.device, &request.source, &source_info));
        if (source_info.flags & gfx.resource_invalidated != 0) return error.Stale;
        if (source_info.image.width != self.width or source_info.image.height != self.height or source_info.image.format != self.format or
            source_info.image.pitch < @as(u64, self.width) * 4) return error.Invalid;
        var stage_info: gfx.R4GfxResourceInfo = undefined;
        try accepted(self.client.resource_info(self.device, &self.staging, &stage_info));
        try accepted(self.client.resource_retain(self.device, &request.source));
        self.source = request.source;
        self.phase = .copying; self.failure = null;
        self.frame = request.frame; self.started_ns = request.now_ns; self.deadline_ns = request.deadline_ns; self.completed_ns = 0;
        self.convert_index = 0; self.convert_row = 0;
        if (!self.valid or self.epoch != request.epoch or request.base_frame == 0 or request.base_frame != self.acknowledged) {
            self.regions[0] = .{ .x = 0, .y = 0, .width = self.width, .height = self.height }; self.region_count = 1;
        } else {
            @memcpy(self.regions[0..request.regions.len], request.regions); self.region_count = request.regions.len;
        }
        self.epoch = request.epoch;
        errdefer self.cancel(error.Graphics);
        for (self.regions[0..self.region_count], 0..) |rect, i| {
            var handle: gfx.R4GfxJob = undefined;
            try accepted(self.client.copy_submit_ex(self.device, &.{ .version = 1, .size = @sizeOf(gfx.R4GfxCopyRequestEx),
                .copy = .{ .source = self.source, .target = self.staging,
                    .source_offset = @as(u64, rect.y) * source_info.image.pitch + @as(u64, rect.x) * 4,
                    .target_offset = @as(u64, rect.y) * stage_info.image.pitch + @as(u64, rect.x) * 4,
                    .byte_length = @as(u64, rect.width) * 4, .deadline_ns = request.deadline_ns },
                .row_count = rect.height, .source_pitch = source_info.image.pitch, .target_pitch = stage_info.image.pitch,
                .dependency_count = @intCast(request.dependencies.len),
                .dependencies = if (request.dependencies.len == 0) 0 else @intFromPtr(request.dependencies.ptr) }, &handle));
            // Record ownership before any further fallible operation.
            self.jobs[i] = .{ .handle = handle, .fence = std.mem.zeroes(gfx.R4GfxCopyFence), .bytes = @as(u64, rect.width) * rect.height * 4 };
            try accepted(self.client.job_fence(self.device, &handle, &self.jobs[i].?.fence));
        }
    }
    pub fn cancel(self: *Owner, reason: Error) void {
        if (self.phase == .empty or self.phase == .idle or self.phase == .failed) return;
        if (self.failure == null) { self.failure = reason; self.stats.failed +|= 1; }
        self.valid = false;
        self.phase = .draining;
        for (&self.jobs) |*entry| if (entry.*) |job| { _ = self.client.job_cancel(self.device, &job.handle); };
    }
    /// A bounded amount of work. Deadlines cancel admission, never authorize
    /// freeing memory that an unconfirmed GPU operation can still access.
    pub fn poll(self: *Owner, now: u64) void {
        if (!self.pending()) return;
        if (self.failure == null and now >= self.deadline_ns) self.cancel(error.Deadline);
        if (self.phase == .copying or self.phase == .draining) {
            var retained = false;
            for (&self.jobs) |*entry| if (entry.*) |*job| {
                var info: gfx.R4GfxJobInfo = undefined;
                const rc = self.client.job_info(self.device, &job.handle, &info);
                if (rc != gfx.status_ok) { self.cancel(if (rc == gfx.status_stale or rc == gfx.status_lost) error.Stale else error.Graphics); retained = true; continue; }
                if (job.fence.timeline != 0 and (info.timeline != job.fence.timeline or info.point != job.fence.point or
                    info.device_generation != job.fence.device_generation or info.reset_generation != job.fence.reset_generation)) {
                    self.cancel(error.Stale); retained = true; continue;
                }
                if (info.phase != a.gfx_queue_phase_terminal or info.flags & (a.gfx_queue_flag_device_active | a.gfx_queue_flag_resources_held) != 0) {
                    retained = true; continue;
                }
                if (info.result != a.gfx_queue_result_complete) self.cancel(error.Graphics);
                if (!job.counted and info.result == a.gfx_queue_result_complete) { self.stats.copy_bytes +|= job.bytes; job.counted = true; }
                if (self.client.job_release(self.device, &job.handle) != gfx.status_ok) { retained = true; continue; }
                entry.* = null;
            };
            if (retained) return;
            if (self.source.slot != 0) {
                if (self.client.resource_release(self.device, &self.source) != gfx.status_ok) return;
                self.source = empty_resource;
            }
            if (self.failure != null) { self.phase = .failed; return; }
            self.phase = .converting;
        }
        if (self.phase != .converting) return;
        const region = self.regions[self.convert_index];
        const rows = @min(region.height - self.convert_row, @max(1, conversion_pixels / region.width));
        const rect: gfx.R4GfxRect = .{ .x = region.x, .y = region.y + self.convert_row, .width = region.width, .height = rows };
        var stats: gfx.R4GfxCpuStats = undefined;
        const rc = self.colors.color_resource_transform(self.device, &self.staging, &self.target, &.{ .version = 1, .size = @sizeOf(gfx.R4GfxColorTransform),
            .source_rect = rect, .target_rect = rect, .sampler = gfx.render_sampler_nearest, .operation = gfx.render_operation_blit,
            .opacity = 65535, .flags = if (std.meta.eql(self.description, sdr())) 0 else
                gfx.color_transform_output | gfx.color_transform_relative_white | gfx.color_transform_dither,
            .pixel_budget = @as(u64, rect.width) * rect.height }, &stats);
        if (rc == gfx.status_busy) return;
        if (rc != gfx.status_ok) { self.cancel(error.Graphics); return; }
        self.stats.cpu_read_bytes +|= stats.read_bytes; self.stats.cpu_write_bytes +|= stats.write_bytes;
        self.convert_row += rows;
        if (self.convert_row == region.height) { self.convert_row = 0; self.convert_index += 1; }
        if (self.convert_index == self.region_count) {
            self.completed_ns = now; self.phase = .ready;
            self.stats.frames +|= 1; self.stats.last_latency_ns = now -| self.started_ns;
            self.stats.max_latency_ns = @max(self.stats.max_latency_ns, self.stats.last_latency_ns);
        }
    }
    pub fn acknowledge(self: *Owner, published: bool) Error!void {
        if (self.phase != .ready and self.phase != .failed) return error.Busy;
        self.valid = self.phase == .ready and published;
        if (self.valid) self.acknowledged = self.frame;
        self.phase = .idle; self.failure = null;
    }
    pub fn close(self: *Owner) Error!void {
        if (self.sourceHeld() or self.pending()) return error.Busy;
        for (self.jobs) |job| if (job != null) return error.Busy;
        for ([_]*gfx.R4GfxResource{ &self.target, &self.staging }) |handle| if (handle.slot != 0) {
            try accepted(self.client.resource_release(self.device, handle)); handle.* = empty_resource;
        };
        self.allocator.free(self.pixels); self.pixels = &.{};
        self.width = 0; self.height = 0; self.format = 0; self.valid = false;
        self.epoch = 0; self.frame = 0; self.acknowledged = 0; self.phase = .empty; self.failure = null;
    }
};
pub fn sdr() gfx.R4GfxColorDescription {
    return .{ .version = 1, .size = @sizeOf(gfx.R4GfxColorDescription), .primaries = gfx.color_primaries_srgb,
        .transfer = gfx.color_transfer_srgb, .range = gfx.color_range_full, .alpha = gfx.color_alpha_opaque,
        .precision = gfx.color_precision_unorm8, .flags = 0, .reference_white = 1000000, .peak = 1000000, .black = 0, .reserved = 0 };
}
fn accepted(status: i32) Error!void {
    return switch (status) { gfx.status_ok => {}, gfx.status_busy => error.Busy,
        gfx.status_stale, gfx.status_suboptimal, gfx.status_lost => error.Stale,
        gfx.status_unsupported, gfx.status_unavailable => error.Unsupported, gfx.status_limit => error.Limit, else => error.Graphics };
}
