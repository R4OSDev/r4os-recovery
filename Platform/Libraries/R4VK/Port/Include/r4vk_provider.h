/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VK_PROVIDER_H
#define R4VK_PROVIDER_H
#include <vulkan/vulkan.h>
#include <r4os/r4draw.h>
#include <r4os/r4dev.h>
struct vk_instance;
struct vk_physical_device;
int r4vk_get_graphics_tables(R4Draw *draw, R4Dev *devices);

/* One immutable table identifies the owner of a private Mesa device layout.
 * Its constructor owns any provider-private instance; the common instance
 * owns the public inventory and outlives every published physical device. */
struct r4vk_provider {
   VkResult (*create)(struct vk_instance *, const R4Draw *, const R4Dev *,
                      const R4GfxBackendInfo *, struct vk_physical_device **);
   VkResult (*revalidate)(struct vk_physical_device *);
   void (*destroy)(struct vk_physical_device *);
};
extern const struct r4vk_provider r4vk_nvk_provider;
extern const struct r4vk_provider r4vk_radv_provider;
VkResult r4vk_enumerate_with_providers(struct vk_instance *, const R4Draw *,
   const R4Dev *, const struct r4vk_provider *const *, uint32_t);
VkResult r4vk_enumerate_physical_devices(struct vk_instance *);
void r4vk_destroy_physical_device(struct vk_physical_device *);
#endif
