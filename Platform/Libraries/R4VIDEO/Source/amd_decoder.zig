// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const gpu = @import("gpu_resources");
const v = @import("r4amd_decode");
// One VCN owner for resolved FFmpeg pictures, canonical image leases and DPB.
// The historical nvdec callback names are private and provider independent.
pub fn Implementation(comptime ff: type) type {
    return struct {
        const Self = @This();
        const State = enum { empty, allocated, decoding, complete, aborted, released };
        const Image = struct { state: State = .empty, resource: gpu.Resource = .{}, sequence: v.Sequence = undefined, epoch: u64 = 0 };
        const Kind = enum { embedded, session, dpb, bitstream, commands };
        const kinds = std.enums.values(Kind);
        ctx: gpu.Context,
        images: [48]Image = @splat(.{}),
        work: [kinds.len]gpu.Resource = @splat(.{}),
        // VCN1 tier 0 uses one contiguous internal DPB, with independent native
        // NV12 output BOs. Reusing an unreferenced DPB slot never alters a lease.
        slots: [v.max_slots]?*Image = @splat(null),
        references: [v.max_refs]v.Reference = undefined,
        active: ?*Image = null,
        sequence: ?v.Sequence = null,
        picture: v.Picture = undefined,
        extra: [4096]u8 align(8) = @splat(0),
        extra_bytes: u32 = 0,
        current_slot: u32 = 0,
        reference_slots: [16]u32 = @splat(0),
        reference_count: u32 = 0,
        embedded: [ff.R4AMD_VCN_EMBEDDED]u8 align(8) = @splat(0),
        stream: v.AccessUnit = .{ .storage = &.{} },
        epoch: u64 = 0,
        serial: u32 = 0,
        failed: bool = false,
        closing: bool = false,
        pub fn ops(self: *Self) ff.struct_r4video_nvdec_ops {
            return .{ .owner = self, .allocate = @ptrCast(&allocate), .begin = @ptrCast(&begin), .slice = @ptrCast(&slice), .end = @ptrCast(&end), .abort = @ptrCast(&abort), .release = @ptrCast(&release) };
        }
        fn reject(self: *Self, err: anyerror) c_int {
            self.failed = true;
            return switch (err) {
                error.NoMemory => -4,
                error.Busy => -3,
                error.Stale, error.Timeout => -7,
                error.Unsupported => -2,
                else => -6,
            };
        }
        fn convert(s: ff.struct_r4video_nvdec_sequence) v.Sequence {
            return .{ .codec = if (s.codec == 0) 1 else s.codec, .depth = if (s.bit_depth == 0) 8 else s.bit_depth, .width = if (s.width == 0) s.width_mbs * 16 else s.width, .height = if (s.height == 0) s.height_mbs * 16 else s.height, .profile = s.profile, .level = s.level, .width_mbs = s.width_mbs, .height_mbs = s.height_mbs, .max_refs = s.max_refs, .log2_frame_num = s.log2_frame_num, .poc_type = s.poc_type, .log2_poc_lsb = s.log2_poc_lsb, .delta_poc_always_zero = s.delta_poc_always_zero != 0, .direct_8x8 = s.direct_8x8 != 0, .gaps_allowed = s.gaps_allowed != 0 };
        }
        fn sameStorage(a: v.Sequence, b: v.Sequence) bool {
            return a.codec == b.codec and a.depth == b.depth and a.width == b.width and a.height == b.height and a.max_refs == b.max_refs;
        }
        fn nativeSequence(s: v.Sequence) ff.struct_r4amd_vcn_sequence {
            return .{ .codec = s.codec, .profile = s.profile, .level = s.level, .width = s.width, .height = s.height, .depth = s.depth, .refs = s.max_refs };
        }
        fn check(rc: c_int) !void {
            if (rc != 0) return if (rc == -2) error.Unsupported else error.Invalid;
        }
        fn requirements(s: v.Sequence) !v.Requirements {
            if (s.codec == 1) return v.requirements(s);
            var req: ff.struct_r4amd_vcn_requirements = undefined;
            try check(ff.r4amd_vcn_plan(&nativeSequence(s), &req));
            return .{ .dpb = req.dpb, .context = req.context, .session = req.session, .pitch = req.pitch, .height = req.height };
        }
        fn commands(self: *Self, image: ?*Image, s: v.Sequence, creating: bool) ![64]u32 {
            if (s.codec == 1) return v.commands(s, self.buffers(image), creating);
            const req = try requirements(s);
            var words: [64]u32 = @splat(0x80000000);
            var at: usize = 0;
            emit(&words, &at, 5, self.span(.session).address);
            emit(&words, &at, 0, self.span(.embedded).address);
            if (!creating) {
                emit(&words, &at, 1, self.span(.dpb).address);
                if (req.context != 0) emit(&words, &at, 0x206, self.span(.session).address + v.session_context_bytes);
                if (s.codec == 2 or s.codec == 3) emit(&words, &at, if (s.codec == 2) 0x204 else 4, self.span(.embedded).address + ff.R4AMD_VCN_ITS);
                emit(&words, &at, 3, self.span(.embedded).address + ff.R4AMD_VCN_FEEDBACK);
                emit(&words, &at, 0x100, self.span(.bitstream).address);
                emit(&words, &at, 2, image.?.resource.address);
                words[at] = 0x20718 / 4;
                words[at + 1] = 1;
            }
            return words;
        }
        fn emit(words: []u32, at: *usize, cmd: u32, va: u64) void {
            @memcpy(words[at.*..][0..6], &[_]u32{ 0x20710 / 4, @truncate(va), 0x20714 / 4, @truncate(va >> 32), 0x2070c / 4, cmd << 1 });
            at.* += 6;
        }
        fn find(self: *Self, ptr: ?*anyopaque) ?*Image {
            for (&self.images) |*i| if (ptr == @as(*anyopaque, @ptrCast(i)) and i.state != .empty and i.state != .released) return i;
            return null;
        }
        fn resource(self: *Self, kind: Kind) *gpu.Resource {
            return &self.work[@intFromEnum(kind)];
        }
        fn span(self: *Self, kind: Kind) v.Span {
            const b = self.resource(kind);
            return .{ .address = b.address, .bytes = b.descriptor.byte_length };
        }
        fn buffers(self: *Self, image: ?*Image) v.Buffers {
            return .{ .embedded = self.span(.embedded), .session = self.span(.session), .dpb = self.span(.dpb), .bitstream = self.span(.bitstream), .target = if (image) |i| .{ .address = i.resource.address, .bytes = i.resource.descriptor.byte_length } else .{ .address = 0, .bytes = 0 } };
        }
        fn target(image: *const Image) v.Target {
            const d = image.resource.descriptor;
            return .{ .pitch = @intCast(d.plane_pitches[0]), .chroma_offset = @intCast(d.plane_offsets[1]), .bytes = @intCast(d.byte_length) };
        }
        fn upload(self: *Self, kind: Kind, data: []const u8) !void {
            const b = try self.resource(kind).mappedBytes();
            if (b.len < data.len) return error.Invalid;
            @memcpy(b[0..data.len], data);
        }
        fn handle(self: *Self) u32 {
            // Canonical BO IDs are globally unique while live. The external
            // firmware session and its BO survive every queued use/retirement.
            return self.resource(.session).backing.buffer.id;
        }
        fn allocate(self: *Self, input: *const ff.struct_r4video_nvdec_sequence, out: *?*anyopaque) callconv(.c) c_int {
            out.* = null;
            if (self.failed or self.closing) return -7;
            self.reap() catch |err| if (err != error.Busy) return self.reject(err);
            const seq = convert(input.*);
            _ = requirements(seq) catch |err| return self.reject(err);
            for (&self.images) |*i| if (i.state == .empty) {
                i.state = .allocated;
                i.sequence = seq;
                out.* = i;
                i.resource.yuv(&self.ctx, seq.width, seq.height, seq.depth) catch |err| return self.reject(err);
                return 0;
            };
            return self.reject(error.NoMemory);
        }
        fn setup(self: *Self, image: *Image, refs: u32) !void {
            const s = image.sequence;
            if (self.sequence) |old| if (sameStorage(old, s)) return;
            if (refs != 0 or self.epoch == std.math.maxInt(u64)) return error.Invalid;
            self.slots = @splat(null);
            const until = try self.ctx.deadline();
            for (&self.work) |*b| try b.closeUntil(until);
            const req = try requirements(s);
            if (s.codec == 6) {
                if (self.ctx.device.engine != .jpeg) return error.Unsupported;
                try self.resource(.bitstream).system(&self.ctx, v.max_stream);
                try self.resource(.commands).system(&self.ctx, 512);
                self.epoch += 1;
                self.sequence = s;
                return;
            }
            try self.resource(.embedded).system(&self.ctx, if (s.codec == 1) v.embedded_bytes else ff.R4AMD_VCN_EMBEDDED);
            try self.resource(.session).system(&self.ctx, req.session);
            try self.resource(.dpb).video(&self.ctx, req.dpb);
            try self.resource(.bitstream).system(&self.ctx, v.max_stream);
            try self.resource(.commands).system(&self.ctx, 256);
            if (s.codec == 1) {
                try self.upload(.embedded, &try v.create(s, self.handle()));
            } else {
                const session = try self.resource(.session).mappedBytes();
                try check(ff.r4amd_vcn_context(&nativeSequence(s), session.ptr, @intCast(session.len)));
                try check(ff.r4amd_vcn_create(&nativeSequence(s), self.handle(), &self.embedded));
                try self.upload(.embedded, &self.embedded);
            }
            const words = try self.commands(null, s, true);
            try self.upload(.commands, std.mem.sliceAsBytes(&words));
            try self.ctx.submit(self.resource(.commands), 256, &.{ .{ .resource = self.resource(.embedded), .write = false }, .{ .resource = self.resource(.session), .write = true } });
            self.epoch += 1;
            self.sequence = s;
        }
        fn begin(self: *Self, ptr: ?*anyopaque, input: *const ff.struct_r4video_nvdec_picture) callconv(.c) c_int {
            const image = self.find(ptr) orelse return self.reject(error.Invalid);
            const p = input.*;
            if (self.failed or self.closing or self.active != null or image.state != .allocated or
                !std.meta.eql(convert(p.sequence), image.sequence) or p.reference_count > p.sequence.max_refs or p.reference_count > 16) return self.reject(error.Invalid);
            var refs: [16]*Image = undefined;
            for (p.references[0..p.reference_count], 0..) |ref, i| {
                const other = self.find(ref.image) orelse return self.reject(error.Invalid);
                if (other == image or other.state != .complete or other.epoch != self.epoch or !sameStorage(other.sequence, image.sequence)) return self.reject(error.Invalid);
                for (refs[0..i]) |prior| if (prior == other) return self.reject(error.Invalid);
                refs[i] = other;
            }
            self.setup(image, p.reference_count) catch |err| return self.reject(err);
            for (&self.slots) |*slot| if (slot.*) |held| {
                var used = false;
                for (refs[0..p.reference_count]) |ref| if (ref == held) {
                    used = true;
                    break;
                };
                if (!used) slot.* = null;
            };
            for (refs[0..p.reference_count], 0..) |other, i| {
                var found: ?u32 = null;
                for (self.slots[0 .. p.sequence.max_refs + 1], 0..) |slot, j| if (slot == other) {
                    found = @intCast(j);
                    break;
                };
                const r = p.references[i];
                self.references[i] = .{ .slot = found orelse return self.reject(error.Invalid), .frame_num = r.frame_index, .poc = r.poc, .long_term = r.long_term != 0 };
            }
            var free: ?u32 = null;
            for (self.slots[0 .. p.sequence.max_refs + 1], 0..) |slot, i| if (slot == null) {
                free = @intCast(i);
                break;
            };
            const slot = free orelse return self.reject(error.NoMemory);
            self.current_slot = slot;
            self.reference_count = p.reference_count;
            for (self.references[0..p.reference_count], 0..) |ref, i| self.reference_slots[i] = ref.slot;
            if (image.sequence.codec != 1) {
                if (p.codec_parameters == null or p.codec_parameter_bytes == 0 or p.codec_parameter_bytes > self.extra.len) return self.reject(error.Invalid);
                self.extra_bytes = p.codec_parameter_bytes;
                @memcpy(self.extra[0..self.extra_bytes], @as([*]const u8, @ptrCast(p.codec_parameters))[0..self.extra_bytes]);
            }
            self.picture = .{ .sequence = image.sequence, .slot = slot, .frame_num = p.frame_num, .poc = p.poc, .references = self.references[0..p.reference_count], .parameters = .{ .entropy_coding = p.entropy_coding != 0, .bottom_field_poc_present = p.bottom_field_poc_present != 0, .l0_default_minus1 = p.l0_default_minus1, .l1_default_minus1 = p.l1_default_minus1, .deblocking_control = p.deblocking_control != 0, .redundant_pic_cnt = p.redundant_pic_cnt != 0, .transform_8x8 = p.transform_8x8 != 0, .weighted_pred = p.weighted_pred != 0, .constrained_intra_pred = p.constrained_intra_pred != 0, .weighted_bipred = p.weighted_bipred, .initial_qp_minus26 = p.initial_qp_minus26, .initial_qs_minus26 = p.initial_qs_minus26, .chroma_qp_offset = p.chroma_qp_offset, .second_chroma_qp_offset = p.second_chroma_qp_offset, .scaling4 = @bitCast(p.scaling4), .scaling8 = @bitCast(p.scaling8) } };
            if (image.sequence.codec == 1) _ = v.decode(self.picture, target(image), self.handle(), 1, 128) catch |err| return self.reject(err);
            self.stream = .{ .codec = image.sequence.codec, .storage = self.resource(.bitstream).mappedBytes() catch |err| return self.reject(err) };
            self.slots[slot] = image;
            self.active = image;
            image.epoch = self.epoch;
            image.state = .decoding;
            return 0;
        }
        fn slice(self: *Self, ptr: ?*anyopaque, data: [*]const u8, bytes: u32) callconv(.c) c_int {
            const image = self.find(ptr) orelse return self.reject(error.Invalid);
            if (self.failed or self.active != image or image.state != .decoding) return self.reject(error.Invalid);
            self.stream.append(data[0..bytes]) catch |err| return self.reject(err);
            return 0;
        }
        fn end(self: *Self, ptr: ?*anyopaque) callconv(.c) c_int {
            const image = self.find(ptr) orelse return self.reject(error.Invalid);
            if (self.failed or self.active != image or image.state != .decoding) return self.reject(error.Invalid);
            self.execute(image) catch |err| return self.reject(err);
            self.active = null;
            image.state = .complete;
            return 0;
        }
        fn execute(self: *Self, image: *Image) !void {
            const bytes = try self.stream.finish();
            if (self.serial == std.math.maxInt(u32)) return error.Invalid;
            self.serial += 1;
            if (image.sequence.codec == 6) {
                const t = target(image);
                const native_target: ff.struct_r4amd_vcn_target = .{ .pitch = t.pitch, .chroma_offset = t.chroma_offset, .bytes = t.bytes };
                var jpeg_words: [128]u32 = undefined;
                try check(ff.r4amd_vcn_jpeg(&nativeSequence(image.sequence), &native_target,
                    self.span(.bitstream).address, bytes, image.resource.address, &jpeg_words));
                try self.resource(.commands).resumeCpu();
                try self.upload(.commands, std.mem.sliceAsBytes(&jpeg_words));
                try self.resource(.commands).suspendCpu();
                try self.ctx.submit(self.resource(.commands), 512, &.{
                    .{ .resource = self.resource(.bitstream), .write = false }, .{ .resource = &image.resource, .write = true } });
                return;
            }
            if (image.sequence.codec == 1) {
                try self.upload(.embedded, &try v.decode(self.picture, target(image), self.handle(), self.serial, bytes));
            } else {
                const t = target(image);
                const native_target: ff.struct_r4amd_vcn_target = .{ .pitch = t.pitch, .chroma_offset = t.chroma_offset, .bytes = t.bytes };
                try check(ff.r4amd_vcn_message(&nativeSequence(image.sequence), &native_target, &self.extra, self.extra_bytes, &self.reference_slots, self.reference_count, self.current_slot, self.handle(), self.serial, bytes, &self.embedded));
                try self.upload(.embedded, &self.embedded);
            }
            const words = try self.commands(image, image.sequence, false);
            try self.upload(.commands, std.mem.sliceAsBytes(&words));
            var loans: [6]gpu.Context.Loan = undefined;
            for (kinds, 0..) |kind, i| loans[i] = .{ .resource = self.resource(kind), .write = kind == .embedded or kind == .session or kind == .dpb };
            loans[5] = .{ .resource = &image.resource, .write = true };
            try self.ctx.submit(self.resource(.commands), 256, &loans);
            const mapped = try self.resource(.embedded).mappedBytes();
            const src: [*]const volatile u8 = @ptrCast(mapped.ptr + @as(usize, if (image.sequence.codec == 1) v.feedback_offset else ff.R4AMD_VCN_FEEDBACK));
            var status: [v.feedback_bytes]u8 = undefined;
            for (&status, 0..) |*b, i| b.* = src[i];
            try v.feedback(&status, self.serial);
        }
        fn abort(self: *Self, ptr: ?*anyopaque) callconv(.c) void {
            const image = self.find(ptr) orelse @trap();
            if (image.state == .complete) @trap();
            image.state = .aborted;
            if (self.active == image) self.active = null;
            self.failed = true;
        }
        fn release(self: *Self, ptr: ?*anyopaque) callconv(.c) void {
            const image = self.find(ptr) orelse @trap();
            if (image.state == .decoding or self.active == image) @trap();
            for (&self.slots) |*slot| if (slot.* == image) {
                slot.* = null;
            };
            image.state = .released;
        }
        pub fn describe(self: *Self, ptr: ?*anyopaque) ?*const gpu.Resource {
            const image = self.find(ptr) orelse return null;
            return if (image.state == .complete) &image.resource else null;
        }
        pub fn reap(self: *Self) !void {
            var pending = false;
            for (&self.images) |*i| if (i.state == .released) {
                i.resource.close() catch |err| {
                    if (err != error.Busy) return err;
                    pending = true;
                    continue;
                };
                i.* = .{};
            };
            if (pending) return error.Busy;
        }
        pub fn pendingRetirement(self: *const Self) bool {
            if (self.ctx.fence.timeline != 0 or self.ctx.queue.timeline != 0) return true;
            for (&self.images) |*i| if (i.state == .released) return true;
            for (&self.work) |*b| if (b.owner != null) return true;
            return false;
        }
        pub fn flush(self: *Self) void {
            std.debug.assert(self.active == null and !self.failed);
            self.slots = @splat(null);
            if (self.epoch == std.math.maxInt(u64)) self.failed = true else self.epoch += 1;
        }
        pub fn close(self: *Self) !void {
            self.closing = true;
            try self.ctx.close();
            try self.reap();
            var pending = false;
            for (&self.images) |*i| if (i.state != .empty) {
                pending = true;
            };
            // Mesa VCN external sessions have no destroy command. Only free the
            // session/DPB after the queue has acknowledged all resource loans.
            for (&self.work) |*b| b.close() catch |err| {
                if (err != error.Busy) return err;
                pending = true;
            };
            if (pending) return error.Busy;
        }
    };
}
