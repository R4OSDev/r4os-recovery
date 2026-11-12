#include <ft2build.h>
#include FT_CONFIG_CONFIG_H
#include <freetype/internal/ftobjs.h>

/* R4FONT always creates a library with caller-owned FT_Memory.  These two
 * symbols only satisfy the unused FT_Init_FreeType compatibility entry point.
 */
FT_BASE_DEF( FT_Memory )
FT_New_Memory( void )
{
  return NULL;
}

FT_BASE_DEF( void )
FT_Done_Memory( FT_Memory memory )
{
  FT_UNUSED( memory );
}
