/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_radv_compile.h"
#include "r4vk_state.h"
#include "radv_pipeline_compute.h"
#include "nir_serialize.h"
#include "ac_shader_debug_info.h"

/* A public API call owns this status. Compiler workers return their own
 * VkResult after exact join; an error cannot cross into another caller. */
static _Thread_local VkResult last_error;
void r4vk_radv_error_reset(void) { last_error = VK_SUCCESS; }
void r4vk_radv_error_record(VkResult result)
{ if (result < 0 && last_error == VK_SUCCESS) last_error = result; }
VkResult r4vk_radv_error_result(VkResult fallback)
{ return last_error < 0 ? last_error : fallback; }

bool r4vk_radv_binary_valid(const struct radv_shader_binary *base, size_t available)
{
   if (!base || available < sizeof(struct radv_shader_binary_legacy) ||
       base->type != RADV_BINARY_TYPE_LEGACY || base->total_size > available)
      return false;
   const struct radv_shader_binary_legacy *b = (const void *)base;
   const uint64_t size = sizeof(*b) + (uint64_t)b->stats_size + b->code_size +
      b->ir_size + b->disasm_size + b->debug_info_size;
   if (size != base->total_size || !b->code_size || (b->code_size & 3) ||
       b->exec_size > b->code_size || b->debug_info_size ||
       (b->stats_size && b->stats_size != sizeof(struct amd_stats))) return false;
   const unsigned char *ir = b->data + b->stats_size + b->code_size;
   if (b->ir_size && ir[b->ir_size - 1]) return false;
   if (b->disasm_size && ir[(uint64_t)b->ir_size + b->disasm_size - 1]) return false;
   return true;
}

