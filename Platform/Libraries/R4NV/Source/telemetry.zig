// NVIDIA 570.144/src/common/sdk/nvidia/inc/class/cl00de.h
// /*
//  * SPDX-FileCopyrightText: Copyright (c) 2022-2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
//  * SPDX-License-Identifier: MIT
//  *
//  * Permission is hereby granted, free of charge, to any person obtaining a
//  * copy of this software and associated documentation files (the "Software"),
//  * to deal in the Software without restriction, including without limitation
//  * the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  * and/or sell copies of the Software, and to permit persons to whom the
//  * Software is furnished to do so, subject to the following conditions:
//  *
//  * The above copyright notice and this permission notice shall be included in
//  * all copies or substantial portions of the Software.
//  *
//  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  * DEALINGS IN THE SOFTWARE.
//  */
// NVIDIA 570.144/src/common/sdk/nvidia/inc/nvfixedtypes.h
// /*
//  * SPDX-FileCopyrightText: Copyright (c) 1993-2022 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
//  * SPDX-License-Identifier: MIT
//  *
//  * Permission is hereby granted, free of charge, to any person obtaining a
//  * copy of this software and associated documentation files (the "Software"),
//  * to deal in the Software without restriction, including without limitation
//  * the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  * and/or sell copies of the Software, and to permit persons to whom the
//  * Software is furnished to do so, subject to the following conditions:
//  *
//  * The above copyright notice and this permission notice shall be included in
//  * all copies or substantial portions of the Software.
//  *
//  * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  * DEALINGS IN THE SOFTWARE.
//  */
//! Exact 570.144 RM User Shared Data decoder. Firmware owns the shared page.
//! Clock values are firmware-reported targets, not frequency measurements.
//! Host freshness tracks observed changes without assuming a GPU clock epoch.
const std = @import("std");

pub const shared_bytes = 464;
pub const page_bytes = 4096;
pub const sequence_start: u64 = 0xff00000000000000;
pub const attempts = 10;
pub const poll_clock: u64 = 1;
pub const poll_perf: u64 = 2;
pub const poll_power: u64 = 8;
pub const poll_thermal: u64 = 16;
pub const poll_mask = poll_clock | poll_perf | poll_power | poll_thermal;

pub const Field = enum(u8) {
    clocks, throttle, utilization, pstate, power_limit,
    gpu_temperature, memory_temperature, average_power, instantaneous_power,
};
pub const field_count = std.meta.fields(Field).len;
pub const fields = std.enums.values(Field);
pub const Spec = struct { offset: usize, bytes: usize, group: u64 };
pub fn spec(field: Field) Spec {
    return switch (field) {
        .clocks => .{ .offset = 72, .bytes = 24, .group = poll_clock },
        .throttle => .{ .offset = 96, .bytes = 16, .group = poll_perf },
        .utilization => .{ .offset = 112, .bytes = 48, .group = poll_perf },
        .pstate => .{ .offset = 264, .bytes = 16, .group = poll_perf },
        .power_limit => .{ .offset = 280, .bytes = 16, .group = poll_power },
        .gpu_temperature => .{ .offset = 296, .bytes = 16, .group = poll_thermal },
        .memory_temperature => .{ .offset = 312, .bytes = 16, .group = poll_thermal },
        .average_power => .{ .offset = 368, .bytes = 24, .group = poll_power },
        .instantaneous_power => .{ .offset = 392, .bytes = 24, .group = poll_power },
    };
}
pub fn validSequence(value: u64) bool {
    return if (value < sequence_start) value != 0 else value & 1 == 0;
}
pub const Status = enum { unavailable, changing, malformed, awaiting_change, fresh, stale };
pub const Reading = struct {
    status: Status = .unavailable,
    sequence: u64 = 0,
    // Max payload is perfDevUtil's 40 bytes. Padding is never interpreted.
    words: [10]u32 = @splat(0),

    pub fn usable(self: Reading) bool { return self.status == .fresh; }
    pub fn pstateIndex(self: Reading) ?u4 {
        const value = self.words[0];
        if (!self.usable() or value == 0 or value > 0x8000 or value & (value - 1) != 0) return null;
        return @intCast(@ctz(value));
    }
    pub fn targetClocksHz(self: Reading) ?[4]u64 {
        if (!self.usable()) return null;
        var result: [4]u64 = undefined;
        for (&result, self.words[0..4]) |*output, mhz| output.* = @as(u64, mhz) * 1_000_000;
        return result;
    }
    pub fn temperatureMilliCelsius(self: Reading) ?i64 {
        if (!self.usable()) return null;
        const fixed: i32 = @bitCast(self.words[0]);
        return @divTrunc(@as(i64, fixed) * 1000, 256);
    }
};

