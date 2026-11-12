const std = @import("std");

// A controlled projection of the canonical contract, not a second slot list.
const Config = struct {
    schema: u32,
    generation: u32,
    source: []const u8,
    query: struct { symbol: []const u8, export_version: u32, magic: u32, abi_version: u32, size: u32, remove_fields: []const []const u8 },
    start: struct { symbol: []const u8, export_version: u32, magic: u32, abi_major: u32, abi_minor: u32, size: u32, remove_fields: []const []const u8 },
    tables: struct {
        magic_high_byte: u32,
        initial_version: u32,
        // The canonical contract already enforces append-only version bumps.
        // Retain that revision progression in the compact table namespace.
        source_versions: struct { R4SYS: u32, R4DESK: u32, R4DRAW: u32, R4NET: u32, R4AUDIO: u32, R4DEV: u32 },
        remove_slots: struct { R4SYS: []const []const u8, R4DEV: []const []const u8 },
    },
    driver: struct { init_symbol: []const u8, protocol_init_symbol: []const u8, export_version: u32, initial_version: u32, source_version: u32, protocol_source_version: u32, protocol_magic: u32, remove_fields: []const []const u8, protocol_tail_fields: []const []const u8, magic: u32 },
    audio_status: struct { name: []const u8, remove_fields: []const []const u8, backend_version: u32, backend_magic: u32 },
    selection: struct { default_generation: u32, profile_selection: []const u8, mixed_start_generations: []const u8, missing_generation: []const u8, shared_resource_owners: bool, profiles: []const []const u8 },
};
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

fn contains(names: []const []const u8, name: []const u8) bool {
    for (names) |item| if (std.mem.eql(u8, item, name)) return true;
    return false;
}
fn removed(config: Config, group: []const u8, name: []const u8) bool {
    if (std.mem.eql(u8, group, "R4SYS")) return contains(config.tables.remove_slots.R4SYS, name);
    if (std.mem.eql(u8, group, "R4DEV")) return contains(config.tables.remove_slots.R4DEV, name);
    return false;
}
fn magic(config: Config, old: u32) u32 {
    return (old & 0x00ffffff) | (config.tables.magic_high_byte << 24);
}

fn tableVersion(config: Config, group: anytype) !u32 {
    inline for (std.meta.fields(@TypeOf(config.tables.source_versions))) |field| {
        if (std.mem.eql(u8, group.name, field.name)) {
            const initial = @field(config.tables.source_versions, field.name);
            if (initial == 0 or group.abi_version < initial) return error.GenerationSourceRevision;
            return std.math.add(u32, config.tables.initial_version, group.abi_version - initial) catch error.GenerationSourceRevision;
        }
    }
    return error.GenerationUnknownGroup;
}

