/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_wsi.h"
#include "r4vk_wsi_backend.h"
#include "nvk_entrypoints.h"
#include "vk_alloc.h"
#include "vk_instance.h"
#include <r4gfx.h>

static struct r4vk_surface *surface_from_handle(VkSurfaceKHR handle)
{
   return (struct r4vk_surface *)(uintptr_t)handle;
}

VKAPI_ATTR VkResult VKAPI_CALL
r4vkCreateWindowSurface(VkInstance handle, const R4VkWindowSurfaceCreateInfo *info,
   const VkAllocationCallbacks *allocator, VkSurfaceKHR *out)
{
   if (out) *out = VK_NULL_HANDLE;
   if (!handle || !info || !out || info->version != R4VK_WINDOW_SURFACE_VERSION ||
       info->size != sizeof(*info) || !info->application || !info->window_id || info->reserved)
      return VK_ERROR_INITIALIZATION_FAILED;
   VK_FROM_HANDLE(vk_instance, instance, handle);
   if (!instance->enabled_extensions.KHR_surface) return VK_ERROR_EXTENSION_NOT_PRESENT;
   uint64_t application;
   if (!r4vk_application_snapshot(info->application, &application))
      return VK_ERROR_INITIALIZATION_FAILED;
   R4WindowGraphicsReply reply;
   int32_t status = r4vk_window_query(application, info->window_id, NULL, &reply);
   if (status == R4OS_WINDOW_GRAPHICS_UNAVAILABLE || status == R4OS_WINDOW_GRAPHICS_NOT_READY)
      return VK_NOT_READY;
   if (status != R4OS_WINDOW_GRAPHICS_OK) return VK_ERROR_SURFACE_LOST_KHR;
   struct r4vk_surface *surface = vk_zalloc2(&instance->alloc, allocator,
      sizeof(*surface), 8, VK_SYSTEM_ALLOCATION_SCOPE_OBJECT);
   if (!surface) return VK_ERROR_OUT_OF_HOST_MEMORY;
   *surface = (struct r4vk_surface) {
      .instance = instance, .application = application, .identity = reply.surface,
   };
   *out = (VkSurfaceKHR)(uintptr_t)surface;
   return VK_SUCCESS;
}

VKAPI_ATTR void VKAPI_CALL
nvk_DestroySurfaceKHR(VkInstance handle, VkSurfaceKHR surface,
                     const VkAllocationCallbacks *allocator)
{
   if (!surface) return;
   VK_FROM_HANDLE(vk_instance, instance, handle);
   /* The surface owns no display, imported BO or service publication. */
   vk_free2(&instance->alloc, allocator, surface_from_handle(surface));
}

static VkImageUsageFlags format_usage(struct vk_physical_device *pdev, VkFormat format)
{
   /* Advertise only features of the provider's actual imported layout. */
   VkFormatFeatureFlags2 f = r4vk_wsi_backend(pdev)->features(pdev, format);
   VkImageUsageFlags usage = 0;
   if (f & VK_FORMAT_FEATURE_2_COLOR_ATTACHMENT_BIT)
      usage |= VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT;
   if (f & VK_FORMAT_FEATURE_2_TRANSFER_SRC_BIT) usage |= VK_IMAGE_USAGE_TRANSFER_SRC_BIT;
   if (f & VK_FORMAT_FEATURE_2_TRANSFER_DST_BIT) usage |= VK_IMAGE_USAGE_TRANSFER_DST_BIT;
   if (f & VK_FORMAT_FEATURE_2_SAMPLED_IMAGE_BIT) usage |= VK_IMAGE_USAGE_SAMPLED_BIT;
   if (f & VK_FORMAT_FEATURE_2_STORAGE_IMAGE_BIT) usage |= VK_IMAGE_USAGE_STORAGE_BIT;
   return usage;
}

static void add_format(struct r4vk_surface_caps *caps, VkSurfaceFormatKHR format,
                      VkImageUsageFlags usage, VkCompositeAlphaFlagsKHR alpha)
{
   if (!(usage & VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT)) return;
   for (uint32_t i = 0; i < caps->format_count; i++) {
      if (caps->formats[i].format == format.format &&
          caps->formats[i].colorSpace == format.colorSpace) {
         caps->alpha[i] |= alpha;
         caps->usage &= usage;
         return;
      }
   }
   const uint32_t i = caps->format_count++;
   assert(i < ARRAY_SIZE(caps->formats));
   caps->formats[i] = format;
   caps->alpha[i] = alpha;
   caps->usage &= usage;
}

