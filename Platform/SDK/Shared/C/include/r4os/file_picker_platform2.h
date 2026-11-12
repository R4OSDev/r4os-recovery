#ifndef R4OS_FILE_PICKER_PLATFORM2_H
#define R4OS_FILE_PICKER_PLATFORM2_H
/* Inline bindings stay outside facades.h to avoid unbacked extern symbols. */
#include "platform2.h"
#include "file_picker.h"
static inline int32_t R4SdkFilePickerProvider2(const R4OS2Context *context,R4SdkFilePickerProvider *out){
 if(!out)return R4_PICKER_INVALID;
 uint64_t info=0,batch=0;
 int32_t rc=R4OS2ContextFunction(context,1,offsetof(R4XStartR4Sys2,file_metadata2),&info);if(rc)return rc;
 rc=R4OS2ContextFunction(context,1,offsetof(R4XStartR4Sys2,directory_metadata_batch2),&batch);if(rc)return rc;
 *out=(R4SdkFilePickerProvider){.info=(R4SysFileMetadata2Fn)(uintptr_t)info,.batch=(R4SysDirectoryMetadataBatch2Fn)(uintptr_t)batch};return 0;
}
#endif
