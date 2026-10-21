// Bounded guest acceptance only. Every key enters through QEMU hardware;
// this code neither injects scancodes nor supplies a console input hook.
const std = @import("std");
const keyboard = @import("../driver/input/keyboard.zig");
const hid = @import("../driver/usb/hid.zig");
const input_boot = @import("input_boot.zig");
const block = @import("../storage/block.zig");
const vfs = @import("../fs/vfs.zig");
const fs_request = @import("../fs/request.zig");
const r4x = @import("../program/r4x.zig");
const runtime = @import("recovery_runtime.zig");
const storage = @import("recovery_storage.zig");
const scheduler = @import("../sched/scheduler.zig");
const smp = @import("smp.zig");
const timer = @import("timer.zig");
const core = @import("../driver/usb/core.zig");
const xhci = @import("../driver/usb/xhci_api.zig");
const native_xhci = @import("../driver/usb/xhci.zig");
const msc = @import("../driver/usb/msc.zig");
const inventory = @import("../platform/device_inventory.zig");
const log = @import("log.zig");

pub fn run() bool {
    if (smp.status().online != 4 or !storage.source.confirmed) return false;
    if (@import("../platform/pci_inventory.zig").status().xhci_count >= 3) return runMulti();
    if (input_boot.mouseStatus() != .not_started or hid.status().mouse_bound) return false;
    if (block.isBusVisible(.usb) != storage.source.usb) return false;
    while (keyboard.readCodepoint() != null) {}
    const before = keyboard.stats();
    const initial_layout = keyboard.stats().layout;
    defer keyboard.setLayout(initial_layout);
    keyboard.setLayout(.en_en);
    log.puts("[RECOVERYINPUT] phase=EN\r\n");
    if (!expect(&.{ keyboard.KEY_UP, keyboard.KEY_DOWN, keyboard.KEY_LEFT, keyboard.KEY_RIGHT, keyboard.KEY_HOME, keyboard.KEY_END, keyboard.KEY_PAGE_UP, keyboard.KEY_PAGE_DOWN, keyboard.KEY_DELETE, '\n', 0x1b, '\t', 0x08, 'a', 'A', 'y', 'z', '!', 3 })) return false;
    keyboard.setLayout(.de_de);
    log.puts("[RECOVERYINPUT] phase=DE\r\n");
    if (!expect(&.{ 'z', 'y', 0x00fc, 0x00df, '@', 0x20ac, '\n' })) return false;
    // Commands below are typed into the actual unchanged TERMINAL.R4X.
    // Its line editor must also process a deliberate typo and Backspace.
    keyboard.setLayout(.en_en);
    const programs_before = r4x.programRegistryStats();
    if (!runtime.launchTerminal()) return false;
    log.puts("[RECOVERYINPUT] phase=TERMINAL\r\n");
    const deadline = timer.deadlineAfter(timer.tickCount(), @as(u64, timer.frequency()) * 30);
    var file_ok = false;
    while (timer.tickCount() < deadline) {
        file_ok = file_ok or terminalWitness();
        if (file_ok and r4x.activeShellInstanceId() == 0 and r4x.programRegistryStats().live_slots == programs_before.live_slots) break;
        scheduler.sleepTicks(1);
    }
    if (!file_ok or r4x.activeShellInstanceId() != 0 or r4x.programRegistryStats().live_slots != programs_before.live_slots) {
        log.puts("[RECOVERYINPUT] terminal_failed file=");
        log.putDec(@intFromBool(file_ok));
        log.puts(" shell=");
        log.putDec(r4x.activeShellInstanceId());
        log.puts(" live=");
        log.putDec(r4x.programRegistryStats().live_slots);
        log.puts(" before=");
        log.putDec(programs_before.live_slots);
        log.puts(" exit=");
        log.putHex(@as(u32, @bitCast(r4x.lastExitCode())), 8);
        log.puts("\r\n");
        return false;
    }
    const after = keyboard.stats();
    const hs = hid.status();
    if (after.dropped_count != before.dropped_count or hs.mouse_bound or hs.decoded_mouse != 0) return false;
    if (hs.keyboard_bound) {
        if (hs.decoded_keys == 0 or hs.boot_r4p_keyboard == 0 or !hs.report_descriptor_ok or after.irq_count != before.irq_count) return false;
    } else if (after.irq_count <= before.irq_count) return false;
    log.puts("[RECOVERYINPUT] result=OK cpus=4 input=");
    log.puts(if (hs.keyboard_bound) "USB" else "PS2");
    log.puts(" layouts=EN,DE navigation=OK text=OK terminal_file=OK shell_exit=OK mouse=0 usb_storage=");
    log.putDec(@intFromBool(block.isBusVisible(.usb)));
    log.puts("\r\n");
    return true;
}

