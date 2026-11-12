const r4os = @import("r4os");

const mb: u64 = 1024 * 1024;
const kb: u64 = 1024;
const version_file_max: usize = 256;
const inventory_file_max: usize = 2048;
const version_unknown = "unknown";

const App = struct {
    sys: r4os.r4sys.Context,
    dev: r4os.r4dev.Context,
    net: r4os.r4net.Context,

    fn init(r4_app: *r4os.App2) ?App {
        return .{
            .sys = r4_app.system(),
            .dev = r4_app.devicesLowLevel() orelse return null,
            .net = r4_app.networkLowLevel() orelse return null,
        };
    }

    fn write(self: *const App, text: []const u8) void {
        self.sys.write(text);
    }

    fn line(self: *const App, text: []const u8) void {
        self.write(text);
        self.write("\r\n");
    }

    fn writeDec(self: *const App, value: u64) void {
        self.sys.printU64(value);
    }

    fn writeHex(self: *const App, value: u64) void {
        self.write("0x");
        var shift: u6 = 60;
        while (true) {
            const nibble: u8 = @intCast((value >> shift) & 0xF);
            self.write(&[_]u8{if (nibble < 10) '0' + nibble else 'A' + (nibble - 10)});
            if (shift == 0) break;
            shift -= 4;
        }
    }

    fn writeZ(self: *const App, value: []const u8) void {
        const text = spanZ(value);
        if (text.len == 0) {
            self.write("-");
        } else {
            self.write(text);
        }
    }

    fn writeBytes(self: *const App, value: u64) void {
        if (value >= mb) {
            self.writeDec(value / mb);
            self.write(" MB");
        } else if (value >= kb) {
            self.writeDec(value / kb);
            self.write(" KB");
        } else {
            self.writeDec(value);
            self.write(" bytes");
        }
    }
};

const DeviceCounts = struct {
    storage: u32 = 0,
    network: u32 = 0,
    display: u32 = 0,
    usb: u32 = 0,
};

const bus_driver: u8 = 8;
const bus_storage: u8 = 4;
const bus_usb: u8 = 10;
const bus_protocol: u8 = 11;

pub fn r4_app_main(r4_app: *r4os.App2) i32 {
    const app = App.init(r4_app) orelse return r4os.abi.err_no_group;
    const args = zSlice(app.sys.argsRaw());
    const test_mode = argsContain(args, "/TEST") or argsContain(args, "TEST");
    const driver_mode = argsContain(args, "/DRIVERS") or argsContain(args, "DRIVERS");
    const storage_mode = argsContain(args, "/STORAGE") or argsContain(args, "STORAGE");
    const usb_hid_mode = argsContain(args, "/USBHID") or argsContain(args, "USBHID");
    const usb_msc_mode = argsContain(args, "/USBMSC") or argsContain(args, "USBMSC");

    if (driver_mode) {
        const ok = runDriverRegistrySelftest(&app);
        if (test_mode) app.line(if (ok) "SYSINFO result: OK" else "SYSINFO result: FAILED");
        return if (ok) 0 else 1;
    }

    if (storage_mode) {
        const ok = runStorageSelftest(&app);
        if (test_mode) app.line(if (ok) "SYSINFO result: OK" else "SYSINFO result: FAILED");
        return if (ok) 0 else 1;
    }

    if (usb_hid_mode) {
        const ok = runUsbHidSelftest(&app);
        if (test_mode) app.line(if (ok) "SYSINFO result: OK" else "SYSINFO result: FAILED");
        return if (ok) 0 else 1;
    }

    if (usb_msc_mode) {
        const ok = runUsbMscSelftest(&app);
        if (test_mode) app.line(if (ok) "SYSINFO result: OK" else "SYSINFO result: FAILED");
        return if (ok) 0 else 1;
    }

    const ok = runReport(&app);
    if (test_mode) app.line(if (ok) "SYSINFO result: OK" else "SYSINFO result: FAILED");
    return if (ok) 0 else 1;
}

fn runReport(app: *const App) bool {
    var ok = app.sys.contractValid();

    app.line("SYSINFO.R4X");
    app.line("==========");
    app.line("");
    printSystem(app, &ok);
    printTime(app);
    printHardware(app, &ok);
    printMemory(app, &ok);
    printDrives(app, &ok);
    printDevices(app, &ok);
    printNetwork(app);
    app.line("");
    app.line("Details: DMESG, HWDIAG.R4X, BOOTINFO.R4X, MEMVIEW.R4X, DEVMGR.R4X, IPCONFIG.R4X");
    return ok;
}

