const std = @import("std");
const inventory_contract = @import("system_update_inventory.zig");

/// The installed module inventory is the only persistent truth. This module
/// projects its subsystem entries into a small, sorted runtime view instead of
/// maintaining a second registry that could become stale after an update.
pub const max_entries: usize = inventory_contract.max_entries;
pub const max_candidates: usize = 128;
pub const max_associations: usize = 64;
pub const max_probe_bytes: usize = inventory_contract.max_guest_probe_bytes;
pub const max_render_bytes: usize = 64 * 1024;

pub const HostState = enum {
    present,
    missing,
    failed,
};

pub const HostVerifier = struct {
    context: ?*anyopaque = null,
    check: *const fn (context: ?*anyopaque, host_path: []const u8) HostState,
};

pub fn assumeHostPresent(_: ?*anyopaque, _: []const u8) HostState {
    return .present;
}

pub const LoadError = error{
    InvalidInventory,
    TooManySubsystems,
    MissingHost,
    HostCheckFailed,
};

pub const Entry = struct {
    subsystem_id: []const u8,
    host_path: []const u8,
    display_name: []const u8,
    module_name: []const u8,
    module_version: []const u8,
    guest_formats: []const []const u8,
    guest_extensions: []const []const u8,
    guest_features: []const []const u8,

    pub fn supportsFormat(self: Entry, format_id: []const u8) bool {
        for (self.guest_formats) |candidate| if (std.ascii.eqlIgnoreCase(candidate, format_id)) return true;
        return false;
    }

    pub fn mapsExtension(self: Entry, format_id: []const u8, extension: []const u8) bool {
        for (self.guest_extensions) |mapping| {
            const split = splitMapping(mapping) orelse continue;
            if (std.mem.eql(u8, split.key, format_id) and std.ascii.eqlIgnoreCase(split.value, extension)) return true;
        }
        return false;
    }
};

pub const Catalog = struct {
    profile: inventory_contract.Profile = .full,
    entries: [max_entries]Entry = undefined,
    count: usize = 0,

    /// `inventory_workspace` must remain alive while `out` is used because the
    /// compact catalog keeps slices into its already validated fixed storage.
    pub fn loadInstalled(
        bytes: []const u8,
        inventory_workspace: *inventory_contract.Inventory,
        out: *Catalog,
        verifier: HostVerifier,
    ) LoadError!void {
        out.* = .{};
        if (!inventory_contract.Inventory.parse(bytes, inventory_workspace)) return error.InvalidInventory;
        try projectInstalled(inventory_workspace, out, verifier);
    }

    fn projectInstalled(
        inventory: *const inventory_contract.Inventory,
        out: *Catalog,
        verifier: HostVerifier,
    ) LoadError!void {
        out.* = .{ .profile = inventory.profile };
        errdefer out.* = .{};
        for (inventory.entries[0..inventory.count]) |*source| {
            if (source.module_role != .subsystem) continue;
            if (out.count >= max_entries) return error.TooManySubsystems;
            switch (verifier.check(verifier.context, source.target)) {
                .present => {},
                .missing => return error.MissingHost,
                .failed => return error.HostCheckFailed,
            }
            out.entries[out.count] = .{
                .subsystem_id = source.subsystem_id orelse return error.InvalidInventory,
                .host_path = source.target,
                .display_name = source.subsystem_display_name orelse return error.InvalidInventory,
                .module_name = source.name,
                .module_version = source.version,
                .guest_formats = source.guestFormatSlice(),
                .guest_extensions = source.guestExtensionSlice(),
                .guest_features = source.guestFeatureSlice(),
            };
            out.count += 1;
        }
        std.mem.sort(Entry, out.entries[0..out.count], {}, lessEntry);
    }

    pub fn render(self: *const Catalog, out: []u8) ?[]const u8 {
        var writer = Writer{ .out = out };
        if (!writer.text("{\n  \"schema\": 1,\n  \"source\": \"MODULES.JSON\",\n  \"profile\": ") or
            !writer.string(self.profile.text()) or
            !writer.text(",\n  \"count\": ") or
            !writer.unsigned(self.count) or
            !writer.text(",\n  \"entries\": [\n")) return null;
        for (self.entries[0..self.count], 0..) |entry, index| {
            if (!writer.text("    {\n      \"subsystem_id\": ") or !writer.string(entry.subsystem_id) or
                !writer.text(",\n      \"host_path\": ") or !writer.string(entry.host_path) or
                !writer.text(",\n      \"display_name\": ") or !writer.string(entry.display_name) or
                !writer.text(",\n      \"module_name\": ") or !writer.string(entry.module_name) or
                !writer.text(",\n      \"module_version\": ") or !writer.string(entry.module_version) or
                !writer.text(",\n      \"guest_formats\": ") or !writer.stringArray(entry.guest_formats) or
                !writer.text(",\n      \"guest_extensions\": ") or !writer.stringArray(entry.guest_extensions) or
                !writer.text(",\n      \"guest_features\": ") or !writer.stringArray(entry.guest_features) or
                !writer.text("\n    }") or
                !writer.text(if (index + 1 == self.count) "\n" else ",\n")) return null;
        }
        if (!writer.text("  ]\n}\n")) return null;
        return out[0..writer.len];
    }
};

