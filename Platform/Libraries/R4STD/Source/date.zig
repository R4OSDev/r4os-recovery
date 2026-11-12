const std = @import("std");
const r4os = @import("r4os");
const abi = r4os.abi;

pub const seconds_per_day: i64 = 24 * 60 * 60;
const unix_epoch_ordinal: i64 = 719162;

pub const Date = extern struct {
    year: u16 = 1970,
    month: u8 = 1,
    day: u8 = 1,
};

pub const TimeOfDay = extern struct {
    hour: u8 = 0,
    minute: u8 = 0,
    second: u8 = 0,
};

pub const DateTime = extern struct {
    date: Date = .{},
    time: TimeOfDay = .{},
};

pub const Weekday = enum(u8) {
    sunday = 0,
    monday = 1,
    tuesday = 2,
    wednesday = 3,
    thursday = 4,
    friday = 5,
    saturday = 6,
};

pub const ShiftedDateTime = struct {
    value: DateTime,
    day_delta: i32,
};

pub const FatDateTime = struct {
    date: u16,
    time: u16,
};

pub fn isLeapYear(year: u16) bool {
    return (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0);
}

pub fn daysInMonth(year: u16, month: u8) u8 {
    return switch (month) {
        1, 3, 5, 7, 8, 10, 12 => 31,
        4, 6, 9, 11 => 30,
        2 => if (isLeapYear(year)) 29 else 28,
        else => 0,
    };
}

pub fn validDateValue(year: u16, month: u8, day: u8) bool {
    if (year < 1 or year > 9999) return false;
    if (month < 1 or month > 12) return false;
    return day >= 1 and day <= daysInMonth(year, month);
}

pub fn validDate(date: Date) bool {
    return validDateValue(date.year, date.month, date.day);
}

pub fn validTimeValue(hour: u8, minute: u8, second: u8) bool {
    return hour < 24 and minute < 60 and second < 60;
}

pub fn validTime(time: TimeOfDay) bool {
    return validTimeValue(time.hour, time.minute, time.second);
}

pub fn validDateTime(value: DateTime) bool {
    return validDate(value.date) and validTime(value.time);
}

pub fn ordinal(date: Date) ?i64 {
    if (!validDate(date)) return null;
    var total = daysBeforeYear(date.year);
    var month: u8 = 1;
    while (month < date.month) : (month += 1) total += daysInMonth(date.year, month);
    total += date.day - 1;
    return total;
}

pub fn fromOrdinal(value: i64) ?Date {
    if (value < 0 or value > ordinalMax()) return null;

    var lo: u16 = 1;
    var hi: u16 = 9999;
    while (lo < hi) {
        const mid: u16 = lo + @as(u16, @intCast((@as(u32, hi) - lo) / 2));
        if (daysBeforeYear(mid + 1) <= value) {
            lo = mid + 1;
        } else {
            hi = mid;
        }
    }

    const year = lo;
    var day_of_year: i64 = value - daysBeforeYear(year);
    var month: u8 = 1;
    while (month <= 12) : (month += 1) {
        const month_days: i64 = daysInMonth(year, month);
        if (day_of_year < month_days) {
            return .{ .year = year, .month = month, .day = @intCast(day_of_year + 1) };
        }
        day_of_year -= month_days;
    }
    return null;
}

pub fn addDays(date: Date, delta: i32) ?Date {
    const base = ordinal(date) orelse return null;
    return fromOrdinal(base + delta);
}

pub fn compareDate(a: Date, b: Date) i32 {
    if (a.year != b.year) return if (a.year < b.year) -1 else 1;
    if (a.month != b.month) return if (a.month < b.month) -1 else 1;
    if (a.day != b.day) return if (a.day < b.day) -1 else 1;
    return 0;
}

pub fn compareDateTime(a: DateTime, b: DateTime) i32 {
    const date_cmp = compareDate(a.date, b.date);
    if (date_cmp != 0) return date_cmp;
    const a_seconds = secondsSinceMidnight(a.time);
    const b_seconds = secondsSinceMidnight(b.time);
    if (a_seconds == b_seconds) return 0;
    return if (a_seconds < b_seconds) -1 else 1;
}

pub fn weekday(date: Date) ?Weekday {
    const day_index = ordinal(date) orelse return null;
    return @enumFromInt(@as(u8, @intCast(@mod(day_index + 1, 7))));
}

