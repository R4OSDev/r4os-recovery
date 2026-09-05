// Recovery workflow identities. Drive letters are used only for leased reads.
const std = @import("std");
const abi = @import("r4os").abi;
pub const installation = @import("installation");
pub const guid = installation.guid;
pub const OperatingSystems = @import("os_probe.zig").Names;
pub const Operation = enum { install, system, recovery };
pub const Source = enum { cached, github };

pub fn cachePath(operation: Operation) [:0]const u8 {
    return if (operation == .recovery) "R:\\INSTALL\\RECOVERY.ZIP" else "R:\\INSTALL\\RELEASE.ZIP";
}

pub const Disk = struct {
    info: abi.StorageDeviceInfo,
    partitions: []abi.StoragePartitionInfo,
    systems: OperatingSystems = .{},
    invalid_manifest: bool = false,
    ambiguous: bool = false,
};
pub const Installed = struct {
    disk: usize,
    manifest: installation.Manifest,
    boot: abi.StorageVolumeInfo,
    hash: [32]u8,
    parts: [5]abi.StorageTarget,
    ambiguous: bool = false,
};
pub const Target = struct {
    operation: Operation,
    disk: usize,
    installed: ?usize = null,
};
pub const Boot = struct { device: abi.StorageDeviceRef, usb: bool };

pub fn sameDevice(a: abi.StorageDeviceRef, b: abi.StorageDeviceRef) bool {
    return a.slot == b.slot and a.generation == b.generation;
}
pub fn sameTarget(a: abi.StorageTarget, b: abi.StorageTarget) bool {
    return sameDevice(a.device, b.device) and a.layout_generation == b.layout_generation and
        a.first_lba == b.first_lba and a.sector_count == b.sector_count and
        a.partition_number == b.partition_number and a.kind == b.kind and guid.eql(a.partition_guid, b.partition_guid);
}

pub fn allowed(boot: ?Boot, disk: Disk, operation: Operation) bool {
    const source = boot orelse return false;
    const d = disk.info;
    if (d.flags & abi.storage_device_ram != 0 or d.bus == abi.storage_bus_ram or d.sector_bytes != 512 or
        d.flags & abi.storage_device_writable == 0 or d.flags & (abi.storage_device_claimed | abi.storage_device_unsupported | abi.storage_device_partial) != 0) return false;
    if (!source.usb and d.bus == abi.storage_bus_usb) return false;
    if (operation == .install) {
        // Fixed five-part layout, at least 16 MB DATA and final GPT records.
        if (d.sector_count < 3411968 + 32768 + 34) return false;
        return !(source.usb and sameDevice(source.device, d.reference));
    }
    return !disk.ambiguous and
        d.flags & (abi.storage_device_table_valid | abi.storage_device_gpt) == (abi.storage_device_table_valid | abi.storage_device_gpt) and
        d.flags & (abi.storage_device_failed | abi.storage_device_partial) == 0;
}

// The shared parser owns schema/roles/types/ranges. Bind every parsed role
// to the live ABI inventory, including the BOOT volume containing the file.
pub fn bind(disk: Disk, boot: abi.StorageVolumeInfo, manifest: installation.Manifest) ?[5]abi.StorageTarget {
    if (!sameDevice(disk.info.reference, boot.target.device) or
        disk.info.flags & (abi.storage_device_table_valid | abi.storage_device_gpt) != (abi.storage_device_table_valid | abi.storage_device_gpt) or
        !guid.eql(disk.info.disk_guid, manifest.disk_guid)) return null;
    var targets: [5]abi.StorageTarget = undefined;
    for (manifest.partitions, 0..) |part, i| {
        var found: ?abi.StorageTarget = null;
        for (disk.partitions) |actual| {
            if (!guid.eql(part.partition_guid, actual.target.partition_guid)) continue;
            if (found != null or !guid.eql(part.type_guid, actual.type_guid) or part.first_lba != actual.target.first_lba or
                part.sector_count != actual.target.sector_count or actual.target.layout_generation != disk.info.layout_generation or
                !sameDevice(actual.target.device, disk.info.reference)) return null;
            found = actual.target;
        }
        targets[i] = found orelse return null;
    }
    if (!sameTarget(targets[@intFromEnum(installation.Role.BOOT)], boot.target)) return null;
    return targets;
}

pub fn flagAmbiguities(disks: []Disk, installed: []Installed) void {
    for (disks, 0..) |*disk, i| {
        for (disks[0..i]) |*other| {
            if (!guid.isZero(disk.info.disk_guid) and guid.eql(disk.info.disk_guid, other.info.disk_guid)) {
                disk.ambiguous = true;
                other.ambiguous = true;
            }
            for (disk.partitions) |p| for (other.partitions) |q| {
                if (!guid.isZero(p.target.partition_guid) and guid.eql(p.target.partition_guid, q.target.partition_guid)) {
                    disk.ambiguous = true;
                    other.ambiguous = true;
                }
            };
        }
        for (disk.partitions, 0..) |p, j| for (disk.partitions[0..j]) |q| {
            if (!guid.isZero(p.target.partition_guid) and guid.eql(p.target.partition_guid, q.target.partition_guid)) disk.ambiguous = true;
        };
    }
    for (installed, 0..) |*a, i| for (installed[0..i]) |*b| {
        if (guid.eql(a.manifest.installation_id, b.manifest.installation_id)) {
            a.ambiguous = true;
            b.ambiguous = true;
        }
    };
}

