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
$sourceRoot=Join-Path $OutputRoot 'Source'
[IO.Directory]::CreateDirectory($sourceRoot)|Out-Null
foreach($file in $manifest.files){
 $path=Join-Path $zigRoot $file.path
 if((Get-FileHash $path).Hash.ToLowerInvariant() -ne $file.sha256){throw "Native scan source pin mismatch: $($file.path)"}
 if($file.path -match '\.(c|h)$'){
  # Original source bytes, with private stdio/math adapters found through the
  # include path. Never pick up musl's Linux FILE layout beside the source.
  Copy-Item -LiteralPath $path -Destination (Join-Path $sourceRoot ([IO.Path]::GetFileName($path)))
 }
}
Assert-R4SdkNativeCompiler $script:R4SdkNative $Clang
$resource=(& $Clang -print-resource-dir).Trim()
if($LASTEXITCODE){throw 'Native scan compiler resource lookup failed'}
$flags=@($script:R4SdkNative.data.Build.codegen.'native-flags'.scan_flags)+@(
 ('-I'+(Join-Path $PSScriptRoot 'Include')),('-I'+$IncludeRoot),
 '-isystem',(Join-Path $resource 'include'),('-I'+$sourceRoot))
$objects=@()
$records=@()
foreach($relative in $manifest.c_units){
 $source=Join-Path $sourceRoot ([IO.Path]::GetFileName($relative))
 $object=Join-Path $OutputRoot ([IO.Path]::GetFileNameWithoutExtension($relative)+'.o')
 & $Clang @flags -c $source -o $object
 if($LASTEXITCODE){throw "Native scan compilation failed: $relative"}
 $objects+=$object
 $records+=[ordered]@{source=$relative;object=[IO.Path]::GetFileName($object);sha256=(Get-FileHash $object).Hash.ToLowerInvariant()}
}
foreach($name in @('convert','format_scan','scan_string')){
 $adapter=Join-Path $PSScriptRoot ($name+'.c')
 $object=Join-Path $OutputRoot ($name+'.o')
 & $Clang @flags -c $adapter -o $object
 if($LASTEXITCODE){throw "Native scan adapter failed: $name"}
 $objects+=$object
 $records+=[ordered]@{source=('R4OS:'+$name+'.c');source_sha256=(Get-FileHash $adapter).Hash.ToLowerInvariant();object=($name+'.o');sha256=(Get-FileHash $object).Hash.ToLowerInvariant()}
}
$ar=Join-Path ([IO.Path]::GetDirectoryName($Clang)) $(if($IsWindows){'llvm-ar.exe'}else{'llvm-ar'})
if(!(Test-Path $ar)){$ar=(Get-Command llvm-ar-19 -CommandType Application | Select-Object -First 1).Source}
$pending=Join-Path $OutputRoot 'R4NativeScan.pending.a'
[IO.File]::Delete($pending)
& $ar rcs $pending @objects
if($LASTEXITCODE){throw 'Native scan archiving failed'}
$archive=Join-Path $OutputRoot 'R4NativeScan.a'
[IO.File]::Move($pending,$archive,$true)
$toolVersion=@(& $Clang --version)
if($LASTEXITCODE){throw 'Native scan compiler identity failed'}
[ordered]@{schema=1;target=$manifest.target;units=$objects.Count;compiler=$toolVersion[0];
 flags=$flags;source_manifest_sha256=(Get-FileHash (Join-Path $PSScriptRoot 'Sources.json')).Hash.ToLowerInvariant();
 archive_sha256=(Get-FileHash $archive).Hash.ToLowerInvariant();objects=$records
}|ConvertTo-Json -Depth 5|Set-Content (Join-Path $OutputRoot 'native-scan.json') -Encoding utf8NoBOM
Write-Host "Native scan archive: $($manifest.c_units.Count) original C units plus 3 adapters"
