param([Parameter(Mandatory)][string]$OldRecovery,[Parameter(Mandatory)][string]$NewRecovery,
      [Parameter(Mandatory)][string]$ReleasePackage,[Parameter(Mandatory)][string]$BaseImage)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$root=Split-Path $PSScriptRoot -Parent;$workspace=[IO.Path]::GetFullPath((Join-Path $root '../..'))
$dist=Join-Path $workspace 'Repositories/Distribution'
. (Join-Path $PSScriptRoot 'Inventory.ps1')
. (Join-Path $dist 'Tools/InstallationImage.Check.ps1')
. (Join-Path $dist 'Tools/RecoveryBudget.ps1')
$null=Test-RecoveryInventory $root
$out=Join-Path $root 'Artifacts/Budgets';[IO.Directory]::CreateDirectory($out)|Out-Null
$suffix=if($IsWindows){'.exe'}else{''};$zig=Join-Path $workspace "DevKit/Toolchains/Zig/zig$suffix"
$zipSource=Join-Path $out 'zip-source'
if(!(Test-Path $zipSource)){[IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $root 'Legal/Sources/Protocols-R4Zip.zip'),$zipSource)}
$sdk=Join-Path $root 'Platform/SDK';$tool=Join-Path $out "budget-host$suffix"
& $zig build-exe -OReleaseSafe --dep r4os --dep zip_core "-Mroot=$(Join-Path $root 'RecoveryTools/Menu/src/recovery_fixture.zig')" --dep r4os_contract "-Mr4os=$(Join-Path $sdk 'r4os.zig')" --dep r4os "-Mzip_core=$(Join-Path $zipSource 'src/zip_core.zig')" "-Mr4os_contract=$(Join-Path $root 'Platform/Contract/Generated/SDK/Zig/package.zig')" "-femit-bin=$tool"
if($LASTEXITCODE -ne 0){throw 'Budget host build failed.'}
$result=Join-Path $out 'budget-results.json';$volume=Join-Path $out 'RECOVERY.img'
& $tool --budget $OldRecovery $NewRecovery $ReleasePackage $result $volume
if($LASTEXITCODE -ne 0){throw 'Budget/slot preflight failed.'}
$checked=Test-R4OSInstallationImage -Image $BaseImage
$prediction=Test-R4RecoveryCacheBudget -FreeBytes $checked.recoveryFreeBytes -ClusterBytes $checked.recoveryClusterBytes -ReleaseBytes ([IO.FileInfo]$ReleasePackage).Length -RecoveryBytes ([IO.FileInfo]$NewRecovery).Length
$rejected=$false;try{$null=Test-R4RecoveryCacheBudget -FreeBytes $checked.recoveryFreeBytes -ClusterBytes $checked.recoveryClusterBytes -ReleaseBytes 512MB -RecoveryBytes ([IO.FileInfo]$NewRecovery).Length}catch{$rejected=$true}
if(!$rejected){throw 'Overfull release combination accepted by producer.'}
# Independent physical FAT inspection after embedding only the host-produced
# RECOVERY region in a disposable copy of the existing common image.
$image=Join-Path $out 'budget.img';Copy-Item -LiteralPath $BaseImage -Destination $image -Force
$f=[IO.File]::Open($image,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None);$v=[IO.File]::OpenRead($volume)
try{$f.Position=$checked.installation.partitions.RECOVERY.firstLba*512;$v.CopyTo($f);$f.Flush($true)}finally{$v.Dispose();$f.Dispose()}
$view=[InstallationImageCheck]::new($image)
try{
 $physicalFree=$view.Volumes['RECOVERY'].FreeBytes
 foreach($path in @('INSTALL/RELEASE.ZIP','INSTALL/RELEASE.PART','INSTALL/RECOVERY.ZIP','INSTALL/RECOVERY.PART')){
  $source=if($path.StartsWith('INSTALL/RELEASE.')){$ReleasePackage}else{$NewRecovery}
  if([InstallationImageCheck]::Hash($view.Volumes['RECOVERY'].ReadFile($path)) -cne (Get-RecoveryHash $source)){throw 'Budget cache content mismatch.'}
 }
 if($physicalFree -le 0){throw 'No capacity margin remains.'}
}finally{$view.Dispose()}
$record=Get-Content -Raw -LiteralPath $result|ConvertFrom-Json -AsHashtable
$record.physicalFreeBytes=$physicalFree;$record.producerBudget=$prediction
$record.inputs=@{old=Get-RecoveryHash $OldRecovery;next=Get-RecoveryHash $NewRecovery;release=Get-RecoveryHash $ReleasePackage;base=Get-RecoveryHash $BaseImage;runner=Get-RecoveryHash $PSCommandPath;hostSource=Get-RecoveryHash (Join-Path $root 'RecoveryTools/Menu/src/recovery_fixture.zig')}
Write-RecoveryJson $result $record
Write-Host "Recovery budget PASS: 512 MB, both full slots, both archive pairs, 1 MB metadata reserve; physical free $physicalFree B."
