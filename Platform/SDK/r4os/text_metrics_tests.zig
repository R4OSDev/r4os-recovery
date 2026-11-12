const std = @import("std");
const a = @import("r4os_contract").abi;
const m = @import("text_metrics.zig");
const wire = @import("binary_cursor.zig");
const program = @import("program.zig");
const gui = @import("gui.zig");
const draw = @import("r4draw.zig");
var new_calls: usize = 0;
var new_bytes: usize = 0;
var old_calls: usize = 0;
var old_bytes: usize = 0;
var revision: u64 = 77;
var mode: u32 = 0;
var reentrant: ?*m.Cache = null;
var busy_seen = false;
fn span(value: []const u8) wire.Span {
    return .{ .address = @intFromPtr(value.ptr), .length = value.len };
}
fn storage(value: []a.FontAdvance2) wire.Span {
    return .{ .address = @intFromPtr(value.ptr), .length = value.len * @sizeOf(a.FontAdvance2) };
}
fn advance(cp: u21) u32 {
    return switch (cp) {
        'i' => 3,
        'W' => 11,
        ' ' => 3,
        0x301, 0x200d => 0,
        else => if (cp > 255) 9 else 5,
    };
}
fn legacy(_: u32, input: [*:0]const u8, out: *a.GuiTextMetrics) callconv(.c) i32 {
    const text = std.mem.span(input);
    old_calls += 1;
    old_bytes += text.len;
    var it = (std.unicode.Utf8View.init(text) catch return -5).iterator();
    var width: u32 = 0;
    var maximum: u32 = 0;
    while (it.nextCodepoint()) |cp| {
        if (cp == '\r') continue;
        if (cp == '\n') {
            maximum = @max(maximum, width);
            width = 0;
            continue;
        }
        width += advance(cp);
    }
    out.* = .{ .width = @max(maximum, width), .height = 16, .line_height = 16, .baseline = 12, .visible_bytes = @intCast(text.len) };
    return 0;
}
fn collect(font_id: u32, input: ?[*]const u8, length: u32, out: ?[*]a.FontAdvance2, capacity: u32, info: *a.FontAdvanceInfo2) callconv(.c) i32 {
    new_calls += 1;
    new_bytes += length;
    if (reentrant) |state| {
        if (state.reset()) |_| return -551 else |err| if (err != error.Busy) return -552;
        const p = state.progress() catch return -553;
        if (p.flags != m.flag_in_call or p.count != 0) return -554;
        busy_seen = true;
    }
    if (mode == 4) return -9;
    const text: []const u8 = if (length == 0) "" else input.?[0..length];
    const view = std.unicode.Utf8View.init(text) catch return -5;
    var scan = view.iterator();
    var required: u32 = 0;
    while (scan.nextCodepointSlice()) |_| required += 1;
    info.* = .{ .font_revision = revision, .font_id = font_id, .text_bytes = length, .required_count = required };
    if (capacity < required) return a.font_metrics2_capacity;
    var it = view.iterator();
    var index: usize = 0;
    var end: u32 = 0;
    var width: u32 = 0;
    var maximum: u32 = 0;
    while (it.nextCodepointSlice()) |part| {
        const cp = std.unicode.utf8Decode(part) catch return -5;
        end += @intCast(part.len);
        if (cp == '\n') {
            maximum = @max(maximum, width);
            width = 0;
        } else if (cp != '\r') width += advance(cp);
        out.?[index] = .{ .byte_end = end, .prefix_width = @max(maximum, width) };
        index += 1;
    }
    info.count = required;
    info.flags = a.font_metrics2_flag_complete;
    if (mode == 1) info.flags |= 2;
    if (mode == 2 and required > 1) out.?[1].prefix_width = 0;
    if (mode == 3 and required != 0) out.?[0].byte_end = 0;
    return 0;
}
test "text metrics owner exact original Canvas offsets and bounded linear preparation" {
    mode = 0;
    revision = 77;
    reentrant = null;
    var table: a.R4XStartR4Draw = .{};
    table.font_measure = @intFromPtr(&legacy);
    const raw: a.R4XStartContext = .{};
    const bundle: program.Bundle = .{ .raw = &raw, .draw = &table };
    const context = draw.Context.init(&bundle);
    const canvas: gui.Canvas = .{ .ctx = &context, .w = 50000, .h = 20 };
    var memory: [4096]a.FontAdvance2 = undefined;
    const ascii = "W" ** 4096;
    for ([_]usize{ 8, 32, 128, 512, 4096 }) |n| {
        old_calls = 0;
        old_bytes = 0;
        new_calls = 0;
        new_bytes = 0;
        try std.testing.expectEqual(n, canvas.textIndexAt(ascii[0..n], std.math.maxInt(i32)));
        try std.testing.expectEqual(n, old_calls);
        try std.testing.expectEqual(n * (n + 1) / 2, old_bytes);
        var cache = try m.Cache.init(span(ascii[0..n]), storage(&memory), memory.len, .{ .measure = &collect });
        const progress = try cache.prepare(9, 0);
        try std.testing.expectEqual(@as(u32, m.flag_complete), progress.flags);
        try std.testing.expectEqual(@as(usize, 1), new_calls);
        try std.testing.expectEqual(n, new_bytes);
        const key = try cache.key();
        for (0..65) |x| _ = try cache.hit(key, @intCast(x));
        try std.testing.expectEqual(@as(u32, @intCast(n)), try cache.hit(key, std.math.maxInt(i32)));
        try std.testing.expectEqual(@as(usize, 1), new_calls);
        try std.testing.expectEqual(n, new_bytes);
        std.debug.print("TX023 n={d} original_calls={d} original_bytes={d} prepares=1 prepare_bytes={d} cached_hits=66 callbacks_after_prepare=0\n", .{ n, old_calls, old_bytes, new_bytes });
    }
    const vectors = [_][]const u8{ "", "iiiWWW", "a\u{301}W", "🙂\u{200d}🙂i", "i\r\nW", "i\nW", "\u{301}\u{301}W", "ä€🙂" };
    for (vectors, 0..) |value, index| {
        var cache = try m.Cache.init(span(value), storage(&memory), memory.len, .{ .measure = &collect });
        _ = try cache.prepare(@intCast(index), 0);
        const key = try cache.key();
        const before = new_calls;
        for (0..65) |x| try std.testing.expectEqual(@as(u32, @intCast(canvas.textIndexAt(value, @intCast(x)))), try cache.hit(key, @intCast(x)));
        try std.testing.expectEqual(before, new_calls);
        var wrong = key;
        wrong.text_revision += 1;
        try std.testing.expectError(error.Stale, cache.hit(wrong, 0));
        wrong = key;
        wrong.font_revision += 1;
        try std.testing.expectError(error.Stale, cache.hit(wrong, 3));
        wrong = key;
        wrong.source_address += 1;
        try std.testing.expectError(error.Stale, cache.hit(wrong, 3));
        try cache.reset();
        try std.testing.expectError(error.Incomplete, cache.key());
    }
}
test "text metrics owner capacity invalid provider encoding alias and exact return boundary" {
    mode = 0;
    revision = 77;
    reentrant = null;
    var memory: [8]a.FontAdvance2 = undefined;
    var cache = try m.Cache.init(span("Wi"), storage(memory[0..1]), 1, .{ .measure = &collect });
    const short = try cache.prepare(1, 0);
    try std.testing.expectEqual(a.font_metrics2_capacity, short.error_code);
    try std.testing.expectEqual(@as(u32, 2), short.required_count);
    try std.testing.expectEqual(@as(u32, 0), short.flags);
    try std.testing.expectError(error.Incomplete, cache.view());
    for ([_]u32{ 1, 2, 3, 4 }) |bad| {
        mode = bad;
        cache = try m.Cache.init(span("Wi"), storage(&memory), memory.len, .{ .measure = &collect });
        const p = try cache.prepare(1, 0);
        try std.testing.expectEqual(if (bad == 4) @as(i32, -9) else m.invalid_provider, p.error_code);
        try std.testing.expectEqual(@as(u32, 0), p.flags);
        try std.testing.expectError(error.Incomplete, cache.view());
    }
    mode = 0;
    for ([_][]const u8{ "\xc3", "a\x00b" }) |bad| {
        cache = try m.Cache.init(span(bad), storage(&memory), memory.len, .{ .measure = &collect });
        const before = new_calls;
        try std.testing.expectEqual(a.font_metrics2_encoding, (try cache.prepare(1, 0)).error_code);
        try std.testing.expectEqual(before, new_calls);
    }
    cache = try m.Cache.init(span("Wi"), storage(&memory), memory.len, .{});
    try std.testing.expectEqual(a.err_no_fn, (try cache.prepare(1, 0)).error_code);
    try std.testing.expectError(error.Incomplete, cache.view());
    const alias = wire.Span{ .address = @intFromPtr(&memory), .length = 1 };
    try std.testing.expectError(error.InvalidStorage, m.Cache.init(alias, storage(&memory), memory.len, .{ .measure = &collect }));
    try std.testing.expectError(error.InvalidStorage, m.Cache.init(.{ .address = std.math.maxInt(usize), .length = 2 }, storage(&memory), memory.len, .{ .measure = &collect }));
    cache = try m.Cache.init(span("Wi"), storage(&memory), memory.len, .{ .measure = &collect });
    reentrant = &cache;
    defer reentrant = null;
    busy_seen = false;
    try std.testing.expectEqual(@as(u32, m.flag_complete), (try cache.prepare(1, 0)).flags);
    try std.testing.expect(busy_seen);
    try std.testing.expectEqual(@as(u32, 0), cache.busy);
}

