// Content import uses the canonical NTFS reader and formatter. Source disk
// geometry never becomes target geometry. The formatter prepares all target
// records, indexes, bitmaps and data extents before its first write.
const std = @import("std");
const r4os = @import("r4os");
const nv = @import("ntfs_volume");
const ntfs = r4os.storage_tools.ntfs_format;
const partition = r4os.storage_tools.partition;
const io = r4os.storage_tools.io;
const Pump = @import("resident.zig").Pump;
pub const Plan = @import("r4os").storage_tools.ntfs.PreparedPlan;
pub const Target = struct {
    builder: r4os.storage_tools.ntfs.Builder,
    plan: Plan,
    pub fn deinit(self: *Target) void {
        self.plan.deinit();
        self.builder.deinit();
    }
};
const Node = struct { path: []const u8, name: []const u8, parent: usize, directory: bool, record: u64, data: []const u8 = &.{} };
const Ram = struct {
    bytes: []const u8,
    fn read(raw: *anyopaque, lba: u64, out: []u8) i32 {
        const self: *Ram = @ptrCast(@alignCast(raw));
        if (lba > self.bytes.len / 512 or out.len > self.bytes.len - lba * 512) return -1;
        @memcpy(out, self.bytes[@intCast(lba * 512)..][0..out.len]);
        return 0;
    }
    fn readNv(raw: *anyopaque, lba: u64, count: u32, out: []u8) bool {
        return @as(u64, count) * 512 == out.len and read(raw, lba, out) == 0;
    }
    fn write(_: *anyopaque, _: u64, _: []const u8) i32 {
        return -1;
    }
    fn flush(_: *anyopaque) i32 {
        return -1;
    }
    fn writeNv(_: *anyopaque, _: u64, _: u32, _: []const u8) bool {
        return false;
    }
    fn flushNv(_: *anyopaque) bool {
        return false;
    }
    fn device(self: *Ram) io.Device {
        return .{ .context = self, .sectors = self.bytes.len / 512, .read_fn = read, .write_fn = write, .flush_fn = flush };
    }
};
pub const Tree = struct {
    nodes: std.ArrayList(Node) = .empty,
    file_bytes: u64 = 0,
    // The prepared image still owns the source; the tree owns independent
    // file content too, including any non-contiguous NTFS stream.
    pub fn get(self: Tree, path: []const u8) ?[]const u8 {
        for (self.nodes.items) |node| if (!node.directory and std.ascii.eqlIgnoreCase(path, node.path)) return node.data;
        return null;
    }
    pub fn read(allocator: std.mem.Allocator, image: []const u8, release: []const u8, pump: Pump) !Tree {
        if (image.len != 2048 * 1024 * 1024) return error.SourceImageSize;
        const ram = try allocator.create(Ram);
        ram.* = .{ .bytes = image };
        const scratch = try allocator.alloc(u8, io.scratch_bytes);
        const table = try allocator.create(partition.Plan);
        table.* = try partition.Plan.read(ram.device(), scratch);
        if (table.kind != .gpt or table.first_usable != 34 or table.last_usable != image.len / 512 - 34) return error.SourceLayout;
        const starts = [_]u64{ 2048, 4096, 266240, 2363392, 3411968 };
        const counts = [_]u64{ 2048, 262144, 2097152, 1048576, image.len / 512 - 33 - starts[4] };
        for (table.entries, 0..) |entry, i| {
            if (i >= 5) {
                if (entry.present) return error.SourceLayout;
                continue;
            }
            const kind = if (i == 0) partition.bios_type else if (i == 1) partition.esp_type else partition.basic_type;
            if (!entry.present or entry.first != starts[i] or entry.count != counts[i] or !partition.guid.eql(entry.type_guid, kind)) return error.SourceLayout;
        }
        const system = table.entries[2];
        ram.bytes = image[@intCast(system.first * 512)..][0..@intCast(system.count * 512)];
        const work = try allocator.create(nv.Scratch);
        work.* = .{};
        const runs = try allocator.alloc(ntfs.Run, nv.MAX_MFT_RUNS);
        const count = try allocator.create(usize);
        const device = nv.Device{ .ctx = ram, .read_sectors = Ram.readNv, .write_sectors = Ram.writeNv, .flush = Ram.flushNv };
        const mounted = nv.mount(device, 0, work, runs) orelse return error.SourceNtfs;
        if ((mounted.total_sectors + 1) * 512 != ram.bytes.len or mounted.cluster_bytes != 4096) return error.SourceNtfs;
        count.* = mounted.mft_run_count;
        var volume = nv.Volume{ .device = device, .partition_lba = 0, .cluster_bytes = mounted.cluster_bytes, .record_bytes = mounted.record_bytes, .index_block_bytes = mounted.index_block_bytes, .total_sectors = mounted.total_sectors, .mft_runs_buf = runs, .mft_run_count = count, .upcase = &.{}, .scratch = work };
        if (nv.isDirty(&volume) orelse true) return error.SourceNtfsDirty;
        const upcase = try allocator.alloc(u8, ntfs.UPCASE_BYTES);
        if ((nv.readFileRange(&volume, ntfs.MFT_RECORD_UPCASE, 0, upcase) orelse return error.SourceNtfs) != upcase.len) return error.SourceNtfs;
        volume.upcase = upcase;
        var tree = Tree{};
        try tree.nodes.append(allocator, .{ .path = "", .name = "", .parent = 0, .directory = true, .record = ntfs.MFT_RECORD_ROOT });
        var dir_index: usize = 0;
        while (dir_index < tree.nodes.items.len) : (dir_index += 1) {
            const directory = tree.nodes.items[dir_index];
            if (!directory.directory) continue;
            var wanted: usize = 0;
            while (true) : (wanted += 1) {
                var sink = nv.EnumSink{ .wanted = wanted };
                if (!nv.enumerateDirectory(&volume, directory.record, &sink)) return error.SourceNtfs;
                const entry = sink.found orelse break;
                if (tree.nodes.items.len >= 4000 or entry.reparse or entry.record < ntfs.MFT_FIRST_NORMAL) return error.SourceTree;
                for (tree.nodes.items) |previous| if (previous.record == entry.record) return error.SourceHardLink;
                const name = try allocator.dupe(u8, entry.name[0..entry.name_len]);
                if (std.mem.indexOfAny(u8, name, "/\\") != null or std.mem.eql(u8, name, ".") or std.mem.eql(u8, name, "..")) return error.SourceTree;
                const path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ directory.path, name });
                if (path.len > 1023 or std.mem.count(u8, path, "/") > 24) return error.SourceTree;
                var node = Node{ .path = path, .name = name, .parent = dir_index, .directory = entry.isDir(), .record = entry.record };
                if (!node.directory) {
                    if (entry.size > ram.bytes.len or tree.file_bytes > ram.bytes.len - entry.size) return error.SourceTree;
                    const data = try allocator.alloc(u8, @intCast(entry.size));
                    var offset: usize = 0;
                    while (offset < data.len) {
                        const amount = @min(data.len - offset, 64 * 1024);
                        if ((nv.readFileRange(&volume, entry.record, offset, data[offset..][0..amount]) orelse return error.SourceNtfs) != amount) return error.SourceNtfs;
                        offset += amount;
                        try pump.run("Reading SYSTEM contents", tree.file_bytes + offset, ram.bytes.len);
                    }
                    node.data = data;
                    tree.file_bytes += data.len;
                }
                try tree.nodes.append(allocator, node);
                try pump.run("Preparing SYSTEM tree", tree.nodes.items.len, 4000);
            }
        }
        const version_file = tree.get("/R4OS/CONFIG/VERSION.R4S") orelse return error.SourceVersion;
        if (!std.mem.eql(u8, r4os.version_info.parseReleaseVersion(version_file) orelse return error.SourceVersion, release)) return error.SourceVersion;
        return tree;
    }
    pub fn prepareTarget(self: Tree, allocator: std.mem.Allocator, first_lba: u64, sectors: u64, serial: u64, pump: Pump) !Target {
        if (first_lba > std.math.maxInt(u32) or sectors > std.math.maxInt(u64) / 512) return error.TargetGeometry;
        var builder = try r4os.storage_tools.ntfs.Builder.init(allocator, sectors * 512, "SYSTEM", @intCast(first_lba), r4os.storage_tools.standardNtfsMetadata(), 0, serial);
        errdefer builder.deinit();
        const ids = try allocator.alloc(u32, self.nodes.items.len);
        defer allocator.free(ids);
        ids[0] = builder.root();
        for (self.nodes.items[1..], 1..) |node, i| {
            const parent = ids[node.parent];
            if (node.directory) ids[i] = try builder.addDirectory(parent, node.name) else try builder.addFile(parent, node.name, node.data);
            try pump.run("Preparing target NTFS metadata", i, self.nodes.items.len);
        }
        const plan = try builder.prepare();
        return .{ .builder = builder, .plan = plan };
    }
};
