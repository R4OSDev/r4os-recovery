const std = @import("std");
const r4u_manifest = @import("r4u_manifest.zig");
const recovery = @import("system_update_recovery.zig");

pub const journal_version: u16 = 1;
pub const max_packages: usize = 16;
pub const max_components: usize = recovery.max_package_payloads;
pub const max_requirements: usize = recovery.max_package_payloads;
pub const journal_max: usize = 64 * 1024;
pub const max_reason: usize = 64;

pub const Phase = enum {
    staged,
    verifying,
    staging,
    committing,
    pending_restart,
    installed,
    failed,
    rolling_back,
    rolled_back,

    pub fn text(self: Phase) []const u8 {
        return switch (self) {
            .staged => "staged",
            .verifying => "verifying",
            .staging => "staging",
            .committing => "committing",
            .pending_restart => "pending-restart",
            .installed => "installed",
            .failed => "failed",
            .rolling_back => "rolling-back",
            .rolled_back => "rolled-back",
        };
    }

    pub fn parse(value: []const u8) ?Phase {
        inline for (std.meta.tags(Phase)) |phase| {
            if (std.ascii.eqlIgnoreCase(value, phase.text())) return phase;
        }
        return null;
    }
};

pub fn phaseTerminal(phase: Phase) bool {
    return phase == .installed or phase == .rolled_back;
}

pub const PackageEntry = struct {
    order: u8 = 0,
    path: [recovery.max_path:0]u8 = .{0} ** recovery.max_path,
    path_len: usize = 0,
    package: [r4u_manifest.package_name_max_bytes + 1]u8 = .{0} ** (r4u_manifest.package_name_max_bytes + 1),
    package_len: usize = 0,
    package_version: [r4u_manifest.version_max_bytes + 1]u8 = .{0} ** (r4u_manifest.version_max_bytes + 1),
    package_version_len: usize = 0,
    release: [r4u_manifest.version_max_bytes + 1]u8 = .{0} ** (r4u_manifest.version_max_bytes + 1),
    release_len: usize = 0,
    package_length: u64 = 0,
    package_digest: u32 = 0,
    manifest_checksum: u32 = 0,
    component_digest: u32 = 0,
    activation: r4u_manifest.InstallMode = .restart,
    priority: r4u_manifest.Priority = .normal,

    pub fn pathText(self: *const PackageEntry) []const u8 {
        return self.path[0..self.path_len];
    }

    pub fn packageText(self: *const PackageEntry) []const u8 {
        return self.package[0..self.package_len];
    }

    pub fn packageVersionText(self: *const PackageEntry) []const u8 {
        return self.package_version[0..self.package_version_len];
    }

    pub fn releaseText(self: *const PackageEntry) []const u8 {
        return self.release[0..self.release_len];
    }
};

pub const BatchJournal = struct {
    slot: u8 = 0,
    valid: bool = false,
    batch_generation: u64 = 0,
    journal_generation: u64 = 0,
    phase: Phase = .staged,
    package_count: u32 = 0,
    current_package: u32 = 0,
    source_release: [r4u_manifest.version_max_bytes + 1]u8 = .{0} ** (r4u_manifest.version_max_bytes + 1),
    source_release_len: usize = 0,
    target_release: [r4u_manifest.version_max_bytes + 1]u8 = .{0} ** (r4u_manifest.version_max_bytes + 1),
    target_release_len: usize = 0,
    reason: [max_reason + 1]u8 = .{0} ** (max_reason + 1),
    reason_len: usize = 0,
    packages: [max_packages]PackageEntry = .{PackageEntry{}} ** max_packages,

    pub fn sourceReleaseText(self: *const BatchJournal) []const u8 {
        return self.source_release[0..self.source_release_len];
    }

    pub fn targetReleaseText(self: *const BatchJournal) []const u8 {
        return self.target_release[0..self.target_release_len];
    }

    pub fn reasonText(self: *const BatchJournal) []const u8 {
        return self.reason[0..self.reason_len];
    }
};

pub const SlotSelection = union(enum) {
    selected: u8,
    not_found,
    invalid,
};

