const std = @import("std");
const r4os = @import("r4os");

const host_api = r4os.subsystem_host;
const runtime_api = r4os.subsystem_runtime;
const max_width: u32 = 640;
const max_height: u32 = 350;
const max_pixels: usize = @as(usize, max_width) * @as(usize, max_height);
const animation_frames: u32 = 24;
const runtime_slice_budget: u32 = 2048;
const guest_a_path = "C:\\TEMP\\SUBSYSTEM-A.BAS";
const guest_b_path = "C:\\TEMP\\SUBSYSTEM-B.BAS";
const selftest_marker_path = "C:\\TEMP\\SUBSYS.OK";

var indexed_pixels: [max_pixels]u8 = .{0} ** max_pixels;
var xrgb_pixels: [max_pixels]u32 = .{0} ** max_pixels;
var palette: [host_api.palette_entries]u32 = .{0} ** host_api.palette_entries;
var tile_scratch: [host_api.tile_max_pixels]u32 = undefined;
var audio_queue_storage: [runtime_api.default_quantum_frames * runtime_api.default_channels * @sizeOf(i16) * runtime_api.default_target_quanta]u8 = undefined;
var audio_scratch: [runtime_api.default_quantum_frames * runtime_api.default_channels * @sizeOf(i16)]u8 = undefined;
var active_selftest_variant: u8 = 0;

const Mode = enum {
    qbasic_640x350,
    dos_320x200,
    snes_256x224,
};

const Demo = struct {
    mode: Mode = .qbasic_640x350,
    animation: bool = true,
    focused: bool = true,
    palette_phase: u8 = 0,
    sprite_x: u32 = 0,
    sprite_y: u32 = 0,
    last_animation_tick: u64 = 0,
};

pub fn r4_app_main(app: *r4os.App) i32 {
    if (app.profile != .desktop) return 66;
    const desk = app.desktop() orelse return 67;
    const draw = app.drawing() orelse return 68;
    var sys = app.system();
    const audio = app.audio();
    if (equalsIgnoreCase(app.args(), "/SELFTEST") or equalsIgnoreCase(app.args(), "/HOSTSELFTEST")) return runSelfTest(&sys, desk, draw, audio, .guest_completion, 1);

    const request = r4os.subsystem_launch.parse(app.args()) catch return 69;
    sys.write("SUBSYSOK guest: ");
    sys.println(request.guest_path);
    if (equalsIgnoreCase(request.guest_path, guest_a_path)) return runSelfTest(&sys, desk, draw, audio, .guest_completion, 1);
    if (equalsIgnoreCase(request.guest_path, guest_b_path)) return runSelfTest(&sys, desk, draw, audio, .window_close, 2);
    return runInteractive(&sys, desk, draw);
}

fn runInteractive(sys: *r4os.r4sys.Context, desk: r4os.r4desk.Context, draw: r4os.r4draw.Context) i32 {
    initializePalette();
    const initial = makeSurface(.qbasic_640x350) catch return 70;
    var host = host_api.Host.init(desk, draw, initial, tile_scratch[0..]) catch return 71;
    _ = host.setMinimumSize(360, 220);
    _ = host.setTitle("Subsystem Host: 640x350 [1/2/3, Space, P]");
    var demo = Demo{};
    paintPattern(&host.video.surface, demo.mode, demo.focused, demo.palette_phase);
    if (!presentSucceeded(host.present())) return 72;

    while (true) {
        var should_present = false;
        while (host.pollInput()) |event| {
            switch (event) {
                .close => return 0,
                .resize => should_present = true,
                .focus => |focus| {
                    demo.focused = focus.focused;
                    paintBorder(&host.video.surface, demo.focused);
                    host.video.invalidate(borderDamage(host.video.surface.width, host.video.surface.height));
                    should_present = true;
                },
                .key_down => |key| {
                    switch (key.code) {
                        '1' => if (!switchMode(&host, &demo, .qbasic_640x350)) return 73,
                        '2' => if (!switchMode(&host, &demo, .dos_320x200)) return 74,
                        '3' => if (!switchMode(&host, &demo, .snes_256x224)) return 75,
                        ' ' => demo.animation = !demo.animation,
                        'P', 'p' => {
                            demo.palette_phase +%= 1;
                            rotatePalette(demo.palette_phase);
                            paintPattern(&host.video.surface, demo.mode, demo.focused, demo.palette_phase);
                            host.video.invalidateAll();
                        },
                        r4os.gui.Key.escape => return 0,
                        else => {},
                    }
                    should_present = true;
                },
                .physical_key_down, .physical_key_up => {},
                .text => |text| {
                    paintTextIndicator(&host.video.surface, text.codepoint);
                    host.video.invalidate(.{ .x = 8, .y = 8, .w = 20, .h = 12 });
                    should_present = true;
                },
                .mouse => |mouse| if (mouse.guest) |point| {
                    paintCrosshair(&host.video.surface, point);
                    host.video.invalidate(crosshairDamage(point, host.video.surface.width, host.video.surface.height));
                    should_present = true;
                },
            }
        }

        const now = sys.ticks();
        const interval = @max(@as(u64, 1), @as(u64, sys.monotonicHz()) / 30);
        if (demo.animation and now -| demo.last_animation_tick >= interval) {
            animate(&host, &demo);
            demo.last_animation_tick = now;
            should_present = true;
        }
        if (should_present) {
            switch (host.present()) {
                .failure => return 76,
                else => {},
            }
        }
        sys.sleepTicks(1);
    }
}

