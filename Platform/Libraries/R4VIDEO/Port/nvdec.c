/*
 * R4OS H.264 hardware callback bridge.
 * Copyright 2026 R4.
 * Parameter/DPB mapping adapted from FFmpeg libavcodec/nvdec_h264.c:
 * Copyright (c) 2016 Anton Khirnov
 * SPDX-License-Identifier: LGPL-2.1-or-later
 *
 * This file is part of the R4VIDEO FFmpeg port. It is free software; you can
 * redistribute it and/or modify it under the terms of the GNU Lesser General
 * Public License as published by the Free Software Foundation; either version
 * 2.1 of the License, or (at your option) any later version.
 *
 * It is distributed in the hope that it will be useful, but WITHOUT ANY
 * WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for
 * more details. A copy is in ../ThirdParty/COPYING.LGPLv2.1.
 */
#include "codec_internal.h"
#include "hardware_private.h"
#include "r4video.h"
#include "libavcodec/h264dec.h"
#include "libavcodec/hwaccel_internal.h"
#include "libavutil/mem.h"
#include <limits.h>
#include <string.h>

enum image_state { IMAGE_ALLOCATED, IMAGE_BEGUN, IMAGE_COMPLETE, IMAGE_ABORTED };
struct image {
    struct r4video_nvdec_ops ops;
    void *surface;
    enum image_state state;
};

static int error(AVCodecContext *context, int result)
{
    if (!result) return 0;
    struct r4video_codec *codec = context->opaque;
    /* AGAIN is meaningful at the public queue, not inside an already accepted
     * FFmpeg picture. Never turn a partial hardware failure into software. */
    if (result >= 0) result = R4VIDEO_ERROR_DECODE;
    r4video_codec_reject(codec, result);
    return result == R4VIDEO_ERROR_NO_MEMORY ? AVERROR(ENOMEM) :
           result == R4VIDEO_ERROR_UNSUPPORTED ? AVERROR(ENOSYS) : AVERROR(EINVAL);
}

static int sequence(AVCodecContext *context, struct r4video_nvdec_sequence *out)
{
    if (context->codec_id != AV_CODEC_ID_H264) return r4video_vcn_sequence(context, out);
    int rc = r4video_codec_admitted(context);
    if (rc) return rc;
    const H264Context *h = context->priv_data;
    const SPS *sps = h->ps.sps;
    if (sps->mb_aff || sps->residual_color_transform_flag || sps->transform_bypass)
        return R4VIDEO_ERROR_UNSUPPORTED;
    if (sps->log2_max_frame_num < 4 || sps->log2_max_frame_num > 16 || sps->poc_type > 2 ||
        (sps->poc_type == 0 && (sps->log2_max_poc_lsb < 4 || sps->log2_max_poc_lsb > 16)))
        return R4VIDEO_ERROR_DECODE;
    *out = (struct r4video_nvdec_sequence){
        .profile=sps->profile_idc, .level=sps->level_idc,
        .width_mbs=sps->mb_width, .height_mbs=sps->mb_height, .max_refs=sps->ref_frame_count,
        .log2_frame_num=sps->log2_max_frame_num, .poc_type=sps->poc_type,
        .log2_poc_lsb=sps->poc_type == 0 ? sps->log2_max_poc_lsb : 4,
        .delta_poc_always_zero=sps->delta_pic_order_always_zero_flag,
        .direct_8x8=sps->direct_8x8_inference_flag,
        .gaps_allowed=sps->gaps_in_frame_num_allowed_flag,
    };
    return R4VIDEO_OK;
}

static struct image *image(const AVFrame *frame)
{
    if (!frame || frame->format != AV_PIX_FMT_R4OS_NVDEC || !frame->buf[0] ||
        frame->buf[0]->size != sizeof(struct image) || frame->data[0] != frame->buf[0]->data)
        return NULL;
    return (struct image *)frame->data[0];
}

static void abort_image(struct image *value)
{
    if (value->surface && value->state != IMAGE_ABORTED && value->state != IMAGE_COMPLETE) {
        value->state = IMAGE_ABORTED;
        value->ops.abort(value->ops.owner, value->surface);
    }
}
static void free_image(void *opaque, uint8_t *bytes)
{
    struct image *value = opaque;
    (void)bytes;
    abort_image(value);
    if (value->surface) value->ops.release(value->ops.owner, value->surface);
    av_free(value);
}

