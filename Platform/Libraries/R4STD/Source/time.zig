const std = @import("std");
const r4os = @import("r4os");
const abi = r4os.abi;
const date = @import("date.zig");
const settings = @import("settings.zig");
const time_contract = r4os.time_contract;

pub const Duration = time_contract.Duration;
pub const MonotonicInstant = time_contract.MonotonicInstant;
pub const Deadline = time_contract.Deadline;
pub const Timeout = time_contract.Timeout;

pub fn durationFromNanoseconds(nanoseconds: u64) Duration {
    return time_contract.durationFromNanoseconds(nanoseconds);
}

pub fn resolutionNanoseconds(monotonic_hz: u32) time_contract.Error!u64 {
    return time_contract.resolutionNanoseconds(monotonic_hz);
}

pub fn durationToTicks(duration: Duration, monotonic_hz: u32) time_contract.Error!u64 {
    return time_contract.durationToTicks(duration, monotonic_hz);
}

pub fn durationFromTicks(ticks: u64, monotonic_hz: u32) time_contract.Error!Duration {
    return time_contract.durationFromTicks(ticks, monotonic_hz);
}

pub fn monotonicFromTicks(ticks: u64, monotonic_hz: u32) time_contract.Error!MonotonicInstant {
    return time_contract.monotonicFromTicks(ticks, monotonic_hz);
}

pub fn deadlineAfter(now: MonotonicInstant, duration: Duration) Deadline {
    return time_contract.deadlineAfter(now, duration);
}

pub fn timeoutPoll() Timeout {
    return time_contract.timeoutPoll();
}

pub fn timeoutFinite(duration: Duration) Timeout {
    return time_contract.timeoutFinite(duration);
}

pub fn timeoutForever() Timeout {
    return time_contract.timeoutForever();
}

pub fn timeoutToTicks(timeout: Timeout, monotonic_hz: u32) time_contract.Error!u64 {
    return time_contract.timeoutToTicks(timeout, monotonic_hz);
}

pub fn timeoutDeadline(timeout: Timeout, now: MonotonicInstant) time_contract.Error!?Deadline {
    return time_contract.timeoutDeadline(timeout, now);
}

pub fn remainingTicks(deadline: Deadline, now: MonotonicInstant, monotonic_hz: u32) time_contract.Error!u64 {
    return time_contract.remainingTicks(deadline, now, monotonic_hz);
}

pub const schema = "TIME";
pub const default_timezone_id = "UTC";
pub const zone_count: usize = 38;
pub const zone_id_max: usize = 31;
pub const zone_label_max: usize = 39;
pub const utc_index: usize = 13;
pub const seconds_per_day: u32 = 24 * 60 * 60;

pub const Zone = struct {
    id: []const u8,
    label: []const u8,
    offset_minutes: i16,
    standard_offset_minutes: i16,
    daylight_offset_minutes: i16,
    uses_daylight_time: bool,
};

const DstProfile = enum {
    none,
    europe,
    north_america,
    australia,
    lord_howe,
    new_zealand,
};

const zone_offsets = [_]i16{
    -12 * 60,
    -11 * 60,
    -10 * 60,
    -9 * 60,
    -8 * 60,
    -7 * 60,
    -6 * 60,
    -5 * 60,
    -4 * 60,
    -3 * 60 - 30,
    -3 * 60,
    -2 * 60,
    -60,
    0,
    0,
    60,
    2 * 60,
    3 * 60,
    3 * 60 + 30,
    4 * 60,
    4 * 60 + 30,
    5 * 60,
    5 * 60 + 30,
    5 * 60 + 45,
    6 * 60,
    6 * 60 + 30,
    7 * 60,
    8 * 60,
    8 * 60 + 45,
    9 * 60,
    9 * 60 + 30,
    10 * 60,
    10 * 60 + 30,
    11 * 60,
    12 * 60,
    12 * 60 + 45,
    13 * 60,
    14 * 60,
};

