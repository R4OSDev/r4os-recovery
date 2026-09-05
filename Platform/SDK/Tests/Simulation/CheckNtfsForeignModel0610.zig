// Host model for foreign-volume completeness (0.60.10).
//
// Runs the REAL shared NTFS logic against the Windows-authored NTFS4K
// fixture: LZNT1-compressed content is read and hashed against the Windows
// manifest (both the compressible text and the stored-unit random file),
// the alternate data stream and the UTF-8 (umlaut) name resolve with exact
// content, and deleting one hard link keeps the record, the second name and
// the clusters alive (verified by NtfsVerify on the mutated image
// afterwards).  Reparse and EFS markers patched into a fresh R4OS-formatted
// volume must stay visible rejections.

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
var chunk: [65536]u8 = undefined;

fn fail(comptime fmt: []const u8, args: anytype) void {
    failures += 1;
    std.debug.print("FAIL: " ++ fmt ++ "\n", args);
}

fn partitionLba(image: []const u8) u32 {
    if (image.len < 512 or image[510] != 0x55 or image[511] != 0xAA) return 0;
    var slot: usize = 0;
    while (slot < 4) : (slot += 1) {
        const entry = image[446 + slot * 16 ..][0..16];
        if (entry[4] == 0x07) return std.mem.readInt(u32, entry[8..12], .little);
    }
    return 0;
}

