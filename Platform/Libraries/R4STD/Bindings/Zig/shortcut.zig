const std = @import("std");
const r4os = @import("r4os");
const abi = r4os.abi;
const settings = @import("settings.zig");
const path_contract = r4os.path;

// R4OS .LNK is a small R4S text schema, not the Windows Shell Link binary format.
pub const schema = "R4LNK";

pub const title_max: usize = 63;
pub const path_max: usize = path_contract.file_path_max;
pub const args_max: usize = 127;
pub const icon_max: usize = path_contract.file_path_max;
pub const workdir_max: usize = path_contract.file_path_max;
pub const foreign_max: usize = 8;

pub const ForeignEntry = struct {
    key: [32]u8 = .{0} ** 32,
    value: [128]u8 = .{0} ** 128,
};

pub const Error = error{
    MissingFormat,
    UnsupportedFormat,
    MissingSchema,
    WrongSchema,
    MissingTarget,
    UnknownField,
    DuplicateField,
    InvalidTarget,
    TargetTooLong,
    TitleTooLong,
    ArgsTooLong,
    IconTooLong,
    WorkdirTooLong,
    InvalidPolicy,
    InvalidText,
    BufferTooSmall,
};

pub const TargetKind = enum {
    program,
    directory,
    file,
};

pub const ResolvedTarget = struct {
    kind: TargetKind,
    target: []const u8,
    title: []const u8,
    args: []const u8,
    policy: abi.LaunchPolicy,
    icon: []const u8,
    workdir: []const u8,
};