const zone_daylight_offsets = [_]i16{
    -12 * 60,
    -11 * 60,
    -10 * 60,
    -8 * 60,
    -7 * 60,
    -6 * 60,
    -5 * 60,
    -4 * 60,
    -3 * 60,
    -2 * 60 - 30,
    -3 * 60,
    -2 * 60,
    0,
    0,
    60,
    2 * 60,
    3 * 60,
    3 * 60,
    3 * 60 + 30,
    4 * 60,
    4 * 60 + 30,
    5 * 60,
    5 * 60 + 30,
    5 * 60 + 45,
    6 * 60,
    6 * 60 + 30,
    7 * 60,
    8 * 60,
    8 * 60 + 45,
    9 * 60,
    10 * 60 + 30,
    11 * 60,
    11 * 60,
    11 * 60,
    13 * 60,
    13 * 60 + 45,
    13 * 60,
    14 * 60,
};

pub const ClockTime = struct {
    hours: u8,
    minutes: u8,
    seconds: u8,
};

pub const Config = struct {
    timezone_index: usize = utc_index,
    clock_format: u32 = abi.clock_format_24h,

    pub fn selectedIndex(self: Config) usize {
        return normalizeIndex(self.timezone_index);
    }

    pub fn zone(self: Config) Zone {
        return zoneAt(self.selectedIndex());
    }

    pub fn selectedClockFormat(self: Config) u32 {
        return normalizeClockFormat(self.clock_format);
    }

    pub fn offsetMinutes(self: Config) i16 {
        return offsetAt(self.selectedIndex());
    }

    pub fn offsetMinutesForState(self: Config, state: abi.TimeState) i16 {
        return offsetAtState(self.selectedIndex(), state);
    }

    pub fn loadFromBytes(self: *Config, bytes: []const u8) bool {
        const doc = settings.Document.init(bytes);
        if (doc.value("CLOCK_FORMAT")) |value| {
            self.clock_format = parseClockFormat(value) orelse abi.clock_format_24h;
        }
        if (doc.value("TIMEZONE")) |id| {
            if (indexForId(id)) |index| {
                self.timezone_index = index;
                return true;
            }
        }
        if (doc.i32Value("UTC_OFFSET_MINUTES")) |offset| {
            if (indexForOffset(offset)) |index| {
                self.timezone_index = index;
                return true;
            }
        }
        return false;
    }

    pub fn setIndex(self: *Config, index: usize) void {
        self.timezone_index = normalizeIndex(index);
    }

    pub fn setClockFormat(self: *Config, clock_format: u32) void {
        self.clock_format = normalizeClockFormat(clock_format);
    }

    pub fn writeTo(self: Config, out: []u8) []const u8 {
        var writer = settings.Writer.init(out);
        var id_buffer: [zone_id_max + 1]u8 = .{0} ** (zone_id_max + 1);
        var label_buffer: [zone_label_max + 1]u8 = .{0} ** (zone_label_max + 1);
        const selected_index = self.selectedIndex();
        const id = copyZoneId(id_buffer[0..], selected_index);
        const label = copyZoneLabel(label_buffer[0..], selected_index);
        writer.writeHeader(schema);
        writer.writePair("TIMEZONE", id);
        writer.writePairI32("UTC_OFFSET_MINUTES", offsetAt(selected_index));
        writer.writePair("CLOCK_FORMAT", clockFormatName(self.selectedClockFormat()));
        writer.writePair("LABEL", label);
        return if (writer.ok()) writer.bytes() else out[0..0];
    }

    pub fn writeToForState(self: Config, out: []u8, state: abi.TimeState) []const u8 {
        var writer = settings.Writer.init(out);
        var id_buffer: [zone_id_max + 1]u8 = .{0} ** (zone_id_max + 1);
        var label_buffer: [zone_label_max + 1]u8 = .{0} ** (zone_label_max + 1);
        const selected_index = self.selectedIndex();
        const id = copyZoneId(id_buffer[0..], selected_index);
        const label = copyZoneLabelForState(label_buffer[0..], selected_index, state);
        writer.writeHeader(schema);
        writer.writePair("TIMEZONE", id);
        writer.writePairI32("UTC_OFFSET_MINUTES", offsetAtState(selected_index, state));
        writer.writePair("CLOCK_FORMAT", clockFormatName(self.selectedClockFormat()));
        writer.writePair("LABEL", label);
        return if (writer.ok()) writer.bytes() else out[0..0];
    }
};

