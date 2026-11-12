/* Generated from pinned Mesa 26.2.2. Copyright 2017-2026 Advanced Micro Devices, Inc.
 * SPDX-License-Identifier: MIT. Full originals/grant: ThirdParty/Mesa26.2.2/Original.
 * Regenerate with Tools/VcnCodecs.ps1 -Write. */
#include <string.h>
#include "vcn_metadata.h"
#include "vcn_wire.h"
#define PIPE_FORMAT_NV12 1
#define RDECODE_DITHERING_RANDOM 5
#define CLAMP(v,lo,hi) ((v)<(lo)?(lo):((v)>(hi)?(hi):(v)))
struct cmd_buffer { void *it_probs_ptr; };
struct ac_video_dec_decode_cmd { struct { unsigned format; } decode_surface; union r4amd_vcn_parameters codec_param; };
static uint32_t
build_hevc_msg(struct cmd_buffer *cmd_buf, struct ac_video_dec_decode_cmd *cmd, rvcn_dec_message_hevc_t *codec)
{
   struct ac_video_dec_hevc *hevc = &cmd->codec_param.hevc;
   rvcn_dec_hevc_its_t *its = cmd_buf->it_probs_ptr;
   rvcn_dec_message_hevc_t msg = {0};

   msg.sps_info_flags |= hevc->sps_flags.scaling_list_enabled_flag << 0;
   msg.sps_info_flags |= hevc->sps_flags.amp_enabled_flag << 1;
   msg.sps_info_flags |= hevc->sps_flags.sample_adaptive_offset_enabled_flag << 2;
   msg.sps_info_flags |= hevc->sps_flags.pcm_enabled_flag << 3;
   msg.sps_info_flags |= hevc->sps_flags.pcm_loop_filter_disabled_flag << 4;
   msg.sps_info_flags |= hevc->sps_flags.long_term_ref_pics_present_flag << 5;
   msg.sps_info_flags |= hevc->sps_flags.sps_temporal_mvp_enabled_flag << 6;
   msg.sps_info_flags |= hevc->sps_flags.strong_intra_smoothing_enabled_flag << 7;
   msg.sps_info_flags |= hevc->sps_flags.separate_colour_plane_flag << 8;
   msg.sps_info_flags |= !!hevc->num_bits_for_st_ref_pic_set_in_slice << 11;

   msg.pps_info_flags |= hevc->pps_flags.dependent_slice_segments_enabled_flag << 0;
   msg.pps_info_flags |= hevc->pps_flags.output_flag_present_flag << 1;
   msg.pps_info_flags |= hevc->pps_flags.sign_data_hiding_enabled_flag << 2;
   msg.pps_info_flags |= hevc->pps_flags.cabac_init_present_flag << 3;
   msg.pps_info_flags |= hevc->pps_flags.constrained_intra_pred_flag << 4;
   msg.pps_info_flags |= hevc->pps_flags.transform_skip_enabled_flag << 5;
   msg.pps_info_flags |= hevc->pps_flags.cu_qp_delta_enabled_flag << 6;
   msg.pps_info_flags |= hevc->pps_flags.pps_slice_chroma_qp_offsets_present_flag << 7;
   msg.pps_info_flags |= hevc->pps_flags.weighted_pred_flag << 8;
   msg.pps_info_flags |= hevc->pps_flags.weighted_bipred_flag << 9;
   msg.pps_info_flags |= hevc->pps_flags.transquant_bypass_enabled_flag << 10;
   msg.pps_info_flags |= hevc->pps_flags.tiles_enabled_flag << 11;
   msg.pps_info_flags |= hevc->pps_flags.entropy_coding_sync_enabled_flag << 12;
   msg.pps_info_flags |= hevc->pps_flags.uniform_spacing_flag << 13;
   msg.pps_info_flags |= hevc->pps_flags.loop_filter_across_tiles_enabled_flag << 14;
   msg.pps_info_flags |= hevc->pps_flags.pps_loop_filter_across_slices_enabled_flag << 15;
   msg.pps_info_flags |= hevc->pps_flags.deblocking_filter_override_enabled_flag << 16;
   msg.pps_info_flags |= hevc->pps_flags.pps_deblocking_filter_disabled_flag << 17;
   msg.pps_info_flags |= hevc->pps_flags.lists_modification_present_flag << 18;
   msg.pps_info_flags |= hevc->pps_flags.slice_segment_header_extension_present_flag << 19;

   msg.chroma_format = hevc->chroma_format_idc;
   msg.bit_depth_luma_minus8 = hevc->bit_depth_luma_minus8;
   msg.bit_depth_chroma_minus8 = hevc->bit_depth_chroma_minus8;
   msg.log2_max_pic_order_cnt_lsb_minus4 = hevc->log2_max_pic_order_cnt_lsb_minus4;
   msg.sps_max_dec_pic_buffering_minus1 = hevc->sps_max_dec_pic_buffering_minus1;
   msg.log2_min_luma_coding_block_size_minus3 = hevc->log2_min_luma_coding_block_size_minus3;
   msg.log2_diff_max_min_luma_coding_block_size = hevc->log2_diff_max_min_luma_coding_block_size;
   msg.log2_min_transform_block_size_minus2 = hevc->log2_min_transform_block_size_minus2;
   msg.log2_diff_max_min_transform_block_size = hevc->log2_diff_max_min_transform_block_size;
   msg.max_transform_hierarchy_depth_inter = hevc->max_transform_hierarchy_depth_inter;
   msg.max_transform_hierarchy_depth_intra = hevc->max_transform_hierarchy_depth_intra;
   msg.pcm_sample_bit_depth_luma_minus1 = hevc->pcm_sample_bit_depth_luma_minus1;
   msg.pcm_sample_bit_depth_chroma_minus1 = hevc->pcm_sample_bit_depth_chroma_minus1;
   msg.log2_min_pcm_luma_coding_block_size_minus3 = hevc->log2_min_pcm_luma_coding_block_size_minus3;
   msg.log2_diff_max_min_pcm_luma_coding_block_size = hevc->log2_diff_max_min_pcm_luma_coding_block_size;
   msg.num_extra_slice_header_bits = hevc->num_extra_slice_header_bits;
   msg.num_short_term_ref_pic_sets = hevc->num_short_term_ref_pic_sets;
   msg.num_long_term_ref_pic_sps = hevc->num_long_term_ref_pics_sps;
   msg.num_ref_idx_l0_default_active_minus1 = hevc->num_ref_idx_l0_default_active_minus1;
   msg.num_ref_idx_l1_default_active_minus1 = hevc->num_ref_idx_l1_default_active_minus1;
   msg.pps_cb_qp_offset = hevc->pps_cb_qp_offset;
   msg.pps_cr_qp_offset = hevc->pps_cr_qp_offset;
   msg.pps_beta_offset_div2 = hevc->pps_beta_offset_div2;
   msg.pps_tc_offset_div2 = hevc->pps_tc_offset_div2;
   msg.diff_cu_qp_delta_depth = hevc->diff_cu_qp_delta_depth;
   msg.num_tile_columns_minus1 = hevc->num_tile_columns_minus1;
   msg.num_tile_rows_minus1 = hevc->num_tile_rows_minus1;
   msg.log2_parallel_merge_level_minus2 = hevc->log2_parallel_merge_level_minus2;
   msg.st_rps_bits = hevc->num_bits_for_st_ref_pic_set_in_slice;
   msg.init_qp_minus26 = hevc->init_qp_minus26;
   msg.num_delta_pocs_ref_rps_idx = hevc->num_delta_pocs_of_ref_rps_idx;
   msg.curr_idx = hevc->curr_pic_id;
   msg.curr_poc = hevc->curr_poc;
   msg.highestTid = 0xff;
   msg.isNonRef = hevc->pic_flags.is_ref_pic_flag ? 0 : 1;

   if (hevc->bit_depth_luma_minus8 || hevc->bit_depth_chroma_minus8) {
      if (cmd->decode_surface.format == PIPE_FORMAT_NV12) {
         msg.luma_10to8 = RDECODE_DITHERING_RANDOM;
         msg.chroma_10to8 = RDECODE_DITHERING_RANDOM;
      } else {
         msg.p010_mode = 1;
         msg.msb_mode = 1;
      }
   }

   for (uint32_t i = 0; i < H265_TILE_COLS_LIST_SIZE; i++)
      msg.column_width_minus1[i] = hevc->column_width_minus1[i];

   for (uint32_t i = 0; i < H265_TILE_ROWS_LIST_SIZE; i++)
      msg.row_height_minus1[i] = hevc->row_height_minus1[i];

   for (uint32_t i = 0; i < H265_MAX_NUM_REF_PICS; i++) {
      msg.ref_pic_list[i] = hevc->ref_pic_id_list[i];
      msg.poc_list[i] = hevc->ref_poc_list[i];
   }

   for (uint32_t i = 0; i < H265_MAX_RPS_SIZE; i++) {
      msg.ref_pic_set_st_curr_before[i] = hevc->ref_pic_set_st_curr_before[i];
      msg.ref_pic_set_st_curr_after[i] = hevc->ref_pic_set_st_curr_after[i];
      msg.ref_pic_set_lt_curr[i] = hevc->ref_pic_set_lt_curr[i];
   }

   for (uint32_t i = 0; i < H265_SCALING_LIST_16X16_NUM_LISTS; i++)
      msg.ucScalingListDCCoefSizeID2[i] = hevc->scaling_list_dc_coef_16x16[i];

   for (uint32_t i = 0; i < H265_SCALING_LIST_32X32_NUM_LISTS; i++)
      msg.ucScalingListDCCoefSizeID3[i] = hevc->scaling_list_dc_coef_32x32[i];

   memcpy(its->scaling_list_4x4, hevc->scaling_list_4x4, sizeof(hevc->scaling_list_4x4));
   memcpy(its->scaling_list_8x8, hevc->scaling_list_8x8, sizeof(hevc->scaling_list_8x8));
   memcpy(its->scaling_list_16x16, hevc->scaling_list_16x16, sizeof(hevc->scaling_list_16x16));
   memcpy(its->scaling_list_32x32, hevc->scaling_list_32x32, sizeof(hevc->scaling_list_32x32));

   memcpy(codec, &msg, sizeof(msg));
   return sizeof(msg);
}

