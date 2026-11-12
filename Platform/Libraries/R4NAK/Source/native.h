/* Copyright 2026 R4; SPDX-License-Identifier: Apache-2.0 */
#ifndef R4NAK_NATIVE_H
#define R4NAK_NATIVE_H
#include <stdint.h>
#include <stddef.h>
struct r4nak_native_binary {
   uint32_t header[32];
   uint32_t sm, stage, gprs, instructions;
   uint32_t code_bytes, slm_bytes, crs_bytes, control_barriers;
   uint32_t max_warps, reserved;
   void *code;
};
/* All addresses are private to one job arena and expire on retirement. */
int r4nak_native_compile(const uint32_t *words, size_t word_count,
                         const char *entry, uint32_t stage, uint32_t sm,
                         struct r4nak_native_binary *out);
#endif
