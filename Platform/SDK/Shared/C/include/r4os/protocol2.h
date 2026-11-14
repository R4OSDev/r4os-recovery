#ifndef R4OS_PROTOCOL2_H
#define R4OS_PROTOCOL2_H
#include "r4os/protocol.h"
#include "r4os/technical2.h"
typedef struct R4Protocol2Context {const R4ProtocolApi2 *api;} R4Protocol2Context;
/* The original immutable loader table and actual PPI execution scope must
 * stay valid throughout every call. A cached table grants no other identity. */
static inline int32_t r4protocol2_init(R4Protocol2Context *out,const R4ProtocolApi2 *api){
 R4OS2Protocol view;
 if(!out || R4OS2ProtocolInit(api,&view))return -1;
 out->api=api;return 0;
}
static inline void r4protocol2_log_info(const R4Protocol2Context *c,const uint8_t *text){c->api->log_info(text);}
static inline void r4protocol2_log_warn(const R4Protocol2Context *c,const uint8_t *text){c->api->log_warn(text);}
static inline void r4protocol2_log_error(const R4Protocol2Context *c,const uint8_t *text){c->api->log_error(text);}
static inline int32_t r4protocol2_register(const R4Protocol2Context *c,const uint8_t *role,uint32_t category,uint32_t flags){return c->api->register_role(role,category,flags);}
static inline int32_t r4protocol2_status(const R4Protocol2Context *c,uint32_t state,const uint8_t *note){return c->api->set_status(state,note);}
static inline int32_t r4protocol2_dependency(const R4Protocol2Context *c,const uint8_t *role){return c->api->dependency_status(role);}
static inline void *r4protocol2_alloc(const R4Protocol2Context *c,uint32_t bytes,uint32_t alignment){return c->api->alloc(bytes,alignment);}
/* All referencing dispatch/session/callback leases must have ended first. */
static inline void r4protocol2_free(const R4Protocol2Context *c,void *p,uint32_t bytes){c->api->free(p,bytes);}
static inline int32_t r4protocol2_file_read(const R4Protocol2Context *c,const uint8_t *path,uint8_t *out,uint32_t bytes){if(bytes>INT32_MAX)return R4OS_FILE_STREAM_ERROR_TOO_LARGE;return c->api->file_read(path,out,bytes);}
#endif
