/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_nvk_submit.h"
#include "vk_device.h"
#include "util/cnd_monotonic.h"
#include <stdint.h>

int r4vk_monotonic_time(uint64_t *);

struct native_sync {
   struct vk_sync base;
   struct vk_device *device;
   mtx_t mutex;
   struct u_cnd_monotonic condition;
   struct r4vk_nvk_point *point;
   bool signaled;
   bool hold_fence;
};
static struct native_sync *native(struct vk_sync *base)
{
   assert(base->type == &r4vk_nvk_sync_type);
   return container_of(base, struct native_sync, base);
}
bool r4vk_nvk_sync_supported(const struct vk_sync *sync, uint64_t value)
{
   return sync && sync->type == &r4vk_nvk_sync_type && !sync->flags && !value;
}
static VkResult lock(struct native_sync *sync)
{
   int rc = mtx_lock(&sync->mutex);
   return rc == thrd_success ? VK_SUCCESS : rc == thrd_nomem ?
      VK_ERROR_OUT_OF_HOST_MEMORY : VK_ERROR_DEVICE_LOST;
}
static void unlock(struct native_sync *sync)
{
   if (mtx_unlock(&sync->mutex) != thrd_success) __builtin_trap();
}
static VkResult sync_init(struct vk_device *device, struct vk_sync *base,
                           uint64_t initial)
{
   if (base->flags || initial > 1) return VK_ERROR_FEATURE_NOT_PRESENT;
   struct native_sync *sync = native(base);
   if (mtx_init(&sync->mutex, mtx_plain) != thrd_success)
      return VK_ERROR_OUT_OF_HOST_MEMORY;
   if (u_cnd_monotonic_init(&sync->condition) != thrd_success) {
      mtx_destroy(&sync->mutex); return VK_ERROR_OUT_OF_HOST_MEMORY;
   }
   sync->device = device;
   sync->point = NULL;
   sync->signaled = initial != 0;
   sync->hold_fence = false;
   return VK_SUCCESS;
}
static void sync_finish(struct vk_device *device, struct vk_sync *base)
{
   (void)device;
   struct native_sync *sync = native(base);
   if (sync->hold_fence && sync->point) r4vk_nvk_point_unexport(sync->point);
   r4vk_nvk_point_unref(sync->point);
   u_cnd_monotonic_destroy(&sync->condition);
   mtx_destroy(&sync->mutex);
}
/* Caller holds the sync mutex. A short timed condition wait, only while no
 * GPU point exists, also observes device loss from another submit worker.
 * Once assigned, the actual resident GPU event supplies the completion wait. */
static VkResult pending(struct native_sync *sync, uint64_t until,
                         struct r4vk_nvk_va_context *resources)
{
   while (!sync->signaled && !sync->point) {
      if ((sync->device && vk_device_is_lost_no_report(sync->device)) ||
          (resources && r4vk_nvk_va_device_lost(resources)))
         return VK_ERROR_DEVICE_LOST;
      uint64_t now;
      if (r4vk_monotonic_time(&now) != 0) return VK_ERROR_DEVICE_LOST;
      if (now >= until) return VK_TIMEOUT;
      const uint64_t duration = MIN2(until - now, 100000000ull);
      const uint64_t wake = now + duration;
      struct timespec deadline = { .tv_sec = wake / 1000000000ull,
                                   .tv_nsec = wake % 1000000000ull };
      int rc = u_cnd_monotonic_timedwait(&sync->condition, &sync->mutex, &deadline);
      if (rc != thrd_success && rc != thrd_timedout) return VK_ERROR_DEVICE_LOST;
   }
   return VK_SUCCESS;
}
VkResult r4vk_nvk_sync_point(struct vk_sync *base,
                            struct r4vk_nvk_va_context *resources,
                            struct r4vk_nvk_point **out)
{
   struct native_sync *sync = native(base);
   VkResult result = lock(sync);
   if (result != VK_SUCCESS) return result;
   result = pending(sync, UINT64_MAX, resources);
   if (result == VK_SUCCESS) { *out = sync->point; r4vk_nvk_point_ref(*out); }
   unlock(sync);
   return result;
}
static VkResult replace(struct native_sync *sync, struct r4vk_nvk_point *point,
                          bool signaled)
{
   VkResult result = lock(sync);
   if (result != VK_SUCCESS) return result;
   struct r4vk_nvk_point *old = sync->point;
   const bool old_pinned = sync->hold_fence && old;
   if (sync->hold_fence && point) {
      result = r4vk_nvk_point_pin(point, NULL);
      if (result != VK_SUCCESS) { unlock(sync); return result; }
   }
   r4vk_nvk_point_ref(point);
   sync->point = point;
   sync->signaled = signaled;
   if (u_cnd_monotonic_broadcast(&sync->condition) != thrd_success)
      result = VK_ERROR_DEVICE_LOST;
   unlock(sync);
   if (old_pinned) r4vk_nvk_point_unexport(old);
   r4vk_nvk_point_unref(old);
   return result;
}
VkResult r4vk_nvk_sync_assign(struct vk_sync *base, struct r4vk_nvk_point *point)
{
   assert(point);
   return replace(native(base), point, false);
}
VkResult r4vk_nvk_sync_prepare_present(struct vk_sync *base)
{
   if (!r4vk_nvk_sync_supported(base, 0)) return VK_ERROR_FEATURE_NOT_PRESENT;
   struct native_sync *sync = native(base);
   VkResult result = lock(sync);
   if (result != VK_SUCCESS) return result;
   if (sync->point || sync->signaled || sync->hold_fence) result = VK_ERROR_UNKNOWN;
   else sync->hold_fence = true;
   unlock(sync);
   return result;
}
/* Transfer one independent point reference and metadata pin to WSI. The
 * Vulkan fence may now be destroyed; native resources remain independently
 * owned even after VkDevice destruction. The caller unexports then unrefs. */
