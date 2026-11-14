#ifndef R4OS_SDK_GUEST_CONTEXT2_H
#define R4OS_SDK_GUEST_CONTEXT2_H
#include <r4os/app2.h>
/* Caller-owned storage stays live through every borrowed facade and callback.
 * Never return a facade pointing into an initializer's own stack frame. */
static inline int32_t sdk_guest_app2(const R4XStartContext2 *raw,R4App2 *owner,R4App *facade) {
    int32_t rc=R4OS2ContextInit(raw,&owner->context);
    if(rc)return rc;
    rc=R4SdkApp2InitRaw(raw,&owner->memory);
    if(rc)return rc;
    owner->profile=0;
    return r4_app2_facade(owner,facade);
}
#endif
