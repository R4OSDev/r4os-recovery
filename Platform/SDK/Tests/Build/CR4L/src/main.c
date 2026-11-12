#include "../Bindings/C/l66c.h"
typedef uint64_t (*Allocate)(uint64_t,uint64_t);
typedef int32_t (*Release)(uint64_t,uint64_t);
typedef int32_t (*Notify)(uint64_t,uint64_t,uint64_t);
int32_t l66c_open_impl(R4L66State *s,uint64_t owner,uint64_t generation,uint64_t allocate,uint64_t release,uint64_t notify){
 if(!s||!owner||!generation||!allocate||!release||!notify)return -1;
 if(s->active||s->in_callback)return -2;
 s->in_callback=1;uint64_t memory=((Allocate)(uintptr_t)allocate)(owner,16);s->in_callback=0;if(!memory)return -4;
 ((uint64_t*)(uintptr_t)memory)[0]=0x52344c36;((uint64_t*)(uintptr_t)memory)[1]=generation;
 s->owner=owner;s->generation=generation;s->operations=0;s->allocation=memory;
 s->allocate=allocate;s->release=release;s->notify=notify;s->active=1;s->in_callback=0;return 0;
}
int32_t l66c_work_impl(R4L66State *s,uint64_t generation,uint64_t value,uint64_t *output){
 if(!s||!output||!s->active)return -1;
 if(s->generation!=generation)return -3;if(s->in_callback)return -2;
 uint64_t owner=s->owner,memory=s->allocation,operations=s->operations;
 s->in_callback=1;int32_t rc=((Notify)(uintptr_t)s->notify)(owner,generation,value);
 if(s->owner!=owner||s->generation!=generation||s->allocation!=memory||!s->active||s->in_callback!=1)return -3;
 s->in_callback=0;if(rc)return rc;
 if(((uint64_t*)(uintptr_t)memory)[0]!=0x52344c36||((uint64_t*)(uintptr_t)memory)[1]!=generation)return -3;
 s->operations=operations+1;*output=value+operations+1+0x43;return 0;
}
int32_t l66c_close_impl(R4L66State *s,uint64_t generation){
 if(!s||!s->active)return -1;if(s->generation!=generation)return -3;if(s->in_callback)return -2;
 /* Keep the exact allocation if the caller's release has not acknowledged. */
 s->in_callback=1;int32_t rc=((Release)(uintptr_t)s->release)(s->owner,s->allocation);s->in_callback=0;
 if(rc)return rc;s->allocation=0;s->active=0;return 0;
}
R4L66ApiV1 l66c_api_v1 __attribute__((aligned(8),section(".data.r4l_exports")))={L66C_API_V1_HEADER_INITIALIZER,l66c_open_impl,l66c_work_impl,l66c_close_impl};
R4L_PROVIDER_QUERY(l66c_query);
