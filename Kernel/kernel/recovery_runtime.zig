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

const std = @import("std");
const block = @import("../storage/block.zig");
const drive = @import("../fs/drive.zig");
const vfs = @import("../fs/vfs.zig");
const fs_request = @import("../fs/request.zig");
const boot_config = @import("boot_config.zig");
const modules = @import("modules.zig");
const fonts = @import("font_catalog.zig");
const memory_boot = @import("memory_boot.zig");
const fatal = @import("fatal.zig");
const boot_perf = @import("boot_perf.zig");
const keyboard = @import("../driver/input/keyboard.zig");
const r4d = @import("../program/r4d.zig");
const r4p = @import("../program/r4p.zig");
const r4x = @import("../program/r4x.zig");
const timer = @import("timer.zig");
const terminal_path = "/R4OS/SOFTWARE/TERMINAL/TERMINAL.R4X";

pub fn admitFilesystem() bool {
    if (!initialized or !block.initRuntimeWorker()) return false;
    @import("module_file.zig").restrictExecutionToDrive('C');
    const volume = vfs.volumeForDrive('C') orelse return false;
    for ([_][]const u8{ "/CONFIG.R4S", "/R4OS/CONFIG/RECOVERY.R4S", "/R4OS/CONFIG/VERSION.R4S", "/R4OS/CONFIG/SERVICES.R4S", terminal_path, "/R4OS/LIBS/R4STD.R4L" }) |path| {
        const entry = vfs.resolveEntry(volume, path) orelse {
            log.puts("[RECOVERYRAM] required-file=missing path=");
            log.puts(path);
            log.puts("\r\n");
            return false;
        };
        if (entry.isDir() or entry.size == 0) return false;
    }
    modules.loadSystemLibraries();
    if (modules.resolveExportAddress("R4STD", "DATE_V1", 1) == null or modules.resolveExportAddress("R4STD", "TIME_V1", 1) == null) return false;
    _ = boot_config.load();
    r4d.discoverAll();
    r4p.loadAll();
    const font_result = fonts.reloadInstalled();
    if (font_result.unavailable or font_result.registered < 2 or font_result.rejected != 0) return false;
    log.puts("[RECOVERYRAM] userland=READY R4L=R4STD fonts=READY modules=on-demand\r\n");
    return true;
}

pub fn startShell() noreturn {
    // Userland owns the complete display after admission. Background kernel
    // diagnostics keep their serial sink without painting over that display.
    log.setConsoleSink(null);
    r4x.initializeRuntime(memory_boot.usableBytes());
    if (!writeBootMedium()) log.puts("[RECOVERY] boot-medium-description=unavailable\r\n");
    if (!writeBootFacts()) log.puts("[RECOVERY] boot-content-identity=unavailable\r\n");
    @import("recovery_network.zig").start();
    const config = boot_config.get();
    const args = if (@import("config").recovery_probe == .ui) "/UISMOKE" else boot_config.shellArgs(config);
    if (!launchShellPath(boot_config.shellPath(config), args))
        fatal.kernelFatal(.shell, "Recovery menu admission failed");
    var ready = false;
    while (r4x.activeShellInstanceId() != 0) {
        if (!ready and boot_perf.snapshot().state == .ready) {
            ready = true;
            log.puts("[RECOVERY] shell=READY\r\n");
        }
        scheduler.sleepTicks(@max(1, timer.frequency() / (if (ready) @as(u32, 1) else 10)));
    }
    fatal.kernelFatal(.shell, "Recovery menu exited unexpectedly");
}

