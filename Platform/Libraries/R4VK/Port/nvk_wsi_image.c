/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_nvk_wsi_image.h"
#include "r4vk_nvk_device.h"
#include "r4vk_nvk_mem.h"
#include "nvk_device.h"
#include "nvk_device_memory.h"
#include "nvk_entrypoints.h"
#include "nvk_format.h"
#include "nvk_image.h"
#include "nvk_physical_device.h"

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

static VkResult admit_descriptor(const struct nvk_physical_device *pdev,
                                 const R4GfxBufferDescriptor *desc,
                                 VkFormat format, VkImageUsageFlags usage,
                                 VkImageCreateFlags flags,
                                 const VkImageFormatListCreateInfo *formats)
{
   const uint32_t bpp = pixel_size(desc->format, format);
   const VkImageUsageFlags allowed = VK_IMAGE_USAGE_TRANSFER_SRC_BIT |
      VK_IMAGE_USAGE_TRANSFER_DST_BIT | VK_IMAGE_USAGE_SAMPLED_BIT |
      VK_IMAGE_USAGE_STORAGE_BIT | VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT |
      VK_IMAGE_USAGE_INPUT_ATTACHMENT_BIT;
   if (!bpp || !usage || (usage & ~allowed)) return VK_ERROR_FORMAT_NOT_SUPPORTED;
   const VkImageCreateFlags mutable_flags = VK_IMAGE_CREATE_MUTABLE_FORMAT_BIT |
      VK_IMAGE_CREATE_EXTENDED_USAGE_BIT;
   if (flags && flags != mutable_flags) return VK_ERROR_INITIALIZATION_FAILED;
   VkResult result = r4vk_wsi_validate_formats(format,
      flags ? VK_SWAPCHAIN_CREATE_MUTABLE_FORMAT_BIT_KHR : 0, formats);
   if (result != VK_SUCCESS) return result;
   if (!desc->width || !desc->height || desc->plane_count != 1 || desc->plane_offsets[0] ||
       desc->width > pdev->vk.properties.maxImageDimension2D ||
       desc->height > pdev->vk.properties.maxImageDimension2D ||
       desc->plane_pitches[0] < (uint64_t)desc->width * bpp ||
       desc->plane_pitches[0] > UINT32_MAX ||
       desc->plane_pitches[0] > desc->byte_length / desc->height)
      return VK_ERROR_INVALID_EXTERNAL_HANDLE;
   for (unsigned p = 1; p < 4; p++)
      if (desc->plane_offsets[p] || desc->plane_pitches[p]) return VK_ERROR_INVALID_EXTERNAL_HANDLE;
   if ((usage & (VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT | VK_IMAGE_USAGE_STORAGE_BIT)) &&
       !(desc->usage & R4OS_GFX_BUFFER_USAGE_RENDER)) return VK_ERROR_INVALID_EXTERNAL_HANDLE;
   if (!desc->modifier && (desc->plane_pitches[0] & 31)) return VK_ERROR_INVALID_EXTERNAL_HANDLE;

   /* These are NVK's existing modifier and format predicates. Public DRM
    * extension queries remain disabled; a private image is not FD support. */
   const struct nil_format layout_format = nil_format(nvk_format_to_pipe_format(format));
   if (nil_select_best_drm_format_mod(&pdev->info, layout_format, 1, &desc->modifier) != desc->modifier)
      return VK_ERROR_FORMAT_NOT_SUPPORTED;
   VkFormatFeatureFlags2 features = nvk_get_image_format_features(pdev,
      format, VK_IMAGE_TILING_DRM_FORMAT_MODIFIER_EXT, desc->modifier);
   if (flags & VK_IMAGE_CREATE_EXTENDED_USAGE_BIT) {
      /* An allowed view may supply usage absent from the base format, e.g.
       * storage on a linear UNORM view of an sRGB image. */
      features = 0;
      for (uint32_t i = 0; i < formats->viewFormatCount; i++)
         features |= nvk_get_image_format_features(pdev, formats->pViewFormats[i],
            VK_IMAGE_TILING_DRM_FORMAT_MODIFIER_EXT, desc->modifier);
   }
   const VkFormatFeatureFlags2 required = usage_features(usage);
   if ((features & required) != required) return VK_ERROR_FORMAT_NOT_SUPPORTED;
   return VK_SUCCESS;
}

