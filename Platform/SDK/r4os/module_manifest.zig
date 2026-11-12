const std = @import("std");
const abi = @import("r4os_contract").abi;

pub const capabilities = @import("module_capabilities.zig");
pub const rust_project = @import("rust_project.zig");
pub const import_spec = @import("import_spec.zig");
pub const startup_metadata = @import("startup_metadata.zig");
const appearance_metadata = @import("appearance_metadata.zig");

test {
    std.testing.refAllDecls(startup_metadata);
}

pub const manifest_version: u8 = 2;
pub const max_manifest_bytes: usize = 128 * 1024;
pub const plan_contract_version: u8 = 1;

pub fn platformApiGroupId(name: []const u8) ?u32 {
    return import_spec.platformGroupId(name);
}

pub const Kind = enum {
    r4x,
    r4d,
    r4p,
    r4l,

    pub fn text(self: Kind) []const u8 {
        return switch (self) {
            .r4x => "R4X",
            .r4d => "R4D",
            .r4p => "R4P",
            .r4l => "R4L",
        };
    }
};

pub const Language = enum {
    zig,
    c,
    rust,

    pub fn text(self: Language) []const u8 {
        return switch (self) {
            .zig => "Zig",
            .c => "C",
            .rust => "Rust",
        };
    }
};

pub const AppClass = enum {
    console,
    gui,
    service,

    pub fn text(self: AppClass) []const u8 {
        return @tagName(self);
    }
};

pub const EntryMode = enum {
    app,
    lowlevel,

    pub fn text(self: EntryMode) []const u8 {
        return @tagName(self);
    }
};

pub const ImageScope = enum {
    slim,
    full,
    @"test",
    none,

    pub fn text(self: ImageScope) []const u8 {
        return @tagName(self);
    }
};

pub const Optimization = enum {
    size,
    speed,

    pub fn text(self: Optimization) []const u8 {
        return @tagName(self);
    }
};

/// Orthogonale Aufgabe eines Moduls. Die Rolle aendert weder R4M0-Kind noch
/// Loaderpfad; ein Subsystem bleibt ein gewoehnliches GUI-R4X.
pub const ModuleRole = enum {
    subsystem,

    pub fn text(self: ModuleRole) []const u8 {
        return @tagName(self);
    }
};

/// Zuordnung einer typischen Dateiendung zu einer deklarierten Gastformat-ID.
/// Die Endung ist nur ein Vorauswahlhinweis und keine alleinige Erkennung.
pub const GuestExtensionEntry = struct {
    format_id: []const u8,
    extension: []const u8,
};

/// Optionales, spaeter erweiterbares Erkennungsmerkmal eines Gastformats.
pub const GuestFeatureEntry = struct {
    format_id: []const u8,
    feature: []const u8,
};

pub const subsystem_id_max_bytes: usize = 63;
pub const subsystem_display_name_max_bytes: usize = 96;
pub const guest_format_id_max_bytes: usize = 63;
pub const guest_feature_max_bytes: usize = 63;
pub const guest_extension_max_bytes: usize = 16;
pub const max_guest_formats: usize = 16;
pub const max_guest_extensions: usize = 32;
pub const max_guest_features: usize = 32;

/// Version des MODULS, nicht des Manifestformats. Beide stehen in derselben
/// Datei und werden leicht verwechselt: `Manifest.version` ist die Formatzahl
/// (aktuell 2), `Manifest.module_version` die Version der Software selbst.
pub const ModuleVersion = struct {
    major: u16,
    minor: u16,
    patch: u16,
    /// Kanonische Schreibweise aus dem Manifest. Wird unveraendert in den
    /// Containermetadatenblock und ins Inventar uebernommen.
    text: []const u8,
};

/// Eine RESOURCE=NAME:pfad-Zeile, am ERSTEN Doppelpunkt getrennt - der Name
/// darf keinen enthalten, ein Windows-Pfad rechts davon schon.
pub const ResourceEntry = struct {
    name: []const u8,
    path: []const u8,
};

/// Ein libraryeigener R4L-Export. Der Manifestwert lautet
/// PUBLIC_NAME:elf_symbol:revision. Section und Offset werden absichtlich
/// nicht im Manifest festgeschrieben, sondern beim Verpacken aus der ELF-
/// Symboltabelle ermittelt.
pub const ExportEntry = struct {
    name: []const u8,
    symbol: []const u8,
    revision: u16,
};

/// Ein C-Praeprozessorwert aus C_DEFINE=NAME=WERT. Die Trennung erfolgt am
/// ersten Gleichheitszeichen, damit Werte wie Header-Tokens oder weitere
/// Gleichheitszeichen unveraendert beim Compiler ankommen.
pub const CDefineEntry = struct {
    name: []const u8,
    value: []const u8,
};

/// Hoechstzahl der Ressourceneintraege je Modul (Icons + Help + Dateien),
/// aus dem R4M0-Vertrag.
pub const max_resource_entries: usize = 64;

pub const Manifest = struct {
    version: u8,
    path: []const u8,
    kind: Kind,
    name: []const u8,
    module_version: ModuleVersion,
    language: ?Language = null,
    /// Filled by file-aware consumers after shared Cargo validation.
    sources: []const []const u8 = &.{},
    entry_mode: ?EntryMode = null,
    app_class: ?AppClass = null,
    module_role: ?ModuleRole = null,
    subsystem_id: ?[]const u8 = null,
    subsystem_display_name: ?[]const u8 = null,
    guest_formats: []const []const u8 = &.{},
    guest_extensions: []const GuestExtensionEntry = &.{},
    guest_features: []const GuestFeatureEntry = &.{},
    target: []const u8,
    image_scope: ?ImageScope = null,
    optimization: ?Optimization = null,
    package: ?[]const u8 = null,
    zig_modules: []const []const u8 = &.{},
    /// Logical native archive names, resolved to tracked LazyPaths by the
    /// owning library build. No host linker or system library search paths.
    native_archives: []const []const u8 = &.{},
    c_includes: []const []const u8 = &.{},
    c_defines: []const CDefineEntry = &.{},
    c_flags: []const []const u8 = &.{},
    imports: []const []const u8 = &.{},
    exports: []const ExportEntry = &.{},
    contract: ?[]const u8 = null,
    contract_baseline: ?[]const u8 = null,
    implementation_zig: ?[]const u8 = null,
    binding_zig: ?[]const u8 = null,
    binding_c: ?[]const u8 = null,
    binding_rust: ?[]const u8 = null,
    conformance_zig: ?[]const u8 = null,
    conformance_c: ?[]const u8 = null,
    api_reference: ?[]const u8 = null,
    metadata: []const []const u8 = &.{},
    /// ICON=-Pfade in Manifestreihenfolge; der erste ist Icon-Index 0 und
    /// damit das Desktopicon.
    icons: []const []const u8 = &.{},
    /// HELP=-Pfad, hoechstens einer.
    help: ?[]const u8 = null,
    /// RESOURCE=-Eintraege in Manifestreihenfolge.
    resources: []const ResourceEntry = &.{},
    /// Optional build-owned platform selection; existing field offsets stay fixed.
    sdk_profile: ?[]const u8 = null,
    platform_generation: u8 = 1,
};

pub const Plan = struct {
    source_project: []const u8,
    artifact: []const u8,
    build_profile: []const u8,
    app_profile: []const u8,
    app_class: []const u8,
    optimization: []const u8,
    export_contract: []const u8 = "R4XStart:R4XStart:1",
    module_contract: []const u8 = "R4M0:1",
    r4x_start_abi: []const u8 = "R4XStart:1",
    imports: []const []const u8,
    metadata: []const []const u8,
};

pub const RenderResult = struct {
    bytes: []const u8,
    ok: bool,
};

pub fn parse(allocator: std.mem.Allocator, path: []const u8, text: []const u8) !Manifest {
    if (text.len >= 3 and text[0] == 0xEF and text[1] == 0xBB and text[2] == 0xBF) return error.ManifestBomForbidden;
    const version = try scanVersion(text);
    if (version != manifest_version) return error.UnsupportedManifestVersion;
    return parseV2(allocator, path, text);
}

fn scanVersion(text: []const u8) !u8 {
    var found: ?u8 = null;
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, raw, " \t\r");
        if (line.len == 0 or line[0] == '#') continue;
        const field = try splitField(line);
        if (!std.mem.eql(u8, field.key, "R4OS_MODULE_MANIFEST")) continue;
        if (found != null) return error.DuplicateField;
        found = std.fmt.parseUnsigned(u8, field.value, 10) catch return error.BadManifestVersion;
    }
    return found orelse error.MissingManifestVersion;
}

const Field = struct { key: []const u8, value: []const u8 };

fn splitField(line: []const u8) !Field {
    const eq = std.mem.indexOfScalar(u8, line, '=') orelse return error.ManifestLineWithoutEquals;
    const key = std.mem.trim(u8, line[0..eq], " \t");
    const value = std.mem.trim(u8, line[eq + 1 ..], " \t\r");
    if (key.len == 0) return error.EmptyManifestKey;
    if (value.len == 0) return error.EmptyManifestValue;
    return .{ .key = key, .value = value };
}

