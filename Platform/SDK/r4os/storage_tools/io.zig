//! Bounded host-neutral block I/O for partition and filesystem tools.
//! Adapters own file/claim lifetime; no kernel or host facilities enter here.
const std = @import("std");

pub const sector_size: usize = 512;
pub const max_transfer_bytes: usize = 128 * 1024;
pub const scratch_bytes: usize = 64 * 1024;
pub const Error = error{
    Geometry,
    Bounds,
    ExclusiveRequired,
    ReadFailed,
    WriteFailed,
    FlushFailed,
    VerifyFailed,
    Cancelled,
};

pub const Phase = enum { preflight, invalidate, erase, metadata, backup, primary, flush, verify, complete };

pub const Progress = struct {
    phase: Phase = .preflight,
    write_attempted: bool = false,
    written_sectors: u64 = 0,
    flushed: bool = false,
    verified: bool = false,
    failed_lba: ?u64 = null,
    failure: ?Error = null,
    native_error: i32 = 0,
};

pub const Device = struct {
    context: *anyopaque,
    sectors: u64,
    sector_bytes: u32 = sector_size,
    exclusive: bool = false,
    read_fn: *const fn (*anyopaque, u64, []u8) i32,
    write_fn: *const fn (*anyopaque, u64, []const u8) i32,
    flush_fn: *const fn (*anyopaque) i32,
    progress: ?*Progress = null,
    cancel_context: ?*anyopaque = null,
    continue_fn: ?*const fn (?*anyopaque, Phase, u64) bool = null,

    pub fn validate(self: Device) Error!void {
        if (self.sector_bytes != sector_size or self.sectors == 0 or
            self.sectors > std.math.maxInt(u64) / sector_size) return error.Geometry;
    }

    pub fn requireExclusive(self: Device) Error!void {
        try self.validate();
        if (!self.exclusive) return error.ExclusiveRequired;
    }

    pub fn checkRange(self: Device, lba: u64, count: u64) Error!void {
        try self.validate();
        if (count == 0 or lba >= self.sectors or count > self.sectors - lba) return error.Bounds;
    }

    pub fn phase(self: Device, value: Phase) void {
        if (self.progress) |p| p.phase = value;
    }

    fn checkpoint(self: Device, lba: u64) Error!void {
        if (self.continue_fn) |function| {
            const current_phase = if (self.progress) |p| p.phase else .preflight;
            const written = if (self.progress) |p| p.written_sectors else 0;
            if (!function(self.cancel_context, current_phase, written))
                return self.fail(error.Cancelled, lba, 0);
        }
    }

    fn fail(self: Device, failure: Error, lba: ?u64, native_error: i32) Error {
        if (self.progress) |p| {
            if (p.failure == null) {
                p.failure = failure;
                p.failed_lba = lba;
                p.native_error = native_error;
            }
        }
        return failure;
    }

    pub fn read(self: Device, lba: u64, out: []u8) Error!void {
        if (out.len == 0 or out.len % sector_size != 0) return error.Bounds;
        try self.checkRange(lba, out.len / sector_size);
        var offset: usize = 0;
        while (offset < out.len) {
            const position = lba + offset / sector_size;
            const length = @min(out.len - offset, max_transfer_bytes);
            try self.checkpoint(position);
            const result = self.read_fn(self.context, position, out[offset..][0..length]);
            if (result != 0) return self.fail(error.ReadFailed, position, result);
            offset += length;
        }
    }

    pub fn write(self: Device, lba: u64, data: []const u8) Error!void {
        try self.requireExclusive();
        if (data.len == 0 or data.len % sector_size != 0) return error.Bounds;
        try self.checkRange(lba, data.len / sector_size);
        var offset: usize = 0;
        while (offset < data.len) {
            const position = lba + offset / sector_size;
            const length = @min(data.len - offset, max_transfer_bytes);
            try self.checkpoint(position);
            // A failed backend may have completed a prefix. Never report an
            // untouched target after the first write attempt or retry it.
            if (self.progress) |p| {
                p.write_attempted = true;
                p.flushed = false;
                p.verified = false;
            }
            const result = self.write_fn(self.context, position, data[offset..][0..length]);
            if (result != 0) return self.fail(error.WriteFailed, position, result);
            if (self.progress) |p| p.written_sectors +|= length / sector_size;
            offset += length;
        }
    }

    pub fn flush(self: Device) Error!void {
        try self.requireExclusive();
        self.phase(.flush);
        const result = self.flush_fn(self.context);
        if (result != 0) return self.fail(error.FlushFailed, null, result);
        if (self.progress) |p| p.flushed = true;
    }

    pub fn verify(self: Device, lba: u64, expected: []const u8, scratch: []u8) Error!void {
        if (scratch.len < sector_size or scratch.len % sector_size != 0 or
            expected.len == 0 or expected.len % sector_size != 0) return error.Bounds;
        try self.checkRange(lba, expected.len / sector_size);
        self.phase(.verify);
        var offset: usize = 0;
        while (offset < expected.len) {
            const length = @min(expected.len - offset, scratch.len);
            try self.read(lba + offset / sector_size, scratch[0..length]);
            if (!std.mem.eql(u8, expected[offset..][0..length], scratch[0..length]))
                return self.fail(error.VerifyFailed, lba + offset / sector_size, 0);
            offset += length;
        }
    }

    pub fn complete(self: Device) void {
        if (self.progress) |p| {
            p.verified = true;
            p.phase = .complete;
        }
    }

    pub fn fill(self: Device, lba: u64, count: u64, value: u8, scratch: []u8) Error!void {
        try self.requireExclusive();
        try self.checkRange(lba, count);
        if (scratch.len < sector_size or scratch.len % sector_size != 0) return error.Bounds;
        @memset(scratch, value);
        var done: u64 = 0;
        while (done < count) {
            const sectors = @min(count - done, scratch.len / sector_size);
            try self.write(lba + done, scratch[0..@intCast(sectors * sector_size)]);
            done += sectors;
        }
    }

    /// Writes an owned extent starting at a sector boundary, zero-padding
    /// its last sector. It never reads or modifies a neighbouring sector.
    pub fn writePadded(self: Device, byte_offset: u64, data: []const u8) Error!void {
        if (byte_offset % sector_size != 0) return error.Bounds;
        if (data.len == 0) return;
        const lba = byte_offset / sector_size;
        try self.checkRange(lba, (data.len - 1) / sector_size + 1);
        const whole = data.len / sector_size * sector_size;
        if (whole != 0) try self.write(lba, data[0..whole]);
        if (whole != data.len) {
            var tail: [sector_size]u8 = .{0} ** sector_size;
            @memcpy(tail[0 .. data.len - whole], data[whole..]);
            try self.write(lba + whole / sector_size, &tail);
        }
    }
};

