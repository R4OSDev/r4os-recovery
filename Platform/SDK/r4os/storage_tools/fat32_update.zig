//! Prepared file replacement in an existing canonical FAT32 volume. The
//! private image preserves unrelated data, entries, attributes and boot code.
//! Execution writes only changed sectors through an exclusive device claim.
const std = @import("std");
const block = @import("io.zig");
const format = @import("fat32.zig");
const view = @import("fat32_view.zig");
/// Null removes the named file or complete directory tree. Changes are
/// applied in caller order to the private image, before any device writes.
pub const Change = struct { path: []const u8, bytes: ?[]const u8 };
const Write = struct { first: u32, count: u32, order: u8 };
const maximum_depth = 24;
const final_order = 27;

/// Exact file set below an existing directory. Empty extra directories and
/// unlisted files are rejected. Read-only; no allocation or volume mutation.
pub fn verifyTree(original: []const u8, hidden: u64, path: []const u8, expected: []const []const u8) !void {
    const checked = try view.View.init(original, hidden);
    if (expected.len > 4096) return error.FileLimit;
    try validPath(path);
    for (expected, 0..) |name, i| {
        try validPath(name);
        for (expected[0..i]) |other| if (std.ascii.eqlIgnoreCase(name, other)) return error.DuplicateChange;
    }
    // The iterator does not write bytes or use directory_depth.
    var fat = Fat{ .bytes = @constCast(original), .geo = checked.geometry, .directory_depth = &.{} };
    var parent: u32 = 2;
    var parts = std.mem.splitScalar(u8, path, '/');
    while (parts.next()) |name| {
        const entry = (try fat.child(parent, name)) orelse return error.SourceFileMissing;
        if (!entry.directory()) return error.PathConflict;
        parent = entry.cluster();
    }
    var path_buffer: [1024]u8 = undefined;
    var found = [_]bool{false} ** 4096;
    var entries: usize = 0;
    try fat.verifyChildren(parent, 0, &path_buffer, 0, expected, &found, &entries);
    for (found[0..expected.len]) |yes| if (!yes) return error.SourceFileMissing;
}

pub const Prepared = struct {
    allocator: std.mem.Allocator,
    bytes: []u8,
    writes: []Write,
    source_sha256: [32]u8,
    changed_files: usize,

    pub fn deinit(self: *Prepared) void {
        self.allocator.free(self.writes);
        self.allocator.free(self.bytes);
        self.writes = &.{};
        self.bytes = &.{};
    }
    pub fn checkSource(self: Prepared, device: block.Device, work: []u8) !void {
        try device.requireExclusive();
        if (device.sectors * 512 != self.bytes.len or work.len < 512 or work.len % 512 != 0) return error.Geometry;
        var digest = std.crypto.hash.sha2.Sha256.init(.{});
        var offset: usize = 0;
        while (offset < self.bytes.len) {
            const amount = @min(self.bytes.len - offset, work.len);
            try device.read(offset / 512, work[0..amount]);
            digest.update(work[0..amount]);
            offset += amount;
        }
        if (!std.mem.eql(u8, &digest.finalResult(), &self.source_sha256)) return error.SourceChanged;
    }
    pub fn execute(self: Prepared, device: block.Device, work: []u8) !void {
        try self.checkSource(device, work);
        // New payloads precede FAT backup/main, then child directories before
        // parents. Only allocation counters follow namespace publication.
        for (0..final_order + 1) |order| {
            var changed = false;
            device.phase(if (order == 0) .metadata else if (order == 1) .backup else .primary);
            for (self.writes) |write| {
                if (write.order != order) continue;
                changed = true;
                const offset = @as(usize, write.first) * 512;
                try device.write(write.first, self.bytes[offset..][0 .. @as(usize, write.count) * 512]);
            }
            if (!changed) continue;
            try device.flush();
            for (self.writes) |write| {
                if (write.order != order) continue;
                const offset = @as(usize, write.first) * 512;
                try device.verify(write.first, self.bytes[offset..][0 .. @as(usize, write.count) * 512], work);
            }
        }
        device.complete();
    }
};

