#ifndef R4FONT_HELPERS_H
#define R4FONT_HELPERS_H
#include "r4font.h"
#include <r4libraries/helpers.h>
/* Keep callback descriptors at their exact address through decoder teardown;
 * close faces before their decoder. R4FontStore cached views expire on cache
 * mutation. Free imported FNT/FON output with its original allocator through
 * R4Library_freeBytes. See Shared/Rust/README.md. */
#endif