pub fn selectNewestSlot(present: [2]bool, valid: [2]bool, generations: [2]u64) SlotSelection {
    if (!present[0] and !present[1]) return .not_found;
    if (!valid[0] and !valid[1]) return .invalid;
    if (valid[0] and !valid[1]) return .{ .selected = 0 };
    if (!valid[0] and valid[1]) return .{ .selected = 1 };
    return .{ .selected = if (generations[1] > generations[0]) 1 else 0 };
}

pub fn serializeJournal(journal: *const BatchJournal, out: []u8) ?[]const u8 {
    if (!journalValid(journal)) return null;
    var len: usize = 0;
    if (!appendText(out, &len, "R4U_BATCH=1\n") or
        !appendKeyU64(out, &len, "BATCH_GENERATION=", journal.batch_generation) or
        !appendKeyU64(out, &len, "JOURNAL_GENERATION=", journal.journal_generation) or
        !appendText(out, &len, "PHASE=") or
        !appendText(out, &len, journal.phase.text()) or
        !appendByte(out, &len, '\n') or
        !appendText(out, &len, "SOURCE_RELEASE=") or
        !appendText(out, &len, journal.sourceReleaseText()) or
        !appendByte(out, &len, '\n') or
        !appendText(out, &len, "TARGET_RELEASE=") or
        !appendText(out, &len, journal.targetReleaseText()) or
        !appendByte(out, &len, '\n') or
        !appendKeyU64(out, &len, "PACKAGES=", journal.package_count) or
        !appendKeyU64(out, &len, "CURRENT_PACKAGE=", journal.current_package) or
        !appendText(out, &len, "REASON=") or
        !appendText(out, &len, journal.reasonText()) or
        !appendByte(out, &len, '\n'))
    {
        return null;
    }

    var index: usize = 0;
    while (index < journal.package_count) : (index += 1) {
        const entry = &journal.packages[index];
        if (!appendText(out, &len, "PACKAGE;index=") or
            !appendU64(out, &len, index) or
            !appendText(out, &len, ";order=") or
            !appendU64(out, &len, entry.order) or
            !appendText(out, &len, ";path=") or
            !appendText(out, &len, entry.pathText()) or
            !appendText(out, &len, ";package=") or
            !appendText(out, &len, entry.packageText()) or
            !appendText(out, &len, ";version=") or
            !appendText(out, &len, entry.packageVersionText()) or
            !appendText(out, &len, ";release=") or
            !appendText(out, &len, entry.releaseText()) or
            !appendText(out, &len, ";length=") or
            !appendU64(out, &len, entry.package_length) or
            !appendText(out, &len, ";digest=") or
            !appendU64(out, &len, entry.package_digest) or
            !appendText(out, &len, ";manifest=") or
            !appendU64(out, &len, entry.manifest_checksum) or
            !appendText(out, &len, ";component=") or
            !appendU64(out, &len, entry.component_digest) or
            !appendText(out, &len, ";activation=") or
            !appendText(out, &len, entry.activation.text()) or
            !appendText(out, &len, ";priority=") or
            !appendText(out, &len, entry.priority.text()) or
            !appendByte(out, &len, '\n'))
        {
            return null;
        }
    }
    const body_checksum = recovery.checksum(out[0..len]);
    if (!appendText(out, &len, "CHECKSUM=") or
        !appendU64(out, &len, body_checksum) or
        !appendByte(out, &len, '\n'))
    {
        return null;
    }
    return out[0..len];
}

