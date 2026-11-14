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
        if (T == s.metrics.Cache) break :blk "R4SdkTextMetrics";
        if (T == s.metrics.Key) break :blk "R4SdkTextMetricsKey";
        if (T == s.offers.Client) break :blk "R4SdkClipboardOffers";
        if (T == s.composition.Owner) break :blk "R4SdkComposition";
        if (T == s.gui) break :blk "R4SdkGui";
        if (T == s.language) break :blk "R4SdkGui";
        if (T == s.app_gui) break :blk "R4SdkAppGui";
        if (T == s.shapes) break :blk "R4SdkGuiShapes";
        if (T == s.chart) break :blk "R4SdkGuiChart";
        if (T == s.clipboard) break :blk "R4SdkGuiClipboard";
        if (T == s.input) break :blk "R4SdkGuiInput";
        if (T == s.mode) break :blk "R4SdkGuiWindowMode";
        if (T == s.program.Context) break :blk "R4SdkGuiProgramContext";
        if (T == s.sys.Context) break :blk "R4SdkGuiSystemContext";
        if (T == s.desk.Context) break :blk "R4SdkGuiDesktopContext";
        if (T == s.draw.Context) break :blk "R4SdkGuiDrawContext";
        if (T == s.audio.Context) break :blk "R4SdkAudioContext";
        if (T == s.platform.Context) break :blk "R4SdkPlatformContext";
        if (T == s.power.Reply) break :blk "R4SdkPowerReply";
        if (T == s.power.CpuReply) break :blk "R4SdkPowerCpuReply";
        if (T == @FieldType(s.app_audio.WriteResult, "failure")) break :blk "R4SdkAudioWriteFailure";
        if (T == s.app_audio) break :blk "R4SdkAudio";
        if (T == s.app_devices) break :blk "R4SdkDevices";
        if (T == s.pcm) break :blk "R4SdkPcm";
        if (T == s.power) break :blk "R4SdkPower";
        if (T == s.dev.Context) break :blk "R4SdkGfxDeviceContext";
        if (T == s.gfx.Context) break :blk "R4SdkGfxContext";
        if (T == s.gfx_buffers) break :blk "R4SdkGfxBuffers";
        if (T == s.gfx_outputs) break :blk "R4SdkGfxOutputs";
        if (T == s.gfx_queue) break :blk "R4SdkGfxQueue";
        if (T == s.gfx_telemetry) break :blk "R4SdkGfxTelemetry";
        if (T == s.graphics_status) break :blk "R4SdkGraphicsStatus";
        if (T == s.session.Session) break :blk "R4SdkGuiSession";
        if (T == s.session.EventKind) break :blk "R4SdkGuiEventKind";
        if (T == s.gui.TextField([]u8)) break :blk "R4SdkGuiTextField";
        if (T == s.gui.TextArea([]u8)) break :blk "R4SdkGuiTextArea";
        if (T == s.input.Queue([]s.abi.ConsoleInputEvent)) break :blk "R4SdkGuiInputQueue";
        const full = @typeName(T);
        if (std.mem.startsWith(u8, full, "gui_modern.")) break :blk "R4SdkGui" ++ clean(full["gui_modern.".len..]);
        if (std.mem.indexOf(u8, full, "__struct_") != null or std.mem.indexOf(u8, full, "__enum_") != null or std.mem.indexOf(u8, full, "__union_") != null) break :blk std.fmt.comptimePrint("R4SdkGuiType{d}", .{s.typeId(T)});
        if (s.canonical(T)) {
            const last = full[(std.mem.lastIndexOfScalar(u8, full, '.') orelse unreachable) + 1 ..];
            break :blk if (std.mem.startsWith(u8, last, "R4")) last else "R4" ++ last;
        }
        const prefixes = .{ .{ "gui.", "R4SdkGui" }, .{ "app_gui.", "R4SdkGui" }, .{ "gui_shapes.", "R4SdkGuiShape" }, .{ "chart.", "R4SdkGuiChart" }, .{ "clipboard.", "R4SdkGuiClipboard" }, .{ "window_mode.", "R4SdkGuiWindowMode" }, .{ "input_events.", "R4SdkGuiInput" } };
        for (prefixes ++ .{ .{ "gfx_buffers.", "R4SdkGfxBuffers" }, .{ "gfx_outputs.", "R4SdkGfxOutputs" }, .{ "gfx_queue.", "R4SdkGfxQueue" }, .{ "gfx_telemetry.", "R4SdkGfxTelemetry" }, .{ "graphics_status.", "R4SdkGraphicsStatus" }, .{ "app_audio.", "R4SdkAudio" }, .{ "app_devices.", "R4SdkDevices" }, .{ "audio_pcm.", "R4SdkPcm" }, .{ "power_profiles.", "R4SdkPower" } }) |entry| if (std.mem.startsWith(u8, full, entry[0])) break :blk entry[1] ++ clean(full[entry[0].len..]);
        break :blk std.fmt.comptimePrint("R4SdkGuiType{d}", .{s.typeId(T)});
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
        .float => if (@sizeOf(T) == 4) "float" else "double",
        else => if (T == anyopaque) "void" else name(T),
    };
}
fn param(comptime T: type) []const u8 {
    return comptime switch (@typeInfo(T)) {
        .bool => "uint8_t",
        .int => integer(T),
        .@"enum" => "uint32_t",
        .float => "const " ++ storage(T) ++ " *",
        .pointer => |p| if (@typeInfo(p.child) == .@"fn") "uintptr_t" else (if (p.is_const) "const " else "") ++ storage(p.child) ++ " *",
        .optional => "R4SdkGuiSlot",
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
    if (comptime @typeInfo(T) == .pointer and @typeInfo(T).pointer.size == .slice) try w.print(", uintptr_t n{d}", .{i});
}
fn argument(w: *std.Io.Writer, comptime T: type, comptime index: usize) !void {
    try w.print(" a[{d}] = ", .{index});
    switch (@typeInfo(T)) {
        .bool, .int, .@"enum" => try w.print("(R4SdkGuiSlot){{.bits=(uint64_t)(int64_t)p{d},.flags=R4SDK_GUI_PRESENT}};\n", .{index}),
        .optional => try w.print("p{d};\n", .{index}),
        .pointer => |p| {
            try w.print("(R4SdkGuiSlot){{.ptr=(void *){s}p{d},", .{ if (@typeInfo(p.child) == .@"fn") "(uintptr_t)" else "", index });
            if (p.size == .slice) try w.print(".length=n{d},", .{index});
            try w.writeAll(".flags=R4SDK_GUI_PRESENT};\n");
        },
        else => try w.print("(R4SdkGuiSlot){{.ptr=(void *)p{d},.flags=R4SDK_GUI_PRESENT}};\n", .{index}),
    }
}
fn fieldList(comptime T: type) []const std.builtin.Type.StructField {
    return @typeInfo(T).@"struct".fields;
}

fn constructorPrefix(comptime T: type) usize {
    // Existing scalar constructors keep their exact source signatures. New
    // defaulted presentation fields use typed setters/withStyle/layoutTabs.
    if (T == s.gui.Canvas) return 5;
    if (T == s.gui.TabBar) return 7;
    return fieldList(T).len;
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
            else => {},
        }
    }
    if (comptime @typeInfo(T) == .@"enum") inline for (@typeInfo(T).@"enum".fields) |f| try w.print("#define {s}_{s} {d}u\n", .{ name(T), f.name, f.value });
}
pub fn emit(w: *std.Io.Writer) !void {
    @setEvalBranchQuota(32_000_000);
    try w.writeAll("/* Compiler-generated GUI owner boundary. Do not edit.\n * Private objects are native storage: use MaybeUninit in Rust. Never read\n * their bytes or assume padding initialized. Initialize all required fields\n * through the typed constructor before use. Borrowed strings/arrays/contexts\n * must outlive every referencing object. Stateful contexts/frames stay at\n * their exact address; inspect native status before release/reuse. Raw field\n * mutation requires preservation of the original owner's invariants.\n * Slot.status is transport status; bits retain native scalar return values,\n * including negative i32. PRESENT marks optional payloads, NATIVE_ERROR\n * exposes a resident error-name view. A returned view borrows its inputs or\n * exact native owner. Float values cross only through pointers. */\n#ifndef R4OS_GUI_BRIDGE_H\n#define R4OS_GUI_BRIDGE_H\n#include \"abi.h\"\n#define R4SDK_GUI_PRESENT 1u\n#define R4SDK_GUI_NATIVE_ERROR 2u\n#define R4SDK_GUI_DEFAULT 4u\ntypedef struct R4SdkGuiSlot { void *ptr; uint64_t length,bits; int32_t status; uint32_t flags; } R4SdkGuiSlot;\nR4SdkGuiSlot R4SdkGuiInvoke(uint64_t,uint32_t,const R4SdkGuiSlot *,uint32_t,void *);\nR4SdkGuiSlot R4SdkGuiConstruct(uint64_t,uint32_t,const R4SdkGuiSlot *,uint32_t,void *);\nR4SdkGuiSlot R4SdkGuiInspect(uint64_t,uint32_t,void *,void *);\nR4SdkGuiSlot R4SdkGuiField(uint64_t,uint32_t,uint32_t,void *,const R4SdkGuiSlot *,void *);\n");
    try w.writeAll("#include \"platform2.h\"\n#include \"text_metrics.h\"\n#include \"clipboard_offer_platform2.h\"\n#include \"text_composition.h\"\n#include \"file_picker.h\"\n");
    inline for (s.types, 0..) |T, i| {
        if (comptime s.canonical(T)) continue;
        try w.print("/* {s}; native size {d}, alignment {d}. */\ntypedef struct {s} {{ _Alignas({d}) uint8_t opaque_bytes[{d}]; }} {s};\n#define {s}_TYPE {d}u\n", .{ s.stableName(@typeName(T)), @sizeOf(T), @alignOf(T), name(T), @alignOf(T), @max(1, @sizeOf(T)), name(T), name(T), i });
    }
    try w.print("#define R4SdkGui_ABI_FINGERPRINT UINT64_C({d})\nint32_t R4SdkGuiVerifyAbi(uint64_t);\n", .{s.fingerprint});
    inline for (s.modules) |M| try constants(w, M);
    try w.writeAll("R4SdkGuiSystemContext *R4SdkPlatformSystem(R4SdkPlatformContext *);\nR4SdkGfxDeviceContext *R4SdkPlatformDevice(R4SdkPlatformContext *);\nR4SdkAudioAudio *R4SdkPlatformAudio(R4SdkPlatformContext *);\nR4SdkAudioContext *R4SdkPlatformAudioRaw(R4SdkPlatformContext *);\nR4SdkDevicesDevices *R4SdkPlatformDevices(R4SdkPlatformContext *);\n");
    try w.writeAll("/* Offscreen graphics admission is independent of GUI windows/host claims.\n * Keep this context pinned while any borrowed native subcontext is used.\n * Resources require explicit native close/unmap/fence/reset acknowledgements. */\nR4SdkGuiDrawContext *R4SdkGfxDraw(R4SdkGfxContext *);\nR4SdkGfxDeviceContext *R4SdkGfxDevice(R4SdkGfxContext *);\n");
    try w.writeAll("int32_t R4SdkGfxOpenNative2(uint64_t,R4SdkGfxContext *,const R4XStartContext2 *);\nstatic inline int32_t R4SdkGfxOpen2(R4SdkGfxContext *s,const R4XStartContext2 *ctx) { return R4SdkGfxOpenNative2(R4SdkGui_ABI_FINGERPRINT,s,ctx); }\n");
    try constants(w, s.session.EventKind);
    inline for (s.types) |T| if (comptime !s.canonical(T) and !s.context(T)) try constants(w, T);
    try w.writeAll("/* Session storage must stay at this address until Close. Open initializes\n * caller-owned timers. role=0 is a hosted app, role=1 an independent host.\n * HostReset closes only the endpoint; the WindowService binding remains\n * tied to the exact live process. Reopening is explicit, without retries. */\ntypedef struct R4SdkGuiEvent {\n");
    inline for (@typeInfo(s.session.Event).@"struct".fields) |f| try w.print(" {s} {s};\n", .{ storage(f.type), f.name });
    try w.writeAll("} R4SdkGuiEvent;\nvoid R4SdkGuiSessionClose(R4SdkGuiSession *);\nR4SdkGuiProgramContext *R4SdkGuiSessionProgram(R4SdkGuiSession *);\nR4SdkGuiSystemContext *R4SdkGuiSessionSystem(R4SdkGuiSession *);\nR4SdkGuiDesktopContext *R4SdkGuiSessionDesktop(R4SdkGuiSession *);\nR4SdkGuiDrawContext *R4SdkGuiSessionDraw(R4SdkGuiSession *);\nR4SdkGuiWindow *R4SdkGuiSessionWindow(R4SdkGuiSession *);\nR4SdkGuiCanvas *R4SdkGuiSessionCanvas(R4SdkGuiSession *);\nint32_t R4SdkGuiSessionBegin(R4SdkGuiSession *,R4GuiFrameCommand *,uintptr_t,uint8_t *,uintptr_t);\nint32_t R4SdkGuiSessionEnd(R4SdkGuiSession *,uint32_t);\nint32_t R4SdkGuiSessionNext(R4SdkGuiSession *,const R4Timeout *,R4SdkGuiEvent *);\nint32_t R4SdkGuiSessionTimer(R4SdkGuiSession *,uintptr_t,uint32_t,const R4Duration *,uint32_t);\nint32_t R4SdkGuiSessionCancelTimer(R4SdkGuiSession *,uintptr_t);\nint32_t R4SdkGuiSessionCommand(R4SdkGuiSession *,uint32_t);\nint32_t R4SdkGuiSessionMode(R4SdkGuiSession *,uint32_t,uint32_t,R4WindowModeReply *);\nint32_t R4SdkGuiSessionHostClaim(R4SdkGuiSession *,R4TrayDesktopExchange *,const R4Timeout *);\nint32_t R4SdkGuiSessionHostExchange(R4SdkGuiSession *,uint16_t,const R4TrayDesktopExchange *,R4TrayDesktopExchange *,const R4Timeout *);\nvoid R4SdkGuiSessionHostReset(R4SdkGuiSession *);\n");
    try w.writeAll("int32_t R4SdkGuiSessionOpenNative2(uint64_t,R4SdkGuiSession *,const R4XStartContext2 *,uint32_t,R4SdkGuiTimer *,uintptr_t);\nstatic inline int32_t R4SdkGuiSessionOpen2(R4SdkGuiSession *s,const R4XStartContext2 *ctx,uint32_t role,R4SdkGuiTimer *timers,uintptr_t count) { return R4SdkGuiSessionOpenNative2(R4SdkGui_ABI_FINGERPRINT,s,ctx,role,timers,count); }\n");
    try w.writeAll("/* Picker, rows, label/scratch storage and records stay disjoint and borrowed through draw. Labels never escape this call. */\nint32_t R4SdkGuiPickerDrawNative(uint64_t,const R4SdkGuiCanvas *,const R4SdkFilePicker *,const R4SdkGuiRect *,const R4SdkWireSpan *,const R4SdkWireSpan *,const R4SdkWireSpan *);\nstatic inline int32_t R4SdkGuiPickerDraw(const R4SdkGuiCanvas *c,const R4SdkFilePicker *p,const R4SdkGuiRect *r,const R4SdkWireSpan *title,const R4SdkWireSpan *labels,const R4SdkWireSpan *scratch) { return R4SdkGuiPickerDrawNative(R4SdkGui_ABI_FINGERPRINT,c,p,r,title,labels,scratch); }\n");
    inline for (s.functions, 0..) |entry, i| {
        const info = @typeInfo(@TypeOf(@field(entry.owner, entry.name))).@"fn";
        const R = info.return_type.?;
        try w.print("/* {s}.{s} -> {s} */\nstatic inline R4SdkGuiSlot {s}_{s}(", .{ s.stableName(@typeName(entry.owner)), entry.name, s.stableName(@typeName(R)), name(entry.owner), entry.name });
        // A leading opaque-free sentinel makes the zero-parameter form uniform.
        try w.writeAll("uint32_t reserved");
        inline for (info.params, 0..) |p, n| try parameter(w, p.type.?, n);
        if (comptime needsOutput(R)) try w.print(", {s} *output", .{storage(base(R))});
        try w.print(") {{\n (void)reserved; R4SdkGuiSlot a[{d}]={{0}};\n", .{@max(1, info.params.len)});
        inline for (info.params, 0..) |p, n| try argument(w, p.type.?, n);
        try w.print(" return R4SdkGuiInvoke(R4SdkGui_ABI_FINGERPRINT,{d}u,a,{d}u,{s});\n}}\n", .{ i, info.params.len, if (comptime needsOutput(R)) "output" else "0" });
    }
    inline for (s.types, 0..) |T, id| {
        if (comptime s.canonical(T) or s.context(T)) continue;
        const info = @typeInfo(T);
        if (info == .@"union") {
            if (info.@"union".tag_type) |Tag| inline for (@typeInfo(Tag).@"enum".fields) |field| try w.print("#define {s}_TAG_{s} {d}u\n", .{ name(T), field.name, field.value });
        }
        if (info == .@"struct") {
            const fields = comptime fieldList(T);
            const prefix = comptime constructorPrefix(T);
            try w.print("static inline R4SdkGuiSlot {s}_create({s} *output", .{ name(T), name(T) });
            inline for (fields, 0..) |f, i| if (f.default_value_ptr == null) {
                try parameter(w, f.type, i);
            };
            try w.print(") {{\n R4SdkGuiSlot a[{d}]={{0}};\n", .{@max(1, fields.len)});
            inline for (fields, 0..) |f, i| {
                if (f.default_value_ptr != null) try w.print(" a[{d}].flags=R4SDK_GUI_DEFAULT;\n", .{i}) else try argument(w, f.type, i);
            }
            try w.print(" return R4SdkGuiConstruct(R4SdkGui_ABI_FINGERPRINT,{d}u,a,{d}u,output);\n}}\n", .{ id, fields.len });
            try w.print("static inline R4SdkGuiSlot {s}_from_fields({s} *output", .{ name(T), name(T) });
            inline for (fields[0..prefix], 0..) |f, i| try parameter(w, f.type, i);
            try w.print(") {{\n R4SdkGuiSlot a[{d}]={{0}};\n", .{@max(1, fields.len)});
            inline for (fields, 0..) |f, i| {
                if (comptime i < prefix) try argument(w, f.type, i) else {
                    if (f.default_value_ptr == null) @compileError("Legacy GUI constructor tail must have a native default");
                    try w.print(" a[{d}].flags=R4SDK_GUI_DEFAULT;\n", .{i});
                }
            }
            try w.print(" return R4SdkGuiConstruct(R4SdkGui_ABI_FINGERPRINT,{d}u,a,{d}u,output);\n}}\n", .{ id, fields.len });
        } else if (info == .@"enum" or info == .pointer or info == .optional or info == .array) {
            try w.print("static inline R4SdkGuiSlot {s}_create({s} *output", .{ name(T), name(T) });
            try parameter(w, T, 0);
            try w.writeAll(") { R4SdkGuiSlot a[1]={0};\n");
            try argument(w, T, 0);
            try w.print(" return R4SdkGuiConstruct(R4SdkGui_ABI_FINGERPRINT,{d}u,a,1u,output); }}\n", .{id});
        }
        if (info == .@"struct" or info == .@"union") {
            const fields = if (info == .@"struct") info.@"struct".fields else info.@"union".fields;
            inline for (fields, 0..) |f, i| {
                try w.print("static inline R4SdkGuiSlot {s}_get_{s}(const {s} *self", .{ name(T), f.name, name(T) });
                if (comptime needsOutput(f.type)) try w.print(", {s} *output", .{storage(base(f.type))});
                try w.print(") {{ return R4SdkGuiField(R4SdkGui_ABI_FINGERPRINT,{d}u,{d}u,(void *)self,0,{s}); }}\n", .{ id, i, if (comptime needsOutput(f.type)) "output" else "0" });
                try w.print("static inline R4SdkGuiSlot {s}_set_{s}({s} *self", .{ name(T), f.name, name(T) });
                if (f.type != void) try parameter(w, f.type, 0);
                try w.writeAll(") { R4SdkGuiSlot a[1]={0};\n");
                if (f.type != void) try argument(w, f.type, 0);
                try w.print(" return R4SdkGuiField(R4SdkGui_ABI_FINGERPRINT,{d}u,{d}u,self,a,0); }}\n", .{ id, i });
            }
        }
        try w.print("static inline R4SdkGuiSlot {s}_inspect(const {s} *self", .{ name(T), name(T) });
        if (comptime needsOutput(T) and info != .@"struct" and info != .@"union") try w.print(", {s} *output", .{storage(base(T))});
        try w.print(") {{ return R4SdkGuiInspect(R4SdkGui_ABI_FINGERPRINT,{d}u,(void *)self,{s}); }}\n", .{ id, if (comptime needsOutput(T) and info != .@"struct" and info != .@"union") "output" else "0" });
    }
    try w.writeAll("#endif\n");
}
