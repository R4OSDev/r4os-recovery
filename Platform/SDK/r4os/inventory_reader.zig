//! Staged complete inventory views over existing canonical nonblocking owners.
const std = @import("std");
const abi = @import("r4os_contract").abi;
const budget = @import("time_budget.zig");
const wire = @import("binary_cursor.zig");
pub const Mode = enum(u32) { full = 0, lifecycle = 1 };
pub const Status = enum(u32) { initial = 0, more = 1, complete = 2, would_block = 3, restart = 4, failed = 5, no_provider = 6, capacity = 7, cancelled = 8, timed_out = 9, clock_failed = 10, invalid_provider = 11 };
pub const Disposition = enum(u32) { unknown = 0, found = 1, missing = 2 };
pub const flag_complete: u32 = 1;
pub const flag_terminal: u32 = 2;
pub const flag_in_call: u32 = 4;
pub const flag_total_known: u32 = 8;
pub const Clock = *const fn (?*anyopaque, *budget.ClockSample) callconv(.c) i32;
pub const Error = error{ InvalidState, InvalidStorage, InvalidLimit, InvalidMode, Busy, Incomplete, WrongMode } || budget.Error;
pub const Provider = extern struct {
    full_begin: ?abi.R4SysFns.program_inventory_begin = null,
    full_page: ?abi.R4SysFns.program_inventory_programs = null,
    lifecycle_begin: ?abi.R4SysFns.program_lifecycle_begin = null,
    lifecycle_page: ?abi.R4SysFns.program_lifecycle_programs = null,
};
pub const Progress = extern struct { snapshot_generation: u64, staged_count: u32, total: u32, status: u32, error_code: i32, flags: u32, restarts: u32 };
pub const Match = extern struct { snapshot_generation: u64 = 0, index: u32 = std.math.maxInt(u32), disposition: u32 = 0, status: u32 = 0, error_code: i32 = 0 };
pub const Reader = extern struct {
    deadline: budget.DeadlineBudget,
    cursor: abi.ProgramInventoryCursor = .{},
    summary: abi.ProgramInventorySummary = .{},
    provider: Provider,
    storage: wire.Span,
    last_generation: u64 = 0,
    mode: u32,
    phase: u32 = 0, // begin, pages, complete, needs-restart, terminal failure
    status: u32 = 0,
    error_code: i32 = 0,
    capacity: u32,
    page_limit: u32,
    count: u32 = 0,
    total: u32 = 0,
    total_known: u32 = 0,
    busy: u32 = 0,
    stop_requested: u32 = 0,
    poll_used: u32 = 0,
    restarts: u32 = 0,

    pub fn init(mode: Mode, storage: wire.Span, capacity: u32, page_limit: u32, provider: Provider, sample: budget.ClockSample, timeout: abi.R4Timeout) Error!Reader {
        return initAbsolute(mode, storage, capacity, page_limit, provider, try budget.DeadlineBudget.init(sample, timeout));
    }
    pub fn initAbsolute(mode: Mode, storage: wire.Span, capacity: u32, page_limit: u32, provider: Provider, deadline: budget.DeadlineBudget) Error!Reader {
        var check = deadline;
        _ = try check.remaining(.{ .identity = deadline.identity, .instant_ns = deadline.last_ns });
        const value = Reader{ .deadline = deadline, .provider = provider, .storage = storage, .mode = @intFromEnum(mode), .capacity = capacity, .page_limit = page_limit };
        try value.validate();
        return value;
    }
    fn recordSize(self: *const Reader) usize {
        return if (self.mode == 0) @sizeOf(abi.ProgramInstanceSnapshot) else @sizeOf(abi.ProgramLifecycleSnapshot);
    }
    fn validate(self: *const Reader) Error!void {
        if (self.mode > 1 or self.phase > 4 or self.status > 11 or self.count > self.capacity or self.busy > 1 or self.stop_requested > 1 or self.poll_used > 1 or self.total_known > 1) return error.InvalidState;
        if (self.page_limit == 0 or self.page_limit > abi.program_inventory_page_max) return error.InvalidLimit;
        self.storage.validate() catch return error.InvalidStorage;
        const required = std.math.mul(usize, self.capacity, self.recordSize()) catch return error.InvalidStorage;
        if (required > self.storage.length or (required != 0 and self.storage.address % @alignOf(abi.ProgramInstanceSnapshot) != 0)) return error.InvalidStorage;
        if (self.phase == 2 and (self.status != @intFromEnum(Status.complete) or self.total_known == 0 or self.total != self.count)) return error.InvalidState;
    }
    pub fn progress(self: *const Reader) Error!Progress {
        try self.validate();
        return .{ .snapshot_generation = self.cursor.snapshot_generation, .staged_count = self.count, .total = self.total, .status = self.status, .error_code = self.error_code, .flags = (if (self.phase == 2) flag_complete | flag_terminal else @as(u32, 0)) | (if (self.phase == 4) flag_terminal else @as(u32, 0)) | (if (self.busy != 0) flag_in_call else @as(u32, 0)) | (if (self.total_known != 0) flag_total_known else @as(u32, 0)), .restarts = self.restarts };
    }
    fn finish(self: *Reader, status: Status, code: i32, terminal: bool) Error!Progress {
        self.status = @intFromEnum(status);
        self.error_code = code;
        self.busy = 0;
        if (terminal) {
            self.phase = 4;
            self.count = 0; // never publish a partial or failed empty success
        }
        return self.progress();
    }
    pub fn cancel(self: *Reader) Error!Progress {
        try self.validate();
        if (self.phase == 2 or self.phase == 4) return self.progress();
        self.stop_requested = 1;
        // A reentrant request is not release of an outstanding owner call.
        if (self.busy != 0) return self.progress();
        return self.finish(.cancelled, 0, true);
    }
    pub fn restart(self: *Reader) Error!Progress {
        try self.validate();
        if (self.busy != 0) return error.Busy;
        if (self.phase != 3 and self.phase != 2) return error.InvalidState;
        self.cursor = .{};
        self.summary = .{};
        self.last_generation = 0;
        self.count = 0;
        self.total = 0;
        self.total_known = 0;
        self.phase = 0;
        self.status = 0;
        self.error_code = 0;
        self.restarts +|= 1;
        // The original deadline/poll admission is deliberately not reset.
        return self.progress();
    }
    fn clockCheck(self: *Reader, clock: Clock, context: ?*anyopaque) Error!?Progress {
        var now: budget.ClockSample = .{};
        const code = clock(context, &now);
        if (code != 0) return try self.finish(.clock_failed, code, true);
        const remaining = self.deadline.remaining(now) catch |err| return try self.finish(.clock_failed, switch (err) {
            error.ClockUnavailable => -101,
            error.ClockChanged => -102,
            error.ClockRegressed => -103,
            else => -104,
        }, true);
        if (self.stop_requested != 0) return try self.finish(.cancelled, 0, true);
        if (self.deadline.kind == 1 and remaining.kind == 0) return try self.finish(.timed_out, 0, true);
        return null;
    }
    fn providerError(self: *Reader, code: i32) Error!Progress {
        if (code == abi.program_handle_error_would_block) return self.finish(.would_block, code, self.deadline.kind == 0);
        return self.finish(if (code == abi.err_no_fn or code == abi.err_no_group) .no_provider else .failed, code, true);
    }
    fn validCursor(cursor: abi.ProgramInventoryCursor, mode: u32) bool {
        return cursor.version == abi.program_inventory_version and cursor.size == @sizeOf(abi.ProgramInventoryCursor) and cursor.snapshot_generation != 0 and cursor.program_epoch != 0 and cursor.reserved0 == 0 and cursor.flags & abi.program_inventory_cursor_flag_initialized != 0 and (cursor.flags & abi.program_inventory_cursor_flag_lifecycle != 0) == (mode == 1);
    }
    fn finishAttempt(self: *Reader) Error!Progress {
        if (self.deadline.kind == 0 and self.phase != 2) return self.finish(.would_block, 0, true);
        self.busy = 0; // Real owner and clock callbacks have both returned.
        return self.progress();
    }
    pub fn step(self: *Reader, stop: bool, clock: Clock, clock_context: ?*anyopaque) Error!Progress {
        try self.validate();
        if (self.busy != 0) return error.Busy;
        if (self.phase == 2 or self.phase == 4) return self.progress();
        if (stop) self.stop_requested = 1;
        if (self.stop_requested != 0) return self.finish(.cancelled, 0, true);
        if (self.phase == 3) return self.progress();
        if (self.deadline.kind == 0 and self.poll_used != 0) return self.finish(.would_block, 0, true);
        self.busy = 1;
        defer self.busy = 0;
        if (try self.clockCheck(clock, clock_context)) |ended| return ended;
        if (self.deadline.kind == 0) self.poll_used = 1;
        if (self.phase == 0) {
            var cursor: abi.ProgramInventoryCursor = .{ .restarts = self.restarts };
            var summary: abi.ProgramInventorySummary = .{};
            const code = if (self.mode == 0) (self.provider.full_begin orelse return self.finish(.no_provider, abi.err_no_fn, true))(&cursor, &summary) else (self.provider.lifecycle_begin orelse return self.finish(.no_provider, abi.err_no_fn, true))(&cursor);
            if (try self.clockCheck(clock, clock_context)) |ended| return ended;
            if (code != 0) return self.providerError(code);
            if (!validCursor(cursor, self.mode) or cursor.program_after_generation != 0) return self.finish(.invalid_provider, -201, true);
            if (self.mode == 0 and (summary.version != abi.program_inventory_version or summary.size != @sizeOf(abi.ProgramInventorySummary) or summary.snapshot_generation != cursor.snapshot_generation or summary.program_epoch != cursor.program_epoch or summary.task_epoch != cursor.task_epoch or summary.thread_epoch != cursor.thread_epoch or summary.flags & abi.program_inventory_summary_flag_stable == 0)) return self.finish(.invalid_provider, -202, true);
            self.cursor = cursor;
            if (self.mode == 0) {
                self.summary = summary;
                self.total = summary.program_total;
                self.total_known = 1;
                if (self.total > self.capacity) return self.finish(.capacity, 0, true);
            }
            self.phase = 1;
            self.status = @intFromEnum(Status.more);
            self.error_code = 0;
            return self.finishAttempt();
        }
        var cursor = self.cursor;
        var page: abi.ProgramInventoryPageInfo = .{};
        var scratch: extern union {
            full: [abi.program_inventory_page_max]abi.ProgramInstanceSnapshot,
            life: [abi.program_inventory_page_max]abi.ProgramLifecycleSnapshot,
        } = undefined;
        // Only the offered rows and selected record shape need initialization;
        // lightweight membership never clears a second full diagnostic page.
        @memset(std.mem.asBytes(&scratch)[0 .. @as(usize, self.page_limit) * self.recordSize()], 0);
        const code = if (self.mode == 0) (self.provider.full_page orelse return self.finish(.no_provider, abi.err_no_fn, true))(&cursor, &scratch.full, self.page_limit, &page) else (self.provider.lifecycle_page orelse return self.finish(.no_provider, abi.err_no_fn, true))(&cursor, &scratch.life, self.page_limit, &page);
        if (try self.clockCheck(clock, clock_context)) |ended| return ended;
        if (code != 0) return self.providerError(code); // saved cursor/rows unchanged on WouldBlock
        const checked = if (self.mode == 0)
            checkPage(abi.ProgramInstanceSnapshot, self.cursor, cursor, page, scratch.full[0..self.page_limit], self.count, self.last_generation, if (self.total_known != 0) self.total else null)
        else
            checkPage(abi.ProgramLifecycleSnapshot, self.cursor, cursor, page, scratch.life[0..self.page_limit], self.count, self.last_generation, if (self.total_known != 0) self.total else null);
        const valid = switch (checked) {
            .invalid => |code_value| return self.finish(.invalid_provider, code_value, true),
            .restart => {
                self.count = 0;
                self.last_generation = 0;
                self.total = 0;
                self.total_known = 0;
                self.phase = 3;
                self.status = @intFromEnum(Status.restart);
                self.error_code = 0;
                return self.finishAttempt();
            },
            .valid => |value| value,
        };
        const sum = valid.count;
        const last = valid.last;
        self.total = page.total;
        self.total_known = 1;
        if (sum > self.capacity or self.total > self.capacity) return self.finish(.capacity, 0, true);
        if (page.returned != 0) {
            const target: [*]u8 = @ptrFromInt(self.storage.address);
            const start = @as(usize, self.count) * self.recordSize();
            const length = @as(usize, page.returned) * self.recordSize();
            const source: [*]const u8 = @ptrCast(&scratch);
            @memcpy(target[start..][0..length], source[0..length]);
        }
        self.cursor = cursor;
        self.count = sum;
        self.last_generation = last;
        self.status = if (page.status == abi.program_inventory_status_complete) @intFromEnum(Status.complete) else @intFromEnum(Status.more);
        self.phase = if (page.status == abi.program_inventory_status_complete) 2 else 1;
        self.error_code = 0;
        return self.finishAttempt();
    }
    pub fn view(self: *const Reader) Error!wire.Span {
        try self.validate();
        if (self.phase != 2) return error.Incomplete;
        return .{ .address = self.storage.address, .length = @as(usize, self.count) * self.recordSize() };
    }
    pub fn fullView(self: *const Reader) Error![]const abi.ProgramInstanceSnapshot {
        if (self.mode != 0) return error.WrongMode;
        const span = try self.view();
        if (self.count == 0) return &.{};
        return @as([*]const abi.ProgramInstanceSnapshot, @ptrFromInt(span.address))[0..self.count];
    }
    pub fn lifecycleView(self: *const Reader) Error![]const abi.ProgramLifecycleSnapshot {
        if (self.mode != 1) return error.WrongMode;
        const span = try self.view();
        if (self.count == 0) return &.{};
        return @as([*]const abi.ProgramLifecycleSnapshot, @ptrFromInt(span.address))[0..self.count];
    }
    pub fn findExact(self: *const Reader, handle: abi.ProgramProcessHandle) Error!Match {
        const progress_value = try self.progress();
        var match = Match{ .snapshot_generation = progress_value.snapshot_generation, .status = progress_value.status, .error_code = progress_value.error_code };
        if (handle.instance_id == 0 or handle.generation == 0 or handle.reserved != 0) {
            match.error_code = -212;
            return match;
        }
        if (self.phase != 2) return match;
        for (0..self.count) |index| {
            const found = if (self.mode == 0) @as([*]const abi.ProgramInstanceSnapshot, @ptrFromInt(self.storage.address))[index].handle else @as([*]const abi.ProgramLifecycleSnapshot, @ptrFromInt(self.storage.address))[index].handle;
            if (found.instance_id == handle.instance_id and found.generation == handle.generation) {
                match.index = @intCast(index);
                match.disposition = @intFromEnum(Disposition.found);
                return match;
            }
        }
        match.disposition = @intFromEnum(Disposition.missing);
        return match;
    }
};

