const std = @import("std");
const css = @import("css.zig");

/// Bounds keep malformed CSS and hostile image metadata from turning a paint
/// operation into unbounded CPU work. They are capacities, not allocations.
pub const max_dimension: u32 = 16 * 1024;
pub const max_target_pixels: usize = 4 * 1024 * 1024;
pub const max_tile_pixels: usize = 4 * 1024 * 1024;

pub const Error = error{
    InvalidValue,
    TooLarge,
    InvalidStride,
    BufferTooSmall,
    DimensionMismatch,
};

pub const Size = struct {
    width: u32 = 0,
    height: u32 = 0,

    pub fn empty(self: Size) bool {
        return self.width == 0 or self.height == 0;
    }
};

pub const Radius = struct {
    x: u32 = 0,
    y: u32 = 0,

    pub fn any(self: Radius) bool {
        return self.x != 0 or self.y != 0;
    }
};

/// Elliptical CSS corner radii before the common overlap scale is applied.
pub const Radii = struct {
    top_left: Radius = .{},
    top_right: Radius = .{},
    bottom_right: Radius = .{},
    bottom_left: Radius = .{},

    pub fn any(self: Radii) bool {
        return self.top_left.any() or self.top_right.any() or self.bottom_right.any() or self.bottom_left.any();
    }
};

pub const PlanInput = struct {
    area: Size,
    intrinsic: Size,
    size: css.BackgroundSize = .{},
    position: css.BackgroundPosition = .{},
    repeat: css.BackgroundRepeat = .repeat,
    radii: Radii = .{},
};

/// A plan is local to the background positioning area. `origin_x/y` may be
/// negative for centered or right-aligned images larger than that area.
pub const Plan = struct {
    area: Size,
    tile: Size,
    origin_x: i32 = 0,
    origin_y: i32 = 0,
    repeat_x: bool = true,
    repeat_y: bool = true,
    radii: Radii = .{},

    pub fn empty(self: Plan) bool {
        return self.area.empty() or self.tile.empty();
    }
};

/// Straight-alpha ARGB (`0xAARRGGBB`) view of an image already scaled to the
/// tile dimensions selected by `buildPlan`.
pub const ArgbTile = struct {
    pixels: []const u32,
    width: u32,
    height: u32,
    stride: u32,
};

/// Straight-alpha ARGB destination. Padding between rows is preserved.
pub const ArgbRaster = struct {
    pixels: []u32,
    width: u32,
    height: u32,
    stride: u32,
};

/// Computes one deterministic, integer-pixel CSS background layer. The caller
/// remains responsible for decoding and scaling the selected image to `tile`.
pub fn buildPlan(input: PlanInput) Error!Plan {
    try validateVisibleSize(input.area, max_target_pixels);
    const radii = normalizeRadii(input.area, input.radii);
    const repeats = repeatAxes(input.repeat);
    if (input.area.empty() or input.intrinsic.empty()) {
        return .{
            .area = input.area,
            .tile = .{},
            .repeat_x = repeats.x,
            .repeat_y = repeats.y,
            .radii = radii,
        };
    }

    var tile = try backgroundSize(input.area, input.intrinsic, input.size);
    if (tile.empty()) tile = .{};
    try validateVisibleSize(tile, max_tile_pixels);
    return .{
        .area = input.area,
        .tile = tile,
        .origin_x = try positionOffset(input.area.width, tile.width, input.position.x),
        .origin_y = try positionOffset(input.area.height, tile.height, input.position.y),
        .repeat_x = repeats.x,
        .repeat_y = repeats.y,
        .radii = radii,
    };
}

