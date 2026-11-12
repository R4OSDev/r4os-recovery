//! Concrete public helper specializations. The original owner still performs
//! all display admission, mode/resource cleanup and Matroska/ICC processing.
const std = @import("std");
const r4os = @import("r4os");
const a = r4os.abi;
const m = @import("consumer_media.zig");
const g = m.gfx_api;
const Draw = r4os.r4draw.Context;
const Sys = r4os.r4sys.Context;
const Receiver = m.r4gfx_edid.Report;
const color = m.r4gfx_color_signal;
const Ctl = m.r4gfx_mode_control.Controller;

/// Library-owned C/Rust bridge to the same App2 worker implementations.
/// Keep this value and the kernel start record at stable addresses until
/// every derived worker has joined. No private Zig App layout is cast from C.
pub const CompilerContext2 = struct {
    app: r4os.App2,

    pub fn init(start: *const anyopaque) error{InvalidStart}!CompilerContext2 {
        if (@intFromPtr(start) % @alignOf(r4os.platform2.abi.R4XStartContext2) != 0) return error.InvalidStart;
        const raw: *const r4os.platform2.abi.R4XStartContext2 = @ptrCast(@alignCast(start));
        // The worker needs system facilities for every application class.
        // Let the SDK validate a matching console, GUI, hybrid or service
        // profile instead of imposing a console-only foreign entry.
        inline for (std.meta.tags(a.R4AppProfile)) |profile| {
            switch (r4os.App2.init(raw, profile)) {
                .value => |app| return .{ .app = app },
                .failure => {},
            }
        }
        return error.InvalidStart;
    }
    pub fn nakWorker(self: *CompilerContext2) !m.r4nak_worker.Worker {
        return m.r4nak_worker.Worker.init2(&self.app);
    }
    pub fn acoWorker(self: *CompilerContext2) !m.r4aco_worker.Worker {
        return m.r4aco_worker.Worker.init2(&self.app);
    }
};

