const interrupts = @import("../../arch/x86_64/interrupts.zig");
pub const MAX_USB_DEVICES: usize = 64 * 8;
pub const MAX_USB_CONFIGS: usize = 1;
pub const MAX_USB_INTERFACES: usize = 8;
pub const MAX_USB_ENDPOINTS: usize = 16;
pub const STRING_LEN: usize = 32;

pub const Interface = struct {
    active: bool = false,
    number: u8 = 0,
    class_code: u8 = 0,
    subclass: u8 = 0,
    protocol: u8 = 0,
    endpoint_count: u8 = 0,
    first_endpoint_address: u8 = 0,
    first_endpoint_attributes: u8 = 0,
    first_endpoint_max_packet: u16 = 0,
    first_endpoint_interval: u8 = 0,
    interrupt_in_endpoint_address: u8 = 0,
    interrupt_in_endpoint_max_packet: u16 = 0,
    interrupt_in_endpoint_interval: u8 = 0,
    bulk_in_endpoint_address: u8 = 0,
    bulk_in_endpoint_max_burst: u8 = 0,
    bulk_out_endpoint_address: u8 = 0,
    bulk_out_endpoint_max_burst: u8 = 0,
    hid_descriptor_len: u8 = 0,
    hid_report_descriptor_len: u16 = 0,
};

pub const Device = struct {
    controller_id: u32 = 0,
    generation: u64 = 0,
    active: bool = false,
    configured: bool = false,
    controller: []const u8 = "unknown",
    slot_id: u8 = 0,
    port: u8 = 0,
    speed: u8 = 0,
    usb_version_bcd: u16 = 0,
    vendor_id: u16 = 0,
    product_id: u16 = 0,
    device_version_bcd: u16 = 0,
    device_class: u8 = 0,
    device_subclass: u8 = 0,
    device_protocol: u8 = 0,
    config_value: u8 = 0,
    config_attributes: u8 = 0,
    config_max_power_ma: u16 = 0,
    interface_count: u8 = 0,
    interface_record_count: u8 = 0,
    interfaces: [MAX_USB_INTERFACES]Interface = .{Interface{}} ** MAX_USB_INTERFACES,
    endpoint_count: u8 = 0,
    first_interface_number: u8 = 0,
    first_interface_class: u8 = 0,
    first_interface_subclass: u8 = 0,
    first_interface_protocol: u8 = 0,
    first_endpoint_address: u8 = 0,
    first_endpoint_attributes: u8 = 0,
    first_endpoint_max_packet: u16 = 0,
    first_endpoint_interval: u8 = 0,
    hid_descriptor_len: u8 = 0,
    hid_report_descriptor_len: u16 = 0,
    bulk_in_endpoint_address: u8 = 0,
    bulk_in_endpoint_max_packet: u16 = 0,
    bulk_in_endpoint_max_burst: u8 = 0,
    bulk_out_endpoint_address: u8 = 0,
    bulk_out_endpoint_max_packet: u16 = 0,
    bulk_out_endpoint_max_burst: u8 = 0,
    string_language_id: u16 = 0,
    manufacturer_len: u8 = 0,
    product_len: u8 = 0,
    serial_len: u8 = 0,
    manufacturer_string: [STRING_LEN]u8 = .{0} ** STRING_LEN,
    product_string: [STRING_LEN]u8 = .{0} ** STRING_LEN,
    serial_string: [STRING_LEN]u8 = .{0} ** STRING_LEN,
};

pub const Summary = struct {
    count: u32 = 0,
    configured: u32 = 0,
    truncated: bool = false,
};

var devices: [MAX_USB_DEVICES]Device = .{Device{}} ** MAX_USB_DEVICES;
var device_count: u32 = 0;
var truncated: bool = false;

pub fn reset() void {
    const flags = interrupts.saveAndDisableRuntime();
    defer interrupts.restore(flags);
    for (devices[0..device_count]) |*device| device.* = .{};
    device_count = 0;
    truncated = false;
}

pub fn publishFirstDevice(device: Device) void {
    reset();
    _ = publishDevice(device);
}

pub fn publishDevice(device: Device) ?usize {
    const flags = interrupts.saveAndDisableRuntime();
    defer interrupts.restore(flags);
    var d = device;
    d.active = true;
    if (device_count >= MAX_USB_DEVICES) {
        truncated = true;
        return null;
    }
    const index: usize = @intCast(device_count);
    devices[index] = d;
    device_count += 1;
    return index;
}

pub fn publishOrReplaceByPort(device: Device) ?usize {
    const flags = interrupts.saveAndDisableRuntime();
    defer interrupts.restore(flags);
    var d = device;
    d.active = true;
    var i: usize = 0;
    while (i < device_count) : (i += 1) {
        if (devices[i].port == d.port and devices[i].controller_id == d.controller_id) {
            devices[i] = d;
            return i;
        }
    }
    return publishDevice(d);
}

pub fn removeByPort(controller: []const u8, port: u8) bool {
    const flags = interrupts.saveAndDisableRuntime();
    defer interrupts.restore(flags);
    var i: usize = 0;
    while (i < device_count) : (i += 1) {
        if (devices[i].port != port or !sameController(devices[i].controller, controller)) continue;
        var j = i;
        while (j + 1 < device_count) : (j += 1) {
            devices[j] = devices[j + 1];
        }
        if (device_count > 0) device_count -= 1;
        devices[@intCast(device_count)] = .{};
        return true;
    }
    return false;
}

pub fn count() usize {
    const flags = interrupts.saveAndDisableRuntime();
    defer interrupts.restore(flags);
    return device_count;
}

pub fn deviceAt(index: usize) ?Device {
    const flags = interrupts.saveAndDisableRuntime();
    defer interrupts.restore(flags);
    if (index >= device_count) return null;
    return devices[index];
}

pub fn removeController(id: u32) void {
    const flags = interrupts.saveAndDisableRuntime();
    defer interrupts.restore(flags);
    var keep: usize = 0;
    for (devices[0..device_count]) |device| {
        if (device.controller_id != id) {
            devices[keep] = device;
            keep += 1;
        }
    }
    for (devices[keep..device_count]) |*device| device.* = .{};
    device_count = @intCast(keep);
}
pub fn contains(id: u32, generation: u64, port: u8, slot: u8) bool {
    const flags = interrupts.saveAndDisableRuntime();
    defer interrupts.restore(flags);
    for (devices[0..device_count]) |device| {
        if (device.active and device.configured and device.controller_id == id and
            device.generation == generation and generation != 0 and device.port == port and device.slot_id == slot) return true;
    }
    return false;
}
pub fn countController(id: u32) u32 {
    const flags = interrupts.saveAndDisableRuntime();
    defer interrupts.restore(flags);
    var n: u32 = 0;
    for (devices[0..device_count]) |device| {
        if (device.controller_id == id) n += 1;
    }
    return n;
}

pub fn summary() Summary {
    const flags = interrupts.saveAndDisableRuntime();
    defer interrupts.restore(flags);
    var configured: u32 = 0;
    var i: usize = 0;
    while (i < device_count) : (i += 1) {
        if (devices[i].configured) configured += 1;
    }
    return .{
        .count = device_count,
        .configured = configured,
        .truncated = truncated,
    };
}

fn sameController(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    var i: usize = 0;
    while (i < a.len) : (i += 1) {
        if (a[i] != b[i]) return false;
    }
    return true;
}