/// Applies the CSS corner-overlap rule with one common scale factor. Scaling
/// all corners together is important: independently clamping every corner to
/// half the box changes asymmetric CSS radii.
pub fn normalizeRadii(area: Size, radii: Radii) Radii {
    if (area.empty() or !radii.any()) return .{};
    var numerator: u64 = 1;
    var denominator: u64 = 1;
    considerRadiusLimit(area.width, @as(u64, radii.top_left.x) + radii.top_right.x, &numerator, &denominator);
    considerRadiusLimit(area.width, @as(u64, radii.bottom_left.x) + radii.bottom_right.x, &numerator, &denominator);
    considerRadiusLimit(area.height, @as(u64, radii.top_left.y) + radii.bottom_left.y, &numerator, &denominator);
    considerRadiusLimit(area.height, @as(u64, radii.top_right.y) + radii.bottom_right.y, &numerator, &denominator);
    return .{
        .top_left = scaleCorner(radii.top_left, numerator, denominator),
        .top_right = scaleCorner(radii.top_right, numerator, denominator),
        .bottom_right = scaleCorner(radii.bottom_right, numerator, denominator),
        .bottom_left = scaleCorner(radii.bottom_left, numerator, denominator),
    };
}

/// Composites a pre-scaled tile over `target` using straight-alpha source-over.
/// Pixels outside a no-repeat axis or the normalized rounded clip are untouched.
/// The return value is the number of non-transparent source pixels blended.
pub fn composite(plan: Plan, tile: ArgbTile, target: ArgbRaster) Error!usize {
    if (target.width != plan.area.width or target.height != plan.area.height or
        tile.width != plan.tile.width or tile.height != plan.tile.height) return error.DimensionMismatch;
    try validateVisibleSize(.{ .width = target.width, .height = target.height }, max_target_pixels);
    try validateVisibleSize(.{ .width = tile.width, .height = tile.height }, max_tile_pixels);
    try validateRaster(target.pixels.len, target.width, target.height, target.stride);
    try validateRaster(tile.pixels.len, tile.width, tile.height, tile.stride);
    if (plan.empty()) return 0;

    const radii = normalizeRadii(plan.area, plan.radii);
    var blended: usize = 0;
    var y: u32 = 0;
    while (y < target.height) : (y += 1) {
        const tile_y = tileCoordinate(y, plan.origin_y, tile.height, plan.repeat_y) orelse continue;
        var x: u32 = 0;
        while (x < target.width) : (x += 1) {
            if (!insideRoundedClip(x, y, plan.area, radii)) continue;
            const tile_x = tileCoordinate(x, plan.origin_x, tile.width, plan.repeat_x) orelse continue;
            const source = tile.pixels[@as(usize, tile_y) * tile.stride + tile_x];
            if ((source >> 24) == 0) continue;
            const target_index = @as(usize, y) * target.stride + x;
            target.pixels[target_index] = sourceOver(source, target.pixels[target_index]);
            blended += 1;
        }
    }
    return blended;
}

fn backgroundSize(area: Size, intrinsic: Size, value: css.BackgroundSize) Error!Size {
    return switch (value.kind) {
        .auto => intrinsic,
        .contain => scaleContain(area, intrinsic),
        .cover => scaleCover(area, intrinsic),
        .explicit => explicitSize(area, intrinsic, value.width, value.height),
    };
}

fn scaleContain(area: Size, intrinsic: Size) Size {
    if (area.empty() or intrinsic.empty()) return .{};
    const width_limited = @as(u64, area.width) * intrinsic.height <= @as(u64, area.height) * intrinsic.width;
    if (width_limited) {
        return .{
            .width = area.width,
            .height = @max(1, mulDivFloor(intrinsic.height, area.width, intrinsic.width)),
        };
    }
    return .{
        .width = @max(1, mulDivFloor(intrinsic.width, area.height, intrinsic.height)),
        .height = area.height,
    };
}

