//! One component fixture for partitioning and formatters; guest acceptance
//! exercises these same routines through actual exclusive storage claims.
const std = @import("std");
const tools = @import("storage_tools");
const expect = std.testing.expect;
const eq = std.testing.expectEqual;
const expectError = std.testing.expectError;
const table = tools.partition;
const disk_guid = table.guid.parse("00112233-4455-6677-8899-aabbccddeeff").?;

const Fixture = struct {
    bytes: []u8,
    writes: usize = 0,
    reads: usize = 0,
    flushes: usize = 0,
    fail_write: ?usize = null,
    fail_flush: ?usize = null,
    corrupt_after_flush: bool = false,
    change_at_read: ?usize = null,

    fn device(self: *Fixture, progress: *tools.io.Progress) tools.io.Device {
        return .{ .context = self, .sectors = self.bytes.len / 512, .exclusive = true, .read_fn = read, .write_fn = write, .flush_fn = flush, .progress = progress };
    }
    fn read(raw: *anyopaque, lba: u64, out: []u8) i32 {
        const self: *Fixture = @ptrCast(@alignCast(raw));
        self.reads += 1;
        if (self.change_at_read == self.reads) self.bytes[20] ^= 1;
        @memcpy(out, self.bytes[@intCast(lba * 512)..][0..out.len]);
        if (self.corrupt_after_flush and self.flushes != 0) out[0] ^= 1;
        return 0;
    }
    fn write(raw: *anyopaque, lba: u64, bytes: []const u8) i32 {
        const self: *Fixture = @ptrCast(@alignCast(raw));
        self.writes += 1;
        if (self.fail_write == self.writes) {
            // A backend may change a prefix before returning an error.
            self.bytes[@intCast(lba * 512)] = bytes[0];
            return -91;
        }
        @memcpy(self.bytes[@intCast(lba * 512)..][0..bytes.len], bytes);
        return 0;
    }
    fn flush(raw: *anyopaque) i32 {
        const self: *Fixture = @ptrCast(@alignCast(raw));
        self.flushes += 1;
        return if (self.fail_flush == self.flushes) -92 else 0;
    }
};

fn newPlan(device: tools.io.Device, work: []u8) !table.Plan {
    var plan = try table.Plan.read(device, work);
    try plan.initializeGpt(disk_guid);
    _ = try plan.add(.{ .present = true, .first = 2048, .count = 4096, .type_guid = table.basic_type, .unique_guid = table.guid.parse("10112233-4455-6677-8899-aabbccddeeff").?, .attributes = 4, .name = try table.asciiName("SYSTEM") });
    return plan;
}

