/* Copyright 2026 R4. Copyright 2017-2026 Advanced Micro Devices, Inc.
 * SPDX-License-Identifier: Apache-2.0 AND MIT
 * VCN1 common messages/storage adapted from pinned Mesa ac_vcn_dec.c.
 * Codec payload builders below are unchanged original functions. */
#include "vcn_codecs.h"
#include "vcn_parameters.h"
#include "Generated/vcn_payloads.inc"

static uint32_t aligned(uint32_t n, uint32_t a) { return (n+a-1)&~(a-1); }
static uint32_t stream_type(uint32_t c) { return c==2?RDECODE_CODEC_H265:c==3?RDECODE_CODEC_VP9:c==4?RDECODE_CODEC_MPEG2_VLD:RDECODE_CODEC_VC1; }

int r4amd_vcn_plan(const struct r4amd_vcn_sequence *s, struct r4amd_vcn_requirements *out)
{
    if (!s || !out || s->width<16 || s->height<16 || s->width>4096 || s->height>4096 ||
        (s->width|s->height)&1 || (s->depth!=8 && s->depth!=10)) return -2;
    if (s->codec==6) {
        if (s->width<64 || s->height<64 || s->profile || s->depth!=8 || s->refs) return -2;
        *out=(struct r4amd_vcn_requirements){.pitch=aligned(s->width,256),.height=aligned(s->height,16)};
        return 0;
    } else if (s->codec==2) {
        if (s->width<64 || s->height<64 || s->level>186 || s->refs>15 ||
            !((s->profile==1 && s->depth==8) || (s->profile==2 && s->depth==10))) return -2;
    } else if (s->codec==3) {
        if (s->refs!=8 || s->level>62 || !((s->profile==0 && s->depth==8) || (s->profile==2 && s->depth==10))) return -2;
    } else if (s->codec==4) {
        if (s->width<64 || s->height<64 || s->refs!=5 || s->depth!=8 || (s->profile!=4 && s->profile!=5)) return -2;
    } else if (s->codec==5) {
        if (s->width<64 || s->height<64 || s->refs!=4 || s->depth!=8 || s->profile!=3 || s->level>4) return -2;
    } else return -2;
    struct r4amd_vcn_requirements r={0};
    uint32_t w=aligned(s->width,16), h=aligned(s->height,16), count=s->refs+1;
    r.pitch=aligned(w,32); r.height=aligned(h,64);
    r.dpb=aligned(r.pitch*r.height*3/2,1024)*count;
    if (s->codec==2) {
        r.dpb=aligned(r.pitch*r.height*(s->depth==10?9:6)/4,256)*count;
        if (s->depth==10) {
            uint32_t ctbw=(w+63)/64, ctbh=(h+63)/64;
            r.context=count*aligned(ctbw*256,256)*ctbh+24576+2*(((h*8+2047)/2048)*4096+1024);
        } else r.context=((w+255)/16)*((h+255)/16)*16*count+52*1024;
    } else if (s->codec==3) {
        uint32_t cpp=s->depth==10?2:1;
        uint32_t pitch_bytes=aligned(w*cpp,256);
        r.pitch=pitch_bytes/cpp;
        r.uv_height=aligned((h+1)/2,32);
        r.y_size=aligned(pitch_bytes*r.height,65536);
        r.uv_size=aligned(pitch_bytes*r.uv_height,65536);
        r.dpb=(r.y_size+r.uv_size)*count;
        r.context=2304*5+32*2*64*64+9*64*2*64*64+8*2*4096+(s->depth==10?8*2*4096:0);
    } else if (s->codec==5) {
        uint32_t wm=w/16, hm=aligned(h/16,2);
        r.dpb+=wm*hm*128+wm*64+wm*128+aligned((wm>hm?wm:hm)*7*16,64);
    }
    r.session=128*1024+r.context;
    *out=r;
    return 0;
}

int r4amd_vcn_context(const struct r4amd_vcn_sequence *s, void *session, uint32_t bytes)
{
    if (!s || s->codec==6) return -2;
    struct r4amd_vcn_requirements r;
    int rc=r4amd_vcn_plan(s,&r);
    if (rc) return rc;
    if (!session || bytes<r.session) return -1;
    memset(session,0,r.session);
    if (s->codec==3) ac_vcn_vp9_fill_probs_table((uint8_t*)session+128*1024);
    return 0;
}

