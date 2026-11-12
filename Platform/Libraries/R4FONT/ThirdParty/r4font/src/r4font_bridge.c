#include "r4font_bridge.h"

#include <limits.h>
#include <string.h>

#include <ft2build.h>
#include FT_FREETYPE_H
#include FT_MODULE_H

#define R4FONT_ALIGNMENT ((size_t)16)
#define R4FONT_BLOCK_MAGIC UINT64_C(0x5234464F4E544D45)
#define R4FONT_MAX_SOURCE_BYTES ((size_t)8 * 1024 * 1024)
#define R4FONT_MAX_RECONSTRUCTED_BYTES ((uint32_t)32 * 1024 * 1024)
#define R4FONT_MAX_RASTER_DIMENSION ((uint32_t)512)
#define R4FONT_MAX_TABLES ((uint16_t)128)
#define R4FONT_MAX_FACES ((uint32_t)32)
#define R4FONT_TAG(a, b, c, d)                                             \
  (((uint32_t)(a) << 24) | ((uint32_t)(b) << 16) | ((uint32_t)(c) << 8) | \
   (uint32_t)(d))

typedef struct R4FontBlockHeader {
  uint64_t magic;
  size_t size;
} R4FontBlockHeader;

struct R4FontDecoder {
  R4FontAllocator allocator;
  struct FT_MemoryRec_ memory;
  FT_Library library;
  size_t current_bytes;
  size_t peak_bytes;
  size_t allocation_count;
  size_t allocation_failure_count;
  size_t reallocation_count;
  size_t reallocation_failure_count;
  size_t allocation_limit;
  int allocation_failed;
};

static void r4font_record_allocation_failure(R4FontDecoder* context)
{
  context->allocation_failed = 1;
  context->allocation_failure_count++;
}

static R4FontDecoder* r4font_face_context(FT_Face face)
{
  if (!face || !face->memory)
    return NULL;
  return (R4FontDecoder*)face->memory->user;
}

static int r4font_add_overflow(size_t left, size_t right, size_t* out)
{
  if (left > SIZE_MAX - right)
    return 1;
  *out = left + right;
  return 0;
}

static uint16_t r4font_be16(const uint8_t* bytes)
{
  return (uint16_t)((uint16_t)bytes[0] << 8) | bytes[1];
}

static uint32_t r4font_be32(const uint8_t* bytes)
{
  return ((uint32_t)bytes[0] << 24) | ((uint32_t)bytes[1] << 16) |
         ((uint32_t)bytes[2] << 8) | bytes[3];
}

static int r4font_range(size_t offset, size_t size, size_t length)
{
  return offset <= length && size <= length - offset;
}

static int r4font_ranges_overlap(size_t left_offset, size_t left_size,
                                 size_t right_offset, size_t right_size)
{
  if (!left_size || !right_size)
    return 0;
  return left_offset < right_offset + right_size &&
         right_offset < left_offset + left_size;
}

static int r4font_valid_sfnt_flavor(uint32_t flavor, int allow_collection)
{
  return flavor == UINT32_C(0x00010000) ||
         flavor == R4FONT_TAG('O', 'T', 'T', 'O') ||
         flavor == R4FONT_TAG('t', 'r', 'u', 'e') ||
         flavor == R4FONT_TAG('t', 'y', 'p', '1') ||
         (allow_collection && flavor == R4FONT_TAG('t', 't', 'c', 'f'));
}

static int r4font_valid_search_fields(const uint8_t* header,
                                      uint16_t table_count)
{
  uint16_t power = 1;
  uint16_t selector = 0;
  uint16_t search_range;
  while ((uint16_t)(power << 1) <= table_count)
  {
    power = (uint16_t)(power << 1);
    selector++;
  }
  search_range = (uint16_t)(power * 16);
  return r4font_be16(header + 6) == search_range &&
         r4font_be16(header + 8) == selector &&
         r4font_be16(header + 10) ==
             (uint16_t)(table_count * 16 - search_range);
}