test "GPT/MBR roundtrip, geometry, free space, attributes and stale plans" {
    const bytes = try std.testing.allocator.alloc(u8, 16 * 1024 * 1024);
    defer std.testing.allocator.free(bytes);
    @memset(bytes, 0);
    var fixture = Fixture{ .bytes = bytes };
    var progress = tools.io.Progress{};
    const device = fixture.device(&progress);
    var work: [32768]u8 = undefined;
    var plan = try newPlan(device, &work);
    var second = plan.entries[0];
    second.first = try plan.firstFit(4096);
    second.unique_guid[0] = 42;
    try eq(@as(u32, 2), try plan.add(second));
    try expectError(error.Overlap, plan.add(plan.entries[0]));
    second.first += 1;
    try expectError(error.Alignment, plan.add(second));
    try expectError(error.NotEmpty, plan.initializeMbr(42));
    try expect(!progress.write_attempted);
    var readonly = device;
    readonly.exclusive = false;
    try expectError(error.ExclusiveRequired, plan.commit(readonly, &work));
    var wrong_sector = device;
    wrong_sector.sector_bytes = 4096;
    try expectError(error.Geometry, plan.commit(wrong_sector, &work));
    try expect(!progress.write_attempted);
    try plan.commit(device, &work);
    try expect(progress.flushed and progress.verified);
    var reread = try table.Plan.read(device, &work);
    try eq(@as(u64, 6144), reread.entries[1].first);
    try eq(@as(u64, 4), reread.entries[0].attributes);
    try eq(device.sectors - 33, reread.backup_array);
    try eq(device.sectors - 34, reread.last_usable);
    try reread.remove(1);
    try reread.commit(device, &work);
    const stale = try table.Plan.read(device, &work);
    try expect(!stale.entries[0].present and stale.entries[1].present);
    bytes[20] = 1;
    progress = .{};
    try expectError(error.Stale, stale.commit(device, &work));
    try expect(!progress.write_attempted);
    try table.clean(device, false, &work);
    var mbr = try table.Plan.read(device, &work);
    try mbr.initializeMbr(42);
    _ = try mbr.add(.{ .present = true, .first = 2048, .count = 4096, .mbr_type = 7, .active = true });
    try mbr.commit(device, &work);
    const after = try table.Plan.read(device, &work);
    try eq(table.Kind.mbr, after.kind);
    try eq(@as(u32, 42), after.disk_id);
    try expect(after.entries[0].active);
    bytes[450] = 0x0f;
    try expectError(error.ExtendedMbrUnsupported, table.Plan.read(device, &work));
    bytes[450] = 7;
    var empty = try table.Plan.read(device, &work);
    try expectError(error.NotEmpty, empty.convertEmpty(.gpt, disk_guid, 42));
    try empty.remove(1);
    try empty.commit(device, &work);
    empty = try table.Plan.read(device, &work);
    try empty.convertEmpty(.gpt, disk_guid, 42);
    try empty.commit(device, &work);
    empty = try table.Plan.read(device, &work);
    try empty.convertEmpty(.mbr, disk_guid, 77);
    try empty.commit(device, &work);
    const converted = try table.Plan.read(device, &work);
    try eq(table.Kind.mbr, converted.kind);
    try eq(@as(u32, 77), converted.disk_id);
    for (bytes[512 .. 34 * 512]) |byte| try eq(@as(u8, 0), byte);
    for (bytes[bytes.len - 33 * 512 ..]) |byte| try eq(@as(u8, 0), byte);
}

test "failed write, flush, verification and cancelled commit retain exact partial status" {
    const bytes = try std.testing.allocator.alloc(u8, 4 * 1024 * 1024);
    defer std.testing.allocator.free(bytes);
    var work: [32768]u8 = undefined;
    for (0..4) |fault| {
        @memset(bytes, 0);
        var fixture = Fixture{ .bytes = bytes };
        var progress = tools.io.Progress{};
        var device = fixture.device(&progress);
        const plan = try newPlan(device, &work);
        switch (fault) {
            0 => fixture.fail_write = 2,
            1 => fixture.fail_flush = 1,
            2 => fixture.corrupt_after_flush = true,
            3 => device.continue_fn = struct {
                fn proceed(_: ?*anyopaque, _: tools.io.Phase, written: u64) bool {
                    return written == 0;
                }
            }.proceed,
            else => unreachable,
        }
        const errors = [_]anyerror{ error.WriteFailed, error.FlushFailed, error.VerifyFailed, error.Cancelled };
        try expectError(errors[fault], plan.commit(device, &work));
        try expect(progress.write_attempted and !progress.verified);
        try eq(errors[fault], progress.failure.?);
        try eq(@as(u8, 0), bytes[510]); // Never publish a protective MBR on failure.
        if (fault == 0) {
            try eq(@as(usize, 2), fixture.writes);
            try eq(@as(i32, -91), progress.native_error);
            try eq(device.sectors - 1, progress.failed_lba.?);
        }
        if (fault == 1) try expect(!progress.flushed);
        if (fault == 2) try expect(progress.flushed);
    }
    @memset(bytes, 0);
    var racing = Fixture{ .bytes = bytes, .change_at_read = 4 };
    var progress = tools.io.Progress{};
    try expectError(error.Stale, table.Plan.read(racing.device(&progress), &work));
    try expect(!progress.write_attempted);
}

