// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
const r4os = @import("r4os");
const c = @import("r4l_contract");
const port = @import("runtime");

export fn r4l_entry() linksection(".text.r4l_entry") callconv(.c) void {}
comptime {
    _ = port.compiler;
    _ = port.platform;
}

extern fn vk_icdGetInstanceProcAddr(?*anyopaque, [*:0]const u8) callconv(.c) ?*const anyopaque;
extern fn vk_icdGetPhysicalDeviceProcAddr(?*anyopaque, [*:0]const u8) callconv(.c) ?*const anyopaque;
extern fn vk_icdNegotiateLoaderICDInterfaceVersion(*u32) callconv(.c) i32;

// Native Zig thunks preserve addressable R4M function relocations. Vulkan's
// x86_64 C ABI and its dispatchable handles remain unchanged behind them.
fn getInstanceProcAddr(instance: ?*anyopaque, name: [*:0]const u8) callconv(.c) ?*const anyopaque {
    return vk_icdGetInstanceProcAddr(instance, name);
}
fn getPhysicalDeviceProcAddr(instance: ?*anyopaque, name: [*:0]const u8) callconv(.c) ?*const anyopaque {
    return vk_icdGetPhysicalDeviceProcAddr(instance, name);
}
fn negotiate(version: *u32) callconv(.c) i32 {
    return vk_icdNegotiateLoaderICDInterfaceVersion(version);
}

pub export fn r4vk_open_impl(runtime: *const c.R4VkRuntime, output: *c.R4VkLoader) callconv(.c) i32 {
    if (runtime.size < @sizeOf(c.R4VkRuntime) or runtime.sys == 0 or runtime.sys % 8 != 0)
        return c.error_initialization_failed;
    switch (runtime.version) {
        1 => {
            if (runtime.draw == 0 or runtime.dev == 0 or runtime.draw % 8 != 0 or runtime.dev % 8 != 0 or
                !port.bind(@ptrFromInt(runtime.sys)) or !port.platform.bind(@ptrFromInt(runtime.draw), @ptrFromInt(runtime.dev)))
                return c.error_initialization_failed;
        },
        // Version2 carries an actual opaque Start2 address in sys; the former
        // table-address fields are zero. VULKAN_V1's slots/layout stay stable.
        2 => {
            if (runtime.draw != 0 or runtime.dev != 0 or !port.bind2(@ptrFromInt(runtime.sys)))
                return c.error_initialization_failed;
        },
        else => return c.error_initialization_failed,
    }
    output.* = .{
        .version = 1,
        .size = @sizeOf(c.R4VkLoader),
        .negotiate_loader_icd = @intFromPtr(&negotiate),
        .get_instance_proc_addr = @intFromPtr(&getInstanceProcAddr),
        .get_physical_device_proc_addr = @intFromPtr(&getPhysicalDeviceProcAddr),
    };
    return c.success;
}

pub export var r4vk_vulkan_v1: c.VulkanV1 align(8) linksection(".data.r4l_exports") = .{
    .header = c.vulkan_v1_header,
    .open = r4vk_open_impl,
};
pub export var r4vk_query: r4os.abi.R4LQuery align(8) linksection(".data.r4l_exports") = .{
    .magic = r4os.abi.r4l_abi_magic,
    .abi_version = r4os.abi.r4l_abi_version,
    .size = r4os.abi.r4l_query_struct_size,
    .group = 0,
    .kernel_bridge = 0,
    .reserved = 0,
};

// Technical generation2 query; independent interfaces keep their revisions.
pub export var r4vk_query2: r4os.platform2.abi.R4LQuery2 align(8) linksection(".data.r4l_exports") = .{};
