const std = @import("std");
const r4os = @import("r4os");
const abi = r4os.abi;
const settings = @import("settings.zig");
const path_contract = r4os.path;

pub const name = "R4STD";

pub const max_path_len: usize = path_contract.file_path_max;
pub const max_file_bytes: usize = 4096;
pub const max_output_bytes: usize = 4096;

pub const result_ok: i32 = 0;
pub const result_defaulted: i32 = 1;
pub const result_created: i32 = 2;
pub const result_recovered: i32 = 3;

pub const error_invalid_path: i32 = -1;
pub const error_invalid_key: i32 = -2;
pub const error_buffer_too_small: i32 = -3;
pub const error_write_failed: i32 = -4;
pub const error_rename_failed: i32 = -5;
pub const error_invalid_value: i32 = -6;
pub const error_verify_failed: i32 = -7;
pub const error_recovery_failed: i32 = -8;
pub const error_read_failed: i32 = -9;

// R4SYS whole-file read: only -3 means absent; zero is an existing empty file.
const file_not_found: i32 = -3;

fn readFailure(read: i32, capacity: usize) ?i32 {
    if (read == -5 or read > @as(i32, @intCast(capacity))) return error_buffer_too_small;
    if (read < 0 and read != file_not_found) return error_read_failed;
    return null;
}

const RawRead = union(enum) {
    value: []const u8,
    defaulted,
    err: i32,
};

const ComposeResult = struct {
    code: i32,
    len: usize,
};

pub fn ok(result: i32) bool {
    return result >= 0;
}

pub fn parseFilePath(bytes: []const u8) path_contract.Error!path_contract.FilePath {
    return path_contract.FilePath.parse(bytes);
}

pub fn parseAbsoluteFilePath(bytes: []const u8) path_contract.Error!path_contract.AbsoluteFilePath {
    return path_contract.AbsoluteFilePath.parse(bytes);
}

pub fn parseRelativeFilePath(bytes: []const u8) path_contract.Error!path_contract.RelativeFilePath {
    return path_contract.RelativeFilePath.parse(bytes);
}

pub fn parseRegistryPath(bytes: []const u8) path_contract.Error!path_contract.RegistryPath {
    return path_contract.RegistryPath.parse(bytes);
}

pub fn pathsEqualIgnoreCase(a: []const u8, b: []const u8) bool {
    return path_contract.equalsIgnoreCase(a, b);
}

pub fn readString(ctx: anytype, path: [*:0]const u8, key: []const u8, fallback: []const u8, out: []u8) i32 {
    if (!validPath(path)) return error_invalid_path;
    if (!settings.validKey(key)) return error_invalid_key;

    var scratch: [max_file_bytes]u8 = undefined;
    switch (readRaw(ctx, path, key, &scratch)) {
        .value => |value| return copyResult(value, out, result_ok),
        .defaulted => return copyResult(fallback, out, result_defaulted),
        .err => |err| return err,
    }
}

pub fn readBool(ctx: anytype, path: [*:0]const u8, key: []const u8, fallback: bool, out: *bool) i32 {
    if (!validPath(path)) return error_invalid_path;
    if (!settings.validKey(key)) return error_invalid_key;

    var scratch: [max_file_bytes]u8 = undefined;
    switch (readRaw(ctx, path, key, &scratch)) {
        .value => |value| {
            if (settings.parseBool(value)) |parsed| {
                out.* = parsed;
                return result_ok;
            }
            out.* = fallback;
            return result_defaulted;
        },
        .defaulted => {
            out.* = fallback;
            return result_defaulted;
        },
        .err => |err| return err,
    }
}

pub fn readU32(ctx: anytype, path: [*:0]const u8, key: []const u8, fallback: u32, out: *u32) i32 {
    if (!validPath(path)) return error_invalid_path;
    if (!settings.validKey(key)) return error_invalid_key;

    var scratch: [max_file_bytes]u8 = undefined;
    switch (readRaw(ctx, path, key, &scratch)) {
        .value => |value| {
            if (settings.parseU32(value)) |parsed| {
                out.* = parsed;
                return result_ok;
            }
            out.* = fallback;
            return result_defaulted;
        },
        .defaulted => {
            out.* = fallback;
            return result_defaulted;
        },
        .err => |err| return err,
    }
}

pub fn readI32(ctx: anytype, path: [*:0]const u8, key: []const u8, fallback: i32, out: *i32) i32 {
    if (!validPath(path)) return error_invalid_path;
    if (!settings.validKey(key)) return error_invalid_key;

    var scratch: [max_file_bytes]u8 = undefined;
    switch (readRaw(ctx, path, key, &scratch)) {
        .value => |value| {
            if (settings.parseI32(value)) |parsed| {
                out.* = parsed;
                return result_ok;
            }
            out.* = fallback;
            return result_defaulted;
        },
        .defaulted => {
            out.* = fallback;
            return result_defaulted;
        },
        .err => |err| return err,
    }
}

