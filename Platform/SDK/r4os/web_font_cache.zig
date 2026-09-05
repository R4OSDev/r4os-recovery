const std = @import("std");

pub const root_path = "C:\\R4OS\\Temp\\Klickifax\\Cache\\Fonts\\";
pub const objects_path = root_path ++ "Objects\\";
pub const staging_path = root_path ++ "Staging\\";
pub const catalog_path = root_path ++ "Catalog.R4S";

pub const digest_bytes: usize = std.crypto.hash.sha2.Sha256.digest_length;
pub const digest_hex_bytes: usize = digest_bytes * 2;
pub const object_digest_component_hex_bytes: usize = 8;
pub const object_digest_component_count: usize = digest_hex_bytes / object_digest_component_hex_bytes;
pub const object_directory_depth: usize = object_digest_component_count - 1;
pub const object_file_extension = ".FNT";
pub const max_entries: usize = 128;
pub const max_source_url_bytes: usize = 767;
pub const max_mime_bytes: usize = 95;
pub const max_path_bytes: usize = 239;

pub const default_max_object_bytes: u64 = 8 * 1024 * 1024;
pub const default_max_total_bytes: u64 = 32 * 1024 * 1024;
pub const default_max_age_seconds: u64 = 30 * 24 * 60 * 60;

pub const Digest = [digest_bytes]u8;
pub const Error = error{
    EmptyContent,
    ObjectTooLarge,
    InvalidSourceUrl,
    InvalidMime,
    UnsupportedFormat,
    ValueTooLong,
    PathTooLong,
    InvalidTransaction,
    InvalidMetadata,
    DigestCollision,
    CatalogFull,
    ReservationTooLarge,
    StageSizeMismatch,
    StageDigestMismatch,
};

pub fn Fixed(comptime capacity: usize) type {
    return struct {
        storage: [capacity + 1]u8 = .{0} ** (capacity + 1),
        len: usize = 0,

        const Self = @This();

        pub fn set(self: *Self, value: []const u8) Error!void {
            if (value.len > capacity) return error.ValueTooLong;
            @memset(&self.storage, 0);
            if (value.len > 0) @memcpy(self.storage[0..value.len], value);
            self.len = value.len;
        }

        pub fn bytes(self: *const Self) []const u8 {
            return self.storage[0..self.len];
        }
    };
}

pub const SourceUrl = Fixed(max_source_url_bytes);
pub const Mime = Fixed(max_mime_bytes);
pub const Path = Fixed(max_path_bytes);

pub const FontFormat = enum(u8) {
    woff,
    woff2,
    truetype,
    opentype,
    collection,
    embedded_opentype,
    unknown,

    pub fn label(self: FontFormat) []const u8 {
        return switch (self) {
            .woff => "woff",
            .woff2 => "woff2",
            .truetype => "truetype",
            .opentype => "opentype",
            .collection => "collection",
            .embedded_opentype => "embedded-opentype",
            .unknown => "unknown",
        };
    }
};

pub const Metadata = struct {
    occupied: bool = false,
    id: Digest = [_]u8{0} ** digest_bytes,
    source_url: SourceUrl = .{},
    format: FontFormat = .unknown,
    mime: Mime = .{},
    size: u64 = 0,
    checksum: Digest = [_]u8{0} ** digest_bytes,
    created_at: u64 = 0,
    last_access: u64 = 0,

    pub fn valid(self: *const Metadata) bool {
        return self.occupied and self.size > 0 and self.source_url.len > 0 and self.mime.len > 0 and
            self.format != .unknown and std.mem.eql(u8, &self.id, &self.checksum) and self.last_access >= self.created_at;
    }
};

pub const Prepared = struct {
    metadata: Metadata,
};

pub const Policy = struct {
    max_object_bytes: u64 = default_max_object_bytes,
    max_total_bytes: u64 = default_max_total_bytes,
    max_age_seconds: u64 = default_max_age_seconds,
    max_entry_count: usize = max_entries,

    pub fn valid(self: Policy) bool {
        return self.max_object_bytes > 0 and self.max_total_bytes >= self.max_object_bytes and
            self.max_entry_count > 0 and self.max_entry_count <= max_entries;
    }

    pub fn acceptsObjectSize(self: Policy, size: u64) bool {
        return self.valid() and size > 0 and size <= self.max_object_bytes;
    }
};

pub fn prepare(
    bytes: []const u8,
    source_url: []const u8,
    mime: []const u8,
    format: FontFormat,
    now: u64,
    policy: Policy,
) Error!Prepared {
    if (!policy.valid()) return error.ReservationTooLarge;
    if (bytes.len == 0) return error.EmptyContent;
    if (!policy.acceptsObjectSize(@intCast(bytes.len))) return error.ObjectTooLarge;
    if (!validSourceUrl(source_url)) return error.InvalidSourceUrl;
    if (!validMime(mime)) return error.InvalidMime;
    if (format == .unknown) return error.UnsupportedFormat;
    var result = Prepared{ .metadata = .{
        .occupied = true,
        .format = format,
        .size = bytes.len,
        .created_at = now,
        .last_access = now,
    } };
    std.crypto.hash.sha2.Sha256.hash(bytes, &result.metadata.id, .{});
    result.metadata.checksum = result.metadata.id;
    try result.metadata.source_url.set(source_url);
    try result.metadata.mime.set(mime);
    return result;
}

pub fn contentId(bytes: []const u8) Digest {
    var result: Digest = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes, &result, .{});
    return result;
}