pub fn zoneCount() usize {
    return zone_count;
}

pub fn zoneAt(index: usize) Zone {
    const normalized = normalizeIndex(index);
    return .{
        .id = zoneId(normalized),
        .label = zoneLabel(normalized),
        .offset_minutes = offsetAt(normalized),
        .standard_offset_minutes = offsetAt(normalized),
        .daylight_offset_minutes = daylightOffsetAt(normalized),
        .uses_daylight_time = dstProfileAt(normalized) != .none,
    };
}

pub fn offsetAt(index: usize) i16 {
    return zone_offsets[normalizeIndex(index)];
}

pub fn daylightOffsetAt(index: usize) i16 {
    return zone_daylight_offsets[normalizeIndex(index)];
}

pub fn offsetAtState(index: usize, state: abi.TimeState) i16 {
    const normalized = normalizeIndex(index);
    if (isDaylightTime(normalized, state)) return daylightOffsetAt(normalized);
    return offsetAt(normalized);
}

pub fn zoneId(index: usize) []const u8 {
    return switch (normalizeIndex(index)) {
        0 => "UTC-12",
        1 => "Pacific/Samoa",
        2 => "Pacific/Honolulu",
        3 => "America/Anchorage",
        4 => "America/Los_Angeles",
        5 => "America/Denver",
        6 => "America/Chicago",
        7 => "America/New_York",
        8 => "America/Halifax",
        9 => "America/St_Johns",
        10 => "America/Sao_Paulo",
        11 => "Atlantic/South_Georgia",
        12 => "Atlantic/Azores",
        13 => "UTC",
        14 => "Europe/London",
        15 => "Europe/Berlin",
        16 => "Europe/Athens",
        17 => "Europe/Moscow",
        18 => "Asia/Tehran",
        19 => "Asia/Dubai",
        20 => "Asia/Kabul",
        21 => "Asia/Karachi",
        22 => "Asia/Kolkata",
        23 => "Asia/Kathmandu",
        24 => "Asia/Dhaka",
        25 => "Asia/Yangon",
        26 => "Asia/Bangkok",
        27 => "Asia/Shanghai",
        28 => "Australia/Eucla",
        29 => "Asia/Tokyo",
        30 => "Australia/Adelaide",
        31 => "Australia/Sydney",
        32 => "Australia/Lord_Howe",
        33 => "Pacific/Guadalcanal",
        34 => "Pacific/Auckland",
        35 => "Pacific/Chatham",
        36 => "Pacific/Tongatapu",
        37 => "Pacific/Kiritimati",
        else => default_timezone_id,
    };
}

