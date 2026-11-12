# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param([switch]$Offline, [ValidateRange(1,32)][int]$Jobs = 4)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. ([IO.Path]::GetFullPath('../../Shared/Native/SDK.ps1',$PSScriptRoot))
if (!$IsWindows -and !$IsLinux) { throw 'Supported hosts: Windows and Linux.' }
. (Join-Path $PSScriptRoot 'Common.ps1')
$paths = Get-R4GLPaths
$prepared = Join-Path $paths.cache 'Mesa'
$options = @('-OutputRoot', $prepared)
if ($Offline) { $options += '-Offline' }
Invoke-R4GLScript (Join-Path $PSScriptRoot 'Prepare.ps1') $options
$lock = Get-Content -Raw -LiteralPath $paths.lock | ConvertFrom-Json
$planPath = Join-Path $PSScriptRoot 'NativeInputs.json'
$plan = Get-Content -Raw -LiteralPath $planPath | ConvertFrom-Json
if ($plan.schema -ne 1 -or $plan.mesa -ne $lock.mesa.version) { throw 'Native source plan differs from the Mesa lock.' }
$clang = (Get-Command $(if ($IsWindows) { 'clang.exe' } else { ('clang-'+$script:R4SdkNative.data.Tools.tools.graphics.clang.Split('.')[0]) }) -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$version = @(& $clang --version)
if ($LASTEXITCODE -or !$version.Count -or [string]$version[0] -notmatch ('(?<![0-9.])' + [regex]::Escape($lock.host_tools.clang) + '(?![0-9.])')) { throw 'Pinned clang required.' }
$resource = [string](& $clang -print-resource-dir)
if ($LASTEXITCODE -or !$resource) { throw 'Cannot locate clang target headers.' }
$ar = Join-Path ([IO.Path]::GetDirectoryName($clang)) $(if ($IsWindows) { 'llvm-ar.exe' } else { 'llvm-ar' })
if (!(Test-Path -LiteralPath $ar)) { $ar = (Get-Command llvm-ar-19 -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source }
$roots = @{
    source = (Join-Path $prepared 'Source'); generated = (Join-Path $prepared 'Generated')
    include = (Join-Path $paths.unit 'Port/Include'); port = (Join-Path $paths.unit 'Port')
    libraries = $paths.libraries; sdk = $paths.sdk; contract = $paths.contract
    zig = $paths.zig; clang_resource = $resource.Trim()
}
function Expand([string]$Value) {
    foreach ($key in $roots.Keys) { $Value = $Value.Replace(('${' + $key + '}'), $roots[$key].Replace('\', '/')) }
    if ($Value.Contains('${')) { throw "Unknown native path variable: $Value" }
    return $Value
}
$output = Join-Path $paths.cache 'C'
$objects = Join-Path $output 'Objects'
$recordPath = Join-Path $output 'native.json'
$cpp = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'CppSources.json') | ConvertFrom-Json
foreach ($file in $cpp.files) {
    if ((Get-R4GLHash (Join-Path $paths.zig $file.path)) -ne $file.sha256) { throw "libc++ source pin mismatch: $($file.path)" }
}
# Include the transitive header owners: a native cache may not survive a change
# in a bundled compiler header or a shared runtime implementation unnoticed.
$inputs = @($PSCommandPath, $paths.lock, $clang, $ar, $planPath, (Join-Path $prepared 'prepare.json'),
    (Join-Path $PSScriptRoot 'Common.ps1'), (Join-Path $PSScriptRoot 'CppSources.json'))
foreach ($directory in @($roots.port, (Join-Path $paths.libraries 'Shared/Native'),
        (Join-Path $paths.libraries 'R4NAK/Port/Include'), (Join-Path $paths.libraries 'R4GFX/Bindings/C'),
        (Join-Path $paths.libraries 'R4VK/Bindings/C'),
        (Join-Path $paths.sdk 'Shared/C/include'), (Join-Path $paths.contract 'Generated/SDK/C/include'), (Join-Path $paths.contract 'Generated/Generation2/C/include'),
        (Join-Path $paths.zig 'lib/libcxx'), (Join-Path $paths.zig 'lib/libcxxabi/include'),
        (Join-Path $resource.Trim() 'include'))) {
    $inputs += @(Get-ChildItem -LiteralPath $directory -File -Recurse | Where-Object Extension -ne '.zig' | ForEach-Object FullName)
}
foreach ($provider in @('Math','Scan')) {
    $manifest = Get-Content -Raw -LiteralPath (Join-Path $paths.libraries "Shared/Native/$provider/Sources.json") | ConvertFrom-Json
    $inputs += @($manifest.files | ForEach-Object { Join-Path $paths.zig $_.path })
}
$identities = @(foreach ($file in $inputs | Sort-Object -Unique) {
    [ordered]@{path = [IO.Path]::GetRelativePath($paths.workspace, $file).Replace('\','/'); sha256 = (Get-R4GLHash $file)}
})
$identity = [ordered]@{sdk_profiles=$script:R4SdkNative.data.hashes;schema = 1; host = $(if ($IsWindows) { 'Windows-x64' } else { 'Linux-x64' }); compiler = $version[0]; inputs = $identities}
$id = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($identity | ConvertTo-Json -Depth 7 -Compress)))).ToLowerInvariant()
if (Test-Path -LiteralPath $recordPath) {
    $previous = Get-Content -Raw -LiteralPath $recordPath | ConvertFrom-Json
    if ($previous.identity -eq $id) {
        if ($previous.schema -ne 1 -or $previous.mesa_units -ne $plan.units.Count -or
            $previous.objects -ne $plan.units.Count + $cpp.units.Count + 1 -or
            $previous.outputs.Count -ne $previous.objects + 3) { throw 'Incomplete native GL cache inventory.' }
        foreach ($file in $previous.outputs) {
            if ((Get-R4GLHash (Join-Path $output $file.path)) -ne $file.sha256) { throw "Native GL cache changed: $($file.path)" }
        }
        Write-Host "Verified native GL archive: $output"
        return
    }
    Remove-Item -LiteralPath $recordPath
}
[IO.Directory]::CreateDirectory($objects) | Out-Null
$units = @(foreach ($entry in $plan.units) {
    if ($entry.name -notmatch '^[A-Za-z0-9_.-]+$' -or $entry.profile -lt 0 -or $entry.profile -ge $plan.profiles.Count) { throw 'Invalid native source entry.' }
    [pscustomobject]@{name = $entry.name; source = (Expand $entry.source); arguments = @($plan.profiles[$entry.profile] | ForEach-Object { Expand $_ })}
})
if (@($units.name | Sort-Object -Unique).Count -ne $units.Count) { throw 'Duplicate native object name.' }
$private = Join-Path $output 'Cpp'
[IO.Directory]::CreateDirectory((Join-Path $private 'include')) | Out-Null
Copy-Item -LiteralPath (Join-Path $paths.zig 'lib/libcxx/src/new.cpp') -Destination (Join-Path $private 'new.cpp') -Force
$header = [IO.File]::ReadAllText((Join-Path $paths.zig 'lib/libcxx/src/include/overridable_function.h'))
$needle = '#elif defined(_LIBCPP_OBJECT_FORMAT_ELF) && !defined(__NVPTX__)'
if (!$header.Contains($needle)) { throw 'libc++ override source drift.' }
# R4M does not interpose application operator-new into an R4L. Select the
# upstream weak-function fallback without an ELF-only section.
[IO.File]::WriteAllText((Join-Path $private 'include/overridable_function.h'), $header.Replace($needle, $needle + ' && !defined(R4OS_NATIVE_R4M)'), [Text.UTF8Encoding]::new($false))
$sample = $units | Where-Object { $_.source.EndsWith('.cpp') } | Select-Object -First 1
$cppFlags = @($sample.arguments | Where-Object { $_ -notmatch '^-std=' }) + @($script:R4SdkNative.data.Build.codegen.'native-flags'.libcxx_flags)
foreach ($name in $cpp.units) {
    $source = if ($name -eq 'new') { Join-Path $private 'new.cpp' } else { Join-Path $paths.zig "lib/libcxx/src/$name.cpp" }
    $units += [pscustomobject]@{name = "r4gl_libcxx_$name"; source = $source; arguments = ($cppFlags + '-D_LIBCPP_BUILDING_LIBRARY')}
}
$units += [pscustomobject]@{name = 'r4gl_cpp_runtime'; source = (Join-Path $paths.libraries 'Shared/Native/cpp.cpp'); arguments = $cppFlags}
$results = @($units | ForEach-Object -Parallel {
    $entry = $_
    $object = Join-Path $using:objects ($entry.name + '.o')
    $log = $object + '.log'
    $arguments = @($entry.arguments) + @('-c', $entry.source, '-o', $object)
    # LLVM response-file escaping, independent of shell quoting/Windows argv limits.
    $quoted = @($arguments | ForEach-Object { '"' + $_.Replace('\','\\').Replace('"','\"') + '"' })
    $response = $object + '.rsp'
    [IO.File]::WriteAllLines($response, $quoted, [Text.UTF8Encoding]::new($false))
    & $using:clang ('@' + $response) 2> $log
    [pscustomobject]@{name = $entry.name; object = $object; log = $log; success = ($LASTEXITCODE -eq 0)}
} -ThrottleLimit $Jobs)
$failed = @($results | Where-Object { !$_.success })
if ($failed.Count) {
    foreach ($failure in $failed) { Write-Host $failure.name; Get-Content -LiteralPath $failure.log | Write-Host }
    throw "Native GL compilation failed: $($failed.Count)/$($units.Count)"
}
foreach ($provider in @('Math','Scan')) {
    $destination = Join-Path $output $provider
    Invoke-R4GLScript (Join-Path $paths.libraries "Shared/Native/$provider/Build.ps1") @('-Clang', $clang, '-OutputRoot', $destination, '-IncludeRoot', $roots.include, '-ZigRoot', $paths.zig)
}
$response = Join-Path $output 'archive.rsp'
[IO.File]::WriteAllLines($response, @($results | Sort-Object name | ForEach-Object { '"' + $_.object.Replace('\','/') + '"' }), [Text.UTF8Encoding]::new($false))
$pending = Join-Path $output 'R4GL-C.pending.a'
[IO.File]::Delete($pending)
& $ar rcs $pending ('@' + $response)
if ($LASTEXITCODE) { throw 'Native GL archive failed.' }
$archive = Join-Path $output 'R4GL-C.a'
[IO.File]::Move($pending, $archive, $true)
$outputs = @(foreach ($file in @($results.object) + @($archive, (Join-Path $output 'Math/R4NativeMath.a'), (Join-Path $output 'Scan/R4NativeScan.a'))) {
    [ordered]@{path = [IO.Path]::GetRelativePath($output, $file).Replace('\','/'); sha256 = (Get-R4GLHash $file)}
})
[ordered]@{schema = 1; identity = $id; inputs = $identity; mesa_units = $plan.units.Count; objects = $units.Count; outputs = $outputs;
    scope = 'Native Mesa EGL/software GL objects and C/C++ runtime. Link with the process and window owners; Zink objects are not feature admission.'} |
    ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $recordPath -Encoding utf8NoBOM
Write-Host "Built native GL: $($units.Count) objects plus pinned math/scan archives."
