//! Bounded userland presentation lifetime. The provider owns resource/job
//! references; only its actual consumer receipts may call rendered/retired.
//! A timer can select a future opportunity, never manufacture visibility.
const std = @import("std");
pub const capacity = 3;
pub const Error = error{ Invalid, Unsupported, Busy, Stale, Occluded, Suboptimal, Lost, Exhausted };
pub const Policy = enum(u32) { fifo = 0, latest_ready = 1, immediate = 2 };
pub const Path = enum(u32) { copy = 0, composition = 1, direct = 2, overlay = 3 };
pub const Life = enum(u32) { active, occluded, suboptimal, lost, closing };
pub const Result = enum(u32) { pending, presented, copied, discarded, failed, lost };
pub const Phase = enum(u32) { free, acquired, queued, submitted, terminal };
pub const Output = struct {
    generation: u64,
    width: u32,
    height: u32,
    policies: u32 = 1,
    synchronized: bool = false,
    visibility: bool = false,
    direct: bool = false,
    overlay: bool = false,
    occluded: bool = false,
    adaptive: bool = false,
    // Monotonic CPU observation of a known scanout phase. GPU timestamps
    // from a different clock domain must never be placed here.
    phase_ns: u64 = 0,
    interval_ns: u64 = 0,
};
pub const Config = struct { count: u32 = 2, policy: Policy = .fifo, require_vsync: bool = false };
pub const Token = struct { slot: u32 = 0, generation: u64 = 0, serial: u64 = 0 };
pub const Times = struct {
    input_ns: u64 = 0,
    acquired_ns: u64 = 0,
    queued_ns: u64 = 0,
    render_end_ns: u64 = 0,
    selected_ns: u64 = 0, // Predicted opportunity, not an observed VBlank.
    submitted_ns: u64 = 0,
    copied_ns: u64 = 0,
    visible_ns: u64 = 0,
    released_ns: u64 = 0,
};
pub const Frame = struct {
    token: Token = .{},
    sequence: u64 = 0,
    phase: Phase = .free,
    result: Result = .pending,
    path: Path = .copy,
    render_held: bool = false,
    consumer_held: bool = false,
    times: Times = .{},
};
pub const Chain = struct {
    generation: u64 = 0,
    serial: u64 = 0,
    enqueued: u64 = 0,
    config: Config = .{},
    output: Output = .{ .generation = 0, .width = 0, .height = 0 },
    life: Life = .closing,
    frames: [capacity]Frame = @splat(.{}),
    cursor: usize = 0,
    render_budget_ns: u64 = 0,
    next_start_ns: u64 = 0,

    pub fn configure(self: *Chain, config: Config, output: Output) Error!void {
        if (config.count < 2 or config.count > capacity or output.generation == 0 or output.width == 0 or output.height == 0 or
            output.policies & ~@as(u32, 7) != 0 or output.policies & 1 == 0 or
            (output.phase_ns == 0) != (output.interval_ns == 0) or output.interval_ns > std.time.ns_per_s or
            (output.adaptive and (!output.synchronized or output.interval_ns != 0))) return error.Invalid;
        if (output.policies & (@as(u32, 1) << @intCast(@intFromEnum(config.policy))) == 0 or
            (config.require_vsync and (!output.synchronized or config.policy == .immediate))) return error.Unsupported;
        for (&self.frames) |*value| if (value.phase != .free) return error.Busy;
        const generation = std.math.add(u64, self.generation, 1) catch return error.Exhausted;
        self.* = .{ .generation = generation, .serial = self.serial, .enqueued = self.enqueued, .config = config, .output = output,
            .life = if (output.occluded) .occluded else .active };
    }
    pub fn frame(self: *Chain, token: Token) Error!*Frame {
        if (token.generation != self.generation or token.slot == 0 or token.slot > self.config.count or token.serial == 0) return error.Stale;
        const value = &self.frames[token.slot - 1];
        if (value.phase == .free or !std.meta.eql(value.token, token)) return error.Stale;
        return value;
    }
    fn available(self: *const Chain) Error!void {
        return switch (self.life) { .active => {}, .occluded => error.Occluded, .suboptimal => error.Suboptimal,
            .lost => error.Lost, .closing => error.Stale };
    }
    pub fn acquire(self: *Chain, now: u64, input: u64) Error!Token {
        try self.available();
        if (now == 0 or input > now) return error.Invalid;
        if (now < self.next_start_ns) return error.Busy;
        const index = for (0..self.config.count) |offset| {
            const index = (self.cursor + offset) % self.config.count;
            if (self.frames[index].phase == .free) break index;
        } else return error.Busy;
        const serial = std.math.add(u64, self.serial, 1) catch return error.Exhausted;
        const token: Token = .{ .slot = @intCast(index + 1), .generation = self.generation, .serial = serial };
        self.frames[index] = .{ .token = token, .phase = .acquired, .times = .{ .input_ns = input, .acquired_ns = now } };
        self.serial = serial; self.cursor = (index + 1) % self.config.count;
        return token;
    }
    pub fn present(self: *Chain, token: Token, now: u64, path: Path, render_pending: bool) Error!void {
        try self.available();
        const value = try self.frame(token);
        if (value.phase != .acquired or now < value.times.acquired_ns) return error.Invalid;
        if ((path == .direct and !self.output.direct) or (path == .overlay and !self.output.overlay)) return error.Unsupported;
        const sequence = std.math.add(u64, self.enqueued, 1) catch return error.Exhausted;
        value.phase = .queued; value.path = path; value.render_held = render_pending;
        value.sequence = sequence; self.enqueued = sequence;
        value.times.queued_ns = now;
        if (!render_pending) value.times.render_end_ns = now;
    }
    pub fn rendered(self: *Chain, token: Token, now: u64, succeeded: bool) Error!void {
        const value = try self.frame(token);
        if (!value.render_held or now < value.times.acquired_ns) return error.Invalid;
        value.render_held = false; value.times.render_end_ns = now;
        if (!succeeded and value.result == .pending) { value.result = .failed; value.phase = .terminal; }
        const elapsed = now - value.times.acquired_ns;
        // Smooth the observed producer time, bounded by one second. The
        // cold allocation frame cannot create an unbounded future backlog.
        const sample = @min(elapsed, std.time.ns_per_s);
        self.render_budget_ns = if (self.render_budget_ns == 0) sample else (self.render_budget_ns * 3 + sample) / 4;
    }
    fn opportunity(self: *const Chain, now: u64) u64 {
        if (self.config.policy == .immediate or self.output.phase_ns == 0) return 0;
        if (now < self.output.phase_ns) return self.output.phase_ns;
        const periods = (now - self.output.phase_ns) / self.output.interval_ns + 1;
        return self.output.phase_ns +| periods *| self.output.interval_ns;
    }
    /// Selection has no side effects. Backpressure/rejection at the actual
    /// consumer cannot drop an older ready frame or strand a selected slot.
    pub fn candidate(self: *Chain) ?Token {
        if (self.life != .active) return null;
        var selected: ?*Frame = null;
        for (&self.frames) |*value| {
            if (value.phase == .submitted) return null;
            if (value.consumer_held and value.times.visible_ns == 0) return null;
            if (value.phase != .queued) continue;
            if (self.config.policy != .latest_ready) {
                if (selected == null or value.sequence < selected.?.sequence) selected = value;
            } else if (!value.render_held and (selected == null or value.sequence > selected.?.sequence)) selected = value;
        }
        const value = selected orelse return null;
        return if (value.render_held) null else value.token;
    }
    pub fn submitted(self: *Chain, token: Token, now: u64) Error!void {
        const candidate_token = self.candidate() orelse return error.Busy;
        if (!std.meta.eql(candidate_token, token)) return error.Stale;
        const value = try self.frame(token);
        if (now < value.times.render_end_ns) return error.Invalid;
        value.phase = .submitted; value.consumer_held = true;
        value.times.submitted_ns = now; value.times.selected_ns = self.opportunity(now);
        if (self.config.policy == .latest_ready) for (&self.frames) |*prior| {
            if (prior.phase == .queued and prior.sequence < value.sequence) { prior.phase = .terminal; prior.result = .discarded; }
        };
        // No global wait. The caller uses this deadline with its ordinary
        // event wait and may continue input/work while no frame is needed.
        self.next_start_ns = if (value.times.selected_ns == 0) 0 else
            value.times.selected_ns -| @min(self.render_budget_ns +| std.time.ns_per_ms, self.output.interval_ns);
    }
    /// Actual completion of all consumer access. For a direct/overlay image
    /// this is FINISHED/detach, not the activation of that same image.
    pub fn retired(self: *Chain, token: Token, now: u64, succeeded: bool) Error!void {
        const value = try self.frame(token);
        if (!value.consumer_held or now < value.times.submitted_ns or now < value.times.visible_ns) return error.Invalid;
        value.consumer_held = false; value.times.released_ns = now;
        if (!succeeded and value.result == .pending) { value.phase = .terminal; value.result = .failed; }
        if (succeeded and (value.path == .copy or value.path == .composition)) {
            value.times.copied_ns = now;
            if (!self.output.visibility and value.result == .pending) { value.phase = .terminal; value.result = .copied; }
        }
    }
    pub fn visible(self: *Chain, token: Token, now: u64) Error!void {
        const value = try self.frame(token);
        if (!self.output.visibility or value.phase != .submitted or value.result != .pending or now < value.times.submitted_ns or
            ((value.path == .copy or value.path == .composition) and value.consumer_held)) return error.Invalid;
        value.phase = .terminal; value.result = .presented; value.times.visible_ns = now;
    }
    /// Terminal errors never imply quiescence. The adapter must still poll
    /// the exact render/consumer receipts before release can succeed.
    pub fn abandon(self: *Chain, token: Token, result: Result) Error!void {
        if (result != .discarded and result != .failed and result != .lost) return error.Invalid;
        const value = try self.frame(token);
        if (value.result == .pending) { value.phase = .terminal; value.result = result; }
    }
    pub fn release(self: *Chain, token: Token) Error!void {
        const value = try self.frame(token);
        if (value.render_held or value.consumer_held or (value.phase != .terminal and value.phase != .acquired)) return error.Busy;
        value.* = .{};
    }
    pub fn change(self: *Chain, life: Life) void {
        if (self.life == .lost or self.life == .closing or life == .active) return;
        self.life = life;
        for (&self.frames) |*value| if (value.phase != .free and value.result == .pending) {
            value.phase = .terminal; value.result = if (life == .lost) .lost else .discarded;
        };
        self.next_start_ns = 0;
    }
    pub fn refresh(self: *Chain, output: Output) Error!void {
        if (self.generation == 0 or self.life == .closing or self.life == .lost) return error.Stale;
        if (output.generation != self.output.generation) { self.change(.suboptimal); return; }
        if (output.width != self.output.width or output.height != self.output.height) { self.change(.suboptimal); return; }
        if (output.policies & (@as(u32, 1) << @intCast(@intFromEnum(self.config.policy))) == 0 or
            (self.config.require_vsync and !output.synchronized)) { self.change(.suboptimal); return; }
        if (output.occluded) self.change(.occluded) else if (self.life == .occluded) self.life = .active;
        if (self.output.adaptive != output.adaptive or self.output.interval_ns != output.interval_ns) self.next_start_ns = 0;
        self.output = output;
    }
};
