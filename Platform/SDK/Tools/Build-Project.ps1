param(
    [Parameter(Mandatory)][string]$ProjectRoot,
    [Parameter(Mandatory)][string]$SdkRoot,
    [Parameter(Mandatory)][string]$ContractRoot,
    [Parameter(Mandatory)][string]$ToolsRoot,
    [string]$ZigRoot='', [string]$InstallRoot='', [string]$CacheRoot='', [string]$OutputRoot='',
    [string]$LibrariesRoot='', [string]$DevelopmentProfile='', [string]$AdditionalLibrariesFile='',
    [string[]]$BuildArguments=@(), [string[]]$DependencyRoot=@(), [string]$DependencyRootsJson='',
    [string]$Features='', [switch]$NoDefaultFeatures, [string]$LibraryHelpersRoot='', [switch]$Technical
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
foreach($key in @('ProjectRoot','SdkRoot','ContractRoot','ToolsRoot')){Set-Variable $key ([IO.Path]::GetFullPath((Get-Variable $key -ValueOnly)))}
. (Join-Path $PSScriptRoot 'MatchedComponents.ps1')
. (Join-Path $PSScriptRoot 'BuildContext.ps1')
if(!$LibrariesRoot){$LibrariesRoot=if($LibraryHelpersRoot){$LibraryHelpersRoot}else{$env:R4OS_SDK_LIBRARIES_ROOT}}
if(!$DevelopmentProfile){$DevelopmentProfile=$env:R4OS_SDK_DEVELOPMENT_PROFILE}
$manifest=Join-Path $ProjectRoot 'module.R4MF'
# Rust retains its existing output/error owner, Cargo and exact build receipt.
$manifestExists=Test-Path -LiteralPath $manifest -PathType Leaf
$selectedOutput=if($OutputRoot){[IO.Path]::GetFullPath($OutputRoot)}else{Join-Path $ProjectRoot 'build'}
$priorRust=Test-Path -LiteralPath (Join-Path $selectedOutput '.r4os-rust-build.json') -PathType Leaf
if(($manifestExists -and [IO.File]::ReadAllText($manifest) -match '(?m)^LANGUAGE=Rust\s*$') -or (!$manifestExists -and $priorRust)){
    $arguments=@{ProjectRoot=$ProjectRoot;SdkRoot=$SdkRoot;ContractRoot=$ContractRoot;ToolsRoot=$ToolsRoot;Technical=$Technical}
    foreach($key in @('LibrariesRoot','DevelopmentProfile','AdditionalLibrariesFile','ZigRoot','InstallRoot','CacheRoot','OutputRoot','DependencyRoot','DependencyRootsJson','Features','LibraryHelpersRoot')){if((Get-Variable $key -ValueOnly)){$arguments[$key]=Get-Variable $key -ValueOnly}}
    if($NoDefaultFeatures){$arguments.NoDefaultFeatures=$true}
    if($BuildArguments.Count){throw 'Rust uses explicit Cargo feature/dependency parameters, not Zig build arguments.'}
    & (Join-Path $PSScriptRoot 'Build-RustModule.ps1') @arguments
    exit $LASTEXITCODE
}
if(!$OutputRoot){$OutputRoot=Join-Path $ProjectRoot 'build'};$OutputRoot=[IO.Path]::GetFullPath($OutputRoot)
$comparison=if($IsWindows){[StringComparison]::OrdinalIgnoreCase}else{[StringComparison]::Ordinal}
if($ProjectRoot.Equals($OutputRoot,$comparison) -or $ProjectRoot.StartsWith($OutputRoot.TrimEnd([IO.Path]::DirectorySeparatorChar)+[IO.Path]::DirectorySeparatorChar,$comparison)){throw 'Output must not contain source project.'}
[IO.Directory]::CreateDirectory($OutputRoot)|Out-Null
$lock=[IO.File]::Open((Join-Path $OutputRoot '.build-lock'),[IO.FileMode]::OpenOrCreate,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
$marker=Join-Path $OutputRoot '.r4os-manifest-build.json';$utf8=[Text.UTF8Encoding]::new($false);$artifact=''
try{
    if(Test-Path -LiteralPath $marker){
        $old=Get-Content -Raw -LiteralPath $marker|ConvertFrom-Json -AsHashtable
        if($old.schema -ne 1 -or !$ProjectRoot.Equals($old.project,$comparison)){throw 'Output belongs to another project.'}
        if($old.artifact){
            if($old.artifact -cnotmatch '^[A-Za-z0-9_-]{1,31}\.(R4X|R4L|R4D|R4P)$'){throw 'Invalid previous artifact identity.'}
            [IO.File]::Delete((Join-Path $OutputRoot $old.artifact))
        }
    }elseif(@(Get-ChildItem -LiteralPath $OutputRoot -Force|Where-Object Name -CNE '.build-lock').Count){throw 'New output must be empty.'}
    $receipt=Join-Path $OutputRoot 'build.json';[IO.File]::Delete($receipt)
    [IO.File]::WriteAllText($marker,(@{schema=1;project=$ProjectRoot;artifact='';status='building'}|ConvertTo-Json),$utf8)
    $profile=Read-SdkMatchedComponents $SdkRoot $ContractRoot $ToolsRoot $Technical.IsPresent
    $hostName=if($IsWindows){'Windows'}elseif($IsLinux){'Linux'}else{throw 'Unsupported host.'}
    $catalog=Get-SdkMatchedTool $ToolsRoot $profile $profile.hosts[$hostName].catalog
    $plan=@(& $catalog plan --manifest $manifest 2>&1);if($LASTEXITCODE -ne 0){throw ($plan -join "`n")};$facts=(($plan -join "`n")|ConvertFrom-Json -AsHashtable).plan
    if($facts.language -cnotin @('C','Zig')){throw 'Host manifest requires C, Zig or Rust.'}
    $profileId=$facts.sdk_profile
    $context=Get-R4SdkBuildContext $SdkRoot $ContractRoot $LibrariesRoot $(if($InstallRoot){$InstallRoot}else{$ToolsRoot}) $ZigRoot -Profile $profileId -DevelopmentProfile $DevelopmentProfile
    Assert-R4SdkBuildArguments $context $BuildArguments
    Assert-R4SdkProjectPins $SdkRoot $ProjectRoot
    if($AdditionalLibrariesFile){$extras=Get-Content -Raw -LiteralPath $AdditionalLibrariesFile|ConvertFrom-Json -AsHashtable -NoEnumerate;$null=Resolve-R4SdkComponents -SdkRoot $SdkRoot -Profile $profileId -Roots @{contract=$ContractRoot;libraries=$LibrariesRoot} -DevelopmentProfile $DevelopmentProfile -AdditionalLibraries $extras}
    $artifact=$facts.name+'.'+$facts.kind
    [IO.File]::WriteAllText($marker,(@{schema=1;project=$ProjectRoot;artifact=$artifact;status='building'}|ConvertTo-Json),$utf8)
    if(!$ZigRoot){throw 'Select the pinned host ZigRoot explicitly.'};$ZigRoot=[IO.Path]::GetFullPath($ZigRoot)
    $zig=Join-Path $ZigRoot $(if($IsWindows){'zig.exe'}else{'zig'})
    $pin=Get-Content -Raw -LiteralPath (Join-Path $ToolsRoot 'Profile/ZigToolchain.json')|ConvertFrom-Json
    $version=(& $zig version)-join '';if($LASTEXITCODE -ne 0 -or $version -cne $pin.version){throw 'Selected Zig version differs from the matched toolchain.'}
    if(!$CacheRoot){$CacheRoot=Join-Path $OutputRoot '.cache'};$CacheRoot=[IO.Path]::GetFullPath($CacheRoot)
    # Source roots and resource paths are resolved by the original SDK manifest
    # builder. This wrapper adds no second role grammar or Zig module root.
    if(!@($BuildArguments|Where-Object {$_ -match '^-j($|[0-9])'}).Count){$BuildArguments=@('-j1')+$BuildArguments}
    & $zig build --build-file (Join-Path $SdkRoot 'Tools/ManifestProject/build.zig') ('--fork='+$ContractRoot) ('--fork='+$LibrariesRoot) ('-Dproject-root='+$ProjectRoot) --cache-dir $CacheRoot --prefix $OutputRoot @BuildArguments
    if($LASTEXITCODE -ne 0){throw 'Original SDK manifest build failed.'}
    $path=Join-Path $OutputRoot $artifact;if(!(Test-Path -LiteralPath $path -PathType Leaf)){throw 'Manifest artifact missing.'}
    $result=@{schema=1;sdk_profile=@{id=$context.resolved.profile;hashes=$context.resolved.hashes;technical=$context.resolved.technical};status='success';technical=[bool]$Technical;project=$ProjectRoot;module=$facts;sdk=$profile.sdk;contract=$profile.contract;compiler=@{version=$version;sha256=(Get-FileHash -LiteralPath $zig -Algorithm SHA256).Hash.ToLowerInvariant()};artifact=@{file=$artifact;bytes=([IO.FileInfo]$path).Length;sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()}}
    [IO.File]::WriteAllText($receipt,($result|ConvertTo-Json -Depth 30)+"`n",$utf8)
    [IO.File]::WriteAllText($marker,(@{schema=1;project=$ProjectRoot;artifact=$artifact;status='success'}|ConvertTo-Json),$utf8)
}catch{
    if($artifact){[IO.File]::Delete((Join-Path $OutputRoot $artifact))}
    throw
}finally{$lock.Dispose()}
