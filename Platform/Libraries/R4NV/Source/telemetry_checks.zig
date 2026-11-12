const std = @import("std");
const t = std.testing;
const telemetry = @import("telemetry.zig");
const Reader = struct {
    bytes: [telemetry.page_bytes]u8 align(8) = @splat(0),
    loads: usize = 0,
    mutate: bool = false,
    bad_offset: ?usize = null,
    fn put32(self: *Reader, offset: usize, value: u32) void { std.mem.writeInt(u32, self.bytes[offset..][0..4], value, .little); }
    fn put64(self: *Reader, offset: usize, value: u64) void { std.mem.writeInt(u64, self.bytes[offset..][0..8], value, .little); }
    pub fn load64(self: *Reader, offset: usize) !u64 {
        self.loads += 1;
        if (self.bad_offset == offset) return error.Mapping;
        const value = std.mem.readInt(u64, self.bytes[offset..][0..8], .little);
        if (self.mutate) self.put64(offset, value + 1);
        return value;
    }
    pub fn load32(self: *Reader, offset: usize) !u32 { return std.mem.readInt(u32, self.bytes[offset..][0..4], .little); }
    pub fn barrier(_: *Reader) !void {}
};
pub fn run() !void {
    var reader: Reader = .{};
    var tracker: telemetry.Tracker = .{};
    try tracker.begin(&reader, telemetry.poll_mask, 1000);
    var frame = try tracker.sample(&reader, 1100, 500);
    try t.expect(frame.get(.clocks).status == .unavailable);
    // Hard-coded original-header witness offsets; distinct neighboring data
    // catches field drift rather than reproducing the implementation's map.
    reader.put64(72, 123);
    reader.put32(80, 210); reader.put32(84, 405); reader.put32(88, 555); reader.put32(92, 210);
    reader.put64(264, 123); reader.put32(272, 1 << 8);
    reader.put64(296, 123); reader.put32(304, @bitCast(@as(i32, -320)));
    reader.put64(312, 123); reader.put32(320, 19264);
    reader.put64(280, 123); reader.put32(288, 170000); reader.put32(292, 150000);
    reader.put64(368, 123); reader.put32(376, 12500); reader.put32(380, 18000); reader.put32(384, 900);
    frame = try tracker.sample(&reader, 1200, 500);
    try t.expectEqual([4]u64{ 210000000, 405000000, 555000000, 210000000 }, frame.get(.clocks).targetClocksHz().?);
    try t.expectEqual(@as(?u4, 8), frame.get(.pstate).pstateIndex());
    try t.expectEqual(@as(?i64, -1250), frame.get(.gpu_temperature).temperatureMilliCelsius());
    try t.expectEqual(@as(?i64, 75250), frame.get(.memory_temperature).temperatureMilliCelsius());
    try t.expect(frame.get(.power_limit).words[0] == 170000 and frame.get(.power_limit).words[1] == 150000);
    try t.expect(frame.get(.average_power).words[2] == 900);
    frame = try tracker.sample(&reader, 1500, 500);
    frame = try tracker.sample(&reader, 1800, 500);
    try t.expect(frame.get(.clocks).status == .stale and frame.get(.clocks).targetClocksHz() == null);
    try tracker.begin(&reader, 0, 1900);
    try tracker.begin(&reader, telemetry.poll_clock, 2000);
    frame = try tracker.sample(&reader, 2100, 500);
    try t.expect(frame.get(.clocks).status == .awaiting_change and frame.get(.pstate).status == .unavailable);
    reader.put64(72, 124);
    frame = try tracker.sample(&reader, 2200, 500);
    try t.expect(frame.get(.clocks).usable());
    reader.put64(72, 122);
    frame = try tracker.sample(&reader, 2300, 500);
    try t.expect(frame.get(.clocks).status == .malformed);
    const saved = tracker;
    try t.expectError(error.Clock, tracker.sample(&reader, 2200, 500));
    try t.expect(std.meta.eql(saved, tracker));
    reader.bad_offset = 72;
    try t.expectError(error.Mapping, tracker.sample(&reader, 2400, 500));
    try t.expect(std.meta.eql(saved, tracker));
    reader.bad_offset = null;
    reader.put64(72, std.math.maxInt(u64));
    var reading = try telemetry.read(&reader, .clocks);
    try t.expect(reading.status == .changing and reading.words[0] == 0);
    reader.put64(72, telemetry.sequence_start + 1);
    reading = try telemetry.read(&reader, .clocks);
    try t.expect(reading.status == .changing);
    reader.put64(72, telemetry.sequence_start + 2);
    reading = try telemetry.read(&reader, .clocks);
    try t.expect(reading.usable());
    reader.put64(72, 42); reader.mutate = true; reader.loads = 0;
    reading = try telemetry.read(&reader, .clocks);
    try t.expect(reading.status == .changing and reading.words[0] == 0 and reader.loads == 2 * telemetry.attempts);
    reader.mutate = false;
    reader.put64(264, 44); reader.put32(272, 3);
    reading = try telemetry.read(&reader, .pstate);
    try t.expect(reading.status == .malformed and reading.pstateIndex() == null);
    reader.put64(112, 55); reader.put32(120, 101);
    reading = try telemetry.read(&reader, .utilization);
    try t.expect(reading.status == .malformed);
    reader.put64(72, 500);
    frame = try tracker.sample(&reader, 2450, 500);
    try t.expect(frame.get(.clocks).status == .malformed);
    try tracker.begin(&reader, 0, 2500);
    try tracker.begin(&reader, telemetry.poll_clock, 2600);
    reader.put64(72, 501);
    frame = try tracker.sample(&reader, 5000, 500);
    try t.expect(frame.get(.clocks).status == .awaiting_change);
    reader.put64(72, 502);
    frame = try tracker.sample(&reader, 5100, 500);
    try t.expect(frame.get(.clocks).usable());
}