static uint32_t
build_vp9_msg(struct cmd_buffer *cmd_buf, struct ac_video_dec_decode_cmd *cmd, rvcn_dec_message_vp9_t *codec)
{
   struct ac_video_dec_vp9 *vp9 = &cmd->codec_param.vp9;
   rvcn_dec_vp9_probs_segment_t *probs = cmd_buf->it_probs_ptr;
   rvcn_dec_message_vp9_t msg = {0};

   /* Only 10 bit is supported for Profile 2 */
   if (vp9->bit_depth_chroma_minus8 > 2 || vp9->bit_depth_luma_minus8 > 2)
      return 0;

   msg.frame_header_flags |= (vp9->frame_type
                              << RDECODE_FRAME_HDR_INFO_VP9_FRAME_TYPE_SHIFT) &
                             RDECODE_FRAME_HDR_INFO_VP9_FRAME_TYPE_MASK;
   msg.frame_header_flags |= (vp9->pic_flags.error_resilient_mode
                              << RDECODE_FRAME_HDR_INFO_VP9_ERROR_RESILIENT_MODE_SHIFT) &
                             RDECODE_FRAME_HDR_INFO_VP9_ERROR_RESILIENT_MODE_MASK;
   msg.frame_header_flags |= (vp9->pic_flags.intra_only
                              << RDECODE_FRAME_HDR_INFO_VP9_INTRA_ONLY_SHIFT) &
                             RDECODE_FRAME_HDR_INFO_VP9_INTRA_ONLY_MASK;
   msg.frame_header_flags |= (vp9->pic_flags.allow_high_precision_mv
                              << RDECODE_FRAME_HDR_INFO_VP9_ALLOW_HIGH_PRECISION_MV_SHIFT) &
                             RDECODE_FRAME_HDR_INFO_VP9_ALLOW_HIGH_PRECISION_MV_MASK;
   msg.frame_header_flags |= (vp9->pic_flags.refresh_frame_context
                              << RDECODE_FRAME_HDR_INFO_VP9_REFRESH_FRAME_CONTEXT_SHIFT) &
                             RDECODE_FRAME_HDR_INFO_VP9_REFRESH_FRAME_CONTEXT_MASK;
   msg.frame_header_flags |= (vp9->pic_flags.frame_parallel_decoding_mode
                              << RDECODE_FRAME_HDR_INFO_VP9_FRAME_PARALLEL_DECODING_MODE_SHIFT) &
                             RDECODE_FRAME_HDR_INFO_VP9_FRAME_PARALLEL_DECODING_MODE_MASK;
   msg.frame_header_flags |= (vp9->segmentation.flags.segmentation_enabled
                              << RDECODE_FRAME_HDR_INFO_VP9_SEGMENTATION_ENABLED_SHIFT) &
                             RDECODE_FRAME_HDR_INFO_VP9_SEGMENTATION_ENABLED_MASK;
   msg.frame_header_flags |= (vp9->segmentation.flags.segmentation_update_map
                              << RDECODE_FRAME_HDR_INFO_VP9_SEGMENTATION_UPDATE_MAP_SHIFT) &
                             RDECODE_FRAME_HDR_INFO_VP9_SEGMENTATION_UPDATE_MAP_MASK;
   msg.frame_header_flags |= (vp9->segmentation.flags.segmentation_temporal_update
                              << RDECODE_FRAME_HDR_INFO_VP9_SEGMENTATION_TEMPORAL_UPDATE_SHIFT) &
                             RDECODE_FRAME_HDR_INFO_VP9_SEGMENTATION_TEMPORAL_UPDATE_MASK;
   msg.frame_header_flags |= (vp9->segmentation.flags.segmentation_update_data
                              << RDECODE_FRAME_HDR_INFO_VP9_SEGMENTATION_UPDATE_DATA_SHIFT) &
                             RDECODE_FRAME_HDR_INFO_VP9_SEGMENTATION_UPDATE_DATA_MASK;
   msg.frame_header_flags |= (vp9->loop_filter.loop_filter_flags.mode_ref_delta_enabled
                              << RDECODE_FRAME_HDR_INFO_VP9_MODE_REF_DELTA_ENABLED_SHIFT) &
                             RDECODE_FRAME_HDR_INFO_VP9_MODE_REF_DELTA_ENABLED_MASK;
   msg.frame_header_flags |= (vp9->loop_filter.loop_filter_flags.mode_ref_delta_update
                              << RDECODE_FRAME_HDR_INFO_VP9_MODE_REF_DELTA_UPDATE_SHIFT) &
                             RDECODE_FRAME_HDR_INFO_VP9_MODE_REF_DELTA_UPDATE_MASK;
   msg.frame_header_flags |= (vp9->pic_flags.use_prev_frame_mvs
                              << RDECODE_FRAME_HDR_INFO_VP9_USE_PREV_IN_FIND_MV_REFS_SHIFT) &
                             RDECODE_FRAME_HDR_INFO_VP9_USE_PREV_IN_FIND_MV_REFS_MASK;
   msg.frame_header_flags |= (vp9->pic_flags.use_uncompressed_header
                              << RDECODE_FRAME_HDR_INFO_VP9_USE_UNCOMPRESSED_HEADER_SHIFT) &
                             RDECODE_FRAME_HDR_INFO_VP9_USE_UNCOMPRESSED_HEADER_MASK;
   msg.frame_header_flags |= (!!vp9->uncompressed_header_offset
                              << RDECODE_FRAME_HDR_INFO_VP9_USE_FRAME_SIZE_AS_OFFSET_SHIFT) &
                             RDECODE_FRAME_HDR_INFO_VP9_USE_FRAME_SIZE_AS_OFFSET_MASK;

   msg.frame_context_idx = vp9->frame_context_idx;
   msg.reset_frame_context = vp9->reset_frame_context;
   msg.curr_pic_idx = vp9->cur_id;
   msg.interp_filter = vp9->interp_filter;
   msg.filter_level = vp9->loop_filter.loop_filter_level;
   msg.sharpness_level = vp9->loop_filter.loop_filter_sharpness;
   msg.base_qindex = vp9->base_q_idx;
   msg.y_dc_delta_q = vp9->y_dc_delta_q;
   msg.uv_ac_delta_q = vp9->uv_ac_delta_q;
   msg.uv_dc_delta_q = vp9->uv_dc_delta_q;
   msg.log2_tile_cols = vp9->log2_tile_cols;
   msg.log2_tile_rows = vp9->log2_tile_rows;
   msg.chroma_format = 1;
   msg.bit_depth_luma_minus8 = vp9->bit_depth_luma_minus8;
   msg.bit_depth_chroma_minus8 = vp9->bit_depth_chroma_minus8;
   msg.vp9_frame_size = vp9->uncompressed_header_offset;
   msg.uncompressed_header_size = vp9->uncompressed_header_size;
   msg.compressed_header_size = vp9->compressed_header_size;

   if (vp9->bit_depth_luma_minus8 || vp9->bit_depth_chroma_minus8) {
      if (cmd->decode_surface.format == PIPE_FORMAT_NV12) {
         msg.luma_10to8 = RDECODE_DITHERING_RANDOM;
         msg.chroma_10to8 = RDECODE_DITHERING_RANDOM;
      } else {
         msg.p010_mode = 1;
         msg.msb_mode = 1;
      }
   }

   const int32_t scale = 1 << (vp9->loop_filter.loop_filter_level >> 5);

   for (uint32_t seg_id = 0; seg_id < VP9_MAX_SEGMENTS; seg_id++) {
      int32_t base_level = vp9->loop_filter.loop_filter_level;

      if (vp9->segmentation.feature_mask[seg_id] & (1 << AC_VIDEO_DEC_VP9_SEG_LEVEL_ALT_LF)) {
         int32_t seg_data = vp9->segmentation.feature_data[seg_id][AC_VIDEO_DEC_VP9_SEG_LEVEL_ALT_LF];
         if (vp9->segmentation.flags.segmentation_abs_delta != VP9_SEG_ABS_DELTA)
            seg_data += base_level;
         base_level = CLAMP(seg_data, 0, VP9_MAX_LOOP_FILTER);
      }

      if (!vp9->loop_filter.loop_filter_flags.mode_ref_delta_enabled) {
         msg.lf_adj_level[seg_id][0][0] = base_level;
      } else {
         const int32_t intra_level = base_level + vp9->loop_filter.loop_filter_ref_deltas[0] * scale;
         msg.lf_adj_level[seg_id][0][0] = CLAMP(intra_level, 0, VP9_MAX_LOOP_FILTER);
      }

      for (uint32_t ref_type = 1; ref_type < VP9_MAX_REF_FRAMES; ref_type++) {
         for (uint32_t mode_type = 0; mode_type < VP9_LOOP_FILTER_ADJUSTMENTS; mode_type++) {
            if (!vp9->loop_filter.loop_filter_flags.mode_ref_delta_enabled) {
               msg.lf_adj_level[seg_id][ref_type][mode_type] = base_level;
            } else {
               const int32_t interLevel = base_level +
                  (vp9->loop_filter.loop_filter_ref_deltas[ref_type] +
                   vp9->loop_filter.loop_filter_mode_deltas[mode_type]) * scale;
               msg.lf_adj_level[seg_id][ref_type][mode_type] = CLAMP(interLevel, 0, VP9_MAX_LOOP_FILTER);
            }
         }
      }
   }

   for (uint32_t i = 0; i < VP9_NUM_REF_FRAMES; i++)
      msg.ref_frame_map[i] = vp9->ref_frame_id_list[i];

   for (uint32_t i = 0; i < VP9_TOTAL_REFS_PER_FRAME; i++) {
      msg.frame_refs[i] = vp9->ref_frames[i];
      msg.ref_frame_sign_bias[i] = vp9->ref_frame_sign_bias[i + 1];
   }

   if (vp9->segmentation.flags.segmentation_enabled) {
      for (uint32_t i = 0; i < VP9_MAX_SEGMENTS; i++) {
         probs->seg.feature_data[i] =
            (vp9->segmentation.feature_data[i][0] & 0xFFFF) |
            ((vp9->segmentation.feature_data[i][1] & 0xFF) << 16) |
            ((vp9->segmentation.feature_data[i][2] & 0xF) << 24) |
            ((vp9->segmentation.feature_data[i][3] & 0xF) << 28);
         probs->seg.feature_mask[i] = vp9->segmentation.feature_mask[i];
      }

      for (uint32_t i = 0; i < VP9_MAX_SEGMENTATION_TREE_PROBS; i++)
         probs->seg.tree_probs[i] = vp9->segmentation.tree_probs[i];

      for (uint32_t i = 0; i < VP9_MAX_SEGMENTATION_PRED_PROBS; i++)
         probs->seg.pred_probs[i] = vp9->segmentation.pred_probs[i];

      probs->seg.abs_delta = vp9->segmentation.flags.segmentation_abs_delta;
   }

   memcpy(codec, &msg, sizeof(msg));
   return sizeof(msg);
}

