// Bounded guest witness. The operation prepares source RAM and a target plan;
// it never executes that plan or opens a partition for writing.
const std = @import("std");
const r4os = @import("r4os");
const packages = @import("package_session.zig");
const abi = r4os.abi;
fn check(value: bool) !void {
    if (!value) return error.RamWitness;
}
fn memory(sys: *const r4os.r4sys.Context, dev: *const r4os.r4dev.Context) !void {
    const region = sys.vmReserve(9 * 4096, 4096, abi.vm_region_flags_default) orelse return error.OutOfMemory;
    var released = false;
    defer if (!released) {
        _ = sys.vmRelease(region.id);
    };
    try check(sys.vmCommitFlags(region.id, 0, 4 * 4096, abi.vm_commit_flag_resident) == abi.vm_ok);
    var info = sys.vmQuery(region.id) orelse return error.RamWitness;
    try check(info.committed_bytes == 4 * 4096 and info.resident_bytes == 4 * 4096 and info.fault_count == 0);
    const probe = dev.memoryVmPageStateProbe(region.id, 0, 4, abi.memory_vm_page_state_operation_query, 0, 0, 0, 0) orelse return error.RamWitness;
    try check(probe.pinned_pages == 4 and probe.resident_pages == 4);
    const bytes: [*]volatile u8 = @ptrFromInt(info.base);
    for (0..4 * 4096) |i| {
        try check(bytes[i] == 0);
        bytes[i] = 0xa5;
    }
    try check(sys.vmCommitFlags(region.id, 4 * 4096, 4096, 8) == abi.vm_error_unsupported_flags);
    try check(sys.vmCommitFlags(region.id, 4 * 4096, abi.vm_commit_resident_max_bytes + 4096, abi.vm_commit_flag_resident) == abi.vm_error_invalid_range);
    try check(sys.vmCommit(region.id, 4 * 4096, 2 * 4096) == abi.vm_ok);
    info = sys.vmQuery(region.id) orelse return error.RamWitness;
    try check(info.committed_bytes == 6 * 4096 and info.resident_bytes == 4 * 4096 and info.fault_count == 0);
    try check(sys.vmDecommit(region.id, 4096, 2 * 4096) == abi.vm_ok);
    try check(sys.vmCommitFlags(region.id, 4096, 2 * 4096, abi.vm_commit_flag_resident) == abi.vm_ok);
    for (4096..3 * 4096) |i| try check(bytes[i] == 0);
    try check(bytes[0] == 0xa5 and bytes[3 * 4096] == 0xa5);
    try check(sys.vmRelease(region.id) == abi.vm_ok);
    released = true;
    try check(sys.vmQuery(region.id) == null);
    sys.write("[PACKAGERAM] resident=pinned zero=yes lazy=unchanged sparse-release=OK flags=checked\r\n");
}
fn pump(raw: ?*anyopaque, _: []const u8, _: u64, _: u64) bool {
    const sys: *const r4os.r4sys.Context = @ptrCast(@alignCast(raw.?));
    sys.taskYield();
    return !sys.programShouldClose();
}
pub fn run(app: *r4os.App, args: []const u8) i32 {
    const sys = app.system();
    const dev = app.devicesLowLevel() orelse return 1;
    witness(&sys, &dev, args) catch |err| {
        var buffer: [128]u8 = undefined;
        sys.write(std.fmt.bufPrint(&buffer, "[PACKAGESMOKE] result=FAILED error={s} writes=0\r\n", .{@errorName(err)}) catch "Package witness failed\r\n");
        return 1;
    };
    return 0;
}
fn witness(sys: *const r4os.r4sys.Context, dev: *const r4os.r4dev.Context, args: []const u8) !void {
    const oom = std.mem.eql(u8, args, "OOM");
    const recovery = std.mem.eql(u8, args, "RECOVERY");
    const reject = std.mem.eql(u8, args, "REJECT");
    const hold = std.mem.eql(u8, args, "HOLD");
    if (!oom and !recovery and !reject and !hold and !std.mem.eql(u8, args, "R4OS")) return error.Usage;
    try memory(sys, dev);
    const session = try sys.allocator().create(packages.Session);
    defer sys.allocator().destroy(session);
    session.init(sys, dev, .{ .context = @constCast(sys), .function = pump });
    var cleaned = false;
    defer if (!cleaned) {
        _ = session.deinit();
    };
    const kind: packages.package.Kind = if (recovery or reject) .recovery else .r4os;
    const path = if (recovery or reject) "R:\\INSTALL\\RECOVERY.ZIP" else "R:\\INSTALL\\RELEASE.ZIP";
    session.prepare(path, kind, null) catch |err| {
        if ((oom and err == error.OutOfMemory) or (reject and (err == error.HashMismatch or err == error.InvalidArchive or err == error.Inflate or err == error.Checksum or err == error.FileSetMismatch))) {
            try check(session.deinit());
            cleaned = true;
            sys.write(if (oom) "[PACKAGESMOKE] insufficient-ram=CONTROLLED result=OK writes=0\r\n" else "[PACKAGESMOKE] invalid-package=REJECTED result=OK writes=0\r\n");
            return;
        }
        return err;
    };
    if (oom or reject) return error.InvalidAccepted;
    if (!recovery) try session.targetSystem(266240, 32 * 2048, 0x7615);
    if (hold) {
        const ready = "C:\\TEMP\\PACKAGE.RDY";
        const release = "C:\\TEMP\\PACKAGE.REL";
        _ = sys.fileDelete(ready);
        _ = sys.fileDelete(release);
        defer {
            _ = sys.fileDelete(ready);
            _ = sys.fileDelete(release);
        }
        const payload_hash = try session.digest(session.prepared.?.archive.payload);
        const recovery_hash = try session.digest(session.prepared.?.recovery_archive.payload);
        try check(sys.fileWrite(ready, "READY") == 5);
        sys.write("[PACKAGESMOKE] source-detach=READY\r\n");
        const deadline = sys.ticks() + sys.ticksFromMilliseconds(30000);
        while (sys.fileInfo(release) == null) {
            if (sys.ticks() >= deadline or sys.programShouldClose()) return error.DetachTimeout;
            sys.sleepTicks(sys.ticksFromMilliseconds(20));
        }
        const original_after = try session.digest(session.prepared.?.archive.original);
        const payload_after = try session.digest(session.prepared.?.archive.payload);
        const recovery_after = try session.digest(session.prepared.?.recovery_archive.payload);
        try check(std.mem.eql(u8, &session.original_digest, &original_after));
        try check(std.mem.eql(u8, &payload_hash, &payload_after));
        try check(std.mem.eql(u8, &recovery_hash, &recovery_after));
        try check(session.tree.?.get("/R4OS/CONFIG/VERSION.R4S") != null and session.target.?.plan.bytes == 32 * 1024 * 1024);
        sys.write("[PACKAGESMOKE] source-detached original_zip=SHA256 payload=SHA256 recovery=SHA256 target_plan=RETAINED\r\n");
    }
    var line: [224]u8 = undefined;
    sys.write(std.fmt.bufPrint(&line, "[PACKAGESMOKE] kind={s} version={s} pinned_peak={d} original_zip={d} system_files={d} target_bytes={d}\r\n", .{ @tagName(kind), session.prepared.?.version(), session.pool.peak, session.prepared.?.archive.original.len, if (session.tree) |tree| tree.nodes.items.len - 1 else @as(usize, 0), if (session.target) |target| target.plan.bytes else @as(u64, 0) }) catch "");
    try check(session.deinit());
    cleaned = true;
    sys.write("[PACKAGESMOKE] cleanup=OK result=OK writes=0\r\n");
}
