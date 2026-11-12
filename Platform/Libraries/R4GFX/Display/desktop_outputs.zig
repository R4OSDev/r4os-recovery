//! Shared discovery and persistence vocabulary for Desktop and its settings
//! application. Policy, images, workers and confirmation belong to callers.
const std = @import("std");
const a = @import("r4os").abi;
pub const topology = @import("topology.zig");
pub const preferences = @import("preferences.zig");
pub const color_preferences = @import("color_preferences.zig");
pub const brightness_preferences = @import("brightness_preferences.zig");
pub const brightness_client = @import("brightness_client.zig");
pub const brightness_status = @import("brightness_status.zig");
pub const refresh_preferences = @import("refresh_preferences.zig");
pub const refresh_client = @import("refresh_client.zig");
pub const refresh_status = @import("refresh_status.zig");
pub const profiles = @import("display_profile.zig");
pub const color = @import("color_signal.zig");
pub const color_control = @import("color_control.zig");
pub const control = @import("control.zig");
pub const modes = @import("mode_control.zig");
const edid = @import("edid.zig");
pub const Entry = struct {
    info: a.GfxOutputInfo = .{},
    target: a.GfxOutputTarget = .{},
    presentation: a.DisplayPresentationInfo = .{},
    color: ?a.GfxOutputColorState = null,
    key: topology.Key = .{},
    name: [14]u8 = @splat(0),
    pub fn active(self: *const Entry) bool { return self.target.connector_id != 0; }
};
pub const Snapshot = struct {
    entries: [topology.capacity]Entry = @splat(.{}),
    count: usize = 0,
    revision: u64 = 0,
    /// Presentation liveness may change without a connector-catalog revision.
    /// Frame/IRQ counters are deliberately excluded: they are not topology.
    pub fn sameOutputs(self: *const Snapshot, other: *const Snapshot) bool {
        if (self.revision != other.revision or self.count != other.count) return false;
        for (self.entries[0..self.count], other.entries[0..other.count]) |left, right| {
            if (!std.meta.eql(left.key, right.key) or !std.meta.eql(left.target, right.target)) return false;
            const l = left.presentation; const r = right.presentation;
            if (l.flags != r.flags or l.width != r.width or l.height != r.height or l.format != r.format or
                l.policies != r.policies or l.buffer_count != r.buffer_count or l.plane_count != r.plane_count or
                l.interval_ns != r.interval_ns or l.path != r.path) return false;
        }
        return true;
    }
    pub fn read(draw: anytype) !Snapshot {
        var before: a.GfxDisplayRevision = .{};
        const outputs = draw.outputs();
        if (outputs.revision(&before) != a.gfx_output_ok) return error.Unavailable;
        if (before.present > 32 or before.present > before.capacity) return error.Capacity;
        var result: Snapshot = .{ .revision = before.revision };
        for (0..before.present) |i| {
            var value: Entry = .{};
            if (outputs.info(@intCast(i), &value.info) != a.gfx_output_ok or value.info.topology_revision != before.revision) return error.Stale;
            if (value.info.flags & a.gfx_output_flag_connected == 0 or value.info.flags & a.gfx_output_flag_receiver_only != 0) continue;
            if (result.count == result.entries.len) return error.Capacity;
            var encoding: a.GfxOutputColorState = .{};
            const color_rc = outputs.color(&value.info.identity, &encoding);
            if (color_rc == a.gfx_output_ok) {
                if (encoding.revision != before.revision or !std.meta.eql(encoding.identity, value.info.identity)) return error.Stale;
                value.color = encoding;
            } else if (color_rc != a.err_no_fn and color_rc != a.gfx_output_error_unsupported) return error.Stale;
            // Driver adapter IDs encode the stable PCI location. Connection
            // and device generations deliberately do not enter saved keys.
            value.key = .{ .adapter = value.info.identity.adapter_id, .connector = value.info.identity.connector_id };
            if (readReceiver(draw, &value.info)) |report| {
                @memcpy(value.name[0..13], &report.name);
                value.key = topology.Key.fromReport(value.key.adapter, value.key.connector, &report) catch value.key;
            } else |err| {
                // A transient EDID read cannot rename a connected monitor
                // to its anonymous port key in an otherwise valid snapshot.
                if (err == error.Stale) return error.Stale;
            }
            if (value.info.flags & a.gfx_output_flag_active != 0) for (0..topology.capacity) |head| {
                var target: a.GfxOutputTarget = .{};
                const target_rc = draw.displayOutputTarget(value.info.identity.adapter_id, @intCast(head), &target);
                if (target_rc != a.gfx_output_ok) {
                    // Busy while the native output owner is borrowed is not
                    // evidence that an active head disappeared. Abort this
                    // candidate; callers retain their last complete catalog.
                    if (target_rc == a.gfx_output_error_unsupported or target_rc == a.err_no_fn or target_rc == a.err_no_group) continue;
                    return error.Stale;
                }
                if (target.connector_id != value.info.identity.connector_id) continue;
                if (target.device_generation != value.info.identity.device_generation or
                    target.connection_generation != value.info.identity.connection_generation) return error.Stale;
                var presentation: a.DisplayPresentationInfo = .{};
                if (draw.displayOutputPresentationInfo(&target, &presentation) != a.gfx_output_ok) return error.Stale;
                if (presentation.width == 0 or presentation.height == 0 or presentation.width > 65536 or presentation.height > 65536 or
                    presentation.flags & (a.display_presentation_info_lost | a.display_presentation_info_occluded) != 0) continue;
                value.target = target; value.presentation = presentation; break;
            };
            result.entries[result.count] = value; result.count += 1;
        }
        var after: a.GfxDisplayRevision = .{};
        if (outputs.revision(&after) != a.gfx_output_ok or after.revision != before.revision) return error.Stale;
        return result;
    }
};

pub fn readReceiver(draw: anytype, info: *const a.GfxOutputInfo) !edid.Report {
    if (info.edid_bytes == 0 or info.edid_bytes > edid.max_blocks * 128 or info.edid_bytes % 128 != 0) return error.Unavailable;
    var bytes: [edid.max_blocks * 128]u8 = undefined;
    const outputs = draw.outputs();
    for (0..info.edid_bytes / 128) |index| {
        var block: a.GfxEdidBlock = .{};
        if (outputs.edid(&info.identity, @intCast(index), &block) != a.gfx_output_ok or
            !std.meta.eql(block.identity, info.identity) or block.byte_count != 128 or block.block_index != index) return error.Stale;
        @memcpy(bytes[index * 128..][0..128], &block.data);
    }
    var after: a.GfxDisplayRevision = .{};
    if (outputs.revision(&after) != a.gfx_output_ok or after.revision != info.topology_revision) return error.Stale;
    var report: edid.Report = .{};
    try edid.parse(bytes[0..info.edid_bytes], &report);
    if (!report.complete()) return error.Incomplete;
    return report;
}
