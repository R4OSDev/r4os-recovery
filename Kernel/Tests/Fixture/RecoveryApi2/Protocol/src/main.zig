const r4os = @import("r4os");
var admitted = false;
comptime { if (!@import("builtin").is_test) asm (r4os.technical2.protocolEntriesAsm("recovery_probe_init", "recovery_probe_shutdown", "recovery_probe_query", "recovery_probe_dispatch")); }
export fn recovery_probe_init(api: *const r4os.r4dev.ProtocolApi2) callconv(.c) i32 {
    const ctx = r4os.r4dev.ProtocolContext2.init(api);
    if (!ctx.requires(.{ "register_role", "set_status", "file_read", "log_info" })) return -1;
    var text: [1024]u8 = undefined;
    if (ctx.fileRead("C:\\R4OS\\CONFIG\\RECOVERY.R4S", &text) <= 0) return -2;
    if (ctx.registerRole("misc.recovery_api2_probe", .misc, 0) != 0 or ctx.setStatus(.active, "Recovery API2 diagnostic") != 0) return -3;
    admitted = true;
    ctx.logInfo("[RECOVERYAPI2] protocol=OK init=2 file_read=OK role=OK");
    return 0;
}
export fn recovery_probe_shutdown() callconv(.c) i32 { admitted = false; return 0; }
export fn recovery_probe_query(out: *r4os.abi.ProtocolStatus) callconv(.c) i32 {
    out.* = .{ .state = @intFromEnum(r4os.abi.ProtocolState.active), .flags = 0, .last_error = 0, .reserved = 0, .note = .{0} ** 64 };
    return if (admitted) 0 else -1;
}
export fn recovery_probe_dispatch(op: u32, input: *const r4os.abi.ProtocolBuffer, output: *r4os.abi.ProtocolBuffer) callconv(.c) i32 {
    _ = input;
    if (!admitted or op != 0x90084 or output.capacity < 4 or output.data == null) return -1;
    const bytes: [*]u8 = @ptrCast(output.data.?);
    @memcpy(bytes[0..4], "API2");
    output.len = 4;
    return 0;
}
