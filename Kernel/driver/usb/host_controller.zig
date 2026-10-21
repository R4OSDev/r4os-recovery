const bootlog = @import("../../kernel/bootlog.zig");
const builtin = @import("builtin");

pub const MAX_CONTROLLERS: usize = 64;
pub const MAX_NAME: usize = 32;

pub const BACKEND_VERSION: u32 = 2;
pub const FLAG_PORT_SCAN: u32 = 1 << 0;
pub const FLAG_CONTROL: u32 = 1 << 1;
pub const FLAG_BULK: u32 = 1 << 2;
pub const FLAG_INTERRUPT: u32 = 1 << 3;
pub const FLAG_EVENT_IRQ: u32 = 1 << 4;
pub const FLAG_POLL_FALLBACK: u32 = 1 << 5;
pub const FLAG_MULTI_TRANSFER: u32 = 1 << 6;
pub const FLAG_HOTPLUG: u32 = 1 << 7;

pub const Source = enum {
    builtin,
    preload,
    disk,
};

pub const State = enum {
    registered,
    active,
    failed,
};

pub const Status = extern struct {
    state: u32 = 0,
    source: u32 = 0,
    ports: u32 = 0,
    devices: u32 = 0,
    transfers: u64 = 0,
    failures: u64 = 0,
    flags: u32 = 0,
    queue_depth: u16 = 0,
    reserved0: u16 = 0,
    max_transfer_bytes: u32 = 0,
    active_transfers: u32 = 0,
    completions: u64 = 0,
    interrupts: u64 = 0,
    polls: u64 = 0,
    cancellations: u64 = 0,
};

pub const DeviceHandle = extern struct {
    controller_id: u32 = 0,
    port: u8 = 0,
    slot_id: u8 = 0,
    speed: u8 = 0,
    config_value: u8 = 0,
    vendor_id: u16 = 0,
    product_id: u16 = 0,
};

pub const EndpointHandle = extern struct {
    device: DeviceHandle = .{},
    kind: u32 = 0,
    address: u8 = 0,
    endpoint_id: u8 = 0,
    max_packet: u16 = 0,
    interval: u8 = 0,
    max_burst: u8 = 0,
};

pub const ControlRequest = extern struct {
    request_type: u8 = 0,
    request: u8 = 0,
    value: u16 = 0,
    index_value: u16 = 0,
    length: u16 = 0,
    direction: u32 = 0,
};

pub const Descriptor = extern struct {
    version: u32 = BACKEND_VERSION,
    size: u32 = @sizeOf(Descriptor),
    flags: u32 = 0,
    source: u32 = 0,
    context: ?*anyopaque = null,
    port_scan: ?*const fn (?*anyopaque) callconv(.c) i32 = null,
    address_device: ?*const fn (?*anyopaque, u8, *DeviceHandle) callconv(.c) i32 = null,
    configure_device: ?*const fn (?*anyopaque, *const DeviceHandle, u8) callconv(.c) i32 = null,
    control_transfer: ?*const fn (?*anyopaque, *const DeviceHandle, *const ControlRequest, [*]u8, u32) callconv(.c) i32 = null,
    bulk_transfer: ?*const fn (?*anyopaque, *const EndpointHandle, [*]u8, u32, u32) callconv(.c) i32 = null,
    interrupt_transfer: ?*const fn (?*anyopaque, *const EndpointHandle, [*]u8, u32, *u32) callconv(.c) i32 = null,
    reset_port: ?*const fn (?*anyopaque, u8) callconv(.c) i32 = null,
    clear_halt: ?*const fn (?*anyopaque, *const EndpointHandle) callconv(.c) i32 = null,
    reset_endpoint: ?*const fn (?*anyopaque, *const EndpointHandle) callconv(.c) i32 = null,
    poll: ?*const fn (?*anyopaque) callconv(.c) i32 = null,
    shutdown: ?*const fn (?*anyopaque) callconv(.c) i32 = null,
    status: ?*const fn (?*anyopaque, *Status) callconv(.c) i32 = null,
};

pub const Controller = struct {
    id: u32 = 0,
    callbacks: u32 = 0,
    closing: bool = false,
    used: bool = false,
    name: [MAX_NAME]u8 = .{0} ** MAX_NAME,
    name_len: usize = 0,
    source: Source = .builtin,
    owner_id: u32 = 0,
    state: State = .registered,
    descriptor: ?*const Descriptor = null,
    transfers: u64 = 0,
    failures: u64 = 0,
    polls: u64 = 0,
};

