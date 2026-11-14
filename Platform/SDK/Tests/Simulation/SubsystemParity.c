/* Shared synthetic work, independent host calls. No ROM or emulator code. */
#include <r4os/facades.h>
#include "GuestContext2.h"
static void bytes_fill(void *p,int value,uintptr_t count){volatile uint8_t *bytes=p;for(uintptr_t i=0;i<count;i++)bytes[i]=(uint8_t)value;}
static int bytes_compare(const void *a,const void *b,uintptr_t count){const uint8_t *left=a,*right=b;for(uintptr_t i=0;i<count;i++)if(left[i]!=right[i])return (int)left[i]-(int)right[i];return 0;}
#define S R4SdkSubsystemSlot
#define P R4SDKSUBSYSTEM_PRESENT
#define K(name) R4SdkSubsystemCallbackKind_##name
#define BIT(name) (UINT64_C(1)<<K(name))
static int good(S v) { return v.status==0 && !(v.flags&R4SDKSUBSYSTEM_NATIVE_ERROR); }
#define OK(v) good(v)
#define NEED(x,n) do { if(!(x)) return (n); } while(0)
static uint64_t last_work[7],last_video;
typedef struct Model { uint64_t steps,operations,resets,presents,checksum,guest_ns,fault,host_state; uint32_t pixels[256]; } Model;
_Static_assert(sizeof(Model)<=8192,"fixture storage");
void sdk65_fixture_init(void *p) { bytes_fill(p,0,sizeof(Model)); }
uint64_t sdk65_fixture_mask(void) {return BIT(verify_host)|BIT(guest_step)|BIT(guest_reset)|BIT(guest_audio)|BIT(host_poll)|BIT(host_present)|BIT(video_begin_full)|BIT(video_begin_damage)|BIT(video_clear)|BIT(video_raster)|BIT(video_indexed8)|BIT(video_commit_full)|BIT(video_commit_damage)|BIT(video_cancel);}
void sdk65_fixture_summary(const void *p,uint64_t *out) {const Model *m=p;out[0]=m->steps;out[1]=m->operations;out[2]=m->resets;out[3]=m->presents;out[4]=m->checksum;out[5]=m->guest_ns;out[6]=m->fault;}
S sdk65_fixture_dispatch(void *p,uint32_t kind,const S *a,uint32_t count,void *output) {
    Model *m=p;S ret={.flags=P};
    if(kind==K(verify_host)){if(count!=2 || !a[1].ptr || !a[1].length)m->fault=7;ret.bits=m->host_state;return ret;}
    if(kind==K(guest_step)) {
        if(count!=3 || a[1].bits!=4) m->fault=1;
        m->steps++;m->operations+=a[1].bits;m->guest_ns=a[2].bits;
        for(uint32_t i=0;i<(uint32_t)a[1].bits;i++)m->checksum=m->checksum*UINT64_C(33)+m->steps*7+i;
        S v=R4SdkSubsystemRuntimeStepResult_from_fields(output,0,1,0,0,(uint32_t)a[1].bits);
        if(!OK(v))m->fault=2;
        ret.ptr=output;return ret;
    }
    if(kind==K(guest_reset)){m->resets++;return ret;}
    if(kind==K(guest_audio)){bytes_fill(a[1].ptr,0,(size_t)a[1].length);ret.bits=a[1].length;return ret;}
    if(kind==K(host_poll)){S v=R4SdkSubsystemRuntimeHostPollResult_set_idle(output);if(!OK(v))m->fault=3;ret.ptr=output;return ret;}
    if(kind==K(host_present)){m->presents++;ret.bits=1;return ret;}
    if(kind==K(video_clear)){for(uint32_t i=0;i<256;i++)m->pixels[i]=(uint32_t)a[1].bits;return ret;}
    if(kind==K(video_raster)) {
        if(count!=7 || a[6].length!=a[3].bits*a[4].bits){m->fault=4;return ret;}
        const uint32_t *pixels=a[6].ptr;uint32_t w=(uint32_t)a[3].bits,h=(uint32_t)a[4].bits,scale=(uint32_t)a[5].bits;
        for(uint32_t y=0;y<h;y++)for(uint32_t x=0;x<w;x++)for(uint32_t sy=0;sy<scale;sy++)for(uint32_t sx=0;sx<scale;sx++) {
            uint32_t dx=(uint32_t)a[1].bits+x*scale+sx,dy=(uint32_t)a[2].bits+y*scale+sy;
            if(dx>=16 || dy>=16)m->fault=5;else m->pixels[dy*16+dx]=pixels[y*w+x];
        }
        return ret;
    }
    if(kind==K(video_begin_full)||kind==K(video_begin_damage)||kind==K(video_commit_full)||kind==K(video_commit_damage)||kind==K(video_cancel)||kind==K(video_indexed8))return ret;
    m->fault=6;ret.status=-1;return ret;
}
static int table(Model *m,R4SdkSubsystemCallbackTable *table) {
    sdk65_fixture_init(m);S user={.ptr=m,.flags=P},fn={.ptr=(void*)(uintptr_t)&sdk65_fixture_dispatch,.flags=P};
    return OK(R4SdkSubsystemCallbackTable_from_fields(table,user,sdk65_fixture_mask(),fn));
}
int sdk65_c_runtime(uint64_t *out) {
    Model m;R4SdkSubsystemCallbackTable t;NEED(table(&m,&t),1);
    R4SdkSubsystemRuntimeGuestDriver guest;R4SdkSubsystemRuntimeHostDriver host;R4SdkSubsystemRuntimeConfig config;R4SdkSubsystemRuntimeRuntime rt;R4SdkSubsystemRuntimeCycleResult cycle;
    NEED(OK(R4SdkSubsystem_guestDriver(0,&t,&guest)),2);NEED(OK(R4SdkSubsystem_hostDriver(0,&t,&host)),3);
    NEED(OK(R4SdkSubsystemRuntimeConfig_from_fields(&config,4,4,8,1)),4);
    NEED(OK(R4SdkSubsystemRuntimeRuntime_init(0,&config,1000,0,(S){0},&rt)),5);
    NEED(OK(R4SdkSubsystemRuntimeRuntime_cycle(0,&rt,10,&guest,&host,&cycle)),6);
    NEED(OK(R4SdkSubsystemRuntimeRuntime_request(0,&rt,1,10,&guest)),7);
    NEED(OK(R4SdkSubsystemRuntimeRuntime_cycle(0,&rt,40,&guest,&host,&cycle)),8);
    NEED(m.steps==1,9);
    NEED(OK(R4SdkSubsystemRuntimeRuntime_request(0,&rt,2,40,&guest)),10);
    NEED(OK(R4SdkSubsystemRuntimeRuntime_cycle(0,&rt,50,&guest,&host,&cycle)),11);
    NEED(m.steps==2 && m.guest_ns==UINT64_C(10000000),12);
    NEED(OK(R4SdkSubsystemRuntimeRuntime_request(0,&rt,4,50,&guest)),13);
    NEED(OK(R4SdkSubsystemRuntimeRuntime_cycle(0,&rt,60,&guest,&host,&cycle)),14);
    NEED(OK(R4SdkSubsystemRuntimeRuntime_request(0,&rt,8,70,&guest)),15);
    NEED(OK(R4SdkSubsystemRuntimeRuntime_cycle(0,&rt,70,&guest,&host,&cycle)),16);
    NEED(R4SdkSubsystemRuntimeRuntime_get_state(&rt).bits==R4SdkSubsystemRuntimeLifecycleState_closed,17);
    NEED(OK(R4SdkSubsystemRuntimeRuntime_shutdown(0,&rt)),18);
    NEED(OK(R4SdkSubsystemRuntimeRuntime_shutdown(0,&rt)),19);
    NEED(m.steps==3 && m.operations==12 && m.resets==1 && !m.fault,20);
    sdk65_fixture_summary(&m,out);for(unsigned i=0;i<7;i++)last_work[i]=out[i];return 0;
}
int sdk65_c_video(uint64_t *out) {
    Model m;R4SdkSubsystemCallbackTable t;NEED(table(&m,&t),1);
    static uint32_t scratch[128*128];uint32_t pixels[6]={1,2,3,4,5,6};
    R4SdkSubsystemVideoBackend backend;R4SdkSubsystemVideoSurface surface;R4SdkSubsystemVideoPresenter present;R4SdkSubsystemVideoPresentResult result;
    NEED(OK(R4SdkSubsystem_videoBackend(0,&t,0,0,0,&backend)),2);
    NEED(OK(R4SdkSubsystemVideoSurface_initXrgb32(0,pixels,6,3,2,&surface)),3);
    NEED(OK(R4SdkSubsystemVideoPresenter_init(0,&surface,scratch,128*128,&present)),4);
    NEED(OK(R4SdkSubsystemVideoPresenter_presentTo(0,&present,&backend,6,4,&result)),5);
    NEED(R4SdkSubsystemVideoPresentResult_inspectNative(&result).bits==R4SdkSubsystemVideoPresentResult_TAG_presented,6);
    for(uint32_t y=0;y<4;y++)for(uint32_t x=0;x<6;x++)NEED(m.pixels[y*16+x]==pixels[(y/2)*3+x/2],7);
    NEED(OK(R4SdkSubsystemVideoPresenter_presentTo(0,&present,&backend,6,4,&result)),8);
    NEED(R4SdkSubsystemVideoPresentResult_inspectNative(&result).bits==0,9);
    pixels[1]=17;R4SdkSubsystemVideoRect rect;NEED(OK(R4SdkSubsystemVideoRect_create(&rect,1,0,1,1)),10);
    NEED(OK(R4SdkSubsystemVideoPresenter_invalidate(0,&present,&rect)),11);
    NEED(OK(R4SdkSubsystemVideoPresenter_presentTo(0,&present,&backend,6,4,&result)),12);
    NEED(m.pixels[2]==17 && m.pixels[3]==17 && !m.fault,13);
    NEED(OK(R4SdkSubsystemVideoPresenter_presentTo(0,&present,&backend,8,8,&result)),14);
    NEED(OK(R4SdkSubsystemVideoPresenter_deinit(0,&present,&backend)),15);
    uint64_t sum=0;for(uint32_t i=0;i<256;i++)sum=sum*33+m.pixels[i];out[0]=sum;out[1]=m.fault;last_video=sum;
    return 0;
}
uint64_t sdk65_fixture_pixels_hash(const void *p) {const Model *m=p;uint64_t sum=0;for(uint32_t i=0;i<256;i++)sum=sum*33+m->pixels[i];return sum;}
int sdk65_guest_media_save(const R4XStartContext2 *start) {
    R4SdkSubsystemContext context;NEED(R4SdkSubsystem_open2(0,&context,start).bits==1,101);
    R4SdkSubsystemNative_app_storage_Files files;NEED(OK(R4SdkSubsystem_platformFiles(0,&context,&files)),102);
    R4SdkSubsystemCallbackTable hooks;NEED(OK(R4SdkSubsystemCallbackTable_create(&hooks)),103);
    R4SdkDataNative_Value31 directories[2];
    NEED(R4SdkDataNative_Value31_create(&directories[0],(const uint8_t*)"C:\\TEMP",7).status==0,104);
    NEED(R4SdkDataNative_Value31_create(&directories[1],(const uint8_t*)"C:\\TEMP\\SP65A",13).status==0,105);
    R4SdkSubsystemPersistenceConfiguration config;
    const char root[]="C:\\TEMP\\SP65A\\";
    NEED(OK(R4SdkSubsystem_persistenceConfiguration(0,&hooks,(const uint8_t*)root,sizeof(root)-1,directories,2,0,0,0,0,&config)),106);
    R4SdkSubsystemStore first,second;R4SdkSubsystemPersistenceBackend a,b;
    NEED(OK(R4SdkSubsystemStore_init(0,&files,&config,&first)),107);NEED(OK(R4SdkSubsystemStore_init(0,&files,&config,&second)),108);
    NEED(OK(R4SdkSubsystemStore_backend(0,&first,&a)),109);NEED(OK(R4SdkSubsystemStore_backend(0,&second,&b)),110);
    R4SdkDataSha256 hash;R4SdkDataNative_Value158 digest;
    NEED(R4SdkData_hashInit(0,&hash).status==0,111);NEED(R4SdkDataSha256_update(0,&hash,(const uint8_t*)"S65!",4).status==0,112);NEED(R4SdkDataSha256_final(0,&hash,&digest).status==0,113);
    NEED(OK(R4SdkSubsystemPersistenceBackend_acquire(0,&a,&digest,5)),114);
    S busy=R4SdkSubsystemPersistenceBackend_acquire(0,&b,&digest,6);NEED(busy.status==0 && (busy.flags&R4SDKSUBSYSTEM_NATIVE_ERROR) && busy.length==4 && !bytes_compare(busy.ptr,"Busy",4),115);
    NEED(OK(R4SdkSubsystemPersistenceBackend_writeAtomic(0,&a,&digest,R4SdkSubsystemPersistenceFileKind_sram,(const uint8_t*)"S65!",4)),116);
    uint8_t bytes[4];NEED(R4SdkSubsystemPersistenceBackend_readExact(0,&a,&digest,R4SdkSubsystemPersistenceFileKind_sram,bytes,4).bits==R4SdkSubsystemPersistenceReadResult_ok && !bytes_compare(bytes,"S65!",4),117);
    S stale=R4SdkSubsystemPersistenceBackend_release(0,&a,&digest,6);NEED(stale.status==0 && (stale.flags&R4SDKSUBSYSTEM_NATIVE_ERROR),118);
    NEED(OK(R4SdkSubsystemPersistenceBackend_release(0,&a,&digest,5)),119);
    NEED(OK(R4SdkSubsystemPersistenceBackend_acquire(0,&b,&digest,6)),120);
    NEED(R4SdkSubsystemPersistenceBackend_readExact(0,&b,&digest,R4SdkSubsystemPersistenceFileKind_sram,bytes,4).bits==R4SdkSubsystemPersistenceReadResult_ok && !bytes_compare(bytes,"S65!",4),121);
    NEED(OK(R4SdkSubsystemPersistenceBackend_release(0,&b,&digest,6)),122);
    NEED(OK(R4SdkSubsystemStore_removeTestFiles(0,&second,&digest)),123);
    /* The original async store copies immutable work, joins its real app
       worker and only then retires the exact cartridge generation. */
    uint8_t arena_memory[8192];R4SdkDataArena arena;R4SdkDataAllocator allocator;
    NEED(R4SdkData_arena(0,&arena,arena_memory,sizeof(arena_memory)).status==0,132);
    NEED(R4SdkData_allocator(0,&arena,&allocator).status==0,133);
    R4SdkSubsystemAsyncStore async;R4SdkSubsystemPersistenceBackend async_backend;R4SdkSubsystemAsyncStats async_stats;
    NEED(OK(R4SdkSubsystemAsyncStore_init(0,&files,&allocator,&config,&async)),134);
    NEED(OK(R4SdkSubsystemAsyncStore_backend(0,&async,&async_backend)),135);
    NEED(OK(R4SdkSubsystemPersistenceBackend_acquire(0,&async_backend,&digest,7)),136);
    NEED(OK(R4SdkSubsystemPersistenceBackend_writeAtomic(0,&async_backend,&digest,R4SdkSubsystemPersistenceFileKind_sram,(const uint8_t*)"S65!",4)),137);
    NEED(OK(R4SdkSubsystemPersistenceBackend_drain(0,&async_backend)),138);
    NEED(R4SdkSubsystemPersistenceBackend_pending(0,&async_backend).bits==0,139);
    NEED(R4SdkSubsystemPersistenceBackend_readExact(0,&async_backend,&digest,R4SdkSubsystemPersistenceFileKind_sram,bytes,4).bits==R4SdkSubsystemPersistenceReadResult_ok && !bytes_compare(bytes,"S65!",4),140);
    NEED(OK(R4SdkSubsystemPersistenceBackend_release(0,&async_backend,&digest,7)),141);
    NEED(OK(R4SdkSubsystemAsyncStore_get_stats(&async,&async_stats)),142);
    NEED(R4SdkSubsystemAsyncStats_get_enqueued(&async_stats).bits==1 && R4SdkSubsystemAsyncStats_get_started(&async_stats).bits==1 && R4SdkSubsystemAsyncStats_get_completed(&async_stats).bits==1,143);
    NEED(OK(R4SdkSubsystemAsyncStore_removeTestFiles(0,&async,&digest)),144);
    /* Actual window output through the original current copy/stream backend.
       Shared ownership/backpressure is separately covered by original owners. */
    R4App2 actual;R4App app;NEED(sdk_guest_app2(start,&actual,&app)==0,124);R4Desk desk=app.desktop;R4Sys sys=app.system;
    R4GuiWindowInfo info={0};int ready=0;
    for(unsigned i=0;i<100;i++){if(r4desk_gui_window_info(&desk,&info)>=0 && info.client_w>0 && info.client_h>0 && info.window_id>=0){ready=1;break;}r4sys_sleep_ticks(&sys,1);}
    NEED(ready,125);r4desk_gui_set_title(&desk,"SDK65 synthetic subsystem");
    static uint32_t scratch[128*128];uint32_t pixels[6]={1,2,3,4,5,6};
    R4SdkSubsystemVideoBackend backend;R4SdkSubsystemVideoSurface surface;R4SdkSubsystemVideoPresenter presenter;R4SdkSubsystemVideoPresentResult result;
    NEED(OK(R4SdkSubsystem_drawBackend(0,&context,&backend)),126);
    NEED(OK(R4SdkSubsystemVideoBackend_set_supports_shared_raster(&backend,0)),127);
    NEED(OK(R4SdkSubsystemVideoSurface_initXrgb32(0,pixels,6,3,2,&surface)),128);
    NEED(OK(R4SdkSubsystemVideoPresenter_init(0,&surface,scratch,128*128,&presenter)),129);
    S presented=R4SdkSubsystemVideoPresenter_presentTo(0,&presenter,&backend,info.client_w,info.client_h,&result);NEED(OK(presented) && R4SdkSubsystemVideoPresentResult_inspectNative(&result).bits==R4SdkSubsystemVideoPresentResult_TAG_presented,130);
    NEED(OK(R4SdkSubsystemVideoPresenter_deinit(0,&presenter,&backend)),131);
    return 0;
}

