const std = @import("std");
const abi = @import("r4os_contract").abi;
const c = @cImport({
    @cInclude("r4libraries/helpers.h");
});

// This projection deliberately reads the compiler's types, never C syntax or
// guessed layouts. Platform records alias the existing generated Rust ABI.
fn starts(name: []const u8, prefix: []const u8) bool {
    return std.mem.startsWith(u8, name, prefix);
}
fn typeCandidate(name: []const u8) bool {
    if (!starts(name, "R4")) return false;
    for (name) |ch| if (std.ascii.isLower(ch)) return true;
    return false;
}
fn selected(comptime name: []const u8) bool {
    // The owner header contains only this boundary and canonical ABI types.
    // Select its entire public R4 namespace, so a new native helper prefix
    // cannot silently drop functions (for example ColorDecoder/NativeJpeg).
    return typeCandidate(name);
}
fn canonical(comptime name: []const u8) ?[]const u8 {
    if (@hasDecl(abi, name)) return name;
    if (starts(name, "R4") and @hasDecl(abi, name[2..])) return name[2..];
    return null;
}
fn nameOf(comptime T: type) []const u8 {
    const full = @typeName(T);
    const last = full[(std.mem.lastIndexOfScalar(u8, full, '.') orelse @compileError("Unnamed facade record")) + 1 ..];
    const prefix = if (starts(last, "struct_")) "struct_" else if (starts(last, "union_")) "union_" else @compileError("Unexpected C record: " ++ full);
    const name = last[prefix.len..];
    if (!typeCandidate(name) or !@hasDecl(c, name) or @field(c, name) != T) @compileError("Missing public facade record: " ++ full);
    return name;
}
fn rustType(comptime T: type) []const u8 {
    return switch (@typeInfo(T)) {
        .void => "()",
        .noreturn => "!",
        .bool => "bool",
        .int => |n| std.fmt.comptimePrint("{s}{d}", .{ if (n.signedness == .signed) "i" else "u", n.bits }),
        .float => |n| std.fmt.comptimePrint("f{d}", .{n.bits}),
        .array => |a| std.fmt.comptimePrint("[{s}; {d}]", .{ rustType(a.child), a.len }),
        .pointer => |p| if (@typeInfo(p.child) == .@"fn") rustType(p.child) else (if (p.is_const) "*const " else "*mut ") ++ (if (@typeInfo(p.child) == .@"opaque" or p.child == anyopaque) "core::ffi::c_void" else rustType(p.child)),
        .optional => |o| if (@typeInfo(o.child) == .pointer and @typeInfo(@typeInfo(o.child).pointer.child) != .@"fn") rustType(o.child) else "Option<" ++ rustType(o.child) ++ ">",
        .@"fn" => |f| blk: {
            if (f.is_var_args) @compileError("Variadic facade unsupported");
            var result: []const u8 = "unsafe extern \"C\" fn(";
            for (f.params, 0..) |p, i| result = result ++ (if (i != 0) ", " else "") ++ rustType(p.type.?);
            break :blk result ++ ") -> " ++ rustType(f.return_type.?);
        },
        .@"struct", .@"union" => nameOf(T),
        else => @compileError("Unsupported C facade type: " ++ @typeName(T)),
    };
}
const Field = struct { name: []const u8, rust: []const u8, offset: usize };
const Record = struct { name: []const u8, owner: ?[]const u8, is_union: bool, size: usize, alignment: usize, fields: []const Field };
const Function = struct { name: []const u8, parameters: []const []const u8, result: []const u8 };
const records = blk: {
    @setEvalBranchQuota(8_000_000);
    var result: []const Record = &.{};
    for (@typeInfo(c).@"struct".decls) |decl| {
        if (!typeCandidate(decl.name) or @TypeOf(@field(c, decl.name)) != type) continue;
        const T = @field(c, decl.name);
        if (@typeInfo(T) != .@"struct" and @typeInfo(T) != .@"union") continue;
        if (!std.mem.eql(u8, decl.name, nameOf(T))) continue;
        var fields: []const Field = &.{};
        const raw = if (@typeInfo(T) == .@"struct") @typeInfo(T).@"struct".fields else @typeInfo(T).@"union".fields;
        for (raw) |field| {
            const field_name = if (canonical(decl.name)) |owner| blk_name: {
                const O = @field(abi, owner);
                if (@hasField(O, field.name)) break :blk_name field.name;
                const trimmed = std.mem.trimEnd(u8, field.name, "_");
                if (!@hasField(O, trimmed)) @compileError("Canonical field mapping missing: " ++ decl.name ++ "." ++ field.name);
                break :blk_name trimmed;
            } else field.name;
            fields = fields ++ &[_]Field{.{ .name = field_name, .rust = rustType(field.type), .offset = if (@typeInfo(T) == .@"struct") @offsetOf(T, field.name) else 0 }};
        }
        result = result ++ &[_]Record{.{ .name = decl.name, .owner = canonical(decl.name), .is_union = @typeInfo(T) == .@"union", .size = @sizeOf(T), .alignment = @alignOf(T), .fields = fields }};
    }
    break :blk result;
};
const functions = blk: {
    @setEvalBranchQuota(8_000_000);
    var result: []const Function = &.{};
    for (@typeInfo(c).@"struct".decls) |decl| {
        if (!selected(decl.name) or @typeInfo(@TypeOf(@field(c, decl.name))) != .@"fn") continue;
        const f = @typeInfo(@TypeOf(@field(c, decl.name))).@"fn";
        var params: []const []const u8 = &.{};
        for (f.params) |p| params = params ++ &[_][]const u8{rustType(p.type.?)};
        result = result ++ &[_]Function{.{ .name = decl.name, .parameters = params, .result = rustType(f.return_type.?) }};
    }
    break :blk result;
};
fn emit(w: *std.Io.Writer) !void {
    @setEvalBranchQuota(8_000_000);
    try w.writeAll("// Generated by CFacadeGen from the library C helper owners. Do not edit.\n" ++
        "//! Unsafe C facade projection. All pointers, lengths, provider loans,\n" ++
        "//! synchronization and exact close acknowledgements follow the C owners.\n" ++
        "#![allow(non_camel_case_types, non_snake_case, non_upper_case_globals, dead_code)]\n");
    for (records) |record| {
        if (record.owner) |owner| try w.print("pub type {s} = crate::abi::{s};\n", .{ record.name, owner }) else {
            try w.print("#[repr(C, align({d}))]\n#[derive(Clone, Copy)]\npub {s} {s} {{\n", .{ record.alignment, if (record.is_union) "union" else "struct", record.name });
            for (record.fields) |field| {
                if (std.mem.eql(u8, field.name, "opaque_bytes")) {
                    try w.print("    pub r#opaque_bytes: [core::mem::MaybeUninit<u8>; {d}],\n", .{record.size});
                } else try w.print("    pub r#{s}: {s},\n", .{ field.name, field.rust });
            }
            try w.writeAll("}\n");
        }
        try w.print("const _: () = {{ assert!(core::mem::size_of::<{s}>() == {d}); assert!(core::mem::align_of::<{s}>() == {d});", .{ record.name, record.size, record.name, record.alignment });
        if (!record.is_union) for (record.fields) |field| try w.print(" assert!(core::mem::offset_of!({s}, r#{s}) == {d});", .{ record.name, field.name, field.offset });
        try w.writeAll(" };\n");
    }
    inline for (@typeInfo(c).@"struct".decls) |decl| {
        if (comptime !selected(decl.name)) continue;
        const value = @field(c, decl.name);
        switch (@typeInfo(@TypeOf(value))) {
            .comptime_int => try w.print("pub const {s}: {s} = {d};\n", .{ decl.name, if (value < 0) "i64" else "u64", value }),
            .int => try w.print("pub const {s}: {s} = {d};\n", .{ decl.name, rustType(@TypeOf(value)), value }),
            else => {},
        }
    }
    try w.writeAll("unsafe extern \"C\" {\n");
    for (functions) |f| {
        try w.print("    pub fn {s}(", .{f.name});
        for (f.parameters, 0..) |parameter, i| {
            if (i != 0) try w.writeAll(", ");
            try w.print("p{d}: {s}", .{ i, parameter });
        }
        try w.print(") -> {s};\n", .{f.result});
    }
    try w.writeAll("}\n");
}
pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len != 3 or (!std.mem.eql(u8, args[1], "write") and !std.mem.eql(u8, args[1], "check"))) return error.UsageCheckOrWriteOutput;
    var out: std.Io.Writer.Allocating = .init(init.arena.allocator());
    try emit(&out.writer);
    if (std.mem.eql(u8, args[1], "write")) {
        try std.Io.Dir.cwd().writeFile(init.io, .{ .sub_path = args[2], .data = out.written() });
    } else {
        const actual = try std.Io.Dir.cwd().readFileAlloc(init.io, args[2], init.arena.allocator(), .limited(4 * 1024 * 1024));
        if (!std.mem.eql(u8, actual, out.written())) return error.CFacadeProjectionDrift;
    }
}
