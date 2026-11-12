#include <r4gfx_helpers.h>
#include <r4aco_helpers.h>
#include <r4nak_helpers.h>
#include <r4os/heap.h>
static int ok(R4LibrariesSlot s){return !s.status && !(s.flags&R4LIBRARIES_NATIVE_ERROR);}
struct Memory {R4Heap heap;uint32_t live,failed;};
static uint8_t *allocate(void *user,uintptr_t bytes,uintptr_t alignment){
    struct Memory *s=user;uint8_t *p=r4_heap_alloc(&s->heap,bytes,alignment);if(p)++s->live;return p;
}
static void release(void *user,uint8_t *p,uintptr_t bytes,uintptr_t alignment){
    (void)bytes;(void)alignment;struct Memory *s=user;
    if(!s->live || r4_heap_free(&s->heap,p)){s->failed=1;return;}--s->live;
}
int32_t r4libraries60_color(const R4XStartContext *start,const uint8_t *icc,uintptr_t length,uint32_t *pixels){
    R4Sys sys;struct Memory memory={0};R4LibraryMemory callbacks;R4LibraryAllocator allocator;
    R4LibraryColorClient colors;R4GfxDisplayProfileOwner profile;
    if(r4sys_init(start,&sys) || r4_heap_init(&sys,&memory.heap))return 1;
    R4LibrariesSlot user={.ptr=&memory,.flags=R4LIBRARIES_PRESENT};
    if(!ok(R4LibraryMemory_from_fields(&callbacks,user,(uintptr_t)allocate,(uintptr_t)release)) || !ok(R4LibraryMemory_allocator(0,&callbacks,&allocator)))return 2;
    if(!ok(R4Library_colorClient(0,start,&colors)))return 3;
    if(!ok(R4GfxDisplayProfileOwner_open(0,&allocator,&colors,icc,length,1,R4GFX_COLOR_PROFILE_CALIBRATION,&profile)))return 4;
    int32_t result=ok(R4GfxDisplayProfileOwner_applySdr(0,&profile,pixels,4,4,1))?0:5;
    R4LibrariesSlot closed=R4GfxDisplayProfileOwner_close(0,&profile);
    if(!ok(closed) || closed.bits!=1)return 6;
    if(memory.live || memory.failed)return 7;
    return result;
}
/* Exact native objects and App remain at their final addresses through join.
 * Deliberately invalid requests exercise the real thread/ABI/cleanup path
 * without a hardware job or a second compiler qualification run. */
static R4Lib_r4os_app_contract_App application;
static R4AcoWorker aco;
static R4NakWorker nak;
int32_t r4libraries60_workers(const R4XStartContext *start){
    R4LibrariesSlot app=R4Library_application(0,&application,start,0);
    if(!ok(app) || app.bits)return 1;
    R4Lib_r4aco_R4AcoRequest ar;
    if(!ok(R4Lib_r4aco_R4AcoRequest_create(&ar,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)))return 2;
    uint32_t missing=0;
    R4AcoCompilerV1Client ac;
    int32_t available=r4aco_compiler_v1_init(start,&ac);
    R4LibrariesSlot value=R4AcoWorker_init(0,&application,&aco);
    if(available){
        if(value.status || !(value.flags&R4LIBRARIES_NATIVE_ERROR))return 3;
        missing|=1;
    }else{
        if(!ok(value))return 3;
        value=R4AcoWorker_start(0,&aco,&ar);
        if(!ok(value) || value.bits)return 4;
        value=R4AcoWorker_join(0,&aco,1000);
        if(!ok(value) || !(value.flags&R4LIBRARIES_PRESENT) || (int32_t)value.bits!=R4ACO_STATUS_INVALID)return 5;
        if(R4AcoWorker_get_live_bytes(&aco).bits)return 6;
    }
    R4Lib_r4nak_R4NakRequest nr;
    if(!ok(R4Lib_r4nak_R4NakRequest_create(&nr,0,0,0,0,0,0,0,0,0,0,0,0,0,0)))return 7;
    R4NakCompilerV1Client nc;
    available=r4nak_compiler_v1_init(start,&nc);
    value=R4NakWorker_init(0,&application,&nak);
    if(available){
        if(value.status || !(value.flags&R4LIBRARIES_NATIVE_ERROR))return 8;
        missing|=2;
    }else{
        if(!ok(value))return 8;
        value=R4NakWorker_start(0,&nak,&nr);
        if(!ok(value) || value.bits)return 9;
        value=R4NakWorker_join(0,&nak,1000);
        if(!ok(value) || !(value.flags&R4LIBRARIES_PRESENT) || (int32_t)value.bits!=R4NAK_STATUS_INVALID)return 10;
        if(R4NakWorker_get_live_bytes(&nak).bits)return 11;
    }
    return -(int32_t)missing;
}
