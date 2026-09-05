const std = @import("std");
const r4os = @import("r4os");

var now_ticks: u64 = 100;
var activity_waits: u32 = 0;
var clipboard_revision: u32 = 7;
var present_count: u32 = 0;
var draw_count: u32 = 0;
var alpha8_count: u32 = 0;
var alpha8_x: i32 = 0;
var alpha8_y: i32 = 0;
var alpha8_width: u32 = 0;
var alpha8_height: u32 = 0;
var alpha8_stride: u32 = 0;
var alpha8_first: u8 = 0;
var frame_begin_count: u32 = 0;
var frame_append_count: u32 = 0;
var frame_commit_count: u32 = 0;
var frame_cancel_count: u32 = 0;
var frame_append_fail_at: u32 = 0;
var captured_command_count: usize = 0;
var captured_resource_len: usize = 0;
var captured_commands = [_]r4os.abi.GuiFrameCommand{.{}} ** 128;
var captured_resources: [8192]u8 = .{0} ** 8192;
var raster_count: u32 = 0;
var event_index: usize = 0;

const raw_events = [_]r4os.abi.GuiEvent{
    .{ .kind = @intFromEnum(r4os.abi.GuiEventKind.resize), .window_id = 4, .tick = 10 },
    .{ .kind = @intFromEnum(r4os.abi.GuiEventKind.key_down), .window_id = 4, .key = 'A', .modifiers = 2, .tick = 11 },
    .{ .kind = @intFromEnum(r4os.abi.GuiEventKind.mouse_down), .window_id = 4, .x = 8, .y = 9, .buttons = 1, .tick = 12 },
    .{ .kind = @intFromEnum(r4os.abi.GuiEventKind.mouse_up), .window_id = 4, .x = 10, .y = 11, .tick = 13 },
    .{ .kind = @intFromEnum(r4os.abi.GuiEventKind.mouse_move), .window_id = 4, .x = 12, .y = 13, .tick = 14 },
    .{ .kind = @intFromEnum(r4os.abi.GuiEventKind.close), .window_id = 4, .tick = 15 },
};

fn fakeWrite(bytes: [*]const u8, length: u32) callconv(.c) i32 {
    _ = bytes;
    return @intCast(length);
}

fn fakePutc(byte: u8) callconv(.c) void {
    _ = byte;
}

fn fakeTicks() callconv(.c) u64 {
    return now_ticks;
}

fn fakeTimeState(out: *r4os.abi.TimeState) callconv(.c) void {
    out.* = .{ .monotonic_ticks = now_ticks, .monotonic_hz = 1000, .valid = 1 };
}

fn fakeShouldClose(context: *const r4os.abi.R4XStartContext) callconv(.c) u32 {
    _ = context;
    return 0;
}

fn fakeWindowId() callconv(.c) i32 {
    return 4;
}

fn fakeWindowInfo(out: *r4os.abi.GuiWindowInfo) callconv(.c) i32 {
    out.* = .{ .window_id = 4, .client_w = 320, .client_h = 200 };
    return 0;
}

fn fakePollEvent(out: *r4os.abi.GuiEvent) callconv(.c) i32 {
    if (event_index >= raw_events.len) return 0;
    out.* = raw_events[event_index];
    event_index += 1;
    return 1;
}

fn fakeSetTitle(title: [*:0]const u8) callconv(.c) i32 {
    return if (std.mem.eql(u8, std.mem.span(title), "Test")) 0 else -1;
}

fn fakeSetMinSize(width: i32, height: i32) callconv(.c) i32 {
    return if (width == 100 and height == 80) 0 else -1;
}

fn fakeClipboardRevision() callconv(.c) u32 {
    return clipboard_revision;
}

fn fakeActivityWait(last_sequence: u64, timeout_ticks: u64, out_sequence: *u64) callconv(.c) i32 {
    activity_waits += 1;
    now_ticks +|= timeout_ticks;
    out_sequence.* = last_sequence;
    return 0;
}

fn fakeClear(rgb: u32) callconv(.c) i32 {
    _ = rgb;
    draw_count += 1;
    return 0;
}

fn fakeRect(x: i32, y: i32, width: u32, height: u32, rgb: u32) callconv(.c) i32 {
    _ = x;
    _ = y;
    _ = width;
    _ = height;
    _ = rgb;
    draw_count += 1;
    return 0;
}

