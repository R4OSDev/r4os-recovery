/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4AMD_VCN_CODECS_H
#define R4AMD_VCN_CODECS_H
#include <stdint.h>
/* Private source interface, compiled into the media owner, not BACKEND_V1.
 * All storage belongs to the caller. No global sessions, allocator or DRM. */
#define R4AMD_VCN_EMBEDDED 8192
#define R4AMD_VCN_ITS 4096
#define R4AMD_VCN_FEEDBACK 7936
struct r4amd_vcn_sequence { uint32_t codec, profile, level, width, height, depth, refs; };
struct r4amd_vcn_requirements { uint32_t dpb, context, session, pitch, height, uv_height, y_size, uv_size; };
struct r4amd_vcn_target { uint32_t pitch, chroma_offset, bytes; };
int r4amd_vcn_plan(const struct r4amd_vcn_sequence *, struct r4amd_vcn_requirements *);
int r4amd_vcn_create(const struct r4amd_vcn_sequence *, uint32_t handle, void *embedded);
int r4amd_vcn_context(const struct r4amd_vcn_sequence *, void *session, uint32_t bytes);
int r4amd_vcn_jpeg(const struct r4amd_vcn_sequence *, const struct r4amd_vcn_target *,
    uint64_t bitstream_va, uint32_t bitstream_bytes, uint64_t target_va, uint32_t commands[128]);
/* Reference IDs in parameters are indices into slots; 255 means absent. */
int r4amd_vcn_message(const struct r4amd_vcn_sequence *, const struct r4amd_vcn_target *,
    const void *parameters, uint32_t parameter_bytes, const uint32_t *slots, uint32_t refs,
    uint32_t current, uint32_t handle, uint32_t serial, uint32_t bitstream_bytes, void *embedded);
#endif