static int r4font_validate_sfnt_at(const uint8_t* bytes, size_t length,
                                   size_t directory_offset)
{
  uint16_t table_count;
  size_t directory_size;
  uint16_t left;

  if (!r4font_range(directory_offset, 12, length))
    return 0;
  if (!r4font_valid_sfnt_flavor(r4font_be32(bytes + directory_offset), 0))
    return 0;
  table_count = r4font_be16(bytes + directory_offset + 4);
  if (table_count == 0 || table_count > R4FONT_MAX_TABLES)
    return 0;
  if (!r4font_valid_search_fields(bytes + directory_offset, table_count))
    return 0;
  directory_size = 12 + (size_t)table_count * 16;
  if (!r4font_range(directory_offset, directory_size, length))
    return 0;
  for (left = 0; left < table_count; left++)
  {
    const uint8_t* left_record = bytes + directory_offset + 12 +
                                 (size_t)left * 16;
    size_t left_offset = r4font_be32(left_record + 8);
    size_t left_size = r4font_be32(left_record + 12);
    uint16_t right;

    if ((left_offset & 3) != 0 ||
        !r4font_range(left_offset, left_size, length) ||
        r4font_ranges_overlap(left_offset, left_size, directory_offset,
                              directory_size))
      return 0;
    for (right = (uint16_t)(left + 1); right < table_count; right++)
    {
      const uint8_t* right_record = bytes + directory_offset + 12 +
                                    (size_t)right * 16;
      size_t right_offset = r4font_be32(right_record + 8);
      size_t right_size = r4font_be32(right_record + 12);
      if (r4font_be32(left_record) == r4font_be32(right_record) ||
          r4font_ranges_overlap(left_offset, left_size, right_offset,
                                right_size))
        return 0;
    }
  }
  return 1;
}

static int r4font_validate_woff(const uint8_t* bytes, size_t length)
{
  uint16_t table_count;
  uint32_t declared_length;
  uint32_t reconstructed;
  uint32_t flavor;
  uint32_t metadata_offset;
  uint32_t metadata_length;
  uint32_t metadata_original;
  uint32_t private_offset;
  uint32_t private_length;
  size_t directory_size;
  size_t reconstructed_expected;
  size_t payload_end;
  uint16_t left;

  if (length < 44)
    return 0;
  declared_length = r4font_be32(bytes + 8);
  flavor = r4font_be32(bytes + 4);
  table_count = r4font_be16(bytes + 12);
  reconstructed = r4font_be32(bytes + 16);
  metadata_offset = r4font_be32(bytes + 24);
  metadata_length = r4font_be32(bytes + 28);
  metadata_original = r4font_be32(bytes + 32);
  private_offset = r4font_be32(bytes + 36);
  private_length = r4font_be32(bytes + 40);
  if (declared_length != length || table_count == 0 ||
      table_count > R4FONT_MAX_TABLES || r4font_be16(bytes + 14) != 0 ||
      !r4font_valid_sfnt_flavor(flavor, 0) ||
      reconstructed > R4FONT_MAX_RECONSTRUCTED_BYTES ||
      reconstructed < 12 + (uint32_t)table_count * 16)
    return 0;
  directory_size = 44 + (size_t)table_count * 20;
  if (directory_size > length)
    return 0;
  reconstructed_expected = 12 + (size_t)table_count * 16;
  payload_end = directory_size;
  for (left = 0; left < table_count; left++)
  {
    const uint8_t* left_record = bytes + 44 + (size_t)left * 20;
    size_t left_offset = r4font_be32(left_record + 4);
    size_t left_size = r4font_be32(left_record + 8);
    size_t left_original = r4font_be32(left_record + 12);
    uint16_t right;

    size_t padded_original = (left_original + (size_t)3) & ~(size_t)3;
    size_t left_end;

    if ((left_offset & 3) != 0 || left_offset < directory_size ||
        left_size > left_original || !r4font_range(left_offset, left_size, length) ||
        r4font_add_overflow(left_offset, left_size, &left_end) ||
        r4font_add_overflow(reconstructed_expected, padded_original,
                            &reconstructed_expected))
      return 0;
    if (left_end > payload_end)
      payload_end = left_end;
    for (right = (uint16_t)(left + 1); right < table_count; right++)
    {
      const uint8_t* right_record = bytes + 44 + (size_t)right * 20;
      size_t right_offset = r4font_be32(right_record + 4);
      size_t right_size = r4font_be32(right_record + 8);
      if (r4font_be32(left_record) == r4font_be32(right_record) ||
          r4font_ranges_overlap(left_offset, left_size, right_offset,
                                right_size))
        return 0;
    }
  }
  if (reconstructed_expected != reconstructed ||
      reconstructed_expected > R4FONT_MAX_RECONSTRUCTED_BYTES)
    return 0;
  if (metadata_offset == 0)
  {
    if (metadata_length != 0 || metadata_original != 0)
      return 0;
  }
  else if (metadata_length == 0 || metadata_original == 0 ||
           (metadata_offset & 3) != 0 || metadata_offset < payload_end ||
           !r4font_range(metadata_offset, metadata_length, length))
    return 0;
  if (private_offset == 0)
  {
    if (private_length != 0)
      return 0;
  }
  else if (private_length == 0 || (private_offset & 3) != 0 ||
           private_offset < payload_end ||
           !r4font_range(private_offset, private_length, length))
    return 0;
  if (r4font_ranges_overlap(metadata_offset, metadata_length, private_offset,
                            private_length))
    return 0;
  return 1;
}

