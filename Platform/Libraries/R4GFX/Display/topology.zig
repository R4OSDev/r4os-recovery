//! Output geometry in signed logical desktop coordinates. Scale uses 120ths;
//! native pixel dimensions, rotation and refresh remain per output. These are
//! original R4OS policy/maths, informed by xdg-output and fractional-scale-v1.
//! No hardware capability or atomic display commit is implied by a layout.
const std = @import("std");
pub const capacity = 8;
pub const scale_unit = 120;
pub const Error = error{ Invalid, Bounds, Empty, Duplicate, Overlap, Clone, Primary, Capacity };
pub const Point = struct { x: i32 = 0, y: i32 = 0 };
pub const Rect = struct {
    x: i32 = 0, y: i32 = 0, w: u32 = 0, h: u32 = 0,
    pub fn right(self: Rect) i64 { return @as(i64, self.x) + self.w; }
    pub fn bottom(self: Rect) i64 { return @as(i64, self.y) + self.h; }
    pub fn valid(self: Rect) bool {
        // Shared desktop surfaces store signed extents and exclusive edges.
        // A representable last pixel alone does not make its edge representable.
        return self.w != 0 and self.h != 0 and self.w <= std.math.maxInt(i32) and self.h <= std.math.maxInt(i32) and
            self.right() <= std.math.maxInt(i32) and self.bottom() <= std.math.maxInt(i32);
    }
    pub fn contains(self: Rect, point: Point) bool {
        return point.x >= self.x and point.y >= self.y and point.x < self.right() and point.y < self.bottom();
    }
    pub fn intersection(self: Rect, other: Rect) ?Rect {
        const x: i64 = @max(self.x, other.x); const y: i64 = @max(self.y, other.y);
        const end_x = @min(self.right(), other.right()); const end_y = @min(self.bottom(), other.bottom());
        if (end_x <= x or end_y <= y) return null;
        return .{ .x = @intCast(x), .y = @intCast(y), .w = @intCast(end_x - x), .h = @intCast(end_y - y) };
    }
    pub fn project(self: Rect, point: Point) Point {
        std.debug.assert(self.valid());
        return .{ .x = @intCast(std.math.clamp(@as(i64, point.x), self.x, self.right() - 1)),
            .y = @intCast(std.math.clamp(@as(i64, point.y), self.y, self.bottom() - 1)) };
    }
};

/// adapter is the caller's persistent PCI location/device identity, never a
/// driver generation. A connector disambiguates identical serial-less sinks.
/// A caller without receiver identity must not persist the key as a monitor.
pub const Key = struct {
    adapter: u64 = 0,
    connector: u32 = 0,
    receiver: [16]u8 = @splat(0),
    pub fn samePort(self: Key, other: Key) bool { return self.adapter == other.adapter and self.connector == other.connector; }
    pub fn persistable(self: Key) bool { return self.adapter != 0 and self.connector != 0 and !std.mem.allEqual(u8, &self.receiver, 0); }
    pub fn fromReport(adapter: u64, connector: u32, report: *const @import("edid.zig").Report) Error!Key {
        if (adapter == 0 or connector == 0 or !report.complete()) return error.Invalid;
        // Avoid dynamic modes, extension order and connection generations.
        // A valid numeric serial wins; name supplements serial-less models.
        var data: [22]u8 = @splat(0);
        @memcpy(data[0..3], &report.manufacturer);
        std.mem.writeInt(u16, data[3..5], report.product, .little);
        const serial = if (report.serial == std.math.maxInt(u32)) 0 else report.serial;
        std.mem.writeInt(u32, data[5..9], serial, .little);
        if (serial == 0) @memcpy(data[9..22], &report.name);
        var digest: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(&data, &digest, .{});
        return .{ .adapter = adapter, .connector = connector, .receiver = digest[0..16].* };
    }
};