fn scaleCover(area: Size, intrinsic: Size) Size {
    if (area.empty() or intrinsic.empty()) return .{};
    const width_limited = @as(u64, area.width) * intrinsic.height >= @as(u64, area.height) * intrinsic.width;
    if (width_limited) {
        return .{
            .width = area.width,
            .height = @max(1, mulDivCeil(intrinsic.height, area.width, intrinsic.width)),
        };
    }
    return .{
        .width = @max(1, mulDivCeil(intrinsic.width, area.height, intrinsic.height)),
        .height = area.height,
    };
}

fn explicitSize(area: Size, intrinsic: Size, width_value: css.Length, height_value: css.Length) Error!Size {
    const width = try resolveSizeLength(width_value, area.width);
    const height = try resolveSizeLength(height_value, area.height);
    if (width) |resolved_width| {
        if (height) |resolved_height| return .{ .width = resolved_width, .height = resolved_height };
        return .{
            .width = resolved_width,
            .height = if (resolved_width == 0) 0 else mulDivRound(intrinsic.height, resolved_width, intrinsic.width),
        };
    }
    if (height) |resolved_height| {
        return .{
            .width = if (resolved_height == 0) 0 else mulDivRound(intrinsic.width, resolved_height, intrinsic.height),
            .height = resolved_height,
        };
    }
    return intrinsic;
}

fn resolveSizeLength(value: css.Length, basis: u32) Error!?u32 {
    return switch (value.kind) {
        .auto => null,
        .px => if (value.value < 0) error.InvalidValue else @intCast(value.value),
        .percent => if (value.value < 0)
            error.InvalidValue
        else
            try unsignedI64(@divTrunc(@as(i64, basis) * value.value, 100)),
        else => error.InvalidValue,
    };
}

fn positionOffset(area: u32, tile: u32, value: css.Length) Error!i32 {
    const offset: i64 = switch (value.kind) {
        .auto => 0,
        .px => value.value,
        .percent => @divTrunc((@as(i64, area) - tile) * value.value, 100),
        else => return error.InvalidValue,
    };
    if (offset < std.math.minInt(i32) or offset > std.math.maxInt(i32)) return error.TooLarge;
    return @intCast(offset);
}

const RepeatAxes = struct { x: bool, y: bool };

fn repeatAxes(value: css.BackgroundRepeat) RepeatAxes {
    return switch (value) {
        .repeat => .{ .x = true, .y = true },
        .no_repeat => .{ .x = false, .y = false },
        .repeat_x => .{ .x = true, .y = false },
        .repeat_y => .{ .x = false, .y = true },
    };
}

fn tileCoordinate(position: u32, origin: i32, tile_size: u32, repeat: bool) ?u32 {
    if (tile_size == 0) return null;
    const relative = @as(i64, position) - origin;
    if (!repeat) {
        if (relative < 0 or relative >= tile_size) return null;
        return @intCast(relative);
    }
    return @intCast(@mod(relative, @as(i64, tile_size)));
}

fn insideRoundedClip(x: u32, y: u32, area: Size, radii: Radii) bool {
    if (!radii.any()) return true;
    if (inCornerEllipse(x, y, radii.top_left, radii.top_left.x, radii.top_left.y, true, true)) return true;
    if (x < radii.top_left.x and y < radii.top_left.y) return false;

    const top_right_start = area.width - radii.top_right.x;
    if (inCornerEllipse(x, y, radii.top_right, top_right_start, radii.top_right.y, false, true)) return true;
    if (x >= top_right_start and y < radii.top_right.y) return false;

    const bottom_right_start_x = area.width - radii.bottom_right.x;
    const bottom_right_start_y = area.height - radii.bottom_right.y;
    if (inCornerEllipse(x, y, radii.bottom_right, bottom_right_start_x, bottom_right_start_y, false, false)) return true;
    if (x >= bottom_right_start_x and y >= bottom_right_start_y) return false;

    const bottom_left_start = area.height - radii.bottom_left.y;
    if (inCornerEllipse(x, y, radii.bottom_left, radii.bottom_left.x, bottom_left_start, true, false)) return true;
    if (x < radii.bottom_left.x and y >= bottom_left_start) return false;
    return true;
}

