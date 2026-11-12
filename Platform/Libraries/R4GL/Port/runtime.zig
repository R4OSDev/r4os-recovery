// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const std = @import("std");
const r = @import("r4os");
const vk = @import("r4vk");
const native = @import("r4native");
const a = r.abi;
const memory = native.memory.Runtime(native.memory.Unscoped);
const options = native.options.Runtime(memory);
const finalizers = native.finalizers.Runtime(memory);
const lifecycle = native.thread_lifecycle.Runtime(memory, releaseApiThread);
const State = struct {
    phase: std.atomic.Value(u32) = .init(0), // ready, finishing, closed
    finishing: std.atomic.Value(bool) = .init(false),
    io_error: bool = false,
    profile: ?u32 = null,
    vulkan: ?VulkanProc = null,
};
var state_key: u8 = 0;
var kernel_bound: std.atomic.Value(bool) = .init(false);
fn initialize(value: *State) void { value.* = .{}; }
fn state() ?*State { return native.process_local.getOrCreate(State, &state_key, initialize); }

const VulkanProc = *const fn (?*anyopaque, [*:0]const u8) callconv(.c) ?*const anyopaque;
pub fn bind(raw_address: u64, profile: u32) bool {
    if (profile > 1) return false;
    const input = native.caller.Input.init(raw_address) catch return false;
    const client: ?vk.VulkanV1Client = if (profile == 1) switch (input) {
        .legacy => |view| vk.VulkanV1Client.init(view.raw) catch return false,
        .generation2 => |view| vk.VulkanV1Client.init2(view.raw) catch return false,
    } else null;
    const vulkan_runtime: vk.R4VkRuntime = switch (input) {
        .legacy => |view| block: {
            const sys = view.sys orelse return false;
            if (sys.abi_version < 23 or view.draw == null or view.dev == null) return false;
            inline for (.{ "program_exit", "cpu_capacity", "vm_reserve", "vm_commit", "vm_release", "program_local_get", "program_local_publish" }) |field|
                if (!native.system.reaches(sys, field)) return false;
            if (!native.threads.bind(sys) or !native.application.bind(view.raw) or !native.system_info.bind(view.dev.?)) return false;
            break :block .{ .version = 1, .size = @sizeOf(vk.R4VkRuntime), .sys = @intFromPtr(sys),
                .draw = @intFromPtr(view.draw.?), .dev = @intFromPtr(view.dev.?) };
        },
        .generation2 => |view| block: {
            const sys = view.system() orelse return false;
            if (view.drawing() == null or view.devices() == null) return false;
            inline for (.{ "program_exit", "cpu_capacity" }) |field|
                if (!native.system.reaches(sys, field)) return false;
            if (!native.threads.bind2(sys) or !native.application.bind2(view.raw) or !native.system_info.bind2(view.devices().?)) return false;
            break :block .{ .version = 2, .size = @sizeOf(vk.R4VkRuntime), .sys = raw_address, .draw = 0, .dev = 0 };
        },
    };
    kernel_bound.store(true, .release);
    if (!lifecycle.bind()) return false;
    const value = state() orelse return false;
    if (value.phase.load(.acquire) != 0) return false;
    if (value.profile) |old| return old == profile;
    if (client) |vulkan| {
        var loader: vk.R4VkLoader = undefined;
        if (vulkan.open(&vulkan_runtime, &loader) != vk.success or
            loader.version != 1 or loader.size < @sizeOf(vk.R4VkLoader) or
            loader.get_instance_proc_addr == 0) return false;
        value.vulkan = @ptrFromInt(loader.get_instance_proc_addr);
    }
    value.profile = profile;
    return true;
}

export fn r4gl_native_profile() callconv(.c) u32 {
    return (state() orelse return 0).profile orelse 0;
}
// The native path binds one ICD directly and has no loader-installed layers.
// This command is a loader responsibility, so supply its truthful empty list.
fn enumerateLayers(count: *u32, _: ?*anyopaque) callconv(.c) i32 {
    count.* = 0;
    return 0;
}
export fn r4gl_native_vulkan_proc(instance: ?*anyopaque, name: [*:0]const u8) callconv(.c) ?*const anyopaque {
    const value = state() orelse return null;
    const proc = value.vulkan orelse return null;
    if (std.mem.eql(u8, std.mem.span(name), "vkEnumerateInstanceLayerProperties")) return @ptrCast(&enumerateLayers);
    return proc(instance, name);
}

