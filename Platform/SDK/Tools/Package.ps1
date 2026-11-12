param(
    [ValidateSet('Describe','Manifest','Verify')][string]$Action='Describe',
    [string]$SdkRoot='', [string]$RootsFile='', [string]$ToolsRoot='',
    [string]$PayloadRoot='', [string]$AssetsFile='', [string]$Manifest='',
    [string]$ReleaseBaseUrl='', [string]$Output=''
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
if(!$SdkRoot){$SdkRoot=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))}
. (Join-Path $PSScriptRoot 'ProfileData.ps1')
. (Join-Path $PSScriptRoot 'ProfileResolver.ps1')
. (Join-Path $PSScriptRoot 'MatchedComponents.ps1')
$data=Read-R4SdkProfiles $SdkRoot
function Digest([string]$Path){return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()}
function Emit($Value){
    $text=$Value|ConvertTo-Json -Depth 100
    if($Output){[IO.File]::WriteAllText([IO.Path]::GetFullPath($Output),$text+"`n",[Text.UTF8Encoding]::new($false))}
    else{$text}
}
function AssetPath([string]$Path){
    Assert-R4SdkRelativePath $Path
    return [IO.Path]::GetFullPath($Path,$PayloadRoot)
}
function CheckSources {
    if(!$RootsFile -or !$ToolsRoot){throw 'SdkPackageRootsAndToolsRequired'}
    $roots=Get-Content -Raw -LiteralPath $RootsFile|ConvertFrom-Json -AsHashtable
    $sets=[ordered]@{}
    foreach($id in $data.Build.profiles.Keys){
        $set=$data.Build.profiles[$id].components
        if(!$sets.Contains($set)){
            $resolved=Resolve-R4SdkComponents -SdkRoot $SdkRoot -Profile $id -Roots $roots
            $sources=[ordered]@{}
            foreach($key in $resolved.sources.Keys){
                $binding=$resolved.sources[$key]
                $sources[$key]=[ordered]@{commit=$binding.expected_commit;tree_sha256=$binding.tree_sha256;matches_sdk=$binding.matches_sdk}
            }
            $sets[$set]=$sources
        }
    }
    $tools=Read-SdkMatchedComponents $SdkRoot $roots['contract'] $ToolsRoot $false
    foreach($file in $tools.files){
        $path=Resolve-SdkComponentFile $ToolsRoot $file.path
        if(!(Test-Path -LiteralPath $path -PathType Leaf) -or (Get-Item -LiteralPath $path).Length -ne $file.bytes -or (Digest $path) -cne $file.sha256){throw "SdkPackageToolMismatch: $($file.path)"}
    }
    return $sets
}
$description=[ordered]@{
    schema=1;interface='r4os-sdk-package';sdk_version=$data.sdk_version;
    profile_sources=[ordered]@{};profiles=$data.Build.profiles;
    toolsets=$data.Tools.toolsets;tools=$data.Tools.tools;
    component_sets=$data.Components.sets;sources=$data.Components.repositories;
    system_libraries=$data.Components.libraries;policy=$data.Components.policy;
    source_hash_mode='r4os-files-sha256-lf-v1';
    commands=@{validate='Tools/Profile.ps1 -Action Validate';describe='Tools/Profile.ps1 -Action Describe -Profile ID';
        resolve='Tools/Profile.ps1 -Action Resolve -Profile ID -RootsFile FILE';
        install='Tools/Setup.ps1 -InstallRoot DIRECTORY';create='Tools/New-Project.ps1';build='Tools/Build-Project.ps1';
        capabilities='module-catalog capabilities --json';verify='Tools/Package.ps1 -Action Verify'}
}
foreach($name in $data.hashes.Keys){$description.profile_sources[$name]=@{path='Profiles/'+$name+'.json';schema=1;sha256=$data.hashes[$name]}}
if($Action -ceq 'Describe'){Emit $description;exit 0}
if(!$PayloadRoot){throw 'SdkPackagePayloadRootRequired'}
$PayloadRoot=[IO.Path]::GetFullPath($PayloadRoot)
if($Action -ceq 'Manifest'){
    if(!$AssetsFile -or !$Output -or $ReleaseBaseUrl -cnotmatch '^https://[^\s]+/$'){throw 'SdkPackageManifestArgumentsRequired'}
    $source=Get-R4SdkSourceState $SdkRoot
    if($source.kind -cne 'git' -or $source.dirty){throw 'SdkPackageCleanSourceRequired'}
    $sets=CheckSources
    $mapping=Get-Content -Raw -LiteralPath $AssetsFile|ConvertFrom-Json -AsHashtable -NoEnumerate
    if($mapping -isnot [array]){throw 'SdkPackageAssetArrayRequired'}
    $assets=@();$roles=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $names=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($item in $mapping){
        Assert-R4ProfileKeys $item @('role','path','prefix') 'asset'
        Assert-R4ProfileId $item.role 'asset.role'
        if(!$names.Add($item.path)){throw 'SdkPackageDuplicateAsset'}
        [void]$roles.Add($item.role)
        $path=AssetPath $item.path
        if([IO.Path]::GetFullPath($Output) -ceq $path){throw 'SdkPackageSelfReference'}
        $entry=[ordered]@{role=$item.role;path=$item.path;url=$ReleaseBaseUrl+$item.path;bytes=(Get-Item -LiteralPath $path).Length;sha256=Digest $path}
        if($item.Contains('prefix')){Assert-R4SdkRelativePath $item.prefix;$entry['prefix']=$item.prefix}
        $assets+=$entry
    }
    foreach($role in @('sdk-source','contract-source','libraries-source','recovery-sources','tools','capabilities','qualification')){
        if(!$roles.Contains($role)){throw "SdkPackageMissingRole: $role"}
    }
    $description['sdk_source']=@{repository='https://github.com/R4OSDev/r4os-sdk.git';commit=$source.commit;tree_sha256=(Get-R4SdkTreeDigest $SdkRoot $source.files);files=$source.files}
    $description['resolved_sources']=$sets
    $description['assets']=$assets
    $description['qualification']='See the qualification asset. Tool preparation and cross-build do not imply Windows or hardware execution.'
    Emit $description;exit 0
}
if(!$Manifest){throw 'SdkPackageManifestRequired'}
$record=Get-Content -Raw -LiteralPath $Manifest|ConvertFrom-Json -AsHashtable -Depth 100
if($record.schema -ne 1 -or $record.interface -cne 'r4os-sdk-package' -or $record.sdk_version -cne $data.sdk_version){throw 'SdkPackageIdentityMismatch'}
foreach($name in $data.hashes.Keys){
    if($record.profile_sources[$name].schema -ne 1 -or $record.profile_sources[$name].path -cne ('Profiles/'+$name+'.json') -or $record.profile_sources[$name].sha256 -cne $data.hashes[$name]){throw "SdkPackageProfileMismatch: $name"}
}
$count=0;$names=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$roles=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach($asset in $record.assets){
    if(!$names.Add($asset.path)){throw 'SdkPackageDuplicateAsset'}
    [void]$roles.Add($asset.role)
    $path=AssetPath $asset.path
    if(!(Test-Path -LiteralPath $path -PathType Leaf) -or (Get-Item -LiteralPath $path).Length -ne $asset.bytes -or (Digest $path) -cne $asset.sha256){throw "SdkPackageAssetMismatch: $($asset.path)"}
    $count++
}
foreach($role in @('sdk-source','contract-source','libraries-source','recovery-sources','tools','capabilities','qualification')){if(!$roles.Contains($role)){throw "SdkPackageMissingRole: $role"}}
if($record.source_hash_mode -cne 'r4os-files-sha256-lf-v1' -or (Get-R4SdkTreeDigest $SdkRoot $record.sdk_source.files) -cne $record.sdk_source.tree_sha256){throw 'SdkPackageSourceMismatch'}
$sources=CheckSources
foreach($set in $sources.Keys){foreach($id in $sources[$set].Keys){
    if($record.resolved_sources[$set][$id].tree_sha256 -cne $sources[$set][$id].tree_sha256){throw "SdkPackageSourceMismatch: $id"}
}}
Emit ([ordered]@{schema=1;valid=$true;sdk_version=$data.sdk_version;verified_assets=$count;hashes=$data.hashes;technical=$false})
