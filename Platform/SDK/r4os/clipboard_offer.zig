//! Copied typed offers over the actual CLIPSVC endpoint. No implicit fallback.
const std = @import("std");
pub const abi = @import("r4os_contract").abi;
const platform = @import("platform2.zig");
pub const Info = abi.ClipboardOfferInfo;
pub const Lease = abi.ClipboardOfferLease;
pub const Format = abi.ClipboardOfferFormat;
pub const Transfer = abi.ClipboardOfferTransfer;
pub const Page = abi.ClipboardOfferPage;
pub const Chunk = abi.ClipboardOfferChunk;
pub fn token(lease: Lease) Lease {
    return .{ .provider = lease.provider, .id = lease.id };
}
pub fn transfer(lease: Lease, item: u32, format: u32, offset: u64, total: u64) Transfer {
    return .{ .provider = lease.provider, .id = lease.id, .item = item, .format = format, .offset = offset, .total_bytes = total };
}
/// One caller-owned synchronous channel. No concurrent use or automatic retry.
/// Context/tables/code remain live through all calls and successful Close.
/// A transport error can leave a mutation outcome unknown; retain the stage
/// token and use Status/idempotent Commit, never publish a replacement blindly.
// Shared with the existing C/Rust R4SdkClipboardOffers record. Auto layout
// reorders handle/timeout and cannot cross the normal control FFI boundary.
pub const Client = extern struct {
    call: abi.R4SysFns.service_call,
    close_call: abi.R4SysFns.service_close,
    handle: u32,
    timeout_ticks: u64 = 500,
    clock: @import("rpc_budget.zig").Clock = null,

    pub fn budget(self: *const Client) @import("rpc_budget.zig").Error!@import("rpc_budget.zig").Budget {
        return @import("rpc_budget.zig").Budget.fromTicks(self.clock, self.timeout_ticks);
    }
    /// A synchronous borrowed call view, not a duplicated channel owner.
    pub fn withBudget(self: *const Client, remaining: *@import("rpc_budget.zig").Budget) @import("rpc_budget.zig").Error!Client {
        var view = self.*;
        view.timeout_ticks = try remaining.remainingTicks();
        return view;
    }

    pub fn connect(context: *const platform.Context, out: *Client) i32 {
        const table = context.system();
        const open = platform.abi.function(platform.abi.R4SysFns2, table, "service_open") orelse return abi.err_no_fn;
        const call = platform.abi.function(platform.abi.R4SysFns2, table, "service_call") orelse return abi.err_no_fn;
        const close_call = platform.abi.function(platform.abi.R4SysFns2, table, "service_close") orelse return abi.err_no_fn;
        var endpoint: abi.ServiceInfo = .{};
        const rc = open("CLIPSVC", &endpoint);
        if (rc != 0) return rc;
        if (endpoint.handle == 0) return abi.service_api_result_no_endpoint;
        out.* = .{ .call = call, .close_call = close_call, .handle = endpoint.handle, .clock = platform.abi.function(platform.abi.R4SysFns2, table, "monotonic_clock") };
        return 0;
    }
    pub fn close(self: *Client) i32 {
        if (self.handle == 0) return abi.clipboard_offer_error_closed;
        const rc = self.close_call(self.handle);
        if (rc >= 0) self.handle = 0;
        return rc;
    }
    fn rpc(self: *const Client, op: u16, request: []const u8, response: []u8) i32 {
        if (self.handle == 0) return abi.clipboard_offer_error_closed;
        var header: abi.ServiceMessageHeader = .{};
        const rc = self.call(self.handle, op, request.ptr, @intCast(request.len), &header, response.ptr, @intCast(response.len), self.timeout_ticks);
        if (rc < 0) return rc;
        if (header.status == abi.service_api_result_bad_op) return abi.clipboard_offer_error_unsupported;
        if (header.status != 0) return if (header.status < 0) header.status else abi.clipboard_offer_error_invalid;
        return rc;
    }
    fn fixed(self: *const Client, comptime T: type, op: u16, request: []const u8, out: *T) i32 {
        var value: T = undefined;
        const rc = self.rpc(op, request, std.mem.asBytes(&value));
        if (rc < 0) return rc;
        if (rc != @sizeOf(T) or value.version != 1 or value.size != @sizeOf(T)) return abi.clipboard_offer_error_invalid;
        out.* = value;
        return 0;
    }
    fn empty(self: *const Client, op: u16, request: []const u8) i32 {
        var response: [1]u8 = undefined;
        const rc = self.rpc(op, request, &response);
        return if (rc <= 0) rc else abi.clipboard_offer_error_invalid;
    }
    pub fn info(self: *const Client, out: *Info) i32 {
        var value: Info = undefined;
        const rc = self.fixed(Info, abi.clipboard_offer_op_info, "", &value);
        if (rc != 0) return rc;
        if (value.provider == 0 or value.flags != 0 or value.put_chunk == 0 or value.put_chunk > abi.clipboard_offer_put_chunk or value.read_chunk == 0 or value.read_chunk > abi.clipboard_offer_read_chunk) return abi.clipboard_offer_error_invalid;
        out.* = value;
        return 0;
    }
    pub fn begin(self: *const Client, current: Info, total: u64, out: *Lease) i32 {
        const request: abi.ClipboardOfferBegin = .{ .provider = current.provider, .expected_revision = current.revision, .total_bytes = total };
        var value: Lease = undefined;
        const rc = self.fixed(Lease, abi.clipboard_offer_op_begin, std.mem.asBytes(&request), &value);
        if (rc != 0) return rc;
        if (!validLease(value, current.provider, abi.clipboard_offer_state_writing) or value.revision != current.revision) return abi.clipboard_offer_error_invalid;
        out.* = value;
        return 0;
    }
    pub fn declare(self: *const Client, stage: Lease, item: u32, format: u32, total: u64) i32 {
        const request = transfer(stage, item, format, 0, total);
        return self.empty(abi.clipboard_offer_op_declare, std.mem.asBytes(&request));
    }
    pub fn put(self: *const Client, stage: Lease, item: u32, format: u32, offset: u64, total: u64, bytes: []const u8) i32 {
        if (bytes.len > abi.clipboard_offer_put_chunk) return abi.clipboard_offer_error_too_large;
        const request = transfer(stage, item, format, offset, total);
        var payload: [4096]u8 = undefined;
        @memcpy(payload[0..@sizeOf(Transfer)], std.mem.asBytes(&request));
        @memcpy(payload[@sizeOf(Transfer)..][0..bytes.len], bytes);
        return self.empty(abi.clipboard_offer_op_put, payload[0 .. @sizeOf(Transfer) + bytes.len]);
    }
    fn leaseCall(self: *const Client, op: u16, lease: Lease, out: *Lease) i32 {
        const request = token(lease);
        var value: Lease = undefined;
        const rc = self.fixed(Lease, op, std.mem.asBytes(&request), &value);
        if (rc != 0) return rc;
        if (!validLease(value, lease.provider, 0) or value.id != lease.id or value.state != abi.clipboard_offer_state_writing and value.state != abi.clipboard_offer_state_committed) return abi.clipboard_offer_error_invalid;
        if (op == abi.clipboard_offer_op_commit and value.state != abi.clipboard_offer_state_committed) return abi.clipboard_offer_error_invalid;
        out.* = value;
        return 0;
    }
    pub fn commit(self: *const Client, stage: Lease, out: *Lease) i32 {
        return self.leaseCall(abi.clipboard_offer_op_commit, stage, out);
    }
    pub fn status(self: *const Client, stage: Lease, out: *Lease) i32 {
        return self.leaseCall(abi.clipboard_offer_op_status, stage, out);
    }
    pub fn abort(self: *const Client, stage: Lease) i32 {
        const request = token(stage);
        return self.empty(abi.clipboard_offer_op_abort, std.mem.asBytes(&request));
    }
    pub fn snapshot(self: *const Client, out: *Lease) i32 {
        var value: Lease = undefined;
        const rc = self.fixed(Lease, abi.clipboard_offer_op_snapshot, "", &value);
        if (rc != 0) return rc;
        if (!validLease(value, value.provider, abi.clipboard_offer_state_snapshot)) return abi.clipboard_offer_error_invalid;
        out.* = value;
        return 0;
    }
    pub fn release(self: *const Client, lease: Lease) i32 {
        const request = token(lease);
        return self.empty(abi.clipboard_offer_op_release, std.mem.asBytes(&request));
    }
    pub fn enumerate(self: *const Client, lease: Lease, cursor: u32, formats: []Format, out: *Page) i32 {
        if (formats.len == 0 or formats.len > abi.clipboard_offer_max_formats) return abi.clipboard_offer_error_invalid;
        const request: abi.ClipboardOfferEnumerate = .{ .provider = lease.provider, .id = lease.id, .cursor = cursor, .capacity = @intCast(formats.len) };
        var payload: [4096]u8 = undefined;
        const rc = self.rpc(abi.clipboard_offer_op_enumerate, std.mem.asBytes(&request), &payload);
        if (rc < 0) return rc;
        if (rc < @sizeOf(Page)) return abi.clipboard_offer_error_invalid;
        const page = std.mem.bytesToValue(Page, payload[0..@sizeOf(Page)]);
        if (page.version != 1 or page.size != @sizeOf(Page) or page.provider != lease.provider or page.id != lease.id or page.revision != lease.revision or page.reserved != 0 or page.count > formats.len or page.total > abi.clipboard_offer_max_formats or cursor > page.total or page.count > page.total - cursor or page.next != cursor + page.count or rc != @sizeOf(Page) + page.count * @sizeOf(Format)) return abi.clipboard_offer_error_invalid;
        for (0..page.count) |i| {
            const start = @sizeOf(Page) + i * @sizeOf(Format);
            const record = std.mem.bytesToValue(Format, payload[start..][0..@sizeOf(Format)]);
            if (record.item >= abi.clipboard_offer_max_items or record.format < 1 or record.format > 5 or record.total_bytes > abi.clipboard_offer_max_offer_bytes or record.flags != 0 or record.reserved != 0) return abi.clipboard_offer_error_invalid;
        }
        @memcpy(std.mem.sliceAsBytes(formats[0..page.count]), payload[@sizeOf(Page)..][0 .. page.count * @sizeOf(Format)]);
        out.* = page;
        return 0;
    }
    pub fn read(self: *const Client, lease: Lease, item: u32, format: u32, offset: u64, bytes: []u8, out: *Chunk) i32 {
        if (bytes.len > abi.clipboard_offer_read_chunk) return abi.clipboard_offer_error_too_large;
        const request = transfer(lease, item, format, offset, bytes.len);
        var payload: [4096]u8 = undefined;
        const rc = self.rpc(abi.clipboard_offer_op_read, std.mem.asBytes(&request), &payload);
        if (rc < 0) return rc;
        if (rc < @sizeOf(Chunk)) return abi.clipboard_offer_error_invalid;
        const chunk = std.mem.bytesToValue(Chunk, payload[0..@sizeOf(Chunk)]);
        if (chunk.version != 1 or chunk.size != @sizeOf(Chunk) or chunk.provider != lease.provider or chunk.id != lease.id or chunk.revision != lease.revision or chunk.offset != offset or chunk.bytes > bytes.len or chunk.total_bytes > abi.clipboard_offer_max_offer_bytes or offset > chunk.total_bytes or chunk.bytes > chunk.total_bytes - offset or chunk.flags > 1 or (chunk.flags == abi.clipboard_offer_flag_eof) != (offset + chunk.bytes == chunk.total_bytes) or rc != @sizeOf(Chunk) + chunk.bytes) return abi.clipboard_offer_error_invalid;
        @memcpy(bytes[0..chunk.bytes], payload[@sizeOf(Chunk)..][0..chunk.bytes]);
        out.* = chunk;
        return 0;
    }
};
fn validLease(value: Lease, provider: u64, state: u32) bool {
    return value.provider == provider and provider != 0 and value.id != 0 and value.expires_ns != 0 and value.reserved == 0 and (state == 0 or value.state == state);
}
