/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "r4nak_libc.h"
#include "util/log.h"
#include "../Bindings/C/r4aco.h"

extern void *r4aco_port_allocate(size_t,size_t);
extern void r4aco_port_deallocate(void *);
extern void *r4aco_port_reallocate(void *,size_t);
extern void *r4aco_port_state(unsigned,size_t,size_t);
extern void *r4aco_port_key(const void *,size_t,size_t,const void *,void (*)(void *));
extern void r4aco_port_log(const char *,size_t);
extern _Noreturn void r4aco_port_fail(int);
extern int r4aco_port_finalizer(void (*)(void));

void *malloc(size_t n) { return r4aco_port_allocate(n,16); }
void free(void *p) { r4aco_port_deallocate(p); }
void *realloc(void *p,size_t n) { return r4aco_port_reallocate(p,n); }
void *calloc(size_t n,size_t width) {
   size_t size;if(__builtin_mul_overflow(n,width,&size))r4aco_port_fail(R4ACO_STATUS_MEMORY);
   return memset(malloc(size),0,size);
}
void *reallocarray(void *p,size_t n,size_t width) {
   size_t size;if(__builtin_mul_overflow(n,width,&size))r4aco_port_fail(R4ACO_STATUS_MEMORY);
   return realloc(p,size);
}
void *aligned_alloc(size_t alignment,size_t n) {
   if(!alignment || (alignment&(alignment-1)) || n%alignment) {errno=EINVAL;return NULL;}
   return r4aco_port_allocate(n,alignment);
}
int posix_memalign(void **p,size_t alignment,size_t n) {
   if(alignment<sizeof(void *) || (alignment&(alignment-1)))return EINVAL;
   *p=r4aco_port_allocate(n,alignment);return 0;
}
_Noreturn void abort(void) { r4aco_port_fail(R4ACO_STATUS_COMPILER); }
_Noreturn void exit(int value) { (void)value;abort(); }
_Noreturn void r4native_fatal(const char *message) { r4aco_port_log(message,strlen(message));abort(); }
_Noreturn void r4nak_port_assert(const char *what,const char *file,int line) {
   char text[512];int n=snprintf(text,sizeof(text),"ACO assertion: %s (%s:%d)\n",what,file,line);
   if(n>0)r4aco_port_log(text,(size_t)n<sizeof(text)?(size_t)n:sizeof(text)-1);
   abort();
}
int32_t r4native_console_write(const char *text,uint32_t bytes) { r4aco_port_log(text,bytes);return (int32_t)bytes; }
void os_log_message(const char *s) { r4aco_port_log(s,strlen(s)); }
const char *os_get_option(const char *name) { (void)name;return NULL; }
const char *os_get_option_cached(const char *name) { return os_get_option(name); }
const char *os_get_option_secure(const char *name) { return os_get_option(name); }
char *getenv(const char *name) { (void)name;return NULL; }
int rand(void) {
   uint32_t *value=r4aco_port_state(1,sizeof(*value),_Alignof(uint32_t));
   *value=*value*UINT32_C(1664525)+UINT32_C(1013904223);return (int)(*value&INT_MAX);
}
void mesa_log_v(enum mesa_log_level level,const char *tag,const char *format,va_list args) {
   if(level>MESA_DEFAULT_LOG_LEVEL)return;
   fprintf(stderr,"%s: ",tag);vfprintf(stderr,format,args);fputc('\n',stderr);
}
void mesa_log(enum mesa_log_level level,const char *tag,const char *format,...) {
   va_list args;va_start(args,format);mesa_log_v(level,tag,format,args);va_end(args);
}
void _mesa_log_multiline(enum mesa_log_level level,const char *tag,const char *lines) { mesa_log(level,tag,"%s",lines); }
void *r4native_cpp_state(const void *key,size_t size,size_t alignment,void (*initialize)(void *)) {
   return r4aco_port_key(key,size,alignment,NULL,initialize);
}
int r4native_register_finalizer(void (*callback)(void)) { return r4aco_port_finalizer(callback); }
/* Clang's control remains immutable. One isolated compiler worker is the
 * sole TLS user of its job; both values and keys retire with that job. */
struct emutls_control { uintptr_t size,alignment,index;const void *initial; };
void *__emutls_get_address(const struct emutls_control *control) {
   return r4aco_port_key(control,control->size,control->alignment,control->initial,NULL);
}