static uint32_t memory_type(const struct nvk_physical_device *pdev,
                            const struct nvkmd_mem *mem, uint32_t type_bits)
{
   for (uint32_t i = 0; i < pdev->mem_type_count; i++) {
      if (!(type_bits & BITFIELD_BIT(i))) continue;
      const VkMemoryPropertyFlags flags = pdev->mem_types[i].propertyFlags;
      if (!!(flags & VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT) != !!(mem->flags & NVKMD_MEM_VRAM)) continue;
      if ((flags & VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT) && !(mem->flags & NVKMD_MEM_CAN_MAP)) continue;
      if ((flags & VK_MEMORY_PROPERTY_HOST_COHERENT_BIT) && !(mem->flags & NVKMD_MEM_COHERENT)) continue;
      return i;
   }
   return UINT32_MAX;
}

VkResult r4vk_nvk_import_wsi_image(VkDevice device,
                                  const R4GfxBufferHandle *source,
                                  VkFormat format, VkImageUsageFlags usage,
                                  VkImageCreateFlags flags,
                                  const VkImageFormatListCreateInfo *formats,
                                  const VkAllocationCallbacks *allocator,
                                  struct r4vk_wsi_image *out)
{
   if (!device || !out) return VK_ERROR_INITIALIZATION_FAILED;
   VK_FROM_HANDLE(nvk_device, dev, device);
   struct nvk_physical_device *pdev = nvk_device_physical_mut(dev);
   struct r4vk_wsi_image candidate = {0};
   struct nvkmd_mem *backing;
   VkResult result = r4vk_nvk_import_buffer(dev->nvkmd, &dev->vk.base,
      source, &backing, &candidate.descriptor);
   if (result != VK_SUCCESS) return result;
   const R4GfxBufferDescriptor *desc = &candidate.descriptor;
   result = admit_descriptor(pdev, desc, format, usage, flags, formats);
   if (result != VK_SUCCESS) goto fail_backing;

