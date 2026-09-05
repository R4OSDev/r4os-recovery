const std = @import("std");
const web_fonts = @import("web_fonts.zig");

pub const max_faces: usize = web_fonts.max_faces;

/// R4OS keeps the installed fallback visible while a document font loads.
/// `fallback` may replace it during this interval; afterwards a late face is
/// ignored for the current document epoch.
pub const fallback_swap_period_ms: u64 = 3_000;

/// `optional` only replaces the visible fallback when it becomes available
/// very quickly. Cache and local hits normally complete inside this interval.
pub const optional_swap_period_ms: u64 = 100;

pub const Error = error{
    FaceLimit,
    InvalidFace,
    DuplicateFace,
    DuplicateEpoch,
};

pub const Demand = struct {
    face_index: u16,
    display: web_fonts.FontDisplay,
};

pub const Completion = enum(u8) {
    /// The face was already active before this demand epoch. It settles the
    /// epoch but must not request another layout revision.
    retained,
    ready,
    failed,
};

pub const FacePhase = enum(u8) {
    unused,
    loading,
    ready,
    failed,
    expired,

    pub fn terminal(self: FacePhase) bool {
        return self == .ready or self == .failed or self == .expired;
    }
};

pub const Revision = struct {
    epoch: u64,
    serial: u64,
    activated_faces: u16,
};

const FaceState = struct {
    face_index: u16 = std.math.maxInt(u16),
    display: web_fonts.FontDisplay = .auto,
    phase: FacePhase = .unused,
};