fn lessEntry(_: void, a: Entry, b: Entry) bool {
    const by_id = std.mem.order(u8, a.subsystem_id, b.subsystem_id);
    if (by_id != .eq) return by_id == .lt;
    return std.mem.order(u8, a.host_path, b.host_path) == .lt;
}

pub const Association = struct {
    extension: []const u8,
    subsystem_id: []const u8,
    format_id: []const u8,
};

pub const Policy = struct {
    user_associations: []const Association = &.{},
    default_associations: []const Association = &.{},
};

pub const Input = struct {
    path: []const u8,
    probe_prefix: []const u8,
    file_size: u64,
    /// True only when `probe_prefix` contains min(file_size,
    /// max_probe_bytes) bytes. A shorter asynchronous read is not mistaken
    /// for a negative signature.
    probe_window_complete: bool,
};

pub const Evidence = enum {
    user_association,
    confirmed_probe,
    default_association,
    extension,
};

pub const Candidate = struct {
    subsystem_id: []const u8,
    format_id: []const u8,
    host_path: []const u8,
    display_name: []const u8,
    module_version: []const u8,
    evidence: Evidence,
    host_validation_required: bool = true,
};

pub const ResolutionState = enum {
    unknown,
    selected,
    ambiguous,
};

pub const Resolution = struct {
    state: ResolutionState = .unknown,
    candidates: [max_candidates]Candidate = undefined,
    count: usize = 0,

    pub fn slice(self: *const Resolution) []const Candidate {
        return self.candidates[0..self.count];
    }

    pub fn selected(self: *const Resolution) ?Candidate {
        if (self.state != .selected or self.count != 1) return null;
        return self.candidates[0];
    }
};

pub const ResolveError = error{
    InvalidInput,
    InvalidAssociation,
    StaleAssociation,
    TooManyCandidates,
};

pub fn resolve(catalog: *const Catalog, input: Input, policy: Policy, out: *Resolution) ResolveError!void {
    out.* = .{};
    if (!validInput(input)) return error.InvalidInput;
    try validateAssociations(policy.user_associations);
    try validateAssociations(policy.default_associations);
    const extension = pathExtension(input.path);

    if (try matchingAssociation(policy.user_associations, extension)) |association| {
        const candidate = associationCandidate(catalog, association, extension, false) orelse return error.StaleAssociation;
        try appendCandidate(out, withEvidence(candidate, .user_association));
        finishResolution(out);
        return;
    }

    for (catalog.entries[0..catalog.count]) |entry| {
        for (entry.guest_formats) |format_id| {
            if (probeState(entry, format_id, input) == .confirmed) {
                try appendCandidate(out, makeCandidate(entry, format_id, .confirmed_probe));
            }
        }
    }
    if (out.count != 0) {
        finishResolution(out);
        return;
    }

    if (try matchingAssociation(policy.default_associations, extension)) |association| {
        if (associationCandidate(catalog, association, extension, true)) |candidate| {
            const entry = findEntry(catalog, candidate.subsystem_id).?;
            if (probeState(entry, candidate.format_id, input) != .rejected) {
                try appendCandidate(out, withEvidence(candidate, .default_association));
                finishResolution(out);
                return;
            }
        } else return error.StaleAssociation;
    }

    if (extension.len != 0) for (catalog.entries[0..catalog.count]) |entry| {
        for (entry.guest_formats) |format_id| {
            if (!entry.mapsExtension(format_id, extension)) continue;
            if (probeState(entry, format_id, input) == .rejected) continue;
            try appendCandidate(out, makeCandidate(entry, format_id, .extension));
        }
    };
    finishResolution(out);
}

