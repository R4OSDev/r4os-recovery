//! Strikter, begrenzter Updatekatalog-v2-Vertrag und lokaler Abgleich.
//!
//! Der produktive Aufrufer reicht ein `json.Document` ein. Damit liegen
//! Tokenisierung und Cursorbewegung weiterhin ausschliesslich in JSON.R4P;
//! dieses Modul kennt nur das fachliche Schema und den Updateplan.

const std = @import("std");
const inventory_contract = @import("system_update_inventory.zig");
const r4u = @import("r4u_manifest.zig");

pub const max_catalog_bytes: usize = 512 * 1024;
pub const max_releases: usize = 32;
pub const max_packages: usize = 64;
pub const max_profile_components: usize = inventory_contract.max_entries;
pub const max_package_components: usize = inventory_contract.max_entries;
pub const max_requirements: usize = 512;
pub const max_download_url_bytes: usize = 1024;
pub const max_filename_bytes: usize = 128;

const tok_end: u32 = 0;
const tok_object_begin: u32 = 1;
const tok_object_end: u32 = 2;
const tok_array_begin: u32 = 3;
const tok_array_end: u32 = 4;
const tok_key: u32 = 5;
const tok_string: u32 = 6;
const tok_number: u32 = 7;
const tok_true: u32 = 8;
const tok_false: u32 = 9;

pub const ParseError = error{
    BadJson,
    BadSchema,
    UnknownField,
    DuplicateField,
    LimitExceeded,
    InvalidValue,
    DuplicateRelease,
    NoEligibleRelease,
};

pub const Component = struct {
    payload: u8 = 0,
    kind: r4u.ComponentKind = .r4x,
    name: []const u8 = "",
    target: []const u8 = "",
    version: []const u8 = "",
    install: r4u.InstallMode = .live,
};

pub const Requirement = struct {
    kind: r4u.ComponentKind = .r4x,
    name: []const u8 = "",
    target: []const u8 = "",
    version: []const u8 = "",
    state: r4u.RequirementState = .installed,
};

pub const Package = struct {
    id: []const u8 = "",
    package_version: []const u8 = "",
    title: []const u8 = "",
    description: []const u8 = "",
    filename: []const u8 = "",
    size: u64 = 0,
    sha256: []const u8 = "",
    reboot_required: bool = false,
    activation: r4u.InstallMode = .live,
    priority: r4u.Priority = .normal,
    install_order: u32 = 0,
    component_start: u16 = 0,
    component_count: u16 = 0,
    requirement_start: u16 = 0,
    requirement_count: u16 = 0,
    download_url: []const u8 = "",
};

pub const CatalogRelease = struct {
    valid: bool = false,
    release: []const u8 = "",
    manifest_filename: []const u8 = "",
    manifest_sha256: []const u8 = "",
    required: [max_profile_components]Component = undefined,
    required_count: usize = 0,
    packages: [max_packages]Package = undefined,
    package_count: usize = 0,
    components: [max_package_components]Component = undefined,
    component_count: usize = 0,
    requirements: [max_requirements]Requirement = undefined,
    requirement_count: usize = 0,

    pub fn packageComponents(self: *const CatalogRelease, package: *const Package) []const Component {
        const start: usize = package.component_start;
        return self.components[start .. start + package.component_count];
    }

    pub fn packageRequirements(self: *const CatalogRelease, package: *const Package) []const Requirement {
        const start: usize = package.requirement_start;
        return self.requirements[start .. start + package.requirement_count];
    }
};

const ManifestSummary = struct {
    release: []const u8 = "",
};

/// Liest den kompletten Katalogvertrag, verwirft nicht ausgewaehlte Profile
/// nach der Validierung und behaelt das hoechste Release >= lokalem Release.
pub fn parseDocument(
    document: anytype,
    profile: inventory_contract.Profile,
    local_release: []const u8,
    workspace: *CatalogRelease,
    out: *CatalogRelease,
) ParseError!void {
    if (!r4u.validSemanticVersion(local_release)) return error.InvalidValue;
    workspace.* = .{};
    out.* = .{};
    document.select("") catch return error.BadJson;
    try expect(document, tok_object_begin);
    document.enter() catch return error.BadJson;

    var seen: u64 = 0;
    var release_names: [max_releases][]const u8 = undefined;
    var release_count: usize = 0;
    while (token(document) != tok_object_end) {
        try expect(document, tok_key);
        const key = tokenBytes(document) orelse return error.BadJson;
        document.next() catch return error.BadJson;
        if (std.mem.eql(u8, key, "schema")) {
            try claim(&seen, 0);
            if ((try unsigned(document)) != 2) return error.BadSchema;
        } else if (std.mem.eql(u8, key, "generated_at")) {
            try claim(&seen, 1);
            const value = try plainString(document);
            if (value.len == 0 or value.len > 64) return error.InvalidValue;
        } else if (std.mem.eql(u8, key, "releases")) {
            try claim(&seen, 2);
            try parseReleases(document, profile, local_release, workspace, out, &release_names, &release_count);
        } else return error.UnknownField;
        document.next() catch return error.BadJson;
    }
    if (seen != mask(3)) return error.BadSchema;
    document.next() catch return error.BadJson;
    if (token(document) != tok_end) return error.BadJson;
    if (!out.valid) return error.NoEligibleRelease;
}

fn parseReleases(
    document: anytype,
    profile: inventory_contract.Profile,
    local_release: []const u8,
    workspace: *CatalogRelease,
    out: *CatalogRelease,
    names: *[max_releases][]const u8,
    name_count: *usize,
) ParseError!void {
    try expect(document, tok_array_begin);
    document.enter() catch return error.BadJson;
    while (token(document) != tok_array_end) {
        if (name_count.* >= max_releases) return error.LimitExceeded;
        workspace.* = .{};
        try parseRelease(document, profile, workspace);
        for (names[0..name_count.*]) |prior| {
            if ((r4u.compareVersions(prior, workspace.release) orelse return error.InvalidValue) == 0)
                return error.DuplicateRelease;
        }
        names[name_count.*] = workspace.release;
        name_count.* += 1;

        const against_local = r4u.compareVersions(workspace.release, local_release) orelse return error.InvalidValue;
        if (against_local >= 0) {
            if (!out.valid or (r4u.compareVersions(workspace.release, out.release) orelse return error.InvalidValue) > 0)
                out.* = workspace.*;
        }
        document.next() catch return error.BadJson;
    }
}

