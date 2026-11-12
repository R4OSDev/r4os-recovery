/* Compile the library-owned typed inline boundary once for Rust callers. */
#include <r4os/abi.h>
#define static
#define inline
#include "../C/include/r4libraries/helpers.h"
