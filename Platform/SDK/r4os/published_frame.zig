//! Scoped published-frame loans over the actual serialized copy Presenter.
const std = @import("std");
pub const video = @import("subsystem_host.zig");
pub const wire = @import("binary_cursor.zig");
pub const callbacks = @import("subsystem_callback_bridge.zig");
const abi = @import("r4os_contract").abi;
fn unavailableIndexed(_: *anyopaque, _: video.IndexedBatch) i32 {
    return abi.err_no_fn;
}
pub const invalid: i32 = -401;
pub const invalid_surface: i32 = -402;
pub const invalid_buffer: i32 = -403;
pub const stale_generation: i32 = -404;
pub const stale_revision: i32 = -405;
pub const stale_damage: i32 = -406;
pub const busy: i32 = -407;
pub const closed: i32 = -408;
pub const exhausted: i32 = -409;
pub const no_provider: i32 = -410;
pub const unsupported: i32 = -411;
pub const no_lease: i32 = -412;
pub const scratch_small: i32 = -413;
pub const published: u32 = 1;
pub const format_indexed8: u32 = 0;
pub const format_xrgb32: u32 = 1;
pub const damage_full: u32 = 0;
pub const damage_rect: u32 = 1;
pub const damage_none: u32 = 2;
pub const unbound: u32 = 0;
pub const running: u32 = 1;
pub const paused: u32 = 2;
pub const ended: u32 = 3;
pub const active_loan: u32 = 1;
pub const in_call: u32 = 2;
pub const close_pending: u32 = 4;
pub const has_observation: u32 = 8;
pub const viewport_valid: u32 = 1;
const magic: u64 = 0x504652414d453031;
var neutral_pixel: [1]u32 = .{0};
fn neutralSurface() video.Surface {
    return .{ .width = 1, .height = 1, .storage = .{ .xrgb32 = &neutral_pixel } };
}
pub const Rect = extern struct { x: u32 = 0, y: u32 = 0, w: u32 = 0, h: u32 = 0 };
pub const Lease = extern struct {
    pixels: wire.Span = .{},
    palette: wire.Span = .{},
    binding_generation: u64 = 0,
    revision: u64 = 0,
    palette_revision: u64 = 0,
    damage_base_revision: u64 = 0,
    width: u32 = 0,
    height: u32 = 0,
    stride_bytes: u32 = 0,
    format: u32 = 0,
    damage_kind: u32 = 0,
    flags: u32 = 0,
    reserved0: u32 = 0,
    reserved1: u32 = 0,
    damage: Rect = .{},
};
pub const Acquisition = extern struct { ticket: u64, kind: u32, reserved0: u32 = 0 };
pub const Viewport = extern struct {
    x: i32 = 0,
    y: i32 = 0,
    width: u32 = 0,
    height: u32 = 0,
    source_width: u32 = 0,
    source_height: u32 = 0,
    integer_scale: u32 = 0,
    reserved0: u32 = 0,
};
pub const Presentation = extern struct {
    kind: u32 = 0,
    error_code: i32 = 0,
    mode: u32 = 0,
    flags: u32 = 0,
    viewport: Viewport = .{},
    damage_regions: u32 = 0,
    raster_blocks: u32 = 0,
    sampled_pixels: u64 = 0,
};
pub const Progress = extern struct {
    binding_generation: u64,
    revision: u64,
    palette_revision: u64,
    active_ticket: u64,
    last_ticket: u64,
    width: u32,
    height: u32,
    stride_bytes: u32,
    format: u32,
    state: u32,
    flags: u32,
    last_sync_kind: u32,
    reserved0: u32 = 0,
};
fn spanOf(pointer: anytype) wire.Span {
    return .{ .address = @intFromPtr(pointer), .length = @sizeOf(@typeInfo(@TypeOf(pointer)).pointer.child) };
}
fn overlap(a: wire.Span, b: wire.Span) bool {
    return a.length != 0 and b.length != 0 and a.address < b.address + b.length and b.address < a.address + a.length;
}
fn projectViewport(value: video.Viewport) Viewport {
    return .{ .x = value.x, .y = value.y, .width = value.w, .height = value.h, .source_width = value.guest_w, .source_height = value.guest_h, .integer_scale = value.integer_scale };
}

