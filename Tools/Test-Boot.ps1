param(
    [ValidateSet('Bios', 'Uefi', 'Both')][string]$Firmware = 'Both',
    [ValidateSet('poweroff', 'reboot', 'ram', 'terminal')][string]$Action = 'poweroff',
    [string]$Zig = '', [string]$Qemu = '', [string]$LimineRoot = '',
    [string]$OvmfCode = '', [string]$OvmfVars = '',
    [ValidateRange(10, 300)][int]$TimeoutSeconds = 120
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'Inventory.ps1')
. (Join-Path $PSScriptRoot 'Runtime.ps1')
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
if ($Action -eq 'terminal') { $kernel = Join-Path $recoveryRoot 'Artifacts/Kernel/bin/recovery.elf' }
$usesRuntime = $Action -in @('ram','terminal')
$runtime = Join-Path $recoveryRoot 'Artifacts/Runtime/runtime.img'
$sourceRoot = Join-Path $recoveryRoot 'Artifacts/HostSources/Distribution'

function Invoke-Checked([string]$Program, [string[]]$Arguments) {
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Host tool failed ($LASTEXITCODE): $Program" }
}

function Remove-RecoveryBootMedium([int]$Port, [bool]$InteractiveTerminal) {
    $client = [Net.Sockets.TcpClient]::new()
    $reader = $null; $writer = $null
    try {
        $client.Connect('127.0.0.1', $Port)
        $stream = $client.GetStream(); $stream.ReadTimeout = 10000; $stream.WriteTimeout = 10000
        $reader = [IO.StreamReader]::new($stream, [Text.UTF8Encoding]::new($false), $false, 4096, $true)
        $writer = [IO.StreamWriter]::new($stream, [Text.UTF8Encoding]::new($false), 4096, $true)
        $writer.AutoFlush = $true
        $events = [Collections.Generic.List[object]]::new()
        function Read-Qmp {
            $line = $reader.ReadLine()
            if ($null -eq $line) { throw 'QMP disconnected.' }
            $message = ConvertFrom-Json -InputObject $line -AsHashtable
            if ($message.ContainsKey('event')) { $events.Add($message) }
            return $message
        }
        function Send-Qmp([string]$Command, [hashtable]$Arguments = @{}) {
            $id = [Guid]::NewGuid().ToString('N')
            $writer.WriteLine((@{execute=$Command; arguments=$Arguments; id=$id} | ConvertTo-Json -Compress -Depth 10))
            do { $message = Read-Qmp } while (!$message.ContainsKey('id') -or $message.id -cne $id)
            if ($message.ContainsKey('error')) { throw "QMP $Command failed: $($message.error | ConvertTo-Json -Compress)" }
            return $message['return']
        }
        $greeting = Read-Qmp
        if (!$greeting.ContainsKey('QMP')) { throw 'Missing QMP greeting.' }
        $null = Send-Qmp 'qmp_capabilities'
        $null = Send-Qmp 'device_del' @{id='recovery-boot'}
        while (@($events | Where-Object {$_.event -ceq 'DEVICE_DELETED' -and $_.data.ContainsKey('device') -and $_.data.device -ceq 'recovery-boot'}).Count -eq 0) { $null = Read-Qmp }
        $null = Send-Qmp 'blockdev-del' @{'node-name'='recovery-source'}
        $null = Send-Qmp 'blockdev-del' @{'node-name'='recovery-file'}
        $nodes = @(Send-Qmp 'query-named-block-nodes')
        if (@($nodes | Where-Object {$_['node-name'] -in @('recovery-source','recovery-file')}).Count -ne 0) { throw 'Boot medium still present in QEMU.' }
        if ($InteractiveTerminal) {
            # Exercise the production console host and a real child program.
            foreach ($key in @('h','e','l','p','ret','p','o','w','e','r','o','f','f','ret')) {
                $null = Send-Qmp 'send-key' @{keys=@(@{type='qcode'; data=$key}); 'hold-time'=40}
                Start-Sleep -Milliseconds 60
            }
        } else { $null = Send-Qmp 'send-key' @{keys=@(@{type='qcode'; data='f'}); 'hold-time'=50} }
        Write-Host 'Recovery USB boot device and file backend removed; late-access witness released.'
    } finally {
        if ($null -ne $writer) { $writer.Dispose() }
        if ($null -ne $reader) { $reader.Dispose() }
        $client.Dispose()
    }
}

