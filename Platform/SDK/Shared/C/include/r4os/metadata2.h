#ifndef R4OS_METADATA2_H
#define R4OS_METADATA2_H
/* Thin inline Query2 access; no new SDK runtime symbols or legacy fallback.
 * Native callers retain context/code/path and exclusive whole outputs until
 * actual return. Only positive row count grants adoption; -10 discards every
 * assembled page. Contents on a batch error are unspecified. */
#include "platform2.h"

static inline int32_t R4SdkFileMetadata2(const R4OS2Context *context,const uint8_t *path,R4FileMetadata2 *out){
    if(!path||!out)return R4OS_FILE_METADATA2_ERROR_INVALID;
    uint64_t address=0;int32_t rc=R4OS2ContextFunction(context,1,offsetof(R4XStartR4Sys2,file_metadata2),&address);
    if(rc)return rc;
    return ((R4SysFileMetadata2Fn)(uintptr_t)address)(path,out);
}
static inline int32_t R4SdkDirectoryMetadata2Init(R4DirectoryMetadataCursor2 *out){
    if(!out)return R4OS_FILE_METADATA2_ERROR_INVALID;
    *out=(R4DirectoryMetadataCursor2){.version=1,.size=sizeof(*out),.scan={.version=1,.size=sizeof(R4DirectoryBatchCursor)}};
    return 0;
}
static inline int32_t R4SdkDirectoryMetadata2Batch(const R4OS2Context *context,const uint8_t *path,R4DirectoryMetadataCursor2 *cursor,R4DirectoryMetadataEntry2 *rows,uint32_t capacity){
    if(!cursor||capacity>R4OS_DIRECTORY_BATCH_MAX_ENTRIES||(capacity&&!rows))return R4OS_FILE_METADATA2_ERROR_INVALID;
    uint64_t address=0;int32_t rc=R4OS2ContextFunction(context,1,offsetof(R4XStartR4Sys2,directory_metadata_batch2),&address);
    if(rc)return rc;
    return ((R4SysDirectoryMetadataBatch2Fn)(uintptr_t)address)(path,cursor,rows,capacity);
}
static inline const R4FileIdentity2 *R4SdkFileMetadata2Identity(const R4FileMetadata2 *value){
    return value&&(value->flags&R4OS_FILE_METADATA2_FLAG_IDENTITY_VALID)?&value->identity:0;
}
#endif
