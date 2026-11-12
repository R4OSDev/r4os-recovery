//! Explicit borrowed DriverApi2 / ProtocolApi2 views. A table does not grant
//! another task or callback a driver/protocol owner or a hardware lifetime.
const std = @import("std");
pub const abi = @import("platform2.zig").abi;

fn View(comptime Table: type, comptime magic: u32, comptime version: u32, comptime minimum_size: usize) type {
    return struct {
        table: *const Table,
        const Self = @This();
        /// Caller retains the original immutable readable table and its exact
        /// admitted execution scope; no borrow survives module retirement.
        pub fn init(raw: ?*const Table) ?Self {
            const table = raw orelse return null;
            const address = @intFromPtr(table);
            if (address % @alignOf(Table) != 0 or @addWithOverflow(address, minimum_size)[1] != 0) return null;
            if (table.magic != magic or table.version < version or table.size < minimum_size or table.reserved != 0) return null;
            return .{ .table = table };
        }
        pub fn function(self: Self, comptime field: []const u8) ?Callback(Table, field) {
            const offset = @offsetOf(Table, field);
            const address = @intFromPtr(self.table);
            if (self.table.size < offset + @sizeOf(usize) or @addWithOverflow(address, offset + @sizeOf(usize))[1] != 0) return null;
            // Mandatory C callback types are non-null Zig pointers. Check the
            // foreign slot as an integer before constructing that pointer.
            const slot: *const usize = @ptrFromInt(address + offset);
            return if (slot.* == 0) null else @ptrFromInt(slot.*);
        }
    };
}
fn Callback(comptime Table: type, comptime field: []const u8) type {
    const F = @FieldType(Table, field);
    const P = if (@typeInfo(F) == .optional) @typeInfo(F).optional.child else F;
    if (@typeInfo(P) != .pointer or @typeInfo(@typeInfo(P).pointer.child) != .@"fn") @compileError("Technical callback field required");
    return P;
}
const driver_prefix = @offsetOf(abi.DriverApi2, "register_audio_capture_backend");
pub const Driver = View(abi.DriverApi2, abi.driver_magic, abi.driver_version, driver_prefix);
// A new SDK can use the complete original protocol2 prefix on an old kernel.
// Optional mechanisms are negotiated by per-slot size/null, never read early.
const protocol_prefix = if (@hasField(abi.ProtocolApi2, "protocol_dispatch")) @offsetOf(abi.ProtocolApi2, "protocol_dispatch") else @sizeOf(abi.ProtocolApi2);
pub const Protocol = View(abi.ProtocolApi2, abi.protocol_magic, abi.protocol_version, protocol_prefix);

pub fn driverClockSample(driver: Driver) @import("time_budget.zig").Error!@import("time_budget.zig").ClockSample {
    const callback = driver.function("monotonic_clock") orelse return error.ClockUnavailable;
    var info: abi.shared.MonotonicClockInfo = .{};
    if (callback(&info) <= 0) return error.ClockUnavailable;
    return @import("time_budget.zig").ClockSample.fromInfo(info);
}

pub fn driverEntriesAsm(comptime init: []const u8, comptime shutdown: []const u8) []const u8 {
    return std.fmt.comptimePrint(".pushsection .text.r4d_entries,\"ax\",@progbits\n.global DriverInit2\nDriverInit2:\n.byte 0xe9\n.long {s} - . - 4\n.global DriverShutdown\nDriverShutdown:\n.byte 0xe9\n.long {s} - . - 4\n.popsection\n", .{ init, shutdown });
}
pub fn protocolEntriesAsm(comptime init: []const u8, comptime shutdown: []const u8, comptime query: []const u8, comptime dispatch: []const u8) []const u8 {
    return std.fmt.comptimePrint(".pushsection .text.r4p_entries,\"ax\",@progbits\n.global ProtocolInit2\nProtocolInit2:\n.byte 0xe9\n.long {s} - . - 4\n.global ProtocolShutdown\nProtocolShutdown:\n.byte 0xe9\n.long {s} - . - 4\n.global ProtocolQuery\nProtocolQuery:\n.byte 0xe9\n.long {s} - . - 4\n.global ProtocolDispatch\nProtocolDispatch:\n.byte 0xe9\n.long {s} - . - 4\n.popsection\n", .{ init, shutdown, query, dispatch });
}

