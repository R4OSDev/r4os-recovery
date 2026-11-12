/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_nvk_physical.h"
#include "nvk_physical_device.h"

VkResult r4vk_nvk_init_physical_resources(struct nvk_physical_device *pdev,
   const R4Dev *devices)
{
   if (!pdev || !pdev->nvkmd || pdev->mem_heap_count || pdev->mem_type_count ||
       pdev->queue_family_count)
      return VK_ERROR_INITIALIZATION_FAILED;
   struct r4vk_nvk_architecture facts;
   VkResult result = r4vk_nvk_query_pdev_architecture(pdev->nvkmd, &facts);
   if (result != VK_SUCCESS) return result;
   if (!facts.host_coherent || !facts.image_layouts)
      return VK_ERROR_INCOMPATIBLE_DRIVER;
   if (pdev->info.device_id != facts.info.device_id ||
       pdev->info.chipset != facts.info.chipset ||
       pdev->info.vram_size_B != facts.info.vram_size_B ||
       pdev->nvkmd->bind_align_B != facts.bind_alignment)
      return VK_ERROR_DEVICE_LOST;

   R4ProgramMemoryPressureSnapshot memory;
   if (r4dev_memory_pressure_snapshot(devices, &memory) != 1 ||
       memory.version != R4OS_MEMORY_PRESSURE_SNAPSHOT_VERSION ||
       memory.size < sizeof(memory) || memory.reserved0 ||
       !memory.total_physical_bytes ||
       memory.app_system_reserve_bytes >= memory.total_physical_bytes)
      return VK_ERROR_INITIALIZATION_FAILED;
   for (unsigned i = 0; i < ARRAY_SIZE(memory.reserved1); i++)
      if (memory.reserved1[i]) return VK_ERROR_INITIALIZATION_FAILED;
   /* Heap capacity is stable total RAM minus the kernel's application
    * reserve, not a transient free-memory snapshot or an invented BAR heap.
    * Per-allocation native BO budgets remain authoritative for admission. */
   const uint64_t sysmem = ROUND_DOWN_TO(memory.total_physical_bytes -
                                         memory.app_system_reserve_bytes,
                                         facts.bind_alignment);
   const uint64_t vram = ROUND_DOWN_TO(facts.info.vram_size_B, facts.bind_alignment);
   if (!sysmem || !vram) return VK_ERROR_INITIALIZATION_FAILED;

   pdev->mem_heaps[0] = (struct nvk_memory_heap) {
      .size = vram, .flags = VK_MEMORY_HEAP_DEVICE_LOCAL_BIT,
   };
   pdev->mem_heaps[1] = (struct nvk_memory_heap) { .size = sysmem };
   pdev->mem_types[0] = (VkMemoryType) {
      .propertyFlags = VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, .heapIndex = 0,
   };
   pdev->mem_types[1] = (VkMemoryType) {
      .propertyFlags = VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT |
         VK_MEMORY_PROPERTY_HOST_COHERENT_BIT | VK_MEMORY_PROPERTY_HOST_CACHED_BIT,
      .heapIndex = 1,
   };
   pdev->queue_families[0] = (struct nvk_queue_family) {
      .queue_flags = VK_QUEUE_GRAPHICS_BIT | VK_QUEUE_COMPUTE_BIT | VK_QUEUE_TRANSFER_BIT,
      .queue_count = 1, .max_priority = VK_QUEUE_GLOBAL_PRIORITY_MEDIUM,
   };
   pdev->mem_heap_count = 2;
   pdev->mem_type_count = 2;
   pdev->queue_family_count = 1;
   return VK_SUCCESS;
}

void r4vk_nvk_filter_physical_caps(struct vk_device_extension_table *ext,
   struct vk_features *features, struct vk_properties *properties)
{
   /* These require host/backend operations absent in the native adapter.
    * Hardware class support in upstream NVK is not enough to enable them. */
   ext->KHR_swapchain = true; /* Native WINSVC ownership, independent of Mesa platform WSI. */
   ext->KHR_swapchain_mutable_format = true; /* Owned format lists and mutable native imports. */
   ext->KHR_external_memory_fd = false;
   ext->KHR_external_semaphore_fd = false;
   ext->KHR_external_fence_fd = false;
   ext->EXT_external_memory_dma_buf = false;
   ext->EXT_image_drm_format_modifier = false;
   ext->EXT_physical_device_drm = false;
   ext->EXT_queue_family_foreign = false;
   ext->KHR_calibrated_timestamps = false;
   ext->EXT_calibrated_timestamps = false;
   ext->EXT_map_memory_placed = false;
   ext->EXT_memory_budget = false;
   ext->EXT_hdr_metadata = false;
   features->sparseBinding = false;
   features->sparseResidencyBuffer = false;
   features->sparseResidencyImage2D = false;
   features->sparseResidencyImage3D = false;
   features->sparseResidency2Samples = false;
   features->sparseResidency4Samples = false;
   features->sparseResidency8Samples = false;
   features->sparseResidency16Samples = false;
   features->sparseResidencyAliased = false;
   features->sparseImageFloat32Atomics = false;
   features->sparseImageFloat32AtomicAdd = false;
   features->sparseImageInt64Atomics = false;
   features->bufferDeviceAddressCaptureReplay = false;
   features->bufferDeviceAddressCaptureReplayEXT = false;
   features->memoryMapPlaced = false;
   features->memoryMapRangePlaced = false;
   features->memoryUnmapReserve = false;
   properties->sparseAddressSpaceSize = 0;
   properties->sparseResidencyNonResidentStrict = false;
   properties->sparseResidencyAlignedMipSize = false;
   properties->sparseResidencyStandard2DBlockShape = false;
   properties->sparseResidencyStandard2DMultisampleBlockShape = false;
   properties->sparseResidencyStandard3DBlockShape = false;
   /* Query timestamps use NVK's original four-word GPU report semaphore.
    * They need no host clock read; calibrated timestamps remain disabled. */
   properties->timestampComputeAndGraphics = true;
   /* Vulkan requires at least two relative priority levels. The only queue
    * in each logical device has no competing peer; Vulkan gives these hints
    * no cross-device scheduling guarantee. Global priority is separate and
    * the native queue-family query admits only MEDIUM. */
   properties->discreteQueuePriorities = 2;
   properties->conformanceVersion = (VkConformanceVersion) {0};
   properties->drmHasPrimary = false;
   properties->drmHasRender = false;
   properties->drmPrimaryMajor = properties->drmPrimaryMinor = 0;
   properties->drmRenderMajor = properties->drmRenderMinor = 0;
}