fn inCornerEllipse(x: u32, y: u32, radius: Radius, start_x: u32, start_y: u32, left: bool, top: bool) bool {
    if (radius.x == 0 or radius.y == 0) return false;
    const in_x = if (left) x < radius.x else x >= start_x;
    const in_y = if (top) y < radius.y else y >= start_y;
    if (!in_x or !in_y) return false;
    const center_x = if (left) radius.x else start_x;
    const center_y = if (top) radius.y else start_y;
    const pixel_x = @as(i64, x) * 2 + 1;
    const pixel_y = @as(i64, y) * 2 + 1;
    const center_x2 = @as(i64, center_x) * 2;
    const center_y2 = @as(i64, center_y) * 2;
    const dx = pixel_x - center_x2;
    const dy = pixel_y - center_y2;
    const rx = @as(i128, radius.x) * 2;
    const ry = @as(i128, radius.y) * 2;
    return @as(i128, dx) * dx * ry * ry + @as(i128, dy) * dy * rx * rx <= rx * rx * ry * ry;
}

fn sourceOver(source: u32, destination: u32) u32 {
    const source_alpha = (source >> 24) & 0xFF;
    if (source_alpha == 0) return destination;
    if (source_alpha == 0xFF) return source;
    const destination_alpha = (destination >> 24) & 0xFF;
    const inverse = 255 - source_alpha;
    const destination_factor = (destination_alpha * inverse + 127) / 255;
    const output_alpha = source_alpha + destination_factor;
    if (output_alpha == 0) return 0;
    const red = channelOver((source >> 16) & 0xFF, (destination >> 16) & 0xFF, source_alpha, destination_factor, output_alpha);
    const green = channelOver((source >> 8) & 0xFF, (destination >> 8) & 0xFF, source_alpha, destination_factor, output_alpha);
    const blue = channelOver(source & 0xFF, destination & 0xFF, source_alpha, destination_factor, output_alpha);
    return (output_alpha << 24) | (red << 16) | (green << 8) | blue;
}

fn channelOver(source: u32, destination: u32, source_alpha: u32, destination_factor: u32, output_alpha: u32) u32 {
    return (source * source_alpha + destination * destination_factor + output_alpha / 2) / output_alpha;
}

fn validateVisibleSize(size: Size, maximum_pixels: usize) Error!void {
    if (size.width > max_dimension or size.height > max_dimension) return error.TooLarge;
    const count = std.math.mul(usize, size.width, size.height) catch return error.TooLarge;
    if (count > maximum_pixels) return error.TooLarge;
}

fn validateRaster(buffer_len: usize, width: u32, height: u32, stride: u32) Error!void {
    if (width == 0 or height == 0) return;
    if (stride < width) return error.InvalidStride;
    const last_row = std.math.mul(usize, height - 1, stride) catch return error.TooLarge;
    const required = std.math.add(usize, last_row, width) catch return error.TooLarge;
    if (required > buffer_len) return error.BufferTooSmall;
}

fn considerRadiusLimit(side: u32, sum: u64, numerator: *u64, denominator: *u64) void {
    if (sum == 0) return;
    if (@as(u128, side) * denominator.* < @as(u128, numerator.*) * sum) {
        numerator.* = side;
        denominator.* = sum;
    }
}

fn scaleRadius(radius: u32, numerator: u64, denominator: u64) u32 {
    return @intCast((@as(u64, radius) * numerator) / denominator);
}

fn scaleCorner(radius: Radius, numerator: u64, denominator: u64) Radius {
    return .{
        .x = scaleRadius(radius.x, numerator, denominator),
        .y = scaleRadius(radius.y, numerator, denominator),
    };
}

fn mulDivFloor(left: u32, right: u32, divisor: u32) u32 {
    return @intCast((@as(u64, left) * right) / divisor);
}

