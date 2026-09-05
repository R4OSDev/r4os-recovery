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
