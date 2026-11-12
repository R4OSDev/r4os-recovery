#include <r4os/r4os.h>
static int equal(const uint8_t *bytes,const char *name,uint32_t cap){uint32_t i=0;for(;i<cap && name[i];i++)if(bytes[i]!=(uint8_t)name[i])return 0;return i<cap && !bytes[i] && !name[i];}
int32_t r4_app_main(R4App *app){
 R4Storage s={.system=&app->system};R4StorageInventory inventory;
 if(r4_storage_inventory(&s,&inventory))return -1;
 R4StorageDeviceInfo disks[2];uint32_t seen=0;
 for(uint32_t i=0;i<inventory.device_slots;i++){
  R4StorageDeviceInfo d;int32_t found=r4_storage_device(&s,inventory.generation,i,&d);if(found<0)return -10;if(found==0)continue;
  if(equal(d.name,"D67C-A",32)||equal(d.name,"D67R-A",32)||equal(d.model,"D67C-A",64)||equal(d.model,"D67R-A",64))return -2;
  int which=(equal(d.name,"D67C-B",32)||equal(d.model,"D67C-B",64))?0:(equal(d.name,"D67R-B",32)||equal(d.model,"D67R-B",64))?1:-1;
  if(which<0)continue;
  if(d.bus!=R4OS_STORAGE_BACKEND_BUS_RAM || d.sector_count!=8 || d.sector_bytes!=512 || (seen&(1u<<which)))return -3;
  disks[which]=d;seen|=1u<<which;
 }
 if(seen!=3)return -4;
 if(!disks[0].reference.generation || !disks[1].reference.generation || disks[0].reference.slot==disks[1].reference.slot)return -11;
 uint8_t bytes[512];
 for(uint32_t i=0;i<2;i++){
  R4StorageTarget target=r4_storage_whole_device(&disks[i]);
  if(r4_storage_read(&s,&target,0,bytes,sizeof(bytes)) || bytes[0]!=67)return -5;
 }
 for(uint32_t i=0;i<2;i++){
  R4StorageTarget target=r4_storage_whole_device(&disks[i]);uint64_t claim=0;
  int32_t rc=r4_storage_claim_begin(&s,&target,&claim);if(rc || !claim)return -6;
  for(uint32_t b=0;b<512;b++)bytes[b]=(uint8_t)(i+71+b);
  rc=r4_storage_claim_write(&s,claim,0,bytes,sizeof(bytes));
  if(!rc)rc=r4_storage_claim_flush(&s,claim);
  int32_t end=r4_storage_claim_end(&s,&claim,1);if(rc || end || claim)return -7;
 }
 if(r4_storage_inventory(&s,&inventory))return -12;
 for(uint32_t i=0;i<2;i++){
  R4StorageDeviceInfo fresh;
  if(r4_storage_device(&s,inventory.generation,disks[i].reference.slot,&fresh)!=R4OS_STORAGE_RESULT_PRESENT || fresh.reference.generation!=disks[i].reference.generation)return -13;
  R4StorageTarget target=r4_storage_whole_device(&fresh);
  if(r4_storage_read(&s,&target,0,bytes,sizeof(bytes)))return -8;
  for(uint32_t b=0;b<512;b++)if(bytes[b]!=(uint8_t)(i+71+b))return -9;
 }
 r4sys_write_cstr(&app->system,"PASS Driver67 real storage IO C-B/R-B distinct patterns after hotremove A; exact claims ended\n");
 return 0;
}
