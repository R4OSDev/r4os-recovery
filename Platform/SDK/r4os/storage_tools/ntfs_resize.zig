//! Offline NTFS 3.1 growth and free-tail shrink. All policy, planning and metadata editing stays
//! in userland. The caller supplies an exclusive whole-device adapter.
const std = @import("std");
const io = @import("io.zig");
const ntfs = @import("../ntfs_format.zig");
const partition = @import("partition.zig");
const Hash = std.crypto.hash.sha2.Sha256;
const max_runs = 64;
const max_index_blocks = 128;
const bad_name = &[_]u8{ '$', 0, 'B', 0, 'a', 0, 'd', 0 };
const bitmap_name = &[_]u8{ '$', 0, 'B', 0, 'i', 0, 't', 0, 'm', 0, 'a', 0, 'p', 0 };

fn get(comptime T: type, data: []const u8, at: usize) T {
    return std.mem.readInt(T, data[at..][0..@sizeOf(T)], .little);
}
fn put(comptime T: type, data: []u8, at: usize, value: T) void {
    std.mem.writeInt(T, data[at..][0..@sizeOf(T)], value, .little);
}
fn digest(bytes: []const u8) [32]u8 {
    var result: [32]u8 = undefined;
    Hash.hash(bytes, &result, .{});
    return result;
}
fn offset(parent: []const u8, child: []const u8) usize {
    return @intFromPtr(child.ptr) - @intFromPtr(parent.ptr);
}

const Map = struct {
    runs: [max_runs]ntfs.Run = undefined,
    count: usize = 0,
    clusters: u64 = 0,
    bytes: u64 = 0,

    fn parse(attr: ntfs.Attribute, total: u64, sparse: bool) !Map {
        if (!attr.non_resident or attr.lowest_vcn != 0 or attr.compression_unit != 0 or
            attr.isCompressed() or attr.isEncrypted() or (!sparse and attr.flags != 0) or
            attr.initialized_size > attr.data_size or attr.data_size > total * 4096)
            return error.UnsupportedNtfs;
        var self = Map{ .bytes = attr.data_size };
        var iter = ntfs.RunlistIterator.init(attr.mapping_pairs);
        while (iter.next()) |run| {
            if (self.count == max_runs or run.length_clusters > total - self.clusters) return error.UnsupportedNtfs;
            if (run.lcn) |lcn| {
                if (sparse or lcn >= total or run.length_clusters > total - lcn) return error.UnsupportedNtfs;
                for (self.runs[0..self.count]) |old| {
                    if (lcn < old.lcn.? + old.length_clusters and old.lcn.? < lcn + run.length_clusters)
                        return error.CorruptNtfs;
                }
            } else if (!sparse) return error.UnsupportedNtfs;
            self.runs[self.count] = run;
            self.count += 1;
            self.clusters += run.length_clusters;
        }
        if (iter.hadError() or self.count == 0 or iter.offset >= iter.mapping.len or iter.mapping[iter.offset] != 0 or
            attr.highest_vcn != self.clusters - 1 or attr.data_size > self.clusters * 4096 or
            (!sparse and (attr.allocated_size != self.clusters * 4096 or attr.initialized_size != attr.data_size)))
            return error.UnsupportedNtfs;
        return self;
    }
    fn lba(self: *const Map, byte_offset: u64, byte_count: usize) !u64 {
        if (byte_offset % 512 != 0 or byte_count % 512 != 0) return error.Geometry;
        var relative = byte_offset;
        for (self.runs[0..self.count]) |run| {
            const bytes = run.length_clusters * 4096;
            if (relative < bytes) {
                if (byte_count > bytes - relative) return error.UnsupportedNtfs;
                return (run.lcn orelse return error.UnsupportedNtfs) * 8 + relative / 512;
            }
            relative -= bytes;
        }
        return error.CorruptNtfs;
    }
    fn read(self: *const Map, device: io.Device, byte_offset: u64, out: []u8) !void {
        if (byte_offset % 512 != 0 or out.len % 512 != 0) return error.Geometry;
        var done: usize = 0;
        while (done < out.len) {
            var relative = byte_offset + done;
            var found = false;
            for (self.runs[0..self.count]) |run| {
                const bytes = run.length_clusters * 4096;
                if (relative >= bytes) {
                    relative -= bytes;
                    continue;
                }
                const count: usize = @intCast(@min(out.len - done, bytes - relative));
                try device.read((run.lcn orelse return error.UnsupportedNtfs) * 8 + relative / 512, out[done..][0..count]);
                done += count;
                found = true;
                break;
            }
            if (!found) return error.CorruptNtfs;
        }
    }
    fn owns(self: *const Map, cluster: u64) bool {
        for (self.runs[0..self.count]) |run| {
            const lcn = run.lcn orelse continue;
            if (cluster >= lcn and cluster - lcn < run.length_clusters) return true;
        }
        return false;
    }
};

const Source = struct { lba: u64, count: u32, sha: [32]u8 };
const Patch = struct { lba: u64, length: usize, bytes: [4096]u8 = undefined };

/// Heap-owned bounded plan (no allocation proportional to volume size).
/// Bitmap data is copied/transformed in caller-owned blocks during execute.
pub const ShrinkLimits = struct {
    maximum_sectors: u64 = 0,
    minimum_sectors: u64 = 0,
    highest_fixed_cluster: u64 = 0,
    bitmap_lcn: ?u64 = null,
};

