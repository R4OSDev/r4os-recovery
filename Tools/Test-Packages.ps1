param([switch]$HostOnly,[switch]$GuestOnly,[string]$Zig='', [string]$Qemu='',
      [ValidateRange(60,300)][int]$TimeoutSeconds=240)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
if($HostOnly -and $GuestOnly){throw 'Choose either HostOnly or GuestOnly.'}
. (Join-Path $PSScriptRoot 'Inventory.ps1')
. (Join-Path $PSScriptRoot 'Runtime.ps1')
. (Join-Path $PSScriptRoot 'Package.ps1')
. (Join-Path $PSScriptRoot 'Storage-Fixtures.ps1')
. (Join-Path $PSScriptRoot 'Guest-Qmp.ps1')
. (Join-Path $PSScriptRoot 'Guest-NetClients.ps1')
$root=Split-Path $PSScriptRoot -Parent
$workspace=[IO.Path]::GetFullPath((Join-Path $root '../..'))
$suffix=if($IsWindows){'.exe'}else{''}
if(!$Zig){$Zig=Join-Path $workspace "DevKit/Toolchains/Zig/zig$suffix"}
if(!$Qemu){$Qemu=Join-Path $workspace "DevKit/Emulation/QEMU/qemu-system-x86_64$suffix"}
$LimineRoot=Join-Path $workspace 'DevKit/Boot/Limine'
$limine=Join-Path $LimineRoot $(if($IsWindows){'limine-tool-windows-x86/limine.exe'}else{'limine'})
$output=Join-Path $root 'Artifacts/BootProbe/packages'
# Existing UI probe enables the regular stdout mirror and readiness markers.
# Package payloads still contain the separately built production kernel.
$kernel=Join-Path $root 'Artifacts/BootProbe/ui/bin/recovery.elf'
$runtime=Join-Path $root 'Artifacts/Runtime/runtime.img'
$releaseVersion=(Get-RecoveryFields (Join-Path $root 'VERSION.R4S')).RECOVERY_VERSION[0]
$utf8=[Text.UTF8Encoding]::new($false)
function Checked([string]$Program,[string[]]$Arguments){& $Program @Arguments;if($LASTEXITCODE -ne 0){throw "Host tool failed: $Program"}}
function Free-Port {$l=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0);$l.Start();$p=$l.LocalEndpoint.Port;$l.Stop();return $p}
function Wait-Marker([string]$Pattern){
    while($true){
        $text=if(Test-Path -LiteralPath $serialLog){Get-Content -Raw -LiteralPath $serialLog}else{''}
        if($text -match '\[CRASH\]|panic-ret=|result=FAILED'){throw "Guest failure: $serialLog"}
        if($text -match $Pattern){return}
        if($process.HasExited -or $watch.Elapsed.TotalSeconds -gt $TimeoutSeconds){throw "Missing marker: $Pattern"}
        Start-Sleep -Milliseconds 50
    }
}
function Package-Command([string]$Argument){
    $text=Client $ssh (@('-p',"$sshPort")+$sshOptions+@('r4os@127.0.0.1',"C:\R4OS\SOFTWARE\RECOVERY\RECOVERY.R4X /PACKAGESMOKE $Argument")) '' 60000
    if($text -notmatch '\[PACKAGERAM\] resident=pinned' -or $text -notmatch '\[PACKAGESMOKE\].*result=OK writes=0'){throw "Incomplete package witness: $Argument"}
    return $text
}
function Package-Detach {
    $start=[Diagnostics.ProcessStartInfo]::new($ssh);$start.UseShellExecute=$false
    $start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true;$start.RedirectStandardInput=$true
    $start.Environment['SSH_ASKPASS']=$askpass;$start.Environment['SSH_ASKPASS_REQUIRE']='force';$start.Environment['DISPLAY']='recovery-package-acceptance'
    foreach($argument in (@('-p',"$sshPort")+$sshOptions+@('r4os@127.0.0.1','C:\R4OS\SOFTWARE\RECOVERY\RECOVERY.R4X /PACKAGESMOKE HOLD'))){$start.ArgumentList.Add($argument)}
    $holder=[Diagnostics.Process]::Start($start)
    try{
        $holder.StandardInput.Close();$holderOut=$holder.StandardOutput.ReadToEndAsync();$holderErr=$holder.StandardError.ReadToEndAsync()
        $deadline=[DateTime]::UtcNow.AddSeconds(60);$ready=$false
        while([DateTime]::UtcNow -lt $deadline -and !$holder.HasExited){
            if((Ssh 'DIR C:\TEMP') -match 'PACKAGE.RDY'){$ready=$true;break}
            Start-Sleep -Milliseconds 200
        }
        if(!$ready){throw 'Package preparation did not become ready for source removal.'}
        $null=Qmp $session 'device_del' @{id='package-media'}
        # USB device deletion completes asynchronously. Verify the device is
        # gone, then close its drive so even the host backend is unavailable.
        $removed=$false
        for($i=0;$i -lt 50;$i++){
            $tree=Qmp $session 'human-monitor-command' @{'command-line'='info qtree'}
            if($tree -notmatch 'id "package-media"'){$removed=$true;break}
            Start-Sleep -Milliseconds 50
        }
        if(!$removed){throw 'Package boot medium remained attached.'}
        $null=Qmp $session 'human-monitor-command' @{'command-line'='drive_del boot-media'}
        $blocks=Qmp $session 'query-block'
        if(@($blocks|Where-Object {$_.device -eq 'boot-media'}).Count){throw 'Package boot backend remained open.'}
        $null=Ssh 'COPY C:\R4OS\CONFIG\VERSION.R4S C:\TEMP\PACKAGE.REL'
        if(!$holder.WaitForExit(30000)){throw 'Package RAM verification timed out after source removal.'}
        $text=$holderOut.GetAwaiter().GetResult();$errors=$holderErr.GetAwaiter().GetResult()
        if($holder.ExitCode -ne 0 -or $text -notmatch 'source-detached original_zip=SHA256 payload=SHA256 recovery=SHA256 target_plan=RETAINED' -or $text -notmatch 'result=OK writes=0'){throw "Package source independence failed: $text $errors"}
        return $text
    }finally{
        if(!$holder.HasExited){$holder.Kill($true);$holder.WaitForExit()}
        [IO.File]::AppendAllText($clientLog,"HOLD after source removal`n$($holderOut.GetAwaiter().GetResult())$($holderErr.GetAwaiter().GetResult())`n",$utf8)
        $holder.Dispose()
    }
}
try {
    Test-RecoveryInventory $root|Out-Null
    [IO.Directory]::CreateDirectory($output)|Out-Null
    $imageCreator=Get-RecoveryImageCreator $root $Zig
    $sdk=Join-Path $root 'Platform/SDK'
    $zipSource=Join-Path $output 'zip-source'
    if(Test-Path -LiteralPath $zipSource){Remove-Item -LiteralPath $zipSource -Recurse -Force}
    [IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $root 'Legal/Sources/Protocols-R4Zip.zip'),$zipSource)
    $hostTool=Join-Path $output "package-host$suffix"
    if(!$GuestOnly){
        Checked $Zig @('build-exe','-OReleaseSafe','--dep','r4os','--dep','ntfs_volume','--dep','zip_core','--dep','installation',
            "-Mroot=$(Join-Path $root 'RecoveryTools/Menu/src/package_fixture.zig')",'--dep','r4os_contract',"-Mr4os=$(Join-Path $sdk 'r4os.zig')",
            '--dep','ntfs_format',"-Mntfs_volume=$(Join-Path $sdk 'r4os/ntfs_volume.zig')",'--dep','r4os',"-Mntfs_format=$(Join-Path $root 'RecoveryTools/Menu/src/ntfs_format.zig')",
            '--dep','r4os',"-Mzip_core=$(Join-Path $zipSource 'src/zip_core.zig')","-Minstallation=$(Join-Path $root 'Kernel/storage/installation.zig')","-Mr4os_contract=$(Join-Path $root 'Platform/Contract/Generated/SDK/Zig/package.zig')","-femit-bin=$hostTool")
    }
    $good=Join-Path $output 'recovery-good.zip';$bad=Join-Path $output 'recovery-bad-hash.zip'
    $systemPackage=Join-Path $output 'system/R4OS-0.76.15-slim-x86_64.zip'
    $inputs=[ordered]@{kernel=Get-RecoveryHash $kernel;productionKernel=Get-RecoveryHash (Join-Path $root 'Artifacts/Kernel/bin/recovery.elf');runtime=Get-RecoveryHash $runtime;creator=Get-RecoveryHash $imageCreator;
        package=Get-RecoveryHash (Join-Path $PSScriptRoot 'Package.ps1');release=Get-RecoveryHash (Join-Path $root 'Platform/Distribution/Tools/ReleasePackage.ps1');
        fixtures=Get-RecoveryHash (Join-Path $PSScriptRoot 'Storage-Fixtures.ps1');script=Get-RecoveryHash $PSCommandPath;
        legal=(Get-ChildItem -LiteralPath (Join-Path $root 'Legal') -File -Recurse | Sort-Object FullName -CaseSensitive | ForEach-Object {Get-RecoveryHash $_.FullName})}
    $serialized=$inputs|ConvertTo-Json -Depth 10 -Compress;$cache=Join-Path $output 'fixture-inputs.json'
    $cached=(Test-Path -LiteralPath $cache) -and ((Get-Content -Raw -LiteralPath $cache).Trim() -ceq $serialized) -and (Test-Path -LiteralPath $systemPackage) -and (Test-Path -LiteralPath (Join-Path $output 'disk-1.img'))
    if(!$cached){
        $null=New-RecoveryPackage -Root $root -Destination $good
        Copy-Item -LiteralPath $good -Destination $bad -Force
        $archive=[IO.Compression.ZipFile]::Open($bad,[IO.Compression.ZipArchiveMode]::Update)
        try {
            $entry=$archive.GetEntry('manifest.json');$reader=[IO.StreamReader]::new($entry.Open(),$utf8)
            try{$manifest=$reader.ReadToEnd()|ConvertFrom-Json -AsHashtable}finally{$reader.Dispose()}
            $entry.Delete();$manifest.files[0].sha256='0'*64
            $entry=$archive.CreateEntry('manifest.json',[IO.Compression.CompressionLevel]::Optimal)
            $writer=[IO.StreamWriter]::new($entry.Open(),$utf8)
            try{$writer.Write(($manifest|ConvertTo-Json -Depth 32)+"`n")}finally{$writer.Dispose()}
        }finally{$archive.Dispose()}
        $versionFile=Join-Path $output 'VERSION.R4S';[IO.File]::WriteAllText($versionFile,"RELEASE_VERSION=0.76.15`n",[Text.UTF8Encoding]::new($true))
        $payload=Join-Path $output 'file.bin';$bytes=[byte[]]::new(131073);for($i=0;$i -lt $bytes.Length;$i++){$bytes[$i]=[byte](($i*37+19)%256)};[IO.File]::WriteAllBytes($payload,$bytes)
        $sourceImage=New-Installation 9 $false '1024x768x32' @{SYSTEM=@("$versionFile|/R4OS/CONFIG/VERSION.R4S","$payload|/R4OS/SOURCE/LARGE.BIN","$payload|/ROOT.BIN")}
        $bootRoot=Join-Path $output 'managed-boot';[IO.Directory]::CreateDirectory((Join-Path $bootRoot 'boot'))|Out-Null
        # Technical ELF fixture only: this ZIP is never a published OS release.
        Copy-Item -LiteralPath $kernel -Destination (Join-Path $bootRoot 'boot/r4os.elf') -Force
        $legalRoot=Join-Path $output 'fixture-legal';[IO.Directory]::CreateDirectory($legalRoot)|Out-Null
        [IO.File]::WriteAllText((Join-Path $legalRoot 'README.txt'),'Technical fixture, not an installable R4OS release.',$utf8)
        . (Join-Path $root 'Platform/Distribution/Tools/ReleasePackage.ps1')
        $null=New-R4OSReleasePackage -Image $sourceImage -BootRoot $bootRoot -RecoveryPackage $good -LegalRoot $legalRoot -ReleaseVersion '0.76.15' `
            -KernelVersion ((Get-RecoveryFields (Join-Path $root 'Kernel/VERSION.R4S')).KERNEL_VERSION[0]) -Profile slim -OutputRoot (Join-Path $output 'system')
        $null=New-Installation 1 $false '1024x768x32' @{RECOVERY=@("$systemPackage|/INSTALL/RELEASE.ZIP","$good|/INSTALL/RECOVERY.ZIP","$bad|/INSTALL/BAD.ZIP")}
        [IO.File]::WriteAllText($cache,$serialized,$utf8)
    }
    if(!$GuestOnly){
        $target=Join-Path $output 'target-32mb.img'
        Checked $hostTool @($good,$systemPackage,$target)
        if($IsLinux -and (Get-Command ntfsfix -ErrorAction SilentlyContinue)){Checked 'ntfsfix' @('-n',$target)}
    }
    if($HostOnly){exit 0}
    $sources=Join-Path $root 'Artifacts/HostSources/Distribution'
    if(!(Test-Path -LiteralPath $sources)){[IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $root 'Legal/Sources/Distribution.zip'),$sources)}
    . (Join-Path $sources 'Tools/Qemu-HostProfile.ps1')
    $profile=Resolve-R4QemuHostProfile $Qemu
    $ssh=(Get-Command "ssh$suffix" -CommandType Application|Select-Object -First 1).Source
    $sshOptions=@('-c','chacha20-poly1305@openssh.com','-o','StrictHostKeyChecking=no','-o',('UserKnownHostsFile='+$(if($IsWindows){'NUL'}else{'/dev/null'})),'-o','LogLevel=ERROR','-o','ConnectTimeout=5')
    $askpass=Join-Path $output "askpass$suffix";Checked $Zig @('cc','-O2',(Join-Path $PSScriptRoot 'Guest-Askpass.c'),'-o',$askpass)
    $runs=@()
    foreach($ram in @(8192,1024)){
        $name="Bios-$ram";$serialLog=Join-Path $output "$name-serial.log";$clientLog=Join-Path $output "$name-clients.log"
        [IO.File]::WriteAllText($clientLog,'',$utf8)
        if(Test-Path -LiteralPath $serialLog){Remove-Item -LiteralPath $serialLog -Force}
        $scratch=Join-Path $output "$name-untouched.img";$file=[IO.File]::Create($scratch);try{$file.SetLength(2048MB)}finally{$file.Dispose()}
        $before=Get-RecoveryHash $scratch;$sshPort=Free-Port;$qmpPort=Free-Port
        $arguments=@('-machine',"q35,accel=$($profile.AcceleratorChain),i8042=off",'-cpu',$profile.CpuModel,'-m',"$ram",'-smp','4','-display','none','-monitor','none','-no-reboot',
            '-serial',"file:$serialLog",'-qmp',"tcp:127.0.0.1:$qmpPort,server=on,wait=off",'-device','qemu-xhci,id=package-xhci','-device','usb-kbd',
            '-drive',"if=none,id=boot-media,format=raw,file=$(Join-Path $output 'disk-1.img'),snapshot=on",'-device','usb-storage,id=package-media,drive=boot-media,bootindex=1',
            '-drive',"if=none,id=untouched,format=raw,file=$scratch",'-device','nvme,drive=untouched,serial=PACKAGE-UNTOUCHED',
            '-netdev',"user,id=net0,hostfwd=tcp:127.0.0.1:${sshPort}-:22",'-device','virtio-net-pci,netdev=net0')
        $start=[Diagnostics.ProcessStartInfo]::new($Qemu);$start.UseShellExecute=$false;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
        foreach($argument in $arguments){$start.ArgumentList.Add($argument)}
        $process=[Diagnostics.Process]::new();$process.StartInfo=$start;$watch=[Diagnostics.Stopwatch]::StartNew();$session=$null;$started=$false
        try{
            Write-Host "Recovery packages $name, SMP4."
            if(!$process.Start()){throw 'QEMU did not start.'};$started=$true;$stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
            Wait-Marker '\[RECOVERYUI\] progress=READY'
            $session=Open-Qmp $qmpPort
            Send-Keys $session @('ret')
            Wait-Marker '\[RECOVERYUI\] ready=1';Wait-Marker 'DHCP05913 state=bound';Wait-Marker '\[RECOVERYNET\] autostart=RETURNED'
            $evidence=@()
            if($ram -eq 8192){
                $evidence+=Package-Command 'RECOVERY'
                Send-Keys $session @('down','down','ret')
                Wait-Marker ("\[RECOVERYPACKAGE\] cache=manifest version="+[regex]::Escape($releaseVersion)+' source=READY')
                Send-Keys $session @('ret');Wait-Marker '\[RECOVERYUI\] page=targets selected=2 choice=0'
                Send-Keys $session @('ret');Wait-Marker '\[RECOVERYUI\] page=review selected=2 choice=0'
                Send-Keys $session @('down','ret');Wait-Marker ("\[RECOVERYPACKAGE\] prepared=recovery version="+[regex]::Escape($releaseVersion)+' .*writes=0')
                Wait-Marker '\[RECOVERYUI\] page=dialog selected=2'
                Send-Keys $session @('esc','esc','esc','esc','up','up')
                $null=Ssh 'DEL R:\INSTALL\RECOVERY.ZIP'
                $null=Ssh 'REN R:\INSTALL\BAD.ZIP R:\INSTALL\RECOVERY.ZIP'
                $evidence+=Package-Command 'REJECT'
                $evidence+=Package-Detach
            }else{$evidence+=Package-Command 'OOM'}
            Send-Keys $session @('up','ret')
            while(!$process.WaitForExit(100)){if($watch.Elapsed.TotalSeconds -gt $TimeoutSeconds){throw 'Package guest timed out.'}}
            if($process.ExitCode -ne 0){throw 'Guest restart failed.'}
        }finally{
            if($null -ne $session){$session.Writer.Dispose();$session.Reader.Dispose();$session.Client.Dispose()}
            if($started){if(!$process.HasExited){$process.Kill($true);$process.WaitForExit()};[IO.File]::WriteAllText((Join-Path $output "$name-qemu.log"),$stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult(),$utf8)}
            $process.Dispose()
        }
        if((Get-RecoveryHash $scratch) -cne $before){throw 'Package preparation changed the target disk.'}
        $serial=Get-Content -Raw -LiteralPath $serialLog
        if($serial -notmatch '\[SMP\] stage=active discovered=4 started=3 online=4 failed=0' -or $serial -notmatch '\[RESET\]' -or $serial -match '\[CRASH\]'){throw 'Incomplete SMP4 package run.'}
        $runs+=[ordered]@{firmware='Bios';ramMB=$ram;cpus=4;seconds=[Math]::Round($watch.Elapsed.TotalSeconds,3);result='ok';kernelSha256=$inputs.kernel;runtimeSha256=$inputs.runtime;targetBefore=$before;targetAfter=Get-RecoveryHash $scratch;evidence=$evidence}
        Write-RecoveryJson (Join-Path $output 'package-results.json') @{schema=1;runs=$runs}
        Write-Host "Recovery packages $name OK."
    }
    exit 0
}catch{Write-Error "$($_.Exception.Message)`n$($_.ScriptStackTrace)" -ErrorAction Continue;exit 1}
