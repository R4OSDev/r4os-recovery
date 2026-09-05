const std = @import("std");
const abi = @import("r4os_contract").abi;

pub const Error = error{
    BufferTooSmall,
    InvalidValue,
    SegmentLimit,
};

pub const Point = struct { x: f32, y: f32 };
pub const FillRule = enum { nonzero, evenodd };
pub const LineJoin = enum { miter, round, bevel };
pub const LineCap = enum { butt, round, square };

pub const Clip = struct {
    x: i32 = 0,
    y: i32 = 0,
    w: u32 = 0,
    h: u32 = 0,
};

pub const Shadow = struct {
    argb: u32 = 0,
    offset_x: f32 = 0,
    offset_y: f32 = 0,
    spread: f32 = 0,
    blur: f32 = 0,
    inset: bool = false,
};

pub const PathStyle = struct {
    fill_rule: FillRule = .nonzero,
    fill_argb: u32 = 0,
    stroke_argb: u32 = 0,
    stroke_width: f32 = 0,
    line_join: LineJoin = .miter,
    line_cap: LineCap = .butt,
    miter_limit: f32 = 4,
    clip: Clip = .{},
    shadow: Shadow = .{},
};

pub const Radii = struct {
    top_left_x: f32 = 0,
    top_left_y: f32 = 0,
    top_right_x: f32 = 0,
    top_right_y: f32 = 0,
    bottom_right_x: f32 = 0,
    bottom_right_y: f32 = 0,
    bottom_left_x: f32 = 0,
    bottom_left_y: f32 = 0,
};

pub const Borders = struct {
    top: f32 = 0,
    right: f32 = 0,
    bottom: f32 = 0,
    left: f32 = 0,
};

pub const RoundedRect = struct {
    x: f32,
    y: f32,
    w: f32,
    h: f32,
    radii: Radii = .{},
    borders: Borders = .{},
    fill_argb: u32 = 0,
    border_argb: u32 = 0,
    clip: Clip = .{},
    shadow: Shadow = .{},
};

fn bits(value: f32, allow_negative: bool, maximum: f32) Error!u32 {
    if (!std.math.isFinite(value) or (!allow_negative and value < 0) or @abs(value) > maximum) return error.InvalidValue;
    return @bitCast(value);
}

fn fillRuleValue(value: FillRule) u32 {
    return switch (value) {
        .nonzero => abi.gui_shape_fill_rule_nonzero,
        .evenodd => abi.gui_shape_fill_rule_evenodd,
    };
}

fn lineJoinValue(value: LineJoin) u32 {
    return switch (value) {
        .miter => abi.gui_shape_line_join_miter,
        .round => abi.gui_shape_line_join_round,
        .bevel => abi.gui_shape_line_join_bevel,
    };
}

fn lineCapValue(value: LineCap) u32 {
    return switch (value) {
        .butt => abi.gui_shape_line_cap_butt,
        .round => abi.gui_shape_line_cap_round,
        .square => abi.gui_shape_line_cap_square,
    };
}

fn applyClip(header: *abi.GuiShapeResource, clip: Clip) Error!void {
    if ((clip.w == 0) != (clip.h == 0) or clip.w > abi.gui_shape_max_dimension or clip.h > abi.gui_shape_max_dimension) return error.InvalidValue;
    header.clip_x = clip.x;
    header.clip_y = clip.y;
    header.clip_w = clip.w;
    header.clip_h = clip.h;
}

fn applyShadow(header: *abi.GuiShapeResource, shadow: Shadow) Error!void {
    header.shadow_argb = shadow.argb;
    header.shadow_offset_x_bits = try bits(shadow.offset_x, true, @floatFromInt(abi.gui_shape_max_coordinate));
    header.shadow_offset_y_bits = try bits(shadow.offset_y, true, @floatFromInt(abi.gui_shape_max_coordinate));
    header.shadow_spread_bits = try bits(shadow.spread, true, @floatFromInt(abi.gui_shape_max_coordinate));
    header.shadow_blur_bits = try bits(shadow.blur, false, @floatFromInt(abi.gui_shape_max_blur_radius));
    if (shadow.inset) header.flags |= abi.gui_shape_flag_shadow_inset;
}

fn writeHeader(output: []u8, header: *const abi.GuiShapeResource) Error!void {
    if (output.len < @sizeOf(abi.GuiShapeResource)) return error.BufferTooSmall;
    @memcpy(output[0..@sizeOf(abi.GuiShapeResource)], std.mem.asBytes(header));
}

