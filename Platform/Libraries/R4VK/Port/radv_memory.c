/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_radv_winsys.h"
#include <stdlib.h>
static bool valid(R4GfxBufferHandle h) { return h.id && h.generation && !h.reserved0; }
static bool equal(R4GfxBufferHandle a, R4GfxBufferHandle b) { return a.id == b.id && a.generation == b.generation && a.reserved0 == b.reserved0; }
static bool power_of_two(uint64_t n) { return n && !(n & (n - 1)); }
VkResult r4vk_radv_status(struct r4vk_radv_ws *ws, int32_t rc)
{
   switch (rc) {
   case R4OS_GFX_BUFFER_ERROR_OOM: case R4OS_GFX_BUFFER_ERROR_CAPACITY: case R4OS_GFX_BUFFER_ERROR_BUDGET:
      return VK_ERROR_OUT_OF_DEVICE_MEMORY;
   case R4OS_ERR_NO_FN: case R4OS_ERR_NO_GROUP: case R4OS_GFX_BUFFER_ERROR_UNSUPPORTED:
   case R4OS_GFX_BUFFER_ERROR_UNAVAILABLE: return VK_ERROR_FEATURE_NOT_PRESENT;
   case R4OS_GFX_BUFFER_ERROR_STALE: case R4OS_GFX_BUFFER_ERROR_CLOSED:
   case R4OS_GFX_QUEUE_ERROR_WAIT_TIMEOUT: case R4OS_GFX_QUEUE_ERROR_WAIT_CANCELLED:
   case R4OS_GFX_QUEUE_ERROR_DEVICE_LOST: return r4vk_radv_lost(ws);
   default: return VK_ERROR_UNKNOWN;
   }
}
static void drop(struct r4vk_radv_ws *context, R4GfxBufferHandle handle)
{
   if (r4draw_gfx_buffer_release(&context->draw, &handle) != 1)
      r4vk_radv_lost(context); /* The resident BO owner retains uncertain cleanup. */
}
static void close_request(struct r4vk_radv_ws *context,
                          R4GfxBufferHandle request)
{
   if (r4draw_gfx_native_close(&context->draw, &request) != 1)
      r4vk_radv_lost(context);
}
static VkResult allocate_vram(struct r4vk_radv_ws *context,
                              uint64_t bytes, R4GfxBufferReference *out)
{
   const struct r4vk_radv_ws *resources = context;
   R4GfxNativeAllocation request = {
      .version = 1, .size = sizeof(request), .adapter_id = resources->facts.backend.binding.adapter_id,
      .memory_generation = resources->facts.backend.memory_generation,
      .byte_length = bytes, .usage = R4OS_GFX_BUFFER_USAGE_TRANSFER_SOURCE |
                                    R4OS_GFX_BUFFER_USAGE_TRANSFER_TARGET,
   };
   uint64_t ticks;
   if (r4vk_operation_deadline(5000000000ull, &request.deadline_ns, &ticks) != 0)
      return r4vk_radv_lost(context);
   R4GfxNativeStatus initial;
   int32_t rc = r4draw_gfx_native_start(&resources->draw, &request, &initial);
   if (rc != 1) return r4vk_radv_status(context, rc);
   if (!valid(initial.request)) return r4vk_radv_lost(context);
   R4GfxNativeStatus ready;
   rc = r4draw_gfx_native_wait(&resources->draw, &initial.request, ticks, &ready);
   if (rc != 1) {
      VkResult result = r4vk_radv_status(context, rc);
      close_request(context, initial.request);
      return r4vk_radv_is_lost(context) ? VK_ERROR_DEVICE_LOST : result;
   }
   if (ready.version != 1 || ready.size < sizeof(ready) || ready.reserved0 ||
       !equal(ready.request, initial.request) || ready.phase != 2 ||
       (ready.flags & ~1u) || ready.deadline_ns != request.deadline_ns ||
       !ready.completed_ns) {
      close_request(context, initial.request);
      return r4vk_radv_lost(context);
   }
   if (ready.result != 1) {
      VkResult result = r4vk_radv_status(context, ready.result);
      close_request(context, initial.request);
      return r4vk_radv_is_lost(context) ? VK_ERROR_DEVICE_LOST : result;
   }
   rc = r4draw_gfx_native_receive(&resources->draw, &initial.request, out);
   if (rc == 1) return VK_SUCCESS; /* Receive consumes the request. */
   VkResult result = r4vk_radv_status(context, rc);
   close_request(context, initial.request);
   return r4vk_radv_is_lost(context) ? VK_ERROR_DEVICE_LOST : result;
}
static VkResult check_backing(struct r4vk_radv_ws *context,
                              const R4GfxBufferReference *ref, bool vram,
                              uint64_t bytes)
{
   if (ref->version != 1 || ref->size < sizeof(*ref) || ref->flags ||
       ref->reserved0 || !valid(ref->buffer) || !valid(ref->reference))
      return r4vk_radv_lost(context);
   R4GfxBufferDescriptor desc;
   const struct r4vk_radv_ws *resources = context;
   int32_t rc = r4draw_gfx_buffer_describe(&resources->draw, &ref->reference, &desc);
   if (rc != 1) return r4vk_radv_status(context, rc);
   if (desc.version != 1 || desc.size < sizeof(desc) || desc.reserved0 ||
       desc.byte_length < bytes || !power_of_two(desc.alignment) ||
       desc.format != R4OS_GFX_BUFFER_FORMAT_BYTES || desc.modifier ||
       desc.width || desc.height || desc.plane_count ||
       desc.location != (vram ? R4OS_GFX_BUFFER_LOCATION_DEVICE_LOCAL : R4OS_GFX_BUFFER_LOCATION_SYSTEM) ||
       (desc.usage & (vram ? 12u : 15u)) != (vram ? 12u : 15u))
      return r4vk_radv_lost(context);
   for (unsigned i = 0; i < 4; i++)
      if (desc.plane_offsets[i] || desc.plane_pitches[i]) return r4vk_radv_lost(context);
   if (vram) {
      if (desc.adapter_id != resources->facts.backend.binding.adapter_id || !desc.driver_owner ||
          desc.device_generation != resources->facts.backend.memory_generation || (desc.usage & 3))
         return r4vk_radv_lost(context);
   } else if (desc.adapter_id || desc.driver_owner || desc.device_generation) {
      return r4vk_radv_lost(context);
   }
   return VK_SUCCESS;
}

