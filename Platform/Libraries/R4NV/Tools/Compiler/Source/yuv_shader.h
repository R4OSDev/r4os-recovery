/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
 * Video fragment: three integer texture handles at CBuf1 bytes0/4/8.
 * CBuf2 retains the common color program. CBuf3 is256 bytes:
 * 0:u4(format1NV12/2P010/3YUV420P, RGB bilinear0/1,0,0)
 * 16/32/48:float4 normalized YCbCr-to-electrical-RGB affine rows
 * 64:float3(chroma origin x,y,1/code_max), u32 storage right shift
 * 80:float4(first luma x,y,last luma x,y) in absolute coded sample centers
 * 96:float4(coded width,height,chroma width,height);112..255 zero.
 * Integer texel loads discard P010 padding before chroma reconstruction.
 * All coordinates are clamped against admitted plane/crop bounds. No readback
 * or full-size RGB intermediate. Interpolation after the EOTF is linear RGB.
 */
#ifndef R4NV_YUV_SHADER_H
#define R4NV_YUV_SHADER_H

static nir_def *r4y_uniform(nir_builder *b, unsigned offset)
{
   return nir_ldc_nv(b, 4, 32, nir_imm_int(b, 3), nir_imm_int(b, offset),
                     .align_mul = 16, .align_offset = 0);
}
static nir_def *r4y_texel(nir_builder *b, unsigned plane, nir_def *position)
{
   nir_def *handle = nir_ldc_nv(b, 1, 32, nir_imm_int(b, 1), nir_imm_int(b, plane * 4),
                               .align_mul = 4, .align_offset = 0);
   nir_tex_instr *tex = nir_tex_instr_create(b->shader, 3);
   tex->op = nir_texop_txf;
   tex->sampler_dim = GLSL_SAMPLER_DIM_2D;
   tex->dest_type = nir_type_uint32;
   tex->coord_components = 2;
   tex->src[0] = (nir_tex_src) { .src_type = nir_tex_src_coord, .src = nir_src_for_ssa(position) };
   tex->src[1] = (nir_tex_src) { .src_type = nir_tex_src_texture_handle, .src = nir_src_for_ssa(handle) };
   tex->src[2] = (nir_tex_src) { .src_type = nir_tex_src_lod, .src = nir_src_for_ssa(nir_imm_int(b, 0)) };
   nir_def_init(&tex->instr, &tex->def, 4, 32);
   nir_builder_instr_insert(b, &tex->instr);
   nir_def *packing = r4y_uniform(b, 64);
   return nir_fmul(b, nir_u2f32(b, nir_ushr(b, &tex->def, nir_channel(b, packing, 3))), nir_channel(b, packing, 2));
}
static nir_def *r4y_chroma(nir_builder *b, nir_def *position)
{
   nir_def *first = r4y_texel(b, 1, position);
   nir_push_if(b, nir_ieq_imm(b, nir_channel(b, r4y_uniform(b, 0), 0), 3));
   nir_def *separate = nir_vec2(b, nir_channel(b, first, 0), nir_channel(b, r4y_texel(b, 2, position), 0));
   nir_push_else(b, NULL);
   nir_def *paired = nir_channels(b, first, 3);
   nir_pop_if(b, NULL);
   return nir_if_phi(b, separate, paired);
}
static nir_def *r4y_decode(nir_builder *b, nir_def *position)
{
   nir_def *luma = nir_channel(b, r4y_texel(b, 0, position), 0);
   nir_def *last = nir_fadd_imm(b, nir_channels(b, r4y_uniform(b, 96), 12), -1);
   nir_def *chroma = nir_fmul_imm(b, nir_fsub(b, nir_i2f32(b, position), nir_channels(b, r4y_uniform(b, 64), 3)), 0.5);
   chroma = nir_fmin(b, nir_fmax(b, chroma, nir_imm_vec2(b, 0, 0)), last);
   nir_def *low = nir_ffloor(b, chroma), *high = nir_fmin(b, nir_fadd_imm(b, low, 1), last);
   nir_def *fraction = nir_fsub(b, chroma, low);
   nir_def *x0 = nir_f2i32(b, nir_channel(b, low, 0)), *x1 = nir_f2i32(b, nir_channel(b, high, 0));
   nir_def *y0 = nir_f2i32(b, nir_channel(b, low, 1)), *y1 = nir_f2i32(b, nir_channel(b, high, 1));
   nir_def *top = nir_flrp(b, r4y_chroma(b, nir_vec2(b, x0, y0)), r4y_chroma(b, nir_vec2(b, x1, y0)), nir_channel(b, fraction, 0));
   nir_def *bottom = nir_flrp(b, r4y_chroma(b, nir_vec2(b, x0, y1)), r4y_chroma(b, nir_vec2(b, x1, y1)), nir_channel(b, fraction, 0));
   nir_def *uv = nir_flrp(b, top, bottom, nir_channel(b, fraction, 1));
   nir_def *code = nir_vec4(b, luma, nir_channel(b, uv, 0), nir_channel(b, uv, 1), nir_imm_float(b, 1));
   nir_def *rgb[3];
   for (unsigned i = 0; i < 3; ++i) rgb[i] = nir_fdot4(b, code, r4y_uniform(b, 16 + 16 * i));
   return r4nv_color_decode(b, nir_vec4(b, rgb[0], rgb[1], rgb[2], nir_imm_float(b, 1)));
}
static nir_def *r4nv_yuv_transform(nir_builder *b, nir_def *uv, nir_def *opacity)
{
   nir_def *bounds = r4y_uniform(b, 80), *size = r4y_uniform(b, 96);
   nir_def *position = nir_fadd_imm(b, nir_fmul(b, uv, nir_channels(b, size, 3)), -0.5);
   position = nir_fmin(b, nir_fmax(b, position, nir_channels(b, bounds, 3)), nir_channels(b, bounds, 12));
   nir_def *bilinear = nir_ine_imm(b, nir_channel(b, r4y_uniform(b, 0), 1), 0);
   nir_def *floor = nir_ffloor(b, position), *weight = nir_fsub(b, position, floor);
   nir_def *origin = nir_bcsel(b, bilinear, floor, nir_ffloor(b, nir_fadd_imm(b, position, 0.5)));
   nir_variable *index = nir_local_variable_create(b->impl, glsl_uint_type(), "yuv_sample");
   nir_variable *sum = nir_local_variable_create(b->impl, glsl_vec4_type(), "yuv_linear_sum");
   nir_store_var(b, index, nir_imm_int(b, 0), 1);
   nir_store_var(b, sum, nir_imm_vec4(b, 0, 0, 0, 0), 15);
   // A bounded uniform1/4 sample loop keeps one color decoder in the program.
   nir_push_loop(b);
   nir_def *i = nir_load_var(b, index);
   nir_push_if(b, nir_uge(b, i, nir_bcsel(b, bilinear, nir_imm_int(b, 4), nir_imm_int(b, 1))));
   nir_jump(b, nir_jump_break);
   nir_pop_if(b, NULL);
   nir_def *x = nir_iand_imm(b, i, 1), *y = nir_ushr_imm(b, i, 1);
   nir_def *sample = nir_fmin(b, nir_fadd(b, origin, nir_u2f32(b, nir_vec2(b, x, y))), nir_channels(b, bounds, 12));
   nir_def *wx = nir_channel(b, weight, 0), *wy = nir_channel(b, weight, 1);
   nir_def *gain = nir_bcsel(b, bilinear, nir_fmul(b,
      nir_bcsel(b, nir_ieq_imm(b, x, 0), nir_fsub(b, nir_imm_float(b, 1), wx), wx),
      nir_bcsel(b, nir_ieq_imm(b, y, 0), nir_fsub(b, nir_imm_float(b, 1), wy), wy)), nir_imm_float(b, 1));
   nir_store_var(b, sum, nir_fadd(b, nir_load_var(b, sum), nir_fmul(b, r4y_decode(b, nir_f2i32(b, sample)), gain)), 15);
   nir_store_var(b, index, nir_iadd_imm(b, i, 1), 1);
   nir_pop_loop(b, NULL);
   return r4nv_color_encode(b, nir_load_var(b, sum), opacity);
}
#endif
