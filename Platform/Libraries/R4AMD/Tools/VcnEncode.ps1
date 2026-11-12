# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
param([switch]$Write)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$unit=[IO.Path]::GetFullPath('..',$PSScriptRoot)
$catalog=Get-Content -Raw (Join-Path $unit 'ThirdParty/Sources.json')|ConvertFrom-Json
$root=Join-Path $unit $catalog.original_root
function Original([string]$name){
 $entry=@($catalog.files|Where-Object path -CEQ $name)
 $path=Join-Path $root $name
 if($entry.Count -ne 1 -or (Get-FileHash $path).Hash.ToLowerInvariant() -cne $entry[0].sha256){throw "Unpinned encoder source: $name"}
 [IO.File]::ReadAllText($path).Replace("`r`n","`n")
}
function Block([string]$source,[string]$pattern){
 $m=[regex]::Match($source,$pattern,'Singleline')
 if(!$m.Success){throw "Missing original encoder block: $pattern"};$m.Value
}
$base='src/gallium/drivers/radeonsi/mm/'
$state=Original 'src/gallium/include/pipe/p_video_state.h'
$decls=[Collections.Generic.Dictionary[string,string]]::new()
foreach($m in [regex]::Matches($state,'(?m)^(?:typedef )?(struct|enum) (pipe_[A-Za-z0-9_]+)\s*\{')){
 $begin=$m.Index;$at=$m.Index+$m.Length;$depth=1
 while($depth -gt 0){if($state[$at] -eq '{'){$depth++};if($state[$at] -eq '}'){$depth--};$at++}
 $end=$state.IndexOf(';',$at)+1
 $decls[$m.Groups[2].Value]=$state.Substring($begin,$end-$begin)
}
$names=[Collections.Generic.HashSet[string]]::new()
function Need([string]$name){
 if(!$names.Add($name)){return}
 if(!$decls.ContainsKey($name)){throw "Missing original codec type: $name"}
 foreach($match in [regex]::Matches($decls[$name],'\bpipe_[A-Za-z0-9_]+\b')){
  $dep=$match.Value
  if($dep -cne $name -and $decls.ContainsKey($dep)){Need $dep}
 }
}
foreach($name in @('pipe_h2645_enc_picture_type','pipe_h264_enc_seq_param','pipe_h264_enc_pic_control','pipe_h264_enc_slice_param','pipe_h265_enc_vid_param','pipe_h265_enc_seq_param','pipe_h265_enc_pic_param','pipe_h265_enc_slice_param')){Need $name}
$notice="/* Generated from pinned Mesa 26.2.2; original functions/types retained.`n * Copyright 2009 Younes Manton; 2017-2025 Advanced Micro Devices, Inc.`n * MIT; full original notices/grants in ThirdParty/Mesa26.2.2/Original.`n * Regenerate: Tools/VcnEncode.ps1 -Write. */`n"
$types=$notice+"#ifndef R4AMD_ENCODER_TYPES_H`n#define R4AMD_ENCODER_TYPES_H`n#include <stdint.h>`n#include <stdbool.h>`n"
$types+=([regex]::Matches($state,'(?m)^#define PIPE_[^\n]+')|ForEach-Object Value) -join "`n"
$types+="`n"
foreach($entry in $decls.GetEnumerator()|Sort-Object {$state.IndexOf($_.Value)}){if($names.Contains($entry.Key)){$types+=$entry.Value+"`n"}}
$types+="#endif`n"
$bitdecl=Original ($base+'radeon_bitstream.h')
$bitdecl=($bitdecl -replace '(?m)^#include [^\n]+\n','') -replace '(?m)^void radeon_bs_av1_seq[^\n]+\n',''
$bits=Original ($base+'radeon_bitstream.c');$bits=$bits.Substring(0,$bits.IndexOf('static void radeon_bs_code_leb128')) -replace '(?m)^#include [^\n]+\n',''
$packets=Original ($base+'radeon_vcn_enc_1_2.c');$packets=$packets.Substring(0,$packets.IndexOf('void radeon_enc_1_2_init')) -replace '(?m)^#include [^\n]+\n',''
$commands=Original 'src/amd/common/ac_vcn_enc.c';$commands=$commands.Substring(0,$commands.IndexOf('bool'+"`n"+'ac_vcn_enc_variable_slice_mode_supported')) -replace '(?m)^#include [^\n]+\n',''
$wire=Original 'src/amd/common/ac_vcn_enc.h';$wire=$wire.Replace('#include "amd_family.h"','#include "../../../ThirdParty/Mesa26.2.2/Original/src/amd/common/amd_family.h"')
[void](Original 'src/amd/common/amd_family.h')
$helper=Original ($base+'radeon_vcn_enc.c')
$helper=(Block $helper 'unsigned int radeon_enc_h2645_picture_type\(.*?\n}\n')+"`n"+(Block $helper 'void radeon_enc_dummy\(.*?\n')
$dir=Join-Path $unit 'Port/Generated/Encode'
if($Write){[IO.Directory]::CreateDirectory($dir)|Out-Null}
foreach($item in @(@('metadata.h',$types),@('bitstream.h',($notice+$bitdecl)),@('bitstream.inc',($notice+$bits)),@('packets.inc',($notice+$packets)),@('commands.inc',($notice+$commands)),@('wire.h',($notice+$wire)),@('helpers.inc',($notice+$helper)))){
 $path=Join-Path $dir $item[0]
 if($Write){[IO.File]::WriteAllText($path,$item[1],[Text.UTF8Encoding]::new($false))}
 if(!(Test-Path $path) -or [IO.File]::ReadAllText($path) -cne $item[1]){throw "Encoder generated-source drift: $path"}
}
Write-Host 'VCN1 original command, header and slice-template sources verified.'
