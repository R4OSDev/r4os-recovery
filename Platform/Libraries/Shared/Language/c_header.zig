const std = @import("std");
const s = @import("schema");
fn clean(comptime value: []const u8) []const u8 {
    return comptime blk: {
        var bytes: [value.len]u8 = undefined;
        for (value, 0..) |ch, i| bytes[i] = if (std.ascii.isAlphanumeric(ch) or ch == '_') ch else '_';
        const result = bytes;
        break :blk &result;
    };
}
pub fn name(comptime T: type) []const u8 {
    return comptime blk: {
        const full = s.stableName(@typeName(T));
        if (T == s.owners.image_color) break :blk "R4ImgColor";
        if (T == s.owners.native_jpeg) break :blk "R4ImgNativeJpeg";
        if (T == s.owners.time.Config) break :blk "R4StdTimeHelpersConfig";
        if (T == s.owners.media.gfx_api.ColorV1Client) break :blk "R4LibraryColorClient";
        if (T == s.owners.media.gfx_api.DeviceV1Client) break :blk "R4LibraryDeviceClient";
        if (T == s.owners.media.gfx_api.RenderV1Client) break :blk "R4LibraryRenderClient";
        if (T == s.owners.media.gfx_api.ApiV1Client) break :blk "R4LibraryGraphicsClient";
        if (T == s.owners.media.aco_api.CompilerV1Client) break :blk "R4LibraryAcoClient";
        if (T == s.owners.media.nak_api.CompilerV1Client) break :blk "R4LibraryNakClient";
        if (T == s.owners.media.profile) break :blk "R4GfxDisplayProfileOwner";
        if (s.canonical(T)) {
            const last = full[(std.mem.lastIndexOfScalar(u8, full, '.') orelse unreachable) + 1 ..];
            break :blk if (std.mem.startsWith(u8, last, "R4")) last else "R4" ++ last;
        }
        if (@typeInfo(T) == .pointer or @typeInfo(T) == .optional or @typeInfo(T) == .array or @typeInfo(T) == .error_union or std.mem.indexOf(u8, full, "__") != null) break :blk std.fmt.comptimePrint("R4Lib_Value{d}", .{s.typeId(T)});
        const prefixes = .{
            .{ "consumer_media_adapters", "R4Media" },
            .{ "R4ACO.Bindings.Zig.shaders", "R4AcoShaders" },
            .{ "R4ACO.Bindings.Zig.worker", "R4Aco" },
            .{ "R4ENC.Bindings.Zig.recording_mux", "R4EncMux" },
            .{ "R4ENC.Bindings.Zig.recording_pixels", "R4EncPixels" },
            .{ "R4GFX.Bindings.Zig.outputs", "R4GfxOutputs" },
            .{ "R4GFX.Bindings.Zig.queue", "R4GfxQueue" },
            .{ "R4GFX.Display.brightness_client", "R4GfxBrightnessClient" },
            .{ "R4GFX.Display.brightness_preferences", "R4GfxBrightnessPreferences" },
            .{ "R4GFX.Display.brightness_status", "R4GfxBrightnessStatus" },
            .{ "R4GFX.Display.color_control", "R4GfxColorControl" },
            .{ "R4GFX.Display.color_preferences", "R4GfxColorPreferences" },
            .{ "R4GFX.Display.color_signal", "R4GfxColorSignal" },
            .{ "R4GFX.Display.control", "R4GfxControl" },
            .{ "R4GFX.Display.cta_timings", "R4GfxCtaTimings" },
            .{ "R4GFX.Display.desktop_outputs", "R4GfxDesktopOutputs" },
            .{ "R4GFX.Display.display_profile", "R4GfxDisplayProfile" },
            .{ "R4GFX.Display.edid", "R4GfxEdid" },
            .{ "R4GFX.Display.eld", "R4GfxEld" },
            .{ "R4GFX.Display.links", "R4GfxLinks" },
            .{ "R4GFX.Display.mode_control", "R4GfxModeControl" },
            .{ "R4GFX.Display.preferences", "R4GfxPreferences" },
            .{ "R4GFX.Display.readback", "R4GfxReadback" },
            .{ "R4GFX.Display.refresh_client", "R4GfxRefreshClient" },
            .{ "R4GFX.Display.refresh_observer", "R4GfxRefreshObserver" },
            .{ "R4GFX.Display.refresh_preferences", "R4GfxRefreshPreferences" },
            .{ "R4GFX.Display.refresh_range", "R4GfxRefreshRange" },
            .{ "R4GFX.Display.refresh_status", "R4GfxRefreshStatus" },
            .{ "R4GFX.Display.timing", "R4GfxTiming" },
            .{ "R4GFX.Display.topology", "R4GfxTopology" },
            .{ "R4GFX.Display.transfer", "R4GfxTransfer" },
            .{ "R4GFX.Display.vrr", "R4GfxVrr" },
            .{ "R4NAK.Bindings.Zig.worker", "R4Nak" },
            .{ "R4VIDEO.Bindings.Zig.playback", "R4VideoPlayback" },
            .{ "R4VIDEO.Bindings.Zig.playback_audio", "R4VideoPlaybackAudio" },
            .{ "R4VIDEO.Bindings.Zig.playback_clock", "R4VideoPlaybackClock" },
            .{ "R4VIDEO.Bindings.Zig.playback_composition", "R4VideoPlaybackComposition" },
            .{ "R4STD.Bindings.Zig.r4std", "R4Std" },
            .{ "R4STD.Bindings.Zig.text", "R4StdText" },
            .{ "R4STD.Bindings.Zig.settings", "R4StdSettings" },
            .{ "R4STD.Bindings.Zig.date", "R4StdDate" },
            .{ "R4STD.Bindings.Zig.time", "R4StdTime" },
            .{ "R4STD.Bindings.Zig.config", "R4StdConfig" },
            .{ "R4STD.Bindings.Zig.codec", "R4StdCodec" },
            .{ "R4STD.Bindings.Zig.grapheme", "R4StdGrapheme" },
            .{ "R4STD.Bindings.Zig.path_text", "R4StdPathText" },
            .{ "R4STD.Bindings.Zig.console_text", "R4StdConsoleText" },
            .{ "R4STD.Bindings.Zig.shortcut", "R4StdShortcut" },
            .{ "R4STD.Bindings.Zig.app_assoc", "R4StdAssociation" },
            .{ "R4STD.Bindings.Zig.file_handler", "R4StdFileHandler" },
            .{ "R4STD.Bindings.Zig.subsystem_runtime", "R4StdSubsystem" },
            .{ "R4IMG.Bindings.Zig.r4img", "R4ImgHelpers" },
            .{ "R4FONT.Bindings.Zig.r4font", "R4FontHelpers" },
            .{ "R4FONT.Bindings.Zig.app_fonts", "R4FontStore" },
            .{ "R4FONT.Bindings.Zig.font_import", "R4FontImport" },
            .{ "R4FONT.Bindings.Zig.font_format", "R4FontFormat" },
            .{ "Shared.Language.support", "R4Library" },
            .{ "consumer_adapters", "R4StdAdapters" },
            .{ "mem.Allocator", "R4LibraryAllocator" },
        };
        for (prefixes) |entry| if (std.mem.eql(u8, full, entry[0])) {
            break :blk entry[1];
        } else if (std.mem.startsWith(u8, full, entry[0] ++ ".")) {
            break :blk entry[1] ++ clean(full[entry[0].len + 1 ..]);
        };
        break :blk "R4Lib_" ++ clean(full);
    };
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
        .optional => "R4LibrariesSlot",
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
    try w.print(", {s} p{d}", .{ param(T), i });
    if (comptime @typeInfo(T) == .error_set or (@typeInfo(T) == .pointer and @typeInfo(T).pointer.size == .slice)) try w.print(", uintptr_t n{d}", .{i});
}
fn argument(w: *std.Io.Writer, comptime T: type, comptime index: usize) !void {
    try w.print(" a[{d}] = ", .{index});
    switch (@typeInfo(T)) {
        .error_set => try w.print("(R4LibrariesSlot){{.ptr=(void *)p{d},.length=n{d},.flags=R4LIBRARIES_PRESENT}};\n", .{ index, index }),
        .bool, .int, .@"enum" => try w.print("(R4LibrariesSlot){{.bits=(uint64_t)(int64_t)p{d},.flags=R4LIBRARIES_PRESENT}};\n", .{index}),
        .optional => try w.print("p{d};\n", .{index}),
        .pointer => |p| {
            try w.print("(R4LibrariesSlot){{.ptr=(void *){s}p{d},", .{ if (@typeInfo(p.child) == .@"fn") "(uintptr_t)" else "", index });
            if (p.size == .slice) try w.print(".length=n{d},", .{index});
            try w.writeAll(".flags=R4LIBRARIES_PRESENT};\n");
        },
        else => try w.print("(R4LibrariesSlot){{.ptr=(void *)p{d},.flags=R4LIBRARIES_PRESENT}};\n", .{index}),
    }
}
fn fieldList(comptime T: type) []const std.builtin.Type.StructField {
    return @typeInfo(T).@"struct".fields;
}
fn stringConstant(w: *std.Io.Writer, comptime T: type, comptime field: []const u8, comptime bytes: []const u8) !void {
    try w.print("static const uint8_t {s}_CONST_{s}[] = {{", .{ name(T), field });
    for (bytes) |b| try w.print("{d},", .{b});
    try w.writeAll("0};\n");
    try w.print("static inline R4LibrariesSlot {s}_constant_{s}(void) {{ return (R4LibrariesSlot){{.ptr=(void *){s}_CONST_{s},.length={d},.flags=1u}}; }}\n", .{ name(T), field, name(T), field, bytes.len });
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
            .comptime_int, .int => try w.print("#define {s}_{s} ({d})\n", .{ name(T), decl.name, value }),
            .bool => try w.print("#define {s}_{s} {d}u\n", .{ name(T), decl.name, @intFromBool(value) }),
            .pointer => |pointer| {
                if (comptime pointer.size == .one and @typeInfo(pointer.child) == .array and @typeInfo(pointer.child).array.child == u8) try stringConstant(w, T, decl.name, value);
            },
            .array => |array| {
                if (comptime array.child == u8) try stringConstant(w, T, decl.name, &value);
            },
            else => {},
        }
    }
    if (comptime @typeInfo(T) == .@"enum") inline for (@typeInfo(T).@"enum".fields) |f| try w.print("#define {s}_{s} {d}u\n", .{ name(T), f.name, f.value });
}
pub fn emit(w: *std.Io.Writer) !void {
    @setEvalBranchQuota(32_000_000);
    try w.writeAll("/* Compiler-generated library helper boundary. Do not edit.\n * Private objects are native storage: use MaybeUninit in Rust. Never read\n * their bytes or assume padding initialized. Initialize all required fields\n * through the typed constructor before use. Borrowed strings/arrays/contexts\n * must outlive every referencing object. Stateful contexts/frames stay at\n * their exact address; inspect native status before release/reuse. Raw field\n * mutation requires preservation of the original owner's invariants.\n * Slot.status is transport status; bits retain native scalar return values,\n * including negative i32. PRESENT marks optional payloads, NATIVE_ERROR\n * exposes a resident error-name view. A returned view borrows its inputs or\n * exact native owner. Float values cross only through pointers. */\n#ifndef R4LIBRARIES_HELPERS_H\n#define R4LIBRARIES_HELPERS_H\n#include \"r4os/abi.h\"\n#define R4LIBRARIES_PRESENT 1u\n#define R4LIBRARIES_NATIVE_ERROR 2u\n#define R4LIBRARIES_DEFAULT 4u\ntypedef struct R4LibrariesSlot { void *ptr; uint64_t length,bits; int32_t status; uint32_t flags; } R4LibrariesSlot;\nR4LibrariesSlot R4LibrariesInvoke(uint64_t,uint32_t,const R4LibrariesSlot *,uint32_t,void *);\nR4LibrariesSlot R4LibrariesConstruct(uint64_t,uint32_t,const R4LibrariesSlot *,uint32_t,void *);\nR4LibrariesSlot R4LibrariesInspect(uint64_t,uint32_t,void *,void *);\nR4LibrariesSlot R4LibrariesField(uint64_t,uint32_t,uint32_t,void *,const R4LibrariesSlot *,void *);\n");
    inline for (s.types, 0..) |T, i| {
        if (comptime s.canonical(T)) continue;
        try w.print("/* {s}; native size {d}, alignment {d}. */\ntypedef struct {s} {{ _Alignas({d}) uint8_t opaque_bytes[{d}]; }} {s};\n#define {s}_TYPE {d}u\n", .{ s.stableName(@typeName(T)), @sizeOf(T), @alignOf(T), name(T), @alignOf(T), @max(1, @sizeOf(T)), name(T), name(T), i });
    }
    try w.print("#define R4Libraries_ABI_FINGERPRINT UINT64_C({d})\nint32_t R4LibrariesVerifyAbi(uint64_t);\n", .{s.fingerprint});
    inline for (s.modules) |M| try constants(w, M);
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
        try w.print("/* {s}.{s} -> {s} */\nstatic inline R4LibrariesSlot {s}_{s}(", .{ s.stableName(@typeName(entry.owner)), entry.name, s.stableName(@typeName(R)), name(entry.owner), entry.name });
        // A leading opaque-free sentinel makes the zero-parameter form uniform.
        try w.writeAll("uint32_t reserved");
        inline for (info.params, 0..) |p, n| try parameter(w, p.type.?, n);
        if (comptime needsOutput(R)) try w.print(", {s} *output", .{storage(base(R))});
        try w.print(") {{\n (void)reserved; R4LibrariesSlot a[{d}]={{0}};\n", .{@max(1, info.params.len)});
        inline for (info.params, 0..) |p, n| try argument(w, p.type.?, n);
        try w.print(" return R4LibrariesInvoke(R4Libraries_ABI_FINGERPRINT,{d}u,a,{d}u,{s});\n}}\n", .{ i, info.params.len, if (comptime needsOutput(R)) "output" else "0" });
    }
    inline for (s.types, 0..) |T, id| {
        if (comptime s.canonical(T) or s.context(T)) continue;
        const info = @typeInfo(T);
        if (info == .@"union") {
            if (info.@"union".tag_type) |Tag| inline for (@typeInfo(Tag).@"enum".fields) |field| try w.print("#define {s}_TAG_{s} {d}u\n", .{ name(T), field.name, field.value });
        }
        if (info == .@"struct") {
            const fields = comptime fieldList(T);
            try w.print("static inline R4LibrariesSlot {s}_create({s} *output", .{ name(T), name(T) });
            inline for (fields, 0..) |f, i| if (f.default_value_ptr == null) {
                try parameter(w, f.type, i);
            };
            try w.print(") {{\n R4LibrariesSlot a[{d}]={{0}};\n", .{@max(1, fields.len)});
            inline for (fields, 0..) |f, i| {
                if (f.default_value_ptr != null) try w.print(" a[{d}].flags=R4LIBRARIES_DEFAULT;\n", .{i}) else try argument(w, f.type, i);
            }
            try w.print(" return R4LibrariesConstruct(R4Libraries_ABI_FINGERPRINT,{d}u,a,{d}u,output);\n}}\n", .{ id, fields.len });
            try w.print("static inline R4LibrariesSlot {s}_from_fields({s} *output", .{ name(T), name(T) });
            inline for (fields, 0..) |f, i| try parameter(w, f.type, i);
            try w.print(") {{\n R4LibrariesSlot a[{d}]={{0}};\n", .{@max(1, fields.len)});
            inline for (fields, 0..) |f, i| try argument(w, f.type, i);
            try w.print(" return R4LibrariesConstruct(R4Libraries_ABI_FINGERPRINT,{d}u,a,{d}u,output);\n}}\n", .{ id, fields.len });
        } else if (info == .@"enum" or info == .pointer or info == .optional or info == .array) {
            try w.print("static inline R4LibrariesSlot {s}_create({s} *output", .{ name(T), name(T) });
            try parameter(w, T, 0);
            try w.writeAll(") { R4LibrariesSlot a[1]={0};\n");
            try argument(w, T, 0);
            try w.print(" return R4LibrariesConstruct(R4Libraries_ABI_FINGERPRINT,{d}u,a,1u,output); }}\n", .{id});
        }
        if (info == .@"struct" or info == .@"union") {
            const fields = if (info == .@"struct") info.@"struct".fields else info.@"union".fields;
            inline for (fields, 0..) |f, i| {
                try w.print("static inline R4LibrariesSlot {s}_get_{s}(const {s} *self", .{ name(T), f.name, name(T) });
                if (comptime needsOutput(f.type)) try w.print(", {s} *output", .{storage(base(f.type))});
                try w.print(") {{ return R4LibrariesField(R4Libraries_ABI_FINGERPRINT,{d}u,{d}u,(void *)self,0,{s}); }}\n", .{ id, i, if (comptime needsOutput(f.type)) "output" else "0" });
                try w.print("static inline R4LibrariesSlot {s}_set_{s}({s} *self", .{ name(T), f.name, name(T) });
                if (f.type != void) try parameter(w, f.type, 0);
                try w.writeAll(") { R4LibrariesSlot a[1]={0};\n");
                if (f.type != void) try argument(w, f.type, 0);
                try w.print(" return R4LibrariesField(R4Libraries_ABI_FINGERPRINT,{d}u,{d}u,self,a,0); }}\n", .{ id, i });
            }
        }
        try w.print("static inline R4LibrariesSlot {s}_inspect(const {s} *self", .{ name(T), name(T) });
        if (comptime needsOutput(T) and info != .@"struct" and info != .@"union") try w.print(", {s} *output", .{storage(base(T))});
        try w.print(") {{ return R4LibrariesInspect(R4Libraries_ABI_FINGERPRINT,{d}u,(void *)self,{s}); }}\n", .{ id, if (comptime needsOutput(T) and info != .@"struct" and info != .@"union") "output" else "0" });
    }
    try w.writeAll("#endif\n");
}
