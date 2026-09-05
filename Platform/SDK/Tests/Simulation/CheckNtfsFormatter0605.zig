// CheckNtfsFormatter0605: drives the shared NTFS formatter (ntfs_mkfs) to
// build a bare NTFS volume from Windows-authored metadata templates plus a
// deterministic file tree, then writes it out for NtfsVerify and chkdsk.
//
// Usage:
//   zig run --dep ntfs_mkfs --dep ntfs_format -Mroot=CheckNtfsFormatter0605.zig \
//       -Mntfs_mkfs=Code/BuildTools/ImageCreator/src/ntfs_mkfs.zig \
//       -Mntfs_format=Code/System/SDK/r4os/ntfs_format.zig \
//       -- <meta-dir> <output-image>

const std = @import("std");
const mkfs = @import("ntfs_mkfs");

const CLUSTER: usize = 4096;

fn loadTemplate(allocator: std.mem.Allocator, io: anytype, dir: std.Io.Dir, name: []const u8) ![]u8 {
    return dir.readFileAlloc(io, name, allocator, .limited(1 << 20));
}

fn loadTemplateOpt(allocator: std.mem.Allocator, io: anytype, dir: std.Io.Dir, name: []const u8) []u8 {
    return dir.readFileAlloc(io, name, allocator, .limited(1 << 20)) catch &[_]u8{};
}

var pattern_state: u32 = 1;
fn pattern(seed: u32, out: []u8) void {
    var s = seed | 1;
    for (out) |*b| {
        s ^= s << 13;
        s ^= s >> 17;
        s ^= s << 5;
        b.* = @truncate(s);
    }
}

pub fn main(init: std.process.Init) !void {
    // Arena keeps template/tree ownership trivial for this one-shot tool.
    const allocator = init.arena.allocator();
    const io = init.io;
    const cwd = std.Io.Dir.cwd();
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len != 3) {
        std.debug.print("Usage: CheckNtfsFormatter0605 <meta-dir> <output-image>\n", .{});
        std.process.exit(2);
    }

    var meta_dir = try cwd.openDir(io, args[1], .{});
    defer meta_dir.close(io);

    const meta = mkfs.Meta{
        .upcase = try loadTemplate(allocator, io, meta_dir, "upcase.bin"),
        .upcase_info = loadTemplateOpt(allocator, io, meta_dir, "upcase_info.bin"),
        .attrdef = try loadTemplate(allocator, io, meta_dir, "attrdef.bin"),
        .sds_prefix = try loadTemplate(allocator, io, meta_dir, "secure_sds_prefix.bin"),
        .sdh_root = try loadTemplate(allocator, io, meta_dir, "secure_sdh_root.bin"),
        .sii_root = try loadTemplate(allocator, io, meta_dir, "secure_sii_root.bin"),
        .sdh_alloc = try loadTemplate(allocator, io, meta_dir, "secure_SDH_alloc.bin"),
        .sii_alloc = try loadTemplate(allocator, io, meta_dir, "secure_SII_alloc.bin"),
        .sdh_bitmap = try loadTemplate(allocator, io, meta_dir, "secure_SDH_bitmap.bin"),
        .sii_bitmap = try loadTemplate(allocator, io, meta_dir, "secure_SII_bitmap.bin"),
        .objid_o_root = try loadTemplate(allocator, io, meta_dir, "extend_objid_o_root.bin"),
        .quota_o_root = try loadTemplate(allocator, io, meta_dir, "extend_quota_o_root.bin"),
        .quota_q_root = try loadTemplate(allocator, io, meta_dir, "extend_quota_q_root.bin"),
        .reparse_r_root = try loadTemplate(allocator, io, meta_dir, "extend_reparse_r_root.bin"),
        .root_sd = try loadTemplate(allocator, io, meta_dir, "root_sd.bin"),
        .boot_sd = try loadTemplate(allocator, io, meta_dir, "boot_sd.bin"),
    };

    // 24 MB volume, partition-less (bare) at LBA 0.
    const total_bytes: u64 = 24 * 1024 * 1024;
    const timestamp: u64 = 132000000000000000; // arbitrary fixed FILETIME
    var builder = try mkfs.Builder.init(allocator, total_bytes, "R4OSNTFS", 0, meta, timestamp, 0x0011223344556677);
    try buildTree(&builder, allocator);

    const image = try builder.finalize();
    try cwd.writeFile(io, .{ .sub_path = args[2], .data = image });

    // MBR-wrapped variants for chkdsk/VHD attachment: full tree and an
    // empty tree (bisection between system area and user tree).
    try writeDisk(allocator, io, cwd, args[2], ".disk.img", meta, total_bytes, timestamp, true);
    try writeDisk(allocator, io, cwd, args[2], ".empty.disk.img", meta, total_bytes, timestamp, false);

    std.debug.print("FORMATTER result: OK bytes={d}\n", .{image.len});
}

