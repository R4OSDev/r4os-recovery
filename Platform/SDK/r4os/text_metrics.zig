//! One bounded preparation, then immutable grapheme-prefix hits in O(log n).
const std = @import("std");
const abi = @import("r4os_contract").abi;
const grapheme = @import("r4std_grapheme");
const wire = @import("binary_cursor.zig");
pub const Error = error{ InvalidState, InvalidStorage, Busy, Incomplete, Stale };
pub const flag_complete: u32 = 1;
pub const flag_in_call: u32 = 2;
pub const invalid_provider: i32 = -105;
pub const Provider = extern struct { measure: ?abi.R4DrawFns.font_prefix_metrics2 = null };
pub const Key = extern struct {
    source_address: u64 = 0,
    text_revision: u64 = 0,
    font_revision: u64 = 0,
    font_id: u32 = 0,
    text_bytes: u32 = 0,
};
pub const Progress = extern struct {
    key: Key,
    required_count: u32,
    count: u32,
    flags: u32,
    error_code: i32,
};
pub fn overlaps(a: wire.Span, b: wire.Span) bool {
    return a.length != 0 and b.length != 0 and a.address < b.address + b.length and b.address < a.address + a.length;
}
pub const Cache = extern struct {
    // Private original scalar receipt; storage is subsequently projected to
    // graphemes. Only progress()/view() grant the final cache row authority.
    native_info: abi.FontAdvanceInfo2 = .{},
    source: wire.Span,
    storage: wire.Span,
    provider: Provider,
    text_revision: u64 = 0,
    capacity: u32,
    count: u32 = 0,
    phase: u32 = 0,
    busy: u32 = 0,
    error_code: i32 = 0,
    reserved0: u32 = 0,

    pub fn init(source: wire.Span, storage: wire.Span, capacity: u32, provider: Provider) Error!Cache {
        const result = Cache{ .source = source, .storage = storage, .capacity = capacity, .provider = provider };
        try result.validateStorage();
        return result;
    }
    fn validateStorage(self: *const Cache) Error!void {
        self.source.validate() catch return error.InvalidStorage;
        self.storage.validate() catch return error.InvalidStorage;
        if (self.source.length > abi.font_metrics2_max_bytes or self.capacity > abi.font_metrics2_max_bytes or
            @as(usize, self.capacity) * @sizeOf(abi.FontAdvance2) > self.storage.length or
            self.capacity != 0 and self.storage.address % @alignOf(abi.FontAdvance2) != 0 or
            overlaps(self.source, self.storage)) return error.InvalidStorage;
    }
    fn validate(self: *const Cache) Error!void {
        try self.validateStorage();
        const own = wire.Span{ .address = @intFromPtr(self), .length = @sizeOf(Cache) };
        own.validate() catch return error.InvalidStorage;
        if (overlaps(own, self.source) or overlaps(own, self.storage)) return error.InvalidStorage;
        if (self.phase > 1 or self.busy > 1 or self.reserved0 != 0 or self.count > self.capacity) return error.InvalidState;
        if (self.phase == 1 and (self.busy != 0 or self.error_code != 0 or !self.validInfo(self.native_info) or
            self.native_info.flags != abi.font_metrics2_flag_complete or self.native_info.count != self.native_info.required_count or
            self.count > self.native_info.count)) return error.InvalidState;
    }
    fn validInfo(self: *const Cache, info: abi.FontAdvanceInfo2) bool {
        return info.version == abi.font_metrics2_version and info.size == @sizeOf(abi.FontAdvanceInfo2) and
            info.font_revision != 0 and info.text_bytes == self.source.length and info.required_count <= self.source.length and
            info.count <= self.capacity and info.reserved0 == 0 and info.flags & ~abi.font_metrics2_flag_complete == 0;
    }
    fn observedKey(self: *const Cache) Key {
        return .{ .source_address = self.source.address, .text_revision = self.text_revision, .font_revision = self.native_info.font_revision, .font_id = self.native_info.font_id, .text_bytes = @intCast(self.source.length) };
    }
    pub fn progress(self: *const Cache) Error!Progress {
        try self.validate();
        return .{ .key = self.observedKey(), .required_count = self.native_info.required_count, .count = self.count, .flags = (if (self.phase == 1) flag_complete else @as(u32, 0)) | (if (self.busy != 0) flag_in_call else @as(u32, 0)), .error_code = self.error_code };
    }
    fn finish(self: *Cache, code: i32, complete: bool) Error!Progress {
        self.error_code = code;
        self.phase = @intFromBool(complete);
        self.busy = 0; // Actual provider return AND projection have completed.
        return self.progress();
    }
    pub fn prepare(self: *Cache, text_revision: u64, font_id: u32) Error!Progress {
        try self.validate();
        if (self.busy != 0) return error.Busy;
        self.phase = 0;
        self.count = 0;
        self.error_code = 0;
        self.text_revision = text_revision;
        self.native_info = .{ .font_id = font_id, .text_bytes = @intCast(self.source.length) };
        const source = self.source.bytes() catch return error.InvalidStorage;
        if (!std.unicode.utf8ValidateSlice(source) or std.mem.indexOfScalar(u8, source, 0) != null) return self.finish(abi.font_metrics2_encoding, false);
        const call = self.provider.measure orelse return self.finish(abi.err_no_fn, false);
        var info: abi.FontAdvanceInfo2 = .{};
        const input: ?[*]const u8 = if (source.len == 0) null else source.ptr;
        const output: ?[*]abi.FontAdvance2 = if (self.capacity == 0) null else @ptrFromInt(self.storage.address);
        self.busy = 1;
        defer self.busy = 0;
        const code = call(font_id, input, @intCast(source.len), output, self.capacity, &info);
        if (code == abi.font_metrics2_capacity) {
            if (!self.validInfo(info) or info.font_id != font_id or info.count != 0 or info.flags != 0 or info.required_count <= self.capacity) return self.finish(invalid_provider, false);
            self.native_info = info;
            return self.finish(code, false);
        }
        if (code != 0) return self.finish(code, false);
        if (!self.validInfo(info) or info.font_id != font_id or info.flags != abi.font_metrics2_flag_complete or info.count != info.required_count or
            (info.count == 0) != (source.len == 0)) return self.finish(invalid_provider, false);
        self.native_info = info;
        if (info.count == 0) return self.finish(0, true);
        const data_rows: [*]abi.FontAdvance2 = @ptrFromInt(self.storage.address);
        var scalar = (std.unicode.Utf8View.init(source) catch return self.finish(invalid_provider, false)).iterator();
        var byte_end: usize = 0;
        var index: usize = 0;
        var width: u32 = 0;
        while (scalar.nextCodepointSlice()) |part| {
            byte_end += part.len;
            if (index >= info.count or data_rows[index].byte_end != byte_end or data_rows[index].prefix_width < width) return self.finish(invalid_provider, false);
            width = data_rows[index].prefix_width;
            index += 1;
        }
        if (index != info.count) return self.finish(invalid_provider, false);
        var clusters = grapheme.Iterator{ .bytes = source };
        var read: usize = 0;
        while (clusters.next() catch return self.finish(invalid_provider, false)) |range| {
            if (source[range.start] == '\n') break; // Exact original Canvas rule, including CRLF.
            while (read < info.count and data_rows[read].byte_end < range.end) read += 1;
            if (read == info.count or data_rows[read].byte_end != range.end) return self.finish(invalid_provider, false);
            var row = data_rows[read];
            row.prefix_width = @min(row.prefix_width, std.math.maxInt(i32));
            data_rows[self.count] = row;
            self.count += 1;
            read += 1;
        }
        return self.finish(0, true);
    }
    pub fn key(self: *const Cache) Error!Key {
        try self.validate();
        if (self.phase != 1) return error.Incomplete;
        return self.observedKey();
    }
    pub fn view(self: *const Cache) Error!wire.Span {
        _ = try self.key();
        return .{ .address = self.storage.address, .length = @as(usize, self.count) * @sizeOf(abi.FontAdvance2) };
    }
    pub fn rows(self: *const Cache) Error![]const abi.FontAdvance2 {
        const span = try self.view();
        if (span.length == 0) return &.{};
        return @as([*]const abi.FontAdvance2, @ptrFromInt(span.address))[0..self.count];
    }
    pub fn hit(self: *const Cache, expected: Key, x: i32) Error!u32 {
        const actual = try self.key();
        if (!std.meta.eql(expected, actual)) return error.Stale;
        const values = try self.rows();
        if (x <= 0 or values.len == 0) return 0;
        var low: usize = 0;
        var high: usize = values.len;
        while (low < high) {
            const mid = low + (high - low) / 2;
            if (values[mid].prefix_width <= @as(u32, @intCast(x))) low = mid + 1 else high = mid;
        }
        if (low == values.len) return values[values.len - 1].byte_end;
        const previous_end: u32 = if (low == 0) 0 else values[low - 1].byte_end;
        const previous_width: u32 = if (low == 0) 0 else values[low - 1].prefix_width;
        const threshold = previous_width + (values[low].prefix_width - previous_width) / 2;
        return if (@as(u32, @intCast(x)) < threshold) previous_end else values[low].byte_end;
    }
    pub fn reset(self: *Cache) Error!void {
        try self.validate();
        if (self.busy != 0) return error.Busy;
        self.phase = 0;
        self.count = 0;
        self.error_code = 0;
        self.native_info = .{};
    }
};
