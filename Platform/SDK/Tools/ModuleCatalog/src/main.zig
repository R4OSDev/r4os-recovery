const std = @import("std");
const contract_bundle = @import("contract_bundle");
const manifest_contract = contract_bundle.r4mf;
const legacy_project = contract_bundle.legacy;
const legacy_converter = contract_bundle;

const Action = enum { catalog, image_inventory, inventories, validate, resolve, plan, contract_plan, image_plan, workspace_image_plan, convert_r4cp };
// ImageMode describes a selection policy, not another IMAGE_SCOPE value.
// Benchmark deliberately reuses slim/full and admits only explicitly named
// test diagnostics, so manifests keep the canonical slim/full/test scopes.
const ImageMode = enum { slim, full, @"test", benchmark };
const max_extra_manifests = 32;
const max_image_include_targets = 32;
const max_workspace_map_bytes = 1024 * 1024;
const max_kernel_version_source_bytes = 256;
const max_kernel_elf_bytes = 64 * 1024 * 1024;
const kernel_metadata_section = ".r4os.kernel.meta";
const kernel_metadata_magic = [8]u8{ 'R', '4', 'O', 'S', 'K', 'R', 'N', '1' };
const kernel_metadata_size: usize = 44;

const SemanticVersion = struct {
    text: []const u8,
    major: u32,
    minor: u32,
    patch: u32,
};

const KernelComponent = struct {
    version: SemanticVersion,
};

const Options = struct {
    action: Action,
    root: []const u8 = "Code",
    output: ?[]const u8 = null,
    image_output: ?[]const u8 = null,
    inventory_output: ?[]const u8 = null,
    manifest_path: ?[]const u8 = null,
    name: ?[]const u8 = null,
    kind: ?manifest_contract.Kind = null,
    path_only: bool = false,
    kind_only: bool = false,
    name_only: bool = false,
    artifact_only: bool = false,
    image_mode: ?ImageMode = null,
    kernel_version_source: ?[]const u8 = null,
    kernel_artifact: ?[]const u8 = null,
    release_version_source: ?[]const u8 = null,
    release_output: ?[]const u8 = null,
    workspace_map: ?[]const u8 = null,
    extra_manifests: [max_extra_manifests][]const u8 = [_][]const u8{""} ** max_extra_manifests,
    extra_manifest_count: usize = 0,
    image_include_targets: [max_image_include_targets][]const u8 = [_][]const u8{""} ** max_image_include_targets,
    image_include_target_count: usize = 0,
};

pub fn main(init: std.process.Init) void {
    run(init) catch |err| {
        std.debug.print("ModuleCatalog FAILED: {s}\n", .{@errorName(err)});
        std.process.exit(1);
    };
}

fn run(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const arena_allocator = init.arena.allocator();
    const io = init.io;
    const cwd = std.Io.Dir.cwd();
    const args = try init.minimal.args.toSlice(arena_allocator);
    const options = parseOptions(args) catch |err| {
        printUsage();
        return err;
    };

    switch (options.action) {
        .catalog => {
            const entries = try discoverCatalog(arena_allocator, io, cwd, options.root);
            const rendered = try renderCatalog(allocator, entries);
            defer allocator.free(rendered);
            try writeOutput(io, cwd, options.output, rendered);
            std.debug.print("ModuleCatalog OK: {d} current R4MF v2 manifest(s), deterministic order.\n", .{entries.len});
        },
        .image_inventory => {
            const entries = try discoverCatalog(arena_allocator, io, cwd, options.root);
            const image_entries = try collectImageEntries(arena_allocator, io, cwd, entries, options);
            const mode = options.image_mode orelse return error.MissingImageMode;
            const includes = options.image_include_targets[0..options.image_include_target_count];
            try validateImageIncludes(image_entries, mode, includes);
            try validateImageDependencyClosure(image_entries, mode, includes);
            const kernel = try loadOptionalKernelComponent(arena_allocator, io, cwd, options);
            const rendered = try renderImageInventory(allocator, image_entries, mode, includes, kernel);
            defer allocator.free(rendered);
            try writeOutput(io, cwd, options.output, rendered);
            std.debug.print("ModuleCatalog image inventory OK: profile={s}, components={d}.\n", .{ @tagName(mode), countImageEntries(image_entries, mode, includes) + @intFromBool(kernel != null) });
        },
        .inventories => {
            // Ein Durchlauf, zwei Sichten. Getrennte Aufrufe wuerden den Baum
            // zweimal lesen und koennten zwischen den Laeufen auseinanderlaufen.
            const entries = try discoverCatalog(arena_allocator, io, cwd, options.root);
            const full = try renderCatalog(allocator, entries);
            defer allocator.free(full);
            try writeOutput(io, cwd, options.output orelse return error.MissingOutput, full);
            const image_entries = try collectImageEntries(arena_allocator, io, cwd, entries, options);
            const mode = options.image_mode orelse return error.MissingImageMode;
            const includes = options.image_include_targets[0..options.image_include_target_count];
            try validateImageIncludes(image_entries, mode, includes);
            try validateImageDependencyClosure(image_entries, mode, includes);
            const kernel = try loadOptionalKernelComponent(arena_allocator, io, cwd, options);
            const lean = try renderImageInventory(allocator, image_entries, mode, includes, kernel);
            defer allocator.free(lean);
            try writeOutput(io, cwd, options.image_output orelse return error.MissingImageOutput, lean);
            if (options.release_version_source) |release_source| {
                const release = try loadVersionSource(arena_allocator, io, cwd, release_source, "RELEASE_VERSION=");
                const required_kernel = kernel orelse return error.ReleaseManifestNeedsKernel;
                inline for (std.meta.tags(ImageMode)) |profile| {
                    try validateImageDependencyClosure(image_entries, profile, &.{});
                }
                const release_manifest = try renderReleaseManifest(allocator, image_entries, required_kernel, release);
                defer allocator.free(release_manifest);
                try writeOutput(io, cwd, options.release_output, release_manifest);
            }
            std.debug.print("ModuleCatalog inventories OK: catalog={d}, profile={s}, image={d} -> {s} + {s}\n", .{ entries.len, @tagName(mode), countImageEntries(image_entries, mode, includes) + @intFromBool(kernel != null), options.output.?, options.image_output.? });
        },
        .validate => {
            const path = options.manifest_path orelse return error.MissingManifestPath;
            const value = try readManifest(arena_allocator, io, cwd, path);
            try validateSourceFiles(arena_allocator, io, cwd, value);
            if (value.kind == .r4x) _ = try manifest_contract.derivePlan(arena_allocator, value);
            if (options.kind_only) {
                try std.Io.File.stdout().writeStreamingAll(io, value.kind.text());
                try std.Io.File.stdout().writeStreamingAll(io, "\n");
            } else if (options.name_only) {
                try std.Io.File.stdout().writeStreamingAll(io, value.name);
                try std.Io.File.stdout().writeStreamingAll(io, "\n");
            } else {
                std.debug.print("Manifest valid: {s} {s} v{d} ({s})\n", .{ value.kind.text(), value.name, value.version, path });
            }
        },
        .resolve => {
            const entries = try discoverCatalog(arena_allocator, io, cwd, options.root);
            const value = try resolve(entries, options.name orelse return error.MissingName, options.kind);
            if (options.path_only) {
                try std.Io.File.stdout().writeStreamingAll(io, value.path);
                try std.Io.File.stdout().writeStreamingAll(io, "\n");
            } else if (options.kind_only) {
                try std.Io.File.stdout().writeStreamingAll(io, value.kind.text());
                try std.Io.File.stdout().writeStreamingAll(io, "\n");
            } else {
                const rendered = try renderEntry(allocator, value, true);
                defer allocator.free(rendered);
                try writeOutput(io, cwd, options.output, rendered);
            }
        },
        .plan => {
            const path = options.manifest_path orelse return error.MissingManifestPath;
            const value = try readManifest(arena_allocator, io, cwd, path);
            const plan = try manifest_contract.derivePlan(arena_allocator, value);
            if (options.artifact_only) {
                try std.Io.File.stdout().writeStreamingAll(io, plan.artifact);
                try std.Io.File.stdout().writeStreamingAll(io, "\n");
            } else {
                const rendered = try renderPlan(allocator, value, plan);
                defer allocator.free(rendered);
                try writeOutput(io, cwd, options.output, rendered);
            }
        },
        .contract_plan => {
            const path = options.manifest_path orelse return error.MissingManifestPath;
            const value = try readManifest(arena_allocator, io, cwd, path);
            try validateSourceFiles(arena_allocator, io, cwd, value);
            const buffer = try allocator.alloc(u8, manifest_contract.max_manifest_bytes);
            defer allocator.free(buffer);
            const rendered = manifest_contract.renderContractPlan(value, buffer);
            if (!rendered.ok) return error.ContractPlanTooLarge;
            try writeOutput(io, cwd, options.output, rendered.bytes);
        },
        .image_plan => {
            const entries = try discoverCatalog(arena_allocator, io, cwd, options.root);
            const image_entries = try collectImageEntries(arena_allocator, io, cwd, entries, options);
            const mode = options.image_mode orelse return error.MissingImageMode;
            const includes = options.image_include_targets[0..options.image_include_target_count];
            try validateImageIncludes(image_entries, mode, includes);
            try validateImageDependencyClosure(image_entries, mode, includes);
            const rendered = try renderImagePlan(arena_allocator, io, cwd, image_entries, mode, includes);
            try writeOutput(io, cwd, options.output, rendered);
            std.debug.print("ModuleCatalog image plan OK: mode={s}, entries={d}.\n", .{ @tagName(mode), countImageEntries(image_entries, mode, includes) });
        },
        .workspace_image_plan => {
            const mode = options.image_mode orelse return error.MissingImageMode;
            const includes = options.image_include_targets[0..options.image_include_target_count];
            const entries = try loadWorkspaceImageEntries(
                arena_allocator,
                io,
                cwd,
                options.workspace_map orelse return error.MissingWorkspaceMap,
            );
            const manifests = try workspaceManifests(arena_allocator, entries);
            try validateCatalogCollisions(manifests);
            try validateImageIncludes(manifests, mode, includes);
            try validateImageDependencyClosure(manifests, mode, includes);
            const rendered = try renderWorkspaceImagePlan(arena_allocator, io, cwd, entries, mode, includes);
            try writeOutput(io, cwd, options.output, rendered);
            if (options.inventory_output) |inventory_output| {
                const kernel = try loadOptionalKernelComponent(arena_allocator, io, cwd, options);
                const inventory = try renderImageInventory(arena_allocator, manifests, mode, includes, kernel);
                try writeOutput(io, cwd, inventory_output, inventory);
            }
            std.debug.print("ModuleCatalog workspace image plan OK: mode={s}, entries={d}{s}.\n", .{
                @tagName(mode),
                countImageEntries(manifests, mode, includes),
                if (options.inventory_output != null) ", inventory generated" else "",
            });
        },
        .convert_r4cp => {
            const path = options.manifest_path orelse return error.MissingManifestPath;
            const output = options.output orelse return error.MissingOutput;
            const changed = try convertR4CP(arena_allocator, io, cwd, path, output);
            std.debug.print("R4CP conversion {s}: {s} -> {s}\n", .{ if (changed) "written atomically" else "not needed (byte-identical destination)", path, output });
        },
    }
}