fn runSelfTest(sys: *r4os.r4sys.Context, desk: r4os.r4desk.Context, draw: r4os.r4draw.Context, audio: ?r4os.Audio, exit_mode: RuntimeExitMode, variant: u8) i32 {
    active_selftest_variant = variant;
    initializePalette();
    var host = host_api.Host.init(desk, draw, makeSurface(.qbasic_640x350) catch return selfTestFail(sys, "surface-640", 80), tile_scratch[0..]) catch return selfTestFail(sys, "host-init", 81);
    _ = host.setMinimumSize(360, 220);
    _ = host.setTitle("Subsystem Host Selftest");
    paintPattern(&host.video.surface, .qbasic_640x350, true, 0);

    if (!presentInitialFullFrame(sys, &host)) return selfTestFail(sys, "full-640", 82);
    if (!runtimeInputSelfTest(sys, &host)) return selfTestFail(sys, "runtime-input", 100);
    if (host.present() != .unchanged) return selfTestFail(sys, "unchanged", 83);
    host.video.invalidate(.{ .x = 12, .y = 14, .w = 18, .h = 16 });
    host.video.invalidate(.{ .x = 580, .y = 310, .w = 12, .h = 10 });
    const sparse_damage_ok = switch (host.present()) {
        .presented => |info| info.mode == .damage and info.damage_regions == 2 and info.raster_blocks >= 2,
        else => false,
    };
    if (!sparse_damage_ok) return selfTestFail(sys, "damage-regions", 84);

    host.video.setSurface(makeSurface(.dos_320x200) catch return selfTestFail(sys, "surface-320", 85)) catch return selfTestFail(sys, "mode-320", 86);
    paintPattern(&host.video.surface, .dos_320x200, true, 0);
    if (!presentedAs(host.present(), .full)) return selfTestFail(sys, "xrgb32", 87);

    host.video.setSurface(makeSurface(.snes_256x224) catch return selfTestFail(sys, "surface-256", 88)) catch return selfTestFail(sys, "mode-256", 89);
    paintPattern(&host.video.surface, .snes_256x224, true, 0);
    if (!presentedAs(host.present(), .full)) return selfTestFail(sys, "indexed8", 90);
    if (!host.video.setPaletteEntry(1, 0x003366CC)) return selfTestFail(sys, "palette-set", 91);
    if (!presentedAs(host.present(), .full)) return selfTestFail(sys, "palette-frame", 92);

    if (!inputSelfTest()) return selfTestFail(sys, "input", 93);

    host.video.setSurface(makeSurface(.qbasic_640x350) catch return selfTestFail(sys, "surface-animation", 94)) catch return selfTestFail(sys, "mode-animation", 95);
    paintPattern(&host.video.surface, .qbasic_640x350, true, 0);
    if (!presentSucceeded(host.present())) return selfTestFail(sys, "animation-prime", 96);
    const started = sys.ticks();
    var frame: u32 = 0;
    while (frame < animation_frames) : (frame += 1) {
        paintAnimationBand(&host.video.surface, frame);
        host.video.invalidateAll();
        if (!presentedAs(host.present(), .full)) return selfTestFail(sys, "animation-present", 97);
        sys.taskYield();
    }
    const elapsed = sys.ticks() -| started;
    const hz: u64 = @max(@as(u32, 1), sys.monotonicHz());
    if (elapsed != 0 and @as(u64, animation_frames) * hz < elapsed * 20) return selfTestFail(sys, "animation-fps", 98);
    if (host.video.stats.skipped_frames == 0 or
        host.video.stats.full_frames < animation_frames + 4 or
        host.video.stats.damage_frames == 0 or
        host.video.stats.damage_regions <= host.video.stats.published_frames or
        host.video.stats.indexed8_frames == 0 or
        host.video.stats.indexed8_blocks == 0 or
        host.video.stats.indexed8_resource_bytes <= host.video.stats.indexed8_blocks or
        host.video.stats.xrgb_fallback_frames != 0)
    {
        return selfTestFail(sys, "stats", 99);
    }

    sys.println("SUBSYSTEM host selftest: OK modes=640x350+320x200+256x224 formats=indexed8+xrgb32 damage=sparse indexed8=abi tiles=bounded input=sequenced+policy-filtered idle=no-frame fps>=20");
    return runRuntimeSelfTest(sys, &host, audio, exit_mode, variant);
}

