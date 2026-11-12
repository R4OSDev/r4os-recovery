#include <r4os/platform2.h>
#ifndef R4OS2_STARTUP_INFO
#error "R4XStart2 requires SDK-selected manifest startup information"
#endif
int32_t r4_main2(const R4OS2Context *context);
__attribute__((section(".text.r4xstart_entry"),used))
int32_t R4XStart2(const R4XStartContext2 *raw) {
    const R4OS2StartupInfo expected = R4OS2_STARTUP_INFO;
    return R4OS2Start(raw, &expected, r4_main2);
}
