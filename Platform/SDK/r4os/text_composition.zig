//! Copied bounded composition state. Only the calling editor owner mutates
//! its document, synchronously, after exact identity/revision/range checks.
//! This module performs no I/O, wait, callback, allocation or implicit Drop.
const std = @import("std");
const a = @import("r4os_contract").abi;
const grapheme = @import("r4std_grapheme");
pub const Id = a.CompositionId;
pub const Focus = a.CompositionFocus;
pub const Provider = a.CompositionProvider;
pub const Event = a.CompositionEvent;
pub const Caret = a.CompositionCaret;
pub const Range = a.Utf8ByteRange;
const magic: u64 = 0x434f4d504f533031;
pub fn validHandle(h: a.ProgramProcessHandle) bool {
    return h.instance_id != 0 and h.generation != 0 and h.reserved == 0;
}
pub fn providerStatus(method: Provider) i32 {
    if (method.version != 1 or method.size != @sizeOf(Provider) or method.max_text_bytes == 0 or method.max_text_bytes > a.composition_max_text_bytes or method.features & ~@as(u32, 1) != 0) return a.composition_error_invalid;
    if (method.features == 0) return if (std.meta.eql(method.process, a.ProgramProcessHandle{}) and method.generation == 0) a.composition_error_no_provider else a.composition_error_invalid;
    if (!validHandle(method.process) or method.generation == 0) return a.composition_error_invalid;
    return 0;
}
pub fn focusStatus(view: Focus) i32 {
    if (view.version != 1 or view.size != @sizeOf(Focus) or view.reserved != 0 or view.focused > 1) return a.composition_error_invalid;
    if (view.focused == 0) return a.composition_error_no_focus;
    if (!validHandle(view.window.service) or !validHandle(view.window.desktop) or !validHandle(view.window.owner) or view.window.serial == 0 or view.window.reserved != 0 or view.view_generation == 0 or view.focus_generation == 0 or view.input_revision == 0 or view.observed_tick == 0) return a.composition_error_invalid;
    return 0;
}
fn caretValid(value: Caret) bool {
    return value.height != 0 and value.scale_numerator != 0 and value.scale_denominator != 0 and @as(i64, value.x) + value.width <= std.math.maxInt(i32) and @as(i64, value.y) + value.height <= std.math.maxInt(i32);
}
fn textValid(text: []const u8) bool {
    return std.unicode.utf8ValidateSlice(text) and std.mem.indexOfScalar(u8, text, 0) == null;
}
fn rangeValid(text: []const u8, range: Range) bool {
    if (range.start > range.end or range.end > text.len) return false;
    var start = range.start == 0;
    var end = range.end == 0;
    var it = grapheme.Iterator{ .bytes = text };
    while (it.next() catch return false) |part| {
        start = start or part.end == range.start;
        end = end or part.end == range.end;
    }
    return start and end;
}
/// Opaque-by-contract state, exclusively owned by one editor thread. Do not
/// copy/reinitialize a live owner. owner_generation is a caller-owned nonzero
/// never-reused editor incarnation within its full window lifetime. Init of
/// replacement storage requires a NEW owner_generation. Views borrow only
/// initialized preedit bytes until the next mutation; no document is retained.
pub const Owner = extern struct {
    stamp: u64 = magic,
    id: Id = .{},
    replacement: Range = .{},
    selection: Range = .{},
    caret: Caret = .{},
    provider: Provider = .{},
    revision: u64 = 0,
    sequence: u64 = 0,
    next_generation: u64 = 1,
    owner_generation: u64,
    phase: u32 = 0,
    preedit_bytes: u32 = 0,
    data: [a.composition_max_text_bytes]u8 = @splat(0),

    pub fn init(owner_generation: u64, out: *Owner) i32 {
        if (owner_generation == 0) return a.composition_error_invalid;
        out.* = .{ .owner_generation = owner_generation };
        return 0;
    }
    fn valid(self: *const Owner) bool {
        return self.stamp == magic and self.owner_generation != 0 and self.next_generation != 0 and self.phase <= 1 and self.preedit_bytes <= a.composition_max_text_bytes;
    }
    fn invalidate(self: *Owner, code: i32) i32 {
        self.phase = 0;
        self.preedit_bytes = 0;
        return code;
    }
    pub fn begin(self: *Owner, view: Focus, method: Provider, revision: u64, document: []const u8, replacement: Range, caret: Caret, out: *Id) i32 {
        if (!self.valid() or self.phase != 0 or revision == 0 or !caretValid(caret)) return a.composition_error_invalid;
        const available = providerStatus(method);
        if (available != 0) return available;
        const focused = focusStatus(view);
        if (focused != 0) return focused;
        if (document.len > a.composition_max_document_bytes) return a.composition_error_capacity;
        if (!textValid(document)) return a.composition_error_encoding;
        if (!rangeValid(document, replacement)) return a.composition_error_range;
        if (self.next_generation == std.math.maxInt(u64) or revision == std.math.maxInt(u64)) return a.composition_error_exhausted;
        const identity: Id = .{ .window = view.window, .view_generation = view.view_generation, .focus_generation = view.focus_generation, .owner_generation = self.owner_generation, .session_generation = self.next_generation, .provider = method.process, .provider_generation = method.generation };
        self.next_generation += 1;
        self.id = identity;
        self.replacement = replacement;
        self.selection = .{};
        self.caret = caret;
        self.provider = method;
        self.revision = revision;
        self.sequence = 0;
        self.preedit_bytes = 0;
        self.phase = 1;
        out.* = identity;
        return 0;
    }
    /// Caller first acquires current scope outside GUI/text locks, then
    /// applies this pure transition at its own event/lock boundary. Its actual
    /// focus/view loss must call Cancel/Refresh before any later event.
    pub fn refresh(self: *Owner, view: Focus, method: Provider, revision: u64) i32 {
        if (!self.valid()) return a.composition_error_invalid;
        if (self.phase == 0) return a.composition_error_stale_session;
        const available = providerStatus(method);
        if (available != 0) return self.invalidate(available);
        if (!std.meta.eql(method, self.provider)) return self.invalidate(a.composition_error_provider_changed);
        const focused = focusStatus(view);
        if (focused != 0) return self.invalidate(focused);
        if (!std.meta.eql(view.window, self.id.window) or view.view_generation != self.id.view_generation or view.focus_generation != self.id.focus_generation) return self.invalidate(a.composition_error_stale_view);
        if (revision == 0 or revision != self.revision) return self.invalidate(a.composition_error_stale_text);
        return 0;
    }
    /// Negative results leave document, length and revision unchanged. Scope
    /// loss invalidates only this old local session. Event/text are copied
    /// before the sole successful document write; preedit never writes it.
    pub fn apply(self: *Owner, view: Focus, method: Provider, event: Event, text: []const u8, document: []u8, length: *usize, revision: *u64) i32 {
        if (!self.valid() or length.* > document.len) return a.composition_error_invalid;
        // Reject a foreign/old event BEFORE refreshing: it cannot cancel an
        // unrelated newer active session by supplying an old focus/provider.
        if (self.phase == 0 or !std.meta.eql(event.id, self.id) or event.sequence == 0 or event.sequence <= self.sequence) return a.composition_error_stale_session;
        if (event.version != 1 or event.size != @sizeOf(Event) or event.kind < 1 or event.kind > 3 or event.text_bytes != text.len) return a.composition_error_invalid;
        const scope = self.refresh(view, method, revision.*);
        if (scope != 0) return scope;
        if (event.text_revision != self.revision) return self.invalidate(a.composition_error_stale_text);
        if (event.kind == a.composition_event_cancel) {
            if (text.len != 0 or !std.meta.eql(event.replacement, Range{}) or !std.meta.eql(event.selection, Range{})) return a.composition_error_invalid;
            return self.invalidate(0);
        }
        if (length.* > a.composition_max_document_bytes or text.len > method.max_text_bytes) return a.composition_error_capacity;
        if (!textValid(document[0..length.*]) or !textValid(text)) return a.composition_error_encoding;
        if (!rangeValid(document[0..length.*], event.replacement) or !rangeValid(text, event.selection)) return a.composition_error_range;
        var copied: [a.composition_max_text_bytes]u8 = undefined;
        @memcpy(copied[0..text.len], text);
        if (event.kind == a.composition_event_preedit) {
            @memcpy(self.data[0..text.len], copied[0..text.len]);
            self.preedit_bytes = @intCast(text.len);
            self.selection = event.selection;
            self.replacement = event.replacement;
            self.sequence = event.sequence;
            return 0;
        }
        const start: usize = @intCast(event.replacement.start);
        const end: usize = @intCast(event.replacement.end);
        const new_length = length.* - (end - start) + text.len;
        if (new_length > document.len or new_length > a.composition_max_document_bytes) return a.composition_error_capacity;
        if (revision.* == std.math.maxInt(u64)) return a.composition_error_exhausted;
        const tail = length.* - end;
        const new_end = start + text.len;
        if (new_end > end) std.mem.copyBackwards(u8, document[new_end..][0..tail], document[end..][0..tail]) else std.mem.copyForwards(u8, document[new_end..][0..tail], document[end..][0..tail]);
        @memcpy(document[start..new_end], copied[0..text.len]);
        length.* = new_length;
        revision.* += 1;
        self.sequence = event.sequence;
        return self.invalidate(0);
    }
    pub fn cancel(self: *Owner, expected: Id) i32 {
        if (!self.valid()) return a.composition_error_invalid;
        if (self.phase == 0 or !std.meta.eql(expected, self.id)) return a.composition_error_stale_session;
        return self.invalidate(0);
    }
    pub fn preedit(self: *const Owner) ?[]const u8 {
        if (!self.valid() or self.phase == 0) return null;
        return self.data[0..self.preedit_bytes];
    }
    pub fn queryCaret(self: *Owner, view: Focus, method: Provider, revision: u64, out: *Caret) i32 {
        const code = self.refresh(view, method, revision);
        if (code != 0) return code;
        out.* = self.caret;
        return 0;
    }
    pub fn setCaret(self: *Owner, view: Focus, method: Provider, revision: u64, value: Caret) i32 {
        if (!caretValid(value)) return a.composition_error_invalid;
        const code = self.refresh(view, method, revision);
        if (code != 0) return code;
        self.caret = value;
        return 0;
    }
    pub fn surrounding(self: *Owner, view: Focus, method: Provider, revision: u64, document: []const u8, range: Range, storage: []u8, out: *usize) i32 {
        const code = self.refresh(view, method, revision);
        if (code != 0) return code;
        if (document.len > a.composition_max_document_bytes) return a.composition_error_capacity;
        if (!textValid(document)) return a.composition_error_encoding;
        if (!rangeValid(document, range)) return a.composition_error_range;
        const count: usize = @intCast(range.end - range.start);
        if (count > a.composition_max_text_bytes or count > storage.len) return a.composition_error_capacity;
        // Surrounding reads cannot mutate document bytes or their revision.
        const doc_start = @intFromPtr(document.ptr);
        const out_start = @intFromPtr(storage.ptr);
        if (document.len != 0 and storage.len != 0 and doc_start < out_start + storage.len and out_start < doc_start + document.len) return a.composition_error_invalid;
        const source = document[@intCast(range.start)..@intCast(range.end)];
        @memcpy(storage[0..count], source);
        out.* = count;
        return 0;
    }
};

