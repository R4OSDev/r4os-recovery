param(
    [ValidateSet('Bios','Uefi','Both')][string]$Firmware='Both',
    [ValidateSet('','800x600x32','1024x768x32','1920x1080x32')][string]$Resolution='',
    [string]$Zig='', [string]$Qemu='', [string]$LimineRoot='',
    [string]$OvmfCode='', [string]$OvmfVars='',
    [ValidateRange(30,300)][int]$TimeoutSeconds=120
)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'Inventory.ps1')
. (Join-Path $PSScriptRoot 'Runtime.ps1')
. (Join-Path $PSScriptRoot 'Guest-Qmp.ps1')
. (Join-Path $PSScriptRoot 'Storage-Fixtures.ps1')
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
$output=Join-Path $root 'Artifacts/BootProbe/ui'
$kernel=Join-Path $output 'bin/recovery.elf'
$runtime=Join-Path $root 'Artifacts/Runtime/runtime.img'
$resultPath=Join-Path $output 'ui-results.json'
$utf8=[Text.UTF8Encoding]::new($false)

function Checked([string]$Program,[string[]]$Arguments){
    & $Program @Arguments
    if($LASTEXITCODE -ne 0){throw "Host tool failed ($LASTEXITCODE): $Program"}
}
function Wait-Marker([string]$Pattern,[int]$Count=1){
    while($true){
        [string]$text=if(Test-Path -LiteralPath $serialLog){Get-Content -Raw -LiteralPath $serialLog}else{''}
        if($null -eq $text){$text=''}
        if($text -match '\[CRASH\]|panic-ret=|result=FAILED'){throw "Recovery UI crashed: $serialLog"}
        if([regex]::Matches($text,$Pattern).Count -ge $Count){return}
        if($process.HasExited -or $watch.Elapsed.TotalSeconds -ge $TimeoutSeconds){throw "Missing UI marker $Pattern ($Count): $serialLog"}
        Start-Sleep -Milliseconds 50
    }
}
function Capture([string]$Label){
    # Serial navigation precedes the following event-loop paint.
    Start-Sleep -Milliseconds 120
    $path=Join-Path $output "$name-$Label.ppm"
    $null=Qmp $session 'screendump' @{filename=$path}
    $frame=[RecoveryFrame]::new($path)
    if($null -ne $baseline){$frame.RequireOutsideUnchanged($baseline)}
    $frames.Add($path)
    return $frame
}
function Type-Command([string]$Command){
    $sequence=@(foreach($ch in $Command.ToLowerInvariant().ToCharArray()){
        switch([string]$ch){
            ' ' {'spc'} ':' {'shift+semicolon'} '\' {'backslash'} '.' {'dot'} '-' {'minus'} '/' {'slash'}
            default {if($ch -notmatch '[a-z0-9]'){throw "Unsupported test input: $ch"};[string]$ch}
        }
    })
    Send-Keys $session ($sequence+@('ret'))
}