const RuntimeExitMode = enum {
    guest_completion,
    window_close,
};

const RuntimePhase = enum {
    warming,
    paused,
    resumed,
    reset,
    muted,
    unmuted,
    done,
};

const RuntimeGuest = struct {
    host: *host_api.Host,
    demo: Demo,
    pacer: runtime_api.Pacer,
    exit_mode: RuntimeExitMode,
    variant: u8,
    steps: u32 = 0,
    total_steps: u32 = 0,
    resets: u32 = 0,
    max_budget: u32 = 0,
    operations: u64 = 0,
    checksum: u32 = 0,
    last_guest_ns: u64 = 0,
    audio_frames: u64 = 0,
    allow_finish: bool = false,

    fn init(host: *host_api.Host, exit_mode: RuntimeExitMode, variant: u8) ?RuntimeGuest {
        return .{
            .host = host,
            .demo = .{ .palette_phase = variant },
            .pacer = runtime_api.Pacer.initHz(30) catch return null,
            .exit_mode = exit_mode,
            .variant = variant,
        };
    }

    fn driver(self: *RuntimeGuest) runtime_api.GuestDriver {
        return .{
            .context = self,
            .step_fn = runtimeGuestStep,
            .reset_fn = runtimeGuestReset,
            .render_audio_fn = runtimeGuestAudio,
        };
    }
};

const RuntimeSelfTestHost = struct {
    host: *host_api.Host,
    guest: *RuntimeGuest,
    runtime: *runtime_api.Runtime,
    exit_mode: RuntimeExitMode,
    phase: RuntimePhase = .warming,
    idle_after_command: bool = false,
    paused_steps: u32 = 0,
    paused_cycles: u32 = 0,
    saw_resize: bool = false,
    saw_focus: bool = false,
    muted_submitted_bytes: u64 = 0,
    muted_writes: u64 = 0,
    muted_idle_closes: u64 = 0,
    muted_was_active: bool = false,

    fn driver(self: *RuntimeSelfTestHost) runtime_api.HostDriver {
        return .{
            .context = self,
            .poll_fn = runtimeHostPoll,
            .present_fn = runtimeHostPresent,
        };
    }

    fn command(self: *RuntimeSelfTestHost, value: runtime_api.LifecycleCommand) runtime_api.HostPollResult {
        self.idle_after_command = true;
        return .{ .command = value };
    }
};