fn fakeText(x: i32, y: i32, text: [*:0]const u8, fg: u32, bg: u32) callconv(.c) i32 {
    _ = x;
    _ = y;
    _ = text;
    _ = fg;
    _ = bg;
    draw_count += 1;
    return 0;
}

fn fakeTextEx(x: i32, y: i32, text: [*:0]const u8, fg: u32, bg: u32, font_id: u32, flags: u32) callconv(.c) i32 {
    _ = font_id;
    _ = flags;
    return fakeText(x, y, text, fg, bg);
}

fn fakeBlit(x: i32, y: i32, width: u32, height: u32, scale: u32, pixels: [*]const u32, pixel_count: u32) callconv(.c) i32 {
    _ = x;
    _ = y;
    _ = scale;
    _ = pixels;
    if (@as(u64, width) * @as(u64, height) > pixel_count) return -3;
    raster_count += 1;
    draw_count += 1;
    return 0;
}

fn fakeAlpha8(x: i32, y: i32, width: u32, height: u32, stride: u32, rgb: u32, alpha: [*]const u8, alpha_len: u32) callconv(.c) i32 {
    _ = rgb;
    if (alpha_len < width) return -1;
    alpha8_count += 1;
    alpha8_x = x;
    alpha8_y = y;
    alpha8_width = width;
    alpha8_height = height;
    alpha8_stride = stride;
    alpha8_first = alpha[0];
    return 0;
}

fn fakePresent() callconv(.c) i32 {
    present_count += 1;
    return 0;
}

fn fakeFrameBegin() callconv(.c) i32 {
    frame_begin_count += 1;
    return r4os.abi.gui_frame_result_ok;
}

fn fakeFrameAppend(commands: ?[*]const r4os.abi.GuiFrameCommand, command_count: u64, resources: ?[*]const u8, resource_len: u64) callconv(.c) i32 {
    if ((commands == null and command_count != 0) or (resources == null and resource_len != 0)) return r4os.abi.gui_frame_error_invalid;
    frame_append_count += 1;
    if (frame_append_fail_at != 0 and frame_append_count == frame_append_fail_at) return r4os.abi.gui_frame_error_oom;
    const command_len = std.math.cast(usize, command_count) orelse return r4os.abi.gui_frame_error_overflow;
    const resource_bytes = std.math.cast(usize, resource_len) orelse return r4os.abi.gui_frame_error_overflow;
    if (command_len > captured_commands.len - captured_command_count or resource_bytes > captured_resources.len - captured_resource_len) return r4os.abi.gui_frame_error_overflow;
    const source_resources: []const u8 = if (resource_bytes == 0) &.{} else resources.?[0..resource_bytes];
    for (if (command_len == 0) (&[_]r4os.abi.GuiFrameCommand{})[0..] else commands.?[0..command_len]) |source| {
        if (source.resource_bytes == 0 and source.resource_offset != 0) return r4os.abi.gui_frame_error_invalid;
        if (source.resource_bytes != 0) {
            const end = std.math.add(u64, source.resource_offset, source.resource_bytes) catch return r4os.abi.gui_frame_error_overflow;
            if (end > resource_len) return r4os.abi.gui_frame_error_invalid;
        }
        var command = source;
        if (command.resource_bytes != 0) command.resource_offset += captured_resource_len;
        captured_commands[captured_command_count] = command;
        captured_command_count += 1;
    }
    @memcpy(captured_resources[captured_resource_len .. captured_resource_len + resource_bytes], source_resources);
    captured_resource_len += resource_bytes;
    return r4os.abi.gui_frame_result_ok;
}

fn fakeFrameCommit() callconv(.c) i32 {
    frame_commit_count += 1;
    return r4os.abi.gui_frame_result_ok;
}

fn fakeFrameCancel() callconv(.c) i32 {
    frame_cancel_count += 1;
    return r4os.abi.gui_frame_result_ok;
}

fn resetFrameCapture() void {
    frame_append_count = 0;
    frame_append_fail_at = 0;
    captured_command_count = 0;
    captured_resource_len = 0;
    @memset(captured_commands[0..], .{});
    @memset(captured_resources[0..], 0);
}

fn fakeFrameInfo(handle: ?*const r4os.abi.ProgramProcessHandle, out: *r4os.abi.GuiFrameInfo) callconv(.c) i32 {
    if (out.version < r4os.abi.gui_frame_info_version or out.size < r4os.abi.gui_frame_info_size) return r4os.abi.gui_frame_error_invalid;
    out.* = .{ .owner = if (handle) |value| value.* else .{}, .committed_generation = 7, .committed_command_count = 1, .committed_resource_bytes = 4 };
    return r4os.abi.gui_frame_result_ok;
}

