//! Private callback input for the existing VM heap. The mapped form copies
//! only resident callbacks admitted from the real generation2 table. It is
//! neither a Query1 table nor an owner, allocator or registry of its own.
const std = @import("std");
const abi = @import("r4os_contract").abi;
const abi2 = @import("r4os_contract2");

pub const Memory = extern struct {
    version: u32 = 1,
    size: u32 = @sizeOf(Memory),
    generation: u32 = 2,
    flags: u32 = 0,
    identity: u64 = 0,
    vm_reserve: u64 = 0,
    vm_commit: u64 = 0,
    vm_decommit: u64 = 0,
    vm_release: u64 = 0,
    notification_create: u64 = 0,
    notification_query: u64 = 0,
    notification_notify: u64 = 0,
    notification_wait: u64 = 0,
    notification_close: u64 = 0,
    sleep_ticks: u64 = 0,
    task_yield: u64 = 0,
    thread_current_handle: u64 = 0,
    program_exit: u64 = 0,

    pub fn valid(self: *const Memory) bool {
        return self.version == 1 and self.size >= @sizeOf(Memory) and
            self.generation == 2 and self.flags == 0 and self.identity != 0 and self.identity % 8 == 0;
    }

    pub fn fromContext2(context: anytype) Memory {
        return fromSystem2(context.system() orelse return .{});
    }

    /// Shared native libraries may retain the immutable actual SYS2 table,
    /// independently of the caller's temporary Context2 view.
    pub fn fromSystem2(table: *const abi2.R4XStartR4Sys2) Memory {
        var out: Memory = .{};
        const Table = @TypeOf(table.*);
        const expected: Table = .{};
        if (table.magic != expected.magic or table.abi_version < 1 or table.size < 16) return out;
        out.identity = @intFromPtr(table);
        inline for (std.meta.fields(Memory)) |field| {
            if (comptime @hasDecl(abi.R4SysFns, field.name) and @hasField(Table, field.name)) {
                const offset = @offsetOf(Table, field.name);
                if (offset + 8 <= table.size and @addWithOverflow(@intFromPtr(table), offset + 8)[1] == 0)
                    @field(out, field.name) = @field(table.*, field.name);
            }
        }
        return out;
    }
};

/// One machine word in allocator wait state. Bit0 describes this SDK-private
/// pointer only; every real dereference first removes the tag. Both inputs
/// have 8-byte alignment. No mapped record is interpreted as a platform table.
pub const Source = struct {
    encoded: usize,

    pub fn system2(table: *const @import("r4os_contract2").R4XStartR4Sys2) Source {
        return .{ .encoded = @intFromPtr(table) };
    }
    pub fn mapped(record: *const Memory) Source {
        return .{ .encoded = @intFromPtr(record) | 1 };
    }
    pub fn from(raw: anytype) Source {
        const T = @TypeOf(raw);
        if (T == Source) return raw;
        if (T == *const @import("r4os_contract2").R4XStartR4Sys2 or T == *@import("r4os_contract2").R4XStartR4Sys2) return system2(raw);
        if (T == *const Memory or T == *Memory) return mapped(raw);
        @compileError("allocator input must name its actual platform source");
    }
    pub fn optional(raw: anytype) ?Source {
        if (@TypeOf(raw) == @TypeOf(null)) return null;
        if (@typeInfo(@TypeOf(raw)) == .optional) return if (raw) |value| from(value) else null;
        return from(raw);
    }
    pub fn toOpaque(self: Source) *anyopaque {
        return @ptrFromInt(self.encoded);
    }
    pub fn fromOpaque(pointer: *anyopaque) Source {
        return .{ .encoded = @intFromPtr(pointer) };
    }
    pub fn table2(self: Source) ?*const @import("r4os_contract2").R4XStartR4Sys2 {
        if (self.encoded == 0 or self.encoded & 1 != 0) return null;
        return @ptrFromInt(self.encoded);
    }
    pub fn memory(self: Source) ?*const Memory {
        if (self.encoded & 1 == 0) return null;
        return @ptrFromInt(self.encoded & ~@as(usize, 1));
    }
    pub fn identity(self: Source) usize {
        if (self.table2()) |table| return @intFromPtr(table);
        return @intCast(self.memory().?.identity | 1);
    }
    pub fn function(self: Source, comptime field: []const u8) ?@field(abi.R4SysFns, field) {
        const address: u64 = if (self.table2()) |table| blk: {
            if (table.magic != (abi2.R4XStartR4Sys2{}).magic or
                table.size < @offsetOf(@import("r4os_contract2").R4XStartR4Sys2, field) + 8) return null;
            break :blk @field(table.*, field);
        } else blk: {
            const value = self.memory() orelse return null;
            if (!value.valid()) return null;
            break :blk @field(value.*, field);
        };
        return if (address == 0) null else @ptrFromInt(address);
    }
    pub fn supportsVm(self: Source) bool {
        // Direct table loans and copied callback records use the same current provider.
        if (self.table2()) |table| {
            if (table.magic != (abi2.R4XStartR4Sys2{}).magic or table.size < @sizeOf(abi2.R4XStartR4Sys2)) return false;
        }
        return self.function("vm_reserve") != null and self.function("vm_commit") != null and
            self.function("vm_decommit") != null and self.function("vm_release") != null;
    }
    pub fn supportsNotifications(self: Source) bool {
        return self.function("notification_create") != null and self.function("notification_query") != null and
            self.function("notification_notify") != null and self.function("notification_wait") != null and
            self.function("notification_close") != null;
    }
    pub fn call(self: Source, comptime field: []const u8) @field(abi.R4SysFns, field) {
        return self.function(field).?;
    }
};

comptime {
    if (@sizeOf(Memory) != 128 or @alignOf(Memory) != 8 or @sizeOf(Source) != @sizeOf(usize))
        @compileError("allocator source layout");
}
