const std = @import("std");
const manifest = @import("contract_bundle").r4mf;
const capabilities = manifest.capabilities;
const Value = std.json.Value;

const Rule = struct {
    platform_generation: u8,
    language: []const u8,
    kind: []const u8,
    app_class: ?[]const u8,
    entry_mode: ?[]const u8,
    role: ?[]const u8,
    execution: []const u8,
    hosts: []const []const u8,
    supported: bool,
    code: []const u8,
    reason: []const u8,
    owner_contract: []const u8,
    missing_steps: []const []const u8,
    source_count: ?u32 = null,
    exact_imports: []const []const u8 = &.{},
    language_subset: ?[]const u8 = null,
};
const File = struct { source: []const u8, target: []const u8, sha256: []const u8 };
const Template = struct {
    id: []const u8,
    display_name: []const u8,
    description: []const u8,
    default_name: []const u8,
    language: []const u8,
    kind: []const u8,
    platform_generation: u8,
    build_profile: []const u8,
    exports: []const []const u8,
    derived_metadata: ?[]const []const u8,
    app_class: ?[]const u8,
    entry_mode: ?[]const u8,
    role: ?[]const u8,
    execution: []const u8,
    target: []const u8,
    module_version: []const u8,
    facts_are_sample_expansion: bool = true,
    imports: []const []const u8,
    metadata: []const []const u8,
    resources: []const manifest.ResourceEntry,
    icons: []const []const u8,
    help: ?[]const u8,
    supported: bool,
    reason_code: []const u8,
    files: []const File,
    input_tokens: []const []const u8,
    creator: ?[]const u8,
    required_components: []const []const u8,
};

