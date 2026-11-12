const std = @import("std");
const abi = @import("r4os_technical_abi");
const core_source = @embedFile("r4os_generated_abi_source");
const export_prefix = "pub const ";
const core_names = blk: {
    @setEvalBranchQuota(10000000);
    var lines = std.mem.splitScalar(u8, core_source, '\n');
    var count: usize = 0;
    while (lines.next()) |line| if (std.mem.startsWith(u8, line, export_prefix)) {
        count += 1;
    };
    var names: [count]struct { []const u8, void } = undefined;
    lines.reset();
    var i: usize = 0;
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, export_prefix)) continue;
        const rest = line[export_prefix.len..];
        var end: usize = 0;
        while (end < rest.len and (std.ascii.isAlphanumeric(rest[end]) or rest[end] == '_')) : (end += 1) {}
        if (end == 0) @compileError("Unsupported generated ABI export name");
        names[i] = .{ rest[0..end], {} };
        i += 1;
    }
    break :blk std.StaticStringMap(void).initComptime(names);
};

// Complement ApiContractGen's public C header from the same append-only Zig
// types already reflected by the Rust generator. No second technical schema.
pub const path = "Generated/SDK/C/include/r4os/abi_technical_generated.h";
pub const Result = struct { bytes: []const u8, structs: usize, enums: usize, aliases: usize, constants: usize };
const Output = struct {
    allocator: std.mem.Allocator,
    bytes: std.ArrayList(u8) = .empty,
    fn text(self: *Output, value: []const u8) !void {
        try self.bytes.appendSlice(self.allocator, value);
    }
    fn print(self: *Output, comptime format: []const u8, args: anytype) !void {
        try self.text(try std.fmt.allocPrint(self.allocator, format, args));
    }
};

fn technical(comptime name: []const u8) bool {
    return !core_names.has(name) and
        !std.mem.eql(u8, name, "R4AppProfileMeta") and
        !std.mem.eql(u8, name, "R4PlatformApiMeta") and
        !std.mem.eql(u8, name, "R4ApiSlotMeta");
}
fn localName(comptime T: type) []const u8 {
    const full = @typeName(T);
    const start = if (std.mem.lastIndexOfScalar(u8, full, '.')) |i| i + 1 else 0;
    const name = full[start..];
    if (@hasDecl(abi, name) and @field(abi, name) == T) return name;
    inline for (std.meta.declarations(abi)) |decl| {
        const value = @field(abi, decl.name);
        if (@TypeOf(value) == type and value == T) return decl.name;
    }
    @compileError("C ABI type needs its canonical public name: " ++ full);
}
fn cName(comptime name: []const u8) []const u8 {
    return if (std.mem.startsWith(u8, name, "R4")) name else "R4" ++ name;
}
fn fieldName(comptime name: []const u8) []const u8 {
    const keywords = .{ "auto", "break", "case", "char", "const", "continue", "default", "do", "double", "else", "enum", "extern", "float", "for", "goto", "if", "inline", "int", "long", "register", "restrict", "return", "short", "signed", "sizeof", "static", "struct", "switch", "typedef", "union", "unsigned", "void", "volatile", "while", "_Alignas", "_Alignof", "_Atomic", "_Bool", "_Complex", "_Generic", "_Imaginary", "_Noreturn", "_Static_assert", "_Thread_local", "bool", "true", "false", "asm", "typeof" };
    inline for (keywords) |keyword| if (std.mem.eql(u8, name, keyword)) return name ++ "_";
    return name;
}
fn upper(out: *Output, value: []const u8) !void {
    for (value) |ch| try out.bytes.append(out.allocator, if (std.ascii.isAlphanumeric(ch) or ch == '_') std.ascii.toUpper(ch) else '_');
}
fn macro(out: *Output, value: []const u8) !void {
    if (!(value.len >= 2 and std.ascii.toLower(value[0]) == 'r' and value[1] == '4'))
        try out.text(if (std.mem.startsWith(u8, value, "remote_")) "R4_" else "R4OS_");
    try upper(out, value);
}
fn enumPrefix(out: *Output, name: []const u8) !void {
    for (name, 0..) |ch, i| {
        if (i != 0 and std.ascii.isUpper(ch) and
            (!std.ascii.isUpper(name[i - 1]) or (i + 1 < name.len and std.ascii.isLower(name[i + 1])))) try out.text("_");
        try out.bytes.append(out.allocator, std.ascii.toUpper(ch));
    }
}

