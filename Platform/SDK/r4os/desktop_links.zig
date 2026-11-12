//! Save the Prepare reply's complete request before Activate. On any lost
//! Activate response, use Status with that original request; never a new intent.
const std = @import("std");
const a = @import("r4os_contract").abi;
const system = @import("r4sys.zig");
pub const Token = a.DesktopLinkToken;
pub const Request = a.DesktopLinkRequest;
pub const Reply = a.DesktopLinkReply;
pub const Call = union(enum) { reply: Reply, failure: i32 };
pub fn supported(reply: *const Reply) bool {
    return reply.result == 0 and reply.flags & a.desktop_link_capabilities == a.desktop_link_capabilities;
}
pub fn binding(scope: Token, owner: a.ProgramProcessHandle, intent: [3]u64, deadline: u64, path: []const u8, bytes: []const u8) ?Request {
    if (scope.version != 1 or scope.size != @sizeOf(Token) or scope.service.instance_id == 0 or scope.service.generation == 0 or scope.epoch[0] | scope.epoch[1] | scope.epoch[2] == 0 or owner.instance_id == 0 or owner.generation == 0 or owner.reserved != 0 or intent[0] | intent[1] | intent[2] == 0 or path.len == 0 or path.len >= 160 or bytes.len == 0 or bytes.len > a.desktop_link_max_bytes or std.mem.indexOfScalar(u8, path, 0) != null or std.mem.indexOfScalar(u8, bytes, 0) != null) return null;
    var q: Request = .{ .token = .{ .service = scope.service, .owner = owner, .epoch = scope.epoch, .intent = intent }, .deadline = deadline, .link_length = @intCast(bytes.len) };
    @memcpy(q.link_path[0..path.len], path);
    @memcpy(q.link_bytes[0..bytes.len], bytes);
    return q;
}
pub const Client = struct {
    sys: system.Context,
    pub fn scope(self: *const Client) Call {
        return self.call(a.desktop_link_op_scope, .{});
    }
    pub fn prepare(self: *const Client, request: Request) Call {
        return self.call(a.desktop_link_op_prepare, request);
    }
    pub fn activate(self: *const Client, saved: Request) Call {
        return self.call(a.desktop_link_op_activate, saved);
    }
    pub fn status(self: *const Client, saved: Request) Call {
        return self.call(a.desktop_link_op_status, saved);
    }
    pub fn release(self: *const Client, saved: Request) Call {
        return self.call(a.desktop_link_op_release, saved);
    }
    fn call(self: *const Client, op: u16, q: Request) Call {
        var info: a.ServiceInfo = .{};
        const opened = self.sys.serviceOpen(a.window_service_name, &info);
        if (opened != 0 or info.handle == 0) return .{ .failure = if (opened != 0) opened else a.service_api_result_no_endpoint };
        defer _ = self.sys.serviceClose(info.handle);
        var out: Reply = .{};
        var header: a.ServiceMessageHeader = .{};
        const count = self.sys.serviceCall(info.handle, op, std.mem.asBytes(&q), &header, std.mem.asBytes(&out), self.sys.ticksFromMilliseconds(500));
        if (count < 0) return .{ .failure = count };
        if (header.status != 0) return .{ .failure = header.status };
        if (count != @sizeOf(Reply) or out.request.token.version != 1 or out.request.token.size != @sizeOf(Token) or out.request.link_length > a.desktop_link_max_bytes or out.phase > a.desktop_link_phase_expired or out.result > 0 or out.result < a.desktop_link_result_unavailable) return .{ .failure = a.desktop_link_result_invalid };
        if (op != a.desktop_link_op_scope) {
            var expected = q;
            expected.token.serial = out.request.token.serial;
            if ((q.token.serial != 0 and q.token.serial != out.request.token.serial) or !std.meta.eql(expected, out.request)) return .{ .failure = a.desktop_link_result_invalid };
        }
        return .{ .reply = out };
    }
};
