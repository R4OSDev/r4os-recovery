// Actual physical RAM, retained across loss of the source disk. The normal
// allocator is lazy; successful allocation here means every page is resident
// and pinned. All kernel calls and UI checkpoints have a bounded batch size.
const std = @import("std");
const r4os = @import("r4os");
const abi = r4os.abi;
pub const Pump = struct {
    context: ?*anyopaque = null,
    function: ?*const fn (?*anyopaque, []const u8, u64, u64) bool = null,
    pub fn run(self: Pump, phase: []const u8, done: u64, total: u64) error{Cancelled}!void {
        if (self.function) |f| if (!f(self.context, phase, done, total)) return error.Cancelled;
    }
};
const Region = struct { id: u32 = 0, base: usize = 0, bytes: u64 = 0 };
pub const Pool = struct {
    sys: *const r4os.r4sys.Context,
    pump: Pump = .{},
    regions: [64]Region = .{Region{}} ** 64,
    current: u64 = 0,
    peak: u64 = 0,
    last_error: i32 = 0,
    cancelled: bool = false,

    pub fn allocator(self: *Pool) std.mem.Allocator {
        return .{ .ptr = self, .vtable = &.{ .alloc = alloc, .resize = resize, .remap = remap, .free = free } };
    }
    fn alloc(raw: *anyopaque, len: usize, alignment: std.mem.Alignment, _: usize) ?[*]u8 {
        const self: *Pool = @ptrCast(@alignCast(raw));
        if (self.cancelled or len == 0 or len > 8 * 1024 * 1024 * 1024) return null;
        const bytes = std.mem.alignForward(u64, len, 4096);
        const slot = for (&self.regions) |*region| {
            if (region.id == 0) break region;
        } else return null;
        var info = abi.ProgramVmRegionInfo{};
        self.last_error = self.sys.vmReserveRaw(bytes, @max(4096, alignment.toByteUnits()), abi.vm_region_flags_default, &info);
        if (self.last_error != abi.vm_ok) return null;
        slot.* = .{ .id = info.id, .base = @intCast(info.base), .bytes = 0 };
        var offset: u64 = 0;
        while (offset < bytes) {
            const amount = @min(bytes - offset, abi.vm_commit_resident_max_bytes);
            self.last_error = self.sys.vmCommitFlags(info.id, offset, amount, abi.vm_commit_flag_resident);
            if (self.last_error != abi.vm_ok) {
                // A failed kernel rollback can retain pages. Query accounts
                // for those too; release never frees unacknowledged mappings.
                if (self.sys.vmQuery(info.id)) |after| slot.bytes = after.committed_bytes;
                self.current += slot.bytes;
                self.peak = @max(self.peak, self.current);
                _ = self.release(slot);
                return null;
            }
            offset += amount;
            slot.bytes = offset;
            self.peak = @max(self.peak, self.current + offset);
            self.pump.run("Reserving physical RAM", offset, bytes) catch {
                self.cancelled = true;
                self.current += slot.bytes;
                _ = self.release(slot);
                return null;
            };
        }
        self.current += bytes;
        self.peak = @max(self.peak, self.current);
        return @ptrFromInt(info.base);
    }
    fn resize(_: *anyopaque, _: []u8, _: std.mem.Alignment, _: usize, _: usize) bool {
        return false;
    }
    fn remap(_: *anyopaque, _: []u8, _: std.mem.Alignment, _: usize, _: usize) ?[*]u8 {
        return null;
    }
    fn free(raw: *anyopaque, memory: []u8, _: std.mem.Alignment, _: usize) void {
        const self: *Pool = @ptrCast(@alignCast(raw));
        for (&self.regions) |*region| if (region.id != 0 and region.base == @intFromPtr(memory.ptr)) {
            _ = self.release(region);
            return;
        };
    }
    fn release(self: *Pool, region: *Region) bool {
        const held = region.bytes;
        var offset: u64 = 0;
        while (offset < held) {
            const amount = @min(held - offset, abi.vm_commit_resident_max_bytes);
            if (self.sys.vmDecommit(region.id, offset, amount) != abi.vm_ok) break;
            offset += amount;
            // Cancellation does not interrupt cleanup.
            self.pump.run("Releasing temporary RAM", offset, held) catch {};
        }
        if (self.sys.vmRelease(region.id) != abi.vm_ok) return false;
        self.current -|= held;
        region.* = .{};
        return true;
    }
    pub fn deinit(self: *Pool) bool {
        var ok = true;
        for (&self.regions) |*region| if (region.id != 0) {
            ok = self.release(region) and ok;
        };
        return ok;
    }
};
