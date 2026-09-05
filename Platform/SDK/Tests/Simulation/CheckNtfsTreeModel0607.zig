// Host model for NTFS write phase 2 (0.60.7).
//
// Drives the REAL shared ntfs_volume tree engine against a RAM-backed
// device: a 1700-file directory forces root push-down, leaf and interior
// splits and MFT growth; full deletion exercises interior-entry replacement
// and empty-chain reclaim; mkdir/rmdir/rename cover the directory
// operations; an append ladder covers resident growth, the resident ->
// non-resident conversion, slack writes and cluster extension.  A seeded
// mixed churn keeps a shadow model and verifies every surviving file.  The
// crash matrix aborts splitting/mkdir/rename/append/delete operations after
// each durable flush and demands a mountable volume with the victim file
// intact.

const std = @import("std");
const ntfs = @import("ntfs_format");
const vol = @import("ntfs_volume");
const mkfs = @import("ntfs_mkfs");

// ---- RAM device ----------------------------------------------------------

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
    var builder = try mkfs.Builder.init(allocator, size, "R4OSTREE", 0, meta, 132_000_000_000_000_000, 0x2607);
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
    var buf: [262144]u8 = undefined;
    if (expected.len > buf.len) return false;
    const got = vol.readFileRange(v, found.record, 0, buf[0..expected.len]) orelse return false;
    if (got != expected.len) return false;
    return std.mem.eql(u8, buf[0..expected.len], expected);
}

fn countEntries(v: *vol.Volume, dir: u64) ?usize {
    var sink = vol.EnumSink{ .wanted = 10_000_000 };
    if (!vol.enumerateDirectory(v, dir, &sink)) return null;
    return sink.seen;
}

fn treeName(buf: []u8, i: usize) []const u8 {
    // Every third name is a long POSIX-namespace name for entry-size variance.
    if (i % 3 == 2) {
        return std.fmt.bufPrint(buf, "long_tree_stress_name_{d:0>4}.data", .{i}) catch unreachable;
    }
    return std.fmt.bufPrint(buf, "F{d:0>4}.TXT", .{i}) catch unreachable;
}

var phase_prefix: ?[]const u8 = null;

fn dumpPhase(allocator: std.mem.Allocator, io: anytype, cwd: std.Io.Dir, image: []const u8, label: []const u8) void {
    const prefix = phase_prefix orelse return;
    var path_buf: [512]u8 = undefined;
    const path = std.fmt.bufPrint(path_buf[0..], "{s}-{s}.disk.img", .{ prefix, label }) catch return;
    const disk = allocator.alloc(u8, 2048 * 512 + image.len) catch return;
    defer allocator.free(disk);
    @memset(disk[0 .. 2048 * 512], 0);
    std.mem.writeInt(u32, disk[0x1B8..][0..4], 0x52344F55, .little);
    disk[446 + 4] = 0x07;
    std.mem.writeInt(u32, disk[446 + 8 ..][0..4], 2048, .little);
    std.mem.writeInt(u32, disk[446 + 12 ..][0..4], @intCast(image.len / 512), .little);
    disk[510] = 0x55;
    disk[511] = 0xAA;
    const patched = allocator.dupe(u8, image) catch return;
    defer allocator.free(patched);
    std.mem.writeInt(u32, patched[0x1C..][0..4], 2048, .little);
    const backup = @as(usize, @intCast(std.mem.readInt(u64, patched[0x28..][0..8], .little) * 512));
    if (backup + 4 <= patched.len) std.mem.writeInt(u32, patched[backup + 0x1C ..][0..4], 2048, .little);
    @memcpy(disk[2048 * 512 ..], patched);
    cwd.writeFile(io, .{ .sub_path = path, .data = disk }) catch return;
    std.debug.print("phase image written: {s}\n", .{path});
}

// ---- big-directory test ---------------------------------------------------

const TREE_FILES: usize = 1700;

