#include <r4os/facades.h>
#include <r4os/metadata2.h>
#include <r4os/text_metrics_platform2.h>
#include <string.h>
#include "AudioWriteParity.c"
#define WIRE_CHECK(test,code) do { if (!(test)) return (code); } while (0)
static uint64_t textmetrics_revision;
static uint32_t textmetrics_calls,textmetrics_legacy_calls;
static int32_t textmetrics_mode;
static int32_t textmetrics_legacy(uint32_t id,const uint8_t *text,R4GuiTextMetrics *out){(void)id;(void)text;(void)out;textmetrics_legacy_calls++;return -71;}
static int32_t textmetrics_measure(uint32_t id,const uint8_t *text,uint32_t length,R4FontAdvance2 *rows,uint32_t capacity,R4FontAdvanceInfo2 *out){
 textmetrics_calls++;
 if(textmetrics_mode==2)return -9;
 *out=(R4FontAdvanceInfo2){.version=1,.size=sizeof(*out),.font_revision=textmetrics_revision,.font_id=id,.text_bytes=length,.required_count=length};
 if(capacity<length)return -7;
 uint32_t width=0;
 for(uint32_t i=0;i<length;i++){width+=text[i]=='W'?11u:3u;rows[i]=(R4FontAdvance2){i+1,width};}
 out->count=length;out->flags=1;return 0;
}
void sdk_textmetrics_mode(int32_t mode){textmetrics_mode=mode;if(mode==1)textmetrics_revision++;}
uint32_t sdk_textmetrics_calls(void){return textmetrics_calls;}
void sdk_textmetrics_tables(R4XStartR4Sys2 *sys,R4XStartR4Draw2 *draw){
 textmetrics_revision=41;textmetrics_mode=0;textmetrics_calls=0;textmetrics_legacy_calls=0;
 *sys=(R4XStartR4Sys2){.magic=R4OS2_R4SYS_MAGIC,.abi_version=2,.size=sizeof(*sys)};
 *draw=(R4XStartR4Draw2){.magic=R4OS2_R4DRAW_MAGIC,.abi_version=2,.size=sizeof(*draw),.font_measure=(uintptr_t)&textmetrics_legacy,.font_prefix_metrics2=(uintptr_t)&textmetrics_measure};
}
int32_t sdk_textmetrics_c_case(void){
 R4XStartR4Sys2 sys;R4XStartR4Draw2 draw;sdk_textmetrics_tables(&sys,&draw);
 R4XStartImport imports[2]={{.group_id=1,.resolved_version=2,.table=(uintptr_t)&sys},{.group_id=3,.resolved_version=2,.table=(uintptr_t)&draw}};
 R4XStartContext2 raw={.magic=R4OS2_START_MAGIC,.abi_major=2,.size=sizeof(raw),.import_count=2,.imports=(uintptr_t)imports};R4OS2Context context;
 WIRE_CHECK(!R4OS2ContextInit(&raw,&context),501);
 R4SdkTextMetricsProvider provider;WIRE_CHECK(!R4SdkTextMetricsProvider2(&context,&provider),502);
 const uint8_t text[]="Wi";R4FontAdvance2 rows[2];R4SdkTextMetrics cache;R4SdkTextMetricsProgress progress;R4SdkTextMetricsKey key;R4SdkWireSpan view;uint32_t offset;
 WIRE_CHECK(!R4SdkTextMetricsInit((R4SdkWireSpan){(uintptr_t)text,2},(R4SdkWireSpan){(uintptr_t)rows,sizeof(rows)},2,provider,&cache),503);
 WIRE_CHECK(R4SdkTextMetricsGetKey(&cache,&key)==-104,504);
 WIRE_CHECK(!R4SdkTextMetricsPrepare(&cache,9,33,&progress)&&progress.count==2&&progress.flags==1&&progress.required_count==2,505);
 WIRE_CHECK(!R4SdkTextMetricsGetKey(&cache,&key)&&key.font_revision==41&&textmetrics_calls==1,506);
 for(uint32_t i=0;i<100;i++)WIRE_CHECK(!R4SdkTextMetricsHit(&cache,key,5,&offset)&&offset==1,507);
 WIRE_CHECK(textmetrics_calls==1&&!textmetrics_legacy_calls,508);
 WIRE_CHECK(!R4SdkTextMetricsGetView(&cache,&view)&&view.length==sizeof(rows)&&rows[1].prefix_width==14,509);
 WIRE_CHECK(!R4SdkTextMetricsValidateFont2(&context,&cache)&&textmetrics_calls==2,510);
 sdk_textmetrics_mode(1);WIRE_CHECK(R4SdkTextMetricsValidateFont2(&context,&cache)==-10&&R4SdkTextMetricsGetView(&cache,&view)==-104,511);
 sdk_textmetrics_mode(2);WIRE_CHECK(R4SdkTextMetricsPrepare(&cache,9,33,&progress)==-9&&!progress.flags,512);
 draw.font_prefix_metrics2=0;WIRE_CHECK(R4SdkTextMetricsProvider2(&context,&provider)==-9002&&!textmetrics_legacy_calls,513);
 return 0;
}

