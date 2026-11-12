#ifndef R4OS_R4AUDIO_H
#define R4OS_R4AUDIO_H

#include "r4l.h"
#include "r4sys.h"

#ifdef __cplusplus
extern "C" {
#endif

/* R4AUDIO is a built-in platform API provided by the kernel. It is resolved
 * as a group_interface import and has no R4L file. The table layout is
 * declared in <r4os/r4xstart.h> (R4XStartR4Audio). */

typedef struct R4Audio {
    const R4XStartR4Audio *table;
    const R4OS2Context *generation2;
} R4Audio;

/* Each generation uses its own canonical offsets. The supplied Context2 is
 * borrowed through the actual calls; no legacy table or start is invented. */
static inline int r4audio_available(const R4Audio *value) {
    return value && (value->generation2 ? R4OS2ContextGroup(value->generation2, 5) != NULL : value->table != NULL);
}
static inline int r4audio_reaches(const R4Audio *value, size_t offset1, uint32_t offset2) {
    if (!value) return 0;
    if (value->generation2) {
        const R4XStartR4Audio2 *table = (const R4XStartR4Audio2 *)R4OS2ContextGroup(value->generation2, 5);
        return table && offset2 <= table->size && sizeof(uintptr_t) <= table->size - offset2;
    }
    return value->table && offset1 <= value->table->size && sizeof(uintptr_t) <= value->table->size - offset1;
}
static inline uintptr_t r4audio_callback(const R4Audio *value, size_t offset1, uint32_t offset2) {
    if (!value) return 0;
    if (value->generation2) {
        uint64_t address;
        return R4OS2ContextFunction(value->generation2, 5, offset2, &address) == 0 ? (uintptr_t)address : 0;
    }
    if (!r4audio_reaches(value, offset1, offset2)) return 0;
    return *(const uintptr_t *)((const uint8_t *)value->table + offset1);
}
#define R4AUDIO_REACHES(value, field) r4audio_reaches((value), offsetof(R4XStartR4Audio, field), offsetof(R4XStartR4Audio2, field))
#define R4AUDIO_SLOT(value, field) r4audio_callback((value), offsetof(R4XStartR4Audio, field), offsetof(R4XStartR4Audio2, field))
#define R4AUDIO_HAS(value, field) (R4AUDIO_SLOT((value), field) != 0)
static inline int32_t r4audio_init2(const R4OS2Context *context, R4Audio *out) {
    if (!out || !context || !R4OS2ContextGroup(context, 5)) return R4OS_ERR_NO_GROUP;
    *out = (R4Audio){.table = NULL, .generation2 = context};
    return 0;
}

static inline int32_t r4audio_init(const R4XStartContext *ctx, R4Audio *out) {
    if (out == 0) return R4OS_ERROR_INVALID;
    out->table = 0;
    out->generation2 = NULL;
    const R4XStartImport *item = r4xstart_find_import(ctx, R4L_GROUP_R4AUDIO);
    if (item == 0 || item->table == 0) return R4OS_ERROR_NOT_FOUND;
    if ((item->flags & R4XSTART_IMPORT_FLAG_GROUP_INTERFACE) == 0) return R4OS_ERROR_NOT_FOUND;
    const R4XStartR4Audio *table = (const R4XStartR4Audio *)(uintptr_t)item->table;
    if (table->magic != R4XSTART_R4AUDIO_MAGIC) return R4OS_ERROR_INVALID;
    if (table->abi_version < R4XSTART_R4AUDIO_VERSION) return R4OS_ERROR_INVALID;
    if (table->size < R4XSTART_R4AUDIO_SIZE) return R4OS_ERROR_INVALID;
    if (table->audio_open_stream == 0) return R4OS_ERROR_INVALID;
    out->table = table;
    return R4OS_OK;
}



/* outputs is scratch until result1; initialize receipt.version=1,size=sizeof.
 * The complete capture needs256 rows. Existing scalar enumeration is intact. */
static inline int32_t r4audio_output_catalog(const R4Audio *g,
    R4AudioOutputInfo *outputs, uint32_t capacity, R4AudioOutputCatalog *receipt) {
    if (!r4audio_available(g)) return R4OS_ERR_NO_GROUP;
    if (!R4AUDIO_REACHES(g, audio_output_catalog)
        || R4AUDIO_SLOT(g, audio_output_catalog) == 0) return R4OS_ERR_NO_FN;
    R4AudioAudioOutputCatalogFn callback = (R4AudioAudioOutputCatalogFn)(uintptr_t)R4AUDIO_SLOT(g, audio_output_catalog);
    return callback(outputs, capacity, receipt);
}

#ifdef __cplusplus
}
#endif

#endif
