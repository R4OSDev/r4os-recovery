. (Join-Path $PSScriptRoot 'ProfileData.ps1')
. (Join-Path $PSScriptRoot 'ProfileSources.ps1')

function Resolve-R4SdkComponents {
    param([string]$SdkRoot,[string]$Profile,[hashtable]$Roots,[string]$DevelopmentProfile='',
          [switch]$CreateDevelopment,[object[]]$AdditionalLibraries=@())
    $SdkRoot=[IO.Path]::GetFullPath($SdkRoot)
    $data=Read-R4SdkProfiles $SdkRoot
    Assert-R4ProfileReference $data.Build.profiles $Profile 'profile'
    $selected=$data.Build.profiles[$Profile]
    $platformId=if($selected.Contains('platform')){$selected.platform}else{'platform1'}
    $set=$data.Components.sets[$selected.components]
    $required=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    [void]$required.Add($set.contract)
    foreach($name in $set.system_libraries){[void]$required.Add($data.Components.libraries[$name].repository)}
    foreach($key in @('source_sdk','source_libraries')){if($set.Contains($key)){[void]$required.Add($set[$key])}}
    $development=$CreateDevelopment.IsPresent -or [bool]$DevelopmentProfile
    $ownState=Get-R4SdkSourceState $SdkRoot
    if(!$development -and $ownState.kind -ceq 'git' -and $ownState.dirty){throw 'SdkDevelopmentRequired: SDK sources'}
    $prior=$null
    if($DevelopmentProfile){
        $prior=Get-Content -Raw -LiteralPath $DevelopmentProfile|ConvertFrom-Json -AsHashtable -Depth 100
        if($prior.schema -ne 1 -or !$prior.technical -or $prior.sdk_version -cne $data.sdk_version){throw 'SdkDevelopmentProfileInvalid'}
        foreach($name in $data.hashes.Keys){if($prior.hashes[$name] -cne $data.hashes[$name]){throw "SdkDevelopmentProfileStale: $name"}}
        $own=Get-R4SdkSourceState $SdkRoot
        $ownDigest=Get-R4SdkTreeDigest $SdkRoot $own.files
        if($ownDigest -cne $prior.sdk_source.tree_sha256 -or $own.commit -cne $prior.sdk_source.commit){throw 'SdkDevelopmentProfileStale: SDK sources'}
    }
    $bindings=[ordered]@{}
    foreach($id in $required){
        if(!$Roots.ContainsKey($id)){throw "SdkSourceRootRequired: $id"}
        $binding=Get-R4SdkRepositoryBinding $id $Roots[$id] $data.Components.repositories[$id] $development
        if($prior){
            if(!$prior.sources.Contains($id)){throw "SdkDevelopmentProfileMissingSource: $id"}
            $record=$prior.sources[$id]
            if($record.root -cne $binding.root -or $record.tree_sha256 -cne $binding.tree_sha256 -or
               $record.commit -cne $binding.commit){throw "SdkDevelopmentProfileStale: $id"}
        }
        $bindings[$id]=$binding
    }
    $systemNames=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($id in $data.Components.libraries.Keys){[void]$systemNames.Add($data.Components.libraries[$id].name)}
    foreach($id in $data.Components.policy.system_packages){[void]$systemNames.Add($id)}
    $extras=[ordered]@{}
    foreach($extra in $AdditionalLibraries){
        if(!$extra.id -or $systemNames.Contains($extra.id)){throw "SdkSystemLibraryShadowed: $($extra.id)"}
        if($extras.Contains($extra.id)){throw "SdkAdditionalLibraryDuplicate: $($extra.id)"}
        if(!$extra.root){throw 'SdkAdditionalLibraryRootRequired'}
        $actual=Get-R4SdkSourceState $extra.root
        $scope=$actual.root
        if($extra.Contains('path')){Assert-R4SdkRelativePath $extra.path;$scope=[IO.Path]::GetFullPath($extra.path,$scope)}
        if($extra.Contains('commit')){
            if($extra.commit -cnotmatch '^[0-9a-f]{40}$' -or $actual.kind -cne 'git' -or
               $actual.commit -cne $extra.commit -or $actual.dirty){throw "SdkAdditionalLibraryIdentityMismatch: $($extra.id)"}
            $extraDigest=Get-R4SdkTreeDigest $actual.root $actual.files
        }elseif($extra.Contains('tree') -and $extra.tree.algorithm -ceq 'r4os-files-sha256-lf-v1'){
            $extraDigest=Get-R4SdkTreeDigest $actual.root $extra.tree.files
            if($extraDigest -cne $extra.tree.sha256){throw "SdkAdditionalLibraryIdentityMismatch: $($extra.id)"}
        }else{throw 'SdkAdditionalLibraryPinRequired'}
        foreach($file in @('module.R4MF','Cargo.toml')){
            $manifest=Join-Path $scope $file
            if(Test-Path -LiteralPath $manifest -PathType Leaf){
                $text=[IO.File]::ReadAllText($manifest)
                $identity=if($file -ceq 'module.R4MF'){
                    [regex]::Match($text,'(?m)^NAME=([^\r\n]+)').Groups[1].Value
                }else{
                    $package=[regex]::Match($text,'(?ms)^\[package\]\s*(.*?)(?=^\[|\z)').Groups[1].Value
                    [regex]::Match($package,'(?m)^name\s*=\s*"([^"]+)"').Groups[1].Value
                }
                if(!$identity -or $systemNames.Contains($identity)){throw "SdkSystemLibraryShadowed: $identity"}
            }
        }
        $extras[$extra.id]=@{root=$actual.root;scope_root=$scope;commit=$actual.commit;tree_sha256=$extraDigest}

    }
    # Validate installed system module identities as well as their owning source trees.
    foreach($id in $set.system_libraries){
        $library=$data.Components.libraries[$id]
        $root=$bindings[$library.repository].root
        $manifest=Join-Path $root ($library.path+'/module.R4MF')
        $text=[IO.File]::ReadAllText($manifest)
        foreach($field in @(@('NAME',$library.name),@('VERSION',$library.version),@('TARGET',$library.target))){
            $value=[regex]::Match($text,('(?m)^'+$field[0]+'=([^\r\n]+)')).Groups[1].Value
            if($value -cne $field[1]){throw "SdkSystemLibraryIdentityMismatch: $id/$($field[0])"}
        }
    }
    $cpuPath=Join-Path $bindings[$set.contract].root 'Module/CpuBaseline.json'
    if(Test-Path -LiteralPath $cpuPath -PathType Leaf){
        $hardware=Get-Content -Raw -LiteralPath $cpuPath|ConvertFrom-Json -AsHashtable
        Assert-R4ProfileReference $data.Build.cpu_baselines $hardware.name 'hardware baseline'
        $cpu=$data.Build.cpu_baselines[$hardware.name]
        foreach($key in @('format','name','cpu_model','xcr0_mask')){if($cpu[$key] -cne $hardware[$key]){throw "SdkHardwareContractMismatch: $key"}}
        if($cpu.requirements.Count -ne $hardware.requirements.Count){throw 'SdkHardwareContractMismatch: requirements'}
        for($i=0;$i -lt $hardware.requirements.Count;$i++){
            foreach($key in @('name','leaf','subleaf','register','bit')){
                if($cpu.requirements[$i][$key] -cne $hardware.requirements[$i][$key]){throw "SdkHardwareContractMismatch: requirement $i/$key"}
            }
        }
    }
    $toolDefinitions=[ordered]@{}
    foreach($id in $data.Tools.toolsets[$selected.toolset].tools){$toolDefinitions[$id]=$data.Tools.tools[$id]}
    $systemLibraries=[ordered]@{}
    foreach($id in $set.system_libraries){$systemLibraries[$id]=$data.Components.libraries[$id]}
    $result=[ordered]@{schema=1;technical=$development;sdk_version=$data.sdk_version;profile=$Profile;
        hashes=$data.hashes;toolset=$selected.toolset;tools=$toolDefinitions;components=$selected.components;
        build=$selected;platform=$data.Build.platforms[$platformId];codegen=$data.Build.codegen[$selected.codegen];system_libraries=$systemLibraries;
        sources=$bindings;additional_libraries=$extras}
    if($CreateDevelopment){
        $own=Get-R4SdkSourceState $SdkRoot
        if($own.kind -cne 'git'){throw 'SdkDevelopmentSourceInventoryRequired'}
        $result['sdk_source']=@{root=$own.root;commit=$own.commit;files=@($own.files);tree_sha256=(Get-R4SdkTreeDigest $SdkRoot $own.files)}
    }
    return $result
}
