# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param([switch]$Write)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$unit = [IO.Path]::GetFullPath('..', $PSScriptRoot)
$catalog = Get-Content -Raw (Join-Path $unit 'ThirdParty/Sources.json') | ConvertFrom-Json
$root = Join-Path $unit $catalog.original_root
function Original([string]$Name) {
    $entry = @($catalog.files | Where-Object path -eq $Name)
    $path = Join-Path $root $Name
    if ($entry.Count -ne 1 -or (Get-FileHash $path).Hash.ToLowerInvariant() -ne $entry[0].sha256) { throw "Unpinned VCN original: $Name" }
    [IO.File]::ReadAllText($path).Replace("`r`n", "`n")
}
function Block([string]$Text, [string]$Pattern) {
    $m = [regex]::Match($Text, $Pattern, 'Singleline')
    if (!$m.Success) { throw "Missing VCN source block: $Pattern" }
    $m.Value
}
$meta = Original 'src/amd/common/ac_video_dec.h'
$wire = Original 'src/amd/common/ac_vcn_dec.h'
$impl = Original 'src/amd/common/ac_vcn_dec.c'
$defaults = Original 'src/amd/common/ac_vcn_vp9_default.h'
$notice = "/* Generated from pinned Mesa 26.2.2. Copyright 2017-2026 Advanced Micro Devices, Inc.`n * SPDX-License-Identifier: MIT. Full originals/grant: ThirdParty/Mesa26.2.2/Original.`n * Regenerate with Tools/VcnCodecs.ps1 -Write. */`n"
$metadata = $notice + "#ifndef R4AMD_VCN_METADATA_H`n#define R4AMD_VCN_METADATA_H`n#include <stdint.h>`n#include <stdbool.h>`n"
$metadata += $meta.Substring($meta.IndexOf('#define H265_'), $meta.IndexOf('#define AV1_') - $meta.IndexOf('#define H265_'))
$metadata += Block $meta 'struct ac_video_dec_mpeg2 \{.*?\n};'
$metadata += "`n" + (Block $meta 'struct ac_video_dec_vc1 \{.*?\n};') + "`n#endif`n"
$raw = $notice + "#include <stdint.h>`n" + $wire.Substring(0, $wire.IndexOf('struct ac_vcn_dec_reg {')).Replace('#include "ac_video_dec.h"', '') + "`n#endif`n"
$payload = $notice + "#include <string.h>`n#include `"vcn_metadata.h`"`n#include `"vcn_wire.h`"`n"
$payload += "#define PIPE_FORMAT_NV12 1`n#define RDECODE_DITHERING_RANDOM 5`n#define CLAMP(v,lo,hi) ((v)<(lo)?(lo):((v)>(hi)?(hi):(v)))`n"
$payload += "struct cmd_buffer { void *it_probs_ptr; };`nstruct ac_video_dec_decode_cmd { struct { unsigned format; } decode_surface; union r4amd_vcn_parameters codec_param; };`n"
foreach ($name in @('hevc','vp9','mpeg2','vc1')) {
    $payload += (Block $impl ("static uint32_t\s+build_" + $name + "_msg\(.*?\n}\n")) + "`n"
}
$payload += $defaults + "`n" + (Block $impl 'static void\s+ac_vcn_vp9_fill_probs_table\(.*?\n}\n')
$directory = Join-Path $unit 'Port/Generated'
if ($Write) { [IO.Directory]::CreateDirectory($directory) | Out-Null }
foreach ($item in @(@('vcn_metadata.h',$metadata), @('vcn_wire.h',$raw), @('vcn_payloads.inc',$payload))) {
    $path = Join-Path $directory $item[0]
    if ($Write) { [IO.File]::WriteAllText($path,$item[1],[Text.UTF8Encoding]::new($false)) }
    if (!(Test-Path $path) -or [IO.File]::ReadAllText($path) -cne $item[1]) { throw "VCN generated-source drift: $path" }
}
Write-Host 'VCN1: original HEVC/VP9/MPEG2/VC1 payload builders and VP9 defaults verified.'