fn validInput(input: Input) bool {
    if (input.path.len == 0 or input.probe_prefix.len > max_probe_bytes or input.file_size < input.probe_prefix.len) return false;
    for (input.path) |byte| if (byte == 0 or byte < 0x20) return false;
    if (input.probe_window_complete) {
        const expected_u64 = @min(input.file_size, @as(u64, max_probe_bytes));
        if (input.probe_prefix.len != @as(usize, @intCast(expected_u64))) return false;
    }
    return true;
}

fn pathExtension(path: []const u8) []const u8 {
    var component_start: usize = 0;
    var dot: ?usize = null;
    for (path, 0..) |byte, index| {
        if (byte == '/' or byte == '\\') {
            component_start = index + 1;
            dot = null;
        } else if (byte == '.' and index >= component_start) {
            dot = index;
        }
    }
    const start = dot orelse return path[0..0];
    if (start + 1 >= path.len) return path[0..0];
    return path[start..];
}

fn validAssociationExtension(value: []const u8) bool {
    if (value.len < 2 or value.len > 16 or value[0] != '.' or !std.ascii.isAlphanumeric(value[1]) or !std.ascii.isAlphanumeric(value[value.len - 1])) return false;
    for (value[1..]) |byte| if (!std.ascii.isAlphanumeric(byte) and byte != '.' and byte != '_' and byte != '-') return false;
    return true;
}

fn validAssociationId(value: []const u8) bool {
    if (value.len == 0 or value.len > 63 or !std.ascii.isAlphabetic(value[0]) or !std.ascii.isAlphanumeric(value[value.len - 1])) return false;
    for (value) |byte| if (!std.ascii.isAlphanumeric(byte) and byte != '.' and byte != '_' and byte != '-') return false;
    return true;
}

fn validateAssociations(values: []const Association) ResolveError!void {
    if (values.len > max_associations) return error.InvalidAssociation;
    for (values, 0..) |value, index| {
        if (!validAssociationExtension(value.extension) or !validAssociationId(value.subsystem_id) or !validAssociationId(value.format_id)) return error.InvalidAssociation;
        for (values[0..index]) |prior| if (std.ascii.eqlIgnoreCase(value.extension, prior.extension)) return error.InvalidAssociation;
    }
}

fn matchingAssociation(values: []const Association, extension: []const u8) ResolveError!?Association {
    if (extension.len == 0) return null;
    var found: ?Association = null;
    for (values) |value| if (std.ascii.eqlIgnoreCase(value.extension, extension)) {
        if (found != null) return error.InvalidAssociation;
        found = value;
    };
    return found;
}

fn associationCandidate(catalog: *const Catalog, association: Association, extension: []const u8, require_extension: bool) ?Candidate {
    for (catalog.entries[0..catalog.count]) |entry| {
        if (!std.ascii.eqlIgnoreCase(entry.subsystem_id, association.subsystem_id)) continue;
        for (entry.guest_formats) |format_id| {
            if (!std.ascii.eqlIgnoreCase(format_id, association.format_id)) continue;
            if (require_extension and !entry.mapsExtension(format_id, extension)) return null;
            return makeCandidate(entry, format_id, .extension);
        }
    }
    return null;
}

fn findEntry(catalog: *const Catalog, subsystem_id: []const u8) ?Entry {
    for (catalog.entries[0..catalog.count]) |entry| if (std.ascii.eqlIgnoreCase(entry.subsystem_id, subsystem_id)) return entry;
    return null;
}

fn makeCandidate(entry: Entry, format_id: []const u8, evidence: Evidence) Candidate {
    return .{
        .subsystem_id = entry.subsystem_id,
        .format_id = format_id,
        .host_path = entry.host_path,
        .display_name = entry.display_name,
        .module_version = entry.module_version,
        .evidence = evidence,
    };
}