pub fn readRgb24(ctx: anytype, path: [*:0]const u8, key: []const u8, fallback: u32, out: *u32) i32 {
    if (!validPath(path)) return error_invalid_path;
    if (!settings.validKey(key)) return error_invalid_key;

    var scratch: [max_file_bytes]u8 = undefined;
    switch (readRaw(ctx, path, key, &scratch)) {
        .value => |value| {
            if (settings.parseRgb24(value)) |parsed| {
                out.* = parsed;
                return result_ok;
            }
            out.* = fallback & 0x00FF_FFFF;
            return result_defaulted;
        },
        .defaulted => {
            out.* = fallback & 0x00FF_FFFF;
            return result_defaulted;
        },
        .err => |err| return err,
    }
}

pub fn writeString(ctx: anytype, path: [*:0]const u8, key: []const u8, value: []const u8) i32 {
    if (!validPath(path)) return error_invalid_path;
    if (!settings.validKey(key)) return error_invalid_key;
    _ = settings.parseUtf8Text(value) catch return error_invalid_value;
    for (value) |byte| if (byte == '\r' or byte == '\n') return error_invalid_value;

    const recovered = recoverDocumentSave(ctx, path);
    if (recovered < 0) return recovered;
    var document: [max_output_bytes]u8 = undefined;
    const composed = composeDocument(ctx, path, key, value, document[0..]);
    if (composed.code < 0) return composed.code;
    const saved = saveDocument(ctx, path, document[0..composed.len]);
    if (saved < 0) return saved;
    return if (recovered == result_recovered) result_recovered else composed.code;
}

pub fn writeBool(ctx: anytype, path: [*:0]const u8, key: []const u8, value: bool) i32 {
    return writeString(ctx, path, key, if (value) "ON" else "OFF");
}

pub fn writeU32(ctx: anytype, path: [*:0]const u8, key: []const u8, value: u32) i32 {
    var text: [10]u8 = undefined;
    const written = formatU32(text[0..], value);
    return writeString(ctx, path, key, written);
}

pub fn writeI32(ctx: anytype, path: [*:0]const u8, key: []const u8, value: i32) i32 {
    var text: [11]u8 = undefined;
    const written = formatI32(text[0..], value);
    return writeString(ctx, path, key, written);
}

pub fn writeRgb24(ctx: anytype, path: [*:0]const u8, key: []const u8, value: u32) i32 {
    var text: [6]u8 = undefined;
    formatRgb24(text[0..], value);
    return writeString(ctx, path, key, text[0..]);
}

pub fn saveDocument(ctx: anytype, path: [*:0]const u8, bytes: []const u8) i32 {
    if (!validPath(path)) return error_invalid_path;
    if (!documentBytesUsable(bytes)) return error_invalid_value;
    return atomicSave(ctx, path, bytes);
}

pub fn recoverDocumentSave(ctx: anytype, path: [*:0]const u8) i32 {
    if (!validPath(path)) return error_invalid_path;
    var tmp_storage: [max_path_len + 1]u8 = .{0} ** (max_path_len + 1);
    var bak_storage: [max_path_len + 1]u8 = .{0} ** (max_path_len + 1);
    const tmp_path = makeSiblingPath(path, ".TMP", &tmp_storage) orelse return error_invalid_path;
    const bak_path = makeSiblingPath(path, ".BAK", &bak_storage) orelse return error_invalid_path;
    return recoverAtomicSiblings(ctx, path, tmp_path, bak_path);
}

pub fn hasDocumentSaveLeftovers(ctx: anytype, path: [*:0]const u8) bool {
    if (!validPath(path)) return true;
    var tmp_storage: [max_path_len + 1]u8 = .{0} ** (max_path_len + 1);
    var bak_storage: [max_path_len + 1]u8 = .{0} ** (max_path_len + 1);
    const tmp_path = makeSiblingPath(path, ".TMP", &tmp_storage) orelse return true;
    const bak_path = makeSiblingPath(path, ".BAK", &bak_storage) orelse return true;
    return ctx.exists(tmp_path) or ctx.exists(bak_path);
}

fn readRaw(ctx: anytype, path: [*:0]const u8, key: []const u8, scratch: *[max_file_bytes]u8) RawRead {
    const read = ctx.fileRead(path, scratch[0..]);
    if (readFailure(read, scratch.len)) |err| return .{ .err = err };
    if (read == file_not_found or read == 0) return .defaulted;

    const bytes = scratch[0..@as(usize, @intCast(read))];
    _ = settings.parseSystemText(bytes) catch return .{ .err = error_invalid_value };
    const doc = settings.Document.init(bytes);
    if (!documentFormatUsable(doc)) return .{ .err = error_invalid_value };
    if (doc.value(key)) |value| return .{ .value = value };
    return .defaulted;
}