fn fakeFrameRead(handle: *const r4os.abi.ProgramProcessHandle, expected_generation: u64, commands: ?[*]r4os.abi.GuiFrameCommand, command_capacity: u64, resources: ?[*]u8, resource_capacity: u64, out: *r4os.abi.GuiFrameInfo) callconv(.c) i32 {
    _ = handle;
    if (out.version < r4os.abi.gui_frame_info_version or out.size < r4os.abi.gui_frame_info_size) return r4os.abi.gui_frame_error_invalid;
    out.* = .{ .committed_generation = 7, .committed_command_count = 1, .committed_resource_bytes = 4 };
    if (expected_generation != 7) return r4os.abi.gui_frame_error_stale;
    if (command_capacity < 1 or resource_capacity < 4) return r4os.abi.gui_frame_error_buffer_too_small;
    commands.?[0] = .{ .kind = r4os.abi.gui_frame_command_kind_text, .resource_bytes = 4 };
    @memcpy(resources.?[0..4], "R4OS");
    return r4os.abi.gui_frame_result_ok;
}

fn makeTables(draw_available: bool) struct { r4os.abi.R4XStartR4Sys, r4os.abi.R4XStartR4Desk, r4os.abi.R4XStartR4Draw } {
    var sys: r4os.abi.R4XStartR4Sys = .{};
    sys.write = @intFromPtr(&fakeWrite);
    sys.putc = @intFromPtr(&fakePutc);
    sys.ticks = @intFromPtr(&fakeTicks);
    sys.time_state = @intFromPtr(&fakeTimeState);
    var desk: r4os.abi.R4XStartR4Desk = .{};
    desk.program_window_id = @intFromPtr(&fakeWindowId);
    desk.gui_window_info = @intFromPtr(&fakeWindowInfo);
    desk.gui_poll_event = @intFromPtr(&fakePollEvent);
    desk.gui_set_title = @intFromPtr(&fakeSetTitle);
    desk.gui_set_min_size = @intFromPtr(&fakeSetMinSize);
    desk.clipboard_revision = @intFromPtr(&fakeClipboardRevision);
    desk.desktop_activity_wait = @intFromPtr(&fakeActivityWait);
    var draw: r4os.abi.R4XStartR4Draw = .{};
    draw.gui_clear = @intFromPtr(&fakeClear);
    draw.gui_rect = @intFromPtr(&fakeRect);
    draw.gui_draw_text = @intFromPtr(&fakeText);
    draw.gui_draw_text_ex = @intFromPtr(&fakeTextEx);
    draw.gui_blit = @intFromPtr(&fakeBlit);
    draw.gui_blend_alpha8 = @intFromPtr(&fakeAlpha8);
    if (draw_available) draw.gui_present = @intFromPtr(&fakePresent);
    return .{ sys, desk, draw };
}

fn enableFrameContract(draw: *r4os.abi.R4XStartR4Draw) void {
    draw.gui_frame_begin = @intFromPtr(&fakeFrameBegin);
    draw.gui_frame_append = @intFromPtr(&fakeFrameAppend);
    draw.gui_frame_commit = @intFromPtr(&fakeFrameCommit);
    draw.gui_frame_cancel = @intFromPtr(&fakeFrameCancel);
    draw.gui_frame_info = @intFromPtr(&fakeFrameInfo);
    draw.gui_frame_read = @intFromPtr(&fakeFrameRead);
}

fn readCapturedXrgb(command: r4os.abi.GuiFrameCommand, pixel_index: usize) u32 {
    const start: usize = @intCast(command.resource_offset + pixel_index * 4);
    return @as(u32, captured_resources[start]) |
        (@as(u32, captured_resources[start + 1]) << 8) |
        (@as(u32, captured_resources[start + 2]) << 16);
}