test "FAT32 quick/full, copies, label and capacity preflight" {
    const bytes = try std.testing.allocator.alloc(u8, 64 * 1024 * 1024);
    defer std.testing.allocator.free(bytes);
    @memset(bytes, 0xa5);
    var memory = tools.io.Memory{ .bytes = bytes };
    var progress = tools.io.Progress{};
    var device = memory.device();
    device.progress = &progress;
    var work: [32768]u8 = undefined;
    const plan = try tools.fat32.Plan.prepare(device.sectors, 2048, "DATA", 42, 0);
    try plan.execute(device, false, &work);
    try std.testing.expectEqualSlices(u8, bytes[0..512], bytes[6 * 512 .. 7 * 512]);
    try std.testing.expectEqualStrings("DATA       ", bytes[71..82]);
    try eq(@as(u8, 0xa5), bytes[bytes.len / 2]);
    try expect(progress.flushed and progress.verified);
    try plan.execute(device, true, &work);
    try eq(@as(u8, 0), bytes[bytes.len / 2]);
    try expectError(error.VolumeTooSmall, tools.fat32.Plan.prepare(16 * 2048, 0, "TEST", 1, 0));
    try expectError(error.Label, tools.fat32.Plan.prepare(device.sectors, 0, "BAD:LABEL", 1, 0));
    try expectError(error.Geometry, tools.fat32.Plan.prepare(device.sectors, 0, "TEST", 1, 3));
}

// Only the metadata prefix and final boot sector are materialised; every
// unexpected write outside those regions fails. Volume size is 128 GiB.
const Sparse = struct {
    prefix: []u8,
    last: [512]u8 = .{0xa5} ** 512,
    const sectors = 128 * 1024 * 1024 * 1024 / 512;
    fn device(self: *Sparse) tools.io.Device {
        return .{ .context = self, .sectors = sectors, .exclusive = true, .read_fn = read, .write_fn = write, .flush_fn = flush };
    }
    fn read(raw: *anyopaque, lba: u64, bytes: []u8) i32 {
        const self: *Sparse = @ptrCast(@alignCast(raw));
        if (lba == sectors - 1 and bytes.len == 512) {
            @memcpy(bytes, &self.last);
            return 0;
        }
        if (lba * 512 + bytes.len > self.prefix.len) return -1;
        @memcpy(bytes, self.prefix[@intCast(lba * 512)..][0..bytes.len]);
        return 0;
    }
    fn write(raw: *anyopaque, lba: u64, bytes: []const u8) i32 {
        const self: *Sparse = @ptrCast(@alignCast(raw));
        if (lba == sectors - 1 and bytes.len == 512) {
            @memcpy(&self.last, bytes);
            return 0;
        }
        if (lba * 512 + bytes.len > self.prefix.len) return -1;
        @memcpy(self.prefix[@intCast(lba * 512)..][0..bytes.len], bytes);
        return 0;
    }
    fn flush(_: *anyopaque) i32 {
        return 0;
    }
};

test "128 GiB NTFS uses a 2 MiB allocator, validates MFT and streams bitmap" {
    const heap = try std.testing.allocator.alloc(u8, 2 * 1024 * 1024);
    defer std.testing.allocator.free(heap);
    const prefix = try std.testing.allocator.alloc(u8, 16 * 1024 * 1024);
    defer std.testing.allocator.free(prefix);
    @memset(prefix, 0xa5);
    var fixed = std.heap.FixedBufferAllocator.init(heap);
    var builder = try tools.ntfs.Builder.init(fixed.allocator(), Sparse.sectors * 512, "DATA", 2048, tools.standardNtfsMetadata(), 132_000_000_000_000_000, 42);
    defer builder.deinit();
    try builder.addFile(builder.root(), "WITNESS.TXT", "STREAMED-NTFS");
    var plan = try builder.prepare();
    defer plan.deinit();
    var sparse = Sparse{ .prefix = prefix };
    const work = try fixed.allocator().alloc(u8, 128 * 1024);
    try plan.execute(sparse.device(), false, work);
    try expect(fixed.end_index < heap.len);
    try std.testing.expectEqualSlices(u8, prefix[0..512], &sparse.last);
    var boot: tools.ntfs_format.BootSector = undefined;
    try eq(.ok, tools.ntfs_format.BootSector.parse(prefix[0..512], &boot));
    try eq(Sparse.sectors - 1, boot.total_sectors);
    var record: [1024]u8 = undefined;
    try sparse.device().read(boot.mft_lcn * 8, &record);
    try eq(.ok, tools.ntfs_format.applyFixups(&record));
    const header = tools.ntfs_format.FileRecordHeader.parse(&record).?;
    try expect(header.inUse() and header.record_number == 0);
    try expect(tools.ntfs_format.findAttribute(&record, header, .data, "") != null);
    try expect(plan.bitmap_bytes > 2 * 1024 * 1024); // Larger than all formatter RAM.
    try expectError(error.AlreadyPrepared, builder.prepare());
}

