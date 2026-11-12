/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_nvk_va.h"
#include "r4vk_state.h"
#include <stdlib.h>

/* Implemented by the native time port, using one monotonic-clock snapshot. */
int r4vk_operation_deadline(uint64_t duration_ns, uint64_t *deadline_ns,
                            uint64_t *timeout_ticks);

struct binding {
   struct binding *next;
   struct list_head residency;
   R4GfxBufferHandle handle;
   R4GfxBufferHandle buffer;
   uint32_t access;
   uint64_t offset, bytes;
};
struct native_va {
   struct nvkmd_va base;
   struct r4vk_nvk_va_context *context;
   R4GfxBufferHandle handle;
   simple_mtx_t mutex;
   struct binding *bindings;
};
static const struct nvkmd_va_ops va_ops;

static VkResult lost(struct r4vk_nvk_va_context *context)
{
   p_atomic_set(&context->lost, 1);
   return VK_ERROR_DEVICE_LOST;
}
bool r4vk_nvk_va_device_lost(const struct r4vk_nvk_va_context *context)
{
   return p_atomic_read(&context->lost) != 0;
}
static VkResult status(struct r4vk_nvk_va_context *context, int32_t result)
{
   switch (result) {
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
      /* A positive/unknown result is not a successful Vulkan operation. */
      return VK_ERROR_UNKNOWN;
   }
}
static bool handle_valid(R4GfxBufferHandle handle)
{
   return handle.id && handle.generation && handle.reserved0 == 0;
}
static bool handle_equal(R4GfxBufferHandle a, R4GfxBufferHandle b)
{
   return a.id == b.id && a.generation == b.generation &&
          a.reserved0 == b.reserved0;
}
static bool extent(uint64_t offset, uint64_t bytes, uint64_t limit)
{
   return bytes && bytes <= limit && offset <= limit - bytes;
}
static bool intersects(uint64_t offset, uint64_t bytes, const struct binding *b)
{
   return offset < b->offset + b->bytes && b->offset < offset + bytes;
}
static bool power_of_two(uint64_t value)
{
   return value && (value & (value - 1)) == 0;
}

VkResult r4vk_nvk_va_context_init(struct r4vk_nvk_va_context *context,
                                 struct nvkmd_dev *dev, const R4Draw *draw,
                                 uint32_t adapter, uint64_t generation,
                                 VkResult (*reference)(struct nvkmd_mem *,
                                                       R4GfxBufferReference *))
{
   if (!context || !dev || !dev->pdev || !r4draw_available(draw) ||
       !adapter || !generation || !reference)
      return VK_ERROR_INITIALIZATION_FAILED;
   if (!R4DRAW_HAS(draw, gfx_virtual_start) || !R4DRAW_HAS(draw, gfx_virtual_query) ||
       !R4DRAW_HAS(draw, gfx_virtual_close) || !R4DRAW_HAS(draw, gfx_virtual_wait))
      return VK_ERROR_FEATURE_NOT_PRESENT;
   const uint32_t alignment = dev->pdev->bind_align_B;
   if (alignment < 4096 || !power_of_two(alignment) ||
       !dev->va_start || dev->va_start >= dev->va_end ||
       ((dev->va_start | dev->va_end) & 4095))
      return VK_ERROR_INITIALIZATION_FAILED;
   *context = (struct r4vk_nvk_va_context) {
      .dev = dev, .draw = *draw, .adapter_id = adapter,
      .memory_generation = generation, .reference = reference,
      .backend_va_start = dev->va_start, .backend_va_end = dev->va_end,
   };
   /* Mesa's pinned NVK descriptor-buffer cache prepopulates views over this
    * usable range and has a 12-bit chunk key. Its Nouveau adapter supplies a
    * 512 GiB range, not the GPU's full 49-bit hardware VA. Retain the real
    * bounds above and give this logical resource device the same bounded
    * span, without extending a smaller backend or altering its shared owner. */
   const uint64_t span = MIN2(dev->va_end - dev->va_start, UINT64_C(1) << 39);
   dev->va_end = dev->va_start + span;
   simple_mtx_init(&context->residency_mutex, mtx_plain);
   simple_mtx_init(&context->submit_mutex, mtx_plain);
   list_inithead(&context->residency);
   return VK_SUCCESS;
}