fn validate(config: Config, contract: anytype) !void {
    if (config.schema != 1 or config.generation != 2 or !std.mem.eql(u8, config.source, "API/ApiContract.json")) return error.GenerationIdentity;
    if (!std.mem.eql(u8, config.query.symbol, "Query2") or config.query.export_version != 2 or config.query.magic != 0x324c3452 or config.query.abi_version != 2 or config.query.size != 24) return error.GenerationQueryIdentity;
    if (!std.mem.eql(u8, config.start.symbol, "R4XStart2") or config.start.export_version != 2 or config.start.magic != 0x32583452 or config.start.abi_major != 2 or config.start.abi_minor != 0 or config.start.size != 120) return error.GenerationStartIdentity;
    if (config.tables.magic_high_byte != '2' or config.tables.initial_version != 1) return error.GenerationTableIdentity;
    const origins = config.tables.source_versions;
    if (origins.R4SYS != 36 or origins.R4DESK != 21 or origins.R4DRAW != 39 or origins.R4NET != 2 or origins.R4AUDIO != 4 or origins.R4DEV != 36) return error.GenerationSourceRevision;
    if (!contains(config.start.remove_fields, "reserved_runtime") or config.start.remove_fields.len != 1 or !contains(config.query.remove_fields, "kernel_bridge") or config.query.remove_fields.len != 1) return error.GenerationFieldRemoval;
    if (!std.mem.eql(u8, config.driver.init_symbol, "DriverInit2") or !std.mem.eql(u8, config.driver.protocol_init_symbol, "ProtocolInit2") or config.driver.export_version != 2) return error.GenerationDriverIdentity;
    if (config.driver.magic != 0x32495044 or config.driver.protocol_magic != 0x32495050 or config.driver.initial_version != 1 or config.driver.source_version != 39 or config.driver.protocol_source_version != 1) return error.GenerationDriverIdentity;
    if (config.driver.remove_fields.len != 2 or !contains(config.driver.remove_fields, "register_audio_backend") or !contains(config.driver.remove_fields, "register_synth_engine")) return error.GenerationFieldRemoval;
    if (config.driver.protocol_tail_fields.len != 3 or !std.mem.eql(u8, config.driver.protocol_tail_fields[0], "protocol_dispatch") or !std.mem.eql(u8, config.driver.protocol_tail_fields[1], "link_io") or !std.mem.eql(u8, config.driver.protocol_tail_fields[2], "process_status")) return error.GenerationProtocolTail;
    if (!std.mem.eql(u8, config.audio_status.name, "AudioBackendStatus2") or config.audio_status.backend_version != 3 or config.audio_status.backend_magic != 0x32425541 or config.audio_status.remove_fields.len != 6) return error.GenerationAudioIdentity;
    for ([_][]const u8{ "last_write_ticks", "max_write_ticks", "total_write_ticks", "last_refill_ticks", "max_refill_ticks", "total_refill_ticks" }) |field| if (!contains(config.audio_status.remove_fields, field)) return error.GenerationFieldRemoval;
    if (config.selection.default_generation != 1 or !config.selection.shared_resource_owners or !std.mem.eql(u8, config.selection.missing_generation, "reject") or !std.mem.eql(u8, config.selection.mixed_start_generations, "reject")) return error.GenerationSelection;
    var drops: usize = 0;
    for (contract.groups) |group| {
        _ = try tableVersion(config, group);
        for (group.slots) |slot| {
            if (!removed(config, group.name, slot.name)) continue;
            if (slot.state != .tombstone or slot.signature != null or slot.required) return error.GenerationDropsLiveSlot;
            drops += 1;
        }
    }
    if (drops != 4 or config.tables.remove_slots.R4SYS.len != 1 or config.tables.remove_slots.R4DEV.len != 3) return error.GenerationRemovalSet;
}

fn emitZig(a: std.mem.Allocator, config: Config, contract: anytype) ![]const u8 {
    var out: Output = .{ .allocator = a };
    try out.text("pub const R4XStartShouldCloseFn2 = *const fn (*const R4XStartContext2) callconv(.c) u32;\npub const R4XStartYieldFn2 = *const fn (*const R4XStartContext2) callconv(.c) void;\n");
    try out.text("// Generated from API/ApiContract.json and API/Generation2.json. DO NOT EDIT.\nconst std = @import(\"std\");\nconst base = @import(\"r4os_base_abi\");\npub const shared = if (@hasDecl(base, \"abi\")) base.abi else base;\n\n");
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
    for (contract.groups) |group| {
        var count: usize = 0;
        for (group.slots) |slot| if (!removed(config, group.name, slot.name)) {
            count += 1;
        };
        try out.print("pub const {s}2 = shared.{s};\npub const {s}2 = extern struct {{\n    magic: u32 = {d},\n    abi_version: u32 = {d},\n    size: u32 = {d},\n    flags: u32 = 0,\n", .{ group.fn_namespace, group.fn_namespace, group.table_type, magic(config, group.magic), try tableVersion(config, group), 16 + 8 * count });
        for (group.slots) |slot| if (!removed(config, group.name, slot.name)) {
            try out.print("    @\"{s}\": u64 = 0,\n", .{slot.name});
        };
        try out.print("}};\ncomptime {{\n    if (@sizeOf({s}2) != {d}) @compileError(\"Generation2 table size\");\n", .{ group.table_type, 16 + 8 * count });
        var i: usize = 0;
        for (group.slots) |slot| if (!removed(config, group.name, slot.name)) {
            try out.print("    if (@offsetOf({s}2, \"{s}\") != {d}) @compileError(\"Generation2 slot offset\");\n", .{ group.table_type, slot.name, 16 + 8 * i });
            i += 1;
        };
        try out.text("}\n");
    }
    try out.text("\npub fn function(comptime Namespace: type, table: anytype, comptime field: []const u8) ?@field(Namespace, field) {\n    const t = table orelse return null;\n    if (t.size < @offsetOf(@typeInfo(@TypeOf(t)).pointer.child, field) + 8) return null;\n    const raw = @field(t, field);\n    return if (raw == 0) null else @ptrFromInt(raw);\n}\n");
    return out.bytes.items;
}

