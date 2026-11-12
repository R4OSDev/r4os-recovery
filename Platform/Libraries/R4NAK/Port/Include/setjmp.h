/* Copyright 2026 R4; SPDX-License-Identifier: Apache-2.0 */
#ifndef R4NAK_SETJMP_H
#define R4NAK_SETJMP_H
/* VTN catches its own C parser failures before entering Rust. These jumps
 * never cross a Rust stack frame or the public library boundary. */
typedef void *jmp_buf[5];
#define setjmp(env) __builtin_setjmp(env)
#define longjmp(env, value) __builtin_longjmp(env, 1)
#endif
