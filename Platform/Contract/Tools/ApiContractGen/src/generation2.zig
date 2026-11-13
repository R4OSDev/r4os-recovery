const std = @import("std");

const TechnicalField = struct { name: []const u8, zig_type: []const u8, default_value: ?[]const u8, offset: u32 };
const Technical = struct { name: []const u8, size: u32, alignment: u32, fields: []TechnicalField };
const Callback = struct { name: []const u8, zig_type: []const u8 };
const Selection = struct { default_generation: u32, profile_selection: []const u8, mixed_start_generations: []const u8, missing_generation: []const u8, shared_resource_owners: bool, profiles: []const []const u8 };
const Spec = struct {
    schema: u32,
    generation: u32,
    source: []const u8,
    driver: struct { init_symbol: []const u8, protocol_init_symbol: []const u8, export_version: u32, magic: u32, version: u32, protocol_magic: u32, protocol_version: u32 },
    audio: struct { magic: u32, version: u32 },
    selection: Selection,
    technical: []Technical,
    callbacks: []Callback,
};
// Headers in this transient renderer are copied from the active contract.
// There is no separately editable root or group list in this specification.
const Resolved = struct {
    query: struct { symbol: []const u8, export_version: u32, magic: u32, abi_version: u32, size: u32 },
    start: struct { symbol: []const u8, export_version: u32, magic: u32, abi_major: u32, abi_minor: u32, size: u32, remove_fields: []const []const u8 = &.{} },
};
fn contains(names: []const []const u8, name: []const u8) bool {
    for (names) |item| if (std.mem.eql(u8, item, name)) return true;
    return false;
}
fn resolve(contract: anytype) Resolved {
    const q = contract.r4l_query;
    const s = contract.r4x_start;
    return .{ .query = .{ .symbol = q.entry_symbol, .export_version = q.entry_version, .magic = q.magic, .abi_version = q.abi_version, .size = q.layout.size }, .start = .{ .symbol = s.entry.symbol, .export_version = s.entry.version, .magic = s.magic, .abi_major = s.abi_major, .abi_minor = s.abi_minor, .size = s.context.size } };
}
fn validate(spec: Spec, contract: anytype) !void {
    if (spec.schema != 2 or spec.generation != 2 or !std.mem.eql(u8, spec.source, "API/ApiContract.json")) return error.GenerationIdentity;
    const q = contract.r4l_query;
    const s = contract.r4x_start;
    if (q.magic != 0x324c3452 or q.abi_version != 2 or q.entry_version != 2 or q.layout.size != 24 or !std.mem.eql(u8, q.entry_symbol, "Query2") or !std.mem.eql(u8, q.layout.name, "R4LQuery2")) return error.GenerationQueryIdentity;
    if (s.magic != 0x32583452 or s.abi_major != 2 or s.abi_minor != 0 or s.context.size != 120 or s.entry.version != 2 or !std.mem.eql(u8, s.entry.symbol, "R4XStart2") or !std.mem.eql(u8, s.context.name, "R4XStartContext2")) return error.GenerationStartIdentity;
    if (contract.schema_version != 12 or !std.mem.eql(u8, contract.baseline_id, "canonical-generation2-0.64.95")) return error.GenerationSchemaIdentity;
    if (spec.driver.magic != 0x32495044 or spec.driver.protocol_magic != 0x32495050 or spec.driver.export_version != 2 or spec.driver.version < 1 or spec.driver.protocol_version < 1 or !std.mem.eql(u8, spec.driver.init_symbol, "DriverInit2") or !std.mem.eql(u8, spec.driver.protocol_init_symbol, "ProtocolInit2")) return error.GenerationDriverIdentity;
    if (spec.audio.magic != 0x32425541 or spec.audio.version < 3) return error.GenerationAudioIdentity;
    if (spec.selection.default_generation != 2 or !spec.selection.shared_resource_owners or !std.mem.eql(u8, spec.selection.missing_generation, "reject") or !std.mem.eql(u8, spec.selection.mixed_start_generations, "reject")) return error.GenerationSelection;
    if (contract.groups.len != 6 or spec.technical.len != 5 or spec.callbacks.len != 3) return error.GenerationSet;
    const magics = [_]u32{ 844714834, 843400274, 844579922, 843402834, 844448082, 844514386 };
    for (contract.groups, 0..) |group, i| {
        if (group.id != i + 1 or group.abi_version == 0 or group.magic != magics[i] or group.size != 16 + 8 * group.slots.len or group.header_size != 16 or group.pointer_size != 8 or !std.mem.endsWith(u8, group.table_type, "2") or !std.mem.endsWith(u8, group.fn_namespace, "2") or !std.mem.endsWith(u8, group.query_import, ":Query2:2")) return error.GenerationTableIdentity;
        for (group.slots, 0..) |slot, n| {
            if (slot.number != n or slot.offset != 16 + 8 * n or slot.state == .tombstone) return error.GenerationSlot;
        }
    }
}
fn validateBaseline(a: std.mem.Allocator, io: std.Io, spec: Spec, update: bool) !void {
    if (update) return;
    const bytes = try std.Io.Dir.cwd().readFileAlloc(io, "API/Generation2.baseline.json", a, .limited(256 * 1024));
    const baseline = (try std.json.parseFromSlice(Spec, a, bytes, .{})).value;
    const current = try std.json.Stringify.valueAlloc(a, spec, .{});
    const original = try std.json.Stringify.valueAlloc(a, baseline, .{});
    if (!std.mem.eql(u8, current, original)) return error.GenerationTechnicalBaselineDrift;
}
const Output = struct {
    allocator: std.mem.Allocator,
    bytes: std.ArrayList(u8) = .empty,
    fn text(self: *Output, value: []const u8) !void {
        try self.bytes.appendSlice(self.allocator, value);
    }
    fn print(self: *Output, comptime fmt: []const u8, args: anytype) !void {
        try self.text(try std.fmt.allocPrint(self.allocator, fmt, args));
    }
};

