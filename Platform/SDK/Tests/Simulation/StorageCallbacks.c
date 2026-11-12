/* Reuse the existing C/Zig conformance fixtures' bytes and callbacks. Only
 * controlled provider failures and append-only snapshot/save slots are new. */
#define main sdk_storage_c_fixture
#include "../Conformance/StorageFacadePrototype05823.c"
#undef main
#include <r4os/app2.h>

static int mode;
static uint8_t console_bytes[64];static uint32_t console_len;
void sdk_storage_mode(int next) { mode=next;if(next>=40)console_len=0; }
uint32_t sdk_storage_console(uint8_t *out,uint32_t capacity){assert(capacity>=console_len);memcpy(out,console_bytes,console_len);return console_len;}
static int32_t console_write(const uint8_t *bytes,uint32_t length){
    if(mode<40)return fake_write(bytes,length);if(mode==41)return -7;
    uint32_t n=length>2u?2u:length;assert(console_len+n<=sizeof(console_bytes));memcpy(console_bytes+console_len,bytes,n);console_len+=n;return (int32_t)n;
}
static void console_put(uint8_t byte){if(mode<40)fake_putc(byte);else{assert(console_len<sizeof(console_bytes));console_bytes[console_len++]=byte;}}
static uint64_t ticks(void){return 17;}
static int32_t collated(const uint8_t *a,const uint8_t *b){return r4_path_equal_ignore_case(a,strlen((const char *)a),b,strlen((const char *)b));}
static int32_t info(const uint8_t *path,R4FileInfo *out){
    if(strstr((const char *)path,".BAK"))return 0;
    return fake_file_info(path,out);
}
static int32_t begin(const uint8_t *path,uint32_t flags){
    if(mode==55)return R4OS_FILE_STREAM_ERROR_NAME_NOT_SUPPORTED;
    if(mode==56)return R4OS_FILE_STREAM_ERROR_NAME_TOO_LONG;
    int32_t r=fake_stream_begin(path,flags);return mode==20?-7:r;
}
static int32_t chunk(const uint8_t *path,uint64_t offset,const uint8_t *bytes,uint32_t length,uint32_t flags){
    int32_t r=fake_stream_write(path,offset,bytes,length,flags);return mode==21&&r>0?r-1:r;
}
static int32_t finish(const uint8_t *path,uint64_t expected,uint32_t flags){return mode==22?-7:fake_stream_finish(path,expected,flags);}
static int32_t abort_stream(const uint8_t *path){return mode==23?-7:fake_stream_abort(path);}
static int32_t replace(const uint8_t *target,const uint8_t *stage,const uint8_t *backup,uint32_t flags){
    assert(target&&stage&&backup&&strstr((const char *)stage,"DS")&&strstr((const char *)backup,".BAK")&&flags==R4SYS_FILE_REPLACE_ATOMIC_CONSUME_STAGE);
    return mode==1?-7:0;
}
static int32_t remove_file(const uint8_t *path){return mode==2&&strstr((const char *)path,".BAK")?-7:fake_file_delete(path);}
static int32_t snapshot_begin(const uint8_t *key,uint32_t kind,R4RegistrySnapshotCursor *out){
    (void)key;*out=(R4RegistrySnapshotCursor){.version=1,.size=sizeof(*out),.generation=77,.kind=kind,.total=1};return 0;
}
static int32_t snapshot_page(R4RegistrySnapshotCursor *cursor,R4RegistrySnapshotEntry *entries,uint32_t capacity,uint8_t *data,uint32_t data_capacity,R4RegistrySnapshotPageInfo *page){
    assert(cursor->generation==77);
    if(mode==30){cursor->generation=78;cursor->next_index=0;++cursor->restarts;*page=(R4RegistrySnapshotPageInfo){.version=1,.size=sizeof(*page),.generation=78,.status=R4OS_REGISTRY_SNAPSHOT_STATUS_RESTART};return 0;}
    *page=(R4RegistrySnapshotPageInfo){.version=1,.size=sizeof(*page),.generation=77,.total=1,.kind=cursor->kind};
    if(cursor->next_index==0){
        if(!capacity||data_capacity<4u)return R4OS_REGISTRY_API_RESULT_BUFFER_TOO_SMALL;
        entries[0]=(R4RegistrySnapshotEntry){.kind=2,.value_type=R4OS_REGISTRY_VALUE_TYPE_U32,.data_len=4};memcpy(entries[0].name,"COUNT",6);
        memcpy(data,"\x78\x56\x34\x12",4);page->returned=1;page->data_bytes=4;cursor->next_index=1;
    }
    page->next_index=cursor->next_index;page->status=R4OS_REGISTRY_SNAPSHOT_STATUS_COMPLETE;return 0;
}
static int32_t batch(const R4RegistryBatchOperation *ops,uint32_t count,const uint8_t *blob,uint32_t length,R4RegistryBatchResult *out){
    assert(count==1&&ops[0].data_len==4&&ops[0].data_offset+4<=length&&blob[ops[0].data_offset]==99);
    *out=(R4RegistryBatchResult){.version=1,.size=sizeof(*out),.generation_before=77,.generation_after=78,.operation_count=count,.status=R4OS_REGISTRY_BATCH_STATUS_COMMITTED};return 0;
}
static int32_t name_limits(const uint8_t *path,R4FileNameLimits *out){
    assert(path&&out);
    if(mode==51)return R4OS_FILE_STREAM_ERROR_UNSUPPORTED;
    if(mode==52)return R4OS_FILE_STREAM_ERROR_NAME_NOT_SUPPORTED;
    if(mode==53)return R4OS_FILE_STREAM_ERROR_NAME_TOO_LONG;
    if(mode==54){*out=(R4FileNameLimits){0};return 0;}
    *out=(R4FileNameLimits){.size=sizeof(*out),.flags=3,.provider=2,.drive_letter='C',
        .mount_slot=7,.mount_generation=99,.max_path_bytes=1023,.max_component_bytes=765,
        .max_component_utf16_units=255,.short_base_bytes=8,.short_extension_bytes=3,
        .name_rules=7,.atomic_rules=7};
    return 0;
}
void sdk_storage_table(R4XStartR4Sys *out){
    R4XStartR4Sys current=*out;
    *out=make_table(1);out->magic=current.magic;out->abi_version=current.abi_version;out->size=current.size;
    out->write=(uintptr_t)&console_write;out->putc=(uintptr_t)&console_put;
    out->file_name_limits=(uintptr_t)&name_limits;
    out->ticks=(uintptr_t)&ticks;out->file_info=(uintptr_t)&info;out->path_names_equal_collated=(uintptr_t)&collated;
    out->file_stream_begin=(uintptr_t)&begin;out->file_stream_write=(uintptr_t)&chunk;out->file_stream_finish=(uintptr_t)&finish;out->file_stream_abort=(uintptr_t)&abort_stream;
    out->file_replace_atomic=(uintptr_t)&replace;out->file_delete=(uintptr_t)&remove_file;
    out->registry_snapshot_begin=(uintptr_t)&snapshot_begin;out->registry_snapshot_page=(uintptr_t)&snapshot_page;out->registry_batch_mutate=(uintptr_t)&batch;
    out->storage_claim_begin=(uintptr_t)&fake_storage_begin;out->storage_claim_end=(uintptr_t)&fake_storage_end;
    mode=0;resume_stale=0;storage_close_result=R4OS_STORAGE_ERROR_BUSY;
}
void sdk_storage_close_mode(int32_t result){storage_close_result=result;}

