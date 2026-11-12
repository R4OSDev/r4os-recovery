//! Single original artefacts enter the existing R4U transaction owner. This
//! module only verifies and wraps bytes; it never replaces an installed file
//! or writes MODULES.JSON. No dependency/version admission policy lives here.
const std = @import("std");
const r = @import("r4os");
const manifest = r.r4u_manifest;
const artifact = r.r4u_artifact;
const seed: u32 = 2166136261;
pub const system = @import("system_update_asset_system.zig");
pub const Digest = system.Digest;
pub const Plan = struct {
    kind: manifest.ComponentKind = .r4x,
    boot: ?system.BootProof = null,
    source: []const u8,
    target: []const u8,
    name: []const u8,
    version: []const u8,
    size: u64,
    sha256: []const u8,
    /// Null means create only. A replacement/adoption needs an observed old
    /// file, rechecked by the transaction owner while holding SYSLOCK.
    previous: ?Digest = null,
};
pub const Prepared = struct { path: r.AbsoluteFilePath };
pub const Reader = struct {
    files: *const r.Files,
    path: r.AbsoluteFilePath,
    pub fn readAt(self: Reader, offset: u64, out: []u8) bool {
        if (offset > std.math.maxInt(u32)) return false;
        return switch (self.files.readAt(self.path.asZ(), @intCast(offset), out)) {
            .bytes => |n| n == out.len,
            else => false,
        };
    }
};
pub fn digest(files: *const r.Files, path: r.AbsoluteFilePath, scratch: []u8) !Digest {
    const before = switch (files.info(path.asZ())) {
        .value => |v| v,
        .missing => return error.AssetMissing,
        .failure => return error.AssetInfo,
    };
    if (before.is_dir != 0 or before.size == 0 or before.size > std.math.maxInt(u32) or scratch.len == 0) return error.AssetSize;
    var hash = std.crypto.hash.sha2.Sha256.init(.{});
    var checksum: u32 = seed;
    var offset: u64 = 0;
    while (offset < before.size) {
        const chunk = scratch[0..@intCast(@min(scratch.len, before.size - offset))];
        if (!(Reader{ .files = files, .path = path }).readAt(offset, chunk)) return error.AssetRead;
        hash.update(chunk);
        checksum = checksumUpdate(checksum, chunk);
        offset += chunk.len;
    }
    const after = switch (files.info(path.asZ())) {
        .value => |v| v,
        else => return error.AssetChanged,
    };
    if (after.is_dir != 0 or after.size != before.size) return error.AssetChanged;
    return .{ .size = before.size, .sha256 = std.fmt.bytesToHex(hash.finalResult(), .lower), .checksum = checksum };
}
pub fn inspect(files: *const r.Files, path: r.AbsoluteFilePath) !artifact.Identity {
    const info = switch (files.info(path.asZ())) {
        .value => |v| v,
        else => return error.AssetMissing,
    };
    if (info.is_dir != 0) return error.AssetType;
    return artifact.inspect(Reader{ .files = files, .path = path }, info.size) orelse error.AssetIdentity;
}
pub fn validate(plan: Plan) !void {
    _ = try r.AbsoluteFilePath.parse(plan.source);
    if (!system.targetSupported(plan.kind, plan.target, plan.name) or
        ((plan.kind == .kernel) != (plan.boot != null)) or
        !manifest.validToken(plan.name, manifest.component_name_max_bytes) or
        !manifest.validSemanticVersion(plan.version) or plan.size == 0 or
        plan.size > std.math.maxInt(u32) or plan.sha256.len != 64) return error.AssetPlan;
    for (plan.sha256) |byte| if (!std.ascii.isHex(byte)) return error.AssetPlan;
    if (manifest.targetEquals(plan.source, plan.target) and plan.previous == null) return error.AssetSourceAliasesTarget;
}
pub fn matches(value: Digest, size: u64, sha256: []const u8) bool {
    return value.size == size and std.ascii.eqlIgnoreCase(&value.sha256, sha256);
}
pub fn prepare(app: *r.App, plan: Plan, current: []const u8) !Prepared {
    return prepareWithFiles(app.system(), app.files(), plan, current);
}