fn emitZig(a: std.mem.Allocator, config: Resolved, contract: anytype, comptime Formatter: type) ![]const u8 {
    var out: Output = .{ .allocator = a };
    try out.text("pub const R4XStartShouldCloseFn2 = *const fn (*const R4XStartContext2) callconv(.c) u32;\npub const R4XStartYieldFn2 = *const fn (*const R4XStartContext2) callconv(.c) void;\n");
    try out.text("// Generated from canonical API/ApiContract.json and independent API/Generation2.json. DO NOT EDIT.\nconst std = @import(\"std\");\nconst base = @import(\"r4os_base_abi\");\npub const shared = if (@hasDecl(base, \"abi\")) base.abi else base;\n\n");
    try out.text("pub const DriverApi2 = shared.DriverApi2;\npub const ProtocolApi2 = shared.ProtocolApi2;\npub const AudioBackend2 = shared.AudioBackend2;\npub const AudioBackendStatus2 = shared.AudioBackendStatus2;\npub const AudioBackendRegisterFn2 = shared.AudioBackendRegisterFn2;\npub const AudioBackendStatusFn2 = shared.AudioBackendStatusFn2;\npub const AudioCaptureBackend2 = shared.AudioCaptureBackend2;\npub const AudioCaptureRegisterFn2 = shared.AudioCaptureRegisterFn2;\npub const driver_magic = shared.driver_api2_magic;\npub const driver_version = shared.driver_api2_version;\npub const protocol_magic = shared.protocol_api2_magic;\npub const protocol_version = shared.protocol_api2_version;\npub const audio_backend_magic = shared.audio_backend2_magic;\npub const audio_backend_version = shared.audio_backend2_version;\n");
    try out.print("pub const generation: u32 = 2;\npub const query_symbol = \"{s}\";\npub const query_version: u32 = {d};\npub const start_symbol = \"{s}\";\npub const start_version: u32 = {d};\n", .{ config.query.symbol, config.query.export_version, config.start.symbol, config.start.export_version });
    try out.print("pub const query_magic: u32 = {d};\npub const start_magic: u32 = {d};\n", .{ config.query.magic, config.start.magic });
    try out.print("pub const R4LQuery2 = extern struct {{\n    magic: u32 = {d},\n    abi_version: u32 = 2,\n    size: u32 = 24,\n    group: u32 = 0,\n    reserved: u64 = 0,\n}};\n", .{config.query.magic});
    try out.text("pub const R4XStartImport = shared.R4XStartImport;\npub const R4XStartContext2 = extern struct {\n");
    for (contract.r4x_start.context.fields) |field| {
        if (contains(config.start.remove_fields, field.name)) continue;
        var value = field.default_value orelse "0";
        if (std.mem.eql(u8, field.name, "magic")) value = try std.fmt.allocPrint(a, "{d}", .{config.start.magic});
        if (std.mem.eql(u8, field.name, "abi_major")) value = "2";
        if (std.mem.eql(u8, field.name, "abi_minor")) value = "0";
        if (std.mem.eql(u8, field.name, "size")) value = "120";
        try out.print("    @\"{s}\": {s} = {s},\n", .{ field.name, field.type.name.?, value });
    }
    try out.text("};\ncomptime {\n    if (@sizeOf(R4LQuery2) != 24 or @sizeOf(R4XStartContext2) != 120 or @offsetOf(R4XStartContext2, \"reserved2\") != 112) @compileError(\"Generation2 root layout\");\n}\n");
    for (contract.types) |payload| try out.print("const {s} = shared.{s};\n", .{ payload.name, payload.name });
    for (contract.groups) |group| {
        const count = group.slots.len;
        try out.text(try Formatter.zigNamespace(a, group));
        try out.print("pub const {s} = extern struct {{\n    magic: u32 = {d},\n    abi_version: u32 = {d},\n    size: u32 = {d},\n    flags: u32 = 0,\n", .{ group.table_type, group.magic, group.abi_version, 16 + 8 * count });
        for (group.slots) |slot| {
            try out.print("    @\"{s}\": u64 = 0,\n", .{slot.name});
        }
        try out.print("}};\ncomptime {{\n    if (@sizeOf({s}) != {d}) @compileError(\"Generation2 table size\");\n", .{ group.table_type, 16 + 8 * count });
        var i: usize = 0;
        for (group.slots) |slot| {
            try out.print("    if (@offsetOf({s}, \"{s}\") != {d}) @compileError(\"Generation2 slot offset\");\n", .{ group.table_type, slot.name, 16 + 8 * i });
            i += 1;
        }
        try out.text("}\n");
    }
    try out.text("\npub fn function(comptime Namespace: type, table: anytype, comptime field: []const u8) ?@field(Namespace, field) {\n    const t = table orelse return null;\n    if (t.size < @offsetOf(@typeInfo(@TypeOf(t)).pointer.child, field) + 8) return null;\n    const raw = @field(t, field);\n    return if (raw == 0) null else @ptrFromInt(raw);\n}\n");
    return out.bytes.items;
}