pub fn zoneLabel(index: usize) []const u8 {
    return switch (normalizeIndex(index)) {
        0 => "UTC-12:00 Baker Island",
        1 => "UTC-11:00 Samoa",
        2 => "UTC-10:00 Hawaii",
        3 => "UTC-09/-08 Alaska",
        4 => "UTC-08/-07 Pacific",
        5 => "UTC-07/-06 Mountain",
        6 => "UTC-06/-05 Central",
        7 => "UTC-05/-04 Eastern",
        8 => "UTC-04/-03 Atlantic",
        9 => "UTC-03:30/-02:30 Newfoundland",
        10 => "UTC-03:00 Brazil",
        11 => "UTC-02:00 South Georgia",
        12 => "UTC-01/+00 Azores",
        13 => "UTC+00:00 UTC",
        14 => "UTC+00/+01 London",
        15 => "UTC+01/+02 Berlin / Paris",
        16 => "UTC+02/+03 Athens / Helsinki",
        17 => "UTC+03:00 Moscow / Riyadh",
        18 => "UTC+03:30 Tehran",
        19 => "UTC+04:00 Dubai",
        20 => "UTC+04:30 Kabul",
        21 => "UTC+05:00 Karachi",
        22 => "UTC+05:30 India / Sri Lanka",
        23 => "UTC+05:45 Nepal",
        24 => "UTC+06:00 Dhaka",
        25 => "UTC+06:30 Yangon",
        26 => "UTC+07:00 Bangkok",
        27 => "UTC+08:00 Beijing / Perth",
        28 => "UTC+08:45 Eucla",
        29 => "UTC+09:00 Tokyo / Seoul",
        30 => "UTC+09:30/+10:30 Adelaide",
        31 => "UTC+10/+11 Sydney / Melbourne",
        32 => "UTC+10:30/+11 Lord Howe",
        33 => "UTC+11:00 Solomon Islands",
        34 => "UTC+12/+13 Auckland / Wellington",
        35 => "UTC+12:45/+13:45 Chatham",
        36 => "UTC+13:00 Tonga",
        37 => "UTC+14:00 Line Islands",
        else => "UTC+00:00 UTC",
    };
}

pub fn copyZoneId(out: []u8, index: usize) []const u8 {
    return copyBytes(out, zoneId(index));
}

pub fn copyZoneLabel(out: []u8, index: usize) []const u8 {
    return copyBytes(out, zoneLabel(index));
}

pub fn copyZoneLabelForState(out: []u8, index: usize, state: abi.TimeState) []const u8 {
    if (out.len == 0) return out[0..0];
    @memset(out, 0);
    var offset_buffer: [10]u8 = .{0} ** 10;
    const offset = formatOffset(offset_buffer[0..], offsetAtState(index, state));
    const name = zoneDisplayName(index);
    var pos: usize = 0;
    pos = appendBytes(out, pos, offset);
    if (pos < out.len - 1) {
        out[pos] = ' ';
        pos += 1;
    }
    pos = appendBytes(out, pos, name);
    out[pos] = 0;
    return out[0..pos];
}

fn zoneDisplayName(index: usize) []const u8 {
    return switch (normalizeIndex(index)) {
        0 => "Baker Island",
        1 => "Samoa",
        2 => "Hawaii",
        3 => "Alaska",
        4 => "Pacific",
        5 => "Mountain",
        6 => "Central",
        7 => "Eastern",
        8 => "Atlantic",
        9 => "Newfoundland",
        10 => "Brazil",
        11 => "South Georgia",
        12 => "Azores",
        13 => "UTC",
        14 => "London",
        15 => "Berlin / Paris",
        16 => "Athens / Helsinki",
        17 => "Moscow / Riyadh",
        18 => "Tehran",
        19 => "Dubai",
        20 => "Kabul",
        21 => "Karachi",
        22 => "India / Sri Lanka",
        23 => "Nepal",
        24 => "Dhaka",
        25 => "Yangon",
        26 => "Bangkok",
        27 => "Beijing / Perth",
        28 => "Eucla",
        29 => "Tokyo / Seoul",
        30 => "Adelaide",
        31 => "Sydney / Melbourne",
        32 => "Lord Howe",
        33 => "Solomon Islands",
        34 => "Auckland / Wellington",
        35 => "Chatham",
        36 => "Tonga",
        37 => "Line Islands",
        else => "UTC",
    };
}

fn dstProfileAt(index: usize) DstProfile {
    return switch (normalizeIndex(index)) {
        3, 4, 5, 6, 7, 8, 9 => .north_america,
        12, 14, 15, 16 => .europe,
        30, 31 => .australia,
        32 => .lord_howe,
        34, 35 => .new_zealand,
        else => .none,
    };
}

