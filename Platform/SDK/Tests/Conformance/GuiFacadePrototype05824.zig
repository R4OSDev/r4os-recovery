const std = @import("std");
const r4os = @import("r4os");

test "command clipboard timer Context2 preserves checked clock deadlines and finite limits" {
    const a = r4os.abi;
    const p = r4os.platform2;
    const Fake = struct {
        var now: u64 = 100;
        var ticks: u64 = 10;
        var generation: u32 = 9;
        var hz: u32 = 333;
        var mode: u32 = 0;
        var waits: u32 = 0;
        var clocks: u32 = 0;
        fn clock(out: *a.MonotonicClockInfo) callconv(.c) i32 {
            clocks += 1;
            out.* = .{ .flags = a.monotonic_clock_flag_valid, .source = 1, .generation = generation, .frequency_hz = a.monotonic_clock_frequency_hz, .resolution_ns = 1, .instant_ns = now, .event_requested_hz = hz, .event_effective_hz = hz + 1 };
            return 1;
        }
        fn tick() callconv(.c) u64 {
            return ticks;
        }
        fn poll(_: *a.GuiEvent) callconv(.c) i32 {
            return 0;
        }
        fn close(_: *const p.abi.R4XStartContext2) callconv(.c) u32 {
            return 0;
        }
        fn wait(sequence: u64, duration: u64, _: u32, out: *u64) callconv(.c) i32 {
            std.debug.assert(duration == 1);
            waits += 1;
            switch (mode) {
                0 => now += 10,
                1 => generation += 1,
                else => now -= 1,
            }
            out.* = sequence + 1;
            return 1;
        }
    };
    var sys: p.abi.R4XStartR4Sys2 = .{};
    sys.monotonic_clock = @intFromPtr(&Fake.clock);
    sys.ticks = @intFromPtr(&Fake.tick);
    var desk: p.abi.R4XStartR4Desk2 = .{};
    desk.gui_poll_event = @intFromPtr(&Fake.poll);
    desk.gui_activity_wait = @intFromPtr(&Fake.wait);
    var draw: p.abi.R4XStartR4Draw2 = .{};
    var imports = [_]a.R4XStartImport{
        .{ .group_id = 1, .resolved_version = 2, .table = @intFromPtr(&sys) },
        .{ .group_id = 2, .resolved_version = 2, .table = @intFromPtr(&desk) },
        .{ .group_id = 3, .resolved_version = 2, .table = @intFromPtr(&draw) },
    };
    var raw: p.abi.R4XStartContext2 = .{ .instance_id = 7, .app_class = 2, .flags = a.r4xstart_flag_imports_valid | a.r4xstart_flag_close_supported, .should_close = @intFromPtr(&Fake.close), .imports = @intFromPtr(&imports), .import_count = imports.len };
    var app = switch (r4os.App2.init(&raw, .desktop)) {
        .value => |v| v,
        .failure => return error.App2,
    };
    const system = app.system();
    const desktop = app.desktop().?;
    for (0..3) |mode| {
        Fake.now = 100;
        Fake.generation = 9;
        Fake.hz = 333;
        Fake.mode = @intCast(mode);
        Fake.waits = 0;
        Fake.clocks = 0;
        var loop = r4os.EventLoop.init(system, desktop, &.{});
        const result = loop.wait(.{ .kind = a.timeout_kind_finite, .nanoseconds = 10 });
        switch (result) {
            .timed_out => try std.testing.expectEqual(@as(usize, 0), mode),
            .failure => |status| try std.testing.expectEqual(if (mode == 1) @as(i32, -5) else @as(i32, -6), status),
            else => return error.UnexpectedMessage,
        }
        try std.testing.expectEqual(@as(u32, 1), Fake.waits);
    }
    Fake.now = 100;
    Fake.generation = 9;
    Fake.hz = 333;
    Fake.waits = 0;
    var loop = r4os.EventLoop.init(system, desktop, &.{});
    try std.testing.expectEqual(@as(i32, -3), loop.wait(.{ .kind = a.timeout_kind_finite, .nanoseconds = std.math.maxInt(u64) }).failure);
    try std.testing.expectEqual(@as(u32, 0), Fake.waits);
    Fake.hz = 0;
    Fake.clocks = 0;
    try std.testing.expect(loop.wait(.{ .kind = a.timeout_kind_poll }) == .timed_out);
    try std.testing.expectEqual(@as(u32, 0), Fake.clocks);
    Fake.hz = 333;
    Fake.ticks = std.math.maxInt(u64) - 1;
    var timer: r4os.Timer = .{ .id = .{ .value = 19 }, .active = true };
    const before = timer;
    try std.testing.expect(!timer.start(&system, .{ .value = 20 }, .{ .nanoseconds = 10_000_000 }, false));
    try std.testing.expectEqualDeep(before, timer);
}

test "modern controls preserve classic defaults and share bounded native resources" {
    resetFrameCapture();
    var tables = makeTables(true);
    enableFrameContract(&tables[2]);
    var imports: [3]r4os.abi.R4XStartImport = undefined;
    var context: r4os.platform2.abi.R4XStartContext2 = undefined;
    var app = try makeApp(&tables, &imports, &context);
    const drawing = app.drawing().?;
    var paint = switch (r4os.app_gui.beginPaintForSize(&drawing, 640, 480)) {
        .paint => |value| value,
        .failure => return error.Paint,
    };
    defer paint.discard();
    var commands: [64]r4os.abi.GuiFrameCommand = undefined;
    var resources: [4096]u8 = undefined;
    var builder: r4os.FrameCanvas = undefined;
    const classic = paint.bufferedCanvas(&builder, &commands, &resources);
    try std.testing.expect(classic.style == null);
    const canvas = classic.withStyle(r4os.gui.Style.light());
    var scratch: [128]u8 = undefined;
    for ([_]r4os.gui.ButtonState{ .normal, .hover, .pressed, .disabled }, 0..) |state, i| {
        try std.testing.expectEqual(@as(i32, 0), canvas.actionButton(.{ .x = @intCast(i * 140), .y = 8, .w = 130, .h = 32 }, "Modern", state, true, true, &scratch));
    }
    try std.testing.expectEqual(@as(i32, 0), canvas.progressBar(.{ .x = 8, .y = 56, .w = 200, .h = 16 }, std.math.maxInt(u64) / 2, std.math.maxInt(u64), 0, false));
    try std.testing.expectEqual(@as(i32, 0), canvas.progressBar(.{ .x = 8, .y = 80, .w = 200, .h = 16 }, 0, 0, 95, false));
    var field: r4os.gui.TextField(64) = .{};
    try std.testing.expect(field.setExact("a\u{301}z"));
    field.focused = true;
    try std.testing.expect(field.setPasswordMode(true));
    try std.testing.expectEqual(@as(i32, 0), field.draw(canvas, .{ .x = 8, .y = 112, .w = 180, .h = 32 }, &scratch));
    const items = [_]r4os.gui.TabItem{ .{ .text = "Apps" }, .{ .text = "Libraries", .enabled = false }, .{ .text = "Kernel" } };
    const tabs = canvas.layoutTabs(.{ .rect = .{ .x = 8, .y = 160, .w = 500, .h = 36 }, .items = &items, .focused = true });
    try std.testing.expect(tabs.indexAt(tabs.tabRect(1).x + 1, 165) == null);
    try std.testing.expectEqual(@as(usize, 2), tabs.keyAction(r4os.gui.Key.right).index);
    try std.testing.expectEqual(@as(i32, 0), tabs.draw(canvas, &scratch));
    const labels = [_][]const u8{ "Hover", "Selected", "Disabled" };
    const list = r4os.gui.List{ .rect = .{ .x = 300, .y = 220, .w = 240, .h = 128 }, .items = &labels, .row_h = 32, .selected_index = 1, .hover_index = 0, .disabled_index = 2, .focused = true };
    try std.testing.expectEqual(@as(i32, 0), list.draw(canvas, &scratch));
    const card = r4os.gui.Card{ .rect = .{ .x = 8, .y = 220, .w = 240, .h = 80 }, .title = "Card", .subtitle = "Shared control", .focused = true, .state = .disabled };
    try std.testing.expect(!card.contains(20, 230));
    try std.testing.expectEqual(r4os.gui.ControlAction.none, card.keyAction(r4os.gui.Key.enter));
    try std.testing.expectEqual(@as(i32, 0), card.draw(canvas, &scratch));
    const grid = r4os.gui.TileGrid{ .rect = .{ .x = 10, .y = 10, .w = 492, .h = 164 }, .count = 9 };
    try std.testing.expectEqual(@as(usize, 2), grid.columns());
    try std.testing.expectEqual(@as(usize, 4), grid.visibleCount());
    try std.testing.expectEqual(@as(?usize, 3), grid.indexAt(265, 100));
    try std.testing.expect(grid.indexAt(252, 30) == null); // the inter-card gap
    try std.testing.expect(grid.itemRect(4).isEmpty());
    try std.testing.expectEqual(@as(i32, 0), paint.present());
    try std.testing.expectEqual(r4os.abi.gui_frame_command_kind_rounded_rect, captured_commands[0].kind);
    const fill_offset = @offsetOf(r4os.abi.GuiShapeResource, "fill_argb");
    try std.testing.expectEqual(@as(u32, 0xff7950d0), std.mem.readInt(u32, captured_resources[fill_offset..][0..4], .little));
    try std.testing.expect(std.mem.indexOf(u8, captured_resources[0..captured_resource_len], "a\u{301}z") == null);
    var invalid = r4os.gui.Style.dark();
    invalid.radius = 65;
    var untouched = classic;
    try std.testing.expectEqual(r4os.abi.gui_frame_error_invalid, untouched.setStyle(invalid));
    try std.testing.expect(untouched.style == null);
}

pub export fn sdk_gui_modern_hash() callconv(.c) u64 {
    var hash = std.hash.Wyhash.init(46);
    for (captured_commands[0..captured_command_count]) |command| std.hash.autoHash(&hash, command);
    hash.update(captured_resources[0..captured_resource_len]);
    return hash.final();
}

pub export fn sdk_gui_modern_expected() callconv(.c) u64 {
    resetFrameCapture();
    var tables = makeTables(true);
    enableFrameContract(&tables[2]);
    var imports: [3]r4os.abi.R4XStartImport = undefined;
    var context: r4os.platform2.abi.R4XStartContext2 = undefined;
    var app = makeApp(&tables, &imports, &context) catch return 0;
    const drawing = app.drawing().?;
    var paint = switch (r4os.app_gui.beginPaintForSize(&drawing, 320, 200)) {
        .paint => |value| value,
        .failure => return 0,
    };
    defer paint.discard();
    var commands: [16]r4os.abi.GuiFrameCommand = undefined;
    var resources: [2048]u8 = undefined;
    var builder: r4os.FrameCanvas = undefined;
    const canvas = paint.bufferedCanvas(&builder, &commands, &resources).withStyle(r4os.gui.Style.light());
    var scratch: [64]u8 = undefined;
    if (canvas.actionButton(.{ .x = 10, .y = 10, .w = 120, .h = 32 }, "Modern", .normal, true, true, &scratch) < 0 or canvas.progressBar(.{ .x = 10, .y = 60, .w = 120, .h = 12 }, 25, 100, 0, false) < 0 or paint.present() < 0) return 0;
    return sdk_gui_modern_hash();
}

fn nativeSubmitProbe(queue: *const r4os.abi.GfxQueueHandle, submission: *const r4os.abi.GfxSubmission, native: *const r4os.abi.GfxNativeSubmission, out: *r4os.abi.GfxFenceStatus) callconv(.c) i32 {
    std.debug.assert(queue.timeline == 0x100000003 and submission.operation == r4os.abi.gfx_queue_operation_native);
    std.debug.assert(native.commands == 0x200000009 and out.version == 1 and out.size == 80);
    out.fence.point = 0x300000007;
    return if (native.revision == 1) 1 else -3;
}
fn nativeInfoProbe(fence: *const r4os.abi.GfxFence, out: *r4os.abi.GfxNativeJobInfo) callconv(.c) i32 {
    std.debug.assert(out.version == 1 and out.size == 40);
    out.command_bytes = 2051;
    return if (fence.slot == 7) 1 else -3;
}
fn queueOwnerProbe(binding: *const r4os.abi.GfxBackendBinding, timeline: u64, out: *r4os.abi.GfxQueueOwnerInfo) callconv(.c) i32 {
    std.debug.assert(binding.device_generation == 0x100000017 and timeline == 0x200000009 and out.version == 1 and out.size == 48);
    out.timeline = timeline;
    out.producer_generation = 0x300000005;
    out.closing = 1;
    return if (binding.adapter_id == 17) 1 else if (binding.adapter_id == 18) 0 else -3;
}

fn gfxMapProbe(ref: *const r4os.abi.GfxBufferHandle, access: u32, offset: u64, bytes: u64, out: *r4os.abi.GfxBufferMap) callconv(.c) i32 {
    std.debug.assert(ref.generation == 99 and access == 1 and offset == 0x100000003 and bytes == 0x200000000);
    std.debug.assert(out.version == 1 and out.size == @sizeOf(r4os.abi.GfxBufferMap));
    out.byte_length = bytes;
    return 1;
}
fn gfxWaitProbe(fence: *const r4os.abi.GfxFence, ticks: u64, wait_for: u32, out: *r4os.abi.GfxFenceStatus) callconv(.c) i32 {
    std.debug.assert(fence.point == 0x100000007 and fence.reset_generation == 0x200000001 and ticks == 0x300000003 and wait_for == 1);
    std.debug.assert(out.version == 1 and out.size == 80);
    out.fence = fence.*;
    return 1;
}
fn gfxCompleteProbe(fence: *const r4os.abi.GfxFence, result: u32, quiesced: u32) callconv(.c) i32 {
    std.debug.assert(fence.point == 0x100000007 and result == 6 and quiesced == 0);
    return -4;
}
fn gfxRetainProbe(fence: *const r4os.abi.GfxFence, which: u32, out: *r4os.abi.GfxBufferReference) callconv(.c) i32 {
    std.debug.assert(fence.point == 0x100000007 and fence.reset_generation == 0x200000001 and which == 1);
    std.debug.assert(out.version == 1 and out.size == 48);
    out.reference.generation = 0x400000009;
    out.flags = r4os.abi.gfx_buffer_reference_mapping_only;
    return 1;
}
fn gfxQueuePrefixProbe(out: *r4os.abi.GfxDriverQueueApi) callconv(.c) i32 {
    std.debug.assert(out.version == 1 and out.size == @sizeOf(r4os.abi.GfxDriverQueueApi));
    out.* = .{ .size = 56, .complete = @intFromPtr(&gfxCompleteProbe) };
    return 1;
}
fn motionProbe(out: *r4os.abi.MouseMotion) callconv(.c) i32 {
    out.* = .{ .mouse = std.mem.zeroes(r4os.abi.Mouse), .motion_x = 0xfffffff1, .motion_y = 0x80000003 };
    return 1;
}
fn gridSubmitProbe(queue: *const r4os.abi.GfxQueueHandle, request: *const r4os.abi.GfxSubmission, list: *const r4os.abi.GfxRenderGridList, output: *r4os.abi.GfxFenceStatus) callconv(.c) i32 {
    std.debug.assert(queue.timeline == 0x200000017 and request.operation == r4os.abi.gfx_queue_operation_render_grid_list and
        list.version == 1 and list.size == 2320 and list.count == 1 and list.grids[0].scale == 180 and list.grids[0].rotation == 3);
    output.fence = .{ .slot = 7, .timeline = queue.timeline, .point = 0x300000019 };
    return 1;
}
fn gridReadProbe(fence: *const r4os.abi.GfxFence, output: *r4os.abi.GfxRenderGridList) callconv(.c) i32 {
    std.debug.assert(fence.timeline == 0x200000017 and fence.point == 0x300000019 and output.version == 1 and output.size == 2320);
    output.* = .{ .count = 1 };
    output.grids[0] = .{ .enabled = 1, .scale = 180, .rotation = 3 };
    return 1;
}
fn gridFacadeProbe() !void {
    try captureFacadeProbe();
    try colorFacadeProbe();
    const a = r4os.abi;
    const t = std.testing;
    var tables = makeTables(true);
    var imports: [3]a.R4XStartImport = undefined;
    var raw: r4os.platform2.abi.R4XStartContext2 = undefined;
    var app = try makeApp(&tables, &imports, &raw);
    const legacy: r4os.r4xstart.R4Desk = r4os.r4xstart.R4Desk.fromProgram(app.lowLevel());
    tables[1].mouse_motion = @intFromPtr(&motionProbe);
    tables[1].size = @offsetOf(r4os.platform2.abi.R4XStartR4Desk2, "mouse_motion");
    var motion: a.MouseMotion = .{ .mouse = std.mem.zeroes(a.Mouse), .motion_x = 79 };
    try t.expectEqual(a.err_no_fn, legacy.mouseMotion(&motion));
    try t.expectEqual(@as(u32, 79), motion.motion_x);
    tables[1].size += 8;
    try t.expectEqual(@as(i32, 1), legacy.mouseMotion(&motion));
    try t.expectEqual(@as(u32, 0xfffffff1), motion.motion_x);
    const queues = app.drawing().?.queues();
    tables[2].gfx_queue_submit_render_grid_list = @intFromPtr(&gridSubmitProbe);
    var list: a.GfxRenderGridList = .{ .count = 1 };
    list.grids[0] = .{ .enabled = 1, .scale = 180, .rotation = 3 };
    const queue: a.GfxQueueHandle = .{ .timeline = 0x200000017 };
    const request: a.GfxSubmission = .{ .operation = a.gfx_queue_operation_render_grid_list };
    var result: a.GfxFenceStatus = .{ .deadline_ns = 79 };
    tables[2].size = @offsetOf(r4os.platform2.abi.R4XStartR4Draw2, "gfx_queue_submit_render_grid_list");
    try t.expectEqual(a.err_no_fn, queues.submitRenderGridList(&queue, &request, &list, &result));
    try t.expect(result.deadline_ns == 79 and result.fence.point == 0);
    tables[2].size += 8;
    try t.expectEqual(@as(i32, 1), queues.submitRenderGridList(&queue, &request, &list, &result));
    var driver: r4os.driver_queue.Context = .{ .table = .{ .read_render_grid_list = @intFromPtr(&gridReadProbe) } };
    list.count = 79;
    for (112..120) |size| {
        driver.table.size = @intCast(size);
        try t.expect(!driver.supportsRenderGridList());
        try t.expectEqual(a.err_no_fn, driver.readRenderGridList(&result.fence, &list));
        try t.expectEqual(@as(u32, 79), list.count);
    }
    driver.table.size = 120;
    try t.expect(driver.supportsRenderGridList());
    try t.expectEqual(@as(i32, 1), driver.readRenderGridList(&result.fence, &list));
    try t.expect(list.count == 1 and list.grids[0].rotation == 3 and list.grids[0].scale == 180);
}

