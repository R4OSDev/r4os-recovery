const std = @import("std");
const contract = @import("r4u_manifest.zig");

pub const max_entries: usize = 192;
pub const max_bytes: usize = 64 * 1024;
pub const max_guest_formats: usize = 16;
pub const max_guest_extensions: usize = 32;
pub const max_guest_features: usize = 32;
pub const max_guest_probe_bytes: usize = 256 * 1024;
pub const subsystem_display_name_max_bytes: usize = 96;

pub const ModuleRole = enum {
    subsystem,

    fn text(self: ModuleRole) []const u8 {
        return @tagName(self);
    }

    fn parse(value: []const u8) ?ModuleRole {
        if (std.mem.eql(u8, value, "subsystem")) return .subsystem;
        return null;
    }
};

pub const Profile = enum {
    slim,
    full,
    test_image,

    pub fn text(self: Profile) []const u8 {
        return switch (self) {
            .slim => "slim",
            .full => "full",
            .test_image => "test",
        };
    }

    fn parse(value: []const u8) ?Profile {
        if (std.mem.eql(u8, value, "slim")) return .slim;
        if (std.mem.eql(u8, value, "full")) return .full;
        if (std.mem.eql(u8, value, "test")) return .test_image;
        return null;
    }
};

pub const Entry = struct {
    name: []const u8,
    kind: contract.ComponentKind,
    version: []const u8,
    target: []const u8,
    module_role: ?ModuleRole = null,
    subsystem_id: ?[]const u8 = null,
    subsystem_display_name: ?[]const u8 = null,
    guest_formats: [max_guest_formats][]const u8 = undefined,
    guest_format_count: usize = 0,
    guest_extensions: [max_guest_extensions][]const u8 = undefined,
    guest_extension_count: usize = 0,
    guest_features: [max_guest_features][]const u8 = undefined,
    guest_feature_count: usize = 0,

    pub fn guestFormatSlice(self: *const Entry) []const []const u8 {
        return self.guest_formats[0..self.guest_format_count];
    }

    pub fn guestExtensionSlice(self: *const Entry) []const []const u8 {
        return self.guest_extensions[0..self.guest_extension_count];
    }

    pub fn guestFeatureSlice(self: *const Entry) []const []const u8 {
        return self.guest_features[0..self.guest_feature_count];
    }
};