fn isDaylightTime(index: usize, state: abi.TimeState) bool {
    if (!validDate(state)) return false;
    return switch (dstProfileAt(index)) {
        .none => false,
        .europe => isEuropeDaylight(state),
        .north_america => isNorthAmericaDaylight(state),
        .australia, .lord_howe => isAustraliaDaylight(state),
        .new_zealand => isNewZealandDaylight(state),
    };
}

pub fn indexForId(id: []const u8) ?usize {
    var index: usize = 0;
    while (index < zone_count) : (index += 1) {
        if (settings.equalsKey(id, zoneId(index))) return index;
    }
    return null;
}

pub fn indexForOffset(offset_minutes: i32) ?usize {
    for (zone_offsets, 0..) |offset, index| {
        if (@as(i32, offset) == offset_minutes) return index;
    }
    return null;
}

pub fn secondsInZone(seconds_utc: u32, offset_minutes: i16) u32 {
    var total: i32 = @intCast(seconds_utc % seconds_per_day);
    total += @as(i32, offset_minutes) * 60;
    total = @mod(total, @as(i32, seconds_per_day));
    return @intCast(total);
}

pub fn splitTime(seconds: u32) ClockTime {
    const split = date.timeFromSeconds(seconds);
    return .{
        .hours = split.hour,
        .minutes = split.minute,
        .seconds = split.second,
    };
}

pub fn clockTimeToDateTime(time: ClockTime) date.TimeOfDay {
    return .{ .hour = time.hours, .minute = time.minutes, .second = time.seconds };
}

pub fn dateTimeToClockTime(time: date.TimeOfDay) ClockTime {
    return .{ .hours = time.hour, .minutes = time.minute, .seconds = time.second };
}

pub fn localDateTimeAtState(index: usize, state: abi.TimeState) ?date.DateTime {
    const utc = date.fromTimeState(state) orelse return null;
    const shifted = date.shiftMinutes(utc, offsetAtState(index, state)) orelse return null;
    return shifted.value;
}

pub fn localDateTimeForConfig(config: Config, state: abi.TimeState) ?date.DateTime {
    return localDateTimeAtState(config.selectedIndex(), state);
}

pub fn formatHms(out: []u8, time: ClockTime) []const u8 {
    return date.formatTime24(out, clockTimeToDateTime(time));
}

pub fn formatHm(out: []u8, time: ClockTime) []const u8 {
    return date.formatHourMinute24(out, clockTimeToDateTime(time));
}

pub fn formatDisplay(out: []u8, time: ClockTime, clock_format: u32) []const u8 {
    return date.formatTimeDisplay(out, clockTimeToDateTime(time), normalizeClockFormat(clock_format));
}

pub fn formatHmDisplay(out: []u8, time: ClockTime, clock_format: u32) []const u8 {
    return date.formatHourMinuteDisplay(out, clockTimeToDateTime(time), normalizeClockFormat(clock_format));
}

pub fn formatOffset(out: []u8, offset_minutes: i16) []const u8 {
    if (out.len < 10) return out[0..0];
    var pos: usize = 0;
    out[pos] = 'U';
    pos += 1;
    out[pos] = 'T';
    pos += 1;
    out[pos] = 'C';
    pos += 1;
    const negative = offset_minutes < 0;
    out[pos] = if (negative) '-' else '+';
    pos += 1;
    const absolute: u16 = if (negative)
        @intCast(-@as(i32, offset_minutes))
    else
        @intCast(offset_minutes);
    const hours: u16 = absolute / 60;
    const minutes: u16 = absolute % 60;
    out[pos] = digit(@intCast(hours / 10));
    pos += 1;
    out[pos] = digit(@intCast(hours % 10));
    pos += 1;
    out[pos] = ':';
    pos += 1;
    out[pos] = digit(@intCast(minutes / 10));
    pos += 1;
    out[pos] = digit(@intCast(minutes % 10));
    pos += 1;
    out[pos] = 0;
    return out[0..pos];
}