pub fn weekdayNumber(year: u16, month: u8, day: u8) u8 {
    const value = weekday(.{ .year = year, .month = month, .day = day }) orelse return 0;
    return @intFromEnum(value);
}

pub fn secondsSinceMidnight(time: TimeOfDay) u32 {
    return @as(u32, time.hour) * 3600 + @as(u32, time.minute) * 60 + time.second;
}

pub fn timeFromSeconds(seconds: u32) TimeOfDay {
    const day_seconds = seconds % @as(u32, @intCast(seconds_per_day));
    return .{
        .hour = @intCast((day_seconds / 3600) % 24),
        .minute = @intCast((day_seconds / 60) % 60),
        .second = @intCast(day_seconds % 60),
    };
}

pub fn shiftSeconds(value: DateTime, delta_seconds: i64) ?ShiftedDateTime {
    if (!validDateTime(value)) return null;
    const base_ordinal = ordinal(value.date).?;
    const seconds = @as(i64, secondsSinceMidnight(value.time)) + delta_seconds;
    const day_delta = @divFloor(seconds, seconds_per_day);
    const day_seconds = @mod(seconds, seconds_per_day);
    const shifted_date = fromOrdinal(base_ordinal + day_delta) orelse return null;
    return .{
        .value = .{
            .date = shifted_date,
            .time = timeFromSeconds(@intCast(day_seconds)),
        },
        .day_delta = @intCast(day_delta),
    };
}

pub fn shiftMinutes(value: DateTime, delta_minutes: i32) ?ShiftedDateTime {
    return shiftSeconds(value, @as(i64, delta_minutes) * 60);
}

pub fn fromTimeState(state: abi.TimeState) ?DateTime {
    const value = DateTime{
        .date = .{ .year = state.year, .month = state.month, .day = state.day },
        .time = .{ .hour = state.hour, .minute = state.minute, .second = state.second },
    };
    return if (validDateTime(value)) value else null;
}

pub fn toTimeState(value: DateTime) ?abi.TimeState {
    if (!validDateTime(value)) return null;
    const dow = weekday(value.date) orelse return null;
    return .{
        .valid = 1,
        .century_source = 0,
        .weekday = @intFromEnum(dow),
        .year = value.date.year,
        .month = value.date.month,
        .day = value.date.day,
        .hour = value.time.hour,
        .minute = value.time.minute,
        .second = value.time.second,
        .seconds_since_midnight = secondsSinceMidnight(value.time),
    };
}

pub fn utcFromDateTime(value: DateTime, nanosecond: u32) ?abi.R4UtcTime {
    if (!validDateTime(value) or nanosecond >= abi.nanoseconds_per_second) return null;
    const day = ordinal(value.date) orelse return null;
    const seconds = (day - unix_epoch_ordinal) * seconds_per_day + secondsSinceMidnight(value.time);
    return .{ .seconds_since_unix_epoch = seconds, .nanosecond = nanosecond };
}

pub fn dateTimeFromUtc(value: abi.R4UtcTime) ?DateTime {
    if (value.nanosecond >= abi.nanoseconds_per_second) return null;
    const day_delta = @divFloor(value.seconds_since_unix_epoch, seconds_per_day);
    const seconds = @mod(value.seconds_since_unix_epoch, seconds_per_day);
    const parsed_date = fromOrdinal(unix_epoch_ordinal + day_delta) orelse return null;
    return .{ .date = parsed_date, .time = timeFromSeconds(@intCast(seconds)) };
}

pub fn formatDateIso(out: []u8, date: Date) []const u8 {
    if (out.len < 11 or !validDate(date)) return out[0..0];
    write4(out[0..4], date.year);
    out[4] = '-';
    write2(out[5..7], date.month);
    out[7] = '-';
    write2(out[8..10], date.day);
    out[10] = 0;
    return out[0..10];
}

pub fn formatTime24(out: []u8, time: TimeOfDay) []const u8 {
    if (out.len < 9 or !validTime(time)) return out[0..0];
    write2(out[0..2], time.hour);
    out[2] = ':';
    write2(out[3..5], time.minute);
    out[5] = ':';
    write2(out[6..8], time.second);
    out[8] = 0;
    return out[0..8];
}

pub fn formatTime12(out: []u8, time: TimeOfDay) []const u8 {
    if (out.len < 12 or !validTime(time)) return out[0..0];
    var hour = time.hour % 12;
    if (hour == 0) hour = 12;
    write2(out[0..2], hour);
    out[2] = ':';
    write2(out[3..5], time.minute);
    out[5] = ':';
    write2(out[6..8], time.second);
    out[8] = ' ';
    out[9] = if (time.hour < 12) 'A' else 'P';
    out[10] = 'M';
    out[11] = 0;
    return out[0..11];
}

