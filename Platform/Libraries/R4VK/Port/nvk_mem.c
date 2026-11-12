/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_nvk_mem.h"
#include "util/cache_ops.h"
#include <stdlib.h>

int r4vk_operation_deadline(uint64_t, uint64_t *, uint64_t *);

struct native_mem {
   struct nvkmd_mem base;
   struct r4vk_nvk_mem_context *context;
   R4GfxBufferReference reference;
   simple_mtx_t mutex;
   R4GfxBufferMap mapping;
   uint32_t map_roles; /* internal and client; NVK counts internal users */
   bool wsi, wsi_acquired; /* resources->residency_mutex, not map mutex */
};
static const struct nvkmd_mem_ops mem_ops;

static VkResult lost(struct r4vk_nvk_mem_context *context)
{
   p_atomic_set(&context->resources->lost, 1);
   return VK_ERROR_DEVICE_LOST;
}
static bool is_lost(const struct r4vk_nvk_mem_context *context)
{
   return r4vk_nvk_va_device_lost(context->resources);
}
static VkResult status(struct r4vk_nvk_mem_context *context, int32_t rc)
{
   switch (rc) {
   case R4OS_GFX_BUFFER_ERROR_OOM:
   case R4OS_GFX_BUFFER_ERROR_BUDGET:
   case R4OS_GFX_BUFFER_ERROR_CAPACITY:
      return VK_ERROR_OUT_OF_DEVICE_MEMORY;
   case R4OS_ERR_NO_FN:
   case R4OS_ERR_NO_GROUP:
   case R4OS_GFX_BUFFER_ERROR_UNSUPPORTED:
   case R4OS_GFX_BUFFER_ERROR_UNAVAILABLE:
      return VK_ERROR_FEATURE_NOT_PRESENT;
   case R4OS_GFX_BUFFER_ERROR_STALE:
   case R4OS_GFX_BUFFER_ERROR_CLOSED:
   case R4OS_GFX_QUEUE_ERROR_WAIT_TIMEOUT:
   case R4OS_GFX_QUEUE_ERROR_WAIT_CANCELLED:
   case R4OS_GFX_QUEUE_ERROR_DEVICE_LOST:
      return lost(context);
   default:
      return VK_ERROR_UNKNOWN;
   }
}
static bool valid(R4GfxBufferHandle handle)
{
   return handle.id && handle.generation && !handle.reserved0;
}
static bool equal(R4GfxBufferHandle a, R4GfxBufferHandle b)
{
   return a.id == b.id && a.generation == b.generation &&
          a.reserved0 == b.reserved0;
}
static bool power_of_two(uint64_t value)
{
   return value && !(value & (value - 1));
}
static struct native_mem *native(struct nvkmd_mem *base)
{
   assert(base->ops == &mem_ops);
   return container_of(base, struct native_mem, base);
}

VkResult r4vk_nvk_mem_context_init(struct r4vk_nvk_mem_context *context,
                                  struct r4vk_nvk_va_context *resources,
                                  bool host_coherent)
{
   if (!context || !resources || !resources->dev || !r4draw_available(&resources->draw) ||
       resources->reference != r4vk_nvk_mem_reference)
      return VK_ERROR_INITIALIZATION_FAILED;
   const R4Draw *draw = &resources->draw;
   if (!R4DRAW_HAS(draw, gfx_buffer_create) || !R4DRAW_HAS(draw, gfx_buffer_describe) ||
       !R4DRAW_HAS(draw, gfx_buffer_release) || !R4DRAW_HAS(draw, gfx_buffer_map_persistent) ||
       !R4DRAW_HAS(draw, gfx_buffer_unmap) || !R4DRAW_HAS(draw, gfx_native_start) ||
       !R4DRAW_HAS(draw, gfx_native_wait) || !R4DRAW_HAS(draw, gfx_native_receive) || !R4DRAW_HAS(draw, gfx_native_close))
      return VK_ERROR_FEATURE_NOT_PRESENT;
   *context = (struct r4vk_nvk_mem_context) {
      .resources = resources, .host_coherent = host_coherent,
   };
   return VK_SUCCESS;
}

