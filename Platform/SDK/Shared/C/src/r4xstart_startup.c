#include <r4os/r4sys.h>

R4OS_SECTION(".text.r4xstart_entry") R4OS_USED
int32_t R4XStart(const R4XStartContext *ctx) {
    if (!r4xstart_context_valid(ctx)) return 51;

    R4Sys sys;
    int32_t init_status = r4sys_init(ctx, &sys);
    if (init_status != R4OS_OK) return 52;

    return r4_main(ctx, &sys);
}
