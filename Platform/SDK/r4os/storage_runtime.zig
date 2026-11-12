//! SDK-local scalar boundary to existing storage policy/codec owners.
const std = @import("std");
const abi = @import("r4os_contract").abi;
const program = @import("program.zig");
const sys = @import("r4sys.zig");
const storage = @import("app_storage.zig");
const save = @import("document_save.zig");
const recent = @import("recent_documents.zig");
const text = @import("bounded_text.zig");
const registry = @import("registry.zig");
const registry_test = @import("registry_selftest.zig");
const RegistryTestPaths = extern struct { hive: ?[*:0]const u8, tmp: ?[*:0]const u8, bak: ?[*:0]const u8, original: ?[*:0]const u8, stage: ?[*:0]const u8, displaced: ?[*:0]const u8 };

const Sys = extern struct {
    ctx: ?*const abi.R4XStartContext,
    table: ?*const abi.R4XStartR4Sys,
    generation2: ?*const @import("platform2.zig").Context,
    memory2: ?*const @import("allocator_source.zig").Memory,
};
const RecentEntry = extern struct { path: [recent.path_max + 1]u8, app: [32]u8, title: [64]u8 };
const HiveHeader = extern struct {
    hive_kind: u16,
    generation: u64,
    key_table_offset: u32,
    key_count: u32,
    value_table_offset: u32,
    value_count: u32,
    string_heap_offset: u32,
    string_heap_size: u32,
    data_heap_offset: u32,
    data_heap_size: u32,
    checksum_type: u32,
    checksum: u32,
};
const HiveView = extern struct { bytes: ?[*]const u8, length: usize, header: HiveHeader };
const HiveKey = extern struct { parent_index: u32, first_value_index: u32, value_count: u32, first_child_index: u32, child_count: u32, name: [*]const u8, name_len: usize };
const HiveValue = extern struct { owner_key_index: u32, value_type: u16, name: [*]const u8, name_len: usize, data: [*]const u8, data_len: usize };
const BuildValue = extern struct { key: ?[*]const u8, key_len: usize, name: ?[*]const u8, name_len: usize, value_type: u16, data: ?[*]const u8, data_len: usize };