pub const CleanupResult = struct {
    removed: u32 = 0,
    failed: bool = false,
};

var controllers: [MAX_CONTROLLERS]Controller = .{Controller{}} ** MAX_CONTROLLERS;

var next_id: u32 = 1;
fn enter() u64 {
    if (comptime builtin.is_test) return 0;
    return @import("../../arch/x86_64/interrupts.zig").saveAndDisableRuntime();
}
fn leave(flags: u64) void {
    if (comptime builtin.is_test) return;
    @import("../../arch/x86_64/interrupts.zig").restore(flags);
}
pub fn reset() void {
    const flags = enter();
    defer leave(flags);
    controllers = .{Controller{}} ** MAX_CONTROLLERS;
}
pub fn registerBuiltIn(name: []const u8, descriptor: *const Descriptor) ?usize {
    return registerInternal(name, descriptor, 0, true);
}
pub fn register(name: []const u8, descriptor: *const Descriptor, owner_id: u32) ?usize {
    return registerInternal(name, descriptor, owner_id, false);
}
fn registerInternal(name: []const u8, descriptor: *const Descriptor, owner_id: u32, builtin_owner: bool) ?usize {
    const copied = block: {
        const flags = enter();
        defer leave(flags);
        if (findByName(name) != null or next_id == 0xffff_ffff) return null;
        const index = freeSlot() orelse return null;
        controllers[index] = .{ .used = true, .id = next_id, .source = if (builtin_owner) .builtin else sourceFromRaw(descriptor.source), .owner_id = owner_id, .state = if (builtin_owner) .active else .registered, .descriptor = descriptor };
        next_id += 1;
        copyName(name, &controllers[index]);
        break :block .{ .index = index, .value = controllers[index] };
    };
    if (!builtin.is_test) {
        bootlog.puts(if (builtin_owner) "[USBHC] register built-in " else "[USBHC] register backend ");
        bootlog.puts(copied.value.name[0..copied.value.name_len]);
        bootlog.puts("\r\n");
    }
    return copied.index;
}
pub fn setState(index: usize, state: State) bool {
    const flags = enter();
    defer leave(flags);
    const slot = mutableAt(index) orelse return false;
    slot.state = state;
    return true;
}
pub fn controllerId(index: usize) u32 {
    return if (at(index)) |slot| slot.id else 0;
}
pub fn indexFromControllerId(id: u32) ?usize {
    const flags = enter();
    defer leave(flags);
    if (id == 0) return null;
    for (controllers, 0..) |slot, index| {
        if (slot.used and slot.id == id) return index;
    }
    return null;
}
pub fn at(index: usize) ?Controller {
    const flags = enter();
    defer leave(flags);
    return if (mutableAt(index)) |slot| slot.* else null;
}
pub fn unregister(index: usize) bool {
    const slot = at(index) orelse return false;
    return unregisterExact(index, slot.id, slot.owner_id);
}
fn unregisterExact(index: usize, id: u32, owner: u32) bool {
    const copied = block: {
        const flags = enter();
        defer leave(flags);
        const slot = mutableAt(index) orelse return false;
        if (slot.id != id or slot.owner_id != owner or slot.closing or slot.callbacks != 0) return false;
        slot.closing = true;
        break :block slot.*;
    };
    if (copied.descriptor) |descriptor| {
        if (descriptor.shutdown) |shutdown| {
            if (shutdown(descriptor.context) < 0) {
                const flags = enter();
                defer leave(flags);
                const slot = &controllers[index];
                @import("std").debug.assert(slot.id == id and slot.closing);
                slot.closing = false;
                slot.state = .failed;
                slot.failures +%= 1;
                return false;
            }
        }
    }
    const flags = enter();
    defer leave(flags);
    @import("std").debug.assert(controllers[index].id == id and controllers[index].callbacks == 0 and controllers[index].closing);
    controllers[index] = .{};
    return true;
}
pub fn unregisterByName(name: []const u8, owner_id: u32) bool {
    if (eqIgnoreCase(name, "XHCI")) {
        var found = false;
        var all = true;
        for (0..MAX_CONTROLLERS) |index| {
            const slot = at(index) orelse continue;
            if (slot.owner_id != owner_id or !family(slot.name[0..slot.name_len])) continue;
            found = true;
            const ok = unregisterExact(index, slot.id, owner_id);
            all = ok and all;
        }
        return found and all;
    }
    const index = findByName(name) orelse return false;
    const slot = at(index) orelse return false;
    return unregisterExact(index, slot.id, owner_id);
}
pub fn cleanupOwner(owner_id: u32) CleanupResult {
    var result: CleanupResult = .{};
    if (owner_id == 0) return result;
    for (0..MAX_CONTROLLERS) |index| {
        const slot = at(index) orelse continue;
        if (slot.owner_id != owner_id) continue;
        if (unregisterExact(index, slot.id, owner_id)) result.removed += 1 else result.failed = true;
    }
    return result;
}
pub fn count() usize {
    const flags = enter();
    defer leave(flags);
    var n: usize = 0;
    for (controllers) |slot| {
        if (slot.used) n += 1;
    }
    return n;
}
const Lease = struct {
    index: usize,
    id: u32,
    descriptor: Descriptor,
    fn release(self: Lease) void {
        const flags = enter();
        defer leave(flags);
        const slot = &controllers[self.index];
        @import("std").debug.assert(slot.used and slot.id == self.id and slot.callbacks != 0);
        slot.callbacks -= 1;
    }
    fn account(self: Lease, result: i32, transfer: bool) i32 {
        const flags = enter();
        defer leave(flags);
        const slot = &controllers[self.index];
        @import("std").debug.assert(slot.used and slot.id == self.id and slot.callbacks != 0);
        if (transfer) slot.transfers +%= 1;
        if (result < 0) slot.failures +%= 1;
        return result;
    }
};
fn takeLease(index: usize, expected: ?u32) ?Lease {
    const flags = enter();
    defer leave(flags);
    const slot = mutableAt(index) orelse return null;
    if (slot.closing or slot.callbacks == 0xffff_ffff or (expected != null and slot.id != expected.?)) return null;
    const descriptor = slot.descriptor orelse return null;
    slot.callbacks += 1;
    return .{ .index = index, .id = slot.id, .descriptor = descriptor.* };
}
fn deviceLease(device: DeviceHandle) ?Lease {
    const index = indexFromControllerId(device.controller_id) orelse return null;
    return takeLease(index, device.controller_id);
}
pub fn statusAt(index: usize, out: *Status) i32 {
    return statusAtExpected(index, null, out);
}
pub fn statusById(id: u32, out: *Status) i32 {
    const index = indexFromControllerId(id) orelse return -1;
    return statusAtExpected(index, id, out);
}
fn statusAtExpected(index: usize, expected: ?u32, out: *Status) i32 {
    const lease = takeLease(index, expected) orelse return -1;
    defer lease.release();
    const initial = at(index).?;
    out.* = .{ .state = stateRaw(initial.state), .source = sourceRaw(initial.source), .transfers = initial.transfers, .failures = initial.failures, .polls = initial.polls };
    const descriptor = lease.descriptor;
    if (descriptor.status) |callback| {
        const rc = callback(descriptor.context, out);
        if (rc < 0) return lease.account(rc, false);
    }
    const slot = at(index).?;
    out.state = stateRaw(slot.state);
    out.source = sourceRaw(slot.source);
    out.flags |= descriptor.flags;
    out.transfers = @max(out.transfers, slot.transfers);
    out.failures = @max(out.failures, slot.failures);
    out.polls = @max(out.polls, slot.polls);
    return 0;
}
pub fn scan(index: usize) i32 {
    const lease = takeLease(index, null) orelse return -1;
    defer lease.release();
    const d = lease.descriptor;
    const callback = d.port_scan orelse return lease.account(-3, false);
    return lease.account(callback(d.context), false);
}
pub fn addressDevice(index: usize, port: u8, out: *DeviceHandle) i32 {
    const lease = takeLease(index, null) orelse return -1;
    defer lease.release();
    const d = lease.descriptor;
    const callback = d.address_device orelse return lease.account(-3, false);
    const rc = callback(d.context, port, out);
    if (rc >= 0) out.controller_id = lease.id;
    return lease.account(rc, false);
}
pub fn configureDevice(device: *const DeviceHandle, configuration: u8) i32 {
    const lease = deviceLease(device.*) orelse return -1;
    defer lease.release();
    const d = lease.descriptor;
    const callback = d.configure_device orelse return lease.account(-3, false);
    return lease.account(callback(d.context, device, configuration), false);
}
pub fn controlTransfer(device: *const DeviceHandle, request: *const ControlRequest, buffer: []u8) i32 {
    const lease = deviceLease(device.*) orelse return -1;
    defer lease.release();
    const d = lease.descriptor;
    const callback = d.control_transfer orelse return lease.account(-3, false);
    return lease.account(callback(d.context, device, request, buffer.ptr, @intCast(buffer.len)), true);
}
pub fn bulkTransfer(endpoint: *const EndpointHandle, buffer: []u8, direction: u32) i32 {
    const lease = deviceLease(endpoint.device) orelse return -1;
    defer lease.release();
    const d = lease.descriptor;
    const callback = d.bulk_transfer orelse return lease.account(-3, false);
    return lease.account(callback(d.context, endpoint, buffer.ptr, @intCast(buffer.len), direction), true);
}
pub fn interruptTransfer(endpoint: *const EndpointHandle, buffer: []u8, actual: *u32) i32 {
    const lease = deviceLease(endpoint.device) orelse return -1;
    defer lease.release();
    const d = lease.descriptor;
    const callback = d.interrupt_transfer orelse return lease.account(-3, false);
    return lease.account(callback(d.context, endpoint, buffer.ptr, @intCast(buffer.len), actual), true);
}
pub fn resetPort(index: usize, port: u8) i32 {
    const lease = takeLease(index, null) orelse return -1;
    defer lease.release();
    const d = lease.descriptor;
    const callback = d.reset_port orelse return lease.account(-3, false);
    return lease.account(callback(d.context, port), false);
}
pub fn clearHalt(endpoint: *const EndpointHandle) i32 {
    return endpointAction(endpoint, false);
}
pub fn resetEndpoint(endpoint: *const EndpointHandle) i32 {
    return endpointAction(endpoint, true);
}
fn endpointAction(endpoint: *const EndpointHandle, reset_endpoint: bool) i32 {
    const lease = deviceLease(endpoint.device) orelse return -1;
    defer lease.release();
    const d = lease.descriptor;
    const callback = (if (reset_endpoint) d.reset_endpoint else d.clear_halt) orelse return lease.account(-3, false);
    return lease.account(callback(d.context, endpoint), false);
}
pub fn poll(index: usize) i32 {
    const lease = takeLease(index, null) orelse return -1;
    defer lease.release();
    const d = lease.descriptor;
    const callback = d.poll orelse return lease.account(-3, false);
    {
        const flags = enter();
        defer leave(flags);
        controllers[index].polls +%= 1;
    }
    return lease.account(callback(d.context), false);
}
fn family(name: []const u8) bool {
    return eqIgnoreCase(name, "XHCI") or (name.len >= 5 and eqIgnoreCase(name[0..5], "XHCI@"));
}
pub fn findByName(name: []const u8) ?usize {
    const flags = enter();
    defer leave(flags);
    for (controllers, 0..) |slot, index| {
        if (slot.used and (eqIgnoreCase(slot.name[0..slot.name_len], name) or (eqIgnoreCase(name, "XHCI") and family(slot.name[0..slot.name_len])))) return index;
    }
    return null;
}
pub fn sourceLabel(source: Source) []const u8 {
    return switch (source) {
        .builtin => "built-in",
        .preload => "preload",
        .disk => "disk",
    };
}
fn freeSlot() ?usize {
    for (controllers, 0..) |slot, index| {
        if (!slot.used) return index;
    }
    return null;
}
fn mutableAt(index: usize) ?*Controller {
    return if (index < controllers.len and controllers[index].used) &controllers[index] else null;
}

