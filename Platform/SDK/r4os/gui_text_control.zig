//! Shared control policy over the original clipboard and composition owners.
//! Caller keeps channel/stage/snapshot identities through explicit Commit,
//! Status/Abort and Release/Close acknowledgement. No automatic retry/fallback.
const std = @import("std");
const a = @import("r4os_contract").abi;
const offers = @import("clipboard_offer.zig");
const rpc = @import("rpc_budget.zig");

/// Stages UTF8 item0 only. It never commits, cuts, replaces or loses the token.
pub fn stageText(client: *const offers.Client, stage: *const offers.Lease, text: []const u8) i32 {
    if (client.handle == 0) return a.clipboard_offer_error_closed;
    if (stage.state != a.clipboard_offer_state_writing or stage.provider == 0 or stage.id == 0) return a.clipboard_offer_error_invalid;
    if (!std.unicode.utf8ValidateSlice(text) or std.mem.indexOfScalar(u8, text, 0) != null) return a.clipboard_offer_error_invalid_encoding;
    if (text.len > a.clipboard_offer_max_offer_bytes) return a.clipboard_offer_error_too_large;
    var budget = client.budget() catch |err| return rpc.code(err);
    return stageTextBudget(client, stage, text, &budget);
}

fn stageTextBudget(client: *const offers.Client, stage: *const offers.Lease, text: []const u8, budget: *rpc.Budget) i32 {
    return stageFormatBudget(client, stage, a.clipboard_offer_format_text_utf8, text, budget);
}

fn stageFormatBudget(client: *const offers.Client, stage: *const offers.Lease, format: u32, bytes: []const u8, budget: *rpc.Budget) i32 {
    var view = client.withBudget(budget) catch |err| return rpc.code(err);
    var rc = view.declare(stage.*, 0, format, bytes.len);
    if (rc != 0) return rc;
    var offset: usize = 0;
    while (offset < bytes.len) {
        const end = offset + @min(bytes.len - offset, a.clipboard_offer_put_chunk);
        view = client.withBudget(budget) catch |err| return rpc.code(err);
        rc = view.put(stage.*, 0, format, offset, bytes.len, bytes[offset..end]);
        if (rc != 0) return rc;
        offset = end;
    }
    return 0;
}

/// Reads one exact advertised UTF8 representation completely into scratch.
/// Any failure leaves the control untouched and the snapshot with its caller.
pub fn readText(client: *const offers.Client, snapshot: *const offers.Lease, format: *const offers.Format, scratch: []u8) i32 {
    const valid = validateTextRead(client, snapshot, format, scratch);
    if (valid != 0) return valid;
    var budget = client.budget() catch |err| return rpc.code(err);
    return readTextBudget(client, snapshot, format, scratch, &budget);
}

fn validateTextRead(client: *const offers.Client, snapshot: *const offers.Lease, format: *const offers.Format, scratch: []u8) i32 {
    if (client.handle == 0) return a.clipboard_offer_error_closed;
    if (snapshot.state != a.clipboard_offer_state_snapshot or snapshot.provider == 0 or snapshot.id == 0 or
        format.item >= a.clipboard_offer_max_items or format.format != a.clipboard_offer_format_text_utf8 or format.flags != 0 or format.reserved != 0) return a.clipboard_offer_error_invalid;
    if (format.total_bytes > a.clipboard_offer_max_offer_bytes or format.total_bytes > scratch.len) return a.clipboard_offer_error_too_large;
    return 0;
}

fn readTextBudget(client: *const offers.Client, snapshot: *const offers.Lease, format: *const offers.Format, scratch: []u8, budget: *rpc.Budget) i32 {
    const count = readFormatBudget(client, snapshot, format, scratch, budget);
    if (count < 0) return count;
    const text = scratch[0..@intCast(count)];
    if (!std.unicode.utf8ValidateSlice(text) or std.mem.indexOfScalar(u8, text, 0) != null) return a.clipboard_offer_error_invalid_encoding;
    return count;
}

