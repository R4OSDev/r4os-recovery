// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Native worker coordinator. Creation validates capabilities without issuing
//! GPU work; the first accepted input creates the stable preparation/session.
const std = @import("std");
const r = @import("r4os");
const gpu = @import("gpu_resources");
const enc = @import("r4nv_encode");
const encoder = @import("gpu_encoder");
const preparer = @import("gpu_input");
const Budget = @import("native_allocation").Budget;
pub const Error = encoder.Error || preparer.Error;
pub const Devices = struct {
    encode: gpu.Device,
    graphics: gpu.Device,
    pub fn query(base: r.program.Context, adapter: u32) Error!Devices {
        const encode = try gpu.Device.queryProvider(base, adapter, .encode, .nvidia);
        const graphics = try gpu.Device.queryProvider(base, adapter, .graphics, .nvidia);
        if (!std.meta.eql(encode.binding, graphics.binding) or encode.memory_generation != graphics.memory_generation) return error.Stale;
        return .{ .encode = encode, .graphics = graphics };
    }
};
pub const Config = struct {
    sequence: enc.Sequence,
    packet_bytes: u32,
    key_interval: u32,
    pub fn from(value: anytype) Error!Config {
        if (value.rate.qp > 51 or value.rate.min_qp > value.rate.qp or value.rate.max_qp < value.rate.qp or
            value.rate.max_qp > 51 or value.gop_frames == 0 or value.gop_frames > 65535) return error.Invalid;
        // CQP,8-bit,709 primaries/matrix, limited, default left chroma.
        // Captured sRGB retains its explicit CICP13 transfer in the SPS.
        if (value.rate.mode != 0 or value.rate.target_bps != 0 or value.rate.peak_bps != 0 or value.rate.buffer_bits != 0 or
            value.color.bit_depth != 8 or value.color.flags != 0 or value.color.primaries != 1 or
            (value.color.transfer != 1 and value.color.transfer != 13) or value.color.matrix != 1 or value.color.range != 2 or
            (value.color.chroma_location != 0 and value.color.chroma_location != 1)) return error.Unsupported;
        const sequence: enc.Sequence = .{ .width = value.width, .height = value.height, .qp = @intCast(value.rate.qp),
            .fps_num = value.fps_num, .fps_den = value.fps_den, .transfer = @intCast(value.color.transfer) };
        const headers = try enc.parameterSets(sequence);
        if (value.max_packet_bytes > enc.max_bitstream_bytes or value.max_packet_bytes < 4096 + headers.length) return error.Invalid;
        return .{ .sequence = sequence, .packet_bytes = @intCast(value.max_packet_bytes), .key_interval = value.gop_frames };
    }
};
pub const Backend = struct {
    session: encoder.Session,
    preparer: preparer.Preparer,
    config: Config,
    started: bool = false,
    failed: bool = false,
    closed: bool = false,
    pub fn init(base: r.program.Context, devices: Devices, budget: *Budget, clock: gpu.Clock, config: Config) Backend {
        return .{ .session = .{ .ctx = .{ .base = base, .device = devices.encode, .budget = budget, .clock = clock } },
            .preparer = .{ .ctx = .{ .base = base, .device = devices.graphics, .budget = budget, .clock = clock } }, .config = config };
    }
    pub fn encode(self: *Backend, input: anytype, force: bool, output: []u8, until: u64) Error!encoder.Packet {
        if (self.closed or self.failed) return error.Stale;
        try input.ready(&.{ .base = self.session.ctx.base });
        self.session.ctx.until_ns = until;
        self.preparer.ctx.until_ns = until;
        errdefer self.failed = true;
        if (!self.started) {
            self.started = true; // Partial allocations are now owned by close.
            try self.session.open(self.config.sequence, self.config.packet_bytes, self.config.key_interval);
            try self.preparer.open(&self.session);
        }
        const prepared = try self.preparer.prepare(input);
        return self.session.encodePrepared(prepared, force, output);
    }
    /// Must finish before the public Input is released or a completion/abort
    /// is acknowledged. A failed job retires both engines and all partial BOs.
    pub fn retireInput(self: *Backend) Error!void {
        if (self.failed) return self.close();
        if (self.started) try self.preparer.retireInput();
    }
    pub fn reset(self: *Backend) Error!void {
        if (self.failed or self.closed) return error.Stale;
        if (self.started) try self.session.reset();
    }
    pub fn close(self: *Backend) Error!void {
        if (self.closed) return;
        self.failed = true;
        if (self.started) {
            // Drain both queue owners before either alias/BO owner. Otherwise
            // a timed-out encode could retain the preparer's destination.
            var failure: ?Error = null;
            self.preparer.ctx.close() catch |err| { failure = err; };
            self.session.ctx.close() catch |err| { failure = err; };
            if (failure) |err| return err;
            try self.preparer.close();
            try self.session.close();
        }
        self.closed = true;
    }
};
