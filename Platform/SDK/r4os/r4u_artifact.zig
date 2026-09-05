const std = @import("std");
pub const contract = @import("r4u_manifest.zig");

pub const name_capacity = contract.component_name_max_bytes + 1;
pub const version_capacity = contract.version_max_bytes + 1;

pub const Identity = struct {
    kind: contract.ComponentKind,
    name: [name_capacity]u8 = .{0} ** name_capacity,
    name_len: usize = 0,
    version: [version_capacity]u8 = .{0} ** version_capacity,
    version_len: usize = 0,

    pub fn nameText(self: *const Identity) []const u8 {
        return self.name[0..self.name_len];
    }

    pub fn versionText(self: *const Identity) []const u8 {
        return self.version[0..self.version_len];
    }
};

pub const SliceReader = struct {
    bytes: []const u8,

    pub fn readAt(self: SliceReader, offset: u64, out: []u8) bool {
        const start = std.math.cast(usize, offset) orelse return false;
        if (start > self.bytes.len or out.len > self.bytes.len - start) return false;
        @memcpy(out, self.bytes[start .. start + out.len]);
        return true;
    }
};

pub fn inspect(reader: anytype, size: u64) ?Identity {
    var magic: [4]u8 = undefined;
    if (size < magic.len or !reader.readAt(0, magic[0..])) return null;
    if (std.mem.eql(u8, magic[0..], "R4M0")) return inspectR4M0(reader, size);
    if (magic[0] == 0x7f and magic[1] == 'E' and magic[2] == 'L' and magic[3] == 'F') return inspectKernelElf(reader, size);
    return null;
}

fn inspectR4M0(reader: anytype, size: u64) ?Identity {
    var header: [64]u8 = undefined;
    if (!reader.readAt(0, header[0..]) or !std.mem.eql(u8, header[0..4], "R4M0")) return null;
    if (rU16(header[0..], 4) != 1 or rU16(header[0..], 10) != 64) return null;
    const kind: contract.ComponentKind = switch (rU16(header[0..], 8)) {
        1 => .r4x,
        2 => .r4l,
        3 => .r4d,
        4 => .r4p,
        else => return null,
    };
    const string_offset: u64 = rU32(header[0..], 56);
    const string_length: u64 = rU32(header[0..], 60);
    if (string_length == 0 or string_offset > size or string_length > size - string_offset) return null;

    var identity: Identity = .{ .kind = kind };
    var first_name: [name_capacity]u8 = .{0} ** name_capacity;
    var first_name_len: usize = 0;
    var explicit_name_seen = false;
    var version_seen = false;
    var entry: [256]u8 = undefined;
    var entry_len: usize = 0;
    var absolute = string_offset;
    const end = string_offset + string_length;
    while (absolute < end) : (absolute += 1) {
        var byte: [1]u8 = undefined;
        if (!reader.readAt(absolute, byte[0..])) return null;
        if (byte[0] != 0) {
            if (entry_len >= entry.len) return null;
            entry[entry_len] = byte[0];
            entry_len += 1;
            continue;
        }
        const text = entry[0..entry_len];
        if (first_name_len == 0 and text.len != 0) {
            const normalized = normalizeContainerName(kind, text);
            first_name_len = copyText(first_name[0..], normalized) orelse return null;
        }
        if (std.mem.startsWith(u8, text, "module.version=")) {
            if (version_seen) return null;
            const version = text["module.version=".len..];
            if (!contract.validSemanticVersion(version)) return null;
            identity.version_len = copyText(identity.version[0..], version) orelse return null;
            version_seen = true;
        }
        const name = moduleNameMetadata(kind, text);
        if (name) |value| {
            if (explicit_name_seen or !contract.validToken(value, contract.component_name_max_bytes)) return null;
            identity.name_len = copyText(identity.name[0..], value) orelse return null;
            explicit_name_seen = true;
        }
        entry_len = 0;
    }
    if (entry_len != 0 or !version_seen) return null;
    if (!explicit_name_seen) {
        if (first_name_len == 0 or !contract.validToken(first_name[0..first_name_len], contract.component_name_max_bytes)) return null;
        identity.name_len = copyText(identity.name[0..], first_name[0..first_name_len]) orelse return null;
    }
    return identity;
}

