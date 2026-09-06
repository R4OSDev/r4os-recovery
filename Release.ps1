param([Parameter(Position=0)][ValidateSet('Prepare','Publish','SelfTest')][string]$Action='Prepare',[switch]$Technical,[switch]$Prerelease)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$requestedAction=$Action;$requestedPrerelease=[bool]$Prerelease;$root=$PSScriptRoot;$workspace=[IO.Path]::GetFullPath((Join-Path $root '../..'))
try {
 . (Join-Path $root 'Tools/Package.ps1')
 . (Join-Path $root 'Tools/PackagePair.ps1')
 . (Join-Path $root 'Tools/Inventory.ps1')
 # Reuse the workspace's existing GitHub release transport. This does not
 # build normal R4OS, inspect its current version or import any components.
 . (Join-Path $root '../Distribution/Tools/Release.ps1') -Action Library
 $script:GitHubRepository='r4os-recovery'
 $version=(Get-RecoveryFields (Join-Path $root 'VERSION.R4S')).RECOVERY_VERSION[0]
 $kernelVersion=(Get-RecoveryFields (Join-Path $root 'Kernel/VERSION.R4S')).KERNEL_VERSION[0]
 if($requestedAction -ceq 'SelfTest'){
  $elf=[IO.File]::ReadAllBytes((Join-Path $root 'Artifacts/Kernel/bin/recovery.elf'))
  $null=Get-RecoveryElfSection $elf '.r4os.recovery.pair'
  Test-RecoveryPackagePair (Join-Path $root 'Artifacts/Kernel/bin/recovery.elf') (Join-Path $root 'Artifacts/Runtime/runtime.img') $version $kernelVersion
  $failed=$false;try{$null=Get-RecoveryElfSection ([byte[]]@(0,1,2)) '.r4os.recovery.pair'}catch{$failed=$true}
  if(!$failed -or $script:GitHubRepository -cne 'r4os-recovery'){throw 'Recovery release contract self-test failed.'}
  Write-Host 'Recovery release/pair self-test PASS (no network publication).';exit 0
 }
 if($requestedAction -ceq 'Publish' -and $Technical){throw 'Technical Recovery candidates cannot be published.'}
 $dirty=@(Invoke-GitCapture $root @('status','--porcelain','--untracked-files=normal'))
 $commit=((Invoke-GitCapture $root @('rev-parse','HEAD')) -join '').Trim()
 $upstream=((Invoke-GitCapture $root @('rev-parse','origin/main')) -join '').Trim()
 $branch=((Invoke-GitCapture $root @('branch','--show-current')) -join '').Trim()
 $remote=((Invoke-GitCapture $root @('remote','get-url','origin')) -join '').Trim()
 if($remote -cne 'https://github.com/R4OSDev/r4os-recovery.git' -or $branch -cne 'main' -or
    (!$Technical -and ($dirty.Count -ne 0 -or $commit -cne $upstream))){throw 'Recovery release requires its clean, pushed main source; local candidates need -Technical.'}
 $package=New-RecoveryPackage -Root $root
 $directory=Join-Path $root ('Artifacts/Releases/'+$version+$(if($Technical){'-technical'}else{''}))
 [IO.Directory]::CreateDirectory($directory)|Out-Null
 $archive=Join-Path $directory (Split-Path $package.path -Leaf);Copy-Item -LiteralPath $package.path -Destination $archive -Force
 $source=Join-Path $directory "R4OS-RECOVERY-SOURCES-$version.json"
 $receipts=@(Get-ChildItem -LiteralPath (Join-Path $root 'Provenance') -Filter owner-update-*.json|Sort-Object Name|ForEach-Object {@{path='Provenance/'+$_.Name;sha256=Get-RecoveryHash $_.FullName}})
 Write-RecoveryJson $source @{schema=1;product='r4os-recovery';version=$version;kernelVersion=$kernelVersion;technical=[bool]$Technical;commit=$commit;dirty=($dirty.Count -ne 0);
  inputsLockSha256=Get-RecoveryHash (Join-Path $root 'Provenance/inputs.lock.json');ownerReceipts=$receipts;packageSha256=$package.sha256;files=$package.manifest.files}
 $checksum=Join-Path $directory 'SHA256SUMS.txt';[IO.File]::WriteAllText($checksum,($package.sha256+'  '+(Split-Path $archive -Leaf)+[Environment]::NewLine+(Get-RecoveryHash $source)+'  '+(Split-Path $source -Leaf)+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
 $notes=Join-Path $directory 'RELEASE-NOTES.md'
 [IO.File]::WriteAllText($notes,('R4OS Recovery '+$version+[Environment]::NewLine+[Environment]::NewLine+'Independent Limine recovery kernel and complete RAM runtime, pinned drivers/services/console tools, keyboard menu, SSH and FTP. Includes installation, SYSTEM replacement, CURRENT/PREVIOUS Recovery update and original sources/licenses.'+[Environment]::NewLine+[Environment]::NewLine+'Package minimum: '+[Math]::Ceiling($package.manifest.minimumRamBytes/1MB)+' MB of OS-usable RAM. Each operation must also reserve its complete working memory before target writes.'+[Environment]::NewLine+'Package SHA256: '+$package.sha256+[Environment]::NewLine),[Text.UTF8Encoding]::new($false))
 $releasePreparation=[pscustomobject]@{Version=$version;Tag='v'+$version;DisplayName='R4OS Recovery '+$version;DistributionCommit=$commit;Assets=@($archive,$source,$checksum);NotesPath=$notes;OutputRoot=$directory}
 if($requestedAction -ceq 'Publish'){
  Publish-Release -Context ([pscustomobject]@{DistributionRoot=$root;CredentialFile=Join-Path $workspace 'Tools/Credentials/Github.json'}) -Preparation $releasePreparation -IsPrerelease $requestedPrerelease
 }
 Write-Host "Recovery assets prepared: $directory (technical=$Technical)"
 exit 0
}catch{Write-Error $_ -ErrorAction Continue;exit 1}
