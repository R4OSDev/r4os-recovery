const std = @import("std");
const api = @import("r4os_contract2");
const c = @cImport({
    @cInclude("r4os/generation2.h");
});

test "new generation has distinct identities and exact compact layouts in C and Zig" {
    @setEvalBranchQuota(100_000);
    try std.testing.expectEqual(@as(usize, 24), @sizeOf(api.R4LQuery2));
    try std.testing.expectEqual(@as(usize, 120), @sizeOf(api.R4XStartContext2));
    try std.testing.expect(!@hasField(api.R4XStartContext2, "reserved_runtime"));
    try std.testing.expect(!@hasField(api.R4LQuery2, "kernel_bridge"));
    inline for (.{ "R4XStartR4Sys2", "R4XStartR4Desk2", "R4XStartR4Draw2", "R4XStartR4Net2", "R4XStartR4Audio2", "R4XStartR4Dev2" }) |name| {
        const T = @field(api, name);
        const C = @field(c, name);
        try std.testing.expectEqual(@sizeOf(T), @sizeOf(C));
        try std.testing.expectEqual(@alignOf(T), @alignOf(C));
        inline for (std.meta.fields(T)) |f| try std.testing.expectEqual(@offsetOf(T, f.name), @offsetOf(C, f.name));
        const version: u32 = if (T == api.R4XStartR4Sys2) 6 else if (T == api.R4XStartR4Draw2 or T == api.R4XStartR4Dev2 or T == api.R4XStartR4Audio2) 2 else 1;
        try std.testing.expectEqual(version, (T{}).abi_version);
    }
    try std.testing.expect(!@hasField(api.R4XStartR4Sys2, "reserved_shell_run"));
    try std.testing.expect(!@hasField(api.R4XStartR4Dev2, "reserved_program_registry_summary_v1"));
    try std.testing.expect((api.R4XStartR4Sys2{}).magic != (api.shared.R4XStartR4Sys{}).magic);
    // One optional capture follows both independently preserved prefixes.
    try std.testing.expectEqual(@as(usize, 736), @offsetOf(api.shared.R4XStartR4Dev, "device_inventory_capture"));
    try std.testing.expectEqual(@as(usize, 712), @offsetOf(api.R4XStartR4Dev2, "device_inventory_capture"));
    try std.testing.expectEqual(@as(usize, 1416), @offsetOf(api.shared.R4XStartR4Sys, "file_metadata2"));
    try std.testing.expectEqual(@as(usize, 1424), @offsetOf(api.shared.R4XStartR4Sys, "directory_metadata_batch2"));
    try std.testing.expectEqual(@as(usize, 1408), @offsetOf(api.R4XStartR4Sys2, "file_metadata2"));
    try std.testing.expectEqual(@as(usize, 1416), @offsetOf(api.R4XStartR4Sys2, "directory_metadata_batch2"));
    try std.testing.expectEqual(@as(usize, 1560), @sizeOf(api.shared.R4XStartR4Sys));
    try std.testing.expectEqual(@as(usize, 1552), @sizeOf(api.R4XStartR4Sys2));
    try std.testing.expectEqual(@as(usize, 240), @sizeOf(api.R4XStartR4Audio2));
    try std.testing.expectEqual(@as(usize, 232), @offsetOf(api.R4XStartR4Audio2, "audio_capture_io"));
    inline for (.{ "waitset_create", "waitset_enroll", "waitset_rearm", "waitset_remove", "waitset_wait", "waitset_close", "waitset_source_prepare" }, 0..) |name, index| {
        try std.testing.expectEqual(@as(usize, 1432) + index * 8, @offsetOf(api.shared.R4XStartR4Sys, name));
        try std.testing.expectEqual(@as(usize, 1424) + index * 8, @offsetOf(api.R4XStartR4Sys2, name));
    }
    // Preserve both original byte prefixes and check the seven new tails
    // independently of the generated field order or current total size.
    inline for (.{ "byte_pipe_create", "byte_pipe_dup", "byte_pipe_read", "byte_pipe_write", "byte_pipe_cancel", "byte_pipe_close", "byte_pipe_info" }, 0..) |name, index| {
        try std.testing.expectEqual(@as(usize, 1488) + index * 8, @offsetOf(api.shared.R4XStartR4Sys, name));
        try std.testing.expectEqual(@as(usize, 1480) + index * 8, @offsetOf(api.R4XStartR4Sys2, name));
    }
    inline for (.{ .{ api.shared.BytePipeEnd, c.R4BytePipeEnd, 24 }, .{ api.shared.BytePipePair, c.R4BytePipePair, 56 }, .{ api.shared.BytePipeProgress, c.R4BytePipeProgress, 24 }, .{ api.shared.BytePipeInfo, c.R4BytePipeInfo, 48 } }) |pair| {
        try std.testing.expectEqual(@as(usize, pair[2]), @sizeOf(pair[0]));
        try std.testing.expectEqual(@sizeOf(pair[0]), @sizeOf(pair[1]));
        try std.testing.expectEqual(@alignOf(pair[0]), @alignOf(pair[1]));
        inline for (std.meta.fields(pair[0])) |field| try std.testing.expectEqual(@offsetOf(pair[0], field.name), @offsetOf(pair[1], field.name));
    }
    inline for (.{ "program_launch_io", "program_stdio" }, 0..) |name, index| {
        try std.testing.expectEqual(@as(usize, 1544) + index * 8, @offsetOf(api.shared.R4XStartR4Sys, name));
        try std.testing.expectEqual(@as(usize, 1536) + index * 8, @offsetOf(api.R4XStartR4Sys2, name));
    }
    inline for (.{ .{ api.shared.LaunchIoBinding, c.R4LaunchIoBinding, 32 }, .{ api.shared.LaunchIo, c.R4LaunchIo, 112 } }) |pair| {
        try std.testing.expectEqual(@as(usize, pair[2]), @sizeOf(pair[0]));
        try std.testing.expectEqual(@sizeOf(pair[0]), @sizeOf(pair[1]));
        try std.testing.expectEqual(@alignOf(pair[0]), @alignOf(pair[1]));
        inline for (std.meta.fields(pair[0])) |field| try std.testing.expectEqual(@offsetOf(pair[0], field.name), @offsetOf(pair[1], field.name));
    }
    try std.testing.expectEqual(@as(usize, 80), @sizeOf(api.shared.WaitSource));
    try std.testing.expectEqual(@as(usize, 64), @sizeOf(api.shared.WaitSourceRequest));
    try std.testing.expectEqual(@as(usize, 48), @sizeOf(api.shared.WaitSetDeadline));
    try std.testing.expectEqual(@as(usize, 48), @sizeOf(api.shared.WaitSetEvent));
    try std.testing.expectEqual(@as(usize, 40), @sizeOf(api.shared.WaitSetBatch));
    try std.testing.expectEqual(@as(usize, 912), @offsetOf(api.shared.R4XStartR4Draw, "font_prefix_metrics2"));
    try std.testing.expectEqual(@as(usize, 912), @offsetOf(api.R4XStartR4Draw2, "font_prefix_metrics2"));
    try std.testing.expectEqual(@as(usize, 8), @sizeOf(api.shared.FontAdvance2));
    try std.testing.expectEqual(@as(usize, 40), @sizeOf(api.shared.FontAdvanceInfo2));
}