pub fn formatTimeDisplay(out: []u8, time: TimeOfDay, clock_format: u32) []const u8 {
    return if (clock_format == abi.clock_format_12h) formatTime12(out, time) else formatTime24(out, time);
}

pub fn formatHourMinute24(out: []u8, time: TimeOfDay) []const u8 {
    if (out.len < 6 or !validTime(time)) return out[0..0];
    write2(out[0..2], time.hour);
    out[2] = ':';
    write2(out[3..5], time.minute);
    out[5] = 0;
    return out[0..5];
}

pub fn formatHourMinute12(out: []u8, time: TimeOfDay) []const u8 {
    if (out.len < 9 or !validTime(time)) return out[0..0];
    var hour = time.hour % 12;
    if (hour == 0) hour = 12;
    write2(out[0..2], hour);
    out[2] = ':';
    write2(out[3..5], time.minute);
    out[5] = ' ';
    out[6] = if (time.hour < 12) 'A' else 'P';
    out[7] = 'M';
    out[8] = 0;
    return out[0..8];
}

pub fn formatHourMinuteDisplay(out: []u8, time: TimeOfDay, clock_format: u32) []const u8 {
    return if (clock_format == abi.clock_format_12h) formatHourMinute12(out, time) else formatHourMinute24(out, time);
}

pub fn formatDateTimeIso(out: []u8, value: DateTime) []const u8 {
    if (out.len < 20 or !validDateTime(value)) return out[0..0];
    _ = formatDateIso(out[0..11], value.date);
    out[10] = ' ';
    _ = formatTime24(out[11..20], value.time);
    out[19] = 0;
    return out[0..19];
}

pub fn formatDateTimeMinuteDisplay(out: []u8, value: DateTime, clock_format: u32) []const u8 {
    if (!validDateTime(value)) return out[0..0];
    if (clock_format == abi.clock_format_12h) {
        if (out.len < 20) return out[0..0];
        _ = formatDateIso(out[0..11], value.date);
        out[10] = ' ';
        _ = formatHourMinute12(out[11..20], value.time);
        out[19] = 0;
        return out[0..19];
    }
    if (out.len < 17) return out[0..0];
    _ = formatDateIso(out[0..11], value.date);
    out[10] = ' ';
    _ = formatHourMinute24(out[11..17], value.time);
    out[16] = 0;
    return out[0..16];
}

pub fn decodeFatDate(raw: u16) ?Date {
    const value = Date{
        .year = 1980 + @as(u16, @intCast((raw >> 9) & 0x7F)),
        .month = @intCast((raw >> 5) & 0x0F),
        .day = @intCast(raw & 0x1F),
    };
    return if (validDate(value)) value else null;
}

pub fn decodeFatTime(raw: u16) ?TimeOfDay {
    const value = TimeOfDay{
        .hour = @intCast((raw >> 11) & 0x1F),
        .minute = @intCast((raw >> 5) & 0x3F),
        .second = @intCast((raw & 0x1F) * 2),
    };
    return if (validTime(value)) value else null;
}

pub fn decodeFatDateTime(date_raw: u16, time_raw: u16) ?DateTime {
    return .{
        .date = decodeFatDate(date_raw) orelse return null,
        .time = decodeFatTime(time_raw) orelse return null,
    };
}

pub fn encodeFatDate(value: Date) ?u16 {
    if (!validDate(value) or value.year < 1980 or value.year > 2107) return null;
    return ((value.year - 1980) << 9) | (@as(u16, value.month) << 5) | value.day;
}

pub fn encodeFatTime(value: TimeOfDay) ?u16 {
    if (!validTime(value)) return null;
    return (@as(u16, value.hour) << 11) | (@as(u16, value.minute) << 5) | (value.second / 2);
}

pub fn encodeFatDateTime(value: DateTime) ?FatDateTime {
    return .{
        .date = encodeFatDate(value.date) orelse return null,
        .time = encodeFatTime(value.time) orelse return null,
    };
}

pub fn parseDateIso(value: []const u8) ?Date {
    if (value.len != 10 or value[4] != '-' or value[7] != '-') return null;
    const year = parseFixedU16(value[0..4]) orelse return null;
    const month = parseFixedU8(value[5..7]) orelse return null;
    const day = parseFixedU8(value[8..10]) orelse return null;
    const out = Date{ .year = year, .month = month, .day = day };
    return if (validDate(out)) out else null;
}