fn printSystem(app: *const App, ok: *bool) void {
    var version_data: [version_file_max]u8 = undefined;
    var inventory_data: [inventory_file_max]u8 = undefined;

    app.line("System");
    label(app, "Release");
    app.line(releaseVersion(app, version_data[0..]));

    const active = app.dev.kernelVersion();
    var active_text_buffer: [32]u8 = undefined;
    label(app, "Kernel active");
    app.line(if (active) |value| r4os.version_info.formatKernelVersion(value, active_text_buffer[0..]) orelse version_unknown else version_unknown);

    const installed = installedKernelVersion(app, inventory_data[0..]);
    label(app, "Kernel installed");
    app.write(installed);
    if (active) |value| {
        if (r4os.version_info.restartRequired(value, installed)) app.write(" (restart required)");
    }
    app.line("");
    label(app, "R4SYS ABI");
    app.write("v");
    app.writeDec(app.sys.tableAbiVersion());
    app.write(" size=");
    app.writeDec(app.sys.tableSize());
    app.line(if (app.sys.contractValid()) " ok" else " incompatible");
    if (!app.sys.contractValid()) ok.* = false;

    label(app, "Bootloader");
    if (app.dev.bootInfoSummary()) |boot| {
        app.writeZ(boot.bootloader_name[0..]);
        app.write(" entries=");
        app.writeDec(boot.memory_map_count);
        app.line("");
    } else {
        app.line("not available");
        ok.* = false;
    }
}

fn printTime(app: *const App) void {
    const time = app.sys.timeState();
    app.line("");
    app.line("Time");
    label(app, "Timer");
    app.write(backendName(time.monotonic_backend));
    app.write(" ");
    app.writeDec(time.monotonic_hz);
    app.write(" Hz ticks=");
    app.writeDec(time.monotonic_ticks);
    app.line("");

    label(app, "RTC");
    if (time.valid != 0) {
        writeDateTime(app, time);
    } else {
        app.write("invalid");
    }
    app.line("");
}

fn printHardware(app: *const App, ok: *bool) void {
    app.line("");
    app.line("Hardware");
    const hw = app.dev.hardwareSummary() orelse {
        label(app, "Snapshot");
        app.line("not available");
        ok.* = false;
        return;
    };

    label(app, "Bus");
    if ((hw.flags & r4os.abi.hardware_summary_flag_pcie) != 0) {
        app.write("PCIe ECAM");
    } else if ((hw.flags & r4os.abi.hardware_summary_flag_legacy_pci) != 0) {
        app.write("Legacy PCI");
    } else {
        app.write("none");
        ok.* = false;
    }
    app.write(" pcie=");
    app.writeDec(hw.pcie_devices);
    app.write(" pci=");
    app.writeDec(hw.legacy_pci_devices);
    app.line("");

    label(app, "ACPI");
    app.write(if ((hw.flags & r4os.abi.hardware_summary_flag_acpi) != 0) "active" else "missing");
    app.write(" tables=");
    app.writeDec(hw.acpi_tables);
    app.write(" invalid=");
    app.writeDec(hw.acpi_invalid_tables);
    app.line("");

    label(app, "IRQ/Timer");
    app.write(irqControllerName(hw.irq_controller));
    app.write(" ");
    app.write(timerBackendName(hw.timer_backend));
    app.write(" lapic=");
    app.writeDec(hw.lapic_count);
    app.write(" ioapic=");
    app.writeDec(hw.ioapic_count);
    if (hw.hpet_frequency_hz != 0) {
        app.write(" hpet=");
        app.writeDec(hw.hpet_frequency_hz);
        app.write("Hz");
    }
    app.line("");

    label(app, "Devices");
    app.write("storage=");
    app.writeDec(hw.storage_controllers);
    app.write(" block=");
    app.writeDec(hw.block_devices);
    app.write(" usb=");
    app.writeDec(hw.usb_devices);
    app.write("/");
    app.writeDec(hw.usb_configured);
    app.write(" net=");
    app.writeDec(hw.network_controllers);
    app.write(" display=");
    app.writeDec(hw.display_controllers);
    app.line("");

    label(app, "Runtime");
    app.write("drivers=");
    app.writeDec(hw.driver_records);
    app.write(" protocols=");
    app.writeDec(hw.protocol_records);
    app.write(" cpu-logical=");
    app.writeDec(hw.cpu_logical_processors);
    app.line("");
}