/// Clockwise rotation of native pixels into the logical view. Submission
/// applies its inverse; input and cursor placement use these same transforms.
pub const Rotation = enum(u2) { normal, clockwise90, clockwise180, clockwise270 };
pub const Viewport = struct {
    origin: Point = .{},
    pixel_w: u32,
    pixel_h: u32,
    scale: u32 = scale_unit,
    rotation: Rotation = .normal,
    pub fn validate(self: Viewport) Error!void {
        if (self.pixel_w == 0 or self.pixel_h == 0 or self.pixel_w > 65536 or self.pixel_h > 65536 or
            self.scale < 60 or self.scale > 960) return error.Invalid;
        if (!self.logicalUnchecked().valid()) return error.Bounds;
    }
    fn oriented(self: Viewport) struct { w: u32, h: u32 } {
        return if (self.rotation == .clockwise90 or self.rotation == .clockwise270)
            .{ .w = self.pixel_h, .h = self.pixel_w } else .{ .w = self.pixel_w, .h = self.pixel_h };
    }
    fn logicalUnchecked(self: Viewport) Rect {
        const size = self.oriented();
        // Outward rounding covers the complete physical edge. At most one
        // logical edge cell is clipped by the exact native pixel extent.
        return .{ .x = self.origin.x, .y = self.origin.y,
            .w = (size.w * scale_unit + self.scale - 1) / self.scale,
            .h = (size.h * scale_unit + self.scale - 1) / self.scale };
    }
    pub fn logical(self: Viewport) Error!Rect { try self.validate(); return self.logicalUnchecked(); }
    fn toNative(self: Viewport, u: i32, v: i32) Point {
        const w: i32 = @intCast(self.pixel_w); const h: i32 = @intCast(self.pixel_h);
        return switch (self.rotation) {
            .normal => .{ .x = u, .y = v },
            .clockwise90 => .{ .x = v, .y = h - 1 - u },
            .clockwise180 => .{ .x = w - 1 - u, .y = h - 1 - v },
            .clockwise270 => .{ .x = w - 1 - v, .y = u },
        };
    }
    pub fn physical(self: Viewport, point: Point) Error!Point {
        const rect = try self.logical();
        if (!rect.contains(point)) return error.Bounds;
        const size = self.oriented();
        const x: u64 = @intCast(@as(i64, point.x) - rect.x); const y: u64 = @intCast(@as(i64, point.y) - rect.y);
        const u = @min(((2 * x + 1) * self.scale) / (2 * scale_unit), size.w - 1);
        const v = @min(((2 * y + 1) * self.scale) / (2 * scale_unit), size.h - 1);
        return self.toNative(@intCast(u), @intCast(v));
    }
    pub fn fromPhysical(self: Viewport, point: Point) Error!Point {
        const rect = try self.logical();
        if (point.x < 0 or point.y < 0 or point.x >= self.pixel_w or point.y >= self.pixel_h) return error.Bounds;
        const w: i32 = @intCast(self.pixel_w); const h: i32 = @intCast(self.pixel_h);
        const local: Point = switch (self.rotation) {
            .normal => point,
            .clockwise90 => .{ .x = h - 1 - point.y, .y = point.x },
            .clockwise180 => .{ .x = w - 1 - point.x, .y = h - 1 - point.y },
            .clockwise270 => .{ .x = point.y, .y = w - 1 - point.x },
        };
        return .{ .x = @intCast(@as(i64, rect.x) + @divFloor((2 * @as(i64, local.x) + 1) * scale_unit, 2 * self.scale)),
            .y = @intCast(@as(i64, rect.y) + @divFloor((2 * @as(i64, local.y) + 1) * scale_unit, 2 * self.scale)) };
    }
    /// Conservative damage uses floor/ceil edges, never point rounding.
    pub fn physicalDamage(self: Viewport, damage: Rect) Error!?Rect {
        const rect = try self.logical();
        if (!damage.valid()) return error.Invalid;
        const clipped = rect.intersection(damage) orelse return null;
        const size = self.oriented();
        const left: u64 = @intCast(@as(i64, clipped.x) - rect.x); const top: u64 = @intCast(@as(i64, clipped.y) - rect.y);
        const x0: i32 = @intCast(@min(left * self.scale / scale_unit, size.w));
        const y0: i32 = @intCast(@min(top * self.scale / scale_unit, size.h));
        const x1: i32 = @intCast(@min(((left + clipped.w) * self.scale + scale_unit - 1) / scale_unit, size.w));
        const y1: i32 = @intCast(@min(((top + clipped.h) * self.scale + scale_unit - 1) / scale_unit, size.h));
        if (x0 == x1 or y0 == y1) return null;
        const w: i32 = @intCast(self.pixel_w); const h: i32 = @intCast(self.pixel_h);
        return switch (self.rotation) {
            .normal => .{ .x = x0, .y = y0, .w = @intCast(x1 - x0), .h = @intCast(y1 - y0) },
            .clockwise90 => .{ .x = y0, .y = h - x1, .w = @intCast(y1 - y0), .h = @intCast(x1 - x0) },
            .clockwise180 => .{ .x = w - x1, .y = h - y1, .w = @intCast(x1 - x0), .h = @intCast(y1 - y0) },
            .clockwise270 => .{ .x = w - y1, .y = x0, .w = @intCast(y1 - y0), .h = @intCast(x1 - x0) },
        };
    }
};

