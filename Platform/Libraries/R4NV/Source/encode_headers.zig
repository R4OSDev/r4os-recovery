// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! H.264 Constrained Baseline parameter sets shared by the native picture
//! encoder. Progressive 8-bit NV12, one short-term reference, no reordering.
const std = @import("std");
pub const Error = error{ Bounds, Unsupported, Capacity };
pub const profile = 66;
pub const level = 51;
pub const log2_frame_num = 16;
pub const poc_type = 2;
pub const reference_count = 1;
pub const max_parameter_bytes = 256;
pub const Sequence = struct {
    width: u32,
    height: u32,
    qp: u32,
    fps_num: u32,
    fps_den: u32,
    transfer: u8 = 1, // CICP BT.709 or IEC61966-2-1 for captured sRGB.
};
pub const Dimensions = struct { width_mbs: u32, height_mbs: u32, macroblocks: u32 };
pub const ParameterSets = struct {
    data: [max_parameter_bytes]u8 = @splat(0),
    length: usize = 0,
    pub fn bytes(self: *const ParameterSets) []const u8 { return self.data[0..self.length]; }
};

pub fn dimensions(s: Sequence) Error!Dimensions {
    if (s.transfer != 1 and s.transfer != 13) return error.Unsupported;
    if (s.width < 16 or s.height < 16 or s.width > 4096 or s.height > 4096 or
        (s.width | s.height) & 1 != 0 or s.qp > 51 or s.fps_num == 0 or
        s.fps_den == 0 or s.fps_num > std.math.maxInt(u32) / 2) return error.Bounds;
    const w = (s.width + 15) / 16;
    const h = (s.height + 15) / 16;
    // Level5.1 MaxFS and MaxMBPS. No rate-control/HRD guarantee is advertised
    // for CQP; even a legal picture size must fit the declared frame rate.
    if (w * h > 36864 or @as(u64, w * h) * s.fps_num > @as(u64, 983040) * s.fps_den)
        return error.Unsupported;
    return .{ .width_mbs = w, .height_mbs = h, .macroblocks = w * h };
}

pub fn parameterSets(s: Sequence) Error!ParameterSets {
    const d = try dimensions(s);
    var output: ParameterSets = .{};
    var b: Bits = .{};
    try b.bits(profile, 8);
    try b.bits(0xc0, 8); // constraint_set0/1, reserved_zero_2bits.
    try b.bits(level, 8);
    try b.ue(0); // seq_parameter_set_id.
    try b.ue(log2_frame_num - 4);
    try b.ue(poc_type);
    try b.ue(reference_count);
    try b.flag(false); // gaps_in_frame_num_value_allowed_flag.
    try b.ue(d.width_mbs - 1);
    try b.ue(d.height_mbs - 1);
    try b.flag(true); // frame_mbs_only_flag.
    try b.flag(true); // direct_8x8_inference_flag.
    const cropped = s.width != d.width_mbs * 16 or s.height != d.height_mbs * 16;
    try b.flag(cropped);
    if (cropped) {
        try b.ue(0); try b.ue((d.width_mbs * 16 - s.width) / 2);
        try b.ue(0); try b.ue((d.height_mbs * 16 - s.height) / 2);
    }
    try b.flag(true); // vui_parameters_present_flag.
    try b.flag(false); // aspect_ratio_info_present_flag.
    try b.flag(false); // overscan_info_present_flag.
    try b.flag(true); // video_signal_type_present_flag.
    try b.bits(5, 3); // unspecified source video format.
    try b.flag(false); // limited range.
    try b.flag(true); // colour_description_present_flag.
    try b.bits(1, 8); try b.bits(s.transfer, 8); try b.bits(1, 8); //709 primaries/matrix; explicit transfer.
    try b.flag(false); // chroma_loc_info_present_flag: default left siting.
    try b.flag(true); // timing_info_present_flag.
    try b.bits(s.fps_den, 32);
    try b.bits(s.fps_num * 2, 32);
    // Capture/remote input may have skipped frames and variable timestamps.
    // This timing expresses a nominal rate, not fixed-interval output.
    try b.flag(false); // fixed_frame_rate_flag.
    try b.flag(false); // nal_hrd_parameters_present_flag.
    try b.flag(false); // vcl_hrd_parameters_present_flag.
    try b.flag(false); // pic_struct_present_flag.
    try b.flag(true); // bitstream_restriction_flag.
    try b.flag(true); // motion_vectors_over_pic_boundaries_flag.
    try b.ue(0); try b.ue(0); // No additional per-picture/MB compression bound.
    try b.ue(16); try b.ue(16); // log2_max_mv_length_horizontal/vertical.
    try b.ue(0); try b.ue(reference_count); // reorder and decoded buffering.
    try b.finish(&output, 0x67);

    b = .{};
    try b.ue(0); try b.ue(0); // PPS0, SPS0.
    try b.flag(false); try b.flag(false); // CAVLC, no bottom-field POC.
    try b.ue(0); // one slice group.
    try b.ue(0); try b.ue(0); // one active reference in either list.
    try b.flag(false); try b.bits(0, 2); // no weighted prediction.
    try b.se(@as(i32, @intCast(s.qp)) - 26);
    try b.se(0); try b.se(0); // pic_init_qs_minus26, chroma_qp_index_offset.
    try b.flag(true); // deblocking_filter_control_present_flag.
    try b.flag(false); try b.flag(false); // unconstrained intra, no redundancy.
    try b.finish(&output, 0x68);
    return output;
}

const Bits = struct {
    data: [128]u8 = @splat(0),
    count: usize = 0,
    fn flag(self: *Bits, value: bool) Error!void {
        if (self.count == self.data.len * 8) return error.Capacity;
        if (value) self.data[self.count / 8] |= @as(u8, 1) << @intCast(7 - self.count % 8);
        self.count += 1;
    }
    fn bits(self: *Bits, value: u32, count: u6) Error!void {
        var remaining = count;
        while (remaining != 0) {
            remaining -= 1;
            try self.flag(value & (@as(u32, 1) << @intCast(remaining)) != 0);
        }
    }
    fn ue(self: *Bits, value: u32) Error!void {
        if (value == std.math.maxInt(u32)) return error.Bounds;
        const code = value + 1;
        const count: u6 = @intCast(32 - @clz(code));
        var zeros = count - 1;
        while (zeros != 0) : (zeros -= 1) try self.flag(false);
        try self.bits(code, count);
    }
    fn se(self: *Bits, value: i32) Error!void {
        const code: i64 = if (value <= 0) -@as(i64, value) * 2 else @as(i64, value) * 2 - 1;
        if (code >= std.math.maxInt(u32)) return error.Bounds;
        try self.ue(@intCast(code));
    }
    fn finish(self: *Bits, output: *ParameterSets, nal: u8) Error!void {
        try self.flag(true); // rbsp_stop_one_bit and byte alignment.
        while (self.count % 8 != 0) try self.flag(false);
        try append(output, 0); try append(output, 0); try append(output, 0);
        try append(output, 1); try append(output, nal);
        var zeros: u8 = 0;
        for (self.data[0 .. self.count / 8]) |value| {
            if (zeros == 2 and value <= 3) { try append(output, 3); zeros = 0; }
            try append(output, value);
            zeros = if (value == 0) zeros + 1 else 0;
        }
    }
};
fn append(output: *ParameterSets, byte: u8) Error!void {
    if (output.length == output.data.len) return error.Capacity;
    output.data[output.length] = byte; output.length += 1;
}
