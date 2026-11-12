#ifndef R4OS_INVENTORY_PLATFORM2_H
#define R4OS_INVENTORY_PLATFORM2_H
#include "inventory_reader.h"
#include "stream_platform2.h"
/* Resolve only the selected existing pair. No synthetic legacy table and no
 * expensive Full fallback for Lifecycle. Output stays untouched on failure. */
static inline int32_t R4SdkInventoryProvider2(const R4OS2Context *ctx,uint32_t mode,R4SdkInventoryProvider *out){
    if(!out)return -1;if(mode>1)return -4;uint64_t begin=0,page=0;int32_t rc;
    if(mode==R4_INV_READER_FULL){
        rc=R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,program_inventory_begin),&begin);if(rc)return rc;
        rc=R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,program_inventory_programs),&page);if(rc)return rc;
        *out=(R4SdkInventoryProvider){.full_begin=(R4SysProgramInventoryBeginFn)(uintptr_t)begin,.full_page=(R4SysProgramInventoryProgramsFn)(uintptr_t)page};
    }else{
        rc=R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,program_lifecycle_begin),&begin);if(rc)return rc;
        rc=R4OS2ContextFunction(ctx,1,offsetof(R4XStartR4Sys2,program_lifecycle_programs),&page);if(rc)return rc;
        *out=(R4SdkInventoryProvider){.lifecycle_begin=(R4SysProgramLifecycleBeginFn)(uintptr_t)begin,.lifecycle_page=(R4SysProgramLifecycleProgramsFn)(uintptr_t)page};
    }return 0;
}
#endif
