/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VK_NVK_MEM_H
#define R4VK_NVK_MEM_H
#include "r4vk_nvk_va.h"

/* Private per-device memory owner. Both contexts outlive every NVK memory
 * object. host_coherent is an explicit backend capability, never inferred
 * from successful CPU mapping or a modeled completion. */
struct r4vk_nvk_mem_context {
   struct r4vk_nvk_va_context *resources;
   bool host_coherent;
};
VkResult r4vk_nvk_mem_context_init(struct r4vk_nvk_mem_context *context,
                                  struct r4vk_nvk_va_context *resources,
                                  bool host_coherent);
VkResult r4vk_nvk_alloc_mem(struct r4vk_nvk_mem_context *context,
                           struct vk_object_base *log_obj,
                           uint64_t size_B, uint64_t align_B,
                           enum nvkmd_mem_flags flags,
                           struct nvkmd_mem **out);
VkResult r4vk_nvk_alloc_tiled_mem(struct r4vk_nvk_mem_context *context,
                                 struct vk_object_base *log_obj,
                                 uint64_t size_B, uint64_t align_B,
                                 uint8_t pte_kind, uint16_t tile_mode,
                                 enum nvkmd_mem_flags flags,
                                 struct nvkmd_mem **out);
/* Backend half of the private canonical-BO import. Like alloc_mem, the
 * successful result still needs publication in the device's memory list. */
VkResult r4vk_nvk_import_mem(struct r4vk_nvk_mem_context *context,
                            struct vk_object_base *log_obj,
                            const R4GfxBufferHandle *source,
                            struct nvkmd_mem **out,
                            R4GfxBufferDescriptor *descriptor);
VkResult r4vk_nvk_mem_reference(struct nvkmd_mem *mem,
                               R4GfxBufferReference *out);
/* Private WSI ownership. The shared window owner supplies the actual
 * acquire/handoff proof; the memory owner updates all canonical VA aliases. */
VkResult r4vk_nvk_mem_wsi_acquired(struct nvkmd_mem *mem, bool acquired);
/* Caller holds this memory's resources->residency_mutex. */
uint32_t r4vk_nvk_mem_access(struct nvkmd_mem *mem);
#endif