static int r4font_validate_woff2(const uint8_t* bytes, size_t length)
{
  uint16_t table_count;
  uint32_t declared_length;
  uint32_t reconstructed;
  uint32_t compressed;
  uint32_t flavor;
  uint32_t metadata_offset;
  uint32_t metadata_length;
  uint32_t metadata_original;
  uint32_t private_offset;
  uint32_t private_length;

  if (length < 48)
    return 0;
  declared_length = r4font_be32(bytes + 8);
  flavor = r4font_be32(bytes + 4);
  table_count = r4font_be16(bytes + 12);
  reconstructed = r4font_be32(bytes + 16);
  compressed = r4font_be32(bytes + 20);
  metadata_offset = r4font_be32(bytes + 28);
  metadata_length = r4font_be32(bytes + 32);
  metadata_original = r4font_be32(bytes + 36);
  private_offset = r4font_be32(bytes + 40);
  private_length = r4font_be32(bytes + 44);
  if (declared_length != length || table_count == 0 ||
      table_count > R4FONT_MAX_TABLES || r4font_be16(bytes + 14) != 0 ||
      !r4font_valid_sfnt_flavor(flavor, 1) ||
      reconstructed > R4FONT_MAX_RECONSTRUCTED_BYTES ||
      reconstructed < 12 + (uint32_t)table_count * 16 ||
      compressed == 0 || compressed > length - 48 ||
      (size_t)table_count > length - 48 - compressed)
    return 0;
  if (metadata_offset == 0)
  {
    if (metadata_length != 0 || metadata_original != 0)
      return 0;
  }
  else if (metadata_length == 0 || metadata_original == 0 ||
           !r4font_range(metadata_offset, metadata_length, length))
    return 0;
  if (private_offset == 0)
  {
    if (private_length != 0)
      return 0;
  }
  else if (private_length == 0 ||
           !r4font_range(private_offset, private_length, length))
    return 0;
  if (r4font_ranges_overlap(metadata_offset, metadata_length, private_offset,
                            private_length))
    return 0;
  return 1;
}

