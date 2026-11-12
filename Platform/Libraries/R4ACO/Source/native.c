/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
/* Fixed native ABI integration of the pinned upstream NIR and ACO passes. */
#include "native.h"
#include "aco_interface.h"
#include "ac_gpu_info.h"
#include "ac_shader_args.h"
#include "ac_shader_util.h"
#include "ac_nir.h"
#include "nir.h"
#include "nir_builder.h"
#include "nir_spirv.h"
#include "spirv_info.h"
#include "amdgfxregs.h"

static const struct ac_compiler_info picasso = {
   .gfx_level=GFX9, .max_waves_per_simd=10,
   .num_physical_sgprs_per_simd=800, .num_physical_wave64_vgprs_per_simd=256,
   .num_simd_per_compute_unit=4, .min_sgpr_alloc=16, .max_sgpr_alloc=102,
   .sgpr_alloc_granularity=16, .min_wave64_vgpr_alloc=4, .max_vgpr_alloc=256,
   .wave64_vgpr_alloc_granularity=4, .wave64_vgpr_encode_granularity=4,
   .lds_size_per_workgroup=65536, .has_fast_fma32=true, .has_mad32=true,
   .has_packed_math_16bit=true, .has_fmask=true,
   .has_3d_cube_border_color_mipmap=true, .has_ls_vgpr_init_bug=true,
};
struct binding { struct ac_shader_args args; struct ac_arg descriptors; bool unsupported, textures; };
#include "textures.h"
extern void r4aco_port_check(void);
static void shared_type(const struct glsl_type *type,unsigned *size,unsigned *alignment)
{
   unsigned scalar=glsl_type_is_boolean(type)?4:glsl_get_bit_size(type)/8;
   *size=scalar*glsl_get_vector_elements(type); *alignment=scalar;
}
static bool resources(nir_builder *b,nir_intrinsic_instr *in,void *data)
{
   struct binding *s=data;
   b->cursor=nir_before_instr(&in->instr);
   nir_def *replacement=NULL;
   switch(in->intrinsic) {
   case nir_intrinsic_vulkan_resource_index:
      if(nir_intrinsic_desc_set(in)!=0 || nir_intrinsic_binding(in)>=16 || !nir_src_is_const(in->src[0]) || nir_src_as_uint(in->src[0])!=0) {s->unsupported=true;return false;}
      replacement=nir_vec2(b,nir_iadd_imm(b,in->src[0].ssa,nir_intrinsic_binding(in)),nir_imm_int(b,0));
      break;
   case nir_intrinsic_vulkan_resource_reindex:
      if(!nir_src_is_const(in->src[1]) || nir_src_as_int(in->src[1])!=0) {s->unsupported=true;return false;}
      replacement=nir_vec2(b,nir_iadd(b,nir_channel(b,in->src[0].ssa,0),in->src[1].ssa),nir_channel(b,in->src[0].ssa,1));
      break;
   case nir_intrinsic_load_vulkan_descriptor: replacement=in->src[0].ssa; break;
   case nir_intrinsic_load_ssbo:
   case nir_intrinsic_load_ubo:
   case nir_intrinsic_store_ssbo: {
      unsigned index=in->intrinsic==nir_intrinsic_store_ssbo?1:0;
      nir_def *pointer=nir_pack_64_2x32(b,ac_nir_load_arg(b,&s->args,s->descriptors));
      nir_def *offset=nir_imul_imm(b,in->src[index].ssa,16);
      nir_def *desc=ac_nir_load_smem(b,4,pointer,offset,16,ACCESS_CAN_SPECULATE);
      nir_src_rewrite(&in->src[index],desc);
      return true;
   }
   case nir_intrinsic_get_ssbo_size: {
      nir_def *pointer=nir_pack_64_2x32(b,ac_nir_load_arg(b,&s->args,s->descriptors));
      nir_def *offset=nir_iadd_imm(b,nir_imul_imm(b,in->src[0].ssa,16),8);
      replacement=ac_nir_load_smem(b,1,pointer,offset,4,ACCESS_CAN_SPECULATE);
      break;
   }
   case nir_intrinsic_load_push_constant: {
      if(in->def.bit_size!=32 || !nir_src_is_const(in->src[0]) ||
         (uint64_t)nir_src_as_uint(in->src[0])+nir_intrinsic_base(in)+in->num_components*4>256) {s->unsupported=true;return false;}
      nir_def *pointer=nir_pack_64_2x32(b,ac_nir_load_arg(b,&s->args,s->args.push_constants));
      nir_def *offset=nir_iadd_imm(b,in->src[0].ssa,nir_intrinsic_base(in));
      replacement=ac_nir_load_smem(b,in->num_components,pointer,offset,4,ACCESS_CAN_SPECULATE);
      break;
   }
   default:return false;
   }
   nir_def_replace(&in->def,replacement);
   return true;
}
static void frontend(nir_shader *nir)
{
   NIR_PASS(_,nir,nir_lower_variable_initializers,nir_var_function_temp);
   NIR_PASS(_,nir,nir_lower_returns);
   NIR_PASS(_,nir,nir_inline_functions);
   NIR_PASS(_,nir,nir_opt_copy_prop);
   NIR_PASS(_,nir,nir_opt_constant_folding);
   NIR_PASS(_,nir,nir_opt_deref);
   nir_remove_non_cmat_call_entrypoints(nir);
   NIR_PASS(_,nir,nir_lower_variable_initializers,~0);
   NIR_PASS(_,nir,nir_split_var_copies);
   NIR_PASS(_,nir,nir_split_per_member_structs);
   NIR_PASS(_,nir,nir_remove_dead_variables,nir_var_shader_in|nir_var_shader_out|nir_var_system_value,NULL);
   NIR_PASS(_,nir,nir_lower_system_values);
   const nir_lower_compute_system_values_options csv={.lower_local_invocation_index=true};
   NIR_PASS(_,nir,nir_lower_compute_system_values,&csv);
   NIR_PASS(_,nir,nir_lower_io_vars_to_temporaries,nir_shader_get_entrypoint(nir),nir_var_shader_in|nir_var_shader_out);
   NIR_PASS(_,nir,nir_split_var_copies);
   NIR_PASS(_,nir,nir_lower_global_vars_to_local);
   NIR_PASS(_,nir,nir_lower_var_copies);
   NIR_PASS(_,nir,nir_lower_vars_to_ssa);
   NIR_PASS(_,nir,nir_lower_explicit_io,nir_var_mem_ubo|nir_var_mem_ssbo,nir_address_format_32bit_index_offset);
   NIR_PASS(_,nir,nir_lower_explicit_io,nir_var_mem_push_const,nir_address_format_32bit_offset);
   if(nir->info.stage==MESA_SHADER_COMPUTE) {
      NIR_PASS(_,nir,nir_lower_vars_to_explicit_types,nir_var_mem_shared,shared_type);
      NIR_PASS(_,nir,nir_lower_explicit_io,nir_var_mem_shared,nir_address_format_32bit_offset);
   }
}
static void optimize(nir_shader *nir)
{
   bool progress;
   do {
      r4aco_port_check();
      progress=false;
      NIR_PASS(progress,nir,nir_opt_copy_prop);
      NIR_PASS(progress,nir,nir_opt_remove_phis);
      NIR_PASS(progress,nir,nir_opt_dce);
      NIR_PASS(progress,nir,nir_opt_dead_cf);
      NIR_PASS(progress,nir,nir_opt_cse);
      NIR_PASS(progress,nir,nir_opt_constant_folding);
      NIR_PASS(progress,nir,nir_opt_algebraic);
   } while(progress);
}
static void binary(void **data,const struct ac_shader_config *config,const char *ir,unsigned ir_bytes,
   const char *disasm,unsigned disasm_bytes,struct amd_stats *stats,uint32_t exec_size,
   const uint32_t *code,uint32_t code_dw,const struct aco_symbol *symbols,unsigned num_symbols,
   const struct ac_shader_debug_info *debug,unsigned debug_count)
{
   (void)ir;(void)ir_bytes;(void)disasm;(void)disasm_bytes;(void)stats;(void)debug;(void)debug_count;
   struct r4aco_native *out=*data; R4AcoBinary *m=&out->metadata;
   if(!code_dw || code_dw>4*1024*1024 || !exec_size || exec_size>code_dw*4 || (exec_size&3) || num_symbols>32) {
      m->status=R4ACO_STATUS_CAPACITY; return;
   }
   uint64_t *fixups=(uint64_t *)&m->symbols;
   for(unsigned i=0;i<num_symbols;i++) {
      if(symbols[i].id<aco_symbol_scratch_addr_lo || symbols[i].id>aco_symbol_const_data_addr || symbols[i].offset>=code_dw) {
         m->status=R4ACO_STATUS_COMPILER; return;
      }
      fixups[i]=(uint64_t)symbols[i].offset<<32 | symbols[i].id;
   }
   m->code_bytes=code_dw*4; m->exec_bytes=exec_size;
   m->sgprs=config->num_sgprs; m->vgprs=config->num_vgprs; m->lds_bytes=config->lds_size;
   m->scratch_bytes_per_wave=config->scratch_bytes_per_wave; m->float_mode=config->float_mode;
   m->spi_ps_input_ena=config->spi_ps_input_ena; m->spi_ps_input_addr=config->spi_ps_input_addr;
   m->symbol_count=num_symbols;
   out->code=malloc(m->code_bytes);
   memcpy(out->code,code,m->code_bytes);
   m->status=0;
}
int r4aco_native_compile(const uint32_t *words,size_t count,const char *entry,uint32_t stage,uint32_t flags,uint32_t gfx_profile,struct r4aco_native *out)
{
   memset(out,0,sizeof(*out));
   out->metadata.status=R4ACO_STATUS_COMPILER;
   if(gfx_profile!=902 && gfx_profile!=909)return R4ACO_STATUS_UNSUPPORTED;
   const enum radeon_family family=gfx_profile==909?CHIP_RAVEN2:CHIP_RAVEN;
   /* ac_gpu_info.c: the LS VGPR initialization erratum affects Raven, but
    * not Raven2. Other compiler limits are the common GFX9 wave64 limits. */
   struct ac_compiler_info gpu=picasso;
   gpu.has_ls_vgpr_init_bug=family==CHIP_RAVEN;
   if(stage!=MESA_SHADER_COMPUTE && stage!=MESA_SHADER_VERTEX && stage!=MESA_SHADER_FRAGMENT)return R4ACO_STATUS_UNSUPPORTED;
   /* The job owns all allocation-bearing Mesa globals through Port/Jobs.patch.
    * Diagnostic gates are resident but cannot retain an abandoned worker lock. */
   extern simple_mtx_t fail_dump_mutex;
   memset(&nir_print_lock,0,sizeof(nir_print_lock));
   memset(&fail_dump_mutex,0,sizeof(fail_dump_mutex));
   r4aco_port_check();
   nir_shader_compiler_options nir_options={0}; ac_nir_set_options(&gpu,false,&nir_options);
   /* Match RADV's GFX9 system-value form; hardware supplies reciprocal W. */
   nir_options.frag_coord_form=nir_frag_coord_xy_z_w_separate|nir_frag_coord_use_w_rcp;
   const struct spirv_capabilities caps={.Shader=true,.Matrix=true};
   const struct spirv_to_nir_options options={.environment=NIR_SPIRV_VULKAN,.capabilities=&caps,
      .ubo_addr_format=nir_address_format_32bit_index_offset,.ssbo_addr_format=nir_address_format_32bit_index_offset,
      .shared_addr_format=nir_address_format_32bit_offset,.min_ubo_alignment=16,.min_ssbo_alignment=16,.ignore_replacement=true};
   glsl_type_singleton_init_or_ref();
   nir_shader *nir=spirv_to_nir(words,count,NULL,stage,entry,&options,&nir_options);
   if(!nir) { glsl_type_singleton_decref(); return R4ACO_STATUS_INVALID; }
   int status=R4ACO_STATUS_UNSUPPORTED;
   if((!flags && nir->info.num_textures) || nir->info.num_images || nir->info.workgroup_size_variable)goto done;
   nir_foreach_variable_in_shader(var,nir) {
      if((var->data.mode==nir_var_uniform && (!flags || !glsl_type_is_sampler(var->type))) || var->data.mode==nir_var_image || var->data.mode==nir_var_mem_global ||
         var->data.mode==nir_var_mem_constant || var->data.mode==nir_var_mem_task_payload)goto done;
   }
   frontend(nir); optimize(nir);
   if(nir->info.shared_size>65536)goto done;
   if(stage==MESA_SHADER_COMPUTE && (!nir->info.workgroup_size[0] || !nir->info.workgroup_size[1] || !nir->info.workgroup_size[2] ||
      (uint64_t)nir->info.workgroup_size[0]*nir->info.workgroup_size[1]*nir->info.workgroup_size[2]>1024))goto done;
   nir_lower_io_passes(nir,false);
   NIR_PASS(_,nir,nir_lower_vars_to_ssa);
   optimize(nir);
   nir_shader_gather_info(nir,nir_shader_get_entrypoint(nir));
   if(stage==MESA_SHADER_VERTEX && nir->info.inputs_read)goto done; /* Vertex pulling uses an SSBO. */
   if(stage==MESA_SHADER_FRAGMENT && nir->info.inputs_read & ~(((UINT64_C(1)<<16)-1)<<VARYING_SLOT_VAR0))goto done;
   /* Preserve logical linkage masks before hardware exports replace NIR I/O. */
   const uint64_t inputs_read=nir->info.inputs_read, outputs_written=nir->info.outputs_written;
   struct binding binding={.textures=flags!=0}; struct ac_shader_args *a=&binding.args;
   ac_add_arg(a,AC_ARG_SGPR,2,AC_ARG_CONST_ADDR,&a->ring_offsets);
   ac_add_arg(a,AC_ARG_SGPR,2,AC_ARG_CONST_ADDR,&binding.descriptors);
   ac_add_arg(a,AC_ARG_SGPR,2,AC_ARG_CONST_ADDR,&a->push_constants);
   if(stage==MESA_SHADER_COMPUTE) {
   ac_add_arg(a,AC_ARG_SGPR,3,AC_ARG_VALUE,&a->num_work_groups);
   for(unsigned i=0;i<3;i++)ac_add_arg(a,AC_ARG_SGPR,1,AC_ARG_VALUE,&a->workgroup_ids[i]);
   ac_add_arg(a,AC_ARG_SGPR,1,AC_ARG_VALUE,&a->tg_size);
   ac_add_arg(a,AC_ARG_SGPR,1,AC_ARG_VALUE,&a->scratch_offset);
   ac_add_arg(a,AC_ARG_VGPR,1,AC_ARG_VALUE,&a->local_invocation_id_x);
   ac_add_arg(a,AC_ARG_VGPR,1,AC_ARG_VALUE,&a->local_invocation_id_y);
   ac_add_arg(a,AC_ARG_VGPR,1,AC_ARG_VALUE,&a->local_invocation_id_z);
   } else if(stage==MESA_SHADER_VERTEX) {
      ac_add_arg(a,AC_ARG_SGPR,1,AC_ARG_VALUE,&a->base_vertex);
      ac_add_arg(a,AC_ARG_SGPR,1,AC_ARG_VALUE,&a->start_instance);
      ac_add_arg(a,AC_ARG_SGPR,1,AC_ARG_VALUE,&a->draw_id);
      ac_add_arg(a,AC_ARG_SGPR,1,AC_ARG_VALUE,&a->scratch_offset);
      ac_add_arg(a,AC_ARG_VGPR,1,AC_ARG_VALUE,&a->vertex_id);
      ac_add_arg(a,AC_ARG_VGPR,1,AC_ARG_VALUE,&a->instance_id);
      ac_add_arg(a,AC_ARG_VGPR,1,AC_ARG_VALUE,&a->vs_prim_id);
      ac_add_arg(a,AC_ARG_VGPR,1,AC_ARG_VALUE,NULL);
   } else {
      ac_add_arg(a,AC_ARG_SGPR,1,AC_ARG_VALUE,&a->prim_mask);
      ac_add_arg(a,AC_ARG_SGPR,1,AC_ARG_VALUE,&a->scratch_offset);
      ac_add_arg(a,AC_ARG_VGPR,2,AC_ARG_VALUE,&a->persp_sample);
      ac_add_arg(a,AC_ARG_VGPR,2,AC_ARG_VALUE,&a->persp_center);
      ac_add_arg(a,AC_ARG_VGPR,2,AC_ARG_VALUE,&a->persp_centroid);
      ac_add_arg(a,AC_ARG_VGPR,3,AC_ARG_VALUE,&a->pull_model);
      ac_add_arg(a,AC_ARG_VGPR,2,AC_ARG_VALUE,&a->linear_sample);
      ac_add_arg(a,AC_ARG_VGPR,2,AC_ARG_VALUE,&a->linear_center);
      ac_add_arg(a,AC_ARG_VGPR,2,AC_ARG_VALUE,&a->linear_centroid);
      ac_add_arg(a,AC_ARG_VGPR,1,AC_ARG_VALUE,&a->line_stipple_tex_ena);
      for(unsigned i=0;i<4;i++)ac_add_arg(a,AC_ARG_VGPR,1,AC_ARG_VALUE,&a->frag_pos[i]);
      ac_add_arg(a,AC_ARG_VGPR,1,AC_ARG_VALUE,&a->front_face);
      ac_add_arg(a,AC_ARG_VGPR,1,AC_ARG_VALUE,&a->ancillary);
      ac_add_arg(a,AC_ARG_VGPR,1,AC_ARG_VALUE,&a->sample_coverage);
      ac_add_arg(a,AC_ARG_VGPR,1,AC_ARG_VALUE,&a->pos_fixed_pt);
   }
   enum ac_hw_stage hw=stage==MESA_SHADER_COMPUTE?AC_HW_COMPUTE_SHADER:stage==MESA_SHADER_VERTEX?AC_HW_VERTEX_SHADER:AC_HW_PIXEL_SHADER;
   struct aco_shader_info info={.hw_stage=hw,.wave_size=64,
      .workgroup_size=stage==MESA_SHADER_COMPUTE?nir->info.workgroup_size[0]*nir->info.workgroup_size[1]*nir->info.workgroup_size[2]:64};
   info.lds_size=nir->info.shared_size;
   if(stage==MESA_SHADER_VERTEX) {
      uint8_t offsets[NUM_TOTAL_VARYING_SLOTS]; memset(offsets,0xff,sizeof(offsets));
      for(unsigned i=0;i<32;i++)offsets[VARYING_SLOT_VAR0+i]=i;
      NIR_PASS(_,nir,ac_nir_lower_legacy_vs,GFX9,0,false,offsets,(nir->info.outputs_written>>VARYING_SLOT_VAR0)!=0,false,true,false);
   } else if(stage==MESA_SHADER_FRAGMENT) {
      const ac_nir_lower_ps_late_options ps={.gfx_level=GFX9,.use_aco=true,.spi_shader_col_format=V_028714_SPI_SHADER_32_ABGR};
      NIR_PASS(_,nir,ac_nir_lower_ps_late,&ps);
      info.ps.spi_ps_input_ena=0xffff;
      info.ps.spi_ps_input_addr=0xffff;
      info.ps.num_inputs=util_bitcount64(nir->info.inputs_read);
   }
   nir_shader_intrinsics_pass(nir,resources,nir_metadata_control_flow,&binding);
   nir_shader_instructions_pass(nir,texture_resources,nir_metadata_control_flow,&binding);
   if(binding.unsupported)goto done;
   if(flags) {
      const ac_nir_lower_tex_coords_options tex={.gfx_level=GFX9,.lower_array_layer_round_even=true};
      NIR_PASS(_,nir,ac_nir_lower_tex_coords,&tex);
   }
   const ac_nir_lower_intrinsics_to_args_options lower={.gfx_level=GFX9,.has_ls_vgpr_init_bug=gpu.has_ls_vgpr_init_bug,
      .hw_stage=hw,.wave_size=64,.workgroup_size=info.workgroup_size,.load_grid_size_from_user_sgpr=true};
   NIR_PASS(_,nir,ac_nir_lower_intrinsics_to_args,a,&lower);
   NIR_PASS(_,nir,nir_lower_alu_to_scalar,NULL,NULL);
   NIR_PASS(_,nir,nir_lower_phis_to_scalar,ac_nir_lower_phis_to_scalar_cb,NULL);
   NIR_PASS(_,nir,nir_lower_load_const_to_scalar);
   const nir_lower_idiv_options idiv={.allow_fp16=false};
   NIR_PASS(_,nir,nir_lower_idiv,&idiv);
   NIR_PASS(_,nir,nir_lower_flrp,16|32|64,false);
   optimize(nir);
   NIR_PASS(_,nir,ac_nir_lower_global_access,GFX9);
   /* ACO consumes the late algebraic form (not NIR's canonical ineg/idiv).
    * Cleanup cannot re-run the early algebraic pass and undo that lowering. */
   bool late;
   do {
      r4aco_port_check(); late=false;
      NIR_PASS(late,nir,nir_opt_algebraic_late);
      NIR_PASS(_,nir,nir_opt_constant_folding);
      NIR_PASS(_,nir,nir_opt_copy_prop);
      NIR_PASS(_,nir,nir_opt_dce);
      NIR_PASS(_,nir,nir_opt_cse);
   } while(late);
   nir_shader_gather_info(nir,nir_shader_get_entrypoint(nir));
   nir_validate_shader(nir,"R4ACO native resource ABI1/2");
   r4aco_port_check();
   R4AcoBinary *m=&out->metadata;
   m->user_sgprs=stage==MESA_SHADER_COMPUTE?9:stage==MESA_SHADER_VERTEX?9:6;
   m->input_vgprs=a->num_vgprs_used;
   m->workgroup_x=stage==MESA_SHADER_COMPUTE?nir->info.workgroup_size[0]:0;
   m->workgroup_y=stage==MESA_SHADER_COMPUTE?nir->info.workgroup_size[1]:0;
   m->workgroup_z=stage==MESA_SHADER_COMPUTE?nir->info.workgroup_size[2]:0;
   m->inputs_read=inputs_read; m->outputs_written=outputs_written;
   m->spi_shader_col_format=stage==MESA_SHADER_FRAGMENT?V_028714_SPI_SHADER_32_ABGR:0;
   const struct aco_compiler_options aco={.compiler_info=&gpu,.family=family,.gfx_level=GFX9,.record_ir=false};
   void *result=out;aco_compile_shader(&aco,&info,1,&nir,a,binary,&result);
   status=out->metadata.status;
done:
   ralloc_free(nir);glsl_type_singleton_decref();
   r4aco_port_check();
   return status;
}
