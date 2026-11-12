//! The actual update engine with finite, competing journal replacement through R4SYS.
const std = @import("std");
const r4os = @import("r4os");
const engine = @import("update_engine");
const recovery = r4os.system_update_recovery;
const batch = r4os.system_update_batch;
const expect = std.testing.expect;

const paths = [_][]const u8{
    "C:\\R4OS\\UPDATE\\STAGED\\SYSUPD0.JRN",
    "C:\\R4OS\\UPDATE\\STAGED\\SYSUPD1.JRN",
    "C:\\R4OS\\UPDATE\\STAGED\\SYSBCH0.JRN",
    "C:\\R4OS\\UPDATE\\STAGED\\SYSBCH1.JRN",
};
const File = struct { bytes: [8192]u8 = undefined, len: usize = 0, stats: usize = 0 };
var files: [4]File = undefined;
var race_slot: ?usize = null;
var race_seen = false;
var permanent = false;
var remove_batch = false;
var output: [8192]u8 = undefined;
var output_len: usize = 0;
var sleeps: usize = 0;
var file_writes: usize = 0;
var update_lease = false;
var prepare_at_lease = false;
var removal_at_lease = false;
var corrupt_removal = false;
const lock_path = "C:\\R4OS\\UPDATE\\STAGED\\SYSLOCK.LCK";

fn index(path: [*:0]const u8) ?usize {
    for (paths, 0..) |name, i| if (std.mem.eql(u8, name, std.mem.span(path))) return i;
    return null;
}
fn info(path: [*:0]const u8, out: *r4os.abi.FileInfo) callconv(.c) i32 {
    out.* = .{};
    if (std.mem.endsWith(u8, std.mem.span(path), "REMOVE0.JRN") or std.mem.endsWith(u8, std.mem.span(path), "REMOVE1.JRN")) {
        if (!corrupt_removal) return 0;
        out.exists = 1; // Truncated concurrently admitted removal journal.
        return 1;
    }
    const i = index(path) orelse {
        out.exists = 1;
        out.is_dir = 1;
        return 1;
    };
    const f = &files[i];
    f.stats += 1;
    if (f.len == 0) return 0;
    out.exists = 1;
    out.size = @intCast(f.len);
    // Simulate atomic replacement with a shorter, valid journal after stat.
    if (race_slot == i and (!race_seen or permanent)) {
        out.size += 31;
        race_seen = true;
        if (remove_batch) {
            files[2].len = 0;
            files[3].len = 0;
        }
    }
    return 1;
}
fn read(path: [*:0]const u8, offset: u32, bytes: [*]u8, capacity: u32) callconv(.c) i32 {
    const i = index(path) orelse return -8;
    const f = &files[i];
    if (offset >= f.len) return 0;
    const n = @min(f.len - offset, capacity);
    @memcpy(bytes[0..n], f.bytes[offset..][0..n]);
    return @intCast(n);
}
fn write(bytes: [*]const u8, len: u32) callconv(.c) i32 {
    const n = @min(len, output.len - output_len);
    @memcpy(output[output_len..][0..n], bytes[0..n]);
    output_len += n;
    return @intCast(len);
}
fn putc(ch: u8) callconv(.c) void {
    _ = write(@ptrCast(&ch), 1);
}
fn sleep(_: u64) callconv(.c) void {
    sleeps += 1;
}
fn mkdir(_: [*:0]const u8) callconv(.c) i32 {
    return 0;
}
fn writeFile(path: [*:0]const u8, bytes: [*]const u8, len: u32) callconv(.c) i32 {
    if (!update_lease) return -8;
    const i = index(path) orelse return -8;
    if (len > files[i].bytes.len) return -8;
    @memcpy(files[i].bytes[0..len], bytes[0..len]);
    files[i].len = len;
    file_writes += 1;
    return @intCast(len);
}
fn streamBegin(path: [*:0]const u8, _: u32) callconv(.c) i32 {
    if (!std.mem.eql(u8, std.mem.span(path), lock_path)) return -8;
    if (update_lease) return r4os.abi.file_stream_error_exists;
    if (removal_at_lease) {
        removal_at_lease = false;
        corrupt_removal = true;
    }
    if (prepare_at_lease) {
        prepare_at_lease = false;
        var newer: batch.BatchJournal = .{};
        if (!batch.parseJournalInto(files[2].bytes[0..files[2].len], 0, &newer)) return -8;
        newer.batch_generation += 1;
        newer.journal_generation += 1;
        newer.phase = .staging;
        newer.current_package = 0;
        files[2].len = (batch.serializeJournal(&newer, &files[2].bytes) orelse return -8).len;
    }
    update_lease = true;
    return 0;
}
fn streamWrite(path: [*:0]const u8, _: u64, _: [*]const u8, len: u32, _: u32) callconv(.c) i32 {
    return if (std.mem.eql(u8, std.mem.span(path), lock_path)) @intCast(len) else -8;
}
fn streamFinish(path: [*:0]const u8, _: u64, _: u32) callconv(.c) i32 {
    return if (std.mem.eql(u8, std.mem.span(path), lock_path)) 0 else -8;
}
fn streamAbort(path: [*:0]const u8) callconv(.c) i32 {
    if (!std.mem.eql(u8, std.mem.span(path), lock_path)) return -8;
    update_lease = false;
    return 0;
}