void r4vk_nvk_va_context_finish(struct r4vk_nvk_va_context *context)
{
   assert(list_is_empty(&context->residency));
   assert(!context->submission_tail);
   simple_mtx_destroy(&context->submit_mutex);
   simple_mtx_destroy(&context->residency_mutex);
}

VkResult r4vk_nvk_va_submit(struct r4vk_nvk_va_context *context,
                           bool retain_bindings,
                           const R4GfxQueueHandle *queue,
                           const R4GfxSubmission *submission,
                           const R4GfxNativeSubmission *native,
                           R4GfxFenceStatus *out)
{
   if (r4vk_nvk_va_device_lost(context)) return VK_ERROR_DEVICE_LOST;
   /* NVK may access arbitrary device addresses indirectly. Holding only the
    * pushbuffer's BO would miss descriptors, shaders, BDA and image storage.
    * The common broker takes independent canonical loans before returning;
    * subsequent unbind/free cannot retire any of these GPU mappings early. */
   simple_mtx_lock(&context->residency_mutex);
   size_t count = 0;
   if (retain_bindings) list_for_each_entry(struct binding, b, &context->residency, residency) {
      (void)b;
      if (++count > UINT32_MAX || count > SIZE_MAX / sizeof(R4GfxNativeResource)) {
         simple_mtx_unlock(&context->residency_mutex);
         return VK_ERROR_OUT_OF_HOST_MEMORY;
      }
   }
   R4GfxNativeResource *resources = count ? calloc(count, sizeof(*resources)) : NULL;
   if (count && !resources) {
      simple_mtx_unlock(&context->residency_mutex);
      return VK_ERROR_OUT_OF_HOST_MEMORY;
   }
   size_t index = 0;
   if (retain_bindings) list_for_each_entry(struct binding, b, &context->residency, residency) {
      resources[index++] = (R4GfxNativeResource) {
         .version = 1, .size = sizeof(*resources), .binding = b->handle,
         .access = b->access,
      };
   }
   R4GfxNativeSubmission snapshot = *native;
   snapshot.resource_count = (uint32_t)count;
   snapshot.resources = (uintptr_t)resources;
   const int32_t rc = r4draw_gfx_queue_submit_native(&context->draw, queue,
                                                   submission, &snapshot, out);
   free(resources);
   simple_mtx_unlock(&context->residency_mutex);
   if (rc == R4OS_GFX_QUEUE_OK) return VK_SUCCESS;
   if (rc == R4OS_GFX_QUEUE_ERROR_BUSY || rc == R4OS_GFX_QUEUE_ERROR_CAPACITY)
      return VK_NOT_READY;
   if (rc == R4OS_GFX_QUEUE_ERROR_OOM) return VK_ERROR_OUT_OF_HOST_MEMORY;
   const VkResult result = status(context, rc);
   r4vk_native_failure("native-submit", result, rc,
                        queue->timeline, submission->dependency_count);
   return result;
}

void r4vk_nvk_va_access_locked(struct r4vk_nvk_va_context *context,
                               R4GfxBufferHandle buffer, uint32_t access)
{
   assert(handle_valid(buffer) && access <= 1);
   list_for_each_entry(struct binding, b, &context->residency, residency) {
      if (b->buffer.id == buffer.id && b->buffer.generation == buffer.generation)
         b->access = access;
   }
}

/* Dropping the public handle requests cleanup; it does not assert physical
 * quiescence. The resident broker owns late creation and ordered retirement,
 * including after this caller or this library allocation is gone. */
