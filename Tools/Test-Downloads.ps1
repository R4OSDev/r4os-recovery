param([switch]$ReuseFixture,[switch]$LiveOnly,[switch]$NoCuts,[string]$Zig='', [string]$Qemu='')
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$root=Split-Path $PSScriptRoot -Parent
$workspace=[IO.Path]::GetFullPath((Join-Path $root '../..'))
. (Join-Path $root 'Tools/Inventory.ps1')
. (Join-Path $root 'Tools/Runtime.ps1')
. (Join-Path $root 'Tools/Storage-Fixtures.ps1')
. (Join-Path $root 'Tools/Package.ps1')
. (Join-Path $root 'Tools/Guest-NetClients.ps1')
Add-Type -Path (Join-Path $root 'Tools/Download-FixtureServer.cs')
Add-Type -Path (Join-Path $root 'Tools/Download-FatFaults.cs')
$suffix=if($IsWindows){'.exe'}else{''}
if(!$Zig){$Zig=Join-Path $workspace "DevKit/Toolchains/Zig/zig$suffix"}
if(!$Qemu){$Qemu=Join-Path $workspace "DevKit/Emulation/QEMU/qemu-system-x86_64$suffix"}
$LimineRoot=Join-Path $workspace 'DevKit/Boot/Limine';$limine=Join-Path $LimineRoot $(if($IsWindows){'limine-tool-windows-x86/limine.exe'}else{'limine'})
$output=Join-Path $root 'Artifacts/BootProbe/downloads';[IO.Directory]::CreateDirectory($output)|Out-Null
$kernel=Join-Path $root 'Artifacts/Kernel/bin/recovery.elf';$runtime=Join-Path $root 'Artifacts/Runtime/runtime.img'
$utf8=[Text.UTF8Encoding]::new($false)
function Checked([string]$Program,[string[]]$Arguments){& $Program @Arguments;if($LASTEXITCODE -ne 0){throw "Host tool failed: $Program"}}
function Free-Port {$l=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0);$l.Start();$p=$l.LocalEndpoint.Port;$l.Stop();return $p}
$imageCreator=Get-RecoveryImageCreator $root $Zig
$good=Join-Path $output 'good.zip';$bad=Join-Path $output 'invalid.zip';$normal=Join-Path $output 'normal.zip'
$oldRecovery=Join-Path $output 'older-recovery.zip'
$oldNormal=Join-Path $output 'older-r4os.zip'
$version=(Get-RecoveryFields (Join-Path $root 'VERSION.R4S')).RECOVERY_VERSION[0]
function Older-Zip([string]$Source,[string]$Destination){
 # A second fully valid original ZIP with identical verified payloads and a
 # different directory timestamp. No previous build/artifact is required.
 Copy-Item -LiteralPath $Source -Destination $Destination -Force
 $archive=[IO.Compression.ZipFile]::Open($Destination,[IO.Compression.ZipArchiveMode]::Update)
 try{$archive.Entries[0].LastWriteTime=[DateTimeOffset]::Parse('2000-01-01T00:00:00Z')}finally{$archive.Dispose()}
 if((Get-RecoveryHash $Source) -ceq (Get-RecoveryHash $Destination)){throw 'Distinct cache generations were not created.'}
}
function Metadata([string]$Name,[string]$File,[string]$Kind='recovery'){
 $release=if($Kind -eq 'r4os'){'0.76.16'}else{$version}
 $asset=if($Kind -eq 'r4os'){"R4OS-$release-slim-x86_64.zip"}else{"R4OS-Recovery-$release-x86_64.zip"}
 $repository=if($Kind -eq 'r4os'){'r4os-distribution'}else{'r4os-recovery'}
 $value=@{tag_name="v$release";draft=$false;prerelease=$false;published_at='2026-09-05T00:00:00Z';assets=@(@{name=$asset;state='uploaded';size=([IO.FileInfo]$File).Length;digest=('sha256:'+(Get-RecoveryHash $File));browser_download_url="https://github.com/R4OSDev/$repository/releases/download/v$release/$asset"})}
 [IO.File]::WriteAllText((Join-Path $output "meta-$Name.json"),($value|ConvertTo-Json -Depth 10),$utf8)
}
$fixtureInputs=@{kernel=Get-RecoveryHash $kernel;runtime=Get-RecoveryHash $runtime;lock=Get-RecoveryHash (Join-Path $root 'Provenance/inputs.lock.json');script=Get-RecoveryHash $PSCommandPath;creator=Get-RecoveryHash $imageCreator}
$stamp=Join-Path $output 'fixture-inputs.json'
if($ReuseFixture){
 if(!(Test-Path -LiteralPath $stamp)){throw 'No verified fixture cache; run without ReuseFixture.'}
 $record=Get-Content -Raw -LiteralPath $stamp|ConvertFrom-Json -AsHashtable
 foreach($key in $fixtureInputs.Keys){if($record.inputs[$key] -cne $fixtureInputs[$key]){throw "Stale fixture input: $key"}}
 foreach($relative in $record.files.Keys){if((Get-RecoveryHash (Join-Path $output $relative)) -cne $record.files[$relative]){throw "Changed fixture: $relative"}}
}
if(!$ReuseFixture){
 $null=New-RecoveryPackage -Root $root -Destination $good
 Copy-Item -LiteralPath $good -Destination $bad -Force
 $archive=[IO.Compression.ZipFile]::Open($bad,[IO.Compression.ZipArchiveMode]::Update)
 try{
  $entry=$archive.GetEntry('manifest.json');$reader=[IO.StreamReader]::new($entry.Open(),$utf8)
  try{$manifest=$reader.ReadToEnd()|ConvertFrom-Json -AsHashtable}finally{$reader.Dispose()}
  $entry.Delete();$manifest.files[0].sha256='0'*64;$entry=$archive.CreateEntry('manifest.json',[IO.Compression.CompressionLevel]::Optimal)
  $writer=[IO.StreamWriter]::new($entry.Open(),$utf8);try{$writer.Write(($manifest|ConvertTo-Json -Depth 32)+"`n")}finally{$writer.Dispose()}
 }finally{$archive.Dispose()}
 $versionFile=Join-Path $output 'VERSION.R4S';[IO.File]::WriteAllText($versionFile,"RELEASE_VERSION=0.76.16`n",[Text.UTF8Encoding]::new($true))
 $sourceImage=New-Installation 9 $false '1024x768x32' @{SYSTEM=@("$versionFile|/R4OS/CONFIG/VERSION.R4S")}
 $bootRoot=Join-Path $output 'managed-boot';[IO.Directory]::CreateDirectory((Join-Path $bootRoot 'boot'))|Out-Null
 Copy-Item -LiteralPath $kernel -Destination (Join-Path $bootRoot 'boot/r4os.elf') -Force
 $legalRoot=Join-Path $output 'fixture-legal';[IO.Directory]::CreateDirectory($legalRoot)|Out-Null
 [IO.File]::WriteAllText((Join-Path $legalRoot 'README.txt'),'Technical fixture; never a published R4OS release.',$utf8)
 . (Join-Path $root 'Platform/Distribution/Tools/ReleasePackage.ps1')
 $package=New-R4OSReleasePackage -Image $sourceImage -BootRoot $bootRoot -RecoveryPackage $good -LegalRoot $legalRoot -ReleaseVersion '0.76.16' -KernelVersion ((Get-RecoveryFields (Join-Path $root 'Kernel/VERSION.R4S')).KERNEL_VERSION[0]) -Profile slim -OutputRoot (Join-Path $output 'system')
 Copy-Item -LiteralPath $package.path -Destination $normal -Force
 Older-Zip $good $oldRecovery;Older-Zip $normal $oldNormal
 foreach($name in @('good','redirect','truncated','wrong')){Metadata $name $good}
 Metadata invalid $bad;Metadata normal $normal r4os
 $null=New-Installation 1 $false '1024x768x32' @{RECOVERY=@("$oldRecovery|/INSTALL/RECOVERY.ZIP","$oldNormal|/INSTALL/RELEASE.ZIP")}
 $files=@{}
 foreach($relative in @('disk-1.img','good.zip','invalid.zip','normal.zip','older-recovery.zip','older-r4os.zip','meta-good.json','meta-redirect.json','meta-truncated.json','meta-wrong.json','meta-invalid.json','meta-normal.json')){$files[$relative]=Get-RecoveryHash (Join-Path $output $relative)}
 Write-RecoveryJson $stamp @{inputs=$fixtureInputs;files=$files}
}
$null=[RecoveryDownloadFatFaults]::Check((Join-Path $output 'disk-1.img'))
. (Join-Path $root 'Artifacts/HostSources/Distribution/Tools/Qemu-HostProfile.ps1')
$profile=Resolve-R4QemuHostProfile $Qemu
$askpass=Join-Path $output "askpass$suffix";Checked $Zig @('cc','-O2',(Join-Path $root 'Tools/Guest-Askpass.c'),'-o',$askpass)
$ssh=(Get-Command "ssh$suffix" -CommandType Application|Select-Object -First 1).Source
$sshOptions=@('-c','chacha20-poly1305@openssh.com','-o','StrictHostKeyChecking=no','-o',('UserKnownHostsFile='+$(if($IsWindows){'NUL'}else{'/dev/null'})),'-o','LogLevel=ERROR','-o','ConnectTimeout=5')
$scratch=Join-Path $output 'untouched.img';$file=[IO.File]::Create($scratch);try{$file.SetLength(2048MB)}finally{$file.Dispose()}
$targetBefore=Get-RecoveryHash $scratch
$server=[RecoveryDownloadFixtureServer]::new($output);$base="http://10.0.2.2:$($server.Port)"
$script:process=$null;$runs=@()
function Start-Guest([string]$Image,[string]$Label){
 $script:name=$Label;$script:serialLog=Join-Path $output "$Label-serial.log";$script:clientLog=Join-Path $output "$Label-clients.log"
 if(Test-Path -LiteralPath $serialLog){Remove-Item -LiteralPath $serialLog -Force}
 [IO.File]::WriteAllText($clientLog,'',$utf8);$script:sshPort=Free-Port
 $arguments=@('-machine',"q35,accel=$($profile.AcceleratorChain)",'-cpu',$profile.CpuModel,'-m','4096','-smp','4','-display','none','-monitor','none','-no-reboot','-serial',"file:$serialLog",'-device','qemu-xhci,id=rec-xhci',
  '-drive',"if=none,id=usb-media,format=raw,file=$Image",'-device','usb-storage,drive=usb-media,bootindex=1',
  '-drive',"if=none,id=untouched,format=raw,file=$scratch",'-device','nvme,drive=untouched,serial=DOWNLOAD-UNTOUCHED',
  '-netdev',"user,id=rec-net,hostfwd=tcp:127.0.0.1:${sshPort}-:22",'-device','virtio-net-pci,netdev=rec-net')
 $start=[Diagnostics.ProcessStartInfo]::new($Qemu);$start.UseShellExecute=$false;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
 foreach($argument in $arguments){$start.ArgumentList.Add($argument)}
 $script:process=[Diagnostics.Process]::Start($start);$script:qemuOut=$process.StandardOutput.ReadToEndAsync();$script:qemuErr=$process.StandardError.ReadToEndAsync();$script:watch=[Diagnostics.Stopwatch]::StartNew()
 while($true){
  $text=if(Test-Path $serialLog){Get-Content -Raw $serialLog}else{''}
  if($text -match '\[CRASH\]' -or $process.HasExited -or $watch.Elapsed.TotalSeconds -gt 90){throw "Guest startup failed: $Label"}
  if($text -match '\[RECOVERY\] shell=READY' -and $text -match '\[RECOVERYNET\] autostart=RETURNED' -and $text -match 'DHCP05913 state=bound'){break}
  Start-Sleep -Milliseconds 100
 }
 Write-Host "SMP4 Recovery $Label ready; SSH $sshPort."
}
function Stop-Guest {
 if($null -ne $process){
  if(!$process.HasExited){$process.Kill($true);$process.WaitForExit()}
  [IO.File]::WriteAllText((Join-Path $output "$name-qemu.log"),$qemuOut.GetAwaiter().GetResult()+$qemuErr.GetAwaiter().GetResult(),$utf8)
  $process.Dispose();$script:process=$null
 }
}
function Witness([string]$Argument,[int]$ExitCode=0){
 $elapsed=[Diagnostics.Stopwatch]::StartNew()
 $text=Client $ssh (@('-p',"$sshPort")+$sshOptions+@('r4os@127.0.0.1',"C:\R4OS\SOFTWARE\RECOVERY\RECOVERY.R4X /DOWNLOADSMOKE $Argument")) '' 180000 $ExitCode
 Write-Host $text
 Write-Host ("Witness {0}: {1:N3}s" -f $Argument,$elapsed.Elapsed.TotalSeconds)
 if($ExitCode -eq 0 -and $text -notmatch '\[DOWNLOADSMOKE\] result=OK'){throw "Incomplete witness: $Argument"}
 return $text
}
function Cache-Matches([string]$File,[switch]$R4OS,[switch]$Complete){
 $text=Witness $(if($R4OS){'CHECKR4OS'}else{'CHECK'})
 if($text -notmatch ('sha256='+(Get-RecoveryHash $File))){throw 'Cached ZIP content differs.'}
 if($Complete -and $text -notmatch 'part=0 txn=0 backup=0'){throw 'Completed cache retained a transaction.'}
}
try{
 $image=Join-Path $output 'run.img';Copy-Item -LiteralPath (Join-Path $output 'disk-1.img') -Destination $image -Force
 Start-Guest $image main
 $null=Witness LIVE
 if(!$LiveOnly){
  Cache-Matches $oldRecovery -Complete;Cache-Matches $oldNormal -R4OS -Complete
  $null=Witness FAT
  $null=Witness NOSPACE;Cache-Matches $oldRecovery -Complete
  foreach($case in @('truncated','wrong','invalid')){
   $text=Witness "FIXTURE $base $case" 1
   $wanted=switch($case){'truncated'{'NetworkDownload'};'wrong'{'SourceChanged'};'invalid'{'HashMismatch'}}
   if($text -notmatch "error=$wanted"){throw "Unexpected rejection: $case"}
   Cache-Matches $oldRecovery;Cache-Matches $oldNormal -R4OS -Complete
  }
  $null=Witness "FIXTURE $base redirect";Cache-Matches $good -Complete;Cache-Matches $oldNormal -R4OS -Complete
  $null=Witness "FIXTURE $base good";Cache-Matches $good -Complete
  $null=Witness "R4OS $base normal";Cache-Matches $normal -R4OS -Complete;Cache-Matches $good -Complete
 }
 $runs+=@{name='main';seconds=$watch.Elapsed.TotalSeconds};Stop-Guest
 $null=[RecoveryDownloadFatFaults]::Check($image)
 if(!$LiveOnly -and !$NoCuts){
  foreach($cut in @('journal','publish','cleanup')){
   Copy-Item -LiteralPath (Join-Path $output 'disk-1.img') -Destination $image -Force
   Start-Guest $image "cut-$cut"
   $start=[Diagnostics.ProcessStartInfo]::new($ssh);$start.UseShellExecute=$false;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true;$start.RedirectStandardInput=$true
   $start.Environment['SSH_ASKPASS']=$askpass;$start.Environment['SSH_ASKPASS_REQUIRE']='force';$start.Environment['DISPLAY']='recovery-download-cut'
   foreach($argument in (@('-p',"$sshPort")+$sshOptions+@('r4os@127.0.0.1',"C:\R4OS\SOFTWARE\RECOVERY\RECOVERY.R4X /DOWNLOADSMOKE CUT $base $cut"))){$start.ArgumentList.Add($argument)}
   $holder=[Diagnostics.Process]::Start($start);$holder.StandardInput.Close();$holderOut=$holder.StandardOutput.ReadToEndAsync();$holderErr=$holder.StandardError.ReadToEndAsync()
   try{
    $ready=$false;$deadline=[DateTime]::UtcNow.AddSeconds(180)
    while(!$holder.HasExited -and [DateTime]::UtcNow -lt $deadline){
     if((Ssh 'DIR C:\TEMP') -match 'DOWNLOAD.RDY'){$ready=$true;break};Start-Sleep -Milliseconds 250
    }
    if(!$ready){throw "Cut point was not reached: $cut"}
    Stop-Guest # abrupt host power loss after the named durable boundary
    if($cut -eq 'journal'){Copy-Item -LiteralPath $image -Destination (Join-Path $output 'journal-durable.img') -Force}
    if(!$holder.WaitForExit(5000)){$holder.Kill($true);$holder.WaitForExit()}
   }finally{
    if(!$holder.HasExited){$holder.Kill($true);$holder.WaitForExit()}
    [IO.File]::WriteAllText((Join-Path $output "cut-$cut-holder.log"),$holderOut.GetAwaiter().GetResult()+$holderErr.GetAwaiter().GetResult(),$utf8);$holder.Dispose()
   }
   Start-Guest $image "resume-$cut"
   Cache-Matches $good -Complete;Cache-Matches $oldNormal -R4OS -Complete
   $runs+=@{name="power-cut-$cut";seconds=$watch.Elapsed.TotalSeconds};Stop-Guest
   $null=[RecoveryDownloadFatFaults]::Check($image)
  }
 }
 if(!$LiveOnly -and !$NoCuts){
  foreach($fault in @('alias-backup','alias-published','lfn-detached','orphan-create')){
   $source=Join-Path $output $(if($fault -eq 'orphan-create'){'disk-1.img'}else{'journal-durable.img'})
   Copy-Item -LiteralPath $source -Destination $image -Force
   [RecoveryDownloadFatFaults]::Patch($image,$fault)
   Start-Guest $image "fat-$fault"
   if($fault -eq 'orphan-create'){Cache-Matches $oldRecovery -Complete}
   else{Cache-Matches $good -Complete}
   if($fault -in @('lfn-detached','orphan-create')){$null=Witness LFN;$null=Witness "FIXTURE $base good";Cache-Matches $good -Complete}
   Cache-Matches $oldNormal -R4OS -Complete
   $runs+=@{name="fat-$fault";seconds=$watch.Elapsed.TotalSeconds};Stop-Guest
   $null=[RecoveryDownloadFatFaults]::Check($image)
  }
 }
 if((Get-RecoveryHash $scratch) -cne $targetBefore){throw 'An installation target was modified.'}
 $report=@{schema=1;kernel=Get-RecoveryHash $kernel;runtime=Get-RecoveryHash $runtime;targetBefore=$targetBefore;targetAfter=Get-RecoveryHash $scratch;runs=$runs;liveOnly=[bool]$LiveOnly;cuts=[bool](!$NoCuts -and !$LiveOnly)}
 Write-RecoveryJson (Join-Path $output 'download-results.json') $report
 Write-Host 'Recovery downloads: all requested witnesses passed; installation target unchanged.'
}finally{
 Stop-Guest;$server.Dispose();[IO.File]::WriteAllText((Join-Path $output 'http-requests.log'),($server.Requests.ToArray() -join "`n---`n"),$utf8)
}
