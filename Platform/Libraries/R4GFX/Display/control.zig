//! Userland display configuration vocabulary shared by Desktop and its UI.
//! WINSVC transports the copied Contract types; callers own graphics policy.
const std = @import("std");
const r4os = @import("r4os");
const a = r4os.abi;
pub const topology = @import("topology.zig");
pub const confirmation_ns = 15 * std.time.ns_per_s;
pub const operation_ns = 30 * std.time.ns_per_s;
pub const Error = topology.Error || error{ Stale, Unsupported, Unavailable, Save };
pub fn active(phase: u32) bool { return phase == 1 or phase == 2 or phase == 3; }
pub fn encode(layout: *const topology.Layout) a.DisplayLayout {
    var value: a.DisplayLayout = .{ .count = @intCast(layout.count), .topology_revision = layout.revision };
    for (layout.outputs[0..layout.count], 0..) |output, i| value.outputs[i] = .{
        .adapter_id = output.key.adapter, .connector_id = output.key.connector, .receiver = output.key.receiver,
        .flags = @as(u32, @intFromBool(output.enabled)) | (@as(u32, @intFromBool(output.primary)) << 1),
        .x = output.view.origin.x, .y = output.view.origin.y, .width = output.view.pixel_w, .height = output.view.pixel_h,
        .scale = output.view.scale, .rotation = @intFromEnum(output.view.rotation),
        .refresh_millihz = output.refresh_millihz, .clone_group = output.clone_group,
    };
    return value;
}
pub fn decode(value: *const a.DisplayLayout) Error!topology.Layout {
    if (value.version != 1 or value.size != @sizeOf(a.DisplayLayout) or value.reserved != 0 or value.count > topology.capacity) return error.Invalid;
    var outputs: [topology.capacity]topology.Output = undefined;
    for (value.outputs[0..value.count], 0..) |output, i| {
        if (output.flags & ~@as(u32, 3) != 0 or output.rotation > 3 or output.clone_group > 255) return error.Invalid;
        outputs[i] = .{ .key = .{ .adapter = output.adapter_id, .connector = output.connector_id, .receiver = output.receiver },
            .view = .{ .origin = .{ .x = output.x, .y = output.y }, .pixel_w = output.width, .pixel_h = output.height,
                .scale = output.scale, .rotation = @enumFromInt(output.rotation) },
            .enabled = output.flags & 1 != 0, .primary = output.flags & 2 != 0,
            .refresh_millihz = output.refresh_millihz, .clone_group = @intCast(output.clone_group) };
        try outputs[i].view.validate();
    }
    return topology.Layout.init(outputs[0..value.count], value.topology_revision);
}
pub fn normalized(layout: topology.Layout) Error!topology.Layout {
    var value = layout;
    const origin = value.outputs[value.primary].view.origin;
    for (value.outputs[0..value.count]) |*output| {
        output.view.origin.x = std.math.sub(i32, output.view.origin.x, origin.x) catch return error.Bounds;
        output.view.origin.y = std.math.sub(i32, output.view.origin.y, origin.y) catch return error.Bounds;
    }
    return topology.Layout.init(value.outputs[0..value.count], value.revision);
}
pub fn find(layout: *const topology.Layout, key: topology.Key) ?usize {
    for (layout.outputs[0..layout.count], 0..) |value, i| if (std.meta.eql(value.key, key)) return i;
    return null;
}
pub fn matches(actual: *const topology.Layout, desired: *const topology.Layout) bool {
    if (actual.count != desired.count) return false;
    for (desired.outputs[0..desired.count]) |choice| {
        const index = find(actual, choice.key) orelse return false;
        const value = actual.outputs[index];
        if (!std.meta.eql(value.view, choice.view) or value.enabled != choice.enabled or value.primary != choice.primary or
            value.clone_group != choice.clone_group or (choice.refresh_millihz != 0 and value.refresh_millihz != choice.refresh_millihz)) return false;
    }
    return true;
}
pub fn persistent(layout: *const topology.Layout) bool {
    for (layout.outputs[0..layout.count]) |value| if (!value.key.persistable()) return false;
    return layout.count != 0;
}