static void abandon(struct r4vk_nvk_va_context *context, R4GfxBufferHandle handle)
{
   if (r4draw_gfx_virtual_close(&context->draw, &handle, 1) != 1)
      lost(context);
}
static bool matching_status(const R4GfxVirtualStatus *value,
                            R4GfxBufferHandle handle,
                            const R4GfxVirtualRequest *request)
{
   return value->version == 1 && value->size >= sizeof(*value) &&
          handle_equal(value->resource, handle) && value->reserved0 == 0 &&
          value->kind == request->kind && value->byte_length == request->byte_length &&
          handle_equal(value->parent, request->parent) &&
          value->deadline_ns == request->deadline_ns;
}
static VkResult create(struct r4vk_nvk_va_context *context,
                       R4GfxVirtualRequest *request, uint64_t expected_address,
                       R4GfxVirtualStatus *output)
{
   uint64_t ticks;
   if (r4vk_nvk_va_device_lost(context)) return VK_ERROR_DEVICE_LOST;
   if (r4vk_operation_deadline(5000000000ull, &request->deadline_ns, &ticks) != 0)
      return lost(context);
   request->version = 1;
   request->size = sizeof(*request);
   request->adapter_id = context->adapter_id;
   request->memory_generation = context->memory_generation;
   R4GfxVirtualStatus initial;
   int32_t rc = r4draw_gfx_virtual_start(&context->draw, request, &initial);
   if (rc != 1) return status(context, rc);
   if (!handle_valid(initial.resource)) return lost(context);
   R4GfxVirtualStatus ready;
   rc = r4draw_gfx_virtual_wait(&context->draw, &initial.resource, 0, ticks, &ready);
   if (rc != 1) {
      VkResult result = status(context, rc);
      abandon(context, initial.resource);
      return r4vk_nvk_va_device_lost(context) ? VK_ERROR_DEVICE_LOST : result;
   }
   if (!matching_status(&ready, initial.resource, request) || !(ready.flags & 1) ||
       (ready.flags & ~15u)) {
      abandon(context, initial.resource);
      return lost(context);
   }
   if (ready.result != 1) {
      VkResult result = status(context, ready.result);
      abandon(context, initial.resource);
      return r4vk_nvk_va_device_lost(context) ? VK_ERROR_DEVICE_LOST : result;
   }
   if ((ready.flags & 14) || !ready.address ||
       ready.address > UINT64_MAX - ready.byte_length ||
       (expected_address && ready.address != expected_address) ||
       (request->kind == 1 && (ready.address % request->alignment ||
          ready.address < context->backend_va_start || ready.address >= context->backend_va_end ||
          ready.byte_length > context->backend_va_end - ready.address))) {
      abandon(context, initial.resource);
      return lost(context);
   }
   if (request->kind == 1 && (ready.address >= context->dev->va_end ||
       ready.byte_length > context->dev->va_end - ready.address)) {
      /* The shared native allocator chooses the first aligned free range.
       * A valid allocation above NVK's usable subset means that subset has
       * no fitting hole. Drop exactly this reservation and report OOM; an
       * ordinary provider limit is not a stale/invalid backend receipt. */
      abandon(context, initial.resource);
      return r4vk_nvk_va_device_lost(context) ? VK_ERROR_DEVICE_LOST :
         VK_ERROR_OUT_OF_DEVICE_MEMORY;
   }
   *output = ready;
   return VK_SUCCESS;
}

/* Exact unbind waits for the separate retired bit. A logical close or an
 * already-successful creation result is never mistaken for an UNMAP ACK. */
