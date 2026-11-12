/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VK_WSI_H
#define R4VK_WSI_H
#include <r4os/r4l.h>
#include <vulkan/vulkan_core.h>

/* Private R4VK entrypoint, obtained from its instance-proc loader with a
 * live instance that enabled VK_KHR_surface. This is not a registered
 * Vulkan extension and allocates no VkStructureType or extension number.
 * application is the calling program's actual Start1 or Start2 context.
 * Creation admits and snapshots it in process-owned native storage; its
 * import/name backing remains resident for the process. window_id comes from the
 * normal Desktop API. WINSVC authenticates the calling process generation.
 * VK_NOT_READY means Desktop has not published a compatible window yet.
 * Destroy a successful result with vkDestroySurfaceKHR. */
#define R4VK_WINDOW_SURFACE_ENTRYPOINT "r4vkCreateWindowSurface"
#define R4VK_WINDOW_SURFACE_VERSION 1u
typedef struct R4VkWindowSurfaceCreateInfo {
    uint32_t version;
    uint32_t size;
    const void *application;
    uint32_t window_id;
    uint32_t reserved;
} R4VkWindowSurfaceCreateInfo;
typedef VkResult (VKAPI_PTR *PFN_r4vkCreateWindowSurface)(
    VkInstance instance, const R4VkWindowSurfaceCreateInfo *info,
    const VkAllocationCallbacks *allocator, VkSurfaceKHR *surface);

/* Private companion entrypoint from the same live instance resolver. Wait for
 * all already-posted frames in this swapchain to leave WINSVC's producer queue.
 * Consumer-held images may remain live; this is not a scanout/VBlank wait.
 * The caller externally synchronizes the swapchain and keeps it/device alive.
 * Zero timeout polls (VK_NOT_READY); a finite elapsed timeout returns VK_TIMEOUT.
 * Neither timeout cancels frames, retires the chain nor changes its policy. */
#define R4VK_WINDOW_DRAIN_ENTRYPOINT "r4vkDrainWindowSwapchain"
typedef VkResult (VKAPI_PTR *PFN_r4vkDrainWindowSwapchain)(
    VkDevice device, VkSwapchainKHR swapchain, uint64_t timeout_ns);

#endif
