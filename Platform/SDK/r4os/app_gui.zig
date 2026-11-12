const desktop_actions = @import("desktop_actions.zig");
const abi = @import("r4os_contract").abi;
const gui = @import("gui.zig");
const r4desk = @import("r4desk.zig");
const r4draw = @import("r4draw.zig");
const r4sys = @import("r4sys.zig");
const time_contract = @import("time_contract.zig");

pub const Canvas = gui.Canvas;
pub const FrameCanvas = gui.FrameCanvas;
pub const FrameCanvasStats = gui.FrameCanvasStats;

pub const CommandId = struct {
    value: u32,

    pub fn init(value: u32) CommandId {
        return .{ .value = value };
    }
};

pub const TimerId = struct {
    value: u32,

    pub fn init(value: u32) TimerId {
        return .{ .value = value };
    }
};

pub const ResizeMessage = struct {
    window_id: i32,
    width: i32,
    height: i32,
    tick: u64,
};

pub const KeyMessage = struct {
    window_id: i32,
    key: u8,
    codepoint: u32,
    modifiers: u32,
    tick: u64,
};

pub const MouseAction = enum(u8) { down, up, move };

pub const MouseMessage = struct {
    window_id: i32,
    action: MouseAction,
    x: i32,
    y: i32,
    buttons: u32,
    modifiers: u32,
    tick: u64,
};

pub const ClipboardMessage = struct {
    revision: u32,
};

pub const TimerMessage = struct {
    id: TimerId,
    tick: u64,
};

pub const FocusMessage = struct {
    window_id: i32,
    tick: u64,
};

/// Notification only; the raw provider does not attach a font ID or revision.
pub const FontChangedMessage = struct {
    window_id: i32,
    tick: u64,
};

pub const WheelMessage = struct {
    window_id: i32,
    x: i32,
    y: i32,
    delta: i32,
    buttons: u32,
    modifiers: u32,
    tick: u64,
};
pub const RelativeMouseMessage = struct {
    window_id: i32,
    dx: i32,
    dy: i32,
    buttons: u32,
    source: u32,
    modifiers: u32,
    tick: u64,
};
pub const PointerCaptureMessage = struct {
    window_id: i32,
    state: u32,
    reason: u32,
    mode: u32,
    capture_id: u64,
    tick: u64,
};

pub const InputResetMessage = struct {
    window_id: i32,
    reason: u32,
    tick: u64,
};

