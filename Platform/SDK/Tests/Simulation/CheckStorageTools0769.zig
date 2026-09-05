//! One component fixture for partitioning and formatters; guest acceptance
//! exercises these same routines through actual exclusive storage claims.
const std = @import("std");
const tools = @import("storage_tools");
const expect = std.testing.expect;
const eq = std.testing.expectEqual;
const expectError = std.testing.expectError;
const table = tools.partition;
const disk_guid = table.guid.parse("00112233-4455-6677-8899-aabbccddeeff").?;

const BootFixture = struct {
    // Sparse logical disk: GPT metadata and the BIOSBOOT extent only.
    // Any accidental access elsewhere is an error, not a zero-filled pass.
    bytes: [131][512]u8 = .{.{0} ** 512} ** 131,
    sectors: u64 = tools.installation.standard_bytes / 512,
    writes: usize = 0,
    flushes: usize = 0,
    fail_write: ?usize = null,
    fail_flush: ?usize = null,
    corrupt_stage: bool = false,
    fn slot(self: *BootFixture, lba: u64) ?*[512]u8 {
        const index = if (lba < 34) lba else if (lba >= self.sectors - 33 and lba < self.sectors)
            34 + lba - (self.sectors - 33)
        else if (lba >= 2048 and lba < 2112) 67 + lba - 2048 else return null;
        return &self.bytes[@intCast(index)];
    }
    fn device(self: *BootFixture, progress: *tools.io.Progress) tools.io.Device {
        return .{ .context = self, .sectors = self.sectors, .exclusive = true, .read_fn = read, .write_fn = write, .flush_fn = flush, .progress = progress };
    }
    fn read(raw: *anyopaque, lba: u64, out: []u8) i32 {
        const self: *BootFixture = @ptrCast(@alignCast(raw));
        for (0..out.len / 512) |i| @memcpy(out[i * 512 ..][0..512], self.slot(lba + i) orelse return -1);
        if (self.corrupt_stage and self.flushes != 0 and lba == 2048) out[0] ^= 1;
        return 0;
    }
    fn write(raw: *anyopaque, lba: u64, bytes: []const u8) i32 {
        const self: *BootFixture = @ptrCast(@alignCast(raw));
        self.writes += 1;
        if (self.fail_write == self.writes) return -2;
        for (0..bytes.len / 512) |i| @memcpy(self.slot(lba + i) orelse return -1, bytes[i * 512 ..][0..512]);
        return 0;
    }
    fn flush(raw: *anyopaque) i32 {
        const self: *BootFixture = @ptrCast(@alignCast(raw));
        self.flushes += 1;
        return if (self.fail_flush == self.flushes) -3 else 0;
    }
};

