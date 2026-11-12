#include <assert.h>
#include <stdio.h>
#include "r4os/driver_lifecycle.h"
static int unmaps,unpins,releases,terminal;
static int32_t unmap(R4DmaMapping *m){assert(m->handle==31);unmaps++;if(unmaps==1)return -6;m->handle=0;return 0;}
static int32_t unpin(R4DmaPinnedBuffer *p){assert(p->handle==17);assert(unmaps==2);unpins++;p->handle=0;return 0;}
static int32_t status(uint32_t handle,R4DriverCompletionStatus *s){assert(handle==19);s->state=terminal?R4OS_DRIVER_WORK_STATE_COMPLETED:1;return 0;}
static int32_t release(uint32_t handle){assert(handle==19);assert(terminal);return ++releases==1?-6:0;}
int main(void){
 R4DriverApi api={.magic=R4OS_DRIVER_MAGIC,.version=R4OS_DRIVER_API_VERSION,.size=sizeof(api),.dma_unmap=unmap,.dma_unpin_buffer=unpin,.driver_completion_status=status,.driver_completion_release=release};
 R4SdkDriverContext ctx;
 assert(r4driver_init(0,&ctx)<0);api.size=16;assert(r4driver_init(&api,&ctx)<0);api.size=sizeof(api);
 assert(r4driver_init(&api,&ctx)==0);
 R4DriverDmaLease d={.owner=&ctx,.pin={.version=1,.size=sizeof(d.pin),.handle=17},.mapping={.version=1,.size=sizeof(d.mapping),.handle=31,.pin_handle=17}};
 assert(r4driver_dma_close_quiesced(&d)==-6);assert(d.mapping.handle==31 && d.pin.handle==17 && unpins==0);
 assert(r4driver_dma_close_quiesced(&d)==0);assert(!d.mapping.handle && !d.pin.handle && unpins==1);
 assert(r4driver_dma_close_quiesced(&d)==0 && unpins==1);
 R4DriverWorkLease w={.owner=&ctx,.ticket=19};
 assert(r4driver_work_release_terminal(&w)==R4OS_DRIVER_WORK_OWNER_BUSY && w.ticket==19 && releases==0);
 terminal=1;assert(r4driver_work_release_terminal(&w)==-6 && w.ticket==19);
 assert(r4driver_work_release_terminal(&w)==0 && w.ticket==0 && releases==2);
 puts("PASS Driver67 native current-header DMA-refusal-kept pin-after-unmap pending-work-kept release-refusal-kept retry-once");return 0;
}
/* Same refusal oracle reached through Rust's independent ownership types. */
static int irq_closes;
static int32_t pin_mock(uint64_t address,uint32_t bytes,uint32_t flags,R4DmaPinnedBuffer *out){*out=(R4DmaPinnedBuffer){.version=1,.size=sizeof(*out),.handle=17,.virt_addr=address,.bytes=bytes,.flags=flags};return 0;}
static int32_t map_mock(const R4DmaPinnedBuffer *pin,const R4DmaConstraints *constraints,uint32_t direction,R4DmaMapping *out){(void)constraints;assert(pin->handle==17);*out=(R4DmaMapping){.version=1,.size=sizeof(*out),.handle=31,.pin_handle=17,.direction=direction};return 0;}
static int32_t work_mock(int32_t (*handler)(uintptr_t),uintptr_t context,uint32_t flags,uint32_t *out){(void)handler;(void)context;(void)flags;*out=19;return 0;}
static int32_t irq_mock(uint8_t line,uint32_t (*handler)(uint8_t,uintptr_t),uintptr_t context,uint32_t flags){(void)handler;assert(line==9 && context==71 && flags==1);return 0;}
static int32_t irq_close_mock(uint8_t line,uint32_t (*handler)(uint8_t,uintptr_t),uintptr_t context){(void)handler;assert(line==9 && context==71);return ++irq_closes==1?-6:0;}
const R4DriverApi *sdk67_driver_oracle(void){
 static R4DriverApi api;
 api=(R4DriverApi){.magic=R4OS_DRIVER_MAGIC,.version=R4OS_DRIVER_API_VERSION,.size=sizeof(api),.dma_pin_buffer=pin_mock,.dma_map_pinned=map_mock,.dma_unmap=unmap,.dma_unpin_buffer=unpin,
  .driver_work_submit=work_mock,.driver_completion_status=status,.driver_completion_release=release,.irq_register=irq_mock,.irq_unregister=irq_close_mock};
 unmaps=unpins=releases=terminal=irq_closes=0;return &api;
}
void sdk67_driver_terminal(void){terminal=1;}
uint32_t sdk67_driver_counts(void){return (uint32_t)(unmaps+16*unpins+256*releases+4096*irq_closes);}
