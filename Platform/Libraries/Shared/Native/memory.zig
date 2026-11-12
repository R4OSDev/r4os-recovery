// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Per-process C allocation for a compiled native library. Optional compiler
// job scopes are a consumer policy, never an imported sibling implementation.
const std = @import("std");
const r4os = @import("r4os");
const threads = @import("threads.zig");
const local = @import("process_local.zig");

pub const Unscoped = struct {
    pub fn allocationScope() @TypeOf(null) {
        return null;
    }
    pub fn allocationFailed() noreturn {
        unreachable;
    }
};

pub fn Runtime(comptime Policy: type) type {
    return struct {
        const Context = struct { heap: threads.system.Heap };
        const Header = struct {
            magic: u64,
            owner: *Context,
            raw: [*]u8,
            raw_bytes: usize,
            bytes: usize,
            scope: ?*Scope = null,
            previous: ?*Header = null,
            next: ?*Header = null,
        };
        // An isolated CPU compiler job owns every C allocation until its exact join.
        // This ledger deliberately does not run C destructors after a failed worker:
        // its object graphs and private caches may be only partially constructed.
        pub const Scope = struct {
            head: ?*Header = null,
            live_bytes: usize = 0,
            limit_bytes: usize = std.math.maxInt(usize),

            pub fn destroy(self: *Scope) void {
                while (self.head) |header| free(@ptrFromInt(@intFromPtr(header) + @sizeOf(Header)));
                std.debug.assert(self.live_bytes == 0);
            }
        };
        const live: u64 = 0x5244564B414C4C31;
        var context_key: u8 = 0;

        fn init(owner: *Context) void {
            owner.heap.init();
        }
        fn context() ?*Context {
            return local.getOrCreate(Context, &context_key, init);
        }
        fn allocate(bytes: usize, alignment: usize, scope: ?*Scope) ?*anyopaque {
            if (alignment == 0 or !std.math.isPowerOfTwo(alignment)) return null;
            const aligned = @max(alignment, @alignOf(Header));
            const overhead = std.math.add(usize, @sizeOf(Header), aligned - 1) catch return null;
            const total = std.math.add(usize, @max(bytes, 1), overhead) catch return null;
            if (scope) |job| if (total > job.limit_bytes -| job.live_bytes) return null;
            const owner = context() orelse return null;
            const allocator = owner.heap.allocator();
            const raw = allocator.rawAlloc(total, .fromByteUnits(@alignOf(Header)), @returnAddress()) orelse return null;
            const address = std.mem.alignForward(usize, @intFromPtr(raw) + @sizeOf(Header), aligned);
            const header: *Header = @ptrFromInt(address - @sizeOf(Header));
            header.* = .{ .magic = live, .owner = owner, .raw = raw, .raw_bytes = total, .bytes = bytes, .scope = scope };
            if (scope) |job| {
                header.next = job.head;
                if (job.head) |head| head.previous = header;
                job.head = header;
                job.live_bytes += total;
            }
            return @ptrFromInt(address);
        }
        fn scopedAllocate(bytes: usize, alignment: usize) ?*anyopaque {
            const scope: ?*Scope = Policy.allocationScope();
            return allocate(bytes, alignment, scope) orelse {
                // Mesa C passes assume successful allocation in many places. Retire
                // only this isolated worker, after the heap has released its owner.
                if (scope != null) Policy.allocationFailed();
                return null;
            };
        }
        // Rust has its own arena ledger. Its backing blocks must not also enter the
        // C ledger, or failure cleanup would free the same storage twice.
        pub fn mallocUntracked(bytes: usize) ?*anyopaque {
            return allocate(bytes, 16, null);
        }
        fn describe(pointer: *anyopaque) *Header {
            const header: *Header = @ptrFromInt(@intFromPtr(pointer) - @sizeOf(Header));
            const owner = context() orelse @trap();
            if (header.magic != live or header.owner != owner) @trap();
            return header;
        }
        pub fn malloc(bytes: usize) callconv(.c) ?*anyopaque {
            return scopedAllocate(bytes, 16);
        }
        pub fn free(pointer: ?*anyopaque) callconv(.c) void {
            const address = pointer orelse return;
            const header = describe(address);
            const owner = header.owner;
            const raw = header.raw;
            const bytes = header.raw_bytes;
            if (header.scope) |job| {
                if (header.previous) |previous| previous.next = header.next else job.head = header.next;
                if (header.next) |next| next.previous = header.previous;
                job.live_bytes -= bytes;
            }
            header.magic = 0;
            owner.heap.allocator().rawFree(raw[0..bytes], .fromByteUnits(@alignOf(Header)), @returnAddress());
        }
        pub fn calloc(count: usize, width: usize) callconv(.c) ?*anyopaque {
            const bytes = std.math.mul(usize, count, width) catch {
                if (Policy.allocationScope() != null) Policy.allocationFailed();
                return null;
            };
            const pointer = malloc(bytes) orelse return null;
            @memset(@as([*]u8, @ptrCast(pointer))[0..bytes], 0);
            return pointer;
        }
        pub fn realloc(pointer: ?*anyopaque, bytes: usize) callconv(.c) ?*anyopaque {
            if (pointer == null) return malloc(bytes);
            const header = describe(pointer.?);
            if (bytes == 0) {
                free(pointer);
                return null;
            }
            const next = malloc(bytes) orelse return null; // Original remains live.
            const amount = @min(bytes, header.bytes);
            @memcpy(@as([*]u8, @ptrCast(next))[0..amount], @as([*]const u8, @ptrCast(pointer.?))[0..amount]);
            free(pointer);
            return next;
        }
        pub fn reallocarray(pointer: ?*anyopaque, count: usize, width: usize) callconv(.c) ?*anyopaque {
            const bytes = std.math.mul(usize, count, width) catch {
                if (Policy.allocationScope() != null) Policy.allocationFailed();
                return null;
            };
            return realloc(pointer, bytes);
        }
        pub fn aligned_alloc(alignment: usize, bytes: usize) callconv(.c) ?*anyopaque {
            if (alignment == 0 or !std.math.isPowerOfTwo(alignment) or bytes % alignment != 0) return null;
            return scopedAllocate(bytes, alignment);
        }
        pub fn posix_memalign(output: *?*anyopaque, alignment: usize, bytes: usize) callconv(.c) c_int {
            if (alignment < @sizeOf(usize) or !std.math.isPowerOfTwo(alignment)) return 22;
            const pointer = scopedAllocate(bytes, alignment) orelse return 12;
            output.* = pointer;
            return 0;
        }

        pub fn stats() ?r4os.vm_allocator.Stats {
            const owner = context() orelse return null;
            return owner.heap.stats();
        }
    };
}
