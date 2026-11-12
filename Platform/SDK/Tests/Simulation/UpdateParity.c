/* Original replay/archive cores; reusable in native and private R4X tests. */
#include <r4os/facades.h>
#define B(s) (const uint8_t *)(s),sizeof(s)-1
#define CHECK(v) do{if(!(v))return __LINE__;}while(0)
static int ok(R4SdkUpdateSlot v){return !v.status&&!(v.flags&2);}
#define TRY(v) CHECK(ok(v))
static int eq(const void *a,const void *b,uintptr_t n){for(uintptr_t i=0;i<n;i++)if(((const uint8_t *)a)[i]!=((const uint8_t *)b)[i])return 0;return 1;}
static int name(R4SdkUpdateSlot v,const char *s,uintptr_t n){return !v.status&&(v.flags&2)&&v.length==n&&v.ptr&&eq(v.ptr,s,n);}
typedef struct Model{
    R4Sys *sys;R4Files files;int real;
    uint8_t *durable;uintptr_t capacity,length;uint8_t slot;
    uint32_t persist,fail_persist,commits,mutations,rollbacks,cleanups;int fail_cleanup;
    uint32_t archive_step,archive_fail;int original,copied;
    int target_new,backup_old;uint32_t old_sum,new_sum;
} Model;
static int path(R4FilePath *out,const char *text){return r4_file_path((const uint8_t *)text,r4os_cstr_len(text),out)==R4_PATH_OK;}
static int write(Model *m,const char *p,const uint8_t *bytes,uint32_t n){R4FilePath f;if(!path(&f,p))return 0;R4Transfer t=r4_files_write(&m->files,&f,bytes,n);return t.state==R4_TRANSFER_BYTES&&t.bytes==n;}
static int read(Model *m,const char *p,uint8_t *out,uint32_t n){R4FilePath f;if(!path(&f,p))return -1;R4Transfer t=r4_files_read(&m->files,&f,out,n);return t.state==R4_TRANSFER_BYTES?(int)t.bytes:-1;}
static int absent(Model *m,const char *p){R4FilePath f;if(!path(&f,p))return 0;return r4_files_info(&m->files,&f).state==R4_FILE_INFO_MISSING;}
static R4SdkUpdateSlot value(uint64_t n){return (R4SdkUpdateSlot){.bits=n,.flags=1};}
static R4SdkUpdateSlot invoke(void *user,uint32_t kind,const R4SdkUpdateSlot *a,uint32_t count,void *out){
    (void)out;Model *m=(Model *)user;if(!count||a[0].ptr!=m)return (R4SdkUpdateSlot){.status=-64};
    if(kind>=R4SdkUpdateCallbackKind_archive_unreferenced){
        m->archive_step++;if(m->archive_step==m->archive_fail)return value(0);
        if(kind==R4SdkUpdateCallbackKind_archive_copy)m->copied=1;
        if(kind==R4SdkUpdateCallbackKind_archive_verify)return value(m->original&&m->copied);
        if(kind==R4SdkUpdateCallbackKind_archive_remove){if(!m->copied)return value(0);m->original=0;}
        return value(1);
    }
    if(kind==R4SdkUpdateCallbackKind_journal_persist){
        R4SdkUpdateRecoveryTransactionJournal *j=(R4SdkUpdateRecoveryTransactionJournal *)a[1].ptr;
        m->persist++;if(m->persist==m->fail_persist)return value(0);
        if(R4SdkUpdateRecoveryTransactionJournal_get_transaction_generation(j).bits!=5)return value(0);
        uint64_t old=R4SdkUpdateRecoveryTransactionJournal_get_journal_generation(j).bits;
        uint8_t slot=(uint8_t)(1-R4SdkUpdateRecoveryTransactionJournal_get_slot(j).bits);
        if(!ok(R4SdkUpdateRecoveryTransactionJournal_set_journal_generation(j,old+1))||!ok(R4SdkUpdateRecoveryTransactionJournal_set_slot(j,slot)))return value(0);
        R4SdkUpdateSlot text=R4SdkUpdateRecovery_serializeJournal(0,j,m->durable,m->capacity);
        if(!ok(text)||!(text.flags&1))return value(0);m->length=text.length;m->slot=slot;
        if(m->real){
            const char *p=slot?"C:\\TEMP\\U64B.JNL":"C:\\TEMP\\U64A.JNL";uint8_t check[8192];
            if(text.length>sizeof(check)||!write(m,p,text.ptr,(uint32_t)text.length)||read(m,p,check,(uint32_t)text.length)!=(int)text.length||!eq(check,text.ptr,text.length))return value(0);
        }
        return value(1);
    }
    if(kind==R4SdkUpdateCallbackKind_payload_cleanup){m->cleanups++;return value(m->fail_cleanup?R4SdkUpdateRecoveryMutationStatus_io:R4SdkUpdateRecoveryMutationStatus_ok);}
    if(kind==R4SdkUpdateCallbackKind_payload_commit||kind==R4SdkUpdateCallbackKind_payload_rollback){
        const R4SdkUpdateRecoveryJournalPayload *p=(const R4SdkUpdateRecoveryJournalPayload *)a[1].ptr;
        if(R4SdkUpdateRecoveryJournalPayload_get_size(p).bits!=3||R4SdkUpdateRecoveryJournalPayload_get_checksum(p).bits!=m->new_sum||R4SdkUpdateRecoveryJournalPayload_get_old_size(p).bits!=3||R4SdkUpdateRecoveryJournalPayload_get_old_checksum(p).bits!=m->old_sum)return value(R4SdkUpdateRecoveryMutationStatus_conflict);
        int forward=kind==R4SdkUpdateCallbackKind_payload_commit;if(forward)m->commits++;else m->rollbacks++;
        if(m->real){
            const char *target=(const char *)R4SdkUpdateRecoveryJournalPayload_targetPtr(0,p).ptr;
            const char *stage=(const char *)R4SdkUpdateRecoveryJournalPayload_stagePtr(0,p).ptr;
            const char *backup=(const char *)R4SdkUpdateRecoveryJournalPayload_backupPtr(0,p).ptr;
            uint32_t flags=(forward?R4SYS_FILE_UPDATE_ATOMIC_CHECKED_FORWARD:R4SYS_FILE_UPDATE_ATOMIC_CHECKED_ROLLBACK)|R4SYS_FILE_UPDATE_ATOMIC_CHECKED_TARGET_EXISTED|R4SYS_FILE_UPDATE_ATOMIC_CHECKED_OLD_KNOWN;
            int32_t code=r4sys_file_update_atomic_checked(m->sys,target,stage,backup,3,m->new_sum,3,m->old_sum,flags);
            return value(code==0?R4SdkUpdateRecoveryMutationStatus_ok:code==R4SYS_FILE_UPDATE_ATOMIC_CHECKED_ERROR_IO?R4SdkUpdateRecoveryMutationStatus_io:R4SdkUpdateRecoveryMutationStatus_conflict);
        }
        if(forward){if(!m->target_new){m->target_new=1;m->backup_old=1;m->mutations++;}}
        else {if(m->target_new&&m->backup_old){m->target_new=0;m->backup_old=0;m->mutations++;}}
        return value(R4SdkUpdateRecoveryMutationStatus_ok);
    }
    if(kind==R4SdkUpdateCallbackKind_path_state){
        if(m->real){R4FilePath f;if(!path(&f,(const char *)a[1].ptr))return value(R4SdkUpdateRecoveryPathState_io);R4FileInfoRead info=r4_files_info(&m->files,&f);if(info.state==R4_FILE_INFO_MISSING)return value(R4SdkUpdateRecoveryPathState_not_found);if(info.state!=R4_FILE_INFO_VALUE)return value(R4SdkUpdateRecoveryPathState_io);uint8_t bytes[16];int n=read(m,(const char *)a[1].ptr,bytes,sizeof(bytes));if(n<0)return value(R4SdkUpdateRecoveryPathState_io);return value((uint64_t)n==a[2].bits&&R4SdkUpdateRecovery_checksum(0,bytes,(uintptr_t)n).bits==a[3].bits?R4SdkUpdateRecoveryPathState_match:R4SdkUpdateRecoveryPathState_other);}
        return value((a[3].bits==m->new_sum&&m->target_new)||(a[3].bits==m->old_sum&&m->backup_old)?R4SdkUpdateRecoveryPathState_match:R4SdkUpdateRecoveryPathState_other);
    }
    if(kind==R4SdkUpdateCallbackKind_path_presence){if(m->real){R4FilePath f;if(!path(&f,(const char *)a[1].ptr))return value(R4SdkUpdateRecoveryPresenceState_io);R4FileInfoRead info=r4_files_info(&m->files,&f);return value(info.state==R4_FILE_INFO_MISSING?R4SdkUpdateRecoveryPresenceState_not_found:info.state==R4_FILE_INFO_VALUE?(info.value.is_dir?R4SdkUpdateRecoveryPresenceState_other:R4SdkUpdateRecoveryPresenceState_file):R4SdkUpdateRecoveryPresenceState_io);}return value(R4SdkUpdateRecoveryPresenceState_not_found);}
    return (R4SdkUpdateSlot){.status=-65};
}
static int table(R4SdkUpdateCallbackTable *out,Model *m,uint64_t mask){return ok(R4SdkUpdateCallbackTable_from_fields(out,(R4SdkUpdateSlot){.ptr=m,.flags=1},mask,(R4SdkUpdateSlot){.ptr=(void *)(uintptr_t)&invoke,.flags=1}));}
int sdk_update_journal_case(const R4XStartContext *start,R4SdkUpdateRecoveryTransactionJournal *first,R4SdkUpdateRecoveryTransactionJournal *second,const uint8_t *input,uintptr_t length,uint8_t *durable,uintptr_t capacity){
    Model m={.durable=durable,.capacity=capacity,.fail_persist=2,.old_sum=(uint32_t)R4SdkUpdateRecovery_checksum(0,B("old")).bits,.new_sum=(uint32_t)R4SdkUpdateRecovery_checksum(0,B("new")).bits};
    R4Sys sys;R4App app;
    CHECK(R4SdkUpdateRecovery_parseJournalInto(0,input,length,0,first).bits==1);
    if(start){
        CHECK(r4sys_init(start,&sys)==0&&R4SdkAppFacade(start,&app)==0);m.sys=&sys;m.files=r4_app_files(&app);m.real=1;
        CHECK(absent(&m,"C:\\TEMP\\SDK64.R4X")&&absent(&m,"C:\\TEMP\\S715609D.R4U")&&absent(&m,"C:\\TEMP\\B715609D.R4U"));
        CHECK(write(&m,"C:\\TEMP\\SDK64.R4X",B("bad"))&&write(&m,"C:\\TEMP\\S715609D.R4U",B("new")));
        CHECK(r4sys_file_update_atomic_checked(m.sys,"C:\\TEMP\\SDK64.R4X","C:\\TEMP\\S715609D.R4U","C:\\TEMP\\B715609D.R4U",3,m.new_sum,3,m.old_sum,R4SYS_FILE_UPDATE_ATOMIC_CHECKED_FORWARD|R4SYS_FILE_UPDATE_ATOMIC_CHECKED_TARGET_EXISTED|R4SYS_FILE_UPDATE_ATOMIC_CHECKED_OLD_KNOWN)==R4SYS_FILE_UPDATE_ATOMIC_CHECKED_ERROR_CONFLICT);
        uint8_t unchanged[3];CHECK(read(&m,"C:\\TEMP\\SDK64.R4X",unchanged,3)==3&&eq(unchanged,"bad",3)&&absent(&m,"C:\\TEMP\\B715609D.R4U"));
        CHECK(write(&m,"C:\\TEMP\\SDK64.R4X",B("old")));
    }
    uint64_t mask=(UINT64_C(1)<<R4SdkUpdateCallbackKind_journal_persist)|(UINT64_C(1)<<R4SdkUpdateCallbackKind_payload_commit)|(UINT64_C(1)<<R4SdkUpdateCallbackKind_payload_rollback)|(UINT64_C(1)<<R4SdkUpdateCallbackKind_path_state)|(UINT64_C(1)<<R4SdkUpdateCallbackKind_path_presence);
    R4SdkUpdateCallbackTable cb;CHECK(table(&cb,&m,mask));
    R4SdkUpdateSlot result=R4SdkUpdate_resumeBatchForward(0,&cb,first);CHECK(ok(result)&&result.bits==R4SdkUpdateRecoveryReplayStatus_io&&m.commits==1&&m.length>0);
    CHECK(R4SdkUpdateRecovery_parseJournalInto(0,durable,m.length,m.slot,second).bits==1);
    m.fail_persist=0;result=R4SdkUpdate_resumeBatchForward(0,&cb,second);CHECK(ok(result)&&result.bits==R4SdkUpdateRecoveryReplayStatus_ok&&m.commits==2);
    CHECK(R4SdkUpdateRecoveryTransactionJournal_get_phase(second).bits==R4SdkUpdateRecoveryJournalPhase_post_boot);
    CHECK(R4SdkUpdate_checkLastGood(0,&cb,second).bits==R4SdkUpdateRecoveryReplayStatus_ok);
    result=R4SdkUpdate_rollbackToTerminal(0,&cb,second);CHECK(ok(result)&&result.bits==R4SdkUpdateRecoveryReplayStatus_ok&&m.rollbacks==1);
    CHECK(R4SdkUpdate_rollbackToTerminal(0,&cb,second).bits==R4SdkUpdateRecoveryReplayStatus_ok&&m.rollbacks==1);
    if(m.real){uint8_t bytes[3];CHECK(read(&m,"C:\\TEMP\\SDK64.R4X",bytes,3)==3&&eq(bytes,"old",3));R4FilePath p;CHECK(path(&p,"C:\\TEMP\\SDK64.R4X"));CHECK(r4_files_delete(&m.files,&p).state==R4_OPERATION_OK);for(int i=0;i<2;i++){CHECK(path(&p,i?"C:\\TEMP\\U64B.JNL":"C:\\TEMP\\U64A.JNL"));(void)r4_files_delete(&m.files,&p);}}
    else CHECK(m.mutations==2&&!m.target_new&&!m.backup_old);
    return 0;
}
static uint32_t scope_calls;
static int32_t scope_probe(const uint8_t *p){scope_calls++;return p&&p[0]=='D'?1:0;}
int sdk_update_archive_case(void){
    uint8_t target[128];
    R4SdkUpdateSlot observed=R4SdkUpdateNative_r4u_manifest_canonicalInventoryTarget(0,target,sizeof(target),B("d:\\Apps\\Gr\xc3\xbc\xc3\x9f" "e\\APP.R4X"));
    CHECK(!observed.status&&(observed.flags&1)&&observed.length==sizeof("D:/Apps/Gr\xc3\xbc\xc3\x9f" "e/APP.R4X")-1&&eq(observed.ptr,"D:/Apps/Gr\xc3\xbc\xc3\x9f" "e/APP.R4X",observed.length));
    R4XStartR4Sys scope_table={.size=offsetof(R4XStartR4Sys,system_update_target_supported),.system_update_target_supported=(uintptr_t)&scope_probe};
    R4Sys scope={.table=&scope_table};scope_calls=0;
    CHECK(r4sys_system_update_target_supported(&scope,"D:\\APP.R4X")==R4OS_ERR_NO_FN&&scope_calls==0);
    scope_table.size=sizeof(scope_table);
    CHECK(r4sys_system_update_target_supported(&scope,"D:\\APP.R4X")==1&&scope_calls==1);
    CHECK(r4sys_system_update_target_supported(&scope,0)==R4OS_ERROR_INVALID&&scope_calls==1);
    scope_table.system_update_target_supported=0;
    CHECK(r4sys_system_update_target_supported(&scope,"D:\\APP.R4X")==R4OS_ERR_NO_FN&&scope_calls==1);
    const char *names[]={"Referenced","Copy","Verification","Referenced","Verification","Remove"};const uintptr_t sizes[]={10,4,12,10,12,6};
    uint64_t mask=(UINT64_C(1)<<R4SdkUpdateCallbackKind_archive_unreferenced)|(UINT64_C(1)<<R4SdkUpdateCallbackKind_archive_copy)|(UINT64_C(1)<<R4SdkUpdateCallbackKind_archive_verify)|(UINT64_C(1)<<R4SdkUpdateCallbackKind_archive_remove);
    for(uint32_t fail=1;fail<=6;fail++){Model m={.original=1,.archive_fail=fail};R4SdkUpdateCallbackTable cb;CHECK(table(&cb,&m,mask));R4SdkUpdateSlot r=R4SdkUpdate_archive(0,&cb);CHECK(name(r,names[fail-1],sizes[fail-1])&&m.original&&m.archive_step==fail);}
    Model m={.original=1};R4SdkUpdateCallbackTable cb;CHECK(table(&cb,&m,mask));TRY(R4SdkUpdate_archive(0,&cb));CHECK(!m.original&&m.copied&&m.archive_step==6);
    CHECK(table(&cb,&m,0));CHECK(name(R4SdkUpdate_archive(0,&cb),"MissingCallback",15));return 0;
}
typedef struct IoModel{uint8_t bytes[1024];uint32_t reads,writes,flushes;int keep,fail_write,fail_source;}IoModel;
static R4SdkUpdateSlot io_invoke(void *user,uint32_t kind,const R4SdkUpdateSlot *a,uint32_t n,void *out){
    (void)out;IoModel *s=(IoModel *)user;if(!n||a[0].ptr!=s)return (R4SdkUpdateSlot){.status=-66};
    if(kind==R4SdkUpdateCallbackKind_block_continue)return value(s->keep!=0);
    if(kind==R4SdkUpdateCallbackKind_block_flush){s->flushes++;return value(0);}
    if(kind==R4SdkUpdateCallbackKind_source_read&&s->fail_source)return (R4SdkUpdateSlot){.ptr=(void *)"SourceRead",.length=10,.flags=2};
    if(n!=3)return (R4SdkUpdateSlot){.status=-67};
    uint64_t offset=a[1].bits*(kind==R4SdkUpdateCallbackKind_source_read?1:512);
    if(offset>sizeof(s->bytes)||a[2].length>sizeof(s->bytes)-offset)return value((uint64_t)(int64_t)-70);
    if(kind==R4SdkUpdateCallbackKind_block_write){s->writes++;if(s->fail_write)return value((uint64_t)(int64_t)-71);for(uintptr_t i=0;i<a[2].length;i++)s->bytes[offset+i]=((uint8_t *)a[2].ptr)[i];}
    else {s->reads++;for(uintptr_t i=0;i<a[2].length;i++)((uint8_t *)a[2].ptr)[i]=s->bytes[offset+i];}
    return kind==R4SdkUpdateCallbackKind_source_read?(R4SdkUpdateSlot){0}:value(0);
}
int sdk_update_io_callbacks_case(void){
    IoModel s={.keep=1};R4SdkUpdateCallbackTable cb;uint64_t mask=(UINT64_C(1)<<R4SdkUpdateCallbackKind_block_read)|(UINT64_C(1)<<R4SdkUpdateCallbackKind_block_write)|(UINT64_C(1)<<R4SdkUpdateCallbackKind_block_flush)|(UINT64_C(1)<<R4SdkUpdateCallbackKind_block_continue)|(UINT64_C(1)<<R4SdkUpdateCallbackKind_source_read);
    TRY(R4SdkUpdateCallbackTable_from_fields(&cb,(R4SdkUpdateSlot){.ptr=&s,.flags=1},mask,(R4SdkUpdateSlot){.ptr=(void *)(uintptr_t)&io_invoke,.flags=1}));
    R4SdkUpdateBlockProgress progress;TRY(R4SdkUpdateBlockProgress_create(&progress));R4SdkUpdateBlockDevice device;TRY(R4SdkUpdate_device(0,&cb,2,0,(R4SdkUpdateSlot){.ptr=&progress,.flags=1},&device));
    uint8_t input[512],output[512];for(uintptr_t i=0;i<512;i++)input[i]=(uint8_t)i;
    CHECK(name(R4SdkUpdateBlockDevice_write(0,&device,0,input,512),"ExclusiveRequired",17)&&s.writes==0);
    TRY(R4SdkUpdateBlockDevice_set_exclusive(&device,1));TRY(R4SdkUpdateBlockDevice_write(0,&device,0,input,512));TRY(R4SdkUpdateBlockDevice_read(0,&device,0,output,512));TRY(R4SdkUpdateBlockDevice_flush(0,&device));CHECK(eq(input,output,512)&&s.reads==1&&s.writes==1&&s.flushes==1);
    s.fail_write=1;CHECK(name(R4SdkUpdateBlockDevice_write(0,&device,1,input,512),"WriteFailed",11));CHECK((int32_t)R4SdkUpdateBlockProgress_get_native_error(&progress).bits==-71);s.fail_write=0;s.keep=0;CHECK(name(R4SdkUpdateBlockDevice_write(0,&device,1,input,512),"Cancelled",9)&&s.writes==2);
    R4SdkUpdateByteSource source;TRY(R4SdkUpdate_source(0,&cb,sizeof(s.bytes),&source));TRY(R4SdkUpdateByteSource_read(0,&source,3,output,7));CHECK(eq(output,input+3,7));s.fail_source=1;CHECK(name(R4SdkUpdateByteSource_read(0,&source,3,output,7),"SourceRead",10));return 0;
}

