// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Worker-owned VCN1 encode session. Caller BOs remain borrowed through input
//! retirement; only commands, feedback and compressed bytes are CPU mapped.
const std = @import("std");
const r = @import("r4os");
const a = r.abi;
const gpu = @import("gpu_resources");
const Budget = @import("native_allocation").Budget;
pub fn Implementation(comptime ff: type) type {
    return struct {
        pub const Error = gpu.Error || error{ Encode, MissingStatus, Bitstream, Capacity, Bounds };
        pub const Packet = struct { bytes: usize, key: bool };
        const scratch_bytes = 65536;
        fn result(value: c_int) Error!void {
            return switch (value) {
                0 => {},
                -1 => error.Invalid,
                -2 => error.Unsupported,
                else => error.Internal,
            };
        }
        pub const Config = struct {
            sequence: ff.struct_r4amd_encode_config,
            packet_bytes: u32,
            pub fn from(value: anytype) Error!Config {
                if (value.query.bit_depth != 8 or value.query.chroma != 1 or value.color.bit_depth != 8 or
                    value.color.flags != 0 or value.color.primaries != 1 or value.color.matrix != 1 or value.color.range != 2 or
                    (value.color.transfer != 1 and value.color.transfer != 13) or
                    (value.color.chroma_location != 0 and value.color.chroma_location != 1)) return error.Unsupported;
                if (value.max_packet_bytes < 8192 or value.max_packet_bytes > 8 * 1024 * 1024 or
                    value.rate.target_bps > std.math.maxInt(u32) or value.rate.peak_bps > std.math.maxInt(u32) or
                    value.rate.buffer_bits > std.math.maxInt(u32)) return error.Invalid;
                const sequence: ff.struct_r4amd_encode_config = .{ .codec = value.query.codec, .profile = value.query.profile, .width = value.width, .height = value.height, .fps_num = value.fps_num, .fps_den = value.fps_den, .transfer = value.color.transfer, .rate = value.rate.mode, .qp = value.rate.qp, .min_qp = value.rate.min_qp, .max_qp = value.rate.max_qp, .target_bps = @intCast(value.rate.target_bps), .peak_bps = @intCast(value.rate.peak_bps), .buffer_bits = @intCast(value.rate.buffer_bits), .packet_bytes = @intCast(value.max_packet_bytes - ff.R4AMD_ENCODE_HEADER_BYTES), .gop = value.gop_frames };
                var requirements: ff.struct_r4amd_encode_requirements = undefined;
                try result(ff.r4amd_encode_plan(&sequence, &requirements));
                if (ff.r4amd_encode_scratch_bytes() > scratch_bytes) return error.Internal;
                return .{ .sequence = sequence, .packet_bytes = @intCast(value.max_packet_bytes) };
            }
        };
        const Work = enum { commands, session, dpb, bitstream, feedback };
        const kinds = std.enums.values(Work);
        pub const Backend = struct {
            ctx: gpu.Context,
            config: Config,
            work: [kinds.len]gpu.Resource = @splat(.{}),
            input: gpu.Resource = .{},
            scratch: [scratch_bytes]u8 align(8) = undefined,
            headers: [ff.R4AMD_ENCODE_HEADER_BYTES]u8 = undefined,
            header_bytes: u32 = 0,
            serial: u32 = 0,
            frame_num: u32 = 0,
            poc: u32 = 0,
            since_idr: u32 = 0,
            idr_id: u16 = 0,
            reference: ?u32 = null,
            started: bool = false,
            opened: bool = false,
            failed: bool = false,
            closing: bool = false,
            close_inflight: bool = false,
            close_ack: bool = false,
            closed: bool = false,

            pub fn init(base: r.program.Context, device: gpu.Device, budget: *Budget, clock: gpu.Clock, config: Config) Backend {
                return .{ .ctx = .{ .base = base, .device = device, .budget = budget, .clock = clock }, .config = config };
            }
            fn resource(self: *Backend, kind: Work) *gpu.Resource {
                return &self.work[@intFromEnum(kind)];
            }
            fn next(self: *Backend) Error!u32 {
                // Reserve a final task identity for close even after the last frame.
                if (self.serial == std.math.maxInt(u32) or (!self.closing and self.serial == std.math.maxInt(u32) - 1)) return error.Bounds;
                self.serial += 1;
                return self.serial;
            }
            fn job(self: *Backend) Error!ff.struct_r4amd_encode_job {
                return .{ .session = self.resource(.session).address, .dpb = self.resource(.dpb).address, .bitstream = self.resource(.bitstream).address, .feedback = self.resource(.feedback).address, .serial = try self.next() };
            }
            fn commands(self: *Backend, value: ff.struct_r4amd_encode_job, operation: u32) Error!u32 {
                const output: [*]u32 = @ptrCast(@alignCast((try self.resource(.commands).mappedBytes()).ptr));
                var words: u32 = 0;
                try result(ff.r4amd_encode_commands(&self.scratch, &self.config.sequence, &value, operation, output, &words));
                if (words == 0 or words > ff.R4AMD_ENCODE_COMMAND_WORDS or words % 16 != 0) return error.Internal;
                return words * 4;
            }
            fn open(self: *Backend) Error!void {
                if (self.started) return;
                self.started = true;
                var req: ff.struct_r4amd_encode_requirements = undefined;
                try result(ff.r4amd_encode_plan(&self.config.sequence, &req));
                try result(ff.r4amd_encode_headers(&self.scratch, &self.config.sequence, &self.headers, &self.header_bytes));
                const sizes = [_]u32{ ff.R4AMD_ENCODE_COMMAND_WORDS * 4, ff.R4AMD_ENCODE_SESSION_BYTES, req.dpb_bytes, self.config.sequence.packet_bytes, 4096 };
                for (&self.work, kinds, sizes) |*bo, kind, bytes| {
                    if (kind == .dpb or kind == .session) try bo.video(&self.ctx, bytes) else try bo.system(&self.ctx, bytes);
                }
                const count = try self.commands(try self.job(), 0);
                self.ctx.submit(self.resource(.commands), count, &.{.{ .resource = self.resource(.session), .write = true }}) catch |err| {
                    // Context poisons every error after acceptance, including a
                    // terminal error that has already consumed its fence. Before
                    // acceptance no firmware session can have been created.
                    self.opened = self.ctx.poisoned or self.ctx.fence.timeline != 0;
                    return err;
                };
                self.opened = true;
            }
            pub fn encode(self: *Backend, input: anytype, force: bool, output: []u8, until: u64) Error!Packet {
                if (self.closed or self.failed or self.closing) return error.Stale;
                try input.ready(&.{ .base = self.ctx.base });
                self.ctx.until_ns = until;
                errdefer self.failed = true;
                if (input.frame.plane_count != 2 or output.len < self.config.packet_bytes) return error.Unsupported;
                const y = try input.devicePlane(0);
                const uv = try input.devicePlane(1);
                if (!std.meta.eql(y.backing, uv.backing) or y.descriptor.modifier != 0 or y.pitch != uv.pitch or
                    y.pitch > std.math.maxInt(u32) or uv.offset <= y.offset or uv.offset - y.offset > std.math.maxInt(u32) or
                    y.offset >= y.descriptor.byte_length or y.descriptor.byte_length - y.offset > std.math.maxInt(u32)) return error.Unsupported;
                try self.open();
                try self.input.borrow(&self.ctx, y.backing);
                const key = force or self.reference == null or self.since_idr >= self.config.sequence.gop or self.frame_num >= 65535 or self.poc >= 65534;
                const target: u32 = if (self.reference) |last| last ^ 1 else 0;
                var value = try self.job();
                value.input = self.input.address + y.offset;
                value.input_pitch = @intCast(y.pitch);
                value.input_chroma = @intCast(uv.offset - y.offset);
                value.input_bytes = @intCast(y.descriptor.byte_length - y.offset);
                value.key = @intFromBool(key);
                value.reference = self.reference orelse 0;
                value.reconstructed = target;
                value.frame_num = self.frame_num;
                value.poc = self.poc;
                value.idr_id = self.idr_id;
                const count = try self.commands(value, 1);
                // No previous ready flag/extent survives into the next task. The native
                // fence must retire before the original firmware feedback is consumed.
                @memset((try self.resource(.feedback).mappedBytes())[0..40], 0xff);
                try self.ctx.submit(self.resource(.commands), count, &.{
                    .{ .resource = self.resource(.session), .write = true },   .{ .resource = self.resource(.dpb), .write = true },
                    .{ .resource = self.resource(.bitstream), .write = true }, .{ .resource = self.resource(.feedback), .write = true },
                    .{ .resource = &self.input, .write = false },
                });
                const status = try self.resource(.feedback).mappedBytes();
                const ready = word(status, 1);
                const offset = word(status, 5);
                const end = word(status, 6);
                const start = word(status, 8);
                if (ready == std.math.maxInt(u32) or offset == std.math.maxInt(u32) or end == std.math.maxInt(u32) or start == std.math.maxInt(u32)) return error.MissingStatus;
                if (ready != 1 or offset != 0 or start != 0 or end <= start or end - start > self.config.sequence.packet_bytes) return error.Encode;
                const encoded = (try self.resource(.bitstream).mappedBytes())[offset..][0 .. end - start];
                try checkBitstream(encoded, self.config.sequence.codec, key);
                const prefix: usize = if (key) self.header_bytes else 0;
                if (encoded.len > output.len - prefix) return error.Capacity;
                @memcpy(output[0..prefix], self.headers[0..prefix]);
                @memcpy(output[prefix..][0..encoded.len], encoded);
                self.reference = target;
                const poc_step: u32 = if (self.config.sequence.codec == 1) 2 else 1;
                self.frame_num = if (key) 1 else self.frame_num + 1;
                self.poc = if (key) poc_step else self.poc + poc_step;
                if (key) {
                    self.since_idr = 1;
                    self.idr_id +%= 1;
                } else self.since_idr += 1;
                return .{ .bytes = prefix + encoded.len, .key = key };
            }
            pub fn retireInput(self: *Backend) Error!void {
                if (self.failed) return self.close();
                try self.input.close();
            }
            pub fn reset(self: *Backend) Error!void {
                if (self.failed or self.closed or self.closing) return error.Stale;
                if (self.ctx.fence.timeline != 0 or self.input.owner != null) return error.Busy;
                self.reference = null;
                self.frame_num = 0;
                self.poc = 0;
                self.since_idr = 0;
            }
            pub fn close(self: *Backend) Error!void {
                if (self.closed) return;
                self.closing = true;
                self.failed = true;
                if (self.close_inflight and self.ctx.fence.timeline != 0) {
                    var state: a.GfxFenceStatus = .{};
                    const q: r.gfx_queue.Context = .{ .base = self.ctx.base };
                    if (q.query(&self.ctx.fence, &state) == 1 and state.version == 1 and state.size >= @sizeOf(a.GfxFenceStatus) and
                        std.meta.eql(state.fence, self.ctx.fence) and state.phase == a.gfx_queue_phase_terminal and state.flags == 0)
                    {
                        self.close_ack = state.result == a.gfx_queue_result_complete;
                        self.close_inflight = false;
                    }
                }
                try self.ctx.close();
                if (self.opened and !self.close_ack) {
                    const current = gpu.Device.queryProvider(self.ctx.base, self.ctx.device.binding.adapter_id, .encode, .amd) catch return error.Busy;
                    if (!std.meta.eql(current.binding, self.ctx.device.binding) or current.memory_generation != self.ctx.device.memory_generation) {
                        // A new device epoch, together with the old queue retirement,
                        // confirms that the old firmware session can no longer run.
                        self.close_ack = true;
                    } else {
                        self.ctx.poisoned = false;
                        self.ctx.until_ns = 0;
                        const bytes = try self.commands(try self.job(), 2);
                        self.ctx.submit(self.resource(.commands), bytes, &.{.{ .resource = self.resource(.session), .write = true }}) catch |err| {
                            self.close_inflight = self.ctx.fence.timeline != 0;
                            return err;
                        };
                        self.close_ack = true;
                    }
                }
                try self.ctx.close();
                var failure: ?Error = null;
                self.input.close() catch |err| {
                    failure = err;
                };
                for (&self.work) |*bo| bo.close() catch |err| {
                    failure = err;
                };
                if (failure) |err| return err;
                self.closed = true;
            }
        };
        fn word(bytes: []const u8, index: usize) u32 {
            return std.mem.readInt(u32, bytes[index * 4 ..][0..4], .little);
        }
        /// Validate the returned Annex-B envelope, not the compressed pixel syntax.
        /// Firmware only emits IDR/P slices, optional SEI/AUD/filler; config is host-owned.
        pub fn checkBitstream(bytes: []const u8, codec: u32, key: bool) Error!void {
            if (bytes.len < 5) return error.Bitstream;
            var at: usize = 0;
            var slices: u32 = 0;
            while (at < bytes.len) {
                var prefix: usize = 0;
                if (bytes.len - at >= 4 and std.mem.eql(u8, bytes[at..][0..4], &.{ 0, 0, 0, 1 })) prefix = 4 else if (bytes.len - at >= 3 and std.mem.eql(u8, bytes[at..][0..3], &.{ 0, 0, 1 })) prefix = 3 else return error.Bitstream;
                at += prefix;
                if (at >= bytes.len or bytes[at] & 0x80 != 0) return error.Bitstream;
                if (codec == 1) {
                    const kind = bytes[at] & 31;
                    if (kind == 1 or kind == 5) {
                        if ((kind == 5) != key) return error.Bitstream;
                        slices += 1;
                    } else if (kind != 6 and kind != 9 and kind != 12) return error.Bitstream;
                } else {
                    if (bytes.len - at < 3 or bytes[at + 1] != 1 or bytes[at] & 1 != 0) return error.Bitstream;
                    const kind = bytes[at] >> 1;
                    if (kind == 1 or kind == 19) {
                        if ((kind == 19) != key) return error.Bitstream;
                        slices += 1;
                    } else if (kind != 35 and kind != 38 and kind != 39 and kind != 40) return error.Bitstream;
                }
                at += if (codec == 1) @as(usize, 1) else 2;
                const start = at;
                while (at < bytes.len) : (at += 1) {
                    if (bytes.len - at >= 3 and bytes[at] == 0 and bytes[at + 1] == 0 and
                        (bytes[at + 2] == 1 or (bytes.len - at >= 4 and bytes[at + 2] == 0 and bytes[at + 3] == 1))) break;
                }
                if (at == start) return error.Bitstream;
            }
            if (slices == 0) return error.Bitstream;
        }
    };
}
