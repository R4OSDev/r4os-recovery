/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4ACO_NATIVE_H
#define R4ACO_NATIVE_H
#include "../Bindings/C/r4aco.h"
#include <stddef.h>
struct r4aco_native { R4AcoBinary metadata; uint8_t *code; };
int r4aco_native_compile(const uint32_t *,size_t,const char *,uint32_t,uint32_t,uint32_t,struct r4aco_native *);
#endif