pub const Inventory = struct {
    profile: Profile = .full,
    entries: [max_entries]Entry = undefined,
    count: usize = 0,

    pub fn parse(bytes: []const u8, out: *Inventory) bool {
        out.* = .{};
        var scanner = Scanner{ .bytes = stripBom(bytes) };
        if (!scanner.take('{') or !scanner.key("schema")) return false;
        const schema = scanner.number() orelse return false;
        if ((schema != 2 and schema != 3 and schema != 4) or
            !scanner.comma() or !scanner.key("profile")) return false;
        const profile_text = scanner.string() orelse return false;
        out.profile = Profile.parse(profile_text) orelse return false;
        if (!scanner.comma() or !scanner.key("count")) return false;
        const declared_count = scanner.number() orelse return false;
        if (declared_count > max_entries or !scanner.comma() or
            !scanner.key("entries") or !scanner.take('[')) return false;

        while (!scanner.peek(']')) {
            if (out.count >= max_entries or !parseEntry(&scanner, &out.entries[out.count], schema)) return false;
            out.count += 1;
            if (scanner.peek(']')) break;
            if (!scanner.comma()) return false;
        }
        if (!scanner.take(']') or !scanner.take('}') or !scanner.done()) return false;
        if (declared_count != out.count) return false;
        return out.validate();
    }

    pub fn upsert(self: *Inventory, replacement: Entry) bool {
        if (!validEntry(replacement)) return false;
        var target_match: ?usize = null;
        var identity_match: ?usize = null;
        for (self.entries[0..self.count], 0..) |entry, index| {
            if (contract.targetEquals(entry.target, replacement.target)) target_match = index;
            if (entry.kind == replacement.kind and std.ascii.eqlIgnoreCase(entry.name, replacement.name)) identity_match = index;
        }
        if (target_match) |index| {
            if (identity_match != null and identity_match.? != index) return false;
            const old = self.entries[index];
            if (old.kind != replacement.kind or !std.ascii.eqlIgnoreCase(old.name, replacement.name)) return false;
            var updated = replacement;
            if (updated.module_role == null and old.module_role != null) copyRoleMetadata(&updated, old);
            if (!validEntry(updated) or subsystemIdUsedByOther(self, updated, index)) return false;
            self.entries[index] = updated;
            return true;
        }
        if (identity_match != null or self.count >= max_entries or subsystemIdUsedByOther(self, replacement, null)) return false;
        self.entries[self.count] = replacement;
        self.count += 1;
        return true;
    }

    pub fn removeExact(self: *Inventory, kind: contract.ComponentKind, name: []const u8, target: []const u8) bool {
        if (!self.validate() or self.count <= 1) return false;
        var found: ?usize = null;
        for (self.entries[0..self.count], 0..) |entry, index| {
            if (entry.kind == kind and std.ascii.eqlIgnoreCase(entry.name, name) and contract.targetEquals(entry.target, target)) {
                if (found != null) return false;
                found = index;
            }
        }
        const index = found orelse return false;
        var move = index;
        while (move + 1 < self.count) : (move += 1) self.entries[move] = self.entries[move + 1];
        self.count -= 1;
        return true;
    }

    pub fn render(self: *const Inventory, out: []u8) ?[]const u8 {
        if (!self.validate()) return null;
        var writer = Writer{ .out = out };
        if (!writer.text("{\n  \"schema\": 4,\n  \"profile\": ") or
            !writer.string(self.profile.text()) or
            !writer.text(",\n  \"count\": ") or
            !writer.unsigned(self.count) or
            !writer.text(",\n  \"entries\": [\n")) return null;
        for (self.entries[0..self.count], 0..) |entry, index| {
            if (!writer.text("    {\n      \"name\": ") or !writer.string(entry.name) or
                !writer.text(",\n      \"kind\": ") or !writer.string(entry.kind.text()) or
                !writer.text(",\n      \"version\": ") or !writer.string(entry.version) or
                !writer.text(",\n      \"target\": ") or !writer.string(entry.target) or
                !writer.text(",\n      \"module_role\": ") or !writer.optionalRole(entry.module_role) or
                !writer.text(",\n      \"subsystem_id\": ") or !writer.optionalString(entry.subsystem_id) or
                !writer.text(",\n      \"subsystem_display_name\": ") or !writer.optionalString(entry.subsystem_display_name) or
                !writer.text(",\n      \"guest_formats\": ") or !writer.stringArray(entry.guestFormatSlice()) or
                !writer.text(",\n      \"guest_extensions\": ") or !writer.stringArray(entry.guestExtensionSlice()) or
                !writer.text(",\n      \"guest_features\": ") or !writer.stringArray(entry.guestFeatureSlice()) or
                !writer.text("\n    }") or
                !writer.text(if (index + 1 == self.count) "\n" else ",\n")) return null;
        }
        if (!writer.text("  ]\n}\n")) return null;
        return out[0..writer.len];
    }

    fn validate(self: *const Inventory) bool {
        if (self.count == 0 or self.count > max_entries) return false;
        for (self.entries[0..self.count], 0..) |entry, index| {
            if (!validEntry(entry)) return false;
            for (self.entries[0..index]) |prior| {
                if (contract.targetEquals(entry.target, prior.target) or
                    (entry.kind == prior.kind and std.ascii.eqlIgnoreCase(entry.name, prior.name))) return false;
                if (entry.module_role == .subsystem and prior.module_role == .subsystem and
                    std.mem.eql(u8, entry.subsystem_id.?, prior.subsystem_id.?)) return false;
            }
        }
        return true;
    }
};

