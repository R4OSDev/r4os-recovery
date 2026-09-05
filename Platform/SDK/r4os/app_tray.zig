const std = @import("std");
const abi = @import("r4os_contract").abi;
const r4sys = @import("r4sys.zig");
const services_facade = @import("app_services.zig");
const time_contract = @import("time_contract.zig");

/// The logical tray contract is multiplexed by the existing window service;
/// R4DESK remains the sole owner of notification-area layout and input.
pub const service_name: [:0]const u8 = "WINSVC";
pub const Timeout = time_contract.Timeout;
pub const icon_width: usize = abi.tray_icon_width;
pub const icon_height: usize = abi.tray_icon_height;
pub const icon_pixel_count: usize = abi.tray_icon_pixel_count;
pub const max_tooltip_bytes: usize = abi.tray_tooltip_bytes;

const valid_item_flags = abi.tray_item_flag_visible |
    abi.tray_item_flag_enabled |
    abi.tray_item_flag_attention;

pub const Item = struct {
    id: u64,
    revision: u64,
    flags: u32 = abi.tray_item_flag_visible | abi.tray_item_flag_enabled,
    status_flags: u32 = 0,
    tooltip: []const u8 = "",
    icon: *const [icon_pixel_count]u32,
};

pub const OpenResult = union(enum) {
    tray: Tray,
    failure: i32,
};

pub const Snapshot = struct {
    raw: abi.TrayServiceResponse,
    epoch_changed: bool,

    pub fn succeeded(self: *const Snapshot) bool {
        return self.raw.result == abi.tray_result_ok;
    }

    pub fn exists(self: *const Snapshot) bool {
        return (self.raw.flags & abi.tray_response_flag_exists) != 0;
    }

    pub fn layoutVisible(self: *const Snapshot) bool {
        return (self.raw.flags & abi.tray_response_flag_layout_visible) != 0;
    }

    pub fn changed(self: *const Snapshot) bool {
        return (self.raw.flags & abi.tray_response_flag_changed) != 0;
    }
};

pub const CallResult = union(enum) {
    response: Snapshot,
    timed_out,
    no_service: i32,
    failure: i32,
};

pub const EventDelivery = struct {
    event: abi.TrayEvent,
    desktop_epoch: u64,
    epoch_changed: bool,
};

pub const WaitResult = union(enum) {
    event: EventDelivery,
    timed_out,
    busy,
    no_service: i32,
    failure: i32,
};

