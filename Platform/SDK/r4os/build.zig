const std = @import("std");
const contract_build = @import("r4os_contract");
const module_manifest = @import("module_manifest.zig");

pub const BuildResult = struct {
    code: std.Build.LazyPath,
    output: std.Build.LazyPath,
    verification: ?*std.Build.Step = null,
};

pub const sdk_package_name = "r4os_sdk";
// Seit 0.61.9 liegt R4XBuilder IM SDK. Vorher zeigte dieser Pfad von der
// SDK-Wurzel aus dem SDK heraus nach Code/BuildTools - wer nur das SDK hatte,
// hatte ihn nicht, und ohne ihn entsteht kein R4M0-Container, also kein .R4X.
pub const default_r4x_builder_source = "Tools/R4XBuilder/src/main.zig";
pub const default_r4l_contract_generator_source = "Tools/R4LContractGen/src/main.zig";

pub const SdkOptions = struct {
    root: ?std.Build.LazyPath = null,
    contract_dependency: ?*std.Build.Dependency = null,
    r4x_builder_source: ?std.Build.LazyPath = null,
    r4l_contract_generator_source: ?std.Build.LazyPath = null,
};

pub const HostProfile = struct {
    sdk_root: std.Build.LazyPath,
    r4x_builder_source: std.Build.LazyPath,
    r4os_module: std.Build.LazyPath,
    contract_module: *std.Build.Module,
    linker_script: std.Build.LazyPath,
    c_include_root: std.Build.LazyPath,
    contract_c_include_root: std.Build.LazyPath,
    c_startup_source_file: std.Build.LazyPath,
    zig_app_startup_source_file: std.Build.LazyPath,
    c_app_startup_source_file: std.Build.LazyPath,
};

pub const AppProfile = enum(u8) { console, desktop, service };

pub const ZigModuleBuild = struct {
    name: []const u8,
    root_source_file: std.Build.LazyPath,
};

/// Hostseitige Pfadauflösung fuer die in module.R4MF deklarierten
/// ZIG_MODULE-Eintraege. Die Reihenfolge entspricht exakt der
/// Manifestreihenfolge; Namen und Importvertrag bleiben allein im Manifest.
pub const R4MFBuildOptions = struct {
    zig_module_roots: ?[]const std.Build.LazyPath = null,
};

/// Eine einzubettende Ressource fuer den R4M0-Ressourcenbereich (0.61.12).
/// Als LazyPath deklariert, damit Zig die Datei als Buildinput trackt -
/// eine geaenderte Ressource baut das Modul neu.
pub const ResourceKind = enum { icon, help, file };
pub const ResourceInput = struct {
    kind: ResourceKind,
    /// Nur fuer .file: der Ressourcenname im Container.
    name: []const u8 = "",
    path: std.Build.LazyPath,
};

pub const R4MFCatalogStats = struct {
    discovered: usize = 0,
    selected: usize = 0,
};

pub const R4AppOptions = struct {
    name: []const u8,
    root_source_file: std.Build.LazyPath,
    version_module: ?std.Build.LazyPath = null,
    profile: AppProfile,
    metadata: []const []const u8 = &.{},
    optimize: std.builtin.OptimizeMode = .ReleaseSmall,
};

pub const R4CAppOptions = struct {
    name: []const u8,
    source_root: std.Build.LazyPath,
    sources: []const []const u8,
    profile: AppProfile,
    metadata: []const []const u8 = &.{},
    optimize: std.builtin.OptimizeMode = .ReleaseSmall,
};

// Die R4L-Import-Liste eines R4X-Moduls kommt ausschliesslich und in exakter
// Reihenfolge aus dessen module.R4MF. Seit R4MF v2 ist auch R4SYS explizit;
// der SDK-Build fuegt keinen Import hinzu und filtert keinen heraus.
fn manifestImportsFor(b: *std.Build, source: std.Build.LazyPath, levels_up: usize) []const []const u8 {
    const sp = switch (source) {
        .src_path => |sp| sp,
        else => @panic("R4X-Import-Aufloesung braucht einen b.path()-Quellpfad (module.R4MF-Ableitung)"),
    };
    var dir: []const u8 = sp.sub_path;
    var i: usize = 0;
    while (i < levels_up) : (i += 1) {
        // Leere Wurzel = Projektroot (Einzelbau mit b.path("src/main.zig")).
        dir = std.fs.path.dirname(dir) orelse "";
    }
    const manifest_full = sp.owner.pathFromRoot(b.pathJoin(&.{ dir, "module.R4MF" }));
    const data = std.Io.Dir.cwd().readFileAlloc(b.graph.io, manifest_full, b.allocator, .limited(64 * 1024)) catch {
        @panic(b.fmt("module.R4MF fehlt/unlesbar: {s} (eine Import-Wahrheit seit 0.57.1 - IMPORT-Zeilen gehoeren ins Manifest)", .{manifest_full}));
    };
    var count: usize = 0;
    var counter = std.mem.splitScalar(u8, data, '\n');
    while (counter.next()) |raw_line| {
        if (manifestImportValue(raw_line) != null) count += 1;
    }
    const list = b.allocator.alloc([]const u8, count) catch @panic("OOM");
    var index: usize = 0;
    var it = std.mem.splitScalar(u8, data, '\n');
    while (it.next()) |raw_line| {
        if (manifestImportValue(raw_line)) |value| {
            list[index] = b.dupe(value);
            index += 1;
        }
    }
    return list;
}

/// Liest VERSION= aus der module.R4MF eines Projektverzeichnisses.
///
/// Legacy-R4Ls mit comptime-Codebytes werden noch nicht ueber addR4MF gebaut.
/// Ihre Modulversion wird bis zur Migration aus dem Manifest gelesen, damit
/// auch dieser Uebergangspfad keine zweite Versionswahrheit fuehrt.
pub fn manifestModuleVersionFor(b: *std.Build, project_dir: []const u8) []const u8 {
    const manifest_full = b.pathFromRoot(b.pathJoin(&.{ project_dir, "module.R4MF" }));
    const data = std.Io.Dir.cwd().readFileAlloc(b.graph.io, manifest_full, b.allocator, .limited(64 * 1024)) catch {
        @panic(b.fmt("module.R4MF fehlt/unlesbar: {s}", .{manifest_full}));
    };
    var it = std.mem.splitScalar(u8, data, '\n');
    while (it.next()) |raw_line| {
        var line = std.mem.trim(u8, raw_line, " \t\r");
        if (line.len >= 3 and line[0] == 0xEF and line[1] == 0xBB and line[2] == 0xBF) line = line[3..];
        if (!std.mem.startsWith(u8, line, "VERSION=")) continue;
        return b.dupe(std.mem.trim(u8, line["VERSION=".len..], " \t\r"));
    }
    @panic(b.fmt("VERSION= fehlt in {s} (Pflichtfeld seit 0.61.4)", .{manifest_full}));
}

/// Die freien META-Zeilen eines Protokollmanifests: alles ausser den vier
/// Angaben, die schon als typisierte Option durchgereicht werden. Ohne diese
/// Filterung staende r4p.name zweimal im Container.
fn extraProtocolMetadata(b: *std.Build, loaded: LoadedR4MF) []const []const u8 {
    const derived = [_][]const u8{ "r4p.name=", "r4p.role=", "r4p.category=", "r4p.dep=" };
    var out: std.ArrayList([]const u8) = .empty;
    for (loaded.manifest.metadata) |entry| {
        var skip = false;
        for (derived) |prefix| {
            if (std.mem.startsWith(u8, entry, prefix)) skip = true;
        }
        if (!skip) out.append(b.allocator, entry) catch @panic("OOM");
    }
    return out.toOwnedSlice(b.allocator) catch @panic("OOM");
}

fn manifestOptimizeMode(manifest: module_manifest.Manifest) std.builtin.OptimizeMode {
    return switch (manifest.optimization orelse .size) {
        .size => .ReleaseSmall,
        .speed => .ReleaseFast,
    };
}

fn manifestImportValue(raw_line: []const u8) ?[]const u8 {
    var line = std.mem.trim(u8, raw_line, " \t\r");
    if (line.len >= 3 and line[0] == 0xEF and line[1] == 0xBB and line[2] == 0xBF) line = line[3..];
    if (!std.mem.startsWith(u8, line, "IMPORT=")) return null;
    return std.mem.trim(u8, line["IMPORT=".len..], " \t\r");
}

pub const R4XAppOptions = struct {
    name: []const u8,
    root_source_file: std.Build.LazyPath,
    version_module: ?std.Build.LazyPath = null,
    app_class: []const u8 = "auto",
    metadata: []const []const u8 = &.{},
    optimize: std.builtin.OptimizeMode = .ReleaseSmall,
};

pub const R4XCAppOptions = struct {
    name: []const u8,
    source_root: std.Build.LazyPath,
    sources: []const []const u8,
    app_class: []const u8 = "auto",
    metadata: []const []const u8 = &.{},
    optimize: std.builtin.OptimizeMode = .ReleaseSmall,
};

pub const R4DModuleOptions = struct {
    // Modulversion aus module.R4MF; null bei Aufrufern ohne Manifest.
    module_version: ?[]const u8 = null,
    name: []const u8,
    driver_name: []const u8,
    driver_type: []const u8 = "misc",
    root_source_file: std.Build.LazyPath,
    optimize: std.builtin.OptimizeMode = .ReleaseSmall,
};