fn printMemory(app: *const App, ok: *bool) void {
    app.line("");
    app.line("Memory");
    if (app.dev.memorySummary()) |mem| {
        label(app, "Physical RAM");
        app.writeBytes(mem.physical_bytes);
        app.line("");
        label(app, "Free physical");
        app.writeBytes(mem.free_physical_bytes);
        app.line("");
        label(app, "Committed");
        app.writeBytes(mem.committed_bytes);
        app.line("");
        label(app, "Blocks");
        app.writeDec(mem.active_blocks);
        app.write(" active, ");
        app.writeDec(mem.released_blocks);
        app.write(" released");
        if (mem.error_blocks != 0) {
            app.write(", ");
            app.writeDec(mem.error_blocks);
            app.write(" errors");
            ok.* = false;
        }
        if (mem.overflow != 0) {
            app.write(", overflow");
            ok.* = false;
        }
        app.line("");
        if (app.dev.memoryPressure()) |pressure| {
            label(app, "Pressure");
            app.write("level=");
            app.writeDec(pressure.pressure_level);
            app.write(" app-avail=");
            app.writeBytes(pressure.app_available_bytes);
            app.write(" headroom=");
            app.writeBytes(pressure.commit_headroom_bytes);
            app.write(" reclaimable=");
            app.writeBytes(pressure.reclaimable_bytes);
            app.line("");
        } else {
            label(app, "Pressure");
            app.line("not available");
            ok.* = false;
        }
        printPaging(app, ok);
    } else {
        label(app, "Snapshot");
        app.line("not available");
        ok.* = false;
    }
}

fn printPaging(app: *const App, ok: *bool) void {
    const paging = app.dev.pagingSummary() orelse {
        label(app, "Paging");
        app.line("not available");
        ok.* = false;
        return;
    };

    const cr3_match = (paging.flags & r4os.abi.paging_flag_active_root_matches_hardware) != 0;
    const r4os_active = (paging.flags & r4os.abi.paging_flag_r4os_root_active) != 0;
    const cr3_switched = (paging.flags & r4os.abi.paging_flag_cr3_switch_done) != 0;
    if (!cr3_match or !r4os_active or !cr3_switched) ok.* = false;

    label(app, "Paging");
    app.write(if (r4os_active) "R4OS PML4" else "not R4OS");
    app.write(", CR3 ");
    app.write(if (cr3_match) "match" else "mismatch");
    app.write(", root=");
    app.writeHex(paging.active_root_phys);
    app.line("");

    label(app, "PageTables");
    app.writeDec(paging.page_table_blocks);
    app.write(" blocks kernel=");
    app.writeDec(paging.kernel_page_table_blocks);
    app.write(" bootloader=");
    app.writeDec(paging.bootloader_page_table_blocks);
    app.line("");

    label(app, "Limine PT");
    app.writeDec(paging.limine_quarantined_frames);
    app.write(" quarantined, ");
    app.writeDec(paging.limine_released_frames);
    app.write(" released, ");
    app.writeDec(paging.limine_retained_frames);
    app.write(" retained");
    app.line("");
}

fn printDrives(app: *const App, ok: *bool) void {
    app.line("");
    app.line("Drives");
    var mounted: u32 = 0;
    var index: u32 = 0;
    while (index < 26) : (index += 1) {
        const info = app.sys.driveInfo(index) orelse continue;
        if (info.mounted == 0) continue;
        mounted += 1;
        app.write("  ");
        app.sys.putc(info.letter);
        app.write(": ");
        app.write(driveKindName(info.kind));
        app.write(" ");
        app.write(driveRoleName(info.role));
        app.write(" ");
        app.writeZ(info.name[0..]);
        app.write(" total=");
        app.writeBytes(info.bytes);
        if (info.free_bytes != 0) {
            app.write(" free=");
            app.writeBytes(info.free_bytes);
        }
        app.line("");
    }
    if (mounted == 0) {
        app.line("  none");
        ok.* = false;
    }
}

