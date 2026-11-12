// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
#include <stdlib.h>

// OpenH264 checks ordinary new for null; compile this closed C++ profile with
// -fcheck-new and no exceptions. All storage remains charged to the current
// R4ENC owner through its malloc/free adapter. No STL or host C++ ABI is used.
void *operator new(size_t bytes) { return malloc(bytes ? bytes : 1); }
void *operator new[](size_t bytes) { return malloc(bytes ? bytes : 1); }
void operator delete(void *p) noexcept { free(p); }
void operator delete[](void *p) noexcept { free(p); }
void operator delete(void *p, size_t) noexcept { free(p); }
void operator delete[](void *p, size_t) noexcept { free(p); }
extern "C" void __cxa_pure_virtual() { abort(); }
