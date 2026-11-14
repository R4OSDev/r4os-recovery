// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Only immutable boot-lifetime platform tables may be bound here.
const r = @import("r4os");
const native = @import("r4native");
const system_info = @import("r4native").system_info;

pub fn bind2(context: *const r.platform2.Context) bool {
    const draw = context.drawing() orelse return false;
    const devices = context.devices() orelse return false;
    return native.system.reaches(draw, "gfx_queue_backend_info") and
        native.system.reaches(devices, "memory_pressure_snapshot") and system_info.bind2(devices);
}

// C views live in the exact process-owned current snapshot.
pub const CFacade = extern struct {
    table: usize = 0,
    generation2: ?*const r.platform2.CView = null,
};
pub export fn r4vk_get_graphics_tables(draw: *CFacade, devices: *CFacade) callconv(.c) c_int {
    const saved = native.application.snapshot() orelse return 0;
    if (saved.generation2.context.drawing() == null or saved.generation2.context.devices() == null) return 0;
    draw.* = .{ .generation2 = &saved.generation2.c_view };
    devices.* = .{ .generation2 = &saved.generation2.c_view };
    return 1;
}
