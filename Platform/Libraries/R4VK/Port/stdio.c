/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_state.h"
#define r4native_console_write r4vk_console_write
#include "../../Shared/Native/stdio.c"

_Noreturn void r4nak_port_assert(const char *condition, const char *file, int line)
{
   fprintf(stderr, "R4VK assertion: %s (%s:%d)\n", condition, file, line);
   r4vk_compiler_fail(3);
}
_Noreturn void abort(void) { r4vk_compiler_fail(3); }
