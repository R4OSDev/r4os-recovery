#include <r4os/app_contract.h>

/* The selected startup owns the entry signature. Common facade headers are
 * also used by App2 and must not declare an incompatible App1 entry. */
extern int32_t r4_app_main(R4App *);

#ifndef R4OS_APP_PROFILE
#error "R4OS_APP_PROFILE must be supplied by the SDK build profile"
#endif
#ifndef R4OS_STARTUP_INFO
#error "R4OS_STARTUP_INFO must be generated from module.R4MF by the SDK"
#endif
static const R4StartupInfo startup_info = R4OS_STARTUP_INFO;

R4OS_SECTION(".text.r4xstart_entry") R4OS_USED
int32_t R4XStart(const R4XStartContext *ctx) {
    R4App app;
    R4Status status = r4_app_init_declared(ctx, &startup_info, &app);
    if (!r4_status_succeeded(status)) return status.raw_code;
    int32_t entropy_status = R4SdkBindProgramEntropy(ctx);
    if (entropy_status < 0) return entropy_status;
    return r4_app_main(&app);
}
