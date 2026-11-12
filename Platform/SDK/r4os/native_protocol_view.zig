//! Native dispatch records, never wire decoding or a memory/owner probe.
//! Caller retains valid native representation and exclusive output storage
//! through dispatch. Views never extend that loan or acknowledge quiescence.
//! Header offsets designate actual initialized native u32 fields, not padding.
const std = @import("std");
const abi = @import("r4os_contract").abi;
pub const Error = error{ NullBuffer, TooShort, LengthMismatch, Misaligned, UnsupportedVersion, InvalidHeaderSize, InvalidDirection, InvalidFlags, InvalidPolicy, LengthOverflow };
pub const Direction = enum(u32) { input = 0, output = 1, inout = 2 };
pub const SizeMode = enum(u32) { exact = 0, prefix = 1 };
pub const no_field = std.math.maxInt(u32);
pub const Policy = extern struct {
    required_bytes: usize,
    alignment: usize,
    version_offset: u32 = no_field,
    size_offset: u32 = no_field,
    expected_version: u32 = 0,
    size_mode: u32 = 0,
    direction: u32 = 0,
    allowed_flags: u32 = 0,
    pub fn record(comptime T: type, direction: Direction, mode: SizeMode) Policy {
        return .{ .required_bytes = @sizeOf(T), .alignment = @alignOf(T), .direction = @intFromEnum(direction), .size_mode = @intFromEnum(mode) };
    }
    pub fn versioned(comptime T: type, version: u32, direction: Direction, mode: SizeMode) Policy {
        if (@FieldType(T, "version") != u32 or @FieldType(T, "size") != u32) @compileError("Native version and size must be u32");
        var result = record(T, direction, mode);
        result.version_offset = @offsetOf(T, "version");
        result.size_offset = @offsetOf(T, "size");
        result.expected_version = version;
        return result;
    }
    fn validate(self: Policy) Error!void {
        if (self.required_bytes == 0 or self.alignment == 0 or !std.math.isPowerOfTwo(self.alignment) or self.size_mode > 1 or self.direction > 2) return error.InvalidPolicy;
        for ([_]u32{ self.version_offset, self.size_offset }) |offset| {
            if (offset == no_field) continue;
            if (offset > self.required_bytes or @sizeOf(u32) > self.required_bytes - offset) return error.InvalidPolicy;
        }
    }
};
fn readNativeU32(address: usize, offset: u32) u32 {
    var value: u32 = undefined;
    const source: [*]const u8 = @ptrFromInt(address + offset);
    @memcpy(std.mem.asBytes(&value), source[0..4]);
    return value;
}
fn header(address: usize, available: usize, policy: Policy) Error!void {
    if (policy.version_offset != no_field and readNativeU32(address, policy.version_offset) != policy.expected_version) return error.UnsupportedVersion;
    if (policy.size_offset != no_field) {
        const declared = readNativeU32(address, policy.size_offset);
        if (declared < policy.required_bytes or declared > available or (policy.size_mode == 0 and declared != policy.required_bytes)) return error.InvalidHeaderSize;
    }
}
/// Bounds/alignment/metadata only. Valid mapped initialized native data is a
/// caller precondition; transport flags do not authorize checksum offload.
pub fn admit(buffer: *const abi.ProtocolBuffer, policy: Policy, direction: Direction) Error!usize {
    try policy.validate();
    if (policy.direction != @intFromEnum(direction)) return error.InvalidDirection;
    if (buffer.reserved != 0 or buffer.flags & ~policy.allowed_flags != 0) return error.InvalidFlags;
    if (buffer.len > buffer.capacity) return error.LengthMismatch;
    const data = buffer.data orelse return error.NullBuffer;
    const address = @intFromPtr(data);
    _ = std.math.add(usize, address, buffer.capacity) catch return error.LengthOverflow;
    if (address % policy.alignment != 0) return error.Misaligned;
    const available = if (direction == .output) buffer.capacity else buffer.len;
    if (available < policy.required_bytes) return error.TooShort;
    if (direction != .output) {
        if (policy.size_mode == 0 and available != policy.required_bytes) return error.LengthMismatch;
        try header(address, available, policy);
    }
    return address;
}
/// Caller really initialized written bytes. Only those bytes are inspected;
/// len is published after success. No unwritten output bytes are read.
pub fn publish(buffer: *abi.ProtocolBuffer, policy: Policy, written: u32) Error!void {
    const address = try admit(buffer, policy, .output);
    if (written < policy.required_bytes or written > buffer.capacity or (policy.size_mode == 0 and written != policy.required_bytes)) return error.LengthMismatch;
    try header(address, written, policy);
    buffer.len = written;
}
pub fn Input(comptime T: type) type {
    return struct {
        value: *const T,
        /// Caller guarantees valid initialized native T representation and an
        /// immutable dispatch loan; a byte span alone is insufficient.
        pub fn init(buffer: *const abi.ProtocolBuffer, policy: Policy) Error!@This() {
            if (policy.required_bytes != @sizeOf(T) or policy.alignment < @alignOf(T)) return error.InvalidPolicy;
            return .{ .value = @ptrFromInt(try admit(buffer, policy, .input)) };
        }
    };
}
pub fn InOut(comptime T: type) type {
    return struct {
        value: *T,
        /// Caller retains exclusive valid native T and metadata through return.
        pub fn init(buffer: *abi.ProtocolBuffer, policy: Policy) Error!@This() {
            if (policy.required_bytes != @sizeOf(T) or policy.alignment < @alignOf(T)) return error.InvalidPolicy;
            return .{ .value = @ptrFromInt(try admit(buffer, policy, .inout)) };
        }
    };
}
pub fn Output(comptime T: type) type {
    return struct {
        buffer: *abi.ProtocolBuffer,
        policy: Policy,
        const Self = @This();
        /// Payload may be uninitialized. Metadata/storage remain separate,
        /// exclusive and stable during dispatch. T is a native POD record.
        pub fn init(buffer: *abi.ProtocolBuffer, policy: Policy) Error!Self {
            if (policy.required_bytes != @sizeOf(T) or policy.alignment < @alignOf(T) or @sizeOf(T) > std.math.maxInt(u32)) return error.InvalidPolicy;
            _ = try admit(buffer, policy, .output);
            return .{ .buffer = buffer, .policy = policy };
        }
        pub fn write(self: Self, value: T) Error!void {
            var candidate = value;
            var candidate_policy = self.policy;
            candidate_policy.direction = @intFromEnum(Direction.input);
            candidate_policy.alignment = @alignOf(T);
            candidate_policy.size_mode = 0;
            candidate_policy.allowed_flags = 0;
            const candidate_buffer: abi.ProtocolBuffer = .{ .data = &candidate, .len = @sizeOf(T), .capacity = @sizeOf(T) };
            _ = try admit(&candidate_buffer, candidate_policy, .input);
            const address = try admit(self.buffer, self.policy, .output);
            @as(*T, @ptrFromInt(address)).* = candidate;
            self.buffer.len = @intCast(@sizeOf(T));
        }
    };
}