pub const R4PModuleOptions = struct {
    // Modulversion aus module.R4MF; null bei Aufrufern ohne Manifest.
    module_version: ?[]const u8 = null,
    name: []const u8,
    protocol_name: []const u8,
    role: []const u8,
    category: []const u8 = "misc",
    dependencies: []const []const u8 = &.{},
    metadata: []const []const u8 = &.{},
    root_source_file: std.Build.LazyPath,
    optimize: std.builtin.OptimizeMode = .ReleaseSmall,
};

pub const R4LModuleOptions = struct {
    // Modulversion aus module.R4MF; null bei Aufrufern ohne Manifest.
    module_version: ?[]const u8 = null,
    name: []const u8,
    code: std.Build.LazyPath,
    rodata: ?std.Build.LazyPath = null,
    data: ?std.Build.LazyPath = null,
    bss_size: []const u8 = "0",
    imports: []const []const u8 = &.{},
    exports: []const []const u8 = &.{},
    relocations: []const []const u8 = &.{},
    metadata: []const []const u8 = &.{},
};

pub const Sdk = struct {
    b: *std.Build,
    profile: HostProfile,
    builder: *std.Build.Step.Compile,
    r4l_contract_generator: ?*std.Build.Step.Compile = null,

    pub fn init(b: *std.Build, opts: SdkOptions) Sdk {
        const root = opts.root orelse lazyPathOption(b, "r4os-sdk", "Path to the R4OS SDK root") orelse b.path(".");
        var resolved_opts = opts;
        if (resolved_opts.contract_dependency == null) {
            resolved_opts.contract_dependency = b.dependencyFromBuildZig(contract_build, .{});
        }
        return initFromRoot(b, root, resolved_opts);
    }

    pub fn fromDependency(b: *std.Build, dependency: *std.Build.Dependency, opts: SdkOptions) Sdk {
        var dep_opts = opts;
        dep_opts.root = dependency.path("");
        if (dep_opts.contract_dependency == null) {
            dep_opts.contract_dependency = dependency.builder.dependencyFromBuildZig(contract_build, .{});
        }
        return initFromRoot(b, dep_opts.root.?, dep_opts);
    }

    pub fn initFromRoot(b: *std.Build, root: std.Build.LazyPath, opts: SdkOptions) Sdk {
        const builder_source = opts.r4x_builder_source orelse
            lazyPathOption(b, "r4os-r4xbuilder", "Path to R4XBuilder src/main.zig") orelse
            root.path(b, default_r4x_builder_source);
        const contract_generator_source = opts.r4l_contract_generator_source orelse
            lazyPathOption(b, "r4os-r4l-contract-gen", "Path to R4LContractGen src/main.zig") orelse
            root.path(b, default_r4l_contract_generator_source);
        const contract_dependency = opts.contract_dependency orelse
            @panic("R4OS SDK requires the r4os_contract package dependency");
        const profile = HostProfile{
            .sdk_root = root,
            .r4x_builder_source = builder_source,
            .r4os_module = root.path(b, "r4os.zig"),
            .contract_module = contract_dependency.module("r4os_contract"),
            .linker_script = root.path(b, "r4os/linker/r4os_module.ld"),
            .c_include_root = root.path(b, "Shared/C/include"),
            .contract_c_include_root = contract_dependency.namedLazyPath("r4os_contract_c_include"),
            .c_startup_source_file = root.path(b, "Shared/C/src/r4xstart_startup.c"),
            .zig_app_startup_source_file = root.path(b, "Shared/Zig/r4app_startup.zig"),
            .c_app_startup_source_file = root.path(b, "Shared/C/src/r4app_startup.c"),
        };
        return .{
            .b = b,
            .profile = profile,
            .builder = addR4XBuilder(b, profile.r4x_builder_source),
            .r4l_contract_generator = addR4LContractGenerator(b, contract_generator_source),
        };
    }

    pub fn createR4osModule(
        self: Sdk,
        target: std.Build.ResolvedTarget,
        optimize: std.builtin.OptimizeMode,
    ) *std.Build.Module {
        const module = self.b.createModule(.{
            .root_source_file = self.profile.r4os_module,
            .target = target,
            .optimize = optimize,
        });
        module.addImport("r4os_contract", self.profile.contract_module);
        return module;
    }

    pub fn addR4XStart(self: Sdk, opts: R4XAppOptions) BuildResult {
        const imports = manifestImportsFor(self.b, opts.root_source_file, 2);
        return addR4XStartWithOptions(self.b, .{
            .name = opts.name,
            .root_source_file = opts.root_source_file,
            .r4os_module = self.profile.r4os_module,
            .contract_module = self.profile.contract_module,
            .version_module = opts.version_module,
            .linker_script = self.profile.linker_script,
            .builder = self.builder,
            .app_class = opts.app_class,
            .imports = imports,
            .metadata = opts.metadata,
            .optimize = opts.optimize,
        });
    }

    pub fn addR4App(self: Sdk, opts: R4AppOptions) BuildResult {
        const imports = manifestImportsFor(self.b, opts.root_source_file, 2);
        return addR4AppWithOptions(self.b, .{
            .name = opts.name,
            .root_source_file = opts.root_source_file,
            .startup_source_file = self.profile.zig_app_startup_source_file,
            .r4os_module = self.profile.r4os_module,
            .contract_module = self.profile.contract_module,
            .version_module = opts.version_module,
            .linker_script = self.profile.linker_script,
            .builder = self.builder,
            .profile = opts.profile,
            .imports = imports,
            .metadata = opts.metadata,
            .optimize = opts.optimize,
        });
    }

    pub fn addR4XStartC(self: Sdk, opts: R4XCAppOptions) BuildResult {
        const imports = manifestImportsFor(self.b, opts.source_root, 1);
        return addR4XStartCWithOptions(self.b, .{
            .name = opts.name,
            .source_root = opts.source_root,
            .sources = opts.sources,
            .include_root = self.profile.c_include_root,
            .extra_include_roots = &.{self.profile.contract_c_include_root},
            .startup_source_file = self.profile.c_startup_source_file,
            .linker_script = self.profile.linker_script,
            .builder = self.builder,
            .app_class = opts.app_class,
            .imports = imports,
            .metadata = opts.metadata,
            .optimize = opts.optimize,
        });
    }

    pub fn addR4AppC(self: Sdk, opts: R4CAppOptions) BuildResult {
        const imports = manifestImportsFor(self.b, opts.source_root, 1);
        return addR4AppCWithOptions(self.b, .{
            .name = opts.name,
            .source_root = opts.source_root,
            .sources = opts.sources,
            .include_root = self.profile.c_include_root,
            .extra_include_roots = &.{self.profile.contract_c_include_root},
            .startup_source_file = self.profile.c_app_startup_source_file,
            .linker_script = self.profile.linker_script,
            .builder = self.builder,
            .profile = opts.profile,
            .imports = imports,
            .metadata = opts.metadata,
            .optimize = opts.optimize,
        });
    }

    /// Baut ein Modul allein aus seinem Manifest. Runtime-R4Ls werden dabei
    /// wie andere Userlandmodule kompiliert und anschliessend aus ihrer ELF
    /// verpackt. Legacy-R4Ls ohne EXPORT=-Deklaration bleiben waehrend der
    /// Migration auf ihrem ausdruecklichen addR4LRaw-Pfad.
    pub fn addR4MF(self: Sdk, manifest_path: std.Build.LazyPath) BuildResult {
        return self.addR4MFWithOptions(manifest_path, .{});
    }

    /// Wie addR4MF, aber mit expliziten, vom Hostbuild gelieferten Pfaden fuer
    /// die im Manifest aufgefuehrten Zig-Module. Das erlaubt gepinnte
    /// Repository-Abhaengigkeiten, ohne feste Nachbarpfade in Quellcode oder
    /// Buildscript und ohne eine zweite Liste von Modulnamen.
    pub fn addR4MFWithOptions(self: Sdk, manifest_path: std.Build.LazyPath, options: R4MFBuildOptions) BuildResult {
        const loaded = loadCurrentR4MF(self.b, manifest_path, options);
        return switch (loaded.manifest.kind) {
            .r4x => self.addR4MFProgram(loaded),
            .r4d => self.addR4MFDriver(loaded),
            .r4p => self.addR4MFProtocol(loaded),
            .r4l => self.addR4MFLibrary(loaded),
        };
    }

    /// Ressourcen des Manifests als Buildinputs: projektrelative Pfade werden
    /// aufgeloest und auf Existenz geprueft, wie bei SOURCE. Reihenfolge ist
    /// bereits die Vertragsreihenfolge (Icons nach Index, Help, Dateien).
    fn manifestResources(self: Sdk, loaded: LoadedR4MF) []const ResourceInput {
        const b = self.b;
        const total = loaded.manifest.icons.len +
            @as(usize, if (loaded.manifest.help != null) 1 else 0) +
            loaded.manifest.resources.len;
        if (total == 0) return &.{};
        const out = b.allocator.alloc(ResourceInput, total) catch @panic("OOM");
        var index: usize = 0;
        for (loaded.manifest.icons) |icon_path| {
            out[index] = .{ .kind = .icon, .path = resolvedResourcePath(b, loaded.project_path, icon_path) };
            index += 1;
        }
        if (loaded.manifest.help) |help_path| {
            out[index] = .{ .kind = .help, .path = resolvedResourcePath(b, loaded.project_path, help_path) };
            index += 1;
        }
        for (loaded.manifest.resources) |entry| {
            out[index] = .{ .kind = .file, .name = entry.name, .path = resolvedResourcePath(b, loaded.project_path, entry.path) };
            index += 1;
        }
        return out;
    }

    fn manifestCIncludeRoots(self: Sdk, loaded: LoadedR4MF) []const std.Build.LazyPath {
        if (loaded.manifest.c_includes.len == 0) return &.{};
        const roots = self.b.allocator.alloc(std.Build.LazyPath, loaded.manifest.c_includes.len) catch @panic("OOM");
        for (loaded.manifest.c_includes, 0..) |path, index| {
            roots[index] = resolvedProjectPath(self.b, loaded.project_path, path);
        }
        return roots;
    }

    fn withContractCIncludeRoot(
        self: Sdk,
        roots: []const std.Build.LazyPath,
    ) []const std.Build.LazyPath {
        const result = self.b.allocator.alloc(std.Build.LazyPath, roots.len + 1) catch @panic("OOM");
        result[0] = self.profile.contract_c_include_root;
        for (roots, 1..) |root, index| result[index] = root;
        return result;
    }

    /// Wert einer META-Zeile aus dem Manifest. Fehlt sie, bricht der Build ab -
    /// ein Treiber ohne r4d.type waere sonst still ein misc-Treiber.
    fn manifestMeta(self: Sdk, loaded: LoadedR4MF, key: []const u8) []const u8 {
        for (loaded.manifest.metadata) |entry| {
            if (entry.len > key.len and std.mem.startsWith(u8, entry, key) and entry[key.len] == '=') {
                return entry[key.len + 1 ..];
            }
        }
        @panic(self.b.fmt("module.R4MF fehlt die Pflichtangabe {s}= : {s}", .{ key, loaded.manifest.path }));
    }

    fn addR4MFDriver(self: Sdk, loaded: LoadedR4MF) BuildResult {
        return addR4DWithOptions(self.b, .{
            .name = loaded.manifest.name,
            .driver_name = self.manifestMeta(loaded, "r4d.name"),
            .driver_type = self.manifestMeta(loaded, "r4d.type"),
            .module_version = loaded.manifest.module_version.text,
            .root_source_file = userPath(self.b, loaded.source_paths[0]),
            .r4os_module = self.profile.r4os_module,
            .contract_module = self.profile.contract_module,
            .linker_script = self.profile.linker_script,
            .builder = self.builder,
            .resources = self.manifestResources(loaded),
            .optimize = manifestOptimizeMode(loaded.manifest),
        });
    }

    fn addR4MFProtocol(self: Sdk, loaded: LoadedR4MF) BuildResult {
        // r4p.dep= ist wiederholbar; die Reihenfolge des Manifests bleibt.
        var deps: std.ArrayList([]const u8) = .empty;
        for (loaded.manifest.metadata) |entry| {
            if (std.mem.startsWith(u8, entry, "r4p.dep=")) {
                deps.append(self.b.allocator, entry["r4p.dep=".len..]) catch @panic("OOM");
            }
        }
        return addR4PWithOptions(self.b, .{
            .name = loaded.manifest.name,
            .protocol_name = self.manifestMeta(loaded, "r4p.name"),
            .role = self.manifestMeta(loaded, "r4p.role"),
            .category = self.manifestMeta(loaded, "r4p.category"),
            .dependencies = deps.toOwnedSlice(self.b.allocator) catch @panic("OOM"),
            .metadata = extraProtocolMetadata(self.b, loaded),
            .module_version = loaded.manifest.module_version.text,
            .root_source_file = userPath(self.b, loaded.source_paths[0]),
            .r4os_module = self.profile.r4os_module,
            .contract_module = self.profile.contract_module,
            .linker_script = self.profile.linker_script,
            .builder = self.builder,
            .resources = self.manifestResources(loaded),
            .optimize = manifestOptimizeMode(loaded.manifest),
        });
    }

    fn addR4MFLibrary(self: Sdk, loaded: LoadedR4MF) BuildResult {
        if (loaded.manifest.exports.len == 0) {
            @panic(self.b.fmt("R4MF runtime-R4L requires EXPORT declarations: {s}", .{loaded.manifest.path}));
        }
        const contract_check = self.addR4LContractCheck(loaded);
        const optimize = manifestOptimizeMode(loaded.manifest);
        self.b.getInstallStep().dependOn(&contract_check.step);
        const implementation_module = [_]ZigModuleBuild{.{
            .name = "r4l_contract",
            .root_source_file = resolvedProjectPath(self.b, loaded.project_path, loaded.manifest.implementation_zig.?),
        }};
        const companion_count = loaded.source_paths.len - 1;
        const c_source_files = self.b.allocator.alloc(std.Build.LazyPath, companion_count) catch @panic("OOM");
        const explicit_include_roots = self.manifestCIncludeRoots(loaded);
        const c_include_roots = self.b.allocator.alloc(std.Build.LazyPath, companion_count + explicit_include_roots.len + 2) catch @panic("OOM");
        c_include_roots[0] = self.profile.c_include_root;
        c_include_roots[1] = self.profile.contract_c_include_root;
        for (loaded.source_paths[1..], 0..) |source_path, index| {
            c_source_files[index] = userPath(self.b, source_path);
            c_include_roots[index + 2] = userPath(self.b, std.fs.path.dirname(source_path) orelse loaded.project_path);
        }
        for (explicit_include_roots, companion_count + 2..) |include_root, index| c_include_roots[index] = include_root;
        const c_library_include_roots = self.b.allocator.alloc(std.Build.LazyPath, explicit_include_roots.len + 2) catch @panic("OOM");
        c_library_include_roots[0] = resolvedProjectPath(self.b, loaded.project_path, std.fs.path.dirname(loaded.manifest.binding_c.?) orelse ".");
        c_library_include_roots[1] = self.profile.contract_c_include_root;
        for (explicit_include_roots, 2..) |include_root, index| c_library_include_roots[index] = include_root;
        const elf = switch (loaded.manifest.language.?) {
            .zig => addRawModule(self.b, .{
                .name = loaded.manifest.name,
                .root_source_file = userPath(self.b, loaded.source_paths[0]),
                .r4os_module = self.profile.r4os_module,
                .contract_module = self.profile.contract_module,
                .linker_script = self.profile.linker_script,
                .entry_symbol = "r4l_entry",
                .zig_modules = &implementation_module,
                .c_source_files = c_source_files,
                .c_include_roots = c_include_roots,
                .c_defines = loaded.manifest.c_defines,
                .c_flags = loaded.manifest.c_flags,
                .optimize = optimize,
            }),
            .c => addCModule(self.b, .{
                .name = loaded.manifest.name,
                .source_root = userPath(self.b, loaded.project_path),
                .sources = loaded.manifest.sources,
                .include_root = self.profile.c_include_root,
                .extra_include_roots = c_library_include_roots,
                .c_defines = loaded.manifest.c_defines,
                .c_flags = loaded.manifest.c_flags,
                .startup_source_file = null,
                .linker_script = self.profile.linker_script,
                .entry_symbol = "r4l_entry",
                .strip = false,
                .emit_relocs = true,
                .optimize = optimize,
            }),
        };
        const exports = self.b.allocator.alloc([]const u8, loaded.manifest.exports.len) catch @panic("OOM");
        for (loaded.manifest.exports, 0..) |entry, index| {
            exports[index] = self.b.fmt("{s}:@{s}:{d}", .{ entry.name, entry.symbol, entry.revision });
        }
        const metadata = self.b.allocator.alloc([]const u8, loaded.manifest.metadata.len + 1) catch @panic("OOM");
        metadata[0] = self.b.fmt("module.version={s}", .{loaded.manifest.module_version.text});
        for (loaded.manifest.metadata, 0..) |entry, index| metadata[index + 1] = entry;
        var result = addR4MElf(self.b, .{
            .name = loaded.manifest.name,
            .kind = "r4l",
            .extension = "R4L",
            .elf = elf,
            .builder = self.builder,
            .imports = loaded.manifest.imports,
            .exports = exports,
            .metadata = metadata,
        });
        result.verification = &contract_check.step;
        return result;
    }

    fn addR4LContractCheck(self: Sdk, loaded: LoadedR4MF) *std.Build.Step.Run {
        const generator = self.r4l_contract_generator orelse @panic("Runtime-R4L contract generator missing from SDK profile");
        const run = self.b.addRunArtifact(generator);
        run.stdio = .inherit;
        run.addArg("--check");
        run.addArg("--module-name");
        run.addArg(loaded.manifest.name);
        for (loaded.manifest.exports) |entry| {
            if (std.ascii.eqlIgnoreCase(entry.name, "Query")) continue;
            run.addArg("--export");
            run.addArg(self.b.fmt("{s}:{s}:{d}", .{ entry.name, entry.symbol, entry.revision }));
        }
        addNamedProjectFile(run, self.b, loaded.project_path, "--contract", loaded.manifest.contract.?);
        addNamedProjectFile(run, self.b, loaded.project_path, "--baseline", loaded.manifest.contract_baseline.?);
        addNamedProjectFile(run, self.b, loaded.project_path, "--implementation-zig", loaded.manifest.implementation_zig.?);
        addNamedProjectFile(run, self.b, loaded.project_path, "--binding-zig", loaded.manifest.binding_zig.?);
        addNamedProjectFile(run, self.b, loaded.project_path, "--binding-c", loaded.manifest.binding_c.?);
        addNamedProjectFile(run, self.b, loaded.project_path, "--fixture-zig", loaded.manifest.conformance_zig.?);
        addNamedProjectFile(run, self.b, loaded.project_path, "--fixture-c", loaded.manifest.conformance_c.?);
        addNamedProjectFile(run, self.b, loaded.project_path, "--docs", loaded.manifest.api_reference.?);
        return run;
    }

    fn addR4MFProgram(self: Sdk, loaded: LoadedR4MF) BuildResult {
        const profile: AppProfile = switch (loaded.manifest.app_class.?) {
            .console => .console,
            .gui => .desktop,
            .service => .service,
        };
        const optimize = manifestOptimizeMode(loaded.manifest);
        const manifest_metadata = module_manifest.r4xManifestMetadata(self.b.allocator, loaded.manifest) catch @panic("invalid R4MF role metadata");
        return switch (loaded.manifest.language.?) {
            .zig => if (loaded.manifest.entry_mode.? == .app) addR4AppWithOptions(self.b, .{
                .name = loaded.manifest.name,
                .root_source_file = userPath(self.b, loaded.source_paths[0]),
                .startup_source_file = self.profile.zig_app_startup_source_file,
                .r4os_module = self.profile.r4os_module,
                .contract_module = self.profile.contract_module,
                .linker_script = self.profile.linker_script,
                .builder = self.builder,
                .profile = profile,
                .zig_modules = loaded.zig_modules,
                .imports = loaded.manifest.imports,
                .module_version = loaded.manifest.module_version.text,
                .metadata = manifest_metadata,
                .resources = self.manifestResources(loaded),
                .optimize = optimize,
            }) else addR4XStartWithOptions(self.b, .{
                .name = loaded.manifest.name,
                .root_source_file = userPath(self.b, loaded.source_paths[0]),
                .r4os_module = self.profile.r4os_module,
                .contract_module = self.profile.contract_module,
                .linker_script = self.profile.linker_script,
                .builder = self.builder,
                .app_class = loaded.manifest.app_class.?.text(),
                .zig_modules = loaded.zig_modules,
                .imports = loaded.manifest.imports,
                .module_version = loaded.manifest.module_version.text,
                .metadata = manifest_metadata,
                .resources = self.manifestResources(loaded),
                .optimize = optimize,
            }),
            .c => if (loaded.manifest.entry_mode.? == .app) addR4AppCWithOptions(self.b, .{
                .name = loaded.manifest.name,
                .source_root = userPath(self.b, loaded.project_path),
                .sources = loaded.manifest.sources,
                .include_root = self.profile.c_include_root,
                .startup_source_file = self.profile.c_app_startup_source_file,
                .linker_script = self.profile.linker_script,
                .builder = self.builder,
                .profile = profile,
                .imports = loaded.manifest.imports,
                .extra_include_roots = self.withContractCIncludeRoot(self.manifestCIncludeRoots(loaded)),
                .c_defines = loaded.manifest.c_defines,
                .c_flags = loaded.manifest.c_flags,
                .module_version = loaded.manifest.module_version.text,
                .metadata = manifest_metadata,
                .resources = self.manifestResources(loaded),
                .optimize = optimize,
            }) else addR4XStartCWithOptions(self.b, .{
                .name = loaded.manifest.name,
                .source_root = userPath(self.b, loaded.project_path),
                .sources = loaded.manifest.sources,
                .include_root = self.profile.c_include_root,
                .startup_source_file = self.profile.c_startup_source_file,
                .linker_script = self.profile.linker_script,
                .builder = self.builder,
                .app_class = loaded.manifest.app_class.?.text(),
                .imports = loaded.manifest.imports,
                .extra_include_roots = self.withContractCIncludeRoot(self.manifestCIncludeRoots(loaded)),
                .c_defines = loaded.manifest.c_defines,
                .c_flags = loaded.manifest.c_flags,
                .module_version = loaded.manifest.module_version.text,
                .metadata = manifest_metadata,
                .resources = self.manifestResources(loaded),
                .optimize = optimize,
            }),
        };
    }

    /// Discover current manifests below the supplied roots and add them in
    /// deterministic kind/name/path order. Legacy-R4Ls without EXPORT=
    /// remain on their explicit comptime transition path.
    pub fn addR4MFCatalog(self: Sdk, roots: []const std.Build.LazyPath, module_filter: []const u8) R4MFCatalogStats {
        var entries: std.ArrayList(R4MFCatalogEntry) = .empty;
        for (roots) |root| collectR4MFCatalogRoot(self.b, &entries, root);
        std.mem.sort(R4MFCatalogEntry, entries.items, {}, lessR4MFCatalogEntry);

        var stats = R4MFCatalogStats{ .discovered = entries.items.len };
        for (entries.items, 0..) |entry, index| {
            // Die Identitaet ist laut Vertrag das Paar (KIND, NAME).
            if (index != 0 and
                entry.kind == entries.items[index - 1].kind and
                std.ascii.eqlIgnoreCase(entry.name, entries.items[index - 1].name))
            {
                @panic(self.b.fmt("R4MF aggregate identity collision: {s} {s} in {s} and {s}", .{ entry.kind.text(), entry.name, entries.items[index - 1].path, entry.path }));
            }
            if (!moduleFilterContains(module_filter, entry.name)) continue;
            _ = self.addR4MF(userPath(self.b, entry.path));
            stats.selected += 1;
        }
        return stats;
    }

    pub fn addR4XService(self: Sdk, opts: R4XAppOptions) BuildResult {
        return addR4XStartWithOptions(self.b, .{
            .name = opts.name,
            .root_source_file = opts.root_source_file,
            .r4os_module = self.profile.r4os_module,
            .contract_module = self.profile.contract_module,
            .version_module = opts.version_module,
            .linker_script = self.profile.linker_script,
            .builder = self.builder,
            .app_class = "service",
            .imports = manifestImportsFor(self.b, opts.root_source_file, 2),
            .metadata = opts.metadata,
            .optimize = opts.optimize,
        });
    }

    pub fn addR4D(self: Sdk, opts: R4DModuleOptions) BuildResult {
        return addR4DWithOptions(self.b, .{
            .name = opts.name,
            .driver_name = opts.driver_name,
            .driver_type = opts.driver_type,
            .module_version = opts.module_version,
            .root_source_file = opts.root_source_file,
            .r4os_module = self.profile.r4os_module,
            .contract_module = self.profile.contract_module,
            .linker_script = self.profile.linker_script,
            .builder = self.builder,
            .optimize = opts.optimize,
        });
    }

    pub fn addR4P(self: Sdk, opts: R4PModuleOptions) BuildResult {
        return addR4PWithOptions(self.b, .{
            .name = opts.name,
            .protocol_name = opts.protocol_name,
            .role = opts.role,
            .category = opts.category,
            .dependencies = opts.dependencies,
            .metadata = opts.metadata,
            .module_version = opts.module_version,
            .root_source_file = opts.root_source_file,
            .r4os_module = self.profile.r4os_module,
            .contract_module = self.profile.contract_module,
            .linker_script = self.profile.linker_script,
            .builder = self.builder,
            .optimize = opts.optimize,
        });
    }

    pub fn addR4LRaw(self: Sdk, opts: R4LModuleOptions) BuildResult {
        return addR4LRawWithOptions(self.b, .{
            .name = opts.name,
            .code = opts.code,
            .rodata = opts.rodata,
            .data = opts.data,
            .builder = self.builder,
            .bss_size = opts.bss_size,
            .imports = opts.imports,
            .exports = opts.exports,
            .relocations = opts.relocations,
            .metadata = opts.metadata,
            .module_version = opts.module_version,
        });
    }
};