fn composeDocument(ctx: anytype, path: [*:0]const u8, key: []const u8, value: []const u8, out: []u8) ComposeResult {
    var existing: [max_file_bytes]u8 = undefined;
    const read = ctx.fileRead(path, existing[0..]);
    if (readFailure(read, existing.len)) |err| return .{ .code = err, .len = 0 };
    const has_existing = read != file_not_found;
    const existing_bytes = if (has_existing) existing[0..@as(usize, @intCast(read))] else existing[0..0];
    if (has_existing and !existingDocumentUsable(existing_bytes)) return .{ .code = error_invalid_value, .len = 0 };

    var schema_storage: [32]u8 = .{0} ** 32;
    const existing_schema = if (has_existing) settings.Document.init(existing_bytes).schemaName() else null;
    const schema = chooseSchema(path, existing_schema, &schema_storage);

    var writer = settings.Writer.init(out);
    writer.writeHeader(schema);
    if (has_existing) {
        var iter = settings.EntryIterator.init(existing_bytes);
        while (iter.next()) |entry| {
            if (settings.equalsKey(entry.key, settings.format_key)) continue;
            if (settings.equalsKey(entry.key, settings.schema_key)) continue;
            if (settings.equalsKey(entry.key, key)) continue;
            writer.writePair(entry.key, entry.value);
        }
    }
    writer.writePair(key, value);
    if (!writer.ok()) return .{ .code = error_buffer_too_small, .len = 0 };
    return .{ .code = if (has_existing) result_ok else result_created, .len = writer.bytes().len };
}

fn atomicSave(ctx: anytype, path: [*:0]const u8, bytes: []const u8) i32 {
    var parent_storage: [max_path_len + 1]u8 = .{0} ** (max_path_len + 1);
    if (makeParentPath(path, &parent_storage)) |parent_path| {
        _ = ctx.dirCreate(parent_path);
    }

    var tmp_storage: [max_path_len + 1]u8 = .{0} ** (max_path_len + 1);
    var bak_storage: [max_path_len + 1]u8 = .{0} ** (max_path_len + 1);
    const tmp_path = makeSiblingPath(path, ".TMP", &tmp_storage) orelse return error_invalid_path;
    const bak_path = makeSiblingPath(path, ".BAK", &bak_storage) orelse return error_invalid_path;
    const recovery = recoverAtomicSiblings(ctx, path, tmp_path, bak_path);
    if (recovery < 0) return recovery;

    var original: [max_file_bytes]u8 = undefined;
    const original_read = ctx.fileRead(path, &original);
    if (readFailure(original_read, original.len)) |err| return err;
    const existed = original_read != file_not_found;
    if (existed and !existingDocumentUsable(original[0..@intCast(original_read)])) return error_invalid_value;
    const written = ctx.fileWrite(tmp_path, bytes);
    if (written != @as(i32, @intCast(bytes.len))) {
        _ = ctx.fileDelete(tmp_path);
        return error_write_failed;
    }

    var verify: [max_file_bytes]u8 = undefined;
    const verify_len = ctx.fileRead(tmp_path, verify[0..]);
    if (verify_len != @as(i32, @intCast(bytes.len)) or !std.mem.eql(u8, verify[0..bytes.len], bytes)) {
        _ = ctx.fileDelete(tmp_path);
        return error_verify_failed;
    }

    if (existed) {
        if (ctx.fileRename(path, bak_path) < 0) {
            _ = ctx.fileDelete(tmp_path);
            return error_rename_failed;
        }
    }
    if (ctx.fileRename(tmp_path, path) < 0) {
        if (existed and ctx.fileRename(bak_path, path) < 0) return error_recovery_failed;
        _ = ctx.fileDelete(tmp_path);
        return error_rename_failed;
    }
    if (existed and !deleteExisting(ctx, bak_path)) return error_recovery_failed;
    if (recovery == result_recovered) return result_recovered;
    return if (existed) result_ok else result_created;
}

fn recoverAtomicSiblings(ctx: anytype, path: [*:0]const u8, tmp_path: [*:0]const u8, bak_path: [*:0]const u8) i32 {
    var target: [max_file_bytes]u8 = undefined;
    const target_read = ctx.fileRead(path, &target);
    if (readFailure(target_read, target.len)) |err| return err;
    const target_exists = target_read != file_not_found;
    if (target_exists and !existingDocumentUsable(target[0..@intCast(target_read)])) return error_invalid_value;
    var sibling: [max_file_bytes]u8 = undefined;
    const tmp_read = ctx.fileRead(tmp_path, &sibling);
    if (readFailure(tmp_read, sibling.len)) |err| return err;
    const tmp_exists = tmp_read != file_not_found;
    const tmp_usable = tmp_read > 0 and documentBytesUsable(sibling[0..@intCast(tmp_read)]);
    const bak_read = ctx.fileRead(bak_path, &sibling);
    if (readFailure(bak_read, sibling.len)) |err| return err;
    const bak_exists = bak_read != file_not_found;
    const bak_usable = bak_exists and existingDocumentUsable(sibling[0..@intCast(bak_read)]);

    if (target_exists) {
        if (tmp_exists and !deleteExisting(ctx, tmp_path)) return error_recovery_failed;
        if (bak_exists and !deleteExisting(ctx, bak_path)) return error_recovery_failed;
        return if (tmp_exists or bak_exists) result_recovered else result_ok;
    }

    if (tmp_exists) {
        if (tmp_usable) {
            if (ctx.fileRename(tmp_path, path) < 0) return error_recovery_failed;
            if (bak_exists and !deleteExisting(ctx, bak_path)) return error_recovery_failed;
            return result_recovered;
        }
        if (!bak_exists) return error_recovery_failed;
    }

    if (bak_exists) {
        if (!bak_usable) return error_recovery_failed;
        if (ctx.fileRename(bak_path, path) < 0) return error_recovery_failed;
        if (tmp_exists and !deleteExisting(ctx, tmp_path)) return error_recovery_failed;
        return result_recovered;
    }

    return result_ok;
}

