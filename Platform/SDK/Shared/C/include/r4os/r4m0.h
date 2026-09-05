#ifndef R4OS_R4M0_H
#define R4OS_R4M0_H

#include "abi.h"

#ifdef __cplusplus
extern "C" {
#endif

#define R4M0_MAGIC 0x304d3452u
#define R4M0_VERSION 1u
#define R4M0_ARCH_X86_64 1u
#define R4M0_HEADER_SIZE 64u
#define R4M0_SECTION_SIZE 32u
#define R4M0_ENTRY_SIZE 16u
#define R4M0_IMPORT_SIZE 16u
#define R4M0_EXPORT_SIZE 16u
#define R4M0_RELOCATION_SIZE 24u

#define R4M0_KIND_R4X 1u
#define R4M0_KIND_R4L 2u
#define R4M0_KIND_R4D 3u
#define R4M0_KIND_R4P 4u
#define R4M0_KIND_KERNEL_PROVIDER 5u
#define R4M0_KIND_KERNEL_MODULE_RESERVED 6u

#define R4M0_ENTRY_R4X 1u
#define R4M0_ENTRY_R4L 2u
#define R4M0_ENTRY_R4D 3u
#define R4M0_ENTRY_R4P 4u

#define R4M0_R4X_FLAG_CONSOLE 0x00000001u
#define R4M0_R4X_FLAG_GUI 0x00000002u
#define R4M0_R4X_FLAG_SERVICE 0x00000004u

#define R4M0_SECTION_FLAG_ALLOC 0x00000001u
#define R4M0_SECTION_FLAG_EXEC 0x00000002u
#define R4M0_SECTION_FLAG_WRITE 0x00000004u
#define R4M0_SECTION_FLAG_BSS 0x00000008u

#define R4M0_RELOC_ABS64 1u
#define R4M0_RELOC_REL32 2u
#define R4M0_RELOC_BASE_REL64 3u
#define R4M0_RELOC_IMPORT_SLOT64 4u

typedef struct R4M0Header {
    uint32_t magic;
    uint16_t version;
    uint16_t arch;
    uint16_t kind;
    uint16_t header_size;
    uint32_t flags;
    uint32_t section_table_offset;
    uint32_t section_count;
    uint32_t import_table_offset;
    uint32_t import_count;
    uint32_t export_table_offset;
    uint32_t export_count;
    uint32_t relocation_table_offset;
    uint32_t relocation_count;
    uint32_t entry_table_offset;
    uint32_t entry_count;
    uint32_t meta_offset;
    uint32_t meta_size;
} R4M0Header;

typedef struct R4M0Section {
    char name[8];
    uint32_t flags;
    uint32_t file_offset;
    uint32_t file_size;
    uint32_t memory_size;
    uint32_t alignment;
    uint32_t reserved;
} R4M0Section;

typedef struct R4M0Entry {
    uint32_t kind;
    uint32_t section_index;
    uint32_t section_offset;
    uint32_t flags;
} R4M0Entry;

typedef struct R4M0Import {
    uint32_t module_name_offset;
    uint32_t symbol_name_offset;
    uint32_t min_version;
    uint32_t flags;
} R4M0Import;

typedef struct R4M0Export {
    uint32_t name_offset;
    uint32_t section_index;
    uint32_t section_offset;
    uint32_t version;
} R4M0Export;

typedef struct R4M0Relocation {
    uint32_t kind;
    uint32_t patch_section_index;
    uint32_t patch_offset;
    uint32_t target_section_or_import_index;
    uint32_t target_offset;
    int32_t addend;
} R4M0Relocation;

_Static_assert(sizeof(R4M0Header) == R4M0_HEADER_SIZE, "R4M0Header size mismatch");
_Static_assert(sizeof(R4M0Section) == R4M0_SECTION_SIZE, "R4M0Section size mismatch");
_Static_assert(sizeof(R4M0Entry) == R4M0_ENTRY_SIZE, "R4M0Entry size mismatch");
_Static_assert(sizeof(R4M0Import) == R4M0_IMPORT_SIZE, "R4M0Import size mismatch");
_Static_assert(sizeof(R4M0Export) == R4M0_EXPORT_SIZE, "R4M0Export size mismatch");
_Static_assert(sizeof(R4M0Relocation) == R4M0_RELOCATION_SIZE, "R4M0Relocation size mismatch");
_Static_assert(offsetof(R4M0Header, meta_offset) == 56, "R4M0Header.meta_offset mismatch");
_Static_assert(offsetof(R4M0Section, alignment) == 24, "R4M0Section.alignment mismatch");
_Static_assert(offsetof(R4M0Relocation, addend) == 20, "R4M0Relocation.addend mismatch");

#ifdef __cplusplus
}
#endif

#endif