const R4MFCatalogEntry = struct {
    name: []const u8,
    path: []const u8,
    kind: module_manifest.Kind,
};

fn collectR4MFCatalogRoot(b: *std.Build, entries: *std.ArrayList(R4MFCatalogEntry), root: std.Build.LazyPath) void {
    const root_path = lazyPathAbsolute(b, root);
    var dir = std.Io.Dir.cwd().openDir(b.graph.io, root_path, .{ .iterate = true }) catch |err|
        @panic(b.fmt("R4MF aggregate root unavailable: {s} ({s})", .{ root_path, @errorName(err) }));
    defer dir.close(b.graph.io);
    var walker = dir.walk(b.allocator) catch @panic("OOM");
    defer walker.deinit();
    while (walker.next(b.graph.io) catch |err| @panic(b.fmt("R4MF aggregate walk failed: {s} ({s})", .{ root_path, @errorName(err) }))) |entry| {
        if (entry.kind != .file or !std.ascii.eqlIgnoreCase(std.fs.path.basename(entry.path), "module.R4MF")) continue;
        const path = std.fs.path.join(b.allocator, &.{ root_path, entry.path }) catch @panic("OOM");
        const bytes = std.Io.Dir.cwd().readFileAlloc(
            b.graph.io,
            path,
            b.allocator,
            .limited(module_manifest.max_manifest_bytes),
        ) catch |err| @panic(b.fmt("R4MF aggregate manifest unavailable: {s} ({s})", .{ path, @errorName(err) }));
        const manifest = module_manifest.parse(b.allocator, path, bytes) catch |err|
            @panic(b.fmt("R4MF aggregate manifest invalid: {s} ({s})", .{ path, @errorName(err) }));
        entries.append(b.allocator, .{ .name = b.dupe(manifest.name), .path = b.dupe(path), .kind = manifest.kind }) catch @panic("OOM");
    }
}

