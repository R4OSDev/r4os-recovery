const std = @import("std");

pub const max_surfaces: usize = 8;
pub const max_dimension: u32 = 512;
pub const max_pixels: usize = max_dimension * max_dimension;
pub const max_path_points: usize = 128;
pub const max_text_ops: usize = 32;
pub const max_state_depth: usize = 16;

pub const Error = error{ SurfaceLimit, SizeLimit, AllocationFailed, InvalidSurface };

pub const Allocator = struct {
    context: *anyopaque,
    allocate: *const fn (*anyopaque, usize, usize) ?[*]u8,
    free: *const fn (*anyopaque, [*]u8, usize, usize) void,
};

pub const TextOp = struct {
    x: i32 = 0,
    y: i32 = 0,
    color: u32 = 0,
    length: u8 = 0,
    bytes: [192]u8 = [_]u8{0} ** 192,

    pub fn text(self: *const TextOp) []const u8 {
        return self.bytes[0..self.length];
    }
};

const Point = struct { x: f64 = 0, y: f64 = 0, move: bool = false };
const DrawState = struct { fill_style: u32, stroke_style: u32, line_width: f64, transform: [6]f64 };

pub const SurfaceView = struct {
    width: u32,
    height: u32,
    pixels: []const u32,
    text_ops: []const TextOp,
};

pub const Surface = struct {
    node: u16 = std.math.maxInt(u16),
    width: u32 = 300,
    height: u32 = 150,
    pixels: ?[*]u8 = null,
    pixel_bytes: usize = 0,
    fill_style: u32 = 0,
    stroke_style: u32 = 0,
    line_width: f64 = 1,
    transform: [6]f64 = .{ 1, 0, 0, 1, 0, 0 },
    path: [max_path_points]Point = [_]Point{.{}} ** max_path_points,
    path_count: usize = 0,
    text_ops: [max_text_ops]TextOp = [_]TextOp{.{}} ** max_text_ops,
    text_count: usize = 0,
    states: [max_state_depth]DrawState = undefined,
    state_count: usize = 0,

    fn resetState(self: *Surface) void {
        self.fill_style = 0;
        self.stroke_style = 0;
        self.line_width = 1;
        self.transform = .{ 1, 0, 0, 1, 0, 0 };
        self.path_count = 0;
        self.text_count = 0;
        self.state_count = 0;
    }
};

