param(
    [ValidateSet('Bios','Uefi','Both')][string]$Firmware='Both',
    [ValidateSet('All','Usb','Local')][string]$Boot='All',
    [ValidateSet('All','Usb','Ps2')][string]$Keyboard='All',
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
$output=Join-Path $root 'Artifacts/BootProbe/input'
$kernel=Join-Path $output 'bin/recovery.elf'
$runtime=Join-Path $root 'Artifacts/Runtime/runtime.img'
$resultPath=Join-Path $output 'input-results.json'
$utf8=[Text.UTF8Encoding]::new($false)
function Checked([string]$Program,[string[]]$Arguments){
    & $Program @Arguments
    if($LASTEXITCODE -ne 0){throw "Host tool failed ($LASTEXITCODE): $Program"}
}
. (Join-Path $PSScriptRoot 'Storage-Fixtures.ps1')

function Qmp([object]$Session,[string]$Command,[hashtable]$Arguments=@{}){
    $id=[Guid]::NewGuid().ToString('N')
    $Session.Writer.WriteLine((@{execute=$Command;arguments=$Arguments;id=$id}|ConvertTo-Json -Compress -Depth 10))
    do{
        $line=$Session.Reader.ReadLine()
        if($null -eq $line){throw 'QMP disconnected.'}
        $message=$line|ConvertFrom-Json -AsHashtable
    }while(!$message.ContainsKey('id') -or $message.id -cne $id)
    if($message.ContainsKey('error')){throw "QMP $Command failed: $($message.error|ConvertTo-Json -Compress)"}
    return $message['return']
}
function Open-Qmp([int]$Port){
    $client=[Net.Sockets.TcpClient]::new()
    try{
        $client.Connect('127.0.0.1',$Port)
        $stream=$client.GetStream();$stream.ReadTimeout=5000;$stream.WriteTimeout=5000
        $session=[pscustomobject]@{Client=$client;Reader=[IO.StreamReader]::new($stream,$utf8,$false,4096,$true);Writer=[IO.StreamWriter]::new($stream,$utf8,4096,$true)}
        $session.Writer.AutoFlush=$true
        $greeting=$session.Reader.ReadLine()|ConvertFrom-Json -AsHashtable
        if(!$greeting.ContainsKey('QMP')){throw 'Missing QMP greeting.'}
        $null=Qmp $session 'qmp_capabilities'
        return $session
    }catch{$client.Dispose();throw}
}
function Send-Keys([object]$Session,[string[]]$Sequence){
    foreach($chord in $Sequence){
        $keys=@($chord.Split('+')|ForEach-Object {@{type='qcode';data=$_}})
        $null=Qmp $Session 'send-key' @{keys=$keys;'hold-time'=35}
        Start-Sleep -Milliseconds 70
    }
}

try{
    [IO.Directory]::CreateDirectory($output)|Out-Null
    Test-RecoveryInventory $root|Out-Null
    foreach($path in @($kernel,$runtime,$Zig,$Qemu,$limine)){if(!(Test-Path -LiteralPath $path -PathType Leaf)){throw "Missing input: $path"}}
    if($Firmware -ne 'Bios'){foreach($path in @($OvmfCode,$OvmfVars)){if(!(Test-Path -LiteralPath $path -PathType Leaf)){throw "Missing firmware: $path"}}}
    $machineHelp=& $Qemu -machine q35,help
    if($LASTEXITCODE -ne 0 -or ($machineHelp -join "`n") -notmatch 'i8042=<bool>'){throw 'USB-only proof requires QEMU i8042=off.'}
    $imageCreator=Get-RecoveryImageCreator $root $Zig
    $sources=Join-Path $root 'Artifacts/HostSources/Distribution'
    if(!(Test-Path -LiteralPath $sources)){[IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $root 'Legal/Sources/Distribution.zip'),$sources)}
    . (Join-Path $sources 'Tools/Qemu-HostProfile.ps1')
    $profile=Resolve-R4QemuHostProfile $Qemu
    $inputs=[ordered]@{schema=1;kernel=Get-RecoveryHash $kernel;runtime=Get-RecoveryHash $runtime;fixtureBuilder=Get-RecoveryHash (Join-Path $PSScriptRoot 'Storage-Fixtures.ps1');
        creator=Get-RecoveryHash $imageCreator;efi=Get-RecoveryHash (Join-Path $LimineRoot 'BOOTX64.EFI');bios=Get-RecoveryHash (Join-Path $LimineRoot 'limine-bios.sys')}
    $cache=Join-Path $output 'fixture-inputs.json';$serialized=$inputs|ConvertTo-Json -Compress
    $cached=(Test-Path -LiteralPath $cache) -and ((Get-Content -Raw -LiteralPath $cache).Trim() -ceq $serialized)
    foreach($number in @(1,2)){if(!(Test-Path -LiteralPath (Join-Path $output "disk-$number.img"))){$cached=$false}}
    if(!$cached){
        foreach($number in @(1,2)){$null=New-Installation $number}
        [IO.File]::WriteAllText($cache,$serialized,$utf8)
    }
    if(Test-Path -LiteralPath $resultPath){Remove-Item -LiteralPath $resultPath -Force}
    [string[]]$modes=if($Firmware -eq 'Both'){@('Bios','Uefi')}else{@($Firmware)}
    [string[]]$boots=if($Boot -eq 'All'){@('Usb','Local')}else{@($Boot)}
    [string[]]$keyboards=if($Keyboard -eq 'All'){@('Ps2','Usb')}else{@($Keyboard)}
    $runs=@()
    foreach($mode in $modes){foreach($origin in $boots){foreach($inputDevice in $keyboards){
        $name="$mode-$origin-$inputDevice"
        $serialLog=Join-Path $output "$name-serial.log";$errorLog=Join-Path $output "$name-qemu.log"
        if(Test-Path -LiteralPath $serialLog){Remove-Item -LiteralPath $serialLog -Force}
        $listener=[Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback,0)
        $listener.Start();$port=$listener.LocalEndpoint.Port;$listener.Stop()
        $usbOrder=if($origin -eq 'Usb'){1}else{9};$localOrder=if($origin -eq 'Local'){1}else{10}
        $ps2=if($inputDevice -eq 'Ps2'){'on'}else{'off'}
        $arguments=@('-machine',"q35,accel=$($profile.AcceleratorChain),i8042=$ps2",'-cpu',$profile.CpuModel,'-m','1024','-smp','4',
            '-display','none','-monitor','none','-no-reboot','-nic','none','-serial',"file:$serialLog",'-qmp',"tcp:127.0.0.1:$port,server=on,wait=off",
            '-device','qemu-xhci,id=input-xhci','-device','usb-mouse,id=ignored-mouse',
            '-drive',"if=none,id=usb-media,format=raw,file=$(Join-Path $output 'disk-1.img'),snapshot=on",'-device',"usb-storage,drive=usb-media,bootindex=$usbOrder",
            '-drive',"if=none,id=local-media,format=raw,file=$(Join-Path $output 'disk-2.img'),snapshot=on",'-device',"ide-hd,drive=local-media,bus=ide.0,bootindex=$localOrder")
        if($inputDevice -eq 'Usb'){$arguments+=@('-device','usb-kbd,id=recovery-keyboard')}
        if($mode -eq 'Uefi'){
            $vars=Join-Path $output 'OVMF-vars.fd';Copy-Item -LiteralPath $OvmfVars -Destination $vars -Force
            $arguments+=@('-drive',"if=pflash,format=raw,unit=0,readonly=on,file=$OvmfCode",'-drive',"if=pflash,format=raw,unit=1,file=$vars")
        }
        $start=[Diagnostics.ProcessStartInfo]::new($Qemu);$start.UseShellExecute=$false;$start.RedirectStandardOutput=$true;$start.RedirectStandardError=$true
        foreach($argument in $arguments){$start.ArgumentList.Add($argument)}
        $process=[Diagnostics.Process]::new();$process.StartInfo=$start
        $watch=[Diagnostics.Stopwatch]::StartNew();$started=$false;$session=$null;$sent=@{}
        Write-Host "Recovery input $name, SMP4, $($profile.Name), i8042=$ps2."
        try{
            if(!$process.Start()){throw 'QEMU did not start.'}
            $started=$true;$stdout=$process.StandardOutput.ReadToEndAsync();$stderr=$process.StandardError.ReadToEndAsync()
            while(!$process.WaitForExit(100)){
                if($watch.Elapsed.TotalSeconds -ge $TimeoutSeconds){throw "Input probe timed out: $serialLog"}
                if(!(Test-Path -LiteralPath $serialLog)){continue}
                [string]$text=Get-Content -Raw -LiteralPath $serialLog
                if($text -match '\[CRASH\]|result=FAILED'){throw "Input probe failed: $serialLog"}
                foreach($phase in @('EN','DE','TERMINAL')){
                    # Empty Get-Content output may be AutomationNull, whose
                    # collection -notmatch result is empty, not Boolean true.
                    if($sent.ContainsKey($phase) -or !($text -match "\[RECOVERYINPUT\] phase=$phase")){continue}
                    if($null -eq $session){$session=Open-Qmp $port}
                    $sequence=switch($phase){
                        'EN'{@('up','down','left','right','home','end','pgup','pgdn','delete','ret','esc','tab','backspace','a','shift+a','y','z','shift+1','ctrl+c')}
                        'DE'{@('y','z','bracket_left','minus','alt_r+q','alt_r+e','ret')}
                        'TERMINAL'{@('e','c','h','o','x','backspace','spc','i','n','p','u','t','minus','o','k','spc','shift+dot','spc','c','shift+semicolon','backslash','t','e','m','p','backslash','i','n','p','u','t','dot','t','x','t','ret','e','x','i','t','ret')}
                    }
                    Send-Keys $session $sequence
                    Write-Host "Recovery input ${name}: sent $phase ($($sequence.Count) chords)."
                    $sent[$phase]=$true
                }
            }
            if($process.ExitCode -ne 0){throw "QEMU failed: $errorLog"}
        }finally{
            if($null -ne $session){$session.Writer.Dispose();$session.Reader.Dispose();$session.Client.Dispose()}
            if($started){
                if(!$process.HasExited){$process.Kill($true);$process.WaitForExit()}
                [IO.File]::WriteAllText($errorLog,$stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult(),$utf8)
            }
            $process.Dispose()
        }
        [string]$text=Get-Content -Raw -LiteralPath $serialLog
        $visible=if($origin -eq 'Usb'){1}else{0};$expectedInput=$inputDevice.ToUpperInvariant()
        if($sent.Count -ne 3 -or $text -notmatch "\[RECOVERYINPUT\] result=OK cpus=4 input=$expectedInput layouts=EN,DE navigation=OK text=OK terminal_file=OK shell_exit=OK mouse=0 usb_storage=$visible"){throw "Incomplete input witness: $serialLog"}
        $bus=$origin.ToLowerInvariant()
        if($text -notmatch "\[RECOVERYSTORAGE\] source=ok bus=$bus slot=current"){throw 'Input probe booted from the wrong medium.'}
        $run=[ordered]@{firmware=$mode;boot=$origin;keyboard=$inputDevice;i8042=$ps2;result='ok';cpus=4;accelerator=$profile.Name;
            seconds=[Math]::Round($watch.Elapsed.TotalSeconds,3);kernelSha256=$inputs.kernel;runtimeSha256=$inputs.runtime;serialLog=$serialLog}
        $runs+=$run;Write-RecoveryJson $resultPath @{schema=1;runs=$runs}
        Write-Host "Recovery input $name OK ($($run.seconds) seconds)."
    }}}
    exit 0
}catch{Write-Error "$($_.Exception.Message)`n$($_.ScriptStackTrace)" -ErrorAction Continue;exit 1}
