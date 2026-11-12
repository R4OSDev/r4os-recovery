/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4GL_SW_H
#define R4GL_SW_H
#include <stdbool.h>
#include <stdint.h>
#include "util/format/u_formats.h"
struct sw_winsys;
struct pipe_box;

/* Private Mesa-to-R4OS boundary, not a public library ABI. The owner creates
 * and maps a canonical GFX buffer. Mapping and token stay valid until release;
 * presentation publishes that same buffer through the window graphics owner. */
struct r4gl_sw_storage {
   void *token;
   void *mapping;
   uint64_t bytes;
   uint32_t stride;
};
struct r4gl_sw_host {
   void *owner;
   bool (*supports)(void *, unsigned usage, enum pipe_format);
   bool (*allocate)(void *, const void *front, unsigned usage, enum pipe_format,
                    unsigned width, unsigned height, unsigned alignment,
                    struct r4gl_sw_storage *out);
   void (*release)(void *, struct r4gl_sw_storage *);
   /* A void Mesa frontbuffer flush records errors at the native surface owner;
    * the following EGL operation must report that surface/device failure. */
   void (*present)(void *, struct r4gl_sw_storage *, void *context,
                   unsigned count, const struct pipe_box *damage);
};
struct sw_winsys *r4gl_sw_create(const struct r4gl_sw_host *);
#endif