void sdk_storage_directory_stale(int value){resume_stale=value;}

static uint32_t metadata_mode;
void sdk_storage2_mode(uint32_t value) { metadata_mode=value; }
static R4FileMetadata2 metadata_value(void) {
    return (R4FileMetadata2){.version=1,.size=sizeof(R4FileMetadata2),
        .flags=R4OS_FILE_METADATA2_FLAG_EXISTS|R4OS_FILE_METADATA2_FLAG_BYTE_SIZE_VALID|R4OS_FILE_METADATA2_FLAG_BACKEND_NODE_VALID,
        .byte_size=UINT64_C(0x100000003),.backend_node=UINT64_C(0x100000007),.drive_letter='C'};
}
static int32_t metadata_read(const uint8_t *path,R4FileMetadata2 *out) {
    assert(path&&out);
    if(metadata_mode==1)return 0;
    if(metadata_mode==2)return R4OS_FILE_METADATA2_ERROR_RESTART;
    *out=metadata_value();return 1;
}
static int32_t metadata_batch(const uint8_t *path,R4DirectoryMetadataCursor2 *cursor,R4DirectoryMetadataEntry2 *rows,uint32_t capacity) {
    assert(cursor&&cursor->version==1&&cursor->size==sizeof(*cursor));
    if(!capacity){assert(!path&&!rows);return metadata_mode==2?R4OS_FILE_METADATA2_ERROR_RESTART:0;}
    assert(path&&rows&&capacity==4);
    if(cursor->namespace_generation)return -5;
    cursor->namespace_generation=7;
    rows[0]=(R4DirectoryMetadataEntry2){.info=metadata_value()};
    memcpy(rows[0].path,"C:\\WIDE.TXT",12);
    rows[1]=rows[0];memcpy(rows[1].path,"C:\\NEXT.TXT",12);
    return 2;
}
static int32_t metadata_clock(R4MonotonicClockInfo *out) {
    *out=(R4MonotonicClockInfo){.version=1,.size=sizeof(*out),.flags=R4OS_MONOTONIC_CLOCK_FLAG_VALID,
        .frequency_hz=R4OS_MONOTONIC_CLOCK_FREQUENCY_HZ,.source=metadata_mode==3?0:1,.generation=9,
        .resolution_ns=1,.instant_ns=100,.event_requested_hz=metadata_mode==4?0:(metadata_mode==5?1000000000:333),.event_effective_hz=334};
    return 1;
}
void sdk_storage2_table(R4XStartR4Sys2 *out) {
    *out=(R4XStartR4Sys2){.magic=R4OS2_R4SYS_MAGIC,.abi_version=R4OS2_R4SYS_VERSION,.size=sizeof(*out),
        .file_read=(uintptr_t)&fake_file_read,.file_read_at=(uintptr_t)&fake_file_read_at,
        .file_write=(uintptr_t)&fake_file_write,.file_append=(uintptr_t)&fake_file_append,
        .file_metadata2=(uintptr_t)&metadata_read,.directory_metadata_batch2=(uintptr_t)&metadata_batch,.monotonic_clock=(uintptr_t)&metadata_clock};
    metadata_mode=0;
}
int32_t sdk_storage2_view(const R4OS2Context *view,const R4App2Memory *memory) {
    R4App app;
    if(r4_app_init2(view,memory,&app)!=0||app.context||app.system.ctx||app.system.table||app.system.generation2!=view||app.system.memory2!=memory)return -1;
    return app.system.generation2->raw->size==120&&app.group_mask==2?0:-2;
}