/// Read-only acquisition through the original WINSVC transport. Call outside
/// GUI/text locks, then hand copied values to Owner at its event boundary.
/// A successful transport is not a provider capability or a future focus lease.
pub const Client = struct {
    call: a.R4SysFns.service_call,
    close_call: a.R4SysFns.service_close,
    handle: u32,
    timeout_ticks: u64,
    pub fn connect(context: *const @import("platform2.zig").Context, timeout_ticks: u64, out: *Client) i32 {
        const platform = @import("platform2.zig");
        if (timeout_ticks == 0) return a.composition_error_invalid;
        const table = context.system();
        const open = platform.abi.function(platform.abi.R4SysFns2, table, "service_open") orelse return a.composition_error_unsupported;
        const call = platform.abi.function(platform.abi.R4SysFns2, table, "service_call") orelse return a.composition_error_unsupported;
        const close_call = platform.abi.function(platform.abi.R4SysFns2, table, "service_close") orelse return a.composition_error_unsupported;
        var endpoint: a.ServiceInfo = .{};
        const code = open("WINSVC", &endpoint);
        if (code != 0) return code;
        if (endpoint.handle == 0) return a.composition_error_unsupported;
        out.* = .{ .call = call, .close_call = close_call, .handle = endpoint.handle, .timeout_ticks = timeout_ticks };
        return 0;
    }
    pub fn close(self: *Client) i32 {
        if (self.handle == 0) return a.composition_error_invalid;
        const code = self.close_call(self.handle);
        if (code >= 0) self.handle = 0;
        return code;
    }
    fn rpc(self: *const Client, op: u16, request: []const u8, response: []u8) i32 {
        if (self.handle == 0) return a.composition_error_invalid;
        var header: a.ServiceMessageHeader = .{};
        const code = self.call(self.handle, op, request.ptr, @intCast(request.len), &header, response.ptr, @intCast(response.len), self.timeout_ticks);
        if (code < 0) return code;
        if (header.status == a.service_api_result_bad_op) return a.composition_error_unsupported;
        if (header.status != 0) return if (header.status < 0) header.status else a.composition_error_invalid;
        if (@as(usize, @intCast(code)) != response.len) return a.composition_error_invalid;
        return 0;
    }
    pub fn capability(self: *const Client, out: *a.CompositionCapabilityReply) i32 {
        var value: a.CompositionCapabilityReply = .{};
        const code = self.rpc(a.composition_op_capability, "", std.mem.asBytes(&value));
        if (code != 0) return code;
        const status = providerStatus(value.provider);
        if (value.reserved != 0 or value.result != status or (status != 0 and status != a.composition_error_no_provider)) return a.composition_error_invalid;
        out.* = value;
        return 0;
    }
    pub fn focus(self: *const Client, expected: a.WindowModeIdentity, out: *a.CompositionFocusReply) i32 {
        var value: a.CompositionFocusReply = .{};
        const code = self.rpc(a.composition_op_focus, std.mem.asBytes(&expected), std.mem.asBytes(&value));
        if (code != 0) return code;
        if (value.reserved != 0 or (value.result != 0 and value.result != a.composition_error_no_focus and value.result != a.composition_error_stale_view)) return a.composition_error_invalid;
        if (value.result == 0 and (focusStatus(value.focus) != 0 or !std.meta.eql(value.focus.window, expected))) return a.composition_error_invalid;
        out.* = value;
        return 0;
    }
};