fn runBigDirectory(allocator: std.mem.Allocator, meta: mkfs.Meta, io: anytype, cwd: std.Io.Dir) !void {
    const image = try formatFresh(allocator, meta, 48 * 1024 * 1024);
    defer allocator.free(image);
    var dev = RamDevice{ .image = image };
    var v = openVolume(&dev) orelse return fail("bigdir: mount failed", .{});
    vol.flush_budget = null;
    const root = ntfs.MFT_RECORD_ROOT;

    if (vol.createDirectory(&v, root, "BIGDIR") != .ok) return fail("bigdir: mkdir failed", .{});
    const dir = (vol.lookupInDirectory(&v, root, "BIGDIR") orelse return fail("bigdir: lookup failed", .{})).record;

    var name_buf: [64]u8 = undefined;
    var content: [96]u8 = undefined;
    var i: usize = 0;
    while (i < TREE_FILES) : (i += 1) {
        const n = treeName(name_buf[0..], i);
        patternFill(@intCast(i + 11), content[0..]);
        const rc = vol.createFile(&v, dir, n, content[0..]);
        if (rc != .ok) return fail("bigdir: create {d} failed: {s}", .{ i, @tagName(rc) });
    }
    if (countEntries(&v, dir) != TREE_FILES) fail("bigdir: enumeration count mismatch", .{});
    dumpPhase(allocator, io, cwd, image, "A-created");

    // Spot-check contents across the tree.
    i = 0;
    while (i < TREE_FILES) : (i += 97) {
        const n = treeName(name_buf[0..], i);
        patternFill(@intCast(i + 11), content[0..]);
        if (!readAndCheck(&v, dir, n, content[0..])) fail("bigdir: readback {d} mismatch", .{i});
    }

    // Delete every other file (hits interior entries), then verify.
    i = 0;
    while (i < TREE_FILES) : (i += 2) {
        const n = treeName(name_buf[0..], i);
        const rc = vol.deleteFile(&v, dir, n);
        if (rc != .ok) fail("bigdir: delete {d} failed: {s}", .{ i, @tagName(rc) });
    }
    if (countEntries(&v, dir) != TREE_FILES / 2) fail("bigdir: count after half-delete mismatch", .{});
    dumpPhase(allocator, io, cwd, image, "B-halfdel");
    i = 1;
    while (i < TREE_FILES) : (i += 193) {
        const odd = if (i % 2 == 0) i + 1 else i;
        if (odd >= TREE_FILES) break;
        const n = treeName(name_buf[0..], odd);
        patternFill(@intCast(odd + 11), content[0..]);
        if (!readAndCheck(&v, dir, n, content[0..])) fail("bigdir: survivor {d} mismatch", .{odd});
    }

    // Delete the rest; directory must be empty and removable.
    i = 1;
    while (i < TREE_FILES) : (i += 2) {
        const n = treeName(name_buf[0..], i);
        const rc = vol.deleteFile(&v, dir, n);
        if (rc != .ok) fail("bigdir: delete2 {d} failed: {s}", .{ i, @tagName(rc) });
    }
    if (countEntries(&v, dir) != 0) fail("bigdir: not empty after full delete", .{});
    if (vol.deleteDirectory(&v, root, "BIGDIR") != .ok) fail("bigdir: rmdir failed", .{});
    if (vol.lookupInDirectory(&v, root, "BIGDIR") != null) fail("bigdir: dir still present", .{});
    std.debug.print("bigdir: ok ({d} files, splits + interior deletes + mft growth)\n", .{TREE_FILES});
}

// ---- directory-operation tests --------------------------------------------