/// Pure document-font activation state. The caller owns decoding and face
/// lifetime; this type only decides whether completed faces may replace the
/// visible fallback and coalesces one document epoch into at most one layout
/// revision. A revision is published only after every demanded face is ready,
/// failed, or outside its display window, so one epoch cannot trigger a train
/// of partial reflows.
///
/// Time is caller supplied and logical. Backwards samples are clamped to the
/// latest observed value. `swap`, plus R4OS's fallback-visible interpretations
/// of `auto` and `block`, has no activation deadline; cancellation or resource
/// failure must settle those faces. `fallback` and `optional` use the bounded
/// periods above.
pub const Coordinator = struct {
    initialized: bool = false,
    epoch: u64 = 0,
    started_ms: u64 = 0,
    observed_ms: u64 = 0,
    faces: [max_faces]FaceState = [_]FaceState{.{}} ** max_faces,
    face_count: u16 = 0,
    terminal_count: u16 = 0,
    activated_count: u16 = 0,
    next_serial: u64 = 0,
    published: bool = false,
    pending_revision: ?Revision = null,

    /// Starts a new, caller-unique document/layout epoch. Validation is
    /// transactional: an invalid demand list leaves the previous epoch intact.
    pub fn begin(self: *Coordinator, epoch: u64, now_ms: u64, demands: []const Demand) Error!void {
        if (demands.len > max_faces) return error.FaceLimit;
        if (self.initialized and epoch == self.epoch) return error.DuplicateEpoch;

        var next_faces = [_]FaceState{.{}} ** max_faces;
        for (demands, 0..) |demand, index| {
            if (demand.face_index >= max_faces) return error.InvalidFace;
            for (next_faces[0..index]) |existing| {
                if (existing.face_index == demand.face_index) return error.DuplicateFace;
            }
            next_faces[index] = .{
                .face_index = demand.face_index,
                .display = demand.display,
                .phase = .loading,
            };
        }

        self.initialized = true;
        self.epoch = epoch;
        self.started_ms = now_ms;
        self.observed_ms = now_ms;
        self.faces = next_faces;
        self.face_count = @intCast(demands.len);
        self.terminal_count = 0;
        self.activated_count = 0;
        self.published = false;
        self.pending_revision = null;
    }

    /// Applies a decoder/resource result only to the matching live epoch and
    /// loading face. A ready result at or beyond a bounded display deadline is
    /// recorded as expired and never requests layout replacement.
    pub fn complete(self: *Coordinator, epoch: u64, face_index: u16, result: Completion, now_ms: u64) bool {
        if (!self.initialized or epoch != self.epoch) return false;
        if (result == .retained) {
            if (now_ms > self.observed_ms) self.observed_ms = now_ms;
            const retained = self.findFace(face_index) orelse return false;
            if (retained.phase != .loading) return false;
            retained.phase = .ready;
            self.terminal_count += 1;
            _ = self.advanceInternal(self.observed_ms);
            self.publishIfSettled();
            return true;
        }
        _ = self.advanceInternal(now_ms);
        const state = self.findFace(face_index) orelse return false;
        if (state.phase != .loading) return false;

        switch (result) {
            .retained => unreachable,
            .failed => state.phase = .failed,
            .ready => {
                if (canActivate(state.display, self.elapsed())) {
                    state.phase = .ready;
                    self.activated_count += 1;
                } else {
                    state.phase = .expired;
                }
            },
        }
        self.terminal_count += 1;
        self.publishIfSettled();
        return true;
    }

    /// Advances bounded display windows without requiring a resource callback.
    /// Returns false for a stale epoch; otherwise true when at least one face
    /// changed to `expired`.
    pub fn advance(self: *Coordinator, epoch: u64, now_ms: u64) bool {
        if (!self.initialized or epoch != self.epoch) return false;
        return self.advanceInternal(now_ms);
    }

    /// Takes the epoch's sole coalesced layout revision. Repeated calls return
    /// null, and starting a new epoch discards an untaken stale notification.
    pub fn takeRevision(self: *Coordinator) ?Revision {
        const revision = self.pending_revision;
        self.pending_revision = null;
        return revision;
    }

    pub fn phase(self: *const Coordinator, epoch: u64, face_index: u16) ?FacePhase {
        if (!self.initialized or epoch != self.epoch) return null;
        for (self.faces[0..self.face_count]) |state| {
            if (state.face_index == face_index) return state.phase;
        }
        return null;
    }

    pub fn settled(self: *const Coordinator, epoch: u64) bool {
        return self.initialized and epoch == self.epoch and self.terminal_count == self.face_count;
    }

    fn findFace(self: *Coordinator, face_index: u16) ?*FaceState {
        for (self.faces[0..self.face_count]) |*state| {
            if (state.face_index == face_index) return state;
        }
        return null;
    }

    fn elapsed(self: *const Coordinator) u64 {
        return self.observed_ms - self.started_ms;
    }

    fn advanceInternal(self: *Coordinator, now_ms: u64) bool {
        if (now_ms > self.observed_ms) self.observed_ms = now_ms;
        const elapsed_ms = self.elapsed();
        var changed = false;
        for (self.faces[0..self.face_count]) |*state| {
            if (state.phase != .loading or !displayExpired(state.display, elapsed_ms)) continue;
            state.phase = .expired;
            self.terminal_count += 1;
            changed = true;
        }
        self.publishIfSettled();
        return changed;
    }

    fn publishIfSettled(self: *Coordinator) void {
        if (self.published or self.terminal_count != self.face_count or self.activated_count == 0) return;
        self.next_serial +%= 1;
        if (self.next_serial == 0) self.next_serial = 1;
        self.pending_revision = .{
            .epoch = self.epoch,
            .serial = self.next_serial,
            .activated_faces = self.activated_count,
        };
        self.published = true;
    }
};

fn displayExpired(display: web_fonts.FontDisplay, elapsed_ms: u64) bool {
    return switch (display) {
        .fallback => elapsed_ms >= fallback_swap_period_ms,
        .optional => elapsed_ms >= optional_swap_period_ms,
        .auto, .block, .swap => false,
    };
}

fn canActivate(display: web_fonts.FontDisplay, elapsed_ms: u64) bool {
    return !displayExpired(display, elapsed_ms);
}

test "font activation coalesces swap faces into exactly one revision" {
    var coordinator = Coordinator{};
    try coordinator.begin(10, 1_000, &.{
        .{ .face_index = 2, .display = .swap },
        .{ .face_index = 7, .display = .swap },
    });
    try std.testing.expect(coordinator.complete(10, 2, .ready, 90_000));
    try std.testing.expect(coordinator.takeRevision() == null);
    try std.testing.expect(coordinator.complete(10, 7, .failed, 90_001));
    const revision = coordinator.takeRevision().?;
    try std.testing.expectEqual(@as(u64, 10), revision.epoch);
    try std.testing.expectEqual(@as(u64, 1), revision.serial);
    try std.testing.expectEqual(@as(u16, 1), revision.activated_faces);
    try std.testing.expect(coordinator.takeRevision() == null);
    try std.testing.expect(!coordinator.complete(10, 2, .ready, 90_002));
}

