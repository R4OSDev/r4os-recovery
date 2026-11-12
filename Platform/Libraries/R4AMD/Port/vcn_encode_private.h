/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 AND MIT
 * Minimal host-independent owner for original Mesa VCN1 packet functions.
 * Mesa/AMD/Younes Manton notices accompany Generated/Encode and originals. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include <assert.h>
#include "Generated/Encode/metadata.h"
#include "Generated/Encode/wire.h"
struct radeon_cmdbuf { struct { uint32_t *buf; unsigned cdw; } current; };
#include "Generated/Encode/bitstream.h"
static unsigned util_logbase2(unsigned v) { return v ? 31-__builtin_clz(v):0; }
static unsigned util_logbase2_ceil(unsigned v) { return v>1 ? 32-__builtin_clz(v-1):0; }
#define debug_warn_once(...) ((void)0)
#define MIN2(a,b) ((a)<(b)?(a):(b))
struct pipe_h264_enc_picture_desc {
 struct pipe_h264_enc_seq_param seq;
 struct pipe_h264_enc_pic_control pic_ctrl;
 struct pipe_h264_enc_slice_param slice;
};
struct pipe_h265_enc_picture_desc {
 struct pipe_h265_enc_vid_param vid;
 struct pipe_h265_enc_seq_param seq;
 struct pipe_h265_enc_pic_param pic;
 struct pipe_h265_enc_slice_param slice;
};
struct radeon_surf { unsigned meta_offset,tile_swizzle; struct { struct { unsigned surf_pitch,surf_offset,swizzle_mode; } gfx9; } u; };
struct pb_buffer_lean { uint64_t address; };
struct si_resource { struct pb_buffer_lean *buf; unsigned domains; };
struct radeon_enc_fb_buffer { struct si_resource *res; };
struct ac_video_enc_codec_caps { struct { bool dependent_slice_segments; } hevc; };
struct radeon_enc_pic {
 enum pipe_h2645_enc_picture_type picture_type;
 struct { struct pipe_h264_enc_picture_desc *desc; } h264;
 struct { struct pipe_h265_enc_picture_desc *desc; } hevc;
 unsigned nal_unit_type,temporal_id,num_temporal_layers;
 rvcn_enc_quality_modes_t quality_modes;
 rvcn_enc_session_info_t session_info;
 rvcn_enc_task_info_t task_info;
 rvcn_enc_session_init_t session_init;
 rvcn_enc_layer_control_t layer_ctrl;
 rvcn_enc_layer_select_t layer_sel;
 rvcn_enc_h264_slice_control_t slice_ctrl;
 rvcn_enc_hevc_slice_control_t hevc_slice_ctrl;
 rvcn_enc_h264_spec_misc_t spec_misc;
 rvcn_enc_hevc_spec_misc_t hevc_spec_misc;
 rvcn_enc_rate_ctl_session_init_t rc_session_init;
 rvcn_enc_rate_ctl_layer_init_t rc_layer_init[RENCODE_MAX_NUM_TEMPORAL_LAYERS];
 rvcn_enc_h264_encode_params_t h264_enc_params;
 rvcn_enc_h264_deblocking_filter_t h264_deblock;
 rvcn_enc_hevc_deblocking_filter_t hevc_deblock;
 rvcn_enc_rate_ctl_per_picture_t rc_per_pic;
 rvcn_enc_quality_params_t quality_params;
 rvcn_enc_encode_context_buffer_t ctx_buf;
 rvcn_enc_video_bitstream_buffer_t bit_buf;
 rvcn_enc_feedback_buffer_t fb_buf;
 rvcn_enc_intra_refresh_t intra_refresh;
 rvcn_enc_encode_params_t enc_params;
 rvcn_enc_stats_t enc_statistics;
 rvcn_enc_qp_map_t enc_qp_map;
 rvcn_enc_latency_t enc_latency;
 rvcn_enc_h264_slice_info_var_t h264_slice_info_var;
 rvcn_enc_hevc_slice_info_var_t hevc_slice_info_var;
};
struct radeon_encoder {
#define ACTION(name) void (*name)(struct radeon_encoder*);
 ACTION(session_info) ACTION(session_init) ACTION(layer_control) ACTION(layer_select)
 ACTION(rc_session_init) ACTION(rc_layer_init) ACTION(quality_params) ACTION(ctx)
 ACTION(bitstream) ACTION(feedback) ACTION(intra_refresh) ACTION(rc_per_pic)
 ACTION(encode_params) ACTION(op_init) ACTION(op_close) ACTION(op_enc)
 ACTION(op_init_rc) ACTION(op_init_rc_vbv) ACTION(op_preset) ACTION(encode_statistics)
 ACTION(qp_map) ACTION(encode_latency) ACTION(input_format) ACTION(output_format)
 ACTION(ctx_override) ACTION(metadata) ACTION(slice_control) ACTION(spec_misc)
 ACTION(deblocking_filter) ACTION(slice_header) ACTION(encode_params_codec_spec) ACTION(encode_headers)
#undef ACTION
 void (*task_info)(struct radeon_encoder*,bool);
 struct radeon_cmdbuf cs;
 struct pb_buffer_lean *handle,*bs_handle,*stats;
 struct radeon_surf *luma,*chroma;
 struct si_resource *si,*dpb,*roi;
 struct radeon_enc_fb_buffer *fb;
 struct radeon_enc_pic enc_pic;
 struct ac_video_enc_codec_caps *caps;
 rvcn_enc_cmd_t cmd;
 uint32_t total_task_size,*p_task_size,bs_size,bs_offset;
 bool need_feedback,need_rate_control,need_rc_per_pic,error;
};
/* These retain the original packet-length/task-size semantics. Addresses
 * come only from checked canonical R4OS GPU bindings, never host pointers. */
#define RADEON_ENC_CS(v) (enc->cs.current.buf[enc->cs.current.cdw++]=(v))
#define RADEON_ENC_BEGIN(cmd) { uint32_t *begin=&enc->cs.current.buf[enc->cs.current.cdw++]; RADEON_ENC_CS(cmd)
#define RADEON_ENC_END() *begin=(&enc->cs.current.buf[enc->cs.current.cdw]-begin)*4; enc->total_task_size+=*begin; }
#define RADEON_ENC_READ(buf,domain,off) r4amd_encode_address(enc,(buf),(off))
#define RADEON_ENC_WRITE(buf,domain,off) r4amd_encode_address(enc,(buf),(off))
#define RADEON_ENC_READWRITE(buf,domain,off) r4amd_encode_address(enc,(buf),(off))
#define RADEON_ENC_ERR(...) (enc->error=true)
static void r4amd_encode_address(struct radeon_encoder *enc,const struct pb_buffer_lean *buf,uint32_t off) {
 uint64_t va=buf->address+off; RADEON_ENC_CS(va>>32);RADEON_ENC_CS((uint32_t)va);
}