fn deleteExisting(ctx: anytype, path: [*:0]const u8) bool {
    if (!ctx.exists(path)) return true;
    _ = ctx.fileDelete(path);
    return !ctx.exists(path);
}

fn validPath(path: [*:0]const u8) bool {
    const text = std.mem.span(path);
    _ = path_contract.AbsoluteFilePath.parse(text) catch return false;
    return true;
}

fn documentFormatUsable(doc: settings.Document) bool {
    const version = doc.formatVersion() orelse return true;
    return version == settings.current_format_version;
}

fn existingDocumentUsable(bytes: []const u8) bool {
    _ = settings.parseSystemText(bytes) catch return false;
    return documentFormatUsable(settings.Document.init(bytes));
}

fn documentBytesUsable(bytes: []const u8) bool {
    if (bytes.len == 0 or bytes.len > max_file_bytes) return false;
    _ = settings.parseSystemText(bytes) catch return false;
    const doc = settings.Document.init(bytes);
    if (!doc.hasSupportedFormat()) return false;
    const schema = doc.schemaName() orelse return false;
    return settings.validKey(schema);
}

fn copyResult(value: []const u8, out: []u8, code: i32) i32 {
    if (!copyString(value, out)) return error_buffer_too_small;
    return code;
}

fn copyString(value: []const u8, out: []u8) bool {
    if (out.len == 0 or value.len >= out.len) return false;
    @memset(out, 0);
    if (value.len > 0) @memcpy(out[0..value.len], value);
    return true;
}

fn chooseSchema(path: [*:0]const u8, existing: ?[]const u8, out: *[32]u8) []const u8 {
    if (existing) |schema| {
        if (settings.validKey(schema)) return schema;
    }
    return deriveSchema(path, out);
}

fn deriveSchema(path: [*:0]const u8, out: *[32]u8) []const u8 {
    @memset(out[0..], 0);
    const text = std.mem.span(path);
    const base_start = if (lastPathSeparator(text)) |index| index + 1 else 0;
    const base = text[base_start..];
    const stem_end = if (lastByte(base, '.')) |index| index else base.len;
    const stem = base[0..stem_end];

    var len: usize = 0;
    for (stem) |ch_raw| {
        if (len >= out.len) break;
        const ch = asciiUpper(ch_raw);
        if ((ch >= 'A' and ch <= 'Z') or (ch >= '0' and ch <= '9') or ch == '_') {
            out[len] = ch;
            len += 1;
        } else if (ch == '-' or ch == '.') {
            out[len] = '_';
            len += 1;
        }
    }
    if (len == 0) {
        @memcpy(out[0..3], "APP");
        len = 3;
    }
    return out[0..len];
}

fn makeParentPath(path: [*:0]const u8, out: *[max_path_len + 1]u8) ?[*:0]const u8 {
    @memset(out[0..], 0);
    const text = std.mem.span(path);
    const sep = lastPathSeparator(text) orelse return null;
    if (sep <= 2 or sep >= out.len) return null;
    @memcpy(out[0..sep], text[0..sep]);
    return @ptrCast(out.ptr);
}

fn makeSiblingPath(path: [*:0]const u8, extension: []const u8, out: *[max_path_len + 1]u8) ?[*:0]const u8 {
    @memset(out[0..], 0);
    const text = std.mem.span(path);
    const base_start = if (lastPathSeparator(text)) |index| index + 1 else 0;
    const base = text[base_start..];
    const stem_end = if (lastByte(base, '.')) |index| base_start + index else text.len;
    const len = stem_end + extension.len;
    if (len == 0 or len >= out.len) return null;
    @memcpy(out[0..stem_end], text[0..stem_end]);
    @memcpy(out[stem_end..len], extension);
    return @ptrCast(out.ptr);
}

fn formatU32(out: []u8, value: u32) []const u8 {
    var pos = out.len;
    var n = value;
    while (true) {
        pos -= 1;
        out[pos] = '0' + @as(u8, @intCast(n % 10));
        n /= 10;
        if (n == 0) break;
    }
    const len = out.len - pos;
    std.mem.copyForwards(u8, out[0..len], out[pos..]);
    return out[0..len];
}

fn formatI32(out: []u8, value: i32) []const u8 {
    if (value < 0) {
        out[0] = '-';
        const magnitude: u32 = @intCast(-(value + 1));
        const written = formatU32(out[1..], magnitude + 1);
        return out[0 .. written.len + 1];
    }
    return formatU32(out, @intCast(value));
}

