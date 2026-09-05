// Host model for the NTFS atomic ownership transfer (0.60.8).
//
// Drives the REAL shared replaceFileAtomic (rename chain inside one dirty
// bracket) against a RAM-backed device: the full state matrix (normal
// replace, idempotent repetition, new target, crash continuation, foreign
// states, alias/flag/type rejections, the recovery rollback pattern) plus a
// crash matrix that cuts the chain after every durable flush and requires
// the SAME call to complete idempotently afterwards - old or new content,
// never a torn or lost target.

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
    var builder = try mkfs.Builder.init(allocator, 24 * 1024 * 1024, "R4OSREPL", 0, meta, 132_000_000_000_000_000, 0x2608);
    return builder.finalize();
}

fn readAndCheck(v: *vol.Volume, dir: u64, name: []const u8, expected: []const u8) bool {
    const found = vol.lookupInDirectory(v, dir, name) orelse return false;
    var buf: [65536]u8 = undefined;
    if (expected.len > buf.len) return false;
    const got = vol.readFileRange(v, found.record, 0, buf[0..expected.len]) orelse return false;
    if (got != expected.len) return false;
    return std.mem.eql(u8, buf[0..expected.len], expected);
}

fn exists(v: *vol.Volume, dir: u64, name: []const u8) bool {
    return vol.lookupInDirectory(v, dir, name) != null;
}

const OLD = "old target payload for the atomic replace";
const NEW = "NEW staged payload that takes over the target name";

fn setupCase(v: *vol.Volume, root: u64, with_target: bool, with_staged: bool, with_backup: bool) bool {
    inline for (.{ "VERSION.R4S", "VERSION.STG", "VERSION.BAK" }) |n| {
        if (vol.lookupInDirectory(v, root, n) != null) {
            if (vol.deleteFile(v, root, n) != .ok) return false;
        }
    }
    if (with_target and vol.createFile(v, root, "VERSION.R4S", OLD) != .ok) return false;
    if (with_staged and vol.createFile(v, root, "VERSION.STG", NEW) != .ok) return false;
    if (with_backup and vol.createFile(v, root, "VERSION.BAK", OLD) != .ok) return false;
    return true;
}

