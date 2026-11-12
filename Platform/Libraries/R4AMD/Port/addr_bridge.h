/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#pragma once
#include "r4amd.h"
#ifdef __cplusplus
extern "C" {
#endif
int32_t r4amd_addr_compute(const R4AmdImageRequest *, void *, uint32_t,
                         R4AmdImageLayout *, R4AmdMip *, const R4AmdCoordinate *,
                         R4AmdImageAddress *, R4AmdMetadata *);
int32_t r4amd_addr_descriptors(const R4AmdImageRequest *, const R4AmdImageLayout *,
                             const R4AmdImageView *, R4AmdImageDescriptors *);
#ifdef __cplusplus
}
#endif
