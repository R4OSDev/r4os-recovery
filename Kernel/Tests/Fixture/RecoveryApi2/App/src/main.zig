const std = @import("std");
const r4os = @import("r4os");
const a = r4os.abi;
const p2 = r4os.platform2;
const executable = "C:\\R4OS\\SOFTWARE\\API2PROBE\\API2PROBE.R4X";

pub fn r4_app_main(app: *r4os.App2) i32 {
    const sys = app.system();
    if (std.mem.eql(u8, app.args(), "/EXIT37")) return 37;
    if (std.mem.eql(u8, app.args(), "/CLOSE")) {
        while (!app.shouldClose()) app.yield();
        return sys.programExit(0, a.program_exit_reason_close);
    }
    if (std.mem.eql(u8, app.args(), "/KILL")) {
        while (true) app.yield();
    }
    const console = app.console() orelse return -100;
    const code = probe(app);
    if (code != 0) {
        var buf: [80]u8 = undefined;
        console.line(std.fmt.bufPrint(&buf, "[RECOVERYAPI2] app=FAILED code={d}", .{code}) catch "app=FAILED");
        return code;
    }
    console.line("[RECOVERYAPI2] app=OK imports=32 query=6 metadata=OK batch=OK clock=OK rng=OK close_kill_wait_reap=OK");
    return 0;
}

fn probe(app: *r4os.App2) i32 {
    const raw = app.startContext();
    if (raw.magic != p2.abi.start_magic or raw.size != @sizeOf(p2.abi.R4XStartContext2) or raw.import_count != 32) return -101;
    const imports: [*]const a.R4XStartImport = @ptrFromInt(raw.imports);
    for (imports[0..6], 1..) |item, group| {
        if (item.group_id != group or item.table == 0 or item.resolved_version != 2 or item.min_version != 2) return -102;
    }
    for (imports[6..32]) |item| if (item.table != 0 or item.resolved_version != 0 or item.group_id != 0 or item.min_version != 1 or item.flags != 0) return -103;
    const sys = app.system();
    var clock: a.MonotonicClockInfo = .{};
    if (sys.monotonicClock(&clock) != 1) return -104;
    const sample = r4os.time_contract.checked.ClockSample.fromInfo(clock) catch return -105;
    var budget = r4os.time_contract.checked.DeadlineBudget.init(sample, r4os.time_contract.timeoutFinite(r4os.time_contract.durationFromNanoseconds(500_000_000))) catch return -106;
    if (sys.monotonicClock(&clock) != 1) return -107;
    _ = budget.remaining(r4os.time_contract.checked.ClockSample.fromInfo(clock) catch return -108) catch return -109;
    const metadata = p2.abi.function(p2.abi.R4SysFns2, app.context.system(), "file_metadata2") orelse return -110;
    var info: a.FileMetadata2 = .{};
    if (metadata("C:\\R4OS\\CONFIG\\RECOVERY.R4S", &info) != 1 or info.byte_size == 0 or info.flags & a.file_metadata2_flag_identity_valid == 0 or info.identity.namespace_generation == 0) return -111;
    if (info.flags & a.file_metadata2_flag_content_revision_valid != 0) return -112;
    var absent: a.FileMetadata2 = .{ .byte_size = 0xfedcba9876543210, .backend_node = 0x123456789abcdef0 };
    const original = absent;
    if (metadata("C:\\TEMP\\R2MISS.TXT", &absent) != 0 or !std.mem.eql(u8, std.mem.asBytes(&original), std.mem.asBytes(&absent))) return -113;
    const batch = p2.abi.function(p2.abi.R4SysFns2, app.context.system(), "directory_metadata_batch2") orelse return -114;
    if (sys.fileWrite("C:\\TEMP\\R2A.TXT", "ONE") != 3 or sys.fileWrite("C:\\TEMP\\R2B.TXT", "TWO") != 3) return -115;
    defer { _ = sys.fileDelete("C:\\TEMP\\R2A.TXT"); _ = sys.fileDelete("C:\\TEMP\\R2B.TXT"); _ = sys.fileDelete("C:\\TEMP\\R2C.TXT"); }
    var cursor: a.DirectoryMetadataCursor2 = .{};
    var rows: [8]a.DirectoryMetadataEntry2 = undefined;
    const count = batch("C:\\TEMP", &cursor, &rows, 8);
    if (count < 2 or count > 8 or cursor.namespace_generation == 0 or cursor.flags & a.directory_metadata2_flag_bound == 0) return -116;
    for (rows[0..@intCast(count)]) |row| if (row.info.flags & a.file_metadata2_flag_identity_valid == 0 or row.info.identity.namespace_generation != cursor.namespace_generation or row.path[0] != 'C') return -117;
    const saved_cursor = cursor;
    if (batch(null, &cursor, null, 0) != 0 or !std.mem.eql(u8, std.mem.asBytes(&cursor), std.mem.asBytes(&saved_cursor))) return -118;
    if (sys.fileWrite("C:\\TEMP\\R2C.TXT", "THREE") != 5) return -119;
    if (batch(null, &cursor, null, 0) != a.file_metadata2_error_restart or !std.mem.eql(u8, std.mem.asBytes(&cursor), std.mem.asBytes(&saved_cursor))) return -120;
    const dev = app.devicesLowLevel() orelse return -128;
    var cpu: a.CpuAccelerationInfo = .{};
    if (dev.cpuAccelerationInfo(&cpu) != 0 or cpu.epoch == 0 or cpu.capture_sequence == 0 or cpu.os_mask & a.cpu_accel_feature_rdrand == 0) return -129;
    var random: [64]u8 = undefined;
    if (!r4os.secure_random.fill(&random)) return -130;
    @memset(&random, 0);
    for ([_][*:0]const u8{ "/EXIT37", "/CLOSE", "/KILL" }, 0..) |args, mode| {
        var child: a.ProgramProcessHandle = .{};
        if (sys.programSpawnHandle(executable, args, .console, &child) != 0 or child.instance_id == 0 or child.generation == 0) return -121;
        var reaped = false;
        defer if (!reaped) { _ = sys.programHandleKill(&child); var done: a.ProgramProcessCompletion = .{}; _ = sys.programHandleWait(&child, sys.ticksFromMilliseconds(5000), &done); _ = sys.programHandleReap(&child, &done); };
        // Actual Close and Kill run under the original process owner. The
        // returned completion, not a request result, authorizes retirement.
        if (mode == 1 and sys.programHandleRequestClose(&child) != 0) return -122;
        if (mode == 2 and sys.programHandleKill(&child) != 0) return -123;
        var done: a.ProgramProcessCompletion = .{};
        if (sys.programHandleWait(&child, sys.ticksFromMilliseconds(5000), &done) != 0 or done.handle.instance_id != child.instance_id or done.handle.generation != child.generation or done.sequence == 0) return -124;
        const reason: u8 = if (mode == 0) a.program_exit_reason_natural else if (mode == 1) a.program_exit_reason_close else a.program_exit_reason_killed;
        if (done.exit_reason != reason or (mode == 0 and done.exit_code != 37)) return -125;
        if (sys.programHandleReap(&child, &done) != 0) return -126;
        reaped = true;
        var stale: a.ProgramInstanceInfo = .{};
        if (sys.programHandleStatus(&child, &stale) == 0) return -127;
    }
    return 0;
}