pub fn ready() bool {
    if (!kernel_bound.load(.acquire)) return false;
    if (native.application.snapshot() == null) return false;
    const value = (native.process_local.lookup(State, &state_key) catch return false) orelse return false;
    return value.phase.load(.acquire) == 0;
}
extern fn eglReleaseThread() callconv(.c) u32;
extern fn r4gl_window_finish(deadline_ns: u64) callconv(.c) bool;
extern fn r4native_stdio_finish() callconv(.c) c_int;
fn releaseApiThread() bool { return eglReleaseThread() != 0; }
pub fn releaseThread() bool {
    if (!kernel_bound.load(.acquire)) return false;
    if (native.application.snapshot() == null) return false;
    const value = (native.process_local.lookup(State, &state_key) catch return false) orelse return false;
    if (value.phase.load(.acquire) == 2) return true;
    return lifecycle.finishCurrent();
}

// Caller has stopped/joined its GL threads, destroyed its objects and terminated
// displays. A retry continues retirement; it never frees storage still read by
// WINSVC/Desktop. No runtime owner lock spans foreign finalizers or service I/O.
pub fn finish(timeout_ns: u64) i32 {
    if (!kernel_bound.load(.acquire)) return -1;
    if (native.application.snapshot() == null) return -1;
    const value = (native.process_local.lookup(State, &state_key) catch return -1) orelse return -1;
    if (value.finishing.swap(true, .acq_rel)) return -2;
    defer value.finishing.store(false, .release);
    if (value.phase.load(.acquire) == 2) return if (value.io_error) -3 else 0;
    value.phase.store(1, .release);
    if (!lifecycle.closeAdmission() or !lifecycle.finishCurrent()) return -2;
    const now = native.time.read() orelse return -2;
    if (!r4gl_window_finish(now.instant_ns +| @min(timeout_ns, 5_000_000_000))) return -2;
    if ((lifecycle.liveWorkers() orelse return -2) != 0 or
        (native.thread_local.liveThreadCount() orelse return -2) != 0) return -2;
    if (!finalizers.finish()) return -2;
    const closed = r4native_stdio_finish();
    if (closed < 0) return -2;
    value.io_error = value.io_error or closed != 0;
    if (!options.closeAfterUsersStop() or !native.thread_local.releaseCurrent()) return -2;
    value.phase.store(2, .release);
    return if (value.io_error) -3 else 0;
}