fn parseOptions(args: []const []const u8) !Options {
    if (args.len < 2) return error.MissingAction;
    var options = Options{ .action = if (std.mem.eql(u8, args[1], "catalog")) .catalog else if (std.mem.eql(u8, args[1], "image-inventory")) .image_inventory else if (std.mem.eql(u8, args[1], "inventories")) .inventories else if (std.mem.eql(u8, args[1], "validate")) .validate else if (std.mem.eql(u8, args[1], "resolve")) .resolve else if (std.mem.eql(u8, args[1], "plan")) .plan else if (std.mem.eql(u8, args[1], "contract-plan")) .contract_plan else if (std.mem.eql(u8, args[1], "image-plan")) .image_plan else if (std.mem.eql(u8, args[1], "workspace-image-plan")) .workspace_image_plan else if (std.mem.eql(u8, args[1], "convert-r4cp")) .convert_r4cp else return error.UnknownAction };
    var index: usize = 2;
    while (index < args.len) : (index += 1) {
        const arg = args[index];
        if (std.mem.eql(u8, arg, "--path-only")) {
            options.path_only = true;
        } else if (std.mem.eql(u8, arg, "--kind-only")) {
            options.kind_only = true;
        } else if (std.mem.eql(u8, arg, "--name-only")) {
            options.name_only = true;
        } else if (std.mem.eql(u8, arg, "--artifact-only")) {
            options.artifact_only = true;
        } else if (std.mem.eql(u8, arg, "--image-mode")) {
            index += 1;
            if (index >= args.len) return error.MissingOptionValue;
            options.image_mode = if (std.mem.eql(u8, args[index], "slim")) .slim else if (std.mem.eql(u8, args[index], "full")) .full else if (std.mem.eql(u8, args[index], "test")) .@"test" else if (std.mem.eql(u8, args[index], "benchmark")) .benchmark else return error.InvalidImageMode;
        } else if (std.mem.eql(u8, arg, "--extra-manifest")) {
            index += 1;
            if (index >= args.len) return error.MissingOptionValue;
            if (options.extra_manifest_count >= max_extra_manifests) return error.TooManyExtraManifests;
            options.extra_manifests[options.extra_manifest_count] = args[index];
            options.extra_manifest_count += 1;
        } else if (std.mem.eql(u8, arg, "--include-target")) {
            index += 1;
            if (index >= args.len) return error.MissingOptionValue;
            if (options.image_include_target_count >= max_image_include_targets) return error.TooManyImageIncludeTargets;
            options.image_include_targets[options.image_include_target_count] = args[index];
            options.image_include_target_count += 1;
        } else if (std.mem.eql(u8, arg, "--kernel-version-source")) {
            index += 1;
            if (index >= args.len) return error.MissingOptionValue;
            options.kernel_version_source = args[index];
        } else if (std.mem.eql(u8, arg, "--kernel-artifact")) {
            index += 1;
            if (index >= args.len) return error.MissingOptionValue;
            options.kernel_artifact = args[index];
        } else if (std.mem.eql(u8, arg, "--release-version-source")) {
            index += 1;
            if (index >= args.len) return error.MissingOptionValue;
            options.release_version_source = args[index];
        } else if (std.mem.eql(u8, arg, "--release-output")) {
            index += 1;
            if (index >= args.len) return error.MissingOptionValue;
            options.release_output = args[index];
        } else if (std.mem.eql(u8, arg, "--root")) {
            index += 1;
            if (index >= args.len) return error.MissingOptionValue;
            options.root = args[index];
        } else if (std.mem.eql(u8, arg, "--image-output")) {
            index += 1;
            if (index >= args.len) return error.MissingImageOutputValue;
            options.image_output = args[index];
        } else if (std.mem.eql(u8, arg, "--inventory-output")) {
            index += 1;
            if (index >= args.len) return error.MissingImageOutputValue;
            options.inventory_output = args[index];
        } else if (std.mem.eql(u8, arg, "--output")) {
            index += 1;
            if (index >= args.len) return error.MissingOptionValue;
            options.output = args[index];
        } else if (std.mem.eql(u8, arg, "--workspace-map")) {
            index += 1;
            if (index >= args.len) return error.MissingOptionValue;
            options.workspace_map = args[index];
        } else if (std.mem.eql(u8, arg, "--manifest")) {
            index += 1;
            if (index >= args.len) return error.MissingOptionValue;
            options.manifest_path = args[index];
        } else if (std.mem.eql(u8, arg, "--name")) {
            index += 1;
            if (index >= args.len) return error.MissingOptionValue;
            options.name = args[index];
        } else if (std.mem.eql(u8, arg, "--kind")) {
            index += 1;
            if (index >= args.len) return error.MissingOptionValue;
            options.kind = parseKindOption(args[index]) orelse return error.InvalidKind;
        } else {
            return error.UnknownOption;
        }
    }
    const compact_modes = @intFromBool(options.path_only) + @intFromBool(options.kind_only) + @intFromBool(options.name_only) + @intFromBool(options.artifact_only);
    if (compact_modes > 1 or (options.output != null and compact_modes != 0)) return error.ConflictingOutputMode;
    if (options.path_only and options.action != .resolve) return error.InvalidOutputMode;
    if (options.kind_only and options.action != .resolve and options.action != .validate) return error.InvalidOutputMode;
    if (options.name_only and options.action != .validate) return error.InvalidOutputMode;
    if (options.artifact_only and options.action != .plan) return error.InvalidOutputMode;
    if (options.action == .convert_r4cp and options.output == null) return error.MissingOutput;
    const image_action = options.action == .image_plan or options.action == .workspace_image_plan or options.action == .image_inventory or options.action == .inventories;
    if ((options.image_mode != null or options.extra_manifest_count != 0 or options.image_include_target_count != 0) and !image_action) return error.InvalidImageOption;
    if (image_action and options.image_mode == null) return error.MissingImageMode;
    if ((options.workspace_map != null) != (options.action == .workspace_image_plan)) return error.InvalidWorkspaceMapOption;
    if (options.inventory_output != null and options.action != .workspace_image_plan) return error.InvalidWorkspaceInventoryOption;
    if ((options.kernel_version_source == null) != (options.kernel_artifact == null)) return error.IncompleteKernelComponent;
    if (options.kernel_version_source != null and options.action != .image_inventory and options.action != .inventories and
        (options.action != .workspace_image_plan or options.inventory_output == null)) return error.InvalidKernelComponentOption;
    if ((options.release_version_source == null) != (options.release_output == null)) return error.IncompleteReleaseManifestOption;
    if (options.release_version_source != null and
        (options.action != .inventories or options.kernel_version_source == null))
    {
        return error.InvalidReleaseManifestOption;
    }
    return options;
}

fn parseKindOption(value: []const u8) ?manifest_contract.Kind {
    inline for (std.meta.tags(manifest_contract.Kind)) |kind| {
        if (std.ascii.eqlIgnoreCase(value, kind.text())) return kind;
    }
    return null;
}

