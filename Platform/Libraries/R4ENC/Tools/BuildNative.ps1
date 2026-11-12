# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param([switch]$Offline, [ValidateRange(1,32)][int]$Jobs = 4)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (!$IsWindows -and !$IsLinux) { throw 'Supported build hosts: Windows and Linux.' }
. ([IO.Path]::GetFullPath('../../Shared/Native/SDK.ps1',$PSScriptRoot))
. (Join-Path $PSScriptRoot 'Common.ps1')
$paths = Get-R4EncPaths
& pwsh -NoLogo -NoProfile -File (Join-Path $paths.libraries 'R4AMD/Tools/VcnEncode.ps1')
if ($LASTEXITCODE) { throw 'Original VCN1 encoder extraction differs.' }
$options = @()
if ($Offline) { $options += '-Offline' }
& pwsh -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'Prepare.ps1') @options
if ($LASTEXITCODE) { throw 'OpenH264 preparation failed.' }
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
$pin = (Get-Content -Raw -LiteralPath (Join-Path $paths.unit 'ThirdParty/Sources.json') | ConvertFrom-Json).sources[0]
if ($plan.schema -ne 1 -or $plan.openh264 -ne $pin.version) { throw 'Native plan differs from OpenH264 lock.' }
$source = Join-Path $paths.cache 'Source'
$include = Join-Path $paths.unit 'Port/Include'
$shared = Join-Path $paths.libraries 'Shared/Native'
$output = Join-Path $paths.cache 'C'
$objects = Join-Path $output 'Objects'
$record = Join-Path $output 'native.json'
$inputs = @($PSCommandPath, (Join-Path $PSScriptRoot 'Common.ps1'), $planPath,
    (Join-Path $paths.cache 'prepare.json'), $clang, $nasm, $ar)
foreach ($directory in @((Join-Path $paths.unit 'Port'), (Join-Path $paths.unit 'Bindings/C'), $shared,
        (Join-Path $paths.libraries 'R4NAK/ThirdParty/stb'), (Join-Path $paths.libraries 'R4AMD/Port'),
        (Join-Path $paths.libraries 'R4AMD/ThirdParty/Mesa26.2.2/Original/src/amd/common'),
        (Join-Path $paths.sdk 'Shared/C/include'), (Join-Path $paths.contract 'Generated/SDK/C/include'), (Join-Path $paths.contract 'Generated/Generation2/C/include'),
        (Join-Path $resource.Trim() 'include'))) {
    $inputs += @(Get-ChildItem -LiteralPath $directory -Recurse -File | ForEach-Object FullName)
}
$math = Get-Content -Raw -LiteralPath (Join-Path $shared 'Math/Sources.json') | ConvertFrom-Json
$inputs += @($math.files | ForEach-Object { Join-Path $paths.zig $_.path })
$identity = [ordered]@{sdk_profiles=$script:R4SdkNative.data.hashes;schema=1;host=$(if($IsWindows){'Windows-x64'}else{'Linux-x64'});compiler=$compiler[0];assembler=$assembler[0];inputs=@(
    $inputs | Sort-Object -Unique | ForEach-Object {
        [ordered]@{path=[IO.Path]::GetRelativePath($paths.workspace,$_).Replace('\','/');sha256=(Get-R4EncHash $_)}
    }
)}
$id = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($identity | ConvertTo-Json -Depth 7 -Compress)))).ToLowerInvariant()
$units = @(foreach ($unit in $plan.units) {
    if ($unit.source -notmatch '^codec/(common|encoder|processing)/[A-Za-z0-9_/]+\.(cpp|asm)$') { throw 'Invalid encoder source path.' }
    [pscustomobject]@{name=($unit.source.Replace('/','_')+'.o');source=(Join-Path $source $unit.source);kind=$unit.kind}
})
foreach ($file in Get-ChildItem -LiteralPath (Join-Path $paths.unit 'Port') -File | Where-Object Extension -In '.c','.cpp') {
    $units += [pscustomobject]@{name=('r4enc_'+$file.Name+'.o');source=$file.FullName;kind=$file.Extension.TrimStart('.')}
}
foreach ($name in @('string','format','stdio','errno')) {
    $units += [pscustomobject]@{name=('shared_'+$name+'.o');source=(Join-Path $shared ($name+'.c'));kind='c'}
}
$units += [pscustomobject]@{name='r4amd_vcn_encode.o';source=(Join-Path $paths.libraries 'R4AMD/Port/vcn_encode.c');kind='c'}
if (@($units.name | Sort-Object -Unique).Count -ne $units.Count) { throw 'Duplicate encoder object name.' }
if (Test-Path -LiteralPath $record) {
    $previous = Get-Content -Raw -LiteralPath $record | ConvertFrom-Json
    if ($previous.identity -eq $id) {
        if ($previous.outputs.Count -ne $units.Count + 2) { throw 'Incomplete encoder output inventory.' }
        foreach ($entry in $previous.outputs) {
            if ((Get-R4EncHash (Join-Path $output $entry.path)) -ne $entry.sha256) { throw "Native encoder cache changed: $($entry.path)" }
        }
        Write-Host "Verified OpenH264 native archive: $output"
        return
    }
    [IO.File]::Delete($record)
}
[IO.Directory]::CreateDirectory($objects) | Out-Null
$flags = @($script:R4SdkNative.data.Build.codegen.'native-flags'.encoder_flags)+@('-isystem',(Join-Path $resource.Trim() 'include'),
    ('-I'+$include),('-I'+$shared),('-I'+(Join-Path $paths.unit 'Port')),('-I'+(Join-Path $paths.libraries 'R4AMD/Port')),
    ('-I'+(Join-Path $paths.unit 'Bindings/C')),('-I'+(Join-Path $paths.sdk 'Shared/C/include')),
    ('-I'+(Join-Path $paths.contract 'Generated/SDK/C/include')), ('-I'+(Join-Path $paths.contract 'Generated/Generation2/C/include')))