test "fallback and optional windows have deterministic deadline boundaries" {
    var coordinator = Coordinator{};
    try coordinator.begin(20, 1_000, &.{.{ .face_index = 1, .display = .fallback }});
    try std.testing.expect(!coordinator.advance(20, 3_999));
    try std.testing.expect(coordinator.complete(20, 1, .ready, 3_999));
    try std.testing.expect(coordinator.takeRevision() != null);

    try coordinator.begin(21, 5_000, &.{.{ .face_index = 1, .display = .fallback }});
    try std.testing.expect(coordinator.advance(21, 8_000));
    try std.testing.expectEqual(FacePhase.expired, coordinator.phase(21, 1).?);
    try std.testing.expect(coordinator.takeRevision() == null);
    try std.testing.expect(!coordinator.complete(21, 1, .ready, 8_001));

    try coordinator.begin(22, 10_000, &.{.{ .face_index = 3, .display = .optional }});
    try std.testing.expect(coordinator.complete(22, 3, .ready, 10_099));
    try std.testing.expect(coordinator.takeRevision() != null);

    try coordinator.begin(23, 20_000, &.{.{ .face_index = 3, .display = .optional }});
    try std.testing.expect(coordinator.advance(23, 20_100));
    try std.testing.expect(coordinator.settled(23));
    try std.testing.expect(coordinator.takeRevision() == null);
}

test "font activation rejects stale epochs and invalid begin is transactional" {
    var coordinator = Coordinator{};
    try coordinator.begin(30, 100, &.{.{ .face_index = 4, .display = .swap }});
    try std.testing.expectError(error.DuplicateEpoch, coordinator.begin(30, 200, &.{}));
    try std.testing.expectError(error.DuplicateFace, coordinator.begin(31, 200, &.{
        .{ .face_index = 5, .display = .swap },
        .{ .face_index = 5, .display = .fallback },
    }));
    try std.testing.expectEqual(FacePhase.loading, coordinator.phase(30, 4).?);

    try coordinator.begin(31, 200, &.{.{ .face_index = 6, .display = .optional }});
    try std.testing.expect(!coordinator.complete(30, 4, .ready, 201));
    try std.testing.expect(!coordinator.advance(30, 1_000));
    try std.testing.expect(coordinator.complete(31, 6, .ready, 250));
    const revision = coordinator.takeRevision().?;
    try std.testing.expectEqual(@as(u64, 1), revision.serial);
}

test "logical time never moves backwards and empty or failed epochs do not repaint" {
    var coordinator = Coordinator{};
    try coordinator.begin(40, 100, &.{.{ .face_index = 0, .display = .optional }});
    try std.testing.expect(!coordinator.advance(40, 150));
    try std.testing.expect(coordinator.complete(40, 0, .ready, 120));
    try std.testing.expect(coordinator.takeRevision() != null);

    try coordinator.begin(41, 200, &.{.{ .face_index = 0, .display = .block }});
    try std.testing.expect(coordinator.complete(41, 0, .failed, 300));
    try std.testing.expect(coordinator.settled(41));
    try std.testing.expect(coordinator.takeRevision() == null);

    try coordinator.begin(42, 400, &.{});
    try std.testing.expect(coordinator.settled(42));
    try std.testing.expect(coordinator.takeRevision() == null);
}

test "retained faces settle new demand epochs without redundant revisions" {
    var coordinator = Coordinator{};
    try coordinator.begin(50, 0, &.{.{ .face_index = 8, .display = .swap }});
    try std.testing.expect(coordinator.complete(50, 8, .ready, 10));
    try std.testing.expect(coordinator.takeRevision() != null);

    try coordinator.begin(51, 20, &.{.{ .face_index = 8, .display = .optional }});
    try std.testing.expect(coordinator.complete(51, 8, .retained, 10_000));
    try std.testing.expect(coordinator.settled(51));
    try std.testing.expectEqual(FacePhase.ready, coordinator.phase(51, 8).?);
    try std.testing.expect(coordinator.takeRevision() == null);

    try coordinator.begin(52, 20_000, &.{
        .{ .face_index = 8, .display = .swap },
        .{ .face_index = 9, .display = .swap },
    });
    try std.testing.expect(coordinator.complete(52, 8, .retained, 20_001));
    try std.testing.expect(coordinator.complete(52, 9, .ready, 20_002));
    const revision = coordinator.takeRevision().?;
    try std.testing.expectEqual(@as(u16, 1), revision.activated_faces);
    try std.testing.expect(coordinator.takeRevision() == null);
}