fn emitC(a: std.mem.Allocator, config: Config, contract: anytype) ![]const u8 {
    var out: Output = .{ .allocator = a };
    try out.text("/* Generated Generation2. DO NOT EDIT. */\n#ifndef R4OS_GENERATION2_H\n#define R4OS_GENERATION2_H\n#include <r4os/abi_generated.h>\n");
    try out.print("#define R4OS2_QUERY_MAGIC UINT32_C({d})\n#define R4OS2_START_MAGIC UINT32_C({d})\n#define R4OS2_QUERY_SYMBOL \"Query2\"\n#define R4OS2_START_SYMBOL \"R4XStart2\"\ntypedef struct {{ uint32_t magic, abi_version, size, group; uint64_t reserved; }} R4LQuery2;\ntypedef struct {{\n", .{ config.query.magic, config.start.magic });
    for (contract.r4x_start.context.fields) |field| if (!contains(config.start.remove_fields, field.name)) {
        const ctype = if (std.mem.eql(u8, field.type.name.?, "u16")) "uint16_t" else if (std.mem.eql(u8, field.type.name.?, "u32")) "uint32_t" else "uint64_t";
        try out.print("    {s} {s};\n", .{ ctype, field.name });
    };
    try out.text("} R4XStartContext2;\n_Static_assert(sizeof(R4LQuery2)==24, \"Query2 size\");\n_Static_assert(sizeof(R4XStartContext2)==120, \"Start2 size\");\n_Static_assert(offsetof(R4XStartContext2,reserved2)==112, \"Start2 tail\");\n");
    for (contract.groups) |group| {
        var count: usize = 0;
        for (group.slots) |slot| if (!removed(config, group.name, slot.name)) {
            count += 1;
        };
        try out.print("#define R4OS2_{s}_MAGIC UINT32_C({d})\n#define R4OS2_{s}_VERSION UINT32_C({d})\ntypedef struct {{\n    uint32_t magic, abi_version, size, flags;\n", .{ group.name, magic(config, group.magic), group.name, try tableVersion(config, group) });
        for (group.slots) |slot| if (!removed(config, group.name, slot.name)) {
            try out.print("    uint64_t {s};\n", .{slot.name});
        };
        try out.print("}} {s}2;\n_Static_assert(sizeof({s}2)=={d}, \"Generation2 table size\");\n", .{ group.table_type, group.table_type, 16 + 8 * count });
        var i: usize = 0;
        for (group.slots) |slot| if (!removed(config, group.name, slot.name)) {
            try out.print("_Static_assert(offsetof({s}2,{s})=={d}, \"Generation2 slot\");\n", .{ group.table_type, slot.name, 16 + 8 * i });
            i += 1;
        };
    }
    try out.text("typedef uint32_t (*R4XStartShouldCloseFn2)(const R4XStartContext2 *);\ntypedef void (*R4XStartYieldFn2)(const R4XStartContext2 *);\n#endif\n");
    return out.bytes.items;
}

