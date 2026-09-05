param(
    [ValidateSet('Bios','Uefi','Both')][string]$Firmware='Both',
    [switch]$OfflineOnly,
    [switch]$StorageAccess,
    [switch]$StorageTools,
    [string]$Zig='', [string]$Qemu='', [string]$LimineRoot='',
    [string]$OvmfCode='', [string]$OvmfVars='',
    [ValidateRange(30,300)][int]$TimeoutSeconds=120
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'Inventory.ps1')
. (Join-Path $PSScriptRoot 'Runtime.ps1')
. (Join-Path $PSScriptRoot 'Storage-Fixtures.ps1')
. (Join-Path $PSScriptRoot 'Guest-Qmp.ps1')
. (Join-Path $PSScriptRoot 'Guest-NetClients.ps1')
if($StorageAccess -or $StorageTools){. (Join-Path $PSScriptRoot 'Storage-Access.Tests.ps1')}
Add-Type -Path (Join-Path $PSScriptRoot 'UI-Framebuffer.cs')
$root=Split-Path $PSScriptRoot -Parent
$workspace=[IO.Path]::GetFullPath((Join-Path $root '../..'))
$suffix=if($IsWindows){'.exe'}else{''}
if(!$Zig){$Zig=Join-Path $workspace "DevKit/Toolchains/Zig/zig$suffix"}
if(!$Qemu){$Qemu=Join-Path $workspace "DevKit/Emulation/QEMU/qemu-system-x86_64$suffix"}
if(!$LimineRoot){$LimineRoot=Join-Path $workspace 'DevKit/Boot/Limine'}
if(!$OvmfCode){$OvmfCode=if($IsLinux){'/usr/share/OVMF/OVMF_CODE_4M.fd'}else{Join-Path $workspace 'DevKit/Emulation/QEMU/share/edk2-x86_64-code.fd'}}
if(!$OvmfVars){$OvmfVars=if($IsLinux){'/usr/share/OVMF/OVMF_VARS_4M.fd'}else{Join-Path $workspace 'DevKit/Emulation/QEMU/share/edk2-i386-vars.fd'}}
$limine=Join-Path $LimineRoot $(if($IsWindows){'limine-tool-windows-x86/limine.exe'}else{'limine'})
$output=Join-Path $root $(if($StorageTools){'Artifacts/BootProbe/storage-tools'}elseif($StorageAccess){'Artifacts/BootProbe/storage-access'}else{'Artifacts/BootProbe/network'})
$kernel=Join-Path $root 'Artifacts/Kernel/bin/recovery.elf'
$runtime=Join-Path $root 'Artifacts/Runtime/runtime.img'
$askpass=Join-Path $output "askpass$suffix"
$resultPath=Join-Path $output 'network-results.json'
$releaseVersion=(Get-RecoveryFields (Join-Path $root 'VERSION.R4S')).RECOVERY_VERSION[0]
$utf8=[Text.UTF8Encoding]::new($false)
$ssh=(Get-Command "ssh$suffix" -CommandType Application | Select-Object -First 1).Source
$sftp=(Get-Command "sftp$suffix" -CommandType Application | Select-Object -First 1).Source
$scp=(Get-Command "scp$suffix" -CommandType Application | Select-Object -First 1).Source
$sshOptions=@('-c','chacha20-poly1305@openssh.com','-o','StrictHostKeyChecking=no','-o',('UserKnownHostsFile='+$(if($IsWindows){'NUL'}else{'/dev/null'})),'-o','LogLevel=ERROR','-o','ConnectTimeout=5','-o','ConnectionAttempts=1')
function Checked([string]$Program,[string[]]$Arguments){& $Program @Arguments;if($LASTEXITCODE -ne 0){throw "Host tool failed: $Program"}}
function Free-Port { $listener=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0);$listener.Start();$port=$listener.LocalEndpoint.Port;$listener.Stop();return $port }
function Wait-Marker([string]$Pattern){
    while($true){
        [string]$text=if(Test-Path -LiteralPath $serialLog){Get-Content -Raw -LiteralPath $serialLog}else{''}
        if($text -match '\[CRASH\]|panic-ret=|result=FAILED'){throw "Guest failure: $serialLog"}
        if($text -match $Pattern){return}
        if($process.HasExited -or $watch.Elapsed.TotalSeconds -gt $TimeoutSeconds){throw "Missing guest marker: $Pattern"}
        Start-Sleep -Milliseconds 50
    }
}
function Capture([string]$Label){$path=Join-Path $output "$name-$Label.ppm";$null=Qmp $session 'screendump' @{filename=$path};return $path}
try{
    [IO.Directory]::CreateDirectory($output)|Out-Null
    Test-RecoveryInventory $root|Out-Null
    foreach($path in @($kernel,$runtime,$Zig,$Qemu,$limine)){if(!(Test-Path -LiteralPath $path -PathType Leaf)){throw "Missing input: $path"}}
    Checked $Zig @('cc','-O2',(Join-Path $PSScriptRoot 'Guest-Askpass.c'),'-o',$askpass)
    $imageCreator=Get-RecoveryImageCreator $root $Zig
    $sources=Join-Path $root 'Artifacts/HostSources/Distribution'
    if(!(Test-Path -LiteralPath $sources)){[IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $root 'Legal/Sources/Distribution.zip'),$sources)}
    . (Join-Path $sources 'Tools/Qemu-HostProfile.ps1')
    $profile=Resolve-R4QemuHostProfile $Qemu
    $inputs=[ordered]@{schema=1;kernel=Get-RecoveryHash $kernel;runtime=Get-RecoveryHash $runtime;builder=Get-RecoveryHash (Join-Path $PSScriptRoot 'Storage-Fixtures.ps1');creator=Get-RecoveryHash $imageCreator;
        efi=Get-RecoveryHash (Join-Path $LimineRoot 'BOOTX64.EFI');bios=Get-RecoveryHash (Join-Path $LimineRoot 'limine-bios.sys')}
    $serialized=$inputs|ConvertTo-Json -Compress;$cache=Join-Path $output 'network-fixture-inputs.json'
    if(!(Test-Path $cache) -or (Get-Content -Raw $cache).Trim() -cne $serialized -or !(Test-Path (Join-Path $output 'disk-1.img'))){$null=New-Installation 1;[IO.File]::WriteAllText($cache,$serialized,$utf8)}
    $payload=Join-Path $output 'payload.bin';$replacement=Join-Path $output 'replacement.bin';$received=Join-Path $output 'received.bin'
    $bytes=[byte[]]::new(131073);for($i=0;$i -lt $bytes.Length;$i++){$bytes[$i]=[byte](($i*37+19)%256)}
    [IO.File]::WriteAllBytes($payload,$bytes);[IO.File]::WriteAllBytes($replacement,$bytes[0..4096])
    $cases=@();if($Firmware -ne 'Uefi'){$cases+=@{mode='Bios';nic='virtio-net-pci'}};if($Firmware -ne 'Bios'){$cases+=@{mode='Uefi';nic='rtl8139'}}
    $cases+=@{mode='Bios';nic='offline'};$runs=@()
    if($OfflineOnly){
        $cases=@(@{mode='Bios';nic='offline'})
        if(Test-Path $resultPath){
            $prior=Get-Content -Raw $resultPath|ConvertFrom-Json -AsHashtable
            $runs=@($prior.runs|Where-Object {$_.adapter -ne 'offline' -and $_.kernelSha256 -ceq $inputs.kernel -and $_.runtimeSha256 -ceq $inputs.runtime})
        }
    }elseif(Test-Path $resultPath){Remove-Item $resultPath -Force}
    foreach($case in $cases){
        $name="$($case.mode)-$($case.nic)";$online=$case.nic -ne 'offline';$clientLog=Join-Path $output "$name-clients.log"
        [IO.File]::WriteAllText($clientLog,'',$utf8)
        $serialLog=Join-Path $output "$name-serial.log";if(Test-Path $serialLog){Remove-Item $serialLog -Force}
        $qmpPort=Free-Port;$sshPort=Free-Port;$ftpPort=Free-Port
        $arguments=@('-machine',"q35,accel=$($profile.AcceleratorChain)",'-cpu',$profile.CpuModel,'-m','1024','-smp','4','-display','none','-monitor','none','-no-reboot','-serial',"file:$serialLog",'-qmp',"tcp:127.0.0.1:$qmpPort,server=on,wait=off",'-device','qemu-xhci,id=rec-xhci',
            '-drive',"if=none,id=usb-media,format=raw,file=$(Join-Path $output 'disk-1.img'),snapshot=on",'-device','usb-storage,drive=usb-media,bootindex=1')
        if($online){$arguments+=@('-netdev',"user,id=rec-net,hostfwd=tcp:127.0.0.1:$sshPort-:22,hostfwd=tcp:127.0.0.1:$ftpPort-:21,hostfwd=tcp:127.0.0.1:2020-:2020",'-device',"$($case.nic),netdev=rec-net")}else{$arguments+=@('-nic','none')}
        if($StorageAccess -and $online){
            $scratch=Join-Path $output "$name-flush-fault.img"
            $file=[IO.File]::Create($scratch);try{$file.SetLength(16MB)}finally{$file.Dispose()}
            # pwritev arms one flush-only error: opening/scanning/claim preparation
            # succeeds, the first raw write succeeds, then the device flush fails.
            $backend=@{driver='blkdebug';'node-name'='storage-fault';image=@{driver='file';filename=$scratch};
                'inject-error'=@(@{event='pwritev';iotype='flush';errno=5;once=$true;immediately=$true})}|ConvertTo-Json -Depth 8 -Compress
            $arguments+=@('-blockdev',$backend,'-device','nvme,drive=storage-fault,serial=R4OS-FAULT-0768')
        }
        if($StorageTools -and $online){
            $scratch=Join-Path $output "$name-format-scratch.img"
            $file=[IO.File]::Create($scratch);try{$file.SetLength(128MB)}finally{$file.Dispose()}
            $arguments+=@('-drive',"if=none,id=storage-tools,format=raw,file=$scratch",'-device','nvme,drive=storage-tools,serial=R4OS-TOOLS-0769')
        }
        if($case.mode -eq 'Uefi'){$vars=Join-Path $output 'network-vars.fd';Copy-Item $OvmfVars $vars -Force;$arguments+=@('-drive',"if=pflash,format=raw,unit=0,readonly=on,file=$OvmfCode",'-drive',"if=pflash,format=raw,unit=1,file=$vars")}
        $start=[Diagnostics.ProcessStartInfo]::new($Qemu);$start.UseShellExecute=$false;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
        foreach($argument in $arguments){$start.ArgumentList.Add($argument)}
        $process=[Diagnostics.Process]::new();$process.StartInfo=$start;$watch=[Diagnostics.Stopwatch]::StartNew();$session=$null;$started=$false
        $savedSectors=@();$diskPath=Join-Path $output 'disk-1.img'
        try{
            if(!$online){
                $disk=[IO.File]::Open($diskPath,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite)
                try{foreach($offset in @(([long]266240*512),([long](266240+2097152-1)*512))){$sector=[byte[]]::new(512);$disk.Position=$offset;$disk.ReadExactly($sector);$savedSectors+=@{offset=$offset;bytes=$sector};Write-At $disk $offset ([byte[]]::new(512))};$disk.Flush($true)}finally{$disk.Dispose()}
            }
            Write-Host "Recovery network $name, SMP4."
            if(!$process.Start()){throw 'QEMU did not start.'};$started=$true;$stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
            Wait-Marker '\[RECOVERY\] shell=READY';$session=Open-Qmp $qmpPort
            if($online){
                Wait-Marker 'DHCP05913 state=bound';Wait-Marker '\[RECOVERYNET\] autostart=RETURNED'
                $ip=Ssh 'IPCONFIG /ALL';if($ip -notmatch '10\.0\.2\.15' -or $ip -notmatch 'dhcp=2'){throw 'Missing actual DHCP/network configuration.'}
                $services=Ssh 'SERVMAN LIST';foreach($service in @('DNSSVC','DHCPSVC','TCPSVC','UDPSVC','SSHD','FTPSVC')){if($services -notmatch $service){throw "Missing service: $service"}}
                Start-Sleep -Milliseconds 1200
                $before=Capture 'before';([RecoveryFrame]::new($before)).RequireArtwork((Join-Path $root 'Runtime/R4OS/MEDIA/RECOVERY.BMP'))
                $banner=Client $ssh (@('-tt','-p',"$sshPort")+$sshOptions+@('r4os@127.0.0.1')) "ECHO SSH-ISOLATED`nEXIT`n"
                foreach($pattern in @(('R4OS Recovery '+[regex]::Escape($releaseVersion)),'Boot medium: USB','running RAM','offline volume','SSH-ISOLATED')){if($banner -notmatch $pattern){throw "Missing SSH session context: $pattern"}}
                if($StorageAccess){Test-StorageAccess}
                if($StorageTools){
                    $text=Storage-Command 'TOOLS'
                    foreach($pattern in @('MBR/GPT=OK','FAT32 quick/NTFS full=OK','mount/read/write/flush=OK')){
                        if(!$text.Contains($pattern)){throw "Missing storage tools witness: $pattern"}
                    }
                }
                $null=Sftp @("get /E/VOLUME.TXT $(Host-Path $received)")
                if([IO.File]::ReadAllText($received) -cne '1/SYSTEM'){throw 'SFTP SYSTEM does not match the mounted volume.'}
                $null=Sftp @('mkdir /E/R4OS','mkdir /E/R4OS/CONFIG',"put $(Host-Path $payload) /E/R4OS/CONFIG/REPAIR.BIN","get /E/R4OS/CONFIG/REPAIR.BIN $(Host-Path $received)")
                Require-Hash $received $payload
                $null=Sftp @("put $(Host-Path $replacement) /C/TEMP/REPLACE.BIN")
                $copy=Ssh 'COPY C:\TEMP\REPLACE.BIN E:\R4OS\CONFIG\REPAIR.BIN';if($copy -notmatch '1 file\(s\) copied'){throw 'Offline replacement failed.'}
                $null=Sftp @("get /E/R4OS/CONFIG/REPAIR.BIN $(Host-Path $received)");Require-Hash $received $replacement
                $null=Sftp @("put $(Host-Path $replacement) /D/BOOT/REPAIR.TXT",'rename /D/BOOT/REPAIR.TXT /D/BOOT/FIXED.TXT','rm /D/BOOT/FIXED.TXT')
                $null=Client $scp (@('-O','-P',"$sshPort")+$sshOptions+@($replacement,'r4os@127.0.0.1:/E/R4OS/CONFIG/SCP.BIN'))
                $null=Client $scp (@('-O','-P',"$sshPort")+$sshOptions+@('r4os@127.0.0.1:/E/R4OS/CONFIG/SCP.BIN',$received));Require-Hash $received $replacement
                $ftp=Open-Ftp
                try{
                    $null=Ftp-Command $ftp 'STOR /C/R4OS/CONFIG/FORBID.BIN' '550'
                    foreach($active in @($false,$true)){
                        # FTP replacement remains the explicit DELE/STOR pair,
                        # preserving the shared create-only upload contract.
                        $null=Ftp-Command $ftp 'DELE /E/R4OS/CONFIG/REPAIR.BIN' '250'
                        Ftp-Transfer $ftp $active $true '/E/R4OS/CONFIG/REPAIR.BIN' $payload
                        Ftp-Transfer $ftp $active $false '/E/R4OS/CONFIG/REPAIR.BIN' $received;Require-Hash $received $payload
                    }
                    Ftp-Transfer $ftp $false $true '/D/BOOT/FTP.BIN' $replacement
                    $null=Ftp-Command $ftp 'DELE /D/BOOT/FTP.BIN' '250'
                    $null=Ftp-Command $ftp 'QUIT' '221'
                }finally{$ftp.Writer.Dispose();$ftp.Reader.Dispose();$ftp.Client.Dispose()}
                $null=Ssh 'COPY C:\R4OS\SOFTWARE\TERMINAL\HELP.R4X E:\BAD.R4X'
                # Client() expects success, so capture the failing command's
                # ERRORLEVEL through a normal interactive shell.
                $denied=Client $ssh (@('-tt','-p',"$sshPort")+$sshOptions+@('r4os@127.0.0.1')) "E:\BAD.R4X`nSET`nECHO DENIAL-RECORDED`nEXIT`n"
                if($denied -match 'Type HELP /S' -or $denied -notmatch 'ERRORLEVEL=1'){throw 'Offline executable was not rejected.'}
                $null=Ssh 'DEL E:\R4OS\CONFIG\REPAIR.BIN'
                $after=Capture 'after';Require-Hash $after $before
            }else{
                $before=Capture 'offline';([RecoveryFrame]::new($before)).RequireArtwork((Join-Path $root 'Runtime/R4OS/MEDIA/RECOVERY.BMP'))
                Send-Keys $session @('up','up','ret');Start-Sleep -Milliseconds 600
                $terminal=Capture 'offline-terminal';([RecoveryFrame]::new($terminal)).RequireContentChanged([RecoveryFrame]::new($before))
                Send-Keys $session @('e','x','i','t','ret');Start-Sleep -Milliseconds 600
                $returned=Capture 'offline-return';([RecoveryFrame]::new($returned)).RequireOutsideUnchanged([RecoveryFrame]::new($before))
                if([RecoveryFrame]::new($returned).RedRow() -le 0){throw 'Offline Terminal did not return to menu.'}
            }
            Send-Keys $session $(if($online){@('up','ret')}else{@('down','ret')})
            while(!$process.WaitForExit(100)){if($watch.Elapsed.TotalSeconds -gt $TimeoutSeconds){throw 'Recovery network acceptance timed out.'}}
            if($process.ExitCode -ne 0){throw 'Guest did not restart cleanly.'}
        }catch{
            if($null -ne $session -and !$process.HasExited){try{$null=Capture 'failed'}catch{}}
            throw
        }finally{
            if($null -ne $session){$session.Writer.Dispose();$session.Reader.Dispose();$session.Client.Dispose()}
            if($started){if(!$process.HasExited){$process.Kill($true);$process.WaitForExit()};[IO.File]::WriteAllText((Join-Path $output "$name-qemu.log"),$stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult(),$utf8)}
            $process.Dispose()
            if($savedSectors.Count){$disk=[IO.File]::Open($diskPath,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite);try{foreach($saved in $savedSectors){Write-At $disk $saved.offset $saved.bytes};$disk.Flush($true)}finally{$disk.Dispose()}}
        }
        [string]$text=Get-Content -Raw $serialLog
        if($text -notmatch '\[SMP\] stage=active discovered=4 started=3 online=4 failed=0' -or $text -notmatch '\[RESET\]' -or $text -match '\[CRASH\]'){throw 'Incomplete SMP4 network acceptance.'}
        $run=[ordered]@{firmware=$case.mode;adapter=$case.nic;result='ok';cpus=4;seconds=[Math]::Round($watch.Elapsed.TotalSeconds,3);kernelSha256=$inputs.kernel;runtimeSha256=$inputs.runtime;serialLog=$serialLog;clients=$clientLog;
            coverage=$(if($online){'SSH shell/exec; SFTP/SCP; active/passive FTP; offline FAT32/NTFS read/create/copy/replace/rename/delete; hashes; executable admission; unchanged menu'}else{'no network; damaged SYSTEM; local Terminal; return and restart'})}
        if($StorageAccess -and $online){$run.storageAccess=$true;$run.coverage+='; local/remote volume uses; raw bounds; exclusive/foreign owner denial; abandoned-claim cleanup; stale generations; real remount/flush failures'}
        if($StorageTools -and $online){$run.storageTools=$true;$run.coverage+='; shared MBR/GPT creation/readback; FAT32 quick and NTFS full; partition claims; mount/read/write/unmount'}
        $runs+=$run;Write-RecoveryJson $resultPath @{schema=1;runs=$runs};Write-Host "Recovery network $name OK ($($run.seconds) seconds)."
    }
    exit 0
}catch{Write-Error "$($_.Exception.Message)`n$($_.ScriptStackTrace)" -ErrorAction Continue;exit 1}
