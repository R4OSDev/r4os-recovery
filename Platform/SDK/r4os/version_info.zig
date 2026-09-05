const abi = @import("r4os_contract").abi;
const std = @import("std");

pub const release_field = "RELEASE_VERSION=";
pub const release_file_path = "/R4OS/CONFIG/VERSION.R4S";
pub const inventory_file_path = "/R4OS/CONFIG/MODULES.JSON";

pub const SemanticVersion = struct {
    major: u32,
    minor: u32,
    patch: u32,

    pub fn eql(a: SemanticVersion, b: SemanticVersion) bool {
        return a.major == b.major and a.minor == b.minor and a.patch == b.patch;
    }
};

pub fn stripBom(data: []const u8) []const u8 {
    if (data.len >= 3 and data[0] == 0xEF and data[1] == 0xBB and data[2] == 0xBF) return data[3..];
    return data;
}

pub fn parseReleaseVersion(data: []const u8) ?[]const u8 {
    var lines = std.mem.splitAny(u8, stripBom(data), "\r\n");
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t");
        if (!std.mem.startsWith(u8, line, release_field)) continue;
        const value = std.mem.trim(u8, line[release_field.len..], " \t");
        if (parseSemanticVersion(value) == null) return null;
        return value;
    }
    return null;
}

pub fn parseInstalledKernelVersion(data: []const u8) ?[]const u8 {
    const name_marker = "\"name\": \"KERNEL\"";
    const kind_marker = "\"kind\": \"KERNEL\"";
    const version_marker = "\"version\": \"";
    const name_index = std.mem.indexOf(u8, data, name_marker) orelse return null;
    const object_start = std.mem.lastIndexOfScalar(u8, data[0..name_index], '{') orelse return null;
    const object_tail = data[object_start..];
    const object_end_relative = std.mem.indexOfScalar(u8, object_tail, '}') orelse return null;
    const object = object_tail[0..object_end_relative];
    if (std.mem.indexOf(u8, object, kind_marker) == null) return null;
    const version_index = std.mem.indexOf(u8, object, version_marker) orelse return null;
    const value_start = version_index + version_marker.len;
    const value_end_relative = std.mem.indexOfScalar(u8, object[value_start..], '"') orelse return null;
    const value = object[value_start .. value_start + value_end_relative];
    if (parseSemanticVersion(value) == null) return null;
    return value;
}

pub fn parseSemanticVersion(value: []const u8) ?SemanticVersion {
    if (value.len == 0 or std.mem.indexOfAny(u8, value, " \t\r\n") != null) return null;
    var parts = std.mem.splitScalar(u8, value, '.');
    const major = parseComponent(parts.next() orelse return null) orelse return null;
    const minor = parseComponent(parts.next() orelse return null) orelse return null;
    const patch = parseComponent(parts.next() orelse return null) orelse return null;
    if (parts.next() != null) return null;
    return .{ .major = major, .minor = minor, .patch = patch };
}

pub fn fromKernelVersion(value: abi.KernelVersion) SemanticVersion {
    return .{ .major = value.major, .minor = value.minor, .patch = value.patch };
}

pub fn formatKernelVersion(value: abi.KernelVersion, buffer: []u8) ?[]const u8 {
    return formatSemanticVersion(fromKernelVersion(value), buffer);
}

pub fn formatSemanticVersion(value: SemanticVersion, buffer: []u8) ?[]const u8 {
    return std.fmt.bufPrint(buffer, "{d}.{d}.{d}", .{ value.major, value.minor, value.patch }) catch null;
}

pub fn restartRequired(active: abi.KernelVersion, installed_text: []const u8) bool {
    const installed = parseSemanticVersion(installed_text) orelse return false;
    return !fromKernelVersion(active).eql(installed);
}

fn parseComponent(value: []const u8) ?u32 {
    if (value.len == 0 or (value.len > 1 and value[0] == '0')) return null;
    for (value) |byte| if (byte < '0' or byte > '9') return null;
    return std.fmt.parseInt(u32, value, 10) catch null;
}

test "release and installed kernel versions remain separate" {
    try std.testing.expectEqualStrings("0.63.10", parseReleaseVersion("\xEF\xBB\xBFRELEASE_VERSION=0.63.10\r\n").?);
    const inventory =
        \\{"entries":[{"name": "KERNEL", "kind": "KERNEL", "version": "0.1.1", "target": "/boot/r4os.elf"}]}
    ;
    const installed = parseInstalledKernelVersion(inventory).?;
    try std.testing.expectEqualStrings("0.1.1", installed);
    const active: abi.KernelVersion = .{ .major = 0, .minor = 1, .patch = 0 };
    try std.testing.expect(restartRequired(active, installed));
    try std.testing.expect(!restartRequired(active, "0.1.0"));
}

test "semantic versions are strict" {
    try std.testing.expect(parseSemanticVersion("1.2.3") != null);
    try std.testing.expect(parseSemanticVersion("01.2.3") == null);
    try std.testing.expect(parseSemanticVersion("1.2") == null);
    try std.testing.expect(parseSemanticVersion("1.2.3-beta") == null);
    try std.testing.expect(parseReleaseVersion("KERNEL_VERSION=0.63.10") == null);
}
