const std = @import("std");
const runtime = @import("runtime.zig");
const abi = runtime.abi;
const text_contract = @import("text.zig");

pub const Bytes = text_contract.Bytes;
pub const Utf8Text = text_contract.Utf8Text;
pub const SystemText = text_contract.SystemText;
pub const DocumentText = text_contract.DocumentText;
pub const UiText8 = text_contract.UiText8;

pub fn parseUtf8Text(bytes: []const u8) text_contract.Error!Utf8Text {
    return Utf8Text.init(bytes);
}

pub fn parseSystemText(bytes: []const u8) text_contract.Error!SystemText {
    return SystemText.parse(bytes);
}

pub fn canonicalizeSystemText(bytes: []const u8, out: []u8) text_contract.Error![]const u8 {
    return (try SystemText.parse(bytes)).writeCanonical(out);
}

pub fn parseDocumentText(bytes: []const u8) text_contract.Error!DocumentText {
    return DocumentText.init(bytes);
}

pub fn parseUiText8(bytes: []const u8) text_contract.Error!UiText8 {
    return UiText8.init(bytes);
}

pub const paths = struct {
    pub const sys_dir = "C:\\R4OS";
    pub const config_dir = "C:\\R4OS\\CONFIG";
    pub const apps_dir = "C:\\R4OS\\CONFIG\\APPS";
    pub const r4os_dir = "C:\\R4OS";
    pub const r4os_config_dir = "C:\\R4OS\\CONFIG";
    pub const desktop = "C:\\R4OS\\CONFIG\\DESKTOP.R4S";
    pub const desktop_layout = "C:\\R4OS\\CONFIG\\DESKLAY.R4S";
    pub const input = "C:\\R4OS\\CONFIG\\INPUT.R4S";
    pub const time = "C:\\R4OS\\CONFIG\\TIME.R4S";
    pub const assoc = "C:\\R4OS\\CONFIG\\ASSOC.R4S";
    pub const explorer = "C:\\R4OS\\CONFIG\\APPS\\EXPLORER.R4S";
    pub const notepad = "C:\\R4OS\\CONFIG\\APPS\\NOTEPAD.R4S";
    pub const paint = "C:\\R4OS\\CONFIG\\APPS\\PAINT.R4S";
};

pub const format_key = "R4S_FORMAT";
pub const schema_key = "SCHEMA";
pub const current_format_version: u32 = abi.current_format_version;
pub const utf8_bom = text_contract.utf8_bom;

pub const Entry = struct {
    key: []const u8,
    value: []const u8,
};

pub const EntryIterator = struct {
    bytes: []const u8,
    cursor: u64 = 0,

    pub fn init(bytes: []const u8) EntryIterator {
        return .{ .bytes = bytes };
    }

    pub fn next(self: *EntryIterator) ?Entry {
        if (!runtime.hasSettings()) return null;
        var range = std.mem.zeroes(abi.R4StdEntryRange);
        const status = runtime.settings().entry_next(self.bytes.ptr, self.bytes.len, &self.cursor, &range);
        if (status != abi.status_ok) return null;
        const key_offset = std.math.cast(usize, range.key_offset) orelse return null;
        const key_length = std.math.cast(usize, range.key_length) orelse return null;
        const value_offset = std.math.cast(usize, range.value_offset) orelse return null;
        const value_length = std.math.cast(usize, range.value_length) orelse return null;
        if (key_offset > self.bytes.len or key_length > self.bytes.len - key_offset) return null;
        if (value_offset > self.bytes.len or value_length > self.bytes.len - value_offset) return null;
        return .{
            .key = self.bytes[key_offset .. key_offset + key_length],
            .value = self.bytes[value_offset .. value_offset + value_length],
        };
    }
};

pub const Document = struct {
    bytes: []const u8,

    pub fn init(bytes: []const u8) Document {
        return .{ .bytes = bytes };
    }

    pub fn value(self: Document, key: []const u8) ?[]const u8 {
        return valueOf(self.bytes, key);
    }

    pub fn boolValue(self: Document, key: []const u8) ?bool {
        return if (self.value(key)) |raw| parseBool(raw) else null;
    }

    pub fn u32Value(self: Document, key: []const u8) ?u32 {
        return if (self.value(key)) |raw| parseU32(raw) else null;
    }

    pub fn i32Value(self: Document, key: []const u8) ?i32 {
        return if (self.value(key)) |raw| parseI32(raw) else null;
    }

    pub fn rgb24Value(self: Document, key: []const u8) ?u32 {
        return if (self.value(key)) |raw| parseRgb24(raw) else null;
    }

    pub fn formatVersion(self: Document) ?u32 {
        return self.u32Value(format_key);
    }

    pub fn schemaName(self: Document) ?[]const u8 {
        return self.value(schema_key);
    }

    pub fn hasSupportedFormat(self: Document) bool {
        return (self.formatVersion() orelse 0) == current_format_version;
    }
};

