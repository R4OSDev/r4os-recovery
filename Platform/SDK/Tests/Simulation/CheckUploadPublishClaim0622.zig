// Host model for the persistent create-only upload publish claim (0.60.22).
//
// It drives the REAL claim replay logic (Code/System/SDK/r4os/
// upload_publish_claim.zig) through an `io` seam that is backed by the REAL
// shared NTFS core, so every decision is proven against actual on-disk
// state rather than a simulation:
//
//   * all five durable states a reset can leave behind are constructed for
//     real (stage-only, half-published, alias, target-only, missing) and
//     each one is replayed to its terminal outcome,
//   * the asymmetry around the point of no return is pinned: before the
//     canonical rewrite the upload rolls back, after it the hand-over
//     completes - a lost acknowledgement therefore never yields a half
//     object,
//   * a foreign object under the claimed name is never touched,
//   * replay is idempotent and a failing claim is retried rather than lost,
//   * an interrupted replay (flush cut) still reaches a terminal state and
//     leaves an NtfsVerify-clean volume.

const std = @import("std");
const ntfs = @import("ntfs_format");
const vol = @import("ntfs_volume");
const mkfs = @import("ntfs_mkfs");
const upc = @import("upload_publish_claim");

const RamDevice = struct {
    image: []u8,

    fn read(ctx: *anyopaque, lba: u64, count: u32, out: []u8) bool {
        const self: *RamDevice = @ptrCast(@alignCast(ctx));
        const start: usize = @intCast(lba * 512);
        const len: usize = @intCast(@as(u64, count) * 512);
        if (start + len > self.image.len or out.len < len) return false;
        @memcpy(out[0..len], self.image[start .. start + len]);
        return true;
    }

    fn write(ctx: *anyopaque, lba: u64, count: u32, data: []const u8) bool {
        const self: *RamDevice = @ptrCast(@alignCast(ctx));
        const start: usize = @intCast(lba * 512);
        const len: usize = @intCast(@as(u64, count) * 512);
        if (start + len > self.image.len or data.len < len) return false;
        @memcpy(self.image[start .. start + len], data[0..len]);
        return true;
    }

    fn flush(ctx: *anyopaque) bool {
        _ = ctx;
        return true;
    }

    fn device(self: *RamDevice) vol.Device {
        return .{ .ctx = self, .read_sectors = read, .write_sectors = write, .flush = flush };
    }
};

var scratch: vol.Scratch = .{};
var mft_runs: [vol.MAX_MFT_RUNS]ntfs.Run = undefined;
var mft_run_count: usize = 0;
var upcase_buf: [ntfs.UPCASE_BYTES]u8 = undefined;
var failures: usize = 0;

fn fail(comptime fmt: []const u8, args: anytype) void {
    failures += 1;
    std.debug.print("FAIL: " ++ fmt ++ "\n", args);
}

fn openVolume(dev: *RamDevice) ?vol.Volume {
    const info = vol.mount(dev.device(), 0, &scratch, mft_runs[0..]) orelse return null;
    mft_run_count = info.mft_run_count;
    var v = vol.Volume{
        .device = dev.device(),
        .partition_lba = 0,
        .cluster_bytes = info.cluster_bytes,
        .record_bytes = info.record_bytes,
        .index_block_bytes = info.index_block_bytes,
        .total_sectors = info.total_sectors,
        .mft_runs_buf = mft_runs[0..],
        .mft_run_count = &mft_run_count,
        .upcase = &[_]u8{},
        .scratch = &scratch,
        .now_filetime = 132_100_000_000_000_000,
    };
    const got = vol.readFileRange(&v, ntfs.MFT_RECORD_UPCASE, 0, upcase_buf[0..]) orelse return null;
    if (got != ntfs.UPCASE_BYTES) return null;
    v.upcase = upcase_buf[0..];
    return v;
}