pub fn parseTime24(value: []const u8) ?TimeOfDay {
    if (value.len != 8 or value[2] != ':' or value[5] != ':') return null;
    const hour = parseFixedU8(value[0..2]) orelse return null;
    const minute = parseFixedU8(value[3..5]) orelse return null;
    const second = parseFixedU8(value[6..8]) orelse return null;
    const out = TimeOfDay{ .hour = hour, .minute = minute, .second = second };
    return if (validTime(out)) out else null;
}

pub fn parseDateTimeIso(value: []const u8) ?DateTime {
    if (value.len != 19 or value[10] != ' ') return null;
    const parsed_date = parseDateIso(value[0..10]) orelse return null;
    const parsed_time = parseTime24(value[11..19]) orelse return null;
    return .{ .date = parsed_date, .time = parsed_time };
}

fn daysBeforeYear(year: u16) i64 {
    const y: i64 = @intCast(year - 1);
    return y * 365 + @divTrunc(y, 4) - @divTrunc(y, 100) + @divTrunc(y, 400);
}

fn ordinalMax() i64 {
    return daysBeforeYear(10000) - 1;
}

fn parseFixedU16(value: []const u8) ?u16 {
    var out: u16 = 0;
    for (value) |ch| {
        if (ch < '0' or ch > '9') return null;
        out = out * 10 + @as(u16, ch - '0');
    }
    return out;
}

fn parseFixedU8(value: []const u8) ?u8 {
    const parsed = parseFixedU16(value) orelse return null;
    if (parsed > std.math.maxInt(u8)) return null;
    return @intCast(parsed);
}

fn write4(out: []u8, value: u16) void {
    out[0] = digit(@intCast(value / 1000));
    out[1] = digit(@intCast((value / 100) % 10));
    out[2] = digit(@intCast((value / 10) % 10));
    out[3] = digit(@intCast(value % 10));
}

fn write2(out: []u8, value: u8) void {
    out[0] = digit(value / 10);
    out[1] = digit(value % 10);
}

fn digit(value: u8) u8 {
    return '0' + value % 10;
}

test "date validation handles leap years and month lengths" {
    try std.testing.expect(!isLeapYear(1900));
    try std.testing.expect(isLeapYear(2000));
    try std.testing.expect(!isLeapYear(2100));
    try std.testing.expectEqual(@as(u8, 29), daysInMonth(2000, 2));
    try std.testing.expectEqual(@as(u8, 28), daysInMonth(2100, 2));
    try std.testing.expect(validDate(.{ .year = 2026, .month = 2, .day = 28 }));
    try std.testing.expect(!validDate(.{ .year = 2026, .month = 2, .day = 29 }));
    try std.testing.expect(!validDate(.{ .year = 2026, .month = 13, .day = 1 }));
    try std.testing.expect(!validDate(.{ .year = 2026, .month = 1, .day = 0 }));
}

test "known weekdays use sunday zero convention" {
    try std.testing.expectEqual(Weekday.thursday, weekday(.{ .year = 1970, .month = 1, .day = 1 }).?);
    try std.testing.expectEqual(Weekday.wednesday, weekday(.{ .year = 2026, .month = 6, .day = 3 }).?);
    try std.testing.expectEqual(@as(u8, 0), weekdayNumber(2026, 6, 7));
}

test "day arithmetic crosses month and year boundaries" {
    try std.testing.expectEqual(Date{ .year = 2026, .month = 3, .day = 1 }, addDays(.{ .year = 2026, .month = 2, .day = 28 }, 1).?);
    try std.testing.expectEqual(Date{ .year = 2025, .month = 12, .day = 31 }, addDays(.{ .year = 2026, .month = 1, .day = 1 }, -1).?);
    try std.testing.expectEqual(Date{ .year = 2000, .month = 2, .day = 29 }, addDays(.{ .year = 2000, .month = 3, .day = 1 }, -1).?);
}

