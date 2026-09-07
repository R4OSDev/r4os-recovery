# Keep publication read-only with respect to already-qualified release assets.
function Read-PreparedRecoveryAssets {
 param([string]$Directory,[string]$Version,[string]$KernelVersion,[string]$Commit,
       [string]$InputsHash,[object[]]$OwnerReceipts,[object[]]$Files)
 $archiveName="R4OS-Recovery-$Version-x86_64.zip"
 $sourceName="R4OS-RECOVERY-SOURCES-$Version.json"
 $expected=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
 $null=$expected.Add($archiveName);$null=$expected.Add($sourceName)
 $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
 $hashes=@{}
 foreach($line in [IO.File]::ReadAllLines((Join-Path $Directory 'SHA256SUMS.txt'))){
  if($line -cnotmatch '^([0-9a-f]{64})  ([A-Za-z0-9_.-]+)$'){throw 'Invalid prepared Recovery checksum record.'}
  $digest=$Matches[1];$name=$Matches[2]
  if(!$expected.Contains($name) -or !$seen.Add($name)){throw 'Unexpected or duplicate prepared Recovery asset.'}
  if((Get-RecoveryHash (Join-Path $Directory $name)) -cne $digest){throw "Prepared Recovery asset changed: $name"}
  $hashes[$name]=$digest
 }
 if(!$seen.SetEquals($expected)){throw 'Prepared Recovery checksums are incomplete.'}
 $source=Get-Content -Raw -LiteralPath (Join-Path $Directory $sourceName)|ConvertFrom-Json
 if($source.schema -ne 1 -or $source.product -cne 'r4os-recovery' -or
    $source.version -cne $Version -or $source.kernelVersion -cne $KernelVersion -or
    $source.technical -or $source.dirty -or $source.commit -cne $Commit -or
    $source.inputsLockSha256 -cne $InputsHash -or $source.packageSha256 -cne $hashes[$archiveName]){
  throw 'Prepared Recovery source/version/input binding differs.'
 }
 $oldReceipts=@($source.ownerReceipts|Sort-Object path -CaseSensitive|Select-Object path,sha256)|ConvertTo-Json -Depth 8 -Compress
 $newReceipts=@($OwnerReceipts|Sort-Object path -CaseSensitive|Select-Object path,sha256)|ConvertTo-Json -Depth 8 -Compress
 $oldFiles=@($source.files|Sort-Object path -CaseSensitive|Select-Object path,bytes,sha256)|ConvertTo-Json -Depth 8 -Compress
 $newFiles=@($Files|Sort-Object path -CaseSensitive|Select-Object path,bytes,sha256)|ConvertTo-Json -Depth 8 -Compress
 if(!$Files.Count -or $oldFiles -cne $newFiles -or $oldReceipts -cne $newReceipts){
  throw 'Recovery artifacts or owner receipts changed since preparation.'
 }
 $notes=Join-Path $Directory 'RELEASE-NOTES.md'
 if(!(Test-Path -LiteralPath $notes -PathType Leaf)){throw 'Prepared Recovery release notes are missing.'}
 return [pscustomobject]@{Version=$Version;Tag="v$Version";DisplayName="R4OS Recovery $Version";
  DistributionCommit=$Commit;Assets=@((Join-Path $Directory $archiveName),(Join-Path $Directory $sourceName),(Join-Path $Directory 'SHA256SUMS.txt'));
  NotesPath=$notes;OutputRoot=$Directory}
}

