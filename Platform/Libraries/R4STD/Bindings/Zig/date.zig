const std = @import("std");
const r4os = @import("r4os");
const runtime = @import("runtime.zig");
const abi = runtime.abi;

pub const seconds_per_day: i64 = 24 * 60 * 60;

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

pub fn daysInMonth(year: u16, month: u8) u8 {
    if (!runtime.hasDate()) return 0;
    return runtime.date().days_in_month(year, month);
}

pub fn validDateValue(year: u16, month: u8, day: u8) bool {
    if (!runtime.hasDate()) return false;
    return runtime.date().valid_date(year, month, day) != 0;
}

pub fn validDate(value: Date) bool {
    return validDateValue(value.year, value.month, value.day);
}

pub fn validDateTime(value: DateTime) bool {
    return validDate(value.date) and value.time.hour < 24 and value.time.minute < 60 and value.time.second < 60;
}

pub fn compareDate(a: Date, b: Date) i32 {
    return compareDateTime(.{ .date = a }, .{ .date = b });
}

pub fn compareDateTime(left: DateTime, right: DateTime) i32 {
    if (!runtime.hasDate()) return 0;
    const raw_left = toAbi(left);
    const raw_right = toAbi(right);
    return runtime.date().compare_date_time(&raw_left, &raw_right);
}

pub fn weekday(value: Date) ?Weekday {
    if (!validDate(value)) return null;
    const raw = weekdayNumber(value.year, value.month, value.day);
    if (raw > @intFromEnum(Weekday.saturday)) return null;
    return @enumFromInt(raw);
}

pub fn weekdayNumber(year: u16, month: u8, day: u8) u8 {
    if (!runtime.hasDate()) return 0;
    return runtime.date().weekday_number(year, month, day);
}

pub fn shiftMinutes(value: DateTime, delta_minutes: i32) ?ShiftedDateTime {
    if (!runtime.hasDate()) return null;
    const input = toAbi(value);
    var output = std.mem.zeroes(abi.R4StdShiftedDateTime);
    if (runtime.date().shift_minutes(&input, delta_minutes, &output) != abi.status_ok) return null;
    return .{
        .value = .{
            .date = .{ .year = output.year, .month = output.month, .day = output.day },
            .time = .{ .hour = output.hour, .minute = output.minute, .second = output.second },
        },
        .day_delta = output.day_delta,
    };
}

pub fn fromTimeState(state: r4os.abi.TimeState) ?DateTime {
    if (!runtime.hasDate()) return null;
    const input = stateToAbi(state);
    var output = std.mem.zeroes(abi.R4StdDateTime);
    if (runtime.date().from_time_state(&input, &output) != abi.status_ok) return null;
    return fromAbi(output);
}

pub fn toTimeState(value: DateTime) ?r4os.abi.TimeState {
    if (!runtime.hasDate()) return null;
    const input = toAbi(value);
    var output = std.mem.zeroes(abi.R4StdTimeState);
    if (runtime.date().to_time_state(&input, &output) != abi.status_ok) return null;
    return stateFromAbi(output);
}

pub fn utcFromDateTime(value: DateTime, nanosecond: u32) ?r4os.abi.R4UtcTime {
    if (!runtime.hasDate()) return null;
    const input = toAbi(value);
    var output = std.mem.zeroes(abi.R4StdUtcTime);
    if (runtime.date().utc_from_date_time(&input, nanosecond, &output) != abi.status_ok) return null;
    return .{ .seconds_since_unix_epoch = output.seconds_since_unix_epoch, .nanosecond = output.nanosecond };
}

pub fn dateTimeFromUtc(value: r4os.abi.R4UtcTime) ?DateTime {
    if (!runtime.hasDate()) return null;
    const input = abi.R4StdUtcTime{ .seconds_since_unix_epoch = value.seconds_since_unix_epoch, .nanosecond = value.nanosecond, .reserved = 0 };
    var output = std.mem.zeroes(abi.R4StdDateTime);
    if (runtime.date().date_time_from_utc(&input, &output) != abi.status_ok) return null;
    return fromAbi(output);
}

