const std = @import("std");
const abi = @import("r4os_technical_abi");
const c_projection = @import("c_projection.zig");

// Reflect the canonical typed Contract, including the append-only technical
// facade. There is deliberately no manually maintained Rust ABI description.
const rust_path = "Generated/SDK/Rust/src/lib.rs";
const inventory_path = "Generated/Inventory/RustABI.json";
const excluded_metadata = &.{ "R4AppProfileMeta", "R4PlatformApiMeta", "R4ApiSlotMeta" };

const Output = struct {
    allocator: std.mem.Allocator,
    bytes: std.ArrayList(u8) = .empty,
    fn text(self: *Output, value: []const u8) !void {
        try self.bytes.appendSlice(self.allocator, value);
    }
    fn print(self: *Output, comptime format: []const u8, args: anytype) !void {
        const value = try std.fmt.allocPrint(self.allocator, format, args);
        defer self.allocator.free(value);
        try self.text(value);
    }
    fn deinit(self: *Output) void {
        self.bytes.deinit(self.allocator);
    }
};

fn excluded(comptime T: type) bool {
    inline for (excluded_metadata) |name| if (T == @field(abi, name)) return true;
    return false;
}

fn identifier(comptime name: []const u8) []const u8 {
    const keywords = &.{ "as", "async", "await", "become", "box", "break", "const", "continue", "do", "dyn", "else", "enum", "extern", "false", "final", "fn", "for", "gen", "if", "impl", "in", "let", "loop", "macro", "match", "mod", "move", "mut", "override", "priv", "pub", "ref", "return", "static", "struct", "trait", "true", "try", "type", "typeof", "unsafe", "unsized", "use", "virtual", "where", "while", "yield" };
    inline for (keywords) |word| if (std.mem.eql(u8, name, word)) return "r#" ++ name;
    if (std.mem.eql(u8, name, "self") or std.mem.eql(u8, name, "Self") or std.mem.eql(u8, name, "super") or std.mem.eql(u8, name, "crate")) @compileError("Unsupported Rust identifier: " ++ name);
    return name;
}

fn typeName(comptime T: type) []const u8 {
    const name = @typeName(T);
    const start = if (std.mem.lastIndexOfScalar(u8, name, '.')) |index| index + 1 else 0;
    const local = name[start..];
    if (@hasDecl(abi, local) and @field(abi, local) == T) return identifier(local);
    // Compiler-derived extern records retain the canonical public alias even
    // when @typeName identifies their projection factory.
    inline for (std.meta.declarations(abi)) |decl| {
        const value = @field(abi, decl.name);
        if (@TypeOf(value) == type and value == T) return identifier(decl.name);
    }
    @compileError("ABI type lacks a canonical public name: " ++ name);
}

fn rustType(out: *Output, comptime T: type) anyerror!void {
    switch (@typeInfo(T)) {
        .void => try out.text("()"),
        .noreturn => try out.text("!"),
        .bool => try out.text("bool"),
        .int => |value| {
            if (T == usize) return out.text("usize");
            if (T == isize) return out.text("isize");
            if (comptime value.bits != 8 and value.bits != 16 and value.bits != 32 and value.bits != 64 and value.bits != 128) @compileError("Non-C integer width: " ++ @typeName(T));
            try out.print("{s}{d}", .{ if (value.signedness == .signed) "i" else "u", value.bits });
        },
        .float => |value| {
            if (comptime value.bits != 32 and value.bits != 64) @compileError("Unsupported float ABI: " ++ @typeName(T));
            try out.print("f{d}", .{value.bits});
        },
        .@"enum", .@"struct" => try out.text(comptime typeName(T)),
        .pointer => |pointer| {
            if (comptime pointer.size == .slice) @compileError("Zig-native slice reached the C ABI: " ++ @typeName(T));
            if (@typeInfo(pointer.child) == .@"fn") {
                try functionType(out, pointer.child);
            } else {
                try out.text(if (pointer.is_const) "*const " else "*mut ");
                if (pointer.child == anyopaque) try out.text("core::ffi::c_void") else try rustType(out, pointer.child);
            }
        },
        .optional => |optional| {
            const pointer = switch (@typeInfo(optional.child)) {
                .pointer => |p| p,
                else => @compileError("Tagged optional reached the C ABI: " ++ @typeName(T)),
            };
            if (@typeInfo(pointer.child) == .@"fn") {
                try out.text("Option<");
                try functionType(out, pointer.child);
                try out.text(">");
            } else try rustType(out, optional.child); // Nullable raw pointer, never Option<*mut T>.
        },
        .array => |array| {
            try out.text("[");
            try rustType(out, array.child);
            try out.print("; {d}]", .{@as(usize, array.len) + @as(usize, @intFromBool(array.sentinel_ptr != null))});
        },
        else => @compileError("Unsupported C ABI type: " ++ @typeName(T)),
    }
}

