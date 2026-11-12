// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const m = @import("native_allocation");
const Budget = m.Budget;
const Allocator = m.Allocator;

fn contender(allocator: *Allocator, budget: *Budget) void {
    for (0..64) |i| {
        const pointer = allocator.allocate(budget, 65 + i, 64) orelse continue;
        std.debug.assert(@intFromPtr(pointer) % 64 == 0);
        std.debug.assert(budget.liveBytes() <= budget.limit);
        std.debug.assert(budget.parent.?.liveBytes() <= budget.parent.?.limit);
        const bytes: [*]u8 = @ptrCast(pointer);
        @memset(bytes[0 .. 65 + i], @intCast(i));
        std.Thread.yield() catch {};
        allocator.free(pointer);
    }
}

test "concurrent decoder budgets, failed growth and cross-worker retirement" {
    try @import("gpu_resources.zig").run();
    try @import("playback.zig").run();
    var root: Budget = .{ .limit = 1024 };
    var first: Budget = .{ .limit = 768, .parent = &root };
    var second: Budget = .{ .limit = 768, .parent = &root };
    var allocator: Allocator = .{ .backing = std.testing.allocator };
    // A leaf failure must roll back the aggregate reservation.
    try std.testing.expect(!first.reserve(769));
    try std.testing.expectEqual(@as(usize, 0), root.liveBytes());
    try std.testing.expect(first.reserve(700));
    try std.testing.expect(!second.reserve(325));
    try std.testing.expectEqual(@as(usize, 0), second.liveBytes());
    first.release(700);

    const pointer = allocator.allocate(&first, 128, 64).?;
    const bytes: [*]u8 = @ptrCast(pointer);
    @memset(bytes[0..128], 0xa5);
    const held = root.liveBytes();
    try std.testing.expect(allocator.resize(pointer, 768) == null);
    try std.testing.expectEqual(held, root.liveBytes());
    try std.testing.expectEqual(held, first.liveBytes());
    try std.testing.expect(allocator.allocate(&first, std.math.maxInt(usize), 16) == null);
    try std.testing.expect(allocator.allocate(&first, 8, 0) == null);
    try std.testing.expectEqual(held, root.liveBytes());
    const grown = allocator.resize(pointer, 192).?;
    try std.testing.expect(@intFromPtr(grown) % 64 == 0);
    for (@as([*]const u8, @ptrCast(grown))[0..128]) |byte| try std.testing.expectEqual(@as(u8, 0xa5), byte);
    const cleanup = try std.Thread.spawn(.{}, Allocator.free, .{ &allocator, grown });
    cleanup.join();
    try std.testing.expectEqual(@as(usize, 0), root.liveBytes());

    var workers: [4]std.Thread = undefined;
    var started: usize = 0;
    defer for (workers[0..started]) |worker| worker.join();
    for (&workers, 0..) |*worker, index| {
        worker.* = try std.Thread.spawn(.{}, contender, .{ &allocator, if (index % 2 == 0) &first else &second });
        started += 1;
    }
    for (workers) |worker| worker.join();
    started = 0;
    try std.testing.expectEqual(@as(usize, 0), root.liveBytes());
    try std.testing.expectEqual(@as(usize, 0), first.liveBytes());
    try std.testing.expectEqual(@as(usize, 0), second.liveBytes());
    // Backing-allocator exhaustion must also leave both budgets unchanged.
    var storage: [1]u8 = undefined;
    var empty = std.heap.FixedBufferAllocator.init(&storage);
    var failing: Allocator = .{ .backing = empty.allocator() };
    try std.testing.expect(failing.allocate(&second, 64, 16) == null);
    try std.testing.expectEqual(@as(usize, 0), root.liveBytes());
    try std.testing.expectEqual(@as(usize, 0), second.liveBytes());
}