pub fn writeDigestHex(digest: Digest, output: *[digest_hex_bytes]u8) void {
    const alphabet = "0123456789abcdef";
    for (digest, 0..) |byte, index| {
        output[index * 2] = alphabet[byte >> 4];
        output[index * 2 + 1] = alphabet[byte & 0x0f];
    }
}

fn validSourceUrl(value: []const u8) bool {
    if (value.len == 0 or value.len > max_source_url_bytes) return false;
    if (!startsWithIgnoreCase(value, "http://") and !startsWithIgnoreCase(value, "https://")) return false;
    for (value) |byte| if (byte < 0x21 or byte == 0x7f) return false;
    return true;
}

fn validMime(value: []const u8) bool {
    if (value.len == 0 or value.len > max_mime_bytes or std.mem.indexOfScalar(u8, value, '/') == null) return false;
    for (value) |byte| if (byte < 0x21 or byte > 0x7e or byte == ';') return false;
    return true;
}

fn startsWithIgnoreCase(value: []const u8, prefix: []const u8) bool {
    return value.len >= prefix.len and std.ascii.eqlIgnoreCase(value[0..prefix.len], prefix);
}

pub const Disposition = enum(u8) {
    new_object,
    duplicate,
};

pub const Catalog = struct {
    entries: [max_entries]Metadata = [_]Metadata{.{}} ** max_entries,
    count: usize = 0,
    total_bytes: u64 = 0,

    pub fn classify(self: *const Catalog, candidate: *const Prepared) Error!Disposition {
        if (!candidate.metadata.valid()) return error.InvalidMetadata;
        for (&self.entries) |*entry| {
            if (!entry.occupied or !std.mem.eql(u8, &entry.id, &candidate.metadata.id)) continue;
            if (!entry.valid() or !std.mem.eql(u8, &entry.checksum, &candidate.metadata.checksum) or
                entry.size != candidate.metadata.size) return error.DigestCollision;
            return .duplicate;
        }
        return .new_object;
    }

    pub fn find(self: *const Catalog, id: Digest) ?*const Metadata {
        for (&self.entries) |*entry| if (entry.occupied and std.mem.eql(u8, &entry.id, &id)) return entry;
        return null;
    }

    pub fn recordCommitted(self: *Catalog, candidate: *const Prepared) Error!Disposition {
        const disposition = try self.classify(candidate);
        if (disposition == .duplicate) {
            for (&self.entries) |*entry| {
                if (!entry.occupied or !std.mem.eql(u8, &entry.id, &candidate.metadata.id)) continue;
                const created_at = @min(entry.created_at, candidate.metadata.created_at);
                const last_access = @max(entry.last_access, candidate.metadata.last_access);
                entry.* = candidate.metadata;
                entry.created_at = created_at;
                entry.last_access = @max(last_access, created_at);
                return disposition;
            }
            unreachable;
        }
        if (self.count >= self.entries.len) return error.CatalogFull;
        const new_total = std.math.add(u64, self.total_bytes, candidate.metadata.size) catch return error.CatalogFull;
        for (&self.entries) |*entry| {
            if (entry.occupied) continue;
            entry.* = candidate.metadata;
            self.count += 1;
            self.total_bytes = new_total;
            return disposition;
        }
        return error.CatalogFull;
    }

    pub fn touch(self: *Catalog, id: Digest, now: u64) bool {
        for (&self.entries) |*entry| {
            if (!entry.occupied or !std.mem.eql(u8, &entry.id, &id)) continue;
            entry.last_access = @max(entry.last_access, now);
            return true;
        }
        return false;
    }

    pub fn remove(self: *Catalog, id: Digest) ?Metadata {
        for (&self.entries) |*entry| {
            if (!entry.occupied or !std.mem.eql(u8, &entry.id, &id)) continue;
            const removed = entry.*;
            entry.* = .{};
            self.count -|= 1;
            self.total_bytes -|= removed.size;
            return removed;
        }
        return null;
    }

    pub fn validate(self: *const Catalog) bool {
        var count: usize = 0;
        var total: u64 = 0;
        for (&self.entries, 0..) |*entry, index| {
            if (!entry.occupied) continue;
            if (!entry.valid()) return false;
            for (self.entries[index + 1 ..]) |later| {
                if (later.occupied and std.mem.eql(u8, &entry.id, &later.id)) return false;
            }
            count += 1;
            total = std.math.add(u64, total, entry.size) catch return false;
        }
        return count == self.count and total == self.total_bytes;
    }
};

pub const PublishResolution = enum(u8) {
    publish_new,
    reuse_existing,
};

pub const TargetObservation = struct {
    exists: bool = false,
    size: u64 = 0,
    checksum: Digest = [_]u8{0} ** digest_bytes,
};

pub const CommitStep = enum(u8) {
    create_stage_exclusive,
    write_object_exact,
    sync_object_stage,
    verify_object_stage,
    publish_object_no_replace,
    write_catalog_stage,
    sync_catalog_stage,
    publish_catalog_replace,
    discard_stage,
};

pub const commit_steps = [_]CommitStep{
    .create_stage_exclusive,
    .write_object_exact,
    .sync_object_stage,
    .verify_object_stage,
    .publish_object_no_replace,
    .write_catalog_stage,
    .sync_catalog_stage,
    .publish_catalog_replace,
    .discard_stage,
};

pub const AtomicPlan = struct {
    transaction_id: u64,
    disposition: Disposition,
    id: Digest,
    expected_size: u64,
    expected_checksum: Digest,
    object_stage: Path = .{},
    object_target: Path,
    catalog_stage: Path,
    catalog_target: Path,
    write_object: bool,
    same_volume_required: bool = true,
    object_publish_requires_absent_target: bool = true,
    catalog_publish_after_object: bool = true,
    consume_stage_on_publish: bool = true,
};