static VkResult retire(struct r4vk_nvk_va_context *context,
                       R4GfxBufferHandle handle)
{
   uint64_t deadline, ticks;
   if (r4vk_operation_deadline(5000000000ull, &deadline, &ticks) != 0) {
      abandon(context, handle);
      return lost(context);
   }
   int32_t rc = r4draw_gfx_virtual_close(&context->draw, &handle, 0);
   if (rc != 1) {
      abandon(context, handle);
      return lost(context);
   }
   R4GfxVirtualStatus retired;
   rc = r4draw_gfx_virtual_wait(&context->draw, &handle, 1, ticks, &retired);
   const bool done = rc == 1 && retired.version == 1 &&
      retired.size >= sizeof(retired) && handle_equal(retired.resource, handle) &&
      retired.reserved0 == 0 && (retired.flags & 6) == 6 && !(retired.flags & ~7u);
   abandon(context, handle);
   return done && !r4vk_nvk_va_device_lost(context) ? VK_SUCCESS : lost(context);
}
static struct native_va *native(struct nvkmd_va *base)
{
   assert(base->ops == &va_ops);
   return container_of(base, struct native_va, base);
}
static void va_free(struct nvkmd_va *base)
{
   struct native_va *va = native(base);
   struct r4vk_nvk_va_context *context = va->context;
   /* Parent close releases all child handles and orders their physical
    * retirement. No C pointer or destructor is retained in the broker. */
   simple_mtx_lock(&context->residency_mutex);
   for (struct binding *b = va->bindings; b; b = b->next)
      list_del(&b->residency);
   simple_mtx_unlock(&context->residency_mutex);
   abandon(va->context, va->handle);
   while (va->bindings) {
      struct binding *next = va->bindings->next;
      free(va->bindings);
      va->bindings = next;
   }
   simple_mtx_destroy(&va->mutex);
   free(va);
   r4vk_nvk_resources_unref(context);
}
static VkResult va_bind(struct nvkmd_va *base, struct vk_object_base *log_obj,
                        uint64_t va_offset, struct nvkmd_mem *mem,
                        uint64_t mem_offset, uint64_t bytes)
{
   (void)log_obj;
   struct native_va *va = native(base);
   struct r4vk_nvk_va_context *context = va->context;
   if (r4vk_nvk_va_device_lost(context)) return VK_ERROR_DEVICE_LOST;
   if (!mem || mem->dev != base->dev ||
       !extent(va_offset, bytes, base->size_B) || !extent(mem_offset, bytes, mem->size_B) ||
       ((va_offset | mem_offset | bytes) & 4095))
      return VK_ERROR_UNKNOWN;
   R4GfxBufferReference reference;
   VkResult result = context->reference(mem, &reference);
   if (result != VK_SUCCESS)
      return result == VK_ERROR_DEVICE_LOST ? lost(context) : result;
   if (reference.version != 1 || reference.size < sizeof(reference) ||
       reference.flags || !handle_valid(reference.reference) ||
       reference.reserved0 || !handle_valid(reference.buffer))
      return VK_ERROR_UNKNOWN;
   struct binding *binding = calloc(1, sizeof(*binding));
   if (!binding) return VK_ERROR_OUT_OF_HOST_MEMORY;
   simple_mtx_lock(&va->mutex);
   /* Non-sparse NVK bindings do not replace live intervals. Sparse/replay
    * features cannot be advertised until their additional rules exist. */
   for (struct binding *b = va->bindings; b; b = b->next) {
      if (intersects(va_offset, bytes, b)) {
         result = VK_ERROR_FEATURE_NOT_PRESENT;
         goto fail;
      }
   }
   R4GfxVirtualRequest request = {
      .kind = 2, .parent = va->handle, .reference = reference.reference,
      .byte_offset = mem_offset, .virtual_offset = va_offset, .byte_length = bytes,
   };
   R4GfxVirtualStatus ready;
   result = create(context, &request, base->addr + va_offset, &ready);
   if (result != VK_SUCCESS) goto fail;
   *binding = (struct binding) {
      .next = va->bindings, .handle = ready.resource, .offset = va_offset, .bytes = bytes,
      .buffer = reference.buffer,
   };
   va->bindings = binding;
   simple_mtx_lock(&context->residency_mutex);
   binding->access = context->access ? context->access(mem) : 1;
   assert(binding->access <= 1);
   list_addtail(&binding->residency, &context->residency);
   simple_mtx_unlock(&context->residency_mutex);
   simple_mtx_unlock(&va->mutex);
   return VK_SUCCESS;
fail:
   simple_mtx_unlock(&va->mutex);
   free(binding);
   return result;
}
static VkResult va_unbind(struct nvkmd_va *base, struct vk_object_base *log_obj,
                          uint64_t offset, uint64_t bytes)
{
   (void)log_obj;
   struct native_va *va = native(base);
   if (r4vk_nvk_va_device_lost(va->context)) return VK_ERROR_DEVICE_LOST;
   if (!extent(offset, bytes, base->size_B) || ((offset | bytes) & 4095))
      return VK_ERROR_UNKNOWN;
   simple_mtx_lock(&va->mutex);
   /* RM unmaps exact previous mappings. Reject unsupported partial splits
    * before changing any binding; never silently unmap a larger interval. */
   for (struct binding *b = va->bindings; b; b = b->next) {
      if (intersects(offset, bytes, b) &&
          (b->offset < offset || b->offset + b->bytes > offset + bytes)) {
         simple_mtx_unlock(&va->mutex);
         return VK_ERROR_FEATURE_NOT_PRESENT;
      }
   }
   struct binding **link = &va->bindings;
   while (*link) {
      struct binding *b = *link;
      if (!intersects(offset, bytes, b)) { link = &b->next; continue; }
      simple_mtx_lock(&va->context->residency_mutex);
      list_del(&b->residency);
      simple_mtx_unlock(&va->context->residency_mutex);
      VkResult result = retire(va->context, b->handle);
      *link = b->next;
      free(b);
      if (result != VK_SUCCESS) {
         simple_mtx_unlock(&va->mutex);
         return result;
      }
   }
   simple_mtx_unlock(&va->mutex);
   return VK_SUCCESS;
}
static const struct nvkmd_va_ops va_ops = {
   .free = va_free, .bind_mem = va_bind, .unbind = va_unbind,
};