fn runDirOps(allocator: std.mem.Allocator, meta: mkfs.Meta, io: anytype, cwd: std.Io.Dir) !void {
    const image = try formatFresh(allocator, meta, 24 * 1024 * 1024);
    defer allocator.free(image);
    var dev = RamDevice{ .image = image };
    var v = openVolume(&dev) orelse return fail("dirops: mount failed", .{});
    vol.flush_budget = null;
    const root = ntfs.MFT_RECORD_ROOT;

    // Nested tree.
    if (vol.createDirectory(&v, root, "A") != .ok) return fail("dirops: mkdir A", .{});
    const a = (vol.lookupInDirectory(&v, root, "A") orelse return fail("dirops: lookup A", .{})).record;
    if (vol.createDirectory(&v, a, "B") != .ok) return fail("dirops: mkdir B", .{});
    const b = (vol.lookupInDirectory(&v, a, "B") orelse return fail("dirops: lookup B", .{})).record;
    if (vol.createDirectory(&v, b, "C") != .ok) return fail("dirops: mkdir C", .{});
    const c = (vol.lookupInDirectory(&v, b, "C") orelse return fail("dirops: lookup C", .{})).record;

    if (vol.createFile(&v, c, "DEEP.TXT", "deep content") != .ok) fail("dirops: create deep", .{});
    if (vol.resolvePath(&v, "A\\B\\C") != c) fail("dirops: resolvePath mismatch", .{});

    // Duplicate/collision handling.
    if (vol.createDirectory(&v, root, "A") != .exists) fail("dirops: duplicate mkdir not rejected", .{});
    if (vol.createFile(&v, root, "A", "x") != .exists) fail("dirops: file over dir not rejected", .{});

    // rmdir constraints.
    if (vol.deleteDirectory(&v, root, "A") != .not_empty) fail("dirops: non-empty rmdir not rejected", .{});
    if (vol.deleteDirectory(&v, c, "DEEP.TXT") != .not_directory) fail("dirops: rmdir on file not rejected", .{});
    if (vol.deleteFile(&v, b, "C") != .directory) fail("dirops: delete on dir not rejected", .{});

    dumpPhase(allocator, io, cwd, image, "C-dirops-pre-rename");

    // Same-directory rename.
    if (vol.renameEntry(&v, c, "DEEP.TXT", c, "RENAMED.TXT") != .ok) fail("dirops: rename failed", .{});
    if (vol.lookupInDirectory(&v, c, "DEEP.TXT") != null) fail("dirops: old name still there", .{});
    if (!readAndCheck(&v, c, "RENAMED.TXT", "deep content")) fail("dirops: renamed readback", .{});

    // Cross-directory move (file and directory).
    if (vol.renameEntry(&v, c, "RENAMED.TXT", a, "MOVED.TXT") != .ok) fail("dirops: move file failed", .{});
    if (!readAndCheck(&v, a, "MOVED.TXT", "deep content")) fail("dirops: moved readback", .{});
    if (vol.renameEntry(&v, b, "C", root, "CTOP") != .ok) fail("dirops: move dir failed", .{});
    const ctop = (vol.lookupInDirectory(&v, root, "CTOP") orelse return fail("dirops: lookup CTOP", .{})).record;
    if (ctop != c) fail("dirops: moved dir record changed", .{});

    // Rename collision.
    if (vol.renameEntry(&v, a, "MOVED.TXT", root, "CTOP") != .exists) fail("dirops: rename collision not rejected", .{});
    dumpPhase(allocator, io, cwd, image, "D-dirops-renamed");

    // Cleanup bottom-up.
    if (vol.deleteFile(&v, a, "MOVED.TXT") != .ok) fail("dirops: cleanup file", .{});
    if (vol.deleteDirectory(&v, root, "CTOP") != .ok) fail("dirops: rmdir CTOP", .{});
    if (vol.deleteDirectory(&v, a, "B") != .ok) fail("dirops: rmdir B", .{});
    if (vol.deleteDirectory(&v, root, "A") != .ok) fail("dirops: rmdir A", .{});
    std.debug.print("dirops: ok\n", .{});
}

// ---- append ladder ---------------------------------------------------------

