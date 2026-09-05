param(
    [ValidateSet('Bios', 'Uefi', 'Both')][string]$Firmware = 'Both',
    [ValidateSet('poweroff', 'reboot')][string]$Action = 'poweroff',
    [string]$Zig = '', [string]$Qemu = '', [string]$LimineRoot = '',
    [string]$OvmfCode = '', [string]$OvmfVars = '',
    [ValidateRange(10, 300)][int]$TimeoutSeconds = 120
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'Inventory.ps1')
$recoveryRoot = Split-Path $PSScriptRoot -Parent
$workspace = [IO.Path]::GetFullPath((Join-Path $recoveryRoot '../..'))
$suffix = if ($IsWindows) {'.exe'} else {''}
if (!$Zig) { $Zig = Join-Path $workspace "DevKit/Toolchains/Zig/zig$suffix" }
if (!$Qemu) { $Qemu = Join-Path $workspace "DevKit/Emulation/QEMU/qemu-system-x86_64$suffix" }
if (!$LimineRoot) { $LimineRoot = Join-Path $workspace 'DevKit/Boot/Limine' }
if (!$OvmfCode) {
    $OvmfCode = if ($IsLinux) {'/usr/share/OVMF/OVMF_CODE_4M.fd'} else {Join-Path $workspace 'DevKit/Emulation/QEMU/share/edk2-x86_64-code.fd'}
}
if (!$OvmfVars) {
    $OvmfVars = if ($IsLinux) {'/usr/share/OVMF/OVMF_VARS_4M.fd'} else {Join-Path $workspace 'DevKit/Emulation/QEMU/share/edk2-i386-vars.fd'}
}
$limine = Join-Path $LimineRoot $(if ($IsWindows) {'limine-tool-windows-x86/limine.exe'} else {'limine'})
$output = Join-Path $recoveryRoot "Artifacts/BootProbe/$Action"
$kernel = Join-Path $output 'bin/recovery.elf'
$sourceRoot = Join-Path $recoveryRoot 'Artifacts/HostSources/Distribution'
$hostOutput = Join-Path $recoveryRoot 'Artifacts/HostTools'

function Invoke-Checked([string]$Program, [string[]]$Arguments) {
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Host tool failed ($LASTEXITCODE): $Program" }
}