pub fn planAtomicCommit(catalog: *const Catalog, candidate: *const Prepared, transaction_id: u64) Error!AtomicPlan {
    if (transaction_id == 0) return error.InvalidTransaction;
    const disposition = try catalog.classify(candidate);
    var plan = AtomicPlan{
        .transaction_id = transaction_id,
        .disposition = disposition,
        .id = candidate.metadata.id,
        .expected_size = candidate.metadata.size,
        .expected_checksum = candidate.metadata.checksum,
        .object_target = try objectPath(candidate.metadata.id),
        .catalog_stage = try catalogStagePath(transaction_id),
        .catalog_target = try fixedPath(catalog_path),
        .write_object = disposition == .new_object,
    };
    if (plan.write_object) plan.object_stage = try objectStagePath(candidate.metadata.id, transaction_id);
    return plan;
}

pub fn resolveTarget(candidate: *const Prepared, observation: TargetObservation) Error!PublishResolution {
    if (!observation.exists) return .publish_new;
    if (observation.size != candidate.metadata.size or
        !std.mem.eql(u8, &observation.checksum, &candidate.metadata.checksum)) return error.DigestCollision;
    return .reuse_existing;
}

/// Reconciles the catalog decision with the immutable object observed just
/// before publishing.  This closes both races: an equal object published by
/// another writer is reused, while a catalog entry whose object disappeared
/// is rebuilt from the already verified candidate bytes.
pub fn reconcileAtomicPlan(plan: *AtomicPlan, candidate: *const Prepared, observation: TargetObservation) Error!PublishResolution {
    if (!std.mem.eql(u8, &plan.id, &candidate.metadata.id) or plan.expected_size != candidate.metadata.size) return error.InvalidMetadata;
    const resolution = try resolveTarget(candidate, observation);
    plan.write_object = resolution == .publish_new;
    plan.object_stage = if (plan.write_object) try objectStagePath(plan.id, plan.transaction_id) else Path{};
    return resolution;
}

pub fn validateStage(plan: *const AtomicPlan, observed_size: u64, observed_checksum: Digest) Error!void {
    if (!plan.write_object) return;
    if (observed_size != plan.expected_size) return error.StageSizeMismatch;
    if (!std.mem.eql(u8, &observed_checksum, &plan.expected_checksum)) return error.StageDigestMismatch;
}

pub fn objectPath(id: Digest) Error!Path {
    var hex: [digest_hex_bytes]u8 = undefined;
    writeDigestHex(id, &hex);
    var buffer: [max_path_bytes]u8 = undefined;
    var len: usize = 0;
    if (!appendPathBytes(buffer[0..], &len, objects_path)) return error.PathTooLong;
    var component: usize = 0;
    while (component < object_digest_component_count) : (component += 1) {
        const start = component * object_digest_component_hex_bytes;
        if (!appendPathBytes(buffer[0..], &len, hex[start .. start + object_digest_component_hex_bytes])) return error.PathTooLong;
        if (component + 1 < object_digest_component_count) {
            if (!appendPathBytes(buffer[0..], &len, "\\")) return error.PathTooLong;
        } else if (!appendPathBytes(buffer[0..], &len, object_file_extension)) return error.PathTooLong;
    }
    return fixedPath(buffer[0..len]);
}

pub fn objectParentPath(id: Digest) Error!Path {
    const object = try objectPath(id);
    const leaf_bytes = object_digest_component_hex_bytes + object_file_extension.len;
    if (object.len <= leaf_bytes) return error.PathTooLong;
    return fixedPath(object.bytes()[0 .. object.len - leaf_bytes]);
}

/// Parses only the canonical hierarchical content-object shape.  Every
/// digest component is an eight-character FAT short name and the final leaf
/// is `XXXXXXXX.FNT`; all 64 SHA-256 hex characters participate in the
/// identity.  ASCII case and slash direction are accepted because R4OS file
/// lookup is case-insensitive and normalizes separators.
pub fn digestFromObjectPath(raw: []const u8) ?Digest {
    const expected_len = objects_path.len +
        object_directory_depth * (object_digest_component_hex_bytes + 1) +
        object_digest_component_hex_bytes + object_file_extension.len;
    if (raw.len != expected_len or !pathPrefixEqual(raw[0..objects_path.len], objects_path)) return null;

    var digest: Digest = [_]u8{0} ** digest_bytes;
    var cursor: usize = objects_path.len;
    var hex_index: usize = 0;
    var component: usize = 0;
    while (component < object_digest_component_count) : (component += 1) {
        var component_index: usize = 0;
        while (component_index < object_digest_component_hex_bytes) : (component_index += 1) {
            const nibble = hexNibble(raw[cursor]) orelse return null;
            const byte_index = hex_index / 2;
            if (hex_index % 2 == 0) {
                digest[byte_index] = nibble << 4;
            } else {
                digest[byte_index] |= nibble;
            }
            cursor += 1;
            hex_index += 1;
        }
        if (component + 1 < object_digest_component_count) {
            if (!isPathSeparator(raw[cursor])) return null;
            cursor += 1;
        }
    }
    if (!std.ascii.eqlIgnoreCase(raw[cursor..], object_file_extension)) return null;
    return digest;
}