fn formatRgb24(out: []u8, value: u32) void {
    var shift: u5 = 20;
    var index: usize = 0;
    while (index < 6) : (index += 1) {
        const nibble: u8 = @intCast((value >> shift) & 0xF);
        out[index] = if (nibble < 10) '0' + nibble else 'A' + (nibble - 10);
        if (shift == 0) break;
        shift -= 4;
    }
}

fn lastPathSeparator(value: []const u8) ?usize {
    var index = value.len;
    while (index > 0) {
        index -= 1;
        if (value[index] == '\\' or value[index] == '/') return index;
    }
    return null;
}

fn lastByte(value: []const u8, needle: u8) ?usize {
    var index = value.len;
    while (index > 0) {
        index -= 1;
        if (value[index] == needle) return index;
    }
    return null;
}

fn asciiUpper(ch: u8) u8 {
    if (ch >= 'a' and ch <= 'z') return ch - ('a' - 'A');
    return ch;
}

const TestFs = struct {
    const Slot = struct {
        path: [max_path_len + 1]u8 = .{0} ** (max_path_len + 1),
        path_len: usize = 0,
        data: [max_file_bytes]u8 = .{0} ** max_file_bytes,
        data_len: i32 = -1,
    };

    slots: [8]Slot = .{Slot{}} ** 8,
    write_fail: bool = false,
    rename_fail: bool = false,
    rename_fail_on_call: usize = 0,
    rename_fail_from_call: usize = 0,
    rename_calls: usize = 0,
    read_failure_path: ?[]const u8 = null,
    read_failure_code: i32 = -6,

    pub fn put(self: *TestFs, path: []const u8, data: []const u8) void {
        const slot = self.slotFor(path).?;
        @memset(slot.data[0..], 0);
        @memcpy(slot.data[0..data.len], data);
        slot.data_len = @intCast(data.len);
    }

    pub fn readFile(self: *const TestFs, path: []const u8, out: []u8) i32 {
        if (self.read_failure_path) |failure_path| {
            if (std.mem.eql(u8, path, failure_path)) return self.read_failure_code;
        }
        const slot = self.find(path) orelse return file_not_found;
        const len: usize = @intCast(slot.data_len);
        if (len > out.len) return -5;
        const count = @min(len, out.len);
        if (count > 0) @memcpy(out[0..count], slot.data[0..count]);
        return @intCast(count);
    }

    pub fn fileRead(self: *const TestFs, path: [*:0]const u8, out: []u8) i32 {
        return self.readFile(std.mem.span(path), out);
    }

    pub fn fileWrite(self: *TestFs, path: [*:0]const u8, data: []const u8) i32 {
        if (self.write_fail) return -1;
        if (data.len > max_file_bytes) return -1;
        const slot = self.slotFor(std.mem.span(path)) orelse return -1;
        @memset(slot.data[0..], 0);
        if (data.len > 0) @memcpy(slot.data[0..data.len], data);
        slot.data_len = @intCast(data.len);
        return @intCast(data.len);
    }

    pub fn fileDelete(self: *TestFs, path: [*:0]const u8) i32 {
        if (self.findMutable(std.mem.span(path))) |slot| {
            slot.data_len = -1;
            return 0;
        }
        return -1;
    }

    pub fn fileRename(self: *TestFs, old_path: [*:0]const u8, new_path: [*:0]const u8) i32 {
        self.rename_calls += 1;
        if (self.rename_fail) return -1;
        if (self.rename_fail_on_call != 0 and self.rename_calls == self.rename_fail_on_call) return -1;
        if (self.rename_fail_from_call != 0 and self.rename_calls >= self.rename_fail_from_call) return -1;
        const old_text = std.mem.span(old_path);
        const old_slot = self.findMutable(old_text) orelse return -1;
        const len: usize = @intCast(old_slot.data_len);
        var tmp: [max_file_bytes]u8 = undefined;
        if (len > 0) @memcpy(tmp[0..len], old_slot.data[0..len]);
        old_slot.data_len = -1;

        const new_slot = self.slotFor(std.mem.span(new_path)) orelse return -1;
        @memset(new_slot.data[0..], 0);
        if (len > 0) @memcpy(new_slot.data[0..len], tmp[0..len]);
        new_slot.data_len = @intCast(len);
        return 0;
    }

    pub fn dirCreate(self: *TestFs, path: [*:0]const u8) i32 {
        _ = self;
        _ = path;
        return 0;
    }

    pub fn exists(self: *const TestFs, path: [*:0]const u8) bool {
        return self.find(std.mem.span(path)) != null;
    }

    fn slotFor(self: *TestFs, path: []const u8) ?*Slot {
        for (&self.slots) |*slot| {
            if (slot.path_len > 0 and std.mem.eql(u8, slot.path[0..slot.path_len], path)) return slot;
        }
        for (&self.slots) |*slot| {
            if (slot.data_len < 0) {
                if (path.len >= slot.path.len) return null;
                @memset(slot.path[0..], 0);
                @memcpy(slot.path[0..path.len], path);
                slot.path_len = path.len;
                return slot;
            }
        }
        return null;
    }

    fn find(self: *const TestFs, path: []const u8) ?*const Slot {
        for (&self.slots) |*slot| {
            if (slot.data_len >= 0 and std.mem.eql(u8, slot.path[0..slot.path_len], path)) return slot;
        }
        return null;
    }

    fn findMutable(self: *TestFs, path: []const u8) ?*Slot {
        for (&self.slots) |*slot| {
            if (slot.data_len >= 0 and std.mem.eql(u8, slot.path[0..slot.path_len], path)) return slot;
        }
        return null;
    }
};

