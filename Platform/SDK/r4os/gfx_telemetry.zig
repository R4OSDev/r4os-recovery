//! Read-only telemetry presentation shared by diagnostics and device details.
const std = @import("std");
const a = @import("r4os_contract").abi;
pub const Field = struct { label: []const u8, metric: usize, value: usize = 0, scale: u64 = 1, unit: []const u8 = "" };
pub const fields = [_]Field{
    .{ .label = "P-state", .metric = 3 },
    .{ .label = "GPU target", .metric = 0, .scale = 1_000_000, .unit = "MHz" },
    .{ .label = "Memory target", .metric = 0, .value = 1, .scale = 1_000_000, .unit = "MHz" },
    .{ .label = "Video target", .metric = 0, .value = 2, .scale = 1_000_000, .unit = "MHz" },
    .{ .label = "SM target", .metric = 0, .value = 3, .scale = 1_000_000, .unit = "MHz" },
    .{ .label = "GPU temp", .metric = 5, .scale = 1000, .unit = "C" },
    .{ .label = "Memory temp", .metric = 6, .scale = 1000, .unit = "C" },
    .{ .label = "GPU power avg", .metric = 7, .scale = 1000, .unit = "W" },
    .{ .label = "Module power avg", .metric = 7, .value = 1, .scale = 1000, .unit = "W" },
    .{ .label = "GPU power now", .metric = 8, .scale = 1000, .unit = "W" },
    .{ .label = "GPU limit", .metric = 4, .value = 1, .scale = 1000, .unit = "W" },
    .{ .label = "Requested limit", .metric = 4, .scale = 1000, .unit = "W" },
    .{ .label = "GPU busy", .metric = 2, .unit = "%" },
    .{ .label = "Memory busy", .metric = 2, .value = 1, .unit = "%" },
    .{ .label = "GPU global timer", .metric = 9, .unit = "ns" },
    .{ .label = "GPU timer delta", .metric = 9, .value = 1, .unit = "ns" },
};
pub fn statusName(status: u32) []const u8 {
    const names = [_][]const u8{"unavailable","changing","malformed","awaiting update","fresh","stale"};
    return if (status < names.len) names[status] else "unknown";
}
pub fn policyName(value: u32) []const u8 {
    const names = [_][]const u8{"idle","settling","desktop","multi-monitor","render","fullscreen","video","compute","limited","stopping"};
    return if (value < names.len) names[value] else "unknown";
}
pub fn formatLine(output: []u8, state: *const a.GfxTelemetryState, index: usize) []const u8 {
    if (index >= fields.len) return "unknown metric";
    var field = fields[index]; const metric = state.metrics[field.metric];
    if (field.metric == 0 and (metric.flags & a.gfx_telemetry_current_clocks != 0 or state.source == a.gfx_telemetry_source_smu10)) field.label = switch (field.value) {
        0 => "GPU clock", 1 => "Memory clock", 2 => "Video clock", else => "SM clock",
    };
    if (field.metric == 0 and field.value == 1 and (metric.flags & a.gfx_telemetry_fabric_clock != 0 or state.source == a.gfx_telemetry_source_smu10)) field.label = "Fabric clock";
    if (state.source == a.gfx_telemetry_source_smu10 and field.metric == 5) field.label = "APU temp";
    if (metric.status == a.gfx_telemetry_fresh and metric.flags & a.gfx_telemetry_partial_values != 0 and
        metric.flags & (@as(u32, 1) << @intCast(8 + field.value)) == 0)
        return std.fmt.bufPrint(output, "{s}: unknown (unavailable)", .{field.label}) catch "unknown";
    const status = if (metric.status == a.gfx_telemetry_fresh and field.metric == 9 and field.value == 1 and metric.flags & a.gfx_telemetry_timer_delta_valid == 0)
        a.gfx_telemetry_unavailable else metric.status;
    if (status != a.gfx_telemetry_fresh) return std.fmt.bufPrint(output, "{s}: unknown ({s})", .{field.label,statusName(status)}) catch "unknown";
    const value = metric.values[field.value];
    if (field.metric == 3) return std.fmt.bufPrint(output, "{s}: P{d}", .{field.label,value}) catch "unknown";
    if (field.scale == 1) return std.fmt.bufPrint(output, "{s}: {d} {s}", .{field.label,value,field.unit}) catch "unknown";
    const magnitude: u64 = @abs(value);
    return std.fmt.bufPrint(output, "{s}: {s}{d}.{d} {s}", .{field.label,if (value < 0) "-" else "",magnitude/field.scale,
        (magnitude%field.scale)*10/field.scale,field.unit}) catch "unknown";
}
pub fn forAdapter(draw: anytype, adapter: u32, mask: u64, output: *a.GfxTelemetryState) i32 {
    for (0..a.gfx_queue_backend_capacity) |i| {
        var backend: a.GfxBackendInfo = .{};
        if (draw.queues().backendInfo(@intCast(i), &backend) != 1 or backend.size < @sizeOf(a.GfxBackendInfo) or
            backend.binding.adapter_id != adapter or backend.memory_generation == 0) continue;
        return draw.gfxTelemetry(&.{ .adapter_id = adapter, .memory_generation = backend.memory_generation, .metric_mask = mask }, output);
    }
    return a.gfx_buffer_error_unavailable;
}
