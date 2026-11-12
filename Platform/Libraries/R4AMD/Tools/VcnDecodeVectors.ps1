# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
# Regenerate the bounded H.264 oracle with ORIGINAL Mesa C layouts/function.
[CmdletBinding()]
param([switch]$Write)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. ([IO.Path]::GetFullPath('../../Shared/Native/SDK.ps1',$PSScriptRoot))
$unit=[IO.Path]::GetFullPath('..',$PSScriptRoot)
$workspace=[IO.Path]::GetFullPath('../../..',$unit)
$temp=Join-Path $workspace 'Temp/AMD-VcnDecodeVectors'
[IO.Directory]::CreateDirectory($temp)|Out-Null
$original=Join-Path $unit 'ThirdParty/Mesa26.2.2/Original/src/amd/common'
$catalog=Get-Content -Raw (Join-Path $unit 'ThirdParty/Sources.json')|ConvertFrom-Json
foreach($name in @('ac_vcn_dec.c','ac_vcn_dec.h','ac_video_dec.h')) {
 $entry=@($catalog.files|Where-Object path -CEQ ('src/amd/common/'+$name))
 if($entry.Count -ne 1 -or (Get-FileHash (Join-Path $original $name)).Hash.ToLowerInvariant() -cne $entry[0].sha256){throw "Source drift $name"}
}
$header=[IO.File]::ReadAllText((Join-Path $original 'ac_vcn_dec.h'))
$input=[IO.File]::ReadAllText((Join-Path $original 'ac_video_dec.h'))
$implementation=[IO.File]::ReadAllText((Join-Path $original 'ac_vcn_dec.c'))
function Extract([string]$Text,[string]$Pattern){$m=[regex]::Match($Text,$Pattern,'Singleline');if(!$m.Success){throw "Missing original block: $Pattern"};return $m.Value}
$parts=[Collections.Generic.List[string]]::new()
$parts.Add("#include <stdint.h>`n#include <stdio.h>`n#include <string.h>`n#define AC_VIDEO_DEC_TIER2 2")
foreach($line in ($header+$input).Split("`n")){if($line -match '^#define (RDECODE_SPS_INFO_H264_|RDECODE_H264_PROFILE_|H264_)'){$parts.Add($line)}}
$parts.Add((Extract $header 'typedef struct \{\s+unsigned short viewOrderIndex;.*?} radeon_mvcElement_t;'))
foreach($name in @('rvcn_dec_message_index','rvcn_dec_message_header','rvcn_dec_message_create','rvcn_dec_message_decode','rvcn_dec_message_avc','rvcn_dec_avc_its')) {
 $parts.Add((Extract $header ("typedef struct "+$name+"_s \{.*?} "+$name+"_t;")))
}
$parts.Add((Extract $input 'struct ac_video_dec_avc \{.*?\n};'))
$parts.Add('struct cmd_buffer { void *it_probs_ptr; }; struct ac_video_dec_decode_cmd { unsigned tier; struct { struct ac_video_dec_avc avc; } codec_param; };')
$parts.Add((Extract $implementation 'static uint32_t\s+build_avc_msg\(.*?\n}\n'))
$parts.Add(@'
int main(int argc, char **argv) {
 if(argc!=2) return 2;
 FILE *f=fopen(argv[1],"wb"); if(!f) return 3;
 for(unsigned k=0;k<3;k++) {
  unsigned char b[2048]={0};
  rvcn_dec_message_header_t *h=(void*)b;
  rvcn_dec_message_index_t *ix=(void*)(b+sizeof(*h));
  rvcn_dec_message_decode_t *d=(void*)(b+sizeof(*h)+sizeof(*ix));
  rvcn_dec_message_avc_t *codec=(void*)((unsigned char*)d+sizeof(*d));
  struct ac_video_dec_decode_cmd cmd={0};
  struct ac_video_dec_avc *a=&cmd.codec_param.avc;
  struct cmd_buffer cb={.it_probs_ptr=b+1536};
  a->profile_idc=k==0?66:k==1?77:100; a->level_idc=31;
  a->sps_flags.direct_8x8_inference_flag=1; a->sps_flags.frame_mbs_only_flag=1;
  a->sps_flags.delta_pic_order_always_zero_flag=k==1; a->sps_flags.gaps_in_frame_num_value_allowed_flag=k==2;
  a->pps_flags.entropy_coding_mode_flag=k!=0; a->pps_flags.transform_8x8_mode_flag=k==2;
  a->pps_flags.deblocking_filter_control_present_flag=1; a->pps_flags.weighted_pred_flag=k!=0;
  a->pps_flags.weighted_bipred_idc=k; a->pps_flags.bottom_field_pic_order_in_frame_present_flag=1;
  a->pps_flags.redundant_pic_cnt_present_flag=k==0; a->pps_flags.constrained_intra_pred_flag=k==2;
  a->pic_flags.chroma_format_idc=1; a->log2_max_frame_num_minus4=4; a->pic_order_cnt_type=k;
  a->log2_max_pic_order_cnt_lsb_minus4=4; a->max_num_ref_frames=4;
  a->pic_init_qp_minus26=-3; a->pic_init_qs_minus26=2; a->chroma_qp_index_offset=-2; a->second_chroma_qp_index_offset=4;
  a->num_ref_idx_l0_default_active_minus1=1; a->num_ref_idx_l1_default_active_minus1=0;
  a->frame_num=8; a->curr_field_order_cnt[0]=4; a->curr_field_order_cnt[1]=5;
  a->curr_pic_ref_frame_num=2; a->curr_pic_id=2;
  for(unsigned i=0;i<16;i++) a->ref_frame_id_list[i]=255;
  a->ref_frame_id_list[0]=1; a->ref_frame_id_list[1]=0; a->used_for_long_term_ref_flags=2;
  a->used_for_reference_flags=15; a->frame_num_list[0]=7; a->frame_num_list[1]=0;
  a->field_order_cnt_list[0][0]=-2; a->field_order_cnt_list[0][1]=1;
  a->field_order_cnt_list[1][0]=0; a->field_order_cnt_list[1][1]=1;
  for(unsigned i=0;i<96;i++) ((unsigned char*)a->scaling_list_4x4)[i]=i+1;
  for(unsigned i=0;i<128;i++) ((unsigned char*)a->scaling_list_8x8)[i]=i+2;
  unsigned size=build_avc_msg(&cb,&cmd,codec);
  h->header_size=sizeof(*h);h->total_size=(unsigned char*)codec-b+size;h->num_buffers=2;h->msg_type=1;h->stream_handle=51;h->status_report_feedback_number=27;
  h->index[0]=(rvcn_dec_message_index_t){2,(unsigned char*)d-b,sizeof(*d),0};
  *ix=(rvcn_dec_message_index_t){6,(unsigned char*)codec-b,size,0};
  d->stream_type=7;d->width_in_samples=1920;d->height_in_samples=1088;d->bsd_size=128;
  d->dpb_size=15667200;d->dt_size=3342336;d->hw_ctxt_size=7833600;d->sw_ctxt_size=131072;
  d->decode_buffer_flags=0xa1f;d->db_pitch=1920;d->db_aligned_height=1088;d->dt_pitch=2048;d->dt_uv_pitch=1024;d->dt_chroma_top_offset=2228224;d->db_pitch_uv=960;
  // R4OS fresh-completion canaries are deliberate additions, not Mesa output.
  unsigned *feedback=(void*)(b+1792);feedback[0]=44;feedback[1]=44;feedback[3]=~27u;feedback[4]=~0u;feedback[6]=~0u;
  if(fwrite(b,1,sizeof(b),f)!=sizeof(b)) return 4;
 }
 return fclose(f)!=0;
}
'@)
$c=Join-Path $temp 'oracle.c';$exe=Join-Path $temp $(if($IsWindows){'oracle.exe'}else{'oracle'})
[IO.File]::WriteAllText($c,($parts -join "`n"),[Text.UTF8Encoding]::new($false))
$compiler=(Get-Command $(if($IsWindows){'clang.exe'}else{'clang-'+$script:R4SdkNative.data.Tools.tools.graphics.clang.Split('.')[0]}) -CommandType Application -ErrorAction Stop|Select-Object -First 1).Source
Assert-R4SdkNativeCompiler $script:R4SdkNative $compiler
& $compiler -std=c11 -Wall -Wextra -Werror $c -o $exe
if($LASTEXITCODE){throw 'VCN C oracle compilation failed'}
$out=Join-Path $temp 'h264.bin'; & $exe $out
if($LASTEXITCODE){throw 'VCN C oracle execution failed'}
$target=Join-Path $unit 'Source/Generated/vcn_h264.bin'
if($Write){Copy-Item $out $target -Force}
if(!(Test-Path $target) -or (Get-FileHash $out).Hash -ne (Get-FileHash $target).Hash){throw 'VCN H264 vector drift'}
[ordered]@{schema=1;mesa='26.2.2';profiles=@(66,77,100);bytes=(Get-Item $out).Length;sha256=(Get-FileHash $out).Hash.ToLowerInvariant();oracle_sha256=(Get-FileHash $c).Hash.ToLowerInvariant();basis='Original Mesa AVC structs and build_avc_msg; named common fields; R4OS pending feedback canaries'}|ConvertTo-Json|Set-Content (Join-Path $temp 'oracle.json') -Encoding utf8NoBOM
Write-Host 'VCN1 H264: three original-C profile vectors verified.'
# Reuse the same pinned originals for the additional VCN1/JPEG codec checks.
$jpegStart=$implementation.IndexOf('#define RDECODE_JPEG_VER_1')
$jpegEnd=$implementation.IndexOf('static void', $jpegStart)
if($jpegStart -lt 0 -or $jpegEnd -lt 0){throw 'Missing original JPEG command builder'}
[IO.File]::WriteAllText((Join-Path $temp 'jpeg_original.inc'),$implementation.Substring($jpegStart,$jpegEnd-$jpegStart),[Text.UTF8Encoding]::new($false))
$create=$implementation.Substring($implementation.IndexOf('ac_vcn_create_jpeg_decoder('))
$registers=[regex]::Match($create,'if \(dec->jpeg_version == RDECODE_JPEG_VER_1\) \{(.*?)\n   } else','Singleline')
if(!$registers.Success){throw 'Missing original JPEG1 registers'}
[IO.File]::WriteAllText((Join-Path $temp 'jpeg_registers.inc'),$registers.Groups[1].Value,[Text.UTF8Encoding]::new($false))
$exe=Join-Path $temp $(if($IsWindows){'codecs.exe'}else{'codecs'})
& $compiler -std=c11 -Wall -Wextra -Werror -Wno-unused-parameter ('-I'+$temp) ('-I'+(Join-Path $unit 'Port')) (Join-Path $unit 'Tools/VcnCodecOracle.c') (Join-Path $unit 'Port/vcn_codecs.c') -o $exe
if($LASTEXITCODE){throw 'VCN codec oracle compilation failed'}
& $exe
if($LASTEXITCODE){throw 'VCN codec oracle mismatch'}
