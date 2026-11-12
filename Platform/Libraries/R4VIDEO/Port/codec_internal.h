/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VIDEO_CODEC_INTERNAL_H
#define R4VIDEO_CODEC_INTERNAL_H
#include "codec.h"
#include "nvdec.h"
#include "libavcodec/avcodec.h"
#include <stdatomic.h>
struct r4video_codec {
    AVCodecContext *context;
    struct r4video_codec_config config;
    atomic_int admission_error;
    void (*notify)(void *);
    void *notify_context;
    struct r4video_nvdec_ops nvdec;
};
int r4video_codec_admitted(AVCodecContext *);
void r4video_codec_reject(struct r4video_codec *, int error);
int r4video_nvdec_buffer(AVCodecContext *, AVFrame *);
void *r4video_nvdec_image(const AVFrame *);
#endif