fn inspectKernelElf(reader: anytype, size: u64) ?Identity {
    var elf_header: [64]u8 = undefined;
    if (size < elf_header.len or !reader.readAt(0, elf_header[0..])) return null;
    if (!std.mem.eql(u8, elf_header[0..4], "\x7fELF") or elf_header[4] != 2 or elf_header[5] != 1 or
        rU16(elf_header[0..], 18) != 62)
    {
        return null;
    }
    const section_offset = rU64(elf_header[0..], 40);
    const section_entry_size: u64 = rU16(elf_header[0..], 58);
    const section_count: u64 = rU16(elf_header[0..], 60);
    const names_index: u64 = rU16(elf_header[0..], 62);
    if (section_entry_size < 64 or section_count == 0 or section_count > 4096 or names_index >= section_count) return null;
    if (section_offset > size or section_count > (size - section_offset) / section_entry_size) return null;

    var names_header: [64]u8 = undefined;
    if (!reader.readAt(section_offset + names_index * section_entry_size, names_header[0..])) return null;
    const names_offset = rU64(names_header[0..], 24);
    const names_size = rU64(names_header[0..], 32);
    if (names_offset > size or names_size > size - names_offset) return null;

    var metadata_seen = false;
    var metadata: [44]u8 = undefined;
    var index: u64 = 0;
    while (index < section_count) : (index += 1) {
        var section_header: [64]u8 = undefined;
        if (!reader.readAt(section_offset + index * section_entry_size, section_header[0..])) return null;
        const name_offset: u64 = rU32(section_header[0..], 0);
        if (name_offset >= names_size) return null;
        var name: [64]u8 = undefined;
        const name_len = readZeroTerminated(reader, names_offset + name_offset, names_offset + names_size, name[0..]) orelse return null;
        if (!std.mem.eql(u8, name[0..name_len], ".r4os.kernel.meta")) continue;
        if (metadata_seen or rU64(section_header[0..], 32) != metadata.len) return null;
        const metadata_offset = rU64(section_header[0..], 24);
        if (metadata_offset > size or metadata.len > size - metadata_offset or !reader.readAt(metadata_offset, metadata[0..])) return null;
        metadata_seen = true;
    }
    if (!metadata_seen or !std.mem.eql(u8, metadata[0..8], "R4OSKRN1") or
        rU32(metadata[0..], 8) != 1 or rU32(metadata[0..], 12) != metadata.len)
    {
        return null;
    }
    const version_len = std.mem.indexOfScalar(u8, metadata[28..44], 0) orelse return null;
    const version = metadata[28 .. 28 + version_len];
    if (!contract.validSemanticVersion(version)) return null;
    var parts = std.mem.splitScalar(u8, version, '.');
    const major = std.fmt.parseInt(u32, parts.next().?, 10) catch return null;
    const minor = std.fmt.parseInt(u32, parts.next().?, 10) catch return null;
    const patch = std.fmt.parseInt(u32, parts.next().?, 10) catch return null;
    if (major != rU32(metadata[0..], 16) or minor != rU32(metadata[0..], 20) or patch != rU32(metadata[0..], 24)) return null;

    var identity: Identity = .{ .kind = .kernel };
    identity.name_len = copyText(identity.name[0..], "KERNEL") orelse return null;
    identity.version_len = copyText(identity.version[0..], version) orelse return null;
    return identity;
}

fn moduleNameMetadata(kind: contract.ComponentKind, value: []const u8) ?[]const u8 {
    const prefix = switch (kind) {
        .r4x => "r4x.name=",
        .r4d => "r4d.name=",
        .r4p => "r4p.name=",
        .r4l, .kernel => return null,
    };
    if (!std.mem.startsWith(u8, value, prefix)) return null;
    return value[prefix.len..];
}

fn normalizeContainerName(kind: contract.ComponentKind, value: []const u8) []const u8 {
    if (kind == .r4d and std.mem.startsWith(u8, value, "R4D_")) return value[4..];
    if (kind == .r4p and std.mem.startsWith(u8, value, "R4P_")) return value[4..];
    return value;
}

fn readZeroTerminated(reader: anytype, start: u64, end: u64, out: []u8) ?usize {
    var offset = start;
    var len: usize = 0;
    while (offset < end) : (offset += 1) {
        var byte: [1]u8 = undefined;
        if (!reader.readAt(offset, byte[0..])) return null;
        if (byte[0] == 0) return len;
        if (len >= out.len) return null;
        out[len] = byte[0];
        len += 1;
    }
    return null;
}

fn copyText(out: []u8, value: []const u8) ?usize {
    if (value.len + 1 > out.len) return null;
    @memset(out, 0);
    @memcpy(out[0..value.len], value);
    return value.len;
}

fn rU16(bytes: []const u8, offset: usize) u16 {
    return std.mem.readInt(u16, bytes[offset..][0..2], .little);
}

fn rU32(bytes: []const u8, offset: usize) u32 {
    return std.mem.readInt(u32, bytes[offset..][0..4], .little);
}

fn rU64(bytes: []const u8, offset: usize) u64 {
    return std.mem.readInt(u64, bytes[offset..][0..8], .little);
}

test "R4M0 metadata identity is exact" {
    var bytes: [160]u8 = .{0} ** 160;
    @memcpy(bytes[0..4], "R4M0");
    std.mem.writeInt(u16, bytes[4..6], 1, .little);
    std.mem.writeInt(u16, bytes[8..10], 1, .little);
    std.mem.writeInt(u16, bytes[10..12], 64, .little);
    const strings = "TERMINAL\x00r4x.name=TERMINAL\x00module.version=1.2.3\x00";
    std.mem.writeInt(u32, bytes[56..60], 64, .little);
    std.mem.writeInt(u32, bytes[60..64], strings.len, .little);
    @memcpy(bytes[64 .. 64 + strings.len], strings);
    const identity = inspect(SliceReader{ .bytes = bytes[0 .. 64 + strings.len] }, 64 + strings.len).?;
    try std.testing.expectEqual(contract.ComponentKind.r4x, identity.kind);
    try std.testing.expectEqualStrings("TERMINAL", identity.nameText());
    try std.testing.expectEqualStrings("1.2.3", identity.versionText());
}
