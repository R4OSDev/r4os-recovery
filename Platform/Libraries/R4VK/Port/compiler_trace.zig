// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Opt-in, process-owned diagnostic. No caller storage is retained in R4L BSS.
const std = @import("std");
const a = @import("r4os").abi;
const threads = @import("r4native").threads;

fn function(comptime name: []const u8) @field(a.R4SysFns, name) {
    return threads.system.required(name);
}

pub const State = struct {
    prefix: [8]u8 = @splat(0),
    length: usize = 0,
    sequence: std.atomic.Value(u32) = .init(0),
    jobs: std.atomic.Value(u32) = .init(0),
    failed: std.atomic.Value(bool) = .init(false),

    pub fn init(self: *State) void {
        self.* = .{};
        const count = function("env_get")("R4VK_COMPILER_TRACE", &self.prefix, self.prefix.len);
        if (count < 1 or count > self.prefix.len) return;
        for (self.prefix[0..@intCast(count)]) |c| {
            if (!std.ascii.isAlphanumeric(c)) return;
        }
        self.length = @intCast(count);
    }

    pub fn nextJob(self: *State) u32 {
        return if (self.length == 0) 0 else self.jobs.fetchAdd(1, .monotonic) + 1;
    }

    // Bounded sampling: first sixteen jobs and subsequent powers of two.
    // Writes have unique filenames, exact lengths and a flushed finish.
    pub fn mark(self: *State, job: u32, comptime label: []const u8, value: i64) void {
        if (self.length == 0 or job == 0 or (job > 16 and !std.math.isPowerOfTwo(job)) or
            self.failed.load(.acquire)) return;
        const sequence = self.sequence.fetchAdd(1, .monotonic);
        if (sequence >= 512) return;
        var path_buffer: [64]u8 = undefined;
        const path = std.fmt.bufPrintZ(&path_buffer, "C:\\TEMP\\{s}{d:0>4}.LOG", .{ self.prefix[0..self.length], sequence }) catch unreachable;
        var text_buffer: [256]u8 = undefined;
        const text = std.fmt.bufPrint(&text_buffer, "R4VK-CT25 seq={d} job={d} thread={d} {s} value={d}\r\n", .{
            sequence, job, function("thread_current")(), label, value,
        }) catch unreachable;
        const created = function("file_stream_begin")(path, a.file_stream_open_create);
        if (created == 0) {
            const written = function("file_stream_write")(path, 0, text.ptr, @intCast(text.len), 0);
            if (written == @as(i32, @intCast(text.len)) and function("file_stream_finish")(path, text.len, 0) == 0) {
                _ = function("write")(text.ptr, @intCast(text.len));
                return;
            }
            _ = function("file_stream_abort")(path);
        }
        self.failed.store(true, .release);
        const failure = "R4VK-CT25 TRACE-FAILED; compiler behavior unchanged\r\n";
        _ = function("write")(failure.ptr, failure.len);
    }
};
