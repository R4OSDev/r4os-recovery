//! Per-monitor color choices. Profile paths and calibration preferences are
//! tied to a stable receiver key; connection generations are never persisted.
const std = @import("std");
const paths = @import("r4os").path;
const a = @import("r4os").abi;
const color = @import("color_signal.zig");
const topology = @import("topology.zig");
const document = @import("document_text.zig");
pub const path = "C:\\R4OS\\CONFIG\\COLORS.R4S";
pub const capacity = 16;
pub const max_bytes = 8192;
pub const Error = error{ Format, Invalid, Buffer, Capacity, Duplicate, UnknownReceiver };
pub const sdr: a.GfxColorSignal = .{ .format = a.gfx_buffer_format_xrgb8888, .bpc = 8, .primaries = 1, .transfer = 1, .range = 1,
    .pipeline = 7, .reference_white = 1_000_000, .peak = 1_000_000 };
pub const Choice = struct {
    key: topology.Key = .{},
    filename: [paths.file_path_max + 1]u8 = @splat(0),
    intent: u32 = 1,
    flags: u32 = 1, // COLOR_V1: black-point compensation1, profile VCGT2.
    signal: a.GfxColorSignal = sdr,
    pub fn enabled(self: *const Choice) bool { return self.filename[0] != 0; }
    pub fn profilePath(self: *const Choice) [*:0]const u8 { return @ptrCast(&self.filename); }
    pub fn setPath(self: *Choice, value: []const u8) Error!void {
        if (value.len > paths.file_path_max or std.mem.indexOfAny(u8, value, "\r\n\x00") != null) return error.Invalid;
        if (value.len != 0) _ = paths.AbsoluteFilePath.parse(value) catch return error.Invalid;
        @memset(&self.filename, 0);
        @memcpy(self.filename[0..value.len], value);
    }
    pub fn validate(self: *const Choice) Error!void {
        if (!self.key.persistable()) return error.UnknownReceiver;
        if (self.intent > 3 or self.flags & ~@as(u32, 3) != 0) return error.Invalid;
        _ = color.requestedSignal(self.signal) catch return error.Invalid;
        // ICC display profiles currently target the canonical SDR CPU path.
        if (self.enabled() and !std.meta.eql(self.signal, sdr)) return error.Invalid;
        const end = std.mem.indexOfScalar(u8, &self.filename, 0) orelse return error.Invalid;
        if (!std.mem.allEqual(u8, self.filename[end..], 0)) return error.Invalid;
        if (end != 0) {
            if (std.mem.indexOfAny(u8, self.filename[0..end], "\r\n") != null) return error.Invalid;
            _ = paths.AbsoluteFilePath.parse(self.filename[0..end]) catch return error.Invalid;
        }
    }
};
pub const Config = struct {
    choices: [capacity]Choice = @splat(.{}),
    count: usize = 0,
    pub fn find(self: *const Config, key: topology.Key) ?Choice {
        if (!key.persistable()) return null;
        for (self.choices[0..self.count]) |choice| if (std.meta.eql(key, choice.key)) return choice;
        return null;
    }
    pub fn remember(self: *const Config, choice: Choice) Error!Config {
        try choice.validate();
        var next = self.*;
        const slot = for (next.choices[0..next.count], 0..) |old, i| {
            if (std.meta.eql(old.key, choice.key)) break i;
        } else blk: {
            if (next.count == capacity) return error.Capacity;
            next.count += 1; break :blk next.count - 1;
        };
        next.choices[slot] = choice;
        return next;
    }
    pub fn parse(bytes: []const u8) Error!Config {
        if (bytes.len > max_bytes) return error.Buffer;
        var result: Config = .{};
        var lines = document.Lines.init(bytes);
        var format = false; var schema: u32 = 0;
        while (lines.next()) |line| {
            if (std.mem.eql(u8, line, "R4S_FORMAT=1")) { if (format) return error.Format; format = true; continue; }
            if (std.mem.eql(u8, line, "SCHEMA=GFX_COLOR_1") or std.mem.eql(u8, line, "SCHEMA=GFX_COLOR_2")) {
                if (schema != 0) return error.Format; schema = line[line.len - 1] - '0'; continue;
            }
            if (!format or schema == 0 or !std.mem.startsWith(u8, line, "DISPLAY=")) return error.Format;
            var fields = std.mem.splitScalar(u8, line[8..], ',');
            var choice: Choice = .{};
            choice.key.adapter = try number(u64, &fields, 16);
            choice.key.connector = try number(u32, &fields, 10);
            const receiver = fields.next() orelse return error.Format;
            if (receiver.len != 32) return error.Format;
            _ = std.fmt.hexToBytes(&choice.key.receiver, receiver) catch return error.Format;
            choice.intent = try number(u32, &fields, 10);
            choice.flags = try number(u32, &fields, 10);
            if (schema == 2) {
                inline for (.{ "format", "bpc", "primaries", "transfer", "range", "reference_white", "peak", "black" }) |field|
                    @field(choice.signal, field) = try number(u32, &fields, 10);
                const metadata = fields.next() orelse return error.Format;
                if (!std.mem.eql(u8, metadata, "NONE")) {
                    if (metadata.len != 48) return error.Format;
                    var values: [12]u16 = undefined;
                    for (&values, 0..) |*value, i| value.* = std.fmt.parseInt(u16, metadata[i * 4..][0..4], 16) catch return error.Invalid;
                    choice.signal.metadata_valid = 1;
                    choice.signal.metadata = .{ .primaries = values[0..6].*, .white = values[6..8].*,
                        .max_mastering = values[8], .min_mastering = values[9], .max_cll = values[10], .max_fall = values[11] };
                }
            }
            const filename = fields.rest(); // Last field permits commas in a filename.
            if (filename.len == 0) return error.Format;
            try choice.setPath(if (std.mem.eql(u8, filename, "NONE")) "" else filename);
            if (result.find(choice.key) != null) return error.Duplicate;
            result = try result.remember(choice);
        }
        if (!format or schema == 0) return error.Format;
        return result;
    }
    pub fn encode(self: *const Config, buffer: []u8) Error![]const u8 {
        if (self.count > capacity) return error.Capacity;
        const header = "\xef\xbb\xbfR4S_FORMAT=1\r\nSCHEMA=GFX_COLOR_2\r\n";
        if (buffer.len < header.len) return error.Buffer;
        @memcpy(buffer[0..header.len], header);
        var used = header.len;
        for (self.choices[0..self.count], 0..) |choice, i| {
            try choice.validate();
            for (self.choices[0..i]) |old| if (std.meta.eql(old.key, choice.key)) return error.Duplicate;
            const receiver = std.fmt.bytesToHex(choice.key.receiver, .lower);
            const signal = choice.signal;
            var metadata: [48]u8 = undefined;
            const m = signal.metadata;
            const values = m.primaries ++ m.white ++ [_]u16{ m.max_mastering, m.min_mastering, m.max_cll, m.max_fall };
            for (values, 0..) |value, index| _ = std.fmt.bufPrint(metadata[index * 4..][0..4], "{x:0>4}", .{value}) catch unreachable;
            const line = std.fmt.bufPrint(buffer[used..], "DISPLAY={x:0>16},{d},{s},{d},{d},{d},{d},{d},{d},{d},{d},{d},{d},{s},{s}\r\n",
                .{ choice.key.adapter, choice.key.connector, receiver, choice.intent, choice.flags,
                    signal.format, signal.bpc, signal.primaries, signal.transfer, signal.range, signal.reference_white, signal.peak, signal.black,
                    if (signal.metadata_valid != 0) @as([]const u8, &metadata) else "NONE",
                    if (choice.enabled()) std.mem.span(choice.profilePath()) else "NONE" }) catch return error.Buffer;
            used += line.len;
        }
        if (used > max_bytes) return error.Buffer;
        return buffer[0..used];
    }
};
fn number(comptime T: type, fields: *std.mem.SplitIterator(u8, .scalar), base: u8) Error!T {
    const value = fields.next() orelse return error.Format;
    return std.fmt.parseInt(T, value, base) catch error.Invalid;
}
