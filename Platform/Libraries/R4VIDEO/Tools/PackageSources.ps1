# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
param([Parameter(Mandatory)][string]$OutputDirectory)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'Common.ps1')
$paths=Get-R4VideoPaths
$output=[IO.Path]::GetFullPath($OutputDirectory)
[IO.Directory]::CreateDirectory($output)|Out-Null
$package=Join-Path $output 'R4VIDEO-SOURCE.tar.gz'
$record=Join-Path $output 'R4VIDEO-SOURCE.json'
$module=Join-Path $paths.unit 'zig-out/R4VIDEO.R4L'
if(!(Test-Path -LiteralPath $module)){throw 'Build the matching R4VIDEO module before packaging its sources.'}
$pin=(Get-Content -Raw (Join-Path $paths.unit 'ThirdParty/Sources.json')|ConvertFrom-Json).sources[0]
$archive=Join-Path $paths.artifacts ('Native/R4VIDEO/Downloads/ffmpeg-'+$pin.version+'.tar.xz')
if((Get-R4VideoHash $archive) -cne $pin.sha256){throw 'FFmpeg source archive hash mismatch.'}
$files=[Collections.Generic.List[string]]::new()
function Add-Tree([string]$Relative){
    $directory=Join-Path $paths.workspace $Relative
    foreach($file in Get-ChildItem -LiteralPath $directory -File){$files.Add([IO.Path]::GetRelativePath($paths.workspace,$file.FullName).Replace('\','/'))}
    foreach($child in Get-ChildItem -LiteralPath $directory -Directory){
        if($child.Name -notin @('.git','.zig-cache','zig-out','zig-pkg','node_modules')){Add-Tree ($Relative+'/'+$child.Name)}
    }
}
foreach($tree in @('Repositories/SDK','Repositories/Contract','Repositories/Libraries/R4VIDEO','Repositories/Libraries/Shared/Native',
    'Repositories/Libraries/R4AMD','Repositories/Libraries/R4NV/Bindings','Repositories/Libraries/R4GFX/Bindings','Repositories/Libraries/R4NAK/ThirdParty/stb')){Add-Tree $tree}
foreach($file in @('Repositories/Libraries/LICENSE','Repositories/Libraries/NOTICE','Repositories/Libraries/THIRD_PARTY_NOTICES.md',
    'Repositories/Libraries/Settings.R4S','Repositories/Libraries/Build.ps1','Repositories/Libraries/Build.sh','Repositories/Libraries/Build.bat',
    'Repositories/Libraries/R4STD/Source/date.zig','Repositories/Libraries/R4NV/Source/video.zig','Repositories/Libraries/R4NV/ThirdParty/Nvidia/LICENSES.txt')){$files.Add($file)}
$files.Add([IO.Path]::GetRelativePath($paths.workspace,$archive).Replace('\','/'))
$entries=@($files|Sort-Object -Unique|ForEach-Object {[ordered]@{path=$_;sha256=Get-R4VideoHash (Join-Path $paths.workspace $_)}})
$identity=[ordered]@{schema=1;module_sha256=Get-R4VideoHash $module;files=$entries}
$id=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($identity|ConvertTo-Json -Depth 6 -Compress)))).ToLowerInvariant()
if((Test-Path $record) -and (Test-Path $package)){
    $prior=Get-Content -Raw $record|ConvertFrom-Json
    if($prior.identity -ceq $id -and $prior.package_sha256 -ceq (Get-R4VideoHash $package)){Write-Host 'R4VIDEO corresponding source package verified.';return}
}
# Temporary lists and pending archives stay in the workspace Temp owner.
$scratch=Join-Path $paths.workspace ('Temp/VideoSources-'+[guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($scratch)|Out-Null
try {
    $list=Join-Path $scratch 'files.txt'
    [IO.File]::WriteAllLines($list,@($entries|ForEach-Object path),[Text.UTF8Encoding]::new($false))
    $pending=Join-Path $scratch 'R4VIDEO-SOURCE.tar.gz'
    & tar -czf $pending -C $paths.workspace -T $list
    if($LASTEXITCODE){throw 'R4VIDEO source archive creation failed.'}
    # Verify every entry before publishing. Rebuild instructions and all port
    # modifications are in R4VIDEO/Tools and Port, original FFmpeg is untouched.
    $listed=@(& tar -tzf $pending)
    if($LASTEXITCODE -or $listed.Count -ne $entries.Count){throw 'Incomplete source archive.'}
    foreach($entry in $entries){if($entry.path -cnotin $listed){throw "Source archive missing $($entry.path)"}}
    [IO.File]::Move($pending,$package,$true)
    [ordered]@{schema=1;identity=$id;module_sha256=$identity.module_sha256;package_sha256=Get-R4VideoHash $package;
        ffmpeg=$pin;files=$entries}|ConvertTo-Json -Depth 7|Set-Content -LiteralPath $record -Encoding utf8NoBOM
} finally {Remove-Item -LiteralPath $scratch -Recurse -Force}
Write-Host "R4VIDEO source package includes $($entries.Count) exact source/build files."
