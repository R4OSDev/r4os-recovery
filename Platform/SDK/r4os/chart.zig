const std = @import("std");

pub const turns_per_circle: u32 = 65_536;

pub const Error = error{
    NoSlices,
    ZeroTotal,
    Overflow,
    OutputTooSmall,
    BadImage,
};

pub const PieSlice = struct {
    value: u64 = 0,
    color: u32 = 0,
};

pub const PieSegment = struct {
    start_turn: u32 = 0,
    end_turn: u32 = 0,
    value: u64 = 0,
    color: u32 = 0,
};

pub const PieSummary = struct {
    total: u64 = 0,
    count: usize = 0,
    skipped: usize = 0,
};

pub fn buildPieSegments(slices: []const PieSlice, out: []PieSegment) Error!PieSummary {
    if (slices.len == 0) return Error.NoSlices;

    var total: u64 = 0;
    var non_zero: usize = 0;
    var skipped: usize = 0;
    for (slices) |slice| {
        if (slice.value == 0) {
            skipped += 1;
            continue;
        }
        if (total > std.math.maxInt(u64) - slice.value) return Error.Overflow;
        total += slice.value;
        non_zero += 1;
    }
    if (total == 0 or non_zero == 0) return Error.ZeroTotal;
    if (non_zero > out.len) return Error.OutputTooSmall;

    var written: usize = 0;
    var cumulative: u128 = 0;
    for (slices) |slice| {
        if (slice.value == 0) continue;
        const start: u32 = if (written == 0) 0 else out[written - 1].end_turn;
        cumulative += slice.value;
        var end: u32 = if (written + 1 == non_zero)
            turns_per_circle
        else
            @intCast((cumulative * turns_per_circle) / total);
        if (end <= start and written + 1 < non_zero) {
            end = if (start < turns_per_circle) start + 1 else turns_per_circle;
        }
        if (end > turns_per_circle) end = turns_per_circle;
        out[written] = .{
            .start_turn = start,
            .end_turn = end,
            .value = slice.value,
            .color = slice.color,
        };
        written += 1;
    }

    return .{ .total = total, .count = written, .skipped = skipped };
}

pub fn drawPie(
    pixels: []u32,
    width: u32,
    height: u32,
    segments: []const PieSegment,
    background: u32,
    border: u32,
) Error!void {
    if (width == 0 or height == 0 or segments.len == 0) return Error.BadImage;
    const width_usize: usize = @intCast(width);
    const height_usize: usize = @intCast(height);
    if (width_usize > std.math.maxInt(usize) / height_usize) return Error.Overflow;
    const needed = width_usize * height_usize;
    if (pixels.len < needed) return Error.BadImage;
    @memset(pixels[0..needed], background);

    const min_dim = if (width < height) width else height;
    if (min_dim < 4) return Error.BadImage;
    const cx: i32 = @intCast(width / 2);
    const cy: i32 = @intCast(height / 2);
    const radius: i32 = @intCast(min_dim / 2 - 1);
    const inner_radius = @max(@as(i32, 0), radius - 1);
    const r2 = radius * radius;
    const inner_r2 = inner_radius * inner_radius;

    var y: u32 = 0;
    while (y < height) : (y += 1) {
        var x: u32 = 0;
        while (x < width) : (x += 1) {
            const dx: i32 = @as(i32, @intCast(x)) - cx;
            const dy: i32 = @as(i32, @intCast(y)) - cy;
            const d2 = dx * dx + dy * dy;
            if (d2 > r2) continue;
            const index = @as(usize, @intCast(y)) * width_usize + @as(usize, @intCast(x));
            if (d2 >= inner_r2) {
                pixels[index] = border;
            } else {
                const turn = (atan2Turns(dy, dx) + 16_384) & (turns_per_circle - 1);
                pixels[index] = colorForTurn(segments, turn);
            }
        }
    }
}

pub fn validateChartHelpers() bool {
    var slices = [_]PieSlice{
        .{ .value = 10, .color = 0x111111 },
        .{ .value = 0, .color = 0x222222 },
        .{ .value = 20, .color = 0x333333 },
        .{ .value = 30, .color = 0x444444 },
    };
    var segments: [4]PieSegment = .{PieSegment{}} ** 4;
    const summary = buildPieSegments(slices[0..], segments[0..]) catch return false;
    if (summary.total != 60 or summary.count != 3 or summary.skipped != 1) return false;
    if (segments[0].start_turn != 0 or segments[summary.count - 1].end_turn != turns_per_circle) return false;
    if (segments[0].end_turn > segments[1].end_turn or segments[1].end_turn > segments[2].end_turn) return false;

    var too_small: [2]PieSegment = .{PieSegment{}} ** 2;
    if (buildPieSegments(slices[0..], too_small[0..])) |_| {
        return false;
    } else |err| {
        if (err != Error.OutputTooSmall) return false;
    }

    var overflow_slices = [_]PieSlice{
        .{ .value = std.math.maxInt(u64), .color = 0x111111 },
        .{ .value = 1, .color = 0x222222 },
    };
    if (buildPieSegments(overflow_slices[0..], segments[0..])) |_| {
        return false;
    } else |err| {
        if (err != Error.Overflow) return false;
    }

    var empty_slices = [_]PieSlice{
        .{ .value = 0, .color = 0x111111 },
    };
    if (buildPieSegments(empty_slices[0..], segments[0..])) |_| {
        return false;
    } else |err| {
        if (err != Error.ZeroTotal) return false;
    }

    var pixels: [16 * 16]u32 = undefined;
    drawPie(pixels[0..], 16, 16, segments[0..summary.count], 0xABCDEF, 0x000000) catch return false;
    var painted: usize = 0;
    for (pixels) |pixel| {
        if (pixel != 0xABCDEF) painted += 1;
    }
    return painted > 0;
}

fn colorForTurn(segments: []const PieSegment, turn: u32) u32 {
    for (segments) |segment| {
        if (turn >= segment.start_turn and turn < segment.end_turn) return segment.color;
    }
    return segments[segments.len - 1].color;
}

fn atan2Turns(y: i32, x: i32) u32 {
    if (x == 0 and y == 0) return 0;
    const yy: i64 = y;
    const xx: i64 = x;
    const abs_y: i64 = if (yy < 0) -yy else yy;
    var angle: i64 = 0;
    if (xx >= 0) {
        const denom = xx + abs_y;
        const r = if (denom == 0) 0 else @divTrunc((xx - abs_y) * 8192, denom);
        angle = 8192 - r;
    } else {
        const denom = abs_y - xx;
        const r = if (denom == 0) 0 else @divTrunc((xx + abs_y) * 8192, denom);
        angle = 24_576 - r;
    }
    if (yy < 0) angle = turns_per_circle - angle;
    while (angle < 0) angle += turns_per_circle;
    while (angle >= turns_per_circle) angle -= turns_per_circle;
    return @intCast(angle);
}