static void abandon(struct r4vk_radv_ws *context, R4GfxBufferHandle handle)
{
   if (r4draw_gfx_virtual_close(&context->draw, &handle, 1) != 1)
      r4vk_radv_lost(context);
}
static bool matching_status(const R4GfxVirtualStatus *value,
                            R4GfxBufferHandle handle,
                            const R4GfxVirtualRequest *request)
{
   return value->version == 1 && value->size >= sizeof(*value) &&
          equal(value->resource, handle) && value->reserved0 == 0 &&
          value->kind == request->kind && value->byte_length == request->byte_length &&
          equal(value->parent, request->parent) &&
          value->deadline_ns == request->deadline_ns;
}
static VkResult create(struct r4vk_radv_ws *context,
                       R4GfxVirtualRequest *request, uint64_t expected_address,
                       R4GfxVirtualStatus *output)
{
   uint64_t ticks;
   if (r4vk_radv_is_lost(context)) return VK_ERROR_DEVICE_LOST;
   if (r4vk_operation_deadline(5000000000ull, &request->deadline_ns, &ticks) != 0)
      return r4vk_radv_lost(context);
   request->version = 1;
   request->size = sizeof(*request);
   request->adapter_id = context->facts.backend.binding.adapter_id;
   request->memory_generation = context->facts.backend.memory_generation;
   R4GfxVirtualStatus initial;
   int32_t rc = r4draw_gfx_virtual_start(&context->draw, request, &initial);
   if (rc != 1) return r4vk_radv_status(context, rc);
   if (!valid(initial.resource)) return r4vk_radv_lost(context);
   R4GfxVirtualStatus ready;
   rc = r4draw_gfx_virtual_wait(&context->draw, &initial.resource, 0, ticks, &ready);
   if (rc != 1) {
      VkResult result = r4vk_radv_status(context, rc);
      abandon(context, initial.resource);
      return r4vk_radv_is_lost(context) ? VK_ERROR_DEVICE_LOST : result;
   }
   if (!matching_status(&ready, initial.resource, request) || !(ready.flags & 1) ||
       (ready.flags & ~15u)) {
      abandon(context, initial.resource);
      return r4vk_radv_lost(context);
   }
   if (ready.result != 1) {
      VkResult result = r4vk_radv_status(context, ready.result);
      abandon(context, initial.resource);
      return r4vk_radv_is_lost(context) ? VK_ERROR_DEVICE_LOST : result;
   }
   if ((ready.flags & 14) || !ready.address ||
       ready.address > UINT64_MAX - ready.byte_length ||
       (expected_address && ready.address != expected_address) ||
       (request->kind == 1 && (ready.address % request->alignment ||
          ready.address < context->facts.facts.va_start || ready.address >= context->facts.facts.va_end ||
          ready.byte_length > context->facts.facts.va_end - ready.address))) {
      abandon(context, initial.resource);
      return r4vk_radv_lost(context);
   }
   *output = ready;
   return VK_SUCCESS;
}

