/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
/* Host-only immutable table materialization from original FFmpeg initializers. */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <string.h>
#include "libavcodec/mpeg12.c"
#include "VlcTableHost.h"
int main(void) {
 mpeg12_init_vlcs();
 puts("/* Generated from FFmpeg 9.0.1 mpeg12.c. LGPL-2.1-or-later. */");
 table("","ff_mv_vlc",ff_mv_vlc,FF_ARRAY_ELEMS(ff_mv_vlc));
 table("","ff_dc_lum_vlc",ff_dc_lum_vlc,FF_ARRAY_ELEMS(ff_dc_lum_vlc));
 table("","ff_dc_chroma_vlc",ff_dc_chroma_vlc,FF_ARRAY_ELEMS(ff_dc_chroma_vlc));
 table("","ff_mbincr_vlc",ff_mbincr_vlc,FF_ARRAY_ELEMS(ff_mbincr_vlc));
 table("","ff_mb_ptype_vlc",ff_mb_ptype_vlc,FF_ARRAY_ELEMS(ff_mb_ptype_vlc));
 table("","ff_mb_btype_vlc",ff_mb_btype_vlc,FF_ARRAY_ELEMS(ff_mb_btype_vlc));
 table("","ff_mb_pat_vlc",ff_mb_pat_vlc,FF_ARRAY_ELEMS(ff_mb_pat_vlc));
 table("","ff_mpeg1_rl_vlc",ff_mpeg1_rl_vlc,FF_ARRAY_ELEMS(ff_mpeg1_rl_vlc));
 table("","ff_mpeg2_rl_vlc",ff_mpeg2_rl_vlc,FF_ARRAY_ELEMS(ff_mpeg2_rl_vlc));
 return ferror(stdout)?1:0;
}