pub const PathBuilder = struct {
    output: []u8,
    header: abi.GuiShapeResource,
    length: usize = @sizeOf(abi.GuiShapeResource),
    active: bool = false,

    pub fn init(output: []u8, style: PathStyle) Error!PathBuilder {
        if (output.len < @sizeOf(abi.GuiShapeResource)) return error.BufferTooSmall;
        var header = abi.GuiShapeResource{
            .geometry_kind = abi.gui_shape_geometry_kind_path,
            .fill_rule = fillRuleValue(style.fill_rule),
            .line_join = lineJoinValue(style.line_join),
            .line_cap = lineCapValue(style.line_cap),
            .fill_argb = style.fill_argb,
            .stroke_argb = style.stroke_argb,
            .stroke_width_bits = try bits(style.stroke_width, false, @floatFromInt(abi.gui_shape_max_coordinate)),
            .miter_limit_bits = try bits(style.miter_limit, false, @floatFromInt(abi.gui_shape_max_coordinate)),
        };
        if (style.miter_limit < 1) return error.InvalidValue;
        try applyClip(&header, style.clip);
        try applyShadow(&header, style.shadow);
        try writeHeader(output, &header);
        return .{ .output = output, .header = header };
    }

    fn append(self: *PathBuilder, segment: abi.GuiPathSegment) Error!void {
        if (self.header.segment_count >= abi.gui_shape_max_segments) return error.SegmentLimit;
        const end = std.math.add(usize, self.length, @sizeOf(abi.GuiPathSegment)) catch return error.BufferTooSmall;
        if (end > self.output.len) return error.BufferTooSmall;
        @memcpy(self.output[self.length..end], std.mem.asBytes(&segment));
        self.length = end;
        self.header.segment_count += 1;
    }

    pub fn moveTo(self: *PathBuilder, point: Point) Error!void {
        try self.append(.{
            .kind = abi.gui_path_segment_kind_move,
            .x1_bits = try bits(point.x, true, @floatFromInt(abi.gui_shape_max_coordinate)),
            .y1_bits = try bits(point.y, true, @floatFromInt(abi.gui_shape_max_coordinate)),
        });
        self.active = true;
    }

    pub fn lineTo(self: *PathBuilder, point: Point) Error!void {
        if (!self.active) return error.InvalidValue;
        try self.append(.{
            .kind = abi.gui_path_segment_kind_line,
            .x1_bits = try bits(point.x, true, @floatFromInt(abi.gui_shape_max_coordinate)),
            .y1_bits = try bits(point.y, true, @floatFromInt(abi.gui_shape_max_coordinate)),
        });
    }

    pub fn quadraticTo(self: *PathBuilder, control: Point, endpoint: Point) Error!void {
        if (!self.active) return error.InvalidValue;
        try self.append(.{
            .kind = abi.gui_path_segment_kind_quadratic,
            .x1_bits = try bits(control.x, true, @floatFromInt(abi.gui_shape_max_coordinate)),
            .y1_bits = try bits(control.y, true, @floatFromInt(abi.gui_shape_max_coordinate)),
            .x2_bits = try bits(endpoint.x, true, @floatFromInt(abi.gui_shape_max_coordinate)),
            .y2_bits = try bits(endpoint.y, true, @floatFromInt(abi.gui_shape_max_coordinate)),
        });
    }

    pub fn cubicTo(self: *PathBuilder, first: Point, second: Point, endpoint: Point) Error!void {
        if (!self.active) return error.InvalidValue;
        try self.append(.{
            .kind = abi.gui_path_segment_kind_cubic,
            .x1_bits = try bits(first.x, true, @floatFromInt(abi.gui_shape_max_coordinate)),
            .y1_bits = try bits(first.y, true, @floatFromInt(abi.gui_shape_max_coordinate)),
            .x2_bits = try bits(second.x, true, @floatFromInt(abi.gui_shape_max_coordinate)),
            .y2_bits = try bits(second.y, true, @floatFromInt(abi.gui_shape_max_coordinate)),
            .x3_bits = try bits(endpoint.x, true, @floatFromInt(abi.gui_shape_max_coordinate)),
            .y3_bits = try bits(endpoint.y, true, @floatFromInt(abi.gui_shape_max_coordinate)),
        });
    }

    pub fn close(self: *PathBuilder) Error!void {
        if (!self.active) return error.InvalidValue;
        try self.append(.{ .kind = abi.gui_path_segment_kind_close });
        self.active = false;
    }

    pub fn finish(self: *PathBuilder) Error![]const u8 {
        if (self.header.segment_count == 0) return error.InvalidValue;
        try writeHeader(self.output, &self.header);
        return self.output[0..self.length];
    }
};

