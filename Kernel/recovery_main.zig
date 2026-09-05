// Independent Recovery boot orchestration. Common mechanisms remain in the
// pinned kernel owners; no SYSTEM scan, desktop or normal update recovery.
const std = @import("std");
const config = @import("config");
const boot_info = @import("bootloader/boot_info.zig");
const boot_display = @import("display/boot_display.zig");
const interrupts = @import("arch/x86_64/interrupts.zig");
const power = @import("arch/x86_64/power.zig");
const reset = @import("arch/x86_64/reset.zig");
const crash = @import("kernel/crash.zig");
const fatal = @import("kernel/fatal.zig");
const log = @import("kernel/log.zig");
const boot_status = @import("kernel/boot_status.zig");
const com_debug_boot = @import("kernel/com_debug_boot.zig");
const cpu_boot = @import("kernel/cpu_boot.zig");
const timer_boot = @import("kernel/timer_boot.zig");
const driver_boot = @import("kernel/driver_boot.zig");
const input_boot = @import("kernel/input_boot.zig");
const memory_boot = @import("kernel/memory_boot.zig");
const storage_boot = @import("kernel/storage_boot.zig");
const platform_boot = @import("kernel/platform_boot.zig");
const platform_irq_boot = @import("kernel/platform_irq_boot.zig");
const module_boot = @import("kernel/module_boot.zig");
const service_boot = @import("kernel/service_boot.zig");
const recovery_runtime = @import("kernel/recovery_runtime.zig");
const version = @import("kernel/version.zig");
const recovery_boot = @import("kernel/recovery_boot.zig");
const recovery_ram = @import("kernel/recovery_ram.zig");
const recovery_storage = @import("kernel/recovery_storage.zig");

pub const panic = std.debug.FullPanic(handleZigPanic);

export fn kmain() callconv(.c) noreturn {
    version.keepMetadata();
    boot_info.keepRequests();
    crash.init();
    fatal.init();
    fatal.setBootPhase(.entry);
    com_debug_boot.init();
    require(boot_info.init(), .entry, "Recovery BootInfo missing");
    require(!boot_info.get().memory_map_truncated and boot_info.get().memory_map_invalid_entries == 0, .memory, "Recovery memory map incomplete");
    _ = boot_display.init();
    log.puts("R4OS Recovery " ++ config.recovery_version ++ " / Kernel " ++ version.text ++ "\r\n");
    boot_status.beginBootLogRedirect();
    fatal.setBootPhase(.cpu);
    cpu_boot.init();
    fatal.setBootPhase(.timer);
    timer_boot.init();
    fatal.setBootPhase(.driver);
    driver_boot.init();
    fatal.setBootPhase(.input);
    input_boot.initKeyboard();
    input_boot.completePs2();
    require(recovery_boot.modulesReserved(), .memory, "Recovery boot module memory not reserved");
    require(memory_boot.initCore(), .memory, "Recovery memory foundation failed");
    require(storage_boot.initFoundation(), .storage, "Recovery block foundation failed");
    module_boot.init();
    require(platform_boot.initDeviceMappings(), .platform, "Recovery platform mappings failed");
    service_boot.init();
    require(platform_irq_boot.init(), .irq, "Recovery IRQ foundation failed");
    require(recovery_runtime.initTasks(), .task_runtime, "Recovery task foundation failed");
    interrupts.enable();
    require(recovery_boot.modulesReserved(), .memory, "Recovery boot module reservation lost");
    log.puts("[RECOVERY] foundation=READY system_required=0\r\n");
    if (comptime config.recovery_probe == .poweroff or config.recovery_probe == .reboot) {
        require(recovery_boot.runProbe(), .runtime, "Recovery foundation probe failed");
        log.serialFlush();
        if (comptime config.recovery_probe == .reboot) reset.reboot();
        power.poweroff();
    }

    require(recovery_ram.mount(), .storage, "Recovery RAM image rejected");
    if (comptime config.recovery_probe == .ram)
        require(recovery_runtime.waitForMediaRemoval(), .storage, "Recovery boot medium removal not acknowledged");
    require(recovery_runtime.admitFilesystem(), .loader, "Recovery RAM userland admission failed");
    if (comptime config.recovery_probe != .ram)
        require(recovery_storage.init(), .storage, "Recovery media admission failed");
    boot_status.releaseForUserSession();
    log.setOutputHook(null);
    if (comptime config.recovery_probe == .ram) {
        require(recovery_runtime.runRamProbe(), .runtime, "Recovery RAM runtime probe failed");
        log.serialFlush();
        power.poweroff();
    }
    if (comptime config.recovery_probe == .storage) {
        require(recovery_storage.runProbe(), .storage, "Recovery storage probe failed");
        log.serialFlush();
        power.poweroff();
    }
    recovery_runtime.startShell();
}

fn require(ok: bool, phase: crash.BootPhase, message: []const u8) void {
    if (!ok) fatal.haltPendingOrMessage(phase, message);
    fatal.setBootPhase(phase);
}

fn handleZigPanic(message: []const u8, address: ?usize) noreturn {
    if (address) |value| {
        log.puts("[RECOVERY] panic-ret=0x");
        log.putHex(value, 16);
        log.puts("\r\n");
    }
    fatal.zigPanic(message);
}