static VkCompositeAlphaFlagsKHR native_format(const R4WindowGraphicsFormat *entry,
                                              VkSurfaceFormatKHR *format)
{
   if (entry->reserved) return 0;
   R4GfxColorDescription color;
   memcpy(&color, entry->color, sizeof(color));
   R4GfxColorDescription expected = {
      .version = 1, .size = sizeof(expected), .primaries = R4GFX_COLOR_PRIMARIES_SRGB,
      .transfer = R4GFX_COLOR_TRANSFER_SRGB, .range = R4GFX_COLOR_RANGE_FULL,
      .alpha = color.alpha, .precision = R4GFX_COLOR_PRECISION_UNORM8,
      .reference_white = 1000000, .peak = 1000000,
   };
   uint32_t premultiplied = R4GFX_COLOR_ALPHA_ELECTRICAL;
   bool opaque_format;
   switch (entry->format) {
   case R4OS_GFX_BUFFER_FORMAT_XRGB8888:
   case R4OS_GFX_BUFFER_FORMAT_ARGB8888:
      *format = (VkSurfaceFormatKHR){VK_FORMAT_B8G8R8A8_UNORM, VK_COLOR_SPACE_SRGB_NONLINEAR_KHR};
      opaque_format = entry->format == R4OS_GFX_BUFFER_FORMAT_XRGB8888;
      break;
   case R4OS_GFX_BUFFER_FORMAT_ABGR16161616F:
      *format = (VkSurfaceFormatKHR){VK_FORMAT_R16G16B16A16_SFLOAT, VK_COLOR_SPACE_EXTENDED_SRGB_LINEAR_EXT};
      expected.transfer = R4GFX_COLOR_TRANSFER_LINEAR;
      expected.precision = R4GFX_COLOR_PRECISION_FLOAT16;
      expected.reference_white = 800000;
      expected.peak = 100000000;
      premultiplied = R4GFX_COLOR_ALPHA_OPTICAL;
      opaque_format = color.alpha == R4GFX_COLOR_ALPHA_OPAQUE;
      break;
   case R4OS_GFX_BUFFER_FORMAT_XRGB2101010:
   case R4OS_GFX_BUFFER_FORMAT_ARGB2101010:
      *format = (VkSurfaceFormatKHR){VK_FORMAT_A2R10G10B10_UNORM_PACK32, VK_COLOR_SPACE_HDR10_ST2084_EXT};
      expected.primaries = R4GFX_COLOR_PRIMARIES_BT2020;
      expected.transfer = R4GFX_COLOR_TRANSFER_PQ;
      expected.precision = R4GFX_COLOR_PRECISION_UNORM10;
      expected.reference_white = 2030000;
      expected.peak = 100000000;
      opaque_format = entry->format == R4OS_GFX_BUFFER_FORMAT_XRGB2101010;
      break;
   default: return 0;
   }
   if (memcmp(&expected, &color, sizeof(color))) return 0;
   if (opaque_format && color.alpha == R4GFX_COLOR_ALPHA_OPAQUE)
      return VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
   if (!opaque_format && color.alpha == premultiplied)
      return VK_COMPOSITE_ALPHA_PRE_MULTIPLIED_BIT_KHR;
   return 0;
}

uint32_t r4vk_surface_format(const R4WindowGraphicsConfig *config,
   VkFormat format, VkColorSpaceKHR space, VkCompositeAlphaFlagBitsKHR alpha)
{
   if (!alpha) return UINT32_MAX;
   if (format == VK_FORMAT_B8G8R8A8_SRGB) format = VK_FORMAT_B8G8R8A8_UNORM;
   for (uint32_t i = 0; i < config->format_count; i++) {
      VkSurfaceFormatKHR mapped;
      if (native_format(&config->formats[i], &mapped) == alpha &&
          mapped.format == format && mapped.colorSpace == space) return i;
   }
   return UINT32_MAX;
}