pub fn roundedRect(output: []u8, value: RoundedRect) Error![]const u8 {
    const maximum: f32 = @floatFromInt(abi.gui_shape_max_coordinate);
    if (value.w <= 0 or value.h <= 0) return error.InvalidValue;
    var header = abi.GuiShapeResource{
        .geometry_kind = abi.gui_shape_geometry_kind_rounded_rect,
        .fill_rule = abi.gui_shape_fill_rule_nonzero,
        .fill_argb = value.fill_argb,
        .stroke_argb = value.border_argb,
        .geometry_x_bits = try bits(value.x, true, maximum),
        .geometry_y_bits = try bits(value.y, true, maximum),
        .geometry_w_bits = try bits(value.w, false, maximum),
        .geometry_h_bits = try bits(value.h, false, maximum),
        .radius_top_left_x_bits = try bits(value.radii.top_left_x, false, maximum),
        .radius_top_left_y_bits = try bits(value.radii.top_left_y, false, maximum),
        .radius_top_right_x_bits = try bits(value.radii.top_right_x, false, maximum),
        .radius_top_right_y_bits = try bits(value.radii.top_right_y, false, maximum),
        .radius_bottom_right_x_bits = try bits(value.radii.bottom_right_x, false, maximum),
        .radius_bottom_right_y_bits = try bits(value.radii.bottom_right_y, false, maximum),
        .radius_bottom_left_x_bits = try bits(value.radii.bottom_left_x, false, maximum),
        .radius_bottom_left_y_bits = try bits(value.radii.bottom_left_y, false, maximum),
        .border_top_bits = try bits(value.borders.top, false, maximum),
        .border_right_bits = try bits(value.borders.right, false, maximum),
        .border_bottom_bits = try bits(value.borders.bottom, false, maximum),
        .border_left_bits = try bits(value.borders.left, false, maximum),
    };
    try applyClip(&header, value.clip);
    try applyShadow(&header, value.shadow);
    try writeHeader(output, &header);
    return output[0..@sizeOf(abi.GuiShapeResource)];
}

pub fn command(kind: u32, x: i32, y: i32, w: u32, h: u32, resource_offset: u64, resource_bytes: u64) Error!abi.GuiFrameCommand {
    if (kind < abi.gui_frame_command_kind_path_fill or kind > abi.gui_frame_command_kind_shadow or
        w == 0 or h == 0 or w > abi.gui_shape_max_dimension or h > abi.gui_shape_max_dimension) return error.InvalidValue;
    const pixels = std.math.mul(u64, w, h) catch return error.InvalidValue;
    if (pixels > abi.gui_shape_max_pixels or resource_bytes < abi.gui_shape_resource_size) return error.InvalidValue;
    return .{ .kind = kind, .x = x, .y = y, .w = w, .h = h, .resource_offset = resource_offset, .resource_bytes = resource_bytes };
}

test "shape builders preserve one versioned resource per logical command" {
    var bytes: [@sizeOf(abi.GuiShapeResource) + 5 * @sizeOf(abi.GuiPathSegment)]u8 = undefined;
    var empty = try PathBuilder.init(bytes[0..], .{});
    try std.testing.expectError(error.InvalidValue, empty.finish());
    var builder = try PathBuilder.init(bytes[0..], .{ .fill_argb = 0xFF112233, .stroke_width = 2 });
    try builder.moveTo(.{ .x = 1, .y = 2 });
    try builder.lineTo(.{ .x = 5, .y = 2 });
    try builder.quadraticTo(.{ .x = 7, .y = 4 }, .{ .x = 5, .y = 6 });
    try builder.cubicTo(.{ .x = 4, .y = 7 }, .{ .x = 2, .y = 7 }, .{ .x = 1, .y = 6 });
    try builder.close();
    const resource = try builder.finish();
    try std.testing.expectEqual(@as(usize, @sizeOf(abi.GuiShapeResource) + 5 * @sizeOf(abi.GuiPathSegment)), resource.len);
    const shape_command = try command(abi.gui_frame_command_kind_path_fill, 0, 0, 16, 16, 7, resource.len);
    try std.testing.expectEqual(@as(u64, 7), shape_command.resource_offset);
    try std.testing.expectError(error.InvalidValue, builder.lineTo(.{ .x = 0, .y = 0 }));
}
