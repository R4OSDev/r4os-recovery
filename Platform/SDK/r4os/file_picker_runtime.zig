//! Static C/Rust ABI; every operation uses the single Zig session owner.
const o = @import("file_picker.zig");
const wire = @import("binary_cursor.zig");
comptime {
    if (@sizeOf(o.Provider) != 32 or @sizeOf(o.Row) != 1400 or @sizeOf(o.Decision) != 1144 or
        @sizeOf(o.Progress) != 56 or @sizeOf(o.Session) != 8640 or @offsetOf(o.Session, "in_call") != 8628)
        @compileError("File picker C/Rust layout drift");
}
pub export fn R4SdkFilePickerInit(a: wire.Span, b: wire.Span, capacity: u32, mode: u32, extension: wire.Span, provider: o.Provider, out: ?*o.Session) callconv(.c) i32 {
    const target = out orelse return o.invalid;
    const bytes = extension.bytes() catch return o.storage_error;
    return o.Session.initSpans(a, b, capacity, mode, bytes, provider, target);
}
pub export fn R4SdkFilePickerBegin(raw: ?*o.Session, path: wire.Span, page: u32) callconv(.c) i32 {
    const state = raw orelse return o.invalid;
    const bytes = path.bytes() catch return o.storage_error;
    return state.begin(bytes, page);
}
pub export fn R4SdkFilePickerStep(raw: ?*o.Session, budget: u32) callconv(.c) i32 {
    return (raw orelse return o.invalid).step(budget);
}
pub export fn R4SdkFilePickerGetProgress(raw: ?*const o.Session, out: ?*o.Progress) callconv(.c) i32 {
    return (raw orelse return o.invalid).progress(out orelse return o.invalid);
}
pub export fn R4SdkFilePickerView(raw: ?*const o.Session, out: ?*wire.Span) callconv(.c) i32 {
    return (raw orelse return o.invalid).view(out orelse return o.invalid);
}
pub export fn R4SdkFilePickerSelect(raw: ?*o.Session, revision: u64, index: u32, visible: u32) callconv(.c) i32 {
    return (raw orelse return o.invalid).select(revision, index, visible);
}
pub export fn R4SdkFilePickerName(raw: ?*o.Session, value: wire.Span) callconv(.c) i32 {
    const bytes = value.bytes() catch return o.storage_error;
    return (raw orelse return o.invalid).setName(bytes);
}
pub export fn R4SdkFilePickerActivate(raw: ?*o.Session, revision: u64, use_name: u32, overwrite: u32, out: ?*o.Decision) callconv(.c) i32 {
    if (use_name > 1 or overwrite > 1) return o.invalid;
    return (raw orelse return o.invalid).activate(revision, use_name != 0, overwrite != 0, out orelse return o.invalid);
}
pub export fn R4SdkFilePickerKey(raw: ?*o.Session, key: u8, visible: u32, out: ?*o.Decision) callconv(.c) i32 {
    return (raw orelse return o.invalid).key(key, visible, out orelse return o.invalid);
}
pub export fn R4SdkFilePickerFocus(raw: ?*o.Session, focus: u32, pressed: u32) callconv(.c) i32 {
    return (raw orelse return o.invalid).setFocus(focus, pressed);
}
pub export fn R4SdkFilePickerCancel(raw: ?*o.Session, out: ?*o.Decision) callconv(.c) i32 {
    return (raw orelse return o.invalid).cancel(out orelse return o.invalid);
}
