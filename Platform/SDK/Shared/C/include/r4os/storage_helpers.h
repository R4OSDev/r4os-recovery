#ifndef R4OS_STORAGE_HELPERS_H
#define R4OS_STORAGE_HELPERS_H
#include "app_storage.h"

/* Caller-owned SDK helpers. Provider/context and every borrowed buffer must
 * remain live through a call. Hive views additionally pin immutable input
 * until their final use; callers must not modify their validated fields. */
enum { R4_SAVE_SAVED=0, R4_SAVE_BACKUP_RETAINED=1, R4_SAVE_FAILED=2, R4_SAVE_COPIES_RETAINED=3 };
int32_t R4SdkDocumentSave(const R4Sys *, uint32_t *sequence, const uint8_t *path, uintptr_t path_len, const uint8_t *bytes, uintptr_t length, int32_t require_absent);
typedef struct R4RecentEntry {
    uint8_t path[R4OS_FILE_PATH_MAX_BYTES+1u];
    uint8_t app[32];
    uint8_t title[64];
} R4RecentEntry;
int32_t R4SdkRecentRead(const R4Sys *, R4RecentEntry *, uintptr_t capacity);
int32_t R4SdkRecentAdd(const R4Sys *, const uint8_t *path, uintptr_t path_len, const uint8_t *app, uintptr_t app_len);
int32_t R4SdkTextValid(const uint8_t *, uintptr_t);
int32_t R4SdkTextAssign(uint8_t *, uintptr_t, const uint8_t *, uintptr_t);
int32_t R4SdkTextLabel(uint8_t *, uintptr_t, const uint8_t *, uintptr_t);
int32_t R4SdkTextPrefix(const uint8_t *, uintptr_t, uintptr_t capacity, int32_t truncated, uintptr_t *prefix);
/* Current R4STD extended-grapheme byte boundaries, without normalization or
 * display-width policy. Offsets clamp to length, as at the original owner.
 * Return 1 on success; failure leaves the output offset unchanged. */
int32_t R4SdkTextNext(const uint8_t *, uintptr_t, uintptr_t offset, uintptr_t *next);
int32_t R4SdkTextPrevious(const uint8_t *, uintptr_t, uintptr_t offset, uintptr_t *previous);
typedef struct R4RegistryTestPaths {const uint8_t *hive,*tmp,*bak,*original,*stage,*displaced;} R4RegistryTestPaths;
/* operation 0: private-image marker; 1: backup (-1 indeterminate, 0 absent,
 * 1 verified original); 2: restore (0/1). Serialize diagnostics and retain
 * these exact admitted paths/buffers. This is not a general cleanup API. */
int32_t R4SdkRegistrySelfTest(const R4Sys *,int32_t operation,const R4RegistryTestPaths *,int32_t had_original,uint8_t *original,uintptr_t original_len,uint8_t *check,uintptr_t check_len);

typedef struct R4HiveHeader {
    uint16_t hive_kind;
    uint64_t generation;
    uint32_t key_table_offset, key_count, value_table_offset, value_count;
    uint32_t string_heap_offset, string_heap_size, data_heap_offset, data_heap_size;
    uint32_t checksum_type, checksum;
} R4HiveHeader;
typedef struct R4HiveView { const uint8_t *bytes; uintptr_t length; R4HiveHeader header; } R4HiveView;
typedef struct R4HiveKey {
    uint32_t parent_index, first_value_index, value_count, first_child_index, child_count;
    const uint8_t *name; uintptr_t name_len;
} R4HiveKey;
typedef struct R4HiveValue {
    uint32_t owner_key_index; uint16_t value_type;
    const uint8_t *name; uintptr_t name_len;
    const uint8_t *data; uintptr_t data_len;
} R4HiveValue;
typedef struct R4HiveBuildValue {
    const uint8_t *key; uintptr_t key_len;
    const uint8_t *name; uintptr_t name_len;
    uint16_t value_type;
    const uint8_t *data; uintptr_t data_len;
} R4HiveBuildValue;
/* Error codes are stable SDK-local values, independent of Zig error-set IDs.
 * 0 succeeds, 1 means found, -25 means output capacity, -22 scratch exhaustion. */
int32_t R4SdkHiveParse(const uint8_t *, uintptr_t, R4HiveView *);
int32_t R4SdkHiveKey(const R4HiveView *, uint32_t, R4HiveKey *);
int32_t R4SdkHiveValue(const R4HiveView *, uint32_t, R4HiveValue *);
int32_t R4SdkHiveFind(const R4HiveView *, int32_t operation, uint32_t parent, const uint8_t *, uintptr_t, uint32_t *index);
int32_t R4SdkHiveBuild(uint16_t kind, uint64_t generation, const R4HiveBuildValue *, uintptr_t count, uint8_t *scratch, uintptr_t scratch_len, uint8_t *out, uintptr_t capacity, uintptr_t *written);
int32_t R4SdkHiveText(int32_t import_text, uint64_t generation, const uint8_t *, uintptr_t, uint8_t *scratch, uintptr_t scratch_len, uint8_t *out, uintptr_t capacity, uintptr_t *written);
#endif