fn runRuntimeSelfTest(sys: *r4os.r4sys.Context, host: *host_api.Host, audio: ?r4os.Audio, exit_mode: RuntimeExitMode, variant: u8) i32 {
    host.video.setSurface(makeSurface(.qbasic_640x350) catch return runtimeSelfTestFail(sys, "surface", 110)) catch return runtimeSelfTestFail(sys, "mode", 111);
    paintPattern(&host.video.surface, .qbasic_640x350, true, variant);
    host.video.invalidateAll();
    _ = host.setTitle(if (variant == 1) "Subsystem Runtime A" else "Subsystem Runtime B");

    var audio_adapter: runtime_api.R4AudioSink = undefined;
    var sink: ?runtime_api.AudioSink = null;
    if (audio) |available| {
        audio_adapter = runtime_api.R4AudioSink.initWithTimeouts(
            available,
            100 * std.time.ns_per_ms,
            500 * std.time.ns_per_ms,
        );
        sink = audio_adapter.sink();
    }

    var runtime = runtime_api.Runtime.init(.{
        .slice_budget = runtime_slice_budget,
        .max_input_events = 64,
        .max_wait_ticks = 1,
    }, sys.monotonicHz(), sys.ticks(), .{
        .queue_storage = audio_queue_storage[0..],
        .scratch = audio_scratch[0..],
        .sink = sink,
    }) catch return runtimeSelfTestFail(sys, "runtime-init", 112);
    var guest = RuntimeGuest.init(host, exit_mode, variant) orelse return runtimeSelfTestFail(sys, "guest-init", 113);
    var runtime_host = RuntimeSelfTestHost{
        .host = host,
        .guest = &guest,
        .runtime = &runtime,
        .exit_mode = exit_mode,
    };

    const result = runtime.run(sys, guest.driver(), runtime_host.driver());
    if (result != 0) return runtimeSelfTestFail(sys, "runtime-exit", 114);
    const expected_state: runtime_api.LifecycleState = if (exit_mode == .guest_completion) .completed else .closed;
    if (runtime.state != expected_state) return runtimeSelfTestFail(sys, switch (runtime_host.phase) {
        .warming => "lifecycle-end-warming",
        .paused => "lifecycle-end-paused",
        .resumed => "lifecycle-end-resumed",
        .reset => "lifecycle-end-reset",
        .muted => "lifecycle-end-muted",
        .unmuted => "lifecycle-end-unmuted",
        .done => "lifecycle-end-done",
    }, 115);
    if (!runtime.resources_closed or runtime.audio.state != .closed) return runtimeSelfTestFail(sys, "resource-close", 116);
    if (runtime.stats.pauses != 1 or runtime.stats.resumes != 1 or runtime.stats.resets != 1) return runtimeSelfTestFail(sys, "lifecycle-counts", 117);
    if (guest.resets != 1 or guest.max_budget == 0 or guest.max_budget > runtime_slice_budget or guest.operations == 0) return runtimeSelfTestFail(sys, "slice-budget", 118);
    if (runtime.stats.slices < 6) return runtimeSelfTestFail(sys, "time-pacing-slices", 119);
    if (runtime.stats.sleeps == 0) return runtimeSelfTestFail(sys, "time-pacing-sleeps", 119);
    if (runtime.clock.guest_ns == 0) return runtimeSelfTestFail(sys, "time-pacing-clock", 119);
    if (runtime.audio.last_error != 0) return runtimeSelfTestFail(sys, "audio-close", 120);
    if (runtime.audio.stats.generated_bytes == 0) return runtimeSelfTestFail(sys, "audio-generate", 120);
    if (runtime.audio.stats.submitted_bytes == 0) return runtimeSelfTestFail(sys, "audio-submit", 120);
    if (runtime.audio.stats.muted_bytes == 0 or runtime.audio.muted or runtime.audio.stats.idle_closes == 0) return runtimeSelfTestFail(sys, "audio-idle", 121);
    if (runtime.stats.presents < 4 or runtime_host.phase == .warming or runtime_host.phase == .paused or runtime_host.phase == .resumed or runtime_host.phase == .reset or runtime_host.phase == .muted) return runtimeSelfTestFail(sys, "host-progress", 122);

    sys.println("SUBSYSTEM runtime selftest: OK slices=bounded time=monotonic audio=s16le-buffered lifecycle=pause+resume+reset+complete+close resources=closed");
    return 0;
}

fn runtimeGuestStep(context: *anyopaque, budget: u32, guest_now_ns: u64) runtime_api.StepResult {
    const self: *RuntimeGuest = @ptrCast(@alignCast(context));
    if (self.steps != 0 and guest_now_ns < self.last_guest_ns) return runtime_api.StepResult.fail(-9701);
    self.last_guest_ns = guest_now_ns;
    if (!self.pacer.take(guest_now_ns)) return runtime_api.StepResult.waitUntil(self.pacer.deadline(), false);

    self.max_budget = @max(self.max_budget, budget);
    var operation: u32 = 0;
    while (operation < budget) : (operation += 1) {
        self.checksum = self.checksum *% 1664525 +% 1013904223 +% operation +% self.variant;
    }
    self.operations +%= budget;
    self.steps +%= 1;
    self.total_steps +%= 1;
    animate(self.host, &self.demo);
    if (self.allow_finish and self.exit_mode == .guest_completion and self.steps >= 6) return runtime_api.StepResult.complete(0, true).withOperations(budget);
    return runtime_api.StepResult.waitUntil(self.pacer.deadline(), true).withOperations(budget);
}

fn runtimeGuestReset(context: *anyopaque) i32 {
    const self: *RuntimeGuest = @ptrCast(@alignCast(context));
    self.resets +%= 1;
    self.steps = 0;
    self.last_guest_ns = 0;
    self.allow_finish = false;
    self.demo.sprite_x = 0;
    self.demo.sprite_y = 0;
    self.pacer.reset(0);
    paintPattern(&self.host.video.surface, .qbasic_640x350, self.demo.focused, self.demo.palette_phase);
    self.host.video.invalidateAll();
    return 0;
}

fn runtimeGuestAudio(context: *anyopaque, out: []u8) i32 {
    const self: *RuntimeGuest = @ptrCast(@alignCast(context));
    const count = out.len - out.len % 4;
    const half_period: u64 = if (self.variant == 1) 48 else 36;
    const amplitude: i16 = if (self.variant == 1) 1024 else 1536;
    var pos: usize = 0;
    while (pos < count) : (pos += 4) {
        const sample: i16 = if ((self.audio_frames / half_period) % 2 == 0) amplitude else -amplitude;
        const bits: u16 = @bitCast(sample);
        const low: u8 = @truncate(bits);
        const high: u8 = @truncate(bits >> 8);
        out[pos] = low;
        out[pos + 1] = high;
        out[pos + 2] = low;
        out[pos + 3] = high;
        self.audio_frames +%= 1;
    }
    return @intCast(count);
}

