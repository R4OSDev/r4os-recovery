//! Desktop restores each saved choice once per output generation. Driver
//! failures need an explicit new choice; no endless hardware retry loop.
const std = @import("std");
const a = @import("r4os").abi;
const preferences = @import("brightness_preferences.zig");
pub const Client = struct {
    choice: ?preferences.Choice = null,
    identity: a.GfxOutputId = .{},
    accepted: u64 = 0,
    next_ns: u64 = 0,
    unavailable: bool = false,
    pub fn select(self: *Client, choice: ?preferences.Choice) void {
        if (!std.meta.eql(self.choice, choice)) {
            self.choice = choice; self.accepted = 0; self.next_ns = 0;
        }
    }
    pub fn step(self: *Client, draw: anytype, identity: a.GfxOutputId, now: u64, ready: bool) void {
        if (!std.meta.eql(self.identity, identity)) {
            self.identity = identity; self.accepted = 0; self.next_ns = 0; self.unavailable = false;
        }
        const choice = self.choice orelse return;
        if (!ready or self.accepted != 0 or self.unavailable or now == 0 or now < self.next_ns) return;
        self.next_ns = now +| std.time.ns_per_s;
        var state: a.GfxOutputBrightness = .{};
        const query = draw.gfxOutputBrightness(&identity, &state);
        if (query == a.err_no_fn) { self.unavailable = true; return; }
        if (query != a.gfx_output_ok or !std.meta.eql(state.identity, identity) or state.path == 0 or
            state.minimum >= state.maximum or state.maximum > 65535) return;
        var accepted: a.GfxBrightnessRequest = .{};
        const rc = draw.gfxBrightnessRequest(&.{ .identity = identity,
            .level = std.math.clamp(choice.level, state.minimum, state.maximum) }, &accepted);
        if (rc == a.err_no_fn) self.unavailable = true;
        if (rc == a.gfx_output_ok and std.meta.eql(accepted.identity, identity) and accepted.sequence != 0)
            self.accepted = accepted.sequence;
    }
};
