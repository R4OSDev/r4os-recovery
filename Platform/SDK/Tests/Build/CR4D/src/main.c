#include "r4os/driver_lifecycle.h"
#include "../../../Simulation/DriverLifecycle.c"
static R4SdkDriverContext ctx;
static const R4DriverApi *saved;
static _Alignas(4096) uint8_t bytes[4096];
static uint32_t irq_hits;
static uint32_t irq_handler(uint8_t irq,uintptr_t cookie){if(irq==0 && cookie==67)__atomic_fetch_add(&irq_hits,1,__ATOMIC_RELAXED);return 0;}
static int32_t work(uintptr_t value){return value==67?167:-1;}
static int32_t task(uintptr_t value){return value==67?267:-1;}
int32_t d67c_init(const R4DriverApi *api){
 saved=api;int32_t rc=r4driver_init(api,&ctx);if(rc)return rc;
 #define CHECK(x) do {if((x)!=0){api->log_error((const uint8_t *)"D67C failed: " #x);return -1;}} while(0)
 R4PciDeviceInfo pci={0};if(r4driver_result(R4SdkDriverContext_pciFindByClass(0,&ctx,2,0,0,&pci))<0)return -10;
 if(pci.vendor_id==0xffff)return -2;
 R4DriverDmaLease lease={.owner=&ctx,.pin={.version=1,.size=sizeof(R4DmaPinnedBuffer)},.mapping={.version=1,.size=sizeof(R4DmaMapping)}};
 CHECK(r4driver_result(R4SdkDriverContext_pinDmaBuffer(0,&ctx,bytes,sizeof(bytes),&lease.pin)));
 R4DmaConstraints constraints={.version=1,.size=sizeof(constraints),.dma_mask=0xffffffff,.boundary=4096,.max_segment_bytes=4096,.alignment=16,.max_segments=4,.flags=R4OS_DMA_FLAG_COHERENT|R4OS_DMA_FLAG_ALLOW_BOUNCE};
 CHECK(r4driver_result(R4SdkDriverContext_mapDmaPinned(0,&ctx,&lease.pin,&constraints,R4OS_DMA_DIRECTION_BIDIRECTIONAL,&lease.mapping)));
 R4DmaMapping stale=lease.mapping;
 CHECK(r4driver_result(R4SdkDriverContext_syncDmaForDevice(0,&ctx,&lease.mapping)));
 CHECK(r4driver_result(R4SdkDriverContext_syncDmaForCpu(0,&ctx,&lease.mapping)));
 CHECK(r4driver_dma_close_quiesced(&lease));
 if(r4driver_result(R4SdkDriverContext_syncDmaForCpu(0,&ctx,&stale))>=0)return -3;
 CHECK(r4driver_result(R4SdkDriverContext_irqRegister(0,&ctx,0,(uintptr_t)irq_handler,67,R4OS_IRQ_FLAG_SHARED)));
 R4SdkDriverContext_waitTicks(0,&ctx,3);
 CHECK(r4driver_result(R4SdkDriverContext_irqUnregister(0,&ctx,0,(uintptr_t)irq_handler,67)));
 if(!__atomic_load_n(&irq_hits,__ATOMIC_RELAXED))return -4;
 R4DriverWorkLease w={.owner=&ctx};CHECK(r4driver_result(R4SdkDriverContext_workSubmit(0,&ctx,(uintptr_t)work,67,0,&w.ticket)));
 int32_t result=0;if(r4driver_result(R4SdkDriverContext_completionWait(0,&ctx,w.ticket,200,&result))<0)return -11;if(result!=167)return -5;
 uint32_t stale_ticket=w.ticket;CHECK(r4driver_work_release_terminal(&w));R4DriverCompletionStatus status={.version=1,.size=sizeof(status)};
 if(r4driver_result(R4SdkDriverContext_completionStatus(0,&ctx,stale_ticket,&status))>=0)return -6;
 R4SdkDriverThreadsContext threads;R4SdkDriverSlot opt=R4SdkDriverContext_threads(0,&ctx,&threads);if(opt.status || !(opt.flags&1))return -7;
 uint64_t handle=0;CHECK(r4driver_result(R4SdkDriverThreadsContext_start(0,&threads,(uintptr_t)task,67,R4OS_DRIVER_THREAD_FLAG_PARALLEL,&handle)));
 CHECK(r4driver_result(R4SdkDriverThreadsContext_join(0,&threads,handle,200,&result)));if(result!=267)return -8;
 R4DriverThreadStatus ts={.version=1,.size=sizeof(ts)};CHECK(r4driver_result(R4SdkDriverThreadsContext_status(0,&threads,handle,&ts)));if(!ts.owner_epoch || !ts.task_generation)return -9;
 CHECK(r4driver_result(R4SdkDriverThreadsContext_release(0,&threads,handle)));
 CHECK(sdk67_backends_init(api,0));
 api->log_info((const uint8_t *)"PASS D67C init PCI DMA-stale IRQ-ended work-released task-generation hotremove-A B-alive");
 return 0;
}
int32_t d67c_shutdown(void){int32_t rc=sdk67_backends_shutdown();if(!rc)saved->log_info((const uint8_t *)"PASS D67C shutdown callbacks-closed=2");return rc;}
R4D_ENTRIES(d67c_init,d67c_shutdown);
