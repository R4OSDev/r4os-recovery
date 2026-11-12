# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param([switch]$Offline, [ValidateRange(1,32)][int]$Jobs = 4)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (!$IsWindows -and !$IsLinux) { throw 'Supported build hosts: Windows and Linux.' }
. ([IO.Path]::GetFullPath('../../Shared/Native/SDK.ps1',$PSScriptRoot))
. (Join-Path $PSScriptRoot 'Common.ps1')
$paths = Get-R4VideoPaths
& pwsh -NoLogo -NoProfile -File (Join-Path $paths.libraries 'R4AMD/Tools/VcnCodecs.ps1')
if ($LASTEXITCODE) { throw 'VCN source verification failed.' }
$options = @()
if ($Offline) { $options += '-Offline' }
& pwsh -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'Prepare.ps1') @options
if ($LASTEXITCODE) { throw 'FFmpeg preparation failed.' }
& pwsh -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'Tables.ps1')
if ($LASTEXITCODE) { throw 'FFmpeg constant-table generation failed.' }
$clang = (Get-Command $(if ($IsWindows) { 'clang.exe' } else { 'clang-'+$script:R4SdkNative.data.Tools.tools.graphics.clang.Split('.')[0] }) -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$nasm = (Get-Command nasm -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$compiler = @(& $clang --version)
Assert-R4SdkNativeCompiler $script:R4SdkNative $clang
$assembler = @(& $nasm -v)
if ($LASTEXITCODE -or !$assembler.Count -or $assembler[0] -notmatch 'NASM version (\d+)\.(\d+)') { throw 'Cannot identify NASM.' }
if(([version]($Matches[1]+'.'+$Matches[2])) -lt [version]$script:R4SdkNative.data.Tools.tools.graphics.nasm_minimum){throw 'SDK NASM minimum not satisfied'}
$resource = [string](& $clang -print-resource-dir)
if ($LASTEXITCODE -or !$resource) { throw 'Cannot locate target compiler headers.' }
$ar = Join-Path ([IO.Path]::GetDirectoryName($clang)) $(if ($IsWindows) { 'llvm-ar.exe' } else { 'llvm-ar' })
if (!(Test-Path -LiteralPath $ar)) { $ar = (Get-Command ('llvm-ar-'+$script:R4SdkNative.data.Tools.tools.graphics.clang.Split('.')[0]) -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source }
$planPath = Join-Path $PSScriptRoot 'NativeInputs.json'
$plan = Get-Content -Raw -LiteralPath $planPath | ConvertFrom-Json
$sharedC = @('string','tokenize','format','stdio','sort','numeric','errno')
$pin = (Get-Content -Raw -LiteralPath (Join-Path $paths.unit 'ThirdParty/Sources.json') | ConvertFrom-Json).sources[0]
if ($plan.schema -ne 1 -or $plan.ffmpeg -ne $pin.version) { throw 'Native source plan differs from FFmpeg lock.' }
$source = Join-Path $paths.cache 'Source'
$generated = Join-Path $paths.cache 'Generated'
$config = Join-Path $paths.unit 'Port/Config'
$include = Join-Path $paths.unit 'Port/Include'
$shared = Join-Path $paths.libraries 'Shared/Native'
$output = Join-Path $paths.cache 'C'
$objects = Join-Path $output 'Objects'
$record = Join-Path $output 'native.json'
$inputs = @($PSCommandPath, (Join-Path $PSScriptRoot 'Common.ps1'), $planPath, (Join-Path $paths.cache 'prepare.json'),
    (Join-Path $generated 'tables.json'), (Join-Path $generated 'r4video_cavlc_tables.h'),
    (Join-Path $generated 'r4video_h274_tables.h'), $clang, $nasm, $ar)
foreach ($directory in @((Join-Path $paths.unit 'Port'), (Join-Path $paths.libraries 'R4AMD/Port'), (Join-Path $paths.unit 'Bindings/C'), $shared,
        (Join-Path $paths.libraries 'R4NAK/ThirdParty/stb'),
        (Join-Path $paths.sdk 'Shared/C/include'), (Join-Path $paths.contract 'Generated/SDK/C/include'), (Join-Path $paths.contract 'Generated/Generation2/C/include'),
        (Join-Path $resource.Trim() 'include'))) {
    $inputs += @(Get-ChildItem -LiteralPath $directory -Recurse -File | ForEach-Object FullName)
}
foreach ($provider in @('Math','Scan')) {
    $manifest = Get-Content -Raw -LiteralPath (Join-Path $shared "$provider/Sources.json") | ConvertFrom-Json
    $inputs += @($manifest.files | ForEach-Object { Join-Path $paths.zig $_.path })
}
$identities = @($inputs | Sort-Object -Unique | ForEach-Object {
    [ordered]@{path=[IO.Path]::GetRelativePath($paths.workspace,$_).Replace('\','/'); sha256=(Get-R4VideoHash $_)}
})
$identity = [ordered]@{sdk_profiles=$script:R4SdkNative.data.hashes;schema=1; host=$(if($IsWindows){'Windows-x64'}else{'Linux-x64'}); compiler=$compiler[0]; assembler=$assembler[0]; inputs=$identities}
$id = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($identity | ConvertTo-Json -Depth 7 -Compress)))).ToLowerInvariant()
if (Test-Path -LiteralPath $record) {
    $previous = Get-Content -Raw -LiteralPath $record | ConvertFrom-Json
    if ($previous.identity -eq $id) {
        if ($previous.outputs.Count -ne $plan.units.Count + $sharedC.Count + 9) { throw 'Incomplete native FFmpeg output inventory.' }
        foreach ($entry in $previous.outputs) {
            if ((Get-R4VideoHash (Join-Path $output $entry.path)) -ne $entry.sha256) { throw "Native FFmpeg cache changed: $($entry.path)" }
        }
        Write-Host "Verified FFmpeg native archive: $output"
        return
    }
    [IO.File]::Delete($record)
}
[IO.Directory]::CreateDirectory($objects) | Out-Null
$flags = @($script:R4SdkNative.data.Build.codegen.'native-flags'.video_flags)+@('-isystem',(Join-Path $resource.Trim() 'include'), ('-I'+$include),('-I'+$shared),('-I'+$config),('-I'+$generated),
    ('-I'+(Join-Path $config 'libavcodec')),('-I'+(Join-Path $config 'libavutil')),('-I'+$source),
    ('-I'+(Join-Path $paths.unit 'Bindings/C')), ('-I'+(Join-Path $paths.sdk 'Shared/C/include')),
    ('-I'+(Join-Path $paths.contract 'Generated/SDK/C/include')), ('-I'+(Join-Path $paths.contract 'Generated/Generation2/C/include')))
$asmFlags = @($script:R4SdkNative.data.Build.codegen.'native-flags'.video_asm_flags)+@(('-P'+(Join-Path $config 'config.asm')),
    ('-I'+$source.Replace('\','/')+'/'), ('-I'+$config.Replace('\','/')+'/'))
$units = @(foreach ($unit in $plan.units) {
    if ($unit.source -notmatch '^libav(codec|util)/[A-Za-z0-9_/]+\.(c|asm)$' -or $unit.object -notmatch '^libav(codec|util)/[A-Za-z0-9_/]+\.o$') { throw 'Invalid FFmpeg source path.' }
    [pscustomobject]@{name=$unit.object.Replace('/','_'); source=(Join-Path $source $unit.source); kind=$unit.kind}
})
$units += [pscustomobject]@{name='r4video_pthread.o'; source=(Join-Path $paths.unit 'Port/pthread.c'); kind='c'}
$units += [pscustomobject]@{name='r4video_codec.o'; source=(Join-Path $paths.unit 'Port/codec.c'); kind='c'}
$units += [pscustomobject]@{name='r4video_nvdec.o'; source=(Join-Path $paths.unit 'Port/nvdec.c'); kind='c'}
$units += [pscustomobject]@{name='r4video_vcn.o'; source=(Join-Path $paths.unit 'Port/vcn.c'); kind='c'}
$units += [pscustomobject]@{name='r4amd_vcn_codecs.o'; source=(Join-Path $paths.libraries 'R4AMD/Port/vcn_codecs.c'); kind='c'}
$units += [pscustomobject]@{name='r4video_state.o'; source=(Join-Path $paths.unit 'Port/state.c'); kind='c'}
foreach ($name in $sharedC) {
    $units += [pscustomobject]@{name=('r4video_native_'+$name+'.o'); source=(Join-Path $shared ($name+'.c')); kind='c'}
}
if (@($units.name | Sort-Object -Unique).Count -ne $units.Count) { throw 'Duplicate FFmpeg object name.' }
$results = @($units | ForEach-Object -Parallel {
    $entry = $_
    $object = Join-Path $using:objects $entry.name
    $log = $object + '.log'
    if ($entry.kind -eq 'c') {
        $options = @($using:flags) + @('-c',$entry.source,'-o',$object)
        $rsp = $object + '.rsp'
        [IO.File]::WriteAllLines($rsp, @($options | ForEach-Object { '"'+$_.Replace('\','\\').Replace('"','\"')+'"' }), [Text.UTF8Encoding]::new($false))
        & $using:clang ('@'+$rsp) 2> $log
    } elseif ($entry.kind -eq 'asm') {
        $options = @($using:asmFlags) + @(('-I'+[IO.Path]::GetDirectoryName($entry.source).Replace('\','/')+'/'),'-o',$object,$entry.source)
        & $using:nasm @options 2> $log
    } else { throw 'Unknown FFmpeg source kind.' }
    [pscustomobject]@{name=$entry.name; object=$object; log=$log; success=($LASTEXITCODE -eq 0)}
} -ThrottleLimit $Jobs)
$failed = @($results | Where-Object { !$_.success })
if ($failed.Count) {
    foreach ($entry in $failed | Select-Object -First 12) { Write-Host $entry.name; Get-Content -LiteralPath $entry.log | Select-Object -First 18 | Write-Host }
    throw "FFmpeg compilation failed: $($failed.Count)/$($units.Count). Full diagnostics: $objects"
}
$rsp = Join-Path $output 'archive.rsp'
[IO.File]::WriteAllLines($rsp, @($results | Sort-Object name | ForEach-Object { '"'+$_.object.Replace('\','/')+'"' }), [Text.UTF8Encoding]::new($false))
$pending = Join-Path $output 'R4VIDEO-FFmpeg.pending.a'
[IO.File]::Delete($pending)
& $ar rcs $pending ('@'+$rsp)
if ($LASTEXITCODE) { throw 'FFmpeg archive failed.' }
$archive = Join-Path $output 'R4VIDEO-FFmpeg.a'
[IO.File]::Move($pending,$archive,$true)
$archives = @($archive)
foreach ($provider in @('Math','Scan')) {
    $providerOutput = Join-Path $output $provider
    & pwsh -NoLogo -NoProfile -File (Join-Path $shared "$provider/Build.ps1") -Clang $clang -OutputRoot $providerOutput -IncludeRoot $include -ZigRoot $paths.zig
    if ($LASTEXITCODE) { throw "Native $provider build failed." }
    $archives += Join-Path $providerOutput ("R4Native$provider.a")
}
$outputs = @(@($results.object)+$archives | ForEach-Object { [ordered]@{path=[IO.Path]::GetRelativePath($output,$_).Replace('\','/'); sha256=(Get-R4VideoHash $_)} })
[ordered]@{schema=1; identity=$id; inputs=$identity; outputs=$outputs; scope='Freestanding codec objects only. Runtime ownership, executable decode and hardware admission require separate integration.'} |
    ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $record -Encoding utf8NoBOM
Write-Host "Built FFmpeg native archive: $($units.Count) objects, plus shared Math/Scan archives."