test "formatting and parsing use canonical ISO forms" {
    var date_buf: [11]u8 = .{0} ** 11;
    var time_buf: [12]u8 = .{0} ** 12;
    var dt_buf: [20]u8 = .{0} ** 20;
    try std.testing.expectEqualStrings("2026-06-03", formatDateIso(date_buf[0..], .{ .year = 2026, .month = 6, .day = 3 }));
    try std.testing.expectEqualStrings("07:05:09", formatTime24(time_buf[0..], .{ .hour = 7, .minute = 5, .second = 9 }));
    try std.testing.expectEqualStrings("07:05:09 AM", formatTime12(time_buf[0..], .{ .hour = 7, .minute = 5, .second = 9 }));
    try std.testing.expectEqualStrings("2026-06-03 07:05:09", formatDateTimeIso(dt_buf[0..], .{ .date = .{ .year = 2026, .month = 6, .day = 3 }, .time = .{ .hour = 7, .minute = 5, .second = 9 } }));
    try std.testing.expectEqual(Date{ .year = 2026, .month = 6, .day = 3 }, parseDateIso("2026-06-03").?);
    try std.testing.expect(parseDateIso("2026-02-29") == null);
    try std.testing.expect(parseDateIso("2026-13-01") == null);
    try std.testing.expect(parseDateIso("2026-01-00") == null);
    try std.testing.expect(parseTime24("24:00:00") == null);
}

test "fat timestamp helpers validate and format through date core" {
    const value = DateTime{ .date = .{ .year = 2026, .month = 6, .day = 3 }, .time = .{ .hour = 7, .minute = 5, .second = 9 } };
    const encoded = encodeFatDateTime(value).?;
    try std.testing.expectEqual(@as(u16, 0x5CC3), encoded.date);
    try std.testing.expectEqual(@as(u16, 0x38A4), encoded.time);

    const decoded = decodeFatDateTime(encoded.date, encoded.time).?;
    try std.testing.expectEqual(Date{ .year = 2026, .month = 6, .day = 3 }, decoded.date);
    try std.testing.expectEqual(TimeOfDay{ .hour = 7, .minute = 5, .second = 8 }, decoded.time);

    var compact: [20]u8 = .{0} ** 20;
    try std.testing.expectEqualStrings("2026-06-03 07:05", formatDateTimeMinuteDisplay(compact[0..], decoded, abi.clock_format_24h));
    try std.testing.expectEqualStrings("2026-06-03 07:05 AM", formatDateTimeMinuteDisplay(compact[0..], decoded, abi.clock_format_12h));

    try std.testing.expect(decodeFatDateTime(0, 0) == null);
    try std.testing.expect(decodeFatDateTime(0x5C5F, encoded.time) == null);
    try std.testing.expect(encodeFatDate(.{ .year = 1979, .month = 12, .day = 31 }) == null);
    try std.testing.expect(encodeFatDate(.{ .year = 2108, .month = 1, .day = 1 }) == null);
}

test "time shifts carry local date across midnight" {
    const base = DateTime{ .date = .{ .year = 2026, .month = 1, .day = 1 }, .time = .{ .hour = 0, .minute = 30, .second = 0 } };
    const west = shiftMinutes(base, -60).?;
    try std.testing.expectEqual(Date{ .year = 2025, .month = 12, .day = 31 }, west.value.date);
    try std.testing.expectEqual(@as(i32, -1), west.day_delta);
    try std.testing.expectEqual(TimeOfDay{ .hour = 23, .minute = 30, .second = 0 }, west.value.time);
    const east = shiftMinutes(base, 14 * 60).?;
    try std.testing.expectEqual(Date{ .year = 2026, .month = 1, .day = 1 }, east.value.date);
    try std.testing.expectEqual(TimeOfDay{ .hour = 14, .minute = 30, .second = 0 }, east.value.time);
}

test "UTC uses Unix epoch seconds and keeps nanosecond fraction separate" {
    const epoch = DateTime{ .date = .{ .year = 1970, .month = 1, .day = 1 }, .time = .{} };
    const encoded = utcFromDateTime(epoch, 123_456_789).?;
    try std.testing.expectEqual(@as(i64, 0), encoded.seconds_since_unix_epoch);
    try std.testing.expectEqual(@as(u32, 123_456_789), encoded.nanosecond);
    try std.testing.expectEqualDeep(epoch, dateTimeFromUtc(encoded).?);

    const before = dateTimeFromUtc(.{ .seconds_since_unix_epoch = -1 }).?;
    try std.testing.expectEqualDeep(DateTime{
        .date = .{ .year = 1969, .month = 12, .day = 31 },
        .time = .{ .hour = 23, .minute = 59, .second = 59 },
    }, before);
    try std.testing.expect(utcFromDateTime(epoch, @intCast(abi.nanoseconds_per_second)) == null);
}