pub fn prepare(allocator: std.mem.Allocator, original: []const u8, hidden: u64, changes: []const Change) !Prepared {
    if (original.len > 1024 * 1024 * 1024 or changes.len > 4096) return error.VolumeLimit;
    const checked = try view.View.init(original, hidden);
    for (changes, 0..) |change, i| {
        try validPath(change.path);
        if (change.bytes) |data| if (data.len > std.math.maxInt(u32)) return error.FileLimit;
        for (changes[0..i]) |other| if (std.ascii.eqlIgnoreCase(change.path, other.path)) return error.DuplicateChange;
    }
    const bytes = try allocator.dupe(u8, original);
    errdefer allocator.free(bytes);
    const owners = try allocator.alloc(u8, checked.geometry.clusters + 2);
    defer allocator.free(owners);
    @memset(owners, 0);
    const depth = try allocator.alloc(u8, owners.len);
    defer allocator.free(depth);
    @memset(depth, 0);
    var fat = Fat{ .bytes = bytes, .geo = checked.geometry, .directory_depth = depth };
    try fat.audit(allocator, owners);
    const original_directories = try allocator.dupe(u8, depth);
    defer allocator.free(original_directories);
    fat.original_directories = original_directories;
    var changed_files: usize = 0;
    for (changes) |change| if (try fat.replace(change)) {
        changed_files += 1;
    };
    if (changed_files != 0) fat.updateInfo();
    var writes: std.ArrayList(Write) = .empty;
    defer writes.deinit(allocator);
    for (0..checked.geometry.sectors) |sector| {
        const offset = sector * 512;
        if (std.mem.eql(u8, original[offset..][0..512], bytes[offset..][0..512])) continue;
        const order = try fat.order(@intCast(sector));
        if (writes.items.len != 0) {
            const previous = &writes.items[writes.items.len - 1];
            if (previous.order == order and previous.first + previous.count == sector) {
                previous.count += 1;
                continue;
            }
        }
        try writes.append(allocator, .{ .first = @intCast(sector), .count = 1, .order = order });
    }
    var sha: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(original, &sha, .{});
    return .{ .allocator = allocator, .bytes = bytes, .writes = try writes.toOwnedSlice(allocator), .source_sha256 = sha, .changed_files = changed_files };
}

fn validPath(path: []const u8) !void {
    if (path.len == 0 or path.len > 1023) return error.Path;
    var parts = std.mem.splitScalar(u8, path, '/');
    var count: usize = 0;
    while (parts.next()) |part| {
        count += 1;
        if (count > maximum_depth or part.len == 0 or part.len > 255 or std.mem.eql(u8, part, ".") or std.mem.eql(u8, part, "..") or part[part.len - 1] == '.' or part[part.len - 1] == ' ') return error.Path;
        for (part) |c| if (c < 32 or c > 126 or std.mem.indexOfScalar(u8, "<>:\"\\|?*", c) != null) return error.Path;
    }
}

