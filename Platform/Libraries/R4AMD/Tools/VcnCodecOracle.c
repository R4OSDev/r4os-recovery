/* Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
 * Bounded adapter around the unchanged Mesa JPEG command function extracted
 * by VcnDecodeVectors.ps1. No driver/GPU execution occurs in this oracle. */
#include <assert.h>
#include <stdio.h>
#include <string.h>
#include "vcn_codecs.h"
#include "vcn_parameters.h"
#include "Generated/vcn_wire.h"
#define align(n,a) (((n)+(a)-1)&~((a)-1))
#define ROUND_DOWN_TO(n,a) ((n)&~((a)-1))
enum amd_gfx_level { GFX9=9,GFX12=12 };
enum vcn_version { VCN_1_0_0=0x10000 };
enum { PIPE_FORMAT_NV12=1,PIPE_FORMAT_R8_G8_B8_UNORM,PIPE_FORMAT_R8G8B8A8_UNORM,PIPE_FORMAT_A8R8G8B8_UNORM };
enum { ADDR_SW_LINEAR=0,ADDR_SW_256B_D,ADDR_SW_4KB_D,ADDR_SW_64KB_D,ADDR_SW_4KB_D_X,ADDR_SW_64KB_D_X,ADDR_SW_256KB_S_X,ADDR_SW_256KB_D_X,ADDR_SW_256KB_R_X,ADDR_SW_256B_S,ADDR_SW_4KB_S,ADDR_SW_64KB_S,ADDR_SW_4KB_S_X,ADDR_SW_64KB_S_X,ADDR_SW_64KB_R_X };
enum { ADDR3_LINEAR=0,ADDR3_256B_2D,ADDR3_4KB_2D,ADDR3_64KB_2D,ADDR3_256KB_2D };
struct radeon_surf { unsigned tile_swizzle,blk_w,bpe; struct { struct { unsigned surf_offset,surf_pitch,swizzle_mode; } gfx9; } u; };
struct ac_video_dec { unsigned max_decode_cmd_dw; };
struct ac_video_dec_session_param { unsigned unused; };
struct ac_video_dec_decode_cmd {
 struct { struct { unsigned crop_x,crop_y,crop_width,crop_height; } mjpeg; } codec_param;
 struct { unsigned num_planes,format; struct { struct radeon_surf *surf; uint64_t va; } planes[3]; } decode_surface;
 uint64_t bitstream_va; unsigned bitstream_size; uint32_t *cmd_buffer;
 struct { unsigned cmd_dw; } out;
};
struct ac_cmdbuf { uint32_t *buf; unsigned max_dw,cdw; };
#define ac_cmdbuf_begin(ptr) struct ac_cmdbuf *oracle_cs=(ptr)
#define ac_cmdbuf_emit(value) do { assert(oracle_cs->cdw<oracle_cs->max_dw);oracle_cs->buf[oracle_cs->cdw++]=(value); } while(0)
#define ac_cmdbuf_end() ((void)0)
#include "jpeg_original.inc"
static void jpeg(void)
{
 for (unsigned k=0;k<4;k++) {
  struct r4amd_vcn_sequence seq={.codec=6,.width=k==0?64:k==1?1920:k==2?4096:130,.height=k==2?4096:k==1?1080:64,.depth=8};
  unsigned pitch=align(seq.width,256),uv=align(pitch*align(seq.height,16),65536),bytes=uv+align(pitch*align(seq.height/2,16),65536);
  struct r4amd_vcn_target target={pitch,uv,bytes};
  uint64_t input=UINT64_C(0x5000010000),dest=UINT64_C(0x5010010000);
  uint32_t original[128]={0},actual[128]={0};
  struct ac_vcn_jpeg_decoder value={.base={128},.gfx_level=GFX9,.jpeg_version=0};
  struct ac_vcn_jpeg_decoder *dec=&value;
#include "jpeg_registers.inc"
  struct radeon_surf y={.blk_w=1,.bpe=1,.u.gfx9={0,pitch,0}},chroma={.blk_w=2,.bpe=2,.u.gfx9={uv,pitch/2,0}};
  struct ac_video_dec_decode_cmd cmd={.decode_surface={.num_planes=2,.format=PIPE_FORMAT_NV12,.planes={{&y,dest},{&chroma,dest}}},
   .bitstream_va=input,.bitstream_size=128*(k+1),.cmd_buffer=original};
  assert(!vcn_jpeg_build_decode_cmd(&dec->base,&cmd));
  for (unsigned i=cmd.out.cmd_dw;i<128;i+=2) original[i]=RDECODE_PKTJ(0,0,6);
  assert(!r4amd_vcn_jpeg(&seq,&target,input,cmd.bitstream_size,dest,actual));
  assert(!memcmp(actual,original,sizeof(actual)));
  target.bytes=uv; uint32_t unchanged[128];memcpy(unchanged,actual,sizeof(actual));
  assert(r4amd_vcn_jpeg(&seq,&target,input,128,dest,actual)<0 && !memcmp(actual,unchanged,sizeof(actual)));
 }
}
static void parameters(void)
{
 uint8_t out[R4AMD_VCN_EMBEDDED];
 struct r4amd_vcn_sequence seq={2,1,120,256,128,8,8};
 struct r4amd_vcn_target target={256,65536,131072};
 union r4amd_vcn_parameters params={0};
 params.hevc.sps_max_dec_pic_buffering_minus1=8;params.hevc.chroma_format_idc=1;
 for(unsigned i=0;i<15;i++) params.hevc.ref_pic_id_list[i]=255;
 memset(params.hevc.ref_pic_set_st_curr_before,255,8);memset(params.hevc.ref_pic_set_st_curr_after,255,8);memset(params.hevc.ref_pic_set_lt_curr,255,8);
 params.hevc.ref_pic_id_list[0]=0;params.hevc.ref_pic_id_list[1]=1;params.hevc.ref_pic_set_st_curr_before[0]=0;
 const uint32_t slots[2]={7,2};
 assert(!r4amd_vcn_message(&seq,&target,&params,sizeof(params),slots,2,4,23,19,128,out));
 rvcn_dec_message_index_t *ix=(void*)(out+sizeof(rvcn_dec_message_header_t));
 rvcn_dec_message_hevc_t *h=(void*)(out+ix->offset);
 assert(h->curr_idx==4 && h->ref_pic_list[0]==7 && h->ref_pic_list[1]==2 && h->ref_pic_list[2]==127 && h->ref_pic_set_st_curr_before[0]==0);
 memset(&params,0,sizeof(params));seq.codec=3;seq.profile=0;seq.level=62;
 for(unsigned i=0;i<8;i++) params.vp9.ref_frame_id_list[i]=255;
 params.vp9.ref_frame_id_list[0]=0;params.vp9.ref_frame_id_list[1]=1;params.vp9.ref_frame_id_list[2]=0;
 params.vp9.ref_frames[0]=0;params.vp9.ref_frames[1]=1;params.vp9.ref_frames[2]=2;
 assert(!r4amd_vcn_message(&seq,&target,&params,sizeof(params),slots,2,4,23,20,128,out));
 rvcn_dec_message_vp9_t *v=(void*)(out+ix->offset);
 assert(v->curr_pic_idx==4 && v->ref_frame_map[0]==7 && v->ref_frame_map[1]==2 && v->ref_frame_map[3]==127);
 assert(v->frame_refs[0]==7 && v->frame_refs[1]==2 && v->frame_refs[2]==7);
 struct r4amd_vcn_requirements req;assert(!r4amd_vcn_plan(&seq,&req));
 assert(req.dpb==9*131072 && req.pitch==256 && req.y_size==65536 && req.uv_size==65536);
 seq.depth=10;seq.profile=2;assert(!r4amd_vcn_plan(&seq,&req));assert(req.pitch==256 && req.dpb==9*131072);
 seq.codec=7;assert(r4amd_vcn_plan(&seq,&req)==-2);
}
int main(void) { jpeg();parameters();puts("VCN1 HEVC/VP9 reference remap, NV12/P010 geometry and four original-Mesa JPEG vectors: OK");return 0; }
