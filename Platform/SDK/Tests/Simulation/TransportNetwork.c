/* Controlled QEMU/SLIRP counterpart: TransportServer.py, port 18163. */
#include <r4os/facades.h>
#define B(s) (const uint8_t *)(s),sizeof(s)-1
#define URL(s) "http://10.0.2.2:18163" s
#define CHECK(v) do{if(!(v))return __LINE__;}while(0)
#define TRY(v) CHECK(valid(v))
#define WEB(v) CHECK(webvalid(v))
static int webvalid(R4SdkWebSlot v){return !v.status&&!(v.flags&2);}
static int valid(R4SdkTransportSlot v){return !v.status&&!(v.flags&2);}
static int bytes(R4SdkTransportSlot v,const char *s,uintptr_t n){
    if(!valid(v)||!(v.flags&1)||v.length!=n||(!v.ptr&&n))return 0;
    for(uintptr_t i=0;i<n;i++)if(((const uint8_t *)v.ptr)[i]!=(uint8_t)s[i])return 0;
    return 1;
}
static int suffix(R4SdkWebSlot v,const char *s,uintptr_t n){
    if(v.length<n)return 0;const uint8_t *p=(const uint8_t *)v.ptr+v.length-n;
    for(uintptr_t i=0;i<n;i++)if(p[i]!=(uint8_t)s[i])return 0;return 1;
}
typedef struct State{
    R4Sys *sys;uint32_t thread;uint32_t wrong_thread;
    uint32_t cookies,targets,lookups,writes;uint64_t next;
    R4SdkWebRuntimeWebRuntime *runtime;uint32_t generation;int retired;
    uint8_t *download;uintptr_t download_capacity;
} State;
static R4SdkWebSlot callback(void *user,uint32_t kind,const R4SdkWebSlot *a,uint32_t n,void *out){
    (void)out;State *s=(State *)user;R4SdkWebSlot yes={.bits=1,.flags=1};
    if(!n||a[0].ptr!=user)return (R4SdkWebSlot){.status=-63};
    if(r4sys_thread_current(s->sys)!=s->thread)s->wrong_thread++;
    switch(kind){
    case R4SdkWebCallbackKind_network_progress:return yes;
    case R4SdkWebCallbackKind_target_authorize:
        s->targets++;yes.bits=!suffix(a[1],"/forbidden",10);return yes;
    case R4SdkWebCallbackKind_cookie_provider:
        if(n!=3||a[2].length<9)return (R4SdkWebSlot){.status=-64};
        for(uintptr_t i=0;i<9;i++)((uint8_t *)a[2].ptr)[i]=(uint8_t)"token=one"[i];
        return (R4SdkWebSlot){.ptr=a[2].ptr,.length=9,.flags=1};
    case R4SdkWebCallbackKind_cookie_sink:
        if(n!=3||a[2].length!=27)return (R4SdkWebSlot){.status=-65};
        s->cookies++;return yes;
    case R4SdkWebCallbackKind_download_progress:return yes;
    case R4SdkWebCallbackKind_download_write:
        if(n!=3||a[1].bits!=s->next||a[2].length>s->download_capacity-s->next)return (R4SdkWebSlot){.flags=1};
        for(uintptr_t i=0;i<a[2].length;i++)if(((uint8_t *)a[2].ptr)[i]!=(uint8_t)((s->next+i)*17+3))return (R4SdkWebSlot){.flags=1};
        for(uintptr_t i=0;i<a[2].length;i++)s->download[s->next+i]=((uint8_t *)a[2].ptr)[i];
        /* The complete object remains owned by the caller after this receipt. */
        s->next+=a[2].length;s->writes++;return yes;
    case R4SdkWebCallbackKind_runtime_lookup:
        s->lookups++;if(s->retired||a[1].bits!=s->generation)return (R4SdkWebSlot){0};
        return (R4SdkWebSlot){.ptr=s->runtime,.flags=1};
    default:return (R4SdkWebSlot){.status=-66};
    }
}
static int table(R4SdkWebCallbackTable *out,State *s,uint64_t mask){
    return !R4SdkWebCallbackTable_from_fields(out,(R4SdkWebSlot){.ptr=s,.flags=1},mask,(R4SdkWebSlot){.ptr=(void *)(uintptr_t)&callback,.flags=1}).status;
}
static int response(R4SdkTransportFetchResult *r,R4SdkTransportFetchResponse *v){
    return valid(R4SdkTransportFetchResult_get_response(r,v));
}
static int failure(R4SdkTransportFetchResult *r,uint32_t code){
    return R4SdkTransportFetchResult_inspectNative(r).bits==R4SdkTransportFetchResult_TAG_failure&&R4SdkTransportFetchResult_get_failure(r).bits==code;
}
int sdk_transport_network_case(const R4XStartContext *start,uint8_t *scratch,uintptr_t capacity,uint8_t *download_bytes,uintptr_t download_capacity,uint32_t *tls_error){
    R4Sys sys;CHECK(r4sys_init(start,&sys)==0);State s={.sys=&sys,.thread=r4sys_thread_current(&sys),.download=download_bytes,.download_capacity=download_capacity};
    R4SdkTransportContext ctx;CHECK(R4SdkTransport_open(0,&ctx,start).bits==1);
    R4SdkTransportWebTransport *transport=(R4SdkTransportWebTransport *)R4SdkTransport_transport(0,&ctx).ptr;
    R4SdkWebCallbackTable cb;CHECK(table(&cb,&s,(UINT64_C(1)<<R4SdkWebCallbackKind_network_progress)|(UINT64_C(1)<<R4SdkWebCallbackKind_cookie_provider)|(UINT64_C(1)<<R4SdkWebCallbackKind_cookie_sink)|(UINT64_C(1)<<R4SdkWebCallbackKind_target_authorize)));
    R4SdkTransportFetchOptions options;TRY(R4SdkTransportFetchOptions_create(&options));TRY(R4SdkTransport_fetchCallbacks(0,&options,&cb));
    uint8_t raw[32768],body[8192];R4SdkTransportFetchResult result;R4SdkTransportFetchResponse value;
    TRY(R4SdkTransportWebTransport_fetch(0,transport,B(URL("/cookie")),raw,sizeof(raw),body,sizeof(body),scratch,capacity,&options,&result));
    CHECK(response(&result,&value)&&bytes(R4SdkTransportFetchResponse_get_body(&value),"token=one",9)&&s.cookies==1);
    TRY(R4SdkTransportWebTransport_fetch(0,transport,B(URL("/redirect-blocked")),raw,sizeof(raw),body,sizeof(body),scratch,capacity,&options,&result));
    CHECK(failure(&result,R4SdkTransportError_policy_rejected)&&s.targets>=3);
    R4SdkTransportJobsJob job;TRY(R4SdkTransport_job(0,&job,&ctx));
    CHECK(R4SdkTransportJobsJob_start(0,&job,B(URL("/cookie?job")),raw,sizeof(raw),body,sizeof(body),scratch,capacity,&options).bits==1);
    int joined=0;for(uint32_t i=0;i<1200;i++){if(R4SdkTransportJobsJob_collect(0,&job).bits){joined=1;break;}r4sys_sleep_ticks(&sys,1);}
    CHECK(joined);TRY(R4SdkTransportJobsJob_get_result(&job,&result));CHECK(response(&result,&value)&&bytes(R4SdkTransportFetchResponse_get_body(&value),"token=one",9)&&s.cookies==2&&!s.wrong_thread);
    TRY(R4SdkTransportJobsJob_deinit(0,&job));
    /* TLS is the original protocol call and original alert/error mapping. */
    TRY(R4SdkTransportWebTransport_fetch(0,transport,B("https://10.0.2.2:18163/tls"),raw,sizeof(raw),body,sizeof(body),scratch,capacity,&options,&result));
    CHECK(R4SdkTransportFetchResult_inspectNative(&result).bits==R4SdkTransportFetchResult_TAG_failure);
    *tls_error=(uint32_t)R4SdkTransportFetchResult_get_failure(&result).bits;
    CHECK(*tls_error==R4SdkTransportError_tls_alert_protocol_version);
    R4SdkTransportDownloadOptions download;R4SdkTransportDownloadSink sink;R4SdkTransportDownloadResult downloaded;R4SdkTransportDownloadResponse done;
    CHECK(table(&cb,&s,(UINT64_C(1)<<R4SdkWebCallbackKind_download_progress)|(UINT64_C(1)<<R4SdkWebCallbackKind_download_write)|(UINT64_C(1)<<R4SdkWebCallbackKind_target_authorize)));
    TRY(R4SdkTransportDownloadOptions_create(&download));TRY(R4SdkTransport_downloadCallbacks(0,&download,&cb));TRY(R4SdkTransport_sink(0,&cb,&sink));
    TRY(R4SdkTransportWebTransport_download(0,transport,B(URL("/range-cut")),raw,sizeof(raw),body,sizeof(body),scratch,capacity,&sink,&download,&downloaded));
    CHECK(R4SdkTransportDownloadResult_inspectNative(&downloaded).bits==R4SdkTransportDownloadResult_TAG_response);
    TRY(R4SdkTransportDownloadResult_get_response(&downloaded,&done));
    CHECK(R4SdkTransportDownloadResponse_get_total_size(&done).bits==200000&&R4SdkTransportDownloadResponse_get_transferred(&done).bits==200000&&s.next==200000&&s.writes>1&&!s.wrong_thread);
    for(uintptr_t i=0;i<200000;i++)CHECK(download_bytes[i]==(uint8_t)(i*17+3));
    return 0;
}
int sdk_transport_runtime_job_case(const R4XStartContext *start,R4SdkDataAllocator *allocator,R4SdkWebJsProgramAllocator *programs,R4SdkWebHtmlDocument *doc,R4SdkWebNative_web_security_BrowserStorage *storage,R4SdkWebRuntimeWebRuntime *runtime,R4SdkTransportRuntimeJobsRequestJob *job){
    R4Sys sys;CHECK(r4sys_init(start,&sys)==0);State s={.sys=&sys,.thread=r4sys_thread_current(&sys),.runtime=runtime,.generation=73};
    R4SdkTransportContext ctx;CHECK(R4SdkTransport_open(0,&ctx,start).bits==1);
    R4SdkWebCallbackTable cb;CHECK(table(&cb,&s,UINT64_C(1)<<R4SdkWebCallbackKind_runtime_lookup));
    R4SdkTransportRuntimeJobsOwner owner;TRY(R4SdkTransport_owner(0,&cb,&owner));TRY(R4SdkTransport_requestJob(0,job,&ctx,allocator,&owner));
    WEB(R4SdkWebRuntimeWebRuntime_initialize(0,runtime,programs));WEB(R4SdkWebNative_web_security_BrowserStorage_reset(0,storage));
    double now=0;WEB(R4SdkWebRuntimeWebRuntime_beginDocument(0,runtime,doc,storage,B(URL("/document")),B(""),73,&now));
    R4SdkWebJsValue value;WEB(R4SdkWebRuntimeWebRuntime_executeSource(0,runtime,B("fetch('/stall');"),&value));
    R4SdkWebSlot pending=R4SdkWebRuntimeWebRuntime_takeRequest(0,runtime);CHECK((pending.flags&1)&&pending.ptr);
    R4SdkWebRuntimePendingRequest *request=(R4SdkWebRuntimePendingRequest *)pending.ptr;
    uint32_t id=(uint32_t)R4SdkWebRuntimePendingRequest_get_id(request).bits;
    TRY(R4SdkTransportRuntimeJobsRequestJob_prepare(0,job,runtime,request,32768,8192));
    CHECK(R4SdkTransportRuntimeJobsRequestJob_activeRuntime(0,job).ptr==runtime&&R4SdkTransportRuntimeJobsRequestJob_get_memory(job).length>0);
    R4SdkTransportFetchOptions options;TRY(R4SdkTransportRuntimeJobsRequestJob_get_options(job,&options));CHECK(R4SdkTransportRuntimeJobsRequestJob_start(0,job,&options).bits==1);
    WEB(R4SdkWebRuntimeWebRuntime_abortDocument(0,runtime));s.retired=1;
    CHECK(!(R4SdkTransportRuntimeJobsRequestJob_activeRuntime(0,job).flags&1));
    int joined=0;for(uint32_t i=0;i<1200;i++){if(R4SdkTransportRuntimeJobsRequestJob_poll(0,job).bits){joined=1;break;}r4sys_sleep_ticks(&sys,1);}
    CHECK(joined&&s.lookups>=3&&!s.wrong_thread);
    TRY(R4SdkTransportRuntimeJobsRequestJob_fail(0,job,B("retired"),0));CHECK(!R4SdkWebRuntimeWebRuntime_requestInFlight(0,runtime,id,73).bits);
    TRY(R4SdkTransportRuntimeJobsRequestJob_deinit(0,job));CHECK(!R4SdkTransportRuntimeJobsRequestJob_get_active(job).bits&&R4SdkTransportRuntimeJobsRequestJob_get_memory(job).length==0);
    WEB(R4SdkWebRuntimeWebRuntime_deinit(0,runtime));return 0;
}