VkResult r4vk_nvk_sync_take_present(struct vk_sync *base,
   struct r4vk_nvk_point **out, R4GfxFence *fence)
{
   struct native_sync *sync = native(base);
   VkResult result = lock(sync);
   if (result != VK_SUCCESS) return result;
   if (!sync->hold_fence) { unlock(sync); return VK_ERROR_UNKNOWN; }
   result = pending(sync, UINT64_MAX, NULL);
   if (result == VK_SUCCESS && !sync->point) result = VK_ERROR_UNKNOWN;
   if (result == VK_SUCCESS) {
      /* A second pin copies the identity while the existing signal pin
       * protects it. Transfer the original pin and release this extra one. */
      result = r4vk_nvk_point_pin(sync->point, fence);
      if (result == VK_SUCCESS) {
         r4vk_nvk_point_unexport(sync->point);
         r4vk_nvk_point_ref(sync->point);
         *out = sync->point;
         sync->hold_fence = false;
      }
   }
   unlock(sync);
   return result;
}
static VkResult sync_signal(struct vk_device *device, struct vk_sync *base,
                             uint64_t value)
{
   (void)device;
   if (!r4vk_nvk_sync_supported(base, value)) return VK_ERROR_FEATURE_NOT_PRESENT;
   return replace(native(base), NULL, true);
}
static VkResult sync_reset(struct vk_device *device, struct vk_sync *base)
{
   (void)device;
   return replace(native(base), NULL, false);
}
static VkResult sync_move(struct vk_device *device, struct vk_sync *dst_base,
                           struct vk_sync *src_base)
{
   (void)device;
   if (dst_base == src_base || !r4vk_nvk_sync_supported(dst_base, 0) ||
       !r4vk_nvk_sync_supported(src_base, 0)) return VK_ERROR_UNKNOWN;
   struct native_sync *dst = native(dst_base), *src = native(src_base);
   struct native_sync *first = (uintptr_t)dst < (uintptr_t)src ? dst : src;
   struct native_sync *second = first == dst ? src : dst;
   VkResult result = lock(first);
   if (result != VK_SUCCESS) return result;
   result = lock(second);
   if (result != VK_SUCCESS) { unlock(first); return result; }
   if (src->hold_fence || dst->hold_fence) {
      unlock(second); unlock(first); return VK_ERROR_FEATURE_NOT_PRESENT;
   }
   struct r4vk_nvk_point *old = dst->point;
   dst->point = src->point; dst->signaled = src->signaled;
   src->point = NULL; src->signaled = false;
   if (u_cnd_monotonic_broadcast(&dst->condition) != thrd_success)
      result = VK_ERROR_DEVICE_LOST;
   unlock(second); unlock(first);
   r4vk_nvk_point_unref(old);
   return result;
}
static VkResult sync_wait(struct vk_device *device, struct vk_sync *base,
                           uint64_t value, enum vk_sync_wait_flags flags,
                           uint64_t until)
{
   (void)device;
   if (!r4vk_nvk_sync_supported(base, value) ||
       (flags & ~(VK_SYNC_WAIT_PENDING | VK_SYNC_WAIT_ANY)))
      return VK_ERROR_FEATURE_NOT_PRESENT;
   struct native_sync *sync = native(base);
   VkResult result = lock(sync);
   if (result != VK_SUCCESS) return result;
   result = pending(sync, until, NULL);
   struct r4vk_nvk_point *point = NULL;
   if (result == VK_SUCCESS && !(flags & VK_SYNC_WAIT_PENDING)) {
      point = sync->point; r4vk_nvk_point_ref(point);
   }
   unlock(sync);
   if (point) {
      result = r4vk_nvk_point_wait(point, until);
      r4vk_nvk_point_unref(point);
   }
   return result;
}

const struct vk_sync_type r4vk_nvk_sync_type = {
   .size = sizeof(struct native_sync),
   .features = VK_SYNC_FEATURE_BINARY | VK_SYNC_FEATURE_GPU_WAIT |
      VK_SYNC_FEATURE_GPU_MULTI_WAIT | VK_SYNC_FEATURE_CPU_WAIT |
      VK_SYNC_FEATURE_CPU_RESET | VK_SYNC_FEATURE_CPU_SIGNAL | VK_SYNC_FEATURE_WAIT_PENDING,
   .init = sync_init, .finish = sync_finish, .signal = sync_signal,
   .reset = sync_reset, .move = sync_move, .wait = sync_wait,
};