static int r4font_validate_collection(const uint8_t* bytes, size_t length)
{
  uint32_t face_count;
  uint32_t version;
  size_t header_size;
  uint32_t index;
  if (length < 16)
    return 0;
  version = r4font_be32(bytes + 4);
  face_count = r4font_be32(bytes + 8);
  if (face_count == 0 || face_count > R4FONT_MAX_FACES ||
      face_count > (length - 12) / 4)
    return 0;
  if (version != UINT32_C(0x00010000) && version != UINT32_C(0x00020000))
    return 0;
  header_size = 12 + (size_t)face_count * 4;
  if (version == UINT32_C(0x00020000))
  {
    uint32_t dsig_tag;
    uint32_t dsig_length;
    uint32_t dsig_offset;
    if (!r4font_range(header_size, 12, length))
      return 0;
    dsig_tag = r4font_be32(bytes + header_size);
    dsig_length = r4font_be32(bytes + header_size + 4);
    dsig_offset = r4font_be32(bytes + header_size + 8);
    header_size += 12;
    if (dsig_tag == 0)
    {
      if (dsig_length != 0 || dsig_offset != 0)
        return 0;
    }
    else if (dsig_tag != R4FONT_TAG('D', 'S', 'I', 'G') ||
             dsig_length == 0 || (dsig_offset & 3) != 0 ||
             dsig_offset < header_size ||
             !r4font_range(dsig_offset, dsig_length, length))
      return 0;
  }
  for (index = 0; index < face_count; index++)
  {
    size_t offset = r4font_be32(bytes + 12 + (size_t)index * 4);
    uint32_t previous;
    if ((offset & 3) != 0 || offset < header_size ||
        !r4font_validate_sfnt_at(bytes, length, offset))
      return 0;
    for (previous = 0; previous < index; previous++)
      if (offset == r4font_be32(bytes + 12 + (size_t)previous * 4))
        return 0;
  }
  for (index = 0; index < face_count; index++)
  {
    size_t directory_offset = r4font_be32(bytes + 12 + (size_t)index * 4);
    uint16_t table_count = r4font_be16(bytes + directory_offset + 4);
    size_t directory_size = 12 + (size_t)table_count * 16;
    uint32_t other;
    uint16_t table;
    if (r4font_ranges_overlap(directory_offset, directory_size, 0,
                              header_size))
      return 0;
    for (other = 0; other < face_count; other++)
    {
      size_t other_offset = r4font_be32(bytes + 12 + (size_t)other * 4);
      uint16_t other_count = r4font_be16(bytes + other_offset + 4);
      size_t other_size = 12 + (size_t)other_count * 16;
      if (other != index &&
          r4font_ranges_overlap(directory_offset, directory_size,
                                other_offset, other_size))
        return 0;
    }
    for (table = 0; table < table_count; table++)
    {
      const uint8_t* record = bytes + directory_offset + 12 +
                              (size_t)table * 16;
      size_t table_offset = r4font_be32(record + 8);
      size_t table_size = r4font_be32(record + 12);
      if (r4font_ranges_overlap(table_offset, table_size, 0, header_size))
        return 0;
      for (other = 0; other < face_count; other++)
      {
        size_t other_offset = r4font_be32(bytes + 12 + (size_t)other * 4);
        uint16_t other_count = r4font_be16(bytes + other_offset + 4);
        size_t other_size = 12 + (size_t)other_count * 16;
        if (r4font_ranges_overlap(table_offset, table_size, other_offset,
                                  other_size))
          return 0;
      }
    }
  }
  return 1;
}

static int r4font_validate_container(const uint8_t* bytes, size_t length,
                                     R4FontFormat format)
{
  switch (format)
  {
  case R4FONT_FORMAT_TTF:
  case R4FONT_FORMAT_OTF_CFF:
    return r4font_validate_sfnt_at(bytes, length, 0);
  case R4FONT_FORMAT_WOFF:
    return r4font_validate_woff(bytes, length);
  case R4FONT_FORMAT_WOFF2:
    return r4font_validate_woff2(bytes, length);
  case R4FONT_FORMAT_COLLECTION:
    return r4font_validate_collection(bytes, length);
  default:
    return 0;
  }
}

static int r4font_container_limit_result(const uint8_t* bytes, size_t length,
                                         R4FontFormat format)
{
  switch (format)
  {
  case R4FONT_FORMAT_TTF:
  case R4FONT_FORMAT_OTF_CFF:
    if (length >= 6 && r4font_be16(bytes + 4) > R4FONT_MAX_TABLES)
      return R4FONT_ERROR_TOO_LARGE;
    break;
  case R4FONT_FORMAT_WOFF:
  case R4FONT_FORMAT_WOFF2:
    if (length >= 20 &&
        (r4font_be16(bytes + 12) > R4FONT_MAX_TABLES ||
         r4font_be32(bytes + 16) > R4FONT_MAX_RECONSTRUCTED_BYTES))
      return R4FONT_ERROR_TOO_LARGE;
    break;
  case R4FONT_FORMAT_COLLECTION:
    if (length >= 12 && r4font_be32(bytes + 8) > R4FONT_MAX_FACES)
      return R4FONT_ERROR_TOO_LARGE;
    break;
  default:
    break;
  }
  return R4FONT_OK;
}

