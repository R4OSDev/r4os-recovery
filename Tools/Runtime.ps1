# Shared deterministic runtime-volume/host-tool build. Caller verifies inputs.
function Get-RecoveryImageCreator([string]$Root, [string]$Zig) {
    $output = Join-Path $Root 'Artifacts/HostTools'
    [IO.Directory]::CreateDirectory($output) | Out-Null
    $program = Join-Path $output $(if ($IsWindows) {'imagecreater.exe'} else {'imagecreater'})
    & $Zig build-exe -OReleaseSafe --cache-dir (Join-Path $output '.Cache') --global-cache-dir (Join-Path $output '.GlobalCache') --dep ntfs_format `
        "-Mroot=$(Join-Path $Root 'Platform/Distribution/Tools/ImageCreator/src/main.zig')" `
        "-Mntfs_format=$(Join-Path $Root 'Platform/SDK/r4os/ntfs_format.zig')" "-femit-bin=$program"
    if ($LASTEXITCODE -ne 0) { throw 'Frozen Recovery ImageCreator build failed.' }
    return $program
}

function Build-RecoveryRuntime([string]$Root, [string]$Zig) {
    $release = Get-RecoveryFields (Join-Path $Root 'VERSION.R4S')
    $identity = Get-RecoveryFields (Join-Path $Root 'Runtime/R4OS/CONFIG/RECOVERY.R4S')
    $shellVersion = Get-RecoveryFields (Join-Path $Root 'Runtime/R4OS/CONFIG/VERSION.R4S')
    if ($identity.RECOVERY_FORMAT[0] -cne '1' -or $identity.RECOVERY_VERSION[0] -cne $release.RECOVERY_VERSION[0] -or
        $shellVersion.RELEASE_VERSION[0] -cne $release.RECOVERY_VERSION[0]) { throw 'Runtime identity/version does not match the Recovery release.' }
    $program = Get-RecoveryImageCreator $Root $Zig
    $output = Join-Path $Root 'Artifacts/Runtime'
    [IO.Directory]::CreateDirectory($output) | Out-Null
    $list = Join-Path $output 'runtime.list'
    $image = Join-Path $output 'runtime.img'
    $files = @(Get-ChildItem -LiteralPath (Join-Path $Root 'Runtime') -File -Recurse -Force |
        Sort-Object { [IO.Path]::GetRelativePath((Join-Path $Root 'Runtime'), $_.FullName).Replace('\','/') } -CaseSensitive)
    $entries = @($files | ForEach-Object {
        $relative = [IO.Path]::GetRelativePath((Join-Path $Root 'Runtime'), $_.FullName).Replace('\','/')
        if ($_.FullName.Contains('|') -or $_.FullName.Contains("`n") -or $_.FullName.Contains("`r")) { throw 'Runtime path cannot be represented in the image list.' }
        "$($_.FullName)|/$relative"
    })
    [IO.File]::WriteAllText($list, ($entries -join "`n")+"`n", [Text.UTF8Encoding]::new($false))
    & $program --output $image --size 64 --volume-only --add-list $list
    if ($LASTEXITCODE -ne 0) { throw 'Recovery runtime volume build failed.' }
    $result = [ordered]@{schema=1; filesystem='FAT32'; partitionStart=0; files=$files.Count;
        image=$image; bytes=([IO.FileInfo]::new($image)).Length; sha256=Get-RecoveryHash $image}
    Write-RecoveryJson (Join-Path $output 'runtime.json') $result
    Write-Host "Recovery runtime: $image ($($result.bytes) bytes, SHA-256 $($result.sha256))"
    return $result
}
