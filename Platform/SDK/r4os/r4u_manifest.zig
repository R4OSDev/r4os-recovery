const std = @import("std");

pub const manifest_version: u16 = 2;
pub const header_magic = "R4U2";
pub const header_version: u16 = 2;
pub const header_size: usize = 64;
pub const title_max_bytes: usize = 96;
pub const description_max_bytes: usize = 2048;
pub const package_name_max_bytes: usize = 48;
pub const component_name_max_bytes: usize = 48;
pub const version_max_bytes: usize = 24;

pub const ComponentKind = enum {
    kernel,
    r4x,
    r4l,
    r4d,
    r4p,

    pub fn text(self: ComponentKind) []const u8 {
        return switch (self) {
            .kernel => "KERNEL",
            .r4x => "R4X",
            .r4l => "R4L",
            .r4d => "R4D",
            .r4p => "R4P",
        };
    }

    pub fn parse(value: []const u8) ?ComponentKind {
        inline for (std.meta.tags(ComponentKind)) |kind| {
            if (std.ascii.eqlIgnoreCase(value, kind.text())) return kind;
        }
        return null;
    }
};

pub const InstallMode = enum {
    live,
    restart,

    pub fn text(self: InstallMode) []const u8 {
        return @tagName(self);
    }

    pub fn parse(value: []const u8) ?InstallMode {
        if (std.ascii.eqlIgnoreCase(value, "live")) return .live;
        if (std.ascii.eqlIgnoreCase(value, "restart")) return .restart;
        return null;
    }
};

pub const Priority = enum {
    normal,
    foundation,

    pub fn text(self: Priority) []const u8 {
        return @tagName(self);
    }

    pub fn parse(value: []const u8) ?Priority {
        if (std.ascii.eqlIgnoreCase(value, "normal")) return .normal;
        if (std.ascii.eqlIgnoreCase(value, "foundation")) return .foundation;
        return null;
    }
};

pub const RequirementState = enum {
    installed,
    active,

    pub fn text(self: RequirementState) []const u8 {
        return @tagName(self);
    }

    pub fn parse(value: []const u8) ?RequirementState {
        if (std.ascii.eqlIgnoreCase(value, "installed")) return .installed;
        if (std.ascii.eqlIgnoreCase(value, "active")) return .active;
        return null;
    }
};

pub const DerivedClass = struct {
    activation: InstallMode = .live,
    priority: Priority = .normal,
};

pub fn componentKindForPayload(value: []const u8, target: []const u8) ?ComponentKind {
    if (std.ascii.eqlIgnoreCase(value, "boot-kernel")) return .kernel;
    if (std.ascii.eqlIgnoreCase(value, "system-library")) return .r4l;
    if (std.ascii.eqlIgnoreCase(value, "driver")) return .r4d;
    if (std.ascii.eqlIgnoreCase(value, "protocol")) return .r4p;
    if ((std.ascii.eqlIgnoreCase(value, "service") or std.ascii.eqlIgnoreCase(value, "software")) and
        std.ascii.endsWithIgnoreCase(target, ".R4X")) return .r4x;
    return null;
}

pub fn installModeFor(kind: ComponentKind, canonical_target: []const u8) InstallMode {
    return switch (kind) {
        .kernel, .r4l, .r4d, .r4p => .restart,
        .r4x => if (pathHasPrefix(canonical_target, "/R4OS/SERVICES/")) .restart else .live,
    };
}

pub fn priorityFor(kind: ComponentKind) Priority {
    return switch (kind) {
        .kernel, .r4l => .foundation,
        .r4x, .r4d, .r4p => .normal,
    };
}

pub fn includeComponent(class: *DerivedClass, kind: ComponentKind, canonical_target: []const u8) void {
    if (installModeFor(kind, canonical_target) == .restart) class.activation = .restart;
    if (priorityFor(kind) == .foundation) class.priority = .foundation;
}

pub fn validSemanticVersion(value: []const u8) bool {
    if (value.len == 0 or value.len > version_max_bytes) return false;
    var parts = std.mem.splitScalar(u8, value, '.');
    var count: usize = 0;
    while (parts.next()) |part| {
        if (part.len == 0 or (part.len > 1 and part[0] == '0')) return false;
        var numeric: u32 = 0;
        for (part) |byte| {
            if (byte < '0' or byte > '9') return false;
            numeric = std.math.mul(u32, numeric, 10) catch return false;
            numeric = std.math.add(u32, numeric, byte - '0') catch return false;
        }
        count += 1;
    }
    return count == 3;
}

pub fn compareVersions(left: []const u8, right: []const u8) ?i8 {
    if (!validSemanticVersion(left) or !validSemanticVersion(right)) return null;
    var left_parts = std.mem.splitScalar(u8, left, '.');
    var right_parts = std.mem.splitScalar(u8, right, '.');
    var index: usize = 0;
    while (index < 3) : (index += 1) {
        const left_value = std.fmt.parseInt(u32, left_parts.next().?, 10) catch return null;
        const right_value = std.fmt.parseInt(u32, right_parts.next().?, 10) catch return null;
        if (left_value < right_value) return -1;
        if (left_value > right_value) return 1;
    }
    return 0;
}