fn withEvidence(candidate: Candidate, evidence: Evidence) Candidate {
    var updated = candidate;
    updated.evidence = evidence;
    return updated;
}

fn appendCandidate(out: *Resolution, candidate: Candidate) ResolveError!void {
    for (out.candidates[0..out.count]) |prior| {
        if (std.mem.eql(u8, prior.subsystem_id, candidate.subsystem_id) and std.mem.eql(u8, prior.format_id, candidate.format_id)) return;
    }
    if (out.count >= max_candidates) return error.TooManyCandidates;
    out.candidates[out.count] = candidate;
    out.count += 1;
}

fn finishResolution(out: *Resolution) void {
    std.mem.sort(Candidate, out.candidates[0..out.count], {}, lessCandidate);
    out.state = if (out.count == 0) .unknown else if (out.count == 1) .selected else .ambiguous;
}

fn lessCandidate(_: void, a: Candidate, b: Candidate) bool {
    const by_subsystem = std.mem.order(u8, a.subsystem_id, b.subsystem_id);
    if (by_subsystem != .eq) return by_subsystem == .lt;
    return std.mem.order(u8, a.format_id, b.format_id) == .lt;
}

const ProbeState = enum {
    absent,
    confirmed,
    rejected,
    indeterminate,
};

fn probeState(entry: Entry, format_id: []const u8, input: Input) ProbeState {
    var recognized = false;
    var indeterminate = false;
    for (entry.guest_features) |mapping| {
        const split = splitMapping(mapping) orelse continue;
        if (!std.mem.eql(u8, split.key, format_id)) continue;
        const state = evaluateProbe(split.value, input) orelse continue;
        recognized = true;
        if (state == .confirmed) return .confirmed;
        if (state == .indeterminate) indeterminate = true;
    }
    if (!recognized) return .absent;
    return if (indeterminate) .indeterminate else .rejected;
}

fn evaluateProbe(feature: []const u8, input: Input) ?ProbeState {
    const magic_prefix = "probe.magic-v1.";
    if (std.mem.startsWith(u8, feature, magic_prefix)) {
        const descriptor = feature[magic_prefix.len..];
        const separator = std.mem.indexOfScalar(u8, descriptor, '.') orelse return null;
        const offset_text = descriptor[0..separator];
        const bytes_text = descriptor[separator + 1 ..];
        const offset = parseHexUnsigned(offset_text) orelse return null;
        if (bytes_text.len < 2 or bytes_text.len > 32 or bytes_text.len % 2 != 0) return null;
        const byte_count = bytes_text.len / 2;
        if (offset > max_probe_bytes or byte_count > max_probe_bytes - @as(usize, @intCast(offset))) return null;
        const end = offset + byte_count;
        if (end > input.file_size) return .rejected;
        if (end > input.probe_prefix.len) return if (input.probe_window_complete) .rejected else .indeterminate;
        const start: usize = @intCast(offset);
        var index: usize = 0;
        while (index < byte_count) : (index += 1) {
            const expected = parseHexByte(bytes_text[index * 2 .. index * 2 + 2]) orelse return null;
            if (input.probe_prefix[start + index] != expected) return .rejected;
        }
        return .confirmed;
    }

    const token_prefix = "probe.text-token-v1.";
    if (std.mem.startsWith(u8, feature, token_prefix)) {
        const token_hex = feature[token_prefix.len..];
        if (token_hex.len < 2 or token_hex.len > 42 or token_hex.len % 2 != 0) return null;
        const token_len = token_hex.len / 2;
        var token_index: usize = 0;
        while (token_index < token_len) : (token_index += 1) {
            const byte = parseHexByte(token_hex[token_index * 2 .. token_index * 2 + 2]) orelse return null;
            if (byte < 0x21 or byte > 0x7e) return null;
        }
        for (input.probe_prefix) |byte| {
            if (byte == 0 or (byte < 0x20 and byte != '\t' and byte != '\r' and byte != '\n' and byte != 0x0c)) return .rejected;
        }
        if (containsTextToken(input.probe_prefix, token_hex, token_len)) return .confirmed;
        return if (input.probe_window_complete) .rejected else .indeterminate;
    }
    return null;
}