foreach ($path in @('codec/api/wels','codec/common/inc','codec/encoder/core/inc','codec/encoder/plus/inc',
        'codec/processing/interface','codec/processing/src/common','codec/processing/src/adaptivequantization',
        'codec/processing/src/downsample','codec/processing/src/scrolldetection','codec/processing/src/vaacalc')) {
    $flags += '-I'+(Join-Path $source $path)
}
$asmFlags = @($script:R4SdkNative.data.Build.codegen.'native-flags'.encoder_asm_flags)+@(('-I'+$source.Replace('\','/')+'/codec/common/x86/'))
$encoderCppFlags=@($script:R4SdkNative.data.Build.codegen.'native-flags'.encoder_cpp_flags)
$encoderCFlags=@($script:R4SdkNative.data.Build.codegen.'native-flags'.encoder_c_flags)
$results = @($units | ForEach-Object -Parallel {
    $entry = $_
    $object = Join-Path $using:objects $entry.name
    $log = $object + '.log'
    if ($entry.kind -eq 'cpp' -or $entry.kind -eq 'c') {
        $options = @($using:flags)
        if ($entry.kind -eq 'cpp') { $options += @($using:encoderCppFlags) }
        else { $options += @($using:encoderCFlags) }
        $options += @('-c',$entry.source,'-o',$object)
        $rsp = $object + '.rsp'
        [IO.File]::WriteAllLines($rsp,@($options | ForEach-Object { '"'+$_.Replace('\','\\').Replace('"','\"')+'"' }),[Text.UTF8Encoding]::new($false))
        & $using:clang ('@'+$rsp) 2> $log
    } elseif ($entry.kind -eq 'asm') {
        $options = @($using:asmFlags) + @('-o',$object,$entry.source)
        & $using:nasm @options 2> $log
    } else { throw 'Unknown encoder source kind.' }
    [pscustomobject]@{name=$entry.name;object=$object;log=$log;success=($LASTEXITCODE -eq 0)}
} -ThrottleLimit $Jobs)
$failed = @($results | Where-Object { !$_.success })
if ($failed.Count) {
    foreach ($entry in $failed | Select-Object -First 8) { Write-Host $entry.name; Get-Content -LiteralPath $entry.log | Select-Object -First 15 | Write-Host }
    throw "OpenH264 compilation failed: $($failed.Count)/$($units.Count). Full diagnostics: $objects"
}
$rsp = Join-Path $output 'archive.rsp'
[IO.File]::WriteAllLines($rsp,@($results | Sort-Object name | ForEach-Object { '"'+$_.object.Replace('\','/')+'"' }),[Text.UTF8Encoding]::new($false))
$pending = Join-Path $output 'R4ENC-OpenH264.pending.a'
[IO.File]::Delete($pending)
& $ar rcs $pending ('@'+$rsp)
if ($LASTEXITCODE) { throw 'OpenH264 archive failed.' }
$archive = Join-Path $output 'R4ENC-OpenH264.a'
[IO.File]::Move($pending,$archive,$true)
$mathOutput = Join-Path $output 'Math'
& pwsh -NoLogo -NoProfile -File (Join-Path $shared 'Math/Build.ps1') -Clang $clang -OutputRoot $mathOutput -IncludeRoot $include -ZigRoot $paths.zig
if ($LASTEXITCODE) { throw 'Shared Math build failed.' }
$outputs = @(@($results.object)+@($archive,(Join-Path $mathOutput 'R4NativeMath.a')) | ForEach-Object {
    [ordered]@{path=[IO.Path]::GetRelativePath($output,$_).Replace('\','/');sha256=(Get-R4EncHash $_)}
})
[ordered]@{schema=1;identity=$id;inputs=$identity;outputs=$outputs;scope='Freestanding objects; runtime ownership and executable encoding require integration.'} |
    ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $record -Encoding utf8NoBOM
Write-Host "Built OpenH264 native archive: $($units.Count) objects plus shared Math."