static int32_t metadata2_mode;
static uint32_t metadata2_legacy_calls;
static int32_t metadata2_old(const uint8_t *path,R4FileInfo *out){(void)path;(void)out;metadata2_legacy_calls++;return -71;}
static int32_t metadata2_info(const uint8_t *path,R4FileMetadata2 *out){
    if(path[0]=='m')return 0;
    *out=(R4FileMetadata2){.version=1,.size=sizeof(*out),.flags=1|4|8|32,.byte_size=UINT64_C(0x100000003),.backend_node=UINT64_C(0x100000001),.identity={.mount_generation=11,.namespace_generation=0,.object_hi=UINT64_C(0x100000001),.flags=1|8}};return 1;
}
static int32_t metadata2_page(const uint8_t *path,R4DirectoryMetadataCursor2 *cursor,R4DirectoryMetadataEntry2 *out,uint32_t capacity){
    (void)path;if(metadata2_mode==1)return 0;if(metadata2_mode)return metadata2_mode;
    if(!capacity)return cursor->flags==1?0:-1;if(cursor->scan.backend[0]==2)return -5;
    uint64_t index=cursor->scan.backend[0];out[0]=(R4DirectoryMetadataEntry2){0};metadata2_info((const uint8_t *)"file",&out[0].info);out[0].info.identity.object_hi+=index;out[0].path[0]=(uint8_t)('A'+index);
    cursor->flags=1;cursor->scan.change.mount_generation=11;cursor->scan.backend[0]++;return 1;
}
void sdk_metadata2_mode(int32_t value){metadata2_mode=value;}
void sdk_metadata2_tables(R4XStartR4Sys2 *table){
    metadata2_mode=0;metadata2_legacy_calls=0;
    *table=(R4XStartR4Sys2){.magic=R4OS2_R4SYS_MAGIC,.abi_version=2,.size=sizeof(*table),.file_info=(uintptr_t)&metadata2_old,.file_metadata2=(uintptr_t)&metadata2_info,.directory_metadata_batch2=(uintptr_t)&metadata2_page};
}
int32_t sdk_metadata2_c_case(void){
    R4XStartR4Sys2 table;sdk_metadata2_tables(&table);R4XStartImport import={.group_id=1,.resolved_version=2,.table=(uintptr_t)&table};
    R4XStartContext2 raw={.magic=R4OS2_START_MAGIC,.abi_major=2,.size=sizeof(raw),.import_count=1,.imports=(uintptr_t)&import};R4OS2Context context;
    WIRE_CHECK(!R4OS2ContextInit(&raw,&context),481);R4FileMetadata2 info={0};
    WIRE_CHECK(R4SdkFileMetadata2(&context,(const uint8_t *)"file",&info)==1&&info.backend_node==UINT64_C(0x100000001)&&info.byte_size==UINT64_C(0x100000003),482);
    WIRE_CHECK(R4SdkFileMetadata2Identity(&info)&&info.identity.namespace_generation==0,483);
    WIRE_CHECK(R4SdkFileMetadata2(&context,(const uint8_t *)"missing",&info)==0,484);
    R4DirectoryMetadataCursor2 cursor;R4DirectoryMetadataEntry2 row;
    WIRE_CHECK(!R4SdkDirectoryMetadata2Init(&cursor),485);
    WIRE_CHECK(R4SdkDirectoryMetadata2Batch(&context,0,&cursor,0,0)==-1,486);
    for(uint32_t i=0;i<2;i++)WIRE_CHECK(R4SdkDirectoryMetadata2Batch(&context,(const uint8_t *)"dir",&cursor,&row,1)==1&&row.info.identity.object_hi==UINT64_C(0x100000001)+i,487);
    WIRE_CHECK(R4SdkDirectoryMetadata2Batch(&context,0,&cursor,&row,1)==-5,488);
    metadata2_mode=-10;WIRE_CHECK(R4SdkDirectoryMetadata2Batch(&context,0,&cursor,&row,1)==-10,489);
    table.file_metadata2=0;WIRE_CHECK(R4SdkFileMetadata2(&context,(const uint8_t *)"file",&info)==-9002&&!metadata2_legacy_calls,490);return 0;
}
static uint32_t device_capture_calls;
static int32_t device_capture(R4DeviceInventoryRecord *rows,uint32_t capacity,R4DeviceInventorySnapshotInfo *info){
    device_capture_calls++;uint32_t count=capacity<3?capacity:3;
    for(uint32_t i=0;i<count;i++){rows[i]=(R4DeviceInventoryRecord){0};rows[i].name[0]=(uint8_t)('A'+i);}
    *info=(R4DeviceInventorySnapshotInfo){.version=1,.size=64,.snapshot_generation=capacity>=3?100+device_capture_calls:0,.count=count,.required_count=3,.capacity=capacity,.flags=capacity>=3?3:2,.with_driver=3,.source_mask=1,.record_size=224};return capacity>=3?0:-2;
}
int32_t sdk_device_snapshot_c_case(void){
    device_capture_calls=0;R4DeviceInventoryRecord rows[3];R4SdkDeviceSnapshot state;R4SdkDeviceSnapshotProgress progress;R4SdkDeviceSnapshotCursor cursor;R4SdkDeviceSnapshotPageInfo page;R4SdkWireSpan span={123,456};
    R4SdkDeviceSnapshotProvider provider={.capture=device_capture};
    WIRE_CHECK(!R4SdkDeviceSnapshotInit((R4SdkWireSpan){(uintptr_t)rows,sizeof(rows)},3,provider,&state),451);
    WIRE_CHECK(R4SdkDeviceSnapshotGetView(&state,&span)==-6&&span.address==123&&span.length==456,452);
    WIRE_CHECK(!R4SdkDeviceSnapshotCapture(&state,0,&progress)&&progress.status==R4_DEV_SNAPSHOT_COMPLETE&&!(progress.flags&R4_DEV_SNAPSHOT_IN_CALL),453);
    WIRE_CHECK(!R4SdkDeviceSnapshotBeginPages(&state,&cursor),454);
    for(uint32_t i=0;i<3;i++){
        WIRE_CHECK(!R4SdkDeviceSnapshotPage(&state,&cursor,1,&span,&page)&&page.returned==1&&span.address==(uintptr_t)&rows[i]&&page.status==(i==2?R4_DEV_SNAPSHOT_PAGE_COMPLETE:R4_DEV_SNAPSHOT_PAGE_MORE),455);
    }
    WIRE_CHECK(device_capture_calls==1,456);R4SdkDeviceSnapshotCursor saved=cursor;
    WIRE_CHECK(!R4SdkDeviceSnapshotCapture(&state,0,&progress)&&device_capture_calls==2,457);
    WIRE_CHECK(!R4SdkDeviceSnapshotPage(&state,&cursor,1,&span,&page)&&page.status==R4_DEV_SNAPSHOT_PAGE_RESTART&&!span.length&&!memcmp(&cursor,&saved,sizeof(cursor)),458);
    WIRE_CHECK(!R4SdkDeviceSnapshotClose(&state,&progress)&&R4SdkDeviceSnapshotGetView(&state,&span)==-6,459);
    WIRE_CHECK(!R4SdkDeviceSnapshotInit((R4SdkWireSpan){(uintptr_t)rows,sizeof(rows)},1,provider,&state),460);
    WIRE_CHECK(!R4SdkDeviceSnapshotCapture(&state,0,&progress)&&progress.status==R4_DEV_SNAPSHOT_CAPACITY&&progress.info.required_count==3&&!(progress.flags&R4_DEV_SNAPSHOT_VIEW_COMPLETE),461);
    return 0;
}
static int inventory_busy,inventory_full_calls;
static int32_t inventory_clock(void *unused,R4SdkClockSample *out){(void)unused;*out=(R4SdkClockSample){.identity={1,1,0,1000},.instant_ns=100};return 0;}
static int32_t inventory_full_begin(R4ProgramInventoryCursor *cursor,R4ProgramInventorySummary *summary){(void)cursor;(void)summary;inventory_full_calls++;return -77;}
static int32_t inventory_life_begin(R4ProgramInventoryCursor *cursor){*cursor=(R4ProgramInventoryCursor){.version=1,.size=sizeof(*cursor),.snapshot_generation=9,.program_epoch=9,.flags=3};return 0;}
static int32_t inventory_life_page(R4ProgramInventoryCursor *cursor,R4ProgramLifecycleSnapshot *rows,uint32_t capacity,R4ProgramInventoryPageInfo *page){
    if(!capacity)return -77;
    if(inventory_busy){cursor->program_after_generation=999;return R4OS_PROGRAM_HANDLE_ERROR_WOULD_BLOCK;}
    uint64_t generation=cursor->program_after_generation?12:11;uint32_t more=generation==11;
    rows[0]=(R4ProgramLifecycleSnapshot){.version=1,.size=sizeof(*rows),.handle={.instance_id=(uint32_t)generation-4,.generation=generation}};
    cursor->program_after_generation=generation;
    *page=(R4ProgramInventoryPageInfo){.version=1,.size=sizeof(*page),.snapshot_generation=9,.next_generation=generation,.total=2,.returned=1,.has_more=more,.kind=4,.status=more?1:0};return 0;
}
int32_t sdk_inventory_c_case(void){
    R4ProgramLifecycleSnapshot rows[2];R4SdkInventoryReader reader;R4SdkInventoryProgress progress;R4SdkInventoryMatch match;R4SdkWireSpan view;
    R4SdkInventoryProvider provider={.full_begin=inventory_full_begin,.lifecycle_begin=inventory_life_begin,.lifecycle_page=inventory_life_page};R4SdkClockSample initial;
    WIRE_CHECK(!inventory_clock(0,&initial),401);inventory_busy=0;inventory_full_calls=0;
    WIRE_CHECK(!R4SdkInventoryInit(1,(R4SdkWireSpan){(uintptr_t)rows,sizeof(rows)},2,1,provider,initial,(R4Timeout){.kind=2},&reader),402);
    WIRE_CHECK(!R4SdkInventoryFindExact(&reader,(R4ProgramProcessHandle){.instance_id=7,.generation=11},&match)&&match.disposition==R4_INV_READER_UNKNOWN,403);
    WIRE_CHECK(!R4SdkInventoryStep(&reader,0,inventory_clock,0,&progress)&&!inventory_full_calls,404);
    WIRE_CHECK(!R4SdkInventoryStep(&reader,0,inventory_clock,0,&progress)&&progress.staged_count==1&&!(progress.flags&R4_INV_READER_IN_CALL),405);
    WIRE_CHECK(R4SdkInventoryGetView(&reader,&view)==-6,406);R4ProgramInventoryCursor saved=reader.cursor;inventory_busy=1;
    WIRE_CHECK(!R4SdkInventoryStep(&reader,0,inventory_clock,0,&progress)&&progress.status==R4_INV_READER_WOULD_BLOCK&&!memcmp(&saved,&reader.cursor,sizeof(saved))&&reader.count==1,407);
    inventory_busy=0;WIRE_CHECK(!R4SdkInventoryStep(&reader,0,inventory_clock,0,&progress)&&(progress.flags&R4_INV_READER_VIEW_COMPLETE),408);
    WIRE_CHECK(!R4SdkInventoryGetView(&reader,&view)&&view.length==sizeof(rows)&&rows[1].handle.generation==12,409);
    WIRE_CHECK(!R4SdkInventoryFindExact(&reader,(R4ProgramProcessHandle){.instance_id=7,.generation=11},&match)&&match.disposition==R4_INV_READER_FOUND&&match.index==0,410);
    WIRE_CHECK(!R4SdkInventoryFindExact(&reader,(R4ProgramProcessHandle){.instance_id=7,.generation=12},&match)&&match.disposition==R4_INV_READER_MISSING,411);
    WIRE_CHECK(!R4SdkInventoryRestart(&reader,&progress)&&progress.restarts==1&&R4SdkInventoryGetView(&reader,&view)==-6,412);return 0;
}
typedef struct { uint64_t now;uint32_t calls,cancel,held;R4SdkTransfer *state;uint8_t output[6]; } TransferProbe;
static int32_t transfer_clock(void *raw,R4SdkClockSample *sample){
    TransferProbe *p=raw;*sample=(R4SdkClockSample){.identity={1,1,0,1000},.instant_ns=p->now};return 0;
}
static R4SdkTransferAck transfer_write(void *raw,uint64_t offset,const uint8_t *bytes,uint32_t count,const R4SdkDeadlineBudget *deadline){
    TransferProbe *p=raw;p->calls++;
    if(deadline->deadline_ns!=110||offset+count>6)return (R4SdkTransferAck){.kind=R4_STREAM_XFER_IO_UNCERTAIN,.error_code=-99};
    uint32_t n=count<2?count:2;memcpy(p->output+offset,bytes,n);p->now+=3;
    if(p->cancel){R4SdkTransferProgress stop;if(!R4SdkTransferCancel(p->state,&stop))p->held=(stop.flags&R4_STREAM_XFER_IN_CALL)&&!(stop.flags&R4_STREAM_XFER_TERMINAL);}
    return (R4SdkTransferAck){.bytes=n};
}
int32_t sdk_transfer_c_case(void){
    TransferProbe p={.now=100};R4SdkClockSample initial;R4SdkTransfer state;R4SdkTransferProgress progress;
    WIRE_CHECK(!transfer_clock(&p,&initial),301);
    WIRE_CHECK(!R4SdkTransferInit(1,6,initial,(R4Timeout){.kind=1,.nanoseconds=10},&state),302);p.state=&state;
    const uint8_t bytes[]="abcdef";
    for(uint32_t i=0;i<3;i++){
        WIRE_CHECK(!R4SdkTransferWriteStep(&state,bytes+state.bytes,6-state.bytes,4,0,transfer_clock,&p,transfer_write,&p,&progress),303);
        WIRE_CHECK(progress.bytes==2*(i+1)&&!(progress.flags&R4_STREAM_XFER_IN_CALL),304);
    }
    WIRE_CHECK(progress.outcome==R4_STREAM_XFER_COMPLETE&&(progress.flags&R4_STREAM_XFER_TERMINAL)&&!memcmp(p.output,bytes,6),305);
    p=(TransferProbe){.now=100,.cancel=1,.state=&state};
    WIRE_CHECK(!R4SdkTransferInit(1,6,initial,(R4Timeout){.kind=1,.nanoseconds=10},&state),306);
    WIRE_CHECK(!R4SdkTransferWriteStep(&state,bytes,6,4,0,transfer_clock,&p,transfer_write,&p,&progress),307);
    WIRE_CHECK(p.held&&progress.bytes==2&&progress.outcome==R4_STREAM_XFER_CANCELLED&&!(progress.flags&R4_STREAM_XFER_IN_CALL),308);
    uint32_t calls=p.calls;
    WIRE_CHECK(!R4SdkTransferWriteStep(&state,bytes+2,4,4,0,transfer_clock,&p,transfer_write,&p,&progress)&&p.calls==calls,309);
    return 0;
}
typedef struct { uint8_t output[3]; uint32_t count,calls; } CliProbe;
static R4SdkDiagnosticAck cli_write(void *raw,const R4SdkDiagnosticChunk *c) {
    CliProbe *p=raw;p->calls++;
    uint32_t count=c->length>1?1:c->length;
    if(p->count+count>sizeof(p->output)) return (R4SdkDiagnosticAck){.kind=R4_DIAG_SINK_UNCERTAIN,.error_code=-99};
    memcpy(p->output+p->count,c->data,count);p->count+=count;
    return (R4SdkDiagnosticAck){.accepted_bytes=count};
}
int32_t sdk_cli_c_case(void) {
    const uint8_t raw[]=" \"\" /Out:  cmd  \"a b\" ";
    R4SdkArgCursor cursor;R4SdkArgFailure failure;R4SdkArgToken token;R4SdkArgSwitch option;
    WIRE_CHECK(R4SdkArgInit(raw,sizeof(raw)-1,(R4SdkArgPolicy){1,1,4096},&cursor,&failure)==0,201);
    WIRE_CHECK(R4SdkArgNext(&cursor,&token,&failure)==0 && token.flags==1 && token.value_start==token.value_end,202);
    WIRE_CHECK(R4SdkArgNext(&cursor,&token,&failure)==0,203);
    WIRE_CHECK(R4SdkArgSwitchParts(raw,sizeof(raw)-1,token,&option)==0 && option.is_switch && option.has_value && option.value_length==0,204);
    uintptr_t start=0,len=0;
    WIRE_CHECK(R4SdkArgRemaining(&cursor,0,&start,&len)==0 && len==sizeof(raw)-1-start && memcmp(raw+start,"  cmd  \"a b\" ",len)==0,205);
    const uint8_t invalid[]="a\"b";
    WIRE_CHECK(R4SdkArgInit(invalid,sizeof(invalid)-1,(R4SdkArgPolicy){1,1,4096},&cursor,&failure)==0,206);
    memset(&token,0xa5,sizeof(token));R4SdkArgToken before=token;
    WIRE_CHECK(R4SdkArgNext(&cursor,&token,&failure)==R4_ARG_INVALID_QUOTE && failure.offset==1 && cursor.position==0 && memcmp(&before,&token,sizeof(token))==0,207);
    uint8_t storage[11];R4SdkDiagnosticBuffer queue;R4SdkDiagnosticAppend append;
    WIRE_CHECK(R4SdkDiagnosticInit(storage,sizeof(storage),&queue)==0,208);
    const uint8_t euro[]={0xe2,0x82,0xac};
    WIRE_CHECK(R4SdkDiagnosticAppendRecord(&queue,euro,3,1,&append)==0 && append.accepted_records==1,209);
    WIRE_CHECK(R4SdkDiagnosticAppendRecord(&queue,(const uint8_t *)"x",1,1,&append)==0 && append.kind==R4_DIAG_FULL,210);
    CliProbe probe={0};R4SdkDiagnosticFlush result;
    for(uint32_t i=0;i<3;i++) WIRE_CHECK(R4SdkDiagnosticFlushOnce(&queue,3,cli_write,&probe,&result)==0 && result.accepted_bytes==1,211);
    WIRE_CHECK(probe.calls==3 && !memcmp(probe.output,euro,3) && result.completed_records==1,212);
    R4SdkDiagnosticStats stats;WIRE_CHECK(R4SdkDiagnosticReadStats(&queue,&stats)==0 && stats.sent_bytes==3 && stats.rejected_records==1 && !stats.queued_records,213);
    return 0;
}
int32_t sdk_wire_c_case(void) {
    _Alignas(8) const uint8_t data[]={0xff,1,2,3,4,5,6,7,8};
    R4SdkWireReader reader;uint64_t value=99;
    WIRE_CHECK(R4SdkWireReaderInit(data+1,8,&reader)==0,101);
    WIRE_CHECK(R4SdkWireReadInteger(&reader,2,R4_WIRE_BIG,&value)==0 && value==0x0102,102);
    R4SdkWireMark mark;WIRE_CHECK(R4SdkWireReaderMark(&reader,&mark)==0,103);
    value=99;WIRE_CHECK(R4SdkWireReadInteger(&reader,8,R4_WIRE_LITTLE,&value)==R4_WIRE_TRUNCATED && value==99 && reader.position==2,104);
    WIRE_CHECK(R4SdkWireReaderRestore(&reader,mark)==0,105);
    WIRE_CHECK(R4SdkWireReadInteger(&reader,4,R4_WIRE_LITTLE,&value)==0 && value==0x06050403,106);
    mark.kind=2;WIRE_CHECK(R4SdkWireReaderRestore(&reader,mark)==R4_WIRE_INVALID_MARK && reader.position==6,107);
    WIRE_CHECK(R4SdkWireReaderInit(0,0,&reader)==0,108);
    R4SdkWireSpan span;WIRE_CHECK(R4SdkWireTake(&reader,0,&span)==0 && !span.length,109);
    WIRE_CHECK(R4SdkWireTake(&reader,1,&span)==R4_WIRE_TRUNCATED,110);
    uint8_t bytes[]={0,1,2,3,4,5,6,7};R4SdkWireWriter writer;
    WIRE_CHECK(R4SdkWireWriterInit(bytes,8,&writer)==0,111);writer.position=2;
    WIRE_CHECK(R4SdkWirePut(&writer,bytes,6)==0 && memcmp(bytes,(uint8_t[]){0,1,0,1,2,3,4,5},8)==0,112);
    WIRE_CHECK(R4SdkWireWriteInteger(&writer,2,R4_WIRE_BIG,65536)==R4_WIRE_VALUE_OVERFLOW && writer.position==8,113);
    uint8_t before[8];memcpy(before,bytes,8);
    WIRE_CHECK(R4SdkWireWriteInteger(&writer,2,R4_WIRE_BIG,1)==R4_WIRE_CAPACITY && memcmp(before,bytes,8)==0,114);
    const uint8_t rfc[]={0x00,0x01,0xf2,0x03,0xf4,0xf5,0xf6,0xf7};
    for(uintptr_t cut=0;cut<=sizeof(rfc);++cut){
        R4SdkChecksum16 checksum;uint16_t result=0;
        WIRE_CHECK(R4SdkChecksumInit(&checksum)==0,115);
        WIRE_CHECK(R4SdkChecksumAdd(&checksum,rfc,cut)==0 && R4SdkChecksumAdd(&checksum,rfc+cut,sizeof(rfc)-cut)==0,116);
        WIRE_CHECK(R4SdkChecksumFinish(&checksum,&result)==0 && result==0x220d,117);
    }
    R4SdkChecksum16 checksum;uint16_t sum=0;
    WIRE_CHECK(R4SdkChecksumInit(&checksum)==0 && R4SdkChecksumAdd(&checksum,(uint8_t[]){1},1)==0 && R4SdkChecksumAdd(&checksum,(uint8_t[]){2,3},2)==0,118);
    R4SdkChecksum16 saved=checksum;
    WIRE_CHECK(R4SdkChecksumFinish(&checksum,&sum)==0 && sum==0xfbfd && memcmp(&saved,&checksum,sizeof(saved))==0,119);
    checksum=(R4SdkChecksum16){.bytes=UINT64_MAX-1};saved=checksum;
    WIRE_CHECK(R4SdkChecksumAdd(&checksum,(uint8_t[]){0,1},2)==R4_CHECKSUM_LENGTH_OVERFLOW && memcmp(&saved,&checksum,sizeof(saved))==0,120);
    typedef struct {uint32_t version,size;uint64_t value;} Record;
    Record record={1,16,0x1234};R4ProtocolBuffer buffer={.data=&record,.len=16,.capacity=16};
    R4SdkNativePolicy policy=R4SDK_NATIVE_VERSIONED(Record,1,R4_NATIVE_INPUT,R4_NATIVE_EXACT);uintptr_t address=77;
    WIRE_CHECK(R4SdkNativeAdmit(&buffer,policy,R4_NATIVE_INPUT,&address)==0 && address==(uintptr_t)&record,121);
    record.version=2;address=77;
    WIRE_CHECK(R4SdkNativeAdmit(&buffer,policy,R4_NATIVE_INPUT,&address)==R4_NATIVE_UNSUPPORTED_VERSION && address==77,122);
    record.version=1;buffer.flags=1;
    WIRE_CHECK(R4SdkNativeAdmit(&buffer,policy,R4_NATIVE_INPUT,&address)==R4_NATIVE_FLAGS,123);buffer.flags=0;
    buffer.data=(uint8_t *)&record+1;
    WIRE_CHECK(R4SdkNativeAdmit(&buffer,policy,R4_NATIVE_INPUT,&address)==R4_NATIVE_MISALIGNED,124);
    Record output;buffer=(R4ProtocolBuffer){.data=&output,.capacity=16};
    policy=R4SDK_NATIVE_VERSIONED(Record,1,R4_NATIVE_OUTPUT,R4_NATIVE_EXACT);
    WIRE_CHECK(R4SdkNativeAdmit(&buffer,policy,R4_NATIVE_OUTPUT,&address)==0,125);
    output=(Record){2,16,55};
    WIRE_CHECK(R4SdkNativePublish(&buffer,policy,16)==R4_NATIVE_UNSUPPORTED_VERSION && !buffer.len,126);
    output.version=1;WIRE_CHECK(R4SdkNativePublish(&buffer,policy,16)==0 && buffer.len==16,127);
    R4SdkBlockLimits limits={1000,128,1048576,28,R4_BLOCK_EXACT};R4SdkBlockShape shape={0,0};
    WIRE_CHECK(R4SdkBlockTransfer(996,4,4096,16384,limits,&shape)==0 && shape.byte_count==16384 && shape.last_lba==999,128);
    R4SdkBlockShape old=shape;
    WIRE_CHECK(R4SdkBlockTransfer(997,4,4096,16384,limits,&shape)==R4_BLOCK_OUT_OF_RANGE && memcmp(&old,&shape,sizeof(old))==0,129);
    WIRE_CHECK(R4SdkBlockTransfer(UINT64_MAX,2,1,2,limits,&shape)==R4_BLOCK_OVERFLOW,130);
    limits.capacity_blocks=0;WIRE_CHECK(R4SdkBlockTransfer(0,1,512,512,limits,&shape)==R4_BLOCK_UNKNOWN_GEOMETRY,131);
    return 0;
}
#undef WIRE_CHECK
static int ok(R4SdkDataSlot v){return !v.status && !(v.flags&R4SDKDATA_NATIVE_ERROR);}
int32_t sdk_data_c_case(const uint8_t *manifest,uintptr_t length){
    R4SdkDataSlot role=R4SdkDataJson_constant_role();
    if(!ok(role) || role.length!=11 || memcmp(role.ptr,"format.json",11))return 16;
    R4SdkDataSha256 hash;uint8_t digest[R4SdkDataSha256_digest_length];
    _Static_assert(R4SdkDataSha256_digest_length==32,"SHA256 digest bytes");
    if(!ok(R4SdkData_hashInit(0,&hash)) || !ok(R4SdkDataSha256_update(0,&hash,(const uint8_t *)"abc",3)) || !ok(R4SdkDataSha256_finalResult(0,&hash,(void *)digest)))return 1;
    if(digest[0]!=0xba || digest[31]!=0xad)return 2;
    R4SdkDataEncodingDecoder decoder;uint8_t out[16];
    if(!ok(R4SdkDataEncodingDecoder_init(0,R4SdkDataEncodingEncoding_utf8,1,0,&decoder)))return 3;
    R4SdkDataSlot value=R4SdkDataEncodingDecoder_decode(0,&decoder,(const uint8_t *)"\xc3",1,out,sizeof(out),1);
    if(!ok(value) || value.length)return 4;
    value=R4SdkDataEncodingDecoder_decode(0,&decoder,(const uint8_t *)"\xbc",1,out,sizeof(out),0);
    if(!ok(value) || value.length!=2 || memcmp(value.ptr,"\xc3\xbc",2))return 5;
    R4SdkDataRandomProvider random;
    if(!ok(R4SdkDataRandomProvider_create(&random)))return 6;
    memset(out,0xa5,sizeof(out));value=R4SdkDataRandomProvider_fill(0,&random,out,sizeof(out));
    if(!ok(value) || value.bits)return 7;
    for(uintptr_t i=0;i<sizeof(out);++i)if(out[i])return 8;
    value=R4SdkDataJson_mapStatus(0,-9);
    if(!ok(value) || !(value.flags&R4SDKDATA_PRESENT) || value.length!=10 || memcmp(value.ptr,"WrongToken",10))return 9;
    R4SdkDataArena arena;R4SdkDataAllocator allocator;R4SdkDataManifestManifest parsed;uint8_t scratch[65536];
    if(!ok(R4SdkData_arena(0,&arena,scratch,sizeof(scratch))) || !ok(R4SdkData_allocator(0,&arena,&allocator)))return 10;
    if(!ok(R4SdkDataManifest_parse(0,&allocator,(const uint8_t *)"module.R4MF",11,manifest,length,&parsed)))return 11;
    value=R4SdkDataManifestManifest_get_name(&parsed);
    if(!ok(value) || value.length!=8 || memcmp(value.ptr,"DATAUNIT",8))return 12;
    R4SdkDataManifestModuleVersion version;
    if(!ok(R4SdkDataManifestManifest_get_module_version(&parsed,&version)) || R4SdkDataManifestModuleVersion_get_patch(&version).bits!=3)return 13;
    R4SdkDataUrlSearchParams params;
    if(!ok(R4SdkDataUrlSearchParams_init(0,(const uint8_t *)"a=one+two&a=three",17,&params)))return 14;
    value=R4SdkDataUrlSearchParams_get(0,&params,(const uint8_t *)"a",1);
    if(!ok(value) || value.length!=7 || memcmp(value.ptr,"one two",7))return 15;
    return 0;
}

