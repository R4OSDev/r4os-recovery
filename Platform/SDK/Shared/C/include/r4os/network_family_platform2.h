#ifndef R4OS_NETWORK_FAMILY_PLATFORM2_H
#define R4OS_NETWORK_FAMILY_PLATFORM2_H
#include "platform2.h"
#include "poll_budget.h"
/* One exclusive synchronous channel; Context/tables/code remain live through
 * explicit Close. A timeout does not prove a mutation failed. No implicit
 * family fallback, socket retry, text conversion or datagram reconstruction. */
enum { R4_NETWORK_DNS=0, R4_NETWORK_TCP=1, R4_NETWORK_UDP=2 };
typedef struct R4SdkNetwork {
 R4SysServiceCallFn call; R4SysServiceCloseFn close;
 uint32_t handle, service; uint64_t timeout_ticks;
} R4SdkNetwork;
static inline int32_t R4SdkNetworkDeadlineFromBudget(const R4SdkDeadlineBudget *budget,R4NetworkDeadline *out){
 if(!budget||!out||budget->kind>2||budget->reserved)return R4OS_NETWORK_ERROR_INVALID;
 R4SdkClockIdentity k=budget->identity;
 if(!k.source||!k.generation||(budget->kind!=2&&budget->deadline_ns<budget->last_ns)||(budget->kind==2&&budget->deadline_ns))return R4OS_NETWORK_ERROR_INVALID;
 *out=(R4NetworkDeadline){.version=1,.size=sizeof(*out),.kind=budget->kind,.absolute_ns=budget->deadline_ns,.last_ns=budget->last_ns,.clock_source=k.source,.clock_generation=k.generation,.event_backend=k.event_backend,.tick_hz=k.tick_hz};return 0;
}
static inline int R4SdkNetworkAddressValid(R4NetworkAddress x){
 if(x.reserved0||x.reserved1||(x.family!=4&&x.family!=6))return 0;
 if(x.family==4)for(uint32_t i=4;i<16;++i)if(x.bytes[i])return 0;
 return 1;
}
static inline int R4SdkNetworkEndpointValid(R4NetworkEndpoint x){return !x.reserved&&!x.flags&&R4SdkNetworkAddressValid(x.address);}
static inline int R4SdkNetworkRecord(const void *p,uint32_t size){uint32_t h[2];__builtin_memcpy(h,p,8);return h[0]==1&&h[1]==size;}
static inline int32_t R4SdkNetworkConnect(const R4OS2Context *context,uint32_t service,R4SdkNetwork *out){
 if(!out||service>2)return R4OS_NETWORK_ERROR_INVALID;
 uint64_t open=0,call=0,close=0;int32_t rc=R4OS2ContextFunction(context,1,offsetof(R4XStartR4Sys2,service_open),&open);if(rc)return rc;
 rc=R4OS2ContextFunction(context,1,offsetof(R4XStartR4Sys2,service_call),&call);if(rc)return rc;
 rc=R4OS2ContextFunction(context,1,offsetof(R4XStartR4Sys2,service_close),&close);if(rc)return rc;
 const uint8_t *name=(const uint8_t *)(service==0?"DNSSVC":service==1?"TCPSVC":"UDPSVC");R4ServiceInfo info={0};
 rc=((R4SysServiceOpenFn)(uintptr_t)open)(name,&info);if(rc)return rc;if(!info.handle)return R4OS_SERVICE_API_RESULT_NO_ENDPOINT;
 *out=(R4SdkNetwork){(R4SysServiceCallFn)(uintptr_t)call,(R4SysServiceCloseFn)(uintptr_t)close,info.handle,service,500};return 0;
}
static inline int32_t R4SdkNetworkClose(R4SdkNetwork *client){
 if(!client||!client->handle)return R4OS_NETWORK_ERROR_BAD_SOCKET;if(!client->close)return R4OS_ERR_NO_FN;
 int32_t rc=client->close(client->handle);if(rc>=0)client->handle=0;return rc;
}
static inline int32_t R4SdkNetworkRpc(const R4SdkNetwork *client,uint16_t op,const void *request,uint32_t length,void *out,uint32_t capacity){
 if(!client||!client->handle)return R4OS_NETWORK_ERROR_BAD_SOCKET;if(!client->call)return R4OS_ERR_NO_FN;
 if((length&&!request)||(capacity&&!out)||length>4096||capacity>4096)return R4OS_NETWORK_ERROR_INVALID;
 R4ServiceMessageHeader header={0};int32_t rc=client->call(client->handle,op,(const uint8_t *)request,length,&header,(uint8_t *)out,capacity,client->timeout_ticks);
 if(rc<0)return rc;if((uint32_t)rc>capacity)return R4OS_NETWORK_ERROR_INVALID;
 if(header.status==R4OS_SERVICE_API_RESULT_BAD_OP)return R4OS_ERR_NO_FN;
 if(header.status)return header.status<0?header.status:R4OS_NETWORK_ERROR_INVALID;return rc;
}
static inline int32_t R4SdkNetworkInfo(const R4SdkNetwork *client,R4NetworkProviderInfo *out){
 if(!out)return R4OS_NETWORK_ERROR_INVALID;R4NetworkProviderInfo x={0};int32_t rc=R4SdkNetworkRpc(client,R4OS_NETWORK_OP_INFO,NULL,0,&x,sizeof(x));if(rc<0)return rc;
 if(rc!=sizeof(x)||!R4SdkNetworkRecord(&x,sizeof(x))||!x.provider||x.reserved||(x.capabilities&~UINT64_C(4095))||x.max_send>3968||x.max_recv>4008||x.max_answers>32||x.page_capacity>16)return R4OS_NETWORK_ERROR_INVALID;
 *out=x;return 0;
}
/* Write/Send result.bytes is the confirmed accepted prefix with no response
 * payload. Read/Recv copy bytes only after the whole reply was validated. */