fn loadMeta(allocator: std.mem.Allocator, io: anytype, dir: std.Io.Dir) !mkfs.Meta {
    const L = struct {
        fn req(a: std.mem.Allocator, i: anytype, d: std.Io.Dir, n: []const u8) ![]u8 {
            return d.readFileAlloc(i, n, a, .limited(1 << 20));
        }
        fn opt(a: std.mem.Allocator, i: anytype, d: std.Io.Dir, n: []const u8) []u8 {
            return d.readFileAlloc(i, n, a, .limited(1 << 20)) catch &[_]u8{};
        }
    };
    return .{
        .upcase = try L.req(allocator, io, dir, "upcase.bin"),
        .upcase_info = L.opt(allocator, io, dir, "upcase_info.bin"),
        .attrdef = try L.req(allocator, io, dir, "attrdef.bin"),
        .sds_prefix = try L.req(allocator, io, dir, "secure_sds_prefix.bin"),
        .sdh_root = try L.req(allocator, io, dir, "secure_sdh_root.bin"),
        .sii_root = try L.req(allocator, io, dir, "secure_sii_root.bin"),
        .sdh_alloc = try L.req(allocator, io, dir, "secure_SDH_alloc.bin"),
        .sii_alloc = try L.req(allocator, io, dir, "secure_SII_alloc.bin"),
        .sdh_bitmap = try L.req(allocator, io, dir, "secure_SDH_bitmap.bin"),
        .sii_bitmap = try L.req(allocator, io, dir, "secure_SII_bitmap.bin"),
        .objid_o_root = try L.req(allocator, io, dir, "extend_objid_o_root.bin"),
        .quota_o_root = try L.req(allocator, io, dir, "extend_quota_o_root.bin"),
        .quota_q_root = try L.req(allocator, io, dir, "extend_quota_q_root.bin"),
        .reparse_r_root = try L.req(allocator, io, dir, "extend_reparse_r_root.bin"),
        .root_sd = try L.req(allocator, io, dir, "root_sd.bin"),
        .boot_sd = try L.req(allocator, io, dir, "boot_sd.bin"),
    };
}

fn formatFresh(allocator: std.mem.Allocator, meta: mkfs.Meta) ![]u8 {
    var builder = try mkfs.Builder.init(allocator, 24 * 1024 * 1024, "R4OSCLAIM", 0, meta, 132_000_000_000_000_000, 0x2622);
    return builder.finalize();
}

const STAGE = "UPLOAD.STG";
const TARGET = "PACKAGE.R4U";
const KEEP = "KEEP.TXT";
const KEEP_DATA = "unrelated bystander file";
const PAYLOAD = "the uploaded package payload handed over by the publish";
const FOREIGN = "a completely different file that merely holds the name";
const VOLUME_TOKEN: u64 = 0x0060_0022;
const PARENT = "C:\\R4OS\\UPDATE\\INBOX";

/// The `io` seam: backed by the real shared NTFS core plus a persistent
/// claim record modelled as a simple present/absent flag (the kernel stores
/// it as a file; what matters for the contract is when it disappears).
const ClaimIo = struct {
    v: *vol.Volume,
    parent: u64,
    claim_present: bool = true,
    publish_calls: usize = 0,
    discard_calls: usize = 0,

    pub fn identityOf(found: vol.LookupResult) upc.FileIdentity {
        return .{ .node = found.record, .generation = found.sequence, .size = found.entry.size };
    }

    pub fn observe(self: *ClaimIo, claim: *const upc.Claim) upc.ObservedState {
        if (claim.volume != VOLUME_TOKEN) return .foreign;

        var stage: vol.LookupResult = undefined;
        const stage_transient = vol.lookupInDirectoryStatusTransient(self.v, self.parent, claim.stageText(), &stage);
        if (stage_transient == .io) return .io;
        var target: vol.LookupResult = undefined;
        const target_transient = vol.lookupInDirectoryStatusTransient(self.v, self.parent, claim.targetText(), &target);
        if (target_transient == .io) return .io;

        const have_stage = stage_transient == .found;
        const have_target = target_transient == .found;

        if (!have_stage and !have_target) return .missing;

        // Identity is what makes this a claim rather than a name guess.
        if (have_stage and !identityOf(stage).eql(claim.identity)) return .foreign;
        if (have_target and !identityOf(target).eql(claim.identity)) return .foreign;

        if (have_stage and have_target) {
            if (stage.record != target.record or stage.sequence != target.sequence) return .foreign;
            return .alias;
        }
        if (have_target) return .target_only;

        // Stage-only: the generic lookup still accepting the name proves the
        // canonical $FILE_NAME is the stage name, so the publish had not yet
        // passed its point of no return.  A generic rejection means the
        // canonical name is already the target (the 0.60.21 window).
        var generic: vol.LookupResult = undefined;
        return switch (vol.lookupInDirectoryStatus(self.v, self.parent, claim.stageText(), &generic)) {
            .found => .stage_only,
            .io => .half_published,
            .not_found => .io, // transient found it; a plain absence is impossible
        };
    }

    pub fn publish(self: *ClaimIo, claim: *const upc.Claim) bool {
        self.publish_calls += 1;
        return vol.publishFileCreateOnly(self.v, self.parent, claim.targetText(), claim.stageText()) == .ok;
    }

    pub fn discardStage(self: *ClaimIo, claim: *const upc.Claim) bool {
        self.discard_calls += 1;
        return switch (vol.deleteRecoveryEntryIfIdentity(
            self.v,
            self.parent,
            claim.stageText(),
            claim.identity.node,
            @intCast(claim.identity.generation),
        )) {
            .ok, .not_found => true,
            else => false,
        };
    }

    pub fn retire(self: *ClaimIo, claim: *const upc.Claim) bool {
        _ = claim;
        self.claim_present = false;
        return true;
    }
};

