/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VK_NVK_WSI_IMAGE_H
#define R4VK_NVK_WSI_IMAGE_H
#include "r4vk_wsi_image.h"
VkResult r4vk_nvk_import_wsi_image(VkDevice device,
                                  const R4GfxBufferHandle *source,
                                  VkFormat format, VkImageUsageFlags usage,
                                  VkImageCreateFlags flags,
                                  const VkImageFormatListCreateInfo *formats,
                                  const VkAllocationCallbacks *allocator,
                                  struct r4vk_wsi_image *out);
void r4vk_nvk_finish_wsi_image(VkDevice device,
                              const VkAllocationCallbacks *allocator,
                              struct r4vk_wsi_image *image);
VkResult r4vk_nvk_wsi_acquired(VkDevice device, struct r4vk_wsi_image *image,
                               bool acquired);
#endif
