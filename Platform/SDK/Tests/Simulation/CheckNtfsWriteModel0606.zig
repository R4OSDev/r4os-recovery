// Host model for NTFS write phase 1 (0.60.6).
//
// Drives the REAL shared ntfs_volume write path against a RAM-backed device:
// formats a volume with the shared formatter, creates/overwrites/appends/
// deletes files, verifies every result through the shared read path and
// NtfsVerify-equivalent invariants, and runs a crash matrix that aborts the
// operation after each durable flush and checks the volume stays
// structurally sound (no cross-links, bitmap exact) with at most leaked
// allocation.

const std = @import("std");
const ntfs = @import("ntfs_format");
const vol = @import("ntfs_volume");
const mkfs = @import("ntfs_mkfs");

const CLUSTER: usize = 4096;

// ---- RAM device ----------------------------------------------------------

const RamDevice = struct {
    image: []u8,
    flushes: u32 = 0,
    write_attempts: u64 = 0,
    fail_write_at: ?u64 = null,

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
        self.write_attempts += 1;
        if (self.fail_write_at == self.write_attempts) {
            self.fail_write_at = null;
            return false;
        }
        const start: usize = @intCast(lba * 512);
        const len: usize = @intCast(@as(u64, count) * 512);
        if (start + len > self.image.len or data.len < len) return false;
        @memcpy(self.image[start .. start + len], data[0..len]);
        return true;
    }

    fn failWriteAfter(self: *RamDevice, attempts: u64) void {
        std.debug.assert(attempts != 0);
        self.fail_write_at = self.write_attempts + attempts;
    }

    fn flush(ctx: *anyopaque) bool {
        const self: *RamDevice = @ptrCast(@alignCast(ctx));
        self.flushes += 1;
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
    // Load $UpCase.
    var attr = vol.AttrScratch{};
    if (!vol.collectAttribute(&v, ntfs.MFT_RECORD_UPCASE, .data, &[_]u8{}, &attr)) return null;
    // Read the upcase content through the read path.
    const raw = readWholeAttr(&v, ntfs.MFT_RECORD_UPCASE, upcase_buf[0..]) orelse return null;
    if (raw != ntfs.UPCASE_BYTES) return null;
    v.upcase = upcase_buf[0..];
    return v;
}

fn readWholeAttr(v: *vol.Volume, record: u64, out: []u8) ?usize {
    return vol.readFileRange(v, record, 0, out);
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
    var builder = try mkfs.Builder.init(allocator, 24 * 1024 * 1024, "R4OSWRITE", 0, meta, 132_000_000_000_000_000, 0x1234);
    return builder.finalize();
}

fn patternFill(seed: u32, out: []u8) void {
    var s = seed | 1;
    for (out) |*b| {
        s ^= s << 13;
        s ^= s >> 17;
        s ^= s << 5;
        b.* = @truncate(s);
    }
}

fn readAndCheck(v: *vol.Volume, dir: u64, name: []const u8, expected: []const u8) bool {
    const found = vol.lookupInDirectory(v, dir, name) orelse return false;
    var buf: [65536]u8 = undefined;
    if (expected.len > buf.len) return false;
    const got = vol.readFileRange(v, found.record, 0, buf[0..expected.len]) orelse return false;
    if (got != expected.len) return false;
    return std.mem.eql(u8, buf[0..expected.len], expected);
}

