const r4os = @import("r4os");

comptime {
    asm (r4os.r4dev.protocolEntriesAsm("sdk_smoke_r4p_init", "sdk_smoke_r4p_shutdown", "sdk_smoke_r4p_query", "sdk_smoke_r4p_dispatch"));
}

export fn sdk_smoke_r4p_init(api: *const r4os.r4dev.ProtocolApi) callconv(.c) i32 {
    var ctx = r4os.r4dev.ProtocolContext.init(api);
    ctx.logInfo("SDKSMOKE.R4P init");
    _ = ctx.registerRole("misc.sdk_smoke", .misc, 0);
    _ = ctx.setStatus(.active, "SDK R4P smoke active");
    return 0;
}

export fn sdk_smoke_r4p_shutdown() callconv(.c) i32 {
    return 0;
}

export fn sdk_smoke_r4p_query(out: *r4os.abi.ProtocolStatus) callconv(.c) i32 {
    out.* = .{
        .state = @intFromEnum(r4os.abi.ProtocolState.active),
        .flags = 0,
        .last_error = 0,
        .reserved = 0,
        .note = note("SDK R4P smoke ready"),
    };
    return 0;
}

export fn sdk_smoke_r4p_dispatch(op: u32, in_buffer: *const r4os.abi.ProtocolBuffer, out_buffer: *r4os.abi.ProtocolBuffer) callconv(.c) i32 {
    _ = op;
    _ = in_buffer;
    _ = out_buffer;
    return -4;
}

fn note(comptime text: []const u8) [64]u8 {
    var out: [64]u8 = .{0} ** 64;
    @memcpy(out[0..text.len], text);
    return out;
}
