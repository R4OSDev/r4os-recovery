//! Partition-table editing belongs to tools. Kernel-facing I/O is supplied
//! by the same bounded adapter as host image files.
const std = @import("std");
const block = @import("io.zig");
const gpt = @import("../gpt_format.zig");
pub const guid = @import("guid.zig");
pub const max_entries = 128;
pub const alignment_sectors: u64 = 2048;
pub const max_array_bytes = max_entries * 128;
pub const Kind = enum { none, mbr, gpt };
pub const esp_type = guid.parse("c12a7328-f81f-11d2-ba4b-00a0c93ec93b").?;
pub const basic_type = guid.parse("ebd0a0a2-b9e5-4433-87c0-68b6b72699c7").?;
pub const bios_type = guid.parse("21686148-6449-6e6f-744e-656564454649").?;

pub const Range = struct { first: u64, count: u64 };
pub const Entry = struct {
    present: bool = false,
    first: u64 = 0,
    count: u64 = 0,
    type_guid: guid.Guid = guid.zero,
    unique_guid: guid.Guid = guid.zero,
    attributes: u64 = 0,
    name: [36]u16 = .{0} ** 36,
    mbr_type: u8 = 0,
    active: bool = false,
    mbr_original: [16]u8 = .{0} ** 16,
};

const Source = struct {
    spans: [5]Range = undefined,
    count: usize = 0,
    digest: [32]u8 = undefined,

    fn add(self: *Source, first: u64, count: u64) void {
        std.debug.assert(self.count < self.spans.len);
        self.spans[self.count] = .{ .first = first, .count = count };
        self.count += 1;
    }
    fn hash(self: *const Source, device: block.Device, scratch: []u8) ![32]u8 {
        if (scratch.len < 512 or scratch.len % 512 != 0) return error.Bounds;
        var digest = std.crypto.hash.sha2.Sha256.init(.{});
        for (self.spans[0..self.count]) |span| {
            var done: u64 = 0;
            while (done < span.count) {
                const count = @min(span.count - done, scratch.len / 512);
                const bytes = scratch[0..@intCast(count * 512)];
                try device.read(span.first + done, bytes);
                digest.update(bytes);
                done += count;
            }
        }
        return digest.finalResult();
    }
};