fn printUsage() void {
    std.debug.print(
        \\ModuleCatalog usage:
        \\  module-catalog catalog [--root Code] [--output FILE]
        \\  module-catalog validate --manifest FILE [--kind-only|--name-only]
        \\  module-catalog resolve --root Code --name NAME [--kind R4X] [--path-only|--kind-only]
        \\  module-catalog plan --manifest FILE [--output FILE|--artifact-only]
        \\  module-catalog contract-plan --manifest FILE [--output FILE]
        \\  module-catalog image-inventory --root Code --image-mode slim|full|test|benchmark [--extra-manifest FILE] [--include-target TARGET] [--kernel-version-source FILE --kernel-artifact ELF] [--output FILE]
        \\  module-catalog inventories --root Code --image-mode slim|full|test|benchmark --output FILE --image-output FILE [--extra-manifest FILE] [--include-target TARGET] [--kernel-version-source FILE --kernel-artifact ELF] [--release-version-source FILE --release-output FILE]
        \\  module-catalog image-plan --root Code --image-mode slim|full|test|benchmark [--extra-manifest FILE] [--include-target TARGET] [--output FILE]
        \\  module-catalog workspace-image-plan --workspace-map FILE --image-mode slim|full|test|benchmark [--include-target TARGET] [--kernel-version-source FILE --kernel-artifact ELF --inventory-output FILE] [--output FILE]
        \\  module-catalog convert-r4cp --manifest LEGACY.R4CP --output module.R4MF
        \\
    , .{});
}

fn renderImagePlan(
    allocator: std.mem.Allocator,
    io: std.Io,
    cwd: std.Io.Dir,
    entries: []const manifest_contract.Manifest,
    mode: ImageMode,
    include_targets: []const []const u8,
) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    for (entries) |entry| {
        if (!imageEntryIncluded(entry, mode, include_targets)) continue;
        // Fuer R4X laeuft weiterhin derivePlan mit, weil es den Startvertrag
        // und die Profilimporte mitprueft. Den Artefaktpfad kennt aber jede
        // Modulart nach derselben Regel.
        if (entry.kind == .r4x) _ = try manifest_contract.derivePlan(allocator, entry);
        const artifact = try artifactPath(allocator, entry);
        cwd.access(io, artifact, .{}) catch |err| {
            std.debug.print("Image artifact missing: {s} {s} -> {s} ({s})\n", .{ entry.kind.text(), entry.name, artifact, @errorName(err) });
            return error.ImageArtifactMissing;
        };
        try out.appendSlice(allocator, artifact);
        try out.append(allocator, ':');
        try out.appendSlice(allocator, entry.target);
        try out.append(allocator, '\n');
    }
    return out.toOwnedSlice(allocator);
}

const WorkspaceImageEntry = struct {
    manifest: manifest_contract.Manifest,
    artifact: []const u8,
};

/// Liest eine hostseitige Mehrrepo-Zuordnung. Jede Nutzzeile besteht aus
/// `MANIFEST|ARTEFAKT`; Kommentare beginnen mit `#`. Die Manifestsemantik
/// bleibt vollstaendig beim gemeinsamen R4MF-Parser. Der Workspace liefert
/// nur den Ort des bereits vom Eigentuerrepository gebauten Artefakts.
fn loadWorkspaceImageEntries(
    allocator: std.mem.Allocator,
    io: std.Io,
    cwd: std.Io.Dir,
    path: []const u8,
) ![]WorkspaceImageEntry {
    const bytes = try cwd.readFileAlloc(io, path, allocator, .limited(max_workspace_map_bytes));
    var lines = std.mem.splitScalar(u8, bytes, '\n');
    var entries: std.ArrayList(WorkspaceImageEntry) = .empty;
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t\r");
        if (line.len == 0 or line[0] == '#') continue;
        const separator = std.mem.indexOfScalar(u8, line, '|') orelse return error.InvalidWorkspaceMapLine;
        if (std.mem.indexOfScalar(u8, line[separator + 1 ..], '|') != null) return error.InvalidWorkspaceMapLine;
        const manifest_text = std.mem.trim(u8, line[0..separator], " \t");
        const artifact_text = std.mem.trim(u8, line[separator + 1 ..], " \t");
        if (manifest_text.len == 0 or artifact_text.len == 0) return error.InvalidWorkspaceMapLine;

        const manifest_path = try canonicalPathAlloc(allocator, manifest_text);
        const artifact_path = try canonicalPathAlloc(allocator, artifact_text);
        const manifest = readManifest(allocator, io, cwd, manifest_path) catch |err| {
            std.debug.print("Workspace manifest invalid: {s} ({s})\n", .{ manifest_path, @errorName(err) });
            return err;
        };
        const expected_name = try std.fmt.allocPrint(allocator, "{s}.{s}", .{ manifest.name, manifest.kind.text() });
        if (!std.ascii.eqlIgnoreCase(std.fs.path.basename(artifact_path), expected_name)) {
            std.debug.print("Workspace artifact identity mismatch: {s} expects {s}, got {s}\n", .{ manifest_path, expected_name, artifact_path });
            return error.WorkspaceArtifactIdentityMismatch;
        }
        try entries.append(allocator, .{ .manifest = manifest, .artifact = artifact_path });
    }
    if (entries.items.len == 0) return error.EmptyWorkspaceMap;
    std.mem.sort(WorkspaceImageEntry, entries.items, {}, lessWorkspaceImageEntry);
    for (entries.items, 0..) |entry, index| {
        for (entries.items[0..index]) |prior| {
            if (std.ascii.eqlIgnoreCase(entry.artifact, prior.artifact)) {
                std.debug.print("Workspace artifact mapped more than once: {s}\n", .{entry.artifact});
                return error.WorkspaceArtifactCollision;
            }
        }
    }
    return entries.toOwnedSlice(allocator);
}

fn lessWorkspaceImageEntry(_: void, a: WorkspaceImageEntry, b: WorkspaceImageEntry) bool {
    return lessManifest({}, a.manifest, b.manifest);
}

fn workspaceManifests(allocator: std.mem.Allocator, entries: []const WorkspaceImageEntry) ![]manifest_contract.Manifest {
    const manifests = try allocator.alloc(manifest_contract.Manifest, entries.len);
    for (entries, 0..) |entry, index| manifests[index] = entry.manifest;
    return manifests;
}

fn renderWorkspaceImagePlan(
    allocator: std.mem.Allocator,
    io: std.Io,
    cwd: std.Io.Dir,
    entries: []const WorkspaceImageEntry,
    mode: ImageMode,
    include_targets: []const []const u8,
) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    for (entries) |entry| {
        if (!imageEntryIncluded(entry.manifest, mode, include_targets)) continue;
        if (entry.manifest.kind == .r4x) _ = try manifest_contract.derivePlan(allocator, entry.manifest);
        cwd.access(io, entry.artifact, .{}) catch |err| {
            std.debug.print("Workspace image artifact missing: {s} -> {s} ({s})\n", .{ entry.manifest.path, entry.artifact, @errorName(err) });
            return error.ImageArtifactMissing;
        };
        try out.appendSlice(allocator, entry.artifact);
        try out.append(allocator, ':');
        try out.appendSlice(allocator, entry.manifest.target);
        try out.append(allocator, '\n');
    }
    return out.toOwnedSlice(allocator);
}

/// Wo der Build das Artefakt eines Moduls ablegt. Die Endung ist die
/// Modulart, deshalb gilt eine Regel fuer alle vier.
fn artifactPath(allocator: std.mem.Allocator, entry: manifest_contract.Manifest) ![]u8 {
    return std.fmt.allocPrint(allocator, "Code/zig-out/{s}.{s}", .{ entry.name, entry.kind.text() });
}

/// Seit 0.61.6 entscheidet der Plan fuer ALLE Modularten, was ins Image
/// kommt - vorher galt er nur fuer R4X, und die Platzierung von R4D und R4P
/// stand in einer hartverdrahteten Liste im Buildscript.
fn imageEntryIncluded(entry: manifest_contract.Manifest, mode: ImageMode, include_targets: []const []const u8) bool {
    if (entry.version != manifest_contract.manifest_version) return false;
    const scope = entry.image_scope orelse return false;
    const scoped = switch (mode) {
        .slim => scope == .slim,
        .full => scope == .slim or scope == .full,
        .@"test" => scope == .slim or scope == .@"test",
        .benchmark => scope == .slim or scope == .full,
    };
    if (scoped) return true;
    for (include_targets) |target| {
        if (std.ascii.eqlIgnoreCase(entry.target, target)) return imageScopeCanBeIncludedExplicitly(mode, scope);
    }
    return false;
}

fn imageScopeCanBeIncludedExplicitly(mode: ImageMode, scope: manifest_contract.ImageScope) bool {
    return switch (mode) {
        .@"test" => scope == .full or scope == .none,
        .benchmark => scope == .@"test",
        else => false,
    };
}