const CheckedPage = union(enum) { valid: struct { count: u32, last: u64 }, restart, invalid: i32 };

// Both complete views and positive-only streaming membership use precisely
// the same cursor, row, ordering and total validation. Only a complete page
// grants absence; a validated more page can establish a positive owner.
fn checkPage(comptime T: type, before: abi.ProgramInventoryCursor, after: abi.ProgramInventoryCursor, page: abi.ProgramInventoryPageInfo, rows: []const T, seen: u32, last_generation: u64, total: ?u32) CheckedPage {
    const full = T == abi.ProgramInstanceSnapshot;
    if (page.version != abi.program_inventory_version or page.size != @sizeOf(abi.ProgramInventoryPageInfo) or page.reserved0 != 0 or page.snapshot_generation != before.snapshot_generation or page.kind != (if (full) @as(u32, abi.program_inventory_kind_program) else abi.program_inventory_kind_lifecycle) or page.returned > rows.len or page.has_more > 1) return .{ .invalid = -203 };
    if (page.status == abi.program_inventory_status_restart) {
        if (page.returned != 0 or !std.meta.eql(after, before)) return .{ .invalid = -204 };
        return .restart;
    }
    var expected = before;
    expected.program_after_generation = after.program_after_generation;
    if (!std.meta.eql(after, expected) or page.next_generation != after.program_after_generation or (total != null and page.total != total.?)) return .{ .invalid = -205 };
    const sum = std.math.add(u32, seen, page.returned) catch return .{ .invalid = -206 };
    if (sum > page.total) return .{ .invalid = -206 };
    if (page.status == abi.program_inventory_status_complete) {
        if (page.has_more != 0 or sum != page.total) return .{ .invalid = -207 };
    } else if (page.status == abi.program_inventory_status_more) {
        if (page.has_more != 1 or page.returned == 0 or sum >= page.total) return .{ .invalid = -208 };
    } else return .{ .invalid = -209 };
    var last = last_generation;
    for (rows[0..page.returned]) |row| {
        if (row.version != abi.program_inventory_version or row.size != @sizeOf(T) or row.handle.instance_id == 0 or row.handle.reserved != 0 or row.handle.generation <= last or (full and row.info.id != row.handle.instance_id)) return .{ .invalid = -210 };
        last = row.handle.generation;
    }
    if (last != page.next_generation) return .{ .invalid = -211 };
    return .{ .valid = .{ .count = sum, .last = last } };
}