struct compile_job {
   struct radv_compiler_info info;
   struct radv_shader_stage stages[MESA_VULKAN_SHADER_STAGES];
   struct radv_shader_debug_info debug[MESA_VULKAN_SHADER_STAGES], gs_debug;
   struct radv_shader_binary *binaries[MESA_VULKAN_SHADER_STAGES], *gs_binary;
   struct radv_retained_shaders retained;
   const struct radv_graphics_state_key *gfx;
   bool compute, internal, retain, noop;
};
static nir_shader *import_nir(const struct radv_compiler_info *info, nir_shader *source)
{
   if (!source) return NULL;
   struct blob blob; blob_init(&blob);
   nir_serialize(&blob, source, false);
   if (blob.out_of_memory) r4vk_compiler_fail(2);
   struct blob_reader reader; blob_reader_init(&reader, blob.data, blob.size);
   nir_shader *result = nir_deserialize(NULL, &info->nir_options[source->info.stage], &reader);
   blob_finish(&blob);
   if (!result || reader.overrun) r4vk_compiler_fail(3);
   return result;
}
static int compile(void *raw)
{
   struct compile_job *job = raw;
   /* Native RADV does not enable source-location debugging: upstream cache
    * binaries embed process-local filename pointers. Never export those from
    * an isolated compiler arena or persist them as a pipeline cache. */
   if (job->info.key.nir_debug_info) return VK_ERROR_FEATURE_NOT_PRESENT;
   if (!r4vk_glsl_init_or_ref() || !r4vk_printf_init_or_ref() || !r4vk_diagnostics_prepare())
      return VK_ERROR_OUT_OF_HOST_MEMORY;
   /* No shared pipeline/NIR cache or GPU object is mutated by this worker. */
   job->info.enable_nir_cache = false;
   job->info.debug.dump_shaders = 0;
   job->info.debug.dump_meta_shaders = false;
   job->info.debug.dump_shader_stats = false;
   for (unsigned i = 0; i < MESA_VULKAN_SHADER_STAGES; i++) {
      struct radv_shader_stage *stage = &job->stages[i];
      stage->nir = import_nir(&job->info, stage->nir);
      stage->internal_nir = import_nir(&job->info, stage->internal_nir);
      stage->gs_copy_shader = import_nir(&job->info, stage->gs_copy_shader);
   }
   if (job->compute) {
      job->binaries[MESA_SHADER_COMPUTE] = radv_compile_cs(&job->info,
         &job->stages[MESA_SHADER_COMPUTE], job->internal, &job->debug[MESA_SHADER_COMPUTE]);
      if (!job->binaries[MESA_SHADER_COMPUTE]) return VK_ERROR_UNKNOWN;
   } else {
      radv_graphics_shaders_compile(&job->info, NULL, job->stages, job->gfx,
         job->internal, job->retain ? &job->retained : NULL, job->noop, job->debug,
         job->binaries, &job->gs_debug, &job->gs_binary);
   }
   return VK_SUCCESS;
}
static void *copy_bytes(const void *p, size_t size)
{
   if (!p || !size) return NULL;
   void *out = malloc(size);
   if (out) memcpy(out, p, size);
   return out;
}
static void free_debug(struct radv_shader_debug_info *d)
{
   free(d->spirv); free(d->nir_string); free(d->disasm_string); free(d->ir_string);
   free(d->args_string); free(d->statistics); free(d->debug_info);
   memset(d, 0, sizeof(*d));
}
static bool copy_debug(struct radv_shader_debug_info *d, const struct radv_shader_debug_info *s)
{
   *d = (struct radv_shader_debug_info){ .dump_shader = s->dump_shader, .stages = s->stages,
      .spirv_size = s->spirv_size, .debug_info_count = s->debug_info_count };
#define COPY(field, bytes) do { if (s->field) { d->field = copy_bytes(s->field, (bytes)); if (!d->field) goto fail; } } while (0)
   COPY(spirv, s->spirv_size);
   COPY(nir_string, strlen(s->nir_string) + 1);
   COPY(disasm_string, strlen(s->disasm_string) + 1);
   COPY(ir_string, strlen(s->ir_string) + 1);
   COPY(args_string, strlen(s->args_string) + 1);
   COPY(statistics, sizeof(*s->statistics));
   COPY(debug_info, (size_t)s->debug_info_count * sizeof(*s->debug_info));
#undef COPY
   return true;
fail:
   free_debug(d); return false;
}
static VkResult run(struct compile_job *job, struct radv_shader_stage *stages,
   struct radv_retained_shaders *retained, struct radv_shader_debug_info *debug,
   struct radv_shader_binary **binaries, struct radv_shader_debug_info *gs_debug,
   struct radv_shader_binary **gs_binary)
{
   struct r4vk_compiler_job *owner = NULL;
   VkResult result = r4vk_compiler_job_run(compile, job, &owner);
   if (result != VK_SUCCESS) return result;
   struct radv_shader_binary *copies[MESA_VULKAN_SHADER_STAGES] = {0}, *gs_copy = NULL;
   struct radv_shader_debug_info dc[MESA_VULKAN_SHADER_STAGES] = {0}, gd = {0};
   struct radv_retained_shaders rc = {0};
   for (unsigned i = 0; i < MESA_VULKAN_SHADER_STAGES; i++) {
      const struct radv_shader_binary *binary = job->binaries[i];
      if (job->debug[i].debug_info_count || (binary &&
          !r4vk_radv_binary_valid(binary, binary->total_size))) {
         result = VK_ERROR_UNKNOWN; goto done;
      }
   }
   if (job->gs_debug.debug_info_count || (job->gs_binary &&
       !r4vk_radv_binary_valid(job->gs_binary, job->gs_binary->total_size))) {
      result = VK_ERROR_UNKNOWN; goto done;
   }
   /* Only complete, independently owned CPU results leave the joined arena. */
   result = VK_ERROR_OUT_OF_HOST_MEMORY;
   for (unsigned i = 0; i < MESA_VULKAN_SHADER_STAGES; i++) {
      if (job->binaries[i]) {
         copies[i] = copy_bytes(job->binaries[i], job->binaries[i]->total_size);
         if (!copies[i]) goto done;
      }
      if (!copy_debug(&dc[i], &job->debug[i])) goto done;
      rc.stages[i] = job->retained.stages[i];
      rc.stages[i].serialized_nir = NULL;
      if (rc.stages[i].serialized_nir_size) {
         rc.stages[i].serialized_nir = copy_bytes(job->retained.stages[i].serialized_nir, rc.stages[i].serialized_nir_size);
         if (!rc.stages[i].serialized_nir) goto done;
      }
   }
   if (job->gs_binary) {
      gs_copy = copy_bytes(job->gs_binary, job->gs_binary->total_size);
      if (!gs_copy) goto done;
   }
   if (!copy_debug(&gd, &job->gs_debug)) goto done;
   for (unsigned i = 0; i < MESA_VULKAN_SHADER_STAGES; i++) {
      if (job->compute && i != MESA_SHADER_COMPUTE) continue;
      struct radv_shader_stage *stage = job->compute ? stages : &stages[i];
      stage->info = job->stages[i].info; stage->args = job->stages[i].args;
      stage->key = job->stages[i].key; stage->feedback = job->stages[i].feedback;
   }
   if (job->compute) {
      *binaries = copies[MESA_SHADER_COMPUTE]; *debug = dc[MESA_SHADER_COMPUTE];
   } else {
      memcpy(binaries, copies, sizeof(copies)); memcpy(debug, dc, sizeof(dc));
      *gs_binary = gs_copy; *gs_debug = gd;
      if (retained) *retained = rc;
   }
   result = VK_SUCCESS;
done:
   if (result != VK_SUCCESS) {
      for (unsigned i = 0; i < MESA_VULKAN_SHADER_STAGES; i++) {
         free(copies[i]); free_debug(&dc[i]); free(rc.stages[i].serialized_nir);
      }
      free(gs_copy); free_debug(&gd);
   }
   r4vk_compiler_job_destroy(owner);
   return result;
}
VkResult r4vk_radv_compile_compute(const struct radv_compiler_info *info,
   struct radv_shader_stage *stage, bool internal, struct radv_shader_debug_info *debug,
   struct radv_shader_binary **binary)
{
   struct compile_job *job = calloc(1, sizeof(*job));
   if (!job) return VK_ERROR_OUT_OF_HOST_MEMORY;
   job->info = *info; job->stages[MESA_SHADER_COMPUTE] = *stage;
   job->compute = true; job->internal = internal;
   VkResult result = run(job, stage, NULL, debug, binary, NULL, NULL);
   free(job); r4vk_radv_error_record(result); return result;
}
VkResult r4vk_radv_compile_graphics(const struct radv_compiler_info *info,
   struct radv_shader_stage *stages, const struct radv_graphics_state_key *gfx,
   bool internal, struct radv_retained_shaders *retained, bool noop,
   struct radv_shader_debug_info *debug, struct radv_shader_binary **binaries,
   struct radv_shader_debug_info *gs_debug, struct radv_shader_binary **gs_binary)
{
   struct compile_job *job = calloc(1, sizeof(*job));
   if (!job) return VK_ERROR_OUT_OF_HOST_MEMORY;
   job->info = *info; memcpy(job->stages, stages, sizeof(job->stages));
   job->gfx = gfx; job->internal = internal; job->retain = retained != NULL; job->noop = noop;
   VkResult result = run(job, stages, retained, debug, binaries, gs_debug, gs_binary);
   free(job); r4vk_radv_error_record(result); return result;
}
struct part_job {
   const struct aco_compiler_options *options;
   const struct aco_shader_info *info;
   const void *part;
   const struct ac_shader_args *args;
   aco_shader_part_callback *build;
   struct radv_shader_part_binary *binary;
   bool fragment;
};
static int compile_part(void *raw)
{
   struct part_job *job = raw;
   if (!r4vk_diagnostics_prepare()) return VK_ERROR_OUT_OF_HOST_MEMORY;
   if (job->fragment)
      aco_compile_ps_epilog(job->options, job->info, job->part, job->args, job->build, (void **)&job->binary);
   else
      aco_compile_vs_prolog(job->options, job->info, job->part, job->args, job->build, (void **)&job->binary);
   return job->binary ? VK_SUCCESS : VK_ERROR_UNKNOWN;
}
VkResult r4vk_radv_compile_part(bool fragment, const struct aco_compiler_options *options,
   const struct aco_shader_info *info, const void *part, const struct ac_shader_args *args,
   aco_shader_part_callback *build, struct radv_shader_part_binary **out)
{
   struct part_job job = { options, info, part, args, build, NULL, fragment };
   struct r4vk_compiler_job *owner = NULL;
   VkResult result = r4vk_compiler_job_run(compile_part, &job, &owner);
   if (result == VK_SUCCESS) {
      struct radv_shader_part_binary *copy = copy_bytes(job.binary, job.binary->total_size);
      if (copy) *out = copy;
      else result = VK_ERROR_OUT_OF_HOST_MEMORY;
      r4vk_compiler_job_destroy(owner);
   }
   r4vk_radv_error_record(result); return result;
}
