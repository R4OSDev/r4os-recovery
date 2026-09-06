//! Strict, content-bound Recovery boot confirmation. Limine never reads it.
const std = @import("std");
const r4os = @import("r4os");
pub const guid = r4os.storage_tools.partition.guid;
const package = @import("package.zig");
pub const maximum = 4096;

pub fn fields(comptime names: []const []const u8, bytes: []const u8) ![names.len][]const u8 {
    if (bytes.len > maximum or !std.mem.startsWith(u8, bytes, "\xef\xbb\xbf")) return error.InvalidState;
    var out: [names.len][]const u8 = .{""} ** names.len;
    var lines = std.mem.splitScalar(u8, bytes[3..], '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trimEnd(u8, raw, "\r");
        if (line.len == 0) continue;
        const at = std.mem.indexOfScalar(u8, line, '=') orelse return error.InvalidState;
        const key = line[0..at];
        const value = line[at + 1 ..];
        if (value.len == 0 or std.mem.indexOfAny(u8, value, "\r\n\x00") != null) return error.InvalidState;
        for (names, 0..) |name, i| {
            if (!std.mem.eql(u8, name, key)) continue;
            if (out[i].len != 0) return error.InvalidState;
            out[i] = value;
            break;
        } else return error.InvalidState;
    }
    for (out) |value| if (value.len == 0) return error.InvalidState;
    if (!std.mem.eql(u8, out[0], "1") or !std.mem.eql(u8, out[2], "1")) return error.InvalidState;
    return out;
}
pub fn hash(bytes: []const u8) [32]u8 {
    var out: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes, &out, .{});
    return out;
}
fn digest(text: []const u8) ![32]u8 {
    if (text.len != 64) return error.InvalidState;
    for (text) |c| if (!std.ascii.isDigit(c) and (c < 'a' or c > 'f')) return error.InvalidState;
    var out: [32]u8 = undefined;
    _ = std.fmt.hexToBytes(&out, text) catch return error.InvalidState;
    return out;
}
pub fn confirmed(bytes: []const u8, installation: guid.Guid, version: []const u8, manifest: []const u8) bool {
    const f = fields(&.{ "R4S_FORMAT", "SCHEMA", "STATE_VERSION", "INSTALLATION_ID", "CURRENT_VERSION", "CURRENT_MANIFEST_SHA256", "CURRENT_CONFIRMED" }, bytes) catch return false;
    return std.mem.eql(u8, f[1], "RECOVERY_STATE") and guid.eql(guid.parse(f[3]) orelse return false, installation) and
        std.mem.eql(u8, f[4], version) and std.mem.eql(u8, &(digest(f[5]) catch return false), &hash(manifest)) and std.mem.eql(u8, f[6], "yes");
}
pub fn encode(out: []u8, installation: guid.Guid, version: []const u8, manifest: []const u8, yes: bool) ![]u8 {
    return std.fmt.bufPrint(out, "\xef\xbb\xbfR4S_FORMAT=1\r\nSCHEMA=RECOVERY_STATE\r\nSTATE_VERSION=1\r\nINSTALLATION_ID={s}\r\nCURRENT_VERSION={s}\r\nCURRENT_MANIFEST_SHA256={s}\r\nCURRENT_CONFIRMED={s}\r\n", .{
        guid.format(installation), version, std.fmt.bytesToHex(hash(manifest), .lower), if (yes) "yes" else "no",
    });
}
pub const Boot = struct {
    disk: guid.Guid,
    partition: guid.Guid,
    previous: bool,
    version: []const u8,
    kernel_version: []const u8,
    kernel_bytes: u64,
    kernel_hash: [32]u8,
    runtime_bytes: u64,
    runtime_hash: [32]u8,
    pub fn parse(bytes: []const u8) !Boot {
        const f = try fields(&.{ "R4S_FORMAT", "SCHEMA", "STATE_VERSION", "DISK_GUID", "PARTITION_GUID", "SLOT", "RECOVERY_VERSION", "KERNEL_VERSION", "KERNEL_BYTES", "KERNEL_SHA256", "RUNTIME_BYTES", "RUNTIME_SHA256" }, bytes);
        if (!std.mem.eql(u8, f[1], "RECOVERY_BOOT") or (!std.mem.eql(u8, f[5], "current") and !std.mem.eql(u8, f[5], "previous"))) return error.InvalidState;
        if (r4os.version_info.parseSemanticVersion(f[6]) == null or r4os.version_info.parseSemanticVersion(f[7]) == null) return error.InvalidState;
        return .{ .disk = guid.parse(f[3]) orelse return error.InvalidState, .partition = guid.parse(f[4]) orelse return error.InvalidState,
            .previous = std.mem.eql(u8, f[5], "previous"), .version = f[6], .kernel_version = f[7],
            .kernel_bytes = std.fmt.parseInt(u64, f[8], 10) catch return error.InvalidState, .kernel_hash = try digest(f[9]),
            .runtime_bytes = std.fmt.parseInt(u64, f[10], 10) catch return error.InvalidState, .runtime_hash = try digest(f[11]) };
    }
    pub fn matches(self: Boot, manifest: package.RecoveryManifest) bool {
        if (!std.mem.eql(u8, manifest.recoveryVersion, self.version) or !std.mem.eql(u8, manifest.recoveryKernelVersion, self.kernel_version)) return false;
        var kernel = false;
        var runtime = false;
        for (manifest.files) |file| {
            if (std.mem.eql(u8, file.path, "recovery.elf")) kernel = file.bytes == self.kernel_bytes and std.mem.eql(u8, &(digest(file.sha256) catch return false), &self.kernel_hash);
            if (std.mem.eql(u8, file.path, "runtime.img")) runtime = file.bytes == self.runtime_bytes and std.mem.eql(u8, &(digest(file.sha256) catch return false), &self.runtime_hash);
        }
        return kernel and runtime;
    }
};

test "confirmation requires exact installation version manifest and unique complete fields" {
    const id = guid.parse("11223344-5566-7788-99aa-bbccddeeff00").?;
    var buffer: [maximum]u8 = undefined;
    const bytes = try encode(&buffer, id, "0.1.17", "manifest", true);
    try std.testing.expect(confirmed(bytes, id, "0.1.17", "manifest"));
    try std.testing.expect(!confirmed(bytes, id, "0.1.16", "manifest"));
    try std.testing.expect(!confirmed(bytes, id, "0.1.17", "manifest changed"));
    var different = id;
    different[0] ^= 1;
    try std.testing.expect(!confirmed(bytes, different, "0.1.17", "manifest"));
    for (0..bytes.len - 3) |size| try std.testing.expect(!confirmed(bytes[0..size], id, "0.1.17", "manifest"));
    const duplicate = try std.fmt.allocPrint(std.testing.allocator, "{s}CURRENT_CONFIRMED=yes\r\n", .{bytes});
    defer std.testing.allocator.free(duplicate);
    try std.testing.expect(!confirmed(duplicate, id, "0.1.17", "manifest"));
    try std.testing.expect(!confirmed(try encode(&buffer, id, "0.1.17", "manifest", false), id, "0.1.17", "manifest"));
}
