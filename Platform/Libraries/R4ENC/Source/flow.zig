// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
pub const limit = 16;
pub const Error = error{ Invalid, Busy, Stale, Closed, Failed, Overflow, Cancelled };
// Pure bookkeeping under the encoder owner. Resource operations stay in the
// worker: a slot may be freed only after its Input/engine mappings retire.
pub fn Flow(comptime c: type) type {
    return struct {
        const Self = @This();
        pub const InputState = enum { free, reserved, queued, active, retiring };
        pub const OutputState = enum { free, writing, ready, leased };
        pub const Claim = struct { input: usize, output: usize, force_idr: bool };
        const Input = struct { state: InputState = .free, serial: u64 = 0 };
        const Output = struct { state: OutputState = .free, serial: u64 = 0, token: u64 = 0, generation: u64 = 0 };
        inputs: [limit]Input = @splat(.{}),
        outputs: [limit]Output = @splat(.{}),
        input_limit: usize,
        output_limit: usize,
        active: ?Claim = null,
        phase: u32 = c.phase_open,
        generation: u64 = 1,
        pending: u64 = 0,
        completed: u64 = 0,
        operation: u32 = c.control_query,
        completed_operation: u32 = c.control_query,
        cancelled: u64 = 0,
        cancelled_operation: u32 = c.control_query,
        serial: u64 = 0,
        token: u64 = 0,
        accepted: u64 = 0,
        encoded: u64 = 0,
        skipped: u64 = 0,
        bytes: u64 = 0,
        last_error: i32 = c.ok,
        need_idr: bool = true,

        pub fn init(pending: usize, packets: usize) Error!Self {
            if (pending == 0 or pending > limit or packets == 0 or packets > limit) return error.Invalid;
            return .{ .input_limit = pending, .output_limit = packets };
        }
        pub fn reserve(self: *Self, generation: u64) Error!usize {
            if (generation != self.generation) return error.Stale;
            if (self.phase == c.phase_failed) return error.Failed;
            if (self.phase != c.phase_open) return error.Closed;
            if (self.serial == std.math.maxInt(u64)) return error.Overflow;
            for (self.inputs[0..self.input_limit], 0..) |*value, i| if (value.state == .free) {
                value.state = .reserved;
                return i;
            };
            return error.Busy;
        }
        pub fn commit(self: *Self, i: usize) void {
            std.debug.assert(i < self.input_limit and self.inputs[i].state == .reserved and self.phase == c.phase_open);
            self.serial += 1;
            self.accepted += 1;
            self.inputs[i] = .{ .state = .queued, .serial = self.serial };
        }
        // Failed admission still owns any partial BO imports/maps until the
        // worker cleans them. It contributes neither acceptance nor a receipt.
        pub fn reject(self: *Self, i: usize) void {
            std.debug.assert(i < self.input_limit and self.inputs[i].state == .reserved);
            self.inputs[i].state = .retiring;
        }
        pub fn discard(self: *Self, i: usize) void {
            std.debug.assert(i < self.input_limit and self.inputs[i].state != .free and self.inputs[i].state != .active);
            self.inputs[i] = .{};
        }
        pub fn take(self: *Self) ?Claim {
            if (self.active != null or (self.phase != c.phase_open and self.phase != c.phase_draining and self.phase != c.phase_failed)) return null;
            var oldest: ?usize = null;
            for (self.inputs[0..self.input_limit], 0..) |value, i| if (value.state == .queued) {
                if (oldest == null or value.serial < self.inputs[oldest.?].serial) oldest = i;
            };
            const i = oldest orelse return null;
            for (self.outputs[0..self.output_limit], 0..) |*value, o| if (value.state == .free) {
                self.inputs[i].state = .active;
                value.state = .writing;
                value.serial = self.inputs[i].serial;
                const claim: Claim = .{ .input = i, .output = o, .force_idr = self.need_idr };
                self.active = claim;
                return claim;
            };
            return null;
        }
        // Called only after source pixels/BO maps and native work are physically
        // released. Cancellation never shortens this prerequisite.
        pub fn finish(self: *Self, claim: Claim, count: u64, flags: u32, result: i32) void {
            std.debug.assert(self.active != null and std.meta.eql(self.active.?, claim));
            self.inputs[claim.input] = .{};
            self.active = null;
            const output = &self.outputs[claim.output];
            if (self.phase == c.phase_aborting or self.phase == c.phase_closing) {
                output.state = .free;
                return;
            }
            output.state = .ready;
            if (result < 0) {
                self.phase = c.phase_failed;
                self.last_error = result;
            } else if (flags & c.packet_skipped != 0) self.skipped +|= 1 else {
                self.encoded +|= 1;
                self.bytes +|= count;
                if (flags & c.packet_key != 0) self.need_idr = false;
            }
        }
        pub fn receive(self: *Self) Error!?usize {
            var oldest: ?usize = null;
            for (self.outputs[0..self.output_limit], 0..) |value, i| if (value.state == .ready) {
                if (oldest == null or value.serial < self.outputs[oldest.?].serial) oldest = i;
            };
            const i = oldest orelse return null;
            if (self.token == std.math.maxInt(u64)) return error.Overflow;
            self.token += 1;
            self.outputs[i].state = .leased;
            self.outputs[i].token = self.token;
            self.outputs[i].generation = self.generation;
            return i;
        }
        pub fn release(self: *Self, token: u64, generation: u64) Error!void {
            if (token == 0 or generation == 0) return error.Stale;
            for (self.outputs[0..self.output_limit]) |*value| {
                if (value.token != token or value.generation != generation) continue;
                if (value.state == .leased) value.state = .free;
                // Last exact returned identity remains retryable until this
                // slot delivers a new lease. A retry cannot free new writing.
                return;
            }
            return error.Stale;
        }
        pub fn request(self: *Self, id: u64, operation: u32) Error!void {
            if (id == 0 or operation < c.control_drain or operation > c.control_close) return error.Invalid;
            if (id == self.cancelled) return if (operation == self.cancelled_operation) error.Cancelled else error.Invalid;
            if (id == self.pending or id == self.completed) {
                if (operation != (if (id == self.pending) self.operation else self.completed_operation)) return error.Invalid;
                return;
            }
            if (id <= @max(self.completed, self.pending)) return error.Stale;
            if (self.phase == c.phase_closed or self.phase == c.phase_closing) return error.Closed;
            if (self.phase == c.phase_failed and operation != c.control_close) return error.Failed;
            if (self.pending != 0) {
                if (!((self.operation == c.control_drain and operation != c.control_drain) or
                    (self.operation == c.control_abort and operation == c.control_close))) return error.Busy;
                self.cancelled = self.pending;
                self.cancelled_operation = self.operation;
            }
            self.pending = id;
            self.operation = operation;
            self.phase = switch (operation) {
                c.control_drain => c.phase_draining,
                c.control_abort => c.phase_aborting,
                else => c.phase_closing,
            };
            if (operation != c.control_drain) {
                for (self.outputs[0..self.output_limit]) |*value| if (value.state == .ready) {
                    value.state = .free;
                };
            }
        }
        pub fn inputsEmpty(self: *const Self) bool {
            for (self.inputs[0..self.input_limit]) |value| if (value.state != .free) return false;
            return self.active == null;
        }
        pub fn leased(self: *const Self) u32 {
            var count: u32 = 0;
            for (self.outputs[0..self.output_limit]) |value| if (value.state == .leased) {
                count += 1;
            };
            return count;
        }
        pub fn progress(self: *Self, backend_idle: bool, backend_closed: bool) void {
            if (self.pending == 0 or !self.inputsEmpty() or !backend_idle) return;
            switch (self.phase) {
                c.phase_draining => self.phase = c.phase_drained,
                c.phase_aborting => {
                    if (self.generation == std.math.maxInt(u64)) {
                        self.phase = c.phase_failed;
                        self.last_error = c.error_internal;
                    } else {
                        self.generation += 1;
                        self.phase = c.phase_open;
                        self.need_idr = true;
                    }
                },
                c.phase_closing => {
                    if (!backend_closed or self.leased() != 0) return;
                    self.phase = c.phase_closed;
                },
                c.phase_failed => {},
                else => return,
            }
            self.completed = self.pending;
            self.completed_operation = self.operation;
            self.pending = 0;
        }
    };
}