test "text metrics owner normal Context2 Canvas prepares once and borrows exact cached revisions" {
    const p2 = @import("platform2.zig");
    mode = 0;
    revision = 77;
    reentrant = null;
    var system: p2.abi.R4XStartR4Sys2 = .{};
    var drawing: p2.abi.R4XStartR4Draw2 = .{};
    drawing.font_measure = @intFromPtr(&legacy);
    drawing.font_prefix_metrics2 = @intFromPtr(&collect);
    var imports = [_]a.R4XStartImport{
        .{ .group_id = 1, .resolved_version = 2, .table = @intFromPtr(&system) },
        .{ .group_id = 3, .resolved_version = 2, .table = @intFromPtr(&drawing) },
    };
    var start: p2.abi.R4XStartContext2 = .{ .imports = @intFromPtr(&imports), .import_count = imports.len };
    const context = try p2.Context.init(&start);
    const binding = draw.Context.fromProgram(.{ .generation2 = &context });
    var canvas: gui.Canvas = .{ .ctx = &binding, .w = 50000, .h = 20 };
    const large = "W" ** 4096;
    old_calls = 0;
    new_calls = 0;
    new_bytes = 0;
    var hit: usize = 0;
    try std.testing.expectEqual(@as(i32, 0), canvas.textIndexChecked(large, std.math.maxInt(i32), &hit));
    try std.testing.expectEqual(@as(usize, 4096), hit);
    try std.testing.expectEqual(@as(usize, 1), new_calls);
    try std.testing.expectEqual(@as(usize, 4096), new_bytes);
    try std.testing.expectEqual(@as(usize, 0), old_calls);

    const text = "iWe\u{301}🙂";
    var memory: [32]a.FontAdvance2 = undefined;
    var cache = try m.Cache.init(span(text), storage(&memory), memory.len, .{ .measure = &collect });
    _ = try cache.prepare(19, 0);
    const key = try cache.key();
    try std.testing.expectEqual(@as(i32, 0), canvas.bindTextMetrics(&cache, &key));
    const calls = new_calls;
    const bytes = new_bytes;
    for (0..66) |x| {
        try std.testing.expectEqual(@as(i32, 0), canvas.textIndexChecked(text, @intCast(x), &hit));
        try std.testing.expectEqual(@as(usize, try cache.hit(key, @intCast(x))), hit);
    }
    try std.testing.expectEqual(calls, new_calls);
    try std.testing.expectEqual(bytes, new_bytes);
    try std.testing.expectEqual(@as(usize, 0), old_calls);
    var other: [text.len]u8 = undefined;
    @memcpy(&other, text);
    hit = 0x1234;
    try std.testing.expectEqual(a.font_metrics2_stale, canvas.textIndexChecked(&other, 8, &hit));
    try std.testing.expectEqual(@as(usize, 0x1234), hit);
    var wrong = key;
    wrong.text_revision += 1;
    try std.testing.expectEqual(a.font_metrics2_stale, canvas.bindTextMetrics(&cache, &wrong));
    canvas.clearTextMetrics();
    drawing.font_prefix_metrics2 = 0;
    try std.testing.expectEqual(a.err_no_fn, canvas.textIndexChecked(text, 8, &hit));
    try std.testing.expectEqual(@as(usize, 0x1234), hit);
    try std.testing.expectEqual(@as(usize, 0), old_calls);
    try std.testing.expectEqual(a.font_metrics2_encoding, canvas.textIndexChecked("\xc3", 8, &hit));
    try std.testing.expectEqual(@as(usize, 0x1234), hit);
    drawing.font_prefix_metrics2 = @intFromPtr(&collect);
    var area = gui.TextArea(32){};
    area.set("iWe\u{301}🙂\nWi");
    const view = gui.TextAreaView.init(12, 2);
    try std.testing.expectEqual(@as(i32, 0), area.hitTestChecked(canvas, 2, 0, view, &hit));
    try std.testing.expectEqual(@as(usize, 1), hit);
    try std.testing.expectEqual(@as(i32, 0), area.hitTestChecked(canvas, 17, 0, view, &hit));
    try std.testing.expectEqual(@as(usize, 5), hit);
    area.scroll_line = 1;
    area.scroll_col = 1;
    try std.testing.expectEqual(@as(i32, 0), area.hitTestChecked(canvas, 2, 0, view, &hit));
    try std.testing.expectEqual(@as(usize, 12), hit);
    drawing.font_prefix_metrics2 = 0;
    hit = 0x1234;
    try std.testing.expectEqual(a.err_no_fn, area.hitTestChecked(canvas, 2, 0, view, &hit));
    try std.testing.expectEqual(@as(usize, 0x1234), hit);
    try std.testing.expectEqual(@as(usize, 0), old_calls);
    std.debug.print("TX042 normal Canvas input4096 callbacks1 legacy0; bound hits66 additional_callbacks0; exact source/revision failures preserve output\n", .{});
}
