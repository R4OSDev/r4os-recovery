#ifndef R4FONT_FREESTANDING_SETJMP_H
#define R4FONT_FREESTANDING_SETJMP_H

typedef void *jmp_buf[5];
#define setjmp(buffer) __builtin_setjmp(buffer)
#define longjmp(buffer, value) ((void)(value), __builtin_longjmp(buffer, 1))

#endif
