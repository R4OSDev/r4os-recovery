const std = @import("std");

pub const max_sources = 12;
pub const max_imports = 12;
pub const max_exports = 12;
pub const max_metadata = 16;
pub const max_contracts = 8;

pub const ModuleKind = enum {
    r4x,
    r4d,
    r4p,
    r4l,
};

pub const Language = enum {
    zig,
    c,
};

pub const ProfileClass = enum {
    internal,
    external_compatible,
};

pub const Token = struct {
    name: []const u8,
    value: []const u8,
};

pub const RenderResult = struct {
    bytes: []const u8,
    ok: bool,
};

pub const ProjectTemplateValues = struct {
    project_name: []const u8,
    module_kind: []const u8,
    language: []const u8,
    build_profile: []const u8,
    app_class: []const u8,
    artifact: []const u8,
    target_path: []const u8,
};

pub const Item = struct {
    key: []const u8 = "",
    value: []const u8 = "",
};

pub const Project = struct {
    name: []const u8 = "",
    module_kind: ModuleKind = .r4x,
    language: Language = .c,
    build_profile: []const u8 = "",
    app_class: []const u8 = "auto",
    artifact: []const u8 = "",
    target_path: []const u8 = "",
    test_profile: []const u8 = "",

    source_items: [max_sources]Item = [_]Item{.{}} ** max_sources,
    source_count: usize = 0,
    import_items: [max_imports]Item = [_]Item{.{}} ** max_imports,
    import_count: usize = 0,
    export_items: [max_exports]Item = [_]Item{.{}} ** max_exports,
    export_count: usize = 0,
    metadata_items: [max_metadata]Item = [_]Item{.{}} ** max_metadata,
    metadata_count: usize = 0,
    contract_items: [max_contracts]Item = [_]Item{.{}} ** max_contracts,
    contract_count: usize = 0,

    pub fn sources(self: *const Project) []const Item {
        return self.source_items[0..self.source_count];
    }

    pub fn imports(self: *const Project) []const Item {
        return self.import_items[0..self.import_count];
    }

    pub fn exports(self: *const Project) []const Item {
        return self.export_items[0..self.export_count];
    }

    pub fn metadata(self: *const Project) []const Item {
        return self.metadata_items[0..self.metadata_count];
    }

    pub fn contracts(self: *const Project) []const Item {
        return self.contract_items[0..self.contract_count];
    }

    pub fn hasR4XStart(self: *const Project) bool {
        for (self.exports()) |item| {
            if (startsWithIgnoreCase(trim(item.value), "R4XStart:")) return true;
        }
        for (self.metadata()) |item| {
            if (equalsIgnoreCase(item.key, "r4x.entry") and equalsIgnoreCase(item.value, "R4XStart")) return true;
            if (equalsIgnoreCase(item.key, "r4x.start") and equalsIgnoreCase(item.value, "r4xstart")) return true;
        }
        return false;
    }

    pub fn profileClass(self: *const Project) ?ProfileClass {
        if (equalsIgnoreCase(self.build_profile, "R4X_C_Console")) return .internal;
        if (equalsIgnoreCase(self.build_profile, "R4X_C_Desktop_OK")) return .internal;
        if (equalsIgnoreCase(self.build_profile, "R4X_C")) return .external_compatible;
        if (equalsIgnoreCase(self.build_profile, "R4X_Zig")) return .external_compatible;
        return null;
    }
};

pub const ParseError = error{
    InvalidSectionHeader,
    InvalidLine,
    KeyOutsideSection,
    InvalidKey,
    MissingProjectName,
    MissingModuleKind,
    InvalidModuleKind,
    MissingLanguage,
    InvalidLanguage,
    MissingBuildProfile,
    UnsupportedBuildProfile,
    IncompatibleBuildProfile,
    MissingSource,
    TooManySources,
    InvalidSourcePath,
    MissingArtifact,
    InvalidArtifactPath,
    MissingTargetPath,
    InvalidTargetPath,
    TooManyImports,
    InvalidImport,
    UnknownImportGroup,
    TooManyExports,
    TooManyMetadata,
    TooManyContracts,
    MissingR4XStart,
    HostPathRejected,
};

