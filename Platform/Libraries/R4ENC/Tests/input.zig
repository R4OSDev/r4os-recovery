// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const t = std.testing;
const r = @import("r4os");
const a = r.abi;
const c = @import("binding");
const input = @import("encode_input");
const Budget = @import("native_allocation").Budget;
var pixels: [768]u8 = undefined;
var refs: u32 = 0;
var maps: u32 = 0;
var imports: u32 = 0;
var unmap_busy = false;
var release_busy = false;
var terminal = false;
var retained = false;
var failed = false;
fn h(id: u32) a.GfxBufferHandle {
    return .{ .id = id, .generation = 7 };
}
fn importBo(source: *const a.GfxBufferHandle, output: *a.GfxBufferReference) callconv(.c) i32 {
    std.debug.assert(std.meta.eql(source.*, h(2)) and refs == 0);
    refs += 1;
    imports += 1;
    output.* = .{ .buffer = h(1), .reference = h(3), .flags = a.gfx_buffer_reference_immutable };
    return a.gfx_buffer_result_ok;
}
fn describe(reference: *const a.GfxBufferHandle, output: *a.GfxBufferDescriptor) callconv(.c) i32 {
    std.debug.assert(std.meta.eql(reference.*, h(3)) and refs == 1);
    output.* = .{ .byte_length = pixels.len, .width = 16, .height = 16, .format = a.gfx_buffer_format_nv12, .plane_count = 2, .plane_offsets = .{ 0, 512, 0, 0 }, .plane_pitches = .{ 32, 32, 0, 0 } };
    return a.gfx_buffer_result_ok;
}
fn map(reference: *const a.GfxBufferHandle, access: u32, offset: u64, count: u64, output: *a.GfxBufferMap) callconv(.c) i32 {
    std.debug.assert(std.meta.eql(reference.*, h(3)) and refs == 1 and maps == 0 and
        access == a.gfx_buffer_map_read and offset == 0 and count == pixels.len);
    maps += 1;
    output.* = .{ .lease = h(4), .cpu_address = @intFromPtr(&pixels), .byte_length = pixels.len };
    return a.gfx_buffer_result_ok;
}
fn unmap(lease: *const a.GfxBufferHandle) callconv(.c) i32 {
    std.debug.assert(std.meta.eql(lease.*, h(4)) and maps == 1);
    if (unmap_busy) return a.gfx_buffer_error_busy;
    maps -= 1;
    return a.gfx_buffer_result_ok;
}
fn release(reference: *const a.GfxBufferHandle) callconv(.c) i32 {
    std.debug.assert(std.meta.eql(reference.*, h(3)) and refs == 1 and maps == 0);
    if (release_busy) return a.gfx_buffer_error_busy;
    refs -= 1;
    return a.gfx_buffer_result_ok;
}
fn query(fence: *const a.GfxFence, output: *a.GfxFenceStatus) callconv(.c) i32 {
    output.* = .{ .fence = fence.*, .phase = if (terminal) a.gfx_queue_phase_terminal else a.gfx_queue_phase_running, .result = if (failed) a.gfx_queue_result_device_lost else a.gfx_queue_result_complete, .flags = @intFromBool(retained), .milestone = a.gfx_queue_milestone_device_execution };
    return a.gfx_queue_ok;
}
pub fn run() !void {
    refs = 0;
    maps = 0;
    imports = 0;
    unmap_busy = false;
    release_busy = false;
    terminal = false;
    retained = false;
    failed = false;
    var raw: a.R4XStartContext = std.mem.zeroes(a.R4XStartContext);
    var table: a.R4XStartR4Draw = .{};
    table.gfx_buffer_import = @intFromPtr(&importBo);
    table.gfx_buffer_describe = @intFromPtr(&describe);
    table.gfx_buffer_map = @intFromPtr(&map);
    table.gfx_buffer_unmap = @intFromPtr(&unmap);
    table.gfx_buffer_release = @intFromPtr(&release);
    table.gfx_fence_query = @intFromPtr(&query);
    var bundle: r.program.Bundle = .{ .raw = &raw, .draw = &table };
    const base = r.program.Context.initBundle(&bundle);
    const memory: r.gfx_buffers.Context = .{ .base = base };
    const queues: r.gfx_queue.Context = .{ .base = base };
    var budget: Budget = .{ .limit = pixels.len };
    var owner: input.Input(c) = .{};
    defer {
        std.debug.assert(refs == 0 and maps == 0 and budget.liveBytes() == 0 and owner.empty());
    }
    var frame = std.mem.zeroes(c.R4EncFrame);
    frame.version = 1;
    frame.size = @sizeOf(c.R4EncFrame);
    frame.stream_generation = 1;
    frame.format = c.format_nv12;
    frame.plane_count = 2;
    frame.ready = .{ .slot = 0, .adapter_id = 0, .timeline = 11, .point = 4, .device_generation = 9, .reset_generation = 2 };
    frame.plane0 = .{ .buffer = @bitCast(h(1)), .reference = @bitCast(h(2)), .offset = 0, .pitch = 32, .row_bytes = 16, .rows = 16, .reserved = 0 };
    frame.plane1 = frame.plane0;
    frame.plane1.offset = 512;
    frame.plane1.rows = 8;
    @memset(&pixels, 0xff);
    for (0..16) |y| for (0..16) |x| {
        pixels[y * 32 + x] = @intCast(y * 16 + x);
    };
    for (0..8) |y| for (0..8) |x| {
        pixels[512 + y * 32 + x * 2] = @intCast(x + 10);
        pixels[513 + y * 32 + x * 2] = @intCast(y + 40);
    };
    try owner.admit(&memory, &budget, frame, 16, 16);
    try t.expectEqual(@as(u32, 1), imports);
    try t.expectEqual(pixels.len, budget.liveBytes());
    try t.expectError(error.Busy, owner.mapCpu(&memory, &queues));
    terminal = true;
    retained = true;
    try t.expectError(error.Busy, owner.mapCpu(&memory, &queues));
    try t.expectEqual(@as(u32, 0), maps);
    retained = false;
    const view = try owner.mapCpu(&memory, &queues);
    try t.expectEqual(@as(u32, 1), maps);
    var y_plane: [256]u8 = undefined;
    var u_plane: [64]u8 = undefined;
    var v_plane: [64]u8 = undefined;
    try view.copyPlanar(.{ &y_plane, &u_plane, &v_plane });
    for (y_plane, 0..) |v, i| try t.expectEqual(@as(u8, @intCast(i)), v);
    for (u_plane, v_plane, 0..) |u, v, i| {
        try t.expectEqual(@as(u8, @intCast(i % 8 + 10)), u);
        try t.expectEqual(@as(u8, @intCast(i / 8 + 40)), v);
    }
    unmap_busy = true;
    try t.expectError(error.Busy, owner.close(&memory));
    try t.expectEqual(pixels.len, budget.liveBytes());
    unmap_busy = false;
    release_busy = true;
    try t.expectError(error.Busy, owner.close(&memory));
    try t.expectEqual(@as(u32, 0), maps);
    try t.expectEqual(@as(u32, 1), refs);
    release_busy = false;
    try owner.close(&memory);
    try owner.close(&memory);
    try t.expectEqual(@as(usize, 0), budget.liveBytes());
    // Complete validation precedes any retain; partial allocation failure
    // instead retains its exact returned reference until explicit cleanup.
    frame.plane1.pitch = std.math.maxInt(u64);
    try t.expectError(error.Invalid, owner.admit(&memory, &budget, frame, 16, 16));
    try t.expectEqual(@as(u32, 1), imports);
    frame.plane1.pitch = 32;
    budget.limit = 100;
    try t.expectError(error.NoMemory, owner.admit(&memory, &budget, frame, 16, 16));
    try t.expectEqual(@as(u32, 1), refs);
    try owner.close(&memory);
    budget.limit = pixels.len;
    try owner.admit(&memory, &budget, frame, 16, 16);
    failed = true;
    try t.expectError(error.Stale, owner.mapCpu(&memory, &queues));
    try t.expectEqual(@as(u32, 0), maps);
    try owner.close(&memory);
}
