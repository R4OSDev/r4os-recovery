const std = @import("std");
const r4os = @import("r4os");
const abi = r4os.abi;
const settings = @import("settings.zig");
const runtime = @import("runtime.zig");
const path_contract = r4os.path;

pub const schema = "APPASSOC";

pub const max_apps: usize = 8;
pub const max_extensions: usize = 16;
pub const app_id_max: usize = 15;
pub const ext_max: usize = 7;
pub const title_max: usize = 31;
pub const path_max: usize = path_contract.file_path_max;
pub const args_max: usize = 95;
pub const type_name_max: usize = 23;
pub const short_name_max: usize = 11;
pub const prefix_max: usize = 7;
pub const subsystem_id_max: usize = 63;
pub const format_id_max: usize = 63;
pub const foreign_max: usize = 16;
pub const foreign_key_max: usize = 79;
pub const foreign_value_max: usize = 127;

pub const ForeignEntry = struct {
    key: [foreign_key_max + 1]u8 = .{0} ** (foreign_key_max + 1),
    value: [foreign_value_max + 1]u8 = .{0} ** (foreign_value_max + 1),
};

pub const LaunchKind = enum {
    direct_program,
    associated,
};

pub const HandlerKind = enum {
    none,
    app,
    subsystem,
};

pub const AppEntry = struct {
    valid: bool = false,
    id: [app_id_max + 1]u8 = .{0} ** (app_id_max + 1),
    title: [title_max + 1]u8 = .{0} ** (title_max + 1),
    path: [path_max + 1]u8 = .{0} ** (path_max + 1),
    policy: abi.LaunchPolicy = .auto,
    args: [args_max + 1]u8 = .{0} ** (args_max + 1),

    pub fn idText(self: *const AppEntry) []const u8 {
        return spanZ(self.id[0..]);
    }

    pub fn titleText(self: *const AppEntry) []const u8 {
        return spanZ(self.title[0..]);
    }

    pub fn pathText(self: *const AppEntry) []const u8 {
        return spanZ(self.path[0..]);
    }

    pub fn argsText(self: *const AppEntry) []const u8 {
        return spanZ(self.args[0..]);
    }
};

pub const ExtEntry = struct {
    valid: bool = false,
    ext: [ext_max + 1]u8 = .{0} ** (ext_max + 1),
    handler_kind: HandlerKind = .app,
    app_id: [app_id_max + 1]u8 = .{0} ** (app_id_max + 1),
    subsystem_id: [subsystem_id_max + 1]u8 = .{0} ** (subsystem_id_max + 1),
    format_id: [format_id_max + 1]u8 = .{0} ** (format_id_max + 1),
    type_name: [type_name_max + 1]u8 = .{0} ** (type_name_max + 1),
    short_name: [short_name_max + 1]u8 = .{0} ** (short_name_max + 1),
    prefix: [prefix_max + 1]u8 = .{0} ** (prefix_max + 1),
    rank: u8 = 6,

    pub fn extText(self: *const ExtEntry) []const u8 {
        return spanZ(self.ext[0..]);
    }

    pub fn appIdText(self: *const ExtEntry) []const u8 {
        return spanZ(self.app_id[0..]);
    }

    pub fn subsystemIdText(self: *const ExtEntry) []const u8 {
        return spanZ(self.subsystem_id[0..]);
    }

    pub fn formatIdText(self: *const ExtEntry) []const u8 {
        return spanZ(self.format_id[0..]);
    }

    pub fn typeNameText(self: *const ExtEntry) []const u8 {
        return spanZ(self.type_name[0..]);
    }

    pub fn shortNameText(self: *const ExtEntry) []const u8 {
        return spanZ(self.short_name[0..]);
    }

    pub fn prefixText(self: *const ExtEntry) []const u8 {
        return spanZ(self.prefix[0..]);
    }
};

pub const LaunchTarget = struct {
    kind: LaunchKind,
    app_id: []const u8,
    title: []const u8,
    app_path: []const u8,
    args: []const u8,
    policy: abi.LaunchPolicy,
    type_name: []const u8,
    short_name: []const u8,
    prefix: []const u8,
    rank: u8,
};

const ScopedKey = struct {
    id: []const u8,
    field: []const u8,
};

const ExtDefaults = struct {
    app_id: []const u8,
    type_name: []const u8,
    short_name: []const u8,
    prefix: []const u8,
    rank: u8,
};

