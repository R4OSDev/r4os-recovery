#include <r4os/app2.h>
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static uint32_t owner = 42, generation = 7, close_requested, yields, writes;
static const R4XStartContext2 *expected_raw;
static void *region;
static uint64_t region_length;
static uint32_t close_callback(const R4XStartContext2 *raw) {
    assert(raw == expected_raw && raw->magic == R4OS2_START_MAGIC && raw->size == 120);
    return close_requested;
}
static void yield_callback(const R4XStartContext2 *raw) {
    assert(raw == expected_raw && raw->size == 120);
    ++yields;
}
static int32_t write_callback(const uint8_t *data, uint32_t length) {
    assert(length == 6 && !memcmp(data, "app2-c", 6)); ++writes; return 3;
}
static int32_t current(R4ProgramJoinHandle *out) {
    *out = (R4ProgramJoinHandle){.thread_id=1,.instance_id=owner,.thread_generation=9,.instance_generation=generation};
    return 0;
}
static int32_t reserve(uint64_t length, uint64_t alignment, uint64_t flags, R4ProgramVmRegionInfo *out) {
    (void)flags;
    if (region || !length || length % alignment) return -1;
    region=aligned_alloc((size_t)alignment,(size_t)length); if(!region) return -1;
    region_length=length; memset(region,0,(size_t)length);
    *out=(R4ProgramVmRegionInfo){.id=1,.base=(uintptr_t)region,.len=length}; return 0;
}
static int32_t commit(uint32_t id,uint64_t offset,uint64_t length,uint64_t flags) {
    (void)flags; return region && id==1 && offset<=region_length && length<=region_length-offset ? 0 : -1;
}
static int32_t decommit(uint32_t id,uint64_t offset,uint64_t length) { return commit(id,offset,length,0); }
static int32_t release(uint32_t id) {
    if(!region || id!=1) return -1; free(region); region=NULL; region_length=0; return 0;
}
extern const R4App2Memory *R4SdkHeapMemory2(const R4App2Memory *, uint64_t);
int main(void) {
    R4XStartR4Sys2 sys={.magic=R4OS2_R4SYS_MAGIC,.abi_version=R4OS2_R4SYS_VERSION,.size=sizeof(sys),
        .write=(uintptr_t)&write_callback,.thread_current_handle=(uintptr_t)&current,
        .vm_reserve=(uintptr_t)&reserve,.vm_commit=(uintptr_t)&commit,.vm_decommit=(uintptr_t)&decommit,.vm_release=(uintptr_t)&release};
    uint64_t independent=0;
    R4XStartImport imports[]={
        {.group_id=1,.min_version=2,.resolved_version=2,.flags=R4XSTART_IMPORT_FLAG_GROUP_INTERFACE,.module_name=(uintptr_t)"R4SYS",.symbol_name=(uintptr_t)"Query2",.table=(uintptr_t)&sys},
        {.min_version=1,.resolved_version=1,.module_name=(uintptr_t)"LIBRARY",.symbol_name=(uintptr_t)"TEXT_V1",.table=(uintptr_t)&independent},
        {.min_version=1,.module_name=(uintptr_t)"ABSENT",.symbol_name=(uintptr_t)"TEXT_V1"}};
    R4App2Import specs[]={{"R4SYS","Query2",2,0,1,0},{"LIBRARY","TEXT_V1",1,0,0,0},{"ABSENT","TEXT_V1",1,1,0,0}};
    R4App2StartupInfo facts={0,1,2,3,specs};
    const uint8_t args[]={1,2,3,0xa5};
    R4XStartContext2 raw={.magic=R4OS2_START_MAGIC,.abi_major=2,.size=120,.flags=R4XSTART_FLAG_IMPORTS_VALID|R4XSTART_FLAG_CLOSE_SUPPORTED|R4XSTART_FLAG_YIELD_SUPPORTED,
        .instance_id=42,.app_class=1,.imports=(uintptr_t)imports,.import_count=3,.args=(uintptr_t)args,.args_len=3,
        .should_close=(uintptr_t)&close_callback,.yield=(uintptr_t)&yield_callback};
    expected_raw=&raw;
    R4App2 app; assert(r4_app2_init(&raw,&facts,&app)==0);
    assert(app.context.raw==&raw && app.context.tables[0]==(uintptr_t)&sys);
    uint64_t length=0; assert(r4_app2_args(&app,&length)==args && length==3);
    assert(!r4_app2_should_close(&app)); close_requested=1; assert(r4_app2_should_close(&app));
    assert(r4_app2_yield(&app)==1 && yields==1);
    assert(r4_app2_write(&app,(const uint8_t *)"app2-c",6)==3 && writes==1);
    raw.app_class=2;
    assert(r4_app2_init(&raw,&facts,&app)==0 && app.context.raw==&raw);
    raw.app_class=1;
    R4App2Memory sentinel; memset(&sentinel,0xa5,sizeof(sentinel)); R4App2Memory output=sentinel;
    /* A raw entry explicitly opts into the same SDK helper owner. It does not
     * install/allocate a global heap and preserves output on failed admission. */
    assert(!region && R4SdkApp2InitRaw(&raw,&output)==0 && !region);
    assert(!memcmp(&output,&app.memory,sizeof(output))); output=sentinel;
    raw.app_class=0; assert(R4SdkApp2InitRaw(&raw,&output)==-12 && !memcmp(&output,&sentinel,sizeof(output))); raw.app_class=1;
    raw.size=119; assert(R4SdkApp2InitRaw(&raw,&output)==-12 && !memcmp(&output,&sentinel,sizeof(output))); raw.size=120;
    raw.flags=0; assert(R4SdkApp2InitRaw(&raw,&output)==-12 && !memcmp(&output,&sentinel,sizeof(output))); raw.flags=7;
    raw.size=119; assert(R4SdkApp2Init(&raw,&facts,&output)==-12 && !memcmp(&output,&sentinel,sizeof(output))); raw.size=120;
    raw.flags=0; assert(R4SdkApp2Init(&raw,&facts,&output)==-12); raw.flags=7;
    raw.app_class=3; assert(R4SdkApp2Init(&raw,&facts,&output)==-12); raw.app_class=1;
    raw.import_count=2; assert(R4SdkApp2Init(&raw,&facts,&output)==-13); raw.import_count=3;
    imports[1].symbol_name=(uintptr_t)"OTHER"; assert(R4SdkApp2Init(&raw,&facts,&output)==-14); imports[1].symbol_name=(uintptr_t)"TEXT_V1";
    imports[2].resolved_version=1; assert(R4SdkApp2Init(&raw,&facts,&output)==-14); imports[2].resolved_version=0;
    imports[0].resolved_version=1; assert(R4SdkApp2Init(&raw,&facts,&output)==-12); imports[0].resolved_version=2;
    uint32_t magic=sys.magic; sys.magic=0; assert(R4SdkApp2Init(&raw,&facts,&output)==-12); sys.magic=magic;
    assert(!memcmp(&output,&sentinel,sizeof(output)));
    assert(r4_app2_heap_bind(&app)==0);
    const R4App2Memory *resident=R4SdkHeapMemory2(&app.memory,42);
    assert(resident && resident!=&app.memory && !memcmp(resident,&app.memory,sizeof(*resident)));
    R4App2Memory changed=app.memory; changed.vm_release=1; assert(R4SdkHeapBind2(&changed,42)==-2);
    uint8_t *p=r4_app2_alloc(&app,17,64); assert(p && (uintptr_t)p%64==0); memset(p,0x5a,17);
    owner=43; assert(r4_app2_free(&app,p)==-2); owner=42;
    generation=8; assert(r4_app2_free(&app,p)==-2); generation=7;
    assert(p[0]==0x5a && p[16]==0x5a); assert(r4_app2_free(&app,p)==0);
    assert(R4SdkHeapFinish2(&app.memory,42)==0 && !region);
    assert(R4SdkHeapFinish2(resident,42)==0);
    puts("PASS normal C App2 ordered imports/independent revision1/optional absent/exact callbacks/unchanged failures/shared heap copied identity/owner-generation/free/release ACK");
    return 0;
}