fn runtimeHostPoll(context: *anyopaque) runtime_api.HostPollResult {
    const self: *RuntimeSelfTestHost = @ptrCast(@alignCast(context));
    if (self.host.pollInput()) |event| return runtimeHostInput(self, event);
    if (self.idle_after_command) {
        self.idle_after_command = false;
        return .idle;
    }

    switch (self.phase) {
        .warming => if (self.guest.steps >= 2) {
            self.paused_steps = self.guest.steps;
            self.phase = .paused;
            return self.command(.pause);
        },
        .paused => {
            if (self.guest.steps != self.paused_steps) return .{ .failure = -9710 };
            self.paused_cycles +%= 1;
            if (self.paused_cycles >= 3) {
                self.phase = .resumed;
                return self.command(.resume_running);
            }
        },
        .resumed => if (self.guest.steps >= self.paused_steps + 2) {
            self.phase = .reset;
            return self.command(.reset);
        },
        .reset => {
            if (self.guest.resets > 1) return .{ .failure = -9711 };
            if (self.guest.resets == 1 and self.guest.steps >= 2) {
                self.muted_submitted_bytes = self.runtime.audio.stats.submitted_bytes;
                self.muted_writes = self.runtime.audio.stats.writes;
                self.muted_idle_closes = self.runtime.audio.stats.idle_closes;
                self.muted_was_active = self.runtime.audio.state == .active;
                self.phase = .muted;
                return self.command(.mute);
            }
        },
        .muted => {
            if (!self.runtime.audio.muted or
                self.runtime.audio.stats.submitted_bytes != self.muted_submitted_bytes or
                self.runtime.audio.stats.writes != self.muted_writes)
            {
                return .{ .failure = -9712 };
            }
            const expected_idle_closes = self.muted_idle_closes + @intFromBool(self.muted_was_active);
            if (self.runtime.audio.state == .ready and
                self.runtime.audio.next_deadline_tick == 0 and
                self.runtime.audio.stats.idle_closes == expected_idle_closes)
            {
                self.phase = .unmuted;
                return self.command(.unmute);
            }
        },
        .unmuted => {
            // On hardware-assisted hosts the six guest steps can finish
            // before the asynchronous audio service confirms its first
            // write. Keep both completion variants alive until transport
            // progress is observable instead of relying on TCG latency.
            if (self.runtime.audio.muted or
                self.runtime.audio.stats.generated_bytes == 0 or
                self.runtime.audio.stats.submitted_bytes == 0)
            {
                return .idle;
            }
            self.guest.allow_finish = true;
            if (self.exit_mode == .window_close and self.guest.steps >= 6) {
                self.phase = .done;
                return self.command(.close);
            }
        },
        .done => {},
    }
    return .idle;
}

fn runtimeHostInput(self: *RuntimeSelfTestHost, event: host_api.InputEvent) runtime_api.HostPollResult {
    switch (event) {
        .close => return self.command(.close),
        .resize => {
            self.saw_resize = true;
            self.host.video.invalidateAll();
            return .present;
        },
        .focus => |focus| {
            self.saw_focus = self.saw_focus or focus.focused;
            self.guest.demo.focused = focus.focused;
            paintBorder(&self.host.video.surface, focus.focused);
            self.host.video.invalidate(borderDamage(self.host.video.surface.width, self.host.video.surface.height));
            return .present;
        },
        .key_down => |key| switch (key.code) {
            ' ' => return self.command(.toggle_pause),
            'R', 'r' => return self.command(.reset),
            'M', 'm' => return self.command(.toggle_mute),
            'P', 'p' => {
                self.guest.demo.palette_phase +%= 1;
                rotatePalette(self.guest.demo.palette_phase);
                paintPattern(&self.host.video.surface, self.guest.demo.mode, self.guest.demo.focused, self.guest.demo.palette_phase);
                self.host.video.invalidateAll();
                return .present;
            },
            r4os.gui.Key.escape => return self.command(.close),
            else => return .handled,
        },
        .physical_key_down, .physical_key_up => return .handled,
        .text => |text| {
            paintTextIndicator(&self.host.video.surface, text.codepoint);
            self.host.video.invalidate(.{ .x = 8, .y = 8, .w = 20, .h = 12 });
            return .present;
        },
        .mouse => |mouse| if (mouse.guest) |point| {
            paintCrosshair(&self.host.video.surface, point);
            self.host.video.invalidate(crosshairDamage(point, self.host.video.surface.width, self.host.video.surface.height));
            return .present;
        } else return .handled,
    }
}

fn runtimeHostPresent(context: *anyopaque) i32 {
    const self: *RuntimeSelfTestHost = @ptrCast(@alignCast(context));
    return switch (self.host.present()) {
        .failure => |raw| raw,
        .presented => 1,
        .hidden, .unchanged => 0,
    };
}