pub fn objectStagePath(id: Digest, transaction_id: u64) Error!Path {
    if (transaction_id == 0) return error.InvalidTransaction;
    var hex: [digest_hex_bytes]u8 = undefined;
    writeDigestHex(id, &hex);
    var buffer: [max_path_bytes]u8 = undefined;
    const value = std.fmt.bufPrint(buffer[0..], "{s}{s}.{x:0>16}.FONT.PART", .{ staging_path, hex[0..], transaction_id }) catch return error.PathTooLong;
    return fixedPath(value);
}

pub fn catalogStagePath(transaction_id: u64) Error!Path {
    if (transaction_id == 0) return error.InvalidTransaction;
    var buffer: [max_path_bytes]u8 = undefined;
    const value = std.fmt.bufPrint(buffer[0..], "{s}Catalog.{x:0>16}.R4S.PART", .{ staging_path, transaction_id }) catch return error.PathTooLong;
    return fixedPath(value);
}

fn fixedPath(value: []const u8) Error!Path {
    var path = Path{};
    path.set(value) catch return error.PathTooLong;
    return path;
}

fn appendPathBytes(output: []u8, len: *usize, value: []const u8) bool {
    if (value.len > output.len -| len.*) return false;
    if (value.len > 0) @memcpy(output[len.* .. len.* + value.len], value);
    len.* += value.len;
    return true;
}

fn pathPrefixEqual(value: []const u8, expected: []const u8) bool {
    if (value.len != expected.len) return false;
    for (value, expected) |left, right| {
        if (isPathSeparator(left) and isPathSeparator(right)) continue;
        if (std.ascii.toLower(left) != std.ascii.toLower(right)) return false;
    }
    return true;
}

fn isPathSeparator(byte: u8) bool {
    return byte == '\\' or byte == '/';
}

fn hexNibble(byte: u8) ?u8 {
    return switch (byte) {
        '0'...'9' => byte - '0',
        'a'...'f' => byte - 'a' + 10,
        'A'...'F' => byte - 'A' + 10,
        else => null,
    };
}

pub const CleanupReason = enum(u8) {
    expired,
    entry_limit,
    size_limit,
};

pub const CleanupAction = struct {
    id: Digest,
    object_path: Path,
    size: u64,
    last_access: u64,
    reason: CleanupReason,
};

pub const Reservation = struct {
    bytes: u64 = 0,
    entries: usize = 0,
};

pub const CleanupPlan = struct {
    actions: [max_entries]CleanupAction = undefined,
    count: usize = 0,
    resulting_bytes: u64 = 0,
    resulting_entries: usize = 0,
    reserved_bytes: u64 = 0,
    reserved_entries: usize = 0,
    publish_catalog_before_object_deletes: bool = true,

    fn append(self: *CleanupPlan, entry: *const Metadata, reason: CleanupReason) Error!void {
        if (self.count >= self.actions.len) return error.CatalogFull;
        self.actions[self.count] = .{
            .id = entry.id,
            .object_path = try objectPath(entry.id),
            .size = entry.size,
            .last_access = entry.last_access,
            .reason = reason,
        };
        self.count += 1;
    }
};

pub const AdmissionPlan = struct {
    disposition: Disposition,
    cleanup: CleanupPlan,
    atomic: AtomicPlan,
};

pub fn planAdmission(
    catalog: *const Catalog,
    candidate: *const Prepared,
    policy: Policy,
    now: u64,
    transaction_id: u64,
) Error!AdmissionPlan {
    const disposition = try catalog.classify(candidate);
    const reservation = if (disposition == .new_object)
        Reservation{ .bytes = candidate.metadata.size, .entries = 1 }
    else
        Reservation{};
    return .{
        .disposition = disposition,
        .cleanup = try planCleanup(catalog, policy, now, reservation, candidate.metadata.id),
        .atomic = try planAtomicCommit(catalog, candidate, transaction_id),
    };
}

pub fn planCleanup(
    catalog: *const Catalog,
    policy: Policy,
    now: u64,
    reservation: Reservation,
    preserve_id: ?Digest,
) Error!CleanupPlan {
    if (!policy.valid() or reservation.bytes > policy.max_total_bytes or reservation.entries > policy.max_entry_count) return error.ReservationTooLarge;
    if (!catalog.validate()) return error.InvalidMetadata;
    var selected = [_]bool{false} ** max_entries;
    var plan = CleanupPlan{
        .resulting_bytes = catalog.total_bytes,
        .resulting_entries = catalog.count,
        .reserved_bytes = reservation.bytes,
        .reserved_entries = reservation.entries,
    };

    while (oldestCandidate(catalog, &selected, preserve_id, now, policy.max_age_seconds, true)) |index| {
        selected[index] = true;
        const entry = &catalog.entries[index];
        try plan.append(entry, .expired);
        plan.resulting_bytes -|= entry.size;
        plan.resulting_entries -|= 1;
    }

    while (exceedsLimits(plan.resulting_bytes, plan.resulting_entries, reservation, policy)) {
        const reason: CleanupReason = if (plan.resulting_entries + reservation.entries > policy.max_entry_count) .entry_limit else .size_limit;
        const index = oldestCandidate(catalog, &selected, preserve_id, now, 0, false) orelse return error.ReservationTooLarge;
        selected[index] = true;
        const entry = &catalog.entries[index];
        try plan.append(entry, reason);
        plan.resulting_bytes -|= entry.size;
        plan.resulting_entries -|= 1;
    }
    plan.resulting_bytes = std.math.add(u64, plan.resulting_bytes, reservation.bytes) catch return error.ReservationTooLarge;
    plan.resulting_entries += reservation.entries;
    return plan;
}

