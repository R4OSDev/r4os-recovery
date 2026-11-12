// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const local = @import("process_local.zig");
const Context = struct { version: u32 };
var context_key: u8 = 0;
const max_version: u32 = 7;
const incompatible_driver: c_int = -9;
const out_of_host_memory: c_int = -1;

fn init(context: *Context) void {
    context.* = .{ .version = max_version };
}

// Keep the upstream minimum-across-negotiations behavior within one caller.
// v0 cannot use the supported dispatchable-object layout and is rejected.
pub export fn r4vk_negotiate_icd_version(version: *u32) callconv(.c) c_int {
    if (version.* == 0) return incompatible_driver;
    const context = local.getOrCreate(Context, &context_key, init) orelse return out_of_host_memory;
    const previous = @atomicRmw(u32, &context.version, .Min, @min(version.*, max_version), .acq_rel);
    version.* = @min(previous, @min(version.*, max_version));
    return 0;
}

pub export fn r4vk_get_icd_version() callconv(.c) u32 {
    const context = (local.lookup(Context, &context_key) catch @trap()) orelse return max_version;
    return @atomicLoad(u32, &context.version, .acquire);
}
