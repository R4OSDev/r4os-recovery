param(
    [ValidateSet('Bios','Uefi','Both')][string]$Firmware='Both',
    [ValidateSet('All','Usb','Local','Nvme','Clone','Damaged')][string]$Case='All',
    [string]$Zig='', [string]$Qemu='', [string]$LimineRoot='',
    [string]$OvmfCode='', [string]$OvmfVars='',
    [ValidateRange(10,300)][int]$TimeoutSeconds=120
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'Inventory.ps1')
. (Join-Path $PSScriptRoot 'Runtime.ps1')
$root=Split-Path $PSScriptRoot -Parent
$workspace=[IO.Path]::GetFullPath((Join-Path $root '../..'))
$suffix=if($IsWindows){'.exe'}else{''}
if(!$Zig){$Zig=Join-Path $workspace "DevKit/Toolchains/Zig/zig$suffix"}
if(!$Qemu){$Qemu=Join-Path $workspace "DevKit/Emulation/QEMU/qemu-system-x86_64$suffix"}
if(!$LimineRoot){$LimineRoot=Join-Path $workspace 'DevKit/Boot/Limine'}
if(!$OvmfCode){$OvmfCode=if($IsLinux){'/usr/share/OVMF/OVMF_CODE_4M.fd'}else{Join-Path $workspace 'DevKit/Emulation/QEMU/share/edk2-x86_64-code.fd'}}
if(!$OvmfVars){$OvmfVars=if($IsLinux){'/usr/share/OVMF/OVMF_VARS_4M.fd'}else{Join-Path $workspace 'DevKit/Emulation/QEMU/share/edk2-i386-vars.fd'}}
$limine=Join-Path $LimineRoot $(if($IsWindows){'limine-tool-windows-x86/limine.exe'}else{'limine'})
$output=Join-Path $root 'Artifacts/BootProbe/storage'
$kernel=Join-Path $output 'bin/recovery.elf'
$runtime=Join-Path $root 'Artifacts/Runtime/runtime.img'
$resultPath=Join-Path $output 'storage-results.json'
$utf8=[Text.UTF8Encoding]::new($false)

function Checked([string]$Program,[string[]]$Arguments){
    & $Program @Arguments
    if($LASTEXITCODE -ne 0){throw "Host tool failed ($LASTEXITCODE): $Program"}
}
. (Join-Path $PSScriptRoot 'Storage-Fixtures.ps1')

