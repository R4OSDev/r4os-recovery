/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0 */
#ifndef R4AMD_VCN_PARAMETERS_H
#define R4AMD_VCN_PARAMETERS_H
#include "Generated/vcn_metadata.h"
union r4amd_vcn_parameters {
    struct ac_video_dec_hevc hevc;
    struct ac_video_dec_vp9 vp9;
    struct ac_video_dec_mpeg2 mpeg2;
    struct ac_video_dec_vc1 vc1;
};
#endif
