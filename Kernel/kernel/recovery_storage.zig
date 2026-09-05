// Recovery boot policy; hardware, partition parsing and filesystem mechanisms
// are frozen copies of their normal Kernel owners.
const std = @import("std");
const boot_info = @import("../bootloader/boot_info.zig");
const source_owner = @import("../storage/boot_source.zig");
const inventory = @import("../storage/media_inventory.zig");
const tables = @import("../storage/partition_table.zig");
const block = @import("../storage/block.zig");
const drive = @import("../fs/drive.zig");
const vfs = @import("../fs/vfs.zig");
const fs_request = @import("../fs/request.zig");
const r4d = @import("../program/r4d.zig");
const r4p = @import("../program/r4p.zig");
const msc = @import("../driver/usb/msc.zig");
const device_inventory = @import("../platform/device_inventory.zig");
const smp = @import("smp.zig");
const log = @import("log.zig");

pub var source: source_owner.Source = .{};
var initialized = false;

pub fn init() bool {
    if (initialized) return true;
    const ram = drive.get('C') orelse return false;
    if (ram.role != .ram) return false;
    for ([_][]const u8{ "XHCI", "AHCI", "NVME", "ATAPIO", "USBMSC" }) |name| {
        const result = r4d.loadRuntimeNameResult(name);
        log.puts("[RECOVERYSTORAGE] driver=");
        log.puts(name);
        log.puts(" result=");
        log.puts(r4d.runtimeLoadResultName(result));
        log.puts("\r\n");
    }
    // Protocol admission runs outside the serialized host-controller path.
    if (r4p.hasActiveR4p("usb.msc_bot") and r4p.hasActiveR4p("usb.scsi_block")) {
        msc.setRuntimeOwner();
        _ = msc.init();
    }
    inventory.scan();
    var views: [inventory.maximum_devices]source_owner.DeviceView = undefined;
    var count: usize = 0;
    for (&inventory.devices) |*record| {
        if (!record.used) continue;
        inventory.readInstallation(record);
        views[count] = .{ .index = record.index, .usb = record.bus == .usb, .local = isLocal(record.bus), .table = &record.table, .installation = if (record.installation) |*manifest| manifest else null, .installation_conflict = record.installation_conflict };
        count += 1;
    }
    const identity = &boot_info.get().executable_source;
    source = source_owner.resolve(.{ .present = identity.present, .generic_media = identity.media_type == 0, .path = identity.path(), .path_truncated = identity.path_truncated, .disk_guid = identity.disk_guid, .partition_guid = identity.partition_guid }, views[0..count]);
    log.puts("[RECOVERYSTORAGE] executable=");
    log.puts(identity.path());
    log.puts(" disk=");
    printGuid(identity.disk_guid);
    log.puts(" partition=");
    printGuid(identity.partition_guid);
    log.puts("\r\n");
    log.puts("[RECOVERYSTORAGE] source=");
    log.puts(source.reason);
    log.puts(" bus=");
    log.puts(if (!source.confirmed) "unknown" else if (source.usb) "usb" else "local");
    log.puts(" slot=");
    log.puts(@tagName(source.slot));
    log.puts("\r\n");
    // An unresolved boot stays in diagnostic RAM mode. USB storage cannot
    // acquire repair/source/target visibility by guessing a local identity.
    if (!source.exposesUsb() and !block.excludeBusBeforeMount(.usb)) return false;
    if (source.confirmed) {
        const record = &inventory.devices[source.device_index];
        for (record.table.items(), 0..) |part, i| {
            if (tables.guid.eql(part.unique_guid, source.recovery_guid) and mount(record, i, 'R')) {
                if (!@import("../storage/operations.zig").reserveRecoveryCacheBoot(record.index)) return false;
            }
        }
    }
    admitAdditionalVolumes();
    if (drive.get('C') != ram or ram.role != .ram or drive.currentLetter() != 'C') return false;
    initialized = true;
    return true;
}

pub fn admitAdditionalVolumes() void {
    for (&inventory.devices) |*record| {
        if (!record.used or block.get(record.index) == null) continue;
        for (record.table.items(), 0..) |part, i| {
            if (record.volumes[i].letter != 0) continue;
            if (source.confirmed and record.index == source.device_index and tables.guid.eql(part.unique_guid, source.recovery_guid)) continue;
            const letter = freeLetter() orelse break;
            _ = mount(record, i, letter);
        }
    }
}

fn mount(record: *inventory.DeviceRecord, part_index: usize, letter: u8) bool {
    if (letter == 'C' or drive.get(letter) != null) return false;
    if (letter == 'R' and (!source.confirmed or record.index != source.device_index or
        !tables.guid.eql(record.table.partitions[part_index].unique_guid, source.recovery_guid))) return false;
    const state = inventory.probe(record, part_index);
    const volume = state.volume orelse return false;
    const part = record.table.partitions[part_index];
    const kind: drive.Kind = switch (volume) {
        .fat32 => .fat32,
        .ntfs => .ntfs,
    };
    if (!drive.mountBlockRole(letter, kind, .none, record.name, @intCast(part.sector_count * 512), record.index)) return false;
    if (!vfs.mountForDrive(letter, volume)) {
        drive.unmountLocked(letter); // Boot-only mount publication.
        return false;
    }
    state.letter = letter;
    return true;
}