fn stateRaw(state: State) u32 {
    return switch (state) {
        .registered => 0,
        .active => 1,
        .failed => 2,
    };
}

fn sourceRaw(source: Source) u32 {
    return switch (source) {
        .builtin => 0,
        .preload => 1,
        .disk => 2,
    };
}

fn sourceFromRaw(source: u32) Source {
    return switch (source) {
        1 => .preload,
        2 => .disk,
        else => .builtin,
    };
}

fn copyName(name: []const u8, slot: *Controller) void {
    const n = if (name.len < slot.name.len) name.len else slot.name.len - 1;
    if (n > 0) @memcpy(slot.name[0..n], name[0..n]);
    slot.name[n] = 0;
    slot.name_len = n;
}

fn eqIgnoreCase(a: []const u8, b: []const u8) bool {
    if (a.len != b.len) return false;
    var i: usize = 0;
    while (i < a.len) : (i += 1) {
        if (upper(a[i]) != upper(b[i])) return false;
    }
    return true;
}

fn upper(ch: u8) u8 {
    if (ch >= 'a' and ch <= 'z') return ch - ('a' - 'A');
    return ch;
}

var test_shutdown_ok = true;
var test_shutdowns: u32 = 0;

fn testPortScan(_: ?*anyopaque) callconv(.c) i32 {
    return 1;
}

