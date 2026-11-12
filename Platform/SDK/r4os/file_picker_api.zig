//! Picker controller over the existing metadata and GUI owners.
const owner = @import("file_picker.zig");
const platform = @import("platform2.zig");
const gui = @import("gui.zig");
const std = @import("std");
pub const Session = owner.Session;
pub const Row = owner.Row;
pub const Provider = owner.Provider;
pub const Decision = owner.Decision;
pub const Progress = owner.Progress;
pub const codes = owner;
pub const Binding = struct { status: i32, provider: Provider = .{} };
pub fn provider2(context: *const platform.Context) Binding {
    var info: u64 = 0;
    var batch: u64 = 0;
    var rc = context.lookup(1, @offsetOf(platform.abi.R4XStartR4Sys2, "file_metadata2"), &info);
    if (rc != 0) return .{ .status = rc };
    rc = context.lookup(1, @offsetOf(platform.abi.R4XStartR4Sys2, "directory_metadata_batch2"), &batch);
    if (rc != 0) return .{ .status = rc };
    return .{ .status = 0, .provider = .{ .info = @ptrFromInt(info), .batch = @ptrFromInt(batch) } };
}
/// Labels and items borrow the current page. Discard both before any mutable
/// controller call. Existing FileDialog owns drawing/hit testing as before.
pub fn dialog(session: *const Session, rect: gui.Rect, title: []const u8, items: [][]const u8) ?gui.FileDialog {
    const rows = session.rows() orelse return null;
    if (items.len < rows.len) return null;
    for (rows, 0..) |*row, index| items[index] = std.mem.sliceTo(&row.label, 0);
    // The existing FileDialog renders list/name as one .select focus group.
    const focus = [_]gui.DialogAction{ .select, .select, .ok, .cancel };
    return .{ .rect = rect, .title = title, .path = std.mem.sliceTo(&session.directory_path, 0), .items = items[0..rows.len], .mode = if (session.mode == owner.mode_save) .save else .open, .file_name = std.mem.sliceTo(&session.filename, 0), .selected_index = session.selected, .first_index = session.first_index, .focus_action = focus[session.focus], .pressed_action = if (session.pressed == 4) .none else focus[session.pressed] };
}
