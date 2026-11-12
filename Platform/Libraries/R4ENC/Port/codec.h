/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4ENC_CODEC_H
#define R4ENC_CODEC_H
#include "r4enc.h"
#ifdef __cplusplus
extern "C" {
#endif
struct r4enc_codec;
int r4enc_codec_open(const R4EncConfig *, struct r4enc_codec **);
/* Synchronous private call on the owning worker. Public send/receive never
 * execute the codec. Input planes remain immutable for the entire call. */
int r4enc_codec_encode(struct r4enc_codec *, const uint8_t *const [3], const uint64_t [3],
                       int64_t, uint32_t, uint8_t *, uint64_t, uint64_t *, uint32_t *);
void r4enc_codec_close(struct r4enc_codec **);
#ifdef __cplusplus
}
#endif
#endif
