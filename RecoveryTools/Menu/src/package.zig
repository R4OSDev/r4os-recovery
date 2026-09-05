// Recovery package policy. ZIP decoding belongs exclusively to R4ZIP.R4P.
// Every allocation is supplied by the caller; the guest supplies pinned RAM.
const std = @import("std");
const r4os = @import("r4os");
const zip = r4os.zip;
const versions = r4os.version_info;
pub const Pump = @import("resident.zig").Pump;
pub const max_archive_bytes = 2 * 1024 * 1024 * 1024;
pub const max_payload_bytes = 4 * 1024 * 1024 * 1024;
pub const max_manifest_bytes = 1024 * 1024;
pub const Kind = enum { r4os, recovery };
pub const File = struct { path: []const u8, bytes: u64, sha256: []const u8 };
pub const RecoveryManifest = struct {
    schema: u32,
    product: []const u8,
    architecture: []const u8,
    recoveryVersion: []const u8,
    recoveryKernelVersion: []const u8,
    platformContract: struct { commit: []const u8, sha256: []const u8 },
    runtime: struct { format: []const u8, logicalSectorBytes: u32 },
    files: []const File,
    minimumRamBytes: u64,
};
pub const SystemManifest = struct {
    schema: u32,
    product: []const u8,
    architecture: []const u8,
    releaseVersion: []const u8,
    kernelVersion: []const u8,
    profile: []const u8,
    asset: []const u8,
    layout: []const u8,
    recovery: struct { version: []const u8, package: []const u8 },
    bootFiles: []const []const u8,
    files: []const File,
};
pub const Archive = struct {
    original: []const u8,
    entries: []zip.Entry,
    payload: []u8,
    offsets: []usize,
    manifest: []const u8,
    pub fn get(self: Archive, name: []const u8) ?[]const u8 {
        for (self.entries, 0..) |entry, i| if (std.mem.eql(u8, entry.name(self.original) catch return null, name)) {
            return self.payload[self.offsets[i]..][0..@intCast(entry.bytes)];
        };
        return null;
    }
};
pub const Prepared = struct {
    kind: Kind,
    archive: Archive,
    recovery_archive: Archive,
    recovery: RecoveryManifest,
    system: ?SystemManifest = null,
    pub fn version(self: *const Prepared) []const u8 {
        return if (self.system) |s| s.releaseVersion else self.recovery.recoveryVersion;
    }
};
pub fn parse(comptime T: type, allocator: std.mem.Allocator, bytes: []const u8) !T {
    if (bytes.len == 0 or bytes.len > max_manifest_bytes) return error.ManifestSize;
    // Parsed strings/arrays belong to the caller's preparation arena.
    const parsed = try std.json.parseFromSlice(T, allocator, versions.stripBom(bytes), .{ .allocate = .alloc_always, .max_value_len = max_manifest_bytes });
    return parsed.value;
}
fn validVersion(value: []const u8) bool {
    return value.len <= 32 and versions.parseSemanticVersion(value) != null;
}
fn lowerHex(value: []const u8, len: usize) bool {
    if (value.len != len) return false;
    for (value) |c| if (!std.ascii.isDigit(c) and (c < 'a' or c > 'f')) return false;
    return true;
}
pub fn portablePath(name: []const u8) bool {
    if (name.len == 0 or name.len > zip.max_path) return false;
    var parts = std.mem.splitScalar(u8, name, '/');
    while (parts.next()) |p| {
        if (p.len == 0 or std.mem.eql(u8, p, ".") or std.mem.eql(u8, p, "..") or p[p.len - 1] == '.' or p[p.len - 1] == ' ') return false;
        for (p) |c| if (c < 32 or c > 126 or std.mem.indexOfScalar(u8, "<>:\"\\|?*", c) != null) return false;
    }
    return true;
}
pub fn validateRecovery(m: RecoveryManifest) !void {
    if (m.schema != 1 or !std.mem.eql(u8, m.product, "r4os-recovery")) return error.PackageFormat;
    if (!std.mem.eql(u8, m.architecture, "x86_64") or !std.mem.eql(u8, m.runtime.format, "fat32") or m.runtime.logicalSectorBytes != 512) return error.IncompatiblePackage;
    if (!validVersion(m.recoveryVersion) or !validVersion(m.recoveryKernelVersion) or !lowerHex(m.platformContract.commit, 40) or !lowerHex(m.platformContract.sha256, 64)) return error.ManifestValue;
    if (m.minimumRamBytes == 0 or m.minimumRamBytes > 8 * 1024 * 1024 * 1024) return error.ManifestValue;
    var kernel = false;
    var runtime = false;
    var legal = false;
    for (m.files) |file| {
        if (std.mem.eql(u8, file.path, "recovery.elf")) kernel = true else if (std.mem.eql(u8, file.path, "runtime.img")) runtime = true else if (std.mem.startsWith(u8, file.path, "Legal/")) legal = true else return error.UnexpectedFile;
    }
    if (!kernel or !runtime or !legal) return error.MissingFile;
}
pub fn validateSystem(m: SystemManifest) !void {
    if (m.schema != 1 or !std.mem.eql(u8, m.product, "r4os")) return error.PackageFormat;
    if (!std.mem.eql(u8, m.architecture, "x86_64") or !std.mem.eql(u8, m.layout, "r4os-gpt-1")) return error.IncompatiblePackage;
    if (!validVersion(m.releaseVersion) or !validVersion(m.kernelVersion) or !validVersion(m.recovery.version)) return error.ManifestValue;
    if (!std.mem.eql(u8, m.profile, "slim") and !std.mem.eql(u8, m.profile, "full")) return error.IncompatiblePackage;
    if (!std.mem.eql(u8, m.recovery.package, "recovery.zip")) return error.ManifestValue;
    var buffer: [128]u8 = undefined;
    const expected = try std.fmt.bufPrint(&buffer, "R4OS-{s}-{s}-x86_64.zip", .{ m.releaseVersion, m.profile });
    if (!std.mem.eql(u8, expected, m.asset)) return error.AssetMismatch;
    if (m.bootFiles.len == 0 or m.bootFiles.len > 32) return error.ManifestValue;
    var kernel = false;
    for (m.bootFiles, 0..) |path, i| {
        if (!portablePath(path)) return error.UnsafePath;
        var parts = std.mem.splitScalar(u8, path, '/');
        while (parts.next()) |part| if (std.ascii.eqlIgnoreCase(part, "limine.conf")) return error.ManagedBootPath;
        for (m.bootFiles[0..i]) |previous| if (std.ascii.eqlIgnoreCase(path, previous)) return error.DuplicatePath;
        if (std.mem.eql(u8, path, "boot/r4os.elf")) kernel = true;
    }
    if (!kernel) return error.MissingFile;
    var disk = false;
    var recovery = false;
    var legal = false;
    for (m.files) |file| {
        if (std.mem.eql(u8, file.path, "disk.img")) disk = true else if (std.mem.eql(u8, file.path, "recovery.zip")) recovery = true else if (std.mem.startsWith(u8, file.path, "Legal/")) legal = true else if (std.mem.startsWith(u8, file.path, "BOOT/")) {
            var found = false;
            for (m.bootFiles) |path| if (std.mem.eql(u8, file.path[5..], path)) {
                found = true;
                break;
            };
            if (!found) return error.ManagedBootPath;
        } else return error.UnexpectedFile;
    }
    if (!disk or !recovery or !legal) return error.MissingFile;
    for (m.bootFiles) |path| {
        var found = false;
        for (m.files) |file| if (std.mem.startsWith(u8, file.path, "BOOT/") and std.mem.eql(u8, file.path[5..], path)) {
            found = true;
            break;
        };
        if (!found) return error.MissingFile;
    }
}
fn extract(allocator: std.mem.Allocator, codec: anytype, input: []const u8, pump: Pump) !Archive {
    if (input.len < 22 or input.len > max_archive_bytes) return error.ArchiveSize;
    const entries = try allocator.alloc(zip.Entry, zip.max_entries);
    const info = try codec.inspect(input, entries);
    if (info.entries == 0 or info.total_bytes > max_payload_bytes) return error.PayloadSize;
    const payload = try allocator.alloc(u8, @intCast(info.total_bytes));
    const offsets = try allocator.alloc(usize, info.entries);
    const work = try allocator.create(zip.Work);
    var offset: usize = 0;
    for (entries[0..info.entries], 0..) |entry, i| {
        offsets[i] = offset;
        const output = payload[offset..][0..@intCast(entry.bytes)];
        var progress = try codec.begin(input, &entry, output, work);
        while (progress.done == 0) {
            try pump.run("Unpacking ZIP", offset + progress.written, payload.len);
            progress = try codec.step(work, 128 * 1024);
        }
        offset += output.len;
    }
    const result = Archive{ .original = input, .entries = entries[0..info.entries], .payload = payload, .offsets = offsets, .manifest = undefined };
    var out = result;
    out.manifest = result.get("manifest.json") orelse return error.PackageFormat;
    return out;
}
fn verifyFiles(archive: Archive, files: []const File, pump: Pump) !void {
    if (files.len == 0 or files.len >= zip.max_entries) return error.ManifestValue;
    var count: usize = 0;
    for (archive.entries) |entry| if (entry.directory == 0) {
        count += 1;
    };
    if (count != files.len + 1) return error.FileSetMismatch;
    for (files, 0..) |file, i| {
        if (!portablePath(file.path) or std.ascii.eqlIgnoreCase(file.path, "manifest.json") or !lowerHex(file.sha256, 64)) return error.ManifestValue;
        for (files[0..i]) |prior| if (std.ascii.eqlIgnoreCase(file.path, prior.path)) return error.DuplicatePath;
        const bytes = archive.get(file.path) orelse return error.MissingFile;
        if (bytes.len != file.bytes) return error.FileSizeMismatch;
        var hash = std.crypto.hash.sha2.Sha256.init(.{});
        var done: usize = 0;
        while (done < bytes.len) {
            const amount = @min(bytes.len - done, 128 * 1024);
            hash.update(bytes[done..][0..amount]);
            done += amount;
            try pump.run("Checking file hashes", done, bytes.len);
        }
        const actual = std.fmt.bytesToHex(hash.finalResult(), .lower);
        if (!std.mem.eql(u8, &actual, file.sha256)) return error.HashMismatch;
    }
}
fn elf64(bytes: []const u8) bool {
    return bytes.len >= 64 and std.mem.eql(u8, bytes[0..7], &.{ 0x7f, 'E', 'L', 'F', 2, 1, 1 }) and std.mem.readInt(u16, bytes[18..20], .little) == 62 and std.mem.readInt(u32, bytes[20..24], .little) == 1;
}
fn runtimeFat(bytes: []const u8) bool {
    if (bytes.len < 512 or bytes.len % 512 != 0) return false;
    const geometry = r4os.storage_tools.fat32.Geometry.init(bytes.len / 512, 0, bytes[13]) catch return false;
    return bytes[510] == 0x55 and bytes[511] == 0xaa and std.mem.readInt(u16, bytes[11..13], .little) == 512 and
        std.mem.readInt(u16, bytes[14..16], .little) == 32 and bytes[16] == 2 and
        std.mem.readInt(u32, bytes[32..36], .little) == geometry.sectors and
        std.mem.readInt(u32, bytes[36..40], .little) == geometry.sectors_per_fat and
        std.mem.readInt(u32, bytes[44..48], .little) == 2;
}
pub fn prepare(allocator: std.mem.Allocator, codec: anytype, input: []const u8, kind: Kind, pump: Pump) anyerror!Prepared {
    _ = try peek(allocator, codec, input, kind, pump);
    const archive = try extract(allocator, codec, input, pump);
    if (kind == .recovery) {
        const manifest = try parse(RecoveryManifest, allocator, archive.manifest);
        try validateRecovery(manifest);
        try verifyFiles(archive, manifest.files, pump);
        if (!elf64(archive.get("recovery.elf").?) or !runtimeFat(archive.get("runtime.img").?)) return error.ImageFormat;
        return .{ .kind = kind, .archive = archive, .recovery_archive = archive, .recovery = manifest };
    }
    const manifest = try parse(SystemManifest, allocator, archive.manifest);
    try validateSystem(manifest);
    try verifyFiles(archive, manifest.files, pump);
    if (!elf64(archive.get("BOOT/boot/r4os.elf").?)) return error.ImageFormat;
    const recovery = try prepare(allocator, codec, archive.get("recovery.zip").?, .recovery, pump);
    if (!std.mem.eql(u8, manifest.recovery.version, recovery.recovery.recoveryVersion)) return error.RecoveryPairMismatch;
    return .{ .kind = kind, .archive = archive, .system = manifest, .recovery_archive = recovery.archive, .recovery = recovery.recovery };
}