fn validEntry(entry: Entry) bool {
    if (!contract.validToken(entry.name, contract.component_name_max_bytes) or
        !contract.validSemanticVersion(entry.version)) return false;
    var canonical_buffer: [1024]u8 = undefined;
    const canonical = contract.canonicalInventoryTarget(canonical_buffer[0..], entry.target) orelse return false;
    if (!contract.targetEquals(canonical, entry.target)) return false;
    const kind_valid = switch (entry.kind) {
        .kernel => contract.targetEquals(entry.target, "/boot/r4os.elf") and std.ascii.eqlIgnoreCase(entry.name, "KERNEL"),
        .r4x => std.ascii.endsWithIgnoreCase(entry.target, ".R4X"),
        .r4l => std.ascii.endsWithIgnoreCase(entry.target, ".R4L"),
        .r4d => std.ascii.endsWithIgnoreCase(entry.target, ".R4D"),
        .r4p => std.ascii.endsWithIgnoreCase(entry.target, ".R4P"),
    };
    if (!kind_valid) return false;
    if (entry.module_role == null) {
        return entry.subsystem_id == null and entry.subsystem_display_name == null and entry.guest_format_count == 0 and
            entry.guest_extension_count == 0 and entry.guest_feature_count == 0;
    }
    if (entry.module_role != .subsystem or entry.kind != .r4x or entry.subsystem_id == null or entry.subsystem_display_name == null or entry.guest_format_count == 0 or
        entry.guest_format_count > max_guest_formats or entry.guest_extension_count > max_guest_extensions or
        entry.guest_feature_count > max_guest_features) return false;
    const subsystem_id = entry.subsystem_id.?;
    if (!validCanonicalId(subsystem_id, 63)) return false;
    if (!validDisplayName(entry.subsystem_display_name.?)) return false;
    var expected_buffer: [1024]u8 = undefined;
    const expected = std.fmt.bufPrint(expected_buffer[0..], "/R4OS/SUBSYSTEMS/{s}/{s}.R4X", .{ subsystem_id, entry.name }) catch return false;
    if (!contract.targetEquals(expected, entry.target)) return false;

    for (entry.guestFormatSlice(), 0..) |format_id, index| {
        if (!validCanonicalId(format_id, 63)) return false;
        for (entry.guestFormatSlice()[0..index]) |prior| if (std.mem.eql(u8, format_id, prior)) return false;
    }
    for (entry.guestExtensionSlice(), 0..) |mapping, index| {
        if (!validGuestMapping(entry.guestFormatSlice(), mapping, true)) return false;
        for (entry.guestExtensionSlice()[0..index]) |prior| if (std.mem.eql(u8, mapping, prior)) return false;
    }
    for (entry.guestFeatureSlice(), 0..) |mapping, index| {
        if (!validGuestMapping(entry.guestFormatSlice(), mapping, false)) return false;
        for (entry.guestFeatureSlice()[0..index]) |prior| if (std.mem.eql(u8, mapping, prior)) return false;
    }
    return true;
}

fn validCanonicalId(value: []const u8, max_len: usize) bool {
    if (value.len == 0 or value.len > max_len or !std.ascii.isAlphabetic(value[0]) or !std.ascii.isAlphanumeric(value[value.len - 1])) return false;
    for (value) |byte| {
        if (std.ascii.toLower(byte) != byte) return false;
        if (!std.ascii.isAlphanumeric(byte) and byte != '.' and byte != '_' and byte != '-') return false;
    }
    return true;
}

fn validDisplayName(value: []const u8) bool {
    if (value.len == 0 or value.len > subsystem_display_name_max_bytes or
        !std.unicode.utf8ValidateSlice(value) or
        !std.mem.eql(u8, value, std.mem.trim(u8, value, " \t"))) return false;
    for (value) |byte| if (byte < 0x20 or byte == 0x7f or byte == '"' or byte == '\\') return false;
    return true;
}

fn validGuestMapping(formats: []const []const u8, mapping: []const u8, extension: bool) bool {
    const colon = std.mem.indexOfScalar(u8, mapping, ':') orelse return false;
    if (colon == 0 or colon + 1 >= mapping.len or std.mem.indexOfScalar(u8, mapping[colon + 1 ..], ':') != null) return false;
    const format_id = mapping[0..colon];
    const value = mapping[colon + 1 ..];
    var declared = false;
    for (formats) |candidate| if (std.mem.eql(u8, candidate, format_id)) {
        declared = true;
        break;
    };
    if (!declared) return false;
    if (!extension) return validCanonicalId(value, 63) and validKnownGuestFeature(value);
    if (value.len < 2 or value.len > 16 or value[0] != '.' or !std.ascii.isAlphanumeric(value[1]) or !std.ascii.isAlphanumeric(value[value.len - 1])) return false;
    for (value[1..]) |byte| {
        if (std.ascii.toLower(byte) != byte) return false;
        if (!std.ascii.isAlphanumeric(byte) and byte != '.' and byte != '_' and byte != '-') return false;
    }
    return true;
}

