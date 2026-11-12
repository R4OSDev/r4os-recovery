/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_radv_winsys.h"
#include "vk_device.h"
/* Internal CPU-only recorder; disabled unless the process opts in. */
void r4vk_pm4_trace(uint32_t, uint32_t, uint32_t, uint32_t, uint64_t, const uint32_t *, uint32_t);
static void ctx_unref(struct radeon_winsys_ctx *);
struct r4vk_radv_point {
   uint32_t references;
   simple_mtx_t mutex;
   struct r4vk_radv_ws *resources;
   struct radeon_winsys_ctx *queue_owner;
   struct radeon_winsys_bo *buffers[32];
   uint32_t buffer_count;
   R4GfxFence fence;
   uint32_t exports;
   VkResult result;
   bool complete;
   bool signal_pending; /* Signal owners may reserve completed metadata. */
   struct r4vk_radv_point *next; /* One context's in-flight collection ref. */
};
static VkResult lost(struct r4vk_radv_ws *resources)
{
   p_atomic_set(&resources->lost, 1);
   return VK_ERROR_DEVICE_LOST;
}
static bool fence_equal(R4GfxFence a, R4GfxFence b)
{
   return a.slot == b.slot && a.adapter_id == b.adapter_id &&
      a.timeline == b.timeline && a.point == b.point &&
      a.device_generation == b.device_generation && a.reset_generation == b.reset_generation;
}
static bool fence_valid(R4GfxFence fence, const struct radeon_winsys_ctx *ctx)
{
   return fence.slot && fence.point && fence.timeline == ctx->queue.timeline &&
      fence.adapter_id == ctx->backend.adapter_id &&
      fence.device_generation == ctx->backend.device_generation &&
      fence.reset_generation == ctx->backend.reset_generation;
}
static bool status_valid(const R4GfxFenceStatus *value, R4GfxFence fence)
{
   return value->version == 1 && value->size >= sizeof(*value) &&
      fence_equal(value->fence, fence) &&
      value->milestone == R4OS_GFX_QUEUE_MILESTONE_DEVICE_EXECUTION &&
      value->phase <= R4OS_GFX_QUEUE_PHASE_TERMINAL &&
      !(value->flags & ~(R4OS_GFX_QUEUE_FLAG_DEVICE_ACTIVE | R4OS_GFX_QUEUE_FLAG_RESOURCES_HELD)) &&
      ((value->phase == R4OS_GFX_QUEUE_PHASE_TERMINAL &&
         value->result >= R4OS_GFX_QUEUE_RESULT_COMPLETE && value->result <= R4OS_GFX_QUEUE_RESULT_DEPENDENCY_FAILED) ||
       (value->phase != R4OS_GFX_QUEUE_PHASE_TERMINAL && value->result == R4OS_GFX_QUEUE_RESULT_PENDING));
}
/* point->mutex held; wait/dependency exports protect a copied kernel handle. */
static void release_fence(struct r4vk_radv_point *point)
{
   if (!point->complete || point->exports || point->signal_pending || !point->fence.slot) return;
   if (r4draw_gfx_fence_release(&point->resources->draw, &point->fence) != R4OS_GFX_QUEUE_OK)
      point->result = lost(point->resources);
   point->fence.slot = 0;
}
void r4vk_radv_point_ref(struct r4vk_radv_point *point)
{
   if (point) p_atomic_inc(&point->references);
}
static void release_buffers(struct r4vk_radv_point *point)
{
   struct radeon_winsys_bo *buffers[32];
   simple_mtx_lock(&point->mutex);
   const uint32_t count = point->buffer_count;
   memcpy(buffers, point->buffers, count * sizeof(buffers[0]));
   point->buffer_count = 0;
   simple_mtx_unlock(&point->mutex);
   /* Pool mutations and broker retirement never span the point mutex. */
   for (uint32_t i = 0; i < count; i++)
      r4vk_radv_buffer_release_submission(buffers[i]);
}
void r4vk_radv_point_unref(struct r4vk_radv_point *point)
{
   if (!point || !p_atomic_dec_zero(&point->references)) return;
   assert(!point->exports);
   /* Dropping a pending fence does not assert completion. The common owner
    * retains its job, canonical bindings and backing until actual retirement. */
   if (point->fence.slot &&
       r4draw_gfx_fence_release(&point->resources->draw, &point->fence) != R4OS_GFX_QUEUE_OK)
      lost(point->resources);
   struct r4vk_radv_ws *resources = point->resources;
   struct radeon_winsys_ctx *queue_owner = point->queue_owner;
   release_buffers(point);
   simple_mtx_destroy(&point->mutex);
   free(point);
   ctx_unref(queue_owner);
   r4vk_radv_ws_unref(resources);
}
VkResult r4vk_radv_point_wait(struct r4vk_radv_point *point, uint64_t until)
{
   simple_mtx_lock(&point->mutex);
   if (point->complete) {
      VkResult result = point->result;
      simple_mtx_unlock(&point->mutex);
      release_buffers(point);
      return result;
   }
   R4GfxFence fence = point->fence;
   point->exports++;
   simple_mtx_unlock(&point->mutex);
   uint64_t ticks;
   R4GfxFenceStatus status;
   VkResult result;
   if (r4vk_wait_ticks(until, &ticks) != 0) {
      result = lost(point->resources);
   } else {
      const int32_t rc = r4draw_gfx_fence_wait(&point->resources->draw, &fence,
         ticks, R4OS_GFX_QUEUE_WAIT_COMPLETION, &status);
      if (rc == R4OS_GFX_QUEUE_ERROR_WAIT_TIMEOUT) result = VK_TIMEOUT;
      else if (rc != R4OS_GFX_QUEUE_OK || !status_valid(&status, fence))
         result = lost(point->resources);
      else if (status.phase != R4OS_GFX_QUEUE_PHASE_TERMINAL) result = VK_TIMEOUT;
      else if (status.result != R4OS_GFX_QUEUE_RESULT_COMPLETE)
         result = lost(point->resources);
      else result = VK_SUCCESS;
   }
   simple_mtx_lock(&point->mutex);
   if (result != VK_TIMEOUT && !point->complete) {
      point->result = result;
      point->complete = true;
   }
   assert(point->exports); point->exports--;
   release_fence(point);
   if (point->complete) result = point->result;
   simple_mtx_unlock(&point->mutex);
   if (result != VK_TIMEOUT) release_buffers(point);
   return result;
}
VkResult r4vk_radv_point_export(struct r4vk_radv_point *point, R4GfxFence *out)
{
   VkResult result = r4vk_radv_point_wait(point, 0);
   if (result != VK_TIMEOUT) return result;
   simple_mtx_lock(&point->mutex);
   if (point->complete) result = point->result;
   else { point->exports++; *out = point->fence; result = VK_NOT_READY; }
   simple_mtx_unlock(&point->mutex);
   return result; /* NOT_READY means a pinned, not-yet-completed dependency. */
}
void r4vk_radv_point_unexport(struct r4vk_radv_point *point)
{
   simple_mtx_lock(&point->mutex);
   assert(point->exports); point->exports--;
   release_fence(point);
   simple_mtx_unlock(&point->mutex);
}
/* WSI signal assignment runs before signal_pending is cleared. Unlike a
 * queue dependency, a presentation receipt still needs completed metadata. */