fn containsTextToken(bytes: []const u8, token_hex: []const u8, token_len: usize) bool {
    if (token_len > bytes.len) return false;
    var start: usize = 0;
    while (start + token_len <= bytes.len) : (start += 1) {
        var matches = true;
        var index: usize = 0;
        while (index < token_len) : (index += 1) {
            const expected = parseHexByte(token_hex[index * 2 .. index * 2 + 2]) orelse return false;
            if (std.ascii.toLower(bytes[start + index]) != std.ascii.toLower(expected)) {
                matches = false;
                break;
            }
        }
        if (!matches) continue;
        const expected_first = parseHexByte(token_hex[0..2]) orelse return false;
        const expected_last = parseHexByte(token_hex[token_hex.len - 2 ..]) orelse return false;
        if (start != 0 and isWordByte(bytes[start - 1]) and isWordByte(expected_first)) continue;
        if (start + token_len < bytes.len and isWordByte(bytes[start + token_len]) and isWordByte(expected_last)) continue;
        return true;
    }
    return false;
}

fn isWordByte(byte: u8) bool {
    return std.ascii.isAlphanumeric(byte) or byte == '_';
}

fn parseHexUnsigned(text: []const u8) ?u64 {
    if (text.len == 0 or text.len > 8) return null;
    var result: u64 = 0;
    for (text) |byte| {
        result = std.math.mul(u64, result, 16) catch return null;
        result = std.math.add(u64, result, hexNibble(byte) orelse return null) catch return null;
    }
    return result;
}

fn parseHexByte(text: []const u8) ?u8 {
    if (text.len != 2) return null;
    return (hexNibble(text[0]) orelse return null) * 16 + (hexNibble(text[1]) orelse return null);
}

fn hexNibble(byte: u8) ?u8 {
    return switch (byte) {
        '0'...'9' => byte - '0',
        'a'...'f' => byte - 'a' + 10,
        'A'...'F' => byte - 'A' + 10,
        else => null,
    };
}

const Mapping = struct { key: []const u8, value: []const u8 };

fn splitMapping(mapping: []const u8) ?Mapping {
    const colon = std.mem.indexOfScalar(u8, mapping, ':') orelse return null;
    if (colon == 0 or colon + 1 >= mapping.len) return null;
    return .{ .key = mapping[0..colon], .value = mapping[colon + 1 ..] };
}

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
        if (!self.text("\"")) return false;
        for (value) |character| switch (character) {
            '"' => if (!self.text("\\\"")) return false,
            '\\' => if (!self.text("\\\\")) return false,
            '\n' => if (!self.text("\\n")) return false,
            '\r' => if (!self.text("\\r")) return false,
            '\t' => if (!self.text("\\t")) return false,
            else => {
                if (character < 0x20 or !self.byte(character)) return false;
            },
        };
        return self.text("\"");
    }

    fn byte(self: *Writer, value: u8) bool {
        if (self.len >= self.out.len) return false;
        self.out[self.len] = value;
        self.len += 1;
        return true;
    }

    fn unsigned(self: *Writer, value: usize) bool {
        var buffer: [32]u8 = undefined;
        const rendered = std.fmt.bufPrint(buffer[0..], "{d}", .{value}) catch return false;
        return self.text(rendered);
    }

    fn stringArray(self: *Writer, values: []const []const u8) bool {
        if (!self.text("[")) return false;
        for (values, 0..) |value, index| {
            if (index != 0 and !self.text(", ")) return false;
            if (!self.string(value)) return false;
        }
        return self.text("]");
    }
};