fn functionType(out: *Output, comptime T: type) anyerror!void {
    const function = @typeInfo(T).@"fn";
    if (comptime function.is_generic or function.is_var_args or !std.meta.eql(function.calling_convention, .c)) @compileError("Non-C or variadic callback: " ++ @typeName(T));
    if (comptime callbackFloats(*const T) != 0) @compileError("Soft-float C ABI needs an explicit reviewed bridge: " ++ @typeName(T));
    try out.text("unsafe extern \"C\" fn(");
    inline for (function.params, 0..) |parameter, index| {
        if (index != 0) try out.text(", ");
        try rustType(out, parameter.type orelse @compileError("Generic callback parameter"));
    }
    try out.text(") -> ");
    try rustType(out, function.return_type orelse @compileError("Generic callback return"));
}

fn valueLiteral(out: *Output, comptime T: type, comptime value: T) anyerror!void {
    switch (@typeInfo(T)) {
        .int, .comptime_int => try out.print("{d}", .{value}),
        .bool => try out.text(if (value) "true" else "false"),
        .@"enum" => {
            try out.text(comptime typeName(T));
            try out.print("({d})", .{@intFromEnum(value)});
        },
        .@"struct" => |structure| {
            try out.text(comptime typeName(T));
            try out.text(" { ");
            inline for (structure.fields, 0..) |field, index| {
                if (index != 0) try out.text(", ");
                try out.print("{s}: ", .{comptime identifier(field.name)});
                try valueLiteral(out, field.type, @field(value, field.name));
            }
            try out.text(" }");
        },
        .optional => |optional| {
            if (value != null) @compileError("Non-null ABI default needs a portable initializer: " ++ @typeName(T));
            const pointer = @typeInfo(optional.child).pointer;
            if (@typeInfo(pointer.child) == .@"fn") try out.text("None") else try out.text(if (pointer.is_const) "core::ptr::null()" else "core::ptr::null_mut()");
        },
        .array => |array| {
            try out.text("[");
            if (comptime array.len > 1 and repeated(T, value) and array.sentinel_ptr == null) {
                try valueLiteral(out, array.child, value[0]);
                try out.print("; {d}]", .{array.len});
                return;
            }
            inline for (value, 0..) |item, index| {
                if (index != 0) try out.text(", ");
                try valueLiteral(out, array.child, item);
            }
            if (array.sentinel_ptr) |sentinel| {
                if (array.len != 0) try out.text(", ");
                try valueLiteral(out, array.child, @as(*const array.child, @ptrCast(@alignCast(sentinel))).*);
            }
            try out.text("]");
        },
        .pointer => |pointer| {
            if (comptime pointer.size != .one or @typeInfo(pointer.child) != .array) @compileError("Non-string constant pointer: " ++ @typeName(T));
            try out.text("&");
            try valueLiteral(out, pointer.child, value.*);
        },
        else => @compileError("Unsupported ABI constant: " ++ @typeName(T)),
    }
}

fn repeated(comptime T: type, comptime value: T) bool {
    for (value[1..]) |item| if (!std.meta.eql(value[0], item)) return false;
    return true;
}

fn hasDefaults(comptime T: type) bool {
    inline for (@typeInfo(T).@"struct".fields) |field| if (field.default_value_ptr == null) return false;
    return true;
}

fn floatsInValue(comptime T: type) usize {
    return switch (@typeInfo(T)) {
        .float => 1,
        .array => |a| a.len * floatsInValue(a.child),
        .@"struct" => |s| result: {
            var count: usize = 0;
            for (s.fields) |f| count += floatsInValue(f.type);
            break :result count;
        },
        else => 0,
    };
}

fn callbackFloats(comptime T: type) usize {
    return switch (@typeInfo(T)) {
        .optional => |o| callbackFloats(o.child),
        .pointer => |p| result: {
            if (@typeInfo(p.child) != .@"fn") break :result 0;
            const f = @typeInfo(p.child).@"fn";
            var count = floatsInValue(f.return_type.?);
            for (f.params) |parameter| count += floatsInValue(parameter.type.?);
            break :result count;
        },
        else => 0,
    };
}