static inline int32_t R4SdkNetworkSocket(const R4SdkNetwork *client,uint16_t op,R4NetworkSocketRequest request,const uint8_t *data,uint32_t length,uint8_t *out_data,uint32_t capacity,R4NetworkSocketResult *out){
 if(!client||!out||client->service==0||op<R4OS_NETWORK_OP_CONNECT||op>R4OS_NETWORK_OP_ACCEPT||!R4SdkNetworkRecord(&request,sizeof(request))||!request.provider||length>3968||capacity>4008||(length&&!data)||(capacity&&!out_data))return R4OS_NETWORK_ERROR_INVALID;
 int sending=op==R4OS_NETWORK_OP_WRITE||op==R4OS_NETWORK_OP_SEND,receiving=op==R4OS_NETWORK_OP_READ||op==R4OS_NETWORK_OP_RECV;
 if(length!=(sending?request.bytes:0)||(receiving&&request.bytes>capacity))return R4OS_NETWORK_ERROR_INVALID;
 uint8_t payload[4096],response[4096];__builtin_memcpy(payload,&request,sizeof(request));if(length)__builtin_memcpy(payload+sizeof(request),data,length);
 int32_t rc=R4SdkNetworkRpc(client,op,payload,sizeof(request)+length,response,sizeof(response));if(rc<0)return rc;
 R4NetworkSocketResult x;if((uint32_t)rc<sizeof(x))return R4OS_NETWORK_ERROR_INVALID;__builtin_memcpy(&x,response,sizeof(x));
 int accepted=op==R4OS_NETWORK_OP_ACCEPT&&x.state==R4OS_NETWORK_STATE_READY;
 if(!R4SdkNetworkRecord(&x,sizeof(x))||x.provider!=request.provider||!x.socket||!x.generation||(request.socket&&!accepted&&(x.socket!=request.socket||x.generation!=request.generation))||(accepted&&x.socket==request.socket&&x.generation==request.generation)||!R4SdkNetworkEndpointValid(x.endpoint)||x.state<1||x.state>6||(x.flags&~(uint32_t)R4OS_NETWORK_FLAG_TRUNCATED)||x.bytes>request.bytes||x.original_bytes<x.bytes||rc!=sizeof(x)+(receiving?x.bytes:0))return R4OS_NETWORK_ERROR_INVALID;
 if((op!=R4OS_NETWORK_OP_RECV&&(x.flags||x.original_bytes!=x.bytes))||(op==R4OS_NETWORK_OP_RECV&&((!!(x.flags&R4OS_NETWORK_FLAG_TRUNCATED))!=(x.original_bytes>x.bytes))))return R4OS_NETWORK_ERROR_INVALID;
 if(receiving&&x.bytes)__builtin_memcpy(out_data,response+sizeof(x),x.bytes);*out=x;return 0;
}
static inline int32_t R4SdkNetworkResolve(const R4SdkNetwork *client,R4NetworkResolveRequest request,R4NetworkResolveAnswer *answers,uint32_t capacity,R4NetworkResolvePage *out){
 if(!client||client->service!=0||!out||!answers||!request.capacity||request.capacity>16||request.capacity>capacity)return R4OS_NETWORK_ERROR_INVALID;
 uint8_t response[4096];int32_t rc=R4SdkNetworkRpc(client,R4OS_NETWORK_OP_RESOLVE,&request,sizeof(request),response,sizeof(response));if(rc<0)return rc;
 R4NetworkResolvePage x;if((uint32_t)rc<sizeof(x))return R4OS_NETWORK_ERROR_INVALID;__builtin_memcpy(&x,response,sizeof(x));
 if(!R4SdkNetworkRecord(&x,sizeof(x))||!request.provider||x.provider!=request.provider||!x.query||(request.query&&x.query!=request.query)||!x.expires_ns||!x.total||x.total>32||!x.count||x.count>request.capacity||request.cursor>x.total||x.count>x.total-request.cursor||x.next!=request.cursor+x.count||x.flags!=(x.next<x.total?R4OS_NETWORK_FLAG_MORE:0)||rc!=sizeof(x)+x.count*sizeof(*answers))return R4OS_NETWORK_ERROR_INVALID;
 for(uint32_t i=0;i<x.count;++i){R4NetworkResolveAnswer a;__builtin_memcpy(&a,response+sizeof(x)+i*sizeof(a),sizeof(a));if(!R4SdkNetworkAddressValid(a.address)||a.reserved||(!request.query&&a.address.family!=request.family))return R4OS_NETWORK_ERROR_INVALID;}
 __builtin_memcpy(answers,response+sizeof(x),x.count*sizeof(*answers));*out=x;return 0;
}
static inline int32_t R4SdkNetworkRelease(const R4SdkNetwork *client,uint64_t provider,uint64_t query){
 if(!client||client->service!=0)return R4OS_NETWORK_ERROR_INVALID;
 R4NetworkResolveRequest request={.version=1,.size=sizeof(request),.provider=provider,.query=query,.deadline={.version=1,.size=sizeof(R4NetworkDeadline)}};uint8_t response;
 int32_t rc=R4SdkNetworkRpc(client,R4OS_NETWORK_OP_RELEASE,&request,sizeof(request),&response,1);return rc<=0?rc:R4OS_NETWORK_ERROR_INVALID;
}
_Static_assert(sizeof(R4NetworkAddress)==32,"network address");
_Static_assert(sizeof(R4NetworkEndpoint)==40,"network endpoint");
_Static_assert(sizeof(R4NetworkDeadline)==48,"network deadline");
_Static_assert(sizeof(R4NetworkSocketRequest)==128,"network request");
_Static_assert(sizeof(R4NetworkSocketResult)==88,"network result");
_Static_assert(sizeof(R4NetworkResolveRequest)==392,"resolver request");
_Static_assert(sizeof(R4NetworkResolveAnswer)==40,"resolver answer");
#endif
