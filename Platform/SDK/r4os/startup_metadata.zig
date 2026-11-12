//! Build-owned startup records derived from the canonical manifest parser
//! and Contract metadata. C/Rust consume records, never an import grammar.
const std = @import("std");
const abi = @import("r4os_contract").abi;
const imports = @import("import_spec.zig");

pub fn profileForClass(name: []const u8) !abi.R4AppProfile {
    inline for (std.meta.tags(abi.R4AppProfile)) |profile| {
        if (std.mem.eql(u8, name, @tagName(abi.r4AppProfileMeta(profile).app_class))) return profile;
    }
    return error.InvalidAppClass;
}

const Platform = struct { id: u32 = 0, magic: u32 = 0, version: u32 = 0, size: u32 = 0 };
fn platformFor(name: []const u8) Platform {
    inline for (abi.r4_platform_apis) |group| {
        if (std.ascii.eqlIgnoreCase(name, group.name)) {
            const Table = switch (group.group) {
                .r4sys => abi.R4XStartR4Sys,
                .r4desk => abi.R4XStartR4Desk,
                .r4draw => abi.R4XStartR4Draw,
                .r4net => abi.R4XStartR4Net,
                .r4audio => abi.R4XStartR4Audio,
                .r4dev => abi.R4XStartR4Dev,
            };
            const current: Table = .{};
            return .{ .id = @intFromEnum(group.group), .magic = current.magic, .version = current.abi_version, .size = @sizeOf(Table) };
        }
    }
    return .{};
}

fn append(out: *std.ArrayList(u8), a: std.mem.Allocator, comptime fmt: []const u8, args: anytype) !void {
    const text = try std.fmt.allocPrint(a, fmt, args);
    defer a.free(text);
    try out.appendSlice(a, text);
}

pub fn rust(a: std.mem.Allocator, profile: abi.R4AppProfile, values: []const []const u8) ![]u8 {
    const meta = abi.r4AppProfileMeta(profile);
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(a);
    try append(&out, a, "// Generated from module.R4MF by the SDK; do not edit.\n__r4os_startup::StartupInfo {{ app_class: __r4os_startup::abi::R4XStartAppClass::{s}, required_groups: {d}, imports: &[\n", .{ @tagName(meta.app_class), meta.required_groups });
    for (values) |value| {
        const spec = try imports.parse(value);
        const p = platformFor(spec.module_name);
        try append(&out, a, "    __r4os_startup::ImportSpec {{ module_name: b\"{s}\", symbol_name: b\"{s}\", minimum: {d}, optional: {}, group_id: {d}, magic: {d}, version: {d}, size: {d} }},\n", .{ spec.module_name, spec.symbol_name, spec.minimum, spec.optional, p.id, p.magic, p.version, p.size });
    }
    try out.appendSlice(a, "] }\n");
    return out.toOwnedSlice(a);
}

pub fn c(a: std.mem.Allocator, profile: abi.R4AppProfile, values: []const []const u8) ![]u8 {
    const meta = abi.r4AppProfileMeta(profile);
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(a);
    try append(&out, a, "{{ .profile = {d}, .app_class = {d}u, .required_groups = {d}u, .import_count = {d}u, .imports = (const R4StartupImport[]){{", .{ @intFromEnum(profile), @intFromEnum(meta.app_class), meta.required_groups, values.len });
    for (values) |value| {
        const spec = try imports.parse(value);
        const p = platformFor(spec.module_name);
        try append(&out, a, "{{\"{s}\",\"{s}\",{d}u,{d}u,{d}u,{d}u,{d}u,{d}u}},", .{ spec.module_name, spec.symbol_name, spec.minimum, @intFromBool(spec.optional), p.id, p.magic, p.version, p.size });
    }
    try out.appendSlice(a, "} }");
    return out.toOwnedSlice(a);
}