/// Nonblocking lifecycle pages for owners that can stop after every requested
/// live identity was observed. There is no allocation, global staging, hidden
/// retry or diagnostic fallback. The caller owns its bounded traversal and
/// output storage; discard rows on null. Missing is authorized only by a
/// returned complete page. Failed calls never advance the saved cursor.
pub const LifecyclePages = struct {
    provider: Provider,
    cursor: abi.ProgramInventoryCursor = .{},
    count: u32 = 0,
    total: ?u32 = null,
    last_generation: u64 = 0,
    status: Status = .initial,
    begun: bool = false,
    busy: bool = false,

    pub fn begin(self: *LifecyclePages) bool {
        if (self.busy) return false;
        self.busy = true;
        defer self.busy = false;
        self.begun = false;
        var cursor: abi.ProgramInventoryCursor = .{};
        const begin_fn = self.provider.lifecycle_begin orelse {
            self.status = .no_provider;
            return false;
        };
        const rc = begin_fn(&cursor);
        if (rc != 0) {
            self.status = if (rc == abi.program_handle_error_would_block) .would_block else .failed;
            return false;
        }
        if (!Reader.validCursor(cursor, 1) or cursor.program_after_generation != 0) {
            self.status = .invalid_provider;
            return false;
        }
        self.* = .{ .provider = self.provider, .cursor = cursor, .begun = true, .status = .more };
        return true;
    }
    pub fn next(self: *LifecyclePages, rows: []abi.ProgramLifecycleSnapshot) ?abi.ProgramInventoryPageInfo {
        if (self.busy or !self.begun or rows.len == 0 or rows.len > abi.program_inventory_page_max or (self.status != .more and self.status != .would_block)) return null;
        self.busy = true;
        defer self.busy = false;
        const page_fn = self.provider.lifecycle_page orelse {
            self.status = .no_provider;
            return null;
        };
        var cursor = self.cursor;
        var page: abi.ProgramInventoryPageInfo = .{};
        @memset(std.mem.sliceAsBytes(rows), 0);
        const rc = page_fn(&cursor, rows.ptr, @intCast(rows.len), &page);
        if (rc != 0) {
            self.status = if (rc == abi.program_handle_error_would_block) .would_block else .failed;
            return null;
        }
        switch (checkPage(abi.ProgramLifecycleSnapshot, self.cursor, cursor, page, rows, self.count, self.last_generation, self.total)) {
            .invalid => {
                self.status = .invalid_provider;
                return null;
            },
            .restart => {
                self.status = .restart;
                return null;
            },
            .valid => |checked| {
                self.cursor = cursor;
                self.count = checked.count;
                self.last_generation = checked.last;
                self.total = page.total;
                self.status = if (page.status == abi.program_inventory_status_complete) .complete else .more;
                self.begun = self.status != .complete;
                return page;
            },
        }
    }
};

