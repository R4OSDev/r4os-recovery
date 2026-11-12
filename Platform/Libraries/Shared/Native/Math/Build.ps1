# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
param(
 [Parameter(Mandatory)][string]$Clang,
 [Parameter(Mandatory)][string]$OutputRoot,
 [Parameter(Mandatory)][string]$IncludeRoot,
 [string]$ZigRoot = ''
)
$ErrorActionPreference='Stop'
. ([IO.Path]::GetFullPath('../SDK.ps1',$PSScriptRoot))
Set-StrictMode -Version Latest
$workspace=[IO.Path]::GetFullPath('../../../../..',$PSScriptRoot)
if (!$ZigRoot) { $ZigRoot=[IO.Path]::GetDirectoryName($script:R4SdkNative.zig) }
$manifest=Get-Content (Join-Path $PSScriptRoot 'Sources.json') -Raw|ConvertFrom-Json
[IO.Directory]::CreateDirectory($OutputRoot)|Out-Null
foreach($file in $manifest.files){
 $path=Join-Path $zigRoot $file.path
 if((Get-FileHash $path).Hash.ToLowerInvariant() -ne $file.sha256){throw "Native math source pin mismatch: $($file.path)"}
}
Assert-R4SdkNativeCompiler $script:R4SdkNative $Clang
$resource=(& $Clang -print-resource-dir).Trim()
if($LASTEXITCODE){throw 'Native math compiler resource lookup failed'}
$flags=@($script:R4SdkNative.data.Build.codegen.'native-flags'.math_flags)+@(
 ('-I'+(Join-Path $PSScriptRoot 'Include')),('-I'+$IncludeRoot),
 '-isystem',(Join-Path $resource 'include'),
 ('-I'+(Join-Path $zigRoot 'lib/libc/musl/src/internal')),
 ('-I'+(Join-Path $zigRoot 'lib/libc/musl/arch/generic')))
$objects=@()
$records=@()
foreach($relative in $manifest.c_units){
 $source=Join-Path $zigRoot $relative
 $object=Join-Path $OutputRoot ([IO.Path]::GetFileNameWithoutExtension($relative)+'.o')
 & $Clang @flags -c $source -o $object
 if($LASTEXITCODE){throw "Native math compilation failed: $relative"}
 $objects+=$object
 $records+=[ordered]@{source=$relative;object=[IO.Path]::GetFileName($object);sha256=(Get-FileHash $object).Hash.ToLowerInvariant()}
}
# The archive belongs to the caller's build directory. Replace it only after
# all selected objects compiled successfully; never publish a partial archive.
$ar=Join-Path ([IO.Path]::GetDirectoryName($Clang)) $(if($IsWindows){'llvm-ar.exe'}else{'llvm-ar'})
if(!(Test-Path $ar)){$ar=(Get-Command llvm-ar-19 -CommandType Application | Select-Object -First 1).Source}
$pending=Join-Path $OutputRoot 'R4NativeMath.pending.a'
[IO.File]::Delete($pending)
& $ar rcs $pending @objects
if($LASTEXITCODE){throw 'Native math archiving failed'}
$archive=Join-Path $OutputRoot 'R4NativeMath.a'
[IO.File]::Move($pending,$archive,$true)
$toolVersion=@(& $Clang --version)
if($LASTEXITCODE){throw 'Native math compiler identity failed'}
[ordered]@{schema=1;target=$manifest.target;units=$objects.Count;compiler=$toolVersion[0];
 flags=$flags;source_manifest_sha256=(Get-FileHash (Join-Path $PSScriptRoot 'Sources.json')).Hash.ToLowerInvariant();
 archive_sha256=(Get-FileHash $archive).Hash.ToLowerInvariant();objects=$records
}|ConvertTo-Json -Depth 5|Set-Content (Join-Path $OutputRoot 'native-math.json') -Encoding utf8NoBOM
Write-Host "Native math archive: $($objects.Count) original C units"
