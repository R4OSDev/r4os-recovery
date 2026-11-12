param(
    [Parameter(Mandatory)][string]$ContractRoot,
    [Parameter(Mandatory)][string]$ToolsRoot,
    [Parameter(Mandatory)][string]$InstallRoot,
    [Parameter(Mandatory)][string]$CacheRoot,
    [Parameter(Mandatory)][string]$ZigRoot,
    [Parameter(Mandatory)][string]$WorkRoot,
    [switch]$Technical,
    [switch]$FeatureSelectionOnly
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$sdk=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
foreach($name in @('ContractRoot','ToolsRoot','InstallRoot','CacheRoot','ZigRoot','WorkRoot')){
    Set-Variable -Name $name -Value ([IO.Path]::GetFullPath((Get-Variable -Name $name -ValueOnly)))
}
if(Test-Path -LiteralPath $WorkRoot){throw 'Use a new empty test root.'}
[IO.Directory]::CreateDirectory($WorkRoot)|Out-Null
$project=Join-Path $WorkRoot 'RustGraph';$dependency=Join-Path $WorkRoot 'RustGraphDependency'
Copy-Item -LiteralPath (Join-Path $sdk 'Tests/Build/RustGraph') -Destination $project -Recurse
Copy-Item -LiteralPath (Join-Path $sdk 'Tests/Build/RustGraphDependency') -Destination $dependency -Recurse
$output=Join-Path $WorkRoot 'Output With Spaces';$pwsh=(Get-Process -Id $PID).Path
$arguments=@('-NoLogo','-NoProfile','-File',(Join-Path $PSScriptRoot 'Build-RustModule.ps1'),'-ProjectRoot',$project,'-SdkRoot',$sdk,'-ContractRoot',$ContractRoot,'-ToolsRoot',$ToolsRoot,'-InstallRoot',$InstallRoot,'-CacheRoot',$CacheRoot,'-OutputRoot',$output,'-ZigRoot',$ZigRoot)
if($Technical){$arguments+='-Technical'}
$utf8=[Text.UTF8Encoding]::new($false)
function Run([string]$Name,[bool]$Success,[bool]$Admit=$true,[string[]]$Extra=@()){
    $call=@($arguments)+$Extra
    if($Admit){$call+=@('-DependencyRootsJson',(ConvertTo-Json -InputObject @($dependency) -Compress))}
    & $pwsh @call > (Join-Path $WorkRoot ($Name+'.log')) 2>&1
    if(($LASTEXITCODE -eq 0) -ne $Success){throw "Unexpected $Name result; see owned log."}
    if(!$Success){
        if((Test-Path -LiteralPath (Join-Path $output 'RUSTGRAPH.R4X')) -or (Test-Path -LiteralPath (Join-Path $output 'build.json')) -or (Test-Path -LiteralPath (Join-Path $output 'startup-info.rs'))){throw "Stale success after $Name"}
        return $null
    }
    $result=Get-Content -Raw -LiteralPath (Join-Path $output 'build.json')|ConvertFrom-Json -AsHashtable
    $index=[Array]::IndexOf($Extra,'-Features');$selected=if($index -ge 0){$Extra[$index+1]}else{''}
    $buildLog=[IO.File]::ReadAllText((Join-Path $WorkRoot ($Name+'.log')))
    if($result.cargo.selected_features -cne $selected -or $result.cpu.features -isnot [array] -or
       @($result.cpu.features|Where-Object {$_ -cnotmatch '^\+[a-z][a-z0-9_]*$'}).Count -or
       $result.codegen.target_features -isnot [array] -or !$result.codegen.backend_feature_policy.reason -or
       $result.codegen.backend_feature_policy.selection -cne 'target-defaults' -or $result.codegen.target_features.Count -ne 0 -or
       $buildLog -match 'unknown and unstable feature|not a recognized feature for this target'){
        throw 'Cargo selection and mandatory CPU features must stay independent and accepted by rustc.'
    }
    return $result
}
$baseline=Run baseline $true
if($baseline.schema -ne 2 -or $baseline.cargo.name -cne 'rust-graph-fixture' -or $baseline.module.name -cne 'RUSTGRAPH' -or $baseline.native_c.commands.Count -ne 2){throw 'Graph/module/C ownership drift.'}
foreach($path in @('src/main.rs','src/logic.rs','src/payload.txt','native/first.c','native/second.c','native/include/graph.h')){
    if(!@($baseline.compiler_inputs|Where-Object {$_.owner -ceq 'project' -and $_.path -ceq $path}).Count){throw "Missing observed input $path"}
}
if(!@($baseline.compiler_inputs|Where-Object {$_.owner -ceq 'dependency0' -and $_.path -ceq 'src/lib.rs'}).Count){throw 'External dependency source not observed.'}
if(!@($baseline.cargo.graph|Where-Object {$_.name -ceq 'r4os-build-helper' -and $_.resolved -and $_.features -contains 'scaled'}).Count){throw 'Resolved dependency feature not bound.'}
if($FeatureSelectionOnly){
    $disabled=Run no-defaults $true $true @('-NoDefaultFeatures')
    $enabled=Run explicit-feature $true $true @('-NoDefaultFeatures','-Features','with-helper')
    if($disabled.artifact.sha256 -ceq $baseline.artifact.sha256 -or $enabled.artifact.sha256 -cne $baseline.artifact.sha256){throw 'Feature selection/container result mismatch.'}
    Write-Host 'Independent Cargo feature selection, canonical CPU flags and restored bytes PASS.'
    return
}
Run undeclared-root $false $false|Out-Null
$sources=@(
    @{path=(Join-Path $dependency 'src/lib.rs');before='wrapping_mul(2)';after='wrapping_mul(3)';name='dependency'},
    @{path=(Join-Path $project 'src/payload.txt');before='7';after='8';name='include'},
    @{path=(Join-Path $project 'native/include/graph.h');before='BIAS 7u';after='BIAS 8u';name='c-header'}
)
foreach($source in $sources){
    $original=[IO.File]::ReadAllText($source.path)
    try{
        if(!$original.Contains($source.before)){throw 'Fixture source site drift.'}
        [IO.File]::WriteAllText($source.path,$original.Replace($source.before,$source.after),$utf8)
        $changed=Run $source.name $true
        if($changed.artifact.sha256 -ceq $baseline.artifact.sha256){throw "No artifact change for $($source.name)"}
    }finally{[IO.File]::WriteAllText($source.path,$original,$utf8)}
}
$header=Join-Path $project 'native/include/graph.h';$original=[IO.File]::ReadAllText($header)
try{[IO.File]::WriteAllText($header,$original+"`n#error owned compile failure`n",$utf8);Run c-error $false|Out-Null}
finally{[IO.File]::WriteAllText($header,$original,$utf8)}
$disabled=Run no-defaults $true $true @('-NoDefaultFeatures')
if($disabled.artifact.sha256 -ceq $baseline.artifact.sha256){throw 'Root feature selection did not change artifact.'}
$enabled=Run explicit-feature $true $true @('-NoDefaultFeatures','-Features','with-helper')
if($enabled.artifact.sha256 -cne $baseline.artifact.sha256){throw 'Explicit equivalent feature selection changed bytes.'}
$cargo=Join-Path $project 'Cargo.toml';$original=[IO.File]::ReadAllText($cargo)
try{
    # Explicit SDK release settings replace conflicting package defaults.
    [IO.File]::WriteAllText($cargo,$original+"`n[profile.release]`nopt-level=0`noverflow-checks=false`ndebug-assertions=true`npanic=`"unwind`"`n",$utf8)
    $overridden=Run explicit-sdk-profile $true
    if($overridden.artifact.sha256 -cne $baseline.artifact.sha256){throw 'Explicit SDK profile did not replace project defaults.'}
    # More specific per-package overrides must not silently alter a crate.
    [IO.File]::WriteAllText($cargo,$original+"`n[profile.release.package.r4os-build-helper]`nopt-level=0`n",$utf8)
    Run conflicting-crate-profile $false|Out-Null
}finally{[IO.File]::WriteAllText($cargo,$original,$utf8)}
try{
    [IO.File]::WriteAllText($cargo,$original.Replace('path = "src/main.rs"','path = "src/logic.rs"'),$utf8)
    Run target-conflict $false|Out-Null
}finally{[IO.File]::WriteAllText($cargo,$original,$utf8)}
$restored=Run restored $true
if($restored.artifact.sha256 -cne $baseline.artifact.sha256){throw 'Restored graph inputs changed bytes.'}
Write-Host ('Rust graph, features, external roots, Rust/include/C-header dep-info, failure cleanup and restored bytes PASS: '+$restored.artifact.sha256)
