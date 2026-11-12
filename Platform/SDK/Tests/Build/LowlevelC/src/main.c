#include <r4os/r4sys.h>
__attribute__((noinline)) static int stack_probe(void){volatile uint8_t b[24576];for(uint32_t i=0;i<sizeof(b);i++)b[i]=(uint8_t)(i*13+91);for(uint32_t i=0;i<sizeof(b);i++)if(b[i]!=(uint8_t)(i*13+91))return 0;return 1;}
int32_t r4_main(const R4XStartContext *ctx,R4Sys *sys){if(!ctx->instance_id || !stack_probe())return -20;if(ctx->args_len==6 && ((const char *)(uintptr_t)ctx->args)[0]=='r')return 37;r4sys_write_cstr(sys,"PASS RAW69C lowlevel original C raw-context,24KB stack and normal return\n");return 0;}