static uint32_t
build_mpeg2_msg(struct cmd_buffer *cmd_buf, struct ac_video_dec_decode_cmd *cmd, rvcn_dec_message_mpeg2_vld_t *codec)
{
   struct ac_video_dec_mpeg2 *mpeg2 = &cmd->codec_param.mpeg2;
   rvcn_dec_message_mpeg2_vld_t msg = {0};

   msg.load_intra_quantiser_matrix = mpeg2->load_intra_quantiser_matrix;
   msg.load_nonintra_quantiser_matrix = mpeg2->load_nonintra_quantiser_matrix;
   memcpy(msg.intra_quantiser_matrix, mpeg2->intra_quantiser_matrix, sizeof(msg.intra_quantiser_matrix));
   memcpy(msg.nonintra_quantiser_matrix, mpeg2->nonintra_quantiser_matrix, sizeof(msg.nonintra_quantiser_matrix));
   msg.chroma_format = 1;
   msg.picture_coding_type = mpeg2->picture_coding_type;
   memcpy(msg.f_code, mpeg2->f_code, sizeof(msg.f_code));
   msg.intra_dc_precision = mpeg2->intra_dc_precision;
   msg.pic_structure = mpeg2->pic_structure;
   msg.top_field_first = mpeg2->top_field_first;
   msg.frame_pred_frame_dct = mpeg2->frame_pred_frame_dct;
   msg.concealment_motion_vectors = mpeg2->concealment_motion_vectors;
   msg.q_scale_type = mpeg2->q_scale_type;
   msg.intra_vlc_format = mpeg2->intra_vlc_format;
   msg.alternate_scan = mpeg2->alternate_scan;

   memcpy(codec, &msg, sizeof(msg));
   return sizeof(msg);
}

