const std = @import("std");
const abi = @import("r4os_contract").abi;
const abi2 = @import("r4os_contract2");
const c = @cImport({
    @cInclude("r4os/facades.h");
});

// This projection deliberately reads the compiler's types, never C syntax or
// guessed layouts. Platform records alias the existing generated Rust ABI.
fn starts(name: []const u8, prefix: []const u8) bool {
    return std.mem.startsWith(u8, name, prefix);
}
fn typeCandidate(name: []const u8) bool {
    inline for (.{ "R4XStartContext", "R4XStartR4Sys", "R4XStartR4Desk", "R4XStartR4Draw", "R4XStartR4Net", "R4XStartR4Audio", "R4XStartR4Dev", "R4DriverApi", "R4ProtocolApi", "R4LQuery", "R4KernelBridgeMap", "R4AudioBackend", "R4AudioBackendStatus" }) |retired| {
        if (std.mem.eql(u8, name, retired)) return false;
    }
    if (!starts(name, "R4")) return false;
    for (name) |ch| if (std.ascii.isLower(ch)) return true;
    return false;
}
fn selected(comptime name: []const u8) bool {
    if (starts(name, "R4SdkHeap")) return false;
    inline for (.{ "r4_files_", "r4_console_", "r4_stream_", "r4_directory_", "r4_registry_", "r4_storage_", "r4_dialog_", "r4_ordered_", "r4_snapshot_", "r4_desktop_evidence_", "r4_desktop_action_", "r4_resources_", "r4_resource_", "r4_process_", "r4os_process_", "r4os_spawn_", "r4_join_", "r4_vm_region_", "r4_io_", "r4_notification_", "r4_services_", "r4_service_", "r4_network_", "r4_net_", "r4_tcp_", "r4_udp_", "r4_resolver_", "r4_ipv4", "r4_tray_", "r4_app_tray", "r4serial_", "r4_duration_", "r4_timeout_", "r4_remaining_ticks", "r4_monotonic_resolution_ns", "r4_deadline_after", "R4Sdk" }) |prefix| {
        if (starts(name, prefix)) return true;
    }
    return false;
}
fn canonical(comptime name: []const u8) ?[]const u8 {
    if (@hasDecl(abi, name)) return name;
    if (starts(name, "R4") and @hasDecl(abi, name[2..])) return name[2..];
    if (@hasDecl(abi2, name)) return "generation2::" ++ name;
    return null;
}
fn canonicalType(comptime name: []const u8) type {
    if (@hasDecl(abi, name)) return @field(abi, name);
    if (starts(name, "R4") and @hasDecl(abi, name[2..])) return @field(abi, name[2..]);
    if (@hasDecl(abi2, name)) return @field(abi2, name);
    @compileError("Missing canonical facade record: " ++ name);
}
fn nameOf(comptime T: type) []const u8 {
    const full = @typeName(T);
    const last = full[(std.mem.lastIndexOfScalar(u8, full, '.') orelse @compileError("Unnamed facade record")) + 1 ..];
    const prefix = if (starts(last, "struct_")) "struct_" else if (starts(last, "union_")) "union_" else "";
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
    @setEvalBranchQuota(32_000_000);
    var result: []const Record = &.{};
    for (@typeInfo(c).@"struct".decls) |decl| {
        if (!typeCandidate(decl.name) or @TypeOf(@field(c, decl.name)) != type) continue;
        const T = @field(c, decl.name);
        if (@typeInfo(T) != .@"struct" and @typeInfo(T) != .@"union") continue;
        if (!std.mem.eql(u8, decl.name, nameOf(T))) continue;
        var fields: []const Field = &.{};
        const raw = if (@typeInfo(T) == .@"struct") @typeInfo(T).@"struct".fields else @typeInfo(T).@"union".fields;
        for (raw) |field| {
            const field_name = if (canonical(decl.name) != null) blk_name: {
                const O = canonicalType(decl.name);
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
    @setEvalBranchQuota(32_000_000);
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
    @setEvalBranchQuota(32_000_000);
    try w.writeAll("// Generated by CFacadeGen from the SDK C owners. Do not edit.\n" ++
        "//! Unsafe C facade projection. All pointers, lengths, provider loans,\n" ++
        "//! synchronization and exact close acknowledgements follow the C owners.\n" ++
        "#![allow(non_camel_case_types, non_snake_case, non_upper_case_globals, dead_code)]\n");
    for (records) |record| {
        if (record.owner) |owner| try w.print("pub type {s} = crate::abi::{s};\n", .{ record.name, owner }) else {
            try w.print("#[repr(C, align({d}))]\n#[derive(Clone, Copy)]\npub {s} {s} {{\n", .{ record.alignment, if (record.is_union) "union" else "struct", record.name });
            for (record.fields) |field| try w.print("    pub r#{s}: {s},\n", .{ field.name, field.rust });
            try w.writeAll("}\n");
        }
        try w.print("const _: () = {{ assert!(core::mem::size_of::<{s}>() == {d}); assert!(core::mem::align_of::<{s}>() == {d});", .{ record.name, record.size, record.name, record.alignment });
        if (!record.is_union) for (record.fields) |field| try w.print(" assert!(core::mem::offset_of!({s}, r#{s}) == {d});", .{ record.name, field.name, field.offset });
        try w.writeAll(" };\n");
    }
    inline for (@typeInfo(c).@"struct".decls) |decl| {
        if (comptime !starts(decl.name, "R4Sdk")) continue;
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
        // readFileAlloc rejects a file that reaches its exclusive limit.
        // Admit the exact rendered length; mem.eql still rejects any drift.
        const actual = try std.Io.Dir.cwd().readFileAlloc(init.io, args[2], init.arena.allocator(), .limited(out.written().len + 1));
        if (!std.mem.eql(u8, actual, out.written())) return error.CFacadeProjectionDrift;
    }
}
