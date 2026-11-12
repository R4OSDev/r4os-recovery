/* Existing C app-resource fixture, without executing unrelated driver groups. */
#define main sdk_resource_unused_full_fixture
#include "../Conformance/ResourceFacadePrototype05825.c"
#undef main
#include <assert.h>
#include <string.h>

static int mode;
static uint64_t sequence, local_value, io_length;
static int notification_live;
static uint8_t *destination;
static const uint8_t *source;
static R4ServiceMessageHeader *service_header;
static uint32_t last_kind, last_flags;
static const uint64_t notification_id = UINT64_C(0x1122334455667788);
void sdk_resource_mode(int value) { mode=value;vm_wrong_owner=value==3; }
uint32_t sdk_resource_last_kind(void) { return last_kind; }
uint32_t sdk_resource_slots(void) { return process_slots+thread_slots+vm_slots+io_slots+(uint32_t)notification_live; }
int sdk_resource_c_app_case(void) { return app_resource_checks(); }
static int32_t create_worker(R4ThreadEntryFn entry,uint64_t arg,uint64_t reserve,uint32_t flags,R4ProgramJoinHandle *out){
    last_flags=flags;
    if(flags & ~R4OS_THREAD_CREATE_FLAG_COMPUTE_WORKER)return R4OS_THREAD_ERROR_UNSUPPORTED;
    return fake_thread_create_handle(entry,arg,reserve,0,out);
}
static int32_t ncreate(uint64_t *out){assert(!notification_live);notification_live=1;sequence=77;*out=notification_id;return 0;}
static int32_t nquery(uint64_t id,uint64_t *out){if(!notification_live||id!=notification_id)return R4OS_NOTIFICATION_ERROR_STALE;*out=sequence;return 0;}
static int32_t nnotify(uint64_t id,uint32_t count){assert(count==1);if(!notification_live||id!=notification_id)return R4OS_NOTIFICATION_ERROR_STALE;++sequence;return 0;}
static int32_t nwait(uint64_t id,uint64_t observed,uint64_t ticks){if(!notification_live||id!=notification_id)return R4OS_NOTIFICATION_ERROR_STALE;return observed!=sequence?0:ticks==0?R4OS_NOTIFICATION_TIMEOUT:0;}
static int32_t nclose(uint64_t id){if(!notification_live||id!=notification_id)return R4OS_NOTIFICATION_ERROR_STALE;if(mode==2)return R4OS_NOTIFICATION_ERROR_RELEASE;notification_live=0;return 0;}
static int32_t local_get(uint64_t key,uint64_t *out){assert(key==UINT64_C(0x1122334455667788));*out=local_value;return 0;}
static int32_t local_publish(uint64_t key,uint64_t value,uint64_t *out){assert(key==UINT64_C(0x1122334455667788));int32_t result=local_value?R4OS_PROGRAM_LOCAL_EXISTING:0;if(!local_value)local_value=value;*out=local_value;return result;}
static int32_t io_start(uint32_t kind,const uint8_t *path,const uint8_t *data,uint8_t *out,uint64_t len,uint32_t flags,uint32_t *id){
    if(mode==5)return R4OS_IO_ERROR_NO_SLOTS;
    int32_t result=fake_io_read(path,out,len,flags,id);
    if(result==0){destination=out;source=data;io_length=len;last_kind=kind;last_flags=flags;service_header=0;}
    return result;
}
static int32_t read_io(const uint8_t *p,uint8_t *b,uint64_t n,uint32_t f,uint32_t *id){return io_start(1,p,0,b,n,f,id);}
static int32_t read_at(const uint8_t *p,uint64_t off,uint8_t *b,uint64_t n,uint32_t f,uint32_t *id){assert(off==17);return io_start(2,p,0,b,n,f,id);}
static int32_t write_io(const uint8_t *p,const uint8_t *b,uint64_t n,uint32_t f,uint32_t *id){return io_start(3,p,b,0,n,f,id);}
static int32_t append_io(const uint8_t *p,const uint8_t *b,uint64_t n,uint32_t f,uint32_t *id){return io_start(4,p,b,0,n,f,id);}
static int32_t write_at(const uint8_t *p,uint64_t off,const uint8_t *b,uint64_t n,uint32_t f,uint32_t *id){assert(off==17);return io_start(5,p,b,0,n,f,id);}
static int32_t stream_write(const uint8_t *p,uint64_t off,const uint8_t *b,uint64_t n,uint32_t f,uint32_t *id){assert(off==17);return io_start(6,p,b,0,n,f,id);}
static int32_t file_info(const uint8_t *p,uint32_t f,uint32_t *id){return io_start(7,p,0,0,0,f,id);}
static int32_t file_lock(const uint8_t *p,uint64_t off,uint64_t len,uint32_t f,uint32_t *id){assert(off==17&&len==31);return io_start(8,p,0,0,0,f,id);}
static int32_t stream_begin(const uint8_t *p,uint32_t f,uint32_t *id){return io_start(9,p,0,0,0,f,id);}
static int32_t stream_finish(const uint8_t *p,uint64_t n,uint32_t f,uint32_t *id){assert(n==31);return io_start(10,p,0,0,0,f,id);}
static int32_t stream_abort(const uint8_t *p,uint32_t *id){return io_start(11,p,0,0,0,0,id);}
static int32_t service_io(uint32_t handle,uint16_t op,const uint8_t *request,uint32_t len,R4ServiceMessageHeader *header,uint8_t *response,uint32_t capacity,uint64_t timeout,uint32_t flags,uint32_t *id){
    assert(handle==91&&op==37&&len==4&&memcmp(request,"PING",4)==0&&capacity==8&&timeout==17);
    int32_t raw=io_start(12,(const uint8_t *)"X",request,response,capacity,flags,id);if(raw==0)service_header=header;return raw;
}
static void complete_buffers(void){
    if(destination){assert(io_length>=4);memcpy(destination,"DATA",4);}
    if(source){assert(memcmp(source,last_kind==12?"PING":"DATA",4)==0);}
    if(service_header)service_header->op=37;
}
static int32_t io_status(uint32_t id,R4ProgramIoInfo *out){
    int32_t r=fake_io_status(id,out);if(r!=0)return r;
    out->version=R4OS_IO_INFO_VERSION;out->size=sizeof(*out);out->requested_bytes=io_length;
    out->processed_bytes=io_complete?4:0;
    if(mode==6&&io_complete){out->state=R4OS_IO_STATE_FAILED;out->status=-9;out->result=-7;out->processed_bytes=2;}
    return 0;
}
static int32_t io_wait(uint32_t id,uint64_t ticks,R4ProgramIoInfo *out){
    if(!io_active||id!=71)return R4OS_IO_ERROR_NOT_FOUND;
    if(!io_complete&&ticks==0)return R4OS_IO_ERROR_TIMEOUT;
    complete_buffers();io_complete=1;return io_status(id,out);
}
static int32_t io_close(uint32_t id){return mode==1&&io_active?R4OS_IO_ERROR_BUSY:fake_io_close(id);}
/* Test-only reclamation after proving a forgotten/drop-BUSY buffer remained
 * allocated. The normal Rust API never reconstructs ownership before ACK. */