static uint32_t
build_vc1_msg(struct cmd_buffer *cmd_buf, struct ac_video_dec_decode_cmd *cmd, rvcn_dec_message_vc1_t *codec)
{
   struct ac_video_dec_vc1 *vc1 = &cmd->codec_param.vc1;
   rvcn_dec_message_vc1_t msg = {0};

   msg.sps_info_flags |= vc1->postprocflag << 7;
   msg.sps_info_flags |= vc1->pulldown << 6;
   msg.sps_info_flags |= vc1->interlace << 5;
   msg.sps_info_flags |= vc1->tfcntrflag << 4;
   msg.sps_info_flags |= vc1->finterpflag << 3;
   msg.sps_info_flags |= vc1->psf << 1;

   msg.pps_info_flags |= vc1->range_mapy_flag << 31;
   msg.pps_info_flags |= vc1->range_mapy << 28;
   msg.pps_info_flags |= vc1->range_mapuv_flag << 27;
   msg.pps_info_flags |= vc1->range_mapuv << 24;
   msg.pps_info_flags |= vc1->multires << 21;
   msg.pps_info_flags |= vc1->maxbframes << 16;
   msg.pps_info_flags |= vc1->overlap << 11;
   msg.pps_info_flags |= vc1->quantizer << 9;
   msg.pps_info_flags |= vc1->panscan_flag << 7;
   msg.pps_info_flags |= vc1->refdist_flag << 6;
   msg.pps_info_flags |= vc1->vstransform << 0;
   msg.pps_info_flags |= vc1->syncmarker << 20;
   msg.pps_info_flags |= vc1->rangered << 19;
   msg.pps_info_flags |= vc1->loopfilter << 5;
   msg.pps_info_flags |= vc1->fastuvmc << 4;
   msg.pps_info_flags |= vc1->extended_mv << 3;
   msg.pps_info_flags |= vc1->extended_dmv << 8;
   msg.pps_info_flags |= vc1->dquant << 1;

   msg.chroma_format = 1;
   msg.profile = vc1->profile;
   msg.level = vc1->level;

   memcpy(codec, &msg, sizeof(msg));
   return sizeof(msg);
}

/**************************************************************************
 *
 * Copyright 2018 Advanced Micro Devices, Inc.
 * All Rights Reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sub license, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 *
 * The above copyright notice and this permission notice (including the
 * next paragraph) shall be included in all copies or substantial portions
 * of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER(S) OR AUTHOR(S) BE LIABLE FOR
 * ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 **************************************************************************/

#ifndef vl_probs_table_h
#define vl_probs_table_h

