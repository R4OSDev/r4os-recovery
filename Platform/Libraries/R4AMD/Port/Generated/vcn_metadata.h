/* Generated from pinned Mesa 26.2.2. Copyright 2017-2026 Advanced Micro Devices, Inc.
 * SPDX-License-Identifier: MIT. Full originals/grant: ThirdParty/Mesa26.2.2/Original.
 * Regenerate with Tools/VcnCodecs.ps1 -Write. */
#ifndef R4AMD_VCN_METADATA_H
#define R4AMD_VCN_METADATA_H
#include <stdint.h>
#include <stdbool.h>
#define H265_SCALING_LIST_4X4_NUM_LISTS             6
#define H265_SCALING_LIST_4X4_NUM_ELEMENTS          16
#define H265_SCALING_LIST_8X8_NUM_LISTS             6
#define H265_SCALING_LIST_8X8_NUM_ELEMENTS          64
#define H265_SCALING_LIST_16X16_NUM_LISTS           6
#define H265_SCALING_LIST_16X16_NUM_ELEMENTS        64
#define H265_SCALING_LIST_32X32_NUM_LISTS           2
#define H265_SCALING_LIST_32X32_NUM_ELEMENTS        64
#define H265_CHROMA_QP_OFFSET_LIST_SIZE             6
#define H265_TILE_COLS_LIST_SIZE                    19
#define H265_TILE_ROWS_LIST_SIZE                    21
#define H265_MAX_NUM_REF_PICS                       15
#define H265_MAX_RPS_SIZE                           8

struct ac_video_dec_hevc {
   struct {
      uint32_t separate_colour_plane_flag : 1;
      uint32_t scaling_list_enabled_flag : 1;
      uint32_t amp_enabled_flag : 1;
      uint32_t sample_adaptive_offset_enabled_flag : 1;
      uint32_t pcm_enabled_flag : 1;
      uint32_t pcm_loop_filter_disabled_flag : 1;
      uint32_t long_term_ref_pics_present_flag : 1;
      uint32_t sps_temporal_mvp_enabled_flag : 1;
      uint32_t strong_intra_smoothing_enabled_flag : 1;
      uint32_t transform_skip_rotate_enabled_flag : 1;
      uint32_t transform_skip_context_enabled_flag : 1;
      uint32_t implicit_rdpcm_enabled_flag : 1;
      uint32_t explicit_rdpcm_enabled_flag : 1;
      uint32_t extended_precision_processing_flag : 1;
      uint32_t intra_smoothing_disabled_flag : 1;
      uint32_t high_precision_offsets_enabled_flag : 1;
      uint32_t persistent_rice_adaptation_enabled_flag : 1;
      uint32_t cabac_bypass_alignment_enabled_flag : 1;
   } sps_flags;

   struct {
      uint32_t dependent_slice_segments_enabled_flag : 1;
      uint32_t output_flag_present_flag : 1;
      uint32_t sign_data_hiding_enabled_flag : 1;
      uint32_t cabac_init_present_flag : 1;
      uint32_t constrained_intra_pred_flag : 1;
      uint32_t transform_skip_enabled_flag : 1;
      uint32_t cu_qp_delta_enabled_flag : 1;
      uint32_t pps_slice_chroma_qp_offsets_present_flag : 1;
      uint32_t weighted_pred_flag : 1;
      uint32_t weighted_bipred_flag : 1;
      uint32_t transquant_bypass_enabled_flag : 1;
      uint32_t tiles_enabled_flag : 1;
      uint32_t entropy_coding_sync_enabled_flag : 1;
      uint32_t uniform_spacing_flag : 1;
      uint32_t loop_filter_across_tiles_enabled_flag : 1;
      uint32_t pps_loop_filter_across_slices_enabled_flag : 1;
      uint32_t deblocking_filter_override_enabled_flag : 1;
      uint32_t pps_deblocking_filter_disabled_flag : 1;
      uint32_t lists_modification_present_flag : 1;
      uint32_t slice_segment_header_extension_present_flag : 1;
      uint32_t cross_component_prediction_enabled_flag : 1;
      uint32_t chroma_qp_offset_list_enabled_flag : 1;
   } pps_flags;

   struct {
      uint32_t irap_pic_flag : 1;
      uint32_t idr_pic_flag : 1;
      uint32_t is_ref_pic_flag : 1;
   } pic_flags;

