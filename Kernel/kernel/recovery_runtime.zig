// Recovery owns this boot ordering. The normal runtime assumes an already
// mounted physical boot device; Recovery first admits its RAM filesystem.
const task = @import("../sched/task.zig");
const scheduler = @import("../sched/scheduler.zig");
const memory_reclaim = @import("../memory/reclaim.zig");
const page_cache = @import("../fs/page_cache.zig");
const platform_boot = @import("platform_boot.zig");
const smp = @import("smp.zig");
const service_ipc = @import("service_ipc.zig");
const driver_work = @import("driver_work.zig");
const log = @import("log.zig");

var initialized = false;

pub fn initTasks() bool {
    if (initialized) return true;
    if (!task.init()) return false;
    memory_reclaim.registerTaskStackReclaimer(task.reclaimStackCache);
    if (!scheduler.init()) return false;
    const acpi = platform_boot.acpiInfo() orelse return false;
    if (!smp.startApplicationProcessors(acpi)) return false;
    smp.activate();
    if (!service_ipc.startRuntimeWorker() or !driver_work.init() or !page_cache.startPolicyWorker()) return false;
    initialized = true;
    log.puts("[RECOVERY] tasks=READY services=READY driver_work=READY\r\n");
    return true;
}