try{
    [IO.Directory]::CreateDirectory($output)|Out-Null
    Test-RecoveryInventory $root|Out-Null
    foreach($path in @($kernel,$runtime,$Zig,$Qemu,$limine)){if(!(Test-Path -LiteralPath $path -PathType Leaf)){throw "Missing test input: $path"}}
    if($Firmware -ne 'Bios'){foreach($path in @($OvmfCode,$OvmfVars)){if(!(Test-Path -LiteralPath $path -PathType Leaf)){throw "Missing firmware: $path"}}}
    $imageCreator=Get-RecoveryImageCreator $root $Zig
    $sources=Join-Path $root 'Artifacts/HostSources/Distribution'
    if(!(Test-Path -LiteralPath $sources)){
        [IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $root 'Legal/Sources/Distribution.zip'),$sources)
    }
    . (Join-Path $sources 'Tools/Qemu-HostProfile.ps1')
    $profile=Resolve-R4QemuHostProfile $Qemu
    $inputs=[ordered]@{schema=1;kernel=Get-RecoveryHash $kernel;runtime=Get-RecoveryHash $runtime;fixtureBuilder=Get-RecoveryHash (Join-Path $PSScriptRoot 'Storage-Fixtures.ps1');
        creator=Get-RecoveryHash $imageCreator;efi=Get-RecoveryHash (Join-Path $LimineRoot 'BOOTX64.EFI');bios=Get-RecoveryHash (Join-Path $LimineRoot 'limine-bios.sys')}
    $cache=Join-Path $output 'fixture-inputs.json'
    $serialized=$inputs|ConvertTo-Json -Compress
    $cached=(Test-Path -LiteralPath $cache) -and ((Get-Content -Raw -LiteralPath $cache).Trim() -ceq $serialized)
    foreach($name in @('disk-1','disk-2','disk-3','damaged','foreign')){if(!(Test-Path -LiteralPath (Join-Path $output "$name.img"))){$cached=$false}}
    if(!$cached){
        foreach($number in @(1,2,3)){$null=New-Installation $number}
        $null=New-Installation 1 $true
        $foreign=[IO.File]::Open((Join-Path $output 'foreign.img'),[IO.FileMode]::Create,[IO.FileAccess]::ReadWrite)
        try{
            $foreign.SetLength(4MB);$mbr=[byte[]]::new(512);$mbr[450]=7;$mbr[510]=85;$mbr[511]=170
            U32 $mbr 440 400;U32 $mbr 454 2048;U32 $mbr 458 6144;Write-At $foreign 0 $mbr
        }finally{$foreign.Dispose()}
        [IO.File]::WriteAllText($cache,$serialized,$utf8)
    }
    if(Test-Path -LiteralPath $resultPath){Remove-Item -LiteralPath $resultPath -Force}
    [string[]]$modes=if($Firmware -eq 'Both'){@('Bios','Uefi')}else{@($Firmware)}
    [string[]]$cases=if($Case -eq 'All'){@('Usb','Local','Nvme','Clone','Damaged')}else{@($Case)}
    $runs=@()
    foreach($scenario in $cases){
        # Full firmware pair for USB/local. Additional faults use one firmware.
        [string[]]$caseModes=if($scenario -in @('Usb','Local')){$modes}else{@($modes[0])}
        foreach($mode in $caseModes){
            $serialLog=Join-Path $output "$mode-$scenario-serial.log"
            $errorLog=Join-Path $output "$mode-$scenario-qemu.log"
            if(Test-Path -LiteralPath $serialLog){Remove-Item -LiteralPath $serialLog -Force}
            $usb=Join-Path $output $(if($scenario -eq 'Damaged'){'damaged.img'}else{'disk-1.img'})
            $local=Join-Path $output 'disk-2.img'
            $nvme=Join-Path $output $(if($scenario -eq 'Clone'){'disk-2.img'}else{'disk-3.img'})
            $usbOrder=if($scenario -in @('Usb','Damaged')){1}else{9}
            $localOrder=if($scenario -in @('Local','Clone')){1}else{10}
            $nvmeOrder=if($scenario -eq 'Nvme'){1}else{11}
            $arguments=@('-machine',"q35,accel=$($profile.AcceleratorChain)",'-cpu',$profile.CpuModel,'-m','1024','-smp','4',
                '-display','none','-monitor','none','-no-reboot','-nic','none','-serial',"file:$serialLog",
                '-device','qemu-xhci,id=storage-xhci',
                '-drive',"if=none,id=usb-media,format=raw,file=$usb,snapshot=on",'-device',"usb-storage,drive=usb-media,bootindex=$usbOrder",
                '-drive',"if=none,id=foreign-media,format=raw,file=$(Join-Path $output 'foreign.img'),snapshot=on",'-device','usb-storage,drive=foreign-media',
                '-drive',"if=none,id=local-media,format=raw,file=$local,snapshot=on",'-device',"ide-hd,drive=local-media,bus=ide.0,bootindex=$localOrder",
                '-drive',"if=none,id=nvme-media,format=raw,file=$nvme,snapshot=on",'-device',"nvme,drive=nvme-media,serial=R4STORAGE3,bootindex=$nvmeOrder")
            if($mode -eq 'Uefi'){
                $vars=Join-Path $output 'OVMF-vars.fd';Copy-Item -LiteralPath $OvmfVars -Destination $vars -Force
                $arguments+=@('-drive',"if=pflash,format=raw,unit=0,readonly=on,file=$OvmfCode",'-drive',"if=pflash,format=raw,unit=1,file=$vars")
            }
            $start=[Diagnostics.ProcessStartInfo]::new($Qemu);$start.UseShellExecute=$false;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
            foreach($argument in $arguments){$start.ArgumentList.Add($argument)}
            $process=[Diagnostics.Process]::new();$process.StartInfo=$start
            $watch=[Diagnostics.Stopwatch]::StartNew();$started=$false
            Write-Host "Recovery storage $mode/$scenario, SMP4, $($profile.Name)."
            try{
                if(!$process.Start()){throw 'QEMU did not start.'}
                $started=$true;$stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
                while(!$process.WaitForExit(250)){
                    if($watch.Elapsed.TotalSeconds -ge $TimeoutSeconds){throw "Storage probe timed out: $serialLog"}
                    if(Test-Path -LiteralPath $serialLog){
                        $text=Get-Content -Raw -LiteralPath $serialLog
                        if($text -match '\[CRASH\]|result=FAILED'){throw "Storage probe failed: $serialLog"}
                    }
                }
                if($process.ExitCode -ne 0){throw "QEMU failed: $errorLog"}
            }finally{
                if($started){
                    if(!$process.HasExited){$process.Kill($true);$process.WaitForExit()}
                    [IO.File]::WriteAllText($errorLog,$stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult(),$utf8)
                }
                $process.Dispose()
            }
            $text=Get-Content -Raw -LiteralPath $serialLog
            if($text -notmatch '\[RECOVERYSTORAGE\] result=OK cpus=4 C=RAM mapping=stable'){throw "Missing storage witness: $serialLog"}
            $sourceLines=[regex]::Matches($text,'(?m)^\[RECOVERYSTORAGE\] source=([^\r\n]+)')
            if($sourceLines.Count -ne 1){throw 'Boot source must be reported exactly once.'}
            $expectedSource=switch($scenario){'Usb'{'ok bus=usb slot=current'} 'Local'{'ok bus=local slot=current'} 'Nvme'{'ok bus=local slot=previous'} 'Clone'{'duplicate-disk-guid bus=unknown slot=current'} 'Damaged'{'installation-unavailable bus=unknown slot=current'}}
            if($sourceLines[0].Groups[1].Value -cne $expectedSource){throw "Unexpected boot source: $($sourceLines[0].Value)"}
            $disks=[regex]::Matches($text,'(?m)^\[RECOVERYSTORAGE\] disk=([^ ]+) bus=([^ ]+) visible=([01]) table=([^ ]+) parts=(\d+) install=([01]) update_recovery=([01])')
            if($disks.Count -ne 4){throw "Expected two local and two USB media, found $($disks.Count)."}
            foreach($disk in $disks){
                $isUsb=$disk.Groups[2].Value -ceq 'usb';$visible=if($isUsb -and $scenario -ne 'Usb'){'0'}else{'1'}
                if($disk.Groups[3].Value -cne $visible){throw "Incorrect media visibility: $($disk.Value)"}
                $install=if($visible -eq '0' -or $scenario -in @('Clone','Damaged') -or ($scenario -eq 'Usb' -and $disk.Groups[1].Value -ceq (Id 1 0))){'0'}else{'1'}
                if($disk.Groups[6].Value -cne $install){throw "Incorrect installation target policy: $($disk.Value)"}
            }
            $r=[regex]::Matches($text,'(?m)^\[RECOVERYSTORAGE\] part=([^ ]+) fs=fat32 letter=R\r?$')
            if($scenario -in @('Clone','Damaged')){if($r.Count -ne 0){throw 'Ambiguous source acquired R:.'}}
            else{
                $bootNumber=switch($scenario){'Usb'{1}'Local'{2}'Nvme'{3}}
                if($r.Count -ne 1 -or $r[0].Groups[1].Value -cne (Id $bootNumber 4)){throw 'R: is not the actual boot RECOVERY partition.'}
                $ntfsCount=[regex]::Matches($text,'fs=ntfs letter=[D-Z]').Count
                if($ntfsCount -ne $(if($scenario -eq 'Usb'){6}else{4})){throw "Incorrect mounted NTFS count: $ntfsCount"}
            }
            if($scenario -eq 'Usb' -and $text -notmatch 'fs=unknown letter=-'){throw 'Unknown foreign filesystem was not retained.'}
            $expectedWrites=if($scenario -in @('Clone','Damaged')){0}elseif($scenario -eq 'Usb'){6}else{4}
            if([regex]::Matches($text,'(?m)^\[RECOVERYSTORAGE\] write_probe=OK').Count -ne $expectedWrites){throw 'NTFS write/read/delete witness is incomplete.'}
            $expectedWitnesses=if($scenario -eq 'Usb'){12}else{8}
            if([regex]::Matches($text,'(?m)^\[RECOVERYSTORAGE\] witness=').Count -ne $expectedWitnesses){throw 'Mounted-volume file access did not cover every expected volume.'}
            $run=[ordered]@{case=$scenario;firmware=$mode;result='ok';cpus=4;accelerator=$profile.Name;seconds=[Math]::Round($watch.Elapsed.TotalSeconds,3);
                source=$expectedSource;kernelSha256=$inputs.kernel;runtimeSha256=$inputs.runtime;serialLog=$serialLog}
            $runs+=$run;Write-RecoveryJson $resultPath @{schema=1;runs=$runs}
            Write-Host "Recovery storage $mode/$scenario OK ($($run.seconds) seconds)."
        }
    }
    exit 0
}catch{Write-Error "$($_.Exception.Message)`n$($_.ScriptStackTrace)" -ErrorAction Continue;exit 1}