fn captureAcquireProbe(expected: u32, info: *r4os.abi.RemoteFrameInfo, lease: *r4os.abi.RemoteFrameLease) callconv(.c) i32 {
    std.debug.assert(expected == 73);
    info.* = .{ .revision = expected, .width = 2, .height = 1, .frame_pixels = 2 };
    lease.* = .{ .id = 0x100000003, .epoch = 0x200000009, .capacity_pixels = 2 };
    return 0;
}
fn captureReleaseProbe(lease: *const r4os.abi.RemoteFrameLease) callconv(.c) i32 {
    std.debug.assert(lease.id == 0x100000003 and lease.epoch == 0x200000009);
    return 0;
}
fn captureResetProbe() callconv(.c) i32 {
    return 0;
}
fn captureStatsProbe(out: *r4os.abi.RemoteFrameCaptureStats) callconv(.c) i32 {
    out.* = .{ .snapshot_copy_bytes = 0x300000007, .leases = 2 };
    return 0;
}
fn captureFacadeProbe() !void {
    const a = r4os.abi;
    const t = std.testing;
    var tables = makeTables(true);
    var imports: [3]a.R4XStartImport = undefined;
    var raw: r4os.platform2.abi.R4XStartContext2 = undefined;
    var app = try makeApp(&tables, &imports, &raw);
    const desk = app.desktop().?;
    const direct: r4os.r4xstart.R4Desk = r4os.r4xstart.R4Desk.fromProgram(app.lowLevel());
    tables[1].remote_frame_snapshot_acquire = @intFromPtr(&captureAcquireProbe);
    tables[1].remote_frame_snapshot_release = @intFromPtr(&captureReleaseProbe);
    tables[1].remote_frame_source_reset = @intFromPtr(&captureResetProbe);
    tables[1].remote_frame_capture_stats = @intFromPtr(&captureStatsProbe);
    tables[1].size = 496;
    var info: a.RemoteFrameInfo = .{ .revision = 17 };
    var lease: a.RemoteFrameLease = .{ .id = 19 };
    try t.expect(desk.remoteFrameSnapshotAcquire(73, &info, &lease) < 0 and info.revision == 17 and lease.id == 19);
    try t.expect(direct.remoteFrameSnapshotRelease(&lease) < 0 and desk.remoteFrameSourceReset() < 0);
    tables[1].size = @sizeOf(r4os.platform2.abi.R4XStartR4Desk2);
    try t.expect(desk.remoteFrameSnapshotAcquire(73, &info, &lease) == 0 and info.revision == 73 and lease.capacity_pixels == 2);
    try t.expect(direct.remoteFrameSnapshotRelease(&lease) == 0 and desk.remoteFrameSourceReset() == 0);
    try t.expect(direct.remoteFrameSnapshotAcquire(73, &info, &lease) == 0 and desk.remoteFrameSnapshotRelease(&lease) == 0);
    var stats: a.RemoteFrameCaptureStats = .{};
    try t.expect(desk.remoteFrameCaptureStats(&stats) == 0 and stats.snapshot_copy_bytes == 0x300000007);
    try t.expect(direct.remoteFrameCaptureStats(&stats) == 0 and direct.remoteFrameSourceReset() == 0);
}
fn colorSubmitProbe(queue: *const r4os.abi.GfxQueueHandle, request: *const r4os.abi.GfxSubmission, list: *const r4os.abi.GfxRenderColorList, output: *r4os.abi.GfxFenceStatus) callconv(.c) i32 {
    std.debug.assert(queue.timeline == 0x200000017 and request.operation == r4os.abi.gfx_queue_operation_render_color_list and
        list.size == 1568 and list.count == 1 and list.program.size == 272 and list.program.words[63] == 0x12345678);
    output.fence = .{ .slot = 7, .timeline = queue.timeline, .point = 0x300000019 };
    return 1;
}
fn colorReadProbe(fence: *const r4os.abi.GfxFence, output: *r4os.abi.GfxRenderColorList) callconv(.c) i32 {
    std.debug.assert(fence.point == 0x300000019 and output.version == 1 and output.size == 1568);
    output.* = .{ .count = 1 };
    output.program.words[63] = 0x87654321;
    return 1;
}
fn colorFacadeProbe() !void {
    try modeColorFacadeProbe();
    try refreshFacadeProbe();
    try powerFacadeProbe();
    try brightnessFacadeProbe();
    const a = r4os.abi;
    const t = std.testing;
    var tables = makeTables(true);
    var imports: [3]a.R4XStartImport = undefined;
    var raw: r4os.platform2.abi.R4XStartContext2 = undefined;
    var app = try makeApp(&tables, &imports, &raw);
    const queues = app.drawing().?.queues();
    tables[2].gfx_queue_submit_render_color_list = @intFromPtr(&colorSubmitProbe);
    var list: a.GfxRenderColorList = .{ .count = 1 };
    list.program.words[63] = 0x12345678;
    const queue: a.GfxQueueHandle = .{ .timeline = 0x200000017 };
    const request: a.GfxSubmission = .{ .operation = a.gfx_queue_operation_render_color_list };
    var result: a.GfxFenceStatus = .{ .deadline_ns = 79 };
    tables[2].size = 760;
    try t.expectEqual(a.err_no_fn, queues.submitRenderColorList(&queue, &request, &list, &result));
    try t.expect(result.deadline_ns == 79 and result.fence.point == 0);
    tables[2].size = 768;
    try t.expectEqual(@as(i32, 1), queues.submitRenderColorList(&queue, &request, &list, &result));
    var driver: r4os.driver_queue.Context = .{ .table = .{ .read_render_color_list = @intFromPtr(&colorReadProbe) } };
    for (120..128) |size| {
        driver.table.size = @intCast(size);
        try t.expect(!driver.supportsRenderColorList());
        try t.expectEqual(a.err_no_fn, driver.readRenderColorList(&result.fence, &list));
        try t.expectEqual(@as(u32, 0x12345678), list.program.words[63]);
    }
    driver.table.size = 128;
    try t.expect(driver.supportsRenderColorList());
    try t.expectEqual(@as(i32, 1), driver.readRenderColorList(&result.fence, &list));
    try t.expectEqual(@as(u32, 0x87654321), list.program.words[63]);
}
fn modeColorTestProbe(request: *const r4os.abi.GfxModeColorRequest, output: *r4os.abi.GfxAtomicResult) callconv(.c) i32 {
    std.debug.assert(request.size == 1344 and request.image.id == 23 and request.image.generation == 0x200000017 and request.signal.metadata.max_cll == 1000);
    output.commit_sequence = 0x300000019;
    return 1;
}
fn modeColorSubmitProbe(request: *const r4os.abi.GfxModeColorRequest, timeout: u32, output: *r4os.abi.GfxModeStatus) callconv(.c) i32 {
    std.debug.assert(request.image.id == 23 and request.image.generation == 0x200000017 and timeout == 15000);
    output.ticket = 0x300000019;
    return 1;
}
fn modeColorReadProbe(ticket: u64, sequence: u64, output: *r4os.abi.GfxDriverModeColor) callconv(.c) i32 {
    std.debug.assert(ticket == 0x300000019 and sequence == 2);
    output.* = .{ .ticket = ticket, .sequence = sequence, .signal = .{ .metadata = .{ .max_cll = 1000 } } };
    return 1;
}
fn modeColorFacadeProbe() !void {
    const a = r4os.abi;
    const t = std.testing;
    var tables = makeTables(true);
    var imports: [3]a.R4XStartImport = undefined;
    var raw: r4os.platform2.abi.R4XStartContext2 = undefined;
    var app = try makeApp(&tables, &imports, &raw);
    const outputs = app.drawing().?.outputs();
    tables[2].gfx_atomic_test_color = @intFromPtr(&modeColorTestProbe);
    tables[2].gfx_atomic_submit_color = @intFromPtr(&modeColorSubmitProbe);
    const request: a.GfxModeColorRequest = .{ .image = .{ .id = 23, .generation = 0x200000017 }, .signal = .{ .metadata = .{ .max_cll = 1000 } } };
    var tested: a.GfxAtomicResult = .{ .commit_sequence = 79 };
    var submitted: a.GfxModeStatus = .{ .ticket = 79 };
    tables[2].size = 768;
    try t.expectEqual(a.err_no_fn, outputs.testColor(&request, &tested));
    try t.expectEqual(a.err_no_fn, outputs.submitColor(&request, 15000, &submitted));
    try t.expect(tested.commit_sequence == 79 and submitted.ticket == 79);
    tables[2].size = 776;
    try t.expectEqual(@as(i32, 1), outputs.testColor(&request, &tested));
    try t.expectEqual(a.err_no_fn, outputs.submitColor(&request, 15000, &submitted));
    tables[2].size = 784;
    try t.expectEqual(@as(i32, 1), outputs.submitColor(&request, 15000, &submitted));
    var driver: r4os.driver_outputs.Context = .{ .table = .{ .mode_enable = 1, .mode_take = 1, .mode_complete = 1, .mode_read_color = @intFromPtr(&modeColorReadProbe) } };
    var color: a.GfxDriverModeColor = .{ .ticket = 79 };
    for (120..128) |size| {
        driver.table.size = @intCast(size);
        try t.expectEqual(a.err_no_fn, driver.readModeColor(submitted.ticket, 2, &color));
        try t.expectEqual(@as(u64, 79), color.ticket);
    }
    driver.table.size = 128;
    try t.expectEqual(@as(i32, 1), driver.readModeColor(submitted.ticket, 2, &color));
    try t.expect(tested.commit_sequence == color.ticket and color.sequence == 2 and color.signal.metadata.max_cll == 1000);
}
fn refreshReadProbe(target: *const r4os.abi.GfxOutputTarget, output: *r4os.abi.GfxOutputRefresh) callconv(.c) i32 {
    std.debug.assert(output.version == 1 and output.size == 272);
    output.* = .{ .target = target.*, .status = .{ .sequence = 0x200000079 } };
    return if (target.head_id == 7) r4os.abi.gfx_output_error_stale else 1;
}
fn refreshIntentProbe(input: *const r4os.abi.GfxRefreshRequest, output: *r4os.abi.GfxRefreshRequest) callconv(.c) i32 {
    std.debug.assert(output.version == 1 and output.size == 88);
    output.* = input.*;
    output.sequence = 0x300000079;
    return if (input.target.head_id == 7) r4os.abi.gfx_output_error_stale else 1;
}
fn refreshDriverReadProbe(target: *const r4os.abi.GfxOutputTarget, output: *r4os.abi.GfxRefreshRequest) callconv(.c) i32 {
    return refreshIntentProbe(&.{ .target = target.* }, output);
}
fn refreshPublishProbe(input: *const r4os.abi.GfxOutputRefresh) callconv(.c) i32 {
    return if (input.status.sequence == 0x200000079) 1 else -3;
}
fn refreshFacadeProbe() !void {
    const a = r4os.abi;
    const t = std.testing;
    var tables = makeTables(true);
    var imports: [3]a.R4XStartImport = undefined;
    var raw: r4os.platform2.abi.R4XStartContext2 = undefined;
    var app = try makeApp(&tables, &imports, &raw);
    const outputs = app.drawing().?.outputs();
    tables[2].gfx_output_refresh = @intFromPtr(&refreshReadProbe);
    tables[2].gfx_refresh_request = @intFromPtr(&refreshIntentProbe);
    var request: a.GfxRefreshRequest = .{ .target = .{ .display_generation = 0x400000079 } };
    var read: a.GfxOutputRefresh = .{ .status = .{ .sequence = 79 } };
    var intent: a.GfxRefreshRequest = .{ .sequence = 79 };
    tables[2].size = 791;
    try t.expectEqual(a.err_no_fn, outputs.refresh(&request.target, &read));
    try t.expect(read.status.sequence == 79);
    tables[2].size = 792;
    try t.expectEqual(@as(i32, 1), outputs.refresh(&request.target, &read));
    try t.expect(read.target.display_generation == request.target.display_generation);
    try t.expectEqual(a.err_no_fn, outputs.requestRefresh(&request, &intent));
    try t.expect(intent.sequence == 79);
    tables[2].size = 800;
    try t.expectEqual(@as(i32, 1), outputs.requestRefresh(&request, &intent));
    var driver: r4os.driver_outputs.Context = .{ .table = .{ .refresh_publish = @intFromPtr(&refreshPublishProbe), .refresh_read = @intFromPtr(&refreshDriverReadProbe) } };
    for (128..144) |bytes| {
        driver.table.size = @intCast(bytes);
        try t.expect(!driver.supportsRefresh());
        try t.expectEqual(a.err_no_fn, driver.readRefresh(&request.target, &intent));
    }
    driver.table.size = 144;
    try t.expectEqual(@as(i32, 1), driver.publishRefresh(&read));
    try t.expectEqual(@as(i32, 1), driver.readRefresh(&request.target, &intent));
    const old_read = read;
    const old_intent = intent;
    request.target.head_id = 7;
    try t.expectEqual(a.gfx_output_error_stale, outputs.refresh(&request.target, &read));
    try t.expectEqual(a.gfx_output_error_stale, outputs.requestRefresh(&request, &intent));
    try t.expectEqual(a.gfx_output_error_stale, driver.readRefresh(&request.target, &intent));
    try t.expect(std.meta.eql(read, old_read) and std.meta.eql(intent, old_intent));
}
fn powerReadProbe(identity: *const r4os.abi.GfxOutputId, output: *r4os.abi.GfxOutputPower) callconv(.c) i32 {
    std.debug.assert(output.version == 1 and output.size == 96);
    output.* = .{ .identity = identity.*, .sequence = 0x200000079 };
    return if (identity.connector_id == 7) r4os.abi.gfx_output_error_stale else 1;
}
fn powerIntentProbe(input: *const r4os.abi.GfxPowerRequest, output: *r4os.abi.GfxPowerRequest) callconv(.c) i32 {
    std.debug.assert(output.version == 1 and output.size == 64);
    output.* = input.*;
    output.sequence = 0x300000079;
    return if (input.identity.connector_id == 7) r4os.abi.gfx_output_error_stale else 1;
}
fn powerDriverReadProbe(identity: *const r4os.abi.GfxOutputId, output: *r4os.abi.GfxPowerRequest) callconv(.c) i32 {
    return powerIntentProbe(&.{ .identity = identity.* }, output);
}
fn powerPublishProbe(input: *const r4os.abi.GfxOutputPower) callconv(.c) i32 {
    return if (input.sequence == 0x200000079) 1 else -3;
}
fn powerFacadeProbe() !void {
    const a = r4os.abi;
    const t = std.testing;
    var tables = makeTables(true);
    var imports: [3]a.R4XStartImport = undefined;
    var raw: r4os.platform2.abi.R4XStartContext2 = undefined;
    var app = try makeApp(&tables, &imports, &raw);
    const outputs = app.drawing().?.outputs();
    tables[2].gfx_output_power = @intFromPtr(&powerReadProbe);
    tables[2].gfx_power_request = @intFromPtr(&powerIntentProbe);
    var request: a.GfxPowerRequest = .{ .identity = .{ .connection_generation = 0x400000079 } };
    var read: a.GfxOutputPower = .{ .sequence = 79 };
    var intent: a.GfxPowerRequest = .{ .sequence = 79 };
    for (816..824) |size| {
        tables[2].size = @intCast(size);
        try t.expectEqual(a.err_no_fn, outputs.power(&request.identity, &read));
        try t.expect(read.sequence == 79);
    }
    tables[2].size = 824;
    try t.expectEqual(@as(i32, 1), outputs.power(&request.identity, &read));
    try t.expect(read.identity.connection_generation == request.identity.connection_generation);
    for (824..832) |size| {
        tables[2].size = @intCast(size);
        try t.expectEqual(a.err_no_fn, outputs.requestPower(&request, &intent));
        try t.expect(intent.sequence == 79);
    }
    tables[2].size = 832;
    try t.expectEqual(@as(i32, 1), outputs.requestPower(&request, &intent));
    var driver: r4os.driver_outputs.Context = .{ .table = .{ .power_publish = @intFromPtr(&powerPublishProbe), .power_read = @intFromPtr(&powerDriverReadProbe) } };
    for (144..160) |size| {
        driver.table.size = @intCast(size);
        try t.expect(!driver.supportsPower());
        try t.expectEqual(a.err_no_fn, driver.readPower(&request.identity, &intent));
    }
    driver.table.size = 160;
    try t.expectEqual(@as(i32, 1), driver.publishPower(&read));
    try t.expectEqual(@as(i32, 1), driver.readPower(&request.identity, &intent));
    const old_read = read;
    const old_intent = intent;
    request.identity.connector_id = 7;
    try t.expectEqual(a.gfx_output_error_stale, outputs.power(&request.identity, &read));
    try t.expectEqual(a.gfx_output_error_stale, outputs.requestPower(&request, &intent));
    try t.expectEqual(a.gfx_output_error_stale, driver.readPower(&request.identity, &intent));
    try t.expect(std.meta.eql(read, old_read) and std.meta.eql(intent, old_intent));
}
fn brightnessReadProbe(identity: *const r4os.abi.GfxOutputId, output: *r4os.abi.GfxOutputBrightness) callconv(.c) i32 {
    std.debug.assert(output.version == 1 and output.size == 88);
    output.* = .{ .identity = identity.*, .sequence = 0x200000079 };
    return if (identity.connector_id == 7) r4os.abi.gfx_output_error_stale else 1;
}
fn brightnessIntentProbe(input: *const r4os.abi.GfxBrightnessRequest, output: *r4os.abi.GfxBrightnessRequest) callconv(.c) i32 {
    std.debug.assert(output.version == 1 and output.size == 48);
    output.* = input.*;
    output.sequence = 0x300000079;
    return if (input.identity.connector_id == 7) r4os.abi.gfx_output_error_stale else 1;
}
fn brightnessDriverReadProbe(identity: *const r4os.abi.GfxOutputId, output: *r4os.abi.GfxBrightnessRequest) callconv(.c) i32 {
    return brightnessIntentProbe(&.{ .identity = identity.* }, output);
}
fn brightnessPublishProbe(input: *const r4os.abi.GfxOutputBrightness) callconv(.c) i32 {
    return if (input.sequence == 0x200000079) 1 else -3;
}
fn brightnessFacadeProbe() !void {
    const a = r4os.abi;
    const t = std.testing;
    var tables = makeTables(true);
    var imports: [3]a.R4XStartImport = undefined;
    var raw: r4os.platform2.abi.R4XStartContext2 = undefined;
    var app = try makeApp(&tables, &imports, &raw);
    const outputs = app.drawing().?.outputs();
    tables[2].gfx_output_brightness = @intFromPtr(&brightnessReadProbe);
    tables[2].gfx_brightness_request = @intFromPtr(&brightnessIntentProbe);
    var request: a.GfxBrightnessRequest = .{ .identity = .{ .connection_generation = 0x400000079 } };
    var read: a.GfxOutputBrightness = .{ .sequence = 79 };
    var intent: a.GfxBrightnessRequest = .{ .sequence = 79 };
    for (896..904) |size| {
        tables[2].size = @intCast(size);
        try t.expectEqual(a.err_no_fn, outputs.brightness(&request.identity, &read));
        try t.expect(read.sequence == 79);
    }
    tables[2].size = 904;
    try t.expectEqual(@as(i32, 1), outputs.brightness(&request.identity, &read));
    try t.expect(read.identity.connection_generation == request.identity.connection_generation);
    for (904..912) |size| {
        tables[2].size = @intCast(size);
        try t.expectEqual(a.err_no_fn, outputs.requestBrightness(&request, &intent));
        try t.expect(intent.sequence == 79);
    }
    tables[2].size = 912;
    try t.expectEqual(@as(i32, 1), outputs.requestBrightness(&request, &intent));
    var driver: r4os.driver_outputs.Context = .{ .table = .{ .brightness_publish = @intFromPtr(&brightnessPublishProbe), .brightness_read = @intFromPtr(&brightnessDriverReadProbe) } };
    for (160..176) |size| {
        driver.table.size = @intCast(size);
        try t.expect(!driver.supportsBrightness());
        try t.expectEqual(a.err_no_fn, driver.readBrightness(&request.identity, &intent));
    }
    driver.table.size = 176;
    try t.expectEqual(@as(i32, 1), driver.publishBrightness(&read));
    try t.expectEqual(@as(i32, 1), driver.readBrightness(&request.identity, &intent));
    const old_read = read;
    const old_intent = intent;
    request.identity.connector_id = 7;
    try t.expectEqual(a.gfx_output_error_stale, outputs.brightness(&request.identity, &read));
    try t.expectEqual(a.gfx_output_error_stale, outputs.requestBrightness(&request, &intent));
    try t.expectEqual(a.gfx_output_error_stale, driver.readBrightness(&request.identity, &intent));
    try t.expect(std.meta.eql(read, old_read) and std.meta.eql(intent, old_intent));
}
fn gfxProfileProbe(input: *const r4os.abi.GfxBackendRegistration, profile: *const r4os.abi.GfxBackendProfile, out: *r4os.abi.GfxBackendBinding) callconv(.c) i32 {
    std.debug.assert(input.operations == 13 and input.memory_generation == 0x500000018);
    std.debug.assert(input.adapter_id == 17 and profile.interface_id_hi == 0x300000017 and profile.data_bytes == 64 and profile.data[63] == 91);
    std.debug.assert(out.version == 1 and out.size == 32);
    out.* = .{ .adapter_id = 17, .device_generation = 0x100000017, .reset_generation = 0x200000017 };
    return 1;
}
fn propertiesReadProbe(binding: *const r4os.abi.GfxBackendBinding, out: *r4os.abi.GfxBackendProperties) callconv(.c) i32 {
    std.debug.assert(binding.device_generation == 0x100000017 and out.version == 1 and out.size == 288);
    out.data[255] = 0x35;
    return if (binding.adapter_id == 17) 1 else -3;
}
fn propertiesPublishProbe(binding: *const r4os.abi.GfxBackendBinding, input: *const r4os.abi.GfxBackendProperties) callconv(.c) i32 {
    std.debug.assert(binding.device_generation == 0x100000017 and input.data[255] == 0x35);
    return 1;
}
fn gfxBackendInfoProbe(index: u32, out: *r4os.abi.GfxBackendInfo) callconv(.c) i32 {
    std.debug.assert(index == 16 and out.version == 1 and out.size == @sizeOf(r4os.abi.GfxBackendInfo));
    out.* = .{ .binding = .{ .adapter_id = 17, .device_generation = 0x100000017, .reset_generation = 0x200000017 }, .operations = 13, .memory_generation = 0x500000018, .profile = .{ .interface_id_hi = 0x300000017, .revision = 1, .data_bytes = 64, .data = @splat(91) } };
    return 1;
}
fn ownedReserveProbe(_: *const r4os.abi.GfxBufferDescriptor, cookie: u64, out: *r4os.abi.GfxOwnedBufferReservation) callconv(.c) i32 {
    std.debug.assert(cookie == 0x100000003 and out.size == 88);
    out.cookie = cookie;
    out.driver_generation = 0x200000005;
    return 1;
}
fn ownedCommitProbe(in: *const r4os.abi.GfxOwnedBufferReservation, out: *r4os.abi.GfxBufferReference) callconv(.c) i32 {
    std.debug.assert(in.cookie == 0x100000003 and in.driver_generation == 0x200000005 and out.size == 48);
    return 1;
}
fn ownedAbortProbe(in: *const r4os.abi.GfxOwnedBufferReservation, quiesced: u32) callconv(.c) i32 {
    std.debug.assert(in.cookie == 0x100000003 and quiesced == 0);
    return -4;
}
fn ownedTakeProbe(adapter: u32, generation: u64, out: *r4os.abi.GfxOwnedBufferRelease) callconv(.c) i32 {
    std.debug.assert(adapter == 17 and generation == 0x300000007 and out.size == 80);
    out.cookie = 0x100000003;
    out.attempt = 0x400000009;
    return 1;
}
fn ownedFinishProbe(in: *const r4os.abi.GfxOwnedBufferRelease, quiesced: u32) callconv(.c) i32 {
    std.debug.assert(in.cookie == 0x100000003 and in.attempt == 0x400000009 and quiesced == 1);
    return 1;
}
fn memoryPrefixProbe(out: *r4os.abi.GfxDriverMemoryApi) callconv(.c) i32 {
    const value: r4os.abi.GfxDriverMemoryApi = .{ .size = 112, .buffer_map = @intFromPtr(&gfxMapProbe) };
    @memcpy(@as([*]u8, @ptrCast(out))[0..112], std.mem.asBytes(&value)[0..112]);
    return 1;
}
fn ownedFacadeProbe() !void {
    try reservedSpanFacadeProbe();
    try deviceLostFacadeProbe();
    const a = r4os.abi;
    var native = r4os.driver_memory.Context{ .table = .{ .buffer_reserve = @intFromPtr(&ownedReserveProbe), .buffer_commit = @intFromPtr(&ownedCommitProbe), .buffer_abort = @intFromPtr(&ownedAbortProbe), .buffer_take_release = @intFromPtr(&ownedTakeProbe), .buffer_finish_release = @intFromPtr(&ownedFinishProbe) } };
    var reservation: a.GfxOwnedBufferReservation = .{};
    var reference: a.GfxBufferReference = .{};
    var release: a.GfxOwnedBufferRelease = .{};
    for (112..120) |size| {
        native.table.size = @intCast(size);
        try std.testing.expectEqual(a.err_no_fn, native.bufferReserve(&.{}, 0x100000003, &reservation));
    }
    try std.testing.expect(reservation.cookie == 0);
    native.table.size = 120;
    try std.testing.expectEqual(@as(i32, 1), native.bufferReserve(&.{}, 0x100000003, &reservation));
    for (120..128) |size| {
        native.table.size = @intCast(size);
        try std.testing.expectEqual(a.err_no_fn, native.bufferCommit(&reservation, &reference));
    }
    native.table.size = 128;
    try std.testing.expectEqual(@as(i32, 1), native.bufferCommit(&reservation, &reference));
    for (128..136) |size| {
        native.table.size = @intCast(size);
        try std.testing.expectEqual(a.err_no_fn, native.bufferAbort(&reservation, 0));
    }
    native.table.size = 136;
    try std.testing.expectEqual(@as(i32, -4), native.bufferAbort(&reservation, 0));
    for (136..144) |size| {
        native.table.size = @intCast(size);
        try std.testing.expectEqual(a.err_no_fn, native.bufferTakeRelease(17, 0x300000007, &release));
    }
    native.table.size = 144;
    try std.testing.expectEqual(@as(i32, 1), native.bufferTakeRelease(17, 0x300000007, &release));
    for (144..152) |size| {
        native.table.size = @intCast(size);
        try std.testing.expectEqual(a.err_no_fn, native.bufferFinishRelease(&release, 1));
    }
    native.table.size = 152;
    try std.testing.expectEqual(@as(i32, 1), native.bufferFinishRelease(&release, 1));
    var api: r4os.platform2.abi.DriverApi2 = undefined;
    api.magic = r4os.platform2.abi.driver_magic;
    api.reserved = 0;
    api.version = 1;
    api.size = @sizeOf(r4os.platform2.abi.DriverApi2);
    api.gfx_memory_query = &memoryPrefixProbe;
    const ctx = r4os.r4dev.DriverContext.init(&api);
    const old = ctx.memory().?;
    try std.testing.expect(old.table.size == 112 and old.table.buffer_reserve == 0);
    try std.testing.expectEqual(a.err_no_fn, old.bufferReserve(&.{}, 0, &reservation));
}
fn deviceLostProbe(adapter: u32, generation: u64, quiesced: u32) callconv(.c) i32 {
    std.debug.assert(adapter == 17 and generation == 0x300000007 and quiesced <= 1);
    return if (quiesced == 1) 1 else r4os.abi.gfx_buffer_error_busy;
}
fn deviceLostFacadeProbe() !void {
    const a = r4os.abi;
    var memory: r4os.driver_memory.Context = .{ .table = .{ .device_lost = @intFromPtr(&deviceLostProbe) } };
    for (200..208) |bytes| {
        memory.table.size = @intCast(bytes);
        try std.testing.expectEqual(a.err_no_fn, memory.deviceLost(17, 0x300000007, true));
    }
    memory.table.size = 208;
    try std.testing.expectEqual(a.gfx_buffer_error_busy, memory.deviceLost(17, 0x300000007, false));
    try std.testing.expectEqual(@as(i32, 1), memory.deviceLost(17, 0x300000007, true));
    memory.table.device_lost = 0;
    try std.testing.expectEqual(a.err_no_fn, memory.deviceLost(17, 0x300000007, true));
}
fn nativeCompleteProbe(provider: *const r4os.abi.GfxBufferHandle, request: *const r4os.abi.GfxBufferHandle, result: i32, reference: *const r4os.abi.GfxBufferHandle) callconv(.c) i32 {
    std.debug.assert(provider.generation == 0x100000019 and request.generation == 0x200000019 and result == -6 and reference.id == 0);
    return 1;
}
fn gfxOperationsProbe(binding: *const r4os.abi.GfxBackendBinding, operations: u64) callconv(.c) i32 {
    std.debug.assert(binding.device_generation == 0x100000019 and operations == 29);
    return 1;
}
fn nativeTakeProbe(_: *const r4os.abi.GfxBufferHandle, output: *r4os.abi.GfxNativeJob) callconv(.c) i32 {
    std.debug.assert(output.version == 1 and output.size == 88);
    output.request.generation = 99;
    return -4;
}
fn nativeFacadeProbe() !void {
    const a = r4os.abi;
    var memory: r4os.driver_memory.Context = .{ .table = .{ .native_take = @intFromPtr(&nativeTakeProbe), .native_complete = @intFromPtr(&nativeCompleteProbe) } };
    const provider: a.GfxBufferHandle = .{ .id = 1, .generation = 0x100000019 };
    const request: a.GfxBufferHandle = .{ .id = 2, .generation = 0x200000019 };
    for (176..184) |bytes| {
        memory.table.size = @intCast(bytes);
        try std.testing.expectEqual(a.err_no_fn, memory.nativeComplete(&provider, &request, -6, &.{}));
    }
    memory.table.size = 184;
    try std.testing.expectEqual(@as(i32, 1), memory.nativeComplete(&provider, &request, -6, &.{}));
    var output: a.GfxNativeJob = .{ .request = .{ .generation = 77 } };
    const unchanged = output;
    try std.testing.expectEqual(@as(i32, -4), memory.nativeTake(&provider, &output));
    try std.testing.expectEqualDeep(unchanged, output);
    memory.table.size = 152;
    try std.testing.expectEqual(a.err_no_fn, memory.nativeTake(&provider, &output));
    try std.testing.expectEqualDeep(unchanged, output);
}
fn virtualStartProbe(input: *const r4os.abi.GfxVirtualRequest, output: *r4os.abi.GfxVirtualStatus) callconv(.c) i32 {
    std.debug.assert(input.memory_generation == 0x100000035 and input.byte_offset == 0x200000035 and output.size == 80);
    output.address = 0x300000035;
    return -4;
}
fn virtualWaitProbe(handle: *const r4os.abi.GfxBufferHandle, until: u32, timeout: u64, output: *r4os.abi.GfxVirtualStatus) callconv(.c) i32 {
    std.debug.assert(handle.generation == 0x400000035 and until == 1 and timeout == 0x500000035 and output.version == 1 and output.size == 80);
    output.address = 0x600000035;
    return 1;
}
fn virtualCloseProbe(handle: *const r4os.abi.GfxBufferHandle, mode: u32) callconv(.c) i32 {
    std.debug.assert(handle.generation == 0x400000035 and mode == 1);
    return 1;
}
fn virtualTakeProbe(provider: *const r4os.abi.GfxBufferHandle, output: *r4os.abi.GfxVirtualJob) callconv(.c) i32 {
    std.debug.assert(provider.generation == 0x400000035 and output.version == 1 and output.size == 248);
    output.token.opaque2 = 0x700000035;
    return -4;
}
fn virtualCompleteProbe(provider: *const r4os.abi.GfxBufferHandle, input: *const r4os.abi.GfxVirtualCompletion) callconv(.c) i32 {
    std.debug.assert(provider.generation == 0x400000035 and input.token.opaque2 == 0x800000035 and input.operation == 1);
    return 1;
}
fn virtualFacadeProbe() !void {
    const a = r4os.abi;
    const t = std.testing;
    var tables = makeTables(true);
    tables[2].gfx_virtual_start = @intFromPtr(&virtualStartProbe);
    tables[2].gfx_virtual_wait = @intFromPtr(&virtualWaitProbe);
    tables[2].gfx_virtual_close = @intFromPtr(&virtualCloseProbe);
    var imports: [3]a.R4XStartImport = undefined;
    var raw: r4os.platform2.abi.R4XStartContext2 = undefined;
    var app = try makeApp(&tables, &imports, &raw);
    const draw = app.drawing().?;
    const handle: a.GfxBufferHandle = .{ .generation = 0x400000035 };
    const input: a.GfxVirtualRequest = .{ .memory_generation = 0x100000035, .byte_offset = 0x200000035 };
    var status: a.GfxVirtualStatus = .{ .address = 77 };
    const unchanged = status;
    for (832..840) |size| {
        tables[2].size = @intCast(size);
        try t.expectEqual(a.err_no_fn, draw.gfxVirtualStart(&input, &status));
        try t.expectEqualDeep(unchanged, status);
    }
    tables[2].size = 840;
    try t.expectEqual(@as(i32, -4), draw.gfxVirtualStart(&input, &status));
    try t.expectEqualDeep(unchanged, status);
    for (856..864) |size| {
        tables[2].size = @intCast(size);
        try t.expectEqual(a.err_no_fn, draw.gfxVirtualWait(&handle, 1, 0x500000035, &status));
    }
    tables[2].size = 864;
    try t.expectEqual(@as(i32, 1), draw.gfxVirtualWait(&handle, 1, 0x500000035, &status));
    try t.expect(status.address == 0x600000035);
    try t.expectEqual(@as(i32, 1), draw.gfxVirtualClose(&handle, 1));
    var driver: r4os.driver_memory.Context = .{ .table = .{ .virtual_take = @intFromPtr(&virtualTakeProbe), .virtual_complete = @intFromPtr(&virtualCompleteProbe) } };
    const completion: a.GfxVirtualCompletion = .{ .operation = 1, .token = .{ .opaque2 = 0x800000035 } };
    for (232..240) |size| {
        driver.table.size = @intCast(size);
        try t.expectEqual(a.err_no_fn, driver.virtualComplete(&handle, &completion));
    }
    driver.table.size = 240;
    try t.expectEqual(@as(i32, 1), driver.virtualComplete(&handle, &completion));
    var job: a.GfxVirtualJob = .{ .token = .{ .opaque2 = 79 } };
    const old = job;
    try t.expectEqual(@as(i32, -4), driver.virtualTake(&handle, &job));
    try t.expectEqualDeep(old, job);
}
var stats_probe_bytes: u32 = @sizeOf(r4os.abi.GfxBufferStats);
fn statsProbe(output: *r4os.abi.GfxBufferStats) callconv(.c) i32 {
    std.debug.assert(output.version == 1 and output.size == 136);
    const value: r4os.abi.GfxBufferStats = .{ .size = stats_probe_bytes, .committed_bytes = 0x100000003, .system_bytes = 17, .device_bytes = 19 };
    @memcpy(std.mem.asBytes(output)[0..stats_probe_bytes], std.mem.asBytes(&value)[0..stats_probe_bytes]);
    return 1;
}
var budget_probe_rc: i32 = 1;
fn budgetProbe(input: *const r4os.abi.GfxDeviceBudgetRequest, output: *r4os.abi.GfxDeviceBudgetState) callconv(.c) i32 {
    std.debug.assert(input.adapter_id == 3 and input.memory_generation == 0x200000007 and output.version == 1 and output.size == 64);
    output.* = .{ .adapter_id = input.adapter_id, .memory_generation = input.memory_generation, .limit_bytes = 0x400000000, .charged_bytes = 0x100000003 };
    return budget_probe_rc;
}
fn budgetFacadeProbe() !void {
    try telemetryFacadeProbe();
    const a = r4os.abi;
    const t = std.testing;
    var tables = makeTables(true);
    tables[2].gfx_memory_budget = @intFromPtr(&budgetProbe);
    var imports: [3]a.R4XStartImport = undefined;
    var raw: r4os.platform2.abi.R4XStartContext2 = undefined;
    var app = try makeApp(&tables, &imports, &raw);
    const draw = app.drawing().?;
    var driver: r4os.driver_memory.Context = .{ .table = .{ .memory_budget = @intFromPtr(&budgetProbe) } };
    const input: a.GfxDeviceBudgetRequest = .{ .adapter_id = 3, .memory_generation = 0x200000007 };
    var output: a.GfxDeviceBudgetState = .{ .charged_bytes = 79 };
    const unchanged = output;
    for (184..192) |bytes| {
        driver.table.size = @intCast(bytes);
        try t.expectEqual(a.err_no_fn, driver.memoryBudget(&input, &output));
        try t.expectEqualDeep(unchanged, output);
    }
    for (800..808) |bytes| {
        tables[2].size = @intCast(bytes);
        try t.expectEqual(a.err_no_fn, draw.gfxMemoryBudget(&input, &output));
        try t.expectEqualDeep(unchanged, output);
    }
    driver.table.size = 192;
    tables[2].size = 808;
    budget_probe_rc = a.gfx_buffer_error_stale;
    try t.expectEqual(budget_probe_rc, driver.memoryBudget(&input, &output));
    try t.expectEqualDeep(unchanged, output);
    try t.expectEqual(budget_probe_rc, draw.gfxMemoryBudget(&input, &output));
    try t.expectEqualDeep(unchanged, output);
    budget_probe_rc = 1;
    try t.expectEqual(@as(i32, 1), driver.memoryBudget(&input, &output));
    try t.expect(output.charged_bytes == 0x100000003 and output.limit_bytes == 0x400000000);
    output = unchanged;
    try t.expectEqual(@as(i32, 1), draw.gfxMemoryBudget(&input, &output));
    try t.expect(output.charged_bytes == 0x100000003 and output.memory_generation == 0x200000007);
}
fn telemetryProbe(input: *const r4os.abi.GfxTelemetryRequest, output: *r4os.abi.GfxTelemetryState) callconv(.c) i32 {
    output.* = .{ .adapter_id = input.adapter_id, .memory_generation = input.memory_generation };
    output.metrics[5] = .{ .status = r4os.abi.gfx_telemetry_fresh, .source_stamp = 9, .values = .{ -12500, 0, 0, 0 } };
    return budget_probe_rc;
}
fn telemetryDriverProbe(input: *const r4os.abi.GfxTelemetryState, output: *r4os.abi.GfxTelemetryDemand) callconv(.c) i32 {
    output.* = .{ .adapter_id = input.adapter_id, .memory_generation = input.memory_generation, .metric_mask = 0x201, .until_ns = 0x200000001 };
    return budget_probe_rc;
}
fn telemetryFacadeProbe() !void {
    const a = r4os.abi;
    const t = std.testing;
    var tables = makeTables(true);
    tables[2].gfx_telemetry = @intFromPtr(&telemetryProbe);
    var imports: [3]a.R4XStartImport = undefined;
    var raw: r4os.platform2.abi.R4XStartContext2 = undefined;
    var app = try makeApp(&tables, &imports, &raw);
    const draw = app.drawing().?;
    var driver: r4os.driver_memory.Context = .{ .table = .{ .telemetry_exchange = @intFromPtr(&telemetryDriverProbe) } };
    const request: a.GfxTelemetryRequest = .{ .adapter_id = 3, .memory_generation = 0x200000007, .metric_mask = 0x201 };
    var state: a.GfxTelemetryState = .{ .adapter_id = 79 };
    const unchanged = state;
    var demand: a.GfxTelemetryDemand = .{ .until_ns = 79 };
    const original_demand = demand;
    for (808..816) |bytes| {
        tables[2].size = @intCast(bytes);
        try t.expectEqual(a.err_no_fn, draw.gfxTelemetry(&request, &state));
        try t.expectEqualDeep(unchanged, state);
    }
    for (192..200) |bytes| {
        driver.table.size = @intCast(bytes);
        try t.expectEqual(a.err_no_fn, driver.telemetryExchange(&state, &demand));
        try t.expectEqualDeep(original_demand, demand);
    }
    tables[2].size = 816;
    driver.table.size = 200;
    budget_probe_rc = a.gfx_buffer_error_stale;
    try t.expectEqual(budget_probe_rc, draw.gfxTelemetry(&request, &state));
    try t.expectEqualDeep(unchanged, state);
    try t.expectEqual(budget_probe_rc, driver.telemetryExchange(&state, &demand));
    try t.expectEqualDeep(original_demand, demand);
    budget_probe_rc = 1;
    try t.expectEqual(@as(i32, 1), draw.gfxTelemetry(&request, &state));
    try t.expect(state.adapter_id == 3 and state.metrics[5].values[0] == -12500 and state.metrics[6].status == a.gfx_telemetry_unavailable);
    try t.expectEqual(@as(i32, 1), driver.telemetryExchange(&state, &demand));
    try t.expect(demand.until_ns == 0x200000001 and demand.metric_mask == 0x201 and demand.memory_generation == request.memory_generation);
    var line: [128]u8 = undefined;
    try t.expectEqualStrings("GPU temp: -12.5 C", r4os.gfx_telemetry.formatLine(&line, &state, 5));
    state.source = a.gfx_telemetry_source_smu10;
    state.metrics[0] = .{ .status = a.gfx_telemetry_fresh, .flags = a.gfx_telemetry_partial_values |
        a.gfx_telemetry_current_clocks | a.gfx_telemetry_fabric_clock | (3 << 8), .values = .{ 800000000, 1200000000, 0, 0 } };
    try t.expectEqualStrings("GPU clock: 800.0 MHz", r4os.gfx_telemetry.formatLine(&line, &state, 1));
    try t.expectEqualStrings("Fabric clock: 1200.0 MHz", r4os.gfx_telemetry.formatLine(&line, &state, 2));
    try t.expectEqualStrings("Video clock: unknown (unavailable)", r4os.gfx_telemetry.formatLine(&line, &state, 3));
    try t.expectEqualStrings("APU temp: -12.5 C", r4os.gfx_telemetry.formatLine(&line, &state, 5));
    state.metrics[2] = .{ .status = a.gfx_telemetry_fresh, .flags = a.gfx_telemetry_partial_values | (1 << 8), .values = .{ 37, 0, 0, 0 } };
    try t.expectEqualStrings("Memory busy: unknown (unavailable)", r4os.gfx_telemetry.formatLine(&line, &state, 13));
}
test "graphics buffer optional tails preserve 64-bit offsets in Zig and R4D calls" {
    try budgetFacadeProbe();
    try gridFacadeProbe();
    try ownedFacadeProbe();
    try nativeFacadeProbe();
    try virtualFacadeProbe();
    var tables = makeTables(true);
    tables[2].abi_version = (r4os.platform2.abi.R4XStartR4Draw2{}).abi_version;
    tables[2].gfx_buffer_map = @intFromPtr(&gfxMapProbe);
    tables[2].size = @offsetOf(r4os.platform2.abi.R4XStartR4Draw2, "gfx_buffer_map");
    var imports: [3]r4os.abi.R4XStartImport = undefined;
    var context: r4os.platform2.abi.R4XStartContext2 = undefined;
    var app = try makeApp(&tables, &imports, &context);
    const draw = app.drawing().?;
    const buffers = draw.buffers();
    tables[2].gfx_buffer_stats = @intFromPtr(&statsProbe);
    var stats: r4os.abi.GfxBufferStats = .{ .device_bytes = 79 };
    tables[2].size = @offsetOf(r4os.platform2.abi.R4XStartR4Draw2, "gfx_buffer_stats") + 8;
    const stats_driver = r4os.driver_memory.Context{ .table = .{ .buffer_stats = @intFromPtr(&statsProbe) } };
    const before_stats = stats;
    for ([_]u32{ 56, 135 }) |bytes| {
        stats_probe_bytes = bytes;
        try std.testing.expectEqual(r4os.abi.gfx_buffer_error_invalid, buffers.stats(&stats));
        try std.testing.expectEqualDeep(before_stats, stats);
        try std.testing.expectEqual(r4os.abi.gfx_buffer_error_invalid, stats_driver.bufferStats(&stats));
        try std.testing.expectEqualDeep(before_stats, stats);
    }
    stats_probe_bytes = @sizeOf(r4os.abi.GfxBufferStats);
    try std.testing.expectEqual(@as(i32, 1), buffers.stats(&stats));
    try std.testing.expect(stats.size == 136 and stats.committed_bytes == 0x100000003 and stats.system_bytes == 17 and stats.device_bytes == 19);
    try std.testing.expectEqual(@as(i32, 1), stats_driver.bufferStats(&stats));
    try std.testing.expect(stats.size == 136 and stats.system_bytes == 17 and stats.device_bytes == 19);
    tables[2].size = @offsetOf(r4os.platform2.abi.R4XStartR4Draw2, "gfx_buffer_map");
    const ref: r4os.abi.GfxBufferHandle = .{ .id = 7, .generation = 99 };
    var output: r4os.abi.GfxBufferMap = .{ .byte_length = 37 };
    try std.testing.expectEqual(r4os.abi.err_no_fn, buffers.map(&ref, 1, 0x100000003, 0x200000000, &output));
    try std.testing.expectEqual(@as(u64, 37), output.byte_length);
    tables[2].size = @sizeOf(r4os.platform2.abi.R4XStartR4Draw2);
    try std.testing.expectEqual(@as(i32, 1), buffers.map(&ref, 1, 0x100000003, 0x200000000, &output));
    tables[2].gfx_buffer_map_persistent = @intFromPtr(&gfxMapProbe);
    const saved_output = output;
    for (864..872) |size| {
        tables[2].size = @intCast(size);
        try std.testing.expectEqual(r4os.abi.err_no_fn, buffers.mapPersistent(&ref, 1, 0x100000003, 0x200000000, &output));
        try std.testing.expectEqualDeep(saved_output, output);
    }
    tables[2].size = @sizeOf(r4os.platform2.abi.R4XStartR4Draw2);
    try std.testing.expectEqual(@as(i32, 1), buffers.mapPersistent(&ref, 1, 0x100000003, 0x200000000, &output));
    var old_driver: r4os.platform2.abi.DriverApi2 = undefined;
    old_driver.magic = r4os.platform2.abi.driver_magic;
    old_driver.reserved = 0;
    old_driver.version = 1;
    old_driver.size = @offsetOf(r4os.platform2.abi.DriverApi2, "gfx_memory_query");
    const old_context = r4os.r4dev.DriverContext.init(&old_driver);
    try std.testing.expect(!old_context.apiCompatible());
    try std.testing.expect(old_context.memory() == null);
    try std.testing.expect(old_context.graphicsQueue() == null);
    const memory = @import("r4os").driver_memory.Context{ .table = .{ .buffer_map = @intFromPtr(&gfxMapProbe) } };
    try std.testing.expectEqual(@as(i32, 1), memory.bufferMap(&ref, 1, 0x100000003, 0x200000000, &output));
    const queues = draw.queues();
    const fence: r4os.abi.GfxFence = .{ .slot = 7, .timeline = 23, .point = 0x100000007, .reset_generation = 0x200000001 };
    var result: r4os.abi.GfxFenceStatus = .{ .deadline_ns = 123 };
    tables[2].gfx_fence_wait = @intFromPtr(&gfxWaitProbe);
    tables[2].size = @offsetOf(r4os.platform2.abi.R4XStartR4Draw2, "gfx_fence_wait");
    try std.testing.expectEqual(r4os.abi.err_no_fn, queues.wait(&fence, 0x300000003, 1, &result));
    try std.testing.expectEqual(@as(u64, 123), result.deadline_ns);
    tables[2].size += 8;
    try std.testing.expectEqual(@as(i32, 1), queues.wait(&fence, 0x300000003, 1, &result));
    var native = r4os.driver_queue.Context{ .table = .{ .complete = @intFromPtr(&gfxCompleteProbe) } };
    native.table.update_operations = @intFromPtr(&gfxOperationsProbe);
    for (72..80) |size| {
        native.table.size = @intCast(size);
        try std.testing.expectEqual(r4os.abi.err_no_fn, native.updateOperations(&.{ .device_generation = 0x100000019 }, 29));
    }
    native.table.size = 80;
    try std.testing.expectEqual(@as(i32, 1), native.updateOperations(&.{ .device_generation = 0x100000019 }, 29));
    try std.testing.expectEqual(@as(i32, -4), native.complete(&fence, 6, 0));
    native.table.size = @offsetOf(r4os.abi.GfxDriverQueueApi, "complete");
    try std.testing.expectEqual(r4os.abi.err_no_fn, native.complete(&fence, 6, 0));
    var retained: r4os.abi.GfxBufferReference = .{ .flags = 79 };
    native.table.retain_resource = @intFromPtr(&gfxRetainProbe);
    for (56..64) |size| {
        native.table.size = @intCast(size);
        try std.testing.expectEqual(r4os.abi.err_no_fn, native.retainResource(&fence, 1, &retained));
        try std.testing.expectEqual(@as(u32, 79), retained.flags);
    }
    native.table.size = 64;
    try std.testing.expectEqual(@as(i32, 1), native.retainResource(&fence, 1, &retained));
    try std.testing.expectEqual(@as(u64, 0x400000009), retained.reference.generation);
    try std.testing.expectEqual(r4os.abi.gfx_buffer_reference_mapping_only, retained.flags);
    var info: r4os.abi.GfxBackendInfo = .{};
    tables[2].gfx_queue_backend_info = @intFromPtr(&gfxBackendInfoProbe);
    tables[2].size = 640;
    try std.testing.expectEqual(r4os.abi.err_no_fn, queues.backendInfo(16, &info));
    try std.testing.expect(info.binding.adapter_id == 0);
    tables[2].size = 648;
    try std.testing.expectEqual(@as(i32, 1), queues.backendInfo(16, &info));
    try std.testing.expect(info.operations == 13 and info.memory_generation == 0x500000018);
    var binding: r4os.abi.GfxBackendBinding = .{};
    native.table.register_profile = @intFromPtr(&gfxProfileProbe);
    for (64..72) |size| {
        native.table.size = @intCast(size);
        try std.testing.expectEqual(r4os.abi.err_no_fn, native.registerProfile(&.{ .adapter_id = 17 }, &info.profile, &binding));
        try std.testing.expect(binding.device_generation == 0);
    }
    native.table.size = 72;
    try std.testing.expectEqual(@as(i32, 1), native.registerProfile(&.{ .adapter_id = 17, .operations = info.operations, .memory_generation = info.memory_generation }, &info.profile, &binding));
    try std.testing.expectEqualDeep(info.binding, binding);
    tables[2].gfx_queue_submit_native = @intFromPtr(&nativeSubmitProbe);
    const raw_queue: r4os.abi.GfxQueueHandle = .{ .timeline = 0x100000003 };
    const raw_submission: r4os.abi.GfxSubmission = .{ .operation = r4os.abi.gfx_queue_operation_native };
    var raw_input: r4os.abi.GfxNativeSubmission = .{ .commands = 0x200000009, .revision = 1 };
    var raw_output: r4os.abi.GfxFenceStatus = .{ .version = 0, .size = 0 };
    const saved_raw = raw_output;
    for (880..888) |size| {
        tables[2].size = @intCast(size);
        try std.testing.expectEqual(r4os.abi.err_no_fn, queues.submitNative(&raw_queue, &raw_submission, &raw_input, &raw_output));
        try std.testing.expectEqualDeep(saved_raw, raw_output);
    }
    tables[2].size = 888;
    raw_input.revision = 2;
    try std.testing.expectEqual(@as(i32, -3), queues.submitNative(&raw_queue, &raw_submission, &raw_input, &raw_output));
    try std.testing.expectEqualDeep(saved_raw, raw_output);
    raw_input.revision = 1;
    try std.testing.expectEqual(@as(i32, 1), queues.submitNative(&raw_queue, &raw_submission, &raw_input, &raw_output));
    try std.testing.expectEqual(@as(u64, 0x300000007), raw_output.fence.point);
    native.table.read_native_info = @intFromPtr(&nativeInfoProbe);
    var raw_fence: r4os.abi.GfxFence = .{ .slot = 7 };
    var raw_info: r4os.abi.GfxNativeJobInfo = .{ .version = 0, .size = 0 };
    const saved_info = raw_info;
    for (136..144) |size| {
        native.table.size = @intCast(size);
        try std.testing.expectEqual(r4os.abi.err_no_fn, native.nativeInfo(&raw_fence, &raw_info));
        try std.testing.expectEqualDeep(saved_info, raw_info);
    }
    native.table.size = 144;
    raw_fence.slot = 8;
    try std.testing.expectEqual(@as(i32, -3), native.nativeInfo(&raw_fence, &raw_info));
    try std.testing.expectEqualDeep(saved_info, raw_info);
    raw_fence.slot = 7;
    try std.testing.expectEqual(@as(i32, 1), native.nativeInfo(&raw_fence, &raw_info));
    try std.testing.expectEqual(@as(u32, 2051), raw_info.command_bytes);
    tables[2].gfx_queue_backend_properties = @intFromPtr(&propertiesReadProbe);
    var properties: r4os.abi.GfxBackendProperties = .{ .data = @splat(0xa5) };
    for (872..880) |size| {
        tables[2].size = @intCast(size);
        try std.testing.expectEqual(r4os.abi.err_no_fn, queues.backendProperties(&binding, &properties));
        try std.testing.expect(properties.data[255] == 0xa5);
    }
    tables[2].size = 880;
    try std.testing.expectEqual(@as(i32, 1), queues.backendProperties(&binding, &properties));
    try std.testing.expect(properties.data[255] == 0x35);
    binding.adapter_id = 18;
    properties.data[255] = 0xa5;
    try std.testing.expectEqual(@as(i32, -3), queues.backendProperties(&binding, &properties));
    try std.testing.expect(properties.data[255] == 0xa5);
    binding.adapter_id = 17;
    properties.data[255] = 0x35;
    native.table.publish_properties = @intFromPtr(&propertiesPublishProbe);
    for (128..136) |size| {
        native.table.size = @intCast(size);
        try std.testing.expectEqual(r4os.abi.err_no_fn, native.publishProperties(&binding, &properties));
    }
    native.table.size = 136;
    try std.testing.expectEqual(@as(i32, 1), native.publishProperties(&binding, &properties));
    native.table.queue_owner_info = @intFromPtr(&queueOwnerProbe);
    var queue_owner: r4os.abi.GfxQueueOwnerInfo = .{ .version = 0, .size = 0 };
    const saved_owner = queue_owner;
    for (160..168) |size| {
        native.table.size = @intCast(size);
        try std.testing.expectEqual(r4os.abi.err_no_fn, native.queueOwnerInfo(&binding, 0x200000009, &queue_owner));
        try std.testing.expectEqualDeep(saved_owner, queue_owner);
    }
    native.table.size = 168;
    binding.adapter_id = 18;
    try std.testing.expectEqual(@as(i32, 0), native.queueOwnerInfo(&binding, 0x200000009, &queue_owner));
    try std.testing.expectEqualDeep(saved_owner, queue_owner);
    binding.adapter_id = 19;
    try std.testing.expectEqual(@as(i32, -3), native.queueOwnerInfo(&binding, 0x200000009, &queue_owner));
    try std.testing.expectEqualDeep(saved_owner, queue_owner);
    binding.adapter_id = 17;
    try std.testing.expectEqual(@as(i32, 1), native.queueOwnerInfo(&binding, 0x200000009, &queue_owner));
    try std.testing.expectEqual(@as(u64, 0x300000005), queue_owner.producer_generation);
    try std.testing.expectEqual(@as(u32, 1), queue_owner.closing);
    old_driver.version = 1;
    old_driver.size = @sizeOf(r4os.platform2.abi.DriverApi2);
    old_driver.gfx_queue_query = &gfxQueuePrefixProbe;
    const prefix = old_context.graphicsQueue().?;
    try std.testing.expectEqual(@as(i32, -4), prefix.complete(&fence, 6, 0));
    try std.testing.expectEqual(r4os.abi.err_no_fn, prefix.retainResource(&fence, 1, &retained));
    try std.testing.expectEqual(@as(usize, 544), @offsetOf(r4os.platform2.abi.DriverApi2, "gfx_memory_query"));
    try std.testing.expectEqual(@as(usize, 552), @offsetOf(r4os.platform2.abi.DriverApi2, "gfx_queue_query"));
    try std.testing.expectEqual(@as(usize, 560), @offsetOf(r4os.platform2.abi.DriverApi2, "gfx_output_query"));
    try std.testing.expectEqual(@as(usize, 568), @offsetOf(r4os.platform2.abi.DriverApi2, "gfx_display_query"));
    try std.testing.expectEqual(@as(usize, 576), @offsetOf(r4os.platform2.abi.DriverApi2, "resource_query"));
    // v29's resource query is still the end of that historical 600-byte
    // prefix; newer optional DriverApi services may follow it.
    try std.testing.expectEqual(@as(usize, 584), @offsetOf(r4os.platform2.abi.DriverApi2, "resource_query") + @sizeOf(usize));
}