fn replayCaptured(width: usize, height: usize, output: []u32) void {
    std.debug.assert(output.len == width * height);
    for (captured_commands[0..captured_command_count]) |command| switch (command.kind) {
        r4os.abi.gui_frame_command_kind_clear => @memset(output, command.rgb & 0x00FF_FFFF),
        r4os.abi.gui_frame_command_kind_rect => {
            const left: usize = @intCast(@max(0, command.x));
            const top: usize = @intCast(@max(0, command.y));
            const right = @min(width, left + command.w);
            const bottom = @min(height, top + command.h);
            for (top..bottom) |row| @memset(output[row * width + left .. row * width + right], command.rgb & 0x00FF_FFFF);
        },
        r4os.abi.gui_frame_command_kind_raster => {
            if (command.parameter0 != 1) continue;
            for (0..@as(usize, @intCast(command.h))) |row| for (0..@as(usize, @intCast(command.w))) |column| {
                const target_x = command.x + @as(i32, @intCast(column));
                const target_y = command.y + @as(i32, @intCast(row));
                if (target_x < 0 or target_y < 0 or target_x >= width or target_y >= height) continue;
                output[@as(usize, @intCast(target_y)) * width + @as(usize, @intCast(target_x))] = readCapturedXrgb(command, row * command.w + column);
            };
        },
        r4os.abi.gui_frame_command_kind_alpha8 => {
            const start: usize = @intCast(command.resource_offset);
            for (0..@as(usize, @intCast(command.h))) |row| for (0..@as(usize, @intCast(command.w))) |column| {
                const target_x = command.x + @as(i32, @intCast(column));
                const target_y = command.y + @as(i32, @intCast(row));
                if (target_x < 0 or target_y < 0 or target_x >= width or target_y >= height) continue;
                const alpha = captured_resources[start + row * command.w + column];
                if (alpha == 255) output[@as(usize, @intCast(target_y)) * width + @as(usize, @intCast(target_x))] = command.rgb & 0x00FF_FFFF;
            };
        },
        else => {},
    };
}

fn makeApp(tables: anytype, imports: *[3]r4os.abi.R4XStartImport, context: *r4os.abi.R4XStartContext) !r4os.App {
    imports.* = .{
        .{ .group_id = @intFromEnum(r4os.abi.R4LGroup.r4sys), .flags = r4os.abi.r4xstart_import_flag_group_interface, .table = @intFromPtr(&tables[0]) },
        .{ .group_id = @intFromEnum(r4os.abi.R4LGroup.r4desk), .flags = r4os.abi.r4xstart_import_flag_group_interface, .table = @intFromPtr(&tables[1]) },
        .{ .group_id = @intFromEnum(r4os.abi.R4LGroup.r4draw), .flags = r4os.abi.r4xstart_import_flag_group_interface, .table = @intFromPtr(&tables[2]) },
    };
    context.* = .{
        .app_class = @intFromEnum(r4os.abi.R4XStartAppClass.gui),
        .flags = r4os.abi.r4xstart_flag_imports_valid,
        .imports = @intFromPtr(imports),
        .import_count = imports.len,
        .should_close = @intFromPtr(&fakeShouldClose),
    };
    return switch (r4os.App.init(context, .desktop)) {
        .value => |app| app,
        .failure => error.AppInit,
    };
}

test "raw GUI events become typed messages and paint presents once" {
    event_index = 0;
    draw_count = 0;
    alpha8_count = 0;
    present_count = 0;
    var tables = makeTables(true);
    var imports: [3]r4os.abi.R4XStartImport = undefined;
    var context: r4os.abi.R4XStartContext = undefined;
    var app = try makeApp(&tables, &imports, &context);
    var timers: [1]r4os.Timer = .{.{}};
    var window = app.window(timers[0..]) orelse return error.WindowMissing;
    try std.testing.expectEqual(@as(i32, 0), window.setTitle("Test"));
    try std.testing.expectEqual(@as(i32, 0), window.setMinimumSize(100, 80));

    switch (window.pollMessage().?) {
        .resize => |message| try std.testing.expect(message.width == 320 and message.height == 200),
        else => return error.Resize,
    }
    switch (window.pollMessage().?) {
        .key => |message| try std.testing.expect(message.key == 'A' and message.codepoint == 'A' and message.modifiers == 2),
        else => return error.Key,
    }
    switch (window.pollMessage().?) {
        .mouse => |message| try std.testing.expect(message.action == .down and message.x == 8),
        else => return error.Mouse,
    }
    switch (window.pollMessage().?) {
        .mouse => |message| try std.testing.expect(message.action == .up),
        else => return error.Mouse,
    }
    switch (window.pollMessage().?) {
        .mouse => |message| try std.testing.expect(message.action == .move),
        else => return error.Mouse,
    }
    switch (window.pollMessage().?) {
        .close => |id| try std.testing.expectEqual(@as(i32, 4), id),
        else => return error.Close,
    }

    var paint = switch (window.beginPaint()) {
        .paint => |value| value,
        .failure => return error.Paint,
    };
    _ = paint.canvas.clear(0);
    _ = paint.canvas.rect(.{ .x = 1, .y = 2, .w = 3, .h = 4 }, 0xFFFFFF);
    const alpha8 = [_]u8{ 10, 20, 30, 99, 40, 50, 60 };
    try std.testing.expectEqual(@as(i32, 0), paint.canvas.blendAlpha8(-1, -1, 3, 2, 4, 0x336699, alpha8[0..]));
    try std.testing.expectEqual(@as(u32, 1), alpha8_count);
    try std.testing.expectEqual(@as(i32, 0), alpha8_x);
    try std.testing.expectEqual(@as(i32, 0), alpha8_y);
    try std.testing.expectEqual(@as(u32, 2), alpha8_width);
    try std.testing.expectEqual(@as(u32, 1), alpha8_height);
    try std.testing.expectEqual(@as(u32, 4), alpha8_stride);
    try std.testing.expectEqual(@as(u8, 50), alpha8_first);
    try std.testing.expectEqual(@as(i32, 0), paint.present());
    try std.testing.expectEqual(@as(i32, r4os.abi.err_no_fn), paint.present());
    try std.testing.expect(draw_count >= 2 and present_count == 1);
}