int r4video_nvdec_buffer(AVCodecContext *context, AVFrame *frame)
{
    struct r4video_codec *codec = context->opaque;
    struct r4video_nvdec_sequence info;
    int rc = sequence(context, &info);
    if (rc) return error(context, rc);
    if (!codec->config.nvdec || frame->format != AV_PIX_FMT_R4OS_NVDEC)
        return error(context, R4VIDEO_ERROR_UNSUPPORTED);
    struct image *value = av_mallocz(sizeof(*value));
    if (!value) return error(context, R4VIDEO_ERROR_NO_MEMORY);
    value->ops = codec->nvdec;
    rc = value->ops.allocate(value->ops.owner, &info, &value->surface);
    if (rc || !value->surface) {
        free_image(value, NULL);
        return error(context, rc ? rc : R4VIDEO_ERROR_DECODE);
    }
    AVBufferRef *buffer = av_buffer_create((uint8_t *)value, sizeof(*value), free_image, value, AV_BUFFER_FLAG_READONLY);
    if (!buffer) {
        free_image(value, NULL);
        return error(context, R4VIDEO_ERROR_NO_MEMORY);
    }
    frame->buf[0] = buffer;
    frame->data[0] = (uint8_t *)value;
    /* FFmpeg's get_buffer2 path attaches packet identity and decode metadata.
     * This buffer contains only an opaque owner, never CPU-addressable pixels. */
    return 0;
}

void *r4video_nvdec_image(const AVFrame *frame)
{
    const struct image *value = image(frame);
    return value && value->state == IMAGE_COMPLETE ? value->surface : NULL;
}

static int add_reference(struct r4video_nvdec_picture *p, const struct image *current,
                         const H264Picture *ref, unsigned frame_index)
{
    struct image *value = image(ref->f);
    if (!value || value->state != IMAGE_COMPLETE || value->ops.owner != current->ops.owner ||
        (ref->reference & 3) != 3 || ref->field_poc[0] == INT_MAX || ref->field_poc[1] == INT_MAX ||
        p->reference_count >= 16) return R4VIDEO_ERROR_DECODE;
    if (value->surface == current->surface) return R4VIDEO_ERROR_DECODE;
    for (unsigned i = 0; i < p->reference_count; i++)
        if (p->references[i].image == value->surface) return R4VIDEO_ERROR_UNSUPPORTED;
    p->references[p->reference_count++] = (struct r4video_nvdec_reference){
        .image=value->surface, .long_term=!!ref->long_ref, .frame_index=frame_index,
        .poc={ref->field_poc[0],ref->field_poc[1]},
    };
    return R4VIDEO_OK;
}

static int start(AVCodecContext *context, const AVBufferRef *buffer_ref, const uint8_t *buffer, uint32_t size)
{
    (void)buffer_ref; (void)buffer; (void)size;
    const H264Context *h = context->priv_data;
    const PPS *pps = h->ps.pps;
    struct image *current = h->cur_pic_ptr ? image(h->cur_pic_ptr->f) : NULL;
    if (!current || current->state != IMAGE_ALLOCATED) return error(context, R4VIDEO_ERROR_DECODE);
    struct r4video_nvdec_picture p = {0};
    int rc = sequence(context, &p.sequence);
    if (!rc && (FIELD_PICTURE(h) || h->short_ref_count > 16 || !pps->ref_count[0] || !pps->ref_count[1] ||
        h->cur_pic_ptr->field_poc[0] == INT_MAX || h->cur_pic_ptr->field_poc[1] == INT_MAX)) rc = R4VIDEO_ERROR_UNSUPPORTED;
    if (rc) { abort_image(current); return error(context, rc); }
    p.entropy_coding = pps->cabac;
    p.bottom_field_poc_present = pps->pic_order_present;
    p.l0_default_minus1 = pps->ref_count[0] - 1;
    p.l1_default_minus1 = pps->ref_count[1] - 1;
    p.deblocking_control = pps->deblocking_filter_parameters_present;
    p.redundant_pic_cnt = pps->redundant_pic_cnt_present;
    p.transform_8x8 = pps->transform_8x8_mode;
    p.weighted_pred = pps->weighted_pred;
    p.constrained_intra_pred = pps->constrained_intra_pred;
    p.weighted_bipred = pps->weighted_bipred_idc;
    p.initial_qp_minus26 = pps->init_qp - 26;
    p.initial_qs_minus26 = pps->init_qs - 26;
    p.chroma_qp_offset = pps->chroma_qp_index_offset[0];
    p.second_chroma_qp_offset = pps->chroma_qp_index_offset[1];
    p.frame_num = h->poc.frame_num;
    p.is_reference = h->nal_ref_idc != 0;
    p.poc[0] = h->cur_pic_ptr->field_poc[0];
    p.poc[1] = h->cur_pic_ptr->field_poc[1];
    /* h264_ps.c decode_scaling_list already scatters into raster positions.
     * The two luma 8x8 matrices are entries 0 (intra) and 3 (inter). */
    memcpy(p.scaling4, pps->scaling_matrix4, sizeof(p.scaling4));
    memcpy(p.scaling8[0], pps->scaling_matrix8[0], sizeof(p.scaling8[0]));
    memcpy(p.scaling8[1], pps->scaling_matrix8[3], sizeof(p.scaling8[1]));
    for (unsigned i = 0; !rc && i < h->short_ref_count; i++) {
        if (!h->short_ref[i]) { rc = R4VIDEO_ERROR_DECODE; break; }
        rc = add_reference(&p, current, h->short_ref[i], h->short_ref[i]->frame_num);
    }
    for (unsigned i = 0; !rc && i < 16; i++)
        if (h->long_ref[i]) rc = add_reference(&p, current, h->long_ref[i], i);
    if (!rc) rc = current->ops.begin(current->ops.owner, current->surface, &p);
    if (rc) { abort_image(current); return error(context, rc); }
    current->state = IMAGE_BEGUN;
    return 0;
}

