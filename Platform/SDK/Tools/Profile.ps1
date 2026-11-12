param(
    [ValidateSet('Validate', 'Describe', 'Resolve', 'Develop')][string]$Action = 'Validate',
    [string]$SdkRoot = '',
    [string]$Profile = 'r4os-zig-module-v1',
    [string]$ContractRoot='', [string]$LibrariesRoot='', [string]$RootsFile='',
    [string]$AdditionalLibrariesFile='', [string]$DevelopmentProfile='', [string]$Output=''
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
if (!$SdkRoot) { $SdkRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..')) }
. (Join-Path $PSScriptRoot 'ProfileData.ps1')
if($Action -cin @('Resolve','Develop')){
    . (Join-Path $PSScriptRoot 'ProfileResolver.ps1')
    $roots=@{}
    if($RootsFile){$roots=Get-Content -Raw -LiteralPath $RootsFile|ConvertFrom-Json -AsHashtable}
    if($ContractRoot){$roots['contract']=$ContractRoot}
    if($LibrariesRoot){$roots['libraries']=$LibrariesRoot}
    $extra=@()
    if($AdditionalLibrariesFile){$extra=Get-Content -Raw -LiteralPath $AdditionalLibrariesFile|ConvertFrom-Json -AsHashtable -NoEnumerate;if($extra -isnot [array]){throw 'SdkAdditionalLibraryArrayRequired'}}
    if($Action -ceq 'Develop' -and (!$Output -or $DevelopmentProfile)){throw 'Develop requires a new Output and no input DevelopmentProfile.'}
    $options=@{SdkRoot=$SdkRoot;Profile=$Profile;Roots=$roots;AdditionalLibraries=$extra}
    if($DevelopmentProfile){$options.DevelopmentProfile=$DevelopmentProfile}
    if($Action -ceq 'Develop'){$options.CreateDevelopment=$true}
    $result=Resolve-R4SdkComponents @options
    $json=$result|ConvertTo-Json -Depth 100
    if($Output){
        $path=[IO.Path]::GetFullPath($Output)
        if($Action -ceq 'Develop' -and (Test-Path -LiteralPath $path)){throw 'Development output already exists; select a new snapshot.'}
        [IO.Directory]::CreateDirectory((Split-Path $path -Parent))|Out-Null
        [IO.File]::WriteAllText($path,$json+"`n",[Text.UTF8Encoding]::new($false))
    }
    if(!$Output){$json}else{[ordered]@{schema=1;status='success';technical=$result.technical;profile=$Profile;output=$path}|ConvertTo-Json}
} elseif ($Action -ceq 'Describe') {
    Get-R4SdkBuildProfile $SdkRoot $Profile | ConvertTo-Json -Depth 100
} else {
    $data = Read-R4SdkProfiles $SdkRoot
    [ordered]@{schema=1; valid=$true; sdk_version=$data.sdk_version; hashes=$data.hashes;
        profiles=@($data.Build.profiles.Keys); system_libraries=@($data.Components.libraries.Keys)} | ConvertTo-Json -Depth 10
}
