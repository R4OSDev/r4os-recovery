// Physical storage facade. All identities and ownership come from R4SYS;
// this layer never talks to drivers or reinterprets filesystem internals.
const abi = @import("r4os_contract").abi;
const r4sys = @import("r4sys.zig");
const std = @import("std");

pub const Context = struct {
    sys: *const r4sys.Context,

    pub fn available(self: Context) bool {
        return self.sys.hasFn("storage_inventory") and self.sys.hasFn("storage_claim_begin") and
            self.sys.hasFn("storage_use_begin") and self.sys.hasFn("storage_use_end");
    }
    fn call(self: Context, comptime name: []const u8, args: anytype) i32 {
        if (!self.sys.hasFn(name)) return abi.storage_error_unsupported;
        const function: @field(abi.R4SysFns, name) = @ptrFromInt(@field(self.sys.base.bundle.?.sys.?.*, name));
        return @call(.auto, function, args);
    }
    pub fn inventory(self: Context, out: *abi.StorageInventory) i32 {
        out.* = .{};
        return self.call("storage_inventory", .{out});
    }
    pub fn device(self: Context, generation: u64, slot: u32, out: *abi.StorageDeviceInfo) i32 {
        out.* = .{};
        return self.call("storage_device", .{ generation, slot, out });
    }
    pub fn partition(self: Context, generation: u64, device_ref: *const abi.StorageDeviceRef, slot: u32, out: *abi.StoragePartitionInfo) i32 {
        out.* = .{};
        return self.call("storage_partition", .{ generation, device_ref, slot, out });
    }
    pub fn volume(self: Context, generation: u64, slot: u32, out: *abi.StorageVolumeInfo) i32 {
        out.* = .{};
        return self.call("storage_volume", .{ generation, slot, out });
    }
    pub fn wholeDevice(info: abi.StorageDeviceInfo) abi.StorageTarget {
        return .{ .device = info.reference, .layout_generation = info.layout_generation, .sector_count = info.sector_count, .kind = abi.storage_target_device };
    }
    pub fn claimBegin(self: Context, target: *const abi.StorageTarget, out: *u64) i32 {
        out.* = 0;
        return self.call("storage_claim_begin", .{ target, out });
    }
    // BUSY means raw I/O is still draining; the caller retains this handle.
    // I/O/remount failures consume it and leave the failed target inventoried.
    pub fn claimEnd(self: Context, claim: *u64, keep_unmounted: bool) i32 {
        const result = self.call("storage_claim_end", .{ claim.*, @as(u32, if (keep_unmounted) abi.storage_claim_end_keep_unmounted else 0) });
        if (result == abi.storage_result_ok or result == abi.storage_error_io or result == abi.storage_error_remount) claim.* = 0;
        return result;
    }
    pub fn read(self: Context, target: *const abi.StorageTarget, relative_lba: u64, out: []u8) i32 {
        const sectors = sectorCount(out.len) orelse return abi.storage_error_invalid;
        return self.call("storage_read", .{ target, relative_lba, sectors, out.ptr, @as(u32, @intCast(out.len)) });
    }
    pub fn claimRead(self: Context, claim: u64, relative_lba: u64, out: []u8) i32 {
        const sectors = sectorCount(out.len) orelse return abi.storage_error_invalid;
        return self.call("storage_claim_read", .{ claim, relative_lba, sectors, out.ptr, @as(u32, @intCast(out.len)) });
    }
    pub fn claimWrite(self: Context, claim: u64, relative_lba: u64, bytes: []const u8) i32 {
        const sectors = sectorCount(bytes.len) orelse return abi.storage_error_invalid;
        return self.call("storage_claim_write", .{ claim, relative_lba, sectors, bytes.ptr, @as(u32, @intCast(bytes.len)) });
    }
    pub fn claimFlush(self: Context, claim: u64) i32 {
        return self.call("storage_claim_flush", .{claim});
    }
    pub fn rescan(self: Context, device_ref: *const abi.StorageDeviceRef) i32 {
        return self.call("storage_rescan", .{device_ref});
    }
    pub fn mount(self: Context, target: *const abi.StorageTarget, letter: u8, out: *abi.StorageVolumeRef) i32 {
        out.* = .{};
        return self.call("storage_mount", .{ target, @as(u32, letter), out });
    }
    pub fn unmount(self: Context, volume_ref: *const abi.StorageVolumeRef) i32 {
        return self.call("storage_unmount", .{volume_ref});
    }
    pub fn useBegin(self: Context, path: [*:0]const u8, out: *u64) i32 {
        out.* = 0;
        return self.call("storage_use_begin", .{ path, out });
    }
    pub fn useEnd(self: Context, use: *u64) i32 {
        if (use.* == 0) return abi.storage_result_ok;
        const result = self.call("storage_use_end", .{use.*});
        if (result == abi.storage_result_ok) use.* = 0;
        return result;
    }

    // Old kernels have neither exclusive raw maintenance nor volume leases.
    // Transfer services may retain that older behavior only when both slots
    // are absent. A partially available new contract always fails closed.
    pub fn transferUseBegin(self: Context, path: [*:0]const u8, out: *u64) i32 {
        if (!self.sys.hasFn("storage_use_begin") and !self.sys.hasFn("storage_claim_begin")) {
            out.* = 0;
            return abi.storage_result_ok;
        }
        return self.useBegin(path, out);
    }
};

fn sectorCount(bytes: usize) ?u32 {
    if (bytes == 0 or bytes % 512 != 0 or bytes > @as(usize, abi.storage_raw_max_sectors) * 512 or bytes > std.math.maxInt(u32)) return null;
    return @intCast(bytes / 512);
}
