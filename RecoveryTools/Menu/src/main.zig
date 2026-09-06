const std = @import("std");
const r4os = @import("r4os");
const view = @import("view.zig");
const diagnostic = @import("diagnostic.zig");
const selection = @import("selection.zig");
const targets = selection.model;
const packages = @import("package_session.zig");
const install = @import("install.zig");
const system_update = @import("system_update.zig");
const recovery_update = @import("recovery_update.zig");
const downloads = @import("download.zig");
const github = @import("github.zig");
const abi = r4os.abi;
const terminal_path = "C:\\R4OS\\SOFTWARE\\TERMINAL\\TERMINAL.R4X";
const Page = enum { menu, source, targets, review, dialog, terminal, progress };

const State = struct {
    sys: r4os.r4sys.Context,
    desk: r4os.r4desk.Context,
    draw: r4os.r4draw.Context,
    net: r4os.r4net.Context,
    dev: r4os.r4dev.Context,
    web: ?r4os.WebTransport,
    profile: github.Profile = .slim,
    source_warning: []const u8 = "",
    cache: packages.Preview = .{},
    work_view_tick: u64 = 0,
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
    choice: usize = 0,
    source: targets.Source = .cached,
    catalog: ?selection.Catalog = null,
    target_index: usize = 0,
    notice_return: Page = .menu,
    notice: [256]u8 = undefined,
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
            .source => self.renderSource(area),
            .targets => self.renderTargets(area),
            .review => self.renderReview(area),
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
            .source, .review => "Up/Down: select  Enter  Esc: back",
            .targets => "Up/Down  Enter  Esc: back  R: refresh",
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
            const newline = std.mem.indexOfScalar(u8, message[offset..], '\n') orelse message.len - offset;
            const count = @min(newline, cols);
            self.text(area.x, y, message[offset..][0..count], color);
            offset += count + @as(usize, if (count == newline and offset + count < message.len) 1 else 0);
            y += self.font_height + 2;
        }
    }

    fn operation(self: *const State) targets.Operation {
        return @enumFromInt(self.selection);
    }

    fn clearCatalog(self: *State) void {
        if (self.catalog) |*catalog| catalog.deinit();
        self.catalog = null;
    }

    fn fail(self: *State, err: anyerror, back: Page) void {
        self.message = std.fmt.bufPrint(&self.notice, "Selection unavailable: {s}\nRefresh the disk list and select again.", .{@errorName(err)}) catch "Selection unavailable.";
        self.page = .dialog;
        self.notice_return = back;
    }

    fn scanTargets(self: *State) void {
        self.clearCatalog();
        self.catalog = selection.Catalog.scan(&self.sys, self.operation()) catch |err| {
            self.fail(err, .source);
            return;
        };
        self.page = .targets;
        self.choice = 0;
        const catalog = &self.catalog.?;
        var line: [256]u8 = undefined;
        self.sys.write(std.fmt.bufPrint(&line, "[RECOVERYTARGET] mode={s} boot={s} count={d} excluded={d}\r\n", .{
            @tagName(self.operation()), if (catalog.boot) |boot| (if (boot.usb) "USB" else "LOCAL") else "UNKNOWN", catalog.targets.items.len, catalog.excluded_installations,
        }) catch "");
        for (catalog.targets.items) |target| {
            const disk = catalog.disks.items[target.disk];
            var names: [32]u8 = undefined;
            self.sys.write(std.fmt.bufPrint(&line, "[RECOVERYTARGET] disk={d} guid={s} os={s}\r\n", .{
                disk.info.reference.slot, targets.guid.format(disk.info.disk_guid), disk.systems.text(&names),
            }) catch "");
        }
    }

    fn option(self: *State, area: view.Rect, y: u32, label: []const u8, chosen: bool) void {
        if (chosen) self.canvas.fill(.{ .x = area.x, .y = y, .w = area.w, .h = self.font_height + 4 }, view.accent);
        self.text(area.x + 2, y + 2, if (chosen) ">" else " ", view.foreground);
        self.text(area.x + self.font_width * 2, y + 2, label, if (chosen) 0xffffff else view.foreground);
    }

    fn renderSource(self: *State, area: view.Rect) void {
        const step = self.font_height + 6;
        self.text(area.x, area.y, "Choose release source", view.foreground);
        const remote = if (self.kind() == .recovery) "Download Recovery from GitHub" else if (self.profile == .slim) "GitHub: Slim (Left/Right)" else "GitHub: Full (Left/Right)";
        for ([_][]const u8{ "Cached release ZIP", remote, "Back" }, 0..) |label, i|
            self.option(area, area.y + step * @as(u32, @intCast(i + 2)), label, self.choice == i);
        var label: [128]u8 = undefined;
        const detail = switch (self.cache.state) {
            .missing => "No cached ZIP",
            .unchecked => "ZIP present; unable to inspect",
            .invalid => "Cached ZIP is invalid/incompatible",
            .manifest => std.fmt.bufPrint(&label, "Version {s}; full check on Continue", .{std.mem.sliceTo(&self.cache.version, 0)}) catch "Manifest checked",
            .verified => std.fmt.bufPrint(&label, "Version {s}; fully verified", .{std.mem.sliceTo(&self.cache.version, 0)}) catch "Package verified",
        };
        self.text(area.x, area.y + step, detail, view.muted);
        const bottom = area.y + step * 6;
        self.wrap(if (self.source_warning.len != 0) self.source_warning else targets.cachePath(self.operation()), .{ .x = area.x, .y = bottom, .w = area.w, .h = (area.y + area.h) -| bottom }, view.muted);
    }

    fn renderTargets(self: *State, area: view.Rect) void {
        const catalog = &self.catalog.?;
        const count = catalog.targets.items.len;
        const step = self.font_height + 6;
        var buffer: [256]u8 = undefined;
        const label: []const u8 = if (catalog.boot == null) "Boot source unknown; no writable targets." else if (count == 0) "No eligible targets. R: refresh" else switch (self.operation()) {
            .install => "Choose entire disk to replace",
            .system => "Choose existing SYSTEM partition",
            .recovery => "Choose existing RECOVERY partition",
        };
        self.text(area.x, area.y, label, view.foreground);
        const rows = @max(1, (area.h -| step -| (self.font_height + 2) * 3) / step);
        const start = if (self.choice >= rows) self.choice - rows + 1 else 0;
        const end = @min(count + 1, start + rows);
        for (start..end) |i| {
            var names: [32]u8 = undefined;
            const row_text = if (i == count) "Back" else blk: {
                const target = catalog.targets.items[i];
                const disk = catalog.disks.items[target.disk];
                const affected = targets.affected(target, catalog.disks.items, catalog.installed.items);
                break :blk if (target.operation == .install)
                    std.fmt.bufPrint(&buffer, "Disk {d} {d}MB {s}", .{ disk.info.reference.slot, affected.sector_count / 2048, disk.systems.text(&names) }) catch "Disk"
                else
                    std.fmt.bufPrint(&buffer, "Disk {d}/P{d} {d}MB {s}", .{ disk.info.reference.slot, affected.partition_number, affected.sector_count / 2048, disk.systems.text(&names) }) catch "Partition";
            };
            self.option(area, area.y + step * @as(u32, @intCast(i - start + 1)), row_text, self.choice == i);
        }
        const detail_y = area.y + area.h -| (self.font_height + 2) * 3;
        if (self.choice < count) {
            const target = catalog.targets.items[self.choice];
            const disk = catalog.disks.items[target.disk];
            self.text(area.x, detail_y, std.mem.sliceTo(&disk.info.model, 0), view.muted);
            const target_guid = if (target.operation == .install) disk.info.disk_guid else targets.affected(target, catalog.disks.items, catalog.installed.items).partition_guid;
            const id = targets.guid.format(target_guid);
            const identity = if (targets.guid.isZero(target_guid))
                std.fmt.bufPrint(&buffer, "Device {d}, generation {d}", .{ disk.info.reference.slot, disk.info.reference.generation }) catch ""
            else
                &id;
            self.text(area.x, detail_y + self.font_height + 2, identity, view.muted);
        }
        if (catalog.excluded_installations != 0)
            self.text(area.x, detail_y + (self.font_height + 2) * 2, "Invalid/ambiguous installations excluded.", view.accent);
    }

    fn renderReview(self: *State, area: view.Rect) void {
        const catalog = &self.catalog.?;
        const target = catalog.targets.items[self.target_index];
        const disk = catalog.disks.items[target.disk];
        const affected = targets.affected(target, catalog.disks.items, catalog.installed.items);
        var buffer: [1024]u8 = undefined;
        const source = if (self.source == .cached) "cached ZIP" else "GitHub release";
        const review_text = switch (target.operation) {
            .install => std.fmt.bufPrint(&buffer, "Disk {d}: {d}MB - ALL DATA ERASED\nNew layout (not current partitions):\nBIOSBOOT 1MB + BOOT 128MB FAT32\nSYSTEM 1024MB NTFS\nRECOVERY 512MB FAT32\nDATA remaining {d}MB NTFS\nSource: {s}", .{
                disk.info.reference.slot, disk.info.sector_count / 2048, (disk.info.sector_count - 33 - 3411968) / 2048, source,
            }),
            .system => std.fmt.bufPrint(&buffer, "Disk {d}: SYSTEM partition {d}, {d}MB\nReplace ALL SYSTEM files and BOOT kernel.\nKeep partition sizes and identifiers.\nKeep DATA, RECOVERY and limine.conf.\nBOOT partition: {d}\nSource: {s}", .{
                disk.info.reference.slot,                                              affected.partition_number, affected.sector_count / 2048,
                catalog.installed.items[target.installed.?].parts[1].partition_number, source,
            }),
            .recovery => std.fmt.bufPrint(&buffer, "Disk {d}: RECOVERY partition {d}, {d}MB\nReplace the current Recovery package.\nKeep a verified previous Recovery.\nKeep INSTALL cache and other partitions.\nKeep sizes, identifiers and limine.conf.\nBOOT partition: {d}\nSource: {s}", .{
                disk.info.reference.slot,                                              affected.partition_number, affected.sector_count / 2048,
                catalog.installed.items[target.installed.?].parts[1].partition_number, source,
            }),
        } catch "Review unavailable.";
        const step = self.font_height + 6;
        self.wrap(review_text, .{ .x = area.x, .y = area.y, .w = area.w, .h = area.h -| step * 2 }, view.foreground);
        self.option(area, area.y + area.h -| step * 2, "Back", self.choice == 0);
        self.option(area, area.y + area.h -| step, "Continue", self.choice == 1);
    }

    fn kind(self: *const State) packages.package.Kind {
        return if (self.operation() == .recovery) .recovery else .r4os;
    }

    fn pump(raw: ?*anyopaque, phase: []const u8, done: u64, total: u64) bool {
        const self: *State = @ptrCast(@alignCast(raw.?));
        self.message = phase;
        self.progress = if (total == 0) 0 else @intCast(@min(100, done * 100 / total));
        if (self.sys.programShouldClose()) return false;
        const now = self.sys.ticks();
        if (now - self.work_view_tick >= self.sys.ticksFromMilliseconds(100)) {
            self.work_view_tick = now;
            _ = self.status();
            if (!self.render(false)) return false;
        }
        var count: usize = 0;
        while (count < 32) : (count += 1) {
            const key = self.sys.readKey();
            if (key == 0) break;
            if (key == 0x1b) return false;
        }
        self.sys.taskYield();
        return true;
    }
    fn inspectCache(self: *State) void {
        defer {
            self.page = .source;
            self.dirty = true;
            var detail: [144]u8 = undefined;
            self.sys.write(std.fmt.bufPrint(&detail, "[RECOVERYPACKAGE] cache={s} version={s} source=READY\r\n", .{ @tagName(self.cache.state), std.mem.sliceTo(&self.cache.version, 0) }) catch "");
        }
        self.cache = .{};
        self.source_warning = "";
        self.page = .progress;
        downloads.recover(&self.sys, self.kind(), .{ .context = self, .function = pump }) catch |err| {
            self.source_warning = downloads.message(err);
        };
        const path = targets.cachePath(self.operation());
        const info = self.sys.fileInfo(path) orelse return;
        self.cache = .{ .state = .unchecked, .bytes = info.size };
        self.page = .progress;
        self.message = "Inspecting cached ZIP...";
        _ = self.render(false);
        const session = self.sys.allocator().create(packages.Session) catch {
            self.page = .source;
            return;
        };
        defer self.sys.allocator().destroy(session);
        session.init(&self.sys, &self.dev, .{ .context = self, .function = pump });
        defer {
            if (!session.deinit()) self.sys.write("[RECOVERYPACKAGE] cleanup=RETAINED\r\n");
            self.page = .source;
            self.dirty = true;
        }
        self.cache = session.describe(path, self.kind()) catch |err| {
            var reason: [128]u8 = undefined;
            self.sys.write(std.fmt.bufPrint(&reason, "[RECOVERYPACKAGE] preview_rejected={s} writes=0\r\n", .{@errorName(err)}) catch "");
            self.cache.state = if (err == error.OutOfMemory or err == error.Cancelled or session.pool.cancelled) .unchecked else .invalid;
            return;
        };
    }
    fn preparePackage(self: *State) void {
        self.notice_return = .review;
        self.choice = 0;
        self.page = .progress;
        self.working = true;
        self.message = "Preparing package...";
        self.progress = 0;
        _ = self.render(false);
        defer {
            self.working = false;
            self.page = .dialog;
            self.dirty = true;
        }
        const session = self.sys.allocator().create(packages.Session) catch {
            self.message = packages.message(error.OutOfMemory);
            return;
        };
        defer self.sys.allocator().destroy(session);
        session.init(&self.sys, &self.dev, .{ .context = self, .function = pump });
        var result_message: []const u8 = "Package and target prepared. Installation is not available in this build.";
        defer {
            if (!session.deinit()) result_message = "Temporary RAM cleanup is incomplete. Restart Recovery before continuing.";
            self.message = result_message;
        }
        self.prepareTargetPackage(session) catch |err| {
            const actual = if (session.pool.cancelled) error.Cancelled else err;
            result_message = session.failureMessage(&self.notice, actual);
            var detail: [256]u8 = undefined;
            self.sys.write(std.fmt.bufPrint(&detail, "[RECOVERYPACKAGE] rejected={s} vm_error={d} writes=0 ram_capacity={d} ram_required={d}\r\n", .{
                @errorName(actual), session.pool.last_error, session.pool.ram_bytes,
                if (session.prepared) |prepared| prepared.recovery.minimumRamBytes else @as(u64, 0),
            }) catch "");
            return;
        };
        self.cache = .{ .state = .verified, .digest = session.original_digest, .bytes = session.prepared.?.archive.original.len };
        const actual_version = session.prepared.?.version();
        @memcpy(self.cache.version[0..actual_version.len], actual_version);
        var detail: [192]u8 = undefined;
        self.sys.write(std.fmt.bufPrint(&detail, "[RECOVERYPACKAGE] prepared={s} version={s} ram_peak={d} original_zip={d} writes=0\r\n", .{ @tagName(self.kind()), session.prepared.?.version(), session.pool.peak, session.prepared.?.archive.original.len }) catch "");
        if (self.operation() == .install) {
            const installer = session.arena.allocator().create(install.Installer) catch {
                result_message = packages.message(error.OutOfMemory);
                return;
            };
            installer.* = install.Installer.prepare(session, &self.catalog.?, self.target_index) catch |err| {
                result_message = install.message(if (session.pool.cancelled) error.Cancelled else err, false);
                self.sys.write(std.fmt.bufPrint(&detail, "[RECOVERYINSTALL] preflight={s} writes=0 ram_peak={d}\r\n", .{ @errorName(err), session.pool.peak }) catch "");
                return;
            };
            self.sys.write(std.fmt.bufPrint(&detail, "[RECOVERYINSTALL] prepared=OK own_source={d} ram_peak={d} writes=0\r\n", .{ @intFromBool(installer.own_source), session.pool.peak }) catch "");
            installer.execute() catch |err| {
                result_message = install.message(err, installer.progress.write_attempted);
                self.sys.write(std.fmt.bufPrint(&detail, "[RECOVERYINSTALL] result={s} attempted={d} sectors={d} native={d} lba={d} claim={d}\r\n", .{
                    @errorName(err),                                                                                       @intFromBool(installer.progress.write_attempted), installer.progress.written_sectors,
                    if (installer.progress.native_error != 0) installer.progress.native_error else installer.native_error, installer.progress.failed_lba orelse 0,           installer.target.claim,
                }) catch "");
                self.clearCatalog();
                self.notice_return = .menu;
                return;
            };
            const digest = std.fmt.bytesToHex(session.original_digest, .lower);
            self.sys.write(std.fmt.bufPrint(&detail, "[RECOVERYINSTALL] result=OK disk={d} sectors={d} original_sha256={s}\r\n", .{ installer.target.target.device.slot, installer.layout.sectors, digest }) catch "");
            result_message = "R4OS installed. SYSTEM, BOOT, both Recovery slots and the original ZIP were verified. DATA is ready. Restart to boot R4OS.";
            self.clearCatalog();
            self.notice_return = .menu;
        } else if (self.operation() == .system) {
            var update_detail: [512]u8 = undefined;
            const updater = session.arena.allocator().create(system_update.Updater) catch {
                result_message = packages.message(error.OutOfMemory);
                return;
            };
            updater.* = system_update.Updater.prepare(session, &self.catalog.?, self.target_index) catch |err| {
                result_message = system_update.message(if (session.pool.cancelled) error.Cancelled else err, false);
                self.sys.write(std.fmt.bufPrint(&update_detail, "[RECOVERYSYSUPDATE] preflight={s} writes=0 ram_peak={d}\r\n", .{ @errorName(err), session.pool.peak }) catch "");
                return;
            };
            self.sys.write(std.fmt.bufPrint(&update_detail, "[RECOVERYSYSUPDATE] prepared=OK system_sectors={d} boot_files={d} ram_peak={d} writes=0\r\n", .{ updater.system.target.sector_count, updater.boot_plan.changed_files, session.pool.peak }) catch "");
            updater.execute() catch |err| {
                result_message = system_update.message(err, updater.progress.write_attempted);
                self.sys.write(std.fmt.bufPrint(&update_detail, "[RECOVERYSYSUPDATE] result={s} phase={s} attempted={d} sectors={d} native={d} relative_lba={d} boot_claim={d} system_claim={d}\r\n", .{
                    @errorName(err),                                                                                 updater.phase,                        @intFromBool(updater.progress.write_attempted), updater.progress.written_sectors,
                    if (updater.progress.native_error != 0) updater.progress.native_error else updater.native_error, updater.progress.failed_lba orelse 0, updater.boot.claim,                             updater.system.claim,
                }) catch "");
                self.clearCatalog();
                self.notice_return = .menu;
                return;
            };
            self.sys.write(std.fmt.bufPrint(&update_detail, "[RECOVERYSYSUPDATE] result=OK version={s} kernel={s} system_sectors={d} ram_peak={d}\r\n", .{
                session.prepared.?.system.?.releaseVersion, session.prepared.?.system.?.kernelVersion, updater.system.target.sector_count, session.pool.peak,
            }) catch "");
            result_message = "R4OS updated. SYSTEM and its matching BOOT files were verified. Restart to boot the updated system.";
            self.clearCatalog();
            self.notice_return = .menu;
        } else if (self.operation() == .recovery) {
            var update_detail: [512]u8 = undefined;
            const updater = session.arena.allocator().create(recovery_update.Updater) catch {
                result_message = packages.message(error.OutOfMemory);
                return;
            };
            updater.* = recovery_update.Updater.prepare(session, &self.catalog.?, self.target_index) catch |err| {
                result_message = recovery_update.message(if (session.pool.cancelled) error.Cancelled else err, false);
                self.sys.write(std.fmt.bufPrint(&update_detail, "[RECOVERYUPDATE] preflight={s} writes=0 ram_peak={d}\r\n", .{ @errorName(err), session.pool.peak }) catch "");
                return;
            };
            self.sys.write(std.fmt.bufPrint(&update_detail, "[RECOVERYUPDATE] prepared=OK rotate={d} own_source={d} ram_peak={d} writes=0\r\n", .{
                @intFromBool(updater.plan.previous != null), @intFromBool(updater.own_source), session.pool.peak,
            }) catch "");
            updater.execute() catch |err| {
                result_message = recovery_update.message(err, updater.progress.write_attempted);
                self.sys.write(std.fmt.bufPrint(&update_detail, "[RECOVERYUPDATE] result={s} phase={s} attempted={d} sectors={d} native={d} relative_lba={d} claim={d}\r\n", .{
                    @errorName(err),                                                                                 updater.phase,                        @intFromBool(updater.progress.write_attempted), updater.progress.written_sectors,
                    if (updater.progress.native_error != 0) updater.progress.native_error else updater.native_error, updater.progress.failed_lba orelse 0, updater.target.claim,
                }) catch "");
                self.clearCatalog();
                self.notice_return = .menu;
                return;
            };
            self.sys.write(std.fmt.bufPrint(&update_detail, "[RECOVERYUPDATE] result=OK version={s} unchanged={d} ram_peak={d}\r\n", .{
                session.prepared.?.recovery.recoveryVersion, @intFromBool(updater.plan.unchanged), session.pool.peak,
            }) catch "");
            result_message = if (updater.plan.unchanged) "This Recovery package is already installed. No slot changes were needed." else "Recovery updated and verified. PREVIOUS and INSTALL are preserved. The running session remains in RAM. Restart to use the new CURRENT.";
            self.clearCatalog();
            self.notice_return = .menu;
        }
    }
    fn downloadPackage(self: *State) bool {
        self.page = .progress;
        self.working = true;
        self.message = "Checking GitHub release...";
        self.progress = 0;
        _ = self.render(false);
        defer {
            self.working = false;
            self.dirty = true;
        }
        self.notice_return = .source;
        var client = downloads.Client{ .sys = &self.sys, .dev = &self.dev, .web = self.web orelse {
            self.page = .dialog;
            self.message = downloads.message(error.NetworkUnavailable);
            return false;
        }, .kind = self.kind(), .profile = self.profile, .pump = .{ .context = self, .function = pump } };
        self.cache = client.run() catch |err| {
            self.page = .dialog;
            self.message = downloads.message(err);
            var detail: [192]u8 = undefined;
            self.sys.write(std.fmt.bufPrint(&detail, "[RECOVERYDOWNLOAD] error={s} network={s} target_writes=0\r\n", .{ @errorName(err), if (client.last_network_error) |network| @tagName(network) else "none" }) catch "");
            return false;
        };
        self.source_warning = "";
        self.sys.write("[RECOVERYDOWNLOAD] cache=VERIFIED target_writes=0\r\n");
        return true;
    }
    fn prepareTargetPackage(self: *State, session: *packages.Session) !void {
        try session.prepare(targets.cachePath(self.operation()), self.kind(), if (self.cache.state == .manifest or self.cache.state == .verified) self.cache.digest else null);
        const catalog = &self.catalog.?;
        const target = catalog.targets.items[self.target_index];
        if (self.operation() == .system) {
            const affected = targets.affected(target, catalog.disks.items, catalog.installed.items);
            try session.targetSystem(affected.first_lba, affected.sector_count, self.sys.ticks());
        }
        try catalog.revalidate(&self.sys, self.target_index);
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
        self.sys.write(std.fmt.bufPrint(&buffer, "[RECOVERYUI] page={s} selected={d} choice={d}\r\n", .{ @tagName(self.page), self.selection, self.choice }) catch return);
    }

    fn open(self: *State) void {
        switch (self.selection) {
            0, 1, 2 => {
                self.clearCatalog();
                self.page = .source;
                self.choice = 0;
            },
            3, 4 => {
                const path: [:0]const u8 = if (self.selection == 4) terminal_path else "C:\\R4OS\\SOFTWARE\\TERMINAL\\R4PART.R4X";
                const args: [:0]const u8 = if (self.selection == 4) "/NOAUTOEXEC" else "";
                if (self.sys.programSpawnWithConsoleHostHandle(path, args, .console, .terminal_mode, &self.child) < 0) {
                    self.page = .dialog;
                    self.notice_return = .menu;
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
                    if (self.page == .source) self.inspectCache();
                    return true;
                },
                else => return true,
            },
            .source => switch (key) {
                0x80 => self.choice = (self.choice + 2) % 3,
                0x81 => self.choice = (self.choice + 1) % 3,
                0x88, 0x89 => if (self.choice == 1 and self.kind() == .r4os) {
                    self.profile = if (self.profile == .slim) .full else .slim;
                },
                '\n' => if (self.choice == 2) {
                    self.clearCatalog();
                    self.page = .menu;
                } else {
                    self.source = @enumFromInt(self.choice);
                    if (self.source == .github and !self.downloadPackage()) return true;
                    self.scanTargets();
                },
                0x1b => {
                    self.clearCatalog();
                    self.page = .menu;
                },
                else => return true,
            },
            .targets => {
                const count = self.catalog.?.targets.items.len;
                switch (key) {
                    0x80 => self.choice = (self.choice + count) % (count + 1),
                    0x81 => self.choice = (self.choice + 1) % (count + 1),
                    'r', 'R' => self.scanTargets(),
                    0x1b => {
                        self.page = .source;
                        self.choice = @intFromEnum(self.source);
                    },
                    '\n' => if (self.choice == count) {
                        self.page = .source;
                        self.choice = @intFromEnum(self.source);
                    } else {
                        self.target_index = self.choice;
                        self.choice = 0; // Destructive review always defaults to Back.
                        self.page = .review;
                    },
                    else => return true,
                }
            },
            .review => switch (key) {
                0x80, 0x81 => self.choice = 1 - self.choice,
                0x1b => {
                    self.page = .targets;
                    self.choice = self.target_index;
                },
                '\n' => if (self.choice == 0) {
                    self.page = .targets;
                    self.choice = self.target_index;
                } else {
                    self.catalog.?.revalidate(&self.sys, self.target_index) catch |err| {
                        self.choice = self.target_index;
                        self.fail(err, .targets);
                        self.dirty = true;
                        self.marker();
                        return true;
                    };
                    self.sys.write("[RECOVERYTARGET] identity=REVALIDATED writes=0\r\n");
                    self.preparePackage();
                },
                else => return true,
            },
            .dialog => {
                if (key != '\n' and key != 0x1b) return true;
                self.page = self.notice_return;
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
    const download_prefix = "/DOWNLOADSMOKE ";
    if (std.mem.startsWith(u8, args, download_prefix)) return @import("download_diagnostic.zig").run(app, args[download_prefix.len..]);
    const package_prefix = "/PACKAGESMOKE ";
    if (std.mem.startsWith(u8, args, package_prefix)) return @import("package_diagnostic.zig").run(app, args[package_prefix.len..]);
    const storage_prefix = "/STORAGESMOKE ";
    if (args.len >= storage_prefix.len and std.ascii.eqlIgnoreCase(args[0..storage_prefix.len], storage_prefix))
        return @import("storage_diagnostic.zig").run(&sys, std.mem.trim(u8, args[storage_prefix.len..], " "));
    const desk = app.desktop() orelse return -1;
    const draw = app.drawing() orelse return -2;
    const net = app.networkLowLevel() orelse return -3;
    const dev = app.devicesLowLevel() orelse return -22;
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
    state.* = .{ .sys = sys, .desk = desk, .draw = draw, .net = net, .dev = dev, .web = app.web(), .geometry = geometry, .canvas = .{ .pixels = pixels, .width = width, .height = height, .clip = geometry.monitor } };
    defer state.test_session.close(sys);
    defer state.clearCatalog();
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
    for ([_]github.Kind{ .r4os, .recovery }) |kind| {
        state.page = .progress;
        downloads.recover(&state.sys, kind, .{ .context = state, .function = State.pump }) catch |err| {
            state.source_warning = downloads.message(err);
            sys.write("[RECOVERYDOWNLOAD] startup=RETAINED check=INSTALL\r\n");
        };
    }
    state.page = .menu;
    if (!state.render(true)) return -12;
    _ = sys.bootReady();
    const confirmed = @import("boot_confirmation.zig").confirm(&state.sys) catch |err| blk: {
        var detail: [192]u8 = undefined;
        sys.write(std.fmt.bufPrint(&detail, "[RECOVERYCONFIRM] state=UNCONFIRMED reason={s} ram=READY\r\n", .{@errorName(err)}) catch "");
        break :blk false;
    };
    if (confirmed) sys.write("[RECOVERYCONFIRM] state=CONFIRMED content=BOOTED\r\n");
    state.marker();
    sys.write("[RECOVERYUI] ready=1\r\n");
    if (state.dev.memoryPressure()) |memory| {
        var line: [192]u8 = undefined;
        const ram = @import("memory_budget.zig").capacity(&state.dev) catch 0;
        sys.write(std.fmt.bufPrint(&line, "[RECOVERYRAM] ram_capacity={d} menu_used={d} free={d} available={d}\r\n", .{ ram, ram -| memory.free_physical_bytes, memory.free_physical_bytes, memory.app_available_bytes }) catch "");
    }
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