   uint8_t sps_max_dec_pic_buffering_minus1;
   uint8_t chroma_format_idc;
   uint32_t pic_width_in_luma_samples;
   uint32_t pic_height_in_luma_samples;
   uint8_t bit_depth_luma_minus8;
   uint8_t bit_depth_chroma_minus8;
   uint8_t log2_max_pic_order_cnt_lsb_minus4;
   uint8_t log2_min_luma_coding_block_size_minus3;
   uint8_t log2_diff_max_min_luma_coding_block_size;
   uint8_t log2_min_transform_block_size_minus2;
   uint8_t log2_diff_max_min_transform_block_size;
   uint8_t max_transform_hierarchy_depth_inter;
   uint8_t max_transform_hierarchy_depth_intra;
   uint8_t pcm_sample_bit_depth_luma_minus1;
   uint8_t pcm_sample_bit_depth_chroma_minus1;
   uint8_t log2_min_pcm_luma_coding_block_size_minus3;
   uint8_t log2_diff_max_min_pcm_luma_coding_block_size;
   uint8_t num_extra_slice_header_bits;
   int8_t init_qp_minus26;
   uint8_t diff_cu_qp_delta_depth;
   int8_t pps_cb_qp_offset;
   int8_t pps_cr_qp_offset;
   int8_t pps_beta_offset_div2;
   int8_t pps_tc_offset_div2;
   uint8_t log2_parallel_merge_level_minus2;
   uint8_t log2_max_transform_skip_block_size_minus2;
   uint8_t diff_cu_chroma_qp_offset_depth;
   uint8_t chroma_qp_offset_list_len_minus1;
   int8_t cb_qp_offset_list[H265_CHROMA_QP_OFFSET_LIST_SIZE];
   int8_t cr_qp_offset_list[H265_CHROMA_QP_OFFSET_LIST_SIZE];
   uint8_t log2_sao_offset_scale_luma;
   uint8_t log2_sao_offset_scale_chroma;
   uint8_t num_tile_columns_minus1;
   uint8_t num_tile_rows_minus1;
   uint16_t column_width_minus1[H265_TILE_COLS_LIST_SIZE];
   uint16_t row_height_minus1[H265_TILE_ROWS_LIST_SIZE];

   uint8_t scaling_list_4x4[H265_SCALING_LIST_4X4_NUM_LISTS][H265_SCALING_LIST_4X4_NUM_ELEMENTS];
   uint8_t scaling_list_8x8[H265_SCALING_LIST_8X8_NUM_LISTS][H265_SCALING_LIST_8X8_NUM_ELEMENTS];
   uint8_t scaling_list_16x16[H265_SCALING_LIST_16X16_NUM_LISTS][H265_SCALING_LIST_16X16_NUM_ELEMENTS];
   uint8_t scaling_list_32x32[H265_SCALING_LIST_32X32_NUM_LISTS][H265_SCALING_LIST_32X32_NUM_ELEMENTS];
   uint8_t scaling_list_dc_coef_16x16[H265_SCALING_LIST_16X16_NUM_LISTS];
   uint8_t scaling_list_dc_coef_32x32[H265_SCALING_LIST_32X32_NUM_LISTS];

   uint8_t num_short_term_ref_pic_sets;
   uint8_t num_long_term_ref_pics_sps;
   uint8_t num_ref_idx_l0_default_active_minus1;
   uint8_t num_ref_idx_l1_default_active_minus1;
   uint8_t num_delta_pocs_of_ref_rps_idx;
   uint16_t num_bits_for_st_ref_pic_set_in_slice;
   uint32_t curr_pic_id;
   int32_t curr_poc;
   uint32_t ref_pic_id_list[H265_MAX_NUM_REF_PICS];
   int32_t ref_poc_list[H265_MAX_NUM_REF_PICS];
   uint32_t used_for_long_term_ref_flags;
   uint8_t ref_pic_set_st_curr_before[H265_MAX_RPS_SIZE];
   uint8_t ref_pic_set_st_curr_after[H265_MAX_RPS_SIZE];
   uint8_t ref_pic_set_lt_curr[H265_MAX_RPS_SIZE];
};

#define VP9_MAX_SEGMENTS                       8
#define VP9_MAX_SEGMENTATION_TREE_PROBS        7
#define VP9_MAX_SEGMENTATION_PRED_PROBS        3
#define VP9_SEG_LVL_MAX                        4
#define VP9_SEG_ABS_DELTA                      1
#define VP9_MAX_LOOP_FILTER                    63
#define VP9_LOOP_FILTER_ADJUSTMENTS            2
#define VP9_NUM_REF_FRAMES                     8
#define VP9_TOTAL_REFS_PER_FRAME               3
#define VP9_MAX_REF_FRAMES                     4

enum ac_video_dec_vp9_seg_level_features {
   AC_VIDEO_DEC_VP9_SEG_LEVEL_ALT_QUANT = 0, /* Use alternate Quantizer */
   AC_VIDEO_DEC_VP9_SEG_LEVEL_ALT_LF,        /* Use alternate loop filter value */
   AC_VIDEO_DEC_VP9_SEG_LEVEL_REF_FRAME,     /* Optional Segment reference frame */
   AC_VIDEO_DEC_VP9_SEG_LEVEL_SKIP,          /* Optional Segment (0,0) + skip mode */
};