fn emitC(a: std.mem.Allocator, config: Resolved, contract: anytype, comptime Formatter: type) ![]const u8 {
    var out: Output = .{ .allocator = a };
    try out.text("/* Generated Generation2. DO NOT EDIT. */\n#ifndef R4OS_GENERATION2_H\n#define R4OS_GENERATION2_H\n#include <r4os/abi_generated.h>\n");
    try out.print("#define R4OS2_QUERY_MAGIC UINT32_C({d})\n#define R4OS2_START_MAGIC UINT32_C({d})\n#define R4OS2_QUERY_SYMBOL \"Query2\"\n#define R4OS2_START_SYMBOL \"R4XStart2\"\ntypedef struct {{ uint32_t magic, abi_version, size, group; uint64_t reserved; }} R4LQuery2;\ntypedef struct {{\n", .{ config.query.magic, config.start.magic });
    for (contract.r4x_start.context.fields) |field| if (!contains(config.start.remove_fields, field.name)) {
        const ctype = if (std.mem.eql(u8, field.type.name.?, "u16")) "uint16_t" else if (std.mem.eql(u8, field.type.name.?, "u32")) "uint32_t" else "uint64_t";
        try out.print("    {s} {s};\n", .{ ctype, field.name });
    };
    try out.text("} R4XStartContext2;\n_Static_assert(sizeof(R4LQuery2)==24, \"Query2 size\");\n_Static_assert(sizeof(R4XStartContext2)==120, \"Start2 size\");\n_Static_assert(offsetof(R4XStartContext2,reserved2)==112, \"Start2 tail\");\n");
    for (contract.groups) |group| {
        try out.text(try Formatter.cNamespace(a, group));
        const count = group.slots.len;
        try out.print("#define R4OS2_{s}_MAGIC UINT32_C({d})\n#define R4OS2_{s}_VERSION UINT32_C({d})\ntypedef struct {{\n    uint32_t magic, abi_version, size, flags;\n", .{ group.name, group.magic, group.name, group.abi_version });
        for (group.slots) |slot| {
            try out.print("    uint64_t {s};\n", .{slot.name});
        }
        try out.print("}} {s};\n_Static_assert(sizeof({s})=={d}, \"Generation2 table size\");\n", .{ group.table_type, group.table_type, 16 + 8 * count });
        var i: usize = 0;
        for (group.slots) |slot| {
            try out.print("_Static_assert(offsetof({s},{s})=={d}, \"Generation2 slot\");\n", .{ group.table_type, slot.name, 16 + 8 * i });
            i += 1;
        }
    }
    try out.text("typedef uint32_t (*R4XStartShouldCloseFn2)(const R4XStartContext2 *);\ntypedef void (*R4XStartYieldFn2)(const R4XStartContext2 *);\n#endif\n");
    return out.bytes.items;
}

