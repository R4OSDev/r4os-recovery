// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Only immutable boot-lifetime platform tables may be bound here.
const std = @import("std");
const r = @import("r4os");
const a = r.abi;
const native = @import("r4native");
const system_info = @import("r4native").system_info;
var draw_address: std.atomic.Value(usize) = .init(0);
var devices_address: std.atomic.Value(usize) = .init(0);

pub fn bind(draw: *const a.R4XStartR4Draw, devices: *const a.R4XStartR4Dev) bool {
    if (draw.magic != a.r4xstart_r4draw_magic or devices.magic != a.r4xstart_r4dev_magic or
        draw.size < @offsetOf(a.R4XStartR4Draw, "gfx_queue_backend_info") + 8 or
        draw.gfx_queue_backend_info == 0 or
        devices.size < @offsetOf(a.R4XStartR4Dev, "memory_pressure_snapshot") + 8 or
        devices.memory_pressure_snapshot == 0 or !system_info.bind(devices)) return false;
    const old_draw = draw_address.cmpxchgStrong(0, @intFromPtr(draw), .acq_rel, .acquire);
    if (old_draw != null and old_draw.? != @intFromPtr(draw)) return false;
    const old_devices = devices_address.cmpxchgStrong(0, @intFromPtr(devices), .acq_rel, .acquire);
    return old_devices == null or old_devices.? == @intFromPtr(devices);
}

pub fn bind2(context: *const r.platform2.Context) bool {
    const draw = context.drawing() orelse return false;
    const devices = context.devices() orelse return false;
    return native.system.reaches(draw, "gfx_queue_backend_info") and
        native.system.reaches(devices, "memory_pressure_snapshot") and system_info.bind2(devices);
}

// The SDK C facades contain both explicit generation alternatives. Always
// initialize the complete record. C views live in the process-owned snapshot,
// never in a temporary native Zig Context or shared library global.
pub const CFacade = extern struct {
    table: usize = 0,
    generation2: ?*const r.platform2.CView = null,
};
pub export fn r4vk_get_graphics_tables(draw: *CFacade, devices: *CFacade) callconv(.c) c_int {
    if (native.application.snapshot()) |saved| switch (saved.*) {
        .generation2 => {
            if (saved.generation2.context.drawing() == null or saved.generation2.context.devices() == null) return 0;
            draw.* = .{ .generation2 = &saved.generation2.c_view };
            devices.* = .{ .generation2 = &saved.generation2.c_view };
            return 1;
        },
        .legacy => {},
    };
    const d = draw_address.load(.acquire);
    const v = devices_address.load(.acquire);
    if (d == 0 or v == 0) return 0;
    draw.* = .{ .table = d };
    devices.* = .{ .table = v };
    return 1;
}

comptime { _ = system_info; }
