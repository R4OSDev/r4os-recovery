# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputRoot, [ValidateRange(1,32)][int]$Jobs = 4)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. ([IO.Path]::GetFullPath('../../Shared/Native/SDK.ps1',$PSScriptRoot))
if (!$IsWindows -and !$IsLinux) { throw 'Supported hosts: Windows and Linux.' }
. (Join-Path $PSScriptRoot 'MesaSource.ps1')
$mesa = Get-R4VKMesaSource
$lockPath = Join-Path $PSScriptRoot 'ShaderTools.lock.json'
$shaderLock = Get-Content -Raw -LiteralPath $lockPath | ConvertFrom-Json
function Run([string]$Tool, [string[]]$Options) {
    & $Tool @Options
    if ($LASTEXITCODE) { throw "$Tool failed ($LASTEXITCODE)" }
}
function Tool([string]$Name) {
    (Get-Command $Name -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
}
$tools = [ordered]@{
    clang = (Tool $(if ($IsWindows) { 'clang.exe' } else { ('clang-'+$script:R4SdkNative.data.Tools.tools.graphics.clang.Split('.')[0]) }))
    clangxx = (Tool $(if ($IsWindows) { 'clang++.exe' } else { ('clang++-'+$script:R4SdkNative.data.Tools.tools.graphics.clang.Split('.')[0]) }))
    llvm = (Tool $(if ($IsWindows) { 'llvm-config.exe' } else { 'llvm-config-19' }))
    meson = (Tool 'meson'); ninja = (Tool 'ninja'); git = (Tool 'git')
    pkgconfig = (Tool 'pkg-config')
}
$versions = [ordered]@{}
foreach ($name in @('clang', 'clangxx', 'llvm', 'meson', 'ninja')) {
    $reported = @(& $tools[$name] --version)
    $expected = if ($name -in @('clang','clangxx','llvm')) { $shaderLock.llvm } else { $mesa.lock.host_tools.$name }
    if ($LASTEXITCODE -or !$reported.Count -or [string]$reported[0] -notmatch ('(?<![0-9.])' + [regex]::Escape([string]$expected) + '(?![0-9.])')) {
        throw "Pinned $name required: $expected"
    }
    $versions[$name] = [string]$reported[0]
}
foreach ($pair in @(@('SPIRV-Tools', $shaderLock.spirv_tools_pkgconfig), @('LLVMSPIRVLib', $shaderLock.llvm_spirv_pkgconfig))) {
    $reported = @(& $tools.pkgconfig --modversion $pair[0])
    if ($LASTEXITCODE -or $reported.Count -ne 1 -or [string]$reported[0] -ne $pair[1]) { throw "Pinned pkg-config dependency required: $($pair[0]) $($pair[1])" }
    $versions[$pair[0]] = [string]$reported[0]
}
$patch = Join-Path $mesa.unit 'Port/MesaGenerators.patch'
$patchHash = Get-R4VKFileHash $patch
$manifestHash = Get-R4VKFileHash $mesa.manifest_path
$identity = $manifestHash.Substring(0,16) + '-' + (Get-R4VKFileHash $lockPath).Substring(0,16)
$cache = Join-Path $mesa.devkit ('Toolchains/R4VKShaders/' + $identity)
$source = Join-Path $cache 'Source'
# Use a separate complete source tree. Meson and the generator patch may not
# alter the checksum-pinned source shared with the installed R4NAK compiler.
foreach ($file in $mesa.files) {
    $destination = Join-Path $source $file.path
    if (!(Test-Path -LiteralPath $destination) -or (Get-R4VKFileHash $destination) -ne $file.sha256) {
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
        Copy-Item -LiteralPath (Join-Path $mesa.source $file.path) -Destination $destination -Force
    }
}
# The shared standalone Mesa recipe refers to its R4NV-owned host target.
# These injected sources are deliberately outside the upstream file manifest.
$standaloneInputs = @(foreach ($file in Get-ChildItem -LiteralPath (Join-Path $mesa.libraries 'R4NV/Tools/Compiler/Source') -File | Sort-Object Name) {
    $destination = Join-Path $source ('src/nouveau/r4os/' + $file.Name)
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
    $digest = Get-R4VKFileHash $file.FullName
    if (!(Test-Path -LiteralPath $destination) -or (Get-R4VKFileHash $destination) -ne $digest) {
        Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
    }
    [ordered]@{path = ('R4NV/Tools/Compiler/Source/' + $file.Name); sha256 = $digest}
})
Push-Location ([IO.Path]::GetPathRoot($source))
try {
    Run $tools.git @('apply', '--unsafe-paths', ('--directory=' + $source), '--check', $patch)
    Run $tools.git @('apply', '--unsafe-paths', ('--directory=' + $source), $patch)
} finally { Pop-Location }
$hostName = if ($IsWindows) { 'Windows-x64' } else { 'Linux-x64' }
$suffix = if ($IsWindows) { '.exe' } else { '' }
$build = Join-Path $cache ('Build-' + $hostName)
$output = [IO.Path]::GetFullPath($OutputRoot, $mesa.workspace)
foreach ($protected in @($mesa.source, $source, $build)) {
    $prefix = $protected.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if ($output -eq $protected -or $output.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw 'Generated shader output must be outside Mesa source/build trees.' }
}
[IO.Directory]::CreateDirectory($output) | Out-Null
$recordPath = Join-Path $output 'shaders.json'
if (Test-Path -LiteralPath $recordPath) { Remove-Item -LiteralPath $recordPath }
$options = @('--wrap-mode=nodownload', '--force-fallback-for=syn,paste,rustc-hash',
    '-Dr4os-nak=true', '-Dbuildtype=release', '-Db_ndebug=false', '-Dgallium-drivers=[]',
    '-Dvulkan-drivers=[]', '-Dplatforms=[]', '-Dglx=disabled', '-Degl=disabled', '-Dgbm=disabled',
    '-Dllvm=enabled', '-Dshared-llvm=enabled', '-Dmesa-clc=enabled', '-Dinstall-mesa-clc=true',
    '-Dmesa-clc-bundle-headers=enabled', '-Dopengl=false', '-Dgles1=disabled', '-Dgles2=disabled',
    '-Dvideo-codecs=[]', '-Dbuild-tests=false', '-Dshader-cache=disabled', '-Dzstd=disabled',
    '-Dxmlconfig=disabled', '-Dtools=[]', '-Dvalgrind=disabled', '-Dexpat=disabled',
    '-Dzlib=disabled', '-Ddisplay-info=disabled')
$saved = @{}
foreach ($name in @('CC', 'CXX', 'CFLAGS', 'CXXFLAGS', 'LDFLAGS', 'RUSTFLAGS', 'LLVM_CONFIG',
                    'NIR_DEBUG', 'NAK_DEBUG', 'PYTHONHASHSEED', 'PYTHONDONTWRITEBYTECODE')) {
    $saved[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
    [Environment]::SetEnvironmentVariable($name, $null, 'Process')
}
try {
    $env:CC = $tools.clang; $env:CXX = $tools.clangxx; $env:LLVM_CONFIG = $tools.llvm
    $env:PYTHONHASHSEED = '0'; $env:PYTHONDONTWRITEBYTECODE = '1'
    $setup = @('setup')
    if (Test-Path -LiteralPath (Join-Path $build 'meson-private/coredata.dat')) { $setup += '--reconfigure' }
    Run $tools.meson ($setup + @($build, $source) + $options)
    Run $tools.ninja @('-C', $build, '-j', [string]$Jobs, ('src/compiler/clc/mesa_clc' + $suffix),
        ('src/compiler/spirv/vtn_bindgen2' + $suffix), 'src/nouveau/headers/nv_push_cl90b5.h')
    $clc = Join-Path $build ('src/compiler/clc/mesa_clc' + $suffix)
    $bindgen = Join-Path $build ('src/compiler/spirv/vtn_bindgen2' + $suffix)
    $clOptions = @('-cl-std=cl2.0', '-D__OPENCL_VERSION__=200', '-DHAVE___BUILTIN_FFS', '-DHAVE___BUILTIN_CLZ',
        ('-fmacro-prefix-map=' + $source.Replace('\','/') + '/='), ('-fmacro-prefix-map=' + $build.Replace('\','/') + '/='))
    foreach ($directory in @('src/compiler/libcl', 'src/nouveau/vulkan', 'src', 'src/nouveau/headers', 'src/nouveau/headers/nvidia/classes')) {
        $clOptions += '-I' + (Join-Path $source $directory)
    }
    $clOptions += '-I' + (Join-Path $build 'src/nouveau/headers')
    Run $clc (@('-o', (Join-Path $output 'nvkcl.spv'), '--depfile', (Join-Path $output 'nvkcl.spv.d'),
        (Join-Path $source 'src/nouveau/vulkan/cl/nvk_query.cl'), (Join-Path $source 'src/nouveau/vulkan/cl/nvk_copy_indirect.cl'), '--') + $clOptions)
    Run $bindgen @((Join-Path $output 'nvkcl.spv'), (Join-Path $output 'nvkcl.c'), (Join-Path $output 'nvkcl.h'),
        '--printf-metadata', 'r4vk_nvkcl_printf_metadata')
} finally {
    foreach ($name in $saved.Keys) { [Environment]::SetEnvironmentVariable($name, $saved[$name], 'Process') }
}
$outputs = @(foreach ($leaf in @('nvkcl.spv', 'nvkcl.spv.d', 'nvkcl.c', 'nvkcl.h')) {
    [ordered]@{path = $leaf; sha256 = (Get-R4VKFileHash (Join-Path $output $leaf))}
})
[ordered]@{
    schema = 1; mesa = $mesa.lock.mesa.version; source_files_verified = $mesa.files.Count
    source_manifest_sha256 = $manifestHash; mesa_lock_sha256 = (Get-R4VKFileHash $mesa.lock_path)
    shader_tools_lock_sha256 = (Get-R4VKFileHash $lockPath); generator_patch_sha256 = $patchHash
    prepare_script_sha256 = (Get-R4VKFileHash $PSCommandPath)
    source_helper_sha256 = (Get-R4VKFileHash (Join-Path $PSScriptRoot 'MesaSource.ps1'))
    host = $hostName; tools = $versions; meson_options = $options; cl_options = $clOptions
    standalone_inputs = $standaloneInputs
    mesa_clc_sha256 = (Get-R4VKFileHash $clc); vtn_bindgen_sha256 = (Get-R4VKFileHash $bindgen)
    outputs = $outputs
    scope = 'Pinned NVK query/indirect-copy SPIR-V and serialized NIR helpers; native provider must register immutable printf metadata in its process-owned compiler context. No Vulkan capability or GPU execution claim.'
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $recordPath -Encoding utf8NoBOM
Write-Host "R4VK native shader helpers: $output"
