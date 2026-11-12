//! Host tests never execute optional SHA instructions. The executor peer uses
//! the normal std compressor and returns explicit accepted/rejected receipts.
const std = @import("std");
const builtin = @import("builtin");
const a = @import("r4os_contract").abi;
const acceleration = @import("cpu_acceleration.zig");
const memory = @import("cpu_memory.zig");
const crypto = @import("crypto_sha256.zig");
const leaf = @import("crypto_sha256_leaf.zig");
const program = @import("program.zig");
var mode: u32 = 0;
var calls: u32 = 0;
fn provider() ?acceleration.WorkFn {
    return if (mode == 6) null else execute;
}
fn execute(kind: u32, blocks: u32, slot: ?*const a.CpuPureWorkFn, context: u64, out: *a.CpuAccelerationWork) callconv(.c) i32 {
    calls += 1;
    std.debug.assert(kind == a.cpu_accel_work_kind_sha256 and blocks >= 8 and blocks <= 64 and slot != null);
    if (mode == 1) return a.cpu_capabilities_error_unsupported;
    const batch: *leaf.Batch = @ptrFromInt(context);
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    h.s = batch.state.s;
    h.update(batch.data[0 .. @as(usize, blocks) * 64]);
    batch.state.s = h.s;
    out.* = .{ .epoch = 7, .capture_sequence = 14, .work_kind = kind, .iterations = blocks, .flags = 127, .original_if = 512, .final_if = 512, .begin_ns = 100, .end_ns = 200, .clock_source = 1, .granted_mask = a.cpu_accel_feature_sha, .xcr0 = 7 };
    switch (mode) {
        2 => {
            batch.state.s = .{0} ** 8;
            out.status = a.cpu_accel_work_status_callback_aborted;
        },
        3 => out.end_ns = out.begin_ns + a.cpu_accel_max_window_ns + 1,
        4 => out.flags &= ~@as(u32, a.cpu_accel_work_flag_identity_valid),
        5 => out.granted_mask = 0,
        else => {},
    }
    return 0;
}
test "SHA streaming HMAC and transaction rollback preserve std vectors without host optional ISA" {
    const Hash = crypto.Sha256(provider);
    var data: [12289]u8 = undefined;
    for (&data, 0..) |*b, i| b.* = @truncate(i *% 73);
    for (0..7) |m| {
        mode = @intCast(m);
        calls = 0;
        var accepted: usize = 0;
        var refused: usize = 0;
        for ([_]usize{ 0, 1, 55, 56, 63, 64, 65, 511, 512, 513, 4095, 4096, 4097, 8192, data.len }) |n| {
            var expected: [32]u8 = undefined;
            std.crypto.hash.sha2.Sha256.hash(data[0..n], &expected, .{});
            for ([_]usize{ 0, 1, 63, 64, 65, 511 }) |split| {
                var h = Hash.init(.{});
                h.update(data[0..@min(split, n)]);
                h.update(data[@min(split, n)..n]);
                const peek = h.peek();
                const result = h.finalResult();
                try std.testing.expectEqualSlices(u8, &expected, &peek);
                try std.testing.expectEqualSlices(u8, &expected, &result);
                try std.testing.expectEqual(@as(u64, n), h.inner.total_len);
                accepted += h.accepted_blocks;
                refused += h.refused_windows;
            }
        }
        var expected: [32]u8 = undefined;
        var result: [32]u8 = undefined;
        std.crypto.auth.hmac.sha2.HmacSha256.create(&expected, &data, "transactional SHA256");
        std.crypto.auth.hmac.Hmac(Hash).create(&result, &data, "transactional SHA256");
        try std.testing.expectEqualSlices(u8, &expected, &result);
        if (m == 0) {
            try std.testing.expect(accepted > 0);
            try std.testing.expectEqual(@as(usize, 0), refused);
        } else {
            try std.testing.expectEqual(@as(usize, 0), accepted);
            if (m == 6) try std.testing.expectEqual(@as(u32, 0), calls) else try std.testing.expect(refused > 0);
        }
    }
}
test "memory short long alignments and overlap both directions preserve exact bytes and canaries" {
    var source: [8192]u8 = undefined;
    for (&source, 0..) |*b, i| b.* = @truncate(i *% 97);
    var actual: [16384 + 128]u8 = undefined;
    var expected: [16384 + 128]u8 = undefined;
    for ([_]bool{ false, true }) |erms| {
        const policy: memory.Policy = .{ .erms = erms };
        for (0..64) |alignment| for ([_]usize{ 0, 1, 7, 31, 63, 64, 127, 128, 255, 256, 257, 511, 512, 4095, 4096, 8192 }) |n| {
            @memset(&actual, 0xa5);
            expected = actual;
            @memcpy(expected[alignment..][0..n], source[0..n]);
            policy.move(actual[alignment..][0..n], source[0..n]);
            try std.testing.expectEqualSlices(u8, &expected, &actual);
        };
        for ([_]usize{ 1, 7, 31, 63, 255, 256, 4096 }) |distance| for ([_]bool{ false, true }) |backward| {
            @memset(&actual, 0xa5);
            @memcpy(actual[0..8192], &source);
            expected = actual;
            const from: usize = if (backward) 0 else distance;
            const to: usize = if (backward) distance else 0;
            if (backward) std.mem.copyBackwards(u8, expected[to..][0..8192], expected[from..][0..8192]) else std.mem.copyForwards(u8, expected[to..][0..8192], expected[from..][0..8192]);
            policy.move(actual[to..][0..8192], actual[from..][0..8192]);
            try std.testing.expectEqualSlices(u8, &expected, &actual);
        };
    }
}
test "memory exact page edges touch neither inaccessible source nor destination guard" {
    if (builtin.os.tag != .linux) return error.SkipZigTest;
    const page = 4096;
    const src = try std.posix.mmap(null, page * 3, .{}, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(src);
    const dst = try std.posix.mmap(null, page * 3, .{}, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(dst);
    try std.testing.expectEqual(@as(usize, 0), std.os.linux.mprotect(src.ptr + page, page, .{ .READ = true, .WRITE = true }));
    try std.testing.expectEqual(@as(usize, 0), std.os.linux.mprotect(dst.ptr + page, page, .{ .READ = true, .WRITE = true }));
    @memset(src[page .. page * 2], 0x6b);
    const Hash = crypto.Sha256(provider);
    for ([_]u32{ 0, 1, 2, 3, 4, 5, 6 }) |m| {
        mode = m;
        for ([_]usize{ 0, 55, 56, 63, 64, 65, 511, 512, 513, 4095, 4096 }) |n| {
            const input = src[page * 2 - n .. page * 2];
            var expected_hash: [32]u8 = undefined;
            var actual_hash: [32]u8 = undefined;
            std.crypto.hash.sha2.Sha256.hash(input, &expected_hash, .{});
            Hash.hash(input, &actual_hash, .{});
            try std.testing.expectEqualSlices(u8, &expected_hash, &actual_hash);
        }
    }
    for ([_]bool{ false, true }) |erms| for ([_]usize{ 0, 1, 63, 255, 256, 257, 4095, 4096 }) |n| {
        const policy: memory.Policy = .{ .erms = erms };
        for ([_]bool{ false, true }) |end| {
            const start = if (end) page * 2 - n else page;
            policy.move(dst[start..][0..n], src[start..][0..n]);
            try std.testing.expectEqualSlices(u8, src[start..][0..n], dst[start..][0..n]);
        }
    };
}
test "legacy ProtocolApi prefix ends at a real inaccessible page and never reads an absent extension" {
    if (builtin.os.tag != .linux) return error.SkipZigTest;
    const page = 4096;
    const region = try std.posix.mmap(null, page * 3, .{}, .{ .TYPE = .PRIVATE, .ANONYMOUS = true }, -1, 0);
    defer std.posix.munmap(region);
    try std.testing.expectEqual(@as(usize, 0), std.os.linux.mprotect(region.ptr + page, page, .{ .READ = true, .WRITE = true }));
    for ([_]usize{ 88, 96, 104 }) |size| {
        @memset(region[page * 2 - size .. page * 2], 0);
        const api: *a.ProtocolApi = @ptrCast(@alignCast(region.ptr + page * 2 - size));
        api.version = 1;
        api.size = @intCast(size);
        try std.testing.expect(acceleration.protocolInfo(api) == null);
        try std.testing.expect(acceleration.protocolWork(api) == null);
    }
}
test "old or null R4DEV extension preserves caller output and callback" {
    var raw: a.R4XStartContext = .{};
    var table: a.R4XStartR4Dev = .{};
    var bundle: program.Bundle = .{ .raw = &raw, .dev = &table };
    const ctx = program.Context.initBundle(&bundle);
    var info: a.CpuAccelerationInfo = .{ .epoch = 0xabcd };
    var receipt: a.CpuAccelerationWork = .{ .begin_ns = 0xabcd };
    const prior_info = info;
    const prior_work = receipt;
    for ([_]u32{ 704, 720 }) |size| {
        table.size = size;
        try std.testing.expectEqual(a.err_no_fn, ctx.cpuAccelerationInfo(&info));
        try std.testing.expectEqual(a.err_no_fn, ctx.cpuAccelerationWork(1, 8, leaf.callback, 0, &receipt));
        try std.testing.expectEqualSlices(u8, std.mem.asBytes(&prior_info), std.mem.asBytes(&info));
        try std.testing.expectEqualSlices(u8, std.mem.asBytes(&prior_work), std.mem.asBytes(&receipt));
    }
}