pub const Shortcut = struct {
    target: [path_max + 1]u8 = .{0} ** (path_max + 1),
    title: [title_max + 1]u8 = .{0} ** (title_max + 1),
    args: [args_max + 1]u8 = .{0} ** (args_max + 1),
    policy: abi.LaunchPolicy = .auto,
    icon: [icon_max + 1]u8 = .{0} ** (icon_max + 1),
    workdir: [workdir_max + 1]u8 = .{0} ** (workdir_max + 1),
    foreign: [foreign_max]ForeignEntry = .{ForeignEntry{}} ** foreign_max,
    foreign_count: u8 = 0,

    pub fn init(target: []const u8) Error!Shortcut {
        var shortcut = Shortcut{};
        try shortcut.setTarget(target);
        return shortcut;
    }

    pub fn loadFromBytes(self: *Shortcut, bytes: []const u8) Error!void {
        self.* = Shortcut{};

        const doc = settings.Document.init(bytes);
        const format_version = doc.formatVersion() orelse return Error.MissingFormat;
        if (format_version != settings.current_format_version) return Error.UnsupportedFormat;
        const schema_name = doc.schemaName() orelse return Error.MissingSchema;
        if (!settings.equalsKey(schema_name, schema)) return Error.WrongSchema;

        var seen_target = false;
        var seen_title = false;
        var seen_args = false;
        var seen_policy = false;
        var seen_icon = false;
        var seen_workdir = false;

        var iter = settings.EntryIterator.init(bytes);
        while (iter.next()) |entry| {
            if (settings.equalsKey(entry.key, settings.format_key) or settings.equalsKey(entry.key, settings.schema_key)) continue;
            if (settings.equalsKey(entry.key, "TARGET")) {
                if (seen_target) return Error.DuplicateField;
                seen_target = true;
                try self.setTarget(entry.value);
                continue;
            }
            if (settings.equalsKey(entry.key, "TITLE")) {
                if (seen_title) return Error.DuplicateField;
                seen_title = true;
                try self.setTitle(entry.value);
                continue;
            }
            if (settings.equalsKey(entry.key, "ARGS")) {
                if (seen_args) return Error.DuplicateField;
                seen_args = true;
                try self.setArgs(entry.value);
                continue;
            }
            if (settings.equalsKey(entry.key, "POLICY")) {
                if (seen_policy) return Error.DuplicateField;
                seen_policy = true;
                self.policy = parsePolicy(entry.value) orelse return Error.InvalidPolicy;
                continue;
            }
            if (settings.equalsKey(entry.key, "ICON")) {
                if (seen_icon) return Error.DuplicateField;
                seen_icon = true;
                try self.setIcon(entry.value);
                continue;
            }
            if (settings.equalsKey(entry.key, "WORKDIR")) {
                if (seen_workdir) return Error.DuplicateField;
                seen_workdir = true;
                try self.setWorkdir(entry.value);
                continue;
            }
            try self.preserveForeign(entry.key, entry.value);
        }

        if (!seen_target or self.targetText().len == 0) return Error.MissingTarget;
    }

    pub fn writeTo(self: *const Shortcut, out: []u8) Error![]const u8 {
        if (self.targetText().len == 0) return Error.MissingTarget;
        var writer = settings.Writer.init(out);
        writer.writeHeader(schema);
        writer.writePair("TARGET", self.targetText());
        if (self.titleText().len != 0) writer.writePair("TITLE", self.titleText());
        if (self.argsText().len != 0) writer.writePair("ARGS", self.argsText());
        writer.writePair("POLICY", policyText(self.policy));
        if (self.iconText().len != 0) writer.writePair("ICON", self.iconText());
        if (self.workdirText().len != 0) writer.writePair("WORKDIR", self.workdirText());
        var foreign_index: usize = 0;
        while (foreign_index < self.foreign_count) : (foreign_index += 1) {
            writer.writePair(spanZ(self.foreign[foreign_index].key[0..]), spanZ(self.foreign[foreign_index].value[0..]));
        }
        return if (writer.ok()) writer.bytes() else Error.BufferTooSmall;
    }

    pub fn resolve(self: *const Shortcut) Error!ResolvedTarget {
        const target = self.targetText();
        if (target.len == 0) return Error.MissingTarget;
        return .{
            .kind = inferTargetKind(target),
            .target = target,
            .title = self.titleText(),
            .args = self.argsText(),
            .policy = self.policy,
            .icon = self.iconText(),
            .workdir = self.workdirText(),
        };
    }

    pub fn setTarget(self: *Shortcut, value: []const u8) Error!void {
        const text = settings.trim(value);
        if (text.len == 0) return Error.MissingTarget;
        if (text.len > path_max) return Error.TargetTooLong;
        const had_trailing_separator = text.len > 3 and (text[text.len - 1] == '\\' or text[text.len - 1] == '/');
        const parsed = path_contract.FilePath.parse(text) catch return Error.InvalidTarget;
        const canonical = parsed.bytes();
        if (canonical.len + @intFromBool(had_trailing_separator) > path_max) return Error.TargetTooLong;
        copyZ(self.target[0..], canonical);
        if (had_trailing_separator and self.targetText().len > 3) {
            const len = self.targetText().len;
            self.target[len] = '\\';
            self.target[len + 1] = 0;
        }
    }

    pub fn setTitle(self: *Shortcut, value: []const u8) Error!void {
        const text = settings.trim(value);
        if (text.len > title_max) return Error.TitleTooLong;
        if (!validLineText(text)) return Error.InvalidText;
        copyZ(self.title[0..], text);
    }

    pub fn setArgs(self: *Shortcut, value: []const u8) Error!void {
        const text = settings.trim(value);
        if (text.len > args_max) return Error.ArgsTooLong;
        if (!validLineText(text)) return Error.InvalidText;
        copyZ(self.args[0..], text);
    }

    pub fn setPolicy(self: *Shortcut, value: abi.LaunchPolicy) void {
        self.policy = value;
    }

    pub fn setIcon(self: *Shortcut, value: []const u8) Error!void {
        const text = settings.trim(value);
        if (text.len > icon_max) return Error.IconTooLong;
        if (text.len == 0) return copyZ(self.icon[0..], text);
        const parsed = path_contract.FilePath.parse(text) catch return Error.InvalidTarget;
        copyZ(self.icon[0..], parsed.bytes());
    }

    pub fn setWorkdir(self: *Shortcut, value: []const u8) Error!void {
        const text = settings.trim(value);
        if (text.len > workdir_max) return Error.WorkdirTooLong;
        if (text.len == 0) return copyZ(self.workdir[0..], text);
        const parsed = path_contract.FilePath.parse(text) catch return Error.InvalidTarget;
        copyZ(self.workdir[0..], parsed.bytes());
    }

    pub fn targetText(self: *const Shortcut) []const u8 {
        return spanZ(self.target[0..]);
    }

    pub fn titleText(self: *const Shortcut) []const u8 {
        return spanZ(self.title[0..]);
    }

    pub fn argsText(self: *const Shortcut) []const u8 {
        return spanZ(self.args[0..]);
    }

    pub fn iconText(self: *const Shortcut) []const u8 {
        return spanZ(self.icon[0..]);
    }

    pub fn workdirText(self: *const Shortcut) []const u8 {
        return spanZ(self.workdir[0..]);
    }

    fn preserveForeign(self: *Shortcut, key: []const u8, value: []const u8) Error!void {
        if (self.foreign_count >= foreign_max or key.len == 0 or key.len >= self.foreign[0].key.len or value.len >= self.foreign[0].value.len) return Error.InvalidText;
        const entry = &self.foreign[self.foreign_count];
        copyZ(entry.key[0..], key);
        copyZ(entry.value[0..], value);
        self.foreign_count += 1;
    }
};