pub const Manager = struct {
    allocator: Allocator = undefined,
    surfaces: [max_surfaces]Surface = [_]Surface{.{}} ** max_surfaces,

    pub fn initialize(self: *Manager, allocator: Allocator) void {
        self.allocator = allocator;
        self.surfaces = [_]Surface{.{}} ** max_surfaces;
    }

    pub fn deinit(self: *Manager) void {
        for (&self.surfaces) |*surface| self.release(surface);
    }

    pub fn reset(self: *Manager) void {
        for (&self.surfaces) |*surface| self.release(surface);
    }

    pub fn ensure(self: *Manager, node: u16, width: u32, height: u32) Error!*Surface {
        if (self.find(node)) |surface| {
            if (surface.width != width or surface.height != height) try self.resize(surface, width, height);
            return surface;
        }
        for (&self.surfaces) |*surface| {
            if (surface.node != std.math.maxInt(u16)) continue;
            surface.* = .{ .node = node, .width = width, .height = height };
            try self.resize(surface, width, height);
            return surface;
        }
        return error.SurfaceLimit;
    }

    pub fn find(self: *Manager, node: u16) ?*Surface {
        for (&self.surfaces) |*surface| if (surface.node == node) return surface;
        return null;
    }

    pub fn view(self: *const Manager, node: u16) ?SurfaceView {
        for (&self.surfaces) |*surface| {
            if (surface.node != node or surface.pixels == null) continue;
            const raw = surface.pixels.?[0..surface.pixel_bytes];
            const pixels: []const u32 = @as([*]align(@alignOf(u32)) const u32, @ptrCast(@alignCast(raw.ptr)))[0 .. raw.len / @sizeOf(u32)];
            return .{ .width = surface.width, .height = surface.height, .pixels = pixels, .text_ops = surface.text_ops[0..surface.text_count] };
        }
        return null;
    }

    pub fn clearRect(self: *Manager, surface: *Surface, x: f64, y: f64, width: f64, height: f64) void {
        self.fillRectColor(surface, x, y, width, height, 0xFFFFFF);
    }

    pub fn fillRect(self: *Manager, surface: *Surface, x: f64, y: f64, width: f64, height: f64) void {
        self.fillRectColor(surface, x, y, width, height, surface.fill_style);
    }

    pub fn fillRectColor(_: *Manager, surface: *Surface, x: f64, y: f64, width: f64, height: f64, color: u32) void {
        const pixels = pixelSlice(surface) orelse return;
        const origin = transformed(surface, x, y);
        const corner = transformed(surface, x + width, y + height);
        const left: i32 = @intFromFloat(@floor(@min(origin.x, corner.x)));
        const top: i32 = @intFromFloat(@floor(@min(origin.y, corner.y)));
        const right: i32 = @intFromFloat(@ceil(@max(origin.x, corner.x)));
        const bottom: i32 = @intFromFloat(@ceil(@max(origin.y, corner.y)));
        const start_x: u32 = @intCast(@max(left, 0));
        const start_y: u32 = @intCast(@max(top, 0));
        const end_x: u32 = @intCast(@min(right, @as(i32, @intCast(surface.width))));
        const end_y: u32 = @intCast(@min(bottom, @as(i32, @intCast(surface.height))));
        var row = start_y;
        while (row < end_y) : (row += 1) {
            var column = start_x;
            while (column < end_x) : (column += 1) pixels[@as(usize, row) * surface.width + column] = color;
        }
    }

    pub fn setPixel(_: *Manager, surface: *Surface, x: u32, y: u32, color: u32) void {
        if (x >= surface.width or y >= surface.height) return;
        const pixels = pixelSlice(surface) orelse return;
        pixels[@as(usize, y) * surface.width + x] = color;
    }

    pub fn beginPath(_: *Manager, surface: *Surface) void {
        surface.path_count = 0;
    }

    pub fn moveTo(self: *Manager, surface: *Surface, x: f64, y: f64) void {
        self.pathPoint(surface, x, y, true);
    }
    pub fn lineTo(self: *Manager, surface: *Surface, x: f64, y: f64) void {
        self.pathPoint(surface, x, y, false);
    }

    pub fn stroke(_: *Manager, surface: *Surface) void {
        var previous: ?Point = null;
        for (surface.path[0..surface.path_count]) |point| {
            if (point.move or previous == null) {
                previous = point;
                continue;
            }
            drawLine(surface, previous.?, point, surface.stroke_style);
            previous = point;
        }
    }

    pub fn fillText(_: *Manager, surface: *Surface, value: []const u8, x: f64, y: f64) void {
        if (surface.text_count >= surface.text_ops.len) return;
        const point = transformed(surface, x, y);
        var entry = &surface.text_ops[surface.text_count];
        const length = @min(value.len, entry.bytes.len);
        @memcpy(entry.bytes[0..length], value[0..length]);
        entry.* = .{ .x = @intFromFloat(@round(point.x)), .y = @intFromFloat(@round(point.y)), .color = surface.fill_style, .length = @intCast(length), .bytes = entry.bytes };
        surface.text_count += 1;
    }

    pub fn translate(_: *Manager, surface: *Surface, x: f64, y: f64) void {
        surface.transform[4] += surface.transform[0] * x + surface.transform[2] * y;
        surface.transform[5] += surface.transform[1] * x + surface.transform[3] * y;
    }

    pub fn scale(_: *Manager, surface: *Surface, x: f64, y: f64) void {
        surface.transform[0] *= x;
        surface.transform[1] *= x;
        surface.transform[2] *= y;
        surface.transform[3] *= y;
    }

    pub fn setTransform(_: *Manager, surface: *Surface, a: f64, b: f64, c: f64, d: f64, e: f64, f: f64) void {
        surface.transform = .{ a, b, c, d, e, f };
    }

    pub fn rotate(_: *Manager, surface: *Surface, angle: f64) void {
        const cosine = std.math.cos(angle);
        const sine = std.math.sin(angle);
        const a = surface.transform[0];
        const b = surface.transform[1];
        const c = surface.transform[2];
        const d = surface.transform[3];
        surface.transform[0] = a * cosine + c * sine;
        surface.transform[1] = b * cosine + d * sine;
        surface.transform[2] = c * cosine - a * sine;
        surface.transform[3] = d * cosine - b * sine;
    }

    pub fn save(_: *Manager, surface: *Surface) void {
        if (surface.state_count >= surface.states.len) return;
        surface.states[surface.state_count] = .{ .fill_style = surface.fill_style, .stroke_style = surface.stroke_style, .line_width = surface.line_width, .transform = surface.transform };
        surface.state_count += 1;
    }

    pub fn restore(_: *Manager, surface: *Surface) void {
        if (surface.state_count == 0) return;
        surface.state_count -= 1;
        const state = surface.states[surface.state_count];
        surface.fill_style = state.fill_style;
        surface.stroke_style = state.stroke_style;
        surface.line_width = state.line_width;
        surface.transform = state.transform;
    }

    fn pathPoint(_: *Manager, surface: *Surface, x: f64, y: f64, move: bool) void {
        if (surface.path_count >= surface.path.len) return;
        const transformed_point = transformed(surface, x, y);
        surface.path[surface.path_count] = .{ .x = transformed_point.x, .y = transformed_point.y, .move = move };
        surface.path_count += 1;
    }

    fn resize(self: *Manager, surface: *Surface, width: u32, height: u32) Error!void {
        if (width == 0 or height == 0 or width > max_dimension or height > max_dimension) return error.SizeLimit;
        const bytes = @as(usize, width) * height * @sizeOf(u32);
        if (bytes / @sizeOf(u32) > max_pixels) return error.SizeLimit;
        const memory = self.allocator.allocate(self.allocator.context, bytes, @alignOf(u32)) orelse return error.AllocationFailed;
        @memset(memory[0..bytes], 0xFF);
        self.releasePixels(surface);
        surface.width = width;
        surface.height = height;
        surface.pixels = memory;
        surface.pixel_bytes = bytes;
        surface.resetState();
    }

    fn release(self: *Manager, surface: *Surface) void {
        self.releasePixels(surface);
        surface.* = .{};
    }

    fn releasePixels(self: *Manager, surface: *Surface) void {
        if (surface.pixels) |memory| self.allocator.free(self.allocator.context, memory, surface.pixel_bytes, @alignOf(u32));
        surface.pixels = null;
        surface.pixel_bytes = 0;
    }
};

