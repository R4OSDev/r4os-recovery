/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
 * Fixed color pipeline, CBuf2/256 bytes. R4GFX supplies the matrices,
 * reference luminance, range and tone-map coefficients. No ICC parser or
 * display policy runs in this shader or the kernel.
 * 0:u4(flags,src transfer,dst transfer,src alpha),16:u4(dst alpha,0,0,0)
 * 32/80:three float4 matrix rows,128/144:float4(white,peak,HLG gamma,beta)
 * BT.1886 uses gamma slot1 and beta=(black/white)^(1/2.4).
 * 160:float4(src range gain,bias,dst range gain,bias)
 * 176:float4(gain,source peak,knee,shoulder),192:float4(target peak,quantum,0,0)
 * 208..255:zero. Flags:1 output tone/gamut mapping,2 ordered dither.
 * Transfers:1 sRGB,2 linear,3 PQ,4 HLG,6 BT.1886. Alpha:1 opaque,2 straight,
 * 3 encoded premultiplied,4 linear premultiplied. */
#ifndef R4NV_COLOR_SHADER_H
#define R4NV_COLOR_SHADER_H

static nir_def *r4c_max(nir_builder *b, nir_def *value, double minimum)
{
   return nir_fmax(b, value, nir_imm_float(b, minimum));
}

