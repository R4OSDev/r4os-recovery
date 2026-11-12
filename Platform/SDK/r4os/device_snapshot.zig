//! One actual passive capture, then constant-time pages over the frozen copy.
const std = @import("std");
const abi = @import("r4os_contract").abi;
const wire = @import("binary_cursor.zig");
pub const page_max: u32 = 64;
pub const Error = error{ InvalidState, InvalidStorage, InvalidLimit, Busy, Closed, Incomplete, InvalidCursor, NoProvider };
pub const Status = enum(u32) { initial = 0, complete = 1, capacity = 2, failed = 3, no_provider = 4, cancelled = 5, closed = 6, invalid_provider = 7 };
pub const PageStatus = enum(u32) { more = 1, complete = 2, restart = 3 };
pub const flag_complete: u32 = 1;
pub const flag_terminal: u32 = 2;
pub const flag_in_call: u32 = 4;
pub const flag_stop_requested: u32 = 8;
pub const Provider = extern struct { capture: ?abi.R4DevFns.device_inventory_capture = null };
pub const Cursor = extern struct { snapshot_generation: u64 = 0, next_index: u32 = 0, reserved0: u32 = 0 };
pub const PageInfo = extern struct { snapshot_generation: u64, total: u32, returned: u32, next_index: u32, status: u32, flags: u32 = 0, reserved0: u32 = 0 };
pub const Progress = extern struct { info: abi.DeviceInventorySnapshotInfo, status: u32, error_code: i32, flags: u32, reserved0: u32 = 0 };
pub const Page = struct { rows: wire.Span, info: PageInfo };
pub const Snapshot = extern struct {
    info: abi.DeviceInventorySnapshotInfo = .{},
    storage: wire.Span,
    provider: Provider,
    capacity: u32,
    phase: u32 = 0, // initial/in-call, complete, failed, cancelled, closed
    status: u32 = 0,
    error_code: i32 = 0,
    busy: u32 = 0,
    stop_requested: u32 = 0,

    pub fn init(storage: wire.Span, capacity: u32, provider: Provider) Error!Snapshot {
        const result = Snapshot{ .storage = storage, .capacity = capacity, .provider = provider };
        try result.validate();
        return result;
    }
    fn validInfo(self: *const Snapshot, info: abi.DeviceInventorySnapshotInfo) bool {
        return info.version == abi.device_snapshot_version and info.size == @sizeOf(abi.DeviceInventorySnapshotInfo) and info.record_size == @sizeOf(abi.DeviceInventoryRecord) and info.capacity == self.capacity and info.count == @min(info.required_count, self.capacity) and info.reserved0 == 0 and info.reserved1 == 0 and info.flags & abi.device_snapshot_flag_independent_copies != 0 and @as(u64, info.with_driver) + info.without_driver + info.unknown == info.required_count;
    }
    fn validate(self: *const Snapshot) Error!void {
        if (self.phase > 4 or self.status > 7 or self.busy > 1 or self.stop_requested > 1) return error.InvalidState;
        self.storage.validate() catch return error.InvalidStorage;
        const bytes = std.math.mul(usize, self.capacity, @sizeOf(abi.DeviceInventoryRecord)) catch return error.InvalidStorage;
        if (bytes > self.storage.length or (bytes != 0 and self.storage.address % @alignOf(abi.DeviceInventoryRecord) != 0)) return error.InvalidStorage;
        if (self.phase == 1 and (!self.validInfo(self.info) or self.info.snapshot_generation == 0 or self.info.count != self.info.required_count or self.info.flags & abi.device_snapshot_flag_complete == 0 or self.status != @intFromEnum(Status.complete))) return error.InvalidState;
    }
    pub fn progress(self: *const Snapshot) Error!Progress {
        try self.validate();
        return .{ .info = self.info, .status = self.status, .error_code = self.error_code, .flags = (if (self.phase == 1) flag_complete else @as(u32, 0)) | (if (self.phase != 0) flag_terminal else @as(u32, 0)) | (if (self.busy != 0) flag_in_call else @as(u32, 0)) | (if (self.stop_requested != 0) flag_stop_requested else @as(u32, 0)) };
    }
    fn finish(self: *Snapshot, status: Status, code: i32, phase: u32) Error!Progress {
        self.status = @intFromEnum(status);
        self.error_code = code;
        self.phase = phase;
        self.busy = 0; // Only called after actual synchronous return.
        return self.progress();
    }
    pub fn cancel(self: *Snapshot) Error!Progress {
        try self.validate();
        if (self.phase != 0) return self.progress();
        self.stop_requested = 1;
        if (self.busy != 0) return self.progress();
        self.info = .{};
        return self.finish(.cancelled, 0, 3);
    }
    pub fn close(self: *Snapshot) Error!Progress {
        try self.validate();
        if (self.busy != 0) return error.Busy;
        self.info = .{};
        return self.finish(.closed, 0, 4);
    }
    pub fn capture(self: *Snapshot, stop: bool) Error!Progress {
        try self.validate();
        if (self.busy != 0) return error.Busy;
        if (self.phase == 3 or self.phase == 4) return error.Closed;
        // An explicit refresh/retry invalidates every former view/cursor.
        self.info = .{};
        self.phase = 0;
        self.status = 0;
        self.error_code = 0;
        if (stop) self.stop_requested = 1;
        if (self.stop_requested != 0) return self.finish(.cancelled, 0, 3);
        const call = self.provider.capture orelse return self.finish(.no_provider, abi.err_no_fn, 2);
        self.busy = 1;
        defer self.busy = 0;
        var info: abi.DeviceInventorySnapshotInfo = .{};
        const rows: ?[*]abi.DeviceInventoryRecord = if (self.capacity == 0) null else @ptrFromInt(self.storage.address);
        const code = call(rows, self.capacity, &info); // Exactly one real call.
        if (self.stop_requested != 0) return self.finish(.cancelled, 0, 3);
        if (code == abi.device_snapshot_result_capacity or code == abi.device_snapshot_result_overflow) {
            if (!self.validInfo(info) or info.snapshot_generation != 0 or info.flags & abi.device_snapshot_flag_complete != 0) return self.finish(.invalid_provider, -201, 2);
            self.info = info; // Diagnostic required_count; never a usable view.
            return self.finish(if (code == abi.device_snapshot_result_capacity) .capacity else .failed, code, 2);
        }
        if (code != 0) return self.finish(if (code == abi.err_no_fn or code == abi.err_no_group) .no_provider else .failed, code, 2);
        if (!self.validInfo(info) or info.snapshot_generation == 0 or info.count != info.required_count or info.flags & abi.device_snapshot_flag_complete == 0) return self.finish(.invalid_provider, -202, 2);
        // Validate initialized native rows only once, before publication.
        // Page/view/progress stay O(1), with no callback or repeated scan.
        var counts = [_]u32{0} ** 3;
        var sources: u32 = 0;
        if (info.count != 0) {
            const view_rows: [*]const abi.DeviceInventoryRecord = @ptrFromInt(self.storage.address);
            for (view_rows[0..info.count]) |record| {
                if (record.binding > 2 or record.reserved0 != 0) return self.finish(.invalid_provider, -203, 2);
                counts[record.binding] += 1;
                if (record.bus < 32) sources |= @as(u32, 1) << @as(u5, @intCast(record.bus));
            }
        }
        if (counts[0] != info.with_driver or counts[1] != info.without_driver or counts[2] != info.unknown or sources != info.source_mask) return self.finish(.invalid_provider, -204, 2);
        self.info = info;
        return self.finish(.complete, 0, 1);
    }
    pub fn view(self: *const Snapshot) Error!wire.Span {
        try self.validate();
        if (self.phase != 1) return error.Incomplete;
        return .{ .address = self.storage.address, .length = @as(usize, self.info.count) * @sizeOf(abi.DeviceInventoryRecord) };
    }
    pub fn records(self: *const Snapshot) Error![]const abi.DeviceInventoryRecord {
        const span = try self.view();
        if (self.info.count == 0) return &.{};
        return @as([*]const abi.DeviceInventoryRecord, @ptrFromInt(span.address))[0..self.info.count];
    }
    pub fn beginPages(self: *const Snapshot) Error!Cursor {
        _ = try self.view();
        return .{ .snapshot_generation = self.info.snapshot_generation };
    }
    pub fn page(self: *const Snapshot, cursor: *Cursor, limit: u32) Error!Page {
        _ = try self.view();
        if (limit == 0 or limit > page_max) return error.InvalidLimit;
        if (cursor.reserved0 != 0) return error.InvalidCursor;
        if (cursor.snapshot_generation != self.info.snapshot_generation) return .{ .rows = .{ .address = 0, .length = 0 }, .info = .{ .snapshot_generation = self.info.snapshot_generation, .total = self.info.count, .returned = 0, .next_index = 0, .status = @intFromEnum(PageStatus.restart) } };
        if (cursor.next_index > self.info.count) return error.InvalidCursor;
        const count = @min(limit, self.info.count - cursor.next_index);
        const start = cursor.next_index;
        cursor.next_index += count;
        const ended = cursor.next_index == self.info.count;
        return .{ .rows = .{ .address = if (count == 0) 0 else self.storage.address + @as(usize, start) * @sizeOf(abi.DeviceInventoryRecord), .length = @as(usize, count) * @sizeOf(abi.DeviceInventoryRecord) }, .info = .{ .snapshot_generation = self.info.snapshot_generation, .total = self.info.count, .returned = count, .next_index = cursor.next_index, .status = @intFromEnum(if (ended) PageStatus.complete else PageStatus.more), .flags = @intFromBool(ended) } };
    }
};
