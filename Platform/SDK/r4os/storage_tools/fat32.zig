//! FAT32 geometry and streaming formatter, shared with ImageCreator.
const std = @import("std");
const block = @import("io.zig");
pub const reserved_sectors = 32;
pub const fat_count = 2;
pub const root_cluster = 2;
pub const last_data_cluster = 0x0fff_fff6;

pub const Geometry = struct {
    sectors: u32,
    hidden: u32,
    sectors_per_cluster: u32,
    sectors_per_fat: u32,
    data_start: u32,
    clusters: u32,

    pub fn init(sectors: u64, hidden: u64, requested_spc: u32) !Geometry {
        if (sectors > std.math.maxInt(u32) or hidden > std.math.maxInt(u32))
            return error.Geometry;
        if (sectors < 65525) return error.VolumeTooSmall;
        var spc: u32 = if (requested_spc != 0) requested_spc else if (sectors >= 512 * 2048) 8 else 1;
        if (spc > 64 or !std.math.isPowerOfTwo(spc)) return error.Geometry;
        while (true) {
            var fat: u64 = 1;
            while (true) {
                const metadata = reserved_sectors + fat_count * fat;
                if (metadata >= sectors) return error.VolumeTooSmall;
                const needed = (((sectors - metadata) / spc + 2) * 4 + 511) / 512;
                if (needed <= fat) break;
                fat = needed;
            }
            const start = reserved_sectors + fat_count * fat;
            const clusters = (sectors - start) / spc;
            if (clusters < 65525) return error.VolumeTooSmall;
            if (clusters + 1 <= last_data_cluster) return .{
                .sectors = @intCast(sectors),
                .hidden = @intCast(hidden),
                .sectors_per_cluster = spc,
                .sectors_per_fat = @intCast(fat),
                .data_start = @intCast(start),
                .clusters = @intCast(clusters),
            };
            if (requested_spc != 0 or spc == 64) return error.Geometry;
            spc *= 2;
        }
    }

    pub fn boot(self: Geometry, label: [11]u8, serial: u32) [512]u8 {
        var out: [512]u8 = .{0} ** 512;
        @memcpy(out[0..3], &[_]u8{ 0xeb, 0x58, 0x90 });
        @memcpy(out[3..11], "R4OS    ");
        put16(out[11..13], 512);
        out[13] = @intCast(self.sectors_per_cluster);
        put16(out[14..16], reserved_sectors);
        out[16] = fat_count;
        out[21] = 0xf8;
        put16(out[24..26], 32);
        put16(out[26..28], 64);
        put32(out[28..32], self.hidden);
        put32(out[32..36], self.sectors);
        put32(out[36..40], self.sectors_per_fat);
        put32(out[44..48], root_cluster);
        put16(out[48..50], 1);
        put16(out[50..52], 6);
        out[64] = 0x80;
        out[66] = 0x29;
        put32(out[67..71], serial);
        @memcpy(out[71..82], &label);
        @memcpy(out[82..90], "FAT32   ");
        out[510] = 0x55;
        out[511] = 0xaa;
        return out;
    }
};

pub const Plan = struct {
    geometry: Geometry,
    label: [11]u8,
    serial: u32,

    pub fn prepare(sectors: u64, hidden: u64, label: []const u8, serial: u32, sectors_per_cluster: u32) !Plan {
        return .{
            .geometry = try Geometry.init(sectors, hidden, sectors_per_cluster),
            .label = try volumeLabel(label),
            .serial = serial,
        };
    }

    pub fn execute(self: Plan, device: block.Device, full: bool, work: []u8) !void {
        try device.requireExclusive();
        const geo = self.geometry;
        if (!std.meta.eql(geo, try Geometry.init(geo.sectors, geo.hidden, geo.sectors_per_cluster)) or
            device.sectors != geo.sectors or work.len < 1024 or work.len % 1024 != 0) return error.Geometry;
        const half = work.len / 2;
        const expected = work[0..half];
        const observed = work[half..];
        const boot = geo.boot(self.label, self.serial);
        const info = fsInfo(geo.clusters - 1, 3);
        var root: [512]u8 = .{0} ** 512;
        @memcpy(root[0..11], &self.label);
        root[11] = 0x08;
        var fat: [512]u8 = .{0} ** 512;
        put32(fat[0..4], 0x0fff_fff8);
        put32(fat[4..8], 0x0fff_ffff);
        put32(fat[8..12], 0x0fff_ffff);
        device.phase(.invalidate);
        @memset(expected[0..512], 0);
        try device.write(0, expected[0..512]);
        try device.write(6, expected[0..512]);
        // Also invalidate an old NTFS backup at the partition's last LBA.
        try device.write(device.sectors - 1, expected[0..512]);
        device.phase(.erase);
        try device.fill(0, if (full) device.sectors else @as(u64, geo.data_start) + geo.sectors_per_cluster, 0, expected);
        device.phase(.metadata);
        for (0..fat_count) |copy| try device.write(reserved_sectors + copy * @as(u64, geo.sectors_per_fat), &fat);
        try device.write(geo.data_start, &root);
        try device.write(1, &info);
        try device.write(7, &info);
        try device.flush();
        device.phase(.backup);
        try device.write(6, &boot);
        device.phase(.primary);
        try device.write(0, &boot);
        try device.flush();

        try device.verify(0, &boot, observed);
        try device.verify(6, &boot, observed);
        try device.verify(1, &info, observed);
        try device.verify(7, &info, observed);
        try device.verify(geo.data_start, &root, observed);
        for (0..fat_count) |copy| {
            var done: u64 = 0;
            while (done < geo.sectors_per_fat) {
                const count = @min(expected.len / 512, geo.sectors_per_fat - done);
                const length: usize = @intCast(count * 512);
                @memset(expected[0..length], 0);
                if (done == 0) @memcpy(expected[0..512], &fat);
                try device.verify(reserved_sectors + copy * @as(u64, geo.sectors_per_fat) + done, expected[0..length], observed);
                done += count;
            }
        }
        device.complete();
    }
};

pub fn fsInfo(free: u32, next: u32) [512]u8 {
    var out: [512]u8 = .{0} ** 512;
    put32(out[0..4], 0x41615252);
    put32(out[484..488], 0x61417272);
    put32(out[488..492], free);
    put32(out[492..496], next);
    put32(out[508..512], 0xaa55_0000);
    return out;
}

pub fn volumeLabel(text: []const u8) ![11]u8 {
    if (text.len == 0) return "NO NAME    ".*;
    if (text.len > 11) return error.Label;
    var result: [11]u8 = .{' '} ** 11;
    for (text, 0..) |byte, i| {
        if (byte < 0x20 or byte > 0x7e or std.mem.indexOfScalar(u8, "\"*+,./:;<=>?[\\]|", byte) != null)
            return error.Label;
        result[i] = std.ascii.toUpper(byte);
    }
    return result;
}
fn put16(out: *[2]u8, value: u16) void {
    std.mem.writeInt(u16, out, value, .little);
}
fn put32(out: *[4]u8, value: u32) void {
    std.mem.writeInt(u32, out, value, .little);
}