try {
    [IO.Directory]::CreateDirectory($output) | Out-Null
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
    # The QEMU host-selection owner is still the original pinned Distribution.
    if (Test-Path -LiteralPath $sourceRoot) { Remove-Item -LiteralPath $sourceRoot -Recurse -Force }
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($sourceRoot)) | Out-Null
    [IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $recoveryRoot 'Legal/Sources/Distribution.zip'), $sourceRoot)
    $imageCreator = Get-RecoveryImageCreator $recoveryRoot $Zig
    . (Join-Path $sourceRoot 'Tools/Qemu-HostProfile.ps1')
    $profile = Resolve-R4QemuHostProfile $Qemu
    $probePath = Join-Path $output 'probe.bin'
    $probeBytes = [byte[]]::new(4096)
    for ($i=0; $i -lt $probeBytes.Length; $i++) { $probeBytes[$i] = ($i*37+11) -band 255 }
    [IO.File]::WriteAllBytes($probePath, $probeBytes)
    $runs = @()
    [string[]]$modes = if ($Firmware -eq 'Both') {@('Bios','Uefi')} else {@($Firmware)}
    $cases = @('valid')
    if ($usesRuntime) {
        if (!(Test-Path -LiteralPath $runtime -PathType Leaf)) { throw 'Runtime volume is missing.' }
        if ($Action -eq 'ram') { $cases += @('missing','truncated','corrupt','duplicate') }
    }
    foreach ($case in $cases) {
        $fixture = Join-Path $output "$case.img"
        $configPath = Join-Path $output "$case-limine.conf"
        $config = "timeout: 0`n`n/R4OS Recovery $Action`n    protocol: limine`n    path: boot():/boot/recovery.elf`n    resolution: 1024x768x32`n"
        $entries = @("$kernel|/boot/recovery.elf", "$configPath|/boot/limine.conf",
            "$(Join-Path $LimineRoot 'limine-bios.sys')|/boot/limine-bios.sys", "$(Join-Path $LimineRoot 'BOOTX64.EFI')|/EFI/BOOT/BOOTX64.EFI")
        if ($usesRuntime) {
            if ($case -ne 'missing') {
                $payload = $runtime
                if ($case -in @('truncated','corrupt')) {
                    $payload = Join-Path $output "$case-runtime.img"
                    Copy-Item -LiteralPath $runtime -Destination $payload -Force
                    $stream = [IO.File]::Open($payload, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite)
                    try {
                        if ($case -eq 'truncated') { $stream.SetLength($stream.Length-512) }
                        else { $stream.Position=100; $value=$stream.ReadByte(); $stream.Position=100; $stream.WriteByte($value -bxor 1) }
                    } finally { $stream.Dispose() }
                }
                $entries += "$payload|/boot/runtime.img"
                $config += "    module_path: boot():/boot/runtime.img`n    module_string: recovery.runtime=1`n"
                if ($case -eq 'duplicate') { $config += "    module_path: boot():/boot/runtime.img`n    module_string: recovery.runtime=1`n" }
            }
        } else {
            $entries += "$probePath|/boot/probe.bin"
            $config += "    module_path: boot():/boot/probe.bin`n    module_string: recovery.probe=foundation`n"
        }
        [IO.File]::WriteAllText($configPath, $config, [Text.UTF8Encoding]::new($false))
        $addList = Join-Path $output "$case-fixture.list"
        [IO.File]::WriteAllText($addList, ($entries -join "`n")+"`n", [Text.UTF8Encoding]::new($false))
        Invoke-Checked $imageCreator @('--output', $fixture, '--size', '128', '--add-list', $addList)
        Invoke-Checked $limine @('bios-install', $fixture)
        $mbr = [byte[]]::new(512)
        $disk = [IO.File]::OpenRead($fixture)
        try { $disk.ReadExactly($mbr) } finally { $disk.Dispose() }
        if ($mbr[450] -ne 12 -or $mbr[466] -ne 0 -or $mbr[482] -ne 0 -or $mbr[498] -ne 0) { throw 'Unexpected fixture partition table.' }
        [string[]]$caseModes = if ($case -eq 'valid') {$modes} else {@($modes[0])}
        foreach ($mode in $caseModes) {
            $serialLog = Join-Path $output "$mode-$case-serial.log"
            $errorLog = Join-Path $output "$mode-$case-qemu.log"
            if (Test-Path -LiteralPath $serialLog) { Remove-Item -LiteralPath $serialLog -Force }
            $arguments = @('-machine', "q35,accel=$($profile.AcceleratorChain)", '-cpu', $profile.CpuModel,
                '-m', '1024', '-smp', '4', '-display', 'none', '-monitor', 'none', '-no-reboot',
                '-nic', 'none', '-serial', "file:$serialLog")
            $qmpPort = 0
            if ($usesRuntime) {
                $listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
                $listener.Start(); $qmpPort = $listener.LocalEndpoint.Port; $listener.Stop()
                $fileNode = @{driver='file'; filename=$fixture; 'node-name'='recovery-file'; 'read-only'=$true} | ConvertTo-Json -Compress
                $rawNode = @{driver='raw'; file='recovery-file'; 'node-name'='recovery-source'; 'read-only'=$true} | ConvertTo-Json -Compress
                $arguments += @('-qmp', "tcp:127.0.0.1:${qmpPort},server=on,wait=off", '-device', 'qemu-xhci,id=recovery-xhci',
                    '-blockdev', $fileNode, '-blockdev', $rawNode, '-device', 'usb-storage,drive=recovery-source,id=recovery-boot,bootindex=1')
            } else { $arguments += @('-drive', "format=raw,file=$fixture", '-snapshot') }
            if ($mode -eq 'Uefi') {
                $varsCopy = Join-Path $output 'OVMF-vars.fd'
                Copy-Item -LiteralPath $OvmfVars -Destination $varsCopy -Force
                $arguments += @('-drive', "if=pflash,format=raw,unit=0,readonly=on,file=$OvmfCode", '-drive', "if=pflash,format=raw,unit=1,file=$varsCopy")
            }
            $start = [Diagnostics.ProcessStartInfo]::new($Qemu)
            $start.UseShellExecute = $false; $start.RedirectStandardOutput = $true; $start.RedirectStandardError = $true
            foreach ($argument in $arguments) { $start.ArgumentList.Add($argument) }
            $process = [Diagnostics.Process]::new(); $process.StartInfo = $start
            $watch = [Diagnostics.Stopwatch]::StartNew()
            Write-Host "Recovery $mode/$Action/${case}: SMP4, $($profile.Name), no SYSTEM partition."
            $started = $false; $exitCode = -1; $removed = $false; $rejected = $false
            $expectedReject = switch ($case) {'missing' {'missing-module'} 'truncated' {'size-mismatch'} 'corrupt' {'hash-mismatch'} 'duplicate' {'duplicate-module'} default {''}}
            try {
                if (!$process.Start()) { throw 'QEMU did not start.' }
                $started = $true; $stdout = $process.StandardOutput.ReadToEndAsync(); $stderr = $process.StandardError.ReadToEndAsync()
                while (!$process.WaitForExit(250)) {
                    if ($watch.Elapsed.TotalSeconds -ge $TimeoutSeconds) { throw "Recovery $mode/$case timed out; inspect $serialLog" }
                    $serial = if (Test-Path -LiteralPath $serialLog) {Get-Content -Raw -LiteralPath $serialLog} else {''}
                    $readyMarker = if ($Action -eq 'terminal') {'\[RECOVERYRAM\] terminal=STARTED'} else {'\[RECOVERYRAM\] boot-medium=WAIT'}
                    if ($usesRuntime -and $case -eq 'valid' -and !$removed -and $serial -match $readyMarker) {
                        Remove-RecoveryBootMedium $qmpPort ($Action -eq 'terminal'); $removed = $true
                    }
                    if ($expectedReject -and $serial -match "\[RECOVERYRAM\] result=REJECT reason=$expectedReject(?:\r?\n)") {
                        $rejected = $true; $process.Kill($true); $process.WaitForExit(); break
                    }
                    if ($serial -match '\[CRASH\]') { throw "Recovery $mode/$case crashed; inspect $serialLog" }
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
            if ($expectedReject) {
                if (!$rejected -or $text -match '\[RECOVERYRAM\] C:=READY') { throw "Recovery negative case $case was not rejected before mounting." }
            } else {
                $marker = switch ($Action) {
                    'ram' {'\[RECOVERYRAM\] result=OK cpus=4 late_modules=R4X,R4D,R4P R4L=R4STD media=OK write_read_delete=OK child_stdio=OK cleanup=OK'}
                    # Unhosted userland output goes to the framebuffer. The
                    # kernel poweroff marker proves the typed command ran.
                    'terminal' {'System poweroff\.'}
                    default {'\[RECOVERYPROBE\] result=OK cpus=4 workers=4 mask=0xf module_bytes=4096 system=absent'}
                }
                if ($exitCode -ne 0 -or $text -notmatch $marker -or $text -match '\[CRASH\]|result=FAILED' -or ($usesRuntime -and !$removed)) { throw "Recovery $mode/$Action/$case failed; inspect $serialLog and $errorLog" }
                if ($Action -eq 'terminal' -and $text -notmatch '\[SMP\] stage=active discovered=4 started=3 online=4 failed=0') { throw 'Production terminal did not retain SMP4.' }
                if ($Action -eq 'reboot' -and $text -notmatch '\[RESET\]') { throw 'QEMU exited without a Recovery reset witness.' }
            }
            $run = [ordered]@{firmware=$mode; action=$Action; case=$case; result='ok'; cpus=4; accelerator=$profile.Name;
                seconds=[Math]::Round($watch.Elapsed.TotalSeconds,3); qemuExitCode=$exitCode; kernelSha256=Get-RecoveryHash $kernel;
                fixtureSha256=Get-RecoveryHash $fixture; systemPartition=$false; serialLog=$serialLog;
                bootMediumRemoved=$removed; expectedReject=$expectedReject; rejectionObserved=$rejected;
                runtimeSha256=$(if ($usesRuntime) {Get-RecoveryHash $runtime} else {$null});
                limineEfiSha256=Get-RecoveryHash (Join-Path $LimineRoot 'BOOTX64.EFI'); ovmfCodeSha256=$(if ($mode -eq 'Uefi') {Get-RecoveryHash $OvmfCode} else {$null})}
            $runs += $run
            Write-RecoveryJson $resultPath @{schema=2; runs=$runs}
            Write-Host "Recovery $mode/$Action/$case OK ($($run.seconds) seconds)."
        }
    }
    exit 0
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