fn text(out: []u8, value: []const u8) usize {
    @memcpy(out[0..value.len], value);
    return value.len;
}
fn reset() void {
    files = @splat(.{});
    race_slot = null;
    race_seen = false;
    permanent = false;
    remove_batch = false;
    output_len = 0;
    sleeps = 0;
    file_writes = 0;
    update_lease = false;
    prepare_at_lease = false;
    removal_at_lease = false;
    corrupt_removal = false;
}
fn journal(slot: usize, generation: u64) !void {
    var value: recovery.TransactionJournal = .{
        .valid = true,
        .transaction_generation = 5,
        .journal_generation = generation,
        .package_payload_count = 1,
        .payload_count = 1,
        .package_length = 1000,
    };
    value.source_len = text(&value.source_path, "C:\\R4OS\\UPDATE\\INBOX\\PKG.R4U");
    value.source_version_len = text(&value.source_version, "0.82.0");
    value.target_version_len = text(&value.target_version, "0.82.0");
    value.package_version_len = text(&value.package_version, "1.0.0");
    const target = "C:\\R4OS\\SOFTWARE\\TERMINAL\\TERMINAL.R4X";
    const entry = &value.payloads[0];
    entry.target_len = text(&entry.target_path, target);
    entry.stage_len = recovery.buildInternal83Name(&entry.stage_path, target, 'S', 5, 0) orelse return error.Fixture;
    entry.backup_len = recovery.buildInternal83Name(&entry.backup_path, target, 'B', 5, 0) orelse return error.Fixture;
    files[slot].len = (recovery.serializeJournal(&value, &files[slot].bytes) orelse return error.Fixture).len;
    var parsed: recovery.TransactionJournal = .{};
    try expect(recovery.parseJournalInto(files[slot].bytes[0..files[slot].len], @intCast(slot), &parsed));
}
fn batchJournal(slot: usize, generation: u64) !void {
    var value: batch.BatchJournal = .{
        .valid = true,
        .batch_generation = 4,
        .journal_generation = generation,
        .phase = .installed,
        .package_count = 1,
        .current_package = 1,
    };
    value.source_release_len = text(&value.source_release, "0.82.0");
    value.target_release_len = text(&value.target_release, "0.82.0");
    const entry = &value.packages[0];
    entry.path_len = text(&entry.path, "C:\\R4OS\\UPDATE\\INBOX\\PKG.R4U");
    entry.package_len = text(&entry.package, "PKG");
    entry.package_version_len = text(&entry.package_version, "1.0.0");
    entry.release_len = text(&entry.release, "0.82.0");
    entry.package_length = 1000;
    entry.package_digest = 100;
    entry.manifest_checksum = 200;
    entry.component_digest = 300;
    files[slot].len = (batch.serializeJournal(&value, &files[slot].bytes) orelse return error.Fixture).len;
    var parsed: batch.BatchJournal = .{};
    try expect(batch.parseJournalInto(files[slot].bytes[0..files[slot].len], @intCast(slot - 2), &parsed));
}
fn observe(want_resume: bool) engine.Result {
    const api: r4os.abi.R4XStartR4Sys = .{
        .write = @intFromPtr(&write),
        .putc = @intFromPtr(&putc),
        .sleep_ticks = @intFromPtr(&sleep),
        .file_info = @intFromPtr(&info),
        .file_read_at = @intFromPtr(&read),
        .dir_create = @intFromPtr(&mkdir),
        .file_write = @intFromPtr(&writeFile),
        .file_stream_begin = @intFromPtr(&streamBegin),
        .file_stream_write = @intFromPtr(&streamWrite),
        .file_stream_finish = @intFromPtr(&streamFinish),
        .file_stream_abort = @intFromPtr(&streamAbort),
    };
    const bundle: r4os.program.Bundle = .{ .raw = undefined, .sys = &api };
    const sys = r4os.r4sys.Context.init(&bundle);
    var owner: engine.Engine = .{ .ctx = sys, .files = .{ .sys = sys } };
    return if (want_resume) owner.resumeBatch() else owner.status();
}
fn status() engine.Result {
    return observe(false);
}