fn constant(out: *Output, comptime name: []const u8, comptime value: anytype) !void {
    const T = @TypeOf(value);
    switch (@typeInfo(T)) {
        .int, .comptime_int, .bool, .@"enum" => {
            try out.print("pub const {s}: ", .{comptime identifier(name)});
            if (T == comptime_int) try out.text(if (value < 0) "i128" else "u128") else try rustType(out, T);
            try out.text(" = ");
            try valueLiteral(out, T, value);
            try out.text(";\n");
        },
        .pointer => |pointer| {
            if (comptime pointer.size == .one and @typeInfo(pointer.child) == .array and @typeInfo(pointer.child).array.child == u8) {
                const array = @typeInfo(pointer.child).array;
                try out.print("pub const {s}: &[u8; {d}] = ", .{ comptime identifier(name), @as(usize, array.len) + @as(usize, @intFromBool(array.sentinel_ptr != null)) });
                try valueLiteral(out, T, value);
                try out.text(";\n");
            } else @compileError("Unexpected exported pointer value: " ++ name);
        },
        .array => |array| {
            if (comptime !excluded(array.child)) @compileError("Unexpected exported array: " ++ name);
            // These arrays contain Zig-native schema/doc metadata, not wire data.
        },
        .@"fn" => {}, // Zig facade helpers are deliberately not C exports.
        else => @compileError("Unsupported exported ABI value: " ++ name),
    }
}

fn declaration(out: *Output, assertions: *Output, comptime name: []const u8, comptime T: type) !void {
    const rust_name = comptime identifier(name);
    switch (@typeInfo(T)) {
        .@"struct" => |structure| {
            if (comptime excluded(T)) return;
            if (comptime structure.layout == .@"extern") {
                try out.print("\n#[repr(C)]\n#[derive(Clone, Copy)]\npub struct {s} {{\n", .{rust_name});
                inline for (structure.fields) |field| {
                    if (comptime (field.alignment orelse @alignOf(field.type)) != @alignOf(field.type)) @compileError("Explicit field alignment needs an audited Rust projection: " ++ name ++ "." ++ field.name);
                    try out.print("    pub {s}: ", .{comptime identifier(field.name)});
                    try rustType(out, field.type);
                    try out.text(",\n");
                    try assertions.print("    assert!(core::mem::offset_of!({s}, {s}) == {d});\n", .{ rust_name, comptime identifier(field.name), @offsetOf(T, field.name) });
                }
                try out.text("}\n");
                if (comptime hasDefaults(T)) {
                    // Keep one canonical initializer template, including nonzero
                    // version/magic/size defaults. Derivation is style, not ABI truth.
                    try out.print("#[allow(clippy::derivable_impls)]\nimpl Default for {s} {{\n    fn default() -> Self {{\n        Self {{\n", .{rust_name});
                    inline for (structure.fields) |field| {
                        try out.print("            {s}: ", .{comptime identifier(field.name)});
                        try valueLiteral(out, field.type, comptime field.defaultValue().?);
                        try out.text(",\n");
                    }
                    try out.text("        }\n    }\n}\n");
                }
                try assertions.print("    assert!(core::mem::size_of::<{s}>() == {d});\n    assert!(core::mem::align_of::<{s}>() == {d});\n", .{ rust_name, @sizeOf(T), rust_name, @alignOf(T) });
            } else if (comptime structure.layout == .auto and structure.fields.len == 0) {
                try out.print("\npub mod {s} {{\n    #[allow(unused_imports)]\n    use super::*;\n", .{rust_name});
                inline for (structure.decls) |decl| {
                    const item = @field(T, decl.name);
                    if (@TypeOf(item) == type) {
                        try out.print("    pub type {s} = ", .{comptime identifier(decl.name)});
                        try rustType(out, item);
                        try out.text(";\n");
                    } else try constant(out, decl.name, item);
                }
                try out.text("}\n");
            } else @compileError("Non-C exported struct: " ++ name);
        },
        .@"enum" => |enumeration| {
            // Integer newtypes accept future/unknown wire values without Rust enum UB.
            try out.print("\n#[repr(transparent)]\n#[derive(Clone, Copy, Debug, PartialEq, Eq)]\npub struct {s}(pub ", .{rust_name});
            try rustType(out, enumeration.tag_type);
            try out.print(");\nimpl {s} {{\n", .{rust_name});
            inline for (enumeration.fields) |field| try out.print("    pub const {s}: Self = Self({d});\n", .{ comptime identifier(field.name), field.value });
            try out.text("}\n");
            try assertions.print("    assert!(core::mem::size_of::<{s}>() == {d});\n    assert!(core::mem::align_of::<{s}>() == {d});\n", .{ rust_name, @sizeOf(T), rust_name, @alignOf(T) });
        },
        .pointer => {
            try out.print("\npub type {s} = ", .{rust_name});
            try rustType(out, T);
            try out.text(";\n");
            try assertions.print("    assert!(core::mem::size_of::<{s}>() == {d});\n    assert!(core::mem::align_of::<{s}>() == {d});\n", .{ rust_name, @sizeOf(T), rust_name, @alignOf(T) });
        },
        else => @compileError("Unsupported exported ABI declaration: " ++ name),
    }
}