pub fn applyCleanup(catalog: *Catalog, plan: *const CleanupPlan) Error!void {
    if (plan.count > plan.actions.len) return error.InvalidMetadata;
    for (plan.actions[0..plan.count], 0..) |action, index| {
        const entry = catalog.find(action.id) orelse return error.InvalidMetadata;
        if (entry.size != action.size) return error.InvalidMetadata;
        for (plan.actions[index + 1 .. plan.count]) |later| {
            if (std.mem.eql(u8, &action.id, &later.id)) return error.InvalidMetadata;
        }
    }
    for (plan.actions[0..plan.count]) |action| {
        if (catalog.remove(action.id) == null) return error.InvalidMetadata;
    }
    // A reservation is reflected in the resulting figures but becomes real
    // only after recordCommitted.  Cleanup is always applied first.
    if (plan.resulting_entries < plan.reserved_entries or plan.resulting_bytes < plan.reserved_bytes or
        catalog.count != plan.resulting_entries - plan.reserved_entries or
        catalog.total_bytes != plan.resulting_bytes - plan.reserved_bytes) return error.InvalidMetadata;
}

fn exceedsLimits(bytes: u64, entries: usize, reservation: Reservation, policy: Policy) bool {
    if (entries > policy.max_entry_count or reservation.entries > policy.max_entry_count - entries) return true;
    if (bytes > policy.max_total_bytes or reservation.bytes > policy.max_total_bytes - bytes) return true;
    return false;
}

fn oldestCandidate(
    catalog: *const Catalog,
    selected: *const [max_entries]bool,
    preserve_id: ?Digest,
    now: u64,
    max_age: u64,
    expired_only: bool,
) ?usize {
    var best: ?usize = null;
    for (&catalog.entries, 0..) |*entry, index| {
        if (!entry.occupied or selected[index]) continue;
        if (preserve_id) |preserved| if (std.mem.eql(u8, &entry.id, &preserved)) continue;
        if (expired_only and !expired(entry.last_access, now, max_age)) continue;
        if (best == null or lessEvictionCandidate(entry, &catalog.entries[best.?])) best = index;
    }
    return best;
}

fn expired(last_access: u64, now: u64, max_age: u64) bool {
    // Zero is the explicit "wall clock unavailable" value.  It is neither
    // Unix epoch nor evidence that an entry is ancient: an entry created
    // while RTC is unavailable starts ageing with its first later valid hit.
    return max_age > 0 and now > 0 and last_access > 0 and now >= last_access and now - last_access >= max_age;
}

fn lessEvictionCandidate(left: *const Metadata, right: *const Metadata) bool {
    if (left.last_access != right.last_access) return left.last_access < right.last_access;
    return std.mem.order(u8, &left.id, &right.id) == .lt;
}

fn testPrepared(seed: u8, size: u64, last_access: u64) Prepared {
    var source_buffer: [64]u8 = undefined;
    const source = std.fmt.bufPrint(source_buffer[0..], "https://fonts.example/{d}.woff2", .{seed}) catch unreachable;
    var prepared = prepare(&.{seed}, source, "font/woff2", .woff2, last_access, .{}) catch unreachable;
    prepared.metadata.size = size;
    return prepared;
}

test "font cache prepares SHA-256 metadata and content-addressed paths" {
    const prepared = try prepare("abc", "https://fonts.example/family.woff2", "font/woff2", .woff2, 123, .{});
    var hex: [digest_hex_bytes]u8 = undefined;
    writeDigestHex(prepared.metadata.id, &hex);
    try std.testing.expectEqualStrings("ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", hex[0..]);
    try std.testing.expectEqualStrings("https://fonts.example/family.woff2", prepared.metadata.source_url.bytes());
    try std.testing.expectEqualStrings("font/woff2", prepared.metadata.mime.bytes());
    try std.testing.expectEqual(FontFormat.woff2, prepared.metadata.format);
    try std.testing.expectEqual(@as(u64, 3), prepared.metadata.size);
    try std.testing.expectEqual(@as(u64, 123), prepared.metadata.last_access);
    try std.testing.expect(prepared.metadata.valid());
    const path = try objectPath(prepared.metadata.id);
    try std.testing.expectEqualStrings(
        "C:\\R4OS\\Temp\\Klickifax\\Cache\\Fonts\\Objects\\ba7816bf\\8f01cfea\\414140de\\5dae2223\\b00361a3\\96177a9c\\b410ff61\\f20015ad.FNT",
        path.bytes(),
    );
    const parent = try objectParentPath(prepared.metadata.id);
    try std.testing.expectEqualStrings(
        "C:\\R4OS\\Temp\\Klickifax\\Cache\\Fonts\\Objects\\ba7816bf\\8f01cfea\\414140de\\5dae2223\\b00361a3\\96177a9c\\b410ff61\\",
        parent.bytes(),
    );
    const parsed = digestFromObjectPath(path.bytes()).?;
    try std.testing.expect(std.mem.eql(u8, &parsed, &prepared.metadata.id));
    const stage = try objectStagePath(prepared.metadata.id, 0x2a);
    try std.testing.expect(std.mem.startsWith(u8, stage.bytes(), staging_path));
    try std.testing.expect(std.mem.endsWith(u8, stage.bytes(), ".000000000000002a.FONT.PART"));
}