pub fn prepareWithFiles(ctx: r.r4sys.Context, file_api: ?r.Files, plan: Plan, current: []const u8) !Prepared {
    try validate(plan);
    const target = try system.RawPath.init(plan.target);
    const target_text = target.storage[0..target.len];
    var component_buffer: [1024]u8 = undefined;
    const component = manifest.canonicalInventoryTarget(&component_buffer, target_text) orelse return error.AssetTarget;
    var derived: manifest.DerivedClass = .{};
    manifest.includeComponent(&derived, plan.kind, component);
    // Optional operation lookup, never a software-version comparison. Older
    // kernels cannot promise replay for arbitrary chosen application paths.
    if (ctx.hasFn("system_update_target_supported")) {
        if (ctx.systemUpdateTargetSupported(target.asZ()) != 1) return error.AssetTargetUnsupported;
    } else if (plan.kind == .r4x) return error.AssetTargetUnsupported;
    // System targets already belong to the existing R4U recovery contract.
    // Arbitrary application locations require the additive native operation.
    if (plan.boot) |proof| if (!proof.eql(try system.bootPlan(&ctx))) return error.BootPlanChanged;
    const files = file_api orelse return error.FilesUnavailable;
    const source = try r.AbsoluteFilePath.parse(plan.source);
    const allocator = ctx.allocator();
    const scratch = try allocator.alloc(u8, 64 * 1024);
    defer allocator.free(scratch);
    const observed = try digest(&files, source, scratch);
    if (!matches(observed, plan.size, plan.sha256)) return error.AssetHashMismatch;
    const identity = try inspect(&files, source);
    if (identity.kind != plan.kind or !std.ascii.eqlIgnoreCase(identity.nameText(), plan.name) or
        !std.mem.eql(u8, identity.versionText(), plan.version)) return error.AssetIdentityMismatch;
    if (!manifest.validSemanticVersion(current)) return error.AssetRelease;
    // Include every immutable plan field, old-file observation and actual OS
    // release in the wrapper identity. An app version never becomes an OS release.
    // Preserve the original application's 0.89.51 wrapper identity. System
    // envelopes have their own stable schema, independent of SDK versions.
    const legacy = .{ .source = plan.source, .target = plan.target, .name = plan.name, .version = plan.version, .size = plan.size, .sha256 = plan.sha256, .previous = plan.previous };
    const encoded = if (plan.kind == .r4x and derived.activation == .live)
        try std.json.Stringify.valueAlloc(allocator, .{ legacy, current }, .{})
    else
        try std.json.Stringify.valueAlloc(allocator, .{ "r4u-original-system-v1", plan, current }, .{});
    defer allocator.free(encoded);
    var hash: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(encoded, &hash, .{});
    const id = std.fmt.bytesToHex(hash, .lower);
    var directory_buffer: [128]u8 = undefined;
    const directory = try r.AbsoluteFilePath.parse(try std.fmt.bufPrint(&directory_buffer, "C:\\R4OS\\UPDATE\\INBOX\\{s}", .{id}));
    try ensureParents(&files, directory);
    var target_buffer: [160]u8 = undefined;
    var stage_buffer: [160]u8 = undefined;
    var backup_buffer: [160]u8 = undefined;
    const envelope = try r.AbsoluteFilePath.parse(try std.fmt.bufPrint(&target_buffer, "{s}\\ASSET.R4U", .{directory.bytes()}));
    const stage = try r.AbsoluteFilePath.parse(try std.fmt.bufPrint(&stage_buffer, "{s}\\ASSET.NEW", .{directory.bytes()}));
    const backup = try r.AbsoluteFilePath.parse(try std.fmt.bufPrint(&backup_buffer, "{s}\\ASSET.BAK", .{directory.bytes()}));
    const activation = derived.activation.text();
    const priority = derived.priority.text();
    const kind = switch (plan.kind) {
        .r4x => "software",
        .r4l => "system-library",
        .kernel => "boot-kernel",
        else => unreachable,
    };
    const component_kind = switch (plan.kind) {
        .r4x => "R4X",
        .r4l => "R4L",
        .kernel => "KERNEL",
        else => unreachable,
    };
    const extension = switch (plan.kind) {
        .r4x => "R4X",
        .r4l => "R4L",
        .kernel => "ELF",
        else => unreachable,
    };
    const description = if (plan.kind == .r4x and derived.activation == .live) "Original application artefact" else "Original artefact";
    const text = try std.fmt.allocPrint(allocator, "R4U_MANIFEST=2\nPACKAGE=PX-{s}\nPACKAGE_VERSION={s}\nRELEASE={s}\nTITLE={s}\nDESCRIPTION={s}\nACTIVATION={s}\nPRIORITY={s}\nPAYLOADS=1\nCOMPONENTS=1\nREQUIRES=0\nABI;R4M0=1;R4L=1;R4D=1;R4P=1;R4XSTART=1;R4U_COMPONENTS=1\nPAYLOAD;index=0;name=ASSET.{s};target={s};kind={s};size={d};checksum={d};offset=0;abi=R4M0:1\nROLLBACK;target={s};backup={s}.prev;strategy=replace\nCOMPONENT;payload=0;kind={s};name={s};target={s};version={s};install={s}\n", .{ id[0..40], plan.version, current, plan.name, description, activation, priority, extension, target_text, kind, plan.size, observed.checksum, target_text, target_text, component_kind, plan.name, component, plan.version, activation });
    defer allocator.free(text);
    var header: [64]u8 = @splat(0);
    @memcpy(header[0..4], "R4U2");
    put(u16, &header, 4, 2);
    put(u16, &header, 6, 64);
    put(u64, &header, 8, text.len);
    put(u64, &header, 16, plan.size);
    put(u32, &header, 24, checksumUpdate(seed, text));
    put(u32, &header, 28, observed.checksum);
    // Package checksum is FNV(manifest || original payload).
    var package_checksum = checksumUpdate(seed, text);
    var offset: u64 = 0;
    while (offset < plan.size) {
        const chunk = scratch[0..@intCast(@min(scratch.len, plan.size - offset))];
        if (!(Reader{ .files = &files, .path = source }).readAt(offset, chunk)) return error.AssetRead;
        package_checksum = checksumUpdate(package_checksum, chunk);
        offset += chunk.len;
    }
    put(u32, &header, 32, package_checksum);
    put(u32, &header, 36, 1);
    put(u32, &header, 40, if (derived.activation == .restart) @as(u32, 1) else @as(u32, 0));
    if (try sameEnvelope(&files, envelope, source, plan, &header, text, scratch)) return .{ .path = envelope };
    if (!try sameEnvelope(&files, stage, source, plan, &header, text, scratch)) {
        var writer = switch (files.streamWriter(stage.asZ(), r.abi.file_stream_open_create)) {
            .writer => |v| v,
            else => return error.AssetWrapStage,
        };
        var finished = false;
        defer if (!finished) {
            _ = writer.abort();
        };
        if (writer.write(&header) != .ok or writer.write(text) != .ok) return error.AssetWrapWrite;
        offset = 0;
        var payload_hash = std.crypto.hash.sha2.Sha256.init(.{});
        while (offset < plan.size) {
            const chunk = scratch[0..@intCast(@min(scratch.len, plan.size - offset))];
            if (!(Reader{ .files = &files, .path = source }).readAt(offset, chunk)) return error.AssetRead;
            payload_hash.update(chunk);
            if (writer.write(chunk) != .ok) return error.AssetWrapWrite;
            offset += chunk.len;
        }
        const payload_sha = std.fmt.bytesToHex(payload_hash.finalResult(), .lower);
        if (!std.ascii.eqlIgnoreCase(&payload_sha, plan.sha256)) return error.AssetChanged;
        if (writer.finish() != .ok) return error.AssetWrapFinish;
        finished = true;
    }
    if (files.replaceAtomic(envelope.asZ(), stage.asZ(), backup.asZ(), .{ .require_target_absent = true }) != .ok) return error.AssetWrapPublish;
    if (!try sameEnvelope(&files, envelope, source, plan, &header, text, scratch)) return error.AssetWrapReadback;
    return .{ .path = envelope };
}
fn sameEnvelope(files: *const r.Files, path: r.AbsoluteFilePath, source: r.AbsoluteFilePath, plan: Plan, header: []const u8, text: []const u8, scratch: []u8) !bool {
    const info = switch (files.info(path.asZ())) {
        .missing => return false,
        .value => |v| v,
        else => return error.AssetWrapInfo,
    };
    if (info.is_dir != 0 or info.size != header.len + text.len + plan.size) return error.AssetWrapConflict;
    const reader = Reader{ .files = files, .path = path };
    if (!reader.readAt(0, scratch[0..header.len]) or !std.mem.eql(u8, header, scratch[0..header.len]) or
        !reader.readAt(header.len, scratch[0..text.len]) or !std.mem.eql(u8, text, scratch[0..text.len])) return error.AssetWrapConflict;
    const half = scratch.len / 2;
    var offset: u64 = 0;
    var hash = std.crypto.hash.sha2.Sha256.init(.{});
    while (offset < plan.size) {
        const n: usize = @intCast(@min(half, plan.size - offset));
        if (!reader.readAt(header.len + text.len + offset, scratch[0..n]) or
            !(Reader{ .files = files, .path = source }).readAt(offset, scratch[half..][0..n]) or
            !std.mem.eql(u8, scratch[0..n], scratch[half..][0..n])) return error.AssetWrapConflict;
        hash.update(scratch[0..n]);
        offset += n;
    }
    const sha = std.fmt.bytesToHex(hash.finalResult(), .lower);
    if (!std.ascii.eqlIgnoreCase(&sha, plan.sha256)) return error.AssetChanged;
    return true;
}
pub fn ensureParents(files: *const r.Files, directory: r.AbsoluteFilePath) !void {
    const text = directory.bytes();
    var i: usize = 3;
    while (i <= text.len) : (i += 1) if (i == text.len or text[i] == '\\') {
        const parent = try r.AbsoluteFilePath.parse(text[0..i]);
        if (files.sys.base.generation2 != null) {
            switch (files.metadata(parent.asZ())) {
                .found => |value| if (value.flags & r.abi.file_metadata2_flag_directory == 0) return error.AssetParentType,
                .missing => if (files.createDirectory(parent.asZ()) != .ok) return error.AssetParentCreate,
                .failure => return error.AssetParentInfo,
            }
            continue;
        }
        switch (files.info(parent.asZ())) {
            .value => |v| {
                if (v.is_dir == 0) return error.AssetParentType;
            },
            .missing => if (files.createDirectory(parent.asZ()) != .ok) return error.AssetParentCreate,
            .failure => return error.AssetParentInfo,
        }
    };
}
fn put(comptime T: type, bytes: []u8, offset: usize, value: anytype) void {
    std.mem.writeInt(T, bytes[offset..][0..@sizeOf(T)], @intCast(value), .little);
}
pub fn checksumUpdate(initial: u32, bytes: []const u8) u32 {
    var hash = initial;
    for (bytes) |byte| hash = (hash ^ byte) *% 16777619;
    return hash;
}
