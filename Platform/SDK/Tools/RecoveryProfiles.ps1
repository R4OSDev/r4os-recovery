. (Join-Path $PSScriptRoot 'BuildContext.ps1')

function Get-R4SdkRecoveryContext {
    param([Parameter(Mandatory)][string]$RecoveryRoot,[string]$Zig='', [string]$DevelopmentProfile='')
    $sdk=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
    $root=[IO.Path]::GetFullPath($RecoveryRoot)
    if(!$DevelopmentProfile){$DevelopmentProfile=$env:R4OS_SDK_DEVELOPMENT_PROFILE}
    $roots=@{'recovery-sdk'=(Join-Path $root 'Platform/SDK');'recovery-contract'=(Join-Path $root 'Platform/Contract');'recovery-libraries'=(Join-Path $root 'Legal/Sources/Libraries.zip')}
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
    $profile=$Context.data.Build.codegen.'recovery-module'
    $lines=[Collections.Generic.List[string]]::new()
    $lines.Add('// Generated solely from selected SDK Profiles/Build.json. Do not edit.')
    $lines.Add('const std = @import("std");')
    foreach($key in @('optimize_size','optimize_speed','host_optimize','contract_generator_optimize')){
        $value=[string]$profile[$key]
        if($value -cnotin @('Debug','ReleaseSmall','ReleaseFast','ReleaseSafe')){throw 'RecoverySdkOptimizationInvalid'}
        $lines.Add('pub const '+$key+': std.builtin.OptimizeMode = .'+$value+';')
    }
    foreach($key in @('single_threaded','strip','pic','red_zone','stack_check','stack_protector','link_emit_relocs')){
        if($profile[$key] -isnot [bool]){throw 'RecoverySdkBooleanInvalid'}
        $lines.Add('pub const '+$key+' = '+$profile[$key].ToString().ToLowerInvariant()+';')
    }
    if($profile.sanitize_c -cne 'off'){throw 'RecoverySdkSanitizerUnsupported'}
    $lines.Add('pub const sanitize_c: std.zig.SanitizeC = .off;')
    $features=@(foreach($feature in $profile.cpu_features_add){
        if($feature -cnotmatch '^[a-z0-9_]+$'){throw 'RecoverySdkFeatureInvalid'}
        '.'+$feature
    })
    $lines.Add('pub const cpu_features_add = std.Target.x86.featureSet(&.{'+($features -join ',')+'});')
    $flags=@(foreach($flag in $profile.c_flags){ConvertTo-Json -InputObject ([string]$flag) -Compress})
    $lines.Add('pub const c_flags: []const []const u8 = &.{'+($flags -join ',')+'};')
    $policy=Join-Path $output 'r4os/recovery_policy.zig'
    [IO.File]::WriteAllText($policy,($lines -join "`n")+"`n",[Text.UTF8Encoding]::new($false))
    $path=Join-Path $output 'r4os/build.zig';$text=[IO.File]::ReadAllText($path)
    $text='const recovery_policy = @import("recovery_policy.zig");'+"`n"+$text
    $cpuPattern='(?s)\.cpu_features_add = std\.Target\.x86\.featureSet\(&\.\{.*?\}\)'
    if([regex]::Matches($text,$cpuPattern).Count -ne 2){throw 'RecoverySdkCompatibilityCpuShapeChanged'}
    $text=[regex]::Replace($text,$cpuPattern,'.cpu_features_add = recovery_policy.cpu_features_add')
    $flagsPattern='(?s)const base_c_flags: \[\]const \[\]const u8 = &\.\{.*?\n    \};'
    if([regex]::Matches($text,$flagsPattern).Count -ne 2){throw 'RecoverySdkCompatibilityFlagsShapeChanged'}
    $text=[regex]::Replace($text,$flagsPattern,'const base_c_flags = recovery_policy.c_flags;')
    foreach($pair in @(@('ReleaseSmall','optimize_size'),@('ReleaseFast','optimize_speed'),@('ReleaseSafe','contract_generator_optimize'))){$text=$text.Replace(('.'+$pair[0]),('recovery_policy.'+$pair[1]))}
    $text=$text.Replace('b.standardOptimizeOption(.{})','recovery_policy.host_optimize')
    foreach($key in @('single_threaded','strip','pic','red_zone','stack_check','stack_protector')){
        $text=[regex]::Replace($text,('\.'+$key+' = (true|false),'),('.'+$key+' = recovery_policy.'+$key+','))
    }
    $text=$text.Replace('.sanitize_c = .off,','.sanitize_c = recovery_policy.sanitize_c,')
    $text=$text.Replace('exe.link_emit_relocs = true;','exe.link_emit_relocs = recovery_policy.link_emit_relocs;')
    [IO.File]::WriteAllText($path,$text,[Text.UTF8Encoding]::new($false))
    $record=@{schema=1;technical=$Context.resolved.technical;sdk_version=$Context.data.sdk_version;profile=$Context.resolved.profile;hashes=$Context.data.hashes;frozen_sources=$Context.resolved.sources;overlay=@{sdk_build_sha256=(Get-R4SdkFileDigest $path);policy_sha256=(Get-R4SdkFileDigest $policy)}}
    $recordPath=Join-Path $Context.root 'Artifacts/SDKProfile/profile.json'
    [IO.File]::WriteAllText($recordPath,($record|ConvertTo-Json -Depth 100)+"`n",[Text.UTF8Encoding]::new($false))
    return $output
}
