/* Reuses EXAMPLE's real storage registration/recovery/removal contract.
 * Linked independently into each SDK test driver, never an installed module. */
#include "r4os/driver.h"
static R4SdkDriverContext backend_owner;
typedef struct {uint8_t bytes[4096];uint32_t closed,reads,generation;} Disk;
static Disk disks[2];
static R4StorageBackend backends[2];
static const uint8_t *names[2];
static uint32_t registered[2],completed;
static int32_t read_disk(void *p,uint64_t lba,uint32_t sectors,uint8_t *out,uint32_t len){
 Disk *s=p;if(!s || s->closed || lba>=8 || sectors>8-lba || len<sectors*512)return -1;
 for(uint32_t i=0;i<sectors*512;i++)out[i]=s->bytes[lba*512+i];s->reads++;return 0;
}
static int32_t write_disk(void *p,uint64_t lba,uint32_t sectors,const uint8_t *in,uint32_t len){
 Disk *s=p;if(!s || s->closed || lba>=8 || sectors>8-lba || len<sectors*512)return -1;
 for(uint32_t i=0;i<sectors*512;i++)s->bytes[lba*512+i]=in[i];return 0;
}
static int32_t flush_disk(void *p){return p && !((Disk *)p)->closed ? 0:-1;}
static int32_t close_disk(void *p){Disk *s=p;if(!s || s->closed)return -1;s->closed++;return 0;}
static int32_t status_disk(void *p,R4StorageBackendStatus *out){Disk *s=p;if(!s || !out)return -1;*out=(R4StorageBackendStatus){.state=s->closed?0:1};return 0;}
int32_t sdk67_backends_init(const R4DriverApi *api,uint32_t rust){
 if(r4driver_init(api,&backend_owner))return -101;
 names[0]=(const uint8_t *)(rust?"D67R-A":"D67C-A");names[1]=(const uint8_t *)(rust?"D67R-B":"D67C-B");
 for(uint32_t i=0;i<2;i++){
  disks[i].generation=i+1;
  backends[i]=(R4StorageBackend){.version=2,.size=sizeof(R4StorageBackend),.flags=R4OS_STORAGE_BACKEND_FLAG_REMOVABLE|R4OS_STORAGE_BACKEND_FLAG_WRITABLE,
   .source=R4OS_STORAGE_BACKEND_SOURCE_DISK,.bus=R4OS_STORAGE_BACKEND_BUS_RAM,.sector_size=512,.max_sectors_per_request=2,.queue_depth=1,.timeout_ticks=50,.sector_count=8,
   .context=&disks[i],.read=read_disk,.write=write_disk,.flush=flush_disk,.shutdown=close_disk,.status=status_disk};
  if(r4driver_result(R4SdkDriverContext_registerStorageBackend(0,&backend_owner,names[i],&backends[i]))<0)return -102;
  registered[i]=1;
 }
 if(r4driver_result(R4SdkDriverContext_registerStorageBackend(0,&backend_owner,names[0],&backends[0]))>=0)return -103;
 if(r4driver_result(R4SdkDriverContext_storageBackendRecoveryBegin(0,&backend_owner,names[0])))return -104;
 if(r4driver_result(R4SdkDriverContext_storageBackendRecoveryFinish(0,&backend_owner,names[0],1)))return -105;
 if(r4driver_result(R4SdkDriverContext_unregisterStorageBackend(0,&backend_owner,names[0])))return -106;
 registered[0]=0;
 if(disks[0].closed!=1 || disks[1].closed!=0 || disks[0].generation!=1 || disks[1].generation!=2)return -107;
 uint8_t b[512]={0};b[0]=67;
 if(write_disk(&disks[1],0,1,b,512) || read_disk(&disks[1],0,1,b,512) || b[0]!=67)return -108;
 completed=1;return 0;
}
int32_t sdk67_backends_shutdown(void){
 for(uint32_t i=0;i<2;i++)if(registered[i]){
  if(disks[i].closed==0){
   int32_t rc=-2;
   /* A controller worker can still hold a short registry pin. A refused
    * unregister restores admission; retain this exact descriptor/backing
    * and wait a bounded interval for the real retirement acknowledgement. */
   for(uint32_t attempt=0;attempt<64;attempt++){
    rc=r4driver_result(R4SdkDriverContext_unregisterStorageBackend(0,&backend_owner,names[i]));
    if(rc!=-2)break;
    R4SdkDriverContext_waitTicks(0,&backend_owner,1);
   }
   if(rc)return -109;
  }
  registered[i]=0;
 }
 return !completed || (disks[0].closed==1 && disks[1].closed==1) ? 0:-110;
}