pub const Message = union(enum) {
    close: i32,
    resize: ResizeMessage,
    key: KeyMessage,
    mouse: MouseMessage,
    command: CommandId,
    clipboard: ClipboardMessage,
    timer: TimerMessage,
    unknown: abi.GuiEvent,
    focus_gained: FocusMessage,
    focus_lost: FocusMessage,
    font_changed: FontChangedMessage,
    wheel: WheelMessage,
    relative: RelativeMouseMessage,
    pointer_capture: PointerCaptureMessage,
    input_reset: InputResetMessage,

    /// Bridge existing raw GUI handlers onto the shared event loop. Synthetic
    /// timer, clipboard and command messages remain explicit to the caller.
    pub fn guiEvent(self: Message) ?abi.GuiEvent {
        return switch (self) {
            .close => |id| .{ .kind = @intFromEnum(abi.GuiEventKind.close), .window_id = id },
            .resize => |value| .{ .kind = @intFromEnum(abi.GuiEventKind.resize), .window_id = value.window_id, .tick = value.tick },
            .key => |value| .{ .kind = @intFromEnum(abi.GuiEventKind.key_down), .window_id = value.window_id, .key = value.codepoint, .modifiers = value.modifiers, .tick = value.tick },
            .mouse => |value| .{ .kind = @intFromEnum(switch (value.action) {
                .down => abi.GuiEventKind.mouse_down,
                .up => abi.GuiEventKind.mouse_up,
                .move => abi.GuiEventKind.mouse_move,
            }), .window_id = value.window_id, .x = value.x, .y = value.y, .buttons = value.buttons, .modifiers = value.modifiers, .tick = value.tick },
            .wheel => |value| .{ .kind = @intFromEnum(abi.GuiEventKind.mouse_wheel), .window_id = value.window_id, .x = value.x, .y = value.y, .key = @bitCast(value.delta), .buttons = value.buttons, .modifiers = value.modifiers, .tick = value.tick },
            .relative => |value| .{ .kind = @intFromEnum(abi.GuiEventKind.mouse_relative), .window_id = value.window_id, .x = value.dx, .y = value.dy, .key = value.source, .buttons = value.buttons, .modifiers = value.modifiers, .tick = value.tick },
            .pointer_capture => |value| .{ .kind = @intFromEnum(abi.GuiEventKind.capture_changed), .window_id = value.window_id, .x = @intCast(value.state), .y = @intCast(value.reason), .key = @truncate(value.capture_id), .buttons = @truncate(value.capture_id >> 32), .modifiers = value.mode, .tick = value.tick },
            .input_reset => |value| .{ .kind = @intFromEnum(abi.GuiEventKind.input_reset), .window_id = value.window_id, .key = value.reason, .tick = value.tick },
            .unknown => |value| value,
            .focus_gained => |value| .{ .kind = @intFromEnum(abi.GuiEventKind.focus_gained), .window_id = value.window_id, .tick = value.tick },
            .focus_lost => |value| .{ .kind = @intFromEnum(abi.GuiEventKind.focus_lost), .window_id = value.window_id, .tick = value.tick },
            .font_changed => |value| .{ .kind = @intFromEnum(abi.GuiEventKind.font_changed), .window_id = value.window_id, .tick = value.tick },
            else => null,
        };
    }
};

pub const WaitResult = union(enum) {
    message: Message,
    timed_out,
    failure: i32,
};

pub const Timer = struct {
    id: TimerId = .{ .value = 0 },
    deadline_tick: u64 = 0,
    interval_ticks: u64 = 0,
    active: bool = false,

    pub fn start(self: *Timer, sys: *const r4sys.Context, id: TimerId, duration: time_contract.Duration, repeating: bool) bool {
        const ticks = if (sys.base.generation2 != null) blk: {
            if (!sys.hasFn("ticks")) return false;
            const sample = sys.base.clockSampleChecked() catch return false;
            break :blk time_contract.checked.durationToTicks(duration, sample.identity.tick_hz) catch return false;
        } else time_contract.durationToTicks(duration, sys.monotonicHz()) catch return false;
        const now = sys.ticks();
        const end = if (sys.base.generation2 != null) @import("std").math.add(u64, now, ticks) catch return false else now +| ticks;
        self.* = .{
            .id = id,
            .deadline_tick = end,
            .interval_ticks = if (repeating) @max(@as(u64, 1), ticks) else 0,
            .active = true,
        };
        return true;
    }

    pub fn cancel(self: *Timer) void {
        self.active = false;
    }

    fn takeIfDue(self: *Timer, now: u64) ?TimerMessage {
        if (!self.active or now < self.deadline_tick) return null;
        const result = TimerMessage{ .id = self.id, .tick = now };
        if (self.interval_ticks == 0) {
            self.active = false;
        } else {
            const elapsed = now - self.deadline_tick;
            const periods = elapsed / self.interval_ticks +| 1;
            self.deadline_tick +|= periods *| self.interval_ticks;
        }
        return result;
    }
};