fn expect(expected: []const u32) bool {
    const deadline = timer.deadlineAfter(timer.tickCount(), @as(u64, timer.frequency()) * 30);
    var index: usize = 0;
    while (timer.tickCount() < deadline) {
        if (keyboard.readCodepoint()) |value| {
            if (value != expected[index]) {
                log.puts("[RECOVERYINPUT] unexpected index=");
                log.putDec(index);
                log.puts(" expected=");
                log.putDec(expected[index]);
                log.puts(" actual=");
                log.putDec(value);
                log.puts("\r\n");
                return false;
            }
            index += 1;
            if (index == expected.len) return true;
        } else scheduler.sleepTicks(1);
    }
    log.puts("[RECOVERYINPUT] timeout index=");
    log.putDec(index);
    log.puts("\r\n");
    return false;
}

fn terminalWitness() bool {
    const volume = vfs.volumeForDrive('C') orelse return false;
    var request = fs_request.begin(.file_read, 'C') orelse return false;
    var ok = false;
    defer fs_request.finish(&request, ok);
    const entry = vfs.resolveEntry(volume, "/TEMP/INPUT.TXT") orelse return false;
    if (entry.isDir() or entry.size > 64) return false;
    var buffer: [64]u8 = undefined;
    const count = vfs.readFileRange(volume, entry, 0, &buffer) orelse return false;
    // The normal R4OS Terminal intentionally uppercases interactive input.
    ok = std.mem.eql(u8, std.mem.trim(u8, buffer[0..count], " \r\n\t"), "INPUT-OK");
    return ok;
}

