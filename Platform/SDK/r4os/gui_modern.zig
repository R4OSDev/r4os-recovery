//! Opt-in presentation for the existing GUI controls. No input or editing engine.
const std = @import("std");
const gui = @import("gui.zig");
const shapes = @import("gui_shapes.zig");
const abi = @import("r4os_contract").abi;
const draw = @import("r4draw.zig");

pub const TextRole = enum { body, caption, heading, display };
pub const SurfaceRole = enum { plain, soft, accent, selected };
pub const FontSet = struct {
    body: u32 = 0,
    caption: u32 = 0,
    heading: u32 = 0,
    display: u32 = 0,

    /// Current renderable catalog, never a guessed font ID or a new font parser.
    pub fn system(context: *const draw.Context) FontSet {
        return .{ .body = closest(context, 12, 400), .caption = closest(context, 12, 400), .heading = closest(context, 24, 700), .display = closest(context, 32, 700) };
    }

    pub fn id(self: FontSet, role: TextRole) u32 {
        return switch (role) {
            .body => self.body,
            .caption => self.caption,
            .heading => self.heading,
            .display => self.display,
        };
    }
};

fn closest(context: *const draw.Context, height: u32, weight: u32) u32 {
    var best: u32 = 0;
    var distance: u64 = std.math.maxInt(u64);
    // The provider owns the catalog bound; no unbounded caller-controlled loop.
    for (0..@min(context.fontCount(), 256)) |index| {
        var info: abi.GuiFontInfo = .{};
        if (context.fontInfo(@intCast(index), &info) <= 0 or (info.flags & abi.gui_font_flag_renderable) == 0) continue;
        const family = std.mem.sliceTo(&info.family, 0);
        if (!std.ascii.eqlIgnoreCase(family, "R4 Sans")) continue;
        const dh = @max(height, info.height) - @min(height, info.height);
        const dw = @max(weight, info.weight) - @min(weight, info.weight);
        const score = @as(u64, dh) * 10000 + dw;
        if (score < distance) {
            distance = score;
            best = info.id;
        }
    }
    return best;
}

pub const Style = struct {
    background: u32 = 0xfcfaff,
    surface: u32 = 0xffffff,
    soft: u32 = 0xf4f0fa,
    text: u32 = 0x2c233e,
    muted: u32 = 0x7a6d89,
    accent: u32 = 0x7950d0,
    accent_text: u32 = 0xffffff,
    tint: u32 = 0xf0eafd,
    line: u32 = 0xe8e0ef,
    hover: u32 = 0xe9e0f6,
    pressed: u32 = 0xded0f0,
    disabled: u32 = 0xa89db5,
    radius: i32 = 8,
    gap: i32 = 12,
    padding: i32 = 12,
    page_padding: i32 = 24,
    fonts: FontSet = .{},

    pub fn light() Style {
        return .{};
    }
    pub fn dark() Style {
        return .{ .background = 0x19151e, .surface = 0x211b29, .soft = 0x292132, .text = 0xf7f0ff, .muted = 0xb6a8c6, .accent = 0xb492ef, .accent_text = 0x20152d, .tint = 0x342746, .line = 0x483954, .hover = 0x40304f, .pressed = 0x503b63, .disabled = 0x82728e };
    }
    pub fn withSystemFonts(self: Style, context: *const draw.Context) Style {
        var result = self;
        result.fonts = FontSet.system(context);
        return result;
    }
    pub fn valid(self: Style) bool {
        return self.radius >= 0 and self.radius <= 64 and self.gap >= 0 and self.gap <= 128 and self.padding >= 0 and self.padding <= 128 and self.page_padding >= 0 and self.page_padding <= 256;
    }
    pub fn palette(self: Style) gui.Palette {
        return .{ .text = self.text, .disabled_text = self.disabled, .face = self.soft, .face_light = self.line, .face_shadow = self.line, .client_bg = self.surface, .select_bg = self.accent, .select_text = self.accent_text, .title_bg = self.soft, .title_text = self.text };
    }
    pub fn controlHeight(self: Style, font: gui.FontMetrics) i32 {
        return @max(28, font.line_height + @min(@max(self.padding, 0), 128));
    }
};

/// The current frame transport can carry rounded resources. The renderer must
/// be the matching Desktop. This query does not prove pixels or GPU execution.
pub fn supported(context: *const draw.Context) bool {
    return context.supportsGuiFrameContract();
}

pub fn surface(canvas: gui.Canvas, rect: gui.Rect, fill: u32, border: u32, radius: i32, focus: bool) i32 {
    return rounded(canvas, rect, 0xff000000 | (fill & 0xffffff), border, radius, focus);
}

pub fn outline(canvas: gui.Canvas, rect: gui.Rect, border: u32, radius: i32) i32 {
    return rounded(canvas, rect, 0, border, radius, true);
}

