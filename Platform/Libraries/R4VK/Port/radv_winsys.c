/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_radv_winsys.h"
void r4vk_radv_memory_init(struct radeon_winsys *);
void r4vk_radv_ws_ref(struct r4vk_radv_ws *ws) { p_atomic_inc(&ws->references); }
void r4vk_radv_ws_unref(struct r4vk_radv_ws *ws)
{
   if (!p_atomic_dec_zero(&ws->references)) return;
   assert(list_is_empty(&ws->residency) && !ws->submission_tail);
   simple_mtx_destroy(&ws->slab_mutex); simple_mtx_destroy(&ws->submit_mutex); simple_mtx_destroy(&ws->residency_mutex); free(ws);
}
VkResult r4vk_radv_validate(struct r4vk_radv_ws *ws)
{
   if (r4vk_radv_is_lost(ws)) return VK_ERROR_DEVICE_LOST;
   struct r4vk_radv_architecture current;
   if (r4vk_radv_query_architecture(&ws->draw, &ws->devices, &ws->facts.backend, &current) != VK_SUCCESS ||
       !r4vk_radv_same_facts(&current, &ws->facts)) return r4vk_radv_lost(ws);
   return VK_SUCCESS;
}
static void destroy(struct radeon_winsys *base)
{
   struct r4vk_radv_ws *ws = (struct r4vk_radv_ws *)base;
   r4vk_radv_submit_finish(ws); r4vk_radv_ws_unref(ws);
}
static uint64_t query(struct radeon_winsys *base, enum radeon_value_id id)
{
   struct r4vk_radv_ws *ws = (struct r4vk_radv_ws *)base;
   uint64_t result = 0;
   if (id == RADEON_ALLOCATED_GTT || id == RADEON_ALLOCATED_VRAM) {
      simple_mtx_lock(&ws->residency_mutex); result = ws->allocated[id == RADEON_ALLOCATED_VRAM]; simple_mtx_unlock(&ws->residency_mutex);
   } else if (id == RADEON_VRAM_USAGE) {
      R4GfxDeviceBudgetRequest request = { .version = 1, .size = sizeof(request),
         .adapter_id = ws->facts.backend.binding.adapter_id, .memory_generation = ws->facts.backend.memory_generation };
      R4GfxDeviceBudgetState state;
      if (r4draw_gfx_memory_budget(&ws->draw, &request, &state) == 1 && state.version == 1 && state.size >= sizeof(state) &&
          state.adapter_id == request.adapter_id && state.memory_generation == request.memory_generation && state.charged_bytes <= state.limit_bytes)
         result = state.charged_bytes;
   }
   /* Unsupported telemetry never feeds an advertised feature. In particular
    * there is no fabricated GPU timestamp, temperature or clock frequency. */
   return result;
}
static bool registers(struct radeon_winsys *ws, unsigned off, unsigned count, uint32_t *out)
{ (void)ws; (void)off; (void)count; (void)out; return false; }
static bool fault(struct radeon_winsys *ws, struct radv_winsys_gpuvm_fault_info *out)
{ (void)ws; (void)out; return false; }
static int fd(struct radeon_winsys *ws) { (void)ws; return -1; }
static struct util_sync_provider *sync_provider(struct radeon_winsys *ws) { (void)ws; return NULL; }
static int reserve(struct radeon_winsys *ws) { (void)ws; return -1; }
static void unreserve(struct radeon_winsys *ws) { (void)ws; }
static void dump(struct radeon_winsys *ws, FILE *file) { (void)ws; (void)file; }
static bool idle(struct radeon_winsys *base, struct radeon_winsys_bo *bo)
{
   struct r4vk_radv_ws *ws = (struct r4vk_radv_ws *)base;
   if (((struct r4vk_radv_bo *)bo)->ws != ws) return false;
   simple_mtx_lock(&ws->submit_mutex);
   struct r4vk_radv_point *tail = ws->submission_tail; r4vk_radv_point_ref(tail);
   simple_mtx_unlock(&ws->submit_mutex);
   VkResult result = tail ? r4vk_radv_point_wait(tail, UINT64_MAX) : r4vk_radv_validate(ws);
   r4vk_radv_point_unref(tail); return result == VK_SUCCESS;
}
VkResult r4vk_radv_create_winsys(const R4Draw *draw, const R4Dev *devices,
   const struct r4vk_radv_architecture *facts, struct radeon_winsys **out)
{
   if (!r4draw_available(draw) || !devices || !facts || !out) return VK_ERROR_INITIALIZATION_FAILED;
   if (!R4DRAW_HAS(draw, gfx_buffer_create) || !R4DRAW_HAS(draw, gfx_buffer_describe) || !R4DRAW_HAS(draw, gfx_buffer_release) || !R4DRAW_HAS(draw, gfx_buffer_map_persistent) || !R4DRAW_HAS(draw, gfx_buffer_unmap) ||
       !R4DRAW_HAS(draw, gfx_native_start) || !R4DRAW_HAS(draw, gfx_native_wait) || !R4DRAW_HAS(draw, gfx_native_receive) || !R4DRAW_HAS(draw, gfx_native_close) ||
       !R4DRAW_HAS(draw, gfx_virtual_start) || !R4DRAW_HAS(draw, gfx_virtual_wait) || !R4DRAW_HAS(draw, gfx_virtual_close) ||
       !R4DRAW_HAS(draw, gfx_queue_open) || !R4DRAW_HAS(draw, gfx_queue_close) || !R4DRAW_HAS(draw, gfx_queue_submit_native) || !R4DRAW_HAS(draw, gfx_fence_wait) || !R4DRAW_HAS(draw, gfx_fence_release))
      return VK_ERROR_FEATURE_NOT_PRESENT;
   struct r4vk_radv_ws *ws = calloc(1, sizeof(*ws));
   if (!ws) return VK_ERROR_OUT_OF_HOST_MEMORY;
   ws->references = 1; ws->draw = *draw; ws->devices = *devices; ws->facts = *facts;
   list_inithead(&ws->residency); simple_mtx_init(&ws->residency_mutex, mtx_plain); simple_mtx_init(&ws->submit_mutex, mtx_plain); simple_mtx_init(&ws->slab_mutex, mtx_plain);
   ws->base.destroy = destroy; ws->base.query_value = query; ws->base.read_registers = registers; ws->base.query_gpuvm_fault = fault;
   ws->base.get_fd = fd; ws->base.get_sync_provider = sync_provider; ws->base.reserve_vmid = reserve; ws->base.unreserve_vmid = unreserve;
   ws->base.dump_bo_ranges = ws->base.dump_bo_log = dump; ws->base.bo_wait_for_idle = idle;
   r4vk_radv_memory_init(&ws->base); r4vk_radv_command_init(&ws->base); r4vk_radv_queue_init(&ws->base);
   VkResult result = r4vk_radv_validate(ws);
   if (result != VK_SUCCESS) { destroy(&ws->base); return result; }
   *out = &ws->base; return VK_SUCCESS;
}
