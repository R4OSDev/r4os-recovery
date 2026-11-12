# SDK-selected source/tool identity checks; callers supply locations only.
function Resolve-SdkComponentFile([string]$Root,[string]$Relative){
    if([IO.Path]::IsPathRooted($Relative) -or $Relative.Contains('\') -or $Relative.Split('/') -contains '..'){throw 'Noncanonical component path.'}
    return [IO.Path]::GetFullPath($Relative,$Root)
}
function Read-SdkMatchedComponents([string]$SdkRoot,[string]$ContractRoot,[string]$ToolsRoot,[bool]$Technical){
    $profile=Get-Content -Raw -LiteralPath (Join-Path $ToolsRoot 'RustToolsProfile.json')|ConvertFrom-Json -AsHashtable
    if($profile.schema -ne 1 -or $profile.id -cne 'r4os-rust-tools-v1' -or ($profile.technical -and !$Technical)){throw 'Unsupported or technical component profile.'}
    . (Join-Path $PSScriptRoot 'ProfileData.ps1')
    . (Join-Path $PSScriptRoot 'ProfileSources.ps1')
    if(!$profile.ContainsKey('source_hash_mode') -or $profile.source_hash_mode -cne 'r4os-files-sha256-lf-v1'){throw 'SdkToolsetSourceHashModeUnsupported'}
    $sdkData=Read-R4SdkProfiles $SdkRoot
    if(!$profile.ContainsKey('profile_sources')){throw 'SdkToolsetProfilesMissing'}
    foreach($name in $sdkData.hashes.Keys){if($profile.profile_sources[$name] -cne $sdkData.hashes[$name]){throw "SdkToolsetProfileMismatch: $name"}}
    foreach($owner in @(@($SdkRoot,$profile.sdk.inputs),@($ContractRoot,$profile.contract.inputs))){
        foreach($file in $owner[1]){
            $path=Resolve-SdkComponentFile $owner[0] $file.path
            if(!(Test-Path -LiteralPath $path -PathType Leaf) -or (Get-R4SdkFileDigest $path) -cne $file.sha256){throw ('Matched source input differs: '+$file.path)}
        }
    }
    return $profile
}
function Get-SdkMatchedTool([string]$ToolsRoot,$Profile,[string]$Relative){
    $file=@($Profile.files|Where-Object path -CEQ $Relative)
    $path=Resolve-SdkComponentFile $ToolsRoot $Relative
    if($file.Count -ne 1 -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -cne $file[0].sha256){throw ('Matched tool differs: '+$Relative)}
    if($IsLinux){& chmod 755 $path;if($LASTEXITCODE -ne 0){throw 'Cannot prepare selected host tool.'}}
    return $path
}
