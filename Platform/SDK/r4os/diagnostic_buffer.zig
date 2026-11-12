//! Caller-owned complete UTF8 records; one synchronous sink callback per step.
//! Prefix acceptance is byte-based and may split a scalar. Unknown acceptance
//! is sticky: no automatic replay, peer acknowledgement or persistence claim.
const std = @import("std");
pub const Error = error{ InvalidBuffer, InvalidState, Busy, InvalidText, InvalidSeverity, Aliasing, InvalidBudget, LengthOverflow };
pub const Severity = enum(u32) { debug = 0, info = 1, warning = 2, err = 3 };
pub const AppendKind = enum(u32) { accepted = 0, full = 1, record_too_large = 2 };
pub const AppendResult = extern struct { kind: u32, accepted_records: u32, required_bytes: u64 };
pub const SinkKind = enum(u32) { accepted = 0, would_block = 1, failed = 2, uncertain = 3 };
pub const Ack = extern struct { accepted_bytes: u32 = 0, kind: u32 = 0, error_code: i32 = 0, reserved: u32 = 0 };
pub const Chunk = extern struct { data: [*]const u8, length: u32, total: u32, offset: u32, severity: u32 };
pub const Sink = *const fn (?*anyopaque, *const Chunk) callconv(.c) Ack;
pub const FlushKind = enum(u32) { empty = 0, progress = 1, would_block = 2, failed = 3, uncertain = 4, poisoned = 5, invalid_sink = 6 };
pub const FlushResult = extern struct { kind: u32, accepted_bytes: u32 = 0, completed_records: u32 = 0, error_code: i32 = 0 };
pub const DiscardResult = extern struct { records: u64, pending_bytes: u64, known_first_prefix: u32, uncertain: u32 };
pub const Stats = extern struct {
    queued_records: u64,
    pending_bytes: u64,
    appended_records: u64,
    rejected_records: u64,
    rejected_input_bytes: u64,
    sent_records: u64,
    sent_bytes: u64,
    counters_saturated: u32,
    poison: u32,
};
const header_bytes: usize = 8;
const Frame = struct { length: u32, severity: u32 };
fn number(data: []const u8) u32 {
    return std.mem.readInt(u32, @as(*const [4]u8, @ptrCast(data.ptr)), .little);
}
fn putNumber(data: []u8, value: u32) void {
    std.mem.writeInt(u32, @as(*[4]u8, @ptrCast(data.ptr)), value, .little);
}
pub const BoundedDiagnosticBuffer = extern struct {
    address: usize,
    capacity: usize,
    head: usize = 0,
    tail: usize = 0,
    offset: u32 = 0,
    busy: u32 = 0,
    poison: u32 = 0, // invalid ack1, explicitly uncertain acceptance2
    counters_saturated: u32 = 0,
    queued_records: u64 = 0,
    pending_bytes: u64 = 0,
    appended_records: u64 = 0,
    rejected_records: u64 = 0,
    rejected_input_bytes: u64 = 0,
    sent_records: u64 = 0,
    sent_bytes: u64 = 0,
    const Self = @This();
    /// Caller keeps the storage separate from state and exclusively borrowed
    /// through every callback return. No callback may retain chunk pointers.
    pub fn init(storage: []u8) Error!Self {
        const result = Self{ .address = @intFromPtr(storage.ptr), .capacity = storage.len };
        try result.validate();
        return result;
    }
    fn bytes(self: *const Self) []u8 {
        if (self.capacity == 0) return &.{};
        return @as([*]u8, @ptrFromInt(self.address))[0..self.capacity];
    }
    fn first(self: *const Self) Error!Frame {
        if (self.head > self.tail or self.tail - self.head < header_bytes) return error.InvalidState;
        const data = self.bytes()[self.head..self.tail];
        const frame = Frame{ .length = number(data[0..4]), .severity = number(data[4..8]) };
        if (frame.severity > 3 or frame.length > data.len - header_bytes or self.offset > frame.length or
            (frame.length != 0 and self.offset == frame.length) or self.pending_bytes < frame.length - self.offset) return error.InvalidState;
        return frame;
    }
    fn validate(self: *const Self) Error!void {
        if (self.capacity > std.math.maxInt(u32) or (self.capacity != 0 and self.address == 0)) return error.InvalidBuffer;
        _ = std.math.add(usize, self.address, self.capacity) catch return error.LengthOverflow;
        if (self.head > self.tail or self.tail > self.capacity or self.busy > 1 or self.poison > 2 or self.counters_saturated > 1) return error.InvalidState;
        if (self.head == self.tail) {
            if (self.offset != 0 or self.queued_records != 0 or self.pending_bytes != 0) return error.InvalidState;
        } else {
            const live = self.tail - self.head;
            if (self.queued_records == 0 or self.queued_records > live / header_bytes or self.pending_bytes > live - self.queued_records * header_bytes) return error.InvalidState;
            _ = try self.first();
        }
    }
    fn addCounter(self: *Self, target: *u64, amount: u64) void {
        target.* = std.math.add(u64, target.*, amount) catch {
            self.counters_saturated = 1;
            target.* = std.math.maxInt(u64);
            return;
        };
    }
    fn rejected(self: *Self, kind: AppendKind, required: usize, length: usize) AppendResult {
        self.addCounter(&self.rejected_records, 1);
        self.addCounter(&self.rejected_input_bytes, length);
        return .{ .kind = @intFromEnum(kind), .accepted_records = 0, .required_bytes = required };
    }
    /// All-or-zero record admission. Oversized requests are rejected without
    /// inspecting their text, and rejection counters count input requests.
    /// Input overlapping this queue is explicitly rejected before compaction.
    pub fn appendRecord(self: *Self, text: []const u8, severity: Severity) Error!AppendResult {
        try self.validate();
        if (self.busy != 0) return error.Busy;
        const required = std.math.add(usize, text.len, header_bytes) catch return error.LengthOverflow;
        const source = @intFromPtr(text.ptr);
        const source_end = std.math.add(usize, source, text.len) catch return error.LengthOverflow;
        if (text.len != 0 and self.capacity != 0 and source < self.address + self.capacity and self.address < source_end) return error.Aliasing;
        if (required > self.capacity) return self.rejected(.record_too_large, required, text.len);
        if (!std.unicode.utf8ValidateSlice(text)) return error.InvalidText;
        const live = self.tail - self.head;
        if (required > self.capacity - live) return self.rejected(.full, required, text.len);
        const data = self.bytes();
        if (required > self.capacity - self.tail) {
            std.mem.copyForwards(u8, data[0..live], data[self.head..self.tail]);
            self.head = 0;
            self.tail = live;
        }
        const destination = data[self.tail..][0..required];
        @memcpy(destination[header_bytes..], text);
        putNumber(destination[0..4], @intCast(text.len));
        putNumber(destination[4..8], @intFromEnum(severity));
        self.tail += required;
        self.queued_records += 1;
        self.pending_bytes += text.len;
        self.addCounter(&self.appended_records, 1);
        return .{ .kind = @intFromEnum(AppendKind.accepted), .accepted_records = 1, .required_bytes = required };
    }
    /// One bounded synchronous callback. Actual accepted byte prefixes are
    /// retained even on a known failure. Empty records still call the sink.
    pub fn flushOnce(self: *Self, max_bytes: u32, sink: Sink, context: ?*anyopaque) Error!FlushResult {
        try self.validate();
        if (self.busy != 0) return error.Busy;
        if (max_bytes == 0 or max_bytes > std.math.maxInt(i32)) return error.InvalidBudget;
        if (self.poison != 0) return .{ .kind = @intFromEnum(FlushKind.poisoned) };
        if (self.queued_records == 0) return .{ .kind = @intFromEnum(FlushKind.empty) };
        const frame = try self.first();
        const count = @min(frame.length - self.offset, max_bytes);
        const chunk = Chunk{ .data = self.bytes()[self.head + header_bytes + self.offset ..].ptr, .length = count, .total = frame.length, .offset = self.offset, .severity = frame.severity };
        self.busy = 1;
        const ack = sink(context, &chunk);
        self.busy = 0;
        if (ack.reserved != 0 or ack.kind > 3 or ack.accepted_bytes > count) {
            self.poison = 1;
            return .{ .kind = @intFromEnum(FlushKind.invalid_sink), .error_code = ack.error_code };
        }
        self.offset += ack.accepted_bytes;
        self.pending_bytes -= ack.accepted_bytes;
        self.addCounter(&self.sent_bytes, ack.accepted_bytes);
        const complete = self.offset == frame.length and (frame.length != 0 or ack.kind == @intFromEnum(SinkKind.accepted));
        if (complete) {
            self.head += header_bytes + frame.length;
            self.offset = 0;
            self.queued_records -= 1;
            self.addCounter(&self.sent_records, 1);
            if (self.queued_records == 0) {
                self.head = 0;
                self.tail = 0;
            }
        }
        const outcome: FlushKind = switch (@as(SinkKind, @enumFromInt(ack.kind))) {
            .accepted => if (ack.accepted_bytes == 0 and !complete) .would_block else .progress,
            .would_block => .would_block,
            .failed => .failed,
            .uncertain => outcome: {
                self.poison = 2;
                break :outcome .uncertain;
            },
        };
        return .{ .kind = @intFromEnum(outcome), .accepted_bytes = ack.accepted_bytes, .completed_records = @intFromBool(complete), .error_code = ack.error_code };
    }
    pub fn stats(self: *const Self) Error!Stats {
        try self.validate();
        return .{ .queued_records = self.queued_records, .pending_bytes = self.pending_bytes, .appended_records = self.appended_records, .rejected_records = self.rejected_records, .rejected_input_bytes = self.rejected_input_bytes, .sent_records = self.sent_records, .sent_bytes = self.sent_bytes, .counters_saturated = self.counters_saturated, .poison = self.poison };
    }
    /// Explicit local discard, not a cancellation or sink/device stop receipt.
    /// Pending bytes are locally unaccepted, not a guessed external loss count.
    pub fn discard(self: *Self) Error!DiscardResult {
        try self.validate();
        if (self.busy != 0) return error.Busy;
        const result = DiscardResult{ .records = self.queued_records, .pending_bytes = self.pending_bytes, .known_first_prefix = self.offset, .uncertain = @intFromBool(self.poison != 0) };
        self.head = 0;
        self.tail = 0;
        self.offset = 0;
        self.queued_records = 0;
        self.pending_bytes = 0;
        self.poison = 0;
        return result;
    }
};