fn runtimeSelfTestFail(sys: *r4os.r4sys.Context, reason: []const u8, code: i32) i32 {
    sys.write("SUBSYSTEM runtime selftest FAILED: ");
    sys.println(reason);
    writeSelfTestFailure(sys, "SUBSYSTEM runtime selftest FAILED: ", reason);
    return code;
}

fn switchMode(host: *host_api.Host, demo: *Demo, mode: Mode) bool {
    host.video.setSurface(makeSurface(mode) catch return false) catch return false;
    demo.mode = mode;
    demo.sprite_x = 0;
    demo.sprite_y = 0;
    paintPattern(&host.video.surface, mode, demo.focused, demo.palette_phase);
    _ = host.setTitle(switch (mode) {
        .qbasic_640x350 => "Subsystem Host: 640x350 Indexed8",
        .dos_320x200 => "Subsystem Host: 320x200 XRGB32",
        .snes_256x224 => "Subsystem Host: 256x224 Indexed8",
    });
    return true;
}

fn makeSurface(mode: Mode) host_api.Error!host_api.Surface {
    return switch (mode) {
        .qbasic_640x350 => host_api.Surface.initIndexed8(indexed_pixels[0..], palette[0..], 640, 350),
        .dos_320x200 => host_api.Surface.initXrgb32(xrgb_pixels[0..], 320, 200),
        .snes_256x224 => host_api.Surface.initIndexed8(indexed_pixels[0..], palette[0..], 256, 224),
    };
}

fn initializePalette() void {
    @memset(palette[0..], 0);
    const basic = [_]u32{
        0x000000, 0x0000AA, 0x00AA00, 0x00AAAA,
        0xAA0000, 0xAA00AA, 0xAA5500, 0xAAAAAA,
        0x555555, 0x5555FF, 0x55FF55, 0x55FFFF,
        0xFF5555, 0xFF55FF, 0xFFFF55, 0xFFFFFF,
    };
    @memcpy(palette[0..basic.len], basic[0..]);
}

fn rotatePalette(phase: u8) void {
    const shift: u5 = @intCast(phase % 8);
    var i: usize = 1;
    while (i < 16) : (i += 1) {
        const base = @as(u32, @intCast(i * 17));
        palette[i] = ((base << shift) | (base >> @as(u5, @intCast(8 - shift)))) & 0x00FF_FFFF;
    }
    palette[15] = 0xFFFFFF;
}

fn paintPattern(surface: *host_api.Surface, mode: Mode, focused: bool, phase: u8) void {
    switch (surface.storage) {
        .indexed8 => |value| {
            var y: u32 = 0;
            while (y < surface.height) : (y += 1) {
                var x: u32 = 0;
                while (x < surface.width) : (x += 1) {
                    const block = (x / 32 + y / 24 + phase) % 14;
                    value.pixels[@as(usize, y) * @as(usize, surface.width) + x] = @intCast(block + 1);
                }
            }
        },
        .xrgb32 => |value| {
            var y: u32 = 0;
            while (y < surface.height) : (y += 1) {
                var x: u32 = 0;
                while (x < surface.width) : (x += 1) {
                    const red = (x * 255) / surface.width;
                    const green = (y * 255) / surface.height;
                    const blue = ((x / 20 + y / 20) & 1) * 96 + 48;
                    value[@as(usize, y) * @as(usize, surface.width) + x] = (red << 16) | (green << 8) | blue;
                }
            }
        },
    }
    _ = mode;
    paintBorder(surface, focused);
}

fn paintBorder(surface: *host_api.Surface, focused: bool) void {
    const color: u32 = if (focused) 15 else 8;
    paintRect(surface, .{ .x = 0, .y = 0, .w = surface.width, .h = 3 }, color);
    paintRect(surface, .{ .x = 0, .y = surface.height - 3, .w = surface.width, .h = 3 }, color);
    paintRect(surface, .{ .x = 0, .y = 0, .w = 3, .h = surface.height }, color);
    paintRect(surface, .{ .x = surface.width - 3, .y = 0, .w = 3, .h = surface.height }, color);
}

fn paintTextIndicator(surface: *host_api.Surface, codepoint: u32) void {
    const color = @as(u32, @intCast(codepoint % 14)) + 1;
    paintRect(surface, .{ .x = 8, .y = 8, .w = 20, .h = 12 }, color);
}

fn paintCrosshair(surface: *host_api.Surface, point: host_api.Point) void {
    const x0 = point.x -| 5;
    const y0 = point.y -| 5;
    paintRect(surface, .{ .x = x0, .y = point.y, .w = @min(@as(u32, 11), surface.width - x0), .h = 1 }, 15);
    paintRect(surface, .{ .x = point.x, .y = y0, .w = 1, .h = @min(@as(u32, 11), surface.height - y0) }, 15);
}

