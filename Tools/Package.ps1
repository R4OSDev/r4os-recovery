# Recovery owns its independent release package. No normal R4OS build is run.
function New-RecoveryPackage {
    param([string]$Root=(Split-Path $PSScriptRoot -Parent),[string]$Destination='',
          [ValidateRange(1,8589934592)][uint64]$MinimumRamBytes=5368709120)
    $ErrorActionPreference='Stop'
    . (Join-Path $PSScriptRoot 'Inventory.ps1')
    $null=Test-RecoveryInventory $Root
    . (Join-Path $PSScriptRoot 'PackagePair.ps1')
    $version=(Get-RecoveryFields (Join-Path $Root 'VERSION.R4S')).RECOVERY_VERSION[0]
    $kernelVersion=(Get-RecoveryFields (Join-Path $Root 'Kernel/VERSION.R4S')).KERNEL_VERSION[0]
    if($version -cnotmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' -or $kernelVersion -cnotmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'){throw 'Invalid Recovery version.'}
    Test-RecoveryPackagePair (Join-Path $Root 'Artifacts/Kernel/bin/recovery.elf') (Join-Path $Root 'Artifacts/Runtime/runtime.img') $version $kernelVersion
    $output=Join-Path $Root 'Artifacts/Packages'
    [IO.Directory]::CreateDirectory($output)|Out-Null
    if(!$Destination){$Destination=Join-Path $output "R4OS-Recovery-$version-x86_64.zip"}
    $stage=Join-Path $output 'staging'
    if(Test-Path -LiteralPath $stage){Remove-Item -LiteralPath $stage -Recurse -Force}
    [IO.Directory]::CreateDirectory($stage)|Out-Null
    Copy-Item -LiteralPath (Join-Path $Root 'Artifacts/Kernel/bin/recovery.elf') -Destination (Join-Path $stage 'recovery.elf')
    Copy-Item -LiteralPath (Join-Path $Root 'Artifacts/Runtime/runtime.img') -Destination (Join-Path $stage 'runtime.img')
    Copy-Item -LiteralPath (Join-Path $Root 'Legal') -Destination (Join-Path $stage 'Legal') -Recurse
    $seen=[Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    $files=@(Get-ChildItem -LiteralPath $stage -File -Recurse | Sort-Object FullName -CaseSensitive | ForEach-Object {
        $path=[IO.Path]::GetRelativePath($stage,$_.FullName).Replace('\','/')
        if($path.Length -gt 255 -or $path -cmatch '[^\x20-\x7e]|[<>:"\\|?*]' -or !$seen.Add($path)){throw "Unsupported package path: $path"}
        foreach($part in $path.Split('/')){if(!$part -or $part -in @('.','..') -or $part.EndsWith('.') -or $part.EndsWith(' ')){throw "Unsupported path component: $path"}}
        [ordered]@{path=$path;bytes=$_.Length;sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()}
    })
    if($files.Count -ge 4096){throw 'Too many Recovery package files.'}
    $lock=Get-Content -Raw -LiteralPath (Join-Path $Root 'Provenance/inputs.lock.json')|ConvertFrom-Json -AsHashtable
    $contract=@($lock.sources|Where-Object {$_.id -eq 'Contract'})[0]
    $ownerReceipts=@(Get-ChildItem -LiteralPath (Join-Path $Root 'Provenance') -Filter 'owner-update-*.json' | Sort-Object { [version]($_.BaseName.Substring('owner-update-'.Length)) })
    $contractCommit=$contract.commit
    foreach($receipt in $ownerReceipts){
        $value=Get-Content -Raw -LiteralPath $receipt.FullName|ConvertFrom-Json -AsHashtable
        if(!$value.ContainsKey('owners')){continue}
        foreach($owner in @($value.owners)){
            if(($owner.ContainsKey('pendingOwnerCommit') -and $owner.pendingOwnerCommit) -or
               ($owner.ContainsKey('sourceCommit') -and $owner.sourceCommit -cnotmatch '^[0-9a-f]{40}$')){throw 'Recovery owner provenance is not finalized.'}
            if($owner.owner -eq 'Contract' -and $owner.ContainsKey('sourceCommit')){
                $contractCommit=$owner.sourceCommit
            }
        }
    }
    if($contractCommit -cnotmatch '^[0-9a-f]{40}$'){throw 'The platform Contract owner commit is not finalized.'}
    $manifest=[ordered]@{schema=1;product='r4os-recovery';architecture='x86_64';recoveryVersion=$version;recoveryKernelVersion=$kernelVersion;
        platformContract=[ordered]@{commit=$contractCommit;sha256=(Get-FileHash -LiteralPath (Join-Path $Root 'Platform/Contract/API/ApiContract.json') -Algorithm SHA256).Hash.ToLowerInvariant()};
        runtime=[ordered]@{format='fat32';logicalSectorBytes=512};files=$files;minimumRamBytes=$MinimumRamBytes}
    Write-RecoveryJson (Join-Path $stage 'manifest.json') $manifest
    if(Test-Path -LiteralPath $Destination){Remove-Item -LiteralPath $Destination -Force}
    [IO.Compression.ZipFile]::CreateFromDirectory($stage,$Destination,[IO.Compression.CompressionLevel]::Optimal,$false)
    # Independent producer floor: two slots and its own ZIP/PART must fit.
    # The normal R4OS producer checks the additional real release ZIP pair
    # against the actual installed FAT allocation, before publication.
    [long]$slotBytes=0
    foreach($file in Get-ChildItem -LiteralPath $stage -File -Recurse){$slotBytes+=[long]([Math]::Ceiling($file.Length/4096.0)*4096)}
    [long]$archiveBytes=[Math]::Ceiling(([IO.FileInfo]$Destination).Length/4096.0)*4096
    if(2*$slotBytes+2*$archiveBytes+3MB -gt 512MB){throw 'Recovery package exceeds the shared 512 MB partition budget for two slots and its ZIP/PART workspace.'}
    return [ordered]@{path=$Destination;version=$version;bytes=([IO.FileInfo]$Destination).Length;sha256=(Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash.ToLowerInvariant();manifest=$manifest}
}
