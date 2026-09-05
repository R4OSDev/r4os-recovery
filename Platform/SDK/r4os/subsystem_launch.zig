const std = @import("std");
const path_contract = @import("path.zig");

/// Subsystem hosts receive one opaque R4X argument string. The record lengths
/// keep guest paths and future options independent from shell quoting or token
/// splitting. Unknown option records are deliberately skippable.
pub const magic = "R4SUBSYS1";
pub const guest_key = "GUEST";
/// Optional VM-local BASIC command line. The host maps this record to
/// COMMAND$ without re-tokenizing or applying shell quoting.
pub const command_key = "C";
/// Optional repeatable `NAME=VALUE` record for a guest's initial environment.
pub const environment_key = "E";
/// Optional diagnostic records use short wire keys so the canonical DOS
/// guest path and a complete first-frame timeline still fit in the frozen
/// 127-byte R4X argument budget. Unknown records remain skippable.
pub const trace_key = "T";
pub const trace_mode_key = "M";
pub const trace_phases_key = "P";
pub const trace_mode_gui = "G";
pub const trace_mode_headless = "H";
pub const max_options: usize = 8;
pub const max_args_bytes: usize = 127;

pub const Option = struct {
    key: []const u8,
    value: []const u8,
};

pub const Request = struct {
    encoded: []const u8,
    guest_path: []const u8,
    option_count: usize,

    pub fn options(self: Request) OptionIterator {
        return .{ .remaining = self.encoded[magic.len..] };
    }

    pub fn option(self: Request, key: []const u8) Error!?[]const u8 {
        var iterator = self.options();
        while (try iterator.next()) |candidate| {
            if (std.ascii.eqlIgnoreCase(candidate.key, key)) return candidate.value;
        }
        return null;
    }
};

pub const Error = error{
    BufferTooSmall,
    InvalidMagic,
    MalformedRecord,
    InvalidKey,
    InvalidValue,
    InvalidGuestPath,
    MissingGuest,
    DuplicateGuest,
    TooManyOptions,
};

pub fn encode(guest_path: []const u8, options_value: []const Option, out: []u8) Error![]const u8 {
    try validateGuestPath(guest_path);
    if (options_value.len > max_options) return error.TooManyOptions;
    var writer = Writer{ .out = out[0..@min(out.len, max_args_bytes)] };
    try writer.append(magic);
    try writer.record(guest_key, guest_path);
    for (options_value) |option| {
        if (!validKey(option.key) or std.ascii.eqlIgnoreCase(option.key, guest_key)) return error.InvalidKey;
        for (option.value) |byte| if (byte == 0) return error.InvalidValue;
        try writer.record(option.key, option.value);
    }
    return out[0..writer.len];
}

pub fn parse(encoded: []const u8) Error!Request {
    if (encoded.len > max_args_bytes) return error.MalformedRecord;
    if (!std.mem.startsWith(u8, encoded, magic)) return error.InvalidMagic;
    var remaining = encoded[magic.len..];
    var guest: ?[]const u8 = null;
    var option_count: usize = 0;
    while (remaining.len != 0) {
        const parsed = try takeRecord(remaining);
        remaining = parsed.remaining;
        if (std.ascii.eqlIgnoreCase(parsed.option.key, guest_key)) {
            if (guest != null) return error.DuplicateGuest;
            try validateGuestPath(parsed.option.value);
            guest = parsed.option.value;
        } else {
            option_count += 1;
            if (option_count > max_options) return error.TooManyOptions;
        }
    }
    return .{
        .encoded = encoded,
        .guest_path = guest orelse return error.MissingGuest,
        .option_count = option_count,
    };
}

pub const OptionIterator = struct {
    remaining: []const u8,

    pub fn next(self: *OptionIterator) Error!?Option {
        while (self.remaining.len != 0) {
            const parsed = try takeRecord(self.remaining);
            self.remaining = parsed.remaining;
            if (!std.ascii.eqlIgnoreCase(parsed.option.key, guest_key)) return parsed.option;
        }
        return null;
    }
};

const ParsedRecord = struct {
    option: Option,
    remaining: []const u8,
};

fn takeRecord(encoded: []const u8) Error!ParsedRecord {
    if (encoded.len == 0 or encoded[0] != ';') return error.MalformedRecord;
    var remaining = encoded[1..];
    const key_len = try takeLength(&remaining);
    if (key_len == 0 or key_len > remaining.len) return error.MalformedRecord;
    const key = remaining[0..key_len];
    remaining = remaining[key_len..];
    if (!validKey(key) or remaining.len == 0 or remaining[0] != '=') return error.InvalidKey;
    remaining = remaining[1..];
    const value_len = try takeLength(&remaining);
    if (value_len > remaining.len) return error.MalformedRecord;
    const value = remaining[0..value_len];
    for (value) |byte| if (byte == 0) return error.InvalidValue;
    return .{ .option = .{ .key = key, .value = value }, .remaining = remaining[value_len..] };
}

fn takeLength(encoded: *[]const u8) Error!usize {
    var value: usize = 0;
    var digits: usize = 0;
    while (digits < encoded.*.len and encoded.*[digits] >= '0' and encoded.*[digits] <= '9') : (digits += 1) {
        value = std.math.mul(usize, value, 10) catch return error.MalformedRecord;
        value = std.math.add(usize, value, encoded.*[digits] - '0') catch return error.MalformedRecord;
    }
    if (digits == 0 or digits >= encoded.*.len or encoded.*[digits] != ':') return error.MalformedRecord;
    encoded.* = encoded.*[digits + 1 ..];
    return value;
}

