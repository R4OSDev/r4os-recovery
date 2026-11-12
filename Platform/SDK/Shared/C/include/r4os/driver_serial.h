#ifndef R4OS_DRIVER_SERIAL_H
#define R4OS_DRIVER_SERIAL_H
#include "r4dev.h"
/* Cached DriverApi37 table; every call still authenticates the exact owner. */
static inline int32_t r4driver_serial_register_port(const R4DriverSerialApi *t,const R4SerialBackend *d,uint64_t *out){if(!t||t->version!=1||t->size<offsetof(R4DriverSerialApi,register_port)+sizeof(uint64_t)||!t->register_port)return R4OS_ERR_NO_FN;typedef int32_t(*Callback)(const R4SerialBackend*,uint64_t*);return ((Callback)(uintptr_t)t->register_port)(d,out);}
static inline int32_t r4driver_serial_unregister_port(const R4DriverSerialApi *t,uint64_t registration){if(!t||t->version!=1||t->size<offsetof(R4DriverSerialApi,unregister_port)+sizeof(uint64_t)||!t->unregister_port)return R4OS_ERR_NO_FN;typedef int32_t(*Callback)(uint64_t);return ((Callback)(uintptr_t)t->unregister_port)(registration);}
static inline int32_t r4driver_serial_notify(const R4DriverSerialApi *t,uint64_t registration,uint32_t events){if(!t||t->version!=1||t->size<offsetof(R4DriverSerialApi,notify)+sizeof(uint64_t)||!t->notify)return R4OS_ERR_NO_FN;typedef int32_t(*Callback)(uint64_t,uint32_t);return ((Callback)(uintptr_t)t->notify)(registration,events);}
static inline int32_t r4driver_serial_admission(const R4DriverSerialApi *t,uint64_t registration){if(!t||t->version!=1||t->size<offsetof(R4DriverSerialApi,admission)+sizeof(uint64_t)||!t->admission)return R4OS_ERR_NO_FN;typedef int32_t(*Callback)(uint64_t);return ((Callback)(uintptr_t)t->admission)(registration);}
#endif
