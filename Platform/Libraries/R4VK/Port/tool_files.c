/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4nak_libc.h"
#include <errno.h>
#include "r4vk_state.h"

/* The Vulkan runtime accepts immutable SYS/DRAW/DEV tables, not an application's
 * native file/stream context. Linux /proc, /sys, DRIRC and trace captures are
 * unavailable; all associated RADV capabilities are disabled. Keep the failure
 * explicit for unreachable upstream tooling as well. Memory streams and console
 * diagnostics use the existing Shared/Native implementation. */
FILE *fopen(const char *name, const char *mode)
{
   (void)name; (void)mode; errno = ENOSYS; return NULL;
}
size_t fread(void *data, size_t bytes, size_t count, FILE *file)
{
   (void)data; (void)bytes; (void)count; (void)file; errno = ENOSYS; return 0;
}
char *os_read_file(const char *name, size_t *size)
{
   (void)name; if (size) *size = 0; errno = ENOSYS; return NULL;
}
_Noreturn void exit(int code) { (void)code; r4vk_compiler_fail(3); }