fn parseRelease(document: anytype, profile: inventory_contract.Profile, out: *CatalogRelease) ParseError!void {
    try expect(document, tok_object_begin);
    document.enter() catch return error.BadJson;
    var seen: u64 = 0;
    var manifest = ManifestSummary{};
    while (token(document) != tok_object_end) {
        try expect(document, tok_key);
        const key = tokenBytes(document) orelse return error.BadJson;
        document.next() catch return error.BadJson;
        if (std.mem.eql(u8, key, "release")) {
            try claim(&seen, 0);
            out.release = try semanticVersion(document);
        } else if (std.mem.eql(u8, key, "manifest")) {
            try claim(&seen, 1);
            manifest = try parseManifest(document, profile, out);
        } else if (std.mem.eql(u8, key, "packages")) {
            try claim(&seen, 2);
            try parsePackages(document, out);
        } else return error.UnknownField;
        document.next() catch return error.BadJson;
    }
    if (seen != mask(3) or !std.mem.eql(u8, out.release, manifest.release)) return error.BadSchema;
    try validateRelease(out);
    out.valid = true;
}

fn parseManifest(document: anytype, profile: inventory_contract.Profile, out: *CatalogRelease) ParseError!ManifestSummary {
    try expect(document, tok_object_begin);
    document.enter() catch return error.BadJson;
    var seen: u64 = 0;
    var summary = ManifestSummary{};
    while (token(document) != tok_object_end) {
        try expect(document, tok_key);
        const key = tokenBytes(document) orelse return error.BadJson;
        document.next() catch return error.BadJson;
        if (std.mem.eql(u8, key, "schema")) {
            try claim(&seen, 0);
            if ((try unsigned(document)) != 1) return error.BadSchema;
        } else if (std.mem.eql(u8, key, "release")) {
            try claim(&seen, 1);
            summary.release = try semanticVersion(document);
        } else if (std.mem.eql(u8, key, "profiles")) {
            try claim(&seen, 2);
            try parseProfiles(document, profile, out);
        } else if (std.mem.eql(u8, key, "filename")) {
            try claim(&seen, 3);
            out.manifest_filename = try plainString(document);
            if (!validFilename(out.manifest_filename, ".JSON")) return error.InvalidValue;
        } else if (std.mem.eql(u8, key, "sha256")) {
            try claim(&seen, 4);
            out.manifest_sha256 = try plainString(document);
            if (!validSha256(out.manifest_sha256)) return error.InvalidValue;
        } else return error.UnknownField;
        document.next() catch return error.BadJson;
    }
    if (seen != mask(5)) return error.BadSchema;
    return summary;
}

fn parseProfiles(document: anytype, selected: inventory_contract.Profile, out: *CatalogRelease) ParseError!void {
    try expect(document, tok_object_begin);
    document.enter() catch return error.BadJson;
    var seen: u64 = 0;
    while (token(document) != tok_object_end) {
        try expect(document, tok_key);
        const key = tokenBytes(document) orelse return error.BadJson;
        const index: u6 = if (std.mem.eql(u8, key, "slim")) 0 else if (std.mem.eql(u8, key, "full")) 1 else if (std.mem.eql(u8, key, "test")) 2 else return error.UnknownField;
        try claim(&seen, index);
        document.next() catch return error.BadJson;
        try parseProfile(document, std.mem.eql(u8, key, selected.text()), out);
        document.next() catch return error.BadJson;
    }
    if (seen != mask(3) or out.required_count == 0) return error.BadSchema;
}

fn parseProfile(document: anytype, retain: bool, out: *CatalogRelease) ParseError!void {
    try expect(document, tok_object_begin);
    document.enter() catch return error.BadJson;
    var seen: u64 = 0;
    var declared: usize = 0;
    var parsed: usize = 0;
    while (token(document) != tok_object_end) {
        try expect(document, tok_key);
        const key = tokenBytes(document) orelse return error.BadJson;
        document.next() catch return error.BadJson;
        if (std.mem.eql(u8, key, "count")) {
            try claim(&seen, 0);
            declared = std.math.cast(usize, try unsigned(document)) orelse return error.LimitExceeded;
            if (declared == 0 or declared > max_profile_components) return error.LimitExceeded;
        } else if (std.mem.eql(u8, key, "required")) {
            try claim(&seen, 1);
            parsed = try parseRequired(document, retain, out);
        } else return error.UnknownField;
        document.next() catch return error.BadJson;
    }
    if (seen != mask(2) or declared != parsed) return error.BadSchema;
}

fn parseRequired(document: anytype, retain: bool, out: *CatalogRelease) ParseError!usize {
    try expect(document, tok_array_begin);
    document.enter() catch return error.BadJson;
    var count: usize = 0;
    while (token(document) != tok_array_end) {
        if (count >= max_profile_components) return error.LimitExceeded;
        const component = try parseReleaseComponent(document);
        if (retain) {
            if (out.required_count >= out.required.len) return error.LimitExceeded;
            out.required[out.required_count] = component;
            out.required_count += 1;
        }
        count += 1;
        document.next() catch return error.BadJson;
    }
    return count;
}

fn parseReleaseComponent(document: anytype) ParseError!Component {
    try expect(document, tok_object_begin);
    document.enter() catch return error.BadJson;
    var seen: u64 = 0;
    var result = Component{};
    while (token(document) != tok_object_end) {
        try expect(document, tok_key);
        const key = tokenBytes(document) orelse return error.BadJson;
        document.next() catch return error.BadJson;
        if (std.mem.eql(u8, key, "kind")) {
            try claim(&seen, 0);
            result.kind = r4u.ComponentKind.parse(try plainString(document)) orelse return error.InvalidValue;
        } else if (std.mem.eql(u8, key, "name")) {
            try claim(&seen, 1);
            result.name = try plainString(document);
        } else if (std.mem.eql(u8, key, "target")) {
            try claim(&seen, 2);
            result.target = try plainString(document);
        } else if (std.mem.eql(u8, key, "version")) {
            try claim(&seen, 3);
            result.version = try semanticVersion(document);
        } else return error.UnknownField;
        document.next() catch return error.BadJson;
    }
    if (seen != mask(4) or !validComponent(result)) return error.InvalidValue;
    result.install = r4u.installModeFor(result.kind, result.target);
    return result;
}