fn parseV2(allocator: std.mem.Allocator, path: []const u8, text: []const u8) !Manifest {
    var version: ?[]const u8 = null;
    var kind: ?[]const u8 = null;
    var name: ?[]const u8 = null;
    var module_version: ?[]const u8 = null;
    var language: ?[]const u8 = null;
    var sdk_profile: ?[]const u8 = null;
    var entry_mode: ?[]const u8 = null;
    var app_class: ?[]const u8 = null;
    var module_role: ?[]const u8 = null;
    var subsystem_id: ?[]const u8 = null;
    var subsystem_display_name: ?[]const u8 = null;
    var guest_formats: std.ArrayList([]const u8) = .empty;
    var guest_extensions: std.ArrayList(GuestExtensionEntry) = .empty;
    var guest_features: std.ArrayList(GuestFeatureEntry) = .empty;
    var target: ?[]const u8 = null;
    var image_scope: ?[]const u8 = null;
    var optimization: ?[]const u8 = null;
    var package: ?[]const u8 = null;
    var sources: std.ArrayList([]const u8) = .empty;
    var zig_modules: std.ArrayList([]const u8) = .empty;
    var native_archives: std.ArrayList([]const u8) = .empty;
    var c_includes: std.ArrayList([]const u8) = .empty;
    var c_defines: std.ArrayList(CDefineEntry) = .empty;
    var c_flags: std.ArrayList([]const u8) = .empty;
    var imports: std.ArrayList([]const u8) = .empty;
    var exports: std.ArrayList(ExportEntry) = .empty;
    var contract: ?[]const u8 = null;
    var contract_baseline: ?[]const u8 = null;
    var implementation_zig: ?[]const u8 = null;
    var binding_zig: ?[]const u8 = null;
    var binding_c: ?[]const u8 = null;
    var binding_rust: ?[]const u8 = null;
    var conformance_zig: ?[]const u8 = null;
    var conformance_c: ?[]const u8 = null;
    var api_reference: ?[]const u8 = null;
    var metadata: std.ArrayList([]const u8) = .empty;
    var icons: std.ArrayList([]const u8) = .empty;
    var help: ?[]const u8 = null;
    var resources: std.ArrayList(ResourceEntry) = .empty;

    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, raw, " \t\r");
        if (line.len == 0 or line[0] == '#') continue;
        const field = try splitField(line);
        if (std.mem.eql(u8, field.key, "R4OS_MODULE_MANIFEST")) {
            try setSingle(&version, field.value);
        } else if (std.mem.eql(u8, field.key, "KIND")) {
            try setSingle(&kind, field.value);
        } else if (std.mem.eql(u8, field.key, "NAME")) {
            try setSingle(&name, field.value);
        } else if (std.mem.eql(u8, field.key, "VERSION")) {
            try setSingle(&module_version, field.value);
        } else if (std.mem.eql(u8, field.key, "LANGUAGE")) {
            try setSingle(&language, field.value);
        } else if (std.mem.eql(u8, field.key, "SDK_PROFILE")) {
            try setSingle(&sdk_profile, field.value);
        } else if (std.mem.eql(u8, field.key, "SOURCE")) {
            try sources.append(allocator, field.value);
        } else if (std.mem.eql(u8, field.key, "ENTRY_MODE")) {
            try setSingle(&entry_mode, field.value);
        } else if (std.mem.eql(u8, field.key, "APP_CLASS")) {
            try setSingle(&app_class, field.value);
        } else if (std.mem.eql(u8, field.key, "MODULE_ROLE")) {
            try setSingle(&module_role, field.value);
        } else if (std.mem.eql(u8, field.key, "SUBSYSTEM_ID")) {
            try setSingle(&subsystem_id, field.value);
        } else if (std.mem.eql(u8, field.key, "SUBSYSTEM_DISPLAY_NAME")) {
            try setSingle(&subsystem_display_name, field.value);
        } else if (std.mem.eql(u8, field.key, "GUEST_FORMAT")) {
            try guest_formats.append(allocator, field.value);
        } else if (std.mem.eql(u8, field.key, "GUEST_EXTENSION")) {
            try guest_extensions.append(allocator, try parseGuestExtensionEntry(field.value));
        } else if (std.mem.eql(u8, field.key, "GUEST_FEATURE")) {
            try guest_features.append(allocator, try parseGuestFeatureEntry(field.value));
        } else if (std.mem.eql(u8, field.key, "TARGET")) {
            try setSingle(&target, field.value);
        } else if (std.mem.eql(u8, field.key, "IMAGE_SCOPE")) {
            try setSingle(&image_scope, field.value);
        } else if (std.mem.eql(u8, field.key, "OPTIMIZE")) {
            try setSingle(&optimization, field.value);
        } else if (std.mem.eql(u8, field.key, "PACKAGE")) {
            try setSingle(&package, field.value);
        } else if (std.mem.eql(u8, field.key, "ZIG_MODULE")) {
            try zig_modules.append(allocator, field.value);
        } else if (std.mem.eql(u8, field.key, "NATIVE_ARCHIVE")) {
            try native_archives.append(allocator, field.value);
        } else if (std.mem.eql(u8, field.key, "C_INCLUDE")) {
            try c_includes.append(allocator, field.value);
        } else if (std.mem.eql(u8, field.key, "C_DEFINE")) {
            try c_defines.append(allocator, try parseCDefineEntry(field.value));
        } else if (std.mem.eql(u8, field.key, "C_FLAG")) {
            try c_flags.append(allocator, field.value);
        } else if (std.mem.eql(u8, field.key, "IMPORT")) {
            try imports.append(allocator, field.value);
        } else if (std.mem.eql(u8, field.key, "EXPORT")) {
            try exports.append(allocator, try parseExportEntry(field.value));
        } else if (std.mem.eql(u8, field.key, "CONTRACT")) {
            try setSingle(&contract, field.value);
        } else if (std.mem.eql(u8, field.key, "CONTRACT_BASELINE")) {
            try setSingle(&contract_baseline, field.value);
        } else if (std.mem.eql(u8, field.key, "IMPLEMENTATION_ZIG")) {
            try setSingle(&implementation_zig, field.value);
        } else if (std.mem.eql(u8, field.key, "BINDING_ZIG")) {
            try setSingle(&binding_zig, field.value);
        } else if (std.mem.eql(u8, field.key, "BINDING_C")) {
            try setSingle(&binding_c, field.value);
        } else if (std.mem.eql(u8, field.key, "BINDING_RUST")) {
            try setSingle(&binding_rust, field.value);
        } else if (std.mem.eql(u8, field.key, "CONFORMANCE_ZIG")) {
            try setSingle(&conformance_zig, field.value);
        } else if (std.mem.eql(u8, field.key, "CONFORMANCE_C")) {
            try setSingle(&conformance_c, field.value);
        } else if (std.mem.eql(u8, field.key, "API_REFERENCE")) {
            try setSingle(&api_reference, field.value);
        } else if (std.mem.eql(u8, field.key, "META")) {
            try metadata.append(allocator, field.value);
        } else if (std.mem.eql(u8, field.key, "ICON")) {
            try icons.append(allocator, field.value);
        } else if (std.mem.eql(u8, field.key, "HELP")) {
            try setSingle(&help, field.value);
        } else if (std.mem.eql(u8, field.key, "RESOURCE")) {
            try resources.append(allocator, try parseResourceEntry(field.value));
        } else {
            return error.UnknownV2Field;
        }
    }

    if (!std.mem.eql(u8, version orelse return error.MissingManifestVersion, "2")) return error.BadManifestVersion;
    const parsed_kind = try parseKind(kind orelse return error.MissingKind);
    const parsed_name = name orelse return error.MissingName;
    try validateName(parsed_name);
    if (parsed_kind == .r4l and platformApiGroupId(parsed_name) != null) return error.ReservedPlatformApiName;
    const parsed_module_version = try parseModuleVersion(module_version orelse return error.MissingModuleVersion);
    const parsed_language = try parseLanguage(language orelse return error.MissingLanguage);
    const generation = try platformGeneration(allocator, parsed_kind, parsed_language, sdk_profile);
    if (generation == 2 and parsed_kind != .r4d and parsed_kind != .r4p and parsed_kind != .r4x) return error.Generation2RequiresExecutableModule;
    if (parsed_language == .rust) {
        const admission = capabilities.rust(parsed_kind.text(), entry_mode orelse "", module_role, .host);
        if (admission.failure) |err| return err;
        if (zig_modules.items.len != 0 or native_archives.items.len != 0) return error.RustForbidsForeignBuildFields;
    }
    if (sources.items.len == 0) return error.MissingSource;
    // One Zig root, followed by optional C companions in R4L/R4D. They are
    // linked into the same owning artifact; no extra runtime module or source
    // injection into a consumer is implied by a companion source.
    const allows_c_companions = parsed_kind == .r4l or parsed_kind == .r4d;
    if (parsed_language == .zig and !allows_c_companions and sources.items.len != 1) return error.ZigRequiresSingleSource;
    for (sources.items, 0..) |source, index| {
        const source_language: Language = if (index != 0 and (parsed_language == .rust or (parsed_language == .zig and allows_c_companions))) .c else parsed_language;
        try validateSource(source, source_language);
    }
    ensureUnique(sources.items, false) catch return error.DuplicateSource;

    const parsed_target = target orelse return error.MissingTarget;
    try validateTarget(parsed_target, parsed_kind);
    if (parsed_language == .c and zig_modules.items.len != 0) return error.CForbidsZigModule;
    try validateZigModules(zig_modules.items);
    if (native_archives.items.len != 0 and ((parsed_kind != .r4l and parsed_kind != .r4d) or parsed_language != .zig)) return error.NativeArchiveRequiresZigLibraryOrDriver;
    for (native_archives.items) |archive| try validateName(archive);
    ensureUnique(native_archives.items, true) catch return error.DuplicateNativeArchive;
    try validateCConfiguration(c_includes.items, c_defines.items, c_flags.items);
    const has_c_source = parsed_language == .c or ((parsed_language == .rust or (allows_c_companions and parsed_language == .zig)) and sources.items.len > 1);
    // R4D/R4L Zig roots can translate data headers with @cImport without a C object
    // or native archive. C_FLAG still requires an actual C compilation unit;
    // include roots and macros also apply to the Zig root's translation.
    const zig_headers = parsed_language == .zig and (parsed_kind == .r4d or parsed_kind == .r4l);
    if (!has_c_source and (c_flags.items.len != 0 or (!zig_headers and (c_includes.items.len != 0 or c_defines.items.len != 0)))) {
        return error.CConfigurationWithoutCSource;
    }
    ensureUnique(imports.items, true) catch return error.DuplicateImport;
    for (imports.items) |entry| try validateImportSyntax(entry);
    try validateExports(exports.items);
    ensureUnique(metadata.items, true) catch return error.DuplicateMetadata;
    try validateMetadata(metadata.items);
    const appearance = try appearance_metadata.parse(metadata.items);
    if (parsed_kind != .r4x and appearance.flags != 0) return error.TitleColorRequiresR4X;

    // Ressourcen (0.61.12): Pfade nur projektintern wie SOURCE, Namen nach
    // dem R4M0-Vertrag. R4L lehnt ab, weil sein Containervertrag keinen
    // Ressourcenpfad besitzt; eine deklarierte, aber nie erreichbare
    // Ressource waere eine stille Luege im Manifest.
    if (parsed_kind == .r4l and (icons.items.len != 0 or help != null or resources.items.len != 0)) {
        return error.R4LResourcesForbidden;
    }
    for (icons.items) |icon_path| try validateResourcePath(icon_path);
    if (help) |help_path| try validateResourcePath(help_path);
    for (resources.items, 0..) |entry, index| {
        try validateResourceName(entry.name);
        try validateResourcePath(entry.path);
        for (resources.items[0..index]) |prior| {
            if (std.ascii.eqlIgnoreCase(entry.name, prior.name)) return error.DuplicateResourceName;
        }
    }
    const resource_total = icons.items.len + @as(usize, if (help != null) 1 else 0) + resources.items.len;
    if (resource_total > max_resource_entries) return error.TooManyResources;

    var parsed_entry_mode: ?EntryMode = null;
    var parsed_class: ?AppClass = null;
    var parsed_optimization: ?Optimization = null;
    var parsed_module_role: ?ModuleRole = null;
    var parsed_subsystem_id: ?[]const u8 = null;

    // IMAGE_SCOPE gilt seit 0.61.6 fuer ALLE vier Modularten und ist ueberall
    // Pflicht. Vorher war es fuer Nicht-R4X sogar verboten, und R4D/R4L
    // deklarierten ihre Platzierung ueber META=image.shipped=, waehrend die
    // R4P gar nichts sagten - ihre Platzierung stand in einer Liste im
    // Buildscript. Ein Mechanismus statt zweier plus einer Liste.
    const parsed_scope = try parseImageScope(image_scope orelse return error.MissingImageScope);
    // Code-generation policy is one common module fact. Omission remains the
    // stable ReleaseSmall default for every current R4M0 kind.
    parsed_optimization = try parseOptimization(optimization orelse "size");

    if (parsed_kind == .r4x) {
        parsed_entry_mode = try parseEntryMode(entry_mode orelse return error.MissingEntryMode);
        parsed_class = try parseAppClass(app_class orelse return error.MissingAppClass);
        if (package) |value| try validateName(value);
        if (imports.items.len == 0) return error.MissingImport;
        for (imports.items) |entry| try validateR4XImportGeneration(entry, generation);
        try validateProfileImports(parsed_class.?, imports.items);
    } else {
        if (entry_mode != null) return error.NonR4XEntryModeForbidden;
        if (generation == 2) {
            if (imports.items.len != 1 or !std.mem.eql(u8, imports.items[0], "R4DEV:Query2:2")) return error.InvalidImport;
        }
        if (app_class != null) return error.NonR4XAppClassForbidden;
        if (package != null) return error.NonR4XPackageForbidden;
        // R4D and R4L share the R4X compiled-library mechanism. This adds no
        // runtime import or application entry point to their containers.
        if (parsed_kind != .r4d and parsed_kind != .r4l and zig_modules.items.len != 0) return error.NonR4XZigModuleForbidden;
        if (parsed_kind == .r4l) for (zig_modules.items) |module| {
            if (std.mem.startsWith(u8, module, "r4l_contract:")) return error.ReservedZigModuleName;
        };
        // image.shipped ist durch IMAGE_SCOPE abgeloest und darf nicht
        // danebenstehen - zwei Quellen fuer dieselbe Aussage waeren genau
        // die Doppelung, die diese Unterversion abschafft.
        for (metadata.items) |entry| {
            if (std.mem.startsWith(u8, entry, "image.shipped=")) return error.ImageShippedSupersededByScope;
        }
    }

    if (module_role) |role_text| {
        if (parsed_kind != .r4x) return error.ModuleRoleForbiddenForKind;
        parsed_module_role = try parseModuleRole(role_text);
        if (parsed_module_role.? == .subsystem) {
            if (parsed_class.? != .gui) return error.SubsystemRequiresGuiApp;
            parsed_subsystem_id = try normalizeContractId(
                allocator,
                subsystem_id orelse return error.MissingSubsystemId,
                subsystem_id_max_bytes,
                error.InvalidSubsystemId,
            );
            try validateSubsystemDisplayName(subsystem_display_name orelse return error.MissingSubsystemDisplayName);
            if (guest_formats.items.len == 0) return error.MissingGuestFormat;
            try normalizeGuestContract(allocator, &guest_formats, &guest_extensions, &guest_features);
            try validateSubsystemTarget(parsed_target, parsed_subsystem_id.?, parsed_name);
        }
    } else if (subsystem_id != null or subsystem_display_name != null or guest_formats.items.len != 0 or guest_extensions.items.len != 0 or guest_features.items.len != 0) {
        return error.SubsystemFieldsWithoutRole;
    }

    var is_generated_fixture = false;
    for (metadata.items) |entry| {
        if (std.mem.startsWith(u8, entry, "fixture.artifact-owner=")) {
            is_generated_fixture = true;
            break;
        }
    }

    if (parsed_kind == .r4l and !is_generated_fixture) {
        try validateRuntimeR4LExports(exports.items);
        const contract_path = contract orelse return error.MissingR4LContract;
        const baseline_path = contract_baseline orelse return error.MissingR4LContractBaseline;
        if (parsed_language == .zig and implementation_zig == null) return error.MissingR4LImplementationZig;
        if (parsed_language == .rust and binding_rust == null) return error.MissingR4LRustBinding;
        const zig_path = binding_zig orelse return error.MissingR4LZigBinding;
        const c_path = binding_c orelse return error.MissingR4LCBinding;
        const fixture_zig_path = conformance_zig orelse return error.MissingR4LZigConformance;
        const fixture_c_path = conformance_c orelse return error.MissingR4LCConformance;
        const api_path = api_reference orelse return error.MissingR4LApiReference;
        try validateLocalContractPath(contract_path, ".json");
        try validateLocalContractPath(baseline_path, ".json");
        if (implementation_zig) |implementation_path| try validateLocalContractPath(implementation_path, ".zig");
        try validateLocalContractPath(zig_path, ".zig");
        try validateLocalContractPath(c_path, ".h");
        if (binding_rust) |binding_path| try validateLocalContractPath(binding_path, ".rs");
        try validateLocalContractPath(fixture_zig_path, ".zig");
        try validateLocalContractPath(fixture_c_path, ".c");
        try validateLocalContractPath(api_path, ".md");
    } else if (parsed_kind == .r4l) {
        // Loader-Negativfixtures werden absichtlich als rohe oder formal
        // fehlerhafte R4L-Container erzeugt. Sie sind keine Runtime-Library-
        // Projekte und besitzen ihren Buildvertrag im angegebenen Fixture-
        // Generator statt in diesem beschreibenden Installationsmanifest.
    } else if (exports.items.len != 0 or contract != null or contract_baseline != null or implementation_zig != null or
        binding_zig != null or binding_c != null or binding_rust != null or conformance_zig != null or conformance_c != null or api_reference != null)
    {
        return error.NonR4LContractFieldForbidden;
    }

    return .{
        .version = manifest_version,
        .path = path,
        .kind = parsed_kind,
        .name = parsed_name,
        .module_version = parsed_module_version,
        .language = parsed_language,
        .sdk_profile = sdk_profile,
        .platform_generation = generation,
        .sources = try sources.toOwnedSlice(allocator),
        .entry_mode = parsed_entry_mode,
        .app_class = parsed_class,
        .module_role = parsed_module_role,
        .subsystem_id = parsed_subsystem_id,
        .subsystem_display_name = subsystem_display_name,
        .guest_formats = try guest_formats.toOwnedSlice(allocator),
        .guest_extensions = try guest_extensions.toOwnedSlice(allocator),
        .guest_features = try guest_features.toOwnedSlice(allocator),
        .target = parsed_target,
        .image_scope = parsed_scope,
        .optimization = parsed_optimization,
        .package = package,
        .zig_modules = try zig_modules.toOwnedSlice(allocator),
        .native_archives = try native_archives.toOwnedSlice(allocator),
        .c_includes = try c_includes.toOwnedSlice(allocator),
        .c_defines = try c_defines.toOwnedSlice(allocator),
        .c_flags = try c_flags.toOwnedSlice(allocator),
        .imports = try imports.toOwnedSlice(allocator),
        .exports = try exports.toOwnedSlice(allocator),
        .contract = contract,
        .contract_baseline = contract_baseline,
        .implementation_zig = implementation_zig,
        .binding_zig = binding_zig,
        .binding_c = binding_c,
        .binding_rust = binding_rust,
        .conformance_zig = conformance_zig,
        .conformance_c = conformance_c,
        .api_reference = api_reference,
        .metadata = try metadata.toOwnedSlice(allocator),
        .icons = try icons.toOwnedSlice(allocator),
        .help = help,
        .resources = try resources.toOwnedSlice(allocator),
    };
}

fn parseExportEntry(value: []const u8) !ExportEntry {
    var parts: [3][]const u8 = undefined;
    var count: usize = 0;
    var it = std.mem.splitScalar(u8, value, ':');
    while (it.next()) |part| {
        if (count >= parts.len or part.len == 0) return error.InvalidExport;
        parts[count] = part;
        count += 1;
    }
    if (count != parts.len) return error.InvalidExport;
    try validateExportName(parts[0]);
    try validateElfSymbol(parts[1]);
    const revision = std.fmt.parseUnsigned(u16, parts[2], 10) catch return error.InvalidExportRevision;
    if (revision == 0) return error.InvalidExportRevision;
    return .{ .name = parts[0], .symbol = parts[1], .revision = revision };
}

fn validateExports(exports: []const ExportEntry) !void {
    for (exports, 0..) |entry, index| {
        for (exports[0..index]) |prior| {
            if (std.ascii.eqlIgnoreCase(entry.name, prior.name)) return error.DuplicateExportName;
            if (std.mem.eql(u8, entry.symbol, prior.symbol)) return error.DuplicateExportSymbol;
        }
    }
}

fn validateRuntimeR4LExports(exports: []const ExportEntry) !void {
    var has_query = false;
    var interface_count: usize = 0;
    for (exports) |entry| {
        if (std.ascii.eqlIgnoreCase(entry.name, "Query")) {
            if (entry.revision != 1) return error.InvalidR4LQueryExport;
            has_query = true;
        } else if (std.ascii.eqlIgnoreCase(entry.name, "Query2")) {
            if (entry.revision != 2) return error.InvalidR4LQueryExport;
            has_query = true;
        } else {
            interface_count += 1;
        }
    }
    if (!has_query) return error.MissingR4LQueryExport;
    if (interface_count == 0) return error.MissingR4LInterfaceExport;
}

fn validateExportName(name: []const u8) !void {
    if (name.len == 0 or name.len > 31 or !std.ascii.isAlphabetic(name[0])) return error.InvalidExportName;
    for (name[1..]) |byte| if (!std.ascii.isAlphanumeric(byte) and byte != '_') return error.InvalidExportName;
}

