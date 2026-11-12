//! Produktive R4S-Implementierung der Runtime-R4L R4STD.
const std = @import("std");
const text_contract = @import("text.zig");

pub const Bytes = text_contract.Bytes;
pub const Utf8Text = text_contract.Utf8Text;
pub const SystemText = text_contract.SystemText;
pub const DocumentText = text_contract.DocumentText;
pub const UiText8 = text_contract.UiText8;

pub fn parseUtf8Text(bytes: []const u8) text_contract.Error!text_contract.Utf8Text {
    return text_contract.Utf8Text.init(bytes);
}

pub fn parseSystemText(bytes: []const u8) text_contract.Error!text_contract.SystemText {
    return text_contract.SystemText.parse(bytes);
}

pub fn canonicalizeSystemText(bytes: []const u8, out: []u8) text_contract.Error![]const u8 {
    const parsed = try text_contract.SystemText.parse(bytes);
    return parsed.writeCanonical(out);
}

pub fn parseDocumentText(bytes: []const u8) text_contract.Error!text_contract.DocumentText {
    return text_contract.DocumentText.init(bytes);
}

pub fn parseUiText8(bytes: []const u8) text_contract.Error!text_contract.UiText8 {
    return text_contract.UiText8.init(bytes);
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
pub const current_format_version: u32 = 1;
pub const utf8_bom = "\xEF\xBB\xBF";

pub const Entry = struct {
    key: []const u8,
    value: []const u8,
};

pub const EntryIterator = struct {
    rest: []const u8,

    pub fn init(bytes: []const u8) EntryIterator {
        return .{ .rest = stripUtf8Bom(bytes) };
    }

    pub fn next(self: *EntryIterator) ?Entry {
        while (self.rest.len > 0) {
            const split = findByte(self.rest, '\n') orelse self.rest.len;
            var raw = self.rest[0..split];
            if (split < self.rest.len) {
                self.rest = self.rest[split + 1 ..];
            } else {
                self.rest = self.rest[split..];
            }

            raw = trim(raw);
            if (raw.len == 0 or raw[0] == '#' or raw[0] == ';') continue;
            if (parseLine(raw)) |entry| return entry;
        }
        return null;
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
    len: usize = 0,
    truncated: bool = false,

    pub fn init(out: []u8) Writer {
        if (out.len > 0) @memset(out, 0);
        return .{ .out = out };
    }

    pub fn writeHeader(self: *Writer, schema: []const u8) void {
        self.write(utf8_bom);
        self.writeComment("R4OS settings");
        self.writePairU32(format_key, current_format_version);
        self.writePair(schema_key, schema);
    }

    pub fn writeComment(self: *Writer, text: []const u8) void {
        self.write("# ");
        self.writeLineValue(text);
        self.write("\r\n");
    }

    pub fn writePair(self: *Writer, key: []const u8, value: []const u8) void {
        self.write(key);
        self.write("=");
        self.writeLineValue(value);
        self.write("\r\n");
    }

    pub fn writePairBool(self: *Writer, key: []const u8, value: bool) void {
        self.writePair(key, if (value) "ON" else "OFF");
    }

    pub fn writePairU32(self: *Writer, key: []const u8, value: u32) void {
        self.write(key);
        self.write("=");
        self.writeUnsigned(value);
        self.write("\r\n");
    }

    pub fn writePairI32(self: *Writer, key: []const u8, value: i32) void {
        self.write(key);
        self.write("=");
        self.writeSigned(value);
        self.write("\r\n");
    }

    pub fn writePairRgb24(self: *Writer, key: []const u8, value: u32) void {
        self.write(key);
        self.write("=");
        self.writeHex(value & 0x00FF_FFFF, 6);
        self.write("\r\n");
    }

    pub fn bytes(self: *const Writer) []const u8 {
        return self.out[0..@min(self.len, self.out.len)];
    }

    pub fn ok(self: *const Writer) bool {
        return !self.truncated;
    }

    fn write(self: *Writer, value: []const u8) void {
        if (value.len == 0) return;
        if (self.len >= self.out.len) {
            self.truncated = true;
            return;
        }
        const count = @min(value.len, self.out.len - self.len);
        if (count > 0) @memcpy(self.out[self.len .. self.len + count], value[0..count]);
        self.len += count;
        if (count < value.len) self.truncated = true;
    }

    fn writeLineValue(self: *Writer, value: []const u8) void {
        var end: usize = 0;
        while (end < value.len and value[end] != '\r' and value[end] != '\n') : (end += 1) {}
        self.write(value[0..end]);
    }

    fn writeUnsigned(self: *Writer, value: u32) void {
        var tmp: [10]u8 = undefined;
        var pos: usize = tmp.len;
        var n = value;
        while (true) {
            pos -= 1;
            tmp[pos] = '0' + @as(u8, @intCast(n % 10));
            n /= 10;
            if (n == 0) break;
        }
        self.write(tmp[pos..]);
    }

    fn writeSigned(self: *Writer, value: i32) void {
        if (value < 0) {
            self.write("-");
            const magnitude: u32 = @intCast(-(value + 1));
            self.writeUnsigned(magnitude + 1);
        } else {
            self.writeUnsigned(@intCast(value));
        }
    }

    fn writeHex(self: *Writer, value: u32, digits: u8) void {
        var shift: u5 = @intCast((digits - 1) * 4);
        while (true) {
            const nibble: u8 = @intCast((value >> shift) & 0xF);
            self.write(&[_]u8{if (nibble < 10) '0' + nibble else 'A' + (nibble - 10)});
            if (shift == 0) break;
            shift -= 4;
        }
    }
};

pub fn ensureSystemDirs(ctx: anytype) void {
    _ = ctx.dirCreate(paths.sys_dir);
    _ = ctx.dirCreate(paths.config_dir);
}

pub fn ensureAppDirs(ctx: anytype) void {
    ensureSystemDirs(ctx);
    _ = ctx.dirCreate(paths.apps_dir);
}

pub fn ensureDesktopDirs(ctx: anytype) void {
    _ = ctx.dirCreate(paths.r4os_dir);
    _ = ctx.dirCreate(paths.r4os_config_dir);
}

pub const WritebackDurability = enum(u8) {
    lazy,
    soon,
    sync,
};

pub const WritebackAction = enum(u8) {
    idle,
    deferred,
    saved,
    failed,
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
        return self.action == .idle or self.action == .deferred or self.action == .saved;
    }
};

pub const WritebackPolicy = struct {
    durability: WritebackDurability = .lazy,
    save_delay_ticks: u64 = 15,
    retry_delay_ticks: u64 = 100,

    pub fn forHz(durability: WritebackDurability, hz: u32) WritebackPolicy {
        return .{
            .durability = durability,
            .save_delay_ticks = ticksFromMilliseconds(hz, defaultSaveDelayMs(durability)),
            .retry_delay_ticks = ticksFromMilliseconds(hz, defaultRetryDelayMs(durability)),
        };
    }

    pub fn defaultSaveDelayMs(durability: WritebackDurability) u32 {
        return switch (durability) {
            .lazy => 150,
            .soon => 50,
            .sync => 0,
        };
    }

    pub fn defaultRetryDelayMs(durability: WritebackDurability) u32 {
        return switch (durability) {
            .lazy => 1000,
            .soon => 500,
            .sync => 250,
        };
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
        return .{ .policy = policy };
    }

    pub fn configure(self: *Writeback, policy: WritebackPolicy, now: u64) void {
        self.policy = policy;
        if (self.dirty) self.due_tick = now + policy.save_delay_ticks;
    }

    pub fn markDirty(self: *Writeback, now: u64) void {
        self.dirty = true;
        self.due_tick = now + self.policy.save_delay_ticks;
    }

    pub fn isDirty(self: *const Writeback) bool {
        return self.dirty;
    }

    pub fn isDue(self: *const Writeback, now: u64) bool {
        return self.dirty and now >= self.due_tick;
    }

    pub fn flushIfDue(self: *Writeback, now: u64, saver: anytype) WritebackFlush {
        if (!self.dirty) return .{ .action = .idle, .result_code = self.last_result };
        if (!self.isDue(now)) return .{ .action = .deferred, .result_code = self.last_result };
        return self.flushNow(now, saver);
    }

    pub fn flushNow(self: *Writeback, now: u64, saver: anytype) WritebackFlush {
        if (!self.dirty) return .{ .action = .idle, .result_code = self.last_result };
        return self.complete(now, saver.save());
    }

    pub fn complete(self: *Writeback, now: u64, result: i32) WritebackFlush {
        self.last_result = result;
        if (result >= 0) {
            const recovered = self.failure_reported;
            self.dirty = false;
            self.due_tick = 0;
            self.failures = 0;
            self.failure_reported = false;
            return .{
                .action = .saved,
                .result_code = result,
                .recovered_after_failure = recovered,
            };
        }

        const first_failure = !self.failure_reported;
        self.failures +%= 1;
        self.failure_reported = true;
        self.due_tick = now + self.policy.retry_delay_ticks;
        return .{
            .action = .failed,
            .result_code = result,
            .first_failure = first_failure,
        };
    }
};

pub fn ticksFromMilliseconds(hz: u32, ms: u32) u64 {
    if (ms == 0) return 0;
    const effective_hz: u64 = if (hz == 0) 100 else hz;
    const ticks = (effective_hz * @as(u64, ms) + 999) / 1000;
    return @max(@as(u64, 1), ticks);
}

pub fn valueOf(bytes: []const u8, key: []const u8) ?[]const u8 {
    var found: ?[]const u8 = null;
    var iter = EntryIterator.init(bytes);
    while (iter.next()) |entry| {
        if (equalsKey(entry.key, key)) found = entry.value;
    }
    return found;
}

pub fn parseLine(line: []const u8) ?Entry {
    const split = findByte(line, '=') orelse return null;
    const key = trim(line[0..split]);
    const value = trim(line[split + 1 ..]);
    if (!validKey(key)) return null;
    return .{ .key = key, .value = value };
}

pub fn parseBool(value: []const u8) ?bool {
    const text = trim(value);
    if (equalsKey(text, "1") or equalsKey(text, "ON") or equalsKey(text, "YES") or equalsKey(text, "TRUE")) return true;
    if (equalsKey(text, "0") or equalsKey(text, "OFF") or equalsKey(text, "NO") or equalsKey(text, "FALSE")) return false;
    return null;
}

pub fn parseU32(value: []const u8) ?u32 {
    const text = trim(value);
    if (text.len == 0) return null;
    var result: u32 = 0;
    for (text) |ch| {
        if (ch < '0' or ch > '9') return null;
        const digit: u32 = ch - '0';
        if (result > (std.math.maxInt(u32) - digit) / 10) return null;
        result = result * 10 + digit;
    }
    return result;
}

pub fn parseI32(value: []const u8) ?i32 {
    var text = trim(value);
    if (text.len == 0) return null;
    var negative = false;
    if (text[0] == '-') {
        negative = true;
        text = text[1..];
    } else if (text[0] == '+') {
        text = text[1..];
    }
    const magnitude = parseU32(text) orelse return null;
    if (negative) {
        if (magnitude > 2147483648) return null;
        if (magnitude == 2147483648) return std.math.minInt(i32);
        return -@as(i32, @intCast(magnitude));
    }
    if (magnitude > std.math.maxInt(i32)) return null;
    return @intCast(magnitude);
}

pub fn parseRgb24(value: []const u8) ?u32 {
    var text = trim(value);
    if (text.len >= 1 and text[0] == '#') text = text[1..];
    if (text.len >= 2 and text[0] == '0' and (text[1] == 'x' or text[1] == 'X')) text = text[2..];
    if (text.len != 6) return null;
    var color: u32 = 0;
    for (text) |ch| {
        color = (color << 4) | (hexNibble(ch) orelse return null);
    }
    return color;
}

pub fn equalsKey(a: []const u8, b: []const u8) bool {
    const aa = trim(a);
    const bb = trim(b);
    if (aa.len != bb.len) return false;
    var i: usize = 0;
    while (i < aa.len) : (i += 1) {
        if (asciiUpper(aa[i]) != asciiUpper(bb[i])) return false;
    }
    return true;
}

pub fn validKey(key: []const u8) bool {
    if (key.len == 0) return false;
    for (key) |ch| {
        if ((ch >= 'A' and ch <= 'Z') or
            (ch >= 'a' and ch <= 'z') or
            (ch >= '0' and ch <= '9') or
            ch == '_' or ch == '-' or ch == '.')
        {
            continue;
        }
        return false;
    }
    return true;
}

pub fn trim(value: []const u8) []const u8 {
    var start: usize = 0;
    var end = value.len;
    while (start < end and isSpace(value[start])) : (start += 1) {}
    while (end > start and isSpace(value[end - 1])) : (end -= 1) {}
    return value[start..end];
}

fn findByte(value: []const u8, needle: u8) ?usize {
    var i: usize = 0;
    while (i < value.len) : (i += 1) {
        if (value[i] == needle) return i;
    }
    return null;
}

fn stripUtf8Bom(bytes: []const u8) []const u8 {
    if (bytes.len >= 3 and bytes[0] == 0xEF and bytes[1] == 0xBB and bytes[2] == 0xBF) return bytes[3..];
    return bytes;
}

fn hexNibble(ch: u8) ?u32 {
    if (ch >= '0' and ch <= '9') return ch - '0';
    if (ch >= 'a' and ch <= 'f') return ch - 'a' + 10;
    if (ch >= 'A' and ch <= 'F') return ch - 'A' + 10;
    return null;
}

fn asciiUpper(ch: u8) u8 {
    if (ch >= 'a' and ch <= 'z') return ch - ('a' - 'A');
    return ch;
}

fn isSpace(ch: u8) bool {
    return ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n';
}

test "settings parser reads key value pairs and comments" {
    const bytes =
        \\# header
        \\R4S_FORMAT=1
        \\Name = Desktop
        \\; comment
        \\TASKBAR_CLOCK = on
    ;
    const doc = Document.init(bytes);
    try std.testing.expectEqualStrings("Desktop", doc.value("name").?);
    try std.testing.expect(doc.boolValue("taskbar_clock").?);
    try std.testing.expectEqual(@as(u32, 1), doc.u32Value(format_key).?);
    try std.testing.expect(doc.hasSupportedFormat());
}

test "settings parser accepts utf8 bom at file start" {
    const bytes = "\xEF\xBB\xBFR4S_FORMAT=1\r\nSCHEMA=INPUT\r\n";
    const doc = Document.init(bytes);
    try std.testing.expectEqual(@as(u32, 1), doc.u32Value(format_key).?);
    try std.testing.expectEqualStrings("INPUT", doc.value(schema_key).?);
}

test "settings parser lets the last duplicate key win" {
    const doc = Document.init(
        \\KEY=old
        \\KEY=new
    );
    try std.testing.expectEqualStrings("new", doc.value("key").?);
}

test "settings parser rejects invalid keys" {
    try std.testing.expect(parseLine("BAD KEY=value") == null);
    try std.testing.expect(parseLine("=value") == null);
}

test "settings parser handles missing empty and broken lines" {
    const doc = Document.init(
        \\BROKEN
        \\BAD KEY=value
        \\EMPTY=
        \\PATH=C:\R4OS\CONFIG\APPS\EXPLORER.R4S
    );
    try std.testing.expect(doc.value("MISSING") == null);
    try std.testing.expectEqualStrings("", doc.value("EMPTY").?);
    try std.testing.expectEqualStrings("C:\\R4OS\\CONFIG\\APPS\\EXPLORER.R4S", doc.value("PATH").?);
}

test "settings helpers parse common value types" {
    try std.testing.expectEqual(@as(?bool, true), parseBool("YES"));
    try std.testing.expectEqual(@as(?bool, false), parseBool("0"));
    try std.testing.expectEqual(@as(?u32, 12345), parseU32("12345"));
    try std.testing.expectEqual(@as(?i32, -42), parseI32("-42"));
    try std.testing.expectEqual(@as(?u32, 0x008080), parseRgb24("#008080"));
    try std.testing.expectEqual(@as(?u32, 0x008080), Document.init("COLOR=008080").rgb24Value("COLOR"));
}

test "settings writer emits canonical header and values" {
    var out: [192]u8 = .{0} ** 192;
    var writer = Writer.init(out[0..]);
    writer.writeHeader("DESKTOP");
    writer.writePairRgb24("DESKTOP_BG", 0x008080);
    writer.writePairBool("TASKBAR_CLOCK", true);
    writer.writePairI32("UTC_OFFSET_MINUTES", -60);
    const bytes = writer.bytes();

    try std.testing.expect(writer.ok());
    try std.testing.expect(std.mem.startsWith(u8, bytes, utf8_bom));
    try std.testing.expect(std.mem.indexOf(u8, bytes, "R4S_FORMAT=1") != null);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "SCHEMA=DESKTOP") != null);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "DESKTOP_BG=008080") != null);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "TASKBAR_CLOCK=ON") != null);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "UTC_OFFSET_MINUTES=-60") != null);

    const doc = Document.init(bytes);
    try std.testing.expect(doc.hasSupportedFormat());
    try std.testing.expectEqualStrings("DESKTOP", doc.schemaName().?);
    try std.testing.expectEqual(@as(?u32, 0x008080), doc.rgb24Value("DESKTOP_BG"));
}