pub const Tray = struct {
    sys: r4sys.Context,
    owner: abi.ProgramProcessHandle,
    desktop_epoch: u64 = 0,

    pub fn open(sys: r4sys.Context, instance_id: u64) OpenResult {
        if (!sys.hasFn("program_open_handle") or
            !sys.hasFn("service_open") or
            !sys.hasFn("service_close") or
            !sys.hasFn("service_call") or
            instance_id == 0 or instance_id > std.math.maxInt(u32))
        {
            return .{ .failure = abi.err_no_fn };
        }

        var owner: abi.ProgramProcessHandle = .{};
        const raw = sys.programOpenHandle(@intCast(instance_id), &owner);
        if (raw != abi.program_handle_ok or !validOwner(owner)) {
            return .{ .failure = if (raw == abi.program_handle_ok) abi.program_handle_error_invalid else raw };
        }
        return .{ .tray = .{ .sys = sys, .owner = owner } };
    }

    pub fn status(self: *Tray, item_id: u64, timeout: Timeout) CallResult {
        var request = baseRequest(self.owner);
        request.item_id = item_id;
        return self.call(abi.tray_service_op_status, &request, timeout);
    }

    pub fn upsert(self: *Tray, item: Item, timeout: Timeout) CallResult {
        const request = itemRequest(self.owner, item) orelse return .{ .failure = abi.tray_result_bad_request };
        return self.call(abi.tray_service_op_upsert, &request, timeout);
    }

    pub fn remove(self: *Tray, item_id: u64, timeout: Timeout) CallResult {
        if (item_id == 0) return .{ .failure = abi.tray_result_bad_request };
        var request = baseRequest(self.owner);
        request.item_id = item_id;
        return self.call(abi.tray_service_op_remove, &request, timeout);
    }

    /// One finite long-poll is allowed per exact owner. `forever` is rejected
    /// so a provider always retains a deterministic close/re-register point.
    pub fn waitEvent(self: *Tray, after_sequence: u64, timeout: Timeout) WaitResult {
        if (timeout.kind == abi.timeout_kind_forever) return .{ .failure = abi.tray_result_bad_request };
        const budget = time_contract.timeoutToTicks(timeout, self.sys.monotonicHz()) catch return .{ .failure = abi.tray_result_bad_request };
        var request = baseRequest(self.owner);
        request.after_sequence = after_sequence;
        // Keep one scheduler tick for the service-call reply path itself.
        const server_budget = if (budget > 0) budget - 1 else 0;
        request.deadline_tick = self.sys.ticks() +| server_budget;

        return switch (self.call(abi.tray_service_op_wait_event, &request, timeout)) {
            .response => |snapshot| blk: {
                if (snapshot.raw.result == abi.tray_result_timeout) break :blk .timed_out;
                if (snapshot.raw.result == abi.tray_result_busy) break :blk .busy;
                if (snapshot.raw.result != abi.tray_result_ok) break :blk .{ .failure = snapshot.raw.result };
                if ((snapshot.raw.flags & abi.tray_response_flag_event) == 0 or
                    !validEvent(&snapshot.raw.event, self.owner))
                {
                    break :blk .{ .failure = abi.service_api_result_invalid };
                }
                break :blk .{ .event = .{
                    .event = snapshot.raw.event,
                    .desktop_epoch = snapshot.raw.desktop_epoch,
                    .epoch_changed = snapshot.epoch_changed,
                } };
            },
            .timed_out => .timed_out,
            .no_service => |raw| .{ .no_service = raw },
            .failure => |raw| .{ .failure = raw },
        };
    }

    fn call(self: *Tray, op: u16, request: *const abi.TrayServiceRequest, timeout: Timeout) CallResult {
        var services = services_facade.Services{ .sys = self.sys };
        var connection = switch (services.open(service_name.ptr)) {
            .connection => |value| value,
            .failure => |raw| return .{ .no_service = raw },
        };
        defer _ = connection.close();

        return switch (connection.callTyped(abi.TrayServiceRequest, abi.TrayServiceResponse, op, request, timeout)) {
            .value => |response| blk: {
                if (!validResponse(&response, self.owner)) break :blk .{ .failure = abi.service_api_result_invalid };
                const changed = self.desktop_epoch != 0 and self.desktop_epoch != response.desktop_epoch;
                self.desktop_epoch = response.desktop_epoch;
                break :blk .{ .response = .{ .raw = response, .epoch_changed = changed } };
            },
            .timed_out => .timed_out,
            .remote_failure => |raw| .{ .failure = raw },
            .failure => |raw| if (serviceUnavailable(raw)) .{ .no_service = raw } else .{ .failure = raw },
        };
    }
};

fn baseRequest(owner: abi.ProgramProcessHandle) abi.TrayServiceRequest {
    return .{
        .magic = abi.tray_service_request_magic,
        .version = abi.tray_service_request_version,
        .size = @sizeOf(abi.TrayServiceRequest),
        .owner = owner,
    };
}

fn itemRequest(owner: abi.ProgramProcessHandle, item: Item) ?abi.TrayServiceRequest {
    if (!validOwner(owner) or item.id == 0 or item.revision == 0 or
        item.tooltip.len > max_tooltip_bytes or
        !std.unicode.utf8ValidateSlice(item.tooltip) or
        (item.flags & ~valid_item_flags) != 0)
    {
        return null;
    }

    var request = baseRequest(owner);
    request.item_id = item.id;
    request.item_revision = item.revision;
    request.item_flags = item.flags;
    request.status_flags = item.status_flags;
    request.tooltip_length = @intCast(item.tooltip.len);
    request.icon_width = @intCast(icon_width);
    request.icon_height = @intCast(icon_height);
    request.icon_format = abi.tray_icon_format_argb32;
    @memcpy(request.tooltip[0..item.tooltip.len], item.tooltip);
    request.icon = item.icon.*;
    return request;
}