fn runAppendLadder(allocator: std.mem.Allocator, meta: mkfs.Meta, io: anytype, cwd: std.Io.Dir) !void {
    const image = try formatFresh(allocator, meta, 24 * 1024 * 1024);
    defer allocator.free(image);
    var dev = RamDevice{ .image = image };
    var v = openVolume(&dev) orelse return fail("append: mount failed", .{});
    vol.flush_budget = null;
    const root = ntfs.MFT_RECORD_ROOT;

    var expected = std.ArrayList(u8).empty;
    defer expected.deinit(allocator);

    // Stage sizes walk through: resident growth, resident->non-resident
    // conversion, slack write, single- and multi-cluster extension.
    const stages = [_]usize{ 100, 400, 300, 3000, 5000, 60000, 140000 };
    if (vol.createFile(&v, root, "LADDER.BIN", "") != .ok) return fail("append: create empty", .{});
    var chunk: [140000]u8 = undefined;
    for (stages, 0..) |stage, si| {
        patternFill(@intCast(si + 21), chunk[0..stage]);
        const offset = expected.items.len;
        try expected.appendSlice(allocator, chunk[0..stage]);
        const rc = vol.appendFileAtOffset(&v, root, "LADDER.BIN", offset, chunk[0..stage]);
        if (rc != .ok) return fail("append: stage {d} ({d} bytes) failed: {s}", .{ si, stage, @tagName(rc) });
        if (!readAndCheck(&v, root, "LADDER.BIN", expected.items)) {
            fail("append: stage {d} readback mismatch (total {d})", .{ si, expected.items.len });
        }
    }
    if (vol.appendFileAtOffset(&v, root, "LADDER.BIN", 1, "x") != .offset_mismatch) {
        fail("append: offset guard missing", .{});
    }
    dumpPhase(allocator, io, cwd, image, "E-append");
    std.debug.print("append: ok ({d} bytes final)\n", .{expected.items.len});
}

// ---- mixed churn with shadow model ----------------------------------------

const ShadowFile = struct {
    dir: u8, // index into dirs
    name: [40]u8,
    name_len: usize,
    seed: u32,
    len: usize,
};