pub fn affected(target: Target, disks: []const Disk, installed: []const Installed) abi.StorageTarget {
    if (target.operation == .install) return @import("r4os").storage.Context.wholeDevice(disks[target.disk].info);
    return installed[target.installed.?].parts[@intFromEnum(if (target.operation == .system) installation.Role.SYSTEM else installation.Role.RECOVERY)];
}

pub fn unchanged(old: Disk, current: Disk) bool {
    return sameDevice(old.info.reference, current.info.reference) and old.info.layout_generation == current.info.layout_generation and
        old.info.sector_count == current.info.sector_count and old.info.sector_bytes == current.info.sector_bytes and
        old.info.bus == current.info.bus and guid.eql(old.info.disk_guid, current.info.disk_guid);
}

test "boot policy and identity never derive write authority from OS names" {
    const t = std.testing;
    var disk = Disk{ .info = .{ .reference = .{ .slot = 2, .generation = 1 }, .sector_count = 4194304, .sector_bytes = 512, .flags = abi.storage_device_writable | abi.storage_device_table_valid | abi.storage_device_gpt, .bus = abi.storage_bus_nvme }, .partitions = &.{} };
    const local = Boot{ .device = disk.info.reference, .usb = false };
    const usb = Boot{ .device = .{ .slot = 3, .generation = 1 }, .usb = true };
    try t.expect(allowed(local, disk, .install));
    try t.expect(allowed(usb, disk, .install));
    try t.expect(!allowed(null, disk, .install));
    disk.info.flags |= abi.storage_device_partial;
    try t.expect(!allowed(local, disk, .install));
    disk.info.flags &= ~abi.storage_device_partial;
    disk.info.bus = abi.storage_bus_usb;
    try t.expect(!allowed(local, disk, .install));
    disk.info.reference = usb.device;
    try t.expect(!allowed(usb, disk, .install));
    try t.expect(allowed(usb, disk, .recovery));
    disk.ambiguous = true;
    try t.expect(!allowed(usb, disk, .system));
    disk.systems = .{ .windows = true, .linux = true, .r4os = true };
    try t.expect(!allowed(usb, disk, .recovery));
    var newer = disk;
    newer.info.reference.generation += 1;
    try t.expect(!unchanged(disk, newer));
    newer = disk;
    newer.info.layout_generation += 1;
    try t.expect(!unchanged(disk, newer));
}

test "five manifest roles bind to actual GPT and BOOT; clones and aliases are ambiguous" {
    const t = std.testing;
    const manifest = try installation.parse(t.allocator, @embedFile("installation.fixture.json"));
    var parts: [5]abi.StoragePartitionInfo = undefined;
    const reference = abi.StorageDeviceRef{ .slot = 1, .generation = 7 };
    for (&parts, manifest.partitions, 0..) |*part, expected, i| {
        part.* = .{ .type_guid = expected.type_guid, .target = .{ .kind = abi.storage_target_partition, .device = reference, .layout_generation = 3, .first_lba = expected.first_lba, .sector_count = expected.sector_count, .partition_number = @intCast(i + 1), .partition_guid = expected.partition_guid } };
    }
    const disk = Disk{ .info = .{ .reference = reference, .layout_generation = 3, .flags = abi.storage_device_gpt | abi.storage_device_table_valid, .disk_guid = manifest.disk_guid }, .partitions = &parts };
    const boot = abi.StorageVolumeInfo{ .target = parts[1].target, .letter = 'D' };
    const bound = bind(disk, boot, manifest) orelse return error.TestUnexpectedResult;
    try t.expect(sameTarget(bound[2], parts[2].target));
    parts[2].target.sector_count -= 1;
    try t.expect(bind(disk, boot, manifest) == null);
    parts[2].target.sector_count += 1;
    parts[3].type_guid[0] ^= 1;
    try t.expect(bind(disk, boot, manifest) == null);
    parts[3].type_guid[0] ^= 1;
    var wrong_boot = boot;
    wrong_boot.target = parts[3].target;
    try t.expect(bind(disk, wrong_boot, manifest) == null);
    var truncated = disk;
    truncated.partitions = parts[0..4];
    try t.expect(bind(truncated, boot, manifest) == null);
    var disks = [_]Disk{ disk, disk };
    disks[1].info.reference.slot = 2;
    flagAmbiguities(&disks, &.{});
    try t.expect(disks[0].ambiguous and disks[1].ambiguous);
    // An installation ID repeated in a separately read BOOT is also rejected,
    // even when its disk and partition GUIDs did not collide.
    const record = Installed{ .disk = 0, .manifest = manifest, .boot = boot, .hash = .{0} ** 32, .parts = bound };
    var records = [_]Installed{ record, record };
    records[1].disk = 1;
    flagAmbiguities(&.{}, &records);
    try t.expect(records[0].ambiguous and records[1].ambiguous);
}
