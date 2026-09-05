param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Reason)

# Explicit local source/configuration revision. This is never called by Build.
# Runtime imports require an owner build/import, not a checksum refresh.
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'Inventory.ps1')
$recoveryRoot = Split-Path $PSScriptRoot -Parent
$lockPath = Join-Path $recoveryRoot 'Provenance/inputs.lock.json'
try {
    $lock = Get-Content -Raw -LiteralPath $lockPath | ConvertFrom-Json -AsHashtable
    $oldFiles = @{}
    foreach ($file in $lock.files) { $oldFiles[$file.path] = $file }
    $newFiles = @()
    $changes = @()
    foreach ($relative in Get-RecoveryInputFiles $recoveryRoot | Sort-Object -CaseSensitive) {
        $path = Get-RecoveryPath $recoveryRoot $relative
        $hash = Get-RecoveryHash $path
        $old = $oldFiles[$relative]
        if (!$old -or $hash -cne $old.sha256) {
            if ($relative -match '^Legal/(Sources|Manifests)/' -or $relative -match '^Runtime/.*\.(R4X|R4D|R4P|R4L)$') {
                throw "Binary/original-source import requires its owner import, not Record-Inputs: $relative"
            }
            $changes += @{path=$relative; before=$(if ($old) {$old.sha256} else {$null}); after=$hash}
        }
        $newFiles += [ordered]@{path=$relative; bytes=([IO.FileInfo]::new($path)).Length; sha256=$hash;
            originalSha256=$(if ($old) {$old.originalSha256} else {$null}); origin=$(if ($old) {$old.origin} else {$null})}
        $oldFiles.Remove($relative)
    }
    foreach ($relative in $oldFiles.Keys) {
        if ($relative -match '^Legal/(Sources|Manifests)/' -or $relative -match '^Runtime/.*\.(R4X|R4D|R4P|R4L)$') {
            throw "Refusing to forget imported original/binary: $relative"
        }
        $changes += @{path=$relative; before=$oldFiles[$relative].sha256; after=$null}
    }
    if ($changes.Count -eq 0) { Write-Host 'No local input changes.'; exit 0 }
    $lock.files = $newFiles
    if (!$lock.ContainsKey('localRevisions')) { $lock.localRevisions = @() }
    $lock.localRevisions += @{reason=$Reason; changes=$changes}
    $oldBytes = [IO.File]::ReadAllBytes($lockPath)
    try {
        Write-RecoveryJson $lockPath $lock
        Test-RecoveryInventory $recoveryRoot | Out-Null
    } catch {
        [IO.File]::WriteAllBytes($lockPath, $oldBytes)
        throw
    }
    Write-Host "Recorded $($changes.Count) explicit input changes: $Reason"
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