int r4amd_vcn_create(const struct r4amd_vcn_sequence *s, uint32_t handle, void *embedded)
{
    if (!s || s->codec==6) return -2;
    struct r4amd_vcn_requirements r;
    int rc=r4amd_vcn_plan(s,&r);
    if (rc) return rc;
    if (!embedded || !handle) return -1;
    memset(embedded,0,R4AMD_VCN_EMBEDDED);
    rvcn_dec_message_header_t *h=embedded;
    rvcn_dec_message_create_t *c=(void*)((uint8_t*)embedded+sizeof(*h));
    *h=(rvcn_dec_message_header_t){.header_size=sizeof(*h),.total_size=sizeof(*h)+sizeof(*c),
        .num_buffers=1,.msg_type=RDECODE_MSG_CREATE,.stream_handle=handle,
        .index={{.message_id=RDECODE_MESSAGE_CREATE,.offset=sizeof(*h),.size=sizeof(*c)}}};
    *c=(rvcn_dec_message_create_t){.stream_type=stream_type(s->codec),.width_in_samples=s->width,.height_in_samples=s->height};
    return 0;
}

static int remap(uint32_t *id, const uint32_t *slots, uint32_t count)
{
    if (*id==255) return 0;
    if (*id>=count) return -1;
    *id=slots[*id]; return 0;
}