fn parsePackages(document: anytype, out: *CatalogRelease) ParseError!void {
    try expect(document, tok_array_begin);
    document.enter() catch return error.BadJson;
    while (token(document) != tok_array_end) {
        if (out.package_count >= out.packages.len) return error.LimitExceeded;
        out.packages[out.package_count] = try parsePackage(document, out);
        out.package_count += 1;
        document.next() catch return error.BadJson;
    }
}

fn parsePackage(document: anytype, out: *CatalogRelease) ParseError!Package {
    try expect(document, tok_object_begin);
    document.enter() catch return error.BadJson;
    var seen: u64 = 0;
    var result = Package{
        .component_start = @intCast(out.component_count),
        .requirement_start = @intCast(out.requirement_count),
    };
    while (token(document) != tok_object_end) {
        try expect(document, tok_key);
        const key = tokenBytes(document) orelse return error.BadJson;
        document.next() catch return error.BadJson;
        if (std.mem.eql(u8, key, "id")) {
            try claim(&seen, 0);
            result.id = try plainString(document);
            if (!r4u.validToken(result.id, r4u.package_name_max_bytes)) return error.InvalidValue;
        } else if (std.mem.eql(u8, key, "package_version")) {
            try claim(&seen, 1);
            result.package_version = try semanticVersion(document);
        } else if (std.mem.eql(u8, key, "title")) {
            try claim(&seen, 2);
            result.title = try escapedString(document);
            if (!validDisplay(result.title, r4u.title_max_bytes)) return error.InvalidValue;
        } else if (std.mem.eql(u8, key, "description")) {
            try claim(&seen, 3);
            result.description = try escapedString(document);
            if (!validDisplay(result.description, r4u.description_max_bytes)) return error.InvalidValue;
        } else if (std.mem.eql(u8, key, "filename")) {
            try claim(&seen, 4);
            result.filename = try plainString(document);
            if (!validFilename(result.filename, ".R4U")) return error.InvalidValue;
        } else if (std.mem.eql(u8, key, "size")) {
            try claim(&seen, 5);
            result.size = try unsigned(document);
            if (result.size == 0) return error.InvalidValue;
        } else if (std.mem.eql(u8, key, "sha256")) {
            try claim(&seen, 6);
            result.sha256 = try plainString(document);
            if (!validSha256(result.sha256)) return error.InvalidValue;
        } else if (std.mem.eql(u8, key, "reboot_required")) {
            try claim(&seen, 7);
            result.reboot_required = try boolean(document);
        } else if (std.mem.eql(u8, key, "activation")) {
            try claim(&seen, 8);
            result.activation = r4u.InstallMode.parse(try plainString(document)) orelse return error.InvalidValue;
        } else if (std.mem.eql(u8, key, "priority")) {
            try claim(&seen, 9);
            result.priority = r4u.Priority.parse(try plainString(document)) orelse return error.InvalidValue;
        } else if (std.mem.eql(u8, key, "install_order")) {
            try claim(&seen, 10);
            result.install_order = std.math.cast(u32, try unsigned(document)) orelse return error.LimitExceeded;
        } else if (std.mem.eql(u8, key, "components")) {
            try claim(&seen, 11);
            result.component_count = try parsePackageComponents(document, out);
        } else if (std.mem.eql(u8, key, "requirements")) {
            try claim(&seen, 12);
            result.requirement_count = try parseRequirements(document, out);
        } else if (std.mem.eql(u8, key, "download_url")) {
            try claim(&seen, 13);
            result.download_url = try plainString(document);
            if (result.download_url.len > max_download_url_bytes or
                !std.mem.startsWith(u8, result.download_url, "https://")) return error.InvalidValue;
        } else return error.UnknownField;
        document.next() catch return error.BadJson;
    }
    if (seen != mask(14)) return error.BadSchema;
    return result;
}

fn parsePackageComponents(document: anytype, out: *CatalogRelease) ParseError!u16 {
    try expect(document, tok_array_begin);
    document.enter() catch return error.BadJson;
    const start = out.component_count;
    while (token(document) != tok_array_end) {
        if (out.component_count >= out.components.len or out.component_count - start >= 32)
            return error.LimitExceeded;
        out.components[out.component_count] = try parsePackageComponent(document);
        out.component_count += 1;
        document.next() catch return error.BadJson;
    }
    return @intCast(out.component_count - start);
}

fn parsePackageComponent(document: anytype) ParseError!Component {
    try expect(document, tok_object_begin);
    document.enter() catch return error.BadJson;
    var seen: u64 = 0;
    var result = Component{};
    while (token(document) != tok_object_end) {
        try expect(document, tok_key);
        const key = tokenBytes(document) orelse return error.BadJson;
        document.next() catch return error.BadJson;
        if (std.mem.eql(u8, key, "payload")) {
            try claim(&seen, 0);
            result.payload = std.math.cast(u8, try unsigned(document)) orelse return error.LimitExceeded;
            if (result.payload >= 32) return error.LimitExceeded;
        } else if (std.mem.eql(u8, key, "kind")) {
            try claim(&seen, 1);
            result.kind = r4u.ComponentKind.parse(try plainString(document)) orelse return error.InvalidValue;
        } else if (std.mem.eql(u8, key, "name")) {
            try claim(&seen, 2);
            result.name = try plainString(document);
        } else if (std.mem.eql(u8, key, "target")) {
            try claim(&seen, 3);
            result.target = try plainString(document);
        } else if (std.mem.eql(u8, key, "version")) {
            try claim(&seen, 4);
            result.version = try semanticVersion(document);
        } else if (std.mem.eql(u8, key, "install")) {
            try claim(&seen, 5);
            result.install = r4u.InstallMode.parse(try plainString(document)) orelse return error.InvalidValue;
        } else return error.UnknownField;
        document.next() catch return error.BadJson;
    }
    if (seen != mask(6) or !validComponent(result) or
        result.install != r4u.installModeFor(result.kind, result.target)) return error.InvalidValue;
    return result;
}

fn parseRequirements(document: anytype, out: *CatalogRelease) ParseError!u16 {
    try expect(document, tok_array_begin);
    document.enter() catch return error.BadJson;
    const start = out.requirement_count;
    while (token(document) != tok_array_end) {
        if (out.requirement_count >= out.requirements.len or out.requirement_count - start >= 64)
            return error.LimitExceeded;
        out.requirements[out.requirement_count] = try parseRequirement(document);
        out.requirement_count += 1;
        document.next() catch return error.BadJson;
    }
    return @intCast(out.requirement_count - start);
}

