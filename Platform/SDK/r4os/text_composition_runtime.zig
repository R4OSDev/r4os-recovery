//! Scalar/pointer C ABI over the same original copied SDK owner. All input
//! records are borrowed through actual return and copied before transitions.
const o = @import("text_composition.zig");
const a = @import("r4os_contract").abi;
const wire = @import("binary_cursor.zig");
comptime {
    if (@sizeOf(o.Owner) != 1288 or @offsetOf(o.Owner, "data") != 264 or @alignOf(o.Owner) != 8) @compileError("Composition owner C/Rust layout drift");
}
const invalid = a.composition_error_invalid;
fn span(pointer: anytype) wire.Span {
    return .{ .address = @intFromPtr(pointer), .length = @sizeOf(@typeInfo(@TypeOf(pointer)).pointer.child) };
}
fn overlaps(x: wire.Span, y: wire.Span) bool {
    return x.length != 0 and y.length != 0 and x.address < y.address + y.length and y.address < x.address + x.length;
}
fn loans(reads: []const wire.Span, writes: []const wire.Span) bool {
    for (reads) |r| r.validate() catch return false;
    for (writes) |w| w.validate() catch return false;
    for (writes, 0..) |w, i| {
        for (writes[i + 1 ..]) |other| if (overlaps(w, other)) return false;
        for (reads) |r| if (overlaps(w, r)) return false;
    }
    return true;
}
fn mutable(value: wire.Span) ?[]u8 {
    value.validate() catch return null;
    if (value.length == 0) return @constCast(&.{});
    return @as([*]u8, @ptrFromInt(value.address))[0..value.length];
}
pub export fn R4SdkCompositionInit(generation: u64, out: ?*o.Owner) callconv(.c) i32 {
    return o.Owner.init(generation, out orelse return invalid);
}
pub export fn R4SdkCompositionBegin(raw: ?*o.Owner, focus: ?*const o.Focus, provider: ?*const o.Provider, revision: u64, document: ?*const wire.Span, replacement: ?*const o.Range, caret: ?*const o.Caret, out: ?*o.Id) callconv(.c) i32 {
    const state = raw orelse return invalid;
    const f = focus orelse return invalid;
    const p = provider orelse return invalid;
    const d = document orelse return invalid;
    const r = replacement orelse return invalid;
    const c = caret orelse return invalid;
    const target = out orelse return invalid;
    const reads = [_]wire.Span{ span(f), span(p), span(d), span(r), span(c), d.* };
    if (!loans(&reads, &.{ span(state), span(target) })) return invalid;
    const bytes = d.bytes() catch return invalid;
    return state.begin(f.*, p.*, revision, bytes, r.*, c.*, target);
}
pub export fn R4SdkCompositionRefresh(raw: ?*o.Owner, focus: ?*const o.Focus, provider: ?*const o.Provider, revision: u64) callconv(.c) i32 {
    const state = raw orelse return invalid;
    const f = focus orelse return invalid;
    const p = provider orelse return invalid;
    if (!loans(&.{ span(f), span(p) }, &.{span(state)})) return invalid;
    return state.refresh(f.*, p.*, revision);
}
pub export fn R4SdkCompositionApply(raw: ?*o.Owner, focus: ?*const o.Focus, provider: ?*const o.Provider, event: ?*const o.Event, text: ?*const wire.Span, document: ?*const wire.Span, length: ?*u64, revision: ?*u64) callconv(.c) i32 {
    const state = raw orelse return invalid;
    const f = focus orelse return invalid;
    const p = provider orelse return invalid;
    const e = event orelse return invalid;
    const t = text orelse return invalid;
    const d = document orelse return invalid;
    const size = length orelse return invalid;
    const stamp = revision orelse return invalid;
    if (!loans(&.{ span(f), span(p), span(e), span(t), span(d) }, &.{ span(state), d.*, span(size), span(stamp) })) return invalid;
    // Text may alias document: Owner stages its whole bounded payload before
    // the sole successful write. It still cannot alias state/output scalars.
    if (!loans(&.{t.*}, &.{ span(state), span(size), span(stamp) })) return invalid;
    const payload = t.bytes() catch return invalid;
    const storage = mutable(d.*) orelse return invalid;
    var actual_length: usize = @intCast(size.*);
    const code = state.apply(f.*, p.*, e.*, payload, storage, &actual_length, stamp);
    if (code == 0) size.* = actual_length;
    return code;
}
pub export fn R4SdkCompositionCancel(raw: ?*o.Owner, expected: ?*const o.Id) callconv(.c) i32 {
    const state = raw orelse return invalid;
    const id = expected orelse return invalid;
    if (!loans(&.{span(id)}, &.{span(state)})) return invalid;
    return state.cancel(id.*);
}
pub export fn R4SdkCompositionPreedit(raw: ?*const o.Owner, out: ?*wire.Span) callconv(.c) i32 {
    const state = raw orelse return invalid;
    const target = out orelse return invalid;
    if (!loans(&.{span(state)}, &.{span(target)})) return invalid;
    const bytes = state.preedit() orelse return a.composition_error_stale_session;
    target.* = .{ .address = @intFromPtr(bytes.ptr), .length = bytes.len };
    return 0;
}
pub export fn R4SdkCompositionCaret(raw: ?*o.Owner, focus: ?*const o.Focus, provider: ?*const o.Provider, revision: u64, out: ?*o.Caret) callconv(.c) i32 {
    const state = raw orelse return invalid;
    const f = focus orelse return invalid;
    const p = provider orelse return invalid;
    const target = out orelse return invalid;
    if (!loans(&.{ span(f), span(p) }, &.{ span(state), span(target) })) return invalid;
    return state.queryCaret(f.*, p.*, revision, target);
}
pub export fn R4SdkCompositionSetCaret(raw: ?*o.Owner, focus: ?*const o.Focus, provider: ?*const o.Provider, revision: u64, value: ?*const o.Caret) callconv(.c) i32 {
    const state = raw orelse return invalid;
    const f = focus orelse return invalid;
    const p = provider orelse return invalid;
    const c = value orelse return invalid;
    if (!loans(&.{ span(f), span(p), span(c) }, &.{span(state)})) return invalid;
    return state.setCaret(f.*, p.*, revision, c.*);
}
pub export fn R4SdkCompositionSurrounding(raw: ?*o.Owner, focus: ?*const o.Focus, provider: ?*const o.Provider, revision: u64, document: ?*const wire.Span, range: ?*const o.Range, storage: ?*const wire.Span, out: ?*u64) callconv(.c) i32 {
    const state = raw orelse return invalid;
    const f = focus orelse return invalid;
    const p = provider orelse return invalid;
    const d = document orelse return invalid;
    const r = range orelse return invalid;
    const s = storage orelse return invalid;
    const count = out orelse return invalid;
    if (!loans(&.{ span(f), span(p), span(d), span(r), span(s), d.* }, &.{ span(state), s.*, span(count) })) return invalid;
    const bytes = d.bytes() catch return invalid;
    const output = mutable(s.*) orelse return invalid;
    var actual_count: usize = 0;
    const code = state.surrounding(f.*, p.*, revision, bytes, r.*, output, &actual_count);
    if (code == 0) count.* = actual_count;
    return code;
}