static void drop(struct r4vk_nvk_mem_context *context, R4GfxBufferHandle handle)
{
   if (r4draw_gfx_buffer_release(&context->resources->draw, &handle) != 1)
      lost(context); /* The resident BO owner retains uncertain cleanup. */
}
static void close_request(struct r4vk_nvk_mem_context *context,
                          R4GfxBufferHandle request)
{
   if (r4draw_gfx_native_close(&context->resources->draw, &request) != 1)
      lost(context);
}
static VkResult allocate_vram(struct r4vk_nvk_mem_context *context,
                              uint64_t bytes, R4GfxBufferReference *out)
{
   const struct r4vk_nvk_va_context *resources = context->resources;
   R4GfxNativeAllocation request = {
      .version = 1, .size = sizeof(request), .adapter_id = resources->adapter_id,
      .memory_generation = resources->memory_generation,
      .byte_length = bytes, .usage = R4OS_GFX_BUFFER_USAGE_TRANSFER_SOURCE |
                                    R4OS_GFX_BUFFER_USAGE_TRANSFER_TARGET,
   };
   uint64_t ticks;
   if (r4vk_operation_deadline(5000000000ull, &request.deadline_ns, &ticks) != 0)
      return lost(context);
   R4GfxNativeStatus initial;
   int32_t rc = r4draw_gfx_native_start(&resources->draw, &request, &initial);
   if (rc != 1) return status(context, rc);
   if (!valid(initial.request)) return lost(context);
   R4GfxNativeStatus ready;
   rc = r4draw_gfx_native_wait(&resources->draw, &initial.request, ticks, &ready);
   if (rc != 1) {
      VkResult result = status(context, rc);
      close_request(context, initial.request);
      return is_lost(context) ? VK_ERROR_DEVICE_LOST : result;
   }
   if (ready.version != 1 || ready.size < sizeof(ready) || ready.reserved0 ||
       !equal(ready.request, initial.request) || ready.phase != 2 ||
       (ready.flags & ~1u) || ready.deadline_ns != request.deadline_ns ||
       !ready.completed_ns) {
      close_request(context, initial.request);
      return lost(context);
   }
   if (ready.result != 1) {
      VkResult result = status(context, ready.result);
      close_request(context, initial.request);
      return is_lost(context) ? VK_ERROR_DEVICE_LOST : result;
   }
   rc = r4draw_gfx_native_receive(&resources->draw, &initial.request, out);
   if (rc == 1) return VK_SUCCESS; /* Receive consumes the request. */
   VkResult result = status(context, rc);
   close_request(context, initial.request);
   return is_lost(context) ? VK_ERROR_DEVICE_LOST : result;
}
static VkResult check_backing(struct r4vk_nvk_mem_context *context,
                              const R4GfxBufferReference *ref, bool vram,
                              uint64_t bytes)
{
   if (ref->version != 1 || ref->size < sizeof(*ref) || ref->flags ||
       ref->reserved0 || !valid(ref->buffer) || !valid(ref->reference))
      return lost(context);
   R4GfxBufferDescriptor desc;
   const struct r4vk_nvk_va_context *resources = context->resources;
   int32_t rc = r4draw_gfx_buffer_describe(&resources->draw, &ref->reference, &desc);
   if (rc != 1) return status(context, rc);
   if (desc.version != 1 || desc.size < sizeof(desc) || desc.reserved0 ||
       desc.byte_length < bytes || !power_of_two(desc.alignment) ||
       desc.format != R4OS_GFX_BUFFER_FORMAT_BYTES || desc.modifier ||
       desc.width || desc.height || desc.plane_count ||
       desc.location != (vram ? R4OS_GFX_BUFFER_LOCATION_DEVICE_LOCAL : R4OS_GFX_BUFFER_LOCATION_SYSTEM) ||
       (desc.usage & (vram ? 12u : 15u)) != (vram ? 12u : 15u))
      return lost(context);
   for (unsigned i = 0; i < 4; i++)
      if (desc.plane_offsets[i] || desc.plane_pitches[i]) return lost(context);
   if (vram) {
      if (desc.adapter_id != resources->adapter_id || !desc.driver_owner ||
          desc.device_generation != resources->memory_generation || (desc.usage & 3))
         return lost(context);
   } else if (desc.adapter_id || desc.driver_owner || desc.device_generation) {
      return lost(context);
   }
   return VK_SUCCESS;
}

/* Both allocation and import acquire exactly the same VA, residency and
 * parent-device lifetime. The caller still owns the BO reference on failure. */