test "command clipboard timer wait and missing draw capability stay explicit" {
    event_index = raw_events.len;
    now_ticks = 100;
    activity_waits = 0;
    clipboard_revision = 7;
    var tables = makeTables(true);
    var imports: [3]r4os.abi.R4XStartImport = undefined;
    var context: r4os.abi.R4XStartContext = undefined;
    var app = try makeApp(&tables, &imports, &context);
    var timers: [1]r4os.Timer = .{.{}};
    var window = app.window(timers[0..]) orelse return error.WindowMissing;

    try std.testing.expect(window.events.postCommand(.init(42)));
    switch (window.pollMessage().?) {
        .command => |id| try std.testing.expectEqual(@as(u32, 42), id.value),
        else => return error.Command,
    }
    clipboard_revision = 8;
    switch (window.pollMessage().?) {
        .clipboard => |message| try std.testing.expectEqual(@as(u32, 8), message.revision),
        else => return error.Clipboard,
    }
    try std.testing.expect(timers[0].start(&window.sys, .init(9), .{ .nanoseconds = 2_000_000 }, false));
    switch (window.waitMessage(r4os.time_contract.timeoutFinite(.{ .nanoseconds = 10_000_000 }))) {
        .message => |message| switch (message) {
            .timer => |timer| try std.testing.expectEqual(@as(u32, 9), timer.id.value),
            else => return error.Timer,
        },
        else => return error.TimerWait,
    }
    try std.testing.expect(activity_waits > 0);
    try std.testing.expect(window.waitMessage(r4os.time_contract.timeoutPoll()) == .timed_out);

    var missing_tables = makeTables(false);
    var missing_imports: [3]r4os.abi.R4XStartImport = undefined;
    var missing_context: r4os.abi.R4XStartContext = undefined;
    var missing_app = try makeApp(&missing_tables, &missing_imports, &missing_context);
    try std.testing.expect(missing_app.window(timers[0..]) == null);
}

