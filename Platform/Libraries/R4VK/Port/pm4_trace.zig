// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
// Opt-in, process-owned CPU command trace. No GPU reads, file mutations,
// retained caller memory, packet changes or synthetic completion receipts.
const std = @import("std");
const a = @import("r4os").abi;
const threads = @import("r4native").threads;

fn function(comptime name: []const u8) @field(a.R4SysFns, name) {
    return threads.system.required(name);
}

pub const State = struct {
    enabled: bool = false,
    sequence: std.atomic.Value(u32) = .init(0),
    failed: std.atomic.Value(bool) = .init(false),

    pub fn init(self: *State) void {
        self.* = .{};
        var option: [2]u8 = @splat(0);
        const count = function("env_get")("R4VK_PM4_TRACE", &option, option.len);
        self.enabled = count == 1 and option[0] == '1';
    }

    fn write(self: *State, text: []const u8) bool {
        if (function("write")(text.ptr, @intCast(text.len)) == @as(i32, @intCast(text.len))) return true;
        self.failed.store(true, .release);
        return false;
    }

    // First 32 streams, at most 8192 dwords each. Each line is one write and
    // carries its stream/word index so concurrent console output is detectable.
    // Trace failure or bounds never changes the submission's result.
    pub fn record(self: *State, engine: u32, group: u32, index: u32, count: u32, address: u64, words: [*]const u32, dwords: u32) void {
        if (!self.enabled or self.failed.load(.acquire)) return;
        const sequence = self.sequence.fetchAdd(1, .monotonic);
        if (sequence >= 32) return;
        var line: [256]u8 = undefined;
        if (dwords == 0 or dwords > 8192 or count == 0 or count > 32 or index >= count or group > 3 or engine > 1) {
            _ = self.write(std.fmt.bufPrint(&line, "R4VK-PM28 SKIP seq={d} dwords={d}\n", .{ sequence, dwords }) catch unreachable);
            return;
        }
        if (!self.write(std.fmt.bufPrint(&line, "R4VK-PM28 BEGIN seq={d} engine={d} group={d} index={d} count={d} va={x:0>16} dwords={d}\n", .{
            sequence, engine, group, index, count, address, dwords,
        }) catch unreachable)) return;
        var offset: u32 = 0;
        while (offset < dwords) {
            const n = @min(@as(u32, 8), dwords - offset);
            const prefix = std.fmt.bufPrint(&line, "R4VK-PM28 DATA seq={d} dw={d}", .{ sequence, offset }) catch unreachable;
            var used = prefix.len;
            for (words[offset..][0..n]) |word| {
                const part = std.fmt.bufPrint(line[used..], " {x:0>8}", .{word}) catch unreachable;
                used += part.len;
            }
            line[used] = '\n';
            if (!self.write(line[0 .. used + 1])) return;
            offset += n;
        }
        _ = self.write(std.fmt.bufPrint(&line, "R4VK-PM28 END seq={d} dwords={d}\n", .{ sequence, dwords }) catch unreachable);
    }
};