/// Explicit view of an already-owned partition within a device. The parent
/// must outlive the view; the callbacks keep all relative bounds checked.
pub const Region = struct {
    parent: Device,
    first: u64,
    count: u64,

    pub fn device(self: *Region) Error!Device {
        try self.parent.checkRange(self.first, self.count);
        return .{
            .context = self,
            .sectors = self.count,
            .exclusive = self.parent.exclusive,
            .read_fn = read,
            .write_fn = write,
            .flush_fn = flush,
            .progress = self.parent.progress,
            .cancel_context = self.parent.cancel_context,
            .continue_fn = self.parent.continue_fn,
        };
    }
    fn read(raw: *anyopaque, lba: u64, bytes: []u8) i32 {
        const self: *Region = @ptrCast(@alignCast(raw));
        return self.parent.read_fn(self.parent.context, self.first + lba, bytes);
    }
    fn write(raw: *anyopaque, lba: u64, bytes: []const u8) i32 {
        const self: *Region = @ptrCast(@alignCast(raw));
        return self.parent.write_fn(self.parent.context, self.first + lba, bytes);
    }
    fn flush(raw: *anyopaque) i32 {
        const self: *Region = @ptrCast(@alignCast(raw));
        return self.parent.flush_fn(self.parent.context);
    }
};

/// Compatibility adapter for existing in-memory formatter fixtures. Host
/// image tools and guest format commands use their file/claim adapters.
pub const Memory = struct {
    bytes: []u8,
    pub fn device(self: *Memory) Device {
        return .{ .context = self, .sectors = self.bytes.len / 512, .exclusive = true, .read_fn = read, .write_fn = write, .flush_fn = flush };
    }
    fn read(raw: *anyopaque, lba: u64, out: []u8) i32 {
        const self: *Memory = @ptrCast(@alignCast(raw));
        const offset: usize = @intCast(lba * 512);
        @memcpy(out, self.bytes[offset..][0..out.len]);
        return 0;
    }
    fn write(raw: *anyopaque, lba: u64, data: []const u8) i32 {
        const self: *Memory = @ptrCast(@alignCast(raw));
        const offset: usize = @intCast(lba * 512);
        @memcpy(self.bytes[offset..][0..data.len], data);
        return 0;
    }
    fn flush(_: *anyopaque) i32 {
        return 0;
    }
};
