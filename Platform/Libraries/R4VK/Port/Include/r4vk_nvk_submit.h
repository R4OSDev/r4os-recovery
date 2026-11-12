/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VK_NVK_SUBMIT_H
#define R4VK_NVK_SUBMIT_H
#include "r4vk_nvk_va.h"
#include "vk_sync.h"

struct r4vk_nvk_point;
extern const struct vk_sync_type r4vk_nvk_sync_type;
VkResult r4vk_nvk_create_ctx(struct r4vk_nvk_va_context *resources,
                            const R4GfxBackendBinding *backend,
                            enum nvkmd_engines engines, struct nvkmd_ctx **out);
/* Break the device's retained tail ownership before its public ref is closed.
 * Existing contexts/syncs and resident jobs keep their independent owners. */
void r4vk_nvk_submit_finish(struct r4vk_nvk_va_context *resources);

/* Shared immutable fence identity, independently retained by queues and sync
 * objects. Completion is cached only after the common GPU fence says so.
 * Export pins the kernel handle until unexport, even if another CPU waiter
 * observes completion meanwhile. No caller address is retained by a driver. */
void r4vk_nvk_point_ref(struct r4vk_nvk_point *point);
void r4vk_nvk_point_unref(struct r4vk_nvk_point *point);
VkResult r4vk_nvk_point_wait(struct r4vk_nvk_point *point, uint64_t abs_timeout_ns);
VkResult r4vk_nvk_point_export(struct r4vk_nvk_point *point, R4GfxFence *out);
void r4vk_nvk_point_unexport(struct r4vk_nvk_point *point);
VkResult r4vk_nvk_point_pin(struct r4vk_nvk_point *point, R4GfxFence *out);
bool r4vk_nvk_sync_supported(const struct vk_sync *sync, uint64_t value);
VkResult r4vk_nvk_sync_point(struct vk_sync *sync,
                            struct r4vk_nvk_va_context *resources,
                            struct r4vk_nvk_point **out);
VkResult r4vk_nvk_sync_assign(struct vk_sync *sync, struct r4vk_nvk_point *point);
VkResult r4vk_nvk_sync_prepare_present(struct vk_sync *sync);
VkResult r4vk_nvk_sync_take_present(struct vk_sync *sync,
   struct r4vk_nvk_point **out, R4GfxFence *fence);
#endif