void sdk65_fixture_host_state(void *p,uint64_t state){((Model*)p)->host_state=state;}
typedef struct AudioModel {Model model;uint64_t opens,writes,closes;} AudioModel;
static S audio_dispatch(void *p,uint32_t kind,const S *a,uint32_t count,void *output) {
    AudioModel *m=p;S v={.flags=P};
    if(kind==K(guest_audio)){bytes_fill(a[1].ptr,0x22,(size_t)a[1].length);v.bits=a[1].length;return v;}
    if(kind==K(audio_open)){m->opens++;return v;}
    if(kind==K(audio_write)){m->writes++;v.bits=(uint64_t)(int64_t)-77;return v;}
    if(kind==K(audio_volume))return v;
    if(kind==K(audio_close)){m->closes++;return v;}
    return sdk65_fixture_dispatch(p,kind,a,count,output);
}
int sdk65_c_audio(uint64_t *out) {
    AudioModel m={0};R4SdkSubsystemCallbackTable t;
    S user={.ptr=&m,.flags=P},fn={.ptr=(void*)(uintptr_t)&audio_dispatch,.flags=P};
    NEED(OK(R4SdkSubsystemCallbackTable_from_fields(&t,user,sdk65_fixture_mask()|BIT(audio_open)|BIT(audio_write)|BIT(audio_volume)|BIT(audio_close),fn)),1);
    R4SdkSubsystemRuntimeGuestDriver guest;R4SdkSubsystemRuntimeHostDriver host;R4SdkSubsystemRuntimeAudioSink sink;
    NEED(OK(R4SdkSubsystem_guestDriver(0,&t,&guest)),2);NEED(OK(R4SdkSubsystem_hostDriver(0,&t,&host)),3);NEED(OK(R4SdkSubsystem_audioSink(0,&t,&sink)),4);
    R4SdkSubsystemRuntimeAudioConfig audio_config;R4SdkSubsystemRuntimeAudioOptions options;uint8_t queue[16],scratch[8];
    NEED(OK(R4SdkSubsystemRuntimeAudioConfig_from_fields(&audio_config,1000,1,65536,4,2,2,10000000,0,960,1920)),5);
    NEED(OK(R4SdkSubsystemRuntimeAudioOptions_from_fields(&options,&audio_config,queue,sizeof(queue),scratch,sizeof(scratch),(S){.ptr=&sink,.flags=P})),6);
    R4SdkSubsystemRuntimeConfig config;R4SdkSubsystemRuntimeRuntime rt;R4SdkSubsystemRuntimeCycleResult cycle;
    NEED(OK(R4SdkSubsystemRuntimeConfig_from_fields(&config,4,4,8,1)),7);
    NEED(OK(R4SdkSubsystemRuntimeRuntime_init(0,&config,1000,0,(S){.ptr=&options,.flags=P},&rt)),8);
    for(uint64_t tick=10;tick<=30;tick+=10)NEED(OK(R4SdkSubsystemRuntimeRuntime_cycle(0,&rt,tick,&guest,&host,&cycle)),9);
    R4SdkSubsystemRuntimeAudioPump pump;NEED(OK(R4SdkSubsystemRuntimeRuntime_get_audio(&rt,&pump)),10);
    NEED(R4SdkSubsystemRuntimeAudioPump_get_state(&pump).bits==R4SdkSubsystemRuntimeAudioState_degraded,11);
    NEED((int32_t)R4SdkSubsystemRuntimeAudioPump_get_last_error(&pump).bits==-77,12);
    NEED(m.model.steps==3 && m.model.guest_ns==20000000 && !m.model.fault,13);
    NEED(OK(R4SdkSubsystemRuntimeRuntime_request(0,&rt,8,40,&guest)),14);
    NEED(OK(R4SdkSubsystemRuntimeRuntime_cycle(0,&rt,40,&guest,&host,&cycle)),15);
    NEED(OK(R4SdkSubsystemRuntimeRuntime_shutdown(0,&rt)),16);
    NEED(m.opens==1 && m.writes==1 && m.closes==1,17);
    out[0]=m.model.steps;out[1]=m.model.guest_ns;out[2]=m.opens;out[3]=m.writes;out[4]=m.closes;return 0;
}
int sdk65_guest_source(const R4XStartContext2 *start) {
    R4App2 actual;R4App app;NEED(sdk_guest_app2(start,&actual,&app)==0,151);R4Sys sys=app.system;R4Files files={.system=&sys};R4FilePath path;
    const char name[]="C:\\TEMP\\SYNTH65.S65";NEED(r4_file_path((const uint8_t*)name,sizeof(name)-1,&path)==R4_PATH_OK,152);
    uint8_t source[4];R4Transfer transfer=r4_files_read(&files,&path,source,sizeof(source));
    NEED(transfer.state==R4_TRANSFER_BYTES && transfer.bytes==4 && !bytes_compare(source,"S65!",4),153);return 0;
}
typedef struct ActualCatalog {R4Files files;uint32_t verified;} ActualCatalog;
static S verify_installed_host(void *p,uint32_t kind,const S *args,uint32_t count,void *output) {
    (void)output;ActualCatalog *model=p;S result={.flags=P,.bits=R4SdkSubsystemCatalogHostState_failed};
    if(kind!=K(verify_host)||count!=2||args[1].length>250||!args[1].length||!args[1].ptr)return result;
    char target[256];target[0]='C';target[1]=':';const uint8_t *raw=args[1].ptr;
    for(uintptr_t i=0;i<args[1].length;i++)target[i+2]=(char)raw[i];target[args[1].length+2]=0;
    R4FilePath path;if(r4_file_path((const uint8_t*)target,args[1].length+2,&path)!=R4_PATH_OK)return result;
    R4FileInfoRead info=r4_files_info(&model->files,&path);
    result.bits=info.state==R4_FILE_INFO_MISSING?R4SdkSubsystemCatalogHostState_missing:info.state==R4_FILE_INFO_VALUE&&!info.value.is_dir?R4SdkSubsystemCatalogHostState_present:R4SdkSubsystemCatalogHostState_failed;
    if(result.bits==R4SdkSubsystemCatalogHostState_present)model->verified++;return result;
}
int sdk65_guest_catalogue(const R4XStartContext2 *start,const char *expected_id) {
    R4App2 actual;R4App app;NEED(sdk_guest_app2(start,&actual,&app)==0,161);R4Sys sys=app.system;ActualCatalog model={.files={.system=&sys}};
    R4FilePath path;const char name[]="C:\\R4OS\\CONFIG\\MODULES.JSON";NEED(r4_file_path((const uint8_t*)name,sizeof(name)-1,&path)==R4_PATH_OK,162);
    static uint8_t bytes[256*1024];static R4SdkUpdateInventoryInventory inventory;static R4SdkSubsystemCatalogCatalog catalog;
    R4Transfer read=r4_files_read(&model.files,&path,bytes,sizeof(bytes));NEED(read.state==R4_TRANSFER_BYTES && read.bytes<sizeof(bytes),163);
    R4SdkSubsystemCallbackTable table;S user={.ptr=&model,.flags=P},fn={.ptr=(void*)(uintptr_t)&verify_installed_host,.flags=P};
    NEED(OK(R4SdkSubsystemCallbackTable_from_fields(&table,user,BIT(verify_host),fn)),164);
    R4SdkSubsystemCatalogHostVerifier verifier;NEED(OK(R4SdkSubsystem_hostVerifier(0,&table,&verifier)),165);
    NEED(OK(R4SdkSubsystemCatalogCatalog_loadInstalled(0,bytes,read.bytes,&inventory,&catalog,&verifier)),166);
    NEED(model.verified==R4SdkSubsystemCatalogCatalog_get_count(&catalog).bits && model.verified>=3,167);
    R4SdkSubsystemCatalogAssociation association;const char format[]="test.synthetic";const char guest[]="C:\\TEMP\\SYNTH65.S65";
    NEED(OK(R4SdkSubsystemCatalogAssociation_create(&association,(const uint8_t*)".s65",4,(const uint8_t*)expected_id,r4os_cstr_len(expected_id),(const uint8_t*)format,sizeof(format)-1)),168);
    R4SdkSubsystemCatalogPolicy policy;NEED(OK(R4SdkSubsystemCatalogPolicy_from_fields(&policy,&association,1,0,0)),169);
    R4SdkSubsystemCatalogInput input;NEED(OK(R4SdkSubsystemCatalogInput_create(&input,(const uint8_t*)guest,sizeof(guest)-1,(const uint8_t*)"S65!",4,4,1)),170);
    static R4SdkSubsystemCatalogResolution resolution;NEED(OK(R4SdkSubsystemCatalog_resolve(0,&catalog,&input,&policy,&resolution)),171);
    R4SdkSubsystemCatalogCandidate candidate;S selected=R4SdkSubsystemCatalogResolution_selected(0,&resolution,&candidate);NEED(OK(selected)&&(selected.flags&P),172);
    S id=R4SdkSubsystemCatalogCandidate_get_subsystem_id(&candidate);NEED(id.length==r4os_cstr_len(expected_id)&&!bytes_compare(id.ptr,expected_id,id.length),173);
    S host=R4SdkSubsystemCatalogCandidate_get_host_path(&candidate);NEED(host.length>0 && host.ptr!=0,174);
    r4sys_write_line(&sys,"SDK65 CATALOG source=MODULES.JSON verified=1 format=test.synthetic");return 0;
}