fn validKnownGuestFeature(value: []const u8) bool {
    const magic_prefix = "probe.magic-v1.";
    if (std.mem.startsWith(u8, value, magic_prefix)) {
        const descriptor = value[magic_prefix.len..];
        const separator = std.mem.indexOfScalar(u8, descriptor, '.') orelse return false;
        const offset = parseProbeHexUnsigned(descriptor[0..separator]) orelse return false;
        const bytes = descriptor[separator + 1 ..];
        if (bytes.len < 2 or bytes.len > 32 or bytes.len % 2 != 0 or !validProbeHex(bytes)) return false;
        const byte_count = bytes.len / 2;
        return offset <= max_guest_probe_bytes and byte_count <= max_guest_probe_bytes - @as(usize, @intCast(offset));
    }
    const token_prefix = "probe.text-token-v1.";
    if (std.mem.startsWith(u8, value, token_prefix)) {
        const token = value[token_prefix.len..];
        if (token.len < 2 or token.len > 42 or token.len % 2 != 0 or !validProbeHex(token)) return false;
        var index: usize = 0;
        while (index < token.len) : (index += 2) {
            const byte = parseProbeHexByte(token[index .. index + 2]) orelse return false;
            if (byte < 0x21 or byte > 0x7e) return false;
        }
    }
    return true;
}

fn validProbeHex(value: []const u8) bool {
    for (value) |byte| if (probeHexNibble(byte) == null) return false;
    return true;
}

test "guest probe descriptors use the shared 256 KiB window" {
    try std.testing.expectEqual(@as(usize, 256 * 1024), max_guest_probe_bytes);
    try std.testing.expect(validKnownGuestFeature("probe.magic-v1.3ffff.00"));
    try std.testing.expect(!validKnownGuestFeature("probe.magic-v1.40000.00"));
}

fn parseProbeHexUnsigned(value: []const u8) ?u64 {
    if (value.len == 0 or value.len > 8) return null;
    var result: u64 = 0;
    for (value) |byte| {
        result = std.math.mul(u64, result, 16) catch return null;
        result = std.math.add(u64, result, probeHexNibble(byte) orelse return null) catch return null;
    }
    return result;
}

fn parseProbeHexByte(value: []const u8) ?u8 {
    if (value.len != 2) return null;
    return (probeHexNibble(value[0]) orelse return null) * 16 + (probeHexNibble(value[1]) orelse return null);
}

fn probeHexNibble(byte: u8) ?u8 {
    return switch (byte) {
        '0'...'9' => byte - '0',
        'a'...'f' => byte - 'a' + 10,
        'A'...'F' => byte - 'A' + 10,
        else => null,
    };
}

fn copyRoleMetadata(target: *Entry, source: Entry) void {
    target.module_role = source.module_role;
    target.subsystem_id = source.subsystem_id;
    target.subsystem_display_name = source.subsystem_display_name;
    target.guest_formats = source.guest_formats;
    target.guest_format_count = source.guest_format_count;
    target.guest_extensions = source.guest_extensions;
    target.guest_extension_count = source.guest_extension_count;
    target.guest_features = source.guest_features;
    target.guest_feature_count = source.guest_feature_count;
}

fn subsystemIdUsedByOther(inventory: *const Inventory, entry: Entry, excluded_index: ?usize) bool {
    if (entry.module_role != .subsystem) return false;
    for (inventory.entries[0..inventory.count], 0..) |prior, index| {
        if (excluded_index != null and excluded_index.? == index) continue;
        if (prior.module_role == .subsystem and std.mem.eql(u8, prior.subsystem_id.?, entry.subsystem_id.?)) return true;
    }
    return false;
}

