. (Join-Path $PSScriptRoot 'ProfileResolver.ps1')

function Read-R4BuildSettings([string]$Root) {
    $result=@{}
    foreach($line in [IO.File]::ReadAllLines((Join-Path $Root 'Settings.R4S'))){
        $line=$line.Trim().TrimStart([char]0xFEFF)
        if(!$line -or $line.StartsWith('#')){continue}
        if($line -notmatch '^([A-Z_]+)=(.+)$'){throw 'SdkBuildInvalidPathSetting'}
        $result[$Matches[1]]=$Matches[2]
    }
    return $result
}

function Get-R4SdkBuildContext {
    param([string]$SdkRoot,[string]$ContractRoot,[string]$LibrariesRoot,[string]$InstallRoot,
          [string]$ZigRoot='', [string]$Profile='r4os-zig-module-v1', [string]$DevelopmentProfile='')
    if(!$DevelopmentProfile){$DevelopmentProfile=$env:R4OS_SDK_DEVELOPMENT_PROFILE}
    $data=Read-R4SdkProfiles $SdkRoot
    $roots=@{contract=$ContractRoot;libraries=$LibrariesRoot}
    $options=@{SdkRoot=$SdkRoot;Profile=$Profile;Roots=$roots}
    if($DevelopmentProfile){$options.DevelopmentProfile=$DevelopmentProfile}
    $resolved=Resolve-R4SdkComponents @options
    if(!$ZigRoot){$ZigRoot=Join-Path $InstallRoot 'Toolchains/Zig'}
    $zig=Join-Path ([IO.Path]::GetFullPath($ZigRoot)) $(if($IsWindows){'zig.exe'}else{'zig'})
    if(!(Test-Path -LiteralPath $zig -PathType Leaf)){throw 'SdkBuildZigMissing'}
    $version=(@(& $zig version)-join '').Trim()
    if($LASTEXITCODE -ne 0 -or $version -cne $data.Tools.tools.zig.version){throw 'SdkBuildZigIdentityMismatch'}
    return [ordered]@{sdk_root=[IO.Path]::GetFullPath($SdkRoot);contract_root=$resolved.sources.contract.root;
        libraries_root=$resolved.sources.libraries.root;install_root=[IO.Path]::GetFullPath($InstallRoot);
        zig=$zig;data=$data;resolved=$resolved;development_profile=$DevelopmentProfile}
}

function Assert-R4SdkBuildArguments($Context, [string[]]$Arguments) {
    $allowedModes=if($Context.Contains('resolved') -and $Context.resolved.build.role -ceq 'host'){$Context.data.Build.codegen.host.allowed_optimize_modes}else{$Context.data.Build.codegen.module.allowed_optimize_modes}
    foreach($argument in $Arguments){
        if($argument.StartsWith('--fork',[StringComparison]::Ordinal) -or
           $argument.StartsWith('-Dr4os-sdk',[StringComparison]::Ordinal) -or
           $argument.StartsWith('-Dr4os-r4xbuilder',[StringComparison]::Ordinal) -or
           $argument.StartsWith('-Dr4os-r4l-contract-gen',[StringComparison]::Ordinal)){
            throw "SdkBuildComponentOverrideForbidden: $argument"
        }
        if($argument -cmatch '^-Doptimize=(.+)$' -and
           $Matches[1] -cnotin $allowedModes){throw "SdkBuildOptimizationOverride: $argument"}
    }
    foreach($name in @('ZIG_LIB_DIR','ZIG_LIBC','RUSTFLAGS','CARGO_ENCODED_RUSTFLAGS')){
        if([Environment]::GetEnvironmentVariable($name,'Process')){throw "SdkBuildEnvironmentOverride: $name"}
    }
}

# Technical dependency projections may be stored in project manifests. They
# never select a different platform set from the SDK chosen by the caller.
function Assert-R4SdkProjectPins([string]$SdkRoot,[string]$ProjectRoot) {
    if(Test-Path -LiteralPath (Join-Path $ProjectRoot 'build.zig.zon')){
        & (Join-Path $SdkRoot 'Tools/Sync-ComponentPins.ps1') -SdkRoot $SdkRoot -ProjectRoot $ProjectRoot
    }
}

function Assert-R4SdkBootTools([string]$SdkRoot,[string]$Qemu='', [string]$LimineRoot='') {
    $data=Read-R4SdkProfiles $SdkRoot
    $hostName=if($IsWindows){'Windows'}elseif($IsLinux){'Linux'}else{throw 'SdkBootHostUnsupported'}
    if($Qemu){
        if(!(Test-Path -LiteralPath $Qemu -PathType Leaf)){throw 'SdkQemuMissing'}
        $lines=@(& $Qemu --version 2>&1)
        $line=if($lines.Count){[string]$lines[0]}else{''}
        $prefix='QEMU emulator version '+$data.Tools.tools.qemu.hosts[$hostName].version+' '
        if($LASTEXITCODE -ne 0 -or !$line.StartsWith($prefix,[StringComparison]::Ordinal)){throw 'SdkQemuVersionMismatch'}
    }
    if($LimineRoot){
        $program=Join-Path $LimineRoot $(if($IsWindows){'limine-tool-windows-x86/limine.exe'}else{'limine'})
        if(!(Test-Path -LiteralPath $program -PathType Leaf)){throw 'SdkLimineMissing'}
        $lines=@(& $program --version 2>&1)
        $line=if($lines.Count){[string]$lines[0]}else{''}
        if($LASTEXITCODE -ne 0 -or $line -cne ('Limine '+$data.Tools.tools.limine.version)){throw 'SdkLimineVersionMismatch'}
    }
}
