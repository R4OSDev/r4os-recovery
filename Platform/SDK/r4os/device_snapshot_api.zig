const platform = @import("platform2.zig");
pub const core = @import("device_snapshot.zig");
pub const Snapshot = core.Snapshot;
pub const Provider = core.Provider;
pub const Cursor = core.Cursor;
pub const Progress = core.Progress;
pub const PageInfo = core.PageInfo;
pub const Page = core.Page;
pub const Status = core.Status;
pub const PageStatus = core.PageStatus;
pub const Error = core.Error;
pub const page_max = core.page_max;
/// The Context/table/code owner remains borrowed through the actual capture.
pub fn fromContext2(context: *const platform.Context) Error!Provider {
    var address: u64 = 0;
    if (context.lookup(6, @offsetOf(platform.abi.R4XStartR4Dev2, "device_inventory_capture"), &address) != 0) return error.NoProvider;
    return .{ .capture = @ptrFromInt(address) };
}