static void* r4font_ft_alloc(FT_Memory memory, long requested)
{
  R4FontDecoder* context;
  R4FontBlockHeader* header;
  size_t size;
  size_t total;

  if (!memory || requested <= 0)
    return NULL;
  context = (R4FontDecoder*)memory->user;
  size = (size_t)requested;
  if (context->current_bytes > context->allocation_limit ||
      r4font_add_overflow(sizeof(*header), size, &total) ||
      size > context->allocation_limit - context->current_bytes)
  {
    r4font_record_allocation_failure(context);
    return NULL;
  }
  header = (R4FontBlockHeader*)context->allocator.alloc(
      context->allocator.user, total, R4FONT_ALIGNMENT);
  if (!header)
  {
    r4font_record_allocation_failure(context);
    return NULL;
  }
  header->magic = R4FONT_BLOCK_MAGIC;
  header->size = size;
  context->current_bytes += size;
  if (context->current_bytes > context->peak_bytes)
    context->peak_bytes = context->current_bytes;
  context->allocation_count++;
  return (void*)(header + 1);
}

static void r4font_ft_free(FT_Memory memory, void* block)
{
  R4FontDecoder* context;
  R4FontBlockHeader* header;
  size_t total;

  if (!memory || !block)
    return;
  context = (R4FontDecoder*)memory->user;
  header = ((R4FontBlockHeader*)block) - 1;
  if (header->magic != R4FONT_BLOCK_MAGIC ||
      r4font_add_overflow(sizeof(*header), header->size, &total))
    return;
  if (header->size <= context->current_bytes)
    context->current_bytes -= header->size;
  header->magic = 0;
  context->allocator.free(context->allocator.user, header, total,
                          R4FONT_ALIGNMENT);
}

static void* r4font_ft_realloc(FT_Memory memory, long current_size,
                               long requested, void* block)
{
  R4FontDecoder* context;
  R4FontBlockHeader* header;
  R4FontBlockHeader* resized;
  size_t old_size;
  size_t new_size;
  size_t old_total;
  size_t new_total;
  size_t without_old;

  if (!block)
    return r4font_ft_alloc(memory, requested);
  if (requested <= 0)
  {
    r4font_ft_free(memory, block);
    return NULL;
  }
  if (!memory || current_size < 0)
    return NULL;
  context = (R4FontDecoder*)memory->user;
  context->reallocation_count++;
  header = ((R4FontBlockHeader*)block) - 1;
  if (header->magic != R4FONT_BLOCK_MAGIC)
    return NULL;
  old_size = header->size;
  new_size = (size_t)requested;
  if (old_size > context->current_bytes)
    return NULL;
  without_old = context->current_bytes - old_size;
  if (without_old > context->allocation_limit ||
      r4font_add_overflow(sizeof(*header), old_size, &old_total) ||
      r4font_add_overflow(sizeof(*header), new_size, &new_total) ||
      new_size > context->allocation_limit - without_old)
  {
    context->reallocation_failure_count++;
    r4font_record_allocation_failure(context);
    return NULL;
  }
  resized = (R4FontBlockHeader*)context->allocator.realloc(
      context->allocator.user, header, old_total, new_total,
      R4FONT_ALIGNMENT);
  if (!resized)
  {
    context->reallocation_failure_count++;
    r4font_record_allocation_failure(context);
    return NULL;
  }
  resized->magic = R4FONT_BLOCK_MAGIC;
  resized->size = new_size;
  context->current_bytes = without_old + new_size;
  if (context->current_bytes > context->peak_bytes)
    context->peak_bytes = context->current_bytes;
  return (void*)(resized + 1);
}