fn normalizeIndex(index: usize) usize {
    return if (index < zone_count) index else utc_index;
}

pub fn normalizeClockFormat(clock_format: u32) u32 {
    return if (clock_format == abi.clock_format_12h) abi.clock_format_12h else abi.clock_format_24h;
}

pub fn clockFormatName(clock_format: u32) []const u8 {
    return if (normalizeClockFormat(clock_format) == abi.clock_format_12h) "12H" else "24H";
}

pub fn parseClockFormat(value: []const u8) ?u32 {
    if (settings.equalsKey(value, "12H") or settings.equalsKey(value, "12") or settings.equalsKey(value, "AMPM")) return abi.clock_format_12h;
    if (settings.equalsKey(value, "24H") or settings.equalsKey(value, "24")) return abi.clock_format_24h;
    return null;
}

fn validDate(state: abi.TimeState) bool {
    return date.validDateValue(state.year, state.month, state.day);
}

fn isEuropeDaylight(state: abi.TimeState) bool {
    if (state.month < 3 or state.month > 10) return false;
    if (state.month > 3 and state.month < 10) return true;
    if (state.month == 3) return state.day >= lastSunday(state.year, 3);
    return state.day < lastSunday(state.year, 10);
}

fn isNorthAmericaDaylight(state: abi.TimeState) bool {
    if (state.month < 3 or state.month > 11) return false;
    if (state.month > 3 and state.month < 11) return true;
    if (state.month == 3) return state.day >= nthSunday(state.year, 3, 2);
    return state.day < nthSunday(state.year, 11, 1);
}

fn isAustraliaDaylight(state: abi.TimeState) bool {
    if (state.month > 10 or state.month < 4) return true;
    if (state.month == 10) return state.day >= nthSunday(state.year, 10, 1);
    if (state.month == 4) return state.day < nthSunday(state.year, 4, 1);
    return false;
}

fn isNewZealandDaylight(state: abi.TimeState) bool {
    if (state.month > 9 or state.month < 4) return true;
    if (state.month == 9) return state.day >= lastSunday(state.year, 9);
    if (state.month == 4) return state.day < nthSunday(state.year, 4, 1);
    return false;
}

fn nthSunday(year: u16, month: u8, n: u8) u8 {
    return firstSunday(year, month) + (n - 1) * 7;
}

fn firstSunday(year: u16, month: u8) u8 {
    const weekday = dayOfWeek(year, month, 1);
    return if (weekday == 0) 1 else 8 - weekday;
}

fn lastSunday(year: u16, month: u8) u8 {
    const last = daysInMonth(year, month);
    const weekday = dayOfWeek(year, month, last);
    return last - weekday;
}

fn dayOfWeek(year: u16, month: u8, day: u8) u8 {
    return date.weekdayNumber(year, month, day);
}

fn daysInMonth(year: u16, month: u8) u8 {
    return date.daysInMonth(year, month);
}

fn isLeapYear(year: u16) bool {
    return date.isLeapYear(year);
}

fn digit(value: u8) u8 {
    return '0' + value % 10;
}

fn appendBytes(out: []u8, start: usize, value: []const u8) usize {
    if (out.len == 0) return 0;
    var pos = start;
    var i: usize = 0;
    while (i < value.len and pos < out.len - 1) : (i += 1) {
        out[pos] = value[i];
        pos += 1;
    }
    return pos;
}

fn copyBytes(out: []u8, value: []const u8) []const u8 {
    if (out.len == 0) return out[0..0];
    @memset(out, 0);
    const count = appendBytes(out, 0, value);
    out[count] = 0;
    return out[0..count];
}