static const unsigned char default_coef_probs_4x4[2][2][6][6][3] = {
   {  /* Y plane */
      {  /* Intra */
         {  /* Band 0 */
            { 195,  29, 183 }, {  84,  49, 136 }, {   8,  42,  71 }
         },
         {  /* Band 1 */
           {  31, 107, 169 }, {  35,  99, 159 }, {  17,  82, 140 },
           {   8,  66, 114 }, {   2,  44,  76 }, {   1,  19,  32 }
         },
         {  /* Band 2 */
           {  40, 132, 201 }, {  29, 114, 187 }, {  13,  91, 157 },
           {   7,  75, 127 }, {   3,  58,  95 }, {   1,  28,  47 }
         },
         {  /* Band 3 */
           {  69, 142, 221 }, {  42, 122, 201 }, {  15,  91, 159 },
           {   6,  67, 121 }, {   1,  42,  77 }, {   1,  17,  31 }
         },
         {  /* Band 4 */
           { 102, 148, 228 }, {  67, 117, 204 }, {  17,  82, 154 },
           {   6,  59, 114 }, {   2,  39,  75 }, {   1,  15,  29 }
         },
         {  /* Band 5 */
           { 156,  57, 233 }, { 119,  57, 212 }, {  58,  48, 163 },
           {  29,  40, 124 }, {  12,  30,  81 }, {   3,  12,  31 }
         }
      },
      {  /* Inter */
         {  /* Band 0 */
           { 191, 107, 226 }, { 124, 117, 204 }, {  25,  99, 155 }
         },
         {  /* Band 1 */
           {  29, 148, 210 }, {  37, 126, 194 }, {   8,  93, 157 },
           {   2,  68, 118 }, {   1,  39,  69 }, {   1,  17,  33 }
         },
         {  /* Band 2 */
           {  41, 151, 213 }, {  27, 123, 193 }, {   3,  82, 144 },
           {   1,  58, 105 }, {   1,  32,  60 }, {   1,  13,  26 }
         },
         {  /* Band 3 */
           {  59, 159, 220 }, {  23, 126, 198 }, {   4,  88, 151 },
           {   1,  66, 114 }, {   1,  38,  71 }, {   1,  18,  34 }
         },
         {  /* Band 4 */
           { 114, 136, 232 }, {  51, 114, 207 }, {  11,  83, 155 },
           {   3,  56, 105 }, {   1,  33,  65 }, {   1,  17,  34 }
         },
         {  /* Band 5 */
           { 149,  65, 234 }, { 121,  57, 215 }, {  61,  49, 166 },
           {  28,  36, 114 }, {  12,  25,  76 }, {   3,  16,  42 }
         }
      }
   },
   {  /* UV plane */
      {  /* Intra */
         {  /* Band 0 */
            { 214,  49, 220 }, { 132,  63, 188 }, {  42,  65, 137 }
         },
         {  /* Band 1 */
            {  85, 137, 221 }, { 104, 131, 216 }, {  49, 111, 192 },
            {  21,  87, 155 }, {   2,  49,  87 }, {   1,  16,  28 }
         },
         {  /* Band 2 */
            {  89, 163, 230 }, {  90, 137, 220 }, {  29, 100, 183 },
            {  10,  70, 135 }, {   2,  42,  81 }, {   1,  17,  33 }
         },
         {  /* Band 3 */
            { 108, 167, 237 }, {  55, 133, 222 }, {  15,  97, 179 },
            {   4,  72, 135 }, {   1,  45,  85 }, {   1,  19,  38 }
         },
         {  /* Band 4 */
            { 124, 146, 240 }, {  66, 124, 224 }, {  17,  88, 175 },
            {   4,  58, 122 }, {   1,  36,  75 }, {   1,  18,  37 }
         },
         {  /*  Band 5 */
            { 141,  79, 241 }, { 126,  70, 227 }, {  66,  58, 182 },
            {  30,  44, 136 }, {  12,  34,  96 }, {   2,  20,  47 }
         }
      },
      {  /* Inter */
         {  /* Band 0 */
            { 229,  99, 249 }, { 143, 111, 235 }, {  46, 109, 192 }
         },
         {  /* Band 1 */
            {  82, 158, 236 }, {  94, 146, 224 }, {  25, 117, 191 },
            {   9,  87, 149 }, {   3,  56,  99 }, {   1,  33,  57 }
         },
         {  /* Band 2 */
            {  83, 167, 237 }, {  68, 145, 222 }, {  10, 103, 177 },
            {   2,  72, 131 }, {   1,  41,  79 }, {   1,  20,  39 }
         },
         {  /* Band 3 */
            {  99, 167, 239 }, {  47, 141, 224 }, {  10, 104, 178 },
            {   2,  73, 133 }, {   1,  44,  85 }, {   1,  22,  47 }
         },
         {  /* Band 4 */
            { 127, 145, 243 }, {  71, 129, 228 }, {  17,  93, 177 },
            {   3,  61, 124 }, {   1,  41,  84 }, {   1,  21,  52 }
         },
         {  /* Band 5 */
            { 157,  78, 244 }, { 140,  72, 231 }, {  69,  58, 184 },
            {  31,  44, 137 }, {  14,  38, 105 }, {   8,  23,  61 }
         }
      }
   }
};

static const unsigned char default_coef_probs_8x8[2][2][6][6][3] = {
   {  /* Y plane */
      {  /* Intra */
         {  /* Band 0 */
            { 125,  34, 187 }, {  52,  41, 133 }, {   6,  31,  56 }
         },
         {  /* Band 1 */
            {  37, 109, 153 }, {  51, 102, 147 }, {  23,  87, 128 },
            {   8,  67, 101 }, {   1,  41,  63 }, {   1,  19,  29 }
         },
         {  /* Band 2 */
            {  31, 154, 185 }, {  17, 127, 175 }, {   6,  96, 145 },
            {   2,  73, 114 }, {   1,  51,  82 }, {   1,  28,  45 }
         },
         {  /* Band 3 */
            {  23, 163, 200 }, {  10, 131, 185 }, {   2,  93, 148 },
            {   1,  67, 111 }, {   1,  41,  69 }, {   1,  14,  24 }
         },
         {  /* Band 4 */
            {  29, 176, 217 }, {  12, 145, 201 }, {   3, 101, 156 },
            {   1,  69, 111 }, {   1,  39,  63 }, {   1,  14,  23 }
         },
         {  /* Band 5 */
            {  57, 192, 233 }, {  25, 154, 215 }, {   6, 109, 167 },
            {   3,  78, 118 }, {   1,  48,  69 }, {   1,  21,  29 }
         }
      },
      {  /* Inter */
         {  /* Band 0 */
            { 202, 105, 245 }, { 108, 106, 216 }, {  18,  90, 144 }
         },
         {  /* Band 1 */
            {  33, 172, 219 }, {  64, 149, 206 }, {  14, 117, 177 },
            {   5,  90, 141 }, {   2,  61,  95 }, {   1,  37,  57 }
         },
         {  /* Band 2 */
            {  33, 179, 220 }, {  11, 140, 198 }, {   1,  89, 148 },
            {   1,  60, 104 }, {   1,  33,  57 }, {   1,  12,  21 }
         },
         {  /* Band 3 */
            {  30, 181, 221 }, {   8, 141, 198 }, {   1,  87, 145 },
            {   1,  58, 100 }, {   1,  31,  55 }, {   1,  12,  20 }
         },
         {  /* Band 4 */
            {  32, 186, 224 }, {   7, 142, 198 }, {   1,  86, 143 },
            {   1,  58, 100 }, {   1,  31,  55 }, {   1,  12,  22 }
         },
         {  /* Band 5 */
            {  57, 192, 227 }, {  20, 143, 204 }, {   3,  96, 154 },
            {   1,  68, 112 }, {   1,  42,  69 }, {   1,  19,  32 }
         }
      }
   },
   {  /* UV plane */
      {  /* Intra */
         {  /* Band 0 */
            { 212,  35, 215 }, { 113,  47, 169 }, {  29,  48, 105 }
         },
         {  /* Band 1 */
            {  74, 129, 203 }, { 106, 120, 203 }, {  49, 107, 178 },
            {  19,  84, 144 }, {   4,  50,  84 }, {   1,  15,  25 }
         },
         {  /* Band 2 */
            {  71, 172, 217 }, {  44, 141, 209 }, {  15, 102, 173 },
            {   6,  76, 133 }, {   2,  51,  89 }, {   1,  24,  42 }
         },
         {  /* Band 3 */
            {  64, 185, 231 }, {  31, 148, 216 }, {   8, 103, 175 },
            {   3,  74, 131 }, {   1,  46,  81 }, {   1,  18,  30 }
         },
         {  /* Band 4 */
            {  65, 196, 235 }, {  25, 157, 221 }, {   5, 105, 174 },
            {   1,  67, 120 }, {   1,  38,  69 }, {   1,  15,  30 }
         },
         {  /* Band 5 */
            {  65, 204, 238 }, {  30, 156, 224 }, {   7, 107, 177 },
            {   2,  70, 124 }, {   1,  42,  73 }, {   1,  18,  34 }
         }
      },
      {  /* Inter */
         {  /* Band 0 */
            { 225,  86, 251 }, { 144, 104, 235 }, {  42,  99, 181 }
         },
         {  /* Band 1 */
            {  85, 175, 239 }, { 112, 165, 229 }, {  29, 136, 200 },
            {  12, 103, 162 }, {   6,  77, 123 }, {   2,  53,  84 }
         },
         {  /* Band 2 */
            {  75, 183, 239 }, {  30, 155, 221 }, {   3, 106, 171 },
            {   1,  74, 128 }, {   1,  44,  76 }, {   1,  17,  28 }
         },
         {  /* Band 3 */
            {  73, 185, 240 }, {  27, 159, 222 }, {   2, 107, 172 },
            {   1,  75, 127 }, {   1,  42,  73 }, {   1,  17,  29 }
         },
         {  /* Band 4 */
            {  62, 190, 238 }, {  21, 159, 222 }, {   2, 107, 172 },
            {   1,  72, 122 }, {   1,  40,  71 }, {   1,  18,  32 }
         },
         {  /* Band 5 */
            {  61, 199, 240 }, {  27, 161, 226 }, {   4, 113, 180 },
            {   1,  76, 129 }, {   1,  46,  80 }, {   1,  23,  41 }
         }
      }
   }
};

