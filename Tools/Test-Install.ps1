param([Parameter(Mandatory)][string]$SourcePackage,[switch]$ReuseFixture,[switch]$VerifyInstalled,[string[]]$Cases=@(),
      [string]$Zig='', [string]$Qemu='', [ValidateRange(60,600)][int]$TimeoutSeconds=300)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$root=Split-Path $PSScriptRoot -Parent
$workspace=[IO.Path]::GetFullPath((Join-Path $root '../..'))
$distribution=Join-Path $workspace 'Repositories/Distribution'
. (Join-Path $PSScriptRoot 'Inventory.ps1')
. (Join-Path $PSScriptRoot 'Runtime.ps1')
. (Join-Path $PSScriptRoot 'Storage-Fixtures.ps1')
. (Join-Path $PSScriptRoot 'Guest-Qmp.ps1')
. (Join-Path $PSScriptRoot 'Guest-NetClients.ps1')
. (Join-Path $distribution 'Tools/Qemu-HostProfile.ps1')
. (Join-Path $distribution 'Tools/InstallationImage.Check.ps1')
$suffix=if($IsWindows){'.exe'}else{''}
if(!$Zig){$Zig=Join-Path $workspace "DevKit/Toolchains/Zig/zig$suffix"}
if(!$Qemu){$Qemu=Join-Path $workspace "DevKit/Emulation/QEMU/qemu-system-x86_64$suffix"}
$LimineRoot=Join-Path $workspace 'DevKit/Boot/Limine'
$limine=Join-Path $LimineRoot $(if($IsWindows){'limine-tool-windows-x86/limine.exe'}else{'limine'})
$output=Join-Path $root 'Artifacts/BootProbe/install';[IO.Directory]::CreateDirectory($output)|Out-Null
$kernel=Join-Path $root 'Artifacts/BootProbe/ui/bin/recovery.elf'
$runtime=Join-Path $root 'Artifacts/Runtime/runtime.img'
$utf8=[Text.UTF8Encoding]::new($false)
$profile=Resolve-R4QemuHostProfile $Qemu
function Checked([string]$Program,[string[]]$Arguments){& $Program @Arguments;if($LASTEXITCODE -ne 0){throw "Host tool failed: $Program"}}
function Free-Port {$l=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0);$l.Start();$p=$l.LocalEndpoint.Port;$l.Stop();return $p}
function Keys([string]$Text){foreach($c in $Text.ToLowerInvariant().ToCharArray()){$key=switch($c){'\'{'backslash'};':'{'shift+semicolon'};'/'{'slash'};'.'{'dot'};' '{'spc'};default{"$c"}};Send-Keys $session @($key)}}
function Wait-Guest([string]$Pattern){
 $deadline=[DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
 while($true){
  [string]$text=if(Test-Path $serialLog){Get-Content -Raw -LiteralPath $serialLog}else{''}
  if($text -match '\[CRASH\]|panic-ret=|result=FAILED'){throw "Guest failure: $serialLog"}
  if($text -match $Pattern){return $text}
  if($process.HasExited -or [DateTime]::UtcNow -ge $deadline){throw "Missing marker $Pattern ($serialLog)"}
  Start-Sleep -Milliseconds 100
 }
}
function Stop-Guest {
 if($null -ne $session){$session.Writer.Dispose();$session.Reader.Dispose();$session.Client.Dispose();$script:session=$null}
 if($null -ne $process){
  if(!$process.HasExited){$process.Kill($true)};$process.WaitForExit()
  [IO.File]::WriteAllText((Join-Path $output "$name-qemu.log"),$stderr.GetAwaiter().GetResult(),$utf8)
  $null=$stdout.GetAwaiter().GetResult();$process.Dispose();$script:process=$null
 }
}
function Start-Guest([string[]]$Arguments){
 $script:serialLog=Join-Path $output "$name-serial.log";$script:clientLog=Join-Path $output "$name-clients.log"
 if(Test-Path $serialLog){Remove-Item $serialLog -Force};[IO.File]::WriteAllText($clientLog,'',$utf8)
 $script:qmpPort=Free-Port;$script:sshPort=Free-Port
 $base=@('-machine',"q35,accel=$($profile.AcceleratorChain)",'-cpu',$profile.CpuModel,'-smp','4','-display','none','-monitor','none','-no-reboot','-serial',"file:$serialLog",'-qmp',"tcp:127.0.0.1:$qmpPort,server=on,wait=off",'-device','qemu-xhci,id=xhci','-device','usb-kbd')
 $base+=@(Get-RecoveryFirmwareArgs)
 $base+=@('-netdev',"user,id=net,hostfwd=tcp:127.0.0.1:$sshPort-:22",'-device','virtio-net-pci,netdev=net')
 $start=[Diagnostics.ProcessStartInfo]::new($Qemu);$start.UseShellExecute=$false;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
 foreach($arg in ($base+$Arguments)){$start.ArgumentList.Add($arg)}
 $script:process=[Diagnostics.Process]::Start($start);$script:stdout=$process.StandardOutput.ReadToEndAsync();$script:stderr=$process.StandardError.ReadToEndAsync()
 $script:session=$null
}
function Blank([string]$Path,[long]$Bytes){$f=[IO.File]::Create($Path);try{$f.SetLength($Bytes)}finally{$f.Dispose()}}
function Set-FixtureBootLabel([string]$Path){
 # Regress the real FAT lookup: the volume label BOOT must not shadow /boot.
 $f=[IO.File]::Open($Path,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite)
 try{
  [long]$base=4096*512;$b=[byte[]]::new(512);$f.Position=$base;$f.ReadExactly($b)
  $cluster=[BitConverter]::ToUInt32($b,44);$reserved=[BitConverter]::ToUInt16($b,14);$fat=[BitConverter]::ToUInt32($b,36)
  $offset=$base+($reserved+$b[16]*$fat+($cluster-2)*$b[13])*512
  $f.Position=$offset;$entry=[byte[]]::new(32);$f.ReadExactly($entry)
  if($entry[11] -ne 8){throw 'Fixture root label entry missing.'}
  $label=[Text.Encoding]::ASCII.GetBytes('BOOT       ')
  foreach($position in @(($base+71),($base+6*512+71),$offset)){Write-At $f $position $label}
  $f.Flush($true)
 }finally{$f.Dispose()}
}
function Firmware-Args([string]$Mode){
 if($Mode -ne 'Uefi'){return @()}
 $code=if($IsLinux){'/usr/share/OVMF/OVMF_CODE_4M.fd'}else{Join-Path $workspace 'DevKit/Emulation/QEMU/share/edk2-x86_64-code.fd'}
 $vars=if($IsLinux){'/usr/share/OVMF/OVMF_VARS_4M.fd'}else{Join-Path $workspace 'DevKit/Emulation/QEMU/share/edk2-i386-vars.fd'}
 $copy=Join-Path $output "$name-vars.fd";Copy-Item -LiteralPath $vars -Destination $copy -Force
 return @('-drive',"if=pflash,format=raw,unit=0,readonly=on,file=$code",'-drive',"if=pflash,format=raw,unit=1,file=$copy")
}
try {
 Test-RecoveryInventory $root|Out-Null
 $imageCreator=Get-RecoveryImageCreator $root $Zig
 $packageHash=Get-RecoveryHash $SourcePackage
 $inputs=@{firmwarePolicy=Get-RecoveryHash (Join-Path $PSScriptRoot 'Guest-Qmp.ps1');package=$packageHash;kernel=Get-RecoveryHash $kernel;runtime=Get-RecoveryHash $runtime;creator=Get-RecoveryHash $imageCreator;fixtures=Get-RecoveryHash (Join-Path $PSScriptRoot 'Storage-Fixtures.ps1');runner=Get-RecoveryHash $PSCommandPath}
 $seed=Join-Path $output 'disk-18.img';$stamp=Join-Path $output 'install-fixture.json'
 if($ReuseFixture){
  $saved=Get-Content -Raw -LiteralPath $stamp|ConvertFrom-Json -AsHashtable
  foreach($key in $inputs.Keys){if($saved.inputs[$key] -cne $inputs[$key]){throw "Stale installation fixture: $key"}}
  if((Get-RecoveryHash $seed) -cne $saved.sha256){throw 'Changed seed image.'}
 } else {
  $null=New-Installation 18 $false '1280x720x32' @{RECOVERY=@("$SourcePackage|/INSTALL/RELEASE.ZIP")}
  Set-FixtureBootLabel $seed
  Write-RecoveryJson $stamp @{inputs=$inputs;sha256=Get-RecoveryHash $seed}
 }
 $zip=[IO.Compression.ZipFile]::OpenRead($SourcePackage)
 try{$reader=[IO.StreamReader]::new($zip.GetEntry('manifest.json').Open());try{$source=$reader.ReadToEnd()|ConvertFrom-Json -AsHashtable}finally{$reader.Dispose()}}finally{$zip.Dispose()}
 $askpass=Join-Path $output "askpass$suffix";Checked $Zig @('cc','-O2',(Join-Path $PSScriptRoot 'Guest-Askpass.c'),'-o',$askpass)
 $ssh=(Get-Command "ssh$suffix" -CommandType Application|Select-Object -First 1).Source
 $sshOptions=@('-c','chacha20-poly1305@openssh.com','-o','StrictHostKeyChecking=no','-o',('UserKnownHostsFile='+$(if($IsWindows){'NUL'}else{'/dev/null'})),'-o','LogLevel=ERROR','-o','ConnectTimeout=5')
 $script:process=$null;$script:session=$null;$runs=@();$installed=@()
 $matrix=@(@{name='UsbInstall';own=$false;ram=8192;fault=$false},@{name='LocalReinstall';own=$true;ram=8192;fault=$false},@{name='WriteFailure';own=$false;ram=8192;fault=$true},@{name='RamFailure';own=$false;ram=1024;fault=$false},@{name='RamMinimum';own=$false;ram=6144;fault=$false})
 if($Cases.Count){$matrix=@($matrix|Where-Object {$_.name -in $Cases});if($matrix.Count -ne $Cases.Count){throw 'Unknown installation case.'}}
 if($VerifyInstalled){
  $saved=Get-Content -Raw -LiteralPath (Join-Path $output 'install-results.json')|ConvertFrom-Json -AsHashtable
  foreach($key in $inputs.Keys){if($saved.inputs[$key] -cne $inputs[$key]){throw "Stale installation result: $key"}}
  $installed=@($saved.installed|Where-Object {!$Cases.Count -or $_.name -in $Cases})
  if(!$installed.Count){throw 'No installed results to verify.'}
  foreach($result in $installed){$result.structure=Test-R4OSInstallationImage -Image $result.image}
  $runs=@($saved.runs);$matrix=@()
 }
 foreach($case in $matrix) {
  $name=$case.name;$watch=[Diagnostics.Stopwatch]::StartNew()
  $boot=Join-Path $output "$name-boot.img";Copy-Item -LiteralPath $seed -Destination $boot -Force
  $target=if($case.own){$boot}else{Join-Path $output "$name-target.img"}
  if(!$case.own){Blank $target 3GB}
  $other=Join-Path $output "$name-other.img";Blank $other 64MB
  $witness=[Text.Encoding]::ASCII.GetBytes("UNTOUCHED-$name");$file=[IO.File]::OpenWrite($other);try{$file.Write($witness);$file.Position=$file.Length-$witness.Length;$file.Write($witness)}finally{$file.Dispose()}
  $otherHash=Get-RecoveryHash $other;$targetHash=Get-RecoveryHash $target;$bootHash=Get-RecoveryHash $boot
  $arguments=@('-m',"$($case.ram)",'-drive',"if=none,id=other,format=raw,file=$other",'-device','nvme,drive=other,serial=OTHER-INSTALL')
  if($case.fault){
   $node=@{driver='blkdebug';'node-name'='target';image=@{driver='file';filename=$target};'inject-error'=@(@{event='none';iotype='write';errno=5;sector=4096;once=$false;immediately=$true})}|ConvertTo-Json -Depth 8 -Compress
   $arguments+=@('-blockdev',$node)
  }else{$arguments+=@('-drive',"if=none,id=target,format=raw,file=$target")}
  $arguments+=@('-device',('nvme,drive=target,serial=TARGET-INSTALL'+$(if($case.own){',bootindex=1'}else{''})))
  if(!$case.own){$arguments+=@('-drive',"if=none,id=boot,format=raw,file=$boot",'-device','usb-storage,drive=boot,bootindex=1')}
  $firmware=if($case.own){'Uefi'}else{'Bios'}
  Write-Host "Recovery installation ${name}: SMP4, $($case.ram) MB RAM, $firmware."
  try {
   Start-Guest ($arguments+(Firmware-Args $firmware))
   $null=Wait-Guest '\[RECOVERYSTORAGE\] source=ok'
   $null=Wait-Guest '\[RECOVERYUI\] progress=READY';$script:session=Open-Qmp $qmpPort;Send-Keys $session @('ret')
   $null=Wait-Guest '\[RECOVERYUI\] ready=1';$null=Wait-Guest '\[RECOVERYNET\] autostart=RETURNED';$null=Wait-Guest 'DHCP05913 state=bound'
   Send-Keys $session @('ret');$null=Wait-Guest '\[RECOVERYPACKAGE\] cache=manifest .*source=READY'
   Send-Keys $session @('ret');$null=Wait-Guest '\[RECOVERYUI\] page=targets selected=0 choice=0'
   Send-Keys $session @('ret');$null=Wait-Guest '\[RECOVERYUI\] page=review selected=0 choice=0'
   Send-Keys $session @('down','ret')
   if($case.ram -eq 1024){$text=Wait-Guest '\[RECOVERYPACKAGE\] rejected=OutOfMemory .*writes=0'}
   elseif($case.ram -eq 6144){$text=Wait-Guest '\[RECOVERYPACKAGE\] rejected=InsufficientRam .*writes=0'}
   elseif($case.fault){$text=Wait-Guest '\[RECOVERYINSTALL\] result=WriteFailed attempted=1 .*claim=0'}
   else{$text=Wait-Guest '\[RECOVERYINSTALL\] result=OK'}
   $null=Wait-Guest '\[RECOVERYUI\] page=dialog selected=0'
   if((Ssh 'ECHO RECOVERY-RAM-STILL-RUNNING') -notmatch 'RECOVERY-RAM-STILL-RUNNING'){throw 'Recovery SSH stopped after operation.'}
   if($case.own){
    $current=(Ssh 'TYPE R:\CURRENT\manifest.json')|ConvertFrom-Json -AsHashtable
    if($current.recoveryVersion -cne $source.recovery.version){throw 'Own-device R: was not rebound to the installed Recovery.'}
   }
   Send-Keys $session @('esc')
   if($case.ram -lt 8192){Send-Keys $session @('esc','esc','esc')}
   Send-Keys $session @('up','up','ret');Start-Sleep -Milliseconds 500;Keys 'POWEROFF';Send-Keys $session @('ret')
   if(!$process.WaitForExit(20000) -or $process.ExitCode -ne 0){throw 'RAM Recovery could not shut down normally.'}
  } finally {Stop-Guest}
  if((Get-RecoveryHash $other) -cne $otherHash){throw 'The other physical target changed.'}
  if(!$case.own -and (Get-RecoveryHash $boot) -cne $bootHash){throw 'The USB source changed.'}
  if($case.ram -lt 8192 -and (Get-RecoveryHash $target) -cne $targetHash){throw 'Low-RAM rejection changed the target.'}
  if(!$case.fault -and $case.ram -ge 8192){
   $structure=Test-R4OSInstallationImage -Image $target
   if($structure.installation.releaseVersion -cne $source.releaseVersion -or $structure.installation.kernelVersion -cne $source.kernelVersion -or $structure.recoveryVersion -cne $source.recovery.version){throw 'Installed package versions differ.'}
   $check=[InstallationImageCheck]::new($target)
   try{if([InstallationImageCheck]::Hash($check.Volumes['RECOVERY'].ReadFile('INSTALL/RELEASE.ZIP')) -cne $packageHash){throw 'Installed original ZIP differs.'}}finally{$check.Dispose()}
   $installed+=@(@{name=$name;image=$target;structure=$structure})
  }
  $runs+=@(@{case=$name;cpus=4;firmware=$firmware;seconds=[Math]::Round($watch.Elapsed.TotalSeconds,3);result='PASS';target=$target;otherUnchanged=$true})
  Write-RecoveryJson (Join-Path $output 'install-results.json') @{schema=1;inputs=$inputs;runs=$runs;installed=$installed}
  Write-Host "PASS $name ($([Math]::Round($watch.Elapsed.TotalSeconds,2)) s)"
 }
 foreach($result in $installed){
  foreach($entry in @('Normal','Recovery')){
   $mode=if(($result.name -eq 'UsbInstall') -eq ($entry -eq 'Normal')){'Bios'}else{'Uefi'}
   $name="$($result.name)-$mode-$entry";$watch=[Diagnostics.Stopwatch]::StartNew()
   $before=Get-RecoveryHash $result.image
   try {
    Start-Guest (@('-m','8192','-drive',"if=none,id=result,format=raw,file=$($result.image),snapshot=on",'-device','nvme,drive=result,serial=INSTALLED,bootindex=1')+(Firmware-Args $mode))
    Start-Sleep -Milliseconds 2000;$script:session=Open-Qmp $qmpPort
    if($entry -eq 'Recovery'){
     Send-Keys $session @('down','ret');$text=Wait-Guest '\[RECOVERY\] shell=READY'
     if(!$text.Contains('disk='+$result.structure.installation.diskGuid+' partition='+$result.structure.installation.partitions.RECOVERY.partitionGuid)){throw 'Installed Recovery boot identity differs.'}
     Send-Keys $session @('up','up','ret');Start-Sleep -Milliseconds 500
    }else{
     $text=Wait-Guest '\[INSTALLBOOT\] mapping=verified C=SYSTEM D=DATA BOOT=unlettered'
     if(!$text.Contains('installation='+$result.structure.installation.installationId)){throw 'Installed normal boot identity differs.'}
     Start-Sleep -Milliseconds 10000;Send-Keys $session @('d');Start-Sleep -Milliseconds 1500
    }
    Keys 'POWEROFF';Send-Keys $session @('ret')
    if(!$process.WaitForExit(20000) -or $process.ExitCode -ne 0){throw 'Installed system did not shut down through its Terminal.'}
   }finally{Stop-Guest}
   if((Get-RecoveryHash $result.image) -cne $before){throw 'Boot acceptance changed the installed base image.'}
   $runs+=@(@{case=$name;cpus=4;seconds=[Math]::Round($watch.Elapsed.TotalSeconds,3);result='PASS'})
   Write-RecoveryJson (Join-Path $output 'install-results.json') @{schema=1;inputs=$inputs;runs=$runs;installed=$installed}
   Write-Host "PASS $name"
  }
 }
 Write-Host "Recovery installation acceptance: $($runs.Count) cases PASS."
 exit 0
}catch{Write-Error $_ -ErrorAction Continue;exit 1}