fn validateImageIncludes(entries: []const manifest_contract.Manifest, mode: ImageMode, include_targets: []const []const u8) !void {
    if (include_targets.len != 0 and mode != .@"test" and mode != .benchmark) return error.ImageIncludesRequireExplicitMode;
    for (include_targets, 0..) |target, index| {
        if (target.len == 0 or target[0] != '/') return error.InvalidImageIncludeTarget;
        for (include_targets[0..index]) |previous| {
            if (std.ascii.eqlIgnoreCase(previous, target)) return error.DuplicateImageIncludeTarget;
        }
        var match: ?manifest_contract.Manifest = null;
        for (entries) |entry| {
            if (!std.ascii.eqlIgnoreCase(entry.target, target)) continue;
            if (match != null) return error.AmbiguousImageIncludeTarget;
            match = entry;
        }
        const entry = match orelse return error.UnknownImageIncludeTarget;
        if (!imageScopeCanBeIncludedExplicitly(mode, entry.image_scope.?)) return error.ImageIncludeTargetWrongScope;
    }
}

fn collectImageEntries(
    allocator: std.mem.Allocator,
    io: std.Io,
    cwd: std.Io.Dir,
    entries: []const manifest_contract.Manifest,
    options: Options,
) ![]manifest_contract.Manifest {
    var image_entries: std.ArrayList(manifest_contract.Manifest) = .empty;
    try image_entries.appendSlice(allocator, entries);
    for (options.extra_manifests[0..options.extra_manifest_count]) |path| {
        const value = try readManifest(allocator, io, cwd, path);
        try validateSourceFiles(allocator, io, cwd, value);
        if (value.kind == .r4x) _ = try manifest_contract.derivePlan(allocator, value);
        try image_entries.append(allocator, value);
    }
    std.mem.sort(manifest_contract.Manifest, image_entries.items, {}, lessManifest);
    try validateCatalogCollisions(image_entries.items);
    return image_entries.toOwnedSlice(allocator);
}

/// IMPORT benennt einen Provider ueber das erste Feld vor dem Doppelpunkt.
/// Die sechs Platform APIs sind im Kernel eingebaut und besitzen deshalb
/// keinen Katalog- oder Imageeintrag. Ist ein anderer Provider als Runtime-
/// R4L im Katalog vorhanden, muss er im gewaehlten Image ebenfalls enthalten
/// sein. Unbekannte Provider bleiben absichtlichen Negativfixtures
/// vorbehalten und werden hier nicht erfunden.
fn validateImageDependencyClosure(entries: []const manifest_contract.Manifest, mode: ImageMode, include_targets: []const []const u8) !void {
    for (entries) |entry| {
        if (!imageEntryIncluded(entry, mode, include_targets)) continue;
        for (entry.imports) |import_spec| {
            const separator = std.mem.indexOfScalar(u8, import_spec, ':') orelse continue;
            const provider_name = import_spec[0..separator];
            if (manifest_contract.platformApiGroupId(provider_name) != null) continue;
            var provider_known = false;
            var provider_selected = false;
            for (entries) |candidate| {
                if (candidate.kind != .r4l or !std.ascii.eqlIgnoreCase(candidate.name, provider_name)) continue;
                provider_known = true;
                provider_selected = imageEntryIncluded(candidate, mode, include_targets);
                break;
            }
            if (provider_known and !provider_selected) {
                std.debug.print("Image dependency missing: profile={s} {s} {s} requires R4L {s}.\n", .{ @tagName(mode), entry.kind.text(), entry.name, provider_name });
                return error.ImageDependencyMissing;
            }
        }
    }
}

fn countImageEntries(entries: []const manifest_contract.Manifest, mode: ImageMode, include_targets: []const []const u8) usize {
    var count: usize = 0;
    for (entries) |entry| {
        if (imageEntryIncluded(entry, mode, include_targets)) count += 1;
    }
    return count;
}

fn discoverCatalog(
    allocator: std.mem.Allocator,
    io: std.Io,
    cwd: std.Io.Dir,
    root: []const u8,
) ![]manifest_contract.Manifest {
    var dir = try cwd.openDir(io, root, .{ .iterate = true });
    defer dir.close(io);
    var walker = try dir.walk(allocator);
    defer walker.deinit();
    var entries: std.ArrayList(manifest_contract.Manifest) = .empty;
    while (try walker.next(io)) |entry| {
        if (entry.kind != .file or !std.ascii.eqlIgnoreCase(std.fs.path.basename(entry.path), "module.R4MF")) continue;
        const joined = try std.fs.path.join(allocator, &.{ root, entry.path });
        const canonical = try canonicalPathAlloc(allocator, joined);
        const value = readManifest(allocator, io, cwd, canonical) catch |err| {
            std.debug.print("Manifest invalid: {s} ({s})\n", .{ canonical, @errorName(err) });
            return err;
        };
        try validateSourceFiles(allocator, io, cwd, value);
        try entries.append(allocator, value);
    }
    std.mem.sort(manifest_contract.Manifest, entries.items, {}, lessManifest);
    try validateCatalogCollisions(entries.items);
    return entries.toOwnedSlice(allocator);
}

fn readManifest(allocator: std.mem.Allocator, io: std.Io, cwd: std.Io.Dir, path: []const u8) !manifest_contract.Manifest {
    const bytes = try cwd.readFileAlloc(io, path, allocator, .limited(manifest_contract.max_manifest_bytes));
    return manifest_contract.parse(allocator, path, bytes);
}

fn validateSourceFiles(allocator: std.mem.Allocator, io: std.Io, cwd: std.Io.Dir, value: manifest_contract.Manifest) !void {
    const project = std.fs.path.dirname(value.path) orelse ".";
    for (value.sources) |source| {
        const path = try std.fs.path.join(allocator, &.{ project, source });
        cwd.access(io, path, .{}) catch |err| {
            std.debug.print("Manifest source missing: {s} -> {s} ({s})\n", .{ value.path, path, @errorName(err) });
            return error.ManifestSourceMissing;
        };
    }
    for (value.zig_modules) |entry| {
        const colon = std.mem.indexOfScalar(u8, entry, ':') orelse unreachable;
        const path = try std.fs.path.join(allocator, &.{ project, entry[colon + 1 ..] });
        cwd.access(io, path, .{}) catch |err| {
            std.debug.print("Manifest Zig module missing: {s} -> {s} ({s})\n", .{ value.path, path, @errorName(err) });
            return error.ManifestZigModuleMissing;
        };
    }
}

fn canonicalPathAlloc(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    const result = try allocator.dupe(u8, path);
    for (result) |*byte| {
        if (byte.* == '\\') byte.* = '/';
    }
    return result;
}

fn lessManifest(_: void, a: manifest_contract.Manifest, b: manifest_contract.Manifest) bool {
    const kind_order = compareIgnoreCase(a.kind.text(), b.kind.text());
    if (kind_order != .eq) return kind_order == .lt;
    const name_order = compareIgnoreCase(a.name, b.name);
    if (name_order != .eq) return name_order == .lt;
    return compareIgnoreCase(a.path, b.path) == .lt;
}

const Order = enum { lt, eq, gt };

fn compareIgnoreCase(a: []const u8, b: []const u8) Order {
    const count = @min(a.len, b.len);
    var index: usize = 0;
    while (index < count) : (index += 1) {
        const ac = std.ascii.toLower(a[index]);
        const bc = std.ascii.toLower(b[index]);
        if (ac < bc) return .lt;
        if (ac > bc) return .gt;
    }
    if (a.len < b.len) return .lt;
    if (a.len > b.len) return .gt;
    return .eq;
}

fn validateCatalogCollisions(entries: []const manifest_contract.Manifest) !void {
    return validateCatalogCollisionsWithDiagnostics(entries, true);
}

fn validateCatalogCollisionsWithDiagnostics(entries: []const manifest_contract.Manifest, diagnostics: bool) !void {
    for (entries, 0..) |entry, index| {
        for (entries[0..index]) |prior| {
            if (entry.kind == prior.kind and std.ascii.eqlIgnoreCase(entry.name, prior.name)) {
                if (diagnostics) std.debug.print("Manifest identity collision ({s}, {s}):\n  {s}\n  {s}\n", .{ entry.kind.text(), entry.name, prior.path, entry.path });
                return error.ManifestIdentityCollision;
            }
            if (std.ascii.eqlIgnoreCase(entry.target, prior.target)) {
                if (diagnostics) std.debug.print("Manifest target collision ({s}):\n  {s} {s} {s}\n  {s} {s} {s}\n", .{ entry.target, prior.kind.text(), prior.name, prior.path, entry.kind.text(), entry.name, entry.path });
                return error.ManifestTargetCollision;
            }
            if (entry.module_role == .subsystem and prior.module_role == .subsystem and
                std.ascii.eqlIgnoreCase(entry.subsystem_id.?, prior.subsystem_id.?))
            {
                if (diagnostics) std.debug.print("Subsystem ID collision ({s}):\n  {s}\n  {s}\n", .{ entry.subsystem_id.?, prior.path, entry.path });
                return error.SubsystemIdCollision;
            }
        }
    }
}

