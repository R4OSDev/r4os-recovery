const std = @import("std");
const abi = @import("r4os_contract").abi;
const r4desk = @import("r4desk.zig");
const r4draw = @import("r4draw.zig");
const raster = @import("raster.zig");

pub const tile_max_width: u32 = raster.max_width;
pub const tile_max_height: u32 = raster.max_height;
pub const tile_max_pixels: usize = raster.max_pixels;
pub const palette_entries: usize = 256;
pub const letterbox_rgb: u32 = 0x000000;
pub const integer_preference_percent: u32 = 85;
pub const max_damage_chain: u32 = 32;
pub const max_damage_regions: usize = abi.gui_frame_max_damage_regions;

pub const Error = error{
    InvalidSize,
    BufferTooSmall,
    PaletteTooSmall,
    ScratchTooSmall,
    Overflow,
    UnsupportedDrawContract,
    WindowUnavailable,
};

pub const PixelFormat = enum {
    indexed8,
    xrgb32,
};

pub const Indexed8 = struct {
    pixels: []u8,
    palette: []u32,
};

pub const PixelStorage = union(PixelFormat) {
    indexed8: Indexed8,
    xrgb32: []u32,
};

pub const Surface = struct {
    width: u32,
    height: u32,
    storage: PixelStorage,

    pub fn initIndexed8(pixels: []u8, palette_values: []u32, width: u32, height: u32) Error!Surface {
        const count = try requiredPixels(width, height);
        if (pixels.len < count) return Error.BufferTooSmall;
        if (palette_values.len < palette_entries) return Error.PaletteTooSmall;
        return .{
            .width = width,
            .height = height,
            .storage = .{ .indexed8 = .{
                .pixels = pixels[0..count],
                .palette = palette_values[0..palette_entries],
            } },
        };
    }

    pub fn initXrgb32(pixels: []u32, width: u32, height: u32) Error!Surface {
        const count = try requiredPixels(width, height);
        if (pixels.len < count) return Error.BufferTooSmall;
        return .{
            .width = width,
            .height = height,
            .storage = .{ .xrgb32 = pixels[0..count] },
        };
    }

    pub fn format(self: Surface) PixelFormat {
        return std.meta.activeTag(self.storage);
    }

    pub fn pixelCount(self: Surface) usize {
        return @as(usize, self.width) * @as(usize, self.height);
    }

    pub fn indexedPixels(self: *Surface) ?[]u8 {
        return switch (self.storage) {
            .indexed8 => |value| value.pixels,
            .xrgb32 => null,
        };
    }

    pub fn xrgb32Pixels(self: *Surface) ?[]u32 {
        return switch (self.storage) {
            .indexed8 => null,
            .xrgb32 => |value| value,
        };
    }

    pub fn palette(self: *Surface) ?[]u32 {
        return switch (self.storage) {
            .indexed8 => |value| value.palette,
            .xrgb32 => null,
        };
    }

    fn colorAt(self: Surface, x: u32, y: u32) u32 {
        const index = @as(usize, y) * @as(usize, self.width) + @as(usize, x);
        return switch (self.storage) {
            .indexed8 => |value| value.palette[value.pixels[index]] & 0x00FF_FFFF,
            .xrgb32 => |value| value[index] & 0x00FF_FFFF,
        };
    }
};

pub const Rect = struct {
    x: u32,
    y: u32,
    w: u32,
    h: u32,

    pub fn full(width: u32, height: u32) Rect {
        return .{ .x = 0, .y = 0, .w = width, .h = height };
    }

    pub fn isEmpty(self: Rect) bool {
        return self.w == 0 or self.h == 0;
    }
};

pub const Point = struct {
    x: u32,
    y: u32,
};

pub const Size = struct {
    w: u32,
    h: u32,
};

pub const Viewport = struct {
    x: i32,
    y: i32,
    w: u32,
    h: u32,
    guest_w: u32,
    guest_h: u32,
    integer_scale: u32,

    pub fn isInteger(self: Viewport) bool {
        return self.integer_scale != 0;
    }

    pub fn mapClientPoint(self: Viewport, client_x: i32, client_y: i32) ?Point {
        if (client_x < self.x or client_y < self.y) return null;
        const local_x: u64 = @intCast(client_x - self.x);
        const local_y: u64 = @intCast(client_y - self.y);
        if (local_x >= self.w or local_y >= self.h) return null;
        return .{
            .x = @intCast((local_x * self.guest_w) / self.w),
            .y = @intCast((local_y * self.guest_h) / self.h),
        };
    }
};

pub fn calculateViewport(client_w: i32, client_h: i32, guest_w: u32, guest_h: u32) Error!Viewport {
    if (client_w <= 0 or client_h <= 0 or guest_w == 0 or guest_h == 0) return Error.InvalidSize;
    const cw: u32 = @intCast(client_w);
    const ch: u32 = @intCast(client_h);
    const cw64: u64 = cw;
    const ch64: u64 = ch;
    const gw64: u64 = guest_w;
    const gh64: u64 = guest_h;

    var fit_w: u32 = undefined;
    var fit_h: u32 = undefined;
    if (cw64 * gh64 <= ch64 * gw64) {
        fit_w = cw;
        fit_h = @intCast(@max(@as(u64, 1), (gh64 * cw64) / gw64));
    } else {
        fit_h = ch;
        fit_w = @intCast(@max(@as(u64, 1), (gw64 * ch64) / gh64));
    }

    const integer_scale = @min(cw / guest_w, ch / guest_h);
    var view_w = fit_w;
    var view_h = fit_h;
    var selected_integer: u32 = 0;
    if (integer_scale != 0) {
        const integer_w: u64 = gw64 * integer_scale;
        const integer_h: u64 = gh64 * integer_scale;
        const preferred = integer_w * 100 >= @as(u64, fit_w) * integer_preference_percent and
            integer_h * 100 >= @as(u64, fit_h) * integer_preference_percent;
        if (preferred) {
            view_w = @intCast(integer_w);
            view_h = @intCast(integer_h);
            selected_integer = integer_scale;
        }
    }

    return .{
        .x = @intCast((cw - view_w) / 2),
        .y = @intCast((ch - view_h) / 2),
        .w = view_w,
        .h = view_h,
        .guest_w = guest_w,
        .guest_h = guest_h,
        .integer_scale = selected_integer,
    };
}

const DamageKind = enum {
    none,
    full,
    rect,
};

const Damage = struct {
    kind: DamageKind = .full,
    regions: [max_damage_regions]Rect = .{Rect{ .x = 0, .y = 0, .w = 0, .h = 0 }} ** max_damage_regions,
    count: usize = 0,

    fn markFull(self: *Damage) void {
        self.kind = .full;
        self.count = 0;
    }

    fn clear(self: *Damage) void {
        self.* = .{ .kind = .none };
    }

    fn mark(self: *Damage, requested: Rect, width: u32, height: u32) void {
        const value = clipRect(requested, width, height) orelse return;
        if (self.kind == .full) return;
        self.kind = .rect;

        var merged = value;
        var index: usize = 0;
        while (index < self.count) {
            if (!rectsTouchOrOverlap(self.regions[index], merged)) {
                index += 1;
                continue;
            }
            merged = mergeRect(self.regions[index], merged);
            self.count -= 1;
            self.regions[index] = self.regions[self.count];
        }
        if (self.count < self.regions.len) {
            self.regions[self.count] = merged;
            self.count += 1;
        } else {
            var best_index: usize = 0;
            var best_growth: u64 = std.math.maxInt(u64);
            for (self.regions[0..self.count], 0..) |existing, candidate| {
                const combined = mergeRect(existing, merged);
                const growth = rectArea(combined) - rectArea(existing);
                if (growth < best_growth) {
                    best_growth = growth;
                    best_index = candidate;
                }
            }
            self.regions[best_index] = mergeRect(self.regions[best_index], merged);
        }
        if (self.count == 1 and rectIsFull(self.regions[0], width, height)) self.markFull();
    }

    fn slice(self: *const Damage) []const Rect {
        return self.regions[0..self.count];
    }
};

pub const PresentMode = enum {
    full,
    damage,
    replace,
};

pub const PresentInfo = struct {
    mode: PresentMode,
    viewport: Viewport,
    damage_regions: u32,
    raster_blocks: u32,
    sampled_pixels: u64,
};

pub const PresentResult = union(enum) {
    unchanged,
    hidden,
    presented: PresentInfo,
    failure: i32,
};

pub const PresentStats = struct {
    published_frames: u64 = 0,
    skipped_frames: u64 = 0,
    full_frames: u64 = 0,
    damage_frames: u64 = 0,
    compacted_frames: u64 = 0,
    damage_regions: u64 = 0,
    indexed8_frames: u64 = 0,
    indexed8_blocks: u64 = 0,
    indexed8_resource_bytes: u64 = 0,
    replacement_frames: u64 = 0,
    xrgb32_nearest_frames: u64 = 0,
    xrgb32_nearest_blocks: u64 = 0,
    xrgb32_nearest_resource_bytes: u64 = 0,
    shared_raster_frames: u64 = 0,
    shared_raster_blocks: u64 = 0,
    shared_raster_descriptor_bytes: u64 = 0,
    shared_raster_published_bytes: u64 = 0,
    shared_raster_fallback_frames: u64 = 0,
    shared_raster_backpressure_fallbacks: u64 = 0,
    xrgb_fallback_frames: u64 = 0,
    raster_blocks: u64 = 0,
    sampled_pixels: u64 = 0,
};

pub const IndexedBatch = struct {
    command: abi.GuiFrameCommand,
    resource: []const u8,
};

pub const Xrgb32Batch = struct {
    command: abi.GuiFrameCommand,
    resource: []const u8,
};

pub const SharedRasterBatch = struct {
    command: abi.GuiFrameCommand,
    resource: abi.GuiSharedRasterResource,
};

fn unavailableBeginReplace(_: *anyopaque, _: []const abi.DisplayDamageRect) i32 {
    return abi.err_no_fn;
}

fn unavailableXrgb32Nearest(_: *anyopaque, _: Xrgb32Batch) i32 {
    return abi.err_no_fn;
}

fn unavailableSharedRasterCreate(_: *anyopaque, _: *const abi.GuiSharedRasterCreateInfo, _: *abi.GuiSharedRasterHandle) i32 {
    return abi.err_no_fn;
}

fn unavailableSharedRasterDestroy(_: *anyopaque, _: *const abi.GuiSharedRasterHandle) i32 {
    return abi.err_no_fn;
}

fn unavailableSharedRasterMapWrite(_: *anyopaque, _: *const abi.GuiSharedRasterHandle, _: *abi.GuiSharedRasterWriteMap) i32 {
    return abi.err_no_fn;
}

fn unavailableSharedRasterPublish(_: *anyopaque, _: *const abi.GuiSharedRasterWriteMap, _: *u64) i32 {
    return abi.err_no_fn;
}

fn unavailableSharedRaster(_: *anyopaque, _: SharedRasterBatch) i32 {
    return abi.err_no_fn;
}