fn printDevices(app: *const App, ok: *bool) void {
    app.line("");
    app.line("Devices");
    var summary: r4os.abi.DeviceInventorySummary = .{};
    if (app.dev.deviceInventorySummary(&summary) <= 0) {
        label(app, "Inventory");
        app.line("not available");
        ok.* = false;
        return;
    }

    var counts = DeviceCounts{};
    var index: u32 = 0;
    while (index < summary.total) : (index += 1) {
        var rec: r4os.abi.DeviceInventoryRecord = .{};
        if (app.dev.deviceInventoryRecord(index, &rec) <= 0) continue;
        switch (rec.class_code) {
            0x01 => counts.storage += 1,
            0x02 => counts.network += 1,
            0x03 => counts.display += 1,
            0x0C => counts.usb += 1,
            else => {},
        }
    }

    label(app, "Inventory");
    app.writeDec(summary.total);
    app.write(" total, ");
    app.writeDec(summary.with_driver);
    app.write(" with driver, ");
    app.writeDec(summary.without_driver);
    app.write(" without");
    if (summary.truncated != 0) {
        app.write(", truncated");
        ok.* = false;
    }
    app.line("");

    label(app, "Classes");
    app.write("storage=");
    app.writeDec(counts.storage);
    app.write(" net=");
    app.writeDec(counts.network);
    app.write(" display=");
    app.writeDec(counts.display);
    app.write(" usb=");
    app.writeDec(counts.usb);
    app.line("");
}

fn runDriverRegistrySelftest(app: *const App) bool {
    app.line("SYSINFO driver registry selftest");

    var summary: r4os.abi.DeviceInventorySummary = .{};
    if (app.dev.deviceInventorySummary(&summary) <= 0) {
        app.line("SYSINFO drivers inventory: not available");
        app.line("SYSINFO driver registry: failed");
        return false;
    }

    var driver_records: u32 = 0;
    var active_r4d: u32 = 0;
    var failed_records: u32 = 0;

    var index: u32 = 0;
    while (index < summary.total) : (index += 1) {
        var rec: r4os.abi.DeviceInventoryRecord = .{};
        if (app.dev.deviceInventoryRecord(index, &rec) <= 0) continue;
        if (rec.bus != bus_driver) continue;

        driver_records += 1;
        const source = spanZ(rec.driver[0..]);
        const status = spanZ(rec.status[0..]);
        const is_active_r4d = textEq(rec.driver[0..], "r4d") and textEq(rec.status[0..], "AKTIV");
        const is_failed = textEq(rec.status[0..], "FAILED");
        if (is_active_r4d) active_r4d += 1;
        if (is_failed) failed_records += 1;

        app.write("SYSINFO driver ");
        writeNonEmptyZ(app, rec.name[0..]);
        app.write(": ");
        app.write(if (source.len != 0 and status.len != 0 and !is_failed) "OK" else "FAILED");
        app.write(" driver=");
        writeNonEmptyZ(app, rec.driver[0..]);
        app.write(" status=");
        writeNonEmptyZ(app, rec.status[0..]);
        app.write(" note=");
        writeNonEmptyZ(app, rec.note[0..]);
        app.line("");
    }

    app.write("SYSINFO drivers records: total=");
    app.writeDec(driver_records);
    app.write(" active_r4d=");
    app.writeDec(active_r4d);
    app.write(" failed=");
    app.writeDec(failed_records);
    app.line("");

    const ok = summary.truncated == 0 and driver_records != 0 and active_r4d != 0 and failed_records == 0;
    app.line(if (ok) "SYSINFO driver registry: ok" else "SYSINFO driver registry: failed");
    return ok;
}

fn runStorageSelftest(app: *const App) bool {
    app.line("SYSINFO storage selftest");

    var summary: r4os.abi.DeviceInventorySummary = .{};
    if (app.dev.deviceInventorySummary(&summary) <= 0) {
        app.line("SYSINFO storage inventory: not available");
        app.line("SYSINFO storage: failed");
        return false;
    }

    var storage_records: u32 = 0;
    var block_records: u32 = 0;
    var preload_blocks: u32 = 0;
    var mounted_c: u32 = 0;
    var mounted_data: u32 = 0;
    var builtin_blocks: u32 = 0;

    var index: u32 = 0;
    while (index < summary.total) : (index += 1) {
        var rec: r4os.abi.DeviceInventoryRecord = .{};
        if (app.dev.deviceInventoryRecord(index, &rec) <= 0) continue;
        if (rec.bus != bus_storage) continue;
        storage_records += 1;

        const is_block = !textEq(rec.driver[0..], "storage/block");
        const source_preload = storageRecordHasSourcePreload(rec);
        const source_builtin = storageRecordHasSourceBuiltin(rec);
        const is_mounted_c = textEq(rec.status[0..], "mounted-C");
        const is_mounted_data = textEq(rec.status[0..], "mounted-D") or textEq(rec.status[0..], "mounted-E");
        const rec_ok = !is_block or source_preload or storageRecordHasSourceDisk(rec);

        if (is_block) block_records += 1;
        if (is_block and source_preload) preload_blocks += 1;
        if (is_block and source_builtin) builtin_blocks += 1;
        if (is_block and is_mounted_c and source_preload) mounted_c += 1;
        if (is_block and is_mounted_data and source_preload) mounted_data += 1;

        app.write("SYSINFO storage ");
        writeNonEmptyZ(app, rec.name[0..]);
        app.write(": ");
        app.write(if (rec_ok) "OK" else "FAILED");
        app.write(" driver=");
        writeNonEmptyZ(app, rec.driver[0..]);
        app.write(" status=");
        writeNonEmptyZ(app, rec.status[0..]);
        app.write(" note=");
        writeNonEmptyZ(app, rec.note[0..]);
        app.line("");
    }

    app.write("SYSINFO storage records: total=");
    app.writeDec(storage_records);
    app.write(" blocks=");
    app.writeDec(block_records);
    app.write(" preload=");
    app.writeDec(preload_blocks);
    app.write(" mounted_c=");
    app.writeDec(mounted_c);
    app.write(" mounted_data=");
    app.writeDec(mounted_data);
    app.write(" builtin=");
    app.writeDec(builtin_blocks);
    app.line("");

    const ok = summary.truncated == 0 and block_records != 0 and preload_blocks != 0 and mounted_c != 0 and builtin_blocks == 0;
    app.line(if (ok) "SYSINFO storage: ok" else "SYSINFO storage: failed");
    return ok;
}

