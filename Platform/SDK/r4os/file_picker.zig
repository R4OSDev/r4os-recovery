//! Bounded caller-owned controller; the existing metadata provider owns I/O.
const std = @import("std");
pub const abi = @import("r4os_contract").abi;
const wire = @import("binary_cursor.zig");
const path = @import("path.zig");
const text = @import("bounded_text.zig");
const gui = @import("gui.zig");
pub const invalid: i32 = -201;
pub const storage_error: i32 = -202;
pub const busy: i32 = -203;
pub const incomplete: i32 = -204;
pub const bad_provider: i32 = -205;
pub const closed: i32 = -206;
pub const exhausted: i32 = -207;
pub const stale: i32 = -10;
pub const missing: i32 = -208;
pub const file: u32 = 0;
pub const directory: u32 = 1;
pub const previous: u32 = 2;
pub const next: u32 = 3;
pub const decision_none: u32 = 0;
pub const decision_file: u32 = 1;
pub const decision_overwrite: u32 = 2;
pub const decision_cancelled: u32 = 3;
pub const mode_open: u32 = 1;
pub const mode_save: u32 = 2;
pub const FilterFn = *const fn (?*anyopaque, *const abi.DirectoryMetadataEntry2) callconv(.c) i32;
pub const Provider = extern struct {
    info: ?abi.R4SysFns.file_metadata2 = null,
    batch: ?abi.R4SysFns.directory_metadata_batch2 = null,
    filter: ?FilterFn = null,
    filter_context: ?*anyopaque = null,
};
pub const Row = extern struct {
    entry: abi.DirectoryMetadataEntry2 = .{},
    kind: u32 = file,
    reserved0: u32 = 0,
    label: [256]u8 = @splat(0),
};
pub const Decision = extern struct {
    entry: abi.DirectoryMetadataEntry2 = .{},
    kind: u32 = decision_none,
    reserved0: u32 = 0,
};
pub const Progress = extern struct {
    revision: u64,
    seen: u64,
    count: u32,
    staged: u32,
    number: u32,
    selected: u32,
    first_index: u32,
    focus: u32,
    pressed: u32,
    flags: u32,
    error_code: i32,
    reserved0: u32 = 0,
};
fn overlap(a: wire.Span, b: wire.Span) bool {
    return a.length != 0 and b.length != 0 and a.address < b.address + b.length and b.address < a.address + a.length;
}
fn z(bytes: []const u8) ?[:0]const u8 {
    const end = std.mem.indexOfScalar(u8, bytes, 0) orelse return null;
    return bytes[0..end :0];
}
fn validInfo(info: abi.FileMetadata2) bool {
    return info.version == 1 and info.size == @sizeOf(abi.FileMetadata2) and
        info.flags & (abi.file_metadata2_flag_exists | abi.file_metadata2_flag_identity_valid) ==
            (abi.file_metadata2_flag_exists | abi.file_metadata2_flag_identity_valid) and
        info.flags & ~@as(u32, 255) == 0 and info.identity.mount_generation != 0 and
        info.identity.flags & abi.file_identity2_flag_namespace != 0 and info.identity.reserved0 == 0 and
        info.reserved0 == 0 and std.mem.allEqual(u16, &info.reserved1, 0);
}
fn isDirectory(info: abi.FileMetadata2) bool {
    return info.flags & abi.file_metadata2_flag_directory != 0;
}
fn tail(value: []const u8) []const u8 {
    const at = std.mem.lastIndexOfScalar(u8, value, '\\') orelse return value;
    return value[at + 1 ..];
}
pub const Session = extern struct {
    provider: Provider,
    active: wire.Span,
    candidate: wire.Span,
    active_cursor: abi.DirectoryMetadataCursor2 = .{},
    candidate_cursor: abi.DirectoryMetadataCursor2 = .{},
    directory_path: [1024]u8 = @splat(0),
    candidate_path: [1024]u8 = @splat(0),
    extension: [64]u8 = @splat(0),
    filename: [768]u8 = @splat(0),
    confirmed: Decision = .{},
    candidate_info: abi.FileMetadata2 = .{},
    revision: u64 = 0,
    seen: u64 = 0,
    capacity: u32,
    count: u32 = 0,
    staged: u32 = 0,
    number: u32 = 0,
    candidate_number: u32 = 0,
    selected: u32 = 0,
    first_index: u32 = 0,
    focus: u32 = 0,
    pressed: u32 = 4, // 4 means no pressed control,0..3 are focus targets.
    mode: u32,
    phase: u32 = 0, // 0 idle,1 directory lookup,2 scan,3 closed.
    in_call: u32 = 0,
    error_code: i32 = 0,
    overwrite_pending: u32 = 0, // Idle candidate_info/path bind the question.

    pub fn init(a: []Row, b: []Row, mode: u32, extension: []const u8, provider: Provider, out: *Session) i32 {
        if (a.len < 4 or a.len > 256) return storage_error;
        const left = wire.Span{ .address = @intFromPtr(a.ptr), .length = std.mem.sliceAsBytes(a).len };
        const right = wire.Span{ .address = @intFromPtr(b.ptr), .length = std.mem.sliceAsBytes(b).len };
        return initSpans(left, right, @intCast(a.len), mode, extension, provider, out);
    }
    pub fn initSpans(a: wire.Span, b: wire.Span, capacity: u32, mode: u32, extension: []const u8, provider: Provider, out: *Session) i32 {
        if (mode != mode_open and mode != mode_save or extension.len >= 64 or !text.valid(extension)) return invalid;
        const own = wire.Span{ .address = @intFromPtr(out), .length = @sizeOf(Session) };
        own.validate() catch return storage_error;
        a.validate() catch return storage_error;
        b.validate() catch return storage_error;
        if (capacity < 4 or capacity > 256 or a.length < @as(usize, capacity) * @sizeOf(Row) or
            b.length < @as(usize, capacity) * @sizeOf(Row) or a.address % @alignOf(Row) != 0 or b.address % @alignOf(Row) != 0 or
            overlap(a, b) or overlap(a, own) or overlap(b, own)) return storage_error;
        var value = Session{ .provider = provider, .active = a, .candidate = b, .capacity = capacity, .mode = mode };
        if (!text.assignZ(&value.extension, extension)) return invalid;
        out.* = value;
        return 0;
    }
    fn check(self: *const Session) i32 {
        self.active.validate() catch return storage_error;
        self.candidate.validate() catch return storage_error;
        const own = wire.Span{ .address = @intFromPtr(self), .length = @sizeOf(Session) };
        own.validate() catch return storage_error;
        if (self.capacity < 4 or self.capacity > 256 or self.active.length < @as(usize, self.capacity) * @sizeOf(Row) or
            self.candidate.length < @as(usize, self.capacity) * @sizeOf(Row) or self.active.address % @alignOf(Row) != 0 or
            self.candidate.address % @alignOf(Row) != 0 or overlap(self.active, self.candidate) or
            overlap(self.active, own) or overlap(self.candidate, own)) return storage_error;
        if (self.phase > 3 or self.in_call > 1 or self.overwrite_pending > 1 or self.count > self.capacity or self.staged > self.capacity or
            self.focus > 3 or self.pressed > 4 or self.mode != mode_open and self.mode != mode_save or
            self.count != 0 and self.selected >= self.count) return invalid;
        return 0;
    }
    fn enter(self: *const Session) i32 {
        const rc = self.check();
        if (rc != 0) return rc;
        if (self.in_call != 0) return busy;
        return if (self.phase == 3) closed else 0;
    }
    pub fn progress(self: *const Session, out: *Progress) i32 {
        const rc = self.check();
        if (rc != 0) return rc;
        out.* = .{ .revision = self.revision, .seen = self.seen, .count = self.count, .staged = self.staged, .number = self.number, .selected = self.selected, .first_index = self.first_index, .focus = self.focus, .pressed = self.pressed, .flags = @as(u32, if (self.revision != 0) 1 else 0) |
            @as(u32, if (self.phase == 1 or self.phase == 2) 2 else 0) |
            @as(u32, if (self.in_call != 0) 4 else 0) | @as(u32, if (self.phase == 3) 8 else 0), .error_code = self.error_code };
        return 0;
    }
    pub fn view(self: *const Session, out: *wire.Span) i32 {
        const rc = self.enter();
        if (rc != 0) return rc;
        if (self.revision == 0) return incomplete;
        out.* = .{ .address = self.active.address, .length = @as(usize, self.count) * @sizeOf(Row) };
        return 0;
    }
    pub fn rows(self: *const Session) ?[]const Row {
        var span: wire.Span = .{};
        if (self.view(&span) != 0) return null;
        return @as([*]const Row, @ptrFromInt(span.address))[0..self.count];
    }
    pub fn begin(self: *Session, input: []const u8, number: u32) i32 {
        const rc = self.enter();
        if (rc != 0) return rc;
        if (self.revision == std.math.maxInt(u64)) return exhausted;
        const normalized = path.AbsoluteFilePath.parse(input) catch return invalid;
        if (!text.assignZ(&self.candidate_path, normalized.bytes())) return invalid;
        self.candidate_cursor = .{};
        self.candidate_info = .{};
        self.overwrite_pending = 0;
        self.candidate_number = number;
        self.staged = 0;
        self.seen = 0;
        self.phase = 1;
        self.error_code = 0;
        return 0;
    }
    fn add(self: *Session, kind: u32, entry: abi.DirectoryMetadataEntry2, label: []const u8) bool {
        if (self.staged >= self.capacity) return false;
        const output: [*]Row = @ptrFromInt(self.candidate.address);
        var row = Row{ .entry = entry, .kind = kind };
        if (!text.labelZ(&row.label, label)) return false;
        output[self.staged] = row;
        self.staged += 1;
        return true;
    }
    fn fail(self: *Session, rc: i32) i32 {
        self.phase = 0;
        self.staged = 0;
        self.candidate_cursor = .{};
        self.error_code = rc;
        return rc;
    }
    fn readInfo(self: *Session, value: [*:0]const u8, out: *abi.FileMetadata2) i32 {
        const call = self.provider.info orelse return abi.err_no_fn;
        return call(value, out);
    }
    fn batch(self: *Session, input: ?[*:0]const u8, cursor: *abi.DirectoryMetadataCursor2, entry: ?*abi.DirectoryMetadataEntry2, capacity: u32) i32 {
        const call = self.provider.batch orelse return abi.err_no_fn;
        return call(input, cursor, if (entry) |value| @as([*]abi.DirectoryMetadataEntry2, @ptrCast(value)) else null, capacity);
    }
    fn parent(self: *Session) bool {
        const current = z(&self.candidate_path) orelse return false;
        const at = std.mem.lastIndexOfScalar(u8, current, '\\') orelse return false;
        var entry: abi.DirectoryMetadataEntry2 = .{};
        if (!text.assignZ(&entry.path, current[0..@max(3, at)])) return false;
        return self.add(directory, entry, "[DIR] ..");
    }
    pub fn step(self: *Session, budget: u32) i32 {
        const rc = self.enter();
        if (rc != 0) return rc;
        if (budget == 0 or budget > 64) return invalid;
        if (self.phase == 0) return 0;
        self.in_call = 1;
        defer self.in_call = 0;
        var used: u32 = 0;
        while (used < budget) : (used += 1) {
            if (self.phase == 1) {
                var info: abi.FileMetadata2 = .{};
                const code = self.readInfo(@ptrCast(&self.candidate_path), &info);
                if (code != 1) return self.fail(if (code == 0) missing else if (code > 0) bad_provider else code);
                if (!validInfo(info)) return self.fail(bad_provider);
                if (!isDirectory(info)) return self.fail(invalid);
                self.candidate_info = info;
                if (!self.parent() or (self.candidate_number != 0 and !self.add(previous, .{}, "<< Previous page"))) return self.fail(bad_provider);
                self.phase = 2;
                continue;
            }
            var cursor = self.candidate_cursor;
            var entry: abi.DirectoryMetadataEntry2 = .{};
            const code = self.batch(@ptrCast(&self.candidate_path), &cursor, &entry, 1);
            if (code != 0 and code != 1 and code != abi.file_metadata2_result_end) return self.fail(if (code > 0) bad_provider else code);
            if (cursor.version != 1 or cursor.size != @sizeOf(abi.DirectoryMetadataCursor2) or
                cursor.flags != abi.directory_metadata2_flag_bound or cursor.reserved0 != 0 or
                cursor.namespace_generation != self.candidate_info.identity.namespace_generation or
                cursor.scan.change.mount_slot != self.candidate_info.identity.mount_slot or
                cursor.scan.change.mount_generation != self.candidate_info.identity.mount_generation) return self.fail(stale);
            self.candidate_cursor = cursor;
            if (code == 0) continue;
            const page_size: u64 = self.capacity - 3;
            const first = @as(u64, self.candidate_number) * page_size;
            if (code == abi.file_metadata2_result_end) {
                if (self.seen > first + page_size and !self.add(next, .{}, "Next page >>")) return self.fail(bad_provider);
                const saved = self.active;
                self.active = self.candidate;
                self.candidate = saved;
                self.active_cursor = self.candidate_cursor;
                self.directory_path = self.candidate_path;
                self.count = self.staged;
                self.number = self.candidate_number;
                self.selected = 0;
                self.first_index = 0;
                self.pressed = 4;
                self.revision += 1;
                self.phase = 0;
                self.staged = 0;
                self.error_code = 0;
                return 0;
            }
            if (!validInfo(entry.info) or entry.info.identity.namespace_generation != cursor.namespace_generation or
                entry.info.identity.mount_slot != cursor.scan.change.mount_slot or entry.info.identity.mount_generation != cursor.scan.change.mount_generation) return self.fail(bad_provider);
            const value = z(&entry.path) orelse return self.fail(bad_provider);
            const normalized = path.AbsoluteFilePath.parse(value) catch return self.fail(bad_provider);
            if (!std.mem.eql(u8, normalized.bytes(), value)) return self.fail(bad_provider);
            const name = tail(value);
            if (path.equalsIgnoreCase(value, z(&self.candidate_path).?) or std.mem.eql(u8, name, ".") or std.mem.eql(u8, name, "..")) continue;
            if (!isDirectory(entry.info)) {
                const extension = z(&self.extension) orelse return self.fail(invalid);
                if (extension.len != 0 and !std.ascii.endsWithIgnoreCase(value, extension)) continue;
                if (self.provider.filter) |filter| {
                    const accepted = filter(self.provider.filter_context, &entry);
                    if (accepted < 0) return self.fail(accepted);
                    if (accepted == 0) continue;
                    if (accepted != 1) return self.fail(bad_provider);
                }
            }
            if (self.seen >= first and self.seen - first < page_size) {
                var label: [256]u8 = @splat(0);
                const prefix = if (isDirectory(entry.info)) "[DIR] " else "";
                if (!text.assignZ(&label, prefix) or !text.labelZ(label[prefix.len..], name) or
                    !self.add(if (isDirectory(entry.info)) directory else file, entry, z(&label).?)) return self.fail(bad_provider);
            }
            self.seen = std.math.add(u64, self.seen, 1) catch return self.fail(exhausted);
        }
        return 0;
    }
    pub fn select(self: *Session, revision: u64, index: u32, visible: u32) i32 {
        const rc = self.enter();
        if (rc != 0) return rc;
        if (revision == 0 or revision != self.revision) return stale;
        if (index >= self.count or visible == 0) return invalid;
        if (index != self.selected) self.overwrite_pending = 0;
        self.selected = index;
        self.first_index = @intCast(gui.listFirstIndexForSelection(self.count, visible, index, self.first_index));
        return 0;
    }
    pub fn setName(self: *Session, value: []const u8) i32 {
        const rc = self.enter();
        if (rc != 0) return rc;
        if (value.len == 0) {
            self.overwrite_pending = 0;
            @memset(&self.filename, 0);
            return 0;
        }
        if (std.mem.indexOfAny(u8, value, "\\/") != null or std.mem.eql(u8, value, ".") or std.mem.eql(u8, value, "..")) return invalid;
        const normalized = path.RelativeFilePath.parse(value) catch return invalid;
        if (!std.mem.eql(u8, value, normalized.bytes())) return invalid;
        const changed = !std.mem.eql(u8, value, z(&self.filename) orelse return invalid);
        if (!text.assignZ(&self.filename, value)) return invalid;
        if (changed) self.overwrite_pending = 0;
        return 0;
    }
    fn validateActive(self: *Session) i32 {
        if (self.revision == 0) return incomplete;
        var cursor = self.active_cursor;
        const rc = self.batch(null, &cursor, null, 0);
        if (rc != 0) return if (rc > 0) bad_provider else rc;
        if (cursor.namespace_generation != self.active_cursor.namespace_generation or
            cursor.scan.change.mount_generation != self.active_cursor.scan.change.mount_generation or
            cursor.scan.change.mount_slot != self.active_cursor.scan.change.mount_slot or cursor.flags != abi.directory_metadata2_flag_bound) return stale;
        return 0;
    }
    /// Whole historical selection; validation is an observation, never an open.
    pub fn activate(self: *Session, revision: u64, use_name: bool, allow_overwrite: bool, out: *Decision) i32 {
        const rc = self.enter();
        if (rc != 0) return rc;
        if (revision == 0 or revision != self.revision) return stale;
        if (self.phase != 0) return incomplete;
        self.in_call = 1;
        var result = Decision{};
        var navigation = false;
        var page: u32 = 0;
        const code = blk: {
            const checked = self.validateActive();
            if (checked != 0) break :blk checked;
            const row = @as([*]const Row, @ptrFromInt(self.active.address))[self.selected];
            if (!use_name and (row.kind == previous or row.kind == next)) {
                if (row.kind == previous and self.number == 0 or row.kind == next and self.number == std.math.maxInt(u32)) break :blk invalid;
                result.entry.path = self.directory_path;
                page = if (row.kind == previous) self.number - 1 else self.number + 1;
                navigation = true;
                break :blk 0;
            }
            if (use_name) {
                const name = z(&self.filename) orelse break :blk invalid;
                if (name.len == 0) break :blk invalid;
                const dir = z(&self.directory_path) orelse break :blk invalid;
                var joined: [1024]u8 = undefined;
                const value = std.fmt.bufPrint(&joined, "{s}{s}{s}", .{ dir, if (dir.len == 3) "" else "\\", name }) catch break :blk invalid;
                const normalized = path.AbsoluteFilePath.parse(value) catch break :blk invalid;
                if (!text.assignZ(&result.entry.path, normalized.bytes())) break :blk invalid;
            } else result.entry.path = row.entry.path;
            var info: abi.FileMetadata2 = .{};
            const found = self.readInfo(@ptrCast(&result.entry.path), &info);
            if (found == 0) {
                if (!use_name or self.mode != mode_save) break :blk missing;
                if (allow_overwrite and self.overwrite_pending != 0) break :blk stale;
                // Validate once more: a missing lookup supplies no identity.
                const stable = self.validateActive();
                if (stable != 0) break :blk stable;
                result.kind = decision_file;
                break :blk 0;
            }
            if (found != 1) break :blk if (found > 0) bad_provider else found;
            if (!validInfo(info)) break :blk bad_provider;
            if (info.identity.namespace_generation != self.active_cursor.namespace_generation) break :blk stale;
            if ((use_name or row.entry.info.flags & abi.file_metadata2_flag_identity_valid != 0) and
                (info.identity.mount_slot != self.active_cursor.scan.change.mount_slot or
                    info.identity.mount_generation != self.active_cursor.scan.change.mount_generation)) break :blk stale;
            if (!use_name and row.entry.info.flags & abi.file_metadata2_flag_identity_valid != 0 and
                !std.meta.eql(row.entry.info.identity, info.identity)) break :blk stale;
            if (!use_name and (row.kind == directory) != isDirectory(info)) break :blk stale;
            if (self.mode == mode_save and allow_overwrite and self.overwrite_pending != 0 and
                (!std.mem.eql(u8, z(&result.entry.path) orelse break :blk invalid, z(&self.candidate_path) orelse break :blk invalid) or
                    !std.meta.eql(info.identity, self.candidate_info.identity))) break :blk stale;
            result.entry.info = info;
            if (isDirectory(info)) {
                navigation = true;
                break :blk 0;
            }
            if (self.mode == mode_save and allow_overwrite and self.overwrite_pending == 0) break :blk stale;
            result.kind = if (self.mode == mode_save and !allow_overwrite) decision_overwrite else decision_file;
            break :blk 0;
        };
        self.in_call = 0; // Every provider/filter call really returned.
        if (code != 0) {
            self.error_code = code;
            return code;
        }
        if (navigation) {
            const started = self.begin(z(&result.entry.path) orelse return invalid, page);
            if (started != 0) return started;
            out.* = .{};
        } else {
            if (result.kind == decision_file) {
                self.confirmed = result;
                self.overwrite_pending = 0;
            } else if (result.kind == decision_overwrite) {
                self.candidate_info = result.entry.info;
                self.candidate_path = result.entry.path;
                self.overwrite_pending = 1;
            }
            out.* = result;
        }
        self.error_code = 0;
        return 0;
    }
    pub fn cancel(self: *Session, out: *Decision) i32 {
        const rc = self.enter();
        if (rc != 0) return rc;
        self.phase = 3;
        self.overwrite_pending = 0;
        self.staged = 0;
        self.candidate_cursor = .{};
        self.pressed = 4;
        out.* = .{ .kind = decision_cancelled };
        return 0;
    }
    /// Existing GUI focus traversal; up/down affect only list focus. Filename
    /// editing/format/overwrite UI is caller policy, supplied via setName.
    pub fn key(self: *Session, key_code: u8, visible: u32, out: *Decision) i32 {
        const rc = self.enter();
        if (rc != 0) return rc;
        if (key_code == gui.Key.escape) return self.cancel(out);
        if (self.phase != 0) return incomplete;
        const actions = [_]gui.DialogAction{ .select, .next, .ok, .cancel };
        if (key_code == gui.Key.tab or key_code == gui.Key.shift_tab) {
            const items = [_]gui.DialogFocusItem{ .{ .action = .select }, .{ .action = .next, .enabled = self.mode == mode_save }, .{ .action = .ok }, .{ .action = .cancel } };
            const focus = gui.dialogFocusStep(&items, actions[self.focus], if (key_code == gui.Key.tab) .next else .previous);
            for (actions, 0..) |action, index| if (focus == action) {
                self.focus = @intCast(index);
            };
        } else if (self.focus == 0 and self.count != 0 and (key_code == gui.Key.up or key_code == gui.Key.down)) {
            const selected = if (key_code == gui.Key.up) (if (self.selected == 0) self.count - 1 else self.selected - 1) else (if (self.selected + 1 == self.count) 0 else self.selected + 1);
            const selected_rc = self.select(self.revision, selected, visible);
            if (selected_rc != 0) return selected_rc;
        } else if (key_code == gui.Key.enter or key_code == '\n' or key_code == ' ' and self.focus >= 2) {
            if (self.focus == 3) return self.cancel(out);
            return self.activate(self.revision, self.focus == 1 or self.focus == 2 and self.filename[0] != 0, false, out);
        }
        out.* = .{};
        return 0;
    }
    pub fn setFocus(self: *Session, focus: u32, pressed: u32) i32 {
        const rc = self.enter();
        if (rc != 0) return rc;
        if (focus > 3 or pressed > 4) return invalid;
        if (self.mode == mode_open and focus == 1) return invalid;
        self.focus = focus;
        self.pressed = pressed;
        return 0;
    }
};