fn copyLiteral(out: []u8, comptime value: []const u8) []const u8 {
    if (out.len == 0) return out[0..0];
    @memset(out, 0);
    const count = @min(value.len, out.len - 1);
    inline for (value, 0..) |ch, i| {
        if (i < count) out[i] = ch;
    }
    out[count] = 0;
    return out[0..count];
}

test "timezone table and labels stay aligned" {
    try std.testing.expectEqual(zone_count, zone_offsets.len);
    try std.testing.expectEqual(zone_count, zone_daylight_offsets.len);
    try std.testing.expectEqualStrings(default_timezone_id, zoneId(utc_index));
    try std.testing.expectEqualStrings("UTC+01/+02 Berlin / Paris", zoneLabel(indexForId("Europe/Berlin").?));
    var label: [zone_label_max + 1]u8 = .{0} ** (zone_label_max + 1);
    try std.testing.expectEqualStrings("UTC+01/+02 Berlin / Paris", copyZoneLabel(label[0..], indexForId("Europe/Berlin").?));
}

test "config parser accepts timezone id and writes canonical file" {
    var config = Config{};
    try std.testing.expect(config.loadFromBytes(
        \\R4S_FORMAT=1
        \\SCHEMA=TIME
        \\TIMEZONE=Europe/Berlin
    ));
    try std.testing.expectEqual(indexForId("Europe/Berlin").?, config.selectedIndex());
    var out: [192]u8 = .{0} ** 192;
    const bytes = config.writeTo(out[0..]);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "SCHEMA=TIME") != null);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "TIMEZONE=Europe/Berlin") != null);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "UTC_OFFSET_MINUTES=60") != null);
}

test "current dst rules make Berlin UTC+2 in May" {
    const berlin = indexForId("Europe/Berlin").?;
    const may: abi.TimeState = .{ .year = 2026, .month = 5, .day = 11 };
    const january: abi.TimeState = .{ .year = 2026, .month = 1, .day = 15 };
    try std.testing.expectEqual(@as(i16, 120), offsetAtState(berlin, may));
    try std.testing.expectEqual(@as(i16, 60), offsetAtState(berlin, january));
    var label: [zone_label_max + 1]u8 = .{0} ** (zone_label_max + 1);
    try std.testing.expectEqualStrings("UTC+02:00 Berlin / Paris", copyZoneLabelForState(label[0..], berlin, may));
}

test "config writer can persist effective daylight offset" {
    var config = Config{};
    config.setIndex(indexForId("Europe/Berlin").?);
    var out: [192]u8 = .{0} ** 192;
    const bytes = config.writeToForState(out[0..], .{ .year = 2026, .month = 5, .day = 11 });
    try std.testing.expect(std.mem.indexOf(u8, bytes, "TIMEZONE=Europe/Berlin") != null);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "UTC_OFFSET_MINUTES=120") != null);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "LABEL=UTC+02:00 Berlin / Paris") != null);
}

test "clock helpers wrap offsets across midnight" {
    const late = splitTime(secondsInZone(23 * 3600 + 30 * 60, 90));
    try std.testing.expectEqual(@as(u8, 1), late.hours);
    try std.testing.expectEqual(@as(u8, 0), late.minutes);
    const early = splitTime(secondsInZone(30 * 60, -60));
    try std.testing.expectEqual(@as(u8, 23), early.hours);
    try std.testing.expectEqual(@as(u8, 30), early.minutes);
}

test "format helpers emit fixed width clock strings" {
    var hms: [9]u8 = .{0} ** 9;
    var hm: [6]u8 = .{0} ** 6;
    var offset: [10]u8 = .{0} ** 10;
    try std.testing.expectEqualStrings("07:05:09", formatHms(hms[0..], .{ .hours = 7, .minutes = 5, .seconds = 9 }));
    try std.testing.expectEqualStrings("07:05", formatHm(hm[0..], .{ .hours = 7, .minutes = 5, .seconds = 9 }));
    try std.testing.expectEqualStrings("UTC+05:30", formatOffset(offset[0..], 330));
}