const catalog_fixture =
    \\{
    \\  "schema": 4,
    \\  "profile": "test",
    \\  "count": 5,
    \\  "entries": [
    \\    {
    \\      "name": "KERNEL",
    \\      "kind": "KERNEL",
    \\      "version": "0.1.0",
    \\      "target": "/boot/r4os.elf",
    \\      "module_role": null,
    \\      "subsystem_id": null,
    \\      "subsystem_display_name": null,
    \\      "guest_formats": [],
    \\      "guest_extensions": [],
    \\      "guest_features": []
    \\    },
    \\    {
    \\      "name": "BASICA",
    \\      "kind": "R4X",
    \\      "version": "0.66.1",
    \\      "target": "/R4OS/SUBSYSTEMS/basic.a/BASICA.R4X",
    \\      "module_role": "subsystem",
    \\      "subsystem_id": "basic.a",
    \\      "subsystem_display_name": "BASIC Host A",
    \\      "guest_formats": ["basic.qbasic-source", "basic.tokenized"],
    \\      "guest_extensions": ["basic.qbasic-source:.bas", "basic.tokenized:.qb"],
    \\      "guest_features": ["basic.qbasic-source:probe.text-token-v1.7072696e74", "basic.tokenized:probe.magic-v1.0.5142544b"]
    \\    },
    \\    {
    \\      "name": "BASICB",
    \\      "kind": "R4X",
    \\      "version": "0.66.1",
    \\      "target": "/R4OS/SUBSYSTEMS/basic.b/BASICB.R4X",
    \\      "module_role": "subsystem",
    \\      "subsystem_id": "basic.b",
    \\      "subsystem_display_name": "BASIC Host B",
    \\      "guest_formats": ["basic.qbasic-source"],
    \\      "guest_extensions": ["basic.qbasic-source:.b2"],
    \\      "guest_features": ["basic.qbasic-source:probe.text-token-v1.636861696e"]
    \\    },
    \\    {
    \\      "name": "DOSHOST",
    \\      "kind": "R4X",
    \\      "version": "0.66.1",
    \\      "target": "/R4OS/SUBSYSTEMS/dos.mz/DOSHOST.R4X",
    \\      "module_role": "subsystem",
    \\      "subsystem_id": "dos.mz",
    \\      "subsystem_display_name": "DOS Host",
    \\      "guest_formats": ["dos.mz-executable"],
    \\      "guest_extensions": ["dos.mz-executable:.exe"],
    \\      "guest_features": ["dos.mz-executable:probe.magic-v1.0.4d5a"]
    \\    },
    \\    {
    \\      "name": "ROMHOST",
    \\      "kind": "R4X",
    \\      "version": "0.66.1",
    \\      "target": "/R4OS/SUBSYSTEMS/rom.snes/ROMHOST.R4X",
    \\      "module_role": "subsystem",
    \\      "subsystem_id": "rom.snes",
    \\      "subsystem_display_name": "ROM Host",
    \\      "guest_formats": ["rom.snes-image"],
    \\      "guest_extensions": ["rom.snes-image:.sfc"],
    \\      "guest_features": ["rom.snes-image:probe.magic-v1.0.534e4553"]
    \\    }
    \\  ]
    \\}
;

fn loadFixture(bytes: []const u8, inventory: *inventory_contract.Inventory, catalog: *Catalog) !void {
    try Catalog.loadInstalled(bytes, inventory, catalog, .{ .check = assumeHostPresent });
}

fn fixtureInput(path: []const u8, bytes: []const u8) Input {
    return .{ .path = path, .probe_prefix = bytes, .file_size = bytes.len, .probe_window_complete = true };
}

test "installed catalog projects complete sorted subsystem data deterministically" {
    var inventory: inventory_contract.Inventory = undefined;
    var catalog: Catalog = undefined;
    try loadFixture(catalog_fixture, &inventory, &catalog);
    try std.testing.expectEqual(@as(usize, 4), catalog.count);
    try std.testing.expectEqualStrings("basic.a", catalog.entries[0].subsystem_id);
    try std.testing.expectEqualStrings("BASIC Host A", catalog.entries[0].display_name);
    try std.testing.expectEqual(@as(usize, 2), catalog.entries[0].guest_formats.len);

    var first: [max_render_bytes]u8 = undefined;
    const first_text = catalog.render(first[0..]).?;
    const basic_entry = inventory.entries[1];
    inventory.entries[1] = inventory.entries[4];
    inventory.entries[4] = basic_entry;
    var reordered: Catalog = undefined;
    try Catalog.projectInstalled(&inventory, &reordered, .{ .check = assumeHostPresent });
    var second: [max_render_bytes]u8 = undefined;
    const second_text = reordered.render(second[0..]).?;
    try std.testing.expectEqualStrings(first_text, second_text);
}

