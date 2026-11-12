/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_wsi_backend.h"
#include "r4vk_radv_winsys.h"
#include "radv_device.h"
#include "radv_device_memory.h"
#include "radv_entrypoints.h"
#include "radv_image.h"
#include "radv_physical_device.h"
#include "vk_alloc.h"

static uint32_t pixel_size(uint32_t fourcc, VkFormat format)
{
   switch (fourcc) {
   case R4OS_GFX_BUFFER_FORMAT_XRGB8888:
   case R4OS_GFX_BUFFER_FORMAT_ARGB8888:
      return format == VK_FORMAT_B8G8R8A8_UNORM ||
             format == VK_FORMAT_B8G8R8A8_SRGB ? 4 : 0;
   case R4OS_GFX_BUFFER_FORMAT_XRGB2101010:
   case R4OS_GFX_BUFFER_FORMAT_ARGB2101010:
      return format == VK_FORMAT_A2R10G10B10_UNORM_PACK32 ? 4 : 0;
   case R4OS_GFX_BUFFER_FORMAT_ABGR16161616F:
      return format == VK_FORMAT_R16G16B16A16_SFLOAT ? 8 : 0;
   default:
      return 0;
   }
}

static VkFormatFeatureFlags2 usage_features(VkImageUsageFlags usage)
{
   VkFormatFeatureFlags2 features = 0;
   if (usage & VK_IMAGE_USAGE_TRANSFER_SRC_BIT) features |= VK_FORMAT_FEATURE_2_TRANSFER_SRC_BIT;
   if (usage & VK_IMAGE_USAGE_TRANSFER_DST_BIT) features |= VK_FORMAT_FEATURE_2_TRANSFER_DST_BIT;
   if (usage & VK_IMAGE_USAGE_SAMPLED_BIT) features |= VK_FORMAT_FEATURE_2_SAMPLED_IMAGE_BIT;
   if (usage & VK_IMAGE_USAGE_STORAGE_BIT) features |= VK_FORMAT_FEATURE_2_STORAGE_IMAGE_BIT;
   if (usage & (VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT))
      features |= VK_FORMAT_FEATURE_2_COLOR_ATTACHMENT_BIT;
   return features;
}

static VkResult admit_descriptor(struct radv_physical_device *pdev,
   const R4GfxBufferDescriptor *desc, VkFormat format, VkImageUsageFlags usage,
   VkImageCreateFlags flags, const VkImageFormatListCreateInfo *formats)
{
   const uint32_t bpp = pixel_size(desc->format, format);
   const VkImageUsageFlags allowed = VK_IMAGE_USAGE_TRANSFER_SRC_BIT | VK_IMAGE_USAGE_TRANSFER_DST_BIT |
      VK_IMAGE_USAGE_SAMPLED_BIT | VK_IMAGE_USAGE_STORAGE_BIT | VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT |
      VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT;
   if (!bpp || !usage || (usage & ~allowed)) return VK_ERROR_FORMAT_NOT_SUPPORTED;
   if (flags && flags != (VK_IMAGE_CREATE_MUTABLE_FORMAT_BIT | VK_IMAGE_CREATE_EXTENDED_USAGE_BIT))
      return VK_ERROR_INITIALIZATION_FAILED;
   VkResult result = r4vk_wsi_validate_formats(format,
      flags ? VK_SWAPCHAIN_CREATE_MUTABLE_FORMAT_BIT_KHR : 0, formats);
   if (result != VK_SUCCESS) return result;
   if (desc->modifier || !desc->width || !desc->height || desc->plane_count != 1 || desc->plane_offsets[0] ||
       desc->width > pdev->vk.properties.maxImageDimension2D || desc->height > pdev->vk.properties.maxImageDimension2D ||
       desc->plane_pitches[0] < (uint64_t)desc->width * bpp || desc->plane_pitches[0] > UINT32_MAX ||
       desc->plane_pitches[0] > desc->byte_length / desc->height || (desc->plane_pitches[0] & 255))
      return VK_ERROR_INVALID_EXTERNAL_HANDLE;
   for (unsigned p = 1; p < 4; p++)
      if (desc->plane_offsets[p] || desc->plane_pitches[p]) return VK_ERROR_INVALID_EXTERNAL_HANDLE;
   if ((usage & (VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK_IMAGE_USAGE_STORAGE_BIT)) &&
       !(desc->usage & R4OS_GFX_BUFFER_USAGE_RENDER)) return VK_ERROR_INVALID_EXTERNAL_HANDLE;
   const struct r4vk_wsi_backend *ops = r4vk_wsi_backend(&pdev->vk);
   if (!ops) return VK_ERROR_INITIALIZATION_FAILED;
   VkFormatFeatureFlags2 features = ops->features(&pdev->vk, format);
   if (flags & VK_IMAGE_CREATE_EXTENDED_USAGE_BIT) {
      features = 0;
      for (uint32_t i = 0; i < formats->viewFormatCount; i++)
         features |= ops->features(&pdev->vk, formats->pViewFormats[i]);
   }
   const VkFormatFeatureFlags2 required = usage_features(usage);
   return (features & required) == required ? VK_SUCCESS : VK_ERROR_FORMAT_NOT_SUPPORTED;
}

