// Hardening host model (0.60.11).
//
// Drives the REAL shared ntfs_volume engine through the closing hardening
// families of the 0.60.X NTFS line:
//
//   1. Long mixed churn across ALL write operations (create, delete,
//      rename/move, append, in-place overwrite, atomic replace, mkdir,
//      rmdir) over a dynamic directory pool with a full shadow model and
//      periodic complete verification.  The final image is dumped for the
//      strict NtfsVerify and the manual chkdsk acceptance.
//   2. A deterministic crash sweep: every operation kind is aborted at
//      varied flush budgets on top of a prepared directory.  After the
//      simulated power loss the volume must mount, every untouched file
//      must read back exactly, the touched object must be in a consistent
//      old-or-new state (never partially visible wrong data), the on-disk
//      dirty flag must reflect whether the operation completed, and a
//      subsequent clean operation must leave the volume clean again.
//      A crashed atomic replace must complete idempotently on re-run.
//   3. A dirty-flag matrix: fresh volumes are clean, the flag is durable
//      across remounts, and every completed operation bracket clears it.
//
// The crash sweep deliberately excludes writeFileAt: in-place range writes
// are pager semantics without a dirty bracket (torn content on power loss
// is the documented contract, as with any page-backed write path).

const std = @import("std");
const ntfs = @import("ntfs_format");
const vol = @import("ntfs_volume");
const mkfs = @import("ntfs_mkfs");

// ---- RAM device ----------------------------------------------------------

const RamDevice = struct {
    image: []u8,
    // Device-flush counter: the measurement basis for the 0.60.14
    // stream-batching family (deferred appends must not flush per chunk).
    flushes: usize = 0,

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
        const self: *RamDevice = @ptrCast(@alignCast(ctx));
        self.flushes += 1;
        return true;
    }

    fn device(self: *RamDevice) vol.Device {
        return .{ .ctx = self, .read_sectors = read, .write_sectors = write, .flush = flush };
    }
};

// Host model of the production 512-page write-back cache.  The ordinary
// RamDevice is intentionally immediate, so it cannot exercise the cache
// pressure created by copying a multi-megabyte package into a stage file.
const CacheEntry = struct {
    valid: bool = false,
    page_lba: u64 = 0,
    valid_mask: u8 = 0,
    dirty_mask: u8 = 0,
    last_use: u64 = 0,
    dirty_sequence: u64 = 0,
    next: u16 = 0xffff,
    data: [4096]u8 = undefined,
};

