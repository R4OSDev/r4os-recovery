#ifndef R4OS_STARTUP_H
#define R4OS_STARTUP_H
#include "r4l.h"

/* SDK-local module bootstrap, once after validated app entry and before
 * workers/callbacks. Copies the same optional resident entropy functions as
 * Zig startup; absence remains unavailable. Not a platform ABI extension. */
int32_t R4SdkBindProgramEntropy(const R4XStartContext *);

/* SDK-owned generated manifest facts, not another platform ABI table. */
typedef struct R4StartupImport {
    const char *module_name;
    const char *symbol_name;
    uint32_t minimum;
    uint32_t optional;
    uint32_t group_id;
    uint32_t magic;
    uint32_t version;
    uint32_t size;
} R4StartupImport;
typedef struct R4StartupInfo {
    R4AppProfile profile;
    uint32_t app_class;
    uint32_t required_groups;
    uint32_t import_count;
    const R4StartupImport *imports;
} R4StartupInfo;

/* Loader-owned context/imports/common group headers stay resident throughout
 * this exact entry. Named R4L table semantics remain with its local resolver. */
static inline int32_t r4xstart_validate_declared(const R4XStartContext *ctx, const R4StartupInfo *info) {
    if (ctx == 0 || info == 0 || ((uintptr_t)ctx % _Alignof(R4XStartContext)) != 0 ||
        !r4xstart_context_valid(ctx) || ctx->abi_minor < R4XSTART_ABI_MINOR ||
        ctx->app_class != info->app_class || (ctx->flags & R4XSTART_FLAG_IMPORTS_VALID) == 0) return -12;
    if (ctx->import_count != info->import_count ||
        (ctx->import_count != 0 && (ctx->imports == 0 || info->imports == 0)) ||
        (ctx->imports % _Alignof(R4XStartImport)) != 0) return -13;
    const uint64_t bytes = (uint64_t)ctx->import_count * sizeof(R4XStartImport);
    if (ctx->imports > UINT64_MAX - bytes) return -13;
    if (ctx->args_len > PTRDIFF_MAX || (ctx->args_len != 0 && ctx->args == 0) ||
        ctx->args > UINT64_MAX - ctx->args_len) return -13;
    uint32_t groups = 0;
    for (uint32_t i = 0; i < ctx->import_count; ++i) {
        const R4XStartImport *actual = r4xstart_import_at(ctx, i);
        const R4StartupImport *expected = &info->imports[i];
        if (expected->minimum == 0 || actual->min_version != expected->minimum ||
            actual->group_id != expected->group_id ||
            !r4xstart_import_name_equal(actual->module_name, expected->module_name) ||
            !r4xstart_import_name_equal(actual->symbol_name, expected->symbol_name)) return -14;
        if (actual->table == 0) {
            if (!expected->optional || expected->group_id != 0 || actual->resolved_version != 0 || actual->flags != 0) return -14;
            continue;
        }
        if (actual->resolved_version < expected->minimum) return -14;
        if (expected->group_id == 0) {
            if (actual->flags != 0) return -14;
            continue;
        }
        if (expected->optional || expected->group_id >= 32 ||
            actual->flags != R4XSTART_IMPORT_FLAG_GROUP_INTERFACE ||
            actual->table % sizeof(uint64_t) != 0 || expected->size < 16) return -14;
        const uint32_t *header = (const uint32_t *)(uintptr_t)actual->table;
        if (header[0] != expected->magic || header[1] < expected->version || header[2] < expected->size) return -15;
        groups |= 1u << expected->group_id;
    }
    return (groups & info->required_groups) == info->required_groups ? R4OS_OK : -15;
}
#endif
