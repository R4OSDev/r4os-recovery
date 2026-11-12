/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "../../Shared/Native/stdio.c"

/* The compiler admits memory streams only. Environment-driven source dumps
 * and replacement files are disabled, and cannot silently open host paths. */
FILE *fopen(const char *name,const char *mode) { (void)name;(void)mode;errno=ENOSYS;return NULL; }
size_t fread(void *data,size_t size,size_t count,FILE *file) {
   if(!size || !count)return 0;
   size_t requested;
   if(!file || !data || is_console(file) || __builtin_mul_overflow(size,count,&requested)) {
      if(file)file->failed=true;errno=EINVAL;return 0;
   }
   if(file->position>=file->length)return 0;
   size_t available=file->length-file->position;
   size_t bytes=requested<available?requested:available;
   memcpy(data,file->bytes+file->position,bytes);file->position+=bytes;
   return bytes/size;
}
