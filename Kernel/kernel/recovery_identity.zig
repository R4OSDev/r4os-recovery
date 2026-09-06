// Early boot facts only. Slot rotation and persistent confirmation belong
// to the Recovery application. Hash the original ELF before memory startup.
const std = @import("std");
const config = @import("config");
const version = @import("version.zig");
const boot_info = @import("../bootloader/boot_info.zig");
const limine = @import("../bootloader/limine.zig");

pub var elf_sha256: [32]u8 = .{0} ** 32;
pub var elf_bytes: u64 = 0;
pub var valid = false;

// Fixed byte layout, independent of ABI padding. The package checker reads
// this named ELF section; arbitrary matching bytes elsewhere do not count.
pub export var recovery_pair: [112]u8 linksection(".r4os.recovery.pair") = pair();
fn pair() [112]u8 {
    var out: [112]u8 = .{0} ** 112;
    @memcpy(out[0..8], "R4RECOV1");
    std.mem.writeInt(u64, out[8..16], config.runtime_bytes, .little);
    if (config.runtime_sha256.len == 64)
        _ = std.fmt.hexToBytes(out[16..48], config.runtime_sha256) catch @compileError("Invalid runtime hash");
    if (config.recovery_version.len >= 32 or version.text.len >= 32) @compileError("Recovery version too long");
    @memcpy(out[48..][0..config.recovery_version.len], config.recovery_version);
    @memcpy(out[80..][0..version.text.len], version.text);
    return out;
}
pub fn capture() void {
    const keep: *volatile const u8 = &recovery_pair[0];
    _ = keep.*;
    const file = limine.executableFile() orelse return;
    const address = file.address orelse return;
    if (file.size < 64 or file.size > 256 * 1024 * 1024) return;
    const start = boot_info.hhdmToPhys(@intFromPtr(address)) orelse return;
    const end = std.math.add(u64, start, file.size) catch return;
    var cursor = start;
    while (cursor < end) {
        var next = cursor;
        for (boot_info.memoryMap()) |entry| {
            if (entry.valid and (entry.kind == .kernel_and_modules or entry.kind == .bootloader_reclaimable) and
                entry.base <= cursor and entry.end > cursor) next = @max(next, @min(end, entry.end));
        }
        if (next == cursor) return;
        cursor = next;
    }
    std.crypto.hash.sha2.Sha256.hash(address[0..@intCast(file.size)], &elf_sha256, .{});
    elf_bytes = file.size;
    valid = true;
}
