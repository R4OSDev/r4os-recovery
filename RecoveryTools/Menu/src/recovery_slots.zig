//! Recovery slot policy over shared, exclusively claimed FAT file updates.
const std = @import("std");
const r4os = @import("r4os");
const tools = r4os.storage_tools;
const package = @import("package.zig");
const state = @import("recovery_state.zig");
const pair = @import("recovery_pair.zig");
const Pump = @import("resident.zig").Pump;
pub const Payload = struct { path: []const u8, bytes: []const u8 };
pub const Slot = struct {
    manifest_bytes: []const u8,
    manifest: package.RecoveryManifest,
    files: []Payload,

    pub fn read(a: std.mem.Allocator, bytes: []const u8, hidden: u64, prefix: []const u8, pump: Pump) !Slot {
        const view = try tools.fat32_view.View.init(bytes, hidden);
        const manifest_path = try std.fmt.allocPrint(a, "{s}/manifest.json", .{prefix});
        const manifest_bytes = try view.readFile(a, manifest_path, package.max_manifest_bytes);
        const manifest = try package.parse(package.RecoveryManifest, a, manifest_bytes);
        try package.validateRecovery(manifest);
        const files = try a.alloc(Payload, manifest.files.len + 1);
        const paths = try a.alloc([]const u8, files.len);
        var total: u64 = manifest_bytes.len;
        for (manifest.files, 0..) |file, i| {
            if (file.bytes > bytes.len or total > bytes.len - file.bytes) return error.SlotSize;
            total += file.bytes;
            paths[i] = file.path;
            const path = try std.fmt.allocPrint(a, "{s}/{s}", .{ prefix, file.path });
            const data = try view.readFile(a, path, @intCast(file.bytes));
            if (data.len != file.bytes or !std.mem.eql(u8, &std.fmt.bytesToHex(state.hash(data), .lower), file.sha256)) return error.SlotContent;
            files[i] = .{ .path = file.path, .bytes = data };
            try pump.run("Checking installed Recovery contents", i + 1, files.len);
        }
        paths[manifest.files.len] = "manifest.json";
        files[manifest.files.len] = .{ .path = "manifest.json", .bytes = manifest_bytes };
        try tools.fat32_update.verifyTree(bytes, hidden, prefix, paths);
        const result = Slot{ .manifest_bytes = manifest_bytes, .manifest = manifest, .files = files };
        try result.verifyPair(a, false);
        return result;
    }
    fn get(self: Slot, path: []const u8) []const u8 {
        for (self.files) |file| if (std.mem.eql(u8, file.path, path)) return file.bytes;
        unreachable;
    }
    pub fn verifyPair(self: Slot, a: std.mem.Allocator, required: bool) !void {
        const kernel = self.get("recovery.elf");
        const runtime = self.get("runtime.img");
        const identity = r4os.r4u_artifact.inspect(r4os.r4u_artifact.SliceReader{ .bytes = kernel }, kernel.len) orelse return error.SourceKernel;
        if (identity.kind != .kernel or !std.mem.eql(u8, identity.versionText(), self.manifest.recoveryKernelVersion)) return error.SourceKernel;
        const fs = try tools.fat32_view.View.init(runtime, 0);
        const version = try fs.readFile(a, "R4OS/CONFIG/VERSION.R4S", 4096);
        if (!std.mem.eql(u8, r4os.version_info.parseReleaseVersion(version) orelse return error.SourceVersion, self.manifest.recoveryVersion)) return error.SourceVersion;
        try pair.verify(kernel, runtime, self.manifest.recoveryVersion, self.manifest.recoveryKernelVersion, required);
    }
    fn changes(self: Slot, a: std.mem.Allocator, prefix: []const u8, list: *std.ArrayList(tools.fat32_update.Change)) !void {
        try list.append(a, .{ .path = prefix, .bytes = null });
        for (self.files) |file| try list.append(a, .{ .path = try std.fmt.allocPrint(a, "{s}/{s}", .{ prefix, file.path }), .bytes = file.bytes });
    }
};
pub const Plan = struct {
    previous: ?tools.fat32_update.Prepared,
    current: tools.fat32_update.Prepared,
    unchanged: bool,
    pub fn prepare(a: std.mem.Allocator, original: []const u8, hidden: u64, installation: state.guid.Guid,
        prepared: package.Prepared, running_previous: bool, pump: Pump) !Plan {
        if (prepared.kind != .recovery or original.len > 1024 * 1024 * 1024) return error.InvalidTarget;
        try package.validateRecovery(prepared.recovery);
        const payloads = try a.alloc(Payload, prepared.recovery.files.len + 1);
        for (prepared.recovery.files, 0..) |file, i| payloads[i] = .{ .path = file.path, .bytes = prepared.recovery_archive.get(file.path) orelse return error.MissingFile };
        payloads[prepared.recovery.files.len] = .{ .path = "manifest.json", .bytes = prepared.recovery_archive.manifest };
        const next = Slot{ .manifest_bytes = prepared.recovery_archive.manifest, .manifest = prepared.recovery, .files = payloads };
        try next.verifyPair(a, true);
        const current: ?Slot = Slot.read(a, original, hidden, "CURRENT", pump) catch |err| switch (err) {
            error.OutOfMemory, error.Cancelled => return err,
            else => null,
        };
        if (current) |old| if (std.mem.eql(u8, old.manifest_bytes, next.manifest_bytes)) {
            return .{ .previous = null, .current = try tools.fat32_update.prepare(a, original, hidden, &.{}), .unchanged = true };
        };
        const view = try tools.fat32_view.View.init(original, hidden);
        const record = view.readFile(a, "state.r4s", state.maximum) catch |err| switch (err) {
            error.OutOfMemory => return err,
            else => "",
        };
        const rotate = !running_previous and if (current) |old| state.confirmed(record, installation, old.manifest.recoveryVersion, old.manifest_bytes) else false;
        var previous: ?tools.fat32_update.Prepared = null;
        var changes: std.ArrayList(tools.fat32_update.Change) = .empty;
        if (rotate) {
            try current.?.changes(a, "PREVIOUS", &changes);
            try pump.run("Preparing confirmed CURRENT to PREVIOUS", 0, 0);
            previous = try tools.fat32_update.prepare(a, original, hidden, changes.items);
        } else {
            // Preserve the existing fallback. Refuse an update that cannot
            // offer the verified previous package promised by this action.
            _ = Slot.read(a, original, hidden, "PREVIOUS", pump) catch |err| switch (err) {
                error.OutOfMemory, error.Cancelled => return err,
                else => return error.PreviousUnavailable,
            };
        }
        changes.clearRetainingCapacity();
        try next.changes(a, "CURRENT", &changes);
        var record_buffer: [state.maximum]u8 = undefined;
        const unconfirmed = try state.encode(&record_buffer, installation, next.manifest.recoveryVersion, next.manifest_bytes, false);
        try changes.append(a, .{ .path = "state.r4s", .bytes = unconfirmed });
        try pump.run("Preparing new CURRENT and unconfirmed state", 0, 0);
        return .{ .previous = previous, .current = try tools.fat32_update.prepare(a, if (previous) |p| p.bytes else original, hidden, changes.items), .unchanged = false };
    }
};
