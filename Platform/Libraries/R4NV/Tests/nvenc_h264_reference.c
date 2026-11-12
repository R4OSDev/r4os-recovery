#include <stdio.h>
#include <string.h>
#include <stddef.h>
#include "nvenc_drv.h"
_Static_assert(sizeof(nvenc_h264_drv_pic_setup_s)==512, "picture ABI");
_Static_assert(sizeof(nvenc_h264_slice_control_s)==128, "slice ABI");
_Static_assert(sizeof(nvenc_h264_me_control_s)==192, "ME ABI");
_Static_assert(sizeof(nvenc_h264_md_control_s)==128, "MD ABI");
_Static_assert(sizeof(nvenc_h264_quant_control_s)==192, "quant ABI");
_Static_assert(sizeof(nvenc_h264_coloc_mb_s)==64, "coloc ABI");
_Static_assert(offsetof(nvenc_stat_data_s,slice_stat)==128, "status ABI");

static nvenc_h264_surface_cfg_s surface(unsigned int block, unsigned int tiled) {
    nvenc_h264_surface_cfg_s s={0};
    s.frame_width_minus1=63; s.frame_height_minus1=47;
    s.sfc_pitch=128; s.sfc_pitch_chroma=64;
    s.block_height=block; s.tiled_16x16=tiled;
    s.chroma_top_frm_offset=8192/256;
    return s;
}
static int emit(FILE *file, unsigned int variant) {
    nvenc_h264_drv_pic_setup_s p={0};
    nvenc_h264_slice_control_s slice={0};
    nvenc_h264_me_control_s me={0};
    nvenc_h264_md_control_s md={0};
    nvenc_h264_quant_control_s q={0};
    unsigned int qp=variant ? 51 : 0;
    p.magic=NV_NVENC_DRV_MAGIC_VALUE;
    p.refpic_cfg=surface(2,0);
    p.input_cfg=surface(variant ? 4 : 2,0);
    p.outputpic_cfg=p.refpic_cfg;
    p.sps_data.profile_idc=66; p.sps_data.level_idc=51;
    p.sps_data.chroma_format_idc=1; p.sps_data.pic_order_cnt_type=2;
    p.sps_data.log2_max_frame_num_minus4=12; p.sps_data.frame_mbs_only=1;
    p.pps_data.pic_init_qp_minus26=(int)qp-26;
    p.pps_data.deblocking_filter_control_present_flag=1;
    for(unsigned int i=0;i<3;i++) p.rate_control.QP[i]=p.rate_control.minQP[i]=p.rate_control.maxQP[i]=qp;
    memset(p.pic_control.l0,-1,sizeof p.pic_control.l0);
    memset(p.pic_control.l1,-1,sizeof p.pic_control.l1);
    if(variant){ p.pic_control.l0[0]=0; p.pic_control.temp_dist_l0[0]=2; }
    p.pic_control.max_byte_count_before_resid_zero=variant ? 8388608 : 4096;
    p.pic_control.frame_num=variant ? 65535 : 0;
    p.pic_control.idr_pic_id=65535;
    p.pic_control.slice_control_offset=sizeof p;
    p.pic_control.me_control_offset=sizeof p+sizeof slice;
    p.pic_control.md_control_offset=sizeof p+sizeof slice+sizeof me;
    p.pic_control.q_control_offset=sizeof p+sizeof slice+sizeof me+sizeof md;
    p.pic_control.hist_buf_size=((4+16)*H264_HIST_BLOCK_SIZE+255)&~255U;
    p.pic_control.bitstream_buf_size=p.pic_control.max_byte_count_before_resid_zero;
    p.pic_control.pic_type=variant ? 0 : 3;
    p.pic_control.ref_pic_flag=1; p.pic_control.slice_mode=0; p.pic_control.ipcm_rewind_enable=0;
    p.pic_control.cur_interview_ref_pic=-1; p.pic_control.prev_interview_ref_pic=-1;
    p.pic_control.codec=0; p.pic_control.e4byteStartCode=1;
    p.pic_control.slice_stat_offset=offsetof(nvenc_stat_data_s,slice_stat);
    p.pic_control.strips_in_frame=1; p.pic_control.slice_encoding_row_num=3;
    p.gpTimer_timeout_val=50000000;
    slice.num_mb=12; slice.qp_avr=qp; slice.qp_slice_min=qp; slice.qp_slice_max=qp;
    slice.force_intra=!variant;
    me.refinement_mode=1; me.refine_on_search_enable=1;
    if(variant){
        me.predsrc.self_spatial_explicit=1; me.predsrc.self_spatial_search=1;
        me.predsrc.self_spatial_refine=1; me.predsrc.self_spatial_enable=1;
        me.predsrc.const_mv_explicit=1; me.predsrc.const_mv_search=1;
        me.predsrc.const_mv_refine=1; me.predsrc.const_mv_enable=1;
    }
    me.shape0.bitmask[0]=me.shape0.bitmask[1]=0xffffffff;
    me.shape0.hor_adjust=me.shape0.ver_adjust=1;
    me.mbc_mb_size=4;
    me.hint_type0=0; me.hint_type1=1; me.hint_type2=2; me.hint_type3=3; me.hint_type4=4;
    md.intra_luma4x4_mode_enable=0x1ff;
    md.intra_luma16x16_mode_enable=md.intra_chroma_mode_enable=0xf;
    if(variant){md.l0_part_16x16_enable=md.l0_part_16x8_enable=md.l0_part_8x16_enable=md.l0_part_8x8_enable=1; md.pskip_enable=1;}
    md.mv_cost_enable=1; md.intra_most_prob_force_on=1; md.early_intra_mode_control=3; md.ip_search_mode=5;
    md.intra_ssd_cnt_4x4=1; md.intra_ssd_cnt_8x8=2; md.intra_ssd_cnt_16x16=2;
    md.skip_evaluate_enable=1; md.rdo_level=1; md.tu_search_num=4; md.num_1div8_lambda_ssd=1;
    return fwrite(&p,1,sizeof p,file)==sizeof p && fwrite(&slice,1,sizeof slice,file)==sizeof slice &&
        fwrite(&me,1,sizeof me,file)==sizeof me && fwrite(&md,1,sizeof md,file)==sizeof md && fwrite(&q,1,sizeof q,file)==sizeof q;
}
int main(int argc,char **argv){
    if(argc!=2)return 1;
    FILE *file=fopen(argv[1],"wb"); if(!file)return 2;
    int success=emit(file,0)&&emit(file,1);
    if(fclose(file))return 3;
    return success ? 0 : 4;
}