fn testAddress(_: ?*anyopaque, port: u8, out: *DeviceHandle) callconv(.c) i32 {
    out.* = .{ .port = port, .slot_id = 7, .speed = 3 };
    return 0;
}

fn testConfigure(_: ?*anyopaque, _: *const DeviceHandle, _: u8) callconv(.c) i32 {
    return 0;
}

fn testControl(_: ?*anyopaque, _: *const DeviceHandle, _: *const ControlRequest, _: [*]u8, len: u32) callconv(.c) i32 {
    return @intCast(len);
}

fn testBulk(_: ?*anyopaque, _: *const EndpointHandle, _: [*]u8, len: u32, _: u32) callconv(.c) i32 {
    return @intCast(len);
}

fn testInterrupt(_: ?*anyopaque, _: *const EndpointHandle, _: [*]u8, len: u32, actual: *u32) callconv(.c) i32 {
    actual.* = len;
    return 1;
}

fn testEndpoint(_: ?*anyopaque, _: *const EndpointHandle) callconv(.c) i32 {
    return 0;
}

fn testPort(_: ?*anyopaque, _: u8) callconv(.c) i32 {
    return 0;
}

fn testPoll(_: ?*anyopaque) callconv(.c) i32 {
    return 1;
}

fn testShutdown(_: ?*anyopaque) callconv(.c) i32 {
    test_shutdowns += 1;
    return if (test_shutdown_ok) 0 else -1;
}