int32_t sdk_resource_complete_dropped(void){R4ProgramIoInfo info;int32_t r=io_wait(71,UINT64_MAX,&info);if(r!=0)return r;mode=0;return io_close(71);}
static int32_t lifecycle_begin(R4ProgramInventoryCursor *cursor) {
    if (mode == 7) return R4OS_PROGRAM_HANDLE_ERROR_WOULD_BLOCK;
    *cursor = (R4ProgramInventoryCursor){.version=1,.size=sizeof(*cursor),.snapshot_generation=91,.program_epoch=91,
        .flags=R4OS_PROGRAM_INVENTORY_CURSOR_FLAG_INITIALIZED|R4OS_PROGRAM_INVENTORY_CURSOR_FLAG_LIFECYCLE};
    return 0;
}
static int32_t lifecycle_programs(R4ProgramInventoryCursor *cursor, R4ProgramLifecycleSnapshot *out,
    uint32_t capacity, R4ProgramInventoryPageInfo *page) {
    assert(capacity>0 && (cursor->flags & R4OS_PROGRAM_INVENTORY_CURSOR_FLAG_LIFECYCLE));
    *page=(R4ProgramInventoryPageInfo){.version=1,.size=sizeof(*page),.snapshot_generation=91,.kind=R4OS_PROGRAM_INVENTORY_KIND_LIFECYCLE};
    if(mode==4){page->status=R4OS_PROGRAM_INVENTORY_STATUS_RESTART;return 0;}
    *out=(R4ProgramLifecycleSnapshot){.version=1,.size=sizeof(*out),.handle={.instance_id=42,.generation=0x1234567887654321ULL},
        .task_id=73,.role=2,.app_class=1,.state=1,.flags=2,.exit_code=-17,.window_id=-1};
    page->returned=mode==8?capacity+1:1;page->status=R4OS_PROGRAM_INVENTORY_STATUS_COMPLETE;
    return 0;
}
static int32_t inventory_begin(R4ProgramInventoryCursor *cursor,R4ProgramInventorySummary *out){
    *cursor=(R4ProgramInventoryCursor){.version=1,.size=sizeof(*cursor),.snapshot_generation=77};
    *out=(R4ProgramInventorySummary){.version=1,.size=sizeof(*out),.snapshot_generation=77};return 0;
}
static int32_t inventory_programs(R4ProgramInventoryCursor *cursor,R4ProgramInstanceSnapshot *out,uint32_t capacity,R4ProgramInventoryPageInfo *page){
    assert(capacity>0);*page=(R4ProgramInventoryPageInfo){.version=1,.size=sizeof(*page),.snapshot_generation=77};
    if(mode==4){cursor->snapshot_generation=78;page->snapshot_generation=78;page->next_generation=78;page->status=R4OS_PROGRAM_INVENTORY_STATUS_RESTART;return 0;}
    *out=(R4ProgramInstanceSnapshot){0};page->returned=1;page->status=R4OS_PROGRAM_INVENTORY_STATUS_COMPLETE;return 0;
}
static int32_t inventory_tasks(R4ProgramInventoryCursor *c,R4ProgramTaskSnapshot *o,uint32_t n,R4ProgramInventoryPageInfo *p){(void)c;assert(n);*o=(R4ProgramTaskSnapshot){0};*p=(R4ProgramInventoryPageInfo){.returned=1};return 0;}
static int32_t inventory_threads(R4ProgramInventoryCursor *c,R4ProgramThreadSnapshot *o,uint32_t n,R4ProgramInventoryPageInfo *p){(void)c;assert(n);*o=(R4ProgramThreadSnapshot){0};*p=(R4ProgramInventoryPageInfo){.returned=1};return 0;}
void sdk_resource_table(R4XStartR4Sys *table,R4XStartR4Desk *desk){
    R4XStartR4Sys current=*table;R4XStartR4Desk current_desk=*desk;
    R4App app;init_app(&app,table,desk);
    table->magic=current.magic;table->abi_version=current.abi_version;table->size=current.size;
    desk->magic=current_desk.magic;desk->abi_version=current_desk.abi_version;desk->size=current_desk.size;
    mode=0;vm_wrong_owner=0;local_value=0;
    table->thread_create_handle=(uintptr_t)&create_worker;
    table->thread_current_handle=(uintptr_t)&current_identity_probe;
    table->thread_placement_get=(uintptr_t)&placement_get_probe;table->thread_placement_set=(uintptr_t)&placement_set_probe;
    table->cpu_capacity=(uintptr_t)&cpu_capacity_probe;
    table->notification_create=(uintptr_t)&ncreate;table->notification_query=(uintptr_t)&nquery;table->notification_notify=(uintptr_t)&nnotify;table->notification_wait=(uintptr_t)&nwait;table->notification_close=(uintptr_t)&nclose;
    table->program_local_get=(uintptr_t)&local_get;table->program_local_publish=(uintptr_t)&local_publish;
    table->io_file_read=(uintptr_t)&read_io;table->io_file_read_at=(uintptr_t)&read_at;
    table->io_file_write=(uintptr_t)&write_io;table->io_file_append=(uintptr_t)&append_io;table->io_file_write_at=(uintptr_t)&write_at;
    table->io_file_stream_write=(uintptr_t)&stream_write;table->io_file_info=(uintptr_t)&file_info;table->io_file_lock=(uintptr_t)&file_lock;
    table->io_file_stream_begin=(uintptr_t)&stream_begin;table->io_file_stream_finish=(uintptr_t)&stream_finish;table->io_file_stream_abort=(uintptr_t)&stream_abort;
    table->io_service_call=(uintptr_t)&service_io;table->io_status=(uintptr_t)&io_status;table->io_wait=(uintptr_t)&io_wait;table->io_close=(uintptr_t)&io_close;
    table->program_lifecycle_begin=(uintptr_t)&lifecycle_begin;
    table->program_lifecycle_programs=(uintptr_t)&lifecycle_programs;
    table->program_inventory_begin=(uintptr_t)&inventory_begin;table->program_inventory_programs=(uintptr_t)&inventory_programs;
    table->program_inventory_tasks=(uintptr_t)&inventory_tasks;table->program_inventory_threads=(uintptr_t)&inventory_threads;
}
int sdk_resource_prefix_case(void){
    R4App app;R4XStartR4Sys table;R4XStartR4Desk desk;init_app(&app,&table,&desk);R4Resources resources=r4_app_resources(&app);
    R4Process process={0};const uint8_t text[]="C:\\TEST.R4X";R4PathZ path={text,sizeof(text)-1};
    table.size=offsetof(R4XStartR4Sys,program_spawn_handle)+7;
    if(r4_resources_spawn(&resources,path,"",1,&process)!=R4OS_ERR_NO_FN||process.raw)return 1;
    table.size=sizeof(table);if(r4_resources_spawn(&resources,path,"",1,&process))return 2;
    uint32_t full=table.size;table.size=offsetof(R4XStartR4Sys,program_handle_status)+7;R4ProgramInstanceInfo info;
    if(r4_process_status(&process,&info)!=R4OS_ERR_NO_FN)return 3;
    table.size=full;if(r4_process_kill(&process)||r4_process_wait(&process,forever_timeout()).kind!=R4_RESOURCE_WAIT_EXITED)return 4;
    /* Independent optional functions: file read/close must work without the
     * unrelated service-call/write slots. No provider or old-OS emulation. */
    table.io_service_call=0;table.io_file_write=0;
    uint8_t bytes[8];R4IoRequest io;
    if(r4_resources_async_read(&resources,path,bytes,sizeof(bytes),0,&io))return 5;
    if(r4_io_request_wait(&io,forever_timeout()).kind!=R4_RESOURCE_WAIT_EXITED||r4_io_request_close(&io))return 6;
    table.vm_query=0;R4VmRegion vm;
    if(r4_resources_reserve_vm(&resources,4096,4096,0,&vm)||r4_vm_region_release(&vm))return 7;
    return sdk_resource_slots()==0?0:8;
}