int sdk_update_cleanup_case(R4SdkUpdateRecoveryTransactionJournal *journal,const uint8_t *input,uintptr_t length,uint8_t *durable,uintptr_t capacity){
    Model m={.durable=durable,.capacity=capacity,.target_new=1,.backup_old=1,.fail_cleanup=1,.old_sum=(uint32_t)R4SdkUpdateRecovery_checksum(0,B("old")).bits,.new_sum=(uint32_t)R4SdkUpdateRecovery_checksum(0,B("new")).bits};
    CHECK(R4SdkUpdateRecovery_parseJournalInto(0,input,length,0,journal).bits==1);
    R4SdkUpdateCallbackTable cb;uint64_t mask=(UINT64_C(1)<<R4SdkUpdateCallbackKind_journal_persist)|(UINT64_C(1)<<R4SdkUpdateCallbackKind_payload_cleanup)|(UINT64_C(1)<<R4SdkUpdateCallbackKind_path_state)|(UINT64_C(1)<<R4SdkUpdateCallbackKind_path_presence);CHECK(table(&cb,&m,mask));
    R4SdkUpdateSlot r=R4SdkUpdate_cleanupToTerminal(0,&cb,journal);CHECK(ok(r)&&r.bits==R4SdkUpdateRecoveryReplayStatus_io&&m.persist==0&&m.target_new&&m.backup_old);
    m.fail_cleanup=0;r=R4SdkUpdate_cleanupToTerminal(0,&cb,journal);CHECK(ok(r)&&r.bits==R4SdkUpdateRecoveryReplayStatus_ok&&m.cleanups==2&&m.persist==1);
    CHECK(R4SdkUpdateRecoveryTransactionJournal_get_phase(journal).bits==R4SdkUpdateRecoveryJournalPhase_cleanup);CHECK(R4SdkUpdate_cleanupToTerminal(0,&cb,journal).bits==R4SdkUpdateRecoveryReplayStatus_ok&&m.cleanups==2);return 0;
}
