param(
 [Parameter(Mandatory)][string]$SdkRoot,[Parameter(Mandatory)][string]$ContractRoot,
 [Parameter(Mandatory)][string]$LibraryRoot,[Parameter(Mandatory)][string]$ToolsRoot,
 [Parameter(Mandatory)][string]$ZigRoot,[Parameter(Mandatory)][string]$InstallRoot,
 [Parameter(Mandatory)][string]$CacheRoot,[Parameter(Mandatory)][string]$NativeCacheRoot,
 [Parameter(Mandatory)][string]$WorkRoot,[Parameter(Mandatory)][string]$ArtifactRoot,
 [switch]$Technical
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
foreach($name in @('SdkRoot','ContractRoot','LibraryRoot','ToolsRoot','ZigRoot','InstallRoot','CacheRoot','NativeCacheRoot','WorkRoot','ArtifactRoot')){
 Set-Variable $name ([IO.Path]::GetFullPath((Get-Variable $name -ValueOnly)))
}
if((Test-Path -LiteralPath $WorkRoot) -or (Test-Path -LiteralPath $ArtifactRoot)){throw 'Select new work and artifact directories.'}
[IO.Directory]::CreateDirectory($WorkRoot)|Out-Null
[IO.Directory]::CreateDirectory($ArtifactRoot)|Out-Null
$success=$false;$utf8=[Text.UTF8Encoding]::new($false);$pwsh=(Get-Process -Id $PID).Path
$fixture=[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../Tests/Build/DesktopHost'))
$proof=[ordered]@{schema=1;host=$(if($IsWindows){'Windows'}else{'Linux'});scope='Actual standalone C and Rust desktop-host builds; guest claim/input/display/close require separate execution';projects=@()}
function Run([string]$Log,[string[]]$Arguments){
 & $pwsh -NoLogo -NoProfile -File @Arguments > (Join-Path $WorkRoot $Log) 2>&1
 if($LASTEXITCODE -ne 0){throw ([IO.File]::ReadAllText((Join-Path $WorkRoot $Log)))}
}
try{
 $projects=Join-Path $WorkRoot 'Projects'
 [IO.Directory]::CreateDirectory($projects)|Out-Null
 Copy-Item -LiteralPath (Join-Path $fixture 'Shared') -Destination (Join-Path $projects 'Shared') -Recurse
 foreach($language in @('C','Rust')){
  $project=Join-Path $projects $language
  Copy-Item -LiteralPath (Join-Path $fixture $language) -Destination $project -Recurse
  $relative=[IO.Path]::GetRelativePath($project,$LibraryRoot).Replace('\','/')
  foreach($name in @('module.R4MF','Cargo.toml')){
   $template=Join-Path $project ($name+'.template')
   if(Test-Path -LiteralPath $template){
    $text=[IO.File]::ReadAllText($template).Replace('{LibraryRelative}',$relative).Replace('{LibraryRoot}',$LibraryRoot.Replace('\','/'))
    [IO.File]::WriteAllText((Join-Path $project $name),$text,$utf8)
    [IO.File]::Delete($template)
   }
  }
  $output=Join-Path $WorkRoot ('Output/'+$language)
  $args=@((Join-Path $SdkRoot 'Tools/Build-Project.ps1'),'-ProjectRoot',$project,'-SdkRoot',$SdkRoot,'-ContractRoot',$ContractRoot,'-ToolsRoot',$ToolsRoot,'-ZigRoot',$ZigRoot,'-InstallRoot',$InstallRoot,'-CacheRoot',$(if($language -ceq 'C'){$NativeCacheRoot}else{$CacheRoot}),'-OutputRoot',$output)
  if($language -ceq 'Rust'){$args+=@('-DependencyRootsJson',(@($LibraryRoot,(Join-Path $projects 'Shared'))|ConvertTo-Json -Compress))}
  if($Technical){$args+='-Technical'}
  Run ($language+'.log') $args
  $receipt=Get-Content -LiteralPath (Join-Path $output 'build.json') -Raw|ConvertFrom-Json -AsHashtable
  if($receipt.status -cne 'success'){throw 'Missing current build success.'}
  $artifact=Join-Path $output $receipt.artifact.file
  $sha=(Get-FileHash -LiteralPath $artifact -Algorithm SHA256).Hash.ToLowerInvariant()
  if($sha -cne $receipt.artifact.sha256){throw 'Artifact/receipt hash differs.'}
  Copy-Item -LiteralPath $artifact -Destination (Join-Path $ArtifactRoot $receipt.artifact.file)
  $proof.projects+=@{language=$language;artifact=$receipt.artifact;receipt_sha256=(Get-FileHash -LiteralPath (Join-Path $output 'build.json') -Algorithm SHA256).Hash.ToLowerInvariant();sdk_version=$receipt.sdk.version;contract_version=$receipt.contract.version}
 }
 [IO.File]::WriteAllText((Join-Path $ArtifactRoot 'builds.json'),($proof|ConvertTo-Json -Depth 12)+"`n",$utf8)
 $success=$true;Write-Host 'PASS: actual C/Rust host builds. Execute each artifact as SHELL in a private guest for the desktop-host acceptance.'
}finally{if($success){Remove-Item -LiteralPath $WorkRoot -Recurse -Force}}
