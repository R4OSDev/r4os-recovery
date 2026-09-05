// One independently recoverable ZIP transaction per release channel.
// All paths are on the boot RECOVERY volume. Installation targets are never
// involved. The shared checked FAT transition owns namespace atomicity.
const std = @import("std");
const r4os = @import("r4os");
const packages = @import("package_session.zig");
const Kind = packages.package.Kind;
const Sha = std.crypto.hash.sha2.Sha256;
const checksums = r4os.system_update_recovery;
pub const Fingerprint = struct {
    bytes: u64,
    checksum: u32,
    sha256: [32]u8,
    pub fn eql(a: Fingerprint, b: Fingerprint) bool {
        return a.bytes == b.bytes and a.checksum == b.checksum and std.mem.eql(u8, &a.sha256, &b.sha256);
    }
};
pub const Record = struct {
    kind: Kind,
    new: Fingerprint,
    old: ?Fingerprint,
    pub const size = 160;
    pub fn encode(self: Record) [size]u8 {
        var bytes = [_]u8{0} ** size;
        @memcpy(bytes[0..8], "R4CACHE1");
        bytes[8] = @intFromEnum(self.kind);
        bytes[9] = @intFromBool(self.old != null);
        putFingerprint(bytes[16..64], self.new);
        if (self.old) |old| putFingerprint(bytes[64..112], old);
        Sha.hash(bytes[0..128], bytes[128..160], .{});
        return bytes;
    }
    pub fn decode(bytes: []const u8, kind: Kind) !Record {
        if (bytes.len != size or !std.mem.eql(u8, bytes[0..8], "R4CACHE1") or bytes[8] != @intFromEnum(kind) or bytes[9] > 1) return error.CacheJournal;
        var digest: [32]u8 = undefined;
        Sha.hash(bytes[0..128], &digest, .{});
        if (!std.mem.eql(u8, &digest, bytes[128..160])) return error.CacheJournal;
        const value = Record{ .kind = kind, .new = getFingerprint(bytes[16..64]), .old = if (bytes[9] == 1) getFingerprint(bytes[64..112]) else null };
        if (value.new.bytes < 22 or value.new.bytes > packages.package.max_archive_bytes or (value.old != null and value.old.?.bytes > packages.package.max_archive_bytes)) return error.CacheJournal;
        if (!std.mem.eql(u8, &value.encode(), bytes)) return error.CacheJournal;
        return value;
    }
    fn putFingerprint(bytes: *[48]u8, value: Fingerprint) void {
        std.mem.writeInt(u64, bytes[0..8], value.bytes, .little);
        std.mem.writeInt(u32, bytes[8..12], value.checksum, .little);
        @memcpy(bytes[16..48], &value.sha256);
    }
    fn getFingerprint(bytes: *const [48]u8) Fingerprint {
        return .{ .bytes = std.mem.readInt(u64, bytes[0..8], .little), .checksum = std.mem.readInt(u32, bytes[8..12], .little), .sha256 = bytes[16..48].* };
    }
};
pub const Paths = struct {
    zip: [:0]const u8,
    part: [:0]const u8,
    backup: [:0]const u8,
    journal: [:0]const u8,
    journal_stage: [:0]const u8,
    journal_backup: [:0]const u8,
    lock: [:0]const u8,
};
pub fn paths(kind: Kind) Paths {
    return if (kind == .r4os) .{
        .zip = "R:\\INSTALL\\RELEASE.ZIP",
        .part = "R:\\INSTALL\\RELEASE.PART",
        .backup = "R:\\INSTALL\\RELEASE.BAK",
        .journal = "R:\\INSTALL\\RELEASE.TXN",
        .journal_stage = "R:\\INSTALL\\RELEASE.TMP",
        .journal_backup = "R:\\INSTALL\\RELEASE.JBK",
        .lock = "R:\\INSTALL\\RELEASE.LCK",
    } else .{
        .zip = "R:\\INSTALL\\RECOVERY.ZIP",
        .part = "R:\\INSTALL\\RECOVERY.PART",
        .backup = "R:\\INSTALL\\RECOVERY.BAK",
        .journal = "R:\\INSTALL\\RECOVERY.TXN",
        .journal_stage = "R:\\INSTALL\\RECOVERY.TMP",
        .journal_backup = "R:\\INSTALL\\RECOVERY.JBK",
        .lock = "R:\\INSTALL\\RECOVERY.LCK",
    };
}
pub const Cache = struct {
    sys: *const r4os.r4sys.Context,
    kind: Kind,
    pump: packages.resident.Pump = .{},
    locked: bool = false,
    buffer: [64 * 1024]u8 = undefined,

    pub fn lock(self: *Cache) !void {
        const drive = self.sys.driveInfo('R' - 'A') orelse return error.CacheUnavailable;
        if (drive.mounted == 0 or drive.cluster_bytes == 0) return error.CacheUnavailable;
        if (try self.info("R:\\INSTALL") == null and self.sys.dirCreate("R:\\INSTALL") <= 0) return error.CacheIo;
        const path = paths(self.kind).lock;
        const rc = self.sys.fileStreamBegin(path, r4os.abi.file_stream_open_create | r4os.r4sys.file_stream_open_lease);
        if (rc != r4os.abi.file_stream_result_ok) return if (rc == r4os.abi.file_stream_error_exists) error.CacheBusy else error.CacheIo;
        self.locked = true;
        errdefer self.unlock();
        if (self.sys.fileStreamWrite(path, 0, "R4CACHE1\n", 0) != 9 or self.sys.fileStreamFinish(path, 9, r4os.r4sys.file_stream_finish_keep_ownership) != 0) return error.CacheIo;
    }
    pub fn unlock(self: *Cache) void {
        if (self.locked) _ = self.sys.fileStreamAbort(paths(self.kind).lock);
        self.locked = false;
    }
    pub fn info(self: *Cache, path: [*:0]const u8) !?r4os.abi.FileInfo {
        var value = r4os.abi.FileInfo{};
        const rc = self.sys.fileInfoRaw(path, &value);
        if (rc < 0) return error.CacheIo;
        return if (rc == 0 or value.exists == 0) null else value;
    }
    pub fn fingerprint(self: *Cache, path: [*:0]const u8) !?Fingerprint {
        const info_before = (try self.info(path)) orelse return null;
        if (info_before.is_dir != 0 or info_before.size > packages.package.max_archive_bytes) return error.CacheConflict;
        var hash = Sha.init(.{});
        var checksum = checksums.checksum_seed;
        var done: u64 = 0;
        while (done < info_before.size) {
            const count: usize = @intCast(@min(info_before.size - done, self.buffer.len));
            if (self.sys.fileReadAt(path, @intCast(done), self.buffer[0..count]) != count) return error.CacheIo;
            hash.update(self.buffer[0..count]);
            checksum = checksums.checksumUpdate(checksum, self.buffer[0..count]);
            done += count;
            try self.pump.run("Checking cached file", done, info_before.size);
        }
        const after = (try self.info(path)) orelse return error.CacheConflict;
        if (after.size != info_before.size or after.first_cluster != info_before.first_cluster) return error.CacheConflict;
        return .{ .bytes = done, .checksum = checksum, .sha256 = hash.finalResult() };
    }
    fn remove(self: *Cache, path: [*:0]const u8, fingerprinted: Fingerprint) !void {
        const rc = self.sys.fileDeleteIfMatch(path, fingerprinted.bytes, fingerprinted.checksum);
        if (rc < 0) return if (rc == r4os.r4sys.file_delete_if_match_error_conflict) error.CacheConflict else error.CacheIo;
    }
    fn removePrivatePart(self: *Cache) !void {
        const p = paths(self.kind);
        if (try self.info(p.part)) |part| {
            if (part.is_dir != 0) return error.CacheConflict;
            if (try self.info(p.zip)) |zip| {
                if (part.first_cluster != 0 and part.first_cluster == zip.first_cluster) return error.CacheConflict;
            }
            if (self.sys.fileDelete(p.part) < 0) return error.CacheIo;
        }
    }
    fn readRecord(self: *Cache, path: [*:0]const u8) !?Record {
        const info_before = (try self.info(path)) orelse return null;
        var bytes: [Record.size]u8 = undefined;
        if (info_before.size != bytes.len or info_before.is_dir != 0) return error.CacheJournal;
        if (self.sys.fileReadAt(path, 0, &bytes) != bytes.len) return error.CacheIo;
        return try Record.decode(&bytes, self.kind);
    }
    fn publishJournal(self: *Cache, record: Record) !void {
        const p = paths(self.kind);
        const bytes = record.encode();
        const rc = self.sys.fileUpdateAtomicChecked(p.journal, p.journal_stage, p.journal_backup, bytes.len, checksums.checksum(&bytes), 0, 0, r4os.r4sys.file_update_atomic_checked_flag_forward);
        if (rc != 0) return error.CacheJournal;
    }
    /// Must run under the channel lock before any new download. A durable
    /// journal is published from an already-flushed short staging file before
    /// the ZIP ownership transfer starts; a partial journal is never active.
    pub fn recover(self: *Cache) !void {
        std.debug.assert(self.locked);
        const p = paths(self.kind);
        if (try self.info(p.journal_backup) != null) return error.CacheConflict;
        var record = try self.readRecord(p.journal);
        if (record == null) {
            if (try self.info(p.backup) != null) return error.CacheConflict;
            record = self.readRecord(p.journal_stage) catch |err| blk: {
                if (err != error.CacheJournal) return err;
                // No published journal/backup: the ZIP transition never
                // started. Refuse a foreign alias before discarding the PART.
                try self.removePrivatePart();
                if (self.sys.fileDelete(p.journal_stage) < 0) return error.CacheIo;
                break :blk null;
            };
        }
        if (record) |value| {
            try self.publishJournal(value); // also consumes a surviving alias
            try self.finish(value);
        }
    }
    pub fn beginDownload(self: *Cache, bytes: u64) !void {
        try self.recover();
        try self.removePrivatePart();
        if (bytes < 22 or bytes > packages.package.max_archive_bytes) return error.ArchiveSize;
        const drive = self.sys.driveInfo('R' - 'A') orelse return error.CacheUnavailable;
        // The old ZIP already occupies its clusters. Only count genuinely
        // free bytes; retain 1MB for directory/journal/allocation metadata.
        if (drive.free_bytes < bytes + 1024 * 1024) return error.CacheNoSpace;
        const rc = self.sys.fileStreamBegin(paths(self.kind).part, r4os.abi.file_stream_open_create);
        if (rc != 0) return error.CacheIo;
    }
    pub fn activate(self: *Cache, validated: Fingerprint) !void {
        std.debug.assert(self.locked);
        const p = paths(self.kind);
        const actual = (try self.fingerprint(p.part)) orelse return error.CacheConflict;
        if (!actual.eql(validated)) return error.CacheConflict;
        const old = try self.fingerprint(p.zip);
        if (old) |previous| if (previous.eql(validated)) {
            try self.removePrivatePart();
            return;
        };
        const record = Record{ .kind = self.kind, .new = validated, .old = old };
        const bytes = record.encode();
        if (self.sys.fileStreamBegin(p.journal_stage, r4os.abi.file_stream_open_create) != 0) return error.CacheIo;
        defer _ = self.sys.fileStreamAbort(p.journal_stage);
        if (self.sys.fileStreamWrite(p.journal_stage, 0, &bytes, 0) != bytes.len or self.sys.fileStreamFinish(p.journal_stage, bytes.len, 0) != 0) return error.CacheIo;
        try self.publishJournal(record);
        try self.pump.run("Cache journal durable", 0, 1);
        try self.finish(record);
    }
    fn finish(self: *Cache, record: Record) !void {
        const p = paths(self.kind);
        const current = try self.fingerprint(p.zip);
        const staged = try self.fingerprint(p.part);
        const backup = try self.fingerprint(p.backup);
        const is_new = current != null and current.?.eql(record.new);
        if (backup) |old| if (record.old == null or !old.eql(record.old.?)) return error.CacheConflict;
        if (!(is_new and staged == null)) {
            if (staged == null or !staged.?.eql(record.new)) return error.CacheConflict;
            if (!is_new and (current != null or record.old != null)) {
                if (current == null or record.old == null or !current.?.eql(record.old.?)) return error.CacheConflict;
            }
            var flags = r4os.r4sys.file_update_atomic_checked_flag_forward | r4os.r4sys.file_update_atomic_checked_flag_long_stage;
            if (record.old != null) flags |= r4os.r4sys.file_update_atomic_checked_flag_target_existed | r4os.r4sys.file_update_atomic_checked_flag_old_known;
            try self.pump.run("Publishing verified package", 0, 1);
            const rc = self.sys.fileUpdateAtomicChecked(p.zip, p.part, p.backup, record.new.bytes, record.new.checksum, if (record.old) |old| old.bytes else 0, if (record.old) |old| old.checksum else 0, flags);
            if (rc != 0) return if (rc == r4os.r4sys.file_update_atomic_checked_error_conflict) error.CacheConflict else error.CacheIo;
        }
        const after = (try self.fingerprint(p.zip)) orelse return error.CacheConflict;
        if (!after.eql(record.new) or try self.info(p.part) != null) return error.CacheConflict;
        try self.pump.run("Cache ZIP published", 1, 1);
        if (record.old) |old| try self.remove(p.backup, old);
        try self.pump.run("Cache backup removed", 1, 1);
        const bytes = record.encode();
        try self.remove(p.journal, .{ .bytes = bytes.len, .checksum = checksums.checksum(&bytes), .sha256 = undefined });
        try self.pump.run("Cache transaction complete", 1, 1);
    }
};

test "cache journal rejects torn bytes, wrong channel and unbounded sizes" {
    const value = Record{ .kind = .r4os, .new = .{ .bytes = 100, .checksum = 5, .sha256 = [_]u8{7} ** 32 }, .old = .{ .bytes = 50, .checksum = 6, .sha256 = [_]u8{8} ** 32 } };
    var bytes = value.encode();
    const decoded = try Record.decode(&bytes, .r4os);
    try std.testing.expect(decoded.new.eql(value.new) and decoded.old.?.eql(value.old.?));
    for (0..bytes.len) |i| {
        bytes[i] ^= 1;
        try std.testing.expectError(error.CacheJournal, Record.decode(&bytes, .r4os));
        bytes[i] ^= 1;
    }
    try std.testing.expectError(error.CacheJournal, Record.decode(&bytes, .recovery));
    try std.testing.expect(!std.mem.eql(u8, paths(.r4os).part, paths(.recovery).part));
}
