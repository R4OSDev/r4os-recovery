// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Opt-in metadata diagnostics, never pixel maps or completion receipts.
const std = @import("std");
const a = @import("r4os").abi;
const d = @import("device.zig");
pub const Trace = struct {
    device: *d.Device,
    enabled: bool,
    stage: []const u8 = "validate",
    pub fn init(device: *d.Device) Trace {
        var enabled = false;
        const sys = device.caller.system();
        if (sys.hasFn("env_get") and sys.hasFn("write")) {
            var value: [8]u8 = undefined;
            enabled = sys.envGet("R4GFX_YUV_TRACE", &value) == 1 and value[0] == '1';
        }
        return .{ .device = device, .enabled = enabled };
    }
    pub fn detail(self: Trace, comptime fmt: []const u8, args: anytype) void {
        if (!self.enabled) return;
        const sys = self.device.caller.system();
        var bytes: [512]u8 = undefined;
        const line = std.fmt.bufPrint(&bytes, fmt ++ "\n", args) catch return;
        sys.write(line);
    }
    pub fn failure(self: Trace, err: d.Error) void {
        if (err == error.Busy) return;
        self.detail("R4GFX YUV stage={s} failure={s}", .{ self.stage, @errorName(err) });
    }
};
