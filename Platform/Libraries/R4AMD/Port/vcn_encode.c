/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 AND MIT
 * Bounded VCN1 adapter using unchanged Mesa26.2.2 header/packet functions.
 * Original AMD/Younes Manton notices and complete MIT text accompany source. */
#include "vcn_encode.h"
#include "vcn_encode_private.h"
#include "Generated/Encode/commands.inc"
#include "Generated/Encode/helpers.inc"
#include "Generated/Encode/bitstream.inc"
#include "Generated/Encode/packets.inc"
struct scratch {
 struct radeon_encoder enc;
 struct pipe_h264_enc_picture_desc avc;
 struct pipe_h265_enc_picture_desc hevc;
 struct ac_video_enc_codec_caps caps;
 struct pb_buffer_lean session,dpb,input,bitstream,feedback;
 struct si_resource session_res,dpb_res,feedback_res;
 struct radeon_enc_fb_buffer feedback_buf;
 struct radeon_surf luma,chroma;
 uint32_t words[R4AMD_ENCODE_COMMAND_WORDS];
 uint8_t headers[R4AMD_ENCODE_HEADER_BYTES];
};
uint32_t r4amd_encode_scratch_bytes(void) { return sizeof(struct scratch); }
static uint32_t round_up(uint32_t x,uint32_t a) { return (x+a-1)&~(a-1); }
int r4amd_encode_plan(const struct r4amd_encode_config *c,struct r4amd_encode_requirements *out)
{
 if(!c || !out || (c->codec!=1 && c->codec!=2) || c->width<(c->codec==1?128u:130u) || c->height<128 ||
    c->width>4096 || c->height>2304 || ((c->width|c->height)&1) || !c->fps_num || !c->fps_den ||
    c->fps_num>1000000 || c->fps_den>1000000 || c->fps_num>(uint64_t)c->fps_den*240 ||
    c->qp>51 || c->min_qp>c->qp || c->max_qp<c->qp || c->max_qp>51 || c->rate>2 ||
    !c->gop || c->gop>65535 || (c->transfer!=1 && c->transfer!=13) ||
    c->packet_bytes<4096 || c->packet_bytes>8*1024*1024) return -1;
 if((c->codec==1 && c->profile!=66 && c->profile!=77 && c->profile!=100) || (c->codec==2 && c->profile!=1))return -2;
 if(!c->rate){if(c->target_bps || c->peak_bps || c->buffer_bits)return -2;}
 else if(!c->target_bps || !c->buffer_bits || c->peak_bps<c->target_bps ||
         (c->rate==1 && c->peak_bps!=c->target_bps) || c->peak_bps>200000000 ||
         c->buffer_bits<c->peak_bps/240 || c->buffer_bits>400000000 ||
         (uint64_t)c->target_bps*c->fps_den/c->fps_num>UINT32_MAX ||
         (uint64_t)c->peak_bps*c->fps_den/c->fps_num>UINT32_MAX) return -1;
 uint32_t alignment=c->codec==1?16:64,w=round_up(c->width,alignment),h=round_up(c->height,alignment);
 // H264 level5.2:36864 MB/frame,2073600 MB/s. HEVC Main level6.2:
 // 35651584 luma samples/frame,4278190080 samples/s; driver dimensions narrow it.
 uint64_t units=c->codec==1?(uint64_t)(w/16)*(h/16):(uint64_t)w*h;
 if(c->codec==1 && (units>36864 || units*c->fps_num>(uint64_t)2073600*c->fps_den))return -2;
 if(c->codec==2 && units*c->fps_num>UINT64_C(4278190080)*c->fps_den)return -2;
 uint32_t pitch=round_up(w,256),rows=h<256?256:h,luma=round_up(pitch*rows,256),chroma=round_up(luma/2,256);
 *out=(struct r4amd_encode_requirements){2*(luma+chroma),pitch,h,luma,luma+chroma};return 0;
}
static void configure(struct scratch *s,const struct r4amd_encode_config *c,const struct r4amd_encode_requirements *req)
{
 memset(s,0,sizeof(*s));struct radeon_encoder *enc=&s->enc;struct radeon_enc_pic *p=&enc->enc_pic;
 enc->caps=&s->caps;enc->cs.current.buf=s->words;p->h264.desc=&s->avc;p->hevc.desc=&s->hevc;
 ac_vcn_enc_init_cmds(&enc->cmd,VCN_1_0_0);
#define SET(name) enc->name=radeon_enc_##name
 SET(session_info);SET(task_info);SET(session_init);SET(layer_control);SET(layer_select);
 SET(rc_session_init);SET(rc_layer_init);SET(quality_params);SET(ctx);SET(bitstream);
 SET(feedback);SET(intra_refresh);SET(encode_params);SET(op_init);SET(op_close);SET(op_enc);
 SET(op_init_rc);SET(op_init_rc_vbv);SET(op_preset);SET(encode_statistics);SET(qp_map);SET(encode_latency);
#undef SET
 enc->rc_per_pic=radeon_enc_rc_per_pic_ex;
 enc->input_format=enc->output_format=enc->ctx_override=enc->metadata=radeon_enc_dummy;
 bool h264=c->codec==1;
 enc->slice_control=h264?radeon_enc_slice_control:radeon_enc_slice_control_hevc;
 enc->spec_misc=h264?radeon_enc_spec_misc:radeon_enc_spec_misc_hevc;
 enc->deblocking_filter=h264?radeon_enc_deblocking_filter_h264:radeon_enc_deblocking_filter_hevc;
 enc->slice_header=h264?radeon_enc_slice_header:radeon_enc_slice_header_hevc;
 enc->encode_headers=h264?radeon_enc_headers_h264:radeon_enc_headers_hevc;
 enc->encode_params_codec_spec=h264?radeon_enc_encode_params_h264:radeon_enc_dummy;
 // Firmware0x0310f005 has encode ABI1.15; Mesa clamps VCN1 packets to1.9
 // and selects the extended per-picture rate controls at minor>=15.
 p->session_info.interface_version=0x00010009;p->num_temporal_layers=1;
 uint32_t block=h264?16:64,aw=round_up(c->width,block),ah=round_up(c->height,block);
 p->session_init=(rvcn_enc_session_init_t){.encode_standard=h264?RENCODE_ENCODE_STANDARD_H264:RENCODE_ENCODE_STANDARD_HEVC,
  .aligned_picture_width=aw,.aligned_picture_height=ah,.padding_width=aw-c->width,.padding_height=ah-c->height};
 p->slice_ctrl.num_mbs_per_slice=aw/16*(ah/16);
 p->hevc_slice_ctrl.fixed_ctbs_per_slice.num_ctbs_per_slice=aw/64*(ah/64);
 p->hevc_slice_ctrl.fixed_ctbs_per_slice.num_ctbs_per_slice_segment=aw/64*(ah/64);
 p->quality_modes.preset_mode=RENCODE_PRESET_MODE_BALANCE;
 p->spec_misc=(rvcn_enc_h264_spec_misc_t){.cabac_enable=c->profile!=66,.half_pel_enabled=1,.quarter_pel_enabled=1,
  .profile_idc=c->profile,.level_idc=52,.deblocking_filter_control_present_flag=1};
 p->hevc_spec_misc=(rvcn_enc_hevc_spec_misc_t){.log2_min_luma_coding_block_size_minus3=0,.amp_disabled=1,
  .strong_intra_smoothing_enabled=1,.half_pel_enabled=1,.quarter_pel_enabled=1,.transform_skip_disabled=1,.cu_qp_delta_enabled_flag=c->rate!=0};
 p->hevc_deblock.disable_sao=1;
 p->hevc_deblock.loop_filter_across_slices_enabled=1;
 p->rc_session_init.rate_control_method=!c->rate?RENCODE_RATE_CONTROL_METHOD_NONE:c->rate==1?RENCODE_RATE_CONTROL_METHOD_CBR:RENCODE_RATE_CONTROL_METHOD_PEAK_CONSTRAINED_VBR;
 p->rc_session_init.vbv_buffer_level=64;
 uint64_t peak=(uint64_t)c->peak_bps*c->fps_den;
 p->rc_layer_init[0]=(rvcn_enc_rate_ctl_layer_init_t){.target_bit_rate=c->target_bps,.peak_bit_rate=c->peak_bps,
  .frame_rate_num=c->fps_num,.frame_rate_den=c->fps_den,.vbv_buffer_size=c->buffer_bits,
  .avg_target_bits_per_picture=(uint64_t)c->target_bps*c->fps_den/c->fps_num,
  .peak_bits_per_picture_integer=peak/c->fps_num,.peak_bits_per_picture_fractional=((peak%c->fps_num)<<32)/c->fps_num};
 p->rc_per_pic=(rvcn_enc_rate_ctl_per_picture_t){.qp_i=c->qp,.qp_p=c->qp,.qp_b=c->qp,
  .min_qp_i=c->rate?c->min_qp:c->qp,.max_qp_i=c->rate?c->max_qp:c->qp,
  .min_qp_p=c->rate?c->min_qp:c->qp,.max_qp_p=c->rate?c->max_qp:c->qp,
  .min_qp_b=c->rate?c->min_qp:c->qp,.max_qp_b=c->rate?c->max_qp:c->qp,
  .enabled_filler_data=c->rate==1,.enforce_hrd=c->rate!=0};
 p->ctx_buf.rec_luma_pitch=p->ctx_buf.rec_chroma_pitch=req->pitch;p->ctx_buf.num_reconstructed_pictures=2;
 p->ctx_buf.pre_encode_picture_luma_pitch=p->ctx_buf.pre_encode_picture_chroma_pitch=req->pitch;
 for(unsigned i=0;i<2;i++) { p->ctx_buf.reconstructed_pictures[i].luma_offset=i*req->picture_bytes;
  p->ctx_buf.reconstructed_pictures[i].chroma_offset=i*req->picture_bytes+req->chroma_offset; }
 // The original SPS/PPS/VPS and slice-template writers share these exact
 // settings. One reference, no B pictures, no long-term/interlace/tile modes.
 struct pipe_h264_enc_seq_param *avc=&s->avc.seq;
 avc->profile_idc=c->profile;avc->level_idc=52;avc->enc_constraint_set_flags=c->profile==66?0x30:0;
 avc->pic_order_cnt_type=0;avc->log2_max_frame_num_minus4=12;avc->log2_max_pic_order_cnt_lsb_minus4=12;
 avc->max_num_ref_frames=1;avc->pic_width_in_mbs_minus1=aw/16-1;avc->pic_height_in_map_units_minus1=ah/16-1;
 avc->enc_frame_cropping_flag=aw!=c->width || ah!=c->height;
 avc->enc_frame_crop_right_offset=(aw-c->width)/2;avc->enc_frame_crop_bottom_offset=(ah-c->height)/2;
 avc->vui_parameters_present_flag=1;avc->vui_flags.timing_info_present_flag=1;avc->vui_flags.fixed_frame_rate_flag=1;
 avc->vui_flags.video_signal_type_present_flag=1;avc->vui_flags.colour_description_present_flag=1;
 avc->video_format=5;avc->colour_primaries=1;avc->transfer_characteristics=c->transfer;avc->matrix_coefficients=1;
 avc->num_units_in_tick=c->fps_den;avc->time_scale=c->fps_num*2;
 s->avc.pic_ctrl.enc_cabac_enable=p->spec_misc.cabac_enable;s->avc.pic_ctrl.entropy_coding_mode_flag=p->spec_misc.cabac_enable;
 s->avc.pic_ctrl.deblocking_filter_control_present_flag=1;s->avc.pic_ctrl.more_rbsp_data=c->profile==100;
 struct pipe_h265_enc_seq_param *hevc=&s->hevc.seq;
 hevc->pic_width_in_luma_samples=c->width;hevc->pic_height_in_luma_samples=c->height;hevc->chroma_format_idc=1;
 hevc->sps_temporal_id_nesting_flag=1;hevc->strong_intra_smoothing_enabled_flag=1;
 hevc->log2_max_pic_order_cnt_lsb_minus4=12;hevc->sps_max_dec_pic_buffering_minus1[0]=1;
 hevc->num_short_term_ref_pic_sets=1;hevc->st_ref_pic_set[0].num_negative_pics=1;hevc->st_ref_pic_set[0].used_by_curr_pic_s0_flag[0]=1;
 hevc->profile_tier_level.general_level_idc=186;
 hevc->profile_tier_level.profile_tier.general_profile_idc=1;
 hevc->profile_tier_level.profile_tier.general_profile_compatibility_flag=1u<<30;
 hevc->profile_tier_level.profile_tier.general_progressive_source_flag=1;
 hevc->profile_tier_level.profile_tier.general_frame_only_constraint_flag=1;
 hevc->vui_parameters_present_flag=1;hevc->vui_flags.timing_info_present_flag=1;
 hevc->vui_flags.video_signal_type_present_flag=1;hevc->vui_flags.colour_description_present_flag=1;
 hevc->video_format=5;hevc->colour_primaries=1;hevc->transfer_characteristics=c->transfer;hevc->matrix_coefficients=1;
 hevc->num_units_in_tick=c->fps_den;hevc->time_scale=c->fps_num;
 s->hevc.vid.profile_tier_level=hevc->profile_tier_level;s->hevc.vid.vps_base_layer_internal_flag=1;
 s->hevc.vid.vps_base_layer_available_flag=1;s->hevc.vid.vps_temporal_id_nesting_flag=1;s->hevc.vid.vps_max_dec_pic_buffering_minus1[0]=1;
 s->hevc.pic.dependent_slice_segments_enabled_flag=1;s->hevc.pic.cu_qp_delta_enabled_flag=c->rate!=0;
 s->hevc.pic.pps_loop_filter_across_slices_enabled_flag=1;s->hevc.pic.deblocking_filter_control_present_flag=1;
}
int r4amd_encode_headers(void *storage,const struct r4amd_encode_config *c,uint8_t *out,uint32_t *bytes)
{
 struct r4amd_encode_requirements req;int rc=r4amd_encode_plan(c,&req);if(rc)return rc;
 if(!storage || (uintptr_t)storage%8 || !out || !bytes)return -1;
 struct scratch *s=storage;configure(s,c,&req);uint32_t n=0;
 if(c->codec==1){n=radeon_enc_write_sps(&s->enc,0x67,s->headers);n+=radeon_enc_write_pps(&s->enc,0x68,s->headers+n);}
 else {n=radeon_enc_write_vps(&s->enc,s->headers);n+=radeon_enc_write_sps_hevc(&s->enc,s->headers+n);n+=radeon_enc_write_pps_hevc(&s->enc,s->headers+n);}
 if(!n || n>R4AMD_ENCODE_HEADER_BYTES)return -3;
 memcpy(out,s->headers,n);*bytes=n;return 0;
}
static bool address(uint64_t va,uint64_t size) { return va && va%256==0 && size && va<(UINT64_C(1)<<40) && size<=(UINT64_C(1)<<40)-va; }
int r4amd_encode_commands(void *storage,const struct r4amd_encode_config *c,const struct r4amd_encode_job *j,uint32_t op,uint32_t *out,uint32_t *words)
{
 struct r4amd_encode_requirements req;int rc=r4amd_encode_plan(c,&req);if(rc)return rc;
 if(!storage || (uintptr_t)storage%8 || !j || !out || !words || op>2 || !j->serial || !address(j->session,R4AMD_ENCODE_SESSION_BYTES))return -1;
 uint32_t aw=round_up(c->width,c->codec==1?16:64),ah=round_up(c->height,c->codec==1?16:64);
 if(op==1 && (!address(j->dpb,req.dpb_bytes) || !address(j->bitstream,c->packet_bytes) || !address(j->feedback,4096) ||
    !address(j->input,j->input_bytes) || j->input_pitch%256 || j->input_pitch<aw || j->input_chroma%256 ||
    (uint64_t)j->input_pitch*ah>j->input_chroma || (uint64_t)j->input_chroma+(uint64_t)j->input_pitch*(ah/2)>j->input_bytes ||
    j->key>1 || j->reference>1 || j->reconstructed>1 || (!j->key && j->reference==j->reconstructed) ||
    j->frame_num>65535 || j->poc>65535 || j->idr_id>65535))return -1;
 struct scratch *s=storage;configure(s,c,&req);struct radeon_encoder *enc=&s->enc;struct radeon_enc_pic *p=&enc->enc_pic;
 s->session.address=j->session;s->dpb.address=j->dpb;s->input.address=j->input;s->bitstream.address=j->bitstream;s->feedback.address=j->feedback;
 s->session_res.buf=&s->session;s->dpb_res.buf=&s->dpb;s->feedback_res.buf=&s->feedback;s->feedback_buf.res=&s->feedback_res;
 enc->si=&s->session_res;enc->dpb=&s->dpb_res;enc->fb=&s->feedback_buf;enc->handle=&s->input;enc->bs_handle=&s->bitstream;
 enc->bs_size=c->packet_bytes;enc->need_feedback=op==1;enc->luma=&s->luma;enc->chroma=&s->chroma;
 s->luma.u.gfx9.surf_pitch=s->chroma.u.gfx9.surf_pitch=j->input_pitch;s->chroma.u.gfx9.surf_offset=j->input_chroma;
 p->task_info.task_id=j->serial-1;p->picture_type=j->key?PIPE_H2645_ENC_PICTURE_TYPE_IDR:PIPE_H2645_ENC_PICTURE_TYPE_P;
 p->nal_unit_type=j->key?19:1;p->enc_params.allowed_max_bitstream_size=c->packet_bytes;
 p->enc_params.reference_picture_index=j->key?UINT32_MAX:j->reference;p->enc_params.reconstructed_picture_index=j->reconstructed;
 p->h264_enc_params.is_reference=1;
 p->h264_enc_params.l0_reference_picture1_index=UINT32_MAX;
 p->h264_enc_params.l1_reference_picture0_index=UINT32_MAX;
 s->avc.pic_ctrl.nal_ref_idc=3;s->avc.pic_ctrl.nal_unit_type=j->key?5:1;
 s->avc.slice.frame_num=j->key?0:j->frame_num;s->avc.slice.pic_order_cnt_lsb=j->key?0:j->poc;s->avc.slice.idr_pic_id=j->idr_id;
 s->hevc.slice.slice_type=j->key?2:1;s->hevc.slice.slice_pic_order_cnt_lsb=j->key?0:j->poc;
 s->hevc.slice.short_term_ref_pic_set_sps_flag=1;s->hevc.slice.max_num_merge_cand=5;s->hevc.slice.slice_loop_filter_across_slices_enabled_flag=1;
 if(op==0)begin(enc);else if(op==1)encode(enc);else destroy(enc);
 uint32_t count=round_up(enc->cs.current.cdw,16);
 if(enc->error || count>R4AMD_ENCODE_COMMAND_WORDS)return -3;
 memcpy(out,s->words,count*4);*words=count;return 0;
}