fn validateElfSymbol(symbol: []const u8) !void {
    if (symbol.len == 0 or symbol.len > 127 or (!std.ascii.isAlphabetic(symbol[0]) and symbol[0] != '_')) return error.InvalidExportSymbol;
    for (symbol[1..]) |byte| if (!std.ascii.isAlphanumeric(byte) and byte != '_') return error.InvalidExportSymbol;
}

fn validateLocalContractPath(path: []const u8, extension: []const u8) !void {
    if (!isSafeRelativePath(path)) return error.R4LContractPathEscape;
    if (std.mem.indexOfScalar(u8, path, '\\') != null) return error.NonCanonicalR4LContractPath;
    if (!std.ascii.eqlIgnoreCase(std.fs.path.extension(path), extension)) return error.R4LContractExtensionMismatch;
}

/// RESOURCE=NAME:pfad - am ERSTEN Doppelpunkt getrennt, denn der Name darf
/// keinen enthalten, ein Pfad rechts davon aber schon.
fn parseResourceEntry(value: []const u8) !ResourceEntry {
    const colon = std.mem.indexOfScalar(u8, value, ':') orelse return error.InvalidResource;
    if (colon == 0 or colon + 1 >= value.len) return error.InvalidResource;
    return .{ .name = value[0..colon], .path = value[colon + 1 ..] };
}

/// Ressourcenname nach R4M0-Vertrag: 1 bis 63 Bytes druckbares ASCII ohne
/// Pfadtrenner und Doppelpunkt. Bewusst NICHT an FAT-Sonderformen gebunden -
/// NTFS ist das Standarddateisystem, FAT32 bleibt unterstuetzt, die Regel
/// gilt auf beiden.
fn validateResourceName(name: []const u8) !void {
    if (name.len == 0 or name.len > 63) return error.InvalidResourceName;
    for (name) |byte| {
        if (byte < 0x21 or byte > 0x7E) return error.InvalidResourceName;
        if (byte == '/' or byte == '\\' or byte == ':') return error.InvalidResourceName;
    }
}

/// Ressourcenpfade folgen denselben Regeln wie SOURCE: projektintern, keine
/// Backslashes, kein Ausbruch. Grund ist die Standalone-Baubarkeit - das
/// Projekt plus SDK muss ausserhalb des Baums byteidentisch bauen, ein
/// Verweis auf Injection/ oder zentrale Orte braeche das still.
fn validateResourcePath(path: []const u8) !void {
    if (!isSafeRelativePath(path)) return error.ResourcePathEscape;
    if (std.mem.indexOfScalar(u8, path, '\\') != null) return error.NonCanonicalResourcePath;
}

fn setSingle(slot: *?[]const u8, value: []const u8) !void {
    if (slot.* != null) return error.DuplicateField;
    slot.* = value;
}

/// MAJOR.MINOR.PATCH, drei Zahlen, sonst nichts.
///
/// Fuehrende Nullen sind verboten, damit eine Version genau EINE Schreibweise
/// hat. Sonst waeren 0.1.0 und 0.01.0 verschiedene Zeichenketten fuer dieselbe
/// Version, und ein Abgleich mit einem Updateserver haette zwei Wahrheiten.
fn parseModuleVersion(value: []const u8) !ModuleVersion {
    var numbers: [3]u16 = undefined;
    var index: usize = 0;
    var parts = std.mem.splitScalar(u8, value, '.');
    while (parts.next()) |part| {
        if (index >= numbers.len) return error.BadModuleVersion;
        if (part.len == 0 or part.len > 5) return error.BadModuleVersion;
        if (part.len > 1 and part[0] == '0') return error.BadModuleVersion;
        for (part) |char| if (!std.ascii.isDigit(char)) return error.BadModuleVersion;
        numbers[index] = std.fmt.parseUnsigned(u16, part, 10) catch return error.BadModuleVersion;
        index += 1;
    }
    if (index != numbers.len) return error.BadModuleVersion;
    return .{ .major = numbers[0], .minor = numbers[1], .patch = numbers[2], .text = value };
}

fn parseKind(value: []const u8) !Kind {
    if (std.ascii.eqlIgnoreCase(value, "R4X")) return .r4x;
    if (std.ascii.eqlIgnoreCase(value, "R4D")) return .r4d;
    if (std.ascii.eqlIgnoreCase(value, "R4P")) return .r4p;
    if (std.ascii.eqlIgnoreCase(value, "R4L")) return .r4l;
    return error.InvalidKind;
}

fn parseLanguage(value: []const u8) !Language {
    if (std.ascii.eqlIgnoreCase(value, "Zig")) return .zig;
    if (std.ascii.eqlIgnoreCase(value, "C")) return .c;
    if (std.ascii.eqlIgnoreCase(value, "Rust")) return .rust;
    return error.InvalidLanguage;
}

fn parseAppClass(value: []const u8) !AppClass {
    if (std.ascii.eqlIgnoreCase(value, "console")) return .console;
    if (std.ascii.eqlIgnoreCase(value, "gui")) return .gui;
    if (std.ascii.eqlIgnoreCase(value, "service")) return .service;
    return error.InvalidAppClass;
}

fn parseEntryMode(value: []const u8) !EntryMode {
    if (std.ascii.eqlIgnoreCase(value, "app")) return .app;
    if (std.ascii.eqlIgnoreCase(value, "lowlevel")) return .lowlevel;
    return error.InvalidEntryMode;
}

fn parseImageScope(value: []const u8) !ImageScope {
    if (std.ascii.eqlIgnoreCase(value, "slim")) return .slim;
    if (std.ascii.eqlIgnoreCase(value, "full")) return .full;
    if (std.ascii.eqlIgnoreCase(value, "test")) return .@"test";
    if (std.ascii.eqlIgnoreCase(value, "none")) return .none;
    return error.InvalidImageScope;
}

fn parseOptimization(value: []const u8) !Optimization {
    if (std.ascii.eqlIgnoreCase(value, "size")) return .size;
    if (std.ascii.eqlIgnoreCase(value, "speed")) return .speed;
    return error.InvalidOptimization;
}

fn parseModuleRole(value: []const u8) !ModuleRole {
    if (std.ascii.eqlIgnoreCase(value, "subsystem")) return .subsystem;
    return error.InvalidModuleRole;
}

fn parseGuestExtensionEntry(value: []const u8) !GuestExtensionEntry {
    const colon = std.mem.indexOfScalar(u8, value, ':') orelse return error.InvalidGuestExtension;
    if (colon == 0 or colon + 1 >= value.len or std.mem.indexOfScalar(u8, value[colon + 1 ..], ':') != null) {
        return error.InvalidGuestExtension;
    }
    return .{ .format_id = value[0..colon], .extension = value[colon + 1 ..] };
}

fn parseGuestFeatureEntry(value: []const u8) !GuestFeatureEntry {
    const colon = std.mem.indexOfScalar(u8, value, ':') orelse return error.InvalidGuestFeature;
    if (colon == 0 or colon + 1 >= value.len or std.mem.indexOfScalar(u8, value[colon + 1 ..], ':') != null) {
        return error.InvalidGuestFeature;
    }
    return .{ .format_id = value[0..colon], .feature = value[colon + 1 ..] };
}

fn normalizeContractId(
    allocator: std.mem.Allocator,
    value: []const u8,
    max_bytes: usize,
    invalid_error: anyerror,
) ![]const u8 {
    if (value.len == 0 or value.len > max_bytes or !std.ascii.isAlphabetic(value[0]) or !std.ascii.isAlphanumeric(value[value.len - 1])) {
        return invalid_error;
    }
    if (value.len > 2) for (value[1 .. value.len - 1]) |byte| {
        if (!std.ascii.isAlphanumeric(byte) and byte != '.' and byte != '_' and byte != '-') return invalid_error;
    };
    const normalized = try allocator.dupe(u8, value);
    for (normalized) |*byte| byte.* = std.ascii.toLower(byte.*);
    return normalized;
}