const Name = struct {
    units: [260]u16 = .{0} ** 260,
    len: usize = 0,
    fn matches(self: *const Name, wanted: []const u8) bool {
        if (self.len != wanted.len) return false;
        for (wanted, self.units[0..self.len]) |a, b| if (b > 127 or std.ascii.toUpper(a) != std.ascii.toUpper(@intCast(b))) return false;
        return true;
    }
};
const Entry = struct {
    offset: usize,
    slots: [21]usize,
    slot_count: u8,
    raw: [32]u8,
    name: Name,
    fn directory(self: Entry) bool {
        return self.raw[11] & 16 != 0;
    }
    fn cluster(self: Entry) u32 {
        return (@as(u32, u16at(&self.raw, 20)) << 16) | u16at(&self.raw, 26);
    }
    fn size(self: Entry) u32 {
        return u32at(&self.raw, 28);
    }
};
const Lfn = struct {
    name: Name = .{},
    active: bool = false,
    expected: u8 = 0,
    checksum: u8 = 0,
    fn consume(self: *Lfn, raw: []const u8) !void {
        const ordinal = raw[0] & 31;
        const last = raw[0] & 64 != 0;
        if (ordinal == 0 or ordinal > 20 or raw[0] & 0xa0 != 0 or raw[12] != 0 or u16at(raw, 26) != 0) return error.SourceFat;
        if (!self.active) {
            if (!last) return error.SourceFat;
            self.* = .{ .active = true, .expected = ordinal, .checksum = raw[13] };
        } else if (last) return error.SourceFat;
        if (ordinal != self.expected or raw[13] != self.checksum) return error.SourceFat;
        var terminated = false;
        for (lfn_positions, 0..) |position, i| {
            const c = u16at(raw, position);
            const at = @as(usize, ordinal - 1) * 13 + i;
            if (terminated) {
                if (c != 0xffff) return error.SourceFat;
            } else if (c == 0) {
                if (!last) return error.SourceFat;
                terminated = true;
            } else {
                if (c == 0xffff or at >= 255) return error.SourceFat;
                self.name.units[at] = c;
                self.name.len = @max(self.name.len, at + 1);
            }
        }
        self.expected -= 1;
    }
    fn finish(self: *Lfn, raw: []const u8) !Name {
        if (self.expected != 0 or self.name.len == 0 or checksum(raw[0..11]) != self.checksum) return error.SourceFat;
        // Preserve foreign Unicode names without recoding or replacing them.
        var i: usize = 0;
        while (i < self.name.len) : (i += 1) {
            const c = self.name.units[i];
            if (c >= 0xd800 and c <= 0xdbff) {
                if (i + 1 >= self.name.len or self.name.units[i + 1] < 0xdc00 or self.name.units[i + 1] > 0xdfff) return error.SourceFat;
                i += 1;
            } else if (c >= 0xdc00 and c <= 0xdfff) return error.SourceFat;
        }
        const name = self.name;
        self.* = .{};
        return name;
    }
};

const Iterator = struct {
    fat: *Fat,
    cluster: u32,
    position: usize = 0,
    traversed: u32 = 0,
    entries: usize = 0,
    finished: bool = false,
    lfn: Lfn = .{},
    slots: [21]usize = undefined,
    slot_count: u8 = 0,
    fn next(self: *Iterator) !?Entry {
        while (!self.finished) {
            const size = self.fat.clusterSize();
            if (self.position == size) {
                self.cluster = (try self.fat.next(self.cluster)) orelse {
                    self.finished = true;
                    if (self.lfn.active) return error.SourceFat;
                    return null;
                };
                self.position = 0;
                self.traversed += 1;
                if (self.traversed >= self.fat.geo.clusters) return error.SourceFat;
            }
            const offset = try self.fat.clusterOffset(self.cluster) + self.position;
            self.position += 32;
            self.entries += 1;
            if (self.entries > 262144) return error.SourceFat;
            const raw = self.fat.bytes[offset..][0..32];
            if (raw[0] == 0) {
                self.finished = true;
                if (self.lfn.active) return error.SourceFat;
                return null;
            }
            if (raw[0] == 0xe5) {
                self.lfn = .{};
                self.slot_count = 0;
                continue;
            }
            if (raw[11] == 15) {
                try self.lfn.consume(raw);
                if (self.slot_count >= 20) return error.SourceFat;
                self.slots[self.slot_count] = offset;
                self.slot_count += 1;
                continue;
            }
            if (raw[11] & 15 == 15) return error.SourceFat;
            if (raw[0] == '.' or raw[11] & 8 != 0) {
                if (self.lfn.active) return error.SourceFat;
                continue;
            }
            var name: Name = .{};
            if (self.lfn.active) {
                name = try self.lfn.finish(raw);
            } else {
                const base = std.mem.trimEnd(u8, raw[0..8], " ");
                const ext = std.mem.trimEnd(u8, raw[8..11], " ");
                for (base) |c| {
                    name.units[name.len] = c;
                    name.len += 1;
                }
                if (ext.len != 0) {
                    name.units[name.len] = '.';
                    name.len += 1;
                    for (ext) |c| {
                        name.units[name.len] = c;
                        name.len += 1;
                    }
                }
            }
            if (name.len == 0) return error.SourceFat;
            self.slots[self.slot_count] = offset;
            self.slot_count += 1;
            const result = Entry{ .offset = offset, .slots = self.slots, .slot_count = self.slot_count, .raw = raw.*, .name = name };
            self.slot_count = 0;
            return result;
        }
        return null;
    }
};

