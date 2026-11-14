#ifndef R4OS_R4NET_H
#define R4OS_R4NET_H

#include "r4l.h"
#include "r4sys.h"

#ifdef __cplusplus
extern "C" {
#endif

/* R4NET is a built-in platform API provided by the kernel. It is resolved as
 * a group_interface import and has no R4L file. The table layout is declared
 * in <r4os/r4xstart.h> (R4XStartR4Net2). */

typedef struct R4Net {
    const R4XStartR4Net2 *table;
    const R4OS2Context *generation2;
} R4Net;

/* Both current table loans use the same canonical offsets. The supplied Context2 is
 * borrowed through the actual calls; no legacy table or start is invented. */
static inline int r4net_available(const R4Net *value) {
    return value && (value->generation2 ? R4OS2ContextGroup(value->generation2, 4) != NULL : (value->table && value->table->magic == R4OS2_R4NET_MAGIC && value->table->abi_version >= 1 && value->table->size >= 16));
}
static inline int r4net_reaches(const R4Net *value, size_t offset) {
    if (!value || offset > UINT32_MAX) return 0;
    if (value->generation2) {
        const R4XStartR4Net2 *table = (const R4XStartR4Net2 *)R4OS2ContextGroup(value->generation2, 4);
        return table && offset <= table->size && sizeof(uintptr_t) <= table->size - offset;
    }
    return (value->table && value->table->magic == R4OS2_R4NET_MAGIC && value->table->abi_version >= 1 && value->table->size >= 16) && offset <= value->table->size && sizeof(uintptr_t) <= value->table->size - offset;
}
static inline uintptr_t r4net_callback(const R4Net *value, size_t offset) {
    if (!value || offset > UINT32_MAX) return 0;
    if (value->generation2) {
        uint64_t address;
        return R4OS2ContextFunction(value->generation2, 4, offset, &address) == 0 ? (uintptr_t)address : 0;
    }
    if (!r4net_reaches(value, offset)) return 0;
    return *(const uintptr_t *)((const uint8_t *)value->table + offset);
}
#define R4NET_REACHES(value, field) r4net_reaches((value), offsetof(R4XStartR4Net2, field))
#define R4NET_SLOT(value, field) r4net_callback((value), offsetof(R4XStartR4Net2, field))
#define R4NET_HAS(value, field) (R4NET_SLOT((value), field) != 0)
static inline int32_t r4net_init2(const R4OS2Context *context, R4Net *out) {
    if (!out || !context || !R4OS2ContextGroup(context, 4)) return R4OS_ERR_NO_GROUP;
    *out = (R4Net){.table = NULL, .generation2 = context};
    return 0;
}

static inline int32_t r4net_init(const R4XStartContext2 *ctx, R4Net *out) {
    if (out == 0) return R4OS_ERROR_INVALID;
    out->table = 0;
    out->generation2 = NULL;
    const R4XStartImport *item = r4xstart_find_import(ctx, R4L_GROUP_R4NET);
    if (item == 0 || item->table == 0) return R4OS_ERROR_NOT_FOUND;
    if ((item->flags & R4XSTART_IMPORT_FLAG_GROUP_INTERFACE) == 0) return R4OS_ERROR_NOT_FOUND;
    const R4XStartR4Net2 *table = (const R4XStartR4Net2 *)(uintptr_t)item->table;
    if (table->magic != R4OS2_R4NET_MAGIC) return R4OS_ERROR_INVALID;
    if (table->abi_version < R4OS2_R4NET_VERSION) return R4OS_ERROR_INVALID;
    /* R4NET grows append-only. Older kernels remain valid; callers must
     * check table->size before using a tail slot. */
    if (table->size < offsetof(R4XStartR4Net2, tcp_connect) + sizeof(uintptr_t)) return R4OS_ERROR_INVALID;
    if (table->tcp_connect == 0) return R4OS_ERROR_INVALID;
    out->table = table;
    return R4OS_OK;
}



#ifdef __cplusplus
}
#endif

#endif