fn spanZ(buf: []const u8) []const u8 {
    var end: usize = 0;
    while (end < buf.len and buf[end] != 0) : (end += 1) {}
    return buf[0..end];
}

fn expectFile(fs: *const TestFs, path: []const u8, expected: []const u8) !void {
    var bytes: [max_file_bytes]u8 = undefined;
    const len = fs.readFile(path, bytes[0..]);
    try std.testing.expect(len >= 0);
    try std.testing.expectEqualStrings(expected, bytes[0..@as(usize, @intCast(len))]);
}

test "config exposes library identity" {
    try std.testing.expectEqualStrings("R4STD", name);
}

test "read functions default missing and broken values" {
    var fs = TestFs{};
    const path = "C:\\TEMP\\APP.R4S";

    var text: [16]u8 = undefined;
    try std.testing.expectEqual(result_defaulted, readString(&fs, path, "TITLE", "Fallback", text[0..]));
    try std.testing.expectEqualStrings("Fallback", spanZ(text[0..]));

    fs.put(path, "BROKEN\r\nCOUNT=NaN\r\nFLAG=maybe\r\nTITLE=Configured\r\n");
    try std.testing.expectEqual(result_ok, readString(&fs, path, "TITLE", "Fallback", text[0..]));
    try std.testing.expectEqualStrings("Configured", spanZ(text[0..]));

    var count: u32 = 0;
    try std.testing.expectEqual(result_defaulted, readU32(&fs, path, "COUNT", 42, &count));
    try std.testing.expectEqual(@as(u32, 42), count);

    var flag = false;
    try std.testing.expectEqual(result_defaulted, readBool(&fs, path, "FLAG", true, &flag));
    try std.testing.expect(flag);
}

test "write creates canonical file and reads typed values" {
    var fs = TestFs{};
    const path = "C:\\TEMP\\APP.R4S";

    try std.testing.expectEqual(result_created, writeString(&fs, path, "TITLE", "Demo"));
    try std.testing.expectEqual(result_ok, writeBool(&fs, path, "ENABLED", true));
    try std.testing.expectEqual(result_ok, writeU32(&fs, path, "COUNT", 27));
    try std.testing.expectEqual(result_ok, writeI32(&fs, path, "OFFSET", -7));
    try std.testing.expectEqual(result_ok, writeRgb24(&fs, path, "COLOR", 0x008080));

    var file: [max_file_bytes]u8 = undefined;
    const file_len = fs.readFile(path, file[0..]);
    try std.testing.expect(file_len > 0);
    const bytes = file[0..@as(usize, @intCast(file_len))];
    try std.testing.expect(std.mem.startsWith(u8, bytes, settings.utf8_bom));
    try std.testing.expect(std.mem.indexOf(u8, bytes, "R4S_FORMAT=1") != null);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "SCHEMA=APP") != null);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "TITLE=Demo") != null);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "ENABLED=ON") != null);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "COLOR=008080") != null);

    var enabled = false;
    var count: u32 = 0;
    var offset: i32 = 0;
    var color: u32 = 0;
    try std.testing.expectEqual(result_ok, readBool(&fs, path, "ENABLED", false, &enabled));
    try std.testing.expectEqual(result_ok, readU32(&fs, path, "COUNT", 0, &count));
    try std.testing.expectEqual(result_ok, readI32(&fs, path, "OFFSET", 0, &offset));
    try std.testing.expectEqual(result_ok, readRgb24(&fs, path, "COLOR", 0, &color));
    try std.testing.expect(enabled);
    try std.testing.expectEqual(@as(u32, 27), count);
    try std.testing.expectEqual(@as(i32, -7), offset);
    try std.testing.expectEqual(@as(u32, 0x008080), color);
}

test "write updates atomically and preserves unrelated keys" {
    var fs = TestFs{};
    const path = "C:\\TEMP\\APP.R4S";
    fs.put(path, settings.utf8_bom ++ "R4S_FORMAT=1\r\nSCHEMA=TEST\r\nKEEP=old\r\nCOUNT=1\r\n");

    try std.testing.expectEqual(result_ok, writeU32(&fs, path, "COUNT", 2));

    var file: [max_file_bytes]u8 = undefined;
    const file_len = fs.readFile(path, file[0..]);
    try std.testing.expect(file_len > 0);
    const bytes = file[0..@as(usize, @intCast(file_len))];
    try std.testing.expect(std.mem.indexOf(u8, bytes, "SCHEMA=TEST") != null);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "KEEP=old") != null);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "COUNT=2") != null);
    try std.testing.expect(!fs.exists("C:\\TEMP\\APP.TMP"));
    try std.testing.expect(!fs.exists("C:\\TEMP\\APP.BAK"));
}

