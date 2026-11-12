#include <r4os/storage_helpers.h>
uint64_t SDKStorageCodecC(void){
    R4FilePath path;
    const uint8_t valid[]="C:\\\xf0\x9f\x99\x82.TXT";
    const uint8_t invalid[]="C:\\\xf4\x90\x80\x80.TXT";
    if(r4_file_path(valid,sizeof(valid)-1,&path)!=R4_PATH_OK ||
       r4_file_path(invalid,sizeof(invalid)-1,&path)!=R4_PATH_INVALID_CHARACTER)return 0;
    uint8_t scratch[64*1024],bytes[4096];uintptr_t length=0;
    const uint8_t count[4]={42,0,0,0},enabled[1]={1};
    const R4HiveBuildValue values[]={
        {(const uint8_t *)"SYSTEM\\Config",13,(const uint8_t *)"Count",5,R4OS_REGISTRY_VALUE_TYPE_U32,count,4},
        {(const uint8_t *)"SYSTEM\\Config",13,(const uint8_t *)"Enabled",7,R4OS_REGISTRY_VALUE_TYPE_BOOL,enabled,1}
    };
    if(R4SdkHiveBuild(1,UINT64_C(0x1122334455667788),values,2,scratch,sizeof(scratch),bytes,sizeof(bytes),&length))return 0;
    R4HiveView hive;uint32_t key,value;R4HiveValue found;
    if(R4SdkHiveParse(bytes,length,&hive)||hive.header.generation!=UINT64_C(0x1122334455667788)||R4SdkHiveFind(&hive,0,0,(const uint8_t *)"SYSTEM\\Config",13,&key)!=1||
       R4SdkHiveFind(&hive,2,key,(const uint8_t *)"Count",5,&value)!=1||R4SdkHiveValue(&hive,value,&found)!=1||found.value_type!=2||found.data_len!=4||found.data[0]!=42)return 0;
    uint64_t hash=UINT64_C(0xcbf29ce484222325);for(uintptr_t n=0;n<length;++n)hash=(hash^bytes[n])*UINT64_C(0x100000001b3);return hash;
}
