/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4vk_state.h"
#include "util/simple_mtx.h"

struct diagnostic_state { simple_mtx_t print, failure; };
static const unsigned char diagnostic_key;
bool r4vk_diagnostics_prepare(void)
{
   return r4vk_state_ensure(&diagnostic_key, sizeof(struct diagnostic_state),
                            _Alignof(struct diagnostic_state));
}
static struct diagnostic_state *state(void)
{
   struct diagnostic_state *job = r4vk_compiler_state(2,
      sizeof(struct diagnostic_state), _Alignof(struct diagnostic_state));
   if (job) return job;
   struct diagnostic_state *result = r4vk_state_get(&diagnostic_key);
   assert(result);
   return result;
}
simple_mtx_t *r4vk_nir_print_mutex(void) { return &state()->print; }
simple_mtx_t *r4vk_nir_failure_mutex(void) { return &state()->failure; }
