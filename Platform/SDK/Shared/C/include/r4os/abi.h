#ifndef R4OS_ABI_H
#define R4OS_ABI_H

#include <r4os/abi_generated.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Handgeschriebene C-Fassadenkonstanten ohne ABI-Zahlenwahrheit. */
#define R4OS_OK 0
#define R4OS_ERROR_INVALID (-1)
#define R4OS_ERROR_NOT_FOUND (-2)
#define R4OS_POINTER_SIZE 8u

#define R4X_START_METADATA_R4XSTART "r4x.start=r4xstart"
#define R4X_ENTRY_METADATA_R4XSTART "r4x.entry=R4XStart"
#define R4X_CONTEXT_METADATA_R4XSTART "r4x.context=R4XStartContext"

#define R4OS_USED __attribute__((used))
#define R4OS_SECTION(name) __attribute__((section(name)))
#define R4OS_ALIGN(n) __attribute__((aligned(n)))
#define R4OS_TEXT(name, literal) \
    static const char name[] R4OS_SECTION(".text.r4cstr") R4OS_USED R4OS_ALIGN(1) = literal

#ifdef __cplusplus
}
#endif

#endif
