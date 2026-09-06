const std = @import("std");
const r4os = @import("r4os");
pub const package = @import("package.zig");
pub const resident = @import("resident.zig");
pub const source = @import("system_source.zig");
pub const Preview = struct {
    state: enum { missing, unchecked, manifest, invalid, verified } = .missing,
    version: [33]u8 = .{0} ** 33,
    digest: [32]u8 = .{0} ** 32,
    bytes: u64 = 0,
};
pub const Session = struct {
    sys: *const r4os.r4sys.Context,
    dev: *const r4os.r4dev.Context,
    pool: resident.Pool,
    arena: std.heap.ArenaAllocator,
    arena_live: bool = false,
    original_digest: [32]u8 = .{0} ** 32,
    prepared: ?package.Prepared = null,
    tree: ?source.Tree = null,
    target: ?source.Target = null,

    pub fn init(self: *Session, sys: *const r4os.r4sys.Context, dev: *const r4os.r4dev.Context, pump: resident.Pump) void {
        self.* = .{ .sys = sys, .dev = dev, .pool = .{ .sys = sys, .dev = dev, .pump = pump }, .arena = undefined };
        self.pool.ram_bytes = @import("memory_budget.zig").capacity(dev) catch 0;
        self.pool.observe();
        self.pool.baseline_used = self.pool.observed_peak;
        self.arena = std.heap.ArenaAllocator.init(self.pool.allocator());
        self.arena_live = true;
    }
    pub fn deinit(self: *Session) bool {
        self.pool.observe();
        var measurement: [192]u8 = undefined;
        self.sys.write(std.fmt.bufPrint(&measurement, "[RECOVERYRAM] baseline_used={d} observed_used_peak={d} pinned_peak={d}\r\n", .{ self.pool.baseline_used, self.pool.observed_peak, self.pool.peak }) catch "");
        // The preparation arena owns the complete decoder/manifest/tree/plan
        // lifetime. Nothing borrowed by a write plan outlives this arena.
        if (self.arena_live) {
            self.arena_live = false;
            self.arena.deinit();
        }
        return self.pool.deinit();
    }
    pub fn read(self: *Session, path: [*:0]const u8) ![]const u8 {
        const info = self.sys.fileInfo(path) orelse return error.PackageMissing;
        if (info.size < 22 or info.size > package.max_archive_bytes) return error.ArchiveSize;
        const bytes = try self.arena.allocator().alloc(u8, @intCast(info.size));
        var done: usize = 0;
        while (done < bytes.len) {
            const amount = @min(bytes.len - done, 128 * 1024);
            if (self.sys.fileReadAt(path, @intCast(done), bytes[done..][0..amount]) != amount) return error.PackageRead;
            done += amount;
            try self.pool.pump.run("Reading local package", done, bytes.len);
        }
        const after = self.sys.fileInfo(path) orelse return error.PackageRead;
        if (after.size != info.size) return error.SourceChanged;
        return bytes;
    }
    pub fn digest(self: *Session, bytes: []const u8) ![32]u8 {
        var hash = std.crypto.hash.sha2.Sha256.init(.{});
        var at: usize = 0;
        while (at < bytes.len) {
            const count = @min(bytes.len - at, 128 * 1024);
            hash.update(bytes[at..][0..count]);
            at += count;
            try self.pool.pump.run("Checking original ZIP", at, bytes.len);
        }
        return hash.finalResult();
    }
    pub fn describe(self: *Session, path: [*:0]const u8, kind: package.Kind) !Preview {
        const bytes = try self.read(path);
        const version = try package.peek(self.arena.allocator(), r4os.zip.Context{ .dev = self.dev }, bytes, kind, self.pool.pump);
        var out = Preview{ .state = .manifest, .bytes = bytes.len, .digest = try self.digest(bytes) };
        @memcpy(out.version[0..version.len], version);
        return out;
    }
    pub fn prepare(self: *Session, path: [*:0]const u8, kind: package.Kind, expected: ?[32]u8) !void {
        const bytes = try self.read(path);
        self.original_digest = try self.digest(bytes);
        if (expected) |wanted| if (!std.mem.eql(u8, &wanted, &self.original_digest)) return error.SourceChanged;
        self.prepared = try package.prepare(self.arena.allocator(), r4os.zip.Context{ .dev = self.dev }, bytes, kind, self.pool.pump);
        try @import("memory_budget.zig").require(self.pool.ram_bytes, self.prepared.?.recovery.minimumRamBytes);
        if (self.prepared.?.system) |system| self.tree = try source.Tree.read(self.arena.allocator(), self.prepared.?.archive.get("disk.img").?, system.releaseVersion, self.pool.pump);
    }
    pub fn targetSystem(self: *Session, first: u64, sectors: u64, serial: u64) !void {
        self.target = try self.tree.?.prepareTarget(self.arena.allocator(), first, sectors, serial, self.pool.pump);
    }
    pub fn failureMessage(self: *const Session, buffer: []u8, err: anyerror) []const u8 {
        if (err == error.InsufficientRam) if (self.prepared) |prepared| {
            const mb = 1024 * 1024;
            return std.fmt.bufPrint(buffer, "Not enough RAM for this release.\nDetected OS RAM: {d} MB\nRequired OS RAM: {d} MB\nNo disk changes made.", .{
                self.pool.ram_bytes / mb,
                std.math.divCeil(u64, prepared.recovery.minimumRamBytes, mb) catch 0,
            }) catch message(err);
        };
        return message(err);
    }
};
pub fn message(err: anyerror) []const u8 {
    return switch (err) {
        error.OutOfMemory => "Not enough RAM to prepare this package. No disk changes made.",
        error.InsufficientRam => "Not enough RAM for this release. No disk changes made. See the release memory requirements.",
        error.MemoryMap => "The available RAM could not be determined. No disk changes made.",
        error.Cancelled => "Preparation cancelled. No disk changes made.",
        error.PackageMissing => "No ZIP at the fixed Recovery cache path. Download a release first.",
        error.PackageRead => "Could not read the complete cached ZIP. Check the source partition.",
        error.SourceChanged => "The cached ZIP changed. Return to source selection and check it again.",
        error.Unavailable => "The ZIP protocol is unavailable in this Recovery build.",
        error.ArchiveSize, error.PayloadSize, error.Limit => "This package exceeds the supported package size or entry limit.",
        error.NoSpace, error.VolumeTooSmall, error.Geometry, error.TargetGeometry => "The SYSTEM contents and required NTFS metadata do not fit this target.",
        error.IncompatiblePackage, error.PackageFormat, error.AssetMismatch, error.RecoveryPairMismatch => "This is not a compatible release package for this action.",
        else => "The package failed validation. Check the ZIP format, manifest, file hashes and images.",
    };
}
