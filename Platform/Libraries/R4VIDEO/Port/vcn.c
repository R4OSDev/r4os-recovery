/*
 * R4OS VCN parser/DPB bridge. Copyright 2026 R4.
 * Mapping adapted from FFmpeg 9.0.1 nvdec_hevc.c (2016 Anton Khirnov),
 * nvdec_mpeg12.c/nvdec_vc1.c/nvdec_mjpeg.c (2017 Philip Langdale), vaapi_vp9.c
 * (2015-2017 Intel Corporation), and Mesa 26.2.2 si_video_dec.c.
 * SPDX-License-Identifier: LGPL-2.1-or-later
 * This port is free software under LGPL 2.1 or later, without warranty.
 * The complete license and corresponding originals accompany R4VIDEO.
 */
#include "hardware_private.h"
#include "r4video.h"
#define IntraPredMode R4HevcIntraPredMode
#include "libavcodec/hevc/hevcdec.h"
#undef IntraPredMode
#include "libavcodec/hevc/data.h"
#include "libavcodec/vp9shared.h"
#include "libavcodec/mpegvideo.h"
#include "libavcodec/mpegutils.h"
#include "libavcodec/vc1.h"
#include "libavcodec/mjpegdec.h"
#include "libavcodec/hwaccel_internal.h"
#include "libavutil/pixdesc.h"
#include "../../R4AMD/Port/vcn_parameters.h"
#include <string.h>
#include <limits.h>

static AVFrame *current(AVCodecContext *av)
{
    switch (av->codec_id) {
    case AV_CODEC_ID_HEVC: { HEVCContext *h=av->priv_data; return h->cur_frame?h->cur_frame->f:NULL; }
    case AV_CODEC_ID_VP9: return ((VP9SharedContext*)av->priv_data)->frames[CUR_FRAME].tf.f;
    case AV_CODEC_ID_MPEG2VIDEO: { MpegEncContext *s=av->priv_data; return s->cur_pic.ptr?s->cur_pic.ptr->f:NULL; }
    case AV_CODEC_ID_VC1: case AV_CODEC_ID_WMV3: { VC1Context *v=av->priv_data; return v->s.cur_pic.ptr?v->s.cur_pic.ptr->f:NULL; }
    case AV_CODEC_ID_MJPEG: return ((MJpegDecodeContext*)av->priv_data)->picture_ptr;
    default: return NULL;
    }
}
int r4video_vcn_sequence(AVCodecContext *av, struct r4video_nvdec_sequence *out)
{
    struct r4video_codec *owner=av->opaque;
    struct r4video_nvdec_sequence s={.codec=owner->config.codec,.bit_depth=8,.width=av->coded_width,.height=av->coded_height};
    switch (av->codec_id) {
    case AV_CODEC_ID_HEVC: {
        const HEVCContext *h=av->priv_data;
        if (!h->pps || !h->pps->sps) return R4VIDEO_ERROR_DECODE;
        const HEVCSPS *p=h->pps->sps;
        if (h->cur_layer || p->chroma_format_idc!=1 || p->separate_colour_plane || p->range_extension ||
            p->vui.field_seq_flag || !p->max_sub_layers) return R4VIDEO_ERROR_UNSUPPORTED;
        s.profile=p->ptl.general_ptl.profile_idc; s.level=p->ptl.general_ptl.level_idc;
        s.width=p->width; s.height=p->height; s.bit_depth=p->bit_depth;
        if (p->temporal_layer[p->max_sub_layers-1].max_dec_pic_buffering<1) return R4VIDEO_ERROR_DECODE;
        s.max_refs=p->temporal_layer[p->max_sub_layers-1].max_dec_pic_buffering-1;
        break;
    }
    case AV_CODEC_ID_VP9: {
        const VP9SharedContext *h=av->priv_data;
        const AVPixFmtDescriptor *fmt=av_pix_fmt_desc_get(av->sw_pix_fmt);
        if (!fmt || fmt->log2_chroma_w!=1 || fmt->log2_chroma_h!=1) return R4VIDEO_ERROR_UNSUPPORTED;
        s.profile=h->h.profile; s.bit_depth=h->h.bpp; s.width=av->width; s.height=av->height; s.max_refs=8;
        break;
    }
    case AV_CODEC_ID_MPEG2VIDEO: {
        const MpegEncContext *m=av->priv_data;
        if (!m->progressive_sequence || !m->progressive_frame || m->picture_structure!=PICT_FRAME || m->chroma_format!=1)
            return R4VIDEO_ERROR_UNSUPPORTED;
        s.profile=av->profile; s.level=av->level; s.width=av->width; s.height=av->height; s.max_refs=5;
        break;
    }
    case AV_CODEC_ID_VC1: case AV_CODEC_ID_WMV3: {
        const VC1Context *v=av->priv_data;
        if (v->interlace || v->field_mode || v->fcm || v->psf) return R4VIDEO_ERROR_UNSUPPORTED;
        s.profile=v->profile; s.level=v->level; s.width=av->width; s.height=av->height; s.max_refs=4;
        break;
    }
    case AV_CODEC_ID_MJPEG: {
        const MJpegDecodeContext *j=av->priv_data;
        if (j->bits!=8 || j->progressive || j->lossless || j->interlaced || j->nb_components!=3 ||
            j->h_count[0]!=2 || j->v_count[0]!=2 || j->h_count[1]!=1 || j->v_count[1]!=1 ||
            j->h_count[2]!=1 || j->v_count[2]!=1) return R4VIDEO_ERROR_UNSUPPORTED;
        s.profile=0; s.width=j->width; s.height=j->height;
        break;
    }
    default: return R4VIDEO_ERROR_UNSUPPORTED;
    }
    if (s.profile!=owner->config.profile || s.bit_depth!=owner->config.bit_depth || !s.width || !s.height ||
        s.width>owner->config.max_width || s.height>owner->config.max_height || (s.width|s.height)&1)
        return R4VIDEO_ERROR_UNSUPPORTED;
    s.width_mbs=(s.width+15)/16; s.height_mbs=(s.height+15)/16;
    *out=s;
    return 0;
}
/* Build one deduplicated list of canonical images. Per-codec descriptor IDs
 * index this list until the Zig owner resolves them to its physical DPB slots. */
