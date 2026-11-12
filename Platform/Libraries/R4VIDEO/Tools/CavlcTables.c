/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
/* Host-only table materialization using the pinned FFmpeg initializer. */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <string.h>
#define R4OS_TABLEGEN 1
#include "libavcodec/h264_cavlc.c"

void *av_malloc(size_t n) { return malloc(n); }
void *av_malloc_array(size_t n, size_t z) { return z && n > SIZE_MAX/z ? NULL : malloc(n*z); }
void *av_mallocz(size_t n) { return calloc(1,n); }
void *av_realloc_f(void *p,size_t n,size_t z) { if(z && n>SIZE_MAX/z){free(p);return NULL;}return realloc(p,n*z); }
void av_free(void *p) { free(p); }
void av_freep(void *p) { void **q=p;free(*q);*q=NULL; }
void av_log(void *c,int level,const char *fmt,...) { (void)c;(void)level;va_list a;va_start(a,fmt);vfprintf(stderr,fmt,a);va_end(a);exit(1); }
void avpriv_request_sample(void *c,const char *fmt,...) { (void)c;(void)fmt;abort(); }
static void vlc(const char *name,const VLCElem *p,size_t n){
 printf("static const VLCElem %s[%u] = {\n",name,(unsigned)n);
 for(size_t i=0;i<n;i++)printf("{.sym=%d,.len=%d},%s",p[i].sym,p[i].len,i%8==7?"\n":"");
 puts("\n};");
}
static void pointers(const char *name,const VLCElem *const *p,size_t n){
 printf("static const VLCElem *const %s[%u] = {",name,(unsigned)n);
 for(size_t i=0;i<n;i++){
  if(!p[i])printf("NULL,");
  else { if(p[i]<run7_vlc_table || p[i]>=run7_vlc_table+FF_ARRAY_ELEMS(run7_vlc_table))abort();printf("run7_vlc_table+%u,",(unsigned)(p[i]-run7_vlc_table)); }
 }
 puts("};");
}
int main(void){
 ff_h264_decode_init_vlc();
 puts("/* Generated from FFmpeg 9.0.1 h264_cavlc.c and vlc.c. LGPL-2.1-or-later. */");
 puts("/* R4OS: immutable provider tables; no runtime initialization or process lookup. */");
 puts("static const int8_t cavlc_level_tab[7][256][2] = {");
 for(unsigned a=0;a<7;a++){puts("{");for(unsigned b=0;b<256;b++)printf("{%d,%d},%s",cavlc_level_tab[a][b][0],cavlc_level_tab[a][b][1],b%8==7?"\n":"");puts("},");}puts("};");
 vlc("run7_vlc_table",run7_vlc_table,FF_ARRAY_ELEMS(run7_vlc_table));
 vlc("chroma_dc_coeff_token_vlc_table",chroma_dc_coeff_token_vlc_table,FF_ARRAY_ELEMS(chroma_dc_coeff_token_vlc_table));
 vlc("chroma422_dc_coeff_token_vlc_table",chroma422_dc_coeff_token_vlc_table,FF_ARRAY_ELEMS(chroma422_dc_coeff_token_vlc_table));
 pointers("coeff_token_vlc",coeff_token_vlc,FF_ARRAY_ELEMS(coeff_token_vlc));
 pointers("total_zeros_vlc",total_zeros_vlc,FF_ARRAY_ELEMS(total_zeros_vlc));
 pointers("chroma_dc_total_zeros_vlc",chroma_dc_total_zeros_vlc,FF_ARRAY_ELEMS(chroma_dc_total_zeros_vlc));
 pointers("chroma422_dc_total_zeros_vlc",chroma422_dc_total_zeros_vlc,FF_ARRAY_ELEMS(chroma422_dc_total_zeros_vlc));
 pointers("run_vlc",run_vlc,FF_ARRAY_ELEMS(run_vlc));
 return ferror(stdout)?1:0;
}