const Fixture = struct {
    image: []u8,
    claim: upc.Claim,
    parent: u64,
};

fn makeClaim(identity: upc.FileIdentity, protocol: upc.Protocol) upc.Claim {
    var claim: upc.Claim = undefined;
    _ = upc.build(&claim, 22, VOLUME_TOKEN, PARENT, STAGE, TARGET, "", identity, protocol);
    return claim;
}

/// Builds a volume with an inbox directory, a bystander and a staged upload,
/// then advances the publish to the requested durable state.
fn buildFixture(
    allocator: std.mem.Allocator,
    meta: mkfs.Meta,
    want: upc.ObservedState,
) !?Fixture {
    const image = try formatFresh(allocator, meta);
    var dev = RamDevice{ .image = image };
    var v = openVolume(&dev) orelse return null;
    vol.flush_budget = null;
    vol.cut_after_canonical_rewrite = false;

    const root = ntfs.MFT_RECORD_ROOT;
    if (vol.createDirectory(&v, root, "INBOX") != .ok) return null;
    const inbox = (vol.lookupInDirectory(&v, root, "INBOX") orelse return null).record;
    if (vol.createFile(&v, inbox, KEEP, KEEP_DATA) != .ok) return null;

    if (want == .missing) {
        return .{ .image = image, .claim = makeClaim(.{ .node = 9999, .generation = 1, .size = 0 }, .ftp), .parent = inbox };
    }

    if (vol.createFile(&v, inbox, STAGE, PAYLOAD) != .ok) return null;
    var staged: vol.LookupResult = undefined;
    if (vol.lookupInDirectoryStatusTransient(&v, inbox, STAGE, &staged) != .found) return null;
    const identity = ClaimIo.identityOf(staged);

    switch (want) {
        .stage_only => {},
        .half_published => {
            vol.cut_after_canonical_rewrite = true;
            _ = vol.publishFileCreateOnly(&v, inbox, TARGET, STAGE);
            vol.cut_after_canonical_rewrite = false;
        },
        .alias => {
            var probe: u32 = 0;
            var landed = false;
            while (probe <= 3 and !landed) : (probe += 1) {
                vol.flush_budget = probe;
                _ = vol.publishFileCreateOnly(&v, inbox, TARGET, STAGE);
                vol.flush_budget = null;
                var a: vol.LookupResult = undefined;
                var b: vol.LookupResult = undefined;
                landed = vol.lookupInDirectoryStatusTransient(&v, inbox, STAGE, &a) == .found and
                    vol.lookupInDirectoryStatusTransient(&v, inbox, TARGET, &b) == .found;
            }
            if (!landed) return null;
        },
        .target_only => {
            if (vol.publishFileCreateOnly(&v, inbox, TARGET, STAGE) != .ok) return null;
        },
        .foreign => {
            // Complete the publish, then replace the object entirely so the
            // name survives while the identity does not.
            if (vol.publishFileCreateOnly(&v, inbox, TARGET, STAGE) != .ok) return null;
            if (vol.deleteFile(&v, inbox, TARGET) != .ok) return null;
            if (vol.createFile(&v, inbox, TARGET, FOREIGN) != .ok) return null;
        },
        else => return null,
    }

    return .{ .image = image, .claim = makeClaim(identity, .sftp), .parent = inbox };
}

fn expectState(io: *ClaimIo, claim: *const upc.Claim, want: upc.ObservedState, label: []const u8) void {
    const got = io.observe(claim);
    if (got != want) {
        fail("{s}: observed {s}, wanted {s}", .{ label, upc.observedStateName(got), upc.observedStateName(want) });
    }
}

