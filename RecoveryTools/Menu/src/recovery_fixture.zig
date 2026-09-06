//! Host fault witness with real Recovery ZIPs and the application's slot plan.
const std = @import("std");
const r4os = @import("r4os");
const package = @import("package.zig");
const slots = @import("recovery_slots.zig");
const state = @import("recovery_state.zig");
const tools = r4os.storage_tools;
const core = @import("zip_core");
const expect = std.testing.expect;
const Codec = struct {
    pub fn inspect(_: Codec, bytes: []const u8, entries: []r4os.zip.Entry) !r4os.zip.Info {
        return core.inspect(bytes, entries);
    }
    pub fn begin(_: Codec, bytes: []const u8, entry: *const r4os.zip.Entry, output: []u8, work: *r4os.zip.Work) !r4os.zip.Progress {
        return core.begin(bytes, entry.*, output, &work.data);
    }
    pub fn step(_: Codec, work: *r4os.zip.Work, budget: u32) !r4os.zip.Progress {
        return core.step(&work.data, budget);
    }
};
const Fault = enum { none, second_write, first_flush, readback };
const Memory = struct {
    bytes: []u8,
    fault: Fault = .none,
    writes: usize = 0,
    flushes: usize = 0,
    first: ?usize = null,
    fn read(raw: *anyopaque, lba: u64, out: []u8) i32 {
        const self: *Memory = @ptrCast(@alignCast(raw));
        if (lba > self.bytes.len / 512 or out.len > self.bytes.len - lba * 512) return -1;
        @memcpy(out, self.bytes[@intCast(lba * 512)..][0..out.len]);
        return 0;
    }
    fn write(raw: *anyopaque, lba: u64, data: []const u8) i32 {
        const self: *Memory = @ptrCast(@alignCast(raw));
        self.writes += 1;
        if (self.fault == .second_write and self.writes == 2) return -5;
        if (lba > self.bytes.len / 512 or data.len > self.bytes.len - lba * 512) return -1;
        if (self.first == null) self.first = @intCast(lba * 512);
        @memcpy(self.bytes[@intCast(lba * 512)..][0..data.len], data);
        return 0;
    }
    fn flush(raw: *anyopaque) i32 {
        const self: *Memory = @ptrCast(@alignCast(raw));
        self.flushes += 1;
        if (self.fault == .first_flush and self.flushes == 1) return -5;
        if (self.fault == .readback and self.flushes == 1) self.bytes[self.first.?] ^= 1;
        return 0;
    }
    fn device(self: *Memory, progress: *tools.io.Progress) tools.io.Device {
        return .{ .context = self, .sectors = self.bytes.len / 512, .exclusive = true, .read_fn = read, .write_fn = write, .flush_fn = flush, .progress = progress };
    }
};
fn appendSlot(a: std.mem.Allocator, files: *std.ArrayList(tools.fat32_image.File), prefix: []const u8, source: package.Prepared) !void {
    for (source.recovery.files) |file| try files.append(a, .{ .path = try std.fmt.allocPrint(a, "{s}/{s}", .{ prefix, file.path }), .bytes = source.recovery_archive.get(file.path).? });
    try files.append(a, .{ .path = try std.fmt.allocPrint(a, "{s}/manifest.json", .{prefix}), .bytes = source.recovery_archive.manifest });
}
fn matches(a: std.mem.Allocator, bytes: []const u8, prefix: []const u8, source: package.Prepared) !void {
    const view = try tools.fat32_view.View.init(bytes, 2048);
    for (source.recovery.files) |file| {
        const path = try std.fmt.allocPrint(a, "{s}/{s}", .{ prefix, file.path });
        defer a.free(path);
        try view.matches(path, source.recovery_archive.get(file.path).?);
    }
    var buffer: [80]u8 = undefined;
    try view.matches(try std.fmt.bufPrint(&buffer, "{s}/manifest.json", .{prefix}), source.recovery_archive.manifest);
}
pub fn main(init: std.process.Init) !void {
    const a = init.arena.allocator();
    const args = try init.minimal.args.toSlice(a);
    if (args.len == 7 and std.mem.eql(u8, args[1], "--budget")) return runBudget(init, args[2..]);
    if (args.len == 4 and std.mem.eql(u8, args[1], "--set-state")) {
        const image = try std.Io.Dir.cwd().readFileAlloc(init.io, args[2], a, .limited(2048 * 1024 * 1024 + 1));
        const record = try std.Io.Dir.cwd().readFileAlloc(init.io, args[3], a, .limited(state.maximum + 1));
        try expect(image.len == 2048 * 1024 * 1024);
        const recovery = image[2363392 * 512 ..][0 .. 512 * 1024 * 1024];
        const plan = try tools.fat32_update.prepare(a, recovery, 2363392, &.{.{ .path = "state.r4s", .bytes = record }});
        @memcpy(recovery, plan.bytes);
        try std.Io.Dir.cwd().writeFile(init.io, .{ .sub_path = args[2], .data = image });
        return;
    }
    if (args.len == 4 and std.mem.eql(u8, args[1], "--slot")) {
        const image = try std.Io.Dir.cwd().readFileAlloc(init.io, args[2], a, .limited(2048 * 1024 * 1024 + 1));
        const slot = try slots.Slot.read(a, image[2363392 * 512 ..][0 .. 512 * 1024 * 1024], 2363392, args[3], .{});
        std.debug.print("[RECOVERYSLOTHOST] slot={s} files={d} version={s} result=OK\n", .{ args[3], slot.files.len, slot.manifest.recoveryVersion });
        return;
    }
    if (args.len == 5 and std.mem.eql(u8, args[1], "--write-plan")) {
        const image = try std.Io.Dir.cwd().readFileAlloc(init.io, args[2], a, .limited(2048 * 1024 * 1024 + 1));
        const zip = try std.Io.Dir.cwd().readFileAlloc(init.io, args[3], a, .limited(package.max_archive_bytes));
        const source = try package.prepare(a, Codec{}, zip, .recovery, .{});
        const boot = try tools.fat32_view.View.init(image[4096 * 512 ..][0 .. 128 * 1024 * 1024], 4096);
        const manifest_bytes = try boot.readFile(a, "boot/r4os-installation.json", 16384);
        const Identity = struct { installationId: []const u8 };
        const identity = try std.json.parseFromSlice(Identity, a, r4os.version_info.stripBom(manifest_bytes), .{ .ignore_unknown_fields = true });
        const plan = try slots.Plan.prepare(a, image[2363392 * 512 ..][0 .. 512 * 1024 * 1024], 2363392, state.guid.parse(identity.value.installationId) orelse return error.InvalidTarget, source, false, .{});
        try expect(plan.previous != null);
        var result: std.Io.Writer.Allocating = .init(a);
        try result.writer.writeAll("{\"rotate\":true,\"currentPayloadWrites\":[");
        var first = true;
        for (plan.current.writes) |write| {
            if (write.order != 0) continue;
            try result.writer.print("{s}{{\"first\":{d},\"count\":{d}}}", .{ if (first) "" else ",", @as(u64, write.first) + 2363392, write.count });
            first = false;
        }
        try result.writer.writeAll("]}\n");
        try std.Io.Dir.cwd().writeFile(init.io, .{ .sub_path = args[4], .data = result.written() });
        return;
    }
    if (args.len != 5) return error.Arguments; // old CURRENT, new ZIP, older PREVIOUS, result JSON
    var prepared: [3]package.Prepared = undefined;
    for (&prepared, args[1..4]) |*value, path| {
        const bytes = try std.Io.Dir.cwd().readFileAlloc(init.io, path, a, .limited(package.max_archive_bytes));
        value.* = try package.prepare(a, Codec{}, bytes, .recovery, .{});
    }
    const old = prepared[0];
    const next = prepared[1];
    const fallback = prepared[2];
    const id = state.guid.parse("01234567-89ab-4cde-8123-456789abcdef").?;
    var files: std.ArrayList(tools.fat32_image.File) = .empty;
    try appendSlot(a, &files, "CURRENT", old);
    try appendSlot(a, &files, "PREVIOUS", fallback);
    var record_buffer: [state.maximum]u8 = undefined;
    try files.append(a, .{ .path = "state.r4s", .bytes = try state.encode(&record_buffer, id, old.recovery.recoveryVersion, old.recovery_archive.manifest, true) });
    try files.append(a, .{ .path = "INSTALL/RELEASE.ZIP", .bytes = "original R4OS ZIP witness" });
    try files.append(a, .{ .path = "INSTALL/RECOVERY.ZIP", .bytes = next.archive.original });
    const original = try tools.fat32_image.prepare(a, 256 * 2048, 2048, "RECOVERY", 20, files.items);
    const plan = try slots.Plan.prepare(a, original.bytes, 2048, id, next, false, .{});
    try expect(plan.previous != null and !plan.unchanged);
    try matches(a, plan.previous.?.bytes, "CURRENT", old);
    try matches(a, plan.previous.?.bytes, "PREVIOUS", old);
    try matches(a, plan.current.bytes, "CURRENT", next);
    try matches(a, plan.current.bytes, "PREVIOUS", old);
    var view = try tools.fat32_view.View.init(plan.current.bytes, 2048);
    try view.matches("INSTALL/RELEASE.ZIP", "original R4OS ZIP witness");
    try view.matches("INSTALL/RECOVERY.ZIP", next.archive.original);
    const record = try view.readFile(a, "state.r4s", state.maximum);
    try expect(!state.confirmed(record, id, next.recovery.recoveryVersion, next.recovery_archive.manifest));
    const memory_bytes = try a.dupe(u8, original.bytes);
    const work = try a.alloc(u8, tools.io.scratch_bytes);
    var cases: usize = 0;
    for ([_]bool{ false, true }) |current_phase| {
        for ([_]Fault{ .second_write, .first_flush, .readback }) |fault| {
            @memcpy(memory_bytes, if (current_phase) plan.previous.?.bytes else original.bytes);
            var memory = Memory{ .bytes = memory_bytes, .fault = fault };
            var progress = tools.io.Progress{};
            const phase = if (current_phase) plan.current else plan.previous.?;
            const errors = switch (fault) {
                .second_write => error.WriteFailed,
                .first_flush => error.FlushFailed,
                .readback => error.VerifyFailed,
                else => unreachable,
            };
            try std.testing.expectError(errors, phase.execute(memory.device(&progress), work));
            try expect(progress.write_attempted and !progress.verified);
            // These failures occur in the payload phase, before shared FAT
            // publication. The other complete slot must remain readable.
            try matches(a, memory_bytes, if (current_phase) "PREVIOUS" else "CURRENT", old);
            view = try tools.fat32_view.View.init(memory_bytes, 2048);
            try view.matches("INSTALL/RELEASE.ZIP", "original R4OS ZIP witness");
            try view.matches("INSTALL/RECOVERY.ZIP", next.archive.original);
            {
                var audit_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
                defer audit_arena.deinit();
                const audit = try tools.fat32_update.prepare(audit_arena.allocator(), memory_bytes, 2048, &.{});
                try expect(std.mem.eql(u8, audit.bytes, memory_bytes));
            }
            cases += 1;
            std.debug.print("[RECOVERYSLOTHOST] phase={s} fault={s} result=REJECT other_slot=OK cache=OK\n", .{ if (current_phase) "current" else "previous", @tagName(fault) });
        }
    }
    @memcpy(memory_bytes, original.bytes);
    var memory = Memory{ .bytes = memory_bytes };
    var progress = tools.io.Progress{};
    try plan.previous.?.execute(memory.device(&progress), work);
    progress.verified = false;
    try plan.current.execute(memory.device(&progress), work);
    try expect(progress.verified and std.mem.eql(u8, memory_bytes, plan.current.bytes));
    // PREVIOUS boot and stale/invalid confirmation must preserve the old
    // fallback, even when CURRENT itself is a valid complete package.
    for (0..3) |condition| {
        var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer arena.deinit();
        const alloc = arena.allocator();
        const bytes = if (condition == 2) blk: {
            const broken = try tools.fat32_update.prepare(alloc, original.bytes, 2048, &.{.{ .path = "state.r4s", .bytes = "truncated state" }});
            break :blk broken.bytes;
        } else original.bytes;
        var other_id = id;
        if (condition == 1) other_id[0] ^= 1;
        const preserved = try slots.Plan.prepare(alloc, bytes, 2048, other_id, next, condition == 0, .{});
        try expect(preserved.previous == null);
        try matches(alloc, preserved.current.bytes, "PREVIOUS", fallback);
    }
    const result = try std.fmt.allocPrint(a, "{{\"result\":\"PASS\",\"payloadFaultCases\":{d},\"preservationCases\":3,\"completeRotation\":true,\"currentVersion\":\"{s}\",\"nextVersion\":\"{s}\"}}\n", .{ cases, old.recovery.recoveryVersion, next.recovery.recoveryVersion });
    try std.Io.Dir.cwd().writeFile(init.io, .{ .sub_path = args[4], .data = result });
    std.debug.print("[RECOVERYSLOTHOST] rotation=VERIFIED state=UNCONFIRMED cache=PRESERVED result=OK\n", .{});
}