pub const Writer = struct {
    out: []u8,
    len: u64 = 0,
    truncated: u32 = 0,

    pub fn init(out: []u8) Writer {
        if (out.len != 0) @memset(out, 0);
        return .{ .out = out };
    }

    pub fn writeHeader(self: *Writer, schema: []const u8) void {
        self.append(abi.writer_header, "", schema, 0);
    }

    pub fn writeComment(self: *Writer, value: []const u8) void {
        self.append(abi.writer_comment, "", value, 0);
    }

    pub fn writePair(self: *Writer, key: []const u8, value: []const u8) void {
        self.append(abi.writer_pair, key, value, 0);
    }

    pub fn writePairBool(self: *Writer, key: []const u8, value: bool) void {
        self.append(abi.writer_bool, key, "", @intFromBool(value));
    }

    pub fn writePairU32(self: *Writer, key: []const u8, value: u32) void {
        self.append(abi.writer_u32, key, "", value);
    }

    pub fn writePairI32(self: *Writer, key: []const u8, value: i32) void {
        self.append(abi.writer_i32, key, "", value);
    }

    pub fn writePairRgb24(self: *Writer, key: []const u8, value: u32) void {
        self.append(abi.writer_rgb24, key, "", value);
    }

    pub fn bytes(self: *const Writer) []const u8 {
        const used = std.math.cast(usize, self.len) orelse return self.out;
        return self.out[0..@min(used, self.out.len)];
    }

    pub fn ok(self: *const Writer) bool {
        return self.truncated == 0;
    }

    fn append(self: *Writer, kind: u32, key: []const u8, value: []const u8, numeric: i64) void {
        if (!runtime.hasSettings()) {
            self.truncated = 1;
            return;
        }
        const status = runtime.settings().writer_append(
            self.out.ptr,
            self.out.len,
            &self.len,
            &self.truncated,
            kind,
            key.ptr,
            key.len,
            value.ptr,
            value.len,
            numeric,
        );
        if (status != abi.status_ok) self.truncated = 1;
    }
};

pub fn ensureSystemDirs(ctx: anytype) void {
    _ = ctx;
    ensureDirs(abi.ensure_dirs_system);
}

pub fn ensureAppDirs(ctx: anytype) void {
    _ = ctx;
    ensureDirs(abi.ensure_dirs_apps);
}

pub fn ensureDesktopDirs(ctx: anytype) void {
    _ = ctx;
    ensureDirs(abi.ensure_dirs_desktop);
}

fn ensureDirs(kind: u32) void {
    if (!runtime.hasConfig()) return;
    _ = runtime.config().ensure_dirs(runtime.rawAddress(), kind);
}

pub const WritebackDurability = enum(u8) {
    lazy = abi.durability_lazy,
    soon = abi.durability_soon,
    sync = abi.durability_sync,
};

pub const WritebackAction = enum(u8) {
    idle = abi.writeback_idle,
    deferred = abi.writeback_deferred,
    saved = abi.writeback_saved,
    failed = abi.writeback_failed,
};

pub const WritebackFlush = struct {
    action: WritebackAction = .idle,
    result_code: i32 = 0,
    first_failure: bool = false,
    recovered_after_failure: bool = false,

    pub fn attempted(self: WritebackFlush) bool {
        return self.action == .saved or self.action == .failed;
    }

    pub fn ok(self: WritebackFlush) bool {
        return self.action != .failed;
    }
};

