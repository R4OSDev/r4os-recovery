//! One client per hosted window. Fullscreen means borderless composition on
//! the current output, never a monitor mode switch. Geometry arrives through
//! the ordinary GUI resize/info path. Keep polling until phase == completed.
const std = @import("std");
const a = @import("r4os_contract").abi;
const system = @import("r4sys.zig");
pub const Mode = enum(u32) { windowed = 0, fullscreen = 1 };
pub const Client = struct {
    owner: a.ProgramProcessHandle,
    window_id: u32,
    state: a.WindowModeReply = .{},
    pending: ?a.WindowModeRequest = null,
    next_request: u64 = 1,
    last_error: i32 = 0,

    pub fn poll(self: *Client, sys: *const system.Context) bool {
        const request: a.WindowModeRequest = .{ .identity = .{ .owner = self.owner, .window_id = self.window_id } };
        return self.call(sys, a.window_mode_op_query, &request);
    }
    /// True means accepted, not necessarily applied. A transport failure
    /// retains the immutable request; retry() must reuse that request ID.
    pub fn set(self: *Client, sys: *const system.Context, mode: Mode) bool {
        if (self.pending != null) { self.last_error = -2; return false; }
        if (!self.bound(self.state.identity) or self.next_request == std.math.maxInt(u64)) { self.last_error = -3; return false; }
        self.pending = .{ .identity = self.state.identity, .request_id = self.next_request, .action = 1, .mode = @intFromEnum(mode) };
        self.next_request += 1;
        return self.retry(sys);
    }
    pub fn retry(self: *Client, sys: *const system.Context) bool {
        const request = self.pending orelse { self.last_error = -1; return false; };
        return self.call(sys, a.window_mode_op_request, &request) and self.last_error == 0;
    }
    fn bound(self: *const Client, id: a.WindowModeIdentity) bool {
        return validIdentity(id) and std.meta.eql(id.owner, self.owner) and id.window_id == self.window_id;
    }
    fn call(self: *Client, sys: *const system.Context, op: u16, request: *const a.WindowModeRequest) bool {
        var endpoint: a.ServiceInfo = .{};
        const opened = sys.serviceOpen(a.window_service_name, &endpoint);
        if (opened != 0 or endpoint.handle == 0) { self.last_error = if (opened != 0) opened else -3; return false; }
        defer _ = sys.serviceClose(endpoint.handle);
        var header: a.ServiceMessageHeader = .{};
        var reply: a.WindowModeReply = .{};
        const rc = sys.serviceCall(endpoint.handle, op, std.mem.asBytes(request), &header, std.mem.asBytes(&reply), sys.ticksFromMilliseconds(250));
        if (rc < 0) { self.last_error = rc; return false; }
        if (header.status != 0) { self.last_error = header.status; return false; }
        if (rc != @sizeOf(a.WindowModeReply) or !validReply(&reply)) { self.last_error = -1; return false; }
        self.last_error = reply.result;
        if (reply.identity.serial == 0) {
            self.state = reply;
            if (op == a.window_mode_op_request) self.pending = null;
            return reply.result != 0;
        }
        if (!self.bound(reply.identity)) { self.last_error = -1; return false; }
        self.state = reply;
        self.next_request = @max(self.next_request, reply.request_id +| 1);
        if (self.pending) |pending| {
            if (!std.meta.eql(pending.identity, reply.identity)) {
                // A restarted service/Desktop/window never receives an old request.
                self.pending = null; self.last_error = -4;
            } else if (reply.request_id == pending.request_id and reply.phase == 2) {
                self.pending = null;
            } else if (op == a.window_mode_op_request and reply.result != 0) {
                self.pending = null;
            }
        }
        return true;
    }
};
pub fn validIdentity(id: a.WindowModeIdentity) bool {
    return id.serial != 0 and id.reserved == 0 and validOwner(id.owner) and validOwner(id.desktop) and validOwner(id.service);
}
fn validOwner(owner: a.ProgramProcessHandle) bool {
    return owner.instance_id != 0 and owner.generation != 0 and owner.reserved == 0;
}
pub fn validReply(reply: *const a.WindowModeReply) bool {
    return reply.version == 1 and reply.size == @sizeOf(a.WindowModeReply) and reply.result <= 0 and reply.result >= -5 and
        reply.phase <= 2 and reply.mode <= 1 and reply.requested_mode <= 1 and
        (if (reply.identity.serial == 0) reply.result != 0 else validIdentity(reply.identity)) and
        (if (reply.phase == 0) reply.request_id == 0 else reply.request_id != 0);
}
