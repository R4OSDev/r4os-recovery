const std = @import("std");
const block = @import("io.zig");

pub const Segment = struct { offset: u64, data: []const u8, owned: bool };

/// Complete metadata is prepared before a target is opened for writing.
/// The cluster bitmap is generated in bounded blocks from the contiguous
/// allocation prefix; it never occupies volume-proportional RAM.
pub const Plan = struct {
    allocator: std.mem.Allocator,
    bytes: u64,
    clusters: u64,
    used_clusters: u64 = 0,
    bitmap_offset: u64 = 0,
    bitmap_bytes: u64 = 0,
    bitmap_allocated_bytes: u64 = 0,
    logfile_offset: u64 = 0,
    logfile_bytes: u64 = 0,
    boot: [512]u8 = .{0} ** 512,
    segments: std.ArrayList(Segment) = .empty,

    pub fn deinit(self: *Plan) void {
        for (self.segments.items) |segment| {
            if (segment.owned) self.allocator.free(segment.data);
        }
        self.segments.deinit(self.allocator);
        self.* = undefined;
    }

    pub fn addBorrowed(self: *Plan, offset: u64, data: []const u8) !void {
        try self.checkSegment(offset, data.len);
        try self.segments.append(self.allocator, .{ .offset = offset, .data = data, .owned = false });
    }

    /// Takes ownership even when appending the descriptor fails.
    pub fn addOwned(self: *Plan, offset: u64, data: []u8) !void {
        errdefer self.allocator.free(data);
        try self.checkSegment(offset, data.len);
        try self.segments.append(self.allocator, .{ .offset = offset, .data = data, .owned = true });
    }

    pub fn addCopy(self: *Plan, offset: u64, data: []const u8) !void {
        try self.addOwned(offset, try self.allocator.dupe(u8, data));
    }

    fn checkSegment(self: *const Plan, offset: u64, length: usize) !void {
        if (offset % 512 != 0 or offset >= self.bytes or length > self.bytes - offset)
            return error.Bounds;
    }

    pub fn validate(self: *const Plan) !void {
        if (self.bytes < 16 * 1024 * 1024 or self.bytes % 512 != 0 or
            self.clusters != (self.bytes / 512 - 1) / 8 or
            self.used_clusters == 0 or self.used_clusters > self.clusters or
            self.bitmap_bytes != std.mem.alignForward(u64, (self.clusters + 7) / 8, 8) or
            self.bitmap_bytes > self.bitmap_allocated_bytes or
            self.bitmap_allocated_bytes % 512 != 0 or
            self.bitmap_offset % 512 != 0 or
            self.bitmap_offset >= self.used_clusters * 4096 or
            self.bitmap_allocated_bytes > self.used_clusters * 4096 - self.bitmap_offset or
            self.logfile_offset % 512 != 0 or self.logfile_bytes % 512 != 0 or
            self.logfile_offset >= self.bytes or self.logfile_bytes > self.bytes - self.logfile_offset or
            !std.mem.eql(u8, self.boot[3..11], "NTFS    ") or
            self.boot[510] != 0x55 or self.boot[511] != 0xaa) return error.Geometry;
        for (self.segments.items) |segment| try self.checkSegment(segment.offset, segment.data.len);
    }

    /// Builder input buffers must outlive execution. Work is caller-owned,
    /// sector-aligned in length and at least two sectors; 128 KiB is usual.
    pub fn execute(self: *const Plan, device: block.Device, full: bool, work: []u8) !void {
        try self.validate();
        try device.requireExclusive();
        if (device.sectors != self.bytes / 512 or work.len < 1024 or work.len % 1024 != 0)
            return error.Geometry;
        const half = work.len / 2;
        const scratch = work[0..half];
        const readback = work[half..];

        device.phase(.invalidate);
        @memset(scratch[0..512], 0);
        try device.write(0, scratch[0..512]);
        try device.write(device.sectors - 1, scratch[0..512]);
        device.phase(.erase);
        try device.fill(0, if (full) device.sectors else self.used_clusters * 8, 0, scratch);
        device.phase(.metadata);
        try device.fill(self.logfile_offset / 512, self.logfile_bytes / 512, 0xff, scratch);
        for (self.segments.items) |segment| try device.writePadded(segment.offset, segment.data);
        var offset: u64 = 0;
        while (offset < self.bitmap_allocated_bytes) {
            const length: usize = @intCast(@min(scratch.len, self.bitmap_allocated_bytes - offset));
            fillBitmap(scratch[0..length], offset, self.used_clusters, self.clusters, self.bitmap_bytes);
            try device.write((self.bitmap_offset + offset) / 512, scratch[0..length]);
            offset += length;
        }
        // Metadata must be durable before publishing recognisable boot
        // sectors. The sequence is ordered, not a power-fail transaction.
        try device.flush();
        device.phase(.backup);
        try device.write(device.sectors - 1, &self.boot);
        device.phase(.primary);
        try device.write(0, &self.boot);
        try device.flush();

        try device.verify(0, &self.boot, readback);
        try device.verify(device.sectors - 1, &self.boot, readback);
        @memset(scratch, 0xff);
        var log_done: u64 = 0;
        while (log_done < self.logfile_bytes) {
            const length: usize = @intCast(@min(scratch.len, self.logfile_bytes - log_done));
            try device.verify((self.logfile_offset + log_done) / 512, scratch[0..length], readback);
            log_done += length;
        }
        for (self.segments.items) |segment| {
            var done: usize = 0;
            while (done < segment.data.len) {
                const length = @min(segment.data.len - done, scratch.len);
                const padded = std.mem.alignForward(usize, length, 512);
                @memset(scratch[0..padded], 0);
                @memcpy(scratch[0..length], segment.data[done..][0..length]);
                try device.verify((segment.offset + done) / 512, scratch[0..padded], readback);
                done += length;
            }
        }
        offset = 0;
        while (offset < self.bitmap_allocated_bytes) {
            const length: usize = @intCast(@min(scratch.len, self.bitmap_allocated_bytes - offset));
            fillBitmap(scratch[0..length], offset, self.used_clusters, self.clusters, self.bitmap_bytes);
            try device.verify((self.bitmap_offset + offset) / 512, scratch[0..length], readback);
            offset += length;
        }
        device.complete();
    }
};

pub fn fillBitmap(out: []u8, byte_offset: u64, used_clusters: u64, total_clusters: u64, data_bytes: u64) void {
    @memset(out, 0);
    const first_bit = byte_offset * 8;
    const last_bit = first_bit + out.len * 8;
    setBitRange(out, first_bit, 0, @min(used_clusters, last_bit));
    setBitRange(out, first_bit, @max(total_clusters, first_bit), @min(data_bytes * 8, last_bit));
}

fn setBitRange(out: []u8, base: u64, begin: u64, end: u64) void {
    var first = @max(begin, base);
    const last = @min(end, base + out.len * 8);
    if (first >= last) return;
    while (first < last and first % 8 != 0) : (first += 1)
        out[@intCast((first - base) / 8)] |= @as(u8, 1) << @intCast(first % 8);
    const whole_end = last / 8 * 8;
    if (whole_end > first) {
        @memset(out[@intCast((first - base) / 8)..@intCast((whole_end - base) / 8)], 0xff);
        first = whole_end;
    }
    while (first < last) : (first += 1)
        out[@intCast((first - base) / 8)] |= @as(u8, 1) << @intCast(first % 8);
}

pub const Memory = block.Memory;