const Section = enum {
    none,
    project,
    sources,
    imports,
    exports,
    metadata,
    contracts,
    output,
    test_section,
    unknown,
};

pub fn parse(bytes: []const u8) ParseError!Project {
    var project: Project = .{};
    var section: Section = .none;
    var rest = stripUtf8Bom(bytes);

    while (nextLine(&rest)) |raw_line| {
        const line = trim(raw_line);
        if (line.len == 0 or line[0] == '#' or line[0] == ';') continue;
        if (line[0] == '[') {
            section = try parseSection(line);
            continue;
        }

        const entry = try parseEntry(line);
        if (containsHostTruth(entry.value)) return error.HostPathRejected;

        switch (section) {
            .none => return error.KeyOutsideSection,
            .project => try applyProjectEntry(&project, entry),
            .sources => try addPathItem(&project.source_items, &project.source_count, max_sources, entry, .source),
            .imports => try addImport(&project, entry),
            .exports => try addItem(&project.export_items, &project.export_count, max_exports, entry, error.TooManyExports),
            .metadata => try addItem(&project.metadata_items, &project.metadata_count, max_metadata, entry, error.TooManyMetadata),
            .contracts => try addItem(&project.contract_items, &project.contract_count, max_contracts, entry, error.TooManyContracts),
            .output => try applyOutputEntry(&project, entry),
            .test_section => {
                if (equalsIgnoreCase(entry.key, "Profile")) project.test_profile = entry.value;
            },
            .unknown => {},
        }
    }

    try validateProject(project);
    return project;
}

pub fn errorMessage(err: ParseError) []const u8 {
    return switch (err) {
        error.InvalidSectionHeader => "Invalid section header.",
        error.InvalidLine => "Invalid R4CP line; expected Key=Value.",
        error.KeyOutsideSection => "Project key is outside a section.",
        error.InvalidKey => "Project key contains invalid characters.",
        error.MissingProjectName => "Missing [Project] Name.",
        error.MissingModuleKind => "Missing [Project] ModuleKind.",
        error.InvalidModuleKind => "Invalid [Project] ModuleKind.",
        error.MissingLanguage => "Missing [Project] Language.",
        error.InvalidLanguage => "Invalid [Project] Language.",
        error.MissingBuildProfile => "Missing [Project] BuildProfile.",
        error.UnsupportedBuildProfile => "Unsupported BuildProfile.",
        error.IncompatibleBuildProfile => "BuildProfile does not match module kind, language or app class.",
        error.MissingSource => "Project must contain at least one [Sources] entry.",
        error.TooManySources => "Project has too many [Sources] entries.",
        error.InvalidSourcePath => "Source paths must be project-relative.",
        error.MissingArtifact => "Missing [Output] Artifact.",
        error.InvalidArtifactPath => "Artifact path must be project-relative and end with the module extension.",
        error.MissingTargetPath => "Missing [Output] TargetPath.",
        error.InvalidTargetPath => "TargetPath must be an R4OS image path.",
        error.TooManyImports => "Project has too many [Imports] entries.",
        error.InvalidImport => "Import must use GROUP:Query:Version format.",
        error.UnknownImportGroup => "Project imports an unknown R4L group.",
        error.TooManyExports => "Project has too many [Exports] entries.",
        error.TooManyMetadata => "Project has too many [Metadata] entries.",
        error.TooManyContracts => "Project has too many [Contracts] entries.",
        error.MissingR4XStart => "R4X project must declare R4XStart.",
        error.HostPathRejected => "R4CP must not contain host/tool paths.",
    };
}

pub fn renderTemplate(template: []const u8, tokens: []const Token, out: []u8) RenderResult {
    var out_len: usize = 0;
    var ok = true;
    var i: usize = 0;
    while (i < template.len) {
        if (template[i] == '{') {
            if (matchToken(template[i..], tokens)) |match| {
                ok = appendBytes(out, &out_len, match.value) and ok;
                i += match.raw_len;
                continue;
            }
        }
        ok = appendByte(out, &out_len, template[i]) and ok;
        i += 1;
    }
    return .{ .bytes = out[0..@min(out_len, out.len)], .ok = ok };
}