pub const Plan = struct {
    sectors: u64,
    kind: Kind = .none,
    blank: bool = false,
    disk_guid: guid.Guid = guid.zero,
    disk_id: u32 = 0,
    first_usable: u64 = 1,
    last_usable: u64,
    entry_count: u32 = 0,
    primary_array: u64 = 2,
    backup_array: u64 = 0,
    mbr_prefix: [446]u8 = .{0} ** 446,
    entries: [max_entries]Entry = .{Entry{}} ** max_entries,
    source: Source = .{},
    erase_source_gpt: bool = false,

    pub fn read(device: block.Device, scratch: []u8) !Plan {
        try device.validate();
        if (device.sectors < 3 or scratch.len < max_array_bytes * 2 or scratch.len % 512 != 0)
            return error.Geometry;
        var result = Plan{ .sectors = device.sectors, .last_usable = device.sectors - 1 };
        var mbr: [512]u8 = undefined;
        try device.read(0, &mbr);
        @memcpy(&result.mbr_prefix, mbr[0..446]);
        result.disk_id = le32(mbr[440..444]);
        result.source.add(0, 1);
        result.source.add(1, 1);
        result.source.add(device.sectors - 1, 1);
        var primary_sector: [512]u8 = undefined;
        var backup_sector: [512]u8 = undefined;
        try device.read(1, &primary_sector);
        try device.read(device.sectors - 1, &backup_sector);
        var parsed_hash = std.crypto.hash.sha2.Sha256.init(.{});
        parsed_hash.update(&mbr);
        parsed_hash.update(&primary_sector);
        parsed_hash.update(&backup_sector);
        var occupied: usize = 0;
        var protective: usize = 0;
        if (mbr[510] == 0x55 and mbr[511] == 0xaa) {
            for (0..4) |slot| {
                const bytes = mbr[446 + slot * 16 ..][0..16];
                if (bytes[4] != 0) occupied += 1;
                if (bytes[4] == 0xee) {
                    protective += 1;
                    if (le32(bytes[8..12]) != 1 or le32(bytes[12..16]) != @min(device.sectors - 1, std.math.maxInt(u32)))
                        return error.ProtectiveMbr;
                }
            }
            if (protective != 0) {
                if (protective != 1 or occupied != 1) return error.HybridMbr;
                try result.readGpt(device, scratch, &primary_sector, &backup_sector, &parsed_hash);
            } else {
                result.kind = .mbr;
                result.entry_count = 4;
                for (0..4) |slot| {
                    const bytes = mbr[446 + slot * 16 ..][0..16];
                    if (bytes[4] == 0) {
                        if (le32(bytes[8..12]) != 0 or le32(bytes[12..16]) != 0) return error.PartitionRange;
                        continue;
                    }
                    if (bytes[0] != 0 and bytes[0] != 0x80) return error.ActiveFlag;
                    if (extended(bytes[4])) return error.ExtendedMbrUnsupported;
                    result.entries[slot] = .{
                        .present = true,
                        .first = le32(bytes[8..12]),
                        .count = le32(bytes[12..16]),
                        .mbr_type = bytes[4],
                        .active = bytes[0] == 0x80,
                        .mbr_original = bytes.*,
                    };
                }
            }
        } else {
            result.blank = zero(&mbr) and zero(&primary_sector) and zero(&backup_sector);
        }
        try result.validate();
        result.source.digest = parsed_hash.finalResult();
        // Bind the fingerprint to the bytes that were actually parsed, not
        // to a later table which may have appeared during a read-only scan.
        if (!std.mem.eql(u8, &result.source.digest, &try result.source.hash(device, scratch))) return error.Stale;
        return result;
    }

    fn readGpt(self: *Plan, device: block.Device, scratch: []u8, primary_sector: *const [512]u8, backup_sector: *const [512]u8, parsed_hash: *std.crypto.hash.sha2.Sha256) !void {
        const primary = try gpt.parseHeader(primary_sector, 1, self.sectors);
        const backup = try gpt.parseHeader(backup_sector, self.sectors - 1, self.sectors);
        if (le32(primary_sector[12..16]) != 92 or le32(backup_sector[12..16]) != 92 or
            primary.entry_size != 128 or primary.entry_count == 0 or primary.entry_count > max_entries)
            return error.GptLayoutUnsupported;
        if (!guid.eql(primary.disk_guid, backup.disk_guid) or
            primary.first_usable_lba != backup.first_usable_lba or primary.last_usable_lba != backup.last_usable_lba or
            primary.entry_count != backup.entry_count or primary.entry_size != backup.entry_size or
            primary.entries_crc32 != backup.entries_crc32) return error.GptCopiesDisagree;
        const array_bytes: usize = @intCast(primary.entrySectors() * 512);
        const first = scratch[0..array_bytes];
        const second = scratch[max_array_bytes..][0..array_bytes];
        try device.read(primary.entries_lba, first);
        try device.read(backup.entries_lba, second);
        parsed_hash.update(first);
        parsed_hash.update(second);
        const used: usize = @intCast(primary.entryBytes());
        if (!std.mem.eql(u8, first[0..used], second[0..used]) or crc(first[0..used]) != primary.entries_crc32)
            return error.GptArrayCrc;
        self.kind = .gpt;
        self.disk_guid = primary.disk_guid;
        self.first_usable = primary.first_usable_lba;
        self.last_usable = primary.last_usable_lba;
        self.entry_count = primary.entry_count;
        self.primary_array = primary.entries_lba;
        self.backup_array = backup.entries_lba;
        self.source.add(primary.entries_lba, primary.entrySectors());
        self.source.add(backup.entries_lba, backup.entrySectors());
        for (0..self.entry_count) |slot| {
            const bytes = first[slot * 128 ..][0..128];
            const part = try gpt.parsePartition(bytes, primary) orelse continue;
            self.entries[slot] = .{
                .present = true,
                .first = part.first_lba,
                .count = part.sectorCount(),
                .type_guid = part.type_guid,
                .unique_guid = part.unique_guid,
                .attributes = part.attributes,
                .name = part.name_utf16,
            };
        }
    }

    pub fn initializeGpt(self: *Plan, disk_guid: guid.Guid) !void {
        if (self.kind != .none or !self.blank) return error.NotEmpty;
        if (self.sectors < 68 or guid.isZero(disk_guid)) return error.Geometry;
        self.kind = .gpt;
        self.disk_guid = disk_guid;
        self.first_usable = 34;
        self.last_usable = self.sectors - 34;
        self.entry_count = max_entries;
        self.primary_array = 2;
        self.backup_array = self.sectors - 33;
        self.mbr_prefix = .{0} ** 446;
        self.disk_id = 0;
    }

    pub fn initializeMbr(self: *Plan, disk_id: u32) !void {
        if (self.kind != .none or !self.blank) return error.NotEmpty;
        if (self.sectors > @as(u64, std.math.maxInt(u32)) + 1 or disk_id == 0) return error.Geometry;
        self.kind = .mbr;
        self.disk_guid = guid.zero;
        self.disk_id = disk_id;
        self.entry_count = 4;
        self.first_usable = 1;
        self.last_usable = self.sectors - 1;
        self.mbr_prefix = .{0} ** 446;
    }

    /// Conversion is supported only for an empty, recognised table. Keep
    /// its source fingerprint, and retire old GPT metadata when making MBR.
    pub fn convertEmpty(self: *Plan, kind: Kind, disk_guid: guid.Guid, disk_id: u32) !void {
        try self.validate();
        for (self.entries[0..self.entry_count]) |entry| if (entry.present) return error.NotEmpty;
        if (self.kind == .none and !self.blank) return error.NotEmpty;
        if (kind == .none) return error.Geometry;
        if (kind == self.kind) return error.AlreadyConverted;
        var next = self.*;
        next.kind = .none;
        next.blank = true;
        if (kind == .gpt) try next.initializeGpt(disk_guid) else try next.initializeMbr(disk_id);
        next.erase_source_gpt = self.kind == .gpt and kind == .mbr;
        self.* = next;
    }

    pub fn validate(self: *const Plan) !void {
        if (self.sectors < 3 or self.sectors > std.math.maxInt(u64) / 512 or
            self.first_usable == 0 or self.first_usable > self.last_usable or
            self.last_usable >= self.sectors or self.entry_count > max_entries) return error.Geometry;
        switch (self.kind) {
            .none => if (self.entry_count != 0) return error.Geometry,
            .mbr => if (self.entry_count != 4) return error.Geometry,
            .gpt => {
                if (guid.isZero(self.disk_guid) or self.entry_count == 0) return error.Geometry;
                const count = arraySectors(self.entry_count);
                if (self.primary_array <= 1 or self.primary_array >= self.first_usable or
                    count > self.first_usable - self.primary_array or
                    self.backup_array <= self.last_usable or self.backup_array >= self.sectors - 1 or
                    count > self.sectors - 1 - self.backup_array) return error.Geometry;
            },
        }
        for (self.entries[0..self.entry_count], 0..) |entry, i| {
            if (!entry.present) continue;
            if (entry.count == 0 or entry.first < self.first_usable or entry.first > self.last_usable or
                entry.count - 1 > self.last_usable - entry.first) return error.PartitionRange;
            switch (self.kind) {
                .none => return error.Geometry,
                .mbr => if (entry.mbr_type == 0 or entry.mbr_type == 0xee or extended(entry.mbr_type) or
                    entry.first > std.math.maxInt(u32) or entry.count > std.math.maxInt(u32) or
                    entry.first + entry.count > @as(u64, std.math.maxInt(u32)) + 1) return error.MbrCapacity,
                .gpt => if (guid.isZero(entry.type_guid) or guid.isZero(entry.unique_guid) or guid.eql(entry.unique_guid, self.disk_guid))
                    return error.PartitionGuid,
            }
            for (self.entries[0..i]) |other| {
                if (!other.present) continue;
                if (entry.first < other.first + other.count and other.first < entry.first + entry.count) return error.Overlap;
                if (self.kind == .gpt and guid.eql(entry.unique_guid, other.unique_guid)) return error.DuplicateGuid;
            }
        }
    }

    pub fn add(self: *Plan, entry: Entry) !u32 {
        if (!entry.present or entry.first % alignment_sectors != 0) return error.Alignment;
        for (self.entries[0..self.entry_count], 0..) |*slot, i| {
            if (slot.present) continue;
            slot.* = entry;
            errdefer slot.* = .{};
            try self.validate();
            return @intCast(i + 1);
        }
        return error.PartitionCapacity;
    }

    pub fn remove(self: *Plan, number: u32) !void {
        if (number == 0 or number > self.entry_count or !self.entries[number - 1].present) return error.NotFound;
        self.entries[number - 1] = .{};
    }

    pub fn get(self: *Plan, number: u32) !*Entry {
        if (number == 0 or number > self.entry_count or !self.entries[number - 1].present) return error.NotFound;
        return &self.entries[number - 1];
    }

    pub fn freeRanges(self: *const Plan, out: []Range) !usize {
        try self.validate();
        var cursor = self.first_usable;
        var count: usize = 0;
        while (cursor <= self.last_usable) {
            var next: ?Entry = null;
            for (self.entries[0..self.entry_count]) |entry| {
                if (!entry.present or entry.first < cursor) continue;
                if (next == null or entry.first < next.?.first) next = entry;
            }
            const end = if (next) |entry| entry.first else self.last_usable + 1;
            if (cursor < end) {
                if (count == out.len) return error.Capacity;
                out[count] = .{ .first = cursor, .count = end - cursor };
                count += 1;
            }
            if (next) |entry| cursor = entry.first + entry.count else break;
        }
        return count;
    }

    pub fn firstFit(self: *const Plan, count: u64) !u64 {
        if (count == 0) return error.Geometry;
        var ranges: [max_entries + 1]Range = undefined;
        const length = try self.freeRanges(&ranges);
        for (ranges[0..length]) |range| {
            const first = std.mem.alignForward(u64, range.first, alignment_sectors);
            const skipped = first - range.first;
            if (skipped <= range.count and count <= range.count - skipped) return first;
        }
        return error.NoSpace;
    }

    /// Changes only the end of one existing partition. A growth request may
    /// consume only immediately adjacent free sectors; no partition is moved.
    pub fn extend(self: *Plan, number: u32, extra_sectors: ?u64) !u64 {
        try self.validate();
        const entry = try self.get(number);
        const end = entry.first + entry.count;
        var limit = self.last_usable + 1;
        for (self.entries[0..self.entry_count]) |other| {
            if (other.present and other.first >= end) limit = @min(limit, other.first);
        }
        const available = limit - end;
        const extra = extra_sectors orelse (available / alignment_sectors * alignment_sectors);
        if (extra == 0 or extra > available) return error.NoSpace;
        const old_count = entry.count;
        entry.count += extra;
        self.validate() catch |err| {
            entry.count = old_count;
            return err;
        };
        return entry.count;
    }

    pub fn revalidate(self: *const Plan, device: block.Device, work: []u8) !void {
        try self.validate();
        if (device.sectors != self.sectors or self.source.count == 0) return error.Geometry;
        if (!std.mem.eql(u8, &self.source.digest, &try self.source.hash(device, work))) return error.Stale;
    }

    /// The source fingerprint is rechecked after the caller acquires its
    /// whole-device claim. Existing unknown layouts are never rewritten.
    pub fn commit(self: *const Plan, device: block.Device, work: []u8) !void {
        try self.validate();
        try device.requireExclusive();
        if (device.sectors != self.sectors or self.kind == .none or
            self.source.count == 0 or work.len < max_array_bytes * 2 or work.len % 512 != 0) return error.Geometry;
        if (self.erase_source_gpt and (self.kind != .mbr or self.source.count != 5)) return error.Geometry;
        if (!std.mem.eql(u8, &self.source.digest, &try self.source.hash(device, work))) return error.Stale;
        if (self.erase_source_gpt) {
            device.phase(.erase);
            // The original, validated spans exclude every filesystem region.
            // Retire the backup first, then the primary, before publishing MBR.
            for ([_]usize{ 4, 2, 3, 1 }) |i| {
                const span = self.source.spans[i];
                try device.fill(span.first, span.count, 0, work);
            }
            try device.flush();
            @memset(work[0..512], 0);
            for (self.source.spans[1..self.source.count]) |span| {
                for (0..span.count) |offset| try device.verify(span.first + offset, work[0..512], work[512..1024]);
            }
        }
        var mbr: [512]u8 = .{0} ** 512;
        @memcpy(mbr[0..446], &self.mbr_prefix);
        put32(mbr[440..444], self.disk_id);
        mbr[510] = 0x55;
        mbr[511] = 0xaa;
        if (self.kind == .mbr) {
            for (self.entries[0..4], 0..) |entry, slot| {
                if (!entry.present) continue;
                const bytes = mbr[446 + slot * 16 ..][0..16];
                @memcpy(bytes, &entry.mbr_original);
                bytes[0] = if (entry.active) 0x80 else 0;
                bytes[4] = entry.mbr_type;
                if (zero(&entry.mbr_original)) {
                    @memcpy(bytes[1..4], &[_]u8{ 0xfe, 0xff, 0xff });
                    @memcpy(bytes[5..8], &[_]u8{ 0xfe, 0xff, 0xff });
                }
                put32(bytes[8..12], @intCast(entry.first));
                put32(bytes[12..16], @intCast(entry.count));
            }
        } else {
            mbr[450] = 0xee;
            @memcpy(mbr[447..450], &[_]u8{ 0, 2, 0 });
            @memcpy(mbr[451..454], &[_]u8{ 0xff, 0xff, 0xff });
            put32(mbr[454..458], 1);
            put32(mbr[458..462], @intCast(@min(self.sectors - 1, std.math.maxInt(u32))));
            const array_len: usize = @intCast(arraySectors(self.entry_count) * 512);
            const array = work[0..array_len];
            const readback = work[max_array_bytes..][0..max_array_bytes];
            @memset(array, 0);
            for (self.entries[0..self.entry_count], 0..) |entry, slot| {
                if (!entry.present) continue;
                const bytes = array[slot * 128 ..][0..128];
                @memcpy(bytes[0..16], &entry.type_guid);
                @memcpy(bytes[16..32], &entry.unique_guid);
                put64(bytes[32..40], entry.first);
                put64(bytes[40..48], entry.first + entry.count - 1);
                put64(bytes[48..56], entry.attributes);
                for (entry.name, 0..) |unit, i| std.mem.writeInt(u16, bytes[56 + i * 2 ..][0..2], unit, .little);
            }
            const checksum = crc(array[0 .. @as(usize, self.entry_count) * 128]);
            const primary = self.header(1, self.sectors - 1, self.primary_array, checksum);
            const backup = self.header(self.sectors - 1, 1, self.backup_array, checksum);
            device.phase(.backup);
            try device.write(self.backup_array, array);
            try device.write(self.sectors - 1, &backup);
            try device.flush();
            try device.verify(self.backup_array, array, readback);
            try device.verify(self.sectors - 1, &backup, readback);
            device.phase(.primary);
            try device.write(self.primary_array, array);
            try device.write(1, &primary);
            try device.flush();
            try device.verify(self.primary_array, array, readback);
            try device.verify(1, &primary, readback);
        }
        device.phase(.primary);
        try device.write(0, &mbr);
        try device.flush();
        try device.verify(0, &mbr, work);
        device.complete();
    }

    fn header(self: *const Plan, current: u64, other: u64, entries: u64, checksum: u32) [512]u8 {
        var out: [512]u8 = .{0} ** 512;
        @memcpy(out[0..8], "EFI PART");
        put32(out[8..12], 0x10000);
        put32(out[12..16], 92);
        put64(out[24..32], current);
        put64(out[32..40], other);
        put64(out[40..48], self.first_usable);
        put64(out[48..56], self.last_usable);
        @memcpy(out[56..72], &self.disk_guid);
        put64(out[72..80], entries);
        put32(out[80..84], self.entry_count);
        put32(out[84..88], 128);
        put32(out[88..92], checksum);
        put32(out[16..20], crc(out[0..92]));
        return out;
    }
};

