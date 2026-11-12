/* Copyright 2026 R4; SPDX-License-Identifier: Apache-2.0 */
#include "native.h"
#include "nir.h"
#include "nir_spirv.h"
#include "spirv_info.h"
#include "nak.h"
#include "nv_device_info.h"
#include "util/format/u_format.h"

/* R4NV graphics constants ABI4. Resource/pipeline layout is part of the
 * public cache identity; the native compiler never discovers a GPU itself. */
const struct nak_constant_offset_info nak_const_offsets_base = {
   .sample_info_cb = 0, .sample_locations_offset = 0,
   .sample_masks_offset = 16, .printf_cb = 0, .printf_buffer_offset = 48,
};
const struct nak_constant_offset_info nak_const_offsets_turing_graphics = {
   .sample_info_cb = 0, .sample_locations_offset = 0,
   .sample_masks_offset = 16, .printf_cb = 0, .printf_buffer_offset = 48,
};

static void frontend(nir_shader *nir)
{
   /* Same generic normalization order as Mesa's vk_spirv_to_nir. NVK's
    * descriptor/queue/device integration belongs to the Vulkan owner. */
   NIR_PASS(_, nir, nir_lower_variable_initializers, nir_var_function_temp);
   NIR_PASS(_, nir, nir_lower_returns);
   NIR_PASS(_, nir, nir_inline_functions);
   NIR_PASS(_, nir, nir_opt_copy_prop);
   NIR_PASS(_, nir, nir_opt_constant_folding);
   NIR_PASS(_, nir, nir_opt_deref);
   nir_remove_non_cmat_call_entrypoints(nir);
   NIR_PASS(_, nir, nir_lower_variable_initializers, ~0);
   NIR_PASS(_, nir, nir_split_var_copies);
   NIR_PASS(_, nir, nir_split_per_member_structs);
   NIR_PASS(_, nir, nir_remove_dead_variables,
            nir_var_shader_in | nir_var_shader_out | nir_var_system_value, NULL);
   nir_gather_clip_cull_distance_sizes_from_vars(nir);
   NIR_PASS(_, nir, nir_merge_clip_cull_distance_vars);
   NIR_PASS(_, nir, nir_propagate_invariant, false);
}