pub const Backend = struct {
    context: *anyopaque,
    begin_full_fn: *const fn (*anyopaque) i32,
    begin_damage_fn: *const fn (*anyopaque, []const abi.DisplayDamageRect) i32,
    begin_replace_fn: *const fn (*anyopaque, []const abi.DisplayDamageRect) i32 = unavailableBeginReplace,
    clear_fn: *const fn (*anyopaque, u32) i32,
    raster_fn: *const fn (*anyopaque, i32, i32, u32, u32, u32, []const u32) i32,
    indexed8_fn: *const fn (*anyopaque, IndexedBatch) i32,
    xrgb32_nearest_fn: *const fn (*anyopaque, Xrgb32Batch) i32 = unavailableXrgb32Nearest,
    shared_raster_create_fn: *const fn (*anyopaque, *const abi.GuiSharedRasterCreateInfo, *abi.GuiSharedRasterHandle) i32 = unavailableSharedRasterCreate,
    shared_raster_destroy_fn: *const fn (*anyopaque, *const abi.GuiSharedRasterHandle) i32 = unavailableSharedRasterDestroy,
    shared_raster_map_write_fn: *const fn (*anyopaque, *const abi.GuiSharedRasterHandle, *abi.GuiSharedRasterWriteMap) i32 = unavailableSharedRasterMapWrite,
    shared_raster_publish_fn: *const fn (*anyopaque, *const abi.GuiSharedRasterWriteMap, *u64) i32 = unavailableSharedRasterPublish,
    shared_raster_fn: *const fn (*anyopaque, SharedRasterBatch) i32 = unavailableSharedRaster,
    commit_full_fn: *const fn (*anyopaque) i32,
    commit_damage_fn: *const fn (*anyopaque) i32,
    cancel_fn: *const fn (*anyopaque) i32,
    supports_indexed8: bool = false,
    supports_xrgb32_nearest: bool = false,
    supports_shared_raster: bool = false,

    pub fn fromDraw(draw: *const r4draw.Context) Backend {
        return .{
            .context = @ptrCast(@constCast(draw)),
            .begin_full_fn = drawBeginFull,
            .begin_damage_fn = drawBeginDamage,
            .begin_replace_fn = drawBeginReplace,
            .clear_fn = drawClear,
            .raster_fn = drawRaster,
            .indexed8_fn = drawIndexed8,
            .xrgb32_nearest_fn = drawXrgb32Nearest,
            .shared_raster_create_fn = drawSharedRasterCreate,
            .shared_raster_destroy_fn = drawSharedRasterDestroy,
            .shared_raster_map_write_fn = drawSharedRasterMapWrite,
            .shared_raster_publish_fn = drawSharedRasterPublish,
            .shared_raster_fn = drawSharedRaster,
            .commit_full_fn = drawCommitFull,
            .commit_damage_fn = drawCommitDamage,
            .cancel_fn = drawCancel,
            .supports_indexed8 = draw.supportsGuiFrameDamageContract(),
            .supports_xrgb32_nearest = draw.supportsGuiFrameStreamingContract(),
            .supports_shared_raster = draw.supportsGuiSharedRasterContract(),
        };
    }

    fn begin(self: Backend, mode: PresentMode, regions: []const abi.DisplayDamageRect) i32 {
        return switch (mode) {
            .full => self.begin_full_fn(self.context),
            .damage => self.begin_damage_fn(self.context, regions),
            .replace => self.begin_replace_fn(self.context, regions),
        };
    }

    fn clear(self: Backend, rgb: u32) i32 {
        return self.clear_fn(self.context, rgb);
    }

    fn raster(self: Backend, x: i32, y: i32, w: u32, h: u32, scale: u32, pixels: []const u32) i32 {
        return self.raster_fn(self.context, x, y, w, h, scale, pixels);
    }

    fn indexed8(self: Backend, batch: IndexedBatch) i32 {
        return self.indexed8_fn(self.context, batch);
    }

    fn xrgb32Nearest(self: Backend, batch: Xrgb32Batch) i32 {
        return self.xrgb32_nearest_fn(self.context, batch);
    }

    fn sharedRasterCreate(self: Backend, info: *const abi.GuiSharedRasterCreateInfo, out_handle: *abi.GuiSharedRasterHandle) i32 {
        return self.shared_raster_create_fn(self.context, info, out_handle);
    }

    fn sharedRasterDestroy(self: Backend, handle: *const abi.GuiSharedRasterHandle) i32 {
        return self.shared_raster_destroy_fn(self.context, handle);
    }

    fn sharedRasterMapWrite(self: Backend, handle: *const abi.GuiSharedRasterHandle, out_map: *abi.GuiSharedRasterWriteMap) i32 {
        return self.shared_raster_map_write_fn(self.context, handle, out_map);
    }

    fn sharedRasterPublish(self: Backend, map: *const abi.GuiSharedRasterWriteMap, out_generation: *u64) i32 {
        return self.shared_raster_publish_fn(self.context, map, out_generation);
    }

    fn sharedRaster(self: Backend, batch: SharedRasterBatch) i32 {
        return self.shared_raster_fn(self.context, batch);
    }

    fn commit(self: Backend, mode: PresentMode) i32 {
        return switch (mode) {
            .full => self.commit_full_fn(self.context),
            .damage => self.commit_damage_fn(self.context),
            .replace => self.commit_damage_fn(self.context),
        };
    }

    fn cancel(self: Backend) void {
        _ = self.cancel_fn(self.context);
    }
};

pub const Presenter = struct {
    surface: Surface,
    scratch: []u32,
    damage: Damage = .{},
    last_viewport: ?Viewport = null,
    has_frame: bool = false,
    damage_chain: u32 = 0,
    stats: PresentStats = .{},
    shared_handle: abi.GuiSharedRasterHandle = .{},
    shared_info: abi.GuiSharedRasterCreateInfo = .{},

    pub fn init(surface: Surface, scratch: []u32) Error!Presenter {
        _ = try requiredPixels(surface.width, surface.height);
        if (scratch.len < tile_max_pixels) return Error.ScratchTooSmall;
        return .{ .surface = surface, .scratch = scratch[0..tile_max_pixels] };
    }

    pub fn setSurface(self: *Presenter, surface: Surface) Error!void {
        _ = try requiredPixels(surface.width, surface.height);
        self.surface = surface;
        self.damage.markFull();
        self.last_viewport = null;
        self.damage_chain = 0;
    }

    pub fn invalidateAll(self: *Presenter) void {
        self.damage.markFull();
    }

    pub fn invalidate(self: *Presenter, rect: Rect) void {
        self.damage.mark(rect, self.surface.width, self.surface.height);
    }

    pub fn setPaletteEntry(self: *Presenter, index: u8, rgb: u32) bool {
        switch (self.surface.storage) {
            .indexed8 => |value| {
                value.palette[index] = rgb & 0x00FF_FFFF;
                self.damage.markFull();
                return true;
            },
            .xrgb32 => return false,
        }
    }

    pub fn currentViewport(self: *const Presenter) ?Viewport {
        return self.last_viewport;
    }

    pub fn presentTo(self: *Presenter, backend: Backend, client_w: i32, client_h: i32) PresentResult {
        const viewport = calculateViewport(client_w, client_h, self.surface.width, self.surface.height) catch {
            self.stats.skipped_frames +%= 1;
            return .hidden;
        };
        const geometry_changed = if (self.last_viewport) |last| !viewportEqual(last, viewport) else true;
        if (self.damage.kind == .none and !geometry_changed and self.has_frame) {
            self.stats.skipped_frames +%= 1;
            return .unchanged;
        }

        const use_xrgb32_nearest = self.surface.format() == .xrgb32 and backend.supports_xrgb32_nearest;
        const shared_info = sharedRasterCreateInfo(self.surface);
        const wants_shared_raster = backend.supports_shared_raster and shared_info != null;
        var compacted = false;
        var mode: PresentMode = if (!self.has_frame or geometry_changed or self.damage.kind == .full)
            .full
        else if (wants_shared_raster or use_xrgb32_nearest)
            .replace
        else
            .damage;
        if (mode == .damage and self.damage_chain >= max_damage_chain) {
            mode = .full;
            compacted = true;
        }
        var full_region = [_]Rect{Rect.full(self.surface.width, self.surface.height)};
        const changed_regions: []const Rect = switch (mode) {
            .full => full_region[0..],
            .damage, .replace => self.damage.slice(),
        };
        const render_regions: []const Rect = switch (mode) {
            .full, .replace => full_region[0..],
            .damage => changed_regions,
        };
        var destination_regions: [max_damage_regions]abi.DisplayDamageRect = undefined;
        var destination_count: usize = 0;
        if (mode != .full) {
            for (changed_regions) |source_region| {
                const mapped = mapDamageToViewport(source_region, self.surface.width, self.surface.height, viewport.w, viewport.h) orelse continue;
                destination_regions[destination_count] = .{
                    .x = viewport.x + @as(i32, @intCast(mapped.x)),
                    .y = viewport.y + @as(i32, @intCast(mapped.y)),
                    .w = mapped.w,
                    .h = mapped.h,
                };
                destination_count += 1;
            }
            if (destination_count == 0) {
                self.damage.clear();
                self.stats.skipped_frames +%= 1;
                return .unchanged;
            }
        }

        const use_indexed8 = self.surface.format() == .indexed8 and backend.supports_indexed8;
        var shared_generation: ?u64 = null;
        if (wants_shared_raster) {
            const prepared = self.prepareSharedRaster(backend, shared_info.?);
            if (prepared.result == abi.gui_frame_result_ok) {
                shared_generation = prepared.generation;
            } else {
                self.stats.shared_raster_fallback_frames +%= 1;
                if (prepared.result == abi.gui_frame_error_state) self.stats.shared_raster_backpressure_fallbacks +%= 1;
            }
        }

        var rendered = RenderResult{};
        var committed_shared_raster = false;
        while (true) {
            const begun = backend.begin(mode, destination_regions[0..destination_count]);
            if (begun < 0) return .{ .failure = begun };
            if (mode != .damage) {
                const cleared = backend.clear(letterbox_rgb);
                if (cleared < 0) {
                    backend.cancel();
                    return .{ .failure = cleared };
                }
            }

            rendered = .{};
            if (shared_generation) |generation| {
                rendered = renderSharedRaster(self.surface, viewport, self.shared_handle, generation, backend);
            } else {
                for (render_regions) |source_region| {
                    const region_result = if (use_xrgb32_nearest)
                        renderXrgb32Nearest(self.surface, viewport, source_region, self.scratch, backend)
                    else if (use_indexed8)
                        renderIndexed8(self.surface, viewport, source_region, self.scratch, backend)
                    else if (viewport.isInteger())
                        renderInteger(self.surface, viewport, source_region, self.scratch, backend)
                    else
                        renderFractional(self.surface, viewport, source_region, self.scratch, backend);
                    rendered.add(region_result);
                    if (rendered.failure != 0) break;
                }
            }
            if (rendered.failure != 0) {
                backend.cancel();
                if (shared_generation != null) {
                    shared_generation = null;
                    self.stats.shared_raster_fallback_frames +%= 1;
                    continue;
                }
                return .{ .failure = rendered.failure };
            }
            const committed = backend.commit(mode);
            if (committed < 0) {
                backend.cancel();
                if (shared_generation != null) {
                    shared_generation = null;
                    self.stats.shared_raster_fallback_frames +%= 1;
                    continue;
                }
                return .{ .failure = committed };
            }
            committed_shared_raster = shared_generation != null;
            break;
        }

        self.has_frame = true;
        self.last_viewport = viewport;
        self.damage.clear();
        self.stats.published_frames +%= 1;
        self.stats.damage_regions +%= changed_regions.len;
        self.stats.raster_blocks +%= rendered.blocks;
        self.stats.sampled_pixels +%= rendered.sampled_pixels;
        self.stats.indexed8_blocks +%= rendered.indexed8_blocks;
        self.stats.indexed8_resource_bytes +%= rendered.indexed8_resource_bytes;
        self.stats.xrgb32_nearest_blocks +%= rendered.xrgb32_nearest_blocks;
        self.stats.xrgb32_nearest_resource_bytes +%= rendered.xrgb32_nearest_resource_bytes;
        self.stats.shared_raster_blocks +%= rendered.shared_raster_blocks;
        self.stats.shared_raster_descriptor_bytes +%= rendered.shared_raster_descriptor_bytes;
        if (committed_shared_raster) {
            self.stats.shared_raster_frames +%= 1;
        } else {
            if (use_indexed8) self.stats.indexed8_frames +%= 1 else if (self.surface.format() == .indexed8) self.stats.xrgb_fallback_frames +%= 1;
            if (use_xrgb32_nearest) self.stats.xrgb32_nearest_frames +%= 1 else if (self.surface.format() == .xrgb32) self.stats.xrgb_fallback_frames +%= 1;
        }
        switch (mode) {
            .full => {
                self.stats.full_frames +%= 1;
                self.damage_chain = 1;
                if (compacted) self.stats.compacted_frames +%= 1;
            },
            .damage => {
                self.stats.damage_frames +%= 1;
                self.damage_chain +|= 1;
            },
            .replace => {
                self.stats.replacement_frames +%= 1;
                self.damage_chain = 1;
            },
        }
        return .{ .presented = .{
            .mode = mode,
            .viewport = viewport,
            .damage_regions = @intCast(changed_regions.len),
            .raster_blocks = rendered.blocks,
            .sampled_pixels = rendered.sampled_pixels,
        } };
    }

    pub fn deinit(self: *Presenter, backend: Backend) void {
        self.dropSharedRaster(backend);
    }

    fn dropSharedRaster(self: *Presenter, backend: Backend) void {
        if (self.shared_handle.id != 0) _ = backend.sharedRasterDestroy(&self.shared_handle);
        self.shared_handle = .{};
        self.shared_info = .{};
    }

    fn prepareSharedRaster(self: *Presenter, backend: Backend, info: abi.GuiSharedRasterCreateInfo) SharedRasterPrepareResult {
        if (self.shared_handle.id != 0 and !sameSharedRasterInfo(self.shared_info, info)) self.dropSharedRaster(backend);
        if (self.shared_handle.id == 0) {
            var handle: abi.GuiSharedRasterHandle = .{};
            const created = backend.sharedRasterCreate(&info, &handle);
            if (created != abi.gui_frame_result_ok) return .{ .result = created };
            if (handle.id == 0 or handle.generation == 0) return .{ .result = abi.gui_frame_error_invalid };
            self.shared_handle = handle;
            self.shared_info = info;
        }

        var map: abi.GuiSharedRasterWriteMap = .{};
        const mapped = backend.sharedRasterMapWrite(&self.shared_handle, &map);
        if (mapped != abi.gui_frame_result_ok) return .{ .result = mapped };
        if (!validSharedRasterWriteMap(map, self.shared_handle, info)) {
            self.dropSharedRaster(backend);
            return .{ .result = abi.gui_frame_error_invalid };
        }
        const destination_pointer: [*]u8 = @ptrFromInt(map.data_address);
        if (!copySurfaceToSharedRaster(self.surface, destination_pointer[0..@as(usize, @intCast(map.byte_length))], info)) {
            self.dropSharedRaster(backend);
            return .{ .result = abi.gui_frame_error_invalid };
        }
        var generation: u64 = 0;
        const published = backend.sharedRasterPublish(&map, &generation);
        if (published != abi.gui_frame_result_ok or generation == 0) {
            self.dropSharedRaster(backend);
            return .{ .result = if (published == abi.gui_frame_result_ok) abi.gui_frame_error_invalid else published };
        }
        self.stats.shared_raster_published_bytes +%= info.data_bytes;
        return .{ .result = abi.gui_frame_result_ok, .generation = generation };
    }
};

const SharedRasterPrepareResult = struct {
    result: i32,
    generation: u64 = 0,
};

