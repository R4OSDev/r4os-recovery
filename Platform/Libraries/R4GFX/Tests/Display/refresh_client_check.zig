const std = @import("std");
const t = std.testing;
const a = @import("r4os").abi;
const prefs = @import("../../Display/refresh_preferences.zig");
const presentation = @import("../../Display/refresh_client.zig");
const key: @import("../../Display/topology.zig").Key = .{ .adapter = 1, .connector = 2, .receiver = @splat(3) };
const Fake = struct {
    calls: u64 = 0,
    rc: i32 = a.gfx_output_ok,
    request: a.GfxRefreshRequest = .{},
    value: a.GfxOutputRefresh = .{},
    pub fn gfxRefreshRequest(self: *Fake, input: *const a.GfxRefreshRequest, output: *a.GfxRefreshRequest) i32 {
        self.calls += 1;
        if (self.rc != a.gfx_output_ok) return self.rc;
        self.request = input.*; output.* = input.*; output.sequence = self.calls;
        return a.gfx_output_ok;
    }
    pub fn gfxOutputRefresh(self: *Fake, _: *const a.GfxOutputTarget, output: *a.GfxOutputRefresh) i32 {
        output.* = self.value; return self.rc;
    }
};
pub fn check() !void {
    try brightnessCheck();
    var saved: prefs.Config = .{};
    saved = try saved.change(key, 2, false);
    var other = key; other.connector += 1;
    saved = try saved.change(other, 0, true);
    var bytes: [prefs.max_bytes]u8 = undefined;
    try t.expectEqualDeep(saved, try prefs.Config.parse(try saved.encode(&bytes)));
    try t.expectError(error.Invalid, saved.change(key, 1, true));
    var invalid = saved; invalid.choices[1] = invalid.choices[0];
    try t.expectError(error.Duplicate, invalid.encode(&bytes));
    var duplicate: [prefs.max_bytes]u8 = undefined;
    const one = try (try (prefs.Config{}).change(key, 2, false)).encode(&bytes);
    const start = std.mem.indexOf(u8, one, "DISPLAY=").?;
    @memcpy(duplicate[0..one.len], one); @memcpy(duplicate[one.len..][0..one.len-start], one[start..]);
    try t.expectError(error.Duplicate, prefs.Config.parse(duplicate[0..2*one.len-start]));
    var activity: presentation.Activity = .{};
    activity.frame(1); activity.frame(1); activity.frame(2);
    try t.expect(!activity.animated(3));
    activity.frame(3); try t.expect(activity.animated(4));
    try t.expect(!activity.animated(3 + presentation.renew_ns));
    activity.frame(4 + presentation.renew_ns); try t.expect(!activity.animated(5 + presentation.renew_ns));
    const target: a.GfxOutputTarget = .{ .adapter_id = 1, .connector_id = 2, .head_id = 1,
        .device_generation = 2, .connection_generation = 3, .display_generation = 4 };
    var draw: Fake = .{};
    var client: presentation.Client = .{};
    client.select(saved.find(key).?);
    client.step(&draw, target, 1, 2, true);
    try t.expect(draw.calls == 1 and draw.request.policy == 2 and draw.request.scene == 2 and draw.request.operation == 0);
    client.step(&draw, target, 2, 2, true); try t.expect(draw.calls == 1);
    client.step(&draw, target, 3, 6, true); try t.expect(draw.calls == 2 and draw.request.scene == 6);
    client.step(&draw, target, 4, 6, false); try t.expect(draw.calls == 3 and draw.request.policy == 0);
    saved = try saved.change(key, 0, true); client.select(saved.find(key).?);
    client.step(&draw, target, 5, 2, true);
    try t.expect(draw.request.operation == a.gfx_refresh_operation_flicker and draw.request.policy == 0);
    draw.value = .{ .target = target, .status = .{ .request_sequence = draw.calls, .phase = a.gfx_refresh_phase_disabling } };
    client.step(&draw, target, 6, 2, true); try t.expect(client.action != 0);
    draw.value.status.phase = a.gfx_refresh_phase_faulted;
    client.step(&draw, target, 7, 2, true); try t.expect(client.action == 0 and draw.request.policy == 0);
    saved = try saved.change(key, 2, false); client.select(saved.find(key).?);
    client.step(&draw, target, 8, 2, true);
    try t.expect(draw.request.operation == a.gfx_refresh_operation_clear_fault and draw.request.policy == 0);
    draw.value.status = .{ .request_sequence = draw.calls, .phase = a.gfx_refresh_phase_fixed };
    client.step(&draw, target, 9, 2, true); try t.expect(draw.request.policy == 2 and client.action == 0);
    const calls = draw.calls;
    client.step(&draw, target, 9 + presentation.renew_ns, 2, true); try t.expect(draw.calls == calls + 1);
    client.release(&draw, target); try t.expect(draw.request.operation == a.gfx_refresh_operation_release);
    draw.rc = a.gfx_output_error_unsupported;
    client.step(&draw, target, 10 + 2*presentation.renew_ns, 2, true);
    const unsupported_calls = draw.calls;
    client.step(&draw, target, 11 + 2*presentation.renew_ns, 2, true);
    try t.expect(draw.calls == unsupported_calls and !client.unavailable);
    draw.rc = a.gfx_output_ok;
    client.step(&draw, target, 11 + 3*presentation.renew_ns, 2, true);
    try t.expect(draw.calls == unsupported_calls + 1 and draw.request.policy == 2);
    draw.rc = a.err_no_fn;
    client.step(&draw, target, 12 + 4*presentation.renew_ns, 2, true);
    const missing_calls = draw.calls;
    client.step(&draw, target, 13 + 5*presentation.renew_ns, 2, true); try t.expect(draw.calls == missing_calls);
}

