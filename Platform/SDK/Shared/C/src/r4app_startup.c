#include <r4os/app_contract.h>

#ifndef R4OS_APP_PROFILE
#error "R4OS_APP_PROFILE must be supplied by the SDK build profile"
#endif

R4OS_SECTION(".text.r4xstart_entry") R4OS_USED
int32_t R4XStart(const R4XStartContext *ctx) {
    R4App app;
    R4Status status = r4_app_init(ctx, (R4AppProfile)R4OS_APP_PROFILE, &app);
    if (!r4_status_succeeded(status)) return status.raw_code;
    return r4_app_main(&app);
}