fn normalizeGuestExtension(allocator: std.mem.Allocator, value: []const u8) ![]const u8 {
    if (value.len < 2 or value.len > guest_extension_max_bytes or value[0] != '.' or !std.ascii.isAlphanumeric(value[1]) or !std.ascii.isAlphanumeric(value[value.len - 1])) {
        return error.InvalidGuestExtension;
    }
    if (value.len > 3) for (value[2 .. value.len - 1]) |byte| {
        if (!std.ascii.isAlphanumeric(byte) and byte != '.' and byte != '_' and byte != '-') return error.InvalidGuestExtension;
    };
    const normalized = try allocator.dupe(u8, value);
    for (normalized) |*byte| byte.* = std.ascii.toLower(byte.*);
    return normalized;
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
        return offset <= 128 * 1024 and byte_count <= 128 * 1024 - @as(usize, @intCast(offset));
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

fn validateSubsystemDisplayName(value: []const u8) !void {
    if (value.len == 0 or value.len > subsystem_display_name_max_bytes or
        !std.unicode.utf8ValidateSlice(value) or
        !std.mem.eql(u8, value, std.mem.trim(u8, value, " \t")))
    {
        return error.InvalidSubsystemDisplayName;
    }
    for (value) |byte| {
        if (byte < 0x20 or byte == 0x7f or byte == '"' or byte == '\\') return error.InvalidSubsystemDisplayName;
    }
}

fn normalizeGuestContract(
    allocator: std.mem.Allocator,
    formats: *std.ArrayList([]const u8),
    extensions: *std.ArrayList(GuestExtensionEntry),
    features: *std.ArrayList(GuestFeatureEntry),
) !void {
    if (formats.items.len > max_guest_formats) return error.TooManyGuestFormats;
    if (extensions.items.len > max_guest_extensions) return error.TooManyGuestExtensions;
    if (features.items.len > max_guest_features) return error.TooManyGuestFeatures;

    for (formats.items, 0..) |*format_id, index| {
        format_id.* = try normalizeContractId(allocator, format_id.*, guest_format_id_max_bytes, error.InvalidGuestFormat);
        for (formats.items[0..index]) |prior| {
            if (std.mem.eql(u8, format_id.*, prior)) return error.DuplicateGuestFormat;
        }
    }
    for (extensions.items, 0..) |*entry, index| {
        entry.format_id = try normalizeContractId(allocator, entry.format_id, guest_format_id_max_bytes, error.InvalidGuestFormat);
        entry.extension = try normalizeGuestExtension(allocator, entry.extension);
        if (!containsString(formats.items, entry.format_id)) return error.UndeclaredGuestFormat;
        for (extensions.items[0..index]) |prior| {
            if (std.mem.eql(u8, entry.format_id, prior.format_id) and std.mem.eql(u8, entry.extension, prior.extension)) {
                return error.DuplicateGuestExtension;
            }
        }
    }
    for (features.items, 0..) |*entry, index| {
        entry.format_id = try normalizeContractId(allocator, entry.format_id, guest_format_id_max_bytes, error.InvalidGuestFormat);
        entry.feature = try normalizeContractId(allocator, entry.feature, guest_feature_max_bytes, error.InvalidGuestFeature);
        if (!validKnownGuestFeature(entry.feature)) return error.InvalidGuestFeature;
        if (!containsString(formats.items, entry.format_id)) return error.UndeclaredGuestFormat;
        for (features.items[0..index]) |prior| {
            if (std.mem.eql(u8, entry.format_id, prior.format_id) and std.mem.eql(u8, entry.feature, prior.feature)) {
                return error.DuplicateGuestFeature;
            }
        }
    }
}

fn containsString(values: []const []const u8, wanted: []const u8) bool {
    for (values) |value| if (std.mem.eql(u8, value, wanted)) return true;
    return false;
}

fn validateSubsystemTarget(target: []const u8, subsystem_id: []const u8, name: []const u8) !void {
    var expected_buffer: [128]u8 = undefined;
    const expected = std.fmt.bufPrint(expected_buffer[0..], "/R4OS/SUBSYSTEMS/{s}/{s}.R4X", .{ subsystem_id, name }) catch return error.InvalidSubsystemTarget;
    if (!std.ascii.eqlIgnoreCase(target, expected)) return error.InvalidSubsystemTarget;
}

fn validateName(name: []const u8) !void {
    if (name.len == 0 or name.len > 31) return error.InvalidName;
    for (name) |byte| {
        if (!std.ascii.isAlphanumeric(byte) and byte != '_' and byte != '-') return error.InvalidName;
    }
}

fn validateSource(source: []const u8, language: Language) !void {
    if (!isSafeRelativePath(source)) return error.SourcePathEscape;
    if (std.mem.indexOfScalar(u8, source, '\\') != null) return error.NonCanonicalSourcePath;
    const extension = std.fs.path.extension(source);
    if (language == .zig and !std.ascii.eqlIgnoreCase(extension, ".zig")) return error.SourceLanguageMismatch;
    if (language == .c and !std.ascii.eqlIgnoreCase(extension, ".c")) return error.SourceLanguageMismatch;
    if (language == .rust and !std.mem.eql(u8, extension, ".rs")) return error.SourceLanguageMismatch;
    if (language == .rust and std.mem.indexOf(u8, source, "//") != null) return error.NonCanonicalSourcePath;
}

fn validateZigModules(values: []const []const u8) !void {
    for (values, 0..) |value, index| {
        const colon = std.mem.indexOfScalar(u8, value, ':') orelse return error.InvalidZigModule;
        if (colon == 0 or colon + 1 >= value.len or std.mem.indexOfScalar(u8, value[colon + 1 ..], ':') != null) return error.InvalidZigModule;
        const name = value[0..colon];
        const path = value[colon + 1 ..];
        if ((!std.ascii.isAlphabetic(name[0]) and name[0] != '_') or std.mem.eql(u8, name, "r4os") or std.mem.eql(u8, name, "r4_app_source")) return error.InvalidZigModuleName;
        for (name[1..]) |byte| if (!std.ascii.isAlphanumeric(byte) and byte != '_') return error.InvalidZigModuleName;
        if (path[0] == '/' or path[0] == '\\' or std.mem.indexOfScalar(u8, path, '\\') != null or !std.ascii.eqlIgnoreCase(std.fs.path.extension(path), ".zig")) return error.InvalidZigModulePath;
        var components = std.mem.tokenizeScalar(u8, path, '/');
        var count: usize = 0;
        while (components.next()) |component| {
            count += 1;
            if (std.mem.eql(u8, component, ".") or component.len == 0) return error.InvalidZigModulePath;
        }
        if (count == 0) return error.InvalidZigModulePath;
        for (values[0..index]) |prior| {
            const prior_colon = std.mem.indexOfScalar(u8, prior, ':') orelse unreachable;
            if (std.ascii.eqlIgnoreCase(name, prior[0..prior_colon])) return error.DuplicateZigModuleName;
        }
    }
}

fn parseCDefineEntry(value: []const u8) !CDefineEntry {
    const eq = std.mem.indexOfScalar(u8, value, '=') orelse return error.InvalidCDefine;
    if (eq == 0 or eq + 1 >= value.len) return error.InvalidCDefine;
    return .{ .name = value[0..eq], .value = value[eq + 1 ..] };
}

fn validateCConfiguration(includes: []const []const u8, defines: []const CDefineEntry, flags: []const []const u8) !void {
    for (includes, 0..) |path, index| {
        try validateBuildRelativePath(path);
        for (includes[0..index]) |prior| if (std.ascii.eqlIgnoreCase(path, prior)) return error.DuplicateCInclude;
    }
    for (defines, 0..) |entry, index| {
        if (entry.name.len == 0 or (!std.ascii.isAlphabetic(entry.name[0]) and entry.name[0] != '_')) return error.InvalidCDefine;
        for (entry.name[1..]) |byte| if (!std.ascii.isAlphanumeric(byte) and byte != '_') return error.InvalidCDefine;
        for (entry.value) |byte| if (byte <= 0x20 or byte == 0x7F) return error.InvalidCDefine;
        for (defines[0..index]) |prior| if (std.ascii.eqlIgnoreCase(entry.name, prior.name)) return error.DuplicateCDefine;
    }
    for (flags, 0..) |flag, index| {
        if (flag.len < 2 or flag.len > 127 or flag[0] != '-') return error.InvalidCFlag;
        for (flag) |byte| if (byte <= 0x20 or byte == 0x7F) return error.InvalidCFlag;
        for (flags[0..index]) |prior| if (std.mem.eql(u8, flag, prior)) return error.DuplicateCFlag;
    }
}

/// Buildabhaengigkeiten duerfen wie ZIG_MODULE zu einem benachbarten Repo
/// zeigen. Absolute Pfade, Backslashes, leere und explizite Punktkomponenten
/// bleiben verboten; `..` wird bewusst zugelassen.
fn validateBuildRelativePath(path: []const u8) !void {
    if (path.len == 0 or path[0] == '/' or path[0] == '\\' or std.mem.indexOfScalar(u8, path, '\\') != null or std.mem.indexOfScalar(u8, path, ':') != null) {
        return error.InvalidCInclude;
    }
    var components = std.mem.tokenizeScalar(u8, path, '/');
    var count: usize = 0;
    while (components.next()) |component| {
        count += 1;
        if (component.len == 0 or std.mem.eql(u8, component, ".")) return error.InvalidCInclude;
    }
    if (count == 0) return error.InvalidCInclude;
}

fn isSafeRelativePath(path: []const u8) bool {
    if (path.len == 0 or path[0] == '/' or path[0] == '\\' or std.mem.indexOfScalar(u8, path, ':') != null) return false;
    var components = std.mem.tokenizeAny(u8, path, "/\\");
    var count: usize = 0;
    while (components.next()) |component| {
        count += 1;
        if (std.mem.eql(u8, component, ".") or std.mem.eql(u8, component, "..")) return false;
    }
    return count != 0;
}

fn validateTarget(target: []const u8, kind: Kind) !void {
    if (target.len < 2 or target.len > 127 or target[0] != '/' or std.mem.indexOfScalar(u8, target, '\\') != null or std.mem.indexOfScalar(u8, target, ':') != null) return error.InvalidTarget;
    if (std.mem.indexOf(u8, target, "//") != null) return error.InvalidTarget;
    var components = std.mem.tokenizeScalar(u8, target, '/');
    while (components.next()) |component| {
        if (std.mem.eql(u8, component, ".") or std.mem.eql(u8, component, "..") or component.len > 63) return error.InvalidTarget;
    }
    const dot = std.mem.lastIndexOfScalar(u8, target, '.') orelse return error.InvalidTarget;
    if (!std.ascii.eqlIgnoreCase(target[dot + 1 ..], kind.text())) return error.TargetKindMismatch;
}

fn validateImportSyntax(value: []const u8) !void {
    _ = try import_spec.parse(value);
}

/// R4M0 import bit 0 permits an absent/incompatible Runtime-R4L provider.
/// Call only after manifest validation; platform imports remain mandatory.
pub fn importIsOptional(value: []const u8) bool {
    var parts = std.mem.splitScalar(u8, value, ':');
    _ = parts.next();
    _ = parts.next();
    _ = parts.next();
    const text = parts.next() orelse return false;
    return (std.fmt.parseUnsigned(u32, text, 10) catch return false) == 1;
}

fn platformGeneration(a: std.mem.Allocator, kind: Kind, language: Language, selection: ?[]const u8) !u8 {
    _ = a;
    const id = selection orelse return 1;
    for (@import("generated/profile_policy.zig").profiles) |profile| {
        if (!std.mem.eql(u8, profile.id, id)) continue;
        if (!std.mem.eql(u8, profile.language, language.text()) or !std.mem.eql(u8, profile.role, "module") or (profile.kind.len != 0 and !std.mem.eql(u8, profile.kind, kind.text()))) return error.SdkProfileRoleMismatch;
        if (!profile.explicit_platform) return error.ExplicitPlatformProfileRequired;
        if (profile.generation != 2) return error.UnsupportedSdkPlatform;
        return profile.generation;
    }
    return error.UnknownSdkProfile;
}

fn validateR4XImport(value: []const u8) !void {
    return validateR4XImportGeneration(value, 1);
}
fn validateR4XImportGeneration(value: []const u8, generation: u8) !void {
    var parts = std.mem.splitScalar(u8, value, ':');
    const group = parts.next() orelse return error.InvalidImport;
    const symbol = parts.next() orelse return error.InvalidImport;
    const major = parts.next() orelse return error.InvalidImport;
    _ = parts.next(); // Optional flags were checked by validateImportSyntax.
    if (parts.next() != null) return error.InvalidImport;

    // Nur die sechs kernelimplementierten Plattformgruppen besitzen den
    // festen Query:1-Vertrag. Alle anderen R4Ls werden direkt ueber ihren
    // Modul- und Exportnamen importiert; dafuer ist keine zentrale
    // R4LGroup-Konstante erforderlich.
    const query = if (generation == 2) "Query2" else "Query";
    const revision = if (generation == 2) "2" else "1";
    if ((isPlatformGroup(group) or std.mem.eql(u8, symbol, "Query") or std.mem.eql(u8, symbol, "Query2")) and (!std.mem.eql(u8, symbol, query) or !std.mem.eql(u8, major, revision))) {
        return error.InvalidImport;
    }
}

fn validateMetadata(values: []const []const u8) !void {
    _ = try appearance_metadata.parse(values);
    for (values, 0..) |value, index| {
        const eq = std.mem.indexOfScalar(u8, value, '=') orelse return error.InvalidMetadata;
        if (eq == 0 or eq + 1 >= value.len) return error.InvalidMetadata;
        const key = value[0..eq];
        if (std.ascii.eqlIgnoreCase(key, "runtime.workers") and
            !std.mem.eql(u8, value[eq + 1 ..], "bsp") and
            !std.mem.eql(u8, value[eq + 1 ..], "owned-v1")) return error.InvalidMetadata;
        if (std.ascii.eqlIgnoreCase(key, "app.class") or
            std.ascii.eqlIgnoreCase(key, "module.role") or
            asciiStartsWithIgnoreCase(key, "r4x.") or
            asciiStartsWithIgnoreCase(key, "subsystem.")) return error.DerivedMetadataForbidden;
        for (values[0..index]) |prior| {
            const prior_eq = std.mem.indexOfScalar(u8, prior, '=') orelse unreachable;
            if (std.ascii.eqlIgnoreCase(key, prior[0..prior_eq]) and !isMultiValueMetadataKey(key)) return error.DuplicateMetadataKey;
        }
    }
}

fn asciiStartsWithIgnoreCase(value: []const u8, prefix: []const u8) bool {
    return value.len >= prefix.len and std.ascii.eqlIgnoreCase(value[0..prefix.len], prefix);
}

fn isMultiValueMetadataKey(key: []const u8) bool {
    return std.ascii.eqlIgnoreCase(key, "feature") or
        std.ascii.eqlIgnoreCase(key, "dependency") or
        std.ascii.eqlIgnoreCase(key, "r4p.dep");
}

fn validateProfileImports(app_class: AppClass, imports: []const []const u8) !void {
    const meta = profileMeta(app_class) orelse return error.ProfileSourceDrift;
    var declared_mask: u32 = 0;
    for (imports) |entry| {
        const colon = std.mem.indexOfScalar(u8, entry, ':') orelse return error.InvalidImport;
        if (groupMask(entry[0..colon])) |mask| declared_mask |= mask;
    }
    if ((declared_mask & meta.required_groups) != meta.required_groups) return error.MissingProfileImport;
}

fn profileMeta(app_class: AppClass) ?abi.R4AppProfileMeta {
    for (abi.r4_app_profiles) |meta| {
        if (std.ascii.eqlIgnoreCase(@tagName(meta.app_class), app_class.text())) return meta;
    }
    return null;
}

fn groupMask(group: []const u8) ?u32 {
    const bit: u32 = if (std.ascii.eqlIgnoreCase(group, "R4SYS")) @intFromEnum(abi.R4LGroup.r4sys) else if (std.ascii.eqlIgnoreCase(group, "R4DESK")) @intFromEnum(abi.R4LGroup.r4desk) else if (std.ascii.eqlIgnoreCase(group, "R4DRAW")) @intFromEnum(abi.R4LGroup.r4draw) else if (std.ascii.eqlIgnoreCase(group, "R4NET")) @intFromEnum(abi.R4LGroup.r4net) else if (std.ascii.eqlIgnoreCase(group, "R4AUDIO")) @intFromEnum(abi.R4LGroup.r4audio) else if (std.ascii.eqlIgnoreCase(group, "R4DEV")) @intFromEnum(abi.R4LGroup.r4dev) else return null;
    return @as(u32, 1) << @intCast(bit);
}

fn isPlatformGroup(group: []const u8) bool {
    return std.ascii.eqlIgnoreCase(group, "R4SYS") or
        std.ascii.eqlIgnoreCase(group, "R4DESK") or
        std.ascii.eqlIgnoreCase(group, "R4DRAW") or
        std.ascii.eqlIgnoreCase(group, "R4NET") or
        std.ascii.eqlIgnoreCase(group, "R4AUDIO") or
        std.ascii.eqlIgnoreCase(group, "R4DEV");
}

fn ensureUnique(values: []const []const u8, case_insensitive: bool) !void {
    for (values, 0..) |value, index| {
        for (values[0..index]) |prior| {
            const equal = if (case_insensitive) std.ascii.eqlIgnoreCase(value, prior) else std.mem.eql(u8, value, prior);
            if (equal) return error.DuplicateValue;
        }
    }
}

fn pathProject(path: []const u8) ?[]const u8 {
    const slash = std.mem.lastIndexOfAny(u8, path, "/\\") orelse return null;
    return path[0..slash];
}

/// Die Modulversion als Metadatenzeile fuer den R4M0-Container.
///
/// Bewusst fuer ALLE vier Modularten dieselbe Zeile: Die uebrigen abgeleiteten
/// Schluessel sind artspezifisch (r4x.name, r4d.name, r4l.group), aber ein
/// Leser, der wissen will welche Version einer Datei installiert ist, soll
/// nicht erst die Modulart bestimmen muessen.
pub fn moduleVersionMeta(allocator: std.mem.Allocator, manifest: Manifest) ![]const u8 {
    return std.fmt.allocPrint(allocator, "module.version={s}", .{manifest.module_version.text});
}

/// Vom Manifest abgeleitete R4X-Rollenmetadaten plus explizite META-Zeilen.
/// Diese Funktion wird sowohl vom semantischen Plan als auch vom wirklichen
/// Packagerpfad benutzt, damit der Container keine zweite Rollenwahrheit hat.
pub fn r4xManifestMetadata(allocator: std.mem.Allocator, manifest: Manifest) ![]const []const u8 {
    if (manifest.version != manifest_version or manifest.kind != .r4x) return error.CurrentManifestRequired;
    if (manifest.module_role == null) return manifest.metadata;

    var metadata: std.ArrayList([]const u8) = .empty;
    try metadata.append(allocator, try std.fmt.allocPrint(allocator, "module.role={s}", .{manifest.module_role.?.text()}));
    try metadata.append(allocator, try std.fmt.allocPrint(allocator, "subsystem.id={s}", .{manifest.subsystem_id.?}));
    try metadata.append(allocator, try std.fmt.allocPrint(allocator, "subsystem.display_name={s}", .{manifest.subsystem_display_name.?}));
    for (manifest.guest_formats) |format_id| {
        try metadata.append(allocator, try std.fmt.allocPrint(allocator, "subsystem.format={s}", .{format_id}));
    }
    for (manifest.guest_extensions) |entry| {
        try metadata.append(allocator, try std.fmt.allocPrint(allocator, "subsystem.extension={s}:{s}", .{ entry.format_id, entry.extension }));
    }
    for (manifest.guest_features) |entry| {
        try metadata.append(allocator, try std.fmt.allocPrint(allocator, "subsystem.feature={s}:{s}", .{ entry.format_id, entry.feature }));
    }
    try metadata.appendSlice(allocator, manifest.metadata);
    return metadata.toOwnedSlice(allocator);
}

/// The SDK admission profile differs from the historical native build-profile
/// display name. Defaults are generated only from Profiles/Build.json.
pub fn sdkBuildProfile(manifest: Manifest) ![]const u8 {
    if (manifest.sdk_profile) |profile| return profile;
    const language = manifest.language orelse return error.MissingLanguage;
    const entry = if (manifest.entry_mode) |mode| mode.text() else "";
    for (@import("generated/profile_policy.zig").module_defaults) |selection| {
        if (std.mem.eql(u8, selection.language, language.text()) and
            std.mem.eql(u8, selection.kind, manifest.kind.text()) and
            (selection.entry.len == 0 or std.mem.eql(u8, selection.entry, entry))) return selection.profile;
    }
    return error.UnknownSdkProfile;
}

/// Canonical role exports for tooling and container generation. Runtime R4Ls
/// preserve their own explicitly declared interface revisions.
pub fn moduleExports(allocator: std.mem.Allocator, manifest: Manifest) ![]const []const u8 {
    const next = manifest.platform_generation == 2;
    return switch (manifest.kind) {
        .r4x => if (next) &.{"R4XStart2:@R4XStart2:2"} else &.{"R4XStart:@R4XStart:1"},
        .r4d => if (next) &.{ "DriverInit2:@DriverInit2:2", "DriverShutdown:@DriverShutdown:1" } else &.{ "DriverInit:@r4d_init_entry:1", "DriverShutdown:@r4d_shutdown_entry:1" },
        .r4p => if (next) &.{ "ProtocolInit2:@ProtocolInit2:2", "ProtocolShutdown:@ProtocolShutdown:1", "ProtocolQuery:@ProtocolQuery:1", "ProtocolDispatch:@ProtocolDispatch:1", "ProtocolRole:@ProtocolInit2:1" } else &.{ "ProtocolInit:@r4p_init_entry:1", "ProtocolShutdown:@r4p_shutdown_entry:1", "ProtocolQuery:@r4p_query_entry:1", "ProtocolDispatch:@r4p_dispatch_entry:1", "ProtocolRole:@r4p_init_entry:1" },
        .r4l => block: {
            var exports: std.ArrayList([]const u8) = .empty;
            for (manifest.exports) |value| try exports.append(allocator, try std.fmt.allocPrint(allocator, "{s}:@{s}:{d}", .{ value.name, value.symbol, value.revision }));
            break :block try exports.toOwnedSlice(allocator);
        },
    };
}

pub fn derivePlan(allocator: std.mem.Allocator, manifest: Manifest) !Plan {
    if (manifest.version != manifest_version or manifest.kind != .r4x) return error.CurrentManifestRequired;
    const language = manifest.language orelse return error.MissingLanguage;
    const app_class = manifest.app_class orelse return error.MissingAppClass;
    const profile = profileMeta(app_class) orelse return error.ProfileSourceDrift;
    const source_project = pathProject(manifest.path) orelse ".";
    const artifact = try std.fmt.allocPrint(allocator, "Code/zig-out/{s}.R4X", .{manifest.name});
    const profile_suffix = switch (app_class) {
        .console => "Console",
        .gui => "Desktop",
        .service => "Service",
    };
    const entry_mode = manifest.entry_mode orelse return error.MissingEntryMode;
    const build_profile = try std.fmt.allocPrint(allocator, "R4X_{s}_{s}_{s}", .{ language.text(), if (entry_mode == .app) "App" else "LowLevel", profile_suffix });

    var metadata: std.ArrayList([]const u8) = .empty;
    try metadata.append(allocator, try std.fmt.allocPrint(allocator, "r4x.name={s}", .{manifest.name}));
    try metadata.append(allocator, try std.fmt.allocPrint(allocator, "r4x.class={s}", .{app_class.text()}));
    try metadata.append(allocator, try moduleVersionMeta(allocator, manifest));
    try metadata.appendSlice(allocator, if (manifest.platform_generation == 2)
        &.{ "feature=program-module", "r4x.start=r4xstart2", "r4x.entry=R4XStart2", "r4x.start_abi=2", "r4x.context=R4XStartContext2" }
    else
        &.{ "feature=program-module", "r4x.start=r4xstart", "r4x.entry=R4XStart", "r4x.start_abi=1", "r4x.context=R4XStartContext" });
    var has_memory_profile = false;
    for (manifest.metadata) |entry| {
        if (std.mem.startsWith(u8, entry, "memory.profile=")) has_memory_profile = true;
    }
    if (!has_memory_profile) {
        const default_profile = switch (app_class) {
            .console => "normal",
            .gui => "desktop",
            .service => "service",
        };
        try metadata.append(allocator, try std.fmt.allocPrint(allocator, "memory.profile={s}", .{default_profile}));
    }
    try metadata.appendSlice(allocator, try r4xManifestMetadata(allocator, manifest));

    return .{
        .source_project = source_project,
        .artifact = artifact,
        .build_profile = manifest.sdk_profile orelse build_profile,
        .export_contract = if (manifest.platform_generation == 2) "R4XStart2:R4XStart2:2" else "R4XStart:R4XStart:1",
        .r4x_start_abi = if (manifest.platform_generation == 2) "R4XStart2:2" else "R4XStart:1",
        .app_profile = profile.name,
        .app_class = app_class.text(),
        .optimization = manifest.optimization.?.text(),
        .imports = manifest.imports,
        .metadata = try metadata.toOwnedSlice(allocator),
    };
}

pub fn buildProfileName(language: Language, entry_mode: EntryMode, app_class: AppClass) []const u8 {
    return switch (language) {
        .rust => switch (entry_mode) {
            .app => switch (app_class) {
                .console => "R4X_Rust_App_Console",
                .gui => "R4X_Rust_App_Desktop",
                .service => "R4X_Rust_App_Service",
            },
            .lowlevel => switch (app_class) {
                .console => "R4X_Rust_LowLevel_Console",
                .gui => "R4X_Rust_LowLevel_Desktop",
                .service => "R4X_Rust_LowLevel_Service",
            },
        },
        .zig => switch (entry_mode) {
            .app => switch (app_class) {
                .console => "R4X_Zig_App_Console",
                .gui => "R4X_Zig_App_Desktop",
                .service => "R4X_Zig_App_Service",
            },
            .lowlevel => switch (app_class) {
                .console => "R4X_Zig_LowLevel_Console",
                .gui => "R4X_Zig_LowLevel_Desktop",
                .service => "R4X_Zig_LowLevel_Service",
            },
        },
        .c => switch (entry_mode) {
            .app => switch (app_class) {
                .console => "R4X_C_App_Console",
                .gui => "R4X_C_App_Desktop",
                .service => "R4X_C_App_Service",
            },
            .lowlevel => switch (app_class) {
                .console => "R4X_C_LowLevel_Console",
                .gui => "R4X_C_LowLevel_Desktop",
                .service => "R4X_C_LowLevel_Service",
            },
        },
    };
}

pub fn appProfileName(app_class: AppClass) []const u8 {
    return switch (app_class) {
        .console => "console",
        .gui => "desktop",
        .service => "service",
    };
}

/// R4MF_PLAN is the environment-neutral semantic plan shared by the host
/// catalog and inside-R4OS tools. Artifact locations are deliberately absent:
/// the host aggregate and R4BUILD install into different build directories.
pub fn renderContractPlan(manifest: Manifest, out: []u8) RenderResult {
    if (manifest.version != manifest_version or manifest.kind != .r4x) return .{ .bytes = out[0..0], .ok = false };
    const language = manifest.language orelse return .{ .bytes = out[0..0], .ok = false };
    const entry_mode = manifest.entry_mode orelse return .{ .bytes = out[0..0], .ok = false };
    const app_class = manifest.app_class orelse return .{ .bytes = out[0..0], .ok = false };
    const image_scope = manifest.image_scope orelse return .{ .bytes = out[0..0], .ok = false };

    var len: usize = 0;
    if (!appendPlanLine(out, &len, "R4MF_PLAN", "1") or
        !appendPlanLine(out, &len, "KIND", manifest.kind.text()) or
        !appendPlanLine(out, &len, "NAME", manifest.name) or
        !appendPlanLine(out, &len, "LANGUAGE", language.text()))
    {
        return .{ .bytes = out[0..0], .ok = false };
    }
    for (manifest.sources) |source| if (!appendPlanLine(out, &len, "SOURCE", source)) return .{ .bytes = out[0..0], .ok = false };
    if (!appendPlanLine(out, &len, "ENTRY_MODE", entry_mode.text()) or
        !appendPlanLine(out, &len, "APP_CLASS", app_class.text()))
    {
        return .{ .bytes = out[0..0], .ok = false };
    }
    if (manifest.module_role) |role| {
        if (!appendPlanLine(out, &len, "MODULE_ROLE", role.text()) or
            !appendPlanLine(out, &len, "SUBSYSTEM_ID", manifest.subsystem_id.?) or
            !appendPlanLine(out, &len, "SUBSYSTEM_DISPLAY_NAME", manifest.subsystem_display_name.?))
        {
            return .{ .bytes = out[0..0], .ok = false };
        }
        for (manifest.guest_formats) |entry| if (!appendPlanLine(out, &len, "GUEST_FORMAT", entry)) return .{ .bytes = out[0..0], .ok = false };
        for (manifest.guest_extensions) |entry| if (!appendMappedPlanLine(out, &len, "GUEST_EXTENSION", entry.format_id, entry.extension)) return .{ .bytes = out[0..0], .ok = false };
        for (manifest.guest_features) |entry| if (!appendMappedPlanLine(out, &len, "GUEST_FEATURE", entry.format_id, entry.feature)) return .{ .bytes = out[0..0], .ok = false };
    }
    if (!appendPlanLine(out, &len, "TARGET", manifest.target) or
        !appendPlanLine(out, &len, "IMAGE_SCOPE", image_scope.text()) or
        !appendPlanLine(out, &len, "OPTIMIZE", manifest.optimization.?.text()) or
        !appendPlanLine(out, &len, "BUILD_PROFILE", manifest.sdk_profile orelse buildProfileName(language, entry_mode, app_class)) or
        !appendPlanLine(out, &len, "APP_PROFILE", appProfileName(app_class)))
    {
        return .{ .bytes = out[0..0], .ok = false };
    }
    for (manifest.imports) |entry| if (!appendPlanLine(out, &len, "IMPORT", entry)) return .{ .bytes = out[0..0], .ok = false };
    // Ressourcen in Vertragsreihenfolge: erst Icons, dann Help, dann Dateien.
    for (manifest.icons) |entry| if (!appendPlanLine(out, &len, "ICON", entry)) return .{ .bytes = out[0..0], .ok = false };
    if (manifest.help) |entry| if (!appendPlanLine(out, &len, "HELP", entry)) return .{ .bytes = out[0..0], .ok = false };
    for (manifest.resources) |entry| {
        if (!appendPlanBytes(out, &len, "RESOURCE=") or
            !appendPlanBytes(out, &len, entry.name) or
            !appendPlanBytes(out, &len, ":") or
            !appendPlanBytes(out, &len, entry.path) or
            !appendPlanBytes(out, &len, "\n"))
        {
            return .{ .bytes = out[0..0], .ok = false };
        }
    }
    for (manifest.metadata) |entry| if (!appendPlanLine(out, &len, "META", entry)) return .{ .bytes = out[0..0], .ok = false };
    return .{ .bytes = out[0..len], .ok = true };
}

fn appendMappedPlanLine(out: []u8, len: *usize, key: []const u8, left: []const u8, right: []const u8) bool {
    return appendPlanBytes(out, len, key) and
        appendPlanBytes(out, len, "=") and
        appendPlanBytes(out, len, left) and
        appendPlanBytes(out, len, ":") and
        appendPlanBytes(out, len, right) and
        appendPlanBytes(out, len, "\n");
}

fn appendPlanLine(out: []u8, len: *usize, key: []const u8, value: []const u8) bool {
    return appendPlanBytes(out, len, key) and appendPlanBytes(out, len, "=") and appendPlanBytes(out, len, value) and appendPlanBytes(out, len, "\n");
}

fn appendPlanBytes(out: []u8, len: *usize, value: []const u8) bool {
    if (len.* + value.len > out.len) return false;
    @memcpy(out[len.* .. len.* + value.len], value);
    len.* += value.len;
    return true;
}

test "V2 derives profile build and fixed start contract from the SDK profile source" {
    try validateMetadata(&.{ "gui.title.background=000000", "gui.title.foreground=FfEeDd" });
    try std.testing.expectError(error.InvalidTitleColor, validateMetadata(&.{"gui.title.background=#123456"}));
    try std.testing.expectError(error.DuplicateTitleColor, validateMetadata(&.{ "gui.title.foreground=123456", "gui.title.foreground=123456" }));
    try validateMetadata(&.{ "runtime.parallel=bsp", "runtime.workers=owned-v1" });
    try std.testing.expectError(error.InvalidMetadata, validateMetadata(&.{"runtime.workers=maybe"}));
    try std.testing.expectError(error.DuplicateMetadataKey, validateMetadata(&.{ "runtime.workers=bsp", "runtime.workers=owned-v1" }));
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const text =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4X
        \\NAME=HELLO
        \\VERSION=0.1.0
        \\LANGUAGE=Zig
        \\SOURCE=src/main.zig
        \\ENTRY_MODE=app
        \\APP_CLASS=gui
        \\TARGET=/R4OS/SOFTWARE/DESKTOP/HELLO.R4X
        \\IMAGE_SCOPE=full
        \\OPTIMIZE=speed
        \\IMPORT=R4SYS:Query:1
        \\IMPORT=R4DESK:Query:1
        \\IMPORT=R4DRAW:Query:1
        \\META=desktop.launch=hosted
    ;
    const manifest = try parse(allocator, "Code/System/Software/Hello/module.R4MF", text);
    const plan = try derivePlan(allocator, manifest);
    try std.testing.expectEqualStrings("desktop", plan.app_profile);
    try std.testing.expectEqualStrings("R4X_Zig_App_Desktop", plan.build_profile);
    try std.testing.expectEqualStrings("speed", plan.optimization);
    try std.testing.expectEqualStrings("R4XStart:R4XStart:1", plan.export_contract);
    try std.testing.expectEqual(@as(usize, 3), plan.imports.len);
}

test "contract plan is deterministic and environment neutral" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const text =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4X
        \\NAME=CPLAN
        \\VERSION=0.1.0
        \\LANGUAGE=C
        \\SOURCE=src/main.c
        \\ENTRY_MODE=app
        \\APP_CLASS=console
        \\TARGET=/R4OS/SOFTWARE/TERMINAL/CPLAN.R4X
        \\IMAGE_SCOPE=none
        \\IMPORT=R4SYS:Query:1
    ;
    const value = try parse(allocator, "CPLAN/module.R4MF", text);
    var first: [1024]u8 = undefined;
    var second: [1024]u8 = undefined;
    const a = renderContractPlan(value, first[0..]);
    const b = renderContractPlan(value, second[0..]);
    try std.testing.expect(a.ok and b.ok);
    try std.testing.expectEqualStrings(a.bytes, b.bytes);
    try std.testing.expect(std.mem.indexOf(u8, a.bytes, "BUILD_PROFILE=R4X_C_App_Console\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, a.bytes, "OPTIMIZE=size\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, a.bytes, "artifact") == null);
}