pub fn renderProjectTemplate(template: []const u8, values: ProjectTemplateValues, out: []u8) RenderResult {
    var out_len: usize = 0;
    var ok = true;
    var i: usize = 0;
    while (i < template.len) {
        if (template[i] == '{') {
            if (matchProjectTemplateToken(template[i..], values)) |match| {
                ok = appendBytes(out, &out_len, match.value) and ok;
                i += match.raw_len;
                continue;
            }
        }
        ok = appendByte(out, &out_len, template[i]) and ok;
        i += 1;
    }
    return .{ .bytes = out[0..@min(out_len, out.len)], .ok = ok };
}

const TokenMatch = struct {
    raw_len: usize,
    value: []const u8,
};

fn matchToken(text: []const u8, tokens: []const Token) ?TokenMatch {
    for (tokens) |token| {
        if (token.name.len == 0) continue;
        const raw_len = token.name.len + 2;
        if (text.len < raw_len) continue;
        if (text[0] != '{' or text[raw_len - 1] != '}') continue;
        if (equalsBytes(text[1 .. raw_len - 1], token.name)) {
            return .{ .raw_len = raw_len, .value = token.value };
        }
    }
    return null;
}

fn matchProjectTemplateToken(text: []const u8, values: ProjectTemplateValues) ?TokenMatch {
    if (startsWithBytes(text, "{ProjectName}")) return .{ .raw_len = 13, .value = values.project_name };
    if (startsWithBytes(text, "{ModuleKind}")) return .{ .raw_len = 12, .value = values.module_kind };
    if (startsWithBytes(text, "{Language}")) return .{ .raw_len = 10, .value = values.language };
    if (startsWithBytes(text, "{BuildProfile}")) return .{ .raw_len = 14, .value = values.build_profile };
    if (startsWithBytes(text, "{AppClass}")) return .{ .raw_len = 10, .value = values.app_class };
    if (startsWithBytes(text, "{Artifact}")) return .{ .raw_len = 10, .value = values.artifact };
    if (startsWithBytes(text, "{TargetPath}")) return .{ .raw_len = 12, .value = values.target_path };
    return null;
}

fn equalsBytes(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    var i: usize = 0;
    while (i < a.len) : (i += 1) {
        if (a[i] != b[i]) return false;
    }
    return true;
}

fn startsWithBytes(value: []const u8, prefix: []const u8) bool {
    if (value.len < prefix.len) return false;
    return equalsBytes(value[0..prefix.len], prefix);
}

fn appendBytes(out: []u8, out_len: *usize, value: []const u8) bool {
    var ok = true;
    for (value) |ch| ok = appendByte(out, out_len, ch) and ok;
    return ok;
}

fn appendByte(out: []u8, out_len: *usize, ch: u8) bool {
    if (out_len.* >= out.len) {
        out_len.* += 1;
        return false;
    }
    out[out_len.*] = ch;
    out_len.* += 1;
    return true;
}

fn applyProjectEntry(project: *Project, entry: Item) ParseError!void {
    if (equalsIgnoreCase(entry.key, "Name")) {
        project.name = entry.value;
    } else if (equalsIgnoreCase(entry.key, "ModuleKind")) {
        project.module_kind = parseModuleKind(entry.value) orelse return error.InvalidModuleKind;
    } else if (equalsIgnoreCase(entry.key, "Language")) {
        project.language = parseLanguage(entry.value) orelse return error.InvalidLanguage;
    } else if (equalsIgnoreCase(entry.key, "BuildProfile")) {
        project.build_profile = entry.value;
    } else if (equalsIgnoreCase(entry.key, "AppClass")) {
        project.app_class = entry.value;
    }
}

fn applyOutputEntry(project: *Project, entry: Item) ParseError!void {
    if (equalsIgnoreCase(entry.key, "Artifact")) {
        project.artifact = entry.value;
    } else if (equalsIgnoreCase(entry.key, "TargetPath")) {
        project.target_path = entry.value;
    }
}

const PathItemKind = enum {
    source,
    artifact,
};

fn addPathItem(
    items: *[max_sources]Item,
    count: *usize,
    comptime limit: usize,
    entry: Item,
    kind: PathItemKind,
) ParseError!void {
    _ = limit;
    if (!isProjectRelativePath(entry.value)) {
        return switch (kind) {
            .source => error.InvalidSourcePath,
            .artifact => error.InvalidArtifactPath,
        };
    }
    try addItem(items, count, max_sources, entry, error.TooManySources);
}

