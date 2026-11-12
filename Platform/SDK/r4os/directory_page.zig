const std = @import("std");
const storage = @import("app_storage.zig");
const text = @import("bounded_text.zig");
const abi = @import("r4os_contract").abi;
const picker = @import("file_picker_api.zig");
const metadata = @import("metadata2.zig");

/// Bounded dialog pages own paths and kinds. Labels are presentation only;
/// activating a row never enumerates its old filesystem index again.
pub fn DialogPage(comptime capacity: usize, comptime path_bytes: usize, comptime label_bytes: usize) type {
    if (capacity < 4) @compileError("A page needs parent, previous, next and file rows");
    return struct {
        const Self = @This();
        pub const page_size = capacity - 3;
        pub const Kind = enum { file, directory, previous, next };
        pub const Row = struct {
            kind: Kind = .file,
            path: [path_bytes]u8 = .{0} ** path_bytes,
            label: [label_bytes]u8 = .{0} ** label_bytes,
            identity: abi.FileIdentity2 = .{},
        };
        directory: [path_bytes]u8 = .{0} ** path_bytes,
        rows: [capacity]Row = .{Row{}} ** capacity,
        count: usize = 0,
        number: u32 = 0,
        cursor: ?abi.DirectoryMetadataCursor2 = null,
        last_error: i32 = 0,

        /// Builds privately through the real end, including entries beyond
        /// the visible page, so an I/O error cannot publish a partial view.
        pub fn load(self: *Self, files: storage.Files, directory: storage.PathZ, number: u32, extension: []const u8) bool {
            if (directory.len >= path_bytes) return false;
            if (capacity <= 256) {
                if (files.sys.base.generation2) |context| {
                    const result = self.loadPicker(files, context, directory, number, extension);
                    self.last_error = result;
                    return result == 0;
                }
            }
            var next = Self{ .number = number };
            if (!text.assignZ(&next.directory, directory.bytes())) return false;
            var iterator = files.iterate(directory);
            iterator.index = 1; // Parent row; omit the redundant current-directory row.
            var path: [path_bytes]u8 = undefined;
            const parent = switch (iterator.next(&path)) {
                .entry => |entry| entry,
                else => return false,
            };
            if (!next.add(.directory, parent.path, "[DIR] ..")) return false;
            if (number != 0 and !next.add(.previous, "", "<< Previous page")) return false;
            const first = @as(u64, number) * page_size;
            var seen: u64 = 0;
            while (true) {
                const entry = switch (iterator.next(&path)) {
                    .entry => |entry| entry,
                    .end => break,
                    .failure => return false,
                };
                if (entry.kind == .file and extension.len != 0 and !std.ascii.endsWithIgnoreCase(entry.path, extension)) continue;
                if (seen >= first and seen - first < page_size) {
                    const name = tail(entry.path);
                    var label: [label_bytes]u8 = .{0} ** label_bytes;
                    const prefix = if (entry.kind == .directory) "[DIR] " else "";
                    if (prefix.len >= label.len or !text.assignZ(&label, prefix) or
                        !text.labelZ(label[prefix.len..], name)) return false;
                    if (!next.add(if (entry.kind == .directory) .directory else .file, entry.path, std.mem.sliceTo(&label, 0))) return false;
                }
                seen += 1;
            }
            if (seen > first + page_size and !next.add(.next, "", "Next page >>")) return false;
            self.* = next;
            return true;
        }

        fn loadPicker(self: *Self, files: storage.Files, context: *const @import("platform2.zig").Context, directory: storage.PathZ, number: u32, extension: []const u8) i32 {
            const binding = picker.provider2(context);
            if (binding.status != 0) return binding.status;
            const buffers = files.sys.allocator().alloc(picker.Row, capacity * 2) catch return picker.codes.storage_error;
            defer files.sys.allocator().free(buffers);
            var session: picker.Session = undefined;
            const initialized = picker.Session.init(buffers[0..capacity], buffers[capacity..], picker.codes.mode_open, extension, binding.provider, &session);
            if (initialized != 0) return initialized;
            defer {
                var decision: picker.Decision = undefined;
                _ = session.cancel(&decision);
            }
            var path = directory.bytes();
            while (path.len > 3 and (path[path.len - 1] == '\\' or path[path.len - 1] == '/')) path = path[0 .. path.len - 1];
            const begun = session.begin(path, number);
            if (begun != 0) return begun;
            const platform = @import("platform2.zig");
            const clock = platform.abi.function(platform.abi.R4SysFns2, context.system(), "monotonic_clock");
            const rpc = @import("rpc_budget.zig");
            var budget = rpc.Budget.fromTimeout(clock, .{ .kind = 1, .nanoseconds = 5_000_000_000 }) catch |err| return rpc.code(err);
            while (session.phase != 0) {
                _ = budget.remainingTicks() catch |err| return rpc.code(err);
                const advanced = session.step(64);
                if (advanced != 0) return advanced;
                if (session.phase != 0) files.sys.taskYield();
            }
            const rows = session.rows() orelse return picker.codes.incomplete;
            var next = Self{ .number = number, .cursor = session.active_cursor };
            if (!text.assignZ(&next.directory, std.mem.sliceTo(&session.directory_path, 0))) return picker.codes.storage_error;
            for (rows) |row| {
                const kind: Kind = switch (row.kind) {
                    picker.codes.file => .file,
                    picker.codes.directory => .directory,
                    picker.codes.previous => .previous,
                    picker.codes.next => .next,
                    else => return picker.codes.bad_provider,
                };
                const at = next.count;
                var label: [label_bytes]u8 = undefined;
                if (!text.labelZ(&label, std.mem.sliceTo(&row.label, 0)) or
                    !next.add(kind, std.mem.sliceTo(&row.entry.path, 0), std.mem.sliceTo(&label, 0))) return picker.codes.storage_error;
                if (row.entry.info.flags & abi.file_metadata2_flag_identity_valid != 0) next.rows[at].identity = row.entry.info.identity;
            }
            self.* = next;
            return 0;
        }

        /// A copied UI row is an observation. Validate the exact directory
        /// cursor and object identity again before acting on its full path.
        pub fn verify(self: *const Self, files: storage.Files, index: usize) i32 {
            if (index >= self.count) return picker.codes.invalid;
            var cursor = self.cursor orelse return 0;
            const context = files.sys.base.generation2 orelse return abi.err_no_group;
            var empty: [0]abi.DirectoryMetadataEntry2 = .{};
            const rc = metadata.batch(context, null, &cursor, &empty);
            if (rc != 0) return rc;
            const row = &self.rows[index];
            if (row.identity.mount_generation == 0) return 0;
            const info = switch (metadata.info(context, @ptrCast(&row.path))) {
                .found => |value| value,
                .missing => return picker.codes.missing,
                .failure => |code| return code,
            };
            if (info.version != 1 or info.size != @sizeOf(abi.FileMetadata2) or
                info.flags & abi.file_metadata2_flag_identity_valid == 0 or
                !std.meta.eql(row.identity, info.identity) or
                (info.flags & abi.file_metadata2_flag_directory != 0) != (row.kind == .directory)) return picker.codes.stale;
            return 0;
        }

        fn add(self: *Self, kind: Kind, path: []const u8, label: []const u8) bool {
            const row = &self.rows[self.count];
            row.kind = kind;
            if (!text.assignZ(&row.path, path) or !text.assignZ(&row.label, label)) return false;
            self.count += 1;
            return true;
        }
    };
}