pub const EventLoop = struct {
    sys: r4sys.Context,
    desk: r4desk.Context,
    timers: []Timer,
    activity_sequence: u64 = 0,
    subscriptions: u32 = abi.gui_activity_shared_clipboard,
    clipboard_revision: u32 = 0,
    pending_command: ?CommandId = null,
    close_delivered: bool = false,
    action_view_pending: bool = false,

    pub fn init(sys: r4sys.Context, desk: r4desk.Context, timers: []Timer) EventLoop {
        return .{
            .sys = sys,
            .desk = desk,
            .timers = timers,
            .clipboard_revision = if (desk.hasFn("clipboard_revision")) desk.clipboardRevision() else 0,
        };
    }

    pub fn postCommand(self: *EventLoop, command: CommandId) bool {
        if (self.pending_command != null) return false;
        self.pending_command = command;
        return true;
    }

    pub fn poll(self: *EventLoop) ?Message {
        var raw: abi.GuiEvent = .{};
        if (self.desk.guiPollEvent(&raw) > 0) {
            if (raw.kind == @intFromEnum(abi.GuiEventKind.close)) self.close_delivered = true;
            return self.translate(raw);
        }
        if (self.pending_command) |command| {
            self.pending_command = null;
            return .{ .command = command };
        }
        if (self.subscriptions & abi.gui_activity_shared_clipboard != 0 and self.desk.hasFn("clipboard_revision")) {
            const revision = self.desk.clipboardRevision();
            if (revision != self.clipboard_revision) {
                self.clipboard_revision = revision;
                return .{ .clipboard = .{ .revision = revision } };
            }
        }
        const now = self.sys.ticks();
        for (self.timers) |*timer| {
            if (timer.takeIfDue(now)) |message| return .{ .timer = message };
        }
        // An editor can keep running to resolve a Save dialog. A persistent
        // lifecycle flag must not turn that dialog into a busy close loop.
        if (self.takeClose(self.sys.programShouldClose())) return .{ .close = self.desk.programWindowId() };
        return null;
    }

    fn takeClose(self: *EventLoop, requested: bool) bool {
        if (!requested) {
            self.close_delivered = false;
            return false;
        }
        if (self.close_delivered) return false;
        self.close_delivered = true;
        return true;
    }

    pub fn wait(self: *EventLoop, timeout: time_contract.Timeout) WaitResult {
        if (!self.desk.hasFn("gui_activity_wait")) return .{ .failure = abi.err_no_fn };
        if (self.sys.base.generation2 != null) return self.wait2(timeout);
        const timeout_ticks = time_contract.timeoutToTicks(timeout, self.sys.monotonicHz()) catch return .{ .failure = abi.remote_frame_error_invalid };
        const started = self.sys.ticks();
        const deadline: ?u64 = if (timeout.kind == abi.timeout_kind_forever) null else started +| timeout_ticks;
        while (true) {
            if (self.poll()) |message| return .{ .message = message };
            const now = self.sys.ticks();
            var remaining = if (deadline) |end| if (now >= end) @as(u64, 0) else end - now else abi.io_wait_forever;
            if (remaining == 0) return .timed_out;
            if (self.nextTimerDelay(now)) |timer_delay| remaining = @min(remaining, timer_delay);
            if (remaining == 0) continue;
            var sequence = self.activity_sequence;
            const raw = self.desk.guiActivityWait(self.activity_sequence, remaining, self.subscriptions, &sequence);
            self.activity_sequence = sequence;
            if (raw < 0) return .{ .failure = raw };
        }
    }

    fn wait2(self: *EventLoop, timeout: time_contract.Timeout) WaitResult {
        const checked = time_contract.checked;
        const kind = checked.fromTimeout(timeout) catch |err| return .{ .failure = checked.failure(err) };
        var deadline: ?checked.DeadlineBudget = null;
        if (kind.kind == @intFromEnum(checked.Kind.finite)) {
            const sample = self.sys.base.clockSampleChecked() catch |err| return .{ .failure = checked.failure(err) };
            deadline = checked.DeadlineBudget.init(sample, timeout) catch |err| return .{ .failure = checked.failure(err) };
        }
        while (true) {
            if (self.poll()) |message| return .{ .message = message };
            var remaining: u64 = if (kind.kind == @intFromEnum(checked.Kind.forever)) abi.io_wait_forever else 0;
            if (deadline) |*budget| {
                const sample = self.sys.base.clockSampleChecked() catch |err| return .{ .failure = checked.failure(err) };
                var value = budget.remaining(sample) catch |err| return .{ .failure = checked.failure(err) };
                if (value.kind == @intFromEnum(checked.Kind.finite)) value.value = checked.durationToTicks(.{ .nanoseconds = value.value }, sample.identity.tick_hz) catch |err| return .{ .failure = checked.failure(err) };
                remaining = checked.toWaitTicks(value) catch |err| return .{ .failure = checked.failure(err) };
            }
            if (remaining == 0) return .timed_out;
            if (self.nextTimerDelay(self.sys.ticks())) |delay| remaining = @min(remaining, delay);
            if (remaining == 0) continue;
            var sequence = self.activity_sequence;
            const raw = self.desk.guiActivityWait(self.activity_sequence, remaining, self.subscriptions, &sequence);
            self.activity_sequence = sequence;
            if (raw < 0) return .{ .failure = raw };
        }
    }

    fn translate(self: *EventLoop, raw: abi.GuiEvent) Message {
        return switch (raw.kind) {
            @intFromEnum(abi.GuiEventKind.close) => .{ .close = raw.window_id },
            @intFromEnum(abi.GuiEventKind.resize) => blk: {
                if (raw.key == abi.gui_resize_action_view_key) self.action_view_pending = true;
                var info: abi.GuiWindowInfo = .{};
                const result = self.desk.guiWindowInfo(&info);
                break :blk if (result < 0)
                    .{ .unknown = raw }
                else
                    .{ .resize = .{ .window_id = raw.window_id, .width = info.client_w, .height = info.client_h, .tick = raw.tick } };
            },
            @intFromEnum(abi.GuiEventKind.key_down) => .{ .key = .{ .window_id = raw.window_id, .key = @truncate(raw.key), .codepoint = raw.key, .modifiers = raw.modifiers, .tick = raw.tick } },
            @intFromEnum(abi.GuiEventKind.mouse_down) => .{ .mouse = mouseMessage(raw, .down) },
            @intFromEnum(abi.GuiEventKind.mouse_up) => .{ .mouse = mouseMessage(raw, .up) },
            @intFromEnum(abi.GuiEventKind.mouse_move) => .{ .mouse = mouseMessage(raw, .move) },
            @intFromEnum(abi.GuiEventKind.mouse_wheel) => .{ .wheel = .{ .window_id = raw.window_id, .x = raw.x, .y = raw.y, .delta = @bitCast(raw.key), .buttons = raw.buttons, .modifiers = raw.modifiers, .tick = raw.tick } },
            @intFromEnum(abi.GuiEventKind.mouse_relative) => .{ .relative = .{ .window_id = raw.window_id, .dx = raw.x, .dy = raw.y, .buttons = raw.buttons, .source = raw.key, .modifiers = raw.modifiers, .tick = raw.tick } },
            @intFromEnum(abi.GuiEventKind.capture_changed) => .{ .pointer_capture = .{ .window_id = raw.window_id, .state = @bitCast(raw.x), .reason = @bitCast(raw.y), .mode = raw.modifiers, .capture_id = @as(u64, raw.key) | (@as(u64, raw.buttons) << 32), .tick = raw.tick } },
            @intFromEnum(abi.GuiEventKind.input_reset) => .{ .input_reset = .{ .window_id = raw.window_id, .reason = raw.key, .tick = raw.tick } },
            @intFromEnum(abi.GuiEventKind.focus_gained) => .{ .focus_gained = .{ .window_id = raw.window_id, .tick = raw.tick } },
            @intFromEnum(abi.GuiEventKind.focus_lost) => .{ .focus_lost = .{ .window_id = raw.window_id, .tick = raw.tick } },
            @intFromEnum(abi.GuiEventKind.font_changed) => .{ .font_changed = .{ .window_id = raw.window_id, .tick = raw.tick } },
            else => .{ .unknown = raw },
        };
    }

    fn nextTimerDelay(self: *const EventLoop, now: u64) ?u64 {
        var result: ?u64 = null;
        for (self.timers) |timer| {
            if (!timer.active) continue;
            const delay = if (now >= timer.deadline_tick) @as(u64, 0) else timer.deadline_tick - now;
            result = if (result) |current| @min(current, delay) else delay;
        }
        return result;
    }
};