fn sharedRasterCreateInfo(surface: Surface) ?abi.GuiSharedRasterCreateInfo {
    const pixel_count = std.math.mul(u64, surface.width, surface.height) catch return null;
    return switch (surface.storage) {
        .xrgb32 => blk: {
            const stride = std.math.mul(u64, surface.width, @sizeOf(u32)) catch return null;
            const data_bytes = std.math.mul(u64, pixel_count, @sizeOf(u32)) catch return null;
            if (stride > std.math.maxInt(u32) or data_bytes > abi.gui_shared_raster_max_bytes) return null;
            break :blk .{
                .format = abi.gui_shared_raster_format_xrgb32,
                .width = surface.width,
                .height = surface.height,
                .stride_bytes = @intCast(stride),
                .data_bytes = data_bytes,
            };
        },
        .indexed8 => blk: {
            const data_bytes = std.math.add(u64, abi.gui_indexed8_pixels_offset, pixel_count) catch return null;
            if (data_bytes > abi.gui_shared_raster_max_bytes) return null;
            break :blk .{
                .format = abi.gui_shared_raster_format_indexed8,
                .width = surface.width,
                .height = surface.height,
                .stride_bytes = surface.width,
                .data_offset = abi.gui_indexed8_pixels_offset,
                .data_bytes = data_bytes,
            };
        },
    };
}

fn sameSharedRasterInfo(a: abi.GuiSharedRasterCreateInfo, b: abi.GuiSharedRasterCreateInfo) bool {
    return a.version == b.version and a.size == b.size and a.format == b.format and a.width == b.width and
        a.height == b.height and a.stride_bytes == b.stride_bytes and a.data_offset == b.data_offset and
        a.flags == b.flags and a.data_bytes == b.data_bytes;
}

fn validSharedRasterWriteMap(map: abi.GuiSharedRasterWriteMap, handle: abi.GuiSharedRasterHandle, info: abi.GuiSharedRasterCreateInfo) bool {
    return map.version >= abi.gui_shared_raster_write_map_version and map.size >= abi.gui_shared_raster_write_map_size and
        map.handle.id == handle.id and map.handle.generation == handle.generation and map.data_address != 0 and
        map.byte_length == info.data_bytes and map.write_token != 0 and map.buffer_index < abi.gui_shared_raster_buffer_count and
        map.reserved0 == 0;
}

fn copySurfaceToSharedRaster(surface: Surface, destination: []u8, info: abi.GuiSharedRasterCreateInfo) bool {
    if (destination.len != info.data_bytes) return false;
    switch (surface.storage) {
        .xrgb32 => |pixels| {
            const source = std.mem.sliceAsBytes(pixels);
            if (source.len != destination.len) return false;
            @memcpy(destination, source);
        },
        .indexed8 => |indexed| {
            const palette = std.mem.sliceAsBytes(indexed.palette);
            const data_offset: usize = @intCast(info.data_offset);
            if (palette.len != data_offset or data_offset + indexed.pixels.len != destination.len) return false;
            @memcpy(destination[0..data_offset], palette);
            @memcpy(destination[data_offset..], indexed.pixels);
        },
    }
    return true;
}

pub const MouseAction = enum {
    down,
    up,
    move,
};

pub const KeyTextMode = enum {
    /// Preserve both the physical key event and the derived text event.
    key_and_text,
    /// Emit printable keys only as text. This is suitable for guests such as
    /// BASIC whose key path accepts controls while its text path accepts
    /// printable characters.
    text_only,
};

pub const PointerMode = enum {
    mapped,
    ignored,
};

pub const InputPolicy = struct {
    key_text_mode: KeyTextMode = .key_and_text,
    pointer_mode: PointerMode = .mapped,

    pub const text_only_no_pointer: InputPolicy = .{
        .key_text_mode = .text_only,
        .pointer_mode = .ignored,
    };
};

pub const InputStamp = struct {
    sequence: u64,
    tick: u64,
};

pub const InputFilterReason = enum {
    none,
    pointer_ignored,
    duplicate_focus,
    duplicate_physical_down,
    unexpected_physical_up,
    invalid_physical_key,
    missing_geometry,
    unsupported_raw,
};

pub const InputTranslationStats = struct {
    raw_events: u64 = 0,
    logical_events: u64 = 0,
    pending_text_created: u64 = 0,
    pending_text_emitted: u64 = 0,
    mouse_events: u64 = 0,
    mouse_moves: u64 = 0,
    mouse_mappings: u64 = 0,
    physical_key_downs: u64 = 0,
    physical_key_ups: u64 = 0,
    physical_key_repeats: u64 = 0,
    synthesized_physical_key_ups: u64 = 0,
    filtered_events: u64 = 0,
    pointer_ignored: u64 = 0,
    duplicate_focus: u64 = 0,
    duplicate_physical_down: u64 = 0,
    unexpected_physical_up: u64 = 0,
    invalid_physical_key: u64 = 0,
    missing_geometry: u64 = 0,
    unsupported_raw: u64 = 0,
    last_raw_sequence: u64 = 0,
    last_raw_tick: u64 = 0,
    last_logical_sequence: u64 = 0,
    last_logical_tick: u64 = 0,
    last_filtered_sequence: u64 = 0,
    last_filtered_tick: u64 = 0,
    last_filter_reason: InputFilterReason = .none,
};

pub const HostStats = struct {
    window_info_calls: u64 = 0,
    present_window_info_calls: u64 = 0,
    input_window_info_calls: u64 = 0,
    viewport_calculations: u64 = 0,
    present_viewport_calculations: u64 = 0,
    input_viewport_calculations: u64 = 0,
};

pub const KeyEvent = struct {
    code: u32,
    modifiers: u32,
    tick: u64,
    sequence: u64 = 0,
};

pub const PhysicalKeyEvent = struct {
    key: u32,
    modifiers: u32,
    flags: u32,
    tick: u64,
    sequence: u64 = 0,
};

pub const TextEvent = struct {
    codepoint: u32,
    modifiers: u32,
    tick: u64,
    sequence: u64 = 0,
};

pub const MouseEvent = struct {
    action: MouseAction,
    client_x: i32,
    client_y: i32,
    guest: ?Point,
    buttons: u32,
    modifiers: u32,
    tick: u64,
    sequence: u64 = 0,
};

pub const ResizeEvent = struct {
    client: Size,
    viewport: Viewport,
    tick: u64,
    sequence: u64 = 0,
};

pub const FocusEvent = struct {
    focused: bool,
    tick: u64,
    sequence: u64 = 0,
};

pub const CloseEvent = struct {
    tick: u64,
    sequence: u64 = 0,
};

pub const InputEvent = union(enum) {
    close: CloseEvent,
    resize: ResizeEvent,
    focus: FocusEvent,
    key_down: KeyEvent,
    physical_key_down: PhysicalKeyEvent,
    physical_key_up: PhysicalKeyEvent,
    text: TextEvent,
    mouse: MouseEvent,

    pub fn stamp(self: InputEvent) InputStamp {
        return switch (self) {
            .close => |event| .{ .sequence = event.sequence, .tick = event.tick },
            .resize => |event| .{ .sequence = event.sequence, .tick = event.tick },
            .focus => |event| .{ .sequence = event.sequence, .tick = event.tick },
            .key_down => |event| .{ .sequence = event.sequence, .tick = event.tick },
            .physical_key_down => |event| .{ .sequence = event.sequence, .tick = event.tick },
            .physical_key_up => |event| .{ .sequence = event.sequence, .tick = event.tick },
            .text => |event| .{ .sequence = event.sequence, .tick = event.tick },
            .mouse => |event| .{ .sequence = event.sequence, .tick = event.tick },
        };
    }
};

pub const InputTranslator = struct {
    policy: InputPolicy = .{},
    focused: bool = false,
    pending_text: ?TextEvent = null,
    held_physical_keys: [256]bool = .{false} ** 256,
    pending_release_cursor: ?u16 = null,
    pending_release_tick: u64 = 0,
    next_sequence: u64 = 1,
    stats: InputTranslationStats = .{},

    pub fn init(policy: InputPolicy) InputTranslator {
        return .{ .policy = policy };
    }

    pub fn setPolicy(self: *InputTranslator, policy: InputPolicy) void {
        self.policy = policy;
        self.pending_text = null;
    }

    pub fn requiresViewport(self: *const InputTranslator, raw_kind: u32) bool {
        return raw_kind == @intFromEnum(abi.GuiEventKind.resize) or
            (self.policy.pointer_mode == .mapped and isMouseKind(raw_kind));
    }

    pub fn takePending(self: *InputTranslator) ?InputEvent {
        if (self.pending_text) |value| {
            self.pending_text = null;
            self.recordLogical(value.sequence, value.tick);
            self.stats.pending_text_emitted +%= 1;
            return .{ .text = value };
        }
        if (self.pending_release_cursor) |start| {
            var index: usize = start;
            while (index < self.held_physical_keys.len) : (index += 1) {
                if (!self.held_physical_keys[index]) continue;
                self.held_physical_keys[index] = false;
                self.pending_release_cursor = @intCast(index + 1);
                self.stats.synthesized_physical_key_ups +%= 1;
                return self.logical(.{ .physical_key_up = .{
                    .key = @intCast(index),
                    .modifiers = 0,
                    .flags = 0,
                    .tick = self.pending_release_tick,
                    .sequence = self.allocateSequence(),
                } });
            }
            self.pending_release_cursor = null;
            self.pending_release_tick = 0;
        }
        return null;
    }

    pub fn translate(self: *InputTranslator, raw: abi.GuiEvent, viewport: ?Viewport, resize_size: ?Size) ?InputEvent {
        const sequence = self.allocateSequence();
        self.stats.raw_events +%= 1;
        self.stats.last_raw_sequence = sequence;
        self.stats.last_raw_tick = raw.tick;
        const kind = raw.kind;
        if (kind == @intFromEnum(abi.GuiEventKind.close)) return self.logical(.{ .close = .{
            .tick = raw.tick,
            .sequence = sequence,
        } });
        if (kind == @intFromEnum(abi.GuiEventKind.resize)) {
            const size = resize_size orelse return self.filtered(sequence, raw.tick, .missing_geometry);
            const view = viewport orelse return self.filtered(sequence, raw.tick, .missing_geometry);
            return self.logical(.{ .resize = .{
                .client = size,
                .viewport = view,
                .tick = raw.tick,
                .sequence = sequence,
            } });
        }
        if (kind == @intFromEnum(abi.GuiEventKind.focus_gained)) {
            if (self.focused) return self.filtered(sequence, raw.tick, .duplicate_focus);
            self.focused = true;
            return self.logical(.{ .focus = .{ .focused = true, .tick = raw.tick, .sequence = sequence } });
        }
        if (kind == @intFromEnum(abi.GuiEventKind.focus_lost)) {
            if (!self.focused) return self.filtered(sequence, raw.tick, .duplicate_focus);
            self.focused = false;
            self.releaseHeldPhysicalKeys(raw.tick);
            return self.logical(.{ .focus = .{ .focused = false, .tick = raw.tick, .sequence = sequence } });
        }
        if (kind == @intFromEnum(abi.GuiEventKind.physical_key_reset)) {
            self.releaseHeldPhysicalKeys(raw.tick);
            return self.takePending() orelse self.filtered(sequence, raw.tick, .unexpected_physical_up);
        }
        if (kind == @intFromEnum(abi.GuiEventKind.physical_key_down) or
            kind == @intFromEnum(abi.GuiEventKind.physical_key_up))
        {
            if (raw.key == 0 or raw.key >= @as(u32, @intCast(self.held_physical_keys.len))) {
                return self.filtered(sequence, raw.tick, .invalid_physical_key);
            }
            const index: usize = @intCast(raw.key);
            if (kind == @intFromEnum(abi.GuiEventKind.physical_key_down)) {
                if (self.held_physical_keys[index]) {
                    if ((raw.buttons & abi.physical_key_flag_repeat) == 0) {
                        return self.filtered(sequence, raw.tick, .duplicate_physical_down);
                    }
                    self.stats.physical_key_downs +%= 1;
                    self.stats.physical_key_repeats +%= 1;
                    return self.logical(.{ .physical_key_down = .{
                        .key = raw.key,
                        .modifiers = raw.modifiers,
                        .flags = raw.buttons,
                        .tick = raw.tick,
                        .sequence = sequence,
                    } });
                }
                self.held_physical_keys[index] = true;
                self.stats.physical_key_downs +%= 1;
                return self.logical(.{ .physical_key_down = .{
                    .key = raw.key,
                    .modifiers = raw.modifiers,
                    .flags = raw.buttons,
                    .tick = raw.tick,
                    .sequence = sequence,
                } });
            }
            if (!self.held_physical_keys[index]) return self.filtered(sequence, raw.tick, .unexpected_physical_up);
            self.held_physical_keys[index] = false;
            self.stats.physical_key_ups +%= 1;
            return self.logical(.{ .physical_key_up = .{
                .key = raw.key,
                .modifiers = raw.modifiers,
                .flags = raw.buttons,
                .tick = raw.tick,
                .sequence = sequence,
            } });
        }
        if (kind == @intFromEnum(abi.GuiEventKind.key_down)) {
            if (isTextCodepoint(raw.key) and self.policy.key_text_mode == .text_only) {
                return self.logical(.{ .text = .{
                    .codepoint = raw.key,
                    .modifiers = raw.modifiers,
                    .tick = raw.tick,
                    .sequence = sequence,
                } });
            }
            if (isTextCodepoint(raw.key)) {
                self.pending_text = .{
                    .codepoint = raw.key,
                    .modifiers = raw.modifiers,
                    .tick = raw.tick,
                    .sequence = sequence,
                };
                self.stats.pending_text_created +%= 1;
            }
            return self.logical(.{ .key_down = .{
                .code = raw.key,
                .modifiers = raw.modifiers,
                .tick = raw.tick,
                .sequence = sequence,
            } });
        }
        const action: MouseAction = if (kind == @intFromEnum(abi.GuiEventKind.mouse_down))
            .down
        else if (kind == @intFromEnum(abi.GuiEventKind.mouse_up))
            .up
        else if (kind == @intFromEnum(abi.GuiEventKind.mouse_move))
            .move
        else
            return self.filtered(sequence, raw.tick, .unsupported_raw);
        self.stats.mouse_events +%= 1;
        if (action == .move) self.stats.mouse_moves +%= 1;
        if (self.policy.pointer_mode == .ignored) return self.filtered(sequence, raw.tick, .pointer_ignored);
        const guest = if (viewport) |value| blk: {
            self.stats.mouse_mappings +%= 1;
            break :blk value.mapClientPoint(raw.x, raw.y);
        } else null;
        return self.logical(.{ .mouse = .{
            .action = action,
            .client_x = raw.x,
            .client_y = raw.y,
            .guest = guest,
            .buttons = raw.buttons,
            .modifiers = raw.modifiers,
            .tick = raw.tick,
            .sequence = sequence,
        } });
    }

    fn logical(self: *InputTranslator, event: InputEvent) InputEvent {
        const event_stamp = event.stamp();
        self.recordLogical(event_stamp.sequence, event_stamp.tick);
        return event;
    }

    fn allocateSequence(self: *InputTranslator) u64 {
        const sequence = self.next_sequence;
        self.next_sequence +%= 1;
        if (self.next_sequence == 0) self.next_sequence = 1;
        return sequence;
    }

    fn releaseHeldPhysicalKeys(self: *InputTranslator, tick: u64) void {
        for (self.held_physical_keys) |held| {
            if (!held) continue;
            if (self.pending_release_cursor == null) self.pending_release_cursor = 0;
            self.pending_release_tick = tick;
            return;
        }
        self.pending_release_cursor = null;
        self.pending_release_tick = 0;
    }

    fn recordLogical(self: *InputTranslator, sequence: u64, tick: u64) void {
        self.stats.logical_events +%= 1;
        self.stats.last_logical_sequence = sequence;
        self.stats.last_logical_tick = tick;
    }

    fn filtered(self: *InputTranslator, sequence: u64, tick: u64, reason: InputFilterReason) ?InputEvent {
        self.stats.filtered_events +%= 1;
        self.stats.last_filtered_sequence = sequence;
        self.stats.last_filtered_tick = tick;
        self.stats.last_filter_reason = reason;
        switch (reason) {
            .none => {},
            .pointer_ignored => self.stats.pointer_ignored +%= 1,
            .duplicate_focus => self.stats.duplicate_focus +%= 1,
            .duplicate_physical_down => self.stats.duplicate_physical_down +%= 1,
            .unexpected_physical_up => self.stats.unexpected_physical_up +%= 1,
            .invalid_physical_key => self.stats.invalid_physical_key +%= 1,
            .missing_geometry => self.stats.missing_geometry +%= 1,
            .unsupported_raw => self.stats.unsupported_raw +%= 1,
        }
        return null;
    }
};