fn rounded(canvas: gui.Canvas, rect: gui.Rect, fill: u32, border: u32, radius: i32, focus: bool) i32 {
    if (rect.isEmpty()) return 0;
    if (radius < 0 or radius > 64 or rect.w > 16384 or rect.h > 16384) return abi.gui_frame_error_invalid;
    var bytes: [160]u8 = undefined;
    const r: f32 = @floatFromInt(@min(radius, @divTrunc(@min(rect.w, rect.h), 2)));
    const shape = shapes.RoundedRect{ .x = 0, .y = 0, .w = @floatFromInt(rect.w), .h = @floatFromInt(rect.h), .radii = .{ .top_left_x = r, .top_left_y = r, .top_right_x = r, .top_right_y = r, .bottom_left_x = r, .bottom_left_y = r, .bottom_right_x = r, .bottom_right_y = r }, .borders = .{ .top = if (focus) 2 else 1, .left = if (focus) 2 else 1, .right = if (focus) 2 else 1, .bottom = if (focus) 2 else 1 }, .fill_argb = fill, .border_argb = 0xff000000 | (border & 0xffffff) };
    const resource = shapes.roundedRect(&bytes, shape) catch return abi.gui_frame_error_invalid;
    const command = shapes.command(abi.gui_frame_command_kind_rounded_rect, rect.x, rect.y, @intCast(rect.w), @intCast(rect.h), 0, resource.len) catch return abi.gui_frame_error_invalid;
    return canvas.frameCommand(command, resource);
}

pub fn button(canvas: gui.Canvas, rect: gui.Rect, scratch: []u8, text: []const u8, state: gui.ButtonState, focus: bool, primary: bool, style: Style) i32 {
    if (!style.valid()) return abi.gui_frame_error_invalid;
    const bg = if (state == .disabled) style.soft else if (state == .pressed) style.pressed else if (state == .hover) style.hover else if (primary) style.accent else style.surface;
    const fg = if (state == .disabled) style.disabled else if (primary and state == .normal) style.accent_text else style.text;
    const rc = surface(canvas, rect, bg, if (focus and state != .disabled) style.accent else style.line, style.radius, focus and state != .disabled);
    if (rc < 0) return rc;
    return gui.drawTextInRect(canvas, rect.inset(@max(4, style.padding), 3), scratch, text, .center, fg, bg);
}

pub const Card = struct {
    rect: gui.Rect,
    title: []const u8,
    subtitle: []const u8 = "",
    state: gui.ButtonState = .normal,
    selected: bool = false,
    focused: bool = false,
    /// Reserve an area for an existing raster/Alpha8/icon resource drawn by the caller.
    icon_width: i32 = 0,

    pub fn contains(self: Card, x: i32, y: i32) bool {
        return self.state != .disabled and self.rect.contains(x, y);
    }
    pub fn keyAction(self: Card, key: u8) gui.ControlAction {
        return if (self.state != .disabled and self.focused and (key == gui.Key.enter or key == ' ')) .submitted else .none;
    }
    pub fn iconRect(self: Card, style: Style) gui.Rect {
        if (!style.valid() or self.icon_width < 0 or self.icon_width > 256) return .{};
        const size = @max(0, @min(self.icon_width, self.rect.h - style.padding * 2));
        return .{ .x = self.rect.x + style.padding, .y = self.rect.y + @divTrunc(self.rect.h - size, 2), .w = size, .h = size };
    }
    pub fn draw(self: Card, canvas: gui.Canvas, scratch: []u8) i32 {
        const style = canvas.style orelse Style.light();
        if (!style.valid() or self.icon_width < 0 or self.icon_width > 256) return abi.gui_frame_error_invalid;
        const bg = if (self.state == .pressed) style.pressed else if (self.state == .hover) style.hover else if (self.selected) style.tint else style.soft;
        const rc = surface(canvas, self.rect, bg, if (self.focused and self.state != .disabled) style.accent else style.line, style.radius, self.focused and self.state != .disabled);
        if (rc < 0) return rc;
        var body = self.rect.inset(style.padding, style.padding);
        if (body.isEmpty()) return 0;
        if (self.icon_width > 0) {
            const skip = @min(body.w, self.icon_width + style.gap);
            body.x += skip;
            body.w -= skip;
        }
        const title_canvas = canvas.withTextRole(.body);
        const top = gui.Rect{ .x = body.x, .y = body.y, .w = body.w, .h = @min(body.h, title_canvas.font.line_height + 4) };
        const result = gui.drawTextInRect(title_canvas, top, scratch, self.title, .left, if (self.state == .disabled) style.disabled else style.text, bg);
        if (result < 0) return result;
        return gui.drawTextInRect(canvas.withTextRole(.caption), .{ .x = body.x, .y = top.bottom() + 2, .w = body.w, .h = @max(0, body.bottom() - top.bottom() - 2) }, scratch, self.subtitle, .left, style.muted, bg);
    }
};