pub fn parseJournalInto(data: []const u8, slot: u8, out: *BatchJournal) bool {
    out.* = .{};
    if (slot > 1 or data.len == 0 or data.len > journal_max) return false;
    const checksum_start = lastLineStart(data, "CHECKSUM=") orelse return false;
    const checksum_line = trimLine(data[checksum_start..]);
    const stored_checksum = parseU32(checksum_line["CHECKSUM=".len..]) orelse return false;
    if (stored_checksum != recovery.checksum(data[0..checksum_start])) return false;

    var saw_magic = false;
    var saw_batch_generation = false;
    var saw_journal_generation = false;
    var saw_phase = false;
    var saw_source = false;
    var saw_target = false;
    var saw_packages = false;
    var saw_current = false;
    var saw_reason = false;
    var parsed_packages: u32 = 0;
    var lines = std.mem.splitScalar(u8, data[0..checksum_start], '\n');
    while (lines.next()) |raw_line| {
        const line = trimLine(raw_line);
        if (line.len == 0) continue;
        if (std.mem.eql(u8, line, "R4U_BATCH=1")) {
            if (saw_magic) return false;
            saw_magic = true;
        } else if (startsWith(line, "BATCH_GENERATION=")) {
            if (saw_batch_generation) return false;
            out.batch_generation = parseU64(line["BATCH_GENERATION=".len..]) orelse return false;
            saw_batch_generation = true;
        } else if (startsWith(line, "JOURNAL_GENERATION=")) {
            if (saw_journal_generation) return false;
            out.journal_generation = parseU64(line["JOURNAL_GENERATION=".len..]) orelse return false;
            saw_journal_generation = true;
        } else if (startsWith(line, "PHASE=")) {
            if (saw_phase) return false;
            out.phase = Phase.parse(line["PHASE=".len..]) orelse return false;
            saw_phase = true;
        } else if (startsWith(line, "SOURCE_RELEASE=")) {
            if (saw_source) return false;
            out.source_release_len = copyTextZ(out.source_release[0..], line["SOURCE_RELEASE=".len..]) orelse return false;
            saw_source = true;
        } else if (startsWith(line, "TARGET_RELEASE=")) {
            if (saw_target) return false;
            out.target_release_len = copyTextZ(out.target_release[0..], line["TARGET_RELEASE=".len..]) orelse return false;
            saw_target = true;
        } else if (startsWith(line, "PACKAGES=")) {
            if (saw_packages) return false;
            out.package_count = parseU32(line["PACKAGES=".len..]) orelse return false;
            saw_packages = true;
        } else if (startsWith(line, "CURRENT_PACKAGE=")) {
            if (saw_current) return false;
            out.current_package = parseU32(line["CURRENT_PACKAGE=".len..]) orelse return false;
            saw_current = true;
        } else if (startsWith(line, "REASON=")) {
            if (saw_reason) return false;
            out.reason_len = copyTextZ(out.reason[0..], line["REASON=".len..]) orelse return false;
            saw_reason = true;
        } else if (startsWith(line, "PACKAGE;")) {
            if (!parsePackageLine(line, parsed_packages, out)) return false;
            parsed_packages += 1;
        } else {
            return false;
        }
    }
    out.slot = slot;
    out.valid = saw_magic and saw_batch_generation and saw_journal_generation and
        saw_phase and saw_source and saw_target and saw_packages and saw_current and
        saw_reason and parsed_packages == out.package_count;
    return journalValid(out);
}

fn parsePackageLine(line: []const u8, expected_index: u32, journal: *BatchJournal) bool {
    if (expected_index >= max_packages or
        !lineFieldsKnown(line, &.{ "index", "order", "path", "package", "version", "release", "length", "digest", "manifest", "component", "activation", "priority" }))
    {
        return false;
    }
    if ((parseU32(fieldValue(line, "index=") orelse "") orelse return false) != expected_index) return false;
    var entry = &journal.packages[expected_index];
    entry.* = .{};
    const order = parseU32(fieldValue(line, "order=") orelse "") orelse return false;
    if (order >= max_packages) return false;
    entry.order = @intCast(order);
    const path = fieldValue(line, "path=") orelse return false;
    entry.path_len = (recovery.normalizeAbsolutePath(entry.path[0..], path) orelse return false).len;
    entry.package_len = copyTextZ(entry.package[0..], fieldValue(line, "package=") orelse return false) orelse return false;
    entry.package_version_len = copyTextZ(entry.package_version[0..], fieldValue(line, "version=") orelse return false) orelse return false;
    entry.release_len = copyTextZ(entry.release[0..], fieldValue(line, "release=") orelse return false) orelse return false;
    entry.package_length = parseU64(fieldValue(line, "length=") orelse "") orelse return false;
    entry.package_digest = parseU32(fieldValue(line, "digest=") orelse "") orelse return false;
    entry.manifest_checksum = parseU32(fieldValue(line, "manifest=") orelse "") orelse return false;
    entry.component_digest = parseU32(fieldValue(line, "component=") orelse "") orelse return false;
    entry.activation = r4u_manifest.InstallMode.parse(fieldValue(line, "activation=") orelse "") orelse return false;
    entry.priority = r4u_manifest.Priority.parse(fieldValue(line, "priority=") orelse "") orelse return false;
    return true;
}

