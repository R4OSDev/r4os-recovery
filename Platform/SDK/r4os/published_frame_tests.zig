const std = @import("std");
test "published frame owner raster callbacks do not require optional indexed transport" {
    const Minimal = struct {
        calls: u32 = 0,
        indexed_calls: u32 = 0,
        fn invoke(user: ?*anyopaque, kind: u32, _: [*]const p.callbacks.Slot, _: u32, _: ?*anyopaque) callconv(.c) p.callbacks.Slot {
            const self: *@This() = @ptrCast(@alignCast(user.?));
            self.calls += 1;
            if (kind == @intFromEnum(p.callbacks.Kind.video_indexed8)) self.indexed_calls += 1;
            return .{ .flags = 1 };
        }
    };
    var state: Minimal = .{};
    var mask: u64 = 0;
    inline for (.{ p.callbacks.Kind.video_begin_full, p.callbacks.Kind.video_begin_damage, p.callbacks.Kind.video_clear, p.callbacks.Kind.video_raster, p.callbacks.Kind.video_commit_full, p.callbacks.Kind.video_commit_damage, p.callbacks.Kind.video_cancel }) |kind| mask |= @as(u64, 1) << @intFromEnum(kind);
    const table: p.callbacks.Table = .{ .user = &state, .mask = mask, .invoke = &Minimal.invoke };
    var scratch: [v.tile_max_pixels]u32 = undefined;
    var bridge: p.Bridge = undefined;
    try t.expectEqual(@as(i32, 0), p.Bridge.initCallbacks(&table, &scratch, 0, &bridge));
    try t.expectEqual(@intFromPtr(&table), @intFromPtr(bridge.backend.context));
    try t.expect(!bridge.backend.supports_indexed8);
    try t.expectEqual(@as(i32, 0), bridge.bind(1));
    var pixels = [_]u32{0x112233} ** 64;
    const acquired = try sync(&bridge, rgb(&pixels, 8, 8, 1));
    try t.expectEqual(@as(u32, 2), (try present(&bridge, acquired.ticket, 16, 16)).kind);
    try t.expect(state.calls > 0);
    try t.expectEqual(@as(u32, 0), state.indexed_calls);
    try t.expectEqual(@as(i32, 0), bridge.close());
    try t.expectEqual(p.no_provider, p.Bridge.initCallbacks(&table, &scratch, 1, &bridge));
    try t.expectEqual(p.no_provider, p.Bridge.initCallbacks(&table, &scratch, 2, &bridge));
}
const p = @import("published_frame.zig");
const v = p.video;
const a = @import("r4os_contract").abi;
const t = std.testing;
const Monitor = struct {
    pixels: [32 * 32]u32 = @splat(0),
    full: u32 = 0,
    damage: u32 = 0,
    commits: u32 = 0,
    rasters: u32 = 0,
    cancels: u32 = 0,
    fail: bool = false,
    bridge: ?*p.Bridge = null,
    request_close: bool = false,
    saw_active_close: bool = false,
    inside_transaction: bool = false,
    fn get(raw: *anyopaque) *Monitor {
        return @ptrCast(@alignCast(raw));
    }
    fn begin(raw: *anyopaque) i32 {
        get(raw).full += 1;
        get(raw).inside_transaction = true;
        return 0;
    }
    fn damageBegin(raw: *anyopaque, _: []const a.DisplayDamageRect) i32 {
        get(raw).damage += 1;
        get(raw).inside_transaction = true;
        return 0;
    }
    fn clear(raw: *anyopaque, color: u32) i32 {
        @memset(&get(raw).pixels, color);
        return 0;
    }
    fn raster(raw: *anyopaque, x: i32, y: i32, width: u32, height: u32, scale: u32, pixels: []const u32) i32 {
        const self = get(raw);
        self.rasters += 1;
        if (self.request_close) {
            self.request_close = false;
            const bridge = self.bridge.?;
            var observed: p.Progress = undefined;
            std.debug.assert(bridge.close() == p.busy and bridge.progress(&observed) == 0);
            self.saw_active_close = observed.flags & (p.active_loan | p.in_call | p.close_pending) == (p.active_loan | p.in_call | p.close_pending) and bridge.frame.pixels.address != 0;
            std.debug.assert(bridge.release(observed.active_ticket) == p.busy);
        }
        if (self.fail) return -77;
        if (x < 0 or y < 0 or width > v.tile_max_width or height > v.tile_max_height or pixels.len != width * height or scale == 0) return -90;
        for (0..height) |sy| for (0..width) |sx| for (0..scale) |dy| for (0..scale) |dx| {
            const tx = @as(usize, @intCast(x)) + sx * scale + dx;
            const ty = @as(usize, @intCast(y)) + sy * scale + dy;
            if (tx >= 32 or ty >= 32) return -91;
            self.pixels[ty * 32 + tx] = pixels[sy * width + sx];
        };
        return 0;
    }
    fn indexed(_: *anyopaque, _: v.IndexedBatch) i32 {
        return a.err_no_fn;
    }
    fn commit(raw: *anyopaque) i32 {
        get(raw).commits += 1;
        get(raw).inside_transaction = false;
        return 0;
    }
    fn cancel(raw: *anyopaque) i32 {
        get(raw).cancels += 1;
        get(raw).inside_transaction = false;
        return 0;
    }
    fn backend(self: *Monitor) v.Backend {
        return .{ .context = self, .begin_full_fn = &begin, .begin_damage_fn = &damageBegin, .clear_fn = &clear, .raster_fn = &raster, .indexed8_fn = &indexed, .commit_full_fn = &commit, .commit_damage_fn = &commit, .cancel_fn = &cancel };
    }
};
fn span(bytes: []const u8) p.wire.Span {
    return .{ .address = @intFromPtr(bytes.ptr), .length = bytes.len };
}
fn rgb(pixels: []const u32, width: u32, height: u32, revision: u64) p.Lease {
    return .{ .pixels = span(std.mem.sliceAsBytes(pixels)), .binding_generation = 1, .revision = revision, .width = width, .height = height, .stride_bytes = width * 4, .format = p.format_xrgb32, .flags = p.published };
}
fn progress(bridge: *const p.Bridge) !p.Progress {
    var value: p.Progress = undefined;
    try t.expectEqual(@as(i32, 0), bridge.progress(&value));
    return value;
}
fn init(bridge: *p.Bridge, monitor: *Monitor, scratch: []u32) !void {
    try t.expectEqual(@as(i32, 0), p.Bridge.init(monitor.backend(), scratch, bridge));
    try t.expectEqual(@as(i32, 0), bridge.bind(1));
}
fn sync(bridge: *p.Bridge, lease: p.Lease) !p.Acquisition {
    var value: p.Acquisition = undefined;
    try t.expectEqual(@as(i32, 0), bridge.syncPublished(lease, &value));
    return value;
}
fn present(bridge: *p.Bridge, ticket: u64, width: i32, height: i32) !p.Presentation {
    var value: p.Presentation = undefined;
    try t.expectEqual(@as(i32, 0), bridge.present(ticket, width, height, &value));
    return value;
}
fn equalPresentation(old: v.PresentResult, current: p.Presentation) !void {
    const info = old.presented;
    try t.expectEqual(@as(u32, 2), current.kind);
    try t.expectEqual(@as(u32, @intFromEnum(info.mode)), current.mode);
    try t.expectEqual(info.damage_regions, current.damage_regions);
    try t.expectEqual(info.raster_blocks, current.raster_blocks);
    try t.expectEqual(info.sampled_pixels, current.sampled_pixels);
    try t.expectEqual(info.viewport.x, current.viewport.x);
    try t.expectEqual(info.viewport.y, current.viewport.y);
    try t.expectEqual(info.viewport.w, current.viewport.width);
    try t.expectEqual(info.viewport.h, current.viewport.height);
    try t.expectEqual(info.viewport.guest_w, current.viewport.source_width);
    try t.expectEqual(info.viewport.guest_h, current.viewport.source_height);
    try t.expectEqual(info.viewport.integer_scale, current.viewport.integer_scale);
}
test "published frame owner actual original full damage duplicate resize and detached source" {
    var pixels: [64]u32 = undefined;
    for (&pixels, 0..) |*pixel, i| pixel.* = @intCast(i * 0x10301);
    var scratch_a: [v.tile_max_pixels]u32 = undefined;
    var scratch_b: [v.tile_max_pixels]u32 = undefined;
    var original = try v.Presenter.init(try v.Surface.initXrgb32(&pixels, 8, 8), &scratch_a);
    var left: Monitor = .{};
    var right: Monitor = .{};
    var bridge: p.Bridge = undefined;
    try init(&bridge, &right, &scratch_b);
    var lease = rgb(&pixels, 8, 8, 1);
    var acquired = try sync(&bridge, lease);
    try equalPresentation(original.presentTo(left.backend(), 16, 16), try present(&bridge, acquired.ticket, 16, 16));
    try t.expectEqualSlices(u32, &left.pixels, &right.pixels);
    try t.expectEqual(@as(i32, 0), bridge.release(acquired.ticket));
    try t.expectEqual(@as(usize, 0), bridge.frame.pixels.address);
    try t.expect(@intFromPtr(bridge.presenter.surface.xrgb32Pixels().?.ptr) != @intFromPtr(&pixels));
    pixels[9] = 0xaa1122;
    original.invalidate(.{ .x = 1, .y = 1, .w = 1, .h = 1 });
    lease.revision = 2;
    lease.damage_kind = p.damage_rect;
    lease.damage_base_revision = 1;
    lease.damage = .{ .x = 1, .y = 1, .w = 1, .h = 1 };
    acquired = try sync(&bridge, lease);
    try equalPresentation(original.presentTo(left.backend(), 16, 16), try present(&bridge, acquired.ticket, 16, 16));
    try t.expectEqualSlices(u32, &left.pixels, &right.pixels);
    try t.expectEqual(@as(u32, 1), right.damage);
    try t.expectEqual(@as(i32, 0), bridge.release(acquired.ticket));
    acquired = try sync(&bridge, lease);
    try t.expectEqual(@as(u32, 0), acquired.kind);
    try t.expect(original.presentTo(left.backend(), 16, 16) == .unchanged);
    try t.expectEqual(@as(u32, 0), (try present(&bridge, acquired.ticket, 16, 16)).kind);
    try equalPresentation(original.presentTo(left.backend(), 20, 16), try present(&bridge, acquired.ticket, 20, 16));
    try t.expectEqualSlices(u32, &left.pixels, &right.pixels);
    try t.expectEqual(@as(i32, 0), bridge.release(acquired.ticket));
    std.debug.print("PF026 sizes Bridge={d} Lease={d} Acquisition={d} Progress={d} Presentation={d}; direct original pixel/viewport/tile comparisons PASS\n", .{ @sizeOf(p.Bridge), @sizeOf(p.Lease), @sizeOf(p.Acquisition), @sizeOf(p.Progress), @sizeOf(p.Presentation) });
}
test "published frame owner palette-only recolor and dynamic packed geometry" {
    var pixels: [128]u8 = @splat(0);
    var palette: [256]u32 = @splat(0);
    palette[0] = 0xffffff;
    var monitor: Monitor = .{};
    var scratch: [v.tile_max_pixels]u32 = undefined;
    var bridge: p.Bridge = undefined;
    try init(&bridge, &monitor, &scratch);
    var lease: p.Lease = .{ .pixels = span(&pixels), .palette = span(std.mem.sliceAsBytes(&palette)), .binding_generation = 1, .revision = 1, .palette_revision = 1, .width = 8, .height = 8, .stride_bytes = 8, .flags = p.published };
    var acquired = try sync(&bridge, lease);
    try t.expectEqual(@as(u32, 2), (try present(&bridge, acquired.ticket, 16, 16)).kind);
    try t.expectEqual(@as(u32, 0xffffff), monitor.pixels[0]);
    try t.expectEqual(@as(i32, 0), bridge.release(acquired.ticket));
    palette[0] = 0xff0000;
    lease.palette_revision = 2;
    acquired = try sync(&bridge, lease);
    try t.expectEqual(@as(u32, 1), acquired.kind);
    try t.expectEqual(@as(u32, 0), (try present(&bridge, acquired.ticket, 16, 16)).mode);
    try t.expectEqual(@as(u32, 0xff0000), monitor.pixels[0]);
    try t.expectEqual(@as(i32, 0), bridge.release(acquired.ticket));
    lease.palette_revision = 1;
    var rejected: p.Acquisition = undefined;
    try t.expectEqual(p.stale_revision, bridge.syncPublished(lease, &rejected));
    var wide: [128]u32 = @splat(0x225588);
    lease = rgb(&wide, 16, 8, 2);
    acquired = try sync(&bridge, lease);
    const output = try present(&bridge, acquired.ticket, 32, 32);
    try t.expectEqual(@as(u32, 0), output.mode);
    try t.expectEqual(@as(i32, 8), output.viewport.y);
    try t.expectEqual(@as(u32, 16), output.viewport.source_width);
    try t.expectEqual(@as(u32, 0x225588), monitor.pixels[8 * 32]);
    try t.expectEqual(@as(i32, 0), bridge.release(acquired.ticket));
}
test "published frame owner rejects stale generation revision damage and exhausted tickets atomically" {
    var pixels: [64]u32 = @splat(3);
    var monitor: Monitor = .{};
    var scratch: [v.tile_max_pixels]u32 = undefined;
    var bridge: p.Bridge = undefined;
    try init(&bridge, &monitor, &scratch);
    var lease = rgb(&pixels, 8, 8, 2);
    var acquired = try sync(&bridge, lease);
    var output: p.Acquisition = .{ .ticket = 777, .kind = 1 };
    try t.expectEqual(p.busy, bridge.bind(2));
    try t.expectEqual(p.busy, bridge.syncPublished(lease, &output));
    try t.expectEqual(p.no_lease, bridge.release(acquired.ticket + 1));
    try t.expectEqual(@as(i32, 0), bridge.release(acquired.ticket));
    const before = try progress(&bridge);
    lease.binding_generation = 0;
    try t.expectEqual(p.stale_generation, bridge.syncPublished(lease, &output));
    lease.binding_generation = 1;
    lease.revision = 1;
    try t.expectEqual(p.stale_revision, bridge.syncPublished(lease, &output));
    lease.revision = 2;
    lease.width = 4;
    lease.height = 16;
    lease.stride_bytes = 16;
    try t.expectEqual(p.stale_revision, bridge.syncPublished(lease, &output));
    lease = rgb(&pixels, 8, 8, 3);
    lease.damage_kind = p.damage_rect;
    lease.damage_base_revision = 1;
    lease.damage = .{ .x = 0, .y = 0, .w = 1, .h = 1 };
    try t.expectEqual(p.stale_damage, bridge.syncPublished(lease, &output));
    try t.expectEqualDeep(before, try progress(&bridge));
    try t.expectEqual(@as(u64, 777), output.ticket);
    bridge.last_ticket = std.math.maxInt(u64);
    lease = rgb(&pixels, 8, 8, 3);
    try t.expectEqual(p.exhausted, bridge.syncPublished(lease, &output));
    bridge.last_ticket = before.last_ticket;
    try t.expectEqual(@as(i32, 0), bridge.bind(2));
    lease.binding_generation = 2;
    acquired = try sync(&bridge, lease);
    try t.expect(acquired.ticket > before.last_ticket);
    try t.expectEqual(@as(i32, 0), bridge.close());
    try t.expectEqual(@as(i32, 0), bridge.close());
    try t.expectEqual(p.closed, bridge.bind(3));
    try t.expectEqual(@as(u64, 0), (try progress(&bridge)).active_ticket);
}
test "published frame owner refuses incomplete alias stride span and unsupported backend" {
    var pixels: [64]u32 align(8) = @splat(0);
    var monitor: Monitor = .{};
    var scratch: [v.tile_max_pixels]u32 = undefined;
    var bridge: p.Bridge = undefined;
    var backend = monitor.backend();
    backend.supports_shared_raster = true;
    try t.expectEqual(p.unsupported, p.Bridge.init(backend, &scratch, &bridge));
    backend.supports_shared_raster = false;
    backend.available = false;
    try t.expectEqual(p.no_provider, p.Bridge.init(backend, &scratch, &bridge));
    try t.expectEqual(p.scratch_small, p.Bridge.init(monitor.backend(), scratch[0..1], &bridge));
    const table: p.callbacks.Table = .{};
    try t.expectEqual(p.no_provider, p.Bridge.initCallbacks(&table, &scratch, 0, &bridge));
    try t.expectEqual(p.unsupported, p.Bridge.initCallbacks(&table, &scratch, 4, &bridge));
    try init(&bridge, &monitor, &scratch);
    const before = try progress(&bridge);
    var lease = rgb(&pixels, 8, 8, 1);
    var output: p.Acquisition = .{ .ticket = 777, .kind = 1 };
    lease.flags = 0;
    try t.expectEqual(p.invalid_surface, bridge.syncPublished(lease, &output));
    lease.flags = p.published;
    lease.stride_bytes += 4;
    try t.expectEqual(p.unsupported, bridge.syncPublished(lease, &output));
    lease = rgb(&pixels, 8, 8, 1);
    lease.pixels.length = 4;
    try t.expectEqual(p.invalid_buffer, bridge.syncPublished(lease, &output));
    lease.pixels = .{ .address = std.math.maxInt(usize) - 2, .length = 64 };
    try t.expectEqual(p.invalid_buffer, bridge.syncPublished(lease, &output));
    lease.pixels = span(std.mem.sliceAsBytes(&scratch));
    try t.expectEqual(p.invalid_buffer, bridge.syncPublished(lease, &output));
    lease = rgb(&pixels, 8, 8, 1);
    try t.expectEqual(p.invalid_buffer, bridge.syncPublished(lease, @ptrCast(@alignCast(&pixels))));
    try t.expectEqualDeep(before, try progress(&bridge));
    try t.expectEqual(@as(u64, 777), output.ticket);
    const acquired = try sync(&bridge, lease);
    try t.expectEqual(p.invalid_buffer, bridge.progress(@ptrCast(@alignCast(&pixels))));
    try t.expectEqual(@as(u32, 0), pixels[0]);
    try t.expectEqual(@as(i32, 0), bridge.release(acquired.ticket));
}
test "published frame owner close request keeps source through actual render callback return" {
    var pixels: [64]u32 = @splat(0xabcdef);
    var monitor: Monitor = .{};
    var scratch: [v.tile_max_pixels]u32 = undefined;
    var bridge: p.Bridge = undefined;
    try init(&bridge, &monitor, &scratch);
    monitor.bridge = &bridge;
    monitor.request_close = true;
    const acquired = try sync(&bridge, rgb(&pixels, 8, 8, 1));
    try t.expectEqual(@as(u32, 2), (try present(&bridge, acquired.ticket, 16, 16)).kind);
    try t.expect(monitor.saw_active_close);
    const final = try progress(&bridge);
    try t.expectEqual(p.ended, final.state);
    try t.expectEqual(@as(u64, 0), final.active_ticket);
    try t.expect(final.flags & (p.active_loan | p.in_call | p.close_pending) == 0);
    try t.expectEqual(@as(usize, 0), bridge.frame.pixels.address);
    try t.expectEqual(p.no_lease, bridge.release(acquired.ticket));
}
test "published frame owner paused complete frame and failed render preserve retry damage" {
    var pixels: [64]u32 = @splat(0x998877);
    var monitor: Monitor = .{ .fail = true };
    var scratch: [v.tile_max_pixels]u32 = undefined;
    var bridge: p.Bridge = undefined;
    try init(&bridge, &monitor, &scratch);
    try t.expectEqual(@as(i32, 0), bridge.pause(true));
    const acquired = try sync(&bridge, rgb(&pixels, 8, 8, 1));
    const failed = try present(&bridge, acquired.ticket, 16, 16);
    try t.expectEqual(@as(u32, 3), failed.kind);
    try t.expectEqual(@as(i32, -77), failed.error_code);
    try t.expectEqual(@as(u32, 1), monitor.cancels);
    try t.expectEqual(acquired.ticket, (try progress(&bridge)).active_ticket);
    monitor.fail = false;
    const completed = try present(&bridge, acquired.ticket, 16, 16);
    try t.expectEqual(@as(u32, 2), completed.kind);
    try t.expectEqual(@as(u32, 0), completed.mode);
    try t.expectEqual(p.paused, (try progress(&bridge)).state);
    try t.expectEqual(@as(i32, 0), bridge.release(acquired.ticket));
    try t.expectEqual(@as(i32, 0), bridge.pause(false));
    try t.expectEqual(@as(i32, 0), bridge.close());
}

