// Compiled receiver-data helper; the R4GFX R4L table remains independent.
const r4os = @import("r4os");
pub const edid = @import("r4gfx_edid");
pub const color = edid.color;
pub const links = edid.links;
const a = r4os.abi;
pub const Error = edid.Error || error{ Invalid, Unavailable, Stale, ReadFailed };

pub fn readReceiver(ctx: *const r4os.gfx_outputs.Context, info: *const a.GfxOutputInfo, storage: []u8, report: *edid.Report) Error!void {
    if (info.version != 1 or info.size < @sizeOf(a.GfxOutputInfo) or info.edid_bytes > a.gfx_output_max_edid_bytes or
        info.edid_bytes > storage.len or info.edid_bytes % 128 != 0) return error.Invalid;
    if (info.edid_bytes == 0) return error.Unavailable;
    for (0..info.edid_bytes / 128) |index| {
        var block: a.GfxEdidBlock = .{};
        const rc = ctx.edid(&info.identity, @intCast(index), &block);
        if (rc == a.gfx_output_error_stale) return error.Stale;
        if (rc != a.gfx_output_ok or block.byte_count != 128 or block.block_index != index or
            !@import("std").meta.eql(block.identity, info.identity)) return error.ReadFailed;
        @memcpy(storage[index * 128 ..][0..128], &block.data);
    }
    // A final generation check closes the last-block/publication race. The
    // report is published only after every block belongs to this receiver.
    var last: a.GfxEdidBlock = .{};
    if (ctx.edid(&info.identity, 0, &last) != a.gfx_output_ok) return error.Stale;
    try edid.parse(storage[0..info.edid_bytes], report);
}

pub fn modeFromTiming(value: edid.timing.Timing, id: u32) ?a.GfxOutputMode {
    if (id == 0 or !value.valid() or value.flags & edid.timing.incomplete != 0) return null;
    return .{ .mode_id = id, .flags = value.flags, .width = value.width, .height = value.height,
        .pixel_clock_hz = value.clock_hz, .h_total = value.h_total, .h_sync_start = value.h_start, .h_sync_end = value.h_end,
        .v_total = value.v_total, .v_sync_start = value.v_start, .v_sync_end = value.v_end, .refresh_millihz = value.millihz() };
}
