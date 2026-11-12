//! The single SDK helper object shared by C and Rust consumers.
pub const panic = @import("runtime_fault.zig").panic;
comptime {
    // Host facade oracles link this same object. Consolidate its heap exports
    // here; freestanding modules keep the single separate heap runtime object.
    if (@import("builtin").os.tag != .freestanding) _ = @import("heap_runtime.zig");
    _ = @import("driver_value_bridge.zig");
    _ = @import("subsystem_value_bridge.zig");
    _ = @import("runtime_bootstrap.zig");
    _ = @import("app2_runtime.zig");
    _ = @import("storage_runtime.zig");
    _ = @import("services_runtime.zig");
    _ = @import("time_budget_runtime.zig");
    _ = @import("wire_runtime.zig");
    _ = @import("cli_runtime.zig");
    _ = @import("stream_runtime.zig");
    _ = @import("inventory_runtime.zig");
    _ = @import("device_snapshot_runtime.zig");
    _ = @import("text_metrics_runtime.zig");
    _ = @import("text_composition_runtime.zig");
    _ = @import("file_picker_runtime.zig");
    _ = @import("audio_write_runtime.zig");
    _ = @import("published_frame_runtime.zig");
    _ = @import("generated/net_facade.zig");
    _ = @import("net_request_runtime.zig");
    _ = @import("gui_value_bridge.zig");
    _ = @import("graphics_runtime.zig");
    _ = @import("platform_runtime.zig");
    _ = @import("data_value_bridge.zig");
    _ = @import("web_value_bridge.zig");
    _ = @import("transport_value_bridge.zig");
}

comptime {
    _ = @import("update_value_bridge.zig");
}
