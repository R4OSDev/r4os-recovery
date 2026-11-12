#include <r4os/facades.h>
static int different(const void *left,const void *right,uintptr_t length){
    const uint8_t *a=left,*b=right;
    for(uintptr_t i=0;i<length;++i)if(a[i]!=b[i])return 1;
    return 0;
}
static int ok(R4SdkDataSlot s){return !s.status && !(s.flags&R4SDKDATA_NATIVE_ERROR);}
int32_t sdk_data_guest(const R4XStartContext *start,const uint8_t *archive,uintptr_t length,uint8_t *decoded,uintptr_t capacity,const uint8_t *plain){
    R4SdkDataContext context;R4SdkDataJsonDocument json;uint8_t depth[8];
    const uint8_t text[]="{\"n\":18446744073709551615,\"too\":18446744073709551616}";
    R4SdkDataSlot s=R4SdkData_open(0,&context,start);
    if(!ok(s) || s.bits!=1)return 1;
    if(!ok(R4SdkData_json(0,&json,&context,text,sizeof(text)-1,depth,sizeof(depth))))return 2;
    s=R4SdkDataJsonDocument_readU64(0,&json,(const uint8_t *)"n",1);
    if(!ok(s) || s.bits!=UINT64_MAX)return 3;
    s=R4SdkDataJsonDocument_readU64(0,&json,(const uint8_t *)"too",3);
    if(s.status || !(s.flags&R4SDKDATA_NATIVE_ERROR) || s.length!=11 || different(s.ptr,"BadDocument",11))return 4;
    R4SdkDataZipContext zip;R4SdkDataZipEntry entries[4];R4SdkDataZipInfo info;R4SdkDataZipWork work;R4SdkDataZipProgress progress;
    if(!ok(R4SdkData_zip(0,&context,&zip)))return 5;
    if(!ok(R4SdkDataZipContext_inspect(0,&zip,archive,length,entries,4,&info)) || R4SdkDataZipInfo_get_files(&info).bits!=1)return 6;
    if(!ok(R4SdkDataZipContext_begin(0,&zip,archive,length,&entries[0],decoded,capacity,&work,&progress)))return 7;
    for(uint32_t i=0;i<128 && !R4SdkDataZipProgress_get_done(&progress).bits;++i){
        if(!ok(R4SdkDataZipContext_step(0,&zip,&work,4096,&progress)))return 8;
    }
    if(R4SdkDataZipProgress_get_done(&progress).bits!=1 || R4SdkDataZipProgress_get_written(&progress).bits!=capacity || different(decoded,plain,capacity))return 9;
    return 0;
}