fn emitRust(a: std.mem.Allocator, config: Resolved, contract: anytype, comptime Formatter: type) ![]const u8 {
    var out: Output = .{ .allocator = a };
    try out.text("// Generated Generation2. DO NOT EDIT.\n");
    try out.text("pub use super::{DriverApi2, ProtocolApi2, AudioBackend2, AudioBackendStatus2, AudioBackendRegisterFn2, AudioBackendStatusFn2, AudioCaptureBackend2, AudioCaptureRegisterFn2};\npub const DRIVER_MAGIC: u32 = super::driver_api2_magic;\npub const DRIVER_VERSION: u32 = super::driver_api2_version;\npub const PROTOCOL_MAGIC: u32 = super::protocol_api2_magic;\npub const PROTOCOL_VERSION: u32 = super::protocol_api2_version;\npub const AUDIO_BACKEND_MAGIC: u32 = super::audio_backend2_magic;\npub const AUDIO_BACKEND_VERSION: u32 = super::audio_backend2_version;\n");
    try out.text("pub type R4XStartShouldCloseFn2 = unsafe extern \"C\" fn(*const R4XStartContext2) -> u32;\npub type R4XStartYieldFn2 = unsafe extern \"C\" fn(*const R4XStartContext2);\n");
    try out.print("pub const QUERY_MAGIC: u32 = {d};\npub const START_MAGIC: u32 = {d};\n#[repr(C)]\n#[derive(Clone, Copy)]\npub struct R4LQuery2 {{ pub magic: u32, pub abi_version: u32, pub size: u32, pub group: u32, pub reserved: u64 }}\nimpl Default for R4LQuery2 {{ fn default() -> Self {{ Self {{ magic: QUERY_MAGIC, abi_version: 2, size: 24, group: 0, reserved: 0 }} }} }}\n#[repr(C)]\n#[derive(Clone, Copy)]\npub struct R4XStartContext2 {{\n", .{ config.query.magic, config.start.magic });
    for (contract.r4x_start.context.fields) |field| if (!contains(config.start.remove_fields, field.name)) {
        const name = if (std.mem.eql(u8, field.name, "yield")) "r#yield" else field.name;
        try out.print("    pub {s}: {s},\n", .{ name, field.type.name.? });
    };
    try out.text("}\nimpl Default for R4XStartContext2 { fn default() -> Self { Self {\n");
    for (contract.r4x_start.context.fields) |field| if (!contains(config.start.remove_fields, field.name)) {
        const name = if (std.mem.eql(u8, field.name, "yield")) "r#yield" else field.name;
        var value = field.default_value orelse "0";
        if (std.mem.eql(u8, field.name, "magic")) value = "START_MAGIC";
        if (std.mem.eql(u8, field.name, "abi_major")) value = "2";
        if (std.mem.eql(u8, field.name, "abi_minor")) value = "0";
        if (std.mem.eql(u8, field.name, "size")) value = "120";
        try out.print("    {s}: {s},\n", .{ name, value });
    };
    try out.text("} } }\nconst _: () = { assert!(core::mem::size_of::<R4LQuery2>() == 24); assert!(core::mem::size_of::<R4XStartContext2>() == 120); assert!(core::mem::offset_of!(R4XStartContext2,reserved2) == 112); };\n");
    for (contract.groups) |group| {
        const count = group.slots.len;
        try out.text(try Formatter.rustNamespace(a, group));
        try out.print("pub const {s}_MAGIC: u32 = {d};\n#[repr(C)]\n#[derive(Clone, Copy)]\npub struct {s} {{\n    pub magic: u32, pub abi_version: u32, pub size: u32, pub flags: u32,\n", .{ group.name, group.magic, group.table_type });
        for (group.slots) |slot| {
            try out.print("    pub {s}: u64,\n", .{slot.name});
        }
        try out.print("}}\nimpl Default for {s} {{ fn default() -> Self {{ Self {{ magic: {d}, abi_version: {d}, size: {d}, flags: 0,\n", .{ group.table_type, group.magic, group.abi_version, 16 + 8 * count });
        for (group.slots) |slot| {
            try out.print("    {s}: 0,\n", .{slot.name});
        }
        try out.print("}} }} }}\nconst _: () = {{ assert!(core::mem::size_of::<{s}>() == {d});\n", .{ group.table_type, 16 + 8 * count });
        var i: usize = 0;
        for (group.slots) |slot| {
            try out.print("    assert!(core::mem::offset_of!({s},{s}) == {d});\n", .{ group.table_type, slot.name, 16 + 8 * i });
            i += 1;
        }
        try out.text("};\n");
    }
    return out.bytes.items;
}

