//! Thin generation-exact access to the canonical wide metadata provider.
const platform = @import("platform2.zig");
pub const abi = platform.abi.shared;
pub const InfoResult = union(enum) { found: abi.FileMetadata2, missing, failure: i32 };
pub const PageResult = union(enum) { rows: []const abi.DirectoryMetadataEntry2, progress, end, restart, failure: i32 };

pub fn info(context: *const platform.Context, path: [*:0]const u8) InfoResult {
    var address: u64 = 0;
    const rc = context.lookup(1, @offsetOf(platform.abi.R4XStartR4Sys2, "file_metadata2"), &address);
    if (rc != 0) return .{ .failure = rc };
    const call: abi.R4SysFns.file_metadata2 = @ptrFromInt(address);
    var output: abi.FileMetadata2 = undefined;
    return switch (call(path, &output)) {
        1 => .{ .found = output },
        0 => .missing,
        else => |code| .{ .failure = code },
    };
}

pub fn batch(context: *const platform.Context, path: ?[*:0]const u8, cursor: *abi.DirectoryMetadataCursor2, rows: []abi.DirectoryMetadataEntry2) i32 {
    if (rows.len > abi.directory_batch_max_entries) return abi.file_metadata2_error_invalid;
    var address: u64 = 0;
    const rc = context.lookup(1, @offsetOf(platform.abi.R4XStartR4Sys2, "directory_metadata_batch2"), &address);
    if (rc != 0) return rc;
    const call: abi.R4SysFns.directory_metadata_batch2 = @ptrFromInt(address);
    return call(path, cursor, if (rows.len == 0) null else rows.ptr, @intCast(rows.len));
}

/// Caller retains context/code/path and exclusive cursor/row storage for each
/// actual synchronous return. A returned page lives until its storage changes.
/// Restart invalidates every previously assembled page; reset is explicit.
pub const Directory = struct {
    context: *const platform.Context,
    path: [*:0]const u8,
    cursor: abi.DirectoryMetadataCursor2 = .{},

    pub fn init(context: *const platform.Context, path: [*:0]const u8) Directory {
        return .{ .context = context, .path = path };
    }
    pub fn next(self: *Directory, rows: []abi.DirectoryMetadataEntry2) PageResult {
        if (rows.len == 0) return .{ .failure = abi.file_metadata2_error_invalid };
        const rc = batch(self.context, self.path, &self.cursor, rows);
        if (rc > 0 and @as(u32, @intCast(rc)) <= rows.len) return .{ .rows = rows[0..@intCast(rc)] };
        return switch (rc) {
            0 => .progress,
            -5 => .end,
            -10 => .restart,
            else => .{ .failure = rc },
        };
    }
    pub fn validate(self: *Directory) i32 {
        var empty: [0]abi.DirectoryMetadataEntry2 = .{};
        return batch(self.context, null, &self.cursor, &empty);
    }
    pub fn reset(self: *Directory) void {
        self.cursor = .{}; // No kernel resource or physical stop acknowledgement.
    }
};

pub fn identity(value: *const abi.FileMetadata2) ?*const abi.FileIdentity2 {
    return if (value.flags & abi.file_metadata2_flag_identity_valid != 0) &value.identity else null;
}
pub fn fileSize(value: *const abi.FileMetadata2) ?u64 {
    return if (value.flags & abi.file_metadata2_flag_byte_size_valid != 0) value.byte_size else null;
}
