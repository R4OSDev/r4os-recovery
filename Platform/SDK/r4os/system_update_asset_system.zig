//! Existing system-update targets and the installed BOOT binding. Read only.
const std = @import("std");
const r = @import("r4os");
const manifest = r.r4u_manifest;
pub const kernel_target = "/boot/r4os.elf";
pub const Digest = struct { size: u64, sha256: [64]u8, checksum: u32 };
pub const BootProof = struct {
    boot_guid: [36]u8,
    configuration_sha256: [64]u8,
    manifest_sha256: [64]u8,

    pub fn eql(self: BootProof, other: BootProof) bool {
        return std.mem.eql(u8, &self.boot_guid, &other.boot_guid) and
            std.mem.eql(u8, &self.configuration_sha256, &other.configuration_sha256) and
            std.mem.eql(u8, &self.manifest_sha256, &other.manifest_sha256);
    }
};
pub fn targetSupported(kind: manifest.ComponentKind, path: []const u8, name: []const u8) bool {
    if (kind == .kernel) return manifest.targetEquals(path, kernel_target) and std.ascii.eqlIgnoreCase(name, "KERNEL");
    const parsed = r.AbsoluteFilePath.parse(path) catch return false;
    if (kind == .r4x) return manifest.paths.applicationTarget(parsed.bytes());
    if (kind != .r4l or !std.ascii.startsWithIgnoreCase(parsed.bytes(), "C:\\R4OS\\LIBS\\")) return false;
    const leaf = parsed.bytes()[(std.mem.lastIndexOfScalar(u8, parsed.bytes(), '\\') orelse return false) + 1 ..];
    return std.ascii.endsWithIgnoreCase(leaf, ".R4L") and std.ascii.eqlIgnoreCase(leaf[0 .. leaf.len - 4], name);
}
pub const RawPath = struct {
    storage: [1024:0]u8 = @splat(0),
    len: usize,
    pub fn init(path: []const u8) !RawPath {
        // The only non-drive path is the installed boot owner's kernel leaf.
        var result = RawPath{ .len = 0 };
        if (manifest.targetEquals(path, kernel_target)) {
            result.len = kernel_target.len;
            @memcpy(result.storage[0..result.len], kernel_target);
        } else {
            const parsed = try r.AbsoluteFilePath.parse(path);
            result.len = parsed.bytes().len;
            @memcpy(result.storage[0..result.len], parsed.bytes());
        }
        return result;
    }
    pub fn asZ(self: *const RawPath) [*:0]const u8 {
        return self.storage[0..self.len :0].ptr;
    }
};
pub const Reader = struct {
    ctx: *const r.r4sys.Context,
    path: [*:0]const u8,
    pub fn readAt(self: Reader, offset: u64, out: []u8) bool {
        return offset <= std.math.maxInt(u32) and self.ctx.fileReadAt(self.path, @intCast(offset), out) == out.len;
    }
};
pub fn info(ctx: *const r.r4sys.Context, path: []const u8) !?r.abi.FileInfo {
    const raw = try RawPath.init(path);
    var value: r.abi.FileInfo = .{};
    const rc = ctx.fileInfoRaw(raw.asZ(), &value);
    if (rc == 0) return null;
    if (rc < 0 or value.exists == 0) return error.AssetInfo;
    return value;
}
pub fn inspect(ctx: *const r.r4sys.Context, path: []const u8) !r.r4u_artifact.Identity {
    const raw = try RawPath.init(path);
    const value = (try info(ctx, path)) orelse return error.AssetMissing;
    if (value.is_dir != 0) return error.AssetType;
    return r.r4u_artifact.inspect(Reader{ .ctx = ctx, .path = raw.asZ() }, value.size) orelse error.AssetIdentity;
}
pub fn digest(ctx: *const r.r4sys.Context, path: []const u8, scratch: []u8) !Digest {
    const raw = try RawPath.init(path);
    const before = (try info(ctx, path)) orelse return error.AssetMissing;
    if (before.is_dir != 0 or before.size == 0 or before.size > std.math.maxInt(u32) or scratch.len == 0) return error.AssetSize;
    var hash = std.crypto.hash.sha2.Sha256.init(.{});
    var checksum: u32 = 2166136261;
    var offset: u64 = 0;
    while (offset < before.size) {
        const chunk = scratch[0..@intCast(@min(scratch.len, before.size - offset))];
        if (!(Reader{ .ctx = ctx, .path = raw.asZ() }).readAt(offset, chunk)) return error.AssetRead;
        hash.update(chunk);
        for (chunk) |byte| checksum = (checksum ^ byte) *% 16777619;
        offset += chunk.len;
    }
    const after = (try info(ctx, path)) orelse return error.AssetChanged;
    if (after.is_dir != 0 or after.size != before.size) return error.AssetChanged;
    return .{ .size = before.size, .sha256 = std.fmt.bytesToHex(hash.finalResult(), .lower), .checksum = checksum };
}
fn read(ctx: *const r.r4sys.Context, allocator: std.mem.Allocator, path: [*:0]const u8, limit: usize) ![]u8 {
    var value: r.abi.FileInfo = .{};
    if (ctx.fileInfoRaw(path, &value) <= 0 or value.exists == 0 or value.is_dir != 0 or value.size == 0 or value.size > limit) return error.BootPlanUnavailable;
    const bytes = try allocator.alloc(u8, @intCast(value.size));
    errdefer allocator.free(bytes);
    if (!(Reader{ .ctx = ctx, .path = path }).readAt(0, bytes)) return error.BootPlanRead;
    return bytes;
}
fn sha(bytes: []const u8) [64]u8 {
    var value: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(bytes, &value, .{});
    return std.fmt.bytesToHex(value, .lower);
}
pub fn kernelConfigMatches(bytes: []const u8, boot_guid: []const u8) bool {
    if (boot_guid.len != 36) return false;
    for (boot_guid, 0..) |byte, i| {
        if (i == 8 or i == 13 or i == 18 or i == 23) {
            if (byte != '-') return false;
        } else if (!std.ascii.isHex(byte)) return false;
    }
    var expected_buffer: [96]u8 = undefined;
    const expected = std.fmt.bufPrint(&expected_buffer, "guid({s}):{s}", .{ boot_guid, kernel_target }) catch return false;
    var lines = std.mem.splitScalar(u8, bytes, '\n');
    var selected = false;
    var paths: usize = 0;
    var protocols: usize = 0;
    var found = false;
    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, raw, " \t\r");
        if (line.len == 0 or line[0] == '#') continue;
        if (line[0] == '/') {
            if (selected and (paths != 1 or protocols != 1)) return false;
            selected = std.mem.eql(u8, line, "/R4OS") or std.mem.eql(u8, line, "/R4OS Software Graphics");
            paths = 0;
            protocols = 0;
        } else if (selected and std.ascii.startsWithIgnoreCase(line, "protocol:")) {
            if (!std.ascii.eqlIgnoreCase(std.mem.trim(u8, line[9..], " \t"), "limine")) return false;
            protocols += 1;
        } else if (selected and std.ascii.startsWithIgnoreCase(line, "path:")) {
            if (!std.ascii.eqlIgnoreCase(std.mem.trim(u8, line[5..], " \t"), expected)) return false;
            paths += 1;
            found = true;
        }
    }
    return found and (!selected or (paths == 1 and protocols == 1));
}
pub fn bootPlan(ctx: *const r.r4sys.Context) !BootProof {
    const allocator = ctx.allocator();
    const document = try read(ctx, allocator, "/boot/r4os-installation.json", 64 * 1024);
    defer allocator.free(document);
    const config = try read(ctx, allocator, "/boot/limine.conf", 16 * 1024);
    defer allocator.free(config);
    const Wire = struct { schema: u32, logicalSectorBytes: u32, partitions: struct { BOOT: struct { partitionGuid: []const u8 } }, bootFiles: []const []const u8 };
    const parsed = try std.json.parseFromSlice(Wire, allocator, document, .{ .ignore_unknown_fields = true });
    defer parsed.deinit();
    const value = parsed.value;
    if (value.schema != 1 or value.logicalSectorBytes != 512 or !kernelConfigMatches(config, value.partitions.BOOT.partitionGuid)) return error.BootPlanUnsupported;
    var kernel_found = false;
    for (value.bootFiles) |path| if (std.ascii.eqlIgnoreCase(path, "boot/r4os.elf")) {
        kernel_found = true;
    };
    if (!kernel_found) return error.BootPlanUnsupported;
    const identity = try inspect(ctx, kernel_target);
    if (identity.kind != .kernel or !std.ascii.eqlIgnoreCase(identity.nameText(), "KERNEL")) return error.BootPlanUnsupported;
    var result = BootProof{ .boot_guid = undefined, .configuration_sha256 = sha(config), .manifest_sha256 = sha(document) };
    @memcpy(&result.boot_guid, value.partitions.BOOT.partitionGuid);
    return result;
}
