/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
/* Host-only immutable table materialization from original FFmpeg initializers. */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <string.h>
#include "libavcodec/msmpeg4_vc1_data.c"
#include "VlcTableHost.h"
int main(void) {
 msmp4_vc1_vlcs_init();
 puts("/* Generated from FFmpeg 9.0.1 msmpeg4_vc1_data.c. LGPL-2.1-or-later. */");
 table("static ","r4_vlc_buf",vlc_buf,FF_ARRAY_ELEMS(vlc_buf));
 table("","ff_msmp4_mb_i_vlc",ff_msmp4_mb_i_vlc,FF_ARRAY_ELEMS(ff_msmp4_mb_i_vlc));
 pointers("","ff_msmp4_dc_vlc","[2][2]",(const VLCElem *const*)ff_msmp4_dc_vlc,sizeof(ff_msmp4_dc_vlc)/sizeof(void*),vlc_buf,FF_ARRAY_ELEMS(vlc_buf),"r4_vlc_buf");
 return ferror(stdout)?1:0;
}