fn emitRust(a: std.mem.Allocator, config: Config, contract: anytype) ![]const u8 {
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
        var count: usize = 0;
        for (group.slots) |slot| if (!removed(config, group.name, slot.name)) {
            count += 1;
        };
        try out.print("pub use super::{s} as {s}2;\npub const {s}_MAGIC: u32 = {d};\n#[repr(C)]\n#[derive(Clone, Copy)]\npub struct {s}2 {{\n    pub magic: u32, pub abi_version: u32, pub size: u32, pub flags: u32,\n", .{ group.fn_namespace, group.fn_namespace, group.name, magic(config, group.magic), group.table_type });
        for (group.slots) |slot| if (!removed(config, group.name, slot.name)) {
            try out.print("    pub {s}: u64,\n", .{slot.name});
        };
        try out.print("}}\nimpl Default for {s}2 {{ fn default() -> Self {{ Self {{ magic: {d}, abi_version: {d}, size: {d}, flags: 0,\n", .{ group.table_type, magic(config, group.magic), try tableVersion(config, group), 16 + 8 * count });
        for (group.slots) |slot| if (!removed(config, group.name, slot.name)) {
            try out.print("    {s}: 0,\n", .{slot.name});
        };
        try out.print("}} }} }}\nconst _: () = {{ assert!(core::mem::size_of::<{s}2>() == {d});\n", .{ group.table_type, 16 + 8 * count });
        var i: usize = 0;
        for (group.slots) |slot| if (!removed(config, group.name, slot.name)) {
            try out.print("    assert!(core::mem::offset_of!({s}2,{s}) == {d});\n", .{ group.table_type, slot.name, 16 + 8 * i });
            i += 1;
        };
        try out.text("};\n");
        // Provider materialization copies only function addresses from the
        // canonical owner. It creates no second resource registry or state.
        try out.print("impl {s}2 {{\n    pub fn project_provider(source: &super::{s}) -> Self {{ Self {{\n", .{ group.table_type, group.table_type });
        for (group.slots) |slot| if (!removed(config, group.name, slot.name) and slot.state == .function) {
            try out.print("        {s}: source.{s} as u64,\n", .{ slot.name, slot.name });
        };
        try out.text("        ..Self::default()\n    } }\n}\n");
    }
    return out.bytes.items;
}

const SlotInfo = struct { group: []const u8, name: []const u8, source_number: u32, source_offset: u32, number: ?u32, offset: ?u32, removed: bool };
fn emitInventory(a: std.mem.Allocator, config: Config, contract: anytype) ![]const u8 {
    var slots: std.ArrayList(SlotInfo) = .empty;
    for (contract.groups) |group| {
        var number: u32 = 0;
        for (group.slots) |slot| {
            const drop = removed(config, group.name, slot.name);
            try slots.append(a, .{ .group = group.name, .name = slot.name, .source_number = slot.number, .source_offset = slot.offset, .number = if (drop) null else number, .offset = if (drop) null else 16 + number * 8, .removed = drop });
            if (!drop) number += 1;
        }
    }
    return std.json.Stringify.valueAlloc(a, .{ .generation = @as(u32, 2), .query_symbol = config.query.symbol, .start_symbol = config.start.symbol, .slots = slots.items }, .{ .whitespace = .indent_2 });
}
fn output(io: std.Io, a: std.mem.Allocator, path: []const u8, bytes: []const u8, write: bool) !void {
    const dir = std.Io.Dir.cwd();
    if (write) {
        if (std.fs.path.dirname(path)) |parent| try dir.createDirPath(io, parent);
        try dir.writeFile(io, .{ .sub_path = path, .data = bytes });
    } else {
        const old = try dir.readFileAlloc(io, path, a, .limited(8 * 1024 * 1024));
        if (!std.mem.eql(u8, old, bytes)) {
            std.debug.print("Generation2 generated artifact differs: {s}\n", .{path});
            return error.GenerationArtifactDrift;
        }
    }
}