fn addImport(project: *Project, entry: Item) ParseError!void {
    const group = importGroup(entry.value) orelse return error.InvalidImport;
    if (!knownPlatformGroup(group)) return error.UnknownImportGroup;
    try addItem(&project.import_items, &project.import_count, max_imports, entry, error.TooManyImports);
}

fn addItem(items: anytype, count: *usize, comptime limit: usize, entry: Item, too_many: ParseError) ParseError!void {
    if (count.* >= limit) return too_many;
    items.*[count.*] = entry;
    count.* += 1;
}

fn validateProject(project: Project) ParseError!void {
    if (project.name.len == 0) return error.MissingProjectName;
    if (project.build_profile.len == 0) return error.MissingBuildProfile;
    if (project.source_count == 0) return error.MissingSource;
    if (project.artifact.len == 0) return error.MissingArtifact;
    if (!isProjectRelativePath(project.artifact)) return error.InvalidArtifactPath;
    if (!endsWithIgnoreCase(project.artifact, extensionFor(project.module_kind))) return error.InvalidArtifactPath;
    if (project.target_path.len == 0) return error.MissingTargetPath;
    if (!isR4OSTargetPath(project.target_path)) return error.InvalidTargetPath;
    if (project.module_kind == .r4x and !project.hasR4XStart()) return error.MissingR4XStart;
    try validateProfile(project);
}

fn validateProfile(project: Project) ParseError!void {
    if (project.profileClass() == null) return error.UnsupportedBuildProfile;
    if (equalsIgnoreCase(project.build_profile, "R4X_C_Console")) {
        if (project.module_kind != .r4x or project.language != .c or !equalsIgnoreCase(project.app_class, "console")) return error.IncompatibleBuildProfile;
        return;
    }
    if (equalsIgnoreCase(project.build_profile, "R4X_C_Desktop_OK")) {
        if (project.module_kind != .r4x or project.language != .c or !(equalsIgnoreCase(project.app_class, "gui") or equalsIgnoreCase(project.app_class, "desktop"))) return error.IncompatibleBuildProfile;
        if (!hasImport(project, "R4DESK") or !hasImport(project, "R4DRAW")) return error.IncompatibleBuildProfile;
        return;
    }
    if (equalsIgnoreCase(project.build_profile, "R4X_C")) {
        if (project.module_kind != .r4x or project.language != .c) return error.IncompatibleBuildProfile;
        return;
    }
    if (equalsIgnoreCase(project.build_profile, "R4X_Zig")) {
        if (project.module_kind != .r4x or project.language != .zig) return error.IncompatibleBuildProfile;
        return;
    }
}

fn parseEntry(line: []const u8) ParseError!Item {
    const split = indexOfScalar(line, '=') orelse return error.InvalidLine;
    const key = trim(line[0..split]);
    const value = trim(line[split + 1 ..]);
    if (!validKey(key)) return error.InvalidKey;
    return .{ .key = key, .value = value };
}

fn parseSection(line: []const u8) ParseError!Section {
    if (line.len < 3 or line[line.len - 1] != ']') return error.InvalidSectionHeader;
    const name = trim(line[1 .. line.len - 1]);
    if (equalsIgnoreCase(name, "Project")) return .project;
    if (equalsIgnoreCase(name, "Sources")) return .sources;
    if (equalsIgnoreCase(name, "Imports")) return .imports;
    if (equalsIgnoreCase(name, "Exports")) return .exports;
    if (equalsIgnoreCase(name, "Metadata")) return .metadata;
    if (equalsIgnoreCase(name, "Contracts")) return .contracts;
    if (equalsIgnoreCase(name, "Output")) return .output;
    if (equalsIgnoreCase(name, "Test")) return .test_section;
    return .unknown;
}

fn parseModuleKind(value: []const u8) ?ModuleKind {
    if (equalsIgnoreCase(value, "R4X")) return .r4x;
    if (equalsIgnoreCase(value, "R4D")) return .r4d;
    if (equalsIgnoreCase(value, "R4P")) return .r4p;
    if (equalsIgnoreCase(value, "R4L")) return .r4l;
    return null;
}

