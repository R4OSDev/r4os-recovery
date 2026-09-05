//! Bounded GPT BIOS installer adapted from Limine 12.0.1 limine.c.
//! Copyright (C) 2019-2026 Mintsuki and contributors. BSD-2-Clause;
//! exact source, payload, license and hashes accompany this module in limine/.
//! R4OS supplies the claim/flush/readback ordering and geometry validation.
const std = @import("std");
const io = @import("io.zig");
const partition = @import("partition.zig");
pub const payload = @embedFile("limine/bios-hdd.bin");
// Matching stage-three companion from the same recorded DevKit release.
// A newer incompatible BIOS companion needs an explicit Recovery refresh.
pub const bios_system_sha256 = "c325db0e68c0954bc1c6b32148fe311e9e6a9de89c47621397cf4f17a707c43d";
pub fn supportsBiosSystem(bytes: []const u8) bool {
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes, &digest, .{});
    return std.mem.eql(u8, &std.fmt.bytesToHex(digest, .lower), bios_system_sha256);
}
const padded_bytes = std.mem.alignForward(usize, payload.len - 512, 512);

/// Read-only compatibility check before a file-level BOOT update. Updating
/// stage three must not silently strand a different installed BIOS loader.
pub fn verifyBios(device: io.Device, table: *const partition.Plan, work: []u8) !void {
    try table.revalidate(device, work);
    if (table.kind != .gpt or work.len < io.scratch_bytes) return error.Geometry;
    var bios: ?partition.Entry = null;
    for (table.entries) |entry| if (entry.present and partition.guid.eql(entry.type_guid, partition.bios_type)) {
        if (bios != null) return error.DuplicateBiosPartition;
        bios = entry;
    };
    const target = bios orelse return error.MissingBiosPartition;
    if (target.count < padded_bytes / 512) return error.Geometry;
    var actual: [512]u8 = undefined;
    try device.read(0, &actual);
    var expected = payload[0..512].*;
    @memcpy(expected[218..224], actual[218..224]);
    @memcpy(expected[440..510], actual[440..510]);
    std.mem.writeInt(u64, expected[0x1a4..][0..8], target.first * 512, .little);
    if (!std.mem.eql(u8, &actual, &expected)) return error.IncompatibleBootChain;
    try device.read(target.first, work[0..padded_bytes]);
    if (!std.mem.eql(u8, work[0 .. payload.len - 512], payload[512..]) or
        !std.mem.allEqual(u8, work[payload.len - 512 .. padded_bytes], 0)) return error.IncompatibleBootChain;
}

pub fn installBios(device: io.Device, table: *const partition.Plan, work: []u8) !void {
    try device.requireExclusive();
    try table.revalidate(device, work);
    if (table.kind != .gpt or work.len < io.scratch_bytes) return error.Geometry;
    var bios: ?partition.Entry = null;
    for (table.entries) |entry| if (entry.present and partition.guid.eql(entry.type_guid, partition.bios_type)) {
        if (bios != null) return error.DuplicateBiosPartition;
        bios = entry;
    };
    const target = bios orelse return error.MissingBiosPartition;
    if (target.first % partition.alignment_sectors != 0 or target.count < 64 or padded_bytes > target.count * 512) return error.Geometry;
    // Only the initial installation owns this partition. Refuse a filesystem
    // signature instead of treating a BIOS-type GUID as permission to erase it.
    var first: [512]u8 = undefined;
    try device.read(target.first, &first);
    if (std.mem.eql(u8, first[3..11], "NTFS    ") or std.mem.eql(u8, first[82..90], "FAT32   ") or
        std.mem.eql(u8, first[54..62], "FAT16   ") or std.mem.eql(u8, first[3..11], "EXFAT   ")) return error.BiosPartitionContainsFilesystem;
    var original: [512]u8 = undefined;
    try device.read(0, &original);
    var mbr = payload[0..512].*;
    @memcpy(mbr[218..224], original[218..224]);
    @memcpy(mbr[440..510], original[440..510]);
    std.mem.writeInt(u64, mbr[0x1a4..][0..8], target.first * 512, .little);
    const stage = work[0..padded_bytes];
    @memset(stage, 0);
    @memcpy(stage[0 .. payload.len - 512], payload[512..]);
    device.phase(.metadata);
    try device.write(target.first, stage);
    try device.flush();
    try device.verify(target.first, stage, work[padded_bytes..]);
    // Make stage 1 reachable only after its complete stage 2 is durable.
    device.phase(.primary);
    try device.write(0, &mbr);
    try device.flush();
    try device.verify(0, &mbr, work);
    device.complete();
}