/// Reader must provide bounded load64/load32 and an acquire/load fence. It
/// owns its coherent CPU mapping for the entire call; no pointer is retained.
pub fn read(reader: anytype, field: Field) !Reading {
    const description = spec(field);
    var had_writer = false;
    for (0..attempts) |_| {
        const before = try reader.load64(description.offset);
        try reader.barrier();
        if (!validSequence(before)) {
            had_writer = had_writer or before != 0;
            continue;
        }
        var result: Reading = .{ .status = .fresh, .sequence = before };
        for (0..(description.bytes - 8) / 4) |index|
            result.words[index] = try reader.load32(description.offset + 8 + index * 4);
        try reader.barrier();
        const after = try reader.load64(description.offset);
        if (after != before) { had_writer = true; continue; }
        if (field == .pstate and result.pstateIndex() == null) return .{ .status = .malformed, .sequence = before };
        if (field == .utilization) {
            if (result.words[0] > 100 or result.words[1] > 100) return .{ .status = .malformed, .sequence = before };
            for (0..4) |engine| if (result.words[2 + engine * 2] > 100)
                return .{ .status = .malformed, .sequence = before };
        }
        return result;
    }
    // Never expose the final torn copy after exhausting retries.
    return .{ .status = if (had_writer) .changing else .unavailable };
}

pub const Snapshot = struct {
    sampled_host_ns: u64 = 0,
    fields: [field_count]Reading = @splat(.{}),
    pub fn get(self: *const Snapshot, field: Field) Reading { return self.fields[@intFromEnum(field)]; }
};
pub const Tracker = struct {
    const Entry = struct { sequence: u64 = 0, changed_host_ns: ?u64 = null, value: Reading = .{}, faulted: bool = false };
    entries: [field_count]Entry = @splat(.{}),
    mask: u64 = 0,
    last_host_ns: u64 = 0,

    /// Before enabling/re-enabling a polling group, baseline its current
    /// contents. An old valid stamp must advance before it can become fresh.
    pub fn begin(self: *Tracker, reader: anytype, mask: u64, now: u64) !void {
        if (mask & ~poll_mask != 0 or now == 0) return error.Parameter;
        var next = self.*;
        for (fields) |field| {
            const index = @intFromEnum(field);
            if (mask & spec(field).group == 0) {
                next.entries[index] = .{};
            } else if (self.mask & spec(field).group == 0) {
                const value = try read(reader, field);
                next.entries[index] = .{ .sequence = value.sequence, .value = .{ .status = .awaiting_change } };
            }
        }
        next.mask = mask;
        next.last_host_ns = now;
        self.* = next;
    }

    pub fn sample(self: *Tracker, reader: anytype, now: u64, max_age_ns: u64) !Snapshot {
        if (now == 0 or max_age_ns == 0 or now < self.last_host_ns) return error.Clock;
        var result: Snapshot = .{ .sampled_host_ns = now };
        var next = self.*;
        for (fields) |field| {
            const index = @intFromEnum(field);
            if (self.mask & spec(field).group == 0) continue;
            const value = try read(reader, field);
            const entry = &next.entries[index];
            if (entry.faulted) {
                entry.value = .{ .status = .malformed, .sequence = entry.sequence };
            } else if (!value.usable()) {
                entry.value = value;
            } else if (now - self.last_host_ns > max_age_ns) {
                // After a long observation gap the change may itself be old.
                // Baseline now and wait for the next actual firmware update.
                entry.sequence = value.sequence;
                entry.changed_host_ns = null;
                entry.value = .{ .status = .awaiting_change, .sequence = value.sequence };
            } else if (value.sequence != entry.sequence) {
                // A regressing firmware timestamp invalidates this group;
                // a new runtime/poll baseline is needed to establish freshness.
                if (value.sequence < sequence_start and entry.sequence < sequence_start and value.sequence < entry.sequence) {
                    entry.faulted = true;
                    entry.value = .{ .status = .malformed, .sequence = value.sequence };
                } else {
                    entry.sequence = value.sequence;
                    entry.changed_host_ns = now;
                    entry.value = value;
                }
            } else if (entry.changed_host_ns) |changed| {
                entry.value = if (now - changed <= max_age_ns) value else .{ .status = .stale, .sequence = value.sequence };
            } else entry.value = .{ .status = .awaiting_change, .sequence = value.sequence };
            result.fields[index] = entry.value;
        }
        next.last_host_ns = now;
        self.* = next;
        return result;
    }
};
