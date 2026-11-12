/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VK_PLATFORM_H
#define R4VK_PLATFORM_H
#include <stdint.h>
#include <vulkan/vulkan_core.h>
#ifdef __cplusplus
extern "C" {
#endif

/* The final native link must supply the digest of its verified build inputs.
 * R4M0 has no ELF build-id note at runtime. There is no zero/default identity
 * definition: an incomplete build must fail to link instead of sharing cache
 * identity with a different compiler or resource ABI. */
extern const uint8_t r4vk_build_identity[32];
int r4vk_negotiate_icd_version(uint32_t *version);
uint32_t r4vk_get_icd_version(void);
struct vk_instance;
struct nvk_instance;
void r4vk_nvk_init_instance_options(struct nvk_instance *instance);
VkResult r4vk_nvk_enumerate_physical_devices(struct vk_instance *instance);

#ifdef __cplusplus
}
#endif
#endif