pub const Host = struct {
    desk: r4desk.Context,
    draw: r4draw.Context,
    video: Presenter,
    input: InputTranslator = .{},
    input_viewport: ?Viewport = null,
    stats: HostStats = .{},

    pub fn init(desk: r4desk.Context, draw: r4draw.Context, surface: Surface, scratch: []u32) Error!Host {
        if (!draw.supportsGuiFrameContract() or !draw.hasFn("gui_blit") or
            !draw.hasFn("gui_clear") or !draw.hasFn("gui_present")) return Error.UnsupportedDrawContract;
        if (desk.programWindowId() < 0) return Error.WindowUnavailable;
        return .{
            .desk = desk,
            .draw = draw,
            .video = try Presenter.init(surface, scratch),
        };
    }

    pub fn setTitle(self: *Host, title: [*:0]const u8) i32 {
        return self.desk.guiSetTitle(title);
    }

    pub fn setMinimumSize(self: *Host, width: i32, height: i32) i32 {
        return self.desk.guiSetMinSize(width, height);
    }

    pub fn setInputPolicy(self: *Host, policy: InputPolicy) void {
        self.input.setPolicy(policy);
    }

    pub fn present(self: *Host) PresentResult {
        var info: abi.GuiWindowInfo = .{};
        self.stats.window_info_calls +%= 1;
        self.stats.present_window_info_calls +%= 1;
        const window_result = self.desk.guiWindowInfo(&info);
        if (window_result < 0) return .{ .failure = window_result };
        if ((info.flags & abi.GuiWindowFlag.visible) == 0 or (info.flags & abi.GuiWindowFlag.minimized) != 0) return .hidden;
        self.stats.viewport_calculations +%= 1;
        self.stats.present_viewport_calculations +%= 1;
        const result = self.video.presentTo(Backend.fromDraw(&self.draw), info.client_w, info.client_h);
        switch (result) {
            .presented => |presented| self.input_viewport = presented.viewport,
            .unchanged => self.input_viewport = self.video.currentViewport(),
            else => {},
        }
        return result;
    }

    pub fn pollInput(self: *Host) ?InputEvent {
        if (self.input.takePending()) |event| return event;
        while (true) {
            var raw: abi.GuiEvent = .{};
            if (self.desk.guiPollEvent(&raw) <= 0) return null;

            var viewport = self.input_viewport orelse self.video.currentViewport();
            var resize_size: ?Size = null;
            const guest_mode_changed = if (viewport) |value|
                value.guest_w != self.video.surface.width or value.guest_h != self.video.surface.height
            else
                true;
            if (self.input.requiresViewport(raw.kind) and
                (raw.kind == @intFromEnum(abi.GuiEventKind.resize) or guest_mode_changed))
            {
                var info: abi.GuiWindowInfo = .{};
                self.stats.window_info_calls +%= 1;
                self.stats.input_window_info_calls +%= 1;
                if (self.desk.guiWindowInfo(&info) >= 0 and info.client_w > 0 and info.client_h > 0) {
                    const size = Size{ .w = @intCast(info.client_w), .h = @intCast(info.client_h) };
                    resize_size = size;
                    self.stats.viewport_calculations +%= 1;
                    self.stats.input_viewport_calculations +%= 1;
                    viewport = calculateViewport(info.client_w, info.client_h, self.video.surface.width, self.video.surface.height) catch null;
                    self.input_viewport = viewport;
                }
            }
            if (self.input.translate(raw, viewport, resize_size)) |event| return event;
        }
    }
};

fn isMouseKind(kind: u32) bool {
    return kind == @intFromEnum(abi.GuiEventKind.mouse_down) or
        kind == @intFromEnum(abi.GuiEventKind.mouse_up) or
        kind == @intFromEnum(abi.GuiEventKind.mouse_move);
}

const RenderResult = struct {
    blocks: u32 = 0,
    sampled_pixels: u64 = 0,
    indexed8_blocks: u64 = 0,
    indexed8_resource_bytes: u64 = 0,
    xrgb32_nearest_blocks: u64 = 0,
    xrgb32_nearest_resource_bytes: u64 = 0,
    shared_raster_blocks: u64 = 0,
    shared_raster_descriptor_bytes: u64 = 0,
    failure: i32 = 0,

    fn add(self: *RenderResult, other: RenderResult) void {
        self.blocks +|= other.blocks;
        self.sampled_pixels +|= other.sampled_pixels;
        self.indexed8_blocks +|= other.indexed8_blocks;
        self.indexed8_resource_bytes +|= other.indexed8_resource_bytes;
        self.xrgb32_nearest_blocks +|= other.xrgb32_nearest_blocks;
        self.xrgb32_nearest_resource_bytes +|= other.xrgb32_nearest_resource_bytes;
        self.shared_raster_blocks +|= other.shared_raster_blocks;
        self.shared_raster_descriptor_bytes +|= other.shared_raster_descriptor_bytes;
        if (self.failure == 0) self.failure = other.failure;
    }
};

fn renderSharedRaster(surface: Surface, viewport: Viewport, handle: abi.GuiSharedRasterHandle, generation: u64, backend: Backend) RenderResult {
    var result = RenderResult{};
    const format: u32 = switch (surface.storage) {
        .indexed8 => abi.gui_shared_raster_format_indexed8,
        .xrgb32 => abi.gui_shared_raster_format_xrgb32,
    };
    var tile_y: u32 = 0;
    while (tile_y < viewport.h) {
        const tile_h = @min(tile_max_height, viewport.h - tile_y);
        var tile_x: u32 = 0;
        while (tile_x < viewport.w) {
            const tile_w = @min(tile_max_width, viewport.w - tile_x);
            const command = abi.GuiFrameCommand{
                .kind = abi.gui_frame_command_kind_shared_raster,
                .x = viewport.x + @as(i32, @intCast(tile_x)),
                .y = viewport.y + @as(i32, @intCast(tile_y)),
                .w = tile_w,
                .h = tile_h,
                .resource_bytes = abi.gui_shared_raster_resource_size,
            };
            const resource = abi.GuiSharedRasterResource{
                .handle = handle,
                .raster_generation = generation,
                .format = format,
                .source_w = surface.width,
                .source_h = surface.height,
                .guest_w = surface.width,
                .guest_h = surface.height,
                .viewport_x = viewport.x,
                .viewport_y = viewport.y,
                .viewport_w = viewport.w,
                .viewport_h = viewport.h,
            };
            const raw = backend.sharedRaster(.{ .command = command, .resource = resource });
            if (raw < 0) {
                result.failure = raw;
                return result;
            }
            result.blocks +|= 1;
            result.shared_raster_blocks +|= 1;
            result.shared_raster_descriptor_bytes +|= abi.gui_shared_raster_resource_size;
            result.sampled_pixels +|= @as(u64, tile_w) * tile_h;
            tile_x += tile_w;
        }
        tile_y += tile_h;
    }
    return result;
}

fn renderInteger(surface: Surface, viewport: Viewport, damage: Rect, scratch: []u32, backend: Backend) RenderResult {
    const source = clipRect(damage, surface.width, surface.height) orelse return .{};
    var result = RenderResult{};
    var tile_y = source.y;
    const source_bottom = source.y + source.h;
    const source_right = source.x + source.w;
    while (tile_y < source_bottom) {
        const tile_h = @min(tile_max_height, source_bottom - tile_y);
        var tile_x = source.x;
        while (tile_x < source_right) {
            const tile_w = @min(tile_max_width, source_right - tile_x);
            const count = @as(usize, tile_w) * @as(usize, tile_h);
            fillGuestTile(surface, tile_x, tile_y, tile_w, tile_h, scratch[0..count]);
            const raw = backend.raster(
                viewport.x + @as(i32, @intCast(tile_x * viewport.integer_scale)),
                viewport.y + @as(i32, @intCast(tile_y * viewport.integer_scale)),
                tile_w,
                tile_h,
                viewport.integer_scale,
                scratch[0..count],
            );
            if (raw < 0) {
                result.failure = raw;
                return result;
            }
            result.blocks +|= 1;
            result.sampled_pixels +|= count;
            tile_x += tile_w;
        }
        tile_y += tile_h;
    }
    return result;
}

fn renderFractional(surface: Surface, viewport: Viewport, damage: Rect, scratch: []u32, backend: Backend) RenderResult {
    const destination = mapDamageToViewport(damage, surface.width, surface.height, viewport.w, viewport.h) orelse return .{};
    var result = RenderResult{};
    var tile_y = destination.y;
    const destination_bottom = destination.y + destination.h;
    const destination_right = destination.x + destination.w;
    while (tile_y < destination_bottom) {
        const tile_h = @min(tile_max_height, destination_bottom - tile_y);
        var tile_x = destination.x;
        while (tile_x < destination_right) {
            const tile_w = @min(tile_max_width, destination_right - tile_x);
            const count = @as(usize, tile_w) * @as(usize, tile_h);
            fillScaledTile(surface, viewport, tile_x, tile_y, tile_w, tile_h, scratch[0..count]);
            const raw = backend.raster(
                viewport.x + @as(i32, @intCast(tile_x)),
                viewport.y + @as(i32, @intCast(tile_y)),
                tile_w,
                tile_h,
                1,
                scratch[0..count],
            );
            if (raw < 0) {
                result.failure = raw;
                return result;
            }
            result.blocks +|= 1;
            result.sampled_pixels +|= count;
            tile_x += tile_w;
        }
        tile_y += tile_h;
    }
    return result;
}