fn parseEntry(scanner: *Scanner, entry: *Entry, schema: usize) bool {
    if (!scanner.take('{') or !scanner.key("name")) return false;
    const name = scanner.string() orelse return false;
    if (!scanner.comma() or !scanner.key("kind")) return false;
    const kind = contract.ComponentKind.parse(scanner.string() orelse return false) orelse return false;
    if (!scanner.comma() or !scanner.key("version")) return false;
    const version = scanner.string() orelse return false;
    if (!scanner.comma() or !scanner.key("target")) return false;
    const target = scanner.string() orelse return false;
    entry.* = .{ .name = name, .kind = kind, .version = version, .target = target };
    if (schema >= 3) {
        if (!scanner.comma() or !scanner.key("module_role")) return false;
        const role_text = scanner.optionalString();
        if (role_text) |value| {
            entry.module_role = ModuleRole.parse(value) orelse return false;
        } else if (!scanner.last_was_null) return false;
        if (!scanner.comma() or !scanner.key("subsystem_id")) return false;
        entry.subsystem_id = scanner.optionalString() orelse if (!scanner.last_was_null) return false else null;
        if (schema >= 4) {
            if (!scanner.comma() or !scanner.key("subsystem_display_name")) return false;
            entry.subsystem_display_name = scanner.optionalString() orelse if (!scanner.last_was_null) return false else null;
        } else if (entry.module_role == .subsystem) {
            entry.subsystem_display_name = entry.name;
        }
        if (!scanner.comma() or !scanner.key("guest_formats") or
            !scanner.stringArray(entry.guest_formats[0..], &entry.guest_format_count) or
            !scanner.comma() or !scanner.key("guest_extensions") or
            !scanner.stringArray(entry.guest_extensions[0..], &entry.guest_extension_count) or
            !scanner.comma() or !scanner.key("guest_features") or
            !scanner.stringArray(entry.guest_features[0..], &entry.guest_feature_count)) return false;
    }
    if (!scanner.take('}')) return false;
    return true;
}

const Scanner = struct {
    bytes: []const u8,
    pos: usize = 0,
    last_was_null: bool = false,

    fn skip(self: *Scanner) void {
        while (self.pos < self.bytes.len and std.ascii.isWhitespace(self.bytes[self.pos])) self.pos += 1;
    }

    fn take(self: *Scanner, expected: u8) bool {
        self.skip();
        if (self.pos >= self.bytes.len or self.bytes[self.pos] != expected) return false;
        self.pos += 1;
        return true;
    }

    fn peek(self: *Scanner, expected: u8) bool {
        self.skip();
        return self.pos < self.bytes.len and self.bytes[self.pos] == expected;
    }

    fn comma(self: *Scanner) bool {
        return self.take(',');
    }

    fn key(self: *Scanner, expected: []const u8) bool {
        const got = self.string() orelse return false;
        return std.mem.eql(u8, got, expected) and self.take(':');
    }

    fn string(self: *Scanner) ?[]const u8 {
        self.skip();
        if (self.pos >= self.bytes.len or self.bytes[self.pos] != '"') return null;
        self.pos += 1;
        const start = self.pos;
        while (self.pos < self.bytes.len and self.bytes[self.pos] != '"') : (self.pos += 1) {
            const byte = self.bytes[self.pos];
            if (byte == '\\' or byte < 0x20) return null;
        }
        if (self.pos >= self.bytes.len or !std.unicode.utf8ValidateSlice(self.bytes[start..self.pos])) return null;
        const value = self.bytes[start..self.pos];
        self.pos += 1;
        return value;
    }

    fn optionalString(self: *Scanner) ?[]const u8 {
        self.skip();
        self.last_was_null = false;
        if (self.pos + 4 <= self.bytes.len and std.mem.eql(u8, self.bytes[self.pos .. self.pos + 4], "null")) {
            self.pos += 4;
            self.last_was_null = true;
            return null;
        }
        return self.string();
    }

    fn stringArray(self: *Scanner, values: [][]const u8, count: *usize) bool {
        count.* = 0;
        if (!self.take('[')) return false;
        while (!self.peek(']')) {
            if (count.* >= values.len) return false;
            values[count.*] = self.string() orelse return false;
            count.* += 1;
            if (self.peek(']')) break;
            if (!self.comma()) return false;
        }
        return self.take(']');
    }

    fn number(self: *Scanner) ?usize {
        self.skip();
        const start = self.pos;
        var value: usize = 0;
        while (self.pos < self.bytes.len and std.ascii.isDigit(self.bytes[self.pos])) : (self.pos += 1) {
            value = std.math.mul(usize, value, 10) catch return null;
            value = std.math.add(usize, value, self.bytes[self.pos] - '0') catch return null;
        }
        if (self.pos == start) return null;
        return value;
    }

    fn done(self: *Scanner) bool {
        self.skip();
        return self.pos == self.bytes.len;
    }
};

