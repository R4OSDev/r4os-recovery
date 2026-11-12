/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VK_NAK_H
#define R4VK_NAK_H
#include <vulkan/vulkan_core.h>
struct nv_device_info;
struct nak_compiler;
struct r4vk_nak_owner;
/* Failure preserves both outputs. The owner retains real NAK allocations
 * across calls and must outlive all uses of the returned compiler. */
VkResult r4vk_nak_create(const struct nv_device_info *info,
   struct r4vk_nak_owner **owner, struct nak_compiler **compiler);
void r4vk_nak_destroy(struct r4vk_nak_owner *owner);
#endif