test "wire owner native admission alignment version prefix direction and output initialization" {
    const Record = extern struct { version: u32 = 1, size: u32 = 16, value: u64 = 0 };
    var record: Record = .{ .value = 0x1234 };
    var buffer: abi.ProtocolBuffer = .{ .data = &record, .len = 16, .capacity = 16 };
    const policy = Policy.versioned(Record, 1, .input, .exact);
    try std.testing.expectEqual(@as(u64, 0x1234), (try Input(Record).init(&buffer, policy)).value.value);
    buffer.len = 15;
    try std.testing.expectError(error.TooShort, Input(Record).init(&buffer, policy));
    buffer.len = 16;
    buffer.data = @ptrFromInt(@intFromPtr(&record) + 1);
    try std.testing.expectError(error.Misaligned, Input(Record).init(&buffer, policy));
    buffer.data = &record;
    record.version = 2;
    try std.testing.expectError(error.UnsupportedVersion, Input(Record).init(&buffer, policy));
    record.version = 1;
    buffer.flags = 1;
    try std.testing.expectError(error.InvalidFlags, Input(Record).init(&buffer, policy));
    buffer.flags = 0;
    try std.testing.expectError(error.InvalidDirection, admit(&buffer, policy, .output));
    var extended: extern struct { first: Record, tail: u64 } = .{ .first = .{ .size = 24, .value = 7 }, .tail = 9 };
    buffer = .{ .data = &extended, .len = 24, .capacity = 24 };
    try std.testing.expectError(error.LengthMismatch, Input(Record).init(&buffer, policy));
    var prefix = policy;
    prefix.size_mode = 1;
    try std.testing.expectEqual(@as(u64, 7), (try Input(Record).init(&buffer, prefix)).value.value);
    var output: Record = undefined;
    buffer = .{ .data = &output, .capacity = 16 };
    const out = try Output(Record).init(&buffer, Policy.versioned(Record, 1, .output, .exact));
    try std.testing.expectError(error.UnsupportedVersion, out.write(.{ .version = 2 }));
    try std.testing.expectEqual(@as(u32, 0), buffer.len);
    try out.write(.{ .value = 55 });
    try std.testing.expectEqual(@as(u32, 16), buffer.len);
    try std.testing.expectEqual(@as(u64, 55), output.value);
}
