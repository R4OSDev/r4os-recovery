//! Bounded, read-only view of canonical R4OS FAT32 image content. Package
//! import compares files through FAT chains; it never trusts byte searches
//! or copies a source partition's geometry onto a physical target.
const std = @import("std");
const format = @import("fat32.zig");
pub const View = struct {
    bytes: []const u8,
    geometry: format.Geometry,

    pub fn init(bytes: []const u8, hidden: u64) !View {
        if (bytes.len < 512 or bytes.len % 512 != 0) return error.SourceFat;
        const geo = try format.Geometry.init(bytes.len / 512, hidden, bytes[13]);
        const boot = geo.boot(bytes[71..82].*, u32at(bytes, 67));
        if (!std.mem.eql(u8, bytes[0..512], &boot) or !std.mem.eql(u8, bytes[6 * 512 ..][0..512], &boot)) return error.SourceFat;
        const fat_size = @as(usize, geo.sectors_per_fat) * 512;
        if (!std.mem.eql(u8, bytes[32 * 512 ..][0..fat_size], bytes[32 * 512 + fat_size ..][0..fat_size])) return error.SourceFat;
        return .{ .bytes = bytes, .geometry = geo };
    }

    pub fn readFile(self: View, allocator: std.mem.Allocator, path: []const u8, limit: usize) ![]u8 {
        const entry = try self.find(path);
        if (entry.directory or entry.size > limit) return error.SourceFat;
        const out = try allocator.alloc(u8, entry.size);
        errdefer allocator.free(out);
        try self.content(entry, out, null);
        return out;
    }

    pub fn matches(self: View, path: []const u8, expected: []const u8) !void {
        const entry = try self.find(path);
        if (entry.directory or entry.size != expected.len) return error.SourceContentMismatch;
        try self.content(entry, null, expected);
    }

    const Entry = struct { cluster: u32, size: u32, directory: bool };
    fn content(self: View, entry: Entry, out: ?[]u8, expected: ?[]const u8) !void {
        if (entry.size == 0) {
            if (entry.cluster != 0) return error.SourceFat;
            return;
        }
        var cluster = entry.cluster;
        var offset: usize = 0;
        while (offset < entry.size) {
            const data = try self.clusterBytes(cluster);
            const amount = @min(data.len, entry.size - offset);
            if (out) |target| @memcpy(target[offset..][0..amount], data[0..amount]);
            if (expected) |wanted| if (!std.mem.eql(u8, wanted[offset..][0..amount], data[0..amount])) return error.SourceContentMismatch;
            offset += amount;
            const following = try self.next(cluster);
            if (offset == entry.size) {
                if (following != null) return error.SourceFat;
            } else cluster = following orelse return error.SourceFat;
        }
    }

    fn find(self: View, path: []const u8) !Entry {
        if (path.len == 0 or path.len > 1023) return error.SourceFat;
        var parts = std.mem.splitScalar(u8, std.mem.trimStart(u8, path, "/"), '/');
        var current = Entry{ .cluster = 2, .size = 0, .directory = true };
        var depth: usize = 0;
        while (parts.next()) |part| {
            depth += 1;
            if (!current.directory or depth > 24 or part.len == 0 or part.len > 255 or std.mem.eql(u8, part, ".") or std.mem.eql(u8, part, "..")) return error.SourceFat;
            current = try self.child(current.cluster, part);
        }
        return current;
    }

    fn child(self: View, start: u32, wanted: []const u8) !Entry {
        var cluster = start;
        var traversed: u32 = 0;
        var entries: usize = 0;
        var found: ?Entry = null;
        var lfn: [260]u16 = .{0xffff} ** 260;
        var sequence: u8 = 0;
        var checksum: u8 = 0;
        var lfn_active = false;
        while (true) {
            traversed += 1;
            if (traversed > self.geometry.clusters) return error.SourceFat;
            const data = try self.clusterBytes(cluster);
            var at: usize = 0;
            while (at < data.len) : (at += 32) {
                entries += 1;
                if (entries > 262144) return error.SourceFat;
                const raw = data[at..][0..32];
                if (raw[0] == 0) {
                    if (lfn_active) return error.SourceFat;
                    return found orelse error.SourceFileMissing;
                }
                if (raw[0] == 0xe5) {
                    lfn_active = false;
                    continue;
                }
                if (raw[11] == 0x0f) {
                    const index = raw[0] & 0x1f;
                    if (index == 0 or index > 20 or raw[0] & 0xa0 != 0 or raw[12] != 0 or u16at(raw, 26) != 0) return error.SourceFat;
                    if (raw[0] & 0x40 != 0) {
                        if (lfn_active) return error.SourceFat;
                        @memset(&lfn, 0xffff);
                        sequence = index;
                        checksum = raw[13];
                        lfn_active = true;
                    }
                    if (!lfn_active or sequence != index or raw[13] != checksum) return error.SourceFat;
                    const positions = [_]usize{ 1, 3, 5, 7, 9, 14, 16, 18, 20, 22, 24, 28, 30 };
                    for (positions, 0..) |pos, i| lfn[(@as(usize, index) - 1) * 13 + i] = u16at(raw, pos);
                    sequence -= 1;
                    continue;
                }
                var name: [260]u8 = undefined;
                var length: usize = 0;
                if (lfn_active) {
                    var actual: u8 = 0;
                    for (raw[0..11]) |c| actual = (if (actual & 1 != 0) @as(u8, 0x80) else 0) +% (actual >> 1) +% c;
                    if (sequence != 0 or actual != checksum or raw[11] & 8 != 0) return error.SourceFat;
                    var ended = false;
                    for (lfn) |c| {
                        if (c == 0 or c == 0xffff) {
                            ended = true;
                            continue;
                        }
                        if (ended or c < 32 or c > 126 or length >= 255) return error.SourceFat;
                        name[length] = @intCast(c);
                        length += 1;
                    }
                } else {
                    const base = std.mem.trimEnd(u8, raw[0..8], " ");
                    const ext = std.mem.trimEnd(u8, raw[8..11], " ");
                    @memcpy(name[0..base.len], base);
                    length = base.len;
                    if (ext.len != 0) {
                        name[length] = '.';
                        length += 1;
                        @memcpy(name[length..][0..ext.len], ext);
                        length += ext.len;
                    }
                }
                lfn_active = false;
                if (raw[11] & 8 != 0 or std.mem.eql(u8, name[0..length], ".") or std.mem.eql(u8, name[0..length], "..")) continue;
                if (std.ascii.eqlIgnoreCase(name[0..length], wanted)) {
                    if (found != null) return error.SourceFat;
                    found = .{ .cluster = (@as(u32, u16at(raw, 20)) << 16) | u16at(raw, 26), .size = u32at(raw, 28), .directory = raw[11] & 16 != 0 };
                }
            }
            cluster = (try self.next(cluster)) orelse {
                if (lfn_active) return error.SourceFat;
                return found orelse error.SourceFileMissing;
            };
        }
    }

    fn clusterBytes(self: View, cluster: u32) ![]const u8 {
        if (cluster < 2 or cluster >= self.geometry.clusters + 2) return error.SourceFat;
        const sector = @as(usize, self.geometry.data_start) + @as(usize, cluster - 2) * self.geometry.sectors_per_cluster;
        return self.bytes[sector * 512 ..][0 .. @as(usize, self.geometry.sectors_per_cluster) * 512];
    }
    fn next(self: View, cluster: u32) !?u32 {
        _ = try self.clusterBytes(cluster);
        const value = u32at(self.bytes, 32 * 512 + @as(usize, cluster) * 4) & 0x0fff_ffff;
        if (value >= 0x0fff_fff8) return null;
        if (value < 2 or value >= self.geometry.clusters + 2) return error.SourceFat;
        return value;
    }
};
fn u16at(bytes: []const u8, at: usize) u16 {
    return std.mem.readInt(u16, bytes[at..][0..2], .little);
}
fn u32at(bytes: []const u8, at: usize) u32 {
    return std.mem.readInt(u32, bytes[at..][0..4], .little);
}
