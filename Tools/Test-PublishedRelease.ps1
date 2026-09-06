param([Parameter(Mandatory)][ValidateSet('Recovery','R4OS')][string]$Product,
      [Parameter(Mandatory)][ValidatePattern('^\d+\.\d+\.\d+$')][string]$Version,
      [Parameter(Mandatory)][ValidatePattern('^[0-9a-f]{64}$')][string]$Sha256,
      [Parameter(Mandatory)][string]$BaseImage,
      [ValidateSet('Slim','Full')][string]$Profile='Full',
      [ValidateRange(60,900)][int]$TimeoutSeconds=600)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$root=Split-Path $PSScriptRoot -Parent;$workspace=[IO.Path]::GetFullPath((Join-Path $root '../..'))
. (Join-Path $PSScriptRoot 'Inventory.ps1')
. (Join-Path $PSScriptRoot 'Guest-Qmp.ps1')
. (Join-Path $PSScriptRoot 'Guest-NetClients.ps1')
. (Join-Path $root '../Distribution/Tools/Qemu-HostProfile.ps1')
. (Join-Path $root '../Distribution/Tools/InstallationImage.Check.ps1')
$output=Join-Path $root "Artifacts/BootProbe/published-$($Product.ToLowerInvariant())"
[IO.Directory]::CreateDirectory($output)|Out-Null
$utf8=[Text.UTF8Encoding]::new($false)
$repository=if($Product -ceq 'Recovery'){'r4os-recovery'}else{'r4os-distribution'}
$assetName=if($Product -ceq 'Recovery'){"R4OS-Recovery-$Version-x86_64.zip"}else{"R4OS-$Version-$($Profile.ToLowerInvariant())-x86_64.zip"}
$channel="https://api.github.com/repos/R4OSDev/$repository/releases/latest"
$metadata=Invoke-RestMethod -Uri $channel -UserAgent 'R4OS-Recovery-release-acceptance' -TimeoutSec 30
$assets=@($metadata.assets|Where-Object {$_.name -ceq $assetName})
if($metadata.tag_name -cne "v$Version" -or $metadata.draft -or $metadata.prerelease -or $assets.Count -ne 1){throw 'The public channel does not select the expected release.'}
$asset=$assets[0];$url="https://github.com/R4OSDev/$repository/releases/download/v$Version/$assetName"
if($asset.state -cne 'uploaded' -or $asset.browser_download_url -cne $url -or $asset.digest -cne "sha256:$Sha256"){throw 'Public asset identity/digest differs from the prepared release.'}
# The complete common image is already verified; always operate on a copy.
$checked=Test-R4OSInstallationImage -Image $BaseImage -Medium local
$sourceHash=Get-RecoveryHash $BaseImage
$image=Join-Path $output 'run.img';Copy-Item -LiteralPath $BaseImage -Destination $image -Force
$part=$checked.installation.partitions.RECOVERY
$cacheName=if($Product -ceq 'Recovery'){'RECOVERY'}else{'RELEASE'}
$initial=[InstallationImageCheck]::new($image)
try{if(@($initial.Volumes['RECOVERY'].Paths()|Where-Object {$_ -ieq "INSTALL/$cacheName.ZIP"}).Count){throw 'Use an uncached base image to prove an actual public download.'}}finally{$initial.Dispose()}
function Other-Bytes {
 $f=[IO.File]::OpenRead($image);$hash=[Security.Cryptography.IncrementalHash]::CreateHash([Security.Cryptography.HashAlgorithmName]::SHA256)
 try{
  [long]$end=($part.firstLba+$part.sectorCount)*512
  foreach($range in @(@{at=0L;bytes=[long]$part.firstLba*512},@{at=$end;bytes=$f.Length-$end})){
   $f.Position=$range.at;[long]$left=$range.bytes;$buffer=[byte[]]::new(1MB)
   while($left -gt 0){$count=[int][Math]::Min($left,$buffer.Length);$f.ReadExactly($buffer,0,$count);$hash.AppendData($buffer,0,$count);$left-=$count}
  }
  return [Convert]::ToHexString($hash.GetHashAndReset()).ToLowerInvariant()
 }finally{$hash.Dispose();$f.Dispose()}
}
$before=Other-Bytes
$qemu=Join-Path $workspace $(if($IsWindows){'DevKit/Emulation/QEMU/qemu-system-x86_64.exe'}else{'DevKit/Emulation/QEMU/qemu-system-x86_64'})
$hostProfile=Resolve-R4QemuHostProfile $qemu
$listener=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0);$listener.Start();$port=$listener.LocalEndpoint.Port;$listener.Stop()
$listener.Start();$sshPort=$listener.LocalEndpoint.Port;$listener.Stop()
$suffix=if($IsWindows){'.exe'}else{''}
$zig=Join-Path $workspace "DevKit/Toolchains/Zig/zig$suffix"
$askpass=Join-Path $output "askpass$suffix"
& $zig cc -O2 (Join-Path $PSScriptRoot 'Guest-Askpass.c') -o $askpass
if($LASTEXITCODE -ne 0){throw 'Guest client helper did not compile.'}
$ssh=(Get-Command "ssh$suffix" -CommandType Application|Select-Object -First 1).Source
$sshOptions=@('-c','chacha20-poly1305@openssh.com','-o','StrictHostKeyChecking=no','-o',('UserKnownHostsFile='+$(if($IsWindows){'NUL'}else{'/dev/null'})),'-o','LogLevel=ERROR','-o','ConnectTimeout=5')
$clientLog=Join-Path $output 'clients.log';[IO.File]::WriteAllText($clientLog,'',$utf8)
$serialLog=Join-Path $output 'serial.log';if(Test-Path $serialLog){Remove-Item $serialLog -Force}
$arguments=@('-machine',"q35,accel=$($hostProfile.AcceleratorChain)",'-cpu',$hostProfile.CpuModel,'-m','8192','-smp','4','-display','none','-monitor','none','-no-reboot',
 '-serial',"file:$serialLog",'-qmp',"tcp:127.0.0.1:$port,server=on,wait=off",'-device','qemu-xhci,id=xhci','-device','usb-kbd',
 '-drive',"if=none,id=source,format=raw,file=$image",'-device','usb-storage,drive=source,bootindex=1','-netdev',"user,id=net,hostfwd=tcp:127.0.0.1:$sshPort-:22",'-device','virtio-net-pci,netdev=net')