R4FontFormat r4font_sniff(const uint8_t* bytes, size_t length)
{
  if (!bytes || length < 4)
    return R4FONT_FORMAT_UNKNOWN;
  if (bytes[0] == 0x00 && bytes[1] == 0x01 && bytes[2] == 0x00 &&
      bytes[3] == 0x00)
    return R4FONT_FORMAT_TTF;
  if (memcmp(bytes, "true", 4) == 0 || memcmp(bytes, "typ1", 4) == 0)
    return R4FONT_FORMAT_TTF;
  if (memcmp(bytes, "OTTO", 4) == 0)
    return R4FONT_FORMAT_OTF_CFF;
  if (memcmp(bytes, "wOFF", 4) == 0)
    return R4FONT_FORMAT_WOFF;
  if (memcmp(bytes, "wOF2", 4) == 0)
    return R4FONT_FORMAT_WOFF2;
  if (memcmp(bytes, "ttcf", 4) == 0)
    return R4FONT_FORMAT_COLLECTION;
  return R4FONT_FORMAT_UNKNOWN;
}

int r4font_decoder_create(R4FontAllocator allocator, size_t allocation_limit,
                          R4FontDecoder** out_context)
{
  R4FontDecoder* context;
  FT_Error error;
  int allocation_failed;

  if (!out_context || !allocator.alloc || !allocator.realloc ||
      !allocator.free || allocation_limit == 0)
    return R4FONT_ERROR_ARGUMENT;
  *out_context = NULL;
  context = (R4FontDecoder*)allocator.alloc(allocator.user, sizeof(*context),
                                            R4FONT_ALIGNMENT);
  if (!context)
    return R4FONT_ERROR_OUT_OF_MEMORY;
  memset(context, 0, sizeof(*context));
  context->allocator = allocator;
  context->allocation_limit = allocation_limit;
  context->memory.user = context;
  context->memory.alloc = r4font_ft_alloc;
  context->memory.realloc = r4font_ft_realloc;
  context->memory.free = r4font_ft_free;
  error = FT_New_Library(&context->memory, &context->library);
  if (error)
  {
    allocation_failed = context->allocation_failure_count != 0;
    allocator.free(allocator.user, context, sizeof(*context),
                   R4FONT_ALIGNMENT);
    return allocation_failed ? R4FONT_ERROR_OUT_OF_MEMORY
                             : R4FONT_ERROR_INVALID_FONT;
  }
  FT_Add_Default_Modules(context->library);
  if (context->allocation_failure_count != 0)
  {
    FT_Done_Library(context->library);
    allocator.free(allocator.user, context, sizeof(*context),
                   R4FONT_ALIGNMENT);
    return R4FONT_ERROR_OUT_OF_MEMORY;
  }
  *out_context = context;
  return R4FONT_OK;
}

void r4font_decoder_destroy(R4FontDecoder* context)
{
  R4FontAllocator allocator;
  if (!context)
    return;
  allocator = context->allocator;
  if (context->library)
    FT_Done_Library(context->library);
  allocator.free(allocator.user, context, sizeof(*context), R4FONT_ALIGNMENT);
}

R4FontDiagnostics r4font_decoder_diagnostics(const R4FontDecoder* context)
{
  R4FontDiagnostics diagnostics;
  memset(&diagnostics, 0, sizeof(diagnostics));
  if (!context)
    return diagnostics;
  diagnostics.current_bytes = context->current_bytes;
  diagnostics.peak_bytes = context->peak_bytes;
  diagnostics.allocation_count = context->allocation_count;
  diagnostics.reallocation_count = context->reallocation_count;
  diagnostics.reallocation_failure_count = context->reallocation_failure_count;
  diagnostics.allocation_limit = context->allocation_limit;
  diagnostics.allocation_failed = context->allocation_failed;
  return diagnostics;
}