fn resolve(entries: []const manifest_contract.Manifest, name: []const u8, kind: ?manifest_contract.Kind) !manifest_contract.Manifest {
    var match: ?manifest_contract.Manifest = null;
    var count: usize = 0;
    for (entries) |entry| {
        if (!std.ascii.eqlIgnoreCase(entry.name, name) or (kind != null and entry.kind != kind.?)) continue;
        match = entry;
        count += 1;
    }
    if (count == 0 and kind == null) {
        for (entries) |entry| {
            const project = std.fs.path.dirname(entry.path) orelse continue;
            if (!std.ascii.eqlIgnoreCase(std.fs.path.basename(project), name)) continue;
            match = entry;
            count += 1;
        }
    }
    if (count == 0) {
        std.debug.print("Module not found: {s}{s}\n", .{ name, if (kind == null) "" else " (requested KIND filter)" });
        return error.ModuleNotFound;
    }
    if (count > 1) {
        std.debug.print("Module name is ambiguous: {s}\nCandidates by KIND:\n", .{name});
        for (entries) |entry| {
            const project = std.fs.path.dirname(entry.path) orelse "";
            if (std.ascii.eqlIgnoreCase(entry.name, name) or std.ascii.eqlIgnoreCase(std.fs.path.basename(project), name)) {
                std.debug.print("  {s} {s}: {s}\n", .{ entry.kind.text(), entry.name, entry.path });
            }
        }
        return error.AmbiguousModuleName;
    }
    return match.?;
}

fn writeOutput(io: std.Io, cwd: std.Io.Dir, output: ?[]const u8, bytes: []const u8) !void {
    if (output) |path| {
        try cwd.writeFile(io, .{ .sub_path = path, .data = bytes });
    } else {
        try std.Io.File.stdout().writeStreamingAll(io, bytes);
    }
}

fn loadVersionSource(
    allocator: std.mem.Allocator,
    io: std.Io,
    cwd: std.Io.Dir,
    path: []const u8,
    prefix: []const u8,
) !SemanticVersion {
    const bytes = try cwd.readFileAlloc(io, path, allocator, .limited(max_kernel_version_source_bytes));
    const without_bom = if (bytes.len >= 3 and bytes[0] == 0xEF and bytes[1] == 0xBB and bytes[2] == 0xBF)
        bytes[3..]
    else
        bytes;
    const line = std.mem.trim(u8, without_bom, " \t\r\n");
    if (!std.mem.startsWith(u8, line, prefix)) return error.InvalidVersionSource;
    return parseSemanticVersion(line[prefix.len..]);
}

fn loadOptionalKernelComponent(
    allocator: std.mem.Allocator,
    io: std.Io,
    cwd: std.Io.Dir,
    options: Options,
) !?KernelComponent {
    const version_path = options.kernel_version_source orelse return null;
    const artifact_path = options.kernel_artifact orelse return error.IncompleteKernelComponent;

    const source_bytes = try cwd.readFileAlloc(io, version_path, allocator, .limited(max_kernel_version_source_bytes));
    const source_without_bom = if (source_bytes.len >= 3 and source_bytes[0] == 0xEF and source_bytes[1] == 0xBB and source_bytes[2] == 0xBF)
        source_bytes[3..]
    else
        source_bytes;
    const source_line = std.mem.trim(u8, source_without_bom, " \t\r\n");
    const prefix = "KERNEL_VERSION=";
    if (!std.mem.startsWith(u8, source_line, prefix)) return error.InvalidKernelVersionSource;
    const source_version = try parseSemanticVersion(source_line[prefix.len..]);

    const elf = try cwd.readFileAlloc(io, artifact_path, allocator, .limited(max_kernel_elf_bytes));
    const metadata = try kernelMetadataSection(elf);
    if (!std.mem.eql(u8, metadata[0..8], &kernel_metadata_magic)) return error.InvalidKernelMetadataMagic;
    if (readU32(metadata, 8) != 1 or readU32(metadata, 12) != kernel_metadata_size) return error.InvalidKernelMetadataHeader;

    const text_storage = metadata[28..44];
    const text_end = std.mem.indexOfScalar(u8, text_storage, 0) orelse return error.InvalidKernelMetadataText;
    if (text_end == 0) return error.InvalidKernelMetadataText;
    for (text_storage[text_end..]) |byte| {
        if (byte != 0) return error.InvalidKernelMetadataText;
    }
    const embedded_version = try parseSemanticVersion(text_storage[0..text_end]);
    if (!std.mem.eql(u8, source_version.text, embedded_version.text) or
        source_version.major != readU32(metadata, 16) or
        source_version.minor != readU32(metadata, 20) or
        source_version.patch != readU32(metadata, 24) or
        embedded_version.major != readU32(metadata, 16) or
        embedded_version.minor != readU32(metadata, 20) or
        embedded_version.patch != readU32(metadata, 24))
    {
        std.debug.print("Kernel version mismatch: source={s} embedded={s} numbers={d}.{d}.{d}\n", .{
            source_version.text,
            embedded_version.text,
            readU32(metadata, 16),
            readU32(metadata, 20),
            readU32(metadata, 24),
        });
        return error.KernelArtifactVersionMismatch;
    }
    return KernelComponent{ .version = source_version };
}

fn parseSemanticVersion(value: []const u8) !SemanticVersion {
    if (value.len == 0 or std.mem.indexOfAny(u8, value, " \t\r\n") != null) return error.InvalidSemanticVersion;
    var parts = std.mem.splitScalar(u8, value, '.');
    const major_text = parts.next() orelse return error.InvalidSemanticVersion;
    const minor_text = parts.next() orelse return error.InvalidSemanticVersion;
    const patch_text = parts.next() orelse return error.InvalidSemanticVersion;
    if (parts.next() != null) return error.InvalidSemanticVersion;
    return .{
        .text = value,
        .major = try parseSemanticComponent(major_text),
        .minor = try parseSemanticComponent(minor_text),
        .patch = try parseSemanticComponent(patch_text),
    };
}

fn parseSemanticComponent(value: []const u8) !u32 {
    if (value.len == 0 or (value.len > 1 and value[0] == '0')) return error.InvalidSemanticVersion;
    for (value) |byte| {
        if (byte < '0' or byte > '9') return error.InvalidSemanticVersion;
    }
    return std.fmt.parseInt(u32, value, 10) catch error.InvalidSemanticVersion;
}

fn kernelMetadataSection(elf: []const u8) ![]const u8 {
    if (elf.len < 64 or elf[0] != 0x7F or elf[1] != 'E' or elf[2] != 'L' or elf[3] != 'F') return error.BadKernelElf;
    if (elf[4] != 2 or elf[5] != 1 or readU16(elf, 18) != 0x3E) return error.UnsupportedKernelElf;
    const section_offset = std.math.cast(usize, readU64(elf, 40)) orelse return error.BadKernelElfSectionTable;
    const section_size: usize = readU16(elf, 58);
    const section_count: usize = readU16(elf, 60);
    const names_index: usize = readU16(elf, 62);
    if (section_size < 64 or section_count == 0 or names_index >= section_count) return error.BadKernelElfSectionTable;
    if (section_offset > elf.len or section_count > (elf.len - section_offset) / section_size) return error.BadKernelElfSectionTable;
    const names = elfSectionBytes(elf, section_offset, section_size, names_index) orelse return error.BadKernelElfStringTable;

    var found: ?[]const u8 = null;
    for (0..section_count) |index| {
        const header = section_offset + index * section_size;
        const name = elfSectionName(names, readU32(elf, header)) orelse continue;
        if (!std.mem.eql(u8, name, kernel_metadata_section)) continue;
        if (found != null) return error.DuplicateKernelMetadataSection;
        found = elfSectionBytes(elf, section_offset, section_size, index) orelse return error.BadKernelMetadataSection;
    }
    const metadata = found orelse return error.KernelMetadataMissing;
    if (metadata.len != kernel_metadata_size) return error.BadKernelMetadataSection;
    return metadata;
}

fn elfSectionBytes(elf: []const u8, section_offset: usize, section_size: usize, index: usize) ?[]const u8 {
    const header = section_offset + index * section_size;
    if (header > elf.len or elf.len - header < 40) return null;
    const file_offset = std.math.cast(usize, readU64(elf, header + 24)) orelse return null;
    const file_size = std.math.cast(usize, readU64(elf, header + 32)) orelse return null;
    if (file_offset > elf.len or file_size > elf.len - file_offset) return null;
    return elf[file_offset .. file_offset + file_size];
}

fn elfSectionName(names: []const u8, offset_value: u32) ?[]const u8 {
    const offset: usize = offset_value;
    if (offset >= names.len) return null;
    const end_relative = std.mem.indexOfScalar(u8, names[offset..], 0) orelse return null;
    return names[offset .. offset + end_relative];
}

fn readU16(bytes: []const u8, offset: usize) u16 {
    return std.mem.readInt(u16, bytes[offset..][0..2], .little);
}

fn readU32(bytes: []const u8, offset: usize) u32 {
    return std.mem.readInt(u32, bytes[offset..][0..4], .little);
}

fn readU64(bytes: []const u8, offset: usize) u64 {
    return std.mem.readInt(u64, bytes[offset..][0..8], .little);
}