test "settings writer reports truncation" {
    var out: [12]u8 = .{0} ** 12;
    var writer = Writer.init(out[0..]);
    writer.writePair("LONG_KEY", "LONG_VALUE");
    try std.testing.expect(!writer.ok());
}

test "settings directory helper calls expected directories" {
    const Fake = struct {
        calls: [3][]const u8 = .{ "", "", "" },
        count: usize = 0,

        pub fn dirCreate(self: *@This(), path: [*:0]const u8) i32 {
            if (self.count < self.calls.len) self.calls[self.count] = std.mem.span(path);
            self.count += 1;
            return 1;
        }
    };
    var fake = Fake{};
    ensureAppDirs(&fake);
    try std.testing.expectEqual(@as(usize, 3), fake.count);
    try std.testing.expectEqualStrings(paths.sys_dir, fake.calls[0]);
    try std.testing.expectEqualStrings(paths.config_dir, fake.calls[1]);
    try std.testing.expectEqualStrings(paths.apps_dir, fake.calls[2]);
}

test "settings writeback debounces and coalesces dirty saves" {
    const Saver = struct {
        calls: u32 = 0,

        pub fn save(self: *@This()) i32 {
            self.calls += 1;
            return 0;
        }
    };

    var writeback = Writeback.init(.{ .durability = .lazy, .save_delay_ticks = 5, .retry_delay_ticks = 20 });
    var saver = Saver{};

    writeback.markDirty(10);
    try std.testing.expect(writeback.isDirty());
    try std.testing.expectEqual(@as(u64, 15), writeback.due_tick);
    try std.testing.expectEqual(WritebackAction.deferred, writeback.flushIfDue(14, &saver).action);

    writeback.markDirty(12);
    try std.testing.expectEqual(@as(u64, 17), writeback.due_tick);
    try std.testing.expectEqual(WritebackAction.deferred, writeback.flushIfDue(16, &saver).action);

    const result = writeback.flushIfDue(17, &saver);
    try std.testing.expectEqual(WritebackAction.saved, result.action);
    try std.testing.expect(result.attempted());
    try std.testing.expect(result.ok());
    try std.testing.expect(!writeback.isDirty());
    try std.testing.expectEqual(@as(u32, 1), saver.calls);
}

