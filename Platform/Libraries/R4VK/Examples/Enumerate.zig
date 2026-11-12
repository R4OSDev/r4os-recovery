//! Bootstrap the public ICD and enumerate devices without assuming a GPU.
//! Bind `vulkan` to a translation of the pinned vulkan_core.h.
const r = @import("r4os");
const binding = @import("r4vk");
const v = @import("vulkan");

fn proc(comptime T: type, get: v.PFN_vkGetInstanceProcAddr, instance: v.VkInstance, name: [*:0]const u8) !T {
    return @ptrCast(get.?(instance, name) orelse return error.MissingFunction);
}

pub fn r4_app_main(app: *r.App2) i32 {
    const count = enumerate(app) catch |err| {
        app.system().println(@errorName(err));
        return -1;
    };
    app.system().write("Vulkan devices: ");
    app.system().printU64(count);
    app.system().println(if (count == 0) " (use R4DRAW or software OpenGL)" else " (query features before device creation)");
    return 0;
}

pub fn enumerate(app: *r.App2) !u32 {
    const client = try binding.VulkanV1Client.init2(app.startContext());
    var loader: binding.R4VkLoader = undefined;
    if (client.open(&.{ .version = 2, .size = @sizeOf(binding.R4VkRuntime),
        .sys = @intFromPtr(app.startContext()), .draw = 0, .dev = 0 }, &loader) != 0) return error.Loader;
    const get: v.PFN_vkGetInstanceProcAddr = @ptrFromInt(loader.get_instance_proc_addr);
    const create = try proc(v.PFN_vkCreateInstance, get, null, "vkCreateInstance");
    const application: v.VkApplicationInfo = .{ .sType = v.VK_STRUCTURE_TYPE_APPLICATION_INFO,
        .pApplicationName = "R4OS Vulkan enumeration", .apiVersion = v.VK_API_VERSION_1_3 };
    var instance: v.VkInstance = null;
    if (create.?(&.{ .sType = v.VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pApplicationInfo = &application }, null, &instance) != v.VK_SUCCESS) return error.Instance;
    const destroy = try proc(v.PFN_vkDestroyInstance, get, instance, "vkDestroyInstance");
    defer destroy.?(instance, null);
    const list = try proc(v.PFN_vkEnumeratePhysicalDevices, get, instance, "vkEnumeratePhysicalDevices");
    var count: u32 = 0;
    if (list.?(instance, &count, null) != v.VK_SUCCESS) return error.Enumeration;
    // Zero is a normal capability result. This provider does not emulate Vulkan.
    return count;
}