fn renderIndexed8(surface: Surface, viewport: Viewport, damage: Rect, scratch: []u32, backend: Backend) RenderResult {
    const destination = mapDamageToViewport(damage, surface.width, surface.height, viewport.w, viewport.h) orelse return .{};
    const indexed = switch (surface.storage) {
        .indexed8 => |value| value,
        .xrgb32 => return .{},
    };
    const resource_scratch = std.mem.sliceAsBytes(scratch);
    var result = RenderResult{};
    var tile_y = destination.y;
    const destination_bottom = destination.y + destination.h;
    const destination_right = destination.x + destination.w;
    while (tile_y < destination_bottom) {
        const tile_h = indexedTileExtent(tile_y, destination_bottom - tile_y, surface.height, viewport.h);
        var tile_x = destination.x;
        while (tile_x < destination_right) {
            const tile_w = indexedTileExtent(tile_x, destination_right - tile_x, surface.width, viewport.w);
            const source = sourceRectForDestination(tile_x, tile_y, tile_w, tile_h, surface.width, surface.height, viewport.w, viewport.h);
            const pixel_bytes = @as(usize, source.w) * @as(usize, source.h);
            const resource_len = @as(usize, abi.gui_indexed8_pixels_offset) + pixel_bytes;
            if (resource_len > resource_scratch.len) return .{ .failure = abi.gui_frame_error_overflow };

            var header = abi.GuiIndexed8Resource{
                .source_x = source.x,
                .source_y = source.y,
                .source_w = source.w,
                .source_h = source.h,
                .guest_w = surface.width,
                .guest_h = surface.height,
                .viewport_x = viewport.x,
                .viewport_y = viewport.y,
                .viewport_w = viewport.w,
                .viewport_h = viewport.h,
                .pixel_stride = source.w,
            };
            @memcpy(resource_scratch[0..@sizeOf(abi.GuiIndexed8Resource)], std.mem.asBytes(&header));
            var palette_index: usize = 0;
            while (palette_index < palette_entries) : (palette_index += 1) {
                var color = indexed.palette[palette_index] & 0x00FF_FFFF;
                const offset = @as(usize, abi.gui_indexed8_palette_offset) + palette_index * @sizeOf(u32);
                @memcpy(resource_scratch[offset .. offset + @sizeOf(u32)], std.mem.asBytes(&color));
            }
            var row: u32 = 0;
            while (row < source.h) : (row += 1) {
                const source_offset = @as(usize, source.y + row) * @as(usize, surface.width) + source.x;
                const destination_offset = @as(usize, abi.gui_indexed8_pixels_offset) + @as(usize, row) * @as(usize, source.w);
                @memcpy(
                    resource_scratch[destination_offset .. destination_offset + source.w],
                    indexed.pixels[source_offset .. source_offset + source.w],
                );
            }
            const command = abi.GuiFrameCommand{
                .kind = abi.gui_frame_command_kind_indexed8,
                .x = viewport.x + @as(i32, @intCast(tile_x)),
                .y = viewport.y + @as(i32, @intCast(tile_y)),
                .w = tile_w,
                .h = tile_h,
                .resource_bytes = resource_len,
            };
            const raw = backend.indexed8(.{ .command = command, .resource = resource_scratch[0..resource_len] });
            if (raw < 0) {
                result.failure = raw;
                return result;
            }
            result.blocks +|= 1;
            result.indexed8_blocks +|= 1;
            result.indexed8_resource_bytes +|= resource_len;
            result.sampled_pixels +|= @as(u64, tile_w) * tile_h;
            tile_x += tile_w;
        }
        tile_y += tile_h;
    }
    return result;
}

fn renderXrgb32Nearest(surface: Surface, viewport: Viewport, damage: Rect, scratch: []u32, backend: Backend) RenderResult {
    const destination = mapDamageToViewport(damage, surface.width, surface.height, viewport.w, viewport.h) orelse return .{};
    const pixels = switch (surface.storage) {
        .xrgb32 => |value| value,
        .indexed8 => return .{},
    };
    const header_words = @sizeOf(abi.GuiXrgb32Resource) / @sizeOf(u32);
    const resource_scratch = std.mem.sliceAsBytes(scratch);
    var result = RenderResult{};
    var tile_y = destination.y;
    const destination_bottom = destination.y + destination.h;
    const destination_right = destination.x + destination.w;
    while (tile_y < destination_bottom) {
        const tile_h = xrgbTileExtent(tile_y, destination_bottom - tile_y, surface.height, viewport.h, tile_max_height - 1);
        var tile_x = destination.x;
        while (tile_x < destination_right) {
            const tile_w = xrgbTileExtent(tile_x, destination_right - tile_x, surface.width, viewport.w, tile_max_width);
            const source = sourceRectForDestination(tile_x, tile_y, tile_w, tile_h, surface.width, surface.height, viewport.w, viewport.h);
            if (source.w > tile_max_width or source.h >= tile_max_height) return .{ .failure = abi.gui_frame_error_overflow };
            const source_pixels = @as(usize, source.w) * @as(usize, source.h);
            const resource_len = @as(usize, abi.gui_xrgb32_pixels_offset) + source_pixels * @sizeOf(u32);
            if (resource_len > resource_scratch.len or header_words + source_pixels > scratch.len) {
                return .{ .failure = abi.gui_frame_error_overflow };
            }

            var header = abi.GuiXrgb32Resource{
                .source_x = source.x,
                .source_y = source.y,
                .source_w = source.w,
                .source_h = source.h,
                .guest_w = surface.width,
                .guest_h = surface.height,
                .viewport_x = viewport.x,
                .viewport_y = viewport.y,
                .viewport_w = viewport.w,
                .viewport_h = viewport.h,
                .pixel_stride = source.w,
            };
            @memcpy(resource_scratch[0..@sizeOf(abi.GuiXrgb32Resource)], std.mem.asBytes(&header));
            var row: u32 = 0;
            while (row < source.h) : (row += 1) {
                const source_offset = @as(usize, source.y + row) * @as(usize, surface.width) + source.x;
                const destination_offset = header_words + @as(usize, row) * @as(usize, source.w);
                var column: usize = 0;
                while (column < source.w) : (column += 1) {
                    scratch[destination_offset + column] = pixels[source_offset + column] & 0x00FF_FFFF;
                }
            }
            const command = abi.GuiFrameCommand{
                .kind = abi.gui_frame_command_kind_xrgb32_nearest,
                .x = viewport.x + @as(i32, @intCast(tile_x)),
                .y = viewport.y + @as(i32, @intCast(tile_y)),
                .w = tile_w,
                .h = tile_h,
                .resource_bytes = resource_len,
            };
            const raw = backend.xrgb32Nearest(.{ .command = command, .resource = resource_scratch[0..resource_len] });
            if (raw < 0) {
                result.failure = raw;
                return result;
            }
            result.blocks +|= 1;
            result.xrgb32_nearest_blocks +|= 1;
            result.xrgb32_nearest_resource_bytes +|= resource_len;
            result.sampled_pixels +|= source_pixels;
            tile_x += tile_w;
        }
        tile_y += tile_h;
    }
    return result;
}

fn xrgbTileExtent(start: u32, remaining: u32, source_size: u32, destination_size: u32, max_source_span: u32) u32 {
    var extent = @min(tile_max_width, remaining);
    while (extent > 1 and sourceSpan(start, extent, source_size, destination_size) > max_source_span) extent -= 1;
    return extent;
}

fn indexedTileExtent(start: u32, remaining: u32, source_size: u32, destination_size: u32) u32 {
    var extent = @min(tile_max_width, remaining);
    while (extent > 1 and sourceSpan(start, extent, source_size, destination_size) > tile_max_width) {
        extent = @max(@as(u32, 1), extent / 2);
    }
    return extent;
}

fn sourceSpan(start: u32, extent: u32, source_size: u32, destination_size: u32) u32 {
    const first = (@as(u64, start) * source_size) / destination_size;
    const last = (@as(u64, start + extent - 1) * source_size) / destination_size;
    return @intCast(last - first + 1);
}

fn sourceRectForDestination(x: u32, y: u32, w: u32, h: u32, source_w: u32, source_h: u32, destination_w: u32, destination_h: u32) Rect {
    const first_x: u32 = @intCast((@as(u64, x) * source_w) / destination_w);
    const first_y: u32 = @intCast((@as(u64, y) * source_h) / destination_h);
    return .{
        .x = first_x,
        .y = first_y,
        .w = sourceSpan(x, w, source_w, destination_w),
        .h = sourceSpan(y, h, source_h, destination_h),
    };
}

fn fillGuestTile(surface: Surface, start_x: u32, start_y: u32, width: u32, height: u32, out: []u32) void {
    var y: u32 = 0;
    while (y < height) : (y += 1) {
        var x: u32 = 0;
        while (x < width) : (x += 1) {
            out[@as(usize, y) * @as(usize, width) + @as(usize, x)] = surface.colorAt(start_x + x, start_y + y);
        }
    }
}

fn fillScaledTile(surface: Surface, viewport: Viewport, start_x: u32, start_y: u32, width: u32, height: u32, out: []u32) void {
    const x_step = surface.width / viewport.w;
    const x_remainder_step = surface.width % viewport.w;
    const x_start_numerator = @as(u64, start_x) * surface.width;
    const x_start: u32 = @intCast(x_start_numerator / viewport.w);
    const x_start_remainder: u32 = @intCast(x_start_numerator % viewport.w);
    const y_step = surface.height / viewport.h;
    const y_remainder_step = surface.height % viewport.h;
    const y_start_numerator = @as(u64, start_y) * surface.height;
    var source_y: u32 = @intCast(y_start_numerator / viewport.h);
    var y_remainder: u32 = @intCast(y_start_numerator % viewport.h);
    var y: u32 = 0;
    while (y < height) : (y += 1) {
        var source_x = x_start;
        var x_remainder = x_start_remainder;
        var x: u32 = 0;
        while (x < width) : (x += 1) {
            out[@as(usize, y) * @as(usize, width) + @as(usize, x)] = surface.colorAt(source_x, source_y);
            source_x += x_step;
            x_remainder += x_remainder_step;
            if (x_remainder >= viewport.w) {
                x_remainder -= viewport.w;
                source_x += 1;
            }
        }
        source_y += y_step;
        y_remainder += y_remainder_step;
        if (y_remainder >= viewport.h) {
            y_remainder -= viewport.h;
            source_y += 1;
        }
    }
}

fn requiredPixels(width: u32, height: u32) Error!usize {
    if (width == 0 or height == 0) return Error.InvalidSize;
    const total = std.math.mul(u64, width, height) catch return Error.Overflow;
    if (total > std.math.maxInt(usize)) return Error.Overflow;
    return @intCast(total);
}

fn clipRect(value: Rect, width: u32, height: u32) ?Rect {
    if (value.isEmpty() or value.x >= width or value.y >= height) return null;
    const right = @min(@as(u64, width), @as(u64, value.x) + value.w);
    const bottom = @min(@as(u64, height), @as(u64, value.y) + value.h);
    if (right <= value.x or bottom <= value.y) return null;
    return .{
        .x = value.x,
        .y = value.y,
        .w = @intCast(right - value.x),
        .h = @intCast(bottom - value.y),
    };
}

fn mergeRect(a: Rect, b: Rect) Rect {
    const x = @min(a.x, b.x);
    const y = @min(a.y, b.y);
    const right = @max(@as(u64, a.x) + a.w, @as(u64, b.x) + b.w);
    const bottom = @max(@as(u64, a.y) + a.h, @as(u64, b.y) + b.h);
    return .{ .x = x, .y = y, .w = @intCast(right - x), .h = @intCast(bottom - y) };
}

fn rectArea(value: Rect) u64 {
    return @as(u64, value.w) * value.h;
}

fn rectsTouchOrOverlap(a: Rect, b: Rect) bool {
    const a_right = @as(u64, a.x) + a.w;
    const a_bottom = @as(u64, a.y) + a.h;
    const b_right = @as(u64, b.x) + b.w;
    const b_bottom = @as(u64, b.y) + b.h;
    return @as(u64, a.x) <= b_right and @as(u64, b.x) <= a_right and
        @as(u64, a.y) <= b_bottom and @as(u64, b.y) <= a_bottom;
}

fn rectIsFull(value: Rect, width: u32, height: u32) bool {
    return value.x == 0 and value.y == 0 and value.w == width and value.h == height;
}

fn mapDamageToViewport(value: Rect, guest_w: u32, guest_h: u32, view_w: u32, view_h: u32) ?Rect {
    const clipped = clipRect(value, guest_w, guest_h) orelse return null;
    const left: u64 = (@as(u64, clipped.x) * view_w) / guest_w;
    const top: u64 = (@as(u64, clipped.y) * view_h) / guest_h;
    const source_right = @as(u64, clipped.x) + clipped.w;
    const source_bottom = @as(u64, clipped.y) + clipped.h;
    const right = divideCeil(source_right * view_w, guest_w);
    const bottom = divideCeil(source_bottom * view_h, guest_h);
    if (right <= left or bottom <= top) return null;
    return .{
        .x = @intCast(left),
        .y = @intCast(top),
        .w = @intCast(@min(@as(u64, view_w), right) - left),
        .h = @intCast(@min(@as(u64, view_h), bottom) - top),
    };
}

fn divideCeil(numerator: u64, denominator: u64) u64 {
    return numerator / denominator + @intFromBool(numerator % denominator != 0);
}

fn viewportEqual(a: Viewport, b: Viewport) bool {
    return a.x == b.x and a.y == b.y and a.w == b.w and a.h == b.h and
        a.guest_w == b.guest_w and a.guest_h == b.guest_h and a.integer_scale == b.integer_scale;
}

fn isTextCodepoint(value: u32) bool {
    if (value >= 0x20 and value <= 0x7E) return true;
    if (value < 0xA0 or value > 0x10FFFF) return false;
    return value < 0xD800 or value > 0xDFFF;
}

fn drawContext(context: *anyopaque) *const r4draw.Context {
    return @ptrCast(@alignCast(context));
}

fn drawBeginFull(context: *anyopaque) i32 {
    return drawContext(context).guiFrameBegin();
}

fn drawBeginDamage(context: *anyopaque, regions: []const abi.DisplayDamageRect) i32 {
    const draw = drawContext(context);
    if (!draw.supportsGuiFrameDamageContract()) return 0;
    return draw.guiFrameBeginDamage(regions);
}

fn drawBeginReplace(context: *anyopaque, regions: []const abi.DisplayDamageRect) i32 {
    const draw = drawContext(context);
    if (!draw.supportsGuiFrameStreamingContract()) return abi.err_no_fn;
    return draw.guiFrameBeginReplace(regions);
}

fn drawClear(context: *anyopaque, rgb: u32) i32 {
    return drawContext(context).guiClear(rgb);
}