int r4amd_vcn_message(const struct r4amd_vcn_sequence *s, const struct r4amd_vcn_target *t,
    const void *parameters, uint32_t parameter_bytes, const uint32_t *slots, uint32_t refs,
    uint32_t current, uint32_t handle, uint32_t serial, uint32_t bsd, void *embedded)
{
    if (!s || s->codec==6) return -2;
    struct r4amd_vcn_requirements r;
    int rc=r4amd_vcn_plan(s,&r);
    if (rc) return rc;
    uint32_t cpp=s->depth==10?2:1;
    if (!t || !parameters || parameter_bytes!=sizeof(union r4amd_vcn_parameters) ||
        !embedded || !handle || !serial || refs>s->refs || current>s->refs || (refs && !slots) ||
        !bsd || bsd>8*1024*1024 || bsd%128 || t->pitch%256 || t->pitch<s->width*cpp ||
        t->chroma_offset%65536 || t->chroma_offset<(uint64_t)t->pitch*s->height ||
        t->bytes<(uint64_t)t->chroma_offset+(uint64_t)t->pitch*((s->height+1)/2)) return -1;
    uint32_t used=1u<<current;
    for (uint32_t i=0;i<refs;i++) {
        if (slots[i]>s->refs || (used&(1u<<slots[i]))) return -1;
        used|=1u<<slots[i];
    }
    struct ac_video_dec_decode_cmd cmd={.decode_surface={s->depth==8?PIPE_FORMAT_NV12:2}};
    memcpy(&cmd.codec_param,parameters,sizeof(cmd.codec_param));
    if (s->codec==2) {
        struct ac_video_dec_hevc *h=&cmd.codec_param.hevc;
        if (h->sps_max_dec_pic_buffering_minus1!=s->refs || h->chroma_format_idc!=1 ||
            h->bit_depth_luma_minus8!=s->depth-8 || h->bit_depth_chroma_minus8!=s->depth-8 ||
            h->num_tile_columns_minus1>18 || h->num_tile_rows_minus1>20) return -1;
        h->curr_pic_id=current;
        for (unsigned i=0;i<15;i++) {
            if (remap(&h->ref_pic_id_list[i],slots,refs)) return -1;
            if (h->ref_pic_id_list[i]==255) h->ref_pic_id_list[i]=127;
        }
        for (unsigned i=0;i<8;i++)
            if ((h->ref_pic_set_st_curr_before[i]!=255 && h->ref_pic_set_st_curr_before[i]>=refs) ||
                (h->ref_pic_set_st_curr_after[i]!=255 && h->ref_pic_set_st_curr_after[i]>=refs) ||
                (h->ref_pic_set_lt_curr[i]!=255 && h->ref_pic_set_lt_curr[i]>=refs)) return -1;
    } else if (s->codec==3) {
        struct ac_video_dec_vp9 *v=&cmd.codec_param.vp9;
        if (v->bit_depth_luma_minus8!=s->depth-8 || v->bit_depth_chroma_minus8!=s->depth-8 ||
            v->loop_filter.loop_filter_level>63 || v->log2_tile_cols>6 || v->log2_tile_rows>2) return -1;
        v->cur_id=current;
        for (unsigned i=0;i<8;i++) {
            if (remap(&v->ref_frame_id_list[i],slots,refs)) return -1;
            if (v->ref_frame_id_list[i]==255) v->ref_frame_id_list[i]=127;
        }
        for (unsigned i=0;i<3;i++) {
            if (v->ref_frames[i]>=8) return -1;
            v->ref_frames[i]=v->ref_frame_id_list[v->ref_frames[i]];
        }
    }
    memset(embedded,0,R4AMD_VCN_EMBEDDED);
    uint8_t *b=embedded;
    rvcn_dec_message_header_t *h=embedded;
    rvcn_dec_message_index_t *ix=(void*)(b+sizeof(*h));
    rvcn_dec_message_index_t *dynamic_ix=s->codec==3?ix+1:NULL;
    uint32_t at=sizeof(*h)+sizeof(*ix)+(dynamic_ix?sizeof(*ix):0);
    rvcn_dec_message_decode_t *d=(void*)(b+at);
    h->header_size=sizeof(*h); h->num_buffers=dynamic_ix?3:2; h->msg_type=RDECODE_MSG_DECODE;
    h->stream_handle=handle; h->status_report_feedback_number=serial;
    h->index[0]=(rvcn_dec_message_index_t){.message_id=RDECODE_MESSAGE_DECODE,.offset=at,.size=sizeof(*d)};
    at+=sizeof(*d);
    if (dynamic_ix) {
        rvcn_dec_message_dynamic_dpb_t *dpb=(void*)(b+at);
        *dynamic_ix=(rvcn_dec_message_index_t){.message_id=RDECODE_MESSAGE_DYNAMIC_DPB,.offset=at,.size=sizeof(*dpb)};
        dpb->dpbArraySize=s->refs+1; dpb->dpbLumaPitch=r.pitch;
        dpb->dpbLumaAlignedHeight=r.height; dpb->dpbLumaAlignedSize=r.y_size;
        dpb->dpbChromaPitch=r.pitch/2; dpb->dpbChromaAlignedHeight=r.uv_height;
        dpb->dpbChromaAlignedSize=r.uv_size; dpb->dpbReserved0[0]=32;
        d->decode_flags=RDECODE_FLAGS_USE_DYNAMIC_DPB_MASK|RDECODE_FLAGS_USE_PAL_MASK;
        at+=sizeof(*dpb);
    }
    ix->offset=at;
    struct cmd_buffer cb={.it_probs_ptr=b+R4AMD_VCN_ITS};
    switch (s->codec) {
    case 2: ix->message_id=RDECODE_MESSAGE_HEVC; ix->size=build_hevc_msg(&cb,&cmd,(void*)(b+at)); break;
    case 3: ix->message_id=RDECODE_MESSAGE_VP9; ix->size=build_vp9_msg(&cb,&cmd,(void*)(b+at)); break;
    case 4: ix->message_id=RDECODE_MESSAGE_MPEG2_VLD; ix->size=build_mpeg2_msg(&cb,&cmd,(void*)(b+at)); break;
    case 5: ix->message_id=RDECODE_MESSAGE_VC1; ix->size=build_vc1_msg(&cb,&cmd,(void*)(b+at)); break;
    default: return -2;
    }
    if (!ix->size || at+ix->size>R4AMD_VCN_ITS) return -1;
    h->total_size=at+ix->size;
    d->stream_type=stream_type(s->codec);
    d->width_in_samples=s->codec==5 && s->profile<2?(s->width+15)/16:s->width;
    d->height_in_samples=s->codec==5 && s->profile<2?(s->height+15)/16:s->height;
    d->bsd_size=bsd; d->dpb_size=r.dpb; d->dt_size=t->bytes;
    d->hw_ctxt_size=r.context; d->sw_ctxt_size=128*1024;
    d->decode_buffer_flags=0x1f|(r.context?0x800:0)|(s->codec==2?0x200:0)|(s->codec==3?0x1000:0);
    d->db_pitch=r.pitch; d->db_pitch_uv=s->codec==3?r.pitch/2:aligned(s->width/2,32);
    d->db_aligned_height=r.height;
    d->dt_pitch=t->pitch/cpp; d->dt_uv_pitch=t->pitch/(cpp*2); d->dt_chroma_top_offset=t->chroma_offset;
    uint32_t *feedback=(void*)(b+R4AMD_VCN_FEEDBACK);
    feedback[0]=feedback[1]=sizeof(rvcn_dec_feedback_header_t);
    feedback[3]=~serial; feedback[4]=feedback[6]=UINT32_MAX;
    return 0;
}
_Static_assert(sizeof(union r4amd_vcn_parameters)<=4096,"bounded private picture metadata");
_Static_assert(sizeof(rvcn_dec_hevc_its_t)<=R4AMD_VCN_FEEDBACK-R4AMD_VCN_ITS,"HEVC ITS capacity");
_Static_assert(sizeof(rvcn_dec_vp9_probs_segment_t)<=R4AMD_VCN_FEEDBACK-R4AMD_VCN_ITS,"VP9 probabilities capacity");

