# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param([ValidateSet('check','write')][string]$Mode = 'check', [switch]$UpdateBaseline)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($UpdateBaseline -and $Mode -ne 'write') { throw 'Baseline update requires write.' }
. (Join-Path $PSScriptRoot 'Common.ps1')
$paths = Get-R4VideoPaths
$zig = Join-Path $paths.zig $(if ($IsWindows) { 'zig.exe' } else { 'zig' })
$options = @("--$Mode", '--module-name', 'R4VIDEO', '--export', 'VIDEO_V1:r4video_video_v1:1')
$files = [ordered]@{
    contract = 'Contract/LibraryContract.json'; baseline = 'Contract/LibraryContract.baseline.json'
    'implementation-zig' = 'Contract/Generated/implementation_abi.zig'; 'binding-zig' = 'Bindings/Zig/r4video.zig'
    'binding-c' = 'Bindings/C/r4video.h'; 'fixture-zig' = 'Tests/Generated/contract_conformance.zig'
    'fixture-c' = 'Tests/Generated/contract_conformance.c'; docs = 'Docs/API.md'
}
foreach ($key in $files.Keys) {
    $file = Join-Path $paths.unit $files[$key]
    if ($Mode -eq 'write') { [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($file)) | Out-Null }
    $options += @("--$key", $file)
}
if ($UpdateBaseline) { $options += '--update-baseline' }
Push-Location (Join-Path $paths.sdk 'Tools/R4LContractGen')
try {
    & $zig build run -- @options
    if ($LASTEXITCODE) { throw "R4VIDEO contract generation failed ($LASTEXITCODE)." }
} finally { Pop-Location }