pub const Plan = struct {
    allocator: std.mem.Allocator,
    first: u64,
    old_sectors: u64,
    new_sectors: u64,
    number: u32,
    old_clusters: u64,
    new_clusters: u64,
    bitmap_lcn: u64,
    bitmap_bytes: u64,
    bitmap_clusters: u64,
    bitmap: Map = .{},
    shrink: ShrinkLimits = .{},
    bitmap_sha: [32]u8 = undefined,
    mft: Map = .{},
    mft_sha: ?[32]u8 = null,
    mirror_lcn: u64 = 0,
    bitmap_sequence: u16 = 0,
    sources: [max_index_blocks + 24]Source = undefined,
    source_count: usize = 0,
    patches: [4]Patch = undefined,
    patch_count: usize = 0,
    clean_volume: [1024]u8 = undefined,
    dirty_volume: [1024]u8 = undefined,
    volume_lba: u64 = 0,
    boot: [512]u8 = undefined,

    pub fn deinit(self: *Plan) void {
        self.allocator.destroy(self);
    }

    /// `layout` has exactly this partition's proposed end, or the unchanged
    /// end for a read-only SHRINK QUERYMAX plan (execute rejects that plan).
    /// The old target geometry comes from the current storage inventory.
    pub fn prepare(allocator: std.mem.Allocator, disk: io.Device, layout: *partition.Plan, number: u32, old_sectors: u64, work: []u8) !*Plan {
        try layout.validate();
        const entry = try layout.get(number);
        if (work.len < 32768 or work.len % 1024 != 0 or entry.count < 32768 or old_sectors < 32768 or
            entry.count > std.math.maxInt(u64) / 512 or
            (layout.kind == .gpt and !partition.guid.eql(entry.type_guid, partition.basic_type)) or
            (layout.kind == .mbr and entry.mbr_type != 7)) return error.UnsupportedNtfs;
        const self = try allocator.create(Plan);
        errdefer allocator.destroy(self);
        self.* = .{
            .allocator = allocator,
            .first = entry.first,
            .old_sectors = old_sectors,
            .new_sectors = entry.count,
            .number = number,
            .old_clusters = (old_sectors - 1) / 8,
            .new_clusters = (entry.count - 1) / 8,
            .bitmap_lcn = (old_sectors + 7) / 8,
            .bitmap_bytes = std.mem.alignForward(u64, ((entry.count - 1) / 8 + 7) / 8, 8),
            .bitmap_clusters = 0,
        };
        self.bitmap_clusters = (self.bitmap_bytes + 4095) / 4096;
        if (self.new_sectors > self.old_sectors and
            (self.bitmap_lcn >= self.new_clusters or self.bitmap_clusters > self.new_clusters - self.bitmap_lcn)) return error.NoSpace;
        var region = io.Region{ .parent = disk, .first = self.first, .count = old_sectors };
        const volume = try region.device();
        try self.readSource(volume, 0, &self.boot);
        try self.readSource(volume, old_sectors - 1, work[0..512]);
        var boot: ntfs.BootSector = undefined;
        if (!std.mem.eql(u8, &self.boot, work[0..512]) or ntfs.BootSector.parse(&self.boot, &boot) != .ok)
            return error.CorruptNtfs;
        if (boot.bytes_per_sector != 512 or boot.cluster_bytes != 4096 or boot.file_record_bytes != 1024 or
            boot.index_block_bytes != 4096 or boot.total_sectors != old_sectors - 1 or get(u32, &self.boot, 0x50) != 0 or
            boot.mft_lcn >= self.old_clusters or boot.mftmirr_lcn >= self.old_clusters) return error.UnsupportedNtfs;
        self.mirror_lcn = boot.mftmirr_lcn;
        try self.readSource(volume, boot.mft_lcn * 8, work[0..1024]);
        try decodeRecord(work[0..1024], 0);
        self.mft = try Map.parse(try attribute(work[0..1024], .data, ""), self.old_clusters, false);
        if (self.mft.bytes < 16 * 1024 or self.mft.runs[0].lcn.? != boot.mft_lcn) return error.CorruptNtfs;
        // Validate and compare the four mirrored records before editing any.
        for (0..4) |record_number| {
            const lba = try self.record(volume, @intCast(record_number), work[0..1024]);
            try self.readSource(volume, self.mirror_lcn * 8 + record_number * 2, work[1024..2048]);
            try decodeRecord(work[1024..2048], @intCast(record_number));
            // USA sequence stamps may differ, decoded record content may not.
            const old_usn = get(u16, work, get(u16, work, 4));
            normaliseUsa(work[0..1024]);
            normaliseUsa(work[1024..2048]);
            if (!std.mem.eql(u8, work[0..1024], work[1024..2048])) return error.CorruptNtfs;
            if (record_number == 1) {
                const mirror = try Map.parse(try attribute(work[0..1024], .data, ""), self.old_clusters, false);
                if (mirror.count != 1 or mirror.runs[0].lcn.? != self.mirror_lcn or mirror.clusters != 1 or mirror.bytes != 4096)
                    return error.UnsupportedNtfs;
            }
            if (record_number == 3) {
                const info = try attribute(work[0..1024], .volume_information, "");
                if (info.non_resident or info.value.len != 12 or info.value[8] != 3 or info.value[9] != 1)
                    return error.UnsupportedNtfs;
                if (get(u16, info.value, 10) != 0) return error.DirtyNtfs;
                self.volume_lba = lba;
                @memcpy(&self.clean_volume, work[0..1024]);
                @memcpy(&self.dirty_volume, work[0..1024]);
                put(u16, &self.dirty_volume, offset(work[0..1024], info.value) + 10, ntfs.VOLUME_FLAG_DIRTY);
                put(u16, &self.clean_volume, get(u16, &self.clean_volume, 4), old_usn +% 1);
                put(u16, &self.dirty_volume, get(u16, &self.dirty_volume, 4), old_usn);
                try encodeRecord(&self.clean_volume);
                try encodeRecord(&self.dirty_volume);
            }
        }
        const bitmap_lba = try self.record(volume, 6, work[0..1024]);
        self.bitmap_sequence = get(u16, work, 0x10);
        self.bitmap = try Map.parse(try attribute(work[0..1024], .data, ""), self.old_clusters, false);
        if (self.bitmap.bytes != std.mem.alignForward(u64, (self.old_clusters + 7) / 8, 8)) return error.UnsupportedNtfs;
        for (self.bitmap.runs[0..self.bitmap.count]) |run| {
            for (self.mft.runs[0..self.mft.count]) |mft_run| {
                if (overlap(run.lcn.?, run.length_clusters, mft_run.lcn.?, mft_run.length_clusters)) return error.CorruptNtfs;
            }
            if (overlap(run.lcn.?, run.length_clusters, self.mirror_lcn, 1) or run.lcn.? < 2) return error.CorruptNtfs;
        }
        if (self.new_sectors <= self.old_sectors) {
            // Query and execution share the same concrete placement and bound.
            // Keep the old bitmap allocation capacity to make the query exact
            // without an iterative, size-dependent allocation search.
            self.shrink = try self.querySpace(volume, work[4096..]);
            self.bitmap_clusters = self.bitmap.clusters;
            self.bitmap_lcn = self.shrink.bitmap_lcn orelse self.bitmap.runs[0].lcn.?;
            if (self.new_sectors < self.old_sectors and
                (self.shrink.bitmap_lcn == null or self.new_sectors < self.shrink.minimum_sectors)) return error.ShrinkLimit;
        } else {
            // Growth also retires the old bitmap. Verify that no other file
            // maps those clusters before freeing them in the replacement.
            var fixed = ShrinkLimits{ .bitmap_lcn = self.bitmap_lcn };
            try self.inspectFixedRuns(volume, work[4096..], &fixed);
        }
        try replaceData(work[0..1024], "", self.bitmap_lcn, self.bitmap_clusters, self.bitmap_bytes, false);
        try self.updateBitmapNames(work[0..1024]);
        try self.addPatch(bitmap_lba, work[0..1024]);
        const bad_lba = try self.record(volume, 8, work[0..1024]);
        const bad = try attribute(work[0..1024], .data, bad_name);
        const bad_map = try Map.parse(bad, self.old_clusters, true);
        if (bad_map.clusters != self.old_clusters or bad.data_size != self.old_clusters * 4096 or
            bad.initialized_size != 0 or bad.flags != 0 or bad.allocated_size != bad.data_size) return error.UnsupportedNtfs;
        try replaceData(work[0..1024], bad_name, null, self.new_clusters, self.new_clusters * 4096, true);
        try self.addPatch(bad_lba, work[0..1024]);
        try self.prepareRoot(volume, work);
        const validated_bitmap = try self.hashBitmap(volume, work, true);
        if (self.new_sectors <= self.old_sectors and !std.mem.eql(u8, &validated_bitmap, &self.bitmap_sha)) return error.Stale;
        self.bitmap_sha = validated_bitmap;
        put(u64, &self.boot, 0x28, self.new_sectors - 1);
        // Bind every parsed byte to a second read, even on a still-mounted
        // preflight target. Revalidation repeats this after exclusive unmount.
        try self.revalidate(volume, work);
        try layout.revalidate(disk, work);
        return self;
    }

    fn querySpace(self: *Plan, device: io.Device, work: []u8) !ShrinkLimits {
        var result = ShrinkLimits{ .minimum_sectors = self.old_sectors };
        var hash = Hash.init(.{});
        var done: u64 = 0;
        var free_start: u64 = 0;
        var free_count: u64 = 0;
        const padded = std.mem.alignForward(u64, self.bitmap.bytes, 512);
        while (done < padded) {
            const bytes = work[0..@intCast(@min(work.len, padded - done))];
            try self.bitmap.read(device, done, bytes);
            hash.update(bytes); // Fingerprint the bytes used to derive the bound.
            const base = done * 8;
            if (result.bitmap_lcn == null) {
                for (bytes, 0..) |byte, i| {
                    const cluster = base + i * 8;
                    if (cluster >= self.old_clusters) break;
                    if (byte == 0 and cluster + 8 <= self.old_clusters) {
                        if (free_count == 0) free_start = cluster;
                        free_count += 8;
                        if (free_count >= self.bitmap.clusters) {
                            result.bitmap_lcn = free_start;
                            break;
                        }
                    } else {
                        for (0..8) |b| {
                            if (cluster + b >= self.old_clusters) break;
                            if (byte & (@as(u8, 1) << @intCast(b)) != 0) {
                                free_count = 0;
                            } else {
                                if (free_count == 0) free_start = cluster + b;
                                free_count += 1;
                                if (free_count >= self.bitmap.clusters) {
                                    result.bitmap_lcn = free_start;
                                    break;
                                }
                            }
                        }
                        if (result.bitmap_lcn != null) break;
                    }
                }
            }
            // Only $Bitmap can move. Other allocations, including fragmented
            // files and unknown file attributes, remain fixed at their LCNs.
            for (self.bitmap.runs[0..self.bitmap.count]) |run|
                changeRange(bytes, base, run.lcn.?, run.lcn.? + run.length_clusters, false);
            changeRange(bytes, base, self.old_clusters, base + bytes.len * 8, false);
            for (bytes, 0..) |byte, i| {
                if (byte != 0) result.highest_fixed_cluster = base + i * 8 + 7 - @as(u64, @clz(byte));
            }
            done += bytes.len;
        }
        self.bitmap_sha = hash.finalResult();
        try self.inspectFixedRuns(device, work, &result);
        if (result.bitmap_lcn) |lcn| {
            const needed_clusters = @max(result.highest_fixed_cluster + 1, lcn + self.bitmap.clusters);
            const needed_sectors = @max(needed_clusters * 8 + 1, 32768);
            if (needed_sectors < self.old_sectors) {
                result.maximum_sectors = (self.old_sectors - needed_sectors) / partition.alignment_sectors * partition.alignment_sectors;
                result.minimum_sectors = self.old_sectors - result.maximum_sectors;
            }
        }
        return result;
    }

    fn inspectFixedRuns(self: *Plan, device: io.Device, work: []u8, result: *ShrinkLimits) !void {
        if (self.mft.bytes % 1024 != 0 or self.mft.bytes / 1024 > 1024 * 1024) return error.UnsupportedNtfs;
        var hash = Hash.init(.{});
        const record_bytes = work[0..1024];
        var checker = BitmapCheck{ .map = &self.bitmap, .device = device, .scratch = work[1024..] };
        for (0..@intCast(self.mft.bytes / 1024)) |number| {
            try self.mft.read(device, number * 1024, record_bytes);
            hash.update(record_bytes);
            if (get(u16, record_bytes, 0x16) & ntfs.RECORD_IN_USE == 0) continue;
            try decodeRecord(record_bytes, @intCast(number));
            const header = ntfs.FileRecordHeader.parse(record_bytes).?;
            var attrs = ntfs.AttributeIterator.init(record_bytes[0..header.bytes_in_use], header);
            while (attrs.next()) |attr| {
                if (!attr.non_resident) continue;
                if (attr.lowest_vcn != 0) return error.UnsupportedNtfs;
                var runs = ntfs.RunlistIterator.init(attr.mapping_pairs);
                var clusters: u64 = 0;
                var count: usize = 0;
                while (runs.next()) |run| {
                    count += 1;
                    if (count > 256) return error.UnsupportedNtfs;
                    clusters = std.math.add(u64, clusters, run.length_clusters) catch return error.CorruptNtfs;
                    const lcn = run.lcn orelse continue;
                    if (lcn >= self.old_clusters or run.length_clusters > self.old_clusters - lcn) return error.CorruptNtfs;
                    try checker.allocated(lcn, run.length_clusters);
                    if (number == 6 and attr.attr_type == @intFromEnum(ntfs.AttrType.data) and attr.name.len == 0) continue;
                    for (self.bitmap.runs[0..self.bitmap.count]) |bitmap_run| {
                        if (overlap(lcn, run.length_clusters, bitmap_run.lcn.?, bitmap_run.length_clusters)) return error.CorruptNtfs;
                    }
                    result.highest_fixed_cluster = @max(result.highest_fixed_cluster, lcn + run.length_clusters - 1);
                    if (result.bitmap_lcn) |destination| {
                        if (overlap(destination, self.bitmap.clusters, lcn, run.length_clusters)) return error.CorruptNtfs;
                    }
                }
                if (runs.hadError() or count == 0 or runs.offset >= runs.mapping.len or runs.mapping[runs.offset] != 0 or
                    clusters == 0 or attr.highest_vcn != clusters - 1) return error.CorruptNtfs;
            }
        }
        self.mft_sha = hash.finalResult();
    }
    fn hashMft(self: *const Plan, device: io.Device, work: []u8) ![32]u8 {
        var hash = Hash.init(.{});
        var at: u64 = 0;
        while (at < self.mft.bytes) {
            const bytes = work[0..@intCast(@min(work.len, self.mft.bytes - at))];
            try self.mft.read(device, at, bytes);
            hash.update(bytes);
            at += bytes.len;
        }
        return hash.finalResult();
    }

    fn readSource(self: *Plan, device: io.Device, lba: u64, out: []u8) !void {
        if (self.source_count == self.sources.len) return error.UnsupportedNtfs;
        try device.read(lba, out);
        self.sources[self.source_count] = .{ .lba = lba, .count = @intCast(out.len / 512), .sha = digest(out) };
        self.source_count += 1;
    }
    fn record(self: *Plan, device: io.Device, number: u32, out: []u8) !u64 {
        const lba = try self.mft.lba(@as(u64, number) * 1024, 1024);
        try self.readSource(device, lba, out);
        try decodeRecord(out, number);
        return lba;
    }
    fn addPatch(self: *Plan, lba: u64, bytes: []u8) !void {
        if (self.patch_count == self.patches.len or bytes.len > 4096) return error.UnsupportedNtfs;
        for (self.patches[0..self.patch_count]) |patch| {
            if (overlap(lba, bytes.len / 512, patch.lba, patch.length / 512)) return error.CorruptNtfs;
        }
        try encodeRecord(bytes);
        self.patches[self.patch_count] = .{ .lba = lba, .length = bytes.len };
        @memcpy(self.patches[self.patch_count].bytes[0..bytes.len], bytes);
        self.patch_count += 1;
    }
    fn updateBitmapNames(self: *Plan, bytes: []u8) !void {
        const header = ntfs.FileRecordHeader.parse(bytes) orelse return error.CorruptNtfs;
        var attrs = ntfs.AttributeIterator.init(bytes, header);
        var found: usize = 0;
        while (attrs.next()) |attr| {
            if (attr.attr_type != @intFromEnum(ntfs.AttrType.file_name)) continue;
            if (attr.non_resident) return error.UnsupportedNtfs;
            const name = ntfs.FileName.parse(attr.value) orelse return error.CorruptNtfs;
            if (name.parent.record != 5 or !std.mem.eql(u8, name.name, bitmap_name) or
                name.allocated_size != self.bitmap.clusters * 4096 or name.data_size != self.bitmap.bytes)
                return error.UnsupportedNtfs;
            self.setNameSizes(bytes[offset(bytes, attr.value)..]);
            found += 1;
        }
        if (found != 1) return error.UnsupportedNtfs;
    }
    fn setNameSizes(self: *const Plan, bytes: []u8) void {
        put(u64, bytes, 0x28, self.bitmap_clusters * 4096);
        put(u64, bytes, 0x30, self.bitmap_bytes);
    }
    fn editEntries(self: *Plan, all: []u8, entries: []const u8, children: *[max_index_blocks]bool, parents: *[max_index_blocks]u16, parent: u16) !usize {
        var iter = ntfs.IndexEntryIterator.init(entries);
        var found: usize = 0;
        var end = false;
        while (iter.next()) |entry| {
            if (entry.flags & ~(ntfs.INDEX_ENTRY_NODE | ntfs.INDEX_ENTRY_END) != 0 or entry.entry_length % 8 != 0 or
                entry.key.len + 16 + @as(usize, if (entry.hasSubNode()) 8 else 0) > entry.entry_length) return error.CorruptNtfs;
            if (entry.sub_node_vcn) |vcn| {
                if (vcn >= max_index_blocks or children[@intCast(vcn)]) return error.CorruptNtfs;
                children[@intCast(vcn)] = true;
                parents[@intCast(vcn)] = parent;
            }
            if (entry.isEnd()) {
                end = true;
                break;
            }
            const name = entry.fileName() orelse return error.CorruptNtfs;
            const reference = ntfs.FileReference.parse(entry.file_reference);
            if (reference.record == 6) {
                if (reference.sequence != self.bitmap_sequence or name.parent.record != 5 or
                    !std.mem.eql(u8, name.name, bitmap_name) or name.allocated_size != self.bitmap.clusters * 4096 or
                    name.data_size != self.bitmap.bytes) return error.CorruptNtfs;
                self.setNameSizes(all[offset(all, entry.key)..]);
                found += 1;
            }
        }
        if (!end or iter.offset != entries.len) return error.CorruptNtfs;
        return found;
    }
    fn prepareRoot(self: *Plan, volume: io.Device, work: []u8) !void {
        const root_record = work[0..1024];
        const root_lba = try self.record(volume, 5, root_record);
        const attr = try attribute(root_record, .index_root, &ntfs.I30_NAME_UTF16);
        if (attr.non_resident) return error.UnsupportedNtfs;
        const root = ntfs.IndexRoot.parse(attr.value) orelse return error.CorruptNtfs;
        if (root.indexed_attr_type != @intFromEnum(ntfs.AttrType.file_name) or root.collation_rule != 1 or root.index_block_bytes != 4096)
            return error.UnsupportedNtfs;
        var children: [max_index_blocks]bool = .{false} ** max_index_blocks;
        var active: [max_index_blocks]bool = .{false} ** max_index_blocks;
        var parents: [max_index_blocks]u16 = undefined;
        var found = try self.editEntries(root_record, root.entries, &children, &parents, max_index_blocks);
        if (root.header.hasSubNodes()) {
            const index = try Map.parse(try attribute(root_record, .index_allocation, &ntfs.I30_NAME_UTF16), self.old_clusters, false);
            if (index.bytes > max_index_blocks * 4096 or index.bytes % 4096 != 0) return error.UnsupportedNtfs;
            const bitmap = try attribute(root_record, .bitmap, &ntfs.I30_NAME_UTF16);
            if (bitmap.non_resident or bitmap.value.len > max_index_blocks / 8 or bitmap.value.len * 8 < index.bytes / 4096)
                return error.UnsupportedNtfs;
            for (0..bitmap.value.len * 8) |i| active[i] = bitmap.value[i / 8] & (@as(u8, 1) << @intCast(i % 8)) != 0;
            for (active, 0..) |live, i| {
                if (!live) continue;
                if (i >= index.bytes / 4096) return error.CorruptNtfs;
                const lba = try index.lba(i * 4096, 4096);
                if (self.bitmap.owns(lba / 8) or self.mft.owns(lba / 8) or lba / 8 == self.mirror_lcn or lba < 16) return error.CorruptNtfs;
                const bytes = work[4096..8192];
                try self.readSource(volume, lba, bytes);
                try decodeFixups(bytes);
                const block = ntfs.IndexBlock.parse(bytes) orelse return error.CorruptNtfs;
                if (block.vcn != i) return error.CorruptNtfs;
                const changed = try self.editEntries(bytes, block.entries, &children, &parents, @intCast(i));
                if (changed != 0) try self.addPatch(lba, bytes);
                found += changed;
            }
        }
        if (!std.mem.eql(bool, &active, &children) or found != 1) return error.CorruptNtfs;
        for (active, 0..) |live, i| {
            if (!live) continue;
            var node = i;
            var depth: usize = 0;
            while (node != max_index_blocks) {
                if (node >= max_index_blocks or !active[node] or depth == max_index_blocks) return error.CorruptNtfs;
                node = parents[node];
                depth += 1;
            }
        }
        // Exactly one index node contains $Bitmap. A resident root is edited
        // only when it contains that entry; unchanged root bytes stay intact.
        if (self.patch_count == 2) try self.addPatch(root_lba, root_record);
    }

    fn hashBitmap(self: *const Plan, device: io.Device, work: []u8, validate: bool) ![32]u8 {
        var hash = Hash.init(.{});
        var done: u64 = 0;
        const padded = std.mem.alignForward(u64, self.bitmap.bytes, 512);
        var owned: u64 = 0;
        while (done < padded) {
            const bytes = work[0..@intCast(@min(work.len, padded - done))];
            try self.bitmap.read(device, done, bytes);
            hash.update(bytes);
            if (validate) {
                const base = done * 8;
                const last = base + bytes.len * 8;
                try expectSetRange(bytes, base, self.old_clusters, self.bitmap.bytes * 8);
                for (self.bitmap.runs[0..self.bitmap.count]) |run| {
                    const first = @max(base, run.lcn.?);
                    const end = @min(last, run.lcn.? + run.length_clusters);
                    if (first < end) {
                        try expectSetRange(bytes, base, first, end);
                        owned += end - first;
                    }
                }
            }
            done += bytes.len;
        }
        if (validate and owned != self.bitmap.clusters) return error.CorruptNtfs;
        return hash.finalResult();
    }
    fn revalidate(self: *const Plan, device: io.Device, work: []u8) !void {
        for (self.sources[0..self.source_count]) |source| {
            const bytes = work[0 .. source.count * 512];
            try device.read(source.lba, bytes);
            if (!std.mem.eql(u8, &source.sha, &digest(bytes))) return error.Stale;
        }
        if (!std.mem.eql(u8, &self.bitmap_sha, &try self.hashBitmap(device, work, false))) return error.Stale;
        if (self.mft_sha) |expected| {
            if (!std.mem.eql(u8, &expected, &try self.hashMft(device, work))) return error.Stale;
        }
    }
    fn fillBitmap(self: *const Plan, volume: io.Device, at: u64, bytes: []u8) !void {
        @memset(bytes, 0);
        const old_padded = std.mem.alignForward(u64, self.bitmap.bytes, 512);
        if (at < old_padded) try self.bitmap.read(volume, at, bytes[0..@intCast(@min(bytes.len, old_padded - at))]);
        const base = at * 8;
        changeRange(bytes, base, @min(self.old_clusters, self.new_clusters), base + bytes.len * 8, false);
        for (self.bitmap.runs[0..self.bitmap.count]) |run|
            changeRange(bytes, base, run.lcn.?, run.lcn.? + run.length_clusters, false);
        changeRange(bytes, base, self.bitmap_lcn, self.bitmap_lcn + self.bitmap_clusters, true);
        changeRange(bytes, base, self.new_clusters, self.bitmap_bytes * 8, true);
    }

    fn storeVolume(self: *const Plan, volume: io.Device, bytes: []const u8, scratch: []u8) !void {
        try volume.write(self.volume_lba, bytes);
        try volume.write(self.mirror_lcn * 8 + 6, bytes);
        try volume.flush();
        try volume.verify(self.volume_lba, bytes, scratch);
        try volume.verify(self.mirror_lcn * 8 + 6, bytes, scratch);
    }

    pub fn execute(self: *const Plan, disk: io.Device, layout: *const partition.Plan, work: []u8) !void {
        try disk.requireExclusive();
        if (work.len < 32768 or work.len % 1024 != 0 or self.number == 0 or self.number > layout.entry_count or
            self.new_sectors == self.old_sectors or layout.entries[self.number - 1].first != self.first or layout.entries[self.number - 1].count != self.new_sectors)
            return error.Geometry;
        var region = io.Region{ .parent = disk, .first = self.first, .count = @max(self.old_sectors, self.new_sectors) };
        const volume = try region.device();
        try layout.revalidate(disk, work);
        try self.revalidate(volume, work);
        const half = work.len / 2;
        const data = work[0..half];
        const scratch = work[half..];
        volume.phase(.metadata);
        try self.storeVolume(volume, &self.dirty_volume, scratch);
        // A larger table with the old smaller filesystem is recoverable.
        // No rollback/atomicity is promised once metadata writing begins.
        if (self.new_sectors > self.old_sectors) try layout.commit(disk, work);
        if (disk.progress) |p| p.verified = false;
        volume.phase(.metadata);
        var done: u64 = 0;
        while (done < self.bitmap_clusters * 4096) {
            const bytes = data[0..@intCast(@min(data.len, self.bitmap_clusters * 4096 - done))];
            try self.fillBitmap(volume, done, bytes);
            volume.phase(.metadata);
            try volume.write(self.bitmap_lcn * 8 + done / 512, bytes);
            done += bytes.len;
        }
        try volume.flush();
        done = 0;
        while (done < self.bitmap_clusters * 4096) {
            const bytes = data[0..@intCast(@min(data.len, self.bitmap_clusters * 4096 - done))];
            try self.fillBitmap(volume, done, bytes);
            try volume.verify(self.bitmap_lcn * 8 + done / 512, bytes, scratch);
            done += bytes.len;
        }
        for (self.patches[0..self.patch_count]) |*patch| {
            volume.phase(.metadata);
            try volume.write(patch.lba, patch.bytes[0..patch.length]);
        }
        try volume.flush();
        for (self.patches[0..self.patch_count]) |*patch| try volume.verify(patch.lba, patch.bytes[0..patch.length], scratch);
        volume.phase(.backup);
        try volume.write(self.new_sectors - 1, &self.boot);
        try volume.flush();
        try volume.verify(self.new_sectors - 1, &self.boot, scratch);
        volume.phase(.primary);
        try volume.write(0, &self.boot);
        try volume.flush();
        try volume.verify(0, &self.boot, scratch);
        // A smaller filesystem is durable before the partition gives away
        // any tail sectors. A failed table update remains an explicit error.
        if (self.new_sectors < self.old_sectors) {
            try layout.commit(disk, work);
            if (disk.progress) |p| p.verified = false;
        }
        try self.storeVolume(volume, &self.clean_volume, scratch);
        volume.complete();
    }
};