pub fn fatal(message: [*:0]const u8, code: i32) noreturn {
    _ = r4native_console_write(message, @intCast(std.mem.len(message)));
    const call = native.system.required("program_exit");
    _ = call(code, a.program_exit_reason_failed);
    // Only a violated kernel calling-context contract can return here.
    @trap();
}
comptime {
    _ = native.math; _ = native.files; _ = native.time;
    _ = native.wall_clock; _ = native.system_info;
}
export fn malloc(n: usize) callconv(.c) ?*anyopaque { return memory.malloc(n); }
export fn calloc(n: usize, size: usize) callconv(.c) ?*anyopaque { return memory.calloc(n, size); }
export fn realloc(p: ?*anyopaque, n: usize) callconv(.c) ?*anyopaque { return memory.realloc(p, n); }
export fn reallocarray(p: ?*anyopaque, n: usize, size: usize) callconv(.c) ?*anyopaque { return memory.reallocarray(p, n, size); }
export fn free(p: ?*anyopaque) callconv(.c) void { memory.free(p); }
export fn aligned_alloc(a_: usize, n: usize) callconv(.c) ?*anyopaque { return memory.aligned_alloc(a_, n); }
export fn posix_memalign(p: *?*anyopaque, alignment: usize, n: usize) callconv(.c) c_int { return memory.posix_memalign(p, alignment, n); }
export fn rand() callconv(.c) c_int { return native.random.next() catch fatal("R4GL: random state unavailable\n", -1); }
export fn srand(value: c_uint) callconv(.c) void { native.random.seed(value) catch fatal("R4GL: random state unavailable\n", -1); }
export fn r4gl_cpu_capacity(available: *u32, configured: *u32) callconv(.c) c_int {
    const capacity = native.process.cpuCapacity() orelse return 0;
    available.* = capacity.available_cpus; configured.* = capacity.configured_cpus;
    return 1;
}
export fn r4gl_native_startup_trace(message: [*:0]const u8) callconv(.c) void {
    // Read the caller's environment directly: this also works inside the
    // initializer of a different process-local Mesa object without recursion.
    var value: [4]u8 = undefined;
    const enabled = native.process.environmentValue("R4GL_STARTUP_TRACE", &value) catch return;
    if (!std.mem.eql(u8, enabled, "1")) return;
    const sys = (native.application.snapshot() orelse return).system();
    sys.println(std.mem.span(message));
}
export fn r4gl_native_runtime_trace(stage: [*:0]const u8) callconv(.c) void {
    var value: [4]u8 = undefined;
    const enabled = native.process.environmentValue("R4GL_STARTUP_TRACE", &value) catch return;
    if (!std.mem.eql(u8, enabled, "1")) return;
    const now = native.time.read() orelse return;
    const sys = (native.application.snapshot() orelse return).system();
    var line: [256]u8 = undefined;
    const text = std.fmt.bufPrint(&line, "R4GL RUNTIME stage={s} instant-ns={d}",
        .{ std.mem.span(stage), now.instant_ns }) catch return;
    sys.println(text);
}
export fn r4gl_process_exec_path(out: [*]u8, capacity: usize) callconv(.c) usize {
    return (native.process.modulePath(out[0..capacity]) orelse return 0).len;
}
export fn os_get_option(name: [*:0]const u8) callconv(.c) ?[*:0]const u8 {
    return if (options.get(std.mem.span(name)) catch return null) |text| text.ptr else null;
}
export fn os_get_option_cached(name: [*:0]const u8) callconv(.c) ?[*:0]const u8 {
    return if (options.getCached(std.mem.span(name)) catch return null) |text| text.ptr else null;
}
export fn os_get_option_secure(name: [*:0]const u8) callconv(.c) ?[*:0]const u8 { return os_get_option(name); }
export fn r4native_console_write(bytes: [*]const u8, count: u32) callconv(.c) i32 {
    const call = native.system.required("write");
    return call(bytes, count);
}
export fn os_log_message(message: [*:0]const u8) callconv(.c) void { _ = r4native_console_write(message, @intCast(std.mem.len(message))); }
export fn r4gl_process_state(key: *const anyopaque, bytes: usize, alignment: usize, callback: native.process_local.Initializer) callconv(.c) *anyopaque {
    return native.process_local.initializedBlob(key, bytes, alignment, callback) orelse fatal("R4GL: process state unavailable\n", -1);
}
export fn __emutls_get_address(control: *const native.thread_local.Control) callconv(.c) *anyopaque {
    return native.thread_local.getAddress(control) orelse fatal("R4GL: thread state unavailable\n", -1);
}
export fn abort() callconv(.c) noreturn { fatal("R4GL: native abort\n", -1); }
export fn exit(code: c_int) callconv(.c) noreturn { fatal("R4GL: native runtime exit\n", code); }
export fn r4nak_port_assert(message: [*:0]const u8, _: [*:0]const u8, _: c_int) callconv(.c) noreturn { fatal(message, -1); }
export var __dso_handle: usize = 0;
export fn __cxa_thread_atexit(callback: *const fn (?*anyopaque) callconv(.c) void, arg: ?*anyopaque, _: ?*anyopaque) callconv(.c) c_int {
    return if (lifecycle.registerDestructor(callback, arg)) 0 else -1;
}
export fn __cxa_thread_atexit_impl(callback: *const fn (?*anyopaque) callconv(.c) void, arg: ?*anyopaque, dso: ?*anyopaque) callconv(.c) c_int {
    return __cxa_thread_atexit(callback, arg, dso);
}
export fn r4native_cpp_state(key: *const anyopaque, bytes: usize, alignment: usize, callback: native.process_local.Initializer) callconv(.c) ?*anyopaque {
    return native.process_local.initializedBlob(key, bytes, alignment, callback);
}
export fn r4native_register_finalizer(callback: finalizers.PlainCallback) callconv(.c) c_int { return if (finalizers.registerPlain(callback)) 0 else -1; }
export fn r4native_fatal(message: [*:0]const u8) callconv(.c) noreturn { fatal(message, -1); }