test "subsystem role normalizes identity and guest format contract into plan metadata" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const text =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4X
        \\NAME=QBASIC
        \\VERSION=0.66.0
        \\LANGUAGE=Zig
        \\SOURCE=src/main.zig
        \\ENTRY_MODE=app
        \\APP_CLASS=gui
        \\MODULE_ROLE=SubSystem
        \\SUBSYSTEM_ID=Basic.QBasic
        \\SUBSYSTEM_DISPLAY_NAME=QBasic Runtime
        \\GUEST_FORMAT=Basic.QBasic-Source
        \\GUEST_EXTENSION=BASIC.QBASIC-SOURCE:.BAS
        \\GUEST_FEATURE=basic.qbasic-source:Text.Source
        \\GUEST_FEATURE=basic.qbasic-source:Probe.Text-Token-V1.7072696E74
        \\TARGET=/R4OS/SUBSYSTEMS/basic.qbasic/QBASIC.R4X
        \\IMAGE_SCOPE=test
        \\IMPORT=R4SYS:Query:1
        \\IMPORT=R4DESK:Query:1
        \\IMPORT=R4DRAW:Query:1
    ;
    const value = try parse(allocator, "QBASIC/module.R4MF", text);
    try std.testing.expectEqual(ModuleRole.subsystem, value.module_role.?);
    try std.testing.expectEqualStrings("basic.qbasic", value.subsystem_id.?);
    try std.testing.expectEqualStrings("QBasic Runtime", value.subsystem_display_name.?);
    try std.testing.expectEqualStrings("basic.qbasic-source", value.guest_formats[0]);
    try std.testing.expectEqualStrings(".bas", value.guest_extensions[0].extension);
    try std.testing.expectEqualStrings("text.source", value.guest_features[0].feature);

    const plan = try derivePlan(allocator, value);
    try std.testing.expect(containsString(plan.metadata, "module.role=subsystem"));
    try std.testing.expect(containsString(plan.metadata, "subsystem.id=basic.qbasic"));
    try std.testing.expect(containsString(plan.metadata, "subsystem.display_name=QBasic Runtime"));
    try std.testing.expect(containsString(plan.metadata, "subsystem.format=basic.qbasic-source"));
    try std.testing.expect(containsString(plan.metadata, "subsystem.extension=basic.qbasic-source:.bas"));
    try std.testing.expect(containsString(plan.metadata, "subsystem.feature=basic.qbasic-source:text.source"));

    var rendered: [2048]u8 = undefined;
    const contract_plan = renderContractPlan(value, rendered[0..]);
    try std.testing.expect(contract_plan.ok);
    try std.testing.expect(std.mem.indexOf(u8, contract_plan.bytes, "MODULE_ROLE=subsystem\nSUBSYSTEM_ID=basic.qbasic\nSUBSYSTEM_DISPLAY_NAME=QBasic Runtime\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, contract_plan.bytes, "GUEST_EXTENSION=basic.qbasic-source:.bas\n") != null);
}

test "subsystem role rejects incomplete forbidden and colliding contract fields" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const base =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4X
        \\NAME=SUBBAD
        \\VERSION=0.66.0
        \\LANGUAGE=Zig
        \\SOURCE=src/main.zig
        \\ENTRY_MODE=app
        \\APP_CLASS=gui
        \\MODULE_ROLE=subsystem
        \\SUBSYSTEM_DISPLAY_NAME=Broken subsystem
        \\GUEST_FORMAT=basic.source
        \\TARGET=/R4OS/SUBSYSTEMS/basic/SubBad.R4X
        \\IMAGE_SCOPE=none
        \\IMPORT=R4SYS:Query:1
        \\IMPORT=R4DESK:Query:1
        \\IMPORT=R4DRAW:Query:1
    ;
    try std.testing.expectError(error.MissingSubsystemId, parse(allocator, "SubBad/module.R4MF", base));

    const fields_without_role =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4X
        \\NAME=NORMAL
        \\VERSION=0.66.0
        \\LANGUAGE=Zig
        \\SOURCE=src/main.zig
        \\ENTRY_MODE=app
        \\APP_CLASS=console
        \\SUBSYSTEM_ID=basic
        \\TARGET=/R4OS/SOFTWARE/TERMINAL/NORMAL.R4X
        \\IMAGE_SCOPE=none
        \\IMPORT=R4SYS:Query:1
    ;
    try std.testing.expectError(error.SubsystemFieldsWithoutRole, parse(allocator, "Normal/module.R4MF", fields_without_role));

    const driver_role =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4D
        \\NAME=ROLEBAD
        \\VERSION=0.66.0
        \\LANGUAGE=Zig
        \\SOURCE=src/main.zig
        \\MODULE_ROLE=subsystem
        \\SUBSYSTEM_ID=basic
        \\GUEST_FORMAT=basic.source
        \\TARGET=/R4OS/DRIVERS/ROLEBAD.R4D
        \\IMAGE_SCOPE=none
    ;
    try std.testing.expectError(error.ModuleRoleForbiddenForKind, parse(allocator, "RoleBad/module.R4MF", driver_role));

    const complete = try std.mem.replaceOwned(u8, allocator, base, "MODULE_ROLE=subsystem", "MODULE_ROLE=subsystem\nSUBSYSTEM_ID=basic");
    const missing_display = try std.mem.replaceOwned(u8, allocator, complete, "SUBSYSTEM_DISPLAY_NAME=Broken subsystem\n", "");
    try std.testing.expectError(error.MissingSubsystemDisplayName, parse(allocator, "SubBad/module.R4MF", missing_display));
    const invalid_display = try std.mem.replaceOwned(u8, allocator, complete, "Broken subsystem", "Broken\"subsystem");
    try std.testing.expectError(error.InvalidSubsystemDisplayName, parse(allocator, "SubBad/module.R4MF", invalid_display));
    const invalid_probe = try std.mem.replaceOwned(u8, allocator, complete, "GUEST_FORMAT=basic.source", "GUEST_FORMAT=basic.source\nGUEST_FEATURE=basic.source:probe.magic-v1.zz.4d5a");
    try std.testing.expectError(error.InvalidGuestFeature, parse(allocator, "SubBad/module.R4MF", invalid_probe));
    const duplicate = try std.mem.replaceOwned(u8, allocator, complete, "GUEST_FORMAT=basic.source", "GUEST_FORMAT=basic.source\nGUEST_FORMAT=BASIC.SOURCE");
    try std.testing.expectError(error.DuplicateGuestFormat, parse(allocator, "SubBad/module.R4MF", duplicate));

    const wrong_target = try std.mem.replaceOwned(u8, allocator, complete, "/R4OS/SUBSYSTEMS/basic/SubBad.R4X", "/R4OS/SOFTWARE/SUBBAD.R4X");
    try std.testing.expectError(error.InvalidSubsystemTarget, parse(allocator, "SubBad/module.R4MF", wrong_target));
}