pub const PaintOpen = union(enum) {
    paint: PaintContext,
    failure: i32,
};

const ActionPaintView = struct { token: abi.DesktopActionToken, revision: u64, width: i32, height: i32 };
pub const PaintContext = struct {
    canvas: Canvas,
    active: bool = true,
    transactional: bool = false,
    frame_canvas: ?*FrameCanvas = null,
    action_view: ?ActionPaintView = null,

    /// Attaches caller-owned bounded command/resource storage to this paint.
    /// The returned Canvas can be passed through all existing widget helpers.
    pub fn bufferedCanvas(self: *PaintContext, builder: *FrameCanvas, commands: []abi.GuiFrameCommand, resources: []u8) Canvas {
        if (self.frame_canvas) |previous| previous.cancel();
        builder.* = FrameCanvas.init(self.canvas.ctx, commands, resources, self.transactional);
        if (!self.active) builder.cancel();
        self.frame_canvas = builder;
        return builder.bind(self.canvas);
    }

    pub fn present(self: *PaintContext) i32 {
        if (!self.active) return abi.err_no_fn;
        if (self.frame_canvas) |builder| {
            const flushed = builder.finish();
            if (flushed < 0) {
                if (self.transactional) _ = self.canvas.ctx.guiFrameCancel();
                builder.cancel();
                self.active = false;
                return flushed;
            }
        }
        const raw = if (self.transactional) self.canvas.ctx.guiFrameCommit() else self.canvas.present();
        if (raw >= 0) {
            self.active = false;
            if (self.frame_canvas) |builder| builder.complete();
            if (self.transactional) if (self.action_view) |view| {
                var frame: abi.GuiFrameInfo = .{};
                if (self.canvas.ctx.guiFrameInfo(&view.token.window.owner, &frame) == 0) {
                    const client = desktop_actions.Client{ .sys = r4sys.Context.fromProgram(self.canvas.ctx.base) };
                    _ = client.appFrame(view.token, view.revision, frame.committed_generation, view.width, view.height);
                }
            };
        } else if (self.transactional) {
            _ = self.canvas.ctx.guiFrameCancel();
            self.active = false;
            if (self.frame_canvas) |builder| builder.cancel();
        }
        return raw;
    }

    pub fn discard(self: *PaintContext) void {
        if (self.active and self.transactional) _ = self.canvas.ctx.guiFrameCancel();
        if (self.frame_canvas) |builder| builder.cancel();
        self.active = false;
    }
};

