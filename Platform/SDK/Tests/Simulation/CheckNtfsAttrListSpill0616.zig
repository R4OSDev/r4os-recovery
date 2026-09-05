// $ATTRIBUTE_LIST spill host model (0.60.16).
//
// Forces a non-resident $DATA runlist to grow past what a single 1-KB FILE
// record can hold, so the shared ntfs_volume write path must move $DATA into
// an extension record and install an $ATTRIBUTE_LIST in the base.  The model
// then verifies that:
//   - the spilled file reads back byte-exact through the read path (which
//     follows the $ATTRIBUTE_LIST into the extension record),
//   - further appends keep growing the runlist in the extension record,
//   - deletion frees both records and every cluster,
//   - the volume passes the strict NtfsVerify after the spill.
//
// Fragmentation is forced by interleaving the target file's appends with a
// second "spacer" file so the target's clusters never stay contiguous; each
// append is one cluster, which makes the runlist grow one fragment at a time.

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

fn formatFresh(allocator: std.mem.Allocator, meta: mkfs.Meta, size: usize) ![]u8 {
    var builder = try mkfs.Builder.init(allocator, size, "R4OSATTR", 0, meta, 132_000_000_000_000_000, 0x2616);
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
    var buf: [1 << 20]u8 = undefined;
    if (expected.len > buf.len) return false;
    const got = vol.readFileRange(v, found.record, 0, buf[0..expected.len]) orelse return false;
    if (got != expected.len) return false;
    return std.mem.eql(u8, buf[0..expected.len], expected);
}

