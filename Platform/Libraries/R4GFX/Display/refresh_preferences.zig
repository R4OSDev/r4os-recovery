//! Stable per-receiver VRR choices. A reported flicker is saved as disabled;
//! a serial change records an explicit user choice, never a timing sample.
const std = @import("std");
const topology = @import("topology.zig");
const document = @import("document_text.zig");
const number = document.unsignedNumber;
pub const path = "C:\\R4OS\\CONFIG\\REFRESH.R4S";
pub const capacity = 16;
pub const max_bytes = 4096;
pub const Error = error{ Format, Invalid, Buffer, Capacity, Duplicate, Exhausted };
pub const Choice = struct {
    key: topology.Key = .{},
    policy: u32 = 1, // Fullscreen animation by default; idle desktops stay fixed.
    blocked: bool = false,
    serial: u64 = 0,
    pub fn validate(self: Choice) Error!void {
        if (!self.key.persistable() or self.policy > 2 or (self.blocked and self.policy != 0) or self.serial == 0) return error.Invalid;
    }
};
pub const Config = struct {
    choices: [capacity]Choice = @splat(.{}),
    count: usize = 0,
    pub fn find(self: *const Config, key: topology.Key) ?Choice {
        if (!key.persistable()) return null;
        for (self.choices[0..self.count]) |choice| if (std.meta.eql(choice.key, key)) return choice;
        return null;
    }
    pub fn change(self: *const Config, key: topology.Key, policy: u32, blocked: bool) Error!Config {
        const previous = self.find(key);
        const serial = std.math.add(u64, if (previous) |value| value.serial else 0, 1) catch return error.Exhausted;
        var next = self.*;
        const choice: Choice = .{ .key = key, .policy = policy, .blocked = blocked, .serial = serial };
        try choice.validate();
        for (next.choices[0..next.count]) |*value| if (std.meta.eql(value.key, key)) { value.* = choice; return next; };
        if (next.count == capacity) return error.Capacity;
        next.choices[next.count] = choice; next.count += 1;
        return next;
    }
    pub fn parse(bytes: []const u8) Error!Config {
        if (bytes.len > max_bytes) return error.Buffer;
        var lines = document.Lines.init(bytes);
        var result: Config = .{};
        var format = false; var schema = false;
        while (lines.next()) |line| {
            if (std.mem.eql(u8, line, "R4S_FORMAT=1")) { if (format) return error.Format; format = true; continue; }
            if (std.mem.eql(u8, line, "SCHEMA=GFX_REFRESH_1")) { if (schema) return error.Format; schema = true; continue; }
            if (!format or !schema or !std.mem.startsWith(u8, line, "DISPLAY=")) return error.Format;
            var fields = std.mem.splitScalar(u8, line[8..], ',');
            var choice: Choice = .{};
            choice.key.adapter = try number(u64, &fields, 16);
            choice.key.connector = try number(u32, &fields, 10);
            const receiver = fields.next() orelse return error.Format;
            if (receiver.len != choice.key.receiver.len * 2) return error.Invalid;
            _ = std.fmt.hexToBytes(&choice.key.receiver, receiver) catch return error.Invalid;
            choice.policy = try number(u32, &fields, 10);
            const blocked = try number(u32, &fields, 10);
            if (blocked > 1) return error.Invalid;
            choice.blocked = blocked == 1;
            choice.serial = try number(u64, &fields, 10);
            if (fields.next() != null) return error.Format;
            try choice.validate();
            if (result.find(choice.key) != null) return error.Duplicate;
            if (result.count == capacity) return error.Capacity;
            result.choices[result.count] = choice; result.count += 1;
        }
        if (!format or !schema) return error.Format;
        return result;
    }
    pub fn encode(self: *const Config, buffer: []u8) Error![]const u8 {
        if (self.count > capacity) return error.Capacity;
        const header = "\xef\xbb\xbfR4S_FORMAT=1\r\nSCHEMA=GFX_REFRESH_1\r\n";
        if (buffer.len < header.len) return error.Buffer;
        @memcpy(buffer[0..header.len], header);
        var used = header.len;
        for (self.choices[0..self.count], 0..) |choice, i| {
            try choice.validate();
            for (self.choices[0..i]) |old| if (std.meta.eql(old.key, choice.key)) return error.Duplicate;
            const receiver = std.fmt.bytesToHex(choice.key.receiver, .lower);
            const line = std.fmt.bufPrint(buffer[used..], "DISPLAY={x:0>16},{d},{s},{d},{d},{d}\r\n",
                .{choice.key.adapter, choice.key.connector, receiver, choice.policy, @intFromBool(choice.blocked), choice.serial}) catch return error.Buffer;
            used += line.len;
        }
        if (used > max_bytes) return error.Buffer;
        return buffer[0..used];
    }
};