test "malformed V2 never falls back to V1" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const text =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4X
        \\NAME=BROKEN
        \\VERSION=0.1.0
        \\SOURCE_PROJECT=Code/System/Software/Broken
    ;
    try std.testing.expectError(error.UnknownV2Field, parse(allocator, "Broken/module.R4MF", text));
}

test "C V2 accepts multiple ordered sources without inventing imports" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const text =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4X
        \\NAME=CHELLO
        \\VERSION=0.1.0
        \\LANGUAGE=C
        \\SOURCE=src/main.c
        \\SOURCE=src/helper.c
        \\ENTRY_MODE=app
        \\APP_CLASS=console
        \\TARGET=/R4OS/SOFTWARE/TERMINAL/CHELLO.R4X
        \\IMAGE_SCOPE=none
        \\IMPORT=R4SYS:Query:1
        \\IMPORT=R4NET:Query:1
    ;
    const value = try parse(allocator, "Code/System/Software/CHello/module.R4MF", text);
    const plan = try derivePlan(allocator, value);
    try std.testing.expectEqualStrings("R4X_C_App_Console", plan.build_profile);
    try std.testing.expectEqual(@as(usize, 2), value.sources.len);
    try std.testing.expectEqualStrings("R4SYS:Query:1", plan.imports[0]);
    try std.testing.expectEqualStrings("R4NET:Query:1", plan.imports[1]);
}

test "runtime R4L accepts one Zig root followed by library-owned C sources" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const text =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4L
        \\NAME=MIXEDLIB
        \\VERSION=0.1.0
        \\LANGUAGE=Zig
        \\SOURCE=Source/main.zig
        \\SOURCE=ThirdParty/codec.c
        \\NATIVE_ARCHIVE=CODEC_NATIVE
        \\C_INCLUDE=ThirdParty/include
        \\C_DEFINE=CODEC_CONFIG=<codec_config.h>
        \\C_FLAG=-fno-builtin
        \\TARGET=/R4OS/LIBS/MIXEDLIB.R4L
        \\IMAGE_SCOPE=test
        \\OPTIMIZE=speed
        \\EXPORT=API_V1:mixedlib_api_v1:1
        \\EXPORT=Query:mixedlib_query:1
        \\CONTRACT=Contract/LibraryContract.json
        \\CONTRACT_BASELINE=Contract/LibraryContract.baseline.json
        \\IMPLEMENTATION_ZIG=Contract/Generated/implementation_abi.zig
        \\BINDING_ZIG=Bindings/Zig/mixedlib.zig
        \\BINDING_C=Bindings/C/mixedlib.h
        \\CONFORMANCE_ZIG=Tests/Generated/contract_conformance.zig
        \\CONFORMANCE_C=Tests/Generated/contract_conformance.c
        \\API_REFERENCE=Docs/API.md
    ;
    const value = try parse(allocator, "MixedLib/module.R4MF", text);
    try std.testing.expectEqual(@as(usize, 2), value.sources.len);
    try std.testing.expectEqualStrings("Source/main.zig", value.sources[0]);
    try std.testing.expectEqualStrings("ThirdParty/codec.c", value.sources[1]);
    try std.testing.expectEqualStrings("CODEC_NATIVE", value.native_archives[0]);
    const duplicate_archive = try std.fmt.allocPrint(allocator, "{s}\nNATIVE_ARCHIVE=codec_native\n", .{text});
    try std.testing.expectError(error.DuplicateNativeArchive, parse(allocator, "MixedLib/module.R4MF", duplicate_archive));
    const archive_path = try std.mem.replaceOwned(u8, allocator, text, "NATIVE_ARCHIVE=CODEC_NATIVE", "NATIVE_ARCHIVE=../codec.a");
    try std.testing.expectError(error.InvalidName, parse(allocator, "MixedLib/module.R4MF", archive_path));
    try std.testing.expectEqualStrings("ThirdParty/include", value.c_includes[0]);
    try std.testing.expectEqualStrings("CODEC_CONFIG", value.c_defines[0].name);
    try std.testing.expectEqualStrings("<codec_config.h>", value.c_defines[0].value);
    try std.testing.expectEqualStrings("-fno-builtin", value.c_flags[0]);
    try std.testing.expectEqual(Optimization.speed, value.optimization.?);

    const wrong_root = std.mem.replaceOwned(u8, allocator, text, "Source/main.zig", "Source/main.c") catch unreachable;
    defer allocator.free(wrong_root);
    try std.testing.expectError(error.SourceLanguageMismatch, parse(allocator, "MixedLib/module.R4MF", wrong_root));
    const wrong_companion = std.mem.replaceOwned(u8, allocator, text, "ThirdParty/codec.c", "ThirdParty/codec.zig") catch unreachable;
    defer allocator.free(wrong_companion);
    try std.testing.expectError(error.SourceLanguageMismatch, parse(allocator, "MixedLib/module.R4MF", wrong_companion));
    const bad_flag = std.mem.replaceOwned(u8, allocator, text, "C_FLAG=-fno-builtin", "C_FLAG=fno-builtin") catch unreachable;
    defer allocator.free(bad_flag);
    try std.testing.expectError(error.InvalidCFlag, parse(allocator, "MixedLib/module.R4MF", bad_flag));
    const no_c_source = std.mem.replaceOwned(u8, allocator, text, "SOURCE=ThirdParty/codec.c", "") catch unreachable;
    defer allocator.free(no_c_source);
    try std.testing.expectError(error.CConfigurationWithoutCSource, parse(allocator, "MixedLib/module.R4MF", no_c_source));
    const headers_only = try std.mem.replaceOwned(u8, allocator, no_c_source, "C_FLAG=-fno-builtin", "");
    const native_header_module = try parse(allocator, "MixedLib/module.R4MF", headers_only);
    try std.testing.expectEqual(@as(usize, 1), native_header_module.sources.len);
    try std.testing.expectEqualStrings("ThirdParty/include", native_header_module.c_includes[0]);
    try std.testing.expectEqualStrings("CODEC_CONFIG", native_header_module.c_defines[0].name);
    const no_archive = try std.mem.replaceOwned(u8, allocator, headers_only, "NATIVE_ARCHIVE=CODEC_NATIVE", "");
    const zig_header_module = try parse(allocator, "MixedLib/module.R4MF", no_archive);
    try std.testing.expectEqual(@as(usize, 0), zig_header_module.native_archives.len);
    try std.testing.expectEqualStrings("ThirdParty/include", zig_header_module.c_includes[0]);
}

test "R4D accepts ordered C companions without changing driver identity or entry contracts" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const text =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4D
        \\NAME=MIXEDDRIVER
        \\VERSION=0.1.0
        \\LANGUAGE=Zig
        \\SOURCE=src/main.zig
        \\SOURCE=src/native.c
        \\SOURCE=src/helpers.c
        \\C_INCLUDE=ThirdParty/include
        \\C_DEFINE=NATIVE_WIDTH=64
        \\C_FLAG=-mno-sse
        \\TARGET=/R4OS/DRIVERS/MIXEDDRIVER.R4D
        \\IMAGE_SCOPE=none
        \\IMPORT=R4DEV:Query:1
        \\META=r4d.name=MIXEDDRIVER
        \\META=r4d.type=display
    ;
    const value = try parse(allocator, "MixedDriver/module.R4MF", text);
    const archived = try std.fmt.allocPrint(allocator, "{s}\nNATIVE_ARCHIVE=AMD_ADDR\n", .{text});
    const archived_driver = try parse(allocator, "MixedDriver/module.R4MF", archived);
    try std.testing.expectEqualStrings("AMD_ADDR", archived_driver.native_archives[0]);
    const duplicate_archive = try std.fmt.allocPrint(allocator, "{s}\nNATIVE_ARCHIVE=amd_addr\n", .{archived});
    try std.testing.expectError(error.DuplicateNativeArchive, parse(allocator, "MixedDriver/module.R4MF", duplicate_archive));
    try std.testing.expectEqual(Kind.r4d, value.kind);
    try std.testing.expectEqualStrings("src/main.zig", value.sources[0]);
    try std.testing.expectEqualStrings("src/native.c", value.sources[1]);
    try std.testing.expectEqualStrings("src/helpers.c", value.sources[2]);
    try std.testing.expect(value.entry_mode == null and value.app_class == null);
    try std.testing.expectEqualStrings("R4DEV:Query:1", value.imports[0]);
    try std.testing.expectEqualStrings("ThirdParty/include", value.c_includes[0]);
    try std.testing.expectEqualStrings("64", value.c_defines[0].value);
    try std.testing.expectEqualStrings("-mno-sse", value.c_flags[0]);
    const without_native = try std.mem.replaceOwned(u8, allocator, text, "SOURCE=src/native.c", "");
    const without_helpers = try std.mem.replaceOwned(u8, allocator, without_native, "SOURCE=src/helpers.c", "");
    try std.testing.expectError(error.CConfigurationWithoutCSource, parse(allocator, "HeaderDriver/module.R4MF", without_helpers));
    const only_headers = try std.mem.replaceOwned(u8, allocator, without_helpers, "C_FLAG=-mno-sse", "");
    const header_driver = try parse(allocator, "HeaderDriver/module.R4MF", only_headers);
    try std.testing.expectEqual(@as(usize, 1), header_driver.sources.len);
    try std.testing.expectEqualStrings("ThirdParty/include", header_driver.c_includes[0]);
    inline for (.{ .{ "C", "c" }, .{ "Rust", "rs" } }) |language| {
        const own_language = try std.mem.replaceOwned(u8, allocator, text, "LANGUAGE=Zig", "LANGUAGE=" ++ language[0]);
        const own_root = try std.mem.replaceOwned(u8, allocator, own_language, "src/main.zig", "src/main." ++ language[1]);
        const own = try parse(allocator, "OwnDriver/module.R4MF", own_root);
        try std.testing.expectEqual(Kind.r4d, own.kind);
        try std.testing.expectEqualStrings("src/main." ++ language[1], own.sources[0]);
        try std.testing.expectEqualStrings("src/native.c", own.sources[1]);
        try std.testing.expect(own.entry_mode == null and own.app_class == null);
        try std.testing.expect(capabilities.query(.{ .language = language[0], .kind = "R4D" }).supported);
        try std.testing.expect(!capabilities.query(.{ .language = language[0], .kind = "R4D", .execution = .native_r4os }).supported);
    }
    // The protocol role uses its original four-entry ABI, independent of R4X.
    inline for (.{ .{ "C", "c" }, .{ "Rust", "rs" } }) |language| {
        const protocol_kind = try std.mem.replaceOwned(u8, allocator, text, "KIND=R4D", "KIND=R4P");
        const protocol_target = try std.mem.replaceOwned(u8, allocator, protocol_kind, "/DRIVERS/MIXEDDRIVER.R4D", "/PROTOCOLS/MIXEDDRIVER.R4P");
        const protocol_language = try std.mem.replaceOwned(u8, allocator, protocol_target, "LANGUAGE=Zig", "LANGUAGE=" ++ language[0]);
        const protocol_root = try std.mem.replaceOwned(u8, allocator, protocol_language, "src/main.zig", "src/main." ++ language[1]);
        const own = try parse(allocator, "OwnProtocol/module.R4MF", protocol_root);
        try std.testing.expectEqual(Kind.r4p, own.kind);
        try std.testing.expectEqualStrings("src/main." ++ language[1], own.sources[0]);
        try std.testing.expectEqualStrings("src/native.c", own.sources[1]);
        try std.testing.expect(own.entry_mode == null and own.app_class == null);
        try std.testing.expect(capabilities.query(.{ .language = language[0], .kind = "R4P" }).supported);
        try std.testing.expect(!capabilities.query(.{ .language = language[0], .kind = "R4P", .execution = .native_r4os }).supported);
    }
    const wrong = try std.mem.replaceOwned(u8, allocator, text, "src/helpers.c", "src/second.zig");
    try std.testing.expectError(error.SourceLanguageMismatch, parse(allocator, "MixedDriver/module.R4MF", wrong));
    const escaped = try std.mem.replaceOwned(u8, allocator, text, "src/helpers.c", "../helpers.c");
    try std.testing.expectError(error.SourcePathEscape, parse(allocator, "MixedDriver/module.R4MF", escaped));
    const duplicate = try std.mem.replaceOwned(u8, allocator, text, "src/helpers.c", "src/native.c");
    try std.testing.expectError(error.DuplicateSource, parse(allocator, "MixedDriver/module.R4MF", duplicate));
    for ([_][]const u8{ "R4X", "R4P" }) |kind| {
        const other = try std.mem.replaceOwned(u8, allocator, text, "KIND=R4D", try std.fmt.allocPrint(allocator, "KIND={s}", .{kind}));
        try std.testing.expectError(error.ZigRequiresSingleSource, parse(allocator, "MixedDriver/module.R4MF", other));
    }
}

