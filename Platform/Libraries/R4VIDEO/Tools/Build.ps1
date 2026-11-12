# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputRoot, [switch]$Offline)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'Common.ps1')
$options = @()
if ($Offline) { $options += '-Offline' }
& pwsh -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'BuildNative.ps1') @options
if ($LASTEXITCODE) { throw 'R4VIDEO native build failed.' }
$paths = Get-R4VideoPaths
[IO.Directory]::CreateDirectory($OutputRoot) | Out-Null
foreach ($entry in @(@('R4VIDEO-FFmpeg.a','R4VIDEO-FFmpeg.a'), @('Math/R4NativeMath.a','R4NativeMath.a'), @('Scan/R4NativeScan.a','R4NativeScan.a'))) {
    Copy-Item -LiteralPath (Join-Path $paths.cache ('C/' + $entry[0])) -Destination (Join-Path $OutputRoot $entry[1]) -Force
}
