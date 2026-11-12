//! Exact subsystem host/guest/media/persistence callbacks. Borrowed state
//! remains stable until the original synchronous return or explicit drain.
const core = @import("native_callback_bridge.zig");
pub const Slot = core.Slot;
pub const Kind = enum(u6) { verify_host, video_begin_full, video_begin_damage, video_begin_replace, video_clear, video_raster, video_indexed8, video_xrgb32, video_shared_create, video_shared_destroy, video_shared_map, video_shared_publish, video_shared_submit, video_commit_full, video_commit_damage, video_cancel, video_overlay, guest_step, guest_reset, guest_audio, guest_feedback, host_poll, host_present, host_wait, host_close, audio_open, audio_write, audio_volume, audio_close, save_acquire, save_release, save_read, save_write, save_poll, save_drain, save_pending, validate_rtc, validate_delta, audio_poll, audio_finish };
pub const Table = extern struct {
    user: ?*anyopaque = null,
    mask: u64 = 0,
    invoke: ?*const fn (?*anyopaque, u32, [*]const Slot, u32, ?*anyopaque) callconv(.c) Slot = null,
    pub fn has(self: *const Table, kind: Kind) bool {
        return self.invoke != null and self.mask & (@as(u64, 1) << @intFromEnum(kind)) != 0;
    }
};
pub fn pointer(comptime T: type, comptime context_index: usize, comptime kind: Kind) T {
    return core.pointer(Table, T, context_index, kind);
}