// Same Input acceptance, limited to the changed controller routing and medium
// lifetime. Production Recovery still admits keyboard input only.
var transfer_buffer: [4096]u8 = undefined;
var readback_buffer: [4096]u8 = undefined;
fn runMulti() bool {
    if (!storage.source.usb or !block.isBusVisible(.usb)) return false;
    const initial = hid.status();
    if (!initial.keyboard_bound or !initial.mouse_bound) return false;
    var keyboard_id: u32 = 0;
    var mouse_id: u32 = 0;
    var medium_id: u32 = 0;
    var raw: ?xhci.DeviceHandle = null;
    var index: usize = 0;
    while (core.deviceAt(index)) |dev| : (index += 1) {
        const handle = xhci.deviceHandleFromCore(&dev);
        if (hid.bindingFor(handle)) |is_mouse| {
            if (is_mouse) mouse_id = dev.controller_id else keyboard_id = dev.controller_id;
        }
        if (msc.bindingFor(handle)) |status| {
            if (status.sector_count == 16384) raw = handle else medium_id = dev.controller_id;
        }
    }
    const old = raw orelse return false;
    if (keyboard_id == 0 or mouse_id == 0 or medium_id == 0 or keyboard_id == mouse_id or mouse_id == medium_id or keyboard_id == medium_id or old.controller_id != mouse_id) return false;
    if (!inventory.acquireSnapshot()) return false;
    const snapshot = inventory.snapshot();
    var active: usize = 0;
    for (snapshot.records[0..snapshot.count]) |record| {
        if (record.has_pci_address and record.class_code == 0x0c and record.subclass == 3 and record.prog_if == 0x30) {
            if (record.binding == .with_driver and std.mem.endsWith(u8, record.status, "-active")) active += 1;
        }
    }
    inventory.releaseSnapshot();
    if (active != 3) return false;
    keyboard.setLayout(.en_en);
    while (keyboard.readCodepoint() != null) {}
    const pages = ownedDmaPages() orelse return false;
    if (pages != 68) return false;
    const idle_start = hid.pollTaskSummary().iterations;
    scheduler.sleepTicks(@max(1, @as(u64, timer.frequency()) / 4));
    const idle_iterations = hid.pollTaskSummary().iterations -% idle_start;
    if (idle_iterations == 0 or idle_iterations > 8) return false;
    log.puts("[RECOVERYINPUT] phase=MULTI_INPUT\r\n");
    if (!expect(&.{'a'})) return false;
    const mouse_deadline = timer.deadlineAfter(timer.tickCount(), @as(u64, timer.frequency()) * 10);
    while (hid.status().decoded_mouse <= initial.decoded_mouse and timer.tickCount() < mouse_deadline) scheduler.sleepTicks(1);
    if (hid.status().decoded_mouse <= initial.decoded_mouse) return false;
    const fallback_before = completionFallbacks();
    log.puts("[RECOVERYINPUT] phase=MULTI_NOIRQ\r\n");
    if (!expect(&.{'n'}) or !mediumWork(old, true)) return false;
    const fallback_delta = completionFallbacks() -% fallback_before;
    if (fallback_delta == 0) return false;
    log.puts("[RECOVERYINPUT] phase=MULTI_KEY_DOWN\r\n");
    const held_deadline = timer.deadlineAfter(timer.tickCount(), @as(u64, timer.frequency()) * 10);
    while ((hid.status().last_modifiers & 2) == 0 and timer.tickCount() < held_deadline) scheduler.sleepTicks(1);
    if ((hid.status().last_modifiers & 2) == 0) return false;
    log.puts("[RECOVERYINPUT] phase=MULTI_KEY_REMOVE\r\n");
    const release_deadline = timer.deadlineAfter(timer.tickCount(), @as(u64, timer.frequency()) * 10);
    while (timer.tickCount() < release_deadline) {
        const state = hid.status();
        if (!state.keyboard_bound and state.last_modifiers == 0) break;
        scheduler.sleepTicks(1);
    }
    if (hid.status().keyboard_bound or hid.status().last_modifiers != 0) return false;
    log.puts("[RECOVERYINPUT] phase=MULTI_KEY_REPLACE\r\n");
    const replacement_deadline = timer.deadlineAfter(timer.tickCount(), @as(u64, timer.frequency()) * 15);
    while (!hid.status().keyboard_bound and timer.tickCount() < replacement_deadline) scheduler.sleepTicks(1);
    if (!hid.status().keyboard_bound) return false;
    log.puts("[RECOVERYINPUT] phase=MULTI_KEY_TEXT\r\n");
    if (!expect(&.{'d'})) return false;
    const prior = msc.bindingFor(old) orelse return false;
    const block_index = prior.block_index orelse return false;
    const old_identity = block.identity(block_index) orelse return false;
    log.puts("[RECOVERYINPUT] phase=MULTI_DETACH\r\n");
    const detach_deadline = timer.deadlineAfter(timer.tickCount(), @as(u64, timer.frequency()) * 15);
    // Catalog removal precedes the class hook and block retirement. Observe
    // all three real acknowledgements without assuming one scheduler turn.
    while (timer.tickCount() < detach_deadline) {
        if (!xhci.deviceHandleCurrent(old) and msc.bindingFor(old) == null and block.get(block_index) == null) break;
        scheduler.sleepTicks(1);
    }
    if (xhci.deviceHandleCurrent(old) or msc.bindingFor(old) != null or block.get(block_index) != null) return false;
    if (!expect(&.{'b'})) return false;
    log.puts("[RECOVERYINPUT] phase=MULTI_REPLUG\r\n");
    var replacement: ?xhci.DeviceHandle = null;
    const attach_deadline = timer.deadlineAfter(timer.tickCount(), @as(u64, timer.frequency()) * 15);
    while (timer.tickCount() < attach_deadline) {
        index = 0;
        while (core.deviceAt(index)) |dev| : (index += 1) {
            if (dev.controller_id != old.controller_id or dev.port != old.port or dev.generation == old.generation) continue;
            const handle = xhci.deviceHandleFromCore(&dev);
            if (msc.bindingFor(handle) != null) replacement = handle;
        }
        if (replacement != null) break;
        scheduler.sleepTicks(1);
    }
    const fresh = replacement orelse return false;
    const current = msc.bindingFor(fresh) orelse return false;
    const fresh_identity = block.identity(current.block_index orelse return false) orelse return false;
    if (fresh_identity.reference.slot == old_identity.reference.slot and fresh_identity.reference.generation == old_identity.reference.generation) return false;
    if (xhci.deviceHandleCurrent(old) or !mediumWork(fresh, false) or !expect(&.{'c'})) return false;
    log.puts("[RECOVERYINPUT] result=OK cpus=4 controllers=3 pci=3 input=USB mouse=1 medium_bytes=262144 write_readback=OK hotplug=OK stale=REJECTED source=USB dma_pages=");
    log.putDec(pages);
    log.puts(" idle_worker=");
    log.putDec(idle_iterations);
    log.puts(" fallback_waits=");
    log.putDec(fallback_delta);
    log.puts(" old_key_release=OK\r\n");
    return true;
}

