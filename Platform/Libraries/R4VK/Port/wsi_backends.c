/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_wsi_backend.h"
#include "r4vk_provider.h"
#include "r4vk_nvk_device.h"
#include "r4vk_nvk_submit.h"
#include "r4vk_nvk_wsi_image.h"
#include "r4vk_radv_winsys.h"
#include "nvk_device.h"
#include "nvk_entrypoints.h"
#include "nvk_format.h"
#include "nvk_image.h"
#include "nvk_physical_device.h"
#include "radv_device.h"
#include "radv_entrypoints.h"
#include "radv_image.h"
#include "radv_physical_device.h"

static struct vk_instance *nvk_instance(struct vk_physical_device *pdev) { return pdev->instance; }
static struct vk_instance *amd_instance(struct vk_physical_device *pdev)
{
   return radv_physical_device_instance((struct radv_physical_device *)pdev)->native_parent;
}
static VkResult nvk_physical(struct vk_physical_device *base, R4GfxBackendBinding *binding, uint64_t *generation)
{
   struct nvk_physical_device *pdev = container_of(base, struct nvk_physical_device, vk);
   struct r4vk_nvk_architecture facts;
   VkResult result = r4vk_nvk_query_pdev_architecture(pdev->nvkmd, &facts);
   if (result == VK_SUCCESS) { *binding = facts.binding; *generation = facts.memory_generation; }
   return result;
}
static VkResult amd_physical(struct vk_physical_device *base, R4GfxBackendBinding *binding, uint64_t *generation)
{
   struct radv_physical_device *pdev = container_of(base, struct radv_physical_device, vk);
   VkResult result = r4vk_radv_provider.revalidate(base);
   if (result == VK_SUCCESS) { *binding = pdev->native_facts.backend.binding; *generation = pdev->native_facts.backend.memory_generation; }
   return result;
}
static VkFormatFeatureFlags2 nvk_features(struct vk_physical_device *base, VkFormat format)
{
   return nvk_get_image_format_features(container_of(base, struct nvk_physical_device, vk),
      format, VK_IMAGE_TILING_DRM_FORMAT_MODIFIER_EXT, 0);
}
static VkFormatFeatureFlags2 amd_features(struct vk_physical_device *base, VkFormat format)
{
   VkFormatProperties3 flags = {.sType = VK_STRUCTURE_TYPE_FORMAT_PROPERTIES_3};
   VkFormatProperties2 properties = {.sType = VK_STRUCTURE_TYPE_FORMAT_PROPERTIES_2, .pNext = &flags};
   radv_GetPhysicalDeviceFormatProperties2(vk_physical_device_to_handle(base), format, &properties);
   /* Modifier zero uses RADV's linear feature set. No compression, external
    * FD ownership or arbitrary optimal-tiled layout is implied. */
   return flags.linearTilingFeatures;
}
static bool nvk_present(struct vk_physical_device *base, uint32_t family)
{
   struct nvk_physical_device *pdev = container_of(base, struct nvk_physical_device, vk);
   return family < pdev->queue_family_count && (pdev->queue_families[family].queue_flags & VK_QUEUE_GRAPHICS_BIT);
}
static bool amd_present(struct vk_physical_device *base, uint32_t family)
{
   VkQueueFamilyProperties2 properties[RADV_MAX_QUEUE_FAMILIES];
   for (unsigned i = 0; i < ARRAY_SIZE(properties); i++)
      properties[i] = (VkQueueFamilyProperties2){.sType = VK_STRUCTURE_TYPE_QUEUE_FAMILY_PROPERTIES_2};
   uint32_t count = ARRAY_SIZE(properties);
   radv_GetPhysicalDeviceQueueFamilyProperties2(vk_physical_device_to_handle(base), &count, properties);
   return family < count && (properties[family].queueFamilyProperties.queueFlags & VK_QUEUE_GRAPHICS_BIT);
}
static VkResult nvk_check(struct vk_device *dev)
{ return r4vk_nvk_check_device(container_of(dev, struct nvk_device, vk)->nvkmd); }
static VkResult amd_check(struct vk_device *dev)
{ return r4vk_radv_validate((struct r4vk_radv_ws *)container_of(dev, struct radv_device, vk)->ws); }
static const struct vk_image *nvk_image(VkImage image) { return &nvk_image_from_handle(image)->vk; }
static const struct vk_image *amd_image(VkImage image) { return &radv_image_from_handle(image)->vk; }