/// Same hit rectangles for paint and input; caller owns scrolling/selection and
/// uses existing FocusState, MouseCapture and Window pointer-capture operations.
pub const TileGrid = struct {
    rect: gui.Rect,
    min_width: i32 = 240,
    row_height: i32 = 76,
    gap: i32 = 12,
    count: usize = 0,
    first_index: usize = 0,

    fn valid(self: TileGrid) bool {
        return self.min_width > 0 and self.min_width <= 16384 and self.row_height > 0 and self.row_height <= 16384 and self.gap >= 0 and self.gap <= 128 and self.rect.w > 0 and self.rect.h > 0 and self.rect.w <= 16384 and self.rect.h <= 16384 and self.rect.x >= -16384 and self.rect.y >= -16384 and self.rect.x <= 16384 and self.rect.y <= 16384;
    }
    pub fn columns(self: TileGrid) usize {
        if (!self.valid()) return 0;
        return @intCast(@max(1, @divTrunc(self.rect.w + self.gap, self.min_width +| self.gap)));
    }
    pub fn visibleCount(self: TileGrid) usize {
        if (!self.valid() or self.first_index >= self.count) return 0;
        const rows: usize = @intCast(@divTrunc(self.rect.h + self.gap, self.row_height +| self.gap));
        return @min(self.count - self.first_index, rows * self.columns());
    }
    pub fn itemRect(self: TileGrid, index: usize) gui.Rect {
        if (index < self.first_index or index - self.first_index >= self.visibleCount()) return .{ .x = 0, .y = 0, .w = 0, .h = 0 };
        const columns_count = self.columns();
        const local = index - self.first_index;
        const width = @divTrunc(self.rect.w - @as(i32, @intCast(columns_count - 1)) * self.gap, @as(i32, @intCast(columns_count)));
        return .{ .x = self.rect.x + @as(i32, @intCast(local % columns_count)) * (width + self.gap), .y = self.rect.y + @as(i32, @intCast(local / columns_count)) * (self.row_height + self.gap), .w = width, .h = self.row_height };
    }
    pub fn indexAt(self: TileGrid, x: i32, y: i32) ?usize {
        const cols = self.columns();
        if (cols == 0 or !self.rect.contains(x, y)) return null;
        const width = @divTrunc(self.rect.w - @as(i32, @intCast(cols - 1)) * self.gap, @as(i32, @intCast(cols)));
        const column: usize = @intCast(@divTrunc(x - self.rect.x, width + self.gap));
        const row: usize = @intCast(@divTrunc(y - self.rect.y, self.row_height + self.gap));
        if (column >= cols) return null;
        const local = row * cols + column;
        if (local >= self.visibleCount()) return null;
        const index = self.first_index + local;
        return if (self.itemRect(index).contains(x, y)) index else null;
    }
};

pub const Paragraph = struct {
    rect: gui.Rect,
    text: []const u8,
    role: TextRole = .body,
    muted: bool = false,
    background: ?u32 = null,
    pub fn draw(self: Paragraph, original: gui.Canvas, scratch: []u8) i32 {
        if (self.rect.isEmpty()) return 0;
        const canvas = original.withTextRole(self.role);
        const style = canvas.style orelse Style.light();
        const cols: usize = @intCast(@max(1, @divTrunc(self.rect.w, @max(1, canvas.font.max_advance))));
        const rows: usize = @intCast(@min(128, @max(0, @divTrunc(self.rect.h, @max(1, canvas.font.line_height)))));
        const layout = gui.textAreaLayout(self.text, 0, cols, 0, rows);
        for (layout.ranges[0..@min(rows, layout.range_count)], 0..) |range, row| {
            const rc = gui.drawTextInRect(canvas, .{ .x = self.rect.x, .y = self.rect.y + @as(i32, @intCast(row)) * canvas.font.line_height, .w = self.rect.w, .h = canvas.font.line_height }, scratch, self.text[range.start..range.end], .left, if (self.muted) style.muted else style.text, self.background orelse style.background);
            if (rc < 0) return rc;
        }
        return 0;
    }
};

pub const Progress = struct {
    rect: gui.Rect,
    completed: u64 = 0,
    total: u64 = 0,
    /// For unknown totals, caller advances this bounded phase on real progress.
    phase: u32 = 0,
    disabled: bool = false,

    pub fn draw(self: Progress, canvas: gui.Canvas) i32 {
        const style = canvas.style orelse Style.light();
        if (!style.valid()) return abi.gui_frame_error_invalid;
        const rc = surface(canvas, self.rect, style.soft, style.line, style.radius, false);
        if (rc < 0) return rc;
        var fill = self.rect.inset(2, 2);
        if (fill.isEmpty()) return 0;
        if (self.total > 0) {
            fill.w = @intCast(@as(u128, @intCast(fill.w)) * @min(self.completed, self.total) / self.total);
        } else {
            const track = fill.w;
            fill.w = @max(1, @divTrunc(track, 4));
            fill.x += @intCast(@as(u64, @intCast(track - fill.w)) * (self.phase % 101) / 100);
        }
        return surface(canvas, fill, if (self.disabled) style.disabled else style.accent, if (self.disabled) style.disabled else style.accent, style.radius, false);
    }
};