pub const Bridge = struct {
    stamp: u64 = magic,
    presenter: video.Presenter,
    backend: video.Backend,
    scratch: wire.Span,
    frame: Lease = .{},
    generation: u64 = 0,
    last_ticket: u64 = 0,
    active_ticket: u64 = 0,
    revision: u64 = 0,
    palette_revision: u64 = 0,
    width: u32 = 0,
    height: u32 = 0,
    stride_bytes: u32 = 0,
    format: u32 = 0,
    state: u32 = unbound,
    call_active: u32 = 0,
    close_requested: u32 = 0,
    last_sync_kind: u32 = 0,

    pub fn init(backend: video.Backend, scratch: []u32, out: *Bridge) i32 {
        if (backend.supports_shared_raster) return unsupported;
        if (!backend.available) return no_provider;
        if (scratch.len < video.tile_max_pixels) return scratch_small;
        const length = std.math.mul(usize, scratch.len, @sizeOf(u32)) catch return invalid_buffer;
        const range = wire.Span{ .address = @intFromPtr(scratch.ptr), .length = length };
        range.validate() catch return invalid_buffer;
        if (overlap(range, spanOf(out))) return invalid_buffer;
        const presenter = video.Presenter.init(neutralSurface(), scratch) catch return scratch_small;
        out.* = .{ .presenter = presenter, .backend = backend, .scratch = range };
        return 0;
    }
    pub fn initCallbacks(table: *const callbacks.Table, scratch: []u32, features: u32, out: *Bridge) i32 {
        if (features & ~@as(u32, 3) != 0) return unsupported;
        const scratch_bytes = std.math.mul(usize, scratch.len, @sizeOf(u32)) catch return invalid_buffer;
        const scratch_range = wire.Span{ .address = @intFromPtr(scratch.ptr), .length = scratch_bytes };
        scratch_range.validate() catch return invalid_buffer;
        if (overlap(spanOf(table), spanOf(out)) or overlap(spanOf(table), scratch_range)) return invalid_buffer;
        if (features & 1 != 0 and !table.has(.video_indexed8)) return no_provider;
        if (features & 2 != 0 and (!table.has(.video_xrgb32) or !table.has(.video_begin_replace))) return no_provider;
        // The original Backend has a required indexed8_fn even when its
        // indexed transport is disabled. This narrower copy profile accepts
        // just its selected callbacks and gives the unused field an honest
        // NoFn implementation. The original Backend and adapters stay intact.
        inline for (.{ callbacks.Kind.video_begin_full, callbacks.Kind.video_begin_damage, callbacks.Kind.video_clear, callbacks.Kind.video_raster, callbacks.Kind.video_commit_full, callbacks.Kind.video_commit_damage, callbacks.Kind.video_cancel }) |kind| {
            if (!table.has(kind)) return no_provider;
        }
        var backend: video.Backend = .{
            .context = @ptrCast(@constCast(table)),
            .begin_full_fn = callbacks.pointer(@FieldType(video.Backend, "begin_full_fn"), 0, .video_begin_full),
            .begin_damage_fn = callbacks.pointer(@FieldType(video.Backend, "begin_damage_fn"), 0, .video_begin_damage),
            .clear_fn = callbacks.pointer(@FieldType(video.Backend, "clear_fn"), 0, .video_clear),
            .raster_fn = callbacks.pointer(@FieldType(video.Backend, "raster_fn"), 0, .video_raster),
            .indexed8_fn = unavailableIndexed,
            .commit_full_fn = callbacks.pointer(@FieldType(video.Backend, "commit_full_fn"), 0, .video_commit_full),
            .commit_damage_fn = callbacks.pointer(@FieldType(video.Backend, "commit_damage_fn"), 0, .video_commit_damage),
            .cancel_fn = callbacks.pointer(@FieldType(video.Backend, "cancel_fn"), 0, .video_cancel),
            .supports_indexed8 = features & 1 != 0,
            .supports_xrgb32_nearest = features & 2 != 0,
        };
        if (features & 1 != 0) backend.indexed8_fn = callbacks.pointer(@FieldType(video.Backend, "indexed8_fn"), 0, .video_indexed8);
        if (features & 2 != 0) {
            backend.begin_replace_fn = callbacks.pointer(@FieldType(video.Backend, "begin_replace_fn"), 0, .video_begin_replace);
            backend.xrgb32_nearest_fn = callbacks.pointer(@FieldType(video.Backend, "xrgb32_nearest_fn"), 0, .video_xrgb32);
        }
        return init(backend, scratch, out);
    }
    fn check(self: *const Bridge) i32 {
        if (self.stamp != magic or self.state > ended or self.call_active > 1 or self.close_requested > 1 or self.last_sync_kind > 1 or
            self.active_ticket > self.last_ticket or self.state == unbound and self.generation != 0 or
            (self.state == running or self.state == paused) and self.generation == 0 or
            self.state == ended and self.active_ticket != 0) return invalid;
        if (self.backend.supports_shared_raster) return unsupported;
        if (self.active_ticket == 0 and (self.frame.pixels.length != 0 or self.frame.palette.length != 0)) return invalid;
        return 0;
    }
    pub fn progress(self: *const Bridge, out: *Progress) i32 {
        const rc = self.check();
        if (rc != 0) return rc;
        const target = spanOf(out);
        if (!self.disjoint(target) or overlap(target, self.frame.pixels) or overlap(target, self.frame.palette)) return invalid_buffer;
        out.* = .{ .binding_generation = self.generation, .revision = self.revision, .palette_revision = self.palette_revision, .active_ticket = self.active_ticket, .last_ticket = self.last_ticket, .width = self.width, .height = self.height, .stride_bytes = self.stride_bytes, .format = self.format, .state = self.state, .flags = (if (self.active_ticket != 0) active_loan else @as(u32, 0)) | (if (self.call_active != 0) in_call else @as(u32, 0)) | (if (self.close_requested != 0) close_pending else @as(u32, 0)) | (if (self.revision != 0) has_observation else @as(u32, 0)), .last_sync_kind = self.last_sync_kind };
        return 0;
    }
    pub fn bind(self: *Bridge, generation: u64) i32 {
        const rc = self.check();
        if (rc != 0) return rc;
        if (self.call_active != 0 or self.active_ticket != 0) return busy;
        if (self.state == ended) return closed;
        if (generation == 0 or generation <= self.generation) return stale_generation;
        self.presenter.setSurface(neutralSurface()) catch return invalid_surface;
        self.presenter.has_frame = false;
        self.generation = generation;
        self.revision = 0;
        self.palette_revision = 0;
        self.width = 0;
        self.height = 0;
        self.stride_bytes = 0;
        self.format = 0;
        self.last_sync_kind = 0;
        self.state = running;
        return 0;
    }
    pub fn pause(self: *Bridge, value: bool) i32 {
        const rc = self.check();
        if (rc != 0) return rc;
        if (self.call_active != 0) return busy;
        if (self.state == ended) return closed;
        if (self.state == unbound) return invalid;
        self.state = if (value) paused else running;
        return 0;
    }
    fn disjoint(self: *const Bridge, source: wire.Span) bool {
        return !overlap(source, self.scratch) and !overlap(source, spanOf(self));
    }
    fn surface(self: *const Bridge, frame: Lease, output: *video.Surface) i32 {
        if (frame.flags != published or frame.reserved0 != 0 or frame.reserved1 != 0 or frame.revision == 0 or
            frame.width == 0 or frame.height == 0 or frame.width > std.math.maxInt(i32) or frame.height > std.math.maxInt(i32) or frame.damage_kind > damage_none) return invalid_surface;
        frame.pixels.validate() catch return invalid_buffer;
        frame.palette.validate() catch return invalid_buffer;
        if (!self.disjoint(frame.pixels) or !self.disjoint(frame.palette) or overlap(frame.pixels, frame.palette)) return invalid_buffer;
        const pixel_bytes: usize = switch (frame.format) {
            format_indexed8 => 1,
            format_xrgb32 => 4,
            else => return unsupported,
        };
        const stride = std.math.mul(usize, frame.width, pixel_bytes) catch return invalid_buffer;
        if (stride > std.math.maxInt(u32) or frame.stride_bytes != stride) return unsupported;
        const required = std.math.mul(usize, stride, frame.height) catch return invalid_buffer;
        if (frame.pixels.length < required) return invalid_buffer;
        const count = required / pixel_bytes;
        if (frame.format == format_indexed8) {
            if (frame.palette_revision == 0 or frame.palette.address % @alignOf(u32) != 0 or frame.palette.length < video.palette_entries * @sizeOf(u32)) return invalid_surface;
            const pixels: [*]u8 = @ptrFromInt(frame.pixels.address);
            const palette: [*]u32 = @ptrFromInt(frame.palette.address);
            output.* = video.Surface.initIndexed8(pixels[0..count], palette[0..video.palette_entries], frame.width, frame.height) catch return invalid_surface;
        } else {
            if (frame.pixels.address % @alignOf(u32) != 0 or frame.palette.address != 0 or frame.palette.length != 0 or frame.palette_revision != 0) return invalid_surface;
            const pixels: [*]u32 = @ptrFromInt(frame.pixels.address);
            output.* = video.Surface.initXrgb32(pixels[0..count], frame.width, frame.height) catch return invalid_surface;
        }
        if (frame.damage_kind == damage_rect) {
            const rect = frame.damage;
            if (rect.w == 0 or rect.h == 0 or @as(u64, rect.x) + rect.w > frame.width or @as(u64, rect.y) + rect.h > frame.height) return stale_damage;
        }
        if (frame.damage_kind != damage_rect and (frame.damage.x != 0 or frame.damage.y != 0 or frame.damage.w != 0 or frame.damage.h != 0)) return stale_damage;
        return 0;
    }
    /// Caller proves this is a complete publication and holds both whole
    /// immutable source buffers until release or completed close.
    pub fn syncPublished(self: *Bridge, frame: Lease, out: *Acquisition) i32 {
        var rc = self.check();
        if (rc != 0) return rc;
        if (self.call_active != 0 or self.active_ticket != 0) return busy;
        if (self.state == ended) return closed;
        if (self.state == unbound) return invalid;
        if (frame.binding_generation != self.generation) return stale_generation;
        var next: video.Surface = undefined;
        rc = self.surface(frame, &next);
        if (rc != 0) return rc;
        const result_span = spanOf(out);
        if (!self.disjoint(result_span) or overlap(result_span, frame.pixels) or overlap(result_span, frame.palette)) return invalid_buffer;
        if (frame.revision < self.revision) return stale_revision;
        const geometry = frame.width != self.width or frame.height != self.height or frame.stride_bytes != self.stride_bytes or frame.format != self.format;
        if (self.revision != 0 and frame.revision == self.revision and geometry) return stale_revision;
        if (self.revision != 0 and self.format == format_indexed8 and frame.format == format_indexed8 and frame.palette_revision < self.palette_revision) return stale_revision;
        const pixels_changed = frame.revision != self.revision;
        const palette_changed = frame.palette_revision != self.palette_revision;
        if (pixels_changed) {
            if (frame.damage_kind == damage_full) {
                if (frame.damage_base_revision != 0) return stale_damage;
            } else if (self.revision == 0 or frame.damage_base_revision != self.revision) return stale_damage;
        }
        if (self.last_ticket == std.math.maxInt(u64)) return exhausted;
        if (self.revision == 0 or geometry or palette_changed) {
            self.presenter.setSurface(next) catch return invalid_surface;
        } else self.presenter.surface = next;
        if (pixels_changed) switch (frame.damage_kind) {
            damage_full => self.presenter.invalidateAll(),
            damage_rect => self.presenter.invalidate(.{ .x = frame.damage.x, .y = frame.damage.y, .w = frame.damage.w, .h = frame.damage.h }),
            damage_none => {},
            else => unreachable,
        };
        self.frame = frame;
        self.last_ticket += 1;
        self.active_ticket = self.last_ticket;
        self.last_sync_kind = @intFromBool(pixels_changed or palette_changed);
        self.revision = frame.revision;
        self.palette_revision = frame.palette_revision;
        self.width = frame.width;
        self.height = frame.height;
        self.stride_bytes = frame.stride_bytes;
        self.format = frame.format;
        out.* = .{ .ticket = self.active_ticket, .kind = self.last_sync_kind };
        return 0;
    }
    fn detach(self: *Bridge) void {
        self.presenter.surface = neutralSurface();
        self.frame = .{};
        self.active_ticket = 0;
    }
    pub fn release(self: *Bridge, ticket: u64) i32 {
        const rc = self.check();
        if (rc != 0) return rc;
        if (self.call_active != 0) return busy;
        if (ticket == 0 or ticket != self.active_ticket) return no_lease;
        self.detach();
        return 0;
    }
    fn finishClose(self: *Bridge) void {
        self.detach();
        self.presenter.deinit(self.backend); // Copy profile owns no shared resource.
        self.state = ended;
        self.close_requested = 0;
    }
    pub fn close(self: *Bridge) i32 {
        const rc = self.check();
        if (rc != 0) return rc;
        if (self.call_active != 0) {
            self.close_requested = 1;
            return busy;
        }
        if (self.state != ended) self.finishClose();
        return 0;
    }
    pub fn present(self: *Bridge, ticket: u64, width: i32, height: i32, out: *Presentation) i32 {
        return self.presentWithOverlay(ticket, width, height, out, null);
    }
    /// Native client overlays append inside the same synchronous copy call.
    /// Callback clients can compose their existing commit callback instead.
    pub fn presentWithOverlay(self: *Bridge, ticket: u64, width: i32, height: i32, out: *Presentation, overlay: ?video.FrameOverlay) i32 {
        const rc = self.check();
        if (rc != 0) return rc;
        if (self.call_active != 0) return busy;
        if (self.state == ended) return closed;
        if (ticket == 0 or ticket != self.active_ticket) return no_lease;
        const result_span = spanOf(out);
        if (!self.disjoint(result_span) or overlap(result_span, self.frame.pixels) or overlap(result_span, self.frame.palette)) return invalid_buffer;
        self.call_active = 1;
        const native = self.presenter.presentToWithOverlay(self.backend, width, height, overlay);
        var value: Presentation = .{};
        switch (native) {
            .unchanged => if (self.presenter.currentViewport()) |viewport| {
                value.viewport = projectViewport(viewport);
                value.flags = viewport_valid;
            },
            .hidden => value.kind = 1,
            .presented => |info| {
                value = .{ .kind = 2, .mode = @intFromEnum(info.mode), .viewport = projectViewport(info.viewport), .flags = viewport_valid, .damage_regions = info.damage_regions, .raster_blocks = info.raster_blocks, .sampled_pixels = info.sampled_pixels };
            },
            .failure => |code| {
                value.kind = 3;
                value.error_code = code;
            },
        }
        self.call_active = 0;
        if (self.close_requested != 0) self.finishClose();
        out.* = value;
        return 0;
    }
};