static VkResult bind_backing(struct native_mem *mem,
                             struct vk_object_base *log_obj,
                             uint64_t size, uint64_t alignment,
                             enum nvkmd_mem_flags flags, bool vram,
                             uint8_t pte_kind)
{
   struct r4vk_nvk_mem_context *context = mem->context;
   nvkmd_mem_init(context->resources->dev, &mem->base, &mem_ops, flags, size, alignment);
   simple_mtx_init(&mem->mutex, mtx_plain);
   VkResult result = nvkmd_dev_alloc_va(mem->base.dev, log_obj,
      vram ? 0 : NVKMD_VA_GART, pte_kind, size, alignment, 0, &mem->base.va);
   if (result != VK_SUCCESS) goto fail;
   result = nvkmd_va_bind_mem(mem->base.va, log_obj, 0, &mem->base, 0, size);
   if (result != VK_SUCCESS) {
      nvkmd_va_free(mem->base.va);
      goto fail;
   }
   r4vk_nvk_resources_ref(context->resources);
   return VK_SUCCESS;
fail:
   simple_mtx_destroy(&mem->mutex);
   simple_mtx_destroy(&mem->base.map_mutex);
   return result;
}

static VkResult allocate_mem(struct r4vk_nvk_mem_context *context,
                              struct vk_object_base *log_obj,
                              uint64_t size, uint64_t alignment,
                              enum nvkmd_mem_flags flags, uint8_t pte_kind,
                              struct nvkmd_mem **out)
{
   if (!context || !context->resources || !out) return VK_ERROR_INITIALIZATION_FAILED;
   if (is_lost(context)) return VK_ERROR_DEVICE_LOST;
   const unsigned placement = flags & NVKMD_MEM_PLACEMENT_FLAGS;
   if (!power_of_two(placement) ||
       (flags & ~(NVKMD_MEM_PLACEMENT_FLAGS | NVKMD_MEM_CAN_MAP | NVKMD_MEM_COHERENT)))
      return VK_ERROR_FEATURE_NOT_PRESENT;
   if ((flags & NVKMD_MEM_COHERENT) && !context->host_coherent)
      return VK_ERROR_FEATURE_NOT_PRESENT;
   /* BAR mappings are not part of this backend. Mappable LOCAL allocations
    * use GART; an explicit VRAM request never silently becomes host memory. */
   const bool vram = placement == NVKMD_MEM_VRAM ||
      (placement == NVKMD_MEM_LOCAL && !(flags & (NVKMD_MEM_CAN_MAP | NVKMD_MEM_COHERENT)));
   if (vram && (flags & (NVKMD_MEM_CAN_MAP | NVKMD_MEM_COHERENT)))
      return VK_ERROR_FEATURE_NOT_PRESENT;
   if (alignment && !power_of_two(alignment)) return VK_ERROR_UNKNOWN;
   const uint64_t minimum = context->resources->dev->pdev->bind_align_B;
   if (alignment < minimum) alignment = minimum;
   if (!size || alignment > UINT32_MAX || size > UINT64_MAX - (alignment - 1))
      return VK_ERROR_OUT_OF_DEVICE_MEMORY;
   size = (size + alignment - 1) & ~(alignment - 1);
   struct native_mem *mem = calloc(1, sizeof(*mem));
   if (!mem) return VK_ERROR_OUT_OF_HOST_MEMORY;
   mem->context = context;
   VkResult result;
   if (vram) {
      result = allocate_vram(context, size, &mem->reference);
   } else {
      /* GPU alignment belongs to VA, not the unrelated CPU virtual address. */
      const R4GfxBufferDescriptor descriptor = {
         .version = 1, .size = sizeof(descriptor), .byte_length = size,
         .alignment = 4096, .usage = 15,
      };
      int32_t rc = r4draw_gfx_buffer_create(&context->resources->draw, &descriptor, &mem->reference);
      result = rc == 1 ? VK_SUCCESS : status(context, rc);
   }
   if (result != VK_SUCCESS) goto fail_metadata;
   result = check_backing(context, &mem->reference, vram, size);
   if (result != VK_SUCCESS) goto fail_reference;
   if (!vram && context->host_coherent) flags |= NVKMD_MEM_COHERENT;
   result = bind_backing(mem, log_obj, size, alignment, flags, vram, pte_kind);
   if (result != VK_SUCCESS) goto fail_reference;
   *out = &mem->base;
   return VK_SUCCESS;
fail_reference:
   if (valid(mem->reference.reference)) drop(context, mem->reference.reference);
fail_metadata:
   free(mem);
   return is_lost(context) ? VK_ERROR_DEVICE_LOST : result;
}

