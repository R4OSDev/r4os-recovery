//! Explicit read-only WINSVC transport. The original broker owns capability
//! and focus; the editor owner applies copied replies outside these calls.
const std = @import("std");
const a = @import("r4os_contract").abi;
const platform = @import("platform2.zig");
const owner = @import("text_composition.zig");
pub const Client = struct {
    call: a.R4SysFns.service_call,
    close_call: a.R4SysFns.service_close,
    handle: u32,
    timeout_ticks: u64,

    pub fn connect(context: *const platform.Context, timeout: u64, out: *Client) i32 {
        if (timeout == 0) return a.composition_error_invalid;
        const table = context.system();
        const open = platform.abi.function(platform.abi.R4SysFns2, table, "service_open") orelse return a.err_no_fn;
        const call = platform.abi.function(platform.abi.R4SysFns2, table, "service_call") orelse return a.err_no_fn;
        const close_call = platform.abi.function(platform.abi.R4SysFns2, table, "service_close") orelse return a.err_no_fn;
        var info: a.ServiceInfo = .{};
        const rc = open(a.window_service_name, &info);
        if (rc != 0) return rc;
        if (info.handle == 0) return a.composition_error_unsupported;
        out.* = .{ .call = call, .close_call = close_call, .handle = info.handle, .timeout_ticks = timeout };
        return 0;
    }
    pub fn close(self: *Client) i32 {
        if (self.handle == 0) return a.composition_error_invalid;
        const rc = self.close_call(self.handle);
        if (rc >= 0) self.handle = 0;
        return rc;
    }
    fn rpc(self: *const Client, comptime T: type, operation: u16, request: []const u8, out: *T) i32 {
        if (self.handle == 0) return a.composition_error_invalid;
        var header: a.ServiceMessageHeader = .{};
        var value: T = undefined;
        const rc = self.call(self.handle, operation, request.ptr, @intCast(request.len), &header, std.mem.asBytes(&value).ptr, @sizeOf(T), self.timeout_ticks);
        if (rc < 0) return rc;
        if (header.status == a.service_api_result_bad_op) return a.composition_error_unsupported;
        if (header.status != 0) return if (header.status < 0) header.status else a.composition_error_invalid;
        if (rc != @sizeOf(T)) return a.composition_error_invalid;
        out.* = value;
        return 0;
    }
    /// A valid reply can explicitly report NoProvider with features0.
    pub fn capability(self: *const Client, out: *a.CompositionCapabilityReply) i32 {
        var value: a.CompositionCapabilityReply = undefined;
        const rc = self.rpc(a.CompositionCapabilityReply, a.composition_op_capability, "", &value);
        if (rc != 0) return rc;
        const status = owner.providerStatus(value.provider);
        if (value.reserved != 0 or (status != 0 and status != a.composition_error_no_provider) or value.result != status) return a.composition_error_invalid;
        out.* = value;
        return 0;
    }
    pub fn focus(self: *const Client, expected: *const a.WindowModeIdentity, out: *a.CompositionFocusReply) i32 {
        const request = expected.*;
        var value: a.CompositionFocusReply = undefined;
        const rc = self.rpc(a.CompositionFocusReply, a.composition_op_focus, std.mem.asBytes(&request), &value);
        if (rc != 0) return rc;
        if (value.reserved != 0 or (value.result != 0 and value.result != a.composition_error_no_focus and value.result != a.composition_error_stale_view)) return a.composition_error_invalid;
        if (value.result == 0 and (owner.focusStatus(value.focus) != 0 or !std.meta.eql(value.focus.window, request))) return a.composition_error_invalid;
        out.* = value;
        return 0;
    }
};