VkResult r4vk_surface_snapshot(struct vk_physical_device *pdev, VkSurfaceKHR handle,
                         struct r4vk_surface_caps *caps)
{
   *caps = (struct r4vk_surface_caps){0};
   struct r4vk_surface *surface = surface_from_handle(handle);
   const struct r4vk_wsi_backend *ops = r4vk_wsi_backend(pdev);
   if (!surface || !ops || surface->instance != ops->instance(pdev)) return VK_ERROR_SURFACE_LOST_KHR;
   R4WindowGraphicsReply reply;
   if (r4vk_window_query(surface->application, surface->identity.window_id,
                        &surface->identity, &reply) != R4OS_WINDOW_GRAPHICS_OK)
      return VK_ERROR_SURFACE_LOST_KHR;
   const R4WindowGraphicsConfig *config = &reply.config;
   const bool software = config->backend.binding.adapter_id == 0;
   const bool headless = config->flags & R4OS_WINDOW_GRAPHICS_HEADLESS;
   const R4GfxOutputId no_output = {0};
   if (config->version != 1 || config->size != sizeof(*config) || !config->revision ||
       !config->width || !config->height || config->reserved ||
       config->format_count > ARRAY_SIZE(config->formats) || !config->format_count ||
       config->min_images < 2 || config->max_images < config->min_images || config->max_images > 3 ||
       !(config->present_modes & R4OS_WINDOW_GRAPHICS_FIFO) ||
       config->present_modes & ~(R4OS_WINDOW_GRAPHICS_FIFO | R4OS_WINDOW_GRAPHICS_MAILBOX) ||
       config->flags & ~(R4OS_WINDOW_GRAPHICS_VISIBLE | R4OS_WINDOW_GRAPHICS_HEADLESS) || !config->display_generation ||
       (headless && (!software || memcmp(&config->output, &no_output, sizeof(no_output)))) ||
       (!headless && (!config->output.connector_id || !config->output.connection_generation ||
                     !config->output.device_generation)) ||
       config->backend.version != 1 || config->backend.size != sizeof(config->backend) ||
       config->backend.binding.version != 1 || config->backend.binding.size != sizeof(config->backend.binding) ||
       !config->backend.binding.device_generation || !config->backend.binding.reset_generation ||
       (software && config->backend.binding.milestone != R4OS_GFX_QUEUE_MILESTONE_CPU_STORES) ||
       (!software && (config->output.adapter_id != config->backend.binding.adapter_id ||
                      config->output.device_generation != config->backend.binding.device_generation)))
      return VK_ERROR_SURFACE_LOST_KHR;
   caps->config = *config;
   R4GfxBackendBinding binding;
   uint64_t generation;
   if (ops->physical(pdev, &binding, &generation) != VK_SUCCESS)
      return VK_ERROR_SURFACE_LOST_KHR;
   if ((!software && (memcmp(&binding, &config->backend.binding, sizeof(binding)) ||
                      generation != config->backend.memory_generation)) ||
       config->width > pdev->properties.maxImageDimension2D ||
       config->height > pdev->properties.maxImageDimension2D)
      return VK_SUCCESS; /* Another adapter/incarnation is not this surface's owner. */

   caps->usage = ~0u;
   for (uint32_t i = 0; i < config->format_count; i++) {
      const R4WindowGraphicsFormat *entry = &config->formats[i];
      if (entry->reserved) continue;
      /* Headless consumers read the original portable BO at its declared
       * precision through the common color compositor. Existing physical
       * software outputs retain their established 8-bit publication. */
      if (software && !headless && entry->format != R4OS_GFX_BUFFER_FORMAT_XRGB8888 &&
          entry->format != R4OS_GFX_BUFFER_FORMAT_ARGB8888) continue;
      /* Only exact, implemented color contracts may be exposed. In
       * particular legacy 100-nit FP16 is not scRGB's absolute 80-nit scale. */
      VkSurfaceFormatKHR mapped;
      const VkCompositeAlphaFlagsKHR alpha = native_format(entry, &mapped);
      if (!alpha || (mapped.colorSpace != VK_COLOR_SPACE_SRGB_NONLINEAR_KHR &&
                     !surface->instance->enabled_extensions.EXT_swapchain_colorspace)) continue;
      add_format(caps, mapped, format_usage(pdev, mapped.format), alpha);
      if (mapped.format == VK_FORMAT_B8G8R8A8_UNORM) {
         mapped.format = VK_FORMAT_B8G8R8A8_SRGB;
         add_format(caps, mapped, format_usage(pdev, mapped.format), alpha);
      }
   }
   caps->common_alpha = ~0u;
   for (uint32_t i = 0; i < caps->format_count; i++) caps->common_alpha &= caps->alpha[i];
   caps->supported = caps->format_count && caps->common_alpha &&
                     (caps->usage & VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT);
   return VK_SUCCESS;
}

VKAPI_ATTR VkResult VKAPI_CALL
nvk_GetPhysicalDeviceSurfaceSupportKHR(VkPhysicalDevice handle, uint32_t family,
   VkSurfaceKHR surface, VkBool32 *supported)
{
   VK_FROM_HANDLE(vk_physical_device, pdev, handle);
   *supported = false;
   struct r4vk_surface_caps caps;
   VkResult result = r4vk_surface_snapshot(pdev, surface, &caps);
   if (result == VK_SUCCESS && r4vk_wsi_backend(pdev) &&
       r4vk_wsi_backend(pdev)->can_present(pdev, family))
      *supported = caps.supported;
   return result;
}

