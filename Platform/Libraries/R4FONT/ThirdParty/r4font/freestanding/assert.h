#ifndef R4FONT_FREESTANDING_ASSERT_H
#define R4FONT_FREESTANDING_ASSERT_H
#define assert(expression) ((void)sizeof(expression))
#endif