fn allocationFixture(allocator: std.mem.Allocator) !void {
    var builder = try tools.ntfs.Builder.init(allocator, 32 * 1024 * 1024, "TEST", 0, tools.standardNtfsMetadata(), 0, 1);
    defer builder.deinit();
    const dir = try builder.addDirectory(builder.root(), "SUB");
    try expectError(error.NameInvalid, builder.addFile(builder.root(), "$mFt", "bad"));
    try expectError(error.NameInvalid, builder.addDirectory(dir, ".."));
    try builder.addFile(dir, "FILE.TXT", "contents");
    try expectError(error.NameInvalid, builder.addFile(dir, "file.txt", "duplicate"));
    var plan = try builder.prepare();
    defer plan.deinit();
}

test "NTFS preparation releases resources on every allocation failure" {
    try std.testing.checkAllAllocationFailures(std.testing.allocator, allocationFixture, .{});
}

fn extendAllocation(allocator: std.mem.Allocator, disk: tools.io.Device, layout: *table.Plan, work: []u8) !void {
    const plan = try tools.ntfs_extend.Plan.prepare(allocator, disk, layout, 1, 128 * 2048, work);
    plan.deinit();
}

test "offline NTFS growth relocates bitmap, preserves data and exposes interrupted metadata/table phases" {
    const allocator = std.testing.allocator;
    const bytes = try allocator.alloc(u8, 200 * 1024 * 1024);
    defer allocator.free(bytes);
    @memset(bytes, 0);
    var memory = tools.io.Memory{ .bytes = bytes };
    var work: [32768]u8 = undefined;
    var layout = try table.Plan.read(memory.device(), &work);
    try layout.initializeGpt(disk_guid);
    _ = try layout.add(.{ .present = true, .first = 2048, .count = 128 * 2048, .type_guid = table.basic_type, .unique_guid = table.guid.parse("20112233-4455-6677-8899-aabbccddeeff").? });
    try layout.commit(memory.device(), &work);
    var region = tools.io.Region{ .parent = memory.device(), .first = 2048, .count = 128 * 2048 };
    var builder = try tools.ntfs.Builder.init(allocator, 128 * 1024 * 1024, "EXTEND", 2048, tools.standardNtfsMetadata(), 0, 42);
    defer builder.deinit();
    const witness = try allocator.alloc(u8, 64 * 1024);
    defer allocator.free(witness);
    for (witness, 0..) |*byte, i| byte.* = @truncate(i *% 17 +% 39);
    try builder.addFile(builder.root(), "WITNESS.BIN", witness);
    // Several index nodes exercise duplicated $Bitmap sizes outside the root.
    var names: [96][32]u8 = undefined;
    for (0..96) |i| try builder.addFile(builder.root(), try std.fmt.bufPrint(&names[i], "FILE{d:0>3}.TXT", .{i}), "unchanged content");
    var formatted = try builder.prepare();
    defer formatted.deinit();
    try formatted.execute(try region.device(), false, &work);
    const original = try allocator.dupe(u8, bytes);
    defer allocator.free(original);
    layout = try table.Plan.read(memory.device(), &work);
    try expectError(error.NoSpace, layout.extend(1, 100 * 2048));
    try eq(@as(u64, 192 * 2048), try layout.extend(1, 64 * 2048));
    try std.testing.checkAllAllocationFailures(allocator, extendAllocation, .{ memory.device(), &layout, &work });
    const plan = try tools.ntfs_extend.Plan.prepare(allocator, memory.device(), &layout, 1, 128 * 2048, &work);
    defer plan.deinit();
    try eq(@as(u64, 2), plan.bitmap_clusters);
    var progress = tools.io.Progress{};
    var fixture = Fixture{ .bytes = bytes };
    try plan.execute(fixture.device(&progress), &layout, &work);
    const writes = fixture.writes;
    const flushes = fixture.flushes;
    try expect(progress.verified and progress.flushed);
    const after = try table.Plan.read(memory.device(), &work);
    try eq(@as(u64, 2048), after.entries[0].first);
    try eq(@as(u64, 192 * 2048), after.entries[0].count);
    try expect(std.mem.eql(u8, &after.entries[0].unique_guid, &layout.entries[0].unique_guid));
    var found_witness = false;
    for (formatted.segments.items) |segment| {
        if (segment.data.ptr == witness.ptr) {
            try expect(std.mem.eql(u8, witness, bytes[1024 * 1024 + @as(usize, @intCast(segment.offset)) ..][0..witness.len]));
            found_witness = true;
        }
    }
    try expect(found_witness);
    var boot: tools.ntfs_format.BootSector = undefined;
    try eq(tools.ntfs_format.BootSector.ParseError.ok, tools.ntfs_format.BootSector.parse(bytes[1024 * 1024 ..][0..512], &boot));
    try eq(@as(u64, 192 * 2048 - 1), boot.total_sectors);
    try expect(std.mem.eql(u8, bytes[1024 * 1024 ..][0..512], bytes[(1 + 192) * 1024 * 1024 - 512 ..][0..512]));
    // A second preflight reads the metadata just written: dirty flag, mirror,
    // bitmap, sparse $Bad and index duplicates must all agree again.
    var second = try table.Plan.read(memory.device(), &work);
    _ = try second.extend(1, 4 * 2048);
    const next = try tools.ntfs_extend.Plan.prepare(allocator, memory.device(), &second, 1, 192 * 2048, &work);
    next.deinit();
    // Inject failure at every metadata/table write and persistence barrier.
    for (0..writes + flushes) |fault| {
        @memcpy(bytes, original);
        progress = .{};
        fixture = .{ .bytes = bytes };
        if (fault < writes) fixture.fail_write = fault + 1 else fixture.fail_flush = fault - writes + 1;
        try expectError(if (fault < writes) error.WriteFailed else error.FlushFailed, plan.execute(fixture.device(&progress), &layout, &work));
        try expect(progress.write_attempted and !progress.verified);
        try expect(progress.failed_lba != null or progress.failure.? == error.FlushFailed);
    }
    @memcpy(bytes, original);
    fixture = .{ .bytes = bytes, .corrupt_after_flush = true };
    progress = .{};
    try expectError(error.VerifyFailed, plan.execute(fixture.device(&progress), &layout, &work));
    try expect(progress.write_attempted and !progress.verified);
    @memcpy(bytes, original);
    bytes[1024 * 1024 + 20] ^= 1;
    fixture = .{ .bytes = bytes };
    progress = .{};
    try expectError(error.Stale, plan.execute(fixture.device(&progress), &layout, &work));
    try expect(!progress.write_attempted and fixture.writes == 0);
    @memcpy(bytes, original);
    var readonly = memory.device();
    readonly.exclusive = false;
    try expectError(error.ExclusiveRequired, plan.execute(readonly, &layout, &work));
    try expect(@sizeOf(tools.ntfs_extend.Plan) < 48 * 1024);
    progress = .{};
    var cancelled = memory.device();
    cancelled.progress = &progress;
    cancelled.continue_fn = struct {
        fn proceed(_: ?*anyopaque, _: tools.io.Phase, _: u64) bool {
            return false;
        }
    }.proceed;
    try expectError(error.Cancelled, plan.execute(cancelled, &layout, &work));
    try expect(!progress.write_attempted);
    // Unsupported cluster geometry is rejected with untouched tables/metadata.
    bytes[1024 * 1024 + 13] = 16;
    bytes[(1 + 128) * 1024 * 1024 - 512 + 13] = 16;
    fixture = .{ .bytes = bytes };
    progress = .{};
    try expectError(error.UnsupportedNtfs, tools.ntfs_extend.Plan.prepare(allocator, fixture.device(&progress), &layout, 1, 128 * 2048, &work));
    try expect(!progress.write_attempted and fixture.writes == 0);
}
