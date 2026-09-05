param([ValidateRange(30,300)][int]$TimeoutSeconds=240)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'Inventory.ps1')
. (Join-Path $PSScriptRoot 'Guest-NetClients.ps1')
. (Join-Path $PSScriptRoot 'Guest-Qmp.ps1')
. (Join-Path $PSScriptRoot 'Storage-Access.Tests.ps1')
. (Join-Path $PSScriptRoot 'R4Part.Tests.ps1')
$root=Split-Path $PSScriptRoot -Parent
$workspace=[IO.Path]::GetFullPath((Join-Path $root '../..'))
$suffix=if($IsWindows){'.exe'}else{''}
$output=Join-Path $root 'Artifacts/BootProbe/r4part-normal'
[IO.Directory]::CreateDirectory($output)|Out-Null
$utf8=[Text.UTF8Encoding]::new($false)
$qemu=Join-Path $workspace "DevKit/Emulation/QEMU/qemu-system-x86_64$suffix"
$zig=Join-Path $workspace "DevKit/Toolchains/Zig/zig$suffix"
$normal=Join-Path $workspace 'Artifacts/Distribution/Profiles/Full'
$distribution=Join-Path $workspace 'Repositories/Distribution'
. (Join-Path $distribution 'Tools/Qemu-HostProfile.ps1')
$profile=Resolve-R4QemuHostProfile $qemu
$ssh=(Get-Command "ssh$suffix" -CommandType Application|Select-Object -First 1).Source
$sftp=(Get-Command "sftp$suffix" -CommandType Application|Select-Object -First 1).Source
$sshOptions=@('-c','chacha20-poly1305@openssh.com','-o','StrictHostKeyChecking=no','-o',('UserKnownHostsFile='+$(if($IsWindows){'NUL'}else{'/dev/null'})),'-o','LogLevel=ERROR','-o','ConnectTimeout=5','-o','ConnectionAttempts=1')
$askpass=Join-Path $output "askpass$suffix"
& $zig cc -O2 (Join-Path $PSScriptRoot 'Guest-Askpass.c') -o $askpass
if($LASTEXITCODE -ne 0){throw 'Askpass build failed.'}
function Free-Port {$l=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0);$l.Start();$p=$l.LocalEndpoint.Port;$l.Stop();return $p}
$sshPort=Free-Port;$qmpPort=Free-Port
$clientLog=Join-Path $output 'clients.log';$serialLog=Join-Path $output 'serial.log'
[IO.File]::WriteAllText($clientLog,'',$utf8);[IO.File]::WriteAllText($serialLog,'',$utf8)
$replacement=Join-Path $output 'witness.bin';$received=Join-Path $output 'received.bin';$payload=Join-Path $output 'payload.bin'
$bytes=[byte[]]::new(131073);for($i=0;$i -lt $bytes.Length;$i++){$bytes[$i]=[byte](($i*37+19)%256)}
[IO.File]::WriteAllBytes($payload,$bytes);[IO.File]::WriteAllBytes($replacement,$bytes[0..4096])
$scratch=Join-Path $output 'scratch.img';$f=[IO.File]::Create($scratch);try{$f.SetLength(128MB)}finally{$f.Dispose()}
$arguments=@('-readconfig',(Join-Path $distribution 'QEMU/standard.conf'),'-machine',"accel=$($profile.AcceleratorChain)",'-cpu',$profile.CpuModel,'-m','1024','-smp','4','-snapshot','-display','none','-monitor','none',
    '-audiodev','driver=none,id=debug-audio','-global','hda-duplex.audiodev=debug-audio','-serial',"file:$serialLog",'-qmp',"tcp:127.0.0.1:$qmpPort,server=on,wait=off",
    '-netdev',"user,id=rec-net,hostfwd=tcp:127.0.0.1:$sshPort-:22",'-device','virtio-net-pci,netdev=rec-net,disable-legacy=on',
    '-drive',"if=none,id=r4part-test,format=raw,file=$scratch",'-device','nvme,drive=r4part-test,serial=R4PART-07610')