/// A caller-owned, ordered best-N set. Scanning all entries with this set
/// gives a globally sorted page without retaining the entire directory.
pub fn OrderedPage(comptime T: type, comptime capacity: usize) type {
    return struct {
        entries: [capacity]T = undefined,
        count: usize = 0,

        pub fn offer(self: *@This(), value: T, context: anytype, comptime less: fn (@TypeOf(context), T, T) bool) void {
            if (self.count == capacity and !less(context, value, self.entries[capacity - 1])) return;
            var at = @min(self.count, capacity - 1);
            while (at > 0 and less(context, value, self.entries[at - 1])) : (at -= 1) {
                self.entries[at] = self.entries[at - 1];
            }
            self.entries[at] = value;
            self.count = @min(self.count + 1, capacity);
        }
    };
}

pub fn Snapshot(comptime T: type, comptime max_bytes: usize) type {
    return struct {
        const Self = @This();
        pub const limit = max_bytes / @sizeOf(T);
        values: std.ArrayList(T) = .empty,

        pub fn append(self: *Self, allocator: std.mem.Allocator, value: T) !void {
            if (self.values.items.len == limit) return error.OutOfMemory;
            if (self.values.items.len == self.values.capacity) {
                const capacity = @min(limit, @max(64, self.values.capacity * 2));
                try self.values.ensureTotalCapacityPrecise(allocator, capacity);
            }
            self.values.appendAssumeCapacity(value);
        }
        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            self.values.deinit(allocator);
            self.* = .{};
        }
        pub fn sort(self: *Self, context: anytype, comptime less: fn (@TypeOf(context), T, T) bool) void {
            std.sort.heap(T, self.values.items, context, less);
        }
    };
}

fn tail(path: []const u8) []const u8 {
    var start: usize = 0;
    for (path, 0..) |ch, index| if (ch == '\\' or ch == '/') {
        start = index + 1;
    };
    return path[start..];
}