// Cheap cache description: ZIP structure + manifest CRC/schema, explicitly
// not a claim that all payload hashes or images have already been checked.
pub fn peek(allocator: std.mem.Allocator, codec: anytype, input: []const u8, kind: Kind, pump: Pump) ![]const u8 {
    if (input.len > max_archive_bytes) return error.ArchiveSize;
    const entries = try allocator.alloc(zip.Entry, zip.max_entries);
    const info = try codec.inspect(input, entries);
    const entry = for (entries[0..info.entries]) |e| {
        if (std.mem.eql(u8, try e.name(input), "manifest.json")) break e;
    } else return error.PackageFormat;
    if (entry.bytes == 0 or entry.bytes > max_manifest_bytes or entry.directory != 0) return error.ManifestSize;
    const decoded = try allocator.alloc(u8, @intCast(entry.bytes));
    const work = try allocator.create(zip.Work);
    var progress = try codec.begin(input, &entry, decoded, work);
    while (progress.done == 0) {
        try pump.run("Reading package manifest", progress.written, decoded.len);
        progress = try codec.step(work, 128 * 1024);
    }
    if (kind == .recovery) {
        const manifest = try parse(RecoveryManifest, allocator, decoded);
        try validateRecovery(manifest);
        return manifest.recoveryVersion;
    }
    const manifest = try parse(SystemManifest, allocator, decoded);
    try validateSystem(manifest);
    return manifest.releaseVersion;
}