static nir_def *r4c_uniform(nir_builder *b, unsigned offset)
{
   return nir_ldc_nv(b, 4, 32, nir_imm_int(b, 2), nir_imm_int(b, offset),
                     .align_mul = 16, .align_offset = 0);
}
static nir_def *r4c_matrix(nir_builder *b, unsigned offset, nir_def *rgb)
{
   return nir_vec3(b,
      nir_fdot3(b, nir_channels(b, r4c_uniform(b, offset), 7), rgb),
      nir_fdot3(b, nir_channels(b, r4c_uniform(b, offset + 16), 7), rgb),
      nir_fdot3(b, nir_channels(b, r4c_uniform(b, offset + 32), 7), rgb));
}
static nir_def *r4c_luminance(nir_builder *b, nir_def *rgb)
{
   return nir_fdot3(b, rgb, nir_imm_vec3(b, 0.26270021, 0.67799807, 0.05930172));
}
static nir_def *r4c_srgb(nir_builder *b, nir_def *value, bool encode)
{
   nir_def *x = nir_fabs(b, value);
   nir_def *low, *high;
   if (encode) {
      low = nir_fmul_imm(b, x, 12.92);
      high = nir_fadd_imm(b, nir_fmul_imm(b, nir_fpow(b, x, nir_imm_float(b, 1.0 / 2.4)), 1.055), -0.055);
   } else {
      low = nir_fmul_imm(b, x, 1.0 / 12.92);
      high = nir_fpow(b, nir_fmul_imm(b, nir_fadd_imm(b, x, 0.055), 1.0 / 1.055), nir_imm_float(b, 2.4));
   }
   return nir_fmul(b, nir_fsign(b, value), nir_bcsel(b,
      nir_fge(b, nir_imm_float(b, encode ? 0.0031308 : 0.04045), x), low, high));
}
static nir_def *r4c_pq(nir_builder *b, nir_def *value, bool encode)
{
   const double m1 = 2610.0 / 16384.0, m2 = 2523.0 / 32.0;
   const double c1 = 3424.0 / 4096.0, c2 = 2413.0 / 128.0, c3 = 2392.0 / 128.0;
   if (encode) {
      nir_def *p = nir_fpow(b, nir_fsat(b, nir_fmul_imm(b, value, 0.0001)), nir_imm_float(b, m1));
      return nir_fpow(b, nir_fdiv(b, nir_fadd_imm(b, nir_fmul_imm(b, p, c2), c1),
         nir_fadd_imm(b, nir_fmul_imm(b, p, c3), 1)), nir_imm_float(b, m2));
   }
   nir_def *p = nir_fpow(b, nir_fsat(b, value), nir_imm_float(b, 1 / m2));
   nir_def *numerator = r4c_max(b, nir_fadd_imm(b, p, -c1), 0);
   nir_def *denominator = nir_fadd_imm(b, nir_fmul_imm(b, p, -c3), c2);
   return nir_fmul_imm(b, nir_fpow(b, nir_fdiv(b, numerator, denominator), nir_imm_float(b, 1 / m1)), 10000);
}
static nir_def *r4c_hlg(nir_builder *b, nir_def *rgb, nir_def *params, bool encode)
{
   nir_def *peak = nir_channel(b, params, 1), *gamma = nir_channel(b, params, 2), *beta = nir_channel(b, params, 3);
   nir_def *one_minus_beta = nir_fsub(b, nir_imm_float(b, 1), beta);
   if (!encode) {
      nir_def *x = nir_fadd(b, nir_fmul(b, one_minus_beta, nir_fsat(b, rgb)), beta);
      nir_def *low = nir_fmul_imm(b, nir_fmul(b, x, x), 1.0 / 3);
      nir_def *high = nir_fmul_imm(b, nir_fadd_imm(b,
         nir_fexp2(b, nir_fmul_imm(b, nir_fadd_imm(b, x, -0.55991073), 1.4426950408889634 / 0.17883277)), 0.28466892), 1.0 / 12);
      nir_def *scene = nir_bcsel(b, nir_fge(b, nir_imm_float(b, 0.5), x), low, high);
      nir_def *y = r4c_luminance(b, scene);
      nir_def *factor = nir_fmul(b, peak, nir_fpow(b, r4c_max(b, y, 1e-20), nir_fadd_imm(b, gamma, -1)));
      return nir_bcsel(b, nir_fgt_imm(b, y, 0), nir_fmul(b, scene, factor), nir_imm_vec3(b, 0, 0, 0));
   }
   nir_def *y = r4c_max(b, nir_fdiv(b, r4c_luminance(b, rgb), peak), 0);
   nir_def *factor = nir_fdiv(b, nir_fpow(b, r4c_max(b, y, 1e-20),
      nir_fdiv(b, nir_fsub(b, nir_imm_float(b, 1), gamma), gamma)), peak);
   nir_def *x = nir_fsat(b, nir_bcsel(b, nir_fgt_imm(b, y, 0), nir_fmul(b, rgb, factor), nir_imm_vec3(b, 0, 0, 0)));
   nir_def *low = nir_fsqrt(b, nir_fmul_imm(b, x, 3));
   nir_def *high = nir_fadd_imm(b, nir_fmul_imm(b,
      nir_flog2(b, r4c_max(b, nir_fadd_imm(b, nir_fmul_imm(b, x, 12), -0.28466892), 1e-20)), 0.17883277 / 1.4426950408889634), 0.55991073);
   nir_def *signal = nir_bcsel(b, nir_fge(b, nir_imm_float(b, 1.0 / 12), x), low, high);
   return nir_fsat(b, nir_fdiv(b, nir_fsub(b, signal, beta), one_minus_beta));
}
static nir_def *r4c_transfer(nir_builder *b, nir_def *rgb, nir_def *tag, nir_def *params, bool encode)
{
   nir_push_if(b, nir_ieq_imm(b, tag, 1));
   nir_def *srgb = encode ? r4c_srgb(b, nir_fdiv(b, rgb, nir_channel(b, params, 0)), true) :
      nir_fmul(b, r4c_srgb(b, rgb, false), nir_channel(b, params, 0));
   nir_push_else(b, NULL);
   nir_push_if(b, nir_ieq_imm(b, tag, 2));
   nir_def *linear = encode ? nir_fdiv(b, rgb, nir_channel(b, params, 0)) : nir_fmul(b, rgb, nir_channel(b, params, 0));
   nir_push_else(b, NULL);
   nir_push_if(b, nir_ieq_imm(b, tag, 3));
   nir_def *pq = r4c_pq(b, rgb, encode);
   nir_push_else(b, NULL);
   nir_push_if(b, nir_ieq_imm(b, tag, 6));
   nir_def *white = nir_channel(b, params, 0), *lift = nir_channel(b, params, 3);
   nir_def *gain = nir_fsub(b, nir_imm_float(b, 1), lift);
   nir_def *video;
   if (encode) {
      nir_def *light = r4c_max(b, nir_fdiv(b, rgb, white), 0);
      video = nir_fdiv(b, nir_fsub(b, nir_fpow(b, light, nir_imm_float(b, 1.0 / 2.4)), lift), gain);
   } else {
      nir_def *signal = r4c_max(b, nir_fadd(b, nir_fmul(b, rgb, gain), lift), 0);
      video = nir_fmul(b, nir_fpow(b, signal, nir_imm_float(b, 2.4)), white);
   }
   nir_push_else(b, NULL);
   nir_def *hlg = r4c_hlg(b, rgb, params, encode);
   nir_pop_if(b, NULL);
   nir_def *display = nir_if_phi(b, video, hlg);
   nir_pop_if(b, NULL);
   nir_def *hdr = nir_if_phi(b, pq, display);
   nir_pop_if(b, NULL);
   nir_def *other = nir_if_phi(b, linear, hdr);
   nir_pop_if(b, NULL);
   return nir_if_phi(b, srgb, other);
}
static nir_def *r4c_gamut(nir_builder *b, nir_def *rgb, nir_def *y, nir_def *peak)
{
   nir_def *gray = nir_fmin(b, r4c_max(b, y, 0), peak);
   nir_def *saturation = nir_imm_float(b, 1);
   for (unsigned i = 0; i < 3; ++i) {
      nir_def *delta = nir_fsub(b, nir_channel(b, rgb, i), gray);
      nir_def *safe_delta = nir_bcsel(b, nir_fneu_imm(b, delta, 0), delta, nir_imm_float(b, 1));
      nir_def *limit = nir_bcsel(b, nir_fgt_imm(b, delta, 0),
         nir_fdiv(b, nir_fsub(b, peak, gray), safe_delta), nir_fdiv(b, nir_fneg(b, gray), safe_delta));
      saturation = nir_fmin(b, saturation, nir_bcsel(b, nir_fneu_imm(b, delta, 0), limit, nir_imm_float(b, 1)));
   }
   return nir_fadd(b, gray, nir_fmul(b, nir_fsub(b, rgb, gray), saturation));
}
static nir_def *r4c_dither(nir_builder *b)
{
   nir_def *xy = nir_f2u32(b, nir_channels(b, nir_load_frag_coord(b), 3));
   nir_def *x = nir_channel(b, xy, 0), *y = nir_channel(b, xy, 1), *index = nir_imm_int(b, 0);
   for (unsigned bit = 0; bit < 3; ++bit) {
      nir_def *xb = nir_iand_imm(b, nir_ushr_imm(b, x, bit), 1);
      nir_def *yb = nir_iand_imm(b, nir_ushr_imm(b, y, bit), 1);
      nir_def *digit = nir_ior(b, nir_ishl_imm(b, nir_ixor(b, xb, yb), 1), yb);
      index = nir_ior(b, index, nir_ishl_imm(b, digit, 2 * (2 - bit)));
   }
   return nir_fadd_imm(b, nir_fmul_imm(b, nir_u2f32(b, index), 1.0 / 64), -31.5 / 64);
}
static nir_def *r4nv_color_decode(nir_builder *b, nir_def *rgba)
{
   nir_def *head = r4c_uniform(b, 0);
   nir_def *source_alpha = nir_channel(b, head, 3);
   nir_def *a = nir_bcsel(b, nir_ieq_imm(b, source_alpha, 1), nir_imm_float(b, 1), nir_fsat(b, nir_channel(b, rgba, 3)));
   nir_def *safe_a = nir_bcsel(b, nir_fgt_imm(b, a, 0), a, nir_imm_float(b, 1));
   nir_def *ranges = r4c_uniform(b, 160);
   nir_def *rgb = nir_fadd(b, nir_fmul(b, nir_channels(b, rgba, 7), nir_channel(b, ranges, 0)), nir_channel(b, ranges, 1));
   rgb = nir_bcsel(b, nir_ieq_imm(b, source_alpha, 3), nir_fdiv(b, rgb, safe_a), rgb);
   rgb = r4c_transfer(b, rgb, nir_channel(b, head, 1), r4c_uniform(b, 128), false);
   rgb = nir_bcsel(b, nir_ieq_imm(b, source_alpha, 4), rgb, nir_fmul(b, rgb, a));
   rgb = nir_bcsel(b, nir_fgt_imm(b, a, 0), r4c_matrix(b, 32, rgb), nir_imm_vec3(b, 0, 0, 0));
   return nir_vec4(b, nir_channel(b, rgb, 0), nir_channel(b, rgb, 1), nir_channel(b, rgb, 2), a);
}
static nir_def *r4nv_color_encode(nir_builder *b, nir_def *rgba, nir_def *opacity)
{
   nir_def *head = r4c_uniform(b, 0), *tail = r4c_uniform(b, 16);
   nir_def *flags = nir_channel(b, head, 0), *target_alpha = nir_channel(b, tail, 0);
   nir_def *ranges = r4c_uniform(b, 160);
   nir_def *rgb = nir_channels(b, rgba, 7), *a = nir_channel(b, rgba, 3);
   nir_def *tone = r4c_uniform(b, 176), *target = r4c_uniform(b, 192);
   rgb = nir_fmul(b, rgb, nir_fmul(b, nir_channel(b, tone, 0), opacity));
   a = nir_fmul(b, a, opacity);
   nir_def *safe_a = nir_bcsel(b, nir_fgt_imm(b, a, 0), a, nir_imm_float(b, 1));
   nir_def *output = nir_ine_imm(b, nir_iand_imm(b, flags, 1), 0);
   nir_push_if(b, output);
   nir_def *y = nir_fdiv(b, r4c_luminance(b, rgb), safe_a);
   nir_def *mapped = nir_fmin(b, y, nir_channel(b, tone, 1));
   nir_def *excess = r4c_max(b, nir_fsub(b, mapped, nir_channel(b, tone, 2)), 0);
   nir_def *shoulder = nir_fadd(b, nir_channel(b, tone, 2), nir_fdiv(b, excess,
      nir_fadd_imm(b, nir_fmul(b, nir_channel(b, tone, 3), excess), 1)));
   mapped = nir_bcsel(b, nir_fgt_imm(b, excess, 0), shoulder, mapped);
   nir_def *scale = nir_fdiv(b, nir_fmin(b, mapped, nir_channel(b, target, 0)), nir_bcsel(b, nir_fgt_imm(b, y, 0), y, nir_imm_float(b, 1)));
   nir_def *toned = nir_bcsel(b, nir_fgt_imm(b, y, 0), nir_fmul(b, rgb, scale), rgb);
   nir_push_else(b, NULL);
   nir_pop_if(b, NULL);
   rgb = nir_if_phi(b, toned, rgb);
   nir_def *target_a = nir_bcsel(b, nir_ieq_imm(b, target_alpha, 1), nir_imm_float(b, 1), a);
   nir_def *safe_target_a = nir_bcsel(b, nir_fgt_imm(b, target_a, 0), target_a, nir_imm_float(b, 1));
   nir_def *out_rgb = r4c_matrix(b, 80, rgb);
   nir_push_if(b, output);
   nir_def *gamut = nir_fmul(b, r4c_gamut(b, nir_fdiv(b, out_rgb, safe_target_a),
      nir_fdiv(b, r4c_luminance(b, rgb), safe_target_a), nir_channel(b, target, 0)), target_a);
   nir_push_else(b, NULL);
   nir_pop_if(b, NULL);
   out_rgb = nir_if_phi(b, gamut, out_rgb);
   out_rgb = nir_bcsel(b, nir_ieq_imm(b, target_alpha, 4), out_rgb, nir_fdiv(b, out_rgb, safe_target_a));
   out_rgb = r4c_transfer(b, out_rgb, nir_channel(b, head, 2), r4c_uniform(b, 144), true);
   out_rgb = nir_bcsel(b, nir_ieq_imm(b, target_alpha, 3), nir_fmul(b, out_rgb, target_a), out_rgb);
   out_rgb = nir_bcsel(b, nir_fgt_imm(b, target_a, 0), out_rgb, nir_imm_vec3(b, 0, 0, 0));
   out_rgb = nir_fadd(b, nir_fmul(b, out_rgb, nir_channel(b, ranges, 2)), nir_channel(b, ranges, 3));
   nir_def *noise = nir_fmul(b, r4c_dither(b), nir_channel(b, target, 1));
   out_rgb = nir_fadd(b, out_rgb, nir_bcsel(b, nir_ine_imm(b, nir_iand_imm(b, flags, 2), 0), noise, nir_imm_float(b, 0)));
   return nir_vec4(b, nir_channel(b, out_rgb, 0), nir_channel(b, out_rgb, 1), nir_channel(b, out_rgb, 2), target_a);
}
static nir_def *r4nv_color_transform(nir_builder *b, nir_def *rgba, nir_def *opacity)
{
   return r4nv_color_encode(b, r4nv_color_decode(b, rgba), opacity);
}
#endif