pub fn parse(bytes: []const u8) Error!Shortcut {
    var shortcut = Shortcut{};
    try shortcut.loadFromBytes(bytes);
    return shortcut;
}

pub fn inferTargetKind(target: []const u8) TargetKind {
    if (endsWithIgnoreCase(target, ".R4X")) return .program;
    if (isDirectorySyntax(target)) return .directory;
    return .file;
}

pub fn parsePolicy(value: []const u8) ?abi.LaunchPolicy {
    const text = settings.trim(value);
    if (settings.equalsKey(text, "auto")) return .auto;
    if (settings.equalsKey(text, "console")) return .console;
    if (settings.equalsKey(text, "gui")) return .gui;
    return null;
}

pub fn policyText(policy: abi.LaunchPolicy) []const u8 {
    return switch (policy) {
        .auto => "auto",
        .console => "console",
        .gui => "gui",
    };
}

fn validPathText(value: []const u8) bool {
    return validLineText(value) and isAbsolutePath(value);
}

fn validLineText(value: []const u8) bool {
    for (value) |ch| {
        if (ch == 0 or ch == '\r' or ch == '\n') return false;
    }
    return true;
}

fn isAbsolutePath(value: []const u8) bool {
    if (value.len == 0) return false;
    if (value[0] == '\\' or value[0] == '/') return true;
    return value.len >= 3 and isAsciiAlpha(value[0]) and value[1] == ':' and isPathSeparator(value[2]);
}

fn isDirectorySyntax(value: []const u8) bool {
    if (value.len == 0) return false;
    if (isDriveRoot(value)) return true;
    if (isPathSeparator(value[value.len - 1])) return true;
    return extensionOfPath(value) == null;
}

fn isDriveRoot(value: []const u8) bool {
    return value.len == 3 and isAsciiAlpha(value[0]) and value[1] == ':' and isPathSeparator(value[2]);
}

fn extensionOfPath(path: []const u8) ?[]const u8 {
    var start: ?usize = null;
    var index: usize = 0;
    while (index < path.len) : (index += 1) {
        const ch = path[index];
        if (isPathSeparator(ch)) {
            start = null;
        } else if (ch == '.') {
            start = index + 1;
        }
    }
    const ext_start = start orelse return null;
    if (ext_start >= path.len) return null;
    return path[ext_start..];
}

fn endsWithIgnoreCase(value: []const u8, suffix: []const u8) bool {
    if (value.len < suffix.len) return false;
    const start = value.len - suffix.len;
    var index: usize = 0;
    while (index < suffix.len) : (index += 1) {
        if (asciiUpper(value[start + index]) != asciiUpper(suffix[index])) return false;
    }
    return true;
}

fn copyZ(out: []u8, value: []const u8) void {
    if (out.len == 0) return;
    @memset(out, 0);
    const count = @min(value.len, out.len - 1);
    if (count > 0) @memcpy(out[0..count], value[0..count]);
    out[count] = 0;
}

fn spanZ(buffer: []const u8) []const u8 {
    var len: usize = 0;
    while (len < buffer.len and buffer[len] != 0) : (len += 1) {}
    return buffer[0..len];
}

fn isPathSeparator(ch: u8) bool {
    return ch == '\\' or ch == '/';
}

fn isAsciiAlpha(ch: u8) bool {
    return (ch >= 'A' and ch <= 'Z') or (ch >= 'a' and ch <= 'z');
}

fn asciiUpper(ch: u8) u8 {
    if (ch >= 'a' and ch <= 'z') return ch - ('a' - 'A');
    return ch;
}

test "parser accepts full R4LNK shortcut and writer emits canonical schema" {
    var link = try parse(
        \\R4S_FORMAT=1
        \\SCHEMA=R4LNK
        \\TARGET=C:\R4OS\SOFTWARE\DESKTOP\NOTEPAD.R4X
        \\TITLE=Notepad
        \\ARGS=C:\TEMP\README.TXT
        \\POLICY=gui
        \\ICON=C:\R4OS\Media\Icons\Notepad.ico
        \\WORKDIR=C:\TEMP
    );

    const target = try link.resolve();
    try std.testing.expectEqual(TargetKind.program, target.kind);
    try std.testing.expectEqualStrings("C:\\R4OS\\SOFTWARE\\DESKTOP\\NOTEPAD.R4X", target.target);
    try std.testing.expectEqualStrings("Notepad", target.title);
    try std.testing.expectEqualStrings("C:\\TEMP\\README.TXT", target.args);
    try std.testing.expectEqual(abi.LaunchPolicy.gui, target.policy);

    var out: [1024]u8 = .{0} ** 1024;
    const bytes = try link.writeTo(out[0..]);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "SCHEMA=R4LNK") != null);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "TARGET=C:\\R4OS\\SOFTWARE\\DESKTOP\\NOTEPAD.R4X") != null);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "POLICY=gui") != null);
}