/* Mesa 26.2.2 vcn_jpeg_build_decode_cmd, VCN1 / linear NV12 specialization.
 * JPEG1 has no firmware session or decode-feedback message. Its packet waits,
 * error interrupts and the driver's exact completion fence establish status. */
int r4amd_vcn_jpeg(const struct r4amd_vcn_sequence *s, const struct r4amd_vcn_target *t,
    uint64_t input, uint32_t bytes, uint64_t target, uint32_t out[128])
{
    struct r4amd_vcn_requirements r;
    if (!s || s->codec!=6 || !t || !out || r4amd_vcn_plan(s,&r)) return -2;
    const uint64_t limit=UINT64_C(1)<<40;
    if (!input || !target || (input|target)&255 || !bytes || bytes>8*1024*1024 || bytes&127 ||
        input>limit-bytes || !t->bytes || target>limit-t->bytes || t->pitch<r.pitch || t->pitch&255 ||
        (uint64_t)t->pitch*r.height>t->chroma_offset || t->chroma_offset&255 ||
        t->chroma_offset>=t->bytes || (uint64_t)t->pitch*aligned(s->height/2,16)>t->bytes-t->chroma_offset ||
        (input<target+t->bytes && target<input+bytes)) return -1;
    unsigned n=0;
#define J(reg,type,value) do { out[n++]=RDECODE_PKTJ(SOC15_REG_ADDR(mmUVD_##reg),0,type); out[n++]=(uint32_t)(value); } while (0)
    J(JPEG_CNTL,0,1);
    J(CTX_INDEX,0,0x01c2); J(CTX_DATA,0,0x01400200);
    J(CTX_INDEX,0,0x01c3); J(CTX_DATA,0,1<<9); J(SOFT_RESET,3,1<<9);
    J(JPEG_CNTL,0,0);
    J(CTX_INDEX,0,0x01c3); J(CTX_DATA,0,0); J(SOFT_RESET,3,1<<9);
    J(LMI_JPEG_READ_64BIT_BAR_HIGH,0,input>>32); J(LMI_JPEG_READ_64BIT_BAR_LOW,0,input);
    J(JPEG_RB_BASE,0,0); J(JPEG_RB_SIZE,0,0xfffffff0); J(JPEG_RB_WPTR,0,bytes>>2);
    J(JPEG_PITCH,0,t->pitch>>4); J(JPEG_UV_PITCH,0,t->pitch>>4);
    J(JPEG_TILING_CTRL,0,0); J(JPEG_UV_TILING_CTRL,0,0);
    J(LMI_JPEG_WRITE_64BIT_BAR_HIGH,0,target>>32); J(LMI_JPEG_WRITE_64BIT_BAR_LOW,0,target);
    J(JPEG_INDEX,0,0); J(JPEG_DATA,0,0); J(JPEG_INDEX,0,1); J(JPEG_DATA,0,t->chroma_offset);
    J(JPEG_TIER_CNTL2,3,0); J(JPEG_OUTBUF_RPTR,0,0); J(JPEG_INT_EN,0,0xfffffffe);
    J(JPEG_CNTL,0,6);
    J(CTX_INDEX,0,0x01c3); J(CTX_DATA,0,bytes>>2); J(CTX_INDEX,0,0x01c2); J(CTX_DATA,0,0x01400200);
    J(JPEG_RB_RPTR,3,0xffffffff); J(CTX_INDEX,0,0x01c3); J(CTX_DATA,0,0xffffffff); J(JPEG_OUTBUF_WPTR,3,1);
    J(JPEG_CNTL,0,4); J(CTX_INDEX,0,5); J(CTX_DATA,0,(1<<23)|1); J(CTX_DATA,1,0);
    J(JPEG_CNTL,0,1); J(CTX_INDEX,0,0x01c3); J(CTX_DATA,0,1<<9); J(SOFT_RESET,3,1<<9);
    J(JPEG_CNTL,0,0); J(CTX_INDEX,0,0x01c3); J(CTX_DATA,0,0); J(SOFT_RESET,3,1<<9);
    J(CTX_INDEX,0,5); J(CTX_DATA,0,0);
#undef J
    while (n<128) { out[n++]=RDECODE_PKTJ(0,0,6); out[n++]=0; }
    return 0;
}
