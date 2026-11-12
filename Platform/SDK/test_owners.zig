//! Package-root test entry: imports must remain in this module, not a separate
//! SDK dependency whose tests Zig deliberately omits from this test artifact.
test "wire owner pure helpers" {
    _ = @import("r4os/binary_cursor.zig");
    _ = @import("r4os/native_protocol_view.zig");
    _ = @import("r4os/internet_checksum.zig");
    _ = @import("r4os/block_transfer.zig");
}
test "cli owner shared helpers" {
    _ = @import("r4os/diagnostic_sinks.zig");
    _ = @import("r4os/arg_cursor.zig");
    _ = @import("r4os/diagnostic_buffer.zig");
}
test "stream owner shared transfer" {
    _ = @import("r4os/stream_transfer.zig");
    _ = @import("r4os/stream_adapters.zig");
}
test "inventory owner staged views" {
    _ = @import("r4os/inventory_reader.zig");
}
test "device snapshot owner complete frozen views" {
    _ = @import("r4os/device_snapshot_tests.zig");
}
test "metadata2 owner exact thin provider views" {
    _ = @import("r4os/metadata2_tests.zig");
}
test "text metrics owner original comparison and frozen hits" {
    _ = @import("r4os/text_metrics_tests.zig");
}
test "file picker owner bounded shared controller" {
    _ = @import("r4os/file_picker_tests.zig");
}
test "audio write owner total deadline and source pacing" {
    _ = @import("r4os/audio_write_tests.zig");
}
test "published frame owner scoped copy presentation" {
    _ = @import("r4os/published_frame_tests.zig");
}
test {
    _ = @import("Tests/Simulation/DataOwners.zig");
    _ = @import("Tests/Simulation/WebOwners.zig");
    _ = @import("Tests/Simulation/TransportOwners.zig");
}

test "composition owner copied text and exact focus" {
    _ = @import("r4os/text_composition_tests.zig");
}

test {
    _ = @import("r4os/network_family.zig");
}

test {
    _ = @import("r4os/network_stream.zig");
    _ = @import("r4os/launch_io.zig");
}