fn runChurn(allocator: std.mem.Allocator, meta: mkfs.Meta, out_path: ?[]const u8, io: anytype, cwd: std.Io.Dir) !void {
    const image = try formatFresh(allocator, meta, 48 * 1024 * 1024);
    defer allocator.free(image);
    var dev = RamDevice{ .image = image };
    var v = openVolume(&dev) orelse return fail("churn: mount failed", .{});
    vol.flush_budget = null;
    const root = ntfs.MFT_RECORD_ROOT;

    const dir_names = [_][]const u8{ "CHURN0", "CHURN1", "CHURN2", "CHURN3" };
    var dirs: [4]u64 = undefined;
    for (dir_names, 0..) |dn, di| {
        if (vol.createDirectory(&v, root, dn) != .ok) return fail("churn: mkdir {s}", .{dn});
        dirs[di] = (vol.lookupInDirectory(&v, root, dn) orelse return fail("churn: lookup {s}", .{dn})).record;
    }

    var shadow = std.ArrayList(ShadowFile).empty;
    defer shadow.deinit(allocator);
    var rng: u32 = 0x2607;
    var next_id: usize = 0;
    var content: [4096]u8 = undefined;
    var ops: usize = 0;
    while (ops < 2000) : (ops += 1) {
        rng ^= rng << 13;
        rng ^= rng >> 17;
        rng ^= rng << 5;
        const action = rng % 100;
        if (action < 45 or shadow.items.len == 0) {
            // Create.
            var sf = ShadowFile{ .dir = @intCast(rng % 4), .name = undefined, .name_len = 0, .seed = rng, .len = @intCast(rng % 2048) };
            const n = std.fmt.bufPrint(sf.name[0..], "CH{d:0>5}.DAT", .{next_id}) catch unreachable;
            sf.name_len = n.len;
            next_id += 1;
            patternFill(sf.seed, content[0..sf.len]);
            const rc = vol.createFile(&v, dirs[sf.dir], n, content[0..sf.len]);
            if (rc != .ok) return fail("churn: create op {d} failed: {s}", .{ ops, @tagName(rc) });
            try shadow.append(allocator, sf);
        } else if (action < 70) {
            // Delete a random shadow file.
            const idx = rng % @as(u32, @intCast(shadow.items.len));
            const sf = shadow.items[idx];
            const rc = vol.deleteFile(&v, dirs[sf.dir], sf.name[0..sf.name_len]);
            if (rc != .ok) return fail("churn: delete op {d} failed: {s}", .{ ops, @tagName(rc) });
            _ = shadow.swapRemove(idx);
        } else if (action < 85) {
            // Rename/move a random file.
            const idx = rng % @as(u32, @intCast(shadow.items.len));
            var sf = &shadow.items[idx];
            const new_dir: u8 = @intCast((rng >> 8) % 4);
            var new_name: [40]u8 = undefined;
            const n = std.fmt.bufPrint(new_name[0..], "CH{d:0>5}.DAT", .{next_id}) catch unreachable;
            next_id += 1;
            const rc = vol.renameEntry(&v, dirs[sf.dir], sf.name[0..sf.name_len], dirs[new_dir], n);
            if (rc != .ok) return fail("churn: rename op {d} failed: {s}", .{ ops, @tagName(rc) });
            sf.dir = new_dir;
            @memcpy(sf.name[0..n.len], n);
            sf.name_len = n.len;
        } else {
            // Append to a random file.
            const idx = rng % @as(u32, @intCast(shadow.items.len));
            var sf = &shadow.items[idx];
            const add: usize = @intCast((rng >> 4) % 1024 + 1);
            if (sf.len + add > content.len) continue;
            patternFill(sf.seed, content[0 .. sf.len + add]);
            const rc = vol.appendFileAtOffset(&v, dirs[sf.dir], sf.name[0..sf.name_len], sf.len, content[sf.len .. sf.len + add]);
            if (rc != .ok) return fail("churn: append op {d} failed: {s}", .{ ops, @tagName(rc) });
            sf.len += add;
        }
    }

    // Verify the complete shadow set.
    var per_dir: [4]usize = .{ 0, 0, 0, 0 };
    for (shadow.items) |sf| {
        per_dir[sf.dir] += 1;
        patternFill(sf.seed, content[0..sf.len]);
        if (!readAndCheck(&v, dirs[sf.dir], sf.name[0..sf.name_len], content[0..sf.len])) {
            fail("churn: final readback mismatch for {s}", .{sf.name[0..sf.name_len]});
        }
    }
    for (dirs, 0..) |d, di| {
        if (countEntries(&v, d) != per_dir[di]) fail("churn: dir {d} count mismatch", .{di});
    }
    std.debug.print("churn: ok ({d} ops, {d} surviving files)\n", .{ ops, shadow.items.len });

    // Dump the churn image (MBR-wrapped) for external NtfsVerify/chkdsk.
    if (out_path) |path| {
        const disk = try allocator.alloc(u8, 2048 * 512 + image.len);
        defer allocator.free(disk);
        @memset(disk[0 .. 2048 * 512], 0);
        std.mem.writeInt(u32, disk[0x1B8..][0..4], 0x52344F54, .little);
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
        std.debug.print("churn image written: {s}\n", .{path});
    }
}

// ---- crash matrix ----------------------------------------------------------

fn structurallySound(image: []u8) bool {
    var dev = RamDevice{ .image = image };
    var v = openVolume(&dev) orelse return false;
    var sink = vol.EnumSink{ .wanted = 10_000_000 };
    return vol.enumerateDirectory(&v, ntfs.MFT_RECORD_ROOT, &sink) and !sink.failed;
}