fn lessR4MFCatalogEntry(_: void, a: R4MFCatalogEntry, b: R4MFCatalogEntry) bool {
    // Nach Art UND Name sortieren, damit die Kollisionspruefung gleiche
    // Identitaeten nebeneinander sieht. Der Name allein reicht nicht: EXAMPLE
    // gibt es als R4X, R4D und R4P, und das sind drei verschiedene Module.
    const by_kind = std.ascii.orderIgnoreCase(a.kind.text(), b.kind.text());
    if (by_kind != .eq) return by_kind == .lt;
    const by_name = std.ascii.orderIgnoreCase(a.name, b.name);
    if (by_name != .eq) return by_name == .lt;
    return std.ascii.orderIgnoreCase(a.path, b.path) == .lt;
}

fn moduleFilterContains(filter: []const u8, name: []const u8) bool {
    if (std.mem.trim(u8, filter, " \t\r\n,;").len == 0) return true;
    var tokens = std.mem.tokenizeAny(u8, filter, " \t\r\n,;");
    while (tokens.next()) |token| if (std.ascii.eqlIgnoreCase(token, name)) return true;
    return false;
}

const LoadedR4MF = struct {
    manifest: module_manifest.Manifest,
    project_path: []const u8,
    source_paths: []const []const u8,
    zig_modules: []const ZigModuleBuild,
};