// Recursive C declarators preserve const at each pointer level, pointers to
// arrays, nullable callback pointers, and borrowed pointers to callback slots.
fn declaration(out: *Output, comptime T: type, name: []const u8, is_const: bool) anyerror!void {
    switch (@typeInfo(T)) {
        .optional => |o| {
            if (@typeInfo(o.child) != .pointer) @compileError("Tagged optional reached C ABI: " ++ @typeName(T));
            try declaration(out, o.child, name, is_const);
        },
        .pointer => |p| {
            if (p.size == .slice) @compileError("Native slice reached C ABI: " ++ @typeName(T));
            const pointer_name = try std.fmt.allocPrint(out.allocator, "*{s}{s}", .{ if (is_const) " const " else "", name });
            if (@typeInfo(p.child) == .@"fn") {
                const f = @typeInfo(p.child).@"fn";
                if (comptime f.is_generic or f.is_var_args or !std.meta.eql(f.calling_convention, .c)) @compileError("Unsupported C callback: " ++ @typeName(T));
                var params = Output{ .allocator = out.allocator };
                inline for (f.params, 0..) |param, i| {
                    if (i != 0) try params.text(", ");
                    try declaration(&params, param.type.?, "", false);
                }
                if (f.params.len == 0) try params.text("void");
                try declaration(out, f.return_type.?, try std.fmt.allocPrint(out.allocator, "({s})({s})", .{ pointer_name, params.bytes.items }), false);
            } else {
                const nested_name = if (@typeInfo(p.child) == .array) try std.fmt.allocPrint(out.allocator, "({s})", .{pointer_name}) else pointer_name;
                try declaration(out, p.child, nested_name, p.is_const);
            }
        },
        .array => |array| try declaration(out, array.child, try std.fmt.allocPrint(out.allocator, "{s}[{d}]", .{ name, @as(usize, array.len) + @as(usize, @intFromBool(array.sentinel_ptr != null)) }), is_const),
        else => {
            if (is_const) try out.text("const ");
            switch (@typeInfo(T)) {
                .void => try out.text("void"),
                .bool => try out.text("bool"),
                .int => |i| {
                    if (T == usize) try out.text("uintptr_t") else if (T == isize) try out.text("intptr_t") else {
                        if (i.bits != 8 and i.bits != 16 and i.bits != 32 and i.bits != 64) @compileError("Unsupported C integer: " ++ @typeName(T));
                        try out.print("{s}int{d}_t", .{ if (i.signedness == .signed) "" else "u", i.bits });
                    }
                },
                .float => |f| {
                    if (f.bits != 32 and f.bits != 64) @compileError("Unsupported C float: " ++ @typeName(T));
                    try out.text(if (f.bits == 32) "float" else "double");
                },
                .@"enum", .@"struct" => try out.text(comptime cName(localName(T))),
                .@"opaque" => {
                    if (T != anyopaque) @compileError("Unsupported opaque C type: " ++ @typeName(T));
                    try out.text("void");
                },
                else => @compileError("Unsupported C ABI value: " ++ @typeName(T)),
            }
            if (name.len != 0) try out.print(" {s}", .{name});
        },
    }
}

fn dependency(out: *Output, emitted: *std.StringHashMap(void), comptime T: type) anyerror!void {
    switch (@typeInfo(T)) {
        .array => |a| try dependency(out, emitted, a.child),
        .@"struct" => |s| if (s.layout == .@"extern" and comptime technical(localName(T))) {
            try structure(out, emitted, T);
        },
        else => {}, // A pointer needs only the forward declaration.
    }
}
fn structure(out: *Output, emitted: *std.StringHashMap(void), comptime T: type) anyerror!void {
    const name = comptime cName(localName(T));
    if (emitted.contains(name)) return;
    inline for (@typeInfo(T).@"struct".fields) |field| try dependency(out, emitted, field.type);
    try out.print("struct {s} {{\n", .{name});
    inline for (@typeInfo(T).@"struct".fields) |field| {
        try out.text("    ");
        try declaration(out, field.type, comptime fieldName(field.name), false);
        try out.text(";\n");
    }
    try out.text("};\n");
    try out.print("_Static_assert(sizeof({s}) == {d}, \"{s} size\");\n_Static_assert(_Alignof({s}) == {d}, \"{s} alignment\");\n", .{ name, @sizeOf(T), name, name, @alignOf(T), name });
    inline for (@typeInfo(T).@"struct".fields) |field|
        try out.print("_Static_assert(offsetof({s}, {s}) == {d}, \"{s}.{s} offset\");\n", .{ name, comptime fieldName(field.name), @offsetOf(T, field.name), name, field.name });
    try out.text("\n");
    try emitted.put(name, {});
}
fn integer(out: *Output, comptime value: anytype) !void {
    if (value < 0) {
        const before_last = -@as(i128, value) - 1;
        if (before_last > std.math.maxInt(i64)) @compileError("C constant exceeds i64");
        try out.print("(-INT64_C({d}) - INT64_C(1))", .{before_last});
    } else {
        if (value > std.math.maxInt(u64)) @compileError("C constant exceeds u64");
        try out.print("UINT64_C({d})", .{value});
    }
}
fn constant(out: *Output, comptime name: []const u8, comptime value: anytype) !void {
    try out.text("#define ");
    try macro(out, name);
    try out.text(" ");
    switch (@typeInfo(@TypeOf(value))) {
        .int => {
            try out.text("((");
            try declaration(out, @TypeOf(value), "", false);
            try out.text(")");
            try integer(out, value);
            try out.text(")");
        },
        .comptime_int => try integer(out, value),
        .bool => try out.text(if (value) "((bool)true)" else "((bool)false)"),
        .@"enum" => {
            try out.print("(({s})", .{comptime cName(localName(@TypeOf(value)))});
            try integer(out, @intFromEnum(value));
            try out.text(")");
        },
        .pointer => |p| {
            if (p.size != .one or @typeInfo(p.child) != .array or @typeInfo(p.child).array.child != u8) @compileError("Unsupported C constant pointer: " ++ name);
            try out.text("\"");
            for (value.*) |byte| try out.print("\\x{x:0>2}", .{byte});
            try out.text("\"");
        },
        else => @compileError("Unsupported C constant: " ++ name),
    }
    try out.text("\n");
}

