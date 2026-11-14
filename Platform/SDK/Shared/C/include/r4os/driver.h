/* Ordinary R4D provider entry and explicit lifecycle helpers. */
#ifndef R4OS_DRIVER_H
#define R4OS_DRIVER_H
#include "r4os/driver_helpers.h"
#include "r4os/technical2.h"
/* Exactly two five-byte relative jumps, matching the original Zig entry.
 * INIT is int32_t(const R4DriverApi2 *); SHUTDOWN is int32_t(void).
 * A nonzero shutdown retains/quarantines the owner; never free active DMA,
 * callback contexts or device rings in response to a timeout or Drop. */
#define R4D_ENTRIES(INIT, SHUTDOWN) R4OS_DRIVER_ENTRY2(INIT, SHUTDOWN)
static inline int32_t r4driver_result(R4SdkDriverSlot slot) {
 if(slot.status < 0) return slot.status;
 if(slot.flags & R4SDKDRIVER_NATIVE_ERROR) return -1;
 return (int32_t)slot.bits;
}
/* Context remains an opaque native object. api is the exact loader table,
 * resident until real shutdown. The API constructor is not ownership transfer. */
static inline int32_t r4driver_init(const R4DriverApi2 *api,R4SdkDriver2Context *out) {
 R4OS2Driver view;
 if (!out || R4OS2DriverInit(api, &view) != 0) return -1;
 return r4driver_result(R4SdkDriver2Context_init(0,api,out));
}
#endif
