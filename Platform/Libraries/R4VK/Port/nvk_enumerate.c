/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_nvk_physical.h"
#include "r4vk_provider.h"
#include "nvk_physical_device.h"

static VkResult revalidate(struct vk_physical_device *device)
{
   struct nvk_physical_device *nvk =
      container_of(device, struct nvk_physical_device, vk);
   struct r4vk_nvk_architecture facts;
   return r4vk_nvk_query_pdev_architecture(nvk->nvkmd, &facts);
}

const struct r4vk_provider r4vk_nvk_provider = {
   .create = nvk_create_r4os_physical_device,
   .revalidate = revalidate,
   .destroy = nvk_physical_device_destroy,
};

VkResult r4vk_nvk_enumerate_with_tables(struct vk_instance *instance,
   const R4Draw *draw, const R4Dev *devices)
{
   const struct r4vk_provider *providers[] = { &r4vk_nvk_provider };
   return r4vk_enumerate_with_providers(instance, draw, devices, providers, 1);
}