int32_t sdk_ico_c_case(const uint8_t *bytes,uintptr_t length){
    R4SdkDataIcoEntry entry;R4SdkDataIcoBitmapImage image;
    if(!ok(R4SdkDataIco_chooseBest(0,bytes,length,32,&entry)) ||
       !ok(R4SdkDataIco_parseBmpImage(0,bytes,length,&entry,&image)))return 1;
    const uint32_t colors[2][4]={{0x0000ff,0x00ff00,0xff0000,0xffffff},{0xff0000,0x0000ff,0x0000ff,0xff0000}};
    const uint8_t opacity[4]={255,0,255,255};
    uint32_t rgb[24];uint8_t alpha[24];
    for(uint32_t i=0;i<24;++i){rgb[i]=0x12345678;alpha[i]=91;}
    R4SdkDataSlot value=R4SdkDataIco_copyScaledPixels(0,bytes,length,&image,rgb,24,alpha,24,4,4,6);
    if(!ok(value)||value.bits!=1)return 2;
    uint32_t indexed=R4SdkDataIcoBitmapImage_get_bpp(&image).bits==8;
    for(uint32_t i=0;i<24;++i){
        uint32_t x=i%6,y=i/6;
        if(x<4){uint32_t at=(y/2)*2+x/2;if(rgb[i]!=colors[indexed][at]||alpha[i]!=opacity[at])return 3;}
        else if(rgb[i]!=0x12345678||alpha[i]!=91)return 4;
    }
    uint32_t before[24];memcpy(before,rgb,sizeof rgb);
    value=R4SdkDataIco_copyScaledPixels(0,bytes,length,&image,rgb,3,alpha,24,2,2,2);
    if(!ok(value)||value.bits||memcmp(before,rgb,sizeof rgb))return 5;
    value=R4SdkDataIco_copyScaledPixels(0,bytes,length,&image,rgb,24,(uint8_t *)rgb,sizeof rgb,2,2,2);
    if(!ok(value)||value.bits||memcmp(before,rgb,sizeof rgb))return 6;
    value=R4SdkDataIco_copyScaledPixels(0,bytes,length,&image,rgb,24,alpha,24,2,2,UINTPTR_MAX);
    if(!ok(value)||value.bits||memcmp(before,rgb,sizeof rgb))return 7;
    if(!ok(R4SdkDataIcoBitmapImage_set_pixel_offset(&image,UINTPTR_MAX)))return 8;
    value=R4SdkDataIco_copyScaledPixels(0,bytes,length,&image,rgb,24,alpha,24,2,2,2);
    if(!ok(value)||value.bits||memcmp(before,rgb,sizeof rgb))return 9;
    return 0;
}

