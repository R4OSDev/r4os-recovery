/* Ordinary R4D provider entry and explicit lifecycle helpers. */
#ifndef R4OS_DRIVER_H
#define R4OS_DRIVER_H
#include "r4os/driver_helpers.h"
/* Exactly two five-byte relative jumps, matching the original Zig entry.
 * INIT is int32_t(const R4DriverApi *); SHUTDOWN is int32_t(void).
 * A nonzero shutdown retains/quarantines the owner; never free active DMA,
 * callback contexts or device rings in response to a timeout or Drop. */
#define R4D_ENTRIES(INIT, SHUTDOWN) \
 _Static_assert(_Generic(&(INIT), int32_t (*)(const R4DriverApi *):1, default:0), "R4D DriverInit signature"); \
 _Static_assert(_Generic(&(SHUTDOWN), int32_t (*)(void):1, default:0), "R4D DriverShutdown signature"); \
 __asm__(".pushsection .text.r4d_entries,\"ax\",@progbits\n" \
         ".global r4d_init_entry\nr4d_init_entry:\n.byte 0xe9\n.long " #INIT " - . - 4\n" \
         ".global r4d_shutdown_entry\nr4d_shutdown_entry:\n.byte 0xe9\n.long " #SHUTDOWN " - . - 4\n.popsection\n")
static inline int32_t r4driver_result(R4SdkDriverSlot slot) {
 if(slot.status < 0) return slot.status;
 if(slot.flags & R4SDKDRIVER_NATIVE_ERROR) return -1;
 return (int32_t)slot.bits;
}
/* Context remains an opaque native object. api is the exact loader table,
 * resident until real shutdown. The API constructor is not ownership transfer. */
static inline int32_t r4driver_init(const R4DriverApi *api,R4SdkDriverContext *out) {
 if(!api || !out || api->magic!=R4OS_DRIVER_MAGIC || api->version<R4OS_DRIVER_API_VERSION || api->size<sizeof(*api)) return -1;
 return r4driver_result(R4SdkDriverContext_init(0,api,out));
}
#endif