pub const Config = struct {
    apps: [max_apps]AppEntry = .{AppEntry{}} ** max_apps,
    app_count: usize = 0,
    extensions: [max_extensions]ExtEntry = .{ExtEntry{}} ** max_extensions,
    extension_count: usize = 0,
    foreign: [foreign_max]ForeignEntry = .{ForeignEntry{}} ** foreign_max,
    foreign_count: usize = 0,

    pub fn initDefault() Config {
        var config = Config{};
        config.loadDefaults();
        return config;
    }

    pub fn clear(self: *Config) void {
        self.* = Config{};
    }

    pub fn loadDefaults(self: *Config) void {
        self.clear();
        _ = self.addApp("NOTEPAD", "Notepad", "C:\\R4OS\\SOFTWARE\\DESKTOP\\NOTEPAD.R4X", .gui, "%1");
        _ = self.addApp("PAINT", "Paint", "C:\\R4OS\\SOFTWARE\\DESKTOP\\PAINT.R4X", .gui, "%1");
        _ = self.addApp("FONTS", "Fonts", "C:\\R4OS\\SOFTWARE\\DESKTOP\\FONTS.R4X", .gui, "%1");
        _ = self.addApp("SYNTH", "R4Synth", "C:\\R4OS\\SOFTWARE\\TERMINAL\\SYNTH.R4X", .console, "%1");

        self.addExtensionGroup(&.{ "TXT", "R4S", "BAT", "LOG", "MD", "INI", "CFG" }, "NOTEPAD", "Text", "Text", "[TXT]", 3);
        _ = self.addSubsystemExtension("BAS", "r4os.basic", "basic.qbasic-source", "BASIC source", "BAS", "[BAS]", 3);
        self.addExtensionGroup(&.{"BMP"}, "PAINT", "Bitmap", "BMP", "[BMP]", 4);
        self.addExtensionGroup(&.{"FON"}, "FONTS", "Font", "Font", "[FNT]", 4);
        self.addExtensionGroup(&.{ "WAV", "MID", "SID" }, "SYNTH", "Audio", "Audio", "[AUD]", 5);
    }

    pub fn loadFromBytes(self: *Config, bytes: []const u8) bool {
        self.loadDefaults();
        const doc = settings.Document.init(bytes);
        if (doc.value(settings.schema_key)) |value| {
            if (!settings.equalsKey(value, schema)) return false;
        }

        var accepted: usize = 0;
        var iter = settings.EntryIterator.init(bytes);
        while (iter.next()) |entry| {
            if (settings.equalsKey(entry.key, settings.format_key) or settings.equalsKey(entry.key, settings.schema_key)) continue;
            if (parseScopedKey(entry.key, "APP")) |key| {
                if (self.applyAppField(key.id, key.field, entry.value)) {
                    accepted += 1;
                } else if (!isKnownAppField(key.field)) {
                    _ = self.preserveForeign(entry.key, entry.value);
                }
                continue;
            }
            if (parseScopedKey(entry.key, "EXT")) |key| {
                if (self.applyExtField(key.id, key.field, entry.value)) {
                    accepted += 1;
                } else if (!isKnownExtField(key.field)) {
                    _ = self.preserveForeign(entry.key, entry.value);
                }
                continue;
            }
            _ = self.preserveForeign(entry.key, entry.value);
        }
        return accepted != 0;
    }

    pub fn writeTo(self: *const Config, out: []u8) []const u8 {
        var writer = settings.Writer.init(out);
        writer.writeHeader(schema);

        var key: [80]u8 = .{0} ** 80;
        var index: usize = 0;
        while (index < self.app_count) : (index += 1) {
            const app = &self.apps[index];
            if (!usableApp(app)) continue;
            if (formatKey(key[0..], "APP", app.idText(), "TITLE")) |field| writer.writePair(field, app.titleText());
            if (formatKey(key[0..], "APP", app.idText(), "PATH")) |field| writer.writePair(field, app.pathText());
            if (formatKey(key[0..], "APP", app.idText(), "POLICY")) |field| writer.writePair(field, policyText(app.policy));
            if (formatKey(key[0..], "APP", app.idText(), "ARGS")) |field| writer.writePair(field, app.argsText());
        }

        index = 0;
        while (index < self.extension_count) : (index += 1) {
            const ext = &self.extensions[index];
            if (!usableExtension(self, ext)) continue;
            if (formatKey(key[0..], "EXT", ext.extText(), "HANDLER")) |field| writer.writePair(field, handlerKindText(ext.handler_kind));
            switch (ext.handler_kind) {
                .none => {},
                .app => if (formatKey(key[0..], "EXT", ext.extText(), "APP")) |field| writer.writePair(field, ext.appIdText()),
                .subsystem => {
                    if (formatKey(key[0..], "EXT", ext.extText(), "SUBSYSTEM")) |field| writer.writePair(field, ext.subsystemIdText());
                    if (formatKey(key[0..], "EXT", ext.extText(), "FORMAT")) |field| writer.writePair(field, ext.formatIdText());
                },
            }
            if (formatKey(key[0..], "EXT", ext.extText(), "TYPE")) |field| writer.writePair(field, ext.typeNameText());
            if (formatKey(key[0..], "EXT", ext.extText(), "SHORT")) |field| writer.writePair(field, ext.shortNameText());
            if (formatKey(key[0..], "EXT", ext.extText(), "PREFIX")) |field| writer.writePair(field, ext.prefixText());
            if (formatKey(key[0..], "EXT", ext.extText(), "RANK")) |field| writer.writePairU32(field, ext.rank);
        }

        index = 0;
        while (index < self.foreign_count) : (index += 1) {
            writer.writePair(spanZ(self.foreign[index].key[0..]), spanZ(self.foreign[index].value[0..]));
        }

        return if (writer.ok()) writer.bytes() else out[0..0];
    }

    pub fn appById(self: *const Config, id: []const u8) ?*const AppEntry {
        var normalized: [app_id_max + 1]u8 = .{0} ** (app_id_max + 1);
        if (!copyNormalizedId(normalized[0..], id)) return null;
        var index: usize = 0;
        while (index < self.app_count) : (index += 1) {
            const app = &self.apps[index];
            if (usableApp(app) and equalsZ(app.id[0..], normalized[0..])) return app;
        }
        return null;
    }

    pub fn extensionByName(self: *const Config, ext_name: []const u8) ?*const ExtEntry {
        var normalized: [ext_max + 1]u8 = .{0} ** (ext_max + 1);
        if (!copyNormalizedExt(normalized[0..], ext_name)) return null;
        var index: usize = 0;
        while (index < self.extension_count) : (index += 1) {
            const ext = &self.extensions[index];
            if (ext.valid and equalsZ(ext.ext[0..], normalized[0..])) return ext;
        }
        return null;
    }

    pub fn resolvePath(self: *const Config, path: []const u8, args_out: []u8) ?LaunchTarget {
        if (isR4XPath(path)) {
            if (args_out.len == 0) return null;
            args_out[0] = 0;
            return .{
                .kind = .direct_program,
                .app_id = "",
                .title = "R4X App",
                .app_path = path,
                .args = args_out[0..0],
                .policy = .auto,
                .type_name = "R4X program",
                .short_name = "R4X",
                .prefix = "[APP]",
                .rank = 1,
            };
        }
        const ext_name = extensionOfPath(path) orelse return null;
        if (self.extensionByName(ext_name)) |ext| {
            if (ext.handler_kind != .app) return null;
            if (self.appById(ext.appIdText())) |app| {
                return targetFromEntry(app, ext, path, args_out);
            }
        }
        if (defaultInfoForExtension(ext_name)) |defaults| {
            if (self.appById(defaults.app_id)) |app| {
                return targetFromDefaults(app, defaults, path, args_out);
            }
        }
        return null;
    }

    pub fn expandAppArgs(self: *const Config, app_id: []const u8, file_path: []const u8, out: []u8) ?[]const u8 {
        const app = self.appById(app_id) orelse return null;
        return expandArgs(app.argsText(), file_path, out);
    }

    pub fn setExtensionApp(self: *Config, index: usize, app_id: []const u8) bool {
        if (index >= self.extension_count or self.appById(app_id) == null) return false;
        const ext = &self.extensions[index];
        if (!copyNormalizedId(ext.app_id[0..], app_id)) return false;
        ext.handler_kind = .app;
        @memset(ext.subsystem_id[0..], 0);
        @memset(ext.format_id[0..], 0);
        return true;
    }

    pub fn setExtensionSubsystem(self: *Config, index: usize, subsystem_id: []const u8, format_id: []const u8) bool {
        if (index >= self.extension_count) return false;
        var subsystem_storage: [subsystem_id_max + 1]u8 = .{0} ** (subsystem_id_max + 1);
        var format_storage: [format_id_max + 1]u8 = .{0} ** (format_id_max + 1);
        if (!copyIdentifier(subsystem_storage[0..], subsystem_id) or !copyIdentifier(format_storage[0..], format_id)) return false;
        const ext = &self.extensions[index];
        ext.handler_kind = .subsystem;
        ext.subsystem_id = subsystem_storage;
        ext.format_id = format_storage;
        @memset(ext.app_id[0..], 0);
        return true;
    }

    pub fn setExtensionNone(self: *Config, index: usize) bool {
        if (index >= self.extension_count) return false;
        const ext = &self.extensions[index];
        ext.handler_kind = .none;
        @memset(ext.app_id[0..], 0);
        @memset(ext.subsystem_id[0..], 0);
        @memset(ext.format_id[0..], 0);
        return true;
    }

    fn addExtensionGroup(self: *Config, comptime extensions: []const []const u8, app_id: []const u8, type_name: []const u8, short_name: []const u8, prefix: []const u8, rank: u8) void {
        inline for (extensions) |ext| {
            _ = self.addExtension(ext, app_id, type_name, short_name, prefix, rank);
        }
    }

    fn addApp(self: *Config, id: []const u8, title: []const u8, path: []const u8, policy: abi.LaunchPolicy, args: []const u8) bool {
        const app = self.findOrAddApp(id) orelse return false;
        setZ(app.title[0..], title);
        setZ(app.path[0..], path);
        app.policy = policy;
        setZ(app.args[0..], args);
        return true;
    }

    fn addExtension(self: *Config, ext_name: []const u8, app_id: []const u8, type_name: []const u8, short_name: []const u8, prefix: []const u8, rank: u8) bool {
        const ext = self.findOrAddExtension(ext_name) orelse return false;
        if (!copyNormalizedId(ext.app_id[0..], app_id)) return false;
        setZ(ext.type_name[0..], type_name);
        setZ(ext.short_name[0..], short_name);
        setZ(ext.prefix[0..], prefix);
        ext.rank = rank;
        return true;
    }

    fn addSubsystemExtension(self: *Config, ext_name: []const u8, subsystem_id: []const u8, format_id: []const u8, type_name: []const u8, short_name: []const u8, prefix: []const u8, rank: u8) bool {
        const ext = self.findOrAddExtension(ext_name) orelse return false;
        if (!copyIdentifier(ext.subsystem_id[0..], subsystem_id) or !copyIdentifier(ext.format_id[0..], format_id)) return false;
        ext.handler_kind = .subsystem;
        @memset(ext.app_id[0..], 0);
        setZ(ext.type_name[0..], type_name);
        setZ(ext.short_name[0..], short_name);
        setZ(ext.prefix[0..], prefix);
        ext.rank = rank;
        return true;
    }

    fn applyAppField(self: *Config, id: []const u8, field: []const u8, value: []const u8) bool {
        const app = self.findOrAddApp(id) orelse return false;
        const text = settings.trim(value);
        if (settings.equalsKey(field, "TITLE")) {
            if (text.len == 0 or text.len > title_max) return false;
            setZ(app.title[0..], text);
            return true;
        }
        if (settings.equalsKey(field, "PATH")) {
            if (text.len > path_max or !validAppPath(text)) return false;
            setZ(app.path[0..], text);
            return true;
        }
        if (settings.equalsKey(field, "POLICY")) {
            app.policy = parsePolicy(text) orelse return false;
            return true;
        }
        if (settings.equalsKey(field, "ARGS")) {
            if (text.len > args_max or !hasPathPlaceholder(text)) return false;
            setZ(app.args[0..], text);
            return true;
        }
        return false;
    }

    fn applyExtField(self: *Config, ext_name: []const u8, field: []const u8, value: []const u8) bool {
        const ext = self.findOrAddExtension(ext_name) orelse return false;
        const text = settings.trim(value);
        if (settings.equalsKey(field, "HANDLER")) {
            ext.handler_kind = parseHandlerKind(text) orelse return false;
            return true;
        }
        if (settings.equalsKey(field, "APP")) {
            return copyNormalizedId(ext.app_id[0..], text);
        }
        if (settings.equalsKey(field, "SUBSYSTEM")) {
            return copyIdentifier(ext.subsystem_id[0..], text);
        }
        if (settings.equalsKey(field, "FORMAT")) {
            return copyIdentifier(ext.format_id[0..], text);
        }
        if (settings.equalsKey(field, "TYPE")) {
            if (text.len == 0 or text.len > type_name_max) return false;
            setZ(ext.type_name[0..], text);
            return true;
        }
        if (settings.equalsKey(field, "SHORT")) {
            if (text.len == 0 or text.len > short_name_max) return false;
            setZ(ext.short_name[0..], text);
            return true;
        }
        if (settings.equalsKey(field, "PREFIX")) {
            if (text.len == 0 or text.len > prefix_max) return false;
            setZ(ext.prefix[0..], text);
            return true;
        }
        if (settings.equalsKey(field, "RANK")) {
            const rank = settings.parseU32(text) orelse return false;
            if (rank > std.math.maxInt(u8)) return false;
            ext.rank = @intCast(rank);
            return true;
        }
        return false;
    }

    fn preserveForeign(self: *Config, key: []const u8, value: []const u8) bool {
        if (self.foreign_count >= foreign_max or key.len == 0 or key.len > foreign_key_max or value.len > foreign_value_max) return false;
        const entry = &self.foreign[self.foreign_count];
        @memset(entry.key[0..], 0);
        @memset(entry.value[0..], 0);
        @memcpy(entry.key[0..key.len], key);
        @memcpy(entry.value[0..value.len], value);
        self.foreign_count += 1;
        return true;
    }

    fn findOrAddApp(self: *Config, id: []const u8) ?*AppEntry {
        var normalized: [app_id_max + 1]u8 = .{0} ** (app_id_max + 1);
        if (!copyNormalizedId(normalized[0..], id)) return null;
        var index: usize = 0;
        while (index < self.app_count) : (index += 1) {
            if (equalsZ(self.apps[index].id[0..], normalized[0..])) return &self.apps[index];
        }
        if (self.app_count >= max_apps) return null;
        index = self.app_count;
        self.app_count += 1;
        self.apps[index] = AppEntry{ .valid = true };
        setZ(self.apps[index].id[0..], spanZ(normalized[0..]));
        self.apps[index].policy = .auto;
        return &self.apps[index];
    }

    fn findOrAddExtension(self: *Config, ext_name: []const u8) ?*ExtEntry {
        var normalized: [ext_max + 1]u8 = .{0} ** (ext_max + 1);
        if (!copyNormalizedExt(normalized[0..], ext_name)) return null;
        var index: usize = 0;
        while (index < self.extension_count) : (index += 1) {
            if (equalsZ(self.extensions[index].ext[0..], normalized[0..])) return &self.extensions[index];
        }
        if (self.extension_count >= max_extensions) return null;
        index = self.extension_count;
        self.extension_count += 1;
        self.extensions[index] = ExtEntry{ .valid = true };
        setZ(self.extensions[index].ext[0..], spanZ(normalized[0..]));
        if (defaultInfoForExtension(spanZ(normalized[0..]))) |defaults| {
            _ = copyNormalizedId(self.extensions[index].app_id[0..], defaults.app_id);
            setZ(self.extensions[index].type_name[0..], defaults.type_name);
            setZ(self.extensions[index].short_name[0..], defaults.short_name);
            setZ(self.extensions[index].prefix[0..], defaults.prefix);
            self.extensions[index].rank = defaults.rank;
        } else {
            setZ(self.extensions[index].type_name[0..], "File");
            setZ(self.extensions[index].short_name[0..], "File");
            self.extensions[index].rank = 6;
        }
        return &self.extensions[index];
    }
};

