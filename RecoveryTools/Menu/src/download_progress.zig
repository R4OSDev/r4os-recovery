const std = @import("std");

const kib: u64 = 1024;
const mib: u64 = kib * kib;

pub const Meter = struct {
    sample_tick: u64 = 0,
    sample_bytes: u64 = 0,
    bytes_per_second: u64 = 0,

    pub fn reset(self: *Meter, now: u64, downloaded: u64) void {
        self.* = .{ .sample_tick = now, .sample_bytes = downloaded };
    }

    pub fn update(self: *Meter, now: u64, downloaded: u64, ticks_per_second: u32) u64 {
        const elapsed = now -| self.sample_tick;
        if (elapsed == 0 or ticks_per_second == 0) return self.bytes_per_second;
        const delta = downloaded -| self.sample_bytes;
        const measured: u128 = @as(u128, delta) * ticks_per_second / elapsed;
        const rate: u64 = @intCast(@min(measured, std.math.maxInt(u64)));
        if (elapsed >= @max(1, ticks_per_second / 2)) {
            self.sample_tick = now;
            self.sample_bytes = downloaded;
            self.bytes_per_second = rate;
        } else if (self.bytes_per_second == 0) {
            self.bytes_per_second = rate;
        }
        return self.bytes_per_second;
    }
};

fn size(buffer: []u8, bytes: u64, speed: bool) []const u8 {
    const unit: u64 = if (bytes >= mib) mib else if (bytes >= kib or speed) kib else 1;
    const name = if (unit == mib) "MB" else if (unit == kib) "KB" else "B";
    if (unit == 1) return std.fmt.bufPrint(buffer, "{d} {s}", .{ bytes, name }) catch unreachable;
    const tenths: u128 = (@as(u128, bytes) * 10 + unit / 2) / unit;
    return std.fmt.bufPrint(buffer, "{d}.{d} {s}", .{ tenths / 10, tenths % 10, name }) catch unreachable;
}

pub fn format(buffer: []u8, downloaded: u64, total: u64, bytes_per_second: u64, retry: u8) []const u8 {
    var loaded_buffer: [40]u8 = undefined;
    var total_buffer: [40]u8 = undefined;
    var rate_buffer: [40]u8 = undefined;
    const loaded = size(&loaded_buffer, downloaded, false);
    const expected = size(&total_buffer, total, false);
    const rate = size(&rate_buffer, bytes_per_second, true);
    const percent: u64 = if (total == 0) 0 else @intCast(@min(@as(u128, 100), @as(u128, @min(downloaded, total)) * 100 / total));
    if (retry != 0) return std.fmt.bufPrint(buffer, "Retry {d}/3 | Loaded {s} / {s} | {d}% | {s}/s", .{ retry, loaded, expected, percent, rate }) catch unreachable;
    return std.fmt.bufPrint(buffer, "Loaded {s} / {s} | {d}% | {s}/s", .{ loaded, expected, percent, rate }) catch unreachable;
}

test "progress displays binary units, percentage and speed" {
    var buffer: [160]u8 = undefined;
    try std.testing.expectEqualStrings("Loaded 1.5 MB / 3.0 MB | 50% | 768.0 KB/s", format(&buffer, mib + mib / 2, mib * 3, kib * 768, 0));
    try std.testing.expectEqualStrings("Retry 2/3 | Loaded 3.0 MB / 3.0 MB | 100% | 1.5 MB/s", format(&buffer, mib * 3, mib * 3, mib + mib / 2, 2));
}

test "meter resets speed after an interruption and measures only new bytes" {
    var meter = Meter{};
    meter.reset(1000, 0);
    try std.testing.expectEqual(@as(u64, 512 * kib), meter.update(1500, 256 * kib, 1000));
    meter.reset(2000, 256 * kib);
    try std.testing.expectEqual(@as(u64, 0), meter.bytes_per_second);
    try std.testing.expectEqual(@as(u64, 256 * kib), meter.update(3000, 512 * kib, 1000));
}