pub const WritebackPolicy = struct {
    durability: WritebackDurability = .lazy,
    save_delay_ticks: u64 = 15,
    retry_delay_ticks: u64 = 100,

    pub fn forHz(durability: WritebackDurability, hz: u32) WritebackPolicy {
        if (!runtime.hasSettings()) return .{ .durability = durability };
        var raw = std.mem.zeroes(abi.R4StdWritebackPolicy);
        if (runtime.settings().writeback_policy(@intFromEnum(durability), hz, &raw) != abi.status_ok) return .{ .durability = durability };
        return policyFromAbi(raw) orelse .{ .durability = durability };
    }

    pub fn defaultSaveDelayMs(durability: WritebackDurability) u32 {
        if (!runtime.hasSettings()) return 0;
        return runtime.settings().writeback_default_delay(@intFromEnum(durability), 0);
    }

    pub fn defaultRetryDelayMs(durability: WritebackDurability) u32 {
        if (!runtime.hasSettings()) return 0;
        return runtime.settings().writeback_default_delay(@intFromEnum(durability), 1);
    }
};

pub const Writeback = struct {
    policy: WritebackPolicy = .{},
    dirty: bool = false,
    due_tick: u64 = 0,
    failures: u32 = 0,
    last_result: i32 = 0,
    failure_reported: bool = false,

    pub fn init(policy: WritebackPolicy) Writeback {
        var value = Writeback{ .policy = policy };
        if (!runtime.hasSettings()) return value;
        var raw = value.toAbi();
        const raw_policy = policyToAbi(policy);
        if (runtime.settings().writeback_init(&raw, &raw_policy) == abi.status_ok) value.fromAbi(raw);
        return value;
    }

    pub fn configure(self: *Writeback, policy: WritebackPolicy, now: u64) void {
        if (!runtime.hasSettings()) return;
        var raw = self.toAbi();
        const raw_policy = policyToAbi(policy);
        if (runtime.settings().writeback_configure(&raw, &raw_policy, now) == abi.status_ok) self.fromAbi(raw);
    }

    pub fn markDirty(self: *Writeback, now: u64) void {
        if (!runtime.hasSettings()) return;
        var raw = self.toAbi();
        if (runtime.settings().writeback_mark_dirty(&raw, now) == abi.status_ok) self.fromAbi(raw);
    }

    pub fn isDirty(self: *const Writeback) bool {
        return self.dirty;
    }

    pub fn isDue(self: *const Writeback, now: u64) bool {
        return self.dirty and now >= self.due_tick;
    }

    pub fn flushIfDue(self: *Writeback, now: u64, saver: anytype) WritebackFlush {
        return self.flushPrepared(now, false, saver);
    }

    pub fn flushNow(self: *Writeback, now: u64, saver: anytype) WritebackFlush {
        return self.flushPrepared(now, true, saver);
    }

    pub fn complete(self: *Writeback, now: u64, result: i32) WritebackFlush {
        if (!runtime.hasSettings()) return .{ .action = .failed, .result_code = result };
        var raw = self.toAbi();
        var flush = std.mem.zeroes(abi.R4StdWritebackFlush);
        if (runtime.settings().writeback_complete(&raw, now, result, &flush) != abi.status_ok) return .{ .action = .failed, .result_code = result };
        self.fromAbi(raw);
        return flushFromAbi(flush);
    }

    fn flushPrepared(self: *Writeback, now: u64, force: bool, saver: anytype) WritebackFlush {
        if (!runtime.hasSettings()) return .{ .action = .failed, .result_code = -1 };
        var raw = self.toAbi();
        var flush = std.mem.zeroes(abi.R4StdWritebackFlush);
        const status = runtime.settings().writeback_prepare(&raw, now, @intFromBool(force), &flush);
        if (status == abi.status_attempt) return self.complete(now, saver.save());
        if (status != abi.status_ok) return .{ .action = .failed, .result_code = status };
        self.fromAbi(raw);
        return flushFromAbi(flush);
    }

    fn toAbi(self: Writeback) abi.R4StdWriteback {
        return .{
            .durability = @intFromEnum(self.policy.durability),
            .dirty = @intFromBool(self.dirty),
            .save_delay_ticks = self.policy.save_delay_ticks,
            .retry_delay_ticks = self.policy.retry_delay_ticks,
            .due_tick = self.due_tick,
            .failures = self.failures,
            .last_result = self.last_result,
            .failure_reported = @intFromBool(self.failure_reported),
            .reserved = 0,
        };
    }

    fn fromAbi(self: *Writeback, value: abi.R4StdWriteback) void {
        self.* = .{
            .policy = policyFromAbi(.{
                .durability = value.durability,
                .reserved = 0,
                .save_delay_ticks = value.save_delay_ticks,
                .retry_delay_ticks = value.retry_delay_ticks,
            }) orelse .{},
            .dirty = value.dirty != 0,
            .due_tick = value.due_tick,
            .failures = value.failures,
            .last_result = value.last_result,
            .failure_reported = value.failure_reported != 0,
        };
    }
};