static const unsigned char default_coef_probs_16x16[2][2][6][6][3] = {
   {  /* Y plane */
      {  /* Intra */
         {  /* Band 0 */
            {   7,  27, 153 }, {   5,  30,  95 }, {   1,  16,  30 }
         },
         {  /* Band 1 */
            {  50,  75, 127 }, {  57,  75, 124 }, {  27,  67, 108 },
            {  10,  54,  86 }, {   1,  33,  52 }, {   1,  12,  18 }
         },
         {  /* Band 2 */
            {  43, 125, 151 }, {  26, 108, 148 }, {   7,  83, 122 },
            {   2,  59,  89 }, {   1,  38,  60 }, {   1,  17,  27 }
         },
         {  /* Band 3 */
            {  23, 144, 163 }, {  13, 112, 154 }, {   2,  75, 117 },
            {   1,  50,  81 }, {   1,  31,  51 }, {   1,  14,  23 }
         },
         {  /* Band 4 */
            {  18, 162, 185 }, {   6, 123, 171 }, {   1,  78, 125 },
            {   1,  51,  86 }, {   1,  31,  54 }, {   1,  14,  23 }
         },
         {  /* Band 5 */
            {  15, 199, 227 }, {   3, 150, 204 }, {   1,  91, 146 },
            {   1,  55,  95 }, {   1,  30,  53 }, {   1,  11,  20 }
         }
      },
      {  /* Inter */
         {  /* Band 0 */
            {  19,  55, 240 }, {  19,  59, 196 }, {   3,  52, 105 }
         },
         {  /* Band 1 */
            {  41, 166, 207 }, { 104, 153, 199 }, {  31, 123, 181 },
            {  14, 101, 152 }, {   5,  72, 106 }, {   1,  36,  52 }
         },
         {  /* Band 2 */
            {  35, 176, 211 }, {  12, 131, 190 }, {   2,  88, 144 },
            {   1,  60, 101 }, {   1,  36,  60 }, {   1,  16,  28 }
         },
         {  /* Band 3 */
            {  28, 183, 213 }, {   8, 134, 191 }, {   1,  86, 142 },
            {   1,  56,  96 }, {   1,  30,  53 }, {   1,  12,  20 }
         },
         {  /* Band 4 */
            {  20, 190, 215 }, {   4, 135, 192 }, {   1,  84, 139 },
            {   1,  53,  91 }, {   1,  28,  49 }, {   1,  11,  20 }
         },
         {  /* Band 5 */
            {  13, 196, 216 }, {   2, 137, 192 }, {   1,  86, 143 },
            {   1,  57,  99 }, {   1,  32,  56 }, {   1,  13,  24 }
         }
      }
   },
   {  /* UV plane */
      {  /* Intra */
         {  /* Band 0 */
            { 211,  29, 217 }, {  96,  47, 156 }, {  22,  43,  87 }
         },
         {  /* Band 1 */
            {  78, 120, 193 }, { 111, 116, 186 }, {  46, 102, 164 },
            {  15,  80, 128 }, {   2,  49,  76 }, {   1,  18,  28 }
         },
         {  /* Band 2 */
            {  71, 161, 203 }, {  42, 132, 192 }, {  10,  98, 150 },
            {   3,  69, 109 }, {   1,  44,  70 }, {   1,  18,  29 }
         },
         {  /* Band 3 */
            {  57, 186, 211 }, {  30, 140, 196 }, {   4,  93, 146 },
            {   1,  62, 102 }, {   1,  38,  65 }, {   1,  16,  27 }
         },
         {  /* Band 4 */
            {  47, 199, 217 }, {  14, 145, 196 }, {   1,  88, 142 },
            {   1,  57,  98 }, {   1,  36,  62 }, {   1,  15,  26 }
         },
         {  /* Band 5 */
            {  26, 219, 229 }, {   5, 155, 207 }, {   1,  94, 151 },
            {   1,  60, 104 }, {   1,  36,  62 }, {   1,  16,  28 }
         }
      },
      {  /* Inter */
         {  /* Band 0 */
            { 233,  29, 248 }, { 146,  47, 220 }, {  43,  52, 140 }
         },
         {  /* Band 1 */
            { 100, 163, 232 }, { 179, 161, 222 }, {  63, 142, 204 },
            {  37, 113, 174 }, {  26,  89, 137 }, {  18,  68,  97 }
         },
         {  /* Band 2 */
            {  85, 181, 230 }, {  32, 146, 209 }, {   7, 100, 164 },
            {   3,  71, 121 }, {   1,  45,  77 }, {   1,  18,  30 }
         },
         {  /* Band 3 */
            {  65, 187, 230 }, {  20, 148, 207 }, {   2,  97, 159 },
            {   1,  68, 116 }, {   1,  40,  70 }, {   1,  14,  29 }
         },
         {  /* Band 4 */
            {  40, 194, 227 }, {   8, 147, 204 }, {   1,  94, 155 },
            {   1,  65, 112 }, {   1,  39,  66 }, {   1,  14,  26 }
         },
         {  /* Band 5 */
            {  16, 208, 228 }, {   3, 151, 207 }, {   1,  98, 160 },
            {   1,  67, 117 }, {   1,  41,  74 }, {   1,  17,  31 }
         }
      }
   }
};