test "settings writeback keeps dirty state and retries failed saves" {
    const Saver = struct {
        calls: u32 = 0,

        pub fn save(self: *@This()) i32 {
            self.calls += 1;
            return if (self.calls == 1) -4 else 0;
        }
    };

    var writeback = Writeback.init(.{ .durability = .soon, .save_delay_ticks = 3, .retry_delay_ticks = 11 });
    var saver = Saver{};

    writeback.markDirty(5);
    const failed = writeback.flushIfDue(8, &saver);
    try std.testing.expectEqual(WritebackAction.failed, failed.action);
    try std.testing.expectEqual(@as(i32, -4), failed.result_code);
    try std.testing.expect(failed.first_failure);
    try std.testing.expect(writeback.isDirty());
    try std.testing.expectEqual(@as(u32, 1), writeback.failures);
    try std.testing.expectEqual(@as(u64, 19), writeback.due_tick);

    try std.testing.expectEqual(WritebackAction.deferred, writeback.flushIfDue(18, &saver).action);
    const saved = writeback.flushIfDue(19, &saver);
    try std.testing.expectEqual(WritebackAction.saved, saved.action);
    try std.testing.expect(saved.recovered_after_failure);
    try std.testing.expect(!writeback.isDirty());
    try std.testing.expectEqual(@as(u32, 2), saver.calls);
}

