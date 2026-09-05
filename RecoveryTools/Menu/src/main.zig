const std = @import("std");
const r4os = @import("r4os");
const view = @import("view.zig");
const diagnostic = @import("diagnostic.zig");
const abi = r4os.abi;
const terminal_path = "C:\\R4OS\\SOFTWARE\\TERMINAL\\TERMINAL.R4X";
const Page = enum { menu, dialog, terminal, progress };

const State = struct {
    sys: r4os.r4sys.Context,
    desk: r4os.r4desk.Context,
    draw: r4os.r4draw.Context,
    net: r4os.r4net.Context,
    canvas: view.Canvas,
    geometry: view.Geometry,
    font_width: u32 = 8,
    font_height: u32 = 8,
    glyphs: [256][32]u64 = .{.{0} ** 32} ** 256,
    raw: [65536]u8 = undefined,
    cells: [32768]u8 = undefined,
    child: abi.ProgramProcessHandle = .{},
    child_revision: u32 = 0,
    console_retry_since: ?u64 = null,
    page: Page = .menu,
    selection: usize = 0,
    message: []const u8 = "",
    progress: u32 = 0,
    working: bool = false,
    ssh_line: [96]u8 = .{0} ** 96,
    ssh_len: usize = 0,
    blink: bool = true,
    dirty: bool = true,
    test_session: diagnostic.Session = .{},

    fn text(self: *State, x: u32, y: u32, value: []const u8, color: u32) void {
        var px = x;
        for (value) |ch| {
            self.canvas.glyph(px, y, self.glyphs[ch][0..self.font_height], self.font_width, color);
            px +|= self.font_width;
            if (px >= self.canvas.clip.x + self.canvas.clip.w) break;
        }
    }

    fn fonts(self: *State) bool {
        const wanted: u32 = if (self.geometry.monitor.h >= 250) 16 else 8;
        var chosen: u32 = 0;
        for (0..self.draw.fontCount()) |i| {
            var info = abi.GuiFontInfo{};
            if (self.draw.fontInfo(@intCast(i), &info) > 0 and
                (info.flags & abi.gui_font_flag_renderable) != 0 and
                info.height == wanted and info.width == 8 and info.max_advance == 8) chosen = @intCast(i);
        }
        var info = abi.GuiFontInfo{};
        if (self.draw.fontInfo(chosen, &info) <= 0 or info.height == 0 or info.height > 32 or info.width != 8) return false;
        self.font_width = info.width;
        self.font_height = info.height;
        for (&self.glyphs, 0..) |*rows, ch| {
            var glyph = abi.GuiGlyphBitmap{};
            if (self.draw.fontGlyphBitmap(chosen, @intCast(ch), &glyph) < 0) return false;
            @memcpy(rows[0..self.font_height], glyph.rows[0..self.font_height]);
        }
        return true;
    }

    fn content(self: *const State) view.Rect {
        const inner = self.geometry.monitor.inset(8);
        const reserved = (self.font_height + 8) * 3;
        return .{ .x = inner.x, .y = inner.y + self.font_height + 8, .w = inner.w, .h = inner.h -| reserved };
    }

    fn status(self: *State) bool {
        var service = abi.ServiceInfo{};
        var net = abi.NetConfigSnapshot{};
        var buffer: [96]u8 = undefined;
        const running = self.sys.serviceStatus("SSHD", &service) >= 0 and service.state == abi.service_state_running;
        const connected = self.net.netConfigGet(&net) >= 0 and
            net.flags & (abi.net_config_flag_configured | abi.net_config_flag_link_up) == (abi.net_config_flag_configured | abi.net_config_flag_link_up) and
            !std.mem.eql(u8, &net.local_ip, &.{ 0, 0, 0, 0 });
        const line = if (running and connected)
            std.fmt.bufPrint(&buffer, "SSH: {d}.{d}.{d}.{d}", .{ net.local_ip[0], net.local_ip[1], net.local_ip[2], net.local_ip[3] }) catch return false
        else if (connected) "SSH: starting..." else "SSH: waiting for network...";
        if (std.mem.eql(u8, self.ssh_line[0..self.ssh_len], line)) return false;
        @memcpy(self.ssh_line[0..line.len], line);
        self.ssh_len = line.len;
        return true;
    }

    fn render(self: *State, full: bool) bool {
        self.canvas.clip = self.geometry.monitor;
        self.canvas.fill(self.geometry.monitor, view.background);
        const inner = self.geometry.monitor.inset(8);
        self.text(inner.x, inner.y, if (self.page == .menu) "Recovery" else view.labels[self.selection], view.accent);
        self.canvas.fill(.{ .x = inner.x, .y = inner.y + self.font_height + 3, .w = inner.w, .h = 1 }, 0x42201b);
        const area = self.content();
        self.canvas.clip = area;
        switch (self.page) {
            .menu => {
                const item_h = self.font_height + 6;
                const start = area.y + (area.h -| @as(u32, @intCast(view.labels.len)) * item_h) / 2;
                for (view.labels, 0..) |label, index| {
                    const y = start + @as(u32, @intCast(index)) * item_h;
                    if (self.selection == index) {
                        self.canvas.fill(.{ .x = area.x, .y = y, .w = area.w, .h = item_h - 1 }, view.accent);
                        self.text(area.x + 4, y + 3, ">", 0xffffff);
                    }
                    self.text(area.x + self.font_width * 3, y + 3, label, if (self.selection == index) 0xffffff else view.foreground);
                }
            },
            .dialog => self.wrap(self.message, area, view.foreground),
            .progress => {
                self.wrap(self.message, area, view.foreground);
                const bar = view.Rect{ .x = area.x, .y = area.y + area.h / 2, .w = area.w, .h = 8 };
                self.canvas.fill(bar, 0x42201b);
                self.canvas.fill(.{ .x = bar.x, .y = bar.y, .w = @intCast(@as(u64, bar.w) * @min(self.progress, 100) / 100), .h = bar.h }, view.accent);
            },
            .terminal => {
                if (!self.renderTerminal(area)) {
                    // Exit may detach a console between the parent's wait
                    // and its transcript read. The durable handle owns the
                    // completion; retry that boundary before reporting an
                    // unavailable session.
                    if (!self.pollChild()) return false;
                    if (self.page != .terminal) return self.render(full);
                    const now = self.sys.ticks();
                    if (self.console_retry_since) |since| {
                        if (now - since >= self.sys.ticksFromMilliseconds(5000)) return false;
                    } else self.console_retry_since = now;
                    return true;
                }
                self.console_retry_since = null;
            },
        }
        self.canvas.clip = self.geometry.monitor;
        const footer_y = inner.y + inner.h - (self.font_height + 4) * 2;
        self.canvas.fill(.{ .x = inner.x, .y = footer_y - 4, .w = inner.w, .h = 1 }, 0x42201b);
        self.text(inner.x, footer_y, switch (self.page) {
            .menu => "Up/Down: select   Enter: open",
            .terminal => "Type EXIT to return to Recovery",
            .dialog => "Enter / Esc: back",
            .progress => "Please wait...",
        }, view.muted);
        self.text(inner.x, footer_y + self.font_height + 4, self.ssh_line[0..self.ssh_len], view.muted);
        const damage = if (full) view.Rect{ .x = 0, .y = 0, .w = self.canvas.width, .h = self.canvas.height } else self.geometry.monitor;
        const offset = @as(usize, damage.y) * self.canvas.width + damage.x;
        if (self.draw.displayBlitXrgb32Stride(@intCast(damage.x), @intCast(damage.y), damage.w, damage.h, self.canvas.width, self.canvas.pixels[offset..]) < 0) return false;
        self.dirty = false;
        return true;
    }

    fn wrap(self: *State, message: []const u8, area: view.Rect, color: u32) void {
        const cols = area.w / self.font_width;
        if (cols == 0) return;
        var offset: usize = 0;
        var y = area.y;
        while (offset < message.len and y < area.y + area.h) {
            const count = @min(message.len - offset, cols);
            self.text(area.x, y, message[offset..][0..count], color);
            offset += count;
            y += self.font_height + 2;
        }
    }

    fn renderTerminal(self: *State, area: view.Rect) bool {
        const cols = @min(area.w / self.font_width, 256);
        const rows = @min(area.h / self.font_height, 128);
        if (cols == 0 or rows == 0) return false;
        if (self.desk.consoleSetMetrics(self.child.instance_id, cols, rows) < 0) return false;
        var state = abi.ConsoleState{};
        if (self.desk.consoleState(self.child.instance_id, &state) < 0) return false;
        self.test_session.observe(self.sys, state);
        const read = self.desk.consoleOutput(self.child.instance_id, &self.raw);
        if (read < 0 or read > self.raw.len) return false;
        view.transcript(self.raw[0..@intCast(read)], &self.cells, cols, rows);
        self.canvas.fill(area, state.bg);
        for (0..rows) |row| {
            for (0..cols) |col| {
                const ch = self.cells[row * cols + col];
                if (ch != ' ') self.canvas.glyph(area.x + @as(u32, @intCast(col)) * self.font_width, area.y + @as(u32, @intCast(row)) * self.font_height, self.glyphs[ch][0..self.font_height], self.font_width, state.fg);
            }
        }
        if (self.blink and state.cursor_visible != 0 and state.cursor_x >= 0 and state.cursor_y >= 0 and state.cursor_x < cols and state.cursor_y < rows)
            self.canvas.fill(.{ .x = area.x + @as(u32, @intCast(state.cursor_x)) * self.font_width, .y = area.y + @as(u32, @intCast(state.cursor_y)) * self.font_height + self.font_height - 2, .w = self.font_width, .h = 2 }, state.fg);
        return true;
    }

    fn marker(self: *State) void {
        var buffer: [128]u8 = undefined;
        self.sys.write(std.fmt.bufPrint(&buffer, "[RECOVERYUI] page={s} selected={d}\r\n", .{ @tagName(self.page), self.selection }) catch return);
    }

    fn open(self: *State) void {
        switch (self.selection) {
            0, 1, 2 => {
                self.page = .dialog;
                self.message = "This operation is not available in this build.";
            },
            3, 4 => {
                const path: [:0]const u8 = if (self.selection == 4) terminal_path else "C:\\R4OS\\SOFTWARE\\R4PART\\R4PART.R4X";
                const args: [:0]const u8 = if (self.selection == 4) "/NOAUTOEXEC" else "";
                if (self.sys.programSpawnWithConsoleHostHandle(path, args, .console, .terminal_mode, &self.child) < 0) {
                    self.page = .dialog;
                    self.message = "The console program could not be started.";
                } else {
                    self.page = .terminal;
                    self.child_revision = 0;
                    self.console_retry_since = null;
                }
            },
            5 => {
                // Installation/update workflows own this flag while a write
                // is active. The menu cannot cross that completion boundary.
                if (self.working or self.child.instance_id != 0) return;
                self.page = .progress;
                self.message = "Restarting...";
                self.progress = 100;
                _ = self.render(false);
                self.sys.write("[RECOVERYUI] restart=REQUESTED\r\n");
                self.sys.systemReboot();
            },
            else => unreachable,
        }
        self.dirty = true;
        self.marker();
    }

    fn input(self: *State, key: u8) bool {
        switch (self.page) {
            .menu => switch (key) {
                0x80 => self.selection = (self.selection + view.labels.len - 1) % view.labels.len,
                0x81 => self.selection = (self.selection + 1) % view.labels.len,
                '\n' => {
                    self.open();
                    return true;
                },
                else => return true,
            },
            .dialog => {
                if (key != '\n' and key != 0x1b) return true;
                self.page = .menu;
            },
            .terminal => {
                if (self.desk.consolePushKey(self.child.instance_id, key) < 0) return self.pollChild();
                return true;
            },
            .progress => return true,
        }
        self.dirty = true;
        self.marker();
        return true;
    }

    fn pollChild(self: *State) bool {
        if (self.child.instance_id == 0) return true;
        var done = abi.ProgramProcessCompletion{};
        const result = self.sys.programHandleWait(&self.child, 0, &done);
        if (result == abi.program_handle_ok) {
            if (self.sys.programHandleReap(&self.child, &done) != abi.program_handle_ok) return true;
            self.child = .{};
            self.page = .menu;
            self.dirty = true;
            self.sys.write("[RECOVERYUI] terminal=RETURNED\r\n");
            if (!self.test_session.finish(self.sys, self.desk)) return false;
            self.marker();
        } else if (result != abi.program_handle_error_would_block and result != abi.program_handle_error_timeout) return false;
        return true;
    }
};