const Writer = struct {
    out: []u8,
    len: usize = 0,

    fn text(self: *Writer, value: []const u8) bool {
        if (value.len > self.out.len - self.len) return false;
        @memcpy(self.out[self.len .. self.len + value.len], value);
        self.len += value.len;
        return true;
    }

    fn string(self: *Writer, value: []const u8) bool {
        return self.text("\"") and self.text(value) and self.text("\"");
    }

    fn optionalString(self: *Writer, value: ?[]const u8) bool {
        if (value) |text_value| return self.string(text_value);
        return self.text("null");
    }

    fn optionalRole(self: *Writer, value: ?ModuleRole) bool {
        if (value) |role| return self.string(role.text());
        return self.text("null");
    }

    fn stringArray(self: *Writer, values: []const []const u8) bool {
        if (!self.text("[")) return false;
        for (values, 0..) |value, index| {
            if (index != 0 and !self.text(", ")) return false;
            if (!self.string(value)) return false;
        }
        return self.text("]");
    }

    fn unsigned(self: *Writer, value: usize) bool {
        var buffer: [24]u8 = undefined;
        const rendered = std.fmt.bufPrint(buffer[0..], "{d}", .{value}) catch return false;
        return self.text(rendered);
    }
};

fn stripBom(bytes: []const u8) []const u8 {
    if (bytes.len >= 3 and bytes[0] == 0xEF and bytes[1] == 0xBB and bytes[2] == 0xBF) return bytes[3..];
    return bytes;
}

const fixture =
    \\{
    \\  "schema": 2,
    \\  "profile": "slim",
    \\  "count": 2,
    \\  "entries": [
    \\    {
    \\      "name": "KERNEL",
    \\      "kind": "KERNEL",
    \\      "version": "0.1.0",
    \\      "target": "/boot/r4os.elf"
    \\    },
    \\    {
    \\      "name": "TERMINAL",
    \\      "kind": "R4X",
    \\      "version": "0.1.3",
    \\      "target": "/R4OS/SOFTWARE/TERMINAL/TERMINAL.R4X"
    \\    }
    \\  ]
    \\}
;

const subsystem_fixture =
    \\{
    \\  "schema": 3,
    \\  "profile": "test",
    \\  "count": 2,
    \\  "entries": [
    \\    {
    \\      "name": "KERNEL",
    \\      "kind": "KERNEL",
    \\      "version": "0.66.0",
    \\      "target": "/boot/r4os.elf",
    \\      "module_role": null,
    \\      "subsystem_id": null,
    \\      "guest_formats": [],
    \\      "guest_extensions": [],
    \\      "guest_features": []
    \\    },
    \\    {
    \\      "name": "QBASIC",
    \\      "kind": "R4X",
    \\      "version": "0.66.0",
    \\      "target": "/R4OS/SUBSYSTEMS/basic.qbasic/QBASIC.R4X",
    \\      "module_role": "subsystem",
    \\      "subsystem_id": "basic.qbasic",
    \\      "guest_formats": ["basic.qbasic-source"],
    \\      "guest_extensions": ["basic.qbasic-source:.bas"],
    \\      "guest_features": ["basic.qbasic-source:text.source"]
    \\    }
    \\  ]
    \\}
;

