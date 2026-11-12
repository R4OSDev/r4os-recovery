//! Restartable WINSVC evidence handoff. Persist intent before Reserve, the
//! returned serial before Offer, and the canonical token before ACK. Status
//! never creates a missing reservation, reference or application instance.
const std = @import("std");
const a = @import("r4os_contract").abi;
const system = @import("r4sys.zig");

pub const Token = a.DesktopEvidenceToken;
pub const Reply = a.DesktopEvidenceReply;
pub const Call = union(enum) { reply: Reply, failure: i32 };

fn sameProcess(x: a.ProgramProcessHandle, y: a.ProgramProcessHandle) bool {
    return std.meta.eql(x, y);
}
fn validProcess(p: a.ProgramProcessHandle) bool {
    return p.instance_id != 0 and p.generation != 0 and p.reserved == 0;
}
fn nonzero(words: [3]u64) bool {
    return words[0] | words[1] | words[2] != 0;
}

/// This is a logical receiver identity, not a permission credential. Copies
/// alias the same lease. Independent observers must choose different intents.
pub fn prepare(scope: Token, request: a.ProgramProcessHandle, intent: [3]u64) ?Token {
    if (scope.version != 1 or scope.size != @sizeOf(Token) or !validProcess(scope.broker) or
        !nonzero(scope.epoch) or !validProcess(request) or !nonzero(intent)) return null;
    return .{ .broker = scope.broker, .epoch = scope.epoch, .request = request, .intent = intent };
}

pub const Client = struct {
    sys: system.Context,

    pub fn scope(self: *const Client) Call {
        return self.call(a.desktop_evidence_op_scope, .{}, &.{});
    }
    pub fn reserve(self: *const Client, intent: Token) Call {
        if (intent.serial != 0) return .{ .failure = a.desktop_evidence_result_invalid };
        return self.call(a.desktop_evidence_op_reserve, .{ .token = intent }, &.{});
    }
    pub fn offer(self: *const Client, token: Token) Call {
        return self.mutate(a.desktop_evidence_op_offer, token);
    }
    pub fn acknowledge(self: *const Client, token: Token) Call {
        return self.mutate(a.desktop_evidence_op_ack, token);
    }
    pub fn status(self: *const Client, token: Token) Call {
        return self.call(a.desktop_evidence_op_status, .{ .token = token }, &.{});
    }
    pub fn read(self: *const Client, token: Token, offset: u32, out: []u8) Call {
        if (out.len == 0 or out.len > a.desktop_evidence_max_output_chunk) return .{ .failure = a.desktop_evidence_result_invalid };
        return self.call(a.desktop_evidence_op_read, .{ .token = token, .offset = offset, .capacity = @intCast(out.len) }, out);
    }
    pub fn release(self: *const Client, token: Token) Call {
        return self.mutate(a.desktop_evidence_op_release, token);
    }
    fn mutate(self: *const Client, op: u16, token: Token) Call {
        if (token.serial == 0) return .{ .failure = a.desktop_evidence_result_invalid };
        return self.call(op, .{ .token = token }, &.{});
    }
    fn call(self: *const Client, op: u16, request: a.DesktopEvidenceRequest, out: []u8) Call {
        var endpoint: a.ServiceInfo = .{};
        const opened = self.sys.serviceOpen(a.window_service_name, &endpoint);
        if (opened != 0 or endpoint.handle == 0) return .{ .failure = if (opened != 0) opened else a.service_api_result_no_endpoint };
        defer _ = self.sys.serviceClose(endpoint.handle);
        var bytes: [a.service_api_max_payload]u8 = undefined;
        var header: a.ServiceMessageHeader = .{};
        const raw = self.sys.serviceCall(endpoint.handle, op, std.mem.asBytes(&request), &header, &bytes, self.sys.ticksFromMilliseconds(500));
        if (raw < 0) return .{ .failure = raw };
        if (header.status != 0) return .{ .failure = header.status };
        if (raw < @sizeOf(Reply)) return .{ .failure = a.desktop_evidence_result_invalid };
        var reply: Reply = .{};
        @memcpy(std.mem.asBytes(&reply), bytes[0..@sizeOf(Reply)]);
        if (reply.token.version != 1 or reply.token.size != @sizeOf(Token) or reply.phase > a.desktop_evidence_phase_unavailable or
            reply.result > 0 or reply.result < a.desktop_evidence_result_released or reply.data_bytes > out.len or
            @as(usize, @intCast(raw)) != @sizeOf(Reply) + reply.data_bytes) return .{ .failure = a.desktop_evidence_result_invalid };
        if (op != a.desktop_evidence_op_scope) {
            if (!sameProcess(reply.token.broker, request.token.broker) or !sameProcess(reply.token.request, request.token.request) or
                !std.meta.eql(reply.token.epoch, request.token.epoch) or !std.meta.eql(reply.token.intent, request.token.intent) or
                (request.token.serial != 0 and reply.token.serial != request.token.serial) or
                (validProcess(request.token.process) and !sameProcess(reply.token.process, request.token.process)) or
                (validProcess(request.token.desktop) and !sameProcess(reply.token.desktop, request.token.desktop))) return .{ .failure = a.desktop_evidence_result_invalid };
        }
        if (reply.data_bytes != 0) @memcpy(out[0..reply.data_bytes], bytes[@sizeOf(Reply)..][0..reply.data_bytes]);
        return .{ .reply = reply };
    }
};

/// Adopt a saved broker token without Retain/Spawn. Every use is validated by
/// its original broker epoch, including when all numeric IDs repeat at boot.
/// Zig callers close explicitly or export the release responsibility.
pub const Lease = struct {
    client: Client,
    token: Token,
    owned: bool = true,
    pub fn status(self: *const Lease) Call {
        return self.client.status(self.token);
    }
    pub fn read(self: *const Lease, offset: u32, out: []u8) Call {
        return self.client.read(self.token, offset, out);
    }
    pub fn exportToken(self: *Lease) Token {
        self.owned = false;
        return self.token;
    }
    pub fn close(self: *Lease) Call {
        if (!self.owned) return .{ .failure = a.err_not_owned };
        const result = self.client.release(self.token);
        if (result == .reply) {
            const code = result.reply.result;
            if (code == a.desktop_evidence_result_released or code == a.desktop_evidence_result_expired or
                code == a.desktop_evidence_result_unknown or code == a.desktop_evidence_result_stale) self.owned = false;
        }
        return result;
    }
};
