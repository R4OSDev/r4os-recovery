/* Copyright 2026 R4; SPDX-License-Identifier: Apache-2.0 */
/* drm_fourcc.h includes the DRM type header while declaring format numbers.
 * R4NAK uses those numbers only. No ioctl declaration or implementation is
 * provided: introducing a DRM call into the native port must fail the build. */
