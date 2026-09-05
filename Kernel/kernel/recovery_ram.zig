// Recovery's early boot volume must exist before an R4D loader is available.
// The retained Limine module backs the regular block/cache/FAT32/VFS path.
const std = @import("std");
const config = @import("config");
const boot_info = @import("../bootloader/boot_info.zig");
const limine = @import("../bootloader/limine.zig");
const block = @import("../storage/block.zig");
const fat32 = @import("../fs/fat/fat32.zig");
const drive = @import("../fs/drive.zig");
const vfs = @import("../fs/vfs.zig");
const log = @import("log.zig");

var backing: []u8 = &.{};
var device_index: ?usize = null;

pub fn mount() bool {
    if (device_index != null or drive.get('C') != null) return fail("already-mounted");
    const response = limine.modules() orelse return fail("missing-module");
    if (response.module_count != boot_info.bootModules().len) return fail("incomplete-module-list");
    var selected: ?boot_info.BootModule = null;
    for (boot_info.bootModules()) |module| {
        if (!std.mem.eql(u8, module.cmdline, "recovery.runtime=1")) continue;
        if (selected != null) return fail("duplicate-module");
        selected = module;
    }
    const module = selected orelse return fail("missing-module");
    if (!module.valid or module.size != config.runtime_bytes or module.size % 512 != 0 or module.size < 512) return fail("size-mismatch");
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(module.address[0..module.size], &digest, .{});
    const expected = comptime expectedDigest();
    if (!std.mem.eql(u8, &digest, &expected)) return fail("hash-mismatch");
    log.puts("[RECOVERYRAM] image=VERIFIED bytes=");
    log.putDec(module.size);
    log.puts("\r\n");
    backing = @constCast(module.address[0..module.size]);
    const index = block.register(.{
        .name = "Recovery RAM", .driver = "RAMBOOT", .bus = .ram, .controller = "Recovery RAM",
        .sector_size = 512, .sector_count = module.size / 512,
        .max_sectors_per_request = 128, .queue_depth = 1, .writable = true,
        .ctx = null, .read_fn = read, .write_fn = write, .flush_fn = flush,
    }) orelse return fail("block-registration");
    const volume = fat32.parse(index, 0) orelse return fail("fat32-invalid");
    if (@as(u64, volume.total_sectors) * 512 != module.size or volume.partition_lba != 0 or
        volume.totalClusters() < 65525 or volume.root_cluster < 2 or volume.root_cluster >= volume.totalClusters() + 2)
        return fail("fat32-geometry");
    if (!drive.mountBlockRole('C', .fat32, .ram, "Recovery runtime", module.size, index)) return fail("drive-mount");
    vfs.mountForDrive('C', .{ .fat32 = volume });
    if (!drive.setCurrent('C')) return fail("current-drive");
    device_index = index;
    log.puts("[RECOVERYRAM] C:=READY filesystem=FAT32 backing=RAM persistent=0\r\n");
    return true;
}

fn expectedDigest() [32]u8 {
    var bytes: [32]u8 = undefined;
    _ = std.fmt.hexToBytes(&bytes, config.runtime_sha256) catch @compileError("Invalid runtime SHA-256 build contract");
    return bytes;
}

fn range(lba: u64, sectors: u16, length: usize) ?[]u8 {
    if (sectors == 0 or length != @as(usize, sectors) * 512) return null;
    const start = std.math.mul(u64, lba, 512) catch return null;
    if (start > backing.len or length > backing.len - start) return null;
    return backing[@intCast(start)..][0..length];
}

fn read(_: ?*anyopaque, lba: u64, sectors: u16, output: []u8) bool {
    const source = range(lba, sectors, output.len) orelse return false;
    @memcpy(output, source);
    return true;
}

fn write(_: ?*anyopaque, lba: u64, sectors: u16, input: []const u8) bool {
    const target = range(lba, sectors, input.len) orelse return false;
    @memcpy(target, input);
    return true;
}

fn flush(_: ?*anyopaque) bool {
    // The synchronous block lane completed every memcpy before this barrier.
    return true;
}

fn fail(reason: []const u8) bool {
    log.puts("[RECOVERYRAM] result=REJECT reason=");
    log.puts(reason);
    log.puts("\r\n");
    return false;
}
