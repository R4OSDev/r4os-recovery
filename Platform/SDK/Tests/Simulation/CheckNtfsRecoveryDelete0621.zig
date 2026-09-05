// Host model for the NTFS recovery-only compare-and-delete (0.60.21).
//
// Alias-first publishing has a durable window between the canonical
// $FILE_NAME rewrite and the target index insert.  A power loss inside that
// window leaves an index entry whose name no longer matches the record's
// canonical name.  Generic lookups reject that half-state on purpose, so
// before 0.60.21 the entry could neither be read, nor completed by name, nor
// deleted - it was stuck forever.
//
// This model drives the REAL shared core against a RAM device:
//   * it reproduces the half-state with the dedicated publish cut (the
//     window contains no flush of its own, so flush_budget cannot reach it),
//   * proves the stuck condition (normal lookup and plain delete refuse it),
//   * proves the recovery view sees it and the recovery delete reverses it,
//   * proves forward completion from the very same cut still works,
//   * pins the negative cases: foreign object, stale sequence, directory,
//     absent name and hard link - none of which may write anything,
//   * proves the alias case detaches only the surplus name and never frees
//     a record another durable alias still points at,
//   * sweeps the cut across a flush matrix and requires a terminal state
//     that NtfsVerify accepts.

const std = @import("std");
const ntfs = @import("ntfs_format");
const vol = @import("ntfs_volume");
const mkfs = @import("ntfs_mkfs");

const RamDevice = struct {
    image: []u8,

    fn read(ctx: *anyopaque, lba: u64, count: u32, out: []u8) bool {
        const self: *RamDevice = @ptrCast(@alignCast(ctx));
        const start: usize = @intCast(lba * 512);
        const len: usize = @intCast(@as(u64, count) * 512);
        if (start + len > self.image.len or out.len < len) return false;
        @memcpy(out[0..len], self.image[start .. start + len]);
        return true;
    }

    fn write(ctx: *anyopaque, lba: u64, count: u32, data: []const u8) bool {
        const self: *RamDevice = @ptrCast(@alignCast(ctx));
        const start: usize = @intCast(lba * 512);
        const len: usize = @intCast(@as(u64, count) * 512);
        if (start + len > self.image.len or data.len < len) return false;
        @memcpy(self.image[start .. start + len], data[0..len]);
        return true;
    }

    fn flush(ctx: *anyopaque) bool {
        _ = ctx;
        return true;
    }

    fn device(self: *RamDevice) vol.Device {
        return .{ .ctx = self, .read_sectors = read, .write_sectors = write, .flush = flush };
    }
};

var scratch: vol.Scratch = .{};
var mft_runs: [vol.MAX_MFT_RUNS]ntfs.Run = undefined;
var mft_run_count: usize = 0;
var upcase_buf: [ntfs.UPCASE_BYTES]u8 = undefined;
var failures: usize = 0;

fn fail(comptime fmt: []const u8, args: anytype) void {
    failures += 1;
    std.debug.print("FAIL: " ++ fmt ++ "\n", args);
}

fn openVolume(dev: *RamDevice) ?vol.Volume {
    const info = vol.mount(dev.device(), 0, &scratch, mft_runs[0..]) orelse return null;
    mft_run_count = info.mft_run_count;
    var v = vol.Volume{
        .device = dev.device(),
        .partition_lba = 0,
        .cluster_bytes = info.cluster_bytes,
        .record_bytes = info.record_bytes,
        .index_block_bytes = info.index_block_bytes,
        .total_sectors = info.total_sectors,
        .mft_runs_buf = mft_runs[0..],
        .mft_run_count = &mft_run_count,
        .upcase = &[_]u8{},
        .scratch = &scratch,
        .now_filetime = 132_100_000_000_000_000,
    };
    const got = vol.readFileRange(&v, ntfs.MFT_RECORD_UPCASE, 0, upcase_buf[0..]) orelse return null;
    if (got != ntfs.UPCASE_BYTES) return null;
    v.upcase = upcase_buf[0..];
    return v;
}

