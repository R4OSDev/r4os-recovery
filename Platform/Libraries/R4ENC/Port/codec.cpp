// Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
#include "codec.h"
#include "codec_api.h"
#include <stdlib.h>
#include <string.h>
#include <limits.h>

struct r4enc_codec { ISVCEncoder *encoder; uint32_t width, height; };

int r4enc_codec_open(const R4EncConfig *c, r4enc_codec **out) {
    if (!c || !out || c->width < 16 || c->height < 16 || c->width > 4096 || c->height > 4096 ||
        ((c->width | c->height) & 1) || !c->fps_num || !c->fps_den || !c->gop_frames ||
        c->fps_num < c->fps_den || (uint64_t)c->fps_num > (uint64_t)c->fps_den * 120 ||
        c->rate.qp > 51 || c->rate.min_qp > c->rate.qp || c->rate.max_qp < c->rate.qp || c->rate.max_qp > 51)
        return R4ENC_ERROR_INVALID;
    const uint64_t mbs = ((c->width + 15) / 16) * ((c->height + 15) / 16);
    if (mbs > 36864 || mbs * c->fps_num > 983040ull * c->fps_den ||
        c->query.backend != R4ENC_BACKEND_SOFTWARE || c->query.codec != R4ENC_CODEC_H264 ||
        (c->query.profile != R4ENC_PROFILE_DEFAULT && c->query.profile != R4ENC_PROFILE_H264_BASELINE) ||
        c->query.bit_depth != 8 || c->query.chroma != R4ENC_CHROMA_420 ||
        c->rate.mode != R4ENC_RATE_CQP || c->rate.target_bps || c->rate.peak_bps || c->rate.buffer_bits ||
        c->color.bit_depth != 8 || c->color.flags || c->color.primaries > 255 || c->color.transfer > 255 ||
        c->color.matrix > 255 || (c->color.range != 1 && c->color.range != 2) ||
        c->color.chroma_location != R4ENC_CHROMA_UNSPECIFIED)
        return R4ENC_ERROR_UNSUPPORTED;
    *out = nullptr;
    r4enc_codec *codec = static_cast<r4enc_codec *>(calloc(1, sizeof(*codec)));
    if (!codec) return R4ENC_ERROR_NO_MEMORY;
    if (WelsCreateSVCEncoder(&codec->encoder) != 0 || !codec->encoder) {
        r4enc_codec_close(&codec);
        return R4ENC_ERROR_NO_MEMORY;
    }
    int trace = 0;
    if (codec->encoder->SetOption(ENCODER_OPTION_TRACE_LEVEL, &trace) != 0) {
        r4enc_codec_close(&codec); return R4ENC_ERROR_ENCODE;
    }
    SEncParamExt p{};
    if (codec->encoder->GetDefaultParams(&p) != 0) { r4enc_codec_close(&codec); return R4ENC_ERROR_ENCODE; }
    p.iUsageType = CAMERA_VIDEO_REAL_TIME;
    p.iPicWidth = c->width; p.iPicHeight = c->height;
    p.fMaxFrameRate = static_cast<float>(c->fps_num) / c->fps_den;
    p.iRCMode = RC_OFF_MODE;
    p.iTargetBitrate = 0; p.iMaxBitrate = 0;
    p.iTemporalLayerNum = p.iSpatialLayerNum = p.iNumRefFrame = 1;
    p.iMultipleThreadIdc = 1; p.bUseLoadBalancing = false;
    p.iComplexityMode = MEDIUM_COMPLEXITY;
    p.uiIntraPeriod = c->gop_frames;
    p.eSpsPpsIdStrategy = CONSTANT_ID;
    p.bPrefixNalAddingCtrl = p.bEnableSSEI = p.bSimulcastAVC = false;
    p.iPaddingFlag = p.iEntropyCodingModeFlag = 0;
    p.bEnableFrameSkip = false;
    p.iMinQp = c->rate.min_qp; p.iMaxQp = c->rate.max_qp;
    p.bEnableLongTermReference = p.bEnableDenoise = p.bEnableAdaptiveQuant = false;
    p.bEnableBackgroundDetection = p.bEnableSceneChangeDetect = false;
    p.bEnableFrameCroppingFlag = true;
    auto &layer = p.sSpatialLayers[0];
    layer.iVideoWidth = c->width; layer.iVideoHeight = c->height; layer.fFrameRate = p.fMaxFrameRate;
    layer.iSpatialBitrate = layer.iMaxSpatialBitrate = 0;
    layer.uiProfileIdc = PRO_BASELINE; layer.uiLevelIdc = LEVEL_5_1;
    layer.iDLayerQp = c->rate.qp;
    layer.sSliceArgument.uiSliceMode = SM_SINGLE_SLICE;
    layer.sSliceArgument.uiSliceNum = 1;
    layer.bVideoSignalTypePresent = true; layer.uiVideoFormat = 5;
    layer.bFullRange = c->color.range == 1;
    layer.bColorDescriptionPresent = true;
    layer.uiColorPrimaries = c->color.primaries; layer.uiTransferCharacteristics = c->color.transfer;
    layer.uiColorMatrix = c->color.matrix;
    layer.bAspectRatioPresent = true; layer.eAspectRatio = ASP_1x1;
    if (codec->encoder->InitializeExt(&p) != 0) { r4enc_codec_close(&codec); return R4ENC_ERROR_ENCODE; }
    codec->width = c->width; codec->height = c->height;
    *out = codec;
    return R4ENC_OK;
}