fn mulDivCeil(left: u32, right: u32, divisor: u32) u32 {
    const product = @as(u64, left) * right;
    return @intCast((product + divisor - 1) / divisor);
}

fn mulDivRound(left: u32, right: u32, divisor: u32) u32 {
    return @intCast((@as(u64, left) * right + divisor / 2) / divisor);
}

fn unsignedI64(value: i64) Error!u32 {
    if (value < 0 or value > std.math.maxInt(u32)) return error.TooLarge;
    return @intCast(value);
}

fn pixelHash(pixels: []const u32) u64 {
    var hash: u64 = 14695981039346656037;
    for (pixels) |pixel| {
        var shift: u6 = 0;
        while (shift < 32) : (shift += 8) {
            hash = (hash ^ @as(u8, @truncate(pixel >> @as(u5, @intCast(shift))))) *% 1099511628211;
        }
    }
    return hash;
}

test "background plan covers auto contain cover explicit position and repeat axes" {
    const automatic = try buildPlan(.{
        .area = .{ .width = 10, .height = 8 },
        .intrinsic = .{ .width = 4, .height = 2 },
        .position = .{
            .x = .{ .kind = .percent, .value = 50 },
            .y = .{ .kind = .percent, .value = 50 },
        },
        .repeat = .no_repeat,
    });
    try std.testing.expectEqual(Size{ .width = 4, .height = 2 }, automatic.tile);
    try std.testing.expectEqual(@as(i32, 3), automatic.origin_x);
    try std.testing.expectEqual(@as(i32, 3), automatic.origin_y);
    try std.testing.expect(!automatic.repeat_x and !automatic.repeat_y);

    const contain = try buildPlan(.{
        .area = .{ .width = 10, .height = 8 },
        .intrinsic = .{ .width = 4, .height = 2 },
        .size = .{ .kind = .contain },
        .repeat = .repeat_x,
    });
    try std.testing.expectEqual(Size{ .width = 10, .height = 5 }, contain.tile);
    try std.testing.expect(contain.repeat_x and !contain.repeat_y);

    const cover = try buildPlan(.{
        .area = .{ .width = 10, .height = 8 },
        .intrinsic = .{ .width = 4, .height = 2 },
        .size = .{ .kind = .cover },
        .repeat = .repeat_y,
    });
    try std.testing.expectEqual(Size{ .width = 16, .height = 8 }, cover.tile);
    try std.testing.expect(!cover.repeat_x and cover.repeat_y);

    const explicit = try buildPlan(.{
        .area = .{ .width = 10, .height = 8 },
        .intrinsic = .{ .width = 4, .height = 2 },
        .size = .{
            .kind = .explicit,
            .width = .{ .kind = .percent, .value = 50 },
            .height = .{},
        },
        .position = .{
            .x = .{ .kind = .percent, .value = 100 },
            .y = .{ .kind = .percent, .value = 100 },
        },
    });
    try std.testing.expectEqual(Size{ .width = 5, .height = 3 }, explicit.tile);
    try std.testing.expectEqual(@as(i32, 5), explicit.origin_x);
    try std.testing.expectEqual(@as(i32, 5), explicit.origin_y);

    const explicit_both = try buildPlan(.{
        .area = .{ .width = 10, .height = 8 },
        .intrinsic = .{ .width = 4, .height = 2 },
        .size = .{
            .kind = .explicit,
            .width = .{ .kind = .px, .value = 3 },
            .height = .{ .kind = .percent, .value = 50 },
        },
    });
    try std.testing.expectEqual(Size{ .width = 3, .height = 4 }, explicit_both.tile);
}

