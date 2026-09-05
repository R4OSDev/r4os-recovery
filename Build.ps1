param(
    [ValidateSet('Verify', 'Kernel')][string]$Mode = 'Verify',
    [string]$Zig = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
try {
    . (Join-Path $PSScriptRoot 'Tools/Inventory.ps1')
    $report = Test-RecoveryInventory -Root $PSScriptRoot
    $output = Join-Path $PSScriptRoot 'Artifacts/Verification'
    [IO.Directory]::CreateDirectory($output) | Out-Null
    Write-RecoveryJson (Join-Path $output 'inventory.json') $report
    Write-Host ("Recovery inventory OK: {0} files, {1} modules, {2} binary imports." -f $report.files, $report.modules, $report.imports)
    if ($Mode -eq 'Kernel') {
        throw 'The executable Recovery kernel build is scheduled for 0.76.2. Verify completed; no kernel artifact was produced.'
    }
    exit 0
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
