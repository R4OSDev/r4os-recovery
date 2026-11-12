/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_nvk_device.h"
#include <r4nv.h>
#include <cpuid.h>
#include <string.h>

/* Exact supported architecture identities. No guessed numeric range accepts
 * an unknown chip. Unit counts and memory sizes always come from the driver. */
static const char *
chip_name(uint32_t chipset, uint32_t *sm, uint32_t *graphics, uint32_t *compute)
{
   *sm = 86; *graphics = 0xc797; *compute = 0xc7c0;
   switch (chipset) {
   case 0x172: return "GA102";
   case 0x173: return "GA103";
   case 0x174: return "GA104";
   case 0x176: return "GA106";
   case 0x177: return "GA107";
   default: break;
   }
   *sm = 89; *graphics = 0xc997; *compute = 0xc9c0;
   switch (chipset) {
   case 0x192: return "AD102";
   case 0x193: return "AD103";
   case 0x194: return "AD104";
   case 0x196: return "AD106";
   case 0x197: return "AD107";
   default: return NULL;
   }
}

VkResult
r4vk_nvk_query_architecture(const R4Draw *draw, const R4GfxBackendInfo *backend,
                            struct r4vk_nvk_architecture *out)
{
   if (!draw || !backend || !out || backend->version != 1 ||
       backend->size < sizeof(*backend) || backend->binding.version != 1 ||
       backend->binding.size < sizeof(backend->binding) ||
       !backend->binding.adapter_id || !backend->binding.device_generation ||
       !backend->binding.reset_generation || !backend->memory_generation ||
       backend->binding.milestone != R4OS_GFX_QUEUE_MILESTONE_DEVICE_EXECUTION)
      return VK_ERROR_INCOMPATIBLE_DRIVER;
   const R4GfxBackendProfile *profile = &backend->profile;
   if (profile->version != 1 || profile->size < sizeof(*profile) ||
       profile->interface_id_lo != R4NV_BACKEND_V1_INTERFACE_ID_LO ||
       profile->interface_id_hi != R4NV_BACKEND_V1_INTERFACE_ID_HI ||
       profile->revision != 1 || profile->data_bytes != sizeof(R4NvDriverProfile))
      return VK_ERROR_INCOMPATIBLE_DRIVER;
   R4NvDriverProfile protocol;
   memcpy(&protocol, profile->data, sizeof(protocol));
   if (protocol.version != 1 || protocol.size != sizeof(protocol) ||
       protocol.vendor_id != 0x10de || protocol.rm_release != R4NV_RM_RELEASE ||
       protocol.command_abi != R4NV_COMMAND_ABI || protocol.reserved0 || protocol.reserved1)
      return VK_ERROR_INCOMPATIBLE_DRIVER;
   R4GfxBackendProperties properties;
   const int32_t rc = r4draw_gfx_queue_backend_properties(draw, &backend->binding, &properties);
   if (rc == 0 || rc == R4OS_ERR_NO_FN || rc == R4OS_ERR_NO_GROUP ||
       rc == R4OS_GFX_QUEUE_ERROR_UNSUPPORTED)
      return VK_ERROR_INCOMPATIBLE_DRIVER;
   if (rc != 1) return VK_ERROR_DEVICE_LOST;
   if (properties.version != 1 || properties.size < sizeof(properties) ||
       properties.interface_id_lo != R4NV_BACKEND_V1_INTERFACE_ID_LO ||
       properties.interface_id_hi != R4NV_BACKEND_V1_INTERFACE_ID_HI ||
       properties.revision < 1 || properties.revision > R4NV_ARCHITECTURE_VERSION ||
       properties.data_bytes != sizeof(R4NvArchitecture))
      return VK_ERROR_INCOMPATIBLE_DRIVER;
   for (uint32_t i = properties.data_bytes; i < sizeof(properties.data); i++)
      if (properties.data[i]) return VK_ERROR_INITIALIZATION_FAILED;
   R4NvArchitecture a;
   memcpy(&a, properties.data, sizeof(a));
   uint32_t sm, graphics, compute;
   const char *name = chip_name(a.chipset, &sm, &graphics, &compute);
   if (!name) return VK_ERROR_INCOMPATIBLE_DRIVER;
   const uint32_t known_flags = (properties.revision >= 2 ? R4NV_ARCHITECTURE_HOST_COHERENT : 0) |
      (properties.revision >= 3 ? R4NV_ARCHITECTURE_IMAGE_LAYOUTS : 0);
   if (a.version != properties.revision || a.size != sizeof(a) || a.vendor_id != 0x10de ||
       !a.device_id || a.device_id >= 0xffff || a.pci_domain || a.pci_bus > 255 ||
       a.pci_device > 31 || a.pci_function > 7 || a.pci_revision > 255 ||
       !a.gpc_count || a.gpc_count > 32 || a.tpc_count < a.gpc_count ||
       a.tpc_count > a.gpc_count * 32 || a.shader_model != sm ||
       a.mp_per_tpc != 2 || a.max_warps_per_mp != 48 || (a.flags & ~known_flags) ||
       a.rm_release != R4NV_RM_RELEASE || !a.vram_bytes ||
       a.bind_alignment != 65536 || !a.va_start || a.va_start >= a.va_end ||
       a.va_end > (UINT64_C(1) << 49) ||
       (a.va_start | a.va_end) % a.bind_alignment ||
       a.graphics_class != graphics || a.compute_class != compute ||
       (a.copy_class != 0xc7b5 && a.copy_class != 0xc6b5) ||
       a.copy_class != protocol.copy_class || a.gpfifo_class != 0xc56f)
      return VK_ERROR_INITIALIZATION_FAILED;
   if (a.memory_generation != backend->memory_generation)
      return VK_ERROR_DEVICE_LOST;
   unsigned eax, ebx, ecx, edx;
   if (!__get_cpuid(1, &eax, &ebx, &ecx, &edx) || !(edx & (1u << 19)))
      return VK_ERROR_INITIALIZATION_FAILED;
   const uint32_t atom = ((ebx >> 8) & 255) * 8;
   if (!atom || (atom & (atom - 1))) return VK_ERROR_INITIALIZATION_FAILED;