fn parseRequirement(document: anytype) ParseError!Requirement {
    try expect(document, tok_object_begin);
    document.enter() catch return error.BadJson;
    var seen: u64 = 0;
    var result = Requirement{};
    while (token(document) != tok_object_end) {
        try expect(document, tok_key);
        const key = tokenBytes(document) orelse return error.BadJson;
        document.next() catch return error.BadJson;
        if (std.mem.eql(u8, key, "kind")) {
            try claim(&seen, 0);
            result.kind = r4u.ComponentKind.parse(try plainString(document)) orelse return error.InvalidValue;
        } else if (std.mem.eql(u8, key, "name")) {
            try claim(&seen, 1);
            result.name = try plainString(document);
        } else if (std.mem.eql(u8, key, "target")) {
            try claim(&seen, 2);
            result.target = try plainString(document);
        } else if (std.mem.eql(u8, key, "version")) {
            try claim(&seen, 3);
            result.version = try semanticVersion(document);
        } else if (std.mem.eql(u8, key, "state")) {
            try claim(&seen, 4);
            result.state = r4u.RequirementState.parse(try plainString(document)) orelse return error.InvalidValue;
        } else return error.UnknownField;
        document.next() catch return error.BadJson;
    }
    const component = Component{ .kind = result.kind, .name = result.name, .target = result.target, .version = result.version };
    if (seen != mask(5) or !validComponent(component)) return error.InvalidValue;
    if (result.state == .active and result.kind != .kernel) return error.InvalidValue;
    return result;
}

fn validateRelease(release: *const CatalogRelease) ParseError!void {
    if (release.required_count == 0 or release.required_count > release.required.len or
        release.package_count > release.packages.len or release.component_count > release.components.len or
        release.requirement_count > release.requirements.len) return error.LimitExceeded;

    var kernels: usize = 0;
    for (release.required[0..release.required_count], 0..) |component, index| {
        if (component.kind == .kernel) kernels += 1;
        for (release.required[0..index]) |prior| {
            if (sameIdentity(component, prior) or r4u.targetEquals(component.target, prior.target))
                return error.InvalidValue;
        }
    }
    if (kernels != 1) return error.InvalidValue;

    for (release.packages[0..release.package_count], 0..) |package, package_index| {
        if (package.install_order >= release.package_count) return error.InvalidValue;
        for (release.packages[0..package_index]) |prior| {
            if (std.ascii.eqlIgnoreCase(package.id, prior.id) or package.install_order == prior.install_order)
                return error.InvalidValue;
        }
        var derived_activation: r4u.InstallMode = .live;
        var derived_priority: r4u.Priority = .normal;
        for (release.packageComponents(&package)) |component| {
            if (component.install == .restart) derived_activation = .restart;
            if (r4u.priorityFor(component.kind) == .foundation) derived_priority = .foundation;
        }
        if (package.activation != derived_activation or package.priority != derived_priority or
            package.reboot_required != (package.activation == .restart)) return error.InvalidValue;
    }
    for (release.components[0..release.component_count], 0..) |component, index| {
        for (release.components[0..index]) |prior| {
            if (sameIdentity(component, prior) or r4u.targetEquals(component.target, prior.target))
                return error.InvalidValue;
        }
    }
}

fn expect(document: anytype, wanted: u32) ParseError!void {
    if (token(document) != wanted) return error.BadJson;
}

fn token(document: anytype) u32 {
    return @intFromEnum(document.token());
}

fn tokenBytes(document: anytype) ?[]const u8 {
    return document.tokenBytes();
}

fn claim(seen: *u64, index: u6) ParseError!void {
    const bit = @as(u64, 1) << index;
    if ((seen.* & bit) != 0) return error.DuplicateField;
    seen.* |= bit;
}

fn mask(count: u6) u64 {
    return (@as(u64, 1) << count) - 1;
}

fn escapedString(document: anytype) ParseError![]const u8 {
    try expect(document, tok_string);
    const value = tokenBytes(document) orelse return error.BadJson;
    if (!std.unicode.utf8ValidateSlice(value)) return error.InvalidValue;
    for (value) |byte| if (byte < 0x20) return error.InvalidValue;
    return value;
}

fn plainString(document: anytype) ParseError![]const u8 {
    const value = try escapedString(document);
    if (std.mem.indexOfScalar(u8, value, '\\') != null) return error.InvalidValue;
    return value;
}

fn semanticVersion(document: anytype) ParseError![]const u8 {
    const value = try plainString(document);
    if (!r4u.validSemanticVersion(value)) return error.InvalidValue;
    return value;
}

fn unsigned(document: anytype) ParseError!u64 {
    try expect(document, tok_number);
    const value = tokenBytes(document) orelse return error.BadJson;
    if (value.len == 0 or (value.len > 1 and value[0] == '0')) return error.InvalidValue;
    var result: u64 = 0;
    for (value) |byte| {
        if (byte < '0' or byte > '9') return error.InvalidValue;
        result = std.math.mul(u64, result, 10) catch return error.LimitExceeded;
        result = std.math.add(u64, result, byte - '0') catch return error.LimitExceeded;
    }
    return result;
}

fn boolean(document: anytype) ParseError!bool {
    return switch (token(document)) {
        tok_true => true,
        tok_false => false,
        else => error.BadJson,
    };
}

fn validComponent(component: Component) bool {
    if (!r4u.validToken(component.name, r4u.component_name_max_bytes) or
        !r4u.validSemanticVersion(component.version)) return false;
    var canonical_buffer: [1024]u8 = undefined;
    const canonical = r4u.canonicalInventoryTarget(canonical_buffer[0..], component.target) orelse return false;
    if (!r4u.targetEquals(canonical, component.target)) return false;
    return switch (component.kind) {
        .kernel => std.ascii.eqlIgnoreCase(component.name, "KERNEL") and r4u.targetEquals(component.target, "/boot/r4os.elf"),
        .r4x => std.ascii.endsWithIgnoreCase(component.target, ".R4X"),
        .r4l => startsWithIgnoreCase(component.target, "/R4OS/LIBS/") and std.ascii.endsWithIgnoreCase(component.target, ".R4L"),
        .r4d => startsWithIgnoreCase(component.target, "/R4OS/DRIVERS/") and std.ascii.endsWithIgnoreCase(component.target, ".R4D"),
        .r4p => startsWithIgnoreCase(component.target, "/R4OS/PROTOCOLS/") and std.ascii.endsWithIgnoreCase(component.target, ".R4P"),
    };
}

