/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VK_WSI_BACKEND_H
#define R4VK_WSI_BACKEND_H
#include "r4vk_wsi_image.h"
#include "vk_device.h"
#include "vk_physical_device.h"
struct vk_image;
struct vk_sync;
/* Private provider boundary. Each point stays paired with its immutable
 * operations after VkDevice/Swapchain destruction; no foreign Mesa layout
 * crosses into the common window transport. */
struct r4vk_wsi_backend {
   struct vk_instance *(*instance)(struct vk_physical_device *);
   VkResult (*physical)(struct vk_physical_device *, R4GfxBackendBinding *, uint64_t *);
   VkFormatFeatureFlags2 (*features)(struct vk_physical_device *, VkFormat);
   bool (*can_present)(struct vk_physical_device *, uint32_t);
   VkResult (*check)(struct vk_device *);
   VkResult (*import)(VkDevice, const R4GfxBufferHandle *, VkFormat, VkImageUsageFlags,
      VkImageCreateFlags, const VkImageFormatListCreateInfo *, const VkAllocationCallbacks *, struct r4vk_wsi_image *);
   void (*finish)(VkDevice, const VkAllocationCallbacks *, struct r4vk_wsi_image *);
   /* Optional provider policy after a confirmed acquire and before handing
    * already-submitted pixels to the consumer. All execution loans remain. */
   VkResult (*acquired)(VkDevice, struct r4vk_wsi_image *, bool);
   const struct vk_image *(*image)(VkImage);
   VkResult (*create_image)(VkDevice, const VkImageCreateInfo *, const VkAllocationCallbacks *, VkImage *);
   VkResult (*prepare)(struct vk_sync *);
   VkResult (*take)(struct vk_sync *, void **, R4GfxFence *);
   VkResult (*pin)(void *, R4GfxFence *);
   void (*ref)(void *);
   void (*unref)(void *);
   void (*unpin)(void *);
};
const struct r4vk_wsi_backend *r4vk_wsi_backend(struct vk_physical_device *);
VkResult r4vk_radv_import_wsi_image(VkDevice, const R4GfxBufferHandle *, VkFormat, VkImageUsageFlags,
   VkImageCreateFlags, const VkImageFormatListCreateInfo *, const VkAllocationCallbacks *, struct r4vk_wsi_image *);
void r4vk_radv_finish_wsi_image(VkDevice, const VkAllocationCallbacks *, struct r4vk_wsi_image *);
extern const struct vk_device_entrypoint_table r4vk_wsi_device_entrypoints;
extern const struct vk_physical_device_entrypoint_table r4vk_wsi_physical_entrypoints;
#endif
