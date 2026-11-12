/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_nvk_submit.h"
#include "r4vk_nvk_device.h"
#include "vk_sync_timeline.h"
#include "vk_object.h"
#include "r4vk_state.h"
#include <r4nv.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

int r4vk_operation_deadline(uint64_t, uint64_t *, uint64_t *);
int r4vk_wait_ticks(uint64_t, uint64_t *);
int r4vk_monotonic_time(uint64_t *);
bool r4vk_device_startup_trace_enabled(void);
void r4vk_device_startup_trace(const char *);

/* Caller-owned, disabled-by-default timing. Emit only outside the resource
 * and point owners; observing a duration never supplies a GPU receipt. */
static uint64_t trace_begin(void)
{
   uint64_t now;
   return r4vk_device_startup_trace_enabled() &&
      r4vk_monotonic_time(&now) == 0 ? now : 0;
}
static void trace_end(const char *stage, uint64_t begin, uint64_t timeline,
                       uint64_t detail, VkResult result, bool slow_only)
{
   uint64_t now;
   if (!begin || r4vk_monotonic_time(&now) != 0 || now < begin ||
       (slow_only && now - begin < 1000000)) return;
   char line[240];
   snprintf(line, sizeof(line),
      "R4VK SUBMIT stage=%s elapsed-ns=%llu timeline=%llu detail=%llu result=%d",
      stage, (unsigned long long)(now - begin),
      (unsigned long long)timeline, (unsigned long long)detail, result);
   r4vk_device_startup_trace(line);
}

struct native_ctx;
static void ctx_unref(struct native_ctx *ctx);
struct r4vk_nvk_point {
   uint32_t references;
   simple_mtx_t mutex;
   struct r4vk_nvk_va_context *resources;
   struct native_ctx *queue_owner;
   R4GfxFence fence;
   uint32_t exports;
   VkResult result;
   bool complete;
   bool signal_pending; /* Signal owners may reserve completed metadata. */
   struct r4vk_nvk_point *next; /* One context's in-flight collection ref. */
};
struct native_ctx {
   struct nvkmd_ctx base;
   uint32_t references; /* Public context plus immutable completion points. */
   struct r4vk_nvk_va_context *resources;
   R4GfxBackendBinding backend;
   R4GfxQueueHandle queue;
   struct {
      R4NvNativeSubmitHeader header;
      R4NvNativePush pushes[R4NV_NATIVE_PUSH_LIMIT];
   } packet;
   struct r4vk_nvk_point *last, *pending;
   struct r4vk_nvk_point *waits[R4OS_GFX_QUEUE_MAX_DEPENDENCIES - 1];
   R4GfxFence fences[R4OS_GFX_QUEUE_MAX_DEPENDENCIES - 1];
   uint32_t wait_count;
};
static const struct nvkmd_ctx_ops ctx_ops;

