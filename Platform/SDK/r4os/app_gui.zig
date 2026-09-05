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

pub const Message = union(enum) {
    close: i32,
    resize: ResizeMessage,
    key: KeyMessage,
    mouse: MouseMessage,
    command: CommandId,
    clipboard: ClipboardMessage,
    timer: TimerMessage,
    unknown: abi.GuiEvent,
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
        const ticks = time_contract.durationToTicks(duration, sys.monotonicHz()) catch return false;
        self.* = .{
            .id = id,
            .deadline_tick = sys.ticks() +| ticks,
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
    clipboard_revision: u32 = 0,
    pending_command: ?CommandId = null,

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
        if (self.desk.guiPollEvent(&raw) > 0) return self.translate(raw);
        if (self.pending_command) |command| {
            self.pending_command = null;
            return .{ .command = command };
        }
        if (self.desk.hasFn("clipboard_revision")) {
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
        if (self.sys.programShouldClose()) return .{ .close = self.desk.programWindowId() };
        return null;
    }

    pub fn wait(self: *EventLoop, timeout: time_contract.Timeout) WaitResult {
        if (!self.desk.hasFn("desktop_activity_wait")) return .{ .failure = abi.err_no_fn };
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
            const raw = self.desk.desktopActivityWait(self.activity_sequence, remaining, &sequence);
            self.activity_sequence = sequence;
            if (raw < 0) return .{ .failure = raw };
        }
    }

    fn translate(self: *EventLoop, raw: abi.GuiEvent) Message {
        return switch (raw.kind) {
            @intFromEnum(abi.GuiEventKind.close) => .{ .close = raw.window_id },
            @intFromEnum(abi.GuiEventKind.resize) => blk: {
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

pub const PaintContext = struct {
    canvas: Canvas,
    active: bool = true,
    transactional: bool = false,
    frame_canvas: ?*FrameCanvas = null,

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
/// directly.  Older R4DRAW tables retain the legacy present path; current
/// tables always publish or discard one explicit dynamic frame.
pub fn beginPaintForSize(draw: *const r4draw.Context, width: i32, height: i32) PaintOpen {
    if (width <= 0 or height <= 0) return .{ .failure = abi.err_no_fn };
    const transactional = draw.supportsGuiFrameContract();
    if (transactional) {
        const raw = draw.guiFrameBegin();
        if (raw < 0) return .{ .failure = raw };
    }
    return .{ .paint = .{ .canvas = Canvas.initSize(draw, width, height), .transactional = transactional } };
}

pub const Window = struct {
    sys: r4sys.Context,
    desk: r4desk.Context,
    draw: r4draw.Context,
    id: i32,
    events: EventLoop,

    pub fn init(sys: r4sys.Context, desk: r4desk.Context, draw: r4draw.Context, timers: []Timer) ?Window {
        if (!desk.hasFn("program_window_id") or !desk.hasFn("gui_window_info") or
            !desk.hasFn("gui_poll_event") or !desk.hasFn("desktop_activity_wait") or
            !draw.hasFn("gui_clear") or !draw.hasFn("gui_rect") or
            !draw.hasFn("gui_draw_text") or !draw.hasFn("gui_present")) return null;
        const id = desk.programWindowId();
        if (id < 0) return null;
        return .{ .sys = sys, .desk = desk, .draw = draw, .id = id, .events = EventLoop.init(sys, desk, timers) };
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
        const value = self.info() orelse return .{ .failure = abi.err_no_fn };
        if (value.client_w <= 0 or value.client_h <= 0) return .{ .failure = abi.err_no_fn };
        return beginPaintForSize(&self.draw, value.client_w, value.client_h);
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
