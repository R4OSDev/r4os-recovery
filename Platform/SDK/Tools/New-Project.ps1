param(
    [Parameter(Mandatory)][string]$TemplateId,
    [Parameter(Mandatory)][string]$Directory,
    [Parameter(Mandatory)][string]$ContractRoot,
    [Parameter(Mandatory)][string]$ToolsRoot,
    [string]$ProjectName='', [string]$SdkRoot='', [string]$Language='',
    [string]$Version='0.1.0', [string]$InstallRoot='', [string]$CacheRoot='', [switch]$Technical
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
if(!$SdkRoot){$SdkRoot=Join-Path $PSScriptRoot '..'}
foreach($key in @('SdkRoot','ContractRoot','ToolsRoot','Directory')){Set-Variable $key ([IO.Path]::GetFullPath((Get-Variable $key -ValueOnly)))}
. (Join-Path $PSScriptRoot 'MatchedComponents.ps1')
$profile=Read-SdkMatchedComponents $SdkRoot $ContractRoot $ToolsRoot $Technical.IsPresent
$templateRoot=Join-Path $SdkRoot 'Templates';$selected=$null;$stage='';$utf8=[Text.UTF8Encoding]::new($false)
function Within([string]$Root,[string]$Relative){
    $full=[IO.Path]::GetFullPath($Relative,$Root)
    if(!$full.StartsWith($Root.TrimEnd([IO.Path]::DirectorySeparatorChar)+[IO.Path]::DirectorySeparatorChar,$(if($IsWindows){[StringComparison]::OrdinalIgnoreCase}else{[StringComparison]::Ordinal}))){throw 'Template path escapes its owner.'}
    return $full
}
function Crate-Version([string]$Path){
    $text=[IO.File]::ReadAllText($Path);$package=[regex]::Match($text,'(?ms)^\[package\]\s*(.*?)(?=^\[|\z)').Groups[1].Value
    $version=[regex]::Match($package,'(?m)^version\s*=\s*"(\d+\.\d+\.\d+)"').Groups[1].Value
    if(!$version){throw 'Matched crate identity missing.'};return $version
}
function Expand-Template([string]$Text,$Tokens){
    foreach($key in $Tokens.Keys){$Text=$Text.Replace('{'+$key+'}',[string]$Tokens[$key])}
    if($Text -cmatch '\{[A-Z][A-Za-z0-9]*\}'){throw ('Unbound template input '+$Matches[0])}
    return $Text
}
try{
    if(Test-Path -LiteralPath $Directory){throw 'Project destination already exists.'}
    foreach($entry in Get-ChildItem -LiteralPath $templateRoot -Filter template.ini -Recurse -File){
        $meta=@{};$files=[Collections.Generic.List[string]]::new()
        foreach($raw in [IO.File]::ReadLines($entry.FullName)){
            $line=$raw.Trim();if(!$line -or $line.StartsWith('#') -or $line -ceq '[Template]'){continue}
            $eq=$line.IndexOf('=');if($eq -lt 1){throw 'Invalid template metadata.'}
            $key=$line.Substring(0,$eq);$value=$line.Substring($eq+1)
            if($key -ceq 'File'){$files.Add($value)}else{if($meta.ContainsKey($key)){throw 'Duplicate template metadata.'};$meta[$key]=$value}
        }
        if($meta.Id -ceq $TemplateId){if($selected){throw 'Ambiguous template ID.'};$selected=@{root=$entry.DirectoryName;meta=$meta;files=$files.ToArray()}}
    }
    if(!$selected -or !$selected.files.Count){throw 'Template/file map not found.'}
    if(!$selected.meta.ContainsKey('Execution') -or $selected.meta.Execution -cne 'host'){throw 'Native templates are consumed by R4BUILD; choose an explicit host template.'}
    if(!$ProjectName){$ProjectName=$selected.meta.DefaultProjectName}
    if($ProjectName -cnotmatch '^[A-Za-z][A-Za-z0-9_-]{0,30}$'){throw 'Invalid project name.'}
    if($Version -cnotmatch '^\d+\.\d+\.\d+$'){throw 'Invalid initial module version.'}
    $identity=[guid]::NewGuid().ToByteArray()
    $tokens=@{ProjectName=$ProjectName;ProjectNameLower=$ProjectName.ToLowerInvariant();ProjectNameUpper=$ProjectName.ToUpperInvariant();CrateName=$ProjectName.ToLowerInvariant().Replace('_','-');SdkCrateVersion=Crate-Version (Join-Path $SdkRoot 'Rust/Cargo.toml');ContractCrateVersion=Crate-Version (Join-Path $ContractRoot 'Generated/SDK/Rust/Cargo.toml');DisplayName=$selected.meta.DisplayName;TemplateId=$TemplateId;Version=$Version;ImageScope='none';Target=('/R4OS/LIBS/'+$ProjectName+'.R4L');Description=$selected.meta.DisplayName;InterfaceIdLow=([BitConverter]::ToUInt64($identity,0) -band [long]::MaxValue);InterfaceIdHigh=([BitConverter]::ToUInt64($identity,8) -band [long]::MaxValue)}
    $stage=$Directory+'.new-'+[guid]::NewGuid().ToString('N');[IO.Directory]::CreateDirectory($stage)|Out-Null
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach($mapping in $selected.files){
        $parts=$mapping.Split('|');if($parts.Count -ne 2){throw 'Invalid template file map.'}
        $source=Within $templateRoot ([IO.Path]::GetRelativePath($templateRoot,[IO.Path]::GetFullPath($parts[0],$selected.root)))
        $relative=Expand-Template $parts[1] $tokens
        if($relative.Contains('\') -or $relative.Split('/') -contains '..' -or !$seen.Add($relative)){throw 'Invalid/duplicate target in template file map.'}
        $target=Within $stage $relative;$text=Expand-Template ([IO.File]::ReadAllText($source)) $tokens
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))|Out-Null
        [IO.File]::WriteAllText($target,$text,$utf8)
    }
    $manifest=Join-Path $stage 'module.R4MF';$fields=@{}
    foreach($line in [IO.File]::ReadLines($manifest)){if($line -match '^([A-Z_]+)=(.*)$' -and !$fields.ContainsKey($Matches[1])){$fields[$Matches[1]]=$Matches[2]}}
    if($Language -and $fields.LANGUAGE -cne $Language){throw 'Template language differs from the selected creator.'}
    $hostName=if($IsWindows){'Windows'}elseif($IsLinux){'Linux'}else{throw 'Unsupported host.'}
    if($fields.KIND -ceq 'R4L'){
        if($ProjectName -cnotmatch '^[A-Za-z][A-Za-z0-9_]*$'){throw 'Library names must also be valid C interface identifiers.'}
        if(!$profile.hosts[$hostName].ContainsKey('r4l_contract_generator')){throw 'Matched local library-contract generator missing.'}
        $generator=Get-SdkMatchedTool $ToolsRoot $profile $profile.hosts[$hostName].r4l_contract_generator
        $generatorArgs=@('--write','--update-baseline','--module-name',$fields.NAME,'--export',('API_V1:'+$ProjectName.ToLowerInvariant()+'_api_v1:1'))
        foreach($pair in @(@('CONTRACT','contract'),@('CONTRACT_BASELINE','baseline'),@('IMPLEMENTATION_ZIG','implementation-zig'),@('BINDING_ZIG','binding-zig'),@('BINDING_C','binding-c'),@('BINDING_RUST','binding-rust'),@('CONFORMANCE_ZIG','fixture-zig'),@('CONFORMANCE_C','fixture-c'),@('API_REFERENCE','docs'))){
            if($fields.ContainsKey($pair[0])){
                $path=Within $stage $fields[$pair[0]];[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($path))|Out-Null
                $generatorArgs+=@(('--'+$pair[1]),$path)
            }
        }
        & $generator @generatorArgs;if($LASTEXITCODE -ne 0){throw 'Initial own library contract generation failed.'}
        if($fields.LANGUAGE -ceq 'Rust'){
            if(!$InstallRoot){$InstallRoot=$ToolsRoot};$InstallRoot=[IO.Path]::GetFullPath($InstallRoot)
            if(!$CacheRoot){$CacheRoot=Join-Path $InstallRoot '.Cache/Rust'};$CacheRoot=[IO.Path]::GetFullPath($CacheRoot)
            $patchSdk='patch.crates-io.r4os-sdk.path="'+$SdkRoot.Replace('\','/')+'/Rust"'
            $patchContract='patch.crates-io.r4os-contract.path="'+$ContractRoot.Replace('\','/')+'/Generated/SDK/Rust"'
            & (Get-Process -Id $PID).Path -NoLogo -NoProfile -File (Join-Path $ToolsRoot 'Setup/Rust.ps1') --root $InstallRoot --cache-root $CacheRoot cargo generate-lockfile --offline --manifest-path (Join-Path $stage 'Cargo.toml') --config $patchSdk --config $patchContract
            if($LASTEXITCODE -ne 0){throw 'Initial explicit local Cargo graph failed.'}
        }
    }
    $catalog=Get-SdkMatchedTool $ToolsRoot $profile $profile.hosts[$hostName].catalog
    $json=@(& $catalog plan --manifest $manifest 2>&1);if($LASTEXITCODE -ne 0){throw ($json -join "`n")}
    $plan=($json -join "`n")|ConvertFrom-Json -AsHashtable
    if($plan.plan.language -ceq 'Rust' -and !$plan.plan.rust_project.host_build_qualified){throw 'Template lacks actual Rust host admission.'}
    if($IsLinux){& chmod 755 (Join-Path $stage 'Build.sh');if($LASTEXITCODE -ne 0){throw 'Cannot prepare project starter.'}}
    [IO.Directory]::Move($stage,$Directory);$stage=''
    Write-Host "Project created: $Directory ($TemplateId)"
}finally{if($stage -and (Test-Path -LiteralPath $stage)){Remove-Item -LiteralPath $stage -Recurse -Force}}
