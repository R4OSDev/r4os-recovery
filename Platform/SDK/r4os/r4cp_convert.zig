const std = @import("std");
pub const legacy = @import("r4cp.zig");
pub const r4mf = @import("module_manifest.zig");

pub const ConvertError = enum {
    unsupported_module_kind,
    unsupported_profile,
    invalid_app_class,
    output_too_small,
};

pub const Result = struct {
    bytes: []const u8,
    err: ?ConvertError,

    pub fn ok(self: Result) bool {
        return self.err == null;
    }
};

/// Converts the historical project description once into the current R4MF-v2
/// contract. The caller owns persistence and must never replace the source.
pub fn render(project: legacy.Project, out: []u8) Result {
    if (project.module_kind != .r4x) return failed(out, .unsupported_module_kind);
    const entry_mode: []const u8 = if (equalsIgnoreCase(project.build_profile, "R4X_C_Console") or
        equalsIgnoreCase(project.build_profile, "R4X_C_Desktop_OK"))
        "app"
    else if (equalsIgnoreCase(project.build_profile, "R4X_C") or equalsIgnoreCase(project.build_profile, "R4X_Zig"))
        "lowlevel"
    else
        return failed(out, .unsupported_profile);
    const app_class = if (equalsIgnoreCase(project.app_class, "console"))
        "console"
    else if (equalsIgnoreCase(project.app_class, "gui"))
        "gui"
    else if (equalsIgnoreCase(project.app_class, "service"))
        "service"
    else
        return failed(out, .invalid_app_class);

    var len: usize = 0;
    if (!line(out, &len, "R4OS_MODULE_MANIFEST", "2") or
        !line(out, &len, "KIND", "R4X") or
        !line(out, &len, "NAME", project.name) or
        // R4CP kannte keine Modulversion. Ein konvertiertes Projekt beginnt
        // deshalb bei 0.1.0; alles andere waere eine erfundene Historie.
        !line(out, &len, "VERSION", "0.1.0") or
        !line(out, &len, "LANGUAGE", languageText(project.language)))
    {
        return failed(out, .output_too_small);
    }
    for (project.sources()) |source| if (!line(out, &len, "SOURCE", source.value)) return failed(out, .output_too_small);
    if (!line(out, &len, "ENTRY_MODE", entry_mode) or
        !line(out, &len, "APP_CLASS", app_class) or
        !line(out, &len, "TARGET", project.target_path) or
        !line(out, &len, "IMAGE_SCOPE", "none"))
    {
        return failed(out, .output_too_small);
    }
    for (project.imports()) |item| if (!line(out, &len, "IMPORT", item.value)) return failed(out, .output_too_small);
    for (project.metadata()) |item| {
        if (isDerivedMetadata(item.key)) continue;
        if (!metaLine(out, &len, item.key, item.value)) return failed(out, .output_too_small);
    }
    return .{ .bytes = out[0..len], .err = null };
}

pub fn errorMessage(err: ConvertError) []const u8 {
    return switch (err) {
        .unsupported_module_kind => "Only historical R4X projects can be converted.",
        .unsupported_profile => "Historical BuildProfile cannot be mapped to R4MF v2.",
        .invalid_app_class => "Historical AppClass cannot be mapped to R4MF v2.",
        .output_too_small => "Converted R4MF v2 exceeds the caller buffer.",
    };
}

fn failed(out: []u8, err: ConvertError) Result {
    return .{ .bytes = out[0..0], .err = err };
}

fn languageText(value: legacy.Language) []const u8 {
    return switch (value) {
        .zig => "Zig",
        .c => "C",
    };
}

fn isDerivedMetadata(key: []const u8) bool {
    return equalsIgnoreCase(key, "app.class") or
        startsWithIgnoreCase(key, "r4x.") or
        startsWithIgnoreCase(key, "image.");
}

fn line(out: []u8, len: *usize, key: []const u8, value: []const u8) bool {
    return bytes(out, len, key) and bytes(out, len, "=") and bytes(out, len, value) and bytes(out, len, "\n");
}

fn metaLine(out: []u8, len: *usize, key: []const u8, value: []const u8) bool {
    return bytes(out, len, "META=") and bytes(out, len, key) and bytes(out, len, "=") and bytes(out, len, value) and bytes(out, len, "\n");
}

fn bytes(out: []u8, len: *usize, value: []const u8) bool {
    if (len.* + value.len > out.len) return false;
    @memcpy(out[len.* .. len.* + value.len], value);
    len.* += value.len;
    return true;
}

fn startsWithIgnoreCase(value: []const u8, prefix: []const u8) bool {
    return value.len >= prefix.len and equalsIgnoreCase(value[0..prefix.len], prefix);
}

fn equalsIgnoreCase(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |left, right| if (asciiLower(left) != asciiLower(right)) return false;
    return true;
}

fn asciiLower(ch: u8) u8 {
    return if (ch >= 'A' and ch <= 'Z') ch + ('a' - 'A') else ch;
}

test "legacy C console converts deterministically to current R4MF v2" {
    const source =
        \\[Project]
        \\Name=HELLOC
        \\ModuleKind=R4X
        \\Language=C
        \\BuildProfile=R4X_C_Console
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
        \\owner=developer
        \\
        \\[Output]
        \\Artifact=out/HELLOC.R4X
        \\TargetPath=/R4OS/SOFTWARE/TERMINAL/HELLOC.R4X
    ;
    const project = try legacy.parse(source);
    var first: [2048]u8 = undefined;
    var second: [2048]u8 = undefined;
    const a = render(project, first[0..]);
    const b = render(project, second[0..]);
    try std.testing.expect(a.ok() and b.ok());
    try std.testing.expectEqualStrings(a.bytes, b.bytes);
    try std.testing.expect(std.mem.indexOf(u8, a.bytes, "SOURCE=src/main.c\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, a.bytes, "IMPORT=R4SYS:Query:1\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, a.bytes, "TARGET=/R4OS/SOFTWARE/TERMINAL/HELLOC.R4X\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, a.bytes, "META=owner=developer\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, a.bytes, "Artifact") == null);

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const current = try r4mf.parse(arena.allocator(), "module.R4MF", a.bytes);
    try std.testing.expectEqualStrings("HELLOC", current.name);
    try std.testing.expectEqual(r4mf.EntryMode.app, current.entry_mode.?);
    // R4CP kannte keine Modulversion: konvertierte Projekte beginnen bei 0.1.0.
    try std.testing.expectEqualStrings("0.1.0", current.module_version.text);
}
