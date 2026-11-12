// SYSUPD-only archival policy. Active journal objects are never candidates;
// an unreferenced boot backup is copied and verified before its old name ends.
const std = @import("std");

pub fn validName(name: []const u8) bool {
    if (name.len != 12 or std.ascii.toUpper(name[0]) != 'B' or !std.ascii.eqlIgnoreCase(name[8..], ".R4U")) return false;
    for (name[1..8]) |ch| if (!std.ascii.isHex(ch)) return false;
    return true;
}

fn folded(ch: u8) u8 {
    return if (ch == '/') '\\' else std.ascii.toUpper(ch);
}
fn bootPath(path: []const u8) []const u8 {
    return if (path.len >= 2 and std.ascii.toUpper(path[0]) == 'C' and path[1] == ':') path[2..] else path;
}
pub fn samePath(left: []const u8, right: []const u8) bool {
    const a = bootPath(left);
    const b = bootPath(right);
    if (a.len != b.len) return false;
    for (a, b) |x, y| if (folded(x) != folded(y)) return false;
    return true;
}
pub fn referenced(journal: anytype, source: []const u8) bool {
    if (samePath(journal.sourceText(), source)) return true;
    for (journal.payloads[0..journal.payload_count]) |*entry| {
        if (samePath(entry.targetText(), source) or samePath(entry.stageText(), source) or
            samePath(entry.backupText(), source) or samePath(entry.previousBackupText(), source)) return true;
    }
    return false;
}

pub const Error = error{ Referenced, Copy, Verification, Remove };
/// The caller holds SYSUPD's update lease. copy() is create-only, or admits
/// an already matching archive; failures retain the original. verify() binds
/// both complete contents. Recheck references after the potentially long copy.
pub fn archive(io: anytype) Error!void {
    if (!io.unreferenced()) return error.Referenced;
    if (!io.copy()) return error.Copy;
    if (!io.verify()) return error.Verification;
    if (!io.unreferenced()) return error.Referenced;
    if (!io.verify()) return error.Verification;
    if (!io.remove()) return error.Remove;
}

test "backup archive excludes every journal alias and retains original at failed copy/verification/reference boundaries" {
    const recovery = @import("system_update_recovery.zig");
    const t = std.testing;
    try t.expect(validName("BC6EF372.R4U"));
    try t.expect(validName("be3779b9.r4u"));
    for ([_][]const u8{ "S1234567.R4U", "B123456.R4U", "B12345678.R4U", "B123456Z.R4U", "../BC6EF372.R4U", "B1234567.ELF" }) |name| try t.expect(!validName(name));
    const journal = try t.allocator.create(recovery.TransactionJournal);
    defer t.allocator.destroy(journal);
    for (0..4) |field| {
        journal.* = .{};
        journal.payload_count = 1;
        const path = "C:/BOOT/bc6ef372.r4u";
        const entry = &journal.payloads[0];
        switch (field) {
            0 => {
                @memcpy(entry.target_path[0..path.len], path);
                entry.target_len = path.len;
            },
            1 => {
                @memcpy(entry.stage_path[0..path.len], path);
                entry.stage_len = path.len;
            },
            2 => {
                @memcpy(entry.backup_path[0..path.len], path);
                entry.backup_len = path.len;
            },
            else => {
                @memcpy(entry.previous_backup_path[0..path.len], path);
                entry.previous_backup_len = path.len;
            },
        }
        try t.expect(referenced(journal, "\\boot\\BC6EF372.R4U"));
        try t.expect(!referenced(journal, "\\boot\\BE3779B9.R4U"));
    }
    const Model = struct {
        fail_at: usize = 0,
        calls: usize = 0,
        original: bool = true,
        durable_copy: bool = false,
        fn step(self: *@This()) bool {
            self.calls += 1;
            return self.calls != self.fail_at;
        }
        fn unreferenced(self: *@This()) bool {
            return self.step();
        }
        fn copy(self: *@This()) bool {
            if (!self.step()) return false;
            self.durable_copy = true;
            return true;
        }
        fn verify(self: *@This()) bool {
            return self.step() and self.original and self.durable_copy;
        }
        fn remove(self: *@This()) bool {
            if (!self.step()) return false;
            std.debug.assert(self.durable_copy);
            self.original = false;
            return true;
        }
    };
    for (1..7) |failure| {
        var io: Model = .{ .fail_at = failure };
        if (archive(&io)) |_| return error.ExpectedFailure else |_| {}
        try t.expect(io.original);
        try t.expectEqual(failure, io.calls);
    }
    var io: Model = .{};
    try archive(&io);
    try t.expect(!io.original and io.durable_copy);
}