fn loadCurrentR4MF(b: *std.Build, manifest_path: std.Build.LazyPath, options: R4MFBuildOptions) LoadedR4MF {
    const full_path = lazyPathAbsolute(b, manifest_path);
    const bytes = std.Io.Dir.cwd().readFileAlloc(
        b.graph.io,
        full_path,
        b.allocator,
        .limited(module_manifest.max_manifest_bytes),
    ) catch |err| @panic(b.fmt("R4MF build capability error: manifest unavailable: {s} ({s})", .{ full_path, @errorName(err) }));
    const canonical_path = b.dupe(full_path);
    for (canonical_path) |*byte| if (byte.* == '\\') {
        byte.* = '/';
    };
    const manifest = module_manifest.parse(b.allocator, canonical_path, bytes) catch |err|
        @panic(b.fmt("R4MF current-contract error: {s} ({s})", .{ full_path, @errorName(err) }));
    // derivePlan prueft den R4X-Startvertrag und die Profilimporte; fuer R4D
    // R4P und R4L gibt es keinen solchen Vertrag.
    if (manifest.kind == .r4x) {
        _ = module_manifest.derivePlan(b.allocator, manifest) catch |err|
            @panic(b.fmt("R4MF build-plan error: {s} ({s})", .{ full_path, @errorName(err) }));
    }
    const project_path = std.fs.path.dirname(full_path) orelse
        @panic(b.fmt("R4MF build capability error: manifest has no project directory: {s}", .{full_path}));
    const source_paths = b.allocator.alloc([]const u8, manifest.sources.len) catch @panic("OOM");
    for (manifest.sources, 0..) |source, index| {
        source_paths[index] = std.fs.path.join(b.allocator, &.{ project_path, source }) catch @panic("OOM");
        std.Io.Dir.cwd().access(b.graph.io, source_paths[index], .{}) catch |err|
            @panic(b.fmt("R4MF source capability error: {s} ({s})", .{ source_paths[index], @errorName(err) }));
    }
    if (options.zig_module_roots) |roots| {
        if (roots.len != manifest.zig_modules.len) {
            @panic(b.fmt(
                "R4MF Zig-module mapping error: {s} declares {d} modules, but the host build supplied {d} roots",
                .{ full_path, manifest.zig_modules.len, roots.len },
            ));
        }
    }
    const zig_modules = b.allocator.alloc(ZigModuleBuild, manifest.zig_modules.len) catch @panic("OOM");
    for (manifest.zig_modules, 0..) |entry, index| {
        const colon = std.mem.indexOfScalar(u8, entry, ':') orelse unreachable;
        const root_source_file = if (options.zig_module_roots) |roots|
            roots[index]
        else blk: {
            const module_path = std.fs.path.join(b.allocator, &.{ project_path, entry[colon + 1 ..] }) catch @panic("OOM");
            std.Io.Dir.cwd().access(b.graph.io, module_path, .{}) catch |err|
                @panic(b.fmt("R4MF Zig-module capability error: {s} ({s})", .{ module_path, @errorName(err) }));
            break :blk userPath(b, module_path);
        };
        zig_modules[index] = .{
            .name = entry[0..colon],
            .root_source_file = root_source_file,
        };
    }
    return .{
        .manifest = manifest,
        .project_path = project_path,
        .source_paths = source_paths,
        .zig_modules = zig_modules,
    };
}

fn resolvedResourcePath(b: *std.Build, project_path: []const u8, relative: []const u8) std.Build.LazyPath {
    const full = std.fs.path.join(b.allocator, &.{ project_path, relative }) catch @panic("OOM");
    std.Io.Dir.cwd().access(b.graph.io, full, .{}) catch |err|
        @panic(b.fmt("R4MF resource capability error: {s} ({s})", .{ full, @errorName(err) }));
    return userPath(b, full);
}

fn resolvedProjectPath(b: *std.Build, project_path: []const u8, relative: []const u8) std.Build.LazyPath {
    const full = std.fs.path.join(b.allocator, &.{ project_path, relative }) catch @panic("OOM");
    return userPath(b, full);
}

fn addNamedProjectFile(run: *std.Build.Step.Run, b: *std.Build, project_path: []const u8, argument: []const u8, relative: []const u8) void {
    const full = std.fs.path.join(b.allocator, &.{ project_path, relative }) catch @panic("OOM");
    run.addArg(argument);
    run.addFileArg(userPath(b, full));
}

fn lazyPathAbsolute(b: *std.Build, path: std.Build.LazyPath) []const u8 {
    return switch (path) {
        .src_path => |source| source.owner.pathFromRoot(source.sub_path),
        .cwd_relative => |value| if (std.fs.path.isAbsolute(value)) value else b.pathResolve(&.{value}),
        else => @panic("R4MF build capability error: manifest must be a source or host path"),
    };
}

pub const R4XOptions = struct {
    name: []const u8,
    root_source_file: std.Build.LazyPath,
    r4os_module: std.Build.LazyPath,
    contract_module: *std.Build.Module,
    version_module: ?std.Build.LazyPath = null,
    linker_script: std.Build.LazyPath,
    builder: *std.Build.Step.Compile,
    app_class: []const u8 = "auto",
    zig_modules: []const ZigModuleBuild = &.{},
    imports: []const []const u8 = &.{},
    // Modulversion aus module.R4MF; null bei Aufrufern ohne Manifest.
    module_version: ?[]const u8 = null,
    metadata: []const []const u8 = &.{},
    resources: []const ResourceInput = &.{},
    optimize: std.builtin.OptimizeMode = .ReleaseSmall,
};

pub const R4AppBuildOptions = struct {
    name: []const u8,
    root_source_file: std.Build.LazyPath,
    startup_source_file: std.Build.LazyPath,
    r4os_module: std.Build.LazyPath,
    contract_module: *std.Build.Module,
    version_module: ?std.Build.LazyPath = null,
    linker_script: std.Build.LazyPath,
    builder: *std.Build.Step.Compile,
    profile: AppProfile,
    zig_modules: []const ZigModuleBuild = &.{},
    imports: []const []const u8 = &.{},
    // Modulversion aus module.R4MF; null bei Aufrufern ohne Manifest.
    module_version: ?[]const u8 = null,
    metadata: []const []const u8 = &.{},
    resources: []const ResourceInput = &.{},
    optimize: std.builtin.OptimizeMode = .ReleaseSmall,
};

pub const R4XCOptions = struct {
    name: []const u8,
    source_root: std.Build.LazyPath,
    sources: []const []const u8,
    include_root: std.Build.LazyPath,
    startup_source_file: std.Build.LazyPath,
    linker_script: std.Build.LazyPath,
    builder: *std.Build.Step.Compile,
    app_class: []const u8 = "auto",
    imports: []const []const u8 = &.{},
    extra_include_roots: []const std.Build.LazyPath = &.{},
    c_defines: []const module_manifest.CDefineEntry = &.{},
    c_flags: []const []const u8 = &.{},
    // Modulversion aus module.R4MF; null bei Aufrufern ohne Manifest.
    module_version: ?[]const u8 = null,
    metadata: []const []const u8 = &.{},
    resources: []const ResourceInput = &.{},
    optimize: std.builtin.OptimizeMode = .ReleaseSmall,
};

pub const R4CAppBuildOptions = struct {
    name: []const u8,
    source_root: std.Build.LazyPath,
    sources: []const []const u8,
    include_root: std.Build.LazyPath,
    startup_source_file: std.Build.LazyPath,
    linker_script: std.Build.LazyPath,
    builder: *std.Build.Step.Compile,
    profile: AppProfile,
    imports: []const []const u8 = &.{},
    extra_include_roots: []const std.Build.LazyPath = &.{},
    c_defines: []const module_manifest.CDefineEntry = &.{},
    c_flags: []const []const u8 = &.{},
    // Modulversion aus module.R4MF; null bei Aufrufern ohne Manifest.
    module_version: ?[]const u8 = null,
    metadata: []const []const u8 = &.{},
    resources: []const ResourceInput = &.{},
    optimize: std.builtin.OptimizeMode = .ReleaseSmall,
};

pub const R4DOptions = struct {
    // Modulversion aus module.R4MF; null bei Aufrufern ohne Manifest.
    module_version: ?[]const u8 = null,
    name: []const u8,
    driver_name: []const u8,
    driver_type: []const u8 = "misc",
    root_source_file: std.Build.LazyPath,
    r4os_module: std.Build.LazyPath,
    contract_module: *std.Build.Module,
    linker_script: std.Build.LazyPath,
    builder: *std.Build.Step.Compile,
    resources: []const ResourceInput = &.{},
    optimize: std.builtin.OptimizeMode = .ReleaseSmall,
};

