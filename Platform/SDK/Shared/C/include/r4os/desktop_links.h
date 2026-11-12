#ifndef R4OS_DESKTOP_LINKS_H
#define R4OS_DESKTOP_LINKS_H
#include "app_services.h"
/* Persist the entire canonical Prepare request before Activate. Status is
 * purely observational; unknown/lost replies never authorize a new start. */
static inline int r4_desktop_link_supported(const R4DesktopLinkReply *r){return r&&r->result==0&&(r->flags&R4OS_DESKTOP_LINK_CAPABILITIES)==R4OS_DESKTOP_LINK_CAPABILITIES;}
static inline int32_t r4_desktop_link_binding(const R4DesktopLinkToken*scope,R4ProgramProcessHandle owner,const uint64_t intent[3],uint64_t deadline,const uint8_t*path,uint32_t path_bytes,const uint8_t*bytes,uint32_t count,R4DesktopLinkRequest*out){
 if(!scope||!intent||!out||!path||!bytes||!path_bytes||path_bytes>=160||!count||count>R4OS_DESKTOP_LINK_MAX_BYTES||!owner.instance_id||!owner.generation||owner.reserved||!(intent[0]|intent[1]|intent[2])||scope->version!=1||scope->size!=sizeof(*scope)||!scope->service.instance_id||!scope->service.generation||!(scope->epoch[0]|scope->epoch[1]|scope->epoch[2]))return R4OS_DESKTOP_LINK_RESULT_INVALID;
 *out=(R4DesktopLinkRequest){0};out->token.version=1;out->token.size=sizeof(out->token);out->token.service=scope->service;out->token.owner=owner;out->deadline=deadline;out->link_length=count;
 for(uint32_t i=0;i<3;i++){out->token.epoch[i]=scope->epoch[i];out->token.intent[i]=intent[i];}
 for(uint32_t i=0;i<path_bytes;i++){if(!path[i])return R4OS_DESKTOP_LINK_RESULT_INVALID;out->link_path[i]=path[i];}
 for(uint32_t i=0;i<count;i++){if(!bytes[i])return R4OS_DESKTOP_LINK_RESULT_INVALID;out->link_bytes[i]=bytes[i];}return 0;
}
static inline int32_t r4_desktop_link_call(R4App*app,uint16_t op,const R4DesktopLinkRequest*q,R4DesktopLinkReply*out){
 if(!app||!q||!out)return R4OS_DESKTOP_LINK_RESULT_INVALID;
 R4Services services=r4_app_services(app);R4ServiceConnection connection={0};int32_t rc=r4_services_open(&services,R4OS_WINDOW_SERVICE_NAME,&connection);if(rc)return rc;
 R4DesktopLinkReply r={0};R4Duration duration={500000000u};R4ServiceCallResult got=r4_service_connection_call(&connection,op,q,sizeof(*q),&r,sizeof(r),r4_timeout_finite(duration));(void)r4_service_connection_close(&connection);
 if(got.kind==R4_SERVICE_CALL_TIMED_OUT)return R4OS_SERVICE_API_RESULT_TIMEOUT;if(got.kind!=R4_SERVICE_CALL_RESPONSE)return got.raw_code;
 if(got.header.status)return got.header.status;
 if(got.bytes!=sizeof(r)||r.request.token.version!=1||r.request.token.size!=sizeof(R4DesktopLinkToken)||r.request.link_length>R4OS_DESKTOP_LINK_MAX_BYTES||r.phase>R4OS_DESKTOP_LINK_PHASE_EXPIRED||r.result>0||r.result<R4OS_DESKTOP_LINK_RESULT_UNAVAILABLE)return R4OS_DESKTOP_LINK_RESULT_INVALID;
 if(op!=R4OS_DESKTOP_LINK_OP_SCOPE){R4DesktopLinkRequest expected=*q;if(q->token.serial&&q->token.serial!=r.request.token.serial)return R4OS_DESKTOP_LINK_RESULT_INVALID;expected.token.serial=r.request.token.serial;const uint8_t*a=(const uint8_t*)&expected,*b=(const uint8_t*)&r.request;for(uint32_t i=0;i<sizeof(expected);i++)if(a[i]!=b[i])return R4OS_DESKTOP_LINK_RESULT_INVALID;}
 *out=r;return 0;
}
static inline int32_t r4_desktop_link_scope(R4App*a,R4DesktopLinkReply*r){R4DesktopLinkRequest q={0};q.token.version=1;q.token.size=sizeof(q.token);return r4_desktop_link_call(a,R4OS_DESKTOP_LINK_OP_SCOPE,&q,r);}
static inline int32_t r4_desktop_link_prepare(R4App*a,const R4DesktopLinkRequest*q,R4DesktopLinkReply*r){return r4_desktop_link_call(a,R4OS_DESKTOP_LINK_OP_PREPARE,q,r);}
static inline int32_t r4_desktop_link_activate(R4App*a,const R4DesktopLinkRequest*q,R4DesktopLinkReply*r){return r4_desktop_link_call(a,R4OS_DESKTOP_LINK_OP_ACTIVATE,q,r);}
static inline int32_t r4_desktop_link_status(R4App*a,const R4DesktopLinkRequest*q,R4DesktopLinkReply*r){return r4_desktop_link_call(a,R4OS_DESKTOP_LINK_OP_STATUS,q,r);}
static inline int32_t r4_desktop_link_release(R4App*a,const R4DesktopLinkRequest*q,R4DesktopLinkReply*r){return r4_desktop_link_call(a,R4OS_DESKTOP_LINK_OP_RELEASE,q,r);}
#endif
