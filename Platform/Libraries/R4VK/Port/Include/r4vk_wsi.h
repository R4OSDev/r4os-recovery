/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VK_NATIVE_WSI_H
#define R4VK_NATIVE_WSI_H
#include <stdbool.h>
#include "../../Bindings/C/r4vk_wsi.h"
#include <r4os/r4draw.h>
struct vk_instance;
struct vk_physical_device;
struct r4vk_surface {
   struct vk_instance *instance;
   uint64_t application;
   R4WindowGraphicsSurface identity;
};
struct r4vk_surface_caps {
   R4WindowGraphicsConfig config;
   uint32_t format_count;
   VkSurfaceFormatKHR formats[16];
   VkCompositeAlphaFlagsKHR alpha[16];
   VkImageUsageFlags usage;
   VkCompositeAlphaFlagsKHR common_alpha;
   bool supported;
};
VkResult r4vk_surface_snapshot(struct vk_physical_device *pdev,
   VkSurfaceKHR surface, struct r4vk_surface_caps *caps);
uint32_t r4vk_surface_format(const R4WindowGraphicsConfig *config,
   VkFormat format, VkColorSpaceKHR space, VkCompositeAlphaFlagBitsKHR alpha);
VkResult r4vk_create_swapchain_alias(VkDevice device, const VkImageCreateInfo *info,
   const VkAllocationCallbacks *allocator, VkImage *out);
VkDeviceMemory r4vk_swapchain_memory(VkDevice device, VkSwapchainKHR chain, uint32_t index);
bool r4vk_application_snapshot(const void *application, uint64_t *snapshot);
int32_t r4vk_window_query(uint64_t application, uint32_t window_id,
   const R4WindowGraphicsSurface *expected, R4WindowGraphicsReply *reply);
/* true means a complete, validated response (possibly a business error).
 * false leaves the outcome unknown; retry the exact immutable request. */
bool r4vk_window_request(uint64_t application,
   const R4WindowGraphicsRequest *request, R4WindowGraphicsReply *reply);
bool r4vk_window_service_dead(uint64_t application,
   const R4ProgramProcessHandle *service);
void r4vk_window_wait(uint64_t application,
   const R4ProgramProcessHandle *owner, uint64_t revision, uint64_t duration_ns);
VKAPI_ATTR VkResult VKAPI_CALL r4vkCreateWindowSurface(VkInstance instance,
   const R4VkWindowSurfaceCreateInfo *info, const VkAllocationCallbacks *allocator,
   VkSurfaceKHR *surface);
VKAPI_ATTR VkResult VKAPI_CALL r4vkDrainWindowSwapchain(VkDevice device,
   VkSwapchainKHR swapchain, uint64_t timeout_ns);
#endif