const Probe = struct {
    const Fault = enum { none, begin_busy, page_busy, restart, epoch, total, empty_more, oom, stop_inside, expire_inside, clock_inside };
    var fault: Fault = .none;
    var instant: u64 = 100;
    var clock_generation: u32 = 1;
    var full_begins: u32 = 0;
    var lifecycle_begins: u32 = 0;
    var pages: u32 = 0;
    var empty: bool = false;
    var reader: ?*Reader = null;
    var observed_active_loan: bool = false;
    const initial: budget.ClockSample = .{ .identity = .{ .source = 1, .generation = 1 }, .instant_ns = 100 };
    fn reset() void {
        fault = .none;
        instant = 100;
        clock_generation = 1;
        full_begins = 0;
        lifecycle_begins = 0;
        pages = 0;
        empty = false;
        reader = null;
        observed_active_loan = false;
    }
    fn clock(_: ?*anyopaque, out: *budget.ClockSample) callconv(.c) i32 {
        out.* = initial;
        out.identity.generation = clock_generation;
        out.instant_ns = instant;
        return 0;
    }
    fn begin(cursor: *abi.ProgramInventoryCursor, life: bool) i32 {
        if (fault == .begin_busy) {
            cursor.program_after_generation = 999;
            return abi.program_handle_error_would_block;
        }
        cursor.* = .{ .snapshot_generation = if (life) 9 else 101, .program_epoch = 9, .task_epoch = if (life) 0 else 8, .thread_epoch = if (life) 0 else 7, .flags = abi.program_inventory_cursor_flag_initialized | (if (life) abi.program_inventory_cursor_flag_lifecycle else @as(u32, 0)) };
        return 0;
    }
    fn fullBegin(cursor: *abi.ProgramInventoryCursor, summary: *abi.ProgramInventorySummary) callconv(.c) i32 {
        full_begins += 1;
        const rc = begin(cursor, false);
        if (rc == 0) summary.* = .{ .snapshot_generation = cursor.snapshot_generation, .program_epoch = 9, .task_epoch = 8, .thread_epoch = 7, .program_total = if (empty) 0 else 2, .flags = abi.program_inventory_summary_flag_stable };
        return rc;
    }
    fn lifeBegin(cursor: *abi.ProgramInventoryCursor) callconv(.c) i32 {
        lifecycle_begins += 1;
        return begin(cursor, true);
    }
    fn acquire(cursor: *abi.ProgramInventoryCursor, capacity: u32, page: *abi.ProgramInventoryPageInfo, kind: u32) i32 {
        pages += 1;
        page.* = .{ .snapshot_generation = cursor.snapshot_generation, .kind = kind };
        if (fault == .page_busy) {
            cursor.program_after_generation = 999;
            return abi.program_handle_error_would_block;
        }
        if (fault == .oom) return abi.program_handle_error_no_memory;
        if (fault == .restart) {
            page.status = abi.program_inventory_status_restart;
            return 0;
        }
        const n: u32 = if (empty) 0 else if (cursor.program_after_generation == 0) @min(capacity, 2) else if (cursor.program_after_generation == 11) 1 else 0;
        cursor.program_after_generation = if (empty) 0 else if (n == 2 or cursor.program_after_generation != 0) 12 else 11;
        page.next_generation = cursor.program_after_generation;
        page.total = if (empty) 0 else 2;
        page.returned = n;
        page.has_more = @intFromBool(n != 0 and cursor.program_after_generation == 11);
        page.status = if (page.has_more != 0) abi.program_inventory_status_more else abi.program_inventory_status_complete;
        switch (fault) {
            .epoch => cursor.program_epoch += 1,
            .total => page.total += 1,
            .empty_more => {
                page.returned = 0;
                page.status = abi.program_inventory_status_more;
                page.has_more = 1;
            },
            .stop_inside => if (reader) |r| {
                const stopped = r.cancel() catch unreachable;
                observed_active_loan = stopped.flags & flag_in_call != 0 and stopped.flags & flag_terminal == 0;
            },
            .expire_inside => instant += 20,
            .clock_inside => clock_generation += 1,
            else => {},
        }
        return 0;
    }
    fn lifePage(cursor: *abi.ProgramInventoryCursor, rows: [*]abi.ProgramLifecycleSnapshot, capacity: u32, page: *abi.ProgramInventoryPageInfo) callconv(.c) i32 {
        const before = cursor.program_after_generation;
        const rc = acquire(cursor, capacity, page, abi.program_inventory_kind_lifecycle);
        if (rc == 0 and page.status != abi.program_inventory_status_restart) for (0..page.returned) |i| {
            const generation: u64 = if (before == 0) 11 + i else 12;
            rows[i] = .{ .handle = .{ .instance_id = @intCast(generation - 4), .generation = generation } };
        };
        return rc;
    }
    fn fullPage(cursor: *abi.ProgramInventoryCursor, rows: [*]abi.ProgramInstanceSnapshot, capacity: u32, page: *abi.ProgramInventoryPageInfo) callconv(.c) i32 {
        const before = cursor.program_after_generation;
        const rc = acquire(cursor, capacity, page, abi.program_inventory_kind_program);
        if (rc == 0 and page.status != abi.program_inventory_status_restart) for (0..page.returned) |i| {
            const generation: u64 = if (before == 0) 11 + i else 12;
            const id: u32 = @intCast(generation - 4);
            rows[i] = .{ .handle = .{ .instance_id = id, .generation = generation }, .info = .{ .id = id } };
        };
        return rc;
    }
    const provider: Provider = .{ .full_begin = fullBegin, .full_page = fullPage, .lifecycle_begin = lifeBegin, .lifecycle_page = lifePage };
    fn create(mode: Mode, storage: []u8, capacity: u32, timeout: abi.R4Timeout) !Reader {
        return Reader.init(mode, .{ .address = @intFromPtr(storage.ptr), .length = storage.len }, capacity, 1, provider, initial, timeout);
    }
};