fn testStatus(_: ?*anyopaque, out: *Status) callconv(.c) i32 {
    out.queue_depth = 8;
    out.max_transfer_bytes = 65_536;
    out.active_transfers = 2;
    out.completions = 9;
    return 0;
}

fn testDescriptor() Descriptor {
    return .{
        .flags = FLAG_PORT_SCAN | FLAG_CONTROL | FLAG_BULK | FLAG_INTERRUPT | FLAG_POLL_FALLBACK,
        .source = 1,
        .port_scan = testPortScan,
        .address_device = testAddress,
        .configure_device = testConfigure,
        .control_transfer = testControl,
        .bulk_transfer = testBulk,
        .interrupt_transfer = testInterrupt,
        .reset_port = testPort,
        .clear_halt = testEndpoint,
        .reset_endpoint = testEndpoint,
        .poll = testPoll,
        .shutdown = testShutdown,
        .status = testStatus,
    };
}

test "registered USB host dispatches every productive operation and status" {
    const testing = @import("std").testing;
    reset();
    test_shutdown_ok = true;
    test_shutdowns = 0;
    var descriptor = testDescriptor();
    const index = register("TESTHC", &descriptor, 77) orelse return error.NoControllerSlot;
    try testing.expect(setState(index, .active));
    try testing.expectEqual(@as(i32, 1), scan(index));

    var device: DeviceHandle = .{};
    try testing.expectEqual(@as(i32, 0), addressDevice(index, 4, &device));
    try testing.expectEqual(controllerId(index), device.controller_id);
    try testing.expectEqual(@as(u8, 7), device.slot_id);
    try testing.expectEqual(@as(i32, 0), configureDevice(&device, 1));

    var endpoint: EndpointHandle = .{ .device = device, .kind = 2, .endpoint_id = 3 };
    var request: ControlRequest = .{};
    var bytes: [32]u8 = .{0} ** 32;
    var actual: u32 = 0;
    try testing.expectEqual(@as(i32, 32), controlTransfer(&device, &request, bytes[0..]));
    try testing.expectEqual(@as(i32, 32), bulkTransfer(&endpoint, bytes[0..], 1));
    try testing.expectEqual(@as(i32, 1), interruptTransfer(&endpoint, bytes[0..], &actual));
    try testing.expectEqual(@as(u32, 32), actual);
    try testing.expectEqual(@as(i32, 0), resetPort(index, 4));
    try testing.expectEqual(@as(i32, 0), clearHalt(&endpoint));
    try testing.expectEqual(@as(i32, 0), resetEndpoint(&endpoint));
    try testing.expectEqual(@as(i32, 1), poll(index));

    var host_status: Status = .{};
    try testing.expectEqual(@as(i32, 0), statusAt(index, &host_status));
    try testing.expectEqual(@as(u16, 8), host_status.queue_depth);
    try testing.expectEqual(@as(u32, 65_536), host_status.max_transfer_bytes);
    try testing.expectEqual(@as(u64, 3), host_status.transfers);
    try testing.expectEqual(@as(u64, 1), host_status.polls);
    try testing.expect((host_status.flags & FLAG_BULK) != 0);
    try testing.expect(unregisterByName("testhc", 77));
    try testing.expectEqual(@as(u32, 1), test_shutdowns);
    try testing.expectEqual(@as(usize, 0), count());
}

