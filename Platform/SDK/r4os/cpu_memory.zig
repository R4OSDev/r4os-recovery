//! Large non-backward copies with an optional ERMS performance hint. REP MOVSB
//! is baseline x86_64; a stale hint cannot enable an unsupported instruction.
const std = @import("std");
const builtin = @import("builtin");
const abi = @import("r4os_contract").abi;
pub const Policy = struct {
    erms: bool = false,
    pub fn fromInfo(info: *const abi.CpuAccelerationInfo) Policy {
        return .{ .erms = info.version == 1 and info.size >= @sizeOf(abi.CpuAccelerationInfo) and
            info.flags & abi.cpu_accel_info_flag_common_complete != 0 and
            info.configured_cpus != 0 and info.common_known_count == info.configured_cpus and
            info.common_hardware_mask & abi.cpu_accel_feature_erms != 0 };
    }
    pub fn move(self: Policy, destination: []u8, source: []const u8) void {
        std.debug.assert(destination.len == source.len);
        if (source.len == 0 or destination.ptr == source.ptr) return;
        const backwards = @intFromPtr(destination.ptr) > @intFromPtr(source.ptr) and
            @intFromPtr(destination.ptr) - @intFromPtr(source.ptr) < source.len;
        if (!@inComptime() and builtin.cpu.arch == .x86_64 and self.erms and source.len >= 256 and !backwards) {
            repMove(destination.ptr, source.ptr, source.len);
        } else if (backwards) {
            std.mem.copyBackwards(u8, destination, source);
        } else {
            std.mem.copyForwards(u8, destination, source);
        }
    }
};
// Forward overlap is valid. Never sets DF, reads outside the source, prefetches
// the next page, flushes caches, or admits short REP solely on FSRM.
noinline fn repMove(dst: [*]u8, src: [*]const u8, count: usize) void {
    var end_dst: usize = undefined;
    var end_src: usize = undefined;
    var remaining: usize = undefined;
    asm volatile ("rep movsb"
        : [dst] "={rdi}" (end_dst),
          [src] "={rsi}" (end_src),
          [count] "={rcx}" (remaining),
        : [_] "0" (dst),
          [_] "1" (src),
          [_] "2" (count),
        : .{ .memory = true });
}
