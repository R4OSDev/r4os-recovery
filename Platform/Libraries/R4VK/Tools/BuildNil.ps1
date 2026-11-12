# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$CompilerRoot,
    [Parameter(Mandatory)][string]$MesaRoot,
    [Parameter(Mandatory)][string]$OutputRoot
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. ([IO.Path]::GetFullPath('../../Shared/Native/SDK.ps1',$PSScriptRoot))
if (!$IsWindows -and !$IsLinux) { throw 'Supported hosts: Windows and Linux.' }
. (Join-Path $PSScriptRoot 'MesaSource.ps1')
$mesa = Get-R4VKMesaSource
$compiler = [IO.Path]::GetFullPath($CompilerRoot, $mesa.workspace)
$prepared = [IO.Path]::GetFullPath($MesaRoot, $mesa.workspace)
$output = [IO.Path]::GetFullPath($OutputRoot, $mesa.workspace)
foreach ($protected in @($mesa.source, $compiler, $prepared)) {
    $prefix = $protected.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if ($output -eq $protected -or $output.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'NIL output must be outside its source and dependency trees.'
    }
}
function Run([string]$Tool, [string[]]$Options) {
    & $Tool @Options
    if ($LASTEXITCODE) { throw "$Tool failed ($LASTEXITCODE)" }
}
$tools = @{}
$versions = [ordered]@{}
foreach ($name in @('rustc', 'clang', 'bindgen')) {
    $command = if ($name -eq 'clang' -and $IsLinux) { ('clang-'+$script:R4SdkNative.data.Tools.tools.graphics.clang.Split('.')[0]) } else { $name }
    $tools[$name] = (Get-Command $command -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
    $reported = @(& $tools[$name] --version)
    if ($LASTEXITCODE -or !$reported.Count -or [string]$reported[0] -notmatch ('(?<![0-9.])' + [regex]::Escape([string]$mesa.lock.host_tools.$name) + '(?![0-9.])')) {
        throw "Pinned $name toolchain required."
    }
    $versions[$name] = [string]$reported[0]
}
$nakUnit = Join-Path $mesa.libraries 'R4NAK'
$nakRecordPath = Join-Path $compiler 'build.json'
$nakRecord = Get-Content -Raw -LiteralPath $nakRecordPath | ConvertFrom-Json
if ($nakRecord.inputs.mesa_lock -ne (Get-R4VKFileHash $mesa.lock_path) -or
    $nakRecord.inputs.mesa_patch -ne (Get-R4VKFileHash (Join-Path $mesa.libraries 'R4NV/Tools/Compiler/MesaStandalone.patch')) -or
    $nakRecord.archive_sha256 -ne (Get-R4VKFileHash (Join-Path $compiler 'R4NAK.a'))) {
    throw 'Native NAK dependency differs from its source/build record.'
}
foreach ($item in $nakRecord.inputs.inputs) {
    if ((Get-R4VKFileHash (Join-Path $nakUnit $item.path)) -ne $item.sha256) { throw "NAK input changed: $($item.path)" }
}
$preparePath = Join-Path $prepared 'prepare.json'
$prepare = Get-Content -Raw -LiteralPath $preparePath | ConvertFrom-Json
if ($prepare.source_manifest_sha256 -ne (Get-R4VKFileHash $mesa.manifest_path)) { throw 'NIL and runtime Mesa sources differ.' }
foreach ($item in $prepare.outputs) {
    if ((Get-R4VKFileHash (Join-Path $prepared $item.path)) -ne $item.sha256) { throw "Prepared Mesa output changed: $($item.path)" }
}
# Verify Rust dependency object code against the recorded complete compiler,
# rather than trusting a loose rlib merely because it is in that cache folder.
function ArchiveObjects([string]$Path) {
    $data = [IO.File]::ReadAllBytes($Path)
    $ascii = [Text.Encoding]::ASCII
    if ($data.Length -lt 8 -or $ascii.GetString($data, 0, 8) -ne "!<arch>`n") { throw "Invalid archive: $Path" }
    $names = ''; $objects = @{}; [long]$at = 8
    while ($at -lt $data.Length) {
        if ($at + 60 -gt $data.Length -or $data[$at + 58] -ne 96 -or $data[$at + 59] -ne 10) { throw 'Invalid archive header.' }
        $name = $ascii.GetString($data, $at, 16).Trim()
        [long]$size = [long]::Parse($ascii.GetString($data, $at + 48, 10).Trim(), [Globalization.CultureInfo]::InvariantCulture)
        $start = $at + 60
        if ($size -lt 0 -or $start + $size -gt $data.Length) { throw 'Archive member exceeds file.' }
        if ($name -eq '//') { $names = $ascii.GetString($data, $start, $size) }
        elseif ($name -ne '/') {
            if ($name -match '^/([0-9]+)$') {
                $offset = [int]$Matches[1]
                $end = $names.IndexOf("/`n", $offset, [StringComparison]::Ordinal)
                if ($end -lt $offset) { throw 'Invalid archive long name.' }
                $name = $names.Substring($offset, $end - $offset)
            } else { $name = $name.TrimEnd('/') }
            if ($name.EndsWith('.o', [StringComparison]::Ordinal)) {
                if ($objects.ContainsKey($name)) { throw "Duplicate archive member: $name" }
                $sha = [Security.Cryptography.SHA256]::Create()
                try { $objects[$name] = [Convert]::ToHexString($sha.ComputeHash($data, $start, $size)).ToLowerInvariant() }
                finally { $sha.Dispose() }
            }
        }
        $at = $start + $size + ($size % 2)
    }
    return $objects
}
$fullObjects = ArchiveObjects (Join-Path $compiler 'R4NAK.a')
$dependencies = @('RustBuild/libr4os_std.rlib', 'RustBuild/libbitview.rlib', 'RustBuild/libnvidia_headers.rlib', 'RustBuild/libhashbrown.rlib',
    'Sysroot/lib/rustlib/r4os-x86_64/lib/libcore.rlib', 'Sysroot/lib/rustlib/r4os-x86_64/lib/liballoc.rlib', 'Sysroot/lib/rustlib/r4os-x86_64/lib/libcompiler_builtins.rlib')
$verifiedMembers = 0
foreach ($relative in $dependencies) {
    $members = ArchiveObjects (Join-Path $compiler $relative)
    foreach ($name in $members.Keys) {
        if (!$fullObjects.ContainsKey($name) -or $fullObjects[$name] -ne $members[$name]) { throw "Rust dependency object differs: $relative / $name" }
        $verifiedMembers++
    }
}
$hostName = if ($IsWindows) { 'Windows-x64' } else { 'Linux-x64' }
$hostBuild = Join-Path ([IO.Path]::GetDirectoryName($mesa.source)) ('Build-' + $hostName)
# The shared compiler owns ABI flags and freestanding headers. Keep its script
# variables private; this consumer only takes the C options and macro target.
function CompilerInputs {
    $unit = $nakUnit; $buildRoot = $compiler; $source = $mesa.source
    $overlay = Join-Path $compiler 'CSource'
    . (Join-Path $nakUnit 'Tools/CInputs.ps1')
    $matches = @($targets | Where-Object name -eq paste)
    if ($matches.Count -ne 1 -or @($matches[0].filename).Count -ne 1) { throw 'Missing native paste macro.' }
    return @{ c = $cArgs; paste = [string]$matches[0].filename[0] }
}
$inputs = CompilerInputs
# The record is validated above. Its elapsed time is evidence, not an input
# to the compiler/driver identity; bind the actual verified archive instead.
$paths = @($PSCommandPath, (Join-Path $PSScriptRoot 'MesaSource.ps1'), (Join-Path $compiler 'R4NAK.a'), $preparePath,
    (Join-Path $nakUnit 'Port/Rust/r4os-x86_64.json'), $inputs.paste)
$paths += @($dependencies | ForEach-Object { Join-Path $compiler $_ })
$paths += @(Get-ChildItem -LiteralPath $hostBuild -Recurse -File -Filter '*.h' | ForEach-Object FullName)
$records = @(foreach ($path in $paths | Sort-Object -Unique) {
    [ordered]@{path = [IO.Path]::GetRelativePath($mesa.workspace, $path).Replace('\', '/'); sha256 = (Get-R4VKFileHash $path)}
})
$identity = [ordered]@{sdk_profiles=$script:R4SdkNative.data.hashes;schema = 1; host = $hostName; tools = $versions; inputs = $records; compiler = $nakRecord.identity; verified_rust_members = $verifiedMembers}
$id = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($identity | ConvertTo-Json -Depth 8 -Compress)))).ToLowerInvariant()
$recordPath = Join-Path $output 'nil.json'
if (Test-Path -LiteralPath $recordPath) {
    $previous = Get-Content -Raw -LiteralPath $recordPath | ConvertFrom-Json
    if ($previous.identity -eq $id) {
        foreach ($item in $previous.outputs) {
            if ((Get-R4VKFileHash (Join-Path $output $item.path)) -ne $item.sha256) { throw "NIL cache changed: $($item.path)" }
        }
        Write-Host "Verified native NIL cache: $output"
        return
    }
    Remove-Item -LiteralPath $recordPath
}
$rust = Join-Path $output 'Rust'
[IO.Directory]::CreateDirectory($rust) | Out-Null
$source = Join-Path $mesa.source 'src/nouveau/nil'
$generated = Join-Path $prepared 'Generated'
$bindOptions = @((Join-Path $source 'nil_bindings.h'), '--rust-target', ($script:R4SdkNative.data.Tools.tools.graphics.rustc.Split('.')[0..1] -join '.'), '--use-core', '--ctypes-prefix', 'core::ffi', '--with-derive-default', '--no-prepend-enum-name', '--formatter', 'none')
foreach ($name in @('util_format_description', 'util_format_get_blocksize', 'util_format_is_compressed', 'util_format_is_pure_integer', 'util_format_is_srgb', 'drm_format_mod_block_linear_2D', 'drm_mod_is_nvidia')) { $bindOptions += @('--allowlist-function', $name) }
foreach ($name in @('nil_format_support_flags', 'nv_device_info', 'nv_device_type', 'nv_zcull_device_info', 'pipe_format', 'pipe_swizzle')) { $bindOptions += @('--allowlist-type', $name) }
foreach ($name in @('nil_format_table', 'drm_format_mod_invalid', 'drm_format_mod_linear')) { $bindOptions += @('--allowlist-var', $name) }
$clangOptions = @($script:R4SdkNative.data.Build.codegen.'native-flags'.binding_c_flags) + @("-I$generated")
for ($i = 0; $i -lt $inputs.c.Count; $i++) {
    if ($inputs.c[$i] -eq '-isystem') { $clangOptions += @($inputs.c[$i], $inputs.c[++$i]) }
    elseif ($inputs.c[$i].StartsWith('-I') -or $inputs.c[$i].StartsWith('-D')) { $clangOptions += $inputs.c[$i] }
}
$bindings = Join-Path $output 'nil_bindings.rs'
Run $tools.bindgen ($bindOptions + @('-o', $bindings, '--') + $clangOptions)
[IO.File]::WriteAllText($bindings, "#![no_std]`n" + [IO.File]::ReadAllText($bindings), [Text.UTF8Encoding]::new($false))
foreach ($file in Get-ChildItem -LiteralPath $source -Filter '*.rs' -File) {
    $text = [IO.File]::ReadAllText($file.FullName).Replace("`r`n", "`n")
    $declarations = [regex]::Matches($text, '(?m)^(?:#!\[.*|//!.*)$')
    $position = if ($declarations.Count) { $last = $declarations[$declarations.Count - 1]; $last.Index + $last.Length } else { 0 }
    $text = $text.Insert($position, "`nuse std::prelude::*;`n")
    $text = [regex]::Replace($text, '(?m)^(\s*(?:pub )?mod \w+ \{)', ('$1' + "`n    use std::prelude::*;"))
    if ($file.Name -eq 'lib.rs') { $text = "#![no_std]`n#[macro_use] extern crate r4os_std as std;`n" + $text }
    if ($file.Name -eq 'image.rs') {
        # Preserve original calculations; only the native worker adapter may
        # invoke these private entries. No pretend catch_unwind is supplied.
        if ([regex]::Matches($text, 'panic::catch_unwind\(\|\| \{').Count -ne 2 -or [regex]::Matches($text, '\}\)\n        \.is_ok\(\)').Count -ne 2) { throw 'Pinned NIL panic boundaries changed.' }
        $text = $text.Replace("use std::panic;`n", '').Replace('panic::catch_unwind(|| {', '{').Replace("})`n        .is_ok()", "}`n        true")
        $text = $text.Replace('fn nil_image_init(', 'fn r4vk_nil_image_init_unchecked(').Replace('fn nil_image_init_planar(', 'fn r4vk_nil_image_init_planar_unchecked(')
    }
    if ($file.Name -eq 'descriptor.rs') {
        $needle = 'scaled.clamp(0.0, scaled_max).round()'
        if (!$text.Contains($needle)) { throw 'Pinned NIL rounding changed.' }
        $text = $text.Replace($needle, 'unsafe { roundf(scaled.clamp(0.0, scaled_max)) }')
        $text += "`n" + 'unsafe extern "C" { fn roundf(x: f32) -> f32; }' + "`n"
    }
    [IO.File]::WriteAllText((Join-Path $rust $file.Name), $text, [Text.UTF8Encoding]::new($false))
}
$common = @(Expand-R4SdkNativeFlags $script:R4SdkNative 'nil_rust_flags' @{target=(Join-Path $nakUnit 'Port/Rust/r4os-x86_64.json');sysroot=(Join-Path $compiler 'Sysroot');rust_build=(Join-Path $compiler 'RustBuild');output=$output})
Run $tools.rustc ($common + @('--crate-type=rlib', '--crate-name', 'nil_rs_bindings', $bindings, '-o', (Join-Path $output 'libnil_rs_bindings.rlib')))
$options = $common + @('--crate-type=staticlib', '--crate-name', 'nil', (Join-Path $rust 'lib.rs'), '-o', (Join-Path $output 'libnil.a'), '--extern', ('nil_rs_bindings=' + (Join-Path $output 'libnil_rs_bindings.rlib')), '--extern', ('paste=' + $inputs.paste))
foreach ($name in @('r4os_std', 'bitview', 'nvidia_headers')) { $options += @('--extern', ($name + '=' + (Join-Path $compiler ('RustBuild/lib' + $name + '.rlib')))) }
Run $tools.rustc $options
$outputs = @(Get-ChildItem -LiteralPath $output -Recurse -File | Where-Object Extension -in @('.rs', '.a', '.rlib') | Sort-Object FullName | ForEach-Object {
    [ordered]@{path = [IO.Path]::GetRelativePath($output, $_.FullName).Replace('\', '/'); sha256 = (Get-R4VKFileHash $_.FullName)}
})
[ordered]@{schema = 1; identity = $id; inputs = $identity; outputs = $outputs; scope = 'Original freestanding NIL; native image constructors require r4vk_nil worker adapters. Format table C comes from the same prepared Mesa tree. No provider/GPU capability claim.'} |
    ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $recordPath -Encoding utf8NoBOM
Write-Host "Built native NIL: $output ($verifiedMembers verified Rust dependency objects)"