// Passive exact-reservation gauge; allocation publishes these runtime fields
// under the same controller owner before a command can use either group.
fn ownedDmaPages() ?u64 {
    var total: u64 = 0;
    var index: usize = 0;
    while (native_xhci.instanceAt(index)) |instance| : (index += 1) {
        if (!instance.acquireControllerOwnership()) return null;
        defer instance.releaseControllerOwnership();
        const c = &instance.current;
        for ([_]u64{ c.command_ring_phys, c.event_ring_phys, c.erst_phys, c.dcbaa_phys, c.scratchpad_array_phys }) |frame| total += @intFromBool(frame != 0);
        for (instance.scratchpad_frames) |frame| total += @intFromBool(frame != 0);
        for (instance.runtimes) |rt| {
            for ([_]u64{ rt.device_context_phys, rt.input_context_phys, rt.ep0_ring_phys, rt.interrupt_ring_phys, rt.interrupt_buffer_phys, rt.bulk_in_ring_phys, rt.bulk_out_ring_phys, rt.descriptor_phys }) |frame| total += @intFromBool(frame != 0);
            if (rt.bulk_buffer_phys != 0) total += rt.bulk_buffer_frames;
        }
    }
    return total;
}
fn completionFallbacks() u64 {
    var total: u64 = 0;
    var index: usize = 0;
    while (native_xhci.instanceAt(index)) |instance| : (index += 1)
        total +%= @atomicLoad(u64, &instance.completion_fallbacks, .monotonic);
    return total;
}

fn mediumWork(handle: xhci.DeviceHandle, write: bool) bool {
    const status = msc.bindingFor(handle) orelse return false;
    const index = status.block_index orelse return false;
    for (0..64) |chunk| {
        if (!block.readDirect(index, 2048 + chunk * 8, 8, &transfer_buffer)) return false;
        for (transfer_buffer, 0..) |value, i| if (value != @as(u8, @intCast((chunk * transfer_buffer.len + i) % 251))) return false;
        if (write) {
            if (!block.writeDirect(index, 4096 + chunk * 8, 8, &transfer_buffer)) return false;
            if (!block.readDirect(index, 4096 + chunk * 8, 8, &readback_buffer) or !std.mem.eql(u8, &transfer_buffer, &readback_buffer)) return false;
        }
    }
    return !write or block.flush(index);
}
