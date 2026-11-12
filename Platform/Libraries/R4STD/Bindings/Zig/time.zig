const std = @import("std");
const r4os = @import("r4os");
const runtime = @import("runtime.zig");
const abi = runtime.abi;
const date = @import("date.zig");

pub const schema = "TIME";
pub const default_timezone_id = "UTC";
pub const zone_count: usize = abi.zone_count;
pub const zone_id_max: usize = abi.zone_id_max;
pub const zone_label_max: usize = abi.zone_label_max;
pub const utc_index: usize = abi.utc_index;
pub const seconds_per_day: u32 = abi.seconds_per_day;

pub const Zone = struct {
    id: []const u8 = "",
    label: []const u8 = "",
    offset_minutes: i16 = 0,
    standard_offset_minutes: i16 = 0,
    daylight_offset_minutes: i16 = 0,
    uses_daylight_time: bool = false,
};

pub const ClockTime = struct {
    hours: u8,
    minutes: u8,
    seconds: u8,
};

pub const Config = struct {
    timezone_index: usize = utc_index,
    clock_format: u32 = r4os.abi.clock_format_24h,

    pub fn selectedIndex(self: Config) usize {
        return normalized(self).timezone_index;
    }

    pub fn zone(self: Config) Zone {
        const index = self.selectedIndex();
        const offset = standardOffsetAt(index);
        return .{ .offset_minutes = offset, .standard_offset_minutes = offset, .daylight_offset_minutes = offset };
    }

    pub fn selectedClockFormat(self: Config) u32 {
        return normalized(self).clock_format;
    }

    pub fn offsetMinutes(self: Config) i16 {
        return standardOffsetAt(self.selectedIndex());
    }

    pub fn offsetMinutesForState(self: Config, state: r4os.abi.TimeState) i16 {
        return offsetAtState(self.selectedIndex(), state);
    }

    pub fn loadFromBytes(self: *Config, bytes: []const u8) bool {
        if (!runtime.hasTime()) return false;
        var raw = toAbi(self.*);
        const loaded = runtime.time().config_load(&raw, bytes.ptr, bytes.len) != 0;
        self.* = fromAbi(raw);
        return loaded;
    }

    pub fn setIndex(self: *Config, index: usize) void {
        self.timezone_index = index;
        self.* = normalized(self.*);
    }

    pub fn setClockFormat(self: *Config, value: u32) void {
        self.clock_format = value;
        self.* = normalized(self.*);
    }

    pub fn writeTo(self: Config, out: []u8) []const u8 {
        return writeConfig(self, out, null);
    }

    pub fn writeToForState(self: Config, out: []u8, state: r4os.abi.TimeState) []const u8 {
        return writeConfig(self, out, state);
    }
};

pub fn zoneCount() usize {
    if (!runtime.hasTime()) return 0;
    return runtime.time().zone_count();
}

pub fn copyZoneId(out: []u8, index: usize) []const u8 {
    if (!runtime.hasTime()) return out[0..0];
    var written: u64 = 0;
    const raw_index = std.math.cast(u32, index) orelse return out[0..0];
    if (runtime.time().copy_zone_id(raw_index, out.ptr, out.len, &written) != abi.status_ok) return out[0..0];
    return writtenSlice(out, written);
}

pub fn copyZoneLabelForState(out: []u8, index: usize, state: r4os.abi.TimeState) []const u8 {
    if (!runtime.hasTime()) return out[0..0];
    var written: u64 = 0;
    const raw_index = std.math.cast(u32, index) orelse return out[0..0];
    const raw_state = date.stateToAbi(state);
    if (runtime.time().copy_zone_label(raw_index, &raw_state, out.ptr, out.len, &written) != abi.status_ok) return out[0..0];
    return writtenSlice(out, written);
}

pub fn indexForId(id: []const u8) ?usize {
    if (!runtime.hasTime()) return null;
    var output: u32 = 0;
    if (runtime.time().index_for_id(id.ptr, id.len, &output) != abi.status_ok) return null;
    return output;
}

pub fn offsetAtState(index: usize, state: r4os.abi.TimeState) i16 {
    if (!runtime.hasTime()) return 0;
    const raw_index = std.math.cast(u32, index) orelse return 0;
    const raw_state = date.stateToAbi(state);
    return std.math.cast(i16, runtime.time().offset_at_state(raw_index, &raw_state)) orelse 0;
}

