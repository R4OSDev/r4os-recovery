/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VK_RADV_COMPILE_H
#define R4VK_RADV_COMPILE_H
#include "radv_shader.h"
#include "radv_pipeline_graphics.h"
#include "aco_interface.h"
VkResult r4vk_radv_compile_compute(const struct radv_compiler_info *, struct radv_shader_stage *,
   bool, struct radv_shader_debug_info *, struct radv_shader_binary **);
VkResult r4vk_radv_compile_graphics(const struct radv_compiler_info *, struct radv_shader_stage *,
   const struct radv_graphics_state_key *, bool, struct radv_retained_shaders *, bool,
   struct radv_shader_debug_info *, struct radv_shader_binary **,
   struct radv_shader_debug_info *, struct radv_shader_binary **);
void r4vk_radv_error_reset(void);
void r4vk_radv_error_record(VkResult);
VkResult r4vk_radv_error_result(VkResult);
bool r4vk_radv_binary_valid(const struct radv_shader_binary *, size_t);
VkResult r4vk_radv_compile_part(bool, const struct aco_compiler_options *,
   const struct aco_shader_info *, const void *, const struct ac_shader_args *,
   aco_shader_part_callback *, struct radv_shader_part_binary **);
#endif
