param(
    [ValidateSet('Verify', 'Runtime', 'Kernel', 'BootTest', 'RuntimeTest', 'StorageTest', 'InputTest', 'UITest', 'NetworkTest')][string]$Mode = 'Verify',
    [string]$Zig = '',
    [ValidateSet('none', 'poweroff', 'reboot', 'ram', 'storage', 'input', 'ui')][string]$BootProbe = 'none',
    [ValidateSet('Bios', 'Uefi', 'Both')][string]$Firmware = 'Both'
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
    if ($Mode -ne 'Verify') {
        if ($Mode -eq 'BootTest' -and $BootProbe -eq 'none') { $BootProbe = 'poweroff' }
        if ($Mode -eq 'BootTest' -and $BootProbe -eq 'ram') { throw 'Use -Mode RuntimeTest for the RAM witness.' }
        if ($Mode -eq 'RuntimeTest') { $BootProbe = 'ram' }
        if ($Mode -eq 'StorageTest') { $BootProbe = 'storage' }
        if ($Mode -eq 'InputTest') { $BootProbe = 'input' }
        if ($Mode -eq 'UITest') { $BootProbe = 'ui' }
        if ($Mode -eq 'NetworkTest') { $BootProbe = 'none' }
        if (!$Zig) {
            $Zig = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot $(if ($IsWindows) {'../../DevKit/Toolchains/Zig/zig.exe'} else {'../../DevKit/Toolchains/Zig/zig'})))
        }
        $expected = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'Provenance/inputs.lock.json') | ConvertFrom-Json -AsHashtable
        $actualVersion = & $Zig version
        if ($LASTEXITCODE -ne 0 -or $actualVersion -cne $expected.toolchain.version) { throw 'Recovery requires the recorded Zig version.' }
        $release = Get-RecoveryFields (Join-Path $PSScriptRoot 'VERSION.R4S')
        $version = $release.RECOVERY_VERSION[0]
        if ($version -cnotmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') { throw 'Invalid Recovery version.' }
        $runtimeArguments = @()
        if ($BootProbe -in @('none', 'ram', 'storage', 'input', 'ui') -or $Mode -eq 'Runtime') {
            . (Join-Path $PSScriptRoot 'Tools/Runtime.ps1')
            $runtime = Build-RecoveryRuntime $PSScriptRoot $Zig
            $runtimeArguments = @("-Druntime-sha256=$($runtime.sha256)", "-Druntime-bytes=$($runtime.bytes)")
        }
        if ($Mode -eq 'Runtime') { exit 0 }
        $prefix = Join-Path $PSScriptRoot $(if ($BootProbe -eq 'none') {'Artifacts/Kernel'} else {"Artifacts/BootProbe/$BootProbe"})
        Push-Location (Join-Path $PSScriptRoot 'Kernel')
        try {
            & $Zig build --prefix $prefix "--fork=$(Join-Path $PSScriptRoot 'Platform/Contract')" "-Drecovery-version=$version" "-Drecovery-probe=$BootProbe" @runtimeArguments
            if ($LASTEXITCODE -ne 0) { throw 'Recovery kernel build failed.' }
        } finally { Pop-Location }
        Write-Host "Recovery kernel: $(Join-Path $prefix 'bin/recovery.elf')"
        if ($Mode -in @('BootTest', 'RuntimeTest')) {
            & pwsh -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'Tools/Test-Boot.ps1') -Firmware $Firmware -Action $BootProbe -Zig $Zig
            if ($LASTEXITCODE -ne 0) { throw 'Recovery boot acceptance failed.' }
        }
        if ($Mode -eq 'StorageTest') {
            & pwsh -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'Tools/Test-Storage.ps1') -Firmware $Firmware -Zig $Zig
            if ($LASTEXITCODE -ne 0) { throw 'Recovery storage acceptance failed.' }
        }
        if ($Mode -eq 'InputTest') {
            & pwsh -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'Tools/Test-Input.ps1') -Firmware $Firmware -Zig $Zig
            if ($LASTEXITCODE -ne 0) { throw 'Recovery input acceptance failed.' }
        }
        if ($Mode -eq 'NetworkTest') {
            & pwsh -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'Tools/Test-Network.ps1') -Firmware $Firmware -Zig $Zig
            if ($LASTEXITCODE -ne 0) { throw 'Recovery network acceptance failed.' }
        }
        if ($Mode -eq 'UITest') {
            & pwsh -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'Tools/Test-UI.ps1') -Firmware $Firmware -Zig $Zig
            if ($LASTEXITCODE -ne 0) { throw 'Recovery UI acceptance failed.' }
        }
    }
    exit 0
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
