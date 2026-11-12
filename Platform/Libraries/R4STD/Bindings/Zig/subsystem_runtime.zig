const std = @import("std");
const r4os = @import("r4os");

const inventory_contract = r4os.system_update_inventory;
const catalog_contract = r4os.subsystem_catalog;

pub const inventory_path = "C:\\R4OS\\CONFIG\\MODULES.JSON";

pub const LoadStatus = enum {
    not_loaded,
    loaded,
    missing,
    too_large,
    read_failed,
    invalid,
};

pub const ProbeError = error{
    InvalidPath,
    MissingFile,
    Directory,
    ReadFailed,
};

pub const AccessStats = struct {
    info_calls: u32 = 0,
    read_calls: u32 = 0,
    read_bytes: u64 = 0,
};

pub const Inspection = struct {
    input: catalog_contract.Input,
    access: AccessStats,
};

var inventory_bytes: [inventory_contract.max_bytes]u8 = undefined;
var inventory_workspace: inventory_contract.Inventory = undefined;
var installed_catalog: catalog_contract.Catalog = .{};
var probe_bytes: [catalog_contract.max_probe_bytes]u8 = undefined;
var load_status: LoadStatus = .not_loaded;

pub fn load(sys: anytype) LoadStatus {
    installed_catalog = .{};
    const info = sys.fileInfo(inventory_path) orelse {
        load_status = .missing;
        return load_status;
    };
    if (info.is_dir != 0 or info.size == 0) {
        load_status = .invalid;
        return load_status;
    }
    if (info.size > inventory_bytes.len) {
        load_status = .too_large;
        return load_status;
    }
    const read = sys.fileRead(inventory_path, inventory_bytes[0..@intCast(info.size)]);
    if (read != @as(i32, @intCast(info.size))) {
        load_status = .read_failed;
        return load_status;
    }
    catalog_contract.Catalog.loadInstalled(
        inventory_bytes[0..@intCast(info.size)],
        &inventory_workspace,
        &installed_catalog,
        .{ .check = catalog_contract.assumeHostPresent },
    ) catch {
        installed_catalog = .{};
        load_status = .invalid;
        return load_status;
    };
    load_status = .loaded;
    return load_status;
}

pub fn status() LoadStatus {
    return load_status;
}

pub fn catalog() *const catalog_contract.Catalog {
    return &installed_catalog;
}

/// Reads only stable path metadata. The returned input deliberately carries an
/// incomplete empty probe for non-empty files so an unambiguous association
/// can be selected without touching source contents.
pub fn inspect(sys: anytype, guest_path: []const u8) ProbeError!Inspection {
    var parsed = r4os.path.AbsoluteFilePath.parse(guest_path) catch return error.InvalidPath;
    const info = sys.fileInfo(parsed.asZ().ptr) orelse return error.MissingFile;
    if (info.is_dir != 0) return error.Directory;
    return .{
        .input = .{
            .path = guest_path,
            .probe_prefix = &.{},
            .file_size = info.size,
            .probe_window_complete = info.size == 0,
        },
        .access = .{ .info_calls = 1 },
    };
}

/// Completes the bounded probe window with range reads. This remains valid for
/// files larger than the caller-owned window; whole-file `fileRead` would
/// reject exactly that case before returning any prefix.
pub fn completeProbe(sys: anytype, input: catalog_contract.Input, access: *AccessStats) ProbeError!catalog_contract.Input {
    var parsed = r4os.path.AbsoluteFilePath.parse(input.path) catch return error.InvalidPath;
    const wanted: usize = @intCast(@min(input.file_size, @as(u64, probe_bytes.len)));
    var offset: usize = 0;
    while (offset < wanted) {
        const read_offset = std.math.cast(u32, offset) orelse return error.ReadFailed;
        const read = sys.fileReadAt(parsed.asZ().ptr, read_offset, probe_bytes[offset..wanted]);
        access.read_calls +|= 1;
        if (read <= 0 or read > @as(i32, @intCast(wanted - offset))) return error.ReadFailed;
        const count: usize = @intCast(read);
        access.read_bytes +|= count;
        offset += count;
    }
    return .{
        .path = input.path,
        .probe_prefix = probe_bytes[0..wanted],
        .file_size = input.file_size,
        .probe_window_complete = true,
    };
}

pub fn probe(sys: anytype, guest_path: []const u8) ProbeError!catalog_contract.Input {
    var inspection = try inspect(sys, guest_path);
    return completeProbe(sys, inspection.input, &inspection.access);
}

pub fn hostPresent(sys: anytype, host_path: []const u8) bool {
    var storage: [r4os.path.file_path_max + 1:0]u8 = .{0} ** (r4os.path.file_path_max + 1);
    const path = hostPathZ(host_path, &storage) orelse return false;
    const info = sys.fileInfo(path) orelse return false;
    return info.is_dir == 0 and info.size != 0;
}

fn hostPathZ(host_path: []const u8, out: *[r4os.path.file_path_max + 1:0]u8) ?[*:0]const u8 {
    if (host_path.len == 0) return null;
    var pos: usize = 0;
    if (host_path[0] == '/') {
        if (host_path.len + 2 > out.len) return null;
        out[0] = 'C';
        out[1] = ':';
        pos = 2;
    } else if (host_path.len + 1 > out.len) return null;
    for (host_path) |byte| {
        if (byte == 0 or pos >= out.len - 1) return null;
        out[pos] = if (byte == '/') '\\' else byte;
        pos += 1;
    }
    out[pos] = 0;
    return @ptrCast(out);
}

test "host target conversion accepts installed canonical module paths" {
    var storage: [r4os.path.file_path_max + 1:0]u8 = .{0} ** (r4os.path.file_path_max + 1);
    const path = hostPathZ("/R4OS/SUBSYSTEMS/test.basic/SUBSYSOK.R4X", &storage).?;
    try @import("std").testing.expectEqualStrings("C:\\R4OS\\SUBSYSTEMS\\test.basic\\SUBSYSOK.R4X", @import("std").mem.span(path));
}

test "bounded probe uses range I/O for a source larger than its window" {
    const FakeSys = struct {
        info_calls: u32 = 0,
        read_calls: u32 = 0,
        read_bytes: u64 = 0,

        pub fn fileInfo(self: *@This(), _: [*:0]const u8) ?r4os.abi.FileInfo {
            self.info_calls += 1;
            return .{ .exists = 1, .size = catalog_contract.max_probe_bytes + 1 };
        }

        pub fn fileReadAt(self: *@This(), _: [*:0]const u8, _: u32, out: []u8) i32 {
            self.read_calls += 1;
            self.read_bytes += out.len;
            @memset(out, 'A');
            return @intCast(out.len);
        }
    };

    var sys: FakeSys = .{};
    var inspection = try inspect(&sys, "C:\\TEMP\\LARGE.BAS");
    const input = try completeProbe(&sys, inspection.input, &inspection.access);
    try std.testing.expect(input.probe_window_complete);
    try std.testing.expectEqual(catalog_contract.max_probe_bytes, input.probe_prefix.len);
    try std.testing.expectEqual(@as(u32, 1), inspection.access.info_calls);
    try std.testing.expectEqual(@as(u32, 1), inspection.access.read_calls);
    try std.testing.expectEqual(@as(u64, catalog_contract.max_probe_bytes), inspection.access.read_bytes);
    try std.testing.expectEqual(@as(u32, 1), sys.info_calls);
    try std.testing.expectEqual(@as(u32, 1), sys.read_calls);
    try std.testing.expectEqual(@as(u64, catalog_contract.max_probe_bytes), sys.read_bytes);
}
