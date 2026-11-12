/* Reusable C caller for both genuine provider languages; private caller heaps. */
#include <r4os/r4os.h>
#include "../Build/CR4L/Bindings/C/l66c.h"
typedef struct Caller66 {
 R4Heap heap;R4L66State *state;R4L66ApiV1CloseFn close;
 uint64_t generation,notify_count,release_count,attempts;
 int fail_allocate,fail_release;
} Caller66;
static uint64_t allocate66(uint64_t owner,uint64_t bytes){Caller66 *c=(Caller66*)(uintptr_t)owner;if(bytes!=16||c->fail_allocate)return 0;return (uint64_t)(uintptr_t)r4_heap_alloc(&c->heap,bytes,8);}
static int32_t release66(uint64_t owner,uint64_t address){Caller66 *c=(Caller66*)(uintptr_t)owner;c->attempts++;if(c->fail_release){c->fail_release=0;return -44;}int rc=r4_heap_free(&c->heap,(void*)(uintptr_t)address);if(!rc)c->release_count++;return rc;}
static int32_t notify66(uint64_t owner,uint64_t generation,uint64_t value){Caller66 *c=(Caller66*)(uintptr_t)owner;if(generation!=c->generation||!value||c->close(c->state,generation)!=-2)return -77;c->notify_count++;return 0;}
#define REQUIRE66(x) do{if(!(x))return __LINE__;}while(0)
int sdk66_consume(const R4XStartContext *start,const char *module,uint64_t tag){
 const R4LQuery *query=0;REQUIRE66(r4l_query_metadata(start,module,&query)==0&&query&&query->kernel_bridge==0);
 R4LInterfaceExpectation expected={0x4c363631,0x53444b36,1,1,56,0,0};const R4LInterfaceHeader *header=0;
 REQUIRE66(r4l_validate_import(r4xstart_find_import_named(start,module,"API_V1"),&expected,&header)==0);
 const R4L66ApiV1 *api=(const R4L66ApiV1*)header;REQUIRE66(api->open&&api->work&&api->close);
 R4Sys sys;REQUIRE66(r4sys_init(start,&sys)==0);R4Heap heap;REQUIRE66(r4_heap_init(&sys,&heap)==0);
 R4HeapStats before,after;REQUIRE66(r4_heap_stats(&heap,&before)==0);
 R4L66State a={0},b={0};Caller66 ca={.heap=heap,.state=&a,.close=api->close,.generation=11,.fail_allocate=1},cb={.heap=heap,.state=&b,.close=api->close,.generation=22};
 REQUIRE66(api->open(&a,(uint64_t)(uintptr_t)&ca,11,(uint64_t)(uintptr_t)allocate66,(uint64_t)(uintptr_t)release66,(uint64_t)(uintptr_t)notify66)==-4&&!a.active&&!a.in_callback);
 ca.fail_allocate=0;
 REQUIRE66(api->open(&a,(uint64_t)(uintptr_t)&ca,11,(uint64_t)(uintptr_t)allocate66,(uint64_t)(uintptr_t)release66,(uint64_t)(uintptr_t)notify66)==0);
 REQUIRE66(api->open(&b,(uint64_t)(uintptr_t)&cb,22,(uint64_t)(uintptr_t)allocate66,(uint64_t)(uintptr_t)release66,(uint64_t)(uintptr_t)notify66)==0);
 REQUIRE66(a.allocation&&b.allocation&&a.allocation!=b.allocation);
 uint64_t value=999,sum=0;REQUIRE66(api->work(&a,99,100,&value)==-3&&value==999&&ca.notify_count==0);
 REQUIRE66(api->work(&a,11,100,&value)==0&&value==101+tag);sum+=value;
 REQUIRE66(api->work(&b,22,200,&value)==0&&value==201+tag);sum+=value;
 uint64_t held=a.allocation;ca.fail_release=1;
 REQUIRE66(api->close(&a,99)==-3&&a.allocation==held&&ca.attempts==0);
 REQUIRE66(api->close(&a,11)==-44&&a.active&&a.allocation==held&&ca.release_count==0);
 REQUIRE66(api->close(&a,11)==0&&!a.active&&!a.allocation&&ca.release_count==1);
 REQUIRE66(api->work(&b,22,300,&value)==0&&value==302+tag);sum+=value;
 REQUIRE66(api->close(&a,11)==-1&&api->close(&b,22)==0&&!b.active);
 REQUIRE66(ca.notify_count==1&&cb.notify_count==2&&ca.attempts==2&&cb.attempts==1&&cb.release_count==1&&sum==604+3*tag);
 REQUIRE66(r4_heap_stats(&heap,&after)==0);uint64_t x,y;
 REQUIRE66(r4_heap_stat(&before,"active_allocations",&x)&&r4_heap_stat(&after,"active_allocations",&y)&&x==y);
 REQUIRE66(r4_heap_stat(&before,"active_bytes",&x)&&r4_heap_stat(&after,"active_bytes",&y)&&x==y);
 R4Console console={.system=&sys};r4_console_line(&console,tag==0x43?"PASS R4L66 L66C work=805 sessions=2 callbacks=3 failed-release-held=1 heap=exact":"PASS R4L66 L66R work=850 sessions=2 callbacks=3 failed-release-held=1 heap=exact");return 0;
}