fn span(bytes: ?[*]const u8, len: usize) ?[]const u8 {
    if (len > std.math.maxInt(isize)) return null;
    return if (bytes) |p| p[0..len] else if (len == 0) "" else null;
}
fn output(bytes: ?[*]u8, len: usize) ?[]u8 {
    if (len > std.math.maxInt(isize)) return null;
    return if (bytes) |p| p[0..len] else if (len == 0) @constCast(&.{}) else null;
}
const Binding = struct {
    first: program.Bundle = undefined,
    next: ?*const @import("platform2.zig").Context = null,
    memory: ?*const @import("allocator_source.zig").Memory = null,

    fn from(value: ?*const Sys) ?Binding {
        const source = value orelse return null;
        if (source.generation2) |context2| {
            _ = context2.system() orelse return null;
            return .{ .next = context2, .memory = source.memory2 };
        }
        const table = source.table orelse return null;
        if (table.magic != abi.r4xstart_r4sys_magic or table.abi_version < (abi.R4XStartR4Sys{}).abi_version or table.size < @sizeOf(abi.R4XStartR4Sys)) return null;
        return .{ .first = .{ .raw = source.ctx orelse return null, .sys = table } };
    }
    // Call after this value has reached its stable local storage. No pointer
    // to a returned temporary Bundle or Context is retained.
    fn system(self: *const Binding) sys.Context {
        return if (self.next) |context2|
            sys.Context.fromProgram(.{ .generation2 = context2, .memory2 = self.memory })
        else
            sys.Context.init(&self.first);
    }
};
export fn R4SdkConsole(s: ?*const Sys, bytes: ?[*]const u8, length: usize, operation: i32) callconv(.c) i32 {
    const b = Binding.from(s) orelse return -1;
    const value = span(bytes, length) orelse return -1;
    const console = storage.Console{ .sys = b.system() };
    switch (operation) {
        0 => console.write(value),
        1 => console.line(value),
        2 => {
            if (value.len != 1) return -1;
            console.put(value[0]);
        },
        else => return -1,
    }
    return 0;
}
export fn R4SdkDocumentSave(s: ?*const Sys, sequence: ?*u32, path: ?[*]const u8, path_len: usize, bytes: ?[*]const u8, length: usize, require_absent: i32) callconv(.c) i32 {
    const b = Binding.from(s) orelse return 2;
    const seq = sequence orelse return 2;
    const p = storage.FilePath.parse(span(path, path_len) orelse return 2) catch return 2;
    var saver = save.Saver{ .sequence = seq.* };
    const result = saver.save(.{ .sys = b.system() }, p.asZ(), span(bytes, length) orelse return 2, require_absent != 0);
    seq.* = saver.sequence;
    return @intFromEnum(result);
}
export fn R4SdkRecentRead(s: ?*const Sys, out: ?[*]RecentEntry, capacity: usize) callconv(.c) i32 {
    const b = Binding.from(s) orelse return -1;
    if (out == null or capacity == 0) return 0;
    var entries: [recent.max_items]recent.Entry = undefined;
    const n = recent.readEntries(b.system(), entries[0..@min(capacity, entries.len)]);
    for (entries[0..n], 0..) |entry, i| out.?[i] = .{ .path = entry.path, .app = entry.app, .title = entry.title };
    return @intCast(n);
}
export fn R4SdkRecentAdd(s: ?*const Sys, path: ?[*]const u8, path_len: usize, app: ?[*]const u8, app_len: usize) callconv(.c) i32 {
    const b = Binding.from(s) orelse return 0;
    return @intFromBool(recent.addOpenedFile(b.system(), span(path, path_len) orelse return 0, span(app, app_len) orelse return 0));
}
export fn R4SdkTextValid(bytes: ?[*]const u8, len: usize) callconv(.c) i32 {
    return @intFromBool(text.valid(span(bytes, len) orelse return 0));
}
export fn R4SdkTextAssign(out: ?[*]u8, cap: usize, bytes: ?[*]const u8, len: usize) callconv(.c) i32 {
    return @intFromBool(text.assignZ(output(out, cap) orelse return 0, span(bytes, len) orelse return 0));
}
export fn R4SdkTextLabel(out: ?[*]u8, cap: usize, bytes: ?[*]const u8, len: usize) callconv(.c) i32 {
    return @intFromBool(text.labelZ(output(out, cap) orelse return 0, span(bytes, len) orelse return 0));
}
export fn R4SdkTextPrefix(bytes: ?[*]const u8, len: usize, cap: usize, truncated: i32, prefix: ?*usize) callconv(.c) i32 {
    const p = prefix orelse return 0;
    p.* = text.loadPrefix(span(bytes, len) orelse return 0, cap, truncated != 0) orelse return 0;
    return 1;
}
export fn R4SdkRegistrySelfTest(s: ?*const Sys, operation: i32, paths: ?*const RegistryTestPaths, had_original: i32, original: ?[*]u8, original_len: usize, check: ?[*]u8, check_len: usize) callconv(.c) i32 {
    const b = Binding.from(s) orelse return -1;
    const context = b.system();
    if (operation == 0) return @intFromBool(registry_test.privateImage(context));
    const source = paths orelse return -1;
    var p: registry_test.Paths = undefined;
    inline for (@typeInfo(registry_test.Paths).@"struct".fields) |f| @field(p, f.name) = @field(source, f.name) orelse return -1;
    const a = output(original, original_len) orelse return -1;
    const z = output(check, check_len) orelse return -1;
    return switch (operation) {
        1 => @intFromBool(registry_test.backup(context, p, a, z) orelse return -1),
        2 => @intFromBool(registry_test.restore(context, p, had_original != 0, a, z)),
        else => -1,
    };
}
fn code(err: registry.Error) i32 {
    return switch (err) {
        error.FileTooSmall => -1,
        error.BadMagic => -2,
        error.BadVersion => -3,
        error.BadHeaderSize => -4,
        error.BadEndian => -5,
        error.BadHiveKind => -6,
        error.BadFlags => -7,
        error.BadFileSize => -8,
        error.BadChecksumType => -9,
        error.BadChecksum => -10,
        error.BadReserved => -11,
        error.BadRange => -12,
        error.BadRootKey => -13,
        error.BadKey => -14,
        error.BadValue => -15,
        error.BadName => -16,
        error.BadData => -17,
        error.DuplicateKey => -18,
        error.DuplicateValue => -19,
        error.RootMismatch => -20,
        error.InvalidPath => -21,
        error.OutOfMemory => -22,
        error.TooManyEntries => -23,
        error.InvalidText => -24,
    };
}
fn flat(h: registry.Header) HiveHeader {
    var result: HiveHeader = undefined;
    inline for (@typeInfo(HiveHeader).@"struct".fields) |f| @field(result, f.name) = if (comptime std.mem.eql(u8, f.name, "hive_kind")) @intFromEnum(h.hive_kind) else @field(h, f.name);
    return result;
}
fn range(bytes: []const u8, offset: u32, length: u64) ?[]const u8 {
    if (@as(u64, offset) + length > bytes.len) return null;
    return bytes[offset..][0..@intCast(length)];
}
fn view(v: ?*const HiveView) ?registry.HiveView {
    const value = v orelse return null;
    const bytes = span(value.bytes, value.length) orelse return null;
    const h = value.header;
    const kind = registry.HiveKind.fromInt(h.hive_kind) orelse return null;
    var header: registry.Header = undefined;
    inline for (@typeInfo(registry.Header).@"struct".fields) |f| @field(header, f.name) = if (comptime std.mem.eql(u8, f.name, "hive_kind")) kind else @field(h, f.name);
    return .{ .bytes = bytes, .header = header, .key_table = range(bytes, h.key_table_offset, @as(u64, h.key_count) * registry.key_record_size) orelse return null, .value_table = range(bytes, h.value_table_offset, @as(u64, h.value_count) * registry.value_record_size) orelse return null, .string_heap = range(bytes, h.string_heap_offset, h.string_heap_size) orelse return null, .data_heap = range(bytes, h.data_heap_offset, h.data_heap_size) orelse return null };
}
export fn R4SdkHiveParse(bytes: ?[*]const u8, len: usize, out: ?*HiveView) callconv(.c) i32 {
    const target = out orelse return -12;
    const parsed = registry.parseHive(span(bytes, len) orelse return -12) catch |err| return code(err);
    target.* = .{ .bytes = bytes, .length = len, .header = flat(parsed.header) };
    return 0;
}
export fn R4SdkHiveKey(v: ?*const HiveView, index: u32, out: ?*HiveKey) callconv(.c) i32 {
    const h = view(v) orelse return -12;
    const target = out orelse return -12;
    if (index >= h.header.key_count) return 0;
    const k = h.keyAt(index);
    const name = h.keyName(k);
    target.* = .{ .parent_index = k.parent_index, .first_value_index = k.first_value_index, .value_count = k.value_count, .first_child_index = k.first_child_index, .child_count = k.child_count, .name = name.ptr, .name_len = name.len };
    return 1;
}
export fn R4SdkHiveValue(v: ?*const HiveView, index: u32, out: ?*HiveValue) callconv(.c) i32 {
    const h = view(v) orelse return -12;
    const target = out orelse return -12;
    if (index >= h.header.value_count) return 0;
    const r = h.valueAt(index);
    const name = h.valueName(r);
    const data = h.valueData(r);
    target.* = .{ .owner_key_index = r.owner_key_index, .value_type = @intFromEnum(r.value_type), .name = name.ptr, .name_len = name.len, .data = data.ptr, .data_len = data.len };
    return 1;
}
export fn R4SdkHiveFind(v: ?*const HiveView, operation: i32, parent: u32, name: ?[*]const u8, len: usize, out: ?*u32) callconv(.c) i32 {
    const h = view(v) orelse return -12;
    const target = out orelse return -12;
    const bytes = span(name, len) orelse return -12;
    const index = switch (operation) {
        0 => h.findKey(bytes),
        1 => if (parent < h.header.key_count) h.findChild(parent, bytes) else null,
        2 => if (parent < h.header.key_count) h.findValue(parent, bytes) else null,
        else => return -12,
    };
    target.* = index orelse return 0;
    return 1;
}
fn publish(bytes: []const u8, out: ?[*]u8, capacity: usize, written: ?*usize) i32 {
    const length = written orelse return -12;
    length.* = bytes.len;
    const target = output(out, capacity) orelse return -12;
    if (target.len < bytes.len) return -25;
    @memcpy(target[0..bytes.len], bytes);
    return 0;
}
export fn R4SdkHiveBuild(kind: u16, generation: u64, values: ?[*]const BuildValue, count: usize, scratch: ?[*]u8, scratch_len: usize, out: ?[*]u8, capacity: usize, written: ?*usize) callconv(.c) i32 {
    const hk = registry.HiveKind.fromInt(kind) orelse return -6;
    if (count > std.math.maxInt(u32) or (values == null and count != 0)) return -23;
    var arena = std.heap.FixedBufferAllocator.init(output(scratch, scratch_len) orelse return -22);
    const a = arena.allocator();
    const inputs = a.alloc(registry.BuildValue, count) catch return -22;
    for (inputs, 0..) |*item, i| {
        const input = values.?[i];
        item.* = .{ .key_path = span(input.key, input.key_len) orelse return -21, .name = span(input.name, input.name_len) orelse return -16, .value_type = registry.ValueType.fromInt(input.value_type) orelse return -15, .data = span(input.data, input.data_len) orelse return -17 };
    }
    const built = registry.buildHive(a, hk, generation, inputs) catch |err| return code(err);
    return publish(built, out, capacity, written);
}
export fn R4SdkHiveText(import_text: i32, generation: u64, bytes: ?[*]const u8, len: usize, scratch: ?[*]u8, scratch_len: usize, out: ?[*]u8, capacity: usize, written: ?*usize) callconv(.c) i32 {
    const input = span(bytes, len) orelse return -12;
    var arena = std.heap.FixedBufferAllocator.init(output(scratch, scratch_len) orelse return -22);
    const a = arena.allocator();
    const built = if (import_text != 0) registry.importTextHive(a, input, generation) catch |err| return code(err) else registry.exportTextHive(a, registry.parseHive(input) catch |err| return code(err)) catch |err| return code(err);
    return publish(built, out, capacity, written);
}