fn drawRaster(context: *anyopaque, x: i32, y: i32, width: u32, height: u32, scale: u32, pixels: []const u32) i32 {
    return drawContext(context).guiBlit(x, y, width, height, scale, pixels);
}

fn drawIndexed8(context: *anyopaque, batch: IndexedBatch) i32 {
    return drawContext(context).guiFrameAppend(&.{batch.command}, batch.resource);
}

fn drawXrgb32Nearest(context: *anyopaque, batch: Xrgb32Batch) i32 {
    return drawContext(context).guiFrameAppend(&.{batch.command}, batch.resource);
}

fn drawSharedRasterCreate(context: *anyopaque, info: *const abi.GuiSharedRasterCreateInfo, out_handle: *abi.GuiSharedRasterHandle) i32 {
    return drawContext(context).guiSharedRasterCreate(info, out_handle);
}

fn drawSharedRasterDestroy(context: *anyopaque, handle: *const abi.GuiSharedRasterHandle) i32 {
    return drawContext(context).guiSharedRasterDestroy(handle);
}

fn drawSharedRasterMapWrite(context: *anyopaque, handle: *const abi.GuiSharedRasterHandle, out_map: *abi.GuiSharedRasterWriteMap) i32 {
    return drawContext(context).guiSharedRasterMapWrite(handle, out_map);
}

fn drawSharedRasterPublish(context: *anyopaque, map: *const abi.GuiSharedRasterWriteMap, out_generation: *u64) i32 {
    return drawContext(context).guiSharedRasterPublish(map, out_generation);
}

fn drawSharedRaster(context: *anyopaque, batch: SharedRasterBatch) i32 {
    return drawContext(context).guiFrameAppend(&.{batch.command}, std.mem.asBytes(&batch.resource));
}

fn drawCommitFull(context: *anyopaque) i32 {
    return drawContext(context).guiFrameCommit();
}

fn drawCommitDamage(context: *anyopaque) i32 {
    const draw = drawContext(context);
    return if (draw.supportsGuiFrameDamageContract()) draw.guiFrameCommit() else draw.guiPresent();
}

fn drawCancel(context: *anyopaque) i32 {
    return drawContext(context).guiFrameCancel();
}

const FakeBackend = struct {
    full_begins: u32 = 0,
    damage_begins: u32 = 0,
    replace_begins: u32 = 0,
    clears: u32 = 0,
    commits: u32 = 0,
    cancels: u32 = 0,
    rasters: u32 = 0,
    indexed8_rasters: u32 = 0,
    xrgb32_nearest_rasters: u32 = 0,
    shared_raster_creates: u32 = 0,
    shared_raster_destroys: u32 = 0,
    shared_raster_maps: u32 = 0,
    shared_raster_publishes: u32 = 0,
    shared_raster_commands: u32 = 0,
    damage_regions: u32 = 0,
    indexed8_resource_bytes: u64 = 0,
    xrgb32_nearest_resource_bytes: u64 = 0,
    shared_raster_descriptor_bytes: u64 = 0,
    indexed8_enabled: bool = false,
    xrgb32_nearest_enabled: bool = false,
    shared_raster_enabled: bool = false,
    shared_raster_map_result: i32 = abi.gui_frame_result_ok,
    shared_raster_append_result: i32 = abi.gui_frame_result_ok,
    shared_raster_memory: []u8 = &.{},
    shared_raster_info: abi.GuiSharedRasterCreateInfo = .{},
    shared_raster_handle: abi.GuiSharedRasterHandle = .{},
    shared_raster_generation: u64 = 0,
    max_w: u32 = 0,
    max_h: u32 = 0,
    last_scale: u32 = 0,
    invalid_raster: bool = false,
    captured: [16]u32 = .{0} ** 16,
    captured_len: usize = 0,
    captured_indexed_command: abi.GuiFrameCommand = .{},
    captured_indexed: [abi.gui_indexed8_pixels_offset + 16]u8 = .{0} ** (abi.gui_indexed8_pixels_offset + 16),
    captured_indexed_len: usize = 0,
    captured_xrgb32_command: abi.GuiFrameCommand = .{},
    captured_xrgb32: [abi.gui_xrgb32_pixels_offset + 16 * @sizeOf(u32)]u8 = .{0} ** (abi.gui_xrgb32_pixels_offset + 16 * @sizeOf(u32)),
    captured_xrgb32_len: usize = 0,

    fn backend(self: *FakeBackend) Backend {
        return .{
            .context = self,
            .begin_full_fn = fakeBeginFull,
            .begin_damage_fn = fakeBeginDamage,
            .begin_replace_fn = fakeBeginReplace,
            .clear_fn = fakeClear,
            .raster_fn = fakeRaster,
            .indexed8_fn = fakeIndexed8,
            .xrgb32_nearest_fn = fakeXrgb32Nearest,
            .shared_raster_create_fn = fakeSharedRasterCreate,
            .shared_raster_destroy_fn = fakeSharedRasterDestroy,
            .shared_raster_map_write_fn = fakeSharedRasterMapWrite,
            .shared_raster_publish_fn = fakeSharedRasterPublish,
            .shared_raster_fn = fakeSharedRaster,
            .commit_full_fn = fakeCommit,
            .commit_damage_fn = fakeCommit,
            .cancel_fn = fakeCancel,
            .supports_indexed8 = self.indexed8_enabled,
            .supports_xrgb32_nearest = self.xrgb32_nearest_enabled,
            .supports_shared_raster = self.shared_raster_enabled,
        };
    }
};

fn fakeState(context: *anyopaque) *FakeBackend {
    return @ptrCast(@alignCast(context));
}

fn fakeBeginFull(context: *anyopaque) i32 {
    fakeState(context).full_begins += 1;
    return 0;
}

fn fakeBeginDamage(context: *anyopaque, regions: []const abi.DisplayDamageRect) i32 {
    const self = fakeState(context);
    self.damage_begins += 1;
    self.damage_regions += @intCast(regions.len);
    return 0;
}

fn fakeBeginReplace(context: *anyopaque, regions: []const abi.DisplayDamageRect) i32 {
    const self = fakeState(context);
    self.replace_begins += 1;
    self.damage_regions += @intCast(regions.len);
    return 0;
}

fn fakeClear(context: *anyopaque, _: u32) i32 {
    fakeState(context).clears += 1;
    return 0;
}

fn fakeRaster(context: *anyopaque, _: i32, _: i32, width: u32, height: u32, scale: u32, pixels: []const u32) i32 {
    const self = fakeState(context);
    self.rasters += 1;
    self.max_w = @max(self.max_w, width);
    self.max_h = @max(self.max_h, height);
    self.last_scale = scale;
    const needed = @as(usize, width) * @as(usize, height);
    if (width == 0 or height == 0 or width > tile_max_width or height > tile_max_height or pixels.len != needed) self.invalid_raster = true;
    if (self.captured_len == 0) {
        self.captured_len = @min(self.captured.len, pixels.len);
        @memcpy(self.captured[0..self.captured_len], pixels[0..self.captured_len]);
    }
    return 0;
}

fn fakeIndexed8(context: *anyopaque, batch: IndexedBatch) i32 {
    const self = fakeState(context);
    self.indexed8_rasters += 1;
    self.indexed8_resource_bytes +%= batch.resource.len;
    if (batch.command.w == 0 or batch.command.h == 0 or
        batch.command.w > tile_max_width or batch.command.h > tile_max_height or
        batch.command.kind != abi.gui_frame_command_kind_indexed8 or
        batch.command.resource_bytes != batch.resource.len or
        batch.resource.len < abi.gui_indexed8_pixels_offset) self.invalid_raster = true;
    if (self.captured_indexed_len == 0) {
        self.captured_indexed_command = batch.command;
        self.captured_indexed_len = @min(self.captured_indexed.len, batch.resource.len);
        @memcpy(self.captured_indexed[0..self.captured_indexed_len], batch.resource[0..self.captured_indexed_len]);
    }
    return 0;
}

fn fakeXrgb32Nearest(context: *anyopaque, batch: Xrgb32Batch) i32 {
    const self = fakeState(context);
    self.xrgb32_nearest_rasters += 1;
    self.xrgb32_nearest_resource_bytes +%= batch.resource.len;
    if (batch.command.w == 0 or batch.command.h == 0 or
        batch.command.w > tile_max_width or batch.command.h > tile_max_height or
        batch.command.kind != abi.gui_frame_command_kind_xrgb32_nearest or
        batch.command.resource_bytes != batch.resource.len or
        batch.resource.len < abi.gui_xrgb32_pixels_offset) self.invalid_raster = true;
    if (self.captured_xrgb32_len == 0) {
        self.captured_xrgb32_command = batch.command;
        self.captured_xrgb32_len = @min(self.captured_xrgb32.len, batch.resource.len);
        @memcpy(self.captured_xrgb32[0..self.captured_xrgb32_len], batch.resource[0..self.captured_xrgb32_len]);
    }
    return 0;
}

fn fakeSharedRasterCreate(context: *anyopaque, info: *const abi.GuiSharedRasterCreateInfo, out_handle: *abi.GuiSharedRasterHandle) i32 {
    const self = fakeState(context);
    if (!self.shared_raster_enabled) return abi.err_no_fn;
    if (info.data_bytes > self.shared_raster_memory.len) return abi.gui_frame_error_oom;
    self.shared_raster_creates += 1;
    self.shared_raster_handle = .{ .id = 1, .generation = self.shared_raster_creates };
    self.shared_raster_info = info.*;
    out_handle.* = self.shared_raster_handle;
    return abi.gui_frame_result_ok;
}

fn fakeSharedRasterDestroy(context: *anyopaque, handle: *const abi.GuiSharedRasterHandle) i32 {
    const self = fakeState(context);
    if (handle.id != self.shared_raster_handle.id or handle.generation != self.shared_raster_handle.generation) return abi.gui_frame_error_stale;
    self.shared_raster_destroys += 1;
    self.shared_raster_handle = .{};
    return abi.gui_frame_result_ok;
}

fn fakeSharedRasterMapWrite(context: *anyopaque, handle: *const abi.GuiSharedRasterHandle, out_map: *abi.GuiSharedRasterWriteMap) i32 {
    const self = fakeState(context);
    if (self.shared_raster_map_result != abi.gui_frame_result_ok) return self.shared_raster_map_result;
    if (handle.id != self.shared_raster_handle.id or handle.generation != self.shared_raster_handle.generation) return abi.gui_frame_error_stale;
    self.shared_raster_maps += 1;
    out_map.* = .{
        .handle = handle.*,
        .data_address = @intFromPtr(self.shared_raster_memory.ptr),
        .byte_length = self.shared_raster_info.data_bytes,
        .write_token = self.shared_raster_maps,
    };
    return abi.gui_frame_result_ok;
}

fn fakeSharedRasterPublish(context: *anyopaque, map: *const abi.GuiSharedRasterWriteMap, out_generation: *u64) i32 {
    const self = fakeState(context);
    if (map.handle.id != self.shared_raster_handle.id or map.handle.generation != self.shared_raster_handle.generation or map.write_token == 0) {
        return abi.gui_frame_error_stale;
    }
    self.shared_raster_publishes += 1;
    self.shared_raster_generation += 1;
    out_generation.* = self.shared_raster_generation;
    return abi.gui_frame_result_ok;
}

fn fakeSharedRaster(context: *anyopaque, batch: SharedRasterBatch) i32 {
    const self = fakeState(context);
    if (self.shared_raster_append_result != abi.gui_frame_result_ok) return self.shared_raster_append_result;
    self.shared_raster_commands += 1;
    self.shared_raster_descriptor_bytes +%= @sizeOf(abi.GuiSharedRasterResource);
    if (batch.command.kind != abi.gui_frame_command_kind_shared_raster or
        batch.command.resource_bytes != abi.gui_shared_raster_resource_size or
        batch.resource.handle.id != self.shared_raster_handle.id or
        batch.resource.handle.generation != self.shared_raster_handle.generation or
        batch.resource.raster_generation != self.shared_raster_generation or batch.resource.format != self.shared_raster_info.format)
    {
        self.invalid_raster = true;
    }
    return abi.gui_frame_result_ok;
}

fn fakeCommit(context: *anyopaque) i32 {
    fakeState(context).commits += 1;
    return 0;
}

fn fakeCancel(context: *anyopaque) i32 {
    fakeState(context).cancels += 1;
    return 0;
}

test "legacy backend initializers keep optional streaming hooks unavailable" {
    var fake = FakeBackend{};
    const backend = Backend{
        .context = &fake,
        .begin_full_fn = fakeBeginFull,
        .begin_damage_fn = fakeBeginDamage,
        .clear_fn = fakeClear,
        .raster_fn = fakeRaster,
        .indexed8_fn = fakeIndexed8,
        .commit_full_fn = fakeCommit,
        .commit_damage_fn = fakeCommit,
        .cancel_fn = fakeCancel,
    };
    try std.testing.expect(!backend.supports_xrgb32_nearest);
    try std.testing.expect(!backend.supports_shared_raster);
    try std.testing.expectEqual(abi.err_no_fn, backend.begin(.replace, &.{}));
}