const Fat = struct {
    bytes: []u8,
    geo: format.Geometry,
    directory_depth: []u8,
    original_directories: []const u8 = &.{},
    free_hint: u32 = 2,

    fn verifyChildren(self: *Fat, parent: u32, depth: u8, path: []u8, length: usize, expected: []const []const u8, found: []bool, entries: *usize) !void {
        if (depth >= maximum_depth) return error.Path;
        var iterator = Iterator{ .fat = self, .cluster = parent };
        while (try iterator.next()) |entry| {
            entries.* += 1;
            if (entries.* > 8192 or length + entry.name.len > path.len) return error.FileLimit;
            for (entry.name.units[0..entry.name.len], 0..) |c, i| {
                if (c > 127) return error.SourceContentMismatch;
                path[length + i] = @intCast(c);
            }
            const end = length + entry.name.len;
            const name = path[0..end];
            if (entry.directory()) {
                for (expected) |wanted| {
                    if (wanted.len > name.len and wanted[name.len] == '/' and std.ascii.eqlIgnoreCase(wanted[0..name.len], name)) break;
                } else return error.SourceContentMismatch;
                if (end == path.len) return error.Path;
                path[end] = '/';
                try self.verifyChildren(entry.cluster(), depth + 1, path, end + 1, expected, found, entries);
            } else {
                for (expected, 0..) |wanted, i| {
                    if (!std.ascii.eqlIgnoreCase(wanted, name)) continue;
                    if (found[i]) return error.AmbiguousPath;
                    found[i] = true;
                    break;
                } else return error.SourceContentMismatch;
            }
        }
    }

    fn clusterSize(self: Fat) usize {
        return @as(usize, self.geo.sectors_per_cluster) * 512;
    }
    fn clusterOffset(self: Fat, cluster: u32) !usize {
        if (cluster < 2 or cluster >= self.geo.clusters + 2) return error.SourceFat;
        return (@as(usize, self.geo.data_start) + @as(usize, cluster - 2) * self.geo.sectors_per_cluster) * 512;
    }
    fn value(self: Fat, cluster: u32) u32 {
        return u32at(self.bytes, 32 * 512 + @as(usize, cluster) * 4) & 0x0fff_ffff;
    }
    fn set(self: *Fat, cluster: u32, value_: u32) void {
        for (0..2) |copy| {
            const offset = (32 + copy * self.geo.sectors_per_fat) * 512 + @as(usize, cluster) * 4;
            put32(self.bytes, offset, (u32at(self.bytes, offset) & 0xf000_0000) | (value_ & 0x0fff_ffff));
        }
    }
    fn next(self: Fat, cluster: u32) !?u32 {
        _ = try self.clusterOffset(cluster);
        const value_ = self.value(cluster);
        if (value_ >= 0x0fff_fff8) return null;
        _ = try self.clusterOffset(value_);
        return value_;
    }
    fn mark(self: *Fat, owners: []u8, first: u32, expected: ?u32, depth: u8) !void {
        if (expected == 0) {
            if (first != 0) return error.SourceFat;
            return;
        }
        var cluster = first;
        var count: u32 = 0;
        while (true) {
            _ = try self.clusterOffset(cluster);
            if (owners[cluster] != 0) return error.SourceAllocation;
            owners[cluster] = 1;
            self.directory_depth[cluster] = depth;
            count += 1;
            cluster = (try self.next(cluster)) orelse break;
        }
        if (expected) |wanted| if (wanted != count) return error.SourceFat;
    }
    fn audit(self: *Fat, allocator: std.mem.Allocator, owners: []u8) !void {
        const Dir = struct { cluster: u32, depth: u8 };
        var dirs: std.ArrayList(Dir) = .empty;
        defer dirs.deinit(allocator);
        try dirs.append(allocator, .{ .cluster = 2, .depth = 1 });
        var index: usize = 0;
        var entries: usize = 0;
        while (index < dirs.items.len) : (index += 1) {
            const dir = dirs.items[index];
            try self.mark(owners, dir.cluster, null, dir.depth);
            var iterator = Iterator{ .fat = self, .cluster = dir.cluster };
            while (try iterator.next()) |entry| {
                entries += 1;
                if (entries > 8192) return error.FileLimit;
                if (entry.directory()) {
                    if (dir.depth >= maximum_depth or entry.size() != 0) return error.SourceFat;
                    try dirs.append(allocator, .{ .cluster = entry.cluster(), .depth = dir.depth + 1 });
                } else {
                    const clusters: u32 = @intCast((@as(u64, entry.size()) + self.clusterSize() - 1) / self.clusterSize());
                    try self.mark(owners, entry.cluster(), clusters, 0);
                }
            }
        }
        for (2..self.geo.clusters + 2) |i| if ((self.value(@intCast(i)) != 0) != (owners[i] != 0)) return error.SourceAllocation;
    }
    fn child(self: *Fat, parent: u32, name: []const u8) !?Entry {
        var iterator = Iterator{ .fat = self, .cluster = parent };
        var found: ?Entry = null;
        while (try iterator.next()) |entry| if (entry.name.matches(name)) {
            if (found != null) return error.AmbiguousPath;
            found = entry;
        };
        return found;
    }
    fn allocate(self: *Fat, depth: u8) !u32 {
        var cluster = self.free_hint;
        var searched: u32 = 0;
        while (searched < self.geo.clusters) : (searched += 1) {
            if (cluster >= self.geo.clusters + 2) cluster = 2;
            // Until namespace publication the original directory graph must
            // remain readable. Reusing an old directory as early payload
            // would destroy its entries while the old FAT still owns all
            // their chains. A failed payload write then creates orphans.
            const payload_safe = depth != 0 or self.original_directories.len == 0 or self.original_directories[cluster] == 0;
            if (self.value(cluster) == 0 and payload_safe) {
                self.set(cluster, 0x0fff_ffff);
                self.directory_depth[cluster] = depth;
                const offset = try self.clusterOffset(cluster);
                @memset(self.bytes[offset..][0..self.clusterSize()], 0);
                self.free_hint = cluster + 1;
                return cluster;
            }
            cluster += 1;
        }
        return error.ImageFull;
    }
    fn free(self: *Fat, first: u32) !void {
        if (first == 0) return;
        var cluster = first;
        while (true) {
            const following = try self.next(cluster);
            self.set(cluster, 0);
            self.free_hint = @min(self.free_hint, cluster);
            cluster = following orelse break;
        }
    }
    fn unchanged(self: *Fat, entry: Entry, bytes: []const u8) !bool {
        if (entry.size() != bytes.len) return false;
        if (bytes.len == 0) return true;
        var cluster = entry.cluster();
        var done: usize = 0;
        while (done < bytes.len) {
            const offset = try self.clusterOffset(cluster);
            const amount = @min(self.clusterSize(), bytes.len - done);
            if (!std.mem.eql(u8, self.bytes[offset..][0..amount], bytes[done..][0..amount])) return false;
            done += amount;
            cluster = (try self.next(cluster)) orelse break;
        }
        return done == bytes.len;
    }
    fn replace(self: *Fat, change: Change) !bool {
        var parts = std.mem.splitScalar(u8, change.path, '/');
        var parent: u32 = 2;
        var name = parts.next().?;
        while (parts.next()) |next_name| {
            if (try self.child(parent, name)) |entry| {
                if (!entry.directory()) return error.PathConflict;
                parent = entry.cluster();
            } else {
                if (change.bytes == null) return false;
                const depth = self.directory_depth[parent] + 1;
                if (depth > maximum_depth) return error.Path;
                const cluster = try self.allocate(depth);
                const offset = try self.clusterOffset(cluster);
                shortEntry(self.bytes[offset..][0..32], ".          ".*, true, cluster, 0);
                shortEntry(self.bytes[offset + 32 ..][0..32], "..         ".*, true, if (parent == 2) 0 else parent, 0);
                _ = try self.create(parent, name, true, cluster);
                parent = cluster;
            }
            name = next_name;
        }
        const previous = try self.child(parent, name);
        const bytes = change.bytes orelse {
            if (previous) |entry| {
                try self.removeTree(entry, 0);
                return true;
            }
            return false;
        };
        if (previous) |entry| {
            if (entry.directory()) return error.PathConflict;
            if (try self.unchanged(entry, bytes)) return false;
        }
        const entry_offset = if (previous) |entry| entry.offset else try self.create(parent, name, false, 0);
        if (previous) |entry| try self.free(entry.cluster());
        var first: u32 = 0;
        var last: u32 = 0;
        var done: usize = 0;
        while (done < bytes.len) {
            const cluster = try self.allocate(0);
            if (first == 0) first = cluster;
            if (last != 0) self.set(last, cluster);
            last = cluster;
            const amount = @min(self.clusterSize(), bytes.len - done);
            const offset = try self.clusterOffset(cluster);
            @memcpy(self.bytes[offset..][0..amount], bytes[done..][0..amount]);
            done += amount;
        }
        const raw = self.bytes[entry_offset..][0..32];
        put16(raw, 20, @truncate(first >> 16));
        put16(raw, 26, @truncate(first));
        put32(raw, 28, @intCast(bytes.len));
        return true;
    }
    fn removeTree(self: *Fat, entry: Entry, depth: u8) !void {
        if (depth >= maximum_depth) return error.Path;
        if (entry.directory()) {
            var iterator = Iterator{ .fat = self, .cluster = entry.cluster() };
            while (try iterator.next()) |child_entry| try self.removeTree(child_entry, depth + 1);
        }
        try self.free(entry.cluster());
        for (entry.slots[0..entry.slot_count]) |offset| self.bytes[offset] = 0xe5;
    }
    fn create(self: *Fat, parent: u32, name: []const u8, directory: bool, cluster: u32) !usize {
        var short = "R4UP0000BIN".*;
        var serial: u32 = 1;
        while (true) : (serial += 1) {
            if (serial > 65535) return error.FileLimit;
            for (0..4) |i| short[7 - i] = "0123456789ABCDEF"[(serial >> @as(u5, @intCast(i * 4))) & 15];
            var iterator = Iterator{ .fat = self, .cluster = parent };
            var used = false;
            while (try iterator.next()) |entry| if (std.ascii.eqlIgnoreCase(entry.raw[0..11], &short)) {
                used = true;
                break;
            };
            if (!used) break;
        }
        const lfn_count = (name.len + 12) / 13;
        const needed = lfn_count + 1;
        var slots: [21]usize = undefined;
        var found: usize = 0;
        var current = parent;
        var at: usize = 0;
        var past_end = false;
        while (found < needed) {
            if (at == self.clusterSize()) {
                if (try self.next(current)) |following| {
                    current = following;
                } else {
                    const fresh = try self.allocate(self.directory_depth[parent]);
                    self.set(current, fresh);
                    current = fresh;
                }
                at = 0;
            }
            const offset = try self.clusterOffset(current) + at;
            at += 32;
            const first = self.bytes[offset];
            if (first == 0) past_end = true;
            if (past_end or first == 0xe5) {
                slots[found] = offset;
                found += 1;
            } else found = 0;
        }
        // Consuming an end marker must not expose stale bytes after it.
        if (past_end) {
            if (at < self.clusterSize()) {
                self.bytes[(try self.clusterOffset(current)) + at] = 0;
            } else if (try self.next(current)) |following| self.bytes[try self.clusterOffset(following)] = 0;
        }
        const sum = checksum(&short);
        for (0..lfn_count) |i| {
            const ordinal = lfn_count - i;
            const raw = self.bytes[slots[i]..][0..32];
            @memset(raw, 0);
            raw[0] = @as(u8, @intCast(ordinal)) | (if (i == 0) @as(u8, 64) else 0);
            raw[11] = 15;
            raw[13] = sum;
            for (lfn_positions, 0..) |position, j| {
                const source = (ordinal - 1) * 13 + j;
                put16(raw, position, if (source < name.len) name[source] else if (source == name.len) @as(u16, 0) else 0xffff);
            }
        }
        const offset = slots[lfn_count];
        shortEntry(self.bytes[offset..][0..32], short, directory, cluster, 0);
        return offset;
    }
    fn updateInfo(self: *Fat) void {
        var free_count: u32 = 0;
        var next_free: u32 = 0xffff_ffff;
        for (2..self.geo.clusters + 2) |i| if (self.value(@intCast(i)) == 0) {
            free_count += 1;
            if (next_free == 0xffff_ffff) next_free = @intCast(i);
        };
        for ([_]usize{ 1, 7 }) |sector| {
            put32(self.bytes, sector * 512 + 488, free_count);
            put32(self.bytes, sector * 512 + 492, next_free);
        }
    }
    fn order(self: Fat, sector: u32) !u8 {
        if (sector < 32) return if (sector == 1 or sector == 7) final_order else error.BootSectorChanged;
        if (sector < 32 + self.geo.sectors_per_fat) return 2;
        if (sector < self.geo.data_start) return 1;
        const cluster = 2 + (sector - self.geo.data_start) / self.geo.sectors_per_cluster;
        if (cluster >= self.directory_depth.len) return error.SourceFat;
        const depth = self.directory_depth[cluster];
        return if (depth == 0) 0 else 3 + maximum_depth - depth;
    }
};

