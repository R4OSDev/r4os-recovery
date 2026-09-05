// Recovery owns the startup plan; protocol, NIC and service implementations
// remain the explicitly imported canonical modules.
const core = @import("../net/core.zig");
const net_config = @import("../net/config.zig");
const net_services = @import("../net/ipc_services.zig");
const boot_config = @import("boot_config.zig");
const service_ipc = @import("service_ipc.zig");
const task = @import("../sched/task.zig");
const drive = @import("../fs/drive.zig");
const r4d = @import("../program/r4d.zig");
const r4p = @import("../program/r4p.zig");
const r4x = @import("../program/r4x.zig");
const log = @import("log.zig");

pub fn start() void {
    core.init();
    net_config.applyBootConfig(boot_config.get());
    service_ipc.init();
    net_services.init();
    // Resolve lazy R4P images before entering a NIC owner or receiving IRQs.
    for ([_][]const u8{ "net.ethernet", "net.arp", "net.ipv4", "net.icmp", "net.udp", "net.tcp", "net.dns", "net.dhcp" }) |role| {
        if (!r4p.hasActiveR4p(role)) {
            log.puts("[RECOVERYNET] protocol=unavailable role=");
            log.puts(role);
            log.puts("\r\n");
            return;
        }
    }
    for ([_][]const u8{ "VIRTNET", "RTL8139", "RTL8168" }) |name| {
        const result = r4d.loadRuntimeNameResult(name);
        log.puts("[RECOVERYNET] driver=");
        log.puts(name);
        log.puts(" result=");
        log.puts(r4d.runtimeLoadResultName(result));
        log.puts("\r\n");
    }
    const rx = core.startRxTask();
    const dhcp = core.startDhcpTask();
    if (!rx or !dhcp) {
        log.puts("[RECOVERYNET] workers=unavailable\r\n");
        return;
    }
    // DHCP and service readiness never hold up the local menu.
    if (task.createKernelThreadWithRole("recovery-services", startServices, .batch) == null)
        log.puts("[RECOVERYNET] autostart=unavailable\r\n");
}

fn startServices() callconv(.c) void {
    const ram = drive.get('C') orelse return;
    const result = r4x.runPath(ram, "/R4OS/SOFTWARE/TERMINAL/SERVMAN.R4X", "BOOT", ram);
    log.puts(if (result == .ran and r4x.lastExitCode() == 0) "[RECOVERYNET] autostart=RETURNED\r\n" else "[RECOVERYNET] autostart=FAILED\r\n");
}
