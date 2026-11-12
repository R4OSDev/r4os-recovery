// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Bounded, append-only Matroska/H.264 writer for an explicit recording owner.
//! RFC9559 and Matroska V_MPEG4/ISO/AVC. One known-sized cluster per access
//! unit; no lacing, B-picture reordering, seeking, retained packet or heap.
//! The caller owns durations and writes through a fallible synchronous sink
//! outside the desktop thread. A failed write invalidates the staged file.
const std = @import("std");
pub const Error = error{ Invalid, Bounds, FormatChange, Write, Closed };
pub const Color = struct { transfer: u8 = 1, centered_chroma: bool = false };
const max_packet = 8 * 1024 * 1024;
const max_parameter = 256;
const max_nals = 64;

const Buffer = struct {
    data: [2048]u8 = undefined,
    length: usize = 0,
    fn view(self: *const Buffer) []const u8 { return self.data[0..self.length]; }
    fn raw(self: *Buffer, bytes: []const u8) Error!void {
        if (bytes.len > self.data.len - self.length) return error.Bounds;
        @memcpy(self.data[self.length..][0..bytes.len], bytes);
        self.length += bytes.len;
    }
    fn number(self: *Buffer, value: u64, count: usize) Error!void {
        var encoded: [8]u8 = undefined;
        std.mem.writeInt(u64, &encoded, value, .big);
        try self.raw(encoded[8-count..]);
    }
    fn header(self: *Buffer, id: u32, size: u64) Error!void {
        const id_bytes: usize = if (id > 0xffffff) 4 else if (id > 0xffff) 3 else if (id > 0xff) 2 else 1;
        try self.number(id, id_bytes);
        var count: usize = 1;
        while (count < 8 and size >= (@as(u64, 1) << @intCast(count * 7)) - 1) : (count += 1) {}
        if (size >= (@as(u64, 1) << 56) - 1) return error.Bounds;
        try self.number(size | (@as(u64, 1) << @intCast(count * 7)), count);
    }
    fn element(self: *Buffer, id: u32, bytes: []const u8) Error!void {
        try self.header(id, bytes.len); try self.raw(bytes);
    }
    fn uint(self: *Buffer, id: u32, value: u64) Error!void {
        var count: usize = 1;
        while (count < 8 and value >> @intCast(count * 8) != 0) : (count += 1) {}
        try self.header(id, count); try self.number(value, count);
    }
};

const Unit = struct {
    nals: [max_nals][]const u8 = undefined,
    count: usize = 0,
    avc_bytes: usize = 0,
    sps: ?[]const u8 = null,
    pps: ?[]const u8 = null,
    key: bool = false,
    fn parse(bytes: []const u8, key: bool) Error!Unit {
        if (bytes.len == 0 or bytes.len > max_packet) return error.Bounds;
        var unit: Unit = .{};
        var cursor: usize = 0;
        var vcl: usize = 0;
        while (cursor < bytes.len) {
            const prefix = startCode(bytes[cursor..]);
            if (prefix == 0 or unit.count == max_nals) return error.Invalid;
            const first = cursor + prefix;
            cursor = first;
            while (cursor < bytes.len and startCode(bytes[cursor..]) == 0) : (cursor += 1) {}
            var end = cursor;
            // Annex-B trailing_zero_8bits are not part of the AVC NAL unit.
            while (end > first and bytes[end-1] == 0) : (end -= 1) {}
            if (end == first or bytes[first] & 0x80 != 0) return error.Invalid;
            const nal = bytes[first..end];
            switch (nal[0] & 31) {
                1 => { if (key) return error.Invalid; vcl += 1; },
                5 => { if (!key) return error.Invalid; vcl += 1; unit.key = true; },
                7 => {
                    if (unit.sps != null or nal.len < 4 or nal.len > max_parameter or nal[1] != 66) return error.Invalid;
                    unit.sps = nal;
                },
                8 => {
                    if (unit.pps != null or nal.len < 2 or nal.len > max_parameter) return error.Invalid;
                    unit.pps = nal;
                },
                6, 9, 12 => {}, // SEI, access-unit delimiter, filler.
                else => return error.Invalid,
            }
            unit.nals[unit.count] = nal; unit.count += 1;
            unit.avc_bytes += 4 + nal.len;
        }
        if (vcl == 0 or unit.key != key) return error.Invalid;
        return unit;
    }
};
fn startCode(bytes: []const u8) usize {
    if (bytes.len >= 3 and bytes[0] == 0 and bytes[1] == 0) {
        if (bytes[2] == 1) return 3;
        if (bytes.len >= 4 and bytes[2] == 0 and bytes[3] == 1) return 4;
    }
    return 0;
}