fn transformed(surface: *const Surface, x: f64, y: f64) struct { x: f64, y: f64 } {
    return .{ .x = surface.transform[0] * x + surface.transform[2] * y + surface.transform[4], .y = surface.transform[1] * x + surface.transform[3] * y + surface.transform[5] };
}

fn pixelSlice(surface: *Surface) ?[]u32 {
    const memory = surface.pixels orelse return null;
    return @as([*]align(@alignOf(u32)) u32, @ptrCast(@alignCast(memory)))[0 .. surface.pixel_bytes / @sizeOf(u32)];
}

fn drawLine(surface: *Surface, from: Point, to: Point, color: u32) void {
    const pixels = pixelSlice(surface) orelse return;
    var x0: i32 = @intFromFloat(@round(from.x));
    var y0: i32 = @intFromFloat(@round(from.y));
    const x1: i32 = @intFromFloat(@round(to.x));
    const y1: i32 = @intFromFloat(@round(to.y));
    const dx: i32 = @intCast(@abs(x1 - x0));
    const dy: i32 = -@as(i32, @intCast(@abs(y1 - y0)));
    const step_x: i32 = if (x0 < x1) 1 else -1;
    const step_y: i32 = if (y0 < y1) 1 else -1;
    var error_value = dx + dy;
    while (true) {
        if (x0 >= 0 and y0 >= 0 and x0 < surface.width and y0 < surface.height) pixels[@as(usize, @intCast(y0)) * surface.width + @as(usize, @intCast(x0))] = color;
        if (x0 == x1 and y0 == y1) break;
        const twice = 2 * error_value;
        if (twice >= dy) {
            error_value += dy;
            x0 += step_x;
        }
        if (twice <= dx) {
            error_value += dx;
            y0 += step_y;
        }
    }
}