test "R4X accepts named Runtime-R4L imports without a profile group bit" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const text =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4X
        \\NAME=NAMEDR4L
        \\VERSION=0.1.0
        \\LANGUAGE=Zig
        \\SOURCE=src/main.zig
        \\ENTRY_MODE=lowlevel
        \\APP_CLASS=console
        \\TARGET=/R4OS/SOFTWARE/NAMEDR4L.R4X
        \\IMAGE_SCOPE=test
        \\IMPORT=R4SYS:Query:1
        \\IMPORT=ACME-CODEC:API_V1:2
    ;
    const value = try parse(allocator, "Named/module.R4MF", text);
    try std.testing.expectEqual(@as(usize, 2), value.imports.len);
    try std.testing.expectEqualStrings("ACME-CODEC:API_V1:2", value.imports[1]);

    const optional_text = try std.mem.replaceOwned(u8, allocator, text, "ACME-CODEC:API_V1:2", "ACME-CODEC:API_V1:2:1");
    const optional = try parse(allocator, "Named/module.R4MF", optional_text);
    try std.testing.expect(importIsOptional(optional.imports[1]) and !importIsOptional(optional.imports[0]));
    for ([_][]const u8{ "ACME-CODEC:API_V1:2:2", "ACME-CODEC:API_V1:2:1:0", "ACME-CODEC:API_V1:2:" }) |bad| {
        const invalid = try std.mem.replaceOwned(u8, allocator, text, "ACME-CODEC:API_V1:2", bad);
        try std.testing.expectError(error.InvalidImport, parse(allocator, "Named/module.R4MF", invalid));
    }
    const optional_platform = try std.mem.replaceOwned(u8, allocator, text, "R4SYS:Query:1", "R4SYS:Query:1:1");
    try std.testing.expectError(error.InvalidImport, parse(allocator, "Named/module.R4MF", optional_platform));

    const invalid_platform = std.mem.replaceOwned(u8, allocator, text, "R4SYS:Query:1", "R4SYS:API_V1:1") catch unreachable;
    defer allocator.free(invalid_platform);
    try std.testing.expectError(error.InvalidImport, parse(allocator, "Named/module.R4MF", invalid_platform));
}

test "V2 keeps package grouping out of the build plan and validates Zig modules" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const text =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4X
        \\NAME=SHAREDAPP
        \\VERSION=0.1.0
        \\LANGUAGE=Zig
        \\SOURCE=src/main.zig
        \\ENTRY_MODE=lowlevel
        \\APP_CLASS=console
        \\TARGET=/R4OS/SOFTWARE/SHAREDAPP.R4X
        \\IMAGE_SCOPE=none
        \\PACKAGE=TOOLS
        \\ZIG_MODULE=compiler_core:../../Shared/compiler_core.zig
        \\IMPORT=R4SYS:Query:1
    ;
    const value = try parse(allocator, "Code/System/Software/Tools/Modules/App/module.R4MF", text);
    const plan = try derivePlan(allocator, value);
    try std.testing.expectEqualStrings("TOOLS", value.package.?);
    try std.testing.expectEqualStrings("compiler_core:../../Shared/compiler_core.zig", value.zig_modules[0]);
    try std.testing.expectEqualStrings("R4X_Zig_LowLevel_Console", plan.build_profile);

    const duplicate = text ++ "\nZIG_MODULE=compiler_core:../../Shared/other.zig\n";
    try std.testing.expectError(error.DuplicateZigModuleName, parse(allocator, "App/module.R4MF", duplicate));
    const c_language = std.mem.replaceOwned(u8, allocator, text, "LANGUAGE=Zig", "LANGUAGE=C") catch unreachable;
    defer allocator.free(c_language);
    const c_module = std.mem.replaceOwned(u8, allocator, c_language, "src/main.zig", "src/main.c") catch unreachable;
    defer allocator.free(c_module);
    try std.testing.expectError(error.CForbidsZigModule, parse(allocator, "App/module.R4MF", c_module));
    const driver_text =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4D
        \\NAME=DISPLAYTEST
        \\VERSION=0.1.0
        \\LANGUAGE=Zig
        \\SOURCE=src/main.zig
        \\TARGET=/R4OS/DRIVERS/DISPLAYTEST.R4D
        \\IMAGE_SCOPE=test
        \\ZIG_MODULE=edid:../../Libraries/R4GFX/Display/edid.zig
        \\META=r4d.name=DisplayTest
        \\META=r4d.type=display
    ;
    const driver = try parse(allocator, "Driver/module.R4MF", driver_text);
    try std.testing.expectEqualStrings("edid:../../Libraries/R4GFX/Display/edid.zig", driver.zig_modules[0]);
    try std.testing.expectError(error.NonR4XEntryModeForbidden, parse(allocator, "Driver/module.R4MF", driver_text ++ "\nENTRY_MODE=app\n"));
}

test "V2 rejects duplicate fields path escape invalid target scope and missing profile imports" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const base =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4X
        \\NAME=HELLO
        \\VERSION=0.1.0
        \\LANGUAGE=Zig
        \\SOURCE=src/main.zig
        \\ENTRY_MODE=app
        \\APP_CLASS=console
        \\TARGET=/R4OS/SOFTWARE/HELLO.R4X
        \\IMAGE_SCOPE=full
        \\IMPORT=R4SYS:Query:1
    ;
    const duplicate = base ++ "\nNAME=SECOND\n";
    try std.testing.expectError(error.DuplicateField, parse(allocator, "Hello/module.R4MF", duplicate));
    const escape = std.mem.replaceOwned(u8, allocator, base, "src/main.zig", "../main.zig") catch unreachable;
    defer allocator.free(escape);
    try std.testing.expectError(error.SourcePathEscape, parse(allocator, "Hello/module.R4MF", escape));
    const target = std.mem.replaceOwned(u8, allocator, base, "/R4OS/SOFTWARE/HELLO.R4X", "../HELLO.R4X") catch unreachable;
    defer allocator.free(target);
    try std.testing.expectError(error.InvalidTarget, parse(allocator, "Hello/module.R4MF", target));
    const scope = std.mem.replaceOwned(u8, allocator, base, "IMAGE_SCOPE=full", "IMAGE_SCOPE=sometimes") catch unreachable;
    defer allocator.free(scope);
    try std.testing.expectError(error.InvalidImageScope, parse(allocator, "Hello/module.R4MF", scope));
    const optimization = base ++ "\nOPTIMIZE=debug\n";
    try std.testing.expectError(error.InvalidOptimization, parse(allocator, "Hello/module.R4MF", optimization));
    const desktop = std.mem.replaceOwned(u8, allocator, base, "APP_CLASS=console", "APP_CLASS=gui") catch unreachable;
    defer allocator.free(desktop);
    try std.testing.expectError(error.MissingProfileImport, parse(allocator, "Hello/module.R4MF", desktop));
}

test "V1 is rejected and non-R4X uses the current common schema" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const v1 =
        \\R4OS_MODULE_MANIFEST=1
        \\KIND=R4X
        \\NAME=HELLO
        \\VERSION=0.1.0
        \\SOURCE_PROJECT=Code\\System\\Software\\Hello
        \\ARTIFACT=Code\\System\\Software\\Hello\\zig-out\\HELLO.R4X
        \\TARGET=/R4OS/SOFTWARE/HELLO.R4X
        \\BUILD_PROFILE=R4X_C_App_Console
        \\IMPORT=R4NET:Query:1
        \\EXPORT=R4XStart:R4XStart:1
        \\CONTRACT=R4M0:1
        \\CONTRACT=R4XStart:1
        \\META=app.class=console
    ;
    try std.testing.expectError(error.UnsupportedManifestVersion, parse(allocator, "Code/System/Software/Hello/module.R4MF", v1));

    const driver =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4D
        \\NAME=EXAMPLE
        \\VERSION=0.1.0
        \\LANGUAGE=Zig
        \\SOURCE=src/main.zig
        \\TARGET=/R4OS/DRIVERS/EXAMPLE.R4D
        \\IMAGE_SCOPE=slim
        \\IMPORT=R4DEV:Query:1
        \\META=r4d.type=example
    ;
    const current = try parse(allocator, "Code/System/Driver/Example/module.R4MF", driver);
    try std.testing.expectEqual(Kind.r4d, current.kind);
    try std.testing.expect(current.entry_mode == null and current.app_class == null);
    // Seit 0.61.6 traegt AUCH ein Nicht-R4X seinen Imagescope selbst, statt
    // ihn ueber META=image.shipped oder eine Liste im Buildscript zu regeln.
    try std.testing.expectEqual(ImageScope.slim, current.image_scope.?);
    try std.testing.expectEqual(Optimization.size, current.optimization.?);
    const forbidden = driver ++ "\nAPP_CLASS=service\n";
    try std.testing.expectError(error.NonR4XAppClassForbidden, parse(allocator, "Code/System/Driver/Example/module.R4MF", forbidden));
    const optimized_driver = driver ++ "\nOPTIMIZE=speed\n";
    const optimized = try parse(allocator, "Code/System/Driver/Example/module.R4MF", optimized_driver);
    try std.testing.expectEqual(Optimization.speed, optimized.optimization.?);

    const protocol = try std.mem.replaceOwned(u8, allocator, optimized_driver, "KIND=R4D", "KIND=R4P");
    defer allocator.free(protocol);
    const protocol_target = try std.mem.replaceOwned(u8, allocator, protocol, "/R4OS/DRIVERS/EXAMPLE.R4D", "/R4OS/PROTOCOLS/EXAMPLE.R4P");
    defer allocator.free(protocol_target);
    const optimized_protocol = try parse(allocator, "Code/System/Protocol/Example/module.R4MF", protocol_target);
    try std.testing.expectEqual(Optimization.speed, optimized_protocol.optimization.?);
}

test "image scope is mandatory for every kind and supersedes image.shipped" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const kopf =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4D
        \\NAME=EXAMPLE
        \\VERSION=0.1.0
        \\LANGUAGE=Zig
        \\SOURCE=src/main.zig
        \\TARGET=/R4OS/DRIVERS/EXAMPLE.R4D
        \\IMPORT=R4DEV:Query:1
    ;
    const pfad = "Code/System/Driver/Example/module.R4MF";

    // Ohne Scope kann der Imageplan nicht entscheiden - das ist ein Fehler,
    // keine stille Annahme.
    try std.testing.expectError(error.MissingImageScope, parse(allocator, pfad, kopf));

    const gut = try parse(allocator, pfad, kopf ++ "\nIMAGE_SCOPE=none\n");
    try std.testing.expectEqual(ImageScope.none, gut.image_scope.?);

    try std.testing.expectError(error.InvalidImageScope, parse(allocator, pfad, kopf ++ "\nIMAGE_SCOPE=normal\n"));
    try std.testing.expectError(error.InvalidImageScope, parse(allocator, pfad, kopf ++ "\nIMAGE_SCOPE=both\n"));

    // Zwei Quellen fuer dieselbe Aussage waeren genau die Doppelung, die
    // diese Version abschafft.
    const doppelt = kopf ++ "\nIMAGE_SCOPE=slim\nMETA=image.shipped=yes\n";
    try std.testing.expectError(error.ImageShippedSupersededByScope, parse(allocator, pfad, doppelt));
}

