/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VK_NIL_H
#define R4VK_NIL_H
#include "nil.h"
#include "vulkan/vulkan_core.h"

/* Original NIL layout calculation, isolated from the caller's C stack.
 * Failures preserve the complete output; resource OOM remains distinct from
 * a rejected layout. Inputs remain live until the disposable worker joins. */
VkResult r4vk_nil_image_init(const struct nv_device_info *dev,
                           struct nil_image *out,
                           const struct nil_image_init_info *info);
VkResult r4vk_nil_image_init_planar(const struct nv_device_info *dev,
                                  struct nil_image *out,
                                  const struct nil_image_init_info *info,
                                  size_t plane, size_t plane_count);
#endif