pub fn expandArgs(template: []const u8, file_path: []const u8, out: []u8) ?[]const u8 {
    if (out.len == 0) return null;
    @memset(out, 0);
    var found = false;
    var pos: usize = 0;
    var index: usize = 0;
    while (index < template.len) {
        if (template[index] == '%' and index + 1 < template.len and template[index + 1] == '1') {
            found = true;
            if (!appendSlice(out, &pos, file_path)) return null;
            index += 2;
            continue;
        }
        if (pos >= out.len - 1) return null;
        out[pos] = template[index];
        pos += 1;
        index += 1;
    }
    if (!found) return null;
    out[pos] = 0;
    return out[0..pos];
}

pub fn extensionOfPath(path: []const u8) ?[]const u8 {
    var start: ?usize = null;
    var index: usize = 0;
    while (index < path.len) : (index += 1) {
        const ch = path[index];
        if (ch == '\\' or ch == '/') {
            start = null;
        } else if (ch == '.') {
            start = index + 1;
        }
    }
    const ext_start = start orelse return null;
    if (ext_start >= path.len) return null;
    return path[ext_start..];
}

pub fn isR4XPath(path: []const u8) bool {
    return endsWithIgnoreCase(path, ".R4X");
}

fn targetFromEntry(app: *const AppEntry, ext: *const ExtEntry, path: []const u8, args_out: []u8) ?LaunchTarget {
    const args = expandArgs(app.argsText(), path, args_out) orelse return null;
    return .{
        .kind = .associated,
        .app_id = app.idText(),
        .title = app.titleText(),
        .app_path = app.pathText(),
        .args = args,
        .policy = app.policy,
        .type_name = ext.typeNameText(),
        .short_name = ext.shortNameText(),
        .prefix = ext.prefixText(),
        .rank = ext.rank,
    };
}

