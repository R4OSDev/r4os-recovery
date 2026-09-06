//! Room for another release download and an independent Recovery ZIP/PART
//! alongside the already installed two slots and original release ZIP.
const std = @import("std");
pub const metadata_reserve: u64 = 1024 * 1024;
pub fn requireCacheHeadroom(free: u64, release: u64, recovery: u64, cluster: u64) !void {
    if (cluster == 0 or cluster > 65536 or !std.math.isPowerOfTwo(cluster)) return error.Geometry;
    const system = (std.math.add(u64, release, cluster - 1) catch return error.NoSpace) / cluster * cluster;
    const independent = (std.math.add(u64, recovery, cluster - 1) catch return error.NoSpace) / cluster * cluster;
    const both = std.math.mul(u64, independent, 2) catch return error.NoSpace;
    const needed = std.math.add(u64, std.math.add(u64, system, both) catch return error.NoSpace, metadata_reserve) catch return error.NoSpace;
    if (free < needed) return error.RecoveryCapacity;
}
