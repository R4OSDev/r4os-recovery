// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const t = std.testing;
const c = @import("r4l_contract");
const compiler = @import("compiler_runtime");
const cache = @import("compiler_cache");

fn words(comptime name: []const u8) [@embedFile("Fixtures/" ++ name).len / 4]u32 {
    @setEvalBranchQuota(100000);
    const bytes = @embedFile("Fixtures/" ++ name);
    var result: [bytes.len / 4]u32 = undefined;
    for (&result, 0..) |*word, i| word.* = std.mem.readInt(u32, bytes[i * 4 ..][0..4], .little);
    return result;
}
const State = struct {
    request: c.R4AcoRequest = std.mem.zeroes(c.R4AcoRequest),
    result: c.R4AcoBinary = undefined,
    code: [16384]u8 = @splat(0xcc),
    log: [8192]u8 = @splat(0),
    live: usize = 0,
    allocations: usize = 0,
    clock_value: u64 = 0,
    cancel_after: usize = std.math.maxInt(usize),
    aborted: bool = false,
    nested: bool = false,
    nested_status: i32 = 0,
    return_status: i32 = c.status_compiler,

    fn at(user: u64) *State {
        return @ptrFromInt(user);
    }
    fn allocate(user: u64, bytes: u64, alignment: u64) callconv(.c) u64 {
        const self = at(user);
        if (self.nested and self.allocations == 0) {
            var other: State = .{};
            other.request = self.request;
            other.request.code = @intFromPtr(&other.code);
            other.request.log = @intFromPtr(&other.log);
            const table = other.callbacks();
            self.nested_status = compiler.r4aco_compile_impl(&table, &other.request, &other.result);
        }
        const p = t.allocator.rawAlloc(bytes, .fromByteUnits(alignment), @returnAddress()) orelse return 0;
        self.live += bytes;
        self.allocations += 1;
        return @intFromPtr(p);
    }
    fn release(user: u64, address: u64, bytes: u64, alignment: u64) callconv(.c) void {
        const self = at(user);
        t.allocator.rawFree(@as([*]u8, @ptrFromInt(address))[0..bytes], .fromByteUnits(alignment), @returnAddress());
        self.live -= bytes;
    }
    // A deterministic clock double isolates deadline transitions from host load.
    // The SMP4 integration probe uses the real R4SYS monotonic clock.
    fn clock(user: u64) callconv(.c) u64 {
        const self = at(user);
        self.clock_value += 1;
        return self.clock_value;
    }
    fn retired(_: u64, _: u64) callconv(.c) u32 {
        return 0;
    }
    fn cancelled(user: u64) callconv(.c) u32 {
        const self = at(user);
        return @intFromBool(self.allocations >= self.cancel_after);
    }
    fn abortWorker(user: u64, status: i32) callconv(.c) void {
        const self = at(user);
        self.aborted = true;
        self.return_status = status;
        // Exit only this disposable Linux test worker; join observes CLONE_CHILD_CLEARTID.
        // No C++ unwinding or longjmp through abandoned compiler frames.
        std.os.linux.exit(0);
    }
    fn callbacks(self: *State) c.R4AcoRuntime {
        return .{ .version = 1, .size = @sizeOf(c.R4AcoRuntime), .user = @intFromPtr(self), .owner_generation = 1, .allocate = @intFromPtr(&allocate), .release = @intFromPtr(&release), .clock_ns = @intFromPtr(&clock), .abort_worker = @intFromPtr(&abortWorker), .owner_retired = @intFromPtr(&retired), .cancelled = @intFromPtr(&cancelled) };
    }
    fn configure(self: *State, spirv: []const u32, stage: u32) void {
        self.request = .{ .version = 1, .size = @sizeOf(c.R4AcoRequest), .stage = stage, .device_id = 0x15d8, .chip_revision = 0x41, .flags = 0, .word_count = @intCast(spirv.len), .entry_length = 4, .words = @intFromPtr(spirv.ptr), .entry = @intFromPtr("main"), .budget_bytes = 64 * 1024 * 1024, .deadline_ns = 0, .code = @intFromPtr(&self.code), .code_capacity = self.code.len, .log_capacity = self.log.len, .log = @intFromPtr(&self.log) };
    }
    fn entry(self: *State) void {
        const table = self.callbacks();
        self.return_status = compiler.r4aco_compile_impl(&table, &self.request, &self.result);
    }
    fn run(self: *State) !void {
        const thread = try std.Thread.spawn(.{ .stack_size = 4 * 1024 * 1024 }, entry, .{self});
        thread.join();
        if (self.return_status != 0 and self.result.log_length != 0)
            std.debug.print("ACO status {d}: {s}\n", .{ self.return_status, self.log[0..self.result.log_length] });
        try t.expectEqual(@as(usize, 0), self.live);
    }
};
fn key(binary: c.R4AcoBinary) c.R4AcoCacheKey {
    return .{ .version = 1, .size = @sizeOf(c.R4AcoCacheKey), .vendor_id = 0x1002, .device_id = 0x15d8, .chip_revision = binary.chip_revision, .gfx_profile = binary.gfx_profile, .stage = binary.stage, .resource_abi = binary.resource_abi, .command_abi = 1, .driver_version = 1, .format = 875713112, .reserved = 0, .device_generation = 1, .reset_generation = 1, .pipeline_layout = 1, .source_hash = binary.source_hash, .pipeline_hash = .{ .h0 = 1, .h1 = 2, .h2 = 3, .h3 = 4 } };
}