test "transactional paint and immutable snapshot use the complete frame facade" {
    frame_begin_count = 0;
    frame_commit_count = 0;
    frame_cancel_count = 0;
    resetFrameCapture();
    var tables = makeTables(true);
    enableFrameContract(&tables[2]);
    var imports: [3]r4os.abi.R4XStartImport = undefined;
    var context: r4os.abi.R4XStartContext = undefined;
    var app = try makeApp(&tables, &imports, &context);
    var timers: [1]r4os.Timer = .{.{}};
    var window = app.window(timers[0..]) orelse return error.WindowMissing;
    try std.testing.expect(window.draw.supportsGuiFrameContract());

    var direct = switch (r4os.app_gui.beginPaintForSize(&window.draw, 333, 201)) {
        .paint => |value| value,
        .failure => return error.Paint,
    };
    try std.testing.expectEqual(@as(i32, 333), direct.canvas.w);
    try std.testing.expectEqual(@as(i32, 201), direct.canvas.h);
    direct.discard();
    try std.testing.expectEqual(@as(u32, 1), frame_begin_count);
    try std.testing.expectEqual(@as(u32, 1), frame_cancel_count);

    var full_hd = switch (r4os.app_gui.beginPaintForSize(&window.draw, 1920, 1080)) {
        .paint => |value| value,
        .failure => return error.Paint,
    };
    try std.testing.expectEqual(@as(i32, 1920), full_hd.canvas.w);
    try std.testing.expectEqual(@as(i32, 1080), full_hd.canvas.h);
    try std.testing.expectEqual(r4os.gui.Rect{ .w = 1920, .h = 1080 }, full_hd.canvas.bounds());
    full_hd.discard();
    try std.testing.expectEqual(@as(u32, 2), frame_begin_count);
    try std.testing.expectEqual(@as(u32, 2), frame_cancel_count);

    var paint = switch (window.beginPaint()) {
        .paint => |value| value,
        .failure => return error.Paint,
    };
    const command = [_]r4os.abi.GuiFrameCommand{.{ .kind = r4os.abi.gui_frame_command_kind_text, .resource_bytes = 4 }};
    try std.testing.expectEqual(@as(i32, 0), window.draw.guiFrameAppend(command[0..], "R4OS"));
    try std.testing.expectEqual(@as(i32, 0), paint.present());
    try std.testing.expectEqual(@as(u32, 3), frame_begin_count);
    try std.testing.expectEqual(@as(u32, 1), frame_commit_count);

    const handle = r4os.abi.ProgramProcessHandle{ .instance_id = 4, .generation = 9 };
    var info: r4os.abi.GuiFrameInfo = .{};
    info.version = 0;
    info.size = 0;
    try std.testing.expectEqual(@as(i32, 0), window.draw.guiFrameInfo(&handle, &info));
    try std.testing.expectEqual(r4os.abi.gui_frame_info_version, info.version);
    try std.testing.expectEqual(r4os.abi.gui_frame_info_size, info.size);
    var commands: [1]r4os.abi.GuiFrameCommand = .{.{}};
    var resources: [4]u8 = undefined;
    info.version = 0;
    info.size = 0;
    try std.testing.expectEqual(@as(i32, 0), window.draw.guiFrameRead(&handle, info.committed_generation, commands[0..], resources[0..], &info));
    try std.testing.expectEqualStrings("R4OS", resources[0..]);

    var cancelled = switch (window.beginPaint()) {
        .paint => |value| value,
        .failure => return error.Paint,
    };
    cancelled.discard();
    try std.testing.expectEqual(@as(u32, 3), frame_cancel_count);
}