fn outputTestProbe(state: *const r4os.abi.GfxAtomicState, out: *r4os.abi.GfxAtomicResult) callconv(.c) i32 {
    std.debug.assert(state.topology_revision == 0x100000007 and state.assignments[7].output.connection_generation == 0x200000009);
    std.debug.assert(out.version == 1 and out.size == @sizeOf(r4os.abi.GfxAtomicResult));
    out.topology_revision = state.topology_revision;
    return 1;
}
fn modeEnableProbe(input: *const r4os.abi.GfxBackendBinding) callconv(.c) i32 {
    std.debug.assert(input.device_generation == 0x100000079);
    return 1;
}
fn modeTakeProbe(input: *const r4os.abi.GfxBackendBinding, output: *r4os.abi.GfxDriverModeJob) callconv(.c) i32 {
    std.debug.assert(input.device_generation == 0x100000079);
    output.* = .{ .ticket = 0x200000079, .sequence = 3, .operation = 1, .backend = input.* };
    return 1;
}
fn modeCompleteProbe(input: *const r4os.abi.GfxDriverModeCompletion) callconv(.c) i32 {
    std.debug.assert(input.ticket == 0x200000079 and input.sequence == 3 and input.quiesced == 1);
    return -3;
}
fn modeSubmitProbe(input: *const r4os.abi.GfxAtomicState, milliseconds: u32, output: *r4os.abi.GfxModeStatus) callconv(.c) i32 {
    std.debug.assert(input.topology_revision == 0x100000007 and milliseconds == 15000 and output.size == 88);
    output.* = .{ .ticket = 0x200000079, .phase = 1, .retained = 3 };
    return 1;
}
fn modeStatusProbe(ticket: u64, output: *r4os.abi.GfxModeStatus) callconv(.c) i32 {
    std.debug.assert(ticket == 0x200000079 and output.size == 88);
    output.phase = 3;
    return 1;
}
fn modeResolveProbe(ticket: u64, action: u32, output: *r4os.abi.GfxModeStatus) callconv(.c) i32 {
    std.debug.assert(ticket == 0x200000079 and action == 2 and output.size == 88);
    output.phase = 5;
    return 1;
}
fn outputPublishProbe(publication: *const r4os.abi.GfxOutputPublication, out: *r4os.abi.GfxOutputId) callconv(.c) i32 {
    std.debug.assert(publication.info.edid_bytes == 128 and publication.edid[127] == 0x79);
    out.* = .{ .adapter_id = 3, .connector_id = 17, .device_generation = 0x30000000b, .connection_generation = 0x40000000d };
    return 1;
}
fn outputPauseProbe(output: *const r4os.abi.GfxOutputId, paused: u32) callconv(.c) i32 {
    std.debug.assert(output.connection_generation == 0x40000000d and paused <= 1);
    return if (paused == 1) 1 else r4os.abi.gfx_output_error_busy;
}
var color_probe_prefix: u32 = @sizeOf(r4os.abi.GfxOutputColorState);
var color_probe_status: i32 = r4os.abi.gfx_output_ok;
fn outputColorProbe(identity: *const r4os.abi.GfxOutputId, output: *r4os.abi.GfxOutputColorState) callconv(.c) i32 {
    std.debug.assert(output.version == 1 and output.size == @sizeOf(r4os.abi.GfxOutputColorState));
    const value: r4os.abi.GfxOutputColorState = .{ .size = color_probe_prefix, .identity = identity.*, .revision = 0x600000007, .flags = r4os.abi.gfx_output_color_known, .formats = 1, .max_frl_rate = 6 };
    @memcpy(std.mem.asBytes(output)[0..color_probe_prefix], std.mem.asBytes(&value)[0..color_probe_prefix]);
    return color_probe_status;
}
fn outputColorPublishProbe(input: *const r4os.abi.GfxOutputColorState) callconv(.c) i32 {
    std.debug.assert(input.identity.connection_generation == 0x40000000d and input.formats == 1);
    return r4os.abi.gfx_output_error_stale;
}
fn modeRestoreProbe(input: *const r4os.abi.GfxAtomicState, out: *r4os.abi.GfxModeStatus) callconv(.c) i32 {
    std.debug.assert(input.topology_revision == 0 and input.count == 1);
    out.ticket = 0x200000079;
    return 1;
}
fn audioRoutePublishProbe(input: *const r4os.abi.GfxAudioRoute) callconv(.c) i32 {
    std.debug.assert(input.source.generation == 0x100000079 and input.revision == 0x200000015 and input.eld[95] == 0x79);
    return r4os.abi.gfx_output_error_stale;
}
fn audioRouteQueryProbe(location: u32, device: u32, index: u32, output: *r4os.abi.GfxAudioRoute) callconv(.c) i32 {
    std.debug.assert(location == 0x01000901 and device == 0x228e10de and output.size == 176);
    if (index != 0) return 0;
    output.source.generation = 0x100000079;
    output.revision = 0x200000015;
    output.eld[95] = 0x79;
    return 1;
}
fn receiverRegisterProbe(adapter: u32, out: *r4os.abi.GfxReceiverSource) callconv(.c) i32 {
    std.debug.assert(adapter == 17);
    out.* = .{ .adapter_id = adapter, .generation = 0x100000079 };
    return 1;
}
fn receiverReplaceProbe(input: *const r4os.abi.GfxReceiverUpdate) callconv(.c) i32 {
    std.debug.assert(input.source.generation == 0x100000079 and input.sequence == 0x200000001 and input.count == 0 and input.receivers == 0);
    return -4;
}
fn receiverCloseProbe(input: *const r4os.abi.GfxReceiverSource) callconv(.c) i32 {
    std.debug.assert(input.generation == 0x100000079);
    return 1;
}
fn displayTransitionProbe(generation: u64, operation: u32, output: *r4os.abi.GfxNativeState) callconv(.c) i32 {
    std.debug.assert(generation == 0x100000007 and operation == 2);
    output.generation = generation + 1;
    output.outcome = 3;
    output.retained = 1;
    return 1;
}
fn displayScheduleProbe(binding: *const r4os.abi.GfxBackendBinding) callconv(.c) i32 {
    std.debug.assert(binding.reset_generation == 0x30000000b);
    return -4;
}
fn displayDeviceResetProbe(binding: *const r4os.abi.GfxBackendBinding, generation: u64, quiesced: u32, output: *r4os.abi.GfxNativeState) callconv(.c) i32 {
    std.debug.assert(binding.reset_generation == 0x30000000b and generation == 0x100000007 and quiesced <= 1);
    std.debug.assert(output.version == 1 and output.size == @sizeOf(r4os.abi.GfxNativeState));
    if (quiesced == 1) return r4os.abi.gfx_output_error_busy;
    output.* = .{ .generation = generation + 1, .outcome = r4os.abi.gfx_output_outcome_lost, .retained = 1 };
    return r4os.abi.gfx_output_ok;
}
fn displayPrepareResetProbe(input: *const r4os.abi.GfxNativeRegistration, held_generation: u64, reset_generation: u64, output: *r4os.abi.GfxNativeState) callconv(.c) i32 {
    std.debug.assert(input.backend.reset_generation == 0x30000000b and held_generation == 0x200000079 and reset_generation == 0x100000008);
    std.debug.assert(output.version == 1 and output.size == @sizeOf(r4os.abi.GfxNativeState));
    output.* = .{ .generation = reset_generation + 1, .outcome = r4os.abi.gfx_output_outcome_validated, .retained = 1 };
    return r4os.abi.gfx_output_ok;
}
fn presentationReadProbe(head: u32, output: *r4os.abi.DisplayPresentationStats) callconv(.c) i32 {
    std.debug.assert(head == 3 and output.version == 1 and output.size == 208);
    output.visible_sequence = 0x100000079;
    output.source_point = 0x200000079;
    return r4os.abi.gfx_output_ok;
}
fn presentationPublishProbe(input: *const r4os.abi.DisplayPresentationStats) callconv(.c) i32 {
    std.debug.assert(input.version == 1 and input.size == 208 and input.visible_sequence == 0x100000079 and input.source_point == 0x200000079);
    return r4os.abi.gfx_output_error_stale;
}
fn cursorInfoProbe(out: *r4os.abi.DisplayCursorInfo) callconv(.c) i32 {
    std.debug.assert(out.version == 1 and out.size == 80);
    out.display_generation = 0x100000079;
    return 1;
}
fn cursorStatusProbe(out: *r4os.abi.DisplayCursorStatus) callconv(.c) i32 {
    std.debug.assert(out.version == 1 and out.size == 72);
    out.completed = 0x200000079;
    return 1;
}
fn cursorSubmitProbe(input: *const r4os.abi.DisplayCursorRequest, out: *r4os.abi.DisplayCursorStatus) callconv(.c) i32 {
    std.debug.assert(input.display_generation == 0x100000079 and input.image_sequence == 0x300000079 and input.x == -17);
    return cursorStatusProbe(out);
}
fn cursorConfigureProbe(input: *const r4os.abi.DisplayCursorInfo) callconv(.c) i32 {
    std.debug.assert(input.display_generation == 0x100000079);
    return 1;
}
fn cursorTakeProbe(input: *const r4os.abi.GfxBackendBinding, out: *r4os.abi.GfxDriverCursorJob) callconv(.c) i32 {
    std.debug.assert(input.reset_generation == 0x400000079 and out.version == 1 and out.size == 160);
    out.sequence = 0x200000079;
    out.barrier_point = 0x500000079;
    return 1;
}
fn cursorCompleteProbe(input: *const r4os.abi.GfxDriverCursorCompletion) callconv(.c) i32 {
    std.debug.assert(input.sequence == 0x200000079 and input.display_generation == 0x100000079);
    return -4;
}
fn cursorFacadeProbe() !void {
    const a = r4os.abi;
    const t = std.testing;
    var tables = makeTables(true);
    var imports: [3]a.R4XStartImport = undefined;
    var context: r4os.platform2.abi.R4XStartContext2 = undefined;
    var app = try makeApp(&tables, &imports, &context);
    const draw = app.drawing().?;
    tables[2].display_cursor_info = @intFromPtr(&cursorInfoProbe);
    tables[2].display_cursor_submit = @intFromPtr(&cursorSubmitProbe);
    tables[2].display_cursor_status = @intFromPtr(&cursorStatusProbe);
    var info: a.DisplayCursorInfo = .{};
    var status: a.DisplayCursorStatus = .{ .completed = 79 };
    const request: a.DisplayCursorRequest = .{ .display_generation = 0x100000079, .image_sequence = 0x300000079, .x = -17 };
    for (616..640) |size| {
        tables[2].size = @intCast(size);
        try t.expect(!draw.supportsDisplayCursor());
        try t.expectEqual(a.err_no_fn, draw.displayCursorInfo(&info));
        try t.expectEqual(a.err_no_fn, draw.displayCursorSubmit(&request, &status));
        try t.expectEqual(a.err_no_fn, draw.displayCursorStatus(&status));
        try t.expect(status.completed == 79 and info.display_generation == 0);
    }
    tables[2].size = 640;
    try t.expectEqual(a.gfx_output_ok, draw.displayCursorInfo(&info));
    try t.expectEqual(a.gfx_output_ok, draw.displayCursorSubmit(&request, &status));
    try t.expectEqual(a.gfx_output_ok, draw.displayCursorStatus(&status));
    var driver: r4os.driver_display.Context = .{ .table = .{ .cursor_configure = @intFromPtr(&cursorConfigureProbe), .cursor_take = @intFromPtr(&cursorTakeProbe), .cursor_complete = @intFromPtr(&cursorCompleteProbe) } };
    var job: a.GfxDriverCursorJob = .{};
    const binding: a.GfxBackendBinding = .{ .reset_generation = 0x400000079 };
    const receipt: a.GfxDriverCursorCompletion = .{ .sequence = 0x200000079, .display_generation = 0x100000079 };
    for (72..96) |size| {
        driver.table.size = @intCast(size);
        try t.expect(!driver.supportsCursor());
        try t.expectEqual(a.err_no_fn, driver.cursorConfigure(&info));
        try t.expectEqual(a.err_no_fn, driver.cursorTake(&binding, &job));
        try t.expectEqual(a.err_no_fn, driver.cursorComplete(&receipt));
        try t.expect(job.sequence == 0);
    }
    driver.table.size = 96;
    try t.expectEqual(a.gfx_output_ok, driver.cursorConfigure(&info));
    try t.expectEqual(a.gfx_output_ok, driver.cursorTake(&binding, &job));
    try t.expect(job.sequence == 0x200000079 and job.barrier_point == 0x500000079);
    try t.expectEqual(a.gfx_output_error_busy, driver.cursorComplete(&receipt));
}
test "old display and driver prefixes hide output tails while C/Zig preserve receiver generations" {
    try cursorFacadeProbe();
    const a = r4os.abi;
    var tables = makeTables(true);
    tables[2].abi_version = 11;
    tables[2].size = 536;
    tables[2].gfx_atomic_test = @intFromPtr(&outputTestProbe);
    var imports: [3]a.R4XStartImport = undefined;
    var context: r4os.platform2.abi.R4XStartContext2 = undefined;
    var app = try makeApp(&tables, &imports, &context);
    const outputs = app.drawing().?.outputs();
    const draw = app.drawing().?;
    var statistics: a.DisplayPresentationStats = .{ .visible_sequence = 79 };
    tables[2].display_presentation_stats = @intFromPtr(&presentationReadProbe);
    for (608..616) |bytes| {
        tables[2].size = @intCast(bytes);
        try std.testing.expect(!draw.supportsDisplayPresentationStats());
        try std.testing.expectEqual(a.err_no_fn, draw.displayPresentationStats(3, &statistics));
        try std.testing.expectEqual(@as(u64, 79), statistics.visible_sequence);
    }
    tables[2].size = 616;
    try std.testing.expect(draw.supportsDisplayPresentationStats());
    try std.testing.expectEqual(a.gfx_output_ok, draw.displayPresentationStats(3, &statistics));
    var statistics_driver: r4os.driver_display.Context = .{ .table = .{ .presentation_stats = @intFromPtr(&presentationPublishProbe) } };
    for (64..72) |bytes| {
        statistics_driver.table.size = @intCast(bytes);
        try std.testing.expect(!statistics_driver.supportsPresentationStats());
        try std.testing.expectEqual(a.err_no_fn, statistics_driver.presentationStats(&statistics));
    }
    statistics_driver.table.size = 72;
    try std.testing.expectEqual(a.gfx_output_error_stale, statistics_driver.presentationStats(&statistics));
    tables[2].size = 536;
    var state = a.GfxAtomicState{ .topology_revision = 0x100000007 };
    state.assignments[7].output.connection_generation = 0x200000009;
    var result = a.GfxAtomicResult{ .commit_sequence = 77 };
    const before = result;
    try std.testing.expectEqual(a.err_no_fn, outputs.testState(&state, &result));
    try std.testing.expectEqualDeep(before, result);
    tables[2].size = @sizeOf(r4os.platform2.abi.R4XStartR4Draw2);
    try std.testing.expectEqual(@as(i32, 1), outputs.testState(&state, &result));
    try std.testing.expectEqual(state.topology_revision, result.topology_revision);
    tables[2].gfx_atomic_submit = @intFromPtr(&modeSubmitProbe);
    tables[2].gfx_atomic_status = @intFromPtr(&modeStatusProbe);
    tables[2].gfx_atomic_resolve = @intFromPtr(&modeResolveProbe);
    var mode_status: a.GfxModeStatus = .{};
    tables[2].size = 584;
    try std.testing.expectEqual(a.err_no_fn, outputs.submit(&state, 15000, &mode_status));
    try std.testing.expectEqual(@as(u64, 0), mode_status.ticket);
    tables[2].size = @sizeOf(r4os.platform2.abi.R4XStartR4Draw2);
    try std.testing.expectEqual(a.gfx_output_ok, outputs.submit(&state, 15000, &mode_status));
    try std.testing.expectEqual(a.gfx_output_ok, outputs.status(mode_status.ticket, &mode_status));
    try std.testing.expectEqual(a.gfx_output_ok, outputs.resolve(mode_status.ticket, 2, &mode_status));
    try std.testing.expect(mode_status.ticket == 0x200000079 and mode_status.phase == 5 and mode_status.retained == 3);
    var mode_driver: r4os.driver_outputs.Context = .{ .table = .{ .mode_enable = @intFromPtr(&modeEnableProbe), .mode_take = @intFromPtr(&modeTakeProbe), .mode_complete = @intFromPtr(&modeCompleteProbe) } };
    const mode_binding: a.GfxBackendBinding = .{ .device_generation = 0x100000079 };
    var mode_job: a.GfxDriverModeJob = .{};
    for ([_]u32{ 24, 48, 56, 64, 71 }) |bytes| {
        mode_driver.table.size = bytes;
        try std.testing.expect(!mode_driver.supportsModes());
        try std.testing.expectEqual(a.err_no_fn, mode_driver.takeMode(&mode_binding, &mode_job));
    }
    mode_driver.table.size = 72;
    try std.testing.expectEqual(a.gfx_output_ok, mode_driver.enableModes(&mode_binding));
    try std.testing.expectEqual(a.gfx_output_ok, mode_driver.takeMode(&mode_binding, &mode_job));
    try std.testing.expectEqual(a.gfx_output_error_stale, mode_driver.completeMode(&.{ .ticket = mode_job.ticket, .sequence = mode_job.sequence, .quiesced = 1 }));
    var old_driver: r4os.platform2.abi.DriverApi2 = undefined;
    old_driver.magic = r4os.platform2.abi.driver_magic;
    old_driver.reserved = 0;
    old_driver.version = 1;
    old_driver.size = 576;
    try std.testing.expect(r4os.r4dev.DriverContext.init(&old_driver).graphicsOutputs() == null);
    var native = r4os.driver_outputs.Context{ .table = .{ .publish = @intFromPtr(&outputPublishProbe) } };
    var hotplug = r4os.driver_outputs.Context{ .table = .{ .output_pause = @intFromPtr(&outputPauseProbe), .mode_restore = @intFromPtr(&modeRestoreProbe), .mode_status = @intFromPtr(&modeStatusProbe) } };
    const port: a.GfxOutputId = .{ .connection_generation = 0x40000000d };
    var color_state: a.GfxOutputColorState = .{ .formats = 7 };
    const color_before = color_state;
    tables[2].gfx_output_color = @intFromPtr(&outputColorProbe);
    tables[2].size = 752;
    try std.testing.expectEqual(a.err_no_fn, outputs.color(&port, &color_state));
    try std.testing.expectEqualDeep(color_before, color_state);
    tables[2].size = @sizeOf(r4os.platform2.abi.R4XStartR4Draw2);
    try std.testing.expectEqual(a.gfx_output_ok, outputs.color(&port, &color_state));
    try std.testing.expect(color_state.revision == 0x600000007 and std.meta.eql(color_state.identity, port) and color_state.formats == 1);
    try std.testing.expect(color_state.max_frl_rate == 6);
    const full_color = color_state;
    color_probe_prefix = 128;
    try std.testing.expectEqual(a.gfx_output_error_invalid, outputs.color(&port, &color_state));
    try std.testing.expectEqualDeep(full_color, color_state);
    color_probe_prefix = @sizeOf(a.GfxOutputColorState);
    const current_color = color_state;
    color_probe_status = a.gfx_output_error_busy;
    try std.testing.expectEqual(a.gfx_output_error_busy, outputs.color(&port, &color_state));
    try std.testing.expectEqualDeep(current_color, color_state);
    color_probe_status = a.gfx_output_ok;
    var color_driver: r4os.driver_outputs.Context = .{ .table = .{ .color_publish = @intFromPtr(&outputColorPublishProbe) } };
    for ([_]u32{ 24, 112, 119 }) |bytes| {
        color_driver.table.size = bytes;
        try std.testing.expect(!color_driver.supportsColor());
        try std.testing.expectEqual(a.err_no_fn, color_driver.publishColor(&color_state));
    }
    color_driver.table.size = 120;
    try std.testing.expectEqual(a.gfx_output_error_stale, color_driver.publishColor(&color_state));
    var restored: a.GfxModeStatus = .{};
    for (24..112) |bytes| {
        hotplug.table.size = @intCast(bytes);
        try std.testing.expect(!hotplug.supportsHotplug());
        try std.testing.expectEqual(a.err_no_fn, hotplug.pauseOutput(&port, true));
        try std.testing.expectEqual(a.err_no_fn, hotplug.restoreMode(&.{ .count = 1 }, &restored));
        try std.testing.expectEqual(a.err_no_fn, hotplug.modeStatus(0x200000079, &restored));
        try std.testing.expect(restored.ticket == 0);
    }
    hotplug.table.size = 112;
    try std.testing.expectEqual(a.gfx_output_ok, hotplug.pauseOutput(&port, true));
    try std.testing.expectEqual(a.gfx_output_error_busy, hotplug.pauseOutput(&port, false));
    try std.testing.expectEqual(a.gfx_output_ok, hotplug.restoreMode(&.{ .count = 1 }, &restored));
    try std.testing.expectEqual(a.gfx_output_ok, hotplug.modeStatus(restored.ticket, &restored));
    hotplug.table.mode_status = 0;
    try std.testing.expect(!hotplug.supportsHotplug());
    var audio_routes: r4os.driver_outputs.Context = .{ .table = .{ .audio_publish = @intFromPtr(&audioRoutePublishProbe), .audio_query = @intFromPtr(&audioRouteQueryProbe) } };
    var audio_route: a.GfxAudioRoute = .{};
    for ([_]u32{ 24, 48, 72, 79, 80, 87 }) |prefix| {
        audio_routes.table.size = prefix;
        try std.testing.expect(!audio_routes.supportsAudio());
        try std.testing.expectEqual(a.err_no_fn, audio_routes.queryAudio(0x01000901, 0x228e10de, 0, &audio_route));
        try std.testing.expectEqual(a.err_no_fn, audio_routes.publishAudio(&audio_route));
        try std.testing.expectEqualDeep(a.GfxAudioRoute{}, audio_route);
    }
    audio_routes.table.size = 88;
    try std.testing.expectEqual(@as(i32, 1), audio_routes.queryAudio(0x01000901, 0x228e10de, 0, &audio_route));
    const audio_before = audio_route;
    try std.testing.expectEqual(@as(i32, 0), audio_routes.queryAudio(0x01000901, 0x228e10de, 1, &audio_route));
    try std.testing.expectEqualDeep(audio_before, audio_route);
    try std.testing.expectEqual(a.gfx_output_error_stale, audio_routes.publishAudio(&audio_route));
    var publication = a.GfxOutputPublication{};
    publication.info.edid_bytes = 128;
    publication.edid[127] = 0x79;
    var identity: a.GfxOutputId = .{};
    try std.testing.expectEqual(@as(i32, 1), native.publish(&publication, &identity));
    try std.testing.expectEqual(@as(u64, 0x40000000d), identity.connection_generation);
    native.table = .{ .register_source = @intFromPtr(&receiverRegisterProbe), .replace_receivers = @intFromPtr(&receiverReplaceProbe), .close_source = @intFromPtr(&receiverCloseProbe) };
    var source: a.GfxReceiverSource = .{};
    try std.testing.expect(native.supportsReceivers());
    try std.testing.expectEqual(@as(i32, 1), native.registerSource(17, &source));
    const update: a.GfxReceiverUpdate = .{ .source = source, .sequence = 0x200000001 };
    try std.testing.expectEqual(@as(i32, -4), native.replaceReceivers(&update));
    try std.testing.expectEqual(@as(i32, 1), native.closeSource(&source));
    for ([_]u32{ 24, 32, 40, 47 }) |prefix| {
        native.table.size = prefix;
        try std.testing.expect(!native.supportsReceivers());
        try std.testing.expectEqual(a.err_no_fn, native.registerSource(17, &source));
        try std.testing.expectEqual(a.err_no_fn, native.replaceReceivers(&update));
        try std.testing.expectEqual(a.err_no_fn, native.closeSource(&source));
        try std.testing.expectEqual(@as(u64, 0x100000079), source.generation);
    }
    native.table.size = @offsetOf(a.GfxDriverOutputApi, "publish");
    try std.testing.expectEqual(a.err_no_fn, native.publish(&publication, &identity));
    try std.testing.expectEqual(@as(u64, 0x40000000d), identity.connection_generation);
    old_driver.version = 1;
    old_driver.size = 584;
    try std.testing.expect(r4os.r4dev.DriverContext.init(&old_driver).graphicsDisplay() == null);
    var display = r4os.driver_display.Context{ .table = .{ .transition = @intFromPtr(&displayTransitionProbe), .schedule = @intFromPtr(&displayScheduleProbe) } };
    var outcome = a.GfxNativeState{};
    try std.testing.expectEqual(@as(i32, 1), display.transition(0x100000007, 2, &outcome));
    try std.testing.expect(outcome.generation == 0x100000008 and outcome.outcome == 3 and outcome.retained == 1);
    const binding = a.GfxBackendBinding{ .reset_generation = 0x30000000b };
    try std.testing.expectEqual(@as(i32, -4), display.schedule(&binding));
    display.table.size = @offsetOf(a.GfxDriverDisplayApi, "schedule");
    try std.testing.expectEqual(a.err_no_fn, display.schedule(&binding));
    display.table.size = @offsetOf(a.GfxDriverDisplayApi, "transition");
    try std.testing.expectEqual(a.err_no_fn, display.transition(0, 0, &outcome));
    try std.testing.expect(outcome.generation == 0x100000008 and outcome.retained == 1);
    display.table = .{ .device_reset = @intFromPtr(&displayDeviceResetProbe), .prepare_reset = @intFromPtr(&displayPrepareResetProbe) };
    const registration: a.GfxNativeRegistration = .{ .backend = binding };
    for (40..136) |prefix| {
        display.table.size = @intCast(prefix);
        try std.testing.expect(!display.supportsReset());
        try std.testing.expectEqual(a.err_no_fn, display.deviceReset(&binding, 0x100000007, false, &outcome));
        try std.testing.expectEqual(a.err_no_fn, display.prepareReset(&registration, 0x200000079, 0x100000008, &outcome));
        try std.testing.expect(outcome.generation == 0x100000008);
    }
    display.table.size = 136;
    try std.testing.expectEqual(a.gfx_output_ok, display.deviceReset(&binding, 0x100000007, false, &outcome));
    try std.testing.expectEqual(a.gfx_output_error_busy, display.deviceReset(&binding, 0x100000007, true, &outcome));
    try std.testing.expect(outcome.generation == 0x100000008 and outcome.retained == 1);
    try std.testing.expectEqual(a.gfx_output_ok, display.prepareReset(&registration, 0x200000079, 0x100000008, &outcome));
    try std.testing.expect(outcome.generation == 0x100000009 and outcome.retained == 1);
    display.table.device_reset = 0;
    try std.testing.expect(!display.supportsReset());
}