VKAPI_ATTR VkResult VKAPI_CALL
nvk_GetPhysicalDeviceSurfaceCapabilitiesKHR(VkPhysicalDevice handle,
   VkSurfaceKHR surface, VkSurfaceCapabilitiesKHR *out)
{
   VK_FROM_HANDLE(vk_physical_device, pdev, handle);
   struct r4vk_surface_caps caps;
   VkResult result = r4vk_surface_snapshot(pdev, surface, &caps);
   if (result != VK_SUCCESS) return result;
   if (!caps.supported) return VK_ERROR_SURFACE_LOST_KHR;
   VkExtent2D extent = {caps.config.width, caps.config.height};
   *out = (VkSurfaceCapabilitiesKHR) {
      .minImageCount = caps.config.min_images, .maxImageCount = caps.config.max_images,
      .currentExtent = extent, .minImageExtent = extent, .maxImageExtent = extent,
      .maxImageArrayLayers = 1, .supportedTransforms = VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR,
      .currentTransform = VK_SURFACE_TRANSFORM_IDENTITY_BIT_KHR,
      .supportedCompositeAlpha = caps.common_alpha, .supportedUsageFlags = caps.usage,
   };
   return VK_SUCCESS;
}

VKAPI_ATTR VkResult VKAPI_CALL
nvk_GetPhysicalDeviceSurfaceFormatsKHR(VkPhysicalDevice handle,
   VkSurfaceKHR surface, uint32_t *count, VkSurfaceFormatKHR *out)
{
   VK_FROM_HANDLE(vk_physical_device, pdev, handle);
   struct r4vk_surface_caps caps;
   VkResult result = r4vk_surface_snapshot(pdev, surface, &caps);
   if (result != VK_SUCCESS) return result;
   if (!caps.supported) return VK_ERROR_SURFACE_LOST_KHR;
   if (!out) { *count = caps.format_count; return VK_SUCCESS; }
   uint32_t copied = MIN2(*count, caps.format_count);
   memcpy(out, caps.formats, copied * sizeof(*out));
   *count = copied;
   return copied < caps.format_count ? VK_INCOMPLETE : VK_SUCCESS;
}

VKAPI_ATTR VkResult VKAPI_CALL
nvk_GetPhysicalDeviceSurfacePresentModesKHR(VkPhysicalDevice handle,
   VkSurfaceKHR surface, uint32_t *count, VkPresentModeKHR *out)
{
   VK_FROM_HANDLE(vk_physical_device, pdev, handle);
   struct r4vk_surface_caps caps;
   VkResult result = r4vk_surface_snapshot(pdev, surface, &caps);
   if (result != VK_SUCCESS) return result;
   if (!caps.supported) return VK_ERROR_SURFACE_LOST_KHR;
   const VkPresentModeKHR modes[] = {VK_PRESENT_MODE_FIFO_KHR, VK_PRESENT_MODE_MAILBOX_KHR};
   const uint32_t available = caps.config.present_modes & R4OS_WINDOW_GRAPHICS_MAILBOX ? 2 : 1;
   if (!out) { *count = available; return VK_SUCCESS; }
   const uint32_t copied = MIN2(*count, available);
   memcpy(out, modes, copied * sizeof(*out));
   *count = copied;
   return copied < available ? VK_INCOMPLETE : VK_SUCCESS;
}

VKAPI_ATTR VkResult VKAPI_CALL
nvk_GetPhysicalDeviceSurfaceCapabilities2KHR(VkPhysicalDevice handle,
   const VkPhysicalDeviceSurfaceInfo2KHR *info, VkSurfaceCapabilities2KHR *out)
{
   return nvk_GetPhysicalDeviceSurfaceCapabilitiesKHR(handle, info->surface, &out->surfaceCapabilities);
}

VKAPI_ATTR VkResult VKAPI_CALL
nvk_GetPhysicalDeviceSurfaceFormats2KHR(VkPhysicalDevice handle,
   const VkPhysicalDeviceSurfaceInfo2KHR *info, uint32_t *count, VkSurfaceFormat2KHR *out)
{
   /* One snapshot serves both enumeration and copy, including changing size
    * or visibility. Preserve the caller's sType/pNext on each output entry. */
   VK_FROM_HANDLE(vk_physical_device, pdev, handle);
   struct r4vk_surface_caps caps;
   VkResult result = r4vk_surface_snapshot(pdev, info->surface, &caps);
   if (result != VK_SUCCESS) return result;
   if (!caps.supported) return VK_ERROR_SURFACE_LOST_KHR;
   if (!out) { *count = caps.format_count; return VK_SUCCESS; }
   const uint32_t copied = MIN2(*count, caps.format_count);
   for (uint32_t i = 0; i < copied; i++) out[i].surfaceFormat = caps.formats[i];
   *count = copied;
   return copied < caps.format_count ? VK_INCOMPLETE : VK_SUCCESS;
}