pub const Output = struct {
    key: Key,
    view: Viewport,
    enabled: bool = true,
    primary: bool = false,
    clone_group: u8 = 0,
    refresh_millihz: u32 = 0, // Zero is unknown, never an invented refresh.
    pub fn interval(self: Output) ?u64 { return if (self.refresh_millihz == 0) null else @as(u64, 1_000_000_000_000) / self.refresh_millihz; }
};
pub const Layout = struct {
    outputs: [capacity]Output = @splat(.{ .key = .{}, .view = .{ .pixel_w = 0, .pixel_h = 0 } }),
    count: usize = 0,
    primary: usize = 0,
    revision: u64 = 0,
    pub fn init(values: []const Output, revision: u64) Error!Layout {
        if (values.len == 0) return error.Empty;
        if (values.len > capacity) return error.Capacity;
        if (revision == 0) return error.Invalid;
        var result = Layout{ .count = values.len, .revision = revision };
        var enabled: usize = 0; var primary_count: usize = 0;
        var left: i64 = std.math.maxInt(i64); var top = left;
        var right: i64 = std.math.minInt(i64); var bottom = right;
        for (values, 0..) |value, i| {
            if (value.key.connector == 0 or value.refresh_millihz > 1_000_000) return error.Invalid;
            for (values[0..i]) |other| if (value.key.samePort(other.key)) return error.Duplicate;
            result.outputs[i] = value;
            if (!value.enabled) { if (value.primary) return error.Primary; continue; }
            enabled += 1;
            const rect = try value.view.logical();
            left = @min(left, rect.x); top = @min(top, rect.y);
            right = @max(right, rect.right()); bottom = @max(bottom, rect.bottom());
            if (right - left > std.math.maxInt(i32) or bottom - top > std.math.maxInt(i32)) return error.Bounds;
            if (value.primary) { primary_count += 1; result.primary = i; }
            for (values[0..i]) |other| {
                if (!other.enabled) continue;
                const previous = try other.view.logical();
                const clone = value.clone_group != 0 and value.clone_group == other.clone_group;
                if (clone and !std.meta.eql(rect, previous)) return error.Clone;
                if (!clone and rect.intersection(previous) != null) return error.Overlap;
            }
        }
        if (enabled == 0) return error.Empty;
        if (primary_count != 1) return error.Primary;
        return result;
    }
    pub fn at(self: *const Layout, point: Point) ?usize {
        if (self.count == 0) return null;
        if (self.outputs[self.primary].view.logicalUnchecked().contains(point)) return self.primary;
        for (self.outputs[0..self.count], 0..) |value, i| if (value.enabled and value.view.logicalUnchecked().contains(point)) return i;
        return null;
    }
    pub fn nearest(self: *const Layout, point: Point) ?struct { index: usize, point: Point } {
        if (self.at(point)) |index| return .{ .index = index, .point = point };
        if (self.count == 0) return null;
        var distance: u128 = std.math.maxInt(u128);
        var best: usize = self.primary; var closest: Point = undefined;
        for (self.outputs[0..self.count], 0..) |value, i| {
            if (!value.enabled) continue;
            const projected = value.view.logicalUnchecked().project(point);
            const dx: i128 = @as(i64, point.x) - projected.x; const dy: i128 = @as(i64, point.y) - projected.y;
            const current: u128 = @intCast(dx * dx + dy * dy);
            if (current < distance or (current == distance and i == self.primary)) {
                distance = current; best = i; closest = projected;
            }
        }
        return .{ .index = best, .point = closest };
    }
    pub fn dominant(self: *const Layout, rect: Rect) ?usize {
        if (self.count == 0 or !rect.valid()) return null;
        var best: usize = self.primary; var area: u64 = 0;
        for (self.outputs[0..self.count], 0..) |value, i| {
            if (!value.enabled) continue;
            if (rect.intersection(value.view.logicalUnchecked())) |part| {
                const current = @as(u64, part.w) * part.h;
                if (current > area or (current == area and i == self.primary)) { best = i; area = current; }
            }
        }
        return best;
    }
    /// Preserve reachable windows. Otherwise restore a draggable titlebar on
    /// the most intersected output, or the primary when completely detached.
    pub fn rescue(self: *const Layout, rect: Rect, title_height: u32) Error!Rect {
        if (!rect.valid() or title_height == 0) return error.Invalid;
        const best = self.dominant(rect) orelse return error.Empty;
        const title = Rect{ .x = rect.x, .y = rect.y, .w = rect.w, .h = @min(rect.h, title_height) };
        for (self.outputs[0..self.count]) |value| {
            if (!value.enabled) continue;
            const region = value.view.logicalUnchecked();
            if (title.intersection(region)) |part| if (part.w >= @min(64, @min(rect.w, region.w)) and
                part.h == @min(title.h, region.h)) return rect;
        }
        const target = self.outputs[best].view.logicalUnchecked();
        const max_x = @max(@as(i64, target.x), target.right() - rect.w);
        const max_y = @max(@as(i64, target.y), target.bottom() - @min(rect.h, target.h));
        const result = Rect{ .x = @intCast(std.math.clamp(@as(i64, rect.x), target.x, max_x)),
            .y = @intCast(std.math.clamp(@as(i64, rect.y), target.y, max_y)), .w = rect.w, .h = rect.h };
        if (!result.valid()) return error.Bounds;
        return result;
    }
};