test "failed host shutdown vetoes unregister and owner cleanup" {
    const testing = @import("std").testing;
    reset();
    test_shutdown_ok = false;
    test_shutdowns = 0;
    var descriptor = testDescriptor();
    const index = register("TESTHC", &descriptor, 88) orelse return error.NoControllerSlot;
    try testing.expect(!unregisterByName("TESTHC", 77));
    try testing.expect(!unregister(index));
    try testing.expectEqual(State.failed, at(index).?.state);
    const failed_cleanup = cleanupOwner(88);
    try testing.expect(failed_cleanup.failed);
    try testing.expectEqual(@as(u32, 0), failed_cleanup.removed);
    try testing.expectEqual(@as(usize, 1), count());

    test_shutdown_ok = true;
    const cleanup = cleanupOwner(88);
    try testing.expect(!cleanup.failed);
    try testing.expectEqual(@as(u32, 1), cleanup.removed);
    try testing.expectEqual(@as(usize, 0), count());
}

test "controller IDs distinguish equal local addresses and survive slot reuse" {
    const testing = @import("std").testing;
    reset();
    test_shutdown_ok = true;
    const descriptor = testDescriptor();
    const first = register("XHCI@00:06.0", &descriptor, 42).?;
    const second = register("XHCI@00:07.0", &descriptor, 42).?;
    var a: DeviceHandle = .{};
    var b: DeviceHandle = .{};
    try testing.expectEqual(@as(i32, 0), addressDevice(first, 1, &a));
    try testing.expectEqual(@as(i32, 0), addressDevice(second, 1, &b));
    try testing.expect(a.port == b.port and a.slot_id == b.slot_id and a.controller_id != b.controller_id);
    try testing.expect(unregister(first));
    const replacement = register("XHCI@00:08.0", &descriptor, 42).?;
    try testing.expectEqual(first, replacement);
    try testing.expect(controllerId(replacement) != a.controller_id);
    var bytes: [8]u8 = .{0} ** 8;
    const stale: EndpointHandle = .{ .device = a, .kind = 2 };
    try testing.expectEqual(@as(i32, -1), bulkTransfer(&stale, &bytes, 0));
    const live: EndpointHandle = .{ .device = b, .kind = 2 };
    try testing.expectEqual(@as(i32, 8), bulkTransfer(&live, &bytes, 0));
    try testing.expect(unregisterByName("xhci", 42));
    try testing.expectEqual(@as(usize, 0), count());
}

fn pinnedScan(_: ?*anyopaque) callconv(.c) i32 {
    return if (unregisterByName("XHCI", 77)) -99 else 0;
}
test "active callback vetoes exact family unregister" {
    const testing = @import("std").testing;
    reset();
    test_shutdown_ok = true;
    var descriptor = testDescriptor();
    descriptor.port_scan = pinnedScan;
    const slot = register("XHCI@00:06.0", &descriptor, 77).?;
    try testing.expectEqual(@as(i32, 0), scan(slot));
    try testing.expectEqual(@as(usize, 1), count());
    try testing.expect(unregisterByName("XHCI", 77));
}