test "content object path uses only 8.3 digest components and round trips all SHA-256 bits" {
    const id = contentId("hierarchical object path");
    const path = try objectPath(id);
    var components = std.mem.splitScalar(u8, path.bytes()[objects_path.len..], '\\');
    var count: usize = 0;
    while (components.next()) |component| : (count += 1) {
        if (count < object_directory_depth) {
            try std.testing.expectEqual(object_digest_component_hex_bytes, component.len);
            for (component) |byte| try std.testing.expect(hexNibble(byte) != null);
        } else {
            try std.testing.expectEqual(object_digest_component_hex_bytes + object_file_extension.len, component.len);
            for (component[0..object_digest_component_hex_bytes]) |byte| try std.testing.expect(hexNibble(byte) != null);
            try std.testing.expect(std.ascii.eqlIgnoreCase(component[object_digest_component_hex_bytes..], object_file_extension));
        }
    }
    try std.testing.expectEqual(object_digest_component_count, count);

    var alternate: [max_path_bytes]u8 = undefined;
    @memcpy(alternate[0..path.len], path.bytes());
    for (alternate[0..path.len]) |*byte| {
        if (byte.* == '\\') byte.* = '/' else byte.* = std.ascii.toUpper(byte.*);
    }
    const parsed = digestFromObjectPath(alternate[0..path.len]).?;
    try std.testing.expect(std.mem.eql(u8, &parsed, &id));

    var corrupt: [max_path_bytes]u8 = undefined;
    @memcpy(corrupt[0..path.len], path.bytes());
    corrupt[objects_path.len] = 'g';
    try std.testing.expect(digestFromObjectPath(corrupt[0..path.len]) == null);
    try std.testing.expect(digestFromObjectPath(path.bytes()[0 .. path.len - 1]) == null);
    try std.testing.expect(digestFromObjectPath("C:\\R4OS\\Temp\\Klickifax\\Cache\\Fonts\\Objects\\01234567.FNT") == null);
}

test "font cache preparation rejects invalid and accepts exact boundaries" {
    const defaults = Policy{};
    try std.testing.expect(!defaults.acceptsObjectSize(0));
    try std.testing.expect(defaults.acceptsObjectSize(default_max_object_bytes));
    try std.testing.expect(!defaults.acceptsObjectSize(default_max_object_bytes + 1));
    try std.testing.expectError(error.EmptyContent, prepare("", "https://fonts.example/a", "font/woff2", .woff2, 0, .{}));
    try std.testing.expectError(error.ObjectTooLarge, prepare("12", "https://fonts.example/a", "font/woff2", .woff2, 0, .{
        .max_object_bytes = 1,
        .max_total_bytes = 1,
    }));
    try std.testing.expectError(error.InvalidSourceUrl, prepare("x", "file:///font", "font/woff2", .woff2, 0, .{}));
    try std.testing.expectError(error.InvalidSourceUrl, prepare("x", "https://fonts.example/a b", "font/woff2", .woff2, 0, .{}));
    try std.testing.expectError(error.InvalidMime, prepare("x", "https://fonts.example/a", "woff2", .woff2, 0, .{}));
    try std.testing.expectError(error.InvalidMime, prepare("x", "https://fonts.example/a", "font/woff2;charset=utf-8", .woff2, 0, .{}));
    try std.testing.expectError(error.UnsupportedFormat, prepare("x", "https://fonts.example/a", "application/octet-stream", .unknown, 0, .{}));
    try std.testing.expectError(error.ReservationTooLarge, prepare("x", "https://fonts.example/a", "font/woff2", .woff2, 0, .{
        .max_object_bytes = 2,
        .max_total_bytes = 1,
    }));

    var url = [_]u8{'a'} ** max_source_url_bytes;
    @memcpy(url[0..8], "https://");
    var mime = [_]u8{'a'} ** max_mime_bytes;
    mime[4] = '/';
    const boundary = try prepare("x", url[0..], mime[0..], .opentype, 1, .{});
    try std.testing.expectEqual(max_source_url_bytes, boundary.metadata.source_url.len);
    try std.testing.expectEqual(max_mime_bytes, boundary.metadata.mime.len);
}

test "catalog deduplicates content updates access metadata and rejects collisions" {
    var catalog = Catalog{};
    var first = try prepare("same bytes", "https://a.example/font.woff", "font/woff", .woff, 10, .{});
    try std.testing.expectEqual(Disposition.new_object, try catalog.recordCommitted(&first));
    try std.testing.expectEqual(@as(usize, 1), catalog.count);
    try std.testing.expectEqual(@as(u64, 10), catalog.total_bytes);

    var duplicate = try prepare("same bytes", "https://b.example/renamed.woff2", "font/woff2", .woff2, 20, .{});
    try std.testing.expectEqual(Disposition.duplicate, try catalog.classify(&duplicate));
    try std.testing.expectEqual(Disposition.duplicate, try catalog.recordCommitted(&duplicate));
    try std.testing.expectEqual(@as(usize, 1), catalog.count);
    const stored = catalog.find(first.metadata.id).?;
    try std.testing.expectEqualStrings("https://b.example/renamed.woff2", stored.source_url.bytes());
    try std.testing.expectEqual(@as(u64, 10), stored.created_at);
    try std.testing.expectEqual(@as(u64, 20), stored.last_access);
    try std.testing.expect(catalog.touch(first.metadata.id, 25));
    try std.testing.expectEqual(@as(u64, 25), catalog.find(first.metadata.id).?.last_access);
    _ = try catalog.recordCommitted(&duplicate);
    try std.testing.expectEqual(@as(u64, 25), catalog.find(first.metadata.id).?.last_access);

    catalog.entries[0].size += 1;
    try std.testing.expectError(error.DigestCollision, catalog.classify(&duplicate));
    catalog.entries[0].size -= 1;
    catalog.entries[0].checksum[0] ^= 0xff;
    try std.testing.expectError(error.DigestCollision, catalog.classify(&duplicate));
    first.metadata.occupied = false;
    const empty_catalog = Catalog{};
    try std.testing.expectError(error.InvalidMetadata, empty_catalog.classify(&first));
}