fn validResponse(response: *const abi.TrayServiceResponse, owner: abi.ProgramProcessHandle) bool {
    return response.magic == abi.tray_service_response_magic and
        response.version == abi.tray_service_response_version and
        response.size == @sizeOf(abi.TrayServiceResponse) and
        (response.desktop_epoch != 0 or response.result == abi.tray_result_not_found) and
        sameOwner(response.owner, owner) and
        response.capacity == abi.tray_max_items;
}

fn validEvent(event: *const abi.TrayEvent, owner: abi.ProgramProcessHandle) bool {
    return event.magic == abi.tray_event_magic and
        event.version == abi.tray_event_version and
        event.size == @sizeOf(abi.TrayEvent) and
        event.sequence != 0 and
        event.item_id != 0 and
        sameOwner(event.owner, owner) and
        (event.kind == abi.tray_event_kind_primary or
            event.kind == abi.tray_event_kind_double or
            event.kind == abi.tray_event_kind_context or
            event.kind == abi.tray_event_kind_wheel);
}

fn validOwner(owner: abi.ProgramProcessHandle) bool {
    return owner.instance_id != 0 and owner.generation != 0 and owner.reserved == 0;
}

fn sameOwner(a: abi.ProgramProcessHandle, b: abi.ProgramProcessHandle) bool {
    return a.instance_id == b.instance_id and a.generation == b.generation and a.reserved == b.reserved;
}

fn serviceUnavailable(raw: i32) bool {
    return raw == abi.service_api_result_no_endpoint or
        raw == abi.service_api_result_not_running or
        raw == abi.service_api_result_bad_handle;
}

test "tray item request is fixed, copied and rejects conflicting input" {
    const owner = abi.ProgramProcessHandle{ .instance_id = 7, .generation = 99 };
    var icon: [icon_pixel_count]u32 = .{0} ** icon_pixel_count;
    icon[3] = 0x8044_3322;
    const request = itemRequest(owner, .{
        .id = 17,
        .revision = 4,
        .tooltip = "Lautstaerke",
        .icon = &icon,
    }).?;
    try std.testing.expectEqual(@as(u16, 16), request.icon_width);
    try std.testing.expectEqual(@as(u16, 11), request.tooltip_length);
    try std.testing.expectEqual(@as(u32, 0x8044_3322), request.icon[3]);
    icon[3] = 0;
    try std.testing.expectEqual(@as(u32, 0x8044_3322), request.icon[3]);
    try std.testing.expect(itemRequest(owner, .{ .id = 17, .revision = 0, .icon = &icon }) == null);
    try std.testing.expect(itemRequest(owner, .{ .id = 17, .revision = 1, .flags = 0x8000_0000, .icon = &icon }) == null);
}

test "tray response and event validation bind the exact process generation" {
    const owner = abi.ProgramProcessHandle{ .instance_id = 3, .generation = 44 };
    var response: abi.TrayServiceResponse = .{
        .desktop_epoch = 8,
        .owner = owner,
        .capacity = abi.tray_max_items,
    };
    try std.testing.expect(validResponse(&response, owner));
    response.owner.generation += 1;
    try std.testing.expect(!validResponse(&response, owner));

    response.owner = owner;
    response.desktop_epoch = 0;
    response.result = abi.tray_result_not_found;
    try std.testing.expect(validResponse(&response, owner));
    response.result = abi.tray_result_ok;
    try std.testing.expect(!validResponse(&response, owner));

    const event: abi.TrayEvent = .{
        .sequence = 1,
        .owner = owner,
        .item_id = 5,
        .kind = abi.tray_event_kind_primary,
    };
    try std.testing.expect(validEvent(&event, owner));
    try std.testing.expect(!validEvent(&event, .{ .instance_id = 3, .generation = 45 }));
}