test "common startup metadata retains optional named imports and current platform requirements" {
    const a = std.testing.allocator;
    const values = [_][]const u8{ "R4SYS:Query:1", "R4STD:SETTINGS_V1:1", "R4NV:BACKEND_V1:3:1" };
    const r = try rust(a, .console, &values);
    defer a.free(r);
    const cc = try c(a, .console, &values);
    defer a.free(cc);
    try std.testing.expect(std.mem.indexOf(u8, r, "minimum: 3, optional: true, group_id: 0") != null);
    try std.testing.expect(std.mem.indexOf(u8, cc, "\"R4NV\",\"BACKEND_V1\",3u,1u,0u,0u,0u,0u") != null);
    try std.testing.expectEqual(abi.r4xstart_r4sys_magic, platformFor("r4sys").magic);
    try std.testing.expectEqual((abi.R4XStartR4Sys{}).abi_version, platformFor("R4SYS").version);
    try std.testing.expectEqual(@as(u32, @sizeOf(abi.R4XStartR4Sys)), platformFor("R4SYS").size);
    try std.testing.expectEqual(abi.R4AppProfile.desktop, try profileForClass("gui"));
    try std.testing.expectError(error.InvalidImport, rust(a, .console, &.{"R4SYS:Query:1:1"}));
}

/// New raw-entry admission facts; kernel already resolves every named import.
pub fn rust2(a: std.mem.Allocator, profile: abi.R4AppProfile, count: usize) ![]u8 {
    const meta = abi.r4AppProfileMeta(profile);
    return std.fmt.allocPrint(a, "__r4os_startup::platform2::StartupInfo {{ app_class: {d}, required_groups: {d}, import_count: {d} }}\n", .{ @intFromEnum(meta.app_class), meta.required_groups, count });
}

pub fn c2(a: std.mem.Allocator, profile: abi.R4AppProfile, count: usize) ![]u8 {
    const meta = abi.r4AppProfileMeta(profile);
    return std.fmt.allocPrint(a, "{{{d}u,{d}u,{d}u}}", .{ @intFromEnum(meta.app_class), meta.required_groups, count });
}

/// Normal App2 entry retains the complete ordered manifest, including named
/// independent libraries. No first-generation table header enters these facts.
pub fn app2(a: std.mem.Allocator, language: enum { zig, c, rust }, profile: abi.R4AppProfile, values: []const []const u8) ![]u8 {
    const meta = abi.r4AppProfileMeta(profile);
    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(a);
    switch (language) {
        .zig => try append(&out, a, "const r4os = @import(\"r4os\");\npub const startup: r4os.startup2.StartupInfo = .{{ .profile = {d}, .app_class = {d}, .required_groups = {d}, .import_count = {d}, .imports = &.{{\n", .{ @intFromEnum(profile), @intFromEnum(meta.app_class), meta.required_groups, values.len }),
        .c => try append(&out, a, "{{ {d}u, {d}u, {d}u, {d}u, (const R4App2Import[]){{", .{ @intFromEnum(profile), @intFromEnum(meta.app_class), meta.required_groups, values.len }),
        .rust => try append(&out, a, "__r4os_startup::app2::StartupInfo {{ profile: {d}, app_class: {d}, required_groups: {d}, imports: &[\n", .{ @intFromEnum(profile), @intFromEnum(meta.app_class), meta.required_groups }),
    }
    for (values) |value| {
        const spec = try imports.parse(value);
        const p = platformFor(spec.module_name);
        switch (language) {
            .zig => try append(&out, a, ".{{ .module_name = \"{s}\", .symbol_name = \"{s}\", .minimum = {d}, .optional = {d}, .group_id = {d} }},\n", .{ spec.module_name, spec.symbol_name, spec.minimum, @intFromBool(spec.optional), p.id }),
            .c => try append(&out, a, "{{\"{s}\",\"{s}\",{d}u,{d}u,{d}u,0u}},", .{ spec.module_name, spec.symbol_name, spec.minimum, @intFromBool(spec.optional), p.id }),
            .rust => try append(&out, a, "__r4os_startup::app2::ImportSpec {{ module_name: b\"{s}\\0\".as_ptr(), symbol_name: b\"{s}\\0\".as_ptr(), minimum: {d}, optional: {d}, group_id: {d}, reserved: 0 }},\n", .{ spec.module_name, spec.symbol_name, spec.minimum, @intFromBool(spec.optional), p.id }),
        }
    }
    try out.appendSlice(a, switch (language) {
        .zig => "} };\n",
        .c => "} }",
        .rust => "] }\n",
    });
    return out.toOwnedSlice(a);
}
