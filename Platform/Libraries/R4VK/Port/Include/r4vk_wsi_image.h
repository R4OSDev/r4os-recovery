/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VK_WSI_IMAGE_H
#define R4VK_WSI_IMAGE_H
#include <stdbool.h>
#include <r4os/r4draw.h>
#include <vulkan/vulkan_core.h>
/* Private WSI-owned image/memory pair. Native backing is retained, never
 * copied or reinitialized by import. Destroy image before memory after use. */
struct r4vk_wsi_image {
   VkImage image;
   VkDeviceMemory memory;
   R4GfxBufferDescriptor descriptor;
};
VkResult r4vk_wsi_validate_formats(VkFormat, VkSwapchainCreateFlagsKHR,
   const VkImageFormatListCreateInfo *);
bool r4vk_wsi_equal_formats(const VkImageFormatListCreateInfo *, const VkImageFormatListCreateInfo *);
#endif
