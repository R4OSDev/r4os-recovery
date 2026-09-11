//! Sequential image ingestion retains only nonzero 64-KB blocks. All blocks
//! are owned before publication; later reads allocate nothing and need no I/O.
const std = @import("std");
const Source = @import("byte_source.zig").Source;
pub const block_bytes = 64 * 1024;
pub const maximum_bytes: usize = 16 * 1024 * 1024 * 1024;
pub const Image = struct {
    allocator: std.mem.Allocator,
    length: usize,
    blocks: []?[]const u8,
    written: usize = 0,
    stored_bytes: usize = 0,
    pending: [block_bytes]u8 = undefined,
    pending_bytes: usize = 0,
    complete: bool = false,

    pub fn init(allocator: std.mem.Allocator, length: usize) !*Image {
        if (length > maximum_bytes) return error.ImageLimit;
        const self = try allocator.create(Image);
        errdefer allocator.destroy(self);
        const blocks = try allocator.alloc(?[]const u8, std.math.divCeil(usize, length, block_bytes) catch return error.ImageLimit);
        @memset(blocks, null);
        self.* = .{ .allocator = allocator, .length = length, .blocks = blocks };
        return self;
    }
    pub fn deinit(self: *Image) void {
        for (self.blocks) |bytes| if (bytes) |owned| self.allocator.free(owned);
        self.allocator.free(self.blocks);
        self.allocator.destroy(self);
    }
    pub fn append(self: *Image, bytes: []const u8) !void {
        if (self.complete or bytes.len > self.length - self.written) return error.SourceBounds;
        var at: usize = 0;
        while (at < bytes.len) {
            const count = @min(block_bytes - self.pending_bytes, bytes.len - at);
            @memcpy(self.pending[self.pending_bytes..][0..count], bytes[at..][0..count]);
            self.pending_bytes += count;
            self.written += count;
            at += count;
            if (self.pending_bytes == block_bytes) try self.storePending();
        }
    }
    fn storePending(self: *Image) !void {
        if (self.pending_bytes == 0) return;
        const bytes = self.pending[0..self.pending_bytes];
        const index = (self.written - self.pending_bytes) / block_bytes;
        if (!std.mem.allEqual(u8, bytes, 0)) {
            self.blocks[index] = try self.allocator.dupe(u8, bytes);
            self.stored_bytes += bytes.len;
        }
        self.pending_bytes = 0;
    }
    pub fn finish(self: *Image) !void {
        if (self.complete or self.written != self.length) return error.SourceBounds;
        try self.storePending();
        self.complete = true;
    }
    pub fn source(self: *const Image) Source {
        return .{ .context = self, .length = self.length, .read_fn = read };
    }
    fn read(raw: *const anyopaque, at: usize, out: []u8) !void {
        const self: *const Image = @ptrCast(@alignCast(raw));
        if (!self.complete) return error.SourceIncomplete;
        var done: usize = 0;
        while (done < out.len) {
            const offset = at + done;
            const within = offset % block_bytes;
            const count = @min(block_bytes - within, out.len - done);
            if (self.blocks[offset / block_bytes]) |bytes|
                @memcpy(out[done..][0..count], bytes[within..][0..count])
            else
                @memset(out[done..][0..count], 0);
            done += count;
        }
    }
};

test "sparse ingestion omits zero blocks and reads cross-block tails exactly" {
    const t = std.testing;
    const input = try t.allocator.alloc(u8, 3 * block_bytes + 17);
    defer t.allocator.free(input);
    @memset(input, 0);
    input[block_bytes + 9] = 42;
    input[input.len - 1] = 89;
    const image = try Image.init(t.allocator, input.len);
    defer image.deinit();
    var readback: [8192]u8 = undefined;
    try t.expectError(error.SourceIncomplete, image.source().read(0, &readback));
    var at: usize = 0;
    while (at < input.len) {
        const count = @min(777, input.len - at);
        try image.append(input[at..][0..count]);
        at += count;
    }
    try image.finish();
    try t.expectEqual(block_bytes + 17, image.stored_bytes);
    at = 0;
    while (at < input.len) {
        const count = @min(readback.len, input.len - at);
        try image.source().read(at, readback[0..count]);
        try t.expectEqualSlices(u8, input[at..][0..count], readback[0..count]);
        at += count;
    }
    try t.expectError(error.SourceBounds, image.append("x"));
    try t.expectError(error.SourceBounds, image.source().read(input.len, readback[0..1]));
}
