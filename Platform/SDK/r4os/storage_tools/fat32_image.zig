//! Prepared FAT32 file trees, moved from the Distribution ImageCreator.
//! No host I/O: contents stay borrowed until buildInto returns. Physical
//! publication uses the same bounded Device/claim seam as other formatters.
const std = @import("std");
const fat32_format = @import("fat32.zig");
const block = @import("io.zig");
const SECTOR: u32 = 512;
const RESERVED_SECTORS: u32 = 32;
const FAT32_EOC: u32 = 0x0FFF_FFFF;
const FAT32_LAST_DATA_CLUSTER: u32 = 0x0FFF_FFF6;
const ROOT_CLUSTER: u32 = 2;
pub const File = struct { path: []const u8, bytes: []const u8 };
pub const Stats = struct { geometry: fat32_format.Geometry, used_sectors: u32 };

pub const Prepared = struct {
    allocator: std.mem.Allocator,
    bytes: []u8,
    stats: Stats,
    pub fn deinit(self: *Prepared) void {
        self.allocator.free(self.bytes);
        self.bytes = &.{};
    }
    pub fn execute(self: Prepared, device: block.Device, full: bool, work: []u8) !void {
        try device.requireExclusive();
        const geo = self.stats.geometry;
        if (device.sectors != geo.sectors or self.bytes.len != device.sectors * 512 or work.len < 512 or work.len % 512 != 0 or
            self.stats.used_sectors < geo.data_start or self.stats.used_sectors > geo.sectors) return error.Geometry;
        const limit = if (full) geo.sectors else self.stats.used_sectors;
        const end: usize = @intCast(@as(u64, limit) * 512);
        const zero: [512]u8 = .{0} ** 512;
        device.phase(.invalidate);
        try device.write(0, &zero);
        try device.write(6, &zero);
        try device.write(device.sectors - 1, &zero);
        try device.flush();
        device.phase(.metadata);
        try device.write(1, self.bytes[512 .. 6 * 512]);
        try device.write(7, self.bytes[7 * 512 .. end]);
        try device.flush();
        try device.verify(1, self.bytes[512 .. 6 * 512], work);
        try device.verify(7, self.bytes[7 * 512 .. end], work);
        if (limit < geo.sectors) try device.verify(device.sectors - 1, &zero, work);
        device.phase(.backup);
        try device.write(6, self.bytes[6 * 512 .. 7 * 512]);
        try device.flush();
        try device.verify(6, self.bytes[6 * 512 .. 7 * 512], work);
        device.phase(.primary);
        try device.write(0, self.bytes[0..512]);
        try device.flush();
        try device.verify(0, self.bytes[0..512], work);
        device.complete();
    }
};

pub fn prepare(allocator: std.mem.Allocator, sectors: u64, hidden: u64, label: []const u8, serial: u32, files: []const File) !Prepared {
    const geometry = try fat32_format.Geometry.init(sectors, hidden, 0);
    const bytes = try allocator.alloc(u8, @as(usize, geometry.sectors) * 512);
    errdefer allocator.free(bytes);
    const stats = try buildInto(allocator, bytes, geometry.hidden, geometry.sectors_per_cluster, label, serial, files);
    return .{ .allocator = allocator, .bytes = bytes, .stats = stats };
}