fn writeDisk(allocator: std.mem.Allocator, io: anytype, cwd: std.Io.Dir, base_path: []const u8, suffix: []const u8, meta: mkfs.Meta, total_bytes: u64, timestamp: u64, with_tree: bool) !void {
    var disk_builder = try mkfs.Builder.init(allocator, total_bytes, "R4OSNTFS", 2048, meta, timestamp, 0x0011223344556677);
    if (with_tree) try buildTree(&disk_builder, allocator);
    const volume = try disk_builder.finalize();
    const disk = try allocator.alloc(u8, 2048 * 512 + volume.len);
    @memset(disk[0 .. 2048 * 512], 0);
    std.mem.writeInt(u32, disk[0x1B8..][0..4], 0x52344F53, .little);
    disk[446] = 0x00;
    disk[446 + 4] = 0x07;
    std.mem.writeInt(u32, disk[446 + 8 ..][0..4], 2048, .little);
    std.mem.writeInt(u32, disk[446 + 12 ..][0..4], @intCast(volume.len / 512), .little);
    disk[510] = 0x55;
    disk[511] = 0xAA;
    @memcpy(disk[2048 * 512 ..], volume);
    var path_buf: [512]u8 = undefined;
    const disk_path = try std.fmt.bufPrint(path_buf[0..], "{s}{s}", .{ base_path, suffix });
    try cwd.writeFile(io, .{ .sub_path = disk_path, .data = disk });
}

fn buildTree(builder: *mkfs.Builder, allocator: std.mem.Allocator) !void {
    const root = builder.root();
    const basic = try builder.addDirectory(root, "BASIC");
    try builder.addFile(basic, "HELLO.TXT", "Hello from the R4OS NTFS formatter.");
    try builder.addFile(basic, "EMPTY.DAT", "");
    const small = try allocator.alloc(u8, 400);
    pattern(33, small);
    try builder.addFile(basic, "RESIDENT.DAT", small);
    const sub = try builder.addDirectory(basic, "SUB1");
    const data1 = try allocator.alloc(u8, 4096);
    pattern(11, data1);
    try builder.addFile(sub, "DATA1.BIN", data1);
    const big = try allocator.alloc(u8, 512 * 1024);
    pattern(777, big);
    try builder.addFile(root, "BIG.BIN", big);
    const bigdir = try builder.addDirectory(root, "BIGDIR");
    var name_buf: [64]u8 = undefined;
    var content_buf: [32]u8 = undefined;
    var i: usize = 0;
    while (i < 400) : (i += 1) {
        const name = std.fmt.bufPrint(name_buf[0..], "Entry-{d:0>4}-with-a-reasonably-long-name.txt", .{i}) catch unreachable;
        const content = std.fmt.bufPrint(content_buf[0..], "entry {d}", .{i}) catch unreachable;
        try builder.addFile(bigdir, try allocator.dupe(u8, name), try allocator.dupe(u8, content));
    }
    try builder.addFile(root, "A rather long file name that needs the Win32 namespace only.txt", "long name payload");
}
