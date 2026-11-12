/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#include "codec.h"
#include "codec_internal.h"
#include "hardware_private.h"
#include "r4video.h"
#include "libavcodec/avcodec.h"
#include "libavcodec/h264dec.h"
#include "libavcodec/internal.h"
#include "libavutil/buffer.h"
#include "libavutil/mem.h"
#include <limits.h>
#include <stdatomic.h>
#include <stdio.h>
#include <string.h>

struct packet_identity {
    uint64_t tag;
    int64_t pts, dts;
    uint64_t duration;
    uint32_t flags, reserved;
};
extern int32_t r4native_console_write(const char *, uint32_t);
static void diagnostic(const char *stage, int value, int detail)
{
    char text[128];
    int length = snprintf(text, sizeof(text), "R4VIDEO codec %s value=%d detail=%d\n", stage, value, detail);
    if (length > 0 && (size_t)length < sizeof(text))
        r4native_console_write(text, (uint32_t)length);
}
static int result(struct r4video_codec *codec, int code)
{
    int rejected = atomic_load_explicit(&codec->admission_error, memory_order_acquire);
    if (rejected) {
        diagnostic("admission", rejected, code);
        return rejected;
    }
    if (code >= 0) return R4VIDEO_OK;
    if (code == AVERROR(EAGAIN)) return R4VIDEO_AGAIN;
    if (code == AVERROR_EOF) return R4VIDEO_EOS;
    if (code == AVERROR(ENOMEM)) return R4VIDEO_ERROR_NO_MEMORY;
    if (code == AVERROR_PATCHWELCOME || code == AVERROR(ENOSYS)) return R4VIDEO_ERROR_UNSUPPORTED;
    diagnostic("error", code, 0);
    return R4VIDEO_ERROR_DECODE;
}
void r4video_codec_reject(struct r4video_codec *codec, int error)
{
    atomic_store_explicit(&codec->admission_error, error, memory_order_release);
    if (codec->notify) codec->notify(codec->notify_context);
}
void r4video_codec_set_notify(struct r4video_codec *codec, void (*notify)(void *), void *context)
{
    codec->notify_context = context;
    codec->notify = notify;
}
int r4video_codec_error(const struct r4video_codec *codec)
{
    return atomic_load_explicit(&codec->admission_error, memory_order_acquire);
}
int r4video_codec_admitted(AVCodecContext *context)
{
    struct r4video_codec *codec = context->opaque;
    if (context->codec_id != AV_CODEC_ID_H264) {
        /* Exact sequence/profile admission runs before image allocation. The
         * format callback may run before the parser installs its new PPS. */
        return codec->config.nvdec ? R4VIDEO_OK : R4VIDEO_ERROR_UNSUPPORTED;
    }
    H264Context *h264 = context->priv_data;
    const SPS *sps = h264->ps.sps;
    const PPS *pps = h264->ps.pps;
    if (!sps || !pps) return R4VIDEO_ERROR_DECODE;
    if (sps->profile_idc != (int)codec->config.profile ||
        sps->level_idc > 51 || sps->bit_depth_luma != 8 || sps->bit_depth_chroma != 8 ||
        sps->chroma_format_idc != 1 || !sps->frame_mbs_only_flag ||
        pps->slice_group_count != 1 || sps->ref_frame_count > 16)
        return R4VIDEO_ERROR_UNSUPPORTED;
    if (sps->mb_width <= 0 || sps->mb_height <= 0 ||
        (uint64_t)sps->mb_width * 16 > codec->config.max_width ||
        (uint64_t)sps->mb_height * 16 > codec->config.max_height)
        return R4VIDEO_ERROR_UNSUPPORTED;
    return R4VIDEO_OK;
}
static enum AVPixelFormat format(AVCodecContext *context, const enum AVPixelFormat *formats)
{
    struct r4video_codec *codec = context->opaque;
    int error = r4video_codec_admitted(context);
    if (!error) {
        for (const enum AVPixelFormat *p = formats; *p != AV_PIX_FMT_NONE; ++p)
            if (codec->config.nvdec ? *p == AV_PIX_FMT_R4OS_NVDEC :
                (*p == AV_PIX_FMT_YUV420P || *p == AV_PIX_FMT_YUVJ420P)) return *p;
        error = R4VIDEO_ERROR_UNSUPPORTED;
    }
    r4video_codec_reject(codec, error);
    return AV_PIX_FMT_NONE;
}
static int buffer(AVCodecContext *context, AVFrame *frame, int flags)
{
    struct r4video_codec *codec = context->opaque;
    if (codec->config.nvdec) return r4video_nvdec_buffer(context, frame);
    int error = r4video_codec_admitted(context);
    if (!error && (frame->width <= 0 || frame->height <= 0 ||
        (uint32_t)frame->width > codec->config.max_width || (uint32_t)frame->height > codec->config.max_height ||
        (frame->format != AV_PIX_FMT_YUV420P && frame->format != AV_PIX_FMT_YUVJ420P)))
        error = R4VIDEO_ERROR_UNSUPPORTED;
    if (error) {
        r4video_codec_reject(codec, error);
        return AVERROR(EINVAL);
    }
    return avcodec_default_get_buffer2(context, frame, flags);
}
int r4video_codec_open(const struct r4video_codec_config *config, struct r4video_codec **output)
{
    if (!config || !output || !config->max_width || !config->max_height ||
        config->max_width > 4096 || config->max_height > 4096 || !config->threads || config->threads > 16 ||
        !config->max_packet_bytes || config->max_packet_bytes > INT_MAX - AV_INPUT_BUFFER_PADDING_SIZE)
        return R4VIDEO_ERROR_INVALID;
    uint32_t kind=config->codec?config->codec:R4VIDEO_CODEC_H264;
    if (kind!=R4VIDEO_CODEC_H264 && !config->nvdec) return R4VIDEO_ERROR_UNSUPPORTED;
    if (kind==R4VIDEO_CODEC_H264 && config->profile != R4VIDEO_PROFILE_H264_BASELINE && config->profile != R4VIDEO_PROFILE_H264_MAIN &&
        config->profile != R4VIDEO_PROFILE_H264_HIGH) return R4VIDEO_ERROR_UNSUPPORTED;
    enum AVCodecID codec_id;
    switch (kind) {
    case R4VIDEO_CODEC_H264: codec_id=AV_CODEC_ID_H264; break;
    case R4VIDEO_CODEC_HEVC: codec_id=AV_CODEC_ID_HEVC; break;
    case R4VIDEO_CODEC_VP9: codec_id=AV_CODEC_ID_VP9; break;
    case R4VIDEO_CODEC_MPEG2: codec_id=AV_CODEC_ID_MPEG2VIDEO; break;
    case R4VIDEO_CODEC_VC1:
        if (config->profile!=3) return R4VIDEO_ERROR_UNSUPPORTED;
        codec_id=AV_CODEC_ID_VC1; break;
    case R4VIDEO_CODEC_JPEG: codec_id=AV_CODEC_ID_MJPEG; break;
    default: return R4VIDEO_ERROR_UNSUPPORTED;
    }
    if (config->nvdec && (!config->nvdec->owner || !config->nvdec->allocate || !config->nvdec->begin ||
        !config->nvdec->slice || !config->nvdec->end || !config->nvdec->abort || !config->nvdec->release))
        return R4VIDEO_ERROR_INVALID;
    const AVCodec *implementation = avcodec_find_decoder(codec_id);
    if (!implementation) return R4VIDEO_ERROR_UNSUPPORTED;
    struct r4video_codec *codec = av_mallocz(sizeof(*codec));
    if (!codec) return R4VIDEO_ERROR_NO_MEMORY;
    codec->config = *config;
    codec->config.codec=kind;
    codec->config.bit_depth=config->bit_depth?config->bit_depth:8;
    if (config->nvdec) {
        codec->nvdec = *config->nvdec;
        codec->config.nvdec = &codec->nvdec;
    }
    atomic_init(&codec->admission_error, 0);
    codec->context = avcodec_alloc_context3(implementation);
    if (!codec->context) { av_free(codec); return R4VIDEO_ERROR_NO_MEMORY; }
    AVCodecContext *context = codec->context;
    context->opaque = codec;
    context->thread_count = config->nvdec ? 1 : (int)config->threads;
    context->thread_type = config->nvdec ? 0 : FF_THREAD_FRAME | FF_THREAD_SLICE;
    /* ff_get_buffer checks STRIDE_ALIGN-rounded width before get_buffer2.
     * Keep this storage guard compatible with that exact upstream rule;
     * admitted()/buffer() still enforce the unrounded caller dimensions. */
    context->max_pixels = (int64_t)FFALIGN(config->max_width, STRIDE_ALIGN) * config->max_height;
    context->get_format = format;
    context->get_buffer2 = buffer;
    context->apply_cropping = 0;
    context->flags |= AV_CODEC_FLAG_COPY_OPAQUE;
    context->err_recognition = AV_EF_CRCCHECK | AV_EF_BITSTREAM | AV_EF_BUFFER | AV_EF_EXPLODE;
    /* Software multi-slice decoding consults error_status_table between
     * slices. FFmpeg leaves that table unmaintained when error_concealment
     * is zero, producing FF_DECODE_ERROR_DECODE_SLICES on intact pictures.
     * Keep its software accounting active; EXPLODE and the receive-side
     * decode_error_flags/CORRUPT checks still reject repaired/broken output.
     * Hardware decoding never executes the CPU slice/concealment path. */
    context->error_concealment = config->nvdec ? 0 : FF_EC_GUESS_MVS | FF_EC_DEBLOCK;
    context->pkt_timebase = (AVRational){1, 1000000000};
    /* Advanced VC1 carries the sequence and entry-point headers in its first
     * access unit. Delay the original decoder's extradata-dependent init until
     * that bounded packet is owned by this worker. */
    int opened = codec_id==AV_CODEC_ID_VC1 ? 0 : result(codec, avcodec_open2(context, implementation, NULL));
    if (opened) { avcodec_free_context(&codec->context); av_free(codec); return opened; }
    *output = codec;
    return R4VIDEO_OK;
}
/* Exactly one baseline interleaved 4:2:0 image. Tables remain in the original
 * parser; multi-scan/progressive/extended JPEG and concatenated images have no
 * native claim. Do this before FFmpeg can start the JPEG hardware callback. */