int r4font_decoder_open_face(R4FontDecoder* context, const uint8_t* bytes,
                             size_t length, uint32_t face_index,
                             R4FontFace* out_face)
{
  FT_Face face = NULL;
  FT_Face probe = NULL;
  FT_Error error;
  size_t allocation_failures;
  int limit_result;
  R4FontFormat format;
  if (out_face)
    *out_face = NULL;
  if (!context || !bytes || !out_face || length == 0)
    return R4FONT_ERROR_ARGUMENT;
  if (length > R4FONT_MAX_SOURCE_BYTES || length > (size_t)LONG_MAX)
    return R4FONT_ERROR_TOO_LARGE;
  format = r4font_sniff(bytes, length);
  if (format == R4FONT_FORMAT_UNKNOWN)
    return R4FONT_ERROR_UNSUPPORTED;
  limit_result = r4font_container_limit_result(bytes, length, format);
  if (limit_result != R4FONT_OK)
    return limit_result;
  if (!r4font_validate_container(bytes, length, format))
    return R4FONT_ERROR_INVALID_FONT;
  allocation_failures = context->allocation_failure_count;
  if (face_index > 0)
  {
    error = FT_New_Memory_Face(context->library, bytes, (FT_Long)length,
                               -1, &probe);
    if (error)
      return context->allocation_failure_count != allocation_failures
                 ? R4FONT_ERROR_OUT_OF_MEMORY
                 : R4FONT_ERROR_INVALID_FONT;
    if (face_index >= (uint32_t)probe->num_faces)
    {
      FT_Done_Face(probe);
      return R4FONT_ERROR_FACE_INDEX;
    }
    FT_Done_Face(probe);
  }
  error = FT_New_Memory_Face(context->library, bytes, (FT_Long)length,
                             (FT_Long)face_index, &face);
  if (error)
    return context->allocation_failure_count != allocation_failures
               ? R4FONT_ERROR_OUT_OF_MEMORY
               : R4FONT_ERROR_INVALID_FONT;
  *out_face = (R4FontFace)face;
  return R4FONT_OK;
}

void r4font_close_face(R4FontFace raw_face)
{
  if (raw_face)
    FT_Done_Face((FT_Face)raw_face);
}

int r4font_face_info(R4FontFace raw_face, R4FontFaceInfo* out_info)
{
  FT_Face face = (FT_Face)raw_face;
  if (!face || !out_info)
    return R4FONT_ERROR_ARGUMENT;
  memset(out_info, 0, sizeof(*out_info));
  out_info->face_count = (uint32_t)face->num_faces;
  out_info->face_index = (uint32_t)face->face_index;
  out_info->glyph_count = (uint32_t)face->num_glyphs;
  out_info->units_per_em = face->units_per_EM;
  out_info->ascender = face->ascender;
  out_info->descender = face->descender;
  out_info->line_height = face->height;
  out_info->max_advance = face->max_advance_width;
  out_info->style_flags = (uint32_t)face->style_flags;
  out_info->family = face->family_name;
  out_info->style = face->style_name;
  return R4FONT_OK;
}

uint32_t r4font_glyph_index(R4FontFace raw_face, uint32_t codepoint)
{
  FT_Face face = (FT_Face)raw_face;
  if (!face)
    return 0;
  return FT_Get_Char_Index(face, codepoint);
}

int r4font_glyph_metrics(R4FontFace raw_face, uint32_t glyph_index,
                         R4FontGlyphMetrics* out_metrics)
{
  FT_Face face = (FT_Face)raw_face;
  R4FontDecoder* context;
  size_t allocation_failures;
  FT_Error error;
  if (!face || !out_metrics)
    return R4FONT_ERROR_ARGUMENT;
  if (glyph_index >= (uint32_t)face->num_glyphs)
    return R4FONT_ERROR_GLYPH;
  context = r4font_face_context(face);
  allocation_failures = context ? context->allocation_failure_count : 0;
  error = FT_Load_Glyph(face, glyph_index,
                        FT_LOAD_NO_SCALE | FT_LOAD_NO_HINTING |
                            FT_LOAD_NO_BITMAP);
  if (error)
    return context && context->allocation_failure_count != allocation_failures
               ? R4FONT_ERROR_OUT_OF_MEMORY
               : R4FONT_ERROR_GLYPH;
  memset(out_metrics, 0, sizeof(*out_metrics));
  out_metrics->glyph_index = glyph_index;
  out_metrics->advance_x = (int32_t)face->glyph->metrics.horiAdvance;
  out_metrics->advance_y = (int32_t)face->glyph->metrics.vertAdvance;
  out_metrics->bearing_x = (int32_t)face->glyph->metrics.horiBearingX;
  out_metrics->bearing_y = (int32_t)face->glyph->metrics.horiBearingY;
  out_metrics->width = (int32_t)face->glyph->metrics.width;
  out_metrics->height = (int32_t)face->glyph->metrics.height;
  return R4FONT_OK;
}