#include <r4os/file_picker_platform2.h>
#define PICKER24_CHECK(test,code) do { if (!(test)) return (code); } while (0)
static int32_t picker24_mode;
static uint32_t picker24_calls;
static R4FileMetadata2 picker24_meta(uint64_t node,int directory){
 return (R4FileMetadata2){.version=1,.size=sizeof(R4FileMetadata2),.flags=1|4|(directory?2:8),.byte_size=directory?0:9,.identity={.mount_generation=23,.namespace_generation=19,.object_hi=node,.mount_slot=4,.provider=2,.flags=1|4}};
}
static int32_t picker24_info(const uint8_t *path,R4FileMetadata2 *out){
 picker24_calls++;
 if(!strcmp((const char *)path,"C:\\DIR")){*out=picker24_meta(1,1);return 1;}
 if(!strcmp((const char *)path,"C:\\DIR\\A.TXT")){*out=picker24_meta(picker24_mode==9?100:2,0);return 1;}
 if(!strcmp((const char *)path,"C:\\DIR\\B.TXT")){*out=picker24_meta(3,0);return 1;}
 if(!strcmp((const char *)path,"C:\\DIR\\SUB")){*out=picker24_meta(4,1);return 1;}
 return 0;
}
static int32_t picker24_batch(const uint8_t *path,R4DirectoryMetadataCursor2 *cursor,R4DirectoryMetadataEntry2 *out,uint32_t capacity){
 (void)path;picker24_calls++;
 if(picker24_mode==-10)return -10;
 if(!capacity)return cursor->flags==1?0:-1;
 if(picker24_mode==-9&&cursor->scan.backend[0]==4)return -9;
 cursor->flags=1;cursor->namespace_generation=19;cursor->scan.change.mount_generation=23;cursor->scan.change.mount_slot=4;
 if(picker24_mode==3)return 0;
 static const char *names[]={"C:\\DIR\\A.TXT","C:\\DIR\\HIDE.BIN","C:\\DIR\\SUB","C:\\DIR\\B.TXT"};
 uint64_t index=cursor->scan.backend[0];if(index==4)return -5;
 *out=(R4DirectoryMetadataEntry2){.info=picker24_meta(index==3?3:index+2,index==2)};
 memcpy(out->path,names[index],strlen(names[index])+1);cursor->scan.backend[0]++;return 1;
}
void sdk_picker24_mode(int32_t mode){picker24_mode=mode;}
uint32_t sdk_picker24_calls(void){return picker24_calls;}
void sdk_picker24_tables(R4XStartR4Sys2 *table){
 picker24_mode=0;picker24_calls=0;
 *table=(R4XStartR4Sys2){.magic=R4OS2_R4SYS_MAGIC,.abi_version=2,.size=sizeof(*table),.file_metadata2=(uintptr_t)&picker24_info,.directory_metadata_batch2=(uintptr_t)&picker24_batch};
}
int32_t sdk_picker24_c_case(void){
 R4XStartR4Sys2 table;sdk_picker24_tables(&table);R4XStartImport import={.group_id=1,.resolved_version=2,.table=(uintptr_t)&table};
 R4XStartContext2 raw={.magic=R4OS2_START_MAGIC,.abi_major=2,.size=sizeof(raw),.import_count=1,.imports=(uintptr_t)&import};R4OS2Context context;
 PICKER24_CHECK(!R4OS2ContextInit(&raw,&context),601);
 R4SdkFilePickerProvider provider;PICKER24_CHECK(!R4SdkFilePickerProvider2(&context,&provider),602);
 R4SdkFilePickerRow a[6],b[6];R4SdkFilePicker s;R4SdkFilePickerProgress p;R4SdkFilePickerDecision d;R4SdkWireSpan view;
 PICKER24_CHECK(!R4SdkFilePickerInit((R4SdkWireSpan){(uintptr_t)a,sizeof(a)},(R4SdkWireSpan){(uintptr_t)b,sizeof(b)},6,2,(R4SdkWireSpan){(uintptr_t)".txt",4},provider,&s),603);
 PICKER24_CHECK(!R4SdkFilePickerBegin(&s,(R4SdkWireSpan){(uintptr_t)"C:\\DIR",6},0)&&R4SdkFilePickerView(&s,&view)==-204,604);
 for(uint32_t i=0;i<20;i++){uint32_t before=picker24_calls;PICKER24_CHECK(!R4SdkFilePickerStep(&s,1)&&picker24_calls-before<=1&&!R4SdkFilePickerGetProgress(&s,&p),605);if(!(p.flags&2))break;}
 PICKER24_CHECK(p.flags==1&&p.count==4&&p.revision==1&&!R4SdkFilePickerView(&s,&view)&&view.length==4*sizeof(a[0]),606);
 PICKER24_CHECK(!R4SdkFilePickerSelect(&s,p.revision,1,2)&&!R4SdkFilePickerActivate(&s,p.revision,0,0,&d)&&d.kind==2&&!s.confirmed.kind,607);
 PICKER24_CHECK(!R4SdkFilePickerActivate(&s,p.revision,0,1,&d)&&d.kind==1&&d.entry.info.identity.object_hi==2,608);
 R4SdkFilePickerDecision confirmed=s.confirmed;picker24_mode=9;
 PICKER24_CHECK(R4SdkFilePickerActivate(&s,p.revision,0,1,&d)==-10&&!memcmp(&confirmed,&s.confirmed,sizeof(confirmed)),609);
 picker24_mode=0;PICKER24_CHECK(!R4SdkFilePickerName(&s,(R4SdkWireSpan){(uintptr_t)"A.TXT",5})&&!R4SdkFilePickerActivate(&s,p.revision,1,0,&d)&&d.kind==2,615);
 picker24_mode=9;PICKER24_CHECK(R4SdkFilePickerActivate(&s,p.revision,1,1,&d)==-10&&!memcmp(&confirmed,&s.confirmed,sizeof(confirmed)),616);
 picker24_mode=0;PICKER24_CHECK(!R4SdkFilePickerActivate(&s,p.revision,1,1,&d)&&d.kind==1,617);
 picker24_mode=0;PICKER24_CHECK(!R4SdkFilePickerName(&s,(R4SdkWireSpan){(uintptr_t)"NEW.TXT",7})&&!R4SdkFilePickerActivate(&s,p.revision,1,0,&d)&&d.kind==1&&!d.entry.info.flags,610);
 PICKER24_CHECK(R4SdkFilePickerName(&s,(R4SdkWireSpan){(uintptr_t)"..",2})==-201,611);
 picker24_mode=-9;PICKER24_CHECK(!R4SdkFilePickerBegin(&s,(R4SdkWireSpan){(uintptr_t)"C:\\DIR",6},1)&&R4SdkFilePickerStep(&s,64)==-9&&!R4SdkFilePickerView(&s,&view)&&s.revision==1,612);
 PICKER24_CHECK(!R4SdkFilePickerCancel(&s,&d)&&d.kind==3&&R4SdkFilePickerStep(&s,1)==-206,613);
 table.file_metadata2=0;PICKER24_CHECK(R4SdkFilePickerProvider2(&context,&provider)==-9002,614);return 0;
}

#undef PICKER24_CHECK
