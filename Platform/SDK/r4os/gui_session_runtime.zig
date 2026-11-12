//! Only context/lifetime and scalar transport; all GUI work stays at its owner.
const std = @import("std");
const a = @import("r4os_contract").abi;
const p = @import("program.zig");
const sys = @import("r4sys.zig");
const desk = @import("r4desk.zig");
const draw = @import("r4draw.zig");
const app = @import("app_gui.zig");
const gui = @import("gui.zig");
const support = @import("gui_session_support.zig");
const S = support.Session;
const E = support.Event;
const Kind = support.EventKind;

pub export fn R4SdkGuiSessionOpenNative(fingerprint: u64, s: *S, raw: *const a.R4XStartContext, role: u32, timers: ?[*]app.Timer, count: usize) callconv(.c) i32 {
    if (fingerprint != @import("gui_bridge_schema.zig").fingerprint) return a.io_error_invalid;
    if (role > 1 or raw.instance_id > std.math.maxInt(u32) or (count != 0 and timers == null) or count > std.math.maxInt(isize) / @sizeOf(app.Timer)) return a.io_error_invalid;
    const bundle = p.bundleValueFromR4XStart(raw) orelse return a.err_no_group;
    inline for (.{ .{ bundle.sys, a.R4XStartR4Sys{} }, .{ bundle.desk, a.R4XStartR4Desk{} }, .{ bundle.draw, a.R4XStartR4Draw{} } }) |entry| {
        const table = entry[0] orelse return a.err_no_group;
        if (table.abi_version < entry[1].abi_version or table.size < entry[1].size) return a.err_no_fn;
    }
    s.* = .{ .bundle = bundle, .instance_id = @intCast(raw.instance_id), .program = undefined, .sys = undefined, .desk = undefined, .draw = undefined, .timers = if (count == 0) &.{} else timers.?[0..count], .role = role };
    s.program = p.Context.initBundle(&s.bundle);
    s.sys = sys.Context.init(&s.bundle);
    s.desk = desk.Context.init(&s.bundle);
    s.draw = draw.Context.init(&s.bundle);
    return finishOpen(s);
}
pub export fn R4SdkGuiSessionOpenNative2(fingerprint: u64, s: *S, raw: *const @import("platform2.zig").abi.R4XStartContext2, role: u32, timers: ?[*]app.Timer, count: usize) callconv(.c) i32 {
    if (fingerprint != @import("gui_bridge_schema.zig").fingerprint) return a.io_error_invalid;
    if (role > 1 or raw.instance_id == 0 or raw.instance_id > std.math.maxInt(u32) or (count != 0 and timers == null) or count > std.math.maxInt(isize) / @sizeOf(app.Timer)) return a.io_error_invalid;
    const context = @import("platform2.zig").Context.init(raw) catch return a.io_error_invalid;
    if (context.desktop() == null or context.drawing() == null) return a.err_no_group;
    s.* = .{ .bundle = undefined, .context2 = context, .instance_id = @intCast(raw.instance_id), .program = undefined, .sys = undefined, .desk = undefined, .draw = undefined, .timers = if (count == 0) &.{} else timers.?[0..count], .role = role };
    // The caller pins Session before admission. Both pointers target its final
    // storage and remain borrowed until explicit Close and all subloans retire.
    s.memory2 = @import("allocator_source.zig").Memory.fromContext2(&s.context2.?);
    s.program = .{ .generation2 = &s.context2.?, .memory2 = &s.memory2 };
    s.sys = sys.Context.fromProgram(s.program);
    s.desk = desk.Context.fromProgram(s.program);
    s.draw = draw.Context.fromProgram(s.program);
    return finishOpen(s);
}
fn finishOpen(s: *S) i32 {
    for (s.timers) |*timer| timer.* = .{};
    if (s.role == 0) s.window = app.Window.init(s.sys, s.desk, s.draw, s.timers) orelse return a.err_no_fn;
    // Host admission deliberately never queries or binds an application window.
    return 0;
}
pub export fn R4SdkGuiSessionProgram(s: *S) callconv(.c) *p.Context {
    return &s.program;
}
pub export fn R4SdkGuiSessionSystem(s: *S) callconv(.c) *sys.Context {
    return &s.sys;
}
pub export fn R4SdkGuiSessionDesktop(s: *S) callconv(.c) *desk.Context {
    return &s.desk;
}
pub export fn R4SdkGuiSessionDraw(s: *S) callconv(.c) *draw.Context {
    return &s.draw;
}
pub export fn R4SdkGuiSessionWindow(s: *S) callconv(.c) ?*app.Window {
    return if (s.window) |*w| w else null;
}
pub export fn R4SdkGuiSessionCanvas(s: *S) callconv(.c) ?*gui.Canvas {
    return if (s.paint != null) &s.canvas else null;
}

