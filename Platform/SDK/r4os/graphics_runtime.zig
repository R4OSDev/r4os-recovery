//! Admission only. Work and status formatting remain at their owners.
//! Ending a context never retires or acknowledges GPU resources.
const a = @import("r4os_contract").abi;
const p = @import("program.zig");
const support = @import("graphics_support.zig");
pub export fn R4SdkGfxOpenNative(fingerprint: u64, out: *support.Context, raw: *const a.R4XStartContext) callconv(.c) i32 {
    if (fingerprint != @import("gui_bridge_schema.zig").fingerprint) return a.io_error_invalid;
    const bundle = p.bundleValueFromR4XStart(raw) orelse return a.err_no_group;
    inline for (.{ .{ bundle.sys, a.R4XStartR4Sys{} }, .{ bundle.draw, a.R4XStartR4Draw{} } }) |entry| {
        const table = entry[0] orelse return a.err_no_group;
        if (table.abi_version < entry[1].abi_version or table.size < entry[1].size) return a.err_no_fn;
    }
    // R4DEV is optional for offscreen work, but must be current if supplied.
    if (bundle.dev) |table| {
        const current = a.R4XStartR4Dev{};
        if (table.abi_version < current.abi_version or table.size < current.size) return a.err_no_fn;
    }
    out.* = .{ .bundle = bundle, .draw = undefined, .dev = undefined };
    out.draw = @import("r4draw.zig").Context.init(&out.bundle);
    out.dev = @import("r4dev.zig").Context.init(&out.bundle);
    return 0;
}
pub export fn R4SdkGfxDraw(out: *support.Context) callconv(.c) *@import("r4draw.zig").Context {
    return &out.draw;
}
pub export fn R4SdkGfxOpenNative2(fingerprint: u64, out: *support.Context, raw: *const @import("platform2.zig").abi.R4XStartContext2) callconv(.c) i32 {
    if (fingerprint != @import("gui_bridge_schema.zig").fingerprint) return a.io_error_invalid;
    const platform = @import("platform2.zig");
    const context = platform.Context.init(raw) catch return a.io_error_invalid;
    inline for (.{ .{ context.system(), platform.abi.R4XStartR4Sys2{} }, .{ context.drawing(), platform.abi.R4XStartR4Draw2{} } }) |entry| {
        const table = entry[0] orelse return a.err_no_group;
        if (table.abi_version < entry[1].abi_version or table.size < entry[1].size) return a.err_no_fn;
    }
    if (context.devices()) |table| {
        const current = platform.abi.R4XStartR4Dev2{};
        if (table.abi_version < current.abi_version or table.size < current.size) return a.err_no_fn;
    }
    out.* = .{ .bundle = undefined, .context2 = context, .draw = undefined, .dev = undefined };
    out.memory2 = @import("allocator_source.zig").Memory.fromContext2(&out.context2.?);
    const program: p.Context = .{ .generation2 = &out.context2.?, .memory2 = &out.memory2 };
    out.draw = @import("r4draw.zig").Context.fromProgram(program);
    out.dev = @import("r4dev.zig").Context.fromProgram(program);
    return 0;
}
pub export fn R4SdkGfxDevice(out: *support.Context) callconv(.c) *@import("r4dev.zig").Context {
    return &out.dev;
}
