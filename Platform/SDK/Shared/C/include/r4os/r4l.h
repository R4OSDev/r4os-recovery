#ifndef R4OS_R4L_H
#define R4OS_R4L_H

#include <stddef.h>
#include <stdint.h>

#include "r4xstart.h"

#define R4L_INTERFACE_MAGIC 0x31493452u
#define R4L_INTERFACE_HEADER_VERSION 1u
#define R4L_INTERFACE_HEADER_SIZE 32u
#define R4L_INTERFACE_ALIGNMENT 8u
#define R4L_INTERFACE_REQUIRED_FLAG_MASK 0x00ffu

#define R4L_BINDING_OK 0
#define R4L_BINDING_INVALID_IMPORT (-1001)
#define R4L_BINDING_MANIFEST_REVISION_TOO_OLD (-1002)
#define R4L_BINDING_MISALIGNED_TABLE (-1003)
#define R4L_BINDING_BAD_MAGIC (-1004)
#define R4L_BINDING_UNSUPPORTED_HEADER (-1005)
#define R4L_BINDING_UNKNOWN_REQUIRED_FLAGS (-1006)
#define R4L_BINDING_INVALID_TABLE_SIZE (-1007)
#define R4L_BINDING_WRONG_INTERFACE (-1008)
#define R4L_BINDING_WRONG_MAJOR (-1009)
#define R4L_BINDING_INVALID_REVISION (-1010)
#define R4L_BINDING_REVISION_DRIFT (-1011)
#define R4L_BINDING_REVISION_TOO_OLD (-1012)
#define R4L_BINDING_TABLE_TOO_SMALL (-1013)
#define R4L_BINDING_INVALID_EXPECTATION (-1014)

typedef struct R4LInterfaceHeader {
    uint32_t magic;
    uint16_t header_version;
    uint16_t flags;
    uint32_t size;
    uint16_t abi_major;
    uint16_t abi_minor;
    uint64_t interface_id_lo;
    uint64_t interface_id_hi;
} R4LInterfaceHeader;

typedef struct R4LInterfaceExpectation {
    uint64_t interface_id_lo;
    uint64_t interface_id_hi;
    uint16_t abi_major;
    uint16_t min_revision;
    uint32_t required_size;
    uint16_t known_required_flags;
    uint16_t reserved;
} R4LInterfaceExpectation;

_Static_assert(sizeof(R4LInterfaceHeader) == R4L_INTERFACE_HEADER_SIZE, "R4LInterfaceHeader size mismatch");
_Static_assert(offsetof(R4LInterfaceHeader, magic) == 0u, "R4LInterfaceHeader.magic offset mismatch");
_Static_assert(offsetof(R4LInterfaceHeader, header_version) == 4u, "R4LInterfaceHeader.header_version offset mismatch");
_Static_assert(offsetof(R4LInterfaceHeader, flags) == 6u, "R4LInterfaceHeader.flags offset mismatch");
_Static_assert(offsetof(R4LInterfaceHeader, size) == 8u, "R4LInterfaceHeader.size offset mismatch");
_Static_assert(offsetof(R4LInterfaceHeader, abi_major) == 12u, "R4LInterfaceHeader.abi_major offset mismatch");
_Static_assert(offsetof(R4LInterfaceHeader, abi_minor) == 14u, "R4LInterfaceHeader.abi_minor offset mismatch");
_Static_assert(offsetof(R4LInterfaceHeader, interface_id_lo) == 16u, "R4LInterfaceHeader.interface_id_lo offset mismatch");
_Static_assert(offsetof(R4LInterfaceHeader, interface_id_hi) == 24u, "R4LInterfaceHeader.interface_id_hi offset mismatch");

static inline int r4xstart_context_valid(const R4XStartContext *ctx) {
    return ctx != 0 &&
        ctx->magic == R4XSTART_MAGIC &&
        ctx->abi_major == R4XSTART_ABI_MAJOR &&
        ctx->size >= R4XSTART_CONTEXT_SIZE;
}

static inline const uint8_t *r4xstart_args(const R4XStartContext *ctx) {
    if (ctx == 0 || ctx->args == 0 || ctx->args_len == 0) return 0;
    return (const uint8_t *)(uintptr_t)ctx->args;
}

static inline uint32_t r4xstart_import_count(const R4XStartContext *ctx) {
    if (ctx == 0 || (ctx->flags & R4XSTART_FLAG_IMPORTS_VALID) == 0) return 0;
    return ctx->import_count;
}

static inline const R4XStartImport *r4xstart_import_at(const R4XStartContext *ctx, uint32_t index) {
    if (ctx == 0 || ctx->imports == 0 || index >= r4xstart_import_count(ctx)) return 0;
    const R4XStartImport *imports = (const R4XStartImport *)(uintptr_t)ctx->imports;
    return &imports[index];
}