fn writeBootMedium() bool {
    const source = @import("recovery_storage.zig").source;
    var buffer: [256]u8 = undefined;
    const text = std.fmt.bufPrint(&buffer, "Boot medium: {s}; slot: {s}\r\n", .{
        if (!source.confirmed) "unknown" else if (source.usb) "USB" else "LOCAL",
        @tagName(source.slot),
    }) catch return false;
    const volume = vfs.volumeForDrive('C') orelse return false;
    var request = fs_request.begin(.file_write, 'C') orelse return false;
    var ok = false;
    defer fs_request.finish(&request, ok);
    const parent = vfs.resolvePath(volume, "/R4OS/CONFIG") orelse return false;
    ok = vfs.writeFile(volume, parent, "BOOTMED.TXT", text);
    return ok;
}

fn writeBootFacts() bool {
    const identity = @import("recovery_identity.zig");
    const source = @import("recovery_storage.zig").source;
    const boot = @import("../bootloader/boot_info.zig").get().executable_source;
    const config = @import("config");
    if (!identity.valid or !source.confirmed) return false;
    const guid = @import("../storage/partition_table.zig").guid;
    var buffer: [1024]u8 = undefined;
    const text = std.fmt.bufPrint(&buffer,
        "\xef\xbb\xbfR4S_FORMAT=1\r\nSCHEMA=RECOVERY_BOOT\r\nSTATE_VERSION=1\r\n" ++
        "DISK_GUID={s}\r\nPARTITION_GUID={s}\r\nSLOT={s}\r\n" ++
        "RECOVERY_VERSION={s}\r\nKERNEL_VERSION={s}\r\nKERNEL_BYTES={d}\r\nKERNEL_SHA256={s}\r\nRUNTIME_BYTES={d}\r\nRUNTIME_SHA256={s}\r\n",
        .{ guid.format(boot.disk_guid), guid.format(boot.partition_guid), @tagName(source.slot),
        config.recovery_version, @import("version.zig").text, identity.elf_bytes,
        std.fmt.bytesToHex(identity.elf_sha256, .lower), config.runtime_bytes, config.runtime_sha256 }) catch return false;
    const volume = vfs.volumeForDrive('C') orelse return false;
    var request = fs_request.begin(.file_write, 'C') orelse return false;
    var ok = false;
    defer fs_request.finish(&request, ok);
    const parent = vfs.resolvePath(volume, "/R4OS/CONFIG") orelse return false;
    ok = vfs.writeFile(volume, parent, "RECBOOT.R4S", text);
    return ok;
}

pub fn launchTerminal() bool {
    return launchShellPath(terminal_path, "/NOAUTOEXEC");
}

fn launchShellPath(path: []const u8, args: []const u8) bool {
    r4x.initializeRuntime(memory_boot.usableBytes());
    const boot_drive = drive.get('C') orelse return false;
    // With no external console host, the standard shell consumes the physical
    // keyboard directly. terminal_mode expects a host to forward input.
    boot_perf.beginShellAttempt(.configured);
    if (r4x.runShellPathWithHost(boot_drive, path, args, boot_drive, .none) != .ran) {
        boot_perf.noteShellLaunchFailure();
        return false;
    }
    boot_perf.noteShellLaunched(r4x.activeShellInstanceId());
    log.puts("[RECOVERYRAM] shell=STARTED\r\n");
    return true;
}

// Diagnostic-only guest path. The host removes the actual USB boot device
// and its block backends, verifies their absence, then sends the F key.
pub fn waitForMediaRemoval() bool {
    log.puts("[RECOVERYRAM] boot-medium=WAIT\r\n");
    const deadline = timer.deadlineAfter(timer.tickCount(), @as(u64, timer.frequency()) * 30);
    var detached = false;
    while (timer.tickCount() < deadline) {
        if (keyboard.readChar()) |key| {
            if (key == 'f' or key == 'F') {
                detached = true;
                break;
            }
        }
        scheduler.sleepTicks(1);
    }
    if (!detached or drive.get('R') != null) return false;
    log.puts("[RECOVERYRAM] boot-medium=DETACHED-CONTINUE\r\n");
    return true;
}