test "real GFX9 graphics, copy, fill and shared-memory compilation" {
    for ([_]u32{ 0x41, 0x82 }) |revision| {
    inline for (.{ .{ "fullscreen.spv", @as(u32, 0) }, .{ "color.spv", @as(u32, 4) }, .{ "copy.spv", @as(u32, 5) }, .{ "fill.spv", @as(u32, 5) }, .{ "shared.spv", @as(u32, 5) }, .{ "sample.spv", @as(u32, 4) } }) |item| {
        const source = comptime words(item[0]);
        var state: State = .{};
        state.configure(&source, item[1]);
        state.request.chip_revision = revision;
        if (comptime std.mem.eql(u8, item[0], "sample.spv")) state.request.flags = c.request_textures;
        try state.run();
        try t.expectEqual(c.status_ok, state.return_status);
        try t.expect(!state.aborted);
        try t.expectEqual(@as(u32, if (revision == 0x82) 909 else 902), state.result.gfx_profile);
        try t.expectEqual(revision, state.result.chip_revision);
        try t.expectEqual(@as(u32, 1) + state.request.flags, state.result.resource_abi);
        try t.expect(state.result.code_bytes > 20 and state.result.exec_bytes > 4);
        try t.expect(state.result.sgprs >= 16 and state.result.vgprs >= 4);
        try t.expectEqual(@as(u64, 0), state.result.inputs_read);
        try t.expectEqual(@as(u64, if (item[1] == 0) 1 else if (item[1] == 4) 16 else 0), state.result.outputs_written);
        // Independent ISA witness: every emitted executable ends in GFX9 S_ENDPGM.
        try t.expectEqual(@as(u32, 0xbf810000), std.mem.readInt(u32, state.code[state.result.exec_bytes - 4 ..][0..4], .little));
        if (comptime std.mem.eql(u8, item[0], "shared.spv")) {
            try t.expectEqual(@as(u32, 512), state.result.lds_bytes);
            try t.expectEqual(@as(u32, 128), state.result.workgroup_x);
            // A two-wave workgroup needs an actual S_BARRIER instruction.
            var barrier = false;
            var offset: usize = 0;
            while (offset < state.result.exec_bytes) : (offset += 4) {
                barrier = barrier or std.mem.readInt(u32, state.code[offset..][0..4], .little) == 0xbf8a0000;
            }
            try t.expect(barrier);
        }
        std.debug.print("GFX9 {s}: exec={d}, code={d}, sgpr={d}, vgpr={d}, lds={d}, peak={d}\n", .{ item[0], state.result.exec_bytes, state.result.code_bytes, state.result.sgprs, state.result.vgprs, state.result.lds_bytes, state.result.peak_bytes });
        var digest: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(state.code[0..state.result.code_bytes], &digest, .{});
        std.debug.print("GFX9 SHA256 {s}: {s}\n", .{ item[0], std.fmt.bytesToHex(digest, .lower) });
        std.debug.print("GFX9 CODE {s}: {x}\n", .{ item[0], state.code[0..state.result.code_bytes] });
    }
    }
}

test "compiler OOM, cooperative cancellation, deadline, busy and subsequent recovery" {
    const source = comptime words("copy.spv");
    inline for (.{ @as(u32, 0), 1, 2, 3 }) |kind| {
        var failed: State = .{};
        failed.configure(&source, 5);
        switch (kind) {
            0 => failed.request.budget_bytes = 4096,
            1 => failed.request.budget_bytes = 256 * 1024,
            2 => failed.cancel_after = 32,
            3 => failed.request.deadline_ns = 100,
            else => unreachable,
        }
        try failed.run();
        try t.expectEqual(if (kind < 2) c.status_memory else c.status_cancelled, failed.return_status);
        try t.expect(failed.aborted);
        try t.expectEqual(@as(u8, 0xcc), failed.code[0]);
        var recovered: State = .{};
        recovered.configure(&source, 5);
        recovered.nested = true;
        try recovered.run();
        try t.expectEqual(c.status_busy, recovered.nested_status);
        try t.expectEqual(c.status_ok, recovered.return_status);
    }
}