test "buffered Canvas keeps pixels identical while collapsing draw transitions" {
    frame_begin_count = 0;
    frame_commit_count = 0;
    frame_cancel_count = 0;
    draw_count = 0;
    alpha8_count = 0;
    raster_count = 0;
    resetFrameCapture();
    var tables = makeTables(true);
    enableFrameContract(&tables[2]);
    var imports: [3]r4os.abi.R4XStartImport = undefined;
    var context: r4os.abi.R4XStartContext = undefined;
    var app = try makeApp(&tables, &imports, &context);
    var timers: [1]r4os.Timer = .{.{}};
    var window = app.window(timers[0..]) orelse return error.WindowMissing;
    var paint = switch (r4os.app_gui.beginPaintForSize(&window.draw, 4, 3)) {
        .paint => |value| value,
        .failure => return error.Paint,
    };
    defer paint.discard();

    var command_buffer: [8]r4os.abi.GuiFrameCommand = undefined;
    var resource_buffer: [64]u8 = undefined;
    var builder: r4os.FrameCanvas = undefined;
    const canvas = paint.bufferedCanvas(&builder, command_buffer[0..], resource_buffer[0..]);
    try std.testing.expectEqual(@as(i32, 0), canvas.clear(0));
    try std.testing.expectEqual(@as(i32, 0), canvas.rect(.{ .x = 2, .y = 1, .w = 2, .h = 1 }, 0xCC0000));
    const raster = [_]u32{ 0xAA112233, 0xFF445566 };
    try std.testing.expectEqual(@as(i32, 0), canvas.raster(0, 0, 2, 1, 1, raster[0..]));
    const alpha = [_]u8{ 0, 255, 77, 255, 0 };
    try std.testing.expectEqual(@as(i32, 0), canvas.blendAlpha8(0, 1, 2, 2, 3, 0xFFFFFF, alpha[0..]));
    // A resource-less command after resource-bearing commands must retain the
    // ABI-mandated zero resource offset instead of inheriting the cursor.
    try std.testing.expectEqual(@as(i32, 0), canvas.rect(.{ .x = 3, .y = 2, .w = 1, .h = 1 }, 0x010203));
    try std.testing.expectEqual(@as(i32, 0), paint.present());

    try std.testing.expectEqual(@as(u64, 5), builder.stats.logical_commands);
    try std.testing.expectEqual(@as(u64, 12), builder.stats.resource_bytes);
    try std.testing.expectEqual(@as(u64, 1), builder.stats.flushes);
    try std.testing.expectEqual(@as(u64, 1), builder.stats.append_calls);
    try std.testing.expectEqual(@as(u64, 0), builder.stats.direct_chunks);
    try std.testing.expectEqual(@as(u64, 0), builder.stats.legacy_calls);
    try std.testing.expectEqual(@as(u64, 1), builder.stats.drawTransitions());
    try std.testing.expectEqual(builder.stats.drawTransitions(), builder.stats.frameMutationEntries());
    try std.testing.expectEqual(@as(u32, 0), draw_count);
    try std.testing.expectEqual(@as(u32, 0), alpha8_count);
    try std.testing.expectEqual(@as(u32, 0), raster_count);
    try std.testing.expectEqual(@as(u32, 1), frame_commit_count);
    try std.testing.expectEqual(@as(usize, 5), captured_command_count);
    try std.testing.expectEqual(@as(usize, 12), captured_resource_len);
    try std.testing.expectEqual(@as(u64, 0), captured_commands[4].resource_offset);
    try std.testing.expectEqual(@as(u64, 0), captured_commands[4].resource_bytes);
    try std.testing.expectEqualSlices(u8, &.{ 0x33, 0x22, 0x11, 0, 0x66, 0x55, 0x44, 0 }, captured_resources[0..8]);
    try std.testing.expectEqualSlices(u8, &.{ 0, 255, 255, 0 }, captured_resources[8..12]);

    var pixels: [12]u32 = undefined;
    replayCaptured(4, 3, pixels[0..]);
    const expected = [_]u32{
        0x112233, 0x445566, 0,        0,
        0,        0xFFFFFF, 0xCC0000, 0xCC0000,
        0xFFFFFF, 0,        0,        0x010203,
    };
    try std.testing.expectEqualSlices(u32, expected[0..], pixels[0..]);
    try std.testing.expectEqual(
        std.hash.Wyhash.hash(0, std.mem.sliceAsBytes(expected[0..])),
        std.hash.Wyhash.hash(0, std.mem.sliceAsBytes(pixels[0..])),
    );
}