static const unsigned char default_coef_probs_32x32[2][2][6][6][3] = {
   {  /* Y plane */
      {  /* Intra */
         {  /* Band 0 */
            {  17,  38, 140 }, {   7,  34,  80 }, {   1,  17,  29 }
         },
         {  /* Band 1 */
            {  37,  75, 128 }, {  41,  76, 128 }, {  26,  66, 116 },
            {  12,  52,  94 }, {   2,  32,  55 }, {   1,  10,  16 }
         },
         {  /* Band 2 */
            {  50, 127, 154 }, {  37, 109, 152 }, {  16,  82, 121 },
            {   5,  59,  85 }, {   1,  35,  54 }, {   1,  13,  20 }
         },
         {  /* Band 3 */
            {  40, 142, 167 }, {  17, 110, 157 }, {   2,  71, 112 },
            {   1,  44,  72 }, {   1,  27,  45 }, {   1,  11,  17 }
         },
         {  /* Band 4 */
            {  30, 175, 188 }, {   9, 124, 169 }, {   1,  74, 116 },
            {   1,  48,  78 }, {   1,  30,  49 }, {   1,  11,  18 }
         },
         {  /* Band 5 */
            {  10, 222, 223 }, {   2, 150, 194 }, {   1,  83, 128 },
            {   1,  48,  79 }, {   1,  27,  45 }, {   1,  11,  17 }
         }
      },
      {  /* Inter */
         {  /* Band 0 */
            {  36,  41, 235 }, {  29,  36, 193 }, {  10,  27, 111 }
         },
         {  /* Band 1 */
            {  85, 165, 222 }, { 177, 162, 215 }, { 110, 135, 195 },
            {  57, 113, 168 }, {  23,  83, 120 }, {  10,  49,  61 }
         },
         {  /* Band 2 */
            {  85, 190, 223 }, {  36, 139, 200 }, {   5,  90, 146 },
            {   1,  60, 103 }, {   1,  38,  65 }, {   1,  18,  30 }
         },
         {  /* Band 3 */
            {  72, 202, 223 }, {  23, 141, 199 }, {   2,  86, 140 },
            {   1,  56,  97 }, {   1,  36,  61 }, {   1,  16,  27 }
         },
         {  /* Band 4 */
            {  55, 218, 225 }, {  13, 145, 200 }, {   1,  86, 141 },
            {   1,  57,  99 }, {   1,  35,  61 }, {   1,  13,  22 }
         },
         {  /* Band 5 */
            {  15, 235, 212 }, {   1, 132, 184 }, {   1,  84, 139 },
            {   1,  57,  97 }, {   1,  34,  56 }, {   1,  14,  23 }
         }
      }
   },
   {  /* UV plane */
      {  /* Intra */
         {  /* Band 0 */
            { 181,  21, 201 }, {  61,  37, 123 }, {  10,  38,  71 }
         },
         {  /* Band 1 */
            {  47, 106, 172 }, {  95, 104, 173 }, {  42,  93, 159 },
            {  18,  77, 131 }, {   4,  50,  81 }, {   1,  17,  23 }
         },
         {  /* Band 2 */
            {  62, 147, 199 }, {  44, 130, 189 }, {  28, 102, 154 },
            {  18,  75, 115 }, {   2,  44,  65 }, {   1,  12,  19 }
         },
         {  /* Band 3 */
            {  55, 153, 210 }, {  24, 130, 194 }, {   3,  93, 146 },
            {   1,  61,  97 }, {   1,  31,  50 }, {   1,  10,  16 }
         },
         {  /* Band 4 */
            {  49, 186, 223 }, {  17, 148, 204 }, {   1,  96, 142 },
            {   1,  53,  83 }, {   1,  26,  44 }, {   1,  11,  17 }
         },
         {  /* Band 5 */
            {  13, 217, 212 }, {   2, 136, 180 }, {   1,  78, 124 },
            {   1,  50,  83 }, {   1,  29,  49 }, {   1,  14,  23 }
         }
      },
      {  /* Inter */
         {  /* Band 0 */
            { 197,  13, 247 }, {  82,  17, 222 }, {  25,  17, 162 }
         },
         {  /* Band 1 */
            { 126, 186, 247 }, { 234, 191, 243 }, { 176, 177, 234 },
            { 104, 158, 220 }, {  66, 128, 186 }, {  55,  90, 137 }
         },
         {  /* Band 2 */
            { 111, 197, 242 }, {  46, 158, 219 }, {   9, 104, 171 },
            {   2,  65, 125 }, {   1,  44,  80 }, {   1,  17,  91 }
         },
         {  /* Band 3 */
            { 104, 208, 245 }, {  39, 168, 224 }, {   3, 109, 162 },
            {   1,  79, 124 }, {   1,  50, 102 }, {   1,  43, 102 }
         },
         {  /* Band 4 */
            {  84, 220, 246 }, {  31, 177, 231 }, {   2, 115, 180 },
            {   1,  79, 134 }, {   1,  55,  77 }, {   1,  60,  79 }
         },
         {  /* Band 5 */
            {  43, 243, 240 }, {   8, 180, 217 }, {   1, 115, 166 },
            {   1,  84, 121 }, {   1,  51,  67 }, {   1,  16,   6 }
         }
      }
   }
};

static const unsigned char default_if_y_probs[4][9] = {
   {  65,  32,  18, 144, 162, 194,  41,  51,  98 },  /* block_size < 8x8 */
   { 132,  68,  18, 165, 217, 196,  45,  40,  78 },  /* block_size < 16x16 */
   { 173,  80,  19, 176, 240, 193,  64,  35,  46 },  /* block_size < 32x32 */
   { 221, 135,  38, 194, 248, 121,  96,  85,  29 }   /* block_size >= 32x32 */
};

static const unsigned char default_if_uv_probs[10][9] = {
   { 120,   7,  76, 176, 208, 126,  28,  54, 103 },  /* y = dc */
   {  48,  12, 154, 155, 139,  90,  34, 117, 119 },  /* y = v */
   {  67,   6,  25, 204, 243, 158,  13,  21,  96 },  /* y = h */
   {  97,   5,  44, 131, 176, 139,  48,  68,  97 },  /* y = d45 */
   {  83,   5,  42, 156, 111, 152,  26,  49, 152 },  /* y = d135 */
   {  80,   5,  58, 178,  74,  83,  33,  62, 145 },  /* y = d117 */
   {  86,   5,  32, 154, 192, 168,  14,  22, 163 },  /* y = d153 */
   {  85,   5,  32, 156, 216, 148,  19,  29,  73 },  /* y = d207 */
   {  77,   7,  64, 116, 132, 122,  37, 126, 120 },  /* y = d63 */
   { 101,  21, 107, 181, 192, 103,  19,  67, 125 }   /* y = tm */
};

