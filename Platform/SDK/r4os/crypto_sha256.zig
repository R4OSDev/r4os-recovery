//! Streaming SHA256 with a transactional, bounded SHA-NI middle-block leaf.
//! Padding, short inputs and fallback remain the pinned standard library.
const std = @import("std");
const abi = @import("r4os_contract").abi;
const acceleration = @import("cpu_acceleration.zig");
const leaf = @import("crypto_sha256_leaf.zig");
pub fn Sha256(comptime provider: fn () ?acceleration.WorkFn) type {
    return struct {
        const Self = @This();
        pub const block_length = 64;
        pub const digest_length = 32;
        pub const Options = std.crypto.hash.sha2.Sha256.Options;
        inner: std.crypto.hash.sha2.Sha256,
        accepted_blocks: usize = 0,
        refused_windows: usize = 0,
        pub fn init(options: Options) Self {
            return .{ .inner = .init(options) };
        }
        pub fn hash(input: []const u8, out: *[32]u8, options: Options) void {
            var self = Self.init(options);
            self.update(input);
            self.final(out);
        }
        pub fn update(self: *Self, input: []const u8) void {
            if (@inComptime()) {
                self.inner.update(input);
                return;
            }
            self.updateWithExecutor(input, provider());
        }
        /// Instance-selected executor for foreign-language consumers. Every
        /// admitted batch still requires the same fresh kernel receipt.
        pub fn updateWithExecutor(self: *Self, input: []const u8, executor: ?acceleration.WorkFn) void {
            const execute = executor orelse {
                self.inner.update(input);
                return;
            };
            var offset: usize = 0;
            if (self.inner.buf_len != 0) {
                const n = @min(input.len, 64 - @as(usize, self.inner.buf_len));
                self.inner.update(input[0..n]);
                offset = n;
            }
            while (input.len - offset >= 8 * 64) {
                const blocks: u32 = @intCast(@min((input.len - offset) / 64, abi.cpu_accel_max_iterations));
                const bytes = @as(usize, blocks) * 64;
                // All writes and potentially faulting source reads precede CLI.
                // Callback sees only this task's already resident stack batch.
                var batch: leaf.Batch = .{ .state = .{ .s = self.inner.s }, .data = undefined };
                @memcpy(batch.data[0..bytes], input[offset..][0..bytes]);
                var receipt: abi.CpuAccelerationWork = .{};
                const callback: abi.CpuPureWorkFn = leaf.callback;
                if (execute(abi.cpu_accel_work_kind_sha256, blocks, &callback, @intFromPtr(&batch), &receipt) == 0 and
                    acceleration.accepted(&receipt, abi.cpu_accel_work_kind_sha256, blocks))
                {
                    self.inner.s = batch.state.s;
                    self.inner.total_len += bytes;
                    self.accepted_blocks += blocks;
                } else {
                    // A partial or rejected callback never commits staged state.
                    self.inner.update(input[offset..][0..bytes]);
                    self.refused_windows += 1;
                }
                offset += bytes;
            }
            self.inner.update(input[offset..]);
        }
        pub fn final(self: *Self, out: *[32]u8) void {
            self.inner.final(out);
        }
        pub fn finalResult(self: *Self) [32]u8 {
            return self.inner.finalResult();
        }
        pub fn peek(self: Self) [32]u8 {
            return self.inner.peek();
        }
    };
}
