const std = @import("std");
const o = @import("text_composition.zig");
const a = @import("r4os_contract").abi;
const t = std.testing;
const gui = @import("gui.zig");
fn h(id: u32) a.ProgramProcessHandle {
    return .{ .instance_id = id, .generation = 100 + id };
}
fn focus() o.Focus {
    return .{ .window = .{ .service = h(1), .desktop = h(2), .owner = h(3), .serial = 8 }, .view_generation = 9, .focus_generation = 10, .input_revision = 11, .observed_tick = 12, .focused = 1 };
}
fn provider() o.Provider {
    return .{ .process = h(4), .generation = 15, .features = 1 };
}
fn event(id: o.Id, seq: u64, kind: u32, revision: u64, range: o.Range, text: []const u8) o.Event {
    return .{ .id = id, .sequence = seq, .kind = kind, .text_revision = revision, .replacement = range, .selection = .{ .end = text.len }, .text_bytes = @intCast(text.len) };
}
fn begin(state: *o.Owner, revision: u64, doc: []const u8, range: o.Range) !o.Id {
    var id: o.Id = undefined;
    try t.expectEqual(@as(i32, 0), o.Owner.init(99, state));
    try t.expectEqual(@as(i32, 0), state.begin(focus(), provider(), revision, doc, range, .{}, &id));
    return id;
}

test "composition owner normal control empty offers still validate exact provider snapshot and close" {
    const offers = @import("clipboard_offer.zig");
    const control = @import("gui_text_control.zig");
    const Provider = struct {
        var calls: usize = 0;
        fn call(_: u32, op: u16, request: [*]const u8, size: u32, header: *a.ServiceMessageHeader, output: [*]u8, capacity: u32, _: u64) callconv(.c) i32 {
            calls += 1;
            if (op != a.clipboard_offer_op_read or size != @sizeOf(a.ClipboardOfferTransfer) or capacity < @sizeOf(offers.Chunk)) return -99;
            const input = std.mem.bytesToValue(a.ClipboardOfferTransfer, request[0..@sizeOf(a.ClipboardOfferTransfer)]);
            if (input.provider != 17) return a.clipboard_offer_error_provider_changed;
            if (input.id != 3) return a.clipboard_offer_error_not_found;
            header.* = .{};
            const chunk: offers.Chunk = .{ .provider = 17, .id = 3, .revision = 9, .flags = a.clipboard_offer_flag_eof };
            @memcpy(output[0..@sizeOf(offers.Chunk)], std.mem.asBytes(&chunk));
            return @sizeOf(offers.Chunk);
        }
        fn close(_: u32) callconv(.c) i32 {
            return 0;
        }
    };
    Provider.calls = 0;
    var client: offers.Client = .{ .call = Provider.call, .close_call = Provider.close, .handle = 1, .timeout_ticks = a.io_wait_forever };
    var lease: offers.Lease = .{ .provider = 17, .id = 3, .revision = 9, .expires_ns = 100, .state = a.clipboard_offer_state_snapshot };
    const format: offers.Format = .{ .format = a.clipboard_offer_format_text_utf8 };
    var empty: [0]u8 = .{};
    try t.expectEqual(@as(i32, 0), control.readText(&client, &lease, &format, &empty));
    try t.expectEqual(@as(usize, 1), Provider.calls);
    var field: gui.TextField(32) = .{};
    try t.expect(field.setExact("kept"));
    lease.provider = 18;
    try t.expectEqual(a.clipboard_offer_error_provider_changed, field.pasteOffer(&client, &lease, &format, &empty));
    try t.expectEqualStrings("kept", field.value());
    lease.provider = 17;
    lease.revision = 10;
    try t.expectEqual(a.clipboard_offer_error_invalid, field.pasteOffer(&client, &lease, &format, &empty));
    try t.expectEqualStrings("kept", field.value());
    try t.expectEqual(@as(i32, 0), client.close());
    try t.expectEqual(a.clipboard_offer_error_closed, field.pasteOffer(&client, &lease, &format, &empty));
    try t.expectEqual(@as(usize, 3), Provider.calls);
}

