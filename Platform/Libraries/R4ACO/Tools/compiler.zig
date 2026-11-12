// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
//! Offline Linux host frontend to the same bounded compiler used by R4ACO.R4L.
//! Output is committed only after joining the disposable compilation worker.
const std = @import("std");
const c = @import("r4l_contract");
const compiler = @import("compiler_runtime");
const Job = struct {
    request: c.R4AcoRequest = undefined,
    result: c.R4AcoBinary = std.mem.zeroes(c.R4AcoBinary),
    code: [1024 * 1024]u8 = undefined,
    log: [65536]u8 = @splat(0),
    status: i32 = c.status_compiler,
    live: u64 = 0,
    fn get(raw: u64) *Job { return @ptrFromInt(raw); }
    fn allocate(raw: u64, bytes: u64, alignment: u64) callconv(.c) u64 {
        const ptr = std.heap.page_allocator.rawAlloc(bytes, .fromByteUnits(alignment), @returnAddress()) orelse return 0;
        get(raw).live += bytes; return @intFromPtr(ptr);
    }
    fn release(raw: u64, address: u64, bytes: u64, alignment: u64) callconv(.c) void {
        std.heap.page_allocator.rawFree(@as([*]u8, @ptrFromInt(address))[0..bytes], .fromByteUnits(alignment), @returnAddress());
        get(raw).live -= bytes;
    }
    fn clock(_: u64) callconv(.c) u64 {
        var ts: std.os.linux.timespec = undefined;
        if (std.os.linux.clock_gettime(.MONOTONIC, &ts) != 0) @trap();
        return @as(u64, @intCast(ts.sec)) * 1_000_000_000 + @as(u64, @intCast(ts.nsec));
    }
    fn abortWorker(raw: u64, status: i32) callconv(.c) void {
        get(raw).status = status;
        std.os.linux.exit(0);
    }
    fn retired(_: u64, _: u64) callconv(.c) u32 { return 0; }
    fn run(self: *Job) void {
        const runtime: c.R4AcoRuntime = .{ .version = 1, .size = @sizeOf(c.R4AcoRuntime),
            .user = @intFromPtr(self), .owner_generation = 1, .allocate = @intFromPtr(&allocate),
            .release = @intFromPtr(&release), .clock_ns = @intFromPtr(&clock), .abort_worker = @intFromPtr(&abortWorker),
            .owner_retired = @intFromPtr(&retired), .cancelled = 0 };
        self.status = compiler.r4aco_compile_impl(&runtime, &self.request, &self.result);
    }
};
pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len != 6 and args.len != 7) {
        std.debug.print("Usage: r4aco-compiler <input.spv> <stage 0/4/5> <resource ABI 1/2> <output.bin> <output.json> [external ASIC revision, default 0x41]\n", .{});
        return error.Arguments;
    }
    const stage = try std.fmt.parseInt(u32, args[2], 10);
    const resource_abi = try std.fmt.parseInt(u32, args[3], 10);
    const revision = if (args.len == 7) try std.fmt.parseInt(u32, args[6], 0) else 0x41;
    if (resource_abi < 1 or resource_abi > 2) return error.Arguments;
    const cwd = std.Io.Dir.cwd();
    const bytes = try cwd.readFileAlloc(init.io, args[1], init.gpa, .limited(65536));
    defer init.gpa.free(bytes);
    if (bytes.len == 0 or bytes.len % 4 != 0) return error.InvalidSpirv;
    const words = try init.gpa.alloc(u32, bytes.len / 4); defer init.gpa.free(words);
    for (words, 0..) |*word, i| word.* = std.mem.readInt(u32, bytes[i * 4..][0..4], .little);
    const job = try init.gpa.create(Job); defer init.gpa.destroy(job); job.* = .{};
    job.request = .{ .version = 1, .size = @sizeOf(c.R4AcoRequest), .stage = stage, .device_id = 0x15d8,
        .chip_revision = revision, .flags = resource_abi - 1, .word_count = @intCast(words.len), .entry_length = 4,
        .words = @intFromPtr(words.ptr), .entry = @intFromPtr("main"), .budget_bytes = 256 * 1024 * 1024,
        .deadline_ns = Job.clock(0) + 30_000_000_000, .code = @intFromPtr(&job.code), .code_capacity = job.code.len,
        .log_capacity = job.log.len, .log = @intFromPtr(&job.log) };
    const thread = try std.Thread.spawn(.{ .stack_size = 4 * 1024 * 1024 }, Job.run, .{job}); thread.join();
    if (job.live != 0) return error.UnreleasedCompilerMemory;
    if (job.status != 0) {
        std.debug.print("R4ACO failed ({d}): {s}\n", .{ job.status, job.log[0..job.result.log_length] });
        return error.CompileFailed;
    }
    const code = job.code[0..job.result.code_bytes];
    var digest: [32]u8 = undefined; std.crypto.hash.sha2.Sha256.hash(code, &digest, .{});
    const metadata = try std.json.Stringify.valueAlloc(init.gpa, .{ .schema = 1,
        .code_sha256 = std.fmt.bytesToHex(digest, .lower), .binary = job.result }, .{ .whitespace = .indent_2 });
    defer init.gpa.free(metadata);
    try cwd.writeFile(init.io, .{ .sub_path = args[4], .data = code });
    try cwd.writeFile(init.io, .{ .sub_path = args[5], .data = metadata });
    std.debug.print("R4ACO compiled {s}: {d} bytes, {d} SGPR/{d} VGPR, ABI {d}.\n", .{
        args[1], code.len, job.result.sgprs, job.result.vgprs, job.result.resource_abi });
}