pub const Sink = struct {
    context: ?*anyopaque = null,
    callback: *const fn (?*anyopaque, [*]const u8, usize) callconv(.c) u8,
    pub fn write(self: Sink, bytes: []const u8) bool {
        return self.callback(self.context, bytes.ptr, bytes.len) != 0;
    }
};
pub fn muxPacket(self: *m.r4enc_recording_mux.Writer, sink: Sink, bytes: []const u8, key: bool, pts_ns: i64, duration_ns: u64) m.r4enc_recording_mux.Error!void {
    return self.packet(sink, bytes, key, pts_ns, duration_ns);
}
pub fn snapshot(draw: *const Draw) !m.r4gfx_desktop_outputs.Snapshot {
    return m.r4gfx_desktop_outputs.Snapshot.read(draw);
}
pub fn receiver(draw: *const Draw, info: *const a.GfxOutputInfo) !Receiver {
    return m.r4gfx_desktop_outputs.readReceiver(draw, info);
}
pub fn brightness(self: *m.r4gfx_brightness_client.Client, draw: *const Draw, identity: a.GfxOutputId, now: u64, ready: bool) void {
    self.step(draw, identity, now, ready);
}
// Opaque clients must be created/selected through their original owner, not
// by guessing private layouts or copying the state machine in a consumer.
pub fn brightnessInit(output: *m.r4gfx_brightness_client.Client) void {
    output.* = .{};
}
pub fn brightnessSelect(self: *m.r4gfx_brightness_client.Client, choice: ?m.r4gfx_brightness_preferences.Choice) void {
    self.select(choice);
}
pub fn refreshInit(output: *m.r4gfx_refresh_client.Client) void {
    output.* = .{};
}
pub fn refreshSelect(self: *m.r4gfx_refresh_client.Client, choice: m.r4gfx_refresh_preferences.Choice) void {
    self.select(choice);
}
pub fn colorPreferencesEqual(left: *const m.r4gfx_color_preferences.Config, right: *const m.r4gfx_color_preferences.Config) bool {
    return std.meta.eql(left.*, right.*);
}
pub fn colorChoiceEqual(left: ?m.r4gfx_color_preferences.Choice, right: ?m.r4gfx_color_preferences.Choice) bool {
    return std.meta.eql(left, right);
}
pub fn refresh(self: *m.r4gfx_refresh_client.Client, draw: *const Draw, target: a.GfxOutputTarget, now: u64, scene: u32, ready: bool) void {
    self.step(draw, target, now, scene, ready);
}
pub fn refreshRelease(self: *m.r4gfx_refresh_client.Client, draw: *const Draw, target: a.GfxOutputTarget) void {
    self.release(draw, target);
}
pub fn modesRefresh(self: *Ctl, draw: *const Draw) bool {
    return self.refresh(draw);
}
pub fn modesApply(self: *Ctl, draw: *const Draw) bool {
    return self.apply(draw);
}
pub fn modesApplyColor(self: *Ctl, draw: *const Draw, colors: *const g.ColorV1Client, signal: a.GfxColorSignal) bool {
    return self.applyColor(g, draw, colors, signal);
}
pub fn modesPoll(self: *Ctl, draw: *const Draw) bool {
    return self.poll(draw);
}
pub fn modesResolve(self: *Ctl, draw: *const Draw, confirm: bool) bool {
    return self.resolve(draw, confirm);
}
pub fn modesClose(self: *Ctl, draw: *const Draw) void {
    self.close(draw);
}
pub fn modesCleanup(self: *Ctl, draw: *const Draw) bool {
    return self.cleanup(draw);
}
pub fn colorValidate(draw: *const Draw, entry: *const m.r4gfx_desktop_outputs.Entry, mode: a.GfxOutputMode, request: a.GfxColorSignal) !void {
    return m.r4gfx_color_control.validate(draw, entry, mode, request);
}
pub fn source(state: a.GfxOutputColorState, transport: color.Transport) color.Error!color.Source {
    return color.Source.fromPublished(state, transport);
}
pub fn publishedSignal(state: a.GfxOutputColorState, metadata: ?color.Metadata) color.Error!color.Signal {
    return color.publishedSignal(state, metadata);
}
pub fn requestedSignal(value: a.GfxColorSignal) color.Error!color.Signal {
    return color.requestedSignal(value);
}
pub fn signalRequest(value: color.Signal) color.Error!a.GfxColorSignal {
    return color.signalRequest(a.GfxColorSignal, value);
}
pub fn publishedLink(state: a.GfxOutputColorState, transport: color.Transport) color.Error!color.Link {
    return color.publishedLink(state, transport);
}
pub fn preview(report: *const Receiver, signal: color.Signal, state: a.GfxOutputColorState, transport: color.Transport, pipeline: color.Pipeline, clock: u64, vic: u16, width: u32, h_total: u32) color.Error!void {
    return color.preview(report, signal, state, transport, pipeline, clock, vic, width, h_total);
}
pub fn colorAdmit(report: *const Receiver, signal: color.Signal, source_value: color.Source, pipeline: color.Pipeline, link: color.Link, clock: u64, vic: u16) color.Error!color.Plan {
    return color.admit(report, signal, source_value, pipeline, link, clock, vic);
}
pub fn hdmiDsc(report: *const Receiver, signal: color.Signal, source_value: color.Source, pipeline: color.Pipeline, clock: u64, vic: u16) color.Error!color.Plan {
    return color.hdmiDscCandidate(report, signal, source_value, pipeline, clock, vic);
}
pub fn profileSignal(value: a.GfxColorSignal) bool {
    return color.profileEncoding(value);
}
pub fn profileOutput(value: a.GfxOutputColorState) bool {
    return color.profileEncoding(value);
}
pub fn vrrAdmit(report: *const Receiver, mode: m.r4gfx_timing.Timing, link: m.r4gfx_vrr.Link, source_value: m.r4gfx_vrr.Source) m.r4gfx_vrr.Error!m.r4gfx_vrr.Plan {
    return m.r4gfx_vrr.admit(report, mode, link, source_value);
}
pub fn profileOpenFile(allocator: std.mem.Allocator, colors: g.ColorV1Client, sys: *const Sys, path: [*:0]const u8, intent: u32, flags: u32) !m.profile {
    return m.profile.openFile(allocator, colors, sys, path, intent, flags);
}

pub const BuiltinShader = enum { fullscreen, color, copy, fill, shared, sample };
pub fn shader(kind: BuiltinShader) []const u32 {
    return switch (kind) {
        .fullscreen => &m.r4aco_shaders.fullscreen,
        .color => &m.r4aco_shaders.color,
        .copy => &m.r4aco_shaders.copy,
        .fill => &m.r4aco_shaders.fill,
        .shared => &m.r4aco_shaders.shared,
        .sample => &m.r4aco_shaders.sample,
    };
}
