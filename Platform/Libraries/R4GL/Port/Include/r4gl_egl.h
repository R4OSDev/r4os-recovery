/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4GL_EGL_H
#define R4GL_EGL_H
#include "r4gl_sw.h"
#include <EGL/egl.h>

/* Private frontend boundary. Native handles are resolved by the process owner,
 * never interpreted as caller-owned structs by Mesa. All successful acquisitions
 * own a lease until their matching release, including after eglTerminate. */
struct r4gl_egl_geometry {
   uint32_t width, height;
   uint64_t revision;
};
struct kopper_loader_info;
struct r4gl_egl_host {
   struct r4gl_sw_host sw;
   void (*close)(void *owner);
   EGLint (*acquire_window)(void *owner, void *native_window, void **lease);
   void (*release_window)(void *owner, void *lease);
   EGLint (*window_state)(void *owner, void *lease, struct r4gl_egl_geometry *);
   EGLint (*present_status)(void *owner, void *lease);
   EGLint max_swap_interval;
   EGLint (*swap_interval)(void *owner, void *lease, EGLint interval);
   EGLint (*window_loader)(void *owner, void *lease, struct kopper_loader_info *);
};
/* The selected profile owns its native window metadata. Zink separately admits
 * the actual R4VK surface/format capabilities. Failure leaves out unowned. */
EGLint r4gl_egl_open_host(void *native_display, struct r4gl_egl_host *out);

/* sw.allocate(front) and sw.present(context) receive the acquired window lease.
 * Presentation must finish consuming the source before returning: CPU mappings
 * stay accessible to Mesa and are reused on the next frame. The native owner
 * must copy or wait through its canonical GFX buffer/fence path, never publish
 * an asynchronous reader of an unprotected CPU mapping. present_status reports
 * the actual present result. Revision/dimension mismatch must reject a frame.
 * Callbacks may not reenter EGL. Interval one requires synchronized native
 * output; the boot framebuffer exposes interval zero. A policy change takes
 * effect on the next posting and must not discard older FIFO frames. */
#endif
