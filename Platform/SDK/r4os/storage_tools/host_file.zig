//! Host-only adapter; uses the same std.Io implementation on Windows/Linux.
const std = @import("std");
const block = @import("io.zig");

/// Borrows a file handle. Release the lock before the caller closes it.
pub const File = struct {
    file: std.Io.File,
    io: std.Io,
    sectors: u64,
    locked: bool = false,
    last_error: ?anyerror = null,

    pub fn init(file: std.Io.File, io: std.Io) !File {
        const info = try file.stat(io);
        if (info.size % 512 != 0) return error.Geometry;
        return .{ .file = file, .io = io, .sectors = info.size / 512 };
    }

    pub fn acquire(self: *File) !void {
        if (self.locked) return;
        if (!try self.file.tryLock(self.io, .exclusive)) return error.Busy;
        self.locked = true;
    }

    pub fn release(self: *File) void {
        if (self.locked) self.file.unlock(self.io);
        self.locked = false;
    }

    pub fn resize(self: *File, sectors: u64) !void {
        if (!self.locked) return error.ExclusiveRequired;
        if (sectors == 0 or sectors > std.math.maxInt(u64) / 512) return error.Geometry;
        try self.file.setLength(self.io, sectors * 512);
        self.sectors = sectors;
    }

    pub fn device(self: *File, progress: ?*block.Progress) block.Device {
        return .{
            .context = self,
            .sectors = self.sectors,
            .exclusive = self.locked,
            .read_fn = read,
            .write_fn = write,
            .flush_fn = flush,
            .progress = progress,
        };
    }

    fn read(raw: *anyopaque, lba: u64, out: []u8) i32 {
        const self: *File = @ptrCast(@alignCast(raw));
        const count = self.file.readPositionalAll(self.io, out, lba * 512) catch |err| {
            self.last_error = err;
            return -1;
        };
        if (count != out.len) {
            self.last_error = error.UnexpectedEndOfFile;
            return -2;
        }
        return 0;
    }

    fn write(raw: *anyopaque, lba: u64, bytes: []const u8) i32 {
        const self: *File = @ptrCast(@alignCast(raw));
        if (!self.locked) return -3;
        self.file.writePositionalAll(self.io, bytes, lba * 512) catch |err| {
            self.last_error = err;
            return -1;
        };
        return 0;
    }

    fn flush(raw: *anyopaque) i32 {
        const self: *File = @ptrCast(@alignCast(raw));
        if (!self.locked) return -3;
        self.file.sync(self.io) catch |err| {
            self.last_error = err;
            return -1;
        };
        return 0;
    }
};