const brightness_prefs = @import("../../Display/brightness_preferences.zig");
const BrightnessFake = struct {
    calls: u64 = 0,
    value: a.GfxOutputBrightness = .{},
    pub fn gfxOutputBrightness(self: *BrightnessFake, _: *const a.GfxOutputId, output: *a.GfxOutputBrightness) i32 { output.* = self.value; return 1; }
    pub fn gfxBrightnessRequest(self: *BrightnessFake, input: *const a.GfxBrightnessRequest, output: *a.GfxBrightnessRequest) i32 {
        self.calls += 1; output.* = input.*; output.sequence = self.calls;
        std.debug.assert(input.level >= self.value.minimum and input.level <= self.value.maximum);
        return 1;
    }
};
fn brightnessCheck() !void {
    var saved: brightness_prefs.Config = .{};
    saved = try saved.change(key, 0);
    var bytes: [brightness_prefs.max_bytes]u8 = undefined;
    try t.expectEqualDeep(saved, try brightness_prefs.Config.parse(try saved.encode(&bytes)));
    try t.expectError(error.Invalid, saved.change(.{}, 100));
    try t.expectError(error.Invalid, saved.change(key, 65536));
    var invalid = saved; invalid.count = 2; invalid.choices[1] = invalid.choices[0];
    try t.expectError(error.Duplicate, invalid.encode(&bytes));
    var draw: BrightnessFake = .{ .value = .{ .identity = .{ .adapter_id = 1, .connector_id = 2,
        .device_generation = 3, .connection_generation = 4 }, .path = 1, .phase = 1, .minimum = 1024, .maximum = 65535, .current = 40000, .flags = 1 } };
    var client: @import("../../Display/brightness_client.zig").Client = .{};
    client.select(saved.find(key));
    client.step(&draw, draw.value.identity, 1, false); try t.expect(draw.calls == 0);
    client.step(&draw, draw.value.identity, 2, true); try t.expect(draw.calls == 1 and client.accepted == 1);
    draw.value.phase = a.gfx_brightness_phase_failed; draw.value.flags = 0;
    client.step(&draw, draw.value.identity, 2 * std.time.ns_per_s, true); try t.expect(draw.calls == 1);
    saved = try saved.change(key, 0); client.select(saved.find(key));
    client.step(&draw, draw.value.identity, 3 * std.time.ns_per_s, true); try t.expect(draw.calls == 2);
    draw.value.identity.connection_generation += 1;
    client.step(&draw, draw.value.identity, 4 * std.time.ns_per_s, true); try t.expect(draw.calls == 3);
    client.select(null);
    client.step(&draw, draw.value.identity, 5 * std.time.ns_per_s, true); try t.expect(draw.calls == 3);
}