int r4font_kerning(R4FontFace raw_face, uint32_t left_glyph,
                   uint32_t right_glyph, int32_t* out_x, int32_t* out_y)
{
  FT_Face face = (FT_Face)raw_face;
  R4FontDecoder* context;
  size_t allocation_failures;
  FT_Vector vector;
  FT_Error error;
  if (!face || !out_x || !out_y)
    return R4FONT_ERROR_ARGUMENT;
  if (left_glyph >= (uint32_t)face->num_glyphs ||
      right_glyph >= (uint32_t)face->num_glyphs)
    return R4FONT_ERROR_GLYPH;
  vector.x = 0;
  vector.y = 0;
  context = r4font_face_context(face);
  allocation_failures = context ? context->allocation_failure_count : 0;
  error = FT_Get_Kerning(face, left_glyph, right_glyph,
                         FT_KERNING_UNSCALED, &vector);
  if (error)
    return context && context->allocation_failure_count != allocation_failures
               ? R4FONT_ERROR_OUT_OF_MEMORY
               : R4FONT_ERROR_GLYPH;
  *out_x = (int32_t)vector.x;
  *out_y = (int32_t)vector.y;
  return R4FONT_OK;
}

int r4font_rasterize(R4FontFace raw_face, uint32_t glyph_index,
                     uint32_t pixel_height, uint8_t* output,
                     size_t output_capacity, R4FontRaster* out_raster)
{
  FT_Face face = (FT_Face)raw_face;
  R4FontDecoder* context;
  size_t allocation_failures;
  FT_Bitmap* bitmap;
  FT_Error error;
  size_t required;
  uint32_t row;

  if (!face || !out_raster || pixel_height < 4 || pixel_height > 256)
    return R4FONT_ERROR_ARGUMENT;
  if (glyph_index >= (uint32_t)face->num_glyphs)
    return R4FONT_ERROR_GLYPH;
  context = r4font_face_context(face);
  allocation_failures = context ? context->allocation_failure_count : 0;
  error = FT_Set_Pixel_Sizes(face, 0, pixel_height);
  if (!error)
    error = FT_Load_Glyph(face, glyph_index,
                          FT_LOAD_NO_HINTING | FT_LOAD_NO_BITMAP);
  if (!error)
    error = FT_Render_Glyph(face->glyph, FT_RENDER_MODE_NORMAL);
  if (error)
    return context && context->allocation_failure_count != allocation_failures
               ? R4FONT_ERROR_OUT_OF_MEMORY
               : R4FONT_ERROR_GLYPH;
  bitmap = &face->glyph->bitmap;
  if (bitmap->pixel_mode != FT_PIXEL_MODE_GRAY ||
      bitmap->width > R4FONT_MAX_RASTER_DIMENSION ||
      bitmap->rows > R4FONT_MAX_RASTER_DIMENSION ||
      bitmap->width != 0 && bitmap->rows > SIZE_MAX / bitmap->width)
    return R4FONT_ERROR_TOO_LARGE;
  required = (size_t)bitmap->width * bitmap->rows;
  memset(out_raster, 0, sizeof(*out_raster));
  out_raster->glyph_index = glyph_index;
  out_raster->width = bitmap->width;
  out_raster->height = bitmap->rows;
  out_raster->left = face->glyph->bitmap_left;
  out_raster->top = face->glyph->bitmap_top;
  out_raster->advance_x_26_6 = (int32_t)face->glyph->advance.x;
  out_raster->required_bytes = required;
  if (required == 0)
    return R4FONT_OK;
  if (!output || output_capacity < required)
    return R4FONT_ERROR_BUFFER;
  for (row = 0; row < bitmap->rows; row++)
  {
    const uint8_t* source;
    if (bitmap->pitch >= 0)
      source = bitmap->buffer + (size_t)row * (size_t)bitmap->pitch;
    else
      source = bitmap->buffer +
               (size_t)(bitmap->rows - 1 - row) * (size_t)(-bitmap->pitch);
    memcpy(output + (size_t)row * bitmap->width, source, bitmap->width);
  }
  return R4FONT_OK;
}
