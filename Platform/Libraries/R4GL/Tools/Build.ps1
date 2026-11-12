# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputRoot, [switch]$Offline, [ValidateRange(1,32)][int]$Jobs = 4)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. ([IO.Path]::GetFullPath('../../Shared/Native/SDK.ps1',$PSScriptRoot))
. (Join-Path $PSScriptRoot 'Common.ps1')
$paths = Get-R4GLPaths
$output = [IO.Path]::GetFullPath($OutputRoot, $paths.workspace)
if ($output -eq $paths.cache -or $output.StartsWith($paths.cache + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Published archives must be outside the native build cache.' }
$options = @('-Jobs', [string]$Jobs)
if ($Offline) { $options += '-Offline' }
Invoke-R4GLScript (Join-Path $PSScriptRoot 'BuildNative.ps1') $options
$native = Join-Path $paths.cache 'C'
[IO.Directory]::CreateDirectory($output) | Out-Null
$archives = @(foreach ($relative in @('R4GL-C.a', 'Math/R4NativeMath.a', 'Scan/R4NativeScan.a')) {
    $source = Join-Path $native $relative
    $destination = Join-Path $output ([IO.Path]::GetFileName($relative))
    $hash = Get-R4GLHash $source
    if (!(Test-Path -LiteralPath $destination) -or (Get-R4GLHash $destination) -ne $hash) { Copy-Item -LiteralPath $source -Destination $destination -Force }
    [ordered]@{path = [IO.Path]::GetFileName($relative); sha256 = $hash}
})
$record = Join-Path $native 'native.json'
[ordered]@{schema = 1; native_identity = (Get-Content -Raw -LiteralPath $record | ConvertFrom-Json).identity;
    native_record_sha256 = (Get-R4GLHash $record); archives = $archives} |
    ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $output 'archives.json') -Encoding utf8NoBOM
Write-Host "Native R4GL archives ready: $output"
