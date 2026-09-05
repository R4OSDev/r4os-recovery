#include <r4os/r4os.h>

R4OS_TEXT(msg_name, "SDKSMOKEC\r\n");
R4OS_TEXT(msg_context, "C R4XStart context: OK\r\n");
R4OS_TEXT(msg_args, "C R4XStart args: ");
R4OS_TEXT(msg_none, "<none>\r\n");
R4OS_TEXT(msg_import, "R4SYS/R4L import from C: OK\r\n");
R4OS_TEXT(msg_result, "SDKSMOKEC result: OK\r\n");
R4OS_TEXT(msg_crlf, "\r\n");

int32_t r4_main(const R4XStartContext *ctx, R4Sys *sys) {
    r4sys_write_cstr(sys, msg_name);
    r4sys_write_cstr(sys, msg_context);
    r4sys_write_cstr(sys, msg_args);
    const uint8_t *args = r4xstart_args(ctx);
    if (args == 0 || ctx->args_len == 0) {
        r4sys_write_cstr(sys, msg_none);
    } else {
        r4sys_write(sys, args, (uint32_t)ctx->args_len);
        r4sys_write_cstr(sys, msg_crlf);
    }
    r4sys_write_cstr(sys, msg_import);
    r4sys_write_cstr(sys, msg_result);
    return 0;
}