fn output(io: std.Io, a: std.mem.Allocator, path: []const u8, bytes: []const u8, write: bool) !void {
    if (write) {
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = bytes });
        return;
    }
    const old = try std.Io.Dir.cwd().readFileAlloc(io, path, a, .limited(8 * 1024 * 1024));
    if (!std.mem.eql(u8, old, bytes)) {
        std.debug.print("Generation2 generated artifact differs: {s}\n", .{path});
        return error.GenerationGeneratedDrift;
    }
}
fn emitTechnical(a: std.mem.Allocator, spec: Spec) ![]const u8 {
    var out: Output = .{ .allocator = a };
    try out.text("// Generated from canonical API/Generation2.json. DO NOT EDIT.\nconst base = @import(\"abi.zig\");\n");
    try out.print("pub const driver_api2_magic: u32 = {d};\npub const driver_api2_version: u32 = {d};\npub const protocol_api2_magic: u32 = {d};\npub const protocol_api2_version: u32 = {d};\npub const audio_backend2_magic: u32 = {d};\npub const audio_backend2_version: u32 = {d};\n", .{ spec.driver.magic, spec.driver.version, spec.driver.protocol_magic, spec.driver.protocol_version, spec.audio.magic, spec.audio.version });
    for (spec.callbacks) |callback| try out.print("pub const {s} = {s};\n", .{ callback.name, callback.zig_type });
    for (spec.technical) |record| {
        try out.print("pub const {s} = extern struct {{\n", .{record.name});
        for (record.fields) |field| {
            try out.print("    {s}: {s}", .{ field.name, field.zig_type });
            if (field.default_value) |value| try out.print(" = {s}", .{value});
            try out.text(",\n");
        }
        try out.text("};\ncomptime {\n");
        try out.print("    if (@sizeOf({s}) != {d} or @alignOf({s}) != {d}) @compileError(\"Canonical technical layout\");\n", .{ record.name, record.size, record.name, record.alignment });
        for (record.fields) |field| try out.print("    if (@offsetOf({s}, \"{s}\") != {d}) @compileError(\"Canonical technical field\");\n", .{ record.name, field.name, field.offset });
        try out.text("}\n");
    }
    return out.bytes.items;
}
pub fn process(allocator: std.mem.Allocator, io: std.Io, contract: anytype, write: bool, check: bool, update_baseline: bool, comptime Formatter: type) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const bytes = try std.Io.Dir.cwd().readFileAlloc(io, "API/Generation2.json", a, .limited(256 * 1024));
    const spec = (try std.json.parseFromSlice(Spec, a, bytes, .{})).value;
    try validate(spec, contract);
    try validateBaseline(a, io, spec, update_baseline);
    if (!write and !check) return;
    const config = resolve(contract);
    try output(io, a, "Generated/SDK/Zig/technical2_generated.zig", try emitTechnical(a, spec), write);
    try output(io, a, "Generated/Generation2/Zig/abi.zig", try emitZig(a, config, contract, Formatter), write);
    try output(io, a, "Generated/Generation2/C/include/r4os/generation2.h", try emitC(a, config, contract, Formatter), write);
    try output(io, a, "Generated/Generation2/Rust/generation2.rs", try emitRust(a, config, contract, Formatter), write);
    const inventory = try std.json.Stringify.valueAlloc(a, .{ .generation = @as(u32, 2), .query_symbol = contract.r4l_query.entry_symbol, .start_symbol = contract.r4x_start.entry.symbol, .groups = contract.groups }, .{ .whitespace = .indent_2 });
    try output(io, a, "Generated/Generation2/Inventory.json", inventory, write);
    if (write and update_baseline) try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = "API/Generation2.baseline.json", .data = bytes });
    std.debug.print("Generation2 {s}: independent canonical groups, roots, signatures and technical records.\n", .{if (write) "written" else "checked"});
}
fn recordNamed(spec: *Spec, name: []const u8) *Technical {
    for (spec.technical) |*record| if (std.mem.eql(u8, record.name, name)) return record;
    unreachable;
}
fn removeField(a: std.mem.Allocator, record: *Technical, name: []const u8) !void {
    var kept: std.ArrayList(TechnicalField) = .empty;
    for (record.fields) |field| if (!std.mem.eql(u8, field.name, name)) {
        try kept.append(a, field);
    };
    if (kept.items.len + 1 != record.fields.len) return error.GenerationMutationFieldMissing;
    record.fields = try kept.toOwnedSlice(a);
}
fn validateComplete(a: std.mem.Allocator, io: std.Io, spec: Spec, contract: anytype) !void {
    try validate(spec, contract);
    try validateBaseline(a, io, spec, false);
}
pub fn selftest(allocator: std.mem.Allocator, io: std.Io, contract: anytype) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const bytes = try std.Io.Dir.cwd().readFileAlloc(io, "API/Generation2.json", a, .limited(256 * 1024));
    const spec = (try std.json.parseFromSlice(Spec, a, bytes, .{})).value;
    try validateComplete(a, io, spec, contract);
    const contract_bytes = try std.json.Stringify.valueAlloc(a, contract.*, .{});
    for (0..17) |i| {
        // Independent copies preserve the unmutated source and baseline.
        var mutated = (try std.json.parseFromSlice(Spec, a, bytes, .{})).value;
        var target = (try std.json.parseFromSlice(@TypeOf(contract.*), a, contract_bytes, .{})).value;
        switch (i) {
            0 => target.r4l_query.entry_symbol = "Query",
            1 => target.r4x_start.entry.symbol = "R4XStart",
            2 => mutated.generation = 3,
            3 => target.groups[0].slots = target.groups[0].slots[1..],
            4 => target.groups[0].magic = 0x31535952,
            5 => mutated.selection.default_generation = 1,
            6 => mutated.selection.missing_generation = "fallback",
            7 => target.r4l_query.layout.size = 32,
            8 => target.groups[0].abi_version = 0,
            9 => mutated.driver.protocol_magic = mutated.driver.magic,
            10 => try removeField(a, recordNamed(&mutated, "DriverApi2"), "register_audio_output_backend"),
            11 => mutated.audio.magic = 3,
            12 => try removeField(a, recordNamed(&mutated, "AudioBackendStatus2"), "writes"),
            13 => {
                const fields = recordNamed(&mutated, "ProtocolApi2").fields;
                std.mem.swap(TechnicalField, &fields[fields.len - 3], &fields[fields.len - 2]);
            },
            14 => {
                const record = recordNamed(&mutated, "ProtocolApi2");
                record.fields = record.fields[0 .. record.fields.len - 2];
            },
            15, 16 => {
                const name = if (i == 15) "link_io" else "process_status";
                for (recordNamed(&mutated, "ProtocolApi2").fields) |*field| {
                    if (std.mem.eql(u8, field.name, name)) {
                        field.name = "unrestricted_kernel";
                        field.zig_type = "?*anyopaque";
                    }
                }
            },
            else => unreachable,
        }
        if (validateComplete(a, io, mutated, &target)) |_| return error.GenerationMutationAccepted else |_| {}
    }
    std.debug.print("Generation2 selftest:17 incompatible identity/removal/selection/revision/tail mutations rejected.\n", .{});
}
