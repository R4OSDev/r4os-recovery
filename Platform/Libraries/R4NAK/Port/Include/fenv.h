/* Copyright 2026 R4; SPDX-License-Identifier: Apache-2.0 */
#ifndef R4NAK_FENV_H
#define R4NAK_FENV_H
#define FE_TONEAREST 0
#define FE_DOWNWARD 0x400
#define FE_UPWARD 0x800
#define FE_TOWARDZERO 0xc00
int fegetround(void);
int fesetround(int);
#endif