/// Begins one complete GUI frame for applications that own their window loop
/// directly. The current six-callback frame contract is required; no
/// automatic legacy paint/present transaction is synthesized.
pub fn beginPaintForSize(draw: *const r4draw.Context, width: i32, height: i32) PaintOpen {
    if (width <= 0 or height <= 0 or !draw.supportsGuiFrameContract()) return .{ .failure = abi.err_no_fn };
    const raw = draw.guiFrameBegin();
    if (raw < 0) return .{ .failure = raw };
    return .{ .paint = .{ .canvas = Canvas.initSize(draw, width, height), .transactional = true } };
}

/// A complete independent replacement with damage in client coordinates.
/// The caller still draws the complete scene; regions only limit replay.
pub fn beginPaintReplaceForSize(draw: *const r4draw.Context, width: i32, height: i32, regions: []const abi.DisplayDamageRect) PaintOpen {
    if (width <= 0 or height <= 0 or !draw.supportsGuiFrameContract() or !draw.hasFn("gui_frame_begin_replace")) return .{ .failure = abi.err_no_fn };
    if (regions.len == 0 or regions.len > abi.gui_frame_max_damage_regions) return .{ .failure = abi.gui_frame_error_invalid };
    for (regions) |region| {
        if (region.x < 0 or region.y < 0 or region.w == 0 or region.h == 0 or
            @as(i64, region.x) + region.w > width or @as(i64, region.y) + region.h > height)
            return .{ .failure = abi.gui_frame_error_invalid };
    }
    const raw = draw.guiFrameBeginReplace(regions);
    if (raw < 0) return .{ .failure = raw };
    return .{ .paint = .{ .canvas = Canvas.initSize(draw, width, height), .transactional = true } };
}