pub fn runRamProbe() bool {
    if (smp.status().online != 4) return false;
    if (!r4d.runtimeLoadSucceeded(r4d.loadRuntimeNameResult("XHCI"))) return false;
    if (!r4p.hasActiveR4p("format.json") or !std.mem.eql(u8, r4p.requiredSourceName("format.json"), "r4p")) return false;
    if (!checkLateMedia()) return false;
    r4x.initializeRuntime(memory_boot.usableBytes());
    const before = r4x.programRegistryStats();
    if (!runCommand("/C HELP /?", "HELP.R4X - R4OS terminal help")) return false;
    if (!runCommand("/C TYPE C:\\R4OS\\CONFIG\\RECOVERY.R4S", "RUNTIME_VOLUME=RAM")) return false;
    if (!runCommand("/C ECHO RAM_WRITE_OK > C:\\TEMP\\LATE.TXT", "")) return false;
    if (!runCommand("/C TYPE C:\\TEMP\\LATE.TXT", "RAM_WRITE_OK")) return false;
    if (!runCommand("/C SERVMAN /?", "SERVMAN - R4OS Service Manager")) return false;
    if (!runCommand("/C DATE", "")) return false;
    if (!runCommand("/C DEL C:\\TEMP\\LATE.TXT", "")) return false;
    const reap_deadline = timer.deadlineAfter(timer.tickCount(), @as(u64, timer.frequency()) * 5);
    while (timer.tickCount() < reap_deadline) {
        const after = r4x.programRegistryStats();
        if (after.live_slots == before.live_slots and after.reserved_slots == 0 and after.retiring_slots == 0 and after.pinned_slots == 0) break;
        scheduler.sleepTicks(1);
    }
    const after = r4x.programRegistryStats();
    if (after.live_slots != before.live_slots or after.reserved_slots != 0 or after.retiring_slots != 0 or after.pinned_slots != 0) return false;
    log.puts("[RECOVERYRAM] result=OK cpus=4 late_modules=R4X,R4D,R4P R4L=R4STD media=OK write_read_delete=OK child_stdio=OK cleanup=OK\r\n");
    return true;
}

fn runCommand(args: []const u8, expected: []const u8) bool {
    const d = drive.get('C') orelse return false;
    var output: [4096]u8 = undefined;
    r4x.beginOutputCapture(&output);
    const result = r4x.runPath(d, terminal_path, args, d);
    const captured = r4x.endOutputCapture();
    const ok = result == .ran and r4x.lastExitCode() == 0 and !captured.truncated and std.mem.indexOf(u8, output[0..captured.len], expected) != null;
    log.puts("[RECOVERYRAM] command=");
    log.puts(args);
    log.puts(if (ok) " result=OK\r\n" else " result=FAILED\r\n");
    if (!ok) log.puts(output[0..captured.len]);
    return ok;
}

fn checkLateMedia() bool {
    const volume = vfs.volumeForDrive('C') orelse return false;
    var request = fs_request.begin(.file_read, 'C') orelse return false;
    var ok = false;
    defer fs_request.finish(&request, ok);
    const entry = vfs.resolveEntry(volume, "/R4OS/MEDIA/RECOVERY.BMP") orelse return false;
    var offset: usize = 0;
    var buffer: [4096]u8 = undefined;
    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    while (offset < entry.size) {
        const count: usize = @min(buffer.len, entry.size - offset);
        const got = vfs.readFileRange(volume, entry, offset, buffer[0..count]) orelse return false;
        if (got != count) return false;
        hasher.update(buffer[0..count]);
        offset += count;
    }
    var digest: [32]u8 = undefined;
    hasher.final(&digest);
    var expected: [32]u8 = undefined;
    _ = std.fmt.hexToBytes(&expected, "be7137ab201586fb805ab3b1c7a648224cad32210b14e0985c1256edecb40e16") catch return false;
    ok = std.mem.eql(u8, &digest, &expected);
    return ok;
}
