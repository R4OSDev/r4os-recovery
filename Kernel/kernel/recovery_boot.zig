const std = @import("std");
const boot_info = @import("../bootloader/boot_info.zig");
const heap = @import("../memory/heap.zig");
const task = @import("../sched/task.zig");
const scheduler = @import("../sched/scheduler.zig");
const percpu = @import("../arch/x86_64/percpu.zig");
const smp = @import("smp.zig");
const timer = @import("timer.zig");
const log = @import("log.zig");

// The normal PMM admits only MemoryKind.usable. Limine kernel/module ranges
// must therefore cover every byte of a boot module before memory startup.
// No Recovery path reclaims these ranges or bootloader strings during boot.
pub fn modulesReserved() bool {
    for (boot_info.bootModules()) |module| {
        const start = boot_info.hhdmToPhys(@intFromPtr(module.address)) orelse return false;
        const end = std.math.add(u64, start, module.size) catch return false;
        var cursor = start;
        while (cursor < end) {
            var next = cursor;
            for (boot_info.memoryMap()) |entry| {
                if (entry.valid and entry.kind == .kernel_and_modules and entry.base <= cursor and entry.end > cursor)
                    next = @max(next, @min(end, entry.end));
            }
            if (next == cursor) return false;
            cursor = next;
        }
    }
    return true;
}

var done: u32 = 0;
var failures: u32 = 0;
var cpu_mask: u64 = 0;

// A small real-guest witness for CPU placement, wait/wake, heap ownership and
// retained Limine payloads. It is excluded from the normal kernel artifact.
pub fn runProbe() bool {
    if (smp.status().online != 4 or percpu.schedulableMask() != 15) return false;
    if (!probePayloadIntact()) return false;
    @atomicStore(u32, &done, 0, .release);
    @atomicStore(u32, &failures, 0, .release);
    @atomicStore(u64, &cpu_mask, 0, .release);
    for (0..4) |cpu| {
        const worker = task.createParallelWorkerBlocked("recovery-probe", workerMain) orelse return false;
        if (!task.bindBlockedHomeCpu(worker, @intCast(cpu))) return false;
        task.markReady(worker, timer.tickCount());
        smp.sendReschedule(@intCast(cpu));
    }
    const begin = timer.tickCount();
    const limit = timer.deadlineAfter(begin, @as(u64, timer.frequency()) * 5);
    while (@atomicLoad(u32, &done, .acquire) != 4 and timer.tickCount() < limit) scheduler.sleepTicks(1);
    if (@atomicLoad(u32, &done, .acquire) != 4 or @atomicLoad(u32, &failures, .acquire) != 0 or
        @atomicLoad(u64, &cpu_mask, .acquire) != 15 or timer.tickCount() <= begin or !modulesReserved() or !probePayloadIntact()) return false;
    log.puts("[RECOVERYPROBE] result=OK cpus=4 workers=4 mask=0xf module_bytes=4096 system=absent\r\n");
    return true;
}

fn probePayloadIntact() bool {
    var found = false;
    for (boot_info.bootModules()) |module| {
        if (!std.mem.endsWith(u8, module.path, "/probe.bin")) continue;
        if (found or module.size != 4096) return false;
        for (module.address[0..module.size], 0..) |byte, index| {
            if (byte != @as(u8, @truncate(index * 37 + 11))) return false;
        }
        found = true;
    }
    return found;
}

fn workerMain() callconv(.c) void {
    const cpu = percpu.currentIndex();
    const buffer = heap.alloc(4096, 64) orelse {
        _ = @atomicRmw(u32, &failures, .Add, 1, .acq_rel);
        _ = @atomicRmw(u32, &done, .Add, 1, .acq_rel);
        scheduler.exitCurrentAndRetire();
    };
    @memset(buffer, @intCast(cpu + 1));
    scheduler.sleepTicks(2);
    for (buffer) |byte| {
        if (byte != cpu + 1) {
            _ = @atomicRmw(u32, &failures, .Add, 1, .acq_rel);
            break;
        }
    }
    if (heap.free(buffer) != .ok) _ = @atomicRmw(u32, &failures, .Add, 1, .acq_rel);
    _ = @atomicRmw(u64, &cpu_mask, .Or, @as(u64, 1) << @intCast(cpu), .acq_rel);
    _ = @atomicRmw(u32, &done, .Add, 1, .acq_rel);
    scheduler.exitCurrentAndRetire();
}
