// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const gpu = @import("gpu_resources");
pub fn Implementation(comptime ff: type) type {
    return union(enum) {
        const Self = @This();
        nvidia: @import("gpu_decoder.zig").Implementation(ff),
        amd: @import("amd_decoder.zig").Implementation(ff),
        pub fn init(ctx: gpu.Context) Self {
            return switch (ctx.device.provider) {
                .nvidia => .{ .nvidia = .{ .ctx = ctx } },
                .amd => .{ .amd = .{ .ctx = ctx } },
            };
        }
        pub fn ops(self: *Self) ff.struct_r4video_nvdec_ops {
            return switch (self.*) {
                inline else => |*d| d.ops(),
            };
        }
        pub fn describe(self: *Self, ptr: ?*anyopaque) ?*const gpu.Resource {
            return switch (self.*) {
                inline else => |*d| d.describe(ptr),
            };
        }
        pub fn reap(self: *Self) !void {
            switch (self.*) {
                inline else => |*d| try d.reap(),
            }
        }
        pub fn close(self: *Self) !void {
            switch (self.*) {
                inline else => |*d| try d.close(),
            }
        }
        pub fn flush(self: *Self) void {
            switch (self.*) {
                inline else => |*d| d.flush(),
            }
        }
        pub fn pendingRetirement(self: *const Self) bool {
            return switch (self.*) {
                inline else => |*d| d.pendingRetirement(),
            };
        }
    };
}