fn checkInstalledInventoryReceipt() !void {
    // Unmodified original journal from the native L66C installation. A
    // restart batch has payload + inventory + the owner's release marker.
    const original = @embedFile("Fixtures/installed-library-v5.jrn");
    reset();
    @memcpy(files[0].bytes[0..original.len], original);
    files[0].len = original.len;
    const installed = status();
    try expect(installed.exit_code == 0 and installed.state == .installed and installed.inventory_consistent);
    try expect(installed.payload_count == 1 and installed.transaction_step_count == 3 and installed.component_count == 1);
    var pending: recovery.TransactionJournal = .{};
    try expect(recovery.parseJournalInto(original, 0, &pending));
    pending.phase = .post_boot;
    files[0].len = (recovery.serializeJournal(&pending, &files[0].bytes) orelse return error.Fixture).len;
    const unconfirmed = status();
    try expect(unconfirmed.exit_code == 0 and unconfirmed.state == .restart_required and !unconfirmed.inventory_consistent);
    try expect(file_writes == 0);
}

fn resumeFixture(phase: batch.Phase, transaction_phase: recovery.JournalPhase, same_package: bool) !void {
    reset();
    try journal(0, 10);
    try batchJournal(2, 7);
    var transaction: recovery.TransactionJournal = .{};
    try expect(recovery.parseJournalInto(files[0].bytes[0..files[0].len], 0, &transaction));
    transaction.phase = transaction_phase;
    transaction.batch = true;
    transaction.reboot = true;
    transaction.components_bound = true;
    transaction.component_digest = std.hash.Fnv1a_32.hash(&.{ 0, 0, 0, 0 });
    if (transaction_phase != .stage) {
        transaction.payloads[0].committed = true;
        transaction.committed_count = 1;
    }
    if (transaction_phase == .rolled_back) {
        transaction.payloads[0].committed = false;
        transaction.committed_count = 0;
        transaction.payloads[0].rolled_back = true;
        transaction.rollback_count = 1;
    }
    files[0].len = (recovery.serializeJournal(&transaction, &files[0].bytes) orelse return error.Fixture).len;
    var pending: batch.BatchJournal = .{};
    try expect(batch.parseJournalInto(files[2].bytes[0..files[2].len], 0, &pending));
    pending.phase = phase;
    pending.current_package = if (phase == .pending_restart) 1 else 0;
    pending.packages[0].package_digest = if (same_package) 0 else 1;
    pending.packages[0].manifest_checksum = 0;
    pending.packages[0].component_digest = 0;
    files[2].len = (batch.serializeJournal(&pending, &files[2].bytes) orelse return error.Fixture).len;
}
fn checkResumeBatchIdentity() !void {
    // Removal may appear between the initial inspection and SYSLOCK. Even
    // an incomplete owner receipt must stop R4U without leaking the lease.
    try resumeFixture(.pending_restart, .cleanup, true);
    removal_at_lease = true;
    try std.testing.expectEqual(@as(i32, 1), observe(true).exit_code);
    try std.testing.expectEqual(@as(usize, 0), file_writes);
    try expect(!update_lease);
    // A new preparation needs its own COMMIT, even if the package and release
    // repeat the old completed batch. There is no installed-generation proof.
    for ([_]batch.Phase{ .staging, .staged }) |phase| {
        try resumeFixture(phase, .cleanup, phase == .staged);
        const before = files[0];
        const result = observe(true);
        try expect(result.exit_code != 0); // Package absent: fresh preflight fails.
        try expect(std.mem.indexOf(u8, output[0..output_len], "Installed") == null);
        try std.testing.expectEqualSlices(u8, before.bytes[0..before.len], files[0].bytes[0..files[0].len]);
    }
    // Pending transactions bind the complete combined package identity before
    // cleanup, post-boot verification or rollback can mutate their batch.
    for ([_]recovery.JournalPhase{ .stage, .post_boot, .applied, .cleanup, .rolled_back }) |phase| {
        try resumeFixture(.pending_restart, phase, false);
        try std.testing.expectEqual(@as(i32, 1), observe(true).exit_code);
        try expect(std.mem.indexOf(u8, output[0..output_len], "reason=transaction-binding") != null);
        try std.testing.expectEqual(@as(usize, 0), file_writes);
    }
    try resumeFixture(.pending_restart, .cleanup, true);
    try std.testing.expectEqual(@as(i32, 0), observe(true).exit_code);
    try expect(std.mem.indexOf(u8, output[0..output_len], "Installed batch=4") != null);
    // A competing STAGE can replace even an identical package batch between
    // the initial observation and lease acquisition. Re-read its phase too.
    try resumeFixture(.pending_restart, .cleanup, true);
    prepare_at_lease = true;
    try expect(observe(true).exit_code != 0);
    try expect(std.mem.indexOf(u8, output[0..output_len], "Installed") == null);
    try expect(!update_lease);
}