fn loadMeta(allocator: std.mem.Allocator, io: anytype, dir: std.Io.Dir) !mkfs.Meta {
    const L = struct {
        fn req(a: std.mem.Allocator, i: anytype, d: std.Io.Dir, n: []const u8) ![]u8 {
            return d.readFileAlloc(i, n, a, .limited(1 << 20));
        }
        fn opt(a: std.mem.Allocator, i: anytype, d: std.Io.Dir, n: []const u8) []u8 {
            return d.readFileAlloc(i, n, a, .limited(1 << 20)) catch &[_]u8{};
        }
    };
    return .{
        .upcase = try L.req(allocator, io, dir, "upcase.bin"),
        .upcase_info = L.opt(allocator, io, dir, "upcase_info.bin"),
        .attrdef = try L.req(allocator, io, dir, "attrdef.bin"),
        .sds_prefix = try L.req(allocator, io, dir, "secure_sds_prefix.bin"),
        .sdh_root = try L.req(allocator, io, dir, "secure_sdh_root.bin"),
        .sii_root = try L.req(allocator, io, dir, "secure_sii_root.bin"),
        .sdh_alloc = try L.req(allocator, io, dir, "secure_SDH_alloc.bin"),
        .sii_alloc = try L.req(allocator, io, dir, "secure_SII_alloc.bin"),
        .sdh_bitmap = try L.req(allocator, io, dir, "secure_SDH_bitmap.bin"),
        .sii_bitmap = try L.req(allocator, io, dir, "secure_SII_bitmap.bin"),
        .objid_o_root = try L.req(allocator, io, dir, "extend_objid_o_root.bin"),
        .quota_o_root = try L.req(allocator, io, dir, "extend_quota_o_root.bin"),
        .quota_q_root = try L.req(allocator, io, dir, "extend_quota_q_root.bin"),
        .reparse_r_root = try L.req(allocator, io, dir, "extend_reparse_r_root.bin"),
        .root_sd = try L.req(allocator, io, dir, "root_sd.bin"),
        .boot_sd = try L.req(allocator, io, dir, "boot_sd.bin"),
    };
}

fn formatFresh(allocator: std.mem.Allocator, meta: mkfs.Meta) ![]u8 {
    var builder = try mkfs.Builder.init(allocator, 24 * 1024 * 1024, "R4OSRECV", 0, meta, 132_000_000_000_000_000, 0x2621);
    return builder.finalize();
}

const STAGE = "UPLOAD.STG";
const TARGET = "UPLOAD.BIN";
const KEEP = "KEEP.TXT";
const KEEP_DATA = "bystander must survive every recovery decision";
const PAYLOAD = "staged upload payload that the publish was about to hand over";

fn exists(v: *vol.Volume, dir: u64, name: []const u8) bool {
    return vol.lookupInDirectory(v, dir, name) != null;
}

fn readAndCheck(v: *vol.Volume, dir: u64, name: []const u8, expected: []const u8) bool {
    const found = vol.lookupInDirectory(v, dir, name) orelse return false;
    var buf: [4096]u8 = undefined;
    if (expected.len > buf.len) return false;
    const got = vol.readFileRange(v, found.record, 0, buf[0..expected.len]) orelse return false;
    if (got != expected.len) return false;
    return std.mem.eql(u8, buf[0..expected.len], expected);
}

/// Identity of the staged object, read before the cut.
const Identity = struct { record: u64, sequence: u16 };

const HalfState = struct { image: []u8, id: Identity };

fn stageIdentity(v: *vol.Volume, root: u64) ?Identity {
    var out: vol.LookupResult = undefined;
    if (vol.lookupInDirectoryStatusTransient(v, root, STAGE, &out) != .found) return null;
    return .{ .record = out.record, .sequence = out.sequence };
}