fn validateGuestPath(path: []const u8) Error!void {
    _ = path_contract.AbsoluteFilePath.parse(path) catch return error.InvalidGuestPath;
}

fn validKey(key: []const u8) bool {
    if (key.len == 0 or key.len > 31 or !std.ascii.isAlphabetic(key[0])) return false;
    for (key) |byte| if (!std.ascii.isAlphanumeric(byte) and byte != '_' and byte != '-') return false;
    return true;
}

const Writer = struct {
    out: []u8,
    len: usize = 0,

    fn append(self: *Writer, value: []const u8) Error!void {
        if (value.len > self.out.len -| self.len) return error.BufferTooSmall;
        @memcpy(self.out[self.len .. self.len + value.len], value);
        self.len += value.len;
    }

    fn byte(self: *Writer, value: u8) Error!void {
        if (self.len >= self.out.len) return error.BufferTooSmall;
        self.out[self.len] = value;
        self.len += 1;
    }

    fn unsigned(self: *Writer, value: usize) Error!void {
        var storage: [24]u8 = undefined;
        const text = std.fmt.bufPrint(storage[0..], "{d}", .{value}) catch return error.BufferTooSmall;
        try self.append(text);
    }

    fn record(self: *Writer, key: []const u8, value: []const u8) Error!void {
        try self.byte(';');
        try self.unsigned(key.len);
        try self.byte(':');
        try self.append(key);
        try self.byte('=');
        try self.unsigned(value.len);
        try self.byte(':');
        try self.append(value);
    }
};

test "launch request preserves guest path bytes without shell quoting" {
    const guest = "C:\\Games and Tools\\A=B; C\\GORILLA.BAS";
    const options_value = [_]Option{
        .{ .key = "MODE", .value = "windowed; scale=2" },
        .{ .key = "PROFILE", .value = "QBasic" },
    };
    var storage: [max_args_bytes]u8 = undefined;
    const encoded = try encode(guest, &options_value, storage[0..]);
    const request = try parse(encoded);
    try std.testing.expectEqualStrings(guest, request.guest_path);
    try std.testing.expectEqual(@as(usize, 2), request.option_count);
    var iterator = request.options();
    const mode = (try iterator.next()).?;
    try std.testing.expectEqualStrings("MODE", mode.key);
    try std.testing.expectEqualStrings("windowed; scale=2", mode.value);
    try std.testing.expectEqualStrings("PROFILE", (try iterator.next()).?.key);
    try std.testing.expect((try iterator.next()) == null);
}

test "launch request rejects malformed duplicate and oversized inputs" {
    try std.testing.expectError(error.InvalidMagic, parse("GORILLA.BAS"));
    try std.testing.expectError(error.MissingGuest, parse(magic));
    try std.testing.expectError(error.DuplicateGuest, parse(magic ++ ";5:GUEST=10:C:\\ONE.BAS;5:GUEST=10:C:\\TWO.BAS"));
    try std.testing.expectError(error.InvalidGuestPath, parse(magic ++ ";5:GUEST=12:relative.bas"));
    var tiny: [12]u8 = undefined;
    try std.testing.expectError(error.BufferTooSmall, encode("C:\\GORILLA.BAS", &.{}, tiny[0..]));
}

test "diagnostic launch options remain optional and addressable" {
    const options_value = [_]Option{
        .{ .key = trace_key, .value = "0123456789ABCDEF" },
        .{ .key = trace_mode_key, .value = trace_mode_headless },
        .{ .key = trace_phases_key, .value = "12,34,56" },
    };
    var storage: [max_args_bytes]u8 = undefined;
    const request = try parse(try encode("C:\\TEMP\\GORILLA.BAS", &options_value, storage[0..]));
    try std.testing.expectEqualStrings("0123456789ABCDEF", (try request.option(trace_key)).?);
    try std.testing.expectEqualStrings(trace_mode_headless, (try request.option(trace_mode_key)).?);
    try std.testing.expectEqualStrings("12,34,56", (try request.option(trace_phases_key)).?);
    try std.testing.expect((try request.option("UNKNOWN")) == null);
}

test "command and repeated environment records remain byte exact" {
    const options_value = [_]Option{
        .{ .key = command_key, .value = "  /quiet Mixed Case" },
        .{ .key = environment_key, .value = "PATH=C:\\R4OS\\SOFTWARE" },
        .{ .key = environment_key, .value = "MODE=TEST" },
    };
    var storage: [max_args_bytes]u8 = undefined;
    const request = try parse(try encode("C:\\TEMP\\START.BAS", &options_value, storage[0..]));
    try std.testing.expectEqualStrings("  /quiet Mixed Case", (try request.option(command_key)).?);
    var iterator = request.options();
    _ = try iterator.next();
    try std.testing.expectEqualStrings("PATH=C:\\R4OS\\SOFTWARE", (try iterator.next()).?.value);
    try std.testing.expectEqualStrings("MODE=TEST", (try iterator.next()).?.value);
}
