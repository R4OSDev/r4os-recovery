//! Presenter-owned intent lease. Configuration and measured hardware state
//! remain separate; missing APIs leave the ordinary fixed presentation path.
const std = @import("std");
const a = @import("r4os").abi;
const prefs = @import("refresh_preferences.zig");
pub const renew_ns = 500 * std.time.ns_per_ms;
pub const Activity = struct {
    last_ns: u64 = 0,
    streak: u8 = 0,
    pub fn frame(self: *Activity, now: u64) void {
        if (now == 0 or now == self.last_ns) return;
        self.streak = if (now > self.last_ns and now - self.last_ns <= 200 * std.time.ns_per_ms) self.streak +| 1 else 1;
        self.last_ns = now;
    }
    pub fn animated(self: *const Activity, now: u64) bool {
        return self.streak >= 3 and now >= self.last_ns and now - self.last_ns < renew_ns;
    }
};
pub const Client = struct {
    choice: prefs.Choice = .{},
    configured: bool = false,
    next_ns: u64 = 0,
    sent: ?a.GfxRefreshRequest = null,
    attempted: ?a.GfxRefreshRequest = null,
    action: u32 = 0,
    action_sequence: u64 = 0,
    unavailable: bool = false,

    pub fn select(self: *Client, choice: prefs.Choice) void {
        if (self.configured and std.meta.eql(choice, self.choice)) return;
        // Loading preferences at startup does not repeatedly clear a fault.
        self.action = if (choice.blocked) a.gfx_refresh_operation_flicker else
            if (self.configured and choice.serial != self.choice.serial) a.gfx_refresh_operation_clear_fault else 0;
        self.action_sequence = 0; self.next_ns = 0;
        self.choice = choice; self.configured = true;
    }
    pub fn step(self: *Client, draw: anytype, target: a.GfxOutputTarget, now: u64, scene: u32, ready: bool) void {
        if (self.unavailable or now == 0) return;
        if (self.action_sequence != 0) {
            var state: a.GfxOutputRefresh = .{};
            if (draw.gfxOutputRefresh(&target, &state) == a.gfx_output_ok and std.meta.eql(state.target, target) and
                state.status.request_sequence == self.action_sequence and
                ((self.action == a.gfx_refresh_operation_flicker and state.status.phase == a.gfx_refresh_phase_faulted) or
                (self.action == a.gfx_refresh_operation_clear_fault and state.status.phase == a.gfx_refresh_phase_fixed)))
            { self.action = 0; self.action_sequence = 0; self.next_ns = 0; }
        }
        const request: a.GfxRefreshRequest = .{ .target = target, .operation = self.action,
            .policy = if (ready and self.action == 0 and !self.choice.blocked) self.choice.policy else 0,
            .scene = if (ready and self.action == 0) scene else 0 };
        if (self.attempted) |old| if (std.meta.eql(old, request) and now < self.next_ns) return;
        var accepted: a.GfxRefreshRequest = .{};
        const rc = draw.gfxRefreshRequest(&request, &accepted);
        self.attempted = request;
        self.next_ns = now +| renew_ns;
        if (rc == a.err_no_fn) { self.unavailable = true; return; }
        // Eligibility can return after a mode/link transition under the
        // same target. Retry an unsupported request on the bounded cadence.
        if (rc != a.gfx_output_ok) return;
        self.sent = request;
        if (self.action != 0) self.action_sequence = accepted.sequence;
    }
    pub fn release(self: *Client, draw: anytype, target: a.GfxOutputTarget) void {
        if (self.sent == null) return;
        var accepted: a.GfxRefreshRequest = .{};
        _ = draw.gfxRefreshRequest(&.{ .target = target, .operation = a.gfx_refresh_operation_release }, &accepted);
        self.sent = null;
    }
};