pub const R4POptions = struct {
    // Modulversion aus module.R4MF; null bei Aufrufern ohne Manifest.
    module_version: ?[]const u8 = null,
    name: []const u8,
    protocol_name: []const u8,
    role: []const u8,
    category: []const u8 = "misc",
    dependencies: []const []const u8 = &.{},
    metadata: []const []const u8 = &.{},
    root_source_file: std.Build.LazyPath,
    r4os_module: std.Build.LazyPath,
    contract_module: *std.Build.Module,
    linker_script: std.Build.LazyPath,
    builder: *std.Build.Step.Compile,
    resources: []const ResourceInput = &.{},
    optimize: std.builtin.OptimizeMode = .ReleaseSmall,
};

pub const R4LRawOptions = struct {
    // Modulversion aus module.R4MF; null bei Aufrufern ohne Manifest.
    module_version: ?[]const u8 = null,
    name: []const u8,
    code: std.Build.LazyPath,
    rodata: ?std.Build.LazyPath = null,
    data: ?std.Build.LazyPath = null,
    builder: *std.Build.Step.Compile,
    bss_size: []const u8 = "0",
    imports: []const []const u8 = &.{},
    exports: []const []const u8 = &.{},
    relocations: []const []const u8 = &.{},
    metadata: []const []const u8 = &.{},
};

pub const R4MRawOptions = struct {
    name: []const u8,
    module_name: ?[]const u8 = null,
    kind: []const u8,
    extension: []const u8,
    code: std.Build.LazyPath,
    rodata: ?std.Build.LazyPath = null,
    data: ?std.Build.LazyPath = null,
    builder: *std.Build.Step.Compile,
    bss_size: []const u8 = "0",
    imports: []const []const u8 = &.{},
    exports: []const []const u8 = &.{},
    relocations: []const []const u8 = &.{},
    metadata: []const []const u8 = &.{},
    resources: []const ResourceInput = &.{},
    app_class: []const u8 = "auto",
};

pub const R4MElfOptions = struct {
    name: []const u8,
    module_name: ?[]const u8 = null,
    kind: []const u8,
    extension: []const u8,
    elf: std.Build.LazyPath,
    builder: *std.Build.Step.Compile,
    imports: []const []const u8 = &.{},
    exports: []const []const u8 = &.{},
    metadata: []const []const u8 = &.{},
    resources: []const ResourceInput = &.{},
    app_class: []const u8 = "auto",
};

pub fn addR4XBuilder(b: *std.Build, root_source_file: std.Build.LazyPath) *std.Build.Step.Compile {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "r4xbuilder",
        .root_module = b.createModule(.{
            .root_source_file = root_source_file,
            .target = target,
            .optimize = optimize,
        }),
    });
    return exe;
}

pub fn addR4LContractGenerator(b: *std.Build, root_source_file: std.Build.LazyPath) *std.Build.Step.Compile {
    return b.addExecutable(.{
        .name = "r4l-contract-gen",
        .root_module = b.createModule(.{
            .root_source_file = root_source_file,
            .target = b.graph.host,
            .optimize = .ReleaseSafe,
        }),
    });
}

// Reihenfolge und Inhalt muessen mit module_manifest.derivePlan uebereinstimmen -
// dort entsteht derselbe Block fuer den Plan, hier fuer den tatsaechlichen Build.
// module.version steht deshalb an beiden Stellen an dritter Position.
fn buildR4XMetadata(b: *std.Build, name: []const u8, app_class: []const u8, module_version: ?[]const u8, extra: []const []const u8) []const []const u8 {
    const has_profile = hasMetadataPrefix(extra, "memory.profile=");
    const default_profile_count: usize = if (has_profile) 0 else 1;
    const version_count: usize = if (module_version == null) 0 else 1;
    const count: usize = 7 + version_count + extra.len + default_profile_count;
    const metadata = b.allocator.alloc([]const u8, count) catch @panic("OOM");
    var index: usize = 0;
    metadata[index] = b.fmt("r4x.name={s}", .{name});
    index += 1;
    metadata[index] = b.fmt("r4x.class={s}", .{app_class});
    index += 1;
    if (module_version) |value| {
        metadata[index] = b.fmt("module.version={s}", .{value});
        index += 1;
    }
    metadata[index] = "feature=program-module";
    index += 1;
    metadata[index] = "r4x.start=r4xstart";
    index += 1;
    metadata[index] = "r4x.entry=R4XStart";
    index += 1;
    metadata[index] = "r4x.start_abi=1";
    index += 1;
    metadata[index] = "r4x.context=R4XStartContext";
    index += 1;
    if (!has_profile) {
        metadata[index] = b.fmt("memory.profile={s}", .{defaultMemoryProfileForClass(app_class)});
        index += 1;
    }
    for (extra) |entry| {
        metadata[index] = entry;
        index += 1;
    }
    return metadata;
}

fn defaultMemoryProfileForClass(app_class: []const u8) []const u8 {
    if (std.ascii.eqlIgnoreCase(app_class, "service")) return "service";
    if (std.ascii.eqlIgnoreCase(app_class, "gui")) return "desktop";
    return "normal";
}

fn hasMetadataPrefix(entries: []const []const u8, prefix: []const u8) bool {
    for (entries) |entry| {
        if (std.mem.startsWith(u8, entry, prefix)) return true;
    }
    return false;
}

fn addR4XStartWithOptions(b: *std.Build, opts: R4XOptions) BuildResult {
    const elf = addRawModule(b, .{
        .name = opts.name,
        .root_source_file = opts.root_source_file,
        .r4os_module = opts.r4os_module,
        .contract_module = opts.contract_module,
        .version_module = opts.version_module,
        .linker_script = opts.linker_script,
        .entry_symbol = "r4xstart_entry",
        .zig_modules = opts.zig_modules,
        .optimize = opts.optimize,
    });

    const exports = b.allocator.alloc([]const u8, 1) catch @panic("OOM");
    exports[0] = "R4XStart:.text:0:1";
    const metadata = buildR4XMetadata(b, opts.name, opts.app_class, opts.module_version, opts.metadata);

    return addR4MElf(b, .{
        .name = opts.name,
        .module_name = b.fmt("R4X_{s}", .{opts.name}),
        .kind = "r4x",
        .extension = "R4X",
        .elf = elf,
        .builder = opts.builder,
        .imports = opts.imports,
        .exports = exports,
        .metadata = metadata,
        .app_class = opts.app_class,
        .resources = opts.resources,
    });
}

fn addR4AppWithOptions(b: *std.Build, opts: R4AppBuildOptions) BuildResult {
    const app_class = appClassForProfile(opts.profile);
    const elf = addRawModule(b, .{
        .name = opts.name,
        .root_source_file = opts.startup_source_file,
        .app_source_file = opts.root_source_file,
        .app_profile = opts.profile,
        .zig_modules = opts.zig_modules,
        .r4os_module = opts.r4os_module,
        .contract_module = opts.contract_module,
        .version_module = opts.version_module,
        .linker_script = opts.linker_script,
        .entry_symbol = "R4XStart",
        .optimize = opts.optimize,
    });
    return packageR4App(b, opts.name, app_class, opts.imports, opts.module_version, opts.metadata, opts.builder, elf, opts.resources);
}

fn addR4AppCWithOptions(b: *std.Build, opts: R4CAppBuildOptions) BuildResult {
    const app_class = appClassForProfile(opts.profile);
    const elf = addCModule(b, .{
        .name = opts.name,
        .source_root = opts.source_root,
        .sources = opts.sources,
        .include_root = opts.include_root,
        .extra_include_roots = opts.extra_include_roots,
        .c_defines = opts.c_defines,
        .c_flags = opts.c_flags,
        .startup_source_file = opts.startup_source_file,
        .linker_script = opts.linker_script,
        .optimize = opts.optimize,
        .app_profile = opts.profile,
    });
    return packageR4App(b, opts.name, app_class, opts.imports, opts.module_version, opts.metadata, opts.builder, elf, opts.resources);
}

fn packageR4App(b: *std.Build, name: []const u8, app_class: []const u8, manifest_imports: []const []const u8, module_version: ?[]const u8, extra_metadata: []const []const u8, builder: *std.Build.Step.Compile, elf: std.Build.LazyPath, resources: []const ResourceInput) BuildResult {
    const exports = b.allocator.alloc([]const u8, 1) catch @panic("OOM");
    exports[0] = "R4XStart:.text:0:1";
    return addR4MElf(b, .{
        .name = name,
        .module_name = b.fmt("R4X_{s}", .{name}),
        .kind = "r4x",
        .extension = "R4X",
        .elf = elf,
        .builder = builder,
        .imports = manifest_imports,
        .exports = exports,
        .metadata = buildR4XMetadata(b, name, app_class, module_version, extra_metadata),
        .app_class = app_class,
        .resources = resources,
    });
}

fn appClassForProfile(profile: AppProfile) []const u8 {
    return switch (profile) {
        .console => "console",
        .desktop => "gui",
        .service => "service",
    };
}

pub fn addR4XStart(b: *std.Build, opts: R4XOptions) BuildResult {
    return addR4XStartWithOptions(b, opts);
}

pub fn addR4XStartC(b: *std.Build, opts: R4XCOptions) BuildResult {
    return addR4XStartCWithOptions(b, opts);
}

