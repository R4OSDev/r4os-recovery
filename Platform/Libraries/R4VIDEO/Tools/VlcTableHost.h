/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
/* Host-only immutable table materialization from original FFmpeg initializers. */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <string.h>

void *av_malloc(size_t n) { return malloc(n); }
void *av_malloc_array(size_t n,size_t z) { return z && n>SIZE_MAX/z?NULL:malloc(n*z); }
void *av_mallocz(size_t n) { return calloc(1,n); }
void *av_realloc_f(void *p,size_t n,size_t z) { if(z && n>SIZE_MAX/z){free(p);return NULL;}return realloc(p,n*z); }
void av_free(void *p) { free(p); }
void av_freep(void *p) { void **q=p;free(*q);*q=NULL; }
void av_log(void *c,int level,const char *fmt,...) { (void)c;(void)level;va_list a;va_start(a,fmt);vfprintf(stderr,fmt,a);va_end(a);exit(1); }
void avpriv_request_sample(void *c,const char *fmt,...) { (void)c;(void)fmt;abort(); }
static void table(const char *storage,const char *name,const VLCElem *p,size_t n) {
 printf("%sconst VLCElem %s[%u] = {\n",storage,name,(unsigned)n);
 for(size_t i=0;i<n;i++)printf("{.sym=%d,.len=%d},%s",p[i].sym,p[i].len,i%8==7?"\n":"");
 puts("\n};");
}
static void pointers(const char *storage,const char *name,const char *dims,const VLCElem *const *p,size_t n,const VLCElem *base,size_t capacity,const char *base_name) {
 printf("%sconst VLCElem *const %s%s = {",storage,name,dims);
 for(size_t i=0;i<n;i++) {
  if(!p[i])printf("NULL,");
  else { if(p[i]<base || p[i]>=base+capacity)abort(); printf("%s+%u,",base_name,(unsigned)(p[i]-base)); }
 }
 puts("};");
}
