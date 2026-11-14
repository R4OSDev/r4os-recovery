#ifndef R4OS_DRIVER2_H
#define R4OS_DRIVER2_H
#include "r4os/driver.h"
#include "r4os/technical2.h"
static inline int32_t r4driver2_init(const R4DriverApi2 *api, R4SdkDriver2Context *out) {
    R4OS2Driver view;
    if (!out || R4OS2DriverInit(api, &view) != 0) return -1;
    return r4driver_result(R4SdkDriver2Context_init(0, api, out));
}
#endif
