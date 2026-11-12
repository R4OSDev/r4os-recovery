/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VIDEO_NVDEC_H
#define R4VIDEO_NVDEC_H
#include <stdint.h>
#include "../../R4AMD/Port/vcn_codecs.h"

/* Private codec/worker bridge. No FFmpeg pointers or CPU addresses are exposed
 * through VIDEO_V1. All callbacks run on the single decoder coordinator. */
struct r4video_nvdec_sequence {
    uint32_t profile, level, width_mbs, height_mbs, max_refs;
    uint32_t log2_frame_num, poc_type, log2_poc_lsb;
    uint32_t delta_poc_always_zero, direct_8x8, gaps_allowed;
    /* Zero means legacy H.264/8-bit. Other codecs use exact coded samples. */
    uint32_t codec, bit_depth, width, height;
};
struct r4video_nvdec_reference {
    void *image;
    uint32_t long_term, frame_index;
    int32_t poc[2];
};
struct r4video_nvdec_picture {
    struct r4video_nvdec_sequence sequence;
    uint32_t entropy_coding, bottom_field_poc_present;
    uint32_t l0_default_minus1, l1_default_minus1;
    uint32_t deblocking_control, redundant_pic_cnt, transform_8x8;
    uint32_t weighted_pred, constrained_intra_pred, weighted_bipred;
    int32_t initial_qp_minus26, initial_qs_minus26, chroma_qp_offset, second_chroma_qp_offset;
    uint32_t frame_num, is_reference, reference_count;
    int32_t poc[2];
    /* Fully resolved, raster-order matrices. 8x8 contains intra-Y/inter-Y. */
    uint8_t scaling4[6][16], scaling8[2][64];
    struct r4video_nvdec_reference references[16];
    const void *codec_parameters;
    uint32_t codec_parameter_bytes;
};
struct r4video_nvdec_ops {
    void *owner;
    /* Success transfers one image reference to FFmpeg. An error may return a
     * partial image too; abort and release will retire it. Output starts NULL. */
    int (*allocate)(void *, const struct r4video_nvdec_sequence *, void **image);
    /* begin copies all metadata/references before returning. Reference images
     * are borrowed until end/abort; retain canonical BO/VA loans for GPU work. */
    int (*begin)(void *, void *image, const struct r4video_nvdec_picture *);
    int (*slice)(void *, void *image, const uint8_t *escaped_nal, uint32_t bytes);
    /* Return OK only after successful native queue completion AND provider picture
     * status. This may wait on the worker; it must have a finite deadline. */
    int (*end)(void *, void *image);
    /* Idempotent retirement, also valid after partial allocation/begin/end.
     * Never drop outstanding GPU loans merely because decoding was aborted. */
    void (*abort)(void *, void *image);
    void (*release)(void *, void *image);
};
/* The table is copied at codec_open. Its owner outlives codec_close AND the last
 * received AVFrame released by codec_release. Frame/DPB references may coexist.
 * Results use VIDEO_V1 status codes, never FFmpeg's internal AVERROR values. */
#endif
