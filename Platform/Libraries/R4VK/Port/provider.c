/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_provider.h"
#include "vk_instance.h"
#include "vk_physical_device.h"
#include "util/list.h"

int r4vk_get_graphics_tables(R4Draw *, R4Dev *);

void r4vk_destroy_physical_device(struct vk_physical_device *device)
{
   assert(device && device->r4os_provider);
   device->r4os_provider->destroy(device);
}

VkResult r4vk_enumerate_with_providers(struct vk_instance *instance,
   const R4Draw *draw, const R4Dev *devices,
   const struct r4vk_provider *const *providers, uint32_t count)
{
   if (!instance || !draw || !devices || !providers || !count ||
       !list_is_empty(&instance->physical_devices.list))
      return VK_ERROR_INITIALIZATION_FAILED;
   for (uint32_t p = 0; p < count; p++)
      if (!providers[p] || !providers[p]->create || !providers[p]->revalidate ||
          !providers[p]->destroy) return VK_ERROR_INITIALIZATION_FAILED;
   struct list_head created;
   list_inithead(&created);
   VkResult result = VK_SUCCESS;
   for (uint32_t index = 0; index < R4OS_GFX_QUEUE_BACKEND_CAPACITY; index++) {
      R4GfxBackendInfo backend;
      const int32_t status = r4draw_gfx_queue_backend_info(draw, index, &backend);
      if (!status) continue; /* Inventory holes are not an end marker. */
      if (status != 1) { result = VK_ERROR_INITIALIZATION_FAILED; goto fail; }
      for (uint32_t p = 0; p < count; p++) {
         struct vk_physical_device *device = NULL;
         result = providers[p]->create(instance, draw, devices, &backend, &device);
         if (result == VK_ERROR_INCOMPATIBLE_DRIVER) continue;
         if (result != VK_SUCCESS) goto fail;
         if (!device) { result = VK_ERROR_INITIALIZATION_FAILED; goto fail; }
         device->r4os_provider = providers[p];
         list_addtail(&device->link, &created);
         break; /* A binding has exactly one private provider owner. */
      }
   }
   /* Device construction can sleep. Revalidate the complete transaction
    * before exposing any handle, including a reset of an earlier provider. */
   list_for_each_entry(struct vk_physical_device, device, &created, link) {
      result = device->r4os_provider->revalidate(device);
      if (result != VK_SUCCESS) goto fail;
   }
   list_for_each_entry_safe(struct vk_physical_device, device, &created, link) {
      list_del(&device->link);
      list_addtail(&device->link, &instance->physical_devices.list);
   }
   return VK_SUCCESS;
fail:
   list_for_each_entry_safe(struct vk_physical_device, device, &created, link) {
      list_del(&device->link);
      r4vk_destroy_physical_device(device);
   }
   return result;
}

VkResult r4vk_enumerate_physical_devices(struct vk_instance *instance)
{
   R4Draw draw;
   R4Dev devices;
   if (r4vk_get_graphics_tables(&draw, &devices) != 1)
      return VK_ERROR_INITIALIZATION_FAILED;
   const struct r4vk_provider *providers[] = { &r4vk_nvk_provider, &r4vk_radv_provider };
   return r4vk_enumerate_with_providers(instance, &draw, &devices,
                                       providers, ARRAY_SIZE(providers));
}