var now_ticks: u64 = 100;
var activity_waits: u32 = 0;
var desktop_activity_waits: u32 = 0;
var gui_wait_mode: u32 = 0;
var last_gui_subscriptions: u32 = 0;
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
var interop_codepoint: u32 = 0;

const raw_events = [_]r4os.abi.GuiEvent{
    .{ .kind = @intFromEnum(r4os.abi.GuiEventKind.resize), .window_id = 4, .tick = 10 },
    .{ .kind = @intFromEnum(r4os.abi.GuiEventKind.key_down), .window_id = 4, .key = 'A', .modifiers = 2, .tick = 11 },
    .{ .kind = @intFromEnum(r4os.abi.GuiEventKind.mouse_down), .window_id = 4, .x = 8, .y = 9, .buttons = 1, .tick = 12 },
    .{ .kind = @intFromEnum(r4os.abi.GuiEventKind.mouse_up), .window_id = 4, .x = 10, .y = 11, .tick = 13 },
    .{ .kind = @intFromEnum(r4os.abi.GuiEventKind.mouse_move), .window_id = 4, .x = 12, .y = 13, .tick = 14 },
    .{ .kind = @intFromEnum(r4os.abi.GuiEventKind.close), .window_id = 4, .tick = 15 },
    .{ .kind = @intFromEnum(r4os.abi.GuiEventKind.focus_gained), .window_id = 4, .tick = 0x100000010 },
    .{ .kind = @intFromEnum(r4os.abi.GuiEventKind.focus_lost), .window_id = 4, .tick = 0x100000011 },
    .{ .kind = @intFromEnum(r4os.abi.GuiEventKind.font_changed) },
    .{ .kind = @intFromEnum(r4os.abi.GuiEventKind.input_reset), .window_id = 4, .key = r4os.abi.gui_input_reset_reason_overflow, .tick = 0x100000014 },
    .{ .kind = 0xfeed, .window_id = 4, .x = -7, .y = 13, .key = 0x1f642, .buttons = 3, .modifiers = 9, .tick = 0x100000012 },
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

fn fakeMonotonicClock(out: *r4os.abi.MonotonicClockInfo) callconv(.c) i32 {
    out.* = .{
        .flags = r4os.abi.monotonic_clock_flag_valid,
        .source = 1,
        .generation = 1,
        .frequency_hz = r4os.abi.monotonic_clock_frequency_hz,
        .resolution_ns = 1,
        .instant_ns = now_ticks * 1_000_000,
        .event_requested_hz = 1000,
        .event_effective_hz = 1000,
    };
    return 1;
}

fn fakeShouldClose(context: *const r4os.platform2.abi.R4XStartContext2) callconv(.c) u32 {
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
    if (interop_codepoint != 0 and out.kind == @intFromEnum(r4os.abi.GuiEventKind.key_down)) out.key = interop_codepoint;
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
    desktop_activity_waits += 1;
    now_ticks +|= timeout_ticks;
    out_sequence.* = last_sequence;
    return 0;
}

fn fakeActivityNotify() callconv(.c) i32 {
    return 0;
}
fn fakeGuiActivityWait(last: u64, timeout: u64, subscriptions: u32, out: *u64) callconv(.c) i32 {
    std.debug.assert(subscriptions & ~r4os.abi.gui_activity_shared_all == 0);
    activity_waits += 1;
    last_gui_subscriptions = subscriptions;
    if (gui_wait_mode == 1) {
        // A real peer may commit clipboard state after poll but before wait.
        gui_wait_mode = 0;
        clipboard_revision +%= 1;
        out.* = last +% 1;
        return 1;
    }
    if (gui_wait_mode == 2 and timeout > 1) {
        now_ticks += 1;
        out.* = last +% 1;
        return 1;
    }
    if (gui_wait_mode == 3) return -2;
    now_ticks +|= timeout;
    out.* = last;
    return 0;
}
fn fakeGuiActivityNotify(categories: u32) callconv(.c) i32 {
    return if (categories != 0 and categories & ~r4os.abi.gui_activity_shared_all == 0) 0 else -1;
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

fn makeTables(draw_available: bool) struct { r4os.platform2.abi.R4XStartR4Sys2, r4os.platform2.abi.R4XStartR4Desk2, r4os.platform2.abi.R4XStartR4Draw2 } {
    var sys: r4os.platform2.abi.R4XStartR4Sys2 = .{};
    sys.write = @intFromPtr(&fakeWrite);
    sys.putc = @intFromPtr(&fakePutc);
    sys.ticks = @intFromPtr(&fakeTicks);
    sys.time_state = @intFromPtr(&fakeTimeState);
    sys.monotonic_clock = @intFromPtr(&fakeMonotonicClock);
    var desk: r4os.platform2.abi.R4XStartR4Desk2 = .{};
    desk.program_window_id = @intFromPtr(&fakeWindowId);
    desk.gui_window_info = @intFromPtr(&fakeWindowInfo);
    desk.gui_poll_event = @intFromPtr(&fakePollEvent);
    desk.gui_set_title = @intFromPtr(&fakeSetTitle);
    desk.gui_set_min_size = @intFromPtr(&fakeSetMinSize);
    desk.clipboard_revision = @intFromPtr(&fakeClipboardRevision);
    desk.desktop_activity_wait = @intFromPtr(&fakeActivityWait);
    desk.gui_activity_wait = @intFromPtr(&fakeGuiActivityWait);
    desk.gui_activity_notify = @intFromPtr(&fakeGuiActivityNotify);
    var draw: r4os.platform2.abi.R4XStartR4Draw2 = .{};
    draw.gui_clear = @intFromPtr(&fakeClear);
    draw.gui_rect = @intFromPtr(&fakeRect);
    draw.gui_draw_text = @intFromPtr(&fakeText);
    draw.gui_draw_text_ex = @intFromPtr(&fakeTextEx);
    draw.gui_blit = @intFromPtr(&fakeBlit);
    draw.gui_blend_alpha8 = @intFromPtr(&fakeAlpha8);
    if (draw_available) draw.gui_present = @intFromPtr(&fakePresent);
    return .{ sys, desk, draw };
}

fn enableFrameContract(draw: *r4os.platform2.abi.R4XStartR4Draw2) void {
    draw.gui_frame_begin = @intFromPtr(&fakeFrameBegin);
    draw.gui_frame_append = @intFromPtr(&fakeFrameAppend);
    draw.gui_frame_commit = @intFromPtr(&fakeFrameCommit);
    draw.gui_frame_cancel = @intFromPtr(&fakeFrameCancel);
    draw.gui_frame_info = @intFromPtr(&fakeFrameInfo);
    draw.gui_frame_read = @intFromPtr(&fakeFrameRead);
}

var replacement_count: u32 = 0;
var replacement_region: r4os.abi.DisplayDamageRect = .{};
fn fakeFrameReplace(regions: [*]const r4os.abi.DisplayDamageRect, count: u32) callconv(.c) i32 {
    if (count != 1) return r4os.abi.gui_frame_error_invalid;
    replacement_count += 1;
    replacement_region = regions[0];
    return 0;
}

test "transactional paint regional replacement retains full commands and promotes changed geometry" {
    resetFrameCapture();
    replacement_count = 0;
    frame_begin_count = 0;
    frame_commit_count = 0;
    frame_cancel_count = 0;
    var tables = makeTables(true);
    enableFrameContract(&tables[2]);
    tables[2].gui_frame_begin_replace = @intFromPtr(&fakeFrameReplace);
    var imports: [3]r4os.abi.R4XStartImport = undefined;
    var context: r4os.platform2.abi.R4XStartContext2 = undefined;
    var app = try makeApp(&tables, &imports, &context);
    var timers: [0]r4os.Timer = .{};
    var window = app.window(&timers) orelse return error.WindowMissing;
    const info = window.info().?;
    const regions = [_]r4os.abi.DisplayDamageRect{.{ .x = 10, .y = 20, .w = 30, .h = 40 }};
    var paint = switch (window.beginPaintReplace(info.client_w, info.client_h, &regions)) {
        .paint => |value| value,
        .failure => return error.ReplacementRefused,
    };
    try std.testing.expectEqual(@as(u32, 1), replacement_count);
    try std.testing.expectEqual(regions[0], replacement_region);
    try std.testing.expectEqual(@as(u32, 0), frame_begin_count);
    // Regional damage must not clip the independent replacement description.
    var commands: [4]r4os.abi.GuiFrameCommand = undefined;
    var resources: [4]u8 = undefined;
    var builder: r4os.app_gui.FrameCanvas = undefined;
    const canvas = paint.bufferedCanvas(&builder, &commands, &resources);
    try std.testing.expectEqual(@as(i32, 0), canvas.clear(0x112233));
    try std.testing.expectEqual(@as(i32, 0), canvas.rect(.{ .x = 100, .y = 100, .w = 20, .h = 10 }, 0xabcdef));
    try std.testing.expectEqual(@as(i32, 0), paint.present());
    try std.testing.expectEqual(@as(u32, 1), frame_commit_count);
    try std.testing.expectEqual(@as(usize, 2), captured_command_count);
    try std.testing.expectEqual(@as(i32, 100), captured_commands[1].x);
    var changed = switch (window.beginPaintReplace(info.client_w - 1, info.client_h, &regions)) {
        .paint => |value| value,
        .failure => return error.Paint,
    };
    changed.discard();
    try std.testing.expectEqual(@as(u32, 1), frame_begin_count);
    window.events.action_view_pending = true;
    var coordinated = switch (window.beginPaintReplace(info.client_w, info.client_h, &regions)) {
        .paint => |value| value,
        .failure => return error.Paint,
    };
    coordinated.discard();
    try std.testing.expectEqual(@as(u32, 2), frame_begin_count);
    try std.testing.expectEqual(@as(u32, 1), replacement_count);
    const bad = [_]r4os.abi.DisplayDamageRect{.{ .x = -1, .y = 0, .w = 1, .h = 1 }};
    switch (window.beginPaintReplace(info.client_w, info.client_h, &bad)) {
        .paint => return error.InvalidDamageAccepted,
        .failure => |code| try std.testing.expectEqual(r4os.abi.gui_frame_error_invalid, code),
    }
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

// Language interop reuses the original callbacks, capture and pixel oracle.
// These exports belong to the test object, never the SDK product runtime.
pub export fn sdk_gfx_oracle_tables(sys: *r4os.platform2.abi.R4XStartR4Sys2, desk: *r4os.platform2.abi.R4XStartR4Desk2, draw: *r4os.platform2.abi.R4XStartR4Draw2) callconv(.c) void {
    sdk_gui_oracle_tables(sys, desk, draw);
    draw.gfx_buffer_map = @intFromPtr(&gfxMapProbe);
    draw.gfx_buffer_map_persistent = @intFromPtr(&gfxMapProbe);
    draw.gfx_fence_wait = @intFromPtr(&gfxWaitProbe);
    draw.gfx_queue_submit_native = @intFromPtr(&nativeSubmitProbe);
    draw.gfx_queue_backend_info = @intFromPtr(&gfxBackendInfoProbe);
    draw.gfx_atomic_test = @intFromPtr(&outputTestProbe);
    draw.gfx_atomic_submit = @intFromPtr(&modeSubmitProbe);
    draw.gfx_atomic_status = @intFromPtr(&modeStatusProbe);
    draw.gfx_atomic_resolve = @intFromPtr(&modeResolveProbe);
    draw.gfx_memory_budget = @intFromPtr(&budgetProbe);
    draw.gfx_telemetry = @intFromPtr(&telemetryProbe);
    draw.display_cursor_info = @intFromPtr(&cursorInfoProbe);
    draw.display_cursor_status = @intFromPtr(&cursorStatusProbe);
    draw.display_cursor_submit = @intFromPtr(&cursorSubmitProbe);
    budget_probe_rc = 1;
}
pub export fn sdk_gui_oracle_tables(sys: *r4os.platform2.abi.R4XStartR4Sys2, desk: *r4os.platform2.abi.R4XStartR4Desk2, draw: *r4os.platform2.abi.R4XStartR4Draw2) callconv(.c) void {
    var tables = makeTables(true);
    enableFrameContract(&tables[2]);
    sys.* = tables[0];
    desk.* = tables[1];
    draw.* = tables[2];
    event_index = 0;
    interop_codepoint = 0x1f642;
    now_ticks = 100;
    clipboard_revision = 7;
    activity_waits = 0;
    frame_begin_count = 0;
    frame_append_count = 0;
    frame_commit_count = 0;
    frame_cancel_count = 0;
    frame_append_fail_at = 0;
    draw_count = 0;
    alpha8_count = 0;
    raster_count = 0;
    present_count = 0;
    resetFrameCapture();
}
pub export fn sdk_gui_oracle_pixels(out: [*]u32, count: usize) callconv(.c) i32 {
    if (count != 12) return -1;
    replayCaptured(4, 3, out[0..count]);
    return if (captured_command_count == 5 and captured_resource_len == 12 and captured_commands[4].resource_offset == 0 and frame_append_count == 1 and frame_commit_count == 1 and draw_count == 0 and raster_count == 0) 0 else -2;
}
pub export fn sdk_gui_oracle_fail_append(at: u32) callconv(.c) void {
    frame_append_fail_at = at;
}
pub export fn sdk_gui_oracle_cancelled() callconv(.c) u32 {
    return frame_cancel_count;
}

fn makeApp(tables: anytype, imports: *[3]r4os.abi.R4XStartImport, context: *r4os.platform2.abi.R4XStartContext2) !r4os.App {
    imports.* = .{
        .{ .group_id = @intFromEnum(r4os.abi.R4LGroup.r4sys), .resolved_version = 2, .min_version = 2, .flags = r4os.abi.r4xstart_import_flag_group_interface, .table = @intFromPtr(&tables[0]) },
        .{ .group_id = @intFromEnum(r4os.abi.R4LGroup.r4desk), .resolved_version = 2, .min_version = 2, .flags = r4os.abi.r4xstart_import_flag_group_interface, .table = @intFromPtr(&tables[1]) },
        .{ .group_id = @intFromEnum(r4os.abi.R4LGroup.r4draw), .resolved_version = 2, .min_version = 2, .flags = r4os.abi.r4xstart_import_flag_group_interface, .table = @intFromPtr(&tables[2]) },
    };
    context.* = .{
        .app_class = @intFromEnum(r4os.abi.R4XStartAppClass.gui),
        .flags = r4os.abi.r4xstart_flag_imports_valid | r4os.abi.r4xstart_flag_close_supported,
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
    frame_begin_count = 0;
    frame_commit_count = 0;
    frame_cancel_count = 0;
    var tables = makeTables(true);
    enableFrameContract(&tables[2]);
    var imports: [3]r4os.abi.R4XStartImport = undefined;
    var context: r4os.platform2.abi.R4XStartContext2 = undefined;
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
    switch (window.pollMessage().?) {
        .focus_gained => |v| try std.testing.expect(v.window_id == 4 and v.tick == 0x100000010),
        else => return error.FocusGained,
    }
    switch (window.pollMessage().?) {
        .focus_lost => |v| try std.testing.expect(v.window_id == 4 and v.tick == 0x100000011),
        else => return error.FocusLost,
    }
    switch (window.pollMessage().?) {
        .font_changed => |v| try std.testing.expect(v.window_id == -1 and v.tick == 0),
        else => return error.FontChanged,
    }
    switch (window.pollMessage().?) {
        .input_reset => |v| try std.testing.expect(v.window_id == 4 and v.reason == r4os.abi.gui_input_reset_reason_overflow and v.tick == 0x100000014),
        else => return error.InputReset,
    }
    const unknown = window.pollMessage().?;
    try std.testing.expect(unknown == .unknown);
    try std.testing.expectEqualDeep(raw_events[10], unknown.guiEvent().?);

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
    try std.testing.expect(draw_count >= 2 and present_count == 0);
    try std.testing.expectEqual(@as(u32, 1), frame_begin_count);
    try std.testing.expectEqual(@as(u32, 1), frame_commit_count);
    try std.testing.expectEqual(@as(u32, 0), frame_cancel_count);
}

test "command clipboard timer wait and missing draw capability stay explicit" {
    event_index = raw_events.len;
    now_ticks = 100;
    activity_waits = 0;
    clipboard_revision = 7;
    var tables = makeTables(true);
    var imports: [3]r4os.abi.R4XStartImport = undefined;
    var context: r4os.platform2.abi.R4XStartContext2 = undefined;
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

    const desk = app.desktop().?;
    const raw_desk = r4os.r4xstart.R4Desk.fromProgram(app.lowLevel());
    try std.testing.expectEqual(r4os.abi.remote_frame_error_unsupported, desk.desktopActivityNotify());
    tables[1].desktop_activity_notify = @intFromPtr(&fakeActivityNotify);
    try std.testing.expectEqual(@as(i32, 0), desk.desktopActivityNotify());
    try std.testing.expectEqual(@as(i32, 0), raw_desk.desktopActivityNotify());
    // An old prefix must hide the optional pointer even if memory beyond its
    // advertised size happens to contain a callable address.
    tables[1].size = @offsetOf(r4os.platform2.abi.R4XStartR4Desk2, "desktop_activity_notify");
    try std.testing.expectEqual(r4os.abi.remote_frame_error_unsupported, desk.desktopActivityNotify());
    try std.testing.expectEqual(r4os.abi.remote_frame_error_unsupported, raw_desk.desktopActivityNotify());

    var missing_tables = makeTables(false);
    var missing_imports: [3]r4os.abi.R4XStartImport = undefined;
    var missing_context: r4os.platform2.abi.R4XStartContext2 = undefined;
    var missing_app = try makeApp(&missing_tables, &missing_imports, &missing_context);
    try std.testing.expect(missing_app.window(timers[0..]) == null);
}

test "command clipboard timer scoped activity preserves enrollment race deadline and cancellation" {
    event_index = raw_events.len;
    now_ticks = 100;
    activity_waits = 0;
    desktop_activity_waits = 0;
    clipboard_revision = 7;
    gui_wait_mode = 1;
    defer gui_wait_mode = 0;
    var tables = makeTables(true);
    var imports: [3]r4os.abi.R4XStartImport = undefined;
    var context: r4os.platform2.abi.R4XStartContext2 = undefined;
    var app = try makeApp(&tables, &imports, &context);
    var timers: [0]r4os.Timer = .{};
    var window = app.window(timers[0..]) orelse return error.WindowMissing;
    switch (window.waitMessage(r4os.time_contract.timeoutForever())) {
        .message => |message| switch (message) {
            .clipboard => |value| try std.testing.expectEqual(@as(u32, 8), value.revision),
            else => return error.Clipboard,
        },
        else => return error.MissedPublication,
    }
    try std.testing.expectEqual(r4os.abi.gui_activity_shared_clipboard, last_gui_subscriptions);
    try std.testing.expectEqual(@as(u32, 1), activity_waits);
    try std.testing.expectEqual(@as(u32, 0), desktop_activity_waits);
    // Multiple unrelated shared hints cannot extend the original deadline.
    window.events.subscriptions = 0;
    clipboard_revision = 9;
    gui_wait_mode = 2;
    try std.testing.expect(window.waitMessage(r4os.time_contract.timeoutFinite(.{ .nanoseconds = 10_000_000 })) == .timed_out);
    try std.testing.expectEqual(@as(u64, 110), now_ticks);
    try std.testing.expectEqual(@as(u32, 11), activity_waits);
    try std.testing.expectEqual(@as(u32, 0), last_gui_subscriptions);
    const sequence = window.events.activity_sequence;
    gui_wait_mode = 3;
    switch (window.waitMessage(r4os.time_contract.timeoutForever())) {
        .failure => |value| try std.testing.expectEqual(@as(i32, -2), value),
        else => return error.Cancellation,
    }
    try std.testing.expectEqual(sequence, window.events.activity_sequence);
    try std.testing.expectEqual(@as(u32, 12), activity_waits);
    try std.testing.expectEqual(@as(u32, 0), desktop_activity_waits);
}

test "transactional paint and immutable snapshot use the complete frame facade" {
    frame_begin_count = 0;
    frame_commit_count = 0;
    frame_cancel_count = 0;
    resetFrameCapture();
    var tables = makeTables(true);
    enableFrameContract(&tables[2]);
    var imports: [3]r4os.abi.R4XStartImport = undefined;
    var context: r4os.platform2.abi.R4XStartContext2 = undefined;
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
    var context: r4os.platform2.abi.R4XStartContext2 = undefined;
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

test "buffered Canvas covers widgets partial flush direct operations and rejects missing transactions" {
    frame_begin_count = 0;
    frame_commit_count = 0;
    frame_cancel_count = 0;
    draw_count = 0;
    present_count = 0;
    resetFrameCapture();
    var tables = makeTables(true);
    enableFrameContract(&tables[2]);
    var imports: [3]r4os.abi.R4XStartImport = undefined;
    var context: r4os.platform2.abi.R4XStartContext2 = undefined;
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

    // A shorter/current provider without the required transaction callbacks
    // is refused before any drawing or PRESENT; no old-OS reconstruction.
    resetFrameCapture();
    draw_count = 0;
    present_count = 0;
    var incomplete_tables = makeTables(true);
    var incomplete_imports: [3]r4os.abi.R4XStartImport = undefined;
    var incomplete_context: r4os.platform2.abi.R4XStartContext2 = undefined;
    var incomplete_app = try makeApp(&incomplete_tables, &incomplete_imports, &incomplete_context);
    var incomplete_window = incomplete_app.window(timers[0..]) orelse return error.WindowMissing;
    switch (incomplete_window.beginPaint()) {
        .paint => return error.IncompatiblePaintAccepted,
        .failure => |code| try std.testing.expectEqual(r4os.abi.err_no_fn, code),
    }
    try std.testing.expectEqual(@as(u32, 0), draw_count);
    try std.testing.expectEqual(@as(u32, 0), present_count);
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
    var context: r4os.platform2.abi.R4XStartContext2 = undefined;
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

fn reservedSpanProbe(base: u64, bytes: u64) callconv(.c) i32 {
    std.debug.assert(base == 0x200000000 and bytes == 0x20000000);
    return r4os.abi.gfx_buffer_error_unsupported;
}
fn reservedSpanFacadeProbe() !void {
    const a = r4os.abi;
    var memory: r4os.driver_memory.Context = .{ .table = .{ .reserved_span = @intFromPtr(&reservedSpanProbe) } };
    for (240..248) |bytes| {
        memory.table.size = @intCast(bytes);
        try std.testing.expectEqual(a.err_no_fn, memory.reservedSpan(0x200000000, 0x20000000));
    }
    memory.table.size = 248;
    try std.testing.expectEqual(a.gfx_buffer_error_unsupported, memory.reservedSpan(0x200000000, 0x20000000));
    memory.table.reserved_span = 0;
    try std.testing.expectEqual(a.err_no_fn, memory.reservedSpan(0x200000000, 0x20000000));
    memory.table.unmanaged_span = @intFromPtr(&reservedSpanProbe);
    for (248..256) |bytes| {
        memory.table.size = @intCast(bytes);
        try std.testing.expectEqual(a.err_no_fn, memory.unmanagedSpan(0x200000000, 0x20000000));
    }
    memory.table.size = 256;
    try std.testing.expectEqual(a.gfx_buffer_error_unsupported, memory.unmanagedSpan(0x200000000, 0x20000000));
    memory.table.version = 2;
    try std.testing.expectEqual(a.err_no_fn, memory.unmanagedSpan(0x200000000, 0x20000000));
    memory.table.version = 1;
    memory.table.unmanaged_span = 0;
    try std.testing.expectEqual(a.err_no_fn, memory.unmanagedSpan(0x200000000, 0x20000000));
}