fn renderCatalog(allocator: std.mem.Allocator, entries: []const manifest_contract.Manifest) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    try appendFmt(&out, allocator, "{{\n  \"schema\": 4,\n  \"manifest_contract\": 2,\n  \"count\": {d},\n  \"entries\": [\n", .{entries.len});
    for (entries, 0..) |entry, index| {
        const rendered = try renderEntry(allocator, entry, false);
        defer allocator.free(rendered);
        var lines = std.mem.splitScalar(u8, rendered, '\n');
        while (lines.next()) |line| {
            if (line.len == 0) continue;
            try out.appendSlice(allocator, "    ");
            try out.appendSlice(allocator, line);
            try out.append(allocator, '\n');
        }
        if (index + 1 != entries.len) {
            out.items.len -= 1;
            try out.appendSlice(allocator, ",\n");
        }
    }
    try out.appendSlice(allocator, "  ]\n}\n");
    return out.toOwnedSlice(allocator);
}

/// Schlanke Sicht fuer das Image: was installiert ist, in welcher Version und
/// wo es liegt. Bewusst OHNE Bauplaene, Quellen und Importe - die braucht auf
/// dem Zielsystem niemand, und das Inventar wird dort zur Laufzeit fortgeschrieben.
///
/// "version" heisst hier schlicht so: Im Zielsystem gibt es keine
/// Manifestformatzahl, von der es sich abgrenzen muesste.
/// "target" ist der Imagepfad aus dem Manifest, unveraendert.
fn renderImageInventory(allocator: std.mem.Allocator, entries: []const manifest_contract.Manifest, mode: ImageMode, include_targets: []const []const u8, kernel: ?KernelComponent) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    const selected_count = countImageEntries(entries, mode, include_targets);
    const component_count = selected_count + @intFromBool(kernel != null);
    try out.appendSlice(allocator, "{\n  \"schema\": 4,\n  \"profile\": ");
    try appendJsonString(&out, allocator, @tagName(mode));
    try appendFmt(&out, allocator, ",\n  \"count\": {d},\n  \"entries\": [\n", .{component_count});
    var selected_index: usize = 0;
    if (kernel) |component| {
        try out.appendSlice(allocator, "    {\n      \"name\": \"KERNEL\",\n      \"kind\": \"KERNEL\",\n      \"version\": ");
        try appendJsonString(&out, allocator, component.version.text);
        try out.appendSlice(allocator, ",\n      \"target\": \"/boot/r4os.elf\",\n      \"module_role\": null,\n      \"subsystem_id\": null,\n      \"subsystem_display_name\": null,\n      \"guest_formats\": [],\n      \"guest_extensions\": [],\n      \"guest_features\": []\n    }");
        selected_index += 1;
        try out.appendSlice(allocator, if (selected_index == component_count) "\n" else ",\n");
    }
    for (entries) |entry| {
        if (!imageEntryIncluded(entry, mode, include_targets)) continue;
        try out.appendSlice(allocator, "    {\n      \"name\": ");
        try appendJsonString(&out, allocator, entry.name);
        try out.appendSlice(allocator, ",\n      \"kind\": ");
        try appendJsonString(&out, allocator, entry.kind.text());
        try out.appendSlice(allocator, ",\n      \"version\": ");
        try appendJsonString(&out, allocator, entry.module_version.text);
        try out.appendSlice(allocator, ",\n      \"target\": ");
        try appendJsonString(&out, allocator, entry.target);
        try out.appendSlice(allocator, ",\n      \"module_role\": ");
        if (entry.module_role) |role| try appendJsonString(&out, allocator, role.text()) else try out.appendSlice(allocator, "null");
        try out.appendSlice(allocator, ",\n      \"subsystem_id\": ");
        if (entry.subsystem_id) |id| try appendJsonString(&out, allocator, id) else try out.appendSlice(allocator, "null");
        try out.appendSlice(allocator, ",\n      \"subsystem_display_name\": ");
        if (entry.subsystem_display_name) |name| try appendJsonString(&out, allocator, name) else try out.appendSlice(allocator, "null");
        try out.appendSlice(allocator, ",\n      \"guest_formats\": ");
        try appendStringArray(&out, allocator, entry.guest_formats);
        try out.appendSlice(allocator, ",\n      \"guest_extensions\": ");
        try appendGuestExtensions(&out, allocator, entry.guest_extensions);
        try out.appendSlice(allocator, ",\n      \"guest_features\": ");
        try appendGuestFeatures(&out, allocator, entry.guest_features);
        try out.appendSlice(allocator, "\n    }");
        selected_index += 1;
        try out.appendSlice(allocator, if (selected_index == component_count) "\n" else ",\n");
    }
    try out.appendSlice(allocator, "  ]\n}\n");
    return out.toOwnedSlice(allocator);
}

fn renderReleaseManifest(
    allocator: std.mem.Allocator,
    entries: []const manifest_contract.Manifest,
    kernel: KernelComponent,
    release: SemanticVersion,
) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    try out.appendSlice(allocator, "{\n  \"schema\": 1,\n  \"release\": ");
    try appendJsonString(&out, allocator, release.text);
    try out.appendSlice(allocator, ",\n  \"profiles\": {\n");
    const profiles = [_]ImageMode{ .slim, .full, .@"test" };
    for (profiles, 0..) |profile, profile_index| {
        try out.appendSlice(allocator, "    ");
        try appendJsonString(&out, allocator, @tagName(profile));
        try out.appendSlice(allocator, ": {\n      \"count\": ");
        try appendFmt(&out, allocator, "{d},\n      \"required\": [\n", .{countImageEntries(entries, profile, &.{}) + 1});
        try appendReleaseComponent(&out, allocator, "KERNEL", "KERNEL", kernel.version.text, "/boot/r4os.elf", 8);
        const selected_count = countImageEntries(entries, profile, &.{});
        if (selected_count != 0) try out.appendSlice(allocator, ",\n") else try out.append(allocator, '\n');
        var selected_index: usize = 0;
        for (entries) |entry| {
            if (!imageEntryIncluded(entry, profile, &.{})) continue;
            try appendReleaseComponent(&out, allocator, entry.name, entry.kind.text(), entry.module_version.text, entry.target, 8);
            selected_index += 1;
            try out.appendSlice(allocator, if (selected_index == selected_count) "\n" else ",\n");
        }
        try out.appendSlice(allocator, "      ]\n    }");
        try out.appendSlice(allocator, if (profile_index + 1 == profiles.len) "\n" else ",\n");
    }
    try out.appendSlice(allocator, "  }\n}\n");
    return out.toOwnedSlice(allocator);
}

fn appendReleaseComponent(
    out: *std.ArrayList(u8),
    allocator: std.mem.Allocator,
    name: []const u8,
    kind: []const u8,
    version: []const u8,
    target: []const u8,
    indent: usize,
) !void {
    try out.appendNTimes(allocator, ' ', indent);
    try out.appendSlice(allocator, "{ \"kind\": ");
    try appendJsonString(out, allocator, kind);
    try out.appendSlice(allocator, ", \"name\": ");
    try appendJsonString(out, allocator, name);
    try out.appendSlice(allocator, ", \"target\": ");
    try appendJsonString(out, allocator, target);
    try out.appendSlice(allocator, ", \"version\": ");
    try appendJsonString(out, allocator, version);
    try out.appendSlice(allocator, " }");
}