fn runUsbHidSelftest(app: *const App) bool {
    app.line("SYSINFO USB-HID selftest");

    var summary: r4os.abi.DeviceInventorySummary = .{};
    if (app.dev.deviceInventorySummary(&summary) <= 0) {
        app.line("SYSINFO usbhid inventory: not available");
        app.line("SYSINFO usbhid: failed");
        return false;
    }

    var hid_report_source: u8 = protocol_source_none;
    var hid_boot_source: u8 = protocol_source_none;
    var keyboard_count: u32 = 0;
    var mouse_count: u32 = 0;
    var keyboard_ok = true;
    var mouse_ok = true;

    var index: u32 = 0;
    while (index < summary.total) : (index += 1) {
        var rec: r4os.abi.DeviceInventoryRecord = .{};
        if (app.dev.deviceInventoryRecord(index, &rec) <= 0) continue;
        if (isR4pProtocolRecord(rec, "usb.hid_report")) hid_report_source = protocolRecordSource(rec);
        if (isR4pProtocolRecord(rec, "usb.hid_boot")) hid_boot_source = protocolRecordSource(rec);
        if (isUsbHidKeyboardRecord(rec)) {
            keyboard_count += 1;
            const ok = usbHidBindingRecordOk(rec);
            keyboard_ok = keyboard_ok and ok;
            printUsbHidRecordLine(app, "keyboard", rec, ok);
        } else if (isUsbHidMouseRecord(rec)) {
            mouse_count += 1;
            const ok = usbHidBindingRecordOk(rec);
            mouse_ok = mouse_ok and ok;
            printUsbHidRecordLine(app, "mouse", rec, ok);
        }
    }

    printUsbHidProtocolLine(app, "usb.hid_report", hid_report_source);
    printUsbHidProtocolLine(app, "usb.hid_boot", hid_boot_source);
    if (keyboard_count == 0) app.line("SYSINFO usbhid keyboard: missing");
    if (mouse_count == 0) app.line("SYSINFO usbhid mouse: missing");
    app.write("SYSINFO usbhid records: keyboard=");
    app.writeDec(keyboard_count);
    app.write(" mouse=");
    app.writeDec(mouse_count);
    app.line("");

    const ok = hid_report_source != protocol_source_none and hid_boot_source != protocol_source_none and keyboard_ok and mouse_ok;
    app.line(if (ok) "SYSINFO usbhid: ok" else "SYSINFO usbhid: failed");
    return ok;
}

fn printUsbHidProtocolLine(app: *const App, role: []const u8, source: u8) void {
    app.write("SYSINFO usbhid protocol ");
    app.write(role);
    app.write(": ");
    if (source == protocol_source_none) {
        app.line("FAILED source=none state=missing required=R4P");
    } else {
        app.write("OK source=");
        app.write(protocolSourceName(source));
        app.line(" state=active required=R4P");
    }
}

fn printUsbHidRecordLine(app: *const App, kind: []const u8, rec: r4os.abi.DeviceInventoryRecord, ok: bool) void {
    app.write("SYSINFO usbhid ");
    app.write(kind);
    app.write(": ");
    app.write(if (ok) "OK" else "FAILED");
    app.write(" driver=");
    writeNonEmptyZ(app, rec.driver[0..]);
    app.write(" status=");
    writeNonEmptyZ(app, rec.status[0..]);
    app.write(" note=");
    writeNonEmptyZ(app, rec.note[0..]);
    app.line("");
}

