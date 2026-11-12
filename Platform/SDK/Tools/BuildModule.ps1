# Shared PS7 owner build used by thin repository launchers on both hosts.
param([Parameter(Mandatory=$true)][string]$ModuleRoot, [string[]]$BuildArguments=@())
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$modulePath=[IO.Path]::GetFullPath($ModuleRoot)
$settings=@{}
foreach($line in Get-Content -LiteralPath (Join-Path $modulePath 'Settings.R4S')){
    if($line -match '^([A-Z_]+)=(.+)$'){$settings[$Matches[1]]=$Matches[2]}
}
function Resolve-ModuleSetting([string]$name,[string]$base){
    if(!$settings.ContainsKey($name)){throw "Missing $name in module Settings.R4S"}
    return [IO.Path]::GetFullPath($settings[$name].Replace('\',[IO.Path]::DirectorySeparatorChar),$base)
}
$sdkPath=Resolve-ModuleSetting SDK_ROOT $modulePath
$contractPath=Resolve-ModuleSetting CONTRACT_ROOT $modulePath
$devkitPath=Resolve-ModuleSetting DEVKIT_ROOT $modulePath
$artifactPath=Resolve-ModuleSetting ARTIFACTS_ROOT $modulePath
$zigPath=Join-Path (Resolve-ModuleSetting ZIG_ROOT $devkitPath) $(if($IsWindows){'zig.exe'}else{'zig'})
. (Join-Path $PSScriptRoot 'BuildContext.ps1')
$librariesPath=Resolve-ModuleSetting LIBRARIES_ROOT $modulePath
$context=Get-R4SdkBuildContext $sdkPath $contractPath $librariesPath $devkitPath ([IO.Path]::GetDirectoryName($zigPath))
Assert-R4SdkBuildArguments $context $BuildArguments
Assert-R4SdkProjectPins $sdkPath $modulePath
Write-Host ('SDK '+$context.data.sdk_version+'; profile sources verified; technical='+$context.resolved.technical)
$moduleManifest=Join-Path $modulePath 'module.R4MF'
$isRust=[IO.File]::ReadAllText($moduleManifest) -match '(?m)^LANGUAGE=Rust\s*$'
$forward=@($BuildArguments)
$hostTests=@($forward|Where-Object {$_ -ceq '-Dhost-tests=true'}).Count -ne 0
if($isRust -and !$hostTests){
    # Use the same standalone manifest/Cargo builder as external consumers.
    # These options describe its fixed size profile/serial build only. Other
    # Zig targets and flags must never silently become a different Rust build.
    foreach($argument in $forward){
        if($argument -cnotin @('install','-j1','-Doptimize=ReleaseSmall')){
            throw "Unsupported Rust owner build argument '$argument'. Use -Dhost-tests=true for owner Zig test targets, or Build-Project.ps1 for explicit Cargo features."
        }
    }
    $toolsPath=Resolve-ModuleSetting RUST_TOOLS_ROOT $modulePath
    $technical=$false
    if($settings.ContainsKey('RUST_TOOLS_TECHNICAL')){
        if($settings.RUST_TOOLS_TECHNICAL -cnotin @('true','false')){throw 'RUST_TOOLS_TECHNICAL must be true or false.'}
        $technical=$settings.RUST_TOOLS_TECHNICAL -ceq 'true'
    }
    $options=@{ProjectRoot=$modulePath;SdkRoot=$sdkPath;ContractRoot=$contractPath;ToolsRoot=$toolsPath;
        InstallRoot=$devkitPath;CacheRoot=(Join-Path $devkitPath '.Cache/Rust');OutputRoot=$artifactPath;
        ZigRoot=([IO.Path]::GetDirectoryName($zigPath));Technical=($technical -or $context.resolved.technical)}
    $options.LibraryHelpersRoot=$librariesPath
    $options.LibrariesRoot=$librariesPath
    if($context.development_profile){$options.DevelopmentProfile=$context.development_profile}
    & (Join-Path $sdkPath 'Tools/Build-Project.ps1') @options
    exit $LASTEXITCODE
}
if($isRust -and !@($forward|Where-Object {!$_.StartsWith('-') -and $_ -cne 'install'}).Count){
    throw 'Select an explicit owner test target with -Dhost-tests=true.'
}
$forkPaths=@($sdkPath,$context.contract_root,$context.libraries_root)
foreach($path in $forkPaths){if(!(Test-Path -LiteralPath (Join-Path $path 'build.zig.zon') -PathType Leaf)){throw "Repository not found: $path"}}
if(!(Test-Path -LiteralPath $zigPath -PathType Leaf)){throw "Zig not found: $zigPath"}
[IO.Directory]::CreateDirectory($artifactPath)|Out-Null
$forks=@($forkPaths|ForEach-Object {'--fork='+$_})
Push-Location $modulePath
try {
    & $zigPath build --prefix $artifactPath @forks @forward
    $buildCode=$LASTEXITCODE
} finally {Pop-Location}
exit $buildCode