test "inventory owner streaming lifecycle positive pages preserve rollback and explicit restart" {
    const t = std.testing;
    Probe.reset();
    var pages = LifecyclePages{ .provider = Probe.provider };
    var rows: [1]abi.ProgramLifecycleSnapshot = undefined;
    try t.expect(pages.begin());
    const first = pages.next(&rows) orelse return error.TestUnexpectedResult;
    try t.expectEqual(abi.program_inventory_status_more, first.status);
    try t.expectEqual(@as(u32, 7), rows[0].handle.instance_id);
    try t.expectEqual(@as(u64, 11), rows[0].handle.generation);
    const before = pages.cursor;
    Probe.fault = .page_busy; // provider deliberately writes cursor999 before WouldBlock
    try t.expect(pages.next(&rows) == null);
    try t.expectEqual(Status.would_block, pages.status);
    try t.expect(std.meta.eql(before, pages.cursor));
    try t.expectEqual(@as(u32, 1), pages.count);
    Probe.fault = .none;
    const last = pages.next(&rows) orelse return error.TestUnexpectedResult;
    try t.expectEqual(abi.program_inventory_status_complete, last.status);
    try t.expectEqual(@as(u64, 12), rows[0].handle.generation);
    try t.expectEqual(@as(u32, 2), pages.count);
    try t.expectEqual(@as(u32, 0), Probe.full_begins);
    Probe.fault = .begin_busy;
    try t.expect(!pages.begin());
    try t.expect(pages.next(&rows) == null);
    Probe.fault = .none;
    try t.expect(pages.begin());
    Probe.fault = .restart;
    try t.expect(pages.next(&rows) == null);
    try t.expectEqual(Status.restart, pages.status);
    const calls = Probe.pages;
    try t.expect(pages.next(&rows) == null);
    try t.expectEqual(calls, Probe.pages);
}