test "viewport preserves aspect ratio maps letterbox and prefers useful integer scales" {
    const gorillas = try calculateViewport(1280, 680, 640, 350);
    try std.testing.expectEqual(@as(u32, 1243), gorillas.w);
    try std.testing.expectEqual(@as(u32, 680), gorillas.h);
    try std.testing.expectEqual(@as(u32, 0), gorillas.integer_scale);
    try std.testing.expect(gorillas.mapClientPoint(gorillas.x - 1, gorillas.y) == null);
    try std.testing.expectEqual(Point{ .x = 0, .y = 0 }, gorillas.mapClientPoint(gorillas.x, gorillas.y).?);
    try std.testing.expectEqual(Point{ .x = 639, .y = 349 }, gorillas.mapClientPoint(gorillas.x + @as(i32, @intCast(gorillas.w)) - 1, gorillas.y + @as(i32, @intCast(gorillas.h)) - 1).?);

    const integer = try calculateViewport(1000, 700, 320, 200);
    try std.testing.expectEqual(@as(u32, 3), integer.integer_scale);
    try std.testing.expectEqual(@as(u32, 960), integer.w);
    try std.testing.expectEqual(@as(u32, 600), integer.h);

    const down = try calculateViewport(200, 200, 256, 224);
    try std.testing.expectEqual(@as(u32, 200), down.w);
    try std.testing.expectEqual(@as(u32, 175), down.h);
    try std.testing.expectEqual(@as(i32, 12), down.y);
}

test "640x350 full frame is split into fifteen bounded raster blocks and unchanged frames are skipped" {
    const pixels = try std.testing.allocator.alloc(u32, 640 * 350);
    defer std.testing.allocator.free(pixels);
    @memset(pixels, 0x00112233);
    const scratch = try std.testing.allocator.alloc(u32, tile_max_pixels);
    defer std.testing.allocator.free(scratch);
    var presenter = try Presenter.init(try Surface.initXrgb32(pixels, 640, 350), scratch);
    var fake = FakeBackend{};

    const first = presenter.presentTo(fake.backend(), 640, 350);
    switch (first) {
        .presented => |info| {
            try std.testing.expectEqual(PresentMode.full, info.mode);
            try std.testing.expectEqual(@as(u32, 15), info.raster_blocks);
        },
        else => return error.TestUnexpectedResult,
    }
    try std.testing.expectEqual(@as(u32, 15), fake.rasters);
    try std.testing.expect(!fake.invalid_raster);
    try std.testing.expectEqual(tile_max_width, fake.max_w);
    try std.testing.expectEqual(tile_max_height, fake.max_h);

    try std.testing.expect(presenter.presentTo(fake.backend(), 640, 350) == .unchanged);
    try std.testing.expectEqual(@as(u32, 15), fake.rasters);

    presenter.invalidate(.{ .x = 7, .y = 9, .w = 12, .h = 10 });
    const partial = presenter.presentTo(fake.backend(), 640, 350);
    switch (partial) {
        .presented => |info| {
            try std.testing.expectEqual(PresentMode.damage, info.mode);
            try std.testing.expectEqual(@as(u32, 1), info.raster_blocks);
        },
        else => return error.TestUnexpectedResult,
    }
    try std.testing.expectEqual(@as(u32, 1), fake.damage_begins);
    try std.testing.expectEqual(@as(u32, 16), fake.rasters);
}

test "bounded damage chains compact into a fresh full frame" {
    var pixels = [_]u32{0x00112233} ** (8 * 8);
    var scratch: [tile_max_pixels]u32 = undefined;
    var presenter = try Presenter.init(try Surface.initXrgb32(pixels[0..], 8, 8), scratch[0..]);
    var fake = FakeBackend{};

    try std.testing.expect(presenter.presentTo(fake.backend(), 8, 8) == .presented);
    var index: u32 = 0;
    while (index + 1 < max_damage_chain) : (index += 1) {
        presenter.invalidate(.{ .x = index % 8, .y = 0, .w = 1, .h = 1 });
        const result = presenter.presentTo(fake.backend(), 8, 8);
        try std.testing.expect(result.presented.mode == .damage);
    }

    presenter.invalidate(.{ .x = 0, .y = 1, .w = 1, .h = 1 });
    const compacted = presenter.presentTo(fake.backend(), 8, 8);
    try std.testing.expect(compacted.presented.mode == .full);
    try std.testing.expectEqual(@as(u64, 1), presenter.stats.compacted_frames);
    try std.testing.expectEqual(@as(u32, 2), fake.full_begins);
}

test "native xrgb32 transport keeps sixty four full-motion generations standalone" {
    const pixels = try std.testing.allocator.alloc(u32, 256 * 224);
    defer std.testing.allocator.free(pixels);
    @memset(pixels, 0xAA112233);
    var scratch: [tile_max_pixels]u32 = undefined;
    var presenter = try Presenter.init(try Surface.initXrgb32(pixels, 256, 224), scratch[0..]);
    var fake = FakeBackend{ .xrgb32_nearest_enabled = true };

    var frame: u32 = 0;
    while (frame < 64) : (frame += 1) {
        if (frame != 0) {
            pixels[frame] = 0xFF000000 | frame;
            presenter.invalidate(.{ .x = frame, .y = 0, .w = 1, .h = 1 });
        }
        const result = presenter.presentTo(fake.backend(), 256, 224);
        try std.testing.expect(result == .presented);
        try std.testing.expectEqual(if (frame == 0) PresentMode.full else PresentMode.replace, result.presented.mode);
        try std.testing.expectEqual(@as(u32, 4), result.presented.raster_blocks);
    }

    try std.testing.expectEqual(@as(u32, 1), fake.full_begins);
    try std.testing.expectEqual(@as(u32, 63), fake.replace_begins);
    try std.testing.expectEqual(@as(u32, 0), fake.damage_begins);
    try std.testing.expectEqual(@as(u32, 256), fake.xrgb32_nearest_rasters);
    try std.testing.expectEqual(@as(u32, 0), fake.rasters);
    try std.testing.expectEqual(@as(u64, 63), presenter.stats.replacement_frames);
    try std.testing.expectEqual(@as(u32, 1), presenter.damage_chain);
    try std.testing.expect(!fake.invalid_raster);

    var header: abi.GuiXrgb32Resource = .{};
    @memcpy(std.mem.asBytes(&header), fake.captured_xrgb32[0..@sizeOf(abi.GuiXrgb32Resource)]);
    try std.testing.expectEqual(@as(u32, 128), header.source_w);
    try std.testing.expectEqual(@as(u32, 127), header.source_h);
    var first_pixel: u32 = undefined;
    @memcpy(std.mem.asBytes(&first_pixel), fake.captured_xrgb32[abi.gui_xrgb32_pixels_offset .. abi.gui_xrgb32_pixels_offset + @sizeOf(u32)]);
    try std.testing.expectEqual(@as(u32, 0x00112233), first_pixel);
}

test "shared raster transport publishes sixty four full-motion frames with bounded descriptors" {
    const width: u32 = 256;
    const height: u32 = 224;
    const pixels = try std.testing.allocator.alloc(u32, @as(usize, width) * height);
    defer std.testing.allocator.free(pixels);
    @memset(pixels, 0xAA112233);
    const shared_memory = try std.testing.allocator.alloc(u8, pixels.len * @sizeOf(u32));
    defer std.testing.allocator.free(shared_memory);
    var scratch: [tile_max_pixels]u32 = undefined;
    var presenter = try Presenter.init(try Surface.initXrgb32(pixels, width, height), scratch[0..]);
    var fake = FakeBackend{
        .xrgb32_nearest_enabled = true,
        .shared_raster_enabled = true,
        .shared_raster_memory = shared_memory,
    };
    defer presenter.deinit(fake.backend());

    var frame: u32 = 0;
    while (frame < 64) : (frame += 1) {
        if (frame != 0) {
            pixels[frame] = 0xFF00_0000 | frame;
            presenter.invalidate(.{ .x = frame, .y = 0, .w = 1, .h = 1 });
        }
        const result = presenter.presentTo(fake.backend(), width, height);
        try std.testing.expect(result == .presented);
        try std.testing.expectEqual(if (frame == 0) PresentMode.full else PresentMode.replace, result.presented.mode);
        try std.testing.expectEqual(@as(u32, 4), result.presented.raster_blocks);
    }

    const frame_bytes = @as(u64, width) * height * @sizeOf(u32);
    const descriptor_bytes = @as(u64, 64 * 4) * abi.gui_shared_raster_resource_size;
    try std.testing.expectEqual(@as(u32, 1), fake.shared_raster_creates);
    try std.testing.expectEqual(@as(u32, 64), fake.shared_raster_maps);
    try std.testing.expectEqual(@as(u32, 64), fake.shared_raster_publishes);
    try std.testing.expectEqual(@as(u32, 256), fake.shared_raster_commands);
    try std.testing.expectEqual(descriptor_bytes, fake.shared_raster_descriptor_bytes);
    try std.testing.expect(descriptor_bytes * 100 < frame_bytes * 64);
    try std.testing.expectEqual(@as(u32, 0), fake.xrgb32_nearest_rasters);
    try std.testing.expectEqual(@as(u64, 64), presenter.stats.shared_raster_frames);
    try std.testing.expectEqual(frame_bytes * 64, presenter.stats.shared_raster_published_bytes);
    try std.testing.expectEqualSlices(u8, std.mem.sliceAsBytes(pixels), shared_memory);
    try std.testing.expect(!fake.invalid_raster);
}

test "shared raster backpressure falls back for the frame and preserves indexed bytes" {
    var palette: [palette_entries]u32 = .{0} ** palette_entries;
    palette[1] = 0xAA112233;
    palette[2] = 0xBB445566;
    var indices = [_]u8{ 1, 2, 2, 1 };
    var shared_memory: [abi.gui_indexed8_pixels_offset + indices.len]u8 = undefined;
    var scratch: [tile_max_pixels]u32 = undefined;
    var presenter = try Presenter.init(try Surface.initIndexed8(indices[0..], palette[0..], 2, 2), scratch[0..]);
    var fake = FakeBackend{
        .indexed8_enabled = true,
        .shared_raster_enabled = true,
        .shared_raster_memory = shared_memory[0..],
    };
    defer presenter.deinit(fake.backend());

    try std.testing.expect(presenter.presentTo(fake.backend(), 2, 2) == .presented);
    try std.testing.expectEqualSlices(u8, std.mem.sliceAsBytes(palette[0..]), shared_memory[0..abi.gui_indexed8_pixels_offset]);
    try std.testing.expectEqualSlices(u8, indices[0..], shared_memory[abi.gui_indexed8_pixels_offset..]);
    fake.shared_raster_map_result = abi.gui_frame_error_state;
    indices[0] = 2;
    presenter.invalidate(.{ .x = 0, .y = 0, .w = 1, .h = 1 });
    const fallback = presenter.presentTo(fake.backend(), 2, 2);
    try std.testing.expect(fallback == .presented);
    try std.testing.expectEqual(PresentMode.replace, fallback.presented.mode);
    try std.testing.expectEqual(@as(u32, 1), fake.indexed8_rasters);
    try std.testing.expectEqual(@as(u64, 1), presenter.stats.shared_raster_fallback_frames);
    try std.testing.expectEqual(@as(u64, 1), presenter.stats.shared_raster_backpressure_fallbacks);
}

test "native xrgb32 transport keeps wide full-motion work bounded" {
    const width: u32 = 512;
    const height: u32 = 224;
    const pixels = try std.testing.allocator.alloc(u32, @as(usize, width) * height);
    defer std.testing.allocator.free(pixels);
    @memset(pixels, 0x00112233);
    var scratch: [tile_max_pixels]u32 = undefined;
    var presenter = try Presenter.init(try Surface.initXrgb32(pixels, width, height), scratch[0..]);
    var fake = FakeBackend{ .xrgb32_nearest_enabled = true };

    var frame: u32 = 0;
    while (frame < 64) : (frame += 1) {
        if (frame != 0) {
            pixels[frame] = frame;
            presenter.invalidate(.{ .x = frame, .y = 0, .w = 1, .h = 1 });
        }
        const result = presenter.presentTo(fake.backend(), width, height);
        try std.testing.expect(result == .presented);
        try std.testing.expectEqual(@as(u32, 8), result.presented.raster_blocks);
    }

    const frame_resource_bytes = @as(u64, width) * height * @sizeOf(u32) + 8 * abi.gui_xrgb32_pixels_offset;
    try std.testing.expectEqual(@as(u32, 1), fake.full_begins);
    try std.testing.expectEqual(@as(u32, 63), fake.replace_begins);
    try std.testing.expectEqual(@as(u32, 512), fake.xrgb32_nearest_rasters);
    try std.testing.expectEqual(@as(u64, 64) * frame_resource_bytes, fake.xrgb32_nearest_resource_bytes);
    try std.testing.expectEqual(@as(u64, 64) * width * height, presenter.stats.sampled_pixels);
    try std.testing.expectEqual(@as(u32, 1), presenter.damage_chain);
    try std.testing.expectEqual(@as(u32, 0), fake.rasters);
    try std.testing.expect(!fake.invalid_raster);
}

test "indexed palette and fractional nearest neighbour scaling produce xrgb tiles" {
    var indices = [_]u8{ 0, 1, 2, 3 };
    var palette_values = [_]u32{0} ** palette_entries;
    palette_values[0] = 0x00000000;
    palette_values[1] = 0x00FF0000;
    palette_values[2] = 0x0000FF00;
    palette_values[3] = 0x000000FF;
    var scratch: [tile_max_pixels]u32 = undefined;
    var presenter = try Presenter.init(try Surface.initIndexed8(indices[0..], palette_values[0..], 2, 2), scratch[0..]);
    var fake = FakeBackend{};
    const result = presenter.presentTo(fake.backend(), 3, 3);
    switch (result) {
        .presented => |info| {
            try std.testing.expectEqual(PresentMode.full, info.mode);
            try std.testing.expectEqual(@as(u32, 0), info.viewport.integer_scale);
        },
        else => return error.TestUnexpectedResult,
    }
    try std.testing.expectEqual(@as(usize, 9), fake.captured_len);
    try std.testing.expectEqualSlices(u32, &.{
        0x00000000, 0x00000000, 0x00FF0000,
        0x00000000, 0x00000000, 0x00FF0000,
        0x0000FF00, 0x0000FF00, 0x000000FF,
    }, fake.captured[0..9]);
    try std.testing.expect(presenter.setPaletteEntry(1, 0xAA123456));
    try std.testing.expectEqual(@as(u32, 0x00123456), palette_values[1]);
}

