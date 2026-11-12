const platform = @import("platform2.zig");
pub const core = @import("text_metrics.zig");
pub const Cache = core.Cache;
pub const Key = core.Key;
pub const Progress = core.Progress;
pub const Provider = core.Provider;
pub const Error = core.Error;
pub const Binding = struct { status: i32, provider: Provider };

/// Context/import/provider code remains borrowed through actual calls. No
/// legacy fallback or synthetic empty-success provider is installed.
pub fn provider2(context: *const platform.Context) Binding {
    var address: u64 = 0;
    const rc = context.lookup(3, @offsetOf(platform.abi.R4XStartR4Draw2, "font_prefix_metrics2"), &address);
    if (rc != 0) return .{ .status = rc, .provider = .{} };
    return .{ .status = 0, .provider = .{ .measure = @ptrFromInt(address) } };
}

/// Empty-source stamp costs no full-text measurement. A failed/mismatched
/// observation explicitly discards this logical cache; it stops no hardware.
pub fn validateFont(context: *const platform.Context, cache: *Cache) Error!i32 {
    const key = try cache.key();
    const binding = provider2(context);
    if (binding.status != 0) {
        try cache.reset();
        return binding.status;
    }
    var info: platform.abi.shared.FontAdvanceInfo2 = .{};
    const rc = binding.provider.measure.?(key.font_id, null, 0, null, 0, &info);
    if (rc != 0) {
        try cache.reset();
        return rc;
    }
    const a = platform.abi.shared;
    if (info.version != a.font_metrics2_version or info.size != @sizeOf(a.FontAdvanceInfo2) or
        info.font_id != key.font_id or info.font_revision == 0 or info.text_bytes != 0 or info.count != 0 or
        info.required_count != 0 or info.flags != a.font_metrics2_flag_complete or info.reserved0 != 0)
    {
        try cache.reset();
        return core.invalid_provider;
    }
    if (info.font_revision != key.font_revision) {
        try cache.reset();
        return a.font_metrics2_stale;
    }
    return 0;
}
