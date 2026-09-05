#ifndef R4OS_R4NET_H
#define R4OS_R4NET_H

#include "r4l.h"
#include "r4sys.h"

#ifdef __cplusplus
extern "C" {
#endif

/* R4NET is a built-in platform API provided by the kernel. It is resolved as
 * a group_interface import and has no R4L file. The table layout is declared
 * in <r4os/r4xstart.h> (R4XStartR4Net). */

typedef struct R4Net {
    const R4XStartR4Net *table;
} R4Net;

static inline int32_t r4net_init(const R4XStartContext *ctx, R4Net *out) {
    if (out == 0) return R4OS_ERROR_INVALID;
    out->table = 0;
    const R4XStartImport *item = r4xstart_find_import(ctx, R4L_GROUP_R4NET);
    if (item == 0 || item->table == 0) return R4OS_ERROR_NOT_FOUND;
    if ((item->flags & R4XSTART_IMPORT_FLAG_GROUP_INTERFACE) == 0) return R4OS_ERROR_NOT_FOUND;
    const R4XStartR4Net *table = (const R4XStartR4Net *)(uintptr_t)item->table;
    if (table->magic != R4XSTART_R4NET_MAGIC) return R4OS_ERROR_INVALID;
    if (table->abi_version < R4XSTART_R4NET_VERSION) return R4OS_ERROR_INVALID;
    /* R4NET grows append-only. Older kernels remain valid; callers must
     * check table->size before using a tail slot. */
    if (table->size < offsetof(R4XStartR4Net, tcp_connect) + sizeof(uintptr_t)) return R4OS_ERROR_INVALID;
    if (table->tcp_connect == 0) return R4OS_ERROR_INVALID;
    out->table = table;
    return R4OS_OK;
}

static inline int r4net_available(const R4Net *g) {
    return g != 0 && g->table != 0;
}

#ifdef __cplusplus
}
#endif

#endif