fn object(v: Value, key: []const u8) !Value {
    if (v != .object) return error.CapabilityProfileInvalid;
    return v.object.get(key) orelse error.CapabilityProfileInvalid;
}
fn string(v: Value) ![]const u8 {
    if (v != .string) return error.CapabilityProfileInvalid;
    return v.string;
}
fn readJson(a: std.mem.Allocator, io: std.Io, cwd: std.Io.Dir, path: []const u8) !Value {
    const bytes = try cwd.readFileAlloc(io, path, a, .limited(8 * 1024 * 1024));
    return std.json.parseFromSliceLeaky(Value, a, bytes, .{ .allocate = .alloc_always });
}
fn hash(a: std.mem.Allocator, bytes: []const u8) ![]const u8 {
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes, &digest, .{});
    return a.dupe(u8, &std.fmt.bytesToHex(digest, .lower));
}
fn relative(a: std.mem.Allocator, root: []const u8, path: []const u8) ![]const u8 {
    if (std.fs.path.isAbsolute(path) or std.mem.indexOfScalar(u8, path, '\\') != null) return error.CapabilityInputPath;
    var parts = std.mem.splitScalar(u8, path, '/');
    while (parts.next()) |part| {
        if (std.mem.eql(u8, part, "..") or std.mem.eql(u8, part, ".")) return error.CapabilityInputPath;
    }
    return std.fs.path.join(a, &.{ root, path });
}
fn addRule(a: std.mem.Allocator, list: *std.ArrayList(Rule), request: capabilities.Request) !void {
    const d = capabilities.query(request);
    const native_c = request.execution == .native_r4os and std.mem.eql(u8, request.language, "C");
    const imports: []const []const u8 = if (native_c and request.platform_generation == 2)
        (if (std.mem.eql(u8, request.app_class orelse "", "gui")) &.{ "R4SYS:Query2:2", "R4DESK:Query2:2", "R4DRAW:Query2:2" } else &.{ "R4SYS:Query2:2", "R4DESK:Query2:2" })
    else
        &.{};
    try list.append(a, .{ .platform_generation = request.platform_generation, .language = request.language, .kind = request.kind, .app_class = request.app_class, .entry_mode = request.entry_mode, .role = request.role, .execution = @tagName(request.execution), .hosts = if (request.execution == .host) &.{ "Linux", "Windows" } else &.{"R4OS"}, .supported = d.supported, .code = d.code, .reason = d.reason, .owner_contract = d.owner_contract, .missing_steps = d.missing_steps, .source_count = if (native_c) 1 else null, .exact_imports = imports, .language_subset = if (native_c) "R4CC C subset" else null });
}
fn rules(a: std.mem.Allocator) ![]const Rule {
    var list: std.ArrayList(Rule) = .empty;
    for (std.meta.tags(manifest.Language)) |language_tag| {
        const language = language_tag.text();
        for (std.meta.tags(manifest.Kind)) |kind_tag| {
            const kind = kind_tag.text();
            for (std.meta.tags(capabilities.Execution)) |execution| {
                if (std.mem.eql(u8, kind, "R4X")) {
                    for (std.meta.tags(manifest.AppClass)) |class_tag| for (std.meta.tags(manifest.EntryMode)) |entry_tag| {
                        const class = class_tag.text();
                        const entry = entry_tag.text();
                        try addRule(a, &list, .{ .language = language, .kind = kind, .app_class = class, .entry_mode = entry, .execution = execution });
                        if (std.mem.eql(u8, class, "gui")) try addRule(a, &list, .{ .language = language, .kind = kind, .app_class = class, .entry_mode = entry, .role = "subsystem", .execution = execution });
                    };
                } else try addRule(a, &list, .{ .language = language, .kind = kind, .execution = execution });
            }
        }
    }
    return list.toOwnedSlice(a);
}
fn tokens(a: std.mem.Allocator, list: *std.ArrayList([]const u8), text: []const u8) !void {
    var offset: usize = 0;
    while (std.mem.indexOfScalarPos(u8, text, offset, '{')) |start| {
        const end = std.mem.indexOfScalarPos(u8, text, start + 1, '}') orelse break;
        offset = start + 1;
        const name = text[start + 1 .. end];
        if (name.len == 0 or name.len > 64) continue;
        var valid = true;
        for (name) |c| {
            if (!std.ascii.isAlphabetic(c)) {
                valid = false;
                break;
            }
        }
        if (!valid) continue;
        var known = false;
        for (list.items) |prior| {
            if (std.mem.eql(u8, prior, name)) {
                known = true;
                break;
            }
        }
        if (!known) try list.append(a, try a.dupe(u8, name));
    }
}
fn templates(a: std.mem.Allocator, io: std.Io, cwd: std.Io.Dir, root: []const u8) ![]const Template {
    var dir = try cwd.openDir(io, root, .{ .iterate = true });
    defer dir.close(io);
    var walker = try dir.walk(a);
    defer walker.deinit();
    var paths: std.ArrayList([]const u8) = .empty;
    while (try walker.next(io)) |entry| {
        if (entry.kind == .file and std.mem.eql(u8, std.fs.path.basename(entry.path), "template.ini")) try paths.append(a, try a.dupe(u8, entry.path));
    }
    std.mem.sort([]const u8, paths.items, {}, struct {
        fn less(_: void, x: []const u8, y: []const u8) bool {
            return std.mem.lessThan(u8, x, y);
        }
    }.less);
    var result: std.ArrayList(Template) = .empty;
    for (paths.items) |ini| {
        const full = try std.fs.path.join(a, &.{ root, ini });
        const base = std.fs.path.dirname(full).?;
        const text = try cwd.readFileAlloc(io, full, a, .limited(128 * 1024));
        var meta = std.StringHashMap([]const u8).init(a);
        var mappings: std.ArrayList([]const u8) = .empty;
        var lines = std.mem.splitScalar(u8, text, '\n');
        while (lines.next()) |raw| {
            const line = std.mem.trim(u8, raw, " \t\r");
            if (line.len == 0 or line[0] == '#' or line[0] == '[') continue;
            const eq = std.mem.indexOfScalar(u8, line, '=') orelse return error.TemplateMetadataInvalid;
            const key = line[0..eq];
            const value = line[eq + 1 ..];
            if (std.mem.eql(u8, key, "File")) try mappings.append(a, value) else {
                if (meta.contains(key)) return error.TemplateDuplicateMetadata;
                try meta.put(key, value);
            }
        }
        const id = meta.get("Id") orelse return error.TemplateMetadataInvalid;
        for (result.items) |prior| {
            if (std.mem.eql(u8, prior.id, id)) return error.TemplateDuplicateId;
        }
        const default_name = meta.get("DefaultProjectName") orelse return error.TemplateMetadataInvalid;
        const manifest_source = meta.get("ProjectFileTemplate") orelse return error.TemplateMetadataInvalid;
        const manifest_path = try std.fs.path.join(a, &.{ base, manifest_source });
        const raw_manifest = try cwd.readFileAlloc(io, manifest_path, a, .limited(manifest.max_manifest_bytes));
        var rendered = try std.mem.replaceOwned(u8, a, raw_manifest, "{ProjectName}", default_name);
        const lower = try a.dupe(u8, default_name);
        for (lower) |*byte| {
            byte.* = std.ascii.toLower(byte.*);
        }
        rendered = try std.mem.replaceOwned(u8, a, rendered, "{ProjectNameLower}", lower);
        rendered = try std.mem.replaceOwned(u8, a, rendered, "{Version}", "0.1.0");
        rendered = try std.mem.replaceOwned(u8, a, rendered, "{ImageScope}", "none");
        const sample_target = try std.fmt.allocPrint(a, "/R4OS/LIBS/{s}.R4L", .{default_name});
        rendered = try std.mem.replaceOwned(u8, a, rendered, "{Target}", sample_target);
        const m = try manifest.parse(a, try std.fs.path.join(a, &.{ base, "module.R4MF" }), rendered);
        // Native legacy templates have the two established manifest/source
        // files. New host definitions explicitly own their complete file map.
        if (mappings.items.len == 0) {
            try mappings.append(a, try std.fmt.allocPrint(a, "{s}|module.R4MF", .{manifest_source}));
            for (m.sources) |source| try mappings.append(a, try std.fmt.allocPrint(a, "{s}.template|{s}", .{ source, source }));
        }
        var files: std.ArrayList(File) = .empty;
        var fields: std.ArrayList([]const u8) = .empty;
        for (mappings.items) |mapping| {
            const sep = std.mem.indexOfScalar(u8, mapping, '|') orelse return error.TemplateFileMapInvalid;
            const source = try std.fs.path.resolve(a, &.{ base, mapping[0..sep] });
            const rel = try std.fs.path.relative(a, root, null, root, source);
            for (rel) |*byte| {
                if (byte.* == '\\') byte.* = '/';
            }
            const checked = try relative(a, root, rel);
            const contents = try cwd.readFileAlloc(io, checked, a, .limited(2 * 1024 * 1024));
            try files.append(a, .{ .source = rel, .target = mapping[sep + 1 ..], .sha256 = try hash(a, contents) });
            try tokens(a, &fields, contents);
        }
        const execution = meta.get("Execution") orelse "native_r4os";
        const request = capabilities.Request{ .platform_generation = m.platform_generation, .language = m.language.?.text(), .kind = m.kind.text(), .app_class = if (m.app_class) |c| c.text() else null, .entry_mode = if (m.entry_mode) |e| e.text() else null, .role = if (m.module_role) |r| r.text() else null, .execution = if (std.mem.eql(u8, execution, "host")) .host else .native_r4os };
        const d = capabilities.query(request);
        const plan = if (m.kind == .r4x) try manifest.derivePlan(a, m) else null;
        const rust = std.mem.eql(u8, request.language, "Rust");
        try result.append(a, .{ .id = id, .display_name = meta.get("DisplayName") orelse id, .description = meta.get("Description") orelse "", .default_name = default_name, .language = request.language, .kind = request.kind, .platform_generation = m.platform_generation, .build_profile = try manifest.sdkBuildProfile(m), .exports = try manifest.moduleExports(a, m), .derived_metadata = if (plan) |value| value.metadata else null, .app_class = request.app_class, .entry_mode = request.entry_mode, .role = request.role, .execution = execution, .target = m.target, .module_version = m.module_version.text, .imports = m.imports, .metadata = m.metadata, .resources = m.resources, .icons = m.icons, .help = m.help, .supported = d.supported, .reason_code = d.code, .files = try files.toOwnedSlice(a), .input_tokens = try fields.toOwnedSlice(a), .creator = if (request.execution == .host) "Tools/New-Project.ps1" else null, .required_components = if (rust and m.kind == .r4l) &.{ "SDK", "Contract", "r4os-rust-tools-v1", "r4l-contract-gen", "local-library-contract-baseline-conformance" } else if (rust) &.{ "SDK", "Contract", "r4os-rust-tools-v1" } else if (m.kind == .r4l) &.{ "SDK", "Contract", "zig-host", "r4l-contract-gen", "local-library-contract-baseline-conformance" } else if (request.execution == .host) &.{ "SDK", "Contract", "zig-host" } else &.{"native-r4build-r4cc"} });
    }
    return result.toOwnedSlice(a);
}

