/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
 * Independent wire vectors compiled against NVIDIA's unmodified MIT headers.
 * Invocation/source hashes: Source/nvdec_h264_vectors.json.
 */
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "nvdec_drv.h"
#include "clc7b0.h"
#include "clc9b0.h"
#include "class/clc56f.h"

#define OFFSET(f) printf("\"" #f "\":%zu,\n", offsetof(nvdec_h264_pic_s, f))
int main(int argc, char **argv) {
    if (argc != 2) return 1;
    FILE *out = fopen(argv[1], "wb");
    if (!out) return 2;
    printf("{\"picture_size\":%zu,\"new_picture_size\":%zu,\"status_size\":%zu,\"slice_error_offset\":%zu,\n",
           sizeof(nvdec_h264_pic_s), sizeof(nvdec_new_h264_pic_s), sizeof(nvdec_status_s), offsetof(nvdec_status_s, slice_header_error_code));
    OFFSET(eos); OFFSET(explicitEOSPresentFlag); OFFSET(stream_len); OFFSET(slice_count);
    OFFSET(mbhist_buffer_size); OFFSET(gptimer_timeout_value);
    OFFSET(log2_max_pic_order_cnt_lsb_minus4); OFFSET(delta_pic_order_always_zero_flag);
    OFFSET(frame_mbs_only_flag); OFFSET(PicWidthInMbs); OFFSET(FrameHeightInMbs);
    OFFSET(entropy_coding_mode_flag); OFFSET(pic_order_present_flag);
    OFFSET(num_ref_idx_l0_active_minus1); OFFSET(num_ref_idx_l1_active_minus1);
    OFFSET(deblocking_filter_control_present_flag); OFFSET(redundant_pic_cnt_present_flag);
    OFFSET(transform_8x8_mode_flag); OFFSET(pitch_luma); OFFSET(pitch_chroma);
    OFFSET(luma_top_offset); OFFSET(luma_bot_offset); OFFSET(luma_frame_offset);
    OFFSET(chroma_top_offset); OFFSET(chroma_bot_offset); OFFSET(chroma_frame_offset);
    OFFSET(HistBufferSize); OFFSET(CurrFieldOrderCnt); OFFSET(dpb); OFFSET(WeightScale);
    OFFSET(WeightScale8x8); OFFSET(displayPara); OFFSET(ssm);
    printf("\"records\":2}\n");
    for (unsigned variant = 0; variant < 2; variant++) {
        nvdec_h264_pic_s p = {0};
        const unsigned char eos[16] = {0,0,1,11,0,0,0,0,0,0,1,11,0,0,0,0};
        memcpy(p.eos, eos, sizeof(eos));
        p.explicitEOSPresentFlag = 1;
        p.stream_len = 1234 + 16; p.slice_count = 3;
        p.mbhist_buffer_size = 512; p.gptimer_timeout_value = 81000000;
        p.log2_max_pic_order_cnt_lsb_minus4 = 12;
        p.delta_pic_order_always_zero_flag = variant;
        p.frame_mbs_only_flag = 1; p.PicWidthInMbs = 4; p.FrameHeightInMbs = 3;
        p.tileFormat = 1; p.gob_height = variant ? 4 : 0;
        p.entropy_coding_mode_flag = 1; p.pic_order_present_flag = 1;
        p.num_ref_idx_l0_active_minus1 = 15; p.num_ref_idx_l1_active_minus1 = 7;
        p.deblocking_filter_control_present_flag = 1;
        p.redundant_pic_cnt_present_flag = 1; p.transform_8x8_mode_flag = 1;
        p.pitch_luma = 128; p.pitch_chroma = 64;
        p.luma_bot_offset = 64; p.chroma_bot_offset = 32; p.HistBufferSize = 12;
        p.direct_8x8_inference_flag = 1; p.weighted_pred_flag = 1;
        p.constrained_intra_pred_flag = 1; p.ref_pic_flag = 1;
        p.log2_max_frame_num_minus4 = 12; p.chroma_format_idc = 1;
        p.pic_order_cnt_type = variant;
        p.pic_init_qp_minus26 = variant ? 25 : -26;
        p.chroma_qp_index_offset = variant ? 12 : -12;
        p.second_chroma_qp_index_offset = variant ? -12 : 12;
        p.weighted_bipred_idc = 2; p.CurrPicIdx = 16; p.CurrColIdx = 16; p.frame_num = 65535;
        p.CurrFieldOrderCnt[0] = -2147483647; p.CurrFieldOrderCnt[1] = 2147483646;
        for (unsigned i = 0; i < 16; i++) {
            nvdec_dpb_entry_s *d = &p.dpb[i];
            d->index = i; d->col_idx = i; d->state = 3;
            d->is_long_term = i % 2;
            d->top_field_marking = d->bottom_field_marking = d->is_long_term ? 2 : 1;
            d->FieldOrderCnt[0] = (unsigned)(-100 + (int)i);
            d->FieldOrderCnt[1] = 100 + i;
            d->FrameIdx = d->is_long_term ? (int)i : 65534 - (int)i;
        }
        for (unsigned i = 0; i < sizeof(p.WeightScale); i++) ((unsigned char *)p.WeightScale)[i] = 1 + i;
        for (unsigned i = 0; i < sizeof(p.WeightScale8x8); i++) ((unsigned char *)p.WeightScale8x8)[i] = 255 - i;
        if (fwrite(&p, sizeof(p), 1, out) != 1) return 3;
    }
    const uint32_t methods[] = {
        NVC7B0_VIDEO_DECODER, NVC9B0_VIDEO_DECODER,
        NVC7B0_SET_APPLICATION_ID, NVC7B0_SET_APPLICATION_ID_ID_H264,
        NVC7B0_SET_CONTROL_PARAMS, NVC7B0_SET_CONTROL_PARAMS_CODEC_TYPE_H264,
        NVC7B0_SET_DRV_PIC_SETUP_OFFSET, NVC7B0_SET_IN_BUF_BASE_OFFSET,
        NVC7B0_SET_PICTURE_INDEX, NVC7B0_SET_SLICE_OFFSETS_BUF_OFFSET,
        NVC7B0_SET_COLOC_DATA_OFFSET, NVC7B0_SET_HISTORY_OFFSET,
        NVC7B0_SET_NVDEC_STATUS_OFFSET, NVC7B0_SET_PICTURE_LUMA_OFFSET0,
        NVC7B0_SET_PICTURE_CHROMA_OFFSET0, NVC7B0_H264_SET_MBHIST_BUF_OFFSET,
        NVC7B0_EXECUTE,
    };
    if (fwrite(methods, sizeof(methods), 1, out) != 1) return 4;
    nvdec_status_s s = {0};
    s.mbs_correctly_decoded = 12; s.cycle_count = 54321;
    if (fwrite(&s, sizeof(s), 1, out) != 1) return 5;
    s.mbs_in_error = 1; s.error_status = NVC7B0_DEC_ERROR_H264_DETECTED_VLD_FAILURE;
    s.slice_header_error_code = NVC7B0_H264_VLD_ERR_BITSTREAM_ERROR;
    if (fwrite(&s, sizeof(s), 1, out) != 1) return 6;
    /* NVK rust/video/decode/mod.rs binds the software engine, and
     * nv_push_rs::class_to_subc maps video decoder classes to subchannel4.
     * Preserve earlier picture/method/status offsets; append binding vectors. */
    const uint32_t binding[] = {
        4, NVC56F_SET_OBJECT_ENGINE_SW,
        0x20000000u | (1u << 16) | (4u << 13) | (NVC56F_SET_OBJECT >> 2),
        NVC7B0_VIDEO_DECODER | (NVC56F_SET_OBJECT_ENGINE_SW << 16),
        NVC9B0_VIDEO_DECODER | (NVC56F_SET_OBJECT_ENGINE_SW << 16),
    };
    if (fwrite(binding, sizeof(binding), 1, out) != 1) return 7;
    return fclose(out) ? 8 : 0;
}