fn freeLetter() ?u8 {
    var letter: u8 = 'D';
    while (letter <= 'Z') : (letter += 1) {
        if (letter != 'R' and drive.get(letter) == null) return letter;
    }
    return null;
}

fn isLocal(bus: block.Bus) bool {
    return bus == .ahci or bus == .ata or bus == .nvme or bus == .virtio;
}
fn printGuid(value: tables.guid.Guid) void {
    const text = tables.guid.format(value);
    log.puts(&text);
}

pub fn runProbe() bool {
    if (!initialized or smp.status().online != 4) return false;
    const c = drive.get('C') orelse return false;
    if (c.role != .ram) return false;
    const snapshot = device_inventory.snapshot();
    if (snapshot.truncated) return false;
    var usb_media_records: usize = 0;
    for (snapshot.records[0..snapshot.count]) |record| {
        if (record.bus == .usb and record.class_code == 0x08) usb_media_records += 1;
    }
    if (!source.exposesUsb() and usb_media_records != 0) return false;
    var saved: [26]?usize = .{null} ** 26;
    for (0..26) |i| if (drive.atIndex(i)) |d| {
        saved[i] = d.block_device_index;
    };
    admitAdditionalVolumes();
    for (0..26) |i| {
        const d = drive.atIndex(i);
        if (saved[i] != if (d) |v| v.block_device_index else null) return false;
    }
    log.puts("[RECOVERYSTORAGE] C=RAM mapping=stable\r\n");
    for (&inventory.devices) |*record| {
        if (!record.used) continue;
        const visible = block.get(record.index) != null;
        log.puts("[RECOVERYSTORAGE] disk=");
        printGuid(record.table.disk_guid);
        log.puts(" bus=");
        log.puts(@tagName(record.bus));
        log.puts(" visible=");
        log.putDec(@intFromBool(visible));
        log.puts(" table=");
        log.puts(record.table.reason);
        log.puts(" parts=");
        log.putDec(record.table.count);
        log.puts(" install=");
        log.putDec(@intFromBool(visible and source.permitsInstall(record.index)));
        log.puts(" update_recovery=");
        log.putDec(@intFromBool(visible and source.permitsRecoveryUpdate(record.index)));
        log.puts(" model=");
        log.puts(record.model);
        log.puts("\r\n");
        for (record.table.items(), 0..) |part, i| {
            const state = &record.volumes[i];
            if (!visible and state.letter != 0) return false;
            if (!visible) continue;
            log.puts("[RECOVERYSTORAGE] part=");
            printGuid(part.unique_guid);
            log.puts(" fs=");
            log.puts(@tagName(state.filesystem));
            log.puts(" letter=");
            log.putc(if (state.letter == 0) '-' else state.letter);
            log.puts("\r\n");
            if (state.letter == 0) continue;
            const volume = state.volume orelse return false;
            const witness = vfs.resolveEntry(volume, "/VOLUME.TXT") orelse continue;
            var buf: [128]u8 = undefined;
            if (witness.isDir() or witness.size > buf.len) return false;
            const got = vfs.readFileRange(volume, witness, 0, &buf) orelse return false;
            if (got != witness.size) return false;
            log.puts("[RECOVERYSTORAGE] witness=");
            log.puts(buf[0..got]);
            log.puts("\r\n");
            if (source.confirmed and state.filesystem == .ntfs and !checkWrite(volume, state.letter)) return false;
        }
    }
    log.puts("[RECOVERYSTORAGE] result=OK cpus=4 C=RAM mapping=stable\r\n");
    return true;
}

fn checkWrite(volume: vfs.Volume, letter: u8) bool {
    var request = fs_request.begin(.file_write, letter) orelse return false;
    var ok = false;
    defer fs_request.finish(&request, ok);
    const path = "/R4PROBE.TMP";
    const payload = "Recovery NTFS volume isolation";
    if (vfs.resolveEntry(volume, path) != null) return false;
    if (!vfs.writeFile(volume, volume.rootNode(), "R4PROBE.TMP", payload) or !vfs.flushVolume(volume)) return false;
    const entry = vfs.resolveEntry(volume, path) orelse return false;
    var buffer: [128]u8 = undefined;
    const got = vfs.readFileRange(volume, entry, 0, &buffer) orelse return false;
    if (!std.mem.eql(u8, buffer[0..got], payload)) return false;
    if (!vfs.deleteFile(volume, volume.rootNode(), "R4PROBE.TMP") or !vfs.flushVolume(volume)) return false;
    if (vfs.resolveEntry(volume, path) != null) return false;
    ok = true;
    log.puts("[RECOVERYSTORAGE] write_probe=OK letter=");
    log.putc(letter);
    log.puts("\r\n");
    return true;
}
