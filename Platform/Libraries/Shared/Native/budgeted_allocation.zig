// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
pub const Budget = @import("budget.zig").Budget;

/// Native C allocations carry their original budget through cross-worker free
/// and realloc. The backing allocator and budget outlive all their allocations.
/// Exhaustion returns null; it never terminates a worker inside FFmpeg cleanup.
pub const Allocator = struct {
    backing: std.mem.Allocator,
    const Header = struct {
        magic: u64,
        owner: *Allocator,
        budget: *Budget,
        raw: [*]u8,
        charged: usize,
        requested: usize,
        alignment: usize,
    };
    const live: u64 = 0x52345649414C4C31;

    pub fn allocate(self: *Allocator, budget: *Budget, bytes: usize, alignment: usize) ?*anyopaque {
        if (alignment == 0 or !std.math.isPowerOfTwo(alignment)) return null;
        const aligned = @max(alignment, @alignOf(Header));
        const overhead = std.math.add(usize, @sizeOf(Header), aligned - 1) catch return null;
        const total = std.math.add(usize, @max(bytes, 1), overhead) catch return null;
        if (!budget.reserve(total)) return null;
        const raw = self.backing.rawAlloc(total, .fromByteUnits(@alignOf(Header)), @returnAddress()) orelse {
            budget.release(total);
            return null;
        };
        const address = std.mem.alignForward(usize, @intFromPtr(raw) + @sizeOf(Header), aligned);
        const header: *Header = @ptrFromInt(address - @sizeOf(Header));
        header.* = .{ .magic = live, .owner = self, .budget = budget, .raw = raw, .charged = total, .requested = bytes, .alignment = aligned };
        return @ptrFromInt(address);
    }
    fn describe(self: *Allocator, pointer: *anyopaque) *Header {
        const header: *Header = @ptrFromInt(@intFromPtr(pointer) - @sizeOf(Header));
        if (header.magic != live or header.owner != self) @trap();
        return header;
    }
    pub fn free(self: *Allocator, pointer: ?*anyopaque) void {
        const header = self.describe(pointer orelse return);
        const budget = header.budget;
        const raw = header.raw;
        const total = header.charged;
        header.magic = 0;
        self.backing.rawFree(raw[0..total], .fromByteUnits(@alignOf(Header)), @returnAddress());
        budget.release(total);
    }
    pub fn resize(self: *Allocator, pointer: *anyopaque, bytes: usize) ?*anyopaque {
        const header = self.describe(pointer);
        if (bytes == 0) {
            self.free(pointer);
            return null;
        }
        // Reserve the temporary overlap too. Failure leaves the old object and
        // its accounting intact, regardless of the caller's current stream.
        const next = self.allocate(header.budget, bytes, header.alignment) orelse return null;
        const copied = @min(bytes, header.requested);
        @memcpy(@as([*]u8, @ptrCast(next))[0..copied], @as([*]const u8, @ptrCast(pointer))[0..copied]);
        self.free(pointer);
        return next;
    }
};
