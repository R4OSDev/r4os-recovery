/* Copyright 2026 R4
 * SPDX-License-Identifier: Apache-2.0
 */
#ifndef R4NV_SHADERS_H
#define R4NV_SHADERS_H
#include "nir.h"

/* Stable source profile IDs, independent of Mesa's shader-stage enum. */
enum r4nv_shader_profile {
   R4NV_RECT_VERTEX = 1,
   R4NV_TEXTURE_FRAGMENT = 2,
   R4NV_SRGB_DECODE_FRAGMENT = 3,
   R4NV_SRGB_ENCODE_FRAGMENT = 4,
   R4NV_SOLID_FRAGMENT = 5,
   R4NV_SOLID_VERTEX = 6,
   R4NV_COLOR_FRAGMENT = 7,
   R4NV_YUV_FRAGMENT = 8,
   R4NV_ENCODE_FRAGMENT = 9,
};

nir_shader *r4nv_build_shader(enum r4nv_shader_profile profile,
                            const nir_shader_compiler_options *options);
#endif