fn readFormatBudget(client: *const offers.Client, snapshot: *const offers.Lease, format: *const offers.Format, scratch: []u8, budget: *rpc.Budget) i32 {
    var offset: usize = 0;
    const total: usize = @intCast(format.total_bytes);
    // Even empty formats must validate the exact live snapshot at its owner.
    // A zero-byte read still acknowledges provider/id/revision and EOF.
    var first = true;
    while (first or offset < total) {
        first = false;
        const end = offset + @min(total - offset, a.clipboard_offer_read_chunk);
        var chunk: offers.Chunk = undefined;
        const view = client.withBudget(budget) catch |err| return rpc.code(err);
        const rc = view.read(snapshot.*, format.item, format.format, offset, scratch[offset..end], &chunk);
        if (rc != 0) return rc;
        if (chunk.total_bytes != total or (total != 0 and chunk.bytes == 0) or chunk.bytes > end - offset) return a.clipboard_offer_error_invalid;
        offset += chunk.bytes;
    }
    return @intCast(total);
}

/// One editor-owned text channel. Mutations retain their exact stage after an
/// uncertain reply. Read bytes remain scratch until snapshot Release succeeds.
/// Every copy/read shares one outer clock deadline through all its RPCs.
pub const Clipboard = struct {
    client: ?offers.Client = null,
    pending: ?struct { lease: offers.Lease, ready: bool = false } = null,
    snapshot: ?offers.Lease = null,
    receipt: ?offers.Lease = null,

    pub fn connect(self: *Clipboard, system: *const @import("r4sys.zig").Context) i32 {
        if (self.client != null) return 0;
        const context = system.base.generation2 orelse return a.clipboard_offer_error_unsupported;
        var client: offers.Client = undefined;
        const rc = offers.Client.connect(context, &client);
        if (rc == 0) self.client = client;
        return rc;
    }

    fn ended(rc: i32) bool {
        return rc == a.clipboard_offer_error_closed or rc == a.clipboard_offer_error_provider_changed or rc == a.clipboard_offer_error_not_found;
    }

    fn resolve(self: *Clipboard) i32 {
        const released = self.releaseReceipt(null);
        if (released != 0) return released;
        const pending = self.pending orelse return 0;
        const client = &(self.client orelse return a.clipboard_offer_error_closed);
        var budget = client.budget() catch |err| return rpc.code(err);
        var view = client.withBudget(&budget) catch |err| return rpc.code(err);
        var state: offers.Lease = undefined;
        const rc = if (pending.ready) view.status(pending.lease, &state) else view.abort(pending.lease);
        if (ended(rc)) {
            self.pending = null;
            return 0;
        }
        if (rc != 0) return rc;
        if (pending.ready and state.state == a.clipboard_offer_state_writing) {
            view = client.withBudget(&budget) catch |err| return rpc.code(err);
            const aborted = view.abort(pending.lease);
            if (aborted != 0 and !ended(aborted)) return aborted;
        }
        self.pending = null;
        if (pending.ready and state.state == a.clipboard_offer_state_committed) self.receipt = state;
        return self.releaseReceipt(&budget);
    }

    pub fn copy(self: *Clipboard, text: []const u8) i32 {
        if (!std.unicode.utf8ValidateSlice(text) or std.mem.indexOfScalar(u8, text, 0) != null) return a.clipboard_offer_error_invalid_encoding;
        return self.copyFormat(a.clipboard_offer_format_text_utf8, text);
    }

    /// Copies one standard representation. Its format owner validates the
    /// payload before calling and CLIPSVC validates the complete staged offer.
    pub fn copyFormat(self: *Clipboard, format: u32, bytes: []const u8) i32 {
        if (format < a.clipboard_offer_format_text_utf8 or format > a.clipboard_offer_format_text_bytes) return a.clipboard_offer_error_invalid;
        if (bytes.len > a.clipboard_offer_max_offer_bytes) return a.clipboard_offer_error_too_large;
        const resolved = self.resolve();
        if (resolved != 0) return resolved;
        const client = &(self.client orelse return a.clipboard_offer_error_closed);
        var budget = client.budget() catch |err| return rpc.code(err);
        var view = client.withBudget(&budget) catch |err| return rpc.code(err);
        var info: offers.Info = undefined;
        var rc = view.info(&info);
        if (rc != 0) return rc;
        view = client.withBudget(&budget) catch |err| return rpc.code(err);
        var stage: offers.Lease = undefined;
        rc = view.begin(info, bytes.len, &stage);
        if (rc != 0) return rc;
        self.pending = .{ .lease = stage };
        rc = stageFormatBudget(client, &stage, format, bytes, &budget);
        if (rc != 0) return rc;
        self.pending.?.ready = true;
        view = client.withBudget(&budget) catch |err| return rpc.code(err);
        var committed: offers.Lease = undefined;
        rc = view.commit(stage, &committed);
        if (rc == 0) {
            self.pending = null;
            self.receipt = committed;
            // Commit already acknowledged publication. A failed Release keeps
            // the exact receipt for the next mutation or explicit close.
            _ = self.releaseReceipt(&budget);
        }
        return rc;
    }

    fn releaseReceipt(self: *Clipboard, budget: ?*rpc.Budget) i32 {
        const receipt = self.receipt orelse return 0;
        const client = &(self.client orelse return a.clipboard_offer_error_closed);
        const view = if (budget) |limit| client.withBudget(limit) catch |err| return rpc.code(err) else client.*;
        const rc = view.release(receipt);
        if (rc == 0 or ended(rc)) self.receipt = null;
        return if (ended(rc)) 0 else rc;
    }

    fn release(self: *Clipboard, budget: ?*rpc.Budget) i32 {
        const snapshot = self.snapshot orelse return 0;
        const client = &(self.client orelse return a.clipboard_offer_error_closed);
        const view = if (budget) |limit| client.withBudget(limit) catch |err| return rpc.code(err) else client.*;
        const rc = view.release(snapshot);
        if (rc == 0 or ended(rc)) self.snapshot = null;
        return if (ended(rc)) 0 else rc;
    }

    pub fn read(self: *Clipboard, scratch: []u8) i32 {
        const count = self.readFormat(a.clipboard_offer_format_text_utf8, scratch);
        if (count < 0) return count;
        const text = scratch[0..@intCast(count)];
        if (!std.unicode.utf8ValidateSlice(text) or std.mem.indexOfScalar(u8, text, 0) != null) return a.clipboard_offer_error_invalid_encoding;
        return count;
    }

    /// Returns an exact representation only after its snapshot Release ACK.
    /// Scratch belongs to the caller and remains unpublished on any error.
    pub fn readFormat(self: *Clipboard, format: u32, scratch: []u8) i32 {
        if (format < a.clipboard_offer_format_text_utf8 or format > a.clipboard_offer_format_text_bytes) return a.clipboard_offer_error_invalid;
        const released = self.release(null);
        if (released != 0) return released;
        const client = &(self.client orelse return a.clipboard_offer_error_closed);
        var budget = client.budget() catch |err| return rpc.code(err);
        var view = client.withBudget(&budget) catch |err| return rpc.code(err);
        var snapshot: offers.Lease = undefined;
        const rc = view.snapshot(&snapshot);
        if (rc != 0) return rc;
        self.snapshot = snapshot;
        const count = self.readSnapshot(format, scratch, snapshot, &budget);
        const closed = self.release(&budget);
        return if (closed != 0) closed else count;
    }

    fn readSnapshot(self: *Clipboard, wanted: u32, scratch: []u8, snapshot: offers.Lease, budget: *rpc.Budget) i32 {
        const client = &(self.client orelse return a.clipboard_offer_error_closed);
        var cursor: u32 = 0;
        var chosen: ?offers.Format = null;
        while (true) {
            var formats: [8]offers.Format = undefined;
            var page: offers.Page = undefined;
            const view = client.withBudget(budget) catch |err| return rpc.code(err);
            const rc = view.enumerate(snapshot, cursor, &formats, &page);
            if (rc != 0) return rc;
            for (formats[0..page.count]) |format| {
                if (format.format == wanted and (chosen == null or format.item < chosen.?.item)) chosen = format;
            }
            if (page.next == page.total) break;
            if (page.next <= cursor) return a.clipboard_offer_error_invalid;
            cursor = page.next;
        }
        const format = chosen orelse return a.clipboard_offer_error_not_found;
        if (format.total_bytes > a.clipboard_offer_max_offer_bytes or format.total_bytes > scratch.len) return a.clipboard_offer_error_too_large;
        return readFormatBudget(client, &snapshot, &format, scratch, budget);
    }

    pub fn close(self: *Clipboard) i32 {
        const resolved = self.resolve();
        if (resolved != 0) return resolved;
        const released = self.release(null);
        if (released != 0) return released;
        if (self.client) |*client| {
            const rc = client.close();
            if (rc >= 0) self.client = null;
            return rc;
        }
        return 0;
    }
};
test "cli owner editor clipboard retains uncertain stages and blocks replacement" {
    const Peer = struct {
        var allow_status = false;
        var status_state: u32 = a.clipboard_offer_state_committed;
        var status_calls: usize = 0;
        var abort_calls: usize = 0;
        var other_calls: usize = 0;
        var release_calls: usize = 0;
        var release_fail = false;
        fn clock(output: *a.MonotonicClockInfo) callconv(.c) i32 {
            output.* = .{ .flags = a.monotonic_clock_flag_valid, .source = 1, .generation = 1, .resolution_ns = 1, .event_requested_hz = 1000 };
            return 1;
        }
        fn close(_: u32) callconv(.c) i32 {
            return 0;
        }
        fn call(_: u32, op: u16, input: [*]const u8, size: u32, header: *a.ServiceMessageHeader, output: [*]u8, capacity: u32, _: u64) callconv(.c) i32 {
            header.* = .{};
            if (op == a.clipboard_offer_op_status) {
                status_calls += 1;
                if (size != @sizeOf(offers.Lease)) return a.clipboard_offer_error_invalid;
                const token = std.mem.bytesToValue(offers.Lease, input[0..@sizeOf(offers.Lease)]);
                if (token.provider != 42 or token.id != 99) return a.clipboard_offer_error_invalid;
                if (!allow_status) return a.service_api_result_timeout;
                const lease = offers.Lease{ .provider = 42, .id = 99, .revision = 7, .expires_ns = 9_000_000_000, .state = status_state };
                if (capacity < @sizeOf(offers.Lease)) return a.clipboard_offer_error_invalid;
                @memcpy(output[0..@sizeOf(offers.Lease)], std.mem.asBytes(&lease));
                return @sizeOf(offers.Lease);
            }
            if (op == a.clipboard_offer_op_abort) {
                abort_calls += 1;
                return 0;
            }
            if (op == a.clipboard_offer_op_release) {
                release_calls += 1;
                const token = std.mem.bytesToValue(offers.Lease, input[0..@sizeOf(offers.Lease)]);
                if (token.provider != 42 or token.id != 99) return a.clipboard_offer_error_invalid;
                return if (release_fail) a.service_api_result_timeout else 0;
            }
            other_calls += 1;
            header.status = a.service_api_result_bad_op;
            return 0;
        }
    };
    Peer.allow_status = false;
    Peer.status_calls = 0;
    Peer.other_calls = 0;
    Peer.release_calls = 0;
    Peer.release_fail = false;
    const stage = offers.Lease{ .provider = 42, .id = 99, .expires_ns = 9_000_000_000, .state = a.clipboard_offer_state_writing };
    var owner = Clipboard{
        .client = .{ .call = Peer.call, .close_call = Peer.close, .handle = 1, .clock = Peer.clock },
        .pending = .{ .lease = stage, .ready = true },
    };
    try std.testing.expectEqual(a.service_api_result_timeout, owner.copy("replacement"));
    try std.testing.expectEqualDeep(stage, owner.pending.?.lease);
    try std.testing.expectEqual(@as(usize, 1), Peer.status_calls);
    try std.testing.expectEqual(@as(usize, 0), Peer.other_calls);
    Peer.allow_status = true;
    try std.testing.expectEqual(a.clipboard_offer_error_unsupported, owner.copy("replacement"));
    try std.testing.expect(owner.pending == null);
    try std.testing.expectEqual(@as(usize, 2), Peer.status_calls);
    try std.testing.expectEqual(@as(usize, 1), Peer.other_calls);
    Peer.status_state = a.clipboard_offer_state_writing;
    owner.pending = .{ .lease = stage, .ready = true };
    try std.testing.expectEqual(a.clipboard_offer_error_unsupported, owner.copy("replacement"));
    try std.testing.expect(owner.pending == null);
    try std.testing.expectEqual(@as(usize, 1), Peer.abort_calls);
    try std.testing.expectEqual(@as(usize, 2), Peer.other_calls);
    owner.receipt = .{ .provider = 42, .id = 99, .state = a.clipboard_offer_state_committed };
    Peer.release_fail = true;
    try std.testing.expectEqual(a.service_api_result_timeout, owner.copyFormat(a.clipboard_offer_format_xrgb32, "blocked"));
    try std.testing.expectEqual(@as(u64, 99), owner.receipt.?.id);
    try std.testing.expectEqual(@as(usize, 2), Peer.other_calls);
    Peer.release_fail = false;
    try std.testing.expectEqual(@as(i32, 0), owner.close());
    try std.testing.expect(owner.receipt == null and owner.client == null);
    try std.testing.expectEqual(@as(usize, 3), Peer.release_calls);
}