fn addR4XStartCWithOptions(b: *std.Build, opts: R4XCOptions) BuildResult {
    const elf = addCModule(b, .{
        .name = opts.name,
        .source_root = opts.source_root,
        .sources = opts.sources,
        .include_root = opts.include_root,
        .extra_include_roots = opts.extra_include_roots,
        .c_defines = opts.c_defines,
        .c_flags = opts.c_flags,
        .startup_source_file = opts.startup_source_file,
        .linker_script = opts.linker_script,
        .optimize = opts.optimize,
    });

    const exports = b.allocator.alloc([]const u8, 1) catch @panic("OOM");
    exports[0] = "R4XStart:.text:0:1";
    const metadata = buildR4XMetadata(b, opts.name, opts.app_class, opts.module_version, opts.metadata);

    return addR4MElf(b, .{
        .name = opts.name,
        .module_name = b.fmt("R4X_{s}", .{opts.name}),
        .kind = "r4x",
        .extension = "R4X",
        .elf = elf,
        .builder = opts.builder,
        .imports = opts.imports,
        .exports = exports,
        .metadata = metadata,
        .app_class = opts.app_class,
        .resources = opts.resources,
    });
}

pub fn addR4XService(b: *std.Build, opts: R4XOptions) BuildResult {
    var service_opts = opts;
    service_opts.app_class = "service";
    return addR4XStartWithOptions(b, service_opts);
}

pub fn addR4D(b: *std.Build, opts: R4DOptions) BuildResult {
    return addR4DWithOptions(b, opts);
}

fn addR4DWithOptions(b: *std.Build, opts: R4DOptions) BuildResult {
    const elf = addRawModule(b, .{
        .name = opts.name,
        .root_source_file = opts.root_source_file,
        .r4os_module = opts.r4os_module,
        .contract_module = opts.contract_module,
        .linker_script = opts.linker_script,
        .entry_symbol = "r4d_init_entry",
        .optimize = opts.optimize,
    });

    const imports = b.allocator.alloc([]const u8, 1) catch @panic("OOM");
    imports[0] = "R4DEV:Query:1";
    const exports = b.allocator.alloc([]const u8, 2) catch @panic("OOM");
    exports[0] = "DriverInit:.text:0:1";
    exports[1] = "DriverShutdown:.text:5:1";
    const version_count: usize = if (opts.module_version == null) 0 else 1;
    const metadata = b.allocator.alloc([]const u8, 2 + version_count) catch @panic("OOM");
    metadata[0] = b.fmt("r4d.name={s}", .{opts.driver_name});
    metadata[1] = b.fmt("r4d.type={s}", .{opts.driver_type});
    if (opts.module_version) |value| metadata[2] = b.fmt("module.version={s}", .{value});

    return addR4MElf(b, .{
        .name = opts.name,
        .module_name = b.fmt("R4D_{s}", .{opts.name}),
        .kind = "r4d",
        .extension = "R4D",
        .elf = elf,
        .builder = opts.builder,
        .imports = imports,
        .exports = exports,
        .metadata = metadata,
        .resources = opts.resources,
    });
}

pub fn addR4P(b: *std.Build, opts: R4POptions) BuildResult {
    return addR4PWithOptions(b, opts);
}

fn addR4PWithOptions(b: *std.Build, opts: R4POptions) BuildResult {
    const elf = addRawModule(b, .{
        .name = opts.name,
        .root_source_file = opts.root_source_file,
        .r4os_module = opts.r4os_module,
        .contract_module = opts.contract_module,
        .linker_script = opts.linker_script,
        .entry_symbol = "r4p_init_entry",
        .optimize = opts.optimize,
    });

    const imports = b.allocator.alloc([]const u8, 1) catch @panic("OOM");
    imports[0] = "R4DEV:Query:1";
    const exports = b.allocator.alloc([]const u8, 5) catch @panic("OOM");
    exports[0] = "ProtocolInit:.text:0:1";
    exports[1] = "ProtocolShutdown:.text:5:1";
    exports[2] = "ProtocolQuery:.text:10:1";
    exports[3] = "ProtocolDispatch:.text:15:1";
    exports[4] = "ProtocolRole:.text:0:1";

    const version_count: usize = if (opts.module_version == null) 0 else 1;
    const metadata_count = 3 + version_count + opts.dependencies.len + opts.metadata.len;
    const metadata = b.allocator.alloc([]const u8, metadata_count) catch @panic("OOM");
    var meta_index: usize = 0;
    metadata[meta_index] = b.fmt("r4p.name={s}", .{opts.protocol_name});
    meta_index += 1;
    if (opts.module_version) |value| {
        metadata[meta_index] = b.fmt("module.version={s}", .{value});
        meta_index += 1;
    }
    metadata[meta_index] = b.fmt("r4p.role={s}", .{opts.role});
    meta_index += 1;
    metadata[meta_index] = b.fmt("r4p.category={s}", .{opts.category});
    meta_index += 1;
    for (opts.dependencies) |dependency| {
        metadata[meta_index] = b.fmt("r4p.dep={s}", .{dependency});
        meta_index += 1;
    }
    for (opts.metadata) |entry| {
        metadata[meta_index] = entry;
        meta_index += 1;
    }

    return addR4MElf(b, .{
        .name = opts.name,
        .module_name = b.fmt("R4P_{s}", .{opts.name}),
        .kind = "r4p",
        .extension = "R4P",
        .elf = elf,
        .builder = opts.builder,
        .imports = imports,
        .exports = exports,
        .metadata = metadata,
        .resources = opts.resources,
    });
}

pub fn addR4LRaw(b: *std.Build, opts: R4LRawOptions) BuildResult {
    return addR4LRawWithOptions(b, opts);
}

fn addR4LRawWithOptions(b: *std.Build, opts: R4LRawOptions) BuildResult {
    var metadata = opts.metadata;
    if (opts.module_version) |value| {
        const erweitert = b.allocator.alloc([]const u8, opts.metadata.len + 1) catch @panic("OOM");
        erweitert[0] = b.fmt("module.version={s}", .{value});
        for (opts.metadata, 0..) |entry, i| erweitert[i + 1] = entry;
        metadata = erweitert;
    }
    return addR4MRaw(b, .{
        .name = opts.name,
        .kind = "r4l",
        .extension = "R4L",
        .code = opts.code,
        .rodata = opts.rodata,
        .data = opts.data,
        .builder = opts.builder,
        .bss_size = opts.bss_size,
        .imports = opts.imports,
        .exports = opts.exports,
        .relocations = opts.relocations,
        .metadata = metadata,
    });
}

pub fn addR4MRaw(b: *std.Build, opts: R4MRawOptions) BuildResult {
    const run = b.addRunArtifact(opts.builder);
    run.stdio = .inherit;
    run.addArgs(&.{ "--r4m", "--kind", opts.kind, "--name", opts.module_name orelse opts.name, "--output" });
    const output = run.addOutputFileArg(b.fmt("{s}.{s}", .{ opts.name, opts.extension }));
    run.addArgs(&.{"--code"});
    run.addFileArg(opts.code);
    if (opts.rodata) |rodata| {
        run.addArgs(&.{"--rodata"});
        run.addFileArg(rodata);
    }
    if (opts.data) |data| {
        run.addArgs(&.{"--data"});
        run.addFileArg(data);
    }
    if (!std.mem.eql(u8, opts.bss_size, "0")) {
        run.addArgs(&.{ "--bss-size", opts.bss_size });
    }
    if (std.mem.eql(u8, opts.kind, "r4x")) {
        run.addArgs(&.{ "--app-class", opts.app_class });
    }
    for (opts.imports) |entry| {
        run.addArgs(&.{ "--import", entry });
    }
    for (opts.exports) |entry| {
        run.addArgs(&.{ "--export", entry });
    }
    for (opts.relocations) |entry| {
        run.addArgs(&.{ "--reloc", entry });
    }
    for (opts.metadata) |entry| {
        run.addArgs(&.{ "--meta", entry });
    }
    // Ressourcen als Datei-Args: Zig trackt sie damit als Buildinputs, eine
    // geaenderte Ressource baut das Modul neu.
    for (opts.resources) |resource| {
        switch (resource.kind) {
            .icon => run.addArgs(&.{"--icon"}),
            .help => run.addArgs(&.{"--help-file"}),
            .file => run.addArgs(&.{ "--resource", resource.name }),
        }
        run.addFileArg(resource.path);
    }

    const install = b.addInstallFile(output, b.fmt("{s}.{s}", .{ opts.name, opts.extension }));
    b.getInstallStep().dependOn(&install.step);

    return .{ .code = opts.code, .output = output };
}

pub fn addR4MElf(b: *std.Build, opts: R4MElfOptions) BuildResult {
    const run = b.addRunArtifact(opts.builder);
    run.stdio = .inherit;
    run.addArgs(&.{ "--r4m", "--kind", opts.kind, "--name", opts.module_name orelse opts.name, "--output" });
    const output = run.addOutputFileArg(b.fmt("{s}.{s}", .{ opts.name, opts.extension }));
    run.addArgs(&.{"--elf"});
    run.addFileArg(opts.elf);
    if (std.mem.eql(u8, opts.kind, "r4x")) {
        run.addArgs(&.{ "--app-class", opts.app_class });
    }
    for (opts.imports) |entry| {
        run.addArgs(&.{ "--import", entry });
    }
    for (opts.exports) |entry| {
        run.addArgs(&.{ "--export", entry });
    }
    for (opts.metadata) |entry| {
        run.addArgs(&.{ "--meta", entry });
    }
    // Ressourcen als Datei-Args: Zig trackt sie damit als Buildinputs, eine
    // geaenderte Ressource baut das Modul neu.
    for (opts.resources) |resource| {
        switch (resource.kind) {
            .icon => run.addArgs(&.{"--icon"}),
            .help => run.addArgs(&.{"--help-file"}),
            .file => run.addArgs(&.{ "--resource", resource.name }),
        }
        run.addFileArg(resource.path);
    }

    const install = b.addInstallFile(output, b.fmt("{s}.{s}", .{ opts.name, opts.extension }));
    b.getInstallStep().dependOn(&install.step);

    return .{ .code = opts.elf, .output = output };
}