fn freeClusterCount(v: *vol.Volume) u64 {
    return vol.freeClusterCount(v) orelse 0;
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;
    const cwd = std.Io.Dir.cwd();
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len < 2 or args.len > 3) {
        std.debug.print("Usage: CheckNtfsAttrListSpill0616 <meta-dir> [out-disk.img]\n", .{});
        std.process.exit(2);
    }
    const out_path: ?[]const u8 = if (args.len == 3) args[2] else null;
    var meta_dir = try cwd.openDir(io, args[1], .{});
    defer meta_dir.close(io);
    const meta = try loadMeta(allocator, io, meta_dir);

    const image = try formatFresh(allocator, meta, 48 * 1024 * 1024);
    defer allocator.free(image);
    var dev = RamDevice{ .image = image };
    var v = openVolume(&dev) orelse {
        fail("mount failed", .{});
        return finish();
    };
    vol.flush_budget = null;
    const root = ntfs.MFT_RECORD_ROOT;
    const cluster: usize = @intCast(v.cluster_bytes);

    const free_before = freeClusterCount(&v);

    // Build the model: BIG.BIN grows one cluster per step; between steps a
    // spacer file grabs a cluster so BIG.BIN fragments.  ~120 fragments far
    // exceeds a single 1-KB record's runlist capacity, forcing the spill.
    if (vol.createFile(&v, root, "BIG.BIN", "") != .ok) {
        fail("create BIG failed", .{});
        return finish();
    }
    if (vol.createFile(&v, root, "SPACER.BIN", "") != .ok) {
        fail("create SPACER failed", .{});
        return finish();
    }

    // Append one cluster to BIG.BIN per step, interleaving a spacer append
    // so BIG.BIN fragments, until the base record overflows and $DATA
    // spills into an extension record.  The read-back is checked before
    // and after the spill; the loop caps well above the expected threshold.
    const max_steps: usize = 400;
    var expected = std.ArrayList(u8).empty;
    defer expected.deinit(allocator);
    var spacer_expected = std.ArrayList(u8).empty;
    defer spacer_expected.deinit(allocator);
    const chunk = try allocator.alloc(u8, cluster);
    var step: usize = 0;
    var spilled_at: ?usize = null;
    while (step < max_steps) : (step += 1) {
        patternFill(@intCast(step + 100), chunk);
        const off = expected.items.len;
        try expected.appendSlice(allocator, chunk);
        const rc = vol.appendFileAtOffset(&v, root, "BIG.BIN", off, chunk);
        if (rc != .ok) {
            fail("BIG append step {d} failed: {s}", .{ step, @tagName(rc) });
            return finish();
        }
        // Spacer append to break contiguity.
        patternFill(@intCast(step + 5000), chunk);
        const soff = spacer_expected.items.len;
        try spacer_expected.appendSlice(allocator, chunk);
        if (vol.appendFileAtOffset(&v, root, "SPACER.BIN", soff, chunk) != .ok) {
            fail("SPACER append step {d} failed", .{step});
            return finish();
        }
        if (spilled_at == null and vol.dataResidesInExtension(&v, root, "BIG.BIN")) {
            spilled_at = step;
            // One more append after the spill exercises extension growth.
        }
        if (spilled_at) |at| {
            if (step >= at + 4) break;
        }
    }

    if (spilled_at == null) {
        fail("BIG.BIN never spilled within {d} fragments", .{max_steps});
        return finish();
    }
    std.debug.print("spill: ok (BIG.BIN $DATA in extension record after {d} fragments)\n", .{spilled_at.? + 1});

    // Read-back through the $ATTRIBUTE_LIST-following read path.
    if (!readAndCheck(&v, root, "BIG.BIN", expected.items)) fail("BIG readback mismatch after spill", .{});
    if (!readAndCheck(&v, root, "SPACER.BIN", spacer_expected.items)) fail("SPACER readback mismatch", .{});
    std.debug.print("spilled-read: ok ({d} bytes)\n", .{expected.items.len});

    // Remount to prove the spill is durable, then append more (grows the
    // runlist inside the extension record).
    var dev2 = RamDevice{ .image = image };
    var v2 = openVolume(&dev2) orelse {
        fail("remount failed", .{});
        return finish();
    };
    vol.flush_budget = null;
    if (!vol.dataResidesInExtension(&v2, root, "BIG.BIN")) fail("spill lost across remount", .{});
    var more: usize = 0;
    while (more < 8) : (more += 1) {
        patternFill(@intCast(more + 9000), chunk);
        const off = expected.items.len;
        try expected.appendSlice(allocator, chunk);
        const rc = vol.appendFileAtOffset(&v2, root, "BIG.BIN", off, chunk);
        if (rc != .ok) {
            fail("post-spill append {d} failed: {s}", .{ more, @tagName(rc) });
            return finish();
        }
    }
    if (!readAndCheck(&v2, root, "BIG.BIN", expected.items)) fail("BIG readback mismatch after post-spill appends", .{});
    std.debug.print("post-spill-append: ok ({d} bytes)\n", .{expected.items.len});

    // Windows-parity boundary (0.60.19): a 255-character name with mixed
    // ASCII/umlaut characters (255 UTF-16 units, 382 UTF-8 bytes) must
    // create, resolve and read back through the shared engine.  The file
    // stays on the image so Windows chkdsk validates the real record.
    {
        var long_name_buf: [510]u8 = undefined;
        var name_len: usize = 0;
        var ci: usize = 0;
        while (ci < 255) : (ci += 1) {
            if (ci % 2 == 0) {
                long_name_buf[name_len] = 'A' + @as(u8, @intCast(ci % 26));
                name_len += 1;
            } else {
                long_name_buf[name_len] = 0xC3;
                long_name_buf[name_len + 1] = 0xA4; // ä
                name_len += 2;
            }
        }
        const long_name = long_name_buf[0..name_len];
        if (vol.createFile(&v2, root, long_name, "grenzwert 255") != .ok) {
            fail("255-char name create failed", .{});
        } else if (vol.lookupInDirectory(&v2, root, long_name) == null) {
            fail("255-char name lookup failed", .{});
        } else if (!readAndCheck(&v2, root, long_name, "grenzwert 255")) {
            fail("255-char name readback failed", .{});
        } else {
            std.debug.print("longname-255: ok ({d} utf8 bytes)\n", .{name_len});
        }
    }

    if (out_path) |path| {
        const disk = try allocator.alloc(u8, 2048 * 512 + image.len);
        defer allocator.free(disk);
        @memset(disk[0 .. 2048 * 512], 0);
        std.mem.writeInt(u32, disk[0x1B8..][0..4], 0x52344F41, .little);
        disk[446 + 4] = 0x07;
        std.mem.writeInt(u32, disk[446 + 8 ..][0..4], 2048, .little);
        std.mem.writeInt(u32, disk[446 + 12 ..][0..4], @intCast(image.len / 512), .little);
        disk[510] = 0x55;
        disk[511] = 0xAA;
        std.mem.writeInt(u32, image[0x1C..][0..4], 2048, .little);
        const backup = @as(usize, @intCast(std.mem.readInt(u64, image[0x28..][0..8], .little) * 512));
        if (backup + 4 <= image.len) std.mem.writeInt(u32, image[backup + 0x1C ..][0..4], 2048, .little);
        @memcpy(disk[2048 * 512 ..], image);
        try cwd.writeFile(io, .{ .sub_path = path, .data = disk });
        std.debug.print("spill image written: {s}\n", .{path});

        // Negative twin for the verifier gate: corrupt the $FILE_NAME
        // attribute-list entry's instance id (the exact defect the first
        // chkdsk run found) and write it as <path>.badinst.img.  NtfsVerify
        // must reject that image.
        var bad_name_buf: [512]u8 = undefined;
        const bad_path = try std.fmt.bufPrint(bad_name_buf[0..], "{s}.badinst.img", .{path});
        var found_attr = false;
        var scan: usize = 2048 * 512;
        while (scan + 0x78 <= disk.len) : (scan += 8) {
            // Resident $ATTRIBUTE_LIST header: type 0x20, length 0x78,
            // non_resident 0; value at +0x18 starts with the $STANDARD_
            // INFORMATION entry (type 0x10) followed by $FILE_NAME (0x30).
            if (std.mem.readInt(u32, disk[scan..][0..4], .little) != 0x20) continue;
            if (std.mem.readInt(u32, disk[scan + 4 ..][0..4], .little) != 0x78) continue;
            if (disk[scan + 8] != 0) continue;
            if (std.mem.readInt(u32, disk[scan + 0x18 ..][0..4], .little) != 0x10) continue;
            if (std.mem.readInt(u32, disk[scan + 0x18 + 0x20 ..][0..4], .little) != 0x30) continue;
            const instance_at = scan + 0x18 + 0x20 + 0x18;
            // Never touch a fixup-protected position (last two bytes of a
            // 512-byte sector inside the record).
            if ((instance_at % 512) >= 510) {
                fail("negative twin: instance byte sits on a fixup position", .{});
                break;
            }
            disk[instance_at] ^= 0x55;
            found_attr = true;
            break;
        }
        if (!found_attr) {
            fail("negative twin: attribute list not found for corruption", .{});
        } else {
            try cwd.writeFile(io, .{ .sub_path = bad_path, .data = disk });
            std.debug.print("bad-instance image written: {s}\n", .{bad_path});
        }
    }

    // Delete both files: extension record and every cluster must return.
    if (vol.deleteFile(&v2, root, "BIG.BIN") != .ok) fail("delete BIG failed", .{});
    if (vol.deleteFile(&v2, root, "SPACER.BIN") != .ok) fail("delete SPACER failed", .{});
    if (vol.lookupInDirectory(&v2, root, "BIG.BIN") != null) fail("BIG still resolvable after delete", .{});

    const free_after = freeClusterCount(&v2);
    if (free_after != free_before) {
        fail("cluster leak after spill+delete: before={d} after={d}", .{ free_before, free_after });
    } else {
        std.debug.print("spill-delete: ok (clusters balanced at {d})\n", .{free_after});
    }

    return finish();
}

fn finish() void {
    if (failures != 0) {
        std.debug.print("NTFSATTRLIST result: FAILED ({d})\n", .{failures});
        std.process.exit(1);
    }
    std.debug.print("NTFSATTRLIST result: OK\n", .{});
}