pub fn generate(allocator: std.mem.Allocator) !Result {
    @setEvalBranchQuota(10000000);
    var out = Output{ .allocator = allocator };
    var counts = Result{ .bytes = &.{}, .structs = 0, .enums = 0, .aliases = 0, .constants = 0 };
    try out.text("/* Generated by Contract/Tools/AbiRustGen from the canonical technical ABI. */\n#ifndef R4OS_ABI_TECHNICAL_GENERATED_H\n#define R4OS_ABI_TECHNICAL_GENERATED_H\n#include <stdbool.h>\n#include <r4os/abi_generated.h>\n\n");
    inline for (comptime std.meta.declarations(abi)) |d| {
        if (comptime !technical(d.name)) continue;
        const T = @field(abi, d.name);
        if (@TypeOf(T) != type) continue;
        switch (@typeInfo(T)) {
            .@"struct" => |s| if (s.layout == .@"extern") {
                try out.print("typedef struct {s} {s};\n", .{ comptime cName(d.name), comptime cName(d.name) });
                counts.structs += 1;
            },
            else => {},
        }
    }
    try out.text("\n");
    inline for (comptime std.meta.declarations(abi)) |d| {
        const T = @field(abi, d.name);
        if (@TypeOf(T) != type) continue;
        if (@typeInfo(T) == .@"enum") {
            try out.text("typedef ");
            try declaration(&out, @typeInfo(T).@"enum".tag_type, comptime cName(d.name), false);
            try out.text(";\n");
            inline for (@typeInfo(T).@"enum".fields) |field| {
                try out.text("#define ");
                try out.text("R4ABI_");
                const name = comptime cName(d.name);
                try enumPrefix(&out, name[2..]);
                try out.text("_");
                try upper(&out, field.name);
                try out.print(" (({s})", .{comptime cName(d.name)});
                try integer(&out, field.value);
                try out.text(")\n");
            }
            counts.enums += 1;
        }
    }
    inline for (comptime std.meta.declarations(abi)) |d| {
        if (comptime !technical(d.name)) continue;
        const T = @field(abi, d.name);
        if (@TypeOf(T) != type) continue;
        if (@typeInfo(T) == .pointer) {
            try out.text("typedef ");
            try declaration(&out, T, comptime cName(d.name), false);
            try out.text(";\n");
            counts.aliases += 1;
        }
    }
    try out.text("\n");
    var emitted = std.StringHashMap(void).init(allocator);
    defer emitted.deinit();
    inline for (comptime std.meta.declarations(abi)) |d| {
        if (comptime !technical(d.name)) continue;
        const T = @field(abi, d.name);
        if (@TypeOf(T) != type) continue;
        if (@typeInfo(T) == .@"struct" and @typeInfo(T).@"struct".layout == .@"extern") try structure(&out, &emitted, T);
    }
    inline for (comptime std.meta.declarations(abi)) |d| {
        if (comptime !technical(d.name)) continue;
        const value = @field(abi, d.name);
        if (@TypeOf(value) == type) continue;
        try constant(&out, d.name, value);
        counts.constants += 1;
    }
    // This canonical flag namespace has no fields or C struct layout. Reflect
    // its declarations, just as Rust does, rather than duplicating bit values.
    inline for (comptime std.meta.declarations(abi.GuiWindowFlag)) |d| {
        try constant(&out, "R4ABI_GUI_WINDOW_FLAG_" ++ d.name, @field(abi.GuiWindowFlag, d.name));
        counts.constants += 1;
    }
    try out.text("\n#endif\n");
    counts.bytes = try out.bytes.toOwnedSlice(allocator);
    return counts;
}
