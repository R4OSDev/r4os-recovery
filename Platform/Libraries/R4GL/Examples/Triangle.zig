//! GL 3.3 Core triangle through public EGL and the ordinary Desktop window.
//! F toggles borderless fullscreen; Escape restores the window or closes it.
const std = @import("std");
const r = @import("r4os");
const gl = @import("r4gl");
const H = ?*anyopaque;
const Resolver = *const fn ([*:0]const u8) callconv(.c) ?*const anyopaque;
pub const Observer = *const fn ([]const u8) void;
const Functions = struct {
    eglGetDisplay: *const fn (H) callconv(.c) H,
    eglInitialize: *const fn (H, *i32, *i32) callconv(.c) u32,
    eglBindAPI: *const fn (u32) callconv(.c) u32,
    eglChooseConfig: *const fn (H, [*]const i32, *H, i32, *i32) callconv(.c) u32,
    eglCreateContext: *const fn (H, H, H, [*]const i32) callconv(.c) H,
    eglCreateWindowSurface: *const fn (H, H, H, ?[*]const i32) callconv(.c) H,
    eglMakeCurrent: *const fn (H, H, H, H) callconv(.c) u32,
    eglSwapBuffers: *const fn (H, H) callconv(.c) u32,
    eglQuerySurface: *const fn (H, H, i32, *i32) callconv(.c) u32,
    eglSwapInterval: *const fn (H, i32) callconv(.c) u32,
    eglTerminate: *const fn (H) callconv(.c) u32,
    eglDestroySurface: *const fn (H, H) callconv(.c) u32,
    eglDestroyContext: *const fn (H, H) callconv(.c) u32,
    eglGetError: *const fn () callconv(.c) u32,
    glGetString: *const fn (u32) callconv(.c) ?[*:0]const u8,
    glGetStringi: *const fn (u32, u32) callconv(.c) ?[*:0]const u8,
    glGetIntegerv: *const fn (u32, *i32) callconv(.c) void,
    glCreateShader: *const fn (u32) callconv(.c) u32,
    glShaderSource: *const fn (u32, i32, *const [*:0]const u8, ?*const i32) callconv(.c) void,
    glCompileShader: *const fn (u32) callconv(.c) void,
    glGetShaderiv: *const fn (u32, u32, *i32) callconv(.c) void,
    glDeleteShader: *const fn (u32) callconv(.c) void,
    glCreateProgram: *const fn () callconv(.c) u32,
    glAttachShader: *const fn (u32, u32) callconv(.c) void,
    glLinkProgram: *const fn (u32) callconv(.c) void,
    glGetProgramiv: *const fn (u32, u32, *i32) callconv(.c) void,
    glUseProgram: *const fn (u32) callconv(.c) void,
    glDeleteProgram: *const fn (u32) callconv(.c) void,
    glGenVertexArrays: *const fn (i32, *u32) callconv(.c) void,
    glBindVertexArray: *const fn (u32) callconv(.c) void,
    glDeleteVertexArrays: *const fn (i32, *const u32) callconv(.c) void,
    glViewport: *const fn (i32, i32, i32, i32) callconv(.c) void,
    glClearColor: *const fn (f32, f32, f32, f32) callconv(.c) void,
    glClear: *const fn (u32) callconv(.c) void,
    glDrawArrays: *const fn (u32, i32, i32) callconv(.c) void,
    glReadPixels: *const fn (i32, i32, i32, i32, u32, u32, *anyopaque) callconv(.c) void,
    glGetError: *const fn () callconv(.c) u32,
    fn init(resolve: Resolver) !Functions {
        var result: Functions = undefined;
        inline for (std.meta.fields(Functions)) |field| @field(result, field.name) = @ptrCast(resolve(field.name) orelse return error.MissingFunction);
        return result;
    }
};
fn require(value: bool) !void {
    if (!value) return error.Graphics;
}
fn emit(observer: ?Observer, text: []const u8) void {
    if (observer) |log| log(text);
}
pub fn r4_app_main(app: *r.App2) i32 {
    run(app, null) catch |err| {
        app.system().println(@errorName(err));
        return -1;
    };
    return 0;
}
pub fn run(app: *r.App2, observer: ?Observer) !void {
    const api = try gl.EglV1Client.init2(app.raw);
    const sys = app.system();
    var loader: gl.R4GlLoader = undefined;
    const native = std.mem.indexOf(u8, std.mem.span(sys.argsRaw()), "/ZINK") != null;
    try require(api.open(&.{ .version = 1, .size = @sizeOf(gl.R4GlRuntime), .application = @intFromPtr(app.raw), .profile = @intFromBool(native), .reserved = 0 }, &loader) == 0);
    const result = runOpened(app, loader, observer);
    const released = api.release_thread();
    const finished = api.finish(5_000_000_000);
    try result;
    try require(released == 0 and finished == 0);
    emit(observer, "GLTRIANGLE closed: OK");
}
fn runOpened(app: *r.App2, loader: gl.R4GlLoader, observer: ?Observer) !void {
    try runWindow(app, try Functions.init(@ptrFromInt(loader.get_proc_address)), observer);
}
fn runWindow(app: *r.App2, f: Functions, observer: ?Observer) !void {
    var timers: [0]r.Timer = .{};
    const sys = app.system();
    var win = r.Window.init(sys, app.desktop() orelse return error.NoDesktop, app.drawing() orelse return error.NoDrawing, &timers) orelse return error.NotHosted;
    _ = win.setTitle("OpenGL Triangle - F: fullscreen, Esc: back");
    _ = win.setMinimumSize(240, 180);
    var owner: r.abi.ProgramProcessHandle = .{};
    try require(sys.programOpenHandle(@intCast(app.raw.instance_id), &owner) == 0);
    var modes: r.window_mode.Client = .{ .owner = owner, .window_id = @intCast(win.id) };
    // EGL windows become available after Desktop publishes the real client
    // rectangle. There is no synthetic surface or private consumer here.
    const services: r.app_services.Services = .{ .sys = sys };
    var connection = switch (services.open("WINSVC")) {
        .connection => |c| c,
        else => return error.NoWindowService,
    };
    defer _ = connection.close();
    const deadline = sys.ticks() +| sys.ticksFromMilliseconds(5000);
    while (true) {
        const request: r.abi.WindowGraphicsRequest = .{ .owner = owner, .window_id = @intCast(win.id) };
        const response = connection.callTyped(r.abi.WindowGraphicsRequest, r.abi.WindowGraphicsReply, r.abi.window_graphics_op_client, &request, r.time_contract.timeoutFinite(r.time_contract.durationFromNanoseconds(250_000_000)));
        if (response == .value and response.value.result == r.abi.window_graphics_ok) break;
        if (sys.ticks() >= deadline) return error.WindowTimeout;
        sys.sleepTicks(1);
    }
    const display = f.eglGetDisplay(null);
    var major: i32 = 0;
    var minor: i32 = 0;
    try require(f.eglInitialize(display, &major, &minor) == 1);
    defer _ = f.eglTerminate(display);
    try require(major == 1 and minor >= 5 and f.eglBindAPI(0x30a2) == 1);
    var config: H = null;
    var count: i32 = 0;
    // This example explicitly uses interval zero. A different output may
    // offer synchronized configs while this window has a CPU consumer.
    try require(f.eglChooseConfig(display, &.{ 0x3033, 4, 0x3040, 8, 0x3024, 8, 0x3023, 8, 0x3022, 8, 0x303c, 0, 0x3038 }, &config, 1, &count) == 1 and count == 1);
    const context = f.eglCreateContext(display, config, null, &.{ 0x3098, 3, 0x30fb, 3, 0x30fd, 1, 0x3038 });
    try require(context != null);
    defer _ = f.eglDestroyContext(display, context);
    const surface = f.eglCreateWindowSurface(display, config, @ptrFromInt(@as(usize, @intCast(win.id))), null);
    try require(surface != null);
    defer _ = f.eglDestroySurface(display, surface);
    try require(f.eglMakeCurrent(display, surface, surface, context) == 1);
    defer _ = f.eglMakeCurrent(display, null, null, null);
    // The firmware fallback has no proven scanout clock. Interval zero is
    // explicit and applies to both software and optional native execution.
    try require(f.eglSwapInterval(display, 0) == 1);
    emit(observer, std.mem.span(f.glGetString(0x1f01) orelse return error.Renderer));
    emit(observer, std.mem.span(f.glGetString(0x1f02) orelse return error.Version));
    if (observer != null) {
        var extensions: i32 = 0;
        f.glGetIntegerv(0x821d, &extensions);
        if (extensions < 0 or extensions > 4096) return error.Extensions;
        for (0..@intCast(extensions)) |i| emit(observer, std.mem.span(f.glGetStringi(0x1f03, @intCast(i)) orelse return error.Extensions));
    }
    const vertex = f.glCreateShader(0x8b31);
    const fragment = f.glCreateShader(0x8b30);
    defer f.glDeleteShader(vertex);
    defer f.glDeleteShader(fragment);
    const vs: [*:0]const u8 = "#version 330 core\nvoid main(){vec2 p[3]=vec2[3](vec2(-0.75,-0.7),vec2(0.75,-0.7),vec2(0,0.8));gl_Position=vec4(p[gl_VertexID],0,1);}";
    const fs: [*:0]const u8 = "#version 330 core\nout vec4 color;void main(){color=vec4(0,1,0,1);}";
    f.glShaderSource(vertex, 1, &vs, null);
    f.glShaderSource(fragment, 1, &fs, null);
    f.glCompileShader(vertex);
    f.glCompileShader(fragment);
    var status: i32 = 0;
    f.glGetShaderiv(vertex, 0x8b81, &status);
    try require(status == 1);
    f.glGetShaderiv(fragment, 0x8b81, &status);
    try require(status == 1);
    const program = f.glCreateProgram();
    defer f.glDeleteProgram(program);
    f.glAttachShader(program, vertex);
    f.glAttachShader(program, fragment);
    f.glLinkProgram(program);
    f.glGetProgramiv(program, 0x8b82, &status);
    try require(status == 1);
    f.glUseProgram(program);
    defer f.glUseProgram(0);
    var vao: u32 = 0;
    f.glGenVertexArrays(1, &vao);
    defer f.glDeleteVertexArrays(1, &vao);
    f.glBindVertexArray(vao);
    var dirty = true;
    var framebuffer_width: i32 = 0;
    var framebuffer_height: i32 = 0;
    var resize_until = sys.ticks() +| sys.ticksFromMilliseconds(1000);
    while (!sys.programShouldClose()) {
        if (modes.pending != null) {
            _ = modes.poll(&sys);
            if (modes.pending != null) _ = modes.retry(&sys);
        }
        if (dirty or sys.ticks() < resize_until) {
            const info = win.info() orelse return error.NoGeometry;
            if (info.flags & r.abi.GuiWindowFlag.minimized == 0) {
                var width: i32 = 0;
                var height: i32 = 0;
                // EGL reports framebuffer pixels; GUI geometry is logical
                // and can differ on a scaled output. Briefly recheck after a
                // resize event while Desktop publishes its new image extent.
                try require(f.eglQuerySurface(display, surface, 0x3057, &width) == 1 and f.eglQuerySurface(display, surface, 0x3056, &height) == 1);
                if (width <= 0 or height <= 0) return error.NoGeometry;
                dirty = dirty or width != framebuffer_width or height != framebuffer_height;
                if (dirty) {
                    framebuffer_width = width;
                    framebuffer_height = height;
                    f.glViewport(0, 0, width, height);
                    f.glClearColor(0.04, 0.06, 0.12, 1);
                    f.glClear(0x4000);
                    f.glDrawArrays(4, 0, 3);
                    var pixel: [4]u8 = undefined;
                    if (observer != null) {
                        f.glReadPixels(@divTrunc(width, 2), @divTrunc(height, 2), 1, 1, 0x1908, 0x1401, &pixel);
                    }
                    try require(f.glGetError() == 0);
                    var current_width: i32 = 0;
                    var current_height: i32 = 0;
                    try require(f.eglQuerySurface(display, surface, 0x3057, &current_width) == 1 and
                        f.eglQuerySurface(display, surface, 0x3056, &current_height) == 1);
                    // Desktop can publish a resize while native rendering
                    // runs. Pixels and the old viewport are then undefined
                    // for the new drawable. Repaint before claiming a frame;
                    // a mismatch at the same extent remains a real error.
                    if (current_width != width or current_height != height) {
                        // Return the rendered native image through its normal
                        // WSI handoff before revalidating the new drawable.
                        try require(f.eglSwapBuffers(display, surface) == 1);
                        emit(observer, "GLTRIANGLE drawable resized during rendering; repaint pending");
                        dirty = true;
                        resize_until = sys.ticks() +| sys.ticksFromMilliseconds(1000);
                        sys.sleepTicks(1);
                        continue;
                    }
                    if (observer != null)
                        try require(std.mem.eql(u8, &pixel, &.{ 0, 255, 0, 255 }));
                    try require(f.glGetError() == 0 and f.eglSwapBuffers(display, surface) == 1);
                    var buffer: [160]u8 = undefined;
                    emit(observer, try std.fmt.bufPrint(&buffer, "GLTRIANGLE frame mode={s} client={d},{d},{d},{d} framebuffer={d},{d} pixel=green", .{ if (info.flags & r.abi.gui_window_flag_fullscreen != 0) @as([]const u8, "fullscreen") else "windowed", info.client_x, info.client_y, info.client_w, info.client_h, width, height }));
                }
            }
            dirty = false;
        }
        const timeout: r.abi.R4Timeout = if (modes.pending != null or sys.ticks() < resize_until) .{ .kind = r.abi.timeout_kind_finite, .nanoseconds = 20_000_000 } else .{ .kind = r.abi.timeout_kind_forever };
        switch (win.waitMessage(timeout)) {
            .message => |message| switch (message) {
                .close => break,
                .resize => {
                    dirty = true;
                    resize_until = sys.ticks() +| sys.ticksFromMilliseconds(1000);
                },
                .key => |key| {
                    if (key.key == 'f' or key.key == 'F' or key.key == 27) {
                        _ = modes.poll(&sys);
                        const full = modes.state.mode == 1;
                        if (key.key == 27 and !full) break;
                        if (modes.last_error == 0 and modes.pending == null) _ = modes.set(&sys, if (full) .windowed else .fullscreen);
                    }
                },
                else => {},
            },
            .timed_out => {},
            .failure => return error.Events,
        }
    }
}
