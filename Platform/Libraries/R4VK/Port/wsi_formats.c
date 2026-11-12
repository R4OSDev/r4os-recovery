/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_wsi_image.h"
#include "vk_format_info.h"

VkResult r4vk_wsi_validate_formats(VkFormat base, VkSwapchainCreateFlagsKHR flags,
                                  const VkImageFormatListCreateInfo *formats)
{
   if (flags & ~VK_SWAPCHAIN_CREATE_MUTABLE_FORMAT_BIT_KHR)
      return VK_ERROR_INITIALIZATION_FAILED;
   const bool mutable = flags & VK_SWAPCHAIN_CREATE_MUTABLE_FORMAT_BIT_KHR;
   const uint32_t count = formats ? formats->viewFormatCount : 0;
   if ((mutable && !count) || (!mutable && count > 1) ||
       (count && !formats->pViewFormats))
      return VK_ERROR_INITIALIZATION_FAILED;
   /* base has already passed native surface/descriptor admission. Compare
    * against its finite class without indexing tables with a foreign enum. */
   const struct vk_format_class_info *class = vk_format_get_class_info(base);
   bool has_base = false;
   for (uint32_t i = 0; i < count; i++) {
      const VkFormat view = formats->pViewFormats[i];
      bool compatible = false;
      for (uint32_t j = 0; j < class->format_count; j++)
         compatible |= view == class->formats[j];
      if (!compatible) return VK_ERROR_FORMAT_NOT_SUPPORTED;
      has_base |= view == base;
   }
   return mutable && !has_base ? VK_ERROR_INITIALIZATION_FAILED : VK_SUCCESS;
}

bool r4vk_wsi_equal_formats(const VkImageFormatListCreateInfo *a,
                            const VkImageFormatListCreateInfo *b)
{
   const uint32_t ac = a ? a->viewFormatCount : 0;
   const uint32_t bc = b ? b->viewFormatCount : 0;
   if (!ac || !bc) return ac == bc;
   if (!a->pViewFormats || !b->pViewFormats) return false;
   /* The allowed format set, independent of order or duplicate entries. */
   for (unsigned side = 0; side < 2; side++) {
      const VkImageFormatListCreateInfo *from = side ? b : a;
      const VkImageFormatListCreateInfo *to = side ? a : b;
      for (uint32_t i = 0; i < from->viewFormatCount; i++) {
         bool found = false;
         for (uint32_t j = 0; j < to->viewFormatCount; j++)
            found |= from->pViewFormats[i] == to->pViewFormats[j];
         if (!found) return false;
      }
   }
   return true;
}