pub fn ticksFromMilliseconds(hz: u32, ms: u32) u64 {
    if (ms == 0) return 0;
    const effective_hz: u64 = if (hz == 0) 100 else hz;
    return @max(@as(u64, 1), (effective_hz * @as(u64, ms) + 999) / 1000);
}

pub fn valueOf(bytes: []const u8, key: []const u8) ?[]const u8 {
    if (!runtime.hasSettings()) return null;
    var range = std.mem.zeroes(abi.R4StdEntryRange);
    if (runtime.settings().value(bytes.ptr, bytes.len, key.ptr, key.len, &range) != abi.status_ok) return null;
    const offset = std.math.cast(usize, range.value_offset) orelse return null;
    const length = std.math.cast(usize, range.value_length) orelse return null;
    if (offset > bytes.len or length > bytes.len - offset) return null;
    return bytes[offset .. offset + length];
}

pub fn parseLine(line: []const u8) ?Entry {
    const split = std.mem.indexOfScalar(u8, line, '=') orelse return null;
    const key = trim(line[0..split]);
    const value = trim(line[split + 1 ..]);
    if (!validKey(key)) return null;
    return .{ .key = key, .value = value };
}

pub fn parseBool(value: []const u8) ?bool {
    return (parseScalar(value, abi.scalar_bool) orelse return null) != 0;
}

pub fn parseU32(value: []const u8) ?u32 {
    return std.math.cast(u32, parseScalar(value, abi.scalar_u32) orelse return null);
}

pub fn parseI32(value: []const u8) ?i32 {
    const raw = std.math.cast(u32, parseScalar(value, abi.scalar_i32) orelse return null) orelse return null;
    return @bitCast(raw);
}

pub fn parseRgb24(value: []const u8) ?u32 {
    return std.math.cast(u32, parseScalar(value, abi.scalar_rgb24) orelse return null);
}

fn parseScalar(value: []const u8, kind: u32) ?u64 {
    if (!runtime.hasSettings()) return null;
    var output: u64 = 0;
    if (runtime.settings().parse_scalar(value.ptr, value.len, kind, &output) != abi.status_ok) return null;
    return output;
}

pub fn equalsKey(left: []const u8, right: []const u8) bool {
    if (!runtime.hasSettings()) return false;
    return runtime.settings().equals_key(left.ptr, left.len, right.ptr, right.len) != 0;
}

pub fn validKey(key: []const u8) bool {
    if (key.len == 0) return false;
    for (key) |ch| {
        if ((ch >= 'A' and ch <= 'Z') or (ch >= 'a' and ch <= 'z') or (ch >= '0' and ch <= '9') or ch == '_' or ch == '-' or ch == '.') continue;
        return false;
    }
    return true;
}

pub fn trim(value: []const u8) []const u8 {
    return std.mem.trim(u8, value, " \t\r\n");
}

fn policyToAbi(value: WritebackPolicy) abi.R4StdWritebackPolicy {
    return .{
        .durability = @intFromEnum(value.durability),
        .reserved = 0,
        .save_delay_ticks = value.save_delay_ticks,
        .retry_delay_ticks = value.retry_delay_ticks,
    };
}

fn policyFromAbi(value: abi.R4StdWritebackPolicy) ?WritebackPolicy {
    return .{
        .durability = switch (value.durability) {
            abi.durability_lazy => .lazy,
            abi.durability_soon => .soon,
            abi.durability_sync => .sync,
            else => return null,
        },
        .save_delay_ticks = value.save_delay_ticks,
        .retry_delay_ticks = value.retry_delay_ticks,
    };
}

fn flushFromAbi(value: abi.R4StdWritebackFlush) WritebackFlush {
    return .{
        .action = switch (value.action) {
            abi.writeback_idle => .idle,
            abi.writeback_deferred => .deferred,
            abi.writeback_saved => .saved,
            else => .failed,
        },
        .result_code = value.result_code,
        .first_failure = value.first_failure != 0,
        .recovered_after_failure = value.recovered_after_failure != 0,
    };
}
