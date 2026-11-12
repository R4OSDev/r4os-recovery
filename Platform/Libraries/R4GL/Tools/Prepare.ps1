# Copyright 2026 R4. SPDX-License-Identifier: Apache-2.0
[CmdletBinding()]
param([Parameter(Mandatory)][string]$OutputRoot, [switch]$Offline)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
. ([IO.Path]::GetFullPath('../../Shared/Native/SDK.ps1',$PSScriptRoot))
if (!$IsWindows -and !$IsLinux) { throw 'Supported hosts: Windows and Linux.' }
$unit=[IO.Path]::GetFullPath('..',$PSScriptRoot)
$libraries=[IO.Path]::GetFullPath('../..',$PSScriptRoot)
. (Join-Path $PSScriptRoot 'Common.ps1')
$paths=Get-R4GLPaths
$sourceOptions=@('-PrepareSources')
if($Offline){$sourceOptions+='-Offline'}
Invoke-R4GLScript (Join-Path $libraries 'R4NV/Tools/Compiler/Build.ps1') $sourceOptions
. (Join-Path $libraries 'R4VK/Tools/MesaSource.ps1')
$mesa=Get-R4VKMesaSource
$output=[IO.Path]::GetFullPath($OutputRoot,$mesa.workspace)
$artifacts=Join-Path $paths.artifacts 'Native/R4GL'
if (!$output.StartsWith($artifacts+[IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
    throw 'R4GL preparation output must be a child of Artifacts/Native/R4GL.'
}
$source=Join-Path $output 'Source'
$generated=Join-Path $output 'Generated'
$recordPath=Join-Path $output 'prepare.json'
$patchPlan=Get-Content -Raw (Join-Path $PSScriptRoot 'Patches.json')|ConvertFrom-Json
$plan=Get-Content -Raw (Join-Path $PSScriptRoot 'Generators.json')|ConvertFrom-Json
if ($plan.schema -ne 1 -or $plan.mesa -ne $mesa.lock.mesa.version -or $patchPlan.schema -ne 1) { throw 'R4GL source plan differs from the pinned provider.' }
function Hash([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Tool([string[]]$Names) {
    foreach($name in $Names){
        $command=Get-Command $name -CommandType Application -ErrorAction SilentlyContinue|Select-Object -First 1
        if($command){return $command.Source}
    }
    throw ('Required R4GL generator unavailable: '+($Names -join ', '))
}
$tools=@{
    python=(Tool $(if($IsWindows){@('python.exe','python3.exe')}else{@('python3')}))
    bison=(Tool $(if($IsWindows){@('win_bison.exe','bison.exe')}else{@('bison')}))
    flex=(Tool $(if($IsWindows){@('win_flex.exe','flex.exe')}else{@('flex')}))
    glslangValidator=(Tool @('glslangValidator'))
    git=(Tool @('git'))
}
$inputs=@($mesa.lock_path,$mesa.manifest_path,$PSCommandPath,(Join-Path $PSScriptRoot 'Common.ps1'),(Join-Path $libraries 'R4VK/Tools/MesaSource.ps1'),
    (Join-Path $PSScriptRoot 'Patches.json'),(Join-Path $PSScriptRoot 'Generators.json'))
$inputs+=@($patchPlan.patches|ForEach-Object {Join-Path $unit $_})
$identities=@($inputs|ForEach-Object {[ordered]@{path=[IO.Path]::GetRelativePath($mesa.workspace,$_).Replace('\','/');sha256=(Hash $_)}})
$versions=[ordered]@{}
foreach($name in @('python','bison','flex','glslangValidator')) {
    $reported=@(& $tools[$name] --version)
    if($LASTEXITCODE -or !$reported.Count){throw "Generator version unavailable: $name"}
    $versions[$name]=[string]$reported[0]
}
$identity=[ordered]@{sdk_profiles=$script:R4SdkNative.data.hashes;schema=1;host=$(if($IsWindows){'Windows-x64'}else{'Linux-x64'});tools=$versions;inputs=$identities}
$id=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes(($identity|ConvertTo-Json -Depth 7 -Compress)))).ToLowerInvariant()
if(Test-Path $recordPath){
    $previous=Get-Content -Raw $recordPath|ConvertFrom-Json
    if($previous.identity -eq $id){
        foreach($file in $previous.outputs){if((Hash (Join-Path $output $file.path)) -ne $file.sha256){throw "Prepared R4GL input changed: $($file.path)"}}
        Write-Host "Verified native GL preparation: $output"
        return
    }
    Remove-Item -LiteralPath $recordPath
}
# These two directories are owned exclusively by this preparation cache.
foreach($directory in @($source,$generated)){if(Test-Path $directory){Remove-Item -LiteralPath $directory -Recurse -Force}}
[IO.Directory]::CreateDirectory($output)|Out-Null
Copy-Item -LiteralPath $mesa.source -Destination $source -Recurse
[IO.Directory]::CreateDirectory($generated)|Out-Null
Push-Location ([IO.Path]::GetPathRoot($source))
try{
    foreach($relative in $patchPlan.patches){
        $patch=Join-Path $unit $relative
        & $tools.git apply --unsafe-paths ('--directory='+$source) --check $patch
        if($LASTEXITCODE){throw "R4GL patch check failed: $relative"}
        & $tools.git apply --unsafe-paths ('--directory='+$source) $patch
        if($LASTEXITCODE){throw "R4GL patch failed: $relative"}
    }
}finally{Pop-Location}
$oldBytecode=[Environment]::GetEnvironmentVariable('PYTHONDONTWRITEBYTECODE','Process')
try{
    [Environment]::SetEnvironmentVariable('PYTHONDONTWRITEBYTECODE','1','Process')
    foreach($step in $plan.steps){
        foreach($relative in $step.outputs){
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName((Join-Path $generated $relative)))|Out-Null
        }
        if($step.PSObject.Properties['text']){
            [IO.File]::WriteAllText((Join-Path $generated $step.outputs[0]),[string]$step.text,[Text.UTF8Encoding]::new($false))
            continue
        }
        $info=[Diagnostics.ProcessStartInfo]::new()
        $info.FileName=$tools[$step.tool];$info.WorkingDirectory=$generated;$info.UseShellExecute=$false
        $info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true
        foreach($argument in $step.arguments){$info.ArgumentList.Add(([string]$argument).Replace('${source}',$source).Replace('${generated}',$generated))}
        $process=[Diagnostics.Process]::Start($info)
        $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
        $process.WaitForExit()
        $text=$stdout.GetAwaiter().GetResult();$errors=$stderr.GetAwaiter().GetResult();$code=$process.ExitCode
        $process.Dispose()
        if($code){throw "Generator failed ($code), $($step.outputs -join ', '): $errors"}
        if($step.PSObject.Properties['capture']){[IO.File]::WriteAllText((Join-Path $generated $step.capture),$text,[Text.UTF8Encoding]::new($false))}
        foreach($relative in $step.outputs){if(!(Test-Path -LiteralPath (Join-Path $generated $relative))){throw "Generator omitted $relative"}}
    }
}finally{[Environment]::SetEnvironmentVariable('PYTHONDONTWRITEBYTECODE',$oldBytecode,'Process')}
$files=@(foreach($directory in @($source,$generated)){
    Get-ChildItem -LiteralPath $directory -File -Recurse|Sort-Object FullName|ForEach-Object {
        [ordered]@{path=[IO.Path]::GetRelativePath($output,$_.FullName).Replace('\','/');sha256=(Hash $_.FullName)}
    }
})
[ordered]@{schema=1;identity=$id;inputs=$identity;outputs=$files}|ConvertTo-Json -Depth 8|Set-Content -LiteralPath $recordPath -Encoding utf8NoBOM
Write-Host "Prepared native Mesa GL source and $($plan.steps.Count) generator steps: $output"