try{
    [IO.Directory]::CreateDirectory($output)|Out-Null
    Test-RecoveryInventory $root|Out-Null
    foreach($path in @($kernel,$runtime,$Zig,$Qemu,$limine)){if(!(Test-Path -LiteralPath $path -PathType Leaf)){throw "Missing input: $path"}}
    if($Firmware -ne 'Bios'){foreach($path in @($OvmfCode,$OvmfVars)){if(!(Test-Path -LiteralPath $path -PathType Leaf)){throw "Missing firmware: $path"}}}
    $imageCreator=Get-RecoveryImageCreator $root $Zig
    $sources=Join-Path $root 'Artifacts/HostSources/Distribution'
    if(!(Test-Path -LiteralPath $sources)){[IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $root 'Legal/Sources/Distribution.zip'),$sources)}
    . (Join-Path $sources 'Tools/Qemu-HostProfile.ps1')
    $profile=Resolve-R4QemuHostProfile $Qemu
    if(Test-Path -LiteralPath $resultPath){Remove-Item -LiteralPath $resultPath -Force}
    [string[]]$modes=if($Firmware -eq 'Both'){@('Bios','Uefi')}else{@($Firmware)}
    $runs=@()
    foreach($mode in $modes){
        [string[]]$sizes=if($Resolution){@($Resolution)}elseif($mode -eq 'Bios'){@('800x600x32','1024x768x32','1920x1080x32')}else{@('1024x768x32')}
        foreach($size in $sizes){
            $name="$mode-$size"
            $inputs=[ordered]@{schema=1;kernel=Get-RecoveryHash $kernel;runtime=Get-RecoveryHash $runtime;resolution=$size;
                fixtureBuilder=Get-RecoveryHash (Join-Path $PSScriptRoot 'Storage-Fixtures.ps1');creator=Get-RecoveryHash $imageCreator;
                efi=Get-RecoveryHash (Join-Path $LimineRoot 'BOOTX64.EFI');bios=Get-RecoveryHash (Join-Path $LimineRoot 'limine-bios.sys')}
            $serialized=$inputs|ConvertTo-Json -Compress;$cache=Join-Path $output 'fixture-inputs.json'
            $cached=(Test-Path -LiteralPath $cache) -and ((Get-Content -Raw -LiteralPath $cache).Trim() -ceq $serialized) -and (Test-Path -LiteralPath (Join-Path $output 'disk-1.img'))
            if(!$cached){$null=New-Installation 1 $false $size;[IO.File]::WriteAllText($cache,$serialized,$utf8)}
            $serialLog=Join-Path $output "$name-serial.log";$errorLog=Join-Path $output "$name-qemu.log"
            if(Test-Path -LiteralPath $serialLog){Remove-Item -LiteralPath $serialLog -Force}
            $listener=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0)
            $listener.Start();$port=$listener.LocalEndpoint.Port;$listener.Stop()
            $arguments=@('-machine',"q35,accel=$($profile.AcceleratorChain),i8042=off",'-cpu',$profile.CpuModel,'-m','1024','-smp','4',
                '-display','none','-monitor','none','-no-reboot','-nic','none','-serial',"file:$serialLog",'-qmp',"tcp:127.0.0.1:$port,server=on,wait=off",
                '-device','qemu-xhci,id=ui-xhci','-device','usb-kbd,id=ui-keyboard','-device','usb-mouse,id=ignored-mouse',
                '-drive',"if=none,id=usb-media,format=raw,file=$(Join-Path $output 'disk-1.img'),snapshot=on",'-device','usb-storage,drive=usb-media,bootindex=1')
            if($mode -eq 'Uefi'){
                $vars=Join-Path $output 'OVMF-vars.fd';Copy-Item -LiteralPath $OvmfVars -Destination $vars -Force
                $arguments+=@('-drive',"if=pflash,format=raw,unit=0,readonly=on,file=$OvmfCode",'-drive',"if=pflash,format=raw,unit=1,file=$vars")
            }
            $start=[Diagnostics.ProcessStartInfo]::new($Qemu);$start.UseShellExecute=$false;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
            foreach($argument in $arguments){$start.ArgumentList.Add($argument)}
            $process=[Diagnostics.Process]::new();$process.StartInfo=$start
            $watch=[Diagnostics.Stopwatch]::StartNew();$started=$false;$session=$null;$baseline=$null
            $frames=[Collections.Generic.List[string]]::new()
            Write-Host "Recovery UI $name, SMP4, USB keyboard, $($profile.Name)."
            try{
                if(!$process.Start()){throw 'QEMU did not start.'}
                $started=$true;$stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
                Wait-Marker '\[RECOVERYUI\] progress=READY'
                $session=Open-Qmp $port
                $baseline=Capture 'progress'
                if("$($baseline.Width)x$($baseline.Height)x32" -cne $size){throw 'Limine did not provide the requested framebuffer mode.'}
                $baseline.RequireArtwork((Join-Path $root 'Runtime/R4OS/MEDIA/RECOVERY.BMP'))
                Send-Keys $session @('ret');Wait-Marker '\[RECOVERYUI\] ready=1'
                $first=Capture 'menu-initial';$first.RequireContentChanged($baseline);$firstRow=$first.RedRow()
                $itemHeight=if($baseline.Bottom-$baseline.Top -ge 250){22}else{14}
                Send-Keys $session @('up');Wait-Marker '\[RECOVERYUI\] page=menu selected=5'
                $last=Capture 'menu-5'
                if($last.RedRow() -ne $firstRow+5*$itemHeight){throw 'Up did not wrap to the last visible menu row.'}
                Send-Keys $session @('down');Wait-Marker '\[RECOVERYUI\] page=menu selected=0' 2
                for($selected=0;$selected -lt 4;$selected++){
                    $frame=Capture "menu-$selected"
                    if($frame.RedRow() -ne $firstRow+$selected*$itemHeight){throw "Wrong visible selection row: $selected"}
                    Send-Keys $session @('ret');Wait-Marker "\[RECOVERYUI\] page=dialog selected=$selected"
                    $dialog=Capture "dialog-$selected";$dialog.RequireContentChanged($frame)
                    Send-Keys $session @('esc');Wait-Marker "\[RECOVERYUI\] page=menu selected=$selected" $(if($selected -eq 0){3}else{2})
                    Send-Keys $session @('down');Wait-Marker "\[RECOVERYUI\] page=menu selected=$($selected+1)"
                }
                $frame=Capture 'menu-4'
                if($frame.RedRow() -ne $firstRow+4*$itemHeight){throw 'Terminal selection row missing.'}
                Send-Keys $session @('ret');Wait-Marker '\[RECOVERYUI\] page=terminal selected=4'
                Wait-Marker 'C:\\>'
                Type-Command 'ECHO UI-MARKER';Wait-Marker 'UI-MARKER' 2
                $typed=Capture 'terminal-text'
                $clearMatches=[regex]::Matches([string](Get-Content -Raw -LiteralPath $serialLog),'\[RECOVERYUI\] console-clear=(\d+)')
                if($clearMatches.Count -eq 0){throw 'Missing initial console clear count.'}
                $nextClear=[int]$clearMatches[-1].Groups[1].Value+1
                Type-Command 'CLS';Wait-Marker "\[RECOVERYUI\] console-clear=$nextClear(?:\r?\n)"
                $cleared=Capture 'terminal-clear';$cleared.RequireContentChanged($typed)
                Type-Command 'HELP';Wait-Marker 'Type HELP /S'
                Wait-Marker '\[RECOVERYUI\] console-scroll=1'
                $scrolled=Capture 'terminal-scroll';$scrolled.RequireContentChanged($cleared)
                Type-Command 'EXIT';Wait-Marker '\[RECOVERYUI\] terminal=RETURNED'
                Wait-Marker '\[RECOVERYUI\] independent-session=UNCHANGED cleanup=OK'
                $returned=Capture 'terminal-return';$returned.RequireContentChanged($scrolled)
                if($returned.RedRow() -ne $firstRow+4*$itemHeight){throw 'EXIT did not restore the Terminal menu selection.'}
                Send-Keys $session @('down','ret');Wait-Marker '\[RECOVERYUI\] restart=REQUESTED'
                while(!$process.WaitForExit(100)){if($watch.Elapsed.TotalSeconds -ge $TimeoutSeconds){throw 'Recovery restart timed out.'}}
                if($process.ExitCode -ne 0){throw 'QEMU did not exit normally on guest reset.'}
            }catch{
                if($null -ne $session -and !$process.HasExited){try{$null=Qmp $session 'screendump' @{filename=(Join-Path $output "$name-failed.ppm")}}catch{}}
                throw
            }finally{
                if($null -ne $session){$session.Writer.Dispose();$session.Reader.Dispose();$session.Client.Dispose()}
                if($started){
                    if(!$process.HasExited){$process.Kill($true);$process.WaitForExit()}
                    [IO.File]::WriteAllText($errorLog,$stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult(),$utf8)
                }
                $process.Dispose()
            }
            [string]$text=Get-Content -Raw -LiteralPath $serialLog
            if($text -notmatch '\[SMP\] stage=active discovered=4 started=3 online=4 failed=0' -or $text -notmatch '\[RESET\]' -or $text -match '\[CRASH\]|result=FAILED'){throw "Incomplete UI acceptance: $serialLog"}
            $run=[ordered]@{firmware=$mode;resolution=$size;result='ok';cpus=4;accelerator=$profile.Name;keyboard='USB';i8042='off';
                seconds=[Math]::Round($watch.Elapsed.TotalSeconds,3);kernelSha256=$inputs.kernel;runtimeSha256=$inputs.runtime;serialLog=$serialLog;
                frames=$frames.ToArray();artworkSha256=Get-RecoveryHash (Join-Path $root 'Runtime/R4OS/MEDIA/RECOVERY.BMP');
                navigation='six entries, wrap, enter, escape';console='text, clear, scroll, cursor, EXIT';independentSession='unchanged and reaped'}
            $runs+=$run;Write-RecoveryJson $resultPath @{schema=1;runs=$runs}
            Write-Host "Recovery UI $name OK ($($run.seconds) seconds, $($frames.Count) framebuffer comparisons)."
        }
    }
    exit 0
}catch{Write-Error "$($_.Exception.Message)`n$($_.ScriptStackTrace)" -ErrorAction Continue;exit 1}
