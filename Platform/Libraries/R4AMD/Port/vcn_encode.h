/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4AMD_VCN_ENCODE_H
#define R4AMD_VCN_ENCODE_H
#include <stdint.h>
#define R4AMD_ENCODE_COMMAND_WORDS 2048
#define R4AMD_ENCODE_HEADER_BYTES 1024
#define R4AMD_ENCODE_SESSION_BYTES (128*1024)
struct r4amd_encode_config {
 uint32_t codec, profile, width, height, fps_num, fps_den, transfer;
 uint32_t rate, qp, min_qp, max_qp, target_bps, peak_bps, buffer_bits;
 uint32_t packet_bytes, gop;
};
struct r4amd_encode_requirements { uint32_t dpb_bytes, pitch, rows, chroma_offset, picture_bytes; };
struct r4amd_encode_job {
 uint64_t session, dpb, input, bitstream, feedback;
 uint32_t input_pitch, input_chroma, input_bytes;
 uint32_t serial, frame_num, poc, idr_id, key, reference, reconstructed;
};
/* All failures preserve output. operation:0 initialize,1 encode,2 close.
 * Scratch is caller-owned, aligned to8 and at least scratch_bytes() large. */
uint32_t r4amd_encode_scratch_bytes(void);
int r4amd_encode_plan(const struct r4amd_encode_config*,struct r4amd_encode_requirements*);
int r4amd_encode_headers(void*,const struct r4amd_encode_config*,uint8_t*,uint32_t*);
int r4amd_encode_commands(void*,const struct r4amd_encode_config*,const struct r4amd_encode_job*,uint32_t,uint32_t*,uint32_t*);
#endif