fn runUsbMscSelftest(app: *const App) bool {
    app.line("SYSINFO USBMSC selftest");

    var summary: r4os.abi.DeviceInventorySummary = .{};
    if (app.dev.deviceInventorySummary(&summary) <= 0) {
        app.line("SYSINFO usbmsc inventory: not available");
        app.line("SYSINFO usbmsc: failed");
        return false;
    }

    var bot_source: u8 = protocol_source_none;
    var scsi_source: u8 = protocol_source_none;
    var storage_count: u32 = 0;
    var storage_ok = true;

    var index: u32 = 0;
    while (index < summary.total) : (index += 1) {
        var rec: r4os.abi.DeviceInventoryRecord = .{};
        if (app.dev.deviceInventoryRecord(index, &rec) <= 0) continue;
        if (isR4pProtocolRecord(rec, "usb.msc_bot")) bot_source = protocolRecordSource(rec);
        if (isR4pProtocolRecord(rec, "usb.scsi_block")) scsi_source = protocolRecordSource(rec);
        if (isUsbMscRecord(rec)) {
            storage_count += 1;
            const ok = usbMscBindingRecordOk(rec);
            storage_ok = storage_ok and ok;
            printUsbMscRecordLine(app, rec, ok);
        }
    }

    printUsbMscProtocolLine(app, "usb.msc_bot", bot_source);
    printUsbMscProtocolLine(app, "usb.scsi_block", scsi_source);
    if (storage_count == 0) app.line("SYSINFO usbmsc storage: missing");
    app.write("SYSINFO usbmsc records: storage=");
    app.writeDec(storage_count);
    app.line("");

    const ok = bot_source != protocol_source_none and scsi_source != protocol_source_none and storage_count != 0 and storage_ok;
    app.line(if (ok) "SYSINFO usbmsc: ok" else "SYSINFO usbmsc: failed");
    return ok;
}

fn printUsbMscProtocolLine(app: *const App, role: []const u8, source: u8) void {
    app.write("SYSINFO usbmsc protocol ");
    app.write(role);
    app.write(": ");
    if (source == protocol_source_none) {
        app.line("FAILED source=none state=missing required=R4P");
    } else {
        app.write("OK source=");
        app.write(protocolSourceName(source));
        app.line(" state=active required=R4P");
    }
}

fn printUsbMscRecordLine(app: *const App, rec: r4os.abi.DeviceInventoryRecord, ok: bool) void {
    app.write("SYSINFO usbmsc storage: ");
    app.write(if (ok) "OK" else "FAILED");
    app.write(" driver=");
    writeNonEmptyZ(app, rec.driver[0..]);
    app.write(" status=");
    writeNonEmptyZ(app, rec.status[0..]);
    app.write(" note=");
    writeNonEmptyZ(app, rec.note[0..]);
    app.line("");
}

fn printNetwork(app: *const App) void {
    app.line("");
    app.line("Network");
    var config: r4os.abi.NetConfigSnapshot = .{};
    const cfg_result = app.net.netConfigGet(&config);
    if (cfg_result == r4os.abi.net_config_ok) {
        label(app, "Adapters");
        app.writeDec(config.adapter_count);
        app.write(" ");
        if ((config.flags & r4os.abi.net_config_flag_adapter_present) != 0) {
            app.writeZ(config.adapter_name[0..]);
            app.write(" ");
            app.writeZ(config.link[0..]);
        } else {
            app.write("none");
        }
        app.line("");
        label(app, "IPv4");
        writeIp(app, config.local_ip);
        app.write(" gateway=");
        writeIp(app, config.gateway_ip);
        app.write(" dns=");
        writeIp(app, config.dns_ip);
        app.line("");
    } else {
        label(app, "Config");
        app.write("not available: ");
        app.line(app.net.netConfigResultName(cfg_result));
    }

    var detail: r4os.abi.NetDetailSnapshot = .{};
    if (app.net.netDetailGet(0, &detail) > 0) {
        label(app, "Driver");
        app.writeZ(detail.adapter.driver[0..]);
        app.write(" mtu=");
        app.writeDec(detail.adapter.mtu);
        app.write(" rx=");
        app.writeDec(detail.adapter.rx_packets);
        app.write(" tx=");
        app.writeDec(detail.adapter.tx_packets);
        app.line("");
    }
}

