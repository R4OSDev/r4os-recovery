/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include <stddef.h>

/* Native R4VK currently has a fixed option policy. Mesa environment overrides
 * are absent; callers retain their explicit upstream default. This is not a
 * host getenv adapter, and cannot enable Linux paths or experimental features. */
const char *os_get_option(const char *name) { (void)name; return NULL; }
const char *os_get_option_cached(const char *name) { return os_get_option(name); }
const char *os_get_option_secure(const char *name) { return os_get_option(name); }
char *getenv(const char *name) { return (char *)os_get_option(name); }