test "background radii use one CSS overlap scale and preserve asymmetry" {
    const equal = normalizeRadii(
        .{ .width = 10, .height = 6 },
        .{ .top_left = .{ .x = 8, .y = 8 }, .top_right = .{ .x = 8, .y = 8 }, .bottom_right = .{ .x = 8, .y = 8 }, .bottom_left = .{ .x = 8, .y = 8 } },
    );
    try std.testing.expectEqual(Radii{ .top_left = .{ .x = 3, .y = 3 }, .top_right = .{ .x = 3, .y = 3 }, .bottom_right = .{ .x = 3, .y = 3 }, .bottom_left = .{ .x = 3, .y = 3 } }, equal);

    const asymmetric = normalizeRadii(
        .{ .width = 100, .height = 50 },
        .{ .top_left = .{ .x = 80, .y = 80 }, .top_right = .{ .x = 40, .y = 40 }, .bottom_right = .{ .x = 10, .y = 10 }, .bottom_left = .{ .x = 30, .y = 30 } },
    );
    try std.testing.expectEqual(Radii{ .top_left = .{ .x = 36, .y = 36 }, .top_right = .{ .x = 18, .y = 18 }, .bottom_right = .{ .x = 4, .y = 4 }, .bottom_left = .{ .x = 13, .y = 13 } }, asymmetric);
    const elliptical = normalizeRadii(.{ .width = 100, .height = 40 }, .{ .top_left = .{ .x = 70, .y = 8 }, .top_right = .{ .x = 50, .y = 12 }, .bottom_right = .{ .x = 20, .y = 30 }, .bottom_left = .{ .x = 10, .y = 20 } });
    try std.testing.expectEqual(Radii{ .top_left = .{ .x = 58, .y = 6 }, .top_right = .{ .x = 41, .y = 10 }, .bottom_right = .{ .x = 16, .y = 25 }, .bottom_left = .{ .x = 8, .y = 16 } }, elliptical);
    try std.testing.expectEqual(Radii{}, normalizeRadii(.{ .width = 0, .height = 5 }, .{ .top_left = .{ .x = 5, .y = 5 } }));
}

test "background no-repeat composition preserves placement stride and padding" {
    const plan = try buildPlan(.{
        .area = .{ .width = 4, .height = 3 },
        .intrinsic = .{ .width = 2, .height = 2 },
        .position = .{
            .x = .{ .kind = .px, .value = 1 },
            .y = .{ .kind = .px, .value = 1 },
        },
        .repeat = .no_repeat,
    });
    const tile_pixels = [_]u32{ 0xFFFF0000, 0xFF00FF00, 0xFF0000FF, 0xFFFFFFFF };
    var target = [_]u32{0xFF101010} ** 15;
    target[4] = 0xDEADBEEF;
    target[9] = 0xDEADBEEF;
    target[14] = 0xDEADBEEF;
    const count = try composite(
        plan,
        .{ .pixels = &tile_pixels, .width = 2, .height = 2, .stride = 2 },
        .{ .pixels = &target, .width = 4, .height = 3, .stride = 5 },
    );
    try std.testing.expectEqual(@as(usize, 4), count);
    try std.testing.expectEqual(@as(u32, 0xFFFF0000), target[6]);
    try std.testing.expectEqual(@as(u32, 0xFF00FF00), target[7]);
    try std.testing.expectEqual(@as(u32, 0xFF0000FF), target[11]);
    try std.testing.expectEqual(@as(u32, 0xFFFFFFFF), target[12]);
    try std.testing.expectEqual(@as(u32, 0xDEADBEEF), target[4]);
    try std.testing.expectEqual(@as(u32, 0xDEADBEEF), target[9]);
    try std.testing.expectEqual(@as(u32, 0xDEADBEEF), target[14]);
}