VkResult r4vk_nvk_alloc_mem(struct r4vk_nvk_mem_context *context,
                           struct vk_object_base *log_obj,
                           uint64_t size, uint64_t alignment,
                           enum nvkmd_mem_flags flags, struct nvkmd_mem **out)
{
   return allocate_mem(context, log_obj, size, alignment, flags, 0, out);
}

VkResult r4vk_nvk_alloc_tiled_mem(struct r4vk_nvk_mem_context *context,
                                 struct vk_object_base *log_obj,
                                 uint64_t size, uint64_t alignment,
                                 uint8_t pte_kind, uint16_t tile_mode,
                                 enum nvkmd_mem_flags flags, struct nvkmd_mem **out)
{
   if (!context || !context->resources || !out) return VK_ERROR_INITIALIZATION_FAILED;
   if (is_lost(context)) return VK_ERROR_DEVICE_LOST;
   /* Uncompressed native mappings carry kind in the VA owner; GOB height
    * and depth belong to NIL's image/command descriptors, not BO metadata.
    * No compression allocation, dma-buf flags or second alias is needed. */
   if (!context->resources->image_layouts || !pte_kind || pte_kind > 6 ||
       (tile_mode & ~0x770u) || ((tile_mode >> 4) & 7) > 5 ||
       ((tile_mode >> 8) & 7) > 5)
      return VK_ERROR_FEATURE_NOT_PRESENT;
   return allocate_mem(context, log_obj, size, alignment, flags, pte_kind, out);
}

VkResult r4vk_nvk_import_mem(struct r4vk_nvk_mem_context *context,
                            struct vk_object_base *log_obj,
                            const R4GfxBufferHandle *source,
                            struct nvkmd_mem **out,
                            R4GfxBufferDescriptor *descriptor)
{
   if (!context || !context->resources || !out || !descriptor)
      return VK_ERROR_INITIALIZATION_FAILED;
   if (is_lost(context)) return VK_ERROR_DEVICE_LOST;
   if (!source || !valid(*source)) return VK_ERROR_INVALID_EXTERNAL_HANDLE;
   const struct r4vk_nvk_va_context *resources = context->resources;
   if (!R4DRAW_HAS(&resources->draw, gfx_buffer_import)) return VK_ERROR_FEATURE_NOT_PRESENT;
   struct native_mem *mem = calloc(1, sizeof(*mem));
   if (!mem) return VK_ERROR_OUT_OF_HOST_MEMORY;
   mem->context = context;
   /* Share before describe: after successful import the producer can close
    * its own reference without invalidating our metadata or GPU backing. */
   int32_t rc = r4draw_gfx_buffer_import(&resources->draw, source, &mem->reference);
   VkResult result;
   if (rc != 1) {
      /* A stale/closed caller handle is not a reset of this Vulkan device. */
      result = rc == R4OS_GFX_BUFFER_ERROR_INVALID ||
               rc == R4OS_GFX_BUFFER_ERROR_STALE ||
               rc == R4OS_GFX_BUFFER_ERROR_CLOSED ?
               VK_ERROR_INVALID_EXTERNAL_HANDLE : status(context, rc);
      goto fail_metadata;
   }
   const R4GfxBufferReference *ref = &mem->reference;
   if (ref->version != 1 || ref->size < sizeof(*ref) || ref->reserved0 ||
       !valid(ref->buffer) || !valid(ref->reference)) {
      result = lost(context);
      goto fail_reference;
   }
   /* Native submissions use mutable residency loans. Immutable capture and
    * mapping-only references must never acquire stronger access here. */
   result = VK_ERROR_INVALID_EXTERNAL_HANDLE;
   if (ref->flags) goto fail_reference;
   R4GfxBufferDescriptor desc;
   rc = r4draw_gfx_buffer_describe(&resources->draw, &ref->reference, &desc);
   if (rc != 1) { result = status(context, rc); goto fail_reference; }
   if (desc.version != 1 || desc.size < sizeof(desc) || desc.reserved0) {
      result = lost(context);
      goto fail_reference;
   }
   const uint64_t alignment = resources->dev->pdev->bind_align_B;
   const uint32_t transfer = R4OS_GFX_BUFFER_USAGE_TRANSFER_SOURCE |
                             R4OS_GFX_BUFFER_USAGE_TRANSFER_TARGET;
   const uint32_t cpu = R4OS_GFX_BUFFER_USAGE_CPU_READ | R4OS_GFX_BUFFER_USAGE_CPU_WRITE;
   /* Do not round an imported extent up: those extra bytes are not ours.
    * The descriptor's alignment describes backing, not the new GPU VA. */
   if (!desc.byte_length || (desc.byte_length & (alignment - 1)) ||
       !power_of_two(desc.alignment) || (desc.usage & transfer) != transfer ||
       (desc.usage & ~(transfer | cpu | R4OS_GFX_BUFFER_USAGE_RENDER | R4OS_GFX_BUFFER_USAGE_SCANOUT)))
      goto fail_reference;
   bool vram;
   enum nvkmd_mem_flags flags = NVKMD_MEM_SHARED;
   if (desc.location == R4OS_GFX_BUFFER_LOCATION_DEVICE_LOCAL) {
      if (desc.adapter_id != resources->adapter_id || !desc.driver_owner ||
          desc.device_generation != resources->memory_generation || (desc.usage & cpu))
         goto fail_reference;
      vram = true;
      flags |= NVKMD_MEM_VRAM;
   } else if (desc.location == R4OS_GFX_BUFFER_LOCATION_SYSTEM) {
      if (desc.adapter_id || desc.driver_owner || desc.device_generation || desc.modifier)
         goto fail_reference;
      vram = false;
      flags |= NVKMD_MEM_GART;
      if ((desc.usage & cpu) == cpu) flags |= NVKMD_MEM_CAN_MAP;
      if (context->host_coherent) flags |= NVKMD_MEM_COHERENT;
   } else {
      goto fail_reference;
   }
   result = bind_backing(mem, log_obj, desc.byte_length, alignment, flags, vram, 0);
   if (result != VK_SUCCESS) goto fail_reference;
   *out = &mem->base;
   *descriptor = desc;
   return VK_SUCCESS;
fail_reference:
   if (valid(mem->reference.reference)) drop(context, mem->reference.reference);
fail_metadata:
   free(mem);
   return is_lost(context) ? VK_ERROR_DEVICE_LOST : result;
}

