const std = @import("std");
const r4os = @import("r4os");
const video = r4os.subsystem_host;
const rt = r4os.subsystem_runtime;
const saves = r4os.subsystem_persistence;
var reported_work: [6]u64 = .{0} ** 6;
var reported_video: u64 = 0;
var scratch: [video.tile_max_pixels]u32 = undefined;
const Model = struct {
    steps: u64 = 0,
    operations: u64 = 0,
    resets: u64 = 0,
    presents: u64 = 0,
    checksum: u64 = 0,
    now: u64 = 0,
    audio_byte: u8 = 0,
    opens: u64 = 0,
    writes: u64 = 0,
    closes: u64 = 0,
    pixels: [256]u32 = .{0} ** 256,
    fn from(p: *anyopaque) *Model {
        return @ptrCast(@alignCast(p));
    }
    fn step(p: *anyopaque, budget: u32, now: u64) rt.StepResult {
        const self = from(p);
        self.steps += 1;
        self.operations += budget;
        self.now = now;
        for (0..budget) |i| self.checksum = self.checksum *% 33 +% self.steps *% 7 +% @as(u64, @intCast(i));
        return rt.StepResult.progress(true).withOperations(budget);
    }
    fn reset(p: *anyopaque) i32 {
        from(p).resets += 1;
        return 0;
    }
    fn audio(p: *anyopaque, out: []u8) i32 {
        @memset(out, from(p).audio_byte);
        return @intCast(out.len);
    }
    fn guest(self: *Model) rt.GuestDriver {
        return .{ .context = self, .step_fn = step, .reset_fn = reset, .render_audio_fn = audio };
    }
    fn poll(_: *anyopaque) rt.HostPollResult {
        return .idle;
    }
    fn present(p: *anyopaque) i32 {
        from(p).presents += 1;
        return rt.host_presented;
    }
    fn host(self: *Model) rt.HostDriver {
        return .{ .context = self, .poll_fn = poll, .present_fn = present };
    }
    fn open(p: *anyopaque, _: rt.AudioConfig) i32 {
        from(p).opens += 1;
        return 0;
    }
    fn write(p: *anyopaque, _: []const u8) i32 {
        from(p).writes += 1;
        return -77;
    }
    fn volume(_: *anyopaque, _: u32) i32 {
        return 0;
    }
    fn close(p: *anyopaque) i32 {
        from(p).closes += 1;
        return 0;
    }
    fn sink(self: *Model) rt.AudioSink {
        return .{ .context = self, .open_fn = open, .write_fn = write, .volume_fn = volume, .close_fn = close };
    }
    fn begin(_: *anyopaque) i32 {
        return 0;
    }
    fn damage(_: *anyopaque, _: []const r4os.abi.DisplayDamageRect) i32 {
        return 0;
    }
    fn clear(p: *anyopaque, rgb: u32) i32 {
        @memset(&from(p).pixels, rgb);
        return 0;
    }
    fn raster(p: *anyopaque, x: i32, y: i32, w: u32, h: u32, scale: u32, pixels: []const u32) i32 {
        if (pixels.len != @as(usize, w) * h or x < 0 or y < 0) return -65;
        const self = from(p);
        for (0..h) |py| for (0..w) |px| for (0..scale) |sy| for (0..scale) |sx| {
            const dx = @as(usize, @intCast(x)) + px * scale + sx;
            const dy = @as(usize, @intCast(y)) + py * scale + sy;
            if (dx >= 16 or dy >= 16) return -66;
            self.pixels[dy * 16 + dx] = pixels[py * w + px];
        };
        return 0;
    }
    fn indexed(_: *anyopaque, _: video.IndexedBatch) i32 {
        return -67;
    }
    fn backend(self: *Model) video.Backend {
        return .{ .context = self, .begin_full_fn = begin, .begin_damage_fn = damage, .clear_fn = clear, .raster_fn = raster, .indexed8_fn = indexed, .commit_full_fn = begin, .commit_damage_fn = begin, .cancel_fn = begin };
    }
};
fn require(ok: bool) !void {
    if (!ok) return error.OracleMismatch;
}
const SaveConfig = struct {
    pub const save_root = "C:\\TEMP\\SP65Z\\";
    pub const root_directories: []const []const u8 = &.{ "C:\\TEMP", "C:\\TEMP\\SP65Z" };
    pub const rtc_record_bytes: usize = 0;
    pub fn validateRtc(_: []const u8) bool {
        return false;
    }
};
var installed_bytes: [256 * 1024]u8 = undefined;
var installed_inventory: r4os.system_update_inventory.Inventory = undefined;
var installed_catalog: r4os.subsystem_catalog.Catalog = undefined;
var installed_resolution: r4os.subsystem_catalog.Resolution = undefined;
fn verifyInstalled(ctx: ?*anyopaque, target: []const u8) r4os.subsystem_catalog.HostState {
    const sys: *r4os.r4sys.Context = @ptrCast(@alignCast(ctx.?));
    var buffer: [256]u8 = undefined;
    const text = std.fmt.bufPrint(&buffer, "C:{s}", .{target}) catch return .failed;
    const path = r4os.AbsoluteFilePath.parse(text) catch return .failed;
    const files = r4os.app_storage.Files{ .sys = sys.* };
    return switch (files.info(path.asZ())) {
        .value => |info| if (info.is_dir == 0) .present else .missing,
        .missing => .missing,
        .failure => .failed,
    };
}
fn checkInstalled(sys: *r4os.r4sys.Context, source: []const u8) !void {
    const count = sys.fileRead("C:\\R4OS\\CONFIG\\MODULES.JSON", &installed_bytes);
    try require(count > 0 and count < installed_bytes.len);
    try r4os.subsystem_catalog.Catalog.loadInstalled(installed_bytes[0..@intCast(count)], &installed_inventory, &installed_catalog, .{ .context = sys, .check = verifyInstalled });
    const associations = [_]r4os.subsystem_catalog.Association{.{ .extension = ".s65", .subsystem_id = "test.sdk65.zig", .format_id = "test.synthetic" }};
    try r4os.subsystem_catalog.resolve(&installed_catalog, .{ .path = "C:\\TEMP\\SYNTH65.S65", .probe_prefix = source, .file_size = 4, .probe_window_complete = true }, .{ .user_associations = &associations }, &installed_resolution);
    const selected = installed_resolution.selected() orelse return error.NoSelectedHost;
    try require(std.mem.eql(u8, selected.subsystem_id, "test.sdk65.zig") and std.mem.eql(u8, selected.host_path, "/R4OS/SUBSYSTEMS/test.sdk65.zig/SP65Z.R4X"));
    sys.println("SDK65 CATALOG source=MODULES.JSON verified=1 format=test.synthetic");
}
fn run(app: *r4os.App) !void {
    var sys = app.system();
    const request = try r4os.subsystem_launch.parse(app.args());
    try require(std.mem.eql(u8, request.guest_path, "C:\\TEMP\\SYNTH65.S65"));
    var source: [4]u8 = undefined;
    try require(sys.fileRead("C:\\TEMP\\SYNTH65.S65", &source) == 4 and std.mem.eql(u8, &source, "S65!"));
    try checkInstalled(&sys, &source);
    var model = Model{};
    const guest = model.guest();
    const host = model.host();
    var runtime = try rt.Runtime.init(.{ .slice_budget = 4, .max_input_events = 4, .max_wait_ticks = 8, .idle_retry_ticks = 1 }, 1000, 0, null);
    _ = runtime.cycle(10, guest, host);
    runtime.request(.pause, 10, guest);
    _ = runtime.cycle(40, guest, host);
    try require(model.steps == 1);
    runtime.request(.resume_running, 40, guest);
    _ = runtime.cycle(50, guest, host);
    runtime.request(.reset, 50, guest);
    _ = runtime.cycle(60, guest, host);
    runtime.request(.close, 70, guest);
    _ = runtime.cycle(70, guest, host);
    runtime.shutdown();
    runtime.shutdown();
    try require(model.steps == 3 and model.operations == 12 and model.resets == 1 and model.presents == 3 and model.now == 10_000_000 and runtime.state == .closed);
    reported_work = .{ model.steps, model.operations, model.resets, model.presents, model.checksum, model.now };
    var line: [256]u8 = undefined;
    sys.println(try std.fmt.bufPrint(&line, "SDK65 WORK steps={d} ops={d} resets={d} presents={d} checksum={d} time_ns={d}", .{ model.steps, model.operations, model.resets, model.presents, model.checksum, model.now }));
    var pixels = [_]u32{ 1, 2, 3, 4, 5, 6 };
    var recorded = Model{};
    const surface = try video.Surface.initXrgb32(&pixels, 3, 2);
    var painter = try video.Presenter.init(surface, &scratch);
    try require(painter.presentTo(recorded.backend(), 6, 4) == .presented);
    try require(painter.presentTo(recorded.backend(), 6, 4) == .unchanged);
    for (0..4) |y| for (0..6) |x| try require(recorded.pixels[y * 16 + x] == pixels[(y / 2) * 3 + x / 2]);
    pixels[1] = 17;
    painter.invalidate(.{ .x = 1, .y = 0, .w = 1, .h = 1 });
    try require(painter.presentTo(recorded.backend(), 6, 4) == .presented);
    try require(painter.presentTo(recorded.backend(), 8, 8) == .presented);
    painter.deinit(recorded.backend());
    var image_hash: u64 = 0;
    for (recorded.pixels) |rgb| image_hash = image_hash *% 33 +% rgb;
    reported_video = image_hash;
    sys.println(try std.fmt.bufPrint(&line, "SDK65 VIDEO checksum={d}", .{image_hash}));
    var audio_model = Model{ .audio_byte = 0x22 };
    var queue: [16]u8 = undefined;
    var audio_scratch: [8]u8 = undefined;
    var audio_runtime = try rt.Runtime.init(.{ .slice_budget = 4, .max_input_events = 4, .max_wait_ticks = 8, .idle_retry_ticks = 1 }, 1000, 0, .{ .config = .{ .sample_rate = 1000, .channels = 1, .quantum_frames = 4, .target_quanta = 2 }, .queue_storage = &queue, .scratch = &audio_scratch, .sink = audio_model.sink() });
    for ([_]u64{ 10, 20, 30 }) |tick| _ = audio_runtime.cycle(tick, audio_model.guest(), audio_model.host());
    try require(audio_runtime.audio.state == .degraded and audio_runtime.audio.last_error == -77 and audio_model.steps == 3 and audio_model.now == 20_000_000);
    audio_runtime.request(.close, 40, audio_model.guest());
    _ = audio_runtime.cycle(40, audio_model.guest(), audio_model.host());
    audio_runtime.shutdown();
    try require(audio_model.opens == 1 and audio_model.writes == 1 and audio_model.closes == 1);
    const engine = saves.R4osStore(SaveConfig);
    const files = r4os.app_storage.Files{ .sys = sys };
    var first = engine.Store.init(files);
    var second = engine.Store.init(files);
    const a = first.backend();
    const b = second.backend();
    var digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(&source, &digest, .{});
    try a.acquire(&digest, 5);
    if (b.acquire(&digest, 6)) |_| return error.ForeignLeaseAccepted else |err| try require(err == error.Busy);
    try a.writeAtomic(&digest, .sram, &source);
    var output: [4]u8 = undefined;
    try require(a.readExact(&digest, .sram, &output) == .ok and std.mem.eql(u8, &source, &output));
    if (a.release(&digest, 6)) |_| return error.StaleReleaseAccepted else |_| {}
    try a.release(&digest, 5);
    try b.acquire(&digest, 6);
    try require(b.readExact(&digest, .sram, &output) == .ok and std.mem.eql(u8, &source, &output));
    try b.release(&digest, 6);
    second.removeTestFiles(&digest);
    var arena: [8192]u8 = undefined;
    var allocator = std.heap.FixedBufferAllocator.init(&arena);
    var async_store = engine.AsyncStore.init(files, allocator.allocator());
    const async_backend = async_store.backend();
    try async_backend.acquire(&digest, 7);
    try async_backend.writeAtomic(&digest, .sram, &source);
    try async_backend.drain();
    try require(!async_backend.pending());
    try require(async_backend.readExact(&digest, .sram, &output) == .ok and std.mem.eql(u8, &source, &output));
    try async_backend.release(&digest, 7);
    try require(async_store.stats.enqueued == 1 and async_store.stats.started == 1 and async_store.stats.completed == 1);
    async_store.removeTestFiles(&digest);
    const desk = app.desktop() orelse return error.MissingDesk;
    const draw = app.drawing() orelse return error.MissingDraw;
    var info: r4os.abi.GuiWindowInfo = .{};
    var ready = false;
    for (0..100) |_| {
        if (desk.guiWindowInfo(&info) >= 0 and info.client_w > 0 and info.client_h > 0) {
            ready = true;
            break;
        }
        sys.sleepTicks(1);
    }
    try require(ready);
    var actual = try video.Host.init(desk, draw, surface, &scratch);
    _ = actual.setTitle("SDK65 Zig synthetic subsystem");
    try require(actual.present() == .presented);
    actual.video.deinit(video.Backend.fromDraw(&draw));
    sys.println("PASS SDK65 Zig guest: canonical launch, same work/video, audio failure, real owned save/reopen/async join and window");
}
pub fn r4_app_main(app: *r4os.App) i32 {
    var code: i32 = 0;
    run(app) catch |err| {
        app.system().write("FAIL SDK65 Zig: ");
        app.system().println(@errorName(err));
        code = 1;
    };
    var out: [512]u8 = undefined;
    const text = std.fmt.bufPrint(&out, "CODE={d}\nWORK={d},{d},{d},{d},{d},{d}\nVIDEO={d}\n", .{ code, reported_work[0], reported_work[1], reported_work[2], reported_work[3], reported_work[4], reported_work[5], reported_video }) catch return 198;
    if (app.system().fileWrite("C:\\TEMP\\S65Z.OUT", text) != @as(i32, @intCast(text.len))) return 197;
    return code;
}