fn targetFromDefaults(app: *const AppEntry, defaults: ExtDefaults, path: []const u8, args_out: []u8) ?LaunchTarget {
    const args = expandArgs(app.argsText(), path, args_out) orelse return null;
    return .{
        .kind = .associated,
        .app_id = app.idText(),
        .title = app.titleText(),
        .app_path = app.pathText(),
        .args = args,
        .policy = app.policy,
        .type_name = defaults.type_name,
        .short_name = defaults.short_name,
        .prefix = defaults.prefix,
        .rank = defaults.rank,
    };
}

fn parseScopedKey(key: []const u8, scope: []const u8) ?ScopedKey {
    const first = findByte(key, '.') orelse return null;
    if (!settings.equalsKey(key[0..first], scope)) return null;
    const rest = key[first + 1 ..];
    const second = findByte(rest, '.') orelse return null;
    const id = rest[0..second];
    const field = rest[second + 1 ..];
    if (id.len == 0 or field.len == 0 or findByte(field, '.') != null) return null;
    return .{ .id = id, .field = field };
}

fn usableApp(app: *const AppEntry) bool {
    return app.valid and app.idText().len != 0 and validAppPath(app.pathText()) and hasPathPlaceholder(app.argsText());
}

fn usableExtension(config: *const Config, ext: *const ExtEntry) bool {
    if (!ext.valid or ext.extText().len == 0) return false;
    return switch (ext.handler_kind) {
        .none => true,
        .app => config.appById(ext.appIdText()) != null,
        .subsystem => validIdentifier(ext.subsystemIdText()) and validIdentifier(ext.formatIdText()),
    };
}

