const std = @import("std");
const m = @import("file_picker.zig");
const a = m.abi;
const text = @import("bounded_text.zig");
const legacy = @import("directory_page.zig");
const storage = @import("app_storage.zig");
const program = @import("program.zig");
const sys = @import("r4sys.zig");
const gui = @import("gui.zig");
const api = @import("file_picker_api.zig");
const wire = @import("binary_cursor.zig");
const names = [_][]const u8{ "A.TXT", "hide.bin", "Sub", "äname.txt", "B.txt", "last.dat", "C.TXT" };
var calls: u32 = 0;
var ns: u64 = 9;
var mode: i32 = 0;
var replacement = false;
var reentrant: ?*m.Session = null;
var busy_observed = false;
fn reset() void {
    calls = 0;
    ns = 9;
    mode = 0;
    replacement = false;
    reentrant = null;
    busy_observed = false;
}
fn meta(index: u64, dir: bool) a.FileMetadata2 {
    return .{ .flags = 1 | 4 | (if (dir) @as(u32, 2) else 8), .byte_size = if (dir) 0 else index * 3, .identity = .{ .mount_generation = 23, .namespace_generation = ns, .mount_slot = 4, .provider = 2, .object_hi = index + (if (replacement) @as(u64, 100) else 0), .flags = 1 | 4 } };
}
fn full(index: usize) a.DirectoryMetadataEntry2 {
    var entry: a.DirectoryMetadataEntry2 = .{ .info = meta(index + 2, index == 2) };
    _ = std.fmt.bufPrintZ(&entry.path, "C:\\DIR\\{s}", .{names[index]}) catch unreachable;
    return entry;
}
fn info(path: [*:0]const u8, out: *a.FileMetadata2) callconv(.c) i32 {
    calls += 1;
    const value = std.mem.span(path);
    if (mode == 8 and std.mem.eql(u8, value, "C:\\DIR\\A.TXT")) return 0;
    if (mode == 11 and std.mem.eql(u8, value, "C:\\DIR\\Sub")) {
        out.* = meta(4, false);
        return 1;
    }
    if (std.mem.eql(u8, value, "C:\\MISSING") or std.mem.endsWith(u8, value, "NEW.TXT")) return 0;
    if (std.mem.eql(u8, value, "C:\\") or std.mem.eql(u8, value, "C:\\DIR")) {
        out.* = meta(1, true);
        return 1;
    }
    for (names, 0..) |_, index| {
        const entry = full(index);
        if (std.mem.eql(u8, value, std.mem.sliceTo(&entry.path, 0))) {
            out.* = entry.info;
            return 1;
        }
    }
    return 0;
}
fn batch(_: ?[*:0]const u8, cursor: *a.DirectoryMetadataCursor2, out: ?[*]a.DirectoryMetadataEntry2, capacity: u32) callconv(.c) i32 {
    calls += 1;
    if (cursor.flags == 1 and cursor.namespace_generation != ns) return -10;
    if (capacity == 0) return if (mode == -10) -10 else 0;
    if (mode == -9 and cursor.scan.backend[0] == names.len) return -9;
    cursor.flags = 1;
    cursor.namespace_generation = ns;
    cursor.scan.change.mount_generation = 23;
    cursor.scan.change.mount_slot = 4;
    if (mode == 3) return 0;
    if (cursor.scan.backend[0] == names.len) return -5;
    out.?[0] = full(@intCast(cursor.scan.backend[0]));
    cursor.scan.backend[0] += 1;
    if (mode == 4) @memset(&out.?[0].path, 'x');
    if (mode == 5) return 2;
    if (mode == 6) out.?[0].info.size = 111;
    return 1;
}
fn oldParent(_: [*:0]const u8, index: u32, out: [*]u8, capacity: u32) callconv(.c) i32 {
    if (index != 1 or capacity < 4) return -1;
    _ = text.assignZ(out[0..capacity], "C:\\");
    return 1;
}
fn oldBatch(_: ?[*:0]const u8, cursor: *a.DirectoryBatchCursor, out: ?[*]a.DirectoryBatchEntry, capacity: u32) callconv(.c) i32 {
    if (capacity == 0) return 0;
    if (cursor.backend[0] == names.len) return if (mode == -9) -9 else -5;
    var count: u32 = 0;
    while (count < capacity and cursor.backend[0] < names.len) : (count += 1) {
        const index: usize = @intCast(cursor.backend[0]);
        const entry = full(index);
        out.?[count] = .{ .path = entry.path, .info = .{ .exists = 1, .is_dir = @intFromBool(index == 2) } };
        cursor.backend[0] += 1;
    }
    return @intCast(count);
}
fn done(session: *m.Session) !void {
    var steps: u32 = 0;
    while (session.phase != 0 and steps < 100) : (steps += 1) {
        const before = calls;
        try std.testing.expectEqual(@as(i32, 0), session.step(2));
        try std.testing.expect(calls - before <= 2);
    }
    try std.testing.expectEqual(@as(u32, 0), session.phase);
}
test "file picker owner actual original DialogPage oracle bounded budgets" {
    var table: @import("r4os_contract2").R4XStartR4Sys2 = .{};
    table.dir_entry = @intFromPtr(&oldParent);
    table.directory_batch = @intFromPtr(&oldBatch);
    const raw: @import("r4os_contract2").R4XStartContext2 = .{};
    const bundle: program.Bundle = .{ .raw = &raw, .sys = &table };
    const files: storage.Files = .{ .sys = sys.Context.init(&bundle) };
    inline for (.{ 4, 6, 12 }) |capacity| {
        for ([_][]const u8{ "", ".TXT", ".bin" }) |extension| {
            for (0..8) |number| {
                reset();
                var old = legacy.DialogPage(capacity, 1024, 256){};
                try std.testing.expect(old.load(files, .{ .ptr = "C:\\DIR", .len = 6 }, @intCast(number), extension));
                var left: [capacity]m.Row = undefined;
                var right: [capacity]m.Row = undefined;
                var session: m.Session = undefined;
                try std.testing.expectEqual(@as(i32, 0), m.Session.init(&left, &right, m.mode_open, extension, .{ .info = &info, .batch = &batch }, &session));
                try std.testing.expectEqual(@as(i32, 0), session.begin("C:\\DIR", @intCast(number)));
                try std.testing.expect(session.rows() == null);
                try done(&session);
                const rows = session.rows().?;
                try std.testing.expectEqual(old.count, rows.len);
                for (rows, old.rows[0..old.count]) |new, original| {
                    try std.testing.expectEqual(@intFromEnum(original.kind), new.kind);
                    try std.testing.expectEqualStrings(std.mem.sliceTo(&original.path, 0), std.mem.sliceTo(&new.entry.path, 0));
                    try std.testing.expectEqualStrings(std.mem.sliceTo(&original.label, 0), std.mem.sliceTo(&new.label, 0));
                }
                try std.testing.expectEqual(@as(u64, 1), session.revision);
            }
        }
    }
    std.debug.print("FP024 original DialogPage:72complete pages/three capacities/three filters exact, each step<=2provider calls\n", .{});
}
test "file picker owner incomplete error restart and stale identities preserve publication" {
    reset();
    var a_rows: [6]m.Row = undefined;
    var b_rows: [6]m.Row = undefined;
    var session: m.Session = undefined;
    try std.testing.expectEqual(@as(i32, 0), m.Session.init(&a_rows, &b_rows, 1, ".TXT", .{ .info = &info, .batch = &batch }, &session));
    try std.testing.expectEqual(@as(i32, 0), session.begin("C:\\DIR", 0));
    try done(&session);
    try std.testing.expectEqual(@as(i32, 0), session.select(session.revision, 1, 1));
    var decision: m.Decision = .{};
    try std.testing.expectEqual(@as(i32, 0), session.activate(session.revision, false, false, &decision));
    try std.testing.expectEqual(@as(u32, 1), decision.kind);
    const confirmed = session.confirmed;
    const first = session.rows().?[1];
    const addr = session.active.address;
    for ([_]i32{ -9, -10, 4, 5, 6 }) |failure| {
        mode = 0;
        try std.testing.expectEqual(@as(i32, 0), session.begin("C:\\DIR", 1));
        mode = failure;
        if (failure == -10) {
            try std.testing.expectEqual(@as(i32, 0), session.step(2));
            ns += 1;
        }
        var code: i32 = 0;
        for (0..20) |_| {
            code = session.step(2);
            if (code != 0 or session.phase == 0) break;
        }
        try std.testing.expectEqual(if (failure == -9 or failure == -10) failure else m.bad_provider, code);
        try std.testing.expectEqual(addr, session.active.address);
        try std.testing.expectEqual(@as(u64, 1), session.revision);
        try std.testing.expectEqual(@as(u32, 1), session.selected);
        try std.testing.expect(std.meta.eql(first, session.rows().?[1]));
        try std.testing.expect(std.meta.eql(confirmed, session.confirmed));
        ns = 9;
    }
    mode = 0;
    try std.testing.expectEqual(@as(i32, 0), session.begin("C:\\MISSING", 0));
    try std.testing.expectEqual(m.missing, session.step(1));
    try std.testing.expectEqual(addr, session.active.address);
    replacement = true;
    const prior = decision;
    try std.testing.expectEqual(m.stale, session.activate(session.revision, false, false, &decision));
    try std.testing.expect(std.meta.eql(prior, decision));
    try std.testing.expect(std.meta.eql(confirmed, session.confirmed));
    replacement = false;
    ns += 1;
    try std.testing.expectEqual(m.stale, session.activate(session.revision, false, false, &decision));
    ns = 9;
    try std.testing.expectEqual(m.stale, session.select(0, 1, 1));
    mode = 3;
    try std.testing.expectEqual(@as(i32, 0), session.begin("C:\\DIR", 0));
    try std.testing.expectEqual(@as(i32, 0), session.step(1));
    const before = calls;
    try std.testing.expectEqual(@as(i32, 0), session.step(64));
    try std.testing.expectEqual(@as(u32, 64), calls - before);
    try std.testing.expectEqual(addr, session.active.address);
    var progress: m.Progress = undefined;
    try std.testing.expectEqual(@as(i32, 0), session.progress(&progress));
    try std.testing.expectEqual(@as(u32, 3), progress.flags);
    try std.testing.expectEqual(@as(i32, 0), session.cancel(&decision));
    try std.testing.expectEqual(@as(u32, 3), decision.kind);
    try std.testing.expect(std.meta.eql(confirmed, session.confirmed));
    try std.testing.expectEqual(m.closed, session.step(1));
}
fn filter(_: ?*anyopaque, _: *const a.DirectoryMetadataEntry2) callconv(.c) i32 {
    if (reentrant) |session| {
        var decision: m.Decision = .{};
        var progress: m.Progress = undefined;
        busy_observed = session.cancel(&decision) == m.busy and session.step(1) == m.busy and
            session.begin("C:\\DIR", 0) == m.busy and session.progress(&progress) == 0 and progress.flags & 4 != 0;
    }
    return if (mode == 7) -77 else 1;
}
test "file picker owner navigation keyboard save overwrite and callback lifetime" {
    reset();
    var left: [4]m.Row = undefined;
    var right: [4]m.Row = undefined;
    var session: m.Session = undefined;
    try std.testing.expectEqual(@as(i32, 0), m.Session.init(&left, &right, 2, ".txt", .{ .info = &info, .batch = &batch, .filter = &filter }, &session));
    reentrant = &session;
    try std.testing.expectEqual(@as(i32, 0), session.begin("C:/DIR/.", 0));
    try done(&session);
    try std.testing.expect(busy_observed);
    var decision: m.Decision = .{};
    try std.testing.expectEqual(@as(i32, 0), session.select(1, session.count - 1, 2));
    try std.testing.expectEqual(m.next, session.rows().?[session.selected].kind);
    try std.testing.expectEqual(@as(i32, 0), session.activate(1, false, false, &decision));
    try done(&session);
    try std.testing.expectEqual(@as(u32, 1), session.number);
    try std.testing.expectEqual(@as(u64, 2), session.revision);
    try std.testing.expectEqual(m.stale, session.select(1, 0, 2));
    try std.testing.expectEqual(m.previous, session.rows().?[1].kind);
    try std.testing.expectEqual(@as(i32, 0), session.select(2, 1, 2));
    try std.testing.expectEqual(@as(i32, 0), session.activate(2, false, false, &decision));
    try done(&session);
    try std.testing.expectEqual(@as(u32, 0), session.number);
    try std.testing.expectEqual(@as(i32, 0), session.key(gui.Key.up, 2, &decision));
    try std.testing.expectEqual(session.count - 1, session.selected);
    try std.testing.expectEqual(@as(i32, 0), session.key(gui.Key.down, 2, &decision));
    try std.testing.expectEqual(@as(u32, 0), session.selected);
    try std.testing.expectEqual(@as(i32, 0), session.key(gui.Key.tab, 2, &decision));
    try std.testing.expectEqual(@as(u32, 1), session.focus);
    try std.testing.expectEqual(@as(i32, 0), session.setName("A.TXT"));
    try std.testing.expectEqual(@as(i32, 0), session.key(gui.Key.enter, 2, &decision));
    try std.testing.expectEqual(m.decision_overwrite, decision.kind);
    try std.testing.expectEqual(@as(u32, 0), session.confirmed.kind);
    try std.testing.expectEqual(@as(i32, 0), session.activate(session.revision, true, true, &decision));
    try std.testing.expectEqual(m.decision_file, decision.kind);
    const saved = session.confirmed;
    for ([_][]const u8{ "..", ".", "a/b", "a\\b", "bad?", "\xc3", "\xf4\x90\x80\x80.TXT" }) |bad| try std.testing.expectEqual(m.invalid, session.setName(bad));
    try std.testing.expectEqualStrings("A.TXT", std.mem.sliceTo(&session.filename, 0));
    try std.testing.expectEqual(@as(i32, 0), session.setName("🙂.TXT"));
    try std.testing.expectEqual(@as(i32, 0), session.setName("NEW.TXT"));
    try std.testing.expectEqual(@as(i32, 0), session.activate(session.revision, true, false, &decision));
    try std.testing.expectEqual(m.decision_file, decision.kind);
    try std.testing.expectEqual(@as(u32, 0), decision.entry.info.flags);
    mode = 7;
    try std.testing.expectEqual(@as(i32, 0), session.begin("C:\\DIR", 0));
    try std.testing.expectEqual(@as(i32, -77), session.step(64));
    try std.testing.expectEqual(@as(u64, 3), session.revision);
    var items: [4][]const u8 = undefined;
    const dialog = api.dialog(&session, .{ .x = 0, .y = 0, .w = 400, .h = 300 }, "Save", &items).?;
    try std.testing.expectEqualStrings("C:\\DIR", dialog.path);
    try std.testing.expectEqual(@as(usize, session.count), dialog.items.len);
    try std.testing.expectEqual(@intFromPtr(&session.rows().?[1].label), @intFromPtr(dialog.items[1].ptr));
    try std.testing.expectEqual(gui.DialogAction.select, dialog.focus_action);
    try std.testing.expectEqualStrings("NEW.TXT", dialog.file_name);
    try std.testing.expectEqual(@as(i32, 0), session.key(gui.Key.escape, 2, &decision));
    try std.testing.expectEqual(m.decision_cancelled, decision.kind);
    try std.testing.expectEqualStrings("C:\\DIR\\NEW.TXT", std.mem.sliceTo(&session.confirmed.entry.path, 0));
    try std.testing.expect(!std.meta.eql(saved, session.confirmed));
}
test "file picker owner storage availability and nonreused page revision" {
    reset();
    var left: [4]m.Row = undefined;
    var right: [4]m.Row = undefined;
    var session: m.Session = undefined;
    try std.testing.expectEqual(m.storage_error, m.Session.init(&left, &left, 1, "", .{}, &session));
    try std.testing.expectEqual(m.invalid, m.Session.init(&left, &right, 3, "", .{}, &session));
    try std.testing.expectEqual(@as(i32, 0), m.Session.init(&left, &right, 1, "", .{}, &session));
    try std.testing.expectEqual(m.invalid, session.begin("C:\\..", 0));
    try std.testing.expectEqual(@as(i32, 0), session.begin("C:\\DIR", 0));
    try std.testing.expectEqual(a.err_no_fn, session.step(1));
    var decision: m.Decision = .{};
    try std.testing.expectEqual(m.invalid, session.setFocus(1, 4));
    try std.testing.expectEqual(@as(i32, 0), session.key(gui.Key.tab, 2, &decision));
    try std.testing.expectEqual(@as(u32, 2), session.focus); // Open skips disabled name field.
    try std.testing.expectEqual(@as(i32, 0), session.key(gui.Key.shift_tab, 2, &decision));
    try std.testing.expectEqual(@as(u32, 0), session.focus);
    try std.testing.expectEqual(m.invalid, session.step(0));
    session.revision = std.math.maxInt(u64);
    try std.testing.expectEqual(m.exhausted, session.begin("C:\\DIR", 0));
    const end = wire.Span{ .address = std.math.maxInt(usize) - 2, .length = 10 };
    try std.testing.expectEqual(m.storage_error, m.Session.initSpans(end, end, 4, 1, "", .{}, &session));
}

