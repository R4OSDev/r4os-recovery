/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_nvk_device.h"
#include "r4vk_nvk_mem.h"
#include "r4vk_nvk_submit.h"
#include "vk_sync_timeline.h"
#include <stdlib.h>

struct native_pdev {
   struct nvkmd_pdev base;
   uint32_t references;
   R4Draw draw;
   R4GfxBackendInfo backend;
   struct vk_sync_timeline_type timeline;
   const struct vk_sync_type *sync_types[3];
};
struct native_dev {
   struct nvkmd_dev base;
   uint32_t references;
   struct r4vk_nvk_va_context resources;
   struct r4vk_nvk_mem_context memory;
};
static const struct nvkmd_pdev_ops pdev_ops;
static const struct nvkmd_dev_ops dev_ops;

static struct native_pdev *pdev(struct nvkmd_pdev *base)
{
   assert(base->ops == &pdev_ops);
   return container_of(base, struct native_pdev, base);
}
static struct native_dev *dev(struct nvkmd_dev *base)
{
   assert(base->ops == &dev_ops);
   return container_of(base, struct native_dev, base);
}
static void pdev_unref(struct nvkmd_pdev *base)
{
   struct native_pdev *physical = pdev(base);
   assert(p_atomic_read(&physical->references) > 0);
   if (p_atomic_dec_zero(&physical->references)) free(physical);
}
static void retain(struct r4vk_nvk_va_context *resources)
{
   struct native_dev *device = container_of(resources, struct native_dev, resources);
   assert(p_atomic_read(&device->references) > 0);
   p_atomic_inc(&device->references);
}
static void release(struct r4vk_nvk_va_context *resources)
{
   struct native_dev *device = container_of(resources, struct native_dev, resources);
   assert(p_atomic_read(&device->references) > 0);
   if (!p_atomic_dec_zero(&device->references)) return;
   /* NVK removes each BO from this list before its backend destructor.
    * Standalone VAs also retain the device, including after BO destruction. */
   assert(list_is_empty(&device->base.mems));
   r4vk_nvk_va_context_finish(&device->resources);
   simple_mtx_destroy(&device->base.mems_mutex);
   pdev_unref(device->base.pdev);
   free(device);
}

VkResult r4vk_nvk_check_device(struct nvkmd_dev *base)
{
   if (!base || base->ops != &dev_ops) return VK_ERROR_INITIALIZATION_FAILED;
   struct native_dev *device = dev(base);
   if (r4vk_nvk_va_device_lost(&device->resources)) return VK_ERROR_DEVICE_LOST;
   struct native_pdev *physical = pdev(base->pdev);
   struct r4vk_nvk_architecture current;
   /* Properties are immutable within this exact backend incarnation. A
    * missing, stale or unsupported former incarnation is lost, never a
    * reason to silently attach this logical device to a replacement. */
   VkResult result = r4vk_nvk_query_architecture(&physical->draw,
                                                &physical->backend, &current);
   if (result != VK_SUCCESS) {
      p_atomic_set(&device->resources.lost, 1);
      return VK_ERROR_DEVICE_LOST;
   }
   return VK_SUCCESS;
}