fn countCall(comptime T: type) usize {
    return switch (@typeInfo(T)) {
        .pointer => |p| if (@typeInfo(p.child) == .@"fn") 1 else 0,
        .optional => |o| countCall(o.child),
        else => 0,
    };
}

pub fn main(init: std.process.Init) !void {
    @setEvalBranchQuota(10000000);
    const args = try init.minimal.args.toSlice(init.arena.allocator());
    if (args.len != 2 or (!std.mem.eql(u8, args[1], "--check") and !std.mem.eql(u8, args[1], "--write"))) return error.ExpectedCheckOrWrite;
    const write = std.mem.eql(u8, args[1], "--write");
    var out = Output{ .allocator = init.gpa };
    defer out.deinit();
    var assertions = Output{ .allocator = init.gpa };
    defer assertions.deinit();
    try out.text("// Generated by Contract/Tools/AbiRustGen; do not edit.\n// Canonical sources: API/ApiContract.json and Generated/SDK/Zig/abi.zig.\n#![no_std]\n#![allow(non_camel_case_types, non_snake_case, non_upper_case_globals)]\n\n#[cfg(not(all(target_arch = \"x86_64\", target_pointer_width = \"64\", target_endian = \"little\")))]\ncompile_error!(\"R4OS Contract requires little-endian x86_64 with 64-bit pointers\");\n");
    try out.text("#[path = \"../../../Generation2/Rust/generation2.rs\"]\npub mod generation2;\n");
    var structs: usize = 0;
    var fields: usize = 0;
    var enums: usize = 0;
    var callbacks: usize = 0;
    var constants: usize = 0;
    var scalar_float_parameters: usize = 0;
    inline for (comptime std.meta.declarations(abi)) |decl| {
        const value = @field(abi, decl.name);
        if (@TypeOf(value) == type) {
            try declaration(&out, &assertions, decl.name, value);
            try generation2Projection(&out, decl.name, value);
            switch (@typeInfo(value)) {
                .@"struct" => |s| {
                    if (s.layout == .@"extern") {
                        structs += 1;
                        fields += s.fields.len;
                        inline for (s.fields) |f| {
                            callbacks += comptime countCall(f.type);
                            scalar_float_parameters += comptime callbackFloats(f.type);
                            if (comptime callbackFloats(f.type) != 0) @compileError("Soft-float/SIMD C ABI needs an explicit reviewed bridge: " ++ decl.name ++ "." ++ f.name);
                        }
                    } else if (s.layout == .auto and s.fields.len == 0) {
                        inline for (s.decls) |item| {
                            const v = @field(value, item.name);
                            if (@TypeOf(v) == type) {
                                callbacks += comptime countCall(v);
                                scalar_float_parameters += comptime callbackFloats(v);
                            }
                        }
                    }
                },
                .@"enum" => enums += 1,
                .pointer => {
                    callbacks += comptime countCall(value);
                    scalar_float_parameters += comptime callbackFloats(value);
                },
                else => {},
            }
        } else {
            try constant(&out, decl.name, value);
            switch (@typeInfo(@TypeOf(value))) {
                .int, .comptime_int, .bool, .@"enum", .pointer => constants += 1,
                else => {},
            }
        }
    }
    try out.text("\n// Each expectation is computed independently by Zig from the canonical type.\nconst _: () = {\n");
    try out.text(assertions.bytes.items);
    try out.text("};\n");
    var inventory = Output{ .allocator = init.gpa };
    defer inventory.deinit();
    try inventory.print("{{\n  \"schema\": 1,\n  \"binding\": \"Generated/SDK/Rust/src/lib.rs\",\n  \"sources\": [\"API/ApiContract.json\", \"Generated/SDK/Zig/abi.zig\"],\n  \"extern_structs\": {d},\n  \"fields\": {d},\n  \"integer_enums\": {d},\n  \"callback_declarations\": {d},\n  \"constants\": {d},\n  \"scalar_float_abi_values\": {d},\n  \"direct_vector_abi_values\": 0,\n  \"excluded_zig_metadata_types\": [\"R4AppProfileMeta\", \"R4PlatformApiMeta\", \"R4ApiSlotMeta\"],\n  \"target\": \"x86_64-unknown-none\"\n}}\n", .{ structs, fields, enums, callbacks, constants, scalar_float_parameters });
    if (scalar_float_parameters != 0) return error.UnreviewedFloatAbi;
    const technical_c = try c_projection.generate(init.arena.allocator());
    inline for (.{ .{ rust_path, out.bytes.items }, .{ inventory_path, inventory.bytes.items }, .{ c_projection.path, technical_c.bytes } }) |file| {
        const cwd = std.Io.Dir.cwd();
        if (write) {
            try cwd.createDirPath(init.io, std.fs.path.dirname(file[0]).?);
            try cwd.writeFile(init.io, .{ .sub_path = file[0], .data = file[1] });
        } else {
            const actual = try cwd.readFileAlloc(init.io, file[0], init.gpa, .limited(8 * 1024 * 1024));
            defer init.gpa.free(actual);
            if (!std.mem.eql(u8, actual, file[1])) return error.RustAbiDrift;
        }
    }
    std.debug.print("Rust ABI {s}: {d} extern structs, {d} fields, {d} integer enums, {d} callbacks, {d} constants\n", .{ if (write) "written" else "checked", structs, fields, enums, callbacks, constants });
    std.debug.print("Technical C ABI: {d} structs, {d} integer enums, {d} callback aliases, {d} constants\n", .{ technical_c.structs, technical_c.enums, technical_c.aliases, technical_c.constants });
}