test "composition owner chunk staging shares one deadline and retains uncertain mutation identity" {
    const offers = @import("clipboard_offer.zig");
    const control = @import("gui_text_control.zig");
    const Peer = struct {
        var now: u64 = 1_000_000_000;
        var generation: u32 = 3;
        var calls: u32 = 0;
        var mode: u32 = 0;
        var budgets: [4]u64 = @splat(0);
        fn clock(out: *a.MonotonicClockInfo) callconv(.c) i32 {
            out.* = .{ .flags = a.monotonic_clock_flag_valid, .source = 1, .generation = generation, .frequency_hz = a.monotonic_clock_frequency_hz, .resolution_ns = 1, .instant_ns = now, .event_requested_hz = 1000, .event_effective_hz = 999 };
            return 1;
        }
        fn call(channel: u32, op: u16, request: [*]const u8, size: u32, header: *a.ServiceMessageHeader, _: [*]u8, _: u32, ticks: u64) callconv(.c) i32 {
            std.debug.assert(channel == 17 and size >= @sizeOf(offers.Transfer));
            std.debug.assert(op == a.clipboard_offer_op_declare or op == a.clipboard_offer_op_put);
            const transfer = std.mem.bytesToValue(offers.Transfer, request[0..@sizeOf(offers.Transfer)]);
            std.debug.assert(transfer.provider == 19 and transfer.id == 23);
            budgets[calls] = ticks;
            calls += 1;
            now += 3_000_000;
            header.* = .{};
            if (mode == 1 and calls == 2) generation += 1;
            if (mode == 2 and calls == 2) return a.service_api_result_timeout;
            return 0;
        }
        fn close(_: u32) callconv(.c) i32 {
            return 0;
        }
    };
    const stage: offers.Lease = .{ .provider = 19, .id = 23, .state = a.clipboard_offer_state_writing };
    const before = stage;
    const text = [_]u8{'x'} ** (a.clipboard_offer_put_chunk * 4);
    const client: offers.Client = .{ .call = Peer.call, .close_call = Peer.close, .handle = 17, .timeout_ticks = 10, .clock = Peer.clock };
    for (0..3) |mode| {
        Peer.now = 1_000_000_000;
        Peer.generation = 3;
        Peer.calls = 0;
        Peer.mode = @intCast(mode);
        Peer.budgets = @splat(0);
        const rc = control.stageText(&client, &stage, &text);
        try t.expectEqual(if (mode == 1) @as(i32, -5) else a.service_api_result_timeout, rc);
        try t.expectEqual(if (mode == 0) @as(u32, 4) else @as(u32, 2), Peer.calls);
        try t.expectEqual(@as(u64, 10), Peer.budgets[0]);
        try t.expectEqual(@as(u64, 7), Peer.budgets[1]);
        if (mode == 0) {
            try t.expectEqual(@as(u64, 4), Peer.budgets[2]);
            try t.expectEqual(@as(u64, 1), Peer.budgets[3]);
        }
        try t.expectEqualDeep(before, stage);
        try t.expectEqual(@as(u32, 17), client.handle);
    }
}

