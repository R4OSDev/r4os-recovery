const std = @import("std");
const r4os = @import("r4os");
const github = @import("github.zig");
const cache = @import("cache.zig");
const packages = @import("package_session.zig");
const time = r4os.time_contract;
// WebTransport already supplies User-Agent and identity encoding. Its shared
// header serialization uses LF; the HTTP owner produces CRLF on the wire.
const headers = "";
pub const Client = struct {
    sys: *const r4os.r4sys.Context,
    dev: *const r4os.r4dev.Context,
    web: r4os.WebTransport,
    kind: github.Kind,
    profile: github.Profile = .slim,
    pump: packages.resident.Pump = .{},
    last_network_error: ?r4os.app_web.Error = null,
    sink_error: bool = false,
    cancelled: bool = false,

    fn progress(raw: ?*anyopaque, done: u64, total: u64) bool {
        const self: *Client = @ptrCast(@alignCast(raw.?));
        self.pump.run("Downloading release package", done, total) catch {
            self.cancelled = true;
            return false;
        };
        return true;
    }
    fn apiProgress(raw: ?*anyopaque) callconv(.c) bool {
        const self: *Client = @ptrCast(@alignCast(raw.?));
        self.pump.run("Checking GitHub release", 0, 1) catch {
            self.cancelled = true;
            return false;
        };
        return true;
    }
    fn write(raw: ?*anyopaque, offset: u64, bytes: []const u8) bool {
        const self: *Client = @ptrCast(@alignCast(raw.?));
        if (self.sys.fileStreamWrite(cache.paths(self.kind).part, offset, bytes, 0) != bytes.len) {
            self.sink_error = true;
            return false;
        }
        return true;
    }
    pub fn run(self: *Client) !packages.Preview {
        var arena = std.heap.ArenaAllocator.init(self.sys.allocator());
        defer arena.deinit();
        const allocator = arena.allocator();
        const transaction = try allocator.create(cache.Cache);
        transaction.* = .{ .sys = self.sys, .kind = self.kind, .pump = self.pump };
        try transaction.lock();
        defer transaction.unlock();
        try transaction.recover();
        if (!self.web.available()) return error.NetworkUnavailable;
        const scratch = try allocator.alloc(u8, r4os.app_web.tls_scratch_bytes);
        const raw = try allocator.alloc(u8, github.max_metadata_bytes + r4os.http.max_header_bytes);
        const body = try allocator.alloc(u8, github.max_metadata_bytes);
        const metadata = self.web.fetch(github.api(self.kind), raw, body, scratch, .{
            .headers = headers ++ "Accept: application/vnd.github+json\n",
            .timeout = time.timeoutFinite(time.durationFromNanoseconds(30_000_000_000)),
            .progress = apiProgress,
            .progress_context = self,
            .target_authorizer = github.allowTarget,
        });
        const response = switch (metadata) {
            .failure => |err| {
                self.last_network_error = err;
                return if (self.cancelled) error.Cancelled else error.NetworkDownload;
            },
            .response => |value| value,
        };
        if (response.status == 404) return error.NoCompatibleRelease;
        if (response.status == 403 or response.status == 429) return error.GitHubRateLimit;
        if (response.status != 200 or !response.secure) return error.ReleaseMetadata;
        const asset = try github.select(allocator, response.body, self.kind, self.profile);
        return self.receive(transaction, asset, null);
    }
    /// Product callers always use the bound GitHub asset URL. The bounded
    /// guest witness may substitute only its host-side QEMU fixture server.
    pub fn receive(self: *Client, transaction: *cache.Cache, asset: github.Asset, fixture_url: ?[]const u8) !packages.Preview {
        if (asset.kind != self.kind or asset.profile != self.profile) return error.AssetMismatch;
        if (fixture_url) |url| if (!allowFixture(null, url)) return error.ReleaseMetadata;
        var arena = std.heap.ArenaAllocator.init(self.sys.allocator());
        defer arena.deinit();
        const allocator = arena.allocator();
        const scratch = try allocator.alloc(u8, r4os.app_web.tls_scratch_bytes);
        const raw = try allocator.alloc(u8, r4os.http.max_header_bytes);
        try transaction.beginDownload(asset.bytes);
        const path = cache.paths(self.kind).part;
        defer _ = self.sys.fileStreamAbort(path);
        const io = try allocator.alloc(u8, 64 * 1024);
        const downloaded = self.web.download(fixture_url orelse asset.url, raw, io, scratch, .{ .context = self, .write_fn = write }, .{
            .headers = headers ++ "Accept: application/octet-stream\n",
            .expected_size = asset.bytes,
            .timeout = time.timeoutFinite(time.durationFromNanoseconds(900_000_000_000)),
            .progress = progress,
            .progress_context = self,
            .target_authorizer = if (fixture_url != null) allowFixture else github.allowTarget,
        });
        const result = switch (downloaded) {
            .failure => |err| {
                self.last_network_error = err;
                return if (self.cancelled) error.Cancelled else if (self.sink_error) error.CacheIo else error.NetworkDownload;
            },
            .range_not_satisfiable => return error.IncompleteDownload,
            .response => |value| value,
        };
        if ((result.status != 200 and result.status != 206) or (fixture_url == null and !result.secure) or result.total_size != asset.bytes or result.transferred != asset.bytes) return error.IncompleteDownload;
        if (self.sys.fileStreamFinish(path, asset.bytes, 0) != 0) return error.CacheIo;
        const session = try allocator.create(packages.Session);
        session.init(self.sys, self.dev, self.pump);
        defer {
            if (!session.deinit()) self.sys.write("[RECOVERYDOWNLOAD] cleanup=RETAINED\r\n");
        }
        try session.prepare(path, self.kind, asset.sha256);
        if (!github.matches(asset, &session.prepared.?)) return error.AssetMismatch;
        var checksum = r4os.system_update_recovery.checksum_seed;
        const original = session.prepared.?.archive.original;
        var at: usize = 0;
        while (at < original.len) {
            const amount = @min(128 * 1024, original.len - at);
            checksum = r4os.system_update_recovery.checksumUpdate(checksum, original[at..][0..amount]);
            at += amount;
            try self.pump.run("Preparing cache replacement", at, original.len);
        }
        try transaction.activate(.{ .bytes = original.len, .checksum = checksum, .sha256 = session.original_digest });
        var preview = packages.Preview{ .state = .verified, .bytes = asset.bytes, .digest = session.original_digest };
        @memcpy(preview.version[0..asset.version.len], asset.version);
        return preview;
    }
};
pub fn allowFixture(_: ?*anyopaque, raw: []const u8) bool {
    const url = switch (r4os.http.parseUrl(raw)) {
        .value => |v| v,
        else => return false,
    };
    return url.scheme == .http and std.mem.eql(u8, url.host, "10.0.2.2") and url.port >= 1024;
}
pub fn recover(sys: *const r4os.r4sys.Context, kind: github.Kind, pump: packages.resident.Pump) !void {
    const p = cache.paths(kind);
    var pending = false;
    for ([_][*:0]const u8{ p.journal, p.journal_stage, p.backup }) |path| {
        var info = r4os.abi.FileInfo{};
        const rc = sys.fileInfoRaw(path, &info);
        if (rc < 0) return error.CacheIo;
        pending = pending or (rc > 0 and info.exists != 0);
    }
    if (!pending) return;
    const value = try sys.allocator().create(cache.Cache);
    defer sys.allocator().destroy(value);
    value.* = .{ .sys = sys, .kind = kind, .pump = pump };
    try value.lock();
    defer value.unlock();
    try value.recover();
}
pub fn message(err: anyerror) []const u8 {
    return switch (err) {
        error.NetworkUnavailable, error.NetworkDownload => "Download failed. Check the network, clock and certificates. The local ZIP remains available.",
        error.GitHubRateLimit => "GitHub request limit reached. Try again later or use the cached ZIP.",
        error.NoCompatibleRelease => "No current compatible release for this channel and profile. You can still use a local ZIP.",
        error.ReleaseMetadata, error.IncompleteDownload => "GitHub returned an unsuitable or incomplete package. No new ZIP was activated.",
        error.CacheUnavailable => "The boot Recovery partition is not available for downloads.",
        error.CacheNoSpace => "Not enough free space on RECOVERY for the new ZIP while keeping the current ZIP.",
        error.CacheBusy => "Another operation is using this release cache. Try again when it finishes.",
        error.CacheIo => "The Recovery cache could not be written or flushed. A pending exchange is checked again on the next start.",
        error.CacheConflict, error.CacheJournal => "The cache transaction is inconsistent. Existing files were retained; check INSTALL from Terminal.",
        error.Cancelled => "Download cancelled. A completed cache exchange may be finished on the next start.",
        error.OutOfMemory => "Not enough RAM to validate this download. The current ZIP was retained.",
        else => "The downloaded package failed validation. The current ZIP was retained.",
    };
}