VkResult r4vk_nvk_mem_reference(struct nvkmd_mem *base, R4GfxBufferReference *out)
{
   if (!base || base->ops != &mem_ops || !out) return VK_ERROR_UNKNOWN;
   struct native_mem *mem = native(base);
   if (is_lost(mem->context)) return VK_ERROR_DEVICE_LOST;
   *out = mem->reference;
   return VK_SUCCESS;
}

uint32_t r4vk_nvk_mem_access(struct nvkmd_mem *base)
{
   struct native_mem *mem = native(base);
   return !mem->wsi || mem->wsi_acquired;
}

VkResult r4vk_nvk_mem_wsi_acquired(struct nvkmd_mem *base, bool acquired)
{
   if (!base || base->ops != &mem_ops) return VK_ERROR_UNKNOWN;
   struct native_mem *mem = native(base);
   struct r4vk_nvk_va_context *resources = mem->context->resources;
   if (is_lost(mem->context)) return VK_ERROR_DEVICE_LOST;
   simple_mtx_lock(&resources->residency_mutex);
   mem->wsi = true;
   mem->wsi_acquired = acquired;
   r4vk_nvk_va_access_locked(resources, mem->reference.buffer,
                              r4vk_nvk_mem_access(base));
   simple_mtx_unlock(&resources->residency_mutex);
   return VK_SUCCESS;
}