static int reference(AVCodecContext *av, struct r4video_nvdec_picture *p, const AVFrame *frame, int32_t poc)
{
    if (!frame) return 255;
    void *surface=r4video_hw_reference(av,frame);
    if (!surface) return -1;
    for (unsigned i=0;i<p->reference_count;i++) if (p->references[i].image==surface) return i;
    if (p->reference_count>=16) return -1;
    unsigned i=p->reference_count++;
    p->references[i]=(struct r4video_nvdec_reference){.image=surface,.poc={poc,poc}};
    return i;
}
static int hevc(AVCodecContext *av, struct r4video_nvdec_picture *p, union r4amd_vcn_parameters *params)
{
    const HEVCContext *s=av->priv_data;
    const HEVCPPS *pps=s->pps;
    const HEVCSPS *sps=pps->sps;
    struct ac_video_dec_hevc *h=&params->hevc;
    if (pps->num_tile_columns>19 || pps->num_tile_rows>21 || pps->pps_range_extensions_flag)
        return R4VIDEO_ERROR_UNSUPPORTED;
    h->sps_max_dec_pic_buffering_minus1=p->sequence.max_refs;
    h->chroma_format_idc=1;
    h->pic_flags.irap_pic_flag=IS_IRAP(s); h->pic_flags.idr_pic_flag=IS_IDR(s);
    h->pic_flags.is_ref_pic_flag=1;
    h->sps_flags.separate_colour_plane_flag=sps->separate_colour_plane;
    h->sps_flags.scaling_list_enabled_flag=sps->scaling_list_enabled;
    h->sps_flags.amp_enabled_flag=sps->amp_enabled;
    h->sps_flags.sample_adaptive_offset_enabled_flag=sps->sao_enabled;
    h->sps_flags.pcm_enabled_flag=sps->pcm_enabled;
    h->sps_flags.pcm_loop_filter_disabled_flag=sps->pcm_loop_filter_disabled;
    h->sps_flags.long_term_ref_pics_present_flag=sps->long_term_ref_pics_present;
    h->sps_flags.sps_temporal_mvp_enabled_flag=sps->temporal_mvp_enabled;
    h->sps_flags.strong_intra_smoothing_enabled_flag=sps->strong_intra_smoothing_enabled;
    h->sps_flags.transform_skip_context_enabled_flag=sps->transform_skip_context_enabled;
    h->sps_flags.implicit_rdpcm_enabled_flag=sps->implicit_rdpcm_enabled;
    h->sps_flags.explicit_rdpcm_enabled_flag=sps->explicit_rdpcm_enabled;
    h->sps_flags.extended_precision_processing_flag=sps->extended_precision_processing;
    h->sps_flags.intra_smoothing_disabled_flag=sps->intra_smoothing_disabled;
    h->sps_flags.high_precision_offsets_enabled_flag=sps->high_precision_offsets_enabled;
    h->sps_flags.persistent_rice_adaptation_enabled_flag=sps->persistent_rice_adaptation_enabled;
    h->sps_flags.cabac_bypass_alignment_enabled_flag=sps->cabac_bypass_alignment_enabled;
    h->pps_flags.dependent_slice_segments_enabled_flag=pps->dependent_slice_segments_enabled_flag;
    h->pps_flags.output_flag_present_flag=pps->output_flag_present_flag;
    h->pps_flags.sign_data_hiding_enabled_flag=pps->sign_data_hiding_flag;
    h->pps_flags.cabac_init_present_flag=pps->cabac_init_present_flag;
    h->pps_flags.constrained_intra_pred_flag=pps->constrained_intra_pred_flag;
    h->pps_flags.transform_skip_enabled_flag=pps->transform_skip_enabled_flag;
    h->pps_flags.cu_qp_delta_enabled_flag=pps->cu_qp_delta_enabled_flag;
    h->pps_flags.pps_slice_chroma_qp_offsets_present_flag=pps->pic_slice_level_chroma_qp_offsets_present_flag;
    h->pps_flags.weighted_pred_flag=pps->weighted_pred_flag;
    h->pps_flags.weighted_bipred_flag=pps->weighted_bipred_flag;
    h->pps_flags.transquant_bypass_enabled_flag=pps->transquant_bypass_enable_flag;
    h->pps_flags.tiles_enabled_flag=pps->tiles_enabled_flag;
    h->pps_flags.entropy_coding_sync_enabled_flag=pps->entropy_coding_sync_enabled_flag;
    h->pps_flags.uniform_spacing_flag=pps->uniform_spacing_flag;
    h->pps_flags.loop_filter_across_tiles_enabled_flag=pps->loop_filter_across_tiles_enabled_flag;
    h->pps_flags.pps_loop_filter_across_slices_enabled_flag=pps->seq_loop_filter_across_slices_enabled_flag;
    h->pps_flags.deblocking_filter_override_enabled_flag=pps->deblocking_filter_override_enabled_flag;
    h->pps_flags.pps_deblocking_filter_disabled_flag=pps->disable_dbf;
    h->pps_flags.lists_modification_present_flag=pps->lists_modification_present_flag;
    h->pps_flags.slice_segment_header_extension_present_flag=pps->slice_header_extension_present_flag;
    h->pps_flags.cross_component_prediction_enabled_flag=pps->cross_component_prediction_enabled_flag;
    h->pps_flags.chroma_qp_offset_list_enabled_flag=pps->chroma_qp_offset_list_enabled_flag;
    h->pic_width_in_luma_samples=sps->width;
    h->pic_height_in_luma_samples=sps->height;
    h->bit_depth_luma_minus8=sps->bit_depth - 8;
    h->bit_depth_chroma_minus8=sps->bit_depth - 8;
    h->log2_max_pic_order_cnt_lsb_minus4=sps->log2_max_poc_lsb - 4;
    h->log2_min_luma_coding_block_size_minus3=sps->log2_min_cb_size - 3;
    h->log2_diff_max_min_luma_coding_block_size=sps->log2_diff_max_min_coding_block_size;
    h->log2_min_transform_block_size_minus2=sps->log2_min_tb_size - 2;
    h->log2_diff_max_min_transform_block_size=sps->log2_max_trafo_size - sps->log2_min_tb_size;
    h->max_transform_hierarchy_depth_inter=sps->max_transform_hierarchy_depth_inter;
    h->max_transform_hierarchy_depth_intra=sps->max_transform_hierarchy_depth_intra;
    h->pcm_sample_bit_depth_luma_minus1=sps->pcm_enabled ? sps->pcm.bit_depth - 1 : 0;
    h->pcm_sample_bit_depth_chroma_minus1=sps->pcm_enabled ? sps->pcm.bit_depth_chroma - 1 : 0;
    h->log2_min_pcm_luma_coding_block_size_minus3=sps->pcm_enabled ? sps->pcm.log2_min_pcm_cb_size - 3 : 0;
    h->log2_diff_max_min_pcm_luma_coding_block_size=sps->pcm.log2_max_pcm_cb_size - sps->pcm.log2_min_pcm_cb_size;
    h->num_extra_slice_header_bits=pps->num_extra_slice_header_bits;
    h->init_qp_minus26=pps->pic_init_qp_minus26;
    h->diff_cu_qp_delta_depth=pps->diff_cu_qp_delta_depth;
    h->pps_cb_qp_offset=pps->cb_qp_offset;
    h->pps_cr_qp_offset=pps->cr_qp_offset;
    h->pps_beta_offset_div2=pps->beta_offset / 2;
    h->pps_tc_offset_div2=pps->tc_offset / 2;
    h->log2_parallel_merge_level_minus2=pps->log2_parallel_merge_level - 2;
    h->log2_max_transform_skip_block_size_minus2=pps->log2_max_transform_skip_block_size - 2;
    h->diff_cu_chroma_qp_offset_depth=pps->diff_cu_chroma_qp_offset_depth;
    h->chroma_qp_offset_list_len_minus1=pps->chroma_qp_offset_list_len_minus1;
    h->log2_sao_offset_scale_luma=pps->log2_sao_offset_scale_luma;
    h->log2_sao_offset_scale_chroma=pps->log2_sao_offset_scale_chroma;
    h->num_short_term_ref_pic_sets=sps->nb_st_rps;
    h->num_long_term_ref_pics_sps=sps->num_long_term_ref_pics_sps;
    h->num_ref_idx_l0_default_active_minus1=pps->num_ref_idx_l0_default_active - 1;
    h->num_ref_idx_l1_default_active_minus1=pps->num_ref_idx_l1_default_active - 1;
    h->num_tile_columns_minus1=pps->num_tile_columns - 1;
    h->num_tile_rows_minus1=pps->num_tile_rows - 1;
    const ScalingList *sl=pps->scaling_list_data_present_flag?&pps->scaling_list:&sps->scaling_list;
    for (unsigned i=0;i<6;i++) {
        for (unsigned j=0;j<16;j++) {
            unsigned at=4*ff_hevc_diag_scan4x4_y[j]+ff_hevc_diag_scan4x4_x[j];
            h->scaling_list_4x4[i][j]=sl->sl[0][i][at];
        }
        for (unsigned j=0;j<64;j++) {
            unsigned at=8*ff_hevc_diag_scan8x8_y[j]+ff_hevc_diag_scan8x8_x[j];
            h->scaling_list_8x8[i][j]=sl->sl[1][i][at]; h->scaling_list_16x16[i][j]=sl->sl[2][i][at];
            if (i<2) h->scaling_list_32x32[i][j]=sl->sl[3][i*3][at];
        }
        h->scaling_list_dc_coef_16x16[i]=sl->sl_dc[0][i];
        if (i<2) h->scaling_list_dc_coef_32x32[i]=sl->sl_dc[1][i*3];
    }
    for (unsigned i=0;i<pps->num_tile_columns;i++) h->column_width_minus1[i]=pps->column_width[i]-1;
    for (unsigned i=0;i<pps->num_tile_rows;i++) h->row_height_minus1[i]=pps->row_height[i]-1;
    h->num_bits_for_st_ref_pic_set_in_slice=s->sh.short_term_rps?s->sh.short_term_ref_pic_set_size:0;
    h->num_delta_pocs_of_ref_rps_idx=s->sh.short_term_rps?s->sh.short_term_rps->rps_idx_num_delta_pocs:0;
    h->curr_poc=s->cur_frame->poc;
    for (unsigned i=0;i<15;i++) h->ref_pic_id_list[i]=255;
    memset(h->ref_pic_set_st_curr_before,255,8); memset(h->ref_pic_set_st_curr_after,255,8); memset(h->ref_pic_set_lt_curr,255,8);
    const HEVCLayerContext *layer=&s->layers[s->cur_layer];
    for (unsigned i=0;i<FF_ARRAY_ELEMS(layer->DPB);i++) {
        const HEVCFrame *ref=&layer->DPB[i];
        if (ref==s->cur_frame || !(ref->flags&(HEVC_FRAME_FLAG_SHORT_REF|HEVC_FRAME_FLAG_LONG_REF))) continue;
        int id=reference(av,p,ref->f,ref->poc);
        if (id<0 || id>=15) return R4VIDEO_ERROR_DECODE;
        h->ref_pic_id_list[id]=id; h->ref_poc_list[id]=ref->poc;
        if (ref->flags&HEVC_FRAME_FLAG_LONG_REF) h->used_for_long_term_ref_flags|=1u<<id;
    }
    const int sets[]={ST_CURR_BEF,ST_CURR_AFT,LT_CURR};
    uint8_t *dst[]={h->ref_pic_set_st_curr_before,h->ref_pic_set_st_curr_after,h->ref_pic_set_lt_curr};
    for (unsigned k=0;k<3;k++) {
        const RefPicList *list=&s->rps[sets[k]];
        if (list->nb_refs>8) return R4VIDEO_ERROR_UNSUPPORTED;
        for (int i=0;i<list->nb_refs;i++) {
            int found=-1;
            for (unsigned j=0;j<p->reference_count;j++) if (h->ref_poc_list[j]==list->list[i]) { found=j; break; }
            if (found<0) return R4VIDEO_ERROR_DECODE;
            dst[k][i]=found;
        }
    }
    return 0;
}
static int vp9(AVCodecContext *av, struct r4video_nvdec_picture *p, union r4amd_vcn_parameters *params)
{
    const VP9SharedContext *s=av->priv_data;
    const VP9BitstreamHeader *h=&s->h;
    struct ac_video_dec_vp9 *v=&params->vp9;
    v->profile=h->profile; v->width=av->width; v->height=av->height;
    v->bit_depth_luma_minus8=v->bit_depth_chroma_minus8=h->bpp-8;
    v->frame_type=!h->keyframe; v->frame_context_idx=h->framectxid; v->reset_frame_context=h->resetctx;
    v->pic_flags.error_resilient_mode=h->errorres; v->pic_flags.intra_only=h->intraonly;
    v->pic_flags.allow_high_precision_mv=!h->keyframe && h->highprecisionmvs;
    v->pic_flags.refresh_frame_context=h->refreshctx; v->pic_flags.frame_parallel_decoding_mode=h->parallelmode;
    v->pic_flags.show_frame=!h->invisible; v->pic_flags.use_prev_frame_mvs=h->use_last_frame_mvs;
    v->pic_flags.use_uncompressed_header=1;
    v->color_config_flags.subsampling_x=v->color_config_flags.subsampling_y=1;
    v->interp_filter=h->filtermode^(h->filtermode<=1);
    v->base_q_idx=h->yac_qi; v->y_dc_delta_q=h->ydc_qdelta; v->uv_ac_delta_q=h->uvac_qdelta; v->uv_dc_delta_q=h->uvdc_qdelta;
    v->log2_tile_cols=h->tiling.log2_tile_cols; v->log2_tile_rows=h->tiling.log2_tile_rows;
    v->uncompressed_header_size=h->uncompressed_header_size; v->compressed_header_size=h->compressed_header_size;
    v->loop_filter.loop_filter_level=h->filter.level; v->loop_filter.loop_filter_sharpness=h->filter.sharpness;
    v->loop_filter.loop_filter_flags.mode_ref_delta_enabled=h->lf_delta.enabled;
    v->loop_filter.loop_filter_flags.mode_ref_delta_update=h->lf_delta.updated;
    memcpy(v->loop_filter.loop_filter_ref_deltas,h->lf_delta.ref,4);
    memcpy(v->loop_filter.loop_filter_mode_deltas,h->lf_delta.mode,2);
    v->segmentation.flags.segmentation_enabled=h->segmentation.enabled;
    v->segmentation.flags.segmentation_update_map=h->segmentation.update_map;
    v->segmentation.flags.segmentation_temporal_update=h->segmentation.temporal;
    v->segmentation.flags.segmentation_abs_delta=h->segmentation.absolute_vals;
    /* CBS retains the raw update_data bit, including frames that reuse data. */
    const VP9RawFrameHeader *raw=s->frames[CUR_FRAME].frame_header;
    if (!raw) return R4VIDEO_ERROR_DECODE;
    v->segmentation.flags.segmentation_update_data=raw->segmentation_update_data;
    memcpy(v->segmentation.tree_probs,h->segmentation.prob,7);
    memset(v->segmentation.pred_probs,255,3);
    if (h->segmentation.temporal) memcpy(v->segmentation.pred_probs,h->segmentation.pred_prob,3);
    for (unsigned i=0;i<8;i++) {
        v->segmentation.feature_mask[i]=h->segmentation.feat[i].q_enabled | h->segmentation.feat[i].lf_enabled<<1 |
            h->segmentation.feat[i].ref_enabled<<2 | h->segmentation.feat[i].skip_enabled<<3;
        v->segmentation.feature_data[i][0]=h->segmentation.feat[i].q_val;
        v->segmentation.feature_data[i][1]=h->segmentation.feat[i].lf_val;
        v->segmentation.feature_data[i][2]=h->segmentation.feat[i].ref_val;
        v->segmentation.feature_data[i][3]=0;
        int id=h->keyframe?255:reference(av,p,s->refs[i].f,0);
        if (id<0) return R4VIDEO_ERROR_DECODE;
        v->ref_frame_id_list[i]=id;
    }
    for (unsigned i=0;i<3;i++) { v->ref_frames[i]=h->refidx[i]; v->ref_frame_sign_bias[i+1]=h->signbias[i]; }
    return 0;
}
static int mpeg2(AVCodecContext *av, struct r4video_nvdec_picture *p, union r4amd_vcn_parameters *params)
{
    const MpegEncContext *s=av->priv_data;
    struct ac_video_dec_mpeg2 *m=&params->mpeg2;
    m->load_intra_quantiser_matrix=m->load_nonintra_quantiser_matrix=1;
    for (unsigned i=0;i<64;i++) { unsigned at=s->idsp.idct_permutation[i]; m->intra_quantiser_matrix[i]=s->intra_matrix[at]; m->nonintra_quantiser_matrix[i]=s->inter_matrix[at]; }
    m->picture_coding_type=s->pict_type; m->intra_dc_precision=s->intra_dc_precision;
    m->pic_structure=s->picture_structure; m->top_field_first=s->top_field_first; m->frame_pred_frame_dct=s->frame_pred_frame_dct;
    m->concealment_motion_vectors=s->concealment_motion_vectors; m->q_scale_type=s->q_scale_type;
    m->intra_vlc_format=s->intra_vlc_format; m->alternate_scan=s->alternate_scan;
    for (unsigned a=0;a<2;a++) for (unsigned b=0;b<2;b++) m->f_code[a][b]=s->mpeg_f_code[a][b];
    if (s->pict_type!=AV_PICTURE_TYPE_I && reference(av,p,s->last_pic.ptr?s->last_pic.ptr->f:NULL,0)<0) return R4VIDEO_ERROR_DECODE;
    if (s->pict_type==AV_PICTURE_TYPE_B && reference(av,p,s->next_pic.ptr?s->next_pic.ptr->f:NULL,0)<0) return R4VIDEO_ERROR_DECODE;
    return 0;
}
static int vc1(AVCodecContext *av, struct r4video_nvdec_picture *p, union r4amd_vcn_parameters *params)
{
    const VC1Context *v=av->priv_data;
    const MpegEncContext *s=&v->s;
    struct ac_video_dec_vc1 *c=&params->vc1;
    c->profile=v->profile;
    c->level=v->level;
    c->postprocflag=v->postprocflag;
    c->pulldown=v->broadcast;
    c->interlace=v->interlace;
    c->tfcntrflag=v->tfcntrflag;
    c->finterpflag=v->finterpflag;
    c->psf=v->psf;
    c->range_mapy_flag=v->range_mapy_flag;
    c->range_mapy=v->range_mapy;
    c->range_mapuv_flag=v->range_mapuv_flag;
    c->range_mapuv=v->range_mapuv;
    c->multires=v->multires;
    c->maxbframes=v->max_b_frames;
    c->overlap=v->overlap;
    c->quantizer=v->quantizer_mode;
    c->panscan_flag=v->panscanflag;
    c->refdist_flag=v->refdist_flag;
    c->vstransform=v->vstransform;
    c->syncmarker=v->resync_marker;
    c->rangered=v->rangered;
    c->loopfilter=v->loop_filter;
    c->fastuvmc=v->fastuvmc;
    c->extended_mv=v->extended_mv;
    c->extended_dmv=v->extended_dmv;
    c->dquant=v->dquant;
    if (s->pict_type!=AV_PICTURE_TYPE_I && s->pict_type!=AV_PICTURE_TYPE_BI &&
        reference(av,p,s->last_pic.ptr?s->last_pic.ptr->f:NULL,0)<0) return R4VIDEO_ERROR_DECODE;
    if (s->pict_type==AV_PICTURE_TYPE_B && reference(av,p,s->next_pic.ptr?s->next_pic.ptr->f:NULL,0)<0) return R4VIDEO_ERROR_DECODE;
    return 0;
}
static int start(AVCodecContext *av, const AVBufferRef *buffer_ref, const uint8_t *bytes, uint32_t size)
{
    (void)buffer_ref; (void)bytes; (void)size;
    struct r4video_nvdec_picture p={0};
    union r4amd_vcn_parameters params={0};
    int rc=r4video_vcn_sequence(av,&p.sequence);
    if (!rc) switch (av->codec_id) {
    case AV_CODEC_ID_HEVC: rc=hevc(av,&p,&params); break;
    case AV_CODEC_ID_VP9: rc=vp9(av,&p,&params); break;
    case AV_CODEC_ID_MPEG2VIDEO: rc=mpeg2(av,&p,&params); break;
    case AV_CODEC_ID_VC1: case AV_CODEC_ID_WMV3: rc=vc1(av,&p,&params); break;
    case AV_CODEC_ID_MJPEG: break;
    default: rc=R4VIDEO_ERROR_UNSUPPORTED;
    }
    if (rc) return r4video_hw_error(av,rc);
    p.codec_parameters=&params; p.codec_parameter_bytes=sizeof(params);
    rc=r4video_hw_begin(av,current(av),&p);
    if (!rc && av->codec_id==AV_CODEC_ID_MJPEG) {
        /* FFmpeg's raw_image_buffer starts directly after SOI. JPEG1 consumes
         * the complete coded image, once, rather than entropy-only slices. */
        static const uint8_t soi[2]={0xff,0xd8};
        rc=r4video_hw_slice(av,current(av),soi,2);
        if (!rc) rc=r4video_hw_slice(av,current(av),bytes,size);
    }
    return rc;
}
static int slice(AVCodecContext *av,const uint8_t *bytes,uint32_t size)
{ return av->codec_id==AV_CODEC_ID_MJPEG?0:r4video_hw_slice(av,current(av),bytes,size); }
static int end(AVCodecContext *av) { return r4video_hw_end(av,current(av)); }
#define ACCEL(codec_name,codec_id) const FFHWAccel ff_##codec_name##_r4os_vcn_hwaccel={ \
    .p.name=#codec_name "_r4os_vcn", .p.type=AVMEDIA_TYPE_VIDEO, .p.id=codec_id, .p.pix_fmt=AV_PIX_FMT_R4OS_NVDEC, \
    .start_frame=start,.decode_slice=slice,.end_frame=end,.init=r4video_hw_init,.frame_priv_data_size=1 }
ACCEL(hevc,AV_CODEC_ID_HEVC);
ACCEL(vp9,AV_CODEC_ID_VP9);
ACCEL(mpeg2,AV_CODEC_ID_MPEG2VIDEO);
ACCEL(vc1,AV_CODEC_ID_VC1);
ACCEL(wmv3,AV_CODEC_ID_WMV3);
ACCEL(mjpeg,AV_CODEC_ID_MJPEG);