/// Call only with a private, unpublished destination buffer. Validate and
/// build the complete namespace before any physical target is claimed.
pub fn buildInto(allocator: std.mem.Allocator, bytes: []u8, hidden: u64, spc: u32, label: []const u8, serial: u32, files: []const File) !Stats {
    if (bytes.len % 512 != 0 or files.len > 8192) return error.Geometry;
    const geometry = try fat32_format.Geometry.init(bytes.len / 512, hidden, spc);
    const name = try fat32_format.volumeLabel(label);
    for (files, 0..) |file, i| {
        const path = std.mem.trimStart(u8, file.path, "/");
        if (path.len == 0 or path.len > 1023 or std.mem.count(u8, path, "/") > 24 or file.bytes.len > std.math.maxInt(u32)) return error.Path;
        var parts = std.mem.splitScalar(u8, path, '/');
        while (parts.next()) |part| {
            if (part.len == 0 or part.len > 255 or std.mem.eql(u8, part, ".") or std.mem.eql(u8, part, "..") or part[part.len - 1] == '.' or part[part.len - 1] == ' ') return error.Path;
            for (part) |c| if (c < 32 or c > 126 or std.mem.indexOfScalar(u8, "<>:\"\\|?*", c) != null) return error.Path;
        }
        for (files[0..i]) |other| if (std.ascii.eqlIgnoreCase(path, std.mem.trimStart(u8, other.path, "/"))) return error.DuplicatePath;
    }
    @memset(bytes, 0);
    const boot = geometry.boot(name, serial);
    @memcpy(bytes[0..512], &boot);
    @memcpy(bytes[6 * 512 ..][0..512], &boot);
    var img: Image = .{ .allocator = allocator, .image = bytes, .part_start_sector = 0, .part_sectors = geometry.sectors, .sectors_per_fat = geometry.sectors_per_fat, .sectors_per_cluster = geometry.sectors_per_cluster, .data_start_sector = geometry.data_start, .nodes = .empty, .label = name };
    defer {
        for (img.nodes.items) |*node| {
            if (node.name.len != 0) allocator.free(node.name);
            node.children.deinit(allocator);
        }
        img.nodes.deinit(allocator);
    }
    try img.nodes.append(allocator, .{ .kind = .dir, .name = "", .parent = 0 });
    for (files) |file| try img.insertFile(file.path, file.bytes);
    try img.allocateLayout(0);
    try img.writeAll();
    img.updateFsInfoFromFat();
    return .{ .geometry = geometry, .used_sectors = geometry.data_start + (img.next_free_cluster - 2) * geometry.sectors_per_cluster };
}
fn buildFsInfo(buf: []u8, free_count: u32, next_free: u32) void {
    const info = fat32_format.fsInfo(free_count, next_free);
    @memcpy(buf[0..512], &info);
}

// --- Filesystem tree, flat with parent indices -----------------------------
const NodeKind = enum { dir, file };

const Node = struct {
    kind: NodeKind,
    name: []const u8, // last path segment, original case/special characters
    parent: u32, // index, 0 = root
    data: []const u8 = &[_]u8{}, // file contents
    children: std.ArrayList(u32) = .empty, // child indices for directories
    first_cluster: u32 = 0, // first cluster of the file/directory
    cluster_count: u32 = 0,
};

// --- Helpers: small endian writers ----------------------------------------
fn wU16(buf: []u8, off: usize, v: u16) void {
    std.mem.writeInt(u16, buf[off..][0..2], v, .little);
}
fn wU32(buf: []u8, off: usize, v: u32) void {
    std.mem.writeInt(u32, buf[off..][0..4], v, .little);
}

// --- 8.3 name generation ---------------------------------------------------
// Returns true when the name is already a perfect 8.3 name and needs no LFN.
fn buildShortName(orig: []const u8, out: *[11]u8) bool {
    @memset(out, ' ');
    var dot_pos: ?usize = null;
    var i: usize = orig.len;
    while (i > 0) : (i -= 1) {
        if (orig[i - 1] == '.') {
            dot_pos = i - 1;
            break;
        }
    }
    const base = if (dot_pos) |p| orig[0..p] else orig;
    const ext = if (dot_pos) |p| orig[p + 1 ..] else "";

    var perfect = true;
    if (base.len > 8 or ext.len > 3 or base.len == 0) perfect = false;
    if (dot_pos != null and (dot_pos.? == 0)) perfect = false;

    // Allowed chars in 8.3: A-Z 0-9 ! # $ % & ' ( ) - @ ^ _ ` { } ~
    const allowed = "!#$%&'()-@^_`{}~";
    var bcount: usize = 0;
    for (base) |c| {
        if (bcount >= 6 and !perfect) break; // tilde suffix leaves six base characters
        if (bcount >= 8) {
            perfect = false;
            break;
        }
        var oc: u8 = c;
        if (oc >= 'a' and oc <= 'z') oc -= 32;
        const is_alnum = (oc >= 'A' and oc <= 'Z') or (oc >= '0' and oc <= '9');
        var ok = is_alnum;
        if (!ok) for (allowed) |a| {
            if (oc == a) {
                ok = true;
                break;
            }
        };
        if (!ok) {
            oc = '_';
            perfect = false;
        }
        out[bcount] = oc;
        bcount += 1;
    }

    var ecount: usize = 0;
    for (ext) |c| {
        if (ecount >= 3) {
            perfect = false;
            break;
        }
        var oc: u8 = c;
        if (oc >= 'a' and oc <= 'z') oc -= 32;
        const is_alnum = (oc >= 'A' and oc <= 'Z') or (oc >= '0' and oc <= '9');
        var ok = is_alnum;
        if (!ok) for (allowed) |a| {
            if (oc == a) {
                ok = true;
                break;
            }
        };
        if (!ok) {
            oc = '_';
            perfect = false;
        }
        out[8 + ecount] = oc;
        ecount += 1;
    }

    if (!perfect) {
        // First tilde suffix. Collisions are resolved later as ~2, ~3, ...
        // Keep shorter base names unchanged.
        const tilde_pos: usize = if (bcount > 6) 6 else bcount;
        out[tilde_pos] = '~';
        out[tilde_pos + 1] = '1';
    }
    return perfect;
}