test "five-role layout, GUID boot references and Limine GPT publication" {
    const a = std.testing.allocator;
    var entropy: [7][16]u8 = .{.{0} ** 16} ** 7;
    for (&entropy, 0..) |*id, i| id[0] = @intCast(i + 1);
    const ids = try tools.installation.Identifiers.fromEntropy(entropy);
    var work: [tools.io.scratch_bytes]u8 = undefined;
    for ([_]u64{ tools.installation.standard_bytes / 512, 16 * 1024 * 2048 }) |sectors| {
        var fixture = BootFixture{ .sectors = sectors };
        var progress = tools.io.Progress{};
        const device = fixture.device(&progress);
        const layout = try tools.installation.Layout.prepare(sectors, 512, ids);
        try eq(sectors - 1, layout.part(.DATA).first + layout.part(.DATA).count + 32);
        var plan = try table.Plan.read(device, &work);
        try layout.bind(&plan);
        try plan.commit(device, &work);
        const actual = try table.Plan.read(device, &work);
        try eq(sectors - 33, actual.backup_array);
        for (actual.entries, 0..) |entry, i| {
            try eq(i < 5, entry.present);
            if (i < 5) {
                try eq(tools.installation.first_lbas[i], entry.first);
                try expect(table.guid.eql(ids.partitions[i], entry.unique_guid));
            }
        }
        const manifest = try layout.manifest(a, "0.76.17", "0.1.97", &tools.installation.boot_paths);
        defer a.free(manifest);
        const json = try std.json.parseFromSlice(std.json.Value, a, manifest, .{});
        defer json.deinit();
        try eq(@as(usize, 5), json.value.object.get("partitions").?.object.count());
        for ([_]tools.installation.Medium{ .local, .usb }) |medium| {
            const config = try layout.limineConfig(a, medium);
            defer a.free(config);
            try expect(std.mem.indexOf(u8, config, if (medium == .local) "default_entry: 1" else "default_entry: 2") != null);
            try eq(@as(usize, 3), std.mem.count(u8, config, "protocol: limine"));
            try expect(std.mem.indexOf(u8, config, &table.guid.format(ids.partitions[1])) != null);
            try expect(std.mem.indexOf(u8, config, ":/CURRENT/runtime.img") != null);
            try expect(std.mem.indexOf(u8, config, ":/PREVIOUS/runtime.img") != null);
        }
        const before = fixture.bytes;
        fixture.writes = 0;
        fixture.flushes = 0;
        progress = .{};
        try tools.limine.installBios(device, &actual, &work);
        try expect(progress.flushed and progress.verified);
        try std.testing.expectEqualSlices(u8, before[0][218..224], fixture.bytes[0][218..224]);
        try std.testing.expectEqualSlices(u8, before[0][440..510], fixture.bytes[0][440..510]);
        try eq(@as(u64, 2048 * 512), std.mem.readInt(u64, fixture.bytes[0][0x1a4..][0..8], .little));
        try std.testing.expectEqualSlices(u8, std.mem.sliceAsBytes(before[1..67]), std.mem.sliceAsBytes(fixture.bytes[1..67]));
        try std.testing.expectEqualSlices(u8, tools.limine.payload[512..], std.mem.sliceAsBytes(fixture.bytes[67..])[0 .. tools.limine.payload.len - 512]);
        for (0..5) |failure| {
            fixture = .{ .sectors = sectors, .bytes = before };
            progress = .{};
            if (failure < 2) fixture.fail_write = failure + 1 else if (failure < 4) fixture.fail_flush = failure - 1 else fixture.corrupt_stage = true;
            if (tools.limine.installBios(device, &actual, &work)) |_| return error.BootFaultAccepted else |_| {}
            try expect(!progress.verified);
            if (failure == 0 or failure == 2 or failure == 4) try std.testing.expectEqualSlices(u8, &before[0], &fixture.bytes[0]);
        }
    }
    try expectError(error.Geometry, tools.installation.Layout.prepare(4194304, 4096, ids));
    try expectError(error.Geometry, tools.installation.Layout.prepare(tools.installation.first_lbas[4] + 32, 512, ids));
    entropy[1] = entropy[0];
    try expectError(error.DuplicateGuid, tools.installation.Identifiers.fromEntropy(entropy));
}

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

fn fatAllocationCase(allocator: std.mem.Allocator, bytes: []u8) !void {
    _ = try tools.fat32_image.buildInto(allocator, bytes, 4096, 1, "BOOT", 42, &.{
        .{ .path = "boot/long name first.dat", .bytes = "first" },
        .{ .path = "BOOT/long name second.dat", .bytes = "second" },
        .{ .path = "boot/empty.dat", .bytes = "" },
    });
    const view = try tools.fat32_view.View.init(bytes, 4096);
    try view.matches("BOOT/long name first.dat", "first");
    try view.matches("boot/long name second.dat", "second");
    try view.matches("boot/empty.dat", "");
}

