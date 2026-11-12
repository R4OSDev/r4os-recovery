const std = @import("std");
const s = @import("schema");
const options = @import("options");
fn replace(comptime value: []const u8, comptime from: []const u8, comptime to: []const u8) []const u8 {
    return comptime if (std.mem.indexOf(u8, value, from)) |index| value[0..index] ++ to ++ replace(value[index + from.len ..], from, to) else value;
}
fn scoped(comptime value: []const u8) []const u8 {
    return replace(replace(value, "R4SdkData", options.prefix), "R4SDKDATA", options.macro);
}

pub fn name(comptime T: type) []const u8 {
    return options.name(T);
}
fn integer(comptime T: type) []const u8 {
    const info = @typeInfo(T).int;
    const bits = if (info.bits <= 8) 8 else if (info.bits <= 16) 16 else if (info.bits <= 32) 32 else 64;
    return std.fmt.comptimePrint("{s}int{d}_t", .{ if (info.signedness == .signed) "" else "u", bits });
}
pub fn storage(comptime T: type) []const u8 {
    return comptime switch (@typeInfo(T)) {
        .void => "void",
        .bool => "uint8_t",
        .int => integer(T),
        .error_set => "const uint8_t *",
        .float => if (@sizeOf(T) == 4) "float" else "double",
        else => if (T == anyopaque) "void" else name(T),
    };
}
fn param(comptime T: type) []const u8 {
    return comptime switch (@typeInfo(T)) {
        .bool => "uint8_t",
        .int => integer(T),
        .error_set => "const uint8_t *",
        .@"enum" => "uint32_t",
        .float => "const " ++ storage(T) ++ " *",
        .pointer => |p| if (@typeInfo(p.child) == .@"fn") "uintptr_t" else (if (p.is_const) "const " else "") ++ storage(p.child) ++ " *",
        .optional => scoped("R4SdkDataSlot"),
        else => "const " ++ storage(T) ++ " *",
    };
}
pub fn base(comptime T: type) type {
    return switch (@typeInfo(T)) {
        .optional => |o| base(o.child),
        .error_union => |e| base(e.payload),
        else => T,
    };
}
pub fn needsOutput(comptime T: type) bool {
    return switch (@typeInfo(base(T))) {
        .@"struct", .@"union", .array, .float => true,
        else => false,
    };
}
fn parameter(w: *std.Io.Writer, comptime T: type, comptime i: usize) !void {
    try w.print(scoped(", {s} p{d}"), .{ param(T), i });
    if (comptime @typeInfo(T) == .error_set or (@typeInfo(T) == .pointer and @typeInfo(T).pointer.size == .slice)) try w.print(scoped(", uintptr_t n{d}"), .{i});
}
fn argument(w: *std.Io.Writer, comptime T: type, comptime index: usize) !void {
    try w.print(scoped(" a[{d}] = "), .{index});
    switch (@typeInfo(T)) {
        .error_set => try w.print(scoped("(R4SdkDataSlot){{.ptr=(void *)p{d},.length=n{d},.flags=R4SDKDATA_PRESENT}};\n"), .{ index, index }),
        .bool, .int, .@"enum" => try w.print(scoped("(R4SdkDataSlot){{.bits=(uint64_t)(int64_t)p{d},.flags=R4SDKDATA_PRESENT}};\n"), .{index}),
        .optional => try w.print(scoped("p{d};\n"), .{index}),
        .pointer => |p| {
            try w.print(scoped("(R4SdkDataSlot){{.ptr=(void *){s}p{d},"), .{ if (@typeInfo(p.child) == .@"fn") "(uintptr_t)" else "", index });
            if (p.size == .slice) try w.print(scoped(".length=n{d},"), .{index});
            try w.writeAll(scoped(".flags=R4SDKDATA_PRESENT};\n"));
        },
        else => try w.print(scoped("(R4SdkDataSlot){{.ptr=(void *)p{d},.flags=R4SDKDATA_PRESENT}};\n"), .{index}),
    }
}
fn fieldList(comptime T: type) []const std.builtin.Type.StructField {
    return @typeInfo(T).@"struct".fields;
}
fn constructor(comptime T: type) []const u8 {
    // A real owner method named create keeps its public name. The transport
    // constructor is generated metadata and must not shadow that operation.
    if (comptime @typeInfo(T) == .@"struct" or @typeInfo(T) == .@"enum") {
        if (comptime @hasDecl(T, "create")) return comptime name(T) ++ "_constructNative";
    }
    return comptime name(T) ++ "_create";
}
fn stringConstant(w: *std.Io.Writer, comptime T: type, comptime field: []const u8, comptime bytes: []const u8) !void {
    try w.print(scoped("static const uint8_t {s}_CONST_{s}[] = {{"), .{ name(T), field });
    for (bytes) |b| try w.print(scoped("{d},"), .{b});
    try w.writeAll(scoped("0};\n"));
    try w.print(scoped("static inline R4SdkDataSlot {s}_constant_{s}(void) {{ return (R4SdkDataSlot){{.ptr=(void *){s}_CONST_{s},.length={d},.flags=1u}}; }}\n"), .{ name(T), field, name(T), field, bytes.len });
}
fn constants(w: *std.Io.Writer, comptime T: type) !void {
    if (comptime @typeInfo(T) != .@"struct" and @typeInfo(T) != .@"union" and @typeInfo(T) != .@"enum") return;
    const declarations = comptime switch (@typeInfo(T)) {
        .@"struct" => |v| v.decls,
        .@"union" => |v| v.decls,
        .@"enum" => |v| v.decls,
        else => unreachable,
    };
    inline for (declarations) |decl| {
        const value = @field(T, decl.name);
        switch (@typeInfo(@TypeOf(value))) {
            .comptime_int, .int => try w.print(scoped("#define {s}_{s} ({d})\n"), .{ name(T), decl.name, value }),
            .bool => try w.print(scoped("#define {s}_{s} {d}u\n"), .{ name(T), decl.name, @intFromBool(value) }),
            .pointer => |pointer| {
                if (comptime pointer.size == .one and @typeInfo(pointer.child) == .array and @typeInfo(pointer.child).array.child == u8) try stringConstant(w, T, decl.name, value);
            },
            .array => |array| {
                if (comptime array.child == u8) try stringConstant(w, T, decl.name, &value);
            },
            else => {},
        }
    }
    if (comptime @typeInfo(T) == .@"enum") inline for (@typeInfo(T).@"enum".fields) |f| try w.print(scoped("#define {s}_{s} {d}u\n"), .{ name(T), f.name, f.value });
}
pub fn emit(w: *std.Io.Writer) !void {
    @setEvalBranchQuota(32_000_000);
    try w.writeAll(scoped("/* Compiler-generated SDK data helper boundary. Do not edit.\n * Private objects are native storage: use MaybeUninit in Rust. Never read\n * their bytes or assume padding initialized. Initialize all required fields\n * through the typed constructor before use. Borrowed strings/arrays/contexts\n * must outlive every referencing object. Stateful contexts/frames stay at\n * their exact address; inspect native status before release/reuse. Raw field\n * mutation requires preservation of the original owner's invariants.\n * Slot.status is transport status; bits retain native scalar return values,\n * including negative i32. PRESENT marks optional payloads, NATIVE_ERROR\n * exposes a resident error-name view. A returned view borrows its inputs or\n * exact native owner. Float values cross only through pointers. */\n#ifndef R4SDKDATA_HELPERS_H\n#define R4SDKDATA_HELPERS_H\n#include \"r4os/abi.h\"\n#define R4SDKDATA_PRESENT 1u\n#define R4SDKDATA_NATIVE_ERROR 2u\n#define R4SDKDATA_DEFAULT 4u\ntypedef struct R4SdkDataSlot { void *ptr; uint64_t length,bits; int32_t status; uint32_t flags; } R4SdkDataSlot;\nR4SdkDataSlot R4SdkDataInvoke(uint64_t,uint32_t,const R4SdkDataSlot *,uint32_t,void *);\nR4SdkDataSlot R4SdkDataConstruct(uint64_t,uint32_t,const R4SdkDataSlot *,uint32_t,void *);\nR4SdkDataSlot R4SdkDataInspect(uint64_t,uint32_t,void *,void *);\nR4SdkDataSlot R4SdkDataField(uint64_t,uint32_t,uint32_t,void *,const R4SdkDataSlot *,void *);\n"));
    inline for (s.types, 0..) |T, i| {
        if (comptime s.canonical(T)) continue;
        try w.print(scoped("/* {s}; native size {d}, alignment {d}. */\ntypedef struct {s} {{ _Alignas({d}) uint8_t opaque_bytes[{d}]; }} {s};\n#define {s}_TYPE {d}u\n"), .{ s.stableName(@typeName(T)), @sizeOf(T), @alignOf(T), name(T), @alignOf(T), @max(1, @sizeOf(T)), name(T), name(T), i });
    }
    try w.print(scoped("#define R4SdkData_ABI_FINGERPRINT UINT64_C({d})\nint32_t R4SdkDataVerifyAbi(uint64_t);\n"), .{s.fingerprint});
    inline for (s.modules) |M| try constants(w, M);
    if (comptime @hasDecl(options, "extra_include")) try w.print("#include \"{s}\"\n", .{options.extra_include});
    inline for (s.types) |T| {
        if (comptime s.canonical(T) or s.context(T)) continue;
        if (@typeInfo(T) != .@"struct" and @typeInfo(T) != .@"union" and @typeInfo(T) != .@"enum") continue;
        comptime var already = false;
        inline for (s.modules) |M| if (T == M) {
            already = true;
        };
        if (comptime !already) try constants(w, T);
    }
    inline for (s.functions, 0..) |entry, i| {
        const info = @typeInfo(@TypeOf(@field(entry.owner, entry.name))).@"fn";
        const R = info.return_type.?;
        try w.print(scoped("/* {s}.{s} -> {s} */\nstatic inline R4SdkDataSlot {s}_{s}("), .{ s.stableName(@typeName(entry.owner)), entry.name, s.stableName(@typeName(R)), name(entry.owner), entry.name });
        // A leading opaque-free sentinel makes the zero-parameter form uniform.
        try w.writeAll(scoped("uint32_t reserved"));
        inline for (info.params, 0..) |p, n| try parameter(w, p.type.?, n);
        if (comptime needsOutput(R)) try w.print(scoped(", {s} *output"), .{storage(base(R))});
        try w.print(scoped(") {{\n (void)reserved; R4SdkDataSlot a[{d}]={{0}};\n"), .{@max(1, info.params.len)});
        inline for (info.params, 0..) |p, n| try argument(w, p.type.?, n);
        try w.print(scoped(" return R4SdkDataInvoke(R4SdkData_ABI_FINGERPRINT,{d}u,a,{d}u,{s});\n}}\n"), .{ i, info.params.len, if (comptime needsOutput(R)) "output" else "0" });
    }
    inline for (s.types, 0..) |T, id| {
        if (comptime s.canonical(T) or s.context(T)) continue;
        const info = @typeInfo(T);
        if (info == .@"union") {
            if (info.@"union".tag_type) |Tag| inline for (@typeInfo(Tag).@"enum".fields) |field| try w.print(scoped("#define {s}_TAG_{s} {d}u\n"), .{ name(T), field.name, field.value });
        }
        if (info == .@"struct") {
            const fields = comptime fieldList(T);
            try w.print(scoped("static inline R4SdkDataSlot {s}({s} *output"), .{ constructor(T), name(T) });
            inline for (fields, 0..) |f, i| if (f.default_value_ptr == null) {
                try parameter(w, f.type, i);
            };
            try w.print(scoped(") {{\n R4SdkDataSlot a[{d}]={{0}};\n"), .{@max(1, fields.len)});
            inline for (fields, 0..) |f, i| {
                if (f.default_value_ptr != null) try w.print(scoped(" a[{d}].flags=R4SDKDATA_DEFAULT;\n"), .{i}) else try argument(w, f.type, i);
            }
            try w.print(scoped(" return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,{d}u,a,{d}u,output);\n}}\n"), .{ id, fields.len });
            try w.print(scoped("static inline R4SdkDataSlot {s}_from_fields({s} *output"), .{ name(T), name(T) });
            inline for (fields, 0..) |f, i| try parameter(w, f.type, i);
            try w.print(scoped(") {{\n R4SdkDataSlot a[{d}]={{0}};\n"), .{@max(1, fields.len)});
            inline for (fields, 0..) |f, i| try argument(w, f.type, i);
            try w.print(scoped(" return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,{d}u,a,{d}u,output);\n}}\n"), .{ id, fields.len });
        } else if (info == .@"enum" or info == .pointer or info == .optional or info == .array) {
            try w.print(scoped("static inline R4SdkDataSlot {s}({s} *output"), .{ constructor(T), name(T) });
            try parameter(w, T, 0);
            try w.writeAll(scoped(") { R4SdkDataSlot a[1]={0};\n"));
            try argument(w, T, 0);
            try w.print(scoped(" return R4SdkDataConstruct(R4SdkData_ABI_FINGERPRINT,{d}u,a,1u,output); }}\n"), .{id});
        }
        if (info == .@"struct" or info == .@"union") {
            const fields = if (info == .@"struct") info.@"struct".fields else info.@"union".fields;
            inline for (fields, 0..) |f, i| {
                try w.print(scoped("static inline R4SdkDataSlot {s}_get_{s}(const {s} *self"), .{ name(T), f.name, name(T) });
                if (comptime needsOutput(f.type)) try w.print(scoped(", {s} *output"), .{storage(base(f.type))});
                try w.print(scoped(") {{ return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,{d}u,{d}u,(void *)self,0,{s}); }}\n"), .{ id, i, if (comptime needsOutput(f.type)) "output" else "0" });
                try w.print(scoped("static inline R4SdkDataSlot {s}_set_{s}({s} *self"), .{ name(T), f.name, name(T) });
                if (f.type != void) try parameter(w, f.type, 0);
                try w.writeAll(scoped(") { R4SdkDataSlot a[1]={0};\n"));
                if (f.type != void) try argument(w, f.type, 0);
                try w.print(scoped(" return R4SdkDataField(R4SdkData_ABI_FINGERPRINT,{d}u,{d}u,self,a,0); }}\n"), .{ id, i });
            }
        }
        try w.print(scoped("static inline R4SdkDataSlot {s}_inspectNative(const {s} *self"), .{ name(T), name(T) });
        if (comptime needsOutput(T) and info != .@"struct" and info != .@"union") try w.print(scoped(", {s} *output"), .{storage(base(T))});
        try w.print(scoped(") {{ return R4SdkDataInspect(R4SdkData_ABI_FINGERPRINT,{d}u,(void *)self,{s}); }}\n"), .{ id, if (comptime needsOutput(T) and info != .@"struct" and info != .@"union") "output" else "0" });
    }
    try w.writeAll(scoped("#endif\n"));
}