function Get-PreparedRecoveryRelease {
 param([string]$Root,[string]$Version,[string]$KernelVersion,[string]$Commit)
 $null=Test-RecoveryInventory $Root
 Test-RecoveryPackagePair (Join-Path $Root 'Artifacts/Kernel/bin/recovery.elf') (Join-Path $Root 'Artifacts/Runtime/runtime.img') $Version $KernelVersion
 $receipts=@(Get-ChildItem -LiteralPath (Join-Path $Root 'Provenance') -Filter owner-update-*.json|ForEach-Object {
  [pscustomobject]@{path='Provenance/'+$_.Name;sha256=Get-RecoveryHash $_.FullName}
 })
 $files=@(Get-ChildItem -LiteralPath (Join-Path $Root 'Legal') -File -Recurse|ForEach-Object {
  [pscustomobject]@{path=[IO.Path]::GetRelativePath($Root,$_.FullName).Replace('\','/');bytes=$_.Length;sha256=Get-RecoveryHash $_.FullName}
 })
 foreach($pair in @(@('recovery.elf','Artifacts/Kernel/bin/recovery.elf'),@('runtime.img','Artifacts/Runtime/runtime.img'))){
  $path=Join-Path $Root $pair[1]
  $files += [pscustomobject]@{path=$pair[0];bytes=([IO.FileInfo]$path).Length;sha256=Get-RecoveryHash $path}
 }
 $result=Read-PreparedRecoveryAssets (Join-Path $Root "Artifacts/Releases/$Version") $Version $KernelVersion $Commit (Get-RecoveryHash (Join-Path $Root 'Provenance/inputs.lock.json')) $receipts $files
 Write-Host "Recovery prepared assets verified without regeneration: $($result.OutputRoot)"
 return $result
}

function Test-PreparedRecoveryAssets {
 param([string]$Directory)
 [IO.Directory]::CreateDirectory($Directory)|Out-Null
 $archive=Join-Path $Directory 'R4OS-Recovery-1.2.3-x86_64.zip'
 $source=Join-Path $Directory 'R4OS-RECOVERY-SOURCES-1.2.3.json'
 $notes=Join-Path $Directory 'RELEASE-NOTES.md'
 [IO.File]::WriteAllText($archive,'qualified bytes');[IO.File]::WriteAllText($notes,'custom release notes')
 $commit='a'*40;$inputs='b'*64
 $receipts=@([pscustomobject]@{path='Provenance/owner-update-1.2.3.json';sha256='c'*64})
 $files=@([pscustomobject]@{path='runtime.img';bytes=4096;sha256='d'*64})
 $before=Get-RecoveryHash $archive
 Write-RecoveryJson $source @{schema=1;product='r4os-recovery';version='1.2.3';kernelVersion='1.2.3';technical=$false;dirty=$false;
  commit=$commit;inputsLockSha256=$inputs;packageSha256=$before;ownerReceipts=$receipts;files=$files}
 [IO.File]::WriteAllText((Join-Path $Directory 'SHA256SUMS.txt'),"$before  $([IO.Path]::GetFileName($archive))`n$(Get-RecoveryHash $source)  $([IO.Path]::GetFileName($source))`n")
 $null=Read-PreparedRecoveryAssets $Directory '1.2.3' '1.2.3' $commit $inputs $receipts $files
 foreach($fault in @('source','inputs','receipt','artifact','zip')){
  $testCommit=$commit;$testInputs=$inputs
  if($fault -eq 'source'){$testCommit='e'*40}
  if($fault -eq 'inputs'){$testInputs='e'*64}
  if($fault -eq 'receipt'){$receipts[0].sha256='e'*64}
  if($fault -eq 'artifact'){$files[0].sha256='e'*64}
  if($fault -eq 'zip'){[IO.File]::WriteAllText($archive,'changed bytes')}
  $rejected=$false
  try{$null=Read-PreparedRecoveryAssets $Directory '1.2.3' '1.2.3' $testCommit $testInputs $receipts $files}catch{$rejected=$true}
  if(!$rejected){throw "Prepared Recovery accepted changed $fault"}
  $receipts[0].sha256='c'*64;$files[0].sha256='d'*64
  [IO.File]::WriteAllText($archive,'qualified bytes')
 }
 $null=Read-PreparedRecoveryAssets $Directory '1.2.3' '1.2.3' $commit $inputs $receipts $files
 if((Get-RecoveryHash $archive) -cne $before -or [IO.File]::ReadAllText($notes) -cne 'custom release notes'){throw 'Prepared verification changed bytes/notes.'}
 Write-Host 'Recovery prepared publication: exact assets/notes retained; changed source, lock, receipt, runtime and ZIP rejected.'
}
