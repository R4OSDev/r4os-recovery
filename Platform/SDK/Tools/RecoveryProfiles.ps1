. (Join-Path $PSScriptRoot 'BuildContext.ps1')

function Get-R4SdkRecoveryContext {
    param([Parameter(Mandatory)][string]$RecoveryRoot,[string]$Zig='', [string]$DevelopmentProfile='')
    $sdk=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
    $root=[IO.Path]::GetFullPath($RecoveryRoot)
    if(!$DevelopmentProfile){$DevelopmentProfile=$env:R4OS_SDK_DEVELOPMENT_PROFILE}
    $configuration=Read-R4SdkProfiles $sdk
    $librarySource=$configuration.Components.repositories['recovery-libraries']
    if(!$librarySource.ContainsKey('source_subdir')){throw 'RecoverySdkLibraryTreeRequired'}
    $libraryRoot=Join-Path $root $librarySource.source_subdir
    $roots=@{'recovery-sdk'=(Join-Path $root 'Platform/SDK');'recovery-contract'=(Join-Path $root 'Platform/Contract');'recovery-libraries'=$libraryRoot}
    $options=@{SdkRoot=$sdk;Profile='r4os-recovery-zig-v1';Roots=$roots}
    if($DevelopmentProfile){$options.DevelopmentProfile=$DevelopmentProfile}
    $resolved=Resolve-R4SdkComponents @options
    $data=Read-R4SdkProfiles $sdk
    if(!$Zig){$Zig=Join-Path ([IO.Path]::GetFullPath('../..',$sdk)) $(if($IsWindows){'DevKit/Toolchains/Zig/zig.exe'}else{'DevKit/Toolchains/Zig/zig'})}
    $Zig=[IO.Path]::GetFullPath($Zig)
    $project=[IO.File]::ReadAllText((Join-Path $root 'Kernel/build.zig.zon'))
    $projection=$data.Components.repositories['recovery-contract']
    if([regex]::Match($project,'\.url\s*=\s*"([^"]+)"').Groups[1].Value -cne $projection.zig_archive_url -or
       [regex]::Match($project,'\.hash\s*=\s*"([^"]+)"').Groups[1].Value -cne $projection.zig_hash){throw 'RecoverySdkContractProjectionMismatch'}
    $version=(@(& $Zig version)-join '').Trim()
    if($LASTEXITCODE -ne 0 -or $version -cne $data.Tools.tools.zig.version){throw 'RecoverySdkZigMismatch'}
    return @{root=$root;sdk_root=$sdk;zig=$Zig;data=$data;resolved=$resolved;development_profile=$DevelopmentProfile}
}

function New-R4SdkRecoveryOverlay($Context) {
    $base=$Context.resolved.sources['recovery-sdk'].root
    $output=Join-Path $Context.root 'Artifacts/SDKProfile/SDK'
    # This directory is solely SDK-generated; original frozen sources/archives
    # remain unchanged. A new overlay cannot inherit obsolete generated files.
    if(Test-Path -LiteralPath $output){Remove-Item -LiteralPath $output -Recurse -Force}
    foreach($relative in $Context.resolved.sources['recovery-sdk'].files){
        $target=Join-Path $output $relative
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))|Out-Null
        [IO.File]::Copy((Join-Path $base $relative),$target,$true)
    }
    if(!(Test-Path -LiteralPath (Join-Path $output 'r4os/build_profile.zig'))) { throw 'RecoverySdkCurrentJsonProfileRequired' }
    # Current SDK sources interpret one Build.json instead of embedding
    # compiler switches in build.zig. Project the selected Recovery policy
    # into this generated overlay; never patch the pinned owner snapshot.
    $projected=($Context.data.Build|ConvertTo-Json -Depth 100)|ConvertFrom-Json -AsHashtable -Depth 100
    $recovery=$Context.data.Build.codegen.'recovery-module'
    $module=$projected.codegen.module
    foreach($key in @('single_threaded','strip','pic','red_zone','sanitize_c','stack_check','stack_protector','link_emit_relocs')) {
        $module[$key]=$recovery[$key]
    }
    $module.optimization.size=$recovery.optimize_size
    $module.optimization.speed=$recovery.optimize_speed
    $module.c_flags=@($recovery.c_flags)
    $projected.codegen.host.optimize=$recovery.host_optimize
    $projected.codegen.host.packager_optimize=$recovery.contract_generator_optimize
    $policy=Join-Path $output 'Profiles/Build.json'
    [IO.File]::WriteAllText($policy,($projected|ConvertTo-Json -Depth 100)+"`n",[Text.UTF8Encoding]::new($false))
    & (Join-Path $PSScriptRoot 'Sync-ProfilePolicy.ps1') -SdkRoot $output
    $record=@{schema=1;technical=$Context.resolved.technical;sdk_version=$Context.data.sdk_version;profile=$Context.resolved.profile;hashes=$Context.data.hashes;frozen_sources=$Context.resolved.sources;overlay=@{kind='current-sdk-json';sdk_build_sha256=(Get-R4SdkFileDigest (Join-Path $output 'r4os/build.zig'));policy_sha256=(Get-R4SdkFileDigest $policy);source_policy='codegen.recovery-module'}}
    $recordPath=Join-Path $Context.root 'Artifacts/SDKProfile/profile.json'
    [IO.File]::WriteAllText($recordPath,($record|ConvertTo-Json -Depth 100)+"`n",[Text.UTF8Encoding]::new($false))
    return $output
}
