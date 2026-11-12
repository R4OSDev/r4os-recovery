// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Private native C calendar adapter. R4OS wall time is UTC; calendar arithmetic
// belongs to R4STD. No host timezone, locale state or shared tm scratch buffer.
const std = @import("std");
const date = @import("r4native_date");
pub const Tm = extern struct {
    second: c_int = 0,
    minute: c_int = 0,
    hour: c_int = 0,
    day: c_int = 1,
    month: c_int = 0,
    year: c_int = 70,
    weekday: c_int = 0,
    yearday: c_int = 0,
    daylight: c_int = 0,
};

pub fn fromSeconds(seconds: i64) ?Tm {
    const value = date.dateTimeFromUtc(.{ .seconds_since_unix_epoch = seconds, .nanosecond = 0 }) orelse return null;
    const ordinal = date.ordinal(value.date).?;
    const january = date.ordinal(.{ .year = value.date.year, .month = 1, .day = 1 }).?;
    return .{ .second = value.time.second, .minute = value.time.minute, .hour = value.time.hour, .day = value.date.day, .month = @as(c_int, value.date.month) - 1, .year = @as(c_int, value.date.year) - 1900, .weekday = @intFromEnum(date.weekday(value.date).?), .yearday = @intCast(ordinal - january) };
}
pub fn normalize(value: Tm) ?struct { seconds: i64, calendar: Tm } {
    const year = @as(i64, value.year) + 1900 + @divFloor(value.month, 12);
    if (year < 1 or year > 9999) return null;
    const first = date.utcFromDateTime(.{ .date = .{ .year = @intCast(year), .month = @intCast(@mod(value.month, 12) + 1), .day = 1 }, .time = .{} }, 0).?;
    const seconds = first.seconds_since_unix_epoch + (@as(i64, value.day) - 1) * date.seconds_per_day +
        @as(i64, value.hour) * 3600 + @as(i64, value.minute) * 60 + value.second;
    return .{ .seconds = seconds, .calendar = fromSeconds(seconds) orelse return null };
}
pub export fn gmtime_r(seconds: *const i64, output: *Tm) callconv(.c) ?*Tm {
    const candidate = fromSeconds(seconds.*) orelse return null;
    output.* = candidate;
    return output;
}
pub export fn localtime_r(seconds: *const i64, output: *Tm) callconv(.c) ?*Tm {
    return gmtime_r(seconds, output);
}
pub export fn mktime(value: *Tm) callconv(.c) i64 {
    const result = normalize(value.*) orelse return -1;
    value.* = result.calendar;
    return result.seconds;
}
// The native decoder uses numeric UTC log formats only. This deliberately
// bounded formatter rejects unsupported locale/week directives with zero.
// It is a private dependency surface, not a public general-purpose libc API.
pub export fn strftime(output: [*]u8, capacity: usize, format: [*:0]const u8, value: *const Tm) callconv(.c) usize {
    if (capacity == 0) return 0;
    output[0] = 0;
    const normalized = normalize(value.*) orelse return 0;
    const calendar = normalized.calendar;
    var used: usize = 0;
    var at: usize = 0;
    var temporary: [32]u8 = undefined;
    while (format[at] != 0) : (at += 1) {
        var byte = format[at];
        var part: []const u8 = undefined;
        if (byte != '%') {
            temporary[0] = byte;
            part = temporary[0..1];
        } else {
            at += 1;
            byte = format[at];
            part = switch (byte) {
                '%' => "%",
                'n' => "\n",
                't' => "\t",
                'z' => "+0000",
                'Z' => "UTC",
                'Y' => std.fmt.bufPrint(&temporary, "{d:0>4}", .{@as(u32, @intCast(calendar.year + 1900))}) catch return 0,
                'y' => std.fmt.bufPrint(&temporary, "{d:0>2}", .{@as(u32, @intCast(@mod(calendar.year + 1900, 100)))}) catch return 0,
                'm' => std.fmt.bufPrint(&temporary, "{d:0>2}", .{@as(u32, @intCast(calendar.month + 1))}) catch return 0,
                'd' => std.fmt.bufPrint(&temporary, "{d:0>2}", .{@as(u32, @intCast(calendar.day))}) catch return 0,
                'H' => std.fmt.bufPrint(&temporary, "{d:0>2}", .{@as(u32, @intCast(calendar.hour))}) catch return 0,
                'M' => std.fmt.bufPrint(&temporary, "{d:0>2}", .{@as(u32, @intCast(calendar.minute))}) catch return 0,
                'S' => std.fmt.bufPrint(&temporary, "{d:0>2}", .{@as(u32, @intCast(calendar.second))}) catch return 0,
                'j' => std.fmt.bufPrint(&temporary, "{d:0>3}", .{@as(u32, @intCast(calendar.yearday + 1))}) catch return 0,
                else => return 0,
            };
        }
        if (part.len >= capacity - used) return 0;
        @memcpy(output[used..][0..part.len], part);
        used += part.len;
    }
    output[used] = 0;
    return used;
}