test "parser rejects missing target and invalid policy" {
    try std.testing.expectError(Error.MissingTarget, parse(
        \\R4S_FORMAT=1
        \\SCHEMA=R4LNK
        \\TITLE=Broken
    ));

    try std.testing.expectError(Error.InvalidPolicy, parse(
        \\R4S_FORMAT=1
        \\SCHEMA=R4LNK
        \\TARGET=C:\R4OS\SOFTWARE\DESKTOP\NOTEPAD.R4X
        \\POLICY=hidden
    ));
}

test "parser rejects unsupported headers and preserves foreign fields" {
    try std.testing.expectError(Error.UnsupportedFormat, parse(
        \\R4S_FORMAT=2
        \\SCHEMA=R4LNK
        \\TARGET=C:\R4OS\SOFTWARE\DESKTOP\NOTEPAD.R4X
    ));

    try std.testing.expectError(Error.WrongSchema, parse(
        \\R4S_FORMAT=1
        \\SCHEMA=APPASSOC
        \\TARGET=C:\R4OS\SOFTWARE\DESKTOP\NOTEPAD.R4X
    ));

    const with_foreign = try parse(
        \\R4S_FORMAT=1
        \\SCHEMA=R4LNK
        \\TARGET=C:\R4OS\SOFTWARE\DESKTOP\NOTEPAD.R4X
        \\WINDOWS_BINARY_COMPAT=NO
    );
    var out: [1024]u8 = undefined;
    const bytes = try with_foreign.writeTo(out[0..]);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "WINDOWS_BINARY_COMPAT=NO") != null);
}

test "length validation covers target args and optional paths" {
    var long_target: [path_max + 4]u8 = .{0} ** (path_max + 4);
    long_target[0] = 'C';
    long_target[1] = ':';
    long_target[2] = '\\';
    @memset(long_target[3..], 'A');
    try std.testing.expectError(Error.TargetTooLong, Shortcut.init(long_target[0..]));

    var link = try Shortcut.init("C:\\R4OS\\SOFTWARE\\DESKTOP\\NOTEPAD.R4X");
    var long_args: [args_max + 1]u8 = .{'A'} ** (args_max + 1);
    try std.testing.expectError(Error.ArgsTooLong, link.setArgs(long_args[0..]));

    var long_icon: [icon_max + 4]u8 = .{0} ** (icon_max + 4);
    long_icon[0] = 'C';
    long_icon[1] = ':';
    long_icon[2] = '\\';
    @memset(long_icon[3..], 'I');
    try std.testing.expectError(Error.IconTooLong, link.setIcon(long_icon[0..]));
}

test "resolver distinguishes program folder and file targets without launching" {
    const app = try Shortcut.init("C:\\R4OS\\SOFTWARE\\DESKTOP\\NOTEPAD.R4X");
    try std.testing.expectEqual(TargetKind.program, (try app.resolve()).kind);

    const folder = try Shortcut.init("C:\\R4OS\\DESKTOP\\");
    try std.testing.expectEqual(TargetKind.directory, (try folder.resolve()).kind);

    const folder_without_slash = try Shortcut.init("C:\\R4OS\\DESKTOP");
    try std.testing.expectEqual(TargetKind.directory, (try folder_without_slash.resolve()).kind);

    const file = try Shortcut.init("C:\\TEMP\\README.TXT");
    try std.testing.expectEqual(TargetKind.file, (try file.resolve()).kind);
}

test "writer rejects tiny buffers and preserves empty optional fields" {
    var link = try Shortcut.init("C:\\R4OS\\DESKTOP\\");
    link.setPolicy(.auto);
    var tiny: [16]u8 = .{0} ** 16;
    try std.testing.expectError(Error.BufferTooSmall, link.writeTo(tiny[0..]));

    var out: [256]u8 = .{0} ** 256;
    const bytes = try link.writeTo(out[0..]);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "TITLE=") == null);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "POLICY=auto") != null);
}
