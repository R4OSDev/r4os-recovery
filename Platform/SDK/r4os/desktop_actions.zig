//! Explicit own-launch delegation. Persist a command ID and its exact request
//! before submitting. Unknown transport/receipt never authorizes a new action.
const std = @import("std");
const a = @import("r4os_contract").abi;
const system = @import("r4sys.zig");
pub const Token = a.DesktopActionToken;
pub const Request = a.DesktopActionRequest;
pub const Reply = a.DesktopActionReply;
pub const State = a.DesktopActionState;
pub const Call = union(enum) { reply: Reply, failure: i32 };
pub const FocusCall = union(enum) { reply: a.DesktopFocusReply, failure: i32 };
fn same(x: a.ProgramProcessHandle, y: a.ProgramProcessHandle) bool {
    return std.meta.eql(x, y);
}
fn valid(h: a.ProgramProcessHandle) bool {
    return h.instance_id != 0 and h.generation != 0 and h.reserved == 0;
}
fn scoped(t: Token) bool {
    return t.version == 1 and t.size == @sizeOf(Token) and valid(t.window.service) and t.epoch[0] | t.epoch[1] | t.epoch[2] != 0;
}
pub fn prepare(scope: Token, requester: a.ProgramProcessHandle, controller: a.ProgramProcessHandle, rights: u32) ?Token {
    if (!scoped(scope) or !valid(requester) or !valid(controller) or rights == 0 or
        (rights != a.desktop_action_right_pointer and rights & ~@as(u32, 7) != 0)) return null;
    return .{ .window = .{ .service = scope.window.service }, .request = requester, .controller = controller, .epoch = scope.epoch, .rights = rights };
}
pub fn frameReady(reply: *const Reply) bool {
    return reply.phase == a.desktop_action_phase_applied and reply.result == 0 and reply.applied.view_revision != 0 and
        reply.current.view_revision == reply.applied.view_revision and std.meta.eql(reply.current.window, reply.applied.window) and
        reply.current.proof_flags & a.desktop_action_proof_composed != 0 and reply.current.composition_serial != 0 and
        (reply.current.proof_flags & a.desktop_action_proof_invisible != 0 or reply.current.proof_flags & a.desktop_action_proof_app_fresh != 0);
}
pub const Client = struct {
    sys: system.Context,
    pub fn scope(self: *const Client) Call {
        return self.call(a.desktop_action_op_scope, .{}, 500);
    }
    pub fn grant(self: *const Client, token: Token) Call {
        return self.call(a.desktop_action_op_grant, .{ .token = token }, 500);
    }
    pub fn command(self: *const Client, request: Request) Call {
        return self.call(a.desktop_action_op_command, request, 500);
    }
    /// One immutable pointer step; the service limits grant, location and
    /// count. Repeat the same operation ID only to retrieve its receipt.
    pub fn pointerStep(self: *const Client, token: Token, operation: u64, deadline: u64, kind: u32, x: i32, y: i32) Call {
        if (token.rights != a.desktop_action_right_pointer or
            kind != a.desktop_action_kind_pointer_down and kind != a.desktop_action_kind_pointer_move and kind != a.desktop_action_kind_pointer_up)
            return .{ .failure = a.desktop_action_result_invalid };
        return self.command(.{ .token = token, .operation = operation, .deadline = deadline, .kind = kind, .x = x, .y = y });
    }
    pub fn status(self: *const Client, token: Token, operation: u64) Call {
        return self.call(a.desktop_action_op_status, .{ .token = token, .operation = operation }, 500);
    }
    pub fn release(self: *const Client, token: Token) Call {
        return self.call(a.desktop_action_op_release, .{ .token = token }, 500);
    }
    /// Actual caller may only query its own window. No action grant is created.
    pub fn appView(self: *const Client, window_id: i32) Call {
        if (window_id < 0) return .{ .failure = a.desktop_action_result_invalid };
        return self.call(a.desktop_action_op_app_view, .{ .token = .{ .window = .{ .window_id = @intCast(window_id) } } }, 20);
    }
    /// Read-only observation of the calling application's own window.
    /// An expected serial detects reuse of a formerly observed incarnation.
    pub fn focusSnapshot(self: *const Client, expected: a.WindowModeIdentity) FocusCall {
        var endpoint: a.ServiceInfo = .{};
        const opened = self.sys.serviceOpen(a.window_service_name, &endpoint);
        if (opened != 0 or endpoint.handle == 0) return .{ .failure = if (opened != 0) opened else a.service_api_result_no_endpoint };
        defer _ = self.sys.serviceClose(endpoint.handle);
        var bytes: [@sizeOf(a.DesktopFocusReply)]u8 = undefined;
        var header: a.ServiceMessageHeader = .{};
        const count = self.sys.serviceCall(endpoint.handle, a.desktop_action_op_focus_snapshot, std.mem.asBytes(&expected), &header, &bytes, self.sys.ticksFromMilliseconds(20));
        if (count < 0) return .{ .failure = count };
        if (header.status != 0) return .{ .failure = header.status };
        if (count != @sizeOf(a.DesktopFocusReply)) return .{ .failure = a.desktop_focus_result_stale };
        var reply: a.DesktopFocusReply = .{};
        @memcpy(std.mem.asBytes(&reply), &bytes);
        if (reply.result > 0 or reply.result < a.desktop_focus_result_unknown or reply.reserved != 0 or
            (reply.result == 0 and (reply.snapshot.version != 1 or reply.snapshot.size != @sizeOf(a.DesktopFocusSnapshot) or
                reply.snapshot.window.window_id != expected.window_id or reply.snapshot.input_revision == 0)))
            return .{ .failure = a.desktop_focus_result_stale };
        return .{ .reply = reply };
    }
    /// Best-effort paint proof only for an explicitly tagged delegated view
    /// transition. Never called for ordinary FPS frames or user drag polling.
    pub fn appFrame(self: *const Client, token: Token, revision: u64, generation: u64, width: i32, height: i32) Call {
        return self.call(a.desktop_action_op_app_frame, .{ .token = token, .operation = revision, .width = width, .height = height, .frame_generation = generation }, 20);
    }
    fn call(self: *const Client, op: u16, request: Request, timeout_ms: u32) Call {
        var endpoint: a.ServiceInfo = .{};
        const opened = self.sys.serviceOpen(a.window_service_name, &endpoint);
        if (opened != 0 or endpoint.handle == 0) return .{ .failure = if (opened != 0) opened else a.service_api_result_no_endpoint };
        defer _ = self.sys.serviceClose(endpoint.handle);
        var bytes: [@sizeOf(Reply)]u8 = undefined;
        var header: a.ServiceMessageHeader = .{};
        const count = self.sys.serviceCall(endpoint.handle, op, std.mem.asBytes(&request), &header, &bytes, self.sys.ticksFromMilliseconds(timeout_ms));
        if (count < 0) return .{ .failure = count };
        if (header.status != 0) return .{ .failure = header.status };
        if (count != @sizeOf(Reply)) return .{ .failure = a.desktop_action_result_invalid };
        var reply: Reply = .{};
        @memcpy(std.mem.asBytes(&reply), &bytes);
        if (reply.result > 0 or reply.result < a.desktop_action_result_released or reply.phase > a.desktop_action_phase_unknown or
            reply.request.token.version != 1 or reply.request.token.size != @sizeOf(Token) or
            reply.applied.version != 1 or reply.applied.size != @sizeOf(State) or reply.current.version != 1 or reply.current.size != @sizeOf(State))
            return .{ .failure = a.desktop_action_result_invalid };
        const token = reply.request.token;
        if (op != a.desktop_action_op_scope and op != a.desktop_action_op_app_view and
            (!same(token.window.service, request.token.window.service) or !same(token.request, request.token.request) or
                !same(token.controller, request.token.controller) or token.rights != request.token.rights or !std.meta.eql(token.epoch, request.token.epoch) or
                (request.token.grant != 0 and token.grant != request.token.grant) or
                (request.token.window.serial != 0 and !std.meta.eql(token.window, request.token.window))))
            return .{ .failure = a.desktop_action_result_invalid };
        if (op == a.desktop_action_op_app_view and reply.result == 0 and token.window.window_id != request.token.window.window_id)
            return .{ .failure = a.desktop_action_result_invalid };
        return .{ .reply = reply };
    }
};
