const abi = @import("r4os_contract").abi;
const storage = @import("app_storage.zig");

pub const Result = enum {
    saved,
    saved_backup_retained,
    failed,
    failed_copies_retained,

    pub fn committed(self: Result) bool {
        return self == .saved or self == .saved_backup_retained;
    }

    pub fn message(self: Result) []const u8 {
        return switch (self) {
            .saved => "Saved",
            .saved_backup_retained => "Saved; backup retained",
            .failed => "Save failed",
            .failed_copies_retained => "Save not confirmed; temporary copies retained",
        };
    }
};

/// Caller-owned, synchronous document save policy. R4SYS owns the native
/// stream and same-directory atomic replacement; there is no direct-write
/// fallback. Relative paths keep their original parent/CWD semantics.
pub const Saver = struct {
    sequence: u32 = 0,

    pub fn save(self: *Saver, files: storage.Files, target: storage.PathZ, bytes: []const u8, require_target_absent: bool) Result {
        const path = target.bytes();
        if (path.len == 0 or path.len > 1023) return .failed;
        var stage_buf: [1024:0]u8 = undefined;
        var backup_buf: [1024:0]u8 = undefined;
        const seed: u32 = @truncate(files.sys.ticks() ^ @intFromPtr(self));
        for (0..64) |_| {
            self.sequence +%= 1;
            const id = seed +% self.sequence;
            const stage = sibling(&stage_buf, path, id, ".TMP") orelse return .failed;
            const backup = sibling(&backup_buf, path, id, ".BAK") orelse return .failed;
            const stage_alias = files.sys.pathNamesEqualCollated(target.ptr, stage.ptr);
            const backup_alias = files.sys.pathNamesEqualCollated(target.ptr, backup.ptr);
            if (stage_alias < 0 or backup_alias < 0) return .failed;
            if (stage_alias != 0 or backup_alias != 0) continue;
            switch (files.info(backup)) {
                .missing => {},
                .value => continue,
                .failure => return .failed,
            }
            var writer = switch (files.streamWriter(stage, abi.file_stream_open_create)) {
                .writer => |opened| opened,
                .failure => |code| {
                    if (code == abi.file_stream_error_exists) continue;
                    // A failed begin may already own a stream slot. Abort
                    // checks that exact slot; never delete a path blindly.
                    const aborted = files.sys.fileStreamAbort(stage.ptr);
                    return if (aborted == abi.file_stream_result_ok or aborted == abi.file_stream_error_not_found) .failed else .failed_copies_retained;
                },
            };
            var offset: usize = 0;
            while (offset < bytes.len) {
                const end = offset + @min(@as(usize, 64 * 1024), bytes.len - offset);
                if (writer.write(bytes[offset..end]) != .ok) return abortFailed(&writer);
                offset = end;
            }
            if (writer.finish() != .ok) return abortFailed(&writer);
            if (files.replaceAtomic(target, stage, backup, .{ .require_target_absent = require_target_absent }) != .ok) {
                // An I/O error may follow publication. Keep both siblings:
                // deleting either could discard the only complete copy.
                return .failed_copies_retained;
            }
            return switch (files.delete(backup)) {
                .ok, .missing => .saved,
                .failure => .saved_backup_retained,
            };
        }
        return .failed;
    }
};

fn abortFailed(writer: *storage.StreamWriter) Result {
    return if (writer.abort() == .ok) .failed else .failed_copies_retained;
}

fn sibling(out: *[1024:0]u8, target: []const u8, id: u32, extension: *const [4]u8) ?storage.PathZ {
    var prefix: usize = 0;
    for (target, 0..) |ch, i| {
        if (ch == '/' or ch == '\\' or ch == ':') prefix = i + 1;
    }
    if (prefix == target.len or prefix + 12 > 1023) return null;
    @memcpy(out[0..prefix], target[0..prefix]);
    @memcpy(out[prefix..][0..2], "DS");
    const hex = "0123456789ABCDEF";
    for (0..6) |i| out[prefix + 2 + i] = hex[(id >> @as(u5, @intCast((5 - i) * 4))) & 15];
    @memcpy(out[prefix + 8 ..][0..4], extension);
    out[prefix + 12] = 0;
    return .{ .ptr = out, .len = @intCast(prefix + 12) };
}
