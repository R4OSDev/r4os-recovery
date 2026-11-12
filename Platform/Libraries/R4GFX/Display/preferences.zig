//! Stable monitor preferences. Runtime output/head generations are never
//! persisted, and an unidentified receiver cannot inherit another's settings.
const std = @import("std");
const topology = @import("topology.zig");
const document = @import("document_text.zig");
pub const path = "C:\\R4OS\\CONFIG\\DISPLAYS.R4S";
pub const capacity = 16;
pub const max_bytes = 4096;
pub const Error = topology.Error || error{ Format, UnknownReceiver, Buffer, Number };
pub const Config = struct {
    values: [capacity]topology.Output = @splat(.{ .key = .{}, .view = .{ .pixel_w = 0, .pixel_h = 0 } }),
    count: usize = 0,

    pub fn find(self: *const Config, key: topology.Key) ?topology.Output {
        if (!key.persistable()) return null;
        for (self.values[0..self.count]) |value| if (std.meta.eql(value.key, key)) return value;
        return null;
    }
    /// Preserve preferences for absent monitors. A full store is a reported
    /// save failure, never silent eviction of a different receiver's record.
    pub fn remember(self: *const Config, layout: *const topology.Layout) Error!Config {
        var next = self.*;
        for (layout.outputs[0..layout.count]) |value| {
            if (!value.key.persistable()) return error.UnknownReceiver;
            try valid(value);
        }
        for (next.values[0..next.count]) |*value| value.primary = false;
        for (layout.outputs[0..layout.count]) |value| {
            const index = for (next.values[0..next.count], 0..) |old, i| {
                if (std.meta.eql(old.key, value.key)) break i;
            } else blk: {
                if (next.count == capacity) return error.Capacity;
                next.count += 1; break :blk next.count - 1;
            };
            next.values[index] = value;
        }
        return next;
    }
    pub fn parse(bytes: []const u8) Error!Config {
        if (bytes.len > max_bytes) return error.Buffer;
        var result: Config = .{};
        var lines = document.Lines.init(bytes);
        var format = false; var schema = false;
        while (lines.next()) |line| {
            if (std.mem.eql(u8, line, "R4S_FORMAT=1")) { if (format) return error.Format; format = true; continue; }
            if (std.mem.eql(u8, line, "SCHEMA=GFX_OUTPUTS_1")) { if (schema) return error.Format; schema = true; continue; }
            if (!format or !schema or !std.mem.startsWith(u8, line, "OUTPUT=")) return error.Format;
            if (result.count == capacity) return error.Capacity;
            var fields = std.mem.splitScalar(u8, line[7..], ',');
            var value: topology.Output = .{ .key = .{}, .view = .{ .pixel_w = 0, .pixel_h = 0 } };
            value.key.adapter = try number(u64, &fields, 16);
            value.key.connector = try number(u32, &fields, 10);
            const receiver = fields.next() orelse return error.Format;
            if (receiver.len != 32) return error.Format;
            _ = std.fmt.hexToBytes(&value.key.receiver, receiver) catch return error.Format;
            value.view.origin.x = try number(i32, &fields, 10);
            value.view.origin.y = try number(i32, &fields, 10);
            value.view.pixel_w = try number(u32, &fields, 10);
            value.view.pixel_h = try number(u32, &fields, 10);
            value.view.scale = try number(u32, &fields, 10);
            value.view.rotation = @enumFromInt(try number(u2, &fields, 10));
            value.refresh_millihz = try number(u32, &fields, 10);
            const flags = try number(u2, &fields, 10);
            value.enabled = flags & 1 != 0; value.primary = flags & 2 != 0;
            value.clone_group = try number(u8, &fields, 10);
            if (fields.next() != null) return error.Format;
            try valid(value);
            for (result.values[0..result.count]) |old| if (std.meta.eql(old.key, value.key)) return error.Duplicate;
            result.values[result.count] = value; result.count += 1;
        }
        if (!format or !schema) return error.Format;
        return result;
    }
    pub fn encode(self: *const Config, buffer: []u8) Error![]const u8 {
        if (self.count > capacity) return error.Capacity;
        const header = "\xef\xbb\xbfR4S_FORMAT=1\r\nSCHEMA=GFX_OUTPUTS_1\r\n";
        if (buffer.len < header.len) return error.Buffer;
        @memcpy(buffer[0..header.len], header);
        var used = header.len;
        for (self.values[0..self.count], 0..) |value, i| {
            try valid(value);
            for (self.values[0..i]) |old| if (std.meta.eql(old.key, value.key)) return error.Duplicate;
            const hex = std.fmt.bytesToHex(value.key.receiver, .lower);
            const line = std.fmt.bufPrint(buffer[used..], "OUTPUT={x:0>16},{d},{s},{d},{d},{d},{d},{d},{d},{d},{d},{d}\r\n",
                .{ value.key.adapter, value.key.connector, hex, value.view.origin.x, value.view.origin.y,
                    value.view.pixel_w, value.view.pixel_h, value.view.scale, @intFromEnum(value.view.rotation),
                    value.refresh_millihz, @as(u32, @intFromBool(value.enabled)) | (@as(u32, @intFromBool(value.primary)) << 1), value.clone_group })
                catch return error.Buffer;
            used += line.len;
        }
        if (used > max_bytes) return error.Buffer;
        return buffer[0..used];
    }
};
fn valid(value: topology.Output) Error!void {
    if (!value.key.persistable()) return error.UnknownReceiver;
    if (value.refresh_millihz > 1_000_000 or (value.primary and !value.enabled)) return error.Invalid;
    try value.view.validate();
}
fn number(comptime T: type, fields: *std.mem.SplitIterator(u8, .scalar), base: u8) Error!T {
    const text = fields.next() orelse return error.Format;
    if (text.len == 0 or std.mem.trim(u8, text, " \t\r").len != text.len) return error.Number;
    return std.fmt.parseInt(T, text, base) catch return error.Number;
}