fn parseLanguage(value: []const u8) ?Language {
    if (equalsIgnoreCase(value, "Zig")) return .zig;
    if (equalsIgnoreCase(value, "C")) return .c;
    return null;
}

fn hasImport(project: Project, group: []const u8) bool {
    for (project.imports()) |item| {
        const current = importGroup(item.value) orelse continue;
        if (equalsIgnoreCase(current, group)) return true;
    }
    return false;
}

fn knownPlatformGroup(group: []const u8) bool {
    return equalsIgnoreCase(group, "R4SYS") or
        equalsIgnoreCase(group, "R4DESK") or
        equalsIgnoreCase(group, "R4DRAW") or
        equalsIgnoreCase(group, "R4NET") or
        equalsIgnoreCase(group, "R4AUDIO") or
        equalsIgnoreCase(group, "R4DEV");
}

fn importGroup(value: []const u8) ?[]const u8 {
    const split = indexOfScalar(value, ':') orelse return null;
    if (split == 0) return null;
    return trim(value[0..split]);
}

fn extensionFor(kind: ModuleKind) []const u8 {
    return switch (kind) {
        .r4x => ".R4X",
        .r4d => ".R4D",
        .r4p => ".R4P",
        .r4l => ".R4L",
    };
}

fn isProjectRelativePath(path: []const u8) bool {
    const text = trim(path);
    if (text.len == 0) return false;
    if (isAbsolutePath(text)) return false;
    if (containsHostTruth(text)) return false;
    if (hasParentTraversal(text)) return false;
    return true;
}

fn isR4OSTargetPath(path: []const u8) bool {
    const text = trim(path);
    if (text.len == 0) return false;
    if (containsHostTruth(text)) return false;
    if (startsWithIgnoreCase(text, "/R4OS/")) return true;
    if (startsWithIgnoreCase(text, "/SOFTWARE/")) return true;
    if (startsWithIgnoreCase(text, "C:\\R4OS\\")) return true;
    if (startsWithIgnoreCase(text, "C:/R4OS/")) return true;
    if (startsWithIgnoreCase(text, "C:\\SOFTWARE\\")) return true;
    if (startsWithIgnoreCase(text, "C:/SOFTWARE/")) return true;
    return false;
}

fn containsHostTruth(value: []const u8) bool {
    return indexOfIgnoreCase(value, "R4CodePad") != null or
        indexOfIgnoreCase(value, "R4CodePad.ini") != null or
        indexOfIgnoreCase(value, "Build.bat") != null or
        indexOfIgnoreCase(value, "DevTools") != null or
        indexOfIgnoreCase(value, "R4XBuilder") != null or
        indexOfIgnoreCase(value, "QEMU") != null;
}

fn hasParentTraversal(path: []const u8) bool {
    var start: usize = 0;
    var i: usize = 0;
    while (i <= path.len) : (i += 1) {
        if (i == path.len or path[i] == '/' or path[i] == '\\') {
            if (i - start == 2 and path[start] == '.' and path[start + 1] == '.') return true;
            start = i + 1;
        }
    }
    return false;
}

fn isAbsolutePath(path: []const u8) bool {
    if (path.len >= 2 and path[1] == ':') return true;
    return path[0] == '/' or path[0] == '\\';
}

fn validKey(key: []const u8) bool {
    if (key.len == 0) return false;
    for (key) |ch| {
        if ((ch >= 'A' and ch <= 'Z') or
            (ch >= 'a' and ch <= 'z') or
            (ch >= '0' and ch <= '9') or
            ch == '_' or ch == '-' or ch == '.')
        {
            continue;
        }
        return false;
    }
    return true;
}

fn nextLine(rest: *[]const u8) ?[]const u8 {
    if (rest.len == 0) return null;
    const split = indexOfScalar(rest.*, '\n') orelse rest.len;
    var line = rest.*[0..split];
    if (split < rest.len) {
        rest.* = rest.*[split + 1 ..];
    } else {
        rest.* = rest.*[split..];
    }
    if (line.len > 0 and line[line.len - 1] == '\r') line = line[0 .. line.len - 1];
    return line;
}

