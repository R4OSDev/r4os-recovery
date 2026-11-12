#ifndef R4OS_PLATFORM_FACADE2_H
#define R4OS_PLATFORM_FACADE2_H
#include "platform2.h"
#include "gui_bridge.h"
/* The caller pins storage and borrows the actual context through all users. */
int32_t R4SdkPlatformOpenNative2(uint64_t, R4SdkPlatformContext *, const R4OS2Context *);
static inline int32_t R4SdkPlatformOpen2(R4SdkPlatformContext *out, const R4OS2Context *context) {
    return R4SdkPlatformOpenNative2(R4SdkGui_ABI_FINGERPRINT, out, context);
}
#endif