fn validSha256(value: []const u8) bool {
    if (value.len != 64) return false;
    for (value) |byte| if (!std.ascii.isHex(byte)) return false;
    return true;
}

fn validFilename(value: []const u8, suffix: []const u8) bool {
    return value.len != 0 and value.len <= max_filename_bytes and
        r4u.validToken(value, max_filename_bytes) and std.ascii.endsWithIgnoreCase(value, suffix);
}

fn validDisplay(raw: []const u8, max_bytes: usize) bool {
    var decoded: [r4u.description_max_bytes]u8 = undefined;
    const value = decodeJsonString(raw, decoded[0..]) orelse return false;
    return r4u.validDisplayText(value, max_bytes);
}

pub const PlanError = error{
    InvalidInventory,
    InvalidCatalog,
    UnmetRequirement,
    DependencyOrder,
    TooManyPackages,
};

pub const PackageDelta = struct {
    eligible: bool = false,
    update_count: u16 = 0,
    repair_count: u16 = 0,
};

pub const Plan = struct {
    package_indices: [max_packages]u16 = .{0} ** max_packages,
    package_count: usize = 0,
    update_component_count: usize = 0,
    missing_required_count: usize = 0,
    restart_required: bool = false,
    release_newer: bool = false,

    pub fn packageIndex(self: *const Plan, index: usize) ?usize {
        if (index >= self.package_count) return null;
        return self.package_indices[index];
    }
};

/// Erzeugt ausschliesslich Angebote fuer installierte Komponenten mit
/// hoeherer Version sowie fuer fehlende Komponenten des lokalen Profils.
/// Pakete sind atomar: ein Paket, das eine uninstallierte optionale
/// Komponente oder ein Downgrade mitbringen wuerde, wird nicht angeboten.
pub fn buildPlan(
    release: *const CatalogRelease,
    inventory: *const inventory_contract.Inventory,
    local_release: []const u8,
    active_kernel: ?[]const u8,
) PlanError!Plan {
    if (!release.valid or release.package_count > max_packages or inventory.count == 0 or
        inventory.count > inventory.entries.len or !r4u.validSemanticVersion(local_release))
        return error.InvalidInventory;
    if (active_kernel) |value| if (!r4u.validSemanticVersion(value)) return error.InvalidInventory;

    var plan = Plan{};
    plan.release_newer = (r4u.compareVersions(release.release, local_release) orelse return error.InvalidCatalog) > 0;
    var eligible: [max_packages]bool = .{false} ** max_packages;
    var selected: [max_packages]bool = .{false} ** max_packages;

    for (release.packages[0..release.package_count], 0..) |*package, index| {
        const delta = packageDelta(release, inventory, package) catch return error.InvalidCatalog;
        eligible[index] = delta.eligible;
        selected[index] = delta.eligible and (delta.update_count != 0 or delta.repair_count != 0);
    }

    // Jede fehlende oder zu alte Pflichtkomponente muss konkret durch ein
    // atomar zulaessiges Paket reparierbar sein. Kein Teilplan wird geraten.
    for (release.required[0..release.required_count]) |required| {
        if (installedSatisfies(inventory, required.kind, required.name, required.target, required.version)) continue;
        const provider = findProvider(release, &eligible, required.kind, required.name, required.target, required.version) orelse
            return error.UnmetRequirement;
        selected[provider] = true;
    }

    // Konkrete installierte Abhaengigkeiten duerfen weitere Provider in den
    // Plan ziehen. ACTIVE ist absichtlich nur durch den laufenden Kernel
    // erfuellbar und nicht durch einen erst nach Neustart aktiven Download.
    var changed = true;
    while (changed) {
        changed = false;
        for (release.packages[0..release.package_count], 0..) |*package, package_index| {
            if (!selected[package_index]) continue;
            for (release.packageRequirements(package)) |requirement| {
                if (requirement.state == .active) {
                    if (!activeSatisfies(active_kernel, requirement)) return error.UnmetRequirement;
                    continue;
                }
                if (installedSatisfies(inventory, requirement.kind, requirement.name, requirement.target, requirement.version)) continue;
                const provider = findProvider(release, &eligible, requirement.kind, requirement.name, requirement.target, requirement.version) orelse
                    return error.UnmetRequirement;
                if (!selected[provider]) {
                    selected[provider] = true;
                    changed = true;
                }
            }
        }
    }

    // Der Server liefert eine topologische install_order. Der Client prueft
    // sie erneut und materialisiert genau diese deterministische Reihenfolge.
    var order: u32 = 0;
    while (order < release.package_count) : (order += 1) {
        var found: ?usize = null;
        for (release.packages[0..release.package_count], 0..) |package, index| {
            if (package.install_order == order) {
                found = index;
                break;
            }
        }
        const index = found orelse return error.InvalidCatalog;
        if (!selected[index]) continue;
        if (plan.package_count >= plan.package_indices.len) return error.TooManyPackages;
        plan.package_indices[plan.package_count] = @intCast(index);
        plan.package_count += 1;
    }

    for (plan.package_indices[0..plan.package_count]) |raw_index| {
        const index: usize = raw_index;
        const package = &release.packages[index];
        const delta = packageDelta(release, inventory, package) catch return error.InvalidCatalog;
        plan.update_component_count += delta.update_count;
        plan.missing_required_count += delta.repair_count;
        if (package.reboot_required) plan.restart_required = true;
        for (release.packageRequirements(package)) |requirement| {
            if (requirement.state == .active or
                installedSatisfies(inventory, requirement.kind, requirement.name, requirement.target, requirement.version)) continue;
            const provider = selectedProvider(release, &selected, requirement) orelse return error.UnmetRequirement;
            if (provider != index and release.packages[provider].install_order >= package.install_order)
                return error.DependencyOrder;
        }
    }

    if (installedKernelVersion(inventory)) |installed| {
        if (active_kernel) |active| {
            if ((r4u.compareVersions(installed, active) orelse return error.InvalidInventory) != 0)
                plan.restart_required = true;
        }
    }
    return plan;
}