static void unmap_bo(struct radeon_winsys *, struct radeon_winsys_bo *, bool);
bool r4vk_radv_buffer_try_ref(struct radeon_winsys_bo *buffer)
{
   struct r4vk_radv_bo *bo = (struct r4vk_radv_bo *)buffer;
   uint32_t value = p_atomic_read(&bo->references);
   while (value) {
      assert(value != UINT32_MAX);
      const uint32_t old = p_atomic_cmpxchg(&bo->references, value, value + 1);
      if (old == value) return true;
      value = old;
   }
   return false; /* A concurrent final release may still be removing its node. */
}
static void destroy_bo(struct radeon_winsys *, struct radeon_winsys_bo *);
static void release_slab_child(struct r4vk_radv_bo *bo)
{
   struct r4vk_radv_ws *ws = bo->ws;
   struct r4vk_radv_bo *root = bo->parent;
   simple_mtx_lock(&ws->residency_mutex);
   const uint32_t first = bo->offset / 4096, count = bo->base.size / 4096;
   for (uint32_t i = first; i < first + count; i++) {
      assert(root->slab_bitmap[i / 64] & (UINT64_C(1) << (i % 64)));
      root->slab_bitmap[i / 64] &= ~(UINT64_C(1) << (i % 64));
   }
   assert(root->slab_children);
   bool last = --root->slab_children == 0;
   if (last) root->slab_retiring = true;
   simple_mtx_unlock(&ws->residency_mutex);
   simple_mtx_destroy(&bo->mutex); free(bo);
   if (last) destroy_bo(&ws->base, &root->base);
}
void r4vk_radv_buffer_release_submission(struct radeon_winsys_bo *buffer)
{
   struct r4vk_radv_bo *root = (struct r4vk_radv_bo *)buffer;
   struct r4vk_radv_ws *ws = root->ws;
   struct r4vk_radv_bo *retired = NULL;
   simple_mtx_lock(&ws->residency_mutex);
   assert(!root->parent && root->submissions);
   if (!--root->submissions) {
      retired = root->retired_children;
      root->retired_children = NULL;
   }
   simple_mtx_unlock(&ws->residency_mutex);
   while (retired) {
      struct r4vk_radv_bo *next = retired->retired_next;
      release_slab_child(retired);
      retired = next;
   }
   destroy_bo(&ws->base, buffer);
}
static void destroy_bo(struct radeon_winsys *base, struct radeon_winsys_bo *buffer)
{
   struct r4vk_radv_ws *ws = (struct r4vk_radv_ws *)base;
   struct r4vk_radv_bo *bo = (struct r4vk_radv_bo *)buffer;
   assert(bo->ws == ws);
   if (!p_atomic_dec_zero(&bo->references)) return;
   if (bo->parent) {
      struct r4vk_radv_bo *root = bo->parent;
      while (bo->map_count) unmap_bo(base, buffer, false);
      simple_mtx_lock(&ws->residency_mutex);
      if (root->submissions) {
         /* The root's native execution loan protects physical pages. Keep
          * this logical extent occupied too, so an unrelated new allocation
          * cannot overwrite a closed shader, upload or command buffer. */
         bo->retired_next = root->retired_children;
         root->retired_children = bo;
         simple_mtx_unlock(&ws->residency_mutex);
         return;
      }
      simple_mtx_unlock(&ws->residency_mutex);
      release_slab_child(bo);
      return;
   }
   assert(!bo->slab_children && !bo->submissions && !bo->retired_children);
   simple_mtx_lock(&ws->residency_mutex);
   list_del(&bo->residency);
   ws->allocated[buffer->initial_domain == RADEON_DOMAIN_VRAM] -= buffer->size;
   simple_mtx_unlock(&ws->residency_mutex);
   /* Broker loans survive public BO/VA handles. Destruction requests ordered
    * retirement; it never treats logical closure as a physical unmap ACK. */
   if (valid(bo->binding)) abandon(ws, bo->binding);
   if (valid(bo->range)) abandon(ws, bo->range);
   if (valid(bo->mapping.lease) && r4draw_gfx_buffer_unmap(&ws->draw, &bo->mapping.lease) != 1) r4vk_radv_lost(ws);
   drop(ws, bo->reference.reference);
   simple_mtx_destroy(&bo->mutex);
   free(bo->slab_bitmap); free(bo);
   r4vk_radv_ws_unref(ws);
}
static void *map_bo(struct radeon_winsys *base, struct radeon_winsys_bo *buffer, bool fixed, void *address)
{
   struct r4vk_radv_ws *ws = (struct r4vk_radv_ws *)base;
   struct r4vk_radv_bo *bo = (struct r4vk_radv_bo *)buffer;
   if (fixed || address || r4vk_radv_is_lost(ws) || buffer->initial_domain != RADEON_DOMAIN_GTT) return NULL;
   simple_mtx_lock(&bo->mutex);
   if (bo->map_count == UINT32_MAX) { simple_mtx_unlock(&bo->mutex); return NULL; }
   if (bo->parent) {
      void *mapped = map_bo(base, &bo->parent->base, false, NULL);
      if (mapped) bo->map_count++;
      simple_mtx_unlock(&bo->mutex);
      return mapped ? (char *)mapped + bo->offset : NULL;
   }
   if (!bo->map_count) {
      int32_t rc = r4draw_gfx_buffer_map_persistent(&ws->draw, &bo->reference.reference,
         R4OS_GFX_BUFFER_MAP_WRITE, 0, buffer->size, &bo->mapping);
      if (rc != 1) { r4vk_radv_status(ws, rc); simple_mtx_unlock(&bo->mutex); return NULL; }
      R4GfxBufferMap *m = &bo->mapping;
      if (m->version != 1 || m->size < sizeof(*m) || m->reserved0 || !valid(m->lease) ||
          !m->cpu_address || (m->cpu_address & 4095) || m->cpu_address > UINTPTR_MAX - buffer->size || m->byte_length != buffer->size ||
          m->cache_policy != R4OS_GFX_BUFFER_CACHE_WRITE_BACK) {
         if (valid(m->lease)) r4draw_gfx_buffer_unmap(&ws->draw, &m->lease);
         memset(m, 0, sizeof(*m)); r4vk_radv_lost(ws); simple_mtx_unlock(&bo->mutex); return NULL;
      }
   }
   bo->map_count++;
   void *result = (void *)(uintptr_t)bo->mapping.cpu_address;
   simple_mtx_unlock(&bo->mutex);
   return result;
}
static void unmap_bo(struct radeon_winsys *base, struct radeon_winsys_bo *buffer, bool replace)
{
   struct r4vk_radv_ws *ws = (struct r4vk_radv_ws *)base;
   struct r4vk_radv_bo *bo = (struct r4vk_radv_bo *)buffer;
   simple_mtx_lock(&bo->mutex);
   if (replace || !bo->map_count) { r4vk_radv_lost(ws); simple_mtx_unlock(&bo->mutex); return; }
   if (bo->parent) {
      bo->map_count--;
      unmap_bo(base, &bo->parent->base, false);
      simple_mtx_unlock(&bo->mutex);
      return;
   }
   if (!--bo->map_count) {
      if (r4draw_gfx_buffer_unmap(&ws->draw, &bo->mapping.lease) != 1) r4vk_radv_lost(ws);
      memset(&bo->mapping, 0, sizeof(bo->mapping));
   }
   simple_mtx_unlock(&bo->mutex);
}
static VkResult allocate_backing(struct radeon_winsys *base, uint64_t bytes,
   unsigned alignment, bool vram, enum radeon_bo_flag flags,
   struct radeon_winsys_bo **out)
{
   struct r4vk_radv_ws *ws = (struct r4vk_radv_ws *)base;
   struct r4vk_radv_bo *bo = calloc(1, sizeof(*bo));
   if (!bo) return VK_ERROR_OUT_OF_HOST_MEMORY;
   bo->ws = ws; bo->references = 1;
   VkResult result;
   if (vram) result = allocate_vram(ws, bytes, &bo->reference);
   else {
      R4GfxBufferDescriptor request = { .version = 1, .size = sizeof(request), .byte_length = bytes, .alignment = 4096, .usage = 15 };
      int32_t rc = r4draw_gfx_buffer_create(&ws->draw, &request, &bo->reference);
      result = rc == 1 ? VK_SUCCESS : r4vk_radv_status(ws, rc);
   }
   if (result != VK_SUCCESS) goto fail;
   result = check_backing(ws, &bo->reference, vram, bytes);
   if (result != VK_SUCCESS) goto fail;
   R4GfxVirtualRequest request = { .kind = 1, .byte_length = bytes, .alignment = alignment, .location = vram };
   R4GfxVirtualStatus ready;
   result = create(ws, &request, 0, &ready);
   if (result != VK_SUCCESS) goto fail;
   bo->range = ready.resource;
   bo->base.va = ready.address;
   request = (R4GfxVirtualRequest){ .kind = 2, .byte_length = bytes, .parent = bo->range, .reference = bo->reference.reference };
   result = create(ws, &request, bo->base.va, &ready);
   if (result != VK_SUCCESS) goto fail;
   bo->binding = ready.resource;
   bo->base.size = bytes;
   bo->base.initial_domain = vram ? RADEON_DOMAIN_VRAM : RADEON_DOMAIN_GTT;
   bo->base.is_local = bo->base.use_global_list = true;
   bo->base.vram_no_cpu_access = vram;
   simple_mtx_init(&bo->mutex, mtx_plain);
   r4vk_radv_ws_ref(ws);
   simple_mtx_lock(&ws->residency_mutex);
   bo->base.obj_id = ++ws->next_id;
   ws->allocated[vram] += bytes;
   list_addtail(&bo->residency, &ws->residency);
   simple_mtx_unlock(&ws->residency_mutex);
   if (flags & RADEON_FLAG_ZERO_VRAM) {
      void *mapped = map_bo(base, &bo->base, false, NULL);
      if (!mapped) { destroy_bo(base, &bo->base); return VK_ERROR_MEMORY_MAP_FAILED; }
      memset(mapped, 0, bytes);
      unmap_bo(base, &bo->base, false);
   }
   *out = &bo->base;
   return VK_SUCCESS;
fail:
   if (valid(bo->binding)) abandon(ws, bo->binding);
   if (valid(bo->range)) abandon(ws, bo->range);
   if (valid(bo->reference.reference)) drop(ws, bo->reference.reference);
   free(bo);
   return r4vk_radv_is_lost(ws) ? VK_ERROR_DEVICE_LOST : result;
}
/* Public Vulkan memory objects suballocate ordinary canonical root BOs.
 * Root bindings stay bounded; each logical allocation owns actual padding. */