test "atomic font commit stages verifies and resolves publish races" {
    var catalog = Catalog{};
    const prepared = try prepare("font payload", "https://fonts.example/a.ttf", "font/ttf", .truetype, 5, .{});
    var plan = try planAtomicCommit(&catalog, &prepared, 7);
    try std.testing.expectEqual(Disposition.new_object, plan.disposition);
    try std.testing.expect(plan.write_object and plan.same_volume_required and plan.object_publish_requires_absent_target);
    try std.testing.expect(plan.catalog_publish_after_object and plan.consume_stage_on_publish);
    try std.testing.expect(std.mem.startsWith(u8, plan.object_stage.bytes(), staging_path));
    try std.testing.expectEqualStrings(catalog_path, plan.catalog_target.bytes());
    try validateStage(&plan, prepared.metadata.size, prepared.metadata.checksum);
    try std.testing.expectError(error.StageSizeMismatch, validateStage(&plan, prepared.metadata.size + 1, prepared.metadata.checksum));
    var corrupt = prepared.metadata.checksum;
    corrupt[0] ^= 1;
    try std.testing.expectError(error.StageDigestMismatch, validateStage(&plan, prepared.metadata.size, corrupt));
    try std.testing.expectEqual(PublishResolution.publish_new, try resolveTarget(&prepared, .{}));
    try std.testing.expectEqual(PublishResolution.reuse_existing, try resolveTarget(&prepared, .{
        .exists = true,
        .size = prepared.metadata.size,
        .checksum = prepared.metadata.checksum,
    }));
    try std.testing.expectError(error.DigestCollision, resolveTarget(&prepared, .{
        .exists = true,
        .size = prepared.metadata.size,
        .checksum = corrupt,
    }));
    try std.testing.expectEqual(PublishResolution.reuse_existing, try reconcileAtomicPlan(&plan, &prepared, .{
        .exists = true,
        .size = prepared.metadata.size,
        .checksum = prepared.metadata.checksum,
    }));
    try std.testing.expect(!plan.write_object and plan.object_stage.len == 0);
    try std.testing.expectEqual(PublishResolution.publish_new, try reconcileAtomicPlan(&plan, &prepared, .{}));
    try std.testing.expect(plan.write_object and plan.object_stage.len > 0);
    try std.testing.expectError(error.InvalidTransaction, planAtomicCommit(&catalog, &prepared, 0));

    _ = try catalog.recordCommitted(&prepared);
    var duplicate_plan = try planAtomicCommit(&catalog, &prepared, 8);
    try std.testing.expectEqual(Disposition.duplicate, duplicate_plan.disposition);
    try std.testing.expect(!duplicate_plan.write_object);
    try std.testing.expectEqual(@as(usize, 0), duplicate_plan.object_stage.len);
    try validateStage(&duplicate_plan, 0, [_]u8{0} ** digest_bytes);
    try std.testing.expectEqual(PublishResolution.publish_new, try reconcileAtomicPlan(&duplicate_plan, &prepared, .{}));
    try std.testing.expect(duplicate_plan.write_object and duplicate_plan.object_stage.len > 0);
}

test "cleanup expires by age then evicts deterministic LRU for reservations" {
    var catalog = Catalog{};
    var oldest = testPrepared(1, 4, 10);
    var tied_a = testPrepared(2, 4, 20);
    var tied_b = testPrepared(3, 4, 20);
    var recent = testPrepared(4, 4, 90);
    _ = try catalog.recordCommitted(&oldest);
    _ = try catalog.recordCommitted(&tied_a);
    _ = try catalog.recordCommitted(&tied_b);
    _ = try catalog.recordCommitted(&recent);

    const expiry = try planCleanup(&catalog, .{
        .max_object_bytes = 32,
        .max_total_bytes = 32,
        .max_age_seconds = 50,
    }, 100, .{}, null);
    try std.testing.expectEqual(@as(usize, 3), expiry.count);
    try std.testing.expectEqual(CleanupReason.expired, expiry.actions[0].reason);
    try std.testing.expect(std.mem.eql(u8, &expiry.actions[0].id, &oldest.metadata.id));
    const tie_order = std.mem.order(u8, &tied_a.metadata.id, &tied_b.metadata.id);
    const expected_second = if (tie_order == .lt) tied_a.metadata.id else tied_b.metadata.id;
    const expected_third = if (tie_order == .lt) tied_b.metadata.id else tied_a.metadata.id;
    try std.testing.expect(std.mem.eql(u8, &expiry.actions[1].id, &expected_second));
    try std.testing.expect(std.mem.eql(u8, &expiry.actions[2].id, &expected_third));
    try std.testing.expectEqual(@as(u64, 4), expiry.resulting_bytes);
    try std.testing.expectEqual(@as(usize, 1), expiry.resulting_entries);
    try std.testing.expect(expiry.publish_catalog_before_object_deletes);

    const preserve = try planCleanup(&catalog, .{
        .max_object_bytes = 32,
        .max_total_bytes = 32,
        .max_age_seconds = 50,
    }, 100, .{}, tied_a.metadata.id);
    try std.testing.expectEqual(@as(usize, 2), preserve.count);
    for (preserve.actions[0..preserve.count]) |action| try std.testing.expect(!std.mem.eql(u8, &action.id, &tied_a.metadata.id));

    const lru = try planCleanup(&catalog, .{
        .max_object_bytes = 18,
        .max_total_bytes = 18,
        .max_age_seconds = 0,
        .max_entry_count = 4,
    }, 100, .{ .bytes = 6, .entries = 1 }, null);
    try std.testing.expectEqual(@as(usize, 1), lru.count);
    try std.testing.expectEqual(CleanupReason.entry_limit, lru.actions[0].reason);
    try std.testing.expect(std.mem.eql(u8, &lru.actions[0].id, &oldest.metadata.id));
    try std.testing.expectEqual(@as(u64, 18), lru.resulting_bytes);
    try std.testing.expectEqual(@as(usize, 4), lru.resulting_entries);
}

