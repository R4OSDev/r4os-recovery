/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4GL_API_H
#define R4GL_API_H
/* Native R4OS handles: default display NULL, window IDs encoded as void *.
 * Resolve commands through R4GlLoader; do not link a host EGL/GL loader. */
#define EGL_NO_PLATFORM_SPECIFIC_TYPES
#include "r4gl.h"
#include "EGL/egl.h"
#include "EGL/eglext.h"
#include "GL/glcorearb.h"
#endif
