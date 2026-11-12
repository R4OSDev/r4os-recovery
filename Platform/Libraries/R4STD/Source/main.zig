const std = @import("std");
const r4os = @import("r4os");
const contract = @import("r4l_contract");
const text = @import("text.zig");
const settings = @import("settings.zig");
const date = @import("date.zig");
const time = @import("time.zig");
const config = @import("config.zig");
const codec = @import("codec.zig");

export fn r4l_entry() linksection(".text.r4l_entry") callconv(.c) void {}

fn length(value: u64) ?usize {
    return std.math.cast(usize, value);
}

fn textStatus(err: text.Error) i32 {
    return switch (err) {
        error.BufferTooSmall => contract.status_buffer_too_small,
        else => contract.status_invalid_text,
    };
}

fn startsWithBom(bytes: []const u8) bool {
    return bytes.len >= text.utf8_bom.len and std.mem.eql(u8, bytes[0..text.utf8_bom.len], text.utf8_bom);
}

pub export fn r4std_text_inspect_impl(input: [*]const u8, input_length: u64, kind: u32, output: *contract.R4StdTextInfo) linksection(".text.r4l_exports") callconv(.c) i32 {
    const len = length(input_length) orelse return contract.status_invalid_argument;
    const bytes = input[0..len];
    output.* = std.mem.zeroes(contract.R4StdTextInfo);
    switch (kind) {
        contract.text_kind_utf8 => {
            const value = text.Utf8Text.init(bytes) catch |err| return textStatus(err);
            output.* = .{
                .content_offset = 0,
                .content_length = bytes.len,
                .canonical_length = bytes.len,
                .scalar_count = value.scalarCount(),
                .encoding = contract.encoding_utf8,
                .line_ending = contract.line_ending_none,
            };
        },
        contract.text_kind_ui => {
            _ = text.UiText8.init(bytes) catch |err| return textStatus(err);
            output.* = .{
                .content_offset = 0,
                .content_length = bytes.len,
                .canonical_length = bytes.len,
                .scalar_count = bytes.len,
                .encoding = contract.encoding_bytes,
                .line_ending = contract.line_ending_none,
            };
        },
        contract.text_kind_system => {
            const value = text.SystemText.parse(bytes) catch |err| return textStatus(err);
            const offset: usize = if (startsWithBom(bytes)) text.utf8_bom.len else 0;
            output.* = .{
                .content_offset = offset,
                .content_length = value.content.len,
                .canonical_length = value.canonicalSize(),
                .scalar_count = 0,
                .encoding = if (offset == 0) contract.encoding_utf8 else contract.encoding_utf8_bom,
                .line_ending = contract.line_ending_crlf,
            };
        },
        contract.text_kind_document => {
            const value = text.DocumentText.init(bytes) catch |err| return textStatus(err);
            output.* = .{
                .content_offset = 0,
                .content_length = bytes.len,
                .canonical_length = bytes.len,
                .scalar_count = 0,
                .encoding = switch (value.encoding) {
                    .bytes => contract.encoding_bytes,
                    .utf8 => contract.encoding_utf8,
                    .utf8_bom => contract.encoding_utf8_bom,
                },
                .line_ending = switch (value.line_ending) {
                    .none => contract.line_ending_none,
                    .lf => contract.line_ending_lf,
                    .crlf => contract.line_ending_crlf,
                    .mixed => contract.line_ending_mixed,
                },
            };
        },
        else => return contract.status_invalid_argument,
    }
    return contract.status_ok;
}

pub export fn r4std_text_write_impl(input: [*]const u8, input_length: u64, mode: u32, output: [*]u8, output_capacity: u64, output_length: *u64) linksection(".text.r4l_exports") callconv(.c) i32 {
    const input_len = length(input_length) orelse return contract.status_invalid_argument;
    const output_len = length(output_capacity) orelse return contract.status_invalid_argument;
    const source = input[0..input_len];
    const target = output[0..output_len];
    const written = switch (mode) {
        contract.text_write_canonical => blk: {
            const value = text.SystemText.parse(source) catch |err| return textStatus(err);
            break :blk value.writeCanonical(target) catch |err| return textStatus(err);
        },
        contract.text_write_exact => blk: {
            const value = text.DocumentText.init(source) catch |err| return textStatus(err);
            break :blk value.writeExact(target) catch |err| return textStatus(err);
        },
        else => return contract.status_invalid_argument,
    };
    output_length.* = written.len;
    return contract.status_ok;
}

fn rangeFor(input: []const u8, entry: settings.Entry) contract.R4StdEntryRange {
    const base = @intFromPtr(input.ptr);
    return .{
        .key_offset = @intFromPtr(entry.key.ptr) - base,
        .key_length = entry.key.len,
        .value_offset = @intFromPtr(entry.value.ptr) - base,
        .value_length = entry.value.len,
    };
}

pub export fn r4std_settings_entry_next_impl(input: [*]const u8, input_length: u64, cursor: *u64, output: *contract.R4StdEntryRange) linksection(".text.r4l_exports") callconv(.c) i32 {
    const len = length(input_length) orelse return contract.status_invalid_argument;
    const start = length(cursor.*) orelse return contract.status_invalid_argument;
    if (start > len) return contract.status_invalid_argument;
    const bytes = input[0..len];
    var iter = settings.EntryIterator.init(bytes[start..]);
    const entry = iter.next() orelse {
        cursor.* = len;
        output.* = std.mem.zeroes(contract.R4StdEntryRange);
        return contract.status_end;
    };
    output.* = rangeFor(bytes, entry);
    cursor.* = @intFromPtr(iter.rest.ptr) - @intFromPtr(bytes.ptr);
    return contract.status_ok;
}