pub const Writer = struct {
    width: u32,
    height: u32,
    color: Color = .{},
    sps: [max_parameter]u8 = undefined,
    pps: [max_parameter]u8 = undefined,
    sps_len: usize = 0,
    pps_len: usize = 0,
    started: bool = false,
    failed: bool = false,
    origin_ns: i64 = 0,
    previous_ms: u64 = 0,
    frames: u64 = 0,
    // Sink.write([]const u8) returns bool only after all bytes are written.
    // No retained sink pointer or packet storage crosses this call.
    pub fn packet(self: *Writer, sink: anytype, bytes: []const u8, key: bool, pts_ns: i64, duration_ns: u64) Error!void {
        if (self.failed) return error.Closed;
        if (self.width < 16 or self.height < 16 or self.width > 4096 or self.height > 4096 or
            (self.width | self.height) & 1 != 0 or (self.color.transfer != 1 and self.color.transfer != 13) or
            duration_ns == 0 or duration_ns > std.math.maxInt(i64) or pts_ns < 0) return error.Invalid;
        const unit = try Unit.parse(bytes, key);
        if (!self.started) {
            if (!key or unit.sps == null or unit.pps == null) return error.Invalid;
        } else {
            if (pts_ns < self.origin_ns) return error.Invalid;
            if (unit.sps) |sps| if (!std.mem.eql(u8, sps, self.sps[0..self.sps_len])) return error.FormatChange;
            if (unit.pps) |pps| if (!std.mem.eql(u8, pps, self.pps[0..self.pps_len])) return error.FormatChange;
        }
        const timestamp: u64 = if (!self.started) 0 else @intCast(@divTrunc(pts_ns - self.origin_ns, 1_000_000));
        if (self.frames != 0 and timestamp <= self.previous_ms) return error.Invalid;
        const duration = (duration_ns + 999999) / 1_000_000;
        errdefer self.failed = true;
        if (!self.started) {
            self.sps_len = unit.sps.?.len; self.pps_len = unit.pps.?.len;
            @memcpy(self.sps[0..self.sps_len], unit.sps.?);
            @memcpy(self.pps[0..self.pps_len], unit.pps.?);
            const file_header = try self.header();
            try write(sink, file_header.view());
            self.origin_ns = pts_ns;
            self.started = true;
        }
        var group: Buffer = .{};
        try group.uint(0x9b, duration); // BlockDuration, in1ms track ticks.
        if (!key) {
            // One short-term reference and no reorder: the previous picture.
            try group.header(0xfb, 8);
            try group.number(@bitCast(-@as(i64, @intCast(timestamp - self.previous_ms))), 8);
        }
        try group.header(0xa1, 4 + unit.avc_bytes); // Block, one frame, no lacing.
        try group.raw(&.{ 0x81, 0, 0, 0 }); // Track1, relative timestamp0, flags0.
        var cluster: Buffer = .{};
        try cluster.uint(0xe7, timestamp);
        try cluster.header(0xa0, group.length + unit.avc_bytes);
        try cluster.raw(group.view());
        var prefix: Buffer = .{};
        try prefix.header(0x1f43b675, cluster.length + unit.avc_bytes);
        try prefix.raw(cluster.view());
        try write(sink, prefix.view());
        for (unit.nals[0..unit.count]) |nal| {
            var length: [4]u8 = undefined;
            std.mem.writeInt(u32, &length, @intCast(nal.len), .big);
            try write(sink, &length); try write(sink, nal);
        }
        self.previous_ms = timestamp;
        self.frames += 1;
    }
    fn header(self: *const Writer) Error!Buffer {
        var document: Buffer = .{};
        var ebml: Buffer = .{};
        try ebml.uint(0x4286, 1); try ebml.uint(0x42f7, 1);
        try ebml.uint(0x42f2, 4); try ebml.uint(0x42f3, 8);
        try ebml.element(0x4282, "matroska");
        try ebml.uint(0x4287, 4); try ebml.uint(0x4285, 2);
        try document.element(0x1a45dfa3, ebml.view());
        try document.raw(&.{ 0x18, 0x53, 0x80, 0x67, 0x01, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff }); // Unknown-sized Segment.
        var info: Buffer = .{};
        try info.uint(0x2ad7b1, 1_000_000);
        try info.element(0x4d80, "R4OS R4ENC"); try info.element(0x5741, "R4OS Recording");
        try document.element(0x1549a966, info.view());
        var avcc: Buffer = .{};
        try avcc.raw(&.{ 1, self.sps[1], self.sps[2], self.sps[3], 0xff, 0xe1 });
        try avcc.number(self.sps_len, 2); try avcc.raw(self.sps[0..self.sps_len]);
        try avcc.raw(&.{1}); try avcc.number(self.pps_len, 2); try avcc.raw(self.pps[0..self.pps_len]);
        var color: Buffer = .{};
        try color.uint(0x55b1, 1); try color.uint(0x55b2, 8);
        try color.uint(0x55b3, 1); try color.uint(0x55b4, 1);
        try color.uint(0x55b7, if (self.color.centered_chroma) 2 else 1); try color.uint(0x55b8, 2);
        try color.uint(0x55b9, 1); try color.uint(0x55ba, self.color.transfer); try color.uint(0x55bb, 1);
        var video: Buffer = .{};
        try video.uint(0xb0, self.width); try video.uint(0xba, self.height);
        try video.uint(0x9a, 2); // Progressive.
        try video.element(0x55b0, color.view());
        var track: Buffer = .{};
        try track.uint(0xd7, 1); try track.uint(0x73c5, 1); try track.uint(0x83, 1);
        try track.uint(0x9c, 0);
        try track.element(0x86, "V_MPEG4/ISO/AVC"); try track.element(0x63a2, avcc.view());
        try track.element(0xe0, video.view());
        var tracks: Buffer = .{};
        try tracks.element(0xae, track.view());
        try document.element(0x1654ae6b, tracks.view());
        return document;
    }
};
fn write(sink: anytype, bytes: []const u8) Error!void {
    var offset: usize = 0;
    while (offset < bytes.len) {
        const end = @min(bytes.len, offset + 65536);
        if (!sink.write(bytes[offset..end])) return error.Write;
        offset = end;
    }
}