/// Explicit destructive CLEAN. The quick form clears both boundary MiB;
/// ALL clears the entire target in the same bounded buffer. A new table is
/// a separate operation and cannot be used as an in-place conversion.
pub fn clean(device: block.Device, all: bool, scratch: []u8) !void {
    try device.requireExclusive();
    if (scratch.len < 1024 or scratch.len % 1024 != 0) return error.Bounds;
    device.phase(.erase);
    const count = if (all) device.sectors else @min(device.sectors, alignment_sectors);
    try device.fill(0, count, 0, scratch);
    if (!all and count < device.sectors) try device.fill(device.sectors - count, count, 0, scratch);
    try device.flush();
    @memset(scratch[0..512], 0);
    try device.verify(0, scratch[0..512], scratch[512..1024]);
    try device.verify(device.sectors - 1, scratch[0..512], scratch[512..1024]);
    device.complete();
}

pub fn asciiName(name: []const u8) ![36]u16 {
    if (name.len > 36) return error.Name;
    var result: [36]u16 = .{0} ** 36;
    for (name, 0..) |byte, i| {
        if (byte < 0x20 or byte > 0x7e) return error.Name;
        result[i] = byte;
    }
    return result;
}

fn arraySectors(count: u32) u64 {
    return (@as(u64, count) * 128 + 511) / 512;
}
fn extended(value: u8) bool {
    return value == 5 or value == 0xf or value == 0x85;
}
fn zero(bytes: []const u8) bool {
    for (bytes) |byte| if (byte != 0) return false;
    return true;
}
fn crc(bytes: []const u8) u32 {
    var state = gpt.Crc32{};
    state.update(bytes);
    return state.finish();
}
fn le32(bytes: *const [4]u8) u32 {
    return std.mem.readInt(u32, bytes, .little);
}
fn put32(bytes: *[4]u8, value: u32) void {
    std.mem.writeInt(u32, bytes, value, .little);
}
fn put64(bytes: *[8]u8, value: u64) void {
    std.mem.writeInt(u64, bytes, value, .little);
}