try {
    $resultPath = Join-Path $output 'boot-results.json'
    if (Test-Path -LiteralPath $resultPath) { Remove-Item -LiteralPath $resultPath -Force }
    Test-RecoveryInventory $recoveryRoot | Out-Null
    foreach ($file in @($Zig, $Qemu, $limine, $kernel, (Join-Path $LimineRoot 'BOOTX64.EFI'), (Join-Path $LimineRoot 'limine-bios.sys'))) {
        if (!(Test-Path -LiteralPath $file -PathType Leaf)) { throw "Required boot test input missing: $file" }
    }
    if ($Firmware -ne 'Bios') {
        foreach ($file in @($OvmfCode, $OvmfVars)) {
            if (!(Test-Path -LiteralPath $file -PathType Leaf)) { throw "UEFI fixture requires matching OVMF code/vars: $file" }
        }
    }
    # Use the already pinned ImageCreator and QEMU host-selection owner, not
    # current Distribution sources or a second FAT32 implementation.
    if (Test-Path -LiteralPath $sourceRoot) { Remove-Item -LiteralPath $sourceRoot -Recurse -Force }
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($sourceRoot)) | Out-Null
    [IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $recoveryRoot 'Legal/Sources/Distribution.zip'), $sourceRoot)
    [IO.Directory]::CreateDirectory($hostOutput) | Out-Null
    $imageCreator = Join-Path $hostOutput "imagecreater$suffix"
    Invoke-Checked $Zig @('build-exe', '-OReleaseSafe', '--dep', 'ntfs_format',
        "-Mroot=$(Join-Path $sourceRoot 'Tools/ImageCreator/src/main.zig')",
        "-Mntfs_format=$(Join-Path $recoveryRoot 'Platform/SDK/r4os/ntfs_format.zig')", "-femit-bin=$imageCreator")
    . (Join-Path $sourceRoot 'Tools/Qemu-HostProfile.ps1')
    $profile = Resolve-R4QemuHostProfile $Qemu
    $fixture = Join-Path $output 'foundation.img'
    $configPath = Join-Path $output 'limine.conf'
    $probePath = Join-Path $output 'probe.bin'
    $probeBytes = [byte[]]::new(4096)
    for ($i=0; $i -lt $probeBytes.Length; $i++) { $probeBytes[$i] = ($i*37+11) -band 255 }
    [IO.File]::WriteAllBytes($probePath, $probeBytes)
    [IO.File]::WriteAllText($configPath, "timeout: 0`n`n/R4OS Recovery foundation`n    protocol: limine`n    path: boot():/boot/recovery.elf`n    module_path: boot():/boot/probe.bin`n    module_string: recovery.probe=foundation`n    resolution: 1024x768x32`n", [Text.UTF8Encoding]::new($false))
    $addList = Join-Path $output 'fixture.list'
    $entries = @("$kernel|/boot/recovery.elf", "$configPath|/boot/limine.conf", "$probePath|/boot/probe.bin",
        "$(Join-Path $LimineRoot 'limine-bios.sys')|/boot/limine-bios.sys", "$(Join-Path $LimineRoot 'BOOTX64.EFI')|/EFI/BOOT/BOOTX64.EFI")
    [IO.File]::WriteAllText($addList, ($entries -join "`n")+"`n", [Text.UTF8Encoding]::new($false))
    Invoke-Checked $imageCreator @('--output', $fixture, '--size', '128', '--add-list', $addList)
    Invoke-Checked $limine @('bios-install', $fixture)
    # This technical fixture has one FAT32 partition, and no SYSTEM/NTFS.
    $mbr = [byte[]]::new(512)
    $disk = [IO.File]::OpenRead($fixture)
    try { $disk.ReadExactly($mbr) } finally { $disk.Dispose() }
    if ($mbr[450] -ne 12 -or $mbr[466] -ne 0 -or $mbr[482] -ne 0 -or $mbr[498] -ne 0) {
        throw 'Unexpected fixture partition table.'
    }
    $runs = @()
    $modes = if ($Firmware -eq 'Both') {@('Bios','Uefi')} else {@($Firmware)}
    foreach ($mode in $modes) {
        $serialLog = Join-Path $output "$mode-serial.log"
        $errorLog = Join-Path $output "$mode-qemu.log"
        if (Test-Path -LiteralPath $serialLog) { Remove-Item -LiteralPath $serialLog -Force }
        $arguments = @('-machine', "q35,accel=$($profile.AcceleratorChain)", '-cpu', $profile.CpuModel,
            '-m', '1024', '-smp', '4', '-display', 'none', '-monitor', 'none', '-no-reboot',
            '-nic', 'none', '-serial', "file:$serialLog", '-drive', "format=raw,file=$fixture", '-snapshot')
        if ($mode -eq 'Uefi') {
            $varsCopy = Join-Path $output 'OVMF-vars.fd'
            Copy-Item -LiteralPath $OvmfVars -Destination $varsCopy -Force
            $arguments += @('-drive', "if=pflash,format=raw,unit=0,readonly=on,file=$OvmfCode",
                '-drive', "if=pflash,format=raw,unit=1,file=$varsCopy")
        }
        $start = [Diagnostics.ProcessStartInfo]::new($Qemu)
        $start.UseShellExecute = $false
        $start.RedirectStandardOutput = $true
        $start.RedirectStandardError = $true
        foreach ($argument in $arguments) { $start.ArgumentList.Add($argument) }
        $process = [Diagnostics.Process]::new()
        $process.StartInfo = $start
        $watch = [Diagnostics.Stopwatch]::StartNew()
        Write-Host "Recovery $mode/${Action}: SMP4, $($profile.Name), no SYSTEM partition."
        $started = $false
        $exitCode = -1
        try {
            if (!$process.Start()) { throw 'QEMU did not start.' }
            $started = $true
            $stdout = $process.StandardOutput.ReadToEndAsync()
            $stderr = $process.StandardError.ReadToEndAsync()
            while (!$process.WaitForExit(1000)) {
                if ($watch.Elapsed.TotalSeconds -ge $TimeoutSeconds) {
                    throw "Recovery $mode timed out; inspect $serialLog"
                }
                if ((Test-Path -LiteralPath $serialLog) -and (Get-Content -Raw -LiteralPath $serialLog) -match '\[CRASH\]') {
                    throw "Recovery $mode crashed; inspect $serialLog"
                }
            }
            $exitCode = $process.ExitCode
        } finally {
            if ($started) {
                if (!$process.HasExited) { $process.Kill($true); $process.WaitForExit() }
                [IO.File]::WriteAllText($errorLog, $stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult(), [Text.UTF8Encoding]::new($false))
            }
            $process.Dispose()
        }
        $text = Get-Content -Raw -LiteralPath $serialLog
        if ($exitCode -ne 0 -or $text -notmatch '\[RECOVERYPROBE\] result=OK cpus=4 workers=4 mask=0xf module_bytes=4096 system=absent' -or
            $text -match '\[CRASH\]|result=FAILED') { throw "Recovery $mode/$Action failed; inspect $serialLog and $errorLog" }
        if ($Action -eq 'reboot' -and $text -notmatch '\[RESET\]') { throw 'QEMU exited without a Recovery reset witness.' }
        $run = [ordered]@{firmware=$mode; action=$Action; result='ok'; cpus=4; accelerator=$profile.Name;
            seconds=[Math]::Round($watch.Elapsed.TotalSeconds,3); qemuExitCode=$exitCode; kernelSha256=Get-RecoveryHash $kernel;
            fixtureSha256=Get-RecoveryHash $fixture; systemPartition=$false; serialLog=$serialLog;
            limineEfiSha256=Get-RecoveryHash (Join-Path $LimineRoot 'BOOTX64.EFI');
            ovmfCodeSha256=$(if ($mode -eq 'Uefi') {Get-RecoveryHash $OvmfCode} else {$null})}
        $runs += $run
        Write-RecoveryJson $resultPath @{schema=1; runs=$runs}
        Write-Host "Recovery $mode/$Action OK ($($run.seconds) seconds)."
    }
    exit 0
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