fn animate(host: *host_api.Host, demo: *Demo) void {
    const old = spriteRect(demo.sprite_x, demo.sprite_y, host.video.surface.width, host.video.surface.height);
    paintPatternRect(&host.video.surface, old, demo.palette_phase);
    demo.sprite_x = (demo.sprite_x + 5) % @max(@as(u32, 1), host.video.surface.width - 18);
    demo.sprite_y = (demo.sprite_y + 3) % @max(@as(u32, 1), host.video.surface.height - 18);
    const next = spriteRect(demo.sprite_x, demo.sprite_y, host.video.surface.width, host.video.surface.height);
    paintRect(&host.video.surface, next, 15);
    host.video.invalidate(mergeDamage(old, next));
}

fn paintAnimationBand(surface: *host_api.Surface, frame: u32) void {
    const y = (frame * 11) % surface.height;
    paintRect(surface, .{ .x = 0, .y = y, .w = surface.width, .h = @min(@as(u32, 8), surface.height - y) }, (frame % 14) + 1);
}

fn paintPatternRect(surface: *host_api.Surface, rect: host_api.Rect, phase: u8) void {
    var y = rect.y;
    while (y < rect.y + rect.h) : (y += 1) {
        var x = rect.x;
        while (x < rect.x + rect.w) : (x += 1) {
            switch (surface.storage) {
                .indexed8 => |value| value.pixels[@as(usize, y) * @as(usize, surface.width) + x] = @intCast(((x / 32 + y / 24 + phase) % 14) + 1),
                .xrgb32 => |value| {
                    const red = (x * 255) / surface.width;
                    const green = (y * 255) / surface.height;
                    const blue = ((x / 20 + y / 20) & 1) * 96 + 48;
                    value[@as(usize, y) * @as(usize, surface.width) + x] = (red << 16) | (green << 8) | blue;
                },
            }
        }
    }
}

fn paintRect(surface: *host_api.Surface, requested: host_api.Rect, color: u32) void {
    if (requested.x >= surface.width or requested.y >= surface.height or requested.w == 0 or requested.h == 0) return;
    const right = @min(surface.width, requested.x +| requested.w);
    const bottom = @min(surface.height, requested.y +| requested.h);
    var y = requested.y;
    while (y < bottom) : (y += 1) {
        var x = requested.x;
        while (x < right) : (x += 1) {
            const offset = @as(usize, y) * @as(usize, surface.width) + x;
            switch (surface.storage) {
                .indexed8 => |value| value.pixels[offset] = @intCast(color & 0xFF),
                .xrgb32 => |value| value[offset] = palette[color & 0xFF] & 0x00FF_FFFF,
            }
        }
    }
}

fn spriteRect(x: u32, y: u32, width: u32, height: u32) host_api.Rect {
    return .{ .x = x, .y = y, .w = @min(@as(u32, 18), width - x), .h = @min(@as(u32, 18), height - y) };
}

fn borderDamage(width: u32, height: u32) host_api.Rect {
    return .{ .x = 0, .y = 0, .w = width, .h = height };
}

fn crosshairDamage(point: host_api.Point, width: u32, height: u32) host_api.Rect {
    const x = point.x -| 5;
    const y = point.y -| 5;
    return .{ .x = x, .y = y, .w = @min(@as(u32, 11), width - x), .h = @min(@as(u32, 11), height - y) };
}

fn mergeDamage(a: host_api.Rect, b: host_api.Rect) host_api.Rect {
    const x = @min(a.x, b.x);
    const y = @min(a.y, b.y);
    const right = @max(a.x + a.w, b.x + b.w);
    const bottom = @max(a.y + a.h, b.y + b.h);
    return .{ .x = x, .y = y, .w = right - x, .h = bottom - y };
}

