param([string]$SdkRoot='', [switch]$Check)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
if(!$SdkRoot){$SdkRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))}
$source=Join-Path $SdkRoot 'Profiles/Build.json'
$text=[IO.File]::ReadAllText($source).Replace("`r`n","`n")
$data=$text|ConvertFrom-Json -AsHashtable -Depth 100
if($data.schema -ne 1){throw 'SdkProfileSchemaMismatch: Build'}
$hash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($text))).ToLowerInvariant()
$lines=[Collections.Generic.List[string]]::new()
$lines.Add('// Generated from Profiles/Build.json by Tools/Sync-ProfilePolicy.ps1. DO NOT EDIT.')
$lines.Add('pub const source_sha256 = "'+$hash+'";')
$lines.Add('pub const Profile = struct { id: []const u8, language: []const u8, role: []const u8, kind: []const u8, generation: u8, explicit_platform: bool };')
$lines.Add('pub const profiles = [_]Profile{')
$ids=[string[]]@($data.profiles.Keys)
[Array]::Sort($ids,[StringComparer]::Ordinal)
foreach($id in $ids){
    $profile=$data.profiles[$id]
    $explicit=$profile.ContainsKey('platform')
    $platform=if($explicit){$profile.platform}else{'platform1'}
    $kind=if($profile.ContainsKey('kind')){[string]$profile.kind}else{''}
    foreach($value in @($id,$profile.language,$profile.role)){
        if($value -cnotmatch '^[A-Za-z0-9_+.-]+$'){throw 'SdkProfileProjectionStringInvalid'}
    }
    $generation=$data.platforms[$platform].generation
    if($generation -notin @(1,2)){throw 'SdkProfileProjectionGenerationInvalid'}
    if($kind -and $kind -cnotin @('R4X','R4D','R4P','R4L')){throw 'SdkProfileProjectionKindInvalid'}
    $lines.Add('    .{ .id = "'+$id+'", .language = "'+$profile.language+'", .role = "'+$profile.role+'", .kind = "'+$kind+'", .generation = '+$generation+', .explicit_platform = '+$explicit.ToString().ToLowerInvariant()+' },')
}
$lines.Add('};')
$lines.Add('pub const ModuleDefault = struct { language: []const u8, kind: []const u8, entry: []const u8, profile: []const u8 };')
$lines.Add('pub const module_defaults = [_]ModuleDefault{')
$seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach($item in $data.module_defaults){
    $key=$item.language+'/'+$item.kind+'/'+$item.entry
    $selected=if($item.ContainsKey('profile')){$item.profile}elseif($item.language -ceq 'Rust' -and $item.ContainsKey('profile_role')){$data.codegen.'rust-module'.profile_ids[$item.profile_role]}else{throw 'SdkModuleDefaultInvalid'}
    if(!$seen.Add($key) -or $item.language -cnotin @('Zig','C','Rust') -or $item.kind -cnotin @('R4X','R4L','R4D','R4P') -or $item.entry -cnotin @('','app','lowlevel') -or !$data.profiles.ContainsKey($selected) -or $data.profiles[$selected].language -cne $item.language){throw 'SdkModuleDefaultInvalid'}
    $lines.Add('    .{ .language = "'+$item.language+'", .kind = "'+$item.kind+'", .entry = "'+$item.entry+'", .profile = "'+$selected+'" },')
}
$lines.Add('};')
$generated=($lines -join "`n")+"`n"
$path=Join-Path $SdkRoot 'r4os/generated/profile_policy.zig'
if($Check){
    if(!(Test-Path -LiteralPath $path) -or [IO.File]::ReadAllText($path).Replace("`r`n","`n") -cne $generated){throw 'SdkProfilePolicyProjectionDrift'}
    Write-Output 'SDK profile policy projection verified.'
}else{
    [IO.Directory]::CreateDirectory((Split-Path $path -Parent))|Out-Null
    [IO.File]::WriteAllText($path,$generated,[Text.UTF8Encoding]::new($false))
}