const Draw = extern struct { table: ?*const a.R4XStartR4Draw = null, generation2: ?*const r.platform2.CView = null };
export fn r4gl_native_application(raw_address: *u64, draw: *Draw) callconv(.c) bool {
    const saved = native.application.snapshot() orelse return false;
    switch (saved.*) {
        .legacy => draw.* = .{ .table = saved.legacy.bundle.draw orelse return false },
        .generation2 => {
            if (saved.generation2.context.drawing() == null) return false;
            draw.* = .{ .generation2 = &saved.generation2.c_view };
        },
    }
    raw_address.* = saved.address();
    return true;
}
// A FIFO broker queue alone cannot promise a video-frame interval. Read the
// exact output capability; never synthesize VBlank from wall-clock sleeps.
fn synchronizedOutput(info: a.DisplayPresentationInfo, head: usize) bool {
    const needed = a.display_presentation_info_active | a.display_presentation_info_synchronized;
    return info.version == 1 and info.size >= @sizeOf(a.DisplayPresentationInfo) and info.head_id == head and
        info.flags & needed == needed and info.flags & a.display_presentation_info_lost == 0 and
        info.policies & 1 != 0 and info.interval_ns != 0 and info.interval_ns <= std.time.ns_per_s and
        info.display_generation != 0 and info.sequence != 0;
}
export fn r4gl_window_swap_limit(raw_address: u64, config: ?*const a.WindowGraphicsConfig) callconv(.c) i32 {
    const input = native.caller.Input.init(raw_address) catch return 0;
    const draw: r.r4draw.Context = .{ .base = input.base() };
    for (0..a.gfx_output_max_assignments) |index| {
        var target: a.GfxOutputTarget = .{};
        var info: a.DisplayPresentationInfo = .{};
        if (config) |window| {
            if (window.present_modes & a.window_graphics_fifo == 0) return 0;
            if (draw.displayOutputTarget(window.output.adapter_id, @intCast(index), &target) != a.gfx_output_ok) continue;
            if (target.connector_id != window.output.connector_id or target.device_generation != window.output.device_generation or
                target.connection_generation != window.output.connection_generation or target.display_generation != window.display_generation) continue;
            if (draw.displayOutputPresentationInfo(&target, &info) != a.gfx_output_ok) return 0;
        } else {
            if (draw.displayPresentationInfo(@intCast(index), &info) != a.gfx_output_ok) continue;
        }
        if (synchronizedOutput(info, index)) return 1;
    }
    // EGL config discovery precedes choosing a window. Additional native
    // outputs can synchronize even when the primary output is bootfb.
    // Surface creation/presentation still validates the exact window target.
    if (config == null) for (1..a.gfx_queue_backend_capacity) |backend_index| {
        var backend: a.GfxBackendInfo = .{};
        if (draw.queues().backendInfo(@intCast(backend_index), &backend) != a.gfx_queue_ok or
            backend.binding.adapter_id == 0) continue;
        for (0..a.gfx_output_max_assignments) |head| {
            var target: a.GfxOutputTarget = .{};
            var info: a.DisplayPresentationInfo = .{};
            if (draw.displayOutputTarget(backend.binding.adapter_id, @intCast(head), &target) != a.gfx_output_ok or
                target.device_generation != backend.binding.device_generation) continue;
            if (draw.displayOutputPresentationInfo(&target, &info) == a.gfx_output_ok and
                info.display_generation == target.display_generation and
                std.meta.eql(info.backend, backend.binding) and synchronizedOutput(info, head)) return 1;
        }
    };
    return 0;
}
export fn r4gl_native_now() callconv(.c) u64 { return @intCast(native.time.os_time_get_nano()); }
export fn r4gl_window_query(raw_address: u64, id: u32, expected: ?*const a.WindowGraphicsSurface, out: *a.WindowGraphicsReply) callconv(.c) i32 {
    return native.window.query(raw_address, id, expected, out);
}
export fn r4gl_window_request(raw_address: u64, request: *const a.WindowGraphicsRequest, out: *a.WindowGraphicsReply) callconv(.c) bool {
    return native.window.request(raw_address, request, out);
}
export fn r4gl_window_service_dead(raw_address: u64, service: *const a.ProgramProcessHandle) callconv(.c) bool { return native.window.service_dead(raw_address, service); }
export fn r4gl_window_wait(raw_address: u64, owner: *const a.ProgramProcessHandle, revision: u64, ns: u64) callconv(.c) void { native.window.wait(raw_address, owner, revision, ns); }
