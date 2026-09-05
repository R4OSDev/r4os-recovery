// Sparse-write host model (0.60.17).
//
// Runs the REAL shared ntfs_volume write path against the Windows-authored
// NTFS4K fixture volume and its genuine sparse file SPARSE.BIN (2 MB,
// Windows attribute SparseFile):
//   - locates a real hole and a real mapped region from the runlist,
//   - writes a pattern into the hole (allocate + split + zero slop) and
//     into the mapped region (plain in-place),
//   - verifies the whole file byte-exact against the expected image
//     (untouched holes still read zeros, neighbours of the patched range
//     keep their zeros),
//   - appends to the sparse file (initialized_size/data_size growth),
//   - remounts to prove durability and re-reads everything,
//   - runs a crash sweep over the hole-fill write (flush budgets) and
//     requires the volume to stay mountable with old-or-new content.
//
// The mutated fixture image is written out for NtfsVerify + Windows chkdsk.

const std = @import("std");
const ntfs = @import("ntfs_format");
const vol = @import("ntfs_volume");

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

fn partitionLba(image: []const u8) u32 {
    if (image.len < 512 or image[510] != 0x55 or image[511] != 0xAA) return 0;
    var slot: usize = 0;
    while (slot < 4) : (slot += 1) {
        const entry = image[446 + slot * 16 ..][0..16];
        if (entry[4] == 0x07) return std.mem.readInt(u32, entry[8..12], .little);
    }
    return 0;
}

fn openVolume(dev: *RamDevice) ?vol.Volume {
    const part_lba = partitionLba(dev.image);
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
        .now_filetime = 132_200_000_000_000_000,
    };
    const got = vol.readFileRange(&v, ntfs.MFT_RECORD_UPCASE, 0, upcase_buf[0..]) orelse return null;
    if (got != ntfs.UPCASE_BYTES) return null;
    v.upcase = upcase_buf[0..];
    return v;
}

const SparseLayout = struct {
    record: u64,
    data_size: u64,
    initialized_size: u64,
    hole_offset: u64, // byte offset of the first hole
    hole_len: u64,
    mapped_offset: u64, // byte offset of some mapped region
};