test "background repeat modes tile in both directions from a negative phase" {
    const tile_pixels = [_]u32{ 0xFFFF0000, 0xFF00FF00 };
    var repeated = [_]u32{0} ** 10;
    const repeat_plan = Plan{
        .area = .{ .width = 5, .height = 2 },
        .tile = .{ .width = 2, .height = 1 },
        .origin_x = 1,
        .origin_y = 0,
    };
    _ = try composite(
        repeat_plan,
        .{ .pixels = &tile_pixels, .width = 2, .height = 1, .stride = 2 },
        .{ .pixels = &repeated, .width = 5, .height = 2, .stride = 5 },
    );
    const expected = [_]u32{
        0xFF00FF00, 0xFFFF0000, 0xFF00FF00, 0xFFFF0000, 0xFF00FF00,
        0xFF00FF00, 0xFFFF0000, 0xFF00FF00, 0xFFFF0000, 0xFF00FF00,
    };
    try std.testing.expectEqualSlices(u32, &expected, &repeated);
    try std.testing.expectEqual(@as(u64, 4457356443900506413), pixelHash(&repeated));

    var horizontal = [_]u32{0} ** 15;
    var horizontal_plan = repeat_plan;
    horizontal_plan.area = .{ .width = 5, .height = 3 };
    horizontal_plan.origin_y = 1;
    horizontal_plan.repeat_y = false;
    _ = try composite(
        horizontal_plan,
        .{ .pixels = &tile_pixels, .width = 2, .height = 1, .stride = 2 },
        .{ .pixels = &horizontal, .width = 5, .height = 3, .stride = 5 },
    );
    try std.testing.expectEqualSlices(u32, &[_]u32{0} ** 5, horizontal[0..5]);
    try std.testing.expectEqualSlices(u32, expected[0..5], horizontal[5..10]);
    try std.testing.expectEqualSlices(u32, &[_]u32{0} ** 5, horizontal[10..15]);

    var vertical = [_]u32{0} ** 12;
    const vertical_plan = Plan{
        .area = .{ .width = 3, .height = 4 },
        .tile = .{ .width = 1, .height = 2 },
        .origin_x = 1,
        .origin_y = 1,
        .repeat_x = false,
        .repeat_y = true,
    };
    _ = try composite(
        vertical_plan,
        .{ .pixels = &tile_pixels, .width = 1, .height = 2, .stride = 1 },
        .{ .pixels = &vertical, .width = 3, .height = 4, .stride = 3 },
    );
    const expected_vertical = [_]u32{
        0, 0xFF00FF00, 0,
        0, 0xFFFF0000, 0,
        0, 0xFF00FF00, 0,
        0, 0xFFFF0000, 0,
    };
    try std.testing.expectEqualSlices(u32, &expected_vertical, &vertical);
}

test "background rounded clip and straight alpha composition are deterministic" {
    const plan = try buildPlan(.{
        .area = .{ .width = 5, .height = 5 },
        .intrinsic = .{ .width = 1, .height = 1 },
        .repeat = .repeat,
        .radii = .{ .top_left = .{ .x = 2, .y = 2 }, .top_right = .{ .x = 2, .y = 2 }, .bottom_right = .{ .x = 2, .y = 2 }, .bottom_left = .{ .x = 2, .y = 2 } },
    });
    const tile_pixels = [_]u32{0x80FF0000};
    var target = [_]u32{0xFF0000FF} ** 25;
    const count = try composite(
        plan,
        .{ .pixels = &tile_pixels, .width = 1, .height = 1, .stride = 1 },
        .{ .pixels = &target, .width = 5, .height = 5, .stride = 5 },
    );
    try std.testing.expectEqual(@as(usize, 21), count);
    try std.testing.expectEqual(@as(u32, 0xFF0000FF), target[0]);
    try std.testing.expectEqual(@as(u32, 0xFF80007F), target[12]);
    try std.testing.expectEqual(@as(u64, 2963697680959417507), pixelHash(&target));
}

