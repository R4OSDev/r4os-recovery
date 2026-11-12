/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4VIDEO_CODEC_H
#define R4VIDEO_CODEC_H
#include <stddef.h>
#include <stdint.h>

/* Private worker interface. CPU pointers never cross VIDEO_V1. */
struct r4video_codec;
struct r4video_nvdec_ops;
struct r4video_codec_config {
    uint32_t profile, max_width, max_height, threads;
    uint64_t max_packet_bytes;
    const struct r4video_nvdec_ops *nvdec; /* NULL selects software. */
    uint32_t codec, bit_depth;
};
struct r4video_codec_packet {
    const uint8_t *bytes;
    uint64_t size, tag;
    int64_t pts, dts;
    uint64_t duration;
    uint32_t flags;
};
struct r4video_codec_frame {
    void *image;
    void *hardware_image; /* Borrowed until codec_release; CPU planes are NULL. */
    const uint8_t *data[3];
    uint64_t pitch[3];
    uint32_t width, height, crop_x, crop_y, crop_width, crop_height;
    uint32_t sar_num, sar_den, primaries, transfer, matrix, range, chroma_location;
    uint64_t tag;
    int64_t pts, dts;
    uint64_t duration;
    uint32_t flags;
};
/* Results use VIDEO_V1 values. Only a decoder worker calls these functions;
 * send/receive/drain may execute codec work and must never run in a GUI owner. */
int r4video_codec_open(const struct r4video_codec_config *, struct r4video_codec **);
/* Set before submitting any packet. A codec child can reject admission after
 * receive returned AGAIN; notify wakes the owning coordinator in that case.
 * The callback/context remain alive through codec_close's exact child joins. */
void r4video_codec_set_notify(struct r4video_codec *, void (*)(void *), void *);
int r4video_codec_error(const struct r4video_codec *);
int r4video_codec_send(struct r4video_codec *, const struct r4video_codec_packet *);
int r4video_codec_receive(struct r4video_codec *, struct r4video_codec_frame *);
int r4video_codec_drain(struct r4video_codec *);
void r4video_codec_release(struct r4video_codec_frame *);
void r4video_codec_flush(struct r4video_codec *);
void r4video_codec_close(struct r4video_codec **);
#endif
