/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VK_RADV_WINSYS_H
#define R4VK_RADV_WINSYS_H
#include "r4vk_radv.h"
#include "radv_radeon_winsys.h"
#include "util/list.h"
#include "util/simple_mtx.h"
#include "util/u_atomic.h"
#include "vk_sync.h"
struct r4vk_radv_point;
struct r4vk_radv_ws {
   struct radeon_winsys base;
   uint32_t references, lost;
   R4Draw draw;
   R4Dev devices;
   struct r4vk_radv_architecture facts;
   simple_mtx_t residency_mutex, submit_mutex, slab_mutex;
   struct list_head residency;
   struct r4vk_radv_point *submission_tail;
   uint64_t allocated[2], next_id;
};
struct r4vk_radv_bo {
   struct radeon_winsys_bo base;
   uint32_t references;
   struct r4vk_radv_ws *ws;
   struct list_head residency;
   R4GfxBufferReference reference;
   R4GfxBufferHandle range, binding;
   R4GfxBufferMap mapping;
   simple_mtx_t mutex;
   uint32_t map_count;
   /* Only roots own broker resources and residency. Children retain one
    * disjoint, padded byte extent; their VA and CPU map include this offset. */
   struct r4vk_radv_bo *parent;
   uint64_t offset;
   uint64_t *slab_bitmap;
   uint32_t slab_children;
   uint32_t submissions;
   struct r4vk_radv_bo *retired_children, *retired_next;
   bool slab_retiring;
   struct radeon_bo_metadata metadata;
};
struct radeon_winsys_ctx {
   uint32_t references;
   struct r4vk_radv_ws *resources;
   R4GfxBackendBinding backend;
   R4GfxQueueHandle queue;
   struct r4vk_radv_point *pending;
};
struct r4vk_radv_cs {
   struct ac_cmdbuf base;
   struct r4vk_radv_ws *ws;
   enum amd_ip_type engine;
   VkResult result;
   struct r4vk_radv_bo *buffer;
};
int r4vk_operation_deadline(uint64_t, uint64_t *, uint64_t *);
int r4vk_wait_ticks(uint64_t, uint64_t *);
int r4vk_monotonic_time(uint64_t *);
static inline bool r4vk_radv_is_lost(const struct r4vk_radv_ws *ws) { return p_atomic_read(&ws->lost) != 0; }
static inline VkResult r4vk_radv_lost(struct r4vk_radv_ws *ws) { p_atomic_set(&ws->lost, 1); return VK_ERROR_DEVICE_LOST; }
void r4vk_radv_ws_ref(struct r4vk_radv_ws *);
void r4vk_radv_ws_unref(struct r4vk_radv_ws *);
void r4vk_radv_submit_finish(struct r4vk_radv_ws *);
void r4vk_radv_command_init(struct radeon_winsys *);
void r4vk_radv_queue_init(struct radeon_winsys *);
VkResult r4vk_radv_validate(struct r4vk_radv_ws *);
VkResult r4vk_radv_status(struct r4vk_radv_ws *, int32_t);
bool r4vk_radv_buffer_try_ref(struct radeon_winsys_bo *);
void r4vk_radv_buffer_release_submission(struct radeon_winsys_bo *);
void r4vk_radv_point_ref(struct r4vk_radv_point *);
void r4vk_radv_point_unref(struct r4vk_radv_point *);
VkResult r4vk_radv_point_wait(struct r4vk_radv_point *, uint64_t);
VkResult r4vk_radv_point_export(struct r4vk_radv_point *, R4GfxFence *);
void r4vk_radv_point_unexport(struct r4vk_radv_point *);
VkResult r4vk_radv_point_pin(struct r4vk_radv_point *, R4GfxFence *);
bool r4vk_radv_sync_supported(const struct vk_sync *, uint64_t);
VkResult r4vk_radv_sync_point(struct vk_sync *, struct r4vk_radv_ws *, struct r4vk_radv_point **);
VkResult r4vk_radv_sync_assign(struct vk_sync *, struct r4vk_radv_point *);
VkResult r4vk_radv_sync_prepare_present(struct vk_sync *);
VkResult r4vk_radv_sync_take_present(struct vk_sync *, struct r4vk_radv_point **, R4GfxFence *);
VkResult r4vk_radv_import_buffer(struct r4vk_radv_ws *, const R4GfxBufferHandle *,
   struct radeon_winsys_bo **, R4GfxBufferDescriptor *);
#endif
