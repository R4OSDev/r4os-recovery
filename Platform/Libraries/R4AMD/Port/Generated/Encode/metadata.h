/* Generated from pinned Mesa 26.2.2; original functions/types retained.
 * Copyright 2009 Younes Manton; 2017-2025 Advanced Micro Devices, Inc.
 * MIT; full original notices/grants in ThirdParty/Mesa26.2.2/Original.
 * Regenerate: Tools/VcnEncode.ps1 -Write. */
#ifndef R4AMD_ENCODER_TYPES_H
#define R4AMD_ENCODER_TYPES_H
#include <stdint.h>
#include <stdbool.h>
#define PIPE_VIDEO_STATE_H
#define PIPE_H264_MAX_NUM_LIST_REF    32
#define PIPE_H264_MAX_DPB_SIZE        17
#define PIPE_H265_MAX_NUM_LIST_REF    15
#define PIPE_H265_MAX_DPB_SIZE        16
#define PIPE_H265_MAX_SLICES          600
#define PIPE_H264_MAX_REFERENCES      16
#define PIPE_H265_MAX_REFERENCES      15
#define PIPE_AV1_MAX_REFERENCES       8
#define PIPE_DEFAULT_FRAME_RATE_DEN   1
#define PIPE_DEFAULT_FRAME_RATE_NUM   30
#define PIPE_DEFAULT_INTRA_IDR_PERIOD 30
#define PIPE_H2645_EXTENDED_SAR       255
#define PIPE_ENC_ROI_REGION_NUM_MAX   32
#define PIPE_ENC_DIRTY_RECTS_NUM_MAX 256
#define PIPE_ENC_MOVE_RECTS_NUM_MAX 256
#define PIPE_ENC_MOVE_MAP_MAX_HINTS 31
#define PIPE_H2645_LIST_REF_INVALID_ENTRY 0xff
#define PIPE_H265_MAX_LONG_TERM_REF_PICS_SPS 32
#define PIPE_H265_MAX_LONG_TERM_PICS 16
#define PIPE_H265_MAX_DELTA_POC 48
#define PIPE_H265_MAX_NUM_LIST_REF 15
#define PIPE_H265_MAX_ST_REF_PIC_SETS 65
#define PIPE_H265_MAX_SUB_LAYERS 7
#define PIPE_AV1_MAX_DPB_SIZE 8
#define PIPE_AV1_REFS_PER_FRAME 7
enum pipe_h2645_enc_picture_type
{
   PIPE_H2645_ENC_PICTURE_TYPE_P = 0x00,
   PIPE_H2645_ENC_PICTURE_TYPE_B = 0x01,
   PIPE_H2645_ENC_PICTURE_TYPE_I = 0x02,
   PIPE_H2645_ENC_PICTURE_TYPE_IDR = 0x03,
   PIPE_H2645_ENC_PICTURE_TYPE_SKIP = 0x04
};
struct pipe_h264_enc_pic_control
{
   unsigned enc_cabac_enable;
   unsigned enc_cabac_init_idc;
   struct {
      uint32_t entropy_coding_mode_flag : 1;
      uint32_t weighted_pred_flag : 1;
      uint32_t deblocking_filter_control_present_flag : 1;
      uint32_t constrained_intra_pred_flag : 1;
      uint32_t redundant_pic_cnt_present_flag : 1;
      uint32_t more_rbsp_data : 1;
      uint32_t transform_8x8_mode_flag : 1;
   };
   uint8_t nal_ref_idc;
   uint8_t nal_unit_type;
   uint8_t num_ref_idx_l0_default_active_minus1;
   uint8_t num_ref_idx_l1_default_active_minus1;
   uint8_t weighted_bipred_idc;
   int8_t pic_init_qp_minus26;
   int8_t pic_init_qs_minus26;
   int8_t chroma_qp_index_offset;
   int8_t second_chroma_qp_index_offset;
   uint8_t temporal_id;
};
typedef struct pipe_h264_enc_hrd_params
{
   uint32_t cpb_cnt_minus1;
   uint32_t bit_rate_scale;
   uint32_t cpb_size_scale;
   uint32_t bit_rate_value_minus1[32];
   uint32_t cpb_size_value_minus1[32];
   uint32_t cbr_flag[32];
   uint32_t initial_cpb_removal_delay_length_minus1;
   uint32_t cpb_removal_delay_length_minus1;
   uint32_t dpb_output_delay_length_minus1;
   uint32_t time_offset_length;
} pipe_h264_enc_hrd_params;
struct pipe_h264_enc_seq_param
{
   struct {
      uint32_t enc_frame_cropping_flag : 1;
      uint32_t vui_parameters_present_flag : 1;
      uint32_t video_full_range_flag : 1;
      uint32_t direct_8x8_inference_flag : 1;
      uint32_t gaps_in_frame_num_value_allowed_flag : 1;
      uint32_t delta_pic_order_always_zero_flag : 1;
   };
   unsigned profile_idc;
   unsigned enc_constraint_set_flags;
   unsigned level_idc;
   unsigned bit_depth_luma_minus8;
   unsigned bit_depth_chroma_minus8;
   unsigned enc_frame_crop_left_offset;
   unsigned enc_frame_crop_right_offset;
   unsigned enc_frame_crop_top_offset;
   unsigned enc_frame_crop_bottom_offset;
   unsigned pic_order_cnt_type;
   unsigned log2_max_frame_num_minus4;
   unsigned log2_max_pic_order_cnt_lsb_minus4;
   unsigned num_temporal_layers;
   struct {
      uint32_t aspect_ratio_info_present_flag: 1;
      uint32_t timing_info_present_flag: 1;
      uint32_t video_signal_type_present_flag: 1;
      uint32_t colour_description_present_flag: 1;
      uint32_t chroma_loc_info_present_flag: 1;
      uint32_t overscan_info_present_flag: 1;
      uint32_t overscan_appropriate_flag: 1;
      uint32_t fixed_frame_rate_flag: 1;
      uint32_t nal_hrd_parameters_present_flag: 1;
      uint32_t vcl_hrd_parameters_present_flag: 1;
      uint32_t low_delay_hrd_flag: 1;
      uint32_t pic_struct_present_flag: 1;
      uint32_t bitstream_restriction_flag: 1;
      uint32_t motion_vectors_over_pic_boundaries_flag: 1;
   } vui_flags;
   uint32_t aspect_ratio_idc;
   uint32_t sar_width;
   uint32_t sar_height;
   uint32_t num_units_in_tick;
   uint32_t time_scale;
   uint32_t video_format;
   uint32_t colour_primaries;
   uint32_t transfer_characteristics;
   uint32_t matrix_coefficients;
   uint32_t chroma_sample_loc_type_top_field;
   uint32_t chroma_sample_loc_type_bottom_field;
   uint32_t max_num_reorder_frames;
   pipe_h264_enc_hrd_params nal_hrd_parameters;
   pipe_h264_enc_hrd_params vcl_hrd_parameters;
   uint32_t max_bytes_per_pic_denom;
   uint32_t max_bits_per_mb_denom;
   uint32_t log2_max_mv_length_vertical;
   uint32_t log2_max_mv_length_horizontal;
   uint32_t max_dec_frame_buffering;
   uint32_t max_num_ref_frames;
   uint32_t pic_width_in_mbs_minus1;
   uint32_t pic_height_in_map_units_minus1;
   int32_t offset_for_non_ref_pic;
   int32_t offset_for_top_to_bottom_field;
   uint32_t num_ref_frames_in_pic_order_cnt_cycle;
   int32_t offset_for_ref_frame[256];
};
struct pipe_h264_ref_list_mod_entry
{
   uint8_t modification_of_pic_nums_idc;
   uint32_t abs_diff_pic_num_minus1;
   uint32_t long_term_pic_num;
};
struct pipe_h264_ref_pic_marking_entry
{
   uint8_t memory_management_control_operation;
   uint32_t difference_of_pic_nums_minus1;
   uint32_t long_term_pic_num;
   uint32_t long_term_frame_idx;
   uint32_t max_long_term_frame_idx_plus1;
};
struct pipe_h264_enc_slice_param
{
   struct {
      uint32_t direct_spatial_mv_pred_flag : 1;
      uint32_t num_ref_idx_active_override_flag : 1;
      uint32_t ref_pic_list_modification_flag_l0 : 1;
      uint32_t ref_pic_list_modification_flag_l1 : 1;
      uint32_t no_output_of_prior_pics_flag : 1;
      uint32_t long_term_reference_flag : 1;
      uint32_t adaptive_ref_pic_marking_mode_flag : 1;
   };
   uint8_t slice_type;
   uint8_t colour_plane_id;
   uint32_t frame_num;
   uint32_t idr_pic_id;
   uint32_t pic_order_cnt_lsb;
   uint8_t redundant_pic_cnt;
   uint8_t num_ref_idx_l0_active_minus1;
   uint8_t num_ref_idx_l1_active_minus1;
   uint8_t num_ref_list0_mod_operations;
   struct pipe_h264_ref_list_mod_entry ref_list0_mod_operations[PIPE_H264_MAX_NUM_LIST_REF];
   uint8_t num_ref_list1_mod_operations;
   struct pipe_h264_ref_list_mod_entry ref_list1_mod_operations[PIPE_H264_MAX_NUM_LIST_REF];
   uint8_t num_ref_pic_marking_operations;
   struct pipe_h264_ref_pic_marking_entry ref_pic_marking_operations[PIPE_H264_MAX_NUM_LIST_REF];
   uint8_t cabac_init_idc;
   int32_t slice_qp_delta;
   uint8_t disable_deblocking_filter_idc;
   int32_t slice_alpha_c0_offset_div2;
   int32_t slice_beta_offset_div2;
   int32_t delta_pic_order_cnt0;
};
struct pipe_h265_st_ref_pic_set
{
   struct {
      uint32_t inter_ref_pic_set_prediction_flag : 1;
   };
   uint32_t delta_idx_minus1;
   uint8_t delta_rps_sign;
   uint16_t abs_delta_rps_minus1;
   uint8_t used_by_curr_pic_flag[PIPE_H265_MAX_DPB_SIZE];
   uint8_t use_delta_flag[PIPE_H265_MAX_DPB_SIZE];
   uint8_t num_negative_pics;
   uint8_t num_positive_pics;
   uint16_t delta_poc_s0_minus1[PIPE_H265_MAX_DPB_SIZE];
   uint8_t used_by_curr_pic_s0_flag[PIPE_H265_MAX_DPB_SIZE];
   uint16_t delta_poc_s1_minus1[PIPE_H265_MAX_DPB_SIZE];
   uint8_t used_by_curr_pic_s1_flag[PIPE_H265_MAX_DPB_SIZE];
};
struct pipe_h265_ref_pic_lists_modification
{
   struct {
      uint32_t ref_pic_list_modification_flag_l0 : 1;
      uint32_t ref_pic_list_modification_flag_l1 : 1;
   };
   uint8_t list_entry_l0[PIPE_H265_MAX_NUM_LIST_REF];
   uint8_t list_entry_l1[PIPE_H265_MAX_NUM_LIST_REF];
};
struct pipe_h265_enc_sublayer_hrd_params
{
    uint32_t bit_rate_value_minus1[32];
    uint32_t cpb_size_value_minus1[32];
    uint32_t cpb_size_du_value_minus1[32];
    uint32_t bit_rate_du_value_minus1[32];
    uint32_t cbr_flag[32];
};
struct pipe_h265_enc_hrd_params
{
   uint32_t nal_hrd_parameters_present_flag;
   uint32_t vcl_hrd_parameters_present_flag;
   uint32_t sub_pic_hrd_params_present_flag;
   uint32_t tick_divisor_minus2;
   uint32_t du_cpb_removal_delay_increment_length_minus1;
   uint32_t sub_pic_cpb_params_in_pic_timing_sei_flag;
   uint32_t dpb_output_delay_du_length_minus1;
   uint32_t bit_rate_scale;
   uint32_t cpb_rate_scale;
   uint32_t cpb_size_du_scale;
   uint32_t initial_cpb_removal_delay_length_minus1;
   uint32_t au_cpb_removal_delay_length_minus1;
   uint32_t dpb_output_delay_length_minus1;
   uint32_t fixed_pic_rate_general_flag[PIPE_H265_MAX_SUB_LAYERS];
   uint32_t fixed_pic_rate_within_cvs_flag[PIPE_H265_MAX_SUB_LAYERS];
   uint32_t elemental_duration_in_tc_minus1[PIPE_H265_MAX_SUB_LAYERS];
   uint32_t low_delay_hrd_flag[PIPE_H265_MAX_SUB_LAYERS];
   uint32_t cpb_cnt_minus1[PIPE_H265_MAX_SUB_LAYERS];
   struct pipe_h265_enc_sublayer_hrd_params nal_hrd_parameters[PIPE_H265_MAX_SUB_LAYERS];
   struct pipe_h265_enc_sublayer_hrd_params vlc_hrd_parameters[PIPE_H265_MAX_SUB_LAYERS];
};
struct pipe_h265_profile_tier
{
   struct {
      uint32_t general_tier_flag : 1;
      uint32_t general_progressive_source_flag : 1;
      uint32_t general_interlaced_source_flag : 1;
      uint32_t general_non_packed_constraint_flag : 1;
      uint32_t general_frame_only_constraint_flag : 1;
   };
   uint8_t general_profile_space;
   uint8_t general_profile_idc;
   uint32_t general_profile_compatibility_flag;
};
struct pipe_h265_profile_tier_level
{
   uint8_t general_level_idc;
   uint8_t sub_layer_profile_present_flag[PIPE_H265_MAX_SUB_LAYERS];
   uint8_t sub_layer_level_present_flag[PIPE_H265_MAX_SUB_LAYERS];
   uint8_t sub_layer_level_idc[PIPE_H265_MAX_SUB_LAYERS];
   struct pipe_h265_profile_tier profile_tier;
   struct pipe_h265_profile_tier sub_layer_profile_tier[PIPE_H265_MAX_SUB_LAYERS];
};
struct pipe_h265_enc_vid_param
{
   struct {
      uint32_t vps_base_layer_internal_flag : 1;
      uint32_t vps_base_layer_available_flag : 1;
      uint32_t vps_temporal_id_nesting_flag : 1;
      uint32_t vps_sub_layer_ordering_info_present_flag : 1;
      uint32_t vps_timing_info_present_flag : 1;
      uint32_t vps_poc_proportional_to_timing_flag : 1;
   };
   uint8_t vps_max_layers_minus1;
   uint8_t vps_max_sub_layers_minus1;
   uint8_t vps_max_dec_pic_buffering_minus1[PIPE_H265_MAX_SUB_LAYERS];
   uint8_t vps_max_num_reorder_pics[PIPE_H265_MAX_SUB_LAYERS];
   uint32_t vps_max_latency_increase_plus1[PIPE_H265_MAX_SUB_LAYERS];
   uint8_t vps_max_layer_id;
   uint32_t vps_num_layer_sets_minus1;
   uint32_t vps_num_units_in_tick;
   uint32_t vps_time_scale;
   uint32_t vps_num_ticks_poc_diff_one_minus1;
   struct pipe_h265_profile_tier_level profile_tier_level;
};
struct pipe_h265_enc_seq_param
{
   struct {
      uint32_t sps_temporal_id_nesting_flag : 1;
      uint32_t strong_intra_smoothing_enabled_flag : 1;
      uint32_t amp_enabled_flag : 1;
      uint32_t sample_adaptive_offset_enabled_flag : 1;
      uint32_t pcm_enabled_flag : 1;
      uint32_t sps_temporal_mvp_enabled_flag : 1;
      uint32_t conformance_window_flag : 1;
      uint32_t vui_parameters_present_flag : 1;
      uint32_t video_full_range_flag : 1;
      uint32_t long_term_ref_pics_present_flag : 1;
      uint32_t sps_sub_layer_ordering_info_present_flag : 1;
   };
   uint8_t  general_profile_idc;
   uint8_t  general_level_idc;
   uint8_t  general_tier_flag;
   uint32_t intra_period;
   uint32_t ip_period;
   uint16_t pic_width_in_luma_samples;
   uint16_t pic_height_in_luma_samples;
   uint32_t chroma_format_idc;
   uint32_t bit_depth_luma_minus8;
   uint32_t bit_depth_chroma_minus8;
   uint8_t  log2_max_pic_order_cnt_lsb_minus4;
   uint8_t  log2_min_luma_coding_block_size_minus3;
   uint8_t  log2_diff_max_min_luma_coding_block_size;
   uint8_t  log2_min_transform_block_size_minus2;
   uint8_t  log2_diff_max_min_transform_block_size;
   uint8_t  max_transform_hierarchy_depth_inter;
   uint8_t  max_transform_hierarchy_depth_intra;
   uint16_t conf_win_left_offset;
   uint16_t conf_win_right_offset;
   uint16_t conf_win_top_offset;
   uint16_t conf_win_bottom_offset;
   struct {
      uint32_t aspect_ratio_info_present_flag: 1;
      uint32_t timing_info_present_flag: 1;
      uint32_t video_signal_type_present_flag: 1;
      uint32_t colour_description_present_flag: 1;
      uint32_t chroma_loc_info_present_flag: 1;
      uint32_t overscan_info_present_flag: 1;
      uint32_t overscan_appropriate_flag: 1;
      uint32_t neutral_chroma_indication_flag: 1;
      uint32_t field_seq_flag: 1;
      uint32_t frame_field_info_present_flag: 1;
      uint32_t default_display_window_flag: 1;
      uint32_t poc_proportional_to_timing_flag: 1;
      uint32_t hrd_parameters_present_flag: 1;
      uint32_t bitstream_restriction_flag: 1;
      uint32_t tiles_fixed_structure_flag: 1;
      uint32_t motion_vectors_over_pic_boundaries_flag: 1;
      uint32_t restricted_ref_pic_lists_flag: 1;
   } vui_flags;
   uint32_t aspect_ratio_idc;
   uint32_t sar_width;
   uint32_t sar_height;
   uint32_t num_units_in_tick;
   uint32_t time_scale;
   uint32_t video_format;
   uint32_t colour_primaries;
   uint32_t transfer_characteristics;
   uint32_t matrix_coefficients;
   uint32_t chroma_sample_loc_type_top_field;
   uint32_t chroma_sample_loc_type_bottom_field;
   uint32_t def_disp_win_left_offset;
   uint32_t def_disp_win_right_offset;
   uint32_t def_disp_win_top_offset;
   uint32_t def_disp_win_bottom_offset;
   uint32_t num_ticks_poc_diff_one_minus1;
   uint32_t min_spatial_segmentation_idc;
   uint32_t max_bytes_per_pic_denom;
   uint32_t max_bits_per_min_cu_denom;
   uint32_t log2_max_mv_length_horizontal;
   uint32_t log2_max_mv_length_vertical;
   uint32_t num_temporal_layers;
   uint32_t num_short_term_ref_pic_sets;
   uint32_t num_long_term_ref_pics_sps;
   uint32_t lt_ref_pic_poc_lsb_sps[PIPE_H265_MAX_LONG_TERM_REF_PICS_SPS];
   uint8_t used_by_curr_pic_lt_sps_flag[PIPE_H265_MAX_LONG_TERM_REF_PICS_SPS];
   uint8_t sps_max_sub_layers_minus1;
   uint8_t sps_max_dec_pic_buffering_minus1[PIPE_H265_MAX_SUB_LAYERS];
   uint8_t sps_max_num_reorder_pics[PIPE_H265_MAX_SUB_LAYERS];
   uint32_t sps_max_latency_increase_plus1[PIPE_H265_MAX_SUB_LAYERS];
   struct pipe_h265_profile_tier_level profile_tier_level;
   struct pipe_h265_enc_hrd_params hrd_parameters;
   struct pipe_h265_st_ref_pic_set st_ref_pic_set[PIPE_H265_MAX_ST_REF_PIC_SETS];
   struct {
      uint32_t sps_range_extension_flag;
      uint32_t transform_skip_rotation_enabled_flag: 1;
      uint32_t transform_skip_context_enabled_flag: 1;
      uint32_t implicit_rdpcm_enabled_flag: 1;
      uint32_t explicit_rdpcm_enabled_flag: 1;
      uint32_t extended_precision_processing_flag: 1;
      uint32_t intra_smoothing_disabled_flag: 1;
      uint32_t high_precision_offsets_enabled_flag: 1;
      uint32_t persistent_rice_adaptation_enabled_flag: 1;
      uint32_t cabac_bypass_alignment_enabled_flag: 1;
   } sps_range_extension;
   uint8_t separate_colour_plane_flag;
};
struct pipe_h265_enc_pic_param
{
   struct {
      uint32_t dependent_slice_segments_enabled_flag : 1;
      uint32_t output_flag_present_flag : 1;
      uint32_t sign_data_hiding_enabled_flag : 1;
      uint32_t cabac_init_present_flag : 1;
      uint32_t constrained_intra_pred_flag : 1;
      uint32_t transform_skip_enabled_flag : 1;
      uint32_t cu_qp_delta_enabled_flag : 1;
      uint32_t weighted_pred_flag : 1;
      uint32_t weighted_bipred_flag : 1;
      uint32_t transquant_bypass_enabled_flag : 1;
      uint32_t entropy_coding_sync_enabled_flag : 1;
      uint32_t pps_slice_chroma_qp_offsets_present_flag : 1;
      uint32_t pps_loop_filter_across_slices_enabled_flag : 1;
      uint32_t deblocking_filter_control_present_flag : 1;
      uint32_t deblocking_filter_override_enabled_flag : 1;
      uint32_t pps_deblocking_filter_disabled_flag : 1;
      uint32_t lists_modification_present_flag : 1;
   };
   uint8_t log2_parallel_merge_level_minus2;
   uint8_t nal_unit_type;
   uint8_t temporal_id;
   uint8_t num_extra_slice_header_bits;
   uint8_t num_ref_idx_l0_default_active_minus1;
   uint8_t num_ref_idx_l1_default_active_minus1;
   int8_t init_qp_minus26;
   uint8_t diff_cu_qp_delta_depth;
   int8_t pps_cb_qp_offset;
   int8_t pps_cr_qp_offset;
   int8_t pps_beta_offset_div2;
   int8_t pps_tc_offset_div2;
   struct {
      uint8_t pps_range_extension_flag;
      uint32_t log2_max_transform_skip_block_size_minus2;
      uint32_t cross_component_prediction_enabled_flag: 1;
      uint32_t chroma_qp_offset_list_enabled_flag: 1;
      uint32_t diff_cu_chroma_qp_offset_depth;
      uint32_t chroma_qp_offset_list_len_minus1;
      int32_t cb_qp_offset_list[6];
      int32_t cr_qp_offset_list[6];
      uint32_t log2_sao_offset_scale_luma;
      uint32_t log2_sao_offset_scale_chroma;
   } pps_range_extension;
};
struct pipe_h265_enc_slice_param
{
   struct {
      uint32_t no_output_of_prior_pics_flag : 1;
      uint32_t dependent_slice_segment_flag : 1;
      uint32_t pic_output_flag : 1;
      uint32_t short_term_ref_pic_set_sps_flag : 1;
      uint32_t slice_sao_luma_flag : 1;
      uint32_t slice_sao_chroma_flag : 1;
      uint32_t slice_temporal_mvp_enabled_flag : 1;
      uint32_t num_ref_idx_active_override_flag : 1;
      uint32_t mvd_l1_zero_flag : 1;
      uint32_t cabac_init_flag : 1;
      uint32_t collocated_from_l0_flag : 1;
      uint32_t cu_chroma_qp_offset_enabled_flag : 1;
      uint32_t deblocking_filter_override_flag : 1;
      uint32_t slice_deblocking_filter_disabled_flag : 1;
      uint32_t slice_loop_filter_across_slices_enabled_flag : 1;
   };
   uint8_t slice_type;
   uint32_t slice_pic_order_cnt_lsb;
   uint8_t colour_plane_id;
   uint8_t short_term_ref_pic_set_idx;
   uint8_t num_long_term_sps;
   uint8_t num_long_term_pics;
   uint8_t lt_idx_sps[PIPE_H265_MAX_LONG_TERM_REF_PICS_SPS];
   uint8_t poc_lsb_lt[PIPE_H265_MAX_LONG_TERM_PICS];
   uint8_t used_by_curr_pic_lt_flag[PIPE_H265_MAX_LONG_TERM_PICS];
   uint8_t delta_poc_msb_present_flag[PIPE_H265_MAX_DELTA_POC];
   uint8_t delta_poc_msb_cycle_lt[PIPE_H265_MAX_DELTA_POC];
   uint8_t num_ref_idx_l0_active_minus1;
   uint8_t num_ref_idx_l1_active_minus1;
   uint8_t collocated_ref_idx;
   uint8_t max_num_merge_cand;
   int8_t slice_qp_delta;
   int8_t slice_cb_qp_offset;
   int8_t slice_cr_qp_offset;
   int8_t slice_beta_offset_div2;
   int8_t slice_tc_offset_div2;
   struct pipe_h265_ref_pic_lists_modification ref_pic_lists_modification;
};
#endif