#define SLAB_BYTES (UINT64_C(64)*1024*1024)
#define SLAB_PAGES (SLAB_BYTES / 4096)
static bool slab_reserve(struct r4vk_radv_bo *root, uint64_t bytes,
                         unsigned alignment, uint64_t *offset)
{
   const uint32_t count = bytes / 4096, step = MAX2(alignment, 65536) / 4096;
   for (uint32_t start = 0; start + count <= SLAB_PAGES;) {
      uint32_t i = start;
      while (i < start + count && !(root->slab_bitmap[i / 64] & (UINT64_C(1) << (i % 64)))) i++;
      if (i == start + count) {
         for (i = start; i < start + count; i++) root->slab_bitmap[i / 64] |= UINT64_C(1) << (i % 64);
         root->slab_children++;
         *offset = (uint64_t)start * 4096;
         return true;
      }
      start = (i + step) & ~(step - 1);
   }
   return false;
}
static VkResult allocate_slab(struct radeon_winsys *base, uint64_t bytes,
   unsigned alignment, bool vram, enum radeon_bo_flag flags,
   struct radeon_winsys_bo **out)
{
   struct r4vk_radv_ws *ws = (struct r4vk_radv_ws *)base;
   struct r4vk_radv_bo *child = calloc(1, sizeof(*child));
   if (!child) return VK_ERROR_OUT_OF_HOST_MEMORY;
   struct r4vk_radv_bo *root = NULL;
   uint64_t offset = 0;
   VkResult result = VK_SUCCESS;
   /* Serialize pool growth independently from the short residency boundary.
    * No heap or broker call spans residency_mutex. Destruction never takes
    * slab_mutex, and the final-child mark prevents racing root reuse. */
   simple_mtx_lock(&ws->slab_mutex);
   simple_mtx_lock(&ws->residency_mutex);
   list_for_each_entry(struct r4vk_radv_bo, candidate, &ws->residency, residency) {
      if (candidate->slab_bitmap && !candidate->slab_retiring &&
          candidate->base.initial_domain == (vram ? RADEON_DOMAIN_VRAM : RADEON_DOMAIN_GTT) &&
          slab_reserve(candidate, bytes, alignment, &offset)) { root = candidate; break; }
   }
   simple_mtx_unlock(&ws->residency_mutex);
   if (!root) {
      uint64_t *bitmap = calloc(SLAB_PAGES / 64, sizeof(uint64_t));
      if (!bitmap) { result = VK_ERROR_OUT_OF_HOST_MEMORY; goto fail; }
      struct radeon_winsys_bo *allocated = NULL;
      result = allocate_backing(base, SLAB_BYTES, 1024*1024, vram, 0, &allocated);
      if (result != VK_SUCCESS) { free(bitmap); goto fail; }
      root = (struct r4vk_radv_bo *)allocated;
      simple_mtx_lock(&ws->residency_mutex);
      root->slab_bitmap = bitmap;
      bool reserved = slab_reserve(root, bytes, alignment, &offset);
      assert(reserved);
      simple_mtx_unlock(&ws->residency_mutex);
   }
   child->ws = ws; child->references = 1; child->parent = root; child->offset = offset;
   child->base = root->base;
   child->base.va += offset; child->base.size = bytes;
   child->reference = root->reference; child->range = root->range; child->binding = root->binding;
   simple_mtx_init(&child->mutex, mtx_plain);
   simple_mtx_lock(&ws->residency_mutex);
   child->base.obj_id = ++ws->next_id;
   simple_mtx_unlock(&ws->residency_mutex);
   simple_mtx_unlock(&ws->slab_mutex);
   if (flags & RADEON_FLAG_ZERO_VRAM) {
      void *mapped = map_bo(base, &child->base, false, NULL);
      if (!mapped) { destroy_bo(base, &child->base); return VK_ERROR_MEMORY_MAP_FAILED; }
      memset(mapped, 0, bytes);
      unmap_bo(base, &child->base, false);
   }
   *out = &child->base;
   return VK_SUCCESS;
fail:
   simple_mtx_unlock(&ws->slab_mutex);
   free(child);
   return result;
}