test "buffered Canvas covers widgets partial flush direct fallback and old tables" {
    frame_begin_count = 0;
    frame_commit_count = 0;
    frame_cancel_count = 0;
    draw_count = 0;
    present_count = 0;
    resetFrameCapture();
    var tables = makeTables(true);
    enableFrameContract(&tables[2]);
    var imports: [3]r4os.abi.R4XStartImport = undefined;
    var context: r4os.abi.R4XStartContext = undefined;
    var app = try makeApp(&tables, &imports, &context);
    var timers: [1]r4os.Timer = .{.{}};
    var window = app.window(timers[0..]) orelse return error.WindowMissing;

    var paint = switch (window.beginPaint()) {
        .paint => |value| value,
        .failure => return error.Paint,
    };
    defer paint.discard();
    var commands: [3]r4os.abi.GuiFrameCommand = undefined;
    var resources: [4]u8 = undefined;
    var builder: r4os.FrameCanvas = undefined;
    const canvas = paint.bufferedCanvas(&builder, commands[0..], resources[0..]);
    var scratch: [32]u8 = undefined;
    try std.testing.expect(canvas.button(.{ .rect = .{ .x = 4, .y = 4, .w = 60, .h = 20 }, .text = "OK", .focused = true }, scratch[0..]) >= 0);
    try std.testing.expectEqual(@as(i32, 0), canvas.text(4, 30, "oversized", 0, 0xFFFFFF));
    var shape_storage: [@sizeOf(r4os.abi.GuiShapeResource)]u8 = undefined;
    const shape_resource = try r4os.gui_shapes.roundedRect(shape_storage[0..], .{ .x = 1, .y = 1, .w = 12, .h = 8, .fill_argb = 0xFF336699 });
    const shape_command = try r4os.gui_shapes.command(r4os.abi.gui_frame_command_kind_rounded_rect, 0, 0, 16, 12, 0, shape_resource.len);
    try std.testing.expectEqual(@as(i32, 0), canvas.frameCommand(shape_command, shape_resource));
    try std.testing.expectEqual(@as(i32, 0), paint.present());
    try std.testing.expect(builder.stats.logical_commands > 4);
    try std.testing.expect(builder.stats.flushes >= 1);
    try std.testing.expectEqual(@as(u64, 2), builder.stats.direct_chunks);
    try std.testing.expect(builder.stats.drawTransitions() < builder.stats.logical_commands);

    // The same facade on an old table uses the established draw calls and
    // PRESENT.  No batch operation is attempted.
    resetFrameCapture();
    draw_count = 0;
    present_count = 0;
    var legacy_tables = makeTables(true);
    var legacy_imports: [3]r4os.abi.R4XStartImport = undefined;
    var legacy_context: r4os.abi.R4XStartContext = undefined;
    var legacy_app = try makeApp(&legacy_tables, &legacy_imports, &legacy_context);
    var legacy_window = legacy_app.window(timers[0..]) orelse return error.WindowMissing;
    var legacy_paint = switch (legacy_window.beginPaint()) {
        .paint => |value| value,
        .failure => return error.Paint,
    };
    defer legacy_paint.discard();
    var legacy_builder: r4os.FrameCanvas = undefined;
    const legacy_canvas = legacy_paint.bufferedCanvas(&legacy_builder, commands[0..], resources[0..]);
    try std.testing.expectEqual(@as(i32, 0), legacy_canvas.clear(0));
    try std.testing.expectEqual(@as(i32, 0), legacy_canvas.rect(.{ .x = 1, .y = 1, .w = 2, .h = 2 }, 1));
    try std.testing.expectEqual(@as(i32, 0), legacy_canvas.text(1, 1, "old", 1, 0));
    try std.testing.expectEqual(@as(i32, 0), legacy_paint.present());
    try std.testing.expectEqual(@as(u64, 3), legacy_builder.stats.legacy_calls);
    try std.testing.expectEqual(@as(u64, 3), legacy_builder.stats.drawTransitions());
    try std.testing.expectEqual(@as(u32, 3), draw_count);
    try std.testing.expectEqual(@as(u32, 1), present_count);
    try std.testing.expectEqual(@as(u32, 0), frame_append_count);
}

test "buffered Canvas cancels a transactional frame after a partial flush failure" {
    frame_begin_count = 0;
    frame_commit_count = 0;
    frame_cancel_count = 0;
    resetFrameCapture();
    frame_append_fail_at = 2;
    var tables = makeTables(true);
    enableFrameContract(&tables[2]);
    var imports: [3]r4os.abi.R4XStartImport = undefined;
    var context: r4os.abi.R4XStartContext = undefined;
    var app = try makeApp(&tables, &imports, &context);
    var timers: [1]r4os.Timer = .{.{}};
    var window = app.window(timers[0..]) orelse return error.WindowMissing;
    var paint = switch (window.beginPaint()) {
        .paint => |value| value,
        .failure => return error.Paint,
    };
    defer paint.discard();
    var commands: [1]r4os.abi.GuiFrameCommand = undefined;
    var resources: [1]u8 = undefined;
    var builder: r4os.FrameCanvas = undefined;
    const canvas = paint.bufferedCanvas(&builder, commands[0..], resources[0..]);
    try std.testing.expectEqual(@as(i32, 0), canvas.rect(.{ .x = 0, .y = 0, .w = 1, .h = 1 }, 1));
    try std.testing.expectEqual(@as(i32, 0), canvas.rect(.{ .x = 1, .y = 0, .w = 1, .h = 1 }, 2));
    try std.testing.expectEqual(@as(i32, r4os.abi.gui_frame_error_oom), canvas.rect(.{ .x = 2, .y = 0, .w = 1, .h = 1 }, 3));
    try std.testing.expectEqual(@as(i32, r4os.abi.gui_frame_error_oom), paint.present());
    try std.testing.expectEqual(@as(u32, 2), frame_append_count);
    try std.testing.expectEqual(@as(u32, 0), frame_commit_count);
    try std.testing.expectEqual(@as(u32, 1), frame_cancel_count);
    try std.testing.expectEqual(@as(u64, 1), builder.stats.failed_calls);
    try std.testing.expectEqual(@as(i32, r4os.abi.err_no_fn), paint.present());
}