fn validAppPath(path: []const u8) bool {
    const text = settings.trim(path);
    _ = path_contract.AbsoluteFilePath.parse(text) catch return false;
    return isR4XPath(text);
}

fn isKnownAppField(field: []const u8) bool {
    return settings.equalsKey(field, "TITLE") or settings.equalsKey(field, "PATH") or settings.equalsKey(field, "POLICY") or settings.equalsKey(field, "ARGS");
}

fn isKnownExtField(field: []const u8) bool {
    return settings.equalsKey(field, "HANDLER") or settings.equalsKey(field, "APP") or settings.equalsKey(field, "SUBSYSTEM") or
        settings.equalsKey(field, "FORMAT") or settings.equalsKey(field, "TYPE") or settings.equalsKey(field, "SHORT") or
        settings.equalsKey(field, "PREFIX") or settings.equalsKey(field, "RANK");
}

fn parseHandlerKind(value: []const u8) ?HandlerKind {
    if (settings.equalsKey(value, "NONE")) return .none;
    if (settings.equalsKey(value, "APP")) return .app;
    if (settings.equalsKey(value, "SUBSYSTEM")) return .subsystem;
    return null;
}

fn handlerKindText(value: HandlerKind) []const u8 {
    return switch (value) {
        .none => "NONE",
        .app => "APP",
        .subsystem => "SUBSYSTEM",
    };
}

fn parsePolicy(value: []const u8) ?abi.LaunchPolicy {
    if (settings.equalsKey(value, "auto")) return .auto;
    if (settings.equalsKey(value, "console")) return .console;
    if (settings.equalsKey(value, "gui")) return .gui;
    return null;
}

fn policyText(policy: abi.LaunchPolicy) []const u8 {
    return switch (policy) {
        .auto => "auto",
        .console => "console",
        .gui => "gui",
    };
}

fn hasPathPlaceholder(value: []const u8) bool {
    return std.mem.indexOf(u8, value, "%1") != null;
}

fn defaultInfoForExtension(ext_name: []const u8) ?ExtDefaults {
    if (settings.equalsKey(ext_name, "TXT") or settings.equalsKey(ext_name, "R4S") or settings.equalsKey(ext_name, "BAT") or settings.equalsKey(ext_name, "LOG") or settings.equalsKey(ext_name, "MD") or settings.equalsKey(ext_name, "INI") or settings.equalsKey(ext_name, "CFG")) {
        return .{ .app_id = "NOTEPAD", .type_name = "Text", .short_name = "Text", .prefix = "[TXT]", .rank = 3 };
    }
    if (settings.equalsKey(ext_name, "BMP")) {
        return .{ .app_id = "PAINT", .type_name = "Bitmap", .short_name = "BMP", .prefix = "[BMP]", .rank = 4 };
    }
    if (settings.equalsKey(ext_name, "WAV") or settings.equalsKey(ext_name, "MID") or settings.equalsKey(ext_name, "SID")) {
        return .{ .app_id = "SYNTH", .type_name = "Audio", .short_name = "Audio", .prefix = "[AUD]", .rank = 5 };
    }
    return null;
}

