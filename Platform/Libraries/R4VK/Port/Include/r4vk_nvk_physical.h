/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VK_NVK_PHYSICAL_H
#define R4VK_NVK_PHYSICAL_H
#include "r4vk_nvk_device.h"
#include <r4os/r4dev.h>
struct nvk_physical_device;
struct vk_instance;
struct vk_physical_device;
struct vk_device_extension_table;
struct vk_features;
struct vk_properties;
int r4vk_get_graphics_tables(R4Draw *draw, R4Dev *devices);
VkResult r4vk_nvk_enumerate_with_tables(struct vk_instance *instance,
   const R4Draw *draw, const R4Dev *devices);

/* Native construction consumes exactly one enumerated binding. It does not
 * scan PCI, reopen an RM client or select a replacement after reset. */
VkResult nvk_create_r4os_physical_device(struct vk_instance *instance,
   const R4Draw *draw, const R4Dev *devices, const R4GfxBackendInfo *backend,
   struct vk_physical_device **out);

/* Transactional resource description: validate all native facts first;
 * failure leaves the physical device's heap/type/queue arrays unchanged. */
VkResult r4vk_nvk_init_physical_resources(struct nvk_physical_device *pdev,
   const R4Dev *devices);
void r4vk_nvk_filter_physical_caps(struct vk_device_extension_table *extensions,
   struct vk_features *features, struct vk_properties *properties);
#endif