test "background transparent and degenerate tiles leave the target unchanged" {
    const transparent = [_]u32{0x00123456};
    var target = [_]u32{ 0x10203040, 0x50607080, 0x90A0B0C0, 0xD0E0F000 };
    const original = target;
    const plan = try buildPlan(.{
        .area = .{ .width = 2, .height = 2 },
        .intrinsic = .{ .width = 1, .height = 1 },
    });
    try std.testing.expectEqual(@as(usize, 0), try composite(
        plan,
        .{ .pixels = &transparent, .width = 1, .height = 1, .stride = 1 },
        .{ .pixels = &target, .width = 2, .height = 2, .stride = 2 },
    ));
    try std.testing.expectEqualSlices(u32, &original, &target);

    const empty_plan = try buildPlan(.{ .area = .{}, .intrinsic = .{ .width = 10, .height = 10 } });
    try std.testing.expect(empty_plan.empty());
    try std.testing.expectEqual(@as(usize, 0), try composite(
        empty_plan,
        .{ .pixels = &.{}, .width = 0, .height = 0, .stride = 0 },
        .{ .pixels = target[0..0], .width = 0, .height = 0, .stride = 0 },
    ));

    const zero_tile = try buildPlan(.{ .area = .{ .width = 2, .height = 2 }, .intrinsic = .{} });
    try std.testing.expect(zero_tile.empty());
    try std.testing.expectEqual(@as(usize, 0), try composite(
        zero_tile,
        .{ .pixels = &.{}, .width = 0, .height = 0, .stride = 0 },
        .{ .pixels = &target, .width = 2, .height = 2, .stride = 2 },
    ));

    const explicit_zero = try buildPlan(.{
        .area = .{ .width = 2, .height = 2 },
        .intrinsic = .{ .width = 1, .height = 1 },
        .size = .{
            .kind = .explicit,
            .width = .{ .kind = .percent, .value = 0 },
            .height = .{ .kind = .px, .value = 2 },
        },
        .repeat = .no_repeat,
    });
    try std.testing.expectEqual(Size{}, explicit_zero.tile);
    try std.testing.expect(!explicit_zero.repeat_x and !explicit_zero.repeat_y);
}

test "background raster contracts reject mismatches overflow and short buffers" {
    const plan = Plan{ .area = .{ .width = 2, .height = 2 }, .tile = .{ .width = 1, .height = 1 } };
    const tile = [_]u32{0xFFFFFFFF};
    var target = [_]u32{0} ** 4;
    try std.testing.expectError(error.InvalidStride, composite(
        plan,
        .{ .pixels = &tile, .width = 1, .height = 1, .stride = 1 },
        .{ .pixels = &target, .width = 2, .height = 2, .stride = 1 },
    ));
    try std.testing.expectError(error.BufferTooSmall, composite(
        plan,
        .{ .pixels = &tile, .width = 1, .height = 1, .stride = 1 },
        .{ .pixels = target[0..3], .width = 2, .height = 2, .stride = 2 },
    ));
    try std.testing.expectError(error.BufferTooSmall, composite(
        plan,
        .{ .pixels = tile[0..0], .width = 1, .height = 1, .stride = 1 },
        .{ .pixels = &target, .width = 2, .height = 2, .stride = 2 },
    ));
    try std.testing.expectError(error.DimensionMismatch, composite(
        plan,
        .{ .pixels = &tile, .width = 1, .height = 1, .stride = 1 },
        .{ .pixels = &target, .width = 1, .height = 2, .stride = 2 },
    ));
    try std.testing.expectError(error.TooLarge, buildPlan(.{
        .area = .{ .width = max_dimension + 1, .height = 1 },
        .intrinsic = .{ .width = 1, .height = 1 },
    }));
    try std.testing.expectError(error.TooLarge, buildPlan(.{
        .area = .{ .width = 4096, .height = 1025 },
        .intrinsic = .{ .width = 1, .height = 1 },
    }));
    try std.testing.expectError(error.InvalidValue, buildPlan(.{
        .area = .{ .width = 10, .height = 10 },
        .intrinsic = .{ .width = 1, .height = 1 },
        .size = .{ .kind = .explicit, .width = .{ .kind = .em, .value = 100 }, .height = .{} },
    }));
}