test "status resnapshots a replaced journal without stale partial results" {
    reset();
    try journal(0, 10);
    try journal(1, 11);
    try batchJournal(2, 7);
    race_slot = 1;
    const result = status();
    if (result.exit_code != 0) std.debug.print("status fixture output={s} stats={d},{d},{d},{d}\n", .{ output[0..output_len], files[0].stats, files[1].stats, files[2].stats, files[3].stats });
    try std.testing.expectEqual(@as(i32, 0), result.exit_code);
    try expect(files[1].stats >= 2 and files[1].stats <= 3);
    try expect(std.mem.indexOf(u8, output[0..output_len], "generation=11 ") != null);
    try expect(std.mem.indexOf(u8, output[0..output_len], "FAILED") == null);

    reset();
    try batchJournal(2, 7);
    try batchJournal(3, 8);
    race_slot = 3;
    try std.testing.expectEqual(@as(i32, 0), status().exit_code);
    try expect(files[3].stats >= 2 and files[3].stats <= 3);

    reset();
    try journal(1, 11);
    try batchJournal(2, 7);
    race_slot = 1;
    remove_batch = true;
    const changed = status();
    try std.testing.expectEqual(@as(i32, 0), changed.exit_code);
    try std.testing.expectEqual(@as(u64, 0), changed.batch_generation);
    try expect(std.mem.indexOf(u8, output[0..output_len], "batch-state=") == null);

    reset();
    try journal(0, 10);
    try journal(1, 11);
    try batchJournal(2, 7);
    race_slot = 1;
    permanent = true;
    const failed = status();
    try std.testing.expectEqual(@as(i32, 1), failed.exit_code);
    try std.testing.expectEqual(@as(u64, 0), failed.batch_generation);
    try std.testing.expectEqual(@as(u64, 0), failed.transaction_generation);
    try expect(files[1].stats <= 3 and sleeps <= 16);
    try expect(std.mem.indexOf(u8, output[0..output_len], "reason=journal-read") != null);
    try checkResumeBatchIdentity();
    try checkInstalledInventoryReceipt();
}