VkResult r4vk_radv_import_wsi_image(VkDevice device, const R4GfxBufferHandle *source,
   VkFormat format, VkImageUsageFlags usage, VkImageCreateFlags flags,
   const VkImageFormatListCreateInfo *formats, const VkAllocationCallbacks *allocator,
   struct r4vk_wsi_image *out)
{
   if (!device || !out) return VK_ERROR_INITIALIZATION_FAILED;
   VK_FROM_HANDLE(radv_device, dev, device);
   struct radv_physical_device *pdev = radv_device_physical(dev);
   struct r4vk_wsi_image candidate = {0};
   struct radeon_winsys_bo *backing;
   VkResult result = r4vk_radv_import_buffer((struct r4vk_radv_ws *)dev->ws, source,
      &backing, &candidate.descriptor);
   if (result != VK_SUCCESS) return result;
   const R4GfxBufferDescriptor *desc = &candidate.descriptor;
   result = admit_descriptor(pdev, desc, format, usage, flags, formats);
   if (result != VK_SUCCESS) goto fail_backing;
   const VkImageFormatListCreateInfo list = {
      .sType = VK_STRUCTURE_TYPE_IMAGE_FORMAT_LIST_CREATE_INFO,
      .viewFormatCount = formats ? formats->viewFormatCount : 0,
      .pViewFormats = formats ? formats->pViewFormats : NULL,
   };
   const VkSubresourceLayout plane = {.rowPitch = desc->plane_pitches[0]};
   const VkImageDrmFormatModifierExplicitCreateInfoEXT modifier = {
      .sType = VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_EXPLICIT_CREATE_INFO_EXT,
      .pNext = formats ? &list : NULL, .drmFormatModifier = 0,
      .drmFormatModifierPlaneCount = 1, .pPlaneLayouts = &plane,
   };
   const VkImageCreateInfo create = {
      .sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO, .pNext = &modifier, .flags = flags,
      .imageType = VK_IMAGE_TYPE_2D, .format = format, .extent = {desc->width, desc->height, 1},
      .mipLevels = 1, .arrayLayers = 1, .samples = VK_SAMPLE_COUNT_1_BIT,
      .tiling = VK_IMAGE_TILING_DRM_FORMAT_MODIFIER_EXT, .usage = usage,
      .sharingMode = VK_SHARING_MODE_EXCLUSIVE, .initialLayout = VK_IMAGE_LAYOUT_UNDEFINED,
   };
   result = radv_CreateImage(device, &create, allocator, &candidate.image);
   if (result != VK_SUCCESS) goto fail_backing;
   struct radv_image *image = radv_image_from_handle(candidate.image);
   const struct radeon_surf *surface = &image->planes[0].surface;
   if (image->plane_count != 1 || surface->meta_size || surface->cmask_size || surface->fmask_size ||
       surface->u.gfx9.surf_offset || (uint64_t)surface->u.gfx9.surf_pitch * surface->bpe != desc->plane_pitches[0] ||
       image->size > backing->size || surface->surf_size > backing->size) {
      result = VK_ERROR_INVALID_EXTERNAL_HANDLE; goto fail_image;
   }
   const VkImageMemoryRequirementsInfo2 query = {
      .sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_REQUIREMENTS_INFO_2, .image = candidate.image,
   };
   VkMemoryRequirements2 requirements = {.sType = VK_STRUCTURE_TYPE_MEMORY_REQUIREMENTS_2};
   radv_GetImageMemoryRequirements2(device, &query, &requirements);
   uint32_t type = UINT32_MAX;
   for (uint32_t i = 0; i < pdev->memory_properties.memoryTypeCount; i++) {
      if (!(requirements.memoryRequirements.memoryTypeBits & (1u << i))) continue;
      VkMemoryPropertyFlags properties = pdev->memory_properties.memoryTypes[i].propertyFlags;
      bool vram = backing->initial_domain == RADEON_DOMAIN_VRAM;
      if (!!(properties & VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT) != vram) continue;
      if (vram && (properties & VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT)) continue;
      type = i; break;
   }
   if (type == UINT32_MAX || requirements.memoryRequirements.size > backing->size ||
       !requirements.memoryRequirements.alignment || backing->va % requirements.memoryRequirements.alignment) {
      result = VK_ERROR_INVALID_EXTERNAL_HANDLE; goto fail_image;
   }
   struct radv_device_memory *mem = vk_zalloc2(&dev->vk.alloc, allocator, sizeof(*mem),
      8, VK_SYSTEM_ALLOCATION_SCOPE_OBJECT);
   if (!mem) { result = VK_ERROR_OUT_OF_HOST_MEMORY; goto fail_image; }
   const uint32_t heap = pdev->memory_properties.memoryTypes[type].heapIndex;
   if (dev->overallocation_disallowed) {
      mtx_lock(&dev->overallocation_mutex);
      const uint64_t total = pdev->memory_properties.memoryHeaps[heap].size;
      if (backing->size > total || dev->allocated_memory_size[heap] > total - backing->size) {
         mtx_unlock(&dev->overallocation_mutex); vk_free2(&dev->vk.alloc, allocator, mem);
         result = VK_ERROR_OUT_OF_DEVICE_MEMORY; goto fail_image;
      }
      dev->allocated_memory_size[heap] += backing->size;
      mtx_unlock(&dev->overallocation_mutex);
   }
   vk_object_base_init(&dev->vk, &mem->base, VK_OBJECT_TYPE_DEVICE_MEMORY);
   mem->bo = backing; mem->image = image; mem->heap_index = heap; mem->alloc_size = backing->size;
   candidate.memory = radv_device_memory_to_handle(mem);
   const VkBindImageMemoryInfo bind = {
      .sType = VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_INFO, .image = candidate.image, .memory = candidate.memory,
   };
   result = radv_BindImageMemory2(device, 1, &bind);
   if (result == VK_SUCCESS) result = r4vk_radv_validate((struct r4vk_radv_ws *)dev->ws);
   if (result != VK_SUCCESS) { r4vk_radv_finish_wsi_image(device, allocator, &candidate); return result; }
   *out = candidate;
   return VK_SUCCESS;
fail_image:
   radv_DestroyImage(device, candidate.image, allocator);
fail_backing:
   dev->ws->buffer_destroy(dev->ws, backing);
   return result;
}
void r4vk_radv_finish_wsi_image(VkDevice device, const VkAllocationCallbacks *allocator,
   struct r4vk_wsi_image *image)
{
   if (!image) return;
   radv_DestroyImage(device, image->image, allocator);
   radv_FreeMemory(device, image->memory, allocator);
   *image = (struct r4vk_wsi_image){0};
}