test "deterministic compiler output and cache identity, corruption and disjoint output publication" {
    const source = comptime words("copy.spv");
    var first: State = .{};
    first.configure(&source, 5);
    try first.run();
    var second: State = .{};
    second.configure(&source, 5);
    try second.run();
    try t.expectEqual(c.status_ok, first.return_status);
    try t.expectEqual(c.status_ok, second.return_status);
    try t.expectEqual(first.result.code_bytes, second.result.code_bytes);
    try t.expectEqualSlices(u8, first.code[0..first.result.code_bytes], second.code[0..second.result.code_bytes]);
    var identity = key(first.result);
    var bytes: [32768]u8 = undefined;
    var written: u64 = 0;
    try t.expectEqual(c.status_ok, cache.r4aco_cache_write_impl(&identity, &first.result, &first.code, first.result.code_bytes, &bytes, bytes.len, &written));
    var output: c.R4AcoBinary = std.mem.zeroes(c.R4AcoBinary);
    var code: [16384]u8 = @splat(0xcc);
    try t.expectEqual(c.status_ok, cache.r4aco_cache_read_impl(&identity, &bytes, written, &output, &code, code.len));
    try t.expectEqualSlices(u8, first.code[0..first.result.code_bytes], code[0..output.code_bytes]);
    const saved = output;
    inline for (.{ "chip_revision", "resource_abi", "driver_version", "reset_generation", "pipeline_layout" }) |field| {
        @field(identity, field) += 1;
        try t.expect(cache.r4aco_cache_read_impl(&identity, &bytes, written, &output, &code, code.len) != c.status_ok);
        try t.expectEqualDeep(saved, output);
        @field(identity, field) -= 1;
    }
    bytes[written - 1] ^= 1;
    try t.expectEqual(c.status_cache_miss, cache.r4aco_cache_read_impl(&identity, &bytes, written, &output, &code, code.len));
    try t.expectEqualDeep(saved, output);
    bytes[written - 1] ^= 1;
    bytes[32] ^= 1;
    try t.expectEqual(c.status_cache_miss, cache.r4aco_cache_read_impl(&identity, &bytes, written, &output, &code, code.len));
    try t.expectEqualDeep(saved, output);
    bytes[32] ^= 1;
    try t.expectEqual(c.status_invalid, cache.r4aco_cache_read_impl(&identity, &bytes, written, &output, &bytes, bytes.len));
    try t.expectEqualDeep(saved, output);
    var invalid: State = .{};
    invalid.configure(&source, 5);
    invalid.request.code = invalid.request.words;
    const callbacks = invalid.callbacks();
    try t.expectEqual(c.status_invalid, compiler.r4aco_compile_impl(&callbacks, &invalid.request, &invalid.result));
    var raven: State = .{};
    raven.configure(&source, 5); raven.request.chip_revision = 0x82;
    try raven.run(); try t.expectEqual(c.status_ok, raven.return_status);
    var raven_key = key(raven.result);
    try t.expectEqual(@as(u32, 909), raven_key.gfx_profile);
    try t.expect(!std.meta.eql(first.result.source_hash, raven.result.source_hash));
    // The Picasso artifact cannot satisfy a valid Raven2 request, even if
    // some independently compiled instruction bytes happen to be identical.
    try t.expect(cache.r4aco_cache_read_impl(&raven_key, &bytes, written, &output, &code, code.len) != c.status_ok);
    try t.expectEqualDeep(saved, output);
    try t.expectEqual(c.status_ok, cache.r4aco_cache_write_impl(&raven_key, &raven.result, &raven.code, raven.result.code_bytes, &bytes, bytes.len, &written));
    try t.expectEqual(c.status_ok, cache.r4aco_cache_read_impl(&raven_key, &bytes, written, &output, &code, code.len));
    try t.expectEqualSlices(u8, raven.code[0..raven.result.code_bytes], code[0..output.code_bytes]);
    const raven_saved = output;
    raven_key.gfx_profile = 902;
    try t.expectEqual(c.status_invalid, cache.r4aco_cache_read_impl(&raven_key, &bytes, written, &output, &code, code.len));
    try t.expectEqualDeep(raven_saved, output);
    invalid.configure(&source, 5);
    invalid.result = std.mem.zeroes(c.R4AcoBinary);
    for ([_]u32{ 0x40, 0x49, 0x80, 0x89 }) |revision| {
        invalid.request.chip_revision = revision;
        try t.expectEqual(c.status_unsupported, compiler.r4aco_compile_impl(&callbacks, &invalid.request, &invalid.result));
        try t.expectEqual(@as(usize, 0), invalid.allocations);
        try t.expectEqualDeep(std.mem.zeroes(c.R4AcoBinary), invalid.result);
    }
}