VkResult r4vk_radv_point_pin(struct r4vk_radv_point *point, R4GfxFence *out)
{
   simple_mtx_lock(&point->mutex);
   VkResult result = VK_SUCCESS;
   if (!point->fence.slot || (point->complete && point->result != VK_SUCCESS))
      result = VK_ERROR_DEVICE_LOST;
   else {
      point->exports++;
      if (out) *out = point->fence;
   }
   simple_mtx_unlock(&point->mutex);
   return result;
}
static void publish_signals(struct r4vk_radv_point *point)
{
   if (!point) return;
   simple_mtx_lock(&point->mutex);
   point->signal_pending = false;
   release_fence(point);
   simple_mtx_unlock(&point->mutex);
}
void r4vk_radv_submit_finish(struct r4vk_radv_ws *resources)
{
   simple_mtx_lock(&resources->submit_mutex);
   struct r4vk_radv_point *tail = resources->submission_tail;
   resources->submission_tail = NULL;
   simple_mtx_unlock(&resources->submit_mutex);
   r4vk_radv_point_unref(tail);
}
static void ctx_unref(struct radeon_winsys_ctx *ctx)
{
   if (!p_atomic_dec_zero(&ctx->references)) return;
   if (r4draw_gfx_queue_close(&ctx->resources->draw, &ctx->queue) != R4OS_GFX_QUEUE_OK) lost(ctx->resources);
   struct r4vk_radv_ws *ws = ctx->resources;
   free(ctx); r4vk_radv_ws_unref(ws);
}
static void destroy_ctx(struct radeon_winsys_ctx *ctx)
{
   while (ctx->pending) {
      struct r4vk_radv_point *point = ctx->pending;
      /* Queue teardown must not return pooled command bytes while another
       * context could still allocate from this winsys. Uncertain completion
       * poisons it; the kernel continues retaining native execution loans. */
      if (r4vk_radv_point_wait(point, UINT64_MAX) != VK_SUCCESS) lost(ctx->resources);
      ctx->pending = point->next; r4vk_radv_point_unref(point);
   }
   ctx_unref(ctx);
}
static VkResult reap(struct radeon_winsys_ctx *ctx)
{
   struct r4vk_radv_point **link = &ctx->pending;
   while (*link) {
      VkResult result = r4vk_radv_point_wait(*link, 0);
      if (result == VK_TIMEOUT) { link = &(*link)->next; continue; }
      struct r4vk_radv_point *point = *link; *link = point->next;
      r4vk_radv_point_unref(point);
      if (result != VK_SUCCESS) return result;
   }
   return r4vk_radv_validate(ctx->resources);
}
static VkResult create_ctx(struct radeon_winsys *base, enum radeon_ctx_priority priority, struct radeon_winsys_ctx **out)
{
   struct r4vk_radv_ws *ws = (struct r4vk_radv_ws *)base;
   if (priority != RADEON_CTX_PRIORITY_MEDIUM) return VK_ERROR_NOT_PERMITTED;
   VkResult result = r4vk_radv_validate(ws);
   if (result != VK_SUCCESS) return result;
   struct radeon_winsys_ctx *ctx = calloc(1, sizeof(*ctx));
   if (!ctx) return VK_ERROR_OUT_OF_HOST_MEMORY;
   ctx->references = 1; ctx->resources = ws; ctx->backend = ws->facts.backend.binding;
   R4GfxQueueConfig config = { .version = 1, .size = sizeof(config), .adapter_id = ctx->backend.adapter_id,
      .policy = R4OS_GFX_QUEUE_POLICY_FIFO, .capacity = R4OS_GFX_QUEUE_FENCE_CAPACITY,
      .milestone = R4OS_GFX_QUEUE_MILESTONE_DEVICE_EXECUTION,
      .device_generation = ctx->backend.device_generation, .reset_generation = ctx->backend.reset_generation };
   int32_t rc = r4draw_gfx_queue_open(&ws->draw, &config, &ctx->queue);
   if (rc != R4OS_GFX_QUEUE_OK) {
      free(ctx);
      return rc == R4OS_GFX_QUEUE_ERROR_OOM || rc == R4OS_GFX_QUEUE_ERROR_CAPACITY ? VK_ERROR_OUT_OF_HOST_MEMORY : lost(ws);
   }
   r4vk_radv_ws_ref(ws);
   if (ctx->queue.version != 1 || ctx->queue.size < sizeof(ctx->queue) || !ctx->queue.timeline) { ctx_unref(ctx); return lost(ws); }
   *out = ctx; return VK_SUCCESS;
}
static bool wait_idle(struct radeon_winsys_ctx *ctx, enum amd_ip_type engine, int index)
{
   if ((engine != AMD_IP_GFX && engine != AMD_IP_COMPUTE) || index) return false;
   for (struct r4vk_radv_point *p = ctx->pending; p; p = p->next)
      if (r4vk_radv_point_wait(p, UINT64_MAX) != VK_SUCCESS) return false;
   return reap(ctx) == VK_SUCCESS;
}
static int pstate(struct radeon_winsys_ctx *ctx, uint32_t value)
{ return value == RADEON_CTX_PSTATE_NONE && !r4vk_radv_is_lost(ctx->resources) ? 0 : -1; }
static VkResult submit(struct radeon_winsys_ctx *ctx, const struct radv_winsys_submit_info *info,
   uint32_t wait_count, const struct vk_sync_wait *waits, uint32_t signal_count, const struct vk_sync_signal *signals)
{
   struct r4vk_radv_ws *ws = ctx->resources;
   if (!info || info->secure || info->uses_shadow_regs || info->queue_index ||
       (info->ip_type != AMD_IP_GFX && info->ip_type != AMD_IP_COMPUTE)) return VK_ERROR_FEATURE_NOT_PRESENT;
   uint64_t total = (uint64_t)info->cs_count + info->initial_preamble_count + info->postamble_count;
   if (total > 32) return VK_ERROR_OUT_OF_DEVICE_MEMORY;
   for (uint32_t i = 0; i < wait_count; i++) if (!r4vk_radv_sync_supported(waits[i].sync, waits[i].wait_value)) return VK_ERROR_FEATURE_NOT_PRESENT;
   for (uint32_t i = 0; i < signal_count; i++) if (!r4vk_radv_sync_supported(signals[i].sync, signals[i].signal_value)) return VK_ERROR_FEATURE_NOT_PRESENT;
   VkResult result = reap(ctx);
   if (result != VK_SUCCESS) return result;
   struct ac_cmdbuf *empty = NULL;
   struct r4vk_radv_cs *streams[32];
   uint32_t count = 0;
   for (uint32_t group = 0; group < 3; group++) {
      uint32_t n = group == 0 ? info->initial_preamble_count : group == 1 ? info->cs_count : info->postamble_count;
      struct ac_cmdbuf **array = group == 0 ? info->initial_preamble_cs : group == 1 ? info->cs_array : info->postamble_cs;
      if (n && !array) return VK_ERROR_UNKNOWN;
      for (uint32_t i = 0; i < n; i++) {
         struct r4vk_radv_cs *cs = container_of(array[i], struct r4vk_radv_cs, base);
         if (cs->ws != ws || cs->engine != info->ip_type) return VK_ERROR_FEATURE_NOT_PRESENT;
         result = ws->base.cs_finalize(array[i]);
         if (result != VK_SUCCESS) return result;
         streams[count++] = cs;
      }
   }
   if (!count) {
      empty = ws->base.cs_create(&ws->base, info->ip_type, false);
      if (!empty) return VK_ERROR_OUT_OF_HOST_MEMORY;
      result = ws->base.cs_finalize(empty);
      if (result != VK_SUCCESS) { ws->base.cs_destroy(empty); return result; }
      streams[count++] = container_of(empty, struct r4vk_radv_cs, base);
   }
   struct r4vk_radv_point *dependencies[R4OS_GFX_QUEUE_MAX_DEPENDENCIES - 1];
   /* Finalized immutable CPU streams, in their exact submission order.
    * Diagnostic I/O runs outside submit/residency owners and before the
    * device deadline starts. No device registers are accessed here. */
   for (uint32_t i = 0; i < count; i++) {
      const uint32_t group = empty ? 3 : i < info->initial_preamble_count ? 0 :
         i < info->initial_preamble_count + info->cs_count ? 1 : 2;
      r4vk_pm4_trace(info->ip_type == AMD_IP_COMPUTE, group, i, count,
         streams[i]->buffer->base.va, streams[i]->base.buf, streams[i]->base.cdw);
   }
   R4GfxFence fences[R4OS_GFX_QUEUE_MAX_DEPENDENCIES - 1];
   uint32_t dep_count = 0;
   for (uint32_t i = 0; i < wait_count; i++) {
      struct r4vk_radv_point *point = NULL;
      result = r4vk_radv_sync_point(waits[i].sync, ws, &point);
      if (result != VK_SUCCESS) goto done;
      if (!point) continue;
      if (point->resources != ws) { r4vk_radv_point_unref(point); result = VK_ERROR_UNKNOWN; goto done; }
      if (dep_count == ARRAY_SIZE(dependencies)) {
         result = r4vk_radv_point_wait(point, UINT64_MAX); r4vk_radv_point_unref(point);
         if (result != VK_SUCCESS) goto done;
         continue;
      }
      R4GfxFence fence;
      result = r4vk_radv_point_export(point, &fence);
      if (result == VK_NOT_READY) { dependencies[dep_count] = point; fences[dep_count++] = fence; }
      else { r4vk_radv_point_unref(point); if (result != VK_SUCCESS) goto done; }
   }
   struct r4vk_radv_point *point = calloc(1, sizeof(*point));
   if (!point) { result = VK_ERROR_OUT_OF_HOST_MEMORY; goto done; }
   point->references = 1; point->resources = ws; point->queue_owner = ctx; point->signal_pending = true;
   simple_mtx_init(&point->mutex, mtx_plain); r4vk_radv_ws_ref(ws); p_atomic_inc(&ctx->references);
   R4GfxSubmission submission = { .version = 1, .size = sizeof(submission), .operation = R4OS_GFX_QUEUE_OPERATION_NATIVE };
   uint64_t ticks;
   if (r4vk_operation_deadline(2000000000ull, &submission.deadline_ns, &ticks)) { result = lost(ws); goto fail_point; }
   for (;;) {
      struct r4vk_radv_point *previous = NULL;
      bool exported = false;
      simple_mtx_lock(&ws->submit_mutex);
      previous = ws->submission_tail;
      submission.dependency_count = 0;
      if (previous) {
         result = r4vk_radv_point_export(previous, &submission.dependencies[0]);
         if (result == VK_NOT_READY) { exported = true; submission.dependency_count++; }
         else if (result != VK_SUCCESS) { simple_mtx_unlock(&ws->submit_mutex); goto fail_point; }
      }
      for (uint32_t i = 0; i < dep_count; i++) {
         bool duplicate = false;
         for (uint32_t j = 0; j < submission.dependency_count; j++) duplicate |= fence_equal(fences[i], submission.dependencies[j]);
         if (!duplicate) submission.dependencies[submission.dependency_count++] = fences[i];
      }
      struct { R4AmdNativeSubmit header; R4AmdNativeIb ibs[32]; } packet = {
         .header = { .version = 1, .size = sizeof(R4AmdNativeSubmit), .engine = info->ip_type == AMD_IP_COMPUTE, .ib_count = count } };
      R4GfxNativeResource resources[32];
      R4GfxFenceStatus accepted;
      simple_mtx_lock(&ws->residency_mutex);
      uint32_t num_resources = 0;
      result = VK_SUCCESS;
      list_for_each_entry(struct r4vk_radv_bo, bo, &ws->residency, residency) {
         if (num_resources == ARRAY_SIZE(resources)) { result = VK_ERROR_OUT_OF_DEVICE_MEMORY; break; }
         if (!r4vk_radv_buffer_try_ref(&bo->base)) continue;
         assert(!bo->parent && bo->submissions < UINT32_MAX);
         bo->submissions++;
         point->buffers[point->buffer_count++] = &bo->base;
         resources[num_resources++] = (R4GfxNativeResource){ .version = 1, .size = sizeof(R4GfxNativeResource), .binding = bo->binding, .access = 1 };
      }
      for (uint32_t i = 0; result == VK_SUCCESS && i < count; i++) {
         struct r4vk_radv_cs *cs = streams[i];
         uint32_t binding = 0;
         for (; binding < num_resources; binding++) if (resources[binding].binding.id == cs->buffer->binding.id && resources[binding].binding.generation == cs->buffer->binding.generation) break;
         if (binding == num_resources) { result = lost(ws); break; }
         packet.ibs[i] = (R4AmdNativeIb){ .address = cs->buffer->base.va, .dwords = cs->base.cdw, .binding_index = binding };
      }
      if (result == VK_SUCCESS) {
         R4GfxNativeSubmission native = { .version = 1, .size = sizeof(native),
            .interface_id_lo = R4AMD_BACKEND_V1_INTERFACE_ID_LO, .interface_id_hi = R4AMD_BACKEND_V1_INTERFACE_ID_HI,
            .revision = 1, .command_bytes = sizeof(packet.header) + count * sizeof(packet.ibs[0]), .commands = (uintptr_t)&packet,
            .resource_count = num_resources, .resources = (uintptr_t)resources };
         int32_t rc = r4draw_gfx_queue_submit_native(&ws->draw, &ctx->queue, &submission, &native, &accepted);
         result = rc == R4OS_GFX_QUEUE_OK ? VK_SUCCESS :
            rc == R4OS_GFX_QUEUE_ERROR_BUSY || rc == R4OS_GFX_QUEUE_ERROR_CAPACITY ? VK_NOT_READY : r4vk_radv_status(ws, rc);
      }
      simple_mtx_unlock(&ws->residency_mutex);
      if (exported) r4vk_radv_point_unexport(previous);
      if (result == VK_SUCCESS) {
         if (!fence_valid(accepted.fence, ctx) || !status_valid(&accepted, accepted.fence)) {
            /* A malformed reply may still contain our valid public handle.
             * Close it; resident execution loans remain with the broker. */
            if (fence_valid(accepted.fence, ctx))
               r4draw_gfx_fence_release(&ws->draw, &accepted.fence);
            result = lost(ws);
         }
         else {
            point->fence = accepted.fence;
            r4vk_radv_point_ref(point); ws->submission_tail = point;
         }
      }
      if (previous) r4vk_radv_point_ref(previous);
      simple_mtx_unlock(&ws->submit_mutex);
      if (result != VK_SUCCESS) release_buffers(point);
      if (result == VK_SUCCESS) r4vk_radv_point_unref(previous); /* Former tail ownership. */
      if (result == VK_NOT_READY && previous && exported) result = r4vk_radv_point_wait(previous, submission.deadline_ns);
      else if (result == VK_NOT_READY) result = VK_ERROR_OUT_OF_DEVICE_MEMORY;
      r4vk_radv_point_unref(previous);
      if (result != VK_SUCCESS) goto fail_point;
      if (point->fence.slot) break;
      uint64_t now;
      if (r4vk_monotonic_time(&now) || now >= submission.deadline_ns) { result = lost(ws); goto fail_point; }
   }
   point->next = ctx->pending; ctx->pending = point;
   for (uint32_t i = 0; i < signal_count; i++) {
      result = r4vk_radv_sync_assign(signals[i].sync, point);
      if (result != VK_SUCCESS) { result = lost(ws); break; }
   }
   publish_signals(point);
   goto done;
fail_point:
   r4vk_radv_point_unref(point);
done:
   for (uint32_t i = 0; i < dep_count; i++) { r4vk_radv_point_unexport(dependencies[i]); r4vk_radv_point_unref(dependencies[i]); }
   if (empty) ws->base.cs_destroy(empty);
   return result;
}
/* Empty public submissions are issued through cs_submit and get a real NOP
 * fence. This payload helper is used only for already-resolved sync copies. */
static VkResult copy_payloads(struct vk_device *device, uint32_t count, const struct vk_sync_wait *waits,
   uint32_t signal_count, const struct vk_sync_signal *signals)
{
   for (uint32_t i = 0; i < signal_count; i++) if (!r4vk_radv_sync_supported(signals[i].sync, signals[i].signal_value)) return VK_ERROR_FEATURE_NOT_PRESENT;
   VkResult result = vk_sync_wait_many(device, count, waits, 0, UINT64_MAX);
   if (result != VK_SUCCESS) return result;
   for (uint32_t i = 0; i < signal_count; i++) {
      result = vk_sync_signal(device, signals[i].sync, signals[i].signal_value);
      if (result != VK_SUCCESS) return result;
   }
   return VK_SUCCESS;
}
void r4vk_radv_queue_init(struct radeon_winsys *ws)
{
   ws->ctx_create = create_ctx; ws->ctx_destroy = destroy_ctx; ws->ctx_wait_idle = wait_idle;
   ws->ctx_set_pstate = pstate; ws->cs_submit = submit; ws->copy_sync_payloads = copy_payloads;
}