int r4enc_codec_encode(r4enc_codec *codec, const uint8_t *const planes[3], const uint64_t pitches[3],
                       int64_t pts, uint32_t force, uint8_t *data, uint64_t capacity,
                       uint64_t *bytes, uint32_t *flags) {
    if (!codec || !planes || !pitches || !data || !capacity || !bytes || !flags || force > 1)
        return R4ENC_ERROR_INVALID;
    SSourcePicture picture{};
    picture.iColorFormat = videoFormatI420;
    picture.iPicWidth = codec->width; picture.iPicHeight = codec->height;
    picture.uiTimeStamp = pts / 1000000;
    for (unsigned i = 0; i < 3; ++i) {
        if (!planes[i] || pitches[i] < (i ? codec->width / 2 : codec->width) || pitches[i] > INT_MAX)
            return R4ENC_ERROR_INVALID;
        picture.pData[i] = const_cast<unsigned char *>(planes[i]);
        picture.iStride[i] = static_cast<int>(pitches[i]);
    }
    if (force && codec->encoder->ForceIntraFrame(true) != 0) return R4ENC_ERROR_ENCODE;
    SFrameBSInfo output{};
    if (codec->encoder->EncodeFrame(&picture, &output) != 0 ||
        (output.eFrameType != videoFrameTypeIDR && output.eFrameType != videoFrameTypeP) ||
        output.iFrameSizeInBytes <= 0 || (uint64_t)output.iFrameSizeInBytes > capacity ||
        output.iLayerNum <= 0 || output.iLayerNum > MAX_LAYER_NUM_OF_FRAME)
        return R4ENC_ERROR_ENCODE;
    uint64_t total = 0;
    bool sps = false, pps = false, slice = false;
    for (int i = 0; i < output.iLayerNum; ++i) {
        const auto &layer = output.sLayerInfo[i];
        if (!layer.pBsBuf || !layer.pNalLengthInByte || layer.iNalCount <= 0 || layer.iNalCount > 128 ||
            layer.uiTemporalId || layer.uiSpatialId || layer.uiQualityId) return R4ENC_ERROR_ENCODE;
        uint64_t offset = 0;
        for (int j = 0; j < layer.iNalCount; ++j) {
            const int count = layer.pNalLengthInByte[j];
            if (count < 5 || (uint64_t)count > capacity - total ||
                total + count > (uint64_t)output.iFrameSizeInBytes) return R4ENC_ERROR_ENCODE;
            const uint8_t *nal = layer.pBsBuf + offset;
            if (nal[0] || nal[1] || nal[2] || nal[3] != 1) return R4ENC_ERROR_ENCODE;
            const uint8_t type = nal[4] & 31;
            sps |= type == 7; pps |= type == 8; slice |= type == 1 || type == 5;
            memcpy(data + total, nal, count);
            total += count; offset += count;
        }
    }
    if (total != (uint64_t)output.iFrameSizeInBytes || !slice ||
        (output.eFrameType == videoFrameTypeIDR && (!sps || !pps))) return R4ENC_ERROR_ENCODE;
    *bytes = total;
    *flags = output.eFrameType == videoFrameTypeIDR ? R4ENC_PACKET_KEY | R4ENC_PACKET_CONFIG : 0;
    return R4ENC_OK;
}

void r4enc_codec_close(r4enc_codec **owner) {
    if (!owner || !*owner) return;
    r4enc_codec *codec = *owner;
    if (codec->encoder) WelsDestroySVCEncoder(codec->encoder);
    free(codec); *owner = nullptr;
}
