//! Complete current web document/layout/script owners. The engines stay here.
const std = @import("std");
pub const html = @import("html.zig");
pub const css = @import("css.zig");
pub const layout = @import("web_layout.zig");
pub const font = @import("web_font.zig");
pub const fonts = @import("web_fonts.zig");
pub const font_cache = @import("web_font_cache.zig");
pub const font_activation = @import("web_font_activation.zig");
pub const images = @import("web_images.zig");
pub const background = @import("web_background.zig");
pub const forms = @import("web_forms.zig");
pub const navigation = @import("web_navigation.zig");
pub const javascript = @import("javascript.zig");
pub const runtime = @import("web_runtime.zig");
pub const canvas = @import("web_canvas.zig");
pub const callbacks = @import("web_callback_bridge.zig");
pub const adapters = @import("web_helper_adapters.zig");
pub const run = font.RunResolver(layout.FontFace);
pub const modules = .{ html, css, layout, font, fonts, font_cache, font_activation, images, background, forms, navigation, javascript, runtime, canvas, callbacks, adapters, run };
pub fn sharedType(comptime T: type) bool {
    return T == std.mem.Allocator or T == std.heap.FixedBufferAllocator;
}
pub fn moduleType(comptime T: type) bool {
    if (T == @This() or T == callbacks.Slot) return true;
    inline for (modules) |M| if (T == M and @sizeOf(T) == 0) return true;
    return false;
}
pub fn opaqueType(comptime T: type) bool {
    if (@typeInfo(T) != .@"struct" and @typeInfo(T) != .@"union") return false;
    if (sharedType(T)) return true;
    const name = @typeName(T);
    inline for (.{ "array_list.", "hash_map.", "mem.Allocator", "heap.", "atomic.", "crypto.", "program.", "r4sys.", "r4dev.", "r4desk.", "r4draw.", "Io.", "std." }) |prefix| if (std.mem.startsWith(u8, name, prefix)) return true;
    return false;
}
fn fieldFn(comptime T: type, comptime field: []const u8) type {
    const F = @FieldType(T, field);
    return if (@typeInfo(F) == .optional) @typeInfo(F).optional.child else F;
}
pub const callbackTypes = .{
    fieldFn(font.GlyphSupport, "callback"),         fieldFn(layout.FontProvider, "resolve"),        fieldFn(layout.FontProvider, "measure"),             fieldFn(layout.ImageResolver, "resolve"),              fieldFn(layout.ImageResolver, "resolve_role"),
    fieldFn(font.CatalogReader, "revision"),        fieldFn(font.CatalogReader, "count"),           fieldFn(font.CatalogReader, "info"),                 javascript.HostFunction,                               javascript.HostPropertyGet,
    javascript.HostPropertySet,                     fieldFn(javascript.Stop, "requested"),          fieldFn(javascript.ClockSource, "now_milliseconds"), fieldFn(javascript.ClockSource, "offset_minutes"),     fieldFn(javascript.PromiseRejectionTracker, "track"),
    fieldFn(javascript.ExternalRootMarker, "mark"), fieldFn(javascript.ProgramAllocator, "create"), fieldFn(javascript.ProgramAllocator, "destroy"),     fieldFn(javascript.ProgramAllocator, "allocate"),      fieldFn(javascript.ProgramAllocator, "free"),
    fieldFn(canvas.Allocator, "allocate"),          fieldFn(canvas.Allocator, "free"),              fieldFn(runtime.ResourceHandler, "complete"),        fieldFn(runtime.FontSourceHandler, "local_available"), fieldFn(runtime.FontSourceHandler, "cached_available"),
    fieldFn(runtime.ResourceObserver, "report"),    fieldFn(runtime.FrameLookup, "inspect"),        fieldFn(runtime.ScriptObserver, "report"),           fieldFn(runtime.MonotonicClock, "now_milliseconds"),
};