pub fn packageDelta(
    release: *const CatalogRelease,
    inventory: *const inventory_contract.Inventory,
    package: *const Package,
) PlanError!PackageDelta {
    var result = PackageDelta{ .eligible = package.component_count != 0 };
    for (release.packageComponents(package)) |component| {
        const installed = findInstalled(inventory, component.kind, component.name, component.target);
        const required = findRequired(release, component.kind, component.name, component.target);
        if (installed) |entry| {
            const comparison = r4u.compareVersions(component.version, entry.version) orelse return error.InvalidCatalog;
            if (comparison < 0) result.eligible = false else if (comparison > 0) result.update_count += 1;
        } else if (required) |needed| {
            const comparison = r4u.compareVersions(component.version, needed.version) orelse return error.InvalidCatalog;
            if (comparison < 0) result.eligible = false else result.repair_count += 1;
        } else {
            result.eligible = false;
        }
    }
    return result;
}

fn findInstalled(
    inventory: *const inventory_contract.Inventory,
    kind: r4u.ComponentKind,
    name: []const u8,
    target: []const u8,
) ?*const inventory_contract.Entry {
    for (inventory.entries[0..inventory.count]) |*entry| {
        if (entry.kind == kind and std.ascii.eqlIgnoreCase(entry.name, name) and r4u.targetEquals(entry.target, target))
            return entry;
    }
    return null;
}

pub fn installedEntry(
    inventory: *const inventory_contract.Inventory,
    kind: r4u.ComponentKind,
    name: []const u8,
    target: []const u8,
) ?*const inventory_contract.Entry {
    return findInstalled(inventory, kind, name, target);
}

fn findRequired(
    release: *const CatalogRelease,
    kind: r4u.ComponentKind,
    name: []const u8,
    target: []const u8,
) ?*const Component {
    for (release.required[0..release.required_count]) |*component| {
        if (component.kind == kind and std.ascii.eqlIgnoreCase(component.name, name) and r4u.targetEquals(component.target, target))
            return component;
    }
    return null;
}

fn installedSatisfies(
    inventory: *const inventory_contract.Inventory,
    kind: r4u.ComponentKind,
    name: []const u8,
    target: []const u8,
    version: []const u8,
) bool {
    const entry = findInstalled(inventory, kind, name, target) orelse return false;
    return (r4u.compareVersions(entry.version, version) orelse -1) >= 0;
}

fn findProvider(
    release: *const CatalogRelease,
    eligible: *const [max_packages]bool,
    kind: r4u.ComponentKind,
    name: []const u8,
    target: []const u8,
    version: []const u8,
) ?usize {
    var found: ?usize = null;
    for (release.packages[0..release.package_count], 0..) |*package, index| {
        if (!eligible[index]) continue;
        for (release.packageComponents(package)) |component| {
            if (component.kind == kind and std.ascii.eqlIgnoreCase(component.name, name) and
                r4u.targetEquals(component.target, target) and
                (r4u.compareVersions(component.version, version) orelse -1) >= 0)
            {
                if (found != null) return null;
                found = index;
            }
        }
    }
    return found;
}

fn selectedProvider(release: *const CatalogRelease, selected: *const [max_packages]bool, requirement: Requirement) ?usize {
    return findProvider(release, selected, requirement.kind, requirement.name, requirement.target, requirement.version);
}

fn activeSatisfies(active_kernel: ?[]const u8, requirement: Requirement) bool {
    if (requirement.kind != .kernel or requirement.state != .active) return false;
    const active = active_kernel orelse return false;
    return (r4u.compareVersions(active, requirement.version) orelse -1) >= 0;
}

fn installedKernelVersion(inventory: *const inventory_contract.Inventory) ?[]const u8 {
    for (inventory.entries[0..inventory.count]) |entry| if (entry.kind == .kernel) return entry.version;
    return null;
}

fn sameIdentity(left: Component, right: Component) bool {
    return left.kind == right.kind and std.ascii.eqlIgnoreCase(left.name, right.name);
}

fn startsWithIgnoreCase(value: []const u8, prefix: []const u8) bool {
    return value.len >= prefix.len and std.ascii.eqlIgnoreCase(value[0..prefix.len], prefix);
}

/// Dekodiert genau den Inhalt eines JSON-Stringtokens (ohne Quotes). Die
/// Funktion ist zugleich der einzige Weg, auf dem Titel und Beschreibung in
/// den spaeteren Clientvertrag gelangen.
pub fn decodeJsonString(raw: []const u8, out: []u8) ?[]const u8 {
    var source: usize = 0;
    var target: usize = 0;
    while (source < raw.len) {
        const byte = raw[source];
        if (byte != '\\') {
            if (byte < 0x20 or target >= out.len) return null;
            out[target] = byte;
            target += 1;
            source += 1;
            continue;
        }
        source += 1;
        if (source >= raw.len) return null;
        const escaped = raw[source];
        source += 1;
        const simple: ?u8 = switch (escaped) {
            '"' => '"',
            '\\' => '\\',
            '/' => '/',
            'b' => 0x08,
            'f' => 0x0c,
            'n' => '\n',
            'r' => '\r',
            't' => '\t',
            'u' => null,
            else => return null,
        };
        if (simple) |value| {
            if (target >= out.len) return null;
            out[target] = value;
            target += 1;
            continue;
        }
        const first = readHexCodeUnit(raw, source) orelse return null;
        source += 4;
        var codepoint: u21 = first;
        if (first >= 0xD800 and first <= 0xDBFF) {
            if (source + 6 > raw.len or raw[source] != '\\' or raw[source + 1] != 'u') return null;
            const second = readHexCodeUnit(raw, source + 2) orelse return null;
            if (second < 0xDC00 or second > 0xDFFF) return null;
            source += 6;
            codepoint = 0x10000 + (@as(u21, first - 0xD800) << 10) + (second - 0xDC00);
        } else if (first >= 0xDC00 and first <= 0xDFFF) return null;
        target = appendUtf8(out, target, codepoint) orelse return null;
    }
    const result = out[0..target];
    return if (std.unicode.utf8ValidateSlice(result)) result else null;
}

fn readHexCodeUnit(raw: []const u8, offset: usize) ?u16 {
    if (offset + 4 > raw.len) return null;
    var value: u16 = 0;
    for (raw[offset .. offset + 4]) |byte| {
        const digit: u16 = if (byte >= '0' and byte <= '9') byte - '0' else if (byte >= 'a' and byte <= 'f') byte - 'a' + 10 else if (byte >= 'A' and byte <= 'F') byte - 'A' + 10 else return null;
        value = value * 16 + digit;
    }
    return value;
}