fn overlap(a: u64, an: u64, b: u64, bn: u64) bool {
    return a < b + bn and b < a + an;
}
fn normaliseUsa(bytes: []u8) void {
    const first = get(u16, bytes, 4);
    @memset(bytes[first..][0 .. get(u16, bytes, 6) * 2], 0);
}
fn decodeFixups(bytes: []u8) !void {
    const start = get(u16, bytes, 4);
    const count = get(u16, bytes, 6);
    if (count != bytes.len / 512 + 1 or start < 0x28 or start + @as(usize, count) * 2 > 510 or
        ntfs.applyFixups(bytes) != .ok) return error.CorruptNtfs;
}
fn decodeRecord(bytes: []u8, number: u32) !void {
    try decodeFixups(bytes);
    const header = ntfs.FileRecordHeader.parse(bytes) orelse return error.CorruptNtfs;
    if (!header.inUse() or header.base_record.pack() != 0 or header.bytes_allocated != 1024 or header.record_number != number)
        return error.UnsupportedNtfs;
    if (get(u16, bytes, 4) < 0x30 or header.attrs_offset < get(u16, bytes, 4) + get(u16, bytes, 6) * 2) return error.CorruptNtfs;
    var iter = ntfs.AttributeIterator.init(bytes[0..header.bytes_in_use], header);
    while (true) {
        const at = iter.offset;
        if (at + 8 > header.bytes_in_use) return error.CorruptNtfs;
        if (get(u32, bytes, at) == ntfs.END_MARKER) break;
        const attr = iter.next() orelse return error.CorruptNtfs;
        if (attr.attr_type == @intFromEnum(ntfs.AttrType.attribute_list)) return error.UnsupportedNtfs;
        const min: usize = if (attr.non_resident) 64 else 24;
        if (attr.length < min or (attr.name.len != 0 and offset(bytes[at..], attr.name) < min)) return error.CorruptNtfs;
        const body = if (attr.non_resident) attr.mapping_pairs else attr.value;
        if (offset(bytes[at..], body) < min or (attr.name.len != 0 and
            offset(bytes[at..], body) < offset(bytes[at..], attr.name) + attr.name.len)) return error.CorruptNtfs;
    }
}
fn attribute(bytes: []const u8, kind: ntfs.AttrType, name: []const u8) !ntfs.Attribute {
    const header = ntfs.FileRecordHeader.parse(bytes) orelse return error.CorruptNtfs;
    var iter = ntfs.AttributeIterator.init(bytes[0..header.bytes_in_use], header);
    var result: ?ntfs.Attribute = null;
    while (iter.next()) |attr| {
        if (attr.attr_type == @intFromEnum(kind) and std.mem.eql(u8, attr.name, name)) {
            if (result != null) return error.UnsupportedNtfs;
            result = attr;
        }
    }
    return result orelse error.UnsupportedNtfs;
}
fn encodeRecord(bytes: []u8) !void {
    if (ntfs.installFixups(bytes, get(u16, bytes, get(u16, bytes, 4))) != .ok) return error.CorruptNtfs;
}
fn replaceData(bytes: []u8, name: []const u8, lcn: ?u64, clusters: u64, data_bytes: u64, sparse: bool) !void {
    const old = try attribute(bytes, .data, name);
    if (!old.non_resident) return error.UnsupportedNtfs;
    const start = offset(bytes, old.mapping_pairs) - getMappingOffset(bytes, old);
    const mapping_at = get(u16, bytes, start + 0x20);
    var mapping: [32]u8 = .{0} ** 32;
    const used = (ntfs.encodeRun(&mapping, clusters, if (lcn) |n| @as(i64, @intCast(n)) else null) orelse return error.UnsupportedNtfs) + 1;
    const length = std.mem.alignForward(usize, mapping_at + used, 8);
    const occupied = get(u32, bytes, 0x18);
    if (length > old.length and length - old.length > bytes.len - occupied) return error.UnsupportedNtfs;
    const tail_length = occupied - start - old.length;
    if (length > old.length) std.mem.copyBackwards(u8, bytes[start + length ..][0..tail_length], bytes[start + old.length ..][0..tail_length]) else std.mem.copyForwards(u8, bytes[start + length ..][0..tail_length], bytes[start + old.length ..][0..tail_length]);
    put(u32, bytes, 0x18, @intCast(occupied - old.length + length));
    put(u32, bytes, start + 4, @intCast(length));
    put(u64, bytes, start + 0x18, clusters - 1);
    put(u64, bytes, start + 0x28, if (sparse) data_bytes else clusters * 4096);
    put(u64, bytes, start + 0x30, data_bytes);
    put(u64, bytes, start + 0x38, if (sparse) 0 else data_bytes);
    @memset(bytes[start + mapping_at .. start + length], 0);
    @memcpy(bytes[start + mapping_at ..][0..used], mapping[0..used]);
}
fn getMappingOffset(bytes: []const u8, wanted: ntfs.Attribute) usize {
    const header = ntfs.FileRecordHeader.parse(bytes).?;
    var iter = ntfs.AttributeIterator.init(bytes, header);
    while (true) {
        const at = iter.offset;
        const attr = iter.next() orelse unreachable;
        if (attr.mapping_pairs.ptr == wanted.mapping_pairs.ptr) return get(u16, bytes, at + 0x20);
    }
}

