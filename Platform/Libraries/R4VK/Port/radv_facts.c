/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_radv.h"
#include "ac_linux_drm.h"
#include "addrlib/src/amdgpu_asic_addr.h"
#include <string.h>

VkResult r4vk_radv_query_architecture(const R4Draw *draw, const R4Dev *devices,
   const R4GfxBackendInfo *backend, struct r4vk_radv_architecture *out)
{
   if (!draw || !devices || !backend || !out || backend->version != 1 ||
       backend->size < sizeof(*backend) || backend->binding.version != 1 ||
       backend->binding.size < sizeof(backend->binding) || !backend->binding.adapter_id ||
       !backend->binding.device_generation || !backend->binding.reset_generation ||
       !backend->memory_generation || backend->binding.milestone != R4OS_GFX_QUEUE_MILESTONE_DEVICE_EXECUTION ||
       !(backend->operations & (UINT64_C(1) << R4OS_GFX_QUEUE_OPERATION_NATIVE)))
      return VK_ERROR_INCOMPATIBLE_DRIVER;
   const R4GfxBackendProfile *profile = &backend->profile;
   if (profile->version != 1 || profile->size < sizeof(*profile) ||
       profile->interface_id_lo != R4AMD_BACKEND_V1_INTERFACE_ID_LO ||
       profile->interface_id_hi != R4AMD_BACKEND_V1_INTERFACE_ID_HI ||
       profile->revision != 1 || profile->data_bytes != sizeof(R4AmdDriverProfile))
      return VK_ERROR_INCOMPATIBLE_DRIVER;
   R4AmdDriverProfile protocol;
   memcpy(&protocol, profile->data, sizeof(protocol));
   const bool raven2 = protocol.gc_version == R4AMD_GC_9_2_2 && protocol.sdma_version == R4AMD_SDMA_4_1_1;
   const bool picasso = protocol.gc_version == R4AMD_GC_9_1_0 && protocol.sdma_version == R4AMD_SDMA_4_1_0;
   if (protocol.version != 1 || protocol.size != sizeof(protocol) ||
       protocol.vendor_id != R4AMD_VENDOR_ID || protocol.device_id != 0x15d8 ||
       (!picasso && !raven2) ||
       protocol.command_abi != R4AMD_COMMAND_ABI || protocol.reserved)
      return VK_ERROR_INCOMPATIBLE_DRIVER;
   for (size_t i = sizeof(protocol); i < sizeof(profile->data); i++)
      if (profile->data[i]) return VK_ERROR_INITIALIZATION_FAILED;
   R4GfxBackendProperties properties;
   const int32_t rc = r4draw_gfx_queue_backend_properties(draw, &backend->binding, &properties);
   if (!rc || rc == R4OS_ERR_NO_FN || rc == R4OS_ERR_NO_GROUP || rc == R4OS_GFX_QUEUE_ERROR_UNSUPPORTED)
      return VK_ERROR_INCOMPATIBLE_DRIVER;
   if (rc != 1) return VK_ERROR_DEVICE_LOST;
   if (properties.version != 1 || properties.size < sizeof(properties) ||
       properties.interface_id_lo != R4AMD_IMAGE_V1_INTERFACE_ID_LO ||
       properties.interface_id_hi != R4AMD_IMAGE_V1_INTERFACE_ID_HI ||
       !((properties.revision == 2 && properties.data_bytes == sizeof(R4AmdDeviceFacts)) ||
         (properties.revision == 3 && properties.data_bytes == sizeof(R4AmdDeviceFactsV3))))
      return VK_ERROR_INCOMPATIBLE_DRIVER;
   for (size_t i = properties.data_bytes; i < sizeof(properties.data); i++)
      if (properties.data[i]) return VK_ERROR_INITIALIZATION_FAILED;
   R4AmdDeviceFacts f;
   memcpy(&f, properties.data, sizeof(f));
   R4AmdDeviceFactsV3 extended = {0};
   if (properties.revision == 3) {
      memcpy(&extended, properties.data, sizeof(extended));
      if ((extended.timestamp_clock_khz && (extended.timestamp_clock_khz < 6000 || extended.timestamp_clock_khz > 25000)) ||
          extended.native_binding_capacity != 32 || extended.max_backing_bytes != UINT64_C(1024)*1024*1024 + 4096)
         return VK_ERROR_INITIALIZATION_FAILED;
   }
   const R4AmdArchitecture *a = &f.architecture;
   if (a->memory_generation != backend->memory_generation) return VK_ERROR_DEVICE_LOST;
   if (a->version != 1 || a->size != sizeof(*a) || a->vendor_id != protocol.vendor_id ||
       a->device_id != protocol.device_id || a->gc_version != protocol.gc_version || a->sdma_version != protocol.sdma_version ||
       !a->gb_addr_config || a->chip_revision < (raven2 ? 0x81u : 0x41u) || a->chip_revision > (raven2 ? 0x88u : 0x48u) ||
       a->bind_alignment != 4096 || a->flags || a->reserved ||
       a->max_image_bytes != UINT64_C(64)*1024*1024 || f.version != 1 || f.size != sizeof(f) ||
       f.pci_domain || f.pci_bus > 255 || f.pci_device > 31 || f.pci_function > 7 || f.pci_revision > 255 ||
       f.asic_revision < (raven2 ? 8u : 0u) || f.asic_revision > (raven2 ? 15u : 7u) ||
       a->chip_revision != (raven2 ? 0x79u : 0x41u) + f.asic_revision ||
       !f.cu_mask || (f.cu_mask & ~(raven2 ? 7u : 0x7ffu)) || !f.rb_mask || (f.rb_mask & ~(raven2 ? 1u : 3u)) ||
       !f.pfp_fw || !f.me_fw || !f.mec_fw || !f.ce_fw || !f.me_feature || !f.mec_feature || !f.smu_fw ||
       (f.flags & 3) != 3 || (f.flags & ~15u) || f.reserved || !f.uma_bytes || !f.native_budget || f.native_budget > f.uma_bytes ||
       f.va_start != R4AMD_NATIVE_VA_START || f.va_end != R4AMD_NATIVE_VA_END || f.max_allocation_bytes != a->max_image_bytes ||
       f.max_se != 1 || f.max_sh_per_se != 1 || f.max_cu_per_sh != (raven2 ? 3u : 11u) || f.max_rb_per_se != (raven2 ? 1u : 2u) ||
       f.wave_size != 64 || !f.num_tccs || !f.num_gprs || !f.max_waves_per_simd || !f.lds_bytes)
      return VK_ERROR_INITIALIZATION_FAILED;
   R4ProgramMemoryPressureSnapshot memory;
   if (r4dev_memory_pressure_snapshot(devices, &memory) != 1 ||
       memory.version != R4OS_MEMORY_PRESSURE_SNAPSHOT_VERSION || memory.size < sizeof(memory) ||
       memory.reserved0 || !memory.total_physical_bytes || memory.app_system_reserve_bytes >= memory.total_physical_bytes)
      return VK_ERROR_INITIALIZATION_FAILED;
   for (size_t i = 0; i < ARRAY_SIZE(memory.reserved1); i++)
      if (memory.reserved1[i]) return VK_ERROR_INITIALIZATION_FAILED;
   const uint64_t system = (memory.total_physical_bytes - memory.app_system_reserve_bytes) & ~UINT64_C(4095);
   if (!system || (system >> 10) > UINT32_MAX || (f.native_budget >> 10) > UINT32_MAX)
      return VK_ERROR_INITIALIZATION_FAILED;
   struct r4vk_radv_architecture value = { .backend = *backend, .facts = f, .system_heap_bytes = system,
      .timestamp_clock_khz = extended.timestamp_clock_khz,
      .native_binding_capacity = extended.native_binding_capacity ? extended.native_binding_capacity : 32,
      .max_backing_bytes = extended.max_backing_bytes ? extended.max_backing_bytes : f.max_allocation_bytes };
   struct radeon_info *info = &value.info;
   /* These declaration structs feed Mesa's pure hardware helpers. They are
    * never a libdrm device, ioctl response or published kernel ABI. */
   struct drm_amdgpu_info_device hw = {
      .device_id = a->device_id, .pci_rev = f.pci_revision, .chip_rev = f.asic_revision,
      .external_rev = a->chip_revision, .family = FAMILY_RV,
      .num_shader_engines = f.max_se, .num_shader_arrays_per_engine = f.max_sh_per_se,
      .cu_active_number = __builtin_popcount(f.cu_mask), .cu_bitmap = {{f.cu_mask}},
      .num_rb_pipes = f.max_rb_per_se, .enabled_rb_pipes_mask = f.rb_mask,
      .num_cu_per_sh = f.max_cu_per_sh, .num_tcc_blocks = f.num_tccs,
      .num_shader_visible_vgprs = f.num_gprs, .wave_front_size = f.wave_size,
      .gc_double_offchip_lds_buf = f.double_offchip_lds, .ids_flags = AMDGPU_IDS_FLAGS_FUSION,
      .virtual_address_offset = f.va_start, .virtual_address_max = f.va_end,
      .virtual_address_alignment = 4096,
   };
   info->ip[AMD_IP_GFX] = raven2 ? (struct amd_ip_info) {9, 2, 2, 1, 1, 32, 7} : (struct amd_ip_info) {9, 1, 0, 1, 1, 32, 7};
   info->ip[AMD_IP_COMPUTE] = info->ip[AMD_IP_GFX];
   info->has_graphics = true;
   if (!ac_identify_chip(info, &hw) || info->family != (raven2 ? CHIP_RAVEN2 : CHIP_RAVEN) || info->gfx_level != GFX9)
      return VK_ERROR_INCOMPATIBLE_DRIVER;
   struct drm_amdgpu_memory_info heaps = {
      .vram = {f.native_budget}, .cpu_accessible_vram = {0}, .gtt = {system},
   };
   ac_fill_memory_info(info, &hw, &heaps);
   info->pfp_fw_version = f.pfp_fw;
   info->me_fw_version = f.me_fw; info->mec_fw_version = f.mec_fw;
   info->me_fw_feature = f.me_feature; info->mec_fw_feature = f.mec_feature;
   ac_fill_hw_info(info, &hw);
   const struct amdgpu_gpu_info tiling = { .gb_addr_cfg = a->gb_addr_config };
   ac_fill_tiling_info(info, &tiling);
   ac_fill_feature_info(info, &hw);
   ac_fill_bug_info(info); ac_fill_tess_info(info); ac_fill_compiler_info(info, &hw, false);
   info->pci.domain = f.pci_domain; info->pci.bus = f.pci_bus;
   info->pci.dev = f.pci_device; info->pci.func = f.pci_function; info->pci.valid = true;
   if (raven2) memcpy(info->marketing_name, "AMD Raven2", sizeof("AMD Raven2"));
   else memcpy(info->marketing_name, "AMD Picasso", sizeof("AMD Picasso"));
   /* ac_query_gpu_info normally supplies this default after the pure fill
    * helpers, in set_custom_cu_en_mask. R4OS has no AMD_CU_MASK override and
    * constructs the hardware facts directly: preserve Mesa's all-CU default.
    * A zero mask disables shader CUs in the generated graphics preamble. The
    * independently reported hardware CU bitmap still describes harvesting. */
   info->spi_cu_en = UINT32_MAX;
   info->address32_hi = f.va_start >> 32;
   info->max_submitted_ibs[AMD_IP_GFX] = 32; info->max_submitted_ibs[AMD_IP_COMPUTE] = 32;
   info->scratch_wavesize_granularity_shift = 10; info->scratch_wavesize_granularity = 1024;
   info->max_scratch_waves = MAX2(32u, 32u * info->num_cu);
   /* The R4OS adapters replace Linux-dependent capabilities explicitly. */
   info->has_userptr = false; info->has_syncobj = false; info->has_fence_to_handle = false;
   info->has_timeline_syncobj = false; info->has_vm_always_valid = true;
   info->has_sparse = false; info->has_sparse_image_3d = false;
   info->has_sparse_image_standard_3d = false; info->has_sparse_unaligned_mip_size = false; info->has_kernelq_reg_shadowing = false;
   info->has_l2_uncached = false; info->kernel_has_modifiers = false;
   info->clock_crystal_freq = value.timestamp_clock_khz;
   *out = value;
   return VK_SUCCESS;
}