test "settings writeback forced flush ignores debounce" {
    const Saver = struct {
        calls: u32 = 0,

        pub fn save(self: *@This()) i32 {
            self.calls += 1;
            return 7;
        }
    };

    var writeback = Writeback.init(.{ .durability = .lazy, .save_delay_ticks = 100, .retry_delay_ticks = 20 });
    var saver = Saver{};

    writeback.markDirty(1);
    const result = writeback.flushNow(2, &saver);
    try std.testing.expectEqual(WritebackAction.saved, result.action);
    try std.testing.expectEqual(@as(i32, 7), result.result_code);
    try std.testing.expect(!writeback.isDirty());
    try std.testing.expectEqual(@as(u32, 1), saver.calls);
}

test "settings writeback durability levels define stable default timing" {
    try std.testing.expectEqual(@as(u32, 150), WritebackPolicy.defaultSaveDelayMs(.lazy));
    try std.testing.expectEqual(@as(u32, 50), WritebackPolicy.defaultSaveDelayMs(.soon));
    try std.testing.expectEqual(@as(u32, 0), WritebackPolicy.defaultSaveDelayMs(.sync));
    try std.testing.expectEqual(@as(u64, 15), WritebackPolicy.forHz(.lazy, 100).save_delay_ticks);
    try std.testing.expectEqual(@as(u64, 5), WritebackPolicy.forHz(.soon, 100).save_delay_ticks);
    try std.testing.expectEqual(@as(u64, 0), WritebackPolicy.forHz(.sync, 100).save_delay_ticks);
    try std.testing.expectEqual(@as(u64, 1), ticksFromMilliseconds(100, 1));
}

test "settings exposes canonical app config paths" {
    try std.testing.expectEqualStrings("C:\\R4OS\\CONFIG\\DESKTOP.R4S", paths.desktop);
    try std.testing.expectEqualStrings("C:\\R4OS\\CONFIG\\DESKLAY.R4S", paths.desktop_layout);
    try std.testing.expectEqualStrings("C:\\R4OS\\CONFIG\\ASSOC.R4S", paths.assoc);
    try std.testing.expectEqualStrings("C:\\R4OS\\CONFIG\\APPS\\EXPLORER.R4S", paths.explorer);
    try std.testing.expectEqualStrings("C:\\R4OS\\CONFIG\\APPS\\NOTEPAD.R4S", paths.notepad);
    try std.testing.expectEqualStrings("C:\\R4OS\\CONFIG\\APPS\\PAINT.R4S", paths.paint);
}
