/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VIDEO_HARDWARE_PRIVATE_H
#define R4VIDEO_HARDWARE_PRIVATE_H
#include "codec_internal.h"
int r4video_vcn_sequence(AVCodecContext *, struct r4video_nvdec_sequence *);
int r4video_hw_error(AVCodecContext *, int);
int r4video_hw_begin(AVCodecContext *, AVFrame *, const struct r4video_nvdec_picture *);
int r4video_hw_slice(AVCodecContext *, AVFrame *, const uint8_t *, uint32_t);
int r4video_hw_end(AVCodecContext *, AVFrame *);
void *r4video_hw_reference(AVCodecContext *, const AVFrame *);
int r4video_hw_init(AVCodecContext *);
#endif