test "inventory owner whole staged view only exact generation and lifecycle does not trigger diagnostic summary" {
    Probe.reset();
    var storage: [2]abi.ProgramLifecycleSnapshot = undefined;
    var r = try Probe.create(.lifecycle, std.mem.asBytes(&storage), 2, .{ .kind = 2 });
    const target: abi.ProgramProcessHandle = .{ .instance_id = 7, .generation = 11 };
    try std.testing.expectEqual(@intFromEnum(Disposition.unknown), (try r.findExact(target)).disposition);
    _ = try r.step(false, Probe.clock, null);
    try std.testing.expectEqual(@as(u32, 0), Probe.full_begins);
    try std.testing.expectEqual(@as(u32, 1), Probe.lifecycle_begins);
    _ = try r.step(false, Probe.clock, null);
    try std.testing.expectEqual(@as(u32, 1), r.count);
    try std.testing.expectError(error.Incomplete, r.lifecycleView());
    try std.testing.expectEqual(@intFromEnum(Disposition.unknown), (try r.findExact(target)).disposition);
    const done = try r.step(false, Probe.clock, null);
    try std.testing.expect(done.flags & flag_complete != 0);
    try std.testing.expect(done.flags & flag_in_call == 0);
    try std.testing.expectEqual(@as(usize, 2), (try r.lifecycleView()).len);
    try std.testing.expectEqual(@intFromEnum(Disposition.found), (try r.findExact(target)).disposition);
    try std.testing.expectEqual(@intFromEnum(Disposition.missing), (try r.findExact(.{ .instance_id = 7, .generation = 12 })).disposition);
    try std.testing.expectEqual(@intFromEnum(Disposition.unknown), (try r.findExact(.{ .instance_id = 7 })).disposition);
    const calls = Probe.pages;
    _ = try r.step(false, Probe.clock, null);
    try std.testing.expectEqual(calls, Probe.pages);
    Probe.reset();
    var full: [2]abi.ProgramInstanceSnapshot = undefined;
    r = try Probe.create(.full, std.mem.asBytes(&full), 2, .{ .kind = 2 });
    _ = try r.step(false, Probe.clock, null);
    _ = try r.step(false, Probe.clock, null);
    _ = try r.step(false, Probe.clock, null);
    try std.testing.expectEqual(@as(u32, 1), Probe.full_begins);
    try std.testing.expectEqual(@as(u32, 0), Probe.lifecycle_begins);
    try std.testing.expectEqual(@as(usize, 2), (try r.fullView()).len);
}