pub const Window = struct {
    sys: r4sys.Context,
    desk: r4desk.Context,
    draw: r4draw.Context,
    id: i32,
    events: EventLoop,

    pub fn init(sys: r4sys.Context, desk: r4desk.Context, draw: r4draw.Context, timers: []Timer) ?Window {
        if (!desk.hasFn("program_window_id") or !desk.hasFn("gui_window_info") or
            !desk.hasFn("gui_poll_event") or !desk.hasFn("gui_activity_wait") or
            !draw.hasFn("gui_clear") or !draw.hasFn("gui_rect") or
            !draw.hasFn("gui_draw_text") or !draw.hasFn("gui_present")) return null;
        const id = desk.programWindowId();
        if (id < 0) return null;
        return .{ .sys = sys, .desk = desk, .draw = draw, .id = id, .events = EventLoop.init(sys, desk, timers) };
    }

    pub fn pointerIdentity(self: *Window, out: *abi.GuiPointerWindowIdentity) i32 {
        var value: abi.GuiPointerCaptureInfo = .{};
        const rc = self.desk.guiPointerCaptureInfo(null, &value);
        if (rc != 0) return rc;
        if (value.capture.window.window_id != self.id or value.capture.window.epoch == 0) return abi.gui_pointer_error_unavailable;
        out.* = value.capture.window;
        return 0;
    }
    /// Zero accepts PENDING; process pointer_capture/ACTIVE before mouse-look.
    pub fn pointerCapture(self: *Window, identity: *const abi.GuiPointerWindowIdentity, mode: u32, out: *abi.GuiPointerCaptureHandle) i32 {
        if (identity.window_id != self.id) return abi.gui_pointer_error_stale;
        return self.desk.guiPointerCaptureAcquire(identity, mode, out);
    }
    pub fn pointerStatus(self: *Window, capture: *const abi.GuiPointerCaptureHandle, out: *abi.GuiPointerCaptureInfo) i32 {
        return self.desk.guiPointerCaptureInfo(capture, out);
    }
    pub fn pointerRelease(self: *Window, capture: *const abi.GuiPointerCaptureHandle) i32 {
        return self.desk.guiPointerCaptureRelease(capture);
    }

    pub fn setTitle(self: *Window, title: [*:0]const u8) i32 {
        return self.desk.guiSetTitle(title);
    }

    pub fn setMinimumSize(self: *Window, width: i32, height: i32) i32 {
        return self.desk.guiSetMinSize(width, height);
    }

    pub fn info(self: *Window) ?abi.GuiWindowInfo {
        var value: abi.GuiWindowInfo = .{};
        if (self.desk.guiWindowInfo(&value) < 0) return null;
        return value;
    }

    pub fn beginPaint(self: *Window) PaintOpen {
        return self.beginPaintInternal(0, 0, null);
    }

    /// A size or coordinated view change promotes this to a full frame.
    pub fn beginPaintReplace(self: *Window, expected_width: i32, expected_height: i32, regions: []const abi.DisplayDamageRect) PaintOpen {
        return self.beginPaintInternal(expected_width, expected_height, regions);
    }

    fn beginPaintInternal(self: *Window, expected_width: i32, expected_height: i32, regions: ?[]const abi.DisplayDamageRect) PaintOpen {
        var value = self.info() orelse return .{ .failure = abi.err_no_fn };
        if (value.client_w <= 0 or value.client_h <= 0) return .{ .failure = abi.err_no_fn };
        var view: ?ActionPaintView = null;
        const changed_view = self.events.action_view_pending;
        if (self.events.action_view_pending) {
            self.events.action_view_pending = false;
            const client = desktop_actions.Client{ .sys = self.sys };
            const reply = client.appView(self.id);
            if (reply == .reply and reply.reply.result == 0 and reply.reply.current.view_revision != 0) {
                if (self.info()) |current| {
                    value = current;
                    if (current.client_x == reply.reply.current.info.client_x and current.client_y == reply.reply.current.info.client_y and
                        current.client_w == reply.reply.current.info.client_w and current.client_h == reply.reply.current.info.client_h and
                        current.flags == reply.reply.current.info.flags)
                    {
                        view = .{ .token = reply.reply.request.token, .revision = reply.reply.current.view_revision, .width = current.client_w, .height = current.client_h };
                    }
                }
            }
        }
        var opened = if (regions != null and !changed_view and value.client_w == expected_width and value.client_h == expected_height)
            beginPaintReplaceForSize(&self.draw, value.client_w, value.client_h, regions.?)
        else
            beginPaintForSize(&self.draw, value.client_w, value.client_h);
        if (opened == .paint) opened.paint.action_view = view;
        return opened;
    }

    pub fn pollMessage(self: *Window) ?Message {
        return self.events.poll();
    }

    pub fn waitMessage(self: *Window, timeout: time_contract.Timeout) WaitResult {
        return self.events.wait(timeout);
    }
};