$start=[Diagnostics.ProcessStartInfo]::new($qemu);$start.UseShellExecute=$false;$start.WorkingDirectory=$normal;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
foreach($argument in $arguments){$start.ArgumentList.Add($argument)}
$process=[Diagnostics.Process]::new();$process.StartInfo=$start;$watch=[Diagnostics.Stopwatch]::StartNew();$session=$null;$started=$false
function Wait-Marker([string]$Pattern,[int]$From=0){
    while($true){
        $text=[IO.File]::ReadAllText($serialLog)
        if($text -match '\[CRASH\]|panic-ret='){throw 'Normal guest crashed.'}
        if($text.Substring([Math]::Min($From,$text.Length)) -match $Pattern){return}
        if($process.HasExited -or $watch.Elapsed.TotalSeconds -gt $TimeoutSeconds){throw "Missing normal guest marker: $Pattern"}
        Start-Sleep -Milliseconds 50
    }
}
try{
    if(!$process.Start()){throw 'Normal QEMU did not start.'};$started=$true
    $stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
    Wait-Marker 'DHCP05913 state=bound';$session=Open-Qmp $qmpPort;Start-Sleep -Milliseconds 500
    $null=Ssh 'VER'
    $null=Sftp @("get /C/R4OS/SOFTWARE/TERMINAL/R4PART.R4X $(Host-Path $received)")
    Require-Hash $received (Join-Path $root 'Runtime/R4OS/SOFTWARE/TERMINAL/R4PART.R4X')
    Test-R4Part $false
    # Use a private QEMU snapshot to select the ordinary local Terminal shell.
    # Neither the published Full image nor its base CONFIG is modified.
    $config=Join-Path $output 'CONFIG.R4S'
    $text=[IO.File]::ReadAllText((Join-Path $distribution 'Injection/CONFIG.R4S')).Replace('SHELL=/R4OS/SOFTWARE/DESKTOP/R4DESK.R4X','SHELL=/R4OS/SOFTWARE/TERMINAL/TERMINAL.R4X')
    [IO.File]::WriteAllText($config,$text,[Text.UTF8Encoding]::new($true))
    $null=Sftp @("put $(Host-Path $config) /C/TEMP/PARTBOOT.R4S")
    $copy=Ssh 'COPY C:\TEMP\PARTBOOT.R4S C:\CONFIG.R4S'
    if($copy -notmatch '1 file\(s\) copied'){throw 'Snapshot Terminal configuration copy failed.'}
    $offset=[IO.File]::ReadAllText($serialLog).Length
    $null=Qmp $session 'system_reset';Wait-Marker 'C:\\>' $offset
    Part-Type 'R4PART';Wait-Marker 'R4PART - R4OS partition tool' $offset
    Part-Type 'LIST DISK';Wait-Marker 'Free MB' $offset
    Part-Type 'EXIT';Part-Type 'ECHO LOCALRETURNED';Wait-Marker 'LOCALRETURNED' $offset
    Part-Type 'POWEROFF'
    if(!$process.WaitForExit(10000) -or $process.ExitCode -ne 0){throw 'Normal guest did not power off.'}
    Write-RecoveryJson (Join-Path $output 'results.json') @{schema=1;result='ok';cpus=4;seconds=[Math]::Round($watch.Elapsed.TotalSeconds,3);
        r4partSha256=Get-RecoveryHash (Join-Path $root 'Runtime/R4OS/SOFTWARE/TERMINAL/R4PART.R4X');diskSha256=Get-RecoveryHash (Join-Path $normal 'disk.img');
        coverage='Same binary in normal Full image, actual storage operations through SSH, ordinary local Terminal input and EXIT after snapshot reboot';serial=$serialLog;clients=$clientLog}
    Write-Host 'Normal R4OS: identical R4PART binary, storage operations, local Terminal and EXIT OK.'
}finally{
    if($null -ne $session){$session.Writer.Dispose();$session.Reader.Dispose();$session.Client.Dispose()}
    if($started){if(!$process.HasExited){$process.Kill($true);$process.WaitForExit()};[IO.File]::WriteAllText((Join-Path $output 'qemu.log'),$stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult(),$utf8)}
    $process.Dispose()
}