fn renderEntry(allocator: std.mem.Allocator, entry: manifest_contract.Manifest, standalone: bool) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    try out.appendSlice(allocator, "{\n  \"kind\": ");
    try appendJsonString(&out, allocator, entry.kind.text());
    try out.appendSlice(allocator, ",\n  \"name\": ");
    try appendJsonString(&out, allocator, entry.name);
    // Version des MODULS aus VERSION=. Das "version" darunter ist die
    // Formatzahl des Manifests und etwas voellig anderes.
    try out.appendSlice(allocator, ",\n  \"module_version\": ");
    try appendJsonString(&out, allocator, entry.module_version.text);
    try appendFmt(&out, allocator, ",\n  \"version\": {d},\n  \"path\": ", .{entry.version});
    try appendJsonString(&out, allocator, entry.path);
    try out.appendSlice(allocator, ",\n  \"target\": ");
    try appendJsonString(&out, allocator, entry.target);
    try out.appendSlice(allocator, ",\n  \"module_role\": ");
    if (entry.module_role) |role| try appendJsonString(&out, allocator, role.text()) else try out.appendSlice(allocator, "null");
    try out.appendSlice(allocator, ",\n  \"subsystem_id\": ");
    if (entry.subsystem_id) |id| try appendJsonString(&out, allocator, id) else try out.appendSlice(allocator, "null");
    try out.appendSlice(allocator, ",\n  \"subsystem_display_name\": ");
    if (entry.subsystem_display_name) |name| try appendJsonString(&out, allocator, name) else try out.appendSlice(allocator, "null");
    try out.appendSlice(allocator, ",\n  \"guest_formats\": ");
    try appendStringArray(&out, allocator, entry.guest_formats);
    try out.appendSlice(allocator, ",\n  \"guest_extensions\": ");
    try appendGuestExtensions(&out, allocator, entry.guest_extensions);
    try out.appendSlice(allocator, ",\n  \"guest_features\": ");
    try appendGuestFeatures(&out, allocator, entry.guest_features);
    try out.appendSlice(allocator, ",\n  \"imports\": ");
    try appendStringArray(&out, allocator, entry.imports);
    try out.appendSlice(allocator, ",\n  \"metadata\": ");
    try appendStringArray(&out, allocator, entry.metadata);
    try out.appendSlice(allocator, ",\n  \"language\": ");
    try appendJsonString(&out, allocator, entry.language.?.text());
    try out.appendSlice(allocator, ",\n  \"sources\": ");
    try appendStringArray(&out, allocator, entry.sources);
    // Ressourcen (0.61.12): Die volle Sicht spiegelt den ganzen
    // Manifestinhalt; der spaetere Updater vergleicht genau diese Datei.
    try out.appendSlice(allocator, ",\n  \"icons\": ");
    try appendStringArray(&out, allocator, entry.icons);
    try out.appendSlice(allocator, ",\n  \"help\": ");
    if (entry.help) |help_path| try appendJsonString(&out, allocator, help_path) else try out.appendSlice(allocator, "null");
    try out.appendSlice(allocator, ",\n  \"resources\": [");
    for (entry.resources, 0..) |resource, index| {
        if (index != 0) try out.appendSlice(allocator, ", ");
        const line = try std.fmt.allocPrint(allocator, "{s}:{s}", .{ resource.name, resource.path });
        defer allocator.free(line);
        try appendJsonString(&out, allocator, line);
    }
    try out.appendSlice(allocator, "]");
    try out.appendSlice(allocator, ",\n  \"image_scope\": ");
    try appendJsonString(&out, allocator, entry.image_scope.?.text());
    try out.appendSlice(allocator, ",\n  \"optimization\": ");
    try appendJsonString(&out, allocator, entry.optimization.?.text());
    if (entry.kind == .r4x) {
        try out.appendSlice(allocator, ",\n  \"package\": ");
        if (entry.package) |package| try appendJsonString(&out, allocator, package) else try out.appendSlice(allocator, "null");
        try out.appendSlice(allocator, ",\n  \"zig_modules\": ");
        try appendStringArray(&out, allocator, entry.zig_modules);
        try out.appendSlice(allocator, ",\n  \"entry_mode\": ");
        try appendJsonString(&out, allocator, entry.entry_mode.?.text());
        try out.appendSlice(allocator, ",\n  \"app_class\": ");
        try appendJsonString(&out, allocator, entry.app_class.?.text());
        const plan = try manifest_contract.derivePlan(allocator, entry);
        try out.appendSlice(allocator, ",\n  \"plan\": ");
        const rendered_plan = try renderPlanObject(allocator, entry, plan);
        defer allocator.free(rendered_plan);
        try out.appendSlice(allocator, rendered_plan);
    } else {
        try out.appendSlice(allocator, ",\n  \"build_mode\": \"explicit-project\"");
    }
    try out.appendSlice(allocator, "\n}");
    if (standalone) try out.append(allocator, '\n');
    return out.toOwnedSlice(allocator);
}

fn renderPlan(allocator: std.mem.Allocator, entry: manifest_contract.Manifest, plan: manifest_contract.Plan) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    try out.appendSlice(allocator, "{\n  \"schema\": 1,\n  \"manifest\": ");
    try appendJsonString(&out, allocator, entry.path);
    try out.appendSlice(allocator, ",\n  \"plan\": ");
    const object = try renderPlanObject(allocator, entry, plan);
    defer allocator.free(object);
    try out.appendSlice(allocator, object);
    try out.appendSlice(allocator, "\n}\n");
    return out.toOwnedSlice(allocator);
}

fn renderPlanObject(allocator: std.mem.Allocator, entry: manifest_contract.Manifest, plan: manifest_contract.Plan) ![]u8 {
    var out: std.ArrayList(u8) = .empty;
    try out.appendSlice(allocator, "{\n    \"kind\": \"R4X\",\n    \"name\": ");
    try appendJsonString(&out, allocator, entry.name);
    try out.appendSlice(allocator, ",\n    \"language\": ");
    try appendJsonString(&out, allocator, entry.language.?.text());
    try out.appendSlice(allocator, ",\n    \"sources\": ");
    try appendStringArray(&out, allocator, entry.sources);
    try out.appendSlice(allocator, ",\n    \"zig_modules\": ");
    try appendStringArray(&out, allocator, entry.zig_modules);
    try out.appendSlice(allocator, ",\n    \"entry_mode\": ");
    try appendJsonString(&out, allocator, entry.entry_mode.?.text());
    try out.appendSlice(allocator, ",\n    \"source_project\": ");
    try appendJsonString(&out, allocator, plan.source_project);
    try out.appendSlice(allocator, ",\n    \"artifact\": ");
    try appendJsonString(&out, allocator, plan.artifact);
    try out.appendSlice(allocator, ",\n    \"target\": ");
    try appendJsonString(&out, allocator, entry.target);
    try out.appendSlice(allocator, ",\n    \"module_role\": ");
    if (entry.module_role) |role| try appendJsonString(&out, allocator, role.text()) else try out.appendSlice(allocator, "null");
    try out.appendSlice(allocator, ",\n    \"subsystem_id\": ");
    if (entry.subsystem_id) |id| try appendJsonString(&out, allocator, id) else try out.appendSlice(allocator, "null");
    try out.appendSlice(allocator, ",\n    \"subsystem_display_name\": ");
    if (entry.subsystem_display_name) |name| try appendJsonString(&out, allocator, name) else try out.appendSlice(allocator, "null");
    try out.appendSlice(allocator, ",\n    \"guest_formats\": ");
    try appendStringArray(&out, allocator, entry.guest_formats);
    try out.appendSlice(allocator, ",\n    \"guest_extensions\": ");
    try appendGuestExtensions(&out, allocator, entry.guest_extensions);
    try out.appendSlice(allocator, ",\n    \"guest_features\": ");
    try appendGuestFeatures(&out, allocator, entry.guest_features);
    try out.appendSlice(allocator, ",\n    \"image_scope\": ");
    try appendJsonString(&out, allocator, entry.image_scope.?.text());
    try out.appendSlice(allocator, ",\n    \"build_profile\": ");
    try appendJsonString(&out, allocator, plan.build_profile);
    try out.appendSlice(allocator, ",\n    \"app_profile\": ");
    try appendJsonString(&out, allocator, plan.app_profile);
    try out.appendSlice(allocator, ",\n    \"app_class\": ");
    try appendJsonString(&out, allocator, plan.app_class);
    try out.appendSlice(allocator, ",\n    \"optimization\": ");
    try appendJsonString(&out, allocator, plan.optimization);
    try out.appendSlice(allocator, ",\n    \"export\": ");
    try appendJsonString(&out, allocator, plan.export_contract);
    try out.appendSlice(allocator, ",\n    \"contracts\": [");
    try appendJsonString(&out, allocator, plan.module_contract);
    try out.appendSlice(allocator, ", ");
    try appendJsonString(&out, allocator, plan.r4x_start_abi);
    try out.appendSlice(allocator, "],\n    \"imports\": ");
    try appendStringArray(&out, allocator, plan.imports);
    try out.appendSlice(allocator, ",\n    \"metadata\": ");
    try appendStringArray(&out, allocator, plan.metadata);
    try out.appendSlice(allocator, "\n  }");
    return out.toOwnedSlice(allocator);
}

fn appendJsonString(out: *std.ArrayList(u8), allocator: std.mem.Allocator, value: []const u8) !void {
    const rendered = try std.json.Stringify.valueAlloc(allocator, value, .{});
    defer allocator.free(rendered);
    try out.appendSlice(allocator, rendered);
}

fn appendStringArray(out: *std.ArrayList(u8), allocator: std.mem.Allocator, values: []const []const u8) !void {
    try out.append(allocator, '[');
    for (values, 0..) |value, index| {
        if (index != 0) try out.appendSlice(allocator, ", ");
        try appendJsonString(out, allocator, value);
    }
    try out.append(allocator, ']');
}

fn appendGuestExtensions(out: *std.ArrayList(u8), allocator: std.mem.Allocator, values: []const manifest_contract.GuestExtensionEntry) !void {
    try out.append(allocator, '[');
    for (values, 0..) |entry, index| {
        if (index != 0) try out.appendSlice(allocator, ", ");
        const value = try std.fmt.allocPrint(allocator, "{s}:{s}", .{ entry.format_id, entry.extension });
        defer allocator.free(value);
        try appendJsonString(out, allocator, value);
    }
    try out.append(allocator, ']');
}

fn appendGuestFeatures(out: *std.ArrayList(u8), allocator: std.mem.Allocator, values: []const manifest_contract.GuestFeatureEntry) !void {
    try out.append(allocator, '[');
    for (values, 0..) |entry, index| {
        if (index != 0) try out.appendSlice(allocator, ", ");
        const value = try std.fmt.allocPrint(allocator, "{s}:{s}", .{ entry.format_id, entry.feature });
        defer allocator.free(value);
        try appendJsonString(out, allocator, value);
    }
    try out.append(allocator, ']');
}