pub fn journalValid(journal: *const BatchJournal) bool {
    if (!journal.valid or journal.slot > 1 or journal.batch_generation == 0 or
        journal.journal_generation == 0 or journal.package_count == 0 or
        journal.package_count > max_packages or journal.current_package > journal.package_count or
        !r4u_manifest.validSemanticVersion(journal.sourceReleaseText()) or
        !r4u_manifest.validSemanticVersion(journal.targetReleaseText()) or
        !validReason(journal.reasonText()))
    {
        return false;
    }
    var orders: [max_packages]bool = .{false} ** max_packages;
    var index: usize = 0;
    while (index < journal.package_count) : (index += 1) {
        const entry = &journal.packages[index];
        if (entry.order >= journal.package_count or orders[entry.order] or
            entry.path_len == 0 or entry.path_len >= entry.path.len or
            !r4u_manifest.validToken(entry.packageText(), r4u_manifest.package_name_max_bytes) or
            !r4u_manifest.validSemanticVersion(entry.packageVersionText()) or
            !r4u_manifest.validSemanticVersion(entry.releaseText()) or
            !std.mem.eql(u8, entry.releaseText(), journal.targetReleaseText()) or
            entry.package_length <= r4u_manifest.header_size)
        {
            return false;
        }
        orders[entry.order] = true;
        var prior: usize = 0;
        while (prior < index) : (prior += 1) {
            if (std.ascii.eqlIgnoreCase(entry.pathText(), journal.packages[prior].pathText()) or
                std.ascii.eqlIgnoreCase(entry.packageText(), journal.packages[prior].packageText()))
            {
                return false;
            }
        }
    }
    return true;
}

pub const PlanComponent = struct {
    package_index: u8,
    kind: r4u_manifest.ComponentKind,
    name: []const u8,
    target: []const u8,
    version: []const u8,
};

pub const PlanRequirement = struct {
    package_index: u8,
    kind: r4u_manifest.ComponentKind,
    name: []const u8,
    target: []const u8,
    version: []const u8,
    current_satisfied: bool = false,
};

pub const PlanPackage = struct {
    priority: r4u_manifest.Priority = .normal,
};

pub const PlanError = error{
    TooManyPackages,
    InvalidReference,
    DuplicateComponent,
    UnresolvedRequirement,
    DependencyCycle,
};

pub fn planOrder(
    packages: []const PlanPackage,
    components: []const PlanComponent,
    requirements: []const PlanRequirement,
    out: []u8,
) PlanError![]const u8 {
    if (packages.len == 0 or packages.len > max_packages or out.len < packages.len)
        return error.TooManyPackages;
    var edges: [max_packages][max_packages]bool = .{.{false} ** max_packages} ** max_packages;
    var indegree: [max_packages]u8 = .{0} ** max_packages;

    for (components, 0..) |component, index| {
        if (component.package_index >= packages.len) return error.InvalidReference;
        for (components[0..index]) |prior| {
            if ((component.kind == prior.kind and std.ascii.eqlIgnoreCase(component.name, prior.name)) or
                r4u_manifest.targetEquals(component.target, prior.target))
            {
                return error.DuplicateComponent;
            }
        }
    }

    for (requirements) |requirement| {
        if (requirement.package_index >= packages.len) return error.InvalidReference;
        if (requirement.current_satisfied) continue;
        var provider: ?u8 = null;
        for (components) |component| {
            if (component.kind != requirement.kind or
                !std.ascii.eqlIgnoreCase(component.name, requirement.name) or
                !r4u_manifest.targetEquals(component.target, requirement.target) or
                (r4u_manifest.compareVersions(component.version, requirement.version) orelse -1) < 0)
            {
                continue;
            }
            provider = component.package_index;
            break;
        }
        const provider_index = provider orelse return error.UnresolvedRequirement;
        if (provider_index == requirement.package_index or edges[provider_index][requirement.package_index]) continue;
        edges[provider_index][requirement.package_index] = true;
        indegree[requirement.package_index] += 1;
    }

    var emitted: [max_packages]bool = .{false} ** max_packages;
    var result_len: usize = 0;
    while (result_len < packages.len) : (result_len += 1) {
        var selected: ?usize = null;
        var index: usize = 0;
        while (index < packages.len) : (index += 1) {
            if (emitted[index] or indegree[index] != 0) continue;
            if (selected == null or
                (packages[index].priority == .foundation and packages[selected.?].priority != .foundation))
            {
                selected = index;
            }
        }
        const next = selected orelse return error.DependencyCycle;
        out[result_len] = @intCast(next);
        emitted[next] = true;
        var consumer: usize = 0;
        while (consumer < packages.len) : (consumer += 1) {
            if (edges[next][consumer]) indegree[consumer] -= 1;
        }
    }
    return out[0..result_len];
}