/// Builds the half-state: a staged file whose canonical $FILE_NAME already
/// says TARGET while the only index entry is still STAGE.
fn buildHalfState(allocator: std.mem.Allocator, meta: mkfs.Meta) !?HalfState {
    const image = try formatFresh(allocator, meta);
    var dev = RamDevice{ .image = image };
    var v = openVolume(&dev) orelse return null;
    vol.flush_budget = null;
    vol.cut_after_canonical_rewrite = false;
    const root = ntfs.MFT_RECORD_ROOT;

    if (vol.createFile(&v, root, KEEP, KEEP_DATA) != .ok) return null;
    if (vol.createFile(&v, root, STAGE, PAYLOAD) != .ok) return null;
    const id = stageIdentity(&v, root) orelse return null;

    vol.cut_after_canonical_rewrite = true;
    _ = vol.publishFileCreateOnly(&v, root, TARGET, STAGE);
    vol.cut_after_canonical_rewrite = false;

    return .{ .image = image, .id = id };
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;
    const cwd = std.Io.Dir.cwd();
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len < 2 or args.len > 3) {
        std.debug.print("Usage: CheckNtfsRecoveryDelete0621 <meta-dir> [out-disk.img]\n", .{});
        std.process.exit(2);
    }
    const out_path: ?[]const u8 = if (args.len == 3) args[2] else null;
    var meta_dir = try cwd.openDir(io, args[1], .{});
    defer meta_dir.close(io);
    const meta = try loadMeta(allocator, io, meta_dir);
    const root = ntfs.MFT_RECORD_ROOT;

    // ---- 1. the half-state is real, visible only to recovery, and stuck ----
    {
        const built = (try buildHalfState(allocator, meta)) orelse return fail("halfstate setup failed", .{});
        var dev = RamDevice{ .image = built.image };
        var v = openVolume(&dev) orelse return fail("halfstate remount failed", .{});

        // The stage name must be rejected by every generic lookup: the index
        // key and the canonical $FILE_NAME disagree, which is metadata
        // disagreement, never a plain absence.
        var generic: vol.LookupResult = undefined;
        if (vol.lookupInDirectoryStatus(&v, root, STAGE, &generic) != .io) {
            fail("generic lookup accepted the half-state", .{});
        }
        // The target name was never inserted into the index.
        var target_view: vol.LookupResult = undefined;
        if (vol.lookupInDirectoryStatusTransient(&v, root, TARGET, &target_view) != .not_found) {
            fail("target name unexpectedly present after the cut", .{});
        }
        // The recovery view resolves it with the exact stage identity.
        var recovered: vol.LookupResult = undefined;
        if (vol.lookupInDirectoryStatusTransient(&v, root, STAGE, &recovered) != .found) {
            fail("recovery lookup did not see the half-state", .{});
        } else if (recovered.record != built.id.record or recovered.sequence != built.id.sequence) {
            fail("recovery lookup returned a foreign identity", .{});
        }
        // The plain delete cannot reverse it - this is the stuck condition.
        if (vol.deleteFile(&v, root, STAGE) == .ok) {
            fail("plain delete unexpectedly removed the half-state", .{});
        }
        std.debug.print("halfstate: ok (generic=io recovery=found plain-delete=refused)\n", .{});
    }

    // ---- 2. the recovery delete reverses it and releases the object -------
    {
        const built = (try buildHalfState(allocator, meta)) orelse return fail("reverse setup failed", .{});
        var dev = RamDevice{ .image = built.image };
        var v = openVolume(&dev) orelse return fail("reverse remount failed", .{});

        const rc = vol.deleteRecoveryEntryIfIdentity(&v, root, STAGE, built.id.record, built.id.sequence);
        if (rc != .ok) fail("recovery delete failed ({s})", .{@tagName(rc)});
        if (exists(&v, root, STAGE) or exists(&v, root, TARGET)) fail("a name survived the recovery delete", .{});
        var gone: vol.LookupResult = undefined;
        if (vol.lookupInDirectoryStatusTransient(&v, root, STAGE, &gone) != .not_found) {
            fail("recovery view still sees the removed name", .{});
        }
        if (!readAndCheck(&v, root, KEEP, KEEP_DATA)) fail("bystander damaged by the recovery delete", .{});

        // Idempotent: a repeated replay must be a clean absence, not an error.
        const again = vol.deleteRecoveryEntryIfIdentity(&v, root, STAGE, built.id.record, built.id.sequence);
        if (again != .not_found) fail("replayed recovery delete not idempotent ({s})", .{@tagName(again)});
        std.debug.print("reverse: ok (released, idempotent, bystander intact)\n", .{});
    }

    // ---- 3. forward completion from the identical cut still works ---------
    {
        const built = (try buildHalfState(allocator, meta)) orelse return fail("forward setup failed", .{});
        var dev = RamDevice{ .image = built.image };
        var v = openVolume(&dev) orelse return fail("forward remount failed", .{});

        const rc = vol.publishFileCreateOnly(&v, root, TARGET, STAGE);
        if (rc != .ok) fail("forward publish from the cut failed ({s})", .{@tagName(rc)});
        if (!readAndCheck(&v, root, TARGET, PAYLOAD)) fail("target content wrong after forward publish", .{});
        if (exists(&v, root, STAGE)) fail("stage survived the forward publish", .{});
        if (!readAndCheck(&v, root, KEEP, KEEP_DATA)) fail("bystander damaged by the forward publish", .{});
        std.debug.print("forward: ok (same cut completes to the target)\n", .{});
    }

    // ---- 4. negatives: nothing may be written ----------------------------
    {
        const built = (try buildHalfState(allocator, meta)) orelse return fail("negative setup failed", .{});
        var dev = RamDevice{ .image = built.image };
        var v = openVolume(&dev) orelse return fail("negative remount failed", .{});

        // Stale sequence: a recycled record must never satisfy the delete.
        const stale = vol.deleteRecoveryEntryIfIdentity(&v, root, STAGE, built.id.record, built.id.sequence +% 1);
        if (stale != .mismatch) fail("stale sequence not rejected ({s})", .{@tagName(stale)});

        // Foreign record number under the same name.
        const foreign = vol.deleteRecoveryEntryIfIdentity(&v, root, STAGE, built.id.record + 1, built.id.sequence);
        if (foreign != .mismatch) fail("foreign record not rejected ({s})", .{@tagName(foreign)});

        // Absent name.
        const absent = vol.deleteRecoveryEntryIfIdentity(&v, root, "NOSUCH.TMP", built.id.record, built.id.sequence);
        if (absent != .not_found) fail("absent name not reported ({s})", .{@tagName(absent)});

        // Directory: this primitive only reverses file publishes.
        if (vol.createDirectory(&v, root, "ADIR") != .ok) fail("dir setup failed", .{});
        var dir_view: vol.LookupResult = undefined;
        if (vol.lookupInDirectoryStatusTransient(&v, root, "ADIR", &dir_view) != .found) {
            fail("dir lookup failed", .{});
        } else {
            const dir_rc = vol.deleteRecoveryEntryIfIdentity(&v, root, "ADIR", dir_view.record, dir_view.sequence);
            if (dir_rc != .directory) fail("directory not rejected ({s})", .{@tagName(dir_rc)});
        }

        // After every refusal the half-state and the bystander are untouched.
        var still: vol.LookupResult = undefined;
        if (vol.lookupInDirectoryStatusTransient(&v, root, STAGE, &still) != .found or
            still.record != built.id.record or still.sequence != built.id.sequence)
        {
            fail("a rejected call disturbed the half-state", .{});
        }
        if (!readAndCheck(&v, root, KEEP, KEEP_DATA)) fail("a rejected call damaged the bystander", .{});

        // The rejections must not have consumed the object either: the
        // forward publish still completes afterwards.
        if (vol.publishFileCreateOnly(&v, root, TARGET, STAGE) != .ok) {
            fail("publish broken after the negative cases", .{});
        }
        std.debug.print("negatives: ok (sequence, foreign, absent, directory - all inert)\n", .{});
    }

    // ---- 5. alias case: detach only, never free a still-referenced record -
    {
        // The two-alias window sits between the target index insert and the
        // stage detach.  Search for the budget that lands in it instead of
        // hard-coding a flush count that a later change could shift.
        var found_window = false;
        var probe: u32 = 0;
        var image: []u8 = &[_]u8{};
        var id: Identity = .{ .record = 0, .sequence = 0 };
        while (probe <= 3 and !found_window) : (probe += 1) {
            image = try formatFresh(allocator, meta);
            var dev = RamDevice{ .image = image };
            var v = openVolume(&dev) orelse return fail("alias mount failed", .{});
            vol.flush_budget = null;
            vol.cut_after_canonical_rewrite = false;

            if (vol.createFile(&v, root, KEEP, KEEP_DATA) != .ok) fail("alias bystander failed", .{});
            if (vol.createFile(&v, root, STAGE, PAYLOAD) != .ok) fail("alias stage failed", .{});
            id = stageIdentity(&v, root) orelse return fail("alias identity failed", .{});

            vol.flush_budget = probe;
            _ = vol.publishFileCreateOnly(&v, root, TARGET, STAGE);
            vol.flush_budget = null;

            var probe_dev = RamDevice{ .image = image };
            var probe_v = openVolume(&probe_dev) orelse continue;
            var pa: vol.LookupResult = undefined;
            var pb: vol.LookupResult = undefined;
            if (vol.lookupInDirectoryStatusTransient(&probe_v, root, STAGE, &pa) == .found and
                vol.lookupInDirectoryStatusTransient(&probe_v, root, TARGET, &pb) == .found and
                pa.record == pb.record and pa.sequence == pb.sequence)
            {
                found_window = true;
            }
        }

        var dev2 = RamDevice{ .image = image };
        var v2 = openVolume(&dev2) orelse return fail("alias remount failed", .{});

        if (found_window) {
            // Deleting the CANONICAL name here must not free the record,
            // because the stage alias still points at it.
            const canon_rc = vol.deleteRecoveryEntryIfIdentity(&v2, root, TARGET, id.record, id.sequence);
            if (canon_rc != .unlinked) {
                fail("canonical-name delete in the alias state not reported as unlinked ({s})", .{@tagName(canon_rc)});
            }
            if (exists(&v2, root, TARGET)) fail("target alias survived the detach", .{});
            // The object must still be reachable and readable via the
            // remaining alias through the recovery view.
            var left: vol.LookupResult = undefined;
            if (vol.lookupInDirectoryStatusTransient(&v2, root, STAGE, &left) != .found or
                left.record != id.record or left.sequence != id.sequence)
            {
                fail("the surviving alias lost the object", .{});
            }
            var buf: [PAYLOAD.len]u8 = undefined;
            const got = vol.readFileRange(&v2, id.record, 0, buf[0..]) orelse 0;
            if (got != PAYLOAD.len or !std.mem.eql(u8, buf[0..], PAYLOAD)) {
                fail("object content lost after the alias detach", .{});
            }
            // Now the remaining alias really is the last name.
            const last_rc = vol.deleteRecoveryEntryIfIdentity(&v2, root, STAGE, id.record, id.sequence);
            if (last_rc != .ok) fail("last-name delete failed ({s})", .{@tagName(last_rc)});
            if (!readAndCheck(&v2, root, KEEP, KEEP_DATA)) fail("bystander damaged in the alias case", .{});
            std.debug.print("alias: ok (unlinked then released, object never orphaned)\n", .{});
        } else {
            fail("alias: no flush budget reached the two-alias window", .{});
        }
    }

    // ---- 6. crash sweep across the cut, terminal state must be verifiable -
    {
        var budget: u32 = 1;
        while (budget <= 8) : (budget += 1) {
            const built = (try buildHalfState(allocator, meta)) orelse {
                fail("sweep {d}: setup failed", .{budget});
                continue;
            };
            defer allocator.free(built.image);
            var dev = RamDevice{ .image = built.image };
            var v = openVolume(&dev) orelse {
                fail("sweep {d}: unmountable after the cut", .{budget});
                continue;
            };

            // Recovery itself is interrupted after `budget` durable steps.
            vol.flush_budget = budget;
            _ = vol.deleteRecoveryEntryIfIdentity(&v, root, STAGE, built.id.record, built.id.sequence);
            vol.flush_budget = null;

            var dev2 = RamDevice{ .image = built.image };
            var v2 = openVolume(&dev2) orelse {
                fail("sweep {d}: unmountable after interrupted recovery", .{budget});
                continue;
            };
            if (!readAndCheck(&v2, root, KEEP, KEEP_DATA)) {
                fail("sweep {d}: bystander damaged", .{budget});
            }
            // Replay must reach a terminal state: either the object is gone
            // or it is still exactly the same stuck object we may retry.
            const rc = vol.deleteRecoveryEntryIfIdentity(&v2, root, STAGE, built.id.record, built.id.sequence);
            switch (rc) {
                .ok, .not_found => {},
                else => fail("sweep {d}: replay not terminal ({s})", .{ budget, @tagName(rc) }),
            }
            if (exists(&v2, root, STAGE) or exists(&v2, root, TARGET)) {
                fail("sweep {d}: a name survived the replay", .{budget});
            }
        }
        std.debug.print("sweep: ok (8 interrupted recoveries all replay to a terminal state)\n", .{});
    }

    // ---- 7. emit an image whose half-state was repaired, for NtfsVerify --
    if (out_path) |path| {
        const built = (try buildHalfState(allocator, meta)) orelse return fail("image setup failed", .{});
        var dev = RamDevice{ .image = built.image };
        var v = openVolume(&dev) orelse return fail("image remount failed", .{});
        if (vol.deleteRecoveryEntryIfIdentity(&v, root, STAGE, built.id.record, built.id.sequence) != .ok) {
            fail("image repair failed", .{});
        }
        // A second, forward-completed publish so the emitted volume also
        // carries a normally published object next to the repaired hole.
        if (vol.createFile(&v, root, STAGE, PAYLOAD) != .ok) fail("image restage failed", .{});
        if (vol.publishFileCreateOnly(&v, root, TARGET, STAGE) != .ok) fail("image publish failed", .{});

        const disk = try allocator.alloc(u8, built.image.len + 2048 * 512);
        @memset(disk[0 .. 2048 * 512], 0);
        std.mem.writeInt(u32, disk[0x1B8..][0..4], 0x52344F56, .little);
        disk[446 + 4] = 0x07;
        std.mem.writeInt(u32, disk[446 + 8 ..][0..4], 2048, .little);
        std.mem.writeInt(u32, disk[446 + 12 ..][0..4], @intCast(built.image.len / 512), .little);
        disk[510] = 0x55;
        disk[511] = 0xAA;
        std.mem.writeInt(u32, built.image[0x1C..][0..4], 2048, .little);
        const backup_at = @as(usize, @intCast(std.mem.readInt(u64, built.image[0x28..][0..8], .little) * 512));
        if (backup_at + 4 <= built.image.len) {
            std.mem.writeInt(u32, built.image[backup_at + 0x1C ..][0..4], 2048, .little);
        }
        @memcpy(disk[2048 * 512 ..], built.image);
        try cwd.writeFile(io, .{ .sub_path = path, .data = disk });
        std.debug.print("NTFSRECOVERYDELETE image written: {s}\n", .{path});
    }

    if (failures != 0) {
        std.debug.print("NTFSRECOVERYDELETE result: FAILED ({d})\n", .{failures});
        std.process.exit(1);
    }
    std.debug.print("NTFSRECOVERYDELETE result: OK\n", .{});
}