static VkResult mem_map(struct nvkmd_mem *base, struct vk_object_base *log_obj,
                        enum nvkmd_mem_map_flags flags, void *fixed, void **out)
{
   (void)log_obj;
   struct native_mem *mem = native(base);
   if (is_lost(mem->context)) return VK_ERROR_DEVICE_LOST;
   if (!(base->flags & NVKMD_MEM_CAN_MAP) || fixed || !out ||
       (flags & ~(NVKMD_MEM_MAP_RDWR | NVKMD_MEM_MAP_CLIENT)) ||
       !(flags & NVKMD_MEM_MAP_RDWR)) return VK_ERROR_MEMORY_MAP_FAILED;
   const uint32_t role = flags & NVKMD_MEM_MAP_CLIENT ? 2 : 1;
   simple_mtx_lock(&mem->mutex);
   VkResult result = VK_SUCCESS;
   if (mem->map_roles & role) { result = VK_ERROR_MEMORY_MAP_FAILED; goto done; }
   if (!mem->map_roles) {
      R4GfxBufferMap map;
      int32_t rc = r4draw_gfx_buffer_map_persistent(&mem->context->resources->draw,
         &mem->reference.reference, R4OS_GFX_BUFFER_MAP_WRITE, 0, base->size_B, &map);
      if (rc != 1) {
         result = status(mem->context, rc);
         if (result == VK_ERROR_UNKNOWN || result == VK_ERROR_FEATURE_NOT_PRESENT)
            result = VK_ERROR_MEMORY_MAP_FAILED;
         goto done;
      }
      /* Retain the real lease even if metadata validation fails; cleanup
       * never turns an uncertain mapping into reusable backing. */
      mem->mapping = map;
      if (map.version != 1 || map.size < sizeof(map) || map.reserved0 ||
          !valid(map.lease) || !map.cpu_address || (map.cpu_address & 4095) ||
          map.byte_length != base->size_B || map.cpu_address > UINT64_MAX - map.byte_length ||
          map.cache_policy != R4OS_GFX_BUFFER_CACHE_WRITE_BACK) {
         result = lost(mem->context);
         goto done;
      }
   }
   mem->map_roles |= role;
   *out = (void *)(uintptr_t)mem->mapping.cpu_address;
done:
   simple_mtx_unlock(&mem->mutex);
   return result;
}
static void release_map(struct native_mem *mem)
{
   if (!valid(mem->mapping.lease)) return;
   if (r4draw_gfx_buffer_unmap(&mem->context->resources->draw, &mem->mapping.lease) != 1)
      lost(mem->context);
   else
      mem->mapping = (R4GfxBufferMap){0};
}
static void mem_unmap(struct nvkmd_mem *base, enum nvkmd_mem_map_flags flags,
                      void *map)
{
   struct native_mem *mem = native(base);
   const uint32_t role = flags & NVKMD_MEM_MAP_CLIENT ? 2 : 1;
   simple_mtx_lock(&mem->mutex);
   if (!(mem->map_roles & role) || (uintptr_t)map != mem->mapping.cpu_address) {
      lost(mem->context);
   } else {
      mem->map_roles &= ~role;
      if (!mem->map_roles) release_map(mem);
   }
   simple_mtx_unlock(&mem->mutex);
}
static void mem_free(struct nvkmd_mem *base)
{
   struct native_mem *mem = native(base);
   struct r4vk_nvk_va_context *resources = mem->context->resources;
   assert(!mem->map_roles);
   release_map(mem); /* One final attempt after an uncertain unmap. */
   nvkmd_va_free(base->va); /* Broker loans outlive this C object. */
   drop(mem->context, mem->reference.reference);
   simple_mtx_destroy(&mem->mutex);
   free(mem);
   r4vk_nvk_resources_unref(resources);
}
static VkResult mem_overmap(struct nvkmd_mem *base, struct vk_object_base *log,
                            enum nvkmd_mem_map_flags flags, void *map)
{
   (void)base; (void)log; (void)flags; (void)map;
   return VK_ERROR_FEATURE_NOT_PRESENT;
}
static VkResult mem_export(struct nvkmd_mem *base, struct vk_object_base *log, int *out)
{
   (void)base; (void)log; (void)out;
   return VK_ERROR_INVALID_EXTERNAL_HANDLE;
}
static uint32_t mem_log_handle(struct nvkmd_mem *base)
{
   return native(base)->reference.buffer.id;
}
static void mem_sync(struct nvkmd_mem *base, uint64_t offset, uint64_t bytes)
{
   struct native_mem *mem = native(base);
   /* x86_64 Mesa calls its cache_ops implementation directly. This fallback
    * is still explicit: it flushes CPU cache lines and orders CPU access,
    * never purporting to finish GPU work or invalidate GPU caches. */
   simple_mtx_lock(&mem->mutex);
   if (!mem->map_roles || !bytes || bytes > base->size_B || offset > base->size_B - bytes) {
      lost(mem->context);
   } else {
      util_flush_inval_range((void *)(uintptr_t)(mem->mapping.cpu_address + offset), bytes);
   }
   simple_mtx_unlock(&mem->mutex);
}
static const struct nvkmd_mem_ops mem_ops = {
   .free = mem_free, .map = mem_map, .unmap = mem_unmap,
   .overmap = mem_overmap, .sync_to_gpu = mem_sync, .sync_from_gpu = mem_sync,
   .export_dma_buf = mem_export, .log_handle = mem_log_handle,
};
