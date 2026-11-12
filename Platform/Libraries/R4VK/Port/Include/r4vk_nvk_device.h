/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VK_NVK_DEVICE_H
#define R4VK_NVK_DEVICE_H
#include "nvkmd/nvkmd.h"
#include <r4os/r4draw.h>
#include <vulkan/vulkan_core.h>

/* Hardware description only. The eventual pdev/queue builder must separately
 * admit implemented execution, synchronization and image-layout operations.
 * No API version, queue family, Vulkan feature or conformance claim is made. */
struct r4vk_nvk_architecture {
   struct nv_device_info info;
   R4GfxBackendBinding binding;
   uint64_t memory_generation, va_start, va_end;
   uint32_t bind_alignment;
   bool host_coherent;
   bool image_layouts;
};
VkResult r4vk_nvk_query_architecture(const R4Draw *draw,
                                    const R4GfxBackendInfo *backend,
                                    struct r4vk_nvk_architecture *out);

/* Private NVKMD resource device. The caller supplies an exact enumerated
 * backend; no DRM device, file descriptor or second RM owner is created.
 * This is not VkPhysicalDevice/VkDevice admission: native execution and sync
 * adapters exist, but public feature/limit and provider integration is separate.
 * Failed creation preserves *out. Each device retains its pdev, and its
 * memory/VA children retain the device through their final C destruction. */
VkResult r4vk_nvk_create_pdev(const R4Draw *draw,
                             const R4GfxBackendInfo *backend,
                             enum nvk_debug debug_flags,
                             struct nvkmd_pdev **out);
VkResult r4vk_nvk_check_device(struct nvkmd_dev *dev);
/* Private WSI building block, not a Vulkan extension or FD import. Takes
 * an independent mutable reference; the source reference stays owned by
 * its caller. Outputs change only on success. Descriptor geometry and
 * modifier are preserved, not reinterpreted as a compatible Vulkan image.
 * Image-layout and presentation admission remain the WSI owner's work. */
VkResult r4vk_nvk_import_buffer(struct nvkmd_dev *dev,
                               struct vk_object_base *log_obj,
                               const R4GfxBufferHandle *source,
                               struct nvkmd_mem **out,
                               R4GfxBufferDescriptor *descriptor);
VkResult r4vk_nvk_query_pdev_architecture(struct nvkmd_pdev *pdev,
                                         struct r4vk_nvk_architecture *out);
#endif