test "indexed8 contract preserves sparse damage and source pixels" {
    var indices = [_]u8{
        0, 1, 2, 3,
        1, 2, 3, 0,
        2, 3, 0, 1,
        3, 0, 1, 2,
    };
    var palette_values = [_]u32{0} ** palette_entries;
    palette_values[0] = 0x00000000;
    palette_values[1] = 0x00FF0000;
    palette_values[2] = 0x0000FF00;
    palette_values[3] = 0x000000FF;
    var scratch: [tile_max_pixels]u32 = undefined;
    var presenter = try Presenter.init(try Surface.initIndexed8(indices[0..], palette_values[0..], 4, 4), scratch[0..]);
    var fake = FakeBackend{ .indexed8_enabled = true };
    const first = presenter.presentTo(fake.backend(), 3, 3);
    try std.testing.expect(first == .presented);
    try std.testing.expectEqual(@as(u32, 1), fake.indexed8_rasters);
    try std.testing.expectEqual(@as(u32, 0), fake.rasters);
    try std.testing.expect(!fake.invalid_raster);
    try std.testing.expectEqual(@as(u32, 3), fake.captured_indexed_command.w);
    try std.testing.expectEqual(@as(u32, 3), fake.captured_indexed_command.h);
    var header: abi.GuiIndexed8Resource = .{};
    @memcpy(std.mem.asBytes(&header), fake.captured_indexed[0..@sizeOf(abi.GuiIndexed8Resource)]);
    try std.testing.expectEqual(@as(u32, 4), header.source_w);
    try std.testing.expectEqual(@as(u32, 4), header.source_h);
    try std.testing.expectEqualSlices(u8, indices[0..], fake.captured_indexed[abi.gui_indexed8_pixels_offset .. abi.gui_indexed8_pixels_offset + indices.len]);

    presenter.invalidate(.{ .x = 0, .y = 0, .w = 1, .h = 1 });
    presenter.invalidate(.{ .x = 3, .y = 3, .w = 1, .h = 1 });
    const sparse = presenter.presentTo(fake.backend(), 3, 3);
    try std.testing.expectEqual(PresentMode.damage, sparse.presented.mode);
    try std.testing.expectEqual(@as(u32, 2), sparse.presented.damage_regions);
    try std.testing.expectEqual(@as(u32, 2), fake.damage_regions);
    try std.testing.expectEqual(@as(u64, 2), presenter.stats.damage_regions - 1);
    try std.testing.expectEqual(@as(u64, 2), presenter.stats.indexed8_frames);
    try std.testing.expectEqual(@as(u64, 0), presenter.stats.xrgb_fallback_frames);
}

test "input translation separates text and rejects letterbox coordinates" {
    const viewport = try calculateViewport(200, 200, 256, 224);
    var translator = InputTranslator{};
    const gained = translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.focus_gained),
        .tick = 1,
    }, viewport, null).?;
    try std.testing.expect(gained.focus.focused);

    const key = translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.key_down),
        .key = 'A',
        .modifiers = 2,
        .tick = 2,
    }, viewport, null).?;
    try std.testing.expectEqual(@as(u32, 'A'), key.key_down.code);
    try std.testing.expectEqual(@as(u64, 2), key.key_down.sequence);
    const text_event = translator.takePending().?;
    try std.testing.expectEqual(@as(u32, 'A'), text_event.text.codepoint);
    try std.testing.expectEqual(key.key_down.sequence, text_event.text.sequence);

    const outside = translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.mouse_move),
        .x = 10,
        .y = 1,
        .tick = 3,
    }, viewport, null).?;
    try std.testing.expect(outside.mouse.guest == null);
    const inside = translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.mouse_down),
        .x = viewport.x,
        .y = viewport.y,
        .buttons = 1,
        .tick = 4,
    }, viewport, null).?;
    try std.testing.expectEqual(Point{ .x = 0, .y = 0 }, inside.mouse.guest.?);

    const lost = translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.focus_lost),
        .tick = 5,
    }, viewport, null).?;
    try std.testing.expect(!lost.focus.focused);
    try std.testing.expectEqual(@as(u64, 5), translator.stats.raw_events);
    try std.testing.expectEqual(@as(u64, 6), translator.stats.logical_events);
    try std.testing.expectEqual(@as(u64, 1), translator.stats.pending_text_created);
    try std.testing.expectEqual(@as(u64, 1), translator.stats.pending_text_emitted);
    try std.testing.expectEqual(@as(u64, 2), translator.stats.mouse_mappings);
}

test "physical key transitions preserve sides and focus loss releases held keys once" {
    var translator = InputTranslator{};
    const gained = translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.focus_gained),
        .tick = 10,
    }, null, null).?;
    try std.testing.expect(gained.focus.focused);

    const left_alt = translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.physical_key_down),
        .key = abi.physical_key_usage_left_alt,
        .modifiers = abi.physical_key_modifier_left_alt,
        .tick = 11,
    }, null, null).?;
    try std.testing.expectEqual(abi.physical_key_usage_left_alt, left_alt.physical_key_down.key);
    try std.testing.expectEqual(abi.physical_key_modifier_left_alt, left_alt.physical_key_down.modifiers);

    const right_control = translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.physical_key_down),
        .key = abi.physical_key_usage_right_control,
        .modifiers = abi.physical_key_modifier_left_alt | abi.physical_key_modifier_right_control,
        .tick = 12,
    }, null, null).?;
    try std.testing.expectEqual(abi.physical_key_usage_right_control, right_control.physical_key_down.key);
    try std.testing.expect(translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.physical_key_down),
        .key = abi.physical_key_usage_right_control,
        .tick = 13,
    }, null, null) == null);
    const repeat = translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.physical_key_down),
        .key = abi.physical_key_usage_right_control,
        .flags = abi.physical_key_flag_repeat,
        .tick = 13,
    }, null, null).?;
    try std.testing.expectEqual(abi.physical_key_flag_repeat, repeat.physical_key_down.flags);

    const lost = translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.focus_lost),
        .tick = 14,
    }, null, null).?;
    try std.testing.expect(!lost.focus.focused);
    const release_left_alt = translator.takePending().?;
    const release_right_control = translator.takePending().?;
    try std.testing.expectEqual(abi.physical_key_usage_left_alt, release_left_alt.physical_key_up.key);
    try std.testing.expectEqual(abi.physical_key_usage_right_control, release_right_control.physical_key_up.key);
    try std.testing.expectEqual(@as(u64, 14), release_left_alt.physical_key_up.tick);
    try std.testing.expect(translator.takePending() == null);
    try std.testing.expect(translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.physical_key_up),
        .key = abi.physical_key_usage_right_control,
        .tick = 15,
    }, null, null) == null);
    try std.testing.expectEqual(@as(u64, 3), translator.stats.physical_key_downs);
    try std.testing.expectEqual(@as(u64, 1), translator.stats.physical_key_repeats);
    try std.testing.expectEqual(@as(u64, 2), translator.stats.synthesized_physical_key_ups);
    try std.testing.expectEqual(@as(u64, 1), translator.stats.duplicate_physical_down);
    try std.testing.expectEqual(@as(u64, 1), translator.stats.unexpected_physical_up);
}

test "keypad and right control transport stays physical through repeat and focus release" {
    var translator = InputTranslator{};
    _ = translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.focus_gained),
        .tick = 20,
    }, null, null).?;

    const keypad = [_]u32{
        abi.physical_key_usage_keypad_2,
        abi.physical_key_usage_keypad_4,
        abi.physical_key_usage_keypad_6,
        abi.physical_key_usage_keypad_7,
        abi.physical_key_usage_keypad_8,
        abi.physical_key_usage_keypad_9,
    };
    for (keypad, 0..) |usage, index| {
        const translated = translator.translate(.{
            .kind = @intFromEnum(abi.GuiEventKind.physical_key_down),
            .key = usage,
            .tick = 21 + index,
        }, null, null).?;
        try std.testing.expectEqual(usage, translated.physical_key_down.key);
    }
    const right_control = translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.physical_key_down),
        .key = abi.physical_key_usage_right_control,
        .modifiers = abi.physical_key_modifier_right_control,
        .tick = 30,
    }, null, null).?;
    try std.testing.expectEqual(abi.physical_key_usage_right_control, right_control.physical_key_down.key);
    try std.testing.expect(abi.physical_key_usage_right_control != abi.physical_key_usage_left_control);

    try std.testing.expect(translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.physical_key_down),
        .key = abi.physical_key_usage_keypad_8,
        .tick = 31,
    }, null, null) == null);
    const repeated = translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.physical_key_down),
        .key = abi.physical_key_usage_keypad_8,
        .flags = abi.physical_key_flag_repeat,
        .tick = 32,
    }, null, null).?;
    try std.testing.expectEqual(abi.physical_key_flag_repeat, repeated.physical_key_down.flags);

    const numeric_row_8: u32 = 0x25;
    const row = translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.physical_key_down),
        .key = numeric_row_8,
        .tick = 33,
    }, null, null).?;
    try std.testing.expectEqual(numeric_row_8, row.physical_key_down.key);
    try std.testing.expect(numeric_row_8 != abi.physical_key_usage_keypad_8);
    try std.testing.expect(abi.physical_key_usage_up != abi.physical_key_usage_keypad_8);

    _ = translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.focus_lost),
        .tick = 40,
    }, null, null).?;
    const expected_releases = [_]u32{
        numeric_row_8,
        abi.physical_key_usage_keypad_2,
        abi.physical_key_usage_keypad_4,
        abi.physical_key_usage_keypad_6,
        abi.physical_key_usage_keypad_7,
        abi.physical_key_usage_keypad_8,
        abi.physical_key_usage_keypad_9,
        abi.physical_key_usage_right_control,
    };
    for (expected_releases) |usage| {
        const released = translator.takePending().?;
        try std.testing.expectEqual(usage, released.physical_key_up.key);
        try std.testing.expectEqual(@as(u64, 40), released.physical_key_up.tick);
    }
    try std.testing.expect(translator.takePending() == null);
}

test "text-only pointer-free policy preserves order and filter reasons" {
    const viewport = try calculateViewport(800, 600, 320, 200);
    var translator = InputTranslator.init(.text_only_no_pointer);

    const gained = translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.focus_gained),
        .tick = 10,
    }, viewport, null).?;
    try std.testing.expectEqual(@as(u64, 1), gained.focus.sequence);
    try std.testing.expect(translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.focus_gained),
        .tick = 11,
    }, viewport, null) == null);
    try std.testing.expect(translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.mouse_move),
        .x = viewport.x,
        .y = viewport.y,
        .tick = 12,
    }, viewport, null) == null);

    const text_event = translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.key_down),
        .key = 'A',
        .tick = 13,
    }, viewport, null).?;
    try std.testing.expectEqual(@as(u32, 'A'), text_event.text.codepoint);
    try std.testing.expectEqual(@as(u64, 4), text_event.text.sequence);
    try std.testing.expect(translator.takePending() == null);

    const enter = translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.key_down),
        .key = 13,
        .tick = 14,
    }, viewport, null).?;
    try std.testing.expectEqual(@as(u32, 13), enter.key_down.code);
    try std.testing.expectEqual(@as(u64, 5), enter.key_down.sequence);

    try std.testing.expect(translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.resize),
        .tick = 15,
    }, null, null) == null);
    try std.testing.expectEqual(@as(u64, 6), translator.stats.raw_events);
    try std.testing.expectEqual(@as(u64, 3), translator.stats.logical_events);
    try std.testing.expectEqual(@as(u64, 3), translator.stats.filtered_events);
    try std.testing.expectEqual(@as(u64, 1), translator.stats.pointer_ignored);
    try std.testing.expectEqual(@as(u64, 1), translator.stats.duplicate_focus);
    try std.testing.expectEqual(@as(u64, 1), translator.stats.missing_geometry);
    try std.testing.expectEqual(@as(u64, 0), translator.stats.pending_text_created);
    try std.testing.expectEqual(@as(u64, 0), translator.stats.mouse_mappings);
    try std.testing.expectEqual(@as(u64, 6), translator.stats.last_filtered_sequence);
    try std.testing.expectEqual(@as(u64, 15), translator.stats.last_filtered_tick);
    try std.testing.expectEqual(InputFilterReason.missing_geometry, translator.stats.last_filter_reason);
}

test "resize event carries unchanged guest mode and recalculated viewport" {
    const viewport = try calculateViewport(800, 600, 320, 200);
    var translator = InputTranslator{};
    const event = translator.translate(.{
        .kind = @intFromEnum(abi.GuiEventKind.resize),
        .tick = 9,
    }, viewport, .{ .w = 800, .h = 600 }).?;
    try std.testing.expectEqual(@as(u32, 320), event.resize.viewport.guest_w);
    try std.testing.expectEqual(@as(u32, 200), event.resize.viewport.guest_h);
    try std.testing.expectEqual(@as(u32, 800), event.resize.client.w);
}