fn appendUtf8(out: []u8, offset: usize, codepoint: u21) ?usize {
    const length: usize = if (codepoint <= 0x7F) 1 else if (codepoint <= 0x7FF) 2 else if (codepoint <= 0xFFFF) 3 else if (codepoint <= 0x10FFFF) 4 else return null;
    if (offset + length > out.len) return null;
    switch (length) {
        1 => out[offset] = @intCast(codepoint),
        2 => {
            out[offset] = @intCast(0xC0 | (codepoint >> 6));
            out[offset + 1] = @intCast(0x80 | (codepoint & 0x3F));
        },
        3 => {
            out[offset] = @intCast(0xE0 | (codepoint >> 12));
            out[offset + 1] = @intCast(0x80 | ((codepoint >> 6) & 0x3F));
            out[offset + 2] = @intCast(0x80 | (codepoint & 0x3F));
        },
        4 => {
            out[offset] = @intCast(0xF0 | (codepoint >> 18));
            out[offset + 1] = @intCast(0x80 | ((codepoint >> 12) & 0x3F));
            out[offset + 2] = @intCast(0x80 | ((codepoint >> 6) & 0x3F));
            out[offset + 3] = @intCast(0x80 | (codepoint & 0x3F));
        },
        else => unreachable,
    }
    return offset + length;
}

const json_core = @import("json_core");

const TestToken = enum(u32) {
    end = 0,
    object_begin = 1,
    object_end = 2,
    array_begin = 3,
    array_end = 4,
    key = 5,
    string = 6,
    number = 7,
    true_value = 8,
    false_value = 9,
    null_value = 10,
    none = 255,
    _,
};

const TestDocument = struct {
    cursor: json_core.Cursor = .{},
    depth: [32]u8 = undefined,

    fn open(self: *TestDocument, bytes: []const u8) void {
        self.cursor = .{ .depth_stack = self.depth[0..].ptr, .depth_capacity = self.depth.len };
        _ = json_core.open(&self.cursor, bytes);
    }

    fn token(self: *const TestDocument) TestToken {
        return @enumFromInt(self.cursor.token);
    }

    fn tokenBytes(self: *const TestDocument) ?[]const u8 {
        return self.cursor.tokenBytes();
    }

    fn select(self: *TestDocument, path: []const u8) !void {
        if (json_core.select(&self.cursor, path) != json_core.err_ok) return error.Protocol;
    }

    fn enter(self: *TestDocument) !void {
        if (json_core.enter(&self.cursor) != json_core.err_ok) return error.Protocol;
    }

    fn next(self: *TestDocument) !void {
        if (json_core.next(&self.cursor) != json_core.err_ok) return error.Protocol;
    }
};

const catalog_fixture =
    \\{
    \\  "schema": 2,
    \\  "generated_at": "2026-08-10T12:00:00Z",
    \\  "releases": [
    \\    {
    \\      "release": "0.63.17",
    \\      "manifest": {
    \\        "schema": 1,
    \\        "release": "0.63.17",
    \\        "profiles": {
    \\          "slim": {"count": 1, "required": [
    \\            {"kind": "KERNEL", "name": "KERNEL", "target": "/boot/r4os.elf", "version": "1.0.0"}
    \\          ]},
    \\          "full": {"count": 2, "required": [
    \\            {"kind": "KERNEL", "name": "KERNEL", "target": "/boot/r4os.elf", "version": "1.0.0"},
    \\            {"kind": "R4X", "name": "FULLOPT", "target": "/R4OS/SOFTWARE/FULL/FULLOPT.R4X", "version": "1.0.0"}
    \\          ]},
    \\          "test": {"count": 2, "required": [
    \\            {"kind": "KERNEL", "name": "KERNEL", "target": "/boot/r4os.elf", "version": "1.0.0"},
    \\            {"kind": "R4X", "name": "TESTONLY", "target": "/R4OS/SOFTWARE/TEST/TESTONLY.R4X", "version": "1.0.0"}
    \\          ]}
    \\        },
    \\        "filename": "R4OS-RELEASE-0.63.17.JSON",
    \\        "sha256": "0000000000000000000000000000000000000000000000000000000000000000"
    \\      },
    \\      "packages": []
    \\    }
    \\  ]
    \\}
;

fn parseFixture(profile: inventory_contract.Profile, out: *CatalogRelease) !void {
    var document = TestDocument{};
    document.open(catalog_fixture);
    var workspace = CatalogRelease{};
    try parseDocument(&document, profile, "0.63.16", &workspace, out);
}

test "catalog v2 is strict bounded and selects exactly the local profile" {
    var slim = CatalogRelease{};
    try parseFixture(.slim, &slim);
    try std.testing.expectEqual(@as(usize, 1), slim.required_count);
    try std.testing.expectEqualStrings("KERNEL", slim.required[0].name);

    var full = CatalogRelease{};
    try parseFixture(.full, &full);
    try std.testing.expectEqual(@as(usize, 2), full.required_count);
    try std.testing.expectEqualStrings("FULLOPT", full.required[1].name);

    var test_image = CatalogRelease{};
    try parseFixture(.test_image, &test_image);
    try std.testing.expectEqual(@as(usize, 2), test_image.required_count);
    try std.testing.expectEqualStrings("TESTONLY", test_image.required[1].name);
}

test "catalog rejects unknown fields and releases older than local state" {
    const bad = try std.mem.replaceOwned(u8, std.testing.allocator, catalog_fixture, "\"generated_at\"", "\"unknown\"");
    defer std.testing.allocator.free(bad);
    var document = TestDocument{};
    document.open(bad);
    var workspace = CatalogRelease{};
    var result = CatalogRelease{};
    try std.testing.expectError(error.UnknownField, parseDocument(&document, .full, "0.63.16", &workspace, &result));

    document.open(catalog_fixture);
    try std.testing.expectError(error.NoEligibleRelease, parseDocument(&document, .full, "0.63.18", &workspace, &result));
}

fn makeComponent(kind: r4u.ComponentKind, name: []const u8, target: []const u8, version: []const u8) Component {
    return .{ .kind = kind, .name = name, .target = target, .version = version, .install = r4u.installModeFor(kind, target) };
}