pub fn trim(value: []const u8) []const u8 {
    var start: usize = 0;
    var end = value.len;
    while (start < end and isSpace(value[start])) : (start += 1) {}
    while (end > start and isSpace(value[end - 1])) : (end -= 1) {}
    return value[start..end];
}

fn stripUtf8Bom(bytes: []const u8) []const u8 {
    if (bytes.len >= 3 and bytes[0] == 0xEF and bytes[1] == 0xBB and bytes[2] == 0xBF) return bytes[3..];
    return bytes;
}

fn indexOfScalar(value: []const u8, needle: u8) ?usize {
    var i: usize = 0;
    while (i < value.len) : (i += 1) {
        if (value[i] == needle) return i;
    }
    return null;
}

fn indexOfIgnoreCase(value: []const u8, needle: []const u8) ?usize {
    if (needle.len == 0) return 0;
    if (needle.len > value.len) return null;
    var i: usize = 0;
    while (i + needle.len <= value.len) : (i += 1) {
        if (equalsIgnoreCase(value[i .. i + needle.len], needle)) return i;
    }
    return null;
}

fn equalsIgnoreCase(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    var i: usize = 0;
    while (i < a.len) : (i += 1) {
        if (asciiLower(a[i]) != asciiLower(b[i])) return false;
    }
    return true;
}

fn startsWithIgnoreCase(value: []const u8, prefix: []const u8) bool {
    if (prefix.len > value.len) return false;
    return equalsIgnoreCase(value[0..prefix.len], prefix);
}

fn endsWithIgnoreCase(value: []const u8, suffix: []const u8) bool {
    if (suffix.len > value.len) return false;
    return equalsIgnoreCase(value[value.len - suffix.len ..], suffix);
}

fn asciiLower(ch: u8) u8 {
    if (ch >= 'A' and ch <= 'Z') return ch + ('a' - 'A');
    return ch;
}

fn isSpace(ch: u8) bool {
    return ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n';
}

test "r4cp parser reads current C project format" {
    const project = try parse(
        \\[Project]
        \\Name=HELLOC
        \\ModuleKind=R4X
        \\Language=C
        \\BuildProfile=R4X_C
        \\AppClass=console
        \\
        \\[Sources]
        \\Main=src/main.c
        \\
        \\[Imports]
        \\R4SYS=R4SYS:Query:1
        \\
        \\[Exports]
        \\Entry=R4XStart:.text:0:1
        \\
        \\[Metadata]
        \\r4x.start=r4xstart
        \\r4x.entry=R4XStart
        \\
        \\[Output]
        \\Artifact=out/HELLOC.R4X
        \\TargetPath=/R4OS/SOFTWARE/TERMINAL/HELLOC.R4X
    );
    try std.testing.expectEqualStrings("HELLOC", project.name);
    try std.testing.expectEqual(ModuleKind.r4x, project.module_kind);
    try std.testing.expectEqual(Language.c, project.language);
    try std.testing.expectEqual(@as(usize, 1), project.source_count);
    try std.testing.expectEqualStrings("src/main.c", project.sources()[0].value);
    try std.testing.expect(project.hasR4XStart());
    try std.testing.expectEqual(ProfileClass.external_compatible, project.profileClass().?);
}

test "r4cp parser reads current Zig project format" {
    const project = try parse(
        \\[Project]
        \\Name=HELLO
        \\ModuleKind=R4X
        \\Language=Zig
        \\BuildProfile=R4X_Zig
        \\AppClass=console
        \\
        \\[Sources]
        \\Main=src/main.zig
        \\
        \\[Imports]
        \\R4SYS=R4SYS:Query:1
        \\
        \\[Exports]
        \\Entry=R4XStart:.text:0:1
        \\
        \\[Metadata]
        \\r4x.start=r4xstart
        \\r4x.entry=R4XStart
        \\
        \\[Output]
        \\Artifact=out/HELLO.R4X
        \\TargetPath=/R4OS/SOFTWARE/TERMINAL/HELLO.R4X
    );
    try std.testing.expectEqualStrings("HELLO", project.name);
    try std.testing.expectEqual(Language.zig, project.language);
    try std.testing.expectEqualStrings("R4X_Zig", project.build_profile);
    try std.testing.expectEqual(ProfileClass.external_compatible, project.profileClass().?);
}

