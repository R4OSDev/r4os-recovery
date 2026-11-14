//! Ordinary native SDK controls. No framebuffer, browser, private input or theme.
const std = @import("std");
const r = @import("r4os");
const g = r.gui;
const tabs = [_]g.TabItem{ .{ .text = "Entdecken" }, .{ .text = "Meine Software" }, .{ .text = "Updates" } };
const focus_items = [_]g.FocusItem{ .{}, .{}, .{}, .{}, .{}, .{ .enabled = false } };
const buttons = [_]g.DialogButton{ .{ .text = "OK", .action = .ok, .role = .default }, .{ .text = "Abbrechen", .action = .cancel, .role = .cancel } };

const Demo = struct {
    window: *r.Window,
    style: g.Style,
    dark: bool = false,
    active: bool = false,
    focus: g.FocusState = .{ .index = 1 },
    field: g.TextField(192) = .{},
    capture: g.MouseCapture = .{},
    native_capture: r.abi.GuiPointerCaptureHandle = .{},
    hover: ?usize = null,
    navigation: usize = 0,
    selected_card: usize = 0,
    actions: u32 = 0,
    dialog: bool = false,
    dialog_state: g.DialogState = .{},
    dirty: bool = true,

    fn layoutCanvas(self: *Demo) g.Canvas {
        var info: r.abi.GuiWindowInfo = .{};
        _ = self.window.desk.guiWindowInfo(&info);
        return g.Canvas.init(&self.window.draw, info).withStyle(self.style);
    }
    fn nav(self: *Demo, canvas: g.Canvas) g.TabBar {
        return canvas.layoutTabs(.{ .rect = .{ .x = 22, .y = 58, .w = canvas.w - 44, .h = 34 }, .items = &tabs, .selected_index = self.navigation, .focused = self.active and self.focus.index == 0 });
    }
    fn search(_: *Demo) g.Rect {
        return .{ .x = 24, .y = 106, .w = 350, .h = 34 };
    }
    fn button(self: *Demo, index: usize) g.Button {
        return .{ .rect = .{ .x = 24 + @as(i32, @intCast(index)) * 144, .y = 156, .w = 132, .h = 34 }, .text = ([_][]const u8{ "Aktion", "Hell / Dunkel", "Dialog", "Deaktiviert" })[index], .state = if (index == 3) .disabled else if (self.capture.isActive(index)) .pressed else if (self.hover == index) .hover else .normal, .focused = self.active and self.focus.index == index + 2, .is_default = index == 0 };
    }
    fn gridLayout(_: *Demo, canvas: g.Canvas) g.TileGrid {
        return .{ .rect = .{ .x = 24, .y = 216, .w = canvas.w - 48, .h = 96 }, .row_height = 96, .count = 2 };
    }
    fn modal(self: *Demo, canvas: g.Canvas) g.ModalDialog {
        var result = g.ModalDialog.centered(canvas.bounds(), 420, 220, "Native SDK-Dialog");
        result.focus_action = if (self.active) self.dialog_state.focus_action else .none;
        result.pressed_action = self.dialog_state.pressed_action;
        return result;
    }
    fn release(self: *Demo) void {
        self.capture.clear();
        if (self.native_capture.id != 0) _ = self.window.pointerRelease(&self.native_capture);
        self.native_capture = .{};
        self.dialog_state.pressed_action = .none;
    }
    fn acquire(self: *Demo) bool {
        var identity: r.abi.GuiPointerWindowIdentity = .{};
        return self.window.pointerIdentity(&identity) == 0 and self.window.pointerCapture(&identity, r.abi.gui_pointer_mode_drag, &self.native_capture) == 0;
    }
    fn action(self: *Demo, index: usize) void {
        self.release();
        switch (index) {
            0 => self.actions +|= 1,
            1 => {
                self.dark = !self.dark;
                self.style = (if (self.dark) g.Style.dark() else g.Style.light()).withSystemFonts(&self.window.draw);
            },
            2 => {
                self.dialog = true;
                self.dialog_state = .{ .focus_action = .ok };
            },
            else => {},
        }
        self.dirty = true;
    }
    fn paint(self: *Demo) bool {
        var painting = switch (self.window.beginPaint()) {
            .paint => |value| value,
            .failure => return false,
        };
        defer painting.discard();
        var commands: [96]r.abi.GuiFrameCommand = undefined;
        var resources: [8192]u8 = undefined;
        var builder: r.app_gui.FrameCanvas = undefined;
        const canvas = painting.bufferedCanvas(&builder, &commands, &resources).withStyle(self.style);
        var scratch: [512]u8 = undefined;
        if (canvas.clear(self.style.background) < 0) return false;
        if (canvas.withTextRole(.heading).label(.{ .rect = .{ .x = 24, .y = 14, .w = canvas.w - 48, .h = 38 }, .text = "Gemeinsame native Controls", .fg = self.style.text, .bg = self.style.background }, &scratch) < 0) return false;
        if (self.nav(canvas).draw(canvas, &scratch) < 0) return false;
        self.field.focused = self.active and self.focus.index == 1;
        if (self.field.draw(canvas, self.search(), &scratch) < 0) return false;
        for (0..4) |index| if (self.button(index).draw(canvas, &scratch) < 0) return false;
        const grid = self.gridLayout(canvas);
        for (0..2) |index| {
            const card = g.Card{ .rect = grid.itemRect(index), .title = if (index == 0) "Native SDK-Karte" else "Text, Auswahl und Fokus", .subtitle = if (index == 0) "Gemeinsame Zig-/C-/Rust-Bausteine" else self.field.value(), .selected = self.selected_card == index, .focused = false, .icon_width = 32 };
            if (card.draw(canvas, &scratch) < 0) return false;
            const icon = card.iconRect(self.style);
            if (canvas.surface(icon, .selected) < 0 or canvas.label(.{ .rect = icon, .text = if (index == 0) "+" else "A", .alignment = .center, .fg = self.style.accent, .bg = self.style.tint }, &scratch) < 0) return false;
        }
        // Ordinary public gradients layered with existing borders and shadows.
        const box = g.Rect{ .x = 24, .y = 334, .w = canvas.w - 48, .h = @max(28, canvas.h - 426) };
        const stops = [_]r.gui_shapes.GradientStop{ .{ .position = 0, .argb = 0xff30223f }, .{ .position = 1, .argb = 0xffa47bdd } };
        var payload: [256]u8 = undefined;
        const shape = r.gui_shapes.RoundedRect{ .x = 2, .y = 2, .w = @floatFromInt(box.w - 4), .h = @floatFromInt(box.h - 4), .radii = .{ .top_left_x = 10, .top_left_y = 10, .top_right_x = 10, .top_right_y = 10, .bottom_left_x = 10, .bottom_left_y = 10, .bottom_right_x = 10, .bottom_right_y = 10 }, .borders = .{ .top = 1, .left = 1, .right = 1, .bottom = 1 }, .border_argb = 0xffb492ef, .shadow = .{ .argb = 0x50000000, .offset_y = 2, .blur = 2 } };
        const shadow = r.gui_shapes.roundedRect(&payload, shape) catch return false;
        const shadow_command = r.gui_shapes.command(r.abi.gui_frame_command_kind_shadow, box.x, box.y, @intCast(box.w), @intCast(box.h), 0, shadow.len) catch return false;
        if (canvas.frameCommand(shadow_command, shadow) < 0) return false;
        const gradient = r.gui_shapes.gradientRoundedRect(&payload, shape, .{ .start = .{ .x = 0, .y = 0 }, .end = .{ .x = @floatFromInt(box.w), .y = @floatFromInt(box.h) }, .stops = &stops }) catch return false;
        const command = r.gui_shapes.command(r.abi.gui_frame_command_kind_gradient_rounded_rect, box.x, box.y, @intCast(box.w), @intCast(box.h), 0, gradient.len) catch return false;
        if (canvas.frameCommand(command, gradient) < 0) return false;
        if (canvas.progressBar(.{ .x = 24, .y = canvas.h - 64, .w = canvas.w - 48, .h = 12 }, self.actions % 5, 4, 0, false) < 0) return false;
        const status = std.fmt.bufPrint(&scratch, "Aktionen: {d} | Tab, Pfeile, Enter; Suche mit Unicode/Clipboard.", .{self.actions}) catch return false;
        var status_scratch: [512]u8 = undefined;
        if (canvas.label(.{ .rect = .{ .x = 24, .y = canvas.h - 40, .w = canvas.w - 48, .h = 28 }, .text = status, .fg = self.style.muted, .bg = self.style.background }, &status_scratch) < 0) return false;
        if (self.dialog) {
            const dialog = self.modal(canvas);
            if (dialog.drawFrame(canvas, &scratch) < 0 or canvas.paragraph(.{ .rect = dialog.contentRect(), .text = "Dieser Dialog nutzt dieselben SDK-Controls und die bestehende Dialog-Eingabelogik.", .background = self.style.surface }, &scratch) < 0 or dialog.drawButtons(canvas, &scratch, &buttons, .right) < 0) return false;
        }
        return painting.present() >= 0;
    }
    fn key(self: *Demo, message: r.app_gui.KeyMessage) void {
        if (self.dialog) {
            const items = [_]g.DialogFocusItem{ .{ .action = .ok }, .{ .action = .cancel } };
            const action_value = self.dialog_state.keyAction(&items, &buttons, message.key);
            if (action_value == .ok or action_value == .cancel) self.dialog = false;
        } else if (message.key == g.Key.tab or message.key == g.Key.shift_tab) {
            _ = self.focus.handleKey(&focus_items, message.key);
        } else if (self.focus.index == 0) {
            const step = self.nav(self.layoutCanvas()).keyAction(message.key);
            self.navigation = step.index;
        } else if (self.focus.index == 1) {
            _ = self.field.handleClipboardCodepoint(&self.window.desk, if (message.codepoint == 0) message.key else message.codepoint);
        } else if (message.key == g.Key.enter or message.key == ' ') self.action(self.focus.index - 2);
        self.dirty = true;
    }
    fn mouse(self: *Demo, message: r.app_gui.MouseMessage) void {
        const canvas = self.layoutCanvas();
        const x = message.x;
        const y = message.y;
        if (self.dialog) {
            const dialog = self.modal(canvas);
            if (message.action == .down and (message.buttons & 1) != 0) {
                _ = self.dialog_state.mouseDown(dialog, &buttons, .right, x, y);
                if (!self.acquire()) self.release();
            } else if (message.action == .up) {
                const event = self.dialog_state.mouseUp(dialog, &buttons, .right, x, y);
                self.release();
                if (event.action == .ok or event.action == .cancel) self.dialog = false;
            }
        } else switch (message.action) {
            .move => {
                self.hover = null;
                for (0..3) |i| if (self.button(i).contains(x, y)) {
                    self.hover = i;
                    break;
                };
            },
            .down => {
                if ((message.buttons & 1) == 0) return;
                if (self.nav(canvas).indexAt(x, y)) |index| {
                    self.navigation = index;
                    self.focus.index = 0;
                } else if (self.search().contains(x, y)) {
                    self.focus.index = 1;
                    self.field.cursor = canvas.textIndexAt(self.field.value(), x - self.search().x - g.default_metrics.text_pad_x);
                    self.field.clearSelection();
                } else if (self.gridLayout(canvas).indexAt(x, y)) |index| self.selected_card = index else for (0..3) |i| if (self.button(i).contains(x, y)) {
                    self.focus.index = i + 2;
                    if (self.acquire()) self.capture.begin(i, .submitted);
                    break;
                };
            },
            .up => {
                if (self.capture.target) |target| {
                    const action_value = self.capture.release(target, self.button(target).contains(x, y));
                    self.release();
                    if (action_value == .submitted) self.action(target);
                }
            },
        }
        self.dirty = true;
    }
};