fn applyTildeSuffix(short: *[11]u8, suffix: u32) !void {
    if (suffix == 0 or suffix > 999_999) return error.TooManyShortNameCollisions;

    var digits: [6]u8 = undefined;
    var n = suffix;
    var digit_count: usize = 0;
    while (n > 0) : (n /= 10) {
        digits[digits.len - 1 - digit_count] = @intCast('0' + (n % 10));
        digit_count += 1;
    }

    const tilde_pos = 8 - digit_count - 1;
    @memset(short[tilde_pos..8], ' ');
    short[tilde_pos] = '~';
    @memcpy(short[tilde_pos + 1 .. 8], digits[digits.len - digit_count ..]);
}

fn shortNameUsed(used: []const [11]u8, short: [11]u8) bool {
    for (used) |existing| {
        if (std.mem.eql(u8, &existing, &short)) return true;
    }
    return false;
}

fn lfnChecksum(short: [11]u8) u8 {
    var sum: u8 = 0;
    for (short) |c| {
        const lo: u8 = if ((sum & 1) != 0) 0x80 else 0;
        sum = lo +% (sum >> 1) +% c;
    }
    return sum;
}

// --- Image-Builder --------------------------------------------------------
const Image = struct {
    allocator: std.mem.Allocator,
    image: []u8,
    part_start_sector: u32,
    part_sectors: u32,
    sectors_per_fat: u32,
    sectors_per_cluster: u32,
    data_start_sector: u32, // relativ zum Partitionsstart
    nodes: std.ArrayList(Node),
    next_free_cluster: u32 = ROOT_CLUSTER + 1,
    label: [11]u8,

    fn partOffset(self: *const Image, sector_in_part: u32) usize {
        return @as(usize, self.part_start_sector + sector_in_part) * SECTOR;
    }

    fn clusterOffset(self: *Image, cluster: u32) usize {
        const sec = self.data_start_sector + (cluster - 2) * self.sectors_per_cluster;
        return self.partOffset(sec);
    }

    fn clusterSize(self: *const Image) u32 {
        return SECTOR * self.sectors_per_cluster;
    }

    fn dataClusterCount(self: *const Image) u32 {
        if (self.part_sectors <= self.data_start_sector) return 0;
        return (self.part_sectors - self.data_start_sector) / self.sectors_per_cluster;
    }

    fn fatEntry(self: *const Image, cluster: u32) u32 {
        const fat0_off = self.partOffset(RESERVED_SECTORS);
        return std.mem.readInt(u32, self.image[fat0_off + @as(usize, cluster) * 4 ..][0..4], .little) & 0x0FFF_FFFF;
    }

    fn updateFsInfoFromFat(self: *Image) void {
        const total_clusters = self.dataClusterCount();
        var free_count: u32 = 0;
        var next_free: u32 = 0xFFFF_FFFF;
        var cluster: u32 = 2;
        const end = total_clusters + 2;
        while (cluster < end) : (cluster += 1) {
            if (self.fatEntry(cluster) == 0) {
                free_count += 1;
                if (next_free == 0xFFFF_FFFF) next_free = cluster;
            }
        }
        buildFsInfo(self.image[self.partOffset(1)..][0..SECTOR], free_count, next_free);
        @memcpy(
            self.image[self.partOffset(7)..][0..SECTOR],
            self.image[self.partOffset(1)..][0..SECTOR],
        );
    }

    // Write cluster chains to both FATs (list of clusters).
    fn writeChain(self: *Image, clusters: []const u32) void {
        const fat0_off = self.partOffset(RESERVED_SECTORS);
        const fat1_off = self.partOffset(RESERVED_SECTORS + self.sectors_per_fat);
        for (clusters, 0..) |c, i| {
            const next: u32 = if (i + 1 < clusters.len) clusters[i + 1] else FAT32_EOC;
            wU32(self.image, fat0_off + @as(usize, c) * 4, next);
            wU32(self.image, fat1_off + @as(usize, c) * 4, next);
        }
    }

    fn allocClusters(self: *Image, count: u32) !std.ArrayList(u32) {
        try self.ensureClustersAvailable(count);
        var list: std.ArrayList(u32) = .empty;
        try list.ensureTotalCapacity(self.allocator, count);
        var i: u32 = 0;
        while (i < count) : (i += 1) {
            const c = self.next_free_cluster;
            self.next_free_cluster += 1;
            try list.append(self.allocator, c);
        }
        return list;
    }

    fn ensureClustersAvailable(self: *const Image, count: u32) !void {
        if (count == 0) return;
        if (self.next_free_cluster + count - 1 > FAT32_LAST_DATA_CLUSTER) {
            return error.ImageTooLargeForFat32;
        }
        if (@as(u64, self.next_free_cluster) + count > @as(u64, self.dataClusterCount()) + 2) {
            return error.ImageFull;
        }
    }

    // Insert a path like "/boot/limine.conf" into the tree and attach file data.
    fn insertFile(self: *Image, dest: []const u8, data: []const u8) !void {
        var iter = std.mem.tokenizeScalar(u8, dest, '/');
        var current: u32 = 0; // root
        var last_seg: ?[]const u8 = null;
        while (iter.next()) |seg| {
            if (last_seg) |ls| {
                // Create or find the previous segment as a subdirectory.
                current = try self.findOrCreateDir(current, ls);
            }
            last_seg = seg;
        }
        const filename = last_seg orelse return error.EmptyDest;
        for (self.nodes.items[current].children.items) |ci| {
            if (std.ascii.eqlIgnoreCase(self.nodes.items[ci].name, filename)) return error.DuplicatePath;
        }
        // File node.
        const idx: u32 = @intCast(self.nodes.items.len);
        try self.nodes.ensureUnusedCapacity(self.allocator, 1);
        const name = try self.allocator.dupe(u8, filename);
        self.nodes.appendAssumeCapacity(.{
            .kind = .file,
            .name = name,
            .parent = current,
            .data = data,
        });
        try self.nodes.items[current].children.append(self.allocator, idx);
    }

    fn findOrCreateDir(self: *Image, parent: u32, name: []const u8) !u32 {
        for (self.nodes.items[parent].children.items) |ci| {
            const child = &self.nodes.items[ci];
            if (std.ascii.eqlIgnoreCase(child.name, name)) {
                if (child.kind != .dir) return error.DuplicatePath;
                return ci;
            }
        }
        const idx: u32 = @intCast(self.nodes.items.len);
        try self.nodes.ensureUnusedCapacity(self.allocator, 1);
        const owned_name = try self.allocator.dupe(u8, name);
        self.nodes.appendAssumeCapacity(.{
            .kind = .dir,
            .name = owned_name,
            .parent = parent,
        });
        try self.nodes.items[parent].children.append(self.allocator, idx);
        return idx;
    }

    // Recursively compute cluster demand and assign first_cluster/cluster_count.
    fn allocateLayout(self: *Image, node_idx: u32) !void {
        const n = &self.nodes.items[node_idx];
        switch (n.kind) {
            .file => {
                if (n.data.len == 0) {
                    n.first_cluster = 0;
                    n.cluster_count = 0;
                } else {
                    const cluster_size = self.clusterSize();
                    const cnt: u32 = @intCast((@as(u64, n.data.len) + cluster_size - 1) / cluster_size);
                    try self.ensureClustersAvailable(cnt);
                    n.cluster_count = cnt;
                    n.first_cluster = self.next_free_cluster;
                    self.next_free_cluster += @intCast(cnt);
                }
            },
            .dir => {
                // Reserve the whole root chain before any children; otherwise
                // a root larger than one cluster overlaps the first file.
                if (node_idx == 0) {
                    var total_entries: u32 = 1; // volume label
                    for (n.children.items) |ci| total_entries += entriesForName(self.nodes.items[ci].name);
                    n.cluster_count = @max(1, (total_entries * 32 + self.clusterSize() - 1) / self.clusterSize());
                    self.next_free_cluster = ROOT_CLUSTER;
                    try self.ensureClustersAvailable(n.cluster_count);
                    n.first_cluster = ROOT_CLUSTER;
                    self.next_free_cluster += n.cluster_count;
                    for (n.children.items) |ci| try self.allocateLayout(ci);
                    return;
                }
                // Allocate children first so their cluster numbers are final
                // before directory entries are written.
                for (n.children.items) |ci| try self.allocateLayout(ci);
                // Entries per child: one short entry plus optional LFN entries.
                var total_entries: u32 = if (node_idx == 0) 0 else 2; // "." and ".."
                for (n.children.items) |ci| {
                    total_entries += entriesForName(self.nodes.items[ci].name);
                }
                const bytes = total_entries * 32;
                const cluster_size = self.clusterSize();
                const cnt = (bytes + cluster_size - 1) / cluster_size;
                n.cluster_count = if (cnt == 0) 1 else cnt;
                try self.ensureClustersAvailable(n.cluster_count);
                n.first_cluster = if (node_idx == 0) ROOT_CLUSTER else self.next_free_cluster;
                self.next_free_cluster += @intCast(n.cluster_count);
            },
        }
    }

    fn writeAll(self: *Image) !void {
        // FAT reserved entries.
        const fat0_off = self.partOffset(RESERVED_SECTORS);
        const fat1_off = self.partOffset(RESERVED_SECTORS + self.sectors_per_fat);
        wU32(self.image, fat0_off + 0, 0x0FFFF_FF8);
        wU32(self.image, fat0_off + 4, FAT32_EOC);
        wU32(self.image, fat1_off + 0, 0x0FFFF_FF8);
        wU32(self.image, fat1_off + 4, FAT32_EOC);

        // Write files and directories recursively.
        try self.writeNode(0);
    }

    fn writeNode(self: *Image, node_idx: u32) !void {
        const n = &self.nodes.items[node_idx];
        switch (n.kind) {
            .file => {
                if (n.cluster_count == 0) return;
                // Build cluster list.
                var clusters: std.ArrayList(u32) = .empty;
                defer clusters.deinit(self.allocator);
                var i: u32 = 0;
                while (i < n.cluster_count) : (i += 1) {
                    try clusters.append(self.allocator, n.first_cluster + i);
                }
                self.writeChain(clusters.items);
                // Write data.
                const dst = self.clusterOffset(n.first_cluster);
                @memcpy(self.image[dst .. dst + n.data.len], n.data);
            },
            .dir => {
                // Build directory entry buffer.
                var buf: std.ArrayList(u8) = .empty;
                defer buf.deinit(self.allocator);
                var used_short_names: std.ArrayList([11]u8) = .empty;
                defer used_short_names.deinit(self.allocator);

                if (node_idx != 0) {
                    // "." Eintrag
                    try writeShortDir(&buf, self.allocator, ".          ".*, true, n.first_cluster, 0);
                    // ".." Eintrag (parent-cluster, root = 0)
                    const parent_cluster: u32 = if (n.parent == 0) 0 else self.nodes.items[n.parent].first_cluster;
                    try writeShortDir(&buf, self.allocator, "..         ".*, true, parent_cluster, 0);
                } else {
                    var label: [32]u8 = .{0} ** 32;
                    @memcpy(label[0..11], &self.label);
                    label[11] = 0x08;
                    try buf.appendSlice(self.allocator, &label);
                }

                for (n.children.items) |ci| {
                    const c = &self.nodes.items[ci];
                    var short: [11]u8 = undefined;
                    const perfect = buildShortName(c.name, &short);
                    if (perfect and shortNameUsed(used_short_names.items, short)) return error.DuplicateShortName;

                    if (!perfect) {
                        var suffix: u32 = 1;
                        while (shortNameUsed(used_short_names.items, short)) : (suffix += 1) {
                            short = undefined;
                            _ = buildShortName(c.name, &short);
                            try applyTildeSuffix(&short, suffix + 1);
                        }
                    }

                    try used_short_names.append(self.allocator, short);
                    try writeDirEntryWithShort(&buf, self.allocator, c, short, perfect);
                }

                var clusters: std.ArrayList(u32) = .empty;
                defer clusters.deinit(self.allocator);
                var i: u32 = 0;
                while (i < n.cluster_count) : (i += 1) {
                    try clusters.append(self.allocator, n.first_cluster + i);
                }
                self.writeChain(clusters.items);
                const off = self.clusterOffset(n.first_cluster);
                @memcpy(self.image[off .. off + buf.items.len], buf.items);

                for (n.children.items) |ci| try self.writeNode(ci);
            },
        }
    }
};