fn runBudget(init: std.process.Init, args: []const []const u8) !void {
    const a = init.arena.allocator();
    const cwd = std.Io.Dir.cwd();
    const old_zip = try cwd.readFileAlloc(init.io, args[0], a, .limited(package.max_archive_bytes));
    const next_zip = try cwd.readFileAlloc(init.io, args[1], a, .limited(package.max_archive_bytes));
    const release = try cwd.readFileAlloc(init.io, args[2], a, .limited(package.max_archive_bytes));
    const old = try package.prepare(a, Codec{}, old_zip, .recovery, .{});
    const next = try package.prepare(a, Codec{}, next_zip, .recovery, .{});
    const id = state.guid.parse("01234567-89ab-4cde-8123-456789abcdef").?;
    const hidden = 2363392;
    var files: std.ArrayList(tools.fat32_image.File) = .empty;
    try appendSlot(a, &files, "CURRENT", old);
    try appendSlot(a, &files, "PREVIOUS", old);
    var record: [state.maximum]u8 = undefined;
    try files.append(a, .{ .path = "state.r4s", .bytes = try state.encode(&record, id, old.recovery.recoveryVersion, old.recovery_archive.manifest, true) });
    try files.append(a, .{ .path = "INSTALL/RELEASE.ZIP", .bytes = release });
    const base = try tools.fat32_image.prepare(a, 512 * 2048, hidden, "RECOVERY", 23, files.items);
    const free = @as(u64, base.stats.geometry.sectors - base.stats.used_sectors) * 512;
    try @import("capacity.zig").requireCacheHeadroom(free, release.len, next_zip.len, base.stats.geometry.sectors_per_cluster * 512);
    try std.testing.expectError(error.RecoveryCapacity, @import("capacity.zig").requireCacheHeadroom(free, base.bytes.len, next_zip.len, base.stats.geometry.sectors_per_cluster * 512));
    try files.appendSlice(a, &.{ .{ .path = "INSTALL/RELEASE.PART", .bytes = release }, .{ .path = "INSTALL/RECOVERY.ZIP", .bytes = next_zip }, .{ .path = "INSTALL/RECOVERY.PART", .bytes = next_zip } });
    const reserve = try a.alloc(u8, @import("capacity.zig").metadata_reserve);
    @memset(reserve, 0);
    try files.append(a, .{ .path = "INSTALL/BUDGET.RES", .bytes = reserve });
    const complete = try tools.fat32_image.prepare(a, 512 * 2048, hidden, "RECOVERY", 23, files.items);
    const plan = try slots.Plan.prepare(a, complete.bytes, hidden, id, next, false, .{});
    try expect(plan.previous != null and !plan.unchanged);
    const view = try tools.fat32_view.View.init(plan.current.bytes, hidden);
    for ([_][]const u8{ "INSTALL/RELEASE.ZIP", "INSTALL/RELEASE.PART" }) |path| try view.matches(path, release);
    for ([_][]const u8{ "INSTALL/RECOVERY.ZIP", "INSTALL/RECOVERY.PART" }) |path| try view.matches(path, next_zip);
    for ([_][]const u8{ "CURRENT", "PREVIOUS" }, [_]package.Prepared{ next, old }) |prefix, source| {
        for (source.recovery.files) |file| try view.matches(try std.fmt.allocPrint(a, "{s}/{s}", .{ prefix, file.path }), source.recovery_archive.get(file.path).?);
    }
    // A real overfull file plan must fail before any write; all allocations
    // and side effects are confined to this disposable host witness.
    const before = state.hash(plan.current.bytes);
    const oversized = try a.alloc(u8, plan.current.bytes.len);
    @memset(oversized, 0x5a);
    try std.testing.expectError(error.ImageFull, tools.fat32_update.prepare(a, plan.current.bytes, hidden, &.{.{ .path = "INSTALL/OVER.BIN", .bytes = oversized }}));
    try expect(std.mem.eql(u8, &before, &state.hash(plan.current.bytes)));
    const audit = try tools.fat32_update.prepare(a, plan.current.bytes, hidden, &.{});
    try expect(std.mem.eql(u8, audit.bytes, plan.current.bytes));
    try cwd.writeFile(init.io, .{ .sub_path = args[4], .data = plan.current.bytes });
    const report = try std.fmt.allocPrint(a, "{{\"result\":\"PASS\",\"partitionBytes\":{d},\"releaseBytes\":{d},\"recoveryBytes\":{d},\"metadataReserve\":{d},\"rotation\":true,\"overfullRejected\":true,\"oldVersion\":\"{s}\",\"newVersion\":\"{s}\"}}\n", .{ plan.current.bytes.len, release.len, next_zip.len, reserve.len, old.recovery.recoveryVersion, next.recovery.recoveryVersion });
    try cwd.writeFile(init.io, .{ .sub_path = args[3], .data = report });
    std.debug.print("[RECOVERYBUDGET] slots=2 release_archives=2 recovery_archives=2 metadata_reserve=1MB rotation=OK overfull=REJECTED result=OK\n", .{});
}