fn replaceCall(v: *vol.Volume, root: u64) vol.ReplaceResult {
    return vol.replaceFileAtomic(v, root, "VERSION.R4S", "VERSION.STG", "VERSION.BAK", true);
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;
    const cwd = std.Io.Dir.cwd();
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len < 2 or args.len > 3) {
        std.debug.print("Usage: CheckNtfsReplaceModel0608 <meta-dir> [out-disk.img]\n", .{});
        std.process.exit(2);
    }
    const out_path: ?[]const u8 = if (args.len == 3) args[2] else null;
    var meta_dir = try cwd.openDir(io, args[1], .{});
    defer meta_dir.close(io);
    const meta = try loadMeta(allocator, io, meta_dir);

    // ---- state matrix ------------------------------------------------------
    {
        const image = try formatFresh(allocator, meta);
        var dev = RamDevice{ .image = image };
        var v = openVolume(&dev) orelse return fail("mount failed", .{});
        vol.flush_budget = null;
        const root = ntfs.MFT_RECORD_ROOT;

        // 1. Normal replace.
        _ = setupCase(&v, root, true, true, false);
        if (replaceCall(&v, root) != .ok) fail("normal replace failed", .{});
        if (!readAndCheck(&v, root, "VERSION.R4S", NEW)) fail("target not new after replace", .{});
        if (!readAndCheck(&v, root, "VERSION.BAK", OLD)) fail("backup not old after replace", .{});
        if (exists(&v, root, "VERSION.STG")) fail("stage still present after replace", .{});

        // 2. Idempotent repetition.
        if (replaceCall(&v, root) != .ok) fail("idempotent repeat not ok", .{});
        if (!readAndCheck(&v, root, "VERSION.R4S", NEW)) fail("repeat changed target", .{});

        // 3. New target (no previous file, no backup).
        _ = setupCase(&v, root, false, true, false);
        if (replaceCall(&v, root) != .ok) fail("new-target replace failed", .{});
        if (!readAndCheck(&v, root, "VERSION.R4S", NEW)) fail("new target wrong content", .{});
        if (exists(&v, root, "VERSION.BAK")) fail("new target created backup", .{});

        // 4. Crash continuation state: stage + backup, no target.
        _ = setupCase(&v, root, false, true, true);
        if (replaceCall(&v, root) != .ok) fail("continuation replace failed", .{});
        if (!readAndCheck(&v, root, "VERSION.R4S", NEW)) fail("continuation target wrong", .{});
        if (!readAndCheck(&v, root, "VERSION.BAK", OLD)) fail("continuation backup lost", .{});

        // 5. Nothing staged, nothing present.
        _ = setupCase(&v, root, false, false, false);
        if (replaceCall(&v, root) != .not_found) fail("missing everything not not_found", .{});

        // 6. Foreign full state target+stage+backup.
        _ = setupCase(&v, root, true, true, true);
        if (replaceCall(&v, root) != .conflict) fail("foreign T+S+B not conflict", .{});

        // 7. Rejections: aliases, flag, directory target.
        _ = setupCase(&v, root, true, true, false);
        if (vol.replaceFileAtomic(&v, root, "VERSION.R4S", "VERSION.R4S", "VERSION.BAK", true) != .alias) fail("alias not rejected", .{});
        if (vol.replaceFileAtomic(&v, root, "VERSION.R4S", "VERSION.STG", "VERSION.BAK", false) != .not_atomic) fail("consume_stage=false not rejected", .{});
        if (vol.createDirectory(&v, root, "DIRTGT") != .ok) fail("mkdir for reject failed", .{});
        if (vol.replaceFileAtomic(&v, root, "DIRTGT", "VERSION.STG", "VERSION.BAK", true) != .read_only) fail("dir target not rejected", .{});
        if (vol.deleteDirectory(&v, root, "DIRTGT") != .ok) fail("mkdir cleanup failed", .{});
        // Non-8.3 stage name breaks the naming contract.
        if (vol.replaceFileAtomic(&v, root, "VERSION.R4S", "stagename.toolong", "VERSION.BAK", true) != .invalid) fail("long stage name not rejected", .{});

        // 8. Recovery rollback pattern: swap stage/backup roles.
        _ = setupCase(&v, root, true, true, false);
        if (replaceCall(&v, root) != .ok) fail("rollback setup replace failed", .{});
        // Roll back: target <- backup, the old target parks under the stage name.
        if (vol.replaceFileAtomic(&v, root, "VERSION.R4S", "VERSION.BAK", "VERSION.STG", true) != .ok) fail("rollback replace failed", .{});
        if (!readAndCheck(&v, root, "VERSION.R4S", OLD)) fail("rollback target not old", .{});
        if (!readAndCheck(&v, root, "VERSION.STG", NEW)) fail("rollback parked new missing", .{});

        // Dump for external NtfsVerify/chkdsk.
        if (out_path) |path| {
            const disk = try allocator.alloc(u8, 2048 * 512 + image.len);
            @memset(disk[0 .. 2048 * 512], 0);
            std.mem.writeInt(u32, disk[0x1B8..][0..4], 0x52344F56, .little);
            disk[446 + 4] = 0x07;
            std.mem.writeInt(u32, disk[446 + 8 ..][0..4], 2048, .little);
            std.mem.writeInt(u32, disk[446 + 12 ..][0..4], @intCast(image.len / 512), .little);
            disk[510] = 0x55;
            disk[511] = 0xAA;
            std.mem.writeInt(u32, image[0x1C..][0..4], 2048, .little);
            const backup_at = @as(usize, @intCast(std.mem.readInt(u64, image[0x28..][0..8], .little) * 512));
            if (backup_at + 4 <= image.len) std.mem.writeInt(u32, image[backup_at + 0x1C ..][0..4], 2048, .little);
            @memcpy(disk[2048 * 512 ..], image);
            try cwd.writeFile(io, .{ .sub_path = path, .data = disk });
            std.debug.print("NTFSREPLACE image written: {s}\n", .{path});
        }
    }

    // ---- repeated catalog-style replacements -----------------------------
    // Klickifax publishes the same catalog name repeatedly, but gives every
    // transaction fresh private stage/backup siblings and removes the backup
    // after success.  Exercise more than the four replacements that exposed
    // the guest-only NTFS failure.
    {
        const image = try formatFresh(allocator, meta);
        var dev = RamDevice{ .image = image };
        var v = openVolume(&dev) orelse return fail("catalog-cycle mount failed", .{});
        vol.flush_budget = null;
        const root = ntfs.MFT_RECORD_ROOT;
        if (vol.createDirectory(&v, root, "FONTS") != .ok) return fail("catalog-cycle directory create failed", .{});
        const font_dir = (vol.lookupInDirectory(&v, root, "FONTS") orelse return fail("catalog-cycle directory lookup failed", .{})).record;
        if (vol.createDirectory(&v, font_dir, "OBJECTS") != .ok or
            vol.createDirectory(&v, font_dir, "STAGING") != .ok or
            vol.createFile(&v, font_dir, "FCACHE.LCK", "") != .ok)
        {
            return fail("catalog-cycle layout create failed", .{});
        }
        var cycle: usize = 0;
        while (cycle < 8) : (cycle += 1) {
            var stage_buf: [12]u8 = undefined;
            var backup_buf: [12]u8 = undefined;
            // Start at 0x0A so every tuple exercises the A-F part of the
            // backend-common upper-case 8.3 naming contract.
            const suffix = cycle + 0x0A;
            const stage = std.fmt.bufPrint(stage_buf[0..], "KC{X:0>6}.TMP", .{suffix}) catch unreachable;
            const backup = std.fmt.bufPrint(backup_buf[0..], "KC{X:0>6}.BAK", .{suffix}) catch unreachable;
            var payload_buf: [32]u8 = undefined;
            const payload = std.fmt.bufPrint(payload_buf[0..], "catalog generation {d}", .{cycle}) catch unreachable;
            if (vol.createFile(&v, font_dir, stage, payload) != .ok) {
                fail("catalog cycle {d}: stage create failed", .{cycle});
                break;
            }
            const result = vol.replaceFileAtomic(&v, font_dir, "CATALOG.R4S", stage, backup, true);
            if (result != .ok) {
                fail("catalog cycle {d}: replace failed ({s})", .{ cycle, @tagName(result) });
                break;
            }
            if (!readAndCheck(&v, font_dir, "CATALOG.R4S", payload)) {
                fail("catalog cycle {d}: target payload wrong", .{cycle});
                break;
            }
            if (cycle == 0) {
                if (exists(&v, font_dir, backup)) fail("catalog cycle 0: unexpected backup", .{});
            } else if (vol.deleteFile(&v, font_dir, backup) != .ok) {
                fail("catalog cycle {d}: backup cleanup failed", .{cycle});
                break;
            }
        }
    }

    // ---- crash matrix ------------------------------------------------------
    {
        var budget: u32 = 1;
        while (budget <= 12) : (budget += 1) {
            const image = try formatFresh(allocator, meta);
            defer allocator.free(image);
            var dev = RamDevice{ .image = image };
            var v = openVolume(&dev) orelse {
                fail("crash mount {d} failed", .{budget});
                continue;
            };
            vol.flush_budget = null;
            const root = ntfs.MFT_RECORD_ROOT;
            _ = vol.createFile(&v, root, "KEEP.TXT", "bystander must survive");
            if (!setupCase(&v, root, true, true, false)) {
                fail("crash setup {d} failed", .{budget});
                continue;
            }

            vol.flush_budget = budget;
            _ = replaceCall(&v, root);
            vol.flush_budget = null;

            // Remount view; the volume must be usable and the SAME call must
            // complete the transfer idempotently.
            var dev2 = RamDevice{ .image = image };
            var v2 = openVolume(&dev2) orelse {
                fail("crash budget {d}: unmountable", .{budget});
                continue;
            };
            if (!readAndCheck(&v2, root, "KEEP.TXT", "bystander must survive")) {
                fail("crash budget {d}: bystander damaged", .{budget});
            }
            const resume_rc = replaceCall(&v2, root);
            if (resume_rc != .ok) {
                fail("crash budget {d}: resume not ok ({s})", .{ budget, @tagName(resume_rc) });
                continue;
            }
            if (!readAndCheck(&v2, root, "VERSION.R4S", NEW)) {
                fail("crash budget {d}: final target not new", .{budget});
            }
            if (exists(&v2, root, "VERSION.STG")) {
                fail("crash budget {d}: stage survived resume", .{budget});
            }
        }
    }

    if (failures != 0) {
        std.debug.print("NTFSREPLACE result: FAILED ({d})\n", .{failures});
        std.process.exit(1);
    }
    std.debug.print("NTFSREPLACE result: OK\n", .{});
}