static VkResult allocate_bo(struct radeon_winsys *base, uint64_t bytes, unsigned alignment,
   enum radeon_bo_domain domain, enum radeon_bo_flag flags, unsigned priority,
   uint64_t address, struct radeon_winsys_bo **out)
{
   struct r4vk_radv_ws *ws = (struct r4vk_radv_ws *)base;
   if (r4vk_radv_is_lost(ws)) return VK_ERROR_DEVICE_LOST;
   const unsigned supported = RADEON_FLAG_GTT_WC | RADEON_FLAG_CPU_ACCESS | RADEON_FLAG_NO_CPU_ACCESS |
      RADEON_FLAG_NO_INTERPROCESS_SHARING | RADEON_FLAG_READ_ONLY | RADEON_FLAG_32BIT |
      RADEON_FLAG_PREFER_LOCAL_BO | RADEON_FLAG_ZERO_VRAM | RADEON_FLAG_DISCARDABLE |
      RADEON_FLAG_VM_PAD_1PAGE | RADEON_FLAG_VM_UPDATE_WAIT;
   if ((flags & ~supported) || address || priority > 31 ||
       (domain != RADEON_DOMAIN_GTT && domain != RADEON_DOMAIN_VRAM && domain != RADEON_DOMAIN_VRAM_GTT))
      return VK_ERROR_FEATURE_NOT_PRESENT;
   if ((flags & RADEON_FLAG_CPU_ACCESS) && (flags & RADEON_FLAG_NO_CPU_ACCESS)) return VK_ERROR_FEATURE_NOT_PRESENT;
   /* Internal RADV shader/descriptor arenas request VRAM but require CPU
    * access. Their native placement is coherent system backing; explicit
    * NO_CPU_ACCESS allocations retain device-local ownership. */
   bool vram = (domain & RADEON_DOMAIN_VRAM) && (flags & RADEON_FLAG_NO_CPU_ACCESS);
   if (vram && (flags & (RADEON_FLAG_CPU_ACCESS | RADEON_FLAG_ZERO_VRAM))) return VK_ERROR_FEATURE_NOT_PRESENT;
   if (alignment && !power_of_two(alignment)) return VK_ERROR_OUT_OF_DEVICE_MEMORY;
   if (!alignment) alignment = 4096;
   alignment = MAX2(alignment, 4096);
   if (!power_of_two(alignment) || alignment > ws->facts.max_backing_bytes ||
       !bytes || bytes > ws->facts.max_backing_bytes) return VK_ERROR_OUT_OF_DEVICE_MEMORY;
   bytes = (bytes + 4095) & ~UINT64_C(4095);
   /* GFX9 SMEM may fetch the page following an application allocation.
    * Reserve real backing for that page within the same retained binding.
    * Unlike the Linux read-only alias this consumes one additional page,
    * which participates in the native budget and allocation-size checks.
    * VM_UPDATE_WAIT is already satisfied by create()'s acknowledged bind. */
   if (flags & RADEON_FLAG_VM_PAD_1PAGE) {
      if (bytes > ws->facts.max_backing_bytes - 4096)
         return VK_ERROR_OUT_OF_DEVICE_MEMORY;
      bytes += 4096;
   }
   /* Small private arenas and command streams share bounded root bindings
    * with application allocations. Submission pins delay logical extent
    * reuse until completion, independently of caller/command destruction. */
   const bool pool = flags & RADEON_FLAG_NO_INTERPROCESS_SHARING;
   if (pool && bytes <= 1024*1024 && alignment <= 1024*1024)
      return allocate_slab(base, bytes, alignment, vram, flags, out);
   return allocate_backing(base, bytes, alignment, vram, flags, out);
}
static VkResult create_bo(struct radeon_winsys *base, uint64_t bytes, unsigned alignment,
   enum radeon_bo_domain domain, enum radeon_bo_flag flags, unsigned priority,
   uint64_t address, struct radeon_winsys_bo **out)
{
   extern void r4vk_radv_error_record(VkResult);
   VkResult result = allocate_bo(base, bytes, alignment, domain, flags, priority, address, out);
   r4vk_radv_error_record(result);
   return result;
}
VkResult r4vk_radv_import_buffer(struct r4vk_radv_ws *ws, const R4GfxBufferHandle *source,
   struct radeon_winsys_bo **out, R4GfxBufferDescriptor *descriptor)
{
   if (!out || !descriptor || !source || !valid(*source)) return VK_ERROR_INVALID_EXTERNAL_HANDLE;
   VkResult result = r4vk_radv_validate(ws);
   if (result != VK_SUCCESS) return result;
   struct r4vk_radv_bo *bo = calloc(1, sizeof(*bo));
   if (!bo) return VK_ERROR_OUT_OF_HOST_MEMORY;
   bo->ws = ws; bo->references = 1;
   /* The producer may release its own reference immediately after import.
    * Describe and bind only the independently retained canonical backing. */
   int32_t rc = r4draw_gfx_buffer_import(&ws->draw, source, &bo->reference);
   if (rc != 1) {
      result = rc == R4OS_GFX_BUFFER_ERROR_INVALID || rc == R4OS_GFX_BUFFER_ERROR_STALE ||
         rc == R4OS_GFX_BUFFER_ERROR_CLOSED ? VK_ERROR_INVALID_EXTERNAL_HANDLE : r4vk_radv_status(ws, rc);
      goto fail;
   }
   const R4GfxBufferReference *ref = &bo->reference;
   if (ref->version != 1 || ref->size < sizeof(*ref) || ref->reserved0 ||
       !valid(ref->buffer) || !valid(ref->reference)) { result = r4vk_radv_lost(ws); goto fail; }
   result = VK_ERROR_INVALID_EXTERNAL_HANDLE;
   if (ref->flags) goto fail;
   R4GfxBufferDescriptor desc;
   rc = r4draw_gfx_buffer_describe(&ws->draw, &ref->reference, &desc);
   if (rc != 1) { result = r4vk_radv_status(ws, rc); goto fail; }
   if (desc.version != 1 || desc.size < sizeof(desc) || desc.reserved0) { result = r4vk_radv_lost(ws); goto fail; }
   const uint32_t transfer = R4OS_GFX_BUFFER_USAGE_TRANSFER_SOURCE | R4OS_GFX_BUFFER_USAGE_TRANSFER_TARGET;
   const uint32_t cpu = R4OS_GFX_BUFFER_USAGE_CPU_READ | R4OS_GFX_BUFFER_USAGE_CPU_WRITE;
   if (!desc.byte_length || (desc.byte_length & 4095) ||
       desc.byte_length > ws->facts.max_backing_bytes || !power_of_two(desc.alignment) ||
       (desc.usage & transfer) != transfer ||
       (desc.usage & ~(transfer | cpu | R4OS_GFX_BUFFER_USAGE_RENDER | R4OS_GFX_BUFFER_USAGE_SCANOUT))) goto fail;
   bool vram = desc.location == R4OS_GFX_BUFFER_LOCATION_DEVICE_LOCAL;
   if (vram) {
      if (desc.adapter_id != ws->facts.backend.binding.adapter_id || !desc.driver_owner ||
          desc.device_generation != ws->facts.backend.memory_generation || (desc.usage & cpu)) goto fail;
   } else if (desc.location != R4OS_GFX_BUFFER_LOCATION_SYSTEM || desc.adapter_id ||
              desc.driver_owner || desc.device_generation || desc.modifier || (desc.usage & cpu) != cpu) goto fail;
   /* Imported extents are never padded or rounded into unowned bytes. WSI
    * image layout admission follows in the VkImage owner before publication. */
   R4GfxVirtualRequest request = {.kind = 1, .byte_length = desc.byte_length, .alignment = 4096, .location = vram};
   R4GfxVirtualStatus ready;
   result = create(ws, &request, 0, &ready);
   if (result != VK_SUCCESS) goto fail;
   bo->range = ready.resource; bo->base.va = ready.address;
   request = (R4GfxVirtualRequest){.kind = 2, .byte_length = desc.byte_length,
      .parent = bo->range, .reference = bo->reference.reference};
   result = create(ws, &request, bo->base.va, &ready);
   if (result != VK_SUCCESS) goto fail;
   bo->binding = ready.resource;
   bo->base.size = desc.byte_length;
   bo->base.initial_domain = vram ? RADEON_DOMAIN_VRAM : RADEON_DOMAIN_GTT;
   bo->base.use_global_list = true;
   bo->base.is_local = false;
   bo->base.vram_no_cpu_access = vram;
   simple_mtx_init(&bo->mutex, mtx_plain);
   r4vk_radv_ws_ref(ws);
   simple_mtx_lock(&ws->residency_mutex);
   bo->base.obj_id = ++ws->next_id;
   ws->allocated[vram] += desc.byte_length;
   list_addtail(&bo->residency, &ws->residency);
   simple_mtx_unlock(&ws->residency_mutex);
   *out = &bo->base; *descriptor = desc;
   return VK_SUCCESS;
fail:
   if (valid(bo->binding)) abandon(ws, bo->binding);
   if (valid(bo->range)) abandon(ws, bo->range);
   if (valid(bo->reference.reference)) drop(ws, bo->reference.reference);
   free(bo);
   return r4vk_radv_is_lost(ws) ? VK_ERROR_DEVICE_LOST : result;
}
static VkResult from_ptr(struct radeon_winsys *ws, void *ptr, uint64_t size, unsigned priority, struct radeon_winsys_bo **out)
{ (void)ws; (void)ptr; (void)size; (void)priority; (void)out; return VK_ERROR_INVALID_EXTERNAL_HANDLE; }
static VkResult from_fd(struct radeon_winsys *ws, int fd, unsigned priority, struct radeon_winsys_bo **out, uint64_t *size)
{ (void)ws; (void)fd; (void)priority; (void)out; (void)size; return VK_ERROR_INVALID_EXTERNAL_HANDLE; }
static bool get_fd(struct radeon_winsys *ws, struct radeon_winsys_bo *bo, int *fd)
{ (void)ws; (void)bo; (void)fd; return false; }
static bool fd_flags(struct radeon_winsys *ws, int fd, enum radeon_bo_domain *d, enum radeon_bo_flag *f)
{ (void)ws; (void)fd; (void)d; (void)f; return false; }
static VkResult bind_virtual(struct radeon_winsys *ws, struct radeon_winsys_bo *parent, uint64_t off, uint64_t size, struct radeon_winsys_bo *bo, uint64_t bo_off)
{ (void)ws; (void)parent; (void)off; (void)size; (void)bo; (void)bo_off; return VK_ERROR_FEATURE_NOT_PRESENT; }
static VkResult resident(struct radeon_winsys *base, struct radeon_winsys_bo *buffer, bool enabled)
{
   (void)enabled;
   struct r4vk_radv_ws *ws = (struct r4vk_radv_ws *)base;
   struct r4vk_radv_bo *bo = (struct r4vk_radv_bo *)buffer;
   return bo->ws == ws && valid(bo->binding) && !r4vk_radv_is_lost(ws) ? VK_SUCCESS : VK_ERROR_DEVICE_LOST;
}
static void set_metadata(struct radeon_winsys *base, struct radeon_winsys_bo *buffer, struct radeon_bo_metadata *md)
{
   struct r4vk_radv_bo *bo = (struct r4vk_radv_bo *)buffer;
   if (md->size_metadata > sizeof(md->metadata)) { r4vk_radv_lost((struct r4vk_radv_ws *)base); return; }
   simple_mtx_lock(&bo->mutex); bo->metadata = *md; simple_mtx_unlock(&bo->mutex);
}
static void get_metadata(struct radeon_winsys *base, struct radeon_winsys_bo *buffer, struct radeon_bo_metadata *md)
{
   (void)base; struct r4vk_radv_bo *bo = (struct r4vk_radv_bo *)buffer;
   simple_mtx_lock(&bo->mutex); *md = bo->metadata; simple_mtx_unlock(&bo->mutex);
}
void r4vk_radv_memory_init(struct radeon_winsys *ws)
{
   ws->buffer_create = create_bo; ws->buffer_destroy = destroy_bo; ws->buffer_map = map_bo;
   ws->buffer_unmap = unmap_bo; ws->buffer_from_ptr = from_ptr; ws->buffer_from_fd = from_fd;
   ws->buffer_get_fd = get_fd; ws->buffer_get_flags_from_fd = fd_flags;
   ws->buffer_virtual_bind = bind_virtual; ws->buffer_make_resident = resident;
   ws->buffer_set_metadata = set_metadata; ws->buffer_get_metadata = get_metadata;
}
