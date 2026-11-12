// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const gpu = @import("gpu_resources");
const v = @import("r4nv_video");

// Private FFmpeg callbacks, serialized by the decoder coordinator. FFmpeg owns
// one AVBuffer reference per Image; its DPB and received AVFrames share that
// reference. Received frames must remain retained until VIDEO_V1 consumer ACK.
pub fn Implementation(comptime ff: type) type {
    return struct {
        const Self = @This();
        const State = enum { empty, allocated, decoding, complete, aborted, released };
        const Image = struct {
            state: State = .empty,
            resource: gpu.Resource = .{},
            sequence: v.Sequence = undefined,
            layout: v.Layout = undefined,
            epoch: u64 = 0,
        };
        const Kind = enum { parameters, bitstream, slices, status, commands, coloc, history, mbhist };
        const kinds = std.enums.values(Kind);
        ctx: gpu.Context,
        // Up to 16 public leases, 16 DPB entries, the current picture and a
        // bounded margin for FFmpeg reorder/retirement. Coloc slots are separate.
        images: [48]Image = @splat(.{}),
        work: [kinds.len]gpu.Resource = @splat(.{}),
        coloc: [v.max_surfaces]?*Image = @splat(null),
        references: [v.max_references]v.Reference = undefined,
        active: ?*Image = null,
        sequence: ?v.Sequence = null,
        layout: v.Layout = undefined,
        picture: v.Picture = undefined,
        stream: v.AccessUnit = .{ .storage = &.{} },
        epoch: u64 = 0,
        picture_index: u32 = 0,
        failed: bool = false,
        closing: bool = false,

        pub fn ops(self: *Self) ff.struct_r4video_nvdec_ops {
            return .{ .owner = self, .allocate = @ptrCast(&allocate), .begin = @ptrCast(&begin),
                .slice = @ptrCast(&slice), .end = @ptrCast(&end), .abort = @ptrCast(&abort), .release = @ptrCast(&release) };
        }
        fn code(err: anyerror) c_int {
            return switch (err) {
                error.NoMemory => -4,
                error.Busy => -3,
                error.Stale, error.Timeout => -7,
                error.Unsupported => -2,
                else => -6,
            };
        }
        fn reject(self: *Self, err: anyerror) c_int {
            self.failed = true;
            return code(err);
        }
        fn convert(s: ff.struct_r4video_nvdec_sequence) v.Sequence {
            return .{ .profile = s.profile, .level = s.level, .width_mbs = s.width_mbs, .height_mbs = s.height_mbs,
                .max_refs = s.max_refs, .log2_frame_num = s.log2_frame_num, .poc_type = s.poc_type,
                .log2_poc_lsb = s.log2_poc_lsb, .delta_poc_always_zero = s.delta_poc_always_zero != 0, .direct_8x8 = s.direct_8x8 != 0 };
        }
        fn find(self: *Self, ptr: ?*anyopaque) ?*Image {
            for (&self.images) |*image| if (ptr == @as(*anyopaque, @ptrCast(image)) and image.state != .empty and image.state != .released) return image;
            return null;
        }
        fn resource(self: *Self, kind: Kind) *gpu.Resource {
            return &self.work[@intFromEnum(kind)];
        }
        fn sameStorage(left: v.Sequence, right: v.Sequence) bool {
            return left.width_mbs == right.width_mbs and left.height_mbs == right.height_mbs and left.max_refs == right.max_refs;
        }
        fn allocate(self: *Self, s: *const ff.struct_r4video_nvdec_sequence, output: *?*anyopaque) callconv(.c) c_int {
            output.* = null;
            if (self.failed or self.closing) return -7;
            self.reap() catch |err| if (err != error.Busy) return self.reject(err);
            const seq = convert(s.*);
            if (seq.width_mbs == 0 or seq.width_mbs > 256 or seq.height_mbs == 0 or seq.height_mbs > 256) return self.reject(error.Unsupported);
            const pitch = std.mem.alignForward(u32, seq.width_mbs * 16, 64);
            _ = v.requirements(seq, .{ .luma_pitch = pitch, .chroma_pitch = pitch, .log2_gobs = 1 }) catch |err| return self.reject(err);
            for (&self.images) |*image| if (image.state == .empty) {
                image.state = .allocated;
                image.sequence = seq;
                // Return the partial owner too. FFmpeg abort/release must keep
                // allocation/mapping requests reachable when setup fails.
                output.* = image;
                image.resource.nv12(&self.ctx, seq.width_mbs * 16, seq.height_mbs * 16) catch |err| return self.reject(err);
                const d = image.resource.descriptor;
                image.layout = .{ .luma_pitch = @intCast(d.plane_pitches[0]), .chroma_pitch = @intCast(d.plane_pitches[1]),
                    .log2_gobs = @intCast(d.modifier & 15) };
                _ = v.requirements(seq, image.layout) catch |err| return self.reject(err);
                return 0;
            };
            return self.reject(error.NoMemory);
        }
        fn setup(self: *Self, image: *Image, refs: u32) !void {
            if (self.sequence) |old| {
                if (sameStorage(old, image.sequence) and std.meta.eql(self.layout, image.layout)) return;
                // A new storage geometry starts with an empty DPB. Outstanding
                // consumer images keep their own BOs but need no coloc storage.
                if (refs != 0) return error.Unsupported;
                const until = try self.ctx.deadline();
                for (&self.work) |*buffer| try buffer.closeUntil(until);
                self.sequence = null;
                self.coloc = @splat(null);
            }
            if (self.epoch == std.math.maxInt(u64)) return error.Invalid;
            const req = try v.requirements(image.sequence, image.layout);
            const sizes = [_]u64{ v.picture_bytes, v.max_stream_bytes + 256, 1024, v.status_bytes,
                v.command_words * 4, req.coloc, req.history, req.mbhist };
            for (&self.work, sizes, kinds) |*buffer, bytes, kind| {
                if (@intFromEnum(kind) <= @intFromEnum(Kind.commands))
                    try buffer.system(&self.ctx, bytes)
                else
                    try buffer.video(&self.ctx, bytes);
            }
            self.epoch += 1;
            self.sequence = image.sequence;
            self.layout = image.layout;
        }
        fn begin(self: *Self, ptr: ?*anyopaque, input: *const ff.struct_r4video_nvdec_picture) callconv(.c) c_int {
            const image = self.find(ptr) orelse return self.reject(error.Invalid);
            const p = input.*;
            if (self.failed or self.closing or self.active != null or image.state != .allocated or
                !std.meta.eql(convert(p.sequence), image.sequence) or p.reference_count > p.sequence.max_refs or p.reference_count > 16)
                return self.reject(error.Invalid);
            var refs: [v.max_references]*Image = undefined;
            for (p.references[0..p.reference_count], 0..) |ref, i| {
                const other = self.find(ref.image) orelse return self.reject(error.Invalid);
                if (other == image or other.state != .complete or other.epoch != self.epoch or
                    !sameStorage(other.sequence, image.sequence) or !std.meta.eql(other.layout, image.layout)) return self.reject(error.Invalid);
                for (refs[0..i]) |earlier| if (earlier == other) return self.reject(error.Invalid);
                refs[i] = other;
            }
            self.setup(image, p.reference_count) catch |err| return self.reject(err);
            // Preserve each reference's physical coloc slot. Output leases may
            // outlive DPB membership; their old slot can then serve another BO.
            for (&self.coloc) |*entry| if (entry.*) |held| {
                var used = false;
                for (refs[0..p.reference_count]) |ref| if (ref == held) { used = true; break; };
                if (!used) entry.* = null;
            };
            for (refs[0..p.reference_count], 0..) |other, i| {
                var slot: ?u32 = null;
                for (self.coloc[0 .. p.sequence.max_refs + 1], 0..) |entry, j| if (entry == other) { slot = @intCast(j); break; };
                const ref = p.references[i];
                self.references[i] = .{ .surface = slot orelse return self.reject(error.Invalid),
                    .long_term = ref.long_term != 0, .frame_index = ref.frame_index, .poc = ref.poc };
            }
            var current: ?u32 = null;
            for (self.coloc[0 .. p.sequence.max_refs + 1], 0..) |entry, i| if (entry == null) { current = @intCast(i); break; };
            const slot = current orelse return self.reject(error.NoMemory);
            self.coloc[slot] = image;
            self.picture = .{ .sequence = image.sequence,
                .parameters = .{ .entropy_coding = p.entropy_coding != 0, .bottom_field_poc_present = p.bottom_field_poc_present != 0,
                    .l0_default_minus1 = p.l0_default_minus1, .l1_default_minus1 = p.l1_default_minus1,
                    .deblocking_control = p.deblocking_control != 0, .redundant_pic_cnt = p.redundant_pic_cnt != 0,
                    .transform_8x8 = p.transform_8x8 != 0, .weighted_pred = p.weighted_pred != 0,
                    .constrained_intra_pred = p.constrained_intra_pred != 0, .weighted_bipred = p.weighted_bipred,
                    .initial_qp_minus26 = p.initial_qp_minus26, .chroma_qp_offset = p.chroma_qp_offset,
                    .second_chroma_qp_offset = p.second_chroma_qp_offset, .scaling4 = @bitCast(p.scaling4), .scaling8 = @bitCast(p.scaling8) },
                .current_surface = slot, .frame_num = p.frame_num, .poc = p.poc, .is_reference = p.is_reference != 0,
                .references = self.references[0..p.reference_count], .bitstream_bytes = 1, .slices = 1 };
            _ = v.encodePicture(self.ctx.device.class, &self.picture, self.layout) catch |err| return self.reject(err);
            self.stream = .{ .storage = self.resource(.bitstream).mappedBytes() catch |err| return self.reject(err) };
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
        fn span(self: *Self, kind: Kind) v.Span {
            const buffer = self.resource(kind);
            return .{ .address = buffer.address, .bytes = buffer.descriptor.byte_length };
        }
        fn upload(self: *Self, kind: Kind, bytes: []const u8) !void {
            const target = try self.resource(kind).mappedBytes();
            if (target.len < bytes.len) return error.Invalid;
            @memcpy(target[0..bytes.len], bytes);
        }
        fn snapshotStatus(self: *Self) ![v.status_bytes]u8 {
            const mapped = try self.resource(.status).mappedBytes();
            var snapshot: [v.status_bytes]u8 = undefined;
            const status: [*]volatile const u8 = @ptrCast(mapped.ptr);
            for (&snapshot, 0..) |*byte, i| byte.* = status[i];
            return snapshot;
        }
        // Opt-in caller diagnostics only. Neither a snapshot nor a marker is
        // a completion receipt; keep the exact original submit/status errors.
        fn trace(self: *Self, stage: []const u8, known: ?*const [v.status_bytes]u8, failure: ?anyerror) void {
            const bundle = self.ctx.base.bundle orelse return;
            const sys = bundle.sys orelse return;
            if (sys.env_get == 0 or sys.write == 0) return;
            const get: @import("r4os").abi.R4SysFns.env_get = @ptrFromInt(sys.env_get);
            var option: [16]u8 = undefined;
            if (get("R4VIDEO_NVDEC_TRACE", &option, option.len) != 1 or option[0] != '1') return;
            const snapshot: ?[v.status_bytes]u8 = if (known) |value| value.* else self.snapshotStatus() catch null;
            const status_hex = if (snapshot) |value| std.fmt.bytesToHex(&value, .lower) else @as([2 * v.status_bytes]u8, @splat('?'));
            const write: @import("r4os").abi.R4SysFns.write = @ptrFromInt(sys.write);
            var text: [512]u8 = undefined;
            const line = std.fmt.bufPrint(&text,
                "R4VIDEO NVDEC stage={s} class={x} picture={d} profile={d} mbs={d}x{d} slot={d} references={d} queue={d} failure={s} status={s}\n",
                .{ stage, self.ctx.device.class, self.picture_index, self.picture.sequence.profile,
                    self.picture.sequence.width_mbs, self.picture.sequence.height_mbs,
                    self.picture.current_surface, self.picture.references.len, self.ctx.queue.timeline,
                    if (failure) |err| @errorName(err) else "none", status_hex }) catch return;
            _ = write(line.ptr, @intCast(line.len));
            if (std.mem.eql(u8, stage, "before-submit")) {
                self.tracePayload(write, .commands, v.command_words * @sizeOf(u32));
                self.tracePayload(write, .parameters, v.picture_bytes);
            }
        }
        fn tracePayload(self: *Self, write: @import("r4os").abi.R4SysFns.write, comptime kind: Kind, comptime bytes: usize) void {
            const mapped = self.resource(kind).mappedBytes() catch return;
            if (mapped.len < bytes) return;
            const snapshot: *const [bytes]u8 = @ptrCast(mapped.ptr);
            var text: [2 * bytes + 128]u8 = undefined;
            const line = std.fmt.bufPrint(&text, "R4VIDEO NVDEC payload={s} picture={d} bytes={d} hex={s}\n",
                .{ @tagName(kind), self.picture_index, bytes, std.fmt.bytesToHex(snapshot, .lower) }) catch return;
            _ = write(line.ptr, @intCast(line.len));
        }
        fn stepTrace(self: *Self) bool {
            const bundle = self.ctx.base.bundle orelse return false;
            const sys = bundle.sys orelse return false;
            if (sys.env_get == 0) return false;
            const get: @import("r4os").abi.R4SysFns.env_get = @ptrFromInt(sys.env_get);
            var option: [16]u8 = undefined;
            return get("R4VIDEO_NVDEC_STEP", &option, option.len) == 1 and option[0] == '1';
        }
        // Opt-in method isolation retains the exact original words and BO/VA
        // owners through each acknowledged queue completion. EXECUTE alone
        // starts decoding; mandatory fresh picture status still gates output.
        fn submitPicture(self: *Self, words: *const [v.command_words]u32, loans: []gpu.Context.Loan) !void {
            if (!self.stepTrace()) return self.ctx.submit(self.resource(.commands), @sizeOf(@TypeOf(words.*)), loans);
            const ends = [_]usize{ 2, 4, 12, 14, 32, 50, 52, 54 };
            const names = [_][]const u8{ "object", "application", "control", "status", "luma", "chroma", "mbhist", "execute" };
            var begin_word: usize = 0;
            for (ends, names) |end_word, name| {
                const bytes = std.mem.sliceAsBytes(words[begin_word..end_word]);
                try self.upload(.commands, bytes);
                var stage: [64]u8 = undefined;
                self.trace(try std.fmt.bufPrint(&stage, "step-before-{s}", .{name}), null, null);
                self.ctx.submit(self.resource(.commands), @intCast(bytes.len), loans) catch |err| {
                    self.trace(std.fmt.bufPrint(&stage, "step-error-{s}", .{name}) catch "step-error", null, err);
                    return err;
                };
                self.trace(try std.fmt.bufPrint(&stage, "step-after-{s}", .{name}), null, null);
                begin_word = end_word;
            }
        }
        fn end(self: *Self, ptr: ?*anyopaque) callconv(.c) c_int {
            const image = self.find(ptr) orelse return self.reject(error.Invalid);
            if (self.failed or self.active != image or image.state != .decoding) return self.reject(error.Invalid);
            self.execute() catch |err| return self.reject(err);
            self.active = null;
            image.state = .complete;
            return 0;
        }
        fn execute(self: *Self) !void {
            const encoded = try self.stream.finish();
            self.picture.bitstream_bytes = encoded.bitstream_bytes;
            self.picture.slices = encoded.slice_count;
            try self.upload(.parameters, &(try v.encodePicture(self.ctx.device.class, &self.picture, self.layout)));
            try self.upload(.slices, &encoded.offsets);
            try self.upload(.status, &v.pendingStatus()); // Fresh for EVERY picture.
            var buffers: v.Buffers = .{ .picture = self.span(.parameters), .bitstream = self.span(.bitstream),
                .slices = self.span(.slices), .status = self.span(.status), .coloc = self.span(.coloc),
                .history = self.span(.history), .mbhist = self.span(.mbhist), .surfaces = @splat(null) };
            var loans: [kinds.len + v.max_surfaces]gpu.Context.Loan = undefined;
            var count: usize = 0;
            for (&self.work, kinds) |*buffer, kind| {
                loans[count] = .{ .resource = buffer, .write = kind == .status or @intFromEnum(kind) >= @intFromEnum(Kind.coloc) };
                count += 1;
            }
            for (self.coloc, 0..) |entry, i| if (entry) |image| {
                const buffer = &image.resource;
                const d = buffer.descriptor;
                const req = try v.requirements(image.sequence, image.layout);
                buffers.surfaces[i] = .{ .luma = .{ .address = buffer.address + d.plane_offsets[0], .bytes = req.luma },
                    .chroma = .{ .address = buffer.address + d.plane_offsets[1], .bytes = req.chroma } };
                loans[count] = .{ .resource = buffer, .write = image == self.active };
                count += 1;
            };
            if (self.picture_index == std.math.maxInt(u32)) return error.Invalid;
            self.picture_index += 1;
            const words = try v.encodeCommands(self.ctx.device.class, &self.picture, self.layout, &buffers, self.picture_index);
            try self.upload(.commands, std.mem.sliceAsBytes(&words));
            self.trace("before-submit", null, null);
            self.submitPicture(&words, loans[0..count]) catch |err| {
                self.trace("submit-error", null, err);
                return err;
            };
            // Read once from the coherent status BO after full engine/resource
            // completion. A queue fence alone never marks an Image complete.
            const snapshot = try self.snapshotStatus();
            self.trace("after-submit", &snapshot, null);
            _ = v.pictureStatus(&snapshot, .succeeded, self.picture.sequence.width_mbs * self.picture.sequence.height_mbs) catch |err| {
                self.trace("status-error", &snapshot, err);
                return err;
            };
        }
        fn abort(self: *Self, ptr: ?*anyopaque) callconv(.c) void {
            const image = self.find(ptr) orelse @trap();
            if (image.state == .complete) @trap();
            image.state = .aborted;
            if (self.active == image) self.active = null;
            self.failed = true;
            // No GPU storage is freed here. A failed queue retains its loans.
        }
        fn release(self: *Self, ptr: ?*anyopaque) callconv(.c) void {
            const image = self.find(ptr) orelse @trap();
            if (image.state == .decoding or self.active == image) @trap();
            for (&self.coloc) |*entry| if (entry.* == image) { entry.* = null; };
            image.state = .released;
        }
        pub fn describe(self: *Self, ptr: ?*anyopaque) ?*const gpu.Resource {
            const image = self.find(ptr) orelse return null;
            return if (image.state == .complete) &image.resource else null;
        }
        pub fn reap(self: *Self) !void {
            var pending = false;
            for (&self.images) |*image| if (image.state == .released) {
                image.resource.close() catch |err| {
                    if (err != error.Busy) return err;
                    pending = true;
                    continue;
                };
                image.* = .{};
            };
            if (pending) return error.Busy;
        }
        pub fn pendingRetirement(self: *const Self) bool {
            if (self.ctx.fence.timeline != 0 or self.ctx.queue.timeline != 0) return true;
            for (&self.images) |*image| if (image.state == .released) return true;
            for (&self.work) |*buffer| if (buffer.owner != null) return true;
            return false;
        }
        // Flush removes codec references, not returned AVFrames. Consumer BOs
        // survive; their old coloc indices may be reassigned on the next begin.
        pub fn flush(self: *Self) void {
            std.debug.assert(self.active == null and !self.failed);
            self.coloc = @splat(null);
        }
        // Call after codec_close, repeatedly while outstanding AVFrames retire.
        // Worker exit/destruction is allowed only after this returns success.
        pub fn close(self: *Self) !void {
            self.closing = true;
            try self.ctx.close();
            try self.reap();
            var live = false;
            for (&self.images) |*image| if (image.state != .empty) { live = true; };
            var pending = false;
            for (&self.work) |*buffer| buffer.close() catch |err| {
                if (err != error.Busy) return err;
                pending = true;
            };
            if (live or pending) return error.Busy;
        }
    };
}