fn runCrashMatrix(allocator: std.mem.Allocator, meta: mkfs.Meta) !void {
    const ops = [_][]const u8{ "split-create", "mkdir", "rename", "append-grow", "delete" };
    for (ops) |op| {
        var budget: u32 = 1;
        while (budget <= 40) : (budget += 1) {
            const image = try formatFresh(allocator, meta, 24 * 1024 * 1024);
            defer allocator.free(image);
            var dev = RamDevice{ .image = image };
            var v = openVolume(&dev) orelse {
                fail("crash {s}: mount failed", .{op});
                continue;
            };
            vol.flush_budget = null;
            const root = ntfs.MFT_RECORD_ROOT;

            // Victim + preparation.
            _ = vol.createFile(&v, root, "KEEP.TXT", "must survive the crash");
            _ = vol.createDirectory(&v, root, "WORK");
            const work = (vol.lookupInDirectory(&v, root, "WORK") orelse continue).record;
            var name_buf: [48]u8 = undefined;
            var content: [128]u8 = undefined;
            if (std.mem.eql(u8, op, "split-create") or std.mem.eql(u8, op, "delete")) {
                // Fill toward a leaf split.
                var i: usize = 0;
                while (i < 60) : (i += 1) {
                    const n = std.fmt.bufPrint(name_buf[0..], "P{d:0>4}.DAT", .{i}) catch unreachable;
                    patternFill(@intCast(i + 5), content[0..]);
                    _ = vol.createFile(&v, work, n, content[0..]);
                }
            }
            if (std.mem.eql(u8, op, "append-grow")) {
                patternFill(9, content[0..]);
                _ = vol.createFile(&v, work, "GROW.BIN", content[0..]);
            }

            vol.flush_budget = budget;
            if (std.mem.eql(u8, op, "split-create")) {
                patternFill(99, content[0..]);
                _ = vol.createFile(&v, work, "PXXXX.NEW", content[0..]);
            } else if (std.mem.eql(u8, op, "mkdir")) {
                _ = vol.createDirectory(&v, work, "SUB");
            } else if (std.mem.eql(u8, op, "rename")) {
                _ = vol.renameEntry(&v, root, "KEEP2.TXT", root, "KEEP3.TXT");
                _ = vol.createFile(&v, work, "RN.TXT", "rename me");
                _ = vol.renameEntry(&v, work, "RN.TXT", root, "RENAMED.TXT");
            } else if (std.mem.eql(u8, op, "append-grow")) {
                var big: [20000]u8 = undefined;
                patternFill(9, big[0..]);
                _ = vol.appendFileAtOffset(&v, work, "GROW.BIN", content.len, big[content.len..]);
            } else {
                _ = vol.deleteFile(&v, work, "P0030.DAT");
            }
            vol.flush_budget = null;

            // The volume must stay mountable with the victim intact.
            var dev2 = RamDevice{ .image = image };
            var v2 = openVolume(&dev2) orelse {
                fail("crash {s} budget {d}: unmountable", .{ op, budget });
                continue;
            };
            if (!readAndCheck(&v2, root, "KEEP.TXT", "must survive the crash")) {
                fail("crash {s} budget {d}: victim damaged", .{ op, budget });
            }
            if (!structurallySound(image)) {
                fail("crash {s} budget {d}: volume not sound", .{ op, budget });
            }
        }
    }
    std.debug.print("crash matrix: ok (5 ops x 40 budgets)\n", .{});
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;
    const cwd = std.Io.Dir.cwd();
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len < 2 or args.len > 4) {
        std.debug.print("Usage: CheckNtfsTreeModel0607 <meta-dir> [out-churn-disk.img] [phase-prefix]\n", .{});
        std.process.exit(2);
    }
    const out_path: ?[]const u8 = if (args.len >= 3) args[2] else null;
    if (args.len == 4) phase_prefix = args[3];
    var meta_dir = try cwd.openDir(io, args[1], .{});
    defer meta_dir.close(io);
    const meta = try loadMeta(allocator, io, meta_dir);

    try runBigDirectory(allocator, meta, io, cwd);
    try runDirOps(allocator, meta, io, cwd);
    try runAppendLadder(allocator, meta, io, cwd);
    try runChurn(allocator, meta, out_path, io, cwd);
    try runCrashMatrix(allocator, meta);

    if (failures != 0) {
        std.debug.print("NTFSTREE result: FAILED ({d})\n", .{failures});
        std.process.exit(1);
    }
    std.debug.print("NTFSTREE result: OK\n", .{});
}