static inline uint8_t r4xstart_name_upper(uint8_t value) {
    return value >= (uint8_t)'a' && value <= (uint8_t)'z'
        ? (uint8_t)(value - ((uint8_t)'a' - (uint8_t)'A'))
        : value;
}

static inline int r4xstart_import_name_equal(uint64_t raw, const char *expected) {
    if (raw == 0 || expected == 0 || expected[0] == 0) return 0;
    const uint8_t *value = (const uint8_t *)(uintptr_t)raw;
    uint32_t index = 0;
    while (index < 31u && expected[index] != 0) {
        if (value[index] == 0 ||
            r4xstart_name_upper(value[index]) != r4xstart_name_upper((uint8_t)expected[index])) return 0;
        index += 1u;
    }
    return index < 32u && expected[index] == 0 && value[index] == 0;
}

static inline const R4XStartImport *r4xstart_find_import_named(const R4XStartContext *ctx, const char *module_name, const char *symbol_name) {
    uint32_t count = r4xstart_import_count(ctx);
    for (uint32_t i = 0; i < count; i += 1) {
        const R4XStartImport *item = r4xstart_import_at(ctx, i);
        if (item != 0 &&
            r4xstart_import_name_equal(item->module_name, module_name) &&
            r4xstart_import_name_equal(item->symbol_name, symbol_name)) return item;
    }
    return 0;
}

static inline int32_t r4l_validate_import(const R4XStartImport *item, const R4LInterfaceExpectation *expected, const R4LInterfaceHeader **out_header) {
    if (out_header != 0) *out_header = 0;
    if (expected == 0 || out_header == 0 ||
        (expected->interface_id_lo == 0 && expected->interface_id_hi == 0) ||
        expected->abi_major == 0 || expected->min_revision == 0 ||
        expected->required_size < R4L_INTERFACE_HEADER_SIZE ||
        (expected->required_size % R4L_INTERFACE_ALIGNMENT) != 0) return R4L_BINDING_INVALID_EXPECTATION;
    if (item == 0 || item->group_id != 0 || item->table == 0 || item->min_version == 0 || item->resolved_version == 0) return R4L_BINDING_INVALID_IMPORT;
    if (item->min_version < expected->min_revision) return R4L_BINDING_MANIFEST_REVISION_TOO_OLD;
    if (item->resolved_version < item->min_version || item->resolved_version > 65535u) return R4L_BINDING_INVALID_REVISION;
    if ((item->table % R4L_INTERFACE_ALIGNMENT) != 0) return R4L_BINDING_MISALIGNED_TABLE;

    const R4LInterfaceHeader *header = (const R4LInterfaceHeader *)(uintptr_t)item->table;
    if (header->magic != R4L_INTERFACE_MAGIC) return R4L_BINDING_BAD_MAGIC;
    if (header->header_version != R4L_INTERFACE_HEADER_VERSION) return R4L_BINDING_UNSUPPORTED_HEADER;
    if (((header->flags & R4L_INTERFACE_REQUIRED_FLAG_MASK) & ~expected->known_required_flags) != 0) return R4L_BINDING_UNKNOWN_REQUIRED_FLAGS;
    if (header->size < R4L_INTERFACE_HEADER_SIZE || (header->size % R4L_INTERFACE_ALIGNMENT) != 0) return R4L_BINDING_INVALID_TABLE_SIZE;
    if (header->interface_id_lo != expected->interface_id_lo || header->interface_id_hi != expected->interface_id_hi) return R4L_BINDING_WRONG_INTERFACE;
    if (header->abi_major != expected->abi_major) return R4L_BINDING_WRONG_MAJOR;
    if (header->abi_minor == 0) return R4L_BINDING_INVALID_REVISION;
    if (item->resolved_version != (uint32_t)header->abi_minor) return R4L_BINDING_REVISION_DRIFT;
    if (header->abi_minor < expected->min_revision) return R4L_BINDING_REVISION_TOO_OLD;
    if (header->size < expected->required_size) return R4L_BINDING_TABLE_TOO_SMALL;
    *out_header = header;
    return R4L_BINDING_OK;
}

static inline int r4l_has_slot(const R4LInterfaceHeader *header, uint32_t byte_offset) {
    if (header == 0 || byte_offset < R4L_INTERFACE_HEADER_SIZE || (byte_offset % sizeof(uint64_t)) != 0) return 0;
    return byte_offset <= header->size && sizeof(uint64_t) <= header->size - byte_offset;
}

static inline uintptr_t r4l_slot_address(const R4LInterfaceHeader *header, uint32_t byte_offset) {
    if (!r4l_has_slot(header, byte_offset)) return (uintptr_t)0;
    const uint64_t *slot = (const uint64_t *)((const uint8_t *)header + byte_offset);
    return (uintptr_t)*slot;
}

#endif