   VkImageFormatListCreateInfo list = {
      .sType = VK_STRUCTURE_TYPE_IMAGE_FORMAT_LIST_CREATE_INFO,
      .viewFormatCount = formats ? formats->viewFormatCount : 0,
      .pViewFormats = formats ? formats->pViewFormats : NULL,
   };
   const VkSubresourceLayout plane = {.rowPitch = desc->plane_pitches[0]};
   const VkImageDrmFormatModifierExplicitCreateInfoEXT modifier = {
      .sType = VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_EXPLICIT_CREATE_INFO_EXT,
      .pNext = formats ? &list : NULL,
      .drmFormatModifier = desc->modifier, .drmFormatModifierPlaneCount = 1,
      .pPlaneLayouts = &plane,
   };
   const VkImageCreateInfo create = {
      .sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO, .pNext = &modifier, .flags = flags,
      .imageType = VK_IMAGE_TYPE_2D, .format = format,
      .extent = {desc->width, desc->height, 1}, .mipLevels = 1, .arrayLayers = 1,
      .samples = VK_SAMPLE_COUNT_1_BIT, .tiling = VK_IMAGE_TILING_DRM_FORMAT_MODIFIER_EXT,
      .usage = usage, .sharingMode = VK_SHARING_MODE_EXCLUSIVE,
      .initialLayout = VK_IMAGE_LAYOUT_UNDEFINED,
   };
   result = nvk_CreateImage(device, &create, allocator, &candidate.image);
   if (result != VK_SUCCESS) goto fail_backing;
   struct nvk_image *image = nvk_image_from_handle(candidate.image);
   const struct nvk_image_plane *actual = &image->planes[0];
   if (image->plane_count != 1 || actual->plane_offset_B ||
       actual->nil.levels[0].row_stride_B != desc->plane_pitches[0] ||
       image->image_size_B > backing->size_B || actual->nil.size_B > backing->size_B) {
      result = VK_ERROR_INVALID_EXTERNAL_HANDLE;
      goto fail_image;
   }
   const VkImageMemoryRequirementsInfo2 query = {
      .sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_REQUIREMENTS_INFO_2, .image = candidate.image,
   };
   VkMemoryRequirements2 requirements = {.sType = VK_STRUCTURE_TYPE_MEMORY_REQUIREMENTS_2};
   nvk_GetImageMemoryRequirements2(device, &query, &requirements);
   const uint32_t type = memory_type(pdev, backing, requirements.memoryRequirements.memoryTypeBits);
   if (type == UINT32_MAX || requirements.memoryRequirements.size > backing->size_B ||
       !requirements.memoryRequirements.alignment ||
       backing->va->addr % requirements.memoryRequirements.alignment) {
      result = VK_ERROR_INVALID_EXTERNAL_HANDLE;
      goto fail_image;
   }
   const VkMemoryAllocateInfo allocation = {
      .sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
      .allocationSize = backing->size_B, .memoryTypeIndex = type,
   };
   struct nvk_device_memory *mem = vk_device_memory_create(&dev->vk,
      &allocation, allocator, sizeof(*mem));
   if (!mem) { result = VK_ERROR_OUT_OF_HOST_MEMORY; goto fail_image; }
   mem->mem = backing;
   mem->dedicated_image = image;
   /* Match ordinary NVK FreeMemory accounting; only the wrapper is new,
    * never another GPU allocation or a reinitialization of shared pixels. */
   p_atomic_add(&pdev->mem_heaps[pdev->mem_types[type].heapIndex].used, backing->size_B);
   candidate.memory = nvk_device_memory_to_handle(mem);
   const VkBindImageMemoryInfo bind = {
      .sType = VK_STRUCTURE_TYPE_BIND_IMAGE_MEMORY_INFO,
      .image = candidate.image, .memory = candidate.memory,
   };
   result = nvk_BindImageMemory2(device, 1, &bind);
   if (result == VK_SUCCESS) result = r4vk_nvk_check_device(dev->nvkmd);
   if (result == VK_SUCCESS) result = r4vk_nvk_mem_wsi_acquired(backing, false);
   if (result != VK_SUCCESS) {
      r4vk_nvk_finish_wsi_image(device, allocator, &candidate);
      return result;
   }
   *out = candidate;
   return VK_SUCCESS;
fail_image:
   nvk_DestroyImage(device, candidate.image, allocator);
fail_backing:
   nvkmd_mem_unref(backing);
   return result;
}

void r4vk_nvk_finish_wsi_image(VkDevice device,
                              const VkAllocationCallbacks *allocator,
                              struct r4vk_wsi_image *image)
{
   if (!image) return;
   nvk_DestroyImage(device, image->image, allocator);
   nvk_FreeMemory(device, image->memory, allocator);
   *image = (struct r4vk_wsi_image){0};
}

VkResult r4vk_nvk_wsi_acquired(VkDevice device, struct r4vk_wsi_image *image,
                               bool acquired)
{
   if (!device || !image || !image->memory) return VK_ERROR_INITIALIZATION_FAILED;
   VK_FROM_HANDLE(nvk_device, dev, device);
   struct nvk_device_memory *mem = nvk_device_memory_from_handle(image->memory);
   if (mem->mem->dev != dev->nvkmd) return VK_ERROR_INVALID_EXTERNAL_HANDLE;
   VkResult result = r4vk_nvk_check_device(dev->nvkmd);
   if (result != VK_SUCCESS) return result;
   return r4vk_nvk_mem_wsi_acquired(mem->mem, acquired);
}
