# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param([switch]$Offline, [string]$OutputFile = '', [switch]$Rebuild, [string]$ResultFile = '')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. ([IO.Path]::GetFullPath('../../Shared/Native/SDK.ps1',$PSScriptRoot))
if (!$IsWindows -and !$IsLinux) { throw 'Supported build hosts: Windows and Linux x64.' }
$unit = [IO.Path]::GetFullPath('..', $PSScriptRoot)
$libraries = [IO.Path]::GetFullPath('../..', $PSScriptRoot)
$settings = @{}
foreach ($line in Get-Content -LiteralPath (Join-Path $libraries 'Settings.R4S')) {
    if ($line -match '^([A-Z_]+)=(.+)$') { $settings[$Matches[1]] = $Matches[2] }
}
function Resolve-Setting([string]$Base,[string]$Name) { [IO.Path]::GetFullPath($settings[$Name].Replace('\',[IO.Path]::DirectorySeparatorChar),$Base) }
$workspace = Resolve-Setting $libraries 'WORKSPACE_ROOT'
$devkit = Resolve-Setting $workspace 'DEVKIT_ROOT'
$hostName = if ($IsWindows) { 'Windows-x64' } else { 'Linux-x64' }
$lock = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'Sources.lock.json') -Raw | ConvertFrom-Json
$mesaTools = [IO.Path]::GetFullPath('../../R4NV/Tools/Compiler',$PSScriptRoot)
$mesaLock = Get-Content -LiteralPath (Join-Path $mesaTools 'Sources.lock.json') -Raw | ConvertFrom-Json
function Hash([string]$Path,[string]$Algorithm='SHA256') { (Get-FileHash -LiteralPath $Path -Algorithm $Algorithm).Hash.ToLowerInvariant() }
function Run([string]$Program,[string[]]$Arguments) { & $Program @Arguments; if($LASTEXITCODE){throw "$Program failed ($LASTEXITCODE)"} }
function Tool([string]$Name) { $t=Get-Command $Name -CommandType Application -ErrorAction Stop | Select-Object -First 1; $t.Source }
$tools = @{rustc=(Tool 'rustc');clang=(Tool $(if($IsWindows){'clang.exe'}else{('clang-'+$script:R4SdkNative.data.Tools.tools.graphics.clang.Split('.')[0])}));bindgen=(Tool 'bindgen');git=(Tool 'git');tar=(Tool 'tar');curl=(Tool 'curl');ninja=(Tool 'ninja')}
$zig = Join-Path (Resolve-Setting $devkit 'ZIG_ROOT') $(if($IsWindows){'zig.exe'}else{'zig'})
$versions=[ordered]@{}
foreach($name in @('rustc','clang','bindgen')) {
    $reported=@(& $tools[$name] --version 2>&1)
    if($LASTEXITCODE -or !$reported.Count -or [string]$reported[0] -notmatch ('(?<![0-9.])'+[regex]::Escape([string]$mesaLock.host_tools.$name)+'(?![0-9.])')) {throw "Pinned $name toolchain required: $($mesaLock.host_tools.$name)"}
    $versions[$name]=[string]$reported[0]
}
foreach($item in $lock.bundled) { if((Hash (Join-Path $unit $item.path)) -ne $item.sha256){throw "Bundled source identity changed: $($item.path)"} }
$inputs=@(foreach($directory in @('Port','Tools','ThirdParty')) {
    Get-ChildItem -LiteralPath (Join-Path $unit $directory) -File -Recurse |
        Where-Object { if($directory -eq 'ThirdParty'){$_.Extension -in @('.c','.h','.rs')}else{$_.Extension -notin @('.md','.txt')} } |
        ForEach-Object { [ordered]@{path=[IO.Path]::GetRelativePath($unit,$_.FullName).Replace('\','/');sha256=(Hash $_.FullName)} }
}) + @(foreach($leaf in @('native.c','native.h')) {[ordered]@{path="Source/$leaf";sha256=(Hash (Join-Path $unit "Source/$leaf"))}})
$inputs=@($inputs | Sort-Object path)
$identity=[ordered]@{sdk_profiles=$script:R4SdkNative.data.hashes;host=$hostName;tools=$versions;mesa_lock=(Hash (Join-Path $mesaTools 'Sources.lock.json'));mesa_patch=(Hash (Join-Path $mesaTools 'MesaStandalone.patch'));inputs=$inputs}
$identityJson=ConvertTo-Json $identity -Depth 10 -Compress
$id=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($identityJson))).ToLowerInvariant()
$buildRoot=Join-Path $devkit "Toolchains/R4NAK/$id"
$archiveOut=Join-Path $buildRoot 'R4NAK.a'
$record=Join-Path $buildRoot 'build.json'
if($Rebuild -and (Test-Path -LiteralPath $buildRoot)){Remove-Item -LiteralPath $buildRoot -Recurse -Force}
if((Test-Path -LiteralPath $record) -and (Test-Path -LiteralPath $archiveOut)) {
    $previous=Get-Content -LiteralPath $record -Raw | ConvertFrom-Json
    if($previous.identity -ne $id -or $previous.archive_sha256 -ne (Hash $archiveOut)){throw 'Native compiler cache is corrupt; use -Rebuild.'}
} else {
    $watch=[Diagnostics.Stopwatch]::StartNew()
    [IO.Directory]::CreateDirectory($buildRoot) | Out-Null
    $cache=Join-Path $devkit '.Cache/R4NAK'
    [IO.Directory]::CreateDirectory($cache) | Out-Null
    $foreign=Join-Path $buildRoot 'Sources'
    [IO.Directory]::CreateDirectory($foreign) | Out-Null
    foreach($item in $lock.archives) {
        $path=Join-Path $cache $item.filename
        if(!(Test-Path -LiteralPath $path) -or (Hash $path) -ne $item.sha256) {
            $reference=Join-Path $workspace ('ExFiles/Reference/GFX/Archives/'+$item.filename)
            if((Test-Path -LiteralPath $reference) -and (Hash $reference) -eq $item.sha256) { Copy-Item -LiteralPath $reference -Destination $path }
            else {
                if($Offline){throw "Offline archive missing: $($item.filename)"}
                $partial=$path+'.part'
                Run $tools.curl @('--fail','--location','--retry','2','--connect-timeout','15','--max-time','300','--output',$partial,$item.url)
                if((Hash $partial) -ne $item.sha256){throw "Archive checksum mismatch: $($item.filename)"}
                Move-Item -LiteralPath $partial -Destination $path -Force
            }
        }
        Run $tools.tar @('-xf',$path,'-C',$foreign)
    }
    # The official pinned Rust archive supplies full notices on both hosts;
    # a Windows installation need not contain a separate rust-docs component.
    & (Join-Path $mesaTools 'Build.ps1') -Offline:$Offline -RustCopyrightFile (Join-Path $foreign ('rust-src-'+$script:R4SdkNative.data.Tools.tools.graphics.rustc+'/COPYRIGHT'))
    if($LASTEXITCODE){throw 'Mesa host preparation failed.'}
    $mesa=Join-Path $devkit ('Toolchains/MesaNAK/'+$mesaLock.mesa.version+'-'+$identity.mesa_patch.Substring(0,16))
    $source=Join-Path $mesa 'Source'
    $hostBuild=Join-Path $mesa ('Build-'+$hostName)
    Run $tools.ninja @('-C',$hostBuild,'src/compiler/spirv/spirv_info.h','src/compiler/spirv/spirv_info.c','src/compiler/spirv/vtn_gather_types.c','src/compiler/spirv/vtn_generator_ids.h','src/util/format/u_format_table.c')
    $overlay=Join-Path $buildRoot 'CSource'
    [IO.Directory]::CreateDirectory($overlay) | Out-Null
    $patch=Join-Path $unit 'Port/MesaGlobals.patch'
    foreach($match in [regex]::Matches([IO.File]::ReadAllText($patch),'(?m)^--- a/(.+)$')) {
        $relative=$match.Groups[1].Value.TrimEnd("`r")
        $dest=Join-Path $overlay $relative
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($dest)) | Out-Null
        Copy-Item -LiteralPath (Join-Path $source $relative) -Destination $dest
    }
    Push-Location ([IO.Path]::GetPathRoot($overlay))
    try { Run $tools.git @('apply','--unsafe-paths',('--directory='+$overlay),'--check',$patch); Run $tools.git @('apply','--unsafe-paths',('--directory='+$overlay),$patch) }
    finally { Pop-Location }
    . (Join-Path $PSScriptRoot 'CInputs.ps1')
    . (Join-Path $PSScriptRoot 'Bindings.ps1')
    . (Join-Path $PSScriptRoot 'PrepareRust.ps1')
    . (Join-Path $PSScriptRoot 'CompileRust.ps1')
    $objectRoot=Join-Path $buildRoot 'Objects'
    [IO.Directory]::CreateDirectory($objectRoot) | Out-Null
    $objects=[Collections.Generic.List[string]]::new()
    $number=0
    foreach($path in $cPaths) {
        $obj=Join-Path $objectRoot (([string]$number)+'-'+[IO.Path]::GetFileName($path)+'.o')
        Run $tools.clang ($cArgs+@('-c',$path,'-o',$obj))
        $objects.Add($obj); $number++
    }
    # Flatten the Rust static library. Nested archives are not a linker input.
    Push-Location $objectRoot
    try { Run $zig @('ar','x',(Join-Path $buildRoot 'RustBuild/libnak_rs.a')) }
    finally { Pop-Location }
    $allObjects=@(Get-ChildItem -LiteralPath $objectRoot -Filter '*.o' -File | Sort-Object Name | ForEach-Object FullName)
    $response=Join-Path $buildRoot 'archive.rsp'
    [IO.File]::WriteAllLines($response,@($allObjects | ForEach-Object {'"'+$_.Replace('\','/').Replace('"','\"')+'"'}))
    Run $zig @('ar','rcsD',$archiveOut,('@'+$response))
    $watch.Stop()
    [ordered]@{schema=1;identity=$id;inputs=$identity;archive_sha256=(Hash $archiveOut);archive_bytes=(Get-Item -LiteralPath $archiveOut).Length;build_seconds=[math]::Round($watch.Elapsed.TotalSeconds,2);c_units=$cPaths.Count;rust_target=$lock.target;runtime='freestanding core/alloc; no host libc, std, TLS or filesystem'} | ConvertTo-Json -Depth 12 | Set-Content -LiteralPath $record -Encoding utf8NoBOM
}
if($OutputFile) {
    $destination=[IO.Path]::GetFullPath($OutputFile,$workspace)
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
    Copy-Item -LiteralPath $archiveOut -Destination $destination -Force
}
Write-Host "R4NAK native archive: $archiveOut"
if ($ResultFile) {
    $destination = [IO.Path]::GetFullPath($ResultFile, $workspace)
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($destination)) | Out-Null
    [ordered]@{
        schema = 1; identity = $id
        root = [IO.Path]::GetRelativePath($workspace, $buildRoot).Replace('\', '/')
        record_sha256 = (Hash $record); archive_sha256 = (Hash $archiveOut)
    } | ConvertTo-Json | Set-Content -LiteralPath $destination -Encoding utf8NoBOM
}