static int slice(AVCodecContext *context, const uint8_t *data, uint32_t bytes)
{
    const H264Context *h = context->priv_data;
    struct image *current = h->cur_pic_ptr ? image(h->cur_pic_ptr->f) : NULL;
    if (!current || current->state != IMAGE_BEGUN) return error(context, R4VIDEO_ERROR_DECODE);
    int rc = current->ops.slice(current->ops.owner, current->surface, data, bytes);
    if (rc) { abort_image(current); return error(context, rc); }
    return 0;
}
static int end(AVCodecContext *context)
{
    const H264Context *h = context->priv_data;
    struct image *current = h->cur_pic_ptr ? image(h->cur_pic_ptr->f) : NULL;
    if (!current || current->state != IMAGE_BEGUN) return error(context, R4VIDEO_ERROR_DECODE);
    int rc = current->ops.end(current->ops.owner, current->surface);
    if (rc) { abort_image(current); return error(context, rc); }
    current->state = IMAGE_COMPLETE;
    return 0;
}
static int init(AVCodecContext *context)
{
    const struct r4video_codec *codec = context->opaque;
    return codec && codec->config.nvdec && context->thread_count == 1 &&
        context->active_thread_type == 0 ? 0 : AVERROR(ENOSYS);
}

int r4video_hw_error(AVCodecContext *context, int result) { return error(context,result); }
int r4video_hw_init(AVCodecContext *context) { return init(context); }
void *r4video_hw_reference(AVCodecContext *context, const AVFrame *frame)
{
    struct image *value=image(frame);
    struct r4video_codec *codec=context->opaque;
    return value && value->state==IMAGE_COMPLETE && value->ops.owner==codec->nvdec.owner ? value->surface : NULL;
}
int r4video_hw_begin(AVCodecContext *context, AVFrame *frame, const struct r4video_nvdec_picture *p)
{
    struct image *value=image(frame);
    if (!value || value->state!=IMAGE_ALLOCATED) return error(context,R4VIDEO_ERROR_DECODE);
    int rc=value->ops.begin(value->ops.owner,value->surface,p);
    if (rc) { abort_image(value); return error(context,rc); }
    value->state=IMAGE_BEGUN;
    return 0;
}
int r4video_hw_slice(AVCodecContext *context, AVFrame *frame, const uint8_t *bytes, uint32_t size)
{
    struct image *value=image(frame);
    if (!value || value->state!=IMAGE_BEGUN) return error(context,R4VIDEO_ERROR_DECODE);
    int rc=value->ops.slice(value->ops.owner,value->surface,bytes,size);
    if (rc) { abort_image(value); return error(context,rc); }
    return 0;
}
int r4video_hw_end(AVCodecContext *context, AVFrame *frame)
{
    struct image *value=image(frame);
    if (!value || value->state!=IMAGE_BEGUN) return error(context,R4VIDEO_ERROR_DECODE);
    int rc=value->ops.end(value->ops.owner,value->surface);
    if (rc) { abort_image(value); return error(context,rc); }
    value->state=IMAGE_COMPLETE;
    return 0;
}

const FFHWAccel ff_h264_r4os_nvdec_hwaccel = {
    .p.name="h264_r4os_nvdec", .p.type=AVMEDIA_TYPE_VIDEO,
    .p.id=AV_CODEC_ID_H264, .p.pix_fmt=AV_PIX_FMT_R4OS_NVDEC,
    .start_frame=start, .decode_slice=slice, .end_frame=end, .init=init,
};
