//! Caller-owned stable contexts; no window/host role or output policy.
const p = @import("program.zig");
pub const Context = struct {
    context2: ?@import("platform2.zig").Context = null,
    memory2: @import("allocator_source.zig").Memory = undefined,
    draw: @import("r4draw.zig").Context,
    dev: @import("r4dev.zig").Context,
};