pub fn r4_app_main(app: *r.App2) i32 {
    var timers: [0]r.Timer = .{};
    var window = r.Window.init(app.system(), app.desktop() orelse return -1, app.drawing() orelse return -1, &timers) orelse return -1;
    _ = window.setTitle("Modern SDK example");
    _ = window.setMinimumSize(680, 480);
    var demo = Demo{ .window = &window, .style = g.Style.light().withSystemFonts(&window.draw) };
    defer demo.release();
    // Initial focus may precede the app loop. Read only our actual router
    // snapshot; later ordered loss/gain events remain the ordinary path.
    const client = r.desktop_actions.Client{ .sys = window.sys };
    switch (client.focusSnapshot(.{ .window_id = @intCast(window.id) })) {
        .reply => |reply| if (reply.result == 0) {
            demo.active = reply.snapshot.focus_state == r.abi.desktop_focus_state_focused;
        },
        .failure => {},
    }
    if (!demo.field.setExact("Suche: R4OS")) return -1;
    while (true) {
        if (demo.dirty) {
            if (!demo.paint()) return -2;
            demo.dirty = false;
        }
        switch (window.waitMessage(.{ .kind = r.abi.timeout_kind_forever })) {
            .message => |message| switch (message) {
                .close => return 0,
                .resize => {
                    demo.release();
                    demo.dirty = true;
                },
                .font_changed => {
                    demo.style = demo.style.withSystemFonts(&window.draw);
                    demo.dirty = true;
                },
                .key => |value| demo.key(value),
                .mouse => |value| demo.mouse(value),
                .focus_gained => {
                    demo.active = true;
                    demo.dirty = true;
                },
                .focus_lost => {
                    demo.active = false;
                    demo.release();
                    demo.dirty = true;
                },
                .input_reset => {
                    demo.release();
                    demo.dirty = true;
                },
                .pointer_capture => |value| {
                    if (value.state == r.abi.gui_pointer_state_cancelled) demo.release();
                    demo.dirty = true;
                },
                else => {},
            },
            .timed_out => {},
            .failure => return -1,
        }
    }
}