fn formatKey(out: []u8, scope: []const u8, id: []const u8, field: []const u8) ?[]const u8 {
    if (out.len == 0) return null;
    @memset(out, 0);
    var pos: usize = 0;
    if (!appendSlice(out, &pos, scope)) return null;
    if (!appendByte(out, &pos, '.')) return null;
    if (!appendSlice(out, &pos, id)) return null;
    if (!appendByte(out, &pos, '.')) return null;
    if (!appendSlice(out, &pos, field)) return null;
    out[pos] = 0;
    return out[0..pos];
}

fn copyNormalizedId(out: []u8, value: []const u8) bool {
    return copyNormalizedSymbol(out, value, app_id_max, false);
}

fn copyNormalizedExt(out: []u8, value: []const u8) bool {
    var text = settings.trim(value);
    if (text.len > 0 and text[0] == '.') text = text[1..];
    return copyNormalizedSymbol(out, text, ext_max, true);
}

fn copyIdentifier(out: []u8, value: []const u8) bool {
    const text = settings.trim(value);
    if (!validIdentifier(text) or text.len + 1 > out.len) return false;
    @memset(out, 0);
    @memcpy(out[0..text.len], text);
    return true;
}

fn validIdentifier(value: []const u8) bool {
    if (value.len == 0 or value.len > subsystem_id_max or !std.ascii.isAlphabetic(value[0]) or !std.ascii.isAlphanumeric(value[value.len - 1])) return false;
    for (value) |byte| if (!std.ascii.isAlphanumeric(byte) and byte != '.' and byte != '_' and byte != '-') return false;
    return true;
}

fn copyNormalizedSymbol(out: []u8, value: []const u8, max_len: usize, extension: bool) bool {
    const text = settings.trim(value);
    if (out.len == 0 or text.len == 0 or text.len > max_len or text.len + 1 > out.len) return false;
    @memset(out, 0);
    var index: usize = 0;
    while (index < text.len) : (index += 1) {
        const upper = asciiUpper(text[index]);
        if (extension) {
            if (!isAsciiAlnum(upper)) return false;
        } else if (!isAsciiAlnum(upper) and upper != '_' and upper != '-') {
            return false;
        }
        out[index] = upper;
    }
    out[text.len] = 0;
    return true;
}

fn setZ(out: []u8, value: []const u8) void {
    if (out.len == 0) return;
    @memset(out, 0);
    const count = @min(value.len, out.len - 1);
    if (count > 0) @memcpy(out[0..count], value[0..count]);
    out[count] = 0;
}

fn spanZ(buf: []const u8) []const u8 {
    var len: usize = 0;
    while (len < buf.len and buf[len] != 0) : (len += 1) {}
    return buf[0..len];
}

fn equalsZ(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, spanZ(a), spanZ(b));
}

fn appendSlice(out: []u8, pos: *usize, value: []const u8) bool {
    if (out.len == 0 or pos.* > out.len - 1 or value.len > out.len - 1 - pos.*) return false;
    if (value.len > 0) @memcpy(out[pos.* .. pos.* + value.len], value);
    pos.* += value.len;
    return true;
}

fn appendByte(out: []u8, pos: *usize, value: u8) bool {
    if (out.len == 0 or pos.* >= out.len - 1) return false;
    out[pos.*] = value;
    pos.* += 1;
    return true;
}

