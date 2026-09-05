// R4ZIP.R4P wire contract and typed facade; no ZIP parser is embedded here.
const std = @import("std");
const abi = @import("r4os_contract").abi;
const r4dev = @import("r4dev.zig");
pub const role = "format.zip";
pub const contract_version: u32 = 1;
pub const max_entries: u32 = 4096;
pub const max_path: u32 = 255;
pub const work_bytes: usize = 16384;
pub const work_alignment = 16;
pub const max_step_bytes: u32 = 4 * 1024 * 1024;
pub const min_step_bytes: u32 = 258; // One complete maximum Deflate match.
pub const op_inspect: u32 = 1;
pub const op_begin: u32 = 2;
pub const op_step: u32 = 3;

pub const Error = error{ Unavailable, BadRequest, InvalidArchive, Unsupported, Bounds, Checksum, OutputTooSmall, DuplicatePath, UnsafePath, Limit, Inflate, Stale };
pub fn status(err: Error) i32 {
    return switch (err) {
        error.Unavailable => -21000,
        error.BadRequest => -21001,
        error.InvalidArchive => -21002,
        error.Unsupported => -21003,
        error.Bounds => -21004,
        error.Checksum => -21005,
        error.OutputTooSmall => -21006,
        error.DuplicatePath => -21007,
        error.UnsafePath => -21008,
        error.Limit => -21009,
        error.Inflate => -21010,
        error.Stale => -21011,
    };
}
pub fn check(value: i32) Error!void {
    switch (value) {
        0 => {},
        -21001 => return error.BadRequest,
        -21002 => return error.InvalidArchive,
        -21003 => return error.Unsupported,
        -21004 => return error.Bounds,
        -21005 => return error.Checksum,
        -21006 => return error.OutputTooSmall,
        -21007 => return error.DuplicatePath,
        -21008 => return error.UnsafePath,
        -21009 => return error.Limit,
        -21010 => return error.Inflate,
        -21011 => return error.Stale,
        else => return error.Unavailable,
    }
}
pub const Info = extern struct {
    version: u32 = contract_version,
    size: u32 = @sizeOf(Info),
    entries: u32 = 0,
    files: u32 = 0,
    total_bytes: u64 = 0,
    central_offset: u64 = 0,
    central_bytes: u64 = 0,
};
pub const Entry = extern struct {
    central_offset: u64 = 0,
    local_offset: u64 = 0,
    data_offset: u64 = 0,
    end_offset: u64 = 0,
    compressed_bytes: u64 = 0,
    bytes: u64 = 0,
    name_offset: u64 = 0,
    name_bytes: u32 = 0,
    crc32: u32 = 0,
    method: u16 = 0,
    flags: u16 = 0,
    directory: u32 = 0,
    pub fn name(self: Entry, archive: []const u8) Error![]const u8 {
        if (self.name_offset > archive.len or self.name_bytes > archive.len - self.name_offset) return error.Bounds;
        return archive[@intCast(self.name_offset)..][0..self.name_bytes];
    }
};
pub const Progress = extern struct {
    written: u64 = 0,
    done: u32 = 0,
    reserved: u32 = 0,
};
pub const Request = extern struct {
    version: u32 = contract_version,
    size: u32 = @sizeOf(Request),
    archive: ?[*]const u8 = null,
    archive_bytes: u64 = 0,
    entries: ?[*]Entry = null,
    entry_capacity: u32 = 0,
    step_bytes: u32 = max_step_bytes,
    entry: ?*const Entry = null,
    work: ?[*]align(work_alignment) u8 = null,
    work_len: u32 = 0,
    reserved: u32 = 0,
    output: ?[*]u8 = null,
    output_bytes: u64 = 0,
};
pub const Work = struct { data: [work_bytes]u8 align(work_alignment) = undefined };
pub const Context = struct {
    dev: *const r4dev.Context,
    fn invoke(self: Context, op: u32, request: *const Request, out: anytype) Error!void {
        var input = abi.ProtocolBuffer{ .data = @ptrCast(@constCast(request)), .len = @sizeOf(Request), .capacity = @sizeOf(Request) };
        var output = abi.ProtocolBuffer{ .data = @ptrCast(out), .len = 0, .capacity = @sizeOf(@TypeOf(out.*)) };
        try check(self.dev.protocolDispatch(role, op, &input, &output));
        if (output.len != @sizeOf(@TypeOf(out.*))) return error.BadRequest;
    }
    // Entries are sorted by portable, case-insensitive path. No filesystem is
    // accessed. Caller retains immutable archive and output storage through
    // inspection/preparation; failed outputs must be discarded.
    pub fn inspect(self: Context, archive: []const u8, entries: []Entry) Error!Info {
        if (entries.len > max_entries) return error.Limit;
        var out = Info{};
        try self.invoke(op_inspect, &.{ .archive = archive.ptr, .archive_bytes = archive.len, .entries = entries.ptr, .entry_capacity = @intCast(entries.len) }, &out);
        return out;
    }
    pub fn begin(self: Context, archive: []const u8, entry: *const Entry, output: []u8, work: *Work) Error!Progress {
        var out = Progress{};
        try self.invoke(op_begin, &.{ .archive = archive.ptr, .archive_bytes = archive.len, .entry = entry, .output = output.ptr, .output_bytes = output.len, .work = &work.data, .work_len = work_bytes }, &out);
        return out;
    }
    // Between these calls the application can paint progress, process input
    // and yield. No protocol callback or global decoder state remains active.
    pub fn step(self: Context, work: *Work, budget: u32) Error!Progress {
        var out = Progress{};
        try self.invoke(op_step, &.{ .work = &work.data, .work_len = work_bytes, .step_bytes = budget }, &out);
        return out;
    }
};

test "ZIP protocol status values cannot collide with generic role failure" {
    inline for (std.meta.fields(Error)) |field| {
        const err = @field(Error, field.name);
        try std.testing.expectError(err, check(status(err)));
    }
    try std.testing.expectError(error.Unavailable, check(-5));
}