fn entriesForName(name: []const u8) u32 {
    var short: [11]u8 = undefined;
    const perfect = buildShortName(name, &short);
    if (perfect) return 1;
    // LFN entry count: ceil(len/13).
    const lfn_count: u32 = (@as(u32, @intCast(name.len)) + 12) / 13;
    return lfn_count + 1;
}

fn writeShortDir(
    buf: *std.ArrayList(u8),
    a: std.mem.Allocator,
    short: [11]u8,
    is_dir: bool,
    first_cluster: u32,
    size: u32,
) !void {
    var e: [32]u8 = .{0} ** 32;
    @memcpy(e[0..11], &short);
    e[11] = if (is_dir) 0x10 else 0x20;
    wU16(&e, 20, @truncate(first_cluster >> 16));
    wU16(&e, 26, @truncate(first_cluster));
    wU32(&e, 28, size);
    try buf.appendSlice(a, &e);
}

fn writeDirEntryWithShort(
    buf: *std.ArrayList(u8),
    a: std.mem.Allocator,
    n: *const Node,
    short: [11]u8,
    perfect: bool,
) !void {
    if (!perfect) {
        const checksum = lfnChecksum(short);
        const lfn_count: u32 = (@as(u32, @intCast(n.name.len)) + 12) / 13;
        // Reverse order: highest sequence value with 0x40 first, then descending.
        var seq: u32 = lfn_count;
        while (seq >= 1) : (seq -= 1) {
            var e: [32]u8 = .{0} ** 32;
            const seq_byte: u8 = @intCast(seq);
            e[0] = if (seq == lfn_count) seq_byte | 0x40 else seq_byte;
            e[11] = 0x0F;
            e[12] = 0;
            e[13] = checksum;
            // LFN cluster field is always 0.
            // Fill 13 characters from the name as UCS-2 LE; pad the rest with
            // 0xFFFF after the 0x0000 terminator.
            const start: usize = (seq - 1) * 13;
            const slot_indices = [_]usize{ 1, 3, 5, 7, 9, 14, 16, 18, 20, 22, 24, 28, 30 };
            var ended = false;
            var k: usize = 0;
            while (k < 13) : (k += 1) {
                const off = slot_indices[k];
                if (start + k < n.name.len) {
                    e[off] = n.name[start + k];
                    e[off + 1] = 0;
                } else if (!ended) {
                    e[off] = 0;
                    e[off + 1] = 0;
                    ended = true;
                } else {
                    e[off] = 0xFF;
                    e[off + 1] = 0xFF;
                }
            }
            try buf.appendSlice(a, &e);
            if (seq == 1) break;
        }
    }

    const size: u32 = if (n.kind == .file) @intCast(n.data.len) else 0;
    try writeShortDir(buf, a, short, n.kind == .dir, n.first_cluster, size);
}