pub fn standardOffsetAt(index: usize) i16 {
    if (!runtime.hasTime()) return 0;
    const raw_index = std.math.cast(u32, index) orelse return 0;
    return std.math.cast(i16, runtime.time().standard_offset(raw_index)) orelse 0;
}

pub fn secondsInZone(seconds_utc: u32, offset_minutes: i16) u32 {
    if (!runtime.hasTime()) return seconds_utc % seconds_per_day;
    return runtime.time().seconds_in_zone(seconds_utc, offset_minutes);
}

pub fn splitTime(seconds: u32) ClockTime {
    if (!runtime.hasTime()) return .{ .hours = 0, .minutes = 0, .seconds = 0 };
    var output = std.mem.zeroes(abi.R4StdClockTime);
    _ = runtime.time().split_time(seconds, &output);
    return .{ .hours = output.hours, .minutes = output.minutes, .seconds = output.seconds };
}

pub fn localDateTimeAtState(index: usize, state: r4os.abi.TimeState) ?date.DateTime {
    if (!runtime.hasTime()) return null;
    const raw_index = std.math.cast(u32, index) orelse return null;
    const raw_state = date.stateToAbi(state);
    var output = std.mem.zeroes(abi.R4StdDateTime);
    if (runtime.time().local_date_time(raw_index, &raw_state, &output) != abi.status_ok) return null;
    return date.fromAbi(output);
}

pub fn localDateTimeForConfig(config: Config, state: r4os.abi.TimeState) ?date.DateTime {
    return localDateTimeAtState(config.selectedIndex(), state);
}

pub fn formatDisplay(out: []u8, value: ClockTime, clock_format: u32) []const u8 {
    return formatClock(out, value, abi.time_format_display, clock_format);
}

pub fn formatHmDisplay(out: []u8, value: ClockTime, clock_format: u32) []const u8 {
    return formatClock(out, value, abi.time_format_hm, clock_format);
}

pub fn formatHms(out: []u8, value: ClockTime) []const u8 {
    return formatClock(out, value, abi.time_format_24h, r4os.abi.clock_format_24h);
}

pub fn formatOffset(out: []u8, offset_minutes: i16) []const u8 {
    if (!runtime.hasTime()) return out[0..0];
    var written: u64 = 0;
    if (runtime.time().format_offset(offset_minutes, out.ptr, out.len, &written) != abi.status_ok) return out[0..0];
    return writtenSlice(out, written);
}

fn formatClock(out: []u8, value: ClockTime, mode: u32, clock_format: u32) []const u8 {
    if (!runtime.hasTime()) return out[0..0];
    const input = abi.R4StdClockTime{ .hours = value.hours, .minutes = value.minutes, .seconds = value.seconds, .reserved = 0 };
    var written: u64 = 0;
    if (runtime.time().format_clock(&input, mode, clock_format, out.ptr, out.len, &written) != abi.status_ok) return out[0..0];
    return writtenSlice(out, written);
}

fn writeConfig(value: Config, out: []u8, state: ?r4os.abi.TimeState) []const u8 {
    if (!runtime.hasTime()) return out[0..0];
    const raw_config = toAbi(value);
    const raw_state = if (state) |current| date.stateToAbi(current) else std.mem.zeroes(abi.R4StdTimeState);
    var written: u64 = 0;
    if (runtime.time().config_write(&raw_config, &raw_state, @intFromBool(state != null), out.ptr, out.len, &written) != abi.status_ok) return out[0..0];
    return writtenSlice(out, written);
}

fn normalized(value: Config) Config {
    if (!runtime.hasTime()) return value;
    var raw = toAbi(value);
    if (runtime.time().config_normalize(&raw) != abi.status_ok) return value;
    return fromAbi(raw);
}

fn toAbi(value: Config) abi.R4StdTimeConfig {
    return .{
        .timezone_index = std.math.cast(u32, value.timezone_index) orelse abi.utc_index,
        .clock_format = value.clock_format,
    };
}

fn fromAbi(value: abi.R4StdTimeConfig) Config {
    return .{ .timezone_index = value.timezone_index, .clock_format = value.clock_format };
}

fn writtenSlice(out: []u8, raw_length: u64) []const u8 {
    const len = std.math.cast(usize, raw_length) orelse return out[0..0];
    if (len > out.len) return out[0..0];
    return out[0..len];
}