fn findByte(value: []const u8, needle: u8) ?usize {
    var index: usize = 0;
    while (index < value.len) : (index += 1) {
        if (value[index] == needle) return index;
    }
    return null;
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

fn asciiUpper(ch: u8) u8 {
    if (ch >= 'a' and ch <= 'z') return ch - ('a' - 'A');
    return ch;
}

fn isAsciiAlnum(ch: u8) bool {
    return (ch >= 'A' and ch <= 'Z') or (ch >= '0' and ch <= '9');
}

test "default associations match Explorer contract" {
    var config = Config.initDefault();
    var args: [128]u8 = .{0} ** 128;
    const text = config.resolvePath("C:\\TEMP\\README.txt", args[0..]).?;
    try std.testing.expectEqual(LaunchKind.associated, text.kind);
    try std.testing.expectEqualStrings("NOTEPAD", text.app_id);
    try std.testing.expectEqualStrings("C:\\R4OS\\SOFTWARE\\DESKTOP\\NOTEPAD.R4X", text.app_path);
    try std.testing.expectEqualStrings("C:\\TEMP\\README.txt", text.args);
    try std.testing.expectEqual(abi.LaunchPolicy.gui, text.policy);
    try std.testing.expectEqualStrings("[TXT]", text.prefix);

    const bmp = config.resolvePath("D:\\IMAGE.BMP", args[0..]).?;
    try std.testing.expectEqualStrings("PAINT", bmp.app_id);

    const font = config.resolvePath("C:\\TEMP\\FONTS\\COURA.FON", args[0..]).?;
    try std.testing.expectEqualStrings("FONTS", font.app_id);
    try std.testing.expectEqualStrings("C:\\R4OS\\SOFTWARE\\DESKTOP\\FONTS.R4X", font.app_path);
    try std.testing.expectEqualStrings("C:\\TEMP\\FONTS\\COURA.FON", font.args);
    try std.testing.expectEqualStrings("Bitmap", bmp.type_name);
    try std.testing.expectEqual(abi.LaunchPolicy.gui, bmp.policy);

    const wav = config.resolvePath("C:\\TEMP\\TADA.WAV", args[0..]).?;
    try std.testing.expectEqualStrings("SYNTH", wav.app_id);
    try std.testing.expectEqual(abi.LaunchPolicy.console, wav.policy);
    try std.testing.expectEqualStrings("[AUD]", wav.prefix);

    const basic = config.extensionByName("BAS").?;
    try std.testing.expectEqual(HandlerKind.subsystem, basic.handler_kind);
    try std.testing.expectEqualStrings("r4os.basic", basic.subsystemIdText());
    try std.testing.expectEqualStrings("basic.qbasic-source", basic.formatIdText());
}

test "r4x files stay direct program launches" {
    var config = Config.initDefault();
    var args: [16]u8 = .{0} ** 16;
    const target = config.resolvePath("C:\\R4OS\\SOFTWARE\\DESKTOP\\APP.R4X", args[0..]).?;
    try std.testing.expectEqual(LaunchKind.direct_program, target.kind);
    try std.testing.expectEqualStrings("C:\\R4OS\\SOFTWARE\\DESKTOP\\APP.R4X", target.app_path);
    try std.testing.expectEqualStrings("", target.args);
    try std.testing.expectEqual(abi.LaunchPolicy.auto, target.policy);
}

test "parser accepts overrides and writer emits canonical schema" {
    if (!runtime.hasSettings()) return error.SkipZigTest;
    var config = Config{};
    try std.testing.expect(config.loadFromBytes(
        \\R4S_FORMAT=1
        \\SCHEMA=APPASSOC
        \\APP.NOTEPAD.TITLE=Editor
        \\APP.NOTEPAD.PATH=C:\R4OS\SOFTWARE\DESKTOP\EDITOR.R4X
        \\APP.NOTEPAD.POLICY=console
        \\APP.NOTEPAD.ARGS=/OPEN %1
        \\EXT.TXT.APP=NOTEPAD
    ));
    var args: [128]u8 = .{0} ** 128;
    const target = config.resolvePath("C:\\AUTOEXEC.BAT", args[0..]).?;
    try std.testing.expectEqualStrings("Editor", target.title);
    try std.testing.expectEqualStrings("C:\\R4OS\\SOFTWARE\\DESKTOP\\EDITOR.R4X", target.app_path);
    try std.testing.expectEqualStrings("/OPEN C:\\AUTOEXEC.BAT", target.args);
    try std.testing.expectEqual(abi.LaunchPolicy.console, target.policy);

    var out: [4096]u8 = .{0} ** 4096;
    const bytes = config.writeTo(out[0..]);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "SCHEMA=APPASSOC") != null);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "APP.NOTEPAD.PATH=C:\\R4OS\\SOFTWARE\\DESKTOP\\EDITOR.R4X") != null);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "EXT.TXT.APP=NOTEPAD") != null);
}

test "case-insensitive extensions and app ids resolve" {
    if (!runtime.hasSettings()) return error.SkipZigTest;
    var config = Config{};
    try std.testing.expect(config.loadFromBytes(
        \\schema=appassoc
        \\app.viewer.title=Viewer
        \\app.viewer.path=C:\R4OS\SOFTWARE\DESKTOP\VIEWER.R4X
        \\app.viewer.policy=gui
        \\app.viewer.args=--file %1
        \\ext.dat.app=viewer
        \\ext.dat.type=Data
        \\ext.dat.short=DAT
        \\ext.dat.prefix=[DAT]
        \\ext.dat.rank=6
    ));
    var args: [128]u8 = .{0} ** 128;
    const target = config.resolvePath("C:\\TEMP\\FILE.Dat", args[0..]).?;
    try std.testing.expectEqualStrings("VIEWER", target.app_id);
    try std.testing.expectEqualStrings("--file C:\\TEMP\\FILE.Dat", target.args);
    try std.testing.expectEqualStrings("Data", target.type_name);
}

test "broken entries keep defaults or fail visibly" {
    if (!runtime.hasSettings()) return error.SkipZigTest;
    var config = Config{};
    try std.testing.expect(config.loadFromBytes(
        \\SCHEMA=APPASSOC
        \\BROKEN LINE WITHOUT EQUALS
        \\APP.PAINT.PATH=C:\R4OS\SOFTWARE\DESKTOP\PAINT.TXT
        \\APP.BAD.ID.PATH=C:\R4OS\SOFTWARE\DESKTOP\BAD.R4X
        \\APP.CUSTOM.TITLE=Custom
        \\APP.CUSTOM.ARGS=%1
        \\EXT.BIN.APP=CUSTOM
        \\EXT.TXT.APP=BAD.ID
    ));
    var args: [128]u8 = .{0} ** 128;
    const bmp = config.resolvePath("C:\\TEMP\\PIC.BMP", args[0..]).?;
    try std.testing.expectEqualStrings("C:\\R4OS\\SOFTWARE\\DESKTOP\\PAINT.R4X", bmp.app_path);

    const txt = config.resolvePath("C:\\TEMP\\NOTE.TXT", args[0..]).?;
    try std.testing.expectEqualStrings("NOTEPAD", txt.app_id);

    try std.testing.expect(config.resolvePath("C:\\TEMP\\DATA.BIN", args[0..]) == null);
}

