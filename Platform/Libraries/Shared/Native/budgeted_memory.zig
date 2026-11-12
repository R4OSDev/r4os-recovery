// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const r = @import("r4os");
const native = @import("root.zig");

pub fn Runtime(comptime Policy: type, comptime allocation: type) type {
    return struct {
        const Context = struct { heap: native.system.Heap, allocations: allocation.Allocator };
        var key: u8 = 0;
        fn initialize(value: *Context) void {
            value.heap.init();
            value.allocations = .{ .backing = value.heap.allocator() };
        }
        fn context() ?*Context {
            return native.process_local.getOrCreate(Context, &key, initialize);
        }
        pub fn malloc(bytes: usize) ?*anyopaque {
            return allocate(bytes, 16);
        }
        fn allocate(bytes: usize, alignment: usize) ?*anyopaque {
            const budget = Policy.currentBudget() orelse return null;
            const owner = context() orelse return null;
            return owner.allocations.allocate(budget, bytes, alignment);
        }
        pub fn calloc(count: usize, width: usize) ?*anyopaque {
            const bytes = std.math.mul(usize, count, width) catch return null;
            const result = malloc(bytes) orelse return null;
            @memset(@as([*]u8, @ptrCast(result))[0..bytes], 0);
            return result;
        }
        pub fn free(pointer: ?*anyopaque) void {
            if (pointer == null) return;
            const owner = context() orelse @trap();
            owner.allocations.free(pointer);
        }
        pub fn realloc(pointer: ?*anyopaque, bytes: usize) ?*anyopaque {
            if (pointer == null) return malloc(bytes);
            const owner = context() orelse return null;
            return owner.allocations.resize(pointer.?, bytes);
        }
        pub fn reallocarray(pointer: ?*anyopaque, count: usize, width: usize) ?*anyopaque {
            return realloc(pointer, std.math.mul(usize, count, width) catch return null);
        }
        pub fn aligned_alloc(alignment: usize, bytes: usize) ?*anyopaque {
            if (alignment == 0 or !std.math.isPowerOfTwo(alignment) or bytes % alignment != 0) return null;
            return allocate(bytes, alignment);
        }
        pub fn posix_memalign(output: *?*anyopaque, alignment: usize, bytes: usize) c_int {
            if (alignment < @sizeOf(usize) or !std.math.isPowerOfTwo(alignment)) return 22;
            const result = allocate(bytes, alignment) orelse return 12;
            output.* = result;
            return 0;
        }
        pub fn trim() void {
            if (context()) |owner| owner.heap.trim();
        }
    };
}
