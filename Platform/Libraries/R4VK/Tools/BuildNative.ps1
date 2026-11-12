# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$CompilerRoot,
    [Parameter(Mandatory)][string]$MesaRoot,
    [Parameter(Mandatory)][string]$ShaderRoot,
    [Parameter(Mandatory)][string]$OutputRoot,
    [ValidateRange(1,32)][int]$Jobs = 4
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. ([IO.Path]::GetFullPath('../../Shared/Native/SDK.ps1',$PSScriptRoot))
$sdkCpp23Flags=@($script:R4SdkNative.data.Build.codegen.'native-flags'.cpp23_flags)
$sdkLibcxxVkFlags=@($script:R4SdkNative.data.Build.codegen.'native-flags'.libcxx_vk_flags)
if (!$IsWindows -and !$IsLinux) { throw 'Supported hosts: Windows and Linux.' }
. (Join-Path $PSScriptRoot 'MesaSource.ps1')
. (Join-Path $PSScriptRoot 'CInputs.ps1')
. (Join-Path $PSScriptRoot 'Archive.ps1')
$mesa = Get-R4VKMesaSource
$compiler = [IO.Path]::GetFullPath($CompilerRoot, $mesa.workspace)
$prepared = [IO.Path]::GetFullPath($MesaRoot, $mesa.workspace)
$shaders = [IO.Path]::GetFullPath($ShaderRoot, $mesa.workspace)
$output = [IO.Path]::GetFullPath($OutputRoot, $mesa.workspace)
foreach ($protected in @($mesa.unit, $mesa.source, $compiler, $prepared, $shaders)) {
    $prefix = $protected.TrimEnd([IO.Path]::DirectorySeparatorChar) + [IO.Path]::DirectorySeparatorChar
    if ($output -eq $protected -or $output.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Native output must be outside source and dependency trees.'
    }
}
$clang = (Get-Command $(if ($IsWindows) { 'clang.exe' } else { ('clang-'+$script:R4SdkNative.data.Tools.tools.graphics.clang.Split('.')[0]) }) -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$reported = @(& $clang --version)
if ($LASTEXITCODE -or !$reported.Count -or [string]$reported[0] -notmatch ('(?<![0-9.])' + [regex]::Escape([string]$mesa.lock.host_tools.clang) + '(?![0-9.])')) { throw 'Pinned clang required.' }
$settings = @{}
foreach ($line in Get-Content -LiteralPath (Join-Path $mesa.libraries 'Settings.R4S')) {
    if ($line -match '^([A-Z_]+)=(.+)$') { $settings[$Matches[1]] = $Matches[2] }
}
$zigRoot = [IO.Path]::GetFullPath($settings.ZIG_ROOT.Replace('\', [IO.Path]::DirectorySeparatorChar), $mesa.devkit)
$zig = Join-Path $zigRoot $(if ($IsWindows) { 'zig.exe' } else { 'zig' })
$nakRecord = Get-Content -Raw -LiteralPath (Join-Path $compiler 'build.json') | ConvertFrom-Json
if ($nakRecord.inputs.mesa_lock -ne (Get-R4VKFileHash $mesa.lock_path) -or
    $nakRecord.inputs.mesa_patch -ne (Get-R4VKFileHash (Join-Path $mesa.libraries 'R4NV/Tools/Compiler/MesaStandalone.patch')) -or
    $nakRecord.archive_sha256 -ne (Get-R4VKFileHash (Join-Path $compiler 'R4NAK.a'))) { throw 'NAK dependency differs from its build record.' }
foreach ($item in $nakRecord.inputs.inputs) {
    if ((Get-R4VKFileHash (Join-Path $mesa.libraries ('R4NAK/' + $item.path))) -ne $item.sha256) { throw "NAK input changed: $($item.path)" }
}
$prepare = Get-Content -Raw -LiteralPath (Join-Path $prepared 'prepare.json') | ConvertFrom-Json
$shader = Get-Content -Raw -LiteralPath (Join-Path $shaders 'shaders.json') | ConvertFrom-Json
foreach ($record in @($prepare, $shader)) {
    if ($record.source_manifest_sha256 -ne (Get-R4VKFileHash $mesa.manifest_path) -or
        $record.mesa_lock_sha256 -ne (Get-R4VKFileHash $mesa.lock_path) -or
        $record.source_helper_sha256 -ne (Get-R4VKFileHash (Join-Path $PSScriptRoot 'MesaSource.ps1'))) { throw 'Mesa input preparation is stale.' }
}
if ($prepare.runtime_patch_sha256 -ne (Get-R4VKFileHash (Join-Path $mesa.unit 'Port/MesaRuntime.patch')) -or
    $prepare.radv_patch_sha256 -ne (Get-R4VKFileHash (Join-Path $mesa.unit 'Port/MesaRADV.patch')) -or
    $prepare.amd_prepare_sha256 -ne (Get-R4VKFileHash (Join-Path $PSScriptRoot 'PrepareAMD.ps1')) -or
    $prepare.shader_tools_lock_sha256 -ne (Get-R4VKFileHash (Join-Path $PSScriptRoot 'ShaderTools.lock.json')) -or
    $prepare.prepare_script_sha256 -ne (Get-R4VKFileHash (Join-Path $PSScriptRoot 'Prepare.ps1')) -or
    $shader.generator_patch_sha256 -ne (Get-R4VKFileHash (Join-Path $mesa.unit 'Port/MesaGenerators.patch')) -or
    $shader.prepare_script_sha256 -ne (Get-R4VKFileHash (Join-Path $PSScriptRoot 'PrepareShaders.ps1')) -or
    $shader.shader_tools_lock_sha256 -ne (Get-R4VKFileHash (Join-Path $PSScriptRoot 'ShaderTools.lock.json'))) { throw 'Native generators or patches changed; prepare their outputs again.' }
foreach ($item in $shader.standalone_inputs) {
    if ((Get-R4VKFileHash (Join-Path $mesa.libraries $item.path)) -ne $item.sha256) { throw 'Shader generator source changed.' }
}
foreach ($pair in @(@($prepared, $prepare), @($shaders, $shader))) {
    foreach ($item in $pair[1].outputs) {
        if ((Get-R4VKFileHash (Join-Path $pair[0] $item.path)) -ne $item.sha256) { throw "Prepared input changed: $($item.path)" }
    }
}
$inputs = Get-R4VKNativeCInputs -Mesa $mesa -CompilerRoot $compiler -MesaRoot $prepared -ShaderRoot $shaders -Clang $clang
$cpp = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'CppSources.json') | ConvertFrom-Json
foreach ($entry in $cpp.files) {
    if ((Get-R4VKFileHash (Join-Path $zigRoot $entry.path)) -ne $entry.sha256) { throw "Pinned libc++ input changed: $($entry.path)" }
}
$cppPrivate = Join-Path $output 'Cpp'
[IO.Directory]::CreateDirectory((Join-Path $cppPrivate 'include')) | Out-Null
Copy-Item -LiteralPath (Join-Path $zigRoot 'lib/libcxx/src/new.cpp') -Destination (Join-Path $cppPrivate 'new.cpp') -Force
$header = [IO.File]::ReadAllText((Join-Path $zigRoot 'lib/libcxx/src/include/overridable_function.h'))
$needle = '#elif defined(_LIBCPP_OBJECT_FORMAT_ELF) && !defined(__NVPTX__)'
if (!$header.Contains($needle)) { throw 'Pinned libc++ override template changed.' }
[IO.File]::WriteAllText((Join-Path $cppPrivate 'include/overridable_function.h'),
    $header.Replace($needle, $needle + ' && !defined(R4OS_NATIVE_R4M)'), [Text.UTF8Encoding]::new($false))
$inputs.sources += @(foreach ($name in $cpp.units) {
    if ($name -eq 'new') { Join-Path $cppPrivate 'new.cpp' } else { Join-Path $zigRoot "lib/libcxx/src/$name.cpp" }
})
$inputs.sources += Join-Path $mesa.libraries 'Shared/Native/cpp.cpp'
$inputs.cpp_arguments += '-DR4OS_NATIVE_R4M=1'
$paths = @($inputs.sources) + @($mesa.lock_path, $mesa.manifest_path, $zig, $clang,
    (Join-Path $compiler 'R4NAK.a'), (Join-Path $prepared 'prepare.json'), (Join-Path $shaders 'shaders.json'),
    (Join-Path $mesa.libraries 'R4NAK/Tools/CInputs.ps1'))
foreach ($directory in @('Port', 'Tools', 'Source', 'Contract')) {
    $path = Join-Path $mesa.unit $directory
    if (Test-Path -LiteralPath $path) {
        $paths += @(Get-ChildItem -LiteralPath $path -Recurse -File | Where-Object Extension -in '.c','.cpp','.h','.zig','.json','.ps1','.patch' | ForEach-Object FullName)
    }
}
foreach ($directory in $inputs.header_roots) {
    $paths += @(Get-ChildItem -LiteralPath $directory -Recurse -File | Where-Object Extension -in '.h','.hpp','.inc','.inl','' | ForEach-Object FullName)
}
# These implementation sources are included by the thin Port C wrappers.
# Hashing only the wrappers would silently accept stale native archives.
foreach ($name in @('string.c', 'format.c', 'stdio.c', 'sort.c', 'numeric.c', 'errno.c')) {
    $paths += Join-Path $mesa.libraries ('Shared/Native/' + $name)
}
$paths += Join-Path $cppPrivate 'include/overridable_function.h'
$paths += @($cpp.files | ForEach-Object { Join-Path $zigRoot $_.path })
$records = @(foreach ($path in $paths | Sort-Object -Unique) {
    [ordered]@{path = [IO.Path]::GetRelativePath($mesa.workspace, $path).Replace('\', '/'); sha256 = (Get-R4VKFileHash $path)}
})
$identity = [ordered]@{sdk_profiles=$script:R4SdkNative.data.hashes;schema = 1; host = $(if ($IsWindows) { 'Windows-x64' } else { 'Linux-x64' });
    compiler = [string]$reported[0]; nak = $nakRecord.identity; inputs = $records;
    arguments = @($inputs.arguments | ForEach-Object { $_.Replace($mesa.workspace, '<workspace>') });
    cpp_arguments = @($inputs.cpp_arguments | ForEach-Object { $_.Replace($mesa.workspace, '<workspace>') })}
$digest = [Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($identity | ConvertTo-Json -Depth 8 -Compress)))
$id = [Convert]::ToHexString($digest).ToLowerInvariant()
$recordPath = Join-Path $output 'native.json'
if (Test-Path -LiteralPath $recordPath) {
    $previous = Get-Content -Raw -LiteralPath $recordPath | ConvertFrom-Json
    if ($previous.identity -eq $id) {
        $names = @($previous.outputs.path)
        if ($previous.schema -ne 1 -or $previous.c_units -ne $inputs.sources.Count -or
            $names.Count -ne $inputs.sources.Count + 4 -or @($names | Sort-Object -Unique).Count -ne $names.Count -or
            'R4VK-C.a' -notin $names -or 'R4VK-C.whole.o' -notin $names -or 'build_identity.c' -notin $names) {
            throw 'Native cache output inventory is incomplete.'
        }
        foreach ($item in $previous.outputs) {
            if ((Get-R4VKFileHash (Join-Path $output $item.path)) -ne $item.sha256) { throw "Native cache changed: $($item.path)" }
        }
        Write-Host "Verified native Vulkan C cache: $output"
        return
    }
    Remove-Item -LiteralPath $recordPath
}
$objects = Join-Path $output 'Objects'
[IO.Directory]::CreateDirectory($objects) | Out-Null
$identitySource = Join-Path $output 'build_identity.c'
[IO.File]::WriteAllText($identitySource, 'const unsigned char r4vk_build_identity[32] = {' +
    (@($digest | ForEach-Object { [string]$_ }) -join ',') + "};`n", [Text.UTF8Encoding]::new($false))
$sources = @($inputs.sources) + @($identitySource)
$options = $inputs.arguments
$cppOptions = $inputs.cpp_arguments
$workspace = $mesa.workspace
$results = @($sources | ForEach-Object -Parallel {
    $file = $_
    $relative = [IO.Path]::GetRelativePath($using:workspace, $file).Replace('\', '/')
    $name = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($relative))).Substring(0, 12).ToLowerInvariant()
    $object = Join-Path $using:objects ($name + '-' + [IO.Path]::GetFileName($file) + '.o')
    $log = $object + '.log'
    $compileOptions = $using:options
    if ([IO.Path]::GetExtension($file) -eq '.cpp') {
        $compileOptions = $using:cppOptions
        if ([IO.Path]::GetFileName($file) -eq 'aco_opcodes.cpp') {
            $compileOptions += @($using:sdkCpp23Flags)
        } elseif ($file.StartsWith($using:zigRoot, [StringComparison]::OrdinalIgnoreCase) -or
                  $file.StartsWith($using:cppPrivate, [StringComparison]::OrdinalIgnoreCase)) {
            $compileOptions += @($using:sdkLibcxxVkFlags)
        }
    }
    & $using:clang @compileOptions -c $file -o $object 2> $log
    [ordered]@{source = $relative; success = ($LASTEXITCODE -eq 0); object = $object; log = $log}
} -ThrottleLimit $Jobs)
$results = @($results | Sort-Object source)
$failed = @($results | Where-Object { !$_.success })
if ($failed.Count) {
    foreach ($failure in $failed) { Write-Host $failure.source; Get-Content -LiteralPath $failure.log | Write-Host }
    throw "Native C compilation failed: $($failed.Count)/$($sources.Count)"
}
$archive = Join-Path $output 'R4VK-C.a'
New-R4VKDispatchArchive -Zig $zig -OutputFile $archive -Objects @($results.object)
$outputs = @(foreach ($path in @($results.object) + @($archive, [IO.Path]::ChangeExtension($archive, '.whole.o'), $identitySource)) {
    [ordered]@{path = [IO.Path]::GetRelativePath($output, $path).Replace('\', '/'); sha256 = (Get-R4VKFileHash $path)}
})
[ordered]@{schema = 1; identity = $id; inputs = $identity; c_units = $inputs.sources.Count;
    outputs = $outputs; scope = 'Native C dispatch archive and build identity. Link with the matching native NAK/NIL archives and R4VK Zig runtime. No fixture or failure injection; no installed module or feature admission.'} |
    ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $recordPath -Encoding utf8NoBOM
Write-Host "Built native Vulkan C archive: $archive ($($inputs.sources.Count) C units plus build identity)"
