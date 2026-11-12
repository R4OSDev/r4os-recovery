/* Copyright 2026 R4
 * SPDX-License-Identifier: Apache-2.0
 */
#include "shaders.h"
#include "nak.h"
#include "nv_device_info.h"
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>

static bool
write_bytes(const char *path, const void *data, size_t size)
{
   FILE *f = fopen(path, "wb");
   if (!f) return false;
   bool ok = fwrite(data, 1, size, f) == size;
   if (fclose(f) != 0) ok = false;
   return ok;
}

int main(int argc, char **argv)
{
   if (argc != 6 && argc != 7) {
      fprintf(stderr, "Usage: r4nak PROFILE CODE.bin INFO.json ASSEMBLY.txt INPUT-NIR.txt [SM]\n"
                      "Profiles: 1=rectangle vertex, 2=texture, 3=sRGB decode, "
                      "4=sRGB encode, 5=solid fragment, 6=solid vertex, 7=color, 8=YUV, 9=encode input. SM: 75, 86 (default), 89, 120.\n");
      return 2;
   }
   char *end;
   errno = 0;
   unsigned long profile = strtoul(argv[1], &end, 10);
   if (errno || *end || profile < R4NV_RECT_VERTEX || profile > R4NV_ENCODE_FRAGMENT)
      return 2;
   errno = 0;
   const unsigned long sm = argc == 7 ? strtoul(argv[6], &end, 10) : 86;
   if (errno || (argc == 7 && *end) || (sm != 75 && sm != 86 && sm != 89 && sm != 120)) return 2;
   /* Pinned Mesa winsys/nouveau_device.c max_warps_per_mp_for_sm and the
    * corresponding NVIDIA architecture tuning guides agree on these limits. */
   const unsigned max_warps = sm == 75 ? 32 : 48;
   const struct nv_device_info dev = {
      .type = NV_DEVICE_TYPE_DIS, .sm = sm, .max_warps_per_mp = max_warps,
   };
   glsl_type_singleton_init_or_ref();
   struct nak_compiler *nak = nak_compiler_create(&dev);
   nir_shader *nir = r4nv_build_shader(profile, nak_nir_options(nak));
   int result = 1;
   struct nak_shader_bin *bin = NULL;
   if (!nir) goto done;
   FILE *f = fopen(argv[5], "wb");
   if (!f) goto done;
   nir_print_shader(nir, f);
   bool printed = !ferror(f);
   if (fclose(f) != 0) printed = false;
   if (!printed) goto done;
   nak_preprocess_nir(nir, nak);
   const struct nak_fs_key key = {0};
   bin = nak_compile_shader(nir, true, nak, 0,
                           (profile == R4NV_RECT_VERTEX || profile == R4NV_SOLID_VERTEX) ? NULL : &key, false);
   if (!bin || !bin->code_size || (bin->code_size % 16) ||
       bin->info.sm != sm || bin->info.slm_size || bin->info.crs_size ||
       bin->info.num_spills_to_mem || bin->info.num_fills_from_mem)
      goto done;
   if (!write_bytes(argv[2], bin->code, bin->code_size) ||
       !write_bytes(argv[4], bin->asm_str, strlen(bin->asm_str))) goto done;
   f = fopen(argv[3], "wb");
   if (!f) goto done;
   fprintf(f, "{\n  \"schema\": 1, \"mesa\": \"26.2.2\", \"profile\": %lu,\n"
              "  \"sm\": %u, \"max_warps_per_mp\": %u, \"stage\": %u,\n"
              "  \"gprs\": %u, \"code_bytes\": %u, \"instructions\": %u,\n"
              "  \"slm_bytes\": %u, \"crs_bytes\": %u, \"max_warps_per_sm\": %u,\n"
              "  \"control_barriers\": %u, \"header\": [",
           profile, bin->info.sm, max_warps, bin->info.stage, bin->info.num_gprs,
           bin->code_size, bin->info.num_instrs, bin->info.slm_size,
           bin->info.crs_size, bin->info.max_warps_per_sm,
           bin->info.num_control_barriers);
   for (unsigned i = 0; i < 32; i++)
      fprintf(f, "%s%u", i ? ", " : "", bin->info.hdr[i]);
   fprintf(f, "]\n}\n");
   bool info_written = !ferror(f);
   if (fclose(f) != 0) info_written = false;
   if (info_written) {
      printf("R4NAK profile=%lu SM%lu bytes=%u gprs=%u instructions=%u\n",
             profile, sm, bin->code_size, bin->info.num_gprs, bin->info.num_instrs);
      result = 0;
   }
done:
   if (bin) nak_shader_bin_destroy(bin);
   if (nir) ralloc_free(nir);
   nak_compiler_destroy(nak);
   glsl_type_singleton_decref();
   if (result) fprintf(stderr, "R4NAK compilation or output failed; discard this output set.\n");
   return result;
}