test "file picker owner overwrite permission binds observed target and expires on changes" {
    reset();
    var left: [6]m.Row = undefined;
    var right: [6]m.Row = undefined;
    var session: m.Session = undefined;
    try std.testing.expectEqual(@as(i32, 0), m.Session.init(&left, &right, 2, ".TXT", .{ .info = &info, .batch = &batch }, &session));
    try std.testing.expectEqual(@as(i32, 0), session.begin("C:\\DIR", 0));
    try done(&session);
    var decision: m.Decision = .{};
    try std.testing.expectEqual(@as(i32, 0), session.setName("A.TXT"));
    try std.testing.expectEqual(@as(i32, 0), session.activate(session.revision, true, false, &decision));
    try std.testing.expectEqual(m.decision_overwrite, decision.kind);
    try std.testing.expectEqual(@as(u32, 1), session.overwrite_pending);
    const observed = decision;
    replacement = true; // Different canonical object with unchanged namespace mock.
    try std.testing.expectEqual(m.stale, session.activate(session.revision, true, true, &decision));
    try std.testing.expect(std.meta.eql(observed, decision));
    try std.testing.expectEqual(@as(u32, 0), session.confirmed.kind);
    replacement = false;
    try std.testing.expectEqual(@as(i32, 0), session.activate(session.revision, true, true, &decision));
    try std.testing.expectEqual(m.decision_file, decision.kind);
    try std.testing.expectEqual(@as(u32, 0), session.overwrite_pending);
    const confirmed = session.confirmed;
    try std.testing.expectEqual(m.stale, session.activate(session.revision, true, true, &decision));
    try std.testing.expectEqual(@as(i32, 0), session.activate(session.revision, true, false, &decision));
    mode = 8; // Existing target disappeared after the overwrite question.
    try std.testing.expectEqual(m.stale, session.activate(session.revision, true, true, &decision));
    try std.testing.expect(std.meta.eql(confirmed, session.confirmed));
    mode = 0;
    try std.testing.expectEqual(@as(i32, 0), session.setName("B.txt"));
    try std.testing.expectEqual(@as(u32, 0), session.overwrite_pending);
    try std.testing.expectEqual(m.stale, session.activate(session.revision, true, true, &decision));
    try std.testing.expect(std.meta.eql(confirmed, session.confirmed));
    try std.testing.expectEqual(@as(i32, 0), session.setName("A.TXT"));
    try std.testing.expectEqual(@as(i32, 0), session.activate(session.revision, true, false, &decision));
    try std.testing.expectEqual(@as(i32, 0), session.begin("C:\\DIR", 0));
    try std.testing.expectEqual(@as(u32, 0), session.overwrite_pending);
    try done(&session);
    try std.testing.expectEqual(m.stale, session.activate(session.revision, true, true, &decision));
    try std.testing.expectEqual(@as(i32, 0), session.select(session.revision, 2, 2));
    mode = 11;
    try std.testing.expectEqual(m.stale, session.activate(session.revision, false, false, &decision));
    try std.testing.expect(std.meta.eql(confirmed, session.confirmed));
}