pub fn validToken(value: []const u8, max_bytes: usize) bool {
    if (value.len == 0 or value.len > max_bytes) return false;
    for (value) |byte| {
        if (byte <= ' ' or byte >= 0x7f or byte == ';' or byte == '|' or byte == '=') return false;
    }
    return true;
}

/// TITLE und DESCRIPTION sind eine einzelne UTF-8-Zeile. Sie werden niemals
/// als HTML oder Markdown interpretiert; spitze Klammern sind deshalb bereits
/// im Paketvertrag unzulaessig.
pub fn validDisplayText(value: []const u8, max_bytes: usize) bool {
    if (value.len == 0 or value.len > max_bytes or !std.unicode.utf8ValidateSlice(value)) return false;
    var view = std.unicode.Utf8View.initUnchecked(value);
    var iterator = view.iterator();
    while (iterator.nextCodepoint()) |codepoint| {
        if (codepoint == '<' or codepoint == '>' or codepoint == 0 or
            codepoint < 0x20 or (codepoint >= 0x7f and codepoint <= 0x9f))
        {
            return false;
        }
    }
    return true;
}

pub fn canonicalInventoryTarget(out: []u8, payload_target: []const u8) ?[]const u8 {
    if (payload_target.len == 0) return null;
    var source = payload_target;
    if (payload_target.len >= 3 and std.ascii.isAlphabetic(payload_target[0]) and payload_target[1] == ':' and isSeparator(payload_target[2])) {
        if (std.ascii.toUpper(payload_target[0]) != 'C') return null;
        source = payload_target[2..];
    } else if (!isSeparator(payload_target[0])) {
        return null;
    }
    if (source.len == 0 or source.len > out.len) return null;
    var len: usize = 0;
    var previous_separator = false;
    for (source) |byte| {
        const separator = isSeparator(byte);
        if (separator and previous_separator) continue;
        if (len >= out.len) return null;
        out[len] = if (separator) '/' else byte;
        len += 1;
        previous_separator = separator;
    }
    if (len == 0 or out[0] != '/' or out[len - 1] == '/') return null;
    return out[0..len];
}

pub fn targetEquals(left: []const u8, right: []const u8) bool {
    if (left.len != right.len) return false;
    for (left, right) |a_raw, b_raw| {
        const a = if (isSeparator(a_raw)) '/' else std.ascii.toUpper(a_raw);
        const b = if (isSeparator(b_raw)) '/' else std.ascii.toUpper(b_raw);
        if (a != b) return false;
    }
    return true;
}

pub fn isManagedStateTarget(canonical_target: []const u8) bool {
    return targetEquals(canonical_target, "/R4OS/CONFIG/VERSION.R4S") or
        targetEquals(canonical_target, "/R4OS/CONFIG/MODULES.JSON");
}

fn pathHasPrefix(value: []const u8, prefix: []const u8) bool {
    return value.len >= prefix.len and targetEquals(value[0..prefix.len], prefix);
}

fn isSeparator(byte: u8) bool {
    return byte == '/' or byte == '\\';
}

test "strict versions and display text" {
    try std.testing.expect(validSemanticVersion("0.63.11"));
    try std.testing.expect(!validSemanticVersion("0.063.11"));
    try std.testing.expect(!validSemanticVersion("0.63"));
    try std.testing.expectEqual(@as(i8, -1), compareVersions("0.1.9", "0.2.0").?);
    try std.testing.expect(validDisplayText("Neue Netzwerkfunktionen fuer R4OS", description_max_bytes));
    try std.testing.expect(validDisplayText("Geräte und Größe", description_max_bytes));
    try std.testing.expect(!validDisplayText("kein\nPlaintext", description_max_bytes));
    try std.testing.expect(!validDisplayText("<b>Markup</b>", description_max_bytes));
}

test "canonical inventory targets and derived classes" {
    var target_buffer: [128]u8 = undefined;
    const target = canonicalInventoryTarget(target_buffer[0..], "C:\\R4OS\\SOFTWARE\\TERMINAL\\TERMINAL.R4X").?;
    try std.testing.expectEqualStrings("/R4OS/SOFTWARE/TERMINAL/TERMINAL.R4X", target);
    try std.testing.expect(isManagedStateTarget("/R4OS/CONFIG/VERSION.R4S"));
    try std.testing.expect(isManagedStateTarget("/R4OS/CONFIG/MODULES.JSON"));
    try std.testing.expectEqual(InstallMode.live, installModeFor(.r4x, target));
    try std.testing.expectEqual(InstallMode.restart, installModeFor(.r4x, "/R4OS/SERVICES/SSHD.R4X"));
    var class: DerivedClass = .{};
    includeComponent(&class, .r4x, target);
    includeComponent(&class, .r4l, "/R4OS/LIBS/R4STD.R4L");
    try std.testing.expectEqual(InstallMode.restart, class.activation);
    try std.testing.expectEqual(Priority.foundation, class.priority);
}