pub export fn r4std_settings_value_impl(input: [*]const u8, input_length: u64, key: [*]const u8, key_length: u64, output: *contract.R4StdEntryRange) linksection(".text.r4l_exports") callconv(.c) i32 {
    const len = length(input_length) orelse return contract.status_invalid_argument;
    const key_len = length(key_length) orelse return contract.status_invalid_argument;
    const bytes = input[0..len];
    const wanted = key[0..key_len];
    const value = settings.valueOf(bytes, wanted) orelse {
        output.* = std.mem.zeroes(contract.R4StdEntryRange);
        return contract.status_not_found;
    };
    const base = @intFromPtr(bytes.ptr);
    output.* = .{
        .key_offset = 0,
        .key_length = 0,
        .value_offset = @intFromPtr(value.ptr) - base,
        .value_length = value.len,
    };
    return contract.status_ok;
}

pub export fn r4std_settings_parse_scalar_impl(input: [*]const u8, input_length: u64, kind: u32, output: *u64) linksection(".text.r4l_exports") callconv(.c) i32 {
    const len = length(input_length) orelse return contract.status_invalid_argument;
    const bytes = input[0..len];
    output.* = switch (kind) {
        contract.scalar_bool => @intFromBool(settings.parseBool(bytes) orelse return contract.status_invalid_value),
        contract.scalar_u32 => settings.parseU32(bytes) orelse return contract.status_invalid_value,
        contract.scalar_i32 => @as(u32, @bitCast(settings.parseI32(bytes) orelse return contract.status_invalid_value)),
        contract.scalar_rgb24 => settings.parseRgb24(bytes) orelse return contract.status_invalid_value,
        else => return contract.status_invalid_argument,
    };
    return contract.status_ok;
}

pub export fn r4std_settings_writer_append_impl(output: [*]u8, output_capacity: u64, output_length: *u64, truncated: *u32, kind: u32, key: [*]const u8, key_length: u64, value: [*]const u8, value_length: u64, numeric_value: i64) linksection(".text.r4l_exports") callconv(.c) i32 {
    const capacity = length(output_capacity) orelse return contract.status_invalid_argument;
    const initial = length(output_length.*) orelse return contract.status_invalid_argument;
    const key_len = length(key_length) orelse return contract.status_invalid_argument;
    const value_len = length(value_length) orelse return contract.status_invalid_argument;
    if (initial > capacity) return contract.status_invalid_argument;
    var writer = settings.Writer{ .out = output[0..capacity], .len = initial, .truncated = truncated.* != 0 };
    const key_bytes = key[0..key_len];
    const value_bytes = value[0..value_len];
    switch (kind) {
        contract.writer_header => writer.writeHeader(value_bytes),
        contract.writer_comment => writer.writeComment(value_bytes),
        contract.writer_pair => writer.writePair(key_bytes, value_bytes),
        contract.writer_bool => writer.writePairBool(key_bytes, numeric_value != 0),
        contract.writer_u32 => writer.writePairU32(key_bytes, std.math.cast(u32, numeric_value) orelse return contract.status_invalid_value),
        contract.writer_i32 => writer.writePairI32(key_bytes, std.math.cast(i32, numeric_value) orelse return contract.status_invalid_value),
        contract.writer_rgb24 => writer.writePairRgb24(key_bytes, std.math.cast(u32, numeric_value) orelse return contract.status_invalid_value),
        else => return contract.status_invalid_argument,
    }
    output_length.* = writer.bytes().len;
    truncated.* = @intFromBool(!writer.ok());
    return if (writer.ok()) contract.status_ok else contract.status_buffer_too_small;
}

pub export fn r4std_settings_equals_key_impl(left: [*]const u8, left_length: u64, right: [*]const u8, right_length: u64) linksection(".text.r4l_exports") callconv(.c) u32 {
    const left_len = length(left_length) orelse return 0;
    const right_len = length(right_length) orelse return 0;
    return @intFromBool(settings.equalsKey(left[0..left_len], right[0..right_len]));
}

fn durabilityFromAbi(value: u32) ?settings.WritebackDurability {
    return switch (value) {
        contract.durability_lazy => .lazy,
        contract.durability_soon => .soon,
        contract.durability_sync => .sync,
        else => null,
    };
}

fn policyFromAbi(value: contract.R4StdWritebackPolicy) ?settings.WritebackPolicy {
    return .{
        .durability = durabilityFromAbi(value.durability) orelse return null,
        .save_delay_ticks = value.save_delay_ticks,
        .retry_delay_ticks = value.retry_delay_ticks,
    };
}

fn policyToAbi(value: settings.WritebackPolicy) contract.R4StdWritebackPolicy {
    return .{
        .durability = @intFromEnum(value.durability),
        .reserved = 0,
        .save_delay_ticks = value.save_delay_ticks,
        .retry_delay_ticks = value.retry_delay_ticks,
    };
}

fn writebackFromAbi(value: contract.R4StdWriteback) ?settings.Writeback {
    return .{
        .policy = .{
            .durability = durabilityFromAbi(value.durability) orelse return null,
            .save_delay_ticks = value.save_delay_ticks,
            .retry_delay_ticks = value.retry_delay_ticks,
        },
        .dirty = value.dirty != 0,
        .due_tick = value.due_tick,
        .failures = value.failures,
        .last_result = value.last_result,
        .failure_reported = value.failure_reported != 0,
    };
}

