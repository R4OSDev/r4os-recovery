//! Recovery's required current-SDK RDRAND leaf admission. CPU metadata is
//! captured on each actual initialized CPU before runtime publication. No
//! synthetic entropy device, random pool or timer/identity seed is created.
const std = @import("std");
const c = @import("../program/generation2.zig").abi.shared;
const percpu = @import("../arch/x86_64/percpu.zig");
const interrupts = @import("../arch/x86_64/interrupts.zig");
const io = @import("../arch/x86_64/io.zig");
const task_context = @import("../sched/task_context.zig");
const scheduler = @import("../sched/scheduler.zig");
const monotonic = @import("monotonic.zig");
const window = @import("cpu_acceleration_window.zig");
extern fn r4os_read_cr0() callconv(.c) u64;
const Record = struct { epoch: u64 = 0, sequence: u64 = 0, signature: u32 = 0, ecx: u32 = 0, xcr0: u64 = 0, baseline: bool = false };
var records: [percpu.max_cpus]Record = @splat(.{});
var exhausted: [percpu.max_cpus]bool = @splat(false);
const Cpuid = struct { eax: u32, ebx: u32, ecx: u32, edx: u32 };
fn cpuid(leaf: u32, sub: u32) Cpuid {
    var a: u32 = undefined;
    var b: u32 = undefined;
    var x: u32 = undefined;
    var d: u32 = undefined;
    asm volatile ("cpuid"
        : [a] "={eax}" (a),
          [b] "={ebx}" (b),
          [x] "={ecx}" (x),
          [d] "={edx}" (d),
        : [leaf] "{eax}" (leaf),
          [sub] "{ecx}" (sub),
    );
    return .{ .eax = a, .ebx = b, .ecx = x, .edx = d };
}
fn xcr0() u64 {
    var low: u32 = undefined;
    var high: u32 = undefined;
    asm volatile ("xgetbv"
        : [lo] "={eax}" (low),
          [hi] "={edx}" (high),
        : [index] "{ecx}" (@as(u32, 0)),
    );
    return (@as(u64, high) << 32) | low;
}
/// Startup owner only: BSP after FPU initialization, AP after local FPU and
/// scheduler setup, before its parked/qualified/online publication.
pub fn captureCurrentCpu() void {
    const index = percpu.currentIndex();
    var result: Record = .{};
    const old = records[index];
    if (exhausted[index]) return;
    if (old.epoch == std.math.maxInt(u64) or old.sequence == std.math.maxInt(u64)) {
        exhausted[index] = true;
        records[index] = .{};
        return;
    }
    result.epoch = old.epoch + 1;
    result.sequence = old.sequence + 1;
    const maximum = cpuid(0, 0).eax;
    if (maximum >= 1) {
        const leaf = cpuid(1, 0);
        result.signature = leaf.eax;
        result.ecx = leaf.ecx;
        if (leaf.ecx & (@as(u32, 1) << 27) != 0) result.xcr0 = xcr0();
        result.baseline = maximum >= 7 and cpuid(7, 0).ebx & 32 != 0 and result.xcr0 & 7 == 7 and r4os_read_cr0() & 12 == 0;
    }
    records[index] = result;
}
fn mask(record: Record) u64 {
    return if (record.ecx & (@as(u32, 1) << 30) != 0) c.cpu_accel_feature_rdrand else 0;
}
fn valid(comptime T: type, out: *const T) bool {
    return @intFromPtr(out) % @alignOf(T) == 0 and out.version == 1 and out.size >= @sizeOf(T);
}
pub fn info(out: *c.CpuAccelerationInfo) callconv(.c) i32 {
    if (!valid(c.CpuAccelerationInfo, out)) return c.cpu_capabilities_error_invalid;
    const saved = interrupts.saveAndDisableLocal();
    defer interrupts.restoreLocal(saved);
    const index = percpu.currentIndex();
    const record = records[index];
    if (record.epoch == 0 or percpu.state(index) != .online) return c.cpu_capabilities_error_unsupported;
    var configured: u32 = 0;
    var known: u32 = 0;
    var common: u64 = c.cpu_accel_feature_rdrand;
    for (0..percpu.max_cpus) |i| {
        if (percpu.state(@intCast(i)) == .absent) continue;
        configured += 1;
        if (percpu.state(@intCast(i)) != .online or records[i].epoch == 0) continue;
        known += 1;
        common &= mask(records[i]);
    }
    const virtual = record.ecx & (@as(u32, 1) << 31) != 0;
    out.* = .{ .cpu_index = index, .epoch = record.epoch, .capture_sequence = record.sequence, .hardware_mask = mask(record), .os_mask = if (record.baseline) mask(record) else 0, .common_hardware_mask = if (known == configured) common else 0, .xcr0 = record.xcr0, .signature = record.signature, .configured_cpus = configured, .common_known_count = known, .feature_count = 1, .flags = c.cpu_accel_info_flag_online | (if (virtual) c.cpu_accel_info_flag_virtual else @as(u32, 0)) |
        (if (record.baseline) c.cpu_accel_info_flag_baseline_ready else @as(u32, 0)) |
        (if (known == configured) c.cpu_accel_info_flag_common_complete else @as(u32, 0)) };
    return 0;
}
const Native = struct {
    index: u32,
    epoch: u64,
    sequence: u64,
    clock: monotonic.Stamp,
    callback: c.CpuPureWorkFn,
    context: u64,
    pub fn current(self: *const Native) bool {
        return io.readRflags() & 512 == 0 and percpu.currentIndex() == self.index and
            records[self.index].epoch == self.epoch and records[self.index].sequence == self.sequence and
            percpu.state(self.index) == .online and percpu.isSchedulable(self.index);
    }
    pub fn now(self: *const Native) ?u64 {
        if (!self.current()) return null;
        const stamp = monotonic.capture();
        if (stamp.kind != self.clock.kind or stamp.generation != self.clock.generation) return null;
        return monotonic.resolve(stamp);
    }
    pub fn work(self: *const Native, iterations: u32) i32 {
        return self.callback(self.context, iterations);
    }
};
pub fn work(kind: u32, iterations: u32, raw_slot: ?*const c.CpuPureWorkFn, context: u64, out: *c.CpuAccelerationWork) callconv(.c) i32 {
    const slot = raw_slot orelse return c.cpu_capabilities_error_invalid;
    if (!valid(c.CpuAccelerationWork, out) or @intFromPtr(slot) % @alignOf(c.CpuPureWorkFn) != 0 or
        @as(*const usize, @ptrCast(slot)).* == 0 or iterations == 0 or iterations > c.cpu_accel_max_iterations) return c.cpu_capabilities_error_invalid;
    if (kind != c.cpu_accel_work_kind_rdrand) return c.cpu_capabilities_error_unsupported;
    if (io.readRflags() & 512 == 0 or interrupts.inRuntimeCriticalSection() or scheduler.current() == null) return c.cpu_capabilities_error_context;
    const saved = interrupts.saveAndDisableLocal();
    var restored = false;
    defer if (!restored) interrupts.restoreLocal(saved);
    const token = task_context.enterUnwind();
    defer _ = task_context.leaveUnwind(token);
    if (!token.context_present or !token.active) return c.cpu_capabilities_error_context;
    const index = percpu.currentIndex();
    const record = records[index];
    if (record.epoch == 0 or !record.baseline or !percpu.isSchedulable(index) or percpu.state(index) != .online or mask(record) == 0) return c.cpu_capabilities_error_unsupported;
    // A cached hint never authorizes the actual optional instruction. Recheck
    // this physical CPU and its enabled local SIMD state inside the IF=0 leaf.
    const local = cpuid(1, 0);
    if (local.eax != record.signature or local.ecx & (@as(u32, 1) << 30) == 0 or
        local.ecx & (@as(u32, 1) << 27) == 0 or xcr0() & 7 != 7 or r4os_read_cr0() & 12 != 0) return c.cpu_capabilities_error_unsupported;
    const stamp = monotonic.capture();
    if ((stamp.kind != .tsc and stamp.kind != .hpet) or stamp.generation == 0) return c.cpu_capabilities_error_unsupported;
    const native: Native = .{ .index = index, .epoch = record.epoch, .sequence = record.sequence, .clock = stamp, .callback = slot.*, .context = context };
    const initial: c.CpuAccelerationWork = .{ .cpu_index = index, .epoch = record.epoch, .capture_sequence = record.sequence, .work_kind = kind, .iterations = iterations, .granted_mask = c.cpu_accel_feature_rdrand, .xcr0 = record.xcr0, .original_if = saved & 512, .clock_source = @intFromEnum(stamp.kind), .clock_generation = stamp.generation, .flags = if (record.ecx & (@as(u32, 1) << 31) != 0) c.cpu_accel_work_flag_virtual else 0 };
    var value = window.run(initial, &native);
    interrupts.restoreLocal(saved);
    restored = true;
    value.final_if = io.readRflags() & 512;
    if (value.final_if == value.original_if) value.flags |= c.cpu_accel_work_flag_if_preserved else {
        value.flags &= ~c.cpu_accel_work_flag_identity_valid;
        value.status = c.cpu_accel_work_status_identity_changed;
    }
    out.* = value;
    return 0;
}
