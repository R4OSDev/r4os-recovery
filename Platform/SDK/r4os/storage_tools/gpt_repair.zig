//! GPT inspection and repair from one unambiguous intact counterpart.
//! The surviving copy and protective MBR are never written by repair.
const std = @import("std");
const io = @import("io.zig");
const gpt = @import("../gpt_format.zig");
const table = @import("partition.zig");
const Hash = std.crypto.hash.sha2.Sha256;
const Copy = struct {
    sector: [512]u8 = undefined,
    header: ?gpt.Header = null,
    array: [table.max_array_bytes]u8 = undefined,
    length: usize = 0,
    reason: ?anyerror = null,
    pub fn valid(self: *const Copy) bool {
        return self.reason == null and self.header != null;
    }
};
pub const Status = enum { healthy, primary_damaged, backup_damaged, both_invalid, conflict, protective_mbr_invalid };
pub const Report = struct {
    allocator: std.mem.Allocator,
    sectors: u64,
    copies: [2]Copy = .{ .{}, .{} },
    mbr: [512]u8 = undefined,
    mbr_reason: ?anyerror = null,
    status: Status = .both_invalid,
    fingerprint: [32]u8 = undefined,

    pub fn read(allocator: std.mem.Allocator, device: io.Device) !*Report {
        try device.validate();
        if (device.sectors < 68) return error.Geometry;
        const self = try allocator.create(Report);
        errdefer allocator.destroy(self);
        self.* = .{ .allocator = allocator, .sectors = device.sectors };
        try device.read(0, &self.mbr);
        checkMbr(&self.mbr, device.sectors) catch |err| {
            self.mbr_reason = err;
        };
        var hash = Hash.init(.{});
        hash.update(&self.mbr);
        for (&self.copies, 0..) |*copy, index| {
            const lba: u64 = if (index == 0) 1 else device.sectors - 1;
            try device.read(lba, &copy.sector);
            hash.update(&copy.sector);
            const header = gpt.parseHeader(&copy.sector, lba, device.sectors) catch |err| {
                copy.reason = err;
                continue;
            };
            copy.header = header;
            if (get(u32, &copy.sector, 12) != 92 or header.entry_size != 128 or header.entry_count > table.max_entries) {
                copy.reason = error.GptLayoutUnsupported;
                continue;
            }
            copy.length = @intCast(header.entrySectors() * 512);
            try device.read(header.entries_lba, copy.array[0..copy.length]);
            hash.update(copy.array[0..copy.length]);
            validateCopy(copy, device.sectors) catch |err| {
                copy.reason = err;
            };
        }
        self.fingerprint = hash.finalResult();
        const a = &self.copies[0];
        const b = &self.copies[1];
        self.status = if (self.mbr_reason != null) .protective_mbr_invalid else if (!a.valid() and !b.valid()) .both_invalid else if (a.header != null and b.header != null and !related(a.header.?, b.header.?)) .conflict else if (a.valid() and b.valid())
            (if (std.mem.eql(u8, a.array[0..@intCast(a.header.?.entryBytes())], b.array[0..@intCast(b.header.?.entryBytes())])) .healthy else .conflict)
        else if (a.valid()) .backup_damaged else .primary_damaged;
        return self;
    }
    pub fn deinit(self: *Report) void {
        self.allocator.destroy(self);
    }
    pub fn repairable(self: *const Report) !usize {
        return switch (self.status) {
            .primary_damaged => 0,
            .backup_damaged => 1,
            .healthy => error.GptAlreadyHealthy,
            .both_invalid => error.GptBothInvalid,
            .conflict => error.GptCopiesDisagree,
            .protective_mbr_invalid => error.ProtectiveMbr,
        };
    }
    /// Revalidate every observed header/array after exclusive admission.
    /// Write/flush/read back the missing array before publishing its header.
    /// A failed repair never destroys or rewrites the surviving copy.
    pub fn repair(self: *const Report, device: io.Device, work: []u8) !void {
        const bad = try self.repairable();
        try device.requireExclusive();
        if (device.sectors != self.sectors or work.len < 512 or work.len % 512 != 0) return error.Geometry;
        const current = try Report.read(self.allocator, device);
        defer current.deinit();
        if (!std.mem.eql(u8, &self.fingerprint, &current.fingerprint) or self.status != current.status) return error.Stale;
        const good = &self.copies[1 - bad];
        const header = good.header.?;
        const new_lba: u64 = if (bad == 0) 1 else self.sectors - 1;
        const array_lba = if (self.copies[bad].header) |old| old.entries_lba else if (bad == 0) 2 else self.sectors - 1 - header.entrySectors();
        var new_header = good.sector;
        put(u64, &new_header, 24, new_lba);
        put(u64, &new_header, 32, header.current_lba);
        put(u64, &new_header, 72, array_lba);
        put(u32, &new_header, 16, 0);
        put(u32, &new_header, 16, crc(new_header[0..92]));
        // The good copy's reserved boundaries must admit the repaired copy.
        // Otherwise there is no safe counterpart location to infer.
        _ = try gpt.parseHeader(&new_header, new_lba, device.sectors);
        device.phase(if (bad == 0) .primary else .backup);
        try device.write(array_lba, good.array[0..good.length]);
        try device.flush();
        try device.verify(array_lba, good.array[0..good.length], work);
        device.phase(if (bad == 0) .primary else .backup);
        try device.write(new_lba, &new_header);
        try device.flush();
        try device.verify(new_lba, &new_header, work);
        // Verify intact source bytes too; success requires both copies.
        try device.verify(header.current_lba, &good.sector, work);
        try device.verify(header.entries_lba, good.array[0..good.length], work);
        try device.verify(0, &self.mbr, work);
        device.complete();
    }
};
fn related(a: gpt.Header, b: gpt.Header) bool {
    return table.guid.eql(a.disk_guid, b.disk_guid) and a.first_usable_lba == b.first_usable_lba and
        a.last_usable_lba == b.last_usable_lba and a.entry_count == b.entry_count and a.entry_size == b.entry_size;
}
fn validateCopy(copy: *const Copy, sectors: u64) !void {
    const h = copy.header.?;
    if (table.guid.isZero(h.disk_guid)) return error.PartitionGuid;
    if (crc(copy.array[0..@intCast(h.entryBytes())]) != h.entries_crc32) return error.GptArrayCrc;
    // Both counterpart metadata areas must fit outside all usable sectors.
    if (h.first_usable_lba < 2 + h.entrySectors() or h.last_usable_lba >= sectors - 1 - h.entrySectors()) return error.Geometry;
    for (0..h.entry_count) |i| {
        const a = try gpt.parsePartition(copy.array[i * 128 ..][0..128], h) orelse continue;
        if (table.guid.isZero(a.unique_guid) or table.guid.eql(a.unique_guid, h.disk_guid)) return error.PartitionGuid;
        for (0..i) |j| {
            const b = (try gpt.parsePartition(copy.array[j * 128 ..][0..128], h)) orelse continue;
            if (a.first_lba <= b.last_lba and b.first_lba <= a.last_lba) return error.Overlap;
            if (table.guid.eql(a.unique_guid, b.unique_guid)) return error.DuplicateGuid;
        }
    }
}
fn checkMbr(mbr: *const [512]u8, sectors: u64) !void {
    if (mbr[510] != 0x55 or mbr[511] != 0xaa) return error.ProtectiveMbr;
    var count: usize = 0;
    for (0..4) |i| {
        const p = mbr[446 + i * 16 ..][0..16];
        if (p[4] == 0) {
            if (get(u32, p, 8) != 0 or get(u32, p, 12) != 0) return error.ProtectiveMbr;
            continue;
        }
        if (p[4] != 0xee or p[0] != 0 or get(u32, p, 8) != 1 or get(u32, p, 12) != @min(sectors - 1, std.math.maxInt(u32))) return error.ProtectiveMbr;
        count += 1;
    }
    if (count != 1) return error.ProtectiveMbr;
}
fn get(comptime T: type, data: []const u8, at: usize) T {
    return std.mem.readInt(T, data[at..][0..@sizeOf(T)], .little);
}
fn put(comptime T: type, data: []u8, at: usize, value: T) void {
    std.mem.writeInt(T, data[at..][0..@sizeOf(T)], value, .little);
}
fn crc(bytes: []const u8) u32 {
    var state = gpt.Crc32{};
    state.update(bytes);
    return state.finish();
}