static void report_text(char *out,unsigned *used,const char *value){while(*value)out[(*used)++]=*value++;}
static void report_number(char *out,unsigned *used,uint64_t value){char digits[32];unsigned i=sizeof(digits);do{digits[--i]=(char)('0'+value%10);value/=10;}while(value);for(;i<sizeof(digits);i++)out[(*used)++]=digits[i];}
int sdk65_guest_report(const R4XStartContext2 *start,char language,int code){
    R4App2 actual;R4App app;if(sdk_guest_app2(start,&actual,&app)!=0)return 198;R4Sys sys=app.system;R4Files files={.system=&sys};
    char path_text[]="C:\\TEMP\\S65C.OUT";path_text[11]=language;
    R4FilePath path;if(r4_file_path((const uint8_t*)path_text,sizeof(path_text)-1,&path)!=R4_PATH_OK)return 197;
    char out[512];unsigned used=0;report_text(out,&used,"CODE=");report_number(out,&used,(uint32_t)code);report_text(out,&used,"\nWORK=");
    for(unsigned i=0;i<6;i++){if(i)report_text(out,&used,",");report_number(out,&used,last_work[i]);}
    report_text(out,&used,"\nVIDEO=");report_number(out,&used,last_video);report_text(out,&used,"\n");
    R4Transfer wrote=r4_files_write(&files,&path,(const uint8_t*)out,used);if(wrote.state!=R4_TRANSFER_BYTES||wrote.bytes!=used)return 196;return code;
}
#include "PublishedFrameParity.c"