fn label(app: *const App, text: []const u8) void {
    app.write(text);
    var pad = if (text.len < 16) 16 - text.len else 1;
    while (pad > 0) : (pad -= 1) app.write(" ");
    app.write(": ");
}

fn releaseVersion(app: *const App, scratch: []u8) []const u8 {
    const read = app.sys.fileRead(r4os.version_info.release_file_path, scratch);
    if (read <= 0) return version_unknown;
    const len: usize = @intCast(read);
    return r4os.version_info.parseReleaseVersion(scratch[0..len]) orelse version_unknown;
}

fn installedKernelVersion(app: *const App, scratch: []u8) []const u8 {
    const read = app.sys.fileReadAt(r4os.version_info.inventory_file_path, 0, scratch);
    if (read <= 0) return version_unknown;
    const len: usize = @intCast(read);
    return r4os.version_info.parseInstalledKernelVersion(scratch[0..len]) orelse version_unknown;
}

fn writeDateTime(app: *const App, time: r4os.abi.TimeState) void {
    writeDecPad(app, time.day, 2);
    app.write(".");
    writeDecPad(app, time.month, 2);
    app.write(".");
    app.writeDec(time.year);
    app.write(" ");
    writeDecPad(app, time.hour, 2);
    app.write(":");
    writeDecPad(app, time.minute, 2);
    app.write(":");
    writeDecPad(app, time.second, 2);
}

fn writeDecPad(app: *const App, value: u64, width: usize) void {
    var buf: [20]u8 = undefined;
    var pos = buf.len;
    var n = value;
    if (n == 0) {
        pos -= 1;
        buf[pos] = '0';
    } else {
        while (n > 0) {
            pos -= 1;
            buf[pos] = '0' + @as(u8, @intCast(n % 10));
            n /= 10;
        }
    }
    const digits = buf.len - pos;
    var pad: usize = if (width > digits) width - digits else 0;
    while (pad > 0) : (pad -= 1) app.write("0");
    app.write(buf[pos..]);
}

fn writeIp(app: *const App, ip: [4]u8) void {
    app.writeDec(ip[0]);
    app.write(".");
    app.writeDec(ip[1]);
    app.write(".");
    app.writeDec(ip[2]);
    app.write(".");
    app.writeDec(ip[3]);
}

fn backendName(value: u32) []const u8 {
    return switch (value) {
        0 => "PIT",
        1 => "HPET",
        2 => "LAPIC",
        else => "unknown",
    };
}

fn irqControllerName(value: u8) []const u8 {
    return switch (value) {
        0 => "PIC",
        1 => "APIC/PIC",
        2 => "IOAPIC",
        else => "unknown",
    };
}

fn timerBackendName(value: u8) []const u8 {
    return switch (value) {
        0 => "PIT",
        1 => "HPET/PIT",
        2 => "LAPIC/PIT",
        3 => "HPET",
        4 => "LAPIC",
        else => "unknown",
    };
}

fn driveKindName(value: u8) []const u8 {
    return switch (value) {
        1 => "RAM",
        2 => "FAT32",
        3 => "NTFS",
        else => "NONE",
    };
}

fn driveRoleName(value: u8) []const u8 {
    return switch (value) {
        1 => "system",
        2 => "data",
        3 => "ram",
        else => "general",
    };
}

fn isUsbHidKeyboardRecord(rec: r4os.abi.DeviceInventoryRecord) bool {
    return rec.bus == bus_usb and rec.class_code == 0x03 and rec.subclass == 0x01 and rec.prog_if == 0x01;
}

fn isUsbHidMouseRecord(rec: r4os.abi.DeviceInventoryRecord) bool {
    return rec.bus == bus_usb and rec.class_code == 0x03 and rec.subclass == 0x01 and rec.prog_if == 0x02;
}

fn isUsbMscRecord(rec: r4os.abi.DeviceInventoryRecord) bool {
    return rec.bus == bus_usb and rec.class_code == 0x08 and rec.subclass == 0x06 and rec.prog_if == 0x50;
}

fn usbHidBindingRecordOk(rec: r4os.abi.DeviceInventoryRecord) bool {
    return rec.binding == 0 and
        rec.bus == bus_usb and
        textEq(rec.driver[0..], "USBHID") and
        textEq(rec.status[0..], "bound-input") and
        containsIgnoreCase(spanZ(rec.note[0..]), "bound through USBHID") and
        containsIgnoreCase(spanZ(rec.note[0..]), "preload/R4P-required active");
}