fn mouseMessage(raw: abi.GuiEvent, action: MouseAction) MouseMessage {
    return .{
        .window_id = raw.window_id,
        .action = action,
        .x = raw.x,
        .y = raw.y,
        .buttons = raw.buttons,
        .modifiers = raw.modifiers,
        .tick = raw.tick,
    };
}

test "GUI compatibility messages preserve input and close dialogs do not spin" {
    const std = @import("std");
    var loop = EventLoop{ .sys = undefined, .desk = undefined, .timers = &.{} };
    const input = abi.GuiEvent{ .kind = @intFromEnum(abi.GuiEventKind.key_down), .window_id = 3, .key = 0x10437, .modifiers = 7, .tick = 123 };
    const key = loop.translate(input).guiEvent().?;
    try std.testing.expectEqual(input.key, key.key);
    try std.testing.expectEqual(input.modifiers, key.modifiers);
    try std.testing.expectEqual(input.tick, key.tick);
    const mouse = abi.GuiEvent{ .kind = @intFromEnum(abi.GuiEventKind.mouse_up), .window_id = 2, .x = -4, .y = 20, .buttons = 2, .modifiers = 1, .tick = 400 };
    try std.testing.expectEqualDeep(mouse, loop.translate(mouse).guiEvent().?);
    try std.testing.expect(loop.takeClose(true));
    for (0..100) |_| try std.testing.expect(!loop.takeClose(true));
    try std.testing.expect(!loop.takeClose(false));
    try std.testing.expect(loop.takeClose(true));
    var timer = Timer{ .id = .{ .value = 1 }, .deadline_tick = 100, .interval_ticks = 100, .active = true };
    try std.testing.expect(timer.takeIfDue(99) == null);
    try std.testing.expectEqual(@as(u64, 100), timer.takeIfDue(100).?.tick);
    try std.testing.expectEqual(@as(u64, 200), timer.deadline_tick);
    _ = timer.takeIfDue(451);
    try std.testing.expectEqual(@as(u64, 500), timer.deadline_tick);
    timer.cancel();
    try std.testing.expect(timer.takeIfDue(1000) == null);
}