pub fn r4_app_main(app: *r4os.App) i32 {
    const result = run(app);
    if (result != 0) {
        var text: [80]u8 = undefined;
        app.system().write(std.fmt.bufPrint(&text, "[RECOVERYUI] result=FAILED code={d}\r\n", .{result}) catch "Recovery menu failed.\r\n");
    }
    return result;
}

fn run(app: *r4os.App) i32 {
    const sys = app.system();
    const args = std.mem.span(sys.argsRaw());
    const storage_prefix = "/STORAGESMOKE ";
    if (args.len >= storage_prefix.len and std.ascii.eqlIgnoreCase(args[0..storage_prefix.len], storage_prefix))
        return @import("storage_diagnostic.zig").run(&sys, std.mem.trim(u8, args[storage_prefix.len..], " "));
    const desk = app.desktop() orelse return -1;
    const draw = app.drawing() orelse return -2;
    const net = app.networkLowLevel() orelse return -3;
    const allocator = sys.allocator();
    const width = draw.screenWidth();
    const height = draw.screenHeight();
    const geometry = view.Geometry.fit(width, height);
    if (geometry.monitor.w < 280 or geometry.monitor.h < 160) return -4;
    const count = std.math.mul(usize, width, height) catch return -5;
    const pixels = allocator.alloc(u32, count) catch return -6;
    defer allocator.free(pixels);
    const state = allocator.create(State) catch return -7;
    defer allocator.destroy(state);
    state.* = .{ .sys = sys, .desk = desk, .draw = draw, .net = net, .geometry = geometry, .canvas = .{ .pixels = pixels, .width = width, .height = height, .clip = geometry.monitor } };
    defer state.test_session.close(sys);
    const path = "C:\\R4OS\\MEDIA\\RECOVERY.BMP";
    const info = sys.fileInfo(path) orelse return -8;
    if (info.size != 4720110) return -9;
    const bytes = allocator.alloc(u8, info.size) catch return -10;
    const read = sys.fileRead(path, bytes);
    if (read != bytes.len) {
        var detail: [128]u8 = undefined;
        sys.write(std.fmt.bufPrint(&detail, "[RECOVERYUI] artwork-read={d} expected={d}\r\n", .{ read, bytes.len }) catch "Recovery artwork read failed.\r\n");
        allocator.free(bytes);
        return -21;
    }
    const bitmap = if (read == bytes.len) view.Bitmap.parse(bytes) else null;
    if (bitmap) |image| state.canvas.artwork(image, geometry.image);
    allocator.free(bytes);
    if (bitmap == null) return -11;
    if (!state.fonts()) return -20;
    _ = state.status();
    if (std.ascii.eqlIgnoreCase(std.mem.span(sys.argsRaw()), "/UISMOKE")) {
        if (!state.test_session.begin(sys, desk)) return -17;
        state.page = .progress;
        state.message = "Checking Recovery console...";
        state.progress = 37;
        if (!state.render(true)) return -18;
        sys.write("[RECOVERYUI] progress=READY\r\n");
        const deadline = sys.ticks() + sys.ticksFromMilliseconds(15000);
        while (sys.readKey() != '\n') {
            if (sys.ticks() >= deadline) return -19;
            sys.sleepTicks(1);
        }
        state.page = .menu;
    }
    if (!state.render(true)) return -12;
    _ = sys.bootReady();
    state.marker();
    sys.write("[RECOVERYUI] ready=1\r\n");
    var next_blink = sys.ticks() + sys.ticksFromMilliseconds(500);
    var next_status = sys.ticks() + sys.ticksFromMilliseconds(1000);
    while (!sys.programShouldClose()) {
        if (!state.pollChild()) return -13;
        var budget: usize = 0;
        while (budget < 64) : (budget += 1) {
            const key = sys.readKey();
            if (key == 0) break;
            if (!state.input(key)) return -14;
        }
        const now = sys.ticks();
        if (now >= next_status) {
            state.dirty = state.status() or state.dirty;
            next_status = now + sys.ticksFromMilliseconds(1000);
        }
        if (state.page == .terminal) {
            const revision = desk.consoleRevision(state.child.instance_id);
            if (revision != state.child_revision) {
                state.child_revision = revision;
                state.dirty = true;
            }
            if (now >= next_blink) {
                state.blink = !state.blink;
                state.dirty = true;
                next_blink = now + sys.ticksFromMilliseconds(500);
            }
        }
        if (state.dirty and !state.render(false)) return -15;
        sys.sleepTicks(sys.ticksFromMilliseconds(20));
    }
    if (state.child.instance_id != 0) {
        _ = sys.programHandleRequestClose(&state.child);
        var done = abi.ProgramProcessCompletion{};
        if (sys.programHandleWait(&state.child, sys.ticksFromMilliseconds(5000), &done) != abi.program_handle_ok) return -16;
        _ = sys.programHandleReap(&state.child, &done);
    }
    return 0;
}
