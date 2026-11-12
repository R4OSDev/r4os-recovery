#ifndef R4FONT_NATIVE_H_
#define R4FONT_NATIVE_H_

#include <stddef.h>
#include <stdint.h>

typedef void* (*R4FontAllocFn)(void* user, size_t size, size_t alignment);
typedef void* (*R4FontReallocFn)(void* user, void* block, size_t old_size,
                                 size_t new_size, size_t alignment);
typedef void (*R4FontFreeFn)(void* user, void* block, size_t size,
                             size_t alignment);

typedef struct R4FontAllocator {
    void* user;
    R4FontAllocFn alloc;
    R4FontReallocFn realloc;
    R4FontFreeFn free;
} R4FontAllocator;

typedef struct R4FontDecoder R4FontDecoder;
typedef void* R4FontFace;

typedef enum R4FontFormat {
    R4FONT_FORMAT_UNKNOWN = 0,
    R4FONT_FORMAT_TTF = 1,
    R4FONT_FORMAT_OTF_CFF = 2,
    R4FONT_FORMAT_WOFF = 3,
    R4FONT_FORMAT_WOFF2 = 4,
    R4FONT_FORMAT_COLLECTION = 5
} R4FontFormat;

typedef enum R4FontResult {
    R4FONT_OK = 0,
    R4FONT_ERROR_ARGUMENT = -1,
    R4FONT_ERROR_OUT_OF_MEMORY = -2,
    R4FONT_ERROR_UNSUPPORTED = -3,
    R4FONT_ERROR_INVALID_FONT = -4,
    R4FONT_ERROR_FACE_INDEX = -5,
    R4FONT_ERROR_GLYPH = -6,
    R4FONT_ERROR_BUFFER = -7,
    R4FONT_ERROR_TOO_LARGE = -8
} R4FontResult;

typedef struct R4FontDiagnostics {
    size_t current_bytes;
    size_t peak_bytes;
    size_t allocation_count;
    size_t reallocation_count;
    size_t reallocation_failure_count;
    size_t allocation_limit;
    int allocation_failed;
} R4FontDiagnostics;

typedef struct R4FontFaceInfo {
    uint32_t face_count;
    uint32_t face_index;
    uint32_t glyph_count;
    uint32_t units_per_em;
    int32_t ascender;
    int32_t descender;
    int32_t line_height;
    int32_t max_advance;
    uint32_t style_flags;
    const char* family;
    const char* style;
} R4FontFaceInfo;

typedef struct R4FontGlyphMetrics {
    uint32_t glyph_index;
    int32_t advance_x;
    int32_t advance_y;
    int32_t bearing_x;
    int32_t bearing_y;
    int32_t width;
    int32_t height;
} R4FontGlyphMetrics;

typedef struct R4FontRaster {
    uint32_t glyph_index;
    uint32_t width;
    uint32_t height;
    int32_t left;
    int32_t top;
    int32_t advance_x_26_6;
    size_t required_bytes;
} R4FontRaster;

R4FontFormat r4font_sniff(const uint8_t* bytes, size_t length);
int r4font_decoder_create(R4FontAllocator allocator, size_t allocation_limit,
                          R4FontDecoder** out_decoder);
void r4font_decoder_destroy(R4FontDecoder* decoder);
R4FontDiagnostics r4font_decoder_diagnostics(const R4FontDecoder* decoder);
int r4font_decoder_open_face(R4FontDecoder* decoder, const uint8_t* bytes,
                             size_t length, uint32_t face_index,
                             R4FontFace* out_face);
void r4font_close_face(R4FontFace face);
int r4font_face_info(R4FontFace face, R4FontFaceInfo* out_info);
uint32_t r4font_glyph_index(R4FontFace face, uint32_t codepoint);
int r4font_glyph_metrics(R4FontFace face, uint32_t glyph_index,
                         R4FontGlyphMetrics* out_metrics);
int r4font_kerning(R4FontFace face, uint32_t left_glyph,
                   uint32_t right_glyph, int32_t* out_x, int32_t* out_y);
int r4font_rasterize(R4FontFace face, uint32_t glyph_index,
                     uint32_t pixel_height, uint8_t* output,
                     size_t output_capacity, R4FontRaster* out_raster);

#endif