fn openVolume(dev: *RamDevice, part_lba: u32) ?vol.Volume {
    const info = vol.mount(dev.device(), part_lba, &scratch, mft_runs[0..]) orelse return null;
    mft_run_count = info.mft_run_count;
    var v = vol.Volume{
        .device = dev.device(),
        .partition_lba = part_lba,
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

fn shaOfFile(v: *vol.Volume, record: u64, size: u64, out_hex: []u8) bool {
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    var offset: u64 = 0;
    while (offset < size) {
        const want: usize = @intCast(@min(size - offset, chunk.len));
        const got = vol.readFileRange(v, record, @intCast(offset), chunk[0..want]) orelse return false;
        if (got != want) return false;
        hasher.update(chunk[0..want]);
        offset += want;
    }
    var digest: [32]u8 = undefined;
    hasher.final(&digest);
    const hex = "0123456789abcdef";
    for (digest, 0..) |b, i| {
        out_hex[i * 2] = hex[b >> 4];
        out_hex[i * 2 + 1] = hex[b & 0xF];
    }
    return true;
}

fn eqlIgnoreCase(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |x, y| {
        if (std.ascii.toLower(x) != std.ascii.toLower(y)) return false;
    }
    return true;
}

fn readAll(v: *vol.Volume, record: u64, size: usize) ?[]const u8 {
    if (size > chunk.len) return null;
    const got = vol.readFileRange(v, record, 0, chunk[0..size]) orelse return null;
    if (got != size) return null;
    return chunk[0..size];
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;
    const cwd = std.Io.Dir.cwd();
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len < 4 or args.len > 6) {
        std.debug.print("Usage: CheckNtfsForeignModel0610 <ntfs4k-image> <compress-sha256> <random-sha256> [meta-dir] [mutated-out]\n", .{});
        std.process.exit(2);
    }
    const image_path = args[1];
    const compress_sha = args[2];
    const random_sha = args[3];
    const meta_path: ?[]const u8 = if (args.len >= 5) args[4] else null;
    const out_path: ?[]const u8 = if (args.len >= 6) args[5] else null;

    const image = try cwd.readFileAlloc(io, image_path, allocator, .limited(256 * 1024 * 1024));
    var dev = RamDevice{ .image = image };
    const part_lba = partitionLba(image);
    var v = openVolume(&dev, part_lba) orelse {
        fail("fixture mount failed", .{});
        return finish();
    };
    vol.flush_budget = null;

    // 1. LZNT1: compressible text content, byte-exact pattern + SHA256.
    {
        const found = vol.resolveEntry(&v, "COMP/COMPRESS.TXT") orelse {
            fail("COMPRESS.TXT unresolved", .{});
            return finish();
        };
        const line = "R4OS NTFS compression test line. ";
        const expected_size: u64 = line.len * 8192;
        if (found.entry.size != expected_size) fail("COMPRESS.TXT size {d} != {d}", .{ found.entry.size, expected_size });
        const head = readAll(&v, found.entry.record, 4096) orelse {
            fail("COMPRESS.TXT head read failed", .{});
            return finish();
        };
        var i: usize = 0;
        var pattern_ok = true;
        while (i < head.len) : (i += 1) {
            if (head[i] != line[i % line.len]) {
                pattern_ok = false;
                break;
            }
        }
        if (!pattern_ok) fail("COMPRESS.TXT pattern mismatch at {d}", .{i});
        var hex: [64]u8 = undefined;
        if (!shaOfFile(&v, found.entry.record, found.entry.size, hex[0..])) {
            fail("COMPRESS.TXT hash read failed", .{});
        } else if (!eqlIgnoreCase(hex[0..], compress_sha)) {
            fail("COMPRESS.TXT sha mismatch: {s}", .{hex[0..]});
        }
        std.debug.print("compressed: ok ({d} bytes)\n", .{found.entry.size});
    }

    // 2. Stored units: the incompressible random file hashes exactly.
    {
        const found = vol.resolveEntry(&v, "COMP/RANDOM.BIN") orelse {
            fail("RANDOM.BIN unresolved", .{});
            return finish();
        };
        var hex: [64]u8 = undefined;
        if (!shaOfFile(&v, found.entry.record, found.entry.size, hex[0..])) {
            fail("RANDOM.BIN hash read failed", .{});
        } else if (!eqlIgnoreCase(hex[0..], random_sha)) {
            fail("RANDOM.BIN sha mismatch: {s}", .{hex[0..]});
        }
        std.debug.print("stored-units: ok ({d} bytes)\n", .{found.entry.size});
    }

    // 3. Alternate data stream.
    {
        const found = vol.resolveEntry(&v, "ADSHOST.TXT") orelse {
            fail("ADSHOST.TXT unresolved", .{});
            return finish();
        };
        const primary = readAll(&v, found.entry.record, "primary stream".len) orelse {
            fail("ADS primary read failed", .{});
            return finish();
        };
        if (!std.mem.eql(u8, primary, "primary stream")) fail("ADS primary mismatch", .{});
        var ads_buf: [64]u8 = undefined;
        const got = vol.readNamedStreamRange(&v, found.entry.record, "SECOND", 0, ads_buf[0.."alternate stream payload".len]) orelse {
            fail("ADS SECOND read failed", .{});
            return finish();
        };
        if (got != "alternate stream payload".len or !std.mem.eql(u8, ads_buf[0..got], "alternate stream payload")) {
            fail("ADS SECOND mismatch", .{});
        }
        std.debug.print("ads: ok\n", .{});
    }

    // 4. UTF-8 (umlaut) name resolves with exact content.
    {
        const name = "Names With Long Components/Umlaute-\xc3\xa4\xc3\xb6\xc3\xbc.txt";
        const found = vol.resolveEntry(&v, name) orelse {
            fail("umlaut name unresolved", .{});
            return finish();
        };
        const payload = readAll(&v, found.entry.record, "utf16 name payload".len) orelse {
            fail("umlaut read failed", .{});
            return finish();
        };
        if (!std.mem.eql(u8, payload, "utf16 name payload")) fail("umlaut content mismatch", .{});
        std.debug.print("utf8-name: ok\n", .{});
    }

    // 4b. Windows metadata records stay hidden (0.60.13): the root listing
    //     carries no $-record and no "." self-entry, and name-based access
    //     to the system files reports not-found (delete included).
    {
        var listing: [16384]u8 = undefined;
        var sink = vol.EnumSink{ .out = listing[0..], .max_entries = 1024 };
        if (!vol.enumerateDirectory(&v, ntfs.MFT_RECORD_ROOT, &sink)) {
            fail("root listing failed", .{});
        } else {
            const text = listing[0..sink.cursor];
            var line_start: usize = 0;
            while (line_start < text.len) {
                const nl = std.mem.indexOfPos(u8, text, line_start, "\r\n") orelse text.len;
                var name = text[line_start..nl];
                while (name.len > 0 and name[0] == ' ') name = name[1..];
                if (std.mem.startsWith(u8, name, "<DIR>")) {
                    name = name["<DIR>".len..];
                    while (name.len > 0 and name[0] == ' ') name = name[1..];
                }
                if (name.len > 0) {
                    if (name[0] == '$') fail("metadata entry visible in root: {s}", .{name});
                    if (std.mem.eql(u8, name, ".")) fail("root self entry visible", .{});
                }
                line_start = if (nl == text.len) text.len else nl + 2;
            }
        }
        for ([_][]const u8{ "$MFT", "$Bitmap", "$LogFile", "$Extend" }) |sys_name| {
            if (vol.lookupInDirectory(&v, ntfs.MFT_RECORD_ROOT, sys_name) != null) {
                fail("system name resolvable: {s}", .{sys_name});
            }
            if (vol.resolveEntry(&v, sys_name) != null) {
                fail("system path resolvable: {s}", .{sys_name});
            }
        }
        if (vol.deleteFile(&v, ntfs.MFT_RECORD_ROOT, "$MFT") != .not_found) {
            fail("delete of $MFT not rejected as not_found", .{});
        }
        std.debug.print("metafiles: ok\n", .{});
    }

    // 5. Hard links: delete one name, the record and the other name survive.
    {
        const alt = vol.resolveEntry(&v, "LINKALT.BIN") orelse {
            fail("LINKALT unresolved", .{});
            return finish();
        };
        const tgt = vol.resolveEntry(&v, "LINKTGT.BIN") orelse {
            fail("LINKTGT unresolved", .{});
            return finish();
        };
        if (alt.entry.record != tgt.entry.record) fail("hardlink records differ", .{});
        const st = vol.deleteFile(&v, ntfs.MFT_RECORD_ROOT, "LINKALT.BIN");
        if (st != .ok) fail("hardlink delete failed: {s}", .{@tagName(st)});
        if (vol.resolveEntry(&v, "LINKALT.BIN") != null) fail("LINKALT still resolvable", .{});
        const tgt_after = vol.resolveEntry(&v, "LINKTGT.BIN") orelse {
            fail("LINKTGT lost after hardlink delete", .{});
            return finish();
        };
        const sample = readAll(&v, tgt_after.entry.record, @min(tgt_after.entry.size, 4096)) orelse {
            fail("LINKTGT unreadable after delete", .{});
            return finish();
        };
        _ = sample;
        std.debug.print("hardlink-delete: ok\n", .{});
    }

    if (out_path) |path| {
        try cwd.writeFile(io, .{ .sub_path = path, .data = image });
        std.debug.print("mutated fixture written: {s}\n", .{path});
    }

    // 6. Reparse and EFS markers stay visible rejections (synthetic patch on
    //    a fresh R4OS-formatted volume).
    if (meta_path) |mp| {
        var meta_dir = try cwd.openDir(io, mp, .{});
        defer meta_dir.close(io);
        const L = struct {
            fn req(a: std.mem.Allocator, i: anytype, d: std.Io.Dir, n: []const u8) ![]u8 {
                return d.readFileAlloc(i, n, a, .limited(1 << 20));
            }
            fn opt(a: std.mem.Allocator, i: anytype, d: std.Io.Dir, n: []const u8) []u8 {
                return d.readFileAlloc(i, n, a, .limited(1 << 20)) catch &[_]u8{};
            }
        };
        const meta = mkfs.Meta{
            .upcase = try L.req(allocator, io, meta_dir, "upcase.bin"),
            .upcase_info = L.opt(allocator, io, meta_dir, "upcase_info.bin"),
            .attrdef = try L.req(allocator, io, meta_dir, "attrdef.bin"),
            .sds_prefix = try L.req(allocator, io, meta_dir, "secure_sds_prefix.bin"),
            .sdh_root = try L.req(allocator, io, meta_dir, "secure_sdh_root.bin"),
            .sii_root = try L.req(allocator, io, meta_dir, "secure_sii_root.bin"),
            .sdh_alloc = try L.req(allocator, io, meta_dir, "secure_SDH_alloc.bin"),
            .sii_alloc = try L.req(allocator, io, meta_dir, "secure_SII_alloc.bin"),
            .sdh_bitmap = try L.req(allocator, io, meta_dir, "secure_SDH_bitmap.bin"),
            .sii_bitmap = try L.req(allocator, io, meta_dir, "secure_SII_bitmap.bin"),
            .objid_o_root = try L.req(allocator, io, meta_dir, "extend_objid_o_root.bin"),
            .quota_o_root = try L.req(allocator, io, meta_dir, "extend_quota_o_root.bin"),
            .quota_q_root = try L.req(allocator, io, meta_dir, "extend_quota_q_root.bin"),
            .reparse_r_root = try L.req(allocator, io, meta_dir, "extend_reparse_r_root.bin"),
            .root_sd = try L.req(allocator, io, meta_dir, "root_sd.bin"),
            .boot_sd = try L.req(allocator, io, meta_dir, "boot_sd.bin"),
        };
        var builder = try mkfs.Builder.init(allocator, 24 * 1024 * 1024, "R4OSFRGN", 0, meta, 132_000_000_000_000_000, 0x2610);
        const fresh = try builder.finalize();
        var dev2 = RamDevice{ .image = fresh };
        var v2 = openVolume(&dev2, 0) orelse {
            fail("fresh volume mount failed", .{});
            return finish();
        };
        const root = ntfs.MFT_RECORD_ROOT;
        _ = vol.createFile(&v2, root, "RP.TXT", "reparse target");
        _ = vol.createDirectory(&v2, root, "RPDIR");
        _ = vol.createFile(&v2, root, "EFS.TXT", "efs target");

        // Patch the reparse flag into the index entries of RP.TXT and
        // RPDIR, and the encrypted flag into EFS.TXT's $DATA header.
        patchRootIndexFlag(&v2, &dev2, "RP.TXT");
        patchRootIndexFlag(&v2, &dev2, "RPDIR");
        patchDataEncrypted(&v2, root, "EFS.TXT");

        const rp = vol.lookupInDirectory(&v2, root, "RP.TXT") orelse {
            fail("RP.TXT unresolved after patch", .{});
            return finish();
        };
        if (!rp.entry.reparse) fail("reparse flag not visible on file", .{});
        const rpdir = vol.lookupInDirectory(&v2, root, "RPDIR") orelse {
            fail("RPDIR unresolved after patch", .{});
            return finish();
        };
        if (!rpdir.entry.reparse) fail("reparse flag not visible on dir", .{});
        if (vol.resolvePath(&v2, "RPDIR") != null) fail("reparse dir traversal not rejected", .{});
        const efs = vol.lookupInDirectory(&v2, root, "EFS.TXT") orelse {
            fail("EFS.TXT unresolved after patch", .{});
            return finish();
        };
        var efs_buf: [16]u8 = undefined;
        if (vol.readFileRange(&v2, efs.record, 0, efs_buf[0..]) != null) {
            fail("encrypted read not rejected", .{});
        }
        std.debug.print("reparse-efs: ok\n", .{});
    }

    finish();
}

/// Sets FILE_ATTR_REPARSE in the FN duplicate flags of the index entry for
/// `name`: scans the resident root AND every $I30 INDX block (fresh
/// R4OS-formatted volumes carry the system names in allocation blocks).
fn patchRootIndexFlag(v: *vol.Volume, dev: *RamDevice, name: []const u8) void {
    var target16: [128]u8 = undefined;
    const tlen = ntfs.utf8ToUtf16(name, target16[0..]) orelse return;

    // Root record entries.
    if (vol.loadRecordForTest(v, ntfs.MFT_RECORD_ROOT)) |_| {
        const record = v.scratch.record[0..v.record_bytes];
        if (patchFnFlagInBuffer(record, target16[0..tlen])) {
            _ = vol.storeRecordForTest(v, ntfs.MFT_RECORD_ROOT);
        }
    }

    // $I30 allocation blocks of the root (raw image access with fixups).
    var alloc = vol.AttrScratch{};
    if (!vol.collectAttribute(v, ntfs.MFT_RECORD_ROOT, .index_allocation, &ntfs.I30_NAME_UTF16, &alloc)) return;
    if (alloc.resident) return;
    for (alloc.runs[0..alloc.count]) |run| {
        const lcn = run.lcn orelse continue;
        var cluster: u64 = 0;
        while (cluster < run.length_clusters) : (cluster += 1) {
            const offset: usize = @intCast((lcn + cluster) * v.cluster_bytes);
            if (offset + v.index_block_bytes > dev.image.len) continue;
            const block = dev.image[offset .. offset + v.index_block_bytes];
            if (std.mem.readInt(u32, block[0..4], .little) != ntfs.INDX_MAGIC) continue;
            if (ntfs.applyFixups(block) != .ok) continue;
            const changed = patchFnFlagInBuffer(block, target16[0..tlen]);
            const usn = std.mem.readInt(u16, block[std.mem.readInt(u16, block[4..6], .little)..][0..2], .little);
            _ = ntfs.installFixups(block, usn);
            _ = changed;
        }
    }
}

/// Raw scan for an FN value with the given UTF-16 name; ORs the reparse
/// flag into its duplicate attribute flags.  Returns true when patched.
fn patchFnFlagInBuffer(buf: []u8, target16: []const u8) bool {
    var patched = false;
    var offset: usize = 0;
    while (offset + 0x42 + target16.len <= buf.len) : (offset += 1) {
        const chars: usize = buf[offset + 0x40];
        if (chars * 2 != target16.len) continue;
        if (!std.mem.eql(u8, buf[offset + 0x42 .. offset + 0x42 + target16.len], target16)) continue;
        const flags = std.mem.readInt(u32, buf[offset + 0x38 ..][0..4], .little);
        std.mem.writeInt(u32, buf[offset + 0x38 ..][0..4], flags | ntfs.FILE_ATTR_REPARSE, .little);
        patched = true;
    }
    return patched;
}

/// Sets ATTR_FLAG_ENCRYPTED on the $DATA attribute header of a file record.
fn patchDataEncrypted(v: *vol.Volume, parent: u64, name: []const u8) void {
    const found = vol.lookupInDirectory(v, parent, name) orelse return;
    const header = vol.loadRecordForTest(v, found.record) orelse return;
    const record = v.scratch.record[0..v.record_bytes];
    var offset: usize = header.attrs_offset;
    while (offset + 8 <= record.len) {
        const t = std.mem.readInt(u32, record[offset..][0..4], .little);
        if (t == ntfs.END_MARKER) break;
        const length = std.mem.readInt(u32, record[offset + 4 ..][0..4], .little);
        if (length < 0x18 or offset + length > record.len) break;
        if (t == @intFromEnum(ntfs.AttrType.data)) {
            const flags = std.mem.readInt(u16, record[offset + 0x0C ..][0..2], .little);
            std.mem.writeInt(u16, record[offset + 0x0C ..][0..2], flags | ntfs.ATTR_FLAG_ENCRYPTED, .little);
            break;
        }
        offset += length;
    }
    _ = vol.storeRecordForTest(v, found.record);
}

fn finish() void {
    if (failures != 0) {
        std.debug.print("NTFSFOREIGN result: FAILED ({d})\n", .{failures});
        std.process.exit(1);
    }
    std.debug.print("NTFSFOREIGN result: OK\n", .{});
}