const RawOptions = struct {
    name: []const u8,
    root_source_file: std.Build.LazyPath,
    r4os_module: std.Build.LazyPath,
    contract_module: *std.Build.Module,
    version_module: ?std.Build.LazyPath = null,
    linker_script: std.Build.LazyPath,
    entry_symbol: []const u8,
    optimize: std.builtin.OptimizeMode,
    app_source_file: ?std.Build.LazyPath = null,
    app_profile: ?AppProfile = null,
    zig_modules: []const ZigModuleBuild = &.{},
    /// Zusaetzliche C-Quellen eines gemischten Zig/R4L-Projekts. Die
    /// Manifestreihenfolge bleibt erhalten; Include-Wurzeln sind aus den
    /// jeweiligen Quellverzeichnissen abgeleitet.
    c_source_files: []const std.Build.LazyPath = &.{},
    c_include_roots: []const std.Build.LazyPath = &.{},
    c_defines: []const module_manifest.CDefineEntry = &.{},
    c_flags: []const []const u8 = &.{},
};

const COptions = struct {
    name: []const u8,
    source_root: std.Build.LazyPath,
    sources: []const []const u8,
    include_root: std.Build.LazyPath,
    extra_include_roots: []const std.Build.LazyPath = &.{},
    c_defines: []const module_manifest.CDefineEntry = &.{},
    c_flags: []const []const u8 = &.{},
    startup_source_file: ?std.Build.LazyPath,
    linker_script: std.Build.LazyPath,
    entry_symbol: []const u8 = "R4XStart",
    strip: bool = true,
    emit_relocs: bool = false,
    optimize: std.builtin.OptimizeMode,
    app_profile: ?AppProfile = null,
};

fn addRawModule(b: *std.Build, opts: RawOptions) std.Build.LazyPath {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
        .abi = .none,
        .ofmt = .elf,
        .cpu_features_add = std.Target.x86.featureSet(&.{
            .mmx, .sse, .sse2, .sse3, .ssse3, .sse4_1, .sse4_2, .avx, .avx2, .aes, .pclmul,
        }),
    });

    const exe = b.addExecutable(.{
        .name = b.fmt("{s}.elf", .{opts.name}),
        .root_module = b.createModule(.{
            .root_source_file = opts.root_source_file,
            .target = target,
            .optimize = opts.optimize,
            .single_threaded = false,
            .strip = false,
            .pic = true,
            .red_zone = false,
            .sanitize_c = .off,
            .stack_check = false,
            .stack_protector = false,
        }),
    });
    exe.entry = .{ .symbol_name = opts.entry_symbol };
    exe.link_emit_relocs = true;
    for (opts.c_include_roots) |include_root| exe.root_module.addIncludePath(include_root);
    for (opts.c_defines) |entry| exe.root_module.addCMacro(entry.name, entry.value);
    const base_c_flags: []const []const u8 = &.{
        "-std=c11",
        "-ffreestanding",
        "-fno-builtin",
        "-fno-stack-protector",
        "-fno-unwind-tables",
        "-fno-asynchronous-unwind-tables",
        "-mno-red-zone",
        "-msse2",
        "-mavx2",
        "-maes",
        "-mpclmul",
    };
    const c_flags = b.allocator.alloc([]const u8, base_c_flags.len + opts.c_flags.len) catch @panic("OOM");
    for (base_c_flags, 0..) |flag, index| c_flags[index] = flag;
    for (opts.c_flags, base_c_flags.len..) |flag, index| c_flags[index] = flag;
    for (opts.c_source_files) |source_file| {
        exe.root_module.addCSourceFile(.{
            .file = source_file,
            .flags = c_flags,
        });
    }
    const r4os_module = b.createModule(.{
        .root_source_file = opts.r4os_module,
        .target = target,
        .optimize = opts.optimize,
        .single_threaded = false,
        .strip = false,
        .red_zone = false,
        .sanitize_c = .off,
        .stack_check = false,
        .stack_protector = false,
    });
    r4os_module.addImport("r4os_contract", opts.contract_module);
    exe.root_module.addImport("r4os", r4os_module);
    const dependencies = b.allocator.alloc(*std.Build.Module, opts.zig_modules.len) catch @panic("OOM");
    for (opts.zig_modules, 0..) |module, index| {
        dependencies[index] = b.createModule(.{
            .root_source_file = module.root_source_file,
            .target = target,
            .optimize = opts.optimize,
            .single_threaded = false,
            .strip = false,
            .red_zone = false,
            .sanitize_c = .off,
            .stack_check = false,
            .stack_protector = false,
        });
        dependencies[index].addImport("r4os", r4os_module);
    }
    for (dependencies, 0..) |dependency, index| {
        for (opts.zig_modules, 0..) |other, other_index| {
            if (index != other_index) dependency.addImport(other.name, dependencies[other_index]);
        }
        if (opts.app_source_file == null) exe.root_module.addImport(opts.zig_modules[index].name, dependency);
    }
    if (opts.app_source_file) |source_file| {
        const app_module = b.createModule(.{
            .root_source_file = source_file,
            .target = target,
            .optimize = opts.optimize,
            .single_threaded = false,
            .strip = false,
            .red_zone = false,
            .sanitize_c = .off,
            .stack_check = false,
            .stack_protector = false,
        });
        app_module.addImport("r4os", r4os_module);
        for (opts.zig_modules, 0..) |module, index| app_module.addImport(module.name, dependencies[index]);
        exe.root_module.addImport("r4_app_source", app_module);
        const app_options = b.addOptions();
        app_options.addOption(u8, "profile", @intFromEnum(opts.app_profile.?));
        exe.root_module.addOptions("r4_app_options", app_options);
    }
    if (opts.version_module) |version_module| {
        exe.root_module.addImport("r4os_version", b.createModule(.{
            .root_source_file = version_module,
            .target = target,
            .optimize = opts.optimize,
            .single_threaded = false,
            .strip = false,
            .red_zone = false,
            .sanitize_c = .off,
            .stack_check = false,
            .stack_protector = false,
        }));
    }
    exe.setLinkerScript(opts.linker_script);
    return exe.getEmittedBin();
}

fn addCModule(b: *std.Build, opts: COptions) std.Build.LazyPath {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .x86_64,
        .os_tag = .freestanding,
        .abi = .none,
        .ofmt = .elf,
        .cpu_features_add = std.Target.x86.featureSet(&.{
            .mmx, .sse, .sse2, .sse3, .ssse3, .sse4_1, .sse4_2, .avx, .avx2, .aes, .pclmul,
        }),
    });

    const c_mod = b.createModule(.{
        .target = target,
        .optimize = opts.optimize,
        .single_threaded = false,
        .strip = opts.strip,
        .pic = true,
        .red_zone = false,
        .sanitize_c = .off,
        .stack_check = false,
        .stack_protector = false,
        .link_libc = false,
    });
    const base_c_flags: []const []const u8 = &.{
        "-std=c11",
        "-ffreestanding",
        "-fno-builtin",
        "-fno-stack-protector",
        "-fno-unwind-tables",
        "-fno-asynchronous-unwind-tables",
        "-mno-red-zone",
        "-msse2",
        "-mavx2",
        "-maes",
        "-mpclmul",
    };
    const profile_flag_count: usize = if (opts.app_profile != null) 1 else 0;
    const c_flags = b.allocator.alloc([]const u8, base_c_flags.len + profile_flag_count + opts.c_flags.len) catch @panic("OOM");
    for (base_c_flags, 0..) |flag, index| c_flags[index] = flag;
    if (opts.app_profile) |profile| c_flags[base_c_flags.len] = b.fmt("-DR4OS_APP_PROFILE={d}", .{@intFromEnum(profile)});
    for (opts.c_flags, base_c_flags.len + profile_flag_count..) |flag, index| c_flags[index] = flag;
    c_mod.addIncludePath(opts.include_root);
    for (opts.extra_include_roots) |include_root| c_mod.addIncludePath(include_root);
    for (opts.c_defines) |entry| c_mod.addCMacro(entry.name, entry.value);
    if (opts.startup_source_file) |startup_source_file| {
        c_mod.addCSourceFile(.{
            .file = startup_source_file,
            .flags = c_flags,
        });
    }
    c_mod.addCSourceFiles(.{
        .root = opts.source_root,
        .files = opts.sources,
        .flags = c_flags,
    });
    const exe = b.addExecutable(.{
        .name = b.fmt("{s}.elf", .{opts.name}),
        .root_module = c_mod,
    });
    exe.entry = .{ .symbol_name = opts.entry_symbol };
    exe.link_emit_relocs = opts.emit_relocs;
    exe.setLinkerScript(opts.linker_script);
    return exe.getEmittedBin();
}

fn lazyPathOption(b: *std.Build, name: []const u8, description: []const u8) ?std.Build.LazyPath {
    const raw = b.option([]const u8, name, description) orelse return null;
    return userPath(b, raw);
}

fn userPath(b: *std.Build, raw: []const u8) std.Build.LazyPath {
    if (std.fs.path.isAbsolute(raw)) {
        return .{ .cwd_relative = raw };
    }
    return .{ .cwd_relative = b.pathResolve(&.{ b.build_root.path orelse ".", raw }) };
}
