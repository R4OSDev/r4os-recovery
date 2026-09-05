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
const log = @import("log.zig");

pub fn run() bool {
    if (smp.status().online != 4 or !storage.source.confirmed) return false;
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