   struct r4vk_nvk_architecture result = {
      .binding = backend->binding, .memory_generation = a.memory_generation,
      .va_start = a.va_start, .va_end = a.va_end, .bind_alignment = a.bind_alignment,
      .host_coherent = (a.flags & R4NV_ARCHITECTURE_HOST_COHERENT) != 0,
      .image_layouts = (a.flags & R4NV_ARCHITECTURE_IMAGE_LAYOUTS) != 0 &&
         (draw->generation2 ?
            (R4DRAW_HAS(draw, gfx_virtual_start) && R4DRAW_HAS(draw, gfx_virtual_query) &&
             R4DRAW_HAS(draw, gfx_virtual_close) && R4DRAW_HAS(draw, gfx_virtual_wait)) :
            (draw->table && draw->table->abi_version >= R4OS_GFX_VIRTUAL_LAYOUT_API_VERSION)),
      .info = {
         .type = NV_DEVICE_TYPE_DIS, .device_id = a.device_id, .chipset = a.chipset,
         .pci = { .domain = a.pci_domain, .bus = a.pci_bus, .dev = a.pci_device,
                  .func = a.pci_function, .revision_id = a.pci_revision },
         .sm = sm, .gpc_count = a.gpc_count, .tpc_count = a.tpc_count,
         .mp_per_tpc = a.mp_per_tpc, .max_warps_per_mp = a.max_warps_per_mp,
         .nc_atom_size_B = atom, .cls_copy = a.copy_class,
         .cls_eng3d = a.graphics_class, .cls_compute = a.compute_class,
         .cls_gpfifo = a.gpfifo_class, .vram_size_B = a.vram_bytes,
         /* Mesa 26.2.2 nouveau_device.c, SM86/89 shared-memory geometry. */
         .max_smem_per_wg_kB = 100, .sm_smem_sizes_kB = {0, 8, 16, 32, 64, 100},
         .sm_smem_size_count = 6,
      },
   };
   memcpy(result.info.chipset_name, name, 6);
   memcpy(result.info.device_name, "NVIDIA ", 7);
   memcpy(result.info.device_name + 7, name, 6);
   /* No BAR map, transfer queue, ZCULL, 2D or M2MF support is inferred. */
   *out = result;
   return VK_SUCCESS;
}
