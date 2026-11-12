# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputRoot, [switch]$Offline, [ValidateRange(1,32)][int]$Jobs = 4)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. ([IO.Path]::GetFullPath('../../Shared/Native/SDK.ps1',$PSScriptRoot))
if (!$IsWindows -and !$IsLinux) { throw 'Supported hosts: Windows and Linux.' }
. (Join-Path $PSScriptRoot 'MesaSource.ps1')
$libraries = [IO.Path]::GetFullPath('../..', $PSScriptRoot)
$settings = @{}
foreach ($line in Get-Content -LiteralPath (Join-Path $libraries 'Settings.R4S')) {
    if ($line -match '^([A-Z_]+)=(.+)$') { $settings[$Matches[1]] = $Matches[2] }
}
function Resolve([string]$Base, [string]$Name) {
    [IO.Path]::GetFullPath($settings[$Name].Replace('\', [IO.Path]::DirectorySeparatorChar), $Base)
}
$workspace = Resolve $libraries 'WORKSPACE_ROOT'
$artifacts = Resolve $workspace 'ARTIFACTS_ROOT'
$hostName = if ($IsWindows) { 'Windows-x64' } else { 'Linux-x64' }
$cache = Join-Path $artifacts ('Native/R4VK/' + $hostName)
$output = [IO.Path]::GetFullPath($OutputRoot, $workspace)
if ($output -eq $cache -or $output.StartsWith($cache + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Published archive directory must be outside the native build cache.' }
[IO.Directory]::CreateDirectory($cache) | Out-Null
function Run([string]$Script, [string[]]$Options) {
    & pwsh -NoLogo -NoProfile -File $Script @Options
    if ($LASTEXITCODE) { throw "Native dependency build failed: $Script" }
}
$nakResultPath = Join-Path $cache 'nak-result.json'
$nakOptions = @('-ResultFile', $nakResultPath)
if ($Offline) { $nakOptions += '-Offline' }
Run (Join-Path $libraries 'R4NAK/Tools/Build.ps1') $nakOptions
$nak = Get-Content -Raw -LiteralPath $nakResultPath | ConvertFrom-Json
$compiler = [IO.Path]::GetFullPath($nak.root, $workspace)
if ($nak.schema -ne 1 -or $nak.record_sha256 -ne (Get-R4VKFileHash (Join-Path $compiler 'build.json')) -or
    $nak.archive_sha256 -ne (Get-R4VKFileHash (Join-Path $compiler 'R4NAK.a'))) { throw 'Invalid compiler result record.' }
$mesa = Get-R4VKMesaSource
$prepared = Join-Path $cache 'Mesa'
$shaders = Join-Path $cache 'Shaders'
function VerifyOutputs($Record, [string]$Root) {
    if (!$Record.outputs.Count) { throw "Empty preparation record: $Root" }
    foreach ($entry in $Record.outputs) {
        if ((Get-R4VKFileHash (Join-Path $Root $entry.path)) -ne $entry.sha256) { throw "Prepared output changed: $Root / $($entry.path)" }
    }
}
function PreparationCurrent([string]$Path, [string]$Script) {
    if (!(Test-Path -LiteralPath $Path)) { return $false }
    $record = Get-Content -Raw -LiteralPath $Path | ConvertFrom-Json
    if ($record.source_manifest_sha256 -ne (Get-R4VKFileHash $mesa.manifest_path) -or
        $record.mesa_lock_sha256 -ne (Get-R4VKFileHash $mesa.lock_path) -or
        $record.source_helper_sha256 -ne (Get-R4VKFileHash (Join-Path $PSScriptRoot 'MesaSource.ps1')) -or
        $record.prepare_script_sha256 -ne (Get-R4VKFileHash (Join-Path $PSScriptRoot $Script))) { return $false }
    if ($Script -eq 'Prepare.ps1') {
        if ($record.runtime_patch_sha256 -ne (Get-R4VKFileHash (Join-Path $mesa.unit 'Port/MesaRuntime.patch')) -or
            $record.radv_patch_sha256 -ne (Get-R4VKFileHash (Join-Path $mesa.unit 'Port/MesaRADV.patch')) -or
            $record.amd_prepare_sha256 -ne (Get-R4VKFileHash (Join-Path $PSScriptRoot 'PrepareAMD.ps1')) -or
            $record.shader_tools_lock_sha256 -ne (Get-R4VKFileHash (Join-Path $PSScriptRoot 'ShaderTools.lock.json'))) { return $false }
    } else {
        if ($record.generator_patch_sha256 -ne (Get-R4VKFileHash (Join-Path $mesa.unit 'Port/MesaGenerators.patch')) -or
            $record.shader_tools_lock_sha256 -ne (Get-R4VKFileHash (Join-Path $PSScriptRoot 'ShaderTools.lock.json'))) { return $false }
        foreach ($entry in $record.standalone_inputs) {
            if ((Get-R4VKFileHash (Join-Path $libraries $entry.path)) -ne $entry.sha256) { return $false }
        }
    }
    VerifyOutputs $record ([IO.Path]::GetDirectoryName($Path))
    return $true
}
if (!(PreparationCurrent (Join-Path $prepared 'prepare.json') 'Prepare.ps1')) {
    Run (Join-Path $PSScriptRoot 'Prepare.ps1') @('-OutputRoot', $prepared)
}
if (!(PreparationCurrent (Join-Path $shaders 'shaders.json') 'PrepareShaders.ps1')) {
    Run (Join-Path $PSScriptRoot 'PrepareShaders.ps1') @('-OutputRoot', $shaders, '-Jobs', [string]$Jobs)
}
$nil = Join-Path $cache 'Nil'
Run (Join-Path $PSScriptRoot 'BuildNil.ps1') @('-CompilerRoot', $compiler, '-MesaRoot', $prepared, '-OutputRoot', $nil)
$native = Join-Path $cache 'C'
Run (Join-Path $PSScriptRoot 'BuildNative.ps1') @('-CompilerRoot', $compiler, '-MesaRoot', $prepared, '-ShaderRoot', $shaders, '-OutputRoot', $native, '-Jobs', [string]$Jobs)
[IO.Directory]::CreateDirectory($output) | Out-Null
$archives = @(foreach ($entry in @(@('R4VK-C.a', (Join-Path $native 'R4VK-C.a')),
        @('NAK.a', (Join-Path $compiler 'RustBuild/libnak_rs.a')), @('NIL.a', (Join-Path $nil 'libnil.a')))) {
    $destination = Join-Path $output $entry[0]
    $hash = Get-R4VKFileHash $entry[1]
    if (!(Test-Path -LiteralPath $destination) -or (Get-R4VKFileHash $destination) -ne $hash) {
        Copy-Item -LiteralPath $entry[1] -Destination $destination -Force
    }
    [ordered]@{path = $entry[0]; sha256 = $hash}
})
$nativeRecord = Get-Content -Raw -LiteralPath (Join-Path $native 'native.json') | ConvertFrom-Json
[ordered]@{schema = 1; native_identity = $nativeRecord.identity; compiler_identity = $nak.identity; archives = $archives;
    native_record_sha256 = (Get-R4VKFileHash (Join-Path $native 'native.json'));
    nil_record_sha256 = (Get-R4VKFileHash (Join-Path $nil 'nil.json'))} |
    ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $output 'archives.json') -Encoding utf8NoBOM
Write-Host "Native R4VK archives ready: $output"