test "saveDocument writes whole R4S documents and rejects invalid input" {
    var fs = TestFs{};
    const path = "C:\\TEMP\\DOC.R4S";
    const doc_a = settings.utf8_bom ++ "R4S_FORMAT=1\r\nSCHEMA=DOC\r\nTITLE=A\r\n";
    const doc_b = settings.utf8_bom ++ "R4S_FORMAT=1\r\nSCHEMA=DOC\r\nTITLE=B\r\n";

    try std.testing.expectEqual(result_created, saveDocument(&fs, path, doc_a));
    try expectFile(&fs, path, doc_a);
    try std.testing.expectEqual(result_ok, saveDocument(&fs, path, doc_b));
    try expectFile(&fs, path, doc_b);
    try std.testing.expectEqual(error_invalid_value, saveDocument(&fs, path, "TITLE=broken\r\n"));
    try expectFile(&fs, path, doc_b);
    try std.testing.expect(!hasDocumentSaveLeftovers(&fs, path));
}

test "saveDocument reports write and rename failures without losing target" {
    const path = "C:\\TEMP\\DOC.R4S";
    const doc_old = settings.utf8_bom ++ "R4S_FORMAT=1\r\nSCHEMA=DOC\r\nTITLE=OLD\r\n";
    const doc_new = settings.utf8_bom ++ "R4S_FORMAT=1\r\nSCHEMA=DOC\r\nTITLE=NEW\r\n";

    var write_fail_fs = TestFs{ .write_fail = true };
    try std.testing.expectEqual(error_write_failed, saveDocument(&write_fail_fs, path, doc_new));
    try std.testing.expect(!write_fail_fs.exists(path));
    try std.testing.expect(!hasDocumentSaveLeftovers(&write_fail_fs, path));

    var rename_fail_fs = TestFs{ .rename_fail = true };
    rename_fail_fs.put(path, doc_old);
    try std.testing.expectEqual(error_rename_failed, saveDocument(&rename_fail_fs, path, doc_new));
    try expectFile(&rename_fail_fs, path, doc_old);
    try std.testing.expect(!hasDocumentSaveLeftovers(&rename_fail_fs, path));
}

test "saveDocument rolls back when final replace rename fails" {
    var fs = TestFs{ .rename_fail_on_call = 2 };
    const path = "C:\\TEMP\\DOC.R4S";
    const doc_old = settings.utf8_bom ++ "R4S_FORMAT=1\r\nSCHEMA=DOC\r\nTITLE=OLD\r\n";
    const doc_new = settings.utf8_bom ++ "R4S_FORMAT=1\r\nSCHEMA=DOC\r\nTITLE=NEW\r\n";
    fs.put(path, doc_old);

    try std.testing.expectEqual(error_rename_failed, saveDocument(&fs, path, doc_new));
    try expectFile(&fs, path, doc_old);
    try std.testing.expect(!hasDocumentSaveLeftovers(&fs, path));
    try std.testing.expectEqual(@as(usize, 3), fs.rename_calls);
}

test "saveDocument recovers and cleans stale atomic siblings" {
    var fs = TestFs{};
    const path = "C:\\TEMP\\DOC.R4S";
    const tmp_path = "C:\\TEMP\\DOC.TMP";
    const bak_path = "C:\\TEMP\\DOC.BAK";
    const doc_old = settings.utf8_bom ++ "R4S_FORMAT=1\r\nSCHEMA=DOC\r\nTITLE=OLD\r\n";
    const doc_tmp = settings.utf8_bom ++ "R4S_FORMAT=1\r\nSCHEMA=DOC\r\nTITLE=TMP\r\n";
    const doc_new = settings.utf8_bom ++ "R4S_FORMAT=1\r\nSCHEMA=DOC\r\nTITLE=NEW\r\n";

    fs.put(path, doc_old);
    fs.put(tmp_path, doc_tmp);
    fs.put(bak_path, doc_old);
    try std.testing.expectEqual(result_recovered, saveDocument(&fs, path, doc_new));
    try expectFile(&fs, path, doc_new);
    try std.testing.expect(!hasDocumentSaveLeftovers(&fs, path));

    var recover_fs = TestFs{};
    recover_fs.put(tmp_path, doc_tmp);
    recover_fs.put(bak_path, doc_old);
    try std.testing.expectEqual(result_recovered, recoverDocumentSave(&recover_fs, path));
    try expectFile(&recover_fs, path, doc_tmp);
    try std.testing.expect(!hasDocumentSaveLeftovers(&recover_fs, path));
}

