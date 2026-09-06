//! Called only after RAM userland and the Recovery menu rendered successfully.
//! Failure is diagnostic: the running session remains usable and unconfirmed.
const std = @import("std");
const r4os = @import("r4os");
const state = @import("recovery_state.zig");
const package = @import("package.zig");
const selection = @import("selection.zig");
const targets = @import("targets.zig");

pub fn confirm(sys: *const r4os.r4sys.Context) !bool {
    var facts: [state.maximum]u8 = undefined;
    const count = sys.fileRead("C:\\R4OS\\CONFIG\\RECBOOT.R4S", &facts);
    if (count <= 0 or count > facts.len) return error.BootFactsUnavailable;
    const boot = try state.Boot.parse(facts[0..@intCast(count)]);
    if (boot.previous) return false;
    var catalog = try selection.Catalog.scan(sys, .recovery);
    defer catalog.deinit();
    const source = catalog.boot orelse return error.BootFactsUnavailable;
    const installed = for (catalog.installed.items) |candidate| {
        if (!candidate.ambiguous and targets.sameDevice(candidate.parts[3].device, source.device) and
            state.guid.eql(candidate.parts[3].partition_guid, boot.partition) and state.guid.eql(candidate.manifest.disk_guid, boot.disk)) break candidate;
    } else return error.BootFactsUnavailable;
    const storage = r4os.storage.Context{ .sys = sys };
    var lease: u64 = 0;
    if (storage.useBegin("R:\\", &lease) != r4os.abi.storage_result_ok) return error.RecoveryBusy;
    defer _ = storage.useEnd(&lease);
    var arena = std.heap.ArenaAllocator.init(sys.allocator());
    defer arena.deinit();
    const a = arena.allocator();
    const manifest_path = "R:\\CURRENT\\manifest.json";
    const info = sys.fileInfo(manifest_path) orelse return error.ManifestMissing;
    if (info.is_dir != 0 or info.size == 0 or info.size > package.max_manifest_bytes) return error.ManifestMissing;
    const bytes = try a.alloc(u8, @intCast(info.size));
    if (sys.fileRead(manifest_path, bytes) != bytes.len) return error.ManifestMissing;
    const manifest = try package.parse(package.RecoveryManifest, a, bytes);
    try package.validateRecovery(manifest);
    if (!boot.matches(manifest)) return error.BootContentMismatch;
    const buffer = try a.alloc(u8, 64 * 1024);
    var total: u64 = 0;
    for (manifest.files) |file| {
        const limit = installed.parts[3].sector_count * 512;
        if (file.bytes > limit or total > limit - file.bytes) return error.SlotContent;
        total += file.bytes;
        var path_buffer: [512]u8 = undefined;
        const path = try std.fmt.bufPrintZ(&path_buffer, "R:\\CURRENT\\{s}", .{file.path});
        const before = sys.fileInfo(path) orelse return error.SlotContent;
        if (before.is_dir != 0 or before.size != file.bytes) return error.SlotContent;
        var digest = std.crypto.hash.sha2.Sha256.init(.{});
        var offset: u64 = 0;
        while (offset < file.bytes) {
            const amount: usize = @intCast(@min(file.bytes - offset, buffer.len));
            if (sys.fileReadAt(path, @intCast(offset), buffer[0..amount]) != amount) return error.SlotContent;
            digest.update(buffer[0..amount]);
            offset += amount;
            sys.taskYield();
        }
        const after = sys.fileInfo(path) orelse return error.SlotContent;
        if (after.size != before.size or after.first_cluster != before.first_cluster or
            !std.mem.eql(u8, &std.fmt.bytesToHex(digest.finalResult(), .lower), file.sha256)) return error.SlotContent;
    }
    const reread = try a.alloc(u8, bytes.len);
    const after = sys.fileInfo(manifest_path) orelse return error.ManifestMissing;
    if (after.size != bytes.len or sys.fileRead(manifest_path, reread) != bytes.len or !std.mem.eql(u8, bytes, reread)) return error.BootContentMismatch;
    var record_buffer: [state.maximum]u8 = undefined;
    const record = try state.encode(&record_buffer, installed.manifest.installation_id, manifest.recoveryVersion, bytes, true);
    var readback: [state.maximum]u8 = undefined;
    const path = "R:\\state.r4s";
    const existing = sys.fileRead(path, &readback);
    if (existing == record.len and std.mem.eql(u8, readback[0..record.len], record)) return true;
    if (sys.fileStreamBegin(path, r4os.abi.file_stream_open_replace) != r4os.abi.file_stream_result_ok) return error.StateWrite;
    var active = true;
    defer if (active) { _ = sys.fileStreamAbort(path); };
    if (sys.fileStreamWrite(path, 0, record, 0) != record.len or
        sys.fileStreamFinish(path, record.len, 0) != 0) return error.StateFlush;
    active = false;
    // Finish flushes payload, allocation and directory metadata and retires
    // the writer. Abort would delete a still-owned finished staging file.
    if (sys.fileRead(path, &readback) != record.len or !std.mem.eql(u8, readback[0..record.len], record)) return error.StateReadback;
    return true;
}