fn appendFmt(out: *std.ArrayList(u8), allocator: std.mem.Allocator, comptime format: []const u8, args: anytype) !void {
    const rendered = try std.fmt.allocPrint(allocator, format, args);
    defer allocator.free(rendered);
    try out.appendSlice(allocator, rendered);
}

fn convertR4CP(
    allocator: std.mem.Allocator,
    io: std.Io,
    cwd: std.Io.Dir,
    source_path: []const u8,
    output_path: []const u8,
) !bool {
    const source_canonical = try canonicalPathAlloc(allocator, source_path);
    const output_canonical = try canonicalPathAlloc(allocator, output_path);
    if (std.ascii.eqlIgnoreCase(source_canonical, output_canonical)) return error.LegacySourceMustRemainUnchanged;
    if (!std.ascii.eqlIgnoreCase(std.fs.path.extension(source_path), ".R4CP")) return error.LegacySourceExtensionRequired;
    if (!std.ascii.eqlIgnoreCase(std.fs.path.extension(output_path), ".R4MF")) return error.CurrentDestinationExtensionRequired;

    const original = try cwd.readFileAlloc(io, source_path, allocator, .limited(manifest_contract.max_manifest_bytes));
    const project = legacy_project.parse(original) catch |err| {
        std.debug.print("Historical R4CP invalid: {s} ({s})\n", .{ legacy_project.errorMessage(err), @errorName(err) });
        return err;
    };
    const buffer = try allocator.alloc(u8, manifest_contract.max_manifest_bytes);
    const converted = legacy_converter.render(project, buffer);
    if (!converted.ok()) {
        std.debug.print("Historical R4CP cannot be converted: {s}\n", .{legacy_converter.errorMessage(converted.err.?)});
        return error.LegacyConversionUnsupported;
    }
    _ = try manifest_contract.parse(allocator, output_path, converted.bytes);

    if (cwd.readFileAlloc(io, output_path, allocator, .limited(manifest_contract.max_manifest_bytes))) |existing| {
        if (!std.mem.eql(u8, existing, converted.bytes)) return error.DestinationExistsWithDifferentBytes;
        return false;
    } else |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    }

    const temp_path = try std.fmt.allocPrint(allocator, "{s}.TMP", .{output_path});
    cwd.deleteFile(io, temp_path) catch |err| switch (err) {
        error.FileNotFound => {},
        else => return err,
    };
    errdefer cwd.deleteFile(io, temp_path) catch {};
    try cwd.writeFile(io, .{ .sub_path = temp_path, .data = converted.bytes, .flags = .{ .exclusive = true } });
    const staged = try cwd.readFileAlloc(io, temp_path, allocator, .limited(manifest_contract.max_manifest_bytes));
    if (!std.mem.eql(u8, staged, converted.bytes)) return error.StagedWriteMismatch;
    try cwd.rename(temp_path, cwd, output_path, io);
    return true;
}

test "catalog rejects duplicate subsystem IDs across profiles" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const cwd = std.Io.Dir.cwd();
    const fixture_a = try cwd.readFileAlloc(std.testing.io, "Tests/Fixture/SubsystemCatalog/RepoA/module.R4MF.fixture", allocator, .limited(manifest_contract.max_manifest_bytes));
    const fixture_b = try cwd.readFileAlloc(std.testing.io, "Tests/Fixture/SubsystemCatalog/RepoB/module.R4MF.fixture", allocator, .limited(manifest_contract.max_manifest_bytes));
    const a = try manifest_contract.parse(allocator, "RepoA/module.R4MF", fixture_a);
    const b = try manifest_contract.parse(allocator, "RepoB/module.R4MF", fixture_b);
    try std.testing.expectError(error.SubsystemIdCollision, validateCatalogCollisionsWithDiagnostics(&.{ a, b }, false));
}

test "catalog and image inventory expose normalized subsystem contract" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const fixture_a = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "Tests/Fixture/SubsystemCatalog/RepoA/module.R4MF.fixture", allocator, .limited(manifest_contract.max_manifest_bytes));
    const text = try std.mem.replaceOwned(u8, allocator, fixture_a, "IMAGE_SCOPE=slim", "IMAGE_SCOPE=test");
    const entry = try manifest_contract.parse(allocator, "RepoA/module.R4MF", text);

    const catalog = try renderCatalog(allocator, &.{entry});
    try std.testing.expect(std.mem.indexOf(u8, catalog, "\"schema\": 4") != null);
    try std.testing.expect(std.mem.indexOf(u8, catalog, "\"module_role\": \"subsystem\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, catalog, "\"subsystem_id\": \"fixture.shared\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, catalog, "\"subsystem_display_name\": \"Fixture Host A\"") != null);

    const inventory = try renderImageInventory(allocator, &.{entry}, .@"test", &.{}, null);
    try std.testing.expect(std.mem.indexOf(u8, inventory, "\"schema\": 4") != null);
    try std.testing.expect(std.mem.indexOf(u8, inventory, "\"guest_formats\": [\"fixture.source\"]") != null);
}

test "catalog exposes common optimization for non-R4X modules" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const driver_text =
        \\R4OS_MODULE_MANIFEST=2
        \\KIND=R4D
        \\NAME=FASTDRV
        \\VERSION=0.1.0
        \\LANGUAGE=Zig
        \\SOURCE=src/main.zig
        \\TARGET=/R4OS/DRIVERS/FASTDRV.R4D
        \\IMAGE_SCOPE=slim
        \\OPTIMIZE=speed
        \\IMPORT=R4DEV:Query:1
        \\META=r4d.name=FASTDRV
        \\META=r4d.type=test
    ;
    const driver = try manifest_contract.parse(allocator, "FastDrv/module.R4MF", driver_text);
    const catalog = try renderCatalog(allocator, &.{driver});
    try std.testing.expect(std.mem.indexOf(u8, catalog, "\"kind\": \"R4D\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, catalog, "\"optimization\": \"speed\"") != null);
}

test "benchmark selection is full plus explicit test diagnostics" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const fixture = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "Tests/Fixture/SubsystemCatalog/RepoA/module.R4MF.fixture", allocator, .limited(manifest_contract.max_manifest_bytes));
    const full_text = try std.mem.replaceOwned(u8, allocator, fixture, "IMAGE_SCOPE=slim", "IMAGE_SCOPE=full");
    const test_text = try std.mem.replaceOwned(u8, allocator, fixture, "IMAGE_SCOPE=slim", "IMAGE_SCOPE=test");
    const none_text = try std.mem.replaceOwned(u8, allocator, fixture, "IMAGE_SCOPE=slim", "IMAGE_SCOPE=none");
    const full_entry = try manifest_contract.parse(allocator, "Full/module.R4MF", full_text);
    const test_entry = try manifest_contract.parse(allocator, "Test/module.R4MF", test_text);
    const none_entry = try manifest_contract.parse(allocator, "None/module.R4MF", none_text);

    try std.testing.expect(imageEntryIncluded(full_entry, .benchmark, &.{}));
    try std.testing.expect(!imageEntryIncluded(test_entry, .benchmark, &.{}));
    try std.testing.expect(imageEntryIncluded(test_entry, .benchmark, &.{test_entry.target}));
    try validateImageIncludes(&.{test_entry}, .benchmark, &.{test_entry.target});
    try std.testing.expectError(error.ImageIncludeTargetWrongScope, validateImageIncludes(&.{full_entry}, .benchmark, &.{full_entry.target}));

    try std.testing.expect(imageEntryIncluded(test_entry, .@"test", &.{}));
    try std.testing.expect(!imageEntryIncluded(full_entry, .@"test", &.{}));
    try std.testing.expect(imageEntryIncluded(full_entry, .@"test", &.{full_entry.target}));
    try validateImageIncludes(&.{full_entry}, .@"test", &.{full_entry.target});
    try std.testing.expect(!imageEntryIncluded(none_entry, .@"test", &.{}));
    try std.testing.expect(imageEntryIncluded(none_entry, .@"test", &.{none_entry.target}));
    try validateImageIncludes(&.{none_entry}, .@"test", &.{none_entry.target});
    try std.testing.expectError(error.ImageIncludeTargetWrongScope, validateImageIncludes(&.{none_entry}, .benchmark, &.{none_entry.target}));
}

test "workspace image plan requires artifacts only for selected manifests" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const fixture = try std.Io.Dir.cwd().readFileAlloc(std.testing.io, "Tests/Fixture/SubsystemCatalog/RepoA/module.R4MF.fixture", allocator, .limited(manifest_contract.max_manifest_bytes));
    const none_text = try std.mem.replaceOwned(u8, allocator, fixture, "IMAGE_SCOPE=slim", "IMAGE_SCOPE=none");
    const none_entry = try manifest_contract.parse(allocator, "None/module.R4MF", none_text);
    const missing_artifact = "Tests/Fixture/SubsystemCatalog/definitely-missing/SUBSYSA.R4X";
    const entries = [_]WorkspaceImageEntry{.{ .manifest = none_entry, .artifact = missing_artifact }};

    const standard = try renderWorkspaceImagePlan(allocator, std.testing.io, std.Io.Dir.cwd(), &entries, .@"test", &.{});
    try std.testing.expectEqualStrings("", standard);
}