fn usbMscBindingRecordOk(rec: r4os.abi.DeviceInventoryRecord) bool {
    return rec.binding == 0 and
        rec.bus == bus_usb and
        textEq(rec.driver[0..], "USBMSC") and
        textEq(rec.status[0..], "bound-storage") and
        containsIgnoreCase(spanZ(rec.note[0..]), "bound through USBMSC") and
        containsIgnoreCase(spanZ(rec.note[0..]), "preload/R4P-required active");
}

fn isR4pProtocolRecord(rec: r4os.abi.DeviceInventoryRecord, role: []const u8) bool {
    return rec.bus == bus_protocol and
        textEq(rec.name[0..], role) and
        (textEq(rec.driver[0..], "r4p") or textEq(rec.driver[0..], "preload")) and
        textEq(rec.status[0..], "active");
}

const protocol_source_none: u8 = 0;
const protocol_source_r4p: u8 = 1;
const protocol_source_preload: u8 = 2;

fn protocolRecordSource(rec: r4os.abi.DeviceInventoryRecord) u8 {
    if (textEq(rec.driver[0..], "preload")) return protocol_source_preload;
    if (textEq(rec.driver[0..], "r4p")) return protocol_source_r4p;
    return protocol_source_none;
}

fn protocolSourceName(source: u8) []const u8 {
    return switch (source) {
        protocol_source_preload => "preload",
        protocol_source_r4p => "r4p",
        else => "none",
    };
}

fn textEq(value: []const u8, expected: []const u8) bool {
    return equalsIgnoreCase(spanZ(value), expected);
}

fn containsIgnoreCase(haystack: []const u8, needle: []const u8) bool {
    if (needle.len == 0) return true;
    if (needle.len > haystack.len) return false;
    var start: usize = 0;
    while (start + needle.len <= haystack.len) : (start += 1) {
        if (equalsIgnoreCase(haystack[start..][0..needle.len], needle)) return true;
    }
    return false;
}

fn storageRecordHasSourcePreload(rec: r4os.abi.DeviceInventoryRecord) bool {
    return containsIgnoreCase(spanZ(rec.note[0..]), "source=preload");
}

fn storageRecordHasSourceBuiltin(rec: r4os.abi.DeviceInventoryRecord) bool {
    return containsIgnoreCase(spanZ(rec.note[0..]), "source=built-in") or
        containsIgnoreCase(spanZ(rec.note[0..]), "builtin storage") or
        containsIgnoreCase(spanZ(rec.note[0..]), "built-in storage");
}

fn storageRecordHasSourceDisk(rec: r4os.abi.DeviceInventoryRecord) bool {
    return containsIgnoreCase(spanZ(rec.note[0..]), "source=disk");
}

fn writeNonEmptyZ(app: *const App, value: []const u8) void {
    const text = spanZ(value);
    app.write(if (text.len == 0) "-" else text);
}

fn argsContain(args: []const u8, needle: []const u8) bool {
    var pos: usize = 0;
    while (pos < args.len) {
        while (pos < args.len and isSpace(args[pos])) : (pos += 1) {}
        const start = pos;
        while (pos < args.len and !isSpace(args[pos])) : (pos += 1) {}
        if (equalsIgnoreCase(args[start..pos], needle)) return true;
    }
    return false;
}

fn spanZ(value: []const u8) []const u8 {
    var end: usize = 0;
    while (end < value.len and value[end] != 0) : (end += 1) {}
    return value[0..end];
}

fn zSlice(ptr: [*:0]const u8) []const u8 {
    var len: usize = 0;
    while (ptr[len] != 0) : (len += 1) {}
    return ptr[0..len];
}

fn isSpace(ch: u8) bool {
    return ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n';
}

fn trim(s: []const u8) []const u8 {
    var start: usize = 0;
    var end: usize = s.len;
    while (start < end and isSpace(s[start])) : (start += 1) {}
    while (end > start and isSpace(s[end - 1])) : (end -= 1) {}
    return s[start..end];
}

fn startsWith(s: []const u8, prefix: []const u8) bool {
    if (s.len < prefix.len) return false;
    var i: usize = 0;
    while (i < prefix.len) : (i += 1) {
        if (s[i] != prefix[i]) return false;
    }
    return true;
}

fn equalsIgnoreCase(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    var i: usize = 0;
    while (i < a.len) : (i += 1) {
        if (asciiUpper(a[i]) != asciiUpper(b[i])) return false;
    }
    return true;
}

fn asciiUpper(ch: u8) u8 {
    if (ch >= 'a' and ch <= 'z') return ch - 32;
    return ch;
}