static VkResult create_dev(struct nvkmd_pdev *base,
                           struct vk_object_base *log_obj,
                           struct nvkmd_dev **out)
{
   (void)log_obj;
   if (!out) return VK_ERROR_INITIALIZATION_FAILED;
   struct native_pdev *physical = pdev(base);
   struct r4vk_nvk_architecture current;
   VkResult result = r4vk_nvk_query_architecture(&physical->draw,
                                                &physical->backend, &current);
   if (result != VK_SUCCESS) return VK_ERROR_DEVICE_LOST;
   struct native_dev *device = calloc(1, sizeof(*device));
   if (!device) return VK_ERROR_OUT_OF_HOST_MEMORY;
   device->base.ops = &dev_ops;
   device->base.pdev = base;
   device->base.va_start = current.va_start;
   device->base.va_end = current.va_end;
   result = r4vk_nvk_va_context_init(&device->resources, &device->base,
      &physical->draw, current.binding.adapter_id, current.memory_generation,
      r4vk_nvk_mem_reference);
   if (result != VK_SUCCESS) goto fail;
   device->resources.access = r4vk_nvk_mem_access;
   device->resources.image_layouts = current.image_layouts;
   /* Only explicit revision2 native mapping-policy facts permit coherence.
    * Revision1 and successful CPU mapping alone supply no such guarantee. */
   result = r4vk_nvk_mem_context_init(&device->memory, &device->resources,
                                      current.host_coherent);
   if (result != VK_SUCCESS) {
      r4vk_nvk_va_context_finish(&device->resources);
      goto fail;
   }
   list_inithead(&device->base.mems);
   simple_mtx_init(&device->base.mems_mutex, mtx_plain);
   device->references = 1;
   device->resources.retain = retain;
   device->resources.release = release;
   p_atomic_inc(&physical->references);
   *out = &device->base;
   return VK_SUCCESS;
fail:
   free(device);
   return result;
}
static void destroy_dev(struct nvkmd_dev *base)
{
   struct native_dev *device = dev(base);
   /* Retained children may still be cleaned up; further resource use cannot
    * succeed. The resident kernel, not this C allocation, owns late GPU work. */
   p_atomic_set(&device->resources.lost, 1);
   r4vk_nvk_submit_finish(&device->resources);
   release(&device->resources);
}
static VkResult alloc_mem(struct nvkmd_dev *base, struct vk_object_base *log,
                          uint64_t size, uint64_t alignment,
                          enum nvkmd_mem_flags flags, struct nvkmd_mem **out)
{
   VkResult result = r4vk_nvk_check_device(base);
   if (result != VK_SUCCESS) return result;
   return r4vk_nvk_alloc_mem(&dev(base)->memory, log, size, alignment, flags, out);
}
static VkResult alloc_va(struct nvkmd_dev *base, struct vk_object_base *log,
                         enum nvkmd_va_flags flags, uint8_t kind, uint64_t size,
                         uint64_t alignment, uint64_t fixed, struct nvkmd_va **out)
{
   VkResult result = r4vk_nvk_check_device(base);
   if (result != VK_SUCCESS) return result;
   return r4vk_nvk_alloc_va(&dev(base)->resources, log, flags, kind,
                           size, alignment, fixed, out);
}
VkResult r4vk_nvk_import_buffer(struct nvkmd_dev *base,
                               struct vk_object_base *log,
                               const R4GfxBufferHandle *source,
                               struct nvkmd_mem **out,
                               R4GfxBufferDescriptor *descriptor)
{
   VkResult result = r4vk_nvk_check_device(base);
   if (result != VK_SUCCESS) return result;
   result = r4vk_nvk_import_mem(&dev(base)->memory, log, source, out, descriptor);
   if (result == VK_SUCCESS) {
      /* Private imports bypass nvkmd_dev_import_dma_buf, whose successful
       * publication is required by lookup and the ordinary memory unref. */
      simple_mtx_lock(&base->mems_mutex);
      list_addtail(&(*out)->link, &base->mems);
      simple_mtx_unlock(&base->mems_mutex);
   }
   return result;
}
static VkResult alloc_tiled(struct nvkmd_dev *base, struct vk_object_base *log,
                            uint64_t size, uint64_t alignment, uint8_t kind,
                            uint16_t mode, enum nvkmd_mem_flags flags,
                            struct nvkmd_mem **out)
{
   VkResult result = r4vk_nvk_check_device(base);
   if (result != VK_SUCCESS) return result;
   return r4vk_nvk_alloc_tiled_mem(&dev(base)->memory, log, size, alignment,
                                   kind, mode, flags, out);
}
static VkResult import_dma_buf(struct nvkmd_dev *base,
                               struct vk_object_base *log, int fd,
                               struct nvkmd_mem **out)
{
   (void)log; (void)fd; (void)out;
   VkResult result = r4vk_nvk_check_device(base);
   return result == VK_SUCCESS ? VK_ERROR_INVALID_EXTERNAL_HANDLE : result;
}
static VkResult create_ctx(struct nvkmd_dev *base, struct vk_object_base *log,
                           enum nvkmd_engines engines, struct nvkmd_ctx **out)
{
   (void)log;
   VkResult result = r4vk_nvk_check_device(base);
   if (result != VK_SUCCESS) return result;
   return r4vk_nvk_create_ctx(&dev(base)->resources, &pdev(base->pdev)->backend.binding,
                             engines, out);
}
static const struct nvkmd_dev_ops dev_ops = {
   .destroy = destroy_dev, .alloc_mem = alloc_mem, .alloc_tiled_mem = alloc_tiled,
   .import_dma_buf = import_dma_buf, .alloc_va = alloc_va, .create_ctx = create_ctx,
   /* No GPU timestamp or DRM FD: neither has a native implementation here. */
};
static const struct nvkmd_pdev_ops pdev_ops = {
   .destroy = pdev_unref, .create_dev = create_dev,
   /* No usage telemetry or DRM FD. Corresponding kmd_info flags stay false. */
};

VkResult r4vk_nvk_query_pdev_architecture(struct nvkmd_pdev *base,
                                         struct r4vk_nvk_architecture *out)
{
   if (!base || base->ops != &pdev_ops || !out)
      return VK_ERROR_INITIALIZATION_FAILED;
   const struct native_pdev *physical = pdev(base);
   return r4vk_nvk_query_architecture(&physical->draw, &physical->backend, out);
}

VkResult r4vk_nvk_create_pdev(const R4Draw *draw,
                             const R4GfxBackendInfo *backend,
                             enum nvk_debug debug_flags,
                             struct nvkmd_pdev **out)
{
   if (!out) return VK_ERROR_INITIALIZATION_FAILED;
   struct r4vk_nvk_architecture architecture;
   VkResult result = r4vk_nvk_query_architecture(draw, backend, &architecture);
   if (result != VK_SUCCESS) return result;
   struct native_pdev *physical = calloc(1, sizeof(*physical));
   if (!physical) return VK_ERROR_OUT_OF_HOST_MEMORY;
   physical->base.ops = &pdev_ops;
   physical->base.debug_flags = debug_flags;
   physical->base.dev_info = architecture.info;
   physical->base.bind_align_B = architecture.bind_alignment;
   physical->timeline = vk_sync_timeline_get_type(&r4vk_nvk_sync_type);
   /* NVK's internal memory streams require the preferred type to support
    * timelines. Internal ctx waits/signals unwrap these just like vk_queue. */
   physical->sync_types[0] = &physical->timeline.sync;
   physical->sync_types[1] = &r4vk_nvk_sync_type;
   physical->base.sync_types = physical->sync_types;
   physical->references = 1;
   physical->draw = *draw;
   physical->backend = *backend;
   *out = &physical->base;
   return VK_SUCCESS;
}