test "resolver recognizes BASIC DOS and ROM fixtures without cross candidates" {
    var inventory: inventory_contract.Inventory = undefined;
    var catalog: Catalog = undefined;
    try loadFixture(catalog_fixture, &inventory, &catalog);
    const cases = [_]struct { path: []const u8, bytes: []const u8, subsystem: []const u8, format: []const u8 }{
        .{ .path = "C:/GAMES/basic.bas", .bytes = @embedFile("../Tests/Fixture/SubsystemResolver/basic.bas"), .subsystem = "basic.a", .format = "basic.qbasic-source" },
        .{ .path = "C:/GAMES/dos.exe", .bytes = @embedFile("../Tests/Fixture/SubsystemResolver/dos.exe"), .subsystem = "dos.mz", .format = "dos.mz-executable" },
        .{ .path = "C:/GAMES/rom.sfc", .bytes = @embedFile("../Tests/Fixture/SubsystemResolver/rom.sfc"), .subsystem = "rom.snes", .format = "rom.snes-image" },
    };
    for (cases) |case| {
        var result: Resolution = undefined;
        try resolve(&catalog, fixtureInput(case.path, case.bytes), .{}, &result);
        const selected = result.selected().?;
        try std.testing.expectEqualStrings(case.subsystem, selected.subsystem_id);
        try std.testing.expectEqualStrings(case.format, selected.format_id);
        try std.testing.expectEqual(Evidence.confirmed_probe, selected.evidence);
        try std.testing.expect(selected.host_validation_required);
    }
}

test "resolver returns stable ambiguity and honors user then default association" {
    const allocator = std.testing.allocator;
    const same_extension = try std.mem.replaceOwned(u8, allocator, catalog_fixture, "basic.qbasic-source:.b2", "basic.qbasic-source:.bas");
    defer allocator.free(same_extension);
    const same_probe = try std.mem.replaceOwned(u8, allocator, same_extension, "probe.text-token-v1.636861696e", "probe.text-token-v1.7072696e74");
    defer allocator.free(same_probe);
    var inventory: inventory_contract.Inventory = undefined;
    var catalog: Catalog = undefined;
    try loadFixture(same_probe, &inventory, &catalog);
    const basic = @embedFile("../Tests/Fixture/SubsystemResolver/basic.bas");

    var ambiguous: Resolution = undefined;
    try resolve(&catalog, fixtureInput("C:/GAMES/GORILLA.BAS", basic), .{}, &ambiguous);
    try std.testing.expectEqual(ResolutionState.ambiguous, ambiguous.state);
    try std.testing.expectEqualStrings("basic.a", ambiguous.candidates[0].subsystem_id);
    try std.testing.expectEqualStrings("basic.b", ambiguous.candidates[1].subsystem_id);

    const user = [_]Association{.{ .extension = ".bas", .subsystem_id = "basic.b", .format_id = "basic.qbasic-source" }};
    var chosen: Resolution = undefined;
    try resolve(&catalog, fixtureInput("C:/GAMES/GORILLA.BAS", basic), .{ .user_associations = &user }, &chosen);
    try std.testing.expectEqualStrings("basic.b", chosen.selected().?.subsystem_id);
    try std.testing.expectEqual(Evidence.user_association, chosen.selected().?.evidence);

    const defaults = [_]Association{.{ .extension = ".bas", .subsystem_id = "basic.a", .format_id = "basic.qbasic-source" }};
    const partial = Input{ .path = "C:/GAMES/PARTIAL.BAS", .probe_prefix = "REM", .file_size = 100, .probe_window_complete = false };
    try resolve(&catalog, partial, .{ .default_associations = &defaults }, &chosen);
    try std.testing.expectEqual(Evidence.default_association, chosen.selected().?.evidence);
}