test "composition owner normal controls preserve preedit cancel and exact atomic commit" {
    var field: gui.TextField(64) = .{};
    try t.expect(field.setExact("abcd"));
    field.setSelection(1, 3);
    var state: o.Owner = undefined;
    var rev: u64 = 7;
    var id: o.Id = undefined;
    const view = focus();
    const method = provider();
    const caret: o.Caret = .{};
    try t.expectEqual(@as(i32, 0), o.Owner.init(99, &state));
    const absent: o.Provider = .{};
    try t.expectEqual(a.composition_error_no_provider, field.beginComposition(&state, &view, &absent, rev, &caret, &id));
    try t.expectEqualStrings("abcd", field.value());
    try t.expectEqual(@as(i32, 0), field.beginComposition(&state, &view, &method, rev, &caret, &id));
    const preedit = event(id, 1, a.composition_event_preedit, rev, .{ .start = 1, .end = 3 }, "e\u{301}");
    try t.expectEqual(@as(i32, 0), field.applyComposition(&state, &view, &method, &preedit, "e\u{301}", &rev));
    try t.expectEqualStrings("abcd", field.value());
    try t.expectEqual(@as(u64, 7), rev);
    const commit = event(id, 2, a.composition_event_commit, rev, .{ .start = 1, .end = 3 }, "e\u{301}");
    try t.expectEqual(@as(i32, 0), field.applyComposition(&state, &view, &method, &commit, "e\u{301}", &rev));
    try t.expectEqualStrings("ae\u{301}d", field.value());
    try t.expectEqual(@as(u64, 8), rev);
    try t.expectEqual(@as(usize, 4), field.cursor);
    try t.expect(!field.hasSelection());

    var area: gui.TextArea(64) = .{};
    try t.expectEqual(@as(i32, 0), o.Owner.init(100, &state));
    area.set("e\u{301}x");
    area.setSelection(0, 3);
    const area_view = gui.TextAreaView.init(20, 4);
    try t.expectEqual(@as(i32, 0), area.beginComposition(&state, &view, &method, rev, &caret, &id));
    const invalid = event(id, 1, a.composition_event_commit, rev, .{ .start = 1, .end = 3 }, "z");
    try t.expectEqual(a.composition_error_range, area.applyComposition(&state, &view, &method, &invalid, "z", &rev, &area_view));
    try t.expectEqualStrings("e\u{301}x", area.value());
    var changed = view;
    changed.focus_generation += 1;
    const pending = event(id, 1, a.composition_event_commit, rev, .{ .start = 0, .end = 3 }, "z");
    try t.expectEqual(a.composition_error_stale_view, area.applyComposition(&state, &changed, &method, &pending, "z", &rev, &area_view));
    try t.expectEqualStrings("e\u{301}x", area.value());
    try t.expectEqual(@as(u64, 8), rev);
    try t.expectEqual(@as(i32, 0), area.beginComposition(&state, &view, &method, rev, &caret, &id));
    const cancel = event(id, 1, a.composition_event_cancel, rev, .{}, "");
    try t.expectEqual(@as(i32, 0), area.applyComposition(&state, &view, &method, &cancel, "", &rev, &area_view));
    try t.expectEqualStrings("e\u{301}x", area.value());
    try t.expectEqual(@as(u64, 8), rev);
}
test "composition owner preedit leaves document exact until original valid commit" {
    var doc: [64]u8 = @splat(0xa5);
    @memcpy(doc[0..4], "abcd");
    var len: usize = 4;
    var rev: u64 = 7;
    var state: o.Owner = undefined;
    const id = try begin(&state, rev, doc[0..len], .{ .start = 1, .end = 3 });
    const before = doc;
    try t.expectEqual(@as(i32, 0), state.apply(focus(), provider(), event(id, 1, 1, rev, .{ .start = 1, .end = 3 }, "e\u{301}"), "e\u{301}", &doc, &len, &rev));
    try t.expectEqualDeep(before, doc);
    try t.expectEqualStrings("e\u{301}", state.preedit().?);
    try t.expectEqual(@as(u64, 7), rev);
    try t.expectEqual(@as(i32, 0), state.apply(focus(), provider(), event(id, 2, 2, rev, .{ .start = 1, .end = 3 }, "\u{1f469}\u{200d}\u{1f4bb}"), "\u{1f469}\u{200d}\u{1f4bb}", &doc, &len, &rev));
    try t.expectEqualStrings("a\u{1f469}\u{200d}\u{1f4bb}d", doc[0..len]);
    try t.expectEqual(@as(u64, 8), rev);
    try t.expect(state.preedit() == null);
}
test "composition owner rejects scalar-interior grapheme ranges invalid UTF8 NUL and whole capacity" {
    var doc: [16]u8 = @splat(0xa5);
    @memcpy(doc[0..4], "e\u{301}x");
    var len: usize = 4;
    var rev: u64 = 1;
    var state: o.Owner = undefined;
    const id = try begin(&state, rev, doc[0..len], .{});
    const before = doc;
    var e = event(id, 1, 1, rev, .{ .start = 1, .end = 3 }, "ok");
    try t.expectEqual(a.composition_error_range, state.apply(focus(), provider(), e, "ok", &doc, &len, &rev));
    e = event(id, 1, 1, rev, .{}, "e\u{301}");
    e.selection.end = 1;
    try t.expectEqual(a.composition_error_range, state.apply(focus(), provider(), e, "e\u{301}", &doc, &len, &rev));
    const bad = [_]u8{ 0xc0, 0xaf };
    try t.expectEqual(a.composition_error_encoding, state.apply(focus(), provider(), event(id, 1, 1, rev, .{}, &bad), &bad, &doc, &len, &rev));
    try t.expectEqual(a.composition_error_encoding, state.apply(focus(), provider(), event(id, 1, 1, rev, .{}, "a\x00"), "a\x00", &doc, &len, &rev));
    const large = [_]u8{'x'} ** 1025;
    try t.expectEqual(a.composition_error_capacity, state.apply(focus(), provider(), event(id, 1, 1, rev, .{}, &large), &large, &doc, &len, &rev));
    try t.expectEqualDeep(before, doc);
    try t.expectEqual(@as(usize, 4), len);
    try t.expectEqual(@as(u64, 1), rev);
    const full = [_]u8{'x'} ** 16;
    try t.expectEqual(a.composition_error_capacity, state.apply(focus(), provider(), event(id, 1, 2, rev, .{}, &full), &full, &doc, &len, &rev));
    try t.expectEqualDeep(before, doc);
}
test "composition owner focus view provider and text changes cancel only matching old session" {
    var state: o.Owner = undefined;
    var doc = [_]u8{'a'} ** 16;
    var len: usize = 1;
    var rev: u64 = 1;
    var id = try begin(&state, rev, doc[0..len], .{});
    const before = doc;
    var view = focus();
    view.focused = 0;
    try t.expectEqual(a.composition_error_no_focus, state.apply(view, provider(), event(id, 1, 2, rev, .{}, "b"), "b", &doc, &len, &rev));
    try t.expect(state.preedit() == null);
    try t.expectEqualDeep(before, doc);
    try t.expectEqual(@as(i32, 0), state.begin(focus(), provider(), rev, doc[0..len], .{}, .{}, &id));
    view = focus();
    view.window.owner.generation += 1;
    try t.expectEqual(a.composition_error_stale_view, state.refresh(view, provider(), rev));
    try t.expectEqual(@as(i32, 0), state.begin(focus(), provider(), rev, doc[0..len], .{}, .{}, &id));
    view = focus();
    view.focus_generation += 1;
    try t.expectEqual(a.composition_error_stale_view, state.refresh(view, provider(), rev));
    try t.expectEqual(@as(i32, 0), state.begin(focus(), provider(), rev, doc[0..len], .{}, .{}, &id));
    var method = provider();
    method.generation += 1;
    try t.expectEqual(a.composition_error_provider_changed, state.refresh(focus(), method, rev));
    try t.expectEqual(@as(i32, 0), state.begin(focus(), provider(), rev, doc[0..len], .{}, .{}, &id));
    try t.expectEqual(a.composition_error_stale_text, state.refresh(focus(), provider(), 2));
    try t.expectEqualDeep(before, doc);
}
test "composition owner stale cancel replay and superseded events cannot affect newer session" {
    var state: o.Owner = undefined;
    var doc = [_]u8{'a'} ** 16;
    var len: usize = 1;
    var rev: u64 = 1;
    const old = try begin(&state, rev, doc[0..len], .{});
    try t.expectEqual(@as(i32, 0), state.cancel(old));
    var id: o.Id = undefined;
    try t.expectEqual(@as(i32, 0), state.begin(focus(), provider(), rev, doc[0..len], .{}, .{}, &id));
    try t.expect(id.session_generation > old.session_generation);
    try t.expectEqual(a.composition_error_stale_session, state.cancel(old));
    var lost = focus();
    lost.focused = 0;
    try t.expectEqual(a.composition_error_stale_session, state.apply(lost, provider(), event(old, 2, 2, rev, .{}, "b"), "b", &doc, &len, &rev));
    try t.expect(state.preedit() != null);
    const e = event(id, 1, 1, rev, .{}, "b");
    try t.expectEqual(@as(i32, 0), state.apply(focus(), provider(), e, "b", &doc, &len, &rev));
    try t.expectEqual(a.composition_error_stale_session, state.apply(focus(), provider(), e, "b", &doc, &len, &rev));
    try t.expectEqualStrings("b", state.preedit().?);
    try t.expectEqual(@as(i32, 0), state.apply(focus(), provider(), event(id, 2, 3, rev, .{}, ""), "", &doc, &len, &rev));
    try t.expect(state.preedit() == null);
    try t.expectEqual(@as(u8, 'a'), doc[0]);
}
test "composition owner bounded surrounding caret scope NoProvider and nonwrapping identities" {
    var state: o.Owner = undefined;
    const text = "Ae\u{301}B";
    _ = try begin(&state, 1, text, .{});
    var bytes: [16]u8 = @splat(0xa5);
    var count: usize = 99;
    try t.expectEqual(a.composition_error_range, state.surrounding(focus(), provider(), 1, text, .{ .start = 2, .end = 4 }, &bytes, &count));
    try t.expectEqual(@as(usize, 99), count);
    try t.expectEqual(@as(i32, 0), state.surrounding(focus(), provider(), 1, text, .{ .start = 1, .end = 4 }, &bytes, &count));
    try t.expectEqualStrings("e\u{301}", bytes[0..count]);
    var caret: o.Caret = undefined;
    try t.expectEqual(@as(i32, 0), state.setCaret(focus(), provider(), 1, .{ .x = 3, .y = 4, .height = 12, .scale_numerator = 3, .scale_denominator = 2 }));
    try t.expectEqual(@as(i32, 0), state.queryCaret(focus(), provider(), 1, &caret));
    try t.expectEqual(@as(i32, 3), caret.x);
    try t.expectEqual(@as(u32, 2), caret.scale_denominator);
    _ = state.cancel(state.id);
    var id: o.Id = undefined;
    try t.expectEqual(a.composition_error_no_provider, state.begin(focus(), .{}, 1, text, .{}, .{}, &id));
    state.next_generation = std.math.maxInt(u64);
    try t.expectEqual(a.composition_error_exhausted, state.begin(focus(), provider(), 1, text, .{}, .{}, &id));
}
