/* Freestanding C cases shared by native Rust tests and the real R4X probe. */
#include <r4os/facades.h>
#define B(s) (const uint8_t *)(s),sizeof(s)-1
#define CHECK(v) do{if(!(v))return __LINE__;}while(0)
static int ok(R4SdkTransportSlot v){return !v.status&&!(v.flags&2);}
static int data_ok(R4SdkDataSlot v){return !v.status&&!(v.flags&2);}
#define TRY(v) CHECK(ok(v))
#define DATA(v) CHECK(data_ok(v))
static int equal(R4SdkTransportSlot v,const char *text,uintptr_t n){
    if(!ok(v)||!(v.flags&1)||v.length!=n||(!v.ptr&&n))return 0;
    for(uintptr_t i=0;i<n;i++)if(((const uint8_t *)v.ptr)[i]!=(uint8_t)text[i])return 0;
    return 1;
}
static int32_t entropy_info(R4EntropySourceInfo *out){
    *out=(R4EntropySourceInfo){.version=1,.size=sizeof(*out),.state=R4OS_ENTROPY_STATE_READY,.generation=1,.max_request_bytes=64};return 0;
}
static int32_t entropy_fill(uint8_t *out,uint32_t bytes){for(uint32_t i=0;i<bytes;i++)out[i]=0x5a;return (int32_t)bytes;}
typedef struct SinkState {uint8_t bytes[16];uint64_t next;uint32_t calls,heads;int allow_head;} SinkState;
static R4SdkWebSlot invoke(void *user,uint32_t kind,const R4SdkWebSlot *args,uint32_t count,void *output){
    (void)output;SinkState *state=(SinkState *)user;
    if(kind==R4SdkWebCallbackKind_download_head){
        if(count!=2||args[0].ptr!=user||!args[1].ptr)return (R4SdkWebSlot){.flags=1};
        const R4SdkTransportDownloadHeadObservation *head=args[1].ptr;
        R4SdkTransportHttpStreamResponse response;
        if(!ok(R4SdkTransportDownloadHeadObservation_get_response(head,&response))||
            R4SdkTransportHttpStreamResponse_get_status(&response).bits!=200||
            R4SdkTransportDownloadHeadObservation_get_requested_offset(head).bits!=7||
            !equal(R4SdkTransportDownloadHeadObservation_get_headers(head),"ETag: \"expected\"\r\n",18))return (R4SdkWebSlot){.flags=1};
        state->heads++;return (R4SdkWebSlot){.bits=(uint64_t)state->allow_head,.flags=1};
    }
    if(kind!=R4SdkWebCallbackKind_download_write||count!=3||args[0].ptr!=user||args[1].bits!=state->next||args[2].length>sizeof(state->bytes)-state->next)return (R4SdkWebSlot){.flags=1};
    for(uintptr_t i=0;i<args[2].length;i++)state->bytes[state->next+i]=((const uint8_t *)args[2].ptr)[i];
    state->next+=args[2].length;state->calls++;return (R4SdkWebSlot){.bits=1,.flags=1};
}
int sdk_transport_bootstrap_case(void){
    R4XStartR4Sys sys={.magic=R4XSTART_R4SYS_MAGIC,.abi_version=R4XSTART_R4SYS_VERSION,.size=sizeof(sys),.entropy_source_info=(uintptr_t)&entropy_info,.entropy_fill=(uintptr_t)&entropy_fill};
    R4XStartImport import={.group_id=R4L_GROUP_R4SYS,.flags=R4XSTART_IMPORT_FLAG_GROUP_INTERFACE,.table=(uintptr_t)&sys};
    R4XStartContext start={.magic=R4XSTART_MAGIC,.abi_major=R4XSTART_ABI_MAJOR,.abi_minor=R4XSTART_ABI_MINOR,.size=sizeof(start),.app_class=R4XSTART_APP_CLASS_CONSOLE,.instance_id=42,.flags=R4XSTART_FLAG_IMPORTS_VALID,.imports=(uintptr_t)&import,.import_count=1};
    CHECK(R4SdkBindProgramEntropy(&start)==0);CHECK(R4SdkDataRandom_available(0).bits==1);
    uint8_t bytes[129];DATA(R4SdkDataRandom_fill(0,bytes,sizeof(bytes)));for(uintptr_t i=0;i<sizeof(bytes);i++)CHECK(bytes[i]==0x5a);
    /* Other native cases retain the genuine no-provider policy. */
    sys.entropy_source_info=0;sys.entropy_fill=0;CHECK(R4SdkBindProgramEntropy(&start)==0);CHECK(R4SdkDataRandom_available(0).bits==0);
    return 0;
}
int sdk_transport_c_case(uint8_t *scratch,uintptr_t capacity){
    R4SdkTransportHttpResponseDecoder decoder;R4SdkTransportHttpDecodeResult decoded;R4SdkTransportHttpResponse response;
    uint8_t body[32];const uint8_t input[]="HTTP/1.1 200 OK\r\nTransfer-Encoding: chunked\r\n\r\n3\r\nabc\r\n3\r\nDEF\r\n0\r\n\r\n";
    TRY(R4SdkTransportHttpResponseDecoder_init(0,R4SdkWebNative_http_Method_get,&decoder));
    TRY(R4SdkTransportHttpResponseDecoder_decode(0,&decoder,input,sizeof(input)-7,body,sizeof(body),0,0,&decoded));
    CHECK(R4SdkTransportHttpDecodeResult_inspectNative(&decoded).bits==R4SdkTransportHttpDecodeResult_TAG_need_more);
    TRY(R4SdkTransportHttpResponseDecoder_decode(0,&decoder,input,sizeof(input)-1,body,sizeof(body),1,0,&decoded));
    CHECK(R4SdkTransportHttpDecodeResult_inspectNative(&decoded).bits==R4SdkTransportHttpDecodeResult_TAG_complete);
    TRY(R4SdkTransportHttpDecodeResult_get_complete(&decoded,&response));CHECK(R4SdkTransportHttpResponse_get_status(&response).bits==200);
    CHECK(equal(R4SdkTransportHttpResponse_get_body(&response),"abcDEF",6));
    TRY(R4SdkTransportHttpResponseDecoder_init(0,R4SdkWebNative_http_Method_get,&decoder));
    TRY(R4SdkTransportHttpResponseDecoder_decode(0,&decoder,input,sizeof(input)-1,body,sizeof(body),0,1,&decoded));
    CHECK(R4SdkTransportHttpDecodeResult_inspectNative(&decoded).bits==R4SdkTransportHttpDecodeResult_TAG_aborted);
    R4SdkDataArena arena;R4SdkDataAllocator allocator;DATA(R4SdkData_arena(0,&arena,scratch,capacity));DATA(R4SdkData_allocator(0,&arena,&allocator));
    R4SdkTransportCacheLimits limits;R4SdkTransportCacheCache cache;R4SdkTransportCacheKey key;R4SdkTransportCacheClock clock;
    R4SdkTransportCacheLookup lookup;R4SdkTransportCacheHandle handle;R4SdkTransportCacheView view;
    TRY(R4SdkTransportCacheLimits_from_fields(&limits,256,4096));TRY(R4SdkTransportCacheCache_init(0,&allocator,&limits,&cache));
    TRY(R4SdkTransportCacheKey_create(&key,B("http://local/x"),B("partition"),B("accept:x\r\n")));
    TRY(R4SdkTransportCacheClock_from_fields(&clock,1000,(R4SdkTransportSlot){0}));
    R4SdkTransportSlot stored=R4SdkTransportCacheCache_store(0,&cache,&key,B("Cache-Control: max-age=60\r\n"),B("body"),&clock,1000,(R4SdkTransportSlot){0});CHECK(ok(stored)&&(stored.flags&1));
    TRY(R4SdkTransportCacheCache_lookup(0,&cache,&key,R4SdkWebNative_web_response_cache_Mode_normal,&clock,&lookup));
    CHECK(R4SdkTransportCacheLookup_get_action(&lookup).bits==R4SdkTransportCacheAction_hit);
    TRY(R4SdkTransportCacheLookup_get_handle(&lookup,&handle));TRY(R4SdkTransportCacheCache_view(0,&cache,&handle,&clock,&view));
    CHECK(equal(R4SdkTransportCacheView_get_body(&view),"body",4));
    TRY(R4SdkTransportCacheCache_invalidate(0,&cache,&key));
    TRY(R4SdkTransportCacheCache_view(0,&cache,&handle,&clock,&view));CHECK(equal(R4SdkTransportCacheView_get_body(&view),"body",4));
    TRY(R4SdkTransportCacheCache_release(0,&cache,&handle));
    CHECK(!(R4SdkTransportCacheCache_view(0,&cache,&handle,&clock,&view).flags&1));
    TRY(R4SdkTransportCacheCache_deinit(0,&cache));
    R4SdkTransportNative_app_network_Ipv4Address ip;
    TRY(R4SdkTransportNative_app_network_Ipv4Address_init(0,0,0,0,0,&ip));CHECK(R4SdkTransportNative_app_network_Ipv4Address_isUnspecified(0,&ip).bits==1);
    TRY(R4SdkTransportNative_app_network_Ipv4Address_init(0,1,0,0,0,&ip));CHECK(R4SdkTransportNative_app_network_Ipv4Address_isUnspecified(0,&ip).bits==0);
    R4SdkTransportRegistrationEndpoint registration;
    TRY(R4SdkTransportRegistrationEndpoint_from_fields(&registration,&ip,B("1.0.0.0"),4021,1));
    CHECK(equal(R4SdkTransportRegistrationEndpoint_get_hostname(&registration),"1.0.0.0",7));
    CHECK(R4SdkTransportRegistrationEndpoint_get_port(&registration).bits==4021);
    CHECK(R4SdkTransportRegistrationEndpoint_get_tls(&registration).bits==1);
    R4SdkTransportRegistrationResult rejected;
    TRY(R4SdkTransportRegistrationResult_set_invalid_reply(&rejected));
    CHECK(R4SdkTransportRegistrationResult_inspectNative(&rejected).bits==R4SdkTransportRegistrationResult_TAG_invalid_reply);
    SinkState state={0};R4SdkWebCallbackTable table;R4SdkTransportDownloadSink sink;
    CHECK(!R4SdkWebCallbackTable_from_fields(&table,(R4SdkWebSlot){.ptr=&state,.flags=1},UINT64_C(1)<<R4SdkWebCallbackKind_download_write,(R4SdkWebSlot){.ptr=(void *)(uintptr_t)&invoke,.flags=1}).status);
    TRY(R4SdkTransport_sink(0,&table,&sink));
    CHECK(R4SdkTransportDownloadSink_write(0,&sink,0,B("abc")).bits==1);
    CHECK(R4SdkTransportDownloadSink_write(0,&sink,3,B("DEF")).bits==1);
    CHECK(R4SdkTransportDownloadSink_write(0,&sink,1,B("bad")).bits==0);
    CHECK(state.next==6&&state.calls==2&&state.bytes[0]=='a'&&state.bytes[5]=='F');
    R4SdkTransportDownloadOptions options;R4SdkTransportDownloadHeadObservation head;
    R4SdkTransportHttpStreamResponse stream_head;
    TRY(R4SdkTransportDownloadOptions_create(&options));
    CHECK(R4SdkTransportDownloadOptions_get_max_retries(&options).bits==1);
    TRY(R4SdkTransportDownloadOptions_set_max_retries(&options,0));
    CHECK(R4SdkTransportDownloadOptions_get_max_retries(&options).bits==0);
    TRY(R4SdkTransportHttpStreamResponse_from_fields(&stream_head,200,R4SdkTransportHttpTransfer_content_length,6,(R4SdkTransportSlot){0},(R4SdkTransportSlot){0},(R4SdkTransportSlot){0}));
    TRY(R4SdkTransportDownloadHeadObservation_from_fields(&head,&stream_head,B("ETag: \"expected\"\r\n"),7));
    CHECK(R4SdkTransportDownloadOptions_observeHead(0,&options,&head).bits==1);
    CHECK(!R4SdkWebCallbackTable_from_fields(&table,(R4SdkWebSlot){.ptr=&state,.flags=1},UINT64_C(1)<<R4SdkWebCallbackKind_download_head,(R4SdkWebSlot){.ptr=(void *)(uintptr_t)&invoke,.flags=1}).status);
    TRY(R4SdkTransport_downloadCallbacks(0,&options,&table));
    state.allow_head=1;CHECK(R4SdkTransportDownloadOptions_observeHead(0,&options,&head).bits==1);
    state.allow_head=0;CHECK(R4SdkTransportDownloadOptions_observeHead(0,&options,&head).bits==0);
    CHECK(state.heads==2&&state.next==6&&state.calls==2);
    return 0;
}