fn inspectSparse(v: *vol.Volume, name: []const u8) ?SparseLayout {
    const found = vol.lookupInDirectory(v, ntfs.MFT_RECORD_ROOT, name) orelse return null;
    const attr = vol.collectAttributeForTest(v, found.record) orelse return null;
    if ((attr.flags & ntfs.ATTR_FLAG_SPARSE) == 0) return null;
    var layout = SparseLayout{
        .record = found.record,
        .data_size = attr.data_size,
        .initialized_size = attr.initialized_size,
        .hole_offset = 0,
        .hole_len = 0,
        .mapped_offset = 0,
    };
    const cluster = v.cluster_bytes;
    var run_start: u64 = 0;
    var have_hole = false;
    var have_mapped = false;
    for (attr.runs[0..attr.count]) |run| {
        const run_bytes = run.length_clusters * cluster;
        if (run.lcn == null and !have_hole and run_bytes >= 2 * cluster) {
            layout.hole_offset = run_start;
            layout.hole_len = run_bytes;
            have_hole = true;
        }
        if (run.lcn != null and !have_mapped) {
            layout.mapped_offset = run_start;
            have_mapped = true;
        }
        run_start += run_bytes;
    }
    if (!have_hole or !have_mapped) return null;
    return layout;
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

var file_buf: [4 * 1024 * 1024]u8 = undefined;

fn readWhole(v: *vol.Volume, record: u64, size: u64) ?[]u8 {
    if (size > file_buf.len) return null;
    const got = vol.readFileRange(v, record, 0, file_buf[0..@intCast(size)]) orelse return null;
    if (got != size) return null;
    return file_buf[0..@intCast(size)];
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;
    const cwd = std.Io.Dir.cwd();
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len < 3 or args.len > 4) {
        std.debug.print("Usage: CheckNtfsSparseWrite0617 <NTFS4K.img> <sparse-sha256> [out-disk.img]\n", .{});
        std.process.exit(2);
    }
    const out_path: ?[]const u8 = if (args.len == 4) args[3] else null;

    const image = try cwd.readFileAlloc(io, args[1], allocator, .limited(256 * 1024 * 1024));
    var dev = RamDevice{ .image = image };
    var v = openVolume(&dev) orelse {
        fail("mount failed", .{});
        return finish();
    };
    vol.flush_budget = null;

    // Baseline: SPARSE.BIN must match the Windows manifest SHA256.
    var layout = inspectSparse(&v, "SPARSE.BIN") orelse {
        fail("SPARSE.BIN not found or not sparse/mapped as expected", .{});
        return finish();
    };
    std.debug.print("layout: size={d} init={d} hole@{d}+{d} mapped@{d}\n", .{ layout.data_size, layout.initialized_size, layout.hole_offset, layout.hole_len, layout.mapped_offset });
    const before = readWhole(&v, layout.record, layout.data_size) orelse {
        fail("baseline read failed", .{});
        return finish();
    };
    var sha_buf: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(before, &sha_buf, .{});
    var sha_hex: [64]u8 = undefined;
    for (sha_buf, 0..) |b, i| _ = std.fmt.bufPrint(sha_hex[i * 2 ..][0..2], "{X:0>2}", .{b}) catch unreachable;
    if (!std.ascii.eqlIgnoreCase(sha_hex[0..], args[2])) {
        fail("baseline SHA mismatch: got {s}", .{sha_hex[0..]});
        return finish();
    }
    var expected = try allocator.alloc(u8, @intCast(layout.data_size));
    @memcpy(expected, before);

    // 1. Write into the middle of a real hole, not cluster-aligned, so the
    //    slop inside the freshly mapped clusters must read back as zeros.
    var patch: [5000]u8 = undefined;
    patternFill(0x617, patch[0..]);
    const hole_write_at = layout.hole_offset + 777;
    {
        const rc = vol.writeFileAt(&v, layout.record, hole_write_at, patch[0..]);
        if (rc != .ok) {
            fail("hole write failed: {s}", .{@tagName(rc)});
            return finish();
        }
        @memcpy(expected[@intCast(hole_write_at)..][0..patch.len], patch[0..]);
    }

    // 2. Plain in-place write into a mapped region (fast path).
    var patch2: [2048]u8 = undefined;
    patternFill(0x1617, patch2[0..]);
    const mapped_write_at = layout.mapped_offset + 123;
    {
        const rc = vol.writeFileAt(&v, layout.record, mapped_write_at, patch2[0..]);
        if (rc != .ok) {
            fail("mapped write failed: {s}", .{@tagName(rc)});
            return finish();
        }
        @memcpy(expected[@intCast(mapped_write_at)..][0..patch2.len], patch2[0..]);
    }

    // Full byte-exact compare: patches visible, untouched holes still zero.
    {
        const now = readWhole(&v, layout.record, layout.data_size) orelse {
            fail("post-write read failed", .{});
            return finish();
        };
        if (!std.mem.eql(u8, now, expected)) fail("content mismatch after hole+mapped writes", .{});
        const after = inspectSparse(&v, "SPARSE.BIN") orelse {
            fail("SPARSE.BIN lost sparse flag after writes", .{});
            return finish();
        };
        if (after.data_size != layout.data_size) fail("data_size changed by in-place writes", .{});
        std.debug.print("hole-write: ok (offset {d}, {d} bytes, still sparse)\n", .{ hole_write_at, patch.len });
    }

    // 3. Append to the sparse file.
    var tail: [3000]u8 = undefined;
    patternFill(0x2617, tail[0..]);
    {
        const rc = vol.appendFileAtOffset(&v, ntfs.MFT_RECORD_ROOT, "SPARSE.BIN", layout.data_size, tail[0..]);
        if (rc != .ok) {
            fail("sparse append failed: {s}", .{@tagName(rc)});
            return finish();
        }
        const new_size = layout.data_size + tail.len;
        const grown = try allocator.alloc(u8, @intCast(new_size));
        @memcpy(grown[0..expected.len], expected);
        @memcpy(grown[expected.len..], tail[0..]);
        expected = grown;
        layout.data_size = new_size;
        std.debug.print("sparse-append: ok (new size {d})\n", .{new_size});
    }

    // 4. Remount: everything must be durable.
    var dev2 = RamDevice{ .image = image };
    var v2 = openVolume(&dev2) orelse {
        fail("remount failed", .{});
        return finish();
    };
    vol.flush_budget = null;
    {
        const found = vol.lookupInDirectory(&v2, ntfs.MFT_RECORD_ROOT, "SPARSE.BIN") orelse {
            fail("SPARSE.BIN lost after remount", .{});
            return finish();
        };
        const now = readWhole(&v2, found.record, layout.data_size) orelse {
            fail("remount read failed", .{});
            return finish();
        };
        if (!std.mem.eql(u8, now, expected)) fail("content mismatch after remount", .{});
        std.debug.print("remount-read: ok ({d} bytes)\n", .{layout.data_size});
    }

    if (out_path) |path| {
        try cwd.writeFile(io, .{ .sub_path = path, .data = image });
        std.debug.print("mutated sparse image written: {s}\n", .{path});
    }

    // 5. Crash sweep over a fresh hole write: for every flush budget the
    //    interrupted volume must stay mountable and show old-or-new bytes.
    {
        const pristine = try allocator.alloc(u8, image.len);
        @memcpy(pristine, image);
        var budget: u32 = 1;
        var completed = false;
        while (!completed and budget < 64) : (budget += 1) {
            @memcpy(image, pristine);
            var dev3 = RamDevice{ .image = image };
            var v3 = openVolume(&dev3) orelse {
                fail("crash sweep mount failed", .{});
                return finish();
            };
            const l3 = inspectSparse(&v3, "SPARSE.BIN") orelse {
                fail("crash sweep: no hole left to write", .{});
                break;
            };
            var cpatch: [4200]u8 = undefined;
            patternFill(0x3617 + budget, cpatch[0..]);
            vol.flush_budget = budget;
            const rc = vol.writeFileAt(&v3, l3.record, l3.hole_offset + 99, cpatch[0..]);
            vol.flush_budget = null;
            if (rc == .ok) completed = true;

            // Post-crash volume: must mount and read old (zeros) or new bytes.
            var dev4 = RamDevice{ .image = image };
            var v4 = openVolume(&dev4) orelse {
                fail("crash budget {d}: volume unmountable", .{budget});
                continue;
            };
            vol.flush_budget = null;
            const found = vol.lookupInDirectory(&v4, ntfs.MFT_RECORD_ROOT, "SPARSE.BIN") orelse {
                fail("crash budget {d}: file lost", .{budget});
                continue;
            };
            var window: [4200]u8 = undefined;
            const got = vol.readFileRange(&v4, found.record, l3.hole_offset + 99, window[0..]) orelse {
                fail("crash budget {d}: window read failed", .{budget});
                continue;
            };
            if (got != window.len) {
                fail("crash budget {d}: short window read", .{budget});
                continue;
            }
            const all_zero = std.mem.allEqual(u8, window[0..], 0);
            const all_new = std.mem.eql(u8, window[0..], cpatch[0..]);
            if (!all_zero and !all_new) fail("crash budget {d}: window is neither old zeros nor new bytes", .{budget});
        }
        if (!completed) {
            fail("crash sweep never completed within budget", .{});
        } else {
            std.debug.print("crash-sweep: ok ({d} budgets, old-or-new consistent)\n", .{budget - 1});
        }
        // Leave the DURABLE mutated image (not a crashed one) in place for
        // the caller: restore and redo the full run deterministically.
        @memcpy(image, pristine);
    }

    return finish();
}

fn finish() void {
    if (failures != 0) {
        std.debug.print("NTFSSPARSE result: FAILED ({d})\n", .{failures});
        std.process.exit(1);
    }
    std.debug.print("NTFSSPARSE result: OK\n", .{});
}
