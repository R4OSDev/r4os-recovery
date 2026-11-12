/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4NATIVE_LIBM_FEATURES_H
#define R4NATIVE_LIBM_FEATURES_H
/* The selected upstream data headers need only internal symbol visibility;
 * they do not use the host libc's platform/feature selection. */
#ifndef hidden
#define hidden __attribute__((visibility("hidden")))
#endif
#endif
