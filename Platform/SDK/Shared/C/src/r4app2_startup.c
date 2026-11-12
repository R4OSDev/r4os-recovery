#include <r4os/app2.h>
#ifndef R4OS2_STARTUP_INFO
#error "The SDK must generate full normal App2 startup facts from module.R4MF"
#endif
static const R4App2StartupInfo startup_info = R4OS2_STARTUP_INFO;
extern int32_t r4_app_main(R4App2 *);
__attribute__((section(".text.r4xstart_entry"), used))
int32_t R4XStart2(const R4XStartContext2 *raw) {
    R4App2 app;
    int32_t rc = r4_app2_init(raw, &startup_info, &app);
    return rc < 0 ? rc : r4_app_main(&app);
}