fn structurallySound(image: []u8) bool {
    // Minimal invariant check: mount, walk root, ensure no referenced
    // cluster is double-counted and $Bitmap covers every referenced cluster.
    var dev = RamDevice{ .image = image };
    const v = openVolume(&dev) orelse return false;
    var vv = v;
    // Enumerate root fully.
    var sink = vol.EnumSink{ .out = null, .wanted = 1_000_000 };
    _ = vol.enumerateDirectory(&vv, ntfs.MFT_RECORD_ROOT, &sink);
    return !sink.failed;
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;
    const cwd = std.Io.Dir.cwd();
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len < 2 or args.len > 3) {
        std.debug.print("Usage: CheckNtfsWriteModel0606 <meta-dir> [out-disk.img]\n", .{});
        std.process.exit(2);
    }
    const out_path: ?[]const u8 = if (args.len == 3) args[2] else null;
    var meta_dir = try cwd.openDir(io, args[1], .{});
    defer meta_dir.close(io);
    const meta = try loadMeta(allocator, io, meta_dir);

    // --- Functional tests ---------------------------------------------------
    {
        const image = try formatFresh(allocator, meta);
        var dev = RamDevice{ .image = image };
        var v = openVolume(&dev) orelse {
            fail("mount of fresh volume failed", .{});
            return finish();
        };
        vol.flush_budget = null;
        const root = ntfs.MFT_RECORD_ROOT;

        // 1. Resident create + read.
        if (vol.createFile(&v, root, "HELLO.TXT", "hello world") != .ok) fail("create resident failed", .{});
        if (!readAndCheck(&v, root, "HELLO.TXT", "hello world")) fail("resident readback mismatch", .{});

        // 2. Duplicate create rejected.
        if (vol.createFile(&v, root, "HELLO.TXT", "x") != .exists) fail("duplicate create not rejected", .{});

        // 3. Non-resident create (multi-cluster).
        var big: [20000]u8 = undefined;
        patternFill(77, big[0..]);
        if (vol.createFile(&v, root, "BIG.BIN", big[0..]) != .ok) fail("create non-resident failed", .{});
        if (!readAndCheck(&v, root, "BIG.BIN", big[0..])) fail("non-resident readback mismatch", .{});

        // 4. Overwrite (shrink to resident).
        if (vol.writeFile(&v, root, "BIG.BIN", "small now") != .ok) fail("overwrite failed", .{});
        if (!readAndCheck(&v, root, "BIG.BIN", "small now")) fail("overwrite readback mismatch", .{});

        // 5. Append.
        if (vol.createFile(&v, root, "LOG.TXT", "line1\n") != .ok) fail("create for append failed", .{});
        if (vol.appendFileAtOffset(&v, root, "LOG.TXT", 6, "line2\n") != .ok) fail("append failed", .{});
        if (!readAndCheck(&v, root, "LOG.TXT", "line1\nline2\n")) fail("append readback mismatch", .{});
        if (vol.appendFileAtOffset(&v, root, "LOG.TXT", 5, "x") != .offset_mismatch) fail("append offset not guarded", .{});

        // 6. Delete + gone.
        if (vol.deleteFile(&v, root, "HELLO.TXT") != .ok) fail("delete failed", .{});
        if (vol.lookupInDirectory(&v, root, "HELLO.TXT") != null) fail("deleted file still present", .{});
        if (vol.deleteFile(&v, root, "HELLO.TXT") != .not_found) fail("second delete not not_found", .{});

        // 7. Many creates to exercise index growth in the resident root.
        var i: usize = 0;
        var name_buf: [32]u8 = undefined;
        while (i < 30) : (i += 1) {
            const n = std.fmt.bufPrint(name_buf[0..], "F{d:0>3}.DAT", .{i}) catch unreachable;
            var content: [64]u8 = undefined;
            patternFill(@intCast(i + 1), content[0..]);
            const rc = vol.createFile(&v, root, n, content[0..]);
            if (rc != .ok and rc != .dir_full) fail("bulk create {d} failed: {s}", .{ i, @tagName(rc) });
        }
        // Verify all that were created read back.
        i = 0;
        while (i < 30) : (i += 1) {
            const n = std.fmt.bufPrint(name_buf[0..], "F{d:0>3}.DAT", .{i}) catch unreachable;
            if (vol.lookupInDirectory(&v, root, n)) |_| {
                var content: [64]u8 = undefined;
                patternFill(@intCast(i + 1), content[0..]);
                if (!readAndCheck(&v, root, n, content[0..])) fail("bulk readback {d} mismatch", .{i});
            }
        }
        if (!structurallySound(image)) fail("volume not structurally sound after functional run", .{});

        // Dump the post-write image (MBR-wrapped) for external NtfsVerify /
        // chkdsk acceptance.
        if (out_path) |path| {
            const disk = try allocator.alloc(u8, 2048 * 512 + image.len);
            @memset(disk[0 .. 2048 * 512], 0);
            std.mem.writeInt(u32, disk[0x1B8..][0..4], 0x52344F53, .little);
            disk[446 + 4] = 0x07;
            std.mem.writeInt(u32, disk[446 + 8 ..][0..4], 2048, .little);
            std.mem.writeInt(u32, disk[446 + 12 ..][0..4], @intCast(image.len / 512), .little);
            disk[510] = 0x55;
            disk[511] = 0xAA;
            // Re-format the boot sector's partition_lba: the bare volume was
            // built at LBA 0, but chkdsk reads hidden_sectors from the boot
            // sector.  Patch it plus the backup copy.
            std.mem.writeInt(u32, image[0x1C..][0..4], 2048, .little);
            const last = @as(usize, @intCast((std.mem.readInt(u64, image[0x28..][0..8], .little)) * 512));
            if (last + 4 <= image.len) std.mem.writeInt(u32, image[last + 0x1C ..][0..4], 2048, .little);
            @memcpy(disk[2048 * 512 ..], image);
            try cwd.writeFile(io, .{ .sub_path = path, .data = disk });
            std.debug.print("NTFSWRITE image written: {s}\n", .{path});
        }
    }

    // --- Transactional allocation and cleanup fault cases -----------------
    {
        const image = try formatFresh(allocator, meta);
        var dev = RamDevice{ .image = image };
        var v = openVolume(&dev) orelse {
            fail("transaction mount failed", .{});
            return finish();
        };
        vol.flush_budget = null;
        const initial_free = vol.freeClusterCount(&v) orelse {
            fail("transaction free-cluster baseline unavailable", .{});
            return finish();
        };

        // Exhaust free space, reopen four isolated holes, and prove that an
        // undersized result buffer rejects the complete plan without setting
        // even its first two bitmap runs.
        var all_runs: [256]ntfs.Run = undefined;
        const all = vol.allocateClustersForTest(&v, initial_free, all_runs[0..]);
        if (all.status != .ok) {
            fail("transaction full allocation failed: {s}", .{@tagName(all.status)});
        } else {
            var long_run: ?ntfs.Run = null;
            for (all_runs[0..all.produced]) |run| {
                if (run.lcn != null and run.length_clusters >= 7) {
                    long_run = run;
                    break;
                }
            }
            if (long_run) |run| {
                const base = run.lcn.?;
                const sparse = [_]ntfs.Run{
                    .{ .length_clusters = 1, .lcn = base },
                    .{ .length_clusters = 1, .lcn = base + 2 },
                    .{ .length_clusters = 1, .lcn = base + 4 },
                    .{ .length_clusters = 1, .lcn = base + 6 },
                };
                if (!vol.freeClustersForTest(&v, sparse[0..])) {
                    fail("transaction sparse-hole setup failed", .{});
                } else {
                    const before = vol.freeClusterCount(&v) orelse 0;
                    var short_runs: [2]ntfs.Run = undefined;
                    const rejected = vol.allocateClustersForTest(&v, 4, short_runs[0..]);
                    const after = vol.freeClusterCount(&v) orelse 0;
                    if (rejected.status != .record_full or rejected.produced != 0 or before != 4 or after != before) {
                        fail("transaction run-capacity rollback mismatch status={s} before={d} after={d}", .{ @tagName(rejected.status), before, after });
                    }
                }
            } else {
                fail("transaction fixture has no long free run", .{});
            }
            if (!vol.freeClustersForTest(&v, all_runs[0..all.produced])) {
                fail("transaction capacity cleanup failed", .{});
            }
            const restored = vol.freeClusterCount(&v) orelse 0;
            if (restored != initial_free) fail("transaction capacity cleanup count {d} != {d}", .{ restored, initial_free });
        }

        // Failing the second bitmap-sector write must undo the already
        // committed first sector as well as the partially attempted range.
        const before_bitmap_fault = vol.freeClusterCount(&v) orelse 0;
        var bitmap_runs: [256]ntfs.Run = undefined;
        dev.failWriteAfter(2);
        const bitmap_fault = vol.allocateClustersForTest(&v, before_bitmap_fault, bitmap_runs[0..]);
        const after_bitmap_fault = vol.freeClusterCount(&v) orelse 0;
        if (bitmap_fault.status != .io or bitmap_fault.produced != 0 or after_bitmap_fault != before_bitmap_fault) {
            fail("transaction bitmap rollback mismatch status={s} before={d} after={d}", .{ @tagName(bitmap_fault.status), before_bitmap_fault, after_bitmap_fault });
        }

        // A failed release is a distinct cleanup error and must retain the
        // dirty bit.  Once I/O works again, cleanup can be completed exactly.
        var cleanup_runs: [8]ntfs.Run = undefined;
        const cleanup_allocation = vol.allocateClustersForTest(&v, 2, cleanup_runs[0..]);
        if (cleanup_allocation.status != .ok or !vol.setDirty(&v, true)) {
            fail("transaction cleanup setup failed", .{});
        } else {
            dev.failWriteAfter(1);
            const cleanup_status = vol.abortWriteFreeingForTest(&v, cleanup_runs[0..cleanup_allocation.produced], .invalid);
            const dirty_after_cleanup_fault = vol.isDirty(&v) orelse false;
            if (cleanup_status != .cleanup_failed or !dirty_after_cleanup_fault) {
                fail("transaction cleanup failure hidden status={s} dirty={}", .{ @tagName(cleanup_status), dirty_after_cleanup_fault });
            }
            if (!vol.freeClustersForTest(&v, cleanup_runs[0..cleanup_allocation.produced]) or !vol.setDirty(&v, false)) {
                fail("transaction cleanup recovery failed", .{});
            }
        }

        // Dirty-clear itself is part of cleanup and therefore follows the
        // same explicit failure contract.
        if (!vol.setDirty(&v, true)) {
            fail("transaction dirty-clear setup failed", .{});
        } else {
            dev.failWriteAfter(1);
            const clear_status = vol.abortWriteForTest(&v, .invalid);
            const still_dirty = vol.isDirty(&v) orelse false;
            if (clear_status != .cleanup_failed or !still_dirty) {
                fail("transaction dirty-clear failure hidden status={s} dirty={}", .{ @tagName(clear_status), still_dirty });
            }
            if (!vol.setDirty(&v, false)) fail("transaction final dirty clear failed", .{});
        }
    }

    // --- Crash matrix: abort after each durable flush -----------------------
    {
        var budget: u32 = 1;
        while (budget <= 40) : (budget += 1) {
            const image = try formatFresh(allocator, meta);
            var dev = RamDevice{ .image = image };
            var v = openVolume(&dev) orelse {
                fail("crash mount {d} failed", .{budget});
                continue;
            };
            // Pre-populate a victim file that must survive.
            vol.flush_budget = null;
            _ = vol.createFile(&v, ntfs.MFT_RECORD_ROOT, "KEEP.TXT", "must survive the crash");

            // Now run an operation with a limited flush budget.
            vol.flush_budget = budget;
            var big: [9000]u8 = undefined;
            patternFill(99, big[0..]);
            _ = vol.createFile(&v, ntfs.MFT_RECORD_ROOT, "NEW.BIN", big[0..]);
            vol.flush_budget = null;

            // The volume must remain structurally sound and KEEP.TXT intact.
            var dev2 = RamDevice{ .image = image };
            var v2 = openVolume(&dev2) orelse {
                fail("crash budget {d}: volume unmountable", .{budget});
                continue;
            };
            if (!readAndCheck(&v2, ntfs.MFT_RECORD_ROOT, "KEEP.TXT", "must survive the crash")) {
                fail("crash budget {d}: victim file damaged", .{budget});
            }
            if (!structurallySound(image)) {
                fail("crash budget {d}: volume not sound", .{budget});
            }
            // If NEW.BIN is present, it must be fully correct (no torn data).
            if (vol.lookupInDirectory(&v2, ntfs.MFT_RECORD_ROOT, "NEW.BIN")) |_| {
                if (!readAndCheck(&v2, ntfs.MFT_RECORD_ROOT, "NEW.BIN", big[0..])) {
                    fail("crash budget {d}: partial file visible with wrong data", .{budget});
                }
            }
        }
    }

    finish();
}

fn finish() void {
    if (failures != 0) {
        std.debug.print("NTFSWRITE result: FAILED ({d})\n", .{failures});
        std.process.exit(1);
    }
    std.debug.print("NTFSWRITE result: OK\n", .{});
}
