/* Copyright 2026 R4; SPDX-License-Identifier: Apache-2.0 */
#include "r4nak_libc.h"
#ifndef R4NAK_UNISTD_H
#define R4NAK_UNISTD_H
/* R4OS has one trusted user and no privilege transitions. Used only by
 * Mesa's debug-option eligibility check; options themselves stay disabled. */
static inline unsigned getuid(void) { return 0; }
static inline unsigned geteuid(void) { return 0; }
static inline unsigned getgid(void) { return 0; }
static inline unsigned getegid(void) { return 0; }
#endif
