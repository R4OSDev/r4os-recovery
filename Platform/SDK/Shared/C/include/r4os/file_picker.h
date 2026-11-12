#ifndef R4OS_FILE_PICKER_H
#define R4OS_FILE_PICKER_H
#include "wire_helpers.h"
/* Private caller state; two disjoint whole aligned row buffers capacity4..256.
 * Context/provider/filter code and buffers outlive actual synchronous return.
 * Readable views must end before any mutable call. No concurrent mutation or
 * overlapping state/outputs/text/row ranges. Fields are not caller controls. */
enum { R4_PICKER_OPEN=1,R4_PICKER_SAVE=2,R4_PICKER_FILE=0,R4_PICKER_DIRECTORY=1,
       R4_PICKER_PREVIOUS=2,R4_PICKER_NEXT=3 };
enum { R4_PICKER_NONE=0,R4_PICKER_SELECTED=1,R4_PICKER_OVERWRITE=2,R4_PICKER_CANCELLED=3 };
enum { R4_PICKER_INVALID=-201,R4_PICKER_STORAGE=-202,R4_PICKER_BUSY=-203,
       R4_PICKER_INCOMPLETE=-204,R4_PICKER_PROVIDER=-205,R4_PICKER_CLOSED=-206,
       R4_PICKER_EXHAUSTED=-207,R4_PICKER_MISSING=-208,R4_PICKER_STALE=-10 };
enum { R4_PICKER_VIEW_COMPLETE=1,R4_PICKER_LOADING=2,R4_PICKER_IN_CALL=4,R4_PICKER_IS_CLOSED=8 };
typedef int32_t (*R4SdkFilePickerFilter)(void *,const R4DirectoryMetadataEntry2 *);
typedef struct R4SdkFilePickerProvider {
    R4SysFileMetadata2Fn info;R4SysDirectoryMetadataBatch2Fn batch;
    R4SdkFilePickerFilter filter;void *filter_context;
} R4SdkFilePickerProvider;
typedef struct R4SdkFilePickerRow {
    R4DirectoryMetadataEntry2 entry;uint32_t kind,reserved0;uint8_t label[256];
} R4SdkFilePickerRow;
typedef struct R4SdkFilePickerDecision {
    R4DirectoryMetadataEntry2 entry;uint32_t kind,reserved0;
} R4SdkFilePickerDecision;
typedef struct R4SdkFilePickerProgress {
    uint64_t revision,seen;uint32_t count,staged,number,selected,first_index,focus,pressed,flags;
    int32_t error_code;uint32_t reserved0;
} R4SdkFilePickerProgress;
typedef struct R4SdkFilePicker {
    R4SdkFilePickerProvider provider;R4SdkWireSpan active,candidate;
    R4DirectoryMetadataCursor2 active_cursor,candidate_cursor;
    uint8_t directory_path[1024],candidate_path[1024],extension[64],filename[768];
    R4SdkFilePickerDecision confirmed;R4FileMetadata2 candidate_info;
    uint64_t revision,seen;
    uint32_t capacity,count,staged,number,candidate_number,selected,first_index,focus,pressed,mode,phase,in_call;
    int32_t error_code;uint32_t overwrite_pending;
} R4SdkFilePicker;
int32_t R4SdkFilePickerInit(R4SdkWireSpan,R4SdkWireSpan,uint32_t,uint32_t,R4SdkWireSpan,R4SdkFilePickerProvider,R4SdkFilePicker *);
int32_t R4SdkFilePickerBegin(R4SdkFilePicker *,R4SdkWireSpan,uint32_t);
int32_t R4SdkFilePickerStep(R4SdkFilePicker *,uint32_t);
int32_t R4SdkFilePickerGetProgress(const R4SdkFilePicker *,R4SdkFilePickerProgress *);
int32_t R4SdkFilePickerView(const R4SdkFilePicker *,R4SdkWireSpan *);
int32_t R4SdkFilePickerSelect(R4SdkFilePicker *,uint64_t,uint32_t,uint32_t);
int32_t R4SdkFilePickerName(R4SdkFilePicker *,R4SdkWireSpan);
int32_t R4SdkFilePickerActivate(R4SdkFilePicker *,uint64_t,uint32_t,uint32_t,R4SdkFilePickerDecision *);
int32_t R4SdkFilePickerKey(R4SdkFilePicker *,uint8_t,uint32_t,R4SdkFilePickerDecision *);
int32_t R4SdkFilePickerFocus(R4SdkFilePicker *,uint32_t,uint32_t);
int32_t R4SdkFilePickerCancel(R4SdkFilePicker *,R4SdkFilePickerDecision *);
/* Step budget1..64 bounds provider CALLS, including hidden entries through real
 * EOF. It does not bound physical latency. Only EOF swaps the complete page;
 * errors/restart keep the old historical view and last confirmed selection.
 * View revision never wraps; identity is observed, not retained/opened.
 * Activate validates the old page and rereads whole identity, never old index.
 * Save of existing file requests OVERWRITE; approval requires that exact
 * previous whole path/identity, freshly revalidated. Begin, changed name or
 * selection, Cancel and successful confirmation end that approval. A missing
 * or replaced target returns STALE. Names are validated components; no writes,
 * automatic suffix/format or document ownership. Cancel logically closes;
 * BUSY never terminates active callback/code/buffer loans. */
_Static_assert(sizeof(R4SdkFilePickerProvider)==32u,"picker provider");
_Static_assert(sizeof(R4SdkFilePickerRow)==1400u,"picker row");
_Static_assert(sizeof(R4SdkFilePickerDecision)==1144u,"picker decision");
_Static_assert(sizeof(R4SdkFilePickerProgress)==56u,"picker progress");
_Static_assert(sizeof(R4SdkFilePicker)==8640u,"picker state");
_Static_assert(offsetof(R4SdkFilePicker,in_call)==8628u,"picker call guard");
#endif