test "published frame owner overlay failure retry and reentrant close retain the real source" {
    const Overlay = struct {
        bridge: *p.Bridge,
        monitor: *Monitor,
        source: usize,
        failure: i32 = -713,
        close_requested: bool = false,
        calls: u32 = 0,
        fn append(raw: *anyopaque) i32 {
            const self: *@This() = @ptrCast(@alignCast(raw));
            std.debug.assert(self.monitor.inside_transaction);
            std.debug.assert(self.bridge.call_active == 1 and self.bridge.active_ticket != 0);
            std.debug.assert(self.bridge.frame.pixels.address == self.source);
            self.calls += 1;
            if (self.close_requested) {
                std.debug.assert(self.bridge.close() == p.busy);
                std.debug.assert(self.bridge.frame.pixels.address == self.source);
                std.debug.assert(self.bridge.release(self.bridge.active_ticket) == p.busy);
            }
            self.monitor.pixels[0] = 0xff5500;
            return self.failure;
        }
    };
    var pixels: [64]u32 = @splat(0x112233);
    var monitor: Monitor = .{};
    var scratch: [v.tile_max_pixels]u32 = undefined;
    var bridge: p.Bridge = undefined;
    try init(&bridge, &monitor, &scratch);
    const acquired = try sync(&bridge, rgb(&pixels, 8, 8, 1));
    var overlay = Overlay{ .bridge = &bridge, .monitor = &monitor, .source = @intFromPtr(&pixels) };
    const hook = v.FrameOverlay{ .context = &overlay, .append_fn = Overlay.append };
    var result: p.Presentation = undefined;
    try t.expectEqual(@as(i32, 0), bridge.presentWithOverlay(acquired.ticket, 16, 16, &result, hook));
    try t.expectEqual(@as(u32, 3), result.kind);
    try t.expectEqual(@as(i32, -713), result.error_code);
    try t.expectEqual(@as(u32, 1), monitor.cancels);
    try t.expectEqual(@as(u32, 0), monitor.commits);
    try t.expect(!monitor.inside_transaction);
    try t.expectEqual(acquired.ticket, bridge.active_ticket);
    overlay.failure = 0;
    try t.expectEqual(@as(i32, 0), bridge.presentWithOverlay(acquired.ticket, 16, 16, &result, hook));
    try t.expectEqual(@as(u32, 2), result.kind);
    try t.expectEqual(@as(u32, 1), monitor.commits);
    try t.expectEqual(@as(u32, 0xff5500), monitor.pixels[0]);
    try t.expectEqual(@as(u32, 0x112233), pixels[0]);
    bridge.presenter.invalidateClient(.{ .x = 0, .y = 0, .w = 2, .h = 2 });
    overlay.close_requested = true;
    try t.expectEqual(@as(i32, 0), bridge.presentWithOverlay(acquired.ticket, 16, 16, &result, hook));
    try t.expectEqual(@as(u32, 2), result.kind);
    try t.expectEqual(@as(u32, 3), overlay.calls);
    try t.expectEqual(p.ended, bridge.state);
    try t.expectEqual(@as(u64, 0), bridge.active_ticket);
    try t.expectEqual(@as(usize, 0), bridge.frame.pixels.address);
    try t.expectEqual(p.no_lease, bridge.release(acquired.ticket));
}
