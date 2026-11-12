/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_radv.h"
#include "radv_physical_device.h"
void r4vk_radv_filter_physical(struct radv_physical_device *pdev)
{
   struct vk_device_extension_table *e = &pdev->vk.supported_extensions;
   struct vk_features *f = &pdev->vk.supported_features;
   struct vk_properties *p = &pdev->vk.properties;
   e->KHR_swapchain = e->KHR_swapchain_mutable_format = true;
   /* Mesa's timeline implementation is installed over our native binary
    * points. Its availability is independent of Linux syncobj support. */
   e->KHR_timeline_semaphore = true;
   f->timelineSemaphore = true;
   e->KHR_external_memory_fd = e->KHR_external_semaphore_fd = e->KHR_external_fence_fd = false;
   e->EXT_external_memory_dma_buf = e->EXT_external_memory_host = e->EXT_image_drm_format_modifier = false;
   e->EXT_physical_device_drm = e->EXT_queue_family_foreign = false;
   e->KHR_calibrated_timestamps = e->EXT_calibrated_timestamps = false;
   e->EXT_map_memory_placed = e->EXT_memory_budget = false;
   e->EXT_hdr_metadata = e->EXT_swapchain_maintenance1 = e->KHR_swapchain_maintenance1 = false;
   e->KHR_present_id = e->KHR_present_wait = e->KHR_present_id2 = e->KHR_present_wait2 = false;
   e->EXT_display_control = e->GOOGLE_display_timing = false;
   e->KHR_performance_query = e->EXT_device_generated_commands = e->NV_device_generated_commands = false;
   e->EXT_global_priority = e->KHR_global_priority = e->EXT_global_priority_query = false;
   e->EXT_device_address_binding_report = e->EXT_device_fault = false;
   e->EXT_pipeline_properties = e->AMD_shader_info = false;
   e->EXT_debug_marker = false;
   e->EXT_shader_object = e->EXT_graphics_pipeline_library = false;
   f->shaderObject = f->graphicsPipelineLibrary = false;
   f->sparseBinding = f->sparseResidencyBuffer = f->sparseResidencyImage2D = f->sparseResidencyImage3D = false;
   f->sparseResidency2Samples = f->sparseResidency4Samples = f->sparseResidency8Samples = f->sparseResidency16Samples = f->sparseResidencyAliased = false;
   f->bufferDeviceAddressCaptureReplay = f->descriptorBufferCaptureReplay = false;
   f->deviceGeneratedCommands = f->performanceCounterQueryPools = f->performanceCounterMultipleQueryPools = false;
   f->deviceFault = f->deviceFaultVendorBinary = f->reportAddressBinding = false;
   f->swapchainMaintenance1 = f->presentId = f->presentWait = f->presentId2 = f->presentWait2 = false;
   f->memoryMapPlaced = f->memoryMapRangePlaced = f->memoryUnmapReserve = false;
   f->globalPriorityQuery = false;
   p->maxMemoryAllocationCount = 4096;
   /* Public memory objects share disjoint padded extents of canonical BOs.
    * The driver limit includes the real GFX9 SMEM page, Vulkan's size does not. */
   p->maxMemoryAllocationSize = pdev->native_facts.max_backing_bytes - 4096;
   p->maxBufferSize = p->maxMemoryAllocationSize;
   if (!pdev->native_facts.timestamp_clock_khz) {
      p->timestampComputeAndGraphics = false;
      p->timestampPeriod = 0.0f;
   }
   p->conformanceVersion = (VkConformanceVersion){0};
   /* A legacy receipt or missing board clock retains basic native admission.
    * Conformance remains undeclared; this is the implemented API profile. */
   p->apiVersion = pdev->native_facts.timestamp_clock_khz &&
      p->maxMemoryAllocationSize >= UINT64_C(1024)*1024*1024 ? VK_API_VERSION_1_3 : VK_API_VERSION_1_0;
}
