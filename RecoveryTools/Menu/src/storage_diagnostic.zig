// Explicit automated fixture witness. It uses only the public SDK facade and
// refuses all destructive paths unless the technical QEMU fixture GUID matches.
const std = @import("std");
const r4os = @import("r4os");
const abi = r4os.abi;
const ready_path = "C:\\TEMP\\STORAGE.RDY";
const release_path = "C:\\TEMP\\STORAGE.REL";
const saved_boot_path = "C:\\TEMP\\STOBOOT.BIN";
const fixture_guid = [_]u8{ 1, 0, 0, 0, 0x22, 0x22, 0x33, 0x43, 0x84, 0x44, 0, 0, 0, 0, 0, 0 };
const Error = error{ Failed, MissingFixture };

const Harness = struct {
    sys: *const r4os.r4sys.Context,
    storage: r4os.storage.Context,
    fn check(self: Harness, label: []const u8, actual: i32, wanted: i32) Error!void {
        if (actual == wanted) return;
        var buf: [160]u8 = undefined;
        self.sys.write(std.fmt.bufPrint(&buf, "[STORAGE] FAIL {s} actual={d} expected={d}\r\n", .{ label, actual, wanted }) catch "STORAGE assertion failed\r\n");
        return error.Failed;
    }
    fn expect(self: Harness, label: []const u8, value: bool) Error!void {
        try self.check(label, if (value) 1 else 0, 1);
    }
    fn inventory(self: Harness) Error!abi.StorageInventory {
        var out: abi.StorageInventory = .{};
        try self.check("inventory", self.storage.inventory(&out), 0);
        return out;
    }
    fn fixtureTarget(self: Harness) Error!abi.StorageTarget {
        const inv = try self.inventory();
        for (0..inv.device_slots) |slot| {
            var disk: abi.StorageDeviceInfo = .{};
            const rc = self.storage.device(inv.generation, @intCast(slot), &disk);
            if (rc == 0) continue;
            try self.check("device snapshot", rc, 1);
            if (!std.mem.eql(u8, &disk.disk_guid, &fixture_guid)) continue;
            for (0..disk.partition_slots) |i| {
                var part: abi.StoragePartitionInfo = .{};
                try self.check("partition snapshot", self.storage.partition(inv.generation, &disk.reference, @intCast(i), &part), 1);
                if (part.target.partition_number == 3 and part.target.first_lba == 266240 and part.target.sector_count == 2097152) return part.target;
            }
        }
        return error.MissingFixture;
    }
    fn volume(self: Harness) Error!abi.StorageVolumeInfo {
        const inv = try self.inventory();
        var out: abi.StorageVolumeInfo = .{};
        try self.check("E mount", self.storage.volume(inv.generation, 'E' - 'A', &out), 1);
        try self.expect("fixture E identity", out.target.partition_number == 3 and out.target.partition_guid[0] == 1);
        return out;
    }
    fn witness(self: Harness) Error!void {
        var bytes: [64]u8 = undefined;
        const got = self.sys.fileRead("E:\\VOLUME.TXT", &bytes);
        try self.check("SYSTEM witness bytes", got, 8);
        try self.expect("SYSTEM witness", std.mem.eql(u8, bytes[0..8], "1/SYSTEM"));
        try self.expect("DATA remains usable", self.sys.fileRead("F:\\VOLUME.TXT", &bytes) > 0);
    }
    fn basic(self: Harness) Error!void {
        var target = try self.fixtureTarget();
        const old = try self.volume();
        var before: [512]u8 = undefined;
        try self.check("raw read", self.storage.read(&target, 0, &before), 0);
        try self.check("raw bound", self.storage.read(&target, target.sector_count, &before), abi.storage_error_invalid);
        var id: u64 = 0;
        defer if (id != 0) { _ = self.storage.claimEnd(&id, false); };
        var use: u64 = 0;
        try self.check("local use", self.storage.useBegin("E:\\VOLUME.TXT", &use), 0);
        defer _ = self.storage.useEnd(&use);
        try self.check("local use busy", self.storage.claimBegin(&target, &id), abi.storage_error_busy);
        try self.expect("busy has no claim", id == 0);
        try self.check("close local use", self.storage.useEnd(&use), 0);
        try self.check("local stream begin", self.sys.fileStreamBegin("E:\\STOHOLD.TMP", abi.file_stream_open_create), 0);
        try self.check("local stream busy", self.storage.claimBegin(&target, &id), abi.storage_error_busy);
        try self.check("local stream abort", self.sys.fileStreamAbort("E:\\STOHOLD.TMP"), 0);
        try self.check("begin", self.storage.claimBegin(&target, &id), 0);
        var after: [512]u8 = undefined;
        try self.check("claimed raw read denied", self.storage.read(&target, 0, &after), abi.storage_error_busy);
        var info: abi.FileInfo = .{};
        try self.expect("ordinary file access denied", self.sys.fileInfoRaw("E:\\VOLUME.TXT", &info) <= 0);
        try self.check("old mount denied", self.storage.unmount(&old.reference), abi.storage_error_stale);
        try self.expect("unrelated DATA", self.sys.fileRead("F:\\VOLUME.TXT", &after) > 0);
        try self.check("claimed read", self.storage.claimRead(id, 0, &after), 0);
        try self.expect("raw equality", std.mem.eql(u8, &before, &after));
        try self.check("claimed bounds", self.storage.claimWrite(id, target.sector_count, &before), abi.storage_error_invalid);
        try self.check("claimed write", self.storage.claimWrite(id, 0, &before), 0);
        try self.check("claimed flush", self.storage.claimFlush(id), 0);
        const retired = id;
        try self.check("finish", self.storage.claimEnd(&id, false), 0);
        try self.expect("consumed claim", id == 0);
        try self.check("old claim", self.storage.claimRead(retired, 0, &after), abi.storage_error_stale);
        try self.check("old target", self.storage.read(&target, 0, &after), abi.storage_error_stale);
        const fresh = try self.volume();
        try self.expect("new mount generation", old.reference.generation != fresh.reference.generation);
        try self.witness();
        try self.check("unmount", self.storage.unmount(&fresh.reference), 0);
        target = try self.fixtureTarget();
        var mounted: abi.StorageVolumeRef = .{};
        try self.check("assign E", self.storage.mount(&target, 'E', &mounted), 0);
        try self.expect("assign generation", mounted.generation != fresh.reference.generation);
        try self.check("full device rescan", self.storage.rescan(&target.device), 0);
        try self.witness();
    }
    fn tryClaim(self: Harness, expect_busy: bool) Error!void {
        const target = try self.fixtureTarget();
        var id: u64 = 0;
        const rc = self.storage.claimBegin(&target, &id);
        if (expect_busy) {
            try self.check("remote handle busy", rc, abi.storage_error_busy);
            try self.expect("busy no token", id == 0);
            self.sys.write("[STORAGE] BUSY\r\n");
        } else {
            try self.check("free claim", rc, 0);
            try self.check("free finish", self.storage.claimEnd(&id, false), 0);
            self.sys.write("[STORAGE] FREE\r\n");
        }
    }
    fn waitFree(self: Harness) Error!void {
        const deadline = self.sys.ticks() + self.sys.ticksFromMilliseconds(5000);
        while (true) {
            const target = try self.fixtureTarget();
            var id: u64 = 0;
            const rc = self.storage.claimBegin(&target, &id);
            if (rc != abi.storage_error_busy or self.sys.ticks() >= deadline) {
                try self.check("disconnect drain", rc, 0);
                try self.check("disconnect finish", self.storage.claimEnd(&id, false), 0);
                return;
            }
            self.sys.sleepTicks(self.sys.ticksFromMilliseconds(20));
        }
    }
    fn hold(self: Harness, abandon: bool) Error!void {
        const target = try self.fixtureTarget();
        _ = self.sys.fileDelete(release_path);
        _ = self.sys.fileDelete(ready_path);
        var id: u64 = 0;
        try self.check("hold begin", self.storage.claimBegin(&target, &id), 0);
        var text: [32]u8 = undefined;
        const token = std.fmt.bufPrint(&text, "{d}", .{id}) catch return error.Failed;
        try self.check("RAM ready", self.sys.fileWrite(ready_path, token), @intCast(token.len));
        self.sys.write("[STORAGE] HOLD READY\r\n");
        if (abandon) return; // Exact ProgramThread retirement must close it.
        defer if (id != 0) { _ = self.storage.claimEnd(&id, false); };
        const deadline = self.sys.ticks() + self.sys.ticksFromMilliseconds(15000);
        while (self.sys.fileInfo(release_path) == null) {
            if (self.sys.ticks() >= deadline) return error.Failed;
            self.sys.sleepTicks(self.sys.ticksFromMilliseconds(20));
        }
        try self.check("hold end", self.storage.claimEnd(&id, false), 0);
        _ = self.sys.fileDelete(ready_path);
        _ = self.sys.fileDelete(release_path);
        self.sys.write("[STORAGE] HOLD CLOSED\r\n");
    }
    fn forged(self: Harness) Error!void {
        var text: [32]u8 = undefined;
        const got = self.sys.fileRead(ready_path, &text);
        if (got <= 0) return error.Failed;
        var id = std.fmt.parseInt(u64, text[0..@intCast(got)], 10) catch return error.Failed;
        var sector: [512]u8 = .{0} ** 512;
        try self.check("foreign read", self.storage.claimRead(id, 0, &sector), abi.storage_error_owner);
        try self.check("foreign write", self.storage.claimWrite(id, 0, &sector), abi.storage_error_owner);
        try self.check("foreign flush", self.storage.claimFlush(id), abi.storage_error_owner);
        try self.check("foreign finish", self.storage.claimEnd(&id, false), abi.storage_error_owner);
    }
    fn corrupt(self: Harness) Error!void {
        const target = try self.fixtureTarget();
        var saved: [512]u8 = undefined;
        try self.check("save boot read", self.storage.read(&target, 0, &saved), 0);
        try self.check("save boot RAM", self.sys.fileWrite(saved_boot_path, &saved), 512);
        var id: u64 = 0;
        try self.check("fault begin", self.storage.claimBegin(&target, &id), 0);
        defer if (id != 0) { _ = self.storage.claimEnd(&id, true); };
        const blank: [512]u8 = .{0} ** 512;
        try self.check("fault boot write", self.storage.claimWrite(id, 0, &blank), 0);
        try self.check("reported remount failure", self.storage.claimEnd(&id, false), abi.storage_error_remount);
        try self.expect("failed close consumed", id == 0);
        const inv = try self.inventory();
        var failed: abi.StoragePartitionInfo = .{};
        try self.check("failed target visible", self.storage.partition(inv.generation, &target.device, 2, &failed), 1);
        try self.expect("failed target flag", failed.flags & abi.storage_partition_failed != 0 and failed.last_error < 0);
        var missing: abi.StorageVolumeInfo = .{};
        try self.check("failed mount absent", self.storage.volume(inv.generation, 'E' - 'A', &missing), 0);
    }
    fn restore(self: Harness) Error!void {
        var target = try self.fixtureTarget();
        var saved: [512]u8 = undefined;
        try self.check("saved boot RAM", self.sys.fileRead(saved_boot_path, &saved), 512);
        var id: u64 = 0;
        try self.check("restore begin", self.storage.claimBegin(&target, &id), 0);
        defer if (id != 0) { _ = self.storage.claimEnd(&id, true); };
        try self.check("restore bytes", self.storage.claimWrite(id, 0, &saved), 0);
        try self.check("restore finish", self.storage.claimEnd(&id, true), 0);
        target = try self.fixtureTarget();
        var mounted: abi.StorageVolumeRef = .{};
        try self.check("restore mount", self.storage.mount(&target, 'E', &mounted), 0);
        try self.witness();
        _ = self.sys.fileDelete(saved_boot_path);
    }
    fn flushFailure(self: Harness) Error!void {
        _ = try self.fixtureTarget(); // Technical fixture guard for the scratch disk.
        const inv = try self.inventory();
        for (0..inv.device_slots) |slot| {
            var disk: abi.StorageDeviceInfo = .{};
            if (self.storage.device(inv.generation, @intCast(slot), &disk) != 1) continue;
            if (disk.bus != abi.storage_bus_nvme or disk.sector_count != 32768 or disk.partition_slots != 0) continue;
            const target = r4os.storage.Context.wholeDevice(disk);
            var id: u64 = 0;
            try self.check("flush fault begin", self.storage.claimBegin(&target, &id), 0);
            defer if (id != 0) { _ = self.storage.claimEnd(&id, true); };
            const sector: [512]u8 = .{0x76} ** 512;
            try self.check("arm real backend fault", self.storage.claimWrite(id, 0, &sector), 0);
            try self.check("real backend flush failure", self.storage.claimEnd(&id, true), abi.storage_error_io);
            try self.expect("failed flush close consumed", id == 0);
            const fresh = try self.inventory();
            var result: abi.StorageDeviceInfo = .{};
            try self.check("failed device visible", self.storage.device(fresh.generation, @intCast(slot), &result), 1);
            try self.expect("flush failure retained", result.last_error == abi.storage_error_io and result.flags & abi.storage_device_failed != 0);
            try self.witness();
            return;
        }
        return error.MissingFixture;
    }
};