int r4nak_native_compile(const uint32_t *words, size_t word_count,
                         const char *entry, uint32_t stage, uint32_t sm,
                         struct r4nak_native_binary *out)
{
   if (sm != 75 && sm != 86 && sm != 89 && sm != 120) return -2;
   if (stage != MESA_SHADER_VERTEX && stage != MESA_SHADER_FRAGMENT && stage != MESA_SHADER_COMPUTE) return -2;
   /* The runtime holds exclusive compiler ownership. Recover diagnostic
    * locks even after the previous owning program was forcibly retired. */
   extern simple_mtx_t fail_dump_mutex;
   memset(&nir_print_lock, 0, sizeof(nir_print_lock));
   memset(&fail_dump_mutex, 0, sizeof(fail_dump_mutex));
   errno = 0;
   const struct nv_device_info dev = {
      .type = NV_DEVICE_TYPE_DIS, .sm = sm,
      .max_warps_per_mp = sm == 75 ? 32 : 48,
   };
   const struct spirv_capabilities capabilities = { .Shader = true, .Matrix = true };
   const struct spirv_to_nir_options options = {
      .environment = NIR_SPIRV_VULKAN, .capabilities = &capabilities,
      .ubo_addr_format = nir_address_format_32bit_index_offset,
      .ssbo_addr_format = nir_address_format_64bit_bounded_global,
      .phys_ssbo_addr_format = nir_address_format_64bit_global,
      .shared_addr_format = nir_address_format_32bit_offset,
      .min_ubo_alignment = 16, .min_ssbo_alignment = 16,
      .ignore_replacement = true,
   };
   glsl_type_singleton_init_or_ref();
   struct nak_compiler *nak = nak_compiler_create(&dev);
   nir_shader *nir = spirv_to_nir(words, word_count, NULL, stage, entry,
                                  &options, nak_nir_options(nak));
   int status = -1;
   if (!nir) goto done;
   frontend(nir);
   /* ABI1 accepts stage I/O and local arithmetic/control flow. Keep the
    * future descriptor/push/shared-memory contract explicit. An unresolved
    * resource operation must never reach NAK as if it had been lowered. */
   nir_foreach_variable_in_shader(var, nir) {
      if (var->data.mode != nir_var_shader_in && var->data.mode != nir_var_shader_out &&
          var->data.mode != nir_var_shader_temp && var->data.mode != nir_var_function_temp &&
          var->data.mode != nir_var_system_value) { status = -2; goto done; }
   }
   if (nir->info.num_textures || nir->info.num_ubos || nir->info.num_ssbos || nir->info.num_images || nir->info.shared_size) { status = -2; goto done; }
   nir_validate_shader(nir, "R4OS SPIR-V frontend");
   nak_preprocess_nir(nir, nak);
   const struct nak_fs_key key = {0};
   struct nak_shader_bin *bin = nak_compile_shader(nir, false, nak, 0,
      stage == MESA_SHADER_FRAGMENT ? &key : NULL, false);
   if (!bin) goto done;
   if (!bin->code_size || (bin->code_size & 15) || bin->info.sm != sm || bin->info.stage != stage) { nak_shader_bin_destroy(bin); goto done; }
   *out = (struct r4nak_native_binary) {
      .sm = sm, .stage = stage, .gprs = bin->info.num_gprs,
      .instructions = bin->info.num_instrs, .code_bytes = bin->code_size,
      .slm_bytes = bin->info.slm_size, .crs_bytes = bin->info.crs_size,
      .control_barriers = bin->info.num_control_barriers,
      .max_warps = bin->info.max_warps_per_sm,
      .code = malloc(bin->code_size),
   };
   memcpy(out->header, bin->info.hdr, sizeof(out->header));
   memcpy(out->code, bin->code, bin->code_size);
   nak_shader_bin_destroy(bin);
   status = 0;
done:
   if (nir) ralloc_free(nir);
   nak_compiler_destroy(nak);
   glsl_type_singleton_decref();
   return status;
}

struct r4nak_format {
   uint32_t version, size, format, block_bits, block_width, block_height;
   uint32_t channels, is_float, is_unorm, is_srgb;
};
int r4nak_native_format(uint32_t format, struct r4nak_format *out)
{
   enum pipe_format pipe;
   switch (format) {
   case 875713112: pipe = PIPE_FORMAT_B8G8R8X8_UNORM; break;
   case 875713089: pipe = PIPE_FORMAT_B8G8R8A8_UNORM; break;
   case 538982482: pipe = PIPE_FORMAT_R8_UNORM; break;
   case 808669784: pipe = PIPE_FORMAT_B10G10R10X2_UNORM; break;
   case 808669761: pipe = PIPE_FORMAT_B10G10R10A2_UNORM; break;
   case 1211384385: pipe = PIPE_FORMAT_R16G16B16A16_FLOAT; break;
   case 942948929: pipe = PIPE_FORMAT_R16G16B16A16_UNORM; break;
   default: return -2;
   }
   const struct util_format_description *d = util_format_description(pipe);
   *out = (struct r4nak_format) {
      .version = 1, .size = sizeof(*out), .format = format,
      .block_bits = d->block.bits, .block_width = d->block.width, .block_height = d->block.height,
      .channels = d->nr_channels, .is_float = d->channel[0].type == UTIL_FORMAT_TYPE_FLOAT,
      .is_unorm = d->channel[0].type == UTIL_FORMAT_TYPE_UNSIGNED && d->channel[0].normalized,
      .is_srgb = d->colorspace == UTIL_FORMAT_COLORSPACE_SRGB,
   };
   return 0;
}
