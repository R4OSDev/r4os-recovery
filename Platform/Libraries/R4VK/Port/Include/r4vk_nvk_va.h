/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VK_NVK_VA_H
#define R4VK_NVK_VA_H

#include "nvkmd/nvkmd.h"
#include <r4os/r4draw.h>

struct r4vk_nvk_point;
/* Private NVK adapter, not a public library ABI. One context belongs to one
 * nvkmd_dev and outlives its VA objects. The memory owner supplies a borrowed
 * canonical reference; the kernel obtains its own loan before start returns.
 * Initialization receives actual backend bounds and retains them separately.
 * dev->va_start/end then describe NVK's usable subset of that exact backend.
 * No Linux FD or RM token crosses this interface. */
struct r4vk_nvk_va_context {
   struct nvkmd_dev *dev;
   R4Draw draw;
   uint32_t adapter_id;
   uint64_t memory_generation;
   uint64_t backend_va_start, backend_va_end;
   bool image_layouts; /* Explicit revision3 backend + R4DRAW36 admission. */
   uint32_t lost; /* atomic, shared by this device's resource calls */
   /* All live bindings in this device, including aliases whose original BO
    * was destroyed. Serialize only binding publication/removal and the
    * resident broker's nonblocking submit snapshot, never a GPU wait. */
   simple_mtx_t residency_mutex;
   struct list_head residency;
   /* Indirect GPU addressing currently requires a conservative all-binding
    * snapshot. Chain native queues on this device to avoid false unordered
    * writer conflicts. This retained tail is dropped at logical device close;
    * never hold submit_mutex across a GPU wait. */
   simple_mtx_t submit_mutex;
   struct r4vk_nvk_point *submission_tail;
   VkResult (*reference)(struct nvkmd_mem *mem, R4GfxBufferReference *out);
   /* Optional memory-owner policy, read only under residency_mutex while
    * publishing a binding. Ordinary BOs remain conservative writers. WSI
    * images handed to the consumer retain read loans until reacquired. */
   uint32_t (*access)(struct nvkmd_mem *mem);
   /* Optional paired private owner hooks. Set before allocating children;
    * each successful memory/VA object holds one reference until destruction.
    * Standalone caller-owned contexts leave both NULL. */
   void (*retain)(struct r4vk_nvk_va_context *context);
   void (*release)(struct r4vk_nvk_va_context *context);
};

static inline void
r4vk_nvk_resources_ref(struct r4vk_nvk_va_context *context)
{
   assert((context->retain == NULL) == (context->release == NULL));
   if (context->retain) context->retain(context);
}
static inline void
r4vk_nvk_resources_unref(struct r4vk_nvk_va_context *context)
{
   if (context->release) context->release(context);
}

VkResult r4vk_nvk_va_context_init(struct r4vk_nvk_va_context *context,
                                 struct nvkmd_dev *dev, const R4Draw *draw,
                                 uint32_t adapter, uint64_t generation,
                                 VkResult (*reference)(struct nvkmd_mem *,
                                                       R4GfxBufferReference *));
bool r4vk_nvk_va_device_lost(const struct r4vk_nvk_va_context *context);
/* Caller holds residency_mutex. Update every alias of this exact canonical
 * BO; no binding is omitted from the execution lifetime snapshot. */
void r4vk_nvk_va_access_locked(struct r4vk_nvk_va_context *context,
                               R4GfxBufferHandle buffer, uint32_t access);
void r4vk_nvk_va_context_finish(struct r4vk_nvk_va_context *context);
VkResult r4vk_nvk_va_submit(struct r4vk_nvk_va_context *context,
                           bool retain_bindings,
                           const R4GfxQueueHandle *queue,
                           const R4GfxSubmission *submission,
                           const R4GfxNativeSubmission *native,
                           R4GfxFenceStatus *out);
VkResult r4vk_nvk_alloc_va(struct r4vk_nvk_va_context *context,
                          struct vk_object_base *log_obj,
                          enum nvkmd_va_flags flags, uint8_t pte_kind,
                          uint64_t size_B, uint64_t align_B,
                          uint64_t fixed_addr, struct nvkmd_va **out);

#endif