test "inventory owner busy rollback restart capacity and invalid pages never publish Missing" {
    const target: abi.ProgramProcessHandle = .{ .instance_id = 99, .generation = 99 };
    var storage: [2]abi.ProgramLifecycleSnapshot = undefined;
    Probe.reset();
    var r = try Probe.create(.lifecycle, std.mem.asBytes(&storage), 2, .{ .kind = 2 });
    Probe.fault = .begin_busy;
    try std.testing.expectEqual(@intFromEnum(Status.would_block), (try r.step(false, Probe.clock, null)).status);
    try std.testing.expectEqual(@as(u64, 0), r.cursor.program_after_generation);
    Probe.fault = .none;
    _ = try r.step(false, Probe.clock, null);
    _ = try r.step(false, Probe.clock, null);
    const saved = r.cursor;
    Probe.fault = .page_busy;
    _ = try r.step(false, Probe.clock, null);
    try std.testing.expect(std.meta.eql(saved, r.cursor));
    try std.testing.expectEqual(@as(u32, 1), r.count);
    Probe.fault = .restart;
    try std.testing.expectEqual(@intFromEnum(Status.restart), (try r.step(false, Probe.clock, null)).status);
    try std.testing.expectEqual(@as(u32, 0), r.count);
    try std.testing.expectEqual(@intFromEnum(Disposition.unknown), (try r.findExact(target)).disposition);
    const calls = Probe.pages;
    _ = try r.step(false, Probe.clock, null);
    try std.testing.expectEqual(calls, Probe.pages);
    const original_deadline = r.deadline;
    _ = try r.restart();
    try std.testing.expect(std.meta.eql(original_deadline, r.deadline));
    try std.testing.expectEqual(@as(u32, 1), r.restarts);
    for ([_]Probe.Fault{ .epoch, .total, .empty_more, .oom }) |fault| {
        Probe.reset();
        r = try Probe.create(.lifecycle, std.mem.asBytes(&storage), 2, .{ .kind = 2 });
        _ = try r.step(false, Probe.clock, null);
        Probe.fault = fault;
        const result = try r.step(false, Probe.clock, null);
        try std.testing.expect(result.flags & flag_terminal != 0);
        try std.testing.expectEqual(@intFromEnum(Disposition.unknown), (try r.findExact(target)).disposition);
    }
    Probe.reset();
    r = try Probe.create(.lifecycle, std.mem.asBytes(&storage), 1, .{ .kind = 2 });
    _ = try r.step(false, Probe.clock, null);
    try std.testing.expectEqual(@intFromEnum(Status.capacity), (try r.step(false, Probe.clock, null)).status);
    try std.testing.expectEqual(@intFromEnum(Disposition.unknown), (try r.findExact(target)).disposition);
    Probe.reset();
    r = try Reader.init(.lifecycle, .{ .address = @intFromPtr(&storage), .length = @sizeOf(@TypeOf(storage)) }, 2, 1, .{}, Probe.initial, .{ .kind = 2 });
    try std.testing.expectEqual(@intFromEnum(Status.no_provider), (try r.step(false, Probe.clock, null)).status);
    try std.testing.expectEqual(@intFromEnum(Disposition.unknown), (try r.findExact(target)).disposition);
    var full: [2]abi.ProgramInstanceSnapshot = undefined;
    r = try Probe.create(.full, std.mem.asBytes(&full), 1, .{ .kind = 2 });
    try std.testing.expectEqual(@intFromEnum(Status.capacity), (try r.step(false, Probe.clock, null)).status);
    try std.testing.expectEqual(@as(u32, 0), Probe.pages);
}