pub fn run(sys: *const r4os.r4sys.Context, command: []const u8) i32 {
    const h = Harness{ .sys = sys, .storage = .{ .sys = sys } };
    if (!h.storage.available()) return 1;
    const result = if (std.ascii.eqlIgnoreCase(command, "BASIC")) h.basic()
        else if (std.ascii.eqlIgnoreCase(command, "BUSY")) h.tryClaim(true)
        else if (std.ascii.eqlIgnoreCase(command, "FREE")) h.tryClaim(false)
        else if (std.ascii.eqlIgnoreCase(command, "WAITFREE")) h.waitFree()
        else if (std.ascii.eqlIgnoreCase(command, "HOLD")) h.hold(false)
        else if (std.ascii.eqlIgnoreCase(command, "ABANDON")) h.hold(true)
        else if (std.ascii.eqlIgnoreCase(command, "FORGED")) h.forged()
        else if (std.ascii.eqlIgnoreCase(command, "CORRUPT")) h.corrupt()
        else if (std.ascii.eqlIgnoreCase(command, "RESTORE")) h.restore()
        else if (std.ascii.eqlIgnoreCase(command, "FLUSHFAIL")) h.flushFailure()
        else @as(Error!void, error.Failed);
    result catch |err| {
        var text: [120]u8 = undefined;
        sys.write(std.fmt.bufPrint(&text, "[STORAGE] result=FAILED {s}: {s}\r\n", .{ command, @errorName(err) }) catch "Storage test failed\r\n");
        return 1;
    };
    sys.write("[STORAGE] result=OK\r\n");
    return 0;
}