test "generation2 typed calls preserve the canonical C function signature and declared prefix" {
    const Provider = struct {
        fn write(bytes: [*]const u8, length: u32) callconv(.c) i32 {
            return if (length == 4 and std.mem.eql(u8, bytes[0..length], "API2")) -20002 else -1;
        }
    };
    var table: api.R4XStartR4Sys2 = .{ .write = @intFromPtr(&Provider.write) };
    const view: ?*const api.R4XStartR4Sys2 = &table;
    const call = api.function(api.R4SysFns2, view, "write") orelse return error.MissingFunction;
    try std.testing.expectEqual(@as(i32, -20002), call("API2", 4));
    table.size = 16;
    try std.testing.expect(api.function(api.R4SysFns2, view, "write") == null);
    table.size = @sizeOf(api.R4XStartR4Sys2);
    table.write = 0;
    try std.testing.expect(api.function(api.R4SysFns2, view, "write") == null);
}

test "technical generation2 retains exact typed live slots and bounds the real smaller status callback" {
    @setEvalBranchQuota(100_000);
    inline for (.{ .{ api.DriverApi2, c.R4DriverApi2 }, .{ api.ProtocolApi2, c.R4ProtocolApi2 }, .{ api.AudioBackend2, c.R4AudioBackend2 }, .{ api.AudioBackendStatus2, c.R4AudioBackendStatus2 } }) |pair| {
        try std.testing.expectEqual(@sizeOf(pair[0]), @sizeOf(pair[1]));
        try std.testing.expectEqual(@alignOf(pair[0]), @alignOf(pair[1]));
        inline for (std.meta.fields(pair[0])) |field| try std.testing.expectEqual(@offsetOf(pair[0], field.name), @offsetOf(pair[1], field.name));
    }
    try std.testing.expectEqual(@as(usize, 664), @sizeOf(api.DriverApi2));
    try std.testing.expectEqual(@as(usize, 656), @offsetOf(api.DriverApi2, "register_audio_capture_backend"));
    try std.testing.expectEqual(@as(usize, 40), @sizeOf(api.AudioCaptureBackend2));
    try std.testing.expectEqual(@as(usize, 144), @sizeOf(api.ProtocolApi2));
    try std.testing.expectEqual(@as(usize, 120), @sizeOf(api.shared.ProtocolApi));
    try std.testing.expectEqual(@as(usize, 120), @offsetOf(api.ProtocolApi2, "protocol_dispatch"));
    try std.testing.expectEqual(@as(usize, 128), @offsetOf(api.ProtocolApi2, "link_io"));
    try std.testing.expectEqual(@as(usize, 136), @offsetOf(api.ProtocolApi2, "process_status"));
    inline for (std.meta.fields(api.shared.ProtocolApi)) |field| {
        try std.testing.expectEqual(@offsetOf(api.shared.ProtocolApi, field.name), @offsetOf(api.ProtocolApi2, field.name));
        try std.testing.expect(@FieldType(api.ProtocolApi2, field.name) == field.type);
    }
    try std.testing.expectEqual(@as(usize, 80), @sizeOf(api.AudioBackendStatus2));
    try std.testing.expectEqual(@as(usize, 136), @sizeOf(api.AudioBackend2));
    try std.testing.expect(!@hasField(api.DriverApi2, "register_audio_backend"));
    try std.testing.expect(!@hasField(api.DriverApi2, "register_synth_engine"));
    inline for (.{ "last_write_ticks", "max_write_ticks", "total_write_ticks", "last_refill_ticks", "max_refill_ticks", "total_refill_ticks" }) |name| try std.testing.expect(!@hasField(api.AudioBackendStatus2, name));
    var offset: usize = 0;
    inline for (std.meta.fields(api.shared.DriverApi)) |field| {
        if (comptime std.mem.eql(u8, field.name, "register_audio_backend") or std.mem.eql(u8, field.name, "register_synth_engine")) continue;
        try std.testing.expectEqual(offset, @offsetOf(api.DriverApi2, field.name));
        if (comptime !std.mem.eql(u8, field.name, "register_audio_output_backend")) try std.testing.expect(@FieldType(api.DriverApi2, field.name) == field.type);
        offset += @sizeOf(field.type);
    }
    try std.testing.expect(api.driver_magic != api.shared.driver_magic);
    try std.testing.expect(api.protocol_magic != api.shared.protocol_magic);
    try std.testing.expectEqual(@as(u32, 3), (api.AudioBackend2{}).version);
    try std.testing.expect((api.AudioBackend2{}).magic != api.shared.audio_backend_outputs_version);
    const Provider = struct {
        fn status(raw: ?*anyopaque, out: *api.AudioBackendStatus2) callconv(.c) i32 {
            if (@intFromPtr(raw) != 0x100000009) return -1;
            out.* = .{ .active = 1, .writes = 0x100000007, .underruns = 3, .last_result = -17, .last_buffer_bytes = 64 };
            return 0;
        }
    };
    var guarded: extern struct { status: c.R4AudioBackendStatus2, guard: u64 } = .{ .status = std.mem.zeroes(c.R4AudioBackendStatus2), .guard = 0xdeadbeef10000003 };
    const callback: c.R4AudioBackendStatusFn2 = @ptrCast(&Provider.status);
    try std.testing.expectEqual(@as(i32, 0), callback.?(@ptrFromInt(0x100000009), &guarded.status));
    try std.testing.expectEqual(@as(u64, 0x100000007), guarded.status.writes);
    try std.testing.expectEqual(@as(i32, -17), guarded.status.last_result);
    try std.testing.expectEqual(@as(u64, 0xdeadbeef10000003), guarded.guard);
}