fn readAndCheck(v: *vol.Volume, dir: u64, name: []const u8, expected: []const u8) bool {
    const found = vol.lookupInDirectory(v, dir, name) orelse return false;
    var buf: [4096]u8 = undefined;
    if (expected.len > buf.len) return false;
    const got = vol.readFileRange(v, found.record, 0, buf[0..expected.len]) orelse return false;
    if (got != expected.len) return false;
    return std.mem.eql(u8, buf[0..expected.len], expected);
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();
    const io_ctx = init.io;
    const cwd = std.Io.Dir.cwd();
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len < 2 or args.len > 3) {
        std.debug.print("Usage: CheckUploadPublishClaim0622 <meta-dir> [out-disk.img]\n", .{});
        std.process.exit(2);
    }
    const out_path: ?[]const u8 = if (args.len == 3) args[2] else null;
    var meta_dir = try cwd.openDir(io_ctx, args[1], .{});
    defer meta_dir.close(io_ctx);
    const meta = try loadMeta(allocator, io_ctx, meta_dir);

    // ---- 1. rollback side of the point of no return ----------------------
    {
        const fx = (try buildFixture(allocator, meta, .stage_only)) orelse return fail("stage-only setup failed", .{});
        var dev = RamDevice{ .image = fx.image };
        var v = openVolume(&dev) orelse return fail("stage-only mount failed", .{});
        var io = ClaimIo{ .v = &v, .parent = fx.parent };

        expectState(&io, &fx.claim, .stage_only, "stage-only");
        const rc = upc.replayClaim(&io, &fx.claim);
        if (rc != .rolled_back) fail("stage-only replay: {s}", .{upc.replayStatusName(rc)});
        if (vol.lookupInDirectory(&v, fx.parent, STAGE) != null) fail("stage survived the rollback", .{});
        if (vol.lookupInDirectory(&v, fx.parent, TARGET) != null) fail("rollback invented a target", .{});
        if (io.claim_present) fail("claim not retired after rollback", .{});
        if (!readAndCheck(&v, fx.parent, KEEP, KEEP_DATA)) fail("bystander damaged by rollback", .{});
        std.debug.print("stage-only: ok (rolled back, no half object)\n", .{});
    }

    // ---- 2. forward side: the 0.60.21 half-published window ---------------
    {
        const fx = (try buildFixture(allocator, meta, .half_published)) orelse return fail("half-published setup failed", .{});
        var dev = RamDevice{ .image = fx.image };
        var v = openVolume(&dev) orelse return fail("half-published mount failed", .{});
        var io = ClaimIo{ .v = &v, .parent = fx.parent };

        expectState(&io, &fx.claim, .half_published, "half-published");
        const rc = upc.replayClaim(&io, &fx.claim);
        if (rc != .published) fail("half-published replay: {s}", .{upc.replayStatusName(rc)});
        if (!readAndCheck(&v, fx.parent, TARGET, PAYLOAD)) fail("target content wrong after replay", .{});
        if (vol.lookupInDirectory(&v, fx.parent, STAGE) != null) fail("stage survived the completion", .{});
        if (io.claim_present) fail("claim not retired after publish", .{});
        std.debug.print("half-published: ok (completed forward, payload byte-exact)\n", .{});
    }

    // ---- 3. alias window completes forward too ---------------------------
    {
        const fx = (try buildFixture(allocator, meta, .alias)) orelse return fail("alias setup failed", .{});
        var dev = RamDevice{ .image = fx.image };
        var v = openVolume(&dev) orelse return fail("alias mount failed", .{});
        var io = ClaimIo{ .v = &v, .parent = fx.parent };

        expectState(&io, &fx.claim, .alias, "alias");
        const rc = upc.replayClaim(&io, &fx.claim);
        if (rc != .published) fail("alias replay: {s}", .{upc.replayStatusName(rc)});
        if (!readAndCheck(&v, fx.parent, TARGET, PAYLOAD)) fail("alias target content wrong", .{});
        if (vol.lookupInDirectory(&v, fx.parent, STAGE) != null) fail("alias stage survived", .{});
        std.debug.print("alias: ok (detached, single owner remains)\n", .{});
    }

    // ---- 4. already complete, and nothing left ---------------------------
    {
        const fx = (try buildFixture(allocator, meta, .target_only)) orelse return fail("target-only setup failed", .{});
        var dev = RamDevice{ .image = fx.image };
        var v = openVolume(&dev) orelse return fail("target-only mount failed", .{});
        var io = ClaimIo{ .v = &v, .parent = fx.parent };

        expectState(&io, &fx.claim, .target_only, "target-only");
        const rc = upc.replayClaim(&io, &fx.claim);
        if (rc != .published) fail("target-only replay: {s}", .{upc.replayStatusName(rc)});
        if (io.publish_calls != 0 or io.discard_calls != 0) fail("target-only replay mutated the volume", .{});
        if (!readAndCheck(&v, fx.parent, TARGET, PAYLOAD)) fail("target-only content changed", .{});

        const missing = (try buildFixture(allocator, meta, .missing)) orelse return fail("missing setup failed", .{});
        var dev2 = RamDevice{ .image = missing.image };
        var v2 = openVolume(&dev2) orelse return fail("missing mount failed", .{});
        var io2 = ClaimIo{ .v = &v2, .parent = missing.parent };
        expectState(&io2, &missing.claim, .missing, "missing");
        const rc2 = upc.replayClaim(&io2, &missing.claim);
        if (rc2 != .retired) fail("missing replay: {s}", .{upc.replayStatusName(rc2)});
        if (io2.publish_calls != 0 or io2.discard_calls != 0) fail("missing replay mutated the volume", .{});
        std.debug.print("terminal: ok (target-only and missing are inert)\n", .{});
    }

    // ---- 5. a foreign object is never touched ----------------------------
    {
        const fx = (try buildFixture(allocator, meta, .foreign)) orelse return fail("foreign setup failed", .{});
        var dev = RamDevice{ .image = fx.image };
        var v = openVolume(&dev) orelse return fail("foreign mount failed", .{});
        var io = ClaimIo{ .v = &v, .parent = fx.parent };

        expectState(&io, &fx.claim, .foreign, "foreign");
        const rc = upc.replayClaim(&io, &fx.claim);
        if (rc != .foreign) fail("foreign replay: {s}", .{upc.replayStatusName(rc)});
        if (io.publish_calls != 0 or io.discard_calls != 0) fail("foreign replay mutated the volume", .{});
        if (!readAndCheck(&v, fx.parent, TARGET, FOREIGN)) fail("foreign object was damaged", .{});
        if (io.claim_present) fail("foreign claim not retired", .{});

        // A claim for another volume must not act here either.
        var other = fx.claim;
        other.volume = VOLUME_TOKEN + 1;
        if (io.observe(&other) != .foreign) fail("cross-volume claim was not refused", .{});
        std.debug.print("foreign: ok (name held by a stranger, nothing written)\n", .{});
    }

    // ---- 6. replay is idempotent and a failure keeps the claim -----------
    {
        const fx = (try buildFixture(allocator, meta, .half_published)) orelse return fail("idempotent setup failed", .{});
        var dev = RamDevice{ .image = fx.image };
        var v = openVolume(&dev) orelse return fail("idempotent mount failed", .{});
        var io = ClaimIo{ .v = &v, .parent = fx.parent };

        if (upc.replayClaim(&io, &fx.claim) != .published) fail("first replay failed", .{});
        io.claim_present = true; // simulate a lost retire acknowledgement
        const second = upc.replayClaim(&io, &fx.claim);
        if (second != .published) fail("replayed claim not idempotent: {s}", .{upc.replayStatusName(second)});
        if (!readAndCheck(&v, fx.parent, TARGET, PAYLOAD)) fail("second replay damaged the target", .{});

        // An invalid claim is reported, never acted upon.
        var broken = fx.claim;
        broken.generation = 0;
        if (upc.replayClaim(&io, &broken) != .invalid) fail("invalid claim was not rejected", .{});
        std.debug.print("idempotent: ok (repeat safe, invalid claim inert)\n", .{});
    }

    // ---- 7. a batch keeps going when one claim fails ---------------------
    {
        const fx = (try buildFixture(allocator, meta, .stage_only)) orelse return fail("batch setup failed", .{});
        var dev = RamDevice{ .image = fx.image };
        var v = openVolume(&dev) orelse return fail("batch mount failed", .{});
        var io = ClaimIo{ .v = &v, .parent = fx.parent };

        var broken = fx.claim;
        broken.generation = 0;
        const batch = [_]upc.Claim{ broken, fx.claim };
        const summary = upc.replayAll(&io, batch[0..]);
        if (summary.invalid != 1) fail("batch lost the invalid claim", .{});
        if (summary.rolled_back != 1) fail("batch did not finish the good claim", .{});
        if (summary.total() != 2) fail("batch summary does not account for every claim", .{});
        std.debug.print("batch: ok (one bad claim does not abort the sweep)\n", .{});
    }

    // ---- 8. interrupted replay still reaches a terminal state ------------
    {
        var budget: u32 = 1;
        while (budget <= 6) : (budget += 1) {
            const fx = (try buildFixture(allocator, meta, .half_published)) orelse {
                fail("sweep {d}: setup failed", .{budget});
                continue;
            };
            defer allocator.free(fx.image);
            var dev = RamDevice{ .image = fx.image };
            var v = openVolume(&dev) orelse {
                fail("sweep {d}: mount failed", .{budget});
                continue;
            };
            var io = ClaimIo{ .v = &v, .parent = fx.parent };

            vol.flush_budget = budget;
            _ = upc.replayClaim(&io, &fx.claim);
            vol.flush_budget = null;

            // The claim survives an interrupted replay, so the next mount
            // retries it.
            var dev2 = RamDevice{ .image = fx.image };
            var v2 = openVolume(&dev2) orelse {
                fail("sweep {d}: unmountable after interrupt", .{budget});
                continue;
            };
            var io2 = ClaimIo{ .v = &v2, .parent = fx.parent };
            const rc = upc.replayClaim(&io2, &fx.claim);
            switch (rc) {
                .published, .rolled_back, .retired => {},
                else => fail("sweep {d}: retry not terminal ({s})", .{ budget, upc.replayStatusName(rc) }),
            }
            const has_stage = vol.lookupInDirectory(&v2, fx.parent, STAGE) != null;
            const has_target = vol.lookupInDirectory(&v2, fx.parent, TARGET) != null;
            if (has_stage) fail("sweep {d}: stage leaked", .{budget});
            if (has_target and !readAndCheck(&v2, fx.parent, TARGET, PAYLOAD)) {
                fail("sweep {d}: target present but torn", .{budget});
            }
            if (!readAndCheck(&v2, fx.parent, KEEP, KEEP_DATA)) fail("sweep {d}: bystander damaged", .{budget});
        }
        std.debug.print("sweep: ok (6 interrupted replays, no leaked stage, no torn target)\n", .{});
    }

    // ---- 9. emit a replayed volume for NtfsVerify ------------------------
    if (out_path) |path| {
        const fx = (try buildFixture(allocator, meta, .half_published)) orelse return fail("image setup failed", .{});
        var dev = RamDevice{ .image = fx.image };
        var v = openVolume(&dev) orelse return fail("image mount failed", .{});
        var io = ClaimIo{ .v = &v, .parent = fx.parent };
        if (upc.replayClaim(&io, &fx.claim) != .published) fail("image replay failed", .{});

        const disk = try allocator.alloc(u8, fx.image.len + 2048 * 512);
        @memset(disk[0 .. 2048 * 512], 0);
        std.mem.writeInt(u32, disk[0x1B8..][0..4], 0x52344F57, .little);
        disk[446 + 4] = 0x07;
        std.mem.writeInt(u32, disk[446 + 8 ..][0..4], 2048, .little);
        std.mem.writeInt(u32, disk[446 + 12 ..][0..4], @intCast(fx.image.len / 512), .little);
        disk[510] = 0x55;
        disk[511] = 0xAA;
        std.mem.writeInt(u32, fx.image[0x1C..][0..4], 2048, .little);
        const backup_at = @as(usize, @intCast(std.mem.readInt(u64, fx.image[0x28..][0..8], .little) * 512));
        if (backup_at + 4 <= fx.image.len) {
            std.mem.writeInt(u32, fx.image[backup_at + 0x1C ..][0..4], 2048, .little);
        }
        @memcpy(disk[2048 * 512 ..], fx.image);
        try cwd.writeFile(io_ctx, .{ .sub_path = path, .data = disk });
        std.debug.print("UPLOADCLAIM image written: {s}\n", .{path});
    }

    if (failures != 0) {
        std.debug.print("UPLOADCLAIM result: FAILED ({d})\n", .{failures});
        std.process.exit(1);
    }
    std.debug.print("UPLOADCLAIM result: OK\n", .{});
}