fn generation2Projection(out: *Output, comptime name: []const u8, comptime T: type) !void {
    if (comptime std.mem.eql(u8, name, "DriverApi2") or std.mem.eql(u8, name, "ProtocolApi2")) {
        const driver = comptime std.mem.eql(u8, name, "DriverApi2");
        try out.print("\nimpl {s} {{\n    pub const fn project_provider(source: &{s}", .{ name, if (driver) "DriverApi" else "ProtocolApi" });
        if (driver) try out.text(", register_audio: AudioBackendRegisterFn2");
        try out.text(") -> Self { Self {\n");
        inline for (std.meta.fields(T)) |field| {
            try out.print("        {s}: ", .{comptime identifier(field.name)});
            if (comptime std.mem.eql(u8, field.name, "magic")) {
                try out.text(if (driver) "driver_api2_magic" else "protocol_api2_magic");
            } else if (comptime std.mem.eql(u8, field.name, "version")) {
                try out.text(if (driver) "driver_api2_version" else "protocol_api2_version");
            } else if (comptime std.mem.eql(u8, field.name, "size")) {
                try out.text("core::mem::size_of::<Self>() as u32");
            } else if (comptime std.mem.eql(u8, field.name, "reserved")) {
                try out.text("0");
            } else if (comptime driver and std.mem.eql(u8, field.name, "register_audio_output_backend")) {
                try out.text("register_audio");
            } else if (comptime driver and std.mem.eql(u8, field.name, "register_audio_capture_backend")) {
                try out.text("None");
            } else if (comptime !driver and (std.mem.eql(u8, field.name, "protocol_dispatch") or std.mem.eql(u8, field.name, "link_io") or std.mem.eql(u8, field.name, "process_status"))) {
                // Source is the exact original legacy table. New optional
                // protocol mechanisms are supplied separately by the owner.
                try out.text("None");
            } else try out.print("source.{s}", .{comptime identifier(field.name)});
            try out.text(",\n");
        }
        try out.text("    } }\n}\n");
    } else if (comptime std.mem.eql(u8, name, "AudioBackendStatus2")) {
        try out.text("\nimpl AudioBackendStatus2 {\n    pub fn expand_legacy(self) -> AudioBackendStatus { AudioBackendStatus {\n");
        inline for (std.meta.fields(T)) |field| try out.print("        {s}: self.{s},\n", .{ comptime identifier(field.name), comptime identifier(field.name) });
        try out.text("        ..AudioBackendStatus::default()\n    } }\n}\n");
    }
}