fn writebackToAbi(value: settings.Writeback) contract.R4StdWriteback {
    return .{
        .durability = @intFromEnum(value.policy.durability),
        .dirty = @intFromBool(value.dirty),
        .save_delay_ticks = value.policy.save_delay_ticks,
        .retry_delay_ticks = value.policy.retry_delay_ticks,
        .due_tick = value.due_tick,
        .failures = value.failures,
        .last_result = value.last_result,
        .failure_reported = @intFromBool(value.failure_reported),
        .reserved = 0,
    };
}

fn flushToAbi(value: settings.WritebackFlush) contract.R4StdWritebackFlush {
    return .{
        .action = @intFromEnum(value.action),
        .first_failure = @intFromBool(value.first_failure),
        .recovered_after_failure = @intFromBool(value.recovered_after_failure),
        .result_code = value.result_code,
    };
}

pub export fn r4std_settings_writeback_policy_impl(durability: u32, ticks_per_second: u32, output: *contract.R4StdWritebackPolicy) linksection(".text.r4l_exports") callconv(.c) i32 {
    const kind = durabilityFromAbi(durability) orelse return contract.status_invalid_argument;
    output.* = policyToAbi(settings.WritebackPolicy.forHz(kind, ticks_per_second));
    return contract.status_ok;
}

pub export fn r4std_settings_writeback_default_delay_impl(durability: u32, retry: u32) linksection(".text.r4l_exports") callconv(.c) u32 {
    const kind = durabilityFromAbi(durability) orelse return 0;
    return if (retry == 0) settings.WritebackPolicy.defaultSaveDelayMs(kind) else settings.WritebackPolicy.defaultRetryDelayMs(kind);
}

pub export fn r4std_settings_writeback_init_impl(state: *contract.R4StdWriteback, policy: *const contract.R4StdWritebackPolicy) linksection(".text.r4l_exports") callconv(.c) i32 {
    const local_policy = policyFromAbi(policy.*) orelse return contract.status_invalid_argument;
    state.* = writebackToAbi(settings.Writeback.init(local_policy));
    return contract.status_ok;
}

pub export fn r4std_settings_writeback_configure_impl(state: *contract.R4StdWriteback, policy: *const contract.R4StdWritebackPolicy, now: u64) linksection(".text.r4l_exports") callconv(.c) i32 {
    var local = writebackFromAbi(state.*) orelse return contract.status_invalid_argument;
    local.configure(policyFromAbi(policy.*) orelse return contract.status_invalid_argument, now);
    state.* = writebackToAbi(local);
    return contract.status_ok;
}

pub export fn r4std_settings_writeback_mark_dirty_impl(state: *contract.R4StdWriteback, now: u64) linksection(".text.r4l_exports") callconv(.c) i32 {
    var local = writebackFromAbi(state.*) orelse return contract.status_invalid_argument;
    local.markDirty(now);
    state.* = writebackToAbi(local);
    return contract.status_ok;
}

pub export fn r4std_settings_writeback_prepare_impl(state: *contract.R4StdWriteback, now: u64, force: u32, output: *contract.R4StdWritebackFlush) linksection(".text.r4l_exports") callconv(.c) i32 {
    if (force > 1) return contract.status_invalid_argument;
    const local = writebackFromAbi(state.*) orelse return contract.status_invalid_argument;
    if (!local.dirty) {
        output.* = flushToAbi(.{ .action = .idle, .result_code = local.last_result });
        return contract.status_ok;
    }
    if (force == 0 and !local.isDue(now)) {
        output.* = flushToAbi(.{ .action = .deferred, .result_code = local.last_result });
        return contract.status_ok;
    }
    output.* = flushToAbi(.{ .action = .deferred, .result_code = local.last_result });
    return contract.status_attempt;
}

pub export fn r4std_settings_writeback_complete_impl(state: *contract.R4StdWriteback, now: u64, result: i32, output: *contract.R4StdWritebackFlush) linksection(".text.r4l_exports") callconv(.c) i32 {
    var local = writebackFromAbi(state.*) orelse return contract.status_invalid_argument;
    output.* = flushToAbi(local.complete(now, result));
    state.* = writebackToAbi(local);
    return contract.status_ok;
}

fn dateTimeFromAbi(value: contract.R4StdDateTime) date.DateTime {
    return .{
        .date = .{ .year = value.year, .month = value.month, .day = value.day },
        .time = .{ .hour = value.hour, .minute = value.minute, .second = value.second },
    };
}