/// Draws the original FileDialog from one immutable complete picker page.
/// All records, title, label/scratch storage, Canvas, picker and row buffers
/// are mapped and disjoint. No labels or controller pointers escape the call.
pub export fn R4SdkGuiPickerDrawNative(fingerprint: u64, canvas: *const gui.Canvas, picker: *const @import("file_picker.zig").Session, rectangle: *const gui.Rect, title: *const @import("binary_cursor.zig").Span, label_storage: *const @import("binary_cursor.zig").Span, scratch: *const @import("binary_cursor.zig").Span) callconv(.c) i32 {
    const picker_api = @import("file_picker_api.zig");
    const picker_owner = @import("file_picker.zig");
    if (fingerprint != @import("gui_bridge_schema.zig").fingerprint) return a.io_error_invalid;
    const title_value = title.*;
    const labels_value = label_storage.*;
    const scratch_value = scratch.*;
    const heading = title_value.bytes() catch return picker_owner.storage_error;
    labels_value.validate() catch return picker_owner.storage_error;
    scratch_value.validate() catch return picker_owner.storage_error;
    const rows = picker.rows() orelse return picker_owner.incomplete;
    if (labels_value.address % @alignOf([]const u8) != 0 or labels_value.length % @sizeOf([]const u8) != 0 or labels_value.length / @sizeOf([]const u8) < rows.len) return picker_owner.storage_error;
    const labels: [][]const u8 = if (rows.len == 0) &.{} else @as([*][]const u8, @ptrFromInt(labels_value.address))[0..rows.len];
    const text_scratch: []u8 = if (scratch_value.length == 0) &.{} else @as([*]u8, @ptrFromInt(scratch_value.address))[0..scratch_value.length];
    const dialog = picker_api.dialog(picker, rectangle.*, heading, labels) orelse return picker_owner.incomplete;
    return dialog.draw(canvas.*, text_scratch);
}
pub export fn R4SdkGuiSessionBegin(s: *S, commands: ?[*]a.GuiFrameCommand, count: usize, resources: ?[*]u8, length: usize) callconv(.c) i32 {
    if (s.paint != null or (count != 0 and commands == null) or (length != 0 and resources == null) or count > std.math.maxInt(isize) / @sizeOf(a.GuiFrameCommand) or length > std.math.maxInt(isize)) return a.io_error_invalid;
    const window = if (s.window) |*w| w else return a.err_no_fn;
    if (!window.draw.supportsGuiFrameContract()) return a.err_no_fn;
    switch (window.beginPaint()) {
        .failure => |rc| return rc,
        .paint => |paint| s.paint = paint,
    }
    s.canvas = if (count != 0) s.paint.?.bufferedCanvas(&s.frame, commands.?[0..count], if (length == 0) &.{} else resources.?[0..length]) else s.paint.?.canvas;
    return 0;
}
pub export fn R4SdkGuiSessionEnd(s: *S, present: u32) callconv(.c) i32 {
    const paint = if (s.paint) |*v| v else return a.err_no_fn;
    if (present > 1) return a.io_error_invalid;
    const rc = if (present == 1) paint.present() else blk: {
        paint.discard();
        break :blk @as(i32, 0);
    };
    if (!paint.active) s.paint = null;
    return rc;
}
fn event(message: app.Message) E {
    var out: E = .{};
    switch (message) {
        .close => |id| {
            out.kind = @intFromEnum(Kind.close);
            out.window_id = id;
        },
        .resize => |v| {
            out.kind = @intFromEnum(Kind.resize);
            out.window_id = v.window_id;
            out.width = v.width;
            out.height = v.height;
            out.tick = v.tick;
        },
        .key => |v| {
            out.kind = @intFromEnum(Kind.key);
            out.window_id = v.window_id;
            out.codepoint = v.codepoint;
            out.modifiers = v.modifiers;
            out.tick = v.tick;
        },
        .mouse => |v| {
            out.kind = @intFromEnum(switch (v.action) {
                .down => Kind.mouse_down,
                .up => Kind.mouse_up,
                .move => Kind.mouse_move,
            });
            out.window_id = v.window_id;
            out.x = v.x;
            out.y = v.y;
            out.buttons = v.buttons;
            out.modifiers = v.modifiers;
            out.tick = v.tick;
        },
        .command => |v| {
            out.kind = @intFromEnum(Kind.command);
            out.id = v.value;
        },
        .clipboard => |v| {
            out.kind = @intFromEnum(Kind.clipboard);
            out.revision = v.revision;
        },
        .timer => |v| {
            out.kind = @intFromEnum(Kind.timer);
            out.id = v.id.value;
            out.tick = v.tick;
        },
        .unknown => |v| {
            out.kind = @intFromEnum(Kind.unknown);
            out.raw = v;
        },
        .focus_gained, .focus_lost => |v| {
            out.kind = @intFromEnum(if (message == .focus_gained) Kind.focus_gained else Kind.focus_lost);
            out.window_id = v.window_id;
            out.tick = v.tick;
            out.raw = message.guiEvent().?;
        },
        .font_changed => |v| {
            out.kind = @intFromEnum(Kind.font_changed);
            out.window_id = v.window_id;
            out.tick = v.tick;
            out.raw = message.guiEvent().?;
        },
        .wheel => |v| {
            out.kind = @intFromEnum(Kind.wheel);
            out.window_id = v.window_id;
            out.x = v.x;
            out.y = v.y;
            out.width = v.delta;
            out.buttons = v.buttons;
            out.modifiers = v.modifiers;
            out.tick = v.tick;
            out.raw = message.guiEvent().?;
        },
        .relative => |v| {
            out.kind = @intFromEnum(Kind.relative);
            out.window_id = v.window_id;
            out.x = v.dx;
            out.y = v.dy;
            out.id = v.source;
            out.buttons = v.buttons;
            out.modifiers = v.modifiers;
            out.tick = v.tick;
            out.raw = message.guiEvent().?;
        },
        .input_reset => |v| {
            out.kind = @intFromEnum(Kind.input_reset);
            out.window_id = v.window_id;
            out.id = v.reason;
            out.tick = v.tick;
            out.raw = message.guiEvent().?;
        },
        .pointer_capture => |v| {
            out.kind = @intFromEnum(Kind.pointer_capture);
            out.window_id = v.window_id;
            out.id = v.state;
            out.revision = v.reason;
            out.buttons = v.mode;
            out.tick = v.tick;
            out.raw = message.guiEvent().?;
        },
    }
    return out;
}
pub export fn R4SdkGuiSessionNext(s: *S, timeout: *const a.R4Timeout, out: *E) callconv(.c) i32 {
    out.* = .{};
    const window = if (s.window) |*w| w else return a.err_no_fn;
    return switch (window.waitMessage(timeout.*)) {
        .failure => |rc| rc,
        .timed_out => 0,
        .message => |value| blk: {
            out.* = event(value);
            break :blk 1;
        },
    };
}
pub export fn R4SdkGuiSessionTimer(s: *S, index: usize, id: u32, duration: *const a.R4Duration, repeating: u32) callconv(.c) i32 {
    if (index >= s.timers.len or repeating > 1) return a.io_error_invalid;
    return if (s.timers[index].start(&s.sys, .{ .value = id }, duration.*, repeating == 1)) 0 else a.io_error_invalid;
}
pub export fn R4SdkGuiSessionCancelTimer(s: *S, index: usize) callconv(.c) i32 {
    if (index >= s.timers.len) return a.io_error_invalid;
    s.timers[index].cancel();
    return 0;
}
pub export fn R4SdkGuiSessionCommand(s: *S, id: u32) callconv(.c) i32 {
    const window = if (s.window) |*w| w else return a.err_no_fn;
    return if (window.events.postCommand(.{ .value = id })) 0 else a.service_api_result_busy;
}
pub export fn R4SdkGuiSessionMode(s: *S, action: u32, value: u32, out: *a.WindowModeReply) callconv(.c) i32 {
    const w = if (s.window) |*v| v else return a.err_no_fn;
    if (s.mode == null) {
        if (s.sys.programOpenHandle(s.instance_id, &s.owner) != a.program_handle_ok) return a.io_error_invalid;
        s.mode = .{ .owner = s.owner, .window_id = @intCast(w.id) };
    }
    const client = &s.mode.?;
    const ok = switch (action) {
        0 => client.poll(&s.sys),
        1 => if (value <= 1) client.set(&s.sys, @enumFromInt(value)) else false,
        2 => client.retry(&s.sys),
        else => return a.io_error_invalid,
    };
    out.* = client.state;
    return if (ok) client.last_error else if (client.last_error != 0) client.last_error else a.io_error_invalid;
}
fn closeEndpoint(s: *S) void {
    const handle = s.endpoint;
    s.endpoint = 0;
    if (handle != 0) _ = s.sys.serviceClose(handle);
}
pub export fn R4SdkGuiSessionHostReset(s: *S) callconv(.c) void {
    closeEndpoint(s);
    s.claimed = false;
    s.epoch = 0;
    // Closing this connection does not revoke the process's host binding.
}
pub export fn R4SdkGuiSessionHostExchange(s: *S, op: u16, request: *const a.TrayDesktopExchange, out: *a.TrayDesktopExchange, timeout: *const a.R4Timeout) callconv(.c) i32 {
    if (s.role != 1 or s.endpoint == 0 or !std.meta.eql(request.desktop_owner, s.owner)) return a.tray_result_not_owner;
    if (op != a.tray_service_op_desktop_sync and op != a.tray_service_op_desktop_activate and op != a.tray_service_op_desktop_visibility) return a.tray_result_bad_request;
    if (!s.claimed and op != a.tray_service_op_desktop_sync) return a.tray_result_not_owner;
    const ticks = s.sys.timeoutTicks(timeout.*) catch return a.io_error_invalid;
    const immutable = request.*;
    var header: a.ServiceMessageHeader = .{};
    out.* = .{};
    const rc = s.sys.serviceCall(s.endpoint, op, std.mem.asBytes(&immutable), &header, std.mem.asBytes(out), ticks);
    if (rc < 0 or header.status != 0) {
        closeEndpoint(s);
        return if (rc < 0) rc else header.status;
    }
    if (rc != @sizeOf(a.TrayDesktopExchange) or out.magic != a.tray_desktop_exchange_magic or out.version != a.tray_desktop_exchange_version or out.size != @sizeOf(a.TrayDesktopExchange) or !std.meta.eql(out.desktop_owner, s.owner) or out.capacity != (a.TrayDesktopExchange{}).capacity or out.registered_count > out.capacity) {
        closeEndpoint(s);
        return a.tray_result_bad_request;
    }
    if (out.result != 0) return out.result;
    if (out.desktop_epoch != s.owner.generation or (s.claimed and out.desktop_epoch != s.epoch)) {
        closeEndpoint(s);
        return a.tray_result_stale;
    }
    s.claimed = true;
    s.epoch = out.desktop_epoch;
    return 0;
}
pub export fn R4SdkGuiSessionHostClaim(s: *S, out: *a.TrayDesktopExchange, timeout: *const a.R4Timeout) callconv(.c) i32 {
    if (s.role != 1 or s.endpoint != 0) return a.io_error_invalid;
    if (s.sys.programOpenHandle(s.instance_id, &s.owner) != a.program_handle_ok or s.owner.instance_id != s.instance_id or s.owner.generation == 0 or s.owner.reserved != 0) return a.tray_result_not_owner;
    var info: a.ServiceInfo = .{};
    const rc = s.sys.serviceOpen(a.window_service_name, &info);
    if (rc != 0 or info.handle == 0) return if (rc != 0) rc else a.service_api_result_no_endpoint;
    s.endpoint = info.handle;
    s.claimed = false;
    s.epoch = 0;
    const request: a.TrayDesktopExchange = .{ .desktop_owner = s.owner };
    const result = R4SdkGuiSessionHostExchange(s, a.tray_service_op_desktop_sync, &request, out, timeout);
    if (result != 0) closeEndpoint(s);
    return result;
}
pub export fn R4SdkGuiSessionClose(s: *S) callconv(.c) void {
    if (s.paint) |*paint| paint.discard();
    s.paint = null;
    closeEndpoint(s);
}
