#ifndef R4OS_CLIPBOARD_OFFER_PLATFORM2_H
#define R4OS_CLIPBOARD_OFFER_PLATFORM2_H
#include "platform2.h"
/* Exclusive synchronous CLIPSVC channel. Keep Context/table/code live through
 * Close. Transport failures can leave publication uncertain: use Status or
 * idempotent Commit on the SAME token. No destructor, retry or conversion. */
typedef struct R4SdkClipboardOffers {
 R4SysServiceCallFn call; R4SysServiceCloseFn close; uint32_t handle;
 uint64_t timeout_ticks;
 R4SysMonotonicClockFn clock;
} R4SdkClipboardOffers;
static inline R4ClipboardOfferLease R4SdkClipboardOfferToken(R4ClipboardOfferLease x){
 return (R4ClipboardOfferLease){.version=1,.size=sizeof(x),.provider=x.provider,.id=x.id};
}
static inline R4ClipboardOfferTransfer R4SdkClipboardOfferTransfer(R4ClipboardOfferLease x,uint32_t item,uint32_t format,uint64_t offset,uint64_t total){
 return (R4ClipboardOfferTransfer){.version=1,.size=sizeof(R4ClipboardOfferTransfer),.provider=x.provider,.id=x.id,.item=item,.format=format,.offset=offset,.total_bytes=total};
}
static inline int32_t R4SdkClipboardOffersConnect(const R4OS2Context *context,R4SdkClipboardOffers *out){
 if(!out)return R4OS_CLIPBOARD_OFFER_ERROR_INVALID;
 uint64_t open=0,call=0,close=0;
 int32_t rc=R4OS2ContextFunction(context,1,offsetof(R4XStartR4Sys2,service_open),&open);if(rc)return rc;
 rc=R4OS2ContextFunction(context,1,offsetof(R4XStartR4Sys2,service_call),&call);if(rc)return rc;
 rc=R4OS2ContextFunction(context,1,offsetof(R4XStartR4Sys2,service_close),&close);if(rc)return rc;
 R4ServiceInfo info={0};rc=((R4SysServiceOpenFn)(uintptr_t)open)((const uint8_t *)"CLIPSVC",&info);if(rc)return rc;
 if(!info.handle)return R4OS_SERVICE_API_RESULT_NO_ENDPOINT;
 uint64_t clock=0;(void)R4OS2ContextFunction(context,1,offsetof(R4XStartR4Sys2,monotonic_clock),&clock);
 *out=(R4SdkClipboardOffers){(R4SysServiceCallFn)(uintptr_t)call,(R4SysServiceCloseFn)(uintptr_t)close,info.handle,500,(R4SysMonotonicClockFn)(uintptr_t)clock};return 0;
}
static inline int32_t R4SdkClipboardOffersClose(R4SdkClipboardOffers *client){
 if(!client||!client->handle)return R4OS_CLIPBOARD_OFFER_ERROR_CLOSED;
 if(!client->close)return R4OS_ERR_NO_FN;
 int32_t rc=client->close(client->handle);if(rc>=0)client->handle=0;return rc;
}
static inline int32_t R4SdkClipboardOffersRpc(const R4SdkClipboardOffers *client,uint16_t op,const void *request,uint32_t length,void *out,uint32_t capacity){
 if(!client||!client->handle)return R4OS_CLIPBOARD_OFFER_ERROR_CLOSED;
 if(!client->call)return R4OS_ERR_NO_FN;
 if((length&&!request)||(capacity&&!out)||length>4096||capacity>4096)return R4OS_CLIPBOARD_OFFER_ERROR_INVALID;
 R4ServiceMessageHeader header={0};int32_t rc=client->call(client->handle,op,(const uint8_t *)request,length,&header,(uint8_t *)out,capacity,client->timeout_ticks);
 if(rc<0)return rc;
 if(header.status==R4OS_SERVICE_API_RESULT_BAD_OP)return R4OS_CLIPBOARD_OFFER_ERROR_UNSUPPORTED;
 if(header.status)return header.status<0?header.status:R4OS_CLIPBOARD_OFFER_ERROR_INVALID;
 return rc;
}
static inline int R4SdkClipboardOfferRecord(const void *record,uint32_t size){
 uint32_t head[2];__builtin_memcpy(head,record,8);return head[0]==1&&head[1]==size;
}
static inline int32_t R4SdkClipboardOffersEmpty(const R4SdkClipboardOffers *client,uint16_t op,const void *request,uint32_t length){
 uint8_t byte=0;int32_t rc=R4SdkClipboardOffersRpc(client,op,request,length,&byte,1);return rc<=0?rc:R4OS_CLIPBOARD_OFFER_ERROR_INVALID;
}
static inline int R4SdkClipboardOfferLeaseValid(R4ClipboardOfferLease x,uint64_t provider,uint32_t state){
 return R4SdkClipboardOfferRecord(&x,sizeof(x))&&provider&&x.provider==provider&&x.id&&x.expires_ns&&!x.reserved&&(!state||state==x.state);
}
static inline int32_t R4SdkClipboardOffersInfo(const R4SdkClipboardOffers *client,R4ClipboardOfferInfo *out){
 if(!out)return R4OS_CLIPBOARD_OFFER_ERROR_INVALID;
 R4ClipboardOfferInfo value={0};int32_t rc=R4SdkClipboardOffersRpc(client,R4OS_CLIPBOARD_OFFER_OP_INFO,NULL,0,&value,sizeof(value));if(rc<0)return rc;
 if(rc!=sizeof(value)||!R4SdkClipboardOfferRecord(&value,sizeof(value))||!value.provider||value.flags||!value.put_chunk||value.put_chunk>R4OS_CLIPBOARD_OFFER_PUT_CHUNK||!value.read_chunk||value.read_chunk>R4OS_CLIPBOARD_OFFER_READ_CHUNK)return R4OS_CLIPBOARD_OFFER_ERROR_INVALID;
 *out=value;return 0;
}
static inline int32_t R4SdkClipboardOffersBegin(const R4SdkClipboardOffers *client,R4ClipboardOfferInfo info,uint64_t bytes,R4ClipboardOfferLease *out){
 if(!out)return R4OS_CLIPBOARD_OFFER_ERROR_INVALID;
 R4ClipboardOfferBegin request={.version=1,.size=sizeof(request),.provider=info.provider,.expected_revision=info.revision,.total_bytes=bytes};
 R4ClipboardOfferLease value={0};int32_t rc=R4SdkClipboardOffersRpc(client,R4OS_CLIPBOARD_OFFER_OP_BEGIN,&request,sizeof(request),&value,sizeof(value));if(rc<0)return rc;
 if(rc!=sizeof(value)||!R4SdkClipboardOfferLeaseValid(value,info.provider,R4OS_CLIPBOARD_OFFER_STATE_WRITING)||value.revision!=info.revision)return R4OS_CLIPBOARD_OFFER_ERROR_INVALID;
 *out=value;return 0;
}
static inline int32_t R4SdkClipboardOffersDeclare(const R4SdkClipboardOffers *client,R4ClipboardOfferLease stage,uint32_t item,uint32_t format,uint64_t total){
 R4ClipboardOfferTransfer request=R4SdkClipboardOfferTransfer(stage,item,format,0,total);return R4SdkClipboardOffersEmpty(client,R4OS_CLIPBOARD_OFFER_OP_DECLARE,&request,sizeof(request));
}
static inline int32_t R4SdkClipboardOffersPut(const R4SdkClipboardOffers *client,R4ClipboardOfferLease stage,uint32_t item,uint32_t format,uint64_t offset,uint64_t total,const uint8_t *bytes,uint32_t length){
 if(length>R4OS_CLIPBOARD_OFFER_PUT_CHUNK)return R4OS_CLIPBOARD_OFFER_ERROR_TOO_LARGE;
 if(length&&!bytes)return R4OS_CLIPBOARD_OFFER_ERROR_INVALID;
 uint8_t payload[4096];R4ClipboardOfferTransfer request=R4SdkClipboardOfferTransfer(stage,item,format,offset,total);
 __builtin_memcpy(payload,&request,sizeof(request));if(length)__builtin_memcpy(payload+sizeof(request),bytes,length);
 return R4SdkClipboardOffersEmpty(client,R4OS_CLIPBOARD_OFFER_OP_PUT,payload,sizeof(request)+length);
}
static inline int32_t R4SdkClipboardOffersLeaseCall(const R4SdkClipboardOffers *client,uint16_t op,R4ClipboardOfferLease lease,R4ClipboardOfferLease *out){
 if(!out)return R4OS_CLIPBOARD_OFFER_ERROR_INVALID;
 R4ClipboardOfferLease request=R4SdkClipboardOfferToken(lease),value={0};int32_t rc=R4SdkClipboardOffersRpc(client,op,&request,sizeof(request),&value,sizeof(value));if(rc<0)return rc;
 if(rc!=sizeof(value)||!R4SdkClipboardOfferLeaseValid(value,lease.provider,0)||value.id!=lease.id||(value.state!=1&&value.state!=2)||(op==R4OS_CLIPBOARD_OFFER_OP_COMMIT&&value.state!=2))return R4OS_CLIPBOARD_OFFER_ERROR_INVALID;
 *out=value;return 0;
}
static inline int32_t R4SdkClipboardOffersCommit(const R4SdkClipboardOffers *client,R4ClipboardOfferLease stage,R4ClipboardOfferLease *out){return R4SdkClipboardOffersLeaseCall(client,R4OS_CLIPBOARD_OFFER_OP_COMMIT,stage,out);}
static inline int32_t R4SdkClipboardOffersStatus(const R4SdkClipboardOffers *client,R4ClipboardOfferLease stage,R4ClipboardOfferLease *out){return R4SdkClipboardOffersLeaseCall(client,R4OS_CLIPBOARD_OFFER_OP_STATUS,stage,out);}
static inline int32_t R4SdkClipboardOffersAbort(const R4SdkClipboardOffers *client,R4ClipboardOfferLease stage){R4ClipboardOfferLease request=R4SdkClipboardOfferToken(stage);return R4SdkClipboardOffersEmpty(client,R4OS_CLIPBOARD_OFFER_OP_ABORT,&request,sizeof(request));}
static inline int32_t R4SdkClipboardOffersSnapshot(const R4SdkClipboardOffers *client,R4ClipboardOfferLease *out){
 if(!out)return R4OS_CLIPBOARD_OFFER_ERROR_INVALID;
 R4ClipboardOfferLease value={0};int32_t rc=R4SdkClipboardOffersRpc(client,R4OS_CLIPBOARD_OFFER_OP_SNAPSHOT,NULL,0,&value,sizeof(value));if(rc<0)return rc;
 if(rc!=sizeof(value)||!R4SdkClipboardOfferLeaseValid(value,value.provider,3))return R4OS_CLIPBOARD_OFFER_ERROR_INVALID;
 *out=value;return 0;
}
static inline int32_t R4SdkClipboardOffersRelease(const R4SdkClipboardOffers *client,R4ClipboardOfferLease lease){R4ClipboardOfferLease request=R4SdkClipboardOfferToken(lease);return R4SdkClipboardOffersEmpty(client,R4OS_CLIPBOARD_OFFER_OP_RELEASE,&request,sizeof(request));}
static inline int32_t R4SdkClipboardOffersEnumerate(const R4SdkClipboardOffers *client,R4ClipboardOfferLease snapshot,uint32_t cursor,R4ClipboardOfferFormat *formats,uint32_t capacity,R4ClipboardOfferPage *out){
 if(!formats||!out||!capacity||capacity>16)return R4OS_CLIPBOARD_OFFER_ERROR_INVALID;
 R4ClipboardOfferEnumerate request={.version=1,.size=sizeof(request),.provider=snapshot.provider,.id=snapshot.id,.cursor=cursor,.capacity=capacity};uint8_t payload[4096];
 int32_t rc=R4SdkClipboardOffersRpc(client,R4OS_CLIPBOARD_OFFER_OP_ENUMERATE,&request,sizeof(request),payload,sizeof(payload));if(rc<0)return rc;
 R4ClipboardOfferPage page;if((uint32_t)rc<sizeof(page))return R4OS_CLIPBOARD_OFFER_ERROR_INVALID;__builtin_memcpy(&page,payload,sizeof(page));
 if(!R4SdkClipboardOfferRecord(&page,sizeof(page))||page.provider!=snapshot.provider||page.id!=snapshot.id||page.revision!=snapshot.revision||page.reserved||page.count>capacity||page.total>16||cursor>page.total||page.count>page.total-cursor||page.next!=cursor+page.count||rc!=sizeof(page)+page.count*sizeof(*formats))return R4OS_CLIPBOARD_OFFER_ERROR_INVALID;
 for(uint32_t i=0;i<page.count;++i){R4ClipboardOfferFormat record;__builtin_memcpy(&record,payload+sizeof(page)+i*sizeof(record),sizeof(record));if(record.item>=8||record.format<1||record.format>5||record.total_bytes>R4OS_CLIPBOARD_OFFER_MAX_OFFER_BYTES||record.flags||record.reserved)return R4OS_CLIPBOARD_OFFER_ERROR_INVALID;}
 if(page.count)__builtin_memcpy(formats,payload+sizeof(page),page.count*sizeof(*formats));*out=page;return 0;
}
static inline int32_t R4SdkClipboardOffersRead(const R4SdkClipboardOffers *client,R4ClipboardOfferLease snapshot,uint32_t item,uint32_t format,uint64_t offset,uint8_t *bytes,uint32_t capacity,R4ClipboardOfferChunk *out){
 if(!out||(capacity&&!bytes))return R4OS_CLIPBOARD_OFFER_ERROR_INVALID;
 if(capacity>R4OS_CLIPBOARD_OFFER_READ_CHUNK)return R4OS_CLIPBOARD_OFFER_ERROR_TOO_LARGE;
 R4ClipboardOfferTransfer request=R4SdkClipboardOfferTransfer(snapshot,item,format,offset,capacity);uint8_t payload[4096];
 int32_t rc=R4SdkClipboardOffersRpc(client,R4OS_CLIPBOARD_OFFER_OP_READ,&request,sizeof(request),payload,sizeof(payload));if(rc<0)return rc;
 R4ClipboardOfferChunk chunk;if((uint32_t)rc<sizeof(chunk))return R4OS_CLIPBOARD_OFFER_ERROR_INVALID;__builtin_memcpy(&chunk,payload,sizeof(chunk));
 if(!R4SdkClipboardOfferRecord(&chunk,sizeof(chunk))||chunk.provider!=snapshot.provider||chunk.id!=snapshot.id||chunk.revision!=snapshot.revision||chunk.offset!=offset||chunk.bytes>capacity||chunk.total_bytes>R4OS_CLIPBOARD_OFFER_MAX_OFFER_BYTES||offset>chunk.total_bytes||chunk.bytes>chunk.total_bytes-offset||chunk.flags>1||((chunk.flags==1)!=(offset+chunk.bytes==chunk.total_bytes))||rc!=sizeof(chunk)+chunk.bytes)return R4OS_CLIPBOARD_OFFER_ERROR_INVALID;
 if(chunk.bytes)__builtin_memcpy(bytes,payload+sizeof(chunk),chunk.bytes);*out=chunk;return 0;
}
_Static_assert(sizeof(R4ClipboardOfferInfo)==80,"clipboard info");
_Static_assert(sizeof(R4ClipboardOfferLease)==48,"clipboard lease");
_Static_assert(sizeof(R4ClipboardOfferTransfer)==48,"clipboard transfer");
_Static_assert(sizeof(R4ClipboardOfferPage)==48,"clipboard page");
_Static_assert(sizeof(R4ClipboardOfferChunk)==56,"clipboard chunk");
#endif