$arguments+=@(Get-RecoveryFirmwareArgs)
$start=[Diagnostics.ProcessStartInfo]::new($qemu);$start.UseShellExecute=$false;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
foreach($argument in $arguments){$start.ArgumentList.Add($argument)}
$process=[Diagnostics.Process]::new();$process.StartInfo=$start;$started=$false;$session=$null
function Wait-Marker([string]$Pattern){
 $deadline=[DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
 while($true){
  [string]$text=if(Test-Path $serialLog){Get-Content -Raw $serialLog}else{''}
  if($text -match '\[CRASH\]|panic-ret=|\[RECOVERYDOWNLOAD\] error='){throw "Guest release download failed: $serialLog"}
  if($text -match $Pattern){return}
  if($process.HasExited -or [DateTime]::UtcNow -gt $deadline){throw "Missing release marker $Pattern"}
  Start-Sleep -Milliseconds 100
 }
}
$cacheObservationCount=0;$cacheObservationMaxMs=0L;$cacheObservationsOver20s=@()
function Observe-Cache([string]$Command,[DateTime]$Deadline){
 # The checked ZIP publication fingerprints the complete large file under
 # the volume request gate. A concurrent directory query can legitimately
 # outlive the general 20-second SSH probe; retain a bounded observation
 # window and the enclosing download deadline, without ignoring failures.
 $remaining=[long][Math]::Floor(($Deadline-[DateTime]::UtcNow).TotalMilliseconds)
 if($remaining -le 0){throw 'Public cache observation exceeded the download deadline.'}
 $timeout=[int][Math]::Min(60000,$remaining)
 $measurement=[Diagnostics.Stopwatch]::StartNew()
 $value=Client $ssh (@('-p',"$sshPort")+$sshOptions+@('r4os@127.0.0.1',$Command)) -TimeoutMilliseconds $timeout
 $elapsed=$measurement.ElapsedMilliseconds
 $script:cacheObservationCount++
 $script:cacheObservationMaxMs=[Math]::Max($script:cacheObservationMaxMs,$elapsed)
 if($elapsed -ge 20000){
  $script:cacheObservationsOver20s+=@(@{command=$Command;milliseconds=$elapsed})
  Write-Host "Public cache observation: $Command completed in $elapsed ms."
 }
 return $value
}
$watch=[Diagnostics.Stopwatch]::StartNew()
try{
 if(!$process.Start()){throw 'QEMU did not start.'};$started=$true;$stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
 Start-Sleep -Milliseconds 2000;$session=Open-Qmp $port
 Send-Keys $session @('down','ret') # fixed common-image Recovery entry
 Wait-Marker '\[RECOVERY\] shell=READY';Wait-Marker 'DHCP05913 state=bound';Wait-Marker '\[RECOVERYNET\] autostart=RETURNED'
 # Production consoles are not mirrored to serial. Observe boot confirmation
 # and the actual published cache through ordinary SSH, without a probe build.
 $deadline=[DateTime]::UtcNow.AddSeconds(60)
 do{
  $state=if((Ssh 'DIR R:\') -match 'state\.r4s'){Ssh 'TYPE R:\state.r4s'}else{''}
  if($state -match 'CURRENT_CONFIRMED=yes'){break}
  if($process.HasExited -or [DateTime]::UtcNow -gt $deadline){throw 'Production menu did not confirm its boot.'}
  Start-Sleep -Milliseconds 250
 }while($true)
 $null=Qmp $session 'screendump' @{filename=(Join-Path $output 'menu.ppm')}
 $selected=if($Product -ceq 'Recovery'){2}else{0}
 if($selected -eq 2){Send-Keys $session @('down','down')}
 Send-Keys $session @('ret');Start-Sleep -Milliseconds 1000
 Send-Keys $session @('down')
 if($Product -ceq 'R4OS' -and $Profile -ceq 'Full'){Send-Keys $session @('right')}
 $null=Qmp $session 'screendump' @{filename=(Join-Path $output 'github-source.ppm')}
 Send-Keys $session @('ret')
 $deadline=[DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
 do{
  $listing=if((Observe-Cache 'DIR R:\' $deadline) -match 'INSTALL'){Observe-Cache 'DIR R:\INSTALL' $deadline}else{''}
  if($listing -match ($cacheName+'\.ZIP') -and $listing -notmatch ($cacheName+'\.(PART|TXN|BAK|TMP|JBK|LCK)')){break}
  if($process.HasExited -or [DateTime]::UtcNow -gt $deadline){throw 'The menu did not publish a complete download cache.'}
  Start-Sleep -Milliseconds 1000
 }while($true)
 Start-Sleep -Milliseconds 1000
 $null=Qmp $session 'screendump' @{filename=(Join-Path $output 'download-complete.ppm')}
 Send-Keys $session @('esc','esc')
 Send-Keys $session $(if($selected -eq 2){@('down','down','ret')}else{@('up','up','ret')})
 Start-Sleep -Milliseconds 600
 Send-Keys $session @('p','o','w','e','r','o','f','f','ret')
 if(!$process.WaitForExit(20000) -or $process.ExitCode -ne 0){throw 'Recovery did not shut down through its Terminal.'}
}catch{
 if($null -ne $session -and !$process.HasExited){try{$null=Qmp $session 'screendump' @{filename=(Join-Path $output 'failure.ppm')}}catch{}}
 throw
}finally{
 if($null -ne $session){$session.Writer.Dispose();$session.Reader.Dispose();$session.Client.Dispose()}
 if($started){if(!$process.HasExited){$process.Kill($true)};$process.WaitForExit();[IO.File]::WriteAllText((Join-Path $output 'qemu.log'),$stderr.GetAwaiter().GetResult(),$utf8);$null=$stdout.GetAwaiter().GetResult()};$process.Dispose()
}
$view=[InstallationImageCheck]::new($image)
try{
 $cache=if($Product -ceq 'Recovery'){'INSTALL/RECOVERY.ZIP'}else{'INSTALL/RELEASE.ZIP'}
 $bytes=$view.Volumes['RECOVERY'].ReadFile($cache)
 if($bytes.Length -ne $asset.size -or [InstallationImageCheck]::Hash($bytes) -cne $Sha256){throw 'The actual downloaded cache is not byte-identical to the public release.'}
}finally{$view.Dispose()}
if((Other-Bytes) -cne $before -or (Get-RecoveryHash $BaseImage) -cne $sourceHash){throw 'Download changed an unrelated partition or its source image.'}
$report=@{schema=1;result='PASS';product=$Product;version=$Version;profile=$Profile;asset=$assetName;releaseId=$metadata.id;assetId=$asset.id;url=$url;sha256=$Sha256;bytes=$asset.size;
 cpus=4;ramBytes=8GB;seconds=[Math]::Round($watch.Elapsed.TotalSeconds,3);sourceImageSha256=$sourceHash;otherPartitionsUnchanged=$true;runnerSha256=Get-RecoveryHash $PSCommandPath;serialSha256=Get-RecoveryHash $serialLog;clientsSha256=Get-RecoveryHash $clientLog;
 cacheObservationCount=$cacheObservationCount;cacheObservationTimeoutMilliseconds=60000;cacheObservationMaxMilliseconds=$cacheObservationMaxMs;cacheObservationsOver20s=$cacheObservationsOver20s}
Write-RecoveryJson (Join-Path $output 'published-release-results.json') $report
Write-Host "Published $Product $Version PASS: actual menu GitHub download, complete cached ZIP SHA256, SMP4/8GB, unrelated partitions unchanged."