test "read rejects invalid key and protects small buffers" {
    var fs = TestFs{};
    const path = "C:\\TEMP\\APP.R4S";
    fs.put(path, "TITLE=Configured\r\n");

    var small: [5]u8 = .{0xCC} ** 5;
    try std.testing.expectEqual(error_buffer_too_small, readString(&fs, path, "TITLE", "Fallback", small[0..]));
    try std.testing.expectEqualSlices(u8, &.{ 0xCC, 0xCC, 0xCC, 0xCC, 0xCC }, small[0..]);
    try std.testing.expectEqual(error_invalid_key, readString(&fs, path, "BAD KEY", "Fallback", small[0..]));
    try std.testing.expectEqual(error_invalid_path, readString(&fs, "", "TITLE", "Fallback", small[0..]));
}

test "config path and value boundaries reject without persistent mutation" {
    var fs = TestFs{};
    const path = "C:\\TEMP\\APP.R4S";
    const original = settings.utf8_bom ++ "R4S_FORMAT=1\r\nSCHEMA=APP\r\nTITLE=Old\r\n";
    fs.put(path, original);
    try std.testing.expectEqual(error_invalid_value, writeString(&fs, path, "TITLE", "Bad\nValue"));
    try expectFile(&fs, path, original);

    var too_long: [max_path_len + 2:0]u8 = .{'A'} ** (max_path_len + 2);
    too_long[0] = 'C';
    too_long[1] = ':';
    too_long[2] = '\\';
    too_long[too_long.len - 1] = 0;
    try std.testing.expectEqual(error_invalid_path, writeString(&fs, @ptrCast(&too_long), "TITLE", "New"));
    try expectFile(&fs, path, original);
}

test "config preserves originals and siblings on read failures" {
    const path = "C:\\TEMP\\SAFE.R4S";
    const tmp = "C:\\TEMP\\SAFE.TMP";
    const bak = "C:\\TEMP\\SAFE.BAK";
    const original = settings.utf8_bom ++ "R4S_FORMAT=1\r\nSCHEMA=SAFE\r\nKEEP=old\r\nCOUNT=1\r\n";
    for ([_]i32{ -6, -5, 4097 }) |failure| {
        var fs = TestFs{ .read_failure_path = path, .read_failure_code = failure };
        fs.put(path, original);
        fs.put(bak, original);
        const expected = if (failure == -6) error_read_failed else error_buffer_too_small;
        try std.testing.expectEqual(expected, writeU32(&fs, path, "COUNT", 2));
        var value: u32 = 91;
        try std.testing.expectEqual(expected, readU32(&fs, path, "COUNT", 7, &value));
        try std.testing.expectEqual(@as(u32, 91), value);
        try std.testing.expectEqual(@as(usize, 0), fs.rename_calls);
        fs.read_failure_path = null;
        try expectFile(&fs, path, original);
        try expectFile(&fs, bak, original);
        try std.testing.expect(!fs.exists(tmp));
    }
    var fs = TestFs{};
    try std.testing.expectEqual(result_created, writeU32(&fs, path, "COUNT", 1));
    fs.put(path, "");
    try std.testing.expectEqual(result_ok, writeU32(&fs, path, "COUNT", 2));
    fs.put(tmp, original);
    fs.read_failure_path = tmp;
    try std.testing.expectEqual(error_read_failed, recoverDocumentSave(&fs, path));
    fs.read_failure_path = null;
    try expectFile(&fs, tmp, original);
}

test "config composes recovered content and retains recoverable data after failed rollback" {
    const path = "C:\\TEMP\\SAFE.R4S";
    const tmp = "C:\\TEMP\\SAFE.TMP";
    const bak = "C:\\TEMP\\SAFE.BAK";
    const old = settings.utf8_bom ++ "R4S_FORMAT=1\r\nSCHEMA=SAFE\r\nKEEP=old\r\nCOUNT=1\r\n";
    const next = settings.utf8_bom ++ "R4S_FORMAT=1\r\nSCHEMA=SAFE\r\nKEEP=new\r\nCOUNT=1\r\n";
    for ([_]bool{ false, true }) |with_tmp| {
        var fs = TestFs{};
        fs.put(bak, old);
        if (with_tmp) fs.put(tmp, next);
        try std.testing.expectEqual(result_recovered, writeU32(&fs, path, "COUNT", 2));
        var kept: [16]u8 = undefined;
        try std.testing.expectEqual(result_ok, readString(&fs, path, "KEEP", "missing", &kept));
        try std.testing.expectEqualStrings(if (with_tmp) "new" else "old", spanZ(&kept));
        var count: u32 = 0;
        try std.testing.expectEqual(result_ok, readU32(&fs, path, "COUNT", 0, &count));
        try std.testing.expectEqual(@as(u32, 2), count);
    }
    var fs = TestFs{ .rename_fail = true };
    fs.put(tmp, next);
    fs.put(bak, old);
    try std.testing.expectEqual(error_recovery_failed, writeU32(&fs, path, "COUNT", 2));
    try expectFile(&fs, tmp, next);
    try expectFile(&fs, bak, old);
    fs = .{ .rename_fail_from_call = 2 };
    fs.put(path, old);
    try std.testing.expectEqual(error_recovery_failed, saveDocument(&fs, path, next));
    try expectFile(&fs, tmp, next);
    try expectFile(&fs, bak, old);
    try std.testing.expect(!fs.exists(path));
}