static const unsigned char default_single_ref_p[5][2] = {
   {  33,  16 },
   {  77,  74 },
   { 142, 142 },
   { 172, 170 },
   { 238, 247 }
};

static const unsigned char  default_switchable_interp_prob[4][2] = {
   { 235, 162, },
   { 36, 255, },
   { 34, 3, },
   { 149, 144, },
};

static const unsigned char default_partition_probs[16][3] = {
   /* 8x8 -> 4x4 */
   { 199, 122, 141 },  /* a/l both not split */
   { 147,  63, 159 },  /* a split, l not split */
   { 148, 133, 118 },  /* l split, a not split */
   { 121, 104, 114 },  /* a/l both split */
   /* 16x16 -> 8x8 */
   { 174,  73,  87 },  /* a/l both not split */
   {  92,  41,  83 },  /* a split, l not split */
   {  82,  99,  50 },  /* l split, a not split */
   {  53,  39,  39 },  /* a/l both split */
   /* 32x32 -> 16x16 */
   { 177,  58,  59 },  /* a/l both not split */
   {  68,  26,  63 },  /* a split, l not split */
   {  52,  79,  25 },  /* l split, a not split */
   {  17,  14,  12 },  /* a/l both split */
   /* 64x64 -> 32x32 */
   { 222,  34,  30 },  /* a/l both not split */
   {  72,  16,  44 },  /* a split, l not split */
   {  58,  32,  12 },  /* l split, a not split */
   {  10,   7,   6 },  /* a/l both split */
};

static const unsigned char default_inter_mode_probs[7][3] = {
   {2,       173,   34},  /* 0 = both zero mv */
   {7,       145,   85},  /* 1 = one zero mv + one a predicted mv */
   {7,       166,   63},  /* 2 = two predicted mvs */
   {7,       94,    66},  /* 3 = one predicted/zero and one new mv */
   {8,       64,    46},  /* 4 = two new mvs */
   {17,      81,    31},  /* 5 = one intra neighbour + x */
   {25,      29,    30},  /* 6 = two intra neighbours */
};

static const unsigned char default_skip_probs[3] = {
   192, 128, 64
};

static const unsigned char default_intra_inter_p[4] = {
   9, 102, 187, 225
};

static const unsigned char default_comp_inter_p[5] = {
   239, 183, 119,  96,  41
};

static const unsigned char default_comp_ref_p[5] = {
   50, 126, 123, 221, 226
};

static const unsigned char default_tx_probs_32x32[2][3] = {
   { 3, 136, 37 },
   { 5, 52,  13 }
};

static const unsigned char default_tx_probs_16x16[2][2] = {
   { 20, 152 },
   { 15, 101 }
};

static const unsigned char default_tx_probs_8x8[2][1] = {
   { 100 },
   { 66  }
};

static const unsigned char default_nmv_joints[3] = {
   32, 64, 96
};

static const unsigned char default_nmv_components[2][33] = {
   {  /* Vertical component */
      128,                                                  /* sign */
      224, 144, 192, 168, 192, 176, 192, 198, 198, 245,     /* class */
      216,                                                  /* class0 */
      136, 140, 148, 160, 176, 192, 224, 234, 234, 240,     /* bits */
      128, 128, 64, 96, 112, 64,                            /* class0_fp */
      64, 96, 64,                                           /* fp */
      160,                                                  /* class0_hp bit */
      128,                                                  /* hp */
   },
   {  /* Horizontal component */
      128,                                                  /* sign */
      216, 128, 176, 160, 176, 176, 192, 198, 198, 208,     /* class */
      208,                                                  /* class0 */
      136, 140, 148, 160, 176, 192, 224, 234, 234, 240,     /* bits */
      128, 128, 64, 96, 112, 64,                            /* class0_fp */
      64, 96, 64,                                           /* fp */
      160,                                                  /* class0_hp bit */
      128,                                                  /* hp */
   }
};

#endif /* vl_probs_table_h */

static void
ac_vcn_vp9_fill_probs_table(void *ptr)
{
   rvcn_dec_vp9_probs_t *probs = (rvcn_dec_vp9_probs_t *)ptr;

   memcpy(&probs->coef_probs[0], default_coef_probs_4x4, sizeof(default_coef_probs_4x4));
   memcpy(&probs->coef_probs[1], default_coef_probs_8x8, sizeof(default_coef_probs_8x8));
   memcpy(&probs->coef_probs[2], default_coef_probs_16x16, sizeof(default_coef_probs_16x16));
   memcpy(&probs->coef_probs[3], default_coef_probs_32x32, sizeof(default_coef_probs_32x32));
   memcpy(probs->y_mode_prob, default_if_y_probs, sizeof(default_if_y_probs));
   memcpy(probs->uv_mode_prob, default_if_uv_probs, sizeof(default_if_uv_probs));
   memcpy(probs->single_ref_prob, default_single_ref_p, sizeof(default_single_ref_p));
   memcpy(probs->switchable_interp_prob, default_switchable_interp_prob,
          sizeof(default_switchable_interp_prob));
   memcpy(probs->partition_prob, default_partition_probs, sizeof(default_partition_probs));
   memcpy(probs->inter_mode_probs, default_inter_mode_probs, sizeof(default_inter_mode_probs));
   memcpy(probs->mbskip_probs, default_skip_probs, sizeof(default_skip_probs));
   memcpy(probs->intra_inter_prob, default_intra_inter_p, sizeof(default_intra_inter_p));
   memcpy(probs->comp_inter_prob, default_comp_inter_p, sizeof(default_comp_inter_p));
   memcpy(probs->comp_ref_prob, default_comp_ref_p, sizeof(default_comp_ref_p));
   memcpy(probs->tx_probs_32x32, default_tx_probs_32x32, sizeof(default_tx_probs_32x32));
   memcpy(probs->tx_probs_16x16, default_tx_probs_16x16, sizeof(default_tx_probs_16x16));
   memcpy(probs->tx_probs_8x8, default_tx_probs_8x8, sizeof(default_tx_probs_8x8));
   memcpy(probs->mv_joints, default_nmv_joints, sizeof(default_nmv_joints));
   memcpy(&probs->mv_comps[0], default_nmv_components, sizeof(default_nmv_components));
   memset(&probs->nmvc_mask, 0, sizeof(rvcn_dec_vp9_nmv_ctx_mask_t));
}