test "technical2 views reject wrong generations and short records without invoking callbacks" {
    _ = @import("driver2.zig");
    _ = @import("protocol2.zig");
    var missing: abi.DriverApi2 = undefined;
    @memset(std.mem.asBytes(&missing), 0);
    missing.magic = abi.driver_magic;
    missing.version = abi.driver_version;
    missing.size = @sizeOf(abi.DriverApi2);
    // Even a nominally mandatory C function pointer may be absent in a
    // malformed foreign record. Never construct/invoke a null Zig pointer.
    try std.testing.expect(Driver.init(&missing).?.function("log_info") == null);
    try std.testing.expect(Driver.init(@ptrFromInt(std.math.maxInt(usize) - 7)) == null);
    var driver: abi.DriverApi2 = undefined;
    driver.magic = abi.driver_magic;
    driver.version = abi.driver_version;
    driver.size = @sizeOf(abi.DriverApi2);
    driver.reserved = 0;
    try std.testing.expect(Driver.init(&driver) != null);
    driver.magic = abi.shared.driver_magic;
    try std.testing.expect(Driver.init(&driver) == null);
    driver.magic = abi.driver_magic;
    driver.size = driver_prefix - 1;
    try std.testing.expect(Driver.init(&driver) == null);
    driver.register_audio_capture_backend = @ptrFromInt(8);
    for (driver_prefix..@sizeOf(abi.DriverApi2)) |size| {
        driver.size = @intCast(size);
        const old = Driver.init(&driver) orelse return error.OriginalDriverPrefixRejected;
        try std.testing.expect(old.function("register_audio_capture_backend") == null);
    }
    driver.size = @sizeOf(abi.DriverApi2);
    try std.testing.expect(Driver.init(&driver).?.function("register_audio_capture_backend") != null);
    var protocol: abi.ProtocolApi2 = undefined;
    protocol.magic = abi.protocol_magic;
    protocol.version = abi.protocol_version;
    protocol.size = @sizeOf(abi.ProtocolApi2);
    protocol.reserved = 0;
    try std.testing.expect(Protocol.init(&protocol) != null);
    protocol.magic = abi.driver_magic;
    try std.testing.expect(Protocol.init(&protocol) == null);
    protocol.magic = abi.protocol_magic;
    protocol.version = 0;
    try std.testing.expect(Protocol.init(&protocol) == null);
    protocol.version = abi.protocol_version;
    protocol.size = protocol_prefix;
    const old = Protocol.init(&protocol) orelse return error.OriginalProtocolPrefixRejected;
    if (comptime @hasField(abi.ProtocolApi2, "link_io")) {
        try std.testing.expect(old.function("protocol_dispatch") == null);
        try std.testing.expect(old.function("link_io") == null);
        // Deliberately poison every unreadable/partial optional pointer. No
        // incomplete slot is loaded or promoted into a callable value.
        protocol.protocol_dispatch = @ptrFromInt(8);
        protocol.link_io = @ptrFromInt(16);
        protocol.process_status = @ptrFromInt(24);
        for (protocol_prefix..@sizeOf(abi.ProtocolApi2) + 1) |size| {
            protocol.size = @intCast(size);
            const partial = Protocol.init(&protocol).?;
            try std.testing.expect((partial.function("protocol_dispatch") != null) == (size >= 128));
            try std.testing.expect((partial.function("link_io") != null) == (size >= 136));
            try std.testing.expect((partial.function("process_status") != null) == (size >= 144));
        }
        protocol.size = @sizeOf(abi.ProtocolApi2);
        protocol.protocol_dispatch = null;
        protocol.link_io = null;
        protocol.process_status = null;
        const absent = Protocol.init(&protocol).?;
        try std.testing.expect(absent.function("protocol_dispatch") == null);
        try std.testing.expect(absent.function("link_io") == null);
        try std.testing.expect(absent.function("process_status") == null);
    }
}