static int jpeg_packet(const uint8_t *p, size_t size)
{
    if (size<4 || p[0]!=0xff || p[1]!=0xd8) return R4VIDEO_ERROR_DECODE;
    size_t at=2;
    int sof=0;
    while (at<size) {
        if (p[at++]!=0xff) return R4VIDEO_ERROR_DECODE;
        while (at<size && p[at]==0xff) at++;
        if (at>=size) return R4VIDEO_ERROR_DECODE;
        const unsigned marker=p[at++];
        if (at+2>size) return R4VIDEO_ERROR_DECODE;
        const size_t n=(size_t)p[at]*256+p[at+1];
        if (n<2 || n>size-at) return R4VIDEO_ERROR_DECODE;
        if (marker==0xc0) {
            if (sof || n!=17 || p[at+2]!=8 || p[at+7]!=3 || p[at+9]!=0x22 || p[at+12]!=0x11 || p[at+15]!=0x11)
                return R4VIDEO_ERROR_UNSUPPORTED;
            sof=1;
        } else if (marker==0xda) {
            if (!sof || n!=12 || p[at+2]!=3 || p[at+9]!=0 || p[at+10]!=63 || p[at+11]!=0)
                return R4VIDEO_ERROR_UNSUPPORTED;
            at+=n;
            while (at<size) {
                if (p[at++]!=0xff) continue;
                while (at<size && p[at]==0xff) at++;
                if (at>=size) break;
                unsigned code=p[at++];
                if (!code || (code>=0xd0 && code<=0xd7)) continue;
                return code==0xd9 && at==size?0:R4VIDEO_ERROR_UNSUPPORTED;
            }
            return R4VIDEO_ERROR_DECODE;
        } else if (marker!=0xc4 && marker!=0xdb && marker!=0xdd && marker!=0xfe && (marker<0xe0 || marker>0xef))
            return R4VIDEO_ERROR_UNSUPPORTED;
        at+=n;
    }
    return R4VIDEO_ERROR_DECODE;
}
int r4video_codec_send(struct r4video_codec *codec, const struct r4video_codec_packet *input)
{
    if (!codec || !input || !input->bytes || !input->size || input->size > codec->config.max_packet_bytes ||
        input->size > UINTPTR_MAX - (uintptr_t)input->bytes ||
        input->flags & ~(R4VIDEO_PACKET_PTS | R4VIDEO_PACKET_DTS | R4VIDEO_PACKET_DURATION))
        return R4VIDEO_ERROR_INVALID;
    if (codec->config.codec==R4VIDEO_CODEC_JPEG) {
        int rc=jpeg_packet(input->bytes,(size_t)input->size);
        if (rc) return rc;
    }
    if (!avcodec_is_open(codec->context)) {
        if (codec->config.codec!=R4VIDEO_CODEC_VC1) return R4VIDEO_ERROR_DECODE;
        size_t prefix=0;
        int sequence=0, entry=0;
        const size_t limit=input->size<65536?input->size:65536;
        for (size_t i=0;i+4<=limit;i++) if (!input->bytes[i] && !input->bytes[i+1] && input->bytes[i+2]==1) {
            const uint8_t type=input->bytes[i+3];
            if (type==0x0f) sequence=1;
            if (type==0x0e && sequence) entry=1;
            if (type==0x0d) { prefix=i; break; }
        }
        if (!sequence || !entry || prefix<16) return R4VIDEO_ERROR_UNSUPPORTED;
        AVCodecContext *context=codec->context;
        context->extradata=av_mallocz(prefix+AV_INPUT_BUFFER_PADDING_SIZE);
        if (!context->extradata) return R4VIDEO_ERROR_NO_MEMORY;
        memcpy(context->extradata,input->bytes,prefix); context->extradata_size=(int)prefix;
        int rc=result(codec,avcodec_open2(context,avcodec_find_decoder(AV_CODEC_ID_VC1),NULL));
        if (rc) return rc;
    }
    AVPacket *packet = av_packet_alloc();
    if (!packet) return R4VIDEO_ERROR_NO_MEMORY;
    int sent = av_new_packet(packet, (int)input->size);
    if (sent >= 0) {
        memcpy(packet->data, input->bytes, (size_t)input->size);
        packet->opaque_ref = av_buffer_alloc(sizeof(struct packet_identity));
        if (!packet->opaque_ref) sent = AVERROR(ENOMEM);
        else {
            struct packet_identity identity = {.tag=input->tag, .pts=input->pts, .dts=input->dts,
                .duration=input->duration, .flags=input->flags};
            memcpy(packet->opaque_ref->data, &identity, sizeof(identity));
            packet->pts = input->flags & R4VIDEO_PACKET_PTS ? input->pts : AV_NOPTS_VALUE;
            packet->dts = input->flags & R4VIDEO_PACKET_DTS ? input->dts : AV_NOPTS_VALUE;
            packet->duration = input->flags & R4VIDEO_PACKET_DURATION && input->duration <= INT64_MAX ? (int64_t)input->duration : 0;
            sent = avcodec_send_packet(codec->context, packet);
        }
    }
    av_packet_free(&packet);
    return result(codec, sent);
}
int r4video_codec_receive(struct r4video_codec *codec, struct r4video_codec_frame *output)
{
    if (!codec || !output) return R4VIDEO_ERROR_INVALID;
    if (!avcodec_is_open(codec->context)) return R4VIDEO_AGAIN;
    AVFrame *frame = av_frame_alloc();
    if (!frame) return R4VIDEO_ERROR_NO_MEMORY;
    int received = result(codec, avcodec_receive_frame(codec->context, frame));
    if (received) { av_frame_free(&frame); return received; }
    if (frame->decode_error_flags || frame->flags & (AV_FRAME_FLAG_CORRUPT | AV_FRAME_FLAG_INTERLACED) ||
        !frame->opaque_ref || frame->opaque_ref->size != sizeof(struct packet_identity)) {
        diagnostic("frame", frame->decode_error_flags, frame->flags);
        diagnostic("identity", frame->opaque_ref ? (int)frame->opaque_ref->size : -1,
                   (int)sizeof(struct packet_identity));
        av_frame_free(&frame); return R4VIDEO_ERROR_DECODE;
    }
    if ((codec->config.nvdec ? frame->format != AV_PIX_FMT_R4OS_NVDEC :
         (frame->format != AV_PIX_FMT_YUV420P && frame->format != AV_PIX_FMT_YUVJ420P)) ||
        frame->width <= 0 || frame->height <= 0 || (uint32_t)frame->width > codec->config.max_width ||
        (uint32_t)frame->height > codec->config.max_height || frame->crop_left >= (size_t)frame->width ||
        frame->crop_right >= (size_t)frame->width - frame->crop_left || frame->crop_top >= (size_t)frame->height ||
        frame->crop_bottom >= (size_t)frame->height - frame->crop_top) {
        av_frame_free(&frame); return R4VIDEO_ERROR_UNSUPPORTED;
    }
    struct r4video_codec_frame next = {.image=frame, .width=(uint32_t)frame->width, .height=(uint32_t)frame->height,
        .crop_x=(uint32_t)frame->crop_left, .crop_y=(uint32_t)frame->crop_top,
        .crop_width=(uint32_t)(frame->width-frame->crop_left-frame->crop_right),
        .crop_height=(uint32_t)(frame->height-frame->crop_top-frame->crop_bottom),
        .sar_num=frame->sample_aspect_ratio.num > 0 && frame->sample_aspect_ratio.den > 0 ? (uint32_t)frame->sample_aspect_ratio.num : 0,
        .sar_den=frame->sample_aspect_ratio.num > 0 && frame->sample_aspect_ratio.den > 0 ? (uint32_t)frame->sample_aspect_ratio.den : 0,
        .primaries=(uint32_t)frame->color_primaries, .transfer=(uint32_t)frame->color_trc,
        .matrix=(uint32_t)frame->colorspace,
        .range=frame->color_range == AVCOL_RANGE_JPEG ? 1 : frame->color_range == AVCOL_RANGE_MPEG ? 2 : 0,
        .chroma_location=(uint32_t)frame->chroma_location};
    if (codec->config.nvdec) {
        next.hardware_image = r4video_nvdec_image(frame);
        if (!next.hardware_image) { av_frame_free(&frame); return R4VIDEO_ERROR_DECODE; }
    } else for (unsigned p=0; p<3; ++p) {
        uint32_t row_bytes = p ? (next.width+1)/2 : next.width;
        if (!frame->data[p] || frame->linesize[p] <= 0 || (uint32_t)frame->linesize[p] < row_bytes) {
            av_frame_free(&frame); return R4VIDEO_ERROR_DECODE;
        }
        next.data[p] = frame->data[p]; next.pitch[p] = (uint64_t)frame->linesize[p];
    }
    struct packet_identity identity;
    memcpy(&identity, frame->opaque_ref->data, sizeof(identity));
    next.tag=identity.tag; next.pts=identity.pts; next.dts=identity.dts; next.duration=identity.duration;
    next.flags=identity.flags | (frame->flags & AV_FRAME_FLAG_KEY ? R4VIDEO_FRAME_KEY : 0);
    *output = next;
    return R4VIDEO_OK;
}
int r4video_codec_drain(struct r4video_codec *codec)
{ return !codec ? R4VIDEO_ERROR_INVALID : !avcodec_is_open(codec->context) ? R4VIDEO_EOS : result(codec, avcodec_send_packet(codec->context, NULL)); }
void r4video_codec_release(struct r4video_codec_frame *frame)
{
    if (!frame || !frame->image) return;
    AVFrame *image = frame->image;
    av_frame_free(&image);
    memset(frame, 0, sizeof(*frame));
}
void r4video_codec_flush(struct r4video_codec *codec)
{
    if (avcodec_is_open(codec->context)) avcodec_flush_buffers(codec->context);
    atomic_store_explicit(&codec->admission_error, 0, memory_order_relaxed);
}
void r4video_codec_close(struct r4video_codec **owner)
{
    if (!owner || !*owner) return;
    struct r4video_codec *codec = *owner;
    avcodec_free_context(&codec->context);
    av_free(codec);
    *owner = NULL;
}
