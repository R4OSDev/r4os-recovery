#ifndef R4OS_CLI_PLATFORM2_H
#define R4OS_CLI_PLATFORM2_H
#include "cli_helpers.h"
#include "platform2.h"
/* Provider/context/path loans remain valid for every adapter call, including
 * closing an outstanding LogService handle. On failure output is unchanged. */
static inline int32_t R4SdkDiagnosticConsole2(const R4OS2Context *ctx,uint32_t stream,R4SdkDiagnosticConsole *out) {
    uint64_t fn=0;
    if(!out || (stream!=1 && stream!=2)) return -10001;
    int32_t rc=R4OS2ContextFunction(ctx,2,offsetof(R4XStartR4Desk2,console_write),&fn);
    if(rc) return rc;
    *out=(R4SdkDiagnosticConsole){.write=(R4DeskConsoleWriteFn)(uintptr_t)fn,.stream=stream};
    return 0;
}
static inline int32_t R4SdkDiagnosticFile2(const R4OS2Context *ctx,const uint8_t *path,R4SdkDiagnosticFile *out) {
    uint64_t fn=0;
    if(!out || !path) return -10001;
    int32_t rc=R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,file_append),&fn);
    if(rc) return rc;
    *out=(R4SdkDiagnosticFile){.append=(R4SysFileAppendFn)(uintptr_t)fn,.path=path};
    return 0;
}
static inline int32_t R4SdkDiagnosticLog2(const R4OS2Context *ctx,const uint8_t *origin,uintptr_t len,R4SdkBudgetValue ticks,R4SdkDiagnosticLog *out) {
    uint64_t open=0,call=0,close=0;
    if(!out) return -10001;
    int32_t rc=R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,service_open),&open);
    if(rc) return rc;
    rc=R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,service_call),&call);
    if(rc) return rc;
    rc=R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,service_close),&close);
    if(rc) return rc;
    *out=(R4SdkDiagnosticLog){.open=(R4SysServiceOpenFn)(uintptr_t)open,.call=(R4SysServiceCallFn)(uintptr_t)call,.close=(R4SysServiceCloseFn)(uintptr_t)close,.origin=origin,.origin_length=len,.call_ticks=ticks};
    return 0;
}
#endif