const CachedRamDevice = struct {
    const PAGE_SECTORS: usize = 8;
    const PAGE_BYTES: usize = PAGE_SECTORS * 512;
    const FULL_MASK: u8 = 0xff;
    const BUCKET_COUNT: usize = 1024;
    const NO_INDEX: u16 = 0xffff;

    backend: *RamDevice,
    entries: []CacheEntry,
    buckets: [BUCKET_COUNT]u16 = .{NO_INDEX} ** BUCKET_COUNT,
    clock: u64 = 0,
    dirty_clock: u64 = 0,
    pressure_drains: usize = 0,
    evictions: usize = 0,

    fn nextClock(self: *CachedRamDevice) u64 {
        self.clock +%= 1;
        if (self.clock == 0) self.clock = 1;
        return self.clock;
    }

    fn nextDirtySequence(self: *CachedRamDevice) u64 {
        self.dirty_clock +%= 1;
        if (self.dirty_clock == 0) self.dirty_clock = 1;
        return self.dirty_clock;
    }

    fn bucketOf(page_lba: u64) usize {
        var h: u64 = page_lba *% 0x9E3779B97F4A7C15;
        h ^= 0xC2B2AE3D27D4EB4F;
        h ^= h >> 29;
        return @intCast(h & (BUCKET_COUNT - 1));
    }

    fn find(self: *CachedRamDevice, page_lba: u64) ?usize {
        var cursor = self.buckets[bucketOf(page_lba)];
        while (cursor != NO_INDEX) {
            const index: usize = cursor;
            const entry = self.entries[index];
            if (entry.valid and entry.page_lba == page_lba) return index;
            cursor = entry.next;
        }
        return null;
    }

    fn link(self: *CachedRamDevice, index: usize) void {
        const bucket = bucketOf(self.entries[index].page_lba);
        self.entries[index].next = self.buckets[bucket];
        self.buckets[bucket] = @intCast(index);
    }

    fn unlink(self: *CachedRamDevice, index: usize) void {
        const bucket = bucketOf(self.entries[index].page_lba);
        var cursor = self.buckets[bucket];
        var previous: u16 = NO_INDEX;
        while (cursor != NO_INDEX) {
            if (cursor == @as(u16, @intCast(index))) {
                if (previous == NO_INDEX) {
                    self.buckets[bucket] = self.entries[index].next;
                } else {
                    self.entries[@as(usize, previous)].next = self.entries[index].next;
                }
                self.entries[index].next = NO_INDEX;
                return;
            }
            previous = cursor;
            cursor = self.entries[@as(usize, cursor)].next;
        }
    }

    fn selectClean(self: *CachedRamDevice) ?usize {
        var best: ?usize = null;
        var best_use: u64 = 0;
        for (self.entries, 0..) |entry, index| {
            if (!entry.valid) return index;
            if (entry.dirty_mask != 0) continue;
            if (best == null or entry.last_use < best_use) {
                best = index;
                best_use = entry.last_use;
            }
        }
        return best;
    }

    fn create(self: *CachedRamDevice, page_lba: u64) ?usize {
        const index = self.selectClean() orelse return null;
        if (self.entries[index].valid) {
            self.evictions += 1;
            self.unlink(index);
        }
        self.entries[index] = .{
            .valid = true,
            .page_lba = page_lba,
            .last_use = self.nextClock(),
        };
        self.link(index);
        return index;
    }

    fn oldestDirty(self: *CachedRamDevice) ?usize {
        var best: ?usize = null;
        var best_sequence: u64 = 0;
        for (self.entries, 0..) |entry, index| {
            if (!entry.valid or entry.dirty_mask == 0) continue;
            if (best == null or entry.dirty_sequence < best_sequence) {
                best = index;
                best_sequence = entry.dirty_sequence;
            }
        }
        return best;
    }

    fn fill(self: *CachedRamDevice, index: usize) bool {
        const entry = &self.entries[index];
        if (entry.valid_mask == FULL_MASK) return true;
        const before = entry.valid_mask;
        if (before == 0) {
            if (!RamDevice.read(self.backend, entry.page_lba, PAGE_SECTORS, entry.data[0..])) return false;
        } else {
            var sector: usize = 0;
            while (sector < PAGE_SECTORS) : (sector += 1) {
                const bit = @as(u8, 1) << @as(u3, @intCast(sector));
                if ((before & bit) != 0) continue;
                const off = sector * 512;
                if (!RamDevice.read(self.backend, entry.page_lba + sector, 1, entry.data[off .. off + 512])) return false;
            }
        }
        entry.valid_mask = FULL_MASK;
        entry.last_use = self.nextClock();
        return true;
    }

    fn writeback(self: *CachedRamDevice, index: usize) bool {
        const entry = &self.entries[index];
        const snapshot = entry.dirty_mask;
        if (!entry.valid or snapshot == 0) return true;
        var written: u8 = 0;
        var sector: usize = 0;
        while (sector < PAGE_SECTORS) {
            const bit = @as(u8, 1) << @as(u3, @intCast(sector));
            if ((snapshot & bit) == 0) {
                sector += 1;
                continue;
            }
            var run_len: usize = 1;
            while (sector + run_len < PAGE_SECTORS) : (run_len += 1) {
                const next_bit = @as(u8, 1) << @as(u3, @intCast(sector + run_len));
                if ((snapshot & next_bit) == 0) break;
            }
            const off = sector * 512;
            if (!RamDevice.write(
                self.backend,
                entry.page_lba + sector,
                @intCast(run_len),
                entry.data[off .. off + run_len * 512],
            )) return false;
            var mark: usize = 0;
            while (mark < run_len) : (mark += 1) {
                written |= @as(u8, 1) << @as(u3, @intCast(sector + mark));
            }
            sector += run_len;
        }
        entry.dirty_mask &= ~written;
        if (entry.dirty_mask == 0) entry.dirty_sequence = 0;
        return true;
    }

    fn read(ctx: *anyopaque, lba: u64, count: u32, out: []u8) bool {
        const self: *CachedRamDevice = @ptrCast(@alignCast(ctx));
        const total: usize = @as(usize, count) * 512;
        if (out.len < total) return false;
        var done: usize = 0;
        while (done < count) {
            const current = lba + done;
            const page = current & ~@as(u64, PAGE_SECTORS - 1);
            const first: usize = @intCast(current - page);
            const span = @min(@as(usize, count) - done, PAGE_SECTORS - first);
            const index = self.find(page) orelse self.create(page) orelse {
                if (!RamDevice.read(
                    self.backend,
                    current,
                    @intCast(span),
                    out[done * 512 ..][0 .. span * 512],
                )) return false;
                done += span;
                continue;
            };
            if (!self.fill(index)) return false;
            const entry = &self.entries[index];
            const src = first * 512;
            @memcpy(out[done * 512 ..][0 .. span * 512], entry.data[src .. src + span * 512]);
            entry.last_use = self.nextClock();
            done += span;
        }
        return true;
    }

    fn write(ctx: *anyopaque, lba: u64, count: u32, data: []const u8) bool {
        const self: *CachedRamDevice = @ptrCast(@alignCast(ctx));
        const total: usize = @as(usize, count) * 512;
        if (data.len < total) return false;
        var done: usize = 0;
        while (done < count) : (done += 1) {
            const current = lba + done;
            const page = current & ~@as(u64, PAGE_SECTORS - 1);
            var index = self.find(page);
            while (index == null) {
                index = self.create(page);
                if (index != null) break;
                const dirty = self.oldestDirty() orelse return false;
                if (!self.writeback(dirty)) return false;
                self.pressure_drains += 1;
            }
            const target = &self.entries[index.?];
            const sector: usize = @intCast(current - page);
            const bit = @as(u8, 1) << @as(u3, @intCast(sector));
            @memcpy(target.data[sector * 512 ..][0..512], data[done * 512 ..][0..512]);
            target.valid_mask |= bit;
            target.last_use = self.nextClock();
            if (target.dirty_mask == 0) target.dirty_sequence = self.nextDirtySequence();
            target.dirty_mask |= bit;
        }
        return true;
    }

    fn flush(ctx: *anyopaque) bool {
        const self: *CachedRamDevice = @ptrCast(@alignCast(ctx));
        while (self.oldestDirty()) |index| {
            if (!self.writeback(index)) return false;
        }
        return RamDevice.flush(self.backend);
    }

    fn device(self: *CachedRamDevice) vol.Device {
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

fn openVolumeDeviceWithCache(device: vol.Device, metadata_cache: ?*vol.MetadataCache) ?vol.Volume {
    const info = vol.mount(device, 0, &scratch, mft_runs[0..]) orelse return null;
    mft_run_count = info.mft_run_count;
    var v = vol.Volume{
        .device = device,
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
        .metadata_cache = metadata_cache,
        .metadata_cache_now_ticks = 1,
    };
    if (metadata_cache) |cache| cache.beginMount(1000);
    const got = vol.readFileRange(&v, ntfs.MFT_RECORD_UPCASE, 0, upcase_buf[0..]) orelse return null;
    if (got != ntfs.UPCASE_BYTES) return null;
    v.upcase = upcase_buf[0..];
    return v;
}

fn openVolumeDevice(device: vol.Device) ?vol.Volume {
    return openVolumeDeviceWithCache(device, null);
}

fn openVolume(dev: *RamDevice) ?vol.Volume {
    return openVolumeDevice(dev.device());
}

fn openVolumeWithCache(dev: *RamDevice, metadata_cache: *vol.MetadataCache) ?vol.Volume {
    return openVolumeDeviceWithCache(dev.device(), metadata_cache);
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
    var builder = try mkfs.Builder.init(allocator, size, "R4OSHARD", 0, meta, 132_000_000_000_000_000, 0x2611);
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

fn structurallySound(image: []u8) bool {
    var dev = RamDevice{ .image = image };
    var v = openVolume(&dev) orelse return false;
    var sink = vol.EnumSink{ .wanted = 10_000_000 };
    return vol.enumerateDirectory(&v, ntfs.MFT_RECORD_ROOT, &sink) and !sink.failed;
}

fn dumpImage(allocator: std.mem.Allocator, io: anytype, cwd: std.Io.Dir, image: []u8, path: []const u8) !void {
    const disk = try allocator.alloc(u8, 2048 * 512 + image.len);
    defer allocator.free(disk);
    @memset(disk[0 .. 2048 * 512], 0);
    std.mem.writeInt(u32, disk[0x1B8..][0..4], 0x52344F56, .little);
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
    std.debug.print("hardening image written: {s}\n", .{path});
}

// ---- family 1: long mixed churn -------------------------------------------

const MAX_SUBDIRS: usize = 24;
const BASE_DIRS: usize = 4;
const MAX_FILE_LEN: usize = 6000;

const ShadowDir = struct {
    record: u64 = 0,
    parent: usize = 0, // pool slot of the parent (base dirs point at themselves)
    name: [16]u8 = .{0} ** 16,
    name_len: usize = 0,
    alive: bool = false,
    is_base: bool = false,
    files: usize = 0,
    children: usize = 0,
};

const ShadowFile = struct {
    dir: usize, // pool slot
    name: [40]u8,
    name_len: usize,
    seed: u32,
    len: usize,
};

fn runLongChurn(allocator: std.mem.Allocator, meta: mkfs.Meta, total_ops: usize, out_path: ?[]const u8, io: anytype, cwd: std.Io.Dir) !void {
    const image = try formatFresh(allocator, meta, 96 * 1024 * 1024);
    defer allocator.free(image);
    var dev = RamDevice{ .image = image };
    var v = openVolume(&dev) orelse return fail("churn: mount failed", .{});
    vol.flush_budget = null;
    const root = ntfs.MFT_RECORD_ROOT;

    var pool: [BASE_DIRS + MAX_SUBDIRS]ShadowDir = .{ShadowDir{}} ** (BASE_DIRS + MAX_SUBDIRS);
    const base_names = [_][]const u8{ "HARD0", "HARD1", "HARD2", "HARD3" };
    for (base_names, 0..) |bn, bi| {
        if (vol.createDirectory(&v, root, bn) != .ok) return fail("churn: mkdir {s}", .{bn});
        const rec = (vol.lookupInDirectory(&v, root, bn) orelse return fail("churn: lookup {s}", .{bn})).record;
        pool[bi] = .{ .record = rec, .parent = bi, .alive = true, .is_base = true };
        @memcpy(pool[bi].name[0..bn.len], bn);
        pool[bi].name_len = bn.len;
    }

    var shadow = std.ArrayList(ShadowFile).empty;
    defer shadow.deinit(allocator);
    var rng: u32 = 0x2611;
    var next_id: usize = 0;
    var content: [MAX_FILE_LEN + 2048]u8 = undefined;
    var stats = [_]usize{0} ** 8;

    var ops: usize = 0;
    while (ops < total_ops) : (ops += 1) {
        rng ^= rng << 13;
        rng ^= rng >> 17;
        rng ^= rng << 5;
        const action = rng % 100;

        if (action < 28 or shadow.items.len == 0) {
            // Create in a random alive directory.
            const slot = pickAliveDir(pool[0..], rng >> 7) orelse return fail("churn: no alive dir", .{});
            var sf = ShadowFile{ .dir = slot, .name = undefined, .name_len = 0, .seed = rng, .len = @intCast(rng % MAX_FILE_LEN) };
            const n = std.fmt.bufPrint(sf.name[0..], "HF{d:0>6}.DAT", .{next_id}) catch unreachable;
            sf.name_len = n.len;
            next_id += 1;
            patternFill(sf.seed, content[0..sf.len]);
            const rc = vol.createFile(&v, pool[slot].record, n, content[0..sf.len]);
            if (rc != .ok) return fail("churn: create op {d} failed: {s}", .{ ops, @tagName(rc) });
            try shadow.append(allocator, sf);
            pool[slot].files += 1;
            stats[0] += 1;
        } else if (action < 44) {
            // Delete.
            const idx = rng % @as(u32, @intCast(shadow.items.len));
            const sf = shadow.items[idx];
            const rc = vol.deleteFile(&v, pool[sf.dir].record, sf.name[0..sf.name_len]);
            if (rc != .ok) return fail("churn: delete op {d} failed: {s}", .{ ops, @tagName(rc) });
            pool[sf.dir].files -= 1;
            _ = shadow.swapRemove(idx);
            stats[1] += 1;
        } else if (action < 56) {
            // Rename/move.
            const idx = rng % @as(u32, @intCast(shadow.items.len));
            var sf = &shadow.items[idx];
            const new_slot = pickAliveDir(pool[0..], rng >> 9) orelse return fail("churn: no alive dir", .{});
            var new_name: [40]u8 = undefined;
            const n = std.fmt.bufPrint(new_name[0..], "HF{d:0>6}.DAT", .{next_id}) catch unreachable;
            next_id += 1;
            const rc = vol.renameEntry(&v, pool[sf.dir].record, sf.name[0..sf.name_len], pool[new_slot].record, n);
            if (rc != .ok) return fail("churn: rename op {d} failed: {s}", .{ ops, @tagName(rc) });
            pool[sf.dir].files -= 1;
            pool[new_slot].files += 1;
            sf.dir = new_slot;
            @memcpy(sf.name[0..n.len], n);
            sf.name_len = n.len;
            stats[2] += 1;
        } else if (action < 68) {
            // Append.
            const idx = rng % @as(u32, @intCast(shadow.items.len));
            var sf = &shadow.items[idx];
            const add: usize = @intCast((rng >> 4) % 1500 + 1);
            if (sf.len + add > content.len) continue;
            patternFill(sf.seed, content[0 .. sf.len + add]);
            const rc = vol.appendFileAtOffset(&v, pool[sf.dir].record, sf.name[0..sf.name_len], sf.len, content[sf.len .. sf.len + add]);
            if (rc != .ok) return fail("churn: append op {d} failed: {s}", .{ ops, @tagName(rc) });
            sf.len += add;
            stats[3] += 1;
        } else if (action < 76) {
            // In-place overwrite via writeFileAt (same length, new seed).
            const idx = rng % @as(u32, @intCast(shadow.items.len));
            var sf = &shadow.items[idx];
            if (sf.len == 0) continue;
            const found = vol.lookupInDirectory(&v, pool[sf.dir].record, sf.name[0..sf.name_len]) orelse
                return fail("churn: overwrite lookup op {d}", .{ops});
            const new_seed = rng ^ 0x5A5A_5A5A;
            patternFill(new_seed, content[0..sf.len]);
            const rc = vol.writeFileAt(&v, found.record, 0, content[0..sf.len]);
            if (rc != .ok) return fail("churn: overwrite op {d} failed: {s}", .{ ops, @tagName(rc) });
            sf.seed = new_seed;
            stats[4] += 1;
        } else if (action < 84) {
            // Atomic replace: stage new content, replace, drop the backup.
            const idx = rng % @as(u32, @intCast(shadow.items.len));
            var sf = &shadow.items[idx];
            var stage_name: [40]u8 = undefined;
            var backup_name: [40]u8 = undefined;
            const sn = std.fmt.bufPrint(stage_name[0..], "RP{d:0>6}.STG", .{next_id}) catch unreachable;
            const bn = std.fmt.bufPrint(backup_name[0..], "RP{d:0>6}.BAK", .{next_id}) catch unreachable;
            next_id += 1;
            const new_seed = rng ^ 0x3C3C_3C3C;
            const new_len: usize = @intCast((rng >> 3) % MAX_FILE_LEN);
            patternFill(new_seed, content[0..new_len]);
            if (vol.createFile(&v, pool[sf.dir].record, sn, content[0..new_len]) != .ok) {
                return fail("churn: replace stage op {d} failed", .{ops});
            }
            const rr = vol.replaceFileAtomic(&v, pool[sf.dir].record, sf.name[0..sf.name_len], sn, bn, true);
            if (rr != .ok) return fail("churn: replace op {d} failed: {s}", .{ ops, @tagName(rr) });
            if (vol.deleteFile(&v, pool[sf.dir].record, bn) != .ok) {
                return fail("churn: replace backup drop op {d} failed", .{ops});
            }
            sf.seed = new_seed;
            sf.len = new_len;
            stats[5] += 1;
        } else if (action < 92) {
            // mkdir in the pool.
            const free_slot = blk: {
                var i: usize = BASE_DIRS;
                while (i < pool.len) : (i += 1) {
                    if (!pool[i].alive) break :blk i;
                }
                break :blk null;
            } orelse continue;
            const parent_slot = pickAliveDir(pool[0..], rng >> 11) orelse continue;
            var dn: [16]u8 = undefined;
            const n = std.fmt.bufPrint(dn[0..], "SD{d:0>5}", .{next_id}) catch unreachable;
            next_id += 1;
            const rc = vol.createDirectory(&v, pool[parent_slot].record, n);
            if (rc != .ok) return fail("churn: mkdir op {d} failed: {s}", .{ ops, @tagName(rc) });
            const rec = (vol.lookupInDirectory(&v, pool[parent_slot].record, n) orelse
                return fail("churn: mkdir lookup op {d}", .{ops})).record;
            pool[free_slot] = .{ .record = rec, .parent = parent_slot, .alive = true };
            @memcpy(pool[free_slot].name[0..n.len], n);
            pool[free_slot].name_len = n.len;
            pool[parent_slot].children += 1;
            stats[6] += 1;
        } else {
            // rmdir of an empty non-base pool directory.
            const victim = blk: {
                var i: usize = BASE_DIRS;
                while (i < pool.len) : (i += 1) {
                    if (pool[i].alive and pool[i].files == 0 and pool[i].children == 0) break :blk i;
                }
                break :blk null;
            } orelse continue;
            const parent_slot = pool[victim].parent;
            const rc = vol.deleteDirectory(&v, pool[parent_slot].record, pool[victim].name[0..pool[victim].name_len]);
            if (rc != .ok) return fail("churn: rmdir op {d} failed: {s}", .{ ops, @tagName(rc) });
            pool[victim].alive = false;
            pool[parent_slot].children -= 1;
            stats[7] += 1;
        }

        if ((ops + 1) % 1000 == 0) {
            if (!verifyShadow(&v, pool[0..], shadow.items, content[0..])) {
                return fail("churn: periodic verification failed at op {d}", .{ops + 1});
            }
        }
    }

    if (!verifyShadow(&v, pool[0..], shadow.items, content[0..])) {
        fail("churn: final verification failed", .{});
    }
    const dirty = vol.isDirty(&v) orelse blk: {
        fail("churn: dirty flag unreadable", .{});
        break :blk true;
    };
    if (dirty) fail("churn: volume left dirty after clean operations", .{});
    std.debug.print(
        "hardening churn: ok ({d} ops: create={d} delete={d} rename={d} append={d} overwrite={d} replace={d} mkdir={d} rmdir={d}, {d} surviving files)\n",
        .{ ops, stats[0], stats[1], stats[2], stats[3], stats[4], stats[5], stats[6], stats[7], shadow.items.len },
    );

    if (out_path) |path| try dumpImage(allocator, io, cwd, image, path);
}

fn pickAliveDir(pool: []ShadowDir, hint: u32) ?usize {
    var offset: usize = @intCast(hint % @as(u32, @intCast(pool.len)));
    var i: usize = 0;
    while (i < pool.len) : (i += 1) {
        const slot = (offset + i) % pool.len;
        if (pool[slot].alive) return slot;
    }
    _ = &offset;
    return null;
}

fn verifyShadow(v: *vol.Volume, pool: []ShadowDir, files: []const ShadowFile, content: []u8) bool {
    var ok = true;
    for (files) |sf| {
        patternFill(sf.seed, content[0..sf.len]);
        if (!readAndCheck(v, pool[sf.dir].record, sf.name[0..sf.name_len], content[0..sf.len])) {
            std.debug.print("  shadow mismatch: {s}\n", .{sf.name[0..sf.name_len]});
            ok = false;
        }
    }
    for (pool) |*d| {
        if (!d.alive) continue;
        const expected = d.files + d.children;
        if (countEntries(v, d.record) != expected) {
            std.debug.print("  dir count mismatch: {s} (expected {d})\n", .{ d.name[0..d.name_len], expected });
            ok = false;
        }
    }
    return ok;
}

// ---- family 2: crash sweep -------------------------------------------------

const PREP_FILES: usize = 40;

fn prepName(buf: []u8, i: usize) []const u8 {
    return std.fmt.bufPrint(buf, "F{d:0>4}.DAT", .{i}) catch unreachable;
}

fn runCrashSweep(allocator: std.mem.Allocator, meta: mkfs.Meta, crash_runs: usize, crashed_out: ?[]const u8, io: anytype, cwd: std.Io.Dir) !void {
    const kinds = [_][]const u8{ "create", "delete", "append", "rename", "mkdir", "rmdir", "replace" };
    // One representative post-crash image (dirty flag set, interrupted
    // create) is dumped for the manual chkdsk suite: Windows must mount it,
    // repair the leftovers under /f and be clean on the second pass.
    const crashed_dump_run: usize = 7;
    const template = try formatFresh(allocator, meta, 24 * 1024 * 1024);
    defer allocator.free(template);
    const image = try allocator.alloc(u8, template.len);
    defer allocator.free(image);
    var observed_recovery_invalidations: usize = 0;

    var run: usize = 0;
    while (run < crash_runs) : (run += 1) {
        const kind = kinds[run % kinds.len];
        const budget: u32 = @intCast(1 + (run / kinds.len) % 14);
        @memcpy(image, template);
        var dev = RamDevice{ .image = image };
        var metadata_cache = vol.MetadataCache{};
        var v = openVolumeWithCache(&dev, &metadata_cache) orelse {
            fail("crash {s} budget {d}: mount failed", .{ kind, budget });
            continue;
        };
        vol.flush_budget = null;
        const root = ntfs.MFT_RECORD_ROOT;

        // Prepared state (never injected).
        if (vol.createDirectory(&v, root, "WORK") != .ok) {
            fail("crash {s} budget {d}: prep mkdir", .{ kind, budget });
            continue;
        }
        const work = (vol.lookupInDirectory(&v, root, "WORK") orelse continue).record;
        var name_buf: [48]u8 = undefined;
        var content: [128]u8 = undefined;
        var i: usize = 0;
        while (i < PREP_FILES) : (i += 1) {
            const n = prepName(name_buf[0..], i);
            patternFill(@intCast(i + 7), content[0..]);
            if (vol.createFile(&v, work, n, content[0..]) != .ok) {
                fail("crash {s} budget {d}: prep create {d}", .{ kind, budget, i });
            }
        }
        var grow_old: [128]u8 = undefined;
        var grow_new: [20128]u8 = undefined;
        patternFill(0xA1, grow_old[0..]);
        @memcpy(grow_new[0..128], grow_old[0..]);
        patternFill(0xB2, grow_new[128..]);
        var repl_old: [900]u8 = undefined;
        var repl_new: [1300]u8 = undefined;
        patternFill(0xC3, repl_old[0..]);
        patternFill(0xD4, repl_new[0..]);
        if (std.mem.eql(u8, kind, "append")) {
            _ = vol.createFile(&v, work, "GROW.BIN", grow_old[0..]);
        }
        if (std.mem.eql(u8, kind, "rename")) {
            _ = vol.createFile(&v, work, "RN.TXT", "rename crash victim");
        }
        if (std.mem.eql(u8, kind, "rmdir")) {
            _ = vol.createDirectory(&v, work, "GONE");
        }
        if (std.mem.eql(u8, kind, "replace")) {
            _ = vol.createFile(&v, work, "T.TXT", repl_old[0..]);
            _ = vol.createFile(&v, work, "S.TXT", repl_new[0..]);
        }

        // The injected operation.
        var crash_content: [3000]u8 = undefined;
        patternFill(0xE5, crash_content[0..]);
        vol.flush_budget = budget;
        const cache_before_failure = metadata_cache.summary();
        var rc_ok = false;
        if (std.mem.eql(u8, kind, "create")) {
            rc_ok = vol.createFile(&v, work, "CNEW.DAT", crash_content[0..]) == .ok;
        } else if (std.mem.eql(u8, kind, "delete")) {
            rc_ok = vol.deleteFile(&v, work, "F0011.DAT") == .ok;
        } else if (std.mem.eql(u8, kind, "append")) {
            rc_ok = vol.appendFileAtOffset(&v, work, "GROW.BIN", 128, grow_new[128..]) == .ok;
        } else if (std.mem.eql(u8, kind, "rename")) {
            rc_ok = vol.renameEntry(&v, work, "RN.TXT", root, "RN2.TXT") == .ok;
        } else if (std.mem.eql(u8, kind, "mkdir")) {
            rc_ok = vol.createDirectory(&v, work, "SUB") == .ok;
        } else if (std.mem.eql(u8, kind, "rmdir")) {
            rc_ok = vol.deleteDirectory(&v, work, "GONE") == .ok;
        } else {
            rc_ok = vol.replaceFileAtomic(&v, work, "T.TXT", "S.TXT", "B.TXT", true) == .ok;
        }
        vol.flush_budget = null;
        const cache_after_failure = metadata_cache.summary();
        const recovered_failure = !rc_ok and
            cache_after_failure.recovery_invalidations > cache_before_failure.recovery_invalidations;
        if (recovered_failure) {
            observed_recovery_invalidations += 1;
        }

        if (run == crashed_dump_run) {
            if (crashed_out) |path| try dumpImage(allocator, io, cwd, image, path);
        }

        // Post-crash: mountable, sound, untouched files exact.
        var dev2 = RamDevice{ .image = image };
        var v2 = openVolume(&dev2) orelse {
            fail("crash {s} budget {d}: unmountable after crash", .{ kind, budget });
            continue;
        };
        if (!structurallySound(image)) fail("crash {s} budget {d}: not sound", .{ kind, budget });
        const work2 = (vol.lookupInDirectory(&v2, root, "WORK") orelse {
            fail("crash {s} budget {d}: WORK missing", .{ kind, budget });
            continue;
        }).record;
        i = 0;
        while (i < PREP_FILES) : (i += 1) {
            if (std.mem.eql(u8, kind, "delete") and i == 11) continue;
            const n = prepName(name_buf[0..], i);
            patternFill(@intCast(i + 7), content[0..]);
            if (!readAndCheck(&v2, work2, n, content[0..])) {
                fail("crash {s} budget {d}: untouched file {d} damaged", .{ kind, budget, i });
            }
        }

        // Touched object: consistent old-or-new; a clean dirty flag demands
        // the completed new state.
        const dirty = vol.isDirty(&v2) orelse blk: {
            fail("crash {s} budget {d}: dirty flag unreadable", .{ kind, budget });
            break :blk true;
        };
        const complete = !dirty;
        // A failed operation that emitted a recovery invalidation may have
        // completed a clean rollback to the old state. Without recovery, a
        // clean volume means the mutation reached its complete new state
        // even if the final durability acknowledgement was lost.
        const requires_new_state = complete and (rc_ok or !recovered_failure);
        if (std.mem.eql(u8, kind, "create")) {
            const present = readAndCheck(&v2, work2, "CNEW.DAT", crash_content[0..]);
            const absent = vol.lookupInDirectory(&v2, work2, "CNEW.DAT") == null;
            if (!present and !absent) fail("crash create budget {d}: partial file visible", .{budget});
            if (requires_new_state and !present) fail("crash create budget {d}: clean volume without new state", .{budget});
        } else if (std.mem.eql(u8, kind, "delete")) {
            patternFill(@intCast(11 + 7), content[0..]);
            const present = readAndCheck(&v2, work2, "F0011.DAT", content[0..]);
            const absent = vol.lookupInDirectory(&v2, work2, "F0011.DAT") == null;
            if (!present and !absent) fail("crash delete budget {d}: damaged victim visible", .{budget});
            if (requires_new_state and !absent) fail("crash delete budget {d}: clean volume without deletion", .{budget});
        } else if (std.mem.eql(u8, kind, "append")) {
            const found = vol.lookupInDirectory(&v2, work2, "GROW.BIN") orelse {
                fail("crash append budget {d}: file lost", .{budget});
                continue;
            };
            const size: usize = @intCast(found.entry.size);
            if (size != 128 and size != grow_new.len) {
                fail("crash append budget {d}: unexpected size {d}", .{ budget, size });
            } else {
                var buf: [20128]u8 = undefined;
                const got = vol.readFileRange(&v2, found.record, 0, buf[0..size]) orelse 0;
                if (got != size or !std.mem.eql(u8, buf[0..size], grow_new[0..size])) {
                    fail("crash append budget {d}: content mismatch at size {d}", .{ budget, size });
                }
            }
            if (requires_new_state and size != grow_new.len) fail("crash append budget {d}: clean volume without new size", .{budget});
        } else if (std.mem.eql(u8, kind, "rename")) {
            const old_present = readAndCheck(&v2, work2, "RN.TXT", "rename crash victim");
            const new_present = readAndCheck(&v2, root, "RN2.TXT", "rename crash victim");
            if (old_present and new_present) fail("crash rename budget {d}: both names visible", .{budget});
            // The remove->insert window may leave the record temporarily
            // unreferenced (classic NTFS rename crash window; chkdsk
            // reconnects orphans).  Partial/wrong content is never allowed.
            if (requires_new_state and !new_present) fail("crash rename budget {d}: clean volume without new name", .{budget});
        } else if (std.mem.eql(u8, kind, "mkdir")) {
            const present = vol.lookupInDirectory(&v2, work2, "SUB") != null;
            if (requires_new_state and !present) fail("crash mkdir budget {d}: clean volume without directory", .{budget});
        } else if (std.mem.eql(u8, kind, "rmdir")) {
            const present = vol.lookupInDirectory(&v2, work2, "GONE") != null;
            if (requires_new_state and present) fail("crash rmdir budget {d}: clean volume with directory", .{budget});
        } else {
            // replace: target holds old or new content, never a mix; the
            // rename chain may be mid-flight (target briefly absent).
            const t_old = readAndCheck(&v2, work2, "T.TXT", repl_old[0..]);
            const t_new = readAndCheck(&v2, work2, "T.TXT", repl_new[0..]);
            const t_absent = vol.lookupInDirectory(&v2, work2, "T.TXT") == null;
            if (!t_old and !t_new and !t_absent) fail("crash replace budget {d}: target content mixed", .{budget});
            if (requires_new_state and !t_new) fail("crash replace budget {d}: clean volume without new target", .{budget});
            // Idempotent completion: re-running the same replace must
            // converge to the new target (0.60.8 contract under crash).
            if (!t_new) {
                const rr = vol.replaceFileAtomic(&v2, work2, "T.TXT", "S.TXT", "B.TXT", true);
                if (rr != .ok) {
                    fail("crash replace budget {d}: idempotent re-run failed: {s}", .{ budget, @tagName(rr) });
                } else if (!readAndCheck(&v2, work2, "T.TXT", repl_new[0..])) {
                    fail("crash replace budget {d}: re-run did not converge", .{budget});
                }
            }
        }

        // Recovery: one clean operation leaves the volume clean again.
        var dev3 = RamDevice{ .image = image };
        var v3 = openVolume(&dev3) orelse {
            fail("crash {s} budget {d}: recovery mount failed", .{ kind, budget });
            continue;
        };
        if (vol.createFile(&v3, root, "RECHK.TXT", "recovered") != .ok) {
            fail("crash {s} budget {d}: recovery create failed", .{ kind, budget });
        }
        const clean = vol.isDirty(&v3) orelse true;
        if (clean) fail("crash {s} budget {d}: dirty after clean recovery op", .{ kind, budget });
    }
    if (crash_runs >= kinds.len and observed_recovery_invalidations == 0) {
        fail("crash sweep: no failed mutation emitted a recovery invalidation", .{});
    }
    std.debug.print(
        "hardening crash sweep: ok ({d} runs across {d} kinds, recovery-invalidations={d})\n",
        .{ crash_runs, kinds.len, observed_recovery_invalidations },
    );
}

// ---- family 2b: deferred stream batching (0.60.14) -------------------------

var stream_expected: [262144]u8 = undefined;

fn runDeferredStream(allocator: std.mem.Allocator, meta: mkfs.Meta) !void {
    const image = try formatFresh(allocator, meta, 24 * 1024 * 1024);
    defer allocator.free(image);
    var dev = RamDevice{ .image = image };
    var v = openVolume(&dev) orelse return fail("deferred: mount failed", .{});
    vol.flush_budget = null;
    const root = ntfs.MFT_RECORD_ROOT;

    // 64 x 4 KB deferred appends: the dirty flag spans the stream and at
    // most the initial dirty-set flush may hit the device.
    if (vol.createFile(&v, root, "STREAM.BIN", "") != .ok) return fail("deferred: create failed", .{});
    const chunk_size: usize = 4096;
    const chunk_count: usize = 64;
    const flush_base = dev.flushes;
    var offset: u64 = 0;
    var i: usize = 0;
    while (i < chunk_count) : (i += 1) {
        const slice = stream_expected[i * chunk_size .. (i + 1) * chunk_size];
        patternFill(@intCast(i + 41), slice);
        const rc = vol.appendFileAtOffsetDeferred(&v, root, "STREAM.BIN", offset, slice);
        if (rc != .ok) return fail("deferred: chunk {d} failed: {s}", .{ i, @tagName(rc) });
        offset += chunk_size;
        if (i == 0 and !(vol.isDirty(&v) orelse false)) fail("deferred: dirty not set by first chunk", .{});
    }
    const deferred_flushes = dev.flushes - flush_base;
    if (deferred_flushes > 2) fail("deferred: {d} device flushes for {d} chunks (batching broken)", .{ deferred_flushes, chunk_count });
    if (!(vol.isDirty(&v) orelse false)) fail("deferred: dirty cleared mid-stream", .{});

    // finishDeferred is the single durability point: drain, then clear.
    if (!vol.finishDeferred(&v)) fail("deferred: finish failed", .{});
    if (vol.isDirty(&v) orelse true) fail("deferred: dirty after finish", .{});
    if (!readAndCheck(&v, root, "STREAM.BIN", stream_expected[0..])) fail("deferred: readback mismatch", .{});

    // Durable comparison: per-call appends must keep flushing per phase.
    if (vol.createFile(&v, root, "DUR.BIN", "") != .ok) return fail("deferred: durable create failed", .{});
    const durable_base = dev.flushes;
    var expected_len: usize = 0;
    i = 0;
    while (i < 8) : (i += 1) {
        const slice = stream_expected[expected_len .. expected_len + chunk_size];
        const rc = vol.appendFileAtOffset(&v, root, "DUR.BIN", expected_len, slice);
        if (rc != .ok) return fail("deferred: durable chunk {d} failed: {s}", .{ i, @tagName(rc) });
        expected_len += chunk_size;
    }
    const durable_flushes = dev.flushes - durable_base;
    if (durable_flushes < 8 * 3) fail("deferred: durable path lost its per-call flushes ({d})", .{durable_flushes});
    std.debug.print(
        "hardening deferred stream: ok (chunks={d} deferredFlushes={d} durableFlushes={d})\n",
        .{ chunk_count, deferred_flushes, durable_flushes },
    );

    // The production updater repeatedly creates, streams and removes a
    // multi-megabyte stage file.  The short single-file fixture above cannot
    // expose state which leaks across delete/recreate cycles.
    const repeated_bytes: usize = 3_184_229;
    const repeated_chunk: usize = 64 * 1024;
    var repeated_pass: usize = 0;
    while (repeated_pass < 32) : (repeated_pass += 1) {
        if (vol.createFile(&v, root, "REPEAT.R4U", "") != .ok)
            return fail("deferred repeat {d}: create failed", .{repeated_pass + 1});
        var repeated_offset: usize = 0;
        while (repeated_offset < repeated_bytes) {
            const take = @min(repeated_chunk, repeated_bytes - repeated_offset);
            patternFill(@intCast(repeated_pass * 97 + repeated_offset + 1), stream_expected[0..take]);
            const rc = vol.appendFileAtOffsetDeferred(
                &v,
                root,
                "REPEAT.R4U",
                repeated_offset,
                stream_expected[0..take],
            );
            if (rc != .ok)
                return fail("deferred repeat {d} offset {d}: {s}", .{ repeated_pass + 1, repeated_offset, @tagName(rc) });
            repeated_offset += take;
        }
        if (!vol.finishDeferred(&v))
            return fail("deferred repeat {d}: finish failed", .{repeated_pass + 1});
        const repeated = vol.lookupInDirectory(&v, root, "REPEAT.R4U") orelse
            return fail("deferred repeat {d}: lookup failed", .{repeated_pass + 1});
        if (repeated.entry.size != repeated_bytes)
            return fail("deferred repeat {d}: size {d}", .{ repeated_pass + 1, repeated.entry.size });
        if (vol.deleteFile(&v, root, "REPEAT.R4U") != .ok)
            return fail("deferred repeat {d}: delete failed", .{repeated_pass + 1});
    }
    std.debug.print("hardening deferred repeat: ok (passes={d} bytes={d})\n", .{ repeated_pass, repeated_bytes });
}

// The updater does not synthesize its stage payload in memory: it alternates
// source-file reads and destination-file appends on the same cached volume.
// This exact copy shape saturates the 2-MB production cache with clean source
// pages and dirty destination/metadata pages at the same time.
fn runCachedPackageCopy(allocator: std.mem.Allocator, meta: mkfs.Meta) !void {
    const package_bytes: usize = 3_184_229;
    const chunk_bytes: usize = 64 * 1024;
    const image = try formatFresh(allocator, meta, 32 * 1024 * 1024);
    defer allocator.free(image);
    var backend = RamDevice{ .image = image };
    var direct = openVolume(&backend) orelse return fail("cached copy: direct mount failed", .{});
    vol.flush_budget = null;
    const root = ntfs.MFT_RECORD_ROOT;

    if (vol.createFile(&direct, root, "SOURCE.R4U", "") != .ok)
        return fail("cached copy: source create failed", .{});
    var offset: usize = 0;
    while (offset < package_bytes) {
        const take = @min(chunk_bytes, package_bytes - offset);
        patternFill(@intCast(offset + 701), stream_expected[0..take]);
        const rc = vol.appendFileAtOffsetDeferred(&direct, root, "SOURCE.R4U", offset, stream_expected[0..take]);
        if (rc != .ok) return fail("cached copy: source offset {d}: {s}", .{ offset, @tagName(rc) });
        offset += take;
    }
    if (!vol.finishDeferred(&direct)) return fail("cached copy: source finish failed", .{});

    const cache_entries = try allocator.alloc(CacheEntry, 512);
    defer allocator.free(cache_entries);
    @memset(cache_entries, CacheEntry{});
    var cached = CachedRamDevice{ .backend = &backend, .entries = cache_entries };
    var v = openVolumeDevice(cached.device()) orelse return fail("cached copy: cached mount failed", .{});
    const source = vol.lookupInDirectory(&v, root, "SOURCE.R4U") orelse
        return fail("cached copy: source lookup failed", .{});

    var pass: usize = 0;
    while (pass < 32) : (pass += 1) {
        if (vol.createFile(&v, root, "STAGE.R4U", "") != .ok)
            return fail("cached copy {d}: stage create failed", .{pass + 1});
        offset = 0;
        while (offset < package_bytes) {
            const take = @min(chunk_bytes, package_bytes - offset);
            const got = vol.readFileRange(&v, source.record, offset, stream_expected[0..take]) orelse
                return fail("cached copy {d}: source read failed at {d}", .{ pass + 1, offset });
            if (got != take)
                return fail("cached copy {d}: short source read at {d}: {d}", .{ pass + 1, offset, got });
            const rc = vol.appendFileAtOffsetDeferred(&v, root, "STAGE.R4U", offset, stream_expected[0..take]);
            if (rc != .ok)
                return fail("cached copy {d}: stage append failed at {d}: {s}", .{ pass + 1, offset, @tagName(rc) });
            offset += take;
        }
        if (!vol.finishDeferred(&v))
            return fail("cached copy {d}: stage finish failed", .{pass + 1});
        const stage = vol.lookupInDirectory(&v, root, "STAGE.R4U") orelse
            return fail("cached copy {d}: stage lookup failed", .{pass + 1});
        if (stage.entry.size != package_bytes)
            return fail("cached copy {d}: stage size {d}", .{ pass + 1, stage.entry.size });
        if (vol.deleteFile(&v, root, "STAGE.R4U") != .ok)
            return fail("cached copy {d}: stage delete failed", .{pass + 1});
    }
    std.debug.print(
        "hardening cached copy: ok (passes={d} bytes={d} pressureDrains={d} evictions={d})\n",
        .{ pass, package_bytes, cached.pressure_drains, cached.evictions },
    );
}

// Optional diagnostic mode over an actual release disk image.  Unlike the
// compact formatter fixture this preserves the production MFT, bitmap,
// directory trees and free-space geometry.  The input is held in memory and
// is never written back.
fn runCachedProductionImage(
    allocator: std.mem.Allocator,
    io: anytype,
    cwd: std.Io.Dir,
    image_path: []const u8,
    requested_passes: usize,
) !void {
    const disk = try cwd.readFileAlloc(io, image_path, allocator, .limited(1024 * 1024 * 1024));
    defer allocator.free(disk);
    if (disk.len < 512) return fail("production image: truncated MBR", .{});

    var partition_offset: usize = 0;
    var partition_bytes: usize = 0;
    var part: usize = 0;
    while (part < 4) : (part += 1) {
        const entry = 446 + part * 16;
        if (disk[entry + 4] != 0x07) continue;
        const lba = std.mem.readInt(u32, disk[entry + 8 ..][0..4], .little);
        const sectors = std.mem.readInt(u32, disk[entry + 12 ..][0..4], .little);
        partition_offset = @as(usize, lba) * 512;
        partition_bytes = @as(usize, sectors) * 512;
        break;
    }
    if (partition_bytes == 0 or partition_offset > disk.len or partition_bytes > disk.len - partition_offset)
        return fail("production image: NTFS partition missing or invalid", .{});

    var backend = RamDevice{ .image = disk[partition_offset .. partition_offset + partition_bytes] };
    var direct = openVolume(&backend) orelse return fail("production image: direct mount failed", .{});
    vol.flush_budget = null;
    const r4os_dir = vol.resolvePath(&direct, "/R4OS") orelse
        return fail("production image: R4OS directory missing", .{});
    var update_dir = vol.resolvePath(&direct, "/R4OS/UPDATE");
    if (update_dir == null) {
        const created = vol.createDirectory(&direct, r4os_dir, "UPDATE");
        if (created != .ok) return fail("production image: UPDATE create: {s}", .{@tagName(created)});
        update_dir = vol.resolvePath(&direct, "/R4OS/UPDATE");
    }
    const update = update_dir orelse return fail("production image: UPDATE resolve failed", .{});
    var inbox_dir = vol.resolvePath(&direct, "/R4OS/UPDATE/INBOX");
    if (inbox_dir == null) {
        const created = vol.createDirectory(&direct, update, "INBOX");
        if (created != .ok) return fail("production image: INBOX create: {s}", .{@tagName(created)});
        inbox_dir = vol.resolvePath(&direct, "/R4OS/UPDATE/INBOX");
    }
    const inbox = inbox_dir orelse return fail("production image: inbox resolve failed", .{});
    const terminal = vol.resolvePath(&direct, "/R4OS/SOFTWARE/TERMINAL") orelse
        return fail("production image: terminal directory missing", .{});
    const source_name = "HOSTSRC.R4U";
    const stage_name = "IOTEST.R4U";
    if (vol.lookupInDirectory(&direct, inbox, source_name) != null) {
        if (vol.deleteFile(&direct, inbox, source_name) != .ok)
            return fail("production image: stale source delete failed", .{});
    }
    if (vol.lookupInDirectory(&direct, terminal, stage_name) != null) {
        if (vol.deleteFile(&direct, terminal, stage_name) != .ok)
            return fail("production image: stale stage delete failed", .{});
    }

    const package_bytes: usize = 3_184_229;
    const chunk_bytes: usize = 64 * 1024;
    if (vol.createFile(&direct, inbox, source_name, "") != .ok)
        return fail("production image: source create failed", .{});
    var offset: usize = 0;
    while (offset < package_bytes) {
        const take = @min(chunk_bytes, package_bytes - offset);
        patternFill(@intCast(offset + 1701), stream_expected[0..take]);
        const rc = vol.appendFileAtOffsetDeferred(&direct, inbox, source_name, offset, stream_expected[0..take]);
        if (rc != .ok) return fail("production image: source offset {d}: {s}", .{ offset, @tagName(rc) });
        offset += take;
    }
    if (!vol.finishDeferred(&direct)) return fail("production image: source finish failed", .{});

    const cache_entries = try allocator.alloc(CacheEntry, 512);
    defer allocator.free(cache_entries);
    @memset(cache_entries, CacheEntry{});
    var cached = CachedRamDevice{ .backend = &backend, .entries = cache_entries };
    var v = openVolumeDevice(cached.device()) orelse return fail("production image: cached mount failed", .{});
    const cached_inbox = vol.resolvePath(&v, "/R4OS/UPDATE/INBOX") orelse
        return fail("production image: cached inbox missing", .{});
    const cached_terminal = vol.resolvePath(&v, "/R4OS/SOFTWARE/TERMINAL") orelse
        return fail("production image: cached terminal missing", .{});
    const source = vol.lookupInDirectory(&v, cached_inbox, source_name) orelse
        return fail("production image: source lookup failed", .{});

    var pass: usize = 0;
    while (pass < requested_passes) : (pass += 1) {
        const created = vol.createFile(&v, cached_terminal, stage_name, "");
        if (created != .ok)
            return fail("production image {d}: stage create: {s}", .{ pass + 1, @tagName(created) });
        offset = 0;
        while (offset < package_bytes) {
            const take = @min(chunk_bytes, package_bytes - offset);
            const got = vol.readFileRange(&v, source.record, offset, stream_expected[0..take]) orelse
                return fail("production image {d}: source read at {d}", .{ pass + 1, offset });
            if (got != take)
                return fail("production image {d}: short source read at {d}: {d}", .{ pass + 1, offset, got });
            const rc = vol.appendFileAtOffsetDeferred(&v, cached_terminal, stage_name, offset, stream_expected[0..take]);
            if (rc != .ok)
                return fail("production image {d}: stage append at {d}: {s}", .{ pass + 1, offset, @tagName(rc) });
            offset += take;
        }
        if (!vol.finishDeferred(&v))
            return fail("production image {d}: stage finish failed", .{pass + 1});
        const stage = vol.lookupInDirectory(&v, cached_terminal, stage_name) orelse
            return fail("production image {d}: stage lookup failed", .{pass + 1});
        if (stage.entry.size != package_bytes)
            return fail("production image {d}: stage size {d}", .{ pass + 1, stage.entry.size });
        const deleted = vol.deleteFile(&v, cached_terminal, stage_name);
        if (deleted != .ok)
            return fail("production image {d}: stage delete: {s}", .{ pass + 1, @tagName(deleted) });
    }
    std.debug.print(
        "hardening production image: ok (passes={d} bytes={d} pressureDrains={d} evictions={d})\n",
        .{ pass, package_bytes, cached.pressure_drains, cached.evictions },
    );
}

// ---- family 3: dirty-flag matrix -------------------------------------------

fn runDirtyMatrix(allocator: std.mem.Allocator, meta: mkfs.Meta) !void {
    const image = try formatFresh(allocator, meta, 24 * 1024 * 1024);
    defer allocator.free(image);
    var dev = RamDevice{ .image = image };
    var v = openVolume(&dev) orelse return fail("dirty: mount failed", .{});
    vol.flush_budget = null;

    if (vol.isDirty(&v) orelse true) fail("dirty: fresh volume not clean", .{});
    if (!vol.setDirty(&v, true)) fail("dirty: set failed", .{});
    if (!(vol.isDirty(&v) orelse false)) fail("dirty: flag not set", .{});

    // Durable across remount.
    var dev2 = RamDevice{ .image = image };
    var v2 = openVolume(&dev2) orelse return fail("dirty: remount failed", .{});
    if (!(vol.isDirty(&v2) orelse false)) fail("dirty: flag lost across remount", .{});

    // A completed operation bracket cleans the volume.
    if (vol.createFile(&v2, ntfs.MFT_RECORD_ROOT, "CLEAN.TXT", "clean again") != .ok) {
        fail("dirty: clean op failed", .{});
    }
    if (vol.isDirty(&v2) orelse true) fail("dirty: flag not cleared by complete bracket", .{});
    std.debug.print("hardening dirty matrix: ok\n", .{});
}

// ---- family 5: metadata-cache invalidation (0.75.7) -----------------------

fn cacheEntryCount(summary: vol.MetadataCacheSummary) u32 {
    return summary.record_entries + summary.attribute_entries + summary.index_entries + summary.path_entries;
}

fn runMetadataInvalidation(allocator: std.mem.Allocator, meta: mkfs.Meta) !void {
    const image = try formatFresh(allocator, meta, 24 * 1024 * 1024);
    defer allocator.free(image);
    var dev = RamDevice{ .image = image };
    var metadata_cache = vol.MetadataCache{};
    var v = openVolumeWithCache(&dev, &metadata_cache) orelse return fail("metadata cache: mount failed", .{});
    vol.flush_budget = null;
    const root = ntfs.MFT_RECORD_ROOT;

    var expected: [16384]u8 = undefined;
    const initial_len: usize = 8192;
    const append_len: usize = 5000;
    patternFill(0x7510, expected[0..initial_len]);
    if (vol.createFile(&v, root, "PAYLOAD.BIN", expected[0..initial_len]) != .ok)
        return fail("metadata cache: payload create failed", .{});
    if (vol.createFile(&v, root, "KEEP.TXT", "unrelated-cache-sentinel") != .ok)
        return fail("metadata cache: sentinel create failed", .{});

    const payload = vol.lookupInDirectory(&v, root, "PAYLOAD.BIN") orelse
        return fail("metadata cache: initial lookup failed", .{});
    _ = vol.lookupInDirectory(&v, root, "PAYLOAD.BIN") orelse
        return fail("metadata cache: repeated initial lookup failed", .{});
    if (!readAndCheck(&v, root, "PAYLOAD.BIN", expected[0..initial_len]) or
        !readAndCheck(&v, root, "KEEP.TXT", "unrelated-cache-sentinel") or
        !readAndCheck(&v, root, "KEEP.TXT", "unrelated-cache-sentinel"))
    {
        return fail("metadata cache: warmup read failed", .{});
    }

    const before_payload = metadata_cache.summary();
    var patch_data: [512]u8 = undefined;
    patternFill(0x7520, patch_data[0..]);
    if (vol.writeFileAt(&v, payload.record, 1024, patch_data[0..]) != .ok)
        return fail("metadata cache: in-place write failed", .{});
    @memcpy(expected[1024 .. 1024 + patch_data.len], patch_data[0..]);
    const after_payload = metadata_cache.summary();
    const payload_retained = after_payload.payload_write_retentions > before_payload.payload_write_retentions and
        after_payload.targeted_invalidations == before_payload.targeted_invalidations and
        after_payload.global_mutation_invalidations == before_payload.global_mutation_invalidations and
        after_payload.content_generation == before_payload.content_generation and
        cacheEntryCount(after_payload) == cacheEntryCount(before_payload);
    if (!payload_retained or !readAndCheck(&v, root, "PAYLOAD.BIN", expected[0..initial_len]) or
        !readAndCheck(&v, root, "KEEP.TXT", "unrelated-cache-sentinel"))
    {
        return fail("metadata cache: pure payload write discarded or corrupted cached metadata", .{});
    }

    const before_append = metadata_cache.summary();
    patternFill(0x7530, expected[initial_len .. initial_len + append_len]);
    if (vol.appendFileAtOffset(&v, root, "PAYLOAD.BIN", initial_len, expected[initial_len .. initial_len + append_len]) != .ok)
        return fail("metadata cache: append/resize failed", .{});
    const after_append = metadata_cache.summary();
    const resized = vol.lookupInDirectory(&v, root, "PAYLOAD.BIN") orelse
        return fail("metadata cache: resized lookup failed", .{});
    const resize_ok = resized.entry.size == initial_len + append_len and
        after_append.payload_write_retentions > before_append.payload_write_retentions and
        after_append.targeted_invalidations > before_append.targeted_invalidations and
        after_append.global_mutation_invalidations == before_append.global_mutation_invalidations and
        after_append.recovery_invalidations == before_append.recovery_invalidations and
        after_append.content_generation == before_append.content_generation and
        readAndCheck(&v, root, "PAYLOAD.BIN", expected[0 .. initial_len + append_len]);
    if (!resize_ok) return fail("metadata cache: stale append/resize metadata", .{});

    const before_rename = metadata_cache.summary();
    if (vol.renameEntry(&v, root, "PAYLOAD.BIN", root, "RENAMED.BIN") != .ok)
        return fail("metadata cache: rename failed", .{});
    const after_rename = metadata_cache.summary();
    const old_absent = vol.lookupInDirectory(&v, root, "PAYLOAD.BIN") == null;
    const renamed = vol.lookupInDirectory(&v, root, "RENAMED.BIN") orelse
        return fail("metadata cache: renamed lookup failed", .{});
    const rename_ok = old_absent and renamed.entry.size == initial_len + append_len and
        after_rename.targeted_invalidations > before_rename.targeted_invalidations and
        after_rename.global_mutation_invalidations == before_rename.global_mutation_invalidations and
        after_rename.recovery_invalidations == before_rename.recovery_invalidations and
        after_rename.content_generation == before_rename.content_generation and
        readAndCheck(&v, root, "RENAMED.BIN", expected[0 .. initial_len + append_len]);
    if (!rename_ok) return fail("metadata cache: stale rename metadata", .{});

    _ = vol.lookupInDirectory(&v, root, "RENAMED.BIN") orelse
        return fail("metadata cache: pre-delete lookup failed", .{});
    const before_delete = metadata_cache.summary();
    if (vol.deleteFile(&v, root, "RENAMED.BIN") != .ok)
        return fail("metadata cache: delete failed", .{});
    const after_delete = metadata_cache.summary();
    const delete_ok = vol.lookupInDirectory(&v, root, "RENAMED.BIN") == null and
        vol.lookupInDirectory(&v, root, "RENAMED.BIN") == null and
        after_delete.targeted_invalidations > before_delete.targeted_invalidations and
        after_delete.global_mutation_invalidations == before_delete.global_mutation_invalidations and
        after_delete.recovery_invalidations == before_delete.recovery_invalidations and
        after_delete.content_generation == before_delete.content_generation;
    if (!delete_ok) return fail("metadata cache: stale delete metadata", .{});

    if (!readAndCheck(&v, root, "KEEP.TXT", "unrelated-cache-sentinel"))
        return fail("metadata cache: sentinel missing before recovery", .{});
    const before_recovery = metadata_cache.summary();
    if (vol.abortWriteForTest(&v, .io) != .io)
        return fail("metadata cache: recovery seam changed status", .{});
    const after_recovery = metadata_cache.summary();
    const recovery_ok = after_recovery.recovery_invalidations > before_recovery.recovery_invalidations and
        after_recovery.global_mutation_invalidations > before_recovery.global_mutation_invalidations and
        after_recovery.content_generation > before_recovery.content_generation and
        readAndCheck(&v, root, "KEEP.TXT", "unrelated-cache-sentinel");
    if (!recovery_ok) return fail("metadata cache: recovery did not reject stale entries", .{});

    const final = metadata_cache.summary();
    const invalidated_parts = final.mutation_invalidated_record_entries +
        final.mutation_invalidated_attribute_entries +
        final.mutation_invalidated_index_entries +
        final.mutation_invalidated_path_entries;
    const counters_ok = final.version == 2 and
        final.targeted_invalidations == final.targeted_record_invalidations +
            final.targeted_attribute_invalidations + final.targeted_directory_invalidations and
        final.global_mutation_invalidations >= final.recovery_invalidations and
        invalidated_parts > 0 and invalidated_parts <= final.invalidated_entries;
    if (!counters_ok) return fail("metadata cache: counter invariants failed", .{});

    std.debug.print(
        "hardening metadata cache: ok (payload-keep={d}, system-keep={d}, targeted={d}/{d}/{d}, global={d}, recovery={d}, invalidated={d})\n",
        .{
            final.payload_write_retentions,
            final.system_write_retentions,
            final.targeted_record_invalidations,
            final.targeted_attribute_invalidations,
            final.targeted_directory_invalidations,
            final.global_mutation_invalidations,
            final.recovery_invalidations,
            invalidated_parts,
        },
    );
}

// ---- main ------------------------------------------------------------------

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io = init.io;
    const cwd = std.Io.Dir.cwd();
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len == 4 and std.mem.eql(u8, args[1], "--production-image")) {
        const passes = try std.fmt.parseInt(usize, args[3], 10);
        try runCachedProductionImage(allocator, io, cwd, args[2], passes);
        if (failures != 0) {
            std.debug.print("NTFSHARDEN result: FAILED ({d})\n", .{failures});
            std.process.exit(1);
        }
        std.debug.print("NTFSHARDEN result: OK\n", .{});
        return;
    }
    if (args.len < 4 or args.len > 6) {
        std.debug.print("Usage: CheckNtfsHardening0611 <meta-dir> <churn-ops> <crash-runs> [out-churn-disk.img] [out-crashed-disk.img]\n       CheckNtfsHardening0611 --production-image <disk.img> <passes>\n", .{});
        std.process.exit(2);
    }
    const churn_ops = try std.fmt.parseInt(usize, args[2], 10);
    const crash_runs = try std.fmt.parseInt(usize, args[3], 10);
    const out_path: ?[]const u8 = if (args.len >= 5) args[4] else null;
    const crashed_out: ?[]const u8 = if (args.len == 6) args[5] else null;
    var meta_dir = try cwd.openDir(io, args[1], .{});
    defer meta_dir.close(io);
    const meta = try loadMeta(allocator, io, meta_dir);

    try runLongChurn(allocator, meta, churn_ops, out_path, io, cwd);
    try runCrashSweep(allocator, meta, crash_runs, crashed_out, io, cwd);
    try runDeferredStream(allocator, meta);
    try runCachedPackageCopy(allocator, meta);
    try runDirtyMatrix(allocator, meta);
    try runMetadataInvalidation(allocator, meta);

    if (failures != 0) {
        std.debug.print("NTFSHARDEN result: FAILED ({d})\n", .{failures});
        std.process.exit(1);
    }
    std.debug.print("NTFSHARDEN result: OK\n", .{});
}