test "argument expansion requires placeholder and enough space" {
    var out: [64]u8 = .{0} ** 64;
    try std.testing.expectEqualStrings("/OPEN C:\\A.TXT", expandArgs("/OPEN %1", "C:\\A.TXT", out[0..]).?);
    try std.testing.expect(expandArgs("/OPEN", "C:\\A.TXT", out[0..]) == null);
    var tiny: [4]u8 = .{0} ** 4;
    try std.testing.expect(expandArgs("%1", "C:\\TOO-LONG.TXT", tiny[0..]) == null);
}

test "writer roundtrip preserves usable custom associations" {
    if (!runtime.hasSettings()) return error.SkipZigTest;
    var config = Config{};
    try std.testing.expect(config.loadFromBytes(
        \\SCHEMA=APPASSOC
        \\APP.VIEW.TITLE=Viewer
        \\APP.VIEW.PATH=C:\R4OS\SOFTWARE\DESKTOP\VIEW.R4X
        \\APP.VIEW.POLICY=gui
        \\APP.VIEW.ARGS=%1
        \\EXT.DAT.APP=VIEW
        \\EXT.DAT.TYPE=Data
        \\EXT.DAT.SHORT=DAT
        \\EXT.DAT.PREFIX=[DAT]
        \\EXT.DAT.RANK=6
    ));
    var bytes_buf: [4096]u8 = .{0} ** 4096;
    const bytes = config.writeTo(bytes_buf[0..]);

    var roundtrip = Config{};
    try std.testing.expect(roundtrip.loadFromBytes(bytes));
    var args: [128]u8 = .{0} ** 128;
    const target = roundtrip.resolvePath("D:\\FILE.DAT", args[0..]).?;
    try std.testing.expectEqualStrings("VIEW", target.app_id);
    try std.testing.expectEqualStrings("C:\\R4OS\\SOFTWARE\\DESKTOP\\VIEW.R4X", target.app_path);
    try std.testing.expectEqualStrings("D:\\FILE.DAT", target.args);
}

test "subsystem and removed handlers persist without copying installed host metadata" {
    if (!runtime.hasSettings()) return error.SkipZigTest;
    var config = Config{};
    try std.testing.expect(config.loadFromBytes(
        \\SCHEMA=APPASSOC
        \\EXT.BAS.HANDLER=SUBSYSTEM
        \\EXT.BAS.SUBSYSTEM=basic.qbasic
        \\EXT.BAS.FORMAT=basic.qbasic-source
        \\EXT.BAS.TYPE=BASIC source
        \\EXT.BAS.SHORT=BAS
        \\EXT.BAS.PREFIX=[BAS]
        \\EXT.BAS.RANK=3
        \\EXT.TXT.HANDLER=NONE
    ));
    const basic = config.extensionByName("BAS").?;
    try std.testing.expectEqual(HandlerKind.subsystem, basic.handler_kind);
    try std.testing.expectEqualStrings("basic.qbasic", basic.subsystemIdText());
    var args: [128]u8 = undefined;
    try std.testing.expect(config.resolvePath("C:\\GORILLA.BAS", args[0..]) == null);
    try std.testing.expectEqual(HandlerKind.none, config.extensionByName("TXT").?.handler_kind);

    var storage: [4096]u8 = undefined;
    const written = config.writeTo(storage[0..]);
    try std.testing.expect(std.mem.indexOf(u8, written, "EXT.BAS.HANDLER=SUBSYSTEM") != null);
    try std.testing.expect(std.mem.indexOf(u8, written, "EXT.BAS.SUBSYSTEM=basic.qbasic") != null);
    try std.testing.expect(std.mem.indexOf(u8, written, "SUBSYSOK.R4X") == null);
    try std.testing.expect(std.mem.indexOf(u8, written, "EXT.TXT.HANDLER=NONE") != null);

    var roundtrip = Config{};
    try std.testing.expect(roundtrip.loadFromBytes(written));
    try std.testing.expectEqualStrings("basic.qbasic-source", roundtrip.extensionByName("BAS").?.formatIdText());
    try std.testing.expectEqual(HandlerKind.none, roundtrip.extensionByName("TXT").?.handler_kind);
}

test "association paths reject overlength and foreign entries survive write" {
    if (!runtime.hasSettings()) return error.SkipZigTest;
    var long_path: [path_max + 1]u8 = .{'A'} ** (path_max + 1);
    @memcpy(long_path[0..3], "C:\\");
    @memcpy(long_path[long_path.len - 4 ..], ".R4X");
    var source: [path_max + 128]u8 = .{0} ** (path_max + 128);
    const prefix = "R4S_FORMAT=1\nSCHEMA=APPASSOC\nFOREIGN.FLAG=KEEP\nAPP.NOTEPAD.PATH=";
    @memcpy(source[0..prefix.len], prefix);
    @memcpy(source[prefix.len .. prefix.len + long_path.len], long_path[0..]);
    source[prefix.len + long_path.len] = '\n';

    var config = Config.initDefault();
    _ = config.loadFromBytes(source[0 .. prefix.len + long_path.len + 1]);
    try std.testing.expectEqualStrings("C:\\R4OS\\SOFTWARE\\DESKTOP\\NOTEPAD.R4X", config.appById("NOTEPAD").?.pathText());
    var out: [4096]u8 = undefined;
    const written = config.writeTo(out[0..]);
    try std.testing.expect(std.mem.indexOf(u8, written, "FOREIGN.FLAG=KEEP") != null);
    try std.testing.expect(std.mem.indexOf(u8, written, long_path[0..]) == null);
}