test "resolver rejects disguised unknown and stale association states visibly" {
    var inventory: inventory_contract.Inventory = undefined;
    var catalog: Catalog = undefined;
    try loadFixture(catalog_fixture, &inventory, &catalog);
    const disguised = @embedFile("../Tests/Fixture/SubsystemResolver/disguised.exe");
    var result: Resolution = undefined;
    try resolve(&catalog, fixtureInput("C:/GAMES/FAKE.EXE", disguised), .{}, &result);
    try std.testing.expectEqual(ResolutionState.unknown, result.state);
    try resolve(&catalog, fixtureInput("C:/GAMES/BROKEN.EXE", "M"), .{}, &result);
    try std.testing.expectEqual(ResolutionState.unknown, result.state);
    try resolve(&catalog, fixtureInput("C:/GAMES/UNKNOWN.DAT", "unknown"), .{}, &result);
    try std.testing.expectEqual(ResolutionState.unknown, result.state);

    const stale = [_]Association{.{ .extension = ".bas", .subsystem_id = "missing.host", .format_id = "basic.qbasic-source" }};
    try std.testing.expectError(error.StaleAssociation, resolve(&catalog, fixtureInput("C:/GAMES/GORILLA.BAS", @embedFile("../Tests/Fixture/SubsystemResolver/basic.bas")), .{ .user_associations = &stale }, &result));
}

test "catalog rejects truncated manipulated and missing-host inventories" {
    var inventory: inventory_contract.Inventory = undefined;
    var catalog: Catalog = undefined;
    try std.testing.expectError(error.InvalidInventory, Catalog.loadInstalled(catalog_fixture[0 .. catalog_fixture.len - 2], &inventory, &catalog, .{ .check = assumeHostPresent }));

    const allocator = std.testing.allocator;
    const duplicate = try std.mem.replaceOwned(u8, allocator, catalog_fixture, "\"subsystem_id\": \"basic.b\"", "\"subsystem_id\": \"basic.a\"");
    defer allocator.free(duplicate);
    try std.testing.expectError(error.InvalidInventory, Catalog.loadInstalled(duplicate, &inventory, &catalog, .{ .check = assumeHostPresent }));
    const invalid_probe = try std.mem.replaceOwned(u8, allocator, catalog_fixture, "probe.magic-v1.0.4d5a", "probe.magic-v1.zz.4d5a");
    defer allocator.free(invalid_probe);
    try std.testing.expectError(error.InvalidInventory, Catalog.loadInstalled(invalid_probe, &inventory, &catalog, .{ .check = assumeHostPresent }));

    const Missing = struct {
        fn verify(_: ?*anyopaque, path: []const u8) HostState {
            return if (std.mem.indexOf(u8, path, "dos.mz") != null) .missing else .present;
        }
    };
    try std.testing.expectError(error.MissingHost, Catalog.loadInstalled(catalog_fixture, &inventory, &catalog, .{ .check = Missing.verify }));
}

test "catalog projection follows inventory update and exact removal" {
    var inventory: inventory_contract.Inventory = undefined;
    var catalog: Catalog = undefined;
    try loadFixture(catalog_fixture, &inventory, &catalog);
    try std.testing.expect(inventory.upsert(.{
        .name = "DOSHOST",
        .kind = .r4x,
        .version = "0.66.2",
        .target = "/R4OS/SUBSYSTEMS/dos.mz/DOSHOST.R4X",
    }));
    try Catalog.projectInstalled(&inventory, &catalog, .{ .check = assumeHostPresent });
    try std.testing.expectEqualStrings("0.66.2", findEntry(&catalog, "dos.mz").?.module_version);
    try std.testing.expect(inventory.removeExact(.r4x, "ROMHOST", "/R4OS/SUBSYSTEMS/rom.snes/ROMHOST.R4X"));
    try Catalog.projectInstalled(&inventory, &catalog, .{ .check = assumeHostPresent });
    try std.testing.expect(findEntry(&catalog, "rom.snes") == null);

    var installed: inventory_contract.Entry = .{
        .name = "ALTBASIC",
        .kind = .r4x,
        .version = "0.66.1",
        .target = "/R4OS/SUBSYSTEMS/basic.alt/ALTBASIC.R4X",
        .module_role = .subsystem,
        .subsystem_id = "basic.alt",
        .subsystem_display_name = "Alternative BASIC",
    };
    installed.guest_formats[0] = "basic.alt-source";
    installed.guest_format_count = 1;
    installed.guest_extensions[0] = "basic.alt-source:.bas";
    installed.guest_extension_count = 1;
    try std.testing.expect(inventory.upsert(installed));
    try Catalog.projectInstalled(&inventory, &catalog, .{ .check = assumeHostPresent });
    try std.testing.expect(findEntry(&catalog, "basic.alt") != null);
}
