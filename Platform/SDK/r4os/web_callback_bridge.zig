//! Explicit C callback ABI for the original Zig web hooks. The table and its
//! user storage stay at stable addresses through every retained native loan.
//! Callback inputs are borrowed only for this invocation; GC hooks retain
//! their original no-allocation/no-JavaScript/no-recursive-collection rules.
const codec = @import("native_value_bridge.zig");
pub const Slot = codec.Slot;
pub const Kind = enum(u6) {
    glyph_support,
    font_resolve,
    font_measure,
    image_resolve,
    image_resolve_role,
    catalog_revision,
    catalog_count,
    catalog_info,
    js_host_function,
    js_host_get,
    js_host_set,
    js_cancel,
    js_clock,
    js_offset,
    promise_rejection,
    root_mark,
    root_mark_weak,
    root_sweep,
    program_create,
    program_destroy,
    program_allocate,
    program_free,
    canvas_allocate,
    canvas_free,
    resource_complete,
    font_local,
    font_cached,
    resource_report,
    frame_lookup,
    script_report,
    monotonic_clock,
    network_progress,
    cookie_provider,
    cookie_sink,
    target_authorize,
    download_progress,
    download_write,
    runtime_lookup,
    post_stream_write,
    post_stream_read,
    download_head,
};
pub const Table = extern struct {
    user: ?*anyopaque = null,
    mask: u64 = 0,
    invoke: ?*const fn (?*anyopaque, u32, [*]const Slot, u32, ?*anyopaque) callconv(.c) Slot = null,
    pub fn has(self: *const Table, kind: Kind) bool {
        return self.invoke != null and self.mask & (@as(u64, 1) << @intFromEnum(kind)) != 0;
    }
};
/// Keep the original descriptor/type identity while sharing the marshaller.
pub fn Adapter(comptime Pointer: type, comptime context_index: usize, comptime kind: Kind) type {
    return @import("native_callback_bridge.zig").Adapter(Table, Pointer, context_index, kind);
}
pub fn pointer(comptime T: type, comptime context_index: usize, comptime kind: Kind) T {
    return &Adapter(T, context_index, kind).call;
}
