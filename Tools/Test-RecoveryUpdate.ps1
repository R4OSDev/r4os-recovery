param([Parameter(Mandatory)][string]$SourcePackage,[Parameter(Mandatory)][string]$PreviousPackage,[Parameter(Mandatory)][string]$BaseImage,
      [Parameter(Mandatory)][string]$ReleasePackage,[switch]$ReuseFixture,[string[]]$Cases=@(),
      [string]$Zig='', [string]$Qemu='', [ValidateRange(60,600)][int]$TimeoutSeconds=300)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$root=Split-Path $PSScriptRoot -Parent;$workspace=[IO.Path]::GetFullPath((Join-Path $root '../..'))
$distribution=Join-Path $workspace 'Repositories/Distribution'
. (Join-Path $PSScriptRoot 'Inventory.ps1')
. (Join-Path $PSScriptRoot 'Runtime.ps1')
. (Join-Path $PSScriptRoot 'Storage-Fixtures.ps1')
. (Join-Path $PSScriptRoot 'Guest-Qmp.ps1')
. (Join-Path $PSScriptRoot 'Guest-NetClients.ps1')
. (Join-Path $distribution 'Tools/Qemu-HostProfile.ps1')
$suffix=if($IsWindows){'.exe'}else{''}
if(!$Zig){$Zig=Join-Path $workspace "DevKit/Toolchains/Zig/zig$suffix"}
if(!$Qemu){$Qemu=Join-Path $workspace "DevKit/Emulation/QEMU/qemu-system-x86_64$suffix"}
$LimineRoot=Join-Path $workspace 'DevKit/Boot/Limine'
$limine=Join-Path $LimineRoot $(if($IsWindows){'limine-tool-windows-x86/limine.exe'}else{'limine'})
$output=Join-Path $root 'Artifacts/BootProbe/recovery-update';[IO.Directory]::CreateDirectory($output)|Out-Null
$kernel=Join-Path $root 'Artifacts/BootProbe/ui/bin/recovery.elf';$runtime=Join-Path $root 'Artifacts/Runtime/runtime.img'
$utf8=[Text.UTF8Encoding]::new($false);$bom=[Text.UTF8Encoding]::new($true)
$profile=Resolve-R4QemuHostProfile $Qemu
function Checked([string]$Program,[string[]]$Arguments){& $Program @Arguments|Out-Host;if($LASTEXITCODE -ne 0){throw "Host tool failed: $Program"}}
function Free-Port {$l=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0);$l.Start();$p=$l.LocalEndpoint.Port;$l.Stop();return $p}
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
 if($null -ne $process){if(!$process.HasExited){$process.Kill($true)};$process.WaitForExit()
  [IO.File]::WriteAllText((Join-Path $output "$name-qemu.log"),$stderr.GetAwaiter().GetResult(),$utf8)
  $null=$stdout.GetAwaiter().GetResult();$process.Dispose();$script:process=$null}
}
function Start-Guest([string[]]$Arguments){
 $script:serialLog=Join-Path $output "$name-serial.log";$script:clientLog=Join-Path $output "$name-clients.log"
 if(Test-Path $serialLog){Remove-Item $serialLog -Force};[IO.File]::WriteAllText($clientLog,'',$utf8)
 $script:qmpPort=Free-Port;$script:sshPort=Free-Port
 $base=@('-machine',"q35,accel=$($profile.AcceleratorChain)",'-cpu',$profile.CpuModel,'-smp','4','-display','none','-monitor','none','-no-reboot','-serial',"file:$serialLog",'-qmp',"tcp:127.0.0.1:$qmpPort,server=on,wait=off",'-device','qemu-xhci,id=xhci','-device','usb-kbd')
 $base+=@('-netdev',"user,id=net,hostfwd=tcp:127.0.0.1:$sshPort-:22",'-device','virtio-net-pci,netdev=net')
 $start=[Diagnostics.ProcessStartInfo]::new($Qemu);$start.UseShellExecute=$false;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
 foreach($arg in ($base+$Arguments)){$start.ArgumentList.Add($arg)}
 $script:process=[Diagnostics.Process]::Start($start);$script:stdout=$process.StandardOutput.ReadToEndAsync();$script:stderr=$process.StandardError.ReadToEndAsync();$script:session=$null
}
function Hash-Range([string]$Path,[long]$First,[long]$Count){
 $f=[IO.File]::OpenRead($Path);$hash=[Security.Cryptography.IncrementalHash]::CreateHash([Security.Cryptography.HashAlgorithmName]::SHA256)
 try{$f.Position=$First*512;$bytes=[byte[]]::new(1MB);[long]$left=$Count*512
  while($left -gt 0){$amount=[int][Math]::Min($left,$bytes.Length);$f.ReadExactly($bytes,0,$amount);$hash.AppendData($bytes,0,$amount);$left-=$amount}
  return [Convert]::ToHexString($hash.GetHashAndReset()).ToLowerInvariant()
 }finally{$hash.Dispose();$f.Dispose()}
}
function Witness([string]$Path){
 $check=[InstallationImageCheck]::new($Path)
 try{$result=[ordered]@{prefix=Hash-Range $Path 0 4096;gptBackup=Hash-Range $Path ($check.Bytes/512-33) 33;files=[ordered]@{};parts=[ordered]@{}}
  foreach($role in @('SYSTEM','BOOT','RECOVERY','DATA')){
   $p=$check.Partitions[$role];$result.parts[$role]=@{first=$p.First;count=$p.Count;guid=$p.Guid;type=$p.Type}
   if($role -ne 'RECOVERY'){$result[$role]=Hash-Range $Path $p.First $p.Count}
  }
  foreach($path in $check.Volumes['RECOVERY'].Paths()){$result.files[$path]=[InstallationImageCheck]::Hash($check.Volumes['RECOVERY'].ReadFile($path))}
  return $result
 }finally{$check.Dispose()}
}
function Expand-Package([string]$Zip,[string]$Destination){
 if(Test-Path $Destination){Remove-Item -LiteralPath $Destination -Recurse -Force}
 [IO.Compression.ZipFile]::ExtractToDirectory($Zip,$Destination)
}
function New-Seed([int]$Number){
 $extras=@("$SourcePackage|/INSTALL/RECOVERY.ZIP","$ReleasePackage|/INSTALL/RELEASE.ZIP")
 foreach($file in Get-ChildItem -LiteralPath $uiStage -File -Recurse){
  $relative=[IO.Path]::GetRelativePath($uiStage,$file.FullName).Replace('\','/')
  if($relative -notin @('recovery.elf','runtime.img')){$extras+="$($file.FullName)|/CURRENT/$relative"}
 }
 foreach($file in Get-ChildItem -LiteralPath $previousStage -File -Recurse){$extras+="$($file.FullName)|/PREVIOUS/$([IO.Path]::GetRelativePath($previousStage,$file.FullName).Replace('\','/'))"}
 $image=New-Installation $Number $false '1280x720x32' @{RECOVERY=$extras}
 $dir=Join-Path $output "disk-$Number";$config=Join-Path $dir 'limine.conf';$guid=Id $Number 4
 [IO.File]::WriteAllText($config,"# Keep this user configuration byte for byte.`ntimeout: 5`ndefault_entry: 1`n`n/R4OS Recovery`n    protocol: limine`n    path: guid($guid):/CURRENT/recovery.elf`n    resolution: 1280x720x32`n    module_path: guid($guid):/CURRENT/runtime.img`n    module_string: recovery.runtime=1`n`n/R4OS Recovery (Previous)`n    protocol: limine`n    path: guid($guid):/PREVIOUS/recovery.elf`n    resolution: 1280x720x32`n    module_path: guid($guid):/PREVIOUS/runtime.img`n    module_string: recovery.runtime=1`n",$utf8)
 $volume=Join-Path $dir 'boot-fixed.img';Checked $imageCreator @('--output',$volume,'--size','128','--volume-only','--add-list',(Join-Path $dir 'BOOT.list'))
 $f=[IO.File]::Open($volume,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite)
 try{$b=[byte[]]::new(512);$f.ReadExactly($b);U32 $b 28 4096;Write-At $f 0 $b;Write-At $f 3072 $b}finally{$f.Dispose()}
 $f=[IO.File]::Open($image,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite)
 try{Copy-Volume $f (4096*512) $volume
  # Storage enumeration fixtures round DATA down to whole MB. This update
  # acceptance instead uses a real release's exact DATA filesystem extent.
  $source=[IO.File]::OpenRead($BaseImage)
  try{$source.Position=3411968L*512;$f.Position=$source.Position;$buffer=[byte[]]::new(1MB);[long]$left=$source.Length-33*512-$source.Position
   while($left -gt 0){$amount=[int][Math]::Min($left,$buffer.Length);$source.ReadExactly($buffer,0,$amount);$f.Write($buffer,0,$amount);$left-=$amount}
  }finally{$source.Dispose()}
  $f.Flush($true)
 }finally{$f.Dispose()}
 Remove-Item $volume -Force
 return $image
}
function Shutdown-Guest([bool]$Mirror=$true) {
 Send-Keys $session @('up','up','ret')
 if($Mirror){$null=Wait-Guest '\[RECOVERYUI\] page=terminal selected=4'}
 Start-Sleep -Milliseconds 800
 foreach($key in @('p','o','w','e','r','o','f','f','ret')){Send-Keys $session @($key)}
 if(!$process.WaitForExit(20000) -or $process.ExitCode -ne 0){throw 'Recovery could not shut down through Terminal.'}
}
function Enter-UI([bool]$Previous=$false){
 if($Previous){Start-Sleep -Milliseconds 2000;$script:session=Open-Qmp $qmpPort;Send-Keys $session @('down','ret')}
 $null=Wait-Guest '\[RECOVERYUI\] progress=READY'
 if($null -eq $session){$script:session=Open-Qmp $qmpPort}
 Send-Keys $session @('ret');$text=Wait-Guest '\[RECOVERYUI\] ready=1';$null=Wait-Guest 'DHCP05913 state=bound'
 return $text
}
function Enter-Update {
 Send-Keys $session @('down','down','ret');$null=Wait-Guest '\[RECOVERYPACKAGE\] cache=manifest .*source=READY'
 Send-Keys $session @('ret');$null=Wait-Guest '\[RECOVERYUI\] page=targets selected=2 choice=0'
 Send-Keys $session @('ret');$null=Wait-Guest '\[RECOVERYUI\] page=review selected=2 choice=0';Send-Keys $session @('down','ret')
}
function Leave-Update {
 $null=Wait-Guest '\[RECOVERYUI\] page=dialog selected=2'
 Send-Keys $session @('esc','up','up');Shutdown-Guest
}
function Check-OtherPartitions([object]$Before,[object]$After){
 foreach($key in @('prefix','gptBackup','SYSTEM','BOOT','DATA')){if($Before[$key] -cne $After[$key]){throw "Recovery update changed $key"}}
 foreach($path in $Before.files.Keys){if($path.StartsWith('INSTALL/',[StringComparison]::OrdinalIgnoreCase) -and $Before.files[$path] -cne $After.files[$path]){throw "Changed cache $path"}}
}
function Check-Current([string]$Image){
 $check=[InstallationImageCheck]::new($Image)
 try{
  if([InstallationImageCheck]::Hash($check.Volumes['RECOVERY'].ReadFile('CURRENT/manifest.json')) -cne [InstallationImageCheck]::Hash($sourceManifestBytes)){throw 'New CURRENT manifest differs from ZIP.'}
  $paths=@($check.Volumes['RECOVERY'].Paths()|Where-Object {$_.StartsWith('CURRENT/',[StringComparison]::OrdinalIgnoreCase)})
  if($paths.Count -ne $sourceManifest.files.Count+1){throw 'Old CURRENT files remain.'}
  foreach($file in $sourceManifest.files){if([InstallationImageCheck]::Hash($check.Volumes['RECOVERY'].ReadFile('CURRENT/'+$file.path)) -cne $file.sha256){throw "New CURRENT mismatch: $($file.path)"}}
 }finally{$check.Dispose()}
}
function Record-Run([string]$Case,[Diagnostics.Stopwatch]$Watch,[string]$Image){
 $script:runs+=@(@{case=$Case;cpus=4;seconds=[Math]::Round($Watch.Elapsed.TotalSeconds,3);result='PASS';target=$Image})
 Write-RecoveryJson (Join-Path $output 'recovery-update-results.json') @{schema=1;inputs=$inputs;runs=$runs}
 Write-Host "PASS $Case ($([Math]::Round($Watch.Elapsed.TotalSeconds,2)) s)"
}
try {
 Test-RecoveryInventory $root|Out-Null
 if(-not ('InstallationImageCheck' -as [type])){Add-Type -Path (Join-Path $distribution 'Tools/InstallationImage.Check.cs')}
 $baseCheck=[InstallationImageCheck]::new($BaseImage)
 try{if($baseCheck.Bytes -ne 2048MB){throw 'Recovery fixture requires a standard 2048 MB release disk.'}}finally{$baseCheck.Dispose()}
 $imageCreator=Get-RecoveryImageCreator $root $Zig
 $zipSource=Join-Path $output 'host-zip-source';Expand-Package (Join-Path $root 'Legal/Sources/Protocols-R4Zip.zip') $zipSource
 $sdk=Join-Path $root 'Platform/SDK';$hostTool=Join-Path $output "recovery-host$suffix"
 Checked $Zig @('build-exe','-OReleaseSafe','--dep','r4os','--dep','zip_core',"-Mroot=$(Join-Path $root 'RecoveryTools/Menu/src/recovery_fixture.zig')",
  '--dep','r4os_contract',"-Mr4os=$(Join-Path $sdk 'r4os.zig')",'--dep','r4os',"-Mzip_core=$(Join-Path $zipSource 'src/zip_core.zig')",
  "-Mr4os_contract=$(Join-Path $root 'Platform/Contract/Generated/SDK/Zig/package.zig')","-femit-bin=$hostTool")
 $zip=[IO.Compression.ZipFile]::OpenRead($SourcePackage)
 try{$entry=$zip.GetEntry('manifest.json');$stream=$entry.Open();$memory=[IO.MemoryStream]::new()
  try{$stream.CopyTo($memory);$sourceManifestBytes=$memory.ToArray();$sourceManifest=[Text.Encoding]::UTF8.GetString($sourceManifestBytes).TrimStart([char]0xfeff)|ConvertFrom-Json -AsHashtable}finally{$stream.Dispose();$memory.Dispose()}
 }finally{$zip.Dispose()}
 $uiStage=Join-Path $output 'technical-ui-package';$previousStage=Join-Path $output 'previous-package'
 $inputs=@{package=Get-RecoveryHash $SourcePackage;previous=Get-RecoveryHash $PreviousPackage;release=Get-RecoveryHash $ReleasePackage;base=Get-RecoveryHash $BaseImage;kernel=Get-RecoveryHash $kernel;runtime=Get-RecoveryHash $runtime;creator=Get-RecoveryHash $imageCreator;host=Get-RecoveryHash $hostTool;runner=Get-RecoveryHash $PSCommandPath}
 $seed=Join-Path $output 'disk-20.img';$stamp=Join-Path $output 'recovery-fixture.json'
 if($ReuseFixture){
  $saved=Get-Content -Raw -LiteralPath $stamp|ConvertFrom-Json -AsHashtable
  foreach($key in $inputs.Keys){if($saved.inputs[$key] -cne $inputs[$key]){throw "Stale Recovery fixture: $key"}}
  foreach($file in $saved.images){if((Get-RecoveryHash $file.path) -cne $file.sha256){throw 'Changed fixture image.'}}
 }else{
  Expand-Package $SourcePackage $uiStage;Expand-Package $PreviousPackage $previousStage
  Copy-Item -LiteralPath $kernel -Destination (Join-Path $uiStage 'recovery.elf') -Force
  Copy-Item -LiteralPath $runtime -Destination (Join-Path $uiStage 'runtime.img') -Force
  $manifestPath=Join-Path $uiStage 'manifest.json';$manifest=Get-Content -Raw -LiteralPath $manifestPath|ConvertFrom-Json -AsHashtable
  $retired=Join-Path $uiStage 'Legal/RETIRED-FIXTURE.txt'
  [IO.File]::WriteAllText($retired,'Technical UI kernel, never published. This old-slot-only file must disappear from CURRENT and survive in PREVIOUS.',$utf8)
  $manifest.files=@($manifest.files)+@(@{path='Legal/RETIRED-FIXTURE.txt';bytes=0;sha256=''})
  foreach($file in $manifest.files){$p=Join-Path $uiStage $file.path;$file.bytes=([IO.FileInfo]$p).Length;$file.sha256=Get-RecoveryHash $p}
  Write-RecoveryJson $manifestPath $manifest
  $null=New-Seed 20
  Write-RecoveryJson $stamp @{inputs=$inputs;images=@(@{path=$seed;sha256=Get-RecoveryHash $seed})}
 }
 $technicalZip=Join-Path $output 'technical-ui.zip'
 if(Test-Path $technicalZip){Remove-Item $technicalZip -Force}
 [IO.Compression.ZipFile]::CreateFromDirectory($uiStage,$technicalZip,[IO.Compression.CompressionLevel]::Optimal,$false)
 Checked $hostTool @($technicalZip,$SourcePackage,$PreviousPackage,(Join-Path $output 'host-results.json'))
 $askpass=Join-Path $output "askpass$suffix";Checked $Zig @('cc','-O2',(Join-Path $PSScriptRoot 'Guest-Askpass.c'),'-o',$askpass)
 $ssh=(Get-Command "ssh$suffix" -CommandType Application|Select-Object -First 1).Source
 $sshOptions=@('-c','chacha20-poly1305@openssh.com','-o','StrictHostKeyChecking=no','-o',('UserKnownHostsFile='+$(if($IsWindows){'NUL'}else{'/dev/null'})),'-o','LogLevel=ERROR','-o','ConnectTimeout=5')
 $script:process=$null;$script:session=$null;$runs=@();$updated=Join-Path $output 'UsbSelfUpdate-target.img'
 $confirmationFile=Join-Path $output 'booted-state.r4s'
 $matrix=@('UsbSelfUpdate')
 if($Cases.Count){foreach($case in $Cases){if($case -notin @('UsbSelfUpdate','NewCurrentBoot','ReadonlyConfirmation','CutCurrent','PreviousAfterCut')){throw 'Unknown Recovery-update case.'}};$matrix=@($matrix|Where-Object {$_ -in $Cases})}
 foreach($case in $matrix){
  $name=$case;$watch=[Diagnostics.Stopwatch]::StartNew();$target=Join-Path $output "$name-target.img";Copy-Item -LiteralPath $seed -Destination $target -Force
  $before=Witness $target
  Write-Host "Recovery update ${name}: SMP4, 8192 MB, BIOS USB boot."
  try{
   Start-Guest @('-m','8192','-drive',"if=none,id=boot,format=raw,file=$target",'-device','usb-storage,drive=boot,bootindex=1')
   $null=Wait-Guest '\[RECOVERYUI\] progress=READY';$script:session=Open-Qmp $qmpPort;Send-Keys $session @('ret')
   $text=Wait-Guest '\[RECOVERYUI\] ready=1'
   if($text -notmatch '\[RECOVERYCONFIRM\] state=CONFIRMED content=BOOTED'){throw 'Actual booted UI kernel/runtime were not confirmed.'}
   $null=Wait-Guest 'DHCP05913 state=bound'
   $confirmedRecord=Ssh 'TYPE R:\state.r4s'
   if($confirmedRecord -notmatch 'CURRENT_CONFIRMED=yes'){throw 'Boot confirmation disappeared before update.'}
   $confirmationFile=Join-Path $output 'booted-state.r4s'
   [IO.File]::WriteAllText($confirmationFile,$confirmedRecord.TrimStart([char]0xfeff).TrimEnd([char[]]"`r`n")+"`r`n",$bom)
   Send-Keys $session @('down','down','ret');$null=Wait-Guest '\[RECOVERYPACKAGE\] cache=manifest .*source=READY'
   Send-Keys $session @('ret');$null=Wait-Guest '\[RECOVERYUI\] page=targets selected=2 choice=0'
   Send-Keys $session @('ret');$null=Wait-Guest '\[RECOVERYUI\] page=review selected=2 choice=0';Send-Keys $session @('down','ret')
   $text=Wait-Guest '\[RECOVERYUPDATE\] result=OK'
   if($text -notmatch '\[RECOVERYUPDATE\] prepared=OK rotate=1 own_source=1' -or $text -notmatch 'previous=VERIFIED current=UNCHANGED'){throw 'Confirmed CURRENT was not saved first.'}
   if((Ssh 'ECHO OLD-RAM-SESSION-ALIVE') -notmatch 'OLD-RAM-SESSION-ALIVE'){throw 'SSH stopped after self-update.'}
   $record=Ssh 'TYPE R:\state.r4s';if($record -notmatch 'CURRENT_CONFIRMED=no'){throw 'New CURRENT was confirmed before its first boot.'}
   $null=Wait-Guest '\[RECOVERYUI\] page=dialog selected=2'
   Send-Keys $session @('esc');Send-Keys $session @('up','up');Shutdown-Guest
  }finally{Stop-Guest}
  $after=Witness $target
  foreach($key in @('prefix','gptBackup','SYSTEM','BOOT','DATA')){if($before[$key] -cne $after[$key]){throw "Recovery update changed $key"}}
  foreach($path in $before.files.Keys){
   if($path.StartsWith('INSTALL/',[StringComparison]::OrdinalIgnoreCase) -and $before.files[$path] -cne $after.files[$path]){throw "Changed cache $path"}
   if($path.StartsWith('CURRENT/',[StringComparison]::OrdinalIgnoreCase)){$previous='PREVIOUS/'+$path.Substring(8);if($before.files[$path] -cne $after.files[$previous]){throw "Incomplete PREVIOUS copy: $path"}}
  }
  $check=[InstallationImageCheck]::new($target)
  try{$manifest=$sourceManifest
   if([InstallationImageCheck]::Hash($check.Volumes['RECOVERY'].ReadFile('CURRENT/manifest.json')) -cne [InstallationImageCheck]::Hash($sourceManifestBytes)){throw 'New CURRENT manifest differs from source ZIP.'}
   $paths=@($check.Volumes['RECOVERY'].Paths()|Where-Object {$_.StartsWith('CURRENT/',[StringComparison]::OrdinalIgnoreCase)})
   if($paths.Count -ne $manifest.files.Count+1){throw 'Old CURRENT files remain.'}
   foreach($file in $manifest.files){if([InstallationImageCheck]::Hash($check.Volumes['RECOVERY'].ReadFile('CURRENT/'+$file.path)) -cne $file.sha256){throw "New CURRENT mismatch: $($file.path)"}}
  }finally{$check.Dispose()}
  $updated=$target;$runs+=@(@{case=$name;cpus=4;seconds=[Math]::Round($watch.Elapsed.TotalSeconds,3);result='PASS';target=$target})
  Write-RecoveryJson (Join-Path $output 'recovery-update-results.json') @{schema=1;inputs=$inputs;runs=$runs}
  Write-Host "PASS $name ($([Math]::Round($watch.Elapsed.TotalSeconds,2)) s)"
 }
 if(!$Cases.Count -or 'NewCurrentBoot' -in $Cases){
  $name='NewCurrentBoot';$watch=[Diagnostics.Stopwatch]::StartNew();$target=Join-Path $output "$name-target.img";Copy-Item -LiteralPath $updated -Destination $target -Force
  $before=Witness $target;Check-Current $target
  try{
   Start-Guest @('-m','2048','-drive',"if=none,id=boot,format=raw,file=$target",'-device','nvme,drive=boot,serial=NEW-CURRENT,bootindex=1')
   $null=Wait-Guest '\[RECOVERY\] shell=READY';$null=Wait-Guest 'DHCP05913 state=bound';$script:session=Open-Qmp $qmpPort
   $deadline=[DateTime]::UtcNow.AddSeconds(40);$record=''
   do{try{$record=Ssh 'TYPE R:\state.r4s'}catch{if([DateTime]::UtcNow -ge $deadline){throw}};if($record -match 'CURRENT_CONFIRMED=yes'){break};Start-Sleep -Milliseconds 250}while([DateTime]::UtcNow -lt $deadline)
   if($record -notmatch 'CURRENT_CONFIRMED=yes' -or !$record.Contains('CURRENT_MANIFEST_SHA256='+[InstallationImageCheck]::Hash($sourceManifestBytes))){throw 'New production CURRENT was not confirmed against its manifest.'}
   $facts=Ssh 'TYPE C:\R4OS\CONFIG\RECBOOT.R4S';$expectedKernel=@($sourceManifest.files|Where-Object {$_.path -ceq 'recovery.elf'})[0].sha256
   if(!$facts.Contains('KERNEL_SHA256='+$expectedKernel) -or !$facts.Contains('SLOT=current')){throw 'Production boot content identity differs.'}
   Shutdown-Guest $false
  }finally{Stop-Guest}
  $after=Witness $target;Check-OtherPartitions $before $after
  foreach($path in $before.files.Keys){if($path -ine 'state.r4s' -and $before.files[$path] -cne $after.files[$path]){throw "Boot changed package file $path"}}
  Record-Run $name $watch $target
 }
 if(!$Cases.Count -or 'ReadonlyConfirmation' -in $Cases){
  $name='ReadonlyConfirmation';$watch=[Diagnostics.Stopwatch]::StartNew();$target=$seed;$beforeHash=Get-RecoveryHash $target
  try{
   Start-Guest @('-m','2048','-drive',"if=none,id=boot,format=raw,file=$target,readonly=on",'-device','usb-storage,drive=boot,bootindex=1')
   $text=Enter-UI
   if($text -notmatch '\[RECOVERYCONFIRM\] state=UNCONFIRMED reason=State(Write|Flush|Readback)' -or $text -match '\[RECOVERYCONFIRM\] state=CONFIRMED'){throw 'Read-only confirmation did not fail without blocking RAM.'}
   if((Ssh 'ECHO UNCONFIRMED-RAM-ALIVE') -notmatch 'UNCONFIRMED-RAM-ALIVE'){throw 'SSH unavailable after confirmation failure.'}
   Shutdown-Guest
  }finally{Stop-Guest}
  if((Get-RecoveryHash $target) -cne $beforeHash){throw 'Read-only boot medium changed.'}
  Record-Run $name $watch $target
 }
 $cutImage=Join-Path $output 'CutCurrent-target.img'
 if(!$Cases.Count -or 'CutCurrent' -in $Cases){
  # The state was collected from the actual successful UI boot above. Apply
  # it to the identical private seed so the fault starts from confirmed bytes.
  $name='CutCurrent';$watch=[Diagnostics.Stopwatch]::StartNew();$target=$cutImage
  Copy-Item -LiteralPath $seed -Destination $target -Force;Checked $hostTool @('--set-state',$target,$confirmationFile)
  $writePlan=Join-Path $output 'current-writes.json';Checked $hostTool @('--write-plan',$target,$SourcePackage,$writePlan)
  $plan=Get-Content -Raw -LiteralPath $writePlan|ConvertFrom-Json -AsHashtable
  $check=[InstallationImageCheck]::new($target);$occupied=[Collections.Generic.HashSet[long]]::new()
  try{foreach($path in @('CURRENT/recovery.elf','CURRENT/runtime.img')){foreach($sector in $check.Volumes['RECOVERY'].FileSectors($path)){$null=$occupied.Add($sector)}}}finally{$check.Dispose()}
  [long]$failLba=-1
  foreach($range in $plan.currentPayloadWrites){for([long]$sector=$range.first;$sector -lt $range.first+$range.count;$sector++){if($occupied.Contains($sector)){$failLba=$sector;break}};if($failLba -ge 0){break}}
  if($failLba -lt 0){throw 'No changed CURRENT payload sector available for the real write fault.'}
  $before=Witness $target
  $backend=@{driver='blkdebug';'node-name'='boot';image=@{driver='file';filename=$target};'inject-error'=@(@{event='none';iotype='write';errno=5;sector=$failLba;once=$false;immediately=$true})}|ConvertTo-Json -Depth 8 -Compress
  try{
   Start-Guest @('-m','8192','-blockdev',$backend,'-device','usb-storage,drive=boot,bootindex=1')
   $null=Enter-UI;Enter-Update
   $text=Wait-Guest '\[RECOVERYUPDATE\] result=(WriteFailed|FlushFailed|VerifyFailed) '
   if($text -notmatch 'previous=VERIFIED current=UNCHANGED' -or $text -notmatch 'phase=Replacing CURRENT.*attempted=1'){throw 'Fault did not interrupt CURRENT after verified PREVIOUS.'}
   if((Ssh 'ECHO FAILED-UPDATE-RAM-ALIVE') -notmatch 'FAILED-UPDATE-RAM-ALIVE'){throw 'RAM session stopped after failed write.'}
   Leave-Update
  }finally{Stop-Guest}
  $after=Witness $target;Check-OtherPartitions $before $after
  foreach($path in $before.files.Keys){if($path.StartsWith('CURRENT/',[StringComparison]::OrdinalIgnoreCase) -and $before.files[$path] -cne $after.files['PREVIOUS/'+$path.Substring(8)]){throw 'Verified PREVIOUS damaged by CURRENT write failure.'}}
  Record-Run $name $watch $target
 }
 if(!$Cases.Count -or 'PreviousAfterCut' -in $Cases){
  $name='PreviousAfterCut';$watch=[Diagnostics.Stopwatch]::StartNew();$target=Join-Path $output "$name-target.img";Copy-Item -LiteralPath $cutImage -Destination $target -Force
  $before=Witness $target
  try{
   Start-Guest @('-m','8192','-drive',"if=none,id=boot,format=raw,file=$target",'-device','usb-storage,drive=boot,bootindex=1')
   $text=Enter-UI $true
   if($text -notmatch 'source=ok bus=usb slot=previous' -or $text -match '\[RECOVERYCONFIRM\] state=CONFIRMED'){throw 'Fixed manual PREVIOUS boot or confirmation policy differs.'}
   Enter-Update;$text=Wait-Guest '\[RECOVERYUPDATE\] result=OK'
   if($text -notmatch 'prepared=OK rotate=0 own_source=1' -or $text -notmatch 'previous=PRESERVED'){throw 'PREVIOUS boot displaced its fallback.'}
   Leave-Update
  }finally{Stop-Guest}
  $after=Witness $target;Check-OtherPartitions $before $after;Check-Current $target
  foreach($path in $before.files.Keys){if($path.StartsWith('PREVIOUS/',[StringComparison]::OrdinalIgnoreCase) -and $before.files[$path] -cne $after.files[$path]){throw 'PREVIOUS changed while running it.'}}
  Record-Run $name $watch $target
 }
 exit 0
}catch{Write-Error $_ -ErrorAction Continue;exit 1}
