/* Copyright 2020 Valve Corporation. Copyright 2026 R4.
 * SPDX-License-Identifier: MIT
 * Descriptor replacement follows Mesa radv_nir_lower_descriptors.c.
 * Original notice and complete MIT terms remain in ThirdParty.
 */
/* Native resource ABI2 keeps set0's sixteen 16-byte buffers unchanged.
 * Set1 holds four combined 2D image/sampler records at 256 + binding*64:
 * eight image DWORDs, four sampler DWORDs and sixteen reserved zero bytes.
 * Only the caller owns the GPU table; the compiler emits real scalar loads. */
static bool texture_resources(nir_builder *b,nir_instr *instruction,void *data)
{
   if(instruction->type!=nir_instr_type_tex)return false;
   struct binding *s=data;
   nir_tex_instr *tex=nir_instr_as_tex(instruction);
   if(!s->textures || tex->sampler_dim!=GLSL_SAMPLER_DIM_2D || tex->is_array ||
      tex->is_shadow || tex->texture_non_uniform || tex->sampler_non_uniform ||
      (tex->op!=nir_texop_tex && tex->op!=nir_texop_txl && tex->op!=nir_texop_txf)) {
      s->unsupported=true;return false;
   }
   b->cursor=nir_before_instr(instruction);
   bool image=false;
   for(unsigned i=0;i<tex->num_srcs;i++) {
      bool sampler=tex->src[i].src_type==nir_tex_src_sampler_deref;
      if(!sampler && tex->src[i].src_type!=nir_tex_src_texture_deref)continue;
      nir_deref_instr *deref=nir_src_as_deref(tex->src[i].src);
      if(!deref || deref->deref_type!=nir_deref_type_var || deref->var->data.descriptor_set!=1 ||
         deref->var->data.binding>=4) {s->unsupported=true;return false;}
      unsigned offset=256+deref->var->data.binding*64+(sampler?32:0);
      nir_def *pointer=nir_pack_64_2x32(b,ac_nir_load_arg(b,&s->args,s->descriptors));
      nir_def *descriptor=ac_nir_load_smem(b,sampler?4:8,pointer,nir_imm_int(b,offset),16,ACCESS_CAN_SPECULATE);
      tex->src[i].src_type=sampler?nir_tex_src_sampler_handle:nir_tex_src_texture_handle;
      nir_src_rewrite(&tex->src[i].src,descriptor);
      image|=!sampler;
   }
   if(!image)s->unsupported=true;
   return image;
}