fn changeRange(bytes: []u8, base: u64, begin: u64, end: u64, set: bool) void {
    var first = @max(base, begin);
    const last = @min(base + bytes.len * 8, end);
    if (first >= last) return;
    while (first < last and first % 8 != 0) : (first += 1) {
        const mask = @as(u8, 1) << @intCast(first % 8);
        if (set) bytes[@intCast((first - base) / 8)] |= mask else bytes[@intCast((first - base) / 8)] &= ~mask;
    }
    const whole_end = last / 8 * 8;
    if (whole_end > first) {
        @memset(bytes[@intCast((first - base) / 8)..@intCast((whole_end - base) / 8)], if (set) 0xff else 0);
        first = whole_end;
    }
    while (first < last) : (first += 1) {
        const mask = @as(u8, 1) << @intCast(first % 8);
        if (set) bytes[@intCast((first - base) / 8)] |= mask else bytes[@intCast((first - base) / 8)] &= ~mask;
    }
}
fn expectSetRange(bytes: []const u8, base: u64, begin: u64, end: u64) !void {
    var first = @max(base, begin);
    const last = @min(base + bytes.len * 8, end);
    if (first >= last) return;
    while (first < last and first % 8 != 0) : (first += 1)
        if (bytes[@intCast((first - base) / 8)] & (@as(u8, 1) << @intCast(first % 8)) == 0) return error.CorruptNtfs;
    const whole_end = last / 8 * 8;
    if (whole_end > first) {
        for (bytes[@intCast((first - base) / 8)..@intCast((whole_end - base) / 8)]) |byte|
            if (byte != 0xff) return error.CorruptNtfs;
        first = whole_end;
    }
    while (first < last) : (first += 1)
        if (bytes[@intCast((first - base) / 8)] & (@as(u8, 1) << @intCast(first % 8)) == 0) return error.CorruptNtfs;
}

const BitmapCheck = struct {
    map: *const Map,
    device: io.Device,
    scratch: []u8,
    cached_at: u64 = 0,
    cached_bytes: usize = 0,

    fn allocated(self: *BitmapCheck, first: u64, count: u64) !void {
        var bit = first;
        const last = first + count;
        const padded = std.mem.alignForward(u64, self.map.bytes, 512);
        while (bit < last) {
            const byte = bit / 8;
            if (self.cached_bytes == 0 or byte < self.cached_at or byte >= self.cached_at + self.cached_bytes) {
                self.cached_at = byte / 512 * 512;
                if (self.cached_at >= padded) return error.CorruptNtfs;
                self.cached_bytes = @intCast(@min(self.scratch.len, padded - self.cached_at));
                try self.map.read(self.device, self.cached_at, self.scratch[0..self.cached_bytes]);
            }
            const end = @min(last, (self.cached_at + self.cached_bytes) * 8);
            try expectSetRange(self.scratch[0..self.cached_bytes], self.cached_at * 8, bit, end);
            bit = end;
        }
    }
};