fn validReason(value: []const u8) bool {
    if (value.len > max_reason) return false;
    for (value) |byte| {
        if (byte < 0x20 or byte >= 0x7f or byte == ';' or byte == '=') return false;
    }
    return true;
}

fn lineFieldsKnown(line: []const u8, known: []const []const u8) bool {
    var fields = std.mem.splitScalar(u8, line, ';');
    _ = fields.next();
    while (fields.next()) |field| {
        const equal = std.mem.indexOfScalar(u8, field, '=') orelse return false;
        var found = false;
        for (known) |name| {
            if (std.mem.eql(u8, field[0..equal], name)) {
                found = true;
                break;
            }
        }
        if (!found) return false;
    }
    return true;
}

fn fieldValue(line: []const u8, key: []const u8) ?[]const u8 {
    var fields = std.mem.splitScalar(u8, line, ';');
    while (fields.next()) |field| {
        if (startsWith(field, key)) return field[key.len..];
    }
    return null;
}

fn lastLineStart(data: []const u8, prefix: []const u8) ?usize {
    var end = data.len;
    while (end != 0 and (data[end - 1] == '\n' or data[end - 1] == '\r')) end -= 1;
    const start = if (std.mem.lastIndexOfScalar(u8, data[0..end], '\n')) |at| at + 1 else 0;
    return if (startsWith(data[start..end], prefix)) start else null;
}

fn trimLine(value: []const u8) []const u8 {
    return std.mem.trimEnd(u8, value, "\r\n");
}

fn startsWith(value: []const u8, prefix: []const u8) bool {
    return value.len >= prefix.len and std.mem.eql(u8, value[0..prefix.len], prefix);
}

fn parseU32(value: []const u8) ?u32 {
    const parsed = parseU64(value) orelse return null;
    return if (parsed <= std.math.maxInt(u32)) @intCast(parsed) else null;
}

fn parseU64(value: []const u8) ?u64 {
    if (value.len == 0) return null;
    var result: u64 = 0;
    for (value) |byte| {
        if (byte < '0' or byte > '9') return null;
        result = std.math.mul(u64, result, 10) catch return null;
        result = std.math.add(u64, result, byte - '0') catch return null;
    }
    return result;
}

fn copyTextZ(out: []u8, value: []const u8) ?usize {
    if (value.len >= out.len) return null;
    @memset(out, 0);
    @memcpy(out[0..value.len], value);
    return value.len;
}

fn appendKeyU64(out: []u8, len: *usize, key: []const u8, value: u64) bool {
    return appendText(out, len, key) and appendU64(out, len, value) and appendByte(out, len, '\n');
}

fn appendU64(out: []u8, len: *usize, value: u64) bool {
    var digits: [20]u8 = undefined;
    const rendered = std.fmt.bufPrint(digits[0..], "{d}", .{value}) catch return false;
    return appendText(out, len, rendered);
}

fn appendText(out: []u8, len: *usize, value: []const u8) bool {
    if (len.* > out.len or value.len > out.len - len.*) return false;
    @memcpy(out[len.* .. len.* + value.len], value);
    len.* += value.len;
    return true;
}

fn appendByte(out: []u8, len: *usize, value: u8) bool {
    if (len.* >= out.len) return false;
    out[len.*] = value;
    len.* += 1;
    return true;
}

fn fillEntry(entry: *PackageEntry, index: u8, package: []const u8, priority: r4u_manifest.Priority) void {
    entry.* = .{ .order = index, .priority = priority };
    entry.path_len = copyTextZ(entry.path[0..], if (index == 0) "C:\\R4OS\\UPDATE\\INBOX\\A.R4U" else "C:\\R4OS\\UPDATE\\INBOX\\B.R4U").?;
    entry.package_len = copyTextZ(entry.package[0..], package).?;
    entry.package_version_len = copyTextZ(entry.package_version[0..], "1.0.0").?;
    entry.release_len = copyTextZ(entry.release[0..], "0.63.13").?;
    entry.package_length = 1000 + @as(u64, index);
    entry.package_digest = 100 + @as(u32, index);
    entry.manifest_checksum = 200 + @as(u32, index);
    entry.component_digest = 300 + @as(u32, index);
}

