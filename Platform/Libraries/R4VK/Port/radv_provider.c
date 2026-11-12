/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_radv.h"
#include "radv_physical_device.h"
#include "radv_entrypoints.h"
#include "vk_instance.h"
#include "vk_physical_device.h"

static VkResult create(struct vk_instance *parent, const R4Draw *draw,
   const R4Dev *devices, const R4GfxBackendInfo *backend, struct vk_physical_device **out)
{
   struct r4vk_radv_architecture facts;
   VkResult result = r4vk_radv_query_architecture(draw, devices, backend, &facts);
   if (result != VK_SUCCESS) return result;
   VkApplicationInfo app = { .sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
      .pApplicationName = parent->app_info.app_name, .applicationVersion = parent->app_info.app_version,
      .pEngineName = parent->app_info.engine_name, .engineVersion = parent->app_info.engine_version,
      .apiVersion = parent->app_info.api_version };
   VkInstanceCreateInfo info = { .sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO, .pApplicationInfo = &app };
   VkInstance handle;
   result = radv_CreateInstance(&info, &parent->alloc, &handle);
   if (result != VK_SUCCESS) return result;
   struct radv_instance *instance = radv_instance_from_handle(handle);
   /* Independent mutexes, compiler caches and immutable option ownership.
    * Parent enumerates/destroys the resulting physical device. The private
    * instance never enumerates its own inventory. */
   instance->native_parent = parent;
   instance->vk.enabled_extensions = parent->enabled_extensions;
   instance->vk.physical_devices.try_create_for_drm = NULL;
   instance->vk.trace_mode = 0;
   instance->debug_flags = RADV_DEBUG_NO_IB_CHAINING | RADV_DEBUG_NO_RT | RADV_DEBUG_NO_VIDEO |
      RADV_DEBUG_NO_MESH_SHADER | RADV_DEBUG_NO_TMZ | RADV_DEBUG_NO_HEAP;
   instance->perftest_flags = instance->experimental_flags = 0;
   instance->profile_pstate = RADEON_CTX_PSTATE_NONE;
   result = r4vk_radv_physical_create(instance, draw, devices, &facts, out);
   if (result != VK_SUCCESS) radv_DestroyInstance(handle, &parent->alloc);
   return result;
}
static VkResult revalidate(struct vk_physical_device *base)
{
   struct radv_physical_device *pdev = container_of(base, struct radv_physical_device, vk);
   struct r4vk_radv_architecture current;
   VkResult result = r4vk_radv_query_architecture(&pdev->native_draw, &pdev->native_devices,
      &pdev->native_facts.backend, &current);
   if (result != VK_SUCCESS) return VK_ERROR_DEVICE_LOST;
   if (!r4vk_radv_same_facts(&current, &pdev->native_facts)) return VK_ERROR_DEVICE_LOST;
   return VK_SUCCESS;
}
static void destroy(struct vk_physical_device *base)
{
   struct radv_instance *instance = (struct radv_instance *)base->instance;
   radv_physical_device_destroy(base);
   radv_DestroyInstance(radv_instance_to_handle(instance), NULL);
}
VkResult r4vk_radv_device_winsys(const struct radv_physical_device *pdev,
   struct vk_device *device, struct radeon_winsys **out)
{
   (void)device;
   VkResult result = revalidate((struct vk_physical_device *)&pdev->vk);
   if (result != VK_SUCCESS) return result;
   return r4vk_radv_create_winsys(&pdev->native_draw, &pdev->native_devices, &pdev->native_facts, out);
}
const struct r4vk_provider r4vk_radv_provider = { create, revalidate, destroy };