const lfn_positions = [_]usize{ 1, 3, 5, 7, 9, 14, 16, 18, 20, 22, 24, 28, 30 };
fn checksum(short: []const u8) u8 {
    var result: u8 = 0;
    for (short) |c| result = (if (result & 1 != 0) @as(u8, 128) else 0) +% (result >> 1) +% c;
    return result;
}
fn shortEntry(raw: *[32]u8, short: [11]u8, directory: bool, cluster: u32, size: u32) void {
    @memset(raw, 0);
    @memcpy(raw[0..11], &short);
    raw[11] = if (directory) 16 else 32;
    put16(raw, 20, @truncate(cluster >> 16));
    put16(raw, 26, @truncate(cluster));
    put32(raw, 28, size);
}
fn u16at(bytes: []const u8, at: usize) u16 {
    return std.mem.readInt(u16, bytes[at..][0..2], .little);
}
fn u32at(bytes: []const u8, at: usize) u32 {
    return std.mem.readInt(u32, bytes[at..][0..4], .little);
}
fn put16(bytes: []u8, at: usize, value: u16) void {
    std.mem.writeInt(u16, bytes[at..][0..2], value, .little);
}
fn put32(bytes: []u8, at: usize, value: u32) void {
    std.mem.writeInt(u32, bytes[at..][0..4], value, .little);
}
