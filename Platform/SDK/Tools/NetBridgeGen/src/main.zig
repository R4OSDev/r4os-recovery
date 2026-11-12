const std = @import("std");
const bridge = @import("bridge");
const abi = bridge.abi;
const net = bridge.net;
const program = bridge.program;
fn canonical(comptime T: type) []const u8 {
    const full = @typeName(T);
    const name = full[(comptime std.mem.lastIndexOfScalar(u8, full, '.') orelse @compileError("Unnamed ABI type")) + 1 ..];
    if (comptime !@hasDecl(abi, name) or @field(abi, name) != T) @compileError("Noncanonical network type: " ++ full);
    return name;
}
fn cRecord(comptime T: type) []const u8 {
    const name = comptime canonical(T);
    return if (std.mem.startsWith(u8, name, "R4")) name else "R4" ++ name;
}
fn cType(comptime T: type) []const u8 {
    if (T == bridge.Request) return "R4SdkNetRequest";
    if (T == bridge.ResolverResult) return "R4SdkResolverResult";
    if (T == bridge.Readiness) return "R4SdkTcpReadiness";
    if (T == bridge.Options) return "R4SdkResolverOptions";
    if (T == bridge.Slice) return "R4SdkNetSlice";
    if (T == [4]u8) return "uint8_t";
    if (T == usize) return "uintptr_t";
    return comptime switch (@typeInfo(T)) {
        .int => |n| std.fmt.comptimePrint("{s}int{d}_t", .{ if (n.signedness == .signed) "" else "u", n.bits }),
        .bool => "uint8_t",
        .void => "void",
        .@"struct" => cRecord(T),
        .pointer => |p| (if (p.is_const) "const " else "") ++ cType(p.child) ++ " *",
        else => @compileError("Unsupported C type " ++ @typeName(T)),
    };
}
fn zType(comptime T: type) []const u8 {
    if (T == program.TcpReadiness) return "bridge.Readiness";
    if (T == [4]u8) return "[4]u8";
    return comptime switch (@typeInfo(T)) {
        .int => @typeName(T),
        .bool => "u8",
        .void => "void",
        .@"struct" => "abi." ++ canonical(T),
        .pointer => |p| (if (p.is_const) "*const " else "*") ++ zType(p.child),
        else => @compileError("Unsupported native type " ++ @typeName(T)),
    };
}
fn sliceType(comptime T: type) bool {
    return @typeInfo(T) == .pointer and @typeInfo(T).pointer.size == .slice;
}
fn pointer(comptime T: type) bool {
    return @typeInfo(T) == .pointer;
}
fn requestPointer(comptime T: type) bool {
    return pointer(T) and @typeInfo(T).pointer.child == program.NetSocketRequest;
}
fn resolverPointer(comptime T: type) bool {
    return pointer(T) and @typeInfo(T).pointer.child == program.ResolverResult;
}
fn cParam(comptime T: type) []const u8 {
    if (comptime sliceType(T)) return if (@typeInfo(T).pointer.is_const) "const uint8_t *" else "uint8_t *";
    if (T == [4]u8) return "const uint8_t *";
    if (T == program.NetSocketService) return "uint8_t";
    if (T == program.ResolverOptions) return "R4SdkResolverOptions";
    if (comptime requestPointer(T)) return "R4SdkNetRequest *";
    if (comptime resolverPointer(T)) return "R4SdkResolverResult *";
    return comptime cType(T);
}
fn zParam(comptime T: type) []const u8 {
    if (comptime sliceType(T)) return if (@typeInfo(T).pointer.is_const) "[*]const u8" else "[*]u8";
    if (T == [4]u8) return "*const [4]u8";
    if (T == program.NetSocketService) return "u8";
    if (T == program.ResolverOptions) return "bridge.Options";
    if (comptime requestPointer(T)) return "*bridge.Request";
    if (comptime resolverPointer(T)) return "*bridge.ResolverResult";
    return comptime zType(T);
}
fn resultSlice(comptime T: type) bool {
    return sliceType(T) or (@typeInfo(T) == .optional and sliceType(@typeInfo(T).optional.child));
}
fn cResult(comptime T: type) []const u8 {
    return comptime if (resultSlice(T)) "R4SdkNetSlice" else if (T == program.TcpReadiness) "R4SdkTcpReadiness" else cType(T);
}
fn zResult(comptime T: type) []const u8 {
    return comptime if (resultSlice(T)) "bridge.Slice" else zType(T);
}
fn failure(comptime T: type) []const u8 {
    if (T == program.TcpReadiness) return "std.mem.zeroes(bridge.Readiness)";
    if (comptime resultSlice(T) or @typeInfo(T) == .@"struct") return ".{}";
    return if (@typeInfo(T) == .int and @typeInfo(T).int.signedness == .signed) "abi.err_no_group" else "0";
}
fn selected(comptime name: []const u8) bool {
    return !std.mem.eql(u8, name, "init") and !std.mem.eql(u8, name, "fromProgram") and !std.mem.eql(u8, name, "hasFn");
}
fn emitFlat(comptime T: type, comptime name: []const u8, w: *std.Io.Writer) !void {
    try w.print("typedef struct {s} {{\n", .{name});
    inline for (@typeInfo(T).@"struct".fields) |field| {
        if (@typeInfo(field.type) == .array) {
            const a = @typeInfo(field.type).array;
            try w.print("    {s} {s}[{d}];\n", .{ cType(a.child), field.name, a.len });
        } else try w.print("    {s} {s};\n", .{ cType(field.type), field.name });
    }
    try w.print("}} {s};\n", .{name});
}
fn emit(c: *std.Io.Writer, z: *std.Io.Writer) !void {
    @setEvalBranchQuota(12_000_000);
    try c.writeAll("/* Generated from compiler-typed SDK networking owners; do not edit. */\n#ifndef R4OS_NET_BRIDGE_H\n#define R4OS_NET_BRIDGE_H\n#include \"platform2.h\"\n/* Every context/buffer is borrowed for its call. Initialized request storage\n * must remain at the same address until actual wait/close acknowledgements;\n * do not reset, copy or release an active request. This is an SDK-local ABI. */\n");
    try c.print("typedef struct R4SdkNetRequest {{ _Alignas({d}) uint8_t data[{d}]; }} R4SdkNetRequest;\n", .{ @alignOf(bridge.Request), @sizeOf(bridge.Request) });
    try c.writeAll("typedef struct R4SdkNetSlice { const uint8_t *ptr; uintptr_t length; uint32_t valid, reserved; } R4SdkNetSlice;\n");
    try emitFlat(bridge.Options, "R4SdkResolverOptions", c);
    try emitFlat(bridge.ResolverResult, "R4SdkResolverResult", c);
    try emitFlat(bridge.Readiness, "R4SdkTcpReadiness", c);
    try z.writeAll("// Generated from compiler-typed r4net.Context; do not edit.\nconst std = @import(\"std\");\nconst abi = @import(\"r4os_contract\").abi;\nconst net = @import(\"../r4net.zig\");\nconst program = @import(\"../program.zig\");\nconst bridge = @import(\"../net_bridge_support.zig\");\n");
    inline for (@typeInfo(net.Context).@"struct".decls) |decl| {
        if (comptime !selected(decl.name)) continue;
        const f = @typeInfo(@TypeOf(@field(net.Context, decl.name))).@"fn";
        const Ret = f.return_type.?;
        inline for (.{ false, true }) |generation2| {
            const prefix = if (generation2) "R4SdkNet2_" else "R4SdkNet_";
            try c.print("{s} {s}{s}(const {s} *context", .{ cResult(Ret), prefix, decl.name, if (generation2) "R4OS2Context" else "R4XStartContext" });
            try z.print("pub export fn {s}{s}(context: *const {s}", .{ prefix, decl.name, if (generation2) "@import(\"../platform2.zig\").Context" else "abi.R4XStartContext" });
            inline for (f.params[1..], 0..) |param, i| {
                const T = param.type.?;
                try c.print(", {s} p{d}", .{ cParam(T), i });
                try z.print(", p{d}: {s}", .{ i, zParam(T) });
                if (comptime sliceType(T)) {
                    try c.print(", uint32_t n{d}", .{i});
                    try z.print(", n{d}: u32", .{i});
                }
            }
            try c.writeAll(");\n");
            if (generation2) {
                try z.print(") callconv(.c) {s} {{\n    _ = context.system() orelse return {s};\n    const owner = net.Context.fromProgram(.{{ .generation2 = context }});\n", .{ zResult(Ret), failure(Ret) });
            } else {
                try z.print(") callconv(.c) {s} {{\n    const bundle = bridge.bundle(context) orelse return {s};\n    const owner = net.Context.init(&bundle);\n", .{ zResult(Ret), failure(Ret) });
            }
            inline for (f.params[1..], 0..) |param, i| {
                const T = param.type.?;
                if (comptime resolverPointer(T)) try z.print("    var result{d}: program.ResolverResult = .{{}};\n", .{i});
                if (comptime T == program.NetSocketService) try z.print("    const enum{d}: program.NetSocketService = switch (p{d}) {{ 0 => .tcp, 1 => .udp, else => return abi.io_error_invalid }};\n", .{ i, i });
            }
            try z.print("    const value = owner.{s}(", .{decl.name});
            inline for (f.params[1..], 0..) |param, i| {
                const T = param.type.?;
                if (i != 0) try z.writeAll(", ");
                if (comptime sliceType(T)) {
                    try z.print("p{d}[0..n{d}]", .{ i, i });
                } else if (T == [4]u8) {
                    try z.print("p{d}.*", .{i});
                } else if (T == program.NetSocketService) {
                    try z.print("enum{d}", .{i});
                } else if (T == program.ResolverOptions) {
                    try z.print(".{{ .server = if (p{d}.has_server != 0) p{d}.server else null }}", .{ i, i });
                } else if (comptime requestPointer(T)) {
                    try z.print("bridge.request(p{d})", .{i});
                } else if (comptime resolverPointer(T)) {
                    try z.print("&result{d}", .{i});
                } else try z.print("p{d}", .{i});
            }
            try z.writeAll(");\n");
            inline for (f.params[1..], 0..) |param, i| {
                if (comptime resolverPointer(param.type.?)) try z.print("    p{d}.* = bridge.flatten(bridge.ResolverResult, result{d});\n", .{ i, i });
            }
            if (comptime resultSlice(Ret)) try z.writeAll("    return bridge.slice(value);\n}\n") else if (Ret == bool) try z.writeAll("    return @intFromBool(value);\n}\n") else if (Ret == program.TcpReadiness) try z.writeAll("    return bridge.flatten(bridge.Readiness, value);\n}\n") else try z.writeAll("    return value;\n}\n");
        }
    }
    try c.writeAll("#endif\n");
}
fn rustType(comptime T: type) []const u8 {
    if (T == usize) return "usize";
    if (T == [4]u8) return "[u8; 4]";
    if (T == program.NetSocketService) return "SocketService";
    if (T == program.ResolverOptions) return "ResolverOptions";
    if (T == program.TcpReadiness) return "TcpReadiness";
    if (comptime resolverPointer(T)) return "&'b mut ResolverResult";
    if (comptime requestPointer(T)) return "&'b mut RawRequest";
    if (comptime sliceType(T)) return if (@typeInfo(T).pointer.is_const) "&'b [u8]" else "&'b mut [u8]";
    return comptime switch (@typeInfo(T)) {
        .int, .bool => @typeName(T),
        .@"struct" => "abi::" ++ canonical(T),
        .pointer => |p| (if (p.is_const) "&'b " else "&'b mut ") ++ rustType(p.child),
        else => @compileError("Unsupported Rust type " ++ @typeName(T)),
    };
}
fn snake(w: *std.Io.Writer, name: []const u8) !void {
    for (name, 0..) |ch, i| {
        if (std.ascii.isUpper(ch) and i != 0) try w.writeByte('_');
        try w.writeByte(std.ascii.toLower(ch));
    }
}
fn emitRust(w: *std.Io.Writer) !void {
    @setEvalBranchQuota(12_000_000);
    try w.writeAll("// Generated from compiler-typed r4net.Context; do not edit.\nuse crate::{abi, c_facades as c};\nuse crate::network::{Network, SocketService, ResolverOptions, ResolverResult, TcpReadiness, RawRequest};\n#[allow(clippy::needless_lifetimes, clippy::let_and_return, clippy::too_many_arguments)]\nimpl Network<'_> {\n");
    inline for (@typeInfo(net.Context).@"struct".decls) |decl| {
        if (comptime !selected(decl.name)) continue;
        const f = @typeInfo(@TypeOf(@field(net.Context, decl.name))).@"fn";
        const Ret = f.return_type.?;
        const lending = comptime blk: {
            for (f.params[1..]) |p| if (requestPointer(p.type.?)) break :blk true;
            break :blk false;
        };
        if (lending) try w.writeAll("    /// # Safety\n    /// Keep this exact initialized request at a stable address, including\n    /// its buffers, until native close succeeds. Forgetting it cannot cancel\n    /// native work. Use OwnedRequest for safe owned admission.\n");
        try w.print("    pub {s}fn ", .{if (lending) "unsafe " else ""});
        try snake(w, decl.name);
        try w.writeAll("<'b>(&'b self");
        inline for (f.params[1..], 0..) |p, i| try w.print(", p{d}: {s}", .{ i, rustType(p.type.?) });
        try w.print(") -> {s} {{\n", .{if (comptime resultSlice(Ret)) "Option<&'b [u8]>" else rustType(Ret)});
        inline for (f.params[1..], 0..) |p, i| {
            if (comptime sliceType(p.type.?)) try w.print("        if p{d}.len() > u32::MAX as usize {{ return {s}; }}\n", .{ i, if (comptime resultSlice(Ret)) "None" else if (Ret == bool) "false" else if (Ret == program.TcpReadiness) "unsafe { core::mem::zeroed() }" else if (Ret == i32) "abi::io_error_invalid" else "0" });
        }
        try w.writeAll("        let value = unsafe { if self.context2.is_null() { ");
        inline for (.{ false, true }) |generation2| {
            try w.print("c::{s}{s}({s}", .{ if (generation2) "R4SdkNet2_" else "R4SdkNet_", decl.name, if (generation2) "self.context2" else "self.context" });
            inline for (f.params[1..], 0..) |p, i| {
                const T = p.type.?;
                if (comptime sliceType(T)) {
                    try w.print(", p{d}.as_{s}ptr(), p{d}.len() as u32", .{ i, if (@typeInfo(T).pointer.is_const) "" else "mut_", i });
                } else if (comptime @typeInfo(T) == .pointer and @typeInfo(T).pointer.child == [4]u8) {
                    try w.print(", p{d}.as_{s}ptr()", .{ i, if (@typeInfo(T).pointer.is_const) "" else "mut_" });
                } else if (T == [4]u8) {
                    try w.print(", p{d}.as_ptr()", .{i});
                } else if (T == program.NetSocketService) {
                    try w.print(", p{d} as u8", .{i});
                } else if (T == usize) {
                    try w.print(", p{d} as u64", .{i});
                } else try w.print(", p{d}", .{i});
            }
            try w.writeAll(if (generation2) ") } };\n" else ") } else { ");
        }
        if (comptime resultSlice(Ret)) try w.writeAll("        // Owner returns only a view of the input or resident label storage.\n        unsafe { crate::network::view(value) }\n") else if (Ret == bool) try w.writeAll("        value != 0\n") else try w.writeAll("        value\n");
        try w.writeAll("    }\n");
    }
    try w.writeAll("}\n");
    try w.writeAll("#[cfg(feature = \"alloc\")]\n#[allow(clippy::needless_lifetimes)]\nimpl crate::network::OwnedRequest<'_> {\n");
    inline for (@typeInfo(net.Context).@"struct".decls) |decl| {
        if (comptime !selected(decl.name)) continue;
        const f = @typeInfo(@TypeOf(@field(net.Context, decl.name))).@"fn";
        const lending = comptime blk: {
            for (f.params[1..]) |p| if (requestPointer(p.type.?)) break :blk true;
            break :blk false;
        };
        if (!lending) continue;
        try w.writeAll("    pub fn ");
        try snake(w, decl.name);
        try w.writeAll("<'b>(&'b mut self");
        inline for (f.params[1..], 0..) |p, i| {
            if (comptime !requestPointer(p.type.?)) try w.print(", p{d}: {s}", .{ i, rustType(p.type.?) });
        }
        try w.writeAll(") -> i32 {\n");
        inline for (f.params[1..], 0..) |p, i| {
            if (comptime sliceType(p.type.?)) try w.print("        if p{d}.len() > u32::MAX as usize {{ return abi::io_error_invalid; }}\n", .{i});
        }
        try w.writeAll("        unsafe { if self.network.context2.is_null() { ");
        inline for (.{ false, true }) |generation2| {
            try w.print("c::{s}{s}({s}", .{ if (generation2) "R4SdkNet2_" else "R4SdkNet_", decl.name, if (generation2) "self.network.context2" else "self.network.context" });
            inline for (f.params[1..], 0..) |p, i| {
                const T = p.type.?;
                if (comptime requestPointer(T)) {
                    try w.writeAll(", self.raw.as_ptr()");
                } else if (comptime sliceType(T)) {
                    try w.print(", p{d}.as_{s}ptr(), p{d}.len() as u32", .{ i, if (@typeInfo(T).pointer.is_const) "" else "mut_", i });
                } else if (T == [4]u8) {
                    try w.print(", p{d}.as_ptr()", .{i});
                } else if (T == program.NetSocketService) {
                    try w.print(", p{d} as u8", .{i});
                } else if (T == usize) {
                    try w.print(", p{d} as u64", .{i});
                } else try w.print(", p{d}", .{i});
            }
            try w.writeAll(if (generation2) ") } }\n    }\n" else ") } else { ");
        }
    }
    try w.writeAll("}\n");
}
pub fn main(init: std.process.Init) !void {
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len != 5 or (!std.mem.eql(u8, args[1], "write") and !std.mem.eql(u8, args[1], "check"))) return error.UsageCheckOrWriteHeaderSourceAndRust;
    var c: std.Io.Writer.Allocating = .init(init.arena.allocator());
    var z: std.Io.Writer.Allocating = .init(init.arena.allocator());
    var r: std.Io.Writer.Allocating = .init(init.arena.allocator());
    try emit(&c.writer, &z.writer);
    try emitRust(&r.writer);
    for ([_][2][]const u8{ .{ args[2], c.written() }, .{ args[3], z.written() }, .{ args[4], r.written() } }) |item| {
        if (std.mem.eql(u8, args[1], "write")) try std.Io.Dir.cwd().writeFile(init.io, .{ .sub_path = item[0], .data = item[1] }) else {
            const actual = try std.Io.Dir.cwd().readFileAlloc(init.io, item[0], init.arena.allocator(), .limited(4 * 1024 * 1024));
            if (!std.mem.eql(u8, actual, item[1])) return error.NetFacadeBridgeDrift;
        }
    }
}