test "inventory update preserves profile and takes exact artifact versions" {
    var inventory: Inventory = undefined;
    try std.testing.expect(Inventory.parse(fixture, &inventory));
    try std.testing.expectEqual(Profile.slim, inventory.profile);
    try std.testing.expect(inventory.upsert(.{
        .name = "TERMINAL",
        .kind = .r4x,
        .version = "0.0.1",
        .target = "/R4OS/SOFTWARE/TERMINAL/TERMINAL.R4X",
    }));
    try std.testing.expect(inventory.upsert(.{
        .name = "R4SYS",
        .kind = .r4l,
        .version = "0.1.1",
        .target = "/R4OS/LIBS/R4STD.R4L",
    }));
    var rendered: [4096]u8 = undefined;
    const text = inventory.render(rendered[0..]).?;
    var reparsed: Inventory = undefined;
    try std.testing.expect(Inventory.parse(text, &reparsed));
    try std.testing.expectEqual(Profile.slim, reparsed.profile);
    try std.testing.expectEqual(@as(usize, 3), reparsed.count);
    try std.testing.expectEqualStrings("0.0.1", reparsed.entries[1].version);
}

test "inventory rejects drifted count and unknown profile" {
    var inventory: Inventory = undefined;
    const bad_count = try std.mem.replaceOwned(u8, std.testing.allocator, fixture, "\"count\": 2", "\"count\": 1");
    defer std.testing.allocator.free(bad_count);
    try std.testing.expect(!Inventory.parse(bad_count, &inventory));
    const bad_profile = try std.mem.replaceOwned(u8, std.testing.allocator, fixture, "\"slim\"", "\"other\"");
    defer std.testing.allocator.free(bad_profile);
    try std.testing.expect(!Inventory.parse(bad_profile, &inventory));
}

test "schema 3 migrates subsystem metadata and preserves it across ordinary package update" {
    var inventory: Inventory = undefined;
    try std.testing.expect(Inventory.parse(subsystem_fixture, &inventory));
    try std.testing.expectEqual(Profile.test_image, inventory.profile);
    try std.testing.expectEqual(ModuleRole.subsystem, inventory.entries[1].module_role.?);
    try std.testing.expectEqualStrings("basic.qbasic", inventory.entries[1].subsystem_id.?);
    try std.testing.expectEqualStrings("QBASIC", inventory.entries[1].subsystem_display_name.?);
    try std.testing.expectEqualStrings("basic.qbasic-source:.bas", inventory.entries[1].guestExtensionSlice()[0]);

    try std.testing.expect(inventory.upsert(.{
        .name = "QBASIC",
        .kind = .r4x,
        .version = "0.66.1",
        .target = "/R4OS/SUBSYSTEMS/basic.qbasic/QBASIC.R4X",
    }));
    try std.testing.expectEqual(ModuleRole.subsystem, inventory.entries[1].module_role.?);
    try std.testing.expectEqualStrings("0.66.1", inventory.entries[1].version);

    var rendered: [8192]u8 = undefined;
    const output = inventory.render(rendered[0..]).?;
    try std.testing.expect(std.mem.indexOf(u8, output, "\"schema\": 4") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "\"subsystem_display_name\": \"QBASIC\"") != null);
    var reparsed: Inventory = undefined;
    try std.testing.expect(Inventory.parse(output, &reparsed));
    try std.testing.expectEqualStrings("basic.qbasic-source:text.source", reparsed.entries[1].guestFeatureSlice()[0]);
}

test "schema 3 rejects noncanonical subsystem data" {
    var inventory: Inventory = undefined;
    const uppercase_extension = try std.mem.replaceOwned(u8, std.testing.allocator, subsystem_fixture, ".bas", ".BAS");
    defer std.testing.allocator.free(uppercase_extension);
    try std.testing.expect(!Inventory.parse(uppercase_extension, &inventory));

    const wrong_target = try std.mem.replaceOwned(u8, std.testing.allocator, subsystem_fixture, "/R4OS/SUBSYSTEMS/basic.qbasic/QBASIC.R4X", "/R4OS/SOFTWARE/QBASIC.R4X");
    defer std.testing.allocator.free(wrong_target);
    try std.testing.expect(!Inventory.parse(wrong_target, &inventory));
}
