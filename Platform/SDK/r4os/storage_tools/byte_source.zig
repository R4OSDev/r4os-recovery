//! Bounded immutable byte reader. The owner retains its backing storage.
const std = @import("std");
pub const Source = struct {
    context: *const anyopaque,
    length: usize,
    offset: usize = 0,
    read_fn: *const fn (*const anyopaque, usize, []u8) anyerror!void,

    pub fn read(self: Source, at: usize, out: []u8) !void {
        if (at > self.length or out.len > self.length - at) return error.SourceBounds;
        try self.read_fn(self.context, self.offset + at, out);
    }
    pub fn range(self: Source, at: usize, len: usize) !Source {
        if (at > self.length or len > self.length - at) return error.SourceBounds;
        var result = self;
        result.offset += at;
        result.length = len;
        return result;
    }
    pub fn slice(bytes: []const u8) Source {
        return .{ .context = bytes.ptr, .length = bytes.len, .read_fn = readSlice };
    }
    fn readSlice(context: *const anyopaque, at: usize, out: []u8) !void {
        const bytes: [*]const u8 = @ptrCast(context);
        @memcpy(out, bytes[at..][0..out.len]);
    }
};

test "byte source nested ranges enforce local bounds" {
    const source = try (try Source.slice("abcdefgh").range(2, 5)).range(1, 3);
    var out: [3]u8 = undefined;
    try source.read(0, &out);
    try std.testing.expectEqualStrings("def", &out);
    try std.testing.expectError(error.SourceBounds, source.read(1, &out));
    try std.testing.expectError(error.SourceBounds, source.range(std.math.maxInt(usize), 1));
}
