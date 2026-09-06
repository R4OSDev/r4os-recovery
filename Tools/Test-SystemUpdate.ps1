param([Parameter(Mandatory)][string]$SourcePackage,[Parameter(Mandatory)][string]$BaseImage,
      [switch]$ReuseFixture,[string[]]$Cases=@(),[string]$Zig='', [string]$Qemu='',
      [ValidateRange(60,600)][int]$TimeoutSeconds=300,
      [ValidateRange(512,32768)][int]$RamMB=8192)
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
$output=Join-Path $root 'Artifacts/BootProbe/system-update';[IO.Directory]::CreateDirectory($output)|Out-Null
$kernel=Join-Path $root 'Artifacts/BootProbe/ui/bin/recovery.elf'
$runtime=Join-Path $root 'Artifacts/Runtime/runtime.img'
$utf8=[Text.UTF8Encoding]::new($false)
$profile=Resolve-R4QemuHostProfile $Qemu
function Checked([string]$Program,[string[]]$Arguments){& $Program @Arguments|Out-Host;if($LASTEXITCODE -ne 0){throw "Host tool failed: $Program"}}
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
function Hash-Range([string]$Path,[long]$First,[long]$Count){
 $f=[IO.File]::OpenRead($Path);$hash=[Security.Cryptography.IncrementalHash]::CreateHash([Security.Cryptography.HashAlgorithmName]::SHA256)
 try{$f.Position=$First*512;$bytes=[byte[]]::new(1MB);[long]$left=$Count*512
  while($left -gt 0){$amount=[int][Math]::Min($left,$bytes.Length);$f.ReadExactly($bytes,0,$amount);$hash.AppendData($bytes,0,$amount);$left-=$amount}
  return [Convert]::ToHexString($hash.GetHashAndReset()).ToLowerInvariant()
 }finally{$hash.Dispose();$f.Dispose()}
}
function Witness([string]$Path){
 $check=[InstallationImageCheck]::new($Path,$true)
 try{
  $result=[ordered]@{prefix=Hash-Range $Path 0 4096;gptBackup=Hash-Range $Path ($check.Bytes/512-33) 33;files=[ordered]@{};parts=[ordered]@{}}
  foreach($role in @('SYSTEM','BOOT','RECOVERY','DATA')){
   $p=$check.Partitions[$role];$result.parts[$role]=@{first=$p.First;count=$p.Count;guid=$p.Guid;type=$p.Type}
   if($role -in @('RECOVERY','DATA')){$result[$role]=Hash-Range $Path $p.First $p.Count}
  }
  foreach($file in @('boot/limine.conf','boot/KEEP-FOREIGN.bin','EFI/OTHER/start.efi')){$result.files[$file]=[InstallationImageCheck]::Hash($check.Volumes['BOOT'].ReadFile($file))}
  return $result
 }finally{$check.Dispose()}
}
function New-Target([int]$Size){
 $dir=Join-Path $output "fixture-$Size";[IO.Directory]::CreateDirectory($dir)|Out-Null
 $target=Join-Path $output "fixture-$Size.img";Copy-Item -LiteralPath $BaseImage -Destination $target -Force
 $check=[InstallationImageCheck]::new($BaseImage)
 try{
  if($check.Bytes -ne 2048MB){throw 'The update fixture requires a standard 2048 MB source image.'}
  $bootRoot=Join-Path $dir 'boot';$files=@()
  foreach($path in $check.Volumes['BOOT'].Paths()){
   $path=$path.ToLowerInvariant()
   $destination=Join-Path $bootRoot $path;[IO.Directory]::CreateDirectory((Split-Path $destination -Parent))|Out-Null
   [IO.File]::WriteAllBytes($destination,$check.Volumes['BOOT'].ReadFile($path));$files+=@("$destination|/$path")
  }
  $manifestPath=Join-Path $bootRoot 'boot/r4os-installation.json'
  $manifest=Get-Content -Raw -LiteralPath $manifestPath|ConvertFrom-Json -AsHashtable
  $manifest.partitions.SYSTEM.sectorCount=[long]$Size*2048
  [IO.File]::WriteAllText($manifestPath,($manifest|ConvertTo-Json -Depth 16),$utf8)
  $config=Join-Path $bootRoot 'boot/limine.conf'
  $custom="# Preserve my settings and line endings`r`n"+(Get-Content -Raw -LiteralPath $config)+"`n/Other boot program`n    protocol: efi`n    path: boot():/EFI/OTHER/start.efi`n"
  [IO.File]::WriteAllText($config,$custom,$utf8)
  foreach($path in @('boot/KEEP-FOREIGN.bin','EFI/OTHER/start.efi')){
   $path=$path.ToLowerInvariant()
   $destination=Join-Path $bootRoot $path;[IO.Directory]::CreateDirectory((Split-Path $destination -Parent))|Out-Null
   [IO.File]::WriteAllText($destination,"FOREIGN-PRESERVED-$path",$utf8);$files+=@("$destination|/$path")
  }
  $bootList=Join-Path $dir 'boot.list';[IO.File]::WriteAllText($bootList,($files -join "`n")+"`n",$utf8)
  $bootImage=Join-Path $dir 'BOOT.img';Checked $imageCreator @('--output',$bootImage,'--size','128','--volume-only','--add-list',$bootList)
  $old=Join-Path $dir 'old.txt';[IO.File]::WriteAllText($old,'Old settings must disappear.',$utf8)
  $oldVersion=Join-Path $dir 'VERSION.R4S';[IO.File]::WriteAllText($oldVersion,"RELEASE_VERSION=$($manifest.releaseVersion)`n",[Text.UTF8Encoding]::new($true))
  $systemList=Join-Path $dir 'system.list';[IO.File]::WriteAllText($systemList,"$old|/OLD-ONLY.TXT`n$oldVersion|/R4OS/CONFIG/VERSION.R4S`n",$utf8)
  $formatSize=[Math]::Max(32,$Size)
  $systemImage=Join-Path $dir 'SYSTEM.img';Checked $imageCreator @('format-ntfs','--output',$systemImage,'--meta',(Join-Path $root 'Platform/SDK/Tests/Fixture/Ntfs/Meta0605'),'--size',"$formatSize",'--label','SYSTEM','--serial','0019000000000001','--add-list',$systemList)
  foreach($pair in @(@{image=$bootImage;role='BOOT';backup=6*512},@{image=$systemImage;role='SYSTEM';backup=([long]$formatSize*1MB-512)})){
   $f=[IO.File]::Open($pair.image,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite);try{$b=[byte[]]::new(512);$f.ReadExactly($b);U32 $b 28 ([uint32]$manifest.partitions[$pair.role].firstLba);Write-At $f 0 $b;Write-At $f $pair.backup $b}finally{$f.Dispose()}
  }
  $disk=[IO.File]::Open($target,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite)
  try{
   $entries=[byte[]]::new(16384);$disk.Position=1024;$disk.ReadExactly($entries);U64 $entries (2*128+40) ($manifest.partitions.SYSTEM.firstLba+$Size*2048-1)
   Write-At $disk 1024 $entries;Write-At $disk (($disk.Length/512-33)*512) $entries
   Write-At $disk 512 (Header $entries $manifest.diskGuid 1 ($disk.Length/512-1) 2)
   Write-At $disk ($disk.Length-512) (Header $entries $manifest.diskGuid ($disk.Length/512-1) 1 ($disk.Length/512-33))
   Copy-Volume $disk ($manifest.partitions.BOOT.firstLba*512) $bootImage
   Copy-Volume $disk ($manifest.partitions.SYSTEM.firstLba*512) $systemImage
   $disk.Flush($true)
  }finally{$disk.Dispose()}
 }finally{$check.Dispose()}
 if($Size -eq 16){Checked $hostTool @('--shrink-fixture',$target)}
 $null=Test-R4OSInstallationImage -Image $target -AllowNonstandardSystem -PreservedMenu
 return $target
}
try {
 Test-RecoveryInventory $root|Out-Null
 $null=Test-R4OSInstallationImage -Image $BaseImage
 $imageCreator=Get-RecoveryImageCreator $root $Zig
 $zipSource=Join-Path $output 'host-zip-source'
 if(Test-Path $zipSource){Remove-Item -LiteralPath $zipSource -Recurse -Force}
 [IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $root 'Legal/Sources/Protocols-R4Zip.zip'),$zipSource)
 $sdk=Join-Path $root 'Platform/SDK';$hostTool=Join-Path $output "update-host$suffix"
 Checked $Zig @('build-exe','-OReleaseSafe','--dep','r4os','--dep','ntfs_volume','--dep','zip_core','--dep','installation',
  "-Mroot=$(Join-Path $root 'RecoveryTools/Menu/src/package_fixture.zig')",'--dep','r4os_contract',"-Mr4os=$(Join-Path $sdk 'r4os.zig')",'--dep','ntfs_format',"-Mntfs_volume=$(Join-Path $sdk 'r4os/ntfs_volume.zig')",
  '--dep','r4os',"-Mntfs_format=$(Join-Path $root 'RecoveryTools/Menu/src/ntfs_format.zig')",'--dep','r4os',"-Mzip_core=$(Join-Path $zipSource 'src/zip_core.zig')", "-Minstallation=$(Join-Path $root 'Kernel/storage/installation.zig')",
  "-Mr4os_contract=$(Join-Path $root 'Platform/Contract/Generated/SDK/Zig/package.zig')","-femit-bin=$hostTool")
 $inputs=@{firmwarePolicy=Get-RecoveryHash (Join-Path $PSScriptRoot 'Guest-Qmp.ps1');package=Get-RecoveryHash $SourcePackage;base=Get-RecoveryHash $BaseImage;kernel=Get-RecoveryHash $kernel;runtime=Get-RecoveryHash $runtime;creator=Get-RecoveryHash $imageCreator;fixtures=Get-RecoveryHash (Join-Path $PSScriptRoot 'Storage-Fixtures.ps1');runner=Get-RecoveryHash $PSCommandPath}
 $seed=Join-Path $output 'disk-19.img';$stamp=Join-Path $output 'update-fixture.json'
 if($ReuseFixture){
  $saved=Get-Content -Raw -LiteralPath $stamp|ConvertFrom-Json -AsHashtable
  foreach($key in $inputs.Keys){if($saved.inputs[$key] -cne $inputs[$key]){throw "Stale system-update fixture: $key"}}
  foreach($file in $saved.images){if((Get-RecoveryHash $file.path) -cne $file.sha256){throw 'Changed fixture image.'}}
 }else{
  $null=New-Installation 19 $false '1280x720x32' @{RECOVERY=@("$SourcePackage|/INSTALL/RELEASE.ZIP")}
  $large=New-Target 768;$small=New-Target 16
  Write-RecoveryJson $stamp @{inputs=$inputs;images=@(@{path=$seed;sha256=Get-RecoveryHash $seed},@{path=$large;sha256=Get-RecoveryHash $large},@{path=$small;sha256=Get-RecoveryHash $small})}
 }
 $zip=[IO.Compression.ZipFile]::OpenRead($SourcePackage)
 try{$reader=[IO.StreamReader]::new($zip.GetEntry('manifest.json').Open());try{$source=$reader.ReadToEnd()|ConvertFrom-Json -AsHashtable}finally{$reader.Dispose()}}finally{$zip.Dispose()}
 $askpass=Join-Path $output "askpass$suffix";Checked $Zig @('cc','-O2',(Join-Path $PSScriptRoot 'Guest-Askpass.c'),'-o',$askpass)
 $ssh=(Get-Command "ssh$suffix" -CommandType Application|Select-Object -First 1).Source
 $sshOptions=@('-c','chacha20-poly1305@openssh.com','-o','StrictHostKeyChecking=no','-o',('UserKnownHostsFile='+$(if($IsWindows){'NUL'}else{'/dev/null'})),'-o','LogLevel=ERROR','-o','ConnectTimeout=5')
 $script:process=$null;$script:session=$null;$runs=@();$updated=@()
 $matrix=@(@{name='System768';size=768},@{name='SystemTooSmall';size=16})
 if($Cases.Count){$matrix=@($matrix|Where-Object {$_.name -in $Cases});if($matrix.Count -ne $Cases.Count){throw 'Unknown system-update case.'}}
 foreach($case in $matrix){
  $name=$case.name;$watch=[Diagnostics.Stopwatch]::StartNew()
  $target=Join-Path $output "$name-target.img";Copy-Item -LiteralPath (Join-Path $output "fixture-$($case.size).img") -Destination $target -Force
  $boot=Join-Path $output "$name-boot.img";Copy-Item -LiteralPath $seed -Destination $boot -Force
  $before=Witness $target;$targetHash=Get-RecoveryHash $target;$bootHash=Get-RecoveryHash $boot
  Write-Host "Recovery system update ${name}: SMP4, $RamMB MB, BIOS USB boot."
  try{
   Start-Guest @('-m',"$RamMB",'-drive',"if=none,id=target,format=raw,file=$target",'-device','nvme,drive=target,serial=SYSTEM-UPDATE','-drive',"if=none,id=boot,format=raw,file=$boot",'-device','usb-storage,drive=boot,bootindex=1')
   $null=Wait-Guest '\[RECOVERYSTORAGE\] source=ok';$null=Wait-Guest '\[RECOVERYUI\] progress=READY';$script:session=Open-Qmp $qmpPort;Send-Keys $session @('ret')
   $null=Wait-Guest '\[RECOVERYUI\] ready=1';$null=Wait-Guest '\[RECOVERYNET\] autostart=RETURNED';$null=Wait-Guest 'DHCP05913 state=bound'
   Send-Keys $session @('down','ret');$null=Wait-Guest '\[RECOVERYPACKAGE\] cache=manifest .*source=READY'
   Send-Keys $session @('ret');$null=Wait-Guest '\[RECOVERYUI\] page=targets selected=1 choice=0'
   Send-Keys $session @('ret');$null=Wait-Guest '\[RECOVERYUI\] page=review selected=1 choice=0'
   Send-Keys $session @('down','ret')
   if($case.size -eq 16){$text=Wait-Guest '\[RECOVERYPACKAGE\] rejected=(NoSpace|VolumeTooSmall|Geometry) .*writes=0'}
   else{$text=Wait-Guest '\[RECOVERYSYSUPDATE\] result=OK'}
   $null=Wait-Guest '\[RECOVERYUI\] page=dialog selected=1'
   if((Ssh 'ECHO UPDATE-RECOVERY-STILL-RUNNING') -notmatch 'UPDATE-RECOVERY-STILL-RUNNING'){throw 'SSH stopped after system update.'}
   Send-Keys $session @('esc');if($case.size -eq 16){Send-Keys $session @('esc','esc','esc')}
   Send-Keys $session @('down','down','down','ret');Start-Sleep -Milliseconds 500;Keys 'POWEROFF';Send-Keys $session @('ret')
   if(!$process.WaitForExit(20000) -or $process.ExitCode -ne 0){throw 'Recovery could not shut down through Terminal.'}
  }finally{Stop-Guest}
  if((Get-RecoveryHash $boot) -cne $bootHash){throw 'USB source changed.'}
  $after=Witness $target
  if(($before|ConvertTo-Json -Depth 12 -Compress) -cne ($after|ConvertTo-Json -Depth 12 -Compress)){throw 'Persistent partition, GPT or foreign BOOT witness changed.'}
  if($case.size -eq 16){if((Get-RecoveryHash $target) -cne $targetHash){throw 'Too-small target changed.'}}
  else{
   $structure=Test-R4OSInstallationImage -Image $target -AllowNonstandardSystem -PreservedMenu
   if($structure.installation.releaseVersion -cne $source.releaseVersion -or $structure.installation.kernelVersion -cne $source.kernelVersion){throw 'Updated system versions differ.'}
   Checked $hostTool @('--updated-system',$SourcePackage,$target)
   $updated+=@(@{image=$target;structure=$structure})
  }
  $runs+=@(@{case=$name;cpus=4;ramMB=$RamMB;seconds=[Math]::Round($watch.Elapsed.TotalSeconds,3);result='PASS';target=$target;persistent=$after})
  Write-RecoveryJson (Join-Path $output 'update-results.json') @{schema=1;inputs=$inputs;runs=$runs;updated=$updated}
  Write-Host "PASS $name"
 }
 foreach($result in $updated){
  $name='UpdatedNormalBoot';$before=Get-RecoveryHash $result.image;$watch=[Diagnostics.Stopwatch]::StartNew()
  try{
   Start-Guest @('-m',"$RamMB",'-drive',"if=none,id=result,format=raw,file=$($result.image),snapshot=on",'-device','nvme,drive=result,serial=UPDATED,bootindex=1')
   $text=Wait-Guest '\[INSTALLBOOT\] mapping=verified C=SYSTEM D=DATA BOOT=unlettered'
   if(!$text.Contains('installation='+$result.structure.installation.installationId)){throw 'Updated normal boot identity differs.'}
   $script:session=Open-Qmp $qmpPort;Start-Sleep -Milliseconds 10000;Send-Keys $session @('d');Start-Sleep -Milliseconds 1500
   Keys 'POWEROFF';Send-Keys $session @('ret')
   if(!$process.WaitForExit(20000) -or $process.ExitCode -ne 0){throw 'Updated R4OS did not shut down through Terminal.'}
  }finally{Stop-Guest}
  if((Get-RecoveryHash $result.image) -cne $before){throw 'Normal boot changed the saved updated image.'}
  $runs+=@(@{case=$name;cpus=4;ramMB=$RamMB;seconds=[Math]::Round($watch.Elapsed.TotalSeconds,3);result='PASS'})
  Write-RecoveryJson (Join-Path $output 'update-results.json') @{schema=1;inputs=$inputs;runs=$runs;updated=$updated}
  Write-Host "PASS $name"
 }
 Write-Host "Recovery system-update acceptance: $($runs.Count) cases PASS."
 exit 0
}catch{Write-Error $_ -ErrorAction Continue;exit 1}
