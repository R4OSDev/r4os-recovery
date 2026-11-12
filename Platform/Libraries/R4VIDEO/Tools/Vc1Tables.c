/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
/* Host-only immutable table materialization from original FFmpeg initializers. */
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdarg.h>
#include <string.h>
#include "libavcodec/vc1dec.c"
#include "VlcTableHost.h"
int main(void) {
 vc1_init_static();
 puts("/* Generated from FFmpeg 9.0.1 vc1dec.c. LGPL-2.1-or-later. */");
 table("static ","r4_vlc_table",vlc_table,FF_ARRAY_ELEMS(vlc_table));
 table("","ff_vc1_imode_vlc",ff_vc1_imode_vlc,FF_ARRAY_ELEMS(ff_vc1_imode_vlc));
 table("","ff_vc1_norm2_vlc",ff_vc1_norm2_vlc,FF_ARRAY_ELEMS(ff_vc1_norm2_vlc));
 table("","ff_vc1_norm6_vlc",ff_vc1_norm6_vlc,FF_ARRAY_ELEMS(ff_vc1_norm6_vlc));
 pointers("","ff_vc1_ttmb_vlc","[3]",(const VLCElem *const*)ff_vc1_ttmb_vlc,sizeof(ff_vc1_ttmb_vlc)/sizeof(void*),vlc_table,FF_ARRAY_ELEMS(vlc_table),"r4_vlc_table");
 pointers("","ff_vc1_mv_diff_vlc","[4]",(const VLCElem *const*)ff_vc1_mv_diff_vlc,sizeof(ff_vc1_mv_diff_vlc)/sizeof(void*),vlc_table,FF_ARRAY_ELEMS(vlc_table),"r4_vlc_table");
 pointers("","ff_vc1_cbpcy_p_vlc","[4]",(const VLCElem *const*)ff_vc1_cbpcy_p_vlc,sizeof(ff_vc1_cbpcy_p_vlc)/sizeof(void*),vlc_table,FF_ARRAY_ELEMS(vlc_table),"r4_vlc_table");
 pointers("","ff_vc1_icbpcy_vlc","[8]",(const VLCElem *const*)ff_vc1_icbpcy_vlc,sizeof(ff_vc1_icbpcy_vlc)/sizeof(void*),vlc_table,FF_ARRAY_ELEMS(vlc_table),"r4_vlc_table");
 pointers("","ff_vc1_4mv_block_pattern_vlc","[4]",(const VLCElem *const*)ff_vc1_4mv_block_pattern_vlc,sizeof(ff_vc1_4mv_block_pattern_vlc)/sizeof(void*),vlc_table,FF_ARRAY_ELEMS(vlc_table),"r4_vlc_table");
 pointers("","ff_vc1_2mv_block_pattern_vlc","[4]",(const VLCElem *const*)ff_vc1_2mv_block_pattern_vlc,sizeof(ff_vc1_2mv_block_pattern_vlc)/sizeof(void*),vlc_table,FF_ARRAY_ELEMS(vlc_table),"r4_vlc_table");
 pointers("","ff_vc1_ttblk_vlc","[3]",(const VLCElem *const*)ff_vc1_ttblk_vlc,sizeof(ff_vc1_ttblk_vlc)/sizeof(void*),vlc_table,FF_ARRAY_ELEMS(vlc_table),"r4_vlc_table");
 pointers("","ff_vc1_subblkpat_vlc","[3]",(const VLCElem *const*)ff_vc1_subblkpat_vlc,sizeof(ff_vc1_subblkpat_vlc)/sizeof(void*),vlc_table,FF_ARRAY_ELEMS(vlc_table),"r4_vlc_table");
 pointers("","ff_vc1_intfr_4mv_mbmode_vlc","[4]",(const VLCElem *const*)ff_vc1_intfr_4mv_mbmode_vlc,sizeof(ff_vc1_intfr_4mv_mbmode_vlc)/sizeof(void*),vlc_table,FF_ARRAY_ELEMS(vlc_table),"r4_vlc_table");
 pointers("","ff_vc1_intfr_non4mv_mbmode_vlc","[4]",(const VLCElem *const*)ff_vc1_intfr_non4mv_mbmode_vlc,sizeof(ff_vc1_intfr_non4mv_mbmode_vlc)/sizeof(void*),vlc_table,FF_ARRAY_ELEMS(vlc_table),"r4_vlc_table");
 pointers("","ff_vc1_if_mmv_mbmode_vlc","[8]",(const VLCElem *const*)ff_vc1_if_mmv_mbmode_vlc,sizeof(ff_vc1_if_mmv_mbmode_vlc)/sizeof(void*),vlc_table,FF_ARRAY_ELEMS(vlc_table),"r4_vlc_table");
 pointers("","ff_vc1_if_1mv_mbmode_vlc","[8]",(const VLCElem *const*)ff_vc1_if_1mv_mbmode_vlc,sizeof(ff_vc1_if_1mv_mbmode_vlc)/sizeof(void*),vlc_table,FF_ARRAY_ELEMS(vlc_table),"r4_vlc_table");
 pointers("","ff_vc1_1ref_mvdata_vlc","[4]",(const VLCElem *const*)ff_vc1_1ref_mvdata_vlc,sizeof(ff_vc1_1ref_mvdata_vlc)/sizeof(void*),vlc_table,FF_ARRAY_ELEMS(vlc_table),"r4_vlc_table");
 pointers("","ff_vc1_2ref_mvdata_vlc","[8]",(const VLCElem *const*)ff_vc1_2ref_mvdata_vlc,sizeof(ff_vc1_2ref_mvdata_vlc)/sizeof(void*),vlc_table,FF_ARRAY_ELEMS(vlc_table),"r4_vlc_table");
 pointers("","ff_vc1_ac_coeff_table","[8]",(const VLCElem *const*)ff_vc1_ac_coeff_table,sizeof(ff_vc1_ac_coeff_table)/sizeof(void*),vlc_table,FF_ARRAY_ELEMS(vlc_table),"r4_vlc_table");
 return ferror(stdout)?1:0;
}