pub fn formatDateIso(out: []u8, value: Date) []const u8 {
    return format(out, .{ .date = value }, abi.date_format_date_iso, r4os.abi.clock_format_24h);
}

pub fn formatDateTimeIso(out: []u8, value: DateTime) []const u8 {
    return format(out, value, abi.date_format_datetime_iso, r4os.abi.clock_format_24h);
}

pub fn formatDateTimeMinuteDisplay(out: []u8, value: DateTime, clock_format: u32) []const u8 {
    return format(out, value, abi.date_format_datetime_minute, clock_format);
}

pub fn parseDateIso(value: []const u8) ?Date {
    return (parse(value, abi.date_parse_date) orelse return null).date;
}

pub fn parseTime24(value: []const u8) ?TimeOfDay {
    return (parse(value, abi.date_parse_time) orelse return null).time;
}

pub fn parseDateTimeIso(value: []const u8) ?DateTime {
    return parse(value, abi.date_parse_datetime);
}

pub fn decodeFatDate(raw: u16) ?Date {
    return (decodeFat(raw, 0, abi.fat_decode_date) orelse return null).date;
}

pub fn decodeFatDateTime(date_raw: u16, time_raw: u16) ?DateTime {
    return decodeFat(date_raw, time_raw, abi.fat_decode_datetime);
}

fn format(out: []u8, value: DateTime, mode: u32, clock_format: u32) []const u8 {
    if (!runtime.hasDate()) return out[0..0];
    const input = toAbi(value);
    var written: u64 = 0;
    if (runtime.date().format(&input, mode, clock_format, out.ptr, out.len, &written) != abi.status_ok) return out[0..0];
    const len = std.math.cast(usize, written) orelse return out[0..0];
    if (len > out.len) return out[0..0];
    return out[0..len];
}

fn parse(value: []const u8, mode: u32) ?DateTime {
    if (!runtime.hasDate()) return null;
    var output = std.mem.zeroes(abi.R4StdDateTime);
    if (runtime.date().parse(value.ptr, value.len, mode, &output) != abi.status_ok) return null;
    return fromAbi(output);
}

fn decodeFat(date_raw: u16, time_raw: u16, mode: u32) ?DateTime {
    if (!runtime.hasDate()) return null;
    var output = std.mem.zeroes(abi.R4StdDateTime);
    if (runtime.date().decode_fat(date_raw, time_raw, mode, &output) != abi.status_ok) return null;
    return fromAbi(output);
}

pub fn toAbi(value: DateTime) abi.R4StdDateTime {
    return .{
        .year = value.date.year,
        .month = value.date.month,
        .day = value.date.day,
        .hour = value.time.hour,
        .minute = value.time.minute,
        .second = value.time.second,
        .reserved = 0,
    };
}

pub fn fromAbi(value: abi.R4StdDateTime) DateTime {
    return .{
        .date = .{ .year = value.year, .month = value.month, .day = value.day },
        .time = .{ .hour = value.hour, .minute = value.minute, .second = value.second },
    };
}

pub fn stateToAbi(value: r4os.abi.TimeState) abi.R4StdTimeState {
    return .{
        .year = value.year,
        .month = value.month,
        .day = value.day,
        .hour = value.hour,
        .minute = value.minute,
        .second = value.second,
        .weekday = value.weekday,
        .seconds_since_midnight = value.seconds_since_midnight,
        .valid = value.valid,
    };
}

pub fn stateFromAbi(value: abi.R4StdTimeState) r4os.abi.TimeState {
    return .{
        .valid = @intCast(value.valid),
        .century_source = 0,
        .weekday = value.weekday,
        .year = value.year,
        .month = value.month,
        .day = value.day,
        .hour = value.hour,
        .minute = value.minute,
        .second = value.second,
        .seconds_since_midnight = value.seconds_since_midnight,
    };
}
