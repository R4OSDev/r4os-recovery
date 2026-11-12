/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VK_STATE_H
#define R4VK_STATE_H
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
void r4vk_native_failure(const char *stage, int32_t result, int64_t detail,
                         uint64_t identity, uint64_t point);
bool r4vk_state_ensure(const void *key, size_t bytes, size_t alignment);
void *r4vk_state_get(const void *key);
bool r4vk_cpu_state_prepare(void);
bool r4vk_glsl_state_prepare(void);
bool r4vk_printf_state_prepare(void);
bool r4vk_diagnostics_prepare(void);
bool r4vk_glsl_init_or_ref(void);
bool r4vk_printf_init_or_ref(void);
_Noreturn void r4vk_compiler_fail(unsigned reason);
void *r4vk_compiler_state(unsigned slot, size_t bytes, size_t alignment);
bool r4vk_compiler_isolated(void);
struct r4vk_compiler_job;
int r4vk_compiler_job_run(int (*callback)(void *), void *argument,
                         struct r4vk_compiler_job **owner);
void r4vk_compiler_job_destroy(struct r4vk_compiler_job *owner);
#endif
