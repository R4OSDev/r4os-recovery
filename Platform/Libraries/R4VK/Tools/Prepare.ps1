# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputRoot)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. ([IO.Path]::GetFullPath('../../Shared/Native/SDK.ps1',$PSScriptRoot))
if (!$IsWindows -and !$IsLinux) { throw 'Supported hosts: Windows and Linux.' }
. (Join-Path $PSScriptRoot 'MesaSource.ps1')
$mesa = Get-R4VKMesaSource
$unit = $mesa.unit
$workspace = $mesa.workspace
$lockPath = $mesa.lock_path
$lock = $mesa.lock
$source = $mesa.source
$manifestPath = $mesa.manifest_path
$sourceFiles = $mesa.files
function Hash([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Run([string]$Program, [string[]]$Arguments) {
    & $Program @Arguments
    if ($LASTEXITCODE) { throw "$Program failed ($LASTEXITCODE)" }
}
$output = [IO.Path]::GetFullPath($OutputRoot, $workspace)
$sourcePrefix = $source.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
if ($output -eq $source -or $output.StartsWith($sourcePrefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'R4VK generation must not modify the prepared Mesa source.' }
$generated = Join-Path $output 'Generated'
$overlay = Join-Path $output 'CSource'
[IO.Directory]::CreateDirectory($generated) | Out-Null
[IO.Directory]::CreateDirectory($overlay) | Out-Null
# The pinned input is a release archive, not a Git checkout. Do not inherit
# the workspace Git HEAD or a host MESA_GIT_SHA1_OVERRIDE as Mesa's identity.
# Pipeline caches use the separately required full r4vk_build_identity.
[IO.File]::WriteAllText((Join-Path $generated 'git_sha1.h'), '#define MESA_GIT_SHA1 ""' + "`n", [Text.UTF8Encoding]::new($false))
# Quoted includes must resolve one consistent private layout in every C unit.
# Keep NVK and Vulkan runtime headers with their consuming C source files.
foreach ($directory in @('src/nouveau/vulkan', 'src/vulkan/runtime', 'src/vulkan/util', 'src/compiler', 'src/util',
                         'src/amd/vulkan', 'src/amd/common', 'src/amd/compiler', 'src/amd/addrlib')) {
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $source $directory) -File -Recurse | Where-Object Extension -in @('.c', '.h', '.cpp')) {
        $relative = [IO.Path]::GetRelativePath($source, $file.FullName)
        $destination = Join-Path $overlay $relative
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
        Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
    }
}
$patches = @((Join-Path $unit 'Port/MesaRuntime.patch'), (Join-Path $unit 'Port/MesaRADV.patch'))
foreach ($patch in $patches) {
$patchedFiles = @([regex]::Matches([IO.File]::ReadAllText($patch), '(?m)^--- a/(.+)$') | ForEach-Object { $_.Groups[1].Value.TrimEnd("`r") })
foreach ($relative in $patchedFiles) {
    $destination = Join-Path $overlay $relative
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
    Copy-Item -LiteralPath (Join-Path $source $relative) -Destination $destination -Force
}
$git = (Get-Command git -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
Push-Location ([IO.Path]::GetPathRoot($overlay))
try {
    Run $git @('apply', '--unsafe-paths', ('--directory=' + $overlay), '--check', $patch)
    Run $git @('apply', '--unsafe-paths', ('--directory=' + $overlay), $patch)
} finally { Pop-Location }
}

$python = (Get-Command $(if ($IsWindows) { 'python.exe' } else { 'python3' }) -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$cbindgen = (Get-Command cbindgen -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$cbindgenVersion = @(& $cbindgen --version)
if ($LASTEXITCODE -or !$cbindgenVersion.Count -or [string]$cbindgenVersion[0] -notmatch ('(?<![0-9.])' + [regex]::Escape([string]$lock.host_tools.cbindgen) + '(?![0-9.])')) { throw 'Pinned cbindgen version required.' }
$xml = Join-Path $source 'src/vulkan/registry/vk.xml'
function Generate([string]$Script, [string[]]$Options) {
    Run $python (@((Join-Path $source ('src/vulkan/' + $Script)), '--xml', $xml) + $Options)
}
$oldBytecode = [Environment]::GetEnvironmentVariable('PYTHONDONTWRITEBYTECODE', 'Process')
try {
    [Environment]::SetEnvironmentVariable('PYTHONDONTWRITEBYTECODE', '1', 'Process')
    foreach ($kind in @('dispatch_table', 'extensions', 'cmd_queue', 'dispatch_trampolines', 'physical_device_features', 'physical_device_properties')) {
        $options = @('--out-c', (Join-Path $generated "vk_$kind.c"), '--out-h', (Join-Path $generated "vk_$kind.h"))
        if ($kind -ne 'extensions') { $options += @('--beta', 'false') }
        Generate "util/vk_$($kind)_gen.py" $options
    }
    Generate 'util/gen_enum_to_str.py' @('--out-c', (Join-Path $generated 'vk_enum_to_str.c'), '--out-h', (Join-Path $generated 'vk_enum_to_str.h'), '--out-d', (Join-Path $generated 'vk_enum_defines.h'), '--beta', 'false')
    Generate 'util/vk_struct_type_cast_gen.py' @('--out', (Join-Path $generated 'vk_struct_type_cast.h'), '--beta', 'false')
    foreach ($kind in @('physical_device_spirv_caps', 'synchronization_helpers')) {
        Generate "util/vk_$($kind)_gen.py" @('--out-c', (Join-Path $generated "vk_$kind.c"), '--beta', 'false')
    }
    Generate 'runtime/vk_format_info_gen.py' @('--out-c', (Join-Path $generated 'vk_format_info.c'), '--out-h', (Join-Path $generated 'vk_format_info.h'))
    foreach ($prefix in @('nvk', 'vk_common', 'vk_cmd_enqueue')) {
        $options = @('--proto', '--weak', '--out-c', (Join-Path $generated "$($prefix)_entrypoints.c"), '--out-h', (Join-Path $generated "$($prefix)_entrypoints.h"), '--prefix', $prefix, '--beta', 'false')
        if ($prefix -eq 'vk_cmd_enqueue') { $options += @('--prefix', 'vk_cmd_enqueue_unless_primary') }
        Generate 'util/vk_entrypoints_gen.py' $options
        # Preserve weak binding in the final ELF. LLD localizes hidden undefined
        # entrypoints, losing the evidence that their resolved NULL is optional.
        # R4M public exports remain selected exclusively by the module manifest.
        $headerPath = Join-Path $generated "$($prefix)_entrypoints.h"
        $header = [IO.File]::ReadAllText($headerPath).Replace("`r`n", "`n")
        $needle = "#ifndef _WIN32`n#define VK_ENTRY_HIDDEN __attribute__ ((visibility(`"hidden`")))"
        if (!$header.Contains($needle)) { throw 'Pinned entrypoint visibility template changed.' }
        $replacement = "#if defined(R4OS_VULKAN)`n#define VK_ENTRY_HIDDEN __attribute__ ((visibility(`"default`")))`n#elif !defined(_WIN32)`n#define VK_ENTRY_HIDDEN __attribute__ ((visibility(`"hidden`")))"
        [IO.File]::WriteAllText($headerPath, $header.Replace($needle, $replacement), [Text.UTF8Encoding]::new($false))
    }
    Run $python @((Join-Path $source 'src/nouveau/vulkan/nvk_drirc_gen.py'), '--import-path', (Join-Path $source 'src/util'),
        '--drirc-src', (Join-Path $generated 'nvk_drirc.c'), '--drirc-hdr', (Join-Path $generated 'nvk_drirc.h'),
        '--validate', (Join-Path $source 'src/nouveau/vulkan/00-nvk-defaults.conf'))
    $nilSource = Join-Path $source 'src/nouveau/nil'
    Run $python @((Join-Path $nilSource 'nil_format_table_gen.py'), '--csv', (Join-Path $nilSource 'nil_formats.csv'),
        '--out-h', (Join-Path $generated 'nil_format_table.h'), '--out-c', (Join-Path $generated 'nil_format_table.c'))
    Run $cbindgen @('-q', '--config', (Join-Path $nilSource 'cbindgen.toml'), '--lang', 'c', '--output', (Join-Path $generated 'nil.h'), '--', (Join-Path $nilSource 'lib.rs'))
    . (Join-Path $PSScriptRoot 'PrepareAMD.ps1')
    Initialize-R4VKAMD -Mesa $mesa -GeneratedRoot $generated
} finally { [Environment]::SetEnvironmentVariable('PYTHONDONTWRITEBYTECODE', $oldBytecode, 'Process') }
$outputs = @(foreach ($directory in @($generated, $overlay)) {
    Get-ChildItem -LiteralPath $directory -File -Recurse | Sort-Object FullName | ForEach-Object {
        [ordered]@{ path = [IO.Path]::GetRelativePath($output, $_.FullName).Replace('\', '/'); sha256 = (Hash $_.FullName) }
    }
})
[ordered]@{
    schema = 1; mesa = $lock.mesa.version; mesa_lock_sha256 = (Hash $lockPath)
    source_manifest_sha256 = (Hash $manifestPath); source_files_verified = $sourceFiles.Count
    runtime_patch_sha256 = (Hash $patches[0]); radv_patch_sha256 = (Hash $patches[1]); prepare_script_sha256 = (Hash $PSCommandPath)
    amd_prepare_sha256 = (Hash (Join-Path $PSScriptRoot 'PrepareAMD.ps1'))
    shader_tools_lock_sha256 = (Hash (Join-Path $PSScriptRoot 'ShaderTools.lock.json'))
    source_helper_sha256 = (Hash (Join-Path $PSScriptRoot 'MesaSource.ps1'))
    outputs = $outputs
    scope = 'Generated Vulkan/NVK/RADV/ACO tables and consistent private source overlays; no provider binary or runtime capability claim.'
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $output 'prepare.json') -Encoding utf8NoBOM
Write-Host "R4VK pinned Mesa preparation: $output ($($outputs.Count) outputs)"