pub fn render(a: std.mem.Allocator, io: std.Io, cwd: std.Io.Dir, selected_profile: ?[]const u8) ![]const u8 {
    const profile_path = selected_profile orelse blk: {
        const executable = try std.process.executablePathAlloc(io, a);
        const host_dir = std.fs.path.dirname(executable) orelse return error.CapabilityProfileMissing;
        const bin = std.fs.path.dirname(host_dir) orelse return error.CapabilityProfileMissing;
        const root = std.fs.path.dirname(bin) orelse return error.CapabilityProfileMissing;
        break :blk try std.fs.path.join(a, &.{ root, "RustToolsProfile.json" });
    };
    const profile = readJson(a, io, cwd, profile_path) catch return error.CapabilityProfileMissing;
    if ((try object(profile, "schema")) != .integer or (try object(profile, "schema")).integer != 1 or !std.mem.eql(u8, try string(try object(profile, "id")), capabilities.rust_tools)) return error.CapabilityProfileInvalid;
    const root = try std.fs.path.resolve(a, &.{std.fs.path.dirname(profile_path) orelse "."});
    const inputs = try object(profile, "files");
    if (inputs != .array) return error.CapabilityProfileInvalid;
    for (inputs.array.items) |input| {
        const path = try relative(a, root, try string(try object(input, "path")));
        const bytes = try cwd.readFileAlloc(io, path, a, .limited(128 * 1024 * 1024));
        if (!std.mem.eql(u8, try hash(a, bytes), try string(try object(input, "sha256")))) return error.CapabilityInputHashMismatch;
    }
    const cpu = try readJson(a, io, cwd, try relative(a, root, "Profile/CpuBaseline.json"));
    const zig = try readJson(a, io, cwd, try relative(a, root, "Profile/ZigToolchain.json"));
    const qualified = try readJson(a, io, cwd, try relative(a, root, "Profile/RustQualification.json"));
    const template_root = try relative(a, root, try string(try object(profile, "template_root")));
    const parity = try readJson(a, io, cwd, try relative(a, root, "Profile/LanguageParity.json"));
    const data = .{
        .schema = @as(u32, 3),
        .interface = "r4os-sdk-capabilities",
        .profile_sources = try object(profile, "profile_sources"),
        .build_profiles = try object(profile, "build_profiles"),
        .component_sets = try object(profile, "component_sets"),
        .profile = capabilities.rust_profile,
        .sdk = try object(profile, "sdk"),
        .contract = try object(profile, "contract"),
        .package_interface = "r4os-sdk-package",
        .formats = .{ .manifest = manifest.manifest_version, .semantic_plan = manifest.plan_contract_version, .source_catalog = @as(u32, 4), .installed_catalog = @as(u32, 4), .rust_build_plan = capabilities.rust_build_plan_schema, .module_container = "R4M0:1", .r4x_start = "R4XStart2:2" },
        .cpu = cpu,
        .rust_codegen = try readJson(a, io, cwd, try relative(a, root, "Profile/RustModuleProfile.json")),
        .support = try rules(a),
        .templates = try templates(a, io, cwd, template_root),
        .tools = .{ .id = capabilities.rust_tools, .rust_version = try object(profile, "rust_version"), .cargo_version = try object(profile, "cargo_version"), .rustup_version = try object(profile, "rustup_version"), .bare_target = try object(profile, "bare_target"), .hosts = try object(profile, "hosts"), .release_manifest = try object(profile, "release_manifest"), .files = inputs, .required_components = try object(profile, "required_components"), .optional_components = try object(profile, "optional_components"), .rust_src_required = try object(profile, "rust_src_required"), .zig_host = zig, .c_host = "Zig bundled Clang, executing on Windows/Linux; not native R4CC", .rust_host = "rustc/Cargo plus pinned rust-lld/packager/catalog; Zig only for explicitly declared native C companions", .native_c = "R4BUILD/R4CC C subset inside R4OS", .local_availability_queried = false, .linker = .{ .id = "rust-lld", .source_component = "rustc", .version_binding = "rust_version and required rustc archive", .exact_sources = "tools.hosts.*.required[component=rustc]", .installed_binary_sha256_command = "Setup/Rust.sh check" }, .packager = .{ .id = "r4xbuilder", .version_binding = "sdk.source.commit and sdk.packager_source_sha256", .exact_files = "tools.files[bin/*/r4xbuilder*]" } },
        .qualification = qualified,
        .language_parity = .{
            .id = try object(parity, "id"),
            .matrix_schema = try object(parity, "schema_version"),
            .completion_rule = try object(parity, "completion_rule"),
            .capabilities = try object(parity, "capabilities"),
            .module_roles = try object(parity, "module_roles"),
            .evidence_source = "Profile/LanguageParity.json#/evidence",
            .availability_is_separate = true,
        },
        .technical = try object(profile, "technical"),
        .project_creation = .{ .driver = "Tools/New-Project.ps1", .rust_driver = "Tools/New-RustProject.ps1", .required_inputs = [_][]const u8{ "TemplateId", "Directory", "ContractRoot", "ToolsRoot" }, .optional_inputs = [_][]const u8{ "ProjectName", "SdkRoot", "Language", "Version", "InstallRoot", "CacheRoot", "Technical" }, .derived_tokens = [_][]const u8{ "ProjectNameLower", "ProjectNameUpper", "CrateName", "SdkCrateVersion", "ContractCrateVersion", "DisplayName", "TemplateId", "ImageScope", "Target", "Description", "InterfaceIdLow", "InterfaceIdHigh" }, .c_zig_builder = "Tools/Build-Project.ps1", .rust_builder = "Tools/Build-RustModule.ps1", .initial_library_outputs = "original owner baseline/bindings/conformance/API docs; local Rust Cargo.lock" },
    };
    const json = try std.json.Stringify.valueAlloc(a, data, .{ .whitespace = .indent_2 });
    return std.fmt.allocPrint(a, "{s}\n", .{json});
}
