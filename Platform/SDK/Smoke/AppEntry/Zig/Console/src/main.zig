const std = @import("std");
const r4os = @import("r4os");

const tray_smoke_item_id: u64 = 0x7103_0001;
const tray_smoke_cleanup_item_id: u64 = 0x7103_0002;
const tray_smoke_timeout: r4os.app_tray.Timeout = .{
    .kind = r4os.abi.timeout_kind_finite,
    .nanoseconds = 10 * r4os.abi.nanoseconds_per_second,
};

pub fn r4_app_main(app: *r4os.App) i32 {
    if (app.profile != .console or !app.hasGroup(.r4sys) or app.desktop() != null) return 71;
    if (std.mem.eql(u8, std.mem.trim(u8, app.args(), " \t"), "/TRAYSMOKE")) return traySmoke(app);
    const files = app.files() orelse return 72;
    var missing_path = r4os.FilePath.parse("C:\\__R4OS_05835_PARITY_MISSING__.BIN") catch return 73;
    var payload_path = r4os.FilePath.parse("C:\\R4OS\\CONFIG\\VERSION.R4S") catch return 74;
    var missing_buffer: [8]u8 = .{0xA5} ** 8;
    const missing_raw: i32 = switch (files.read(missing_path.asZ(), missing_buffer[0..])) {
        .failure => |raw| raw,
        .end => 0,
        .bytes => |count| @intCast(count),
    };

    var buffer: [128]u8 = .{0xA5} ** 128;
    const count: u32 = switch (files.read(payload_path.asZ(), buffer[0..64])) {
        .bytes => |value| value,
        .end => 0,
        .failure => return 75,
    };
    var payload: u64 = 14695981039346656037;
    for (buffer[0..count]) |byte| {
        payload ^= byte;
        payload *%= 1099511628211;
    }

    var region = switch (app.resources().reserveVm(4096, 4096, r4os.abi.vm_region_flags_default)) {
        .region => |value| value,
        .failure => return 76,
    };
    const handle_before: u64 = @intFromBool(region.valid());
    const close_raw = region.release();
    const handle_after: u64 = @intFromBool(region.valid());

    const sys = app.system();
    sys.write("APPPARITY lang=zig domain=");
    sys.printU64(@intFromEnum(r4os.app_contract.ErrorDomain.filesystem));
    sys.write(" raw=");
    sys.printI32(missing_raw);
    sys.write(" payload=");
    sys.printU64(payload);
    sys.write(" bytes=");
    sys.printU64(count);
    sys.write(" mutated=");
    sys.printU64(@intFromBool(count != 0 and buffer[0] != 0xA5));
    sys.write(" tail=");
    sys.printU64(@intFromBool(buffer[64] == 0xA5));
    sys.write(" handle_before=");
    sys.printU64(handle_before);
    sys.write(" close=");
    sys.printI32(close_raw);
    sys.write(" handle_after=");
    sys.printU64(handle_after);
    sys.write("\r\n");
    if (count == 0 or buffer[64] != 0xA5 or handle_before != 1 or close_raw != 0 or handle_after != 0) return 77;
    sys.println("APPZCON app entry: OK");
    return 0;
}

fn traySmoke(app: *r4os.App) i32 {
    var tray_client = switch (app.tray()) {
        .tray => |value| value,
        .failure => return 81,
    };
    var icon = traySmokeIcon();
    const first = r4os.TrayItem{
        .id = tray_smoke_item_id,
        .revision = 1,
        .tooltip = "Tray contract smoke",
        .icon = &icon,
    };
    const upsert = switch (tray_client.upsert(first, tray_smoke_timeout)) {
        .response => |value| value,
        else => return 82,
    };
    if (!upsert.succeeded() or !upsert.exists()) return 83;

    const delivery = switch (tray_client.waitEvent(0, tray_smoke_timeout)) {
        .event => |value| value,
        else => return 84,
    };
    if (delivery.event.item_id != tray_smoke_item_id or
        delivery.event.kind != r4os.abi.tray_event_kind_primary or
        delivery.event.sequence == 0)
    {
        return 85;
    }

    const removed = switch (tray_client.remove(tray_smoke_item_id, tray_smoke_timeout)) {
        .response => |value| value,
        else => return 86,
    };
    if (!removed.succeeded() or removed.exists()) return 87;

    // Leave one second item registered intentionally. The Desktop acceptance
    // reaps this exact generation and verifies owner-lifecycle cleanup.
    icon[0] = 0xffff_0000;
    const cleanup = switch (tray_client.upsert(.{
        .id = tray_smoke_cleanup_item_id,
        .revision = 1,
        .tooltip = "Tray owner cleanup",
        .icon = &icon,
    }, tray_smoke_timeout)) {
        .response => |value| value,
        else => return 88,
    };
    if (!cleanup.succeeded() or !cleanup.exists()) return 89;
    return 0;
}

fn traySmokeIcon() [r4os.app_tray.icon_pixel_count]u32 {
    var icon: [r4os.app_tray.icon_pixel_count]u32 = .{0} ** r4os.app_tray.icon_pixel_count;
    var y: usize = 0;
    while (y < r4os.app_tray.icon_height) : (y += 1) {
        var x: usize = 0;
        while (x < r4os.app_tray.icon_width) : (x += 1) {
            const border = x == 0 or y == 0 or x + 1 == r4os.app_tray.icon_width or y + 1 == r4os.app_tray.icon_height;
            const diagonal = x == y or x + y + 1 == r4os.app_tray.icon_width;
            icon[y * r4os.app_tray.icon_width + x] = if (border)
                0xff20_4070
            else if (diagonal)
                0xffff_ffff
            else
                0xff40_80d0;
        }
    }
    return icon;
}
