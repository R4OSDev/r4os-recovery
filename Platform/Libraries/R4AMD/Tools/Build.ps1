# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param([string]$OutputRoot)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. ([IO.Path]::GetFullPath('../../Shared/Native/SDK.ps1',$PSScriptRoot))
$unit = [IO.Path]::GetFullPath('..', $PSScriptRoot)
$libraries = [IO.Path]::GetFullPath('..', $unit)
& (Join-Path $PSScriptRoot 'Shaders.ps1')
& (Join-Path $libraries 'Shared/Native/BuildPortability.ps1') -UnitRoot $unit
$settings = @{}
foreach ($line in Get-Content (Join-Path $libraries 'Settings.R4S')) {
    if ($line -match '^([A-Z_]+)=(.+)$') { $settings[$Matches[1]] = $Matches[2] }
}
$workspace = [IO.Path]::GetFullPath($settings.WORKSPACE_ROOT.Replace('\','/'), $libraries)
$artifacts = [IO.Path]::GetFullPath($settings.ARTIFACTS_ROOT.Replace('\','/'), $workspace)
$hostName = if ($IsWindows) { 'Windows-x64' } else { 'Linux-x64' }
$native = Join-Path $artifacts "Native/R4AMD/$hostName/AddrLib-26.2.2"
$record = Get-Content -Raw (Join-Path $native 'portability.json') | ConvertFrom-Json
if ($record.objects.Count -ne 19) { throw 'Incomplete image/render object closure.' }
$output = if ($OutputRoot) { [IO.Path]::GetFullPath($OutputRoot, $workspace) } else { Join-Path $native 'Archives' }
[IO.Directory]::CreateDirectory($output) | Out-Null
$ar = (Get-Command $(if ($IsWindows) { 'llvm-ar.exe' } else { ('llvm-ar-'+$script:R4SdkNative.data.Tools.tools.graphics.clang.Split('.')[0]) }) -CommandType Application | Select-Object -First 1).Source
$nm = (Get-Command $(if ($IsWindows) { 'llvm-nm.exe' } else { ('llvm-nm-'+$script:R4SdkNative.data.Tools.tools.graphics.clang.Split('.')[0]) }) -CommandType Application | Select-Object -First 1).Source
$objects = @($record.objects | ForEach-Object { Join-Path $native $_.object })
function Archive([string]$Name, [string[]]$Files) {
    $path = Join-Path $output $Name
    # Replace the archive: removed objects may never survive an incremental ar.
    [IO.File]::Delete($path)
    $response = Join-Path $output ($Name + '.rsp')
    [IO.File]::WriteAllLines($response, @(@('rcsD', $path) + $Files | ForEach-Object { '"' + $_.Replace('\','\\').Replace('"','\"') + '"' }), [Text.UTF8Encoding]::new($false))
    & $ar ('@' + $response)
    if ($LASTEXITCODE) { throw "Native archive failed: $Name" }
}
Archive 'R4AMD-Addr.a' $objects
Copy-Item (Join-Path $native 'Generated/amdgfx9regs.h') (Join-Path $output 'amdgfx9regs.h') -Force
if ($IsWindows) {
    $clang = (Get-Command 'clang.exe' -CommandType Application | Select-Object -First 1).Source
    $hostObjects = @(foreach ($object in $record.objects) {
        $arguments = [Collections.Generic.List[string]]::new()
        foreach ($argument in $object.compiler_arguments) { $arguments.Add([string]$argument) }
        $target = $arguments.IndexOf('-target'); $destination = $arguments.IndexOf('-o')
        $dependency = $arguments.IndexOf('-MF')
        if ($target -lt 0 -or $destination -lt 0 -or $dependency -lt 0) { throw 'Incomplete compiler arguments.' }
        $path = Join-Path $output ($object.name + '.obj')
        $arguments[$target+1] = 'x86_64-w64-windows-gnu'
        $arguments[$destination+1] = $path; $arguments[$dependency+1] = $path + '.d'
        $response = $path + '.rsp'
        [IO.File]::WriteAllLines($response, @($arguments | ForEach-Object { '"' + $_.Replace('\','\\').Replace('"','\"') + '"' }), [Text.UTF8Encoding]::new($false))
        & $clang ('@' + $response)
        if ($LASTEXITCODE) { throw "Windows host AddrLib compilation failed: $($object.name)" }
        $path
    })
    Archive 'R4AMD-Addr-Host.a' $hostObjects
} else {
    Copy-Item (Join-Path $output 'R4AMD-Addr.a') (Join-Path $output 'R4AMD-Addr-Host.a') -Force
}
$symbols = @(& $nm --defined-only (Join-Path $output 'R4AMD-Addr.a'))
if ($LASTEXITCODE) { throw 'Cannot inspect AddrLib archive.' }
foreach ($symbol in @('AddrCreate','AddrDestroy','Addr2ComputeSurfaceInfo','Addr2ComputeSurfaceAddrFromCoord','Addr2ComputeDccInfo','Addr2ComputeHtileInfo','r4amd_addr_compute','r4amd_addr_descriptors','r4amd_native_pipeline','r4amd_native_draw')) {
    if (!($symbols | Where-Object { $_ -match ('\b' + [regex]::Escape($symbol) + '$') })) { throw "Missing linked AddrLib function: $symbol" }
}
$files = @(foreach ($name in @('R4AMD-Addr.a','R4AMD-Addr-Host.a')) { [ordered]@{name=$name; sha256=(Get-FileHash (Join-Path $output $name)).Hash.ToLowerInvariant()} })
[ordered]@{schema=1; module='R4AMD'; upstream='26.2.2'; scope=$record.scope; originals=16; bridge_units=3; native_record_sha256=(Get-FileHash (Join-Path $native 'portability.json')).Hash.ToLowerInvariant(); archives=$files} | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $output 'archives.json') -Encoding utf8NoBOM
Write-Host 'R4AMD: complete 16-original/3-bridge image/render archives for runtime and host checks.'