test "prepared FAT file trees, long root chains, bounded import and publication faults" {
    const a = std.testing.allocator;
    const bytes = try a.alloc(u8, 64 * 1024 * 1024);
    defer a.free(bytes);
    try std.testing.checkAllAllocationFailures(a, fatAllocationCase, .{bytes});
    var names: [40][64]u8 = undefined;
    var files: [40]tools.fat32_image.File = undefined;
    const content = [_]u8{0x35} ** 6000;
    for (&files, 0..) |*file, i| file.* = .{
        .path = try std.fmt.bufPrint(&names[i], "Root long file number {d}.bin", .{i}),
        .bytes = &content,
    };
    var prepared = try tools.fat32_image.prepare(a, bytes.len / 512, 4096, "BOOT", 71, &files);
    defer prepared.deinit();
    const view = try tools.fat32_view.View.init(prepared.bytes, 4096);
    for (files) |file| try view.matches(file.path, file.bytes);
    const copy = try view.readFile(a, files[39].path, content.len);
    defer a.free(copy);
    try std.testing.expectEqualSlices(u8, &content, copy);
    try expectError(error.SourceFileMissing, view.matches("MISSING", ""));
    try expectError(error.SourceFat, view.readFile(a, files[0].path, 5999));
    try expectError(error.DuplicatePath, tools.fat32_image.buildInto(a, bytes, 4096, 1, "BOOT", 1, &.{
        .{ .path = "boot", .bytes = "" }, .{ .path = "BOOT/file", .bytes = "x" },
    }));
    try expectError(error.Path, tools.fat32_image.buildInto(a, bytes, 4096, 1, "BOOT", 1, &.{.{ .path = "../escape", .bytes = "" }}));
    // File bytes can fit in the partition size while filesystem metadata
    // makes the complete prepared image too large. No device I/O is exposed.
    try expectError(error.ImageFull, tools.fat32_image.buildInto(a, bytes, 4096, 1, "RECOVERY", 1, &.{.{ .path = "INSTALL/RELEASE.ZIP", .bytes = bytes }}));
    var work: [tools.io.scratch_bytes]u8 = undefined;
    for (0..5) |fault| {
        @memset(bytes, 0xa5);
        var fixture = Fixture{ .bytes = bytes };
        var progress = tools.io.Progress{};
        var device = fixture.device(&progress);
        switch (fault) {
            1 => fixture.fail_write = 2,
            2 => fixture.fail_flush = 1,
            3 => fixture.corrupt_after_flush = true,
            4 => device.continue_fn = struct {
                fn proceed(_: ?*anyopaque, _: tools.io.Phase, written: u64) bool {
                    return written < 4;
                }
            }.proceed,
            else => {},
        }
        if (fault == 0) {
            var readonly = device;
            readonly.exclusive = false;
            try expectError(error.ExclusiveRequired, prepared.execute(readonly, false, &work));
            try expect(!progress.write_attempted);
            try prepared.execute(device, false, &work);
            try expect(progress.flushed and progress.verified);
            const observed = try tools.fat32_view.View.init(bytes, 4096);
            for (files) |file| try observed.matches(file.path, file.bytes);
            try eq(@as(u8, 0xa5), bytes[@as(usize, prepared.stats.used_sectors) * 512]);
        } else {
            const errors = [_]anyerror{ error.WriteFailed, error.FlushFailed, error.VerifyFailed, error.Cancelled };
            try expectError(errors[fault - 1], prepared.execute(device, false, &work));
            try expect(progress.write_attempted and !progress.verified);
            try eq(@as(u8, 0), bytes[510]);
        }
    }
    @memcpy(bytes, prepared.bytes);
    bytes[32 * 512 + 8] ^= 1;
    try expectError(error.SourceFat, tools.fat32_view.View.init(bytes, 4096));
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

fn shrinkAllocation(allocator: std.mem.Allocator, disk: tools.io.Device, layout: *table.Plan, work: []u8) !void {
    const plan = try tools.ntfs_resize.Plan.prepare(allocator, disk, layout, 1, 96 * 2048, work);
    plan.deinit();
}

fn fixtureRuns(record: []u8, runs: []const tools.ntfs_format.Run) !void {
    const ntfs = tools.ntfs_format;
    try eq(ntfs.FixupError.ok, ntfs.applyFixups(record));
    const header = ntfs.FileRecordHeader.parse(record).?;
    var iter = ntfs.AttributeIterator.init(record, header);
    while (true) {
        const start = iter.offset;
        const attr = iter.next() orelse return error.Fixture;
        if (attr.attr_type != @intFromEnum(ntfs.AttrType.data) or attr.name.len != 0) continue;
        try expect(attr.non_resident);
        // These formatter fixtures have their unnamed DATA attribute last.
        try eq(ntfs.END_MARKER, std.mem.readInt(u32, record[start + attr.length ..][0..4], .little));
        const at = @intFromPtr(attr.mapping_pairs.ptr) - @intFromPtr(record.ptr);
        var pos = at;
        var previous: i64 = 0;
        var clusters: u64 = 0;
        @memset(record[at..], 0);
        for (runs) |run| {
            const lcn: i64 = @intCast(run.lcn.?);
            pos += ntfs.encodeRun(record[pos..], run.length_clusters, lcn - previous).?;
            previous = lcn;
            clusters += run.length_clusters;
        }
        const end = std.mem.alignForward(usize, pos + 1, 8);
        std.mem.writeInt(u32, record[start + 4 ..][0..4], @intCast(end - start), .little);
        std.mem.writeInt(u32, record[0x18..][0..4], @intCast(end + 8), .little);
        std.mem.writeInt(u64, record[start + 0x18 ..][0..8], clusters - 1, .little);
        std.mem.writeInt(u32, record[end..][0..4], ntfs.END_MARKER, .little);
        const usa = std.mem.readInt(u16, record[4..6], .little);
        const usn = std.mem.readInt(u16, record[usa..][0..2], .little);
        try eq(ntfs.FixupError.ok, ntfs.installFixups(record, usn));
        return;
    }
}
fn fixtureBits(bytes: []u8, bitmap_offset: u64, first: u64, count: u64, set: bool) void {
    for (first..first + count) |cluster| {
        const byte = &bytes[@intCast(bitmap_offset + cluster / 8)];
        const mask = @as(u8, 1) << @intCast(cluster % 8);
        if (set) byte.* |= mask else byte.* &= ~mask;
    }
}

test "NTFS shrink query follows fragmented files and fixed mirror, and every interrupted writer fails" {
    const ntfs = tools.ntfs_format;
    const allocator = std.testing.allocator;
    const bytes = try allocator.alloc(u8, 128 * 1024 * 1024);
    defer allocator.free(bytes);
    @memset(bytes, 0);
    var memory = tools.io.Memory{ .bytes = bytes };
    var work: [32768]u8 = undefined;
    var layout = try table.Plan.read(memory.device(), &work);
    try layout.initializeMbr(0x7612);
    _ = try layout.add(.{ .present = true, .first = 2048, .count = 96 * 2048, .mbr_type = 7 });
    try layout.commit(memory.device(), &work);
    var region = tools.io.Region{ .parent = memory.device(), .first = 2048, .count = 96 * 2048 };
    var builder = try tools.ntfs.Builder.init(allocator, 96 * 1024 * 1024, "SHRINK", 2048, tools.standardNtfsMetadata(), 0, 73);
    defer builder.deinit();
    const witness = try allocator.alloc(u8, 64 * 1024);
    defer allocator.free(witness);
    for (witness, 0..) |*byte, i| byte.* = @truncate(i *% 31 +% 23);
    try builder.addFile(builder.root(), "FRAGMENT.BIN", witness);
    var formatted = try builder.prepare();
    defer formatted.deinit();
    try formatted.execute(try region.device(), false, &work);
    const volume = bytes[1024 * 1024 ..][0 .. 96 * 1024 * 1024];
    var boot: ntfs.BootSector = undefined;
    try eq(ntfs.BootSector.ParseError.ok, ntfs.BootSector.parse(volume, &boot));
    const mft: usize = @intCast(boot.mft_lcn * 4096);
    var old_file_lcn: ?u64 = null;
    for (formatted.segments.items) |segment| {
        if (segment.data.ptr == witness.ptr) old_file_lcn = segment.offset / 4096;
    }
    try expect(old_file_lcn != null);
    @memcpy(volume[16 * 1024 * 1024 ..][0 .. 16 * 1024], witness[0 .. 16 * 1024]);
    @memcpy(volume[80 * 1024 * 1024 ..][0 .. 48 * 1024], witness[16 * 1024 ..]);
    try fixtureRuns(volume[mft + @as(usize, @intCast(builder.nodes.items[1].record)) * 1024 ..][0..1024], &.{ .{ .lcn = 4096, .length_clusters = 4 }, .{ .lcn = 20480, .length_clusters = 12 } });
    fixtureBits(volume, formatted.bitmap_offset, old_file_lcn.?, 16, false);
    fixtureBits(volume, formatted.bitmap_offset, 4096, 4, true);
    fixtureBits(volume, formatted.bitmap_offset, 20480, 12, true);
    layout = try table.Plan.read(memory.device(), &work);
    var readonly = memory.device();
    readonly.exclusive = false;
    const fragmented = try tools.ntfs_resize.Plan.prepare(allocator, readonly, &layout, 1, 96 * 2048, &work);
    try eq(@as(u64, 15 * 2048), fragmented.shrink.maximum_sectors);
    try eq(@as(u64, 81 * 2048), fragmented.shrink.minimum_sectors);
    try eq(@as(u64, 20491), fragmented.shrink.highest_fixed_cluster);
    fragmented.deinit();
    // A real $MFTMirr relocation in the fixture adds a nonmovable metadata
    // bound. Its record and both boots agree; all four mirror records match.
    try fixtureRuns(volume[mft + 1024 ..][0..1024], &.{.{ .lcn = 23040, .length_clusters = 1 }});
    @memcpy(volume[90 * 1024 * 1024 ..][0..4096], volume[mft..][0..4096]);
    fixtureBits(volume, formatted.bitmap_offset, boot.mftmirr_lcn, 1, false);
    fixtureBits(volume, formatted.bitmap_offset, 23040, 1, true);
    std.mem.writeInt(u64, volume[0x38..][0..8], 23040, .little);
    @memcpy(volume[volume.len - 512 ..], volume[0..512]);
    const original = try allocator.dupe(u8, bytes);
    defer allocator.free(original);
    var progress = tools.io.Progress{};
    var fixture = Fixture{ .bytes = bytes };
    const query = try tools.ntfs_resize.Plan.prepare(allocator, fixture.device(&progress), &layout, 1, 96 * 2048, &work);
    try expect(!progress.write_attempted and fixture.writes == 0 and std.mem.eql(u8, bytes, original));
    try eq(@as(u64, 5 * 2048), query.shrink.maximum_sectors);
    try eq(@as(u64, 91 * 2048), query.shrink.minimum_sectors);
    try eq(@as(u64, 23040), query.shrink.highest_fixed_cluster);
    try std.testing.checkAllAllocationFailures(allocator, shrinkAllocation, .{ memory.device(), &layout, &work });
    try expectError(error.Geometry, query.execute(fixture.device(&progress), &layout, &work));
    query.deinit();
    var rejected = layout;
    _ = try rejected.shrink(1, 6 * 2048);
    try expectError(error.ShrinkLimit, tools.ntfs_resize.Plan.prepare(allocator, fixture.device(&progress), &rejected, 1, 96 * 2048, &work));
    try expect(fixture.writes == 0 and !progress.write_attempted);
    _ = try layout.shrink(1, 5 * 2048);
    const plan = try tools.ntfs_resize.Plan.prepare(allocator, memory.device(), &layout, 1, 96 * 2048, &work);
    defer plan.deinit();
    try plan.execute(fixture.device(&progress), &layout, &work);
    const writes = fixture.writes;
    const flushes = fixture.flushes;
    try expect(progress.verified and progress.flushed);
    var after = try table.Plan.read(memory.device(), &work);
    try eq(@as(u64, 91 * 2048), after.entries[0].count);
    try eq(@as(u64, 2048), after.entries[0].first);
    try eq(@as(u32, 0x7612), after.disk_id);
    try eq(ntfs.BootSector.ParseError.ok, ntfs.BootSector.parse(volume, &boot));
    try eq(@as(u64, 91 * 2048 - 1), boot.total_sectors);
    try expect(std.mem.eql(u8, volume[0..512], volume[91 * 1024 * 1024 - 512 ..][0..512]));
    try expect(std.mem.eql(u8, volume[16 * 1024 * 1024 ..][0 .. 16 * 1024], witness[0 .. 16 * 1024]));
    try expect(std.mem.eql(u8, volume[80 * 1024 * 1024 ..][0 .. 48 * 1024], witness[16 * 1024 ..]));
    const again = try tools.ntfs_resize.Plan.prepare(allocator, readonly, &after, 1, 91 * 2048, &work);
    try eq(@as(u64, 0), again.shrink.maximum_sectors);
    again.deinit();
    for (0..writes + flushes) |fault| {
        @memcpy(bytes, original);
        progress = .{};
        fixture = .{ .bytes = bytes };
        if (fault < writes) fixture.fail_write = fault + 1 else fixture.fail_flush = fault - writes + 1;
        try expectError(if (fault < writes) error.WriteFailed else error.FlushFailed, plan.execute(fixture.device(&progress), &layout, &work));
        try expect(progress.write_attempted and !progress.verified);
    }
    @memcpy(bytes, original);
    progress = .{};
    fixture = .{ .bytes = bytes, .corrupt_after_flush = true };
    try expectError(error.VerifyFailed, plan.execute(fixture.device(&progress), &layout, &work));
    try expect(progress.write_attempted and !progress.verified);
    @memcpy(bytes, original);
    progress = .{};
    fixture = .{ .bytes = bytes };
    // A file-record change with unchanged table/bitmap is also stale.
    const file_record = mft + @as(usize, @intCast(builder.nodes.items[1].record)) * 1024;
    volume[file_record + 0x50] ^= 1;
    try expectError(error.Stale, plan.execute(fixture.device(&progress), &layout, &work));
    try expect(!progress.write_attempted and fixture.writes == 0);
    @memcpy(bytes, original);
    var before = try table.Plan.read(memory.device(), &work);
    fixtureBits(volume, formatted.bitmap_offset, 23040, 1, false);
    try expectError(error.CorruptNtfs, tools.ntfs_resize.Plan.prepare(allocator, fixture.device(&progress), &before, 1, 96 * 2048, &work));
    try expect(!progress.write_attempted and fixture.writes == 0);
}

fn refreshGptCrc(sector: []u8) void {
    std.mem.writeInt(u32, sector[16..20], 0, .little);
    std.mem.writeInt(u32, sector[16..20], std.hash.Crc32.hash(sector[0..92]), .little);
}
fn repairAllocations(allocator: std.mem.Allocator, original: []const u8) !void {
    const bytes = try allocator.dupe(u8, original);
    defer allocator.free(bytes);
    bytes[512 + 16] ^= 1;
    var fixture = Fixture{ .bytes = bytes };
    var progress = tools.io.Progress{};
    const device = fixture.device(&progress);
    const report = try tools.gpt_repair.Report.read(allocator, device);
    defer report.deinit();
    var work: [32768]u8 = undefined;
    try report.repair(device, &work);
}

test "GPT repair preserves the unique survivor and refuses ambiguity, stale and partial I/O" {
    const allocator = std.testing.allocator;
    const bytes = try allocator.alloc(u8, 16 * 1024 * 1024);
    defer allocator.free(bytes);
    @memset(bytes, 0);
    var fixture = Fixture{ .bytes = bytes };
    var progress = tools.io.Progress{};
    const device = fixture.device(&progress);
    var work: [32768]u8 = undefined;
    var layout = try newPlan(device, &work);
    layout.mbr_prefix[42] = 0x76;
    try layout.commit(device, &work);
    @memset(bytes[2048 * 512 ..][0..4096], 0x13);
    const original = try allocator.dupe(u8, bytes);
    defer allocator.free(original);
    {
        const report = try tools.gpt_repair.Report.read(allocator, device);
        defer report.deinit();
        try eq(tools.gpt_repair.Status.healthy, report.status);
        progress = .{};
        try expectError(error.GptAlreadyHealthy, report.repair(device, &work));
        try expect(!progress.write_attempted);
    }
    for (0..4) |fault| {
        @memcpy(bytes, original);
        const bad: usize = fault / 2;
        const lba: usize = if (bad == 0) 1 else bytes.len / 512 - 1;
        const array: usize = if (bad == 0) 2 else bytes.len / 512 - 33;
        if (fault % 2 == 0) bytes[lba * 512 + 16] ^= 1 else bytes[array * 512 + 56] ^= 1;
        const damaged = try allocator.dupe(u8, bytes);
        defer allocator.free(damaged);
        fixture = .{ .bytes = bytes };
        progress = .{};
        const report = try tools.gpt_repair.Report.read(allocator, device);
        defer report.deinit();
        try eq(if (bad == 0) tools.gpt_repair.Status.primary_damaged else .backup_damaged, report.status);
        try expect(std.mem.eql(u8, bytes, damaged));
        var readonly = device;
        readonly.exclusive = false;
        try expectError(error.ExclusiveRequired, report.repair(readonly, &work));
        try expect(!progress.write_attempted);
        try report.repair(device, &work);
        try expect(progress.verified and progress.flushed);
        try expect(std.mem.eql(u8, original, bytes));
        _ = try table.Plan.read(device, &work);
        for (0..2) |kind| for (1..3) |point| {
            @memcpy(bytes, damaged);
            fixture = .{ .bytes = bytes };
            progress = .{};
            if (kind == 0) fixture.fail_write = point else fixture.fail_flush = point;
            if (kind == 0) try expectError(error.WriteFailed, report.repair(device, &work)) else try expectError(error.FlushFailed, report.repair(device, &work));
            try expect(progress.write_attempted and !progress.verified);
            // Only the bad copy's header/array may have changed.
            try expect(std.mem.eql(u8, bytes[0..512], original[0..512]));
            const survivor: usize = if (bad == 0) bytes.len - 33 * 512 else 512;
            try expect(std.mem.eql(u8, bytes[survivor..][0 .. 33 * 512], original[survivor..][0 .. 33 * 512]));
            try expect(std.mem.eql(u8, bytes[34 * 512 .. bytes.len - 33 * 512], original[34 * 512 .. bytes.len - 33 * 512]));
        };
        @memcpy(bytes, damaged);
        fixture = .{ .bytes = bytes };
        progress = .{};
        bytes[42] ^= 1;
        try expectError(error.Stale, report.repair(device, &work));
        try expect(!progress.write_attempted);
        @memcpy(bytes, damaged);
        fixture = .{ .bytes = bytes, .corrupt_after_flush = true };
        progress = .{};
        try expectError(error.VerifyFailed, report.repair(device, &work));
        try expect(!progress.verified);
    }
    // Two valid CRCs never grant permission to choose between different IDs,
    // boundaries or arrays, even if one array is independently corrupt.
    for (0..6) |kind| {
        @memcpy(bytes, original);
        fixture = .{ .bytes = bytes };
        progress = .{};
        const primary = bytes[512..1024];
        const backup = bytes[bytes.len - 512 ..];
        switch (kind) {
            0 => {
                primary[16] ^= 1;
                backup[16] ^= 1;
            },
            1 => {
                backup[56] ^= 1;
                refreshGptCrc(backup);
            },
            2 => {
                bytes[bytes.len - 33 * 512 + 56] ^= 1;
                std.mem.writeInt(u32, backup[88..92], std.hash.Crc32.hash(bytes[bytes.len - 33 * 512 ..][0..16384]), .little);
                refreshGptCrc(backup);
            },
            3 => {
                backup[56] ^= 1;
                refreshGptCrc(backup);
                bytes[bytes.len - 33 * 512 + 56] ^= 1;
            },
            4 => bytes[466] = 7, // hybrid protective MBR
            5 => {
                primary[56] ^= 1;
                refreshGptCrc(primary);
            },
            else => unreachable,
        }
        const report = try tools.gpt_repair.Report.read(allocator, device);
        defer report.deinit();
        try eq(if (kind == 0) tools.gpt_repair.Status.both_invalid else if (kind == 4) tools.gpt_repair.Status.protective_mbr_invalid else tools.gpt_repair.Status.conflict, report.status);
        if (kind == 0) try expectError(error.GptBothInvalid, report.repair(device, &work)) else if (kind == 4) try expectError(error.ProtectiveMbr, report.repair(device, &work)) else try expectError(error.GptCopiesDisagree, report.repair(device, &work));
        try expect(!progress.write_attempted);
    }
    @memcpy(bytes, original);
    try std.testing.checkAllAllocationFailures(allocator, repairAllocations, .{bytes});
    try expect(std.mem.eql(u8, original, bytes));
}