pub const Client = struct {
    owner: a.ProgramProcessHandle = .{},
    state: a.DisplayControlStatus = .{},
    next_request: u64 = 1,
    pending: ?a.DisplayControlRequest = null,
    pending_color: ?a.DisplayColorSelection = null,
    last_error: i32 = 0,
    pub fn init(sys: *const r4os.r4sys.Context, instance: u64) ?Client {
        if (instance == 0 or instance > std.math.maxInt(u32)) return null;
        var value: Client = .{};
        if (sys.programOpenHandle(@intCast(instance), &value.owner) != a.program_handle_ok) return null;
        return value;
    }
    fn call(self: *Client, sys: *const r4os.r4sys.Context, op: u16, payload: anytype) bool {
        var endpoint: a.ServiceInfo = .{};
        var rc = sys.serviceOpen(a.window_service_name, &endpoint);
        if (rc != a.service_api_result_ok or endpoint.handle == 0) { self.last_error = if (rc != 0) rc else -3; return false; }
        defer _ = sys.serviceClose(endpoint.handle);
        var header: a.ServiceMessageHeader = .{};
        var response: a.DisplayControlStatus = .{};
        rc = sys.serviceCall(endpoint.handle, op, std.mem.asBytes(payload), &header, std.mem.asBytes(&response), sys.ticksFromMilliseconds(250));
        if (rc >= 0 and header.status != a.service_api_result_ok) {
            self.last_error = header.status;
            if (op == a.display_control_op_color_request and header.status == a.service_api_result_bad_op) {
                self.pending = null; self.pending_color = null;
            }
            return false;
        }
        if (rc != @sizeOf(a.DisplayControlStatus) or header.status != a.service_api_result_ok or
            response.magic != a.display_control_status_magic or response.version != 1 or response.size != @sizeOf(a.DisplayControlStatus) or
            response.phase > 6 or response.flags & ~@as(u32, 3) != 0 or response.layout.count > topology.capacity) {
            self.last_error = if (rc < 0) rc else -1; return false;
        }
        self.state = response; self.last_error = response.result;
        if (self.pending) |pending| {
            if (response.desktop_epoch != pending.desktop_epoch or
                (response.request_id == pending.request_id and std.meta.eql(response.owner, self.owner))) { self.pending = null; self.pending_color = null; }
        }
        return true;
    }
    pub fn poll(self: *Client, sys: *const r4os.r4sys.Context) bool {
        const payload: a.DisplayControlRequest = .{ .owner = self.owner };
        return self.call(sys, a.display_control_op_query, &payload);
    }
    pub fn request(self: *Client, sys: *const r4os.r4sys.Context, action: u32, layout: ?*const topology.Layout) bool {
        if (self.pending != null or self.next_request == std.math.maxInt(u64)) return false;
        const request_value: a.DisplayControlRequest = .{ .owner = self.owner, .desktop_epoch = self.state.desktop_epoch,
            .request_id = self.next_request, .base_revision = self.state.revision,
            .transaction_id = if (action == 1) 0 else self.state.transaction_id, .action = action,
            .layout = if (layout) |value| encode(value) else .{} };
        self.next_request += 1;
        // Keep the exact request after a transport timeout: it may already
        // have reached Desktop. A fresh request must not repeat its effects.
        self.pending = request_value; self.pending_color = null;
        if (!self.call(sys, a.display_control_op_request, &request_value)) return false;
        if (self.state.result != 0) { self.pending = null; return false; }
        return true;
    }
    pub fn requestColor(self: *Client, sys: *const r4os.r4sys.Context, selection: a.DisplayColorSelection) bool {
        if (self.pending != null or self.next_request == std.math.maxInt(u64)) return false;
        const request_value: a.DisplayColorRequest = .{ .base = .{ .owner = self.owner, .desktop_epoch = self.state.desktop_epoch,
            .request_id = self.next_request, .base_revision = self.state.revision, .action = 4, .layout = self.state.layout }, .color = selection };
        self.next_request += 1; self.pending = request_value.base; self.pending_color = selection;
        if (!self.call(sys, a.display_control_op_color_request, &request_value)) return false;
        if (self.state.result != 0) { self.pending = null; self.pending_color = null; return false; }
        return true;
    }
    pub fn retry(self: *Client, sys: *const r4os.r4sys.Context) bool {
        const pending = self.pending orelse return self.poll(sys);
        const success = if (self.pending_color) |color|
            self.call(sys, a.display_control_op_color_request, &a.DisplayColorRequest{ .base = pending, .color = color })
            else self.call(sys, a.display_control_op_request, &pending);
        if (!success) return false;
        if (self.state.result != 0) { self.pending = null; self.pending_color = null; }
        return self.state.result == 0;
    }
    pub fn close(self: *Client, sys: *const r4os.r4sys.Context) void {
        // If apply is still in flight, its Desktop deadline remains the
        // authoritative cancellation path. Close never waits for a monitor.
        if (self.pending == null and active(self.state.phase) and std.meta.eql(self.state.owner, self.owner)) _ = self.request(sys, 3, null);
    }
};
