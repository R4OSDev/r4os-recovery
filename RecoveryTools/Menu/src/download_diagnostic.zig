// Bounded automated guest witness. It can only download to INSTALL and never
// calls an installation writer. Controlled HTTP is limited to QEMU's host.
const std = @import("std");
const r4os = @import("r4os");
const github = @import("github.zig");
const download = @import("download.zig");
const cache = @import("cache.zig");
const time = r4os.time_contract;
const Hook = struct {
    sys: *const r4os.r4sys.Context,
    stop_on: []const u8 = "",
    last_phase: []const u8 = "",
    fn progress(raw: ?*anyopaque, phase: []const u8, _: u64, _: u64) bool {
        const self: *Hook = @ptrCast(@alignCast(raw.?));
        if (!std.mem.eql(u8, self.last_phase, phase)) {
            self.last_phase = phase;
            var line: [144]u8 = undefined;
            self.sys.write(std.fmt.bufPrint(&line, "[DOWNLOADSMOKE] tick={d} phase={s}\r\n", .{ self.sys.ticks(), phase }) catch "");
        }
        if (self.stop_on.len != 0 and std.mem.eql(u8, self.stop_on, phase)) {
            if (self.sys.fileWrite("C:\\TEMP\\DOWNLOAD.RDY", phase) != phase.len) return false;
            const end = self.sys.ticks() + self.sys.ticksFromMilliseconds(120000);
            while (self.sys.ticks() < end and !self.sys.programShouldClose()) self.sys.sleepTicks(self.sys.ticksFromMilliseconds(20));
            return false;
        }
        self.sys.taskYield();
        return !self.sys.programShouldClose();
    }
};
const SmallSink = struct {
    bytes: [4096]u8 = undefined,
    count: usize = 0,
    fn write(raw: ?*anyopaque, offset: u64, bytes: []const u8) bool {
        const self: *SmallSink = @ptrCast(@alignCast(raw.?));
        if (offset != self.count or self.count + bytes.len > self.bytes.len) return false;
        @memcpy(self.bytes[self.count..][0..bytes.len], bytes);
        self.count += bytes.len;
        return true;
    }
};
pub fn run(app: *r4os.App, args: []const u8) i32 {
    const sys = app.system();
    execute(app, args) catch |err| {
        var line: [128]u8 = undefined;
        sys.write(std.fmt.bufPrint(&line, "[DOWNLOADSMOKE] error={s} target_writes=0\r\n", .{@errorName(err)}) catch "");
        return 1;
    };
    sys.write("[DOWNLOADSMOKE] result=OK target_writes=0\r\n");
    return 0;
}
fn execute(app: *r4os.App, args: []const u8) !void {
    const sys = app.system();
    const dev = app.devicesLowLevel() orelse return error.Unavailable;
    var web = app.web() orelse return error.Unavailable;
    var arena = std.heap.ArenaAllocator.init(sys.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();
    var words = std.mem.tokenizeScalar(u8, args, ' ');
    const mode = words.next() orelse return error.Usage;
    if (std.mem.eql(u8, mode, "FAT") or std.mem.eql(u8, mode, "LFN")) {
        try fatFiles(app, allocator, std.mem.eql(u8, mode, "FAT"));
        return;
    }
    const kind: github.Kind = if (std.mem.eql(u8, mode, "R4OS")) .r4os else .recovery;
    var hook = Hook{ .sys = &sys };
    const pump = @import("resident.zig").Pump{ .context = &hook, .function = Hook.progress };
    const transaction = try allocator.create(cache.Cache);
    transaction.* = .{ .sys = &sys, .kind = kind, .pump = pump };
    if (std.mem.eql(u8, mode, "CHECK") or std.mem.eql(u8, mode, "CHECKR4OS")) {
        if (std.mem.eql(u8, mode, "CHECKR4OS")) transaction.kind = .r4os;
        try transaction.lock();
        defer transaction.unlock();
        try transaction.recover();
        const p = cache.paths(transaction.kind);
        const value = (try transaction.fingerprint(p.zip)) orelse return error.PackageMissing;
        var line: [256]u8 = undefined;
        const sha = std.fmt.bytesToHex(value.sha256, .lower);
        sys.write(try std.fmt.bufPrint(&line, "[DOWNLOADCACHE] kind={s} bytes={d} sha256={s} part={d} txn={d} backup={d}\r\n", .{
            @tagName(transaction.kind), value.bytes, sha, @intFromBool(try transaction.info(p.part) != null), @intFromBool(try transaction.info(p.journal) != null), @intFromBool(try transaction.info(p.backup) != null),
        }));
        return;
    }
    if (std.mem.eql(u8, mode, "NOSPACE")) {
        try transaction.lock();
        defer transaction.unlock();
        transaction.beginDownload(@import("package.zig").max_archive_bytes) catch |err| {
            if (err != error.CacheNoSpace) return err;
            sys.write("[DOWNLOADSMOKE] space=REJECTED\r\n");
            return;
        };
        return error.ExpectedNoSpace;
    }
    const raw = try allocator.alloc(u8, 256 * 1024);
    const body = try allocator.alloc(u8, 256 * 1024);
    const scratch = try allocator.alloc(u8, r4os.app_web.tls_scratch_bytes);
    if (std.mem.eql(u8, mode, "LIVE")) {
        const result = web.fetch(github.api(.r4os), raw, body, scratch, .{ .target_authorizer = github.allowTarget, .timeout = time.timeoutFinite(time.durationFromNanoseconds(30_000_000_000)) });
        switch (result) {
            .failure => |err| {
                sys.write(@tagName(err));
                return error.LiveApi;
            },
            .response => |value| {
                if (value.status != 200 or !value.secure) return error.LiveApi;
            },
        }
        sys.write("[DOWNLOADLIVE] api=HTTPS200\r\n");
        var sink = SmallSink{};
        const transfer = web.download("https://github.com/R4OSDev/r4os-distribution/releases/download/v0.73.25/SHA256SUMS.txt", raw[0..r4os.http.max_header_bytes], body[0 .. 64 * 1024], scratch, .{ .context = &sink, .write_fn = SmallSink.write }, .{
            .expected_size = 282,
            .target_authorizer = github.allowTarget,
            .timeout = time.timeoutFinite(time.durationFromNanoseconds(60_000_000_000)),
        });
        const value = switch (transfer) {
            .failure => |err| {
                sys.write(@tagName(err));
                return error.LiveDownload;
            },
            .response => |v| v,
            else => return error.LiveDownload,
        };
        var digest: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(sink.bytes[0..sink.count], &digest, .{});
        const text = std.fmt.bytesToHex(digest, .lower);
        if (!value.secure or value.redirects == 0 or sink.count != 282 or !std.mem.eql(u8, &text, "e3171e3f3d0eafe0d69bf4c689f412de4b836f873123a5df0b1a5432d242494a")) return error.LiveDigest;
        sys.write("[DOWNLOADLIVE] asset=HTTPS200 redirect=VERIFIED sha256=OK bytes=282 cache_writes=0\r\n");
        return;
    }
    if (!std.mem.eql(u8, mode, "FIXTURE") and !std.mem.eql(u8, mode, "CUT") and !std.mem.eql(u8, mode, "R4OS")) return error.Usage;
    const base = words.next() orelse return error.Usage;
    const scenario = words.next() orelse return error.Usage;
    if (words.next() != null or !download.allowFixture(null, base)) return error.Usage;
    if (std.mem.eql(u8, mode, "CUT")) {
        hook.stop_on = if (std.mem.eql(u8, scenario, "journal")) "Cache journal durable" else if (std.mem.eql(u8, scenario, "publish")) "Cache ZIP published" else if (std.mem.eql(u8, scenario, "cleanup")) "Cache backup removed" else return error.Usage;
    }
    const name = if (hook.stop_on.len != 0) "good" else scenario;
    var url: [256]u8 = undefined;
    const metadata_url = try std.fmt.bufPrint(&url, "{s}/meta-{s}.json", .{ base, name });
    const result = web.fetch(metadata_url, raw, body, scratch, .{ .target_authorizer = download.allowFixture });
    const response = switch (result) {
        .response => |v| v,
        .failure => |err| {
            sys.write(@tagName(err));
            return error.FixtureNetwork;
        },
    };
    if (response.status != 200) return error.FixtureNetwork;
    const asset = try github.select(allocator, response.body, kind, .slim);
    try transaction.lock();
    defer transaction.unlock();
    var client = download.Client{ .sys = &sys, .dev = &dev, .web = web, .kind = kind, .pump = pump };
    const source = try std.fmt.bufPrint(&url, "{s}/{s}.zip", .{ base, name });
    const preview = client.receive(transaction, asset, source) catch |err| {
        if (client.last_network_error) |network| {
            sys.write("[DOWNLOADSMOKE] network=");
            sys.println(@tagName(network));
        }
        return err;
    };
    var line: [144]u8 = undefined;
    sys.write(try std.fmt.bufPrint(&line, "[DOWNLOADSMOKE] activated={s} bytes={d}\r\n", .{ std.mem.sliceTo(&preview.version, 0), preview.bytes }));
}

fn fatFiles(app: *r4os.App, allocator: std.mem.Allocator, large: bool) !void {
    const sys = app.system();
    const before = sys.driveInfo('R' - 'A') orelse return error.CacheUnavailable;
    if (before.cluster_bytes != 4096) return error.FixtureGeometry;
    var path: [64]u8 = undefined;
    // Enough short entries to reuse deleted directory slots on both sides
    // of the synthetic orphan LFN's sector boundary.
    for (0..32) |index| {
        const name = try std.fmt.bufPrintZ(&path, "R:\\INSTALL\\LFN{d:0>2}.TMP", .{index});
        if (sys.fileInfo(name) != null or sys.fileWrite(name, "LFN slot witness") != 16) return error.FatDirectory;
    }
    for (0..32) |index| {
        const name = try std.fmt.bufPrintZ(&path, "R:\\INSTALL\\LFN{d:0>2}.TMP", .{index});
        var bytes: [16]u8 = undefined;
        if (sys.fileRead(name, &bytes) != bytes.len or !std.mem.eql(u8, &bytes, "LFN slot witness") or sys.fileDelete(name) < 0) return error.FatDirectory;
    }
    if (!large) {
        sys.write("[DOWNLOADFAT] orphan_slots=REUSED verified_files=32\r\n");
        return;
    }
    const name = "R:\\INSTALL\\FATCHECK.TMP";
    const total = 4100 * 4096;
    const io = try allocator.alloc(u8, 65536);
    if (sys.fileInfo(name) != null or sys.fileStreamBegin(name, r4os.abi.file_stream_open_create) != 0) return error.FatWrite;
    defer _ = sys.fileStreamAbort(name);
    var at: usize = 0;
    while (at < total) {
        const count = @min(io.len, total - at);
        for (io[0..count], 0..) |*byte, i| byte.* = @intCast(((at + i) / 4096) % 251);
        if (sys.fileStreamWrite(name, at, io[0..count], 0) != count) return error.FatWrite;
        at += count;
        sys.taskYield();
    }
    if (sys.fileStreamFinish(name, total, 0) != 0) return error.FatWrite;
    // First read is deliberately a cold random offset beyond cluster 4096.
    const offset = 4097 * 4096;
    if (sys.fileReadAt(name, offset, io[0..4096]) != 4096) return error.FatRead;
    for (io[0..4096]) |byte| if (byte != 4097 % 251) return error.FatRead;
    @memset(io[0..4096], 0xea);
    const resources = app.resources();
    var request = switch (resources.asyncWriteAt(.{ .ptr = name, .len = name.len }, offset, io[0..4096], 0)) {
        .request => |value| value,
        else => return error.FatWrite,
    };
    // Keep borrowed bytes alive through the existing bounded backend I/O.
    const result = request.wait(time.timeoutForever());
    if (request.close() != 0) return error.FatWrite;
    switch (result) {
        .completed => |info| if (info.result != 4096 or info.processed_bytes != 4096) return error.FatWrite,
        else => return error.FatWrite,
    }
    if (sys.fileReadAt(name, offset, io[0..4096]) != 4096) return error.FatRead;
    for (io[0..4096]) |byte| if (byte != 0xea) return error.FatRead;
    if (sys.fileReadAt(name, 4096 * 4096, io[0..4096]) != 4096) return error.FatRead;
    for (io[0..4096]) |byte| if (byte != 4096 % 251) return error.FatRead;
    if (sys.fileDelete(name) < 0) return error.FatDelete;
    const after = sys.driveInfo('R' - 'A') orelse return error.CacheUnavailable;
    if (after.free_bytes != before.free_bytes) return error.FatLeakedClusters;
    sys.write("[DOWNLOADFAT] clusters=4100 cold_random_read=OK random_write=OK adjacent_data=UNCHANGED free_space=RESTORED\r\n");
}
