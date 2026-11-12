//! Private lexemes shared by the current display preference documents.
//! Schemas, field counts, identities and semantic errors stay in each parser.
const std = @import("std");

pub const Lines = struct {
    split: std.mem.SplitIterator(u8, .scalar),

    pub fn init(bytes: []const u8) Lines {
        const content = if (std.mem.startsWith(u8, bytes, "\xef\xbb\xbf")) bytes[3..] else bytes;
        return .{ .split = std.mem.splitScalar(u8, content, '\n') };
    }
    pub fn next(self: *Lines) ?[]const u8 {
        while (self.split.next()) |raw| {
            const line = std.mem.trim(u8, raw, " \t\r");
            if (line.len == 0 or line[0] == '#' or line[0] == ';') continue;
            return line;
        }
        return null;
    }
};

/// Only refresh/brightness use this exact unsigned/error contract. Layout
/// and color intentionally retain their different numeric acceptance/errors.
pub fn unsignedNumber(comptime T: type, fields: *std.mem.SplitIterator(u8, .scalar), base: u8) error{ Format, Invalid }!T {
    const field = fields.next() orelse return error.Format;
    if (field.len == 0 or field[0] == '+' or field[0] == '-') return error.Invalid;
    return std.fmt.parseInt(T, field, base) catch error.Invalid;
}
