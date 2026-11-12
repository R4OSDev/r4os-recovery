#include <r4os/r4os.h>
#include <r4os/facades.h>
int sdk54_c_resources(const R4XStartContext *context,const uint8_t *module_path) {
    R4App app;if(R4SdkAppFacade(context,&app))return 1;
    R4Resources resources=r4_app_resources(&app);R4CpuCapacity capacity={0};
    if(r4_resources_cpu_capacity(&resources,&capacity)||capacity.available_cpus!=4)return 2;
    uint64_t notification=0,old=0,now=0;
    if(r4_resources_notification_create(&resources,&notification)||!notification||r4_resources_notification_query(&resources,notification,&old)||r4_resources_notification_notify(&resources,notification,1)||r4_resources_notification_query(&resources,notification,&now)||old==now||r4_resources_notification_close(&resources,notification))return 3;
    R4VmRegion region;if(r4_resources_reserve_vm(&resources,8192,4096,R4OS_VM_REGION_FLAGS_DEFAULT,&region)||r4_vm_region_commit(&region,0,8192))return 4;
    R4ProgramVmRegionInfo info={0};if(r4_vm_region_query(&region,&info)||info.len<8192||!info.base)return 5;
    volatile uint8_t *memory=(volatile uint8_t *)(uintptr_t)info.base;memory[0]=0xa5;memory[8191]=0x5a;
    if(memory[0]!=0xa5||memory[8191]!=0x5a||r4_vm_region_decommit(&region,4096,4096)||r4_vm_region_release(&region)||r4_vm_region_valid(&region))return 6;
    static const uint8_t file[]="C:\\TEMP\\SDKRS54\\C54.BIN";R4PathZ path={file,sizeof(file)-1};
    static const uint8_t payload[]={0x44,0,0x54,0xa5};R4IoRequest io;
    if(r4_resources_async_write(&resources,path,payload,sizeof(payload),0,&io))return 7;
    if(r4_io_request_release_buffers(&io)!=R4OS_ERR_BUFFER_IN_USE)return 8;
    R4ResourceWait waited=r4_io_request_wait(&io,r4_timeout_forever());
    if(waited.kind!=R4_RESOURCE_WAIT_EXITED||io.last_info.result!=4||io.last_info.processed_bytes!=4||r4_io_request_close(&io)||r4_io_request_valid(&io))return 9;
    R4PathZ module={module_path,0};while(module_path[module.length])++module.length;
    R4Process child;if(r4_resources_spawn(&resources,module,"child-c",R4ABI_LAUNCH_POLICY_CONSOLE,&child))return 10;
    R4ResourceWait exited=r4_process_wait(&child,r4_timeout_forever());
    if(exited.kind!=R4_RESOURCE_WAIT_EXITED||exited.value!=43||r4_process_valid(&child))return 11;
    return 0;
}