test "cli owner diagnostic whole UTF8 record admission and explicit capacity loss" {
    var storage: [22]u8 = undefined;
    var buffer = try BoundedDiagnosticBuffer.init(&storage);
    try std.testing.expectEqual(@as(u32, 1), (try buffer.appendRecord("€", .info)).accepted_records);
    _ = try buffer.appendRecord("abc", .warning);
    const before = storage;
    const full = try buffer.appendRecord("", .debug);
    try std.testing.expectEqual(@intFromEnum(AppendKind.full), full.kind);
    try std.testing.expectEqualDeep(before, storage);
    try std.testing.expectError(error.InvalidText, buffer.appendRecord("\xff", .info));
    const info = try buffer.stats();
    try std.testing.expectEqual(@as(u64, 2), info.queued_records);
    try std.testing.expectEqual(@as(u64, 6), info.pending_bytes);
    try std.testing.expectEqual(@as(u64, 1), info.rejected_records);
    var empty = try BoundedDiagnosticBuffer.init(&.{});
    try std.testing.expectEqual(@intFromEnum(AppendKind.record_too_large), (try empty.appendRecord("", .info)).kind);
}
test "cli owner diagnostic byte prefixes across UTF8 and actual empty record acknowledgement" {
    const Probe = struct {
        output: [3]u8 = undefined,
        offset: usize = 0,
        calls: usize = 0,
        fn write(raw: ?*anyopaque, chunk: *const Chunk) callconv(.c) Ack {
            const self: *@This() = @ptrCast(@alignCast(raw.?));
            self.calls += 1;
            const count = @min(chunk.length, if (self.offset == 0) @as(u32, 1) else @as(u32, 2));
            @memcpy(self.output[self.offset..][0..count], chunk.data[0..count]);
            self.offset += count;
            return .{ .accepted_bytes = count };
        }
    };
    var storage: [32]u8 = undefined;
    var buffer = try BoundedDiagnosticBuffer.init(&storage);
    _ = try buffer.appendRecord("€", .info);
    _ = try buffer.appendRecord("", .debug);
    var probe: Probe = .{};
    try std.testing.expectEqual(@as(u32, 1), (try buffer.flushOnce(8, Probe.write, &probe)).accepted_bytes);
    try std.testing.expectEqual(@as(u64, 2), (try buffer.stats()).pending_bytes);
    try std.testing.expectEqual(@as(u32, 1), (try buffer.flushOnce(8, Probe.write, &probe)).completed_records);
    try std.testing.expectEqual(@as(u32, 1), (try buffer.flushOnce(8, Probe.write, &probe)).completed_records);
    try std.testing.expectEqualStrings("€", &probe.output);
    try std.testing.expectEqual(@as(usize, 3), probe.calls);
    const info = try buffer.stats();
    try std.testing.expectEqual(@as(u64, 2), info.sent_records);
    try std.testing.expectEqual(@as(u64, 3), info.sent_bytes);
}
test "cli owner diagnostic unknown invalid acknowledgement no replay and explicit discard" {
    const Probe = struct {
        calls: usize = 0,
        bad: bool = false,
        fn write(raw: ?*anyopaque, chunk: *const Chunk) callconv(.c) Ack {
            const self: *@This() = @ptrCast(@alignCast(raw.?));
            self.calls += 1;
            return if (self.bad) .{ .accepted_bytes = chunk.length + 1 } else .{ .accepted_bytes = 1, .kind = @intFromEnum(SinkKind.uncertain), .error_code = -99 };
        }
    };
    var storage: [24]u8 = undefined;
    var buffer = try BoundedDiagnosticBuffer.init(&storage);
    _ = try buffer.appendRecord("abc", .err);
    var probe: Probe = .{};
    const uncertain = try buffer.flushOnce(8, Probe.write, &probe);
    try std.testing.expectEqual(@intFromEnum(FlushKind.uncertain), uncertain.kind);
    try std.testing.expectEqual(@as(u32, 1), uncertain.accepted_bytes);
    try std.testing.expectEqual(@intFromEnum(FlushKind.poisoned), (try buffer.flushOnce(8, Probe.write, &probe)).kind);
    try std.testing.expectEqual(@as(usize, 1), probe.calls);
    const discarded = try buffer.discard();
    try std.testing.expectEqual(@as(u64, 2), discarded.pending_bytes);
    try std.testing.expectEqual(@as(u32, 1), discarded.known_first_prefix);
    try std.testing.expectEqual(@as(u32, 1), discarded.uncertain);
    _ = try buffer.appendRecord("z", .info);
    probe.bad = true;
    try std.testing.expectEqual(@intFromEnum(FlushKind.invalid_sink), (try buffer.flushOnce(8, Probe.write, &probe)).kind);
    try std.testing.expectEqual(@as(u64, 1), (try buffer.stats()).pending_bytes);
    try std.testing.expectEqual(@as(u32, 1), (try buffer.discard()).uncertain);
}
test "cli owner diagnostic compaction alias reentry and saturated counters" {
    const Probe = struct {
        buffer: *BoundedDiagnosticBuffer,
        output: [8]u8 = undefined,
        length: usize = 0,
        busy_rejected: bool = false,
        fn write(raw: ?*anyopaque, chunk: *const Chunk) callconv(.c) Ack {
            const self: *@This() = @ptrCast(@alignCast(raw.?));
            _ = self.buffer.appendRecord("x", .info) catch |err| {
                self.busy_rejected = err == error.Busy;
                @memcpy(self.output[self.length..][0..chunk.length], chunk.data[0..chunk.length]);
                self.length += chunk.length;
                return .{ .accepted_bytes = chunk.length };
            };
            return .{ .kind = @intFromEnum(SinkKind.failed), .error_code = -1 };
        }
    };
    var storage: [24]u8 = undefined;
    var buffer = try BoundedDiagnosticBuffer.init(&storage);
    _ = try buffer.appendRecord("aa", .info);
    _ = try buffer.appendRecord("bb", .info);
    var probe: Probe = .{ .buffer = &buffer };
    _ = try buffer.flushOnce(8, Probe.write, &probe);
    const before = buffer;
    try std.testing.expectError(error.Aliasing, buffer.appendRecord(storage[buffer.head + header_bytes ..][0..2], .info));
    try std.testing.expectEqualDeep(before, buffer);
    _ = try buffer.appendRecord("cccc", .info);
    buffer.sent_bytes = std.math.maxInt(u64) - 1;
    _ = try buffer.flushOnce(8, Probe.write, &probe);
    _ = try buffer.flushOnce(8, Probe.write, &probe);
    try std.testing.expectEqualStrings("aabbcccc", &probe.output);
    try std.testing.expect(probe.busy_rejected);
    const info = try buffer.stats();
    try std.testing.expectEqual(std.math.maxInt(u64), info.sent_bytes);
    try std.testing.expectEqual(@as(u32, 1), info.counters_saturated);
}
