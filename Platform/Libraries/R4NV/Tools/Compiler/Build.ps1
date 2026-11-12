# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param(
    [switch]$InstallDependencies,
    [switch]$Offline,
    [switch]$PrepareSources,
    [switch]$VerifyReproducible,
    [ValidateSet(75,86,89,120)][int]$ShaderModel = 86,
    [ValidateRange(1, 32)][int]$Jobs = 8,
    [string]$OutputDirectory = '',
    [string]$RustCopyrightFile = ''
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. ([IO.Path]::GetFullPath('../../../Shared/Native/SDK.ps1',$PSScriptRoot))
if (!$IsWindows -and !$IsLinux) { throw 'Supported hosts: Windows and Linux.' }
$libraryRoot = [IO.Path]::GetFullPath('../../..', $PSScriptRoot)
$settings = @{}
foreach ($line in Get-Content -LiteralPath (Join-Path $libraryRoot 'Settings.R4S')) {
    if ($line -match '^([A-Z_]+)=(.+)$') { $settings[$Matches[1]] = $Matches[2] }
}
function Resolve-Setting([string]$Base, [string]$Name) {
    return [IO.Path]::GetFullPath($settings[$Name].Replace('\', [IO.Path]::DirectorySeparatorChar), $Base)
}
$workspace = Resolve-Setting $libraryRoot 'WORKSPACE_ROOT'
$devkit = Resolve-Setting $workspace 'DEVKIT_ROOT'
$artifacts = Resolve-Setting $workspace 'ARTIFACTS_ROOT'
$hostName = if ($IsWindows) { 'Windows-x64' } else { 'Linux-x64' }
if ([Runtime.InteropServices.RuntimeInformation]::OSArchitecture -ne 'X64') { throw 'This compiler toolchain profile requires an x64 host.' }
$suffix = if ($IsWindows) { '.exe' } else { '' }
$lockPath = Join-Path $PSScriptRoot 'Sources.lock.json'
$lock = Get-Content -LiteralPath $lockPath -Raw | ConvertFrom-Json
if ($lock.schema -ne 1) { throw 'Unsupported compiler source lock.' }
$targets=@($lock.targets|Where-Object sm -eq $ShaderModel)
if($targets.Count -ne 1){throw 'Unsupported shader target'}
$shaderTarget=$targets[0]
$watch = [Diagnostics.Stopwatch]::StartNew()

function Invoke-Checked([string]$Program, [string[]]$Arguments) {
    & $Program @Arguments
    if ($LASTEXITCODE) { throw "$Program failed with exit code $LASTEXITCODE" }
}
function Find-Tool([string]$Name) {
    $tool = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($null -eq $tool) { throw "Required host tool is missing: $Name. See Tools/Compiler/README.md." }
    return $tool.Source
}
function Read-Version([string]$Program, [string]$Expected) {
    $value = @(& $Program --version 2>&1)
    if ($LASTEXITCODE -or !$value.Count -or
        [string]$value[0] -notmatch ('(?<![0-9.])' + [regex]::Escape($Expected) + '(?![0-9.])')) {
        throw "Unsupported tool version: $Program. Required: $Expected; reported: $($value -join ' ')"
    }
    return [string]$value[0]
}
function Hash([string]$Path, [string]$Algorithm = 'SHA256') {
    return (Get-FileHash -LiteralPath $Path -Algorithm $Algorithm).Hash.ToLowerInvariant()
}

if ($InstallDependencies) {
    if ($Offline) { throw '-InstallDependencies cannot be combined with -Offline.' }
    if ($IsLinux) {
        $release = Get-Content -LiteralPath '/etc/os-release' -Raw
        if ($release -notmatch '(?m)^ID=debian$' -or $release -notmatch '(?m)^VERSION_ID="13"$') {
            throw 'Automatic dependency installation currently supports Debian 13; other hosts can provide the tools from Sources.lock.json.'
        }
        $aptArgs = @('install', '-y', '--no-install-recommends', 'rustc', 'bindgen', 'cbindgen', 'meson',
            'ninja-build', 'python3-mako', 'python3-yaml', 'python3-packaging', ('clang-'+$script:R4SdkNative.data.Tools.tools.graphics.clang.Split('.')[0]),
            ('libclang-'+$script:R4SdkNative.data.Tools.tools.graphics.clang.Split('.')[0]+'-dev'), 'flex', 'bison', 'pkg-config', 'curl', 'git', 'xz-utils', 'build-essential')
        $uid = & (Find-Tool 'id') -u
        if ($LASTEXITCODE) { throw 'Cannot determine the host user.' }
        if ($uid -eq '0') { Invoke-Checked (Find-Tool 'apt-get') $aptArgs }
        else { Invoke-Checked (Find-Tool 'sudo') (@('apt-get') + $aptArgs) }
    } else {
        throw 'On Windows, prepare the native LLVM/Windows SDK, Rust and Python tools listed in README.md, then run Build.bat. This script does not replace an installed toolchain.'
    }
}
$toolVersions = [ordered]@{}
$tools = @{}
if (!$PrepareSources) {
foreach ($name in @('rustc', 'meson', 'ninja', 'bindgen', 'cbindgen')) {
    $tools[$name] = Find-Tool ($name + $suffix)
    $toolVersions[$name] = Read-Version $tools[$name] $lock.host_tools.$name
}
$cc = Find-Tool $(if ($IsWindows) { 'clang-cl.exe' } else { ('clang-'+$script:R4SdkNative.data.Tools.tools.graphics.clang.Split('.')[0]) })
$cxx = if ($IsWindows) { $cc } else { Find-Tool ('clang++-'+$script:R4SdkNative.data.Tools.tools.graphics.clang.Split('.')[0]) }
$toolVersions.clang = Read-Version $cc $lock.host_tools.clang
}
$git = Find-Tool ('git' + $suffix)
$tar = Find-Tool ('tar' + $suffix)
$curl = Find-Tool ('curl' + $suffix)

$cache = Join-Path $devkit '.Cache/MesaNAK'
[void](New-Item -ItemType Directory -Path $cache -Force)
function Get-Source([object]$Item, [string]$Algorithm, [string]$Expected) {
    $target = Join-Path $cache $Item.filename
    if ((Test-Path -LiteralPath $target) -and (Hash $target $Algorithm) -eq $Expected) { return $target }
    $reference = Join-Path $workspace ('ExFiles/Reference/GFX/Archives/' + $Item.filename)
    if ((Test-Path -LiteralPath $reference) -and (Hash $reference $Algorithm) -eq $Expected) {
        Copy-Item -LiteralPath $reference -Destination $target
        return $target
    }
    if ($Offline) { throw "Offline source archive is missing or has the wrong hash: $target" }
    $partial = $target + '.' + [Guid]::NewGuid().ToString('N') + '.part'
    try {
        Invoke-Checked $curl @('--fail', '--location', '--retry', '2', '--connect-timeout', '15',
            '--max-time', '180', '--silent', '--show-error', '--output', $partial, $Item.url)
        if ((Hash $partial $Algorithm) -ne $Expected) { throw "Source hash mismatch: $($Item.filename)" }
        Move-Item -LiteralPath $partial -Destination $target -Force
    } finally {
        if (Test-Path -LiteralPath $partial) { Remove-Item -LiteralPath $partial }
    }
    return $target
}
$archive = Get-Source $lock.mesa 'SHA512' $lock.mesa.sha512
$crateArchives = @{}
foreach ($crate in $lock.crates) { $crateArchives[$crate.wrap] = Get-Source $crate 'SHA256' $crate.sha256 }
$patch = Join-Path $PSScriptRoot 'MesaStandalone.patch'
$patchId = (Hash $patch).Substring(0, 16)
$prepared = Join-Path $devkit ('Toolchains/MesaNAK/' + $lock.mesa.version + '-' + $patchId)
$source = Join-Path $prepared 'Source'
$preparedStamp = Join-Path $prepared 'prepared.json'
$sourceManifest = Join-Path $prepared 'source-files.json'
if (!(Test-Path -LiteralPath $preparedStamp)) {
    if (Test-Path -LiteralPath $prepared) { throw "An incomplete compiler source tree exists at $prepared. Inspect or remove that generated tree before retrying." }
    [void](New-Item -ItemType Directory -Path $source -Force)
    Invoke-Checked $tar @('-xJf', $archive, '--strip-components=1', '-C', $source)
    # Run outside the surrounding coordinator repository. Otherwise git apply
    # can silently skip paths below its ignored DevKit directory.
    Push-Location ([IO.Path]::GetPathRoot($source))
    try {
        Invoke-Checked $git @('apply', '--unsafe-paths', ('--directory=' + $source), '--check', $patch)
        Invoke-Checked $git @('apply', '--unsafe-paths', ('--directory=' + $source), $patch)
    } finally { Pop-Location }
    $packagecache = Join-Path $source 'subprojects/packagecache'
    [void](New-Item -ItemType Directory -Path $packagecache -Force)
    foreach ($crate in $lock.crates) {
        $wrap = Get-Content -LiteralPath (Join-Path $source ('subprojects/' + $crate.wrap + '.wrap')) -Raw
        foreach ($expected in @($crate.sha256, $crate.url, $crate.directory)) {
            if (!$wrap.Contains($expected, [StringComparison]::Ordinal)) { throw "Mesa crate lock does not match $($crate.wrap)." }
        }
        Copy-Item -LiteralPath $crateArchives[$crate.wrap] -Destination (Join-Path $packagecache $crate.filename)
        Invoke-Checked $tar @('-xzf', $crateArchives[$crate.wrap], '-C', (Join-Path $source 'subprojects'))
        $overlay = Join-Path $source ('subprojects/packagefiles/' + $crate.wrap)
        Get-ChildItem -LiteralPath $overlay -Force | Copy-Item -Destination (Join-Path $source ('subprojects/' + $crate.directory)) -Recurse -Force
    }
    $sourceFiles = @(Get-ChildItem -LiteralPath $source -File -Recurse -Force | ForEach-Object {
        [ordered]@{path=[IO.Path]::GetRelativePath($source, $_.FullName).Replace('\', '/');sha256=(Hash $_.FullName)}
    })
    $sourceFiles | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $sourceManifest -Encoding utf8NoBOM
    [ordered]@{mesa=$lock.mesa.sha512;patch=(Hash $patch)} | ConvertTo-Json |
        Set-Content -LiteralPath $preparedStamp -Encoding utf8NoBOM
} else {
    $stamp = Get-Content -LiteralPath $preparedStamp -Raw | ConvertFrom-Json
    if ($stamp.mesa -ne $lock.mesa.sha512 -or $stamp.patch -ne (Hash $patch)) { throw 'Prepared source identity differs from the source lock.' }
    foreach ($file in (Get-Content -LiteralPath $sourceManifest -Raw | ConvertFrom-Json)) {
        if ((Hash (Join-Path $source $file.path)) -ne $file.sha256) { throw "Prepared compiler source changed: $($file.path)" }
    }
}
if ($PrepareSources) {
    Write-Host "Verified shared Mesa sources: $source"
    return
}
$r4osSources = Join-Path $source 'src/nouveau/r4os'
[void](New-Item -ItemType Directory -Path $r4osSources -Force)
Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'Source') -File | ForEach-Object {
    $dest = Join-Path $r4osSources $_.Name
    if (!(Test-Path -LiteralPath $dest) -or (Hash $_.FullName) -ne (Hash $dest)) {
        Copy-Item -LiteralPath $_.FullName -Destination $dest
    }
}
$build = Join-Path $prepared ('Build-' + $hostName)
$oldEnvironment = @{}
foreach ($name in @('CC', 'CXX', 'NAK_DEBUG', 'NIR_DEBUG', 'RUSTFLAGS', 'CFLAGS', 'CXXFLAGS', 'LDFLAGS', 'PYTHONHASHSEED')) {
    $oldEnvironment[$name] = [Environment]::GetEnvironmentVariable($name)
    Remove-Item -LiteralPath ('Env:' + $name) -ErrorAction SilentlyContinue
}
try {
    $env:CC = $cc; $env:CXX = $cxx; $env:PYTHONHASHSEED = '0'
    $options = @($script:R4SdkNative.data.Build.codegen.'native-flags'.meson_options)
    $setupArgs = @('setup')
    if (Test-Path -LiteralPath (Join-Path $build 'meson-private/coredata.dat')) { $setupArgs += '--reconfigure' }
    Invoke-Checked $tools.meson ($setupArgs + @($build, $source) + $options)
    Invoke-Checked $tools.ninja @('-C', $build, '-j', [string]$Jobs, ('src/nouveau/r4os/r4nak' + $suffix))
    $compiler = Join-Path $build ('src/nouveau/r4os/r4nak' + $suffix)
    $output = if ($OutputDirectory) { [IO.Path]::GetFullPath($OutputDirectory, $workspace) }
              else { Join-Path $artifacts ('Tools/R4NAK/' + $hostName + $(if($ShaderModel -ne 86){'/SM'+$ShaderModel}else{''})) }
    [void](New-Item -ItemType Directory -Path $output -Force)
    $buildRecord = Join-Path $output 'build.json'
    if (Test-Path -LiteralPath $buildRecord) { Remove-Item -LiteralPath $buildRecord }
    $outputs = @(foreach ($profile in $lock.profiles) {
        $prefix = Join-Path $output $profile.name
        Invoke-Checked $compiler @([string]$profile.id, ($prefix+'.bin'), ($prefix+'.json'), ($prefix+'.asm.txt'), ($prefix+'.nir.txt'), [string]$ShaderModel) | Out-Host
        $info = Get-Content -LiteralPath ($prefix+'.json') -Raw | ConvertFrom-Json
        if ($info.sm -ne $shaderTarget.sm -or $info.max_warps_per_mp -ne $shaderTarget.max_warps_per_mp -or $info.stage -ne $profile.stage -or $info.profile -ne $profile.id -or
            $info.header.Count -ne 32 -or $info.code_bytes -ne (Get-Item -LiteralPath ($prefix+'.bin')).Length) { throw "Unexpected shader metadata: $($profile.name)" }
        $binaryHash = Hash ($prefix+'.bin')
        if ($VerifyReproducible) {
            $repeat = $prefix + '.repeat'
            Invoke-Checked $compiler @([string]$profile.id, ($repeat+'.bin'), ($repeat+'.json'), ($repeat+'.asm.txt'), ($repeat+'.nir.txt'), [string]$ShaderModel) | Out-Host
            foreach ($ext in @('.bin', '.json', '.asm.txt', '.nir.txt')) {
                if ((Hash ($prefix+$ext)) -ne (Hash ($repeat+$ext))) { throw "Nonreproducible compiler output: $($profile.name)$ext" }
                Remove-Item -LiteralPath ($repeat+$ext)
            }
        }
        [ordered]@{profile=$profile.id;name=$profile.name;sha256=$binaryHash;
            metadata_sha256=(Hash ($prefix+'.json'));assembly_sha256=(Hash ($prefix+'.asm.txt'));nir_sha256=(Hash ($prefix+'.nir.txt'));
            code_bytes=$info.code_bytes;gprs=$info.gprs;instructions=$info.instructions}
    })
    $inputs = @(foreach ($file in @('Sources.lock.json', 'MesaStandalone.patch', 'Build.ps1',
                                  'Source/meson.build', 'Source/r4nak.c', 'Source/shaders.c', 'Source/shaders.h', 'Source/color_shader.h', 'Source/yuv_shader.h', 'Source/encode_shader.h')) {
        [ordered]@{path=$file;sha256=(Hash (Join-Path $PSScriptRoot $file))}
    })
    $recipeText = ($inputs | ConvertTo-Json -Compress) + ($options -join "`n") + ($shaderTarget | ConvertTo-Json -Compress)
    $inputs+=@(foreach($name in @('Build','Tools','Components')){
        $path=Join-Path $script:R4SdkNative.sdk_root ('Profiles/'+$name+'.json')
        [ordered]@{path=[IO.Path]::GetRelativePath($PSScriptRoot,$path).Replace('\','/');sha256=(Hash $path)}
    })
    $recipe = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($recipeText))).ToLowerInvariant()
    Copy-Item -LiteralPath $compiler -Destination (Join-Path $output ('r4nak' + $suffix))
    # Host-tool redistribution retains every original source/license archive.
    # No part of this host package is installed in an R4OS image.
    $legal = Join-Path $output 'Legal'
    $legalSources = Join-Path $legal 'Sources'
    [void](New-Item -ItemType Directory -Path $legalSources -Force)
    Copy-Item -LiteralPath $archive -Destination $legalSources
    foreach ($crate in $lock.crates) { Copy-Item -LiteralPath $crateArchives[$crate.wrap] -Destination $legalSources }
    foreach ($name in @('LICENSE', 'NOTICE', 'THIRD_PARTY_NOTICES.md')) {
        Copy-Item -LiteralPath (Join-Path $libraryRoot $name) -Destination (Join-Path $legal $name)
    }
    Copy-Item -LiteralPath (Join-Path $source 'docs/license.rst') -Destination (Join-Path $legal 'Mesa-license.rst')
    $mesaLicenses = Join-Path $legal 'Mesa-Licenses'
    [void](New-Item -ItemType Directory -Path $mesaLicenses -Force)
    Get-ChildItem -LiteralPath (Join-Path $source 'licenses') -Force | Copy-Item -Destination $mesaLicenses -Recurse -Force
    if ($RustCopyrightFile) { $rustCopyright = [IO.Path]::GetFullPath($RustCopyrightFile, $workspace) }
    elseif ($IsLinux -and (Test-Path -LiteralPath '/usr/share/doc/libstd-rust-1.85/copyright')) {
        $rustCopyright = '/usr/share/doc/libstd-rust-1.85/copyright'
    } else {
        $sysroot = & $tools.rustc --print sysroot
        if ($LASTEXITCODE) { throw 'Cannot locate the Rust runtime notices.' }
        $rustCopyright = Join-Path ([string]$sysroot) 'share/doc/rust/COPYRIGHT'
    }
    if (!(Test-Path -LiteralPath $rustCopyright -PathType Leaf)) {
        throw 'Rust runtime copyright notices are missing. Supply the matching full notices with -RustCopyrightFile.'
    }
    Copy-Item -LiteralPath $rustCopyright -Destination (Join-Path $legal 'Rust-runtime-copyright.txt')
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'README.md') -Destination (Join-Path $output 'README.md')
    Copy-Item -LiteralPath $lockPath -Destination (Join-Path $output 'Sources.lock.json')
    $mesonInfo = Join-Path $build 'meson-info'
    foreach ($name in @('intro-compilers.json', 'intro-buildoptions.json', 'intro-dependencies.json', 'intro-machines.json')) {
        Copy-Item -LiteralPath (Join-Path $mesonInfo $name) -Destination (Join-Path $output $name)
    }
    $legalBytes = (Get-ChildItem -LiteralPath $legal -File -Recurse | Measure-Object -Property Length -Sum).Sum
    [ordered]@{schema=1;host=$hostName;compiler_id=$recipe;inputs=$inputs;tools=$toolVersions;
        target=$shaderTarget;profiles=$outputs;reproducible=$VerifyReproducible.IsPresent;
        tool_sha256=(Hash $compiler);tool_bytes=(Get-Item -LiteralPath $compiler).Length;
        legal_bytes=$legalBytes;rust_copyright_sha256=(Hash $rustCopyright);
        elapsed_seconds=[Math]::Round($watch.Elapsed.TotalSeconds, 3)} | ConvertTo-Json -Depth 20 |
        Set-Content -LiteralPath $buildRecord -Encoding utf8NoBOM
    Write-Output "R4NAK build complete: $output"
} finally {
    foreach ($name in $oldEnvironment.Keys) {
        if ($null -eq $oldEnvironment[$name]) { Remove-Item -LiteralPath ('Env:' + $name) -ErrorAction SilentlyContinue }
        else { [Environment]::SetEnvironmentVariable($name, $oldEnvironment[$name]) }
    }
}