fn inputSelfTest() bool {
    const viewport = host_api.calculateViewport(640, 400, 640, 350) catch return false;
    var translator = host_api.InputTranslator{};
    const focus = translator.translate(.{ .kind = @intFromEnum(r4os.abi.GuiEventKind.focus_gained), .tick = 1 }, viewport, null) orelse return false;
    if (!focus.focus.focused) return false;
    const key = translator.translate(.{ .kind = @intFromEnum(r4os.abi.GuiEventKind.key_down), .key = 'G', .tick = 2 }, viewport, null) orelse return false;
    if (key.key_down.code != 'G' or key.key_down.sequence != 2) return false;
    const text = translator.takePending() orelse return false;
    if (text.text.codepoint != 'G' or text.text.sequence != key.key_down.sequence) return false;
    const outside = translator.translate(.{ .kind = @intFromEnum(r4os.abi.GuiEventKind.mouse_move), .x = 1, .y = 1, .tick = 3 }, viewport, null) orelse return false;
    if (outside.mouse.guest != null) return false;
    const inside = translator.translate(.{ .kind = @intFromEnum(r4os.abi.GuiEventKind.mouse_down), .x = viewport.x, .y = viewport.y, .buttons = 1, .tick = 4 }, viewport, null) orelse return false;
    if (inside.mouse.guest == null or inside.mouse.guest.?.x != 0 or inside.mouse.guest.?.y != 0) return false;

    var basic = host_api.InputTranslator.init(.text_only_no_pointer);
    const basic_text = basic.translate(.{ .kind = @intFromEnum(r4os.abi.GuiEventKind.key_down), .key = 'G', .tick = 10 }, viewport, null) orelse return false;
    if (basic_text.text.codepoint != 'G' or basic_text.text.sequence != 1 or basic.takePending() != null) return false;
    if (basic.translate(.{ .kind = @intFromEnum(r4os.abi.GuiEventKind.mouse_move), .x = viewport.x, .y = viewport.y, .tick = 11 }, viewport, null) != null) return false;
    const basic_enter = basic.translate(.{ .kind = @intFromEnum(r4os.abi.GuiEventKind.key_down), .key = 13, .tick = 12 }, viewport, null) orelse return false;
    if (basic_enter.key_down.code != 13 or basic_enter.key_down.sequence != 3) return false;
    if (basic.stats.raw_events != 3 or basic.stats.logical_events != 2 or basic.stats.pointer_ignored != 1 or basic.stats.mouse_mappings != 0) return false;
    return true;
}

fn runtimeInputSelfTest(sys: *r4os.r4sys.Context, host: *host_api.Host) bool {
    var saw_resize = false;
    var saw_focus = false;
    var round: u32 = 0;
    while (round < 64) : (round += 1) {
        while (host.pollInput()) |event| {
            switch (event) {
                .resize => |resize| saw_resize = resize.viewport.guest_w == 640 and resize.viewport.guest_h == 350,
                .focus => |focus| saw_focus = saw_focus or focus.focused,
                .close => return false,
                else => {},
            }
        }
        if (saw_resize and saw_focus) return true;
        sys.taskYield();
    }
    return false;
}

fn presentSucceeded(result: host_api.PresentResult) bool {
    return switch (result) {
        .presented, .unchanged => true,
        else => false,
    };
}

fn presentedAs(result: host_api.PresentResult, mode: host_api.PresentMode) bool {
    return switch (result) {
        .presented => |info| info.mode == mode and info.raster_blocks != 0,
        else => false,
    };
}

fn presentInitialFullFrame(sys: *r4os.r4sys.Context, host: *host_api.Host) bool {
    // The spawned GUI task may be admitted after its window handle is set but
    // before Desktop has made the corresponding window visible. Keep the
    // admission race bounded while preserving persistent draw failures.
    var attempt: u32 = 0;
    while (attempt < 64) : (attempt += 1) {
        switch (host.present()) {
            .presented => |info| return info.mode == .full and info.raster_blocks != 0,
            .unchanged => return false,
            .hidden, .failure => sys.taskYield(),
        }
    }
    return false;
}

fn selfTestFail(sys: *r4os.r4sys.Context, reason: []const u8, code: i32) i32 {
    sys.write("SUBSYSTEM host selftest FAILED: ");
    sys.println(reason);
    writeSelfTestFailure(sys, "SUBSYSTEM host selftest FAILED: ", reason);
    return code;
}

fn writeSelfTestFailure(sys: *r4os.r4sys.Context, prefix: []const u8, reason: []const u8) void {
    var marker: [160]u8 = undefined;
    var pos: usize = 0;
    const prefix_count = @min(prefix.len, marker.len);
    @memcpy(marker[0..prefix_count], prefix[0..prefix_count]);
    pos += prefix_count;
    const reason_count = @min(reason.len, marker.len -| pos -| 4);
    if (reason_count != 0) @memcpy(marker[pos .. pos + reason_count], reason[0..reason_count]);
    pos += reason_count;
    if (pos + 4 <= marker.len) {
        marker[pos] = ' ';
        marker[pos + 1] = '[';
        marker[pos + 2] = if (active_selftest_variant == 2) 'B' else 'A';
        marker[pos + 3] = ']';
        pos += 4;
    }
    if (pos + 2 <= marker.len) {
        marker[pos] = '\r';
        marker[pos + 1] = '\n';
        pos += 2;
    }
    _ = sys.fileWrite(selftest_marker_path, marker[0..pos]);
}

fn equalsIgnoreCase(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    for (a, b) |left, right| {
        if (asciiLower(left) != asciiLower(right)) return false;
    }
    return true;
}

fn asciiLower(value: u8) u8 {
    return if (value >= 'A' and value <= 'Z') value + ('a' - 'A') else value;
}
