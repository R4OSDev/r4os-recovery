#ifndef R4OS_PROTOCOL_H
#define R4OS_PROTOCOL_H
#include "r4os/abi.h"
#include "r4os/technical2.h"
/* Ordinary R4P entry, independent of R4XStart or a Zig owner root. */
#define R4P_ENTRIES(INIT,SHUTDOWN,QUERY,DISPATCH) R4OS_PROTOCOL_ENTRY2(INIT,SHUTDOWN,QUERY,DISPATCH)
typedef struct R4ProtocolContext {const R4ProtocolApi2 *api;} R4ProtocolContext;
/* The original immutable loader table and actual PPI execution scope must
 * stay valid throughout every call. A cached table grants no other identity. */
static inline int32_t r4protocol_init(const R4ProtocolApi2 *api,R4ProtocolContext *out){R4OS2Protocol view;if(!out || R4OS2ProtocolInit(api,&view)!=0)return -1;out->api=api;return 0;}
static inline void r4protocol_log_info(const R4ProtocolContext *c,const uint8_t *text){c->api->log_info(text);}
static inline void r4protocol_log_warn(const R4ProtocolContext *c,const uint8_t *text){c->api->log_warn(text);}
static inline void r4protocol_log_error(const R4ProtocolContext *c,const uint8_t *text){c->api->log_error(text);}
static inline int32_t r4protocol_register(const R4ProtocolContext *c,const uint8_t *role,uint32_t category,uint32_t flags){return c->api->register_role(role,category,flags);}
static inline int32_t r4protocol_status(const R4ProtocolContext *c,uint32_t state,const uint8_t *note){return c->api->set_status(state,note);}
static inline int32_t r4protocol_dependency(const R4ProtocolContext *c,const uint8_t *role){return c->api->dependency_status(role);}
static inline void *r4protocol_alloc(const R4ProtocolContext *c,uint32_t bytes,uint32_t alignment){return c->api->alloc(bytes,alignment);}
/* All referencing dispatch/session/callback leases must have ended first. */
static inline void r4protocol_free(const R4ProtocolContext *c,void *p,uint32_t bytes){c->api->free(p,bytes);}
static inline int32_t r4protocol_file_read(const R4ProtocolContext *c,const uint8_t *path,uint8_t *out,uint32_t bytes){return c->api->file_read(path,out,bytes);}
/* Exact logical provider/session epochs, not kernel module generations or
 * hardware receipts. Caller serializes access as the original R4P call owner.
 * Never copy a live lease. Keep the gate at its exact address while leases
 * or receipts exist. Neither closing nor losing a lease releases backing. */
typedef struct R4ProtocolGate {uint64_t epoch;uint32_t active,phase;} R4ProtocolGate;
typedef struct R4ProtocolLease {R4ProtocolGate *owner;uint64_t epoch;uint32_t held;} R4ProtocolLease;
typedef struct R4ProtocolClosed {const R4ProtocolGate *owner;uint64_t epoch;} R4ProtocolClosed;
enum {R4PROTOCOL_GATE_BUSY=-1,R4PROTOCOL_GATE_CLOSED=-2,R4PROTOCOL_GATE_STALE=-3,R4PROTOCOL_GATE_EXHAUSTED=-4};
static inline int32_t r4protocol_gate_init(R4ProtocolGate *g,uint64_t epoch){if(!g || !epoch)return R4PROTOCOL_GATE_STALE;*g=(R4ProtocolGate){.epoch=epoch};return 0;}
static inline int32_t r4protocol_gate_enter(R4ProtocolGate *g,R4ProtocolLease *out){
 if(!g || !out || !g->epoch)return R4PROTOCOL_GATE_STALE;
 if(g->phase)return R4PROTOCOL_GATE_CLOSED;
 if(g->active==UINT32_MAX)return R4PROTOCOL_GATE_EXHAUSTED;
 ++g->active;*out=(R4ProtocolLease){.owner=g,.epoch=g->epoch,.held=1};return 0;
}
static inline int32_t r4protocol_lease_finish(R4ProtocolLease *l){
 if(!l || !l->held || !l->owner || l->owner->epoch!=l->epoch || !l->owner->active)return R4PROTOCOL_GATE_STALE;
 --l->owner->active;l->held=0;return 0;
}
static inline int32_t r4protocol_gate_close(R4ProtocolGate *g,R4ProtocolClosed *receipt){
 if(!g || !receipt || !g->epoch)return R4PROTOCOL_GATE_STALE;
 g->phase=1;if(g->active)return R4PROTOCOL_GATE_BUSY;
 g->phase=2;*receipt=(R4ProtocolClosed){.owner=g,.epoch=g->epoch};return 0;
}
static inline int32_t r4protocol_gate_reset(R4ProtocolGate *g,R4ProtocolClosed receipt,uint64_t next){
 if(!g || g->phase!=2 || g->active || receipt.owner!=g || receipt.epoch!=g->epoch || next<=g->epoch)return R4PROTOCOL_GATE_STALE;
 return r4protocol_gate_init(g,next);
}
#endif
