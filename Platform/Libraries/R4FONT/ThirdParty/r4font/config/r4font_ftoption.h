#ifndef R4FONT_FTOPTION_H_
#define R4FONT_FTOPTION_H_

#include <freetype/config/ftoption.h>

/* R4FONT opens caller-owned memory faces only. */
#define FT_CONFIG_OPTION_DISABLE_STREAM_SUPPORT
#undef FT_CONFIG_OPTION_ENVIRONMENT_PROPERTIES

/* WOFF uses FreeType's bundled zlib subset; WOFF2 uses pinned Brotli C. */
#define FT_CONFIG_OPTION_USE_ZLIB
#define FT_CONFIG_OPTION_USE_BROTLI
#undef FT_CONFIG_OPTION_SYSTEM_ZLIB

/* Web fonts do not execute embedded TrueType bytecode. */
#undef TT_CONFIG_OPTION_BYTECODE_INTERPRETER
#undef TT_CONFIG_OPTION_UNPATENTED_HINTING

/* Basic pair kerning from both legacy kern and GPOS tables. */
#define TT_CONFIG_OPTION_GPOS_KERNING

#endif