fn basePlanRelease() CatalogRelease {
    var release = CatalogRelease{ .valid = true, .release = "0.63.18" };
    release.required[0] = makeComponent(.kernel, "KERNEL", "/boot/r4os.elf", "1.0.0");
    release.required[1] = makeComponent(.r4l, "R4LIB", "/R4OS/LIBS/R4LIB.R4L", "2.0.0");
    release.required[2] = makeComponent(.r4x, "APP", "/R4OS/SOFTWARE/APP/APP.R4X", "2.0.0");
    release.required_count = 3;
    release.components[0] = release.required[1];
    release.components[1] = release.required[2];
    release.component_count = 2;
    release.requirements[0] = .{
        .kind = .r4l,
        .name = "R4LIB",
        .target = "/R4OS/LIBS/R4LIB.R4L",
        .version = "2.0.0",
        .state = .installed,
    };
    release.requirement_count = 1;
    release.packages[0] = .{
        .id = "LIB",
        .package_version = "2.0.0",
        .install_order = 0,
        .priority = .foundation,
        .activation = .restart,
        .reboot_required = true,
        .component_start = 0,
        .component_count = 1,
    };
    release.packages[1] = .{
        .id = "APP",
        .package_version = "2.0.0",
        .install_order = 1,
        .component_start = 1,
        .component_count = 1,
        .requirement_start = 0,
        .requirement_count = 1,
    };
    release.package_count = 2;
    return release;
}

fn makeInventory(kernel_version: []const u8, library_version: ?[]const u8, app_version: ?[]const u8) inventory_contract.Inventory {
    var result = inventory_contract.Inventory{ .profile = .full };
    result.entries[0] = .{ .kind = .kernel, .name = "KERNEL", .target = "/boot/r4os.elf", .version = kernel_version };
    result.count = 1;
    if (library_version) |version| {
        result.entries[result.count] = .{ .kind = .r4l, .name = "R4LIB", .target = "/R4OS/LIBS/R4LIB.R4L", .version = version };
        result.count += 1;
    }
    if (app_version) |version| {
        result.entries[result.count] = .{ .kind = .r4x, .name = "APP", .target = "/R4OS/SOFTWARE/APP/APP.R4X", .version = version };
        result.count += 1;
    }
    return result;
}

test "inventory comparison yields none one multiple and mandatory repair deterministically" {
    const release = basePlanRelease();
    var current = makeInventory("1.0.0", "2.0.0", "2.0.0");
    var plan = try buildPlan(&release, &current, "0.63.17", "1.0.0");
    try std.testing.expectEqual(@as(usize, 0), plan.package_count);

    current = makeInventory("1.0.0", "2.0.0", "1.0.0");
    plan = try buildPlan(&release, &current, "0.63.17", "1.0.0");
    try std.testing.expectEqual(@as(usize, 1), plan.package_count);
    try std.testing.expectEqual(@as(usize, 1), plan.packageIndex(0).?);

    current = makeInventory("1.0.0", "1.0.0", "1.0.0");
    plan = try buildPlan(&release, &current, "0.63.17", "1.0.0");
    try std.testing.expectEqualSlices(u16, &.{ 0, 1 }, plan.package_indices[0..plan.package_count]);

    current = makeInventory("1.0.0", "2.0.0", null);
    plan = try buildPlan(&release, &current, "0.63.17", "1.0.0");
    try std.testing.expectEqual(@as(usize, 1), plan.missing_required_count);
    try std.testing.expectEqual(@as(usize, 1), plan.packageIndex(0).?);
}

test "new central release with unchanged kernel is detected through module versions" {
    const release = basePlanRelease();
    var current = makeInventory("1.0.0", "2.0.0", "1.0.0");
    const plan = try buildPlan(&release, &current, "0.63.17", "1.0.0");
    try std.testing.expect(plan.release_newer);
    try std.testing.expectEqual(@as(usize, 1), plan.package_count);
    try std.testing.expect(!plan.restart_required);
}

test "optional missing components and downgrades stay hidden" {
    var release = basePlanRelease();
    release.required_count = 1;
    var current = makeInventory("1.0.0", "3.0.0", null);
    const plan = try buildPlan(&release, &current, "0.63.18", "1.0.0");
    try std.testing.expectEqual(@as(usize, 0), plan.package_count);
}

test "missing concrete requirement and broken dependency order are visible errors" {
    var release = basePlanRelease();
    release.package_count = 1;
    release.packages[0] = release.packages[1];
    release.packages[0].install_order = 0;
    var current = makeInventory("1.0.0", null, "1.0.0");
    try std.testing.expectError(error.UnmetRequirement, buildPlan(&release, &current, "0.63.17", "1.0.0"));

    release = basePlanRelease();
    release.packages[0].install_order = 1;
    release.packages[1].install_order = 0;
    current = makeInventory("1.0.0", "1.0.0", "1.0.0");
    try std.testing.expectError(error.DependencyOrder, buildPlan(&release, &current, "0.63.17", "1.0.0"));
}

test "kind name and target identity does not merge different module kinds" {
    var release = basePlanRelease();
    release.required[1] = makeComponent(.r4l, "SAME", "/R4OS/LIBS/SAME.R4L", "2.0.0");
    release.components[0] = release.required[1];
    release.requirements[0].name = "SAME";
    release.requirements[0].target = "/R4OS/LIBS/SAME.R4L";
    var current = inventory_contract.Inventory{ .profile = .full };
    current.entries[0] = .{ .kind = .kernel, .name = "KERNEL", .target = "/boot/r4os.elf", .version = "1.0.0" };
    current.entries[1] = .{ .kind = .r4x, .name = "SAME", .target = "/R4OS/SOFTWARE/SAME/SAME.R4X", .version = "9.0.0" };
    current.entries[2] = .{ .kind = .r4x, .name = "APP", .target = "/R4OS/SOFTWARE/APP/APP.R4X", .version = "2.0.0" };
    current.count = 3;
    const plan = try buildPlan(&release, &current, "0.63.17", "1.0.0");
    try std.testing.expectEqual(@as(usize, 1), plan.package_count);
    try std.testing.expectEqual(@as(usize, 0), plan.packageIndex(0).?);
}

test "installed kernel newer than active kernel reports restart without downgrade" {
    const release = basePlanRelease();
    var current = makeInventory("1.1.0", "2.0.0", "2.0.0");
    const plan = try buildPlan(&release, &current, "0.63.18", "1.0.0");
    try std.testing.expectEqual(@as(usize, 0), plan.package_count);
    try std.testing.expect(plan.restart_required);
}

test "escaped package display text decodes once and remains plain UTF-8" {
    var out: [128]u8 = undefined;
    const decoded = decodeJsonString("Ger\\u00e4te: \\\"OK\\\" und \\\\Pfad", out[0..]).?;
    try std.testing.expectEqualStrings("Ger\xc3\xa4te: \"OK\" und \\Pfad", decoded);
}