VkResult r4vk_nvk_alloc_va(struct r4vk_nvk_va_context *context,
                          struct vk_object_base *log_obj,
                          enum nvkmd_va_flags flags, uint8_t pte_kind,
                          uint64_t size_B, uint64_t align_B,
                          uint64_t fixed_addr, struct nvkmd_va **out)
{
   (void)log_obj;
   if (!context || !context->dev || !out) return VK_ERROR_INITIALIZATION_FAILED;
   if (r4vk_nvk_va_device_lost(context)) return VK_ERROR_DEVICE_LOST;
   if (flags & ~NVKMD_VA_GART || fixed_addr ||
       (pte_kind && (!context->image_layouts || pte_kind > 6)))
      return VK_ERROR_FEATURE_NOT_PRESENT;
   if (!size_B || (align_B && !power_of_two(align_B)))
      return VK_ERROR_UNKNOWN;
   const uint64_t minimum = context->dev->pdev->bind_align_B;
   align_B = MAX2(align_B, minimum);
   if (size_B > UINT64_MAX - (align_B - 1)) return VK_ERROR_OUT_OF_DEVICE_MEMORY;
   size_B = (size_B + align_B - 1) & ~(align_B - 1);
   if (size_B > context->dev->va_end - context->dev->va_start)
      return VK_ERROR_OUT_OF_DEVICE_MEMORY;
   struct native_va *va = calloc(1, sizeof(*va));
   if (!va) return VK_ERROR_OUT_OF_HOST_MEMORY;
   R4GfxVirtualRequest request = {
      .kind = 1, .byte_length = size_B, .alignment = align_B,
      .flags = pte_kind ? R4OS_GFX_VIRTUAL_FLAG_BLOCKLINEAR |
         ((uint32_t)pte_kind << R4OS_GFX_VIRTUAL_LAYOUT_SHIFT) : 0,
      .location = (flags & NVKMD_VA_GART) ? 0 : 1,
   };
   R4GfxVirtualStatus ready;
   VkResult result = create(context, &request, 0, &ready);
   if (result != VK_SUCCESS) { free(va); return result; }
   va->base = (struct nvkmd_va) {
      .ops = &va_ops, .dev = context->dev, .flags = flags,
      .pte_kind = pte_kind, .addr = ready.address, .size_B = size_B,
   };
   va->context = context;
   va->handle = ready.resource;
   simple_mtx_init(&va->mutex, mtx_plain);
   r4vk_nvk_resources_ref(context);
   *out = &va->base;
   return VK_SUCCESS;
}