test "resources parse in order, validate names and paths, and reject R4L" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const kopf =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4X
        \\NAME=RSRC
        \\VERSION=0.1.0
        \\LANGUAGE=Zig
        \\SOURCE=src/main.zig
        \\ENTRY_MODE=app
        \\APP_CLASS=console
        \\TARGET=/R4OS/SOFTWARE/RSRC.R4X
        \\IMAGE_SCOPE=none
        \\IMPORT=R4SYS:Query:1
    ;
    const pfad = "Code/System/Software/Rsrc/module.R4MF";

    const voll = kopf ++
        "\nICON=Assets/Desktop.ico" ++
        "\nICON=Assets/Second.ico" ++
        "\nHELP=Assets/Help.txt" ++
        "\nRESOURCE=BACK.ICO:Assets/Back.ico" ++
        "\nRESOURCE=DATA.BIN:Assets/Data.bin\n";
    const manifest = try parse(allocator, pfad, voll);
    try std.testing.expectEqual(@as(usize, 2), manifest.icons.len);
    try std.testing.expectEqualStrings("Assets/Desktop.ico", manifest.icons[0]);
    try std.testing.expectEqualStrings("Assets/Help.txt", manifest.help.?);
    try std.testing.expectEqual(@as(usize, 2), manifest.resources.len);
    try std.testing.expectEqualStrings("BACK.ICO", manifest.resources[0].name);
    try std.testing.expectEqualStrings("Assets/Back.ico", manifest.resources[0].path);

    // Der Plan traegt die Zeilen in Vertragsreihenfolge weiter - R4BUILD im
    // Gast liest genau diesen Block.
    var plan_buf: [2048]u8 = undefined;
    const plan = renderContractPlan(manifest, plan_buf[0..]);
    try std.testing.expect(plan.ok);
    try std.testing.expect(std.mem.indexOf(u8, plan.bytes, "ICON=Assets/Desktop.ico\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, plan.bytes, "HELP=Assets/Help.txt\n") != null);
    try std.testing.expect(std.mem.indexOf(u8, plan.bytes, "RESOURCE=BACK.ICO:Assets/Back.ico\n") != null);

    // HELP ist einmalig.
    const doppel_help = kopf ++ "\nHELP=Assets/A.txt\nHELP=Assets/B.txt\n";
    try std.testing.expectError(error.DuplicateField, parse(allocator, pfad, doppel_help));

    // Namen sind case-insensitive eindeutig.
    const doppel_name = kopf ++ "\nRESOURCE=BACK.ICO:Assets/A.bin\nRESOURCE=back.ico:Assets/B.bin\n";
    try std.testing.expectError(error.DuplicateResourceName, parse(allocator, pfad, doppel_name));

    // Pfade bleiben projektintern (Standalone-Baubarkeit).
    const ausbruch = kopf ++ "\nICON=../Shared/Desktop.ico\n";
    try std.testing.expectError(error.ResourcePathEscape, parse(allocator, pfad, ausbruch));

    // Name mit Doppelpunkt ist unmoeglich, mit Pfadtrenner verboten.
    const schlechter_name = kopf ++ "\nRESOURCE=SUB/DIR.BIN:Assets/D.bin\n";
    try std.testing.expectError(error.InvalidResourceName, parse(allocator, pfad, schlechter_name));

    // R4L bettet nie ein - deklarierte Ressourcen waeren eine stille Luege.
    const r4l =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4L
        \\NAME=EXAMPLE
        \\VERSION=0.1.0
        \\LANGUAGE=Zig
        \\SOURCE=src/main.zig
        \\TARGET=/R4OS/LIBS/EXAMPLE.R4L
        \\IMAGE_SCOPE=none
        \\HELP=Assets/Help.txt
    ;
    try std.testing.expectError(error.R4LResourcesForbidden, parse(allocator, "Code/Libs/Example/module.R4MF", r4l));
}

test "runtime R4L owns symbolic exports contract and language bindings" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const base =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4L
        \\NAME=VENDORLIB
        \\VERSION=0.1.0
        \\LANGUAGE=Zig
        \\SOURCE=Source/main.zig
        \\TARGET=/R4OS/LIBS/VENDORLIB.R4L
        \\IMAGE_SCOPE=none
        \\EXPORT=API_V1:acme_api_v1:2
        \\EXPORT=Query:acme_query:1
        \\CONTRACT=Contract/LibraryContract.json
        \\CONTRACT_BASELINE=Contract/LibraryContract.baseline.json
        \\IMPLEMENTATION_ZIG=Contract/Generated/implementation_abi.zig
        \\BINDING_ZIG=Bindings/Zig/acmecalc.zig
        \\BINDING_C=Bindings/C/acmecalc.h
        \\CONFORMANCE_ZIG=Tests/Generated/contract_conformance.zig
        \\CONFORMANCE_C=Tests/Generated/contract_conformance.c
        \\API_REFERENCE=Docs/API.md
    ;
    const no_zig_implementation = try std.mem.replaceOwned(u8, allocator, base, "IMPLEMENTATION_ZIG=Contract/Generated/implementation_abi.zig", "");
    const c_language = try std.mem.replaceOwned(u8, allocator, no_zig_implementation, "LANGUAGE=Zig", "LANGUAGE=C");
    const c_provider = try std.mem.replaceOwned(u8, allocator, c_language, "Source/main.zig", "Source/main.c");
    try std.testing.expectEqual(Language.c, (try parse(allocator, "Vendor/C/module.R4MF", c_provider)).language.?);
    const rust_language = try std.mem.replaceOwned(u8, allocator, no_zig_implementation, "LANGUAGE=Zig", "LANGUAGE=Rust");
    const rust_provider = try std.mem.replaceOwned(u8, allocator, rust_language, "Source/main.zig", "Source/main.rs");
    try std.testing.expectError(error.MissingR4LRustBinding, parse(allocator, "Vendor/Rust/module.R4MF", rust_provider));
    const rust_complete = try std.fmt.allocPrint(allocator, "{s}\nBINDING_RUST=Bindings/Rust/lib.rs\n", .{rust_provider});
    try std.testing.expectEqual(Language.rust, (try parse(allocator, "Vendor/Rust/module.R4MF", rust_complete)).language.?);
    try std.testing.expectError(error.MissingR4LImplementationZig, parse(allocator, "Vendor/Zig/module.R4MF", no_zig_implementation));
    const parsed = try parse(allocator, "Vendor/Library/module.R4MF", base);
    try std.testing.expectEqual(Kind.r4l, parsed.kind);
    try std.testing.expectEqual(@as(usize, 2), parsed.exports.len);
    try std.testing.expectEqualStrings("API_V1", parsed.exports[0].name);
    try std.testing.expectEqualStrings("acme_api_v1", parsed.exports[0].symbol);
    try std.testing.expectEqual(@as(u16, 2), parsed.exports[0].revision);
    try std.testing.expectEqualStrings("Bindings/C/acmecalc.h", parsed.binding_c.?);
    const compiled = try parse(allocator, "Vendor/Library/module.R4MF", base ++ "\nZIG_MODULE=backend:../Backend/Bindings/Zig/backend.zig\n");
    try std.testing.expectEqualStrings("backend:../Backend/Bindings/Zig/backend.zig", compiled.zig_modules[0]);
    try std.testing.expectError(error.ReservedZigModuleName, parse(allocator, "Vendor/Library/module.R4MF", base ++ "\nZIG_MODULE=r4l_contract:Other.zig\n"));

    const duplicate = base ++ "\nEXPORT=api_v1:another_symbol:3\n";
    try std.testing.expectError(error.DuplicateExportName, parse(allocator, "Vendor/Library/module.R4MF", duplicate));

    const missing_binding = std.mem.replaceOwned(u8, allocator, base, "BINDING_C=Bindings/C/acmecalc.h", "") catch unreachable;
    try std.testing.expectError(error.MissingR4LCBinding, parse(allocator, "Vendor/Library/module.R4MF", missing_binding));

    const escaped = std.mem.replaceOwned(u8, allocator, base, "Contract/LibraryContract.json", "../Contract.json") catch unreachable;
    try std.testing.expectError(error.R4LContractPathEscape, parse(allocator, "Vendor/Library/module.R4MF", escaped));

    const missing_query = std.mem.replaceOwned(u8, allocator, base, "EXPORT=Query:acme_query:1", "") catch unreachable;
    try std.testing.expectError(error.MissingR4LQueryExport, parse(allocator, "Vendor/Library/module.R4MF", missing_query));

    const bad_query = std.mem.replaceOwned(u8, allocator, base, "EXPORT=Query:acme_query:1", "EXPORT=Query:acme_query:2") catch unreachable;
    try std.testing.expectError(error.InvalidR4LQueryExport, parse(allocator, "Vendor/Library/module.R4MF", bad_query));

    const raw_fixture =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4L
        \\NAME=BADTAB
        \\VERSION=0.1.0
        \\LANGUAGE=Zig
        \\SOURCE=fixture.zig
        \\TARGET=/R4OS/LIBS/BADTAB.R4L
        \\IMAGE_SCOPE=test
        \\META=fixture.artifact-owner=Fixtures/build.zig
    ;
    const parsed_fixture = try parse(allocator, "Fixtures/Manifests/R4LNegative/BADTAB.R4MF", raw_fixture);
    try std.testing.expectEqual(Kind.r4l, parsed_fixture.kind);
    try std.testing.expectEqual(@as(usize, 0), parsed_fixture.exports.len);

    const reserved_name = std.mem.replaceOwned(u8, allocator, base, "NAME=VENDORLIB", "NAME=R4SYS") catch unreachable;
    try std.testing.expectError(error.ReservedPlatformApiName, parse(allocator, "Vendor/Library/module.R4MF", reserved_name));

    try std.testing.expectEqual(@as(?u32, 1), platformApiGroupId("r4sys"));
    try std.testing.expectEqual(@as(?u32, 6), platformApiGroupId("R4DEV"));
    try std.testing.expectEqual(@as(?u32, null), platformApiGroupId("R4STD"));

    const non_library_kind = std.mem.replaceOwned(u8, allocator, base, "KIND=R4L", "KIND=R4D") catch unreachable;
    const non_library = std.mem.replaceOwned(u8, allocator, non_library_kind, "/R4OS/LIBS/VENDORLIB.R4L", "/R4OS/DRIVERS/VENDORLIB.R4D") catch unreachable;
    try std.testing.expectError(error.NonR4LContractFieldForbidden, parse(allocator, "Vendor/Library/module.R4MF", non_library));
}

test "module version is mandatory and has exactly one spelling" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const kopf =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4D
        \\NAME=EXAMPLE
        \\LANGUAGE=Zig
        \\SOURCE=src/main.zig
        \\TARGET=/R4OS/DRIVERS/EXAMPLE.R4D
        \\IMAGE_SCOPE=slim
        \\IMPORT=R4DEV:Query:1
    ;
    const pfad = "Code/System/Driver/Example/module.R4MF";

    try std.testing.expectError(error.MissingModuleVersion, parse(allocator, pfad, kopf));

    const gut = try parse(allocator, pfad, kopf ++ "\nVERSION=2.13.7\n");
    try std.testing.expectEqual(@as(u16, 2), gut.module_version.major);
    try std.testing.expectEqual(@as(u16, 13), gut.module_version.minor);
    try std.testing.expectEqual(@as(u16, 7), gut.module_version.patch);
    try std.testing.expectEqualStrings("2.13.7", gut.module_version.text);

    // Null bleibt zulaessig, nur nicht als fuehrende Ziffer.
    const null_version = try parse(allocator, pfad, kopf ++ "\nVERSION=0.0.0\n");
    try std.testing.expectEqualStrings("0.0.0", null_version.module_version.text);

    // Jede dieser Schreibweisen meint dieselbe oder gar keine Version und
    // wuerde beim Serverabgleich als eigener Zeichenkettenwert auftauchen.
    const schlecht = [_][]const u8{
        "0.01.0", // fuehrende Null
        "1.0", // zu wenig Bestandteile
        "1.0.0.0", // zu viele
        "1.0.x", // keine Zahl
        "v1.0.0", // Praefix
        "1.0.", // leerer Bestandteil
        "65536.0.0", // passt nicht in u16
    };
    for (schlecht) |wert| {
        const text = try std.fmt.allocPrint(allocator, "{s}\nVERSION={s}\n", .{ kopf, wert });
        try std.testing.expectError(error.BadModuleVersion, parse(allocator, pfad, text));
    }
}

test "Rust R4X classes share admission and preserve semantic plan v1" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const base = "R4OS_MODULE_MANIFEST=2\nKIND=R4X\nNAME=RUSTTEST\nVERSION=0.1.0\nLANGUAGE=Rust\nSOURCE=src/main.rs\nENTRY_MODE=app\nTARGET=/SOFTWARE/RUSTTEST.R4X\nIMAGE_SCOPE=none\nIMPORT=R4SYS:Query:1\n";
    inline for (.{ "console", "gui", "service" }) |class| {
        const extra = if (comptime std.mem.eql(u8, class, "gui")) "IMPORT=R4DESK:Query:1\nIMPORT=R4DRAW:Query:1\n" else "";
        const text = try std.fmt.allocPrint(a, "{s}APP_CLASS={s}\n{s}", .{ base, class, extra });
        const manifest = try parse(a, "Rust/module.R4MF", text);
        try std.testing.expectEqual(Language.rust, manifest.language.?);
        var buffer: [4096]u8 = undefined;
        const plan = renderContractPlan(manifest, &buffer);
        try std.testing.expect(plan.ok);
        try std.testing.expect(std.mem.startsWith(u8, plan.bytes, "R4MF_PLAN=1\n"));
        const companions = try parse(a, "Rust/module.R4MF", try std.fmt.allocPrint(a, "{s}SOURCE=native/first.c\nSOURCE=native/second.c\nC_INCLUDE=native/include\nC_DEFINE=BIAS=7\n", .{text}));
        try std.testing.expectEqual(@as(usize, 3), companions.sources.len);
        try std.testing.expectEqualStrings("native/first.c", companions.sources[1]);
        try std.testing.expectEqualStrings("native/second.c", companions.sources[2]);
        const wrong = try std.mem.replaceOwned(u8, a, text, "main.rs", "main.c");
        try std.testing.expectError(error.SourceLanguageMismatch, parse(a, "Rust/module.R4MF", wrong));
        const escape = try std.mem.replaceOwned(u8, a, text, "src/main.rs", "../main.rs");
        try std.testing.expectError(error.SourcePathEscape, parse(a, "Rust/module.R4MF", escape));
        const low = try std.mem.replaceOwned(u8, a, text, "ENTRY_MODE=app", "ENTRY_MODE=lowlevel");
        const raw = try parse(a, "Rust/module.R4MF", low);
        try std.testing.expectEqual(EntryMode.lowlevel, raw.entry_mode.?);
        const raw_plan = try derivePlan(a, raw);
        try std.testing.expect(std.mem.indexOf(u8, raw_plan.build_profile, "_LowLevel_") != null);
        try std.testing.expect(!capabilities.query(.{ .language = "Rust", .kind = "R4X", .entry_mode = "lowlevel", .execution = .native_r4os }).supported);
    }
    _ = rust_project;
}

test "generation2 manifest selects central profile and exact start/import names" {
    const a = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(a);
    defer arena.deinit();
    const base = "R4OS_MODULE_MANIFEST=2\nKIND=R4X\nNAME=PROBE2\nVERSION=0.1.0\nLANGUAGE=Zig\nSOURCE=main.zig\nENTRY_MODE=lowlevel\nAPP_CLASS=console\nTARGET=/PROBE2.R4X\nIMAGE_SCOPE=none\nSDK_PROFILE=r4os-zig-generation2\nIMPORT=R4SYS:Query2:2\n";
    const manifest = try parse(arena.allocator(), "module.R4MF", base);
    const plan = try derivePlan(arena.allocator(), manifest);
    try std.testing.expectEqual(@as(u8, 2), manifest.platform_generation);
    try std.testing.expectEqualStrings("R4XStart2:R4XStart2:2", plan.export_contract);
    try std.testing.expectEqualStrings("r4os-zig-generation2", plan.build_profile);
    var text_buffer: [4096]u8 = undefined;
    const text_plan = renderContractPlan(manifest, &text_buffer);
    try std.testing.expect(text_plan.ok);
    try std.testing.expect(std.mem.indexOf(u8, text_plan.bytes, "BUILD_PROFILE=r4os-zig-generation2\n") != null);
    const wrong = try std.mem.replaceOwned(u8, arena.allocator(), base, "Query2:2", "Query:1");
    try std.testing.expectError(error.InvalidImport, parse(arena.allocator(), "module.R4MF", wrong));
    const ambiguous = try std.fmt.allocPrint(arena.allocator(), "{s}IMPORT=R4SYS:Query:1\n", .{base});
    try std.testing.expectError(error.InvalidImport, parse(arena.allocator(), "module.R4MF", ambiguous));
    const wrong_language = try std.mem.replaceOwned(u8, arena.allocator(), base, "r4os-zig-generation2", "r4os-c-generation2");
    try std.testing.expectError(error.SdkProfileRoleMismatch, parse(arena.allocator(), "module.R4MF", wrong_language));
    const unknown = try std.mem.replaceOwned(u8, arena.allocator(), base, "r4os-zig-generation2", "r4os-unknown");
    try std.testing.expectError(error.UnknownSdkProfile, parse(arena.allocator(), "module.R4MF", unknown));
    const application = try std.mem.replaceOwned(u8, arena.allocator(), base, "ENTRY_MODE=lowlevel", "ENTRY_MODE=app");
    const app = try parse(arena.allocator(), "module.R4MF", application);
    try std.testing.expectEqual(EntryMode.app, app.entry_mode.?);
    try std.testing.expectEqualStrings("R4XStart2:R4XStart2:2", (try derivePlan(arena.allocator(), app)).export_contract);
    // Every technical profile is bound to its actual language AND kind.
    // Query2 metadata by itself never selects a new loader init callback.
    for ([_][3][]const u8{ .{ "Zig", "zig", "zig" }, .{ "C", "c", "c" }, .{ "Rust", "rust", "rs" } }) |language| {
        for ([_][2][]const u8{ .{ "R4D", "r4d" }, .{ "R4P", "r4p" } }) |kind| {
            const text = try std.fmt.allocPrint(arena.allocator(), "R4OS_MODULE_MANIFEST=2\nKIND={s}\nNAME=TECH2\nVERSION=0.1.0\nLANGUAGE={s}\nSOURCE=main.{s}\nTARGET=/TECH2.{s}\nIMAGE_SCOPE=none\nSDK_PROFILE=r4os-{s}-{s}-generation2\nIMPORT=R4DEV:Query2:2\n", .{ kind[0], language[0], language[2], kind[0], language[1], kind[1] });
            const technical = try parse(arena.allocator(), "module.R4MF", text);
            try std.testing.expectEqual(@as(u8, 2), technical.platform_generation);
            try std.testing.expect(technical.entry_mode == null);
            const old_import = try std.mem.replaceOwned(u8, arena.allocator(), text, "R4DEV:Query2:2", "R4DEV:Query:1");
            try std.testing.expectError(error.InvalidImport, parse(arena.allocator(), "module.R4MF", old_import));
            const other_profile = try std.mem.replaceOwned(u8, arena.allocator(), text, if (std.mem.eql(u8, kind[1], "r4d")) "-r4d-generation2" else "-r4p-generation2", if (std.mem.eql(u8, kind[1], "r4d")) "-r4p-generation2" else "-r4d-generation2");
            try std.testing.expectError(error.SdkProfileRoleMismatch, parse(arena.allocator(), "module.R4MF", other_profile));
            const extra_import = try std.fmt.allocPrint(arena.allocator(), "{s}IMPORT=R4SYS:Query2:2\n", .{text});
            try std.testing.expectError(error.InvalidImport, parse(arena.allocator(), "module.R4MF", extra_import));
        }
    }
}
