/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
/* Host-only immutable table materialization from original FFmpeg initializers. */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <string.h>
#include "libavcodec/intrax8.c"
#include "VlcTableHost.h"
int main(void) {
 x8_vlc_init();
 puts("/* Generated from FFmpeg 9.0.1 intrax8.c. LGPL-2.1-or-later. */");
 table("static ","r4_vlc_buf",vlc_buf,FF_ARRAY_ELEMS(vlc_buf));
 pointers("static ","j_ac_vlc","[2][2][8]",(const VLCElem *const*)j_ac_vlc,sizeof(j_ac_vlc)/sizeof(void*),vlc_buf,FF_ARRAY_ELEMS(vlc_buf),"r4_vlc_buf");
 pointers("static ","j_dc_vlc","[2][8]",(const VLCElem *const*)j_dc_vlc,sizeof(j_dc_vlc)/sizeof(void*),vlc_buf,FF_ARRAY_ELEMS(vlc_buf),"r4_vlc_buf");
 pointers("static ","j_orient_vlc","[2][4]",(const VLCElem *const*)j_orient_vlc,sizeof(j_orient_vlc)/sizeof(void*),vlc_buf,FF_ARRAY_ELEMS(vlc_buf),"r4_vlc_buf");
 return ferror(stdout)?1:0;
}