pub fn process(allocator: std.mem.Allocator, io: std.Io, contract: anytype, write: bool, check: bool) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const raw = try std.Io.Dir.cwd().readFileAlloc(io, "API/Generation2.json", a, .limited(64 * 1024));
    const parsed = try std.json.parseFromSlice(Config, a, raw, .{});
    const config = parsed.value;
    try validate(config, contract);
    if (!write and !check) return;
    try output(io, a, "Generated/SDK/Zig/technical2_generated.zig", try emitTechnical(a, config), write);
    try output(io, a, "Generated/Generation2/Zig/abi.zig", try emitZig(a, config, contract), write);
    try output(io, a, "Generated/Generation2/C/include/r4os/generation2.h", try emitC(a, config, contract), write);
    try output(io, a, "Generated/Generation2/Rust/generation2.rs", try emitRust(a, config, contract), write);
    try output(io, a, "Generated/Generation2/Inventory.json", try emitInventory(a, config, contract), write);
    std.debug.print("Generation2 {s}: canonical slots projected without four retired entries.\n", .{if (write) "written" else "checked"});
}

pub fn selftest(allocator: std.mem.Allocator, io: std.Io, contract: anytype) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const raw = try std.Io.Dir.cwd().readFileAlloc(io, "API/Generation2.json", a, .limited(64 * 1024));
    const parsed = try std.json.parseFromSlice(Config, a, raw, .{});
    try validate(parsed.value, contract);
    for (0..17) |i| {
        var mutated = parsed.value;
        switch (i) {
            0 => mutated.query.symbol = "Query",
            1 => mutated.start.symbol = "R4XStart",
            2 => mutated.generation = 3,
            3 => mutated.tables.remove_slots.R4SYS = &.{"write"},
            4 => mutated.tables.magic_high_byte = '1',
            5 => mutated.selection.default_generation = 2,
            6 => mutated.selection.missing_generation = "fallback",
            7 => mutated.query.size = 32,
            8 => mutated.tables.source_versions.R4SYS = 35,
            9 => mutated.driver.protocol_magic = mutated.driver.magic,
            10 => mutated.driver.remove_fields = &.{"register_audio_output_backend"},
            11 => mutated.audio_status.backend_magic = 3,
            12 => mutated.audio_status.remove_fields = &.{"writes"},
            13 => mutated.driver.protocol_tail_fields = &.{ "link_io", "protocol_dispatch" },
            14 => mutated.driver.protocol_tail_fields = &.{"protocol_dispatch"},
            15 => mutated.driver.protocol_tail_fields = &.{ "protocol_dispatch", "unrestricted_kernel" },
            16 => mutated.driver.protocol_tail_fields = &.{ "protocol_dispatch", "link_io", "unrestricted_kernel" },
            else => unreachable,
        }
        if (validate(mutated, contract)) |_| return error.GenerationMutationAccepted else |_| {}
    }
    std.debug.print("Generation2 selftest: 17 incompatible identity/removal/selection/revision/tail mutations rejected.\n", .{});
}

fn emitTechnical(a: std.mem.Allocator, config: Config) ![]const u8 {
    var out: Output = .{ .allocator = a };
    try out.text("// Generated from API/Generation2.json and canonical technical ABI types. DO NOT EDIT.\nconst std = @import(\"std\");\nconst base = @import(\"abi.zig\");\n");
    try out.print("pub const driver_api2_magic: u32 = {d};\npub const driver_api2_version: u32 = {d} + base.driver_api_version - {d};\npub const protocol_api2_magic: u32 = {d};\npub const protocol_api2_version: u32 = {d} + base.protocol_api_version - {d};\npub const audio_backend2_magic: u32 = {d};\npub const audio_backend2_version: u32 = {d};\n", .{ config.driver.magic, config.driver.initial_version, config.driver.source_version, config.driver.protocol_magic, config.driver.initial_version, config.driver.protocol_source_version, config.audio_status.backend_magic, config.audio_status.backend_version });
    try out.text("const driver_drops = [_][]const u8{");
    for (config.driver.remove_fields) |field| try out.print("\"{s}\",", .{field});
    try out.text("};\nconst status_drops = [_][]const u8{");
    for (config.audio_status.remove_fields) |field| try out.print("\"{s}\",", .{field});
    try out.text("};\n");
    try out.text(@embedFile("generation2_technical.zig.in"));
    return out.bytes.items;
}