/* Typed bridges keep the C function ABI defined; the window worker keeps
 * these static operations with every independently retained native point. */
#define POINT_BRIDGE(name) \
static VkResult name##_take(struct vk_sync *sync, void **out, R4GfxFence *fence) { \
   struct r4vk_##name##_point *point = NULL; \
   VkResult result = r4vk_##name##_sync_take_present(sync, &point, fence); \
   if (result == VK_SUCCESS) *out = point; return result; } \
static VkResult name##_pin(void *point, R4GfxFence *fence) { return r4vk_##name##_point_pin(point, fence); } \
static void name##_ref(void *point) { r4vk_##name##_point_ref(point); } \
static void name##_unref(void *point) { r4vk_##name##_point_unref(point); } \
static void name##_unpin(void *point) { r4vk_##name##_point_unexport(point); }
POINT_BRIDGE(nvk)
POINT_BRIDGE(radv)
#undef POINT_BRIDGE

static const struct r4vk_wsi_backend nvk_ops = {
   .instance = nvk_instance, .physical = nvk_physical, .features = nvk_features, .can_present = nvk_present,
   .check = nvk_check, .import = r4vk_nvk_import_wsi_image, .finish = r4vk_nvk_finish_wsi_image,
   .acquired = r4vk_nvk_wsi_acquired,
   .image = nvk_image, .create_image = nvk_CreateImage, .prepare = r4vk_nvk_sync_prepare_present,
   .take = nvk_take, .pin = nvk_pin, .ref = nvk_ref, .unref = nvk_unref, .unpin = nvk_unpin,
};
static const struct r4vk_wsi_backend amd_ops = {
   .instance = amd_instance, .physical = amd_physical, .features = amd_features, .can_present = amd_present,
   .check = amd_check, .import = r4vk_radv_import_wsi_image, .finish = r4vk_radv_finish_wsi_image,
   .image = amd_image, .create_image = radv_CreateImage, .prepare = r4vk_radv_sync_prepare_present,
   .take = radv_take, .pin = radv_pin, .ref = radv_ref, .unref = radv_unref, .unpin = radv_unpin,
};
const struct r4vk_wsi_backend *r4vk_wsi_backend(struct vk_physical_device *pdev)
{
   if (pdev->r4os_provider == &r4vk_nvk_provider) return &nvk_ops;
   if (pdev->r4os_provider == &r4vk_radv_provider) return &amd_ops;
   return NULL;
}

const struct vk_physical_device_entrypoint_table r4vk_wsi_physical_entrypoints = {
   .GetPhysicalDeviceSurfaceSupportKHR = nvk_GetPhysicalDeviceSurfaceSupportKHR,
   .GetPhysicalDeviceSurfaceCapabilitiesKHR = nvk_GetPhysicalDeviceSurfaceCapabilitiesKHR,
   .GetPhysicalDeviceSurfaceCapabilities2KHR = nvk_GetPhysicalDeviceSurfaceCapabilities2KHR,
   .GetPhysicalDeviceSurfaceFormatsKHR = nvk_GetPhysicalDeviceSurfaceFormatsKHR,
   .GetPhysicalDeviceSurfaceFormats2KHR = nvk_GetPhysicalDeviceSurfaceFormats2KHR,
   .GetPhysicalDeviceSurfacePresentModesKHR = nvk_GetPhysicalDeviceSurfacePresentModesKHR,
   .GetPhysicalDevicePresentRectanglesKHR = nvk_GetPhysicalDevicePresentRectanglesKHR,
};
const struct vk_device_entrypoint_table r4vk_wsi_device_entrypoints = {
   .CreateSwapchainKHR = nvk_CreateSwapchainKHR, .DestroySwapchainKHR = nvk_DestroySwapchainKHR,
   .GetSwapchainImagesKHR = nvk_GetSwapchainImagesKHR, .AcquireNextImageKHR = nvk_AcquireNextImageKHR,
   .AcquireNextImage2KHR = nvk_AcquireNextImage2KHR, .QueuePresentKHR = nvk_QueuePresentKHR,
   .GetDeviceGroupPresentCapabilitiesKHR = nvk_GetDeviceGroupPresentCapabilitiesKHR,
   .GetDeviceGroupSurfacePresentModesKHR = nvk_GetDeviceGroupSurfacePresentModesKHR,
};