test "r4cp parser accepts internal console and desktop build profiles" {
    const console_project = try parse(
        \\[Project]
        \\Name=HELLOC
        \\ModuleKind=R4X
        \\Language=C
        \\BuildProfile=R4X_C_Console
        \\AppClass=console
        \\[Sources]
        \\Main=src/main.c
        \\[Imports]
        \\R4SYS=R4SYS:Query:1
        \\[Exports]
        \\Entry=R4XStart:.text:0:1
        \\[Output]
        \\Artifact=out/HELLOC.R4X
        \\TargetPath=/R4OS/SOFTWARE/TERMINAL/HELLOC.R4X
    );
    try std.testing.expectEqual(ProfileClass.internal, console_project.profileClass().?);

    const desktop_project = try parse(
        \\[Project]
        \\Name=HELLOGUI
        \\ModuleKind=R4X
        \\Language=C
        \\BuildProfile=R4X_C_Desktop_OK
        \\AppClass=gui
        \\[Sources]
        \\Main=src/main.c
        \\[Imports]
        \\R4SYS=R4SYS:Query:1
        \\R4DESK=R4DESK:Query:1
        \\R4DRAW=R4DRAW:Query:1
        \\[Exports]
        \\Entry=R4XStart:.text:0:1
        \\[Output]
        \\Artifact=out/HELLOGUI.R4X
        \\TargetPath=/SOFTWARE/HELLOGUI/HELLOGUI.R4X
    );
    try std.testing.expectEqual(ProfileClass.internal, desktop_project.profileClass().?);
}

test "r4cp parser rejects host paths and absolute project paths" {
    try std.testing.expectError(error.HostPathRejected, parse(
        \\[Project]
        \\Name=BAD
        \\ModuleKind=R4X
        \\Language=C
        \\BuildProfile=R4X_C_Console
        \\AppClass=console
        \\[Sources]
        \\Main=DevTools/R4XBuilder/src/main.zig
        \\[Imports]
        \\R4SYS=R4SYS:Query:1
        \\[Exports]
        \\Entry=R4XStart:.text:0:1
        \\[Output]
        \\Artifact=out/BAD.R4X
        \\TargetPath=/R4OS/SOFTWARE/TERMINAL/BAD.R4X
    ));
    try std.testing.expectError(error.InvalidSourcePath, parse(
        \\[Project]
        \\Name=BAD
        \\ModuleKind=R4X
        \\Language=C
        \\BuildProfile=R4X_C_Console
        \\AppClass=console
        \\[Sources]
        \\Main=C:\TEMP\main.c
        \\[Imports]
        \\R4SYS=R4SYS:Query:1
        \\[Exports]
        \\Entry=R4XStart:.text:0:1
        \\[Output]
        \\Artifact=out/BAD.R4X
        \\TargetPath=/R4OS/SOFTWARE/TERMINAL/BAD.R4X
    ));
}

test "r4cp parser reports missing required fields" {
    try std.testing.expectError(error.MissingSource, parse(
        \\[Project]
        \\Name=NOSRC
        \\ModuleKind=R4X
        \\Language=C
        \\BuildProfile=R4X_C_Console
        \\AppClass=console
        \\[Imports]
        \\R4SYS=R4SYS:Query:1
        \\[Exports]
        \\Entry=R4XStart:.text:0:1
        \\[Output]
        \\Artifact=out/NOSRC.R4X
        \\TargetPath=/R4OS/SOFTWARE/TERMINAL/NOSRC.R4X
    ));
}

test "r4cp template renderer replaces project tokens" {
    var out: [96]u8 = undefined;
    const result = renderTemplate(
        "Name={ProjectName}\nArtifact={Artifact}\n",
        &.{
            .{ .name = "ProjectName", .value = "HELLOC" },
            .{ .name = "Artifact", .value = "out/HELLOC.R4X" },
        },
        out[0..],
    );
    try std.testing.expect(result.ok);
    try std.testing.expectEqualStrings("Name=HELLOC\nArtifact=out/HELLOC.R4X\n", result.bytes);
}