test "batch journal roundtrip preserves package bindings and pending restart" {
    var journal: BatchJournal = .{
        .valid = true,
        .batch_generation = 4,
        .journal_generation = 7,
        .phase = .pending_restart,
        .package_count = 2,
        .current_package = 2,
    };
    journal.source_release_len = copyTextZ(journal.source_release[0..], "0.63.12").?;
    journal.target_release_len = copyTextZ(journal.target_release[0..], "0.63.13").?;
    fillEntry(&journal.packages[0], 1, "APP", .normal);
    fillEntry(&journal.packages[1], 0, "CORE", .foundation);
    var bytes: [journal_max]u8 = undefined;
    const encoded = serializeJournal(&journal, bytes[0..]) orelse return error.TestUnexpectedResult;
    var parsed: BatchJournal = .{};
    try std.testing.expect(parseJournalInto(encoded, 1, &parsed));
    try std.testing.expectEqual(Phase.pending_restart, parsed.phase);
    try std.testing.expectEqual(@as(u8, 1), parsed.slot);
    try std.testing.expectEqualStrings("CORE", parsed.packages[1].packageText());
    try std.testing.expectEqual(@as(u8, 1), parsed.packages[0].order);
}

test "dependency order beats foundation priority and keeps stable ties" {
    const packages = [_]PlanPackage{
        .{ .priority = .normal },
        .{ .priority = .foundation },
        .{ .priority = .normal },
    };
    const components = [_]PlanComponent{
        .{ .package_index = 0, .kind = .r4x, .name = "APP", .target = "/R4OS/SOFTWARE/APP/APP.R4X", .version = "2.0.0" },
        .{ .package_index = 1, .kind = .r4l, .name = "R4STD", .target = "/R4OS/LIBS/R4STD.R4L", .version = "2.0.0" },
        .{ .package_index = 2, .kind = .r4x, .name = "TOOL", .target = "/R4OS/SOFTWARE/TOOL/TOOL.R4X", .version = "2.0.0" },
    };
    const requirements = [_]PlanRequirement{
        .{ .package_index = 1, .kind = .r4x, .name = "APP", .target = "/R4OS/SOFTWARE/APP/APP.R4X", .version = "2.0.0" },
    };
    var order: [max_packages]u8 = undefined;
    const planned = try planOrder(packages[0..], components[0..], requirements[0..], order[0..]);
    try std.testing.expectEqualSlices(u8, &.{ 0, 1, 2 }, planned);
}

test "planner rejects unresolved and cyclic package requirements" {
    const packages = [_]PlanPackage{ .{}, .{} };
    const components = [_]PlanComponent{
        .{ .package_index = 0, .kind = .r4x, .name = "A", .target = "/R4OS/SOFTWARE/A/A.R4X", .version = "1.0.0" },
        .{ .package_index = 1, .kind = .r4x, .name = "B", .target = "/R4OS/SOFTWARE/B/B.R4X", .version = "1.0.0" },
    };
    var order: [max_packages]u8 = undefined;
    const unresolved = [_]PlanRequirement{
        .{ .package_index = 0, .kind = .r4l, .name = "MISS", .target = "/R4OS/LIBS/MISS.R4L", .version = "1.0.0" },
    };
    try std.testing.expectError(error.UnresolvedRequirement, planOrder(packages[0..], components[0..], unresolved[0..], order[0..]));
    const cyclic = [_]PlanRequirement{
        .{ .package_index = 0, .kind = .r4x, .name = "B", .target = "/R4OS/SOFTWARE/B/B.R4X", .version = "1.0.0" },
        .{ .package_index = 1, .kind = .r4x, .name = "A", .target = "/R4OS/SOFTWARE/A/A.R4X", .version = "1.0.0" },
    };
    try std.testing.expectError(error.DependencyCycle, planOrder(packages[0..], components[0..], cyclic[0..], order[0..]));
}
