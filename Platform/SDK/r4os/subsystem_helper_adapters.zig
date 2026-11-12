//! Concrete subsystem callback and platform-context adapters only.
const std = @import("std");
const a = @import("r4os_contract").abi;
const cb = @import("subsystem_callback_bridge.zig");
const catalog = @import("subsystem_catalog.zig");
const video = @import("subsystem_host.zig");
const rt = @import("subsystem_runtime.zig");
const save = @import("subsystem_persistence.zig");
const p = @import("program.zig");
pub const Error = error{ MissingCallback, InvalidConfiguration, Unavailable };
fn make(comptime T: type, table: *const cb.Table, comptime mappings: anytype) Error!T {
    var value: T = undefined;
    inline for (@typeInfo(T).@"struct".fields) |field| {
        if (comptime std.mem.eql(u8, field.name, "context")) {
            @field(value, field.name) = @ptrCast(@constCast(table));
        } else {
            const selected: ?usize = comptime blk: {
                for (mappings, 0..) |mapping, i| if (std.mem.eql(u8, field.name, mapping[0])) break :blk i;
                break :blk null;
            };
            if (comptime selected != null) {
                const mapping = mappings[selected.?];
                const optional = @typeInfo(field.type) == .optional;
                const Pointer = if (optional) @typeInfo(field.type).optional.child else field.type;
                @field(value, field.name) = if (table.has(mapping[1])) cb.pointer(Pointer, mapping[2], mapping[1]) else if (optional) null else if (field.default_value_ptr) |raw| @as(*const field.type, @ptrCast(@alignCast(raw))).* else return error.MissingCallback;
            } else {
                const ptr: *const field.type = @ptrCast(@alignCast(field.default_value_ptr orelse @compileError("unmapped required subsystem field " ++ field.name)));
                @field(value, field.name) = ptr.*;
            }
        }
    }
    return value;
}
pub fn hostVerifier(table: *const cb.Table) Error!catalog.HostVerifier {
    return make(catalog.HostVerifier, table, .{.{ "check", cb.Kind.verify_host, 0 }});
}
pub fn videoBackend(table: *const cb.Table, indexed8: bool, xrgb32: bool, shared_raster: bool) Error!video.Backend {
    var result = try make(video.Backend, table, .{ .{ "begin_full_fn", cb.Kind.video_begin_full, 0 }, .{ "begin_damage_fn", cb.Kind.video_begin_damage, 0 }, .{ "begin_replace_fn", cb.Kind.video_begin_replace, 0 }, .{ "clear_fn", cb.Kind.video_clear, 0 }, .{ "raster_fn", cb.Kind.video_raster, 0 }, .{ "indexed8_fn", cb.Kind.video_indexed8, 0 }, .{ "xrgb32_nearest_fn", cb.Kind.video_xrgb32, 0 }, .{ "shared_raster_create_fn", cb.Kind.video_shared_create, 0 }, .{ "shared_raster_destroy_fn", cb.Kind.video_shared_destroy, 0 }, .{ "shared_raster_map_write_fn", cb.Kind.video_shared_map, 0 }, .{ "shared_raster_publish_fn", cb.Kind.video_shared_publish, 0 }, .{ "shared_raster_fn", cb.Kind.video_shared_submit, 0 }, .{ "commit_full_fn", cb.Kind.video_commit_full, 0 }, .{ "commit_damage_fn", cb.Kind.video_commit_damage, 0 }, .{ "cancel_fn", cb.Kind.video_cancel, 0 } });
    result.supports_indexed8 = indexed8;
    result.supports_xrgb32_nearest = xrgb32;
    result.supports_shared_raster = shared_raster;
    return result;
}
pub fn overlay(table: *const cb.Table) Error!video.FrameOverlay {
    return make(video.FrameOverlay, table, .{.{ "append_fn", cb.Kind.video_overlay, 0 }});
}
pub fn guestDriver(table: *const cb.Table) Error!rt.GuestDriver {
    return make(rt.GuestDriver, table, .{ .{ "step_fn", cb.Kind.guest_step, 0 }, .{ "reset_fn", cb.Kind.guest_reset, 0 }, .{ "render_audio_fn", cb.Kind.guest_audio, 0 }, .{ "audio_feedback_fn", cb.Kind.guest_feedback, 0 } });
}
pub fn hostDriver(table: *const cb.Table) Error!rt.HostDriver {
    return make(rt.HostDriver, table, .{ .{ "poll_fn", cb.Kind.host_poll, 0 }, .{ "present_fn", cb.Kind.host_present, 0 }, .{ "wait_fn", cb.Kind.host_wait, 0 }, .{ "should_close_fn", cb.Kind.host_close, 0 } });
}
pub fn audioSink(table: *const cb.Table) Error!rt.AudioSink {
    return make(rt.AudioSink, table, .{ .{ "open_fn", cb.Kind.audio_open, 0 }, .{ "write_fn", cb.Kind.audio_write, 0 }, .{ "volume_fn", cb.Kind.audio_volume, 0 }, .{ "close_fn", cb.Kind.audio_close, 0 }, .{ "poll_fn", cb.Kind.audio_poll, 0 }, .{ "finish_fn", cb.Kind.audio_finish, 0 } });
}
pub fn persistenceBackend(table: *const cb.Table) Error!save.Backend {
    return make(save.Backend, table, .{ .{ "acquire_fn", cb.Kind.save_acquire, 0 }, .{ "release_fn", cb.Kind.save_release, 0 }, .{ "read_exact_fn", cb.Kind.save_read, 0 }, .{ "write_atomic_fn", cb.Kind.save_write, 0 }, .{ "poll_fn", cb.Kind.save_poll, 0 }, .{ "drain_fn", cb.Kind.save_drain, 0 }, .{ "pending_fn", cb.Kind.save_pending, 0 } });
}
pub fn persistenceConfiguration(table: *const cb.Table, root: []const u8, directories: []const []const u8, rtc_bytes: usize, delta_bytes: usize, scratch: []u8) Error!save.Configuration {
    const result = save.Configuration{ .save_root = root, .root_directories = directories, .rtc_record_bytes = rtc_bytes, .delta_record_bytes = delta_bytes, .record_scratch = scratch, .context = @ptrCast(@constCast(table)), .validate_rtc = if (table.has(.validate_rtc)) cb.pointer(@typeInfo(@FieldType(save.Configuration, "validate_rtc")).optional.child, 0, .validate_rtc) else null, .validate_delta = if (table.has(.validate_delta)) cb.pointer(@typeInfo(@FieldType(save.Configuration, "validate_delta")).optional.child, 0, .validate_delta) else null };
    if (!result.valid()) return error.InvalidConfiguration;
    return result;
}
/// Initialize at the final address; hosts, streams and stores borrow this bundle.
pub const Context = struct { bundle: p.Bundle, sys: @import("r4sys.zig").Context, desk: @import("r4desk.zig").Context, draw: @import("r4draw.zig").Context, audio: @import("r4audio.zig").Context };
pub fn open(out: *Context, raw: *const a.R4XStartContext) bool {
    out.bundle = p.bundleValueFromR4XStart(raw) orelse return false;
    out.sys = .init(&out.bundle);
    out.desk = .init(&out.bundle);
    out.draw = .init(&out.bundle);
    out.audio = .init(&out.bundle);
    return true;
}
pub fn guiHost(out: *video.Host, ctx: *const Context, surface: video.Surface, scratch: []u32) video.Error!void {
    out.* = try video.Host.init(ctx.desk, ctx.draw, surface, scratch);
}
pub fn drawBackend(ctx: *const Context) video.Backend {
    return video.Backend.fromDraw(&ctx.draw);
}
pub fn platformAudio(out: *rt.R4AudioSink, ctx: *const Context, timeout_ns: u64, close_timeout_ns: u64) void {
    out.* = rt.R4AudioSink.initWithTimeouts(.{ .sys = ctx.sys, .raw = ctx.audio }, timeout_ns, close_timeout_ns);
}
pub fn platformFiles(ctx: *const Context) @import("app_storage.zig").Files {
    return .{ .sys = ctx.sys };
}
pub fn run(runtime: *rt.Runtime, ctx: *const Context, guest: rt.GuestDriver, host: rt.HostDriver) i32 {
    return runtime.run(&ctx.sys, guest, host);
}