fn dateTimeToAbi(value: date.DateTime) contract.R4StdDateTime {
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

fn stateFromAbi(value: contract.R4StdTimeState) r4os.abi.TimeState {
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

fn stateToAbi(value: r4os.abi.TimeState) contract.R4StdTimeState {
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

pub export fn r4std_date_days_in_month_impl(year: u16, month: u8) linksection(".text.r4l_exports") callconv(.c) u8 {
    return date.daysInMonth(year, month);
}

pub export fn r4std_date_valid_date_impl(year: u16, month: u8, day: u8) linksection(".text.r4l_exports") callconv(.c) u32 {
    return @intFromBool(date.validDateValue(year, month, day));
}

pub export fn r4std_date_compare_date_time_impl(left: *const contract.R4StdDateTime, right: *const contract.R4StdDateTime) linksection(".text.r4l_exports") callconv(.c) i32 {
    return date.compareDateTime(dateTimeFromAbi(left.*), dateTimeFromAbi(right.*));
}

pub export fn r4std_date_weekday_number_impl(year: u16, month: u8, day: u8) linksection(".text.r4l_exports") callconv(.c) u8 {
    return date.weekdayNumber(year, month, day);
}

pub export fn r4std_date_shift_minutes_impl(input: *const contract.R4StdDateTime, delta_minutes: i32, output: *contract.R4StdShiftedDateTime) linksection(".text.r4l_exports") callconv(.c) i32 {
    const shifted = date.shiftMinutes(dateTimeFromAbi(input.*), delta_minutes) orelse return contract.status_invalid_value;
    const value = dateTimeToAbi(shifted.value);
    output.* = .{
        .year = value.year,
        .month = value.month,
        .day = value.day,
        .hour = value.hour,
        .minute = value.minute,
        .second = value.second,
        .reserved = 0,
        .day_delta = shifted.day_delta,
    };
    return contract.status_ok;
}

pub export fn r4std_date_from_time_state_impl(input: *const contract.R4StdTimeState, output: *contract.R4StdDateTime) linksection(".text.r4l_exports") callconv(.c) i32 {
    output.* = dateTimeToAbi(date.fromTimeState(stateFromAbi(input.*)) orelse return contract.status_invalid_value);
    return contract.status_ok;
}

pub export fn r4std_date_to_time_state_impl(input: *const contract.R4StdDateTime, output: *contract.R4StdTimeState) linksection(".text.r4l_exports") callconv(.c) i32 {
    output.* = stateToAbi(date.toTimeState(dateTimeFromAbi(input.*)) orelse return contract.status_invalid_value);
    return contract.status_ok;
}

pub export fn r4std_date_utc_from_date_time_impl(input: *const contract.R4StdDateTime, nanosecond: u32, output: *contract.R4StdUtcTime) linksection(".text.r4l_exports") callconv(.c) i32 {
    const value = date.utcFromDateTime(dateTimeFromAbi(input.*), nanosecond) orelse return contract.status_invalid_value;
    output.* = .{ .seconds_since_unix_epoch = value.seconds_since_unix_epoch, .nanosecond = value.nanosecond, .reserved = 0 };
    return contract.status_ok;
}

pub export fn r4std_date_date_time_from_utc_impl(input: *const contract.R4StdUtcTime, output: *contract.R4StdDateTime) linksection(".text.r4l_exports") callconv(.c) i32 {
    const value = r4os.abi.R4UtcTime{ .seconds_since_unix_epoch = input.seconds_since_unix_epoch, .nanosecond = input.nanosecond };
    output.* = dateTimeToAbi(date.dateTimeFromUtc(value) orelse return contract.status_invalid_value);
    return contract.status_ok;
}

pub export fn r4std_date_format_impl(input: *const contract.R4StdDateTime, mode: u32, clock_format: u32, output: [*]u8, output_capacity: u64, output_length: *u64) linksection(".text.r4l_exports") callconv(.c) i32 {
    const capacity = length(output_capacity) orelse return contract.status_invalid_argument;
    const target = output[0..capacity];
    const value = dateTimeFromAbi(input.*);
    const written = switch (mode) {
        contract.date_format_date_iso => date.formatDateIso(target, value.date),
        contract.date_format_datetime_iso => date.formatDateTimeIso(target, value),
        contract.date_format_datetime_minute => date.formatDateTimeMinuteDisplay(target, value, clock_format),
        else => return contract.status_invalid_argument,
    };
    if (written.len == 0) return if (date.validDateTime(value)) contract.status_buffer_too_small else contract.status_invalid_value;
    output_length.* = written.len;
    return contract.status_ok;
}

pub export fn r4std_date_parse_impl(input: [*]const u8, input_length: u64, mode: u32, output: *contract.R4StdDateTime) linksection(".text.r4l_exports") callconv(.c) i32 {
    const len = length(input_length) orelse return contract.status_invalid_argument;
    const bytes = input[0..len];
    const value = switch (mode) {
        contract.date_parse_date => date.DateTime{ .date = date.parseDateIso(bytes) orelse return contract.status_invalid_value, .time = .{} },
        contract.date_parse_time => date.DateTime{ .date = .{ .year = 1970, .month = 1, .day = 1 }, .time = date.parseTime24(bytes) orelse return contract.status_invalid_value },
        contract.date_parse_datetime => date.parseDateTimeIso(bytes) orelse return contract.status_invalid_value,
        else => return contract.status_invalid_argument,
    };
    output.* = dateTimeToAbi(value);
    return contract.status_ok;
}

pub export fn r4std_date_decode_fat_impl(date_raw: u16, time_raw: u16, mode: u32, output: *contract.R4StdDateTime) linksection(".text.r4l_exports") callconv(.c) i32 {
    const value = switch (mode) {
        contract.fat_decode_date => date.DateTime{ .date = date.decodeFatDate(date_raw) orelse return contract.status_invalid_value, .time = .{} },
        contract.fat_decode_datetime => date.decodeFatDateTime(date_raw, time_raw) orelse return contract.status_invalid_value,
        else => return contract.status_invalid_argument,
    };
    output.* = dateTimeToAbi(value);
    return contract.status_ok;
}

fn clockToAbi(value: time.ClockTime) contract.R4StdClockTime {
    return .{ .hours = value.hours, .minutes = value.minutes, .seconds = value.seconds, .reserved = 0 };
}

fn clockFromAbi(value: contract.R4StdClockTime) time.ClockTime {
    return .{ .hours = value.hours, .minutes = value.minutes, .seconds = value.seconds };
}

fn configFromAbi(value: contract.R4StdTimeConfig) time.Config {
    return .{ .timezone_index = value.timezone_index, .clock_format = value.clock_format };
}

fn configToAbi(value: time.Config) contract.R4StdTimeConfig {
    return .{ .timezone_index = @intCast(value.timezone_index), .clock_format = value.clock_format };
}

pub export fn r4std_time_zone_count_impl() linksection(".text.r4l_exports") callconv(.c) u32 {
    return @intCast(time.zoneCount());
}

pub export fn r4std_time_copy_zone_id_impl(index: u32, output: [*]u8, output_capacity: u64, output_length: *u64) linksection(".text.r4l_exports") callconv(.c) i32 {
    const capacity = length(output_capacity) orelse return contract.status_invalid_argument;
    const written = time.copyZoneId(output[0..capacity], index);
    if (written.len == 0) return contract.status_buffer_too_small;
    output_length.* = written.len;
    return contract.status_ok;
}

pub export fn r4std_time_copy_zone_label_impl(index: u32, state: *const contract.R4StdTimeState, output: [*]u8, output_capacity: u64, output_length: *u64) linksection(".text.r4l_exports") callconv(.c) i32 {
    const capacity = length(output_capacity) orelse return contract.status_invalid_argument;
    const written = time.copyZoneLabelForState(output[0..capacity], index, stateFromAbi(state.*));
    if (written.len == 0) return contract.status_buffer_too_small;
    output_length.* = written.len;
    return contract.status_ok;
}

pub export fn r4std_time_index_for_id_impl(input: [*]const u8, input_length: u64, output_index: *u32) linksection(".text.r4l_exports") callconv(.c) i32 {
    const len = length(input_length) orelse return contract.status_invalid_argument;
    output_index.* = @intCast(time.indexForId(input[0..len]) orelse return contract.status_not_found);
    return contract.status_ok;
}

pub export fn r4std_time_offset_at_state_impl(index: u32, state: *const contract.R4StdTimeState) linksection(".text.r4l_exports") callconv(.c) i32 {
    return time.offsetAtState(index, stateFromAbi(state.*));
}

pub export fn r4std_time_standard_offset_impl(index: u32) linksection(".text.r4l_exports") callconv(.c) i32 {
    return time.offsetAt(index);
}

pub export fn r4std_time_seconds_in_zone_impl(seconds_utc: u32, offset_minutes: i32) linksection(".text.r4l_exports") callconv(.c) u32 {
    const offset = std.math.cast(i16, offset_minutes) orelse return seconds_utc % time.seconds_per_day;
    return time.secondsInZone(seconds_utc, offset);
}

pub export fn r4std_time_split_time_impl(seconds: u32, output: *contract.R4StdClockTime) linksection(".text.r4l_exports") callconv(.c) i32 {
    output.* = clockToAbi(time.splitTime(seconds));
    return contract.status_ok;
}

pub export fn r4std_time_local_date_time_impl(index: u32, state: *const contract.R4StdTimeState, output: *contract.R4StdDateTime) linksection(".text.r4l_exports") callconv(.c) i32 {
    output.* = dateTimeToAbi(time.localDateTimeAtState(index, stateFromAbi(state.*)) orelse return contract.status_invalid_value);
    return contract.status_ok;
}

pub export fn r4std_time_format_clock_impl(input: *const contract.R4StdClockTime, mode: u32, clock_format: u32, output: [*]u8, output_capacity: u64, output_length: *u64) linksection(".text.r4l_exports") callconv(.c) i32 {
    const capacity = length(output_capacity) orelse return contract.status_invalid_argument;
    const target = output[0..capacity];
    const value = clockFromAbi(input.*);
    const written = switch (mode) {
        contract.time_format_display => time.formatDisplay(target, value, clock_format),
        contract.time_format_hm => time.formatHmDisplay(target, value, clock_format),
        contract.time_format_24h => time.formatHms(target, value),
        else => return contract.status_invalid_argument,
    };
    if (written.len == 0) return contract.status_buffer_too_small;
    output_length.* = written.len;
    return contract.status_ok;
}

pub export fn r4std_time_format_offset_impl(offset_minutes: i32, output: [*]u8, output_capacity: u64, output_length: *u64) linksection(".text.r4l_exports") callconv(.c) i32 {
    const capacity = length(output_capacity) orelse return contract.status_invalid_argument;
    const offset = std.math.cast(i16, offset_minutes) orelse return contract.status_invalid_value;
    const written = time.formatOffset(output[0..capacity], offset);
    if (written.len == 0) return contract.status_buffer_too_small;
    output_length.* = written.len;
    return contract.status_ok;
}

pub export fn r4std_time_config_load_impl(value: *contract.R4StdTimeConfig, input: [*]const u8, input_length: u64) linksection(".text.r4l_exports") callconv(.c) u32 {
    const len = length(input_length) orelse return 0;
    var local = configFromAbi(value.*);
    const loaded = local.loadFromBytes(input[0..len]);
    value.* = configToAbi(local);
    return @intFromBool(loaded);
}

pub export fn r4std_time_config_write_impl(value: *const contract.R4StdTimeConfig, state: *const contract.R4StdTimeState, with_state: u32, output: [*]u8, output_capacity: u64, output_length: *u64) linksection(".text.r4l_exports") callconv(.c) i32 {
    if (with_state > 1) return contract.status_invalid_argument;
    const capacity = length(output_capacity) orelse return contract.status_invalid_argument;
    const local = configFromAbi(value.*);
    const written = if (with_state == 0) local.writeTo(output[0..capacity]) else local.writeToForState(output[0..capacity], stateFromAbi(state.*));
    if (written.len == 0) return contract.status_buffer_too_small;
    output_length.* = written.len;
    return contract.status_ok;
}

pub export fn r4std_time_config_normalize_impl(value: *contract.R4StdTimeConfig) linksection(".text.r4l_exports") callconv(.c) i32 {
    var local = configFromAbi(value.*);
    local.setIndex(local.timezone_index);
    local.setClockFormat(local.clock_format);
    value.* = configToAbi(local);
    return contract.status_ok;
}

pub export fn r4std_time_config_offset_impl(value: *const contract.R4StdTimeConfig, state: *const contract.R4StdTimeState) linksection(".text.r4l_exports") callconv(.c) i32 {
    return configFromAbi(value.*).offsetMinutesForState(stateFromAbi(state.*));
}

const Caller = union(enum) {
    legacy: r4os.program.Bundle,
    generation2: r4os.platform2.Context,

    fn system(self: *const Caller) r4os.r4sys.Context {
        return switch (self.*) {
            .legacy => r4os.r4sys.Context.init(&self.legacy),
            .generation2 => r4os.r4sys.Context.fromProgram(.{ .generation2 = &self.generation2 }),
        };
    }
};

// CONFIG_V1 carries a caller-owned opaque context address. Admit its actual
// generation before taking a typed view; retain that view for this call only.
fn callerContext(address: u64) ?Caller {
    if (address == 0 or address % @alignOf(u64) != 0) return null;
    const magic: *const u32 = @ptrFromInt(address);
    if (magic.* == r4os.platform2.abi.start_magic) {
        const raw: *const r4os.platform2.abi.R4XStartContext2 = @ptrFromInt(address);
        return .{ .generation2 = r4os.platform2.Context.init(raw) catch return null };
    }
    if (magic.* != r4os.abi.r4xstart_magic) return null;
    const raw: *const r4os.abi.R4XStartContext = @ptrFromInt(address);
    return .{ .legacy = r4os.program.bundleValueFromR4XStart(raw) orelse return null };
}

fn pathZ(pointer: [*]const u8, raw_length: u64, storage: *[config.max_path_len + 1]u8) ?[*:0]const u8 {
    const len = length(raw_length) orelse return null;
    if (len == 0 or len >= storage.len) return null;
    const bytes = pointer[0..len];
    if (std.mem.indexOfScalar(u8, bytes, 0) != null) return null;
    @memset(storage[0..], 0);
    @memcpy(storage[0..len], bytes);
    return @ptrCast(storage.ptr);
}

pub export fn r4std_config_read_impl(caller_context: u64, path: [*]const u8, path_length: u64, key: [*]const u8, key_length: u64, kind: u32, fallback: [*]const u8, fallback_length: u64, fallback_scalar: i64, output: [*]u8, output_capacity: u64, output_scalar: *u64) linksection(".text.r4l_exports") callconv(.c) i32 {
    const caller = callerContext(caller_context) orelse return contract.status_unavailable;
    const sys = caller.system();
    var path_storage: [config.max_path_len + 1]u8 = undefined;
    const file_path = pathZ(path, path_length, &path_storage) orelse return config.error_invalid_path;
    const key_len = length(key_length) orelse return config.error_invalid_key;
    const fallback_len = length(fallback_length) orelse return config.error_invalid_value;
    const out_len = length(output_capacity) orelse return config.error_buffer_too_small;
    const key_bytes = key[0..key_len];
    output_scalar.* = 0;
    return switch (kind) {
        contract.config_kind_string => config.readString(&sys, file_path, key_bytes, fallback[0..fallback_len], output[0..out_len]),
        contract.config_kind_bool => blk: {
            var value = fallback_scalar != 0;
            const result = config.readBool(&sys, file_path, key_bytes, value, &value);
            output_scalar.* = @intFromBool(value);
            break :blk result;
        },
        contract.config_kind_u32 => blk: {
            var value = std.math.cast(u32, fallback_scalar) orelse return config.error_invalid_value;
            const result = config.readU32(&sys, file_path, key_bytes, value, &value);
            output_scalar.* = value;
            break :blk result;
        },
        contract.config_kind_i32 => blk: {
            var value = std.math.cast(i32, fallback_scalar) orelse return config.error_invalid_value;
            const result = config.readI32(&sys, file_path, key_bytes, value, &value);
            output_scalar.* = @as(u32, @bitCast(value));
            break :blk result;
        },
        contract.config_kind_rgb24 => blk: {
            var value = std.math.cast(u32, fallback_scalar) orelse return config.error_invalid_value;
            const result = config.readRgb24(&sys, file_path, key_bytes, value, &value);
            output_scalar.* = value;
            break :blk result;
        },
        else => contract.status_invalid_argument,
    };
}

pub export fn r4std_config_write_impl(caller_context: u64, path: [*]const u8, path_length: u64, key: [*]const u8, key_length: u64, kind: u32, value: [*]const u8, value_length: u64, scalar_value: i64) linksection(".text.r4l_exports") callconv(.c) i32 {
    const caller = callerContext(caller_context) orelse return contract.status_unavailable;
    const sys = caller.system();
    var path_storage: [config.max_path_len + 1]u8 = undefined;
    const file_path = pathZ(path, path_length, &path_storage) orelse return config.error_invalid_path;
    const key_len = length(key_length) orelse return config.error_invalid_key;
    const value_len = length(value_length) orelse return config.error_invalid_value;
    const key_bytes = key[0..key_len];
    return switch (kind) {
        contract.config_kind_string => config.writeString(&sys, file_path, key_bytes, value[0..value_len]),
        contract.config_kind_bool => config.writeBool(&sys, file_path, key_bytes, scalar_value != 0),
        contract.config_kind_u32 => config.writeU32(&sys, file_path, key_bytes, std.math.cast(u32, scalar_value) orelse return config.error_invalid_value),
        contract.config_kind_i32 => config.writeI32(&sys, file_path, key_bytes, std.math.cast(i32, scalar_value) orelse return config.error_invalid_value),
        contract.config_kind_rgb24 => config.writeRgb24(&sys, file_path, key_bytes, std.math.cast(u32, scalar_value) orelse return config.error_invalid_value),
        else => contract.status_invalid_argument,
    };
}

pub export fn r4std_config_save_document_impl(caller_context: u64, path: [*]const u8, path_length: u64, input: [*]const u8, input_length: u64) linksection(".text.r4l_exports") callconv(.c) i32 {
    const caller = callerContext(caller_context) orelse return contract.status_unavailable;
    const sys = caller.system();
    var path_storage: [config.max_path_len + 1]u8 = undefined;
    const file_path = pathZ(path, path_length, &path_storage) orelse return config.error_invalid_path;
    const len = length(input_length) orelse return config.error_invalid_value;
    return config.saveDocument(&sys, file_path, input[0..len]);
}

pub export fn r4std_config_recover_document_impl(caller_context: u64, path: [*]const u8, path_length: u64) linksection(".text.r4l_exports") callconv(.c) i32 {
    const caller = callerContext(caller_context) orelse return contract.status_unavailable;
    const sys = caller.system();
    var path_storage: [config.max_path_len + 1]u8 = undefined;
    const file_path = pathZ(path, path_length, &path_storage) orelse return config.error_invalid_path;
    return config.recoverDocumentSave(&sys, file_path);
}

pub export fn r4std_config_has_leftovers_impl(caller_context: u64, path: [*]const u8, path_length: u64) linksection(".text.r4l_exports") callconv(.c) u32 {
    const caller = callerContext(caller_context) orelse return 1;
    const sys = caller.system();
    var path_storage: [config.max_path_len + 1]u8 = undefined;
    const file_path = pathZ(path, path_length, &path_storage) orelse return 1;
    return @intFromBool(config.hasDocumentSaveLeftovers(&sys, file_path));
}

pub export fn r4std_config_ensure_dirs_impl(caller_context: u64, kind: u32) linksection(".text.r4l_exports") callconv(.c) i32 {
    const caller = callerContext(caller_context) orelse return contract.status_unavailable;
    const sys = caller.system();
    switch (kind) {
        contract.ensure_dirs_system => settings.ensureSystemDirs(&sys),
        contract.ensure_dirs_apps => settings.ensureAppDirs(&sys),
        contract.ensure_dirs_desktop => settings.ensureDesktopDirs(&sys),
        else => return contract.status_invalid_argument,
    }
    return contract.status_ok;
}

pub export var r4std_text_v1: contract.TextV1 align(8) linksection(".data.r4l_exports") = .{
    .header = contract.text_v1_header,
    .inspect = r4std_text_inspect_impl,
    .write = r4std_text_write_impl,
};

pub export var r4std_settings_v1: contract.SettingsV1 align(8) linksection(".data.r4l_exports") = .{
    .header = contract.settings_v1_header,
    .entry_next = r4std_settings_entry_next_impl,
    .value = r4std_settings_value_impl,
    .parse_scalar = r4std_settings_parse_scalar_impl,
    .writer_append = r4std_settings_writer_append_impl,
    .equals_key = r4std_settings_equals_key_impl,
    .writeback_policy = r4std_settings_writeback_policy_impl,
    .writeback_default_delay = r4std_settings_writeback_default_delay_impl,
    .writeback_init = r4std_settings_writeback_init_impl,
    .writeback_configure = r4std_settings_writeback_configure_impl,
    .writeback_mark_dirty = r4std_settings_writeback_mark_dirty_impl,
    .writeback_prepare = r4std_settings_writeback_prepare_impl,
    .writeback_complete = r4std_settings_writeback_complete_impl,
};

pub export var r4std_date_v1: contract.DateV1 align(8) linksection(".data.r4l_exports") = .{
    .header = contract.date_v1_header,
    .days_in_month = r4std_date_days_in_month_impl,
    .valid_date = r4std_date_valid_date_impl,
    .compare_date_time = r4std_date_compare_date_time_impl,
    .weekday_number = r4std_date_weekday_number_impl,
    .shift_minutes = r4std_date_shift_minutes_impl,
    .from_time_state = r4std_date_from_time_state_impl,
    .to_time_state = r4std_date_to_time_state_impl,
    .utc_from_date_time = r4std_date_utc_from_date_time_impl,
    .date_time_from_utc = r4std_date_date_time_from_utc_impl,
    .format = r4std_date_format_impl,
    .parse = r4std_date_parse_impl,
    .decode_fat = r4std_date_decode_fat_impl,
};

pub export var r4std_time_v1: contract.TimeV1 align(8) linksection(".data.r4l_exports") = .{
    .header = contract.time_v1_header,
    .zone_count = r4std_time_zone_count_impl,
    .copy_zone_id = r4std_time_copy_zone_id_impl,
    .copy_zone_label = r4std_time_copy_zone_label_impl,
    .index_for_id = r4std_time_index_for_id_impl,
    .offset_at_state = r4std_time_offset_at_state_impl,
    .seconds_in_zone = r4std_time_seconds_in_zone_impl,
    .split_time = r4std_time_split_time_impl,
    .local_date_time = r4std_time_local_date_time_impl,
    .format_clock = r4std_time_format_clock_impl,
    .format_offset = r4std_time_format_offset_impl,
    .config_load = r4std_time_config_load_impl,
    .config_write = r4std_time_config_write_impl,
    .config_normalize = r4std_time_config_normalize_impl,
    .config_offset = r4std_time_config_offset_impl,
    .standard_offset = r4std_time_standard_offset_impl,
};

pub export var r4std_config_v1: contract.ConfigV1 align(8) linksection(".data.r4l_exports") = .{
    .header = contract.config_v1_header,
    .read = r4std_config_read_impl,
    .write = r4std_config_write_impl,
    .save_document = r4std_config_save_document_impl,
    .recover_document = r4std_config_recover_document_impl,
    .has_leftovers = r4std_config_has_leftovers_impl,
    .ensure_dirs = r4std_config_ensure_dirs_impl,
};

pub export fn r4std_codec_legacy_decode_impl(codepage: u32, mode: u32, byte: u32, scalar: *u32) linksection(".text.r4l_exports") callconv(.c) i32 {
    const value = codec.legacyDecode(codepage, mode, byte) catch |err| return codec.status(err);
    scalar.* = value;
    return contract.status_ok;
}

pub export fn r4std_codec_legacy_encode_impl(codepage: u32, mode: u32, scalar: u32, byte: *u8) linksection(".text.r4l_exports") callconv(.c) i32 {
    const value = codec.legacyEncode(codepage, mode, scalar) catch |err| return codec.status(err);
    byte.* = value;
    return contract.status_ok;
}

pub export fn r4std_codec_utf8_decode_impl(input: [*]const u8, input_length: u64, output: *contract.R4StdScalarResult) linksection(".text.r4l_exports") callconv(.c) i32 {
    const len = length(input_length) orelse return contract.status_invalid_argument;
    switch (codec.decode(input[0..len])) {
        .complete => |value| {
            output.* = value;
            return contract.status_ok;
        },
        .incomplete => |required| {
            output.* = .{ .scalar = 0, .byte_length = 0, .required = required, .reserved = 0 };
            return contract.codec_incomplete;
        },
        .invalid => return contract.status_invalid_text,
    }
}

pub export fn r4std_codec_utf8_encode_impl(scalar: u32, output: [*]u8, output_capacity: u64, written: *u32) linksection(".text.r4l_exports") callconv(.c) i32 {
    const len = length(output_capacity) orelse return contract.status_invalid_argument;
    const count = codec.encode(scalar, output[0..len]) catch |err| return codec.status(err);
    written.* = count;
    return contract.status_ok;
}

pub export fn r4std_codec_utf8_push_impl(state: *contract.R4StdUtf8State, byte: u32, output: *contract.R4StdScalarResult) linksection(".text.r4l_exports") callconv(.c) i32 {
    return codec.push(state, byte, output);
}

pub export fn r4std_codec_utf8_finish_impl(state: *const contract.R4StdUtf8State) linksection(".text.r4l_exports") callconv(.c) i32 {
    return codec.finish(state);
}

pub export var r4std_codec_v1: contract.CodecV1 align(8) linksection(".data.r4l_exports") = .{
    .header = contract.codec_v1_header,
    .legacy_decode = r4std_codec_legacy_decode_impl,
    .legacy_encode = r4std_codec_legacy_encode_impl,
    .utf8_decode = r4std_codec_utf8_decode_impl,
    .utf8_encode = r4std_codec_utf8_encode_impl,
    .utf8_push = r4std_codec_utf8_push_impl,
    .utf8_finish = r4std_codec_utf8_finish_impl,
};

pub export var r4std_query: r4os.abi.R4LQuery align(8) linksection(".data.r4l_exports") = .{
    .magic = r4os.abi.r4l_abi_magic,
    .abi_version = r4os.abi.r4l_abi_version,
    .size = r4os.abi.r4l_query_struct_size,
    .group = 0,
    .kernel_bridge = 0,
    .reserved = 0,
};

test "R4STD preserves five interfaces and adds independent scalar codecs" {
    try std.testing.expectEqual(@as(u32, 0), r4std_query.group);
    try std.testing.expectEqual(contract.text_v1_header.interface_id_lo, r4std_text_v1.header.interface_id_lo);
    try std.testing.expectEqual(contract.codec_v1_header.interface_id_lo, r4std_codec_v1.header.interface_id_lo);
    try std.testing.expectEqual(contract.settings_v1_header.interface_id_lo, r4std_settings_v1.header.interface_id_lo);
    try std.testing.expectEqual(contract.date_v1_header.interface_id_lo, r4std_date_v1.header.interface_id_lo);
    try std.testing.expectEqual(contract.time_v1_header.interface_id_lo, r4std_time_v1.header.interface_id_lo);
    try std.testing.expectEqual(contract.config_v1_header.interface_id_lo, r4std_config_v1.header.interface_id_lo);
}

// Technical generation2 query; independent interfaces keep their revisions.
pub export var r4std_query2: r4os.platform2.abi.R4LQuery2 align(8) linksection(".data.r4l_exports") = .{};