test "cleanup treats zero timestamps as unavailable wall clock" {
    var unknown_created = Catalog{};
    var unknown = testPrepared(40, 4, 0);
    _ = try unknown_created.recordCommitted(&unknown);
    const later_valid = try planCleanup(&unknown_created, .{
        .max_object_bytes = 32,
        .max_total_bytes = 32,
        .max_age_seconds = default_max_age_seconds,
    }, default_max_age_seconds * 4, .{}, null);
    try std.testing.expectEqual(@as(usize, 0), later_valid.count);

    var valid_created = Catalog{};
    var valid = testPrepared(41, 4, 100);
    _ = try valid_created.recordCommitted(&valid);
    const rtc_unavailable = try planCleanup(&valid_created, .{
        .max_object_bytes = 32,
        .max_total_bytes = 32,
        .max_age_seconds = default_max_age_seconds,
    }, 0, .{}, null);
    try std.testing.expectEqual(@as(usize, 0), rtc_unavailable.count);
}

test "admission cleanup applies before commit and protects a duplicate being accessed" {
    var catalog = Catalog{};
    var old = testPrepared(10, 6, 1);
    var keep = testPrepared(11, 6, 2);
    _ = try catalog.recordCommitted(&old);
    _ = try catalog.recordCommitted(&keep);
    const incoming = testPrepared(12, 6, 50);
    const admission = try planAdmission(&catalog, &incoming, .{
        .max_object_bytes = 12,
        .max_total_bytes = 12,
        .max_age_seconds = 0,
        .max_entry_count = 3,
    }, 50, 22);
    try std.testing.expectEqual(Disposition.new_object, admission.disposition);
    try std.testing.expectEqual(@as(usize, 1), admission.cleanup.count);
    try std.testing.expect(std.mem.eql(u8, &admission.cleanup.actions[0].id, &old.metadata.id));
    var corrupt_plan = admission.cleanup;
    corrupt_plan.actions[0].id = [_]u8{0} ** digest_bytes;
    var unchanged = catalog;
    try std.testing.expectError(error.InvalidMetadata, applyCleanup(&unchanged, &corrupt_plan));
    try std.testing.expectEqual(catalog.count, unchanged.count);
    try std.testing.expectEqual(catalog.total_bytes, unchanged.total_bytes);
    try applyCleanup(&catalog, &admission.cleanup);
    _ = try catalog.recordCommitted(&incoming);
    try std.testing.expectEqual(admission.cleanup.resulting_entries, catalog.count);
    try std.testing.expectEqual(admission.cleanup.resulting_bytes, catalog.total_bytes);
    try std.testing.expect(catalog.validate());

    var duplicate = incoming;
    duplicate.metadata.last_access = 1000;
    try duplicate.metadata.source_url.set("https://other.example/same.woff2");
    const duplicate_admission = try planAdmission(&catalog, &duplicate, .{
        .max_object_bytes = 12,
        .max_total_bytes = 12,
        .max_age_seconds = 10,
        .max_entry_count = 3,
    }, 1000, 23);
    try std.testing.expectEqual(Disposition.duplicate, duplicate_admission.disposition);
    for (duplicate_admission.cleanup.actions[0..duplicate_admission.cleanup.count]) |action| {
        try std.testing.expect(!std.mem.eql(u8, &action.id, &incoming.metadata.id));
    }
}

test "cleanup rejects impossible reservations and catalog reaches fixed capacity without overflow" {
    var catalog = Catalog{};
    var seed: usize = 0;
    while (seed < max_entries) : (seed += 1) {
        var candidate = testPrepared(@intCast(seed), 1, @intCast(seed));
        _ = try catalog.recordCommitted(&candidate);
    }
    try std.testing.expectEqual(max_entries, catalog.count);
    try std.testing.expect(catalog.validate());
    var extra = testPrepared(0xff, 1, 200);
    // Seed 255 is distinct from all occupied one-byte payloads 0..127.
    try std.testing.expectError(error.CatalogFull, catalog.recordCommitted(&extra));
    try std.testing.expectError(error.ReservationTooLarge, planCleanup(&catalog, .{
        .max_object_bytes = 1,
        .max_total_bytes = 1,
        .max_age_seconds = 0,
        .max_entry_count = 1,
    }, 0, .{ .bytes = 2, .entries = 1 }, null));

    var single = Catalog{};
    _ = try single.recordCommitted(&extra);
    try std.testing.expectError(error.ReservationTooLarge, planCleanup(&single, .{
        .max_object_bytes = 1,
        .max_total_bytes = 1,
        .max_age_seconds = 0,
        .max_entry_count = 1,
    }, 0, .{ .bytes = 1, .entries = 1 }, extra.metadata.id));
}
