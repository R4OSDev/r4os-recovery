/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4GL_VULKAN_H
#define R4GL_VULKAN_H
#include <vulkan/vulkan_core.h>
/* Process-owned optional R4VK import. This is the native ICD path; there is
 * no host loader, implicit device selection layer, or invented device. */
PFN_vkVoidFunction r4gl_native_vulkan_proc(VkInstance instance, const char *name);
unsigned r4gl_native_profile(void);
#endif