static VkResult lost(struct r4vk_nvk_va_context *resources)
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
static bool fence_valid(R4GfxFence fence, const struct native_ctx *ctx)
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
static void release_fence(struct r4vk_nvk_point *point)
{
   if (!point->complete || point->exports || point->signal_pending || !point->fence.slot) return;
   const int32_t rc = r4draw_gfx_fence_release(&point->resources->draw, &point->fence);
   if (rc != R4OS_GFX_QUEUE_OK) {
      r4vk_native_failure("point-release", VK_ERROR_DEVICE_LOST, rc,
                           point->fence.timeline, point->fence.point);
      point->result = lost(point->resources);
   }
   point->fence.slot = 0;
}
void r4vk_nvk_point_ref(struct r4vk_nvk_point *point)
{
   if (point) p_atomic_inc(&point->references);
}
void r4vk_nvk_point_unref(struct r4vk_nvk_point *point)
{
   if (!point || !p_atomic_dec_zero(&point->references)) return;
   assert(!point->exports);
   /* Dropping a pending fence does not assert completion. The common owner
    * retains its job, canonical bindings and backing until actual retirement. */
   if (point->fence.slot &&
       r4draw_gfx_fence_release(&point->resources->draw, &point->fence) != R4OS_GFX_QUEUE_OK)
      lost(point->resources);
   struct r4vk_nvk_va_context *resources = point->resources;
   struct native_ctx *queue_owner = point->queue_owner;
   simple_mtx_destroy(&point->mutex);
   free(point);
   ctx_unref(queue_owner);
   r4vk_nvk_resources_unref(resources);
}
VkResult r4vk_nvk_point_wait(struct r4vk_nvk_point *point, uint64_t until)
{
   const uint64_t trace = trace_begin();
   simple_mtx_lock(&point->mutex);
   if (point->complete) {
      VkResult result = point->result;
      simple_mtx_unlock(&point->mutex);
      trace_end("point-cached", trace, point->queue_owner->queue.timeline,
                  until, result, true);
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
      else if (rc != R4OS_GFX_QUEUE_OK || !status_valid(&status, fence)) {
         r4vk_native_failure("point-wait-status", VK_ERROR_DEVICE_LOST, rc,
                              fence.timeline, fence.point);
         result = lost(point->resources);
      }
      else if (status.phase != R4OS_GFX_QUEUE_PHASE_TERMINAL) result = VK_TIMEOUT;
      else if (status.result != R4OS_GFX_QUEUE_RESULT_COMPLETE) {
         r4vk_native_failure("point-wait-terminal", VK_ERROR_DEVICE_LOST,
                              status.result, fence.timeline, fence.point);
         result = lost(point->resources);
      }
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
   trace_end("point-wait", trace, fence.timeline, until, result, true);
   return result;
}
VkResult r4vk_nvk_point_export(struct r4vk_nvk_point *point, R4GfxFence *out)
{
   VkResult result = r4vk_nvk_point_wait(point, 0);
   if (result != VK_TIMEOUT) return result;
   simple_mtx_lock(&point->mutex);
   if (point->complete) result = point->result;
   else { point->exports++; *out = point->fence; result = VK_NOT_READY; }
   simple_mtx_unlock(&point->mutex);
   return result; /* NOT_READY means a pinned, not-yet-completed dependency. */
}
void r4vk_nvk_point_unexport(struct r4vk_nvk_point *point)
{
   simple_mtx_lock(&point->mutex);
   assert(point->exports); point->exports--;
   release_fence(point);
   simple_mtx_unlock(&point->mutex);
}
/* WSI signal assignment runs before signal_pending is cleared. Unlike a
 * queue dependency, a presentation receipt still needs completed metadata. */
VkResult r4vk_nvk_point_pin(struct r4vk_nvk_point *point, R4GfxFence *out)
{
   simple_mtx_lock(&point->mutex);
   VkResult result = VK_SUCCESS;
   if (!point->fence.slot || (point->complete && point->result != VK_SUCCESS)) {
      r4vk_native_failure("point-pin-unavailable", VK_ERROR_DEVICE_LOST,
                           point->result, point->fence.timeline, point->fence.point);
      result = VK_ERROR_DEVICE_LOST;
   }
   else {
      point->exports++;
      if (out) *out = point->fence;
   }
   simple_mtx_unlock(&point->mutex);
   return result;
}
static void publish_signals(struct r4vk_nvk_point *point)
{
   if (!point) return;
   simple_mtx_lock(&point->mutex);
   point->signal_pending = false;
   release_fence(point);
   simple_mtx_unlock(&point->mutex);
}
void r4vk_nvk_submit_finish(struct r4vk_nvk_va_context *resources)
{
   simple_mtx_lock(&resources->submit_mutex);
   struct r4vk_nvk_point *tail = resources->submission_tail;
   resources->submission_tail = NULL;
   simple_mtx_unlock(&resources->submit_mutex);
   r4vk_nvk_point_unref(tail);
}
static struct native_ctx *native(struct nvkmd_ctx *base)
{
   assert(base->ops == &ctx_ops);
   return container_of(base, struct native_ctx, base);
}
static VkResult reap(struct native_ctx *ctx)
{
   struct r4vk_nvk_point **link = &ctx->pending;
   while (*link) {
      struct r4vk_nvk_point *point = *link;
      VkResult result = r4vk_nvk_point_wait(point, 0);
      if (result == VK_TIMEOUT) { link = &point->next; continue; }
      *link = point->next;
      r4vk_nvk_point_unref(point);
      if (result != VK_SUCCESS) return result;
   }
   return r4vk_nvk_check_device(ctx->base.dev);
}
static void clear_waits(struct native_ctx *ctx)
{
   for (uint32_t i = 0; i < ctx->wait_count; i++) {
      r4vk_nvk_point_unexport(ctx->waits[i]);
      r4vk_nvk_point_unref(ctx->waits[i]);
   }
   ctx->wait_count = 0;
}
/* Atomic cross-queue ordering of the conservative residency snapshot. NVK's
 * upload and main contexts may access disjoint ranges of the same BO; the
 * common owner cannot infer that from arbitrary indirect GPU addresses.
 * Its existing hazard rules therefore require a device-wide predecessor.
 * An empty batch has no caller memory access, only the driver's fence suffix.
 * The physical publisher is currently serialized as well. No GPU wait occurs
 * under either submit_mutex or residency_mutex. */
static VkResult submit_attempt(struct native_ctx *ctx,
                                struct r4vk_nvk_point *point,
                                R4GfxSubmission *submission,
                                struct r4vk_nvk_point **blocker)
{
   struct r4vk_nvk_va_context *resources = ctx->resources;
   simple_mtx_lock(&resources->submit_mutex);
   VkResult result;
   struct r4vk_nvk_point *previous = resources->submission_tail;
   bool exported = false, replaced = false;
   submission->dependency_count = 0;
   memset(submission->dependencies, 0, sizeof(submission->dependencies));
   if (r4vk_nvk_va_device_lost(resources)) {
      result = VK_ERROR_DEVICE_LOST;
      goto done;
   }
   if (previous) {
      result = r4vk_nvk_point_export(previous, &submission->dependencies[0]);
      if (result == VK_NOT_READY) { exported = true; submission->dependency_count = 1; }
      else if (result != VK_SUCCESS) goto done;
   }
   for (uint32_t i = 0; i < ctx->wait_count; i++) {
      bool duplicate = false;
      for (uint32_t j = 0; j < submission->dependency_count; j++)
         duplicate |= fence_equal(ctx->fences[i], submission->dependencies[j]);
      if (!duplicate) submission->dependencies[submission->dependency_count++] = ctx->fences[i];
   }
   R4GfxNativeSubmission command = {
      .version = 1, .size = sizeof(command),
      .interface_id_lo = R4NV_BACKEND_V1_INTERFACE_ID_LO,
      .interface_id_hi = R4NV_BACKEND_V1_INTERFACE_ID_HI,
      .revision = R4NV_NATIVE_SUBMIT_VERSION,
      .command_bytes = sizeof(ctx->packet.header) + ctx->packet.header.push_count * sizeof(R4NvNativePush),
      .commands = (uintptr_t)&ctx->packet,
   };
   R4GfxFenceStatus accepted;
   result = r4vk_nvk_va_submit(resources, ctx->packet.header.push_count != 0,
                              &ctx->queue, submission, &command, &accepted);
   if (result == VK_NOT_READY && previous) {
      r4vk_nvk_point_ref(previous);
      *blocker = previous;
   }
   if (result != VK_SUCCESS) goto done;
   if (!fence_valid(accepted.fence, ctx)) {
      result = lost(resources);
      goto done;
   }
   point->fence = accepted.fence;
   if (!status_valid(&accepted, accepted.fence) ||
       (accepted.phase == R4OS_GFX_QUEUE_PHASE_TERMINAL &&
        accepted.result != R4OS_GFX_QUEUE_RESULT_COMPLETE)) {
      result = lost(resources);
      goto done;
   }
   resources->submission_tail = point;
   r4vk_nvk_point_ref(point);
   replaced = true;
done:
   if (exported) r4vk_nvk_point_unexport(previous);
   simple_mtx_unlock(&resources->submit_mutex);
   if (replaced) r4vk_nvk_point_unref(previous);
   return result;
}
static VkResult flush(struct native_ctx *ctx, bool force, bool reserve_signals)
{
   VkResult result = reap(ctx);
   if (result != VK_SUCCESS) return result;
   if (!force && !ctx->packet.header.push_count && !ctx->wait_count) return VK_SUCCESS;
   struct r4vk_nvk_point *point = calloc(1, sizeof(*point));
   if (!point) return VK_ERROR_OUT_OF_HOST_MEMORY;
   point->references = 1;
   point->resources = ctx->resources;
   point->queue_owner = ctx;
   p_atomic_inc(&ctx->references);
   point->result = VK_NOT_READY;
   point->signal_pending = reserve_signals;
   simple_mtx_init(&point->mutex, mtx_plain);
   r4vk_nvk_resources_ref(point->resources);
   R4GfxSubmission submission = {
      .version = 1, .size = sizeof(submission), .operation = R4OS_GFX_QUEUE_OPERATION_NATIVE,
   };
   uint64_t ticks;
   if (r4vk_operation_deadline(60000000000ull, &submission.deadline_ns, &ticks) != 0) {
      r4vk_nvk_point_unref(point); return lost(ctx->resources);
   }
   struct r4vk_nvk_point *blocker = NULL;
   uint64_t trace = trace_begin();
   result = submit_attempt(ctx, point, &submission, &blocker);
   trace_end("physical-submit", trace, ctx->queue.timeline,
               ctx->packet.header.push_count, result, false);
   /* Wait outside both owner mutexes, then rebuild against the current tail.
    * Other contexts may have submitted while this thread was asleep. */
   if (result == VK_NOT_READY && blocker) {
      result = r4vk_nvk_point_wait(blocker, submission.deadline_ns);
      r4vk_nvk_point_unref(blocker);
      blocker = NULL;
      if (result == VK_SUCCESS) result = reap(ctx);
      if (result == VK_SUCCESS) {
         trace = trace_begin();
         result = submit_attempt(ctx, point, &submission, &blocker);
         trace_end("physical-retry", trace, ctx->queue.timeline,
                     ctx->packet.header.push_count, result, false);
      }
   }
   r4vk_nvk_point_unref(blocker);
   if (result != VK_SUCCESS) {
      r4vk_native_failure("queue-flush", result, ctx->packet.header.push_count,
                           ctx->queue.timeline, ctx->wait_count);
      r4vk_nvk_point_unref(point);
      return result == VK_TIMEOUT ? lost(ctx->resources) :
         result == VK_NOT_READY ? VK_ERROR_OUT_OF_HOST_MEMORY : result;
   }
   clear_waits(ctx);
   ctx->packet.header.push_count = 0;
   r4vk_nvk_point_unref(ctx->last);
   ctx->last = point;
   r4vk_nvk_point_ref(point);
   point->next = ctx->pending;
   ctx->pending = point;
   return VK_SUCCESS;
}
static void ctx_unref(struct native_ctx *ctx)
{
   if (!p_atomic_dec_zero(&ctx->references)) return;
   /* Closing a queue invalidates its fence namespace. WSI points keep that
    * namespace alive until the last Desktop loan ends, beyond VkDevice. */
   if (r4draw_gfx_queue_close(&ctx->resources->draw, &ctx->queue) != R4OS_GFX_QUEUE_OK)
      lost(ctx->resources);
   struct r4vk_nvk_va_context *resources = ctx->resources;
   free(ctx);
   r4vk_nvk_resources_unref(resources);
}
static void ctx_destroy(struct nvkmd_ctx *base)
{
   struct native_ctx *ctx = native(base);
   clear_waits(ctx);
   r4vk_nvk_point_unref(ctx->last);
   ctx->last = NULL;
   while (ctx->pending) {
      struct r4vk_nvk_point *point = ctx->pending;
      ctx->pending = point->next;
      r4vk_nvk_point_unref(point);
   }
   ctx_unref(ctx);
}
/* Public vk_queue submissions already unwrap assisted timelines. NVK's
 * private upload/memory streams bypass that layer and need the same bridge.
 * Their log object supplies the live Vulkan allocator owner; no device or
 * timeline pointer is retained by the native context. */
static bool internal_timeline(struct vk_object_base *log, struct vk_sync *sync)
{
   if (!log || !log->device || !sync || sync->flags != VK_SYNC_IS_TIMELINE ||
       !vk_sync_as_timeline(sync)) return false;
   const struct vk_sync_timeline_type *type =
      container_of(sync->type, struct vk_sync_timeline_type, sync);
   return type->point_sync_type == &r4vk_nvk_sync_type;
}
static VkResult ctx_wait(struct nvkmd_ctx *base, struct vk_object_base *log,
                          uint32_t count, const struct vk_sync_wait *waits)
{
   struct native_ctx *ctx = native(base);
   for (uint32_t i = 0; i < count; i++)
      if (!r4vk_nvk_sync_supported(waits[i].sync, waits[i].wait_value) &&
          !internal_timeline(log, waits[i].sync))
         return VK_ERROR_FEATURE_NOT_PRESENT;
   for (uint32_t i = 0; i < count; i++) {
      if (ctx->wait_count == ARRAY_SIZE(ctx->waits)) {
         VkResult result = flush(ctx, true, false);
         if (result != VK_SUCCESS) return result;
      }
      struct vk_sync_wait wait = waits[i];
      struct vk_sync_timeline_point *time_point = NULL;
      if (internal_timeline(log, wait.sync)) {
         VkResult result = vk_sync_wait_unwrap(log->device, &wait, &time_point);
         if (result != VK_SUCCESS) return result;
         if (!wait.sync) continue; /* Zero or an already completed value. */
      }
      struct r4vk_nvk_point *point = NULL;
      VkResult result = r4vk_nvk_sync_point(wait.sync, ctx->resources, &point);
      if (time_point) vk_sync_timeline_point_unref(log->device, time_point);
      if (result != VK_SUCCESS) return result;
      if (!point) continue; /* Explicit CPU-signaled binary event. */
      if (point->resources != ctx->resources) {
         r4vk_nvk_point_unref(point); return VK_ERROR_UNKNOWN;
      }
      R4GfxFence fence;
      result = r4vk_nvk_point_export(point, &fence);
      if (result == VK_NOT_READY) {
         bool duplicate = false;
         for (uint32_t j = 0; j < ctx->wait_count; j++)
            duplicate |= fence_equal(ctx->fences[j], fence);
         if (!duplicate) {
            ctx->waits[ctx->wait_count] = point;
            ctx->fences[ctx->wait_count++] = fence;
            continue;
         }
         r4vk_nvk_point_unexport(point);
         result = VK_SUCCESS;
      }
      r4vk_nvk_point_unref(point);
      if (result != VK_SUCCESS) return result;
   }
   return r4vk_nvk_check_device(base->dev);
}
static VkResult ctx_exec(struct nvkmd_ctx *base, struct vk_object_base *log,
                          uint32_t count, const struct nvkmd_ctx_exec *execs)
{
   (void)log;
   struct native_ctx *ctx = native(base);
   VkResult result = r4vk_nvk_check_device(base->dev);
   if (result != VK_SUCCESS) return result;
   uint32_t chain = 0;
   for (uint32_t i = 0; i < count; i++) {
      const struct nvkmd_ctx_exec *exec = &execs[i];
      if (!exec->addr || !exec->size_B || ((exec->addr | exec->size_B) & 3) ||
          exec->size_B >= (1u << 23) || exec->addr >= (1ull << 40) ||
          exec->size_B > (1ull << 40) - exec->addr ||
          (++chain > R4NV_NATIVE_PUSH_LIMIT) || (i == count - 1 && exec->incomplete))
         return VK_ERROR_UNKNOWN;
      if (!exec->incomplete) chain = 0;
   }
   for (uint32_t i = 0; i < count;) {
      uint32_t end = i;
      while (execs[end++].incomplete) {}
      if (end - i > R4NV_NATIVE_PUSH_LIMIT - ctx->packet.header.push_count) {
         result = flush(ctx, false, false);
         if (result != VK_SUCCESS) return result;
      }
      for (; i < end; i++) {
         ctx->packet.pushes[ctx->packet.header.push_count++] = (R4NvNativePush) {
            .address = execs[i].addr, .byte_length = execs[i].size_B,
            .flags = (execs[i].incomplete ? R4NV_NATIVE_PUSH_INCOMPLETE : 0) |
                     (execs[i].no_prefetch ? R4NV_NATIVE_PUSH_NO_PREFETCH : 0),
         };
      }
   }
   return VK_SUCCESS;
}
/* A signal-only submit orders after this queue's actual last execution.
 * Reuse that exact completion instead of publishing a second empty native
 * job, which a serialized physical publisher may accept only after the
 * execution finishes. Reserve its real metadata before reap can release it;
 * WSI signal consumers need the same independently pinned receipt. Commands,
 * waits, another queue/epoch and already released receipts still use flush.
 * Vulkan queue submission is externally synchronized by its caller. */
static bool reserve_last_signals(struct native_ctx *ctx)
{
   struct r4vk_nvk_point *point = ctx->last;
   if (!point || ctx->packet.header.push_count || ctx->wait_count)
      return false;
   simple_mtx_lock(&point->mutex);
   bool valid = point->resources == ctx->resources && point->queue_owner == ctx &&
      !point->signal_pending && fence_valid(point->fence, ctx) &&
      (!point->complete || point->result == VK_SUCCESS);
   if (valid) point->signal_pending = true;
   simple_mtx_unlock(&point->mutex);
   return valid;
}
static VkResult ctx_signal(struct nvkmd_ctx *base, struct vk_object_base *log,
                            uint32_t count, const struct vk_sync_signal *signals)
{
   struct native_ctx *ctx = native(base);
   const uint64_t trace = trace_begin();
   bool reserved = false;
   bool has_timeline = false;
   for (uint32_t i = 0; i < count; i++) {
      if (internal_timeline(log, signals[i].sync) && signals[i].signal_value)
         has_timeline = true;
      else if (!r4vk_nvk_sync_supported(signals[i].sync, signals[i].signal_value))
         return VK_ERROR_FEATURE_NOT_PRESENT;
   }
   /* Allocate every timeline point before submitting or publishing any
    * signal. Failed allocation leaves the batch and all signals untouched. */
   struct vk_sync_timeline_point **points = NULL;
   VkResult result = VK_SUCCESS;
   if (has_timeline) {
      points = calloc(count, sizeof(*points));
      if (!points) return VK_ERROR_OUT_OF_HOST_MEMORY;
      for (uint32_t i = 0; i < count; i++) {
         if (!internal_timeline(log, signals[i].sync)) continue;
         struct vk_sync_signal signal = signals[i];
         result = vk_sync_signal_unwrap(log->device, &signal, &points[i]);
         if (result != VK_SUCCESS) goto done;
      }
   }
   reserved = count != 0 && reserve_last_signals(ctx);
   result = reserved ? reap(ctx) : flush(ctx, count != 0, count != 0);
   if (result != VK_SUCCESS) goto done;
   for (uint32_t i = 0; i < count; i++) {
      struct vk_sync *sync = points && points[i] ? &points[i]->sync : signals[i].sync;
      result = r4vk_nvk_sync_assign(sync, ctx->last);
      if (result != VK_SUCCESS) { result = lost(ctx->resources); goto done; }
   }
   if (points) {
      for (uint32_t i = 0; i < count; i++) {
         if (!points[i]) continue;
         result = vk_sync_timeline_point_install(log->device, points[i]);
         points[i] = NULL; /* Install consumes the reference, also on error. */
         if (result != VK_SUCCESS) { result = lost(ctx->resources); goto done; }
      }
   }
done:
   publish_signals(ctx->last);
   if (points) {
      for (uint32_t i = 0; i < count; i++)
         if (points[i]) vk_sync_timeline_point_unref(log->device, points[i]);
      free(points);
   }
   trace_end("signal", trace, ctx->queue.timeline,
               ((uint64_t)count << 32) | reserved, result, false);
   return result;
}
static VkResult ctx_flush(struct nvkmd_ctx *base, struct vk_object_base *log)
{
   (void)log;
   return flush(native(base), false, false);
}
static VkResult ctx_sync(struct nvkmd_ctx *base, struct vk_object_base *log)
{
   (void)log;
   struct native_ctx *ctx = native(base);
   VkResult result = flush(ctx, false, false);
   if (result != VK_SUCCESS) return result;
   if (ctx->last) result = r4vk_nvk_point_wait(ctx->last, UINT64_MAX);
   return result == VK_SUCCESS ? reap(ctx) : result;
}
static const struct nvkmd_ctx_ops ctx_ops = {
   .destroy = ctx_destroy, .wait = ctx_wait, .exec = ctx_exec,
   .signal = ctx_signal, .flush = ctx_flush, .sync = ctx_sync,
};

VkResult r4vk_nvk_create_ctx(struct r4vk_nvk_va_context *resources,
                            const R4GfxBackendBinding *backend,
                            enum nvkmd_engines engines, struct nvkmd_ctx **out)
{
   if (!out) return VK_ERROR_INITIALIZATION_FAILED;
   /* Modern NVK's private upload queue requests COPY alone. The native
    * packet still creates a regular GR channel, with its paired CE object;
    * do not reinterpret Mesa's differently numbered engine mask. */
   const unsigned supported = NVKMD_ENGINE_3D | NVKMD_ENGINE_COMPUTE | NVKMD_ENGINE_COPY;
   if (!engines || ((unsigned)engines & ~supported)) return VK_ERROR_FEATURE_NOT_PRESENT;
   const R4Draw *draw = &resources->draw;
   if (!R4DRAW_HAS(draw, gfx_queue_submit_native) || !R4DRAW_HAS(draw, gfx_queue_open) || !R4DRAW_HAS(draw, gfx_queue_close) ||
       !R4DRAW_HAS(draw, gfx_fence_query) || !R4DRAW_HAS(draw, gfx_fence_wait) || !R4DRAW_HAS(draw, gfx_fence_release))
      return VK_ERROR_FEATURE_NOT_PRESENT;
   VkResult result = r4vk_nvk_check_device(resources->dev);
   if (result != VK_SUCCESS) return result;
   struct native_ctx *ctx = calloc(1, sizeof(*ctx));
   if (!ctx) return VK_ERROR_OUT_OF_HOST_MEMORY;
   ctx->base = (struct nvkmd_ctx){ .ops = &ctx_ops, .dev = resources->dev };
   ctx->references = 1;
   ctx->resources = resources;
   ctx->backend = *backend;
   ctx->packet.header = (R4NvNativeSubmitHeader) {
      .version = R4NV_NATIVE_SUBMIT_VERSION, .size = sizeof(R4NvNativeSubmitHeader),
      .engine_mask = R4NV_NATIVE_ENGINE_GRAPHICS |
         ((engines & NVKMD_ENGINE_COPY) ? R4NV_NATIVE_ENGINE_COPY : 0) |
         ((engines & NVKMD_ENGINE_COMPUTE) ? R4NV_NATIVE_ENGINE_COMPUTE : 0),
   };
   R4GfxQueueConfig config = {
      .version = 1, .size = sizeof(config), .adapter_id = backend->adapter_id,
      .policy = R4OS_GFX_QUEUE_POLICY_FIFO, .capacity = R4OS_GFX_QUEUE_FENCE_CAPACITY,
      .milestone = R4OS_GFX_QUEUE_MILESTONE_DEVICE_EXECUTION,
      .device_generation = backend->device_generation, .reset_generation = backend->reset_generation,
   };
   int32_t rc = r4draw_gfx_queue_open(&resources->draw, &config, &ctx->queue);
   if (rc != R4OS_GFX_QUEUE_OK) {
      free(ctx);
      if (rc == R4OS_GFX_QUEUE_ERROR_OOM || rc == R4OS_GFX_QUEUE_ERROR_CAPACITY)
         return VK_ERROR_OUT_OF_HOST_MEMORY;
      if (rc == R4OS_GFX_QUEUE_ERROR_UNSUPPORTED || rc == R4OS_GFX_QUEUE_ERROR_UNAVAILABLE)
         return VK_ERROR_FEATURE_NOT_PRESENT;
      return lost(resources);
   }
   r4vk_nvk_resources_ref(resources);
   if (ctx->queue.version != 1 || ctx->queue.size < sizeof(ctx->queue) || !ctx->queue.timeline) {
      ctx_destroy(&ctx->base); return lost(resources);
   }
   /* A live class ID is insufficient. The first empty batch instantiates all
    * requested real RM engine objects and executes the physical fence suffix. */
   result = flush(ctx, true, false);
   if (result == VK_SUCCESS) result = ctx_sync(&ctx->base, NULL);
   if (result != VK_SUCCESS) { ctx_destroy(&ctx->base); return result; }
   *out = &ctx->base;
   return VK_SUCCESS;
}