struct ac_video_dec_vp9 {
   struct {
      uint32_t error_resilient_mode : 1;
      uint32_t intra_only : 1;
      uint32_t allow_high_precision_mv : 1;
      uint32_t refresh_frame_context : 1;
      uint32_t frame_parallel_decoding_mode : 1;
      uint32_t show_frame : 1;
      uint32_t use_prev_frame_mvs : 1;
      uint32_t use_uncompressed_header : 1;
      uint32_t extra_plane : 1;
   } pic_flags;

   struct {
      uint32_t subsampling_x : 1;
      uint32_t subsampling_y : 1;
   } color_config_flags;

   uint8_t profile;
   uint32_t width;
   uint32_t height;
   uint8_t frame_context_idx;
   uint8_t reset_frame_context;
   uint32_t cur_id;
   uint8_t bit_depth_luma_minus8;
   uint8_t bit_depth_chroma_minus8;
   uint8_t frame_type;
   uint8_t interp_filter;
   uint8_t base_q_idx;
   int8_t y_dc_delta_q;
   int8_t uv_ac_delta_q;
   int8_t uv_dc_delta_q;
   uint8_t log2_tile_cols;
   uint8_t log2_tile_rows;
   uint32_t uncompressed_header_offset;
   uint32_t compressed_header_size;
   uint32_t uncompressed_header_size;
   uint32_t ref_frames[VP9_TOTAL_REFS_PER_FRAME];
   uint32_t ref_frame_id_list[VP9_NUM_REF_FRAMES];
   uint32_t ref_frame_coded_width_list[VP9_NUM_REF_FRAMES];
   uint32_t ref_frame_coded_height_list[VP9_NUM_REF_FRAMES];
   uint32_t ref_frame_sign_bias[VP9_MAX_REF_FRAMES];

   struct {
      struct {
         uint32_t mode_ref_delta_enabled : 1;
         uint32_t mode_ref_delta_update : 1;
      } loop_filter_flags;
      uint8_t loop_filter_level;
      uint8_t loop_filter_sharpness;
      int8_t loop_filter_ref_deltas[VP9_MAX_REF_FRAMES];
      int8_t loop_filter_mode_deltas[VP9_LOOP_FILTER_ADJUSTMENTS];
   } loop_filter;

   struct {
      struct {
         uint32_t segmentation_enabled : 1;
         uint32_t segmentation_update_map : 1;
         uint32_t segmentation_temporal_update : 1;
         uint32_t segmentation_update_data : 1;
         uint32_t segmentation_abs_delta : 1;
      } flags;
      uint8_t feature_mask[VP9_MAX_SEGMENTS];
      int16_t feature_data[VP9_MAX_SEGMENTS][VP9_SEG_LVL_MAX];
      uint8_t tree_probs[VP9_MAX_SEGMENTATION_TREE_PROBS];
      uint8_t pred_probs[VP9_MAX_SEGMENTATION_PRED_PROBS];
   } segmentation;
};

struct ac_video_dec_mpeg2 {
   uint8_t load_intra_quantiser_matrix;
   uint8_t load_nonintra_quantiser_matrix;
   uint8_t intra_quantiser_matrix[64];
   uint8_t nonintra_quantiser_matrix[64];
   uint8_t picture_coding_type;
   uint8_t f_code[2][2];
   uint8_t intra_dc_precision;
   uint8_t pic_structure;
   uint8_t top_field_first;
   uint8_t frame_pred_frame_dct;
   uint8_t concealment_motion_vectors;
   uint8_t q_scale_type;
   uint8_t intra_vlc_format;
   uint8_t alternate_scan;
};
struct ac_video_dec_vc1 {
   uint32_t profile;
   uint32_t level;
   uint8_t postprocflag;
   uint8_t pulldown;
   uint8_t interlace;
   uint8_t tfcntrflag;
   uint8_t finterpflag;
   uint8_t psf;
   uint8_t range_mapy_flag;
   uint8_t range_mapy;
   uint8_t range_mapuv_flag;
   uint8_t range_mapuv;
   uint8_t multires;
   uint8_t maxbframes;
   uint8_t overlap;
   uint8_t quantizer;
   uint8_t panscan_flag;
   uint8_t refdist_flag;
   uint8_t vstransform;
   uint8_t syncmarker;
   uint8_t rangered;
   uint8_t loopfilter;
   uint8_t fastuvmc;
   uint8_t extended_mv;
   uint8_t extended_dmv;
   uint8_t dquant;
};
#endif
