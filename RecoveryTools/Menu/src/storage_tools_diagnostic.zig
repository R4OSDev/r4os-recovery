//! Bounded acceptance on the designated QEMU scratch disk. The caller also
//! checks the boot fixture GUID before this destructive witness can run.
const std = @import("std");
const r4os = @import("r4os");
const abi = r4os.abi;
const tools = r4os.storage_tools;
const partition = tools.partition;
const scratch_sectors = 128 * 2048;
const scratch_guid = partition.guid.parse("07690009-2222-4333-8444-000000000000").?;

const Harness = struct {
    sys: *const r4os.r4sys.Context,
    storage: r4os.storage.Context,
    fn check(self: Harness, label: []const u8, actual: i32, wanted: i32) !void {
        if (actual == wanted) return;
        var text: [160]u8 = undefined;
        self.sys.write(std.fmt.bufPrint(&text, "[STORAGETOOLS] {s} actual={d} expected={d}\r\n", .{ label, actual, wanted }) catch "Storage tools assertion\r\n");
        return error.Assertion;
    }
    fn inventory(self: Harness) !abi.StorageInventory {
        var result: abi.StorageInventory = .{};
        try self.check("inventory", self.storage.inventory(&result), 0);
        return result;
    }
    fn findDisk(self: Harness, require_blank: bool) !abi.StorageDeviceInfo {
        const inv = try self.inventory();
        for (0..inv.device_slots) |i| {
            var disk: abi.StorageDeviceInfo = .{};
            if (self.storage.device(inv.generation, @intCast(i), &disk) != 1) continue;
            if (disk.bus != abi.storage_bus_nvme or disk.sector_bytes != 512 or disk.sector_count != scratch_sectors) continue;
            if (require_blank and disk.partition_slots != 0) continue;
            if (!require_blank and !std.mem.eql(u8, &disk.disk_guid, &scratch_guid)) continue;
            return disk;
        }
        return error.MissingScratchDisk;
    }
    fn part(self: Harness, number: u32) !abi.StorageTarget {
        const disk = try self.findDisk(false);
        const inv = try self.inventory();
        var result: abi.StoragePartitionInfo = .{};
        try self.check("partition", self.storage.partition(inv.generation, &disk.reference, number - 1, &result), 1);
        return result.target;
    }
};

pub fn run(sys: *const r4os.r4sys.Context) !void {
    const h = Harness{ .sys = sys, .storage = .{ .sys = sys } };
    const allocator = sys.allocator();
    const work = try allocator.alloc(u8, 128 * 1024);
    defer allocator.free(work);
    // Prepare all volume metadata and allocations before changing the disk.
    const fat = try tools.fat32.Plan.prepare(64 * 2048, 2048, "FATWITNESS", 0x7691, 0);
    var builder = try tools.ntfs.Builder.init(allocator, 32 * 1024 * 1024, "NTFSWITNESS", 65 * 2048, tools.standardNtfsMetadata(), 132_000_000_000_000_000, 0x7692);
    defer builder.deinit();
    try builder.addFile(builder.root(), "WITNESS.TXT", "COMMON-NTFS-0769");
    var ntfs = try builder.prepare();
    defer ntfs.deinit();
    var progress = tools.io.Progress{};
    const disk = try h.findDisk(true);
    var whole = r4os.storage_tools_guest.Target{ .storage = h.storage, .target = r4os.storage.Context.wholeDevice(disk) };
    try h.check("whole claim", whole.acquire(), 0);
    defer _ = whole.release(true);
    const device = whole.device(&progress);
    // MBR creation and active/type flags are read through the common parser.
    try partition.clean(device, false, work);
    const plan = try allocator.create(partition.Plan);
    defer allocator.destroy(plan);
    plan.* = try partition.Plan.read(device, work);
    try plan.initializeMbr(0x769);
    _ = try plan.add(.{ .present = true, .first = 2048, .count = 4096, .mbr_type = 7, .active = true });
    try plan.commit(device, work);
    plan.* = try partition.Plan.read(device, work);
    if (plan.kind != .mbr or !plan.entries[0].active) return error.MbrMismatch;
    try partition.clean(device, false, work);
    plan.* = try partition.Plan.read(device, work);
    try plan.initializeGpt(scratch_guid);
    _ = try plan.add(.{ .present = true, .first = 2048, .count = 64 * 2048, .type_guid = partition.basic_type, .unique_guid = partition.guid.parse("07690109-2222-4333-8444-000000000000").?, .name = try partition.asciiName("FATWITNESS") });
    _ = try plan.add(.{ .present = true, .first = 65 * 2048, .count = 32 * 2048, .type_guid = partition.basic_type, .unique_guid = partition.guid.parse("07690209-2222-4333-8444-000000000000").?, .name = try partition.asciiName("NTFSWITNESS") });
    try plan.commit(device, work);
    plan.* = try partition.Plan.read(device, work);
    if (plan.backup_array != scratch_sectors - 33 or plan.entries[1].first != 65 * 2048) return error.GptMismatch;
    try h.check("publish GPT and rescan", whole.release(true), 0);
    sys.write("[STORAGETOOLS] MBR/GPT=OK\r\n");

    var fat_target = r4os.storage_tools_guest.Target{ .storage = h.storage, .target = try h.part(1) };
    try h.check("FAT claim", fat_target.acquire(), 0);
    defer _ = fat_target.release(true);
    progress = .{};
    try fat.execute(fat_target.device(&progress), false, work);
    if (!progress.verified or !progress.flushed) return error.IncompleteFat;
    try h.check("FAT publish", fat_target.release(true), 0);

    var ntfs_target = r4os.storage_tools_guest.Target{ .storage = h.storage, .target = try h.part(2) };
    try h.check("NTFS claim", ntfs_target.acquire(), 0);
    defer _ = ntfs_target.release(true);
    progress = .{};
    try ntfs.execute(ntfs_target.device(&progress), true, work);
    if (!progress.verified or !progress.flushed) return error.IncompleteNtfs;
    try h.check("NTFS publish", ntfs_target.release(true), 0);
    sys.write("[STORAGETOOLS] FAT32 quick/NTFS full=OK\r\n");

    var fat_mount: abi.StorageVolumeRef = .{};
    var ntfs_mount: abi.StorageVolumeRef = .{};
    const fat_part = try h.part(1);
    try h.check("FAT mount", h.storage.mount(&fat_part, 'X', &fat_mount), 0);
    const ntfs_part = try h.part(2);
    try h.check("NTFS mount", h.storage.mount(&ntfs_part, 'Y', &ntfs_mount), 0);
    var text: [64]u8 = undefined;
    try h.check("NTFS existing file", sys.fileRead("Y:\\WITNESS.TXT", &text), 16);
    if (!std.mem.eql(u8, text[0..16], "COMMON-NTFS-0769")) return error.WitnessMismatch;
    for ([_][*:0]const u8{ "X:\\AFTER.TXT", "Y:\\AFTER.TXT" }) |path| {
        try h.check("mounted write", sys.fileWrite(path, "MOUNTED-0769"), 12);
        try h.check("mounted read", sys.fileRead(path, &text), 12);
        if (!std.mem.eql(u8, text[0..12], "MOUNTED-0769")) return error.WitnessMismatch;
    }
    try h.check("FAT unmount flush", h.storage.unmount(&fat_mount), 0);
    try h.check("NTFS unmount flush", h.storage.unmount(&ntfs_mount), 0);
    sys.write("[STORAGETOOLS] mount/read/write/flush=OK\r\n");
}
