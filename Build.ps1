param(
    [ValidateSet('Verify', 'Embedded', 'Runtime', 'Kernel', 'BootTest', 'RuntimeTest', 'StorageTest', 'StorageAccessTest', 'StorageToolsTest', 'R4PartTest', 'InputTest', 'UITest', 'PackageTest', 'DownloadTest', 'NetworkTest')][string]$Mode = 'Verify',
    [string]$Zig = '', [string]$SdkRoot='',
    [ValidateSet('none', 'poweroff', 'reboot', 'ram', 'storage', 'input', 'ui')][string]$BootProbe = 'none',
    [ValidateSet('Bios', 'Uefi', 'Both')][string]$Firmware = 'Both'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
try {
    . (Join-Path $PSScriptRoot 'Tools/SDKProfile.ps1')
    $sdkContext=Get-RecoverySdkContext $PSScriptRoot $Zig $SdkRoot
    $Zig=$sdkContext.zig
    $env:R4OS_RECOVERY_SDK_ROOT=$sdkContext.sdk_root
    $sdkBuildJson=Join-Path $sdkContext.sdk_root 'Profiles/Build.json'
    . (Join-Path $PSScriptRoot 'Tools/Inventory.ps1')
    $report = Test-RecoveryInventory -Root $PSScriptRoot
    $output = Join-Path $PSScriptRoot 'Artifacts/Verification'
    [IO.Directory]::CreateDirectory($output) | Out-Null
    Write-RecoveryJson (Join-Path $output 'inventory.json') $report
    Write-Host ("Recovery inventory OK: {0} files, {1} modules, {2} binary imports." -f $report.files, $report.modules, $report.imports)
    if ($Mode -eq 'Embedded') {
        . (Join-Path $PSScriptRoot 'Tools/Embedded.ps1')
        $rebuilt=@(Build-RecoveryEmbedded -Root $PSScriptRoot -Zig $Zig)
        foreach($item in $rebuilt){
            $locked=Join-Path $PSScriptRoot ('Runtime'+(Get-RecoveryFields (Join-Path $PSScriptRoot ($item.source+'/module.R4MF'))).TARGET[0])
            if((Get-RecoveryHash $locked) -cne $item.sha256){throw "Rebuilt embedded artifact differs from admitted Runtime: $($item.name)"}
        }
        Write-Host 'All39 embedded source builds match the admitted Runtime bytes.'
        exit 0
    }
    if ($Mode -ne 'Verify') {
        if ($Mode -eq 'BootTest' -and $BootProbe -eq 'none') { $BootProbe = 'poweroff' }
        if ($Mode -eq 'BootTest' -and $BootProbe -eq 'ram') { throw 'Use -Mode RuntimeTest for the RAM witness.' }
        if ($Mode -eq 'RuntimeTest') { $BootProbe = 'ram' }
        if ($Mode -eq 'StorageTest') { $BootProbe = 'storage' }
        if ($Mode -eq 'InputTest') { $BootProbe = 'input' }
        if ($Mode -in @('UITest', 'PackageTest')) { $BootProbe = 'ui' }
        if ($Mode -in @('NetworkTest', 'StorageAccessTest', 'StorageToolsTest', 'R4PartTest', 'DownloadTest')) { $BootProbe = 'none' }
        $release = Get-RecoveryFields (Join-Path $PSScriptRoot 'VERSION.R4S')
        $version = $release.RECOVERY_VERSION[0]
        if ($version -cnotmatch '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$') { throw 'Invalid Recovery version.' }
        $runtimeArguments = @()
        if ($BootProbe -in @('none', 'ram', 'storage', 'input', 'ui') -or $Mode -eq 'Runtime') {
            . (Join-Path $PSScriptRoot 'Tools/Runtime.ps1')
            $runtime = Build-RecoveryRuntime $PSScriptRoot $Zig ($Mode -eq 'RuntimeTest')
            $runtimeArguments = @("-Druntime-sha256=$($runtime.sha256)", "-Druntime-bytes=$($runtime.bytes)")
        }
        if ($Mode -eq 'Runtime') { exit 0 }
        $probes = if ($Mode -eq 'PackageTest') { @('none', 'ui') } else { @($BootProbe) }
        foreach ($probe in $probes) {
            $prefix = Join-Path $PSScriptRoot $(if ($probe -eq 'none') {'Artifacts/Kernel'} else {"Artifacts/BootProbe/$probe"})
            Push-Location (Join-Path $PSScriptRoot 'Kernel')
            try {
                & $Zig build --prefix $prefix "--fork=$(Join-Path $PSScriptRoot 'Platform/Contract')" "-Dsdk-build-profile-json=$sdkBuildJson" "-Drecovery-version=$version" "-Drecovery-probe=$probe" @runtimeArguments
                if ($LASTEXITCODE -ne 0) { throw 'Recovery kernel build failed.' }
            } finally { Pop-Location }
            Write-Host "Recovery kernel: $(Join-Path $prefix 'bin/recovery.elf')"
        }
        if ($Mode -in @('BootTest', 'RuntimeTest')) {
            $pairArguments=@{}
            if($Mode -eq 'RuntimeTest'){$pairArguments.RuntimeImage=$runtime.image;$pairArguments.RequireApi2=$true}
            & pwsh -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'Tools/Test-Boot.ps1') -Firmware $Firmware -Action $BootProbe -Zig $Zig @pairArguments
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
        if ($Mode -in @('NetworkTest', 'StorageAccessTest', 'StorageToolsTest', 'R4PartTest')) {
            & pwsh -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'Tools/Test-Network.ps1') -Firmware $Firmware -Zig $Zig -StorageAccess:($Mode -eq 'StorageAccessTest') -StorageTools:($Mode -eq 'StorageToolsTest') -R4Part:($Mode -eq 'R4PartTest') -TimeoutSeconds 300
            if ($LASTEXITCODE -ne 0) { throw 'Recovery network acceptance failed.' }
        }
        if ($Mode -eq 'UITest') {
            & pwsh -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'Tools/Test-UI.ps1') -Firmware $Firmware -Zig $Zig
            if ($LASTEXITCODE -ne 0) { throw 'Recovery UI acceptance failed.' }
        }
        if ($Mode -eq 'PackageTest') {
            & pwsh -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'Tools/Test-Packages.ps1') -Zig $Zig
            if ($LASTEXITCODE -ne 0) { throw 'Recovery package acceptance failed.' }
        }
        if ($Mode -eq 'DownloadTest') {
            & pwsh -NoLogo -NoProfile -File (Join-Path $PSScriptRoot 'Tools/Test-Downloads.ps1') -Zig $Zig
            if ($LASTEXITCODE -ne 0) { throw 'Recovery download acceptance failed.' }
        }
    }
    exit 0
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