test "inventory owner empty success stop after real return one poll and unrebased clock budget" {
    var storage: [2]abi.ProgramLifecycleSnapshot = undefined;
    for ([_]Probe.Fault{ .stop_inside, .expire_inside, .clock_inside }) |fault| {
        Probe.reset();
        var r = try Probe.create(.lifecycle, std.mem.asBytes(&storage), 2, .{ .kind = 1, .nanoseconds = 10 });
        _ = try r.step(false, Probe.clock, null);
        Probe.reader = &r;
        Probe.fault = fault;
        const result = try r.step(false, Probe.clock, null);
        try std.testing.expectEqual(@intFromEnum(switch (fault) {
            .stop_inside => Status.cancelled,
            .expire_inside => Status.timed_out,
            else => Status.clock_failed,
        }), result.status);
        try std.testing.expectEqual(@as(u32, 0), result.staged_count);
        try std.testing.expect(result.flags & flag_terminal != 0 and result.flags & flag_in_call == 0);
        if (fault == .stop_inside) try std.testing.expect(Probe.observed_active_loan);
        const calls = Probe.pages;
        _ = try r.step(false, Probe.clock, null);
        try std.testing.expectEqual(calls, Probe.pages);
    }
    Probe.reset();
    var r = try Probe.create(.lifecycle, std.mem.asBytes(&storage), 2, .{});
    try std.testing.expectEqual(@intFromEnum(Status.would_block), (try r.step(false, Probe.clock, null)).status);
    _ = try r.step(false, Probe.clock, null);
    try std.testing.expectEqual(@as(u32, 1), Probe.lifecycle_begins);
    try std.testing.expectEqual(@as(u32, 0), Probe.pages);
    Probe.reset();
    Probe.empty = true;
    r = try Probe.create(.lifecycle, std.mem.asBytes(&storage), 0, .{ .kind = 2 });
    _ = try r.step(false, Probe.clock, null);
    const done = try r.step(false, Probe.clock, null);
    try std.testing.expect(done.flags & flag_complete != 0);
    try std.testing.expectEqual(@as(usize, 0), (try r.lifecycleView()).len);
    try std.testing.expectEqual(@intFromEnum(Disposition.missing), (try r.findExact(.{ .instance_id = 9, .generation = 19 })).disposition);
}
